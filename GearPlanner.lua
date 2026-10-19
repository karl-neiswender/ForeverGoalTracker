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
-- Top-ranked choices from the linked Wowhead SoM pre-raid guide (reviewed 2026-10-18).
-- Classic acquisition routes; Forever availability remains unconfirmed.
local hunterPreRaid = {
    {1, 18421, "Backwood Helm", "HeadSlot", "The Treasure of the Shen'dralar — Dire Maul library chest; complete The Madness Within first"},
    {2, 22340, "Pendant of Celerity", "NeckSlot", "Lord Valthalak — Upper Blackrock Spire; summon in The Beast's room with a Tier 0.5 brazier"},
    {3, 12927, "Truestrike Shoulders", "ShoulderSlot", "Pyroguard Emberseer — Upper Blackrock Spire"},
    {5, 11726, "Savage Gladiator Chain", "ChestSlot", "Gorosh the Dervish — Blackrock Depths, Ring of Law"},
    {6, 22232, "Marksman's Girdle", "WaistSlot", "Urok Doomhowl — Lower Blackrock Spire; summon with Omokk's Head and a Roughshod Pike"},
    {7, 15062, "Devilsaur Leggings", "LegsSlot", "Leatherworking — craft or buy from another player"},
    {8, 22061, "Beastmaster's Boots", "FeetSlot", "Anthion's Parting Words — Deliana, Ironforge; requires the Dungeon Set 2 upgrade chain"},
    {9, 18375, "Bracers of the Eclipse", "WristSlot", "Prince Tortheldrin — Dire Maul West"},
    {10, 15063, "Devilsaur Gauntlets", "HandsSlot", "Leatherworking — craft or buy from another player"},
    {11, 18500, "Tarnished Elven Ring", "FingerSlot", "Gordok Tribute chest — Dire Maul North"},
    {13, 13965, "Blackhand's Breadth", "TrinketSlot", "General Drakkisath's Demise — Marshal Maxwell, Morgan's Vigil, Burning Steppes"},
    {14, 18473, "Royal Seal of Eldre'Thalas", "TrinketSlot", "The Greatest Race of Hunters — turn in the book to Lorekeeper Mykos, Dire Maul library"},
    {15, 13340, "Cape of the Black Baron", "BackSlot", "Baron Rivendare — Stratholme, undead side"},
    {16, 22314, "Huntsman's Harpoon", "MainHandSlot", "Isalien — Dire Maul East; summon in Alzzin's room with a Tier 0.5 brazier"},
    {18, 19107, "Bloodseeker", "RangedSlot", "Hero of the Stormpike — Alterac Valley victory quest; turn in to Prospector Stonehewer, Alterac Mountains"},
}
for _, entry in ipairs(hunterPreRaid) do
    catalogue[#catalogue + 1] = { class = "HUNTER", id = entry[2], name = entry[3], slot = entry[4],
        icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(entry[2]))
            or (GetItemIcon and GetItemIcon(entry[2])) or "Interface\\Icons\\INV_Misc_QuestionMark",
        source = entry[5], twoHand = entry[2] == 22314, unique = entry[4] == "TrinketSlot", quality = entry[2] == 11726 and 4 or 3, preRaid = true }
end
for _, item in ipairs(catalogue) do byId[item.id] = item end
local function SlotMatches(item, slot)
    return item.slot == slot or (item.slot == "FingerSlot" and (slot == "Finger0Slot" or slot == "Finger1Slot"))
        or (item.slot == "TrinketSlot" and (slot == "Trinket0Slot" or slot == "Trinket1Slot"))
end
local function Store()
    local db = ForeverGoalTrackerDB
    db.gearPlanner = db.gearPlanner or { version = 1, characters = {} }
    local key = U.charKey()
    local chars = db.gearPlanner.characters
    chars[key] = chars[key] or { nextId = 1, builds = {} }
    return chars[key]
