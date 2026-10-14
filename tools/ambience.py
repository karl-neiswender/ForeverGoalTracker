"""Draw the Classic Era stand-ins for Forever's goal-page clouds and leaves.

    python tools/ambience.py [--preview DIR]

Forever's goal page borrows two pieces of Blizzard's talent-window art
(Ambience.lua): "talents-animations-clouds" (1612x774, soft greyscale cloud
noise) and "talents-animations-particles" (1308x774, a sparse sheet of small
curled leaves). Classic Era doesn't have them, so this draws look-alikes of
our own, tuned to numbers measured from Blizzard's sheets on wago.tools
(2026-10-14; only measured there, nothing of theirs is copied or shipped):

  clouds: opaque grey, mean 58.6 and spread 53 (0-255); 41% below 32,
          19.0 / 14.8 / 11.7 / 8.6 / 4.1 / 0.9 / 0% in the next 32-level bands;
          blobs about 100 units across (neighbours 32 units apart correlate
          0.8, 64 apart 0.47, 128 apart about 0); tiles seamlessly left-right.
  leaves: 147 pieces on the sheet; longest side 3 / 7 / 18 units at the
          10th / 50th / 90th percentile, 48 at most; 60% of them in the bottom
          third (bigger, darker, as if nearer); alpha-weighted brightness
          12 typical, 49 for the brightest tenth; the big ones stretched
          2.5-3.5 times longer than wide, curved, lit along one edge, some
          broken in two.

Both are drawn additively and greyscale in game, so each is stored as white
plus alpha (DXT5, mips), alpha = how much light the pixel adds: the same
picture, without DXT1's tinted greys (tools/texpack.py). The textures are
smaller than the shown size (soft art, stretched by the game): clouds
512x256, leaves 1024x512 drawn at 1308x774 first and resized, so leaves keep
their shape once stretched back.
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from texpack import encode  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
CLOUD_SHOWN, LEAF_SHOWN = (1612, 774), (1308, 774)
CLOUD_TEX, LEAF_TEX = (512, 256), (1024, 512)
CLOUD_BANDS = [41.0, 19.0, 14.8, 11.7, 8.6, 4.1, 0.9, 0.0]  # % per 32 levels


def periodic_blur_noise(rng, w, h, sigma):
    """White noise blurred by a Gaussian of `sigma` pixels, wrapping at every edge (FFT)."""
    white = rng.standard_normal((h, w))
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    kernel = np.exp(-2 * (math.pi * sigma) ** 2 * (fx ** 2 + fy ** 2))
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * kernel))
    return (out - out.mean()) / out.std()


def match_bands(values, bands):
    """Map values so their histogram follows `bands` (% per 32 levels), keeping their order."""
    flat = values.ravel()
    order = np.argsort(flat)
    cdf = np.concatenate([[0], np.cumsum(bands) / sum(bands)])
    edges = np.arange(len(bands) + 1) * 32.0
    q = (np.arange(flat.size) + 0.5) / flat.size
    out = np.empty_like(flat)
    out[order] = np.interp(q, cdf, edges)
    return out.reshape(values.shape)


def autocorr(img, lag, axis):
    a = img - img.mean()
    b = np.roll(a, -lag, axis=axis)
    return float((a * b).mean() / a.var())


def clouds(seed=7):
    rng = np.random.default_rng(seed)
    w, h = CLOUD_TEX
    sx = CLOUD_SHOWN[0] / w  # shown units per texture pixel (about 3.1)
    # broad billows (correlation length set by the measured falloff) with finer
    # detail on top, like a painted cloud render
    base = periodic_blur_noise(rng, w, h, 37.0 / sx)
    mid = periodic_blur_noise(rng, w, h, 12.0 / sx)
    fine = periodic_blur_noise(rng, w, h, 3.5 / sx)
    v = base + 0.28 * mid + 0.10 * fine
    grey = match_bands(v, CLOUD_BANDS)
    report = {
        "mean": grey.mean(), "sd": grey.std(),
        "bands": [float(((grey >= i * 32) & (grey < (i + 1) * 32)).mean() * 100) for i in range(8)],
        "ac32": autocorr(grey, round(32 / sx), 1), "ac64": autocorr(grey, round(64 / sx), 1),
        "ac128": autocorr(grey, round(128 / sx), 1),
        # the wrap (last column to first) against any other pair of neighbouring columns
        "seam": float(np.abs(grey[:, 0] - grey[:, -1]).mean()),
        "neighbours": float(np.abs(np.diff(grey, axis=1)).mean()),
    }
    return np.clip(grey, 0, 255).astype(np.uint8), report


def leaf_sprite(rng, length, bright, curl, broken):
    """One curled leaf, RGBA float, about `length` units long, horizontal; lit along its top edge."""
    width = length / rng.uniform(3.0, 4.2) if length > 10 else length / rng.uniform(1.2, 2.2)
    width = max(width, 2.2)  # thinner than that breaks into stray pixels once rotated
    pad = 4
    size = int(math.ceil(length + 2 * pad))
    hgt = int(math.ceil(width + 2 * pad + abs(curl) * length * 0.25))
    hgt += int(width * 0.6)
    y, x = np.mgrid[0:hgt, 0:size].astype(np.float64)
    u = (x - size / 2) / (length / 2)          # -1..1 along the leaf
    bend = curl * (u ** 2) * length * 0.26      # curled into a shallow crescent
    v = (y - hgt / 2 - bend) / (width / 2)      # -1..1 across
    # a torn, curled fragment: blunt ends (sharp tips break off into stray
    # pixels), fuller toward one end, a ragged outline
    if length > 10:
        k1, k2 = rng.uniform(5, 9), rng.uniform(11, 17)
        p1, p2 = rng.uniform(0, 6.3, 2)
        ragged = 1 + 0.08 * np.sin(u * k1 + p1) + 0.05 * np.sin(u * k2 + p2)
        half = np.clip(1 - u ** 2, 0, 1) ** 0.45 * (1 - 0.3 * u) * ragged
    else:  # a small fleck: too small to tear (it falls apart into stray pixels)
        v = (y - hgt / 2) / (width / 2)
        half = np.clip(1 - u ** 2, 0, 1) ** 0.5
    inside = half - np.abs(v)
    # about one pixel of soft edge, and nothing past the ends (else the centre
    # line keeps half strength the whole way across: a hairline)
    a = np.clip(inside * width * 0.5 + 0.5, 0, 1) * np.clip(half * 4, 0, 1)
    if broken:  # a small gap a third of the way along: two fragments
        gap = np.abs(u - rng.uniform(-0.2, 0.4)) < (1.6 / max(4, length) * 2)
        a[gap] = 0
    if length > 10:  # drifting: a slight smear along the leaf
        a = (a + np.roll(a, 1, 1) + np.roll(a, -1, 1)) / 3
    # dark body, the upper edge catching the light
    rim = np.clip(1 - (v + 1) * 1.4, 0, 1) * (a > 0)
    lum = bright * (0.5 + 1.4 * rim)
    rgb = np.stack([lum * 1.35, lum * 0.85, lum * 0.70], -1)  # warm brown before the game greys it
    return np.concatenate([np.clip(rgb, 0, 255), a[..., None] * 255], -1)


def paste(sheet, sprite, cx, cy, angle):
    # (bilinear: bicubic overshoots and leaves detached halo pixels around each leaf)
    img = Image.fromarray(sprite.astype(np.uint8), "RGBA").rotate(angle, resample=Image.Resampling.BILINEAR, expand=True)
    s = np.asarray(img, dtype=np.float64)
    h, w = s.shape[:2]
    x0, y0 = int(cx - w / 2), int(cy - h / 2)
    H, W = sheet.shape[:2]
    xs, ys = max(0, x0), max(0, y0)
    xe, ye = min(W, x0 + w), min(H, y0 + h)
    if xe <= xs or ye <= ys:
        return
    part = s[ys - y0:ye - y0, xs - x0:xe - x0]
    a = part[..., 3:4] / 255
    dst = sheet[ys:ye, xs:xe]
    da = dst[..., 3:4] / 255
    out_a = a + da * (1 - a)
    # straight (not premultiplied) colour, "over" compositing
    dst[..., :3] = np.where(out_a > 0, (part[..., :3] * a + dst[..., :3] * da * (1 - a)) / np.maximum(out_a, 1e-6), 0)
    dst[..., 3:4] = 255 * out_a


def leaves(seed=11):
    rng = np.random.default_rng(seed)
    W, H = LEAF_SHOWN
    sheet = np.zeros((H, W, 4))
    # 142 leaves measure as about 147 pieces (a few are torn in two, a few overlap)
    count = 142
    # rows: 32 / 27 / 88 pieces in the top, middle and bottom thirds
    thirds = [0] * 31 + [1] * 26 + [2] * 85
    rng.shuffle(thirds)
    for third in thirds:
        near = third == 2 and rng.random() < 0.5  # big dark foreground leaves sit low
        if near:
            length = float(np.clip(rng.lognormal(math.log(13), 0.6), 7, 46))
            bright = rng.uniform(26, 42)
        else:
            length = float(np.clip(rng.lognormal(math.log(4.6), 0.5), 3, 20))
            bright = rng.uniform(120, 210) if rng.random() < 0.2 else rng.uniform(22, 46)
        sprite = leaf_sprite(rng, length, bright, rng.uniform(-1, 1), length > 12 and rng.random() < 0.3)
        cx = rng.uniform(0, W)
        cy = rng.uniform(third * H / 3, (third + 1) * H / 3)
        angle = rng.normal(0, 22) if length > 10 else rng.uniform(-90, 90)  # big ones lie flatter
        paste(sheet, sprite, cx, cy, angle)
    return sheet, count


def leaf_report(sheet):
    """The same measures as taken from Blizzard's sheet."""
    a = sheet[..., 3]
    lum = (0.3 * sheet[..., 0] + 0.59 * sheet[..., 1] + 0.11 * sheet[..., 2]) * a / 255
    mask = a > 20
    H, W = mask.shape
    seen = np.zeros_like(mask)
    blobs = []
    for sy, sx in zip(*np.nonzero(mask)):
        if seen[sy, sx]:
            continue
        stack = [(sy, sx)]
        seen[sy, sx] = True
        pts = []
        while stack:
            y, x = stack.pop()
            pts.append((y, x))
            for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        ys, xs = zip(*pts)
        blobs.append((max(max(xs) - min(xs), max(ys) - min(ys)) + 1,
                      float(np.mean([lum[p] for p in pts])), float(np.mean(ys))))
    sizes = sorted(b[0] for b in blobs)
    lums = sorted(b[1] for b in blobs)
    q = lambda arr, f: arr[int(f * (len(arr) - 1))]
    rows = [sum(1 for b in blobs if int(b[2] / H * 3) == i) for i in range(3)]
    return {"count": len(blobs), "size p10/50/90/max": (q(sizes, .1), q(sizes, .5), q(sizes, .9), sizes[-1]),
            "lum p50/p90": (round(q(lums, .5)), round(q(lums, .9))), "rows": rows,
            "coverage %": round(float(mask.mean() * 100), 2)}


