local ADDON, FGT = ...
local U = FGT.MaterialsUI
local P = CreateFrame("Frame", nil, U.main)
FGT.GearPlanner = P
P:SetAllPoints(U.main)
P:Hide()
local tab = FGT.NewPlannerTab("Gear Planner")
FGT.gearTab = tab
tab:SetPoint("LEFT", FGT.libraryTab, "RIGHT", 6, 0)
tab:SetScript("OnClick", function() FGT.ShowTab("gear") end)

-- Match the native character panel for every empty equipment slot.
-- Use slot names (HeadSlot, Finger0Slot, etc.) when adding planner slots.
function FGT.GearPlannerSlotTexture(slotName)
    local _, texture = GetInventorySlotInfo(slotName)
    if (type(texture) == "string" and texture ~= "") or (type(texture) == "number" and texture > 0) then
        return texture
    end
    return "Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. slotName:gsub("%d", ""):gsub("Slot$", "")
end
local slotIds = { HeadSlot=1, NeckSlot=2, ShoulderSlot=3, ShirtSlot=4, ChestSlot=5,
    WaistSlot=6, LegsSlot=7, FeetSlot=8, WristSlot=9, HandsSlot=10,
    Finger0Slot=11, Finger1Slot=12, Trinket0Slot=13, Trinket1Slot=14,
    BackSlot=15, MainHandSlot=16, SecondaryHandSlot=17, RangedSlot=18, TabardSlot=19 }
local byId = {}

local catalogue = {
    { class = "WARRIOR", name = "Helm of Might", id = 16866, icon = "Interface\\Icons\\inv_helmet_09", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "PALADIN", name = "Lawbringer Helm", id = 16854, icon = "Interface\\Icons\\inv_helmet_05", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "HUNTER", name = "Giantstalker's Helmet", id = 16846, icon = "Interface\\Icons\\inv_helmet_05", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "ROGUE", name = "Nightslayer Cover", id = 16821, icon = "Interface\\Icons\\inv_helmet_41", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "PRIEST", name = "Circlet of Prophecy", id = 16813, icon = "Interface\\Icons\\inv_helmet_34", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "SHAMAN", name = "Earthfury Helmet", id = 16842, icon = "Interface\\Icons\\inv_helmet_09", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "MAGE", name = "Arcanist Crown", id = 16795, icon = "Interface\\Icons\\inv_helmet_53", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "WARLOCK", name = "Felheart Horns", id = 16808, icon = "Interface\\Icons\\inv_helmet_08", slot = "HeadSlot", source = "Garr — Molten Core" },
    { class = "DRUID", name = "Cenarion Helm", id = 16834, icon = "Interface\\Icons\\inv_helmet_09", slot = "HeadSlot", source = "Garr — Molten Core" },

}
-- Reuse the Library's Tier 3 armor tuples; one canonical item/icon source.
local tier3Slots = { "HeadSlot", "ShoulderSlot", "ChestSlot", "HandsSlot", "LegsSlot", "WaistSlot", "WristSlot", "FeetSlot" }
local tier3 = FGT.armorCollections and FGT.armorCollections.tier3
for _, section in ipairs(tier3 and tier3.sections or {}) do
    local class = section.name:match("^(.-) %- ")
    for i, piece in ipairs(section.pieces or {}) do
        catalogue[#catalogue + 1] = { class = class:upper(), name = piece.name,
            id = piece.auto.item, icon = "Interface\\Icons\\" .. piece.icon,
            slot = tier3Slots[i], source = "Tier 3 turn-in — Light's Hope Chapel" }
    end
end
-- Classic item tooltip IDs/names/icons verified against Wowhead; Forever sources unconfirmed.
local rings = {
    { "WARRIOR", 23059, "Ring of the Dreadnaught" }, { "ROGUE", 23060, "Bonescythe Ring" },
    { "PRIEST", 23061, "Ring of Faith" }, { "MAGE", 23062, "Frostfire Ring" },
    { "WARLOCK", 23063, "Plagueheart Ring" }, { "DRUID", 23064, "Ring of the Dreamwalker" },
    { "SHAMAN", 23065, "Ring of the Earthshatterer" }, { "PALADIN", 23066, "Ring of Redemption" },
    { "HUNTER", 23067, "Ring of the Cryptstalker" },
}
for _, ring in ipairs(rings) do
    catalogue[#catalogue + 1] = { class = ring[1], id = ring[2], name = ring[3], slot = "FingerSlot",
        icon = "Interface\\Icons\\inv_jewelry_ring_51naxxramas", unique = true,
        source = "Kel'Thuzad — Naxxramas" }
end
for _, item in ipairs(catalogue) do byId[item.id] = item end
local function SlotMatches(item, slot)
    return item.slot == slot or (item.slot == "FingerSlot" and (slot == "Finger0Slot" or slot == "Finger1Slot"))
