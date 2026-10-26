local ADDON, FGT = ...
-- The progress bars' shared light, trail, ticks, numbers and step segments (Karl's redesign,
-- 2026-10-26; reports/Progress-bars-2026-10-26.md). Core.lua's NewBar draws the track and the
-- fill; this file adds what makes a bar feel alive: a bright tip whose glow spills past the bar's
-- edges, a gentle pulse, a flare when the idle glint arrives, a bright trail over what was just
-- earned, ticks that spark when crossed, numbers inside the bar, and goal bars split into one
-- segment per step. Loaded before Core.lua so NewBar can attach the light to every bar it makes.
-- One driver animates everything, only while something on screen moves.

local B = {}
FGT.Bars = B

local SOLID = "Interface\\Buttons\\WHITE8x8"
local STRIPES = "Interface\\AddOns\\" .. ADDON .. "\\Media\\stripes"
local GLOW_TEX = "Interface\\AddOns\\" .. ADDON .. "\\Media\\glow"
local BLACK = { 0, 0, 0 }
local CORE = { 1.00, 0.97, 0.82 }
local GLOW = { 1.00, 0.84, 0.40 }
local BLUE_GLOW = { 0.50, 0.76, 1.00 }
local TRAIL = { 1.00, 0.97, 0.86 }
local PULSE, FLARE, TRAIL_TIME, SPARK = 5.5, 0.45, 1.1, 0.7 -- seconds
local FRAME = 1 / 30 -- the driver paints at most 30 times a second

-- Gradients take two colour objects; reuse one pair for every call (Core.lua explains why).
local lo, hi
local function Gradient(tex, dir, a, aA, b, bA)
    if CreateColor and not lo then lo, hi = CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 1) end
    if lo then
        lo.r, lo.g, lo.b, lo.a = a[1], a[2], a[3], aA
        hi.r, hi.g, hi.b, hi.a = b[1], b[2], b[3], bA
        if pcall(tex.SetGradient, tex, dir, lo, hi) then return end
    end
    tex:SetVertexColor(b[1], b[2], b[3], (aA + bA) / 2)
end

local function Motion() return FGT.Setting and FGT.Setting("celebrations") or "full" end

-- Bars whose light is drawn, and the ones with something moving right now. Plain tables keyed by
-- the bar: per-bar state lives here rather than on textures.
local lit, moving = {}, {}
local driver = CreateFrame("Frame")
driver:Hide()
function B.Wake() driver:Show() end

-- ------------------------------------------------------------
-- The light: a pale core at the end of the fill, taller than the bar, with a soft glow spilling
-- out of the bar's top and bottom edges. Bars under 5 tall (Library cards, the rail) keep their
-- plain fill.
-- ------------------------------------------------------------
local function PaintLight(bar, s, t)
    local k = 0.5
    if s.pulse and Motion() ~= "off" then k = 0.5 - 0.5 * math.cos(t * 2 * math.pi / PULSE) end
    local f = s.flare and math.max(0, 1 - s.flare / FLARE) or 0
    local glow = bar.blue and BLUE_GLOW or GLOW
    s.core:SetAlpha(math.min(1, 0.78 + 0.16 * k + 0.3 * f))
    s.glow:SetVertexColor(glow[1], glow[2], glow[3], math.min(0.85, 0.30 + 0.15 * k + 0.4 * f))
    if s.bloom then s.bloom:SetVertexColor(glow[1], glow[2], glow[3], math.min(0.6, 0.24 + 0.10 * k + 0.3 * f)) end
end

