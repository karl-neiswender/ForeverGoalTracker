"""Draw a labelled u,v grid over a banner master so light positions can be read off.

    python tools/gridview.py <master image> <out.jpg> [step] [u0 u1 v0 v1]

u runs left to right and v top to bottom, as fractions of the master (the
numbers B.glows uses). With a window (u0 u1 v0 v1) it crops first and the
labels still show the full-image fractions. Default step 0.1.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

src, out = sys.argv[1], sys.argv[2]
step = float(sys.argv[3]) if len(sys.argv) > 3 else 0.1
u0, u1, v0, v1 = (float(x) for x in sys.argv[4:8]) if len(sys.argv) >= 8 else (0, 1, 0, 1)
im = Image.open(src).convert("RGB")
W, H = im.size
im = im.crop((int(u0 * W), int(v0 * H), int(u1 * W), int(v1 * H)))
scale = 1100 / im.width
im = im.resize((1100, int(im.height * scale)), Image.LANCZOS)
d = ImageDraw.Draw(im)
font = ImageFont.load_default()
n = 0
while n * step <= 1.0001:
    f = n * step
    if u0 <= f <= u1:
        x = (f - u0) / (u1 - u0) * im.width
        d.line((x, 0, x, im.height), fill=(255, 80, 80), width=1)
        d.text((x + 2, 2), f"{f:.2f}", fill=(255, 200, 200), font=font)
    if v0 <= f <= v1:
        y = (f - v0) / (v1 - v0) * im.height
        d.line((0, y, im.width, y), fill=(80, 160, 255), width=1)
        d.text((2, y + 2), f"{f:.2f}", fill=(200, 220, 255), font=font)
    n += 1
im.save(out, quality=88)
