"""Draws Media/shadow.tga: a soft shadow for popups, used as a nine-slice
by FGT.AddDropShadow. The image is a round blur around its center point:
each quarter becomes a rounded corner, the center lines stretch into the
edges, and the middle fills the inside. White with a Gaussian alpha
falloff, tinted black and faded in code.

Run from the repo root:  python tools/shadow.py
"""
import math, os, struct

SIZE = 64
HALF = SIZE / 2
SIGMA = HALF * 0.42  # falloff width: almost gone by the texture's edge

pixels = bytearray()
for y in range(SIZE):
    for x in range(SIZE):
        dist = math.hypot(x + 0.5 - HALF, y + 0.5 - HALF)
        a = math.exp(-((dist / SIGMA) ** 2) / 2)
        pixels += bytes((255, 255, 255, round(a * 255)))  # BGRA

# uncompressed true-color TGA, 32 bits, 8 alpha bits, rows top to bottom
# (0x28: the same header as tools/icon.py, which the game loads fine)
header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media", "shadow.tga")
with open(out, "wb") as f:
    f.write(header + bytes(pixels))
print("wrote", out)
