"""Draws Media/ring.tga: a thin soft white ring on a transparent square, the
ping of the map pin (Maplet.lua). Plain Python, no Pillow needed.

    python tools/ring.py
"""
import math
import os
import struct

SIZE = 128
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media", "ring.tga")

# a ring at 82% of the radius, soft on both edges (Gaussian), fading to nothing
# well before the square's edge so it never clips
RADIUS, SIGMA = 0.80, 0.045

rows = []
half = (SIZE - 1) / 2.0
for y in range(SIZE):
    row = bytearray()
    for x in range(SIZE):
        d = math.hypot(x - half, y - half) / half
        a = math.exp(-((d - RADIUS) ** 2) / (2 * SIGMA ** 2))
        if d > 0.98:
            a = 0.0
        row += bytes((255, 255, 255, int(round(a * 255))))
    rows.append(bytes(row))

# 32-bit uncompressed TGA, origin top left, 8 alpha bits
header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
with open(OUT, "wb") as f:
    f.write(header)
    for row in rows:
        f.write(row)
print("wrote", OUT, SIZE, "x", SIZE)
