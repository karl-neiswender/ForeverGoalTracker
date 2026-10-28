local ADDON, FGT = ...
-- The goals list folding to an icon rail (Karl's design, 2026-10-14;
-- reports/collapsed-goals-rail-spec.md). The cards themselves narrow into rail
-- items: each icon stays where it is, the card keeps its etched background and
-- every state, and everything right of the icon (Core.lua's row.body) is trimmed
-- from the right by the card's clip as it fades. The list's header controls do
-- the same, and in the rail live in a small filter card beside it. Open by
-- default; the choice is remembered. The empty tracker always shows the full list.
local U, S = FGT.RailUI, FGT.MaterialsUI
local C, STYLE = S.colors, S.styles
local list, content, rows = U.list, U.content, U.rows

local R = { f = 0, target = 0, saved = false }
FGT.Rail = R

-- Widths. OPEN is the list's own width (set from the tabs above it); a rail card
-- is the icon with 10 units each side (70), plus the list's insets (6 + 10 + 12).
local OPEN = list:GetWidth()
if not OPEN or OPEN < 150 then OPEN = 258 end
local RAIL = 98 -- 80 with compact cards (a 32px icon): R:Density
local function RailCenter() return 12 + (RAIL - 28) / 2 end -- the rail card's middle, from the list's left
local CARD_OPEN = OPEN - 28
-- the folded rail's header: its filter button, count and divider (-70), then the cards
-- (was 104, when the open list's controls set it; Karl, 2026-10-28: too much space under it)
local HEAD = 84
-- The open list's header (Karl, 2026-10-28: fold the filters away to simplify the
-- list): the Filters bar, and under it, while open, the view, sort, search and
-- completed-goals controls. The filter card beside the rail always shows them all.
local BAR, HEAD_SHUT, HEAD_OPEN = 22, 32, 130

local function Motion() return FGT.Setting("celebrations") or "full" end
local function Clamp01(x) return math.max(0, math.min(1, x)) end
local function Smooth(x) x = Clamp01(x); return x * x * (3 - 2 * x) end

-- ------------------------------------------------------------
-- Header: the list's controls move into a clipped holder, so they wipe
-- away from the right like the cards. The list's scroll starts at a fixed
-- depth (it was anchored under the search box), so moving the controls
-- into the filter card never moves the cards.
-- ------------------------------------------------------------
local head = CreateFrame("Frame", nil, list)
head:SetPoint("TOPLEFT", list, "TOPLEFT", 4, -4)
head:SetPoint("TOPRIGHT", list, "TOPRIGHT", -4, -4)
head:SetHeight(HEAD_SHUT - 4)
if head.SetClipsChildren then head:SetClipsChildren(true) end
local inner = CreateFrame("Frame", nil, head)
R.head, R.inner = head, inner
local view, sortBar, search = FGT.myGoalsView, U.sortBar, FGT.listSearch
for _, control in ipairs({ view, sortBar, search }) do control:SetParent(inner) end

-- The Filters bar: a disclosure row like the Sort and Show menus, the sliders icon
-- and a count (gold while a filter is on, so folded filters never hide silently),
-- and the gold chevron pointing down while folded, up while open.
local bar = CreateFrame("Button", nil, inner, "BackdropTemplate")
R.bar = bar
bar:SetHeight(BAR)
bar:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, -2)
bar:SetPoint("TOPRIGHT", inner, "TOPRIGHT", -2, -2)
S.etch(bar, STYLE.button, 10)
bar.icon = bar:CreateTexture(nil, "ARTWORK")
bar.icon:SetTexture(FGT.Icon("sliders-white"))
bar.icon:SetSize(14, 14)
bar.icon:SetPoint("LEFT", bar, "LEFT", 7, 0)
bar.label = S.font(bar, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
bar.label:SetPoint("LEFT", bar.icon, "RIGHT", 6, 0)
bar.label:SetText("Filters")
bar.caret = bar:CreateTexture(nil, "OVERLAY")
bar.caret:SetTexture(FGT.Icon("chevron"))
bar.caret:SetSize(14, 14)
bar.caret:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
bar.count = S.font(bar, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
bar.count:SetPoint("RIGHT", bar.caret, "LEFT", -6, 0)

sortBar:ClearAllPoints()
sortBar:SetPoint("TOPLEFT", view, "BOTTOMLEFT", 0, -4)
sortBar:SetPoint("TOPRIGHT", view, "BOTTOMRIGHT", -58, -4) -- room for Clear
-- The Filters bar heads the open list; the rail's filter card has no use for it (the rail
-- shows the count already, Karl 2026-10-28), so there the Show menu starts the card.
local function BarShown(on)
    bar:SetShown(on)
    view:ClearAllPoints()
    if on then
        view:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
        view:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    else
        view:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, -2)
        view:SetPoint("TOPRIGHT", inner, "TOPRIGHT", -2, -2)
    end
