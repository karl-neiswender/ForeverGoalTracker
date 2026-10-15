"""Audit real artwork resolution per faction, race, class, and supported client."""
from pathlib import Path
import sys, subprocess, json
sys.path.insert(0, 'C:/Users/kneis/AppData/Local/Temp/fgt-lua-check')
from lupa import lua51
root = Path.cwd()
files = [x.strip() for x in (root/'ForeverGoalTracker.toc').read_text().splitlines() if x.strip().endswith('.lua')]
result = {'commit': subprocess.check_output(['git','rev-parse','HEAD']).decode().strip(), 'clients': {}, 'missing_files': []}
races = {'Alliance': ['Human','Dwarf','Gnome','NightElf','Skyborne'], 'Horde': ['Orc','Troll','Tauren','Scourge']}
classes = ['WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID']
for client in ['Era','Forever']:
    rt = lua51.LuaRuntime()
    rt.execute((root/'tools/wowstub.lua').read_text())
    if client == 'Forever':
        rt.execute('GetBuildInfo = function() return "1.60.1", "70291", "", 16001 end; GetItemInfo = false')
    run = rt.eval('function(src,name,ns) assert(loadstring(src,"@"..name))("ForeverGoalTracker", ns) end')
    ns = rt.table(); rt.globals().STUB_NS = ns
    for file in files: run((root/file).read_text(encoding='utf-8'),file,ns)
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN"); STUB_NS.goalBanner.PlayerArtContext = function() return STUB_NS.auditProfile end')
    rows = []
    for _, g in ns.goals.items():
        if g.libraryOnly: continue
        child = g.libraryChild
        g.libraryChild = None  # library children appear through their collection picker
        visible = ns.LibraryVisible(g)
        g.libraryChild = child
        if not visible: continue
        row = {'id':g.id, 'name':g.name, 'category':g.category, 'armorParent':g.armorParent, 'armorClass':g.armorClass, 'factions':{}}
        for faction, raceList in races.items():
            if g.faction and g.faction != faction: continue
            contexts = []
            for race in raceList:
                if race == 'Skyborne' and client == 'Era': continue
                for cls in classes:
                    profile = rt.table_from({'faction':faction,'race':race,'class':cls})
                    if not ns.GoalFits(g,profile): continue
                    ns.auditProfile = profile
                    path = ns.goalBanner.ArtPath(ns.goalBanner,g.id)
                    contexts.append({'race':race,'class':cls,'path':path})
                    if path and not (root/'Media'/path).is_file() and path not in result['missing_files']:
                        result['missing_files'].append(path)
            if contexts:
                row['factions'][faction] = {'paths':sorted({c['path'] for c in contexts if c['path']}), 'blank_contexts':sum(not c['path'] for c in contexts), 'contexts':contexts}
        rows.append(row)
    def check_paths(value):
        if isinstance(value,str) and value.endswith(('.blp','.tga')):
            if not (root/'Media'/value).is_file() and value not in result['missing_files']:
                result['missing_files'].append(value)
        elif hasattr(value,'items'):
            for _, child in value.items(): check_paths(child)
    for key in ['artPaths','factionArtPaths','artVariants','professionArt']:
        check_paths(ns.goalBanner[key])
    result['clients'][client] = rows
out = root/'reports/image-tests/banner-coverage-2026-10-15.json'
out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
for client,rows in result['clients'].items():
    missing = [r for r in rows if not any(f['paths'] for f in r['factions'].values())]
    print(client, len(rows), 'goals;', 'blank:',[(r['id'],r['name']) for r in missing])
print('Missing files:',result['missing_files'])
for r in result['clients']['Forever']:
    if r['armorParent'] or r['id'] in ('allclasses','epicmounts','social_lol','social_buffs'):
        print(r['id'],r['name'], {f:v['paths'] for f,v in r['factions'].items()})
