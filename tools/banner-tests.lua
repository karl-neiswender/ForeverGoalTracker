local F, D = STUB_NS, ForeverGoalTrackerDB
local B = F.goalBanner
F.detailBody.GetWidth = function() return B.panel:GetWidth() - 14 end
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
assert(descriptionAnchor == F.detailBody, "empty note leaves no extra gap")
local coords
local artWidth, artHeight
B.art.SetSize = function(_,w,h) artWidth,artHeight=w,h end
local bottomShown = false
B.bottom.Show = function() bottomShown=true end
B.bottom.Hide = function() bottomShown=false end
B.bottom.SetShown = function(_,v) bottomShown=v end
B.art.SetTexCoord = function(_,...) coords={...} end
B.GetHeight = function() return 200 end
B.panel.GetHeight = function() return 600 end
B.panel.GetWidth = function() return 600 end
B:Fit()
assert(math.abs(artWidth-592*0.6*0.92) < 0.001 and B.fullImageHeight == 184,
    "artwork retains its approved eight percent reduction from the top-right anchor")
assert(math.abs(artHeight-(184-math.min(140,184*0.35))) < 0.001,
    "original bottom transparency is preserved without an extra height change")
assert(not bottomShown, "bottom veil stays removed during resize")
B.panel.GetWidth = function() return 1000 end
B:Fit()
assert(B.uv[1]==0 and B.uv[2]==1 and B.uv[3]>0, "wide cover crops vertically")
B.panel.GetWidth = function() return 190 end
B:Fit()
assert(B.uv[1]>0 and B.uv[3]==0 and B.uv[4]==1, "tall cover crops horizontally")
B.panel.GetHeight = function() return 100 end
B:Fit()
assert(B.fullImageHeight == 92 and B.uv[4] < 1, "short panel crops artwork at its bottom without shrinking the subject")
assert(B.fadeStrips[1].fadeWeight > 0.99 and B.fadeStrips[64].fadeWeight < 0.001,
    "artwork itself fades smoothly to transparent at its bottom")
B.panel.GetHeight = function() return 600 end
-- A saved-goal startup may have no empty-state transition to show the driver.
local driverShown = false
local originalShow, originalIsShown = B.Show, B.IsShown
B.Show = function() driverShown=true end
B.IsShown = function() return driverShown end
local stripVisible = {}
for i,t in ipairs(B.fadeStrips) do
    t.SetShown = function(_,v) stripVisible[i]=v end
end
F.LayoutGoalBanner(g)
assert(driverShown, "saved-goal layout explicitly shows the animation driver")
for i=1,#B.fadeStrips do assert(stripVisible[i], "bottom fade strip stays visible: "..i) end
B.Show, B.IsShown = originalShow, originalIsShown
for id in pairs(B.artPaths) do
    assert(F.GoalById(id), "artwork maps to an existing goal: " .. id)
    D.active[id] = true
    F.SelectGoal(id)
    assert(B.hasArt and B.sourceAspect == B.artAspects[id], id .. " uses supplied art with original proportions")
    assert(desaturated == (not B.preprocessed[id]), id .. " selects the correct desaturation state on reused art")
    if B.preprocessed[id] then assert(B.sourceAspect == 4/3, "taller final masters retain 4:3 proportions") end
end
for _, id in ipairs({"raid_mc", "att_mc", "set_tier1"}) do
    F.SelectGoal(id)
    assert(B.preprocessed[id] and not desaturated and B.sourceAspect == 4/3,
        id .. " uses the approved monochrome Molten Core master")
