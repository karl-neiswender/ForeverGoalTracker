local ADDON, FGT = ...
local U = FGT.MaterialsUI

-- Floating dust over the goal page, the same art, speed and strength as the
-- Forever talent window (Blizzard_ClassTalentsFrame.xml, Camelot): two
-- additive layers of "talents-animations-particles" drifting sideways while
-- they slowly turn, each fading in over 5 s, holding, fading out over 5 s.
-- Built on the game's own animation groups, so it costs almost nothing.
-- Clients without that art (Classic Era) simply get none.
local ATLAS = "talents-animations-particles"
local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(ATLAS)
if not info then return end

local A = {}
FGT.ambience = A

-- Clipped just inside the panel's etched edge, above the banner art and
-- under the goal's text and steps.
local fx = CreateFrame("Frame", nil, U.detail)
A.frame = fx
fx:SetPoint("TOPLEFT", U.detail, "TOPLEFT", 4, -4)
fx:SetPoint("BOTTOMRIGHT", U.detail, "BOTTOMRIGHT", -4, 4)
-- One level above the goal panel itself (so above its banner image, which
-- the panel draws), and the goal page's scrolling body above that (so the
-- title, steps and text stay on top of the dust).
fx:SetFrameLevel(U.detail:GetFrameLevel() + 1)
local body = FGT.detailViewport and FGT.detailViewport.scroll
if body and body:GetFrameLevel() <= fx:GetFrameLevel() then body:SetFrameLevel(fx:GetFrameLevel() + 2) end
if fx.SetClipsChildren then fx:SetClipsChildren(true) end
fx:EnableMouse(false)

-- One drifting layer (Blizzard's numbers: start offset, travel, seconds,
-- turn, peak alpha, when the fade out starts).
local function Layer(flip, width, height, start, travel, seconds, degrees, peak, outAt)
    local t = fx:CreateTexture(nil, "BACKGROUND", nil, 7)
    if flip then
        -- the far layer is the same art mirrored both ways
        t:SetTexture(info.file)
        t:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.bottomTexCoord, info.topTexCoord)
    else
        t:SetAtlas(ATLAS)
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
local cloud = C_Texture.GetAtlasInfo(CLOUDS)
if cloud then
    for _, startX in ipairs({ 0, 1612 }) do
        local t = fx:CreateTexture(nil, "BACKGROUND", nil, 6)
        t:SetAtlas(CLOUDS)
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
local mask = fx.CreateMaskTexture and fx:CreateMaskTexture()
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
    for _, l in ipairs(A.layers) do
        if not l.steady then l.tex:SetShown(A.dust) end
    end
end

-- Runs only while the goal page is on screen, and with Image effects on.
function A.Refresh()
    -- Settings > Images > Image effects (the clouds go too)
    local on = U.detail:IsVisible() and FGT.Setting("imageEffects")
    fx:SetShown(FGT.Setting("imageEffects") and true or false)
    for _, l in ipairs(A.layers) do
        if on and not l.group:IsPlaying() then l.group:Play()
        elseif not on and l.group:IsPlaying() then l.group:Stop(); if not l.steady then l.tex:SetAlpha(0) end end
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
        tostring(fx:IsVisible()), tostring(FGT.Setting("imageEffects")), A.dust and "on" or "off (embers)"))
    for i, l in ipairs(A.layers) do
        say(string.format("  layer %d: %s, playing %s, alpha %.2f, size %dx%d", i, l.steady and "clouds" or "dust",
            tostring(l.group:IsPlaying()), l.tex:GetAlpha(), l.tex:GetWidth(), l.tex:GetHeight()))
    end
end
