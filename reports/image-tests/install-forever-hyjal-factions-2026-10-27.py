"""Install approved Horde Hyjal art and retain current art for Alliance."""
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
    assert b.count(a) == 1, (path, old)
    end = b.find(b'\n', b.index(a))
    nl = '\r\n' if b[end-1:end] == b'\r' else '\n'
    p.write_bytes(b.replace(a, new.replace('\n', nl).encode(), 1))

master = ROOT / 'Media/final-images/forever-hyjal-horde-master.png'
assert not master.exists()
with Image.open(ROOT / 'Media/final-images/forever-hyjal-horde-review-v1.png') as im:
    im.convert('L').convert('RGB').resize((1200, 900), Image.Resampling.LANCZOS).save(master)
p = ROOT / 'Media/final-images/runtime-manifest.json'
manifest = json.loads(p.read_text())
for faction, source in [('alliance', 'set_forever_raid-master.png'), ('horde', master.name)]:
    key = 'set_forever_raid_' + faction
    info = artwork.compress(ROOT / 'Media/final-images' / source, ROOT / 'Media' / (key+'-banner.blp'))
    assert info['mips'] == 10
    info['source'] = source
    manifest[key] = info
replace('tools/artwork.py', 'FINAL_BANNERS = {', 'FINAL_BANNERS = {\n    "set_forever_raid_alliance": "set_forever_raid-master.png",\n    "set_forever_raid_horde": "forever-hyjal-horde-master.png",')
p.write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8', newline='\n')
replace('Core.lua', '    B.artPaths.set_forever_raid = "set_forever_raid-banner.blp"', '''    B.artVariants.set_forever_raid = {
        {path="set_forever_raid_alliance-banner.blp", faction="Alliance", aspect=4/3, preprocessed=true},
        {path="set_forever_raid_horde-banner.blp", faction="Horde", aspect=4/3, preprocessed=true},
    }
    B.artPaths.set_forever_raid = "set_forever_raid_alliance-banner.blp"''')
replace('Core.lua', '        B.artPaths[child.id] = "set_forever_raid-banner.blp"', '''        B.artVariants[child.id] = B.artVariants.set_forever_raid
        B.artPaths[child.id] = "set_forever_raid_alliance-banner.blp"''')
# Preserve the old artwork's existing animation and attribution on its Alliance copy.
p = ROOT / 'Core.lua'
b = p.read_bytes().replace(b'["set_forever_raid-banner.blp"]', b'["set_forever_raid_alliance-banner.blp"]')
p.write_bytes(b)
replace('Core.lua', '    B.artArtists = {', '    B.artArtists = {\n        ["set_forever_raid_horde-banner.blp"] = "Alex Horley",')
p = ROOT / 'reports/Goal-art-checklist.html'
s = p.read_text(encoding='utf-8')
for var in ['GOALS', 'CLASSIMG', 'TABLES']:
    prefix = 'var '+var+' = '
    start = s.index(prefix)+len(prefix)
    end = s.index(';\n', start)
    d = json.loads(s[start:end])
    if var == 'GOALS':
        for _, rows in d:
            for row in rows:
                if row[3] == 'set_forever_raid':
                    row[1:4] = ['share', 'share', 'Alliance: set_forever_raid_alliance; Horde: set_forever_raid_horde']
    elif var == 'CLASSIMG':
        for table in d.values():
            for pair in table.values():
                for i, faction in enumerate(['alliance', 'horde']):
                    pair[i] = ['set_forever_raid_'+faction if key == 'set_forever_raid' else key for key in pair[i]]
    else:
        for _, rows in d:
            for row in rows:
                if row[0] == 'Forever Hyjal sets (all nine classes)':
                    row[1:4] = ['done', 'done', 'Alliance: set_forever_raid_alliance; Horde: set_forever_raid_horde']
    s = s[:start]+json.dumps(d, indent=1, ensure_ascii=False)+s[end:]
s = s.replace('var FOUND = [', 'var FOUND = [\n  "2026-10-27: All nine Forever Hyjal class goals now share faction-specific art: set_forever_raid_alliance (existing), set_forever_raid_horde (approved mirrored Horde scene).",')
p.write_text(s, encoding='utf-8', newline='\n')
print('Installed both faction banners and shared variants for every Hyjal class child.')
