"""Checks the addon's Lua with real Lua 5.1 (the game's version).

1. Compiles every Lua file in the addon: catches syntax slips,
   missing commas and Lua's 200-local limit.
2. Loads them against tools/wowstub.lua, a stand-in for the WoW
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

FILES = ["Data.lua", "Library.lua", "AQArmor.lua", "ArmorSets.lua", "Npcs.lua", "Quests.lua", "Dependencies.lua", "Filters.lua", "Core.lua", "ItemTooltips.lua", "Materials.lua", "Popout.lua", "Rail.lua", "Maplet.lua", "WhatsNew.lua", "Ambience.lua", "Audit.lua", "GearData.lua", "GearCatalog.lua", "GearPlanner.lua"] # load order, as in the .toc
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
        rt.execute('GetBuildInfo = function() return "1.60.1", "70291", "", 16001 end')
        # globals the modern engine removed (moved into C_ namespaces): calling
        # one errors, like in the Forever client (GetItemInfo crashed 2.7 work)
        rt.execute('GetItemInfo = false')
    rt.execute(SERIALIZE)
    run = rt.eval('function(src, name, ns) local f = assert(loadstring(src, "@" .. name)); f("ForeverGoalTracker", ns) end')
    ns = rt.eval("{}")
    rt.globals().STUB_NS = ns
    baseline_globals = set(rt.globals().keys())
    for f in FILES:
        run(open(f).read(), f, ns)
    # Addon state belongs in the private namespace. These exports are WoW
    # integration points; catch accidental globals on every client load.
    allowed_globals = {
        "BINDING_HEADER_FOREVERGOALTRACKER", "BINDING_NAME_FGT_TOGGLE",
        "ForeverGoalTrackerDB", "ForeverGoalTracker_Toggle",
        "ForeverGoalTrackerFrame", "ForeverGoalTrackerMinimapButton",
        "SLASH_FOREVERGOALTRACKER1", "SLASH_FOREVERGOALTRACKER2",
        "SLASH_FOREVERGOALTRACKER3", "SetItemRef",
    }
    unexpected_globals = set(rt.globals().keys()) - baseline_globals - allowed_globals
    assert not unexpected_globals, "Unexpected addon globals: " + repr(sorted(unexpected_globals))
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
    # Stray control bytes (a lost backslash in an escape such as the middle dot) show
    # as empty squares in game while still compiling. Reject them.
    src = open(f, encoding="utf-8").read()
    bad = [i for i, ch in enumerate(src) if ord(ch) < 32 and ch not in "\r\n\t"]
    if bad:
        print("CONTROL    " + f + ": byte " + str(ord(src[bad[0]])) + " near " + repr(src[max(0, bad[0] - 40):bad[0] + 10]))
        ok_all = False

# Banner layering (Karl, 2026-10-13): every light effect must sit below the dark
# gradient layers (the left, top and bottom shading, BACKGROUND sublevel 0 and up)
# and below the inner shadows (BORDER), whichever file order they are created in.
import re
core_src = open("Core.lua", encoding="utf-8").read()
shading, effects = {}, {}
func = None
for line_no, line in enumerate(core_src.splitlines(), 1):
    m = re.search(r"function B[:.](\w+)", line)
    if m:
        func = m.group(1)
    m = re.search(r'(?:(B\.\w+)\s*=\s*)?detailPanel:CreateTexture\(nil,\s*"(\w+)"(?:,\s*nil,\s*(-?\d+))?\)', line)
    if not m:
        continue
    name, layer, sub = m.group(1), m.group(2), int(m.group(3) or 0)
    if name in ("B.left", "B.top", "B.bottom"):
        shading[name] = (layer, sub, line_no)
    elif name in ("B.glowTex", "B.raysTex", "B.bloomTex") or func in ("ResetEmbers", "ResetShafts", "BloomTexture"):
        effects[name or ("texture made in " + func)] = (layer, sub, line_no)
    elif name == "B.art" or name == "B.background":
        effects[name] = (layer, sub, line_no)
layers_ok = len(shading) == 3 and len(effects) >= 6
for n, (layer, sub, line_no) in effects.items():
    below = layer == "BACKGROUND" and sub < min(v[1] for v in shading.values())
    layers_ok = layers_ok and below
    if not below:
        print("LAYER      " + n + " (line " + str(line_no) + ") is " + layer + " " + str(sub) + ", not below the shading")
print(("layers     " if layers_ok else "LAYER      ") + "banner lights, bloom, embers and sparks sit below the dark gradients ("
      + ", ".join(sorted(effects)) + ")")
ok_all = ok_all and layers_ok

# The windy leaves and clouds (Ambience.lua) are textures on the goal panel below the banner's
# dark gradients, like the lights, so the shading darkens them. A child frame would draw above.
amb_src = open("Ambience.lua", encoding="utf-8").read()
amb_levels = {}
m_ = re.search(r"local DUST_LEVEL, CLOUD_LEVEL = (-?\d+), (-?\d+)", amb_src)
if m_:
    amb_levels = {"dust": int(m_.group(1)), "clouds": int(m_.group(2))}
amb_on_panel = amb_src.count("U.detail:CreateTexture(nil, \"BACKGROUND\", nil, ") >= 2 and "fx:CreateTexture" not in amb_src
amb_ok = bool(amb_levels) and amb_on_panel and all(v < min(s_[1] for s_ in shading.values()) for v in amb_levels.values())
print(("ambience  " if amb_ok else "AMBIENCE  ") + "windy leaves and clouds are panel layers below the dark gradients ("
      + ", ".join(k_ + " " + str(v_) for k_, v_ in sorted(amb_levels.items())) + ")")
ok_all = ok_all and amb_ok

# Every banner texture registered as a variant is on disk, except those marked pending (art not
# delivered yet; the selection code skips them). Pending ones are listed so none is forgotten.
variant_paths, pending_paths = [], []
for line_ in core_src.splitlines():
    for m_ in re.finditer(r'path="([\w-]+-banner\.blp)"', line_):
        (pending_paths if "pending=true" in line_.replace(" ", "") else variant_paths).append(m_.group(1))
gone = sorted({p for p in variant_paths if not os.path.exists("Media/" + p)})
print(("variants   " if not gone else "VARIANT    ") + str(len(set(variant_paths))) + " registered banner variants are on disk"
      + ("" if not gone else "; MISSING: " + ", ".join(gone)))
if pending_paths:
    print("pending    waiting for art: " + ", ".join(sorted(set(pending_paths))))
ok_all = ok_all and not gone

# Every bloom a banner asks for has its texture (and its banner image) on disk.
stems = re.findall(r'"([\w-]+)"', re.search(r"B\.bloomStems = \{(.*?)\n    \}", core_src, re.S).group(1))
named = [n for n in re.findall(r'bloom = \{ "([\w-]+-bloom)"', core_src) if n != "name-bloom"]  # ("name-bloom" is the doc comment's example)
zoned = {m_.group(1): len(re.findall(r'"[\w-]+-bloom-\d+"', m_.group(2))) for m_ in
         re.finditer(r'(\w+) = \{ depth = [\d.]+,(.*?)\n        \},', core_src, re.S)}
zone_files = [s_ + "-bloom-" + str(k_) for s_, n_ in zoned.items() for k_ in range(1, n_ + 1)]
missing = [m for m in [s + "-bloom" for s in stems if s not in zoned] + named + zone_files if not (os.path.exists("Media/" + m + ".blp") or os.path.exists("Media/" + m + ".tga"))]
missing += [s + "-banner.blp" for s in stems if not os.path.exists("Media/" + s + "-banner.blp")]
print(("blooms     " if not missing else "BLOOM      ") + str(len(stems) + len(named)) + " bloom textures and their banners are on disk"
      + ("" if not missing else "; MISSING: " + ", ".join(missing)))
ok_all = ok_all and not missing

# Lua quietly drops the backslash of an unknown escape ("Interface\AddOns" loses its folder
# separators), so a texture path written that way compiles and then fails to load in game.
sys.path.insert(0, here)
import escapecheck
bad_escapes = escapecheck.run()
for name_, number_, esc_, text_ in bad_escapes:
    print("ESCAPE     " + name_ + ":" + str(number_) + " has " + esc_ + " in a string: " + text_)
print(("escapes    " if not bad_escapes else "ESCAPE     ") + "no invalid backslash escapes in any Lua string")
ok_all = ok_all and not bad_escapes

# Language conventions (tools/copycheck.py, reports/copy-sweep/conventions.md): the enforced
# rules fail the suite; proposed ones are only reported by running copycheck.py itself.
sys.path.insert(0, here)
import copycheck
found_copy = copycheck.run()
copy_bad = 0
for rule_ in copycheck.RULES:
    if rule_.status == "enforced":
        for where, field, msg, text in found_copy[rule_.id]:
            print("COPY       " + rule_.id + ": " + where + " / " + field + ": " + msg + "  |  " + text)
            copy_bad += 1
print(("language   " if not copy_bad else "COPY       ") + "player-facing text follows the enforced conventions"
      + ("" if not copy_bad else " (" + str(copy_bad) + " broken)"))
ok_all = ok_all and not copy_bad

if ok_all:
    steps = [
        ("fresh install", None, None),
        ("Forever 1.60.1 build 70291 startup", None,
            'local version, build, _, interface = GetBuildInfo(); '
            'assert(version == "1.60.1" and build == "70291" and interface == 16001, "build identity"); '
            'assert(STUB_NS.isForever and STUB_NS.clientLabel == "FOREVER", "Forever detection"); '
            'assert(GetItemInfo == false, "removed legacy API stays unavailable"); '
            'ForeverGoalTrackerDB.active.raid_mc = true; STUB_NS.SelectGoal("raid_mc"); '
            'assert(STUB_NS.goalBanner.hasArt and STUB_NS.goalBanner.preprocessed.raid_mc, "approved banner loaded"); '
            'STUB_FIRE("PLAYER_LOGOUT"); '
            'print("  build 70291 startup, Forever detection, final banners and logout ok")', True),
        # Ashbringer finished (6 steps), Atiesh just started.
        ("login with goals", 'local D = ForeverGoalTrackerDB; D.active.ashbringer = true; D.active.atiesh = true; '
            'D.progress.ashbringer = {true, true, true, true, true, true}; D.progress.atiesh = {true}; '
            'D.goalsDone = { ashbringer = true }', None),
        ("goal finished while closed", None,
            'local p = ForeverGoalTrackerDB.progress.atiesh; for i = 1, 10 do p[i] = true end; '
            'STUB_PRINTS = {}; STUB_FIRE("BAG_UPDATE_DELAYED")'),
        ("/goals testbanner", None, 'STUB_PRINTS = {}; SlashCmdList["FOREVERGOALTRACKER"]("testbanner")'),
        ("personal notes", None,
            'local F, D = STUB_NS, ForeverGoalTrackerDB; local g = F.GoalById("ashbringer"); '
            'F.SelectGoal(g.id); local progress, date = D.progress[g.id], D.goalDates[g.id]; '
            'F.OpenNoteCard(g); local enabled, saveEnabled; F.noteCard.delete.SetEnabled = function(_, on) enabled = on end; '
            'F.noteCard.save.SetEnabled = function(_, on) saveEnabled = on end; '
            'assert(F.noteCard.title:GetText() == "Add personal note"); '
            'assert(F.noteCard.hint:GetText() == "0 / 240 characters"); '
            'F.noteCard.box:SetText("A" .. string.char(195, 169)); F.noteCard.box:GetScript("OnTextChanged")(); '
            'assert(F.noteCard.hint:GetText() == "2 / 240 characters", "unicode character count"); F.noteCard.box:SetText(""); '
            'F.StyleNoteControls(); assert(not F.noteCard.save.gold and not enabled and not saveEnabled, "empty controls"); '
            'F.SaveNoteCard(); assert(F.noteCard.goal == g and F.GoalNote(g) == "", "empty save blocked"); '
            'F.noteCard.box:SetText("  Bring resistance gear |cff123456  "); F.noteCard.box:GetScript("OnTextChanged")(); '
            'assert(F.noteCard.save.gold and saveEnabled, "gold save when text entered"); F.SaveNoteCard(); '
            'assert(F.GoalNote(g) == "Bring resistance gear |cff123456"); '
            'assert(F.personalNote.text:GetText():find("||cff123456", 1, true), "literal formatting"); '
            'assert(D.progress[g.id] == progress and D.goalDates[g.id] == date, "notes preserve progress"); '
            'F.OpenNoteCard(g); assert(enabled, "saved note can be deleted"); '
            'F.noteCard.box:SetText("   "); F.noteCard.box:GetScript("OnTextChanged")(); assert(not F.noteCard.save.gold and not saveEnabled, "blank save disabled"); '
            'F.SaveNoteCard(); assert(F.noteCard.goal == g and F.GoalNote(g) == "Bring resistance gear |cff123456", "blank save preserves note"); '
            'F.noteCard.box:SetText("Unsaved changes"); F.noteCard.close:GetScript("OnClick")(); '
            'assert(F.GoalNote(g) == "Bring resistance gear |cff123456", "cancel"); '
            'F.OpenNoteCard(g); F.SelectGoal("atiesh"); assert(F.noteCard.goal == nil, "switch closes editor"); '
            'F.SetGoalNote(F.GoalById("atiesh"), "Keep the splinters in the bank."); '
            'assert(F.GoalNote(g) == "Bring resistance gear |cff123456", "separate goals"); '
            'F.OpenNoteCard(g); F.noteCard.delete:GetScript("OnClick")(); assert(D.notes[g.id] == nil, "delete button"); '
            'F.SetGoalNote(g, "Bring resistance gear."); print("  save, cancel, delete, literal text and separate goals ok")'),
        ("personal notes survive reload", None,
            'assert(STUB_NS.GoalNote(STUB_NS.GoalById("ashbringer")) == "Bring resistance gear."); '
            'assert(STUB_NS.GoalNote(STUB_NS.GoalById("atiesh")) == "Keep the splinters in the bank."); '
            'print("  both notes restored from SavedVariables")'),
        ("note modal motion and gold hover", None,
            'local F, W = STUB_NS, STUB_NS.welcome; local g = F.GoalById("ashbringer"); '
            'F.OpenNoteCard(g); F.CloseNoteCard(true); local T = F.noteCard; '
            'local alpha, scale = 1, 1; T.IsShown = function() return true end; '
            'T.SetAlpha = function(_, a) alpha = a end; T.GetAlpha = function() return alpha end; '
            'T.SetScale = function(_, s) scale = s end; T.GetScale = function() return scale end; '
            'local oldTween, oldSetting = W.Tween, F.Setting; local mode, pending = "full", {}; '
            'F.Setting = function(key) if key == "celebrations" then return mode end return oldSetting(key) end; '
            'W.Tween = function(key, dur, fn, done) '
            'if key ~= "noteOpen" and key ~= "noteClose" then return oldTween(key, dur, fn, done) end; '
            'if not dur then pending[key] = nil; return end; '
            'if mode == "off" then fn(1); if done then done() end; return end; '
            'pending[key] = {fn = fn, done = done}; fn(0) end; '
            'F.OpenNoteCard(g); assert(T.greyActive and T.greyAmount == 0 and alpha == 0 and scale < 1, "opening starts softly"); '
            'local tw = pending.noteOpen; tw.fn(0.5); assert(T.greyAmount > 0 and T.greyAmount < 1 and alpha > 0 and alpha < 1); '
            'tw.fn(1); tw.done(); assert(T.greyAmount == 1 and alpha == 1 and scale == 1); '
            'local style; T.save.SetEtch = function(_, s) style = s end; T.save.IsMouseOver = function() return false end; '
            'F.StyleNoteControls(); local normal = style; T.save.IsMouseOver = function() return true end; F.StyleNoteControls(); '
            'assert(T.save.gold and style ~= normal, "gold hover differs from rest"); '
            'F.CloseNoteCard(); assert(T.closing and pending.noteClose and pending.noteOpen == nil); '
            'tw = pending.noteClose; tw.fn(1); tw.done(); assert(T.goal == nil and T.greyActive == nil and alpha == 1 and scale == 1); '
            'F.OpenNoteCard(g); pending.noteOpen.fn(0.2); F.CloseNoteCard(true); assert(not T.greyActive and not pending.noteOpen); '
            'mode = "subtle"; F.OpenNoteCard(g); pending.noteOpen.fn(0.5); assert(scale == 1 and alpha < 1); F.CloseNoteCard(true); '
            'mode = "off"; F.OpenNoteCard(g); assert(alpha == 1 and scale == 1 and T.greyAmount == 1); '
            'F.CloseNoteCard(); assert(T.goal == nil and not T.greyActive); W.Tween, F.Setting = oldTween, oldSetting; '
            'print("  fades, pop, hover, interrupted close and motion settings ok")'),
        ("forever personal note layout", None,
            'local F = STUB_NS; local g = F.GoalById("ashbringer"); F.SelectGoal(g.id); '
            'local anchor; F.foreverNotice.SetPoint = function(_, point, relative) if point == "TOPLEFT" then anchor = relative end end; '
            'F.LayoutForeverInfo(g); assert(anchor == F.goalBanner.description, "notice follows description after note"); '
            'F.SetGoalNote(g, ""); assert(anchor ~= F.personalNote, "empty note removes gap"); '
            'F.SetGoalNote(g, "Bring resistance gear."); '
            'local oldNotice = F.ForeverNote; F.ForeverNote = function() return nil end; '
            'F.LayoutForeverInfo(g); assert(F.LayoutPersonalNote(g) == F.goalBanner.description); F.ForeverNote = oldNotice; '
            'print("  personal note layout with and without Forever notice ok")', True),
        ("reset icon and undo countdown", None,
            'local F, D = STUB_NS, ForeverGoalTrackerDB; local now, timers = 100, {}; '
            'local oldTime, oldAfter = GetTime, C_Timer.After; GetTime = function() return now end; '
            'C_Timer.After = function(_, fn) timers[#timers + 1] = fn end; '
            'D.active.ashbringer = true; D.progress.ashbringer = {true, true, true, true, true, true}; D.goalsDone.ashbringer = true; D.goalDates.ashbringer = 123; '
            'F.SelectGoal("ashbringer"); local b = F.resetBtn; local click = b:GetScript("OnClick"); '
            'GameTooltip = GameTooltip; local tipLines = {}; GameTooltip.AddLine = function(_, text) tipLines[#tipLines + 1] = text end; '
            'b.IsMouseOver = function() return true end; GameTooltip.IsOwned = function() return true end; '
            'click(); assert(F.resetUndo.expires == 110 and not D.progress.ashbringer[1], "reset"); '
            'assert(tipLines[#tipLines] == "10 seconds left", "initial tooltip: " .. tostring(tipLines[#tipLines])); '
            'local rotation; b.icon.SetRotation = function(_, r) rotation = r end; '
            'b:GetScript("OnUpdate")(b, 0.325); assert(rotation > 3 and rotation < 3.2, "counterclockwise half turn"); '
            'b:GetScript("OnUpdate")(b, 0.325); assert(rotation == 0 and b.spin == nil, "rotation end"); '
            'now = 104.1; b:GetScript("OnUpdate")(b, 0); assert(tipLines[#tipLines] == "6 seconds left", "countdown"); '
            'local pops, oldPop = 0, F.PopCheck; F.PopCheck = function(...) pops = pops + 1; return oldPop(...) end; '
            'click(); assert(D.progress.ashbringer[1] and D.goalsDone.ashbringer and D.goalDates.ashbringer == 123, "restore"); '
            'assert(pops >= #F.GoalById("ashbringer").steps and F.restoringReset == nil and F.quietCelebrate == nil, "animated restore: " .. pops); F.PopCheck = oldPop; '
            'assert(F.resetUndo == nil); timers[1](); '
            'click(); now = 114.1; b:GetScript("OnUpdate")(b, 0); assert(F.resetUndo == nil); '
            'assert(tipLines[#tipLines - 1] == "Reset this goal"); '
            'click(); assert(F.resetUndo); F.SelectGoal("atiesh"); assert(F.resetUndo == nil); '
            'GetTime, C_Timer.After = oldTime, oldAfter; print("  reset, rotation, countdown, restore, expiry and goal switching ok")'),
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
        # Profession-aware suggestions: Fishing goals only for a character who
        # knows Fishing; secondary skills offered only when known.
        ("suggestions follow professions", None,
            'STUB_PRINTS = {}; local W = STUB_NS.welcome; local D = ForeverGoalTrackerDB; D.active.fishing_extravaganza = nil; D.active.prof_secondary = nil; D.activeParts.prof_secondary = nil; '
            'local mine = D.characters[next(D.characters)]; local old = mine.skills.Fishing; local oldCooking = mine.skills.Cooking; '
            'local function ids() STUB_NS.OpenWelcome(nil, nil); W.picked = { collect = true, grind = true }; W.Show(3); local t = {}; '
            'for _, e in ipairs(W.list) do t[e.goal.id] = e end; STUB_NS.CloseWelcome(true); return t end; '
            'local others = {}; for k, c in pairs(D.characters) do if c ~= mine and c.skills then others[k] = c.skills.Fishing; c.skills.Fishing = nil end end; '
            'mine.skills.Fishing, mine.skills.Cooking = nil, nil; local t = ids(); '
            'assert(not t.fishing_extravaganza, "no Fishing, no tournament"); assert(not t.prof_secondary, "no secondary skills known"); '
            'mine.skills.Fishing = 224; t = ids(); assert(not t.fishing_extravaganza, "a casual fisher is not"); '
            'mine.skills.Fishing = 225; t = ids(); assert(t.fishing_extravaganza, "an angler is offered the tournament"); '
            'assert(STUB_NS.KnowsSkill("Fishing") and not STUB_NS.KnowsSkill("Mining") and not STUB_NS.KnowsSkill(nil), "KnowsSkill reads the roster"); '
            'mine.skills.Fishing, mine.skills.Cooking = old, oldCooking; for k, v in pairs(others) do D.characters[k].skills.Fishing = v end; '
            'print("  fishing and secondary skills suggested only when the character knows them")'),
        # Goals that are pure progress (a standing, a skill, a counter) are confirmed in Forever: no notice.
        ("confirmed in Forever", None,
            'local F = STUB_NS; local ids = { "rep_timbermaw", "rep_thorium", "rep_argentdawn", "rep_cenarion", "rep_zandalar", "rep_hydraxian", "rep_nozdormu", '
            '"rep_ambassador_ally", "rep_ambassador_horde", "prof_secondary", "prof_all", "pvp_wsg_ally", "pvp_ab_ally", "pvp_av_ally", "pvp_wsg_horde", "pvp_ab_horde", "pvp_av_horde", '
            '"gold_5k", "social_guild", "social_friends", "allclasses" }; '
            'for _, id in ipairs(ids) do local g = F.GoalById(id); assert(g, id); assert(F.ForeverStatus(g) == "confirmed", id .. " is confirmed"); '
            'assert(F.ForeverNote(g) == nil and F.ForeverNote(g, true) == nil, id .. " shows no notice") end; '
            'assert(F.ForeverNote(F.GoalById("raid_mc")), "an unchecked raid still says unconfirmed"); '
            'print("  " .. #ids .. " pure-progress goals show no unconfirmed notice; content goals still do")', True),
        # Ctrl-click on an armor set's big icon tries on every piece.
        ("try on a whole set", None,
            'local F = STUB_NS; local g = F.GoalById("set_tier1_warrior"); local ids = F.SetPreviewIds(g); '
            'assert(ids and #ids >= 5, "a Tier 1 set lists its pieces"); assert(F.SetPreviewIds(F.GoalById("thunderfury")) == nil, "a weapon is not a set"); '
            'local dressed = {}; DressUpItemLink = function(link) dressed[#dressed + 1] = link end; IsModifiedClick = function() return true end; '
            'F.ItemInfo = function(id) return "Item" .. id, "|Hitem:" .. id .. "|h[Item]|h", 4, 0, 0, "", "", 1, "INVTYPE_CHEST" end; '
            'assert(F.PreviewSetClick(g, "LeftButton") == true and #dressed == #ids, "every piece goes on: " .. #dressed .. " of " .. #ids); '
            'local resets = 0; DressUpFrame = { IsShown = function() return true end, ResetButton = { Click = function() resets = resets + 1 end } }; '
            'dressed = {}; assert(F.PreviewSetClick(g, "LeftButton") and resets == 1 and #dressed == #ids, "an open dressing room is reset first"); DressUpFrame = nil; '
            'assert(not F.PreviewSetClick(g, "RightButton"), "only a left click"); IsModifiedClick = function() return false end; '
            'assert(not F.PreviewSetClick(g, "LeftButton"), "only with the Ctrl-click modifier"); IsModifiedClick = function() return true end; '
            'dressed = {}; F.ItemInfo = function(id) if id == ids[1] then return nil end return "Item" .. id, "|Hitem:" .. id .. "|h[Item]|h", 4, 0, 0, "", "", 1, "INVTYPE_CHEST" end; '
            'STUB_PRINTS = {}; assert(F.PreviewSetClick(g, "LeftButton") and #dressed == #ids - 1, "a hidden piece is skipped, the rest go on"); '
            'print("  Ctrl-click tries on every piece of a set, skips pieces the game has no details for")'),
        # Image effects used to be on or off; an old Off is still Off.
        ("image effects: old save", 'ForeverGoalTrackerDB.settings = ForeverGoalTrackerDB.settings or {}; ForeverGoalTrackerDB.settings.imageEffects = false',
            'assert(ForeverGoalTrackerDB.settings.imageEffects == "off" and STUB_NS.EffectsLevel() == "off", "an old Off becomes Off"); ForeverGoalTrackerDB.settings.imageEffects = nil; print("  an old Image effects Off stays Off")'),
        # /goals audit asks the game about every item, quest, faction and map we rely on.
        ("data audit", None,
            'local A = STUB_NS.Audit; local T = A.Targets(); local n = 0; for _ in pairs(T.items) do n = n + 1 end; '
            'assert(n > 300, "the audit knows our items: " .. n); assert(T.items[19019] or next(T.items), "items listed"); '
            'assert(next(T.quests) and next(T.factions) and next(T.maps), "quests, factions and maps listed"); '
            'STUB_PRINTS = {}; SlashCmdList["FOREVERGOALTRACKER"]("audit"); '
            'local D = ForeverGoalTrackerDB; assert(D.audit and D.audit.items and D.audit.caps, "the answers are saved"); '
            'assert(not A.running, "the audit finished"); SlashCmdList["FOREVERGOALTRACKER"]("audit clear"); assert(D.audit == nil, "audit clear"); '
            'print("  audit: " .. n .. " items listed, answers saved and cleared")'),
        # /goals addblooms puts every goal whose banner blooms on My Goals.
        ("add bloom goals", None,
            'STUB_PRINTS = {}; local D = ForeverGoalTrackerDB; SlashCmdList["FOREVERGOALTRACKER"]("addblooms"); '
            'local n = 0; for _, id in ipairs(STUB_NS.BLOOM_GOALS) do local g = STUB_NS.GoalById(id); assert(g, "a real goal: " .. id); '
            'if D.active[id] then n = n + 1 end end; assert(n >= 36, "most are on My Goals: " .. n); '
            'assert(D.active.thunderfury and D.active.raid_mc and D.active.set_tier2_shaman, "key goals added"); print("  addblooms: " .. n .. " goals added")'),
        # On Forever the new raids and their Tier 0.5 set lead the raiding suggestions, before Molten Core.
        ("forever raids lead suggestions", None,
            'STUB_PRINTS = {}; local W = STUB_NS.welcome; STUB_NS.OpenWelcome(nil, nil); W.picked = { raid = true }; W.Show(3); '
            'local first = {}; local ids = {}; for i, e in ipairs(W.list) do local id = e.goal.id; ids[#ids + 1] = id; '
            'for _, key in ipairs({ "raid_barrow", "raid_hyjal", "set_forever_raid", "set_tier1", "raid_mc" }) do if id:sub(1, #key) == key and not first[key] then first[key] = i end end end; '
            'local list = table.concat(ids, ", "); '
            'assert(first.raid_barrow and first.raid_hyjal and first.set_forever_raid, "the Forever raids and their set are suggested: " .. list); '
            'assert(first.raid_barrow < first.raid_hyjal and first.raid_hyjal < first.set_forever_raid, "raids, then their set: " .. list); '
            'assert(not first.set_tier1 or first.set_forever_raid < first.set_tier1, "Tier 0.5 comes before Tier 1: " .. list); '
            'assert(not first.raid_mc or first.set_forever_raid < first.raid_mc, "and before Molten Core: " .. list); '
            'STUB_NS.CloseWelcome(true); print("  Forever raids and the Tier 0.5 set lead the raiding suggestions: " .. list)', True),
        # Blown sand (Ruins of Ahn'Qiraj): grains travel with the wind, streaked along it, and the wind is steady.
        ("blown sand", None,
            'local F = STUB_NS; local B = F.goalBanner; '
            'rawset(B.art, "GetWidth", function() return 700 end); '
            'B.goal = F.GoalById("raid_aq20"); B.hasArt, B.shownArtHeight, B.uv, B.sourceAspect, B.imageFade = true, 520, { 0, 1, 0, 1 }, 4/3, 1; '
            'B.glowLevel = 0.5; B.emberFor = nil; B:PlaceGlow(); '
            'assert(B.glowSpec and B.glowSpec.embers and B.glowSpec.embers.drift, "Ruins of Ahn\'Qiraj has blown sand"); '
            'assert(B.glowSpec.bloom, "and keeps its bloom"); '
            'B:ResetEmbers(); assert(B.emberCount == 110, "110 sand particles: " .. tostring(B.emberCount)); '
            'local grains, haze, wide = 0, 0, 0; for k = 1, B.emberCount do local e = B.emberDots[k]; '
            '  if e.blur then haze = haze + 1 else grains = grains + 1 end; if (e.stretch or 1) > 2 then wide = wide + 1 end end; '
            'assert(haze >= 9 and haze <= 17 and wide == haze, "grains are near-round specks, only the dust puffs streak: " .. haze .. " " .. wide); '
            'local x0 = {}; for k = 1, B.emberCount do x0[k] = B.emberDots[k].x end; '
            'B.glowAnim.t = 0; for _ = 1, 30 do B.glowAnim.t = B.glowAnim.t + 1/30; B:StepEmbers(1/30) end; '
            'local left, moved = 0, 0; for k = 1, B.emberCount do local e = B.emberDots[k]; '
            '  if not e.wait and e.age > 1 then moved = moved + 1; if e.x < x0[k] then left = left + 1 end end end; '
            'assert(moved > 20 and left / moved > 0.9, "the wind carries sand to the left: " .. left .. " of " .. moved); '
            'local lean, n = 0, 0; for k = 1, B.emberCount do local e = B.emberDots[k]; if not e.wait then lean = lean + math.sin(e.heading); n = n + 1 end end; '
            'assert(math.abs(lean / n) < 0.03, "the default wind blows level (Karl, 2026-10-14): " .. lean / n); '
            'local seen = {}; local tex = B.emberDots[1].tex; local oldA = tex.SetAlpha; tex.SetAlpha = function(_, a) seen[#seen + 1] = a end; '
            'local e1 = B.emberDots[1]; e1.wait, e1.age, e1.life, e1.alphaNow, e1.shownNow = nil, 1, 10, nil, nil; e1.x, e1.y, e1.sway = 600, 519, 0; e1.heading, e1.curve, e1.speed = math.pi, 0, 0; '
            'B:StepEmbers(1/60); tex.SetAlpha = oldA; '
            'assert(seen[#seen] == 0, "sand at the very bottom, where the art has faded away, is invisible: " .. tostring(seen[#seen])); '
            'local drift = e1.cfg.drift; e1.cfg.drift = nil; seen = {}; tex.SetAlpha = function(_, a) seen[#seen + 1] = a end; e1.alphaNow, e1.shownNow, e1.heading = nil, nil, -math.pi/2; '
            'B:StepEmbers(1/60); tex.SetAlpha = oldA; e1.cfg.drift = drift; '
            'assert(seen[#seen] == 0, "so is a fire ember there (every particle shares the bottom fade): " .. tostring(seen[#seen])); '
            'local gz = B.glows["social_guild_dungeon-banner.blp"]; assert(gz and gz.embers.drift and (gz.embers.wind or 180) == 180 and gz.embers.count == 140, "Gahz\'rilla\'s sandstorm blows level"); '
            'local cen = B.glows["rep_cenarion-banner.blp"]; assert(cen and cen.embers and cen.embers.drift, "Cenarion Circle has blown sand"); '
            'assert(not B:IsLeafy("rep_cenarion", "rep_cenarion-banner.blp"), "and no drifting leaves with it"); '
            'print("  blown sand: 70 particles leftward, streaked, bloom kept, steady wind; Cenarion sand without leaves ok")'),
        # Classic Era has no talent-window atlas: the goal page's leaves and clouds use our own textures.
        ("Classic Era ambience", None,
            'local A = STUB_NS.ambience; assert(A and A.own, "Classic Era gets our own clouds and leaves"); '
            'assert(#A.layers == 4, "two leaf layers and two cloud layers: " .. #A.layers); '
            'local steady = 0; for _, l in ipairs(A.layers) do if l.steady then steady = steady + 1 end end; '
            'assert(steady == 2, "both cloud copies scroll end to end"); '
            'print("  Classic Era ambience: our clouds and leaves, four layers ok")'),
        # Ritual of Summoning (spell 698) counts for Warlocks, once per ritual.
        ("summon counter", None,
            'local F, D = STUB_NS, ForeverGoalTrackerDB; local g = F.GoalById("social_summons"); '
            'assert(g and g.classes.WARLOCK and g.icon[1] == "spell_shadow_twilight" and g.forever == "confirmed", "Summon Players goal"); '
            'D.active.social_summons = true; local c = D.characters[next(D.characters)]; c.counts = nil; '
            'assert(not F.CanSummon(), "a Warrior cannot summon"); UnitClass = function() return "Warlock", "WARLOCK" end; '
            'assert(F.CanSummon(), "a Warlock can"); F.WatchCasts(); assert(F.watchingCasts, "casts are watched for a Warlock"); '
            'local now = 100; GetTime = function() return now end; '
            'STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "a", 133); assert(((c.counts or {}).summons or 0) == 0, "another spell does not count"); '
            'STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "b", 698); now = 101; STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 698); '
            'assert(c.counts.summons == 1, "one ritual counts once: " .. tostring(c.counts.summons)); '
            'for i = 1, 4 do now = now + 6; STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "d" .. i, 698) end; '
            'assert(c.counts.summons == 5, "five rituals"); assert(D.progress.social_summons and D.progress.social_summons[1] and not D.progress.social_summons[2], "five summons tick the first step only"); '
            'print("  summons: Warlock only, one count per ritual, first step at five ok")'),
        # New social goals: boss kills with guildmates, completed trades and campfires are counted by the addon.
        ("social counters", None,
            'local F, D = STUB_NS, ForeverGoalTrackerDB; for _, id in ipairs({ "social_guild_dungeon", "social_guild_raid", "social_trades" }) do assert(F.GoalById(id), id); D.active[id] = true end; '
            'local me = D.characters[next(D.characters)]; me.counts = nil; '
            'IsInInstance = function() return true, "party" end; IsInGuild = function() return true end; IsInRaid = function() return false end; '
            'UnitIsInMyGuild = function(u) return u == "party1" end; UnitExists = function() return true end; UnitIsUnit = function() return false end; GetNumGroupMembers = function() return 3 end; '
            'STUB_FIRE("ENCOUNTER_END", 1, "Test Boss", 1, 5, 1); STUB_FIRE("BOSS_KILL", 1, "Test Boss"); '
            'local c = D.characters[next(D.characters)]; '
            'assert(c.counts and c.counts.guildDungeonBosses == 1, "a dungeon boss with one guildmate counts once, not twice for the two events: " .. tostring(c.counts and c.counts.guildDungeonBosses)); '
            'IsInInstance = function() return true, "raid" end; GetNumGroupMembers = function() return 10 end; IsInRaid = function() return true end; UnitIsInMyGuild = function(u) return u == "raid2" or u == "raid3" end; '
            'STUB_FIRE("ENCOUNTER_END", 2, "Raid Boss", 1, 10, 1); assert((c.counts.guildRaidBosses or 0) == 0, "two guildmates are not a guild raid"); '
            'UnitIsInMyGuild = function(u) return u:find("^raid[2-7]$") ~= nil end; STUB_FIRE("ENCOUNTER_END", 3, "Another Raid Boss", 1, 10, 1); '
            'assert(c.counts.guildRaidBosses == 1, "six guildmates in the raid count"); '
            'ERR_TRADE_COMPLETE = "Trade complete."; for i = 1, 5 do STUB_FIRE("UI_INFO_MESSAGE", 0, "Trade complete.") end; STUB_FIRE("UI_INFO_MESSAGE", 0, "Something else"); '
            'assert(c.counts.trades == 5, "five completed trades: " .. tostring(c.counts.trades)); '
            'assert(D.progress.social_trades and D.progress.social_trades[1] and not D.progress.social_trades[2], "five trades tick the first step only"); '
            'assert(not STUB_NS.CampfireReady(), "no campfires on Classic Era"); STUB_NS.isForever = true; STUB_NS.WatchCasts(); '
            'assert(STUB_NS.CampfireReady(), "the campfire spells are known"); STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 12345); assert((c.counts.campfires or 0) == 0, "an unrelated spell does not count"); '
            'STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 1307227); STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 1229737); assert(c.counts.campfires == 1, "placing a campfire counts once: " .. tostring(c.counts.campfires)); '
            'STUB_NS.lastCampfire = -100; STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 1307252); assert(c.counts.campfires == 2, "a later Journeyman campfire counts"); '
            'STUB_NS.isForever = false; STUB_NS.WatchCasts(); '
            'UnitClass = function() return "Mage", "MAGE" end; STUB_NS.WatchCasts(); assert(STUB_NS.CanBuff(), "a Mage can buff"); '
            'GetSpellInfo = function(id) return ({ [1459] = "Arcane Intellect", [23028] = "Arcane Brilliance", [133] = "Fireball" })[id] end; local mine = UnitName("player"); '
            'STUB_NS.buffSpellCache = {}; local b0 = c.counts.buffs or 0; '
            'STUB_FIRE("UNIT_SPELLCAST_SENT", "player", "Bob", "g1", 1459); assert(STUB_NS.pendingBuffs and STUB_NS.pendingBuffs.g1, "the cast is remembered when sent"); STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "g1", 1459); assert(c.counts.buffs == b0 + 1, "Arcane Intellect on another player counts: buffs=" .. tostring(c.counts.buffs) .. " watching=" .. tostring(STUB_NS.watchingCasts) .. " name=" .. tostring(STUB_NS.BuffSpellName(1459)) .. " pending=" .. tostring(STUB_NS.pendingBuffs and STUB_NS.pendingBuffs.g1)); '
            'STUB_FIRE("UNIT_SPELLCAST_SENT", "player", mine, "g2", 1459); STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "g2", 1459); assert(c.counts.buffs == b0 + 1, "a buff on yourself does not"); '
            'STUB_FIRE("UNIT_SPELLCAST_SENT", "player", "Bob", "g3", 1459); assert(c.counts.buffs == b0 + 1, "a cast that has not succeeded does not"); '
            'STUB_FIRE("UNIT_SPELLCAST_SENT", "player", "Bob", "g4", 133); STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "g4", 133); assert(c.counts.buffs == b0 + 1, "a fireball is not a buff"); '
            'GetNumGroupMembers = function() return 1 end; STUB_FIRE("UNIT_SPELLCAST_SENT", "player", "", "g5", 23028); STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "g5", 23028); assert(c.counts.buffs == b0 + 1, "Arcane Brilliance alone does not"); '
            'GetNumGroupMembers = function() return 4 end; STUB_FIRE("UNIT_SPELLCAST_SENT", "player", "", "g6", 23028); STUB_FIRE("UNIT_SPELLCAST_SUCCEEDED", "player", "g6", 23028); assert(c.counts.buffs == b0 + 2, "Arcane Brilliance in a group does"); '
            'print("  guild dungeon and raid kills, trades and campfires are counted")'),
        # The emote goals read Forever's Statistics window (hugs, cheers, waves, LOLs).
        ("emote goals", None,
            'local F = STUB_NS; for id, stat in pairs({ social_hugs = 1042, social_cheers = 1045, social_waves = 1065, social_lol = 1066 }) do '
            'local g = F.GoalById(id); assert(g and g.category == "Social" and g.needs == "stats", id); assert(g.steps[1].auto.stat.id == stat and #g.steps == 4, id .. " steps"); '
            'end; '
            'print("  four emote goals read Statistics 1042, 1045, 1065 and 1066")'),
        # A step's count bar glides to a new count on the same step and jumps when its row is reused.
        ("step count bars glide", None,
            'local F = STUB_NS; local calls = {}; local row = { miniBar = { SetProgress = function(self, cur, max) calls[#calls + 1] = { cur = cur, instant = self.instant } end } }; '
            'F.MiniProgress(row, "social_buffs:1", 10, 100); F.MiniProgress(row, "social_buffs:1", 30, 100); '
            'F.MiniProgress(row, "social_trades:2", 5, 25); F.MiniProgress(row, "social_trades:2", 9, 25); '
            'assert(calls[1].instant == true, "a row showing a step for the first time jumps"); '
            'assert(not calls[2].instant, "the same step glides to 30"); '
            'assert(calls[3].instant == true, "a reused row jumps to the other goal value"); '
            'assert(not calls[4].instant and row.miniBar.instant == nil, "and then glides"); '
            'F.quietCelebrate = true; F.MiniProgress(row, "social_trades:2", 12, 25); assert(calls[5].instant == true, "silent redraws jump"); F.quietCelebrate = nil; '
            'print("  step count bars glide on the same step and jump on a reused row")'),
        # /goals perf times the banner effects; without an animated banner it says how to start.
        ("perf command", None,
            'STUB_PRINTS = {}; SlashCmdList["FOREVERGOALTRACKER"]("perf"); SlashCmdList["FOREVERGOALTRACKER"]("perf 5")'),
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
            'STUB_NS.CloseWowheadCard(); '
            'local row2 = { text = { GetText = function(self) return self.s end, SetText = function(self, s) self.s = s end } }; '
            'row2.text:SetText("Turn in the four demon heads to Vartrus for Lok\'delar and the Ancient Rune Etched Stave."); '
            'local lok = STUB_NS.GoalById("lokdelar"); local st = lok.steps[#lok.steps]; STUB_NS.SetStepLinks(row2, st.auto, st); '
            'print("  step 7: " .. row2.text:GetText()); '
            'local row3 = { text = { GetText = function(self) return self.s end, SetText = function(self, s) self.s = s end } }; '
            'local ram = STUB_NS.GoalById("epicmounts").sections[2].pieces[5]; row3.text:SetText(ram.name); STUB_NS.stepQuality = 4; '
            'STUB_NS.SetStepLinks(row3, ram.auto, ram); print("  ram: " .. row3.text:GetText()); '
            'STUB_NS.ShowVariantsTip({}, 18786, ram.auto); STUB_NS.OpenVariantsWowhead(18786); print("  " .. STUB_NS.wowheadCard.url)'),
        # NPC links: teal names (longest name first, aliases, not inside
        # other links), the map pin without TomTom, then with TomTom.
        ("npc links", None,
            'STUB_PRINTS = {}; TomTom = false; '
            'print("  " .. STUB_NS.LinkText("Bring the leaf to Vartrus the Ancient in Felwood.")); '
            'print("  " .. STUB_NS.LinkText("Turn in the sinew to Vartrus for the {lokdelar:Lokdelar} reward.")); '
            'print("  " .. STUB_NS.LinkText("Solo Artorius the Doombringer in Winterspring.")); '
            'STUB_NS.ShowNpcTip({}, 14535); STUB_NS.ShowNpcOnMap(14524); STUB_NS.ShowNpcOnMap(14387); '
            'TomTom = { AddWaypoint = function(self, m, x, y, o) print("  tomtom: " .. m .. " " .. x .. " " .. y .. " " .. o.title) end }; '
            'STUB_NS.ShowNpcOnMap(14535); STUB_NS.SetSetting("mapPins", "game"); print("  set to game map:"); STUB_NS.ShowNpcOnMap(14535); '
            'STUB_NS.SetSetting("mapPins", "auto"); TomTom = nil; '
            'STUB_NS.OpenWowheadCard("npc", 14524, "Vartrus", nil, STUB_NS.NpcById(14524)); print("  card: " .. STUB_NS.wowheadCard.url); '
            'STUB_NS.OpenWowheadCard("item", 16866, "Helm")'),
        # On Forever: Lothos has Forever's own spot (outside the mountain).
        ("npc spots on forever", None,
            'STUB_PRINTS = {}; TomTom = false; STUB_NS.ShowNpcOnMap(14387); local h = STUB_NS.NpcById(3685); '
            'print("  harb: " .. h.x .. ", " .. h.y)', True),
        # Goal link shine: mid-sweep the link's letters get their own golds;
        # the link and the text around it stay intact. Then the link card.
        ("goal link gradient", None,
            'STUB_PRINTS = {}; local t = STUB_NS.LinkText("Get {att_naxx:attuned to Naxxramas} at the chapel."); '
            'local s = STUB_NS.ScanText(t, 0.2); print("  " .. s); '
            'print("  plain: " .. s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")); '
            'STUB_NS.OpenLinkCard("att_naxx"); print("  add comet on: " .. tostring(STUB_NS.linkCard.btn.comet.on))'),
        # Quest links: the "!" and yellow link (quoted names only), next to
        # an NPC link; the tooltip, a per-class quest's Wowhead search.
        ("quest links", None,
            'STUB_PRINTS = {}; '
            'print("  " .. STUB_NS.LinkText("Pick up \'A Proper String\' from Stoma the Ancient in Felwood.")); '
            'print("  " .. STUB_NS.LinkText("Bring the Frame of Atiesh to Anachronos.")); '
            'print("  " .. STUB_NS.LinkText("Turn in \'Frostsaber Provisions\' daily.")); '
            'print("  " .. STUB_NS.LinkText("Bring a {item:12811:Righteous Orb} to {rep_argentdawn:the Argent Dawn}.")); '
            'STUB_NS.ShowQuestTip({}, 4); STUB_NS.QuestWowhead(4); print("  " .. STUB_NS.wowheadCard.url); '
            'for k, q in ipairs(STUB_NS.QUESTS) do if q.perClass then STUB_NS.QuestWowhead(k); break end end; '
            'print("  " .. STUB_NS.wowheadCard.url)'),
        # /goals shots: walks every gallery scene, takes a screenshot each,
        # and puts demo mode, photo mode and the screenshot format back.
        ("gallery screenshots", None,
            'STUB_PRINTS = {}; local shots, cv = 0, {}; Screenshot = function() shots = shots + 1 end; '
            'SetCVar = function(k, v) cv[k] = v end; GetCVar = function(k) return k == "screenshotFormat" and "jpeg" or "3" end; '
            'for _, f in ipairs(STUB_FRAMES) do rawset(f, "IsShown", function() return true end) end; '
            'SlashCmdList["FOREVERGOALTRACKER"]("shots"); '
            'print("  screenshots: " .. shots .. ", format back to " .. tostring(cv.screenshotFormat) .. ", demo off: " .. tostring(ForeverGoalTrackerDB.demoBackup == nil))'),
        # Link sweep (2026-10-07): extra items link before the rule item
        # ("Eye of Sulfuras" before "Sulfuras"), and a name inside a quest
        # link is skipped for its next spot ('Rise, Thunderfury!').
        ("link sweep", None,
            'STUB_PRINTS = {}; '
            'C_Item = { GetItemInfo = function(id) local n = ({ [17182] = "Sulfuras, Hand of Ragnaros", [19019] = "Thunderfury, Blessed Blade of the Windseeker" })[id]; if n then return n, nil, 5 end end }; '
            'local function Row(t) return { text = { GetText = function(self) return self.s end, SetText = function(self, s) self.s = s end } } end; '
            'local sul = STUB_NS.GoalById("sulfuras"); for _, st in ipairs(sul.steps) do if type(st) == "table" and st.text:find("^Combine") then '
            'local r = Row(); r.text:SetText(STUB_NS.LinkText(st.text)); STUB_NS.SetStepLinks(r, st.auto, st); print("  " .. r.text:GetText()) end end; '
            'local tf = STUB_NS.GoalById("thunderfury"); for _, st in ipairs(tf.steps) do if type(st) == "table" and st.text:find("^Turn in .Rise") then '
            'local r = Row(); r.text:SetText(STUB_NS.LinkText(st.text)); STUB_NS.SetStepLinks(r, st.auto, st); print("  " .. r.text:GetText()) end end; '
            'local ash = STUB_NS.GoalById("ashbringer"); print("  " .. STUB_NS.LinkText(ash.tips[2])); C_Item = nil'),
        # Quest starts: every start NPC is in Npcs.lua (so tooltips can say
        # where), and the quests that begin from an item name it.
        ("quest starts", None,
            'STUB_PRINTS = {}; local missing, items = {}, 0; '
            'for _, q in ipairs(STUB_NS.QUESTS) do '
            'if q.start and not STUB_NS.NpcById(q.start) then table.insert(missing, q.startName) end; '
            'if q.startItem then items = items + 1 end end; '
            'print("  start NPCs missing from Npcs.lua: " .. (#missing > 0 and table.concat(missing, ", ") or "none") .. "; item starts: " .. items)'),
        # Test commands: add every goal, then reset all (asks first) and undo.
        ("add all and reset all", None,
            'STUB_PRINTS = {}; local S = SlashCmdList["FOREVERGOALTRACKER"]; S("addall"); '
            'print("  active: " .. #STUB_NS.ActiveGoals()); '
            'ForeverGoalTrackerDB.progress.gold_5k = { [1] = true }; S("resetall"); S("resetall"); '
            'print("  gold ticks after reset: " .. tostring(ForeverGoalTrackerDB.progress.gold_5k[1])); '
            'S("resetall undo"); print("  gold ticks after undo: " .. tostring(ForeverGoalTrackerDB.progress.gold_5k[1]))'),
        # The demo scenes, then everything back.
        ("demo scenes", None,
            'STUB_PRINTS = {}; for i = 1, 8 do SlashCmdList["FOREVERGOALTRACKER"]("demo " .. i) end; '
            'print("  demo gold name: " .. STUB_NS.GoalById("gold_5k").name); '
            'SlashCmdList["FOREVERGOALTRACKER"]("demo off"); print("  after off: " .. STUB_NS.GoalById("gold_5k").name)'),
    ]
    demo_new = ('local S, F, D = SlashCmdList["FOREVERGOALTRACKER"], STUB_NS, ForeverGoalTrackerDB; local LF = F.libState; '
        'D.active = { raid_mc = true }; '
        'S("demo 9"); assert(D.active.tier3_warrior and D.progress.tier3_warrior["1_1_m1"], "scene 9 stages Tier 3 materials"); '
        'assert(#F.MaterialRows(F.GoalById("tier3_warrior"), true) >= 9, "scene 9 has a real shopping list"); '
        'S("demo 10"); assert(LF.forWho == "WARRIOR" and LF.sort == "progression", "scene 10 sets For and Sort"); '
        'assert(D.goalsDone.set_tier1_warrior, "scene 10 finishes Tier 1"); '
        'local last = -1; for _, g in ipairs(LF.shown) do local r = F.SetOrder(g); assert(r >= last, "progression order"); last = r end; '
        'S("demo off"); assert(LF.forWho == "any" and LF.sort == "alpha", "demo off resets the Library"); '
        'assert(D.active.raid_mc and not D.active.tier3_warrior, "demo off restores your goals"); '
        'assert(not (F.materialsPanel and F.materialsPanel.open), "demo off closes the drawer"); '
        'S("demo 11"); assert(D.active.wolfsbane and D.progress.wolfsbane and next(D.progress.wolfsbane), "scene 11 stages Wolfsbane part way"); '
        'S("demo off"); assert(not D.active.wolfsbane, "demo off puts Wolfsbane back"); '
        'S("demo 12"); assert(D.active.mount_dreadsteed and D.progress.mount_dreadsteed and D.progress.mount_dreadsteed[4] and not D.progress.mount_dreadsteed[5], "scene 12 stages the Dreadsteed four steps in, the Gorzeeki step next"); '
        'S("demo off"); assert(not D.active.mount_dreadsteed, "demo off puts the Dreadsteed back"); '
        'assert(#F.SHOTS == 12, "twelve gallery shots"); print("  materials, Library, Wolfsbane and map scenes ok")')
    steps += [
        ("demo scenes: materials and Library", None, demo_new),
        ("Forever demo scenes: materials and Library", None, demo_new, True),
    ]
    armor_fixture = 'local F = STUB_NS; local r = F.GoalById("set_tier1_rogue").armorSection; local h = F.GoalById("set_tier1_hunter").armorSection; local t = F.GoalById("tier3_rogue").armorSection;\nForeverGoalTrackerDB = { active = {}, activeParts = { set_tier1 = {[r]=true,[h]=true}, tier3 = {[t]=true} }, progress = {set_tier1 = {[r.."_1_piece"]=true,[h.."_2_piece"]=true}, tier3 = {[t.."_1_m1"]=true}}, selected="set_tier1", notes={set_tier1="Keep this note"}, favorites={set_tier1=true}, goalsDone={set_tier1=true}, goalDates={set_tier1=123456}, t3RecipeFix=true, characters={} }; for pi in ipairs(F.GoalById("set_tier1_rogue").sections[1].pieces) do ForeverGoalTrackerDB.progress.set_tier1[r.."_"..pi.."_piece"] = true end'
    steps.extend([
        ("Gear Planner prototype", None, open(os.path.join(here, "gear-planner-tests.lua")).read()),
        ("Forever Gear Planner prototype", None, open(os.path.join(here, "gear-planner-tests.lua")).read(), True),
        ("Gear Planner saved-build reload", None, 'local d=ForeverGoalTrackerDB.gearPlanner.characters["PlannerOwner-"..GetRealmName()]; assert(d.builds[1].name == "Renamed"); assert(d.builds[1].id); local smoke=ForeverGoalTrackerDB.plannerPolishSmoke; local g=STUB_NS.GoalById(smoke.goalId); assert(g and g.name == "Tracked renamed" and #g.steps == 2); assert(not ForeverGoalTrackerDB.progress[g.id][1] and ForeverGoalTrackerDB.progress[g.id][2], "item credit survives fresh Lua reload"); print("  named gear build and tracked item credit survive reload")'),
        ("pop-out tracker", None, open(os.path.join(here, "popout-tests.lua"), encoding="utf-8").read()),
        ("Forever pop-out tracker", None, open(os.path.join(here, "popout-tests.lua"), encoding="utf-8").read(), True),
        ("pop-out refinements", None, open(os.path.join(here, "popout-refinement-tests.lua"), encoding="utf-8").read()),
        ("Forever pop-out refinements", None, open(os.path.join(here, "popout-refinement-tests.lua"), encoding="utf-8").read(), True),
        ("pop-out sizing and style", None, open(os.path.join(here, "popout-qol-tests.lua"), encoding="utf-8").read()),
        ("Forever pop-out sizing and style", None, open(os.path.join(here, "popout-qol-tests.lua"), encoding="utf-8").read(), True),
        ("goals rail", None, open(os.path.join(here, "rail-tests.lua"), encoding="utf-8").read()),
        ("Forever goals rail", None, open(os.path.join(here, "rail-tests.lua"), encoding="utf-8").read(), True),
        ("pop-out polish", None, open(os.path.join(here, "popout-polish-tests.lua"), encoding="utf-8").read()),
        ("Forever pop-out polish", None, open(os.path.join(here, "popout-polish-tests.lua"), encoding="utf-8").read(), True),
        ("materials panel", None, open(os.path.join(here, "materials-tests.lua"), encoding="utf-8").read()),
        ("Forever materials panel", None, open(os.path.join(here, "materials-tests.lua"), encoding="utf-8").read(), True),
        ("racial mount costs", None, open(os.path.join(here, "mount-cost-tests.lua")).read()),
        ("Forever racial mount costs", None, open(os.path.join(here, "mount-cost-tests.lua")).read(), True),
        ("typography helpers", 'ForeverGoalTrackerDB.settings = ForeverGoalTrackerDB.settings or {}; ForeverGoalTrackerDB.settings.typeStyle = "modern"', open(os.path.join(here, "type-style-tests.lua")).read()),
        ("Forever typography helpers", 'ForeverGoalTrackerDB.settings = ForeverGoalTrackerDB.settings or {}; ForeverGoalTrackerDB.settings.typeStyle = "modern"', open(os.path.join(here, "type-style-tests.lua")).read(), True),
        ("empty book artwork", None, open(os.path.join(here, "empty-book-tests.lua"), encoding="utf-8").read()),
        ("Forever empty book artwork", None, open(os.path.join(here, "empty-book-tests.lua"), encoding="utf-8").read(), True),
        ("item needs and previews", None, open(os.path.join(here, "item-tooltip-tests.lua"), encoding="utf-8").read()),
        ("Forever item needs and previews", None, open(os.path.join(here, "item-tooltip-tests.lua"), encoding="utf-8").read(), True),
        ("AQ40 battle tanks", None, open(os.path.join(here, "qiraji-tests.lua"), encoding="utf-8").read()),
        ("Forever AQ40 battle tanks", None, open(os.path.join(here, "qiraji-tests.lua"), encoding="utf-8").read(), True),
        ("Zin'rokh on Era", None, open(os.path.join(here, "zinrokh-tests.lua"), encoding="utf-8").read()),
        ("Zin'rokh on Forever", None, open(os.path.join(here, "zinrokh-tests.lua"), encoding="utf-8").read(), True),
        ("Library polish on Era", None, open(os.path.join(here, "library-polish-tests.lua"), encoding="utf-8").read()),
        ("Library polish on Forever", None, open(os.path.join(here, "library-polish-tests.lua"), encoding="utf-8").read(), True),
        ("guide fixes on Era", None, open(os.path.join(here, "guide-fixes-tests.lua"), encoding="utf-8").read()),
        ("guide fixes on Forever", None, open(os.path.join(here, "guide-fixes-tests.lua"), encoding="utf-8").read(), True),
        ("Teebu's on Era", None, open(os.path.join(here, "teebus-tests.lua"), encoding="utf-8").read()),
        ("Teebu's on Forever", None, open(os.path.join(here, "teebus-tests.lua"), encoding="utf-8").read(), True),
        ("Darkspear Islands reputations on Era", None, open(os.path.join(here, "darkspear-rep-tests.lua"), encoding="utf-8").read()),
        ("Darkspear Islands reputations on Forever", None, open(os.path.join(here, "darkspear-rep-tests.lua"), encoding="utf-8").read(), True),
        ("Wolfsbane on Era", None, open(os.path.join(here, "wolfsbane-tests.lua"), encoding="utf-8").read()),
        ("Wolfsbane on Forever", None, open(os.path.join(here, "wolfsbane-tests.lua"), encoding="utf-8").read(), True),
        ("fishing tournament", None, open(os.path.join(here, "fishing-tests.lua"), encoding="utf-8").read()),
        ("Forever fishing tournament", None, open(os.path.join(here, "fishing-tests.lua"), encoding="utf-8").read(), True),
        ("AQ40 armor sets", None, open(os.path.join(here, "aq-armor-tests.lua"), encoding="utf-8").read()),
        ("Forever AQ40 armor sets", None, open(os.path.join(here, "aq-armor-tests.lua"), encoding="utf-8").read(), True),
        ("completed step motion", None, open(os.path.join(here, "completed-step-motion-tests.lua"), encoding="utf-8").read()),
        ("Forever completed step motion", None, open(os.path.join(here, "completed-step-motion-tests.lua"), encoding="utf-8").read(), True),
        ("completed step filter", None, open(os.path.join(here, "completed-step-tests.lua"), encoding="utf-8").read()),
        ("Forever completed step filter", None, open(os.path.join(here, "completed-step-tests.lua"), encoding="utf-8").read(), True),
        ("individual armor sets", armor_fixture, open(os.path.join(here, "armor-tests.lua"), encoding="utf-8").read()),
        ("Forever individual armor sets", armor_fixture, open(os.path.join(here, "armor-tests.lua"), encoding="utf-8").read(), True),
        ("dungeon entrance links", None, open(os.path.join(here, "dungeon-link-tests.lua")).read()),
        ("Forever dungeon entrance links", None, open(os.path.join(here, "dungeon-link-tests.lua")).read(), True),
        ("goal banner layout", None, open(os.path.join(here, "banner-tests.lua"), encoding="utf-8").read()),
        ("Forever 70291 banner layout and image fades", None,
            open(os.path.join(here, "banner-tests.lua"), encoding="utf-8").read(), True),
        ("short goal window", None, open(os.path.join(here, "short-window-tests.lua"), encoding="utf-8").read()),
        ("window size bounds", None, open(os.path.join(here, "window-size-tests.lua")).read()),
        ("Forever window size bounds", None, open(os.path.join(here, "window-size-tests.lua")).read(), True),
        ("Forever short goal window", None, open(os.path.join(here, "short-window-tests.lua"), encoding="utf-8").read(), True),
        ("mount preview", None, open(os.path.join(here, "mount-preview-tests.lua")).read()),
        ("Forever mount preview", None, open(os.path.join(here, "mount-preview-tests.lua")).read(), True),
        ("guide progress migration", 'UnitLevel = function() return 1 end; ForeverGoalTrackerDB = {active={},progress={sulfuras={[10]=true,[11]=true,[12]=true,[13]=true},mount_dreadsteed={[1]=true,[3]=true,[4]=true,[5]=true,[7]=true},frostsaber={[1]=true,[2]=true,[3]=true,[8]=true},mount_charger={[1]=true,[11]=true},att_naxx={[1]=true,[2]=true},wolfsbane={[1]=true,[8]=true,[16]=true},benediction={[1]=true,[5]=true},lokdelar={[1]=true,[7]=true},rhokdelar={[1]=true,[5]=true},att_mc={[1]=true,[3]=true},att_bwl={[1]=true,[3]=true},mount_tiger={[1]=true,[2]=true},mount_raptor={[1]=true,[2]=true},mount_deathcharger={[1]=true,[2]=true,[3]=true}},tipsFix=true,stepsFix231=true}', open(os.path.join(here, "guide-edit-tests.lua")).read()),
        ("guide migration repeat login", 'UnitLevel = function() return 1 end', open(os.path.join(here, "guide-edit-tests.lua")).read()),
        ("beta guide migration", 'UnitLevel = function() return 1 end; ForeverGoalTrackerDB = {active={},guideFix20261011=true,repFix=true,frostRaceFix=true,tipsFix=true,stepsFix231=true,progress={sulfuras={[10]=true,[11]=true,[12]=true},frostsaber={[1]=true,[2]=true,[7]=true},mount_dreadsteed={[2]=true,[4]=true,[5]=true,[7]=true},mount_charger={[2]=true,[12]=true},att_naxx={[2]=true,[3]=true},wolfsbane={[2]=true,[9]=true,[17]=true},benediction={[1]=true,[5]=true},lokdelar={[1]=true,[7]=true},rhokdelar={[1]=true,[5]=true},att_mc={[1]=true,[3]=true},att_bwl={[1]=true,[3]=true},mount_tiger={[1]=true,[2]=true},mount_raptor={[1]=true,[2]=true},mount_deathcharger={[1]=true,[2]=true,[3]=true}}}', open(os.path.join(here, "guide-edit-tests.lua")).read()),
        ("step dependencies", None, open(os.path.join(here, "dependency-tests.lua"), encoding="utf-8").read()),
        ("Forever step-lock preview", None, open(os.path.join(here, "dependency-tests.lua"), encoding="utf-8").read(), True),
        ("dependency rollout and scope", None, open(os.path.join(here, "forever-dependency-rollout-tests.lua")).read()),
        ("Forever dependency rollout and scope", None, open(os.path.join(here, "forever-dependency-rollout-tests.lua")).read(), True),
        ("Forever dependency quest evidence", 'C_QuestLog = { IsQuestFlaggedCompleted = function(id) return id == 7632 end, IsOnQuest = function(id) return id == 7636 end }',
            'local F = STUB_NS; local g = F.GoalById("lokdelar"); '
            'SlashCmdList.FOREVERGOALTRACKER("testlocks on"); '
            'assert(F.DependencyMet(g,2), "modern completed quest satisfies leaf prerequisite"); '
            'assert(F.DependencyMet(g,3), "modern active quest satisfies chain start"); '
            'for i=4,7 do assert(not F.StepLocked(g,i), "modern quest evidence opens demon branches") end; '
            'SlashCmdList.FOREVERGOALTRACKER("testlocks off"); '
            'print("  C_QuestLog completed/active evidence satisfies prerequisites through normal roster scanning")', True),
        ("Forever dependency gates withheld", None,
            'local F = STUB_NS; assert(F.isForever); '
            'for id, gates in pairs(F.DEPENDENCIES) do if type(gates) == "table" then '
            'for key in pairs(gates) do assert(not F.StepLocked(F.GoalById(id), key), "unverified Forever gate withheld") end end end; '
            'print("  Classic-only gates stay off in unverified Forever builds")', True),
    ])
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
