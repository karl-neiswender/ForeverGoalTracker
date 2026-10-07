"""Turn one of Karl's images (PNG/WebP) into a TGA the addon loads:
  python3 tools/icon.py <image> <name> [WxH] [folder]
Default 128x128 into Media/interests (the wizard's interest icons).
Writes <folder>/<name>.tga and keeps the original as
<folder>/<name>-source.<ext> (left out of the zip by .pkgmeta).
Uses macOS sips to resize; the PNG decode and TGA write are plain Python."""
import os, shutil, struct, subprocess, sys, tempfile, zlib

src, name = sys.argv[1], sys.argv[2]
tw, th = (int(v) for v in (sys.argv[3] if len(sys.argv) > 3 else "128x128").split("x"))
here = os.path.dirname(os.path.abspath(__file__))
out_dir = os.path.join(here, "..", *(sys.argv[4] if len(sys.argv) > 4 else "Media/interests").split("/"))
os.makedirs(out_dir, exist_ok=True)
shutil.copy(src, os.path.join(out_dir, name + "-source" + os.path.splitext(src)[1]))

tmp = os.path.join(tempfile.mkdtemp(), "icon.png")
subprocess.run(["sips", "-s", "format", "png", "-z", str(th), str(tw), src, "--out", tmp], check=True, capture_output=True)
data = open(tmp, "rb").read()
pos, idat = 8, b""
while pos < len(data):
    ln, = struct.unpack(">I", data[pos:pos + 4]); typ = data[pos + 4:pos + 8]; body = data[pos + 8:pos + 8 + ln]; pos += 12 + ln
    if typ == b"IHDR":
        w, h, bd, ct = struct.unpack(">IIBB", body[:10])
        assert bd == 8 and ct in (2, 6), "needs an 8-bit RGB or RGBA image"
    elif typ == b"IDAT":
        idat += body
raw = zlib.decompress(idat); bpp = 4 if ct == 6 else 3; stride = w * bpp; rows = []; prev = bytearray(stride); i = 0
for y in range(h):
    f = raw[i]; i += 1; cur = bytearray(raw[i:i + stride]); i += stride
    for x in range(stride):
        a = cur[x - bpp] if x >= bpp else 0; b = prev[x]; c = prev[x - bpp] if x >= bpp else 0
        if f == 1: cur[x] = (cur[x] + a) & 255
        elif f == 2: cur[x] = (cur[x] + b) & 255
        elif f == 3: cur[x] = (cur[x] + (a + b) // 2) & 255
        elif f == 4:
            p = a + b - c; pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            cur[x] = (cur[x] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
    rows.append(cur); prev = cur
out = bytearray(struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28))
for r in rows:
    for x in range(0, stride, bpp): out += bytes((r[x + 2], r[x + 1], r[x], r[x + 3] if bpp == 4 else 255))
open(os.path.join(out_dir, name + ".tga"), "wb").write(out)
alphas = [(r[x + 3] if bpp == 4 else 255) for r in rows for x in range(0, stride, bpp)]
print("%s.tga: %dx%d, %d see-through pixels, %d solid" % (name, w, h,
      sum(1 for a in alphas if a == 0), sum(1 for a in alphas if a >= 240)))
