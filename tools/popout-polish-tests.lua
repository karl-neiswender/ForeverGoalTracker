local F, D = STUB_NS, ForeverGoalTrackerDB
local P, S = F.Popout, F.MaterialsUI
local function Track(frame, shown)
    frame.shownForTest = shown or false
    frame.Show=function(self) self.shownForTest=true end
    frame.Hide=function(self) self.shownForTest=false end
    frame.SetShown=function(self,on) self.shownForTest=on and true or false end
    frame.IsShown=function(self) return self.shownForTest end
end
Track(S.main,true); Track(P.frame); Track(P.options); Track(P.grip); Track(P.clip); Track(P.scroll.scroll); Track(P.doneCheck)
P.frame.IsVisible=function(self) return self.shownForTest end
P.frame.SetSize=function(self,w,h) self.widthForTest,self.heightForTest=w,h end
P.clip.SetAlpha=function(self,a) self.alphaForTest=a end
P.shadow.SetAlpha=function(self,a) self.alphaForTest=a end
F.SetSetting("hideCompletedSteps",false)
D.active.gold_5k=true; D.progress.gold_5k={}; D.characters={}
P.autoFit=false; P.width=360; P.height=300; P.left=100; P.top=100

-- Folding slides the bottom edge, and the steps stay laid out at full size.
F.SetSetting("celebrations","full")
P:Open("gold_5k")
assert(P.unfold==1 and P.frame.heightForTest==300, "a window that is just appearing opens unfolded, without sliding")
P.driver:GetScript("OnUpdate")(P.driver, 1)
P:ToggleCollapsed()
local slide=P.bodyDriver:GetScript("OnUpdate")
assert(slide and P.collapsed, "folding starts one finite slide")
slide(P.bodyDriver,0.09)
assert(P.unfold>0 and P.unfold<1, "intermediate fold")
assert(P.frame.heightForTest>P.COLLAPSED and P.frame.heightForTest<300, "the bottom edge travels between the two sizes")
assert(P.scroll.scroll:IsShown() and P.clip.alphaForTest<1, "steps stay drawn and fade while they fold away")
slide(P.bodyDriver,1)
assert(P.unfold==0 and P.frame.heightForTest==P.COLLAPSED and not P.bodyDriver:GetScript("OnUpdate"), "fold settles and its driver stops")
assert(not P.scroll.scroll:IsShown() and not P.grip:IsShown() and P.clip.alphaForTest==1, "folded body and grip are hidden, alpha restored")
P:ToggleCollapsed()
slide=P.bodyDriver:GetScript("OnUpdate")
slide(P.bodyDriver,0.05)
assert(P.unfold>0 and P.unfold<1 and P.scroll.scroll:IsShown(), "unfolding slides open")
P:ToggleCollapsed()
assert(P.collapsed and P.bodyDriver:GetScript("OnUpdate"), "a fold can reverse mid-slide")
local reversed=P.unfold
P.bodyDriver:GetScript("OnUpdate")(P.bodyDriver,0.03)
assert(P.unfold<reversed, "reversal continues from where the edge was")
P.bodyDriver:GetScript("OnUpdate")(P.bodyDriver,1)
P:ToggleCollapsed(); P.bodyDriver:GetScript("OnUpdate")(P.bodyDriver,1)
assert(P.unfold==1 and P.frame.heightForTest==300, "unfold settles at the chosen size")

F.SetSetting("celebrations","subtle")
P:ToggleCollapsed()
assert(P.unfold==0 and not P.bodyDriver:GetScript("OnUpdate"), "Subtle folds at once")
P:ToggleCollapsed()
assert(P.unfold==1 and P.frame.heightForTest==300 and P.bodyDriver:GetScript("OnUpdate"), "Subtle unfolds at full size")
P.bodyDriver:GetScript("OnUpdate")(P.bodyDriver,0.05)
assert(P.clip.alphaForTest>0 and P.clip.alphaForTest<1, "Subtle fades the steps in")
P.bodyDriver:GetScript("OnUpdate")(P.bodyDriver,1)

