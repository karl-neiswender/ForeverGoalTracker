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

local catalogue = {
    { class = "WARRIOR", name = "Helm of Might", id = 16866, icon = "Interface\\Icons\\inv_helmet_09", source = "Garr — Molten Core" },
    { class = "PALADIN", name = "Lawbringer Helm", id = 16854, icon = "Interface\\Icons\\inv_helmet_05", source = "Garr — Molten Core" },
    { class = "HUNTER", name = "Giantstalker's Helmet", id = 16846, icon = "Interface\\Icons\\inv_helmet_05", source = "Garr — Molten Core" },
    { class = "ROGUE", name = "Nightslayer Cover", id = 16821, icon = "Interface\\Icons\\inv_helmet_41", source = "Garr — Molten Core" },
    { class = "PRIEST", name = "Circlet of Prophecy", id = 16813, icon = "Interface\\Icons\\inv_helmet_34", source = "Garr — Molten Core" },
    { class = "SHAMAN", name = "Earthfury Helmet", id = 16842, icon = "Interface\\Icons\\inv_helmet_09", source = "Garr — Molten Core" },
    { class = "MAGE", name = "Arcanist Crown", id = 16795, icon = "Interface\\Icons\\inv_helmet_53", source = "Garr — Molten Core" },
    { class = "WARLOCK", name = "Felheart Horns", id = 16808, icon = "Interface\\Icons\\inv_helmet_08", source = "Garr — Molten Core" },
    { class = "DRUID", name = "Cenarion Helm", id = 16834, icon = "Interface\\Icons\\inv_helmet_09", source = "Garr — Molten Core" },
    { class = "WARRIOR", name = "Dreadnaught Helmet", id = 22418, icon = "Interface\\Icons\\inv_helmet_58", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "PALADIN", name = "Redemption Headpiece", id = 22428, icon = "Interface\\Icons\\inv_helmet_15", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "HUNTER", name = "Cryptstalker Headpiece", id = 22438, icon = "Interface\\Icons\\inv_helmet_15", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "ROGUE", name = "Bonescythe Helmet", id = 22478, icon = "Interface\\Icons\\inv_helmet_58", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "PRIEST", name = "Circlet of Faith", id = 22514, icon = "Interface\\Icons\\inv_crown_01", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "DRUID", name = "Dreamwalker Headpiece", id = 22490, icon = "Interface\\Icons\\inv_helmet_15", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "MAGE", name = "Frostfire Circlet", id = 22498, icon = "Interface\\Icons\\inv_crown_01", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "WARLOCK", name = "Plagueheart Circlet", id = 22506, icon = "Interface\\Icons\\inv_crown_01", source = "Tier 3 turn-in — Light's Hope Chapel" },
    { class = "SHAMAN", name = "Earthshatter Headpiece", id = 22466, icon = "Interface\\Icons\\inv_helmet_15", source = "Tier 3 turn-in — Light's Hope Chapel" },
}
local function Store()
    local db = ForeverGoalTrackerDB
    db.gearPlanner = db.gearPlanner or { version = 1, characters = {} }
    local key = U.charKey()
    local chars = db.gearPlanner.characters
    chars[key] = chars[key] or { nextId = 1, builds = {} }
    return chars[key]
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
    b:SetScript("OnEnter", function() b:SetEtch(U.styles.btnHover) end)
    b:SetScript("OnLeave", function() b:SetEtch(U.styles.button) end)
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
list.scroll:ClearAllPoints(); list.scroll:SetPoint("TOPLEFT", 12, -108)
list.scroll:SetPoint("BOTTOMRIGHT", -20, 16)
local rows, selected, draft, changing = {}, nil, nil, false
local name = CreateFrame("EditBox", nil, right, "InputBoxTemplate")
name:SetAutoFocus(false); name:SetMaxLetters(60); name:SetHeight(28)
name:SetPoint("TOP", right, "TOP", 0, -24)
name:SetWidth(340)
name:SetFontObject("GameFontHighlight")
local nameLabel = Label(right, "Set name", 10, 22, -6)
nameLabel:ClearAllPoints(); nameLabel:SetPoint("BOTTOMLEFT", name, "TOPLEFT", 0, 4)
local status = U.font(right, 10)
status:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
right:SetScript("OnSizeChanged", function(_, w) name:SetWidth(math.min(340, math.max(120, w - 48))) end)
local empty = Label(right, "Create a build to begin.", 14, 20, -100)
local modelArea = CreateFrame("Frame", nil, right)
modelArea:SetPoint("TOPLEFT", 16, -88); modelArea:SetPoint("BOTTOMRIGHT", -16, 62)
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
    bg:SetAlpha(0.18)
    bg:SetPoint("TOPLEFT", modelArea, "TOPLEFT", 0, 0)
    -- Layout is set on resize so the quadrants remain a continuous background.
    modelArea["bg" .. i] = { texture = bg, rect = backgroundTiles[i] }
