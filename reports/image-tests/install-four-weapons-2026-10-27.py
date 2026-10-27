"""Install four weapon banner reviews approved by Karl."""
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from PIL import Image
import artwork

def replace(path, old, new):
    p = ROOT / path
    data = p.read_bytes()
    # Match the actual line ending at this anchor, including mixed-ending files.
    anchor = old.encode('utf-8')
    assert data.count(anchor) == 1, path
    pos = data.index(anchor)
    end = data.find(b'\n', pos)
    newline = '\r\n' if end > 0 and data[end-1:end] == b'\r' else '\n'
    p.write_bytes(data.replace(anchor, new.replace('\n', newline).encode('utf-8'), 1))

jobs = [
    ('widows_remorse', 'widows-remorse', "Widow's Remorse", 'Craig Elliott'),
    ('lobotomizer', 'the-lobotomizer', 'The Lobotomizer', 'Michael Sutfin'),
    ('demonslayer', 'demonslayer', 'Demonslayer', None),
    ('claw_of_the_black_drake', 'claw-of-the-black-drake', 'Claw of the Black Drake', None),
]
p = ROOT / 'Media/final-images/runtime-manifest.json'
manifest = json.loads(p.read_text())
for goal, review, name, artist in jobs:
    master = ROOT / 'Media/final-images' / (review + '-master.png')
    assert not master.exists(), master
    with Image.open(ROOT / 'Media/final-images' / (review + '-review-v1.png')) as im:
        im.convert('L').convert('RGB').resize((1200, 900), Image.Resampling.LANCZOS).save(master)
    info = artwork.compress(master, ROOT / 'Media' / (goal + '-banner.blp'))
    assert info['mips'] == 10
    info['source'] = master.name
    manifest[goal] = info
replace('tools/artwork.py', 'FINAL_BANNERS = {', 'FINAL_BANNERS = {\n' + '\n'.join('    "' + goal + '": "' + review + '-master.png",' for goal, review, _, _ in jobs))
p.write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8', newline='\n')
replace('Core.lua', '    B.artVariants.social_chests =', '\n'.join('    B.artVariants.' + goal + ' = {{path="' + goal + '-banner.blp", aspect=4/3, preprocessed=true}}' for goal, _, _, _ in jobs) + '\n    B.artVariants.social_chests =')
replace('Core.lua', '    B.artArtists = {', '    B.artArtists = {\n' + '\n'.join('        ["' + goal + '-banner.blp"] = "' + artist + '",' for goal, _, _, artist in jobs if artist))
p = ROOT / 'reports/Goal-art-checklist.html'
s = p.read_text(encoding='utf-8')
start = s.index('var GOALS = ') + len('var GOALS = ')
end = s.index(';\n', start)
goals = json.loads(s[start:end])
updated = []
for _, rows in goals:
    for row in rows:
        for goal, _, name, _ in jobs:
            if row[0] == name:
                row[1:4] = ['done', 'done', goal]
                updated.append(name)
assert len(updated) == 4, updated
s = s[:start] + json.dumps(goals, indent=1, ensure_ascii=False) + s[end:]
for _, _, name, _ in jobs:
    s = s.replace('  "' + name + ' (both factions)",\n', '')
s = s.replace('var FOUND = [', 'var FOUND = [\n  "2026-10-27: Approved and installed widows_remorse, lobotomizer, demonslayer, claw_of_the_black_drake. Card credits retained: Craig Elliott and Michael Sutfin.",')
p.write_text(s, encoding='utf-8', newline='\n')
p = ROOT / 'reports/image-tests/weapons-widow-lobotomizer-demonslayer-claw-review-2026-10-27.json'
d = json.loads(p.read_text())
d['status'] = 'All four approved by Karl: all good. Installed 2026-10-27. Full game restart and native visual review pending.'
d['runtime'] = {goal: manifest[goal] for goal, _, _, _ in jobs}
p.write_text(json.dumps(d, indent=2)+'\n', encoding='utf-8', newline='\n')
print('Installed all four: neutral 1200x900 masters, independently decoded 512px DXT1 BLPs with ten mip levels.')
