local ADDON, FGT = ...
-- The goal's banner turns into a map (Karl's idea, 2026-10-15; a test for now).
-- When a goal's next step sends you to a person, the map pin button beside the note icon
-- fades the banner art out and a crop of the game's own map for that zone in, with the
-- parts of the zone this character has discovered drawn over the plain map and a gold pin
-- on the person that pings softly. The pin sits in the art's upper right, the fades on the
-- left and at the bottom match the art's (the same light mask), and the clouds stay as they
-- are. The tiles come from the game (C_Map and C_MapExplorationInfo), so nothing of
-- Blizzard's ships with the addon. /goals map does the same from chat (see HandleMapCommand).
local B = FGT.goalBanner
if not B or not B.panel or not B.art then return end
local panel = B.panel
local C = FGT.MaterialsUI and FGT.MaterialsUI.colors or {}
local TAG = "|cffffd75eForever Goal Tracker:|r "
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

local M = {
    mix = 0, target = 0, -- 0 = the art, 1 = the map
    zoomIn = 0,          -- how far in from the widest the map can be (0.5 = 50% in); /goals map zoom N
    peak = 0.40,         -- how strong the map is at its brightest, like the art's 0.18
    dotU = 0.75, dotV = 0.25, -- where the pin sits in the art, from its top left
    FADE_IN = 2.4, FADE_OUT = 1.8, -- seconds
    PERIOD = 3.6,        -- seconds per ping
    t = 0,
    tiles = {},          -- the plain map (below the art's sublevel)
    over = {},           -- the discovered parts, drawn over it
    used = 0, usedOver = 0,
}
FGT.Maplet = M

local function Clamp01(x) return math.max(0, math.min(1, x)) end
local function Smooth(x) x = Clamp01(x); return x * x * (3 - 2 * x) end

-- ------------------------------------------------------------
-- Which NPC, and the game's map for it
-- ------------------------------------------------------------
local function Layers(mapID)
    if not (C_Map and C_Map.GetMapArtLayers and C_Map.GetMapArtLayerTextures) then
        return nil, "this client has no map tile API"
    end
    local ok, layers = pcall(C_Map.GetMapArtLayers, mapID)
    local info = ok and layers and layers[1]
    if not info or not info.layerWidth or not info.tileWidth then return nil, "no map art for map " .. tostring(mapID) end
    local ok2, tex = pcall(C_Map.GetMapArtLayerTextures, mapID, 1)
    if not ok2 or type(tex) ~= "table" or #tex == 0 then return nil, "no map tiles for map " .. tostring(mapID) end
    return info, tex
end

-- The parts of the zone this character has discovered: each is a picture split in 256 pixel
-- tiles, placed by its offset in the map's own pixels (as the game's world map does).
local function Explored(mapID)
    local list = {}
    if not (C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures) then return list end
    local ok, found = pcall(C_MapExplorationInfo.GetExploredMapTextures, mapID)
    if not ok or type(found) ~= "table" then return list end
    for _, e in ipairs(found) do
        if e.fileDataIDs and not e.isShownByMouseOver and e.textureWidth and e.textureWidth > 0
            and e.textureHeight and e.textureHeight > 0 then
            list[#list + 1] = e
        end
    end
    return list
end

-- the first NPC the step names that has a spot on a map
local function NpcInText(text)
    if not (text and FGT.LinkNpcs) then return nil end
    local linked = FGT.LinkNpcs(text)
    for id in linked:gmatch("Hfgtnpc:(%d+)") do
        local n = FGT.NpcById(tonumber(id))
        if n and n.map and n.x and n.y then return n end
    end
end

local function NextStepNpc(goal)
    if not (goal and FGT.NextStep) then return nil end
    local ok, n = pcall(function() return NpcInText(FGT.NextStep(goal)) end)
    return ok and n or nil
end

local function FindNpc(query)
    FGT.NpcById(0) -- (builds the index, which applies Forever's own spots)
    local id = tonumber(query)
    if id then
        local n = FGT.NpcById(id)
        if n and n.map then return n end
        return nil
    end
    query = query:lower()
    for _, entry in ipairs(FGT.NPCS or {}) do
        local n = FGT.NpcById(entry.id)
        if n and n.map and n.x then
            if n.name:lower():find(query, 1, true) then return n end
            for _, a in ipairs(n.alias or {}) do
                if a:lower():find(query, 1, true) then return n end
            end
        end
    end
end

-- ------------------------------------------------------------
-- The map: tiles cropped to the art's rectangle, the pin on the NPC
-- ------------------------------------------------------------
-- the same fades as the art: its left edge, a darker top and the faded bottom
M.mask = panel.CreateMaskTexture and panel:CreateMaskTexture()
if M.mask then
    M.mask:SetTexture(MEDIA .. "light-mask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
end

-- BACKGROUND sublevels on the goal panel: the plain map is -4, under the art (-3), and the
-- discovered parts -3, over it. (The clouds, -2, and the shading stay above both.)
local function Tile(pool, i, level)
    local t = pool[i]
    if t then return t end
    t = panel:CreateTexture(nil, "BACKGROUND", nil, level)
    t:SetDesaturated(true)
    t:SetVertexColor(0.92, 0.86, 0.72) -- a warm grey, like the parchment tones of the art
    if M.mask then t:AddMaskTexture(M.mask) end
    t:Hide()
    pool[i] = t
    return t
end

function M:HideTiles()
    for _, t in ipairs(self.tiles) do t:Hide() end
    for _, t in ipairs(self.over) do t:Hide() end
end

function M:TileAlpha()
    return self.peak * Smooth(self.mix)
end

-- Lays the tiles for the art's current size; called again when the window resizes.
function M:Layout()
    local n, info, ids = self.npc, self.info, self.ids
    local aw, ah = B.art:GetWidth(), B.shownArtHeight
    if not (n and info and ids and ah and aw > 20 and ah > 20) then self:HideTiles(); return end
    local tw, th = info.tileWidth, info.tileHeight or info.tileWidth
    local lw, lh = info.layerWidth, info.layerHeight
    local cols = math.ceil(lw / tw)
    -- The pin always sits in the art's upper right (dotU, dotV), and the zoom follows from that: the
    -- most zoomed out the map can be is with its own bottom edge on the art's bottom edge (so a map
    -- never ends above the bottom), which is a different zoom for every map. Zooming in from there
    -- (zoomIn, 0 = none) keeps the pin where it is. The crop is held inside the map's other edges.
    local px, py = n.x / 100 * lw, n.y / 100 * lh
    local winH = math.min(lh, (lh - py) / (1 - self.dotV))
    winH = math.max(winH / (1 + self.zoomIn), lh * 0.10)
    local winW = winH * aw / ah
    if winW > lw then winW = lw; winH = winW * ah / aw end
    local scale = aw / winW          -- screen units per map pixel
    local left = math.max(0, math.min(lw - winW, px - winW * self.dotU))
    local top = math.max(0, math.min(lh - winH, py - winH * self.dotV))
    self.pinX, self.pinY = (px - left) * scale, (py - top) * scale
    if self.mask then
        self.mask:ClearAllPoints()
        self.mask:SetPoint("TOPLEFT", B.art, "TOPLEFT", 0, 0)
        self.mask:SetSize(aw, ah)
    end
    local alpha = self:TileAlpha()
    -- puts one picture's piece [x0,x1] by [y0,y1] (map pixels, the file covering fileW by fileH of
    -- them from x0, y0) on the art, cropped to the visible part; false when none of it shows
    local function Place(t, id, x0, x1, y0, y1, fileW, fileH)
        local ix0, ix1 = math.max(x0, left), math.min(x1, left + winW)
        local iy0, iy1 = math.max(y0, top), math.min(y1, top + winH)
        if not id or ix1 <= ix0 or iy1 <= iy0 then return false end
        t:SetTexture(id)
        t:SetTexCoord((ix0 - x0) / fileW, (ix1 - x0) / fileW, (iy0 - y0) / fileH, (iy1 - y0) / fileH)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", B.art, "TOPLEFT", (ix0 - left) * scale, -(iy0 - top) * scale)
        t:SetSize((ix1 - ix0) * scale, (iy1 - iy0) * scale)
        t:SetAlpha(alpha)
        t:Show()
        return true
    end

    local used = 0
    local rows = math.ceil(lh / th)
    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            local t = Tile(self.tiles, used + 1, -4)
            if Place(t, ids[r * cols + c + 1], c * tw, math.min((c + 1) * tw, lw), r * th, math.min((r + 1) * th, lh), tw, th) then
                used = used + 1
            end
        end
    end
    for i = used + 1, #self.tiles do self.tiles[i]:Hide() end
    self.used = used

    -- the discovered parts, in the game's own way: 256 pixel cells, the last of a row or column
    -- cut to what is left and read from a file of the next power of two
    local usedOver = 0
    local function FilePixels(size)
        local px = size % 256
        if px == 0 then return 256, 256 end
        local file = 16
        while file < px do file = file * 2 end
        return px, file
    end
    for _, e in ipairs(self.explored or {}) do
        local numCols, numRows = math.ceil(e.textureWidth / 256), math.ceil(e.textureHeight / 256)
        for j = 0, numRows - 1 do
            local ph, fh
            if j < numRows - 1 then ph, fh = 256, 256 else ph, fh = FilePixels(e.textureHeight) end
            for k = 0, numCols - 1 do
                local pw, fw
                if k < numCols - 1 then pw, fw = 256, 256 else pw, fw = FilePixels(e.textureWidth) end
                local x0, y0 = e.offsetX + k * 256, e.offsetY + j * 256
                local id = e.fileDataIDs[j * numCols + k + 1]
                -- (skipped without making a texture when it's off the visible crop)
                if id and x0 + pw > left and x0 < left + winW and y0 + ph > top and y0 < top + winH then
                    local t = Tile(self.over, usedOver + 1, -3)
                    if Place(t, id, x0, x0 + pw, y0, y0 + ph, fw, fh) then usedOver = usedOver + 1 end
                end
            end
        end
    end
    for i = usedOver + 1, #self.over do self.over[i]:Hide() end
    self.usedOver = usedOver

    self.dot:ClearAllPoints()
    self.dot:SetPoint("CENTER", B.art, "TOPLEFT", self.pinX, -self.pinY)
    if self.PlaceSlider then self:PlaceSlider() end
end

-- the pin: a gold dot over everything on the page's top right, a ring that pings out of it
local dot = CreateFrame("Frame", nil, panel)
M.dot = dot
dot:SetSize(26, 26)
dot:SetFrameLevel((FGT.detailViewport and FGT.detailViewport.scroll and FGT.detailViewport.scroll:GetFrameLevel() or panel:GetFrameLevel()) + 6)
dot:EnableMouse(true)
dot:Hide()
dot.ring = dot:CreateTexture(nil, "ARTWORK")
dot.ring:SetTexture(MEDIA .. "ring")
dot.ring:SetBlendMode("ADD")
dot.ring:SetPoint("CENTER")
dot.glow = dot:CreateTexture(nil, "ARTWORK")
dot.glow:SetTexture(MEDIA .. "glow")
dot.glow:SetBlendMode("ADD")
dot.glow:SetPoint("CENTER")
dot.glow:SetSize(46, 46)
dot.tex = dot:CreateTexture(nil, "OVERLAY")
dot.tex:SetTexture(MEDIA .. "dot")
dot.tex:SetPoint("CENTER")
dot.tex:SetSize(20, 20)
local GOLD = C.GOLD2 or { 1, 0.82, 0.3 }
dot.tex:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
dot.glow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
dot.ring:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])

