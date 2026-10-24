local F, D = STUB_NS, ForeverGoalTrackerDB
F.noRequirementLocks = true -- the order locks are tested on their own first; requirement locks follow below
D.characters = {}
if F.isForever then
    local before = STUB_SERIALIZE(D.progress)
    SlashCmdList.FOREVERGOALTRACKER("testlocks on")
    assert(F.testDependencies, "Forever preview enabled")
    assert(STUB_SERIALIZE(D.progress) == before, "enabling preview preserves progress")
end
-- All deployed references must exist, and their graph must be acyclic.
for id, gates in pairs(F.DEPENDENCIES) do
    if type(gates) == "table" then
        local goal = assert(F.GoalById(id), "dependency goal exists")
        local visiting, visited = {}, {}
        local function visit(key)
            assert(F.DependencyEntry(goal,key), "dependency address exists")
            assert(not visiting[key], "dependency cycle")
            if visited[key] then return end
            visiting[key] = true
            local gate = gates[key]
            if gate then for _,group in ipairs({gate.all or {},gate.any or {}}) do
                for _,prior in ipairs(group) do visit(prior) end
            end end
            visiting[key],visited[key] = nil,true
        end
        for key in pairs(gates) do visit(key) end
    end
end

local g = F.GoalById("lokdelar")
D.active[g.id],D.progress[g.id] = true,{}
F.SelectGoal(g.id)
assert(F.stepRows[3].depLocked and F.stepRows[4].depLocked, "dependent rows locked")
local row = F.stepRows[4]
row:GetScript("OnClick")(row,"LeftButton")
assert(not D.progress[g.id][4], "locked click never ticks")
assert(row.lockLayer.motion == "jiggle", "locked click starts jiggle")
row.lockLayer:GetScript("OnUpdate")(row.lockLayer,0.5)
assert(row.lockLayer.motion == nil, "jiggle settles")
-- Hyperlinks keep their existing click behavior even on a locked row.
F.overLink = true; row:GetScript("OnClick")(row,"LeftButton"); F.overLink = nil
assert(row.lockLayer.motion == nil and not D.progress[g.id][4], "link click bypasses locked action")

F.stepRows[2]:GetScript("OnClick")(F.stepRows[2],"LeftButton")
assert(not F.stepRows[3].depLocked and F.stepRows[3].lockLayer.motion == "unlock")
F.stepRows[3]:GetScript("OnClick")(F.stepRows[3],"LeftButton")
for i = 4,7 do
    assert(not F.stepRows[i].depLocked, "fan-out unlocks all demon steps")
    assert(F.stepRows[i].lockLayer.motion == "unlock", "each demon has its own breakaway")
    local alpha
    F.stepRows[i].box.SetAlpha = function(_, a) alpha=a end
    F.stepRows[i].lockLayer:GetScript("OnUpdate")(F.stepRows[i].lockLayer,0.5)
    assert(F.stepRows[i].lockLayer.motion == nil and alpha == 1, "unlock leaves visible checkbox")
end
assert(F.StepLocked(g,8), "all four heads required")
for i = 4,7 do F.stepRows[i]:GetScript("OnClick")(F.stepRows[i],"LeftButton") end
assert(not F.StepLocked(g,8), "fan-in opens reward")
D.progress[g.id][3]=nil
assert(not F.StepLocked(g,4) and D.progress[g.id][4], "completed child stays completed")

local t = F.GoalById("thunderfury")
D.progress[t.id]={}
assert(F.StepLocked(t,4), "either-binding gate starts locked")
assert(not F.StepLocked(t,2) and not F.StepLocked(t,3) and not F.StepLocked(t,5), "loot and gathering parallel")
D.progress[t.id][3]=true; assert(not F.StepLocked(t,4), "right binding alone works")
D.progress[t.id]={[2]=true}; assert(not F.StepLocked(t,4), "left binding alone works")
local b=F.GoalById("benediction")
D.progress[b.id]={}
assert(not F.StepLocked(b,5), "Eye of Shadow can be gathered early")
D.characters.Test={items={[18608]=1}}
assert(not F.StepLocked(b,6), "owned reward overrides missing manual prerequisites")
D.characters={}

-- Modes and pool reuse must always restore checkbox alpha and end effects.
local r=F.stepRows[4]
r.depLocked=true; F.SetSetting("celebrations","subtle"); F.PlayLockMotion(r,"jiggle")
r.lockLayer:GetScript("OnUpdate")(r.lockLayer,0.5)
r.depLocked=false; F.PlayLockMotion(r,"unlock")
r.lockLayer:GetScript("OnUpdate")(r.lockLayer,0.5)
assert(not r.lockLayer.motion, "subtle fade finishes")
F.SetSetting("celebrations","off"); F.PlayLockMotion(r,"unlock")
assert(not r.lockLayer:GetScript("OnUpdate"), "motion off is instant")
F.SetSetting("celebrations","full"); F.PlayLockMotion(r,"unlock")
D.active.atiesh = true
F.SelectGoal("atiesh")
assert(not r.depLocked and not r.lockLayer.motion, "pooled row reuse cancels old lock motion")
print("  dependency references, cycles, blocked clicks, links, fan-out, fan-in, OR, evidence and motion modes ok")

