"""Install only the weapon artwork approved by Karl on 2026-10-25."""
import sys, json, re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image
import artwork
records = json.loads((Path(__file__).with_suffix(".json")).read_text())
final = ROOT / "Media/final-images"
manifest_path = final / "runtime-manifest.json"
manifest = json.loads(manifest_path.read_text())
for r in records:
    master = final / artwork.FINAL_BANNERS[r["id"]]
    master.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(final / r["review"]) as im:
        assert im.width * 3 == im.height * 4
        im.convert("L").resize((1200,900), Image.Resampling.LANCZOS).convert("RGB").save(master)
    manifest[r["id"]] = artwork.compress(master, ROOT / "Media" / (r["id"] + "-banner.blp"))
    manifest[r["id"]]["source"] = artwork.FINAL_BANNERS[r["id"]]
    assert manifest[r["id"]]["mips"] == 10
manifest_path.write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8", newline="\n")
page = ROOT / "reports/Goal-art-checklist.html"
text = page.read_text(encoding="utf-8")
start = text.index("var GOALS = ") + len("var GOALS = ")
end = text.index(";\n", start)
goals = json.loads(text[start:end])
names = {r["name"]:r for r in records}
names["Hyperthermically Insulated Lava Dredger"] = names["Lava Dredger"]
updated = set()
for _, rows in goals:
    for row in rows:
        if row[0] in names:
            r = names[row[0]]
            row[1:4] = ["na" if row[1]=="na" else "share", "done" if row[1]=="na" else "share", r["id"]]
            updated.add(r["id"])
assert len(updated)==20, updated
text = text[:start]+json.dumps(goals, indent=1, ensure_ascii=False)+text[end:]
start = text.index("var FIRST = ") + len("var FIRST = ")
end = text.index(";\n", start)
first = json.loads(text[start:end])
first = [s for s in first if not any(s.startswith(n+" (") for n in names)]
text = text[:start]+json.dumps(first, indent=2, ensure_ascii=False)+text[end:]
page.write_text(text, encoding="utf-8", newline="\n")
print("Installed", len(records), "masters, BLPs and goal checklist entries")
