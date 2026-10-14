"""Inspect the real runtime artwork resolver against the WoW stub."""
from pathlib import Path
import sys, subprocess, json
sys.path.insert(0, 'C:/Users/kneis/AppData/Local/Temp/fgt-lua-check')
from lupa import lua51
root = Path.cwd()
files = [x.strip() for x in (root/'ForeverGoalTracker.toc').read_text().splitlines() if x.strip().endswith('.lua')]
result = {'commit': subprocess.check_output(['git','rev-parse','HEAD']).decode().strip(), 'clients': {}, 'missing_files': [], 'variant_gaps': {}}
for client in ['Era', 'Forever']:
    rt = lua51.LuaRuntime()
    rt.execute((root/'tools/wowstub.lua').read_text())
    if client == 'Forever':
        rt.execute('GetBuildInfo = function() return "1.60.1", "70291", "", 16001 end; GetItemInfo = false')
    run = rt.eval('function(src,name,ns) assert(loadstring(src,"@"..name))("ForeverGoalTracker", ns) end')
    ns = rt.table()
    rt.globals().STUB_NS = ns
    for file in files: run((root/file).read_text(encoding='utf-8'), file, ns)
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN"); STUB_NS.goalBanner.PlayerArtContext = function() return STUB_NS.auditProfile end')
    missing, conditional, coverage = [], [], []
    profiles = [('Alliance', 'Human'), ('Alliance', 'Dwarf'), ('Alliance', 'Gnome'), ('Alliance', 'NightElf'), ('Alliance', 'Skyborne'), ('Horde', 'Orc'), ('Horde', 'Troll'), ('Horde', 'Tauren'), ('Horde', 'Scourge')]
    for _, g in ns.goals.items():
        if g.libraryOnly or not ns.LibraryVisible(g): continue
        paths = set()
        for faction, race in profiles:
            if g.faction and g.faction != faction: continue
            for token in ['WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID']:
                ns.auditProfile = rt.table_from({'faction': faction, 'race': race, 'class': token})
                path = ns.goalBanner.ArtPath(ns.goalBanner, g.id)
                if path: paths.add(path)
        row = {'id': g.id, 'name': g.name, 'category': g.category, 'paths': sorted(paths)}
        if not paths:
            (conditional if g.category == 'Profession' else missing).append(row)
        else: coverage.append(row)
    for key in ['artPaths','factionArtPaths','artVariants','professionArt']:
        def inspect(value):
            if isinstance(value, str) and value.endswith(('.blp','.tga')) and not (root/'Media'/value).exists():
                if value not in result['missing_files']: result['missing_files'].append(value)
            elif hasattr(value, 'items'):
                for _, child in value.items(): inspect(child)
        inspect(ns.goalBanner[key])
    result['clients'][client] = {'missing': missing, 'conditional_professions': conditional, 'covered': coverage}
out = root/'reports/image-tests/banner-coverage-2026-10-14.json'
out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
for client, data in result['clients'].items():
    print(client, len(data['missing']), 'missing backgrounds')
    for row in data['missing']: print(' ',row['id'],':',row['name'])
    print('Conditional professions:', [r['name'] for r in data['conditional_professions']])
print('Missing mapped files:',result['missing_files'])