-- ------------------------------------------------------------
-- Requirement locks (Karl, 2026-10-24)
-- ------------------------------------------------------------
F.noRequirementLocks = nil
D.characters, D.unlocked = {}, nil
-- the first step of each lockable kind in the library, and one the addon must never lock
local found, never = {}, nil
for _, goal in ipairs(F.goals) do
    for i, step in ipairs(goal.steps or {}) do
        local rule = type(step) == "table" and step.auto
        if rule then
            local kinds = {}
            for k in pairs(rule) do if k ~= "forFaction" and k ~= "forClass" and k ~= "forRace" then kinds[#kinds + 1] = k end end
            if #kinds == 1 and not found[kinds[1]] and (kinds[1] == "level" or kinds[1] == "rep" or kinds[1] == "skill" or kinds[1] == "quest") then
                found[kinds[1]] = { goal = goal, key = i }
            end
            if not never and (rule.boss or rule.item) and #kinds == 1 then never = { goal = goal, key = i } end
        end
    end
end
for _, kind in ipairs({ "level", "rep", "skill", "quest" }) do assert(found[kind], "the library has a " .. kind .. " step to test") end
local patterns = { level = "^Requires level %d+%.$", rep = "^Requires .+ with .+%.$", skill = "^Requires .+ %d+%.$", quest = "^Quest not completed%.$" }
for kind, at in pairs(found) do
    D.progress[at.goal.id] = {}
    local text = F.StepRequirement(at.goal, at.key)
    assert(text and text:match(patterns[kind]), kind .. " requirement is one short line: " .. tostring(text))
    local locked, missing = F.StepLocked(at.goal, at.key)
    assert(locked and missing.requirement == text, kind .. " step is locked while the character does not meet it")
end
assert(never and not F.StepRequirement(never.goal, never.key), "boss and item rules are never requirement-locked")
-- meeting the requirement (any recorded character) opens the lock; the step then ticks itself
local lv = found.level
local need = F.GoalById(lv.goal.id).steps[lv.key].auto.level
D.characters = { Low = { level = need - 1, name = "Low" } }
assert(F.StepLocked(lv.goal, lv.key), "a recorded character below the level does not open it")
D.characters = { High = { level = need, name = "High" } }
assert(not F.StepLocked(lv.goal, lv.key), "a recorded character at the level opens it")
D.characters = {}
-- an unmet step is not ticked by a click; the first blocked click arms the hint; Shift-click unlocks, never ticks
D.active[lv.goal.id], D.progress[lv.goal.id] = true, {}
F.SelectGoal(lv.goal.id)
local lrow = F.stepRows[lv.key]
assert(lrow.depLocked, "the requirement-locked row shows its lock")
local lines = {}
-- (the stub makes a fresh blank object for every unknown global, so the tooltip here is a small recording one)
GameTooltip = { SetOwner = function() end, Show = function() end, Hide = function() end, IsOwned = function() return false end,
    NumLines = function() return #lines end, AddLine = function(_, text) lines[#lines + 1] = text end }
F.ShowStepLockTip(lrow)
assert(lines[1] and lines[1]:match("^Requires") and #lines == 1, "the tooltip is the requirement alone before any click: " .. tostring(lines[1]))
lrow:GetScript("OnClick")(lrow, "LeftButton")
assert(not D.progress[lv.goal.id][lv.key] and lrow.lockLayer.motion == "jiggle", "a click on an unmet step jiggles and does not tick")
lines = {}
F.ShowStepLockTip(lrow)
assert(lines[#lines] == "Shift-click to unlock", "after one blocked click the tooltip ends with the hint")
GameTooltip = nil
local shiftDown = IsShiftKeyDown; IsShiftKeyDown = function() return true end
lrow:GetScript("OnClick")(lrow, "LeftButton")
IsShiftKeyDown = shiftDown
assert(F.StepUnlocked(lv.goal, lv.key) and not D.progress[lv.goal.id][lv.key], "Shift-click unlocks the step and does not tick it")
assert(not F.StepLocked(lv.goal, lv.key), "an unlocked step is no longer locked")
F.stepRows[lv.key]:GetScript("OnClick")(F.stepRows[lv.key], "LeftButton")
assert(D.progress[lv.goal.id][lv.key], "after the unlock a click ticks it")
-- the unlock lasts the game session: a reload keeps it, the next login clears it
D.progress[lv.goal.id] = {}
STUB_FIRE("PLAYER_ENTERING_WORLD", false, true)
assert(F.StepUnlocked(lv.goal, lv.key), "a reload keeps the unlock")
STUB_FIRE("PLAYER_ENTERING_WORLD", false, false)
assert(F.StepUnlocked(lv.goal, lv.key), "changing zones keeps it")
STUB_FIRE("PLAYER_ENTERING_WORLD", true, false)
assert(not F.StepUnlocked(lv.goal, lv.key) and F.StepLocked(lv.goal, lv.key), "a login clears the unlock and the lock returns")
-- Forever has no requirement locks until its rules are verified
if F.isForever then
    local prior = F.testDependencies
    F.testDependencies = nil
    assert(not F.StepRequirement(lv.goal, lv.key), "no requirement locks on Forever")
    F.testDependencies = prior
end
D.characters, D.unlocked = {}, nil
print("  requirement locks: short lines for level, reputation, skill and quest steps, the hint, Shift-click unlock, session memory and Forever ok")


if F.isForever then
    local before = STUB_SERIALIZE(D.progress)
    SlashCmdList.FOREVERGOALTRACKER("testlocks status")
    assert(F.testDependencies, "status is read-only")
    SlashCmdList.FOREVERGOALTRACKER("testlocks off")
    assert(not F.testDependencies and not F.StepLocked(t,4), "preview off restores ungated Forever")
    assert(STUB_SERIALIZE(D.progress) == before, "disabling preview preserves progress")
    assert(not D.testDependencies, "preview never stored in SavedVariables")
    SlashCmdList.FOREVERGOALTRACKER("testlocks")
    assert(F.testDependencies, "bare command toggles on")
    SlashCmdList.FOREVERGOALTRACKER("testlocks")
    assert(not F.testDependencies, "bare command toggles off")
end
