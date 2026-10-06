"""Checks the addon's Lua with real Lua 5.1 (the game's version).

1. Compiles Data.lua, Library.lua and Core.lua: catches syntax slips,
   missing commas and Lua's 200-local limit.
2. Runs all three in order against tools/wowstub.lua, a stand-in for
   the WoW API, with no saved variables yet (like a fresh /reload):
   catches errors in the load path, such as reading
   ForeverGoalTrackerDB before the game has loaded it.

Setup, once per machine:  pip3 install --target tools/.py lupa
Run from the repo root:   python3 tools/check.py
"""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
from lupa import lua51

FILES = ["Data.lua", "Library.lua", "Core.lua"]
rt = lua51.LuaRuntime()
compile_ = rt.eval('function(src, name) local f, err = loadstring(src, "@" .. name); return f ~= nil, err end')
ok_all = True
for f in FILES:
    ok, err = compile_(open(f).read(), f)
    print(("compiles   " if ok else "SYNTAX     ") + f + ("" if ok else ": " + str(err)))
    ok_all = ok_all and ok
if ok_all:
    rt.execute(open(os.path.join(here, "wowstub.lua")).read())
    run = rt.eval('function(src, name, ns) local f = assert(loadstring(src, "@" .. name)); f("ForeverGoalTracker", ns) end')
    ns = rt.eval("{}")
    for f in FILES:
        try:
            run(open(f).read(), f, ns)
            print("loads      " + f)
        except Exception as e:
            print("LOAD ERROR " + f + ": " + str(e).split("\n")[0])
            ok_all = False
            break
sys.exit(0 if ok_all else 1)
