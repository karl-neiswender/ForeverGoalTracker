"""Crop the gallery screenshots that /goals shots took and name them.
  python tools/shots.py [game Screenshots folder]
Finds the newest burst of screenshots in the game's Screenshots folder
(taken a few seconds apart by /goals shots, in gallery order), crops each
to the addon window (the black photo backdrop around it makes that easy)
and saves them as Screenshots/01-my-goals.png ... in the repo.
Needs Pillow (Mac: pip3 install pillow; PC: pip install --target tools/.py pillow)."""
import glob, os, sys

# same order as FGT.SHOTS in Core.lua
NAMES = ["01-my-goals", "02-new-and-updated", "03-epic-mounts", "04-links-and-tips",
         "05-find-your-next-goal", "06-welcome", "07-suggestions", "08-settings"]

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
from PIL import Image

candidates = sys.argv[1:] or [
    os.path.join(here, "..", "..", "..", "..", "Screenshots"),          # PC: repo sits in AddOns
    "/Applications/World of Warcraft/_classic_beta_/Screenshots",      # Mac
]
folder = next((c for c in candidates if os.path.isdir(c)), None)
if not folder:
    sys.exit("Couldn't find the game's Screenshots folder. Pass it: python tools/shots.py <folder>")

files = []
for ext in ("tga", "jpg", "jpeg", "png"):
    files += glob.glob(os.path.join(folder, "WoWScrnShot_*." + ext))
files.sort(key=os.path.getmtime)
if not files:
    sys.exit("No screenshots in " + os.path.abspath(folder) + ". Run /goals shots in game first.")

# the newest burst: files no more than 20 s apart, counting back from the last
burst = [files[-1]]
for f in reversed(files[:-1]):
    if os.path.getmtime(burst[0]) - os.path.getmtime(f) > 20:
        break
    burst.insert(0, f)
if len(burst) != len(NAMES):
    print("Warning: the newest burst has %d screenshots, expected %d. Using the last %d."
          % (len(burst), len(NAMES), min(len(burst), len(NAMES))))
burst = burst[-len(NAMES):]
names = NAMES[:len(burst)] if len(burst) == len(NAMES) else NAMES[len(NAMES) - len(burst):]

out_dir = os.path.join(here, "..", "Screenshots")
os.makedirs(out_dir, exist_ok=True)
for src, name in zip(burst, names):
    img = Image.open(src).convert("RGB")
    # The window is the big bright block on the black backdrop: keep the
    # columns and rows where a good share of pixels are lit, so small
    # things outside it (the beta's Issue Reporter button, a tooltip from
    # the mouse resting on a character) don't widen the crop.
    mask = img.convert("L").point(lambda v: 255 if v > 12 else 0)
    cols = list(mask.resize((mask.width, 1), Image.BOX).getdata())
    rows = list(mask.resize((1, mask.height), Image.BOX).getdata())
    def span(vals):
        cut = max(vals) * 0.4
        lit = [i for i, v in enumerate(vals) if v >= cut]
        return (lit[0], lit[-1] + 1) if lit else None
    cx, cy = span(cols), span(rows)
    box = (cx[0], cy[0], cx[1], cy[1]) if cx and cy else None
    if not box:
        print("  %s: all black, skipped" % os.path.basename(src))
        continue
    out = os.path.join(out_dir, name + ".png")
    img.crop(box).save(out, optimize=True)
    print("  %s -> Screenshots/%s.png (%dx%d)" % (os.path.basename(src), name, box[2] - box[0], box[3] - box[1]))