end
BarShown(true)
local CARD_INNER = HEAD_OPEN - 4 - BAR - 4 -- the card's controls, without the bar

-- How open the filters are (R.p, 0 to 1) and how folded the list is (R.f) set the
-- header's height; the cards start under it.
R.p = 0
local function PlaceHead()
    local listH = HEAD_SHUT + (HEAD_OPEN - HEAD_SHUT) * R.p
    local h = listH + (HEAD - listH) * Smooth(R.f)
    head:SetHeight(h - 4)
    U.scroll.scroll:ClearAllPoints()
    U.scroll.scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -h)
    U.scroll.scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -10, 4)
end
R.PlaceHead = PlaceHead
-- The controls under the bar at strength `a` (hidden at 0, so nothing folded takes clicks).
-- The empty tracker hides them itself (Core's ShowEmptyTracker).
local function ControlsAt(a)
    if R.empty then return end
    for _, control in ipairs({ view, sortBar, search }) do
        control:SetAlpha(a)
        control:SetShown(a > 0)
    end
end
PlaceHead()
ControlsAt(0) -- folded until the saved choice arrives (PLAYER_LOGIN)

-- Moving the controls between the list and the card: raise the whole group
-- above its new holder, or it could draw under the card's background (a
-- moved frame's children keep their old levels).
local function Raise(frame, level)
    frame:SetFrameLevel(level)
    for _, child in ipairs({ frame:GetChildren() }) do
        if type(child) == "table" then Raise(child, level + 1) end
    end
end
local function InnerFill()
    inner:SetParent(head)
    Raise(inner, head:GetFrameLevel() + 1)
    inner:ClearAllPoints()
    inner:SetPoint("TOPLEFT", head, "TOPLEFT", 0, 0)
    inner:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 0)
end
local function InnerFreeze() -- open width, so the controls never squeeze mid-motion
    inner:SetParent(head)
    Raise(inner, head:GetFrameLevel() + 1)
    inner:ClearAllPoints()
    inner:SetPoint("TOPLEFT", head, "TOPLEFT", 0, 0)
    inner:SetSize(OPEN - 8, HEAD_OPEN - 4)
end
InnerFill()

-- Each card's body: filling the card when open, held at the open width while
-- the card narrows (the card's clip then trims it).
local function BodyFill(row)
    row.body:ClearAllPoints()
    row.body:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.body:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
end
local function BodyFreeze(row)
    row.body:ClearAllPoints()
    row.body:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.body:SetSize(CARD_OPEN, row:GetHeight())
end

-- ------------------------------------------------------------
-- The filter card beside the rail: the same controls, moved in.
-- Below the dropdown menus (main + 55 and 60), so they open over it.
-- ------------------------------------------------------------
local card = CreateFrame("Frame", nil, S.main, "BackdropTemplate")
R.card = card
card:SetFrameLevel(S.main:GetFrameLevel() + 50)
card:SetSize(OPEN - 8 + 16, CARD_INNER + 16)
S.etch(card, STYLE.panel, 12)
FGT.AddGrime(card, 0.18, 12, 0.53, 0, 90)
card.drop = FGT.AddDropShadow(card, 30, 0.5, 6, 10)
card:EnableMouse(true)
card:Hide()
card.drop:Hide() -- (hidden while the window is: OnHide never fired for it)
local function PlaceCard(drop)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, -2 + drop)
end
PlaceCard(0)
local cardDriver = CreateFrame("Frame", nil, card)

