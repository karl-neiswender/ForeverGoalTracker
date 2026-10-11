local F, D = STUB_NS, ForeverGoalTrackerDB
assert(D.guideFix20261011Final)
local expected = {
    benediction={[2]=true,[6]=true}, lokdelar={[2]=true,[8]=true},
    rhokdelar={[2]=true,[6]=true}, att_mc={[2]=true,[4]=true}, att_bwl={[2]=true,[4]=true},
    mount_tiger={[1]=true}, mount_raptor={[1]=true}, mount_deathcharger={[1]=true,[2]=true},
    sulfuras={[10]=true,[11]=true,[12]=true},
    mount_dreadsteed={[2]=true,[4]=true,[8]=true,[13]=true},
    frostsaber={[1]=true,[2]=true,[7]=true},
    mount_charger={[2]=true,[12]=true},
    att_naxx={[2]=true,[3]=true},
    wolfsbane={[3]=true,[10]=true,[18]=true},
}
for id, ticks in pairs(expected) do
    for key in pairs(ticks) do assert(D.progress[id][key], id.." lost tick "..key) end
    for key in pairs(D.progress[id]) do assert(ticks[key], id.." gained tick "..key) end
end
assert(F.GoalById("mount_dreadsteed").steps[1].auto.level == 60)
for _, step in ipairs(F.GoalById("mount_dreadsteed").steps) do assert(step.auto.quest ~= 7603) end
assert(F.GoalById("wolfsbane").steps[1].auto.level == 18)
for _, goal in ipairs(F.goals) do
    for _, step in ipairs(goal.steps or {}) do
        local text = type(step)=="table" and step.text or step
        assert(not text:find("weekly reset schedule",1,true))
    end
end
print("  removed tips, explicit levels and sparse saved tick remaps ok")
