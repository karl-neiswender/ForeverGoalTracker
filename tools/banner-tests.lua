local F, D = STUB_NS, ForeverGoalTrackerDB
local B = F.goalBanner
local g = F.GoalById("thunderfury")
D.active[g.id] = true
F.SelectGoal(g.id)
assert(B.hasArt, "Thunderfury uses supplied art")
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
local coords
B.art.SetTexCoord = function(_,...) coords={...} end
B.GetHeight = function() return 200 end
B.panel.GetWidth = function() return 600 end
B:Fit()
assert(coords[1]==0 and coords[2]==1 and coords[3]>0, "wide cover crops vertically")
B.panel.GetWidth = function() return 190 end
B:Fit()
assert(coords[1]>0 and coords[3]==0 and coords[4]==1, "tall cover crops horizontally")
F.SelectGoal("atiesh")
assert(not B.hasArt, "unmapped goal clears previous artwork")
local hidden=0
for _,t in ipairs({B.background,B.art,B.left,B.top,B.bottom}) do t.Hide=function() hidden=hidden+1 end end
B:GetScript("OnHide")(B)
assert(hidden==5, "empty-state hide clears all background layers")
print("  banner title reflow, badge wrapping, artwork switching, aspect crop and empty-state layers ok")