end
D.active.raid_bwl = true
F.SelectGoal("raid_bwl")
assert(not desaturated, "final Blackwing Lair artwork bypasses desaturation")
D.active.raid_ony = true
F.SelectGoal("raid_ony")
assert(B.preprocessed.raid_ony and not desaturated and B.sourceAspect == 4/3, "approved Onyxia master bypasses desaturation at 4:3")
D.active.mount_dreadsteed = true
F.SelectGoal("mount_dreadsteed")
assert(desaturated, "switching to older color artwork restores its existing monochrome look")
F.SelectGoal("raid_bwl")
assert(not desaturated, "switching back clears desaturation")
D.active.gold_5k = true
F.SelectGoal("gold_5k")
assert(not B.hasArt, "unmapped goal clears previous artwork")
-- Only the background artwork fades; the square goal icon remains immediate.
B:StopImageFade()
B.imageSeen = {}
local visible = false
local iconAlphaWrites = 0
local originalIconAlpha = B.icon.SetAlpha
B.icon.SetAlpha = function() iconAlphaWrites=iconAlphaWrites+1 end
B.IsVisible = function() return visible end
F.SetSetting("celebrations", "full")
B.goal = F.GoalById("raid_mc")
B:RevealImages()
assert(not B.imageSeen.raid_mc and not B.revealGoal, "hidden layouts do not consume first-open reveal")
visible = true
B:RevealImages()
assert(B.imageFade == 0 and B:GetScript("OnUpdate"), "first visible open starts at zero")
assert(B.art.fgtGa2 == 0, "artwork gradient starts fully transparent")
local tick = B:GetScript("OnUpdate")
tick(B, 0.2)
local mid = B.imageFade
assert(mid > 0 and mid < 1, "fade eases through intermediate opacity")
assert(math.abs(B.art.fgtGa2-0.18*mid) < 0.0001, "artwork gradient follows the fade")
B:RevealImages()
assert(B.imageFade == mid and B:GetScript("OnUpdate") == tick, "layout refresh does not restart fade")
F.LayoutGoalBanner(B.goal)
assert(B.imageFade == mid and math.abs(B.art.fgtGa2-0.18*mid)<0.0001,
    "texture refresh preserves the running gradient fade")
tick(B, 0.9)
assert(B.imageFade == 1 and B.imageSeen.raid_mc and not B:GetScript("OnUpdate"), "fade completes and stops its ticker")
B:StopImageFade(); B:RevealImages()
assert(B.imageFade == 1 and not B:GetScript("OnUpdate"), "repeat visits are immediate")
B.goal = F.GoalById("att_mc")
B:RevealImages()
assert(B.imageFade == 0, "another goal gets its own first reveal")
B:GetScript("OnUpdate")(B, 0.1)
B:GetScript("OnHide")(B)
assert(B.imageFade == 1 and not B:GetScript("OnUpdate") and not B.imageSeen.att_mc,
    "hide cancels fade without leaving dimmed artwork or consuming unseen goal")
F.SetSetting("celebrations", "subtle")
B:RevealImages()
assert(B:GetScript("OnUpdate"), "subtle motion still fades")
F.SetSetting("celebrations", "off")
B:GetScript("OnUpdate")(B, 0.01)
assert(B.imageFade == 1 and not B:GetScript("OnUpdate"), "motion off completes a running fade immediately")
B.goal = F.GoalById("gold_5k")
B:RevealImages()
assert(B.imageFade == 1 and B.imageSeen.gold_5k and not B:GetScript("OnUpdate"), "motion off skips new fades too")
F.SetSetting("celebrations", "full")
assert(iconAlphaWrites == 0, "background reveal never changes the square goal icon opacity")
B.icon.SetAlpha = originalIconAlpha
-- Per-goal tuning must scale all gradient strips and survive goal switches.
F.SelectGoal("raid_mc")
B:StopImageFade()
SlashCmdList.FOREVERGOALTRACKER("banneropacity 60")
assert(D.bannerOpacity.raid_mc == 0.6 and math.abs(B.art.fgtGa2-0.108)<0.0001,
    "saved opacity scales the existing banner strength")
for _, strip in ipairs(B.fadeStrips) do
    assert(math.abs(strip.fgtGa2-0.108*strip.fadeWeight)<0.0001,
        "opacity preserves the smooth bottom fade")
end
B:SetImageFade(0.5)
assert(math.abs(B.art.fgtGa2-0.054)<0.0001, "opacity multiplies rather than replacing reveal fade")
F.SelectGoal("raid_bwl"); B:StopImageFade()
assert(B:GetArtOpacity()==1 and math.abs(B.art.fgtGa2-0.18)<0.0001,
    "tuning one banner leaves other banners at their default")
F.SelectGoal("raid_mc"); B:StopImageFade()
assert(B:GetArtOpacity()==0.6, "saved tuning follows the goal on return")
SlashCmdList.FOREVERGOALTRACKER("banneropacity 101")
assert(B:GetArtOpacity()==0.6, "invalid tuning is rejected")
SlashCmdList.FOREVERGOALTRACKER("banneropacity reset")
assert(D.bannerOpacity.raid_mc==nil and math.abs(B.art.fgtGa2-0.18)<0.0001,
    "reset restores the approved banner default")
local hidden=0
for _,t in ipairs({B.background,B.border,B.art,B.left,B.top,B.bottom}) do t.Hide=function() hidden=hidden+1 end end
B:GetScript("OnHide")(B)
assert(hidden==6, "empty-state hide clears all background layers")
print("  banner title reflow, badge wrapping, artwork switching, aspect crop and empty-state layers ok")
