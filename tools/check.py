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

def session(saved, before_events=None, after_login=None, forever=False):
    """One game session in a fresh Lua state. Returns (saved, chat).
    forever: the Warcraft Forever client (interface 16001) instead of Classic Era."""
    rt = lua51.LuaRuntime()
    rt.execute(STUB)
    if forever:
        rt.execute('GetBuildInfo = function() return "1.60.1", "0", "", 16001 end')
        # globals the modern engine removed (moved into C_ namespaces): calling
        # one errors, like in the Forever client (GetItemInfo crashed 2.7 work)
        rt.execute('GetItemInfo = false')
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
            'W.picked = { raid = true, loot = true, grind = true, pvp = true, collect = true, social = true }; W.Show(3); '
            'for _, e in ipairs(W.list) do print(W.Title(e, { className = "Warrior" }) .. "  [" .. e.why .. (e.tracked and ", on My Goals" or "") .. "]") end; '
            'W.AddChosen()'),
        # Find your next goal: saved interests, goals already tracked left out.
        ("find your next goal", None,
            'STUB_PRINTS = {}; local W = STUB_NS.welcome; STUB_NS.FindMoreButton(); '
            'ForeverGoalTrackerDB.interests = { raid = true, loot = true }; STUB_NS.OpenWelcome(nil, true); '
            'for _, e in ipairs(W.list) do print(W.Title(e, { className = "Warrior" }) .. (e.tracked and "  [TRACKED: wrong]" or "")) end; '
            'STUB_NS.CloseWelcome(true)'),
        # Change target on the gold goal, then back to the default.
        ("change target", None,
            'STUB_PRINTS = {}; local g = STUB_NS.GoalById("gold_5k"); ForeverGoalTrackerDB.active.gold_5k = true; '
            'STUB_NS.OpenTargetCard(g); STUB_NS.CloseTargetCard(); STUB_NS.SetTarget(g, 10000); '
            'for _, s in ipairs(g.steps) do print("  " .. s.text .. " (" .. s.auto.money / 10000 .. "g)") end; '
            'STUB_NS.SetTarget(g, nil); print("  back to: " .. g.name)'),
        # Social goals tick from guild and friends; the lockout preview.
        ("social goals and lockout", None,
            'STUB_PRINTS = {}; local D = ForeverGoalTrackerDB; D.active.social_guild = true; D.active.social_friends = true; '
            'D.active.raid_mc = true; STUB_FIRE("FRIENDLIST_UPDATE"); '
            'STUB_NS.SelectGoal("raid_mc"); SlashCmdList["FOREVERGOALTRACKER"]("testlockout"); '
            'SlashCmdList["FOREVERGOALTRACKER"]("testlockout")'),
        # Statistics (Forever): 12 duels won ticks Duelist's first two steps;
        # money text with coin icons parses to copper.
        ("statistics: duelist", None,
            'STUB_PRINTS = {}; GetStatisticsCategoryList = function() return { 21, 130 } end; '
            'GetCategoryNumAchievements = function() return 1 end; '
            'GetStatistic = function(cat) if cat == 21 then return "12", false, 319 end '
            'return "5|TInterface\\\\MoneyFrame\\\\UI-GoldIcon:0:0:2:0|t 56|TInterface\\\\MoneyFrame\\\\UI-SilverIcon:0:0:2:0|t", false, 334 end; '
            'ForeverGoalTrackerDB.active.pvp_duelist = true; STUB_NS.forceStats = true; STUB_FIRE("BAG_UPDATE_DELAYED"); '
            'local p = ForeverGoalTrackerDB.progress.pvp_duelist or {}; '
            'print("  duelist ticks: " .. tostring(p[1]) .. " " .. tostring(p[2]) .. " " .. tostring(p[3])); '
            'print("  money parse: " .. STUB_NS.StatNumber(select(1, GetStatistic(130))) .. " copper"); '
            'local g = STUB_NS.GoalById("pvp_duelist"); STUB_NS.SetTarget(g, 200); '
            'for _, s in ipairs(g.steps) do print("  " .. s.text) end'),
        # Forever client: the new raid sets and PvP sets show up, and the
        # wizard suggests the character's class set from each (Human Warrior).
        ("forever: new sets in the wizard", None,
            'STUB_PRINTS = {}; local W = STUB_NS.welcome; ForeverGoalTrackerDB.welcomeSeen = true; '
            'W.picked = { raid = true, pvp = true }; W.Show(3); '
            'for _, e in ipairs(W.list) do print(W.Title(e, { className = "Warrior" })) end; '
            'local n = 0; for _, g in ipairs(STUB_NS.goals) do if STUB_NS.LibraryVisible(g) then n = n + 1 end end; '
            'print("  goals visible on Forever: " .. n); '
            'ForeverGoalTrackerDB.active.thunderfury = true; STUB_NS.SelectGoal("thunderfury"); '
            'local s = STUB_NS.GoalById("pvp_set_plate_ally").sections[1].pieces[2]; print("  " .. s.text); '
            'local r = STUB_NS.GoalById("set_forever_raid"); print("  raid set parts: " .. #r.sections .. ", plate PvP parts: " .. #STUB_NS.GoalById("pvp_set_plate_ally").sections); '
            'print("  paladin helm ticks from: " .. table.concat(r.sections[2].pieces[1].auto.item, ", "))', True),
        # Logout must not read statistics: GetStatistic during PLAYER_LOGOUT
        # crashed the Forever client on exit (2.6.0, ASSERT s_lootInitialized).
        ("logout reads no statistics", None,
            'STUB_PRINTS = {}; GetStatisticsCategoryList = function() return { 21 } end; '
            'GetCategoryNumAchievements = function() return 1 end; '
            'GetStatistic = function() rawset(_G, "STUB_STAT_CALLED", true); return "0", false, 319 end; '
            'STUB_NS.statsReadAt = nil; rawset(_G, "STUB_STAT_CALLED", nil); STUB_FIRE("PLAYER_LOGOUT"); '
            'assert(not rawget(_G, "STUB_STAT_CALLED"), "GetStatistic was called during logout"); print("  logout ok")', True),
        # Item and Wowhead links: a set piece links to its item, the card
        # builds the address for this client.
        ("item and wowhead links", None,
            'STUB_PRINTS = {}; local row = { text = { GetText = function(self) return self.s or "Helm of Might from Garr." end, SetText = function(self, s) self.s = s end } }; local g = STUB_NS.GoalById("set_tier1"); '
            'STUB_NS.SetStepLinks(row, g.sections[1].pieces[1].auto); print("  helm item: " .. tostring(row.itemId) .. ", text: " .. row.text:GetText()); '
            'STUB_NS.OpenWowheadCard("item", row.itemId, "Helm of Might"); print("  " .. STUB_NS.wowheadCard.url); '
            'STUB_NS.CloseWowheadCard()'),
        # The demo scenes, then everything back.
        ("demo scenes", None,
            'STUB_PRINTS = {}; for i = 1, 7 do SlashCmdList["FOREVERGOALTRACKER"]("demo " .. i) end; '
            'print("  demo gold name: " .. STUB_NS.GoalById("gold_5k").name); '
            'SlashCmdList["FOREVERGOALTRACKER"]("demo off"); print("  after off: " .. STUB_NS.GoalById("gold_5k").name)'),
    ]
    saved = None
    for step in steps:
        label, before, after = step[0], step[1], step[2]
        try:
            saved, chat = session(saved, before, after, forever=len(step) > 3 and step[3])
            print("session    " + label)
            for line in chat:
                print("             chat: " + line)
        except Exception as e:
            print("ERROR      " + label + ": " + str(e).split("\n")[0])
            ok_all = False
            break

sys.exit(0 if ok_all else 1)
