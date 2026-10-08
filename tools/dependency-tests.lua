local F, D = STUB_NS, ForeverGoalTrackerDB
assert(not F.isForever, "Classic test session")
D.characters = {}
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
assert(F.stepRows[2].depLocked and F.stepRows[3].depLocked, "dependent rows locked")
local row = F.stepRows[3]
row:GetScript("OnClick")(row,"LeftButton")
assert(not D.progress[g.id][3], "locked click never ticks")
assert(row.lockLayer.motion == "jiggle", "locked click starts jiggle")
row.lockLayer:GetScript("OnUpdate")(row.lockLayer,0.5)
assert(row.lockLayer.motion == nil, "jiggle settles")
-- Hyperlinks keep their existing click behavior even on a locked row.
F.overLink = true; row:GetScript("OnClick")(row,"LeftButton"); F.overLink = nil
assert(row.lockLayer.motion == nil and not D.progress[g.id][3], "link click bypasses locked action")

F.stepRows[1]:GetScript("OnClick")(F.stepRows[1],"LeftButton")
assert(not F.stepRows[2].depLocked and F.stepRows[2].lockLayer.motion == "unlock")
F.stepRows[2]:GetScript("OnClick")(F.stepRows[2],"LeftButton")
for i = 3,6 do
    assert(not F.stepRows[i].depLocked, "fan-out unlocks all demon steps")
    assert(F.stepRows[i].lockLayer.motion == "unlock", "each demon has its own breakaway")
    local alpha
    F.stepRows[i].box.SetAlpha = function(_, a) alpha=a end
    F.stepRows[i].lockLayer:GetScript("OnUpdate")(F.stepRows[i].lockLayer,0.5)
    assert(F.stepRows[i].lockLayer.motion == nil and alpha == 1, "unlock leaves visible checkbox")
end
assert(F.StepLocked(g,7), "all four heads required")
for i = 3,6 do F.stepRows[i]:GetScript("OnClick")(F.stepRows[i],"LeftButton") end
assert(not F.StepLocked(g,7), "fan-in opens reward")
D.progress[g.id][2]=nil
assert(not F.StepLocked(g,3) and D.progress[g.id][3], "completed child stays completed")

local t = F.GoalById("thunderfury")
D.progress[t.id]={}
assert(F.StepLocked(t,4), "either-binding gate starts locked")
assert(not F.StepLocked(t,2) and not F.StepLocked(t,3) and not F.StepLocked(t,5), "loot and gathering parallel")
D.progress[t.id][3]=true; assert(not F.StepLocked(t,4), "right binding alone works")
D.progress[t.id]={[2]=true}; assert(not F.StepLocked(t,4), "left binding alone works")
local b=F.GoalById("benediction")
D.progress[b.id]={}
assert(not F.StepLocked(b,4), "Eye of Shadow can be gathered early")
D.characters.Test={items={[18608]=1}}
assert(not F.StepLocked(b,5), "owned reward overrides missing manual prerequisites")
D.characters={}

-- Modes and pool reuse must always restore checkbox alpha and end effects.
local r=F.stepRows[3]
r.depLocked=true; F.SetSetting("celebrations","subtle"); F.PlayLockMotion(r,"jiggle")
r.lockLayer:GetScript("OnUpdate")(r.lockLayer,0.5)
r.depLocked=false; F.PlayLockMotion(r,"unlock")
r.lockLayer:GetScript("OnUpdate")(r.lockLayer,0.5)
assert(not r.lockLayer.motion, "subtle fade finishes")
F.SetSetting("celebrations","off"); F.PlayLockMotion(r,"unlock")
assert(not r.lockLayer:GetScript("OnUpdate"), "motion off is instant")
F.SetSetting("celebrations","full"); F.PlayLockMotion(r,"unlock")
F.SelectGoal("atiesh")
assert(not r.depLocked and not r.lockLayer.motion, "pooled row reuse cancels old lock motion")
print("  dependency references, cycles, blocked clicks, links, fan-out, fan-in, OR, evidence and motion modes ok")
