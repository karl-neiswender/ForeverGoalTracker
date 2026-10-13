"""Pack the addon's big TGA textures as compressed BLP2 (DXT1 or DXT5).

    python tools/texpack.py [--apply] [files...]

With no files it considers every TGA under Media/ of 100 KB or more (the small
icons stay TGA; they gain nothing). For each one it chooses DXT1 when the
picture is opaque and DXT5 when it uses alpha (DXT5 keeps a full 8-bit alpha
channel, so soft glows and fades do not band), writes the BLP next to a scratch
copy, decodes it again and compares with the original:
  - mean error per colour channel, only where the pixel shows (alpha > 0),
  - the worst alpha error,
  - a banding score: the largest jump between neighbouring alpha levels along
    the picture's smoothest ramp.
A file is only converted when its errors are small. Without --apply it just
reports (and writes a before/after contact sheet into the scratch folder named
by FGT_SCRATCH). With --apply it writes Media/<name>.blp and removes the TGA
(the game loads the name without an extension, so nothing else changes).

DXT1 stores colour as RGB565, which tints neutral greys: never use it for a
grey image drawn additively. Those are stored as white plus alpha (DXT5).
Uses the BLP2 layout documented by
https://github.com/Kanma/BLPConverter/blob/master/blp_internal.h
"""
import os
import struct
import sys
from io import BytesIO
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MIN_BYTES = 100 * 1024
LIMITS = {"mean": 3.0, "alpha": 10, "band": 10}  # levels (0-255); alpha is the 99.9th percentile


def encode(image, dxt5):
    """BLP2 bytes for an RGBA/RGB image, with a full mip chain."""
    w, h = image.size
    assert (w & (w - 1)) == 0 and (h & (h - 1)) == 0, "power-of-two sizes only"
    mode = "RGBA" if dxt5 else "RGB"
    level = image.convert(mode)
    payloads = []
    while True:
        dds = BytesIO()
        level.save(dds, format="DDS", pixel_format="DXT5" if dxt5 else "DXT1")
        data = dds.getvalue()
        assert data[:4] == b"DDS " and data[84:88] == (b"DXT5" if dxt5 else b"DXT1")
        payloads.append(data[128:])
        if level.width == 1 and level.height == 1:
            break
        level = level.resize((max(1, level.width // 2), max(1, level.height // 2)), Image.Resampling.LANCZOS)
    offset = 148 + 1024
    offsets, lengths = [], []
    for block in payloads:
        offsets.append(offset)
        lengths.append(len(block))
        offset += len(block)
    # encoding 2 = DXTC; alpha depth 8 and alpha encoding 7 = DXT5 (0 and 0 = DXT1); 1 = has mips
    header = struct.pack("<4sI4BII", b"BLP2", 1, 2, 8 if dxt5 else 0, 7 if dxt5 else 0, 1, w, h)
    header += struct.pack("<16I", *(offsets + [0] * (16 - len(offsets))))
    header += struct.pack("<16I", *(lengths + [0] * (16 - len(lengths))))
    return header + bytes(1024) + b"".join(payloads)


def compare(original, blp_bytes):
    """Errors in 0-255 levels. Pillow expands RGB565 without bit replication (white decodes
    as 248/252/248); graphics cards map it to 255, so the decoded colour is scaled back first."""
    decoded = Image.open(BytesIO(blp_bytes))
    decoded.load()
    a = np.asarray(original.convert("RGBA"), dtype=np.float32)
    b = np.asarray(decoded.convert("RGBA"), dtype=np.float32)
    b[..., 0] = np.minimum(255, b[..., 0] * 255 / 248)
    b[..., 1] = np.minimum(255, b[..., 1] * 255 / 252)
    b[..., 2] = np.minimum(255, b[..., 2] * 255 / 248)
    shows = a[..., 3] > 8
    mean = float(np.abs(a[..., :3] - b[..., :3])[shows].mean()) if shows.any() else 0.0
    aerr = np.abs(a[..., 3] - b[..., 3])
    alpha = int(np.percentile(aerr, 99.9))
    # banding: how coarse the decoded alpha ramp is compared with the original along each row
    da = np.abs(np.diff(b[..., 3], axis=1)).max() if b.shape[1] > 1 else 0
    do = np.abs(np.diff(a[..., 3], axis=1)).max() if a.shape[1] > 1 else 0
    band = int(max(0, da - do))
    return mean, alpha, band, decoded


def main():
    apply = "--apply" in sys.argv
    names = [a for a in sys.argv[1:] if not a.startswith("--")]
    files = [ROOT / n for n in names] if names else sorted(
        p for p in (ROOT / "Media").rglob("*.tga")
        if p.stat().st_size >= MIN_BYTES and not any(x in p.parts for x in ("final-images", "artwork", "interests")))
    scratch = Path(os.environ.get("FGT_SCRATCH", ROOT / "reports" / "texpack"))
    scratch.mkdir(parents=True, exist_ok=True)
    total_before = total_after = 0
    sheet = []
    print(f"{'file':44s} {'before':>8s} {'after':>8s}  fmt   mean  alpha  band  result")
    for path in files:
        img = Image.open(path)
        rgba = img.convert("RGBA")
        arr = np.asarray(rgba)
        uses_alpha = bool(arr[..., 3].min() < 250)
        neutral = bool(uses_alpha is False and np.all(arr[..., 0] == arr[..., 1]) and np.all(arr[..., 1] == arr[..., 2]))
        if neutral:
            # a grey picture drawn additively: white plus alpha (no DXT1 tint)
            white = np.full_like(arr, 255)
            white[..., 3] = arr[..., 0]
            rgba = Image.fromarray(white, "RGBA")
            uses_alpha = True
        blp = encode(rgba, uses_alpha)
        mean, alpha, band, decoded = compare(rgba, blp)
        ok = mean <= LIMITS["mean"] and alpha <= LIMITS["alpha"] and band <= LIMITS["band"]
        before, after = path.stat().st_size, len(blp)
        print(f"{path.relative_to(ROOT).as_posix():44s} {before // 1024:7d}K {after // 1024:7d}K  "
              f"{'DXT5' if uses_alpha else 'DXT1'} {mean:5.2f} {alpha:5d} {band:5d}  {'ok' if ok else 'KEEP TGA'}")
        if ok:
            total_before += before
            total_after += after
            sheet.append((path.stem, rgba, decoded))
            if apply:
                path.with_suffix(".blp").write_bytes(blp)
                path.unlink()
    print(f"converted {len(sheet)} of {len(files)}: {total_before // 1024} KB -> {total_after // 1024} KB")
    if sheet and not apply:
        cell = 220
        out = Image.new("RGB", (cell * 2 + 6, (cell + 4) * len(sheet)), (30, 30, 34))
        for i, (name, before, after) in enumerate(sheet):
            for j, im in enumerate((before, after)):
                bg = Image.new("RGBA", im.size, (60, 60, 66, 255))
                bg.alpha_composite(im.convert("RGBA"))
                t = bg.convert("RGB")
                t.thumbnail((cell, cell))
                out.paste(t, (j * (cell + 6), i * (cell + 4)))
        out.save(scratch / "texpack-compare.jpg", quality=88)
        print("contact sheet:", scratch / "texpack-compare.jpg")


if __name__ == "__main__":
    main()
