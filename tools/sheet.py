"""Slices Karl's 4 x 4 UI icon sheet into separate TGAs the addon loads:
  python tools/sheet.py <sheet image> [suffix]
Writes Media/icons/<name><suffix>.tga (64 x 64, 32-bit) for the 16 icons
below, in reading order, and keeps the sheet as
Media/icons/sheet<suffix>-source.<ext> (left out of the zip by .pkgmeta).
Suffix: "" for the gold set, "-white" for the recolorable set.

Each icon is cut out by its own outline (alpha), not by the grid, then
centered in the square with a little padding, so icons that sit off
center or run large on the sheet still come out even. Needs Pillow in
tools/.py (pip install --target tools/.py pillow).
"""
import os, shutil, struct, sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
from PIL import Image

NAMES = ["gear", "close", "pencil", "star",
         "check", "lock", "pin", "link",
         "plus", "minus", "search", "trash",
         "undo", "chevron", "bubble", "bell"]
SIZE, PAD = 64, 3  # output square, empty pixels kept on each side

src = sys.argv[1]
suffix = sys.argv[2] if len(sys.argv) > 2 else ""
out_dir = os.path.join(here, "..", "Media", "icons")
os.makedirs(out_dir, exist_ok=True)
keep = os.path.join(out_dir, "sheet" + suffix + "-source" + os.path.splitext(src)[1])
if os.path.abspath(src) != os.path.abspath(keep):
    shutil.copy(src, keep)

sheet = Image.open(src).convert("RGBA")
W, H = sheet.size
cw, ch = W / 4, H / 4
for i, name in enumerate(NAMES):
    r, c = divmod(i, 4)
    cell = sheet.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))
    # the icon's own outline: pixels that are more than faintly visible
    box = cell.getchannel("A").point(lambda v: 255 if v > 16 else 0).getbbox()
    icon = cell.crop(box)
    inner = SIZE - 2 * PAD
    scale = inner / max(icon.size)
    icon = icon.resize((max(1, round(icon.size[0] * scale)), max(1, round(icon.size[1] * scale))), Image.LANCZOS)
    square = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    square.paste(icon, ((SIZE - icon.size[0]) // 2, (SIZE - icon.size[1]) // 2), icon)
    # 32-bit TGA, rows top to bottom (same header as tools/icon.py)
    data = bytearray(struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28))
    for y in range(SIZE):
        for x in range(SIZE):
            rr, gg, bb, aa = square.getpixel((x, y))
            data += bytes((bb, gg, rr, aa))
    open(os.path.join(out_dir, name + suffix + ".tga"), "wb").write(data)
    print("%-8s %dx%d from %s" % (name + suffix, SIZE, SIZE, box))
