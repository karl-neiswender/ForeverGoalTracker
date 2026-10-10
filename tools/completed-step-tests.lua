local F, D = STUB_NS, ForeverGoalTrackerDB
D.characters = {}
F.SetSetting("hideCompletedSteps", false)
F.SetSetting("celebrations", "off")
local flat, set = F.GoalById("ashbringer"), F.GoalById("tier3_rogue")
D.active[flat.id], D.active[set.id] = true, true
D.progress[flat.id], D.progress[set.id] = {[1]=true}, {["1_1_m1"]=true}
F.sectionOpen[set.id .. "_1"] = true
F.pieceExpanded[set.id .. "_1_1"] = true
F.SelectGoal(set.id) -- allocate enough rows for the expanded recipe
local function watch(frame)
    frame.Show = function(self) self.visible = true end
    frame.Hide = function(self) self.visible = false end
    frame.SetShown = function(self, on) self.visible = on end
    frame.IsShown = function(self) return self.visible == true end
end
for _, row in ipairs(F.stepRows) do watch(row) end
for _, row in ipairs(F.headerRows) do watch(row) end
watch(F.completedStepsBtn)
watch(F.expandAllBtn)
local function count()
    local n = 0
    for _, row in ipairs(F.stepRows) do if row.visible then n = n + 1 end end
    return n
end
local function click()
    F.completedStepsBtn:GetScript("OnClick")()
end
F.SelectGoal(flat.id)
assert(F.completedStepsBtn.text:GetText() == "Hide completed", "shown by default")
assert(F.stepRows[1].visible and F.stepRows[2].visible)
local ticks = STUB_SERIALIZE(D.progress[flat.id])
click()
assert(not F.stepRows[1].visible and F.stepRows[2].visible, "only completed steps disappear")
assert(F.stepRows[2].num:GetText() == "2.", "original numbering remains")
assert(F.completedStepsBtn.text:GetText() == "Show completed")
assert(STUB_SERIALIZE(D.progress[flat.id]) == ticks, "filter preserves ticks")
click()
assert(F.stepRows[1].visible, "completed rows return")

F.SelectGoal(set.id)
local all = count()
ticks = STUB_SERIALIZE(D.progress[set.id])
click()
assert(count() == all - 1, "completed recipe material disappears")
assert(STUB_SERIALIZE(D.progress[set.id]) == ticks)
click()
assert(count() == all, "material and recipe rows return")
for mi in ipairs(set.sections[1].pieces[1].materials) do D.progress[set.id]["1_1_m" .. mi] = true end
F.SelectGoal(set.id)
all = count()
click()
assert(count() == all - 1 - #set.sections[1].pieces[1].materials, "finished piece and its materials disappear")
for pi, piece in ipairs(set.sections[1].pieces) do
    if #piece.materials > 0 then
        for mi in ipairs(piece.materials) do D.progress[set.id]["1_" .. pi .. "_m" .. mi] = true end
    else D.progress[set.id]["1_" .. pi .. "_piece"] = true end
end
F.SelectGoal(set.id)
assert(not F.headerRows[1].visible and count() == 0, "finished section disappears")
assert(F.completedStepsBtn.visible, "show completed remains available on a finished goal")
click()
assert(F.headerRows[1].visible, "finished section returns")
click()
F.SelectGoal(flat.id)
assert(not F.stepRows[1].visible, "choice carries across goals")
D.active, D.activeParts = {}, {}
F.SelectGoal(flat.id)
assert(not F.completedStepsBtn.visible, "empty tracker hides the control")
print("  shown default, original numbering, unchanged ticks, recipe materials, completed pieces/groups and empty state ok")
