local F, D = STUB_NS, ForeverGoalTrackerDB
local P, S = F.Popout, F.MaterialsUI
local function Track(frame, shown)
    frame.shownForTest = shown or false
    frame.Show=function(self) self.shownForTest=true end
    frame.Hide=function(self) self.shownForTest=false end
    frame.SetShown=function(self,on) self.shownForTest=on and true or false end
    frame.IsShown=function(self) return self.shownForTest end
end
Track(S.main,true); Track(P.frame); Track(P.options); Track(P.grip)
P.mainLevel=10
S.main.SetFrameLevel=function(self,level) self.levelForTest=level end
S.main.GetFrameLevel=function(self) return self.levelForTest or 10 end
P.frame.SetFrameLevel=function(self,level) self.levelForTest=level end
P.frame.GetFrameLevel=function(self) return self.levelForTest or 110 end
P.shadow.SetAlpha=function(self,a) self.alphaForTest=a end
P.frame.SetAlpha=function(self,a) self.alphaForTest=a end
P.frame.SetSize=function(self,w,h) self.widthForTest,self.heightForTest=w,h end
P.frame.SetPoint=function(self,_,_,_,x,y) self.xForTest,self.yForTest=x,y end
P.measure.GetStringWidth=function(self)
    local text=(self:GetText() or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
    return #text*6
end
F.SetSetting("celebrations","off")
F.SetSetting("hideCompletedSteps",false)
D.active.gold_5k=true; D.active.sulfuras=true
D.progress.gold_5k={}; D.progress.sulfuras={}; D.characters={}
P.autoFit=true; P.closeMain=false; P.width=500; P.height=600
P:Open("gold_5k")
assert(P.width<500 and P.height<600 and P.height==math.max(80,math.ceil(P.layout.height+62)), "opening fits the steps instead of leaving a large empty body")
assert(S.main:IsShown(),"main remains open by default")
assert(not P.bar:GetScript("OnEnter") and not P.bar:GetScript("OnLeave"),"progress strip has no redundant tooltip")
assert(P.chrome.etchBg and P.chrome.grimeParts and P.shadow,"What’s new etched panel, grime and shadow are reused")
local before=STUB_SERIALIZE(D.progress)
P:FitSteps()
assert(STUB_SERIALIZE(D.progress)==before,"sizing never changes checklist progress")

P:SetOpacity(0.4); P:SetShadowOpacity(0.2)
assert(P.chrome.etchBg.fgtGa1==0.4 and P.chrome.etchBg.fgtGa2==0.4,"panel gradients use actual alpha endpoints")
assert(P.shadow.alphaForTest==0.2,"shadow has independent opacity")
P:SetOpacity(0)
assert(P.shadow.alphaForTest==0.2 and P.chrome.etchBg.fgtGa1==0,"body transparency does not overwrite shadow choice")
P:SetShadowOpacity(0)
assert(P.shadow.alphaForTest==0,"shadow can be removed completely")
local fade=P.scroll.fadeBottom
for i,strip in ipairs(fade.strips) do strip.SetVertexColor=function(self,_,_,_,a) self.alphaForTest=a end end
P:SetOpacity(0.5)
assert(fade.strips[1].alphaForTest>fade.strips[#fade.strips].alphaForTest,"bottom shading stays a ramp, not a solid rectangle")
P.scroll:Update()
for i,strip in ipairs(fade.strips) do assert(strip.alphaForTest==fade.stripAlphas[i]*0.5,"scroll updates preserve the opacity-scaled fade") end

local oldFoci=GetMouseFoci
GetMouseFoci=function() return {S.detail} end
STUB_FIRE("GLOBAL_MOUSE_DOWN","LeftButton")
assert(P.frame.levelForTest>S.main.levelForTest,"clicking main content does not bring main in front of the pop-out (Karl, 2026-10-14)")
GetMouseFoci=function() return {P.scroll.scroll} end
STUB_FIRE("GLOBAL_MOUSE_DOWN","LeftButton")
assert(P.frame.levelForTest>S.main.levelForTest,"the pop-out stays in front")
for _=1,20 do
    P:FocusMain(); P:Raise()
end
assert(S.main.levelForTest==10 and P.frame.levelForTest==110,"focus changes do not keep increasing frame levels")
GetMouseFoci=oldFoci

P.autoFit=false; P.width=390; P.height=220; P:Place()
P:Open("sulfuras")
assert(P.width==390 and P.height==220,"manual size is retained for later goals")
P.autoFit=true
local oldCursor, oldDown = GetCursorPosition, IsMouseButtonDown
local mouseX, mouseY = 0, 0
GetCursorPosition=function() return mouseX, mouseY end
IsMouseButtonDown=function() return true end
P.frame.GetEffectiveScale=function() return 1 end
P.grip:GetScript("OnMouseDown")(P.grip,"LeftButton")
assert(P.autoFit,"pressing the grip without resizing keeps auto-fit enabled")
mouseX, mouseY=20, -20
P.grip:GetScript("OnUpdate")(P.grip,0.1)
assert(not P.autoFit,"manual resize turns automatic fitting off")
P.grip:GetScript("OnMouseUp")(P.grip,"LeftButton")
GetCursorPosition, IsMouseButtonDown=oldCursor, oldDown
P:Close(false)
P.closeMain=true; S.main:Show()
P:Open("gold_5k")
assert(not S.main:IsShown(),"opt-in auto close hides main after pop-out")
P:Close(true)
assert(S.main:IsShown(),"docking opens main even when auto close is enabled")

P.closeMain=false; P:SetShadowOpacity(0.4)
F.SetSetting("celebrations","full")
P:Open("sulfuras")
assert(P.frame.alphaForTest==0 and P.shadow.alphaForTest==0,"window and shadow start hidden")
local step=P.driver:GetScript("OnUpdate")
step(P.driver,0.1)
assert(math.abs(P.fraction-0.875)<0.00001,"opening uses What’s new cubic fade")
assert(math.abs(P.shadow.alphaForTest-0.35)<0.00001,"shadow fades with opening at chosen opacity")
assert(math.abs(P.frame.yForTest-(-P.top-6*(1-P.fraction)))<0.00001,"opening uses the same six-unit rise")
step(P.driver,0.1)
assert(not P.driver:GetScript("OnUpdate"),"opening leaves no idle driver")
-- docking back: the pop-out arrow and Hide completed fade in with the steps
for _,c in ipairs({P.launch,F.completedStepsBtn}) do c.SetAlpha=function(self,v) self.alphaForTest=v end end
P:Close(true)
local docking=P.driver:GetScript("OnUpdate")
docking(P.driver,0.05)
local mid=F.completedStepsBtn.alphaForTest
assert(mid and mid>0 and mid<1 and P.launch.alphaForTest==mid,"docking fades the guide's controls in with the steps: "..tostring(mid))
docking(P.driver,1)
assert(F.completedStepsBtn.alphaForTest==1 and P.launch.alphaForTest==1,"docked controls end fully shown")
P:Open("sulfuras")
P.driver:GetScript("OnUpdate")(P.driver,1)
P.autoFit=false; P.closeMain=true; P:SetShadowOpacity(0.65); P:Save()
P.open=false
P.events:GetScript("OnEvent")(P.events,"PLAYER_LOGIN")
assert(P.open and not P.autoFit and P.closeMain and P.shadowOpacity==0.65,"new preferences survive login restoration")
F.SetSetting("celebrations","off"); P:Close(false)
-- a narrow page: Pop out keeps only its icon before Show completed leaves the heading row
do
    local body, launch = F.detailBody, P.launch
    local getWidth = body.GetWidth
    -- (stub frames have no size or visibility of their own)
    Track(launch, true); Track(launch.text, true)
    launch.SetWidth = function(self, w) self.widthForTest = w end
    launch.GetWidth = function(self) return self.widthForTest or self.fullWidth end
    launch.fullWidth = 90
    body.GetWidth = function() return 900 end; F.LayoutStepControls()
    assert(launch.text:IsShown() and launch:GetWidth() == launch.fullWidth, "a wide page keeps the Pop out word")
    body.GetWidth = function() return 44 + 14 + F.completedStepsBtn:GetWidth() + launch.fullWidth end; F.LayoutStepControls() -- (the word's last 14 don't fit)
    assert(not launch.text:IsShown() and launch:GetWidth() == launch.iconWidth, "a narrow page shows only the Pop out icon")
    body.GetWidth = function() return 900 end; F.LayoutStepControls()
    assert(launch.text:IsShown() and launch:GetWidth() == launch.fullWidth, "widening brings the word back")
    body.GetWidth = getWidth; F.LayoutStepControls()
end
print("  pop-out QOL: compact Pop out on narrow pages, fit sizing, manual precedence, panel style, preserved fade curve, no bar tooltip, focus switching, opt-in main close and shadow fade/persistence ok")
