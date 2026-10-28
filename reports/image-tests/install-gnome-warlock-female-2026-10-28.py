"""Install Karl's approved female Gnome Warlock leveling review."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image
import artwork

final = ROOT / "Media/final-images"
review = final / "gnome-female-warlock-leveling-review-2026-10-28-v1.png"
master = final / "leveling/gnome-warlock-female-master.png"
banner = ROOT / "Media/allclasses_gnome_warlock_female-banner.blp"
key = "allclasses_gnome_warlock_female"
manifest_path = final / "runtime-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
assert not master.exists() and not banner.exists() and key not in manifest
with Image.open(review) as image:
    assert image.width * 3 == image.height * 4
    master.parent.mkdir(parents=True, exist_ok=True)
    image.convert("L").convert("RGB").resize((1200, 900), Image.Resampling.LANCZOS).save(master)
info = artwork.compress(master, banner)
assert info["mips"] == 10 and info["aspect"] == 4 / 3
info["source"] = str(master.relative_to(final)).replace("\\", "/")
manifest[key] = info
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
print("Installed approved female Gnome Warlock review as a 1200x900 master and 512px DXT1 BLP.")
