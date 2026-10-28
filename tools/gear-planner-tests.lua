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
Track(F.GearPlanner); Track(F.libraryPanel); Track(T.picker); Track(T.filters.showAll); Track(T.filters.kind)
-- Pick a dropdown choice by its value, the way a player clicks it in the popup.
local function Choose(drop, value)
    drop:GetScript("OnClick")(drop)
    for i = 1, #drop.choices do
        local row = T.filters.rows[i]
        if row.value == value then row:GetScript("OnClick")(row); return end
    end
    error("no choice " .. tostring(value))
end
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
assert(headCount == 25 and T.filters.showAll:IsShown(), "an unsearched slot starts with its best 25")
T.filters.showAll:GetScript("OnClick")(T.filters.showAll)
headList, headCount = T.found()
assert(headCount > 40 and not T.filters.showAll:IsShown(), "Show all reaches the whole head database")
local sawPlate, sawLighter = false, false
for _, entry in ipairs(headList) do
    assert(entry.sub >= 400 and entry.sub <= 404, "a level 60 Warrior sees the armor it can wear")
    if entry.sub == 404 then sawPlate = true elseif entry.sub < 404 then sawLighter = true end
end
assert(sawPlate and sawLighter, "lighter armor stays plannable when plate is wearable")
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
-- The goal pages' weather on the racial backdrops: every race gets its own particles, no lights;
-- the setting (Full / Subtle / Off) and the planner closing stop them.
do
    local PE = F.PlannerEffects
    assert(PE and PE.engine and PE.driver, "planner effects are built")
    local visible, setting = true, nil
    T.modelArea.IsVisible = function() return visible end
    local art = T.background.texture
    art.GetWidth, art.GetHeight = function() return 1000 end, function() return 1204 end
    local oldSetting = F.Setting
    F.Setting = function(key) if key == "imageEffects" then return setting end return oldSetting(key) end
    for _, race in ipairs({ "Dwarf", "Gnome", "NightElf", "Scourge", "Orc", "Tauren", "Troll", "Human" }) do
        setting = nil
        T.background.race = nil
        T.background:SetRace(race)
        PE.Refresh()
        local tick = PE.driver:GetScript("OnUpdate")
        assert(tick, race .. " plays its effects")
        tick(PE.driver, 0.016)
        -- the field builds up over a few seconds, each particle fading in where it starts
        local waiting = 0
        for _, e in ipairs(PE.engine.emberDots) do if e.wait then waiting = waiting + 1 end end
        assert(PE.engine.emberCount == 0 or waiting > PE.engine.emberCount * 0.8, race .. " does not start with a full field")
        for _ = 1, 400 do tick(PE.driver, 0.016) end -- (about 6 s)
        -- (the troll, the tauren and the human have only the clouds and leaves, no particles of their own)
        local bare = race == "Troll" or race == "Tauren" or race == "Human"
        assert(bare and PE.engine.emberCount == 0 or not bare and PE.engine.emberCount > 0, race .. " has its own particles or none")
        assert(PE.engine.shaftCount == 0, race .. " has no lights, only weather")
        setting = "subtle"; PE.Refresh()
        assert(not PE.driver:GetScript("OnUpdate") and PE.engine.emberCount == 0, race .. " stops its particles on Subtle")
        setting = "off"; PE.Refresh()
        assert(not PE.driver:GetScript("OnUpdate"), race .. " stops on Off")
        setting = nil; PE.Refresh()
        assert(PE.driver:GetScript("OnUpdate"), race .. " plays again on Full")
        visible = false; PE.Refresh()
        assert(not PE.driver:GetScript("OnUpdate"), race .. " stops with the planner closed")
        local kept = PE.engine.emberCount
        visible = true; PE.Refresh()
        assert(PE.engine.emberCount == kept, race .. " keeps its particles while the planner is closed")
    end
    F.Setting = oldSetting
    T.modelArea.IsVisible, art.GetWidth, art.GetHeight = nil, nil, nil
    T.background.race = nil
    T.background:SetRace("Orc")
end
-- The gallery scene's Dwarf keeps the logged-in Dwarf's own look; any other race still gets the game's default.
do
    local calls = 0
    T.model.SetCustomRace = function() calls = calls + 1 end
    local oldRace, oldSex = UnitRace, UnitSex
    UnitRace = function() return "Dwarf", "Dwarf" end
    UnitSex = function() return 2 end
    local spec = { key = "Demo Look-Demo", name = "Thurgrim", class = "ROGUE", race = "Dwarf", faction = "Alliance",
        level = 60, sex = 2, preset = "rogue_preraid_wowhead" }
    spec.ownLook = true
    F.GearPlannerDemo(spec); F.GearPlannerDemoOff()
    assert(calls == 0, "an own-look Dwarf keeps the player's model")
    spec.ownLook = nil
    F.GearPlannerDemo(spec); F.GearPlannerDemoOff()
    assert(calls > 0, "without own look the game's default Dwarf is used")
    calls = 0
    spec.ownLook, spec.race = true, "Human"
    F.GearPlannerDemo(spec); F.GearPlannerDemoOff()
    assert(calls > 0, "another race never keeps the player's model")
    T.model.SetCustomRace, UnitRace, UnitSex = nil, oldRace, oldSex
    F.ShowTab("tracker") -- (the demo opened the planner; leave it as it was found)
end
-- The character picker's menu opens inside the drawer (which clips what runs past its edge).
do
    local width
    local setSize = T.charMenu.SetSize
    T.charMenu.SetSize = function(self, w, h) width = w; if setSize then setSize(self, w, h) end end
    T.ownerButton:GetScript("OnClick")(T.ownerButton)
    T.charMenu.SetSize = setSize
    assert(width and width + 12 <= T.drawer.width, "the character menu fits inside the drawer")
    T.charMenu:Hide()
