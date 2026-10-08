"""Shift painted gold icons to the UI's gold (Karl, 2026-10-07):
  python tools/gold.py <icon.tga> [more.tga ...]
The UI's golds (the heading gold #ffd75e, the bars, the deep gold) sit
at a hue of about 45 degrees; the painted icons came out more orange
(about 37) and a little more saturated. Each icon's colored pixels move
by the same amount, so its mean hue lands on 45 and its mean saturation
on 0.80; brightness and the painted shading stay as they are. Rewrites
the file in place as an uncompressed TGA, top-left origin, like
tools/icon.py (24-bit when fully opaque). Running it again on an icon
that's already shifted changes nothing (its mean is already on target).
Needs Pillow (Mac: pip3 install pillow; PC: pip install --target tools/.py pillow)."""
import colorsys, os, struct, sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
from PIL import Image

HUE, SAT = 45 / 360, 0.80

def colored(r, g, b, a):
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return a >= 128 and s >= 0.25 and v >= 0.25, h, s, v

for path in sys.argv[1:]:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = list(im.getdata())
    hs = ss = n = 0
    for p in px:
        ok, hh, s, v = colored(*p)
        if ok:
            wgt = s * v
            hs += hh * wgt; ss += s * wgt; n += wgt
    if not n:
        print("%s: no gold to shift" % path)
        continue
    dh, ks = HUE - hs / n, SAT / (ss / n)
    out_px = []
    for r, g, b, a in px:
        hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if s > 0.05:  # leave greys, black and white alone
            hh = (hh + dh) % 1
            s = min(1, s * ks)
        rr, gg, bb = colorsys.hsv_to_rgb(hh, s, v)
        out_px.append((round(rr * 255), round(gg * 255), round(bb * 255), a))
    opaque = all(p[3] == 255 for p in out_px)
    data = bytearray(struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h,
                                 24 if opaque else 32, 0x20 if opaque else 0x28))
    for r, g, b, a in out_px:
        data += bytes((b, g, r)) if opaque else bytes((b, g, r, a))
    open(path, "wb").write(data)
    print("%s: hue %+.0f deg, saturation x%.2f" % (os.path.basename(path), dh * 360, ks))
