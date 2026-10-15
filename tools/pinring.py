"""Draws Media/pin-ring.tga: a thin, crisp white ring that sits around the gold map pin's core
(Maplet.lua) so the pin reads clearly on any map. Plain Python, no Pillow.

    python tools/pinring.py
"""
import math
import os
import struct

SIZE = 64
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media", "pin-ring.tga")

CENTER, HALF_THICK, SOFT = 0.60, 0.065, 0.03   # in half widths

half = (SIZE - 1) / 2.0
rows = []
for y in range(SIZE):
    row = bytearray()
    for x in range(SIZE):
        d = math.hypot(x - half, y - half) / half
        edge = abs(d - CENTER) - HALF_THICK        # < 0 inside the ring's band
        a = min(max(0.5 - edge / SOFT, 0.0), 1.0)  # a soft one pixel edge on both sides
        row += bytes((255, 255, 255, int(round(a * 255))))
    rows.append(bytes(row))

header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
with open(OUT, "wb") as f:
    f.write(header)
    for row in rows:
        f.write(row)
print("wrote", OUT, SIZE, "x", SIZE)
