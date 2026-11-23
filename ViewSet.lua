local ADDON, FGT = ...

-- ============================================================
-- View set (Karl, 2026-11-22): a small window that shows a Gear Planner set on its character,
-- staged as the planner stages it: the race's backdrop, its weather, the soft light and the
-- shadow under the feet, the resting camera, and the planner's helm, cloak, weapon and sheathe
-- choices. View only: nothing here changes the set. Drag the character to turn it; drag the
-- title bar to move the window; the X or Escape closes it. Opened from the eye on a Gear Planner
-- goal's page (Core.lua, FGT.viewSetBtn).
-- ============================================================
local U, Cat, GV = FGT.MaterialsUI, FGT.GearCatalog, FGT.GearView
if not (U and Cat and GV) then return end
local C = U.colors

local V = CreateFrame("Frame", "ForeverGoalTrackerViewSet", UIParent, "BackdropTemplate")
FGT.ViewSet = V
V:SetSize(460, 620)
V:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
V:SetFrameStrata("DIALOG"); V:SetToplevel(true); V:SetClampedToScreen(true)
V:SetMovable(true); V:EnableMouse(true); V:RegisterForDrag("LeftButton")
V:SetScript("OnDragStart", V.StartMoving)
V:SetScript("OnDragStop", V.StopMovingOrSizing)
V:Hide()
U.etch(V, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
if UISpecialFrames then table.insert(UISpecialFrames, "ForeverGoalTrackerViewSet") end -- Escape closes it

V.title = U.title(V, 13)
V.title:SetPoint("TOPLEFT", 14, -11)
V.title:SetPoint("RIGHT", V, "RIGHT", -40, 0)
V.title:SetJustifyH("LEFT"); V.title:SetWordWrap(false)
V.sub = U.font(V, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
V.sub:SetPoint("TOPLEFT", V.title, "BOTTOMLEFT", 0, -3)
V.sub:SetPoint("RIGHT", V, "RIGHT", -40, 0)
V.sub:SetJustifyH("LEFT"); V.sub:SetWordWrap(false)

local close = CreateFrame("Button", nil, V)
V.close = close
close:SetSize(22, 22)
close:SetPoint("TOPRIGHT", V, "TOPRIGHT", -9, -9)
close.icon = close:CreateTexture(nil, "ARTWORK")
close.icon:SetTexture(FGT.Icon("close-white")); close.icon:SetSize(13, 13); close.icon:SetPoint("CENTER")
local function Tint(on)
    local c = on and C.ACCENT or C.SUBTEXT
    close.icon:SetVertexColor(c[1], c[2], c[3], on and 1 or 0.85)
end
Tint(false)
close:SetScript("OnEnter", function() Tint(true) end)
close:SetScript("OnLeave", function() Tint(false) end)
close:SetScript("OnClick", function() V:Hide() end)

-- ------------------------------------------------------------
-- The stage: the planner's, in its own window
-- ------------------------------------------------------------
local area = CreateFrame("Frame", nil, V)
area:SetPoint("TOPLEFT", V, "TOPLEFT", 6, -46)
area:SetPoint("BOTTOMRIGHT", V, "BOTTOMRIGHT", -6, 6)
area:SetClipsChildren(true)
local bg = CreateFrame("Frame", nil, area)
bg:SetAllPoints()
bg.texture = bg:CreateTexture(nil, "BACKGROUND")
bg.texture:SetAlpha(0.18)
bg.light = bg:CreateTexture(nil, "BORDER")
bg.light:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
bg.light:SetBlendMode("ADD"); bg.light:SetVertexColor(1, 1, 1)
bg.shadow = bg:CreateTexture(nil, "ARTWORK")
bg.shadow:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
bg.shadow:SetVertexColor(GV.side[1], GV.side[2], GV.side[3])
local shades = {}
for i = 1, 27 do
    shades[i] = bg:CreateTexture(nil, "OVERLAY")
    shades[i]:SetColorTexture(1, 1, 1, 1)
end
local model = CreateFrame("DressUpModel", nil, area)
V.model, V.area, V.backdrop = model, area, bg
model:SetFrameLevel(bg:GetFrameLevel() + 1)
if model.SetAutoDress then model:SetAutoDress(false) end
model:SetAllPoints(area)
model:EnableMouse(true)
-- (on its own layer over the stage: on the stage itself the floor shading covered it)
local front = CreateFrame("Frame", nil, area)
front:SetAllPoints(area)
front:SetFrameLevel(model:GetFrameLevel() + 2)
V.hint = U.font(front, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
V.hint:SetShadowColor(0, 0, 0, 1); V.hint:SetShadowOffset(1, -1)
V.hint:SetText("Drag to turn · Scroll to zoom · Double-click to reset")
V.hint:SetPoint("BOTTOM", area, "BOTTOM", 0, 8)

local function SetRace(raceFile)
    raceFile = GV.races[raceFile or ""] and raceFile or "Orc"
    if bg.race == raceFile then return end
    bg.race = raceFile
    bg.texture:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\dressing-room\\" .. raceFile)
    -- the weather: a second copy of the planner's (PlannerEffects.lua), made with the first race
    if not V.effects and FGT.NewPlannerEffects then
        V.effects = FGT.NewPlannerEffects({ frame = bg, texture = bg.texture, area = area })
    elseif V.effects then
        V.effects.SetRace(raceFile)
    end
end

-- The planner's LayoutPreview at the resting view: the camera, the backdrop's crop (a race with
-- a set place to stand puts the feet on it), the edge shading, the light and the foot shadow.
local function Layout()
    local w, h = area:GetWidth() or 0, area:GetHeight() or 0
    if w <= 0 or h <= 0 then return end
    local aspect = math.max(1, w / h / 0.85)
    local feetMove = 0.157 * (1 / aspect - 1 / 1.93)
    local scale = math.max(w / 318, h / 383)
    local x, y = (w - 318 * scale) / 2, (h - 383 * scale) / 2
    local ground = GV.ground[bg.race]
    if ground then y = math.max(h - 383 * scale, math.min(0, (GV.FEET + feetMove) * h - ground * 383 * scale)) end
    bg.texture:ClearAllPoints()
    bg.texture:SetPoint("TOPLEFT", area, "TOPLEFT", x, -y)
    bg.texture:SetSize(318 * scale, 383 * scale)
    local side, top, floor = GV.side, GV.top, GV.floor
    for i = 1, 2 do
        local t = shades[i]
        t:ClearAllPoints(); t:SetWidth(w * 0.34)
        t:SetPoint(i == 1 and "TOPLEFT" or "TOPRIGHT", area)
        t:SetPoint(i == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT", area)
        U.gradient(t, side, side, i == 1 and 1 or 0, i == 1 and 0 or 1)
    end
    shades[3]:ClearAllPoints(); shades[3]:SetPoint("TOPLEFT", area); shades[3]:SetPoint("TOPRIGHT", area)
    shades[3]:SetHeight(h * 0.28)
    FGT.PopoutUI.vgradient(shades[3], top, top, 0.65, 0)
    local height = math.max(60, math.min(110, h * 0.12))
    for i = 1, 24 do
        local t, p1, p2 = shades[i + 3], (i - 1) / 24, i / 24
        t:ClearAllPoints(); t:SetPoint("TOPLEFT", area, "TOPLEFT", 0, -(h - height + height * p1))
        t:SetPoint("TOPRIGHT", area, "TOPRIGHT", 0, -(h - height + height * p1))
        t:SetHeight(height / 24)
        FGT.PopoutUI.vgradient(t, floor, floor, 0.92 * p1 * p1 * (3 - 2 * p1), 0.92 * p2 * p2 * (3 - 2 * p2))
    end
    V.size = { w = w, h = h, aspect = aspect, feetMove = feetMove }
    local prefs = ForeverGoalTrackerDB and GV.prefs()
    V.lightOn = not prefs or prefs.light ~= false
    V.ApplyZoom(V.zoom or GV.REST_ZOOM)
end

-- The camera at a zoom, as the planner's ApplyZoom: the portrait zoom up to 0.8, then the camera
-- distance (blended across 0.76 to 0.84), with the character moved by right-drag. The foot
-- shadow fades as the feet leave the view; the light grows as the camera closes in.
local MAX_ZOOM = 1
local function Handover(value)
    if value <= 0.76 then return 0 end
    if value >= 0.84 then return 0.04 + (value - 0.84) end
    local u = (value - 0.76) / 0.08
    return 0.08 * (u * u * u - u * u * u * u / 2)
end
function V.ApplyZoom(value)
    V.zoom = value
    local size = V.size
    if not size then return end
    local w, h = size.w, size.h
    local closer = math.max(0, value - GV.REST_ZOOM)
    local feet = math.max(0, 1 - closer * 2.5)
    local rest = GV.shadowFeet[bg.race] or 0.785
    bg.shadow:ClearAllPoints()
    bg.shadow:SetPoint("CENTER", model, "CENTER", 0, -h * (rest + size.feetMove - 0.5))
    bg.shadow:SetSize(math.min(w, h * 0.56), h * 0.105)
    bg.shadow:SetAlpha(0.9 * feet); bg.shadow:SetShown(feet > 0)
    local grow = 1 + closer * 0.6
    bg.light:SetShown(V.lightOn)
    bg.light:ClearAllPoints(); bg.light:SetPoint("CENTER", model, "CENTER", 0, h * 0.06)
    bg.light:SetSize(math.min(w, h * 0.62 * grow), h * 0.85 * grow); bg.light:SetAlpha(0.09)
    local shared = Handover(value)
    if model.SetCamDistanceScale then model:SetCamDistanceScale((1.3 - 2 * shared) * size.aspect) end
    if model.SetPortraitZoom then model:SetPortraitZoom(value - shared) end
    if model.SetPosition then model:SetPosition(0, V.offsetY or 0, V.offsetZ or 0) end
end
area:SetScript("OnSizeChanged", Layout)

-- ------------------------------------------------------------
-- What the character wears: the planner's own rules (GearPlanner.lua VIEW and PaintGear)
-- ------------------------------------------------------------
local function Shown(build, id)
    local item = Cat.Get(build.slots[id])
    return item ~= nil and not GV.NO_MODEL[item.inv]
end
local function Skip(build, who, id)
    local prefs = GV.prefs()
    if id == 1 then return prefs.hideHelm and true or false end
    if id == 15 then return prefs.hideCloak and true or false end
    if (id == 16 or id == 17 or id == 18) and Shown(build, 18) and (Shown(build, 16) or Shown(build, 17)) then
        local choice = prefs.weapons and prefs.weapons[who.class or ""]
        local ranged = choice and choice == "ranged" or (not choice and who.class == "HUNTER")
        return (id == 18) ~= ranged
    end
    return false
end
local function PaintGear()
    local build, who = V.build, V.who
    if not (build and model.TryOn) then return end
    model:Undress()
    for _, id in ipairs(Cat.SLOT_ORDER) do
        local item = Cat.Get(build.slots[id])
        if item and not GV.NO_MODEL[item.inv] and not Skip(build, who, id) then
            FGT.ItemInfo(item.id) -- request uncached item data before trying its appearance
            local hand = id == 16 and "MAINHANDSLOT" or id == 17 and "SECONDARYHANDSLOT" or nil
            local e = build.enchants and Cat.Enchant(build.enchants[id])
            if not pcall(model.TryOn, model, "item:" .. item.id, hand, e and e.effect or nil) then
                pcall(model.TryOn, model, "item:" .. item.id, hand)
            end
        end
    end
    if model.SetSheathed then pcall(model.SetSheathed, model, GV.prefs().sheathed and true or false) end
end
V.PaintGear = PaintGear
model:SetScript("OnModelLoaded", function() PaintGear(); Layout(); model:SetFacing(V.facing or 0) end)

-- Items the client had not loaded arrive later: repaint once for a burst of them.
V:SetScript("OnEvent", function(_, _, itemId, ok)
    if ok == false or not V.build or V.pending then return end
    for _, id in pairs(V.build.slots) do
        if id == itemId then
            V.pending = true
            C_Timer.After(0.1, function() V.pending = nil; if V:IsShown() then PaintGear() end end)
            return
        end
    end
end)
V:SetScript("OnShow", function() V:RegisterEvent("GET_ITEM_INFO_RECEIVED") end)
V:SetScript("OnHide", function()
    V:UnregisterEvent("GET_ITEM_INFO_RECEIVED"); model:SetScript("OnUpdate", nil); V.camera:SetScript("OnUpdate", nil)
end)

-- Left-drag turns the character, right-drag moves it, the wheel zooms (gliding, as in the
-- planner), and a double-click puts the camera back.
local camera = CreateFrame("Frame", nil, V)
V.camera = camera
local target = { zoom = GV.REST_ZOOM, y = 0, z = 0 }
V.target = target
function camera.Glide(_, dt)
    local k = 1 - math.exp(-math.min(dt, 0.1) * 12)
    local zoom = V.zoom + (target.zoom - V.zoom) * k
    V.offsetY = V.offsetY + (target.y - V.offsetY) * k
    V.offsetZ = V.offsetZ + (target.z - V.offsetZ) * k
    if math.abs(target.zoom - zoom) < 0.0005 and math.abs(target.y - V.offsetY) < 0.0005
        and math.abs(target.z - V.offsetZ) < 0.0005 then
        V.offsetY, V.offsetZ = target.y, target.z
        V.ApplyZoom(target.zoom)
        camera:SetScript("OnUpdate", nil)
    else
        V.ApplyZoom(zoom)
    end
end
local function GlideTo(zoom, y, z)
    target.zoom, target.y, target.z = zoom, y or target.y, z or target.z
    if FGT.Setting and FGT.Setting("celebrations") == "off" then
        camera:SetScript("OnUpdate", nil); V.offsetY, V.offsetZ = target.y, target.z; V.ApplyZoom(target.zoom); return
    end
    camera:SetScript("OnUpdate", camera.Glide)
end
function V.ResetCamera(glide)
    camera:SetScript("OnUpdate", nil)
    if glide then GlideTo(GV.REST_ZOOM, 0, 0); return end
    target.zoom, target.y, target.z = GV.REST_ZOOM, 0, 0
    V.offsetY, V.offsetZ = 0, 0
    V.ApplyZoom(GV.REST_ZOOM)
end
V.offsetY, V.offsetZ = 0, 0
model:EnableMouseWheel(true)
model:SetScript("OnMouseWheel", function(_, delta)
    GlideTo(math.max(0, math.min(MAX_ZOOM, target.zoom + delta * 0.1)))
end)
model:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then
        -- (a model has no OnDoubleClick, only buttons do: two presses within 0.3 s count as one)
        local now = GetTime()
        if V.lastPress and now - V.lastPress < 0.3 then
            V.lastPress = nil; V.ResetCamera(true); return
        end
        V.lastPress = now
        local last = GetCursorPosition()
        model:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then model:SetScript("OnUpdate", nil); return end
            local x = GetCursorPosition()
            V.facing = (V.facing or 0) + (x - last) * 0.01; last = x
            model:SetFacing(V.facing)
        end)
    elseif button == "RightButton" then
        camera:SetScript("OnUpdate", nil)
        local lastX, lastY = GetCursorPosition()
        model:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("RightButton") then model:SetScript("OnUpdate", nil); return end
            local x, y = GetCursorPosition()
            local k = 1.6 / (math.max(1, area:GetHeight()) * model:GetEffectiveScale()) * (1 - (V.zoom or 0) * 0.6)
            V.offsetY = math.max(-1.5, math.min(1.5, V.offsetY + (x - lastX) * k))
            V.offsetZ = math.max(-1.5, math.min(1.5, V.offsetZ + (y - lastY) * k))
            target.y, target.z = V.offsetY, V.offsetZ
            lastX, lastY = x, y
            V.ApplyZoom(V.zoom)
        end)
    end
end)
model:SetScript("OnMouseUp", function() model:SetScript("OnUpdate", nil) end)

-- Opens the window on a Gear Planner goal's set. False when the set can't be found.
function FGT.ShowViewSet(goal)
    local build, who = GV.SetFor(goal)
    if not build then return false end
    V.build, V.who, V.facing = build, who, 0
    V.title:SetText(build.name or goal.name or "Gear set")
    local race = who.me and UnitRace and UnitRace("player")
        or (who.race == "Scourge" and "Undead") or (who.race and who.race:gsub("(%l)(%u)", "%1 %2"))
    local class = who.class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[who.class]
    V.sub:SetText((who.name or "") .. ((race or class) and (" · " .. (race and (race .. " ") or "") .. (class or "")) or ""))
    SetRace(who.race)
    V:Show(); V:Raise()
    model:SetUnit("player")
    -- another character: their race where the game allows it (SetCustomRace: 0 male, 1 female)
    if not who.me and model.SetCustomRace and GV.RACE_IDS[who.race or ""] then
        pcall(model.SetCustomRace, model, GV.RACE_IDS[who.race], who.sex == 3 and 1 or 0)
    end
    model:SetFacing(0)
    V.ResetCamera()
    Layout(); PaintGear()
    if V.effects then V.effects.Refresh() end
    return true
end
