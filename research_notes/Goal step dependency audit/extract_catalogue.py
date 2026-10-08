import sys, json, pathlib
ROOT=pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/.py'))
from lupa import lua51
def convert(t):
    if lua51.lua_type(t)=='table':
        keys=list(t.keys())
        if keys and all(isinstance(k,(int,float)) for k in keys) and sorted(keys)==list(range(1,len(keys)+1)):
            return [convert(t[k]) for k in range(1,len(keys)+1)]
        return {str(k):convert(v) for k,v in t.items() if lua51.lua_type(v)!='function'}
    return t
out={}
for client,interface in [('Era',11509),('Forever',16001)]:
    rt=lua51.LuaRuntime()
    rt.execute((ROOT/'tools/wowstub.lua').read_text())
    rt.execute('GetBuildInfo=function() return "", "", "", '+str(interface)+' end')
    ns=rt.eval('{}');rt.globals().STUB_NS=ns
    run=rt.eval('function(src,name,ns) assert(loadstring(src,"@"..name))("ForeverGoalTracker",ns) end')
    for f in ['Data.lua','Library.lua','Npcs.lua','Quests.lua','Core.lua']:
        run((ROOT/f).read_text(encoding='utf-8'),f,ns)
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN")')
    out[client]=convert(ns['goals'])
(ROOT/'research_notes/Goal step dependency audit/catalogue.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8')
for client,goals in out.items():
    print(client,len(goals),[(g['id'],g['category']) for g in goals])