end
local model = CreateFrame("DressUpModel", nil, modelArea)
if model.SetAutoDress then model:SetAutoDress(false) end
model:SetPoint("CENTER", modelArea, "CENTER", 0, 0)
model:SetSize(260, 340)
model:EnableMouse(true); model:EnableMouseWheel(true)
local zoom, facing, dragX = 0, 0, nil
local camera = CreateFrame("Frame", nil, P)
local function ApplyZoom(value)
    zoom = value
    -- A portrait-shaped viewport avoids the wide panel magnifying the body.
    -- Leave extra distance for helmets and feet in the full-character view.
    if model.SetCamDistanceScale then model:SetCamDistanceScale(1.3 - value * 0.3) end
    if model.SetPortraitZoom then model:SetPortraitZoom(value) end
end
local function Focus(on)
    local start, target, elapsed = zoom, on and 0.9 or 0, 0
    camera:SetScript("OnUpdate", nil)
    if FGT.Setting("celebrations") == "off" then ApplyZoom(target); model:SetAlpha(1); return end
    camera:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / 0.4)
        local eased = t * t * (3 - 2 * t)
        ApplyZoom(start + (target - start) * eased)
        model:SetAlpha(1 - 0.28 * math.sin(math.pi * t))
        if t == 1 then camera:SetScript("OnUpdate", nil); model:SetAlpha(1) end
    end)
end
local function Dress()
    if not model.TryOn then return end
    model:Undress()
    if selected and selected.slots[1] then model:TryOn("item:" .. selected.slots[1]) end
end
model:SetScript("OnModelLoaded", function() Dress(); ApplyZoom(zoom) end)
local function Rotate()
    if not dragX then return end
    if not IsMouseButtonDown("LeftButton") then dragX = nil; model:SetScript("OnUpdate", nil); return end
    local x = GetCursorPosition()
    facing = facing + (x - dragX) * 0.01; dragX = x; model:SetFacing(facing)
