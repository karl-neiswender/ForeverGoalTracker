"""Bake a bloom layer for a banner master: light that spills from its brightest parts.

    python tools/bloom.py <master image> <Media/name-bloom.blp> [--preview out.jpg] [--strength 0.6]

Keeps only the brightest pixels of the master (the bolt cores, flames, gems),
blurs them at two sizes (a tight halo hugging the source and a wide soft one)
and writes a small texture, 256x256 stretched like the banners themselves (the
addon restores the aspect), to be drawn additively over the banner. Brighter
parts bloom more, in a power curve, and the picture's own shape decides where,
so nothing needs placing by hand. Monochrome only.

The texture is white with the bloom in its alpha channel (BLP2, DXT5, full mip
chain): additive blending multiplies colour by alpha, so this looks exactly like
a grey image, but needs no RGB565 colour (which tints greys) and the alpha is
encoded by tools/bloom.py itself with the best two endpoints per 4x4 block, far
cleaner than a generic encoder on a smooth glow. About 87 KB. Ending the output
name in .tga writes the older uncompressed grey TGA instead.

--preview writes a before/after of the master with the bloom added at the given
strength, to judge it before it goes in game.
"""
import argparse
import struct
from io import BytesIO
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

SIZE = 256


def smoothstep(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)


def bake(master, near=5.0, far=30.0, floor=0.60, power=1.7, mix=(0.70, 0.60), region=None):
    """Returns the bloom as a float array 0..1 at the master's own size.

    region: optional list of (u0, u1, v0, v1) boxes (fractions of the master). When given,
    only light inside them blooms (the boxes have soft edges), for a banner where one spot
    should glow, such as a staff's gem, a mount's eyes or a pair of shoulders.
    """
    img = Image.open(master).convert("L")
    w, h = img.size
    scale = w / 1200.0  # radii are given for a 1200px wide master
    lum = np.asarray(img, dtype=np.float32) / 255.0
    white = float(np.percentile(lum, 99.6))
    # only what is close to the picture's own white point counts as light
    core = smoothstep((lum / max(white, 1e-3) - floor) / (1.0 - floor)) ** power
    if region:
        keep = np.zeros((h, w), dtype=np.float32)
        for u0, u1, v0, v1 in region:
            keep[int(v0 * h):int(v1 * h), int(u0 * w):int(u1 * w)] = 1.0
        keep = np.asarray(Image.fromarray((keep * 255).astype(np.uint8)).filter(
            ImageFilter.GaussianBlur(0.012 * w)), dtype=np.float32) / 255.0
        core = core * keep
    core_img = Image.fromarray((core * 255).astype(np.uint8))
    small = np.asarray(core_img.filter(ImageFilter.GaussianBlur(near * scale)), dtype=np.float32) / 255.0
    large = np.asarray(core_img.filter(ImageFilter.GaussianBlur(far * scale)), dtype=np.float32) / 255.0
    bloom = mix[0] * small + mix[1] * large
    bloom = bloom / max(float(np.percentile(bloom, 99.8)), 1e-3)
    return np.clip(bloom, 0.0, 1.0), lum