dot:SetScript("OnEnter", function(self)
    local n = M.npc
    if not n then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(n.name, 0.37, 0.83, 0.74)
    if n.tag then GameTooltip:AddLine("<" .. n.tag .. ">", 0.7, 0.66, 0.58) end
    GameTooltip:AddLine((n.zone or "?") .. "  " .. string.format("%.1f, %.1f", n.x, n.y), 1, 0.9, 0.55)
    if n.where then GameTooltip:AddLine(n.where, 0.7, 0.66, 0.58, true) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(FGT.UseTomTom and FGT.UseTomTom() and "Click: TomTom waypoint" or "Click: show on the map",
        1, 0.82, 0.3)
    GameTooltip:AddLine("Right-click: map and Wowhead", 1, 0.82, 0.3)
    GameTooltip:Show()
end)
dot:SetScript("OnLeave", function() GameTooltip:Hide() end)
dot:SetScript("OnMouseUp", function(_, button)
    local n = M.npc
    if not n then return end
    if button == "RightButton" then
        FGT.OpenWowheadCard("npc", n.id, n.name, nil, n)
    else
        FGT.ShowNpcOnMap(n.id)
    end
end)

-- the ping: a ring grows out of the dot and fades, then a pause
function M:Ping(dt)
    local appear = Smooth((Smooth(self.mix) - 0.8) / 0.2) -- the pin comes after the map is mostly in
    dot:SetAlpha(appear)
    dot:SetShown(appear > 0)
    if appear <= 0 then return end
    local effects = FGT.EffectsLevel and FGT.EffectsLevel() or "full"
    if effects == "off" then dot.ring:Hide(); return end
    self.t = self.t + dt
    local p = (self.t % self.PERIOD) / self.PERIOD
    local q = p / 0.7
    -- the glow behind the dot breathes a little with it
    dot.glow:SetAlpha(0.35 + 0.15 * math.sin(self.t * 2 * math.pi / self.PERIOD))
    if q >= 1 then dot.ring:Hide(); return end
    local ease = 1 - (1 - q) * (1 - q)
    local size = 14 + 60 * ease
    dot.ring:SetSize(size, size)
    dot.ring:SetAlpha(0.5 * (1 - q) * (1 - q))
    dot.ring:Show()
