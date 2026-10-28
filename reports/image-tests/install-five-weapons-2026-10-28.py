"""Install Karl's approved 2026-10-28 weapon reviews, using Vis'kag v1."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image
import artwork

JOBS = [
    ("might_of_menethil", "might-of-menethil-review-v1.png", "might-of-menethil-master.png", "Might of Menethil"),
    ("sulthraze", "sulthraze-review-v1.png", "sulthraze-master.png", "Sul'thraze the Lasher"),
    ("fiery_war_axe", "fiery-war-axe-review-v1.png", "fiery-war-axe-master.png", "Fiery War Axe"),
    ("viskag", "viskag-bloodletter-review-2026-10-28-v1.png", "viskag-bloodletter-master.png", "Vis'kag the Bloodletter"),
    ("unstoppable_force", "unstoppable-force-review-v1.png", "unstoppable-force-master.png", "The Unstoppable Force"),
]

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
    row = next((row for row in weapons if row[0] == title), None)
    if row is None:
        row = [title, "done", "done", goal]
        index = next((i for i, item in enumerate(weapons) if item[0].lower() > title.lower()), len(weapons))
        weapons.insert(index, row)
    else:
        row[1:4] = ["done", "done", goal]
page = page[:start] + json.dumps(groups, indent=1, ensure_ascii=False) + page[end:]
page = page.replace('var UPDATED = "2026-10-27";', 'var UPDATED = "2026-10-28";', 1)
page = page.replace('  "Vis\'kag the Bloodletter (both factions)",\n', '', 1)
page = page.replace("var FOUND = [", "var FOUND = [\n  \"2026-10-28: Approved and installed five weapon banners: Might of Menethil, Sul'thraze, Fiery War Axe, Vis'kag (first version with person), The Unstoppable Force.\",", 1)
page_path.write_text(page, encoding="utf-8", newline="\n")
print("Installed five neutral 1200x900 masters and decoded 512px DXT1 BLPs with ten mips; Vis'kag uses v1.")
