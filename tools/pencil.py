"""Draws Media/pencil.tga: a 64px pencil (white on transparent, tinted in
code) for the goal page's "Edit goal" button. Diagonal, tip at the bottom
left: a pointed tip, the body, a thin gap, then the eraser. Anti-aliased
by sampling each pixel 4 x 4 times.

Run from the repo root:  python tools/pencil.py
"""
import math, os, struct

SIZE, SS = 64, 4
A, B = (10.0, 54.0), (54.0, 10.0)          # tip end, eraser end (y down)
L = math.hypot(B[0] - A[0], B[1] - A[1])
ux, uy = (B[0] - A[0]) / L, (B[1] - A[1]) / L  # along the pencil
vx, vy = -uy, ux                               # across it
HALF_W = 7.0       # half the pencil's thickness
TIP = 15.0         # length of the pointed tip
GAP = (L - 15.0, L - 11.5)  # thin cut between body and eraser

def inside(x, y):
    dx, dy = x - A[0], y - A[1]
    u, v = dx * ux + dy * uy, abs(dx * vx + dy * vy)
    if u < 0 or u > L:
        return False
    if u < TIP:
        return v <= HALF_W * u / TIP
    if GAP[0] <= u <= GAP[1]:
        return False
    return v <= HALF_W

pixels = bytearray()
for y in range(SIZE):
    for x in range(SIZE):
        hits = sum(inside(x + (i + 0.5) / SS, y + (j + 0.5) / SS) for i in range(SS) for j in range(SS))
        pixels += bytes((255, 255, 255, round(255 * hits / (SS * SS))))  # BGRA

# 32-bit TGA, rows top to bottom (same header as tools/icon.py)
header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media", "pencil.tga")
with open(out, "wb") as f:
    f.write(header + bytes(pixels))
print("wrote", out)