-- ------------------------------------------------------------
-- Rail header: the filter button, lit with a count while a filter is on
-- ------------------------------------------------------------
local filter = CreateFrame("Button", nil, list)
R.filter = filter
filter:SetSize(32, 32)
filter:SetPoint("CENTER", list, "TOPLEFT", 47, -30)
FGT.IconButton(filter, "sliders-white", 22) -- larger to fill the folded header (Karl, 2026-10-14; was 17)
filter.count = S.font(filter, 9, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
filter.count:SetPoint("TOP", filter, "BOTTOM", 0, -1)
filter:SetAlpha(0)
filter:Hide()

-- The folded header's floor (Karl, 2026-10-14, to make the bare space read as a
-- header): the goal page's embossed bronze groove (FGT.NewEmbossLine: a black
-- shadow over the panels' edge brown), shortened to the rail and fading in from
-- both ends, centered under the sliders icon. Gradients ignore SetAlpha, so it
-- is repainted with the rail's fade (PaintDivider, from R:Apply).
local DIVIDER_Y, DIVIDER_HALF = -70, 34
local divider = {}
R.divider = divider
for i, c in ipairs({ { 0, 0, 0, 0.75 }, { 0.19, 0.16, 0.11, 0.55 } }) do
    for side = 1, 2 do
        local t = list:CreateTexture(nil, "ARTWORK")
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetSize(DIVIDER_HALF, 1)
        t:SetPoint(side == 1 and "TOPRIGHT" or "TOPLEFT", list, "TOPLEFT", 47, DIVIDER_Y - (i - 1))
        t:Hide()
        divider[#divider + 1] = { tex = t, color = c, side = side, drop = i - 1 }
    end
end
local dividerA
local function PaintDivider(a)
    if a == dividerA then return end
    dividerA = a
    for _, d in ipairs(divider) do
        local c = d.color
        local col, peak = { c[1], c[2], c[3] }, c[4] * a
        -- left half fades in toward the middle, right half fades back out
        if d.side == 1 then S.gradient(d.tex, col, col, 0, peak) else S.gradient(d.tex, col, col, peak, 0) end
        d.tex:SetShown(a > 0)
    end
end

local function FilterOn()
    return (FGT.listQuery or "") ~= "" or (view.value or "all") ~= "all" or FGT.Setting("hideCompletedGoals")
end
function R:UpdateFilter()
    local shown, total = 0, 0
    for _, g in ipairs(FGT.ActiveGoals()) do
        total = total + 1
        local row = rows[g.id]
        if row and row:IsShown() then shown = shown + 1 end
    end
    local on = FilterOn()
    -- always shown while folded (Karl, 2026-10-14): grey, gold while a filter is on
    filter.count:SetText(shown .. " of " .. total)
    local cc = on and C.ACCENT or C.SUBTEXT
    filter.count:SetTextColor(cc[1], cc[2], cc[3])
    local lit = on or card:IsShown() or filter:IsMouseOver()
    local c = lit and C.ACCENT or C.SUBTEXT
    filter.icon:SetVertexColor(c[1], c[2], c[3]); filter.glow:SetVertexColor(c[1], c[2], c[3])
    filter.lit = on or card:IsShown()
    filter:RefreshIcon()
    -- the Filters bar: the same count, "N goals" while nothing is filtered
    bar.count:SetText(on and (shown .. " of " .. total) or (total .. (total == 1 and " goal" or " goals")))
    bar.count:SetTextColor(cc[1], cc[2], cc[3])
    local ic = on and C.ACCENT or (bar:IsMouseOver() and C.TEXT) or C.SUBTEXT
    bar.icon:SetVertexColor(ic[1], ic[2], ic[3])
end

-- Opening and folding the filters: remembered; a short ease in Full motion,
-- at once in Subtle and Off (Subtle never slides).
local fdriver = CreateFrame("Frame", nil, list)
R.fdriver = fdriver
local function PointCaret()
    local open = R.filtersOpen
    bar.caret:SetTexCoord(0, 1, open and 1 or 0, open and 0 or 1)
end
function R:SetFilters(open, instant)
    self.filtersOpen = open and true or false
    local DB = ForeverGoalTrackerDB
    if DB then DB.listFiltersOpen = self.filtersOpen or nil end
    if not open and search:HasFocus() then search:ClearFocus() end
    PointCaret()
    fdriver:SetScript("OnUpdate", nil)
    local target = open and 1 or 0
    local function Done()
        R.p = target
        PlaceHead()
        if R.f == 0 then ControlsAt(target) end
        U.layout() -- the cards' scroll changed height
    end
    if instant or Motion() ~= "full" or R.f > 0 or not list:IsVisible() then Done(); return end
    local from, t = R.p, 0
    local duration = 0.22 * math.max(0.35, math.abs(target - from))
    if open then ControlsAt(math.max(from, 0.01)) end
    fdriver:SetScript("OnUpdate", function(driver, dt)
        t = t + dt
        local p = math.min(1, t / duration)
        R.p = from + (target - from) * (1 - (1 - p) ^ 3)
        PlaceHead()
        ControlsAt(math.max(R.p, 0.01))
        if p >= 1 then driver:SetScript("OnUpdate", nil); Done() end
    end)
end
bar:SetScript("OnClick", function()
    if R.f > 0 then return end -- in the rail's card the filters are always open
    R:SetFilters(not R.filtersOpen)
end)
bar:SetScript("OnEnter", function(self)
    self:SetEtch(STYLE.btnHover)
    self.label:SetTextColor(1, 1, 1)
    R:UpdateFilter()
    if R.f > 0 then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(R.filtersOpen and "Hide filters" or "Show, sort and search")
    GameTooltip:Show()
end)
bar:SetScript("OnLeave", function(self)
    self:SetEtch(STYLE.button)
    self.label:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
    R:UpdateFilter()
    GameTooltip:Hide()
end)
PointCaret()
filter:HookScript("OnEnter", function(self)
    R:UpdateFilter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Search and sort")
    GameTooltip:Show()
end)
filter:HookScript("OnLeave", function() R:UpdateFilter(); GameTooltip:Hide() end)

local function CloseCard()
    if not card:IsShown() then return end
    cardDriver:SetScript("OnUpdate", nil)
    if search:HasFocus() then search:ClearFocus() end
    card:Hide()
    R:UpdateFilter()
end
R.CloseCard = CloseCard
function R:OpenCard()
    if R.f < 1 then return end
    inner:SetParent(card)
    inner:ClearAllPoints()
    inner:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    inner:SetSize(OPEN - 8, CARD_INNER)
    Raise(inner, card:GetFrameLevel() + 2)
    inner:SetAlpha(1)
    ControlsAt(1) -- the card always shows every control
    BarShown(false)
    card:Show(); card.drop:Show()
    local mode = Motion()
    if mode == "off" then PlaceCard(0); card:SetAlpha(1); card.drop:SetAlpha(1)
    else
        local t = 0
        PlaceCard(mode == "full" and 4 or 0); card:SetAlpha(0); card.drop:SetAlpha(0)
        cardDriver:SetScript("OnUpdate", function(driver, dt)
            t = t + dt
            local e = 1 - (1 - math.min(1, t / 0.14)) ^ 3
            card:SetAlpha(e); card.drop:SetAlpha(e)
            PlaceCard(mode == "full" and 4 * (1 - e) or 0)
            if e >= 1 then driver:SetScript("OnUpdate", nil) end
        end)
    end
    R:UpdateFilter()
end
filter:SetScript("OnClick", function() if card:IsShown() then CloseCard() else R:OpenCard() end end)
card:HookScript("OnHide", function() card.drop:Hide() end)

-- ------------------------------------------------------------
-- The handle in the gap between the list and the goal page, like the
-- Materials drawer's: points left to fold the list, right to open it.
-- ------------------------------------------------------------
local handle = CreateFrame("Button", nil, list)
R.handle = handle
handle:SetSize(24, 48)
handle:SetPoint("CENTER", list, "RIGHT", 6, 0)
handle:SetFrameLevel(S.detail:GetFrameLevel() + 10)
handle:SetScript("OnEnter", function(self)
    self.icon:SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
    self.glow:SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(R.target >= 1 and "Show goal names" or "Show icons only")
    GameTooltip:Show()
end)
handle:SetScript("OnLeave", function(self)
    self.icon:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    self.glow:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    GameTooltip:Hide()
end)
FGT.IconButton(handle, "chevron-white", 10)
handle.icon:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
handle.glow:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
local function PointHandle()
    -- the chevron art points down: right for the rail (open the list), left otherwise
    local turn = R.target >= 1 and math.pi / 2 or -math.pi / 2
    handle.icon:SetRotation(turn); handle.glow:SetRotation(turn)
end
PointHandle()

-- ------------------------------------------------------------
-- A card's rail marks, made the first time it folds (most cards in the
-- catalog are never shown): a thin progress sliver under the icon, and the
-- favorite star on the icon's top-right corner with a soft shadow (Karl).
-- ------------------------------------------------------------
local railA = 0
-- The progress sliver: under the icon on a comfortable card; on a compact one there is no room
-- under its 32px icon (it broke out of the card), so it is the card's own thin bottom line,
-- as on the open compact card (Karl, 2026-10-28).
function R.PlaceRailBar(row)
    local bar = row.railBar
    bar:ClearAllPoints()
    if row.compact then
        bar:SetHeight(4)
        bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 3, 3)
        bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -3, 3)
    else
        bar:SetHeight(3)
        bar:SetPoint("TOPLEFT", row.icon, "BOTTOMLEFT", 1, -4)
        bar:SetPoint("TOPRIGHT", row.icon, "BOTTOMRIGHT", -1, -4)
    end
