"""Install Karl's approved hunter, PvP warrior and rogue reviews."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image
import artwork

final = ROOT / "Media/final-images"
jobs = [
    ("allclasses_dwarf_hunter_female", "dwarf-female-hunter-review-2026-10-28-v1.png", "leveling/dwarf-hunter-female-master.png"),
    ("pvp_set_plate_ally_warrior_gnome_female", "gnome-female-warrior-pvp-review-2026-10-28-v1.png", "pvp/gnome-warrior-female-master.png"),
    ("set_tier1_rogue_dwarf_female", "dwarf-female-rogue-tier1-review-2026-10-28-v1.png", "tier-sets/rogue/tier1-dwarf-female-master.png"),
]
manifest_path = final / "runtime-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
for key, review_name, master_name in jobs:
    review = final / review_name
    master = final / master_name
    banner = ROOT / "Media" / (key + "-banner.blp")
    assert not master.exists() and not banner.exists() and key not in manifest, key
    with Image.open(review) as image:
        assert image.width * 3 == image.height * 4, review_name
        master.parent.mkdir(parents=True, exist_ok=True)
        image.convert("L").convert("RGB").resize((1200, 900), Image.Resampling.LANCZOS).save(master)
    info = artwork.compress(master, banner)
    assert info["mips"] == 10 and info["aspect"] == 4 / 3
    info["source"] = master_name
    manifest[key] = info
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
print("Installed three neutral 1200x900 masters and 512px DXT1 BLPs with ten mips.")
