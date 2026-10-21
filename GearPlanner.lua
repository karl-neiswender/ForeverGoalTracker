local ADDON, FGT = ...
local U = FGT.MaterialsUI
local Cat = FGT.GearCatalog
local QUALITY = Cat.QUALITY
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
local slotIds = Cat.SLOT_INDEX
local colors, styles = U.colors, U.styles
-- Inventory types with no model to show: neck, rings, trinkets and relics.
local NO_MODEL = { [2] = true, [11] = true, [12] = true, [24] = true, [28] = true }
local ROW_H = 46
local POOL_ROWS = 12 -- enough to fill the tallest picker (460) without measuring a frame before it is laid out
local PICKER_MAX, PICKER_MIN = 460, 200

-- ------------------------------------------------------------
-- Saved data
-- ------------------------------------------------------------
-- ForeverGoalTrackerDB.gearPlanner = { version, prefs, characters[charKey] = { nextId, selected, builds } }
-- A build is { id, name, slots = { [slot number] = item id }, tracked, goalId, goalItems, preset }.
local function Root()
    local db = ForeverGoalTrackerDB
    db.gearPlanner = db.gearPlanner or { version = 2, characters = {} }
    db.gearPlanner.prefs = db.gearPlanner.prefs or { usable = true, quality = 0, sort = "ilvl", revealed = false }
    return db.gearPlanner
end
local function Store()
    local chars, key = Root().characters, U.charKey()
    chars[key] = chars[key] or { nextId = 1, builds = {} }
    return chars[key]
end
local function Prefs() return Root().prefs end

-- ------------------------------------------------------------
-- Goals for tracked sets
-- ------------------------------------------------------------
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
    local nextProgress, copies, firstIcon, classic, unrevealed = {}, {}, nil, false, false
    for _, slot in ipairs(Cat.SLOT_ORDER) do
        local item = Cat.Get(build.slots[slot])
        if item then
            copies[item.id] = (copies[item.id] or 0) + 1
            local acquisition, advice = Cat.Acquisition(item)
            local finger = Cat.SLOT_NAMES[slot]:match("^Finger(%d)")
            local trinket = Cat.SLOT_NAMES[slot]:match("^Trinket(%d)")
            local suffix = finger and (finger == "0" and " (Finger 1)" or " (Finger 2)")
                or trinket and (trinket == "0" and " (Trinket 1)" or " (Trinket 2)") or ""
            -- A step per planned slot; the same item twice needs two owned copies.
            local step = { text = acquisition .. suffix,
                auto = { item = item.id, count = copies[item.id], forCharacter = ownerKey }, plannerSlot = slot,
                tip = advice }
            goal.steps[#goal.steps + 1] = step
            build.goalItems[#build.goalItems + 1] = { slot = slot, id = item.id }
            if advice then goal.tips[#goal.tips + 1] = "{item:" .. item.id .. ":" .. item.name .. "}: " .. advice end
            if credit[slot .. ":" .. item.id] then nextProgress[#goal.steps] = true end
            if U.watch then U.watch[item.id] = true end
            firstIcon = firstIcon or item.icon
            if item.forever < 2 then classic = true else unrevealed = unrevealed or item.forever == 3 end
        end
    end
    local preset = build.preset and Cat.PRESETS[build.preset]
    if preset and preset.note then goal.tips[#goal.tips + 1] = preset.note end
    if FGT.isForever then
        if classic then goal.tips[#goal.tips + 1] = "Sources shown are from Classic Era. Availability in Forever is Unconfirmed." end
        if unrevealed then goal.tips[#goal.tips + 1] = "Some of these items are not revealed in Forever yet." end
    end
    DB.progress[id] = nextProgress
    goal.icon = firstIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
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

-- ------------------------------------------------------------
-- Small controls in the addon's own style
-- ------------------------------------------------------------
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
-- One place decides how a button looks, so hover, selection and quality never fight.
local function PaintButton(b)
    b:SetEtch(b.chosen and styles.rowSel or (b.hovered and styles.btnHover or styles.button))
    local q = b.quality and QUALITY[b.quality]
    if q and b.SetBackdropBorderColor then b:SetBackdropBorderColor(q[1], q[2], q[3], b.chosen and 1 or 0.85) end
end
local function Button(parent, text, width, height, size)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, height or 28); U.etch(b, styles.button)
    b.text = U.font(b, size or 12); b.text:SetPoint("CENTER"); b.text:SetText(text)
    b:SetScript("OnEnter", function() b.hovered = true; Hover(b, true); PaintButton(b) end)
    b:SetScript("OnLeave", function() b.hovered = false; Hover(b, false); PaintButton(b) end)
    return b
end
-- The Library's search field: etched box, magnifier, hint text and a clear X.
local function SearchBox(parent, hintText)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetHeight(24); U.etch(box, styles.row, 10)
    box:SetAutoFocus(false)
    FGT.RegisterFont(box, "body", 11, "")
    box:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3])
    box:SetTextInsets(24, 20, 0, 0); box:SetMaxLetters(40)
    local glass = box:CreateTexture(nil, "OVERLAY")
    glass:SetTexture(FGT.Icon("search-white")); glass:SetSize(13, 13); glass:SetPoint("LEFT", 7, -1)
    glass:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    box.hint = U.font(box, 11); box.hint:SetPoint("LEFT", 24, 0)
    box.hint:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3]); box.hint:SetText(hintText)
    box.clear = CreateFrame("Button", nil, box)
    box.clear:SetSize(16, 16); box.clear:SetPoint("RIGHT", -4, 0)
    local x = box.clear:CreateTexture(nil, "ARTWORK")
    x:SetTexture(FGT.Icon("close-white")); x:SetSize(10, 10); x:SetPoint("CENTER")
    x:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    box.clear:SetScript("OnClick", function() box:SetText(""); box:ClearFocus() end)
    box.clear:Hide()
    box:HookScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        self.hint:SetShown(text == "" and not self:HasFocus()); self.clear:SetShown(text ~= "")
    end)
    box:SetScript("OnEditFocusGained", function(self)
        self.hint:Hide(); self:SetBackdropBorderColor(colors.GOLD2[1], colors.GOLD2[2], colors.GOLD2[3], 1)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self.hint:SetShown((self:GetText() or "") == "")
        self:SetBackdropBorderColor(styles.row.edge[1], styles.row.edge[2], styles.row.edge[3], 1)
    end)
    return box
end

-- ------------------------------------------------------------
-- Layout: set list on the left, editor on the right
-- ------------------------------------------------------------
local left = CreateFrame("Frame", nil, P, "BackdropTemplate")
left:SetPoint("TOPLEFT", U.list, "TOPLEFT")
left:SetPoint("BOTTOMLEFT", U.list, "BOTTOMLEFT")
left:SetWidth(FGT.trackerTab:GetWidth() + FGT.libraryTab:GetWidth() + 56)
U.etch(left, styles.panel)
local right = CreateFrame("Frame", nil, P, "BackdropTemplate")
right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
right:SetPoint("BOTTOMRIGHT", U.main, "BOTTOMRIGHT", -16, 16)
U.etch(right, styles.panel)
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
local name = CreateFrame("EditBox", nil, header, "BackdropTemplate")
name:SetAutoFocus(false); name:SetMaxLetters(60); name:SetHeight(28)
U.etch(name, styles.row, 10)
FGT.RegisterFont(name, "body", 12, "")
name:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3]); name:SetTextInsets(8, 8, 0, 0)
name:SetPoint("TOPLEFT", right, "TOPLEFT", 24, -24)
name:SetWidth(340)
local nameLabel = Label(header, "Set name", 10, 22, -6)
nameLabel:ClearAllPoints(); nameLabel:SetPoint("BOTTOMLEFT", name, "TOPLEFT", 0, 4)
local status = U.font(header, 10)
status:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
status:SetJustifyH("LEFT"); status:SetWordWrap(false)
local options = Button(header, "...", 30, 28)
options:SetPoint("TOPRIGHT", right, "TOPRIGHT", -16, -24)
local add = Button(header, "Add to Goals", 132)
add:SetPoint("RIGHT", options, "LEFT", -8, 0)
local viewGoal = Button(header, "View in Goals", 132)
viewGoal:SetPoint("RIGHT", options, "LEFT", -8, 0)
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