end
local function Store()
    local db = ForeverGoalTrackerDB
    db.gearPlanner = db.gearPlanner or { version = 1, characters = {} }
    local key = U.charKey()
    local chars = db.gearPlanner.characters
    chars[key] = chars[key] or { nextId = 1, builds = {} }
    return chars[key]
end
-- Planner goals stay out of the Library; their stable IDs survive renames and reloads.
local function SyncGoal(build, ownerKey)
    if not build.tracked or not build.id then return end
    local DB = ForeverGoalTrackerDB
    local ownerId = ownerKey:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)
    local id = "planner_" .. ownerId .. "_" .. build.id
    local goal = FGT.GoalById(id)
    local old, credit = build.goalItems or {}, {}
    local progress = DB.progress[id] or {}
    for i, item in ipairs(old) do
        if progress[i] then credit[item.slot .. ":" .. item.id] = true end
    end
    if not goal then
        goal = { id = id, category = "Item Set", plannerOwner = ownerKey,
            difficulty = "Varies", duration = "Varies", steps = {} }
        FGT.goals[#FGT.goals + 1] = goal
        FGT.goalIndex = nil
    end
    goal.name = build.name
    goal.steps, goal.tips, build.goalItems = {}, {}, {}
    local nextProgress = {}
    for slot = 1, 19 do
        local item = byId[build.slots[slot]]
        if item then
            local step = { text = "Collect " .. item.name,
                auto = { item = item.id, forCharacter = ownerKey }, plannerSlot = slot,
                tip = item.source }
            goal.steps[#goal.steps + 1] = step
            build.goalItems[#build.goalItems + 1] = { slot = slot, id = item.id }
            goal.tips[#goal.tips + 1] = "{item:" .. item.id .. ":" .. item.name .. "}: " .. step.tip
            if credit[slot .. ":" .. item.id] then nextProgress[#goal.steps] = true end
            U.watch[item.id] = true
        end
    end
    DB.progress[id] = nextProgress
    goal.icon = goal.steps[1] and byId[goal.steps[1].auto.item].icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    build.goalId = id
    FGT.EnsureGoalRow(goal)
    return goal
end
function FGT.LoadPlannerGoals()
    local DB = ForeverGoalTrackerDB
    for key, store in pairs(DB.gearPlanner and DB.gearPlanner.characters or {}) do
        for _, build in ipairs(store.builds or {}) do SyncGoal(build, key) end
    end
end
local function Label(parent, text, size, x, y)
    local f = U.font(parent, size or 12)
    f:SetPoint("TOPLEFT", x, y); f:SetText(text)
    return f
end
local function Button(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, height or 28); U.etch(b, U.styles.button)
    b.text = U.font(b, 12); b.text:SetPoint("CENTER"); b.text:SetText(text)
    b:SetScript("OnEnter", function() b:SetEtch(b.chosen and U.styles.rowSel or U.styles.btnHover) end)
    b:SetScript("OnLeave", function() b:SetEtch(b.chosen and U.styles.rowSel or U.styles.button) end)
    return b
end
local left = CreateFrame("Frame", nil, P, "BackdropTemplate")
left:SetPoint("TOPLEFT", U.list, "TOPLEFT")
left:SetPoint("BOTTOMLEFT", U.list, "BOTTOMLEFT")
left:SetWidth(FGT.trackerTab:GetWidth() + FGT.libraryTab:GetWidth() + 56)
U.etch(left, U.styles.panel)
local right = CreateFrame("Frame", nil, P, "BackdropTemplate")
right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
right:SetPoint("BOTTOMRIGHT", U.main, "BOTTOMRIGHT", -16, 16)
U.etch(right, U.styles.panel)
Label(left, "My Gear Sets", 16, 16, -16)
local owner = Label(left, "", 11, 16, -40)
local new = Button(left, "+ New build", 140); new:SetPoint("TOPLEFT", 16, -66)
local list = U.scroll(left, 0, 0, 0, 0)
-- Use an independent clipped viewport; no dependency on the guide layout.
list.scroll:ClearAllPoints(); list.scroll:SetPoint("TOPLEFT", 12, -146)
list.scroll:SetPoint("BOTTOMRIGHT", -20, 16)
local add = Button(left, "Add to Goals", 140); add:SetPoint("TOPLEFT", 16, -102)
local rows, selected, draft, changing = {}, nil, nil, false
local draftOwner
local header = CreateFrame("Frame", nil, right)
header:SetAllPoints(); header:SetFrameLevel(right:GetFrameLevel() + 12)
local name = CreateFrame("EditBox", nil, header, "InputBoxTemplate")
name:SetAutoFocus(false); name:SetMaxLetters(60); name:SetHeight(28)
name:SetPoint("TOP", right, "TOP", 0, -24)
name:SetWidth(340)
name:SetFontObject("GameFontHighlight")
local nameLabel = Label(header, "Set name", 10, 22, -6)
nameLabel:ClearAllPoints(); nameLabel:SetPoint("BOTTOMLEFT", name, "TOPLEFT", 0, 4)
local status = U.font(header, 10)
status:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
right:SetScript("OnSizeChanged", function(_, w) name:SetWidth(math.min(340, math.max(120, w - 48))) end)
local empty = Label(header, "Create a build to begin.", 14, 20, -100)
local modelArea = CreateFrame("Frame", nil, right)
modelArea:SetPoint("TOPLEFT", 4, -4); modelArea:SetPoint("BOTTOMRIGHT", -4, 4)
modelArea:SetClipsChildren(true)
-- Blizzard Classic DressUpFrames.xml assembles a 318 x 383 background.
-- The right column is only 62 wide; equal quarters stretch its artwork.
local backgroundTiles = {
    { 0, 0, 256, 255 }, { 256, 0, 62, 255 },
    { 0, 255, 256, 128 }, { 256, 255, 62, 128 },
}
local _, race = UnitRace("player")
local background = CreateFrame("Frame", nil, modelArea)
background:SetAllPoints() -- child frame lets modelArea clip the cropped texture regions
for i = 1, 4 do
    local bg = background:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. (race or "Orc") .. i)
    bg:SetDesaturated(true)
    bg:SetAlpha(0.18)
    bg:SetPoint("TOPLEFT", modelArea, "TOPLEFT", 0, 0)
    -- Layout is set on resize so the quadrants remain a continuous background.
    modelArea["bg" .. i] = { texture = bg, rect = backgroundTiles[i] }
end
local model = CreateFrame("DressUpModel", nil, modelArea)
model:SetFrameLevel(background:GetFrameLevel() + 1)
if model.SetAutoDress then model:SetAutoDress(false) end
model:SetAllPoints(modelArea)
model:EnableMouse(true); model:EnableMouseWheel(true)
-- A separate veil above the model protects labels without dimming the controls.
local textVeil = CreateFrame("Frame", nil, modelArea)
textVeil:SetAllPoints(); textVeil:SetFrameLevel(model:GetFrameLevel() + 1)
local textShades = {}
for i = 1, 4 do
    local t = textVeil:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(1, 1, 1, 1)
    textShades[i] = t
end
local veilColor = {0.025, 0.022, 0.018}
local function PaintTextVeil(value)
    local color = veilColor
    local strength = 0.55 + value * 0.3
    U.gradient(textShades[1], color, color, strength, 0)
    U.gradient(textShades[2], color, color, 0, strength)
    FGT.PopoutUI.vgradient(textShades[3], color, color, strength, 0)
    FGT.PopoutUI.vgradient(textShades[4], color, color, 0, strength * 0.85)
end
local zoom, facing, dragX = 0, 0, nil
local cameraAspect = 1
local MAX_ZOOM = 1
local selectedSlot
local slotButtons = {}
local camera = CreateFrame("Frame", nil, P)
-- Model-space offsets keep the drawing frame full-panel, avoiding clipped armor.
-- Positive Z raises the model; a small negative offset lowers focused armor.
local focusProfiles = {
    HeadSlot = {0.75, 0, -0.08},
    ShoulderSlot = {0.70, 0.32, 0.02}, ChestSlot = {0.58, 0, 0.28},
    ShirtSlot = {0.58, 0, 0.28}, TabardSlot = {0.50, 0, 0.35},
    WristSlot = {0.68, 0.40, 0.65}, HandsSlot = {0.68, 0.40, 0.78},
    WaistSlot = {0.60, 0, 0.65}, LegsSlot = {0.48, 0, 0.95},
    FeetSlot = {0.68, 0.18, 1.35}, BackSlot = {0.68, 0, 0.30},
}
-- Dwarf male has a shorter torso and lower hands than the general profile.
-- Tuned on Swagrid in the Forever beta; independent of other bodies.
local dwarfMaleFocus = {
    ChestSlot = {0.70, 0, 0.12}, ShirtSlot = {0.70, 0, 0.12},
    TabardSlot = {0.62, 0, 0.16}, BackSlot = {0.74, 0, 0.10},
    WristSlot = {0.68, 0.32, 0.30},
    HandsSlot = {0.64, 0.32, 0.31}, WaistSlot = {0.60, 0, 0.20},
    LegsSlot = {0.64, 0, 0.48}, FeetSlot = {0.66, 0.18, 0.66},
}
local offsetY, offsetZ, targetZoom, targetY, targetZ = 0, 0, 0, 0, 0
local function Ease(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end
local function ApplyZoom(value)
    zoom = value
    PaintTextVeil(value)
    if model.SetCamDistanceScale then model:SetCamDistanceScale((1.3 - math.max(0, value - 0.8) * 2) * cameraAspect) end
    if model.SetPortraitZoom then model:SetPortraitZoom(math.min(0.8, value)) end
    if model.SetPosition then model:SetPosition(0, offsetY, offsetZ) end
end
local function MoveCamera(target, y, z, duration)
    local start, startY, startZ, elapsed = zoom, offsetY, offsetZ, 0
    targetZoom, targetY, targetZ = target, y, z
    camera:SetScript("OnUpdate", nil)
    if FGT.Setting("celebrations") == "off" then
        offsetY, offsetZ = y, z; ApplyZoom(target); return
    end
    camera:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / duration)
        local eased = Ease(t)
        offsetY = startY + (y - startY) * eased
        offsetZ = startZ + (z - startZ) * eased
        ApplyZoom(start + (target - start) * eased)
        if t == 1 then camera:SetScript("OnUpdate", nil) end
    end)
end
local turn = CreateFrame("Frame", nil, P)
local function TurnTo(target)
    turn:SetScript("OnUpdate", nil)
    -- Choose the shortest arc even after several manual rotations.
    local start = facing
    local delta = (target - start + math.pi) % (2 * math.pi) - math.pi
    -- Half-turns are equally short either way; use Karl's preferred direction.
    if math.abs(delta + math.pi) < 0.000001 then delta = math.pi end
    if FGT.Setting("celebrations") == "off" then
        facing = target; model:SetFacing(facing); return
    end
    local elapsed = 0
    turn:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / 0.65)
        facing = start + delta * Ease(t)
        model:SetFacing(facing)
        if t == 1 then turn:SetScript("OnUpdate", nil) end
    end)
end
local function Focus(slot)
    TurnTo(slot == "BackSlot" and math.pi or 0)
    local _, currentRace = UnitRace("player")
    local profile = currentRace == "Dwarf" and UnitSex("player") == 2 and dwarfMaleFocus[slot]
        or focusProfiles[slot] or {0, 0, 0}
    MoveCamera(profile[1], profile[2], profile[3], 0.55)
end
local function FadeIn(frame)
    frame:SetScript("OnUpdate", nil); frame:SetAlpha(1); frame:Show()
    if FGT.Setting("celebrations") == "off" then return end
    local elapsed = 0
    frame:SetAlpha(0)
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        self:SetAlpha(math.min(1, elapsed / 0.12))
        if elapsed >= 0.12 then self:SetScript("OnUpdate", nil) end
    end)
