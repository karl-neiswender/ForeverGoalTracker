local F, D = STUB_NS, ForeverGoalTrackerDB
local function Find(rows,id)
    for _,row in ipairs(rows) do if row.id==id then return row end end
end
local goal = {id="materials_test", steps={
    {text="Gather 10 Sample Bars.",auto={item=12360,count=10}},
    {text="Gather 20 Sample Bars.",auto={item=12360,count=20}},
    {text="Loot a weapon.",auto={item=999}},
}}
local current = F.MaterialsUI.charKey()
D.characters = {[current]={race="Human",faction="Alliance",items={[12360]=5}}, Alt={race="Orc",faction="Horde",items={[12360]=7}}}
D.progress[goal.id]={}
local progress = STUB_SERIALIZE(D.progress)
local row = Find(F.MaterialRows(goal,true),12360)
assert(row.need==20 and row.have==12 and row.percent==60,"same stock uses largest milestone")
assert(#F.MaterialRows(goal,true)==1,"single loot reward is not a reagent")
assert(Find(F.MaterialRows(goal,false),12360).have==5,"current character filter")
goal.steps[1].auto.forFaction="Alliance"
goal.steps[2].auto.forFaction="Alliance"
assert(Find(F.MaterialRows(goal,true),12360).have==5,"faction scopes respected")
goal.steps[1].auto.forFaction=nil; goal.steps[2].auto.forFaction=nil
assert(STUB_SERIALIZE(D.progress)==progress,"collecting panel data does not tick anything")
D.progress[goal.id][2]=true
D.characters[current].items={}; D.characters.Alt.items={}
assert(Find(F.MaterialRows(goal,true),12360).have==20,"historical completed milestone stays collected")

local recipe = {id="materials_recipe",group=true,sections={
    {pieces={
        {materials={},requiredItems={{item=12360,count=3}}},
        {materials={},requiredItems={{item=12360,count=4}}},
    }},
    {pieces={{materials={},requiredItems={{item=12360,count=100}}}}},
}}
D.activeParts[recipe.id]={[1]=true}; D.progress[recipe.id]={}
D.characters[current].items={[12360]=2}
row=Find(F.MaterialRows(recipe,true),12360)
assert(row.need==7 and row.have==2,"selected recipe pieces add their quantities")
D.progress[recipe.id]["1_1_piece"]=true
row=Find(F.MaterialRows(recipe,true),12360)
assert(row.need==7 and row.have==5,"completed turn-in credited alongside remaining stock")
local manual={id="materials_manual",sections={{pieces={{materials={"3 Arcanite Bars","Unknown reagent from a boss"}}}}}}
D.progress[manual.id]={}
local oldInfo=F.ItemInfo
F.ItemInfo=function(id)
    if id=="Unknown reagent" then return nil end
    return oldInfo(id)
end
local manualRows=F.MaterialRows(manual,true)
row=Find(manualRows,12360)
assert(row and row.need==3,"manual material name resolves from existing item metadata")
local unknown
for _,entry in ipairs(manualRows) do if not entry.id then unknown=entry end end
assert(unknown and unknown.unknown,"unresolved item never presented as a verified zero count")
D.progress[manual.id]["1_1_m1"]=true
assert(Find(F.MaterialRows(manual,true),12360).have==3,"manual collection tick retained")
manual.sections[1].pieces[2]={materials={"4 Arcanite Bars"}}
D.characters[current].items={[12360]=3}
assert(Find(F.MaterialRows(manual,true),12360).have==3,"collected tick does not double-count stock still held")
D.progress[manual.id]["1_1_piece"]=true
assert(Find(F.MaterialRows(manual,true),12360).have==6,"owned piece proves its ingredients were consumed")
F.ItemInfo=oldInfo

local M,U=F.materialsPanel,F.MaterialsUI
assert(not M.open and M.fraction==0,"collapsed on fresh load")
local oldMainWidth,oldListWidth=U.main.GetWidth,U.list.GetWidth
local width=1000
U.main.GetWidth=function() return width end
U.list.GetWidth=function() return 300 end
D.active={sulfuras=true}; D.progress.sulfuras={}; F.SelectGoal("sulfuras")
local oldMotion=F.Setting("celebrations")
F.SetSetting("celebrations","full")
M:Place()
local before=STUB_SERIALIZE(D.progress)
M:SetOpen(true)
local step=M.driver:GetScript("OnUpdate")
assert(step,"animation is active only during the transition")
step(M.driver,0.1)
assert(M.fraction>0 and M.fraction<1,"intermediate glide")
step(M.driver,0.2)
assert(M.fraction==1 and M.span==210 and not M.driver:GetScript("OnUpdate"),"glide finishes and removes update handler")
M:SetOpen(false); M.driver:GetScript("OnUpdate")(M.driver,0.3)
assert(M.fraction==0 and M.span==22,"closed drawer preserves its visible sliver")
F.SetSetting("celebrations","off"); M:SetOpen(true)
assert(M.fraction==1,"motion-off opens immediately")
width=520; M:Place()
assert(not M.canOpen and not M.open and M.span==22,"narrow window preserves guide space")
assert(STUB_SERIALIZE(D.progress)==before,"open/close/resize never changes saved progress")
-- Removing the last goal restores the full empty guide; a grouped goal
-- selected through activeParts still has a drawer.
D.active={}; F.RefreshMaterials(); M:Place()
assert(M.span==0 and not M.open,"empty tracker has no hidden drawer footprint")
local mounts=F.GoalById("epic_racial_mounts")
-- Use a real grouped goal without assuming its historic catalogue ID.
for _,candidate in ipairs(F.goals) do if candidate.group and candidate.steps then mounts=candidate; break end end
if mounts then
    D.activeParts[mounts.id]={[1]=true}; F.SelectGoal(mounts.id)
    assert(U.goal() and U.goal().id==mounts.id,"grouped selection is recognized")
end
F.SetSetting("celebrations",oldMotion)
U.main.GetWidth,U.list.GetWidth=oldMainWidth,oldListWidth
print("  per-goal stock, recipe sums, historical credit, scopes, alts, unknown items, slide lifecycle and narrow bounds pass")