end

-- ------------------------------------------------------------
-- The map pin button, left of the note icon at the page's top right
-- ------------------------------------------------------------
local btn = CreateFrame("Button", nil, FGT.detailBody or panel)
M.button = btn
btn:SetSize(22, 22)
btn:SetPoint("TOPRIGHT", FGT.detailBody or panel, "TOPRIGHT", -20 - 26 * 2, -22)
FGT.IconButton(btn, "map-location", 16)
-- the icons are painted gold: greyed and tinted to silver here
local SILVER = { 0.86, 0.88, 0.92 }
local function Silver()
    for _, t in ipairs({ btn.icon, btn.glow }) do
        t:SetDesaturated(true)
        t:SetVertexColor(SILVER[1], SILVER[2], SILVER[3])
    end
end
Silver()
btn:Hide()

-- It fades in when a step first has a place to go, and out when it goes (no halo or ping).
local FADE_BTN = 1.2
function btn:StopAttention() end -- (kept: the handlers below call it)

btn:SetScript("OnUpdate", function(self, dt)
    if self.fadeT then
        self.fadeT = self.fadeT + dt
        local p = Smooth(self.fadeT / FADE_BTN)
        self:SetAlpha((self.fadeFrom or 0) + (1 - (self.fadeFrom or 0)) * p)
        if p >= 1 then self.fadeT = nil end
    end
    if self.fadeOutT then
        self.fadeOutT = self.fadeOutT + dt
        local p = Smooth(self.fadeOutT / 0.45)
        self:SetAlpha(self.fadeOutFrom * (1 - p))
        if p >= 1 then self.fadeOutT = nil; self:Hide() end
    end
end)