def white_alpha(light):
    """RGBA: white, with alpha = the light each pixel adds."""
    a = np.clip(light, 0, 255).astype(np.uint8)
    rgba = np.full(a.shape + (4,), 255, np.uint8)
    rgba[..., 3] = a
    return Image.fromarray(rgba, "RGBA")


def main():
    preview = None
    if "--preview" in sys.argv:
        preview = Path(sys.argv[sys.argv.index("--preview") + 1])
        preview.mkdir(parents=True, exist_ok=True)
    grey, rep = clouds()
    print("clouds  mean %.1f (58.6)  sd %.1f (53.1)  wrap step %.1f vs neighbours %.1f (equal = seamless)"
          % (rep["mean"], rep["sd"], rep["seam"], rep["neighbours"]))
    print("        bands", " / ".join("%.1f" % b for b in rep["bands"]), "(41.0 / 19.0 / 14.8 / 11.7 / 8.6 / 4.1 / 0.9 / 0.0)")
    print("        correlation at 32 / 64 / 128 units: %.2f / %.2f / %.2f (0.80 / 0.47 / 0.00)" % (rep["ac32"], rep["ac64"], rep["ac128"]))
    sheet, _ = leaves()
    print("leaves ", leaf_report(sheet), "(147, 3/7/18/48, 12/49, 32/27/88, 0.59)")
    cloud_img = white_alpha(grey.astype(np.float64))
    lum = (0.3 * sheet[..., 0] + 0.59 * sheet[..., 1] + 0.11 * sheet[..., 2]) * sheet[..., 3] / 255
    leaf_img = white_alpha(lum).resize(LEAF_TEX, Image.Resampling.LANCZOS)
    for name, img in (("ambience-clouds", cloud_img), ("ambience-leaves", leaf_img)):
        data = encode(img, True)
        (ROOT / "Media" / (name + ".blp")).write_bytes(data)
        print("wrote Media/%s.blp  %d KB" % (name, len(data) // 1024))
    if preview:
        Image.fromarray(grey, "L").resize(CLOUD_SHOWN, Image.Resampling.BICUBIC).save(preview / "clouds-shown.png")
        shown = np.clip(lum, 0, 255).astype(np.uint8)
        Image.fromarray(np.clip(shown * 4, 0, 255).astype(np.uint8), "L").save(preview / "leaves-shown-x4.png")
        print("previews in", preview)


if __name__ == "__main__":
    main()
