"""Install Karl's approved Immovable Object, Wand and Mass reviews."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image
import artwork

JOBS = [
    ("immovable_object", "immovable-object-review-v1.png", "immovable-object-master.png", "The Immovable Object"),
    ("wand_of_biting_cold", "wand-of-biting-cold-review-v1.png", "wand-of-biting-cold-master.png", "Wand of Biting Cold"),
    ("mass_of_mcgowan", "mass-of-mcgowan-review-v1.png", "mass-of-mcgowan-master.png", "Mass of McGowan"),
]

FINAL = ROOT / "Media/final-images"
manifest_path = FINAL / "runtime-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
for goal, review, master_name, _ in JOBS:
    master = FINAL / master_name
    banner = ROOT / "Media" / (goal + "-banner.blp")
    assert not master.exists() and not banner.exists() and goal not in manifest, goal
    with Image.open(FINAL / review) as image:
        assert image.width * 3 == image.height * 4, review
        image.convert("L").convert("RGB").resize((1200, 900), Image.Resampling.LANCZOS).save(master)
    info = artwork.compress(master, banner)
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
for _, _, _, title in JOBS:
    page = page.replace(f'  "{title} (both factions)",\n', "", 1)
page = page.replace(
    "var FOUND = [",
    'var FOUND = [\n  "2026-10-29: Approved and installed The Immovable Object, Wand of Biting Cold and Mass of McGowan. Twig of the World Tree v3 awaits approval.",',
    1,
)
page_path.write_text(page, encoding="utf-8", newline="\n")
print("Installed three 1200x900 masters and 512px DXT1 BLPs with ten mip levels.")
