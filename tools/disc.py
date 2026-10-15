"""Draws Media/disc.tga: a small crisp white disc with a one pixel soft edge and no glow, for the
map zoom slider's dot (Maplet.lua). Plain Python, no Pillow.

    python tools/disc.py
"""
import math
import os
import struct

SIZE = 32
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media", "disc.tga")

half = (SIZE - 1) / 2.0
radius = half * 0.92
rows = []
for y in range(SIZE):
    row = bytearray()
    for x in range(SIZE):
        d = math.hypot(x - half, y - half)
        a = min(max(radius + 0.5 - d, 0.0), 1.0)
        row += bytes((255, 255, 255, int(round(a * 255))))
    rows.append(bytes(row))

header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
with open(OUT, "wb") as f:
    f.write(header)
    for row in rows:
        f.write(row)
print("wrote", OUT, SIZE, "x", SIZE)
