local ADDON, FGT = ...
local U = FGT.MaterialsUI

-- Floating dust over the goal page, the same art, speed and strength as the
-- Forever talent window (Blizzard_ClassTalentsFrame.xml, Camelot): two
-- additive layers of "talents-animations-particles" drifting sideways while
-- they slowly turn, each fading in over 5 s, holding, fading out over 5 s.
-- Built on the game's own animation groups, so it costs almost nothing.
-- Classic Era doesn't have that art, so it gets look-alikes of our own,
-- drawn by tools/ambience.py to the sizes, counts and brightness measured
-- from Blizzard's sheets (Karl, 2026-10-14: 95% as close as Forever's).
-- Forever keeps Blizzard's.
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local ATLAS = "talents-animations-particles"
local function AtlasInfo(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end
-- Our stand-in for an atlas's description: the file, the size shown and the whole texture.
local function OwnArt(file, width, height)
    return { file = MEDIA .. file, width = width, height = height,
             leftTexCoord = 0, rightTexCoord = 1, topTexCoord = 0, bottomTexCoord = 1 }
end
local info = AtlasInfo(ATLAS)
local own = not info -- (our own textures, shown at the atlas's size)
if own then info = OwnArt("ambience-leaves.blp", 1308, 774) end
-- An atlas by name on Forever, or our file on Classic Era.
local function Art(t, atlas, art)
    if own then t:SetTexture(art.file); t:SetTexCoord(0, 1, 0, 1)
    else t:SetAtlas(atlas) end
end

local A = { own = own } -- own: our Classic Era look-alikes, not Blizzard's atlas
FGT.ambience = A

-- The dust and clouds are textures on the goal panel itself, on its BACKGROUND layer
-- below the banner's dark gradients (left, top and bottom shading) and the panel's inner
-- shadows, so those darken the leaves exactly as they darken the banner's lights
-- (Karl, 2026-10-13). A child frame would draw above all of the panel's own layers.
-- `fx` is only the rectangle just inside the panel's etched edge that they are placed
-- in and masked to (the mask below clips them: a region is not clipped by a frame).
local fx = CreateFrame("Frame", nil, U.detail)
A.frame = fx
fx:SetPoint("TOPLEFT", U.detail, "TOPLEFT", 4, -4)
fx:SetPoint("BOTTOMRIGHT", U.detail, "BOTTOMRIGHT", -4, 4)
-- One level above the goal panel itself (so above its banner image, which
-- the panel draws), and the goal page's scrolling body above that (so the
-- title, steps and text stay on top of the dust).
fx:SetFrameLevel(U.detail:GetFrameLevel() + 1)
-- (the goal page's scrolling body stays above the panel's own layers, so text stays on top)
local body = FGT.detailViewport and FGT.detailViewport.scroll
if body and body:GetFrameLevel() <= fx:GetFrameLevel() then body:SetFrameLevel(fx:GetFrameLevel() + 2) end
fx:EnableMouse(false)

-- BACKGROUND sublevels on the goal panel: the banner art is -3 and its lights -2 and -1; the
-- shading is 0 and 1, so the dust (-1) and the clouds (-2) sit under it. tools/check.py
-- checks these numbers against Core.lua.
local DUST_LEVEL, CLOUD_LEVEL = -1, -2

-- One drifting layer (Blizzard's numbers: start offset, travel, seconds,
-- turn, peak alpha, when the fade out starts).
local function Layer(flip, width, height, start, travel, seconds, degrees, peak, outAt)
    local t = U.detail:CreateTexture(nil, "BACKGROUND", nil, DUST_LEVEL)
    if flip then
        -- the far layer is the same art mirrored both ways
        t:SetTexture(info.file)
        t:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.bottomTexCoord, info.topTexCoord)
    else
        Art(t, ATLAS, info)
    end
    t:SetSize(width, height)
    t:SetPoint("CENTER", fx, "CENTER", 0, 0)
    t:SetBlendMode("ADD")
    t:SetAlpha(0)
    local g = t:CreateAnimationGroup()
    g:SetLooping("REPEAT")
    local a = g:CreateAnimation("Translation")
    a:SetOffset(start, 0); a:SetDuration(0); a:SetOrder(1)
    a = g:CreateAnimation("Translation")
    a:SetOffset(-travel, 0); a:SetDuration(seconds); a:SetOrder(2)
    a = g:CreateAnimation("Rotation")
    a:SetDegrees(degrees); a:SetDuration(seconds); a:SetOrder(2)
    a = g:CreateAnimation("Alpha")
    a:SetFromAlpha(0); a:SetToAlpha(peak); a:SetDuration(5); a:SetOrder(2)
    a = g:CreateAnimation("Alpha")
    a:SetFromAlpha(peak); a:SetToAlpha(0); a:SetStartDelay(outAt); a:SetDuration(5); a:SetOrder(2)
    a = g:CreateAnimation("Translation")
    a:SetOffset(travel, 0); a:SetDuration(0); a:SetOrder(3) -- as Blizzard's order 3
    return { tex = t, group = g }
