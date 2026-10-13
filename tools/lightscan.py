"""Find the brightest, most light-like spots in every banner master.

For each banner in Media/final-images/runtime-manifest.json this loads the
approved master, finds compact bright blobs (candle flames, braziers, gems,
torches, magic), merges neighbouring ones into clusters (a candelabra is one
light source with several flames), ranks them, and draws numbered markers on
contact sheets for review. Positions are fractions of the master (u from the
left, v from the top), the same numbers B.glows uses in Core.lua.

    python tools/lightscan.py [out_dir]

Writes lightscan.json and sheet-XX.jpg into out_dir (default: reports/
image-tests/lightscan). Requires Pillow and numpy. Nothing here ships.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FINAL = ROOT / "Media/final-images"
SCAN_W = 400  # scan width in pixels; the height follows the master's aspect
TILE_W, TILE_H, LABEL_H = 420, 315, 36
COLS, ROWS = 4, 3

KIND_COLOR = {
    "point": (255, 214, 64),    # small and sharp: candle, gem, spark
    "flame": (255, 140, 40),    # a compact source with some body: torch, brazier, fire
    "cluster": (255, 70, 200),  # several flames close together: candelabra, braziers
    "edge": (90, 220, 120),     # long thin highlight: blade, staff, rim light
    "ambient": (90, 190, 255),  # large and soft: sky, sun, fog (a sunlight candidate)
}


def has_effects():
    """Banner keys that already have a B.glows spec in Core.lua."""
    text = (ROOT / "Core.lua").read_text(encoding="utf-8")
    keys = set()
    for m in re.finditer(r'^\s*(?:\["([\w\-.]+)"\]|([A-Za-z_][\w]*))\s*=\s*(?:\{|[A-Z]\w*\()', text, re.M):
        keys.add((m.group(1) or m.group(2)).replace("-banner.blp", ""))
    return keys


def label_components(mask):
    """4-connected components of a boolean array; returns a list of (ys, xs)."""
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    comps = []
    ys0, xs0 = np.nonzero(mask)
    for y0, x0 in zip(ys0, xs0):
        if seen[y0, x0]:
            continue
        stack, ys, xs = [(y0, x0)], [], []
        seen[y0, x0] = True
        while stack:
            y, x = stack.pop()
            ys.append(y)
            xs.append(x)
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        comps.append((np.array(ys), np.array(xs)))
    return comps


def scan(path):
    img = Image.open(path).convert("L")
    w = SCAN_W
    h = round(w * img.height / img.width)
    img = img.resize((w, h), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))
    a = np.asarray(img, dtype=np.float32)
    wide = np.asarray(img.filter(ImageFilter.GaussianBlur(22)), dtype=np.float32)
    robust = float(np.percentile(a, 99.7))
    # a candidate must be near the picture's own white point and clearly bright
    thresh = max(0.93 * robust, 215.0)
    mask = a >= thresh
    comps = []
    for ys, xs in label_components(mask):
        area = len(ys)
        if area < 3:
            continue
        wgt = a[ys, xs] - thresh + 1
        cy, cx = float((ys * wgt).sum() / wgt.sum()), float((xs * wgt).sum() / wgt.sum())
        bw, bh = xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
        r = int(np.sqrt(area) * 2 + 5)
        y0, y1, x0, x1 = max(0, int(cy) - r), min(h, int(cy) + r + 1), max(0, int(cx) - r), min(w, int(cx) + r + 1)
        patch = a[y0:y1, x0:x1]
        ring = patch.copy()
        inner = np.zeros_like(patch, dtype=bool)
        inner[max(0, int(cy) - y0 - bh // 2 - 1):int(cy) - y0 + bh // 2 + 2,
              max(0, int(cx) - x0 - bw // 2 - 1):int(cx) - x0 + bw // 2 + 2] = True
        ring_mean = float(ring[~inner].mean()) if (~inner).any() else 0.0
        # a real light is bright against both its near and its wider surroundings;
        # a rim highlight on skin or armor only beats the near ring
        near = float(a[ys, xs].mean() - ring_mean)
        far = float(a[ys, xs].mean() - wide[min(h - 1, int(cy)), min(w - 1, int(cx))])
        comps.append({
            "u": cx / w, "v": cy / h, "area": area, "aw": bw / w, "ah": bh / h,
            "peak": float(a[ys, xs].max()), "contrast": min(near, far * 1.5),
            "elong": max(bw, bh) / max(1, min(bw, bh)),
        })
    # merge neighbouring small sources into clusters (candelabra, torch rows)
    comps.sort(key=lambda c: -c["area"])
    clusters = []
    for c in comps:
        for k in clusters:
            if (abs(k["u"] - c["u"]) < 0.07 and abs(k["v"] - c["v"]) < 0.09 and c["area"] < 0.004 * w * h
                    and c["contrast"] > 60 and k["contrast"] > 60):
                n = k["count"]
                k["u"] = (k["u"] * n + c["u"]) / (n + 1)
                k["v"] = (k["v"] * n + c["v"]) / (n + 1)
                k["umin"], k["umax"] = min(k["umin"], c["u"]), max(k["umax"], c["u"])
                k["vmin"], k["vmax"] = min(k["vmin"], c["v"]), max(k["vmax"], c["v"])
                k["area"] += c["area"]
                k["contrast"] = max(k["contrast"], c["contrast"])
                k["count"] = n + 1
                break
        else:
            clusters.append(dict(c, count=1, umin=c["u"], umax=c["u"], vmin=c["v"], vmax=c["v"]))
    out = []
    for k in clusters:
        frac = k["area"] / (w * h)
        if k["elong"] >= 3.2 and k["count"] == 1:
            kind = "edge"
        elif frac > 0.02:
            kind = "ambient"
        elif k["count"] >= 3:
            kind = "cluster"
        elif frac > 0.0025:
            kind = "flame"
        else:
            kind = "point"
        # where the art fades (left, bottom, very top) a light is hidden by the shading
        zone = 1.0
        if k["u"] < 0.22:
            zone *= 0.35
        if k["v"] > 0.82:
            zone *= 0.4
        if k["v"] < 0.04:
            zone *= 0.5
        compact = 1.0 / (1.0 + max(0.0, frac - 0.004) * 60)
        score = max(0.0, k["contrast"]) / 255.0 * compact * zone * (1 + 0.15 * min(k["count"], 6))
        out.append({
            "kind": kind, "u": round(k["u"], 3), "v": round(k["v"], 3),
            "size": round(max(k["umax"] - k["umin"], k["aw"] if k["count"] == 1 else 0, 0.02), 3),
            "flames": k["count"], "area": round(frac, 5), "contrast": round(k["contrast"], 1),
            "peak": round(k["peak"], 1), "score": round(score, 3),
            "hidden_by_fade": zone < 1.0,
        })
    out = [c for c in out if c["score"] >= 0.10]
    out.sort(key=lambda c: -c["score"])
    return out[:4], img.size


def draw_tile(src, cands, name, existing):
    tile = Image.new("RGB", (TILE_W, TILE_H + LABEL_H), (14, 14, 16))
    im = Image.open(src).convert("RGB")
    im.thumbnail((TILE_W, TILE_H), Image.LANCZOS)
    ox, oy = (TILE_W - im.width) // 2, (TILE_H - im.height) // 2
    tile.paste(im, (ox, oy))
    d = ImageDraw.Draw(tile)
    font = ImageFont.load_default()
    for i, c in enumerate(cands, 1):
        x, y = ox + c["u"] * im.width, oy + c["v"] * im.height
        col = KIND_COLOR[c["kind"]]
        r = 8 if c["kind"] != "ambient" else 12
        d.ellipse((x - r, y - r, x + r, y + r), outline=col, width=2)
        d.text((x + r + 2, y - 5), str(i), fill=col, font=font)
    label = name + ("  [has effects]" if existing else "")
    d.text((6, TILE_H + 4), label, fill=(235, 235, 235), font=font)
    kinds = " ".join(f"{i}:{c['kind']}{'x' + str(c['flames']) if c['flames'] > 1 else ''}" for i, c in enumerate(cands, 1))
    d.text((6, TILE_H + 18), kinds[:70], fill=(160, 160, 160), font=font)
    return tile


def main():
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "reports/image-tests/lightscan"
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((FINAL / "runtime-manifest.json").read_text(encoding="utf-8"))
    existing = has_effects()
    # one scan per master image; several goals can share it
    by_source = {}
    for goal, info in manifest.items():
        by_source.setdefault(info["source"], []).append(goal)
    results, tiles = {}, []
    for source, goals in sorted(by_source.items(), key=lambda kv: kv[1][0]):
        path = FINAL / source
        if not path.exists():
            print("missing", source)
            continue
        cands, _ = scan(path)
        flagged = any(g in existing for g in goals)
        results[source] = {"goals": goals, "has_effects": flagged, "candidates": cands}
        tiles.append(draw_tile(path, cands, goals[0] + (f" (+{len(goals) - 1})" if len(goals) > 1 else ""), flagged))
    per = COLS * ROWS
    for page in range(0, len(tiles), per):
        sheet = Image.new("RGB", (COLS * TILE_W, ROWS * (TILE_H + LABEL_H)), (8, 8, 9))
        for i, t in enumerate(tiles[page:page + per]):
            sheet.paste(t, ((i % COLS) * TILE_W, (i // COLS) * (TILE_H + LABEL_H)))
        sheet.save(out_dir / f"sheet-{page // per + 1:02d}.jpg", quality=84)
    (out_dir / "lightscan.json").write_text(json.dumps(results, indent=1) + "\n", encoding="utf-8")
    print(f"{len(results)} images, {len(tiles)} tiles, {(len(tiles) + per - 1) // per} sheets -> {out_dir}")


if __name__ == "__main__":
    main()