btn:SetScript("OnEnter", function(self)
    self:StopAttention()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    local n = M.npc or M.available
    if M.target == 1 then
        GameTooltip:AddLine("Back to the goal art", 1, 0.93, 0.62)
    else
        GameTooltip:AddLine("Show the next step on the map", 1, 0.93, 0.62)
    end
    if n then
        GameTooltip:AddLine(n.name .. ", " .. (n.zone or "?"), 0.7, 0.66, 0.58)
    end
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
btn:SetScript("OnClick", function(self)
    self:StopAttention()
    GameTooltip:Hide()
    if M.target == 1 then M:Hide() elseif M.available then M:Show(M.available, true) end
end)

-- Core's layout puts the page's icons in a row from the right (edit, reset, note); the map pin
-- takes the next place along. `taken` is how many places are used.
function FGT.PlaceMapButton(taken)
    btn:ClearAllPoints()
    btn:SetPoint("TOPRIGHT", FGT.detailBody or panel, "TOPRIGHT", -20 - 26 * taken, -22)
end

function M:SyncButton()
    -- while the map is on, the pin is slashed: it turns the location off and brings the art back
    local icon = FGT.Icon(self.target == 1 and "map-location-off" or "map-location")
    if btn.shownIcon ~= icon then
        btn.icon:SetTexture(icon)
        btn.glow:SetTexture(icon)
        btn.shownIcon = icon
        Silver()
    end
    btn:RefreshIcon()
    local want = self.target == 1 or self.available ~= nil
    local still = (FGT.Setting("celebrations") or "full") == "off"
    if want and (not btn:IsShown() or btn.fadeOutT) then
        -- it fades in rather than appearing (and does not, with Celebrations off); from where it
        -- was, if it was on its way out
        btn.fadeFrom = btn.fadeOutT and btn:GetAlpha() or 0
        btn.fadeOutT = nil
        if still then
            btn:SetAlpha(1)
        else
            btn:SetAlpha(btn.fadeFrom)
            btn.fadeT = 0
        end
        btn:Show()
    elseif not want and btn:IsShown() and not btn.fadeOutT then
        btn:StopAttention()
        btn.fadeT = nil
        if still then
            btn:Hide()
        else
            btn.fadeOutFrom, btn.fadeOutT = btn:GetAlpha(), 0
        end
    end
end

-- ------------------------------------------------------------
-- Zoom: the mouse wheel over the top of the page, or a quiet slider by the right edge. Zooming in
-- is measured from the widest view (0), always around the pin; right-click the slider to reset.
-- ------------------------------------------------------------
local ZMAX = 4 -- 400% in
local slider = CreateFrame("Frame", nil, panel)
M.slider = slider
slider:SetSize(16, 96)
slider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -16) -- the top right corner, right of the refresh icon
slider:SetFrameLevel(dot:GetFrameLevel())
slider:EnableMouse(true)
slider:EnableMouseWheel(true)
slider:SetAlpha(0)
slider:Hide()
slider.track = slider:CreateTexture(nil, "ARTWORK")
slider.track:SetTexture("Interface\\Buttons\\WHITE8X8")
slider.track:SetWidth(2)
slider.track:SetPoint("TOP", slider, "TOP", 0, 0)
slider.track:SetPoint("BOTTOM", slider, "BOTTOM", 0, 0)
slider.track:SetVertexColor(0.62, 0.62, 0.60, 0.40) -- grey
slider.thumb = slider:CreateTexture(nil, "OVERLAY")
slider.thumb:SetTexture(MEDIA .. "dot")
slider.thumb:SetSize(11, 11)
slider.thumb:SetVertexColor(0.62, 0.80, 0.98) -- a soft blue, so it never competes with the gold pin

