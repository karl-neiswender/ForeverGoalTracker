local F, D = STUB_NS, ForeverGoalTrackerDB
local goal = F.GoalById("lokdelar")
local oldProgress, oldCharacters, oldPreview = D.progress[goal.id], D.characters, F.testDependencies
D.progress[goal.id], D.characters = {}, {}
F.testDependencies = nil
assert(next(F.FOREVER_DEPENDENCIES) == nil, "no Forever gameplay edges enabled without evidence")
-- Test a single reviewed edge; these fixtures never ship as enabled rules.
F.FOREVER_DEPENDENCIES.lokdelar = {[3]={all={2}}}
if F.isForever then
    assert(F.StepLocked(goal,3), "individual approved edge active")
    assert(not F.StepLocked(goal,4), "unreviewed sibling edges stay available")
    assert(not F.StepLocked(F.GoalById("thunderfury"),4), "unreviewed chains stay available")
    D.progress[goal.id][2]=true
    assert(not F.StepLocked(goal,3), "reviewed edge opens on existing progress")
    D.progress[goal.id][2]=nil
    F.testDependencies=true
    assert(F.StepLocked(goal,4), "preview still exercises Classic baseline")
    F.testDependencies=nil
    assert(not F.StepLocked(goal,4), "leaving preview returns to reviewed subset")
else
    assert(F.StepPrerequisites(goal,3) == F.DEPENDENCIES.lokdelar[3], "Era keeps its existing graph")
end
F.FOREVER_DEPENDENCIES.lokdelar=nil
D.progress[goal.id], D.characters, F.testDependencies = oldProgress, oldCharacters, oldPreview

-- Scope filters apply to automatic prerequisite evidence. Saved checklist
-- ticks remain account/roster progress, not current-character eligibility.
local fixture = {id="dependency_scope_fixture", steps={
    {text="Accept quest",auto={questTaken=123,forRace="NightElf",forFaction="Alliance",forClass="HUNTER"}},
    {text="Follow-up"},
}}
oldCharacters,oldPreview = D.characters,F.testDependencies
D.characters={wrong={race="Human",faction="Horde",class="WARRIOR",questsTaken={[123]=true}}}
F.DEPENDENCIES[fixture.id]={[2]={all={1}}}
F.testDependencies=true
assert(F.StepLocked(fixture,2), "unmatched characters cannot satisfy scoped evidence")
D.characters.correct={race="NightElf",faction="Alliance",class="HUNTER",questsTaken={[123]=true}}
assert(not F.StepLocked(fixture,2), "matching character supplies prerequisite")
D.characters.correct.questsTaken={}
D.characters.correct.quests={[123]=true}
assert(not F.StepLocked(fixture,2), "turned-in quest also satisfies acceptance")
D.characters.correct=nil
D.progress[fixture.id]={[1]=true}
assert(not F.StepLocked(fixture,2), "saved manual prerequisite remains valid")
D.progress[fixture.id]={[2]=true}
assert(not F.StepLocked(fixture,2), "completed child never relocked")
D.progress[fixture.id],F.DEPENDENCIES[fixture.id]=nil,nil
D.characters,F.testDependencies=oldCharacters,oldPreview
print("  isolated Forever rollout, preview separation, scoped automatic evidence and historical ticks ok")