function B.Attach(bar, height)
    if height < 5 then return end
    local spill = height >= 16 and 4 or (height >= 9 and 3 or 2)
    local wide = height >= 13 and 2 or 1
    local s = { height = height, spill = spill }
    -- a faint gold wash at the start of the empty track, so an empty bar reads as waiting
    s.groove = bar:CreateTexture(nil, "BACKGROUND", nil, 2)
    s.groove:SetTexture(SOLID)
    s.groove:SetPoint("TOPLEFT", 1, -1)
    s.groove:SetPoint("BOTTOMLEFT", 1, 1)
    Gradient(s.groove, "HORIZONTAL", GLOW, 0.05, GLOW, 0)
    s.core = bar:CreateTexture(nil, "OVERLAY", nil, 5)
    s.core:SetTexture(SOLID)
    s.core:SetVertexColor(CORE[1], CORE[2], CORE[3], 1)
    s.core:SetSize(wide, height + 2 * math.min(2, spill - 1))
    s.core:SetPoint("RIGHT", bar.fill, "RIGHT", 0, 0)
    -- a soft glow that spills past the bar's top and bottom edges but ends at the core: only the
    -- round glow's left half, so no light runs on past the tip into the empty track or out past
    -- the bar's right end (Karl, 2026-10-26: it read as the gradient overrunning the bar)
    s.glow = bar:CreateTexture(nil, "OVERLAY", nil, 4)
    s.glow:SetTexture(GLOW_TEX)
    s.glow:SetTexCoord(0, 0.5, 0, 1)
    s.glow:SetBlendMode("ADD")
    s.glow:SetSize(math.max(6, math.floor(height * 0.8)), height + 2 * spill + 4)
    s.glow:SetPoint("RIGHT", s.core, "RIGHT", 0, 0)
    if height >= 9 then
        -- Depth (Karl, 2026-10-26: "more tactile"). The track is carved in: a shadow falls from its
        -- top edge over the track and the fill, and its far end darkens. The fill is a lit rod: a
        -- dark rim along its underside and a soft bloom inside it, brightest at the tip and fading
        -- back along the fill and toward its top and bottom.
        -- Third pass (Karl's screenshot, 2026-10-26: muddy; it should feel inset in the groove).
        -- The deep shadows belong to the groove, so they sit under the fill and only show in the
        -- empty track. The fill gets just a thin contact shadow where it meets the groove's top
        -- edge, then a clean highlight band, so the gold stays bright and reads as sitting in it.
        local contact = math.max(2, math.floor(height * 0.14 + 0.5))
        s.inset = bar:CreateTexture(nil, "ARTWORK", nil, 4)
        s.inset:SetTexture(SOLID)
        s.inset:SetPoint("TOPLEFT", 1, -1)
        s.inset:SetPoint("TOPRIGHT", -1, -1)
        s.inset:SetHeight(contact)
        Gradient(s.inset, "VERTICAL", BLACK, 0, BLACK, 0.55)
        s.edge = bar:CreateTexture(nil, "ARTWORK", nil, 4)
        s.edge:SetTexture(SOLID)
        s.edge:SetPoint("TOPLEFT", 1, -1)
        s.edge:SetPoint("TOPRIGHT", -1, -1)
        s.edge:SetHeight(1)
        s.edge:SetVertexColor(0, 0, 0, 0.5)
        s.grooveTop = bar:CreateTexture(nil, "BACKGROUND", nil, 4)
        s.grooveTop:SetTexture(SOLID)
        s.grooveTop:SetPoint("TOPLEFT", 1, -1)
        s.grooveTop:SetPoint("TOPRIGHT", -1, -1)
        s.grooveTop:SetHeight(math.max(2, math.floor(height * 0.45 + 0.5)))
        Gradient(s.grooveTop, "VERTICAL", BLACK, 0, BLACK, 0.65)
        s.under = bar:CreateTexture(nil, "BACKGROUND", nil, 4)
        s.under:SetTexture(SOLID)
        s.under:SetPoint("BOTTOMLEFT", 1, 1)
        s.under:SetPoint("BOTTOMRIGHT", -1, 1)
        s.under:SetHeight(math.max(2, math.floor(height * 0.26 + 0.5)))
        Gradient(s.under, "VERTICAL", BLACK, 0.45, BLACK, 0)
        s.spec = bar:CreateTexture(nil, "ARTWORK", nil, 3)
        s.spec:SetTexture(SOLID)
        s.spec:SetBlendMode("ADD")
        s.spec:SetPoint("TOPLEFT", bar.fill, "TOPLEFT", 0, -contact + 1)
        s.spec:SetPoint("TOPRIGHT", bar.fill, "TOPRIGHT", 0, -contact + 1)
        s.spec:SetHeight(math.max(2, math.floor(height * 0.3 + 0.5)))
        Gradient(s.spec, "VERTICAL", { 1.00, 0.95, 0.80 }, 0, { 1.00, 0.95, 0.80 }, 0.28)
        s.spec:Hide()
        s.start = bar:CreateTexture(nil, "ARTWORK", nil, 4)
        s.start:SetTexture(SOLID)
        s.start:SetPoint("TOPLEFT", bar.fill, "TOPLEFT", 0, 0)
        s.start:SetPoint("BOTTOMLEFT", bar.fill, "BOTTOMLEFT", 0, 0)
        s.startW = math.max(2, math.floor(height * 0.4 + 0.5))
        Gradient(s.start, "HORIZONTAL", BLACK, 0.25, BLACK, 0)
        s.start:Hide()
        s.endShade = bar:CreateTexture(nil, "BACKGROUND", nil, 4)
        s.endShade:SetTexture(SOLID)
        s.endShade:SetPoint("TOPRIGHT", -1, -1)
        s.endShade:SetPoint("BOTTOMRIGHT", -1, 1)
        s.endShade:SetWidth(math.max(3, math.floor(height * 0.3 + 0.5)))
        Gradient(s.endShade, "HORIZONTAL", BLACK, 0, BLACK, 0.45)
        s.rim = bar:CreateTexture(nil, "ARTWORK", nil, 2)
        s.rim:SetTexture(SOLID)
        s.rim:SetPoint("BOTTOMLEFT", bar.fill, "BOTTOMLEFT", 0, 0)
        s.rim:SetPoint("BOTTOMRIGHT", bar.fill, "BOTTOMRIGHT", 0, 0)
        s.rim:SetHeight(1)
        s.rim:SetVertexColor(0, 0, 0, 0.5)
        s.bloom = bar:CreateTexture(nil, "ARTWORK", nil, 5)
        s.bloom:SetTexture(GLOW_TEX)
        s.bloom:SetTexCoord(0, 0.5, 0, 1)
        s.bloom:SetBlendMode("ADD")
        s.bloom:SetPoint("RIGHT", bar.fill, "RIGHT", 0, 0)
        s.bloom:SetHeight(height - 2)
        s.bloom:Hide()
    end
    -- what was just earned: a bright stretch that fades into the fill
    s.trail = bar:CreateTexture(nil, "ARTWORK", nil, 3)
    s.trail:SetTexture(SOLID)
    s.trail:SetBlendMode("ADD")
    s.trail:SetVertexColor(TRAIL[1], TRAIL[2], TRAIL[3], 0.85)
    s.trail:Hide()
    B[bar] = s
    s.core:Hide(); s.glow:Hide()
    bar:HookScript("OnShow", function(self) if lit[self] then B.Wake() end end)
end

-- Called at the end of every Render: shows the light where the fill ends, while the bar is
-- partly filled and allowed a light (segments other than the active one have none).
function B.Update(bar, pct, complete)
    local s = B[bar]
    if not s then return end
    local on = pct > 0.0005 and not complete and not bar.noLight
    s.core:SetShown(on); s.glow:SetShown(on)
    if s.rim then
        local filled = pct > 0.0005
        s.rim:SetShown(filled)
        s.spec:SetShown(filled)
        -- the start shade never covers more than a third of a short fill
        s.start:SetWidth(math.max(1, math.min(s.startW, (bar.fill:GetWidth() or 0) / 3)))
        s.start:SetShown(filled)
    end
    if s.bloom then
        -- reaches back about five bar heights, never past the start of the fill
        s.bloom:SetWidth(math.max(1, math.min(bar.fill:GetWidth() or 0, s.height * 5)))
        s.bloom:SetShown(on)
    end
    if on then
        s.pulse = bar.pulse
        lit[bar] = true
        PaintLight(bar, s, GetTime and GetTime() or 0)
        if s.pulse then B.Wake() end
    else
        lit[bar] = nil
    end
    if s.ticks then B.PlaceTicks(bar, pct) end
end

-- The idle glint has arrived at the tip: a short flare.
function B.Flare(bar)
    local s = B[bar]
    if not (s and lit[bar]) or Motion() == "off" then return end
    s.flare = 0
    moving[bar] = true
    B.Wake()
end

-- Progress went up while you watch: the stretch between the old and new values lights up and
-- fades into the fill. Never for a jump (another goal shown, a pooled row reused).
function B.Gain(bar, from, to)
    local s = B[bar]
    if not s or to <= from + 0.002 or Motion() == "off" or not bar:IsVisible() then return end
    local inner = math.max(0, (bar:GetWidth() or 0) - 2)
    local x = math.floor(inner * from + 0.5)
    local w = math.floor(inner * to + 0.5) - x
    if w < 1 then return end
    s.trail:ClearAllPoints()
    s.trail:SetPoint("TOPLEFT", bar, "TOPLEFT", 1 + x, -1)
    s.trail:SetSize(w, math.max(1, s.height - 2))
    s.trail:SetAlpha(0.85)
    s.trail:Show()
    s.trailT = 0
    moving[bar] = true
    B.Wake()
end

-- ------------------------------------------------------------
-- Ticks (the main bar's 25, 50 and 75; continuous goal bars past 12 steps). A passed tick is
-- a dark notch in the fill; crossing one while you watch makes it spark once.
-- ------------------------------------------------------------
local TICK_OFF = { 1.00, 0.84, 0.47, 0.10 }
local TICK_ON = { 0.27, 0.14, 0.00, 0.50 }
function B.SetTicks(bar, list)
    local s = B[bar]
    if not s then return end
    s.ticks = s.ticks or {}
    for i, at in ipairs(list or {}) do
        local t = s.ticks[i]
        if not t then
            t = { tex = bar:CreateTexture(nil, "OVERLAY", nil, 1) }
            t.tex:SetTexture(SOLID)
            t.tex:SetWidth(1)
            s.ticks[i] = t
        end
        t.at = at
        t.tex:Show()
    end
    for i = #(list or {}) + 1, #s.ticks do s.ticks[i].tex:Hide(); s.ticks[i].at = nil end
    B.PlaceTicks(bar, bar.cur or 0, true)
end

function B.PlaceTicks(bar, pct, quiet)
    local s = B[bar]
    if not (s and s.ticks) then return end
    local inner = math.max(0, (bar:GetWidth() or 0) - 2)
    local hidden = not (FGT.Setting and FGT.Setting("barTicks") ~= false)
    for _, t in ipairs(s.ticks) do
        if t.at then
            t.tex:SetShown(not hidden)
            t.tex:ClearAllPoints()
            -- short marks in the middle of the bar, so they never read as segment gaps
            t.tex:SetPoint("LEFT", bar, "LEFT", 1 + math.floor(inner * t.at + 0.5), 0)
            t.tex:SetHeight(math.max(2, math.floor(s.height * 0.4 + 0.5)))
            local passed = pct >= t.at
            if passed and t.passed == false and not quiet and not bar.instant and bar:IsVisible()
                and Motion() ~= "off" then
                t.spark = 0
                moving[bar] = true
                B.Wake()
            end
            t.passed = passed
            if not t.spark then
                local c = passed and TICK_ON or TICK_OFF
                t.tex:SetVertexColor(c[1], c[2], c[3], c[4])
            end
        end
    end
end

-- ------------------------------------------------------------
-- Hover rings: a frame's border eases to gold and back, at the same quick speed both ways (the
-- slower fade out felt laggy: Karl, 2026-10-26), instead of switching. The resting colour is
-- read the first time, so etched borders keep theirs.
-- Second pass (Karl, 2026-10-26: still felt instant, not eased): a longer fade on an ease-out
-- curve both ways (quick to start, settling softly), and the colour is blended as it is seen
-- (premultiplied), so the change spreads over the whole fade instead of landing at the end. The
-- bars' tooltips use the same time and curve, in and out, so they move with the border.
B.HOVER_FADE = 0.22 -- seconds, in and out (the main bar's numbers use it too)
-- ------------------------------------------------------------
local RING_ON = { 0.55, 0.45, 0.26, 0.32 } -- a quiet, muted gold (was 1.00, 0.84, 0.47 at 0.60: Karl, 2026-10-26, subtler twice)
local rings = {}
local function EaseOut(p) return 1 - (1 - p) ^ 3 end
local function PaintRing(frame, r)
    -- r.a runs 0..1 toward the hover look; either way the visible change starts fast and settles
    local q = r.to == 1 and EaseOut(r.a) or r.a ^ 3
    local c, o = r.rest, RING_ON
    local a = c[4] + (o[4] - c[4]) * q
    if a <= 0.001 then frame:SetBackdropBorderColor(o[1], o[2], o[3], 0) return end
    local ca, oa = c[4], o[4]
    frame:SetBackdropBorderColor((c[1] * ca + (o[1] * oa - c[1] * ca) * q) / a,
        (c[2] * ca + (o[2] * oa - c[2] * ca) * q) / a, (c[3] * ca + (o[3] * oa - c[3] * ca) * q) / a, a)
end
function B.Ring(frame, on)
    local r = rings[frame]
    if not r then
        local cr, cg, cb, ca = 0, 0, 0, 1
        if frame.GetBackdropBorderColor then cr, cg, cb, ca = frame:GetBackdropBorderColor() end
        r = { a = 0, to = 0, rest = { cr or 0, cg or 0, cb or 0, ca or 1 } }
        rings[frame] = r
    end
    r.to = on and 1 or 0
    if Motion() == "off" then
        r.a = r.to
        PaintRing(frame, r)
        return
    end
    B.Wake()
end

-- ------------------------------------------------------------
-- Tooltips the bars show fade in and rise 4 units into place. The game's tooltip is shared by
-- the whole UI, so this only touches it while it still belongs to the bar that asked, and its
-- opacity is put back whenever it hides.
-- ------------------------------------------------------------
local tip = {}
local RISE = 4
-- The tooltip's drop shadow (Core.lua's dark style) is a separate frame, so it does not follow
-- the tooltip's opacity: fade it too, or it stays dark while the tooltip fades out and then
-- vanishes in one frame (Karl, 2026-10-26).
local function TipAlpha(a)
    GameTooltip:SetAlpha(a)
    if GameTooltip.fgtShadow then GameTooltip.fgtShadow:SetAlpha(a) end
end
local function PlaceTip(p)
    local e = EaseOut(p)
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint(tip.point, tip.owner, tip.rel, tip.x, tip.y - RISE * (1 - e))
    TipAlpha(e)
end
-- Call after GameTooltip:Show(): anchors it below the owner, or above it (above = true) where
-- the space below holds what the hover lights up (a segment's step row). Either way it rises.
function B.TipIn(owner, gap, above)
    tip.owner, tip.x = owner, 0
    if above then
        tip.point, tip.rel, tip.y = "BOTTOM", "TOP", gap or 6
    else
        tip.point, tip.rel, tip.y = "TOP", "BOTTOM", -(gap or 6)
    end
    if not tip.hooked then
        tip.hooked = true
        GameTooltip:HookScript("OnHide", function() tip.t, tip.out = nil, nil; TipAlpha(1) end)
    end
    -- moving from one segment to the next: the tooltip was still fading out, so it carries on
    -- from where it is rather than blinking out and starting again
    local from = tip.out and tip.outA or 0
    tip.out = nil
    if Motion() == "off" then
        tip.t = nil
        PlaceTip(1)
        return
    end
    tip.t = B.HOVER_FADE * (1 - (1 - from) ^ (1 / 3)) -- the point on the curve at that opacity
    PlaceTip(tip.t / B.HOVER_FADE)
    B.Wake()
end

-- Instead of GameTooltip:Hide() when the bar is left: the tooltip fades out with the border, then
-- hides, unless something else has taken the tooltip meanwhile.
function B.TipOut(owner)
    if GameTooltip:GetOwner() ~= owner or not GameTooltip:IsShown() then return end
    if Motion() == "off" then GameTooltip:Hide() return end
    tip.t = nil
    tip.out, tip.outOwner, tip.outA = 0, owner, GameTooltip:GetAlpha() or 1
    tip.outFrom = tip.outA
    B.Wake()
end

-- ------------------------------------------------------------
-- The driver
-- ------------------------------------------------------------
local wait = 0
driver:SetScript("OnUpdate", function(self, elapsed)
    -- hover rings and the tooltip's entrance run every frame: they are short and close to the eye
    local quick = false
    for frame, r in pairs(rings) do
        if r.a ~= r.to then
            if r.to > r.a then r.a = math.min(r.to, r.a + elapsed / B.HOVER_FADE)
            else r.a = math.max(r.to, r.a - elapsed / B.HOVER_FADE) end
            PaintRing(frame, r)
            quick = true
        end
    end
    if tip.t then
        if GameTooltip:GetOwner() ~= tip.owner or not GameTooltip:IsShown() then
            tip.t = nil
            TipAlpha(1)
        else
            tip.t = tip.t + elapsed
            local p = math.min(1, tip.t / B.HOVER_FADE)
            PlaceTip(p)
            if p >= 1 then tip.t = nil else quick = true end
        end
    end
    if tip.out then
        if GameTooltip:GetOwner() ~= tip.outOwner or not GameTooltip:IsShown() then
            tip.out = nil -- taken over by something else, or already gone
        else
            tip.out = tip.out + elapsed
            local p = math.min(1, tip.out / B.HOVER_FADE)
            tip.outA = tip.outFrom * (1 - p) ^ 3
            TipAlpha(tip.outA)
            if p >= 1 then
                tip.out = nil
                GameTooltip:Hide()
            else
                quick = true
            end
        end
    end
    wait = wait + elapsed
    if wait < FRAME then return end
    local dt = wait
    wait = 0
    local now = GetTime and GetTime() or 0
    local busy = quick
    for bar in pairs(moving) do
        local s = B[bar]
        local still = false
        if s.flare then
            s.flare = s.flare + dt
            if s.flare >= FLARE then s.flare = nil else still = true end
        end
        if s.trailT then
            s.trailT = s.trailT + dt
            local p = s.trailT / TRAIL_TIME
            if p >= 1 or not bar:IsVisible() then
                s.trailT = nil
                s.trail:Hide()
            else
                s.trail:SetAlpha(0.85 * (1 - p) ^ 1.5)
                still = true
            end
        end
        for _, t in ipairs(s.ticks or {}) do
            if t.spark then
                t.spark = t.spark + dt
                local p = t.spark / SPARK
                if p >= 1 then
                    t.spark = nil
                    local c = t.passed and TICK_ON or TICK_OFF
                    t.tex:SetVertexColor(c[1], c[2], c[3], c[4])
                else
                    local c = TICK_ON
                    t.tex:SetVertexColor(1 - (1 - c[1]) * p, 0.95 - (0.95 - c[2]) * p, 0.8 - (0.8 - c[3]) * p, 1 - 0.5 * p)
                    still = true
                end
            end
        end
        if not still then moving[bar] = nil else busy = true end
    end
    for bar in pairs(lit) do
        local s = B[bar]
        if bar:IsVisible() then
            if s.pulse or s.flare then
                PaintLight(bar, s, now)
                if s.pulse and Motion() ~= "off" then busy = true end
            end
        end
    end
    if not busy then self:Hide() end
end)

-- ------------------------------------------------------------
-- Numbers inside a bar, in two tones: dark over the fill, light over the empty track, switching
-- exactly at the tip. Two copies of each string, each in a frame that clips it to its side.
-- font(parent, size, r, g, b) makes a font string (Core.lua passes its own).
-- ------------------------------------------------------------
local DARK = { 0.17, 0.09, 0.00 }
local DARK_DONE = { 0.05, 0.16, 0.02 }
function B.InsideNumbers(bar, font, size)
    local n = { bar = bar, sides = {} }
    local dark = CreateFrame("Frame", nil, bar)
    dark:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    dark:SetPoint("BOTTOMRIGHT", bar.fill, "BOTTOMRIGHT", 0, 0)
    local light = CreateFrame("Frame", nil, bar)
    light:SetPoint("TOPLEFT", bar.fill, "TOPRIGHT", 0, 0)
    light:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, 1)
    for _, f in ipairs({ dark, light }) do
        if f.SetClipsChildren then f:SetClipsChildren(true) end
        f:SetFrameLevel(bar:GetFrameLevel() + 2)
    end
    for side, frame in pairs({ dark = dark, light = light }) do
        local l = font(frame, size)
        local r = font(frame, size)
        l:SetPoint("LEFT", bar, "LEFT", 10, 0)
        r:SetPoint("RIGHT", bar, "RIGHT", -10, 0)
        r:SetJustifyH("RIGHT")
        if side == "dark" then
            for _, fs in ipairs({ l, r }) do fs:SetShadowOffset(0, 0) end
        else
            for _, fs in ipairs({ l, r }) do
                fs:SetTextColor(0.91, 0.86, 0.75)
                fs:SetShadowColor(0, 0, 0, 1)
                fs:SetShadowOffset(1, -1)
            end
        end
        n.sides[side] = { frame = frame, l = l, r = r }
    end
    function n:SetText(left, right)
        for _, side in pairs(self.sides) do
            side.l:SetText(left or "")
            side.r:SetText(right or "")
        end
        local c = (self.bar.look == "done") and DARK_DONE or DARK
        for _, fs in ipairs({ self.sides.dark.l, self.sides.dark.r }) do fs:SetTextColor(c[1], c[2], c[3]) end
    end
    function n:SetAlpha(a)
        self.sides.dark.frame:SetAlpha(a)
        self.sides.light.frame:SetAlpha(a)
    end
    return n
end

-- ------------------------------------------------------------
-- Goal bars: one segment per step. Each segment is a NewBar (makeBar from Core.lua) placed side
-- by side with small gaps. segs:Set(list) takes, per segment: frac (0..1), done, locked, tip
-- (the one segment with the light), sealed (finished, the goal not yet). Hovering a segment
-- calls segs.onEnter(segs, i, bar) / segs.onLeave(segs, i); segs:Light(i) rings one segment.
-- ------------------------------------------------------------
function B.NewSegments(parent, height, makeBar)
    local segs = CreateFrame("Frame", nil, parent)
    segs:SetHeight(height)
    segs.bars, segs.count, segs.height = {}, 0, height
    segs.gap = height >= 12 and 4 or 2

    local function Make(i)
        local bar = makeBar(segs, height)
        bar.label:Hide()
        bar.hatch = bar:CreateTexture(nil, "BACKGROUND", nil, 3)
        bar.hatch:SetTexture(STRIPES, "REPEAT", "REPEAT")
        if bar.hatch.SetHorizTile then bar.hatch:SetHorizTile(true); bar.hatch:SetVertTile(true) end
        bar.hatch:SetPoint("TOPLEFT", 1, -1)
        bar.hatch:SetPoint("BOTTOMRIGHT", -1, 1)
        bar.hatch:SetVertexColor(1.00, 0.86, 0.55, 0.07)
        bar.hatch:Hide()
        bar.segIndex = i
        bar:EnableMouse(true)
        bar:SetScript("OnEnter", function(self) if segs.onEnter then segs.onEnter(segs, self.segIndex, self) end end)
        bar:SetScript("OnLeave", function(self) if segs.onLeave then segs.onLeave(segs, self.segIndex, self) end end)
        segs.bars[i] = bar
        return bar
    end

    function segs:Layout()
        local n = self.count
        if n < 1 then return end
        local w = (self:GetWidth() or 0)
        local each = (w - self.gap * (n - 1)) / n
        for i = 1, n do
            local bar = self.bars[i]
            local x = math.floor((i - 1) * (each + self.gap) + 0.5)
            local right = math.floor(i * each + (i - 1) * self.gap + 0.5)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", self, "TOPLEFT", x, 0)
            bar:SetSize(math.max(1, right - x), height)
        end
    end
    segs:SetScript("OnSizeChanged", function(self) self:Layout() end)

    -- instant: a different goal is shown, so every segment jumps instead of gliding
    function segs:Set(list, instant)
        local n = #list
        local grew = n ~= self.count
        for i = 1, n do
            local bar = self.bars[i] or Make(i)
            local d = list[i]
            bar:Show()
            bar.noLight = not d.tip
            bar.pulse = d.tip and true or nil
            bar.sealed = d.sealed and true or nil
            bar.hatch:SetShown(d.locked and not d.done and true or false)
            bar:SetBlue(self.blue)
            bar.instant = (instant or grew) and true or nil
            bar:SetProgress(math.floor((d.done and 1 or math.min(0.999, d.frac or 0)) * 1000 + 0.5), 1000)
            bar.instant = nil
        end
        for i = n + 1, #self.bars do self.bars[i]:Hide() end
        self.count = n
        if grew then self:Layout() end
    end

    -- Forever blue for goals new in Forever, like the continuous bar
    function segs:SetBlue(on)
        self.blue = on and true or false
        for k = 1, self.count do self.bars[k]:SetBlue(self.blue) end
    end

    function segs:Light(i)
        for k = 1, self.count do B.Ring(self.bars[k], k == i) end
    end
    return segs
end
