"""Draws Media/rays.tga: soft light rays fanning out from the center, for
the slow-turning holy light on banner art (B.glows `rays`). White with an
alpha falloff along and across each ray, tinted and faded in code.
Rays of uneven length and width so the turn reads as light, not a wheel.

Run from the repo root:  python tools/rays.py
"""
import math, os, random, struct

SIZE = 256
HALF = SIZE / 2
random.seed(7)  # the same rays every run
RAYS = [(i * 2 * math.pi / 18 + random.uniform(-0.12, 0.12),  # angle
         random.uniform(0.55, 1.0),                              # length (share of radius)
         random.uniform(0.035, 0.08))                            # half width (radians)
        for i in range(18)]

pixels = bytearray()
for y in range(SIZE):
    for x in range(SIZE):
        dx, dy = x + 0.5 - HALF, y + 0.5 - HALF
        r = math.hypot(dx, dy) / HALF
        ang = math.atan2(dy, dx)
        a = 0.0
        for angle, length, width in RAYS:
            d = abs((ang - angle + math.pi) % (2 * math.pi) - math.pi)
            across = math.exp(-((d / width) ** 2))
            along = max(0.0, 1 - r / length) ** 1.6
            a = max(a, across * along)
        a *= min(1.0, r / 0.12)  # leave the very center to the glow
        pixels += bytes((255, 255, 255, round(min(1.0, a) * 255)))  # BGRA

header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media", "rays.tga")
with open(out, "wb") as f:
    f.write(header + bytes(pixels))
print("wrote", out)
