local F, D = STUB_NS, ForeverGoalTrackerDB
D.active, D.activeParts, D.characters = {}, {}, {}
local g, other = F.GoalById("ashbringer"), F.GoalById("atiesh")
D.active[g.id], D.active[other.id] = true, true
D.progress[g.id], D.progress[other.id] = {}, {}
F.SetSetting("hideCompletedSteps", true)
F.SetSetting("celebrations", "full")
-- Control time explicitly so we can inspect the pause, fade and slide.
local W, scheduled = F.welcome, {}
local tween = W.Tween
W.Tween = function(key, duration, update, finish, delay)
    scheduled[key] = duration and {update=update, finish=finish, delay=delay} or nil
    if duration then update(0) end
end
F.SelectGoal(g.id)
local first = F.stepRows[1]
local alpha
first.SetAlpha = function(_, value) alpha = value end
local originalY = F.guideLayout.byKey["step:3"].y
first:GetScript("OnClick")(first, "LeftButton")
assert(D.progress[g.id][1] and F.guideLayout.byKey["step:1"], "new completion stays in the guide")
assert(first.fxT == 0 and alpha == 1, "check pop starts before fade")
assert(scheduled.guideExit.delay >= 0.5, "check has time to settle")
-- A second click while waiting retains both completed entries.
F.stepRows[2]:GetScript("OnClick")(F.stepRows[2], "LeftButton")
assert(F.guideLayout.pending["step:1"] and F.guideLayout.pending["step:2"])
scheduled.guideExit.update(0.5)
assert(alpha > 0 and alpha < 1, "row fades gradually")
scheduled.guideExit.update(1)
local fadingLayout = F.guideLayout
scheduled.guideExit.finish()
assert(F.guideLayout ~= fadingLayout, "fade callback rebuilds the selected guide")
assert(not F.guideLayout.byKey["step:1"] and not F.guideLayout.byKey["step:2"], "faded entries leave the layout")
assert(F.guideLayout.byKey["step:3"].y < originalY, "remaining steps move upward")
assert(scheduled.guideSlide, "surviving rows slide into place")
scheduled.guideSlide.update(0.5)
scheduled.guideSlide.update(1)
scheduled.guideSlide.finish()
assert(alpha == 1, "pooled row alpha restored")
-- Goal switching cancels an unfinished exit instead of altering the new guide.
F.stepRows[3]:GetScript("OnClick")(F.stepRows[3], "LeftButton")
assert(scheduled.guideExit)
F.SelectGoal(other.id)
assert(not scheduled.guideExit and not scheduled.guideSlide, "switch cancels motion")
assert(F.guideLayout.goal == other.id and not next(F.guideLayout.pending))
F.SetSetting("celebrations", "off")
F.SelectGoal(g.id)
F.stepRows[4]:GetScript("OnClick")(F.stepRows[4], "LeftButton")
assert(not F.guideLayout.byKey["step:4"] and not scheduled.guideExit, "motion off hides immediately")
-- Finishing a recipe retains its last material and piece, then safely
-- reuses their pooled frames for the remaining set pieces.
F.SetSetting("celebrations", "full")
local set = F.GoalById("tier3_rogue")
D.active[set.id], D.progress[set.id] = true, {}
local materials = set.sections[1].pieces[1].materials
for mi = 1, #materials - 1 do D.progress[set.id]["1_1_m" .. mi] = true end
F.sectionOpen[set.id .. "_1"], F.pieceExpanded[set.id .. "_1_1"] = true, true
F.SelectGoal(set.id)
local materialKey = "material:1:1:" .. #materials
local material = F.guideLayout.byKey[materialKey].frame
material:GetScript("OnClick")(material, "LeftButton")
assert(F.guideLayout.pending[materialKey] and F.guideLayout.pending["piece:1:1"], "last material and completed recipe stay for their checks")
scheduled.guideExit.update(1)
scheduled.guideExit.finish()
assert(not F.guideLayout.byKey[materialKey] and not F.guideLayout.byKey["piece:1:1"])
assert(F.guideLayout.byKey["piece:1:2"].frame.guideIdentity == set.id .. "|piece:1:2", "pooled row now belongs to the correct piece")
scheduled.guideSlide.update(1)
scheduled.guideSlide.finish()
W.Tween = tween
-- Exercise the real OnUpdate loop: the earlier tests intentionally
-- intercepted Tween and could not catch mutations during pairs().
local driver
for i = 1, 20 do
    local name, value = debug.getupvalue(W.Tween, i)
    if not name then break end
    if name == "driver" then driver = value end
end
assert(driver, "real animation driver found")
local update = driver:GetScript("OnUpdate")
F.SelectGoal(g.id)
D.progress[g.id] = {}
F.SelectGoal(g.id)
F.stepRows[1]:GetScript("OnClick")(F.stepRows[1], "LeftButton")
assert(F.guideLayout.pending["step:1"])
for i = 1, 125 do update(driver, 0.007) end
assert(not F.guideLayout.byKey["step:1"], "real fade callback removes completed row and starts slide")
for i = 1, 40 do update(driver, 0.007) end
assert(F.guideLayout.byKey["step:2"], "remaining rows survive slide")
-- A replacement added in an update callback must not be removed when
-- the old tween finishes; new entries start on the next frame.
local replacementTicks, replacementDone = 0, false
W.Tween("mutationTest", 0.01, function(p)
    if p == 1 then
        W.Tween("mutationTest", 0.02, function(q)
            if q > 0 then replacementTicks = replacementTicks + 1 end
        end, function() replacementDone = true end)
        for i = 1, 64 do W.Tween("mutationAdded" .. i, 0.02, function() end) end
    end
end)
update(driver, 0.01)
assert(replacementTicks == 0 and not replacementDone, "replacement waits until next frame")
update(driver, 0.02)
assert(replacementTicks == 1 and replacementDone, "replacement survives old completion")
print("  check pause, gradual fade, consecutive completions, slide, pooled alpha, switching and motion-off behavior ok")
