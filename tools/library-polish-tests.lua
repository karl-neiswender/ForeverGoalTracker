local F, D = STUB_NS, ForeverGoalTrackerDB
local LF = F.libState
F.SetSetting("celebrations", "off")
F.SetSetting("hideCompletedSteps", false)
local function watch(frame)
    frame.Show = function(self) self.testShown = true end
    frame.Hide = function(self) self.testShown = false end
    frame.SetShown = function(self, on) self.testShown = not not on end
    frame.IsShown = function(self) return self.testShown == true end
end
local g = F.GoalById("att_mc")
D.active[g.id], D.progress[g.id] = true, {}
F.myGoalsView:SetValue("all")
F.SetSetting("hideCompletedGoals", false)
F.SelectGoal(g.id)
for i in ipairs(g.steps) do D.progress[g.id][i] = true end
local snapshot = STUB_SERIALIZE(D.progress[g.id])
F.completedGoalsBtn:GetScript("OnClick")()
assert(not F.MyGoalsShows(g), "completed tracked goal is hidden")
assert(D.active[g.id] and D.settings.hideCompletedGoals, "filter is saved without removing the goal")
F.Rail:UpdateFilter()
assert(F.Rail.filter.lit, "completed-goal filtering lights the folded list filter")
assert(F.completedGoalsBtn.text:GetText() == "Show completed goals", "clear recovery action")
F.completedGoalsBtn:GetScript("OnClick")()
assert(F.MyGoalsShows(g), "completed tracked goal returns")
assert(STUB_SERIALIZE(D.progress[g.id]) == snapshot, "filter never edits progress")
D.progress[g.id] = {}
F.SetSetting("hideCompletedGoals", true)
assert(F.MyGoalsShows(g), "unfinished goal remains visible")
F.SelectGoal(g.id)
local row = F.RailUI.rows[g.id]
watch(row)
for i in ipairs(g.steps) do D.progress[g.id][i] = true end
F.SelectGoal(g.id)
assert(not row.testShown, "completion refresh hides the goal immediately")
D.progress[g.id] = {}
F.SelectGoal(g.id)
assert(row.testShown, "reset or undo returns unfinished goals")
F.SetSetting("hideCompletedGoals", false)

local set, recipe = F.GoalById("set_tier1_rogue"), F.GoalById("tier3_rogue")
D.active[set.id], D.active[recipe.id] = true, true
D.progress[set.id], D.progress[recipe.id] = {}, {}
F.SelectGoal(recipe.id)
for _, h in ipairs(F.headerRows) do watch(h) end
for _, r in ipairs(F.stepRows) do watch(r) end
F.sectionOpen[set.id .. "_1"] = false
F.SelectGoal(set.id)
assert(F.SimpleItemCollection(set) and not F.SimpleItemCollection(recipe))
assert(not F.headerRows[1].testShown, "simple set omits the redundant header")
assert(F.stepRows[1].testShown, "old collapsed state cannot hide the simple item list")
assert(F.PopoutUI.header:GetText() == "Items to collect", "collection heading fits the content")
F.stepRows[1]:GetScript("OnClick")(F.stepRows[1], "LeftButton")
assert(D.progress[set.id]["1_1_piece"], "flat display keeps the original progress address")
F.SelectGoal(recipe.id)
assert(F.headerRows[1].testShown, "recipes keep their collapsible section")
F.SelectGoal(g.id)
assert(F.PopoutUI.header:GetText() == "Steps", "ordinary guides restore their heading")

F.ShowTab("library"); LF.Reset()
F.SetLibraryView("all", "set_tier1")
F.LayoutLibrary()
local card = F.libCards.set_tier1
local child = card.subs[set.armorSection]
watch(child.doneGlow)
for pi in ipairs(set.sections[1].pieces) do D.progress[set.id]["1_" .. pi .. "_piece"] = true end
F.LayoutLibrary()
assert(not child.doneGlow.testShown, "finished collection parts have no green wash")
LF.SetFor("ROGUE"); F.LayoutLibrary()
card = F.libCards[set.id]
watch(card.doneGlow)
F.LayoutLibrary()
assert(not card.doneGlow.testShown and card.restStyle == F.MaterialsUI.styles.doneCard, "completed card uses its darker surface")
assert(card.btnText:GetText() == "Complete" and card.meta:GetText():find("Complete"), "completion remains explicit")
card.btn:GetScript("OnClick")(card.btn)
assert(not D.active[set.id] and D.progress[set.id]["1_1_piece"], "quiet completed card still removes without losing progress")

LF.Reset()
if F.isForever then
    LF.newOnly = true
    LF.faction = "Both"
    local ids, count = {}, 0
    for _, result in ipairs(LF.Results({key="all"})) do
        assert(not ids[result.id], "no duplicate results")
        ids[result.id], count = result, count + 1
        assert(F.ForeverWord(result), "every result has its own blue Forever status")
        assert(not result.group, "no collection wrappers in New & Updated")
    end
    assert(count > 0 and ids["epicmounts#9"] and not ids.epicmounts, "Skyborne shown directly")
    assert(ids["epicmounts#9"].faction == "Alliance", "Skyborne retains its faction in direct results")
    assert(ids.set_viper and not ids.set_tier1_rogue, "UPDATED included; ordinary sets excluded")
    local pvp = 0
    for id in pairs(ids) do if id:match("^pvp_set_") then pvp = pvp + 1 end end
    assert(pvp > 0, "Forever PvP class sets appear directly")
    D.activeParts.epicmounts = {}
    F.LayoutLibrary()
    local mount = F.libCards["epicmounts#9"]
    mount.btn:GetScript("OnClick")(mount.btn)
    assert(D.activeParts.epicmounts[9] and not D.activeParts.epicmounts[1], "Add selects only the visible Forever mount")
    LF.show = "added"
    local found
    for _, result in ipairs(LF.Results({key="all"})) do if result.id == "epicmounts#9" then found = true end end
    assert(found, "Added filter follows the original part selection")
    LF.show = "all"; LF.faction = "Horde"
    for _, result in ipairs(LF.Results({key="all"})) do assert(result.faction ~= "Alliance", "faction filter remains effective") end
    LF.faction = "Both"; LF.SetFor("ROGUE"); LF.newOnly = true
    for _, result in ipairs(LF.Results({key="all"})) do
        assert(not result.armorClass or result.armorClass:upper() == "ROGUE", "class filters apply to extracted sets")
    end
    -- Completed Forever cards stay blue but lose their large completion wash.
    LF.Reset(); LF.newOnly = true
    local updated = F.GoalById("set_viper")
    D.active[updated.id], D.progress[updated.id] = true, {}
    for i in ipairs(updated.steps) do D.progress[updated.id][i] = true end
    F.LayoutLibrary()
    card = F.libCards[updated.id]
    assert(card.foreverNew and card.meta:GetText():find("UPDATED",1,true), "completed UPDATED card keeps its Forever identity")
else
    LF.newOnly = true
    assert(#LF.Results({key="all"}) == 0, "Era does not surface Forever-only parts")
end
LF.Reset()
print("  Library polish: completed-goal filter, stable item keys, recipe sections, quiet completion and direct Forever results pass")