end
-- Acquisition copy stays separate from ownership rules and stable slot credit.
local function Acquisition(item)
    local source, advice = (item.source or "Source unknown"):match("^([^;]+);?%s*(.*)$")
    local who, where = source:match("^(.-) — (.+)$")
    local text
    if item.id == 18421 then
        text = "Complete 'The Treasure of the Shen'dralar' in Dire Maul"
        advice = "Complete 'The Madness Within' first; collect the reward from the Dire Maul library chest."
    elseif item.id == 22061 then
        text = "Complete 'Anthion's Parting Words' with Deliana in Ironforge"
    elseif item.id == 13965 then
        text = "Complete 'General Drakkisath's Demise' with Marshal Maxwell at Morgan's Vigil in Burning Steppes"
    elseif item.id == 18473 then
        text = "Complete 'The Greatest Race of Hunters' with Lorekeeper Mykos in the Dire Maul library"
        advice = "Turn in the hunter book."
    elseif item.id == 19107 then
        text = "Complete 'Hero of the Stormpike' in Alterac Valley"
        advice = "Win Alterac Valley, then turn in to Prospector Stonehewer in Alterac Mountains."
    elseif who == "Leatherworking" then
        text = "Craft " .. item.name .. " with Leatherworking, or buy it"
    elseif who == "Tier 3 turn-in" then
        text = "Obtain " .. item.name .. " from a Tier 3 turn-in at " .. where
    elseif who and where then
        text = "Loot " .. item.name .. " from " .. who .. " in " .. where
    else
        text = "Collect " .. item.name .. " (Source unknown)"
    end
    -- Quest steps must name the reward too, so it remains an item link.
    if text:sub(1, 9) == "Complete " then text = text .. " for " .. item.name end
    return text, advice ~= "" and advice or nil
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
    local nextProgress, copies = {}, {}
    for slot = 1, 19 do
        local item = byId[build.slots[slot]]
        if item then
            copies[item.id] = (copies[item.id] or 0) + 1
            local acquisition, advice = Acquisition(item)
            local step = { text = acquisition .. (item.slot == "FingerSlot" and
                    (slot == 11 and " (Finger 1)" or " (Finger 2)") or ""),
                auto = { item = item.id, count = copies[item.id], forCharacter = ownerKey }, plannerSlot = slot,
                tip = advice }
            goal.steps[#goal.steps + 1] = step
            build.goalItems[#build.goalItems + 1] = { slot = slot, id = item.id }
            if advice then goal.tips[#goal.tips + 1] = "{item:" .. item.id .. ":" .. item.name .. "}: " .. advice end
            if credit[slot .. ":" .. item.id] then nextProgress[#goal.steps] = true end
            U.watch[item.id] = true
        end
    end
    if build.preset == "hunter_preraid_wowhead" then
        goal.tips[#goal.tips + 1] = "Use both Devilsaur pieces for the set bonus."
        if FGT.isForever then goal.tips[#goal.tips + 1] = "Classic sources shown. Availability in Forever is Unconfirmed." end
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
local function Hover(button, on)
    local wash = button.hoverWash
    if not wash then
        wash = CreateFrame("Frame", nil, button)
        wash:SetAllPoints(button)
        local texture = wash:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints(); texture:SetColorTexture(0.80, 0.62, 0.16, 0.13)
        wash:SetAlpha(0); button.hoverWash = wash
        button:HookScript("OnHide", function()
            wash:SetScript("OnUpdate", nil); wash:SetAlpha(0)
        end)
    end
    local start, target, elapsed = wash:GetAlpha(), on and 1 or 0, 0
    wash:SetScript("OnUpdate", nil)
    if FGT.Setting("celebrations") == "off" then wash:SetAlpha(target); return end
    wash:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / 0.12)
        self:SetAlpha(start + (target - start) * t)
        if t == 1 then self:SetScript("OnUpdate", nil) end
    end)
end
local function Button(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, height or 28); U.etch(b, U.styles.button)
    b.text = U.font(b, 12); b.text:SetPoint("CENTER"); b.text:SetText(text)
    b:SetScript("OnEnter", function() Hover(b, true); b:SetEtch(b.chosen and U.styles.rowSel or U.styles.btnHover) end)
    b:SetScript("OnLeave", function() Hover(b, false); b:SetEtch(b.chosen and U.styles.rowSel or U.styles.button) end)
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
local new = Button(left, "+ New", 68, 24); new:SetPoint("TOPRIGHT", -14, -14)
local list = U.scroll(left, 0, 0, 0, 0)
-- Use an independent clipped viewport; no dependency on the guide layout.
list.scroll:ClearAllPoints(); list.scroll:SetPoint("TOPLEFT", 12, -76)
list.scroll:SetPoint("BOTTOMRIGHT", -20, 16)
local listEmpty = Label(left, "No gear sets yet.\nChoose + New to start a set.", 11, 16, -84)
listEmpty:SetWidth(left:GetWidth() - 32); listEmpty:SetJustifyH("LEFT")
local rows, selected, draft, changing = {}, nil, nil, false
local draftOwner
local editingName = false
local header = CreateFrame("Frame", nil, right)
header:SetAllPoints(); header:SetFrameLevel(right:GetFrameLevel() + 12)
local name = CreateFrame("EditBox", nil, header, "InputBoxTemplate")
name:SetAutoFocus(false); name:SetMaxLetters(60); name:SetHeight(28)
name:SetPoint("TOPLEFT", right, "TOPLEFT", 24, -24)
name:SetWidth(340)
name:SetFontObject("GameFontHighlight")
local nameLabel = Label(header, "Set name", 10, 22, -6)
nameLabel:ClearAllPoints(); nameLabel:SetPoint("BOTTOMLEFT", name, "TOPLEFT", 0, 4)
local status = U.font(header, 10)
status:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
local options = Button(header, "...", 30, 28)
options:SetPoint("TOPRIGHT", right, "TOPRIGHT", -16, -24)
local add = Button(header, "Add to Goals", 132)
add:SetPoint("RIGHT", options, "LEFT", -8, 0)
name:ClearAllPoints(); name:SetPoint("TOPLEFT", right, "TOPLEFT", 24, -24)
name:SetPoint("RIGHT", add, "LEFT", -16, 0)
local setTitle = U.font(header, 18)
setTitle:SetPoint("LEFT", name, "LEFT", 0, 0)
setTitle:SetPoint("RIGHT", add, "LEFT", -48, 0)
setTitle:SetWordWrap(false)
local editName = CreateFrame("Button", nil, header)
editName:SetSize(24, 28); editName:SetPoint("RIGHT", add, "LEFT", -16, 0)
FGT.IconButton(editName, "pencil-white", 14)
editName.icon:SetVertexColor(0.65, 0.65, 0.65)
editName:HookScript("OnEnter", function(self)
    self.icon:SetVertexColor(0.80, 0.62, 0.16)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Rename set", 1, 1, 1); GameTooltip:Show()
end)
editName:HookScript("OnLeave", function(self)
    self.icon:SetVertexColor(0.65, 0.65, 0.65); GameTooltip:Hide()
end)

local actions = CreateFrame("Frame", nil, header, "BackdropTemplate")
actions:SetSize(176, 112); actions:SetPoint("TOPRIGHT", options, "BOTTOMRIGHT", 0, -6)
actions:SetFrameLevel(header:GetFrameLevel() + 20); actions:EnableMouse(true)
U.etch(actions, U.styles.panel); actions:Hide()
local rename = Button(actions, "Rename", 156); rename:SetPoint("TOPLEFT", 10, -8)
local clear = Button(actions, "Clear items", 156); clear:SetPoint("TOPLEFT", 10, -42)
local remove = Button(actions, "Remove from Goals", 156); remove:SetPoint("TOPLEFT", 10, -76)
local cleared, clearedBuild, clearedItems, clearedProgress
options:SetScript("OnClick", function() actions:SetShown(not actions:IsShown()) end)
options:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Set options", 1, 1, 1); GameTooltip:Show()
end)
options:HookScript("OnLeave", function() GameTooltip:Hide() end)
local empty = Label(header, "Create a set to begin.", 14, 20, -100)
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
        if item and item.slot ~= "FingerSlot" and item.slot ~= "TrinketSlot" and item.slot ~= "NeckSlot" then
            FGT.ItemInfo(item.id) -- request uncached item data before trying its appearance
            model:TryOn("item:" .. item.id)
        end
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
P:HookScript("OnShow", function() P:RegisterEvent("GET_ITEM_INFO_RECEIVED") end)
P:HookScript("OnHide", function() P:UnregisterEvent("GET_ITEM_INFO_RECEIVED") end)
P:SetScript("OnEvent", function(_, _, itemId, ok)
    if ok == false or not P:IsShown() or not selected or P.itemRefreshPending then return end
    for _, id in pairs(selected.slots) do
        if id == itemId then
            P.itemRefreshPending = true
            C_Timer.After(0.1, function()
                P.itemRefreshPending = nil
                if P:IsShown() then Dress(false) end
            end)
            return
        end
    end
end)
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
    if actions:IsShown() and not actions:IsMouseOver() and not options:IsMouseOver() then actions:Hide() end
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
    if value == "" and selected.id then
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
    status:SetAlpha(1)
end
local function Choose(build)
    actions:Hide(); cleared, clearedBuild, clearedItems, clearedProgress = nil, nil, nil, nil
    selected = build; changing = true; name:SetText(build and build.name or ""); changing = false
    editingName = false
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
        if build.name ~= "" then
            visible = visible + 1
            local i = visible
            local row = rows[i]
            if not row then row = Button(list.content, "", 180, 48); rows[i] = row
                row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 10, -7)
                row.state = U.font(row, 9); row.state:SetPoint("TOPLEFT", 10, -28)
            end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 2, -(i - 1) * 54)
            row:SetWidth(math.max(120, left:GetWidth() - 40))
            row.text:SetWidth(math.max(100, left:GetWidth() - 60))
            row.text:SetText(build.name ~= "" and build.name or "Name your set")
            row.state:SetText(build.goalId and ForeverGoalTrackerDB.active[build.goalId] and "In My Goals" or "Draft")
            row.chosen = build == selected
            row:SetEtch(row.chosen and U.styles.rowSel or U.styles.button)
            row:SetScript("OnClick", function() store.selected = build.id; Choose(build) end); row:Show()
        end
    end
    listEmpty:SetShown(visible == 0)
    list.content:SetHeight(math.max(1, visible * 54)); list:Finalize(); list:Update()
    empty:SetShown(not selected)
    local editing = selected ~= nil and (editingName or selected.name == "")
    name:SetShown(editing); nameLabel:SetShown(editing)
    setTitle:SetText(selected and selected.name or "")
    setTitle:SetShown(selected ~= nil and not editing)
    editName:SetShown(selected ~= nil and not editing)
    modelArea:SetShown(selected ~= nil); controls:SetShown(selected ~= nil)
    local tracked = selected and selected.goalId and ForeverGoalTrackerDB.active[selected.goalId]
    status:SetAlpha(1)
    if not selected then
        status:SetText("Create a set to begin.")
    elseif tracked then
        status:SetText("In My Goals · Changes saved")
    else
        status:SetText(not next(selected.slots) and "Choose a slot to start building your set." or (selected.name ~= "" and "Draft · Not in Goals" or "Name your set before adding it."))
    end
    add:SetShown(selected ~= nil and not tracked)
    local canAdd = selected ~= nil and next(selected.slots) ~= nil
    add:SetEnabled(canAdd)
    add.chosen = canAdd
    add:SetEtch(canAdd and U.styles.rowSel or U.styles.button)
    add.text:SetAlpha(canAdd and 1 or 0.4)
    options:SetShown(selected ~= nil)
    remove:SetShown(tracked and true or false)
    actions:SetHeight(tracked and 112 or 78)
    clear.text:SetText(clearedBuild == selected and "Undo clear" or "Clear items")
    for slot, button in pairs(slotButtons) do
        local item = selected and byId[selected.slots[slotIds[slot]]]
        button.icon:SetTexture(item and item.icon or FGT.GearPlannerSlotTexture(slot))
        button.itemName:SetText(item and item.name or "")
        if item and item.quality == 3 then button.itemName:SetTextColor(0, 0.44, 0.87)
        else button.itemName:SetTextColor(0.75, 0.45, 1) end
        button.icon:SetAlpha((item or button.chosen) and 1 or 0.65)
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
                row.source = U.font(row, 9); row.source:SetPoint("LEFT", 40, -10); row.source:SetWidth(174); row.source:SetWordWrap(false)
            end
            row:SetPoint("TOPLEFT", 10, -42 - (count - 1) * 50)
            row.icon:SetTexture(entry.icon); row.text:SetText(entry.name)
            if entry.quality == 3 then row.text:SetTextColor(0, 0.44, 0.87)
            else row.text:SetTextColor(0.75, 0.45, 1) end
            row.chosen = selected and selected.slots[slotIds[selectedSlot]] == entry.id
            row:SetEtch(row.chosen and U.styles.rowSel or U.styles.button)
            row.source:SetText((row.chosen and "|T" .. FGT.Icon("check") .. ":10:10|t " or "") .. entry.source:match("^[^;]+"))
            row:SetScript("OnClick", function()
                if not selected or not selectedSlot or not SlotMatches(entry, selectedSlot) then return end
                local id = slotIds[selectedSlot]
                local moved = false
                if entry.unique then
                    for other, itemId in pairs(selected.slots) do
                        if other ~= id and itemId == entry.id then selected.slots[other] = nil; moved = true end
                    end
                end
                if entry.twoHand then selected.slots[17] = nil end
                if id == 17 and byId[selected.slots[16]] and byId[selected.slots[16]].twoHand then selected.slots[16] = nil end
                selected.slots[id] = entry.id; Dress(true); Save(); Refresh(); Results()
                if moved then status:SetText("Moved item to the selected slot.") end
            end)
            row:SetScript("OnEnter", function(self)
                Hover(self, true); self:SetEtch(self.chosen and U.styles.rowSel or U.styles.btnHover)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink("item:" .. entry.id)
                GameTooltip:AddLine(entry.source, 0.8, 0.75, 0.65, true)
                if FGT.isForever then GameTooltip:AddLine("Unconfirmed in Forever", 0.4, 0.65, 1) end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function(self)
                Hover(self, false); self:SetEtch(self.chosen and U.styles.rowSel or U.styles.button)
                GameTooltip:Hide()
            end); row:Show()
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
        Hover(self, true)
        self.icon:SetAlpha(1)
        self:SetEtch(self.chosen and U.styles.rowSel or U.styles.btnHover)
        if selectedSlot == slot and (menu:IsShown() or picker:IsShown()) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local item = selected and byId[selected.slots[slotIds[slot]]]
        if item then GameTooltip:SetHyperlink("item:" .. item.id)
        else
            self.itemName:SetText(label); self.itemName:SetTextColor(0.8, 0.75, 0.65)
            GameTooltip:SetText(label, 1, 1, 1); GameTooltip:AddLine("Choose item", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        Hover(self, false)
        self:SetEtch(self.chosen and U.styles.rowSel or U.styles.button)
        self.icon:SetAlpha(selected and selected.slots[slotIds[slot]] and 1 or 0.65)
        if not (selected and selected.slots[slotIds[slot]]) then self.itemName:SetText("") end
        GameTooltip:Hide()
    end)
end
replace:SetScript("OnClick", OpenPicker)
unequip:SetScript("OnClick", function()
    if selected and selectedSlot then selected.slots[slotIds[selectedSlot]] = nil; Dress(true); Save(); Refresh() end
    Deselect()
end)
add:SetScript("OnClick", function()
    if not selected or not next(selected.slots) then return end
    if selected.name == "" then name:SetFocus(); return end
    name:ClearFocus(); actions:Hide()
    selected.tracked = true
    local goal = SyncGoal(selected, U.charKey())
    if not goal then return end
    ForeverGoalTrackerDB.active[goal.id] = true
    FGT.RefreshPlannerGoals(goal); Refresh()
end)
new:SetScript("OnClick", function() draft = { name = "", slots = {} }; draftOwner = U.charKey(); Choose(draft); editingName = true; Refresh(); name:SetFocus() end)
local function RenameSet()
    actions:Hide(); editingName = true; Refresh(); name:SetFocus(); name:HighlightText()
end
rename:SetScript("OnClick", RenameSet)
editName:SetScript("OnClick", RenameSet)
clear:SetScript("OnClick", function()
    if not selected then return end
    if clearedBuild == selected then
        selected.slots = cleared
        if selected.goalId then
            selected.goalItems = clearedItems
            ForeverGoalTrackerDB.progress[selected.goalId] = clearedProgress
        end
        cleared, clearedBuild, clearedItems, clearedProgress = nil, nil, nil, nil
    else
        cleared, clearedBuild = selected.slots, selected
        clearedItems = selected.goalItems
        clearedProgress = selected.goalId and ForeverGoalTrackerDB.progress[selected.goalId]
        selected.slots = {}
    end
    Deselect(); Dress(true); Save(); Refresh()
end)
remove:SetScript("OnClick", function()
    if not selected or not selected.goalId then return end
    ForeverGoalTrackerDB.active[selected.goalId] = nil
    -- Keep the set and its credit so Add to Goals can restore it without loss.
    actions:Hide(); FGT.RefreshPlannerGoals(); Refresh()
end)
name:SetScript("OnEditFocusLost", function()
    editingName = false
    if selected and selected.id and (name:GetText() or ""):match("^%s*$") then
        changing = true; name:SetText(selected.name); changing = false
    end
    Refresh()
end)
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
    picker:SetScript("OnUpdate", nil); menu:SetScript("OnUpdate", nil)
    actions:Hide(); Deselect(); name:ClearFocus(); GameTooltip:Hide()
end)
-- Explicit test-build import; never changes another character or an existing set.
function FGT.CreateHunterPreRaidBuild()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" or UnitFactionGroup("player") ~= "Alliance" then
        print("Forever Goal Tracker: This test build is for an Alliance Hunter."); return
    end
    local store = Store()
    local build
    for _, existing in ipairs(store.builds) do
        if existing.preset == "hunter_preraid_wowhead" then build = existing; break end
    end
    if not build then
        build = { id = store.nextId, name = "Hunter Pre-Raid BiS", slots = {}, preset = "hunter_preraid_wowhead" }
        store.nextId = store.nextId + 1
        for _, entry in ipairs(hunterPreRaid) do build.slots[entry[1]] = entry[2] end
        build.slots[12] = 18500
        store.builds[#store.builds + 1] = build
    end
    build.tracked = true
    local goal = SyncGoal(build, U.charKey())
    if not goal then return end
    ForeverGoalTrackerDB.active[goal.id] = true; store.selected = build.id
    FGT.RefreshPlannerGoals(goal); FGT.ShowTab("gear"); Choose(build)
    return build, goal
end
-- Expose only prototype operations needed by regression checks.
FGT.GearPlannerTest = { store = Store, new = function() new:GetScript("OnClick")() end,
    name = name, setTitle = setTitle, editName = editName, add = add, options = options, actions = actions, clear = clear, remove = remove, rename = rename, camera = camera, turn = turn, appearance = appearance, menu = menu, replace = replace, rows = rows, head = head, picker = picker, results = resultRows, unequip = unequip,
    modelArea = modelArea, model = model, clickAway = clickAway, slots = slotButtons, catalogue = catalogue }