-- The "..." menu: one button per action, laid out from what applies to the open set.
local actions = CreateFrame("Frame", nil, header, "BackdropTemplate")
actions:SetSize(176, 112); actions:SetPoint("TOPRIGHT", options, "BOTTOMRIGHT", 0, -6)
actions:SetFrameLevel(header:GetFrameLevel() + 20); actions:EnableMouse(true)
U.etch(actions, styles.panel); actions:Hide()
local rename = Button(actions, "Rename", 156)
local clear = Button(actions, "Clear items", 156)
local fill = Button(actions, "Fill from equipped", 156)
local duplicate = Button(actions, "Duplicate", 156)
local remove = Button(actions, "Remove from Goals", 156)
local delete = Button(actions, "Delete set", 156)
local cleared, clearedBuild, clearedItems, clearedProgress
local deleteArmed
options:SetScript("OnClick", function() deleteArmed = nil; actions:SetShown(not actions:IsShown()) end)
options:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Set options", 1, 1, 1); GameTooltip:Show()
end)
options:HookScript("OnLeave", function() GameTooltip:Hide() end)
local empty = Label(header, "Create a set to begin.", 14, 20, -100)
-- First visit: a way in that does not need the + New button on the other side of the screen.
local startNew = Button(header, "Create a set", 150); startNew:SetPoint("TOPLEFT", empty, "BOTTOMLEFT", 0, -12)
local startHunter = Button(header, "Hunter Pre-Raid BiS", 150); startHunter:SetPoint("LEFT", startNew, "RIGHT", 8, 0)

-- ------------------------------------------------------------
-- The character
-- ------------------------------------------------------------
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
-- Dress the model with the planned items. Undress first, so removed items disappear.
local function PaintGear()
    if not model.TryOn then return end
    model:Undress()
    for _, id in ipairs(Cat.SLOT_ORDER) do
        local item = selected and Cat.Get(selected.slots[id])
        if item and not NO_MODEL[item.inv] then
            FGT.ItemInfo(item.id) -- request uncached item data before trying its appearance
            pcall(model.TryOn, model, "item:" .. item.id)
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
-- Items the client had not loaded arrive later; repaint once for a burst of them.
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
    local panel = styles.panel
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

