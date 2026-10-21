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
-- Open a slot, find an item by id in its picker and click it.
local function Pick(slot, itemId)
    click(T.slots[slot])
    if not T.picker:IsShown() then click(T.replace) end
    text(T.search, "#" .. itemId)
    local list = T.found()
    assert(list[1] and list[1].id == itemId, "item " .. itemId .. " is in the " .. slot .. " database")
    click(T.results[1])
end
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
assert(T.picker:IsShown(), "empty slot opens the picker")
local headList, headCount = T.found()
assert(headCount > 40, "the head database is searchable, not a short list")
for _, entry in ipairs(headList) do assert(entry.sub == 404 or entry.sub == 400, "a level 60 Warrior sees plate heads only") end
for _, entry in ipairs(headList) do assert(entry.inv == 1, "head search shows head items only") end
text(T.search, "helm of might")
assert(T.found()[1].id == 16866, "name search finds the Warrior Tier 1 helm")
click(T.results[1])
assert(not T.picker:IsShown(), "choosing an item closes the picker")
local item = store.builds[1].slots[1]
assert(item == 16866, "Warrior head target saved")
assert(T.head.itemName:GetText() == "Helm of Might", "filled head shows its name")
Pick("HeadSlot", 22418)
assert(store.builds[1].slots[1] == 22418 and store.builds[1].id == id, "id search finds Dreadnaught Helmet")
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

-- Every class can plan its full Tier 3 set: eight armor pieces plus its unique ring, found by class.
local classes = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local names = {"HeadSlot","ShoulderSlot","ChestSlot","HandsSlot","LegsSlot","WaistSlot","WristSlot","FeetSlot"}
local ids = {1,3,5,10,7,6,9,8}
local rings = { WARRIOR = 23059, ROGUE = 23060, PRIEST = 23061, MAGE = 23062, WARLOCK = 23063,
    DRUID = 23064, SHAMAN = 23065, PALADIN = 23066, HUNTER = 23067 }
