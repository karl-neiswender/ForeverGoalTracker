local F, D = STUB_NS, ForeverGoalTrackerDB
local B = F.goalBanner
local desaturated
B.art.SetDesaturated = function(_, value) desaturated=value end
local g = F.GoalById("ashbringer")
D.active[g.id] = true
F.SelectGoal(g.id)
assert(B.hasArt, "Ashbringer uses the correctly assigned supplied art")
F.SetGoalNote(g, "")
local px, py
B.description.SetPoint = function(_,point,relative,relativePoint,x,y)
    if point == "TOPLEFT" then px,py=x,y end
end
B.difficulty.IsShown = function() return true end
B.duration.IsShown = function() return true end
B.difficulty.GetWidth = function() return 85 end
B.duration.GetWidth = function() return 75 end
B.panel.GetWidth = function() return 600 end
B.tag.GetStringHeight = function() return 12 end
B.title.GetStringHeight = function() return 40 end
F.LayoutGoalBanner(g)
local normal = py
B.title.GetStringHeight = function() return 96 end
F.LayoutGoalBanner(g)
assert(py < normal, "long wrapped title pushes chips and description down")
B.title.GetStringHeight = function() return 40 end
B.panel.GetWidth = function() return 190 end
F.LayoutGoalBanner(g)
assert(py < normal and px == 22, "narrow badge row wraps above the description")
local descriptionAnchor
B.description.SetPoint = function(_,point,relative)
    if point == "TOPLEFT" then descriptionAnchor = relative end
end
F.SetGoalNote(g,"Bring resistance gear.")
F.LayoutForeverInfo(g)
assert(descriptionAnchor == F.personalNote, "description follows the personal note")
F.SetGoalNote(g,"")
F.LayoutForeverInfo(g)
assert(descriptionAnchor == B.panel, "empty note leaves no extra gap")
local coords
B.art.SetTexCoord = function(_,...) coords={...} end
B.GetHeight = function() return 200 end
B.panel.GetWidth = function() return 600 end
B:Fit()
assert(coords[1]==0 and coords[2]==1 and coords[3]>0, "wide cover crops vertically")
B.panel.GetWidth = function() return 190 end
B:Fit()
assert(coords[1]>0 and coords[3]==0 and coords[4]==1, "tall cover crops horizontally")
for id in pairs(B.artPaths) do
    assert(F.GoalById(id), "artwork maps to an existing goal: " .. id)
    D.active[id] = true
    F.SelectGoal(id)
    assert(B.hasArt and B.sourceAspect == B.artAspects[id], id .. " uses supplied art with original proportions")
    assert(desaturated == (not B.preprocessed[id]), id .. " selects the correct desaturation state on reused art")
    if B.preprocessed[id] then assert(B.sourceAspect == 1.5, "final masters retain 3:2 proportions") end
end
D.active.raid_bwl = true
F.SelectGoal("raid_bwl")
assert(not desaturated, "final Blackwing Lair artwork bypasses desaturation")
D.active.raid_ony = true
F.SelectGoal("raid_ony")
assert(desaturated, "switching to older color artwork restores its existing monochrome look")
F.SelectGoal("raid_bwl")
assert(not desaturated, "switching back clears desaturation")
D.active.gold_5k = true
F.SelectGoal("gold_5k")
assert(not B.hasArt, "unmapped goal clears previous artwork")
local hidden=0
for _,t in ipairs({B.background,B.border,B.art,B.left,B.top,B.bottom}) do t.Hide=function() hidden=hidden+1 end end
B:GetScript("OnHide")(B)
assert(hidden==6, "empty-state hide clears all background layers")
print("  banner title reflow, badge wrapping, artwork switching, aspect crop and empty-state layers ok")