end
-- The game's sheathe key toggles the character's weapons while the planner is open, and only then.
do
    local bound, sheathed = {}, nil
    SetOverrideBindingClick = function(_, _, key, button) bound[#bound + 1] = key .. ">" .. button end
    ClearOverrideBindings = function() bound = {} end
    GetBindingKey = function(action) assert(action == "TOGGLESHEATH"); return "Z", "SHIFT-Z" end
    T.model.SetSheathed = function(_, value) sheathed = value end
    F.ShowTab("gear")
    assert(#bound == 2 and bound[1] == "Z>FGTGearPlannerSheath" and bound[2] == "SHIFT-Z>FGTGearPlannerSheath",
        "both sheathe keys open the planner's sheathe button")
    click(T.sheathButton)
    assert(sheathed == true and D.gearPlanner.prefs.sheathed == true, "the key sheathes the weapons and the choice is kept")
    T.model.SetSheathed = function(_, value) sheathed = value end
    T.sheathButton:GetScript("OnClick")(T.sheathButton)
    assert(sheathed == false and D.gearPlanner.prefs.sheathed == nil, "the key draws them again")
    D.gearPlanner.prefs.sheathed = true
    T.model:GetScript("OnModelLoaded")()
    assert(sheathed == true, "a repaint keeps the weapons sheathed")
    D.gearPlanner.prefs.sheathed = nil
    GetBindingKey = function() return nil end
    T.bindSheath()
    assert(#bound == 0, "a sheathe key the player has unbound is not taken over")
    GetBindingKey = function() return "Z" end
    T.bindSheath()
    assert(#bound == 1, "bound again once the key is back")
    F.ShowTab("tracker")
    assert(#bound == 0, "the key is the game's again once the planner closes")
    SetOverrideBindingClick, ClearOverrideBindings, GetBindingKey, T.model.SetSheathed = nil, nil, nil, nil
end
-- Wide and tall windows preserve background proportions without shrinking the model drawing area.
T.model.SetSize = function() error("resizing must not reintroduce an interior model clipping frame") end
for _, size in ipairs({ {800, 400}, {400, 650} }) do
    local width, height
    T.background.texture.SetSize = function(_, w, h) width, height = w, h end
    T.modelArea:GetScript("OnSizeChanged")(T.modelArea, size[1], size[2])
    assert(math.abs(width / height - 318/383) < 0.0001, "background keeps portrait aspect")
    assert(width >= size[1] and height >= size[2], "background covers wide and tall panels")
end
-- The orc's rock and the night elf's path stay under the character's feet at every width,
-- without uncovering the panel.
do
    local oldRace, top, frozen = T.background.race, nil, T.model.frozenW
    T.model.frozenW = nil -- (the width held while the drawer slides)
    T.background.texture.SetPoint = function(_, _, _, _, _, y) top = y end
    for raceFile, ground in pairs({ Orc = 0.70, NightElf = 0.77, Dwarf = 0.69, Scourge = 0.77, Tauren = 0.64 }) do
        T.background.race = raceFile
        for _, size in ipairs({ {1225, 745}, {825, 720}, {800, 400}, {400, 650} }) do
            local w, h = size[1], size[2]
            local imageH = 383 * math.max(w / 318, h / 383)
            T.modelArea:GetScript("OnSizeChanged")(T.modelArea, w, h)
            assert(top >= 0 and top <= imageH - h + 0.001, raceFile .. " backdrop still covers the panel")
            if imageH - h > 200 then
                -- (narrower windows bring the camera closer, so the feet sit lower)
                local feetLine = 0.78 + 0.157 * (1 / math.max(1, w / h / 0.85) - 1 / 1.93)
                assert(math.abs(imageH * ground - top - h * feetLine) < 0.001, raceFile .. " ground sits at the character's feet " .. w .. "x" .. h)
            end
        end
    end
    T.background.race = "Human"
    T.modelArea:GetScript("OnSizeChanged")(T.modelArea, 800, 400)
    assert(math.abs(top - (800 / 318 * 383 - 400) * 0.5) < 0.001, "other backdrops still crop evenly")
    T.background.race, T.model.frozenW = oldRace, frozen
    T.background.texture.SetPoint = nil
end
T.model.SetSize = nil
T.background.texture.SetSize = nil
do
    local selected
    T.background.race = nil
    T.background.texture.SetTexture = function(_, path) selected = path end
    for _, raceFile in ipairs({"Human", "Dwarf", "Gnome", "NightElf", "Orc", "Tauren", "Troll", "Scourge"}) do
        T.background:SetRace(raceFile)
        assert(selected == "Interface\\AddOns\\ForeverGoalTracker\\Media\\dressing-room\\" .. raceFile,
            "race selects its installed backdrop")
    end
    T.background:SetRace("UnknownRace")
    assert(T.background.race == "Orc", "unknown race has a supported fallback")
    T.background.texture.SetTexture = nil
end
print("  wide/tall preview keeps native background proportions and full-panel model drawing")
-- Wheel zoom uses the same safe portrait limit as head focus.
local portraitZoom
T.model.SetPortraitZoom = function(_, value) portraitZoom = value end
-- (the wheel glides: run frames until the camera settles)
local function SettleCamera()
    for _ = 1, 300 do
        local f = T.camera:GetScript("OnUpdate")
        if not f then return end
        f(T.camera, 0.05)
    end
    error("the camera never settled")
end
T.model:GetScript("OnMouseWheel")(T.model, 100)
SettleCamera()
assert(math.abs(portraitZoom - 0.8) < 1e-9, "wheel zoom reaches native portrait limit")
local shadowShown, shadowAlpha
T.modelArea.GetWidth = function() return 1225 end
T.modelArea.GetHeight = function() return 745 end
T.background.shadow.SetShown = function(_, shown) shadowShown = shown end
T.background.shadow.SetAlpha = function(_, a) shadowAlpha = a end
T.background.PaintLight()
assert(shadowShown == false, "feet shadow fades out once zoomed in")
T.model:GetScript("OnMouseWheel")(T.model, -100)
SettleCamera()
assert(math.abs(portraitZoom) < 1e-9, "wheel zoom returns to full-character view")
assert(shadowShown and shadowAlpha > 0.5, "feet shadow grounds the full-character view")
do
    -- pulled all the way back the orc's feet reach 69.5% (the 0.78 line less the shadow's rise), and its rock rises with them
    local oldRace, top = T.background.race, nil
    T.background.race = "Orc"
    T.background.texture.SetPoint = function(_, _, _, _, _, y) top = y end
    local frozen = T.model.frozenW
    T.model.frozenW = nil
    T.modelArea:GetScript("OnSizeChanged")(T.modelArea, 1225, 745)
    local imageH = 383 * math.max(1225 / 318, 745 / 383)
    local shift = 0.157 * (1 / math.max(1, 1225 / 745 / 0.85) - 1 / 1.93)
    assert(math.abs(imageH * 0.70 - top - 745 * (0.695 + shift)) < 0.001, "orc ground follows the feet when zoomed out")
    T.background.race, T.background.texture.SetPoint, T.model.frozenW = oldRace, nil, frozen
end
T.modelArea.GetWidth, T.modelArea.GetHeight = nil, nil
T.background.shadow.SetShown, T.background.shadow.SetAlpha = nil, nil
T.model.SetPortraitZoom = nil

click(T.head)
assert(T.picker:IsShown())
T.clickAway:GetScript("OnEvent")()
assert(not T.picker:IsShown(), "outside click closes picker")
local count = 0
for _ in pairs(T.slots) do count = count + 1 end
assert(count == 21, "armor, accessory, weapon, quiver and ammo placeholders are present")

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
assert(not build.tracked and not build.goalId and SelectedRowState() == "Empty", "named drafts list without tracking a goal")
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
assert(build.tracked and D.active[build.goalId] and (SelectedRowState() or ""):find("In My Goals", 1, true), "explicit add lists and activates a stable goal")
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
-- choosing a slot leaves the camera where the player put it (no slot zoom since 2026-10-24)
do
    local settle = T.camera:GetScript("OnUpdate"); if settle then settle(T.camera, 1) end
    settle = T.turn:GetScript("OnUpdate"); if settle then settle(T.turn, 1) end
    local moved = false
    T.model.SetPosition = function() moved = true end
    for _, slot in ipairs({"HeadSlot", "ShoulderSlot", "HandsSlot", "WristSlot", "FeetSlot", "BackSlot"}) do
        click(T.slots[slot])
        assert(not T.camera:GetScript("OnUpdate") and not T.turn:GetScript("OnUpdate"), "a slot neither zooms nor turns the character")
        T.clickAway:GetScript("OnEvent")()
    end
    assert(not moved, "the character stays put")
    T.model.SetPosition = nil
end
D.plannerPolishSmoke = { goalId = goalId, key = key, buildId = build.id }
D.characters[key], D.characters[foreign] = previousOwner, previousForeign
UnitName = oldName
F.ShowTab("tracker")
print("  explicit add, Library exclusion, character scope, replacement credit, tooltip suppression and camera settling ok")

-- Gear swaps are delayed until the fade, coalesced, and independent of camera alpha.
local oldRace, oldSex = UnitRace, UnitSex
UnitName = function() return "PlannerOwner" end
F.ShowTab("gear")
T.model:GetScript("OnMouseWheel")(T.model, 1) -- a camera move under way during the fade
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
print("  independent gear fades ok")

-- Another set faces the character front again; dragging takes over a turn at once.
UnitName = function() return "PlannerOwner" end
F.ShowTab("gear")
local angle
T.model.SetFacing = function(_, value) angle = value end
T.new()
T.turn:GetScript("OnUpdate")(T.turn, 0.2)
T.model:GetScript("OnMouseWheel")(T.model, 1)
assert(T.turn:GetScript("OnUpdate"), "wheel zoom does not interrupt the turn")
T.model:GetScript("OnMouseDown")(T.model, "LeftButton")
assert(not T.turn:GetScript("OnUpdate"), "manual rotation takes over immediately")
T.model:GetScript("OnMouseUp")(T.model)
F.ShowTab("tracker")
assert(not T.turn:GetScript("OnUpdate"), "hidden planner stops rotation")
T.model.SetFacing = nil
UnitName = oldName
print("  front view on another set, independent wheel zoom and manual rotation takeover ok")

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
for presetId, preset in pairs(Cat.PRESETS) do
    for slot, id in pairs(preset.slots) do
        local item = Cat.Get(id)
        assert(item, presetId .. " item " .. id .. " exists")
        local fits = false
        for _, inv in ipairs(Cat.SLOT_INV[Cat.SLOT_NAMES[slot]]) do if inv == item.inv then fits = true end end
        assert(fits, item.name .. " fits its slot in " .. presetId)
        assert(Cat.Usable(item, preset.class, Cat.SLOT_NAMES[slot], "Alliance", 60), item.name .. " is usable by a level 60 " .. preset.class .. " in " .. presetId)
    end
end
assert(Cat.PRESETS.rogue_preraid_wowhead.slots[16] == 12590 and Cat.PRESETS.rogue_preraid_wowhead.slots[17] == 12783, "the Rogue set dual wields Felstriker and Heartseeker")
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

-- Imported sources (GearSources.lua): bosses with their instance, world drops, quartermasters.
local coif = Cat.Get(19875)
assert(Cat.SourceLabel(coif) == "Jin'do the Hexxer · Zul'Gurub", "imported boss and raid")
assert(select(1, Cat.Acquisition(coif)) == "Loot Bloodstained Coif from Jin'do the Hexxer in Zul'Gurub", "imported boss step")
assert(Cat.EntranceFor(Cat.Source(coif).place).id == "hub:raid_zg", "imported raid gets a map pin")
assert(Cat.SourceLabel(Cat.Get(22718)) == "Bosses · Zul'Gurub", "several bosses in one raid")
assert(Cat.SourceLabel(Cat.Get(2244)) == "World drop" and Cat.Source(Cat.Get(2244)).place == nil, "world drops have no pin")
local insignia = Cat.Get(18443)
local _, insigniaTip = Cat.Acquisition(insignia)
assert(Cat.SourceLabel(insignia) == "PvP rank 4" and insigniaTip:find("Sold by Officer Areyn.", 1, true), "PvP rank keeps the game's wording, names the quartermaster")
local _, coifTip = Cat.Acquisition(coif)
local hogger = select(1, Cat.Acquisition(Cat.Get(6085)))
assert(hogger:find(F.isForever and "'WANTED: \"Hogger\"'" or "'Wanted: \"Hogger\"'", 1, true), "each client names its own quest")
assert(Cat.SourceLabel(Cat.Get(4614)) == "World drop", "a creature or two seen in the beta does not replace a world drop")
do -- a drop the site cannot place, from a boss we know, gets its raid and pin
    local saved = F.GEARSOURCES
    F.GEARSOURCES = "999001|N|Ragnaros||"
    Cat.ReleaseSources()
    local source = Cat.Source({ id = 999001, name = "Test Item" })
    assert(source.label == "Ragnaros · Molten Core" and Cat.EntranceFor(source.place).id == "dungeon:mc", "known boss gets its raid")
    F.GEARSOURCES = saved
    Cat.ReleaseSources()
end
if F.isForever then
    assert(coifTip and coifTip:find("Unconfirmed in WoW Forever", 1, true), "Classic sources are Unconfirmed on Forever")
else
    assert(coifTip == nil, "no Forever note on Classic Era")
end
print("  imported sources: bosses, raids, world drops, quartermasters ok")

-- Each client its own item: same, updated in Forever, or new in Forever.
local dawn = Cat.Get(19057)
local dawnListed
for _, item in ipairs(Cat.Search("HandsSlot", { text = "gloves of the dawn" })) do
    if item.id == 19057 then assert(not dawnListed, "an updated item is listed once"); dawnListed = item end
end
local helm = Cat.Get(16465)
if F.isForever then
    assert(dawn.ilvl == 61 and dawn.req == 56 and dawn.updated and Cat.ForeverStatus(dawn) == "updated", "Forever's version of an updated item")
    assert(helm.set == 0 and Cat.ForeverStatus(helm) == "updated", "Forever's PvP pieces leave the old set")
    local ring = Cat.Get(272409)
    assert(ring and ring.stats:find("t10", 1, true), "Forever-only items have stats from the item-level budget")
else
    assert(dawn.ilvl == 64 and dawn.req == 59 and not dawn.updated, "Classic Era keeps Classic's item")
    assert(helm.set == 395, "Classic Era keeps the Classic set")
    assert(Cat.Get(272409).forever == 2, "Forever-only items stay marked")
end
assert(dawnListed == dawn, "search and lookup agree")
print("  Forever versions: same, updated and new items per client ok")

-- Picker: filters persist, the list recycles a few rows over thousands of items, scrolling rebinds them.
UnitName = function() return "ListOwner" end
UnitClass = function() return "Warrior", "WARRIOR" end
F.ShowTab("gear"); T.new(); text(T.name, "List test")
click(T.head)
text(T.search, "")
assert(select(2, T.found()) == 25, "the list starts with the best 25")
T.filters.showAll:GetScript("OnClick")(T.filters.showAll)
local list, total = T.found()
assert(total > 40 and #T.results < total, "few rows for many items")
assert(T.results[1].item == list[1] and T.results[2].item == list[2], "rows start at the top of the list")
local scrolled = 20 * 46 + 5
T.list.scroll.GetVerticalScroll = function() return scrolled end
T.list:Update()
assert(T.results[1].item == list[21], "scrolling rebinds the same rows to later items")
T.list.scroll.GetVerticalScroll = nil
-- quality: one dropdown, game terms
Choose(T.filters.quality, 4)
for _, entry in ipairs(T.found()) do assert(entry.q >= 4, "Epic+ shows epics and legendaries") end
Choose(T.filters.quality, 0)
-- stat: only items with it, best first, and the row says how much
Choose(T.filters.stat, "s")
local strong = T.found()
assert(#strong > 1, "strength heads exist")
for i, entry in ipairs(strong) do
    assert(Cat.Stat(entry, "s") > 0, "the stat filter keeps items with that stat")
    if i > 1 then assert(Cat.Stat(strong[i - 1], "s") >= Cat.Stat(entry, "s"), "best first by the chosen stat") end
end
assert((T.results[1].source:GetText() or ""):find("Strength", 1, true), "rows show the stat value")
-- type: the slot's armor types, remembered per slot
local kinds = {}
for _, c in ipairs(T.filters.kind.choices) do kinds[c[1]] = c[2] end
assert(T.filters.kind:IsShown() and kinds[404] == "Plate" and kinds[401] == "Cloth" and kinds[false] == "Any armor", "armor types to choose from")
Choose(T.filters.kind, 404)
for _, entry in ipairs(T.found()) do assert(entry.sub == 404, "Plate shows plate only") end
assert(D.gearPlanner.prefs.stat == "s" and D.gearPlanner.prefs.kinds.HeadSlot == 404, "filter choices persist in the saved data")
T.clickAway:GetScript("OnEvent")(); click(T.head)
assert(T.filters.kind.value == 404, "the type choice is remembered for the slot")
Choose(T.filters.kind, false); Choose(T.filters.stat, false)
T.clickAway:GetScript("OnEvent")()
click(T.slots.Finger0Slot)
assert(not T.filters.kind:IsShown(), "rings have no type to choose")
T.clickAway:GetScript("OnEvent")()
-- target level: a ceiling; heavier armor waits for its level
local listBuild = T.store().builds[#T.store().builds]
T.level:SetText("20"); T.level:GetScript("OnEnterPressed")(T.level)
assert(listBuild.level == 20, "the set keeps its target level")
click(T.head)
T.filters.showAll:GetScript("OnClick")(T.filters.showAll)
for _, entry in ipairs(T.found()) do assert(entry.req <= 20 and entry.sub ~= 404, "a level 20 Warrior set lists what it can wear at 20") end
for _, c in ipairs(T.filters.kind.choices) do assert(c[1] ~= 404, "no plate choice before 40") end
T.clickAway:GetScript("OnEvent")()
T.level:GetScript("OnMouseWheel")(T.level, 1)
assert(listBuild.level == 21, "scrolling raises the level")
T.level:SetText("99"); T.level:GetScript("OnEnterPressed")(T.level)
assert(listBuild.level == 60, "levels stop at 60")
Pick("HeadSlot", 22418)
T.list.scroll.GetVerticalScroll = function() return scrolled end
click(T.slots.HeadSlot)
T.list.scroll.GetVerticalScroll = nil
F.ShowTab("tracker")
print("  picker: best 25 then Show all, recycled rows, stat/type/quality dropdowns, target level and persistence ok")

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
-- From another character: the pencil opens the owner's set, planning for the owner.
local ownerKey = setGoal.plannerOwner
ForeverGoalTrackerDB.characters[ownerKey] = ForeverGoalTrackerDB.characters[ownerKey] or {}
ForeverGoalTrackerDB.characters[ownerKey].class = ForeverGoalTrackerDB.characters[ownerKey].class or "HUNTER"
UnitName = function() return "SomeoneElse" end
F.UpdateEditButton(setGoal)
assert(F.detailEditBtn:IsShown(), "any character can edit a roster character's set")
F.ShowTab("tracker")
assert(F.OpenGearSet(setGoal) == true and T.setTitle:GetText() == "Dragonstalker plan", "opens the owner's set from another character")
assert(not T.fill:IsShown(), "Fill from equipped is only for the logged-in character")
F.GearPlannerFor(nil)
assert(F.OpenGearSet({ id = "x", plannerOwner = "Nobody-Nowhere" }) == false, "a character not on the roster cannot be opened")
F.UpdateEditButton(F.GoalById("raid_mc"))
assert(not F.detailEditBtn:IsShown(), "ordinary goals are unaffected")
UnitName = oldName
UnitClass = oldClass
F.ShowTab("tracker")
print("  whole sets, slot assignment, Enter to pick and the goal-page edit button ok")

-- Armor type follows the class (and level 40 for mail and plate); cloaks stay open to all.
local function subs(list) local out = {} for _, item in ipairs(list) do out[item.sub] = true end return out end
local hunter60 = Cat.Search("ChestSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 60 })
local h60 = subs(hunter60)
assert(h60[403] and h60[402] and h60[401] and not h60[404], "a level 60 Hunter can still pick leather or cloth")
local lowest = 60
for _, item in ipairs(hunter60) do lowest = math.min(lowest, item.req) end
assert(lowest < 20, "a level 60 set still lists low-level items")
local hunter30 = Cat.Search("ChestSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 30 })
local h30 = subs(hunter30)
assert(h30[402] and h30[401] and not h30[403], "mail waits for level 40")
for _, item in ipairs(hunter30) do assert(item.req <= 30, "the target level is a ceiling") end
assert(#Cat.Search("HeadSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 20, text = "cryptstalker" }) == 0,
    "a level 20 set leaves out what it cannot wear yet")
local crypt = Cat.Search("HeadSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 60, text = "cryptstalker" })
assert(#crypt == 1 and crypt[1].id == 22438, "a level 60 set finds the Cryptstalker Headpiece")
local warrior30 = subs(Cat.Search("LegsSlot", { usable = true, class = "WARRIOR", faction = "Alliance", level = 30 }))
assert(warrior30[403] and warrior30[402] and not warrior30[404], "Warriors wear mail from the start and plate at 40")
local druid = subs(Cat.Search("HandsSlot", { usable = true, class = "DRUID", faction = "Alliance" }))
assert(druid[402] and druid[401] and not druid[403], "Druids see leather and cloth, never mail")
assert(#Cat.Search("BackSlot", { usable = true, class = "WARRIOR", faction = "Alliance" }) > 50, "cloaks are for everyone")
local allChests = subs(Cat.Search("ChestSlot", { usable = false, class = "HUNTER" }))
assert(allChests[401] and allChests[402] and allChests[403] and allChests[404], "Usable off shows every armor type")
-- stats come from the game: the item's own and its Equip: spells
local helm, legs = Cat.Get(16846), Cat.Get(15062)
assert(Cat.Stat(helm, "a") == 23 and Cat.Stat(helm, "t") == 23 and Cat.Stat(helm, "c") == 1, "Giantstalker's Helmet stats")
assert(Cat.Stat(legs, "A") == 46 and Cat.StatText(legs, "c") == "+1% Crit", "Devilsaur Leggings attack power and crit")
assert(#Cat.Search("HeadSlot", { level = 25, text = "" }) > #Cat.Search("HeadSlot", { level = 25, minQuality = 3 }), "leveling greens are in the database")
print("  armor by class and target level, lighter armor kept, low-level items kept, stats from the game")

-- Every ammo item on Wowhead Forever's projectiles list has a source (Doomshot and the cannon balls are not on it).
for _, item in ipairs(Cat.Search("AmmoSlot", { usable = false })) do
    if item.id ~= 12654 and item.id ~= 13377 then
        assert(Cat.Source(item), "ammo has a source: " .. item.name)
    end
end
assert(Cat.SourceLabel(Cat.Get(9399)):find("Uldaman", 1, true), "Precision Arrow drops in Uldaman")
print("  ammo sources ok")

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

-- Ammo for classes that shoot, matched to the planned ranged weapon; relics in the ranged slot.
assert(Cat.SLOT_INDEX.AmmoSlot == 0 and Cat.SLOT_NAMES[0] == "AmmoSlot")
assert(Cat.UsesAmmo("HUNTER") and Cat.UsesAmmo("ROGUE") and not Cat.UsesAmmo("MAGE") and not Cat.UsesAmmo("PALADIN"))
assert(Cat.UsesRelic("SHAMAN") and Cat.UsesRelic("DRUID") and Cat.UsesRelic("PALADIN") and not Cat.UsesRelic("HUNTER"))
local arrows = Cat.Search("AmmoSlot", { usable = true, class = "HUNTER", ammo = 602 })
assert(#arrows > 3, "arrows for bows")
for _, item in ipairs(arrows) do assert(item.sub == 602 and item.inv == 24, "only arrows") end
assert(#Cat.Search("AmmoSlot", { usable = true, class = "MAGE" }) == 0, "casters have no ammo")
assert(Cat.AmmoFor(Cat.Get(21272)) == 603 and Cat.AmmoFor(Cat.Get(19107)) == 602 and Cat.AmmoFor(Cat.Get(22812)) == 602, "guns take bullets; bows and crossbows take arrows")
UnitName = function() return "AmmoOwner" end
UnitClass = function() return "Hunter", "HUNTER" end
F.ShowTab("gear"); T.new(); text(T.name, "Ammo test")
Pick("RangedSlot", 21272) -- Blessed Qiraji Musket, a gun
click(T.slots.AmmoSlot)
local ammoList = T.found()
assert(#ammoList > 0, "ammo picker lists bullets")
for _, item in ipairs(ammoList) do assert(item.sub == 603, "a gun gets bullets only") end
click(T.results[1])
local ammoBuild = T.store().builds[#T.store().builds]
assert(ammoBuild.slots[0] == ammoList[1].id, "ammo saves in slot 0")
click(T.add)
local ammoGoal = F.GoalById(ammoBuild.goalId)
assert(ammoGoal.steps[#ammoGoal.steps].auto.item == ammoList[1].id and ammoGoal.steps[#ammoGoal.steps - 1].auto.item == 21272,
    "the ammo step follows the ranged weapon")
-- Hunters also plan a quiver (bows) or ammo pouch (guns), listed between the ranged weapon and the ammo.
assert(Cat.SLOT_INDEX.QuiverSlot == 20 and Cat.UsesQuiver("HUNTER") and not Cat.UsesQuiver("ROGUE"))
assert(#Cat.Search("QuiverSlot", { usable = true, class = "WARRIOR" }) == 0, "only Hunters see quivers")
local ammoId = ammoBuild.slots[0] -- the picker reuses its result list, so keep the id
click(T.slots.QuiverSlot)
local pouches = T.found()
assert(#pouches > 0, "quiver picker lists ammo pouches for a gun")
for _, item in ipairs(pouches) do assert(item.sub == 1103 and item.inv == 27, "a gun gets ammo pouches only") end
click(T.results[1])
local pouchId = pouches[1].id
assert(ammoBuild.slots[20] == pouchId, "the quiver saves in slot 20")
-- A quiver worn in a bag slot is in no bag, yet it is owned.
do
    local oldInv = GetInventoryItemID
    GetInventoryItemID = function(_, slot) if slot == 33 then return pouchId end end
    local oldConvert = ContainerIDToInventoryID
    ContainerIDToInventoryID = function(bag) return 30 + bag end -- Forever-style numbering
    F.bagSlots = nil
    F.Count("trades", true)
    local me = ForeverGoalTrackerDB.characters[F.MaterialsUI.charKey()]
    assert(me and me.items[pouchId] == 1, "an equipped quiver counts as owned")
    GetInventoryItemID = oldInv; ContainerIDToInventoryID = oldConvert; F.bagSlots = nil
end
ammoGoal = F.GoalById(ammoBuild.goalId)
local n = #ammoGoal.steps
assert(ammoGoal.steps[n - 2].auto.item == 21272 and ammoGoal.steps[n - 1].auto.item == pouchId
    and ammoGoal.steps[n].auto.item == ammoId, "steps run ranged, quiver, ammo")
assert(Cat.QuiverFor(Cat.Get(19107)) == 1102, "bows take quivers")
UnitClass = function() return "Druid", "DRUID" end
F.ShowTab("tracker"); F.ShowTab("gear"); T.new()
click(T.slots.RangedSlot)
assert(#T.found() > 0)
for _, item in ipairs(T.found()) do assert(item.sub == 408, "a Druid's ranged slot lists idols") end
UnitClass = oldClass
UnitName = oldName
F.ShowTab("tracker")
print("  ammo slot for classes that shoot, matched to the ranged weapon; relics for Druids, Paladins and Shamans")

-- The picker pops out beside the slot column for every slot, the same width, never past the window.
UnitName = function() return "SizeOwner" end
F.ShowTab("gear"); T.new(); text(T.name, "Size test")
local widths, oldSetWidth = {}, T.picker.SetWidth
T.picker.SetWidth = function(_, w) widths[#widths + 1] = w end
for _, slot in ipairs({ "HeadSlot", "ChestSlot", "WristSlot", "FeetSlot", "Finger0Slot", "Trinket1Slot", "MainHandSlot" }) do
    click(T.slots[slot]); T.clickAway:GetScript("OnEvent")()
end
T.picker.SetWidth = oldSetWidth
assert(#widths == 7, "every slot placed the picker")
for i = 1, #widths do
    assert(widths[i] == widths[1] and widths[i] >= 250 and widths[i] <= 340, "same picker width for every slot, within its bounds")
end
UnitName = oldName
F.ShowTab("tracker")
print("  one picker size and place for every slot, beside the slot column")

-- An item the game cannot name (unrevealed in Forever) still becomes a link in its quality color.
do
    local oldInfo = F.ItemInfo
    F.ItemInfo = function() return nil end
    local shown = "Complete 'The Treasure of the Shen'dralar' in Dire Maul for Backwood Helm"
    local row = { itemId = 18421, text = { GetText = function() return shown end, SetText = function(_, t) shown = t end } }
    F.LinkItemName(row)
    assert(shown:find("|cff0070dd|Hitem:18421|hBackwood Helm|h|r", 1, true), "unrevealed planner item is a blue link: " .. shown)
    assert(F.ItemTag(18421, "Backwood Helm"):find("|cff0070dd", 1, true), "tips use the database quality too")
    F.ItemInfo = oldInfo
    print("  unrevealed items stay links from the planner database")
end

-- Recipes come from the game's own tables, per client.
do
    local legs = Cat.Recipe(15062)
    assert(legs and legs.skill == "Leatherworking", "Devilsaur Leggings are Leatherworking")
    local want = { [8170] = 30, [15417] = 14, [15407] = 1, [14341] = 1 }
    for _, r in ipairs(legs.reagents) do assert(want[r[1]] == r[2], "Devilsaur Leggings reagent " .. r[1]) ; want[r[1]] = nil end
    assert(next(want) == nil, "every Devilsaur Leggings reagent")
    -- Forever moved Wildthorn Mail from Blacksmithing to Leatherworking
    assert(Cat.Recipe(12624).skill == (F.isForever and "Leatherworking" or "Blacksmithing"), "each client keeps its own recipe")
    assert(Cat.SourceLabel(Cat.Get(12624)):find("craft or buy", 1, true), "a crafted item says so without a hand-written source")
    assert(Cat.Recipe(19389) == nil, "dropped items have no recipe")
    print("  recipes from the game's tables, per client")
end

-- Planning for another character uses their class, faction and level, and keeps their sets apart.
do
    local D = ForeverGoalTrackerDB
    D.characters["Altlock-Realm"] = { name = "Altlock", class = "WARLOCK", race = "Gnome", faction = "Alliance", level = 60, lastSeen = 1 }
    F.ShowTab("gear")
    F.GearPlannerFor("Altlock-Realm")
    T.new(); text(T.name, "Altlock plan")
    T.name:GetScript("OnEnterPressed")(T.name)
    click(T.slots.RangedSlot)
    local wands = T.found()
    assert(#wands > 0, "the alt's ranged slot lists items")
    for _, item in ipairs(wands) do assert(item.sub == 219, "a Warlock alt sees wands only") end
    local altStore = D.gearPlanner.characters["Altlock-Realm"]
    assert(altStore and altStore.builds[1] and altStore.builds[1].name == "Altlock plan", "the set is saved under the alt")
    F.GearPlannerFor(nil)
    for _, build in ipairs(T.store().builds) do assert(build.name ~= "Altlock plan", "the alt's set stays off your own list") end
    F.ShowTab("tracker")
    print("  planning for another character on the roster")
end

-- Enchants: a smaller square beside each item that can take one; planned, tracked and costed.
do
    local D = ForeverGoalTrackerDB
    local bracers, ring, sword, polearm, crossbow, neck = 16861, 18500, 19019, 22314, 19107, 22340
    -- which enchants fit is the game's own data, per client
    local function Names(id)
        local out = {}
        for _, e in ipairs(Cat.EnchantsFor(Cat.Get(id))) do out[#out + 1] = e.name end
        return table.concat(out, "; ")
    end
    assert(Names(ring) == "", "rings take no enchant")
    assert(Names(sword):find("Crusader", 1, true) and not Names(sword):find("2H", 1, true), "one-handers get weapon enchants, not 2H ones")
    assert(Names(polearm):find("2H Weapon", 1, true), "two-handers get 2H enchants")
    assert(Names(crossbow):find("Scope", 1, true) and not Names(crossbow):find("Crusader", 1, true), "ranged weapons get scopes")
    assert((Names(neck) ~= "") == (F.isForever and true or false), "necklace enchants exist only on Forever")

    F.ShowTab("gear")
    T.new(); text(T.name, "Enchant test")
    T.name:GetScript("OnEnterPressed")(T.name)
    local build = T.store().builds[#T.store().builds]
    assert(not T.slots.WristSlot.enchant.planned, "no enchant square without an item")
    Pick("WristSlot", bracers)
    local square = T.slots.WristSlot.enchant
    assert(square.planned, "a bracer shows the enchant square")
    Pick("Finger0Slot", ring)
    assert(not T.slots.Finger0Slot.enchant.planned, "a ring shows none")
    click(square)
    assert(T.picker:IsShown(), "the square opens the picker")
    text(T.search, "superior strength")
    local list = T.found()
    assert(list[1] and list[1].spell, "the picker lists enchants")
    for _, e in ipairs(list) do assert(Cat.EnchantFits(e.spell, Cat.Get(bracers)), "only enchants that fit the bracer") end
    local chosen = list[1]
    click(T.results[1])
    assert(build.enchants and build.enchants[9] == chosen.spell and not T.picker:IsShown(), "picking plans the enchant and closes")
    -- removing the item drops its enchant; right-click removes just the enchant
    click(T.slots.WristSlot); click(T.unequip)
    assert(not (build.enchants and build.enchants[9]), "an enchant never outlives its item")
    Pick("WristSlot", bracers); click(square); text(T.search, "superior strength"); click(T.results[1])
    square:GetScript("OnClick")(square, "RightButton")
    assert(not (build.enchants and build.enchants[9]), "right-click removes the enchant")
    click(square); text(T.search, "superior strength"); click(T.results[1])

    -- the goal gets an enchant step with its materials, done when the owner wears it
    local key = F.MaterialsUI.charKey()
    local previous = D.characters[key]
    D.characters[key] = { items = {} }
    click(T.add)
    local goal = F.GoalById(build.goalId)
    local index
    for i, step in ipairs(goal.steps) do if step.auto and step.auto.enchant then index = i end end
    assert(index and goal.steps[index].auto.enchant == chosen.effect and goal.steps[index].auto.slot == 9, "an enchant step for the bracer")
    assert(goal.steps[index].text:find("Superior Strength", 1, true) and #goal.steps[index].reagents > 0, "the step names the enchant and costs its materials")
    assert(not D.progress[goal.id][index], "not done before it is worn")
    D.characters[key].enchants = { [9] = "1:" .. chosen.effect }
    F.RefreshPlannerGoals()
    assert(not D.progress[goal.id][index], "the enchant on a different item does not count")
    D.characters[key].enchants = { [9] = bracers .. ":" .. chosen.effect }
    F.RefreshPlannerGoals()
    assert(D.progress[goal.id][index], "wearing the enchanted bracer completes the step")
    Pick("HeadSlot", 16866)
    local moved
    for i, step in ipairs(goal.steps) do if step.auto and step.auto.enchant then moved = i end end
    assert(moved and D.progress[goal.id][moved], "enchant credit moves with its step")
    D.characters[key] = previous

    -- Fill from equipped copies worn enchants and names what it skipped
    local oldGet, oldLink, oldInfo = GetInventoryItemID, GetInventoryItemLink, F.ItemInfo
    local worn = { [9] = bracers, [2] = 1 }
    GetInventoryItemID = function(_, slot) return worn[slot] end
    GetInventoryItemLink = function(_, slot)
        if slot == 9 then return "|cffa335ee|Hitem:" .. bracers .. ":" .. chosen.effect .. ":0:0|h[Bracers]|h|r" end
    end
    F.ItemInfo = function(id) if id == 1 then return "Mystery Necklace" end return oldInfo(id) end
    T.new(); text(T.name, "Enchant fill")
    T.name:GetScript("OnEnterPressed")(T.name)
    local filled = T.store().builds[#T.store().builds]
    click(T.fill)
    assert(filled.slots[9] == bracers and filled.enchants and filled.enchants[9] == chosen.spell, "fill copies the worn enchant")
    assert((T.status:GetText() or "") == "", "fill leaves out what the database doesn't know, without a message")
    GetInventoryItemID, GetInventoryItemLink, F.ItemInfo = oldGet, oldLink, oldInfo
    click(T.duplicate)
    local copy = T.store().builds[#T.store().builds]
    assert(copy.enchants and copy.enchants[9] == chosen.spell and copy.enchants ~= filled.enchants, "duplicate copies enchants")
    F.ShowTab("tracker")
    print("  enchants: fit rules, square, picker, goal step, credit, fill and duplicate")
end

-- A gear set goal shows its owner's leveling art and says whose set it is.
do
    local D, B = ForeverGoalTrackerDB, F.goalBanner
    D.characters["Dwarfhunt-Realm"] = { name = "Dwarfhunt", class = "HUNTER", race = "Dwarf", faction = "Alliance", level = 60 }
    D.characters["Sneaky-Realm"] = { name = "Sneaky", class = "ROGUE", race = "Human", faction = "Alliance", level = 60 }
    local dwarfSet = { id = "planner_test_dwarf", name = "Dwarf set", category = "Item Set", plannerOwner = "Dwarfhunt-Realm", steps = {} }
    local rogueSet = { id = "planner_test_rogue", name = "Rogue set", category = "Item Set", plannerOwner = "Sneaky-Realm", steps = {} }
    F.goals[#F.goals + 1] = dwarfSet; F.goals[#F.goals + 1] = rogueSet; F.goalIndex = nil
    assert(B:ResolveArt(dwarfSet.id) == "allclasses_dwarf_hunter-banner.blp", "a Dwarf Hunter's set shows the Dwarf Hunter leveling art")
    assert(B:ResolveArt(rogueSet.id) == B.artPaths.allclasses, "a class without its own art gets the shared leveling art")
    local eyebrow = F.GoalEyebrow(dwarfSet, true)
    assert(eyebrow:find("^GEAR SET") and eyebrow:find("DWARFHUNT", 1, true), "the card says it is that character's gear set: " .. eyebrow)
    assert(not F.GoalEyebrow(F.GoalById("set_tier1") or { category = "Item Set" }, true):find("GEAR SET", 1, true), "Library sets keep their own label")
    table.remove(F.goals); table.remove(F.goals); F.goalIndex = nil
    D.characters["Dwarfhunt-Realm"], D.characters["Sneaky-Realm"] = nil, nil
    print("  gear set goals: owner's leveling art and a GEAR SET label")
end

-- Library goals: items that a Library goal rewards or that belong to a Library set link to it.
do
    local D = ForeverGoalTrackerDB
    local thunder, kind = Cat.GoalFor(19019, "Alliance")
    assert(thunder and thunder.id == "thunderfury" and kind == "reward", "Thunderfury links to its legendary goal")
    local setGoal, setKind = Cat.GoalFor(16866, "Alliance")
    assert(setGoal and setKind == "set", "a Tier 1 piece links to its Library set goal")
    assert(Cat.GoalFor(1, "Alliance") == nil, "other items have no Library goal")
    local oldName, oldClass = UnitName, UnitClass
    UnitName = function() return "LibraryOwner" end
    UnitClass = function() return "Warrior", "WARRIOR" end
    F.ShowTab("gear"); T.new(); text(T.name, "Library links")
    T.name:GetScript("OnEnterPressed")(T.name)
    local build = T.store().builds[#T.store().builds]
    -- the picker row carries the gold goal mark
    click(T.slots.MainHandSlot); text(T.search, "#19019")
    assert(T.results[1].goal == thunder and T.results[1].goalBtn and T.found()[1].id == 19019, "the picker row marks Thunderfury's goal")
    click(T.results[1])
    Pick("HeadSlot", 16866); Pick("ShoulderSlot", 16868)
    -- the header names the Library set behind two or more pieces
    assert(T.libraryHeader.goal == setGoal and (T.libraryHeader.text:GetText() or ""):find("Library goal", 1, true), "the header links the Library set")
    -- the slot menu adds the goal, then opens it
    D.active.thunderfury = nil
    click(T.slots.MainHandSlot)
    assert(T.goalMenu.text:GetText() == "+ Add Thunderfury goal", "the menu offers to add the goal: " .. tostring(T.goalMenu.text:GetText()))
    click(T.goalMenu)
    assert(D.active.thunderfury, "Add goal adds Thunderfury to My Goals")
    click(T.slots.MainHandSlot)
    assert(T.goalMenu.text:GetText() == "Open Thunderfury goal", "then it offers to open it")
    T.clickAway:GetScript("OnEvent")()
    -- in the gear set goal, the step is the Library goal (no doubled materials), the set is a tip
    click(T.add)
    local goal = F.GoalById(build.goalId)
    local thunderStep, setTip
    for _, step in ipairs(goal.steps) do if step.auto and step.auto.item == 19019 then thunderStep = step end end
    for _, tip in ipairs(goal.tips) do if tip:find("Library goal for these pieces", 1, true) then setTip = tip end end
    assert(thunderStep and thunderStep.text:find("{thunderfury:Thunderfury} goal", 1, true) and not thunderStep.reagents,
        "the step is Complete the Thunderfury goal")
    assert(setTip and setTip:find("{" .. setGoal.id .. ":", 1, true), "a tip links the Library set goal")
    -- any other item can become its own goal
    D.active.thunderfury = nil
    Pick("Finger0Slot", 18500)
    assert(Cat.GoalFor(18500, "Alliance") == nil)
    click(T.slots.Finger0Slot)
    assert(T.goalMenu.text:GetText() == "Track this item", "items without a Library goal can be tracked on their own")
    local before = #T.store().builds
    click(T.goalMenu)
    local solo = T.store().builds[before + 1]
    assert(solo and solo.single == 18500 and solo.slots[11] == 18500 and solo.level == build.level and D.active[solo.goalId],
        "its own goal: a one-item set, tracked at once")
    assert(F.GoalById(solo.goalId).plannerOwner, "it is a gear set goal (owner art, GEAR SET label)")
    click(T.slots.Finger0Slot)
    assert(T.goalMenu.text:GetText() == "View in Goals", "then the menu opens it")
    T.clickAway:GetScript("OnEvent")()
    UnitName, UnitClass = oldName, oldClass
    F.ShowTab("tracker")
    print("  Library goals: picker mark, header link, add or open from the slot menu, linked steps, track on its own")
end

-- Across characters: a gear set is its owner's; other characters' copies are hints, never credit.
do
    local D = ForeverGoalTrackerDB
    assert(Cat.Get(16846).bind == 1 and Cat.Get(15062).bind == 2, "bind types come from the game (pickup, equip)")
    assert(F.GoalFits({ plannerOwner = "Swagrid-Realm" }, { key = "Frostbolt-Realm", class = "MAGE" }) == false,
        "This character hides another character's gear sets")
    assert(F.GoalFits({ plannerOwner = "Swagrid-Realm" }, { key = "Swagrid-Realm", class = "HUNTER" }), "and shows your own")
    local saved = { D.characters["Swagrid-Realm"], D.characters["Frostbolt-Realm"] }
    D.characters["Swagrid-Realm"] = { name = "Swagrid", class = "HUNTER", items = {}, lastSeen = (time and time() or 0) - 2 * 86400 }
    local mage = { name = "Frostbolt", class = "MAGE", items = { [15062] = 1 }, worn = {} }
    D.characters["Frostbolt-Realm"] = mage
    local goal = { id = "planner_cross_test", plannerOwner = "Swagrid-Realm" }
    local legs = { auto = { item = 15062, forCharacter = "Swagrid-Realm" } }
    assert(F.PlannerElsewhere(goal, legs) == "On Frostbolt: mail it to Swagrid", "a Bind on Equip piece in another character's bags can be mailed")
    mage.worn = { [7] = 15062 }
    assert((F.PlannerElsewhere(goal, legs) or ""):find("soulbound", 1, true), "a worn Bind on Equip piece is soulbound")
    mage.worn, mage.items = {}, { [16846] = 1 }
    local helm = { auto = { item = 16846, forCharacter = "Swagrid-Realm" } }
    assert(F.PlannerElsewhere(goal, helm) == "Frostbolt has one, but it's soulbound. Swagrid needs their own",
        "a Bind on Pickup piece on another character is soulbound")
    mage.items = {}
    assert(F.PlannerElsewhere(goal, helm) == nil, "no hint when nobody else has it")
    assert(not (F.PlannerElsewhere(goal, { auto = { enchant = 1, slot = 9, forCharacter = "Swagrid-Realm" } })), "enchants are not mailed")
    assert((F.PlannerFreshness(goal) or ""):find("Swagrid's gear, saved", 1, true), "another character's set says how fresh it is")
    D.characters["Swagrid-Realm"], D.characters["Frostbolt-Realm"] = saved[1], saved[2]
    print("  across characters: This character view, mail or soulbound hints, freshness")
end

-- The planner light: on by default, /goals plannerlight switches it and remembers the choice.
do
    local D = ForeverGoalTrackerDB
    D.gearPlanner.prefs.light = nil
    assert(D.gearPlanner.prefs.light ~= false, "the light starts on")
    F.TogglePlannerLight()
    assert(D.gearPlanner.prefs.light == false, "the toggle turns it off and saves that")
    F.TogglePlannerLight()
    assert(D.gearPlanner.prefs.light == true, "and back on")
    print("  planner light toggle")
end

-- The resting camera is two wheel steps in; opening or switching a set returns there after a focused slot.
do
    local portrait
    T.model.SetPortraitZoom = function(_, v) portrait = v end
    F.ShowTab("gear"); T.new(); text(T.name, "Camera rest")
    T.name:GetScript("OnEnterPressed")(T.name)
    click(T.slots.HeadSlot)
    local settle = T.camera:GetScript("OnUpdate"); if settle then settle(T.camera, 1) end
    T.clickAway:GetScript("OnEvent")()
    T.new() -- a new (or another) set
    settle = T.camera:GetScript("OnUpdate"); if settle then settle(T.camera, 1) end
    assert(portrait and math.abs(portrait - 0.2) < 1e-6, "the camera rests two wheel steps in: " .. tostring(portrait))
    T.model.SetPortraitZoom = nil
    F.ShowTab("tracker")
    print("  camera rests at the closer default view")
end

-- The wheel glides: quick clicks add up into one continuous move that settles on its target.
do
    local portrait
    T.model.SetPortraitZoom = function(_, v) portrait = v end
    F.ShowTab("gear"); T.new(); text(T.name, "Glide")
    T.name:GetScript("OnEnterPressed")(T.name)
    local settle = T.camera:GetScript("OnUpdate"); if settle then settle(T.camera, 1) end
    local wheel, frames = T.model:GetScript("OnMouseWheel"), {}
    local function Frame() local f = T.camera:GetScript("OnUpdate"); if f then f(T.camera, 0.016) end; frames[#frames + 1] = portrait end
    wheel(T.model, 1); Frame(); Frame()
    wheel(T.model, 1); Frame() -- a second click mid-move
    for _ = 1, 120 do Frame() end
    for i = 2, #frames do assert(frames[i] >= frames[i - 1] - 1e-9, "the zoom never steps back while gliding") end
    assert(frames[3] > frames[2], "a second click keeps the move going, no restart from a standstill")
    assert(math.abs(portrait - 0.4) < 1e-6 and not T.camera:GetScript("OnUpdate"), "it settles exactly two steps in and stops")
    T.model.SetPortraitZoom = nil
    F.ShowTab("tracker")
    print("  wheel zoom glides and settles")
end

-- Dual wielding: each weapon is tried on in its own hand (the off hand no longer replaces the main).
do
    local oldName, oldClass = UnitName, UnitClass
    UnitName = function() return "DualOwner" end
    UnitClass = function() return "Rogue", "ROGUE" end
    local hands = {}
    T.model.TryOn = function(_, link, hand) hands[tonumber(link:match("item:(%d+)"))] = hand or true end
    F.ShowTab("gear"); T.new(); text(T.name, "Dual wield")
    T.name:GetScript("OnEnterPressed")(T.name)
    Pick("MainHandSlot", 19019); Pick("SecondaryHandSlot", 18832)
    local fade = T.appearance:GetScript("OnUpdate"); if fade then fade(T.appearance, 1) end -- the gear swap mid-fade
    assert(hands[19019] == "MAINHANDSLOT" and hands[18832] == "SECONDARYHANDSLOT", "each weapon goes in its own hand")
    -- with a gun too, a Rogue holds the daggers; the toggle swaps to the gun, per class
    local D = ForeverGoalTrackerDB
    local function Worn() -- what the model wears once any fade has finished
        local f = T.appearance:GetScript("OnUpdate"); if f then f(T.appearance, 1) end
        hands = {}
        T.model:GetScript("OnModelLoaded")(T.model)
        return hands
    end
    local band = T.band
    Track(band.weapons)
    Pick("RangedSlot", 21272)
    local worn = Worn()
    assert(worn[19019] and worn[18832] and not worn[21272], "a Rogue shows the melee weapons over the gun")
    assert(band.weapons:IsShown(), "the weapons toggle shows when the set has both")
    click(band.weapons); worn = Worn()
    assert(worn[21272] and not worn[19019] and not worn[18832], "the toggle shows the gun instead")
    assert(D.gearPlanner.prefs.weapons.ROGUE == "ranged", "remembered for Rogues")
    click(band.weapons); worn = Worn()
    assert(worn[19019] and not worn[21272], "and back")
    -- choosing the ranged slot shows the gun while its picker is open
    hands = {}
    click(T.slots.RangedSlot)
    assert(hands[21272], "the slot being chosen shows")
    T.clickAway:GetScript("OnEvent")()
    -- a Hunter holds the ranged weapon unless the toggle says otherwise
    UnitClass = function() return "Hunter", "HUNTER" end
    T.new(); text(T.name, "Hunter weapons"); T.name:GetScript("OnEnterPressed")(T.name)
    Pick("MainHandSlot", 19019); Pick("RangedSlot", 21272)
    worn = Worn()
    assert(worn[21272] and not worn[19019], "a Hunter shows the ranged weapon")
    -- helm and cloak: hidden from the model, back when their slot is chosen
    Pick("HeadSlot", 16846)
    click(band.helm); worn = Worn()
    assert(D.gearPlanner.prefs.hideHelm and not worn[16846], "a hidden helm stays off the model")
    assert(band.helm.hidden, "its button is greyed")
    local eyeShown, eyeTexture
    band.helm.eye.SetShown = function(_, on) eyeShown = on end
    band.helm.eye.SetTexture = function(_, path) eyeTexture = path end
    band.helm:GetScript("OnEnter")(band.helm)
    assert(eyeShown and eyeTexture:find("eye%-white$"), "hovering a hidden helm previews showing it: the open eye")
    band.helm:GetScript("OnLeave")(band.helm)
    assert(not eyeShown, "the eye goes when the cursor leaves")
    band.helm.eye.SetShown, band.helm.eye.SetTexture = nil, nil
    hands = {}
    click(T.slots.HeadSlot)
    assert(hands[16846], "choosing the head slot shows the helm")
    T.clickAway:GetScript("OnEvent")()
    click(band.helm); worn = Worn()
    assert(not D.gearPlanner.prefs.hideHelm and worn[16846] and not band.helm.hidden, "shown again, the open eye")
    click(band.cloak)
    assert(D.gearPlanner.prefs.hideCloak, "the cloak toggle is saved")
    click(band.cloak)
    D.gearPlanner.prefs.weapons = nil
    T.model.TryOn = nil
    UnitName, UnitClass = oldName, oldClass
    F.ShowTab("tracker")
    print("  dual wield: main and off hand both on the model; melee or ranged by class and toggle; helm and cloak toggles")
end

-- No level requirement: planned by the level of its content; requirements above the set show red.
do
    local helm = Cat.Get(18421) -- Backwood Helm: item level 63, no requirement
    assert(helm.req <= 1 and Cat.PlanLevel(helm) == 58, "a no-requirement item plans at its content level")
    local function Has(list, id) for _, item in ipairs(list) do if item.id == id then return true end end return false end
    assert(not Has(Cat.Search("HeadSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 30 }), 18421),
        "a level 30 plan leaves out level-60 rewards without a requirement")
    assert(Has(Cat.Search("HeadSlot", { usable = true, class = "HUNTER", faction = "Alliance", level = 60 }), 18421), "a level 60 plan keeps them")
    local oldName, oldClass = UnitName, UnitClass
    UnitName = function() return "LevelOwner" end
    UnitClass = function() return "Warrior", "WARRIOR" end
    F.ShowTab("gear"); T.new(); text(T.name, "Level flags")
    T.name:GetScript("OnEnterPressed")(T.name)
    T.level:SetText("60"); T.level:GetScript("OnEnterPressed")(T.level)
    click(T.head); text(T.search, "#13216") -- Crown of the Penitent: no requirement
    assert((T.results[1].source:GetText() or ""):find("No level requirement", 1, true), "the row says what the game says")
    T.clickAway:GetScript("OnEvent")()
    Pick("HeadSlot", 16866) -- Helm of Might: requires 60
    T.level:SetText("10"); T.level:GetScript("OnEnterPressed")(T.level)
    local label = T.slots.HeadSlot.itemName:GetText() or ""
    assert(label:find("|cffff5a4aLv 60|r", 1, true) and label:find("Helm of Might", 1, true), "a planned item above the set's level shows its level in red")
    T.level:SetText("60"); T.level:GetScript("OnEnterPressed")(T.level)
    assert(not (T.slots.HeadSlot.itemName:GetText() or ""):find("Lv 60", 1, true), "no flag once the set's level allows it")
    UnitName, UnitClass = oldName, oldClass
    F.ShowTab("tracker")
    print("  level: no-requirement items by content level, honest wording, red flags above the set's level")
end

-- "Showing gear for level [min] – [max]": a floor and a ceiling, typed or scrolled, empty = any.
do
    local oldName, oldClass = UnitName, UnitClass
    UnitName = function() return "RangeOwner" end
    UnitClass = function() return "Warrior", "WARRIOR" end
    F.ShowTab("gear"); T.new(); text(T.name, "Range")
    T.name:GetScript("OnEnterPressed")(T.name)
    local build = T.store().builds[#T.store().builds]
    local function Type(box, value) box:SetText(value); box:GetScript("OnEnterPressed")(box) end
    local function Wheel(box, delta) box:GetScript("OnMouseWheel")(box, delta) end
    Type(T.level, "60"); Type(T.minLevel, "55")
    assert(build.minLevel == 55 and build.level == 60, "the set keeps its range")
    click(T.head); T.filters.showAll:GetScript("OnClick")(T.filters.showAll)
    for _, item in ipairs(T.found()) do assert(Cat.PlanLevel(item) >= 55 and Cat.PlanLevel(item) <= 60, "only gear for levels 55 to 60") end
    T.clickAway:GetScript("OnEvent")()
    Type(T.minLevel, "")
    assert(build.minLevel == nil, "an empty min is any")
    -- the box being changed stops at the other one: min never passes max
    Type(T.level, "10"); Type(T.minLevel, "30")
    assert(build.minLevel == 10 and build.level == 10, "a min above the max stops at the max")
    Type(T.minLevel, "5"); Type(T.level, "3")
    assert(build.minLevel == 5 and build.level == 5, "a max below the min stops at the min")
    Type(T.level, "20")
    for _ = 1, 30 do Wheel(T.minLevel, 1) end
    assert(build.minLevel == 20, "scrolling the min up stops at the max")
    assert(T.minLevel.any:GetText() == "Min" and T.level.any:GetText() == "Max", "empty boxes say Min and Max")
    Type(T.minLevel, "")
    -- an empty max is any level; armor and red flags treat it as 60
    Type(T.level, "")
    assert(build.level == false, "an empty max is any")
    click(T.head)
    local plate = false
    for _, c in ipairs(T.filters.kind.choices) do if c[1] == 404 then plate = true end end
    assert(plate, "with any max, a Warrior plans plate")
    T.clickAway:GetScript("OnEvent")()
    -- scrolling past the ends reaches any
    Wheel(T.level, -1); assert(build.level == 60, "scrolling down from any max gives 60")
    Wheel(T.level, 1); assert(build.level == false, "scrolling up from 60 gives any")
    Wheel(T.minLevel, 1); assert(build.minLevel == 1, "scrolling up from any min gives 1")
    Wheel(T.minLevel, -1); assert(build.minLevel == nil, "scrolling down from 1 gives any")
    UnitName, UnitClass = oldName, oldClass
    F.ShowTab("tracker")
    print("  level range: floor and ceiling, any at either end, scrolling past the ends, min never passes max")
end

-- First visit: the welcome card over the character's scene, with a gold way in.
do
    local W = T.welcome
    Track(W.card); Track(W.import)
    local oldName, oldClass, oldFaction = UnitName, UnitClass, UnitFactionGroup
    UnitName = function() return "WelcomeOwner" end
    UnitClass = function() return "Warrior", "WARRIOR" end
    local unit
    T.model.SetUnit = function(_, u) unit = u end
    F.ShowTab("gear")
    assert(#T.store().builds == 0 and W.card:IsShown(), "a first visit shows the welcome card")
    assert(unit == "player", "the scene shows your own character")
    assert(W.import:IsShown() and W.preset == nil, "Import from Wowhead, and no third button")
    assert(W.import:GetHeight() == W.create:GetHeight(), "the two buttons are the same height")
    assert(W.import:GetScript("OnClick") == T.wowhead.Open, "the card's import opens the Wowhead window")
    -- start from current gear (the "..." menu): a named set, filled and saved at once
    local oldGet = GetInventoryItemID
    GetInventoryItemID = function(_, slot) if slot == 1 then return 16866 end end
    local seen = {}
    for _, slot in ipairs({ "HeadSlot", "Trinket1Slot" }) do
        local b = T.slots[slot]
        b.SetAlpha = function(self, a) seen[slot] = a end
        b.GetAlpha = function() return seen[slot] or 1 end
    end
    click(T.newWorn)
    GetInventoryItemID = oldGet
    local made = T.store().builds[#T.store().builds]
    assert(made and made.name == "Current gear" and made.slots[1] == 16866, "it makes a set from the worn gear")
    -- the card fades out while the slots fade in, one after another
    local head = T.slots.HeadSlot
    assert(W.card:IsShown() and head:GetAlpha() < 0.01, "the slots start hidden as the set opens")
    local fade, alphas = W.driver:GetScript("OnUpdate"), {}
    for _ = 1, 100 do
        if not W.driver:GetScript("OnUpdate") then break end
        fade(W.driver, 0.02); alphas[#alphas + 1] = head:GetAlpha()
    end
    for i = 2, #alphas do assert(alphas[i] >= alphas[i - 1] - 1e-9, "the fade only rises") end
    assert(not W.driver:GetScript("OnUpdate") and head:GetAlpha() == 1 and T.slots.Trinket1Slot:GetAlpha() == 1,
        "every slot ends fully shown and the fade stops")
    assert(not W.card:IsShown(), "the card leaves once a set is open")
    T.slots.HeadSlot.SetAlpha, T.slots.HeadSlot.GetAlpha, T.slots.Trinket1Slot.SetAlpha, T.slots.Trinket1Slot.GetAlpha = nil, nil, nil, nil
    -- an Alliance Hunter still gets only the two ways in (Karl, 2026-10-27: no preset button)
    UnitName = function() return "WelcomeHunter" end
    UnitClass = function() return "Hunter", "HUNTER" end
    UnitFactionGroup = function() return "Alliance", "Alliance" end
    F.ShowTab("tracker"); F.ShowTab("gear")
    assert(W.card:IsShown() and W.preset == nil, "an Alliance Hunter sees only Create and Import")
    -- the import window fades the card away, Cancel brings it back, and an import opens without it
    local WI = T.wowhead
    Track(WI.frame)
    local cardAlpha = 1
    W.card.SetAlpha = function(_, a) cardAlpha = a end
    W.card.GetAlpha = function() return cardAlpha end
    local function Run(driver)
        for _ = 1, 60 do
            local fn = driver:GetScript("OnUpdate")
            if not fn then return end
            fn(driver, 0.05)
        end
    end
    -- the slots work from the welcome: the picker sets the card aside, and a pick starts a set
    click(T.slots.HeadSlot); Run(W.hold)
    assert(T.picker:IsShown() and not W.card:IsShown() and W.away, "the picker sets the welcome card aside")
    click(T.slots.ShoulderSlot)
    assert(T.picker:IsShown() and W.away and not W.card:IsShown(), "another slot keeps the picker open, the card away")
    T.clickAway:GetScript("OnEvent")(T.clickAway); Run(W.hold)
    assert(not T.picker:IsShown() and W.card:IsShown() and cardAlpha == 1 and not W.away, "closing the picker brings the card back")
    -- the welcome's picker lists gear for the character's level, the level the set it starts gets
    local oldLevel = UnitLevel
    UnitLevel = function() return 45 end
    click(T.slots.HeadSlot)
    local low = T.found()
    assert(#low > 0, "a level 45 Hunter has helms to choose")
    for _, entry in ipairs(low) do assert(F.GearCatalog.PlanLevel(entry) <= 45, "no gear above level 45: " .. entry.name) end
    assert(T.level:GetText() == "45", "the level box says 45")
    -- the boxes scroll on the welcome too, and the set the pick starts keeps that range
    T.level:GetScript("OnMouseWheel")(T.level, -1)
    T.minLevel:GetScript("OnMouseWheel")(T.minLevel, 1)
    assert(T.level:GetText() == "44" and T.minLevel:GetText() == "1", "scrolling changes the welcome's range")
    assert(#T.store().builds == 0, "changing the range starts no set")
    low = T.found()
    for _, entry in ipairs(low) do assert(F.GearCatalog.PlanLevel(entry) <= 44, "no gear above level 44: " .. entry.name) end
    click(low[1] and T.results[1])
    local lowSet = T.store().builds[#T.store().builds]
    assert(lowSet.level == 44 and lowSet.minLevel == 1 and lowSet.slots[1] == low[1].id, "the set it starts keeps the range")
    UnitLevel = oldLevel
    T.store().builds, T.store().selected = {}, nil
    F.ShowTab("tracker"); F.ShowTab("gear")
    local hunterStore = T.store()
    Pick("HeadSlot", 18421)
    local started = hunterStore.builds[#hunterStore.builds]
    assert(started and started.name == "New gear set" and started.slots[1] == 18421 and hunterStore.selected == started.id,
        "picking an item from the welcome starts a set with it")
    assert(not W.card:IsShown(), "the set opens without the card flashing back")
    Run(W.driver)
    assert(not W.card:IsShown() and not W.away, "and the card stays away")
    hunterStore.builds, hunterStore.selected = {}, nil
    F.ShowTab("tracker"); F.ShowTab("gear")
    assert(W.card:IsShown() and cardAlpha == 1, "back on the welcome for the import checks")
    local frameAlpha = 1
    WI.frame.SetAlpha = function(_, a) frameAlpha = a end
    local function Step(share) WI.driver:GetScript("OnUpdate")(WI.driver, WI.FADE * share) end
    click(W.import)
    assert(frameAlpha < 0.01 and cardAlpha == 1 and WI.driver:GetScript("OnUpdate"), "the window starts faded out, the card still there")
    Step(0.2)
    assert(frameAlpha < 0.01 and cardAlpha < 1, "the card leaves first")
    Step(0.4)
    assert(frameAlpha > 0 and frameAlpha < 1 and not W.card:IsShown(), "the window follows once the card is nearly gone")
    Run(WI.driver)
    assert(frameAlpha == 1 and WI.p == 1 and WI.frame:IsShown(), "the window ends fully shown")
    click(WI.cancel)
    Step(0.4)
    assert(WI.frame:IsShown() and frameAlpha > 0 and frameAlpha < 1 and not W.card:IsShown(), "Cancel fades the window out first")
    Run(WI.driver)
    assert(not WI.frame:IsShown() and W.card:IsShown() and cardAlpha == 1 and not WI.hidCard, "then the welcome comes back")
    click(W.import); Step(0.3); click(WI.cancel); click(W.import)
    Run(WI.driver)
    assert(WI.p == 1 and frameAlpha == 1 and not W.card:IsShown(), "reopening mid-way turns the same timeline around")
    text(WI.box, "BDwRAFAjEE8CMwUgAFUBACIfBfAAgQBV9QA8KgIAV0SDAFX4AFhHhQBV-QBOOQYAVfKHADrWADwqiABV8wA2QokAVfQATiqKADrXAE4sCwBIRAwASEQNAC4nDgA2jY8ANBwANjqQADEuAE5CkQBH2ABOQpIACDQAMKw")
    click(WI.import)
    assert(not W.card:IsShown(), "the imported set opens without the welcome flashing back")
    Run(WI.driver); Run(W.driver)
    assert(not W.card:IsShown() and not WI.frame:IsShown() and not WI.hidCard, "it stays away once the set is open")
    W.card.SetAlpha, W.card.GetAlpha, WI.frame.SetAlpha = nil, nil, nil
    hunterStore.builds, hunterStore.selected = {}, nil
    T.model.SetUnit = nil
    UnitName, UnitClass, UnitFactionGroup = oldName, oldClass, oldFaction
    F.ShowTab("tracker")
    print("  welcome card: character scene, Wowhead import, current gear start, two buttons only")
end

-- The 2026-10-23 layout: slot rows, the sets drawer and its cards, the switcher, the band, stage controls.
do
    local D = ForeverGoalTrackerDB
    local Cat = F.GearCatalog
    local SD = T.drawer
    local oldClassL, oldCount, oldInv = UnitClass, GetItemCount, GetInventoryItemID
    UnitName = function() return "LayoutOwner" end
    UnitClass = function() return "Warrior", "WARRIOR" end
    F.ShowTab("gear")
    -- the drawer slides at Materials' pace and remembers being closed
    F.SetSetting("celebrations", "on")
    SD.SetOpen(false)
    local step = SD.driver:GetScript("OnUpdate")
    assert(step, "closing the drawer slides")
    step(SD.driver, 0.2)
    assert(SD.fraction > 0 and SD.fraction < 1, "part way through the slide")
    step(SD.driver, 1)
    assert(SD.fraction == 0 and not SD.driver:GetScript("OnUpdate"), "the slide ends closed and stops")
    assert(D.gearPlanner.prefs.setsClosed, "closed is remembered")
    F.ShowTab("tracker"); F.ShowTab("gear")
    assert(not SD.open and SD.fraction == 0, "the drawer comes back closed")
    -- one width always; with no room beside the stage it opens over it instead of refusing
    assert(SD.Beside(1, 1200) == SD.width, "a wide window: the drawer sits beside the stage")
    assert(SD.Beside(1, SD.STAGE + 100) == 100, "a narrow one: the stage keeps its least width and the drawer covers the rest")
    assert(SD.Beside(0, 200) == 22, "closed, it is the strip")
    -- the character holds one size through the slide and fills the stage again after
    SD.SetOpen(true)
    assert(T.model.frozenW, "the character's frame holds still while the drawer slides")
    SD.driver:GetScript("OnUpdate")(SD.driver, 1)
    assert(not T.model.frozenW and not SD.driver:GetScript("OnUpdate"), "and fills the stage when the slide ends")
    SD.SetOpen(false); SD.driver:GetScript("OnUpdate")(SD.driver, 1)
    F.SetSetting("celebrations", "off")
    SD.SetOpen(true)
    assert(SD.open and SD.fraction == 1 and not D.gearPlanner.prefs.setsClosed and not SD.driver:GetScript("OnUpdate"),
        "instant with Celebrations off")
    F.SetSetting("celebrations", "on")
    -- rows: an empty slot names itself; a filled one shows its item
    T.new(); text(T.name, "Layout one")
    local one = T.store().builds[#T.store().builds]
    assert(T.slots.WaistSlot.slotName:GetText() == "WAIST" and T.slots.WaistSlot.itemName:GetText() == "", "an empty row names its slot")
    Pick("HeadSlot", 16866)
    assert(T.slots.HeadSlot.itemName:GetText() == "Helm of Might", "a filled row shows the item")
    -- a two-hand weapon fills both hands: the off hand says so and opens nothing
    Pick("MainHandSlot", 22314)
    local off = T.slots.SecondaryHandSlot
    assert(off.blocked and (off.slotName:GetText() or ""):find("TWO-HAND WEAPON", 1, true), "the off hand under a two-hander is blocked")
    click(off)
    assert(not T.picker:IsShown(), "a blocked off hand opens nothing")
    -- the owned check: in bags, bank or worn
    local seen
    T.slots.HeadSlot.owned.SetAlpha = function(_, a) seen = a end
    GetItemCount = function(id) return id == 16866 and 1 or 0 end
    F.ShowTab("tracker"); F.ShowTab("gear")
    assert(seen == 1, "an item you have gets the check")
    GetItemCount = function() return 0 end
    F.ShowTab("tracker"); F.ShowTab("gear")
    assert(seen == 0, "an item you don't have does not")
    T.slots.HeadSlot.owned.SetAlpha = nil
    -- the picker marks the set's item and what the character wears
    GetInventoryItemID = function(_, slot) if slot == 1 then return 16866 end end
    click(T.slots.HeadSlot); text(T.search, "#16866")
    assert(T.results[1].tag:GetText() == "Selected" and T.results[1].worn:GetText() == "EQUIPPED", "the worn, planned helm says both")
    T.clickAway:GetScript("OnEvent")()
    GetInventoryItemID = oldInv
    -- an enhancement shows its icon in a green frame; the totals add it to the stat; right-click removes it
    local band = T.band
    local function TotalsRow(label)
        for i = 1, band.count or 0 do
            if band.rows[i].name:GetText() == label then return band.rows[i] end
        end
    end
    Pick("WristSlot", 16861)
    local square = T.slots.WristSlot.enchant
    Track(square.applied); Track(square)
    F.ShowTab("tracker"); F.ShowTab("gear")
    assert(square:IsShown() and not square.applied:IsShown(), "a bracer with nothing planned shows the square")
    click(square); text(T.search, "superior strength"); click(T.results[1])
    assert(square.applied:IsShown() and not square:IsShown(), "a planned enhancement replaces the square")
    assert(square.applied.icon:GetTexture(), "it shows the enhancement's icon")
    local strength = TotalsRow("Strength")
    assert(strength and strength.bonus:GetText() == "+9" and (tonumber(strength.value:GetText()) or 0) > 0,
        "the Strength row has the items' total and the enhancement's +9 beside it")
    square.applied:GetScript("OnClick")(square.applied, "RightButton")
    assert(not (one.enchants and one.enchants[9]) and square:IsShown() and not square.applied:IsShown(),
        "right-clicking the icon removes it and the square returns")
    assert(TotalsRow("Strength").bonus:GetText() == "", "and its bonus leaves the totals")
    -- effects written either way round, joined or not
    local E = T.enhancement
    local hit, agi = E.Effects({ text = "+3% Hit" })[1], E.Effects({ text = "Agility +7" })[1]
    assert(hit[1] == 3 and hit[2] == "%" and agi[1] == 7 and agi[3] == "Agility", "both ways round")
    local both = E.Effects({ text = "Attack Power +10 and Armor +40" })
    assert(#both == 2 and both[1][3] == "Attack Power" and both[2][1] == 40, "joined effects split")
    assert(#E.Effects({ text = "+18 Spell Damage and Healing" }) == 1, "a stat with 'and' in its name stays whole")
    assert(#E.Effects({ text = "Crusader" }) == 0, "named effects add nothing to the totals")
    assert(E.Kind({ name = "Rugged Armor Kit" }) == "Armor kit" and E.Kind({ name = "Sniper Scope" }) == "Scope"
        and E.Kind({ name = "Lesser Arcanum of Voracity" }) == "Arcanum" and E.Kind({ name = "x", enchanting = true }) == "Enchant",
        "every kind of enhancement is named")
    -- the totals: closed until the tab opens them, closed again the next time the planner opens
    Track(band.panel)
    assert(not band.panel:IsShown() and not band.open, "the totals start closed")
    click(band.tab)
    assert(band.panel:IsShown() and band.open, "the tab opens them")
    assert((band.summary:GetText() or ""):find("slots filled", 1, true), "the summary line sits under the stats")
    assert((band.summary:GetText() or ""):find("slots filled\nAverage item level %d+"), "the average item level is on its own line")
    click(band.tab)
    assert(not band.panel:IsShown(), "and closes them")
    click(band.tab); F.ShowTab("tracker"); F.ShowTab("gear")
    assert(not band.panel:IsShown() and not band.open, "reopening the planner starts them closed")
    -- an empty set says so once, briefly, with no summary line under it
    band.Paint({ slots = {} }, nil)
    assert(band.count == 1 and band.rows[1].name:GetText() == "No items added yet." and (band.summary:GetText() or "") == "",
        "the empty totals say so once")
    -- a stat only an enhancement gives gets its own row, with no item total
    local fake = { text = "+40 Armor" }
    local oldEnchant = Cat.Enchant
    Cat.Enchant = function(spell) if spell == -1 then return fake end; return oldEnchant(spell) end
    band.Paint({ slots = {}, enchants = { [5] = -1 } }, "")
    local armor = TotalsRow("Armor")
    assert(armor and armor.value:GetText() == "" and armor.bonus:GetText() == "+40", "an enhancement-only stat")
    Cat.Enchant = oldEnchant
    F.ShowTab("tracker"); F.ShowTab("gear")
    -- set cards: hovering shows Rename and Delete; delete takes two clicks
    T.new(); text(T.name, "Layout two")
    local two = T.store().builds[#T.store().builds]
    local card
    for _, row in ipairs(T.rows) do if row.build == two then card = row end end
    assert(card, "the new set has a card")
    Track(card.ren); Track(card.del)
    card:GetScript("OnEnter")(card)
    assert(card.ren:IsShown() and card.del:IsShown(), "hovering a card shows Rename and Delete")
    local count = #T.store().builds
    click(card.del)
    assert(#T.store().builds == count and card.del.armed, "delete asks again")
    click(card.del)
    assert(#T.store().builds == count - 1, "the second click deletes the set")
    -- the switcher lists every set and switches
    Track(T.switchMenu)
    click(T.switch)
    assert(T.switchMenu:IsShown(), "the chevron opens the set list")
    local target
    for _, r in ipairs(T.switchMenu.rows) do if r.build == one then target = r end end
    assert(target, "the list holds the other set")
    click(target)
    assert(T.setTitle:GetText() == "Layout one" and not T.switchMenu:IsShown(), "picking a set switches to it")
    -- Remove all from My Goals keeps the sets; Delete all takes two clicks and clears them
    for _, row in ipairs(T.rows) do Track(row.bar) end
    click(T.add)
    assert(D.active[one.goalId], "added")
    local tracked
    for _, row in ipairs(T.rows) do if row.build == one then tracked = row end end
    assert(tracked and tracked.bar:IsShown(), "a set in My Goals shows its progress on its card")
    assert(T.band.goal:GetParent() == T.slotList.scroll:GetParent(), "In My Goals sits in the Equipment panel")
    click(T.removeAll)
    assert(not D.active[one.goalId] and #T.store().builds > 0, "every set leaves My Goals and stays planned")
    click(T.deleteAll)
    assert(#T.store().builds > 0, "delete all asks again")
    click(T.deleteAll)
    assert(#T.store().builds == 0 and not D.progress[one.goalId], "the second click deletes every set and its progress")
    -- the stage: right-drag moves the character
    T.new(); text(T.name, "Layout three"); Pick("HeadSlot", 16866)
    local moved
    T.model.SetPosition = function(_, x, y, z) moved = { y, z } end
    local cx, cy = 0, 0
    local oldCursor, oldDown = GetCursorPosition, IsMouseButtonDown
    GetCursorPosition = function() return cx, cy end
    IsMouseButtonDown = function() return true end
    T.model.GetEffectiveScale = function() return 1 end
    T.modelArea.GetHeight = function() return 500 end
    T.model:GetScript("OnMouseDown")(T.model, "RightButton")
    cx, cy = 50, 30
    T.model:GetScript("OnUpdate")(T.model, 0.02)
    assert(moved and moved[1] > 0 and moved[2] > 0, "right-drag moves the character with the cursor")
    T.model:GetScript("OnMouseUp")(T.model)
    assert(not T.model:GetScript("OnUpdate"), "letting go stops moving")
    GetCursorPosition, IsMouseButtonDown = oldCursor, oldDown
    T.model.SetPosition, T.model.GetEffectiveScale, T.modelArea.GetHeight = nil, nil, nil
    -- rename from the title: Enter keeps the name
    click(T.editName)
    text(T.name, "Layout renamed")
    T.name:GetScript("OnEnterPressed")(T.name)
    T.name:GetScript("OnEditFocusLost")(T.name)
    assert(T.store().builds[#T.store().builds].name == "Layout renamed" and T.setTitle:GetText() == "Layout renamed", "Enter renames the set")
    -- a set in My Goals: renaming it renames its card in the My Goals list too
    local oldAfter = C_Timer.After
    C_Timer.After = function(_, fn) fn() end
    click(T.add)
    local renamed = T.store().builds[#T.store().builds]
    click(T.editName); text(T.name, "Layout renamed again")
    T.name:GetScript("OnEnterPressed")(T.name); T.name:GetScript("OnEditFocusLost")(T.name)
    local card = F.RailUI.rows[renamed.goalId]
    assert(card and card.name:GetText() == "Layout renamed again", "the My Goals card shows the new name: "
        .. tostring(card and card.name:GetText()))
    C_Timer.After = oldAfter
    UnitClass, GetItemCount = oldClassL, oldCount
    UnitName = oldName
    F.ShowTab("tracker")
    print("  layout: drawer slide, slot rows, blocked off hand, owned and equipped marks, enhancement icons, totals tab, cards, switcher, delete all, move")
end

-- Out-of-date reminder: a higher version heard from another player says so once, nothing else does.
do
    local V = F.VersionCheck
    local D = ForeverGoalTrackerDB
    local lines, oldPrint = {}, print
    print = function(...) lines[#lines + 1] = table.concat({ tostring((...)) }, " ") end
    local oldMeta = C_AddOns and C_AddOns.GetAddOnMetadata
    C_AddOns = C_AddOns or {}
    C_AddOns.GetAddOnMetadata = function() return "2.16.0" end
    V.warned, D.outdatedWarned = nil, nil
    D.settings = D.settings or {}
    D.settings.versionReminder = nil
    assert(V.Number("2.16.0") == 2016000 and V.Number("10.0.1") == 10000001 and V.Number("2.16") == nil
        and V.Number("2.16.0 beta") == nil and V.Number("x") == nil, "versions compare by number and reject anything else")
    assert(not V.Receive("OTHER", "9.9.9") and not V.Receive(V.PREFIX, "2.16.0") and not V.Receive(V.PREFIX, "2.15.2")
        and not V.Receive(V.PREFIX, "garbage") and #lines == 0, "equal, older, unrelated and malformed versions say nothing")
    assert(V.Receive(V.PREFIX, "2.17.0") and #lines == 1, "a newer version speaks")
    assert(lines[1]:find("Forever Goal Tracker", 1, true) and lines[1]:find("out of date", 1, true)
        and lines[1]:find("CurseForge", 1, true) and not lines[1]:find("you have", 1, true), "the message: " .. lines[1])
    assert(not V.Receive(V.PREFIX, "2.18.0") and #lines == 1, "once per session")
    V.warned = nil
    assert(not V.Receive(V.PREFIX, "2.17.0") and #lines == 1 and D.outdatedWarned == "2.17.0", "not again for a version it already named")
    V.warned = nil
    assert(V.Receive(V.PREFIX, "2.18.0") and #lines == 2, "a still newer version speaks again")
    D.settings.versionReminder = false
    V.warned, D.outdatedWarned = nil, nil
    assert(not V.Receive(V.PREFIX, "9.0.0") and #lines == 2, "the Settings switch turns it off")
    D.settings.versionReminder = nil
    -- sharing: guild and group, throttled, never in combat
    local sent = {}
    C_ChatInfo = C_ChatInfo or {}
    local oldSend = C_ChatInfo.SendAddonMessage
    C_ChatInfo.SendAddonMessage = function(prefix, text, channel) sent[#sent + 1] = prefix .. ":" .. text .. ":" .. channel end
    V.sent = {}
    V.Send("GUILD"); V.Send("GUILD")
    assert(#sent == 1 and sent[1] == "FGTVER:2.16.0:GUILD", "the version goes to the guild, once within the throttle: " .. tostring(sent[1]))
    local oldCombat = InCombatLockdown
    InCombatLockdown = function() return true end
    V.Send("PARTY")
    InCombatLockdown = oldCombat
    assert(#sent == 1, "nothing is sent in combat")
    D.settings.versionReminder = false
    V.Send("RAID")
    assert(#sent == 1, "nothing is sent with reminders off")
    D.settings.versionReminder = nil
    C_ChatInfo.SendAddonMessage = oldSend
    C_AddOns.GetAddOnMetadata = oldMeta
    print = oldPrint
    print("  version reminder: newer versions speak once, sharing is throttled and quiet")
end

-- Import from Wowhead: Karl's Rogue link (2026-10-27) is read record by record and becomes a new set.
do
    local Cat, WI = F.GearCatalog, T.wowhead
    local CODE = "BDwRAFAjEE8CMwUgAFUBACIfBfAAgQBV9QA8KgIAV0SDAFX4AFhHhQBV-QBOOQYAVfKHADrWADwqiABV8wA2QokAVfQATiqKADrXAE4sCwBIRAwASEQNAC4nDgA2jY8ANBwANjqQADEuAE5CkQBH2ABOQpIACDQAMKw"
    local URL = "https://www.wowhead.com/classic/gear-planner/rogue/human/" .. CODE
    local expected = { { 1, 22005, 15402 }, { 2, 22340 }, { 3, 22008, 22599 }, { 5, 22009, 20025 }, { 6, 22002 },
        { 7, 15062, 15402 }, { 8, 22003, 13890 }, { 9, 22004, 20010 }, { 10, 15063, 20012 }, { 11, 18500 }, { 12, 18500 },
        { 13, 11815 }, { 14, 13965 }, { 15, 13340, 13882 }, { 16, 12590, 20034 }, { 17, 18392, 20034 }, { 18, 2100, 12460 } }
    local r = assert(Cat.ReadWowheadLink(URL))
    assert(r.class == "ROGUE" and r.level == 60 and #r.records == #expected, "the link's class, level and 17 items")
    for i, e in ipairs(expected) do
        local got = r.records[i]
        assert(got.slot == e[1] and got.item == e[2] and got.spell == e[3],
            "record " .. i .. ": slot " .. got.slot .. " item " .. got.item .. " enchant " .. tostring(got.spell))
    end
    assert(r.slots[16] == 12590 and r.enchants[16] == 20034, "Felstriker comes across with Crusader")
    local bare = assert(Cat.ReadWowheadLink("  " .. CODE .. "\n"))
    assert(#bare.records == 17 and bare.class == nil, "the code alone works too, without a class")
    -- what it can't read is refused with a reason, never guessed at
    assert(Cat.ReadWowheadLink("") == nil and select(2, Cat.ReadWowheadLink("")) == nil, "an empty box says nothing")
    assert(select(2, Cat.ReadWowheadLink("hello there")) == Cat.WOWHEAD_NOT_A_LINK, "plain text is not a link")
    assert(select(2, Cat.ReadWowheadLink("C" .. CODE:sub(2))) == Cat.WOWHEAD_UNKNOWN, "another format version is refused")
    assert(select(2, Cat.ReadWowheadLink(CODE:sub(1, -5))) == Cat.WOWHEAD_UNKNOWN, "a cut-off link is refused")
    assert(select(2, Cat.ReadWowheadLink("https://www.wowhead.com/classic/gear-planner/rogue/human")) == "This link has no gear in it.",
        "an empty planner link says so")
    -- items the planner doesn't know are listed, and their enchants left out
    local oldGet = Cat.Get
    Cat.Get = function(id) if id == 22005 then return nil end return oldGet(id) end
    local partial = assert(Cat.ReadWowheadLink(URL))
    Cat.Get = oldGet
    assert(partial.missing[1] == 22005 and not partial.slots[1] and partial.skipped >= 1, "an unknown item is named, not imported")

    -- the window: a preview first, then a new set (the open set is left alone)
    Track(WI.frame)
    F.ShowTab("gear")
    local store = T.store()
    local before, open = #store.builds, store.selected
    local openBuild
    for _, b in ipairs(store.builds) do if b.id == open then openBuild = b end end
    local openSlots = openBuild and openBuild.slots[1]
    local windowAlpha
    WI.frame.SetAlpha = function(_, a) windowAlpha = a end
    click(WI.menu)
    assert(WI.frame:IsShown(), "the menu entry opens the import window")
    WI.driver:GetScript("OnUpdate")(WI.driver, WI.FADE * 0.1)
    assert(WI.lead == 0 and windowAlpha > 0, "with no welcome card the window starts at once")
    WI.frame.SetAlpha = nil
    text(WI.box, "hello there")
    assert(WI.result == nil and (WI.preview:GetText() or ""):find(Cat.WOWHEAD_NOT_A_LINK, 1, true), "a bad paste explains itself")
    click(WI.import)
    assert(#store.builds == before, "Import does nothing until the link reads")
    text(WI.box, URL)
    local preview = WI.preview:GetText() or ""
    assert(preview:find("Rogue · Level 60 · 17 items", 1, true), "the preview counts what comes across: " .. preview)
    assert(preview:find("This set is for a Rogue", 1, true), "a Warrior is told the set is for a Rogue")
    click(WI.import)
    local made = store.builds[#store.builds]
    assert(#store.builds == before + 1 and made.name == "Wowhead Rogue" and made.level == 60, "a new set named for the class")
    assert(made.slots[16] == 12590 and made.enchants and made.enchants[16] == 20034, "items and enchants are in the new set")
    assert(store.selected == made.id, "the new set opens")
    for _ = 1, 60 do local fn = WI.driver:GetScript("OnUpdate"); if not fn then break end; fn(WI.driver, 0.05) end
    assert(not WI.frame:IsShown(), "the window fades away")
    if openBuild then assert(openBuild.slots[1] == openSlots, "the set that was open is untouched") end
    for i, b in ipairs(store.builds) do if b == made then table.remove(store.builds, i) end end
    store.selected = open
    F.ShowTab("tracker")
    print("  Wowhead import: reads the link, refuses what it can't, previews and makes a new set")
end
