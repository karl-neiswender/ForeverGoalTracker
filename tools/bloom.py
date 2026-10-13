"""Bake a bloom layer for a banner master: light that spills from its brightest parts.

    python tools/bloom.py <master image> <Media/name-bloom.tga> [--preview out.jpg] [--strength 0.6]

Keeps only the brightest pixels of the master (the bolt cores, flames, gems),
blurs them at two sizes (a tight halo hugging the source and a wide soft one)
and writes a small grayscale texture, 256x256 stretched like the banners
themselves (the addon restores the aspect), to be drawn additively over the
banner. Brighter parts bloom more, in a power curve, and the picture's own
shape decides where, so nothing needs placing by hand. Monochrome only.

--preview writes a before/after of the master with the bloom added at the given
strength, to judge it before it goes in game.
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

SIZE = 256


def smoothstep(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)


def bake(master, near=5.0, far=30.0, floor=0.60, power=1.7, mix=(0.70, 0.60)):
    """Returns the bloom as a float array 0..1 at the master's own size."""
    img = Image.open(master).convert("L")
    w, h = img.size
    scale = w / 1200.0  # radii are given for a 1200px wide master
    lum = np.asarray(img, dtype=np.float32) / 255.0
    white = float(np.percentile(lum, 99.6))
    # only what is close to the picture's own white point counts as light
    core = smoothstep((lum / max(white, 1e-3) - floor) / (1.0 - floor)) ** power
    core_img = Image.fromarray((core * 255).astype(np.uint8))
    small = np.asarray(core_img.filter(ImageFilter.GaussianBlur(near * scale)), dtype=np.float32) / 255.0
    large = np.asarray(core_img.filter(ImageFilter.GaussianBlur(far * scale)), dtype=np.float32) / 255.0
    bloom = mix[0] * small + mix[1] * large
    bloom = bloom / max(float(np.percentile(bloom, 99.8)), 1e-3)
    return np.clip(bloom, 0.0, 1.0), lum


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("master")
    ap.add_argument("out")
    ap.add_argument("--preview")
    ap.add_argument("--strength", type=float, default=0.6)
    ap.add_argument("--near", type=float, default=5.0)
    ap.add_argument("--far", type=float, default=30.0)
    ap.add_argument("--floor", type=float, default=0.60)
    ap.add_argument("--power", type=float, default=1.7)
    args = ap.parse_args()

    bloom, lum = bake(args.master, args.near, args.far, args.floor, args.power)
    small = Image.fromarray((bloom * 255).astype(np.uint8)).resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    arr = np.asarray(small, dtype=np.float32)
    # a touch of dither so the smooth falloff doesn't band in 8 bits
    rng = np.random.default_rng(7)
    arr = np.clip(arr + rng.triangular(-1, 0, 1, arr.shape), 0, 255).astype(np.uint8)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr).convert("RGB").save(out)  # uncompressed 24-bit TGA
    print(f"{out} {out.stat().st_size // 1024} KB; bloom mean {bloom.mean():.3f}, max {bloom.max():.2f}")

    if args.preview:
        base = Image.open(args.master).convert("RGB")
        up = np.asarray(small.resize(base.size, Image.Resampling.BICUBIC), dtype=np.float32) / 255.0
        b = np.asarray(base, dtype=np.float32) / 255.0
        lit = np.clip(b + args.strength * 0.5 * up[..., None], 0, 1)  # in game the layer is drawn at about half strength
        both = Image.new("RGB", (base.width * 2 + 8, base.height), (10, 10, 12))
        both.paste(base, (0, 0))
        both.paste(Image.fromarray((lit * 255).astype(np.uint8)), (base.width + 8, 0))
        both.thumbnail((2000, 1000), Image.Resampling.LANCZOS)
        both.save(args.preview, quality=88)
        print("preview", args.preview)


if __name__ == "__main__":
    main()
