local F, D = STUB_NS, ForeverGoalTrackerDB
local P, U = F.Popout, F.PopoutUI
P.autoFit = false -- this fixture verifies the player's explicitly chosen size
local function Track(frame, shown)
    frame._testShown = shown or false
    frame.Show = function(self) self._testShown = true end
    frame.Hide = function(self) self._testShown = false end
    frame.SetShown = function(self, value) self._testShown = value and true or false end
    frame.IsShown = function(self) return self._testShown end
    frame.SetAlpha = function(self, alpha) self._testAlpha = alpha end
end
Track(F.MaterialsUI.main, true)
Track(P.frame); Track(P.placeholder); Track(P.grip); Track(P.launch); Track(P.options)
Track(P.body); Track(P.heading)
for _, row in ipairs(U.rows) do Track(row) end
for _, row in ipairs(U.headers) do Track(row) end
D.active = {thunderfury=true, sulfuras=true, lokdelar=true, gold_5k=true, tier3_warrior=true}
D.activeParts = {}
D.progress = {thunderfury={}, sulfuras={}, lokdelar={}, gold_5k={}, tier3_warrior={}}
D.characters = {}
F.SetSetting("celebrations", "off")
F.SetSetting("hideCompletedSteps", false)
F.SelectGoal("sulfuras")
local before = STUB_SERIALIZE(D.progress)
assert(P:Open("sulfuras"), "active goal can be popped out")
assert(P.open and P.frame:IsShown() and P.placeholder:IsShown(), "pop-out and recessed placeholder are shown")
assert(STUB_SERIALIZE(D.progress)==before, "opening never changes progress")
local height = P.slotHeight
P.rows[1]:GetScript("OnClick")(P.rows[1], "LeftButton")
assert(D.progress.sulfuras[1], "pop-out checkbox writes the authoritative progress")
assert(P.slotHeight==height, "progress does not move Tips up")
F.SelectGoal("thunderfury")
assert(P.goalId=="sulfuras" and not P.placeholder:IsShown(), "browsing does not replace the popped-out goal")
local browsing = D.selected
P.rows[2]:GetScript("OnClick")(P.rows[2], "LeftButton")
assert(D.progress.sulfuras[2] and D.selected==browsing, "pop-out tick preserves the browsed goal")

local oldLink = F.StepLinkClick
F.StepLinkClick = function() return true end
before = STUB_SERIALIZE(D.progress)
P.rows[3]:GetScript("OnClick")(P.rows[3], "RightButton")
assert(STUB_SERIALIZE(D.progress)==before, "handled link cannot tick the row")
F.StepLinkClick = oldLink

P:SetOpacity(0.3)
assert(P.chrome.etchBg.fgtGa1==0.3 and P.chrome.etchBg.fgtGa2==0.3 and P.frame._testAlpha==1,
    "opacity changes both backgrounds without fading the parent/text")
P:SetLocked(true)
assert(not P.grip:IsShown(), "locking hides the resize grip")
P.header:GetScript("OnMouseDown")(P.header, "LeftButton")
assert(not P.header:GetScript("OnUpdate"), "locked header cannot start moving")
P:SetLocked(false)
assert(P.grip:IsShown(), "unlock restores the resize grip")
P.left, P.top, P.width, P.height = 90, 110, 400, 240
P:Place(); P:Save()
P:Open("thunderfury")
assert(P.left==90 and P.top==110 and P.width==400 and P.height==240, "new goal reuses placement and size")

local oldCursor, oldButton = GetCursorPosition, IsMouseButtonDown
local x, y = 50, 50
GetCursorPosition = function() return x, y end
IsMouseButtonDown = function() return true end
P.frame.GetEffectiveScale = function() return 1 end
P.header:GetScript("OnMouseDown")(P.header, "LeftButton")
x, y = 100, 20
P.header:GetScript("OnUpdate")(P.header, 0.1)
P.header:GetScript("OnMouseUp")(P.header, "LeftButton")
assert(P.left==140 and P.top==140 and D.popout.left==140, "header drag moves and saves the shared anchor")
P.grip:GetScript("OnMouseDown")(P.grip, "LeftButton")
x, y = 150, -10
P.grip:GetScript("OnUpdate")(P.grip, 0.1)
P.grip:GetScript("OnMouseUp")(P.grip, "LeftButton")
assert(P.width==450 and P.height==270 and not P.grip:GetScript("OnUpdate"), "corner resizing updates bounds and stops on release")
P.width, P.height, P.left, P.top = 1, 1, -100, -100
P:Place()
assert(P.width>=280 and P.height>=80 and P.left>=8 and P.top>=8, "minimum readable size and offscreen clamping")
GetCursorPosition, IsMouseButtonDown = oldCursor, oldButton