end
A.layers = {
    Layer(false, info.width, info.height, 300, 600, 27, 20, 0.15, 22), -- close
    Layer(true, 800, 473, 100, 200, 36, -20, 0.14, 31),                -- far
}

-- Behind the dust, two very faint (5%) copies of "talents-animations-clouds"
-- slide left end to end, 1612 units in 80 s, so the band never runs out.
local CLOUDS = "talents-animations-clouds"
local cloud = AtlasInfo(CLOUDS)
if not cloud and own then cloud = OwnArt("ambience-clouds.blp", 1612, 774) end
if cloud then
    for _, startX in ipairs({ 0, 1612 }) do
        local t = U.detail:CreateTexture(nil, "BACKGROUND", nil, CLOUD_LEVEL)
        Art(t, CLOUDS, cloud)
        t:SetSize(cloud.width, cloud.height)
        t:SetPoint("TOPLEFT", fx, "TOPLEFT", 0, 0)
        t:SetBlendMode("ADD")
        t:SetAlpha(0.05)
        local g = t:CreateAnimationGroup()
        g:SetLooping("REPEAT")
        local m = g:CreateAnimation("Translation")
        m:SetOffset(startX, 0); m:SetDuration(0); m:SetOrder(1)
        m = g:CreateAnimation("Translation")
        m:SetOffset(-1612, 0); m:SetDuration(80); m:SetOrder(2)
        m = g:CreateAnimation("Translation")
        m:SetOffset(1612, 0); m:SetDuration(0); m:SetOrder(3)
        A.layers[#A.layers + 1] = { tex = t, group = g, steady = true }
    end
end

-- Greyscale like the banner art, and faded out toward the left where the
-- goal's text sits: a fixed mask over the panel (Media/fade-left: clear on
-- the left, full from about 65% across), so the fade stays put while the
-- dust drifts and turns underneath it.
local mask = U.detail.CreateMaskTexture and U.detail:CreateMaskTexture()
if mask then
    mask:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\fade-left", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(fx)
end
for _, l in ipairs(A.layers) do
    l.tex:SetDesaturated(true)
    if mask then l.tex:AddMaskTexture(mask) end
end

-- Banner embers turn the drifting dust off (the faint clouds stay).
A.dust = true
function A.SetDust(on)
    A.dust = on and true or false
    local full = FGT.EffectsLevel() == "full"
    for _, l in ipairs(A.layers) do
        if not l.steady then l.tex:SetShown(A.dust and full and U.detail:IsVisible()) end
    end
end

-- Runs only while the goal page is on screen. Settings > Images > Image
-- effects: Full plays the dust and the clouds, Subtle just the clouds, Off
-- neither.
function A.Refresh()
    local level = FGT.EffectsLevel()
    local visible = U.detail:IsVisible()
    fx:SetShown(level ~= "off")
    for _, l in ipairs(A.layers) do
        local on = visible and (level == "full" or (level == "subtle" and l.steady))
        if on and not l.group:IsPlaying() then l.group:Play()
        elseif not on and l.group:IsPlaying() then l.group:Stop(); if not l.steady then l.tex:SetAlpha(0) end end
        -- (textures on the panel no longer hide with `fx`, so each one is shown on its own)
        if l.steady then l.tex:SetShown(visible and level ~= "off")
        else l.tex:SetShown(visible and level == "full" and A.dust) end
    end
end
U.detail:HookScript("OnShow", A.Refresh)
U.detail:HookScript("OnHide", A.Refresh)
U.main:HookScript("OnShow", A.Refresh)
U.main:HookScript("OnHide", A.Refresh)

-- /goals dust: what the effect is doing, for checking in game.
function A.Status()
    local say = function(t) print("|cffffd75eForever Goal Tracker:|r " .. t) end
    say(string.format("dust on goal page: panel level %d, dust level %d, body level %d, shown %s, image effects %s, dust %s",
        U.detail:GetFrameLevel(), fx:GetFrameLevel(), body and body:GetFrameLevel() or -1,
        tostring(fx:IsVisible()), FGT.EffectsLevel(), A.dust and "on" or "off (embers)"))
    for i, l in ipairs(A.layers) do
        say(string.format("  layer %d: %s, playing %s, alpha %.2f, size %dx%d", i, l.steady and "clouds" or "dust",
            tostring(l.group:IsPlaying()), l.tex:GetAlpha(), l.tex:GetWidth(), l.tex:GetHeight()))
    end
end