-- its top is level with the top of the page's icons (the map button's icon is 3 down in its box)
function M:PlaceSlider()
    local top, panelTop = btn:GetTop(), panel:GetTop()
    local y = (top and panelTop) and (top - panelTop - 3) or -22
    slider:ClearAllPoints()
    slider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, y)
end

function M:SyncSlider()
    local t = math.log(1 + self.zoomIn) / math.log(1 + ZMAX)
    slider.thumb:ClearAllPoints()
    slider.thumb:SetPoint("CENTER", slider, "BOTTOM", 0, 6 + t * (slider:GetHeight() - 12))
end

-- sets the zoom (a share, 0 = widest); smoothly unless `instant`
function M:SetZoom(z, instant)
    z = math.max(0, math.min(ZMAX, z))
    self.zoomTarget = z
    if instant then
        self.zoomIn = z
        self:Layout()
        self:SyncSlider()
    end
end

function M:WheelStep(delta)
    local z = (1 + (self.zoomTarget or self.zoomIn)) * (1.2 ^ delta) - 1
    if math.abs(z) < 0.01 then z = 0 end
    self:SetZoom(z)
end

local function SliderDrag(self)
    local _, cy = GetCursorPosition()
    cy = cy / self:GetEffectiveScale()
    local t = Clamp01((cy - self:GetBottom() - 6) / (self:GetHeight() - 12))
    M:SetZoom(math.exp(t * math.log(1 + ZMAX)) - 1, true)
