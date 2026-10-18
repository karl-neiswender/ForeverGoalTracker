local F, D = STUB_NS, ForeverGoalTrackerDB
D.gearPlanner = nil
local T = F.GearPlannerTest
local function Track(frame)
    local shown = false
    frame.IsShown = function() return shown end
    frame.Show = function(self)
        if not shown then shown = true; local fn = self:GetScript("OnShow"); if fn then fn(self) end end
    end
    frame.Hide = function(self)
        if shown then shown = false; local fn = self:GetScript("OnHide"); if fn then fn(self) end end
    end
    frame.SetShown = function(self, on) if on then self:Show() else self:Hide() end end
end
Track(F.GearPlanner); Track(F.libraryPanel); Track(T.picker)
local function click(b) b:GetScript("OnClick")(b) end
local function text(box, value) box:SetText(value); box:GetScript("OnTextChanged")(box) end
local oldName = UnitName
UnitName = function() return "PlannerOwner" end
F.ShowTab("gear")
assert(F.GearPlanner:IsShown() and not F.libraryPanel:IsShown())
local store = T.store()
assert(#store.builds == 0)
T.new()
assert(#store.builds == 0, "unnamed drafts are not persisted")
text(T.name, "Helm test")
assert(#store.builds == 1 and store.builds[1].name == "Helm test")
local id = store.builds[1].id
click(T.head)
assert(T.picker:IsShown() and #T.results == 2, "head-only class catalogue opens")
click(T.results[1])
assert(T.picker:IsShown(), "selection keeps picker open")
local item = store.builds[1].slots[1]
assert(item == 16866, "Warrior head target saved")
assert(T.head.itemName:GetText() == "Helm of Might", "filled head shows its name")
click(T.results[2])
assert(store.builds[1].slots[1] == 22418 and store.builds[1].id == id)
text(T.name, "Renamed")
assert(#store.builds == 1 and store.builds[1].id == id)
F.ShowTab("tracker"); F.ShowTab("gear")
assert(T.name:GetText() == "Renamed" and store.builds[1].slots[1] == 22418)
UnitName = function() return "OtherPlannerOwner" end
F.ShowTab("tracker"); F.ShowTab("gear")
assert(#T.store().builds == 0, "other character cannot see owner builds")
UnitName = function() return "PlannerOwner" end
F.ShowTab("tracker"); F.ShowTab("gear")
assert(T.name:GetText() == "Renamed")
click(T.unequip)
assert(not store.builds[1].slots[1], "unequip clears only the planned target")
assert(T.head.itemName:GetText() == "", "unequip removes item label")
F.ShowTab("library")
assert(not F.GearPlanner:IsShown() and F.libraryPanel:IsShown())
UnitName = oldName
F.ShowTab("tracker")
print("  per-character named autosave, stable IDs, item replacement, open picker and tab switching ok")
-- Wide and tall windows preserve background proportions without shrinking the model drawing area.
T.model.SetSize = function() error("resizing must not reintroduce an interior model clipping frame") end
for _, size in ipairs({ {800, 400}, {400, 650} }) do
    local tiles = {}
    for i = 1, 4 do
        local index = i
        T.modelArea["bg" .. i].texture.SetSize = function(_, w, h) tiles[index] = {w, h} end
    end
    T.modelArea:GetScript("OnSizeChanged")(T.modelArea, size[1], size[2])
    assert(math.abs(tiles[1][1] / tiles[1][2] - 256/255) < 0.0001, "background keeps native aspect")
    assert(math.abs(tiles[2][1] / tiles[1][1] - 62/256) < 0.0001, "right background strip is not stretched")
end
T.model.SetSize = nil
print("  wide/tall preview keeps native background proportions and full-panel model drawing")
-- Wheel zoom uses the same safe portrait limit as head focus.
local portraitZoom
T.model.SetPortraitZoom = function(_, value) portraitZoom = value end
T.model:GetScript("OnMouseWheel")(T.model, 100)
assert(portraitZoom == 0.8, "wheel zoom reaches native portrait limit")
T.model:GetScript("OnMouseWheel")(T.model, -100)
assert(portraitZoom == 0, "wheel zoom returns to full-character view")
T.model.SetPortraitZoom = nil

click(T.head)
assert(T.picker:IsShown())
T.clickAway:GetScript("OnEvent")()
assert(not T.picker:IsShown(), "outside click closes picker")
local count = 0
for _ in pairs(T.slots) do count = count + 1 end
assert(count == 19, "armor, accessory and weapon placeholders are present")