-- Carrying the window deepens its shadow; letting go settles it.
F.SetSetting("celebrations","full")
P:SetShadowOpacity(0.3)
local oldCursor, oldDown = GetCursorPosition, IsMouseButtonDown
local x, y = 0, 0
GetCursorPosition=function() return x, y end
IsMouseButtonDown=function() return true end
P.frame.GetEffectiveScale=function() return 1 end
P.header:GetScript("OnMouseDown")(P.header,"LeftButton")
x=40
P.header:GetScript("OnUpdate")(P.header,0.016)
assert(P.dragging and P.fx:GetScript("OnUpdate"), "drag wakes the lift")
P.fx:GetScript("OnUpdate")(P.fx,1)
assert(math.abs(P.shadow.alphaForTest-0.48)<0.0001, "carried shadow is deeper")
P.header:GetScript("OnMouseUp")(P.header,"LeftButton")
assert(not P.dragging and not P.collapsed, "drop is not a click")
P.fx:GetScript("OnUpdate")(P.fx,1)
assert(math.abs(P.shadow.alphaForTest-0.3)<0.0001 and not P.fx:GetScript("OnUpdate"), "shadow settles and the driver stops")
GetCursorPosition, IsMouseButtonDown = oldCursor, oldDown
P:SetShadowOpacity(0)
P:WakeFx(); P.lift=1; P:PaintShadow()
assert(P.shadow.alphaForTest==0, "no shadow chosen stays no shadow, even when carried")
P.lift=0; P:SetShadowOpacity(0.3)

-- Hover wash: idle once the pointer is away.
P:WakeFx()
P.fx:GetScript("OnUpdate")(P.fx,1)
assert(P.wash==0 and not P.fx:GetScript("OnUpdate") and not P.washTex:IsShown(), "no wash or driver while the pointer is away")

-- Settings card: the Settings page's switches and sliders, on pop-out state.
P:ToggleOptions()
assert(P.options:IsShown() and P.settings.lit, "gear opens the card and stays lit")
local before=P.locked
P.optionControls[1]:GetScript("OnClick")(P.optionControls[1])
assert(P.locked==not before and D.popout.locked==(P.locked or nil), "lock switch writes pop-out state")
P.optionControls[1]:GetScript("OnClick")(P.optionControls[1])
local hide=F.Setting("hideCompletedSteps")
P.optionControls[2]:GetScript("OnClick")(P.optionControls[2])
assert(F.Setting("hideCompletedSteps")==not hide, "completed steps switch uses the shared setting")
P.optionControls[2]:GetScript("OnClick")(P.optionControls[2])
local closeMain=P.closeMain
P.optionControls[4]:GetScript("OnClick")(P.optionControls[4])
assert(P.closeMain==not closeMain and D.popout.closeMain==(P.closeMain or nil), "close-main switch is saved")
P.optionControls[4]:GetScript("OnClick")(P.optionControls[4])
for _, control in ipairs(P.optionControls) do control:Refresh() end
assert(not P.groupsButton:IsShown(), "Expand all only for goals with several groups")
P:ToggleOptions()
assert(not P.options:IsShown(), "gear closes the card")

