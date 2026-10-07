"""Checks the addon's Lua with real Lua 5.1 (the game's version).

1. Compiles Data.lua, Library.lua and Core.lua: catches syntax slips,
   missing commas and Lua's 200-local limit.
2. Loads all three against tools/wowstub.lua, a stand-in for the WoW
   API, and fires the startup events through the addon's own handlers,
   each time in a fresh Lua state with the saved variables carried
   over (like a real /reload):
     - fresh install (no saved variables at all)
     - normal login with two goals, one of them finished
     - a goal finishing while the window is closed (bag update)
   and shows what each one printed to chat. This catches load-path
   errors such as reading ForeverGoalTrackerDB before the game loads it.

The stand-in can't draw anything, so this doesn't replace testing in
game; it catches Lua errors on the way in.

Setup, once per machine:  pip3 install --target tools/.py lupa
Run from the repo root:   python3 tools/check.py
"""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
from lupa import lua51

FILES = ["Data.lua", "Library.lua", "Core.lua"]
STUB = open(os.path.join(here, "wowstub.lua")).read()

# Serializes the saved variables so the next "session" can start fresh.
SERIALIZE = r'''
function STUB_SERIALIZE(v)
  local t = type(v)
  if t == "table" then
    local out = {}
    for k, x in pairs(v) do
      local kt = type(k)
      if (kt == "string" or kt == "number") and type(x) ~= "function" and type(x) ~= "userdata" then
        local ks = kt == "string" and string.format("[%q]", k) or "[" .. k .. "]"
        local xs = STUB_SERIALIZE(x)
        if xs then out[#out + 1] = ks .. "=" .. xs end
      end
    end
    return "{" .. table.concat(out, ",") .. "}"
  elseif t == "string" then return string.format("%q", v)
  elseif t == "number" or t == "boolean" then return tostring(v) end
  return nil
end
'''

def session(saved, before_events=None, after_login=None):
    """One game session in a fresh Lua state. Returns (saved, chat)."""
    rt = lua51.LuaRuntime()
    rt.execute(STUB)
    rt.execute(SERIALIZE)
    run = rt.eval('function(src, name, ns) local f = assert(loadstring(src, "@" .. name)); f("ForeverGoalTracker", ns) end')
    ns = rt.eval("{}")
    rt.globals().STUB_NS = ns
    for f in FILES:
        run(open(f).read(), f, ns)
    if saved:
        rt.execute("ForeverGoalTrackerDB = " + saved)
    if before_events:
        rt.execute(before_events)
    rt.execute('STUB_PRINTS = {}; STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN")')
    if after_login:
        rt.execute(after_login)
    chat = list(rt.eval("STUB_PRINTS").values())
    return rt.eval("STUB_SERIALIZE(ForeverGoalTrackerDB)"), chat

ok_all = True
rt = lua51.LuaRuntime()
compile_ = rt.eval('function(src, name) local f, err = loadstring(src, "@" .. name); return f ~= nil, err end')
for f in FILES:
    ok, err = compile_(open(f).read(), f)
    print(("compiles   " if ok else "SYNTAX     ") + f + ("" if ok else ": " + str(err)))
    ok_all = ok_all and ok

if ok_all:
    steps = [
        ("fresh install", None, None),
        # Ashbringer finished (6 steps), Atiesh just started.
        ("login with goals", 'local D = ForeverGoalTrackerDB; D.active.ashbringer = true; D.active.atiesh = true; '
            'D.progress.ashbringer = {true, true, true, true, true, true}; D.progress.atiesh = {true}; '
            'D.goalsDone = { ashbringer = true }', None),
        ("goal finished while closed", None,
            'local p = ForeverGoalTrackerDB.progress.atiesh; for i = 1, 10 do p[i] = true end; '
            'STUB_PRINTS = {}; STUB_FIRE("BAG_UPDATE_DELAYED")'),
        ("/goals testbanner", None, 'STUB_PRINTS = {}; SlashCmdList["FOREVERGOALTRACKER"]("testbanner")'),
        # Welcome wizard: every step, then the suggestions for some interests.
        ("welcome wizard", None,
            'STUB_PRINTS = {}; local W = STUB_NS.welcome; STUB_NS.OpenWelcome(1); W.Show(2); '
            'W.picked = { raid = true, loot = true, grind = true, pvp = true, collect = true }; W.Show(3); '
            'for _, e in ipairs(W.list) do print(W.Title(e, { className = "Warrior" }) .. "  [" .. e.why .. (e.tracked and ", on My Goals" or "") .. "]") end; '
            'W.AddChosen()'),
    ]
    saved = None
    for label, before, after in steps:
        try:
            saved, chat = session(saved, before, after)
            print("session    " + label)
            for line in chat:
                print("             chat: " + line)
        except Exception as e:
            print("ERROR      " + label + ": " + str(e).split("\n")[0])
            ok_all = False
            break

sys.exit(0 if ok_all else 1)
