local F, D = STUB_NS, ForeverGoalTrackerDB
STUB_NS.noRequirementLocks = true -- these tests tick steps by clicking; locks have their own tests (dependency-tests.lua)
local P, U = F.Popout, F.PopoutUI
P.autoFit = false
local function Track(frame, shown)
    frame._testShown = shown or false
    frame.Show = function(self) self._testShown = true end
    frame.Hide = function(self) self._testShown = false end
    frame.SetShown = function(self, value) self._testShown = value and true or false end
    frame.IsShown = function(self) return self._testShown end
end
Track(P.frame); Track(P.options); Track(P.grip); Track(P.scroll.scroll); Track(F.MaterialsUI.main, true)
P.frame.SetSize = function(self, width, height) self._testWidth, self._testHeight = width, height end
P.frame.SetFrameStrata = function(self, strata) self._testStrata = strata end
P.frame.SetFrameLevel = function(self, level) self._testLevel = level end
F.MaterialsUI.main.GetFrameLevel = function() return 20 end
F.SetSetting("celebrations", "off")
F.SetSetting("hideCompletedSteps", false)
local goal = F.GoalById("set_tier2_hunter")
assert(goal and #goal.sections==1, "screenshot armor set exists")
D.active[goal.id] = true
D.progress[goal.id] = {}
F.sectionOpen[goal.id .. "_1"] = nil
P:Open(goal.id)
assert(P.frame._testStrata=="HIGH" and P.frame._testLevel>20, "pop-out layers above main")
assert(P.singleSection==1 and not P.layout.byKey["section:1"], "single group is merged into the window heading")
assert(P.title:GetText()==goal.sections[1].name, "heading identifies the group")
for _, row in ipairs(P.rows) do
    row.icon.Show = function() error("pop-out should not show row icons") end
end
P:Refresh()

local expandedHeight = P.height
P.header:GetScript("OnMouseDown")(P.header, "LeftButton")
P.header:GetScript("OnMouseUp")(P.header, "LeftButton")
assert(P.collapsed and P.frame._testHeight==P.COLLAPSED and P.height==expandedHeight,
    "header click collapses to header and retains expanded size")
assert(not P.scroll.scroll:IsShown() and not P.grip:IsShown(), "collapsed body and resize grip are hidden")
assert(not F.SectionIsOpen(goal, 1), "merged heading uses the real group expansion state")
P.header:GetScript("OnMouseDown")(P.header, "LeftButton")
P.header:GetScript("OnMouseUp")(P.header, "LeftButton")
assert(not P.collapsed and P.frame._testHeight==expandedHeight and P.scroll.scroll:IsShown(), "header click restores expanded window")
P:SetLocked(true)
P.header:GetScript("OnMouseDown")(P.header, "LeftButton")
P.header:GetScript("OnMouseUp")(P.header, "LeftButton")
assert(P.collapsed and not P.header:GetScript("OnUpdate"), "locked header remains clickable without allowing movement")
P:ToggleCollapsed(); P:SetLocked(false)

local oldCursor, oldDown = GetCursorPosition, IsMouseButtonDown
local x, y = 50, 50
GetCursorPosition = function() return x, y end
IsMouseButtonDown = function() return true end
P.frame.GetEffectiveScale = function() return 1 end
P.header:GetScript("OnMouseDown")(P.header, "LeftButton")
x = 65
P.header:GetScript("OnUpdate")(P.header, 0.1)
P.header:GetScript("OnMouseUp")(P.header, "LeftButton")
assert(not P.collapsed and F.SectionIsOpen(goal,1), "header drag never toggles the group")
GetCursorPosition, IsMouseButtonDown = oldCursor, oldDown

local optionsHover, gearHover = false, false
P.options.IsMouseOver = function() return optionsHover end
P.settings.IsMouseOver = function() return gearHover end
P.options:Show()
optionsHover = true; STUB_FIRE("GLOBAL_MOUSE_DOWN", "LeftButton")
assert(P.options:IsShown(), "inside settings clicks remain interactive")
optionsHover = false; gearHover = true; STUB_FIRE("GLOBAL_MOUSE_DOWN", "LeftButton")
assert(P.options:IsShown(), "settings button is left to its own toggle")
P.settings:GetScript("OnClick")(P.settings)
assert(not P.options:IsShown(), "settings button closes without immediately reopening")
P.options:Show(); gearHover = false
STUB_FIRE("GLOBAL_MOUSE_DOWN", "RightButton")
assert(not P.options:IsShown(), "any outside mouse down dismisses settings")

for _, fade in ipairs({P.scroll.fadeTop, P.scroll.fadeBottom}) do
    for _, strip in ipairs(fade.strips) do
        strip.SetVertexColor=function(self,_,_,_,a) self._testOpacity=a end
        strip.SetAlpha=function() error("setting uniform strip alpha flattens the fade") end
    end
end
P:SetOpacity(0.25)
P.scroll:Update()
for _, fade in ipairs({P.scroll.fadeTop, P.scroll.fadeBottom}) do
    for i, strip in ipairs(fade.strips) do assert(strip._testOpacity==fade.stripAlphas[i]*0.25, "scroll shade preserves its curve at reduced opacity") end
end
P:SetOpacity(0)
for _, strip in ipairs(P.scroll.fadeBottom.strips) do assert(strip._testOpacity==0, "no opaque bottom band at zero opacity") end

local oldInfo, oldPreview, oldDress, oldModified = F.ItemInfo, F.ItemCanPreview, DressUpItemLink, IsModifiedClick
local oldDressFrame = DressUpFrame
local dressed = {}
F.ItemInfo = function(id) return "Piece " .. id, "item:" .. id end
F.ItemCanPreview = function() return true end
DressUpItemLink = function(link) dressed[#dressed+1]=link end
DressUpFrame = nil
IsModifiedClick = function(kind) return kind=="DRESSUP" end
local before = STUB_SERIALIZE(D.progress)
P.headerIcon:GetScript("OnMouseUp")(P.headerIcon,"LeftButton")
assert(#dressed==#F.SetPreviewIds(goal), "Ctrl-click header icon previews every piece")
assert(STUB_SERIALIZE(D.progress)==before, "header preview never changes progress")
F.ItemInfo, F.ItemCanPreview, DressUpItemLink, IsModifiedClick = oldInfo, oldPreview, oldDress, oldModified
DressUpFrame = oldDressFrame

P:ToggleCollapsed()
P:Save()
assert(D.popout.collapsed, "collapsed state is saved")
P.open = false
P.events:GetScript("OnEvent")(P.events,"PLAYER_LOGIN")
assert(P.open and P.collapsed and P.height==expandedHeight, "reload restores collapsed state and expanded size")
P:ToggleCollapsed()
D.activeParts.epicmounts={[1]=true,[2]=true}; D.progress.epicmounts={}
assert(P:Open("epicmounts"), "multi-part mount remains available")
assert(not P.singleSection and P.layout.byKey["section:1"] and P.layout.byKey["section:2"], "multiple groups retain their headings")
P:Close(false)
print("  pop-out refinements: above-main layering, outside settings dismissal, fading shade, merged header, click versus drag, collapse restoration and full-set preview ok")
