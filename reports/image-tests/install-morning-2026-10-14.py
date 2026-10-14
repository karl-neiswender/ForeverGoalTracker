"""Technical export of Karl's five approved ImageGen previews."""
import sys, json
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'tools'))
import artwork
folder = artwork.FINAL / 'morning-2026-10-14'
approved = {
    'prof_blacksmithing': ('blacksmithing-alliance-review.png', 'blacksmithing-alliance-master.png'),
    'raid_naxx': ('naxxramas-kelthuzad-review-v3.png', 'naxxramas-kelthuzad-master.png'),
    'social_waves': ('social-wave-review.png', 'social-wave-master.png'),
    'social_guild': ('social-guild-review.png', 'social-guild-master.png'),
    'rep_nozdormu': ('brood-nozdormu-review.png', 'brood-nozdormu-master.png'),
}
manifest_path = artwork.FINAL / 'runtime-manifest.json'
manifest = json.loads(manifest_path.read_text())
for goal, (review, master) in approved.items():
    with Image.open(folder / review) as image:
        image.convert('RGB').resize((1200, 900), Image.Resampling.LANCZOS).save(folder / master)
    result = artwork.compress(folder / master, root / 'Media' / (goal + '-banner.blp'))
    result['source'] = 'morning-2026-10-14/' + master
    assert result['mips'] == 10 and result['aspect'] == 4/3
    manifest[goal] = result
    print(goal, result)
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8', newline='\n')