end
local function PaintGear()
    if not model.TryOn then return end
    model:Undress()
    for id = 1, 19 do
        local item = selected and byId[selected.slots[id]]
        if item and item.slot ~= "FingerSlot" then model:TryOn("item:" .. item.id) end
    end
end
local appearance = CreateFrame("Frame", nil, P)
local appearanceAlpha, modelOwner = 1, nil
local function Dress(animate)
    appearance:SetScript("OnUpdate", nil)
    if not animate or FGT.Setting("celebrations") == "off" then
        PaintGear(); appearanceAlpha = 1; model:SetAlpha(1); return
    end
    local elapsed, swapped, startAlpha = 0, false, appearanceAlpha
    appearance:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 0.16 then
            appearanceAlpha = startAlpha + (0.30 - startAlpha) * Ease(elapsed / 0.16)
        else
            if not swapped then swapped = true; PaintGear() end
            appearanceAlpha = 0.30 + 0.70 * Ease(math.min(1, (elapsed - 0.16) / 0.24))
        end
        model:SetAlpha(appearanceAlpha)
        if elapsed >= 0.40 then appearance:SetScript("OnUpdate", nil) end
    end)
end
model:SetScript("OnModelLoaded", function() PaintGear(); ApplyZoom(zoom); model:SetFacing(facing) end)
local function Rotate()
    if not dragX then return end
    if not IsMouseButtonDown("LeftButton") then dragX = nil; model:SetScript("OnUpdate", nil); return end
    local x = GetCursorPosition()
    facing = facing + (x - dragX) * 0.01; dragX = x; model:SetFacing(facing)
