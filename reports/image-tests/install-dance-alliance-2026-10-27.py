"""Install the Alliance Dance review approved by Karl."""
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from PIL import Image
import artwork

def replace(path, old, new):
    p = ROOT / path
    data = p.read_bytes()
    newline = '\r\n' if b'\r\n' in data else '\n'
    old, new = (s.replace('\n', newline).encode() for s in (old, new))
    assert data.count(old) == 1, path
    p.write_bytes(data.replace(old, new, 1))

master = ROOT / 'Media/final-images/dance-alliance-master.png'
with Image.open(ROOT / 'Media/final-images/dance-alliance-review-v1.png') as im:
    im.convert('L').convert('RGB').resize((1200, 900), Image.Resampling.LANCZOS).save(master)
info = artwork.compress(master, ROOT / 'Media/social_dances_alliance-banner.blp')
assert info['mips'] == 10
info['source'] = master.name
p = ROOT / 'Media/final-images/runtime-manifest.json'
manifest = json.loads(p.read_text())
manifest['social_dances_alliance'] = info
p.write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8', newline='\n')
replace('tools/artwork.py', 'FINAL_BANNERS = {', 'FINAL_BANNERS = {\n    "social_dances_alliance": "dance-alliance-master.png",')
replace('Core.lua', '    B.artVariants.social_dances = {{path="social_dances_horde-banner.blp", faction="Horde", aspect=4/3, preprocessed=true}}', '''    B.artVariants.social_dances = {
        {path="social_dances_alliance-banner.blp", faction="Alliance", aspect=4/3, preprocessed=true},
        {path="social_dances_horde-banner.blp", faction="Horde", aspect=4/3, preprocessed=true},
    }''')
p = ROOT / 'reports/Goal-art-checklist.html'
s = p.read_text(encoding='utf-8')
start = s.index('var GOALS = ') + len('var GOALS = ')
end = s.index(';\n', start)
goals = json.loads(s[start:end])
for _, rows in goals:
    for row in rows:
        if row[0] == 'Dance':
            row[1:4] = ['done', 'done', 'Alliance: social_dances_alliance; Horde: social_dances_horde']
s = s[:start] + json.dumps(goals, indent=1, ensure_ascii=False) + s[end:]
s = s.replace('  "Dance (Alliance)",\n', '')
s = s.replace('var FOUND = [', 'var FOUND = [\n  "2026-10-27: Approved and installed social_dances_alliance. Dance now has dedicated artwork for both factions.",')
p.write_text(s, encoding='utf-8', newline='\n')
p = ROOT / 'reports/image-tests/dance-alliance-review-2026-10-27.json'
d = json.loads(p.read_text())
d['status'] = 'Approved by Karl: good. Installed 2026-10-27; full game restart and native review pending.'
d['runtime'] = info
p.write_text(json.dumps(d, indent=2)+'\n', encoding='utf-8', newline='\n')
print('Installed Alliance Dance: 1200x900 neutral master, 512px DXT1 BLP, ten mip levels.')
