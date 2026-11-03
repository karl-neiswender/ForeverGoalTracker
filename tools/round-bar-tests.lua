-- Rounded progress bars (Karl, 2026-11-03): the radius per height, the colour calls routed to
-- the rounded outline and track, the masks, thin bars turning into pills and segment ends.
-- (The stand-in can't draw, so the look itself is checked in game.)
local F = STUB_NS
local B = F.Bars

assert(B.Radius(24) == 4 and B.Radius(9) == 4 and B.Radius(6) == 3 and B.Radius(4) == 2, "radius: 4, or half a thin bar")
assert(B.Radius(3) == 0 and B.Radius(nil) == 0, "under 4 tall the bar stays square")

local bar = F.MaterialsUI.bar(UIParent, 24)
assert(bar.roundRing and bar.roundBg and bar.roundRadius == 4, "a bar is drawn rounded")
assert(bar.roundMasks and bar.roundMasks.LEFT and bar.roundMasks.RIGHT and not bar.roundMasks.TOPLEFT,
    "two end masks clip its inside (the game allows three per texture)")
assert(bar.roundOwners[1] == bar, "the bar owns its masks")
-- a texture added later (a tick, the hatch, the shine) is clipped by both ends, within the game's
-- three-mask limit (the stand-in errors on a fourth), and a second sweep leaves it alone
local late = bar:CreateTexture()
late.GetObjectType = function() return "Texture" end
late.fgtNoClip, late.fgtClipped = false, false -- (a stand-in texture answers every field; a real one has these unset)
bar.GetRegions = function() return late end
B.Clip(bar); B.Clip(bar)
assert(rawget(late, "_masks") == 2, "two masks per texture: " .. tostring(rawget(late, "_masks")))
bar.GetRegions = nil

-- the backdrop's colour calls reach the rounded pieces (Skin, B.Glass, the hover ring)
bar:SetBackdropBorderColor(1, 0.5, 0.25, 0.4)
local r, g, b, a = bar:GetBackdropBorderColor()
assert(r == 1 and g == 0.5 and b == 0.25 and a == 0.4, "the outline takes the border colour")
bar:SetBackdropColor(0, 0, 0, 0.34)
assert(select(4, bar:GetBackdropColor()) == 0.34, "the rounded track takes the background colour")
bar:SetBackdrop({}) -- (a square backdrop never comes back)
B.Glass(bar)
assert(select(4, bar:GetBackdropBorderColor()) == 0.28, "glass sets its hairline through the outline")

-- a compact card's bar shrinks to 4 tall: its corners follow
B.Resize(bar, 4)
assert(bar.roundRadius == 2, "a thin bar turns into a pill")

-- segments: only the whole bar's outer ends turn
B.SetRoundEnds(bar, true, false)
assert(bar.roundL == true and bar.roundR == false, "an inner segment end stays square")

-- the outline around the goal page bar recolours like a border (overall bar hover)
local outline = B.Outline(bar)
outline:SetBackdropBorderColor(1, 0.85, 0.55, 0)
assert(select(4, outline:GetBackdropBorderColor()) == 0, "the outline fades like a border")
SlashCmdList["FOREVERGOALTRACKER"]("barprobe") -- (runs without error; nothing is visible in the stand-in)
print("  rounded bars: radius, routed colours, masks, pills, segment ends and outline ok")