end
function FGT.RailMarks(row)
    if row.rail then return end
    row.rail = CreateFrame("Frame", nil, row)
    row.rail:SetAllPoints(row)
    row.rail:SetFrameLevel(row.icon:GetFrameLevel() + 4) -- over the icon and its finished check
    row.railBar = S.bar(row.rail, 3)
    R.PlaceRailBar(row)
    row.railBar.label:Hide()
    row.railStarShadow = row.rail:CreateTexture(nil, "ARTWORK")
    row.railStarShadow:SetTexture(FGT.Icon("star"))
    row.railStarShadow:SetVertexColor(0, 0, 0, 0.8)
    row.railStarShadow:SetSize(17, 17)
    row.railStarShadow:SetPoint("CENTER", row.icon, "TOPRIGHT", -2, -3.5)
    row.railStar = row.rail:CreateTexture(nil, "OVERLAY")
    row.railStar:SetTexture(FGT.Icon("star"))
    row.railStar:SetSize(14, 14)
    row.railStar:SetPoint("CENTER", row.icon, "TOPRIGHT", -3, -2)
    row.railStar:Hide(); row.railStarShadow:Hide()
    row.rail:SetAlpha(railA)
    row.rail:SetShown(railA > 0)
    return true
end

-- ------------------------------------------------------------
-- Drawing one moment of the fold. f: 0 the full list, 1 the rail.
-- ------------------------------------------------------------
local function FindMore()
    local b = FGT.FindMoreButton and FGT.FindMoreButton()
    if b and not b.plus then
        b.plus = b:CreateTexture(nil, "OVERLAY")
        b.plus:SetTexture(FGT.Icon("plus"))
        b.plus:SetSize(16, 16)
        b.plus:SetPoint("CENTER", 0, 0)
        b.plus:SetAlpha(0)
        b:HookScript("OnEnter", function(self)
            if R.f >= 0.5 then -- the rail's "+": the name only, like every rail item
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine("Find your next goal")
                GameTooltip:Show()
            end
        end)
    end
    return b
