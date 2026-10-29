"""Install Karl's approved spiked Twig of the World Tree review."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image
import artwork

goal = "twig_of_the_world_tree"
review = "twig-of-the-world-tree-review-v4.png"
master_name = "twig-of-the-world-tree-master.png"
final = ROOT / "Media/final-images"
master = final / master_name
banner = ROOT / "Media" / (goal + "-banner.blp")
manifest_path = final / "runtime-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
assert not master.exists() and not banner.exists() and goal not in manifest
with Image.open(final / review) as image:
    assert image.width * 3 == image.height * 4
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
row = next(row for row in weapons if row[0] == "Twig of the World Tree")
row[1:4] = ["done", "done", goal]
page = page[:start] + json.dumps(groups, indent=1, ensure_ascii=False) + page[end:]
page = page.replace('  "Twig of the World Tree (both factions)",\n', "", 1)
page = page.replace(
    "var FOUND = [",
    'var FOUND = [\n  "2026-10-29: Approved and installed Twig of the World Tree v4 with spikes added to the original wrapped wooden head.",',
    1,
)
page_path.write_text(page, encoding="utf-8", newline="\n")
print("Installed Twig 1200x900 master and 512px DXT1 BLP with ten mip levels.")