end
model:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then dragX = GetCursorPosition(); model:SetScript("OnUpdate", Rotate) end
end)
model:SetScript("OnMouseUp", function() dragX = nil; model:SetScript("OnUpdate", nil) end)
model:SetScript("OnMouseWheel", function(_, delta)
    camera:SetScript("OnUpdate", nil); model:SetAlpha(1)
    ApplyZoom(math.max(0, math.min(1, zoom + delta * 0.1)))
end)
-- Soft masks cover all four background edges without masking slot controls.
local masks = CreateFrame("Frame", nil, modelArea)
masks:SetAllPoints(); masks:SetFrameLevel(model:GetFrameLevel() + 1)
for side = 1, 4 do
    local t = masks:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(0.05, 0.045, 0.04, 1)
    if side <= 2 then
        t:SetWidth(100); t:SetPoint(side == 1 and "TOPLEFT" or "TOPRIGHT")
        t:SetPoint(side == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT")
        U.gradient(t, {0.05,0.045,0.04}, {0.05,0.045,0.04}, side == 1 and 1 or 0, side == 1 and 0 or 1)
    else
        t:SetHeight(70); t:SetPoint(side == 3 and "TOPLEFT" or "BOTTOMLEFT")
        t:SetPoint(side == 3 and "TOPRIGHT" or "BOTTOMRIGHT")
        FGT.PopoutUI.vgradient(t, {0.05,0.045,0.04}, {0.05,0.045,0.04}, side == 3 and 1 or 0, side == 3 and 0 or 1)
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
    local height = math.max(1, h - 36)
    model:SetSize(math.min(w, height * 0.85), height)
    ApplyZoom(zoom)
end
modelArea:SetScript("OnSizeChanged", LayoutPreview)
local controls = CreateFrame("Frame", nil, right)
controls:SetAllPoints(); controls:SetFrameLevel(masks:GetFrameLevel() + 2)
local head = Button(controls, "Head", 54, 54); head:SetPoint("TOPLEFT", 22, -96)
head.icon = head:CreateTexture(nil, "ARTWORK"); head.icon:SetAllPoints()
local toggle = Button(controls, "Full character", 126)
toggle:SetPoint("BOTTOM", -65, 18)
local refocus = Button(controls, "Focus head", 116); refocus:SetPoint("LEFT", toggle, "RIGHT", 8, 0)
toggle:SetScript("OnClick", function() Focus(false) end)
refocus:SetScript("OnClick", function() Focus(true) end)
local hint = Label(controls, "Drag to rotate · Scroll to zoom", 10, 20, -160)
local picker = CreateFrame("Frame", nil, controls, "BackdropTemplate")
picker:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -40)
picker:SetWidth(244); picker:SetHeight(176); U.etch(picker, U.styles.panel); picker:Hide()
local search = CreateFrame("EditBox", nil, picker, "InputBoxTemplate")
search:SetAutoFocus(false); search:SetSize(208, 26); search:SetPoint("TOPLEFT", 16, -12)
search:SetFontObject("GameFontHighlight")
Label(picker, "Tier 1 + 3 helm test list", 10, 12, -150)
local noResults = Label(picker, "", 11, 12, -48)
local resultRows = {}
local menu = CreateFrame("Frame", nil, controls, "BackdropTemplate")
menu:SetSize(150, 76); menu:SetPoint("TOPLEFT", head, "TOPRIGHT", 8, 0)
U.etch(menu, U.styles.panel); menu:Hide()
local replace = Button(menu, "Replace", 130); replace:SetPoint("TOPLEFT", 10, -8)
local unequip = Button(menu, "Unequip", 130); unequip:SetPoint("TOPLEFT", 10, -40)
local Refresh, Results
local function Save()
    if not selected then return end
    local value = (name:GetText() or ""):match("^%s*(.-)%s*$")
    selected.name = value
    if value ~= "" and draft == selected then
        local store = Store(); selected.id = store.nextId; store.nextId = store.nextId + 1
        store.builds[#store.builds + 1] = selected; store.selected = selected.id; draft = nil
    end
    status:SetText(value == "" and "Name your set to save it." or "Saved")
end
local function Choose(build)
    selected = build; changing = true; name:SetText(build and build.name or ""); changing = false
    picker:Hide(); menu:Hide(); Focus(false)
    model:SetUnit("player"); model:SetFacing(facing); Dress()
    LayoutPreview(modelArea, modelArea:GetWidth(), modelArea:GetHeight())
    Refresh()
end
Refresh = function()
    local store = Store()
    owner:SetText(UnitName("player") or "")
    for _, row in ipairs(rows) do row:Hide() end
    for i, build in ipairs(store.builds) do
        local row = rows[i]
        if not row then row = Button(list.content, "", 180, 34); rows[i] = row end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 2, -(i - 1) * 40)
        row:SetWidth(math.max(120, left:GetWidth() - 40))
        row.text:SetWidth(math.max(100, left:GetWidth() - 60))
        row.text:SetText(build.name ~= "" and build.name or "Name your set")
        row:SetEtch(build == selected and U.styles.rowSel or U.styles.button)
        row:SetScript("OnClick", function() store.selected = build.id; Choose(build) end); row:Show()
    end
    list.content:SetHeight(math.max(1, #store.builds * 40)); list:Finalize(); list:Update()
    empty:SetShown(not selected); name:SetShown(selected ~= nil)
    modelArea:SetShown(selected ~= nil); controls:SetShown(selected ~= nil)
    status:SetText(not selected and "Create a build to begin."
        or (selected and selected.name == "") and "Name your set to save it." or "Saved")
    local item
    for _, entry in ipairs(catalogue) do if selected and entry.id == selected.slots[1] then item = entry end end
    head.icon:SetTexture(item and item.icon or nil); head.text:SetText(item and "" or "Head")
end
Results = function()
    local _, class = UnitClass("player")
    local query = (search:GetText() or ""):lower(); local count = 0
    for _, row in ipairs(resultRows) do row:Hide() end
    for _, entry in ipairs(catalogue) do
        if entry.class == class and entry.name:lower():find(query, 1, true) then
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
            row.source:SetText(entry.source)
            row:SetScript("OnClick", function()
                if not selected then return end
                selected.slots[1] = entry.id; Dress(); Save(); Refresh()
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
    noResults:SetText(count == 0 and "No matching helms in this test list." or "")
end
search:SetScript("OnTextChanged", Results)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus(); picker:Hide() end)
local function OpenPicker()
    menu:Hide(); picker:Show(); search:SetText(""); Results(); Focus(true)
end
head:SetScript("OnClick", function()
    if selected and selected.slots[1] then menu:SetShown(not menu:IsShown()); picker:Hide()
    else OpenPicker() end
end)
head:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if selected and selected.slots[1] then GameTooltip:SetHyperlink("item:" .. selected.slots[1])
    else GameTooltip:SetText("Head", 1, 1, 1); GameTooltip:AddLine("Choose a helm", 1, 1, 1) end
    GameTooltip:Show()
end)
head:SetScript("OnLeave", function() GameTooltip:Hide() end)
replace:SetScript("OnClick", OpenPicker)
unequip:SetScript("OnClick", function()
    if selected then selected.slots[1] = nil; Dress(); Save(); Refresh() end
    menu:Hide()
end)
new:SetScript("OnClick", function() draft = { name = "", slots = {} }; Choose(draft); name:SetFocus() end)
name:SetScript("OnTextChanged", function() if not changing then Save(); Refresh() end end)
name:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
name:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
P:SetScript("OnShow", function()
    local store = Store(); selected = nil
    for _, build in ipairs(store.builds) do if build.id == store.selected then selected = build end end
    Choose(draft or selected or store.builds[1])
end)
P:SetScript("OnHide", function()
    camera:SetScript("OnUpdate", nil); model:SetScript("OnUpdate", nil); model:SetAlpha(1); dragX = nil
    name:ClearFocus(); search:ClearFocus(); GameTooltip:Hide()
end)
-- Expose only prototype operations needed by regression checks.
FGT.GearPlannerTest = { store = Store, new = function() new:GetScript("OnClick")() end,
    name = name, head = head, picker = picker, results = resultRows, unequip = unequip,
    modelArea = modelArea, model = model }