-- Fit to steps keeps following the list: a finished step that hides
-- shrinks the window, gliding the bottom edge on Full.
P:Close(false)
D.active.sulfuras=true; D.progress.sulfuras={}
F.SetSetting("hideCompletedSteps",true)
F.SetSetting("celebrations","full")
P.autoFit=true
P:Open("sulfuras")
P.driver:GetScript("OnUpdate")(P.driver,1)
local fitted=P.height
assert(fitted==P:FitTarget(), "opens fitted")
local oldAfter, pending = C_Timer.After, {}
C_Timer.After=function(delay, callback) pending[#pending+1]={delay,callback} end
P.rows[1]:GetScript("OnClick")(P.rows[1],"LeftButton")
assert(P.height==fitted and not P.sizeDriver:GetScript("OnUpdate"), "the ticked row lingers, so the window holds")
for _, timer in ipairs(pending) do if timer[1]==0.55 then timer[2]() end end
C_Timer.After=oldAfter
local follow=P.sizeDriver:GetScript("OnUpdate")
assert(follow and P.sizeTo and P.sizeTo<fitted, "once the row hides, the window glides shorter")
follow(P.sizeDriver,0.08)
assert(P.height<fitted and P.height>P.sizeTo, "mid-glide")
follow(P.sizeDriver,1)
assert(P.height==P:FitTarget() and not P.sizeDriver:GetScript("OnUpdate") and D.popout.height==P.height, "settles fitted and saved")

-- Off snaps; a manual resize stops following for good.
F.SetSetting("celebrations","off")
P.rows[1]:GetScript("OnClick")(P.rows[1],"LeftButton")
assert(P.height==P:FitTarget() and not P.sizeDriver:GetScript("OnUpdate"), "Off fits at once")
local oldCursor2, oldDown2 = GetCursorPosition, IsMouseButtonDown
local gx, gy = 0, 0
GetCursorPosition=function() return gx, gy end
IsMouseButtonDown=function() return true end
P.grip:GetScript("OnMouseDown")(P.grip,"LeftButton")
gx, gy = 0, -40
P.grip:GetScript("OnUpdate")(P.grip,0.1)
P.grip:GetScript("OnMouseUp")(P.grip,"LeftButton")
GetCursorPosition, IsMouseButtonDown = oldCursor2, oldDown2
local chosen=P.height
assert(not P.autoFit, "resizing turns following off")
P.rows[2]:GetScript("OnClick")(P.rows[2],"LeftButton")
assert(P.height==chosen, "a chosen size is never overridden")
F.SetSetting("hideCompletedSteps",false)
P:Close(false)
P:Open("gold_5k")

-- The main guide's empty slot fills the visible guide, less room for the Tips row.
local viewport = F.PopoutUI.content:GetParent()
local oldHeight = viewport.GetHeight
viewport.GetHeight = function() return 200 end
local gold = F.GoalById("gold_5k")
local reserve = (gold.tips and #gold.tips > 0) and 40 or 0
P.slotHeight, P.slotWidth = nil, nil
assert(F.PopoutStepHeight(gold, 600, 300) == 200 - reserve, "a long guide's slot fills just the visible area")
P.slotHeight, P.slotWidth = nil, nil
assert(F.PopoutStepHeight(gold, 120, 300) == 200 - reserve, "a short guide's slot also fills the visible area (Karl, 2026-10-14)")
-- Short windows scroll the whole page and the list is as tall as its
-- content, so the visible part is measured on screen: list top (as if the
-- page were at its top) down to the page's bottom edge.
local page = F.detailViewport.scroll
local oldTop, oldBottom, oldScroll = viewport.GetTop, page.GetBottom, page.GetVerticalScroll
viewport.GetHeight = function() return 900 end
viewport.GetTop = function() return 500 end
page.GetBottom = function() return 300 end
page.GetVerticalScroll = function() return 50 end
P.slotHeight, P.slotWidth = nil, nil
assert(F.PopoutStepHeight(gold, 600, 300) == math.max(60, 150 - reserve), "short page: the slot fits what shows below the header: " .. tostring(P.slotDebug.used))
-- A normal window: the list's frame stops above the page's bottom edge, and the
-- slot fits the frame, not the edge (a few units more drew a scroll bar).
local oldShort = F.detailViewport.short
F.detailViewport.short = false
viewport.GetHeight = function() return 197 end
viewport.GetTop = function() return 500 end
page.GetBottom = function() return 300 end
page.GetVerticalScroll = function() return 0 end
P.slotHeight, P.slotWidth = nil, nil
assert(F.PopoutStepHeight(gold, 120, 300) == 197 - reserve, "normal window: the slot fits the list's own frame, so no scroll bar: " .. tostring(P.slotDebug.used))
F.detailViewport.short = oldShort
viewport.GetTop, page.GetBottom, page.GetVerticalScroll = oldTop, oldBottom, oldScroll
viewport.GetHeight = oldHeight
P.slotHeight, P.slotWidth = nil, nil

-- A finished goal shows the green check in place of its count.
GetMoney=function() return 5000 * 10000 end
STUB_FIRE("PLAYER_MONEY")
assert(P.progress==1 and P.doneCheck:IsShown(), "finished goal swaps its count for the check")
GetMoney=function() return 0 end
F.SetSetting("celebrations","off")
P:Close(false)
-- Tips glide from where they were to the fresh layout's spot (popping out, docking).
do
    local oldTips, oldLayout = F.tipsUI, F.guideLayout
    local placedY
    local tipFrame = { SetPoint = function(_, _, _, _, _, y) placedY = y end }
    F.SetSetting("celebrations","full")
    F.tipsUI = { startY = 100 }
    F.guideLayout = { nodes = { { key = "tips:line", frame = tipFrame, x = 0, y = 108 },
        { key = "step:1", frame = { SetPoint = function() error("steps are not glided here") end }, x = 0, y = 0 } } }
    P:GlideTips(160)
    assert(placedY == -168, "tips start where they were: " .. tostring(placedY))
    local glide = P.tipsDriver:GetScript("OnUpdate")
    glide(P.tipsDriver, 0.1)
    assert(placedY < -108 and placedY > -168, "tips ease toward their new spot: " .. tostring(placedY))
    glide(P.tipsDriver, 1)
    assert(placedY == -108 and not P.tipsDriver:GetScript("OnUpdate"), "tips settle and the glide stops")
    F.SetSetting("celebrations","off")
    placedY = nil
    P:GlideTips(160)
    assert(placedY == nil, "no glide with motion off")
    F.tipsUI, F.guideLayout = oldTips, oldLayout
end
print("  pop-out polish: sliding fold with reversal, Subtle and Off, carried shadow, idle hover driver, settings card switches, fit following the steps, finished check and tips glide ok")