end
local function SliderPaint()
    slider:SetAlpha(Smooth(M.mix) * (slider.hover and 1 or 0.55))
end
slider:SetScript("OnEnter", function(self)
    self.hover = true
    SliderPaint()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Zoom", 1, 0.93, 0.62)
    GameTooltip:AddLine(string.format("%d%% in. Drag, or scroll over the top of the page.", math.floor(M.zoomIn * 100 + 0.5)), 0.7, 0.66, 0.58, true)
    GameTooltip:AddLine("Right-click: reset", 0.7, 0.66, 0.58)
    GameTooltip:Show()
end)
slider:SetScript("OnLeave", function(self)
    self.hover = false
    SliderPaint()
    GameTooltip:Hide()
end)
slider:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then M:SetZoom(0); return end
    self:SetScript("OnUpdate", SliderDrag)
    SliderDrag(self)
end)
slider:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
slider:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
slider:SetScript("OnMouseWheel", function(_, delta) M:WheelStep(delta) end)

-- The page's own wheel handler scrolls the page. While the map is on, the wheel over the top of the page
-- (above the "Step by step" row) zooms instead; over the steps it still scrolls them.
do
    local outer = FGT.detailViewport and FGT.detailViewport.scroll
    local original = outer and outer:GetScript("OnMouseWheel")
    if outer then
        outer:SetScript("OnMouseWheel", function(self, delta, ...)
            if M.target == 1 and M.mix > 0.5 and FGT.stepsRow then
                local top = FGT.stepsRow:GetTop()
                local _, cy = GetCursorPosition()
                if top and cy / FGT.stepsRow:GetEffectiveScale() > top then
                    M:WheelStep(delta)
                    return
                end
            end
            if original then original(self, delta, ...) end
        end)
    end
end

-- ------------------------------------------------------------
-- The crossfade
-- ------------------------------------------------------------
function M:Apply()
    local e = Smooth(self.mix)
    B.mapMix = e
    B:SetImageFade(B.imageFade or 1) -- redraws the art and its lights at their share
    local a = self:TileAlpha()
    for i = 1, self.used do self.tiles[i]:SetAlpha(a) end
    for i = 1, self.usedOver do self.over[i]:SetAlpha(a) end
    slider:SetShown(e > 0)
    self:PlaceSlider()
    SliderPaint()
end

