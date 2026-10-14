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
local RAIL = 98
local CARD_OPEN = OPEN - 28
local HEAD = 84 -- the header: view, sort and search rows (22 each, 4 apart, 6 in)

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
head:SetHeight(HEAD - 4)
if head.SetClipsChildren then head:SetClipsChildren(true) end
local inner = CreateFrame("Frame", nil, head)
R.head, R.inner = head, inner
local view, sortBar, search = FGT.myGoalsView, U.sortBar, FGT.listSearch
for _, control in ipairs({ view, sortBar, search }) do control:SetParent(inner) end
view:ClearAllPoints()
view:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, -2)
view:SetPoint("TOPRIGHT", inner, "TOPRIGHT", -2, -2)
sortBar:ClearAllPoints()
sortBar:SetPoint("TOPLEFT", view, "BOTTOMLEFT", 0, -4)
sortBar:SetPoint("TOPRIGHT", inner, "TOPRIGHT", -2 - 58, -28) -- room for Clear
U.scroll.scroll:ClearAllPoints()
U.scroll.scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -HEAD)
U.scroll.scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -10, 4)

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
    inner:SetSize(OPEN - 8, HEAD - 4)
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
    row.body:SetSize(CARD_OPEN, FGT.ROW_H)
end

-- ------------------------------------------------------------
-- The filter card beside the rail: the same controls, moved in.
-- Below the dropdown menus (main + 55 and 60), so they open over it.
-- ------------------------------------------------------------
local card = CreateFrame("Frame", nil, S.main, "BackdropTemplate")
R.card = card
card:SetFrameLevel(S.main:GetFrameLevel() + 50)
card:SetSize(OPEN - 8 + 16, HEAD - 4 + 16)
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
filter:SetSize(28, 28)
filter:SetPoint("CENTER", list, "TOPLEFT", 47, -30)
FGT.IconButton(filter, "sliders-white", 17)
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
        divider[#divider + 1] = { tex = t, color = c, side = side }
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
    return (FGT.listQuery or "") ~= "" or (view.value or "all") ~= "all"
end
function R:UpdateFilter()
    local shown, total = 0, 0
    for _, g in ipairs(FGT.ActiveGoals()) do
        total = total + 1
        local row = rows[g.id]
        if row and row:IsShown() then shown = shown + 1 end
    end
    local on = FilterOn()
    filter.count:SetText(on and (shown .. " of " .. total) or "")
    local lit = on or card:IsShown() or filter:IsMouseOver()
    local c = lit and C.ACCENT or C.SUBTEXT
    filter.icon:SetVertexColor(c[1], c[2], c[3]); filter.glow:SetVertexColor(c[1], c[2], c[3])
    filter.lit = on or card:IsShown()
    filter:RefreshIcon()
end
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
    inner:SetSize(OPEN - 8, HEAD - 4)
    Raise(inner, card:GetFrameLevel() + 2)
    inner:SetAlpha(1)
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
function FGT.RailMarks(row)
    if row.rail then return end
    row.rail = CreateFrame("Frame", nil, row)
    row.rail:SetAllPoints(row)
    row.rail:SetFrameLevel(row.icon:GetFrameLevel() + 4) -- over the icon and its finished check
    row.railBar = S.bar(row.rail, 3)
    row.railBar:SetPoint("TOPLEFT", row.icon, "BOTTOMLEFT", 1, -4)
    row.railBar:SetPoint("TOPRIGHT", row.icon, "BOTTOMRIGHT", -1, -4)
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
    end
    self:UpdateFilter()
end

local driver = CreateFrame("Frame", nil, list)
R.driver = driver
local function Finish(quiet)
    driver:SetScript("OnUpdate", nil)
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
    driver:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local p = math.min(1, elapsed / duration)
        -- eased here, both ways, exactly like the Materials drawer
        R.f = from + (R.target - from) * (1 - (1 - p) ^ 3)
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
    if not DB or DB.demoBackup or R.empty then return false end
    return R.saved
end
function R:Sync(instant, quiet)
    local want = Wanted()
    handle:SetShown(not self.empty)
    if (want and 1 or 0) ~= self.target or (instant and self.f ~= self.target) then
        self:Animate(want, instant, quiet)
    end
end

-- Handle click, or /goals rail: switch and remember.
function R:Toggle()
    self.saved = self.target < 1
    local DB = ForeverGoalTrackerDB
    if DB then DB.listRail = self.saved or nil end
    self:Animate(self.saved)
end
handle:SetScript("OnClick", function() R:Toggle() end)

function FGT.ListIsRail() return R.f >= 0.5 end

-- The empty tracker always shows the full list (its welcome lives there).
-- Core's ShowEmptyTracker and HideEmptyTracker call this.
function FGT.RailEmpty(empty)
    if R.empty == empty then return end
    R.empty = empty
    R:Sync(true, true)
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
        R:Sync(true)
    elseif card:IsShown() and not card:IsMouseOver() and not filter:IsMouseOver() then
        local menuOpen = (view.menu and view.menu:IsShown()) or (U.sortMenu and U.sortMenu:IsShown())
            or (FGT.clearMenu and FGT.clearMenu:IsShown())
        if not menuOpen then CloseCard() end
    end
end)
S.main:HookScript("OnShow", function() R:Sync(true) end)
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