-- ------------------------------------------------------------
-- Equipment slots
-- ------------------------------------------------------------
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
    {"AmmoSlot", "Ammo", "BOTTOM", 4},
}
-- Paladins, Druids and Shamans keep a relic (Libram, Idol, Totem) in the ranged slot.
local function SlotLabel(slot)
    local _, class = UnitClass("player")
    if slot == "RangedSlot" and Cat.UsesRelic(class) then return "Relic" end
    for _, spec in ipairs(slots) do if spec[1] == slot then return spec[2] end end
    return slot
end
local function SlotTexture(slot)
    local _, class = UnitClass("player")
    if slot == "RangedSlot" and Cat.UsesRelic(class) then return "Interface\\PaperDoll\\UI-PaperDoll-Slot-Relic" end
    return FGT.GearPlannerSlotTexture(slot)
end
local slotSpec = {}
for _, spec in ipairs(slots) do
    slotSpec[spec[1]] = spec
    local button = Button(controls, "", 44, 44)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3); button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.plannerSlot = spec[1]
    button.icon:SetTexture(FGT.GearPlannerSlotTexture(spec[1]))
    button.itemName = U.font(button, 11)
    button.itemName:SetText(""); button.itemName:SetWordWrap(false)
    button.itemName:SetShadowColor(0, 0, 0, 1); button.itemName:SetShadowOffset(1, -1)
    if spec[3] == "LEFT" or spec[3] == "BOTTOM" then
        -- every slot reads the same way: icon, then its name on one line
        button.itemName:SetPoint("LEFT", button, "RIGHT", 8, 0)
        button.itemName:SetJustifyH("LEFT")
    elseif spec[3] == "RIGHT" then
        button.itemName:SetPoint("RIGHT", button, "LEFT", -8, 0)
        button.itemName:SetJustifyH("RIGHT")
    end
    slotButtons[spec[1]] = button
end
local function LayoutSlots()
    local available = math.max(1, right:GetHeight() - 152)
    local size = math.min(44, available / 8 - 4)
    size = math.max(20, size)
    -- The bottom row has three or four cells: ammo only for classes that shoot.
    local _, class = UnitClass("player")
    local ammo = Cat.UsesAmmo(class)
    slotButtons.AmmoSlot:SetShown(ammo)
    local cells = ammo and 4 or 3
    for _, spec in ipairs(slots) do
        local button = slotButtons[spec[1]]
        button:SetSize(size, size); button:ClearAllPoints()
        if spec[3] == "BOTTOM" then
            -- Three equal cells across the bottom; each holds the icon and its name, shortened with "..." if long.
            local cell = math.max(110, math.min(240, ((right:GetWidth() or 600) - 44) / cells))
            button.itemName:SetWidth(cell - size - 20)
            button:SetPoint("BOTTOMLEFT", right, "BOTTOM", (spec[4] - 1 - cells / 2) * cell + 8, 18)
        else
            button.itemName:SetWidth(math.max(40, math.min(160, (right:GetWidth() - size * 2 - 100) / 3)))
            button:SetPoint("TOP" .. spec[3], right, "TOP" .. spec[3],
                spec[3] == "LEFT" and 22 or -22, -88 - (spec[4] - 1) * (size + 4))
        end
    end
end
right:HookScript("OnSizeChanged", function(self)
    LayoutSlots()
    status:SetWidth(math.max(80, (self:GetWidth() or 0) - 48))
end)
local head = slotButtons.HeadSlot
local hint = U.font(controls, 10)
hint:SetText("Drag to rotate · Scroll to zoom"); hint:SetPoint("BOTTOM", 0, 76)

-- ------------------------------------------------------------
-- The item picker: search, filters and a recycled list
-- ------------------------------------------------------------
local PICKER_W = 304
local picker = CreateFrame("Frame", nil, controls, "BackdropTemplate")
picker:SetPoint("TOPLEFT", head, "TOPRIGHT", 10, 0)
picker:SetFrameLevel(controls:GetFrameLevel() + 5)
picker:EnableMouse(true)
picker:SetWidth(PICKER_W); picker:SetHeight(400); U.etch(picker, styles.panel); picker:Hide()
local search = SearchBox(picker, "Search items or sets")
search:SetPoint("TOPLEFT", 12, -12); search:SetPoint("TOPRIGHT", -12, -12)
local function FilterButton(width)
    return Button(picker, "", width, 22, 10)
