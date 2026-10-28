"""Install approved card-art weapon banners, preserving their source images."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image
import artwork

JOBS = [
    ("core_hound_tooth", "core-hound-tooth-review-2026-10-28-v1.png", "core-hound-tooth-master.png", "Core Hound Tooth"),
    ("bloodseeker", "bloodseeker-review-2026-10-28-v1.png", "bloodseeker-master.png", "Bloodseeker"),
    ("blackcrow", "blackcrow-review-2026-10-28-v1.png", "blackcrow-master.png", "Blackcrow"),
]
if "--brutality-v1" in sys.argv or "--brutality-v2" in sys.argv:
    version = "v1" if "--brutality-v1" in sys.argv else "v2"
    JOBS = [("brutality_blade", f"brutality-blade-review-2026-10-28-{version}.png", "brutality-blade-master.png", "Brutality Blade")]

FINAL = ROOT / "Media/final-images"
manifest_path = FINAL / "runtime-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
for goal, review, master_name, _ in JOBS:
    master = FINAL / master_name
    assert not master.exists() and goal not in manifest, goal
    with Image.open(FINAL / review) as image:
        assert image.width * 3 == image.height * 4, review
        image.convert("L").convert("RGB").resize((1200, 900), Image.Resampling.LANCZOS).save(master)
    info = artwork.compress(master, ROOT / "Media" / (goal + "-banner.blp"))
    assert info["mips"] == 10 and info["aspect"] == 4 / 3
    info["source"] = master_name
    manifest[goal] = info
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

page_path = ROOT / "reports/Goal-art-checklist.html"
page = page_path.read_text(encoding="utf-8")
start = page.index("var GOALS = ") + len("var GOALS = ")
end = page.index(";\n", start)
groups = json.loads(page[start:end])
weapons = next(rows for label, rows in groups if label == "Legendary and epic weapons")
for goal, _, _, title in JOBS:
    row = next(row for row in weapons if row[0] == title)
    row[1:4] = ["done", "done", goal]
page = page[:start] + json.dumps(groups, indent=1, ensure_ascii=False) + page[end:]
first_start = page.index("var FIRST = [")
first_end = page.index("];", first_start)
first = page[first_start:first_end]
for _, _, _, title in JOBS:
    first = first.replace(f'  "{title}",\n', "", 1)
page = page[:first_start] + first + page[first_end:]
names = ", ".join(title for _, _, _, title in JOBS)
page = page.replace("var FOUND = [", f'var FOUND = [\n  "2026-10-28: Approved and installed weapon banners: {names}.",', 1)
page_path.write_text(page, encoding="utf-8", newline="\n")
print(f"Installed {len(JOBS)} neutral 1200x900 masters and 512px DXT1 BLPs with ten mips.")