end

function R:Apply()
    local f = self.f
    -- width follows f directly: the slide timer eases it like the Materials drawer
    local e = f
    list:SetWidth(OPEN + (RAIL - OPEN) * e)
    -- card text and marks: trimmed by the narrowing card and fading a little ahead of it
    local textA = 1 - Smooth(f / 0.6)
    -- the rail's own marks arrive as the card settles
    railA = Smooth((f - 0.5) / 0.5)
    local made = false
    for _, row in pairs(rows) do
        -- (only the cards on the list; Settle puts the rest right)
        if row:IsShown() then
            row.body:SetAlpha(textA)
            row.body:SetShown(textA > 0)
            if railA > 0 and FGT.RailMarks(row) then made = true end
            if row.rail then
                row.rail:SetAlpha(railA)
                row.rail:SetShown(railA > 0)
            end
        end
    end
    if made then U.refresh() end -- new marks take their card's progress and star
    PlaceHead() -- the folded header is the rail's own height
    local headA = 1 - Smooth(f / 0.45)
    head:SetAlpha(headA)
    head:SetShown(headA > 0)
    filter:SetAlpha(railA)
    PaintDivider(railA)
    filter:SetShown(railA > 0)
    local b = FindMore()
    if b then
        b.text:SetAlpha(1 - Smooth(f / 0.4))
        b.plus:SetAlpha(railA)
    end
    -- the goal page and the Materials drawer follow the list's new edge
    if FGT.materialsPanel then FGT.materialsPanel:Place() end
