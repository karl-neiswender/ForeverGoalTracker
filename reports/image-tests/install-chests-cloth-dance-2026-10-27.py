"""Install Karl's three approved reviews, without rebuilding unrelated artwork."""
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from PIL import Image
import artwork

def edit(path, old, new):
    p = ROOT / path
    data = p.read_bytes()
    newline = '\r\n' if b'\r\n' in data else '\n'
    a, b = [s.replace('\n', newline).encode('utf-8') for s in (old, new)]
    assert a in data, (path, old)
    p.write_bytes(data.replace(a, b, 1))

jobs = [('social_chests', 'chests'), ('cloth_donations', 'donate-cloth'), ('social_dances_horde', 'dance-horde')]
manifest_path = ROOT / 'Media/final-images/runtime-manifest.json'
manifest = json.loads(manifest_path.read_text())
for key, review in jobs:
    filename = review + '-master.png'
    master = ROOT / 'Media/final-images' / filename
    assert not master.exists(), master
    with Image.open(ROOT / 'Media/final-images' / (review + '-review-v1.png')) as im:
        # Neutralize imperceptible channel differences and normalize approved aspect.
        im.convert('L').convert('RGB').resize((1200, 900), Image.Resampling.LANCZOS).save(master)
    info = artwork.compress(master, ROOT / 'Media' / (key + '-banner.blp'))
    assert info['mips'] == 10
    info['source'] = filename
    manifest[key] = info
    edit('tools/artwork.py', 'FINAL_BANNERS = {', 'FINAL_BANNERS = {\n    "' + key + '": "' + filename + '",')
manifest_path.write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
edit('Core.lua', '    B.artVariants.tier3_rogue =', '''    B.artVariants.social_chests = {{path="social_chests-banner.blp", aspect=4/3, preprocessed=true}}
    B.artVariants.social_dances = {{path="social_dances_horde-banner.blp", faction="Horde", aspect=4/3, preprocessed=true}}
    for _, city in ipairs({"stormwind", "ironforge", "darnassus", "gnomeregan", "orgrimmar", "undercity", "thunderbluff", "darkspear"}) do
        B.artVariants["cloth_" .. city] = {{path="cloth_donations-banner.blp", aspect=4/3, preprocessed=true}}
    end
    B.artVariants.tier3_rogue =''')
edit('Core.lua', '    B.artArtists = {', '''    B.artArtists = {
        ["cloth_donations-banner.blp"] = "Matt Cavotta",
        ["social_dances_horde-banner.blp"] = "Mauro Cascioli",''')

p = ROOT / 'reports/Goal-art-checklist.html'
text = p.read_text(encoding='utf-8')
start = text.index('var GOALS = ') + len('var GOALS = ')
end = text.index(';\n', start)
goals = json.loads(text[start:end])
cloth_count = 0
for _, rows in goals:
    for row in rows:
        if row[0] == 'Dance':
            row[2] = 'done'
            row[3] = 'Horde: social_dances_horde; Alliance still needed.'
        elif row[0] == 'Open Treasure Chests':
            row[1:4] = ['done', 'done', 'social_chests']
        elif 'cloth' in row[0].lower():
            cloth_count += 1
            row[1:3] = ['share' if s != 'na' else s for s in row[1:3]]
            row[3] = 'cloth_donations (shared across all cloth donation goals)'
assert cloth_count == 8, cloth_count
text = text[:start] + json.dumps(goals, indent=1, ensure_ascii=False) + text[end:]
text = text.replace('  "Dance (both factions)",', '  "Dance (Alliance)",').replace('  "Open Treasure Chests (both factions)",\n', '')
text = text.replace('var FOUND = [', 'var FOUND = [\n  "2026-10-27: Approved and installed social_chests, cloth_donations (all eight capitals), and social_dances_horde. Source card credits: Matt Cavotta (cloth), Mauro Cascioli (dance).",')
p.write_text(text, encoding='utf-8', newline='\n')
record = ROOT / 'reports/image-tests/goals-chests-cloth-dance-review-2026-10-27.json'
data = json.loads(record.read_text())
data['status'] = 'Approved by Karl: all good. Installed 2026-10-27; native review pending a full game restart.'
data['runtime'] = {key: manifest[key] for key, _ in jobs}
record.write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8')
print('Installed three banners; updated eight cloth goals and Horde Dance.')