local driver = CreateFrame("Frame", nil, panel)
M.driver = driver
driver:Hide()
driver:SetScript("OnUpdate", function(f, dt)
    -- a different goal opened: back to its art at once
    if M.goalId and B.goal and B.goal.id ~= M.goalId and M.target == 1 then
        M.target, M.fast = 0, true -- the map fades out quickly while the new goal's art fades in
        M:SyncButton()
    end
    if M.mix ~= M.target then
        if (FGT.Setting("celebrations") or "full") == "off" then
            M.mix = M.target
        elseif M.target > M.mix then
            M.mix = math.min(M.target, M.mix + dt / M.FADE_IN)
        else
            M.mix = math.max(M.target, M.mix - dt / (M.fast and 0.45 or M.FADE_OUT))
        end
        M:Apply()
    end
    if M.zoomTarget and M.zoomIn ~= M.zoomTarget then
        -- eases toward where the wheel or slider asked
        local d = M.zoomTarget - M.zoomIn
        M.zoomIn = math.abs(d) < 0.002 and M.zoomTarget or M.zoomIn + d * math.min(1, dt * 9)
        M:Layout()
        M:SyncSlider()
    end
    M:Ping(dt)
    if M.mix == 0 and M.target == 0 then M:Release() end
end)

function M:Release()
    self.npc, self.info, self.ids, self.explored, self.goalId = nil, nil, nil, nil, nil
    self.manual, self.fast = false, false
    self.used, self.usedOver = 0, 0
    self:HideTiles()
    dot:Hide()
    slider:Hide()
    self.zoomIn, self.zoomTarget = 0, 0
    driver:Hide()
    self:SyncButton()
end

function M:Reset()
    self.mix, self.target = 0, 0
    B.mapMix = 0
    B:SetImageFade(B.imageFade or 1)
    self:Release()
end

-- loads a map for the NPC; false (and a line in chat) when the client can't give it
function M:Load(n)
    local info, ids = Layers(n.map)
    if not info then
        print(TAG .. "Can't draw the map for " .. n.name .. ": " .. tostring(ids) .. ".")
        return false
    end
    self.npc, self.info, self.ids, self.explored = n, info, ids, Explored(n.map)
    return true
end

