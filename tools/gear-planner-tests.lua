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
click(T.head)
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
T.camera:GetScript("OnUpdate")(T.camera, 1)
assert(portraitZoom == 0.8, "wheel zoom reaches native portrait limit")
T.model:GetScript("OnMouseWheel")(T.model, -100)
T.camera:GetScript("OnUpdate")(T.camera, 1)
assert(portraitZoom == 0, "wheel zoom returns to full-character view")
T.model.SetPortraitZoom = nil

click(T.head)
assert(T.picker:IsShown())
T.clickAway:GetScript("OnEvent")()
assert(not T.picker:IsShown(), "outside click closes picker")
local count = 0
for _ in pairs(T.slots) do count = count + 1 end
assert(count == 19, "armor, accessory and weapon placeholders are present")

-- Every class has its eight canonical Tier 3 armor pieces plus its unique ring.
local classes = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local names = {"HeadSlot","ShoulderSlot","ChestSlot","HandsSlot","LegsSlot","WaistSlot","WristSlot","FeetSlot"}
local ids = {1,3,5,10,7,6,9,8}
local oldClass = UnitClass
local counts = {}
for _, item in ipairs(T.catalogue) do if not item.preRaid then counts[item.class] = (counts[item.class] or 0) + 1 end end
for _, class in ipairs(classes) do
    assert(counts[class] == 10, "each class has Tier 1 head plus complete nine-piece Tier 3")
    UnitClass = function() return class, class end
    F.ShowTab("gear"); T.new(); text(T.name, class .. " full Tier 3")
    local build = T.store().builds[#T.store().builds]
    for i, slot in ipairs(names) do
        click(T.slots[slot])
        if slot == "HeadSlot" then click(T.results[2]) else click(T.results[1]) end
        local item = build.slots[ids[i]]
        assert(item, "slot selection saves its target")
        for _, entry in ipairs(T.catalogue) do
            if entry.id == item then assert(entry.class == class and entry.slot == slot, "picker restricts class and slot") end
        end
        assert(T.picker:IsShown(), "armor selection keeps picker open")
        assert(T.head.itemName:GetText() ~= "", "equipping armor preserves head label")
    end
    click(T.slots.Finger0Slot); click(T.results[1])
    local ring = build.slots[11]
    assert(ring)
    click(T.slots.Finger1Slot); click(T.results[1])
    assert(build.slots[12] == ring and not build.slots[11], "unique ring moves instead of duplicating")
    click(T.slots.ShoulderSlot); click(T.unequip)
    assert(not build.slots[3] and build.slots[1] and build.slots[5], "unequip only clears chosen slot")
end
UnitClass = oldClass
F.ShowTab("tracker")
print("  all nine classes: full Tier 3, class/slot filtering, independent targets and unique ring placement ok")

-- Explicit tracking, character scope, stable item credit and menu/camera behavior.
UnitName = function() return "PlannerOwner" end
F.ShowTab("gear"); T.new(); text(T.name, "Tracked polish")
local build = T.store().builds[#T.store().builds]
local function SelectedRowState()
    for _, row in ipairs(T.rows) do
        if row.text:GetText() == build.name then return row.state:GetText() end
    end
end
assert(not build.tracked and not build.goalId and SelectedRowState() == "Draft", "named drafts list without tracking a goal")
click(T.head); click(T.results[1])
assert(T.head.chosen and T.results[1].chosen and not T.results[2].chosen, "selection survives refresh")
local key = F.MaterialsUI.charKey()
local foreign = "Foreign-" .. GetRealmName()
local previousOwner, previousForeign = D.characters[key], D.characters[foreign]
D.characters[key] = {items = {}}
D.characters[foreign] = {items = {[16866] = 1}}
local catalogueCount = F.CatalogGoalCount()
click(T.add)
assert(build.tracked and D.active[build.goalId] and SelectedRowState() == "In My Goals", "explicit add lists and activates a stable goal")
local goal = F.GoalById(build.goalId)
assert(goal and goal.name == "Tracked polish" and #goal.steps == 1)
assert(not F.LibraryVisible(goal) and F.CatalogGoalCount() == catalogueCount, "personal sets stay out of Library")
assert(not D.progress[goal.id][1], "another character's item never completes the build")
D.characters[key].items[16866] = 1
F.RefreshPlannerGoals()
assert(D.progress[goal.id][1], "owner's existing item completes automatically")
D.characters[key].items = {}
local goalId = goal.id
text(T.name, "Tracked renamed")
assert(build.goalId == goalId and goal.name == "Tracked renamed" and D.progress[goalId][1], "rename preserves identity and credit")
click(T.slots.ShoulderSlot); click(T.results[1])
D.progress[goalId][2] = true
click(T.head)
local tooltipCalls = 0
local oldTip = GameTooltip.SetHyperlink
GameTooltip.SetHyperlink = function() tooltipCalls = tooltipCalls + 1 end
T.head:GetScript("OnEnter")(T.head)
assert(tooltipCalls == 0, "active slot tooltip cannot cover its action menu")
GameTooltip.SetHyperlink = oldTip
click(T.replace); click(T.results[2])
assert(not D.progress[goalId][1] and D.progress[goalId][2], "replacing head clears only head credit")
assert(T.results[2].chosen and not T.results[1].chosen, "picker marks the replacement")
click(T.head); click(T.unequip)
assert(#goal.steps == 1 and D.progress[goalId][1], "removing an earlier slot moves shoulder credit with its item")
click(T.head); click(T.results[2])
assert(#goal.steps == 2 and not D.progress[goalId][1] and D.progress[goalId][2], "inserting an earlier slot preserves shoulder credit")
local position
T.model.SetPosition = function(_, x, y, z) position = {x,y,z} end
for _, slot in ipairs({"HeadSlot", "ShoulderSlot", "HandsSlot", "WristSlot", "FeetSlot"}) do
    click(T.slots[slot])
    local update = T.camera:GetScript("OnUpdate")
    if update then update(T.camera, 1) end
    assert(position and position[3] ~= 0, "armor focus repositions the full-panel model")
    assert(not T.camera:GetScript("OnUpdate"), "camera stops after settling")
end
T.model.SetPosition = nil
D.plannerPolishSmoke = { goalId = goalId, key = key, buildId = build.id }
D.characters[key], D.characters[foreign] = previousOwner, previousForeign
UnitName = oldName
F.ShowTab("tracker")
print("  explicit add, Library exclusion, character scope, replacement credit, tooltip suppression and camera settling ok")

-- Dwarf male focus differs from the general body profile; retargeting stays continuous.
local oldRace, oldSex = UnitRace, UnitSex
UnitName = function() return "PlannerOwner" end
UnitRace = function() return "Dwarf", "Dwarf" end
UnitSex = function() return 2 end
F.ShowTab("gear")
local focused
T.model.SetPosition = function(_, x, y, z) focused = {x, y, z} end
local function settle(slot)
    click(T.slots[slot])
    local update = T.camera:GetScript("OnUpdate")
    if update then update(T.camera, 1) end
    return focused
end
for _, slot in ipairs({"ShoulderSlot", "HandsSlot", "WristSlot", "FeetSlot"}) do
    assert(settle(slot)[2] > 0, "one-sided focus uses the opposite lateral offset")
end
local dwarfHands = settle("HandsSlot")[3]
UnitSex = function() return 3 end
assert(settle("HandsSlot")[3] ~= dwarfHands, "dwarf male calibration leaves female profile unchanged")
UnitSex = function() return 2 end
settle("WaistSlot")
local from = focused[3]
click(T.slots.FeetSlot)
local update = T.camera:GetScript("OnUpdate")
update(T.camera, 0.1)
assert(focused[3] > from and focused[3] < 0.99, "camera eases through intermediate positions")
local intermediate = focused[3]
click(T.slots.HandsSlot)
T.camera:GetScript("OnUpdate")(T.camera, 0)
assert(focused[3] == intermediate, "retarget begins at the displayed position")
T.camera:GetScript("OnUpdate")(T.camera, 1)
-- Gear swaps are delayed until the fade, coalesced, and independent of camera alpha.
local swaps, alpha = 0, 1
T.model.Undress = function() swaps = swaps + 1 end
T.model.SetAlpha = function(_, value) alpha = value end
click(T.head); click(T.replace); click(T.results[1]); click(T.results[2])
assert(swaps == 0, "rapid comparisons keep the old preview until the fade")
T.appearance:GetScript("OnUpdate")(T.appearance, 0.08)
local faded = alpha
assert(faded < 1 and faded > 0.30, "appearance eases down before replacement")
local cameraUpdate = T.camera:GetScript("OnUpdate")
if cameraUpdate then cameraUpdate(T.camera, 0.1) end
assert(alpha == faded, "camera never overwrites the gear fade")
T.appearance:GetScript("OnUpdate")(T.appearance, 0.32)
assert(swaps == 1 and alpha == 1 and not T.appearance:GetScript("OnUpdate"), "latest preview paints once and fade stops")
UnitRace, UnitSex, UnitName = oldRace, oldSex, oldName
T.model.SetPosition, T.model.Undress, T.model.SetAlpha = nil, nil, nil
F.ShowTab("tracker")
assert(not T.camera:GetScript("OnUpdate") and not T.appearance:GetScript("OnUpdate"), "hidden planner stops both drivers")
print("  dwarf male profile isolation, opposite-side focus, continuous camera retargets and independent gear fades ok")

-- Back selection turns the model without interfering with wheel zoom or manual rotation.
UnitName = function() return "PlannerOwner" end
F.ShowTab("gear")
local angle
T.model.SetFacing = function(_, value) angle = value end
click(T.slots.BackSlot)
T.turn:GetScript("OnUpdate")(T.turn, 0.2)
assert(angle and angle > 0 and angle < math.pi, "back view eases in the preferred positive direction")
T.model:GetScript("OnMouseWheel")(T.model, 1)
assert(T.turn:GetScript("OnUpdate"), "wheel zoom does not interrupt rotation")
T.turn:GetScript("OnUpdate")(T.turn, 1)
assert(math.abs(math.abs(angle) - math.pi) < 0.00001, "back view finishes facing away")
click(T.head)
T.turn:GetScript("OnUpdate")(T.turn, 1)
assert(math.abs(angle % (2 * math.pi)) < 0.00001, "another slot restores front view")
click(T.slots.BackSlot)
T.model:GetScript("OnMouseDown")(T.model, "LeftButton")
assert(not T.turn:GetScript("OnUpdate"), "manual rotation takes over immediately")
T.model:GetScript("OnMouseUp")(T.model)
F.ShowTab("tracker")
assert(not T.turn:GetScript("OnUpdate"), "hidden planner stops rotation")
T.model.SetFacing = nil
UnitName = oldName
print("  eased back/front views, independent wheel zoom and manual rotation takeover ok")

-- Set actions preserve identity and collection credit through clear/remove/restore.
UnitName = function() return "PlannerOwner" end
F.ShowTab("tracker"); F.ShowTab("gear")
T.new(); text(T.name, "Workflow actions")
click(T.head); click(T.results[1]); click(T.add)
local actionBuild = T.store().builds[#T.store().builds]
local actionId = actionBuild.goalId
D.progress[actionId][1] = true
click(T.clear)
assert(not next(actionBuild.slots), "clear empties planned items")
click(T.clear)
assert(actionBuild.slots[1] and D.progress[actionId][1], "undo clear restores items and collection credit")
click(T.remove)
assert(not D.active[actionId] and actionBuild.slots[1], "remove untracks without deleting the set")
click(T.add)
assert(D.active[actionId] and actionBuild.goalId == actionId and D.progress[actionId][1], "re-add restores the same goal and credit")
text(T.name, "")
T.name:GetScript("OnEditFocusLost")()
assert(T.name:GetText() == "Workflow actions", "blank rename restores the saved name")
UnitName = oldName
print("  clear undo, remove/re-add and invalid rename preserve set identity and credit")

-- Explicit Hunter import covers all meaningful slots and counts duplicate rings.
local preRaidClass, preRaidFaction = UnitClass, UnitFactionGroup
UnitClass = function() return "Hunter", "HUNTER" end
UnitFactionGroup = function() return "Alliance" end
UnitName = function() return "PreRaidOwner" end
D.characters[F.MaterialsUI.charKey()] = {items = {}}
local imported, importedGoal = F.CreateHunterPreRaidBuild()
assert(imported and importedGoal and D.active[importedGoal.id], "test import saves and adds a Hunter goal")
assert(#importedGoal.steps == 16 and imported.slots[16] == 22314 and not imported.slots[17], "16 item slots with a two-handed melee weapon")
assert(imported.slots[11] == 18500 and imported.slots[12] == 18500, "both non-unique rings are selected")
local ringSteps = {}
for i, step in ipairs(importedGoal.steps) do
    if step.auto.item == 12927 then
        assert(step.text == "Loot Truestrike Shoulders from Pyroguard Emberseer in Upper Blackrock Spire")
        assert(not step.tip, "plain drop sources need no repeated tip")
        assert(F.LinkText(step.text):find("|Hfgtentrance:", 1, true), "dungeon stays clickable")
    elseif step.auto.item == 22340 then
        assert(step.tip and step.tip:find("summon", 1, true), "summoning advice is preserved")
    elseif step.auto.item == 15062 then
        assert(step.text == "Craft Devilsaur Leggings with Leatherworking, or buy it", "crafted gear is not described as a drop")
    end
    if step.auto.item == 18500 then ringSteps[#ringSteps + 1] = i end
end
local preRaidKey = F.MaterialsUI.charKey()
D.characters[preRaidKey] = {items = {[18500] = 1}}
F.RefreshPlannerGoals(importedGoal)
assert(D.progress[importedGoal.id][ringSteps[1]] and not D.progress[importedGoal.id][ringSteps[2]], "one ring cannot credit both planned slots")
D.characters[preRaidKey].items[18500] = 2
F.RefreshPlannerGoals(importedGoal)
assert(D.progress[importedGoal.id][ringSteps[2]], "second ring needs two owned copies")
local importedCount = #T.store().builds
local again = F.CreateHunterPreRaidBuild()
assert(again == imported and #T.store().builds == importedCount, "repeated import reopens without duplicates")
UnitClass, UnitFactionGroup, UnitName = preRaidClass, preRaidFaction, oldName
print("  Hunter pre-raid import: all 16 slots, sources, duplicate ring quantities and idempotence ok")

-- Hover drivers are bounded and respect the existing reduced-motion preference.
F.SetSetting("celebrations", "on")
T.head:GetScript("OnEnter")(T.head)
local wash = T.head.hoverWash
assert(wash and wash:GetScript("OnUpdate"))
local hoverAlpha = 0
wash.SetAlpha = function(_, value) hoverAlpha = value end
wash.GetAlpha = function() return hoverAlpha end
wash:GetScript("OnUpdate")(wash, 0.2)
assert(wash:GetAlpha() == 1 and not wash:GetScript("OnUpdate"))
T.head:GetScript("OnLeave")(T.head)
wash:GetScript("OnUpdate")(wash, 0.2)
assert(wash:GetAlpha() == 0 and not wash:GetScript("OnUpdate"))
F.SetSetting("celebrations", "off")
T.head:GetScript("OnEnter")(T.head)
assert(wash:GetAlpha() == 1 and not wash:GetScript("OnUpdate"))
T.head:GetScript("OnHide")(T.head)
assert(wash:GetAlpha() == 0 and not wash:GetScript("OnUpdate"))
wash.SetAlpha, wash.GetAlpha = nil, nil
F.SetSetting("celebrations", "on")
print("  hover settles, cleans up on hide and respects Celebrations Off")
