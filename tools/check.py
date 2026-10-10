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

FILES = ["Data.lua", "Library.lua", "AQArmor.lua", "ArmorSets.lua", "Npcs.lua", "Quests.lua", "Dependencies.lua", "Core.lua"] # load order, as in the .toc
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
    armor_fixture = 'local F = STUB_NS; local r = F.GoalById("set_tier1_rogue").armorSection; local h = F.GoalById("set_tier1_hunter").armorSection; local t = F.GoalById("tier3_rogue").armorSection;\nForeverGoalTrackerDB = { active = {}, activeParts = { set_tier1 = {[r]=true,[h]=true}, tier3 = {[t]=true} }, progress = {set_tier1 = {[r.."_1_piece"]=true,[h.."_2_piece"]=true}, tier3 = {[t.."_1_m1"]=true}}, selected="set_tier1", notes={set_tier1="Keep this note"}, favorites={set_tier1=true}, goalsDone={set_tier1=true}, goalDates={set_tier1=123456}, t3RecipeFix=true, characters={} }; for pi in ipairs(F.GoalById("set_tier1_rogue").sections[1].pieces) do ForeverGoalTrackerDB.progress.set_tier1[r.."_"..pi.."_piece"] = true end'
    steps.extend([
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
        ("goal banner layout", None, open(os.path.join(here, "banner-tests.lua"), encoding="utf-8").read()),
        ("Forever 70291 banner layout and image fades", None,
            open(os.path.join(here, "banner-tests.lua"), encoding="utf-8").read(), True),
        ("short goal window", None, open(os.path.join(here, "short-window-tests.lua"), encoding="utf-8").read()),
        ("Forever short goal window", None, open(os.path.join(here, "short-window-tests.lua"), encoding="utf-8").read(), True),
        ("step dependencies", None, open(os.path.join(here, "dependency-tests.lua"), encoding="utf-8").read()),
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