end
model:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then
        turn:SetScript("OnUpdate", nil)
        dragX = GetCursorPosition(); model:SetScript("OnUpdate", Rotate)
    end
end)
model:SetScript("OnMouseUp", function() dragX = nil; model:SetScript("OnUpdate", nil) end)
model:SetScript("OnMouseWheel", function(_, delta)
    MoveCamera(math.max(0, math.min(MAX_ZOOM, targetZoom + delta * 0.1)), targetY, targetZ, 0.20)
end)
-- Goal-art treatment belongs below the character and equipment controls.
-- Keep the same panel colors/top veil, with broad side fades and an eased bottom.
local shades = {}
for i = 1, 27 do
    shades[i] = background:CreateTexture(nil, "OVERLAY")
    shades[i]:SetColorTexture(1, 1, 1, 1)
end
local function ShadeBackground(w, h)
    local panel = U.styles.panel
    local function Color(y)
        local p = math.min(1, math.max(0, y / h))
        local c = {}
        for i = 1, 3 do c[i] = panel.top[i] + (panel.bottom[i] - panel.top[i]) * p end
        return c
    end
    for i = 1, 2 do
        local t = shades[i]
        t:ClearAllPoints(); t:SetWidth(w * 0.28)
        t:SetPoint(i == 1 and "TOPLEFT" or "TOPRIGHT", modelArea)
        t:SetPoint(i == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT", modelArea)
        U.gradient(t, panel.top, panel.top, i == 1 and 1 or 0, i == 1 and 0 or 1)
    end
    local top = shades[3]
    top:ClearAllPoints(); top:SetPoint("TOPLEFT", modelArea); top:SetPoint("TOPRIGHT", modelArea)
    top:SetHeight(h * 0.28)
    FGT.PopoutUI.vgradient(top, panel.top, Color(h * 0.28), 0.65, 0)
    local height = math.min(140, h * 0.35)
    for i = 1, 24 do
        local t = shades[i + 3]
        local p1, p2 = (i - 1) / 24, i / 24
        local y = h - height + height * p1
        t:ClearAllPoints(); t:SetPoint("TOPLEFT", modelArea, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", modelArea, "TOPRIGHT", 0, -y)
        t:SetHeight(height / 24)
        FGT.PopoutUI.vgradient(t, Color(y), Color(y + height / 24),
            p1 * p1 * (3 - 2 * p1), p2 * p2 * (3 - 2 * p2))
    end
end
local function LayoutPreview(self, w, h)
    if w <= 0 or h <= 0 then return end
    -- One uniform scale for every tile; crop the assembled picture as a unit.
    local scale = math.max(w / 318, h / 383)
    local x, y = (w - 318 * scale) / 2, (h - 383 * scale) / 2
    for i = 1, 4 do
        local b = self["bg" .. i]
        local r = b.rect
        b.texture:ClearAllPoints()
        b.texture:SetPoint("TOPLEFT", self, "TOPLEFT", x + r[1] * scale, -y - r[2] * scale)
        b.texture:SetSize(r[3] * scale, r[4] * scale)
    end
    -- Draw across the full panel: a narrow model frame slices enlarged geometry.
    -- Compensate camera distance for its wider aspect instead of clipping the model.
    cameraAspect = math.max(1, w / h / 0.85)
    ShadeBackground(w, h)
    for i = 1, 2 do
        local t = textShades[i]
        t:ClearAllPoints(); t:SetWidth(w * 0.42)
        t:SetPoint(i == 1 and "TOPLEFT" or "TOPRIGHT", modelArea)
        t:SetPoint(i == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT", modelArea)
    end
    for i = 3, 4 do
        local t = textShades[i]
        t:ClearAllPoints(); t:SetHeight(math.min(i == 3 and 140 or 110, h * 0.23))
        t:SetPoint(i == 3 and "TOPLEFT" or "BOTTOMLEFT", modelArea)
        t:SetPoint(i == 3 and "TOPRIGHT" or "BOTTOMRIGHT", modelArea)
    end
    ApplyZoom(zoom)
end
modelArea:SetScript("OnSizeChanged", LayoutPreview)
local controls = CreateFrame("Frame", nil, right)
controls:SetAllPoints(); controls:SetFrameLevel(model:GetFrameLevel() + 3)
local slots = {
    {"HeadSlot", "Head", "LEFT", 1}, {"NeckSlot", "Neck", "LEFT", 2},
    {"ShoulderSlot", "Shoulders", "LEFT", 3}, {"BackSlot", "Back", "LEFT", 4},
    {"ChestSlot", "Chest", "LEFT", 5}, {"ShirtSlot", "Shirt", "LEFT", 6},
    {"TabardSlot", "Tabard", "LEFT", 7}, {"WristSlot", "Wrists", "LEFT", 8},
    {"HandsSlot", "Hands", "RIGHT", 1}, {"WaistSlot", "Waist", "RIGHT", 2},
    {"LegsSlot", "Legs", "RIGHT", 3}, {"FeetSlot", "Feet", "RIGHT", 4},
    {"Finger0Slot", "Finger 1", "RIGHT", 5}, {"Finger1Slot", "Finger 2", "RIGHT", 6},
    {"Trinket0Slot", "Trinket 1", "RIGHT", 7}, {"Trinket1Slot", "Trinket 2", "RIGHT", 8},
    {"MainHandSlot", "Main Hand", "BOTTOM", 1},
    {"SecondaryHandSlot", "Off Hand", "BOTTOM", 2},
    {"RangedSlot", "Ranged", "BOTTOM", 3},
}
for _, spec in ipairs(slots) do
    local button = Button(controls, "", 44, 44)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3); button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.plannerSlot = spec[1]
    button.icon:SetTexture(FGT.GearPlannerSlotTexture(spec[1]))
    button.itemName = U.font(button, 11)
    button.itemName:SetText(""); button.itemName:SetWordWrap(false)
    button.itemName:SetShadowColor(0, 0, 0, 1); button.itemName:SetShadowOffset(1, -1)
    if spec[3] == "LEFT" then
        button.itemName:SetPoint("LEFT", button, "RIGHT", 8, 0)
    elseif spec[3] == "RIGHT" then
        button.itemName:SetPoint("RIGHT", button, "LEFT", -8, 0)
        button.itemName:SetJustifyH("RIGHT")
    else
        button.itemName:SetPoint("BOTTOM", button, "TOP", 0, 6)
        button.itemName:SetJustifyH("CENTER")
    end
    slotButtons[spec[1]] = button
end
local function LayoutSlots()
    local available = math.max(1, right:GetHeight() - 152)
    local size = math.min(44, available / 8 - 4)
    size = math.max(20, size)
    for _, spec in ipairs(slots) do
        local button = slotButtons[spec[1]]
        button:SetSize(size, size); button:ClearAllPoints()
        button.itemName:SetWidth(math.max(40, math.min(160, (right:GetWidth() - size * 2 - 100) / 3)))
        if spec[3] == "BOTTOM" then
            button:SetPoint("BOTTOM", right, "BOTTOM", (spec[4] - 2) * (size + 12), 18)
        else
            button:SetPoint("TOP" .. spec[3], right, "TOP" .. spec[3],
                spec[3] == "LEFT" and 22 or -22, -88 - (spec[4] - 1) * (size + 4))
        end
    end
end
right:HookScript("OnSizeChanged", LayoutSlots)
local head = slotButtons.HeadSlot

local hint = U.font(controls, 10)
hint:SetText("Drag to rotate · Scroll to zoom"); hint:SetPoint("BOTTOM", 0, 76)
local picker = CreateFrame("Frame", nil, controls, "BackdropTemplate")
picker:SetPoint("TOPLEFT", head, "TOPRIGHT", 10, 0)
picker:SetFrameLevel(controls:GetFrameLevel() + 5)
picker:EnableMouse(true)
picker:SetWidth(244); picker:SetHeight(176); U.etch(picker, U.styles.panel); picker:Hide()
local search = CreateFrame("EditBox", nil, picker, "InputBoxTemplate")
search:SetAutoFocus(false); search:SetSize(208, 26); search:SetPoint("TOPLEFT", 16, -12)
search:SetFontObject("GameFontHighlight")
local pickerNote = Label(picker, "Tier 3 test list", 10, 12, -150)
local noResults = Label(picker, "", 11, 12, -48)
local resultRows = {}
local menu = CreateFrame("Frame", nil, controls, "BackdropTemplate")
menu:SetSize(150, 76); menu:SetPoint("TOPLEFT", head, "TOPRIGHT", 8, 0)
U.etch(menu, U.styles.panel); menu:Hide()
menu:SetFrameLevel(controls:GetFrameLevel() + 5); menu:EnableMouse(true)
local function Deselect()
    GameTooltip:Hide()
    selectedSlot = nil; picker:Hide(); menu:Hide(); search:ClearFocus()
    for _, button in pairs(slotButtons) do button.chosen = false; button:SetEtch(U.styles.button) end
end
local clickAway = CreateFrame("Frame", nil, P)
P:HookScript("OnShow", function() clickAway:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
P:HookScript("OnHide", function() clickAway:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
clickAway:SetScript("OnEvent", function()
    if not selectedSlot then return end
    if picker:IsShown() and picker:IsMouseOver() then return end
    if menu:IsShown() and menu:IsMouseOver() then return end
    if slotButtons[selectedSlot] and slotButtons[selectedSlot]:IsMouseOver() then return end
    Deselect()
end)
local replace = Button(menu, "Replace", 130); replace:SetPoint("TOPLEFT", 10, -8)
local unequip = Button(menu, "Unequip", 130); unequip:SetPoint("TOPLEFT", 10, -40)
local Refresh, Results
local function Save()
    if not selected then return end
    local value = (name:GetText() or ""):match("^%s*(.-)%s*$")
    if value == "" and selected.tracked then
        status:SetText("Enter a set name."); status:SetAlpha(1); return
    end
    selected.name = value
    if value ~= "" and draft == selected then
        local store = Store(); selected.id = store.nextId; store.nextId = store.nextId + 1
        store.builds[#store.builds + 1] = selected; store.selected = selected.id; draft = nil
    end
    if selected.tracked then
        local goal = SyncGoal(selected, U.charKey()); FGT.RefreshPlannerGoals(goal)
    end
    status:SetText(value == "" and "Name your set to save it." or "Saved")
    status:SetAlpha(1)
    local elapsed = 0
    status:SetScript("OnUpdate", value ~= "" and function(self, dt)
        elapsed = elapsed + dt
        self:SetAlpha(math.max(0, 1 - math.max(0, elapsed - 1.5) / 0.4))
        if elapsed >= 1.9 then self:SetScript("OnUpdate", nil) end
    end or nil)
end
local function Choose(build)
    selected = build; changing = true; name:SetText(build and build.name or ""); changing = false
    Deselect(); Focus(false)
    LayoutSlots()
    local ownerKey = U.charKey()
    if modelOwner ~= ownerKey then
        modelOwner = ownerKey; model:SetUnit("player"); model:SetFacing(facing); Dress()
    else
        Dress(true)
    end
    LayoutPreview(modelArea, modelArea:GetWidth(), modelArea:GetHeight())
    status:SetText(""); status:SetAlpha(1)
    Refresh()
end
Refresh = function()
    local store = Store()
    owner:SetText(UnitName("player") or "")
    for _, row in ipairs(rows) do row:Hide() end
    local visible = 0
    for _, build in ipairs(store.builds) do
        if build.tracked and ForeverGoalTrackerDB.active[build.goalId] then
            visible = visible + 1
            local i = visible
            local row = rows[i]
            if not row then row = Button(list.content, "", 180, 34); rows[i] = row end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 2, -(i - 1) * 40)
            row:SetWidth(math.max(120, left:GetWidth() - 40))
            row.text:SetWidth(math.max(100, left:GetWidth() - 60))
            row.text:SetText(build.name ~= "" and build.name or "Name your set")
            row.chosen = build == selected
            row:SetEtch(row.chosen and U.styles.rowSel or U.styles.button)
            row:SetScript("OnClick", function() store.selected = build.id; Choose(build) end); row:Show()
        end
    end
    list.content:SetHeight(math.max(1, visible * 40)); list:Finalize(); list:Update()
    empty:SetShown(not selected); name:SetShown(selected ~= nil)
    modelArea:SetShown(selected ~= nil); controls:SetShown(selected ~= nil)
    if not selected or selected.name == "" then
        status:SetScript("OnUpdate", nil); status:SetAlpha(1)
        status:SetText(not selected and "Create a build to begin." or "Name your set to save it.")
    end
    local tracked = selected and selected.goalId and ForeverGoalTrackerDB.active[selected.goalId]
    add.text:SetText(tracked and "Added to Goals" or "Add to Goals")
    add:SetEnabled(selected ~= nil and selected.name ~= "" and next(selected.slots) ~= nil and not tracked)
    for slot, button in pairs(slotButtons) do
        local item = selected and byId[selected.slots[slotIds[slot]]]
        button.icon:SetTexture(item and item.icon or FGT.GearPlannerSlotTexture(slot))
        button.itemName:SetText(item and item.name or "")
        button.itemName:SetTextColor(0.75, 0.45, 1)
        button.icon:SetAlpha((item or button.chosen) and 1 or 0.50)
    end
end
Results = function()
    local _, class = UnitClass("player")
    local query = (search:GetText() or ""):lower(); local count = 0
    for _, row in ipairs(resultRows) do row:Hide() end
    for _, entry in ipairs(catalogue) do
        if entry.class == class and SlotMatches(entry, selectedSlot) and entry.name:lower():find(query, 1, true) then
            count = count + 1
            local row = resultRows[count]
            if not row then
                row = Button(picker, "", 220, 44); resultRows[count] = row
                row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(28, 28); row.icon:SetPoint("LEFT", 5, 0)
                row.text:ClearAllPoints(); row.text:SetPoint("LEFT", 40, 7); row.text:SetWidth(174)
                row.source = U.font(row, 9); row.source:SetPoint("LEFT", 40, -10); row.source:SetWidth(174)
            end
            row:SetPoint("TOPLEFT", 10, -42 - (count - 1) * 50)
            row.icon:SetTexture(entry.icon); row.text:SetText(entry.name)
            row.text:SetTextColor(0.75, 0.45, 1)
            row.chosen = selected and selected.slots[slotIds[selectedSlot]] == entry.id
            row:SetEtch(row.chosen and U.styles.rowSel or U.styles.button)
            row.source:SetText((row.chosen and "|T" .. FGT.Icon("check") .. ":10:10|t " or "") .. entry.source)
            row:SetScript("OnClick", function()
                if not selected or not selectedSlot or not SlotMatches(entry, selectedSlot) then return end
                local id = slotIds[selectedSlot]
                local moved = false
                if entry.unique then
                    for other, itemId in pairs(selected.slots) do
                        if other ~= id and itemId == entry.id then selected.slots[other] = nil; moved = true end
                    end
                end
                selected.slots[id] = entry.id; Dress(true); Save(); Refresh(); Results()
                if moved then status:SetText("Moved ring to the selected slot.") end
            end)
            row:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink("item:" .. entry.id)
                GameTooltip:AddLine(entry.source, 0.8, 0.75, 0.65, true)
                if FGT.isForever then GameTooltip:AddLine("Unconfirmed in Forever", 0.4, 0.65, 1) end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end); row:Show()
        end
    end
    noResults:SetText(count == 0 and (query == "" and "No items available for this slot yet." or "No matching items.") or "")
end
search:SetScript("OnTextChanged", Results)
search:SetScript("OnEscapePressed", Deselect)
local function PositionPopup(frame)
    local button = slotButtons[selectedSlot]
    if not button then return end
    local spec
    for _, value in ipairs(slots) do if value[1] == selectedSlot then spec = value; break end end
    frame:ClearAllPoints()
    local edge = spec[4] >= 5 and "BOTTOM" or "TOP"
    if spec[3] == "BOTTOM" then
        frame:SetPoint("BOTTOM", button, "TOP", 0, 8)
    elseif spec[3] == "RIGHT" then
        frame:SetPoint(edge .. "RIGHT", button, edge .. "LEFT", -10, 0)
    else
        frame:SetPoint(edge .. "LEFT", button, edge .. "RIGHT", 10, 0)
    end
end
local function OpenPicker()
    if not selectedSlot then return end
    slotButtons[selectedSlot]:SetEtch(U.styles.rowSel)
    GameTooltip:Hide(); menu:Hide(); PositionPopup(picker); FadeIn(picker); search:SetText("")
    local label = selectedSlot
    for _, spec in ipairs(slots) do if spec[1] == selectedSlot then label = spec[2]; break end end
    pickerNote:SetText(label .. (selectedSlot == "HeadSlot" and " · Tier 1 & Tier 3" or " · Tier 3"))
    Results(); Focus(selectedSlot)
end
for _, spec in ipairs(slots) do
    local slot, label = spec[1], spec[2]
    local button = slotButtons[slot]
    button:SetScript("OnClick", function()
        Deselect(); selectedSlot = slot; button.chosen = true; button:SetEtch(U.styles.rowSel)
        if selected and selected.slots[slotIds[slot]] then
            PositionPopup(menu); FadeIn(menu); Focus(slot)
        else OpenPicker() end
    end)
    button:SetScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        self:SetEtch(self.chosen and U.styles.rowSel or U.styles.btnHover)
        if selectedSlot == slot and (menu:IsShown() or picker:IsShown()) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local item = selected and byId[selected.slots[slotIds[slot]]]
        if item then GameTooltip:SetHyperlink("item:" .. item.id)
        else GameTooltip:SetText(label, 1, 1, 1); GameTooltip:AddLine("Choose an item", 1, 1, 1) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self:SetEtch(self.chosen and U.styles.rowSel or U.styles.button)
        self.icon:SetAlpha(selected and selected.slots[slotIds[slot]] and 1 or 0.50)
        GameTooltip:Hide()
    end)
end
replace:SetScript("OnClick", OpenPicker)
unequip:SetScript("OnClick", function()
    if selected and selectedSlot then selected.slots[slotIds[selectedSlot]] = nil; Dress(true); Save(); Refresh() end
    Deselect()
end)
add:SetScript("OnClick", function()
    if not selected or selected.name == "" or not next(selected.slots) then return end
    selected.tracked = true
    local goal = SyncGoal(selected, U.charKey())
    if not goal then return end
    ForeverGoalTrackerDB.active[goal.id] = true
    FGT.RefreshPlannerGoals(goal); Refresh()
end)
new:SetScript("OnClick", function() draft = { name = "", slots = {} }; draftOwner = U.charKey(); Choose(draft); name:SetFocus() end)
name:SetScript("OnTextChanged", function() if not changing then Save(); Refresh() end end)
name:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
name:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
P:HookScript("OnShow", function()
    local store = Store(); selected = nil
    for _, build in ipairs(store.builds) do if build.id == store.selected then selected = build end end
    Choose((draftOwner == U.charKey() and draft) or selected or store.builds[1])
end)
P:HookScript("OnHide", function()
    camera:SetScript("OnUpdate", nil); model:SetScript("OnUpdate", nil); model:SetAlpha(1); dragX = nil
    turn:SetScript("OnUpdate", nil)
    appearance:SetScript("OnUpdate", nil); appearanceAlpha = 1
    status:SetScript("OnUpdate", nil)
    picker:SetScript("OnUpdate", nil); menu:SetScript("OnUpdate", nil)
    Deselect(); name:ClearFocus(); GameTooltip:Hide()
end)
-- Expose only prototype operations needed by regression checks.
FGT.GearPlannerTest = { store = Store, new = function() new:GetScript("OnClick")() end,
    name = name, add = add, camera = camera, turn = turn, appearance = appearance, menu = menu, replace = replace, rows = rows, head = head, picker = picker, results = resultRows, unequip = unequip,
    modelArea = modelArea, model = model, clickAway = clickAway, slots = slotButtons, catalogue = catalogue }
