"""Slice Karl's transparent gold/silver refresh pair into the 64px UI icons.

Usage: python tools/refresh.py <image> [name]
Name defaults to refresh; also supports other side-by-side gold/silver pairs.
Then: python tools/gold.py Media/icons/<name>.tga
Uses the same outline crop, padding and TGA format as tools/sheet.py.
"""
import os
import shutil
import struct
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, '.py'))
from PIL import Image

src = sys.argv[1]
name_base = sys.argv[2] if len(sys.argv) > 2 else 'refresh'
out = os.path.join(here, '..', 'Media', 'icons')
keep = os.path.join(out, name_base + '-source.png')
if os.path.abspath(src) != os.path.abspath(keep):
    shutil.copyfile(src, keep)
sheet = Image.open(src).convert('RGBA')
w, h = sheet.size
for i, name in enumerate((name_base, name_base + '-white')):
    cell = sheet.crop((i * w // 2, 0, (i + 1) * w // 2, h))
    box = cell.getchannel('A').point(lambda v: 255 if v > 16 else 0).getbbox()
    icon = cell.crop(box)
    scale = 58 / max(icon.size)
    icon = icon.resize(tuple(max(1, round(n * scale)) for n in icon.size), Image.Resampling.LANCZOS)
    square = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    # Paste without a mask to preserve the source alpha, including soft edges.
    square.paste(icon, ((64 - icon.width) // 2, (64 - icon.height) // 2))
    data = bytearray(struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, 64, 64, 32, 0x28))
    for r, g, b, a in square.getdata():
        data += bytes((b, g, r, a))
    with open(os.path.join(out, name + '.tga'), 'wb') as f:
        f.write(data)
    print(name + ': 64x64, transparent')