end

-- At rest: the open list fills its cards again; the rail parks the controls
-- in the filter card (hidden until asked for).
function R:Settle()
    local rail = self.f > 0
    for _, row in pairs(rows) do
        if rail then BodyFreeze(row) else BodyFill(row) end
        row.body:SetAlpha(rail and 0 or 1)
        row.body:SetShown(not rail)
        if row.rail then row.rail:SetAlpha(rail and 1 or 0); row.rail:SetShown(rail) end
    end
    if rail then
        inner:SetParent(card)
    else
        InnerFill()
        CloseCard()
        ControlsAt(R.p) -- back to the bar's own choice
        BarShown(not R.empty)
    end
    PlaceHead()
    self:UpdateFilter()
end

local driver = CreateFrame("Frame", nil, list)
R.driver = driver
local function Finish(quiet)
    driver:SetScript("OnUpdate", nil)
    FGT.railBusy = false
    -- the "Find your next goal" glow fades back in now that the list has settled
    local fm = FGT.findMore
    if fm and fm.comet then fm.comet.on = true end
    list:SetAlpha(1)
    R:Apply()
    R:Settle()
    U.layout()
    -- (quiet: called from inside the empty tracker's own redraw, which would loop)
    if not quiet then S.redraw() end
end

-- Folds (rail = true) or opens the list. Full: the whole morph; Subtle: the
-- list fades out, changes and fades back in, without the slide; Off: at once.
-- A fold can be reversed mid-way; it carries on from where it is.
function R:Animate(rail, instant, quiet)
    self.target = rail and 1 or 0
    PointHandle()
    CloseCard()
    if not rail then ControlsAt(R.p); BarShown(not R.empty) end -- the card showed them all, without the bar
    driver:SetScript("OnUpdate", nil)
    for _, row in pairs(rows) do BodyFreeze(row) end
    InnerFreeze()
    local mode = Motion()
    if instant or mode == "off" or not list:IsVisible() then
        self.f = self.target
        Finish(quiet)
        return
    end
    local elapsed, lastReflow = 0, 0
    -- The glow circling the "Find your next goal" button would race around its changing
    -- border while the list moves: it fades out now and returns in Finish (Karl, 2026-10-14).
    local fm = FGT.findMore
    if fm and fm.comet then fm.comet.on = false end
    if mode == "subtle" then
        local switched = false
        driver:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + dt
            local p = math.min(1, elapsed / 0.3)
            if p >= 0.5 and not switched then switched = true; R.f = R.target; R:Apply() end
            list:SetAlpha(math.abs(1 - 2 * p))
            if p >= 1 then Finish() end
        end)
        return
    end
    local from = self.f
    -- same pace and ease-out as the Materials drawer (0.7 s for a full slide)
    local duration = 0.7 * math.max(0.35, math.abs(self.target - from))
    -- Opening the list narrows the goal page; its banner art then shrinks at its own slower
    -- pace (B.artLag, see B:Fit in Core.lua), not the list's (Karl, 2026-10-14).
    FGT.railBusy = true
    if self.target == 0 and FGT.goalBanner then FGT.goalBanner.artLag = true end
    driver:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local p = math.min(1, elapsed / duration)
        -- eased here, both ways, exactly like the Materials drawer
        local e = 1 - (1 - p) ^ 3
        R.f = from + (R.target - from) * e
        R:Apply()
        if p >= 1 then Finish()
        elseif elapsed - lastReflow >= 0.075 then
            -- the steps re-wrap to the widening page a few times a second, like Materials
            lastReflow = elapsed
            S.reflow()
        end
    end)
