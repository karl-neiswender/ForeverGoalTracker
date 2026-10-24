"""Turn a dressing-room review PNG into the runtime texture the Gear Planner loads.
  python tools/backdrop_tga.py Media/artwork/dressing-room/skyborne-bw.png Media/dressing-room/Skyborne.tga
The review PNGs are 1143 x 1376 grayscale; the runtime files are opaque 1024 x 1024 RGB TGAs (24-bit,
uncompressed, the same as the eight installed races). The layout stretches the square back to the
318:383 portrait, so the picture is squeezed here exactly as the shipped ones were.
Needs Pillow (PC: pip install --target tools/.py pillow)."""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
from PIL import Image

if len(sys.argv) != 3:
    sys.exit(__doc__)
src, dst = sys.argv[1], sys.argv[2]
img = Image.open(src).convert("RGB").resize((1024, 1024), Image.LANCZOS)
img.save(dst, format="TGA")
out = Image.open(dst)
print("%s -> %s (%dx%d %s)" % (os.path.basename(src), dst, out.width, out.height, out.mode))