end
local usableBtn, qualityBtn, sortBtn, revealBtn = FilterButton(62), FilterButton(64), FilterButton(86), FilterButton(56)
usableBtn:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -6)
qualityBtn:SetPoint("LEFT", usableBtn, "RIGHT", 4, 0)
sortBtn:SetPoint("LEFT", qualityBtn, "RIGHT", 4, 0)
revealBtn:SetPoint("LEFT", sortBtn, "RIGHT", 4, 0)
local pickerList = U.scroll(picker, 0, 0, 0, 0)
pickerList.scroll:ClearAllPoints()
pickerList.scroll:SetPoint("TOPLEFT", usableBtn, "BOTTOMLEFT", 0, -8)
pickerList.scroll:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -20, 30)
local pickerNote = Label(picker, "", 10, 12, -380)
pickerNote:ClearAllPoints(); pickerNote:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", 12, 10)
pickerNote:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -12, 10)
pickerNote:SetJustifyH("LEFT"); pickerNote:SetWordWrap(false)
pickerNote:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
local noResults = Label(picker, "", 11, 14, -96)
noResults:SetWidth(PICKER_W - 40); noResults:SetJustifyH("LEFT")
noResults:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
local found, foundCount, resultRows = {}, 0, {}
local QUALITY_STEPS = { { 0, "All" }, { 3, "Rare+" }, { 4, "Epic+" } }
local SORT_STEPS = { { "ilvl", "Item level" }, { "name", "Name" }, { "level", "Level" } }
local menu = CreateFrame("Frame", nil, controls, "BackdropTemplate")
menu:SetSize(150, 76); menu:SetPoint("TOPLEFT", head, "TOPRIGHT", 8, 0)
U.etch(menu, styles.panel); menu:Hide()
menu:SetFrameLevel(controls:GetFrameLevel() + 5); menu:EnableMouse(true)
local function Deselect()
    GameTooltip:Hide()
    selectedSlot = nil; picker:Hide(); menu:Hide(); search:ClearFocus()
    for _, button in pairs(slotButtons) do button.chosen = false; PaintButton(button) end
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
local Refresh, Results, PickSet

-- A short line for the set: how much of it is planned, and the average item level.
local function Summary(build)
    local count, scored, total = 0, 0, 0
    for _, slot in ipairs(Cat.SLOT_ORDER) do
        local item = Cat.Get(build.slots[slot])
        if item then
            count = count + 1
            -- shirts, tabards and ammo say nothing about a set's strength
            if slot ~= 0 and slot ~= 4 and slot ~= 19 then scored = scored + 1; total = total + item.ilvl end
        end
    end
    if count == 0 then return nil end
    local _, class = UnitClass("player")
    local slotsShown = Cat.UsesAmmo(class) and 20 or 19
    return string.format("%d of %d slots", count, slotsShown)
        .. (scored > 0 and string.format(" · average item level %d", math.floor(total / scored + 0.5)) or "")
end
local function GoalProgressText(build)
    local goal = build.goalId and FGT.GoalById(build.goalId)
    if not (goal and ForeverGoalTrackerDB.active[build.goalId]) then return nil end
    local done, progress = 0, ForeverGoalTrackerDB.progress[build.goalId] or {}
    for i = 1, #goal.steps do if progress[i] then done = done + 1 end end
    return done, #goal.steps
end

local pendingGoal
-- Typing a name should not rebuild the goals list on every letter.
local function RefreshGoalSoon(goal)
    if pendingGoal then pendingGoal = goal or pendingGoal; return end
    pendingGoal = goal or true
    C_Timer.After(0.35, function()
        local g = pendingGoal ~= true and pendingGoal or nil
        pendingGoal = nil
        FGT.RefreshPlannerGoals(g)
    end)
end
-- immediate: item changes refresh the goal list now; renames can wait for a pause in typing.
local function Save(immediate)
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
        local goal = SyncGoal(selected, U.charKey())
        if immediate then FGT.RefreshPlannerGoals(goal) else RefreshGoalSoon(goal) end
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

-- ------------------------------------------------------------
-- Picker rows (a small pool rebound as the list scrolls)
-- ------------------------------------------------------------
local FOREVER_BLUE = { 0.40, 0.65, 1 }
local function PickItem(item)
    if not selected or not selectedSlot or not item then return end
    local id = slotIds[selectedSlot]
    local moved = false
    if item.unique then
        for other, itemId in pairs(selected.slots) do
            if other ~= id and itemId == item.id then selected.slots[other] = nil; moved = true end
        end
    end
    if item.twoHand then selected.slots[17] = nil end
    if id == 17 then
        local main = Cat.Get(selected.slots[16])
        if main and main.twoHand then selected.slots[16] = nil end
    end
    selected.slots[id] = item.id
    Dress(true); Save(true); Deselect(); Refresh()
    if moved then status:SetText("Moved item to the selected slot.") end
end
-- Plan every piece of a game item set at once; pieces that do not fit are skipped.
PickSet = function(anchor)
    if not selected or not anchor or anchor.set <= 0 then return end
    local taken, count = {}, 0
    for _, item in ipairs(Cat.SetItems(anchor.set)) do
        local slot = Cat.SlotFor(item, taken)
        if slot and not taken[slot] then
            taken[slot] = true; count = count + 1
            selected.slots[slot] = item.id
            if item.twoHand then selected.slots[17] = nil; taken[17] = true end
        end
    end
    Dress(true); Save(true); Deselect(); Refresh()
    status:SetText(count > 0 and ("Added " .. count .. " pieces of " .. (Cat.SetName(anchor.set) or "the set") .. ".")
        or "That set has no pieces for this planner yet.")
end
-- The item tooltip goes on whichever side of the picker faces away from the character.
local function PlaceBesidePicker(tip)
    local px, rx = picker:GetCenter(), right:GetCenter()
    if px and rx and px > rx then tip:SetPoint("TOPRIGHT", picker, "TOPLEFT", -8, 0)
    else tip:SetPoint("TOPLEFT", picker, "TOPRIGHT", 8, 0) end