-- A checked row stays in place until its response has finished.
F.SetSetting("hideCompletedSteps", true)
F.SetSetting("celebrations", "full")
D.progress.sulfuras = {}
P:Open("sulfuras")
local oldAfter, pending = C_Timer.After, {}
C_Timer.After = function(delay, callback) pending[#pending+1]={delay,callback} end
P.rows[1]:GetScript("OnClick")(P.rows[1], "LeftButton")
assert(P.layout.byKey["step:1"], "new completion does not immediately move the next row under the pointer")
for _, timer in ipairs(pending) do if timer[1]==0.55 then timer[2]() end end
assert(not P.layout.byKey["step:1"], "completed row disappears after the response delay")
C_Timer.After = oldAfter
F.SetSetting("hideCompletedSteps", false)
F.SetSetting("celebrations", "off")

-- Locks are the same Classic gates (or explicit preview) as the main guide.
local oldPreview = F.testDependencies
F.testDependencies = true
P:Open("lokdelar")
before = STUB_SERIALIZE(D.progress.lokdelar)
assert(P.rows[3].depLocked, "pop-out displays prerequisite lock")
P.rows[3]:GetScript("OnClick")(P.rows[3], "LeftButton")
assert(STUB_SERIALIZE(D.progress.lokdelar)==before, "locked row cannot be checked off")
F.testDependencies = oldPreview

-- Reuse the exact piece and material addresses; never add a piece checkbox.
P:Open("tier3_warrior")
assert(P.rows[1].pieceKey, "recipe row expands rather than becoming a checkbox")
P.rows[1]:GetScript("OnClick")(P.rows[1], "LeftButton")
local node = P.layout.byKey["material:1:1:1"]
assert(node, "expanding a recipe exposes its ingredient rows")
node.frame:GetScript("OnClick")(node.frame, "LeftButton")
assert(D.progress.tier3_warrior["1_1_m1"], "material checkbox uses existing saved key")
assert(not D.progress.tier3_warrior["1_1_piece"], "ingredient tick does not invent ownership")

-- Automatic updates still render with the main frame hidden.
P:Open("gold_5k")
F.MaterialsUI.main:Hide()
local money = GetMoney
GetMoney = function() return 5000 * 10000 end
STUB_FIRE("PLAYER_MONEY")
assert(P.progress==1, "automatic progress updates the pop-out while main is closed")
GetMoney = money
P:Close(false)
assert(not P.open and not P.frame:IsShown() and not F.MaterialsUI.main:IsShown(), "Close keeps main closed")
P:Open("thunderfury")
P:Close(true)
assert(F.MaterialsUI.main:IsShown() and D.selected=="thunderfury" and not P.open, "Dock opens the right main guide")
assert(not P.driver:GetScript("OnUpdate"), "motion-off docking leaves no idle updater")

-- Interrupted transfers use the current alpha and cancel the old completion.
F.SetSetting("celebrations", "full")
P:Open("sulfuras")
local opening = P.driver:GetScript("OnUpdate")
assert(opening, "opening starts a finite transition")
opening(P.driver, 0.08)
assert(P.fraction>0 and P.fraction<1, "intermediate opening fade")
P:Close(false)
P:Open("thunderfury")
local replacement = P.driver:GetScript("OnUpdate")
replacement(P.driver, 0.25)
assert(P.open and P.goalId=="thunderfury" and P.fraction==1, "replacement survives interrupted close")
assert(not P.driver:GetScript("OnUpdate"), "opening stops its update script")
F.SetSetting("celebrations", "off")

-- Load persisted preferences before setters can overwrite the save table.
D.popout = {open=true,goal="sulfuras",left=75,top=80,width=410,height=260,opacity=0.42,locked=true,autoFit=false}
P.open = false
P.events:GetScript("OnEvent")(P.events, "PLAYER_LOGIN")
assert(P.open and P.goalId=="sulfuras" and P.left==75 and P.top==80, "login restores chosen goal and placement")
assert(P.width==410 and P.height==260 and P.opacity==0.42 and P.locked, "login restores size, opacity and lock")
D.active.sulfuras = nil
P:Refresh()
assert(not P.open and not D.popout.open, "removed goal cannot leave a stale pop-out")
assert(not P:Open("missing_goal") and not P:Open("sulfuras"), "missing or inactive goals cannot open")
print("  pop-out: shared ticks, locks, recipes, links, hidden-window updates, placeholder, opacity, docking, interruption and saved preferences ok")
