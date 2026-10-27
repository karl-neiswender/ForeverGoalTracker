"""Install Karl's approved ivory shoulder correction, v4."""
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from PIL import Image
import artwork

def replace(path, old, new):
    p = ROOT / path
    b = p.read_bytes()
    a = old.encode()
    assert b.count(a) == 1, path
    end = b.find(b'\n', b.index(a))
    nl = '\r\n' if b[end-1:end] == b'\r' else '\n'
    p.write_bytes(b.replace(a, new.replace('\n', nl).encode(), 1))

master = ROOT / 'Media/final-images/scarlet-crusade-master.png'
assert not master.exists()
with Image.open(ROOT / 'Media/final-images/scarlet-crusade-review-v4.png') as im:
    im.convert('L').convert('RGB').resize((1200, 900), Image.Resampling.LANCZOS).save(master)
info = artwork.compress(master, ROOT / 'Media/set_scarlet_crusade-banner.blp')
assert info['mips'] == 10
info['source'] = master.name
p = ROOT / 'Media/final-images/runtime-manifest.json'
d = json.loads(p.read_text())
d['set_scarlet_crusade'] = info
p.write_text(json.dumps(d, indent=2)+'\n', encoding='utf-8', newline='\n')
replace('tools/artwork.py', 'FINAL_BANNERS = {', 'FINAL_BANNERS = {\n    "set_scarlet_crusade": "scarlet-crusade-master.png",')
replace('Core.lua', '    B.artVariants.social_chests =', '    B.artVariants.set_scarlet_crusade = {{path="set_scarlet_crusade-banner.blp", aspect=4/3, preprocessed=true}}\n    B.artVariants.social_chests =')
p = ROOT / 'reports/Goal-art-checklist.html'
s = p.read_text(encoding='utf-8')
start = s.index('var GOALS = ') + len('var GOALS = ')
end = s.index(';\n', start)
goals = json.loads(s[start:end])
found = 0
for _, rows in goals:
    for row in rows:
        if 'Scarlet Crusade' in row[0]:
            row[1:4] = ['done', 'done', 'set_scarlet_crusade']
            found += 1
assert found == 1, found
s = s[:start]+json.dumps(goals, indent=1, ensure_ascii=False)+s[end:]
s = '\n'.join(line for line in s.split('\n') if not (line.startswith('  "') and 'Scarlet Crusade (both factions)' in line))
s = s.replace('var FOUND = [', 'var FOUND = [\n  "2026-10-27: Approved and installed set_scarlet_crusade from v4, smooth ivory pointed spikes on image-left shoulder only.",')
p.write_text(s, encoding='utf-8', newline='\n')
p = ROOT / 'reports/image-tests/scarlet-crusade-ivory-review-2026-10-27.json'
d = json.loads(p.read_text())
d['status'] = 'Approved by Karl: yes good. Installed 2026-10-27. Full restart and native visual review pending.'
d['runtime'] = info
p.write_text(json.dumps(d, indent=2)+'\n', encoding='utf-8', newline='\n')
print('Installed Scarlet Crusade v4: neutral 1200x900 master, 512px DXT1 BLP, ten mip levels.')