end

-- What the list should be now: the saved choice, but never on an empty
-- tracker, and never in a demo scene (the gallery shows the full list).
local function Wanted()
    local DB = ForeverGoalTrackerDB
    if not DB or R.empty then return false end
    -- (a demo scene shows the full list, unless the scene asks for the folded one: the gallery's
    -- Corrupted Ashbringer shot, FGT.demoRail)
    if DB.demoBackup then return FGT.demoRail and true or false end
    return R.saved or (R.narrow and not R.handOpen)
end

-- A narrow window folds the list on its own, so the goal page keeps room to read
-- (Karl, 2026-10-26: unusable on a laptop at the smallest size). The player's own
-- choice is still saved; opening the list by hand on a narrow window holds until
-- the window widens again. Measured against the open list's width, so the fold
-- itself never changes the answer.
local function Narrow()
    local w = S.main:GetWidth() or 0
    -- the page beside the open list and the closed Materials strip (34)
    local page = w - OPEN - 44 - 34
    local need = ((FGT.materialsPanel and FGT.materialsPanel.GUIDE_MIN) or 380) + 60
    -- (20 of slack once folded, so a window right at the edge doesn't flip back and forth)
    return page < need + (R.narrow and 20 or 0)
end
function R:Fit(instant)
    local narrow = Narrow()
    if narrow == (self.narrow or false) then return end
    self.narrow = narrow
    if not narrow then self.handOpen = false end
    self:Sync(instant)
end
function FGT.RailFit(instant) R:Fit(instant) end
function FGT.RailSync(instant) R:Sync(instant) end
function R:Sync(instant, quiet)
    local want = Wanted()
    handle:SetShown(not self.empty)
    if (want and 1 or 0) ~= self.target or (instant and self.f ~= self.target) then
        self:Animate(want, instant, quiet)
    end
end

-- Handle click, or /goals rail: switch and remember.
function R:Toggle()
    local rail = self.target < 1
    -- (on a narrow window a fold may be automatic: opening by hand holds, and clears the saved fold)
    if self.narrow then
        self.handOpen = not rail
        if not rail then self.saved = false end
    else
        self.saved = rail
    end
    local DB = ForeverGoalTrackerDB
    if DB then DB.listRail = self.saved or nil end
    self:Animate(rail)
end
handle:SetScript("OnClick", function() R:Toggle() end)

function FGT.ListIsRail() return R.f >= 0.5 end

-- Card density (Core's FGT.ApplyCardDensity): the rail is the icon with 10 each side, so
-- compact cards fold to a narrower rail; its filter button and divider stay centered on it.
function R:Density()
    RAIL = FGT.Setting("cardDensity") == "compact" and 80 or 98
    local c = RailCenter()
    filter:ClearAllPoints()
    filter:SetPoint("CENTER", list, "TOPLEFT", c, -30)
    for _, d in ipairs(divider) do
        d.tex:ClearAllPoints()
        d.tex:SetPoint(d.side == 1 and "TOPRIGHT" or "TOPLEFT", list, "TOPLEFT", c, DIVIDER_Y - d.drop)
    end
    for _, row in pairs(rows) do if row.railBar then R.PlaceRailBar(row) end end
    if self.f > 0 then self:Apply(); self:Settle() end
end

-- The empty tracker always shows the full list (its welcome lives there).
-- Core's ShowEmptyTracker and HideEmptyTracker call this.
function FGT.RailEmpty(empty)
    if R.empty == empty then return end
    R.empty = empty
    bar:SetShown(not empty) -- nothing to filter
    R:Sync(true, true)
end
-- Core's HideEmptyTracker shows every control again: put the folded ones back.
function FGT.RailFilters()
    if R.f == 0 then ControlsAt(R.p) end
end

-- The filter count follows the search box and the view.
search:HookScript("OnTextChanged", function() R:UpdateFilter() end)
local viewChanged = view.onChange
view.onChange = function(...)
    if viewChanged then viewChanged(...) end
    R:UpdateFilter()
end

-- Clicking anywhere else closes the filter card (not while one of its menus is open).
local events = CreateFrame("Frame")
R.events = events
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("GLOBAL_MOUSE_DOWN")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local DB = ForeverGoalTrackerDB
        R.saved = DB and DB.listRail and true or false
        FGT.ApplyCardDensity() -- the saved Goal cards choice (cards are built before it loads)
        R:SetFilters(DB and DB.listFiltersOpen, true)
        R:Sync(true)
    elseif card:IsShown() and not card:IsMouseOver() and not filter:IsMouseOver() then
        local menuOpen = (view.menu and view.menu:IsShown()) or (U.sortMenu and U.sortMenu:IsShown())
            or (FGT.clearMenu and FGT.clearMenu:IsShown())
        if not menuOpen then CloseCard() end
    end
end)
S.main:HookScript("OnShow", function() R.narrow = Narrow(); if not R.narrow then R.handOpen = false end; R:Sync(true) end)
-- Sizes set by code (scale, reset, the clamp) refold at once; a resize drag waits
-- for mouse-up (Core.lua's grip calls FGT.RailFit).
S.main:HookScript("OnSizeChanged", function() if not FGT.sizeStart and S.main:IsShown() then R:Fit() end end)
S.main:HookScript("OnHide", function() CloseCard(); driver:SetScript("OnUpdate", nil) end)
list:HookScript("OnHide", CloseCard)

-- The Goal Library's filter panel fills this same frame, so it gets the full
-- open width while the Library shows (Karl saw its filters squeezed into the
-- rail, 2026-10-14); back on My Goals the folded width returns. A slide under
-- way is finished first.
local showTab = FGT.ShowTab
FGT.ShowTab = function(which, ...)
    if driver:GetScript("OnUpdate") then R.f = R.target; Finish(true) end
    if which == "library" then
        CloseCard()
        list:SetWidth(OPEN)
    end
    showTab(which, ...)
    if which ~= "library" then R:Apply() end
end

R:Apply()

-- /goals rail: fold or open the list (same as the handle)
function FGT.HandleRailCommand(msg)
    if strtrim(msg or ""):lower() ~= "rail" then return false end
    R:Toggle()
    return true
end