def dxt5_alpha_blocks(alpha):
    """DXT5 bytes for an alpha plane (uint8, any size >= 1): white colour, the given alpha.

    Per 4x4 block: alpha endpoints are the block's max and min, the 8-value mode
    interpolates six values between them, and every texel takes the nearest of the
    eight. For a smooth glow a block's range is small, so the error is a level or two.
    """
    h, w = alpha.shape
    bw, bh = max(1, (w + 3) // 4), max(1, (h + 3) // 4)
    padded = np.pad(alpha, ((0, bh * 4 - h), (0, bw * 4 - w)), mode="edge").astype(np.int32)
    blocks = padded.reshape(bh, 4, bw, 4).transpose(0, 2, 1, 3).reshape(bh * bw, 16)
    a0 = blocks.max(axis=1)
    a1 = blocks.min(axis=1)
    pal = np.empty((len(blocks), 8), dtype=np.float32)
    pal[:, 0], pal[:, 1] = a0, a1
    for k in range(1, 7):
        pal[:, k + 1] = ((7 - k) * a0 + k * a1) / 7.0
    idx = np.abs(blocks[:, :, None].astype(np.float32) - pal[:, None, :]).argmin(axis=2).astype(np.uint64)
    bits = np.zeros(len(blocks), dtype=np.uint64)
    for t in range(16):
        bits |= idx[:, t] << np.uint64(3 * t)
    out = bytearray()
    for i in range(len(blocks)):
        out += struct.pack("<BB", int(a0[i]), int(a1[i]))
        out += int(bits[i]).to_bytes(8, "little")[:6]
        out += struct.pack("<HHI", 0xFFFF, 0xFFFF, 0)  # white; every texel takes colour 0
    return bytes(out)


def encode_blp(alpha):
    """A BLP2 (DXT5, mips down to 1x1) whose colour is white and whose alpha is `alpha`."""
    h, w = alpha.shape
    levels = [alpha.astype(np.uint8)]
    cur = alpha.astype(np.float32)
    while cur.shape[0] > 1 or cur.shape[1] > 1:
        nh, nw = max(1, cur.shape[0] // 2), max(1, cur.shape[1] // 2)
        trimmed = cur[:nh * 2, :nw * 2] if cur.shape[0] > 1 and cur.shape[1] > 1 else cur
        if cur.shape[0] > 1 and cur.shape[1] > 1:
            cur = trimmed.reshape(nh, 2, nw, 2).mean(axis=(1, 3))
        elif cur.shape[0] > 1:
            cur = cur[:nh * 2].reshape(nh, 2, nw).mean(axis=1)
        else:
            cur = cur[:, :nw * 2].reshape(nh, nw, 2).mean(axis=2)
        levels.append(np.round(cur).astype(np.uint8))
    payloads = [dxt5_alpha_blocks(level) for level in levels]
    offset = 148 + 1024
    offsets, lengths = [], []
    for block in payloads:
        offsets.append(offset)
        lengths.append(len(block))
        offset += len(block)
    header = struct.pack("<4sI4BII", b"BLP2", 1, 2, 8, 7, 1, w, h)
    header += struct.pack("<16I", *(offsets + [0] * (16 - len(offsets))))
    header += struct.pack("<16I", *(lengths + [0] * (16 - len(lengths))))
    return header + bytes(1024) + b"".join(payloads)


def alpha_error(blp_bytes, alpha):
    """Largest and mean difference between the encoded alpha (decoded again) and the original."""
    decoded = Image.open(BytesIO(blp_bytes))
    decoded.load()
    got = np.asarray(decoded.convert("RGBA"))[..., 3].astype(np.int32)
    diff = np.abs(got - alpha.astype(np.int32))
    return int(diff.max()), float(diff.mean())


def bloom_alpha(master, **kw):
    bloom, lum = bake(master, **kw)
    small = Image.fromarray((bloom * 255).astype(np.uint8)).resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    return np.asarray(small, dtype=np.uint8), bloom


def preview(master, alpha, strength, out, size=(2000, 1000)):
    base = Image.open(master).convert("RGB")
    up = np.asarray(Image.fromarray(alpha).resize(base.size, Image.Resampling.BICUBIC), dtype=np.float32) / 255.0
    b = np.asarray(base, dtype=np.float32) / 255.0
    lit = np.clip(b + strength * 0.5 * up[..., None], 0, 1)  # in game the layer is drawn at about half strength
    both = Image.new("RGB", (base.width * 2 + 8, base.height), (10, 10, 12))
    both.paste(base, (0, 0))
    both.paste(Image.fromarray((lit * 255).astype(np.uint8)), (base.width + 8, 0))
    both.thumbnail(size, Image.Resampling.LANCZOS)
    both.save(out, quality=88)


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

    alpha, bloom = bloom_alpha(args.master, near=args.near, far=args.far, floor=args.floor, power=args.power)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.suffix.lower() == ".blp":
        data = encode_blp(alpha)
        out.write_bytes(data)
        worst, mean = alpha_error(data, alpha)
        print(f"{out} {out.stat().st_size // 1024} KB; alpha error max {worst}, mean {mean:.2f}; bloom mean {bloom.mean():.3f}")
    else:
        rng = np.random.default_rng(7)
        grey = np.clip(alpha.astype(np.float32) + rng.triangular(-1, 0, 1, alpha.shape), 0, 255).astype(np.uint8)
        Image.fromarray(grey).convert("RGB").save(out)  # uncompressed 24-bit TGA
        print(f"{out} {out.stat().st_size // 1024} KB; bloom mean {bloom.mean():.3f}")
    if args.preview:
        preview(args.master, alpha, args.strength, args.preview)
        print("preview", args.preview)


if __name__ == "__main__":
    main()