function M:Show(n, quiet, manual)
    if not (B:IsShown() and B.shownArtHeight and B.art:GetWidth() > 20) then
        print(TAG .. "Open a goal with banner artwork first.")
        return false
    end
    if not self:Load(n) then return false end
    self.goalId = B.goal and B.goal.id
    self.target = 1
    self.fast = false
    self.manual = manual and true or false -- picked by name or from a step: the next step doesn't move it
    self:Layout()
    driver:Show()
    self:SyncButton()
    if not quiet then
        print(string.format("%s%s, %s %.1f, %.1f (map %d, %dx%d, %d tiles, %d drawn, %d discovered areas, %d drawn).", TAG,
            n.name, n.zone or "?", n.x, n.y, n.map, self.info.layerWidth, self.info.layerHeight, #self.ids,
            self.used, #self.explored, self.usedOver))
    end
    return true
end

function M:Hide()
    if self.target == 0 then return end
    self.target = 0
    self.fast = false
    self.manual = false
    driver:Show()
    self:SyncButton()
end

-- the banner's own layout calls keep the tiles in step with the art
local fit = B.Fit
function B:Fit()
    fit(self)
    if M.npc then M:Layout() end
end
B:HookScript("OnHide", function() if M.mix > 0 or M.target > 0 then M:Reset() end end)

-- Twice a second, while the goal page is up: does the next step send you to someone? The button
-- shows only then (or while the map is on). When a step is ticked and the next person is somewhere
-- else, the map moves to them; when no one is left, it fades back to the art.
local watch = CreateFrame("Frame", nil, panel)
watch.t = 0
watch:SetScript("OnUpdate", function(f, dt)
    f.t = f.t + dt
    if f.t < 0.5 then return end
    f.t = 0
    local n = B:IsShown() and B.goal and NextStepNpc(B.goal) or nil
    M.available = n
    if M.target == 1 and not M.manual then
        if not n then
            M:Hide()
        elseif n ~= M.npc and M:Load(n) then
            M:Layout()
        end
    end
    M:SyncButton()
end)

-- ------------------------------------------------------------
-- /goals map ...
-- ------------------------------------------------------------
function FGT.HandleMapCommand(msg)
    local cmd = strtrim(msg or ""):lower()
    local rest = cmd == "map" and "" or cmd:match("^map%s+(.*)$")
    if not rest then return false end
    local percent = tonumber(rest:match("^zoom%s+(%d+)$") or "")
    if percent then
        M:SetZoom(percent / 100, true)
        print(TAG .. "map zoomed in " .. math.floor(M.zoomIn * 100 + 0.5) .. "% from its widest (the map's bottom on the art's bottom).")
        return true
    end
    percent = tonumber(rest:match("^alpha%s+(%d+)$") or "")
    if percent then
        M.peak = Clamp01(percent / 100)
        M:Apply()
        print(TAG .. "map strength: " .. math.floor(M.peak * 100 + 0.5) .. "%.")
        return true
    end
    local u, v = rest:match("^dot%s+(%d+)%s+(%d+)$")
    if u then
        M.dotU, M.dotV = Clamp01(tonumber(u) / 100), Clamp01(tonumber(v) / 100)
        M:Layout()
        print(TAG .. "pin at " .. u .. "% across, " .. v .. "% down.")
        return true
    end
    if rest == "debug" then
        local aw, ah = B.art:GetWidth(), B.shownArtHeight or 0
        print(string.format("%smix %.2f target %d, zoom in %.0f%%, tiles %d + %d, art %.0fx%.0f, mapMix %.2f, tile alpha %.2f, pin %s",
            TAG, M.mix, M.target, M.zoomIn * 100, M.used, M.usedOver, aw, ah,
            B.mapMix or 0, M:TileAlpha(), M.dot:IsShown() and "shown" or "hidden"))
        return true
    end
    if rest == "off" then M:Hide(); return true end
    if rest == "" then
        if M.target == 1 then M:Hide(); return true end
        local n = NextStepNpc(B.goal)
        if n then
            M:Show(n, false, true)
        else
            print(TAG .. "This goal's next step doesn't name anyone with a map spot. Try /goals map vartrus (a name or an NPC id), "
                .. "or /goals map off.")
        end
        return true
    end
    local n = FindNpc(rest)
    if not n then
        print(TAG .. "No NPC with a map spot matches '" .. rest .. "'.")
        return true
    end
    M:Show(n, false, true)
    return true
end

-- ------------------------------------------------------------
-- "Show on map" after a step that names someone with a map spot: a link in the step text that does
-- what the pin button does, for that person (Core.lua draws the step text; this adds the tail).
-- ------------------------------------------------------------
local LINK_HEX = "c9b37a"

local function NpcInLinkedText(text)
    for id in text:gmatch("Hfgtnpc:(%d+)") do
        local n = FGT.NpcById(tonumber(id))
        if n and n.map and n.x and n.y then return n end
    end
end

function FGT.MapLinkText(text, done, skip)
    if done or skip or type(text) ~= "string" or not C_Map then return text end
    local n = NpcInLinkedText(text)
    if not n then return text end
    -- the icon is set like the quest "!" (15 px, 3 down) and touches its text, one space after the step
    return text .. " |cff" .. LINK_HEX .. "|Hfgtmap:" .. n.id .. "|h|T" .. FGT.Icon("map-location")
        .. ":15:15:0:-3|tShow on map|h|r"
end

function FGT.ShowMapLinkTip(owner, id)
    local n = FGT.NpcById(id)
    if not n then return end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
    GameTooltip:AddLine("Show on the map", 1, 0.93, 0.62) -- (only the pin button at the top turns the map off)
    GameTooltip:AddLine(n.name .. ", " .. (n.zone or "?"), 0.7, 0.66, 0.58)
    GameTooltip:Show()
end

function FGT.MapLinkClick(id)
    local n = FGT.NpcById(id)
    if not n then return end
    if M.target == 1 and M.npc == n then
        return -- already showing: only the pin button at the top turns the map off
    elseif B:IsShown() and B.shownArtHeight then
        M:Show(n, true, true)
    else
        FGT.ShowNpcOnMap(id) -- no banner to draw on (the pop-out alone): the game's own map
    end
end