end
local function BindRow(row, item, index)
    row.item = item
    row:ClearAllPoints(); row:SetPoint("TOPLEFT", pickerList.content, "TOPLEFT", 0, -(index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", pickerList.content, "TOPRIGHT", 0, -(index - 1) * ROW_H)
    row.icon:SetTexture(item.icon)
    row.text:SetText(item.name)
    local c = QUALITY[item.q] or QUALITY[1]
    row.text:SetTextColor(c[1], c[2], c[3])
    row.quality = item.q
    row.chosen = selected and selectedSlot and selected.slots[slotIds[selectedSlot]] == item.id
    local state = FGT.isForever and Cat.ForeverStatus(item)
    local line = (item.forever == 3 and "" or ("iLvl " .. item.ilvl .. " · ")) .. (item.req > 1 and ("Req " .. item.req) or "Any level")
    local sourceLine = Cat.SourceLabel(item)
    if state == "hidden" or item.forever == 3 then sourceLine = sourceLine .. " · Not revealed yet" end
    row.source:SetText((row.chosen and "|T" .. FGT.Icon("check") .. ":10:10|t " or "")
        .. (state == "new" and "|cff66a6ffNew in Forever|r · " or "") .. line .. " · " .. sourceLine)
    local source = Cat.Source(item)
    local entrance = source and source.place and Cat.EntranceFor(source.place)
    row.entrance = entrance
    row.pin:SetShown(entrance ~= nil)
    row.setBtn:SetShown(item.set > 0 and Cat.SetName(item.set) ~= nil)
    PaintButton(row)
    row:Show()
end
local function Rebind()
    local first = math.floor((pickerList.scroll:GetVerticalScroll() or 0) / ROW_H)
    for i, row in ipairs(resultRows) do
        local item = found[first + i]
        if item then BindRow(row, item, first + i) else row.item = nil; row:Hide() end
    end
end
local function EnsureRows(count)
    for i = #resultRows + 1, count do
        local row = Button(pickerList.content, "", 200, ROW_H - 2)
        resultRows[i] = row
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(30, 30); row.icon:SetPoint("LEFT", 6, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 44, -7); row.text:SetPoint("RIGHT", row, "RIGHT", -28, 0)
        row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(false)
        row.source = U.font(row, 9); row.source:SetPoint("TOPLEFT", 44, -25); row.source:SetPoint("RIGHT", row, "RIGHT", -48, 0)
        row.source:SetJustifyH("LEFT"); row.source:SetWordWrap(false)
        row.source:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
        -- Fills every piece of the item's set (Dragonstalker, Lightforge, ...) in one click.
        row.setBtn = Button(row, "+ Set", 38, 16, 9)
        row.setBtn:SetPoint("BOTTOMRIGHT", -6, 5)
        row.setBtn:SetScript("OnClick", function() if row.item then PickSet(row.item) end end)
        row.setBtn:HookScript("OnEnter", function()
            local item = row.item
            if not item then return end
            GameTooltip:SetOwner(row.setBtn, "ANCHOR_TOP")
            GameTooltip:SetText("Add the whole set", 1, 1, 1)
            GameTooltip:AddLine(Cat.SetName(item.set) or "", 0.8, 0.75, 0.65)
            GameTooltip:Show()
        end)
        row.setBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
        row.setBtn:Hide()
        -- Entrance pin: sets the map pin for the dungeon or raid the item comes from.
        row.pin = CreateFrame("Button", nil, row)
        row.pin:SetSize(18, 18); row.pin:SetPoint("TOPRIGHT", -6, -4)
        row.pin.tex = row.pin:CreateTexture(nil, "ARTWORK")
        row.pin.tex:SetAllPoints(); row.pin.tex:SetTexture(FGT.Icon("map-location-white") or FGT.Icon("map-location"))
        row.pin.tex:SetVertexColor(0.65, 0.65, 0.65)
        row.pin:SetScript("OnEnter", function(self)
            self.tex:SetVertexColor(0.80, 0.62, 0.16)
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Show entrance on map", 1, 1, 1)
            if row.entrance then GameTooltip:AddLine(row.entrance.name .. ", " .. (row.entrance.zone or ""), 0.8, 0.75, 0.65) end
            GameTooltip:Show()
        end)
        row.pin:SetScript("OnLeave", function(self) self.tex:SetVertexColor(0.65, 0.65, 0.65); GameTooltip:Hide() end)
        row.pin:SetScript("OnClick", function() if row.entrance then FGT.ShowNpcOnMap(row.entrance.id) end end)
        row.pin:Hide()
        row:SetScript("OnClick", function(self, button)
            local item = self.item
            if not item then return end
            -- Shift-click links, right-click opens Wowhead, Ctrl-click tries it on: same as step items.
            if FGT.StepLinkClick({ itemId = item.id, text = { GetText = function() return item.name end } }, button) then return end
            PickItem(item)
        end)
        row:SetScript("OnEnter", function(self) self.hovered = true; Hover(self, true); PaintButton(self) end)
        row:SetScript("OnLeave", function(self) self.hovered = false; Hover(self, false); PaintButton(self) end)
        -- Only the thumbnail opens the item tooltip, beside the picker so it never covers the list.
        row.thumb = CreateFrame("Frame", nil, row)
        row.thumb:SetAllPoints(row.icon); row.thumb:EnableMouse(true)
        row.thumb:SetScript("OnMouseUp", function(_, button) row:GetScript("OnClick")(row, button) end)
        row.thumb:SetScript("OnLeave", function() row:GetScript("OnLeave")(row); GameTooltip:Hide() end)
        row.thumb:SetScript("OnEnter", function()
            row:GetScript("OnEnter")(row)
            local item = row.item
            if not item then return end
            FGT.ShowItemTip(row.thumb, item.id, nil, item.name, false, function(tip)
                tip:AddLine(" ")
                tip:AddLine(Cat.SourceLabel(item), 0.8, 0.75, 0.65, true)
                local set = Cat.SetName(item.set)
                if set then tip:AddLine("Part of " .. set, 0.8, 0.75, 0.65) end
                if FGT.isForever and Cat.ForeverStatus(item) == "hidden" then
                    tip:AddLine("Not revealed in Forever yet", 1.00, 0.50, 0.42)
                end
                tip:AddLine("Click: plan this item", colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
            end, PlaceBesidePicker)
        end)
        row:Hide()
    end
end

local function PaintFilters()
    local pref = Prefs()
    usableBtn.text:SetText("Usable"); usableBtn.chosen = pref.usable; PaintButton(usableBtn)
    for _, step in ipairs(QUALITY_STEPS) do if step[1] == pref.quality then qualityBtn.text:SetText(step[2]) end end
    qualityBtn.chosen = pref.quality > 0; PaintButton(qualityBtn)
    for _, step in ipairs(SORT_STEPS) do if step[1] == pref.sort then sortBtn.text:SetText(step[2]) end end
    revealBtn.text:SetText("Revealed"); revealBtn.chosen = pref.revealed; PaintButton(revealBtn)
    revealBtn:SetShown(FGT.isForever and true or false)
end
Results = function(keepScroll)
    if not selectedSlot then return end
    local pref = Prefs()
    local _, class = UnitClass("player")
    local _, count = Cat.Search(selectedSlot, { class = class, faction = UnitFactionGroup("player"),
        usable = pref.usable, level = UnitLevel("player"), minQuality = pref.quality,
        ammo = selectedSlot == "AmmoSlot" and selected and Cat.AmmoFor(Cat.Get(selected.slots[18])) or nil, sort = pref.sort, text = search:GetText(),
        revealedOnly = FGT.isForever and pref.revealed }, found)
    foundCount = count
    pickerList.content:SetHeight(math.max(1, count * ROW_H))
    if not keepScroll then pickerList.scroll:SetVerticalScroll(0) end
    EnsureRows(POOL_ROWS)
    pickerList:Finalize(); pickerList:Update(); Rebind()
    local text = search:GetText() or ""
    noResults:SetText(count == 0 and (text == "" and "No items for this slot." or "No matching items.")
        .. (pref.usable and "\nTurn off Usable to see everything." or "") or "")
    pickerNote:SetText(count == 0 and "" or (count .. (count == 1 and " item" or " items")
        .. " · Sources are shown where known"))
end
-- Keep rows bound while scrolling (the scroll area calls Update on every move).
do
    local baseUpdate = pickerList.Update
    local lastFirst
    function pickerList:Update()
        baseUpdate(self)
        local first = math.floor((self.scroll:GetVerticalScroll() or 0) / ROW_H)
        if first ~= lastFirst then lastFirst = first; Rebind() end
    end
end
search:HookScript("OnTextChanged", function() Results(false) end)
search:SetScript("OnEscapePressed", Deselect)
search:SetScript("OnEnterPressed", function() if found[1] then PickItem(found[1]) end end)
usableBtn:SetScript("OnClick", function() Prefs().usable = not Prefs().usable; PaintFilters(); Results() end)
revealBtn:SetScript("OnClick", function() Prefs().revealed = not Prefs().revealed; PaintFilters(); Results() end)
qualityBtn:SetScript("OnClick", function()
    local pref, nextIndex = Prefs(), 1
    for i, step in ipairs(QUALITY_STEPS) do if step[1] == pref.quality then nextIndex = i % #QUALITY_STEPS + 1 end end
    pref.quality = QUALITY_STEPS[nextIndex][1]; PaintFilters(); Results()
end)
sortBtn:SetScript("OnClick", function()
    local pref, nextIndex = Prefs(), 1
    for i, step in ipairs(SORT_STEPS) do if step[1] == pref.sort then nextIndex = i % #SORT_STEPS + 1 end end
    pref.sort = SORT_STEPS[nextIndex][1]; PaintFilters(); Results()
end)
for button, text in pairs({ [usableBtn] = "Show only your armor type and the weapons your class can use",
    [qualityBtn] = "Lowest item quality shown", [sortBtn] = "Sort the list",
    [revealBtn] = "Hide items Forever has not revealed yet" }) do
    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(text, 1, 1, 1); GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function PositionPopup(frame)
    local button = slotButtons[selectedSlot]
    if not button then return end
    local spec = slotSpec[selectedSlot]
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
-- As tall as the room allows from the selected slot, so the picker never leaves the panel.
local function PickerHeight()
    local button, spec = slotButtons[selectedSlot], slotSpec[selectedSlot]
    local top, bottom = right:GetTop(), right:GetBottom()
    local edge = button and (spec[3] == "BOTTOM" and button:GetTop() or (spec[4] >= 5 and button:GetBottom() or button:GetTop()))
    if not (top and bottom and edge) then return PICKER_MAX end
    local room
    if spec[3] == "BOTTOM" then room = (top - 84) - (edge + 8)       -- grows upward from the weapon row
    elseif spec[4] >= 5 then room = (top - 84) - edge                -- lower slots: grows upward
    else room = edge - (bottom + 12) end                             -- upper slots: grows downward
    return math.max(PICKER_MIN, math.min(PICKER_MAX, room))
end
local function OpenPicker()
    if not selectedSlot then return end
    slotButtons[selectedSlot].chosen = true; PaintButton(slotButtons[selectedSlot])
    GameTooltip:Hide(); menu:Hide()
    picker:SetHeight(PickerHeight())
    PositionPopup(picker); FadeIn(picker); search:SetText("")
    PaintFilters(); Results(); Focus(selectedSlot)
end

-- ------------------------------------------------------------
-- Slot buttons
-- ------------------------------------------------------------
for _, spec in ipairs(slots) do
    local slot = spec[1]
    local button = slotButtons[slot]
    button:SetScript("OnClick", function()
        Deselect(); selectedSlot = slot; button.chosen = true; PaintButton(button)
        if selected and selected.slots[slotIds[slot]] then
            PositionPopup(menu); FadeIn(menu); Focus(slot)
        else OpenPicker() end
    end)
    button:SetScript("OnEnter", function(self)
        self.hovered = true; Hover(self, true)
        self.icon:SetAlpha(1)
        PaintButton(self)
        if selectedSlot == slot and (menu:IsShown() or picker:IsShown()) then return end
        local item = selected and Cat.Get(selected.slots[slotIds[slot]])
        if item then
            FGT.ShowItemTip(self, item.id, nil, item.name, false, function(tip)
                tip:AddLine(" "); tip:AddLine(Cat.SourceLabel(item), 0.8, 0.75, 0.65, true)
            end)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local shown = SlotLabel(slot)
            self.itemName:SetText(shown); self.itemName:SetTextColor(0.8, 0.75, 0.65)
            GameTooltip:SetText(shown, 1, 1, 1); GameTooltip:AddLine("Choose item", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self.hovered = false; Hover(self, false)
        PaintButton(self)
        self.icon:SetAlpha(selected and selected.slots[slotIds[slot]] and 1 or 0.65)
        if not (selected and selected.slots[slotIds[slot]]) then self.itemName:SetText("") end
        GameTooltip:Hide()
    end)
end
replace:SetScript("OnClick", OpenPicker)
unequip:SetScript("OnClick", function()
    if selected and selectedSlot then selected.slots[slotIds[selectedSlot]] = nil; Dress(true); Save(true); Refresh() end
    Deselect()
end)

-- ------------------------------------------------------------
-- Set list and header state
-- ------------------------------------------------------------
local menuY
local function Place(button, show)
    button:SetShown(show)
    if show then button:ClearAllPoints(); button:SetPoint("TOPLEFT", 10, -menuY); menuY = menuY + 34 end
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
            local done, total = GoalProgressText(build)
            row.state:SetText(done and ("In My Goals · " .. done .. "/" .. total) or "Draft")
            row.chosen = build == selected
            PaintButton(row)
            row:SetScript("OnClick", function() store.selected = build.id; Choose(build) end); row:Show()
        end
    end
    listEmpty:SetShown(visible == 0)
    list.content:SetHeight(math.max(1, visible * 54)); list:Finalize(); list:Update()
    empty:SetShown(not selected)
    startNew:SetShown(not selected)
    local _, class = UnitClass("player")
    local preset = Cat.PRESETS.hunter_preraid_wowhead
    startHunter:SetShown(not selected and class == preset.class and UnitFactionGroup("player") == preset.faction)
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
    else
        local summary = Summary(selected)
        local done, total = GoalProgressText(selected)
        if tracked then
            status:SetText("In My Goals · " .. (done or 0) .. " of " .. (total or 0) .. " collected" .. (summary and (" · " .. summary) or ""))
        elseif not summary then
            status:SetText("Choose a slot to start building your set.")
        else
            status:SetText((selected.name ~= "" and "Draft · Not in Goals" or "Name your set before adding it.") .. " · " .. summary)
        end
    end
    add:SetShown(selected ~= nil and not tracked)
    viewGoal:SetShown(tracked and true or false)
    local canAdd = selected ~= nil and next(selected.slots) ~= nil
    add:SetEnabled(canAdd)
    add.chosen = canAdd
    PaintButton(add)
    add.text:SetAlpha(canAdd and 1 or 0.4)
    options:SetShown(selected ~= nil)
    -- menu: only what applies, stacked from the top
    menuY = 8
    Place(rename, true)
    clear.text:SetText(clearedBuild == selected and "Undo clear" or "Clear items")
    Place(clear, true)
    Place(fill, true)
    Place(duplicate, selected ~= nil and selected.id ~= nil)
    Place(remove, tracked and true or false)
    delete.text:SetText(deleteArmed and "Click again to delete" or "Delete set")
    Place(delete, selected ~= nil and selected.id ~= nil)
    actions:SetHeight(menuY + 4)
    for slot, button in pairs(slotButtons) do
        local item = selected and Cat.Get(selected.slots[slotIds[slot]])
        button.icon:SetTexture(item and item.icon or SlotTexture(slot))
        button.itemName:SetText(item and item.name or "")
        local c = item and QUALITY[item.q]
        if c then button.itemName:SetTextColor(c[1], c[2], c[3]) end
        button.quality = item and item.q or nil
        button.icon:SetAlpha((item or button.chosen) and 1 or 0.65)
        PaintButton(button)
    end
end

-- ------------------------------------------------------------
-- Set actions
-- ------------------------------------------------------------
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
viewGoal:SetScript("OnClick", function()
    if not (selected and selected.goalId) then return end
    FGT.ShowTab("tracker"); FGT.SelectGoal(selected.goalId)
end)
new:SetScript("OnClick", function() draft = { name = "", slots = {} }; draftOwner = U.charKey(); Choose(draft); editingName = true; Refresh(); name:SetFocus() end)
startNew:SetScript("OnClick", function() new:GetScript("OnClick")() end)
startHunter:SetScript("OnClick", function() FGT.CreateHunterPreRaidBuild() end)
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
    Deselect(); Dress(true); Save(true); Refresh()
end)
-- Start from what the character is wearing now: only items the database knows.
fill:SetScript("OnClick", function()
    if not selected then return end
    local count = 0
    for _, slot in ipairs(Cat.SLOT_ORDER) do
        local id = GetInventoryItemID and GetInventoryItemID("player", slot)
        if id and Cat.Get(id) then selected.slots[slot] = id; count = count + 1 end
    end
    actions:Hide(); Deselect(); Dress(true); Save(true); Refresh()
    status:SetText(count > 0 and ("Added " .. count .. " equipped items.") or "No equipped items found in the database.")
end)
duplicate:SetScript("OnClick", function()
    if not (selected and selected.id) then return end
    local store = Store()
    local copy = { id = store.nextId, name = selected.name .. " copy", slots = {} }
    store.nextId = store.nextId + 1
    for slot, id in pairs(selected.slots) do copy.slots[slot] = id end
    store.builds[#store.builds + 1] = copy; store.selected = copy.id
    actions:Hide(); Choose(copy)
end)
remove:SetScript("OnClick", function()
    if not selected or not selected.goalId then return end
    ForeverGoalTrackerDB.active[selected.goalId] = nil
    -- Keep the set and its credit so Add to Goals can restore it without loss.
    actions:Hide(); FGT.RefreshPlannerGoals(); Refresh()
end)
delete:SetScript("OnClick", function()
    if not (selected and selected.id) then return end
    if not deleteArmed then deleteArmed = true; Refresh(); return end
    deleteArmed = nil
    local store, DB = Store(), ForeverGoalTrackerDB
    if selected.goalId then
        DB.active[selected.goalId] = nil; DB.progress[selected.goalId] = nil
        local goal = FGT.GoalById(selected.goalId)
        if goal then goal.steps = {} end
    end
    for i, build in ipairs(store.builds) do if build == selected then table.remove(store.builds, i); break end end
    store.selected = store.builds[1] and store.builds[1].id or nil
    actions:Hide(); FGT.RefreshPlannerGoals()
    Choose(store.builds[1])
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
name:HookScript("OnEditFocusGained", function()
    name:SetBackdropBorderColor(colors.GOLD2[1], colors.GOLD2[2], colors.GOLD2[3], 1)
end)
name:HookScript("OnEditFocusLost", function()
    name:SetBackdropBorderColor(styles.row.edge[1], styles.row.edge[2], styles.row.edge[3], 1)
end)
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
    Cat.Release(selected and selected.slots) -- the slot lists are rebuilt on demand
end)

-- From a planner goal's page: open the set it came from (only on the character that owns it).
function FGT.OpenGearSet(goal)
    if not (goal and goal.plannerOwner == U.charKey()) then return false end
    local store = Store()
    for _, build in ipairs(store.builds) do
        if build.goalId == goal.id then
            store.selected = build.id; draft = nil
            FGT.ShowTab("gear")
            if P:IsShown() then Choose(build) end
            return true
        end
    end
    return false
end

-- ------------------------------------------------------------
-- Ready-made sets
-- ------------------------------------------------------------
-- Explicit test-build import; never changes another character or an existing set.
function FGT.CreateHunterPreRaidBuild()
    local presetId = "hunter_preraid_wowhead"
    local preset = Cat.PRESETS[presetId]
    local _, class = UnitClass("player")
    if class ~= preset.class or UnitFactionGroup("player") ~= preset.faction then
        print("Forever Goal Tracker: This test build is for an Alliance Hunter."); return
    end
    local store = Store()
    local build
    for _, existing in ipairs(store.builds) do
        if existing.preset == presetId then build = existing; break end
    end
    if not build then
        build = { id = store.nextId, name = preset.name, slots = {}, preset = presetId }
        store.nextId = store.nextId + 1
        for slot, id in pairs(preset.slots) do build.slots[slot] = id end
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
    name = name, setTitle = setTitle, editName = editName, add = add, viewGoal = viewGoal, options = options, actions = actions,
    clear = clear, remove = remove, rename = rename, fill = fill, duplicate = duplicate, delete = delete,
    camera = camera, turn = turn, appearance = appearance, menu = menu, replace = replace, rows = rows, head = head,
    picker = picker, results = resultRows, unequip = unequip, search = search, filters = { usable = usableBtn,
        quality = qualityBtn, sort = sortBtn, reveal = revealBtn }, list = pickerList, found = function() return found, foundCount end,
    modelArea = modelArea, model = model, clickAway = clickAway, slots = slotButtons }