local oldClass = UnitClass
local tier3 = F.armorCollections.tier3
for _, section in ipairs(tier3.sections) do
    local class = section.name:match("^(.-) %- "):upper()
    UnitClass = function() return class, class end
    F.ShowTab("gear"); T.new(); text(T.name, class .. " full Tier 3")
    local build = T.store().builds[#T.store().builds]
    for i, slot in ipairs(names) do
        local piece = section.pieces[i].auto.item
        Pick(slot, piece)
        assert(build.slots[ids[i]] == piece, "slot selection saves its target")
        assert(not T.picker:IsShown(), "armor selection closes the picker")
        assert(T.head.itemName:GetText() ~= "" or slot == "HeadSlot", "equipping armor preserves head label")
    end
    -- a piece for another class never shows under Usable (the Tier 1 helms are class-locked)
    local other = class == "WARRIOR" and 16854 or 16866
    click(T.slots.HeadSlot); click(T.replace)
    text(T.search, "#" .. other)
    assert(#T.found() == 0, "class-locked pieces stay hidden for other classes")
    Pick("Finger0Slot", rings[class])
    local ring = build.slots[11]
    assert(ring == rings[class])
    Pick("Finger1Slot", rings[class])
    assert(build.slots[12] == ring and not build.slots[11], "unique ring moves instead of duplicating")
    click(T.slots.ShoulderSlot); click(T.unequip)
    assert(not build.slots[3] and build.slots[1] and build.slots[5], "unequip only clears chosen slot")
end
UnitClass = oldClass
F.ShowTab("tracker")
print("  all nine classes: full Tier 3 by id, class-locked pieces hidden, independent targets and unique ring placement ok")

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
Pick("HeadSlot", 16866)
click(T.head); click(T.replace); text(T.search, "#16866")
assert(T.head.chosen and T.results[1].chosen, "the planned item is marked when the picker reopens")
T.clickAway:GetScript("OnEvent")()
local key = F.MaterialsUI.charKey()
local foreign = "Foreign-" .. GetRealmName()
local previousOwner, previousForeign = D.characters[key], D.characters[foreign]
D.characters[key] = {items = {}}
D.characters[foreign] = {items = {[16866] = 1}}
local catalogueCount = F.CatalogGoalCount()
click(T.add)
assert(build.tracked and D.active[build.goalId] and (SelectedRowState() or ""):find("^In My Goals"), "explicit add lists and activates a stable goal")
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
Pick("ShoulderSlot", 16868)
D.progress[goalId][2] = true
click(T.head)
local tooltipCalls = 0
local oldTip = GameTooltip.SetHyperlink
GameTooltip.SetHyperlink = function() tooltipCalls = tooltipCalls + 1 end
T.head:GetScript("OnEnter")(T.head)
assert(tooltipCalls == 0, "active slot tooltip cannot cover its action menu")
GameTooltip.SetHyperlink = oldTip
click(T.replace); text(T.search, "#22418"); click(T.results[1])
assert(not D.progress[goalId][1] and D.progress[goalId][2], "replacing head clears only head credit")
click(T.head); click(T.unequip)
assert(#goal.steps == 1 and D.progress[goalId][1], "removing an earlier slot moves shoulder credit with its item")
Pick("HeadSlot", 22418)
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
click(T.head); click(T.replace); text(T.search, "#16866"); click(T.results[1]); Pick("HeadSlot", 22418)
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
Pick("HeadSlot", 16866); click(T.add)
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
        assert(step.tip and step.tip:lower():find("summon", 1, true), "summoning advice is preserved")
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

-- ------------------------------------------------------------
-- Item database
-- ------------------------------------------------------------
local Cat = F.GearCatalog
assert(Cat and F.GEARDB and F.GEARDB.builds.forever, "database and catalogue load")
-- Every item the Library already tracks for sets is in the database, in a slot that fits.
local missing = 0
for _, parent in pairs(F.armorCollections) do
    for _, section in ipairs(parent.sections) do
        for _, piece in ipairs(section.pieces) do
            local id = type(piece.auto.item) == "table" and piece.auto.item[1] or piece.auto.item
            if id and not Cat.Get(id) then missing = missing + 1 end
        end
    end
end
assert(missing == 0, missing .. " Library set pieces are missing from the database")
for slot, id in pairs(Cat.PRESETS.hunter_preraid_wowhead.slots) do
    local item = Cat.Get(id)
    assert(item, "preset item " .. id .. " exists")
    local fits = false
    for _, inv in ipairs(Cat.SLOT_INV[Cat.SLOT_NAMES[slot]]) do if inv == item.inv then fits = true end end
    assert(fits, item.name .. " fits its preset slot")
end
-- Items are found without parsing a slot, and parse to the same record afterwards.
local direct = Cat.Get(16866)
assert(direct and direct.name == "Helm of Might" and direct.q == 4 and direct.mask == 1 and direct.inv == 1, "single lookup")
assert(Cat.Get(99999999) == nil and Cat.Get("x") == nil, "unknown ids return nothing")
local both = Cat.Search("HeadSlot", { text = "helm of might" })
assert(both[1] == direct, "search and lookup share one record")
Cat.Release({ 16866 })
assert(Cat.Search("HeadSlot", { text = "helm of might" })[1] == direct, "planned items stay known across a release")
Cat.Release()
local reparsed = Cat.Search("HeadSlot", { text = "helm of might" })[1]
assert(reparsed ~= direct and reparsed.id == 16866 and reparsed.name == "Helm of Might", "a full release rebuilds records on demand")
print("  database: every Library set piece present, preset slots fit, lookup and release ok")

-- Eligibility by class, faction, hands and armor type.
local function ids(list) local out = {} for _, item in ipairs(list) do out[item.id] = true end return out end
local usable = { usable = true, class = "MAGE", faction = "Alliance" }
local mageHead = ids(Cat.Search("HeadSlot", usable))
assert(mageHead[16795] and not mageHead[22418] and not mageHead[16866], "mage sees cloth and own set only")
usable.class = "WARRIOR"
local warHead = ids(Cat.Search("HeadSlot", usable))
assert(warHead[16866] and warHead[22418] and not warHead[16795], "warrior sees plate and own set only")
usable.class = "ROGUE"
local rogueOff = Cat.Search("SecondaryHandSlot", usable)
local sawWeapon, sawShield = false, false
for _, item in ipairs(rogueOff) do
    if item.inv == 13 then sawWeapon = true end
    if item.inv == 14 then sawShield = true end
end
assert(sawWeapon and not sawShield, "rogue dual wields and never carries a shield")
usable.class = "PRIEST"
for _, item in ipairs(Cat.Search("SecondaryHandSlot", usable)) do assert(item.inv == 23, "priest off hand is held items only") end
usable.class = "PALADIN"
local palOff = Cat.Search("SecondaryHandSlot", usable)
local palShield = false
for _, item in ipairs(palOff) do if item.inv == 14 then palShield = true end; assert(item.inv ~= 13, "paladin cannot dual wield") end
assert(palShield, "paladin carries shields")
for _, item in ipairs(Cat.Search("RangedSlot", usable)) do assert(item.sub == 407, "paladin ranged slot is librams") end
usable.class = "DRUID"
for _, item in ipairs(Cat.Search("RangedSlot", usable)) do assert(item.sub == 408, "druid ranged slot is idols") end
usable.class = "HUNTER"
for _, item in ipairs(Cat.Search("MainHandSlot", usable)) do assert(item.sub ~= 204 and item.sub ~= 205, "hunters use no maces") end
usable.class = "WARRIOR"
local allow, hordeSeesAlliance = Cat.Search("HeadSlot", { usable = true, class = "WARRIOR", faction = "Horde", text = "field marshal" }), false
for _, item in ipairs(allow) do hordeSeesAlliance = true end
assert(not hordeSeesAlliance, "Horde never sees Alliance PvP gear")
assert(#Cat.Search("HeadSlot", { usable = true, class = "WARRIOR", faction = "Alliance", text = "field marshal" }) > 0, "Alliance does")
-- Cloaks fit every class, whatever their cloth label says.
for _, class in ipairs(classes) do
    assert(#Cat.Search("BackSlot", { usable = true, class = class, faction = "Alliance" }) > 50, class .. " has cloaks")
end
print("  eligibility: armor type, weapon skills, dual wield, shields, relics, faction and cloaks ok")

-- Search: names, sets, ids, quality, sort and the Forever filter.
local epic = Cat.Search("ChestSlot", { minQuality = 4, class = "WARRIOR" })
for _, item in ipairs(epic) do assert(item.q >= 4, "quality floor holds") end
assert(#Cat.Search("ChestSlot", { class = "WARRIOR" }) > #epic, "lower quality adds results")
local byLevel = Cat.Search("HeadSlot", { sort = "ilvl" })
for i = 2, #byLevel do assert(byLevel[i - 1].ilvl >= byLevel[i].ilvl, "item level sort") end
local byName = Cat.Search("HeadSlot", { sort = "name" })
for i = 2, #byName do assert(byName[i - 1].name <= byName[i].name, "name sort") end
assert(#Cat.Search("HeadSlot", { text = "cryptstalker" }) > 0, "partial name")
assert(#Cat.Search("HeadSlot", { text = "dreadnaught helmet" }) == 1, "every word must match")
assert(#Cat.Search("HeadSlot", { text = "zzzzqqq" }) == 0, "no match")
local viaSet = Cat.Search("ChestSlot", { text = "giantstalker armor" })
assert(#viaSet > 0, "set names are searchable")
assert(Cat.Search("HeadSlot", { text = "item:22418" })[1].id == 22418, "item link text finds the item")
assert(#Cat.Search("FeetSlot", { text = "#16866" }) == 0, "slot filter wins over id")
for _, item in ipairs(Cat.Search("HeadSlot", { revealedOnly = true })) do assert(item.forever ~= 0, "revealed filter") end
print("  search: tokens, set names, ids, quality, sort and revealed filter ok")

-- Sources: hand-checked, from the Library, from the game's own requirements, or honestly unknown.
local garr = Cat.Get(16866)
local text1, advice1 = Cat.Acquisition(garr)
assert(text1:find("Loot Helm of Might from Garr in ", 1, true) and text1:find("|Hfgtentrance:mc|h", 1, true), "Tier 1 helm: Garr, Molten Core pin")
assert(Cat.SourceLabel(garr) == "Garr · Molten Core", "short label")
local nef = Cat.Get(16963) -- Helm of Wrath, Onyxia
assert(Cat.Acquisition(nef):find("|Hfgtentrance:ony|h", 1, true), "Onyxia's Lair pin")
local quest = Cat.Acquisition(Cat.Get(21999))
assert(quest:find("Complete 'Saving the Best for Last' for Helm of Heroism", 1, true), "quest rewards say so")
local plain = Cat.Acquisition(Cat.Get(15062))
assert(plain == "Craft Devilsaur Leggings with Leatherworking, or buy it", "crafted item")
local pvp = Cat.Get(16465)
assert(pvp and pvp.note and pvp.note:find("PvP rank 13", 1, true), "PvP rank requirement comes from the game's table")
assert(select(1, Cat.Acquisition(pvp)) == "Earn Field Marshal's Chain Helm at PvP rank 13", "PvP source text")
local anyUnknown
for _, item in ipairs(Cat.Search("NeckSlot", {})) do
    if not Cat.Source(item) and not item.note then anyUnknown = item; break end
end
assert(anyUnknown and Cat.Acquisition(anyUnknown):find("(Source unknown)", 1, true), "missing sources are called unknown")
assert(Cat.EntranceFor("Upper Blackrock Spire").id == "dungeon:brs" and Cat.EntranceFor("Molten Core").id == "dungeon:mc", "entrances resolve from place names")
assert(Cat.EntranceFor("Nowhere in particular") == nil)
print("  sources: boss pins, quests, crafted items, PvP ranks and honest unknowns ok")

-- Picker: filters persist, the list recycles a few rows over thousands of items, scrolling rebinds them.
UnitName = function() return "ListOwner" end
UnitClass = function() return "Warrior", "WARRIOR" end
F.ShowTab("gear"); T.new(); text(T.name, "List test")
click(T.head)
text(T.search, "")
local list, total = T.found()
assert(total > 40 and #T.results < total, "few rows for many items")
assert(T.results[1].item == list[1] and T.results[2].item == list[2], "rows start at the top of the list")
local scrolled = 20 * 46 + 5
T.list.scroll.GetVerticalScroll = function() return scrolled end
T.list:Update()
assert(T.results[1].item == list[21], "scrolling rebinds the same rows to later items")
T.list.scroll.GetVerticalScroll = nil
click(T.filters.quality)
local _, rare = T.found()
assert(rare < total and F.Setting and T.store and true, "quality filter narrows the list")
click(T.filters.quality); click(T.filters.quality)
assert(select(2, T.found()) == total, "quality cycles back to all")
click(T.filters.usable)
assert(select(2, T.found()) > total, "turning Usable off shows everything")
click(T.filters.usable)
click(T.filters.sort)
local byname = T.found()
assert(byname[1].name <= byname[2].name, "sort button cycles to name")
click(T.filters.sort); click(T.filters.sort)
assert(D.gearPlanner.prefs.usable == true and D.gearPlanner.prefs.sort == "ilvl", "filter choices persist in the saved data")
Pick("HeadSlot", 22418)
T.list.scroll.GetVerticalScroll = function() return scrolled end
click(T.slots.HeadSlot)
T.list.scroll.GetVerticalScroll = nil
F.ShowTab("tracker")
print("  picker: recycled rows, scroll rebinding, quality/usable/sort filters and persistence ok")

-- Set actions: fill from equipped, duplicate, view, delete.
F.ShowTab("gear")
local actions = T.store()
local equipped = { [1] = 16866, [5] = 16865, [99] = 1 }
local oldGet = GetInventoryItemID
GetInventoryItemID = function(_, slot) return equipped[slot] end
T.new(); text(T.name, "Fill test")
local filled = actions.builds[#actions.builds]
click(T.fill)
assert(filled.slots[1] == 16866 and filled.slots[5] == 16865 and not filled.slots[2], "fill copies only equipped items the database knows")
GetInventoryItemID = oldGet
click(T.duplicate)
local copy = actions.builds[#actions.builds]
assert(copy ~= filled and copy.name == "Fill test copy" and copy.slots[1] == 16866 and copy.id ~= filled.id, "duplicate makes an independent draft")
copy.slots[1] = nil
assert(filled.slots[1] == 16866, "editing the copy leaves the original")
local buildCount = #actions.builds
click(T.delete)
assert(#actions.builds == buildCount, "delete asks again before removing")
click(T.delete)
assert(#actions.builds == buildCount - 1, "second click deletes the set")
T.new(); text(T.name, "View test")
Pick("HeadSlot", 16866); click(T.add)
local trackedBuild = actions.builds[#actions.builds]
assert(trackedBuild.name == "View test")
local trackedGoal = trackedBuild.goalId
assert(D.active[trackedGoal], "added")
local shown
local oldShowTab, oldSelect = F.ShowTab, F.SelectGoal
F.SelectGoal = function(id) shown = id end
click(T.viewGoal)
assert(shown == trackedGoal, "View in Goals opens the goal")
F.SelectGoal = oldSelect
F.ShowTab("gear")
click(T.delete); click(T.delete)
assert(not D.active[trackedGoal] and not D.progress[trackedGoal], "deleting a tracked set removes its goal and progress")
UnitName = oldName
F.ShowTab("tracker")
print("  fill from equipped, duplicate, view in goals and confirmed delete ok")

-- Typing a name does not rebuild the goals list on every letter.
local refreshes = 0
local oldRefresh = F.RefreshPlannerGoals
local oldAfter = C_Timer.After
local queued = {}
C_Timer.After = function(_, fn) queued[#queued + 1] = fn end
F.RefreshPlannerGoals = function(...) refreshes = refreshes + 1; return oldRefresh(...) end
UnitName = function() return "TypingOwner" end
F.ShowTab("gear"); T.new(); text(T.name, "Typed")
click(T.slots.HeadSlot); text(T.search, "#16866"); click(T.results[1]); click(T.add)
local base = refreshes
for _, word in ipairs({ "Typed s", "Typed se", "Typed set" }) do text(T.name, word) end
assert(refreshes == base and #queued >= 1, "renaming queues one goal refresh instead of one per letter")
for _, fn in ipairs(queued) do fn() end
assert(refreshes == base + 1, "the queued refresh runs once")
local renamed = T.store().builds[#T.store().builds]
assert(F.GoalById(renamed.goalId).name == "Typed set", "goal name follows immediately")
C_Timer.After, F.RefreshPlannerGoals = oldAfter, oldRefresh
UnitName = oldName
F.ShowTab("tracker")
print("  renaming a tracked set debounces the goals refresh")

-- Whole sets, jumping between the planner and the goal page, and Enter to pick.
local drag = Cat.Get(16939)
assert(drag and drag.set > 0 and Cat.SetName(drag.set) == "Dragonstalker Armor", "Dragonstalker's helm belongs to its set")
local dragSet = Cat.SetItems(drag.set)
assert(#dragSet == 8, "Dragonstalker has eight pieces, found " .. #dragSet)
local taken = {}
for _, piece in ipairs(dragSet) do
    local slot = Cat.SlotFor(piece, taken)
    assert(slot and not taken[slot], piece.name .. " gets its own slot"); taken[slot] = true
end
assert(Cat.SlotFor(Cat.Get(18500), { [11] = true }) == 12 and Cat.SlotFor(Cat.Get(18500), {}) == 11, "second ring takes the second finger")
assert(Cat.SlotFor(Cat.Get(22314), {}) == 16 and Cat.SlotFor(Cat.Get(13965), { [13] = true }) == 14, "weapons and trinkets")
UnitName = function() return "SetOwner" end
UnitClass = function() return "Hunter", "HUNTER" end
F.ShowTab("gear"); T.new(); text(T.name, "Dragonstalker plan")
local setBuild = T.store().builds[#T.store().builds]
click(T.slots.HeadSlot)
text(T.search, "dragonstalker's helm")
assert(T.results[1].item.id == 16939, "set piece found")
click(T.results[1].setBtn)
local count = 0
for _ in pairs(setBuild.slots) do count = count + 1 end
assert(count == 8 and setBuild.slots[1] == 16939, "one click plans all eight pieces")
assert(not T.picker:IsShown(), "adding a set closes the picker")
-- Enter takes the first result for the open slot
click(T.slots.NeckSlot)
text(T.search, "")
local firstNeck = T.found()[1]
T.search:GetScript("OnEnterPressed")(T.search)
assert(setBuild.slots[2] == firstNeck.id, "Enter plans the top result")
-- A planner goal's pencil opens its set, only for the owning character.
click(T.add)
local setGoal = F.GoalById(setBuild.goalId)
Track(F.detailEditBtn)
F.UpdateEditButton(setGoal)
assert(F.detailEditBtn:IsShown(), "gear set goals get an edit button on their owner")
F.ShowTab("tracker")
assert(F.OpenGearSet(setGoal) == true and F.GearPlanner:IsShown(), "opens the planner on that set")
assert(T.setTitle:GetText() == "Dragonstalker plan", "and selects it")
UnitName = function() return "SomeoneElse" end
F.UpdateEditButton(setGoal)
assert(not F.detailEditBtn:IsShown() and F.OpenGearSet(setGoal) == false, "other characters cannot open it")
F.UpdateEditButton(F.GoalById("raid_mc"))
assert(not F.detailEditBtn:IsShown(), "ordinary goals are unaffected")
UnitName = oldName
UnitClass = oldClass
F.ShowTab("tracker")
print("  whole sets, slot assignment, Enter to pick and the goal-page edit button ok")

-- Armor type follows the class (and level 40 for mail and plate); cloaks stay open to all.
local function subs(list) local out = {} for _, item in ipairs(list) do out[item.sub] = true end return out end
local hunter60 = subs(Cat.Search("ChestSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 60 }))
assert(hunter60[403] and not hunter60[402] and not hunter60[401], "a level 60 Hunter sees mail chests only")
local hunter30 = subs(Cat.Search("ChestSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 30 }))
assert(hunter30[402] and not hunter30[403], "before 40 a Hunter sees leather")
local warrior30 = subs(Cat.Search("LegsSlot", { usable = true, class = "WARRIOR", faction = "Alliance", level = 30 }))
assert(warrior30[403] and not warrior30[404], "before 40 a Warrior sees mail")
local druid = subs(Cat.Search("HandsSlot", { usable = true, class = "DRUID", faction = "Alliance" }))
assert(druid[402] and not druid[401], "Druids see leather, not cloth")
assert(#Cat.Search("BackSlot", { usable = true, class = "WARRIOR", faction = "Alliance" }) > 50, "cloaks are for everyone")
local allChests = subs(Cat.Search("ChestSlot", { usable = false, class = "HUNTER" }))
assert(allChests[401] and allChests[402] and allChests[403] and allChests[404], "Usable off shows every armor type")
print("  armor type by class and level, cloaks for all, Usable off shows everything")

-- Only the thumbnail opens the item tooltip; the row itself just highlights.
UnitName = function() return "TipOwner" end
F.ShowTab("gear"); T.new(); text(T.name, "Tip test")
click(T.head)
local shown = 0
local oldTip = F.ShowItemTip
F.ShowItemTip = function(_, _, _, _, _, _, place) shown = shown + 1; assert(place, "the tooltip is placed beside the picker") end
T.results[1]:GetScript("OnEnter")(T.results[1])
assert(shown == 0, "hovering the row does not open the tooltip")
T.results[1].thumb:GetScript("OnEnter")(T.results[1].thumb)
assert(shown == 1, "hovering the thumbnail does")
F.ShowItemTip = oldTip
local before = T.store().builds[#T.store().builds].slots[1]
T.results[1].thumb:GetScript("OnMouseUp")(T.results[1].thumb, "LeftButton")
assert(T.store().builds[#T.store().builds].slots[1] and not T.picker:IsShown(), "clicking the thumbnail plans the item too")
UnitName = oldName
F.ShowTab("tracker")
print("  thumbnail-only tooltips beside the picker; thumbnail clicks plan the item")
