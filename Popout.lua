local ADDON, FGT = ...
local U, S = FGT.PopoutUI, FGT.MaterialsUI
local C = S.colors
local P = { open = false, rows = {}, headers = {}, fraction = 1, width = 360, height = 300,
    autoFit = true, closeMain = false, shadowOpacity = 0.3, mainLevel = S.main:GetFrameLevel(),
    unfold = 1, bodyTarget = 1, rise = 0, wash = 0, lift = 0 }
FGT.Popout = P

-- Window geometry (UI units). The header and its progress bar stay put;
-- the steps sit in a body that slides open and shut beneath them.
local HEADER_H = 26   -- the title strip, 3 in from the etched rim
local BAR_Y = -32     -- top of the progress bar under the title (8 tall, Karl 2026-10-14; was 4)
local BODY_TOP = 46   -- where the steps start
local CHROME_H = 62   -- header plus bottom margin around the steps
local COLLAPSED = 46  -- header and bar only
P.COLLAPSED = COLLAPSED

local function Label(parent, size, text, r, g, b)
    local label = S.font(parent, size, "", r, g, b)
    label:SetText(text)
    return label
end

local function Clamp(value, low, high) return math.max(low, math.min(high, value)) end
local function Saved()
    local DB = ForeverGoalTrackerDB
    if not DB then return end
    DB.popout = type(DB.popout) == "table" and DB.popout or {}
    return DB.popout
end
local function Tip(button, text)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(text, C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
local function Motion() return FGT.Setting("celebrations") end
local function EaseOut(t) return 1 - (1 - t) ^ 3 end
local function Smooth(t) return t * t * (3 - 2 * t) end

function P:Save()
    local saved = Saved()
    if not saved then return end
    saved.goal, saved.open = self.goalId, self.open or nil
    saved.left, saved.top = self.left, self.top
    saved.width, saved.height = self.width, self.height
    saved.opacity, saved.locked = self.opacity, self.locked or nil
    saved.collapsed = self.collapsed or nil
    saved.autoFit, saved.closeMain, saved.shadowOpacity = self.autoFit, self.closeMain or nil, self.shadowOpacity
end

-- Layers inside the window, bottom to top, as explicit frame levels: the
-- background (chrome) must stay under the clipped steps. Siblings on the
-- same level draw in no fixed order, and a clipping frame draws its whole
-- contents as one group, so a tie let the background cover the text.
function P:Stack()
    local level = self.frame:GetFrameLevel()
    self.chrome:SetFrameLevel(level + 1)
    self.clip:SetFrameLevel(level + 3)
    self.header:SetFrameLevel(level + 4)
    self.bar:SetFrameLevel(level + 4)
    self.grip:SetFrameLevel(level + 6)
    self.options:SetFrameLevel(level + 60)
end

function P:Raise()
    S.main:SetFrameLevel(self.mainLevel)
    self.frame:SetFrameStrata("HIGH")
    self.frame:SetFrameLevel(self.mainLevel + 100)
    self.shadow:SetFrameStrata("HIGH")
    self.shadow:SetFrameLevel(self.mainLevel + 99)
    self:Stack()
end

function P:FocusMain()
    if not self.open then return end
    S.main:SetFrameLevel(self.mainLevel + 200)
end

-- Ask the top mouse target which window owns the click; rectangle tests
-- alone also match windows behind it.
function P:FocusClick()
    if not self.open then return end
    local foci
    if GetMouseFoci then foci = GetMouseFoci()
    else
        local legacy = rawget(_G, "GetMouseFocus")
        foci = legacy and {legacy()} or {}
    end
    for _, focus in ipairs(foci or FGT.EMPTY) do
        while focus do
            if focus == self.frame then self:Raise(); return end
            if focus == S.main then self:FocusMain(); return end
            focus = focus.GetParent and focus:GetParent() or nil
        end
    end
end

-- The shadow follows the open fade, and deepens a little while the window
-- is carried (dragged), so it reads as lifted off the screen.
function P:PaintShadow()
    local alpha = math.min(1, self.shadowOpacity * (1 + 0.6 * self.lift))
    self.shadow:SetAlpha(alpha * self.fraction)
end

function P:Place(offset)
    if not self.frame then return end
    if offset then self.rise = offset end
    local scale = FGT.windowScale or 1
    local screenW = UIParent:GetWidth()
    local screenH = UIParent:GetHeight()
    if screenW <= 0 then screenW = GetScreenWidth() end
    if screenH <= 0 then screenH = GetScreenHeight() end
    screenW, screenH = screenW / scale, screenH / scale
    self.width = Clamp(self.width, math.min(280, screenW - 16), math.max(100, screenW - 16))
    self.height = Clamp(self.height, math.min(80, screenH - 16), math.max(80, screenH - 16))
    self.left = Clamp(self.left or (screenW - self.width - 40), 8, math.max(8, screenW - self.width - 8))
    self.top = Clamp(self.top or (screenH * 0.25), 8, math.max(8, screenH - self.height - 8))
    self.frame:SetScale(scale)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.left, -self.top + (self.rise or 0))
    self.frame:SetSize(self.width, COLLAPSED + (self.height - COLLAPSED) * self.unfold)
    -- The steps keep their full size while the body slides; the clip frame
    -- trims them, so rows never re-wrap or jump mid-motion.
    self.scroll.scroll:SetSize(math.max(50, self.width - 34), math.max(1, self.height - CHROME_H))
    self.content:SetWidth(math.max(50, self.width - 34))
    self.scroll:Update()
    self.shadow:SetScale(scale)
    local shown = self.unfold > 0
    self.clip:SetShown(shown)
    self.scroll.scroll:SetShown(shown)
    self.grip:SetShown(not self.locked and self.unfold >= 1)
    if not shown then self.complete:Hide() end
end

-- (the sliders apply live, every frame while held: nothing is redrawn,
-- saved or allocated unless the value actually changed)
local WHITE = {1, 1, 1}
function P:SetOpacity(value)
    local opacity = Clamp(tonumber(value) or 0.85, 0, 1)
    if opacity == self.opacity then return end
    self.opacity = opacity
    local style = S.styles.panel
    U.vgradient(self.chrome.etchBg, style.top, style.bottom, opacity, opacity)
    self.chrome:SetBackdropBorderColor(style.edge[1], style.edge[2], style.edge[3], opacity)
    self.chrome.etchHi:SetVertexColor(1, 0.92, 0.70, 0.07 * opacity)
    local grime = self.chrome.grimeParts
    grime[1]:SetVertexColor(1, 1, 1, 0.18 * opacity)
    U.vgradient(grime[2], WHITE, WHITE, 0.18 * opacity, 0.07 * opacity)
    grime[3]:SetVertexColor(1, 1, 1, 0.07 * opacity)
    for f = 1, 2 do
        local fade = f == 1 and self.scroll.fadeTop or self.scroll.fadeBottom
        local color = fade.stripColor
        for i, strip in ipairs(fade.strips) do
            strip:SetVertexColor(color[1], color[2], color[3], fade.stripAlphas[i] * opacity)
        end
    end
    self:Save()
end

function P:SetShadowOpacity(value)
    local opacity = Clamp(tonumber(value) or 0.3, 0, 1)
    if opacity == self.shadowOpacity and self.shadowPainted then return end
    self.shadowOpacity, self.shadowPainted = opacity, true
    self:PaintShadow()
    self:Save()
end

-- The tallest the window fits to: 70% of the screen; longer lists scroll.
function P:FitTarget()
    local screenH = UIParent:GetHeight()
    if screenH <= 0 then screenH = GetScreenHeight() end
    screenH = screenH / (FGT.windowScale or 1)
    return Clamp(math.ceil(self.layout.height + CHROME_H), 80, math.max(80, screenH * 0.7))
end

-- While "Fit to steps" is on, the height follows the list as it changes
-- (a finished step hiding, a recipe opening). The top edge stays put and
-- the bottom glides; width is only fitted when the window opens, so the
-- text never re-wraps while you read. Subtle and Off snap.
function P:FollowSteps(instant)
    if not (self.autoFit and self.open and self.layout) or self.collapsed or self.fitting then return end
    local target = self:FitTarget()
    local goal = self.sizeTo or self.height
    if math.abs(target - goal) < 1 then return end
    self.sizeDriver:SetScript("OnUpdate", nil)
    if instant or Motion() ~= "full" or not self.frame:IsVisible() then
        self.sizeTo, self.height = nil, target
        self:Place(); self:Save()
        return
    end
    local from, elapsed = self.height, 0
    self.sizeTo = target
    self.sizeDriver:SetScript("OnUpdate", function(driver, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / 0.24)
        self.height = from + (target - from) * EaseOut(t)
        self:Place()
        if t >= 1 then
            driver:SetScript("OnUpdate", nil)
            self.sizeTo, self.height = nil, target
            self:Place(); self:Save()
        end
    end)
end

function P:StopFollowing()
    self.sizeDriver:SetScript("OnUpdate", nil)
    if self.sizeTo then self.height, self.sizeTo = math.floor(self.height + 0.5), nil end
end

function P:FitSteps()
    if not self.open or self.collapsed or self.fitting then return end
    self:StopFollowing()
    self.fitting = true
    local function Measure(label)
        local file, size, flags = label:GetFont()
        if type(file) == "string" and type(size) == "number" then self.measure:SetFont(file, size, flags) end
        self.measure:SetText(label:GetText() or "")
        return self.measure:GetStringWidth()
    end
    local width = Measure(self.title) + 182
    for _, node in ipairs(self.layout.nodes) do
        local row = node.frame
        local label = row.text or row.name
        if label then
            local left, rowLeft = label:GetLeft(), row:GetLeft()
            local indent = left and rowLeft and math.max(0, left-rowLeft) or 32
            local tail = row.levelText and row.levelText:IsShown() and 80 or
                (row.count and row.count:IsShown() and 52 or 12)
            width = math.max(width, Measure(label) + indent + tail + 36)
        end
    end
    self.width = Clamp(math.ceil(width), 280, 520)
    self:Place()
    self:Refresh()
    self.height = self:FitTarget()
    self:Place()
    self:Save()
    self.fitting = nil
end

function P:SetLocked(locked)
    self.locked = locked and true or false
    self.header:SetScript("OnUpdate", nil)
    self.grip:SetScript("OnUpdate", nil)
    self.grip:SetShown(not self.locked and self.unfold >= 1)
    if self.RefreshOptions then self:RefreshOptions() end
    self:Save()
end

function P:ResetPosition()
    self.left, self.top = nil, nil
    self:Place()
    self:Save()
end

-- A single finite transition. No update script remains while idle.
function P:Animate(show, done)
    self.driver:SetScript("OnUpdate", nil)
    local mode = Motion()
    local from, target, elapsed = self.fraction, show and 1 or 0, 0
    local function Paint(t)
        self.fraction = from + (target - from) * t
        self.frame:SetAlpha(self.fraction)
        self:PaintShadow()
        self:Place(mode == "full" and -6 * (1 - self.fraction) or 0)
        self:PaintPlaceholder()
    end
    if mode == "off" then
        Paint(1)
        if done then done() end
        return
    end
    self.driver:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / (show and 0.20 or 0.16))
        Paint(show and EaseOut(t) or Smooth(t))
        if t == 1 then
            self.driver:SetScript("OnUpdate", nil)
            if done then done() end
        end
    end)
end

-- Folding the steps away (or back) slides the window's bottom edge
-- instead of snapping it: Full slides with the steps fading, Subtle snaps
-- the size and fades the steps in, Off is immediate.
function P:SetBodyOpen(open, instant)
    local target = open and 1 or 0
    if self.bodyTarget == target and (self.unfold == target or self.bodyDriver:GetScript("OnUpdate")) then return end
    self.bodyTarget = target
    self.bodyDriver:SetScript("OnUpdate", nil)
    local mode = Motion()
    if instant or mode == "off" or not self.frame:IsVisible() or (mode == "subtle" and not open) then
        self.unfold = target
        self.clip:SetAlpha(1)
        self:Place()
        return
    end
    if mode == "subtle" then self.unfold = 1; self.clip:SetAlpha(0); self:Place() end
    local from, elapsed = self.unfold, 0
    local duration = open and 0.24 or 0.18
    self.bodyDriver:SetScript("OnUpdate", function(driver, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / duration)
        local e = open and EaseOut(t) or Smooth(t)
        if mode == "subtle" then
            self.clip:SetAlpha(e)
        else
            self.unfold = from + (target - from) * e
            -- the steps fade a touch ahead of the edge closing, behind it opening
            self.clip:SetAlpha(open and e or self.unfold * self.unfold)
            self:Place()
        end
        if t >= 1 then
            driver:SetScript("OnUpdate", nil)
            self.unfold = target
            self.clip:SetAlpha(1)
            self:Place()
        end
    end)
end

function P:Refresh()
    if not self.open or self.refreshing then return end
    local goal = FGT.GoalById(self.goalId)
    if not goal or goal.libraryOnly or not U.active(goal) then self:Close(false); return end
    self.refreshing = true
    local count, single = 0, nil
    for si in ipairs(goal.sections or FGT.EMPTY) do
        if FGT.PartSelected(goal, si) then count, single = count + 1, si end
    end
    self.singleSection = count == 1 and single or nil
    if self.restoreCollapsed ~= nil then
        self.collapsed = self.restoreCollapsed
        if self.singleSection then FGT.sectionOpen[goal.id .. "_" .. self.singleSection] = not self.collapsed end
        self.restoreCollapsed = nil
    elseif self.singleSection then
        self.collapsed = not FGT.SectionIsOpen(goal, self.singleSection)
    end
    local ok, err = pcall(U.render, goal, self)
    if not ok then self.refreshing = nil; error(err) end
    local done, total = U.progress(goal)
    local finished = total > 0 and done >= total
    local section = self.singleSection and goal.sections[self.singleSection]
    local forever = FGT.ForeverWord(goal) and true or false
    self.title:SetText(section and section.name or goal.name)
    self.headerCount:SetText(done .. " / " .. total)
    self.headerCount:SetShown(not finished)
    self.doneCheck:SetShown(finished)
    self.title:ClearAllPoints()
    self.title:SetPoint("LEFT", self.headerIcon, "RIGHT", 7, 0)
    self.title:SetPoint("RIGHT", finished and self.doneCheck or self.headerCount, "LEFT", -8, 0)
    self.headerIcon:SetIcon(FGT.GoalIcon(goal), forever and C.FOREVER or C.GOLD2)
    FGT.SetPlusMinus(self.arrow, not self.collapsed)
    self:PaintHeader()
    self.progress = total > 0 and done / total or 0
    self.bar:SetBlue(forever)
    self.bar:SetProgress(done, total)
    self.complete:SetShown(finished and #self.layout.nodes == 0 and self.unfold > 0)
    self.countText = done .. " / " .. total
    -- (unfolding: take the fitted size at once; the unfold slide carries the edge there)
    self:FollowSteps(self.instantBody or self.bodyTarget ~= 1 or self.unfold < 1)
    self:SetBodyOpen(not self.collapsed, self.instantBody)
    self:Place()
    if self.options:IsShown() then self:RefreshOptions() end
    self:Save()
    self.refreshing = nil
end
P.refresh = function() P:Refresh() end
FGT.RefreshPopout = function() P:Refresh() end

function P:Open(id, collapsed)
    local goal = FGT.GoalById(id)
    if not goal or goal.libraryOnly or not U.active(goal) then return false end
    if self.open and self.goalId == id then
        self:Raise()
        if self.closeMain then S.main:Hide() end
        return true
    end
    local fraction = (self.open or self.closing) and self.fraction or 0
    self.driver:SetScript("OnUpdate", nil)
    self.bodyDriver:SetScript("OnUpdate", nil)
    self.options:Hide()
    self.options.drop:Hide() -- (no OnHide while the window itself is hidden)
    self.settings.lit = nil; self.settings:RefreshIcon()
    self.slotHeight, self.slotWidth, self.layout, self.hidePending = nil, nil, nil, nil
    self.skipPrevious = nil
    self.singleSection, self.collapsed, self.restoreCollapsed = nil, false, collapsed
    self.goalId, self.open, self.closing = id, true, nil
    self.slotId = id
    self.scroll.scroll:SetVerticalScroll(0)
    self.fraction = fraction
    self.unfold, self.bodyTarget = collapsed and 0 or 1, collapsed and 0 or 1
    self.clip:SetAlpha(1)
    self:Place()
    self:Raise()
    self.frame:SetAlpha(self.fraction)
    self:PaintShadow()
    self.frame:Show()
    self.instantBody = true -- a window that is just appearing doesn't also unfold
    self:Refresh()
    self.instantBody = nil
    if self.autoFit and not self.collapsed then self:FitSteps() end
    U.redraw()
    self:Animate(true)
    if self.closeMain then S.main:Hide() end
    self:Save()
    return true
end

function P:ToggleCollapsed()
    if not self.open then return end
    self.options:Hide()
    local goal = FGT.GoalById(self.goalId)
    if not goal then return end
    if self.singleSection then
        local key = goal.id .. "_" .. self.singleSection
        FGT.sectionOpen[key] = not FGT.SectionIsOpen(goal, self.singleSection)
    else self.collapsed = not self.collapsed end
    self:Refresh()
end

function P:Close(dock)
    if not self.open and not self.closing then return end
    self.header:SetScript("OnUpdate", nil)
    self.grip:SetScript("OnUpdate", nil)
    self.options:Hide()
    self.dragging = nil
    self:StopFollowing()
    if FGT.linkCard and FGT.linkCard:GetParent() == self.frame then FGT.CloseLinkCard() end
    if FGT.wowheadCard and FGT.wowheadCard:GetParent() == self.frame then FGT.CloseWowheadCard() end
    local id = self.goalId
    self.open, self.closing = false, true
    self:Save()
    if dock and id and U.active(FGT.GoalById(id)) then
        if FGT.ShowTab then FGT.ShowTab("tracker") end
        FGT.SelectGoal(id)
        S.main:Show()
    else
        U.redraw()
    end
    self:Animate(false, function()
        self.frame:Hide()
        self.closing, self.slotId = nil, nil
        self.fraction = 1
        self.frame:SetAlpha(1)
        self.bodyDriver:SetScript("OnUpdate", nil)
        self.unfold, self.bodyTarget, self.rise = 1, 1, 0
        self.clip:SetAlpha(1)
        S.main:SetFrameLevel(self.mainLevel)
        self:Place()
        self.placeholder:Hide()
        U.redraw()
    end)
end

-- Keep Tips at their original position. A width change remeasures the
-- slot; ticks and recipe expansion in the pop-out do not collapse it.
-- The slot is never taller than the guide's visible area (Karl): a long
-- guide shows one framed empty state with Tips just below, not a tall
-- empty field to scroll past. Tips only move on guides longer than the
-- view, where they were below the fold anyway, so nothing visibly jumps.
-- How much of the steps area shows without scrolling: from the top of the
-- steps list (with the page scrolled to its top) down to the bottom of the
-- goal page's visible area. Measured on screen, because the list's own
-- height is no help on short windows: there the whole page scrolls and the
-- list is as tall as its content (FGT.UpdateDetailViewport).
local function VisibleSteps()
    local steps = U.content:GetParent()
    local page = FGT.detailViewport
    local top = steps and steps:GetTop()
    local bottom = page and page.scroll and page.scroll:GetBottom()
    local visible
    if type(top) == "number" and type(bottom) == "number" and top > bottom then
        -- (with the page scrolled down by s, the list's top sits s higher)
        visible = (top - (page.scroll:GetVerticalScroll() or 0)) - bottom
    end
    if not visible or visible <= 0 then visible = steps and steps:GetHeight() or 0 end
    return visible, page and page.short
end

function FGT.PopoutStepHeight(goal, height, width)
    if (P.open or P.closing) and P.slotId == goal.id then
        if not P.slotHeight or P.slotWidth ~= width then P.slotHeight, P.slotWidth = height, width end
        local visible, short = VisibleSteps()
        local used = P.slotHeight
        if type(visible) == "number" and visible > 0 then used = math.min(used, math.max(60, visible)) end
        P.slotDebug = { raw = P.slotHeight, visible = visible, short = short, used = used }
        return used
    end
    return height
end

function P:PaintPlaceholder()
    local selected = U.selected()
    local active = (self.open or self.closing) and selected and selected.id == self.slotId
    self.placeholder:SetShown(active and true or false)
    if not active then return end
    self.placeholder:SetAlpha(self.fraction)
    -- docking back: the guide's controls (the pop-out arrow, Hide completed,
    -- Expand all) fade in with the steps instead of popping in at the end (Karl)
    if self.closing then
        for _, control in ipairs({ P.launch, FGT.completedStepsBtn, FGT.expandAllBtn }) do
            control:SetAlpha(1 - self.fraction)
        end
    end
    for _, row in ipairs(self.mainRows or FGT.EMPTY) do
        row.fgtPopoutTransfer = true
        row:SetAlpha(1 - self.fraction)
        row:EnableMouse(false)
        if row.icon then row.icon:EnableMouse(false) end
        if self.closing then row:Show()
        elseif self.fraction == 1 then row:Hide() end
    end
end

function FGT.UpdatePopoutPlaceholder(goal, height, width)
    P.mainRows = {}
    for _, pool in ipairs({U.rows, U.headers}) do
        for _, row in ipairs(pool) do
            row.fgtPopoutTransfer = nil
            if row:IsShown() then P.mainRows[#P.mainRows + 1] = row end
            row:SetAlpha(1)
            row:EnableMouse(true)
            if row.icon then row.icon:EnableMouse(true) end
        end
    end
    local slot = math.max(36, height - 6)
    P.placeholder:SetSize(math.max(50, width), slot)
    -- The message and button sit centered as one group (about 42 tall);
    -- the slot is at most the visible area, so the center is on screen.
    P.placeholder.text:ClearAllPoints()
    P.placeholder.text:SetPoint("CENTER", P.placeholder, "TOP", 0, -slot / 2 + 15)
    local active = (P.open or P.closing) and goal.id == P.slotId
    -- (while docking back they show, faded by PaintPlaceholder; otherwise full)
    local docking = active and P.closing
    for _, control in ipairs({ P.launch, FGT.completedStepsBtn, FGT.expandAllBtn }) do control:SetAlpha(1) end
    if active and not docking then FGT.completedStepsBtn:Hide(); FGT.expandAllBtn:Hide() end
    P.launch:SetShown(U.active(goal) and (not active or docking))
    if not active or docking then FGT.LayoutStepControls() end
    P:PaintPlaceholder()
end

function FGT.HidePopoutGuide()
    P.launch:Hide()
    P.placeholder:Hide()
    P.mainRows = nil
end

-- ------------------------------------------------------------
-- The window: the What's new panel's etched surface, grime and shadow
-- ------------------------------------------------------------
local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
P.frame = frame
frame.fgtOwn = true
frame:SetFrameStrata("HIGH")
frame:SetFrameLevel(S.main:GetFrameLevel() + 100)
frame:SetClampedToScreen(true)
frame:SetDontSavePosition(true)
frame:EnableMouse(true)
frame:Hide()
P.chrome = CreateFrame("Frame", nil, frame, "BackdropTemplate")
P.chrome:SetAllPoints(frame)
P.chrome:EnableMouse(false)
S.etch(P.chrome, S.styles.panel, 12)
FGT.AddGrime(P.chrome, 0.18, 12, 0.61, 0, 140)
P.body, P.heading, P.rim = P.chrome.etchBg, P.chrome.etchBg, P.chrome
P.shadow = FGT.AddDropShadow(frame, 40, 1, 12, 12)
P.shadow:EnableMouse(false)
P.shadow.pieces[9]:Hide() -- outer shadow only; transparent body stays transparent
P.shadow:Hide()

-- ------------------------------------------------------------
-- Header: click to fold the steps away, drag to move
-- ------------------------------------------------------------
P.header = CreateFrame("Frame", nil, frame)
P.header:SetPoint("TOPLEFT", 3, -3)
P.header:SetPoint("TOPRIGHT", -3, -3)
P.header:SetHeight(HEADER_H)
P.header:EnableMouse(true)
-- A warm wash under the title while the pointer is on it: the strip is
-- something you can click and carry. Fades in from the left, like the
-- guide's step-row hover. A gradient, so it is redrawn rather than faded.
P.washTex = P.header:CreateTexture(nil, "BACKGROUND")
P.washTex:SetTexture("Interface\\Buttons\\WHITE8x8")
P.washTex:SetAllPoints(P.header)
P.washTex:Hide()
local WASH = { 1.00, 0.86, 0.52 }
P.arrow = Label(P.header, 10, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
P.arrow:SetWidth(10)
P.arrow:SetPoint("LEFT", 6, 0)
P.headerIcon = U.icon(P.header, 18)
P.headerIcon:SetPoint("LEFT", P.arrow, "RIGHT", 7, 0)
P.headerIcon:EnableMouse(true)
P.headerIcon:SetScript("OnEnter", function(self)
    local goal = FGT.GoalById(P.goalId)
    if not goal then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(goal.name, C.TITLE[1], C.TITLE[2], C.TITLE[3])
    if FGT.SetPreviewIds(goal) then GameTooltip:AddLine("Ctrl-click: Try on the whole set", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3]) end
    GameTooltip:Show()
end)
P.headerIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
P.headerIcon:SetScript("OnMouseUp", function(_, button)
    local goal = FGT.GoalById(P.goalId)
    if not goal then return end
    if FGT.PreviewSetClick(goal, button) then return end
    local reward = goal.rewardItem or (goal.completeWith and goal.completeWith.item)
    if type(reward) == "table" then reward = reward[1] end
    if reward and not goal.sections then FGT.PreviewItemClick(reward, button) end
end)

-- Icon buttons on the right, sized like the main window's (close a hair
-- smaller than the gear, as there), each in a 20 unit hit square.
local function HeaderButton(hint, action, icon, size)
    local b = CreateFrame("Button", nil, P.header)
    b:SetSize(20, 20)
    Tip(b, hint)
    b:SetScript("OnClick", action)
    FGT.IconButton(b, icon, size)
    return b
end
P.close = HeaderButton("Close pop-out", function() P:Close(false) end, "close", 12)
P.close:SetPoint("RIGHT", -2, 0)
P.settings = HeaderButton("Pop-out settings", function() P:ToggleOptions() end, "gear", 14)
P.settings:SetPoint("RIGHT", P.close, "LEFT", 0, 0)
P.dock = HeaderButton("Bring back to main window", function() P:Close(true) end, "dock", 13)
P.dock:SetPoint("RIGHT", P.settings, "LEFT", 0, 0)

P.headerCount = Label(P.header, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
P.headerCount:SetPoint("RIGHT", P.dock, "LEFT", -6, 0)
P.headerCount:SetJustifyH("RIGHT")
-- a finished goal swaps its count for the guide's green check
P.doneCheck = P.header:CreateTexture(nil, "ARTWORK")
P.doneCheck:SetTexture(FGT.Icon("check-white"))
P.doneCheck:SetVertexColor(C.DONE[1], C.DONE[2], C.DONE[3])
P.doneCheck:SetSize(13, 13)
P.doneCheck:SetPoint("RIGHT", P.dock, "LEFT", -6, 0)
P.doneCheck:Hide()
P.title = S.title(P.header, 13)
P.title:SetText("")
P.title:SetPoint("LEFT", P.headerIcon, "RIGHT", 7, 0)
P.title:SetPoint("RIGHT", P.headerCount, "LEFT", -8, 0)
P.title:SetWordWrap(false)
P.title:SetJustifyH("LEFT")

function P:PaintHeader()
    local w = self.wash
    self.washTex:SetShown(w > 0.001)
    if w > 0.001 then S.gradient(self.washTex, WASH, WASH, 0.055 * w, 0) end
    if self.arrow.pm then self.arrow.pm:SetAlpha(0.72 + 0.28 * w) end
end

-- One small driver eases the hover wash and the carried-window shadow,
-- and stops once both have settled with the pointer away.
P.fx = CreateFrame("Frame", nil, frame)
-- (the wash is for the strip itself: not the icon or the buttons, which
-- don't fold the window and light up on their own)
local stripChildren = {P.close, P.settings, P.dock, P.headerIcon} -- (built once: checked every frame)
local function OverStrip()
    if not (P.open and P.header:IsMouseOver()) then return false end
    for i = 1, #stripChildren do
        if stripChildren[i]:IsMouseOver() then return false end
    end
    return true
end
local function FxStep(_, dt)
    local hover = OverStrip() and not P.dragging
    local washTo, liftTo = hover and 1 or 0, P.dragging and 1 or 0
    if Motion() == "off" then
        P.wash, P.lift = washTo, liftTo
    else
        -- in quickly, out slowly
        P.wash = washTo > P.wash and math.min(1, P.wash + dt / 0.12) or math.max(0, P.wash - dt / 0.28)
        P.lift = liftTo > P.lift and math.min(1, P.lift + dt / 0.14) or math.max(0, P.lift - dt / 0.30)
    end
    P:PaintHeader()
    P:PaintShadow()
    if P.wash == washTo and P.lift == liftTo and not P.header:IsMouseOver() and not P.dragging then
        P.fx:SetScript("OnUpdate", nil)
    end
end
function P:WakeFx() self.fx:SetScript("OnUpdate", FxStep) end
P.header:SetScript("OnEnter", function() P:WakeFx() end)

-- Thin progress bar under the title: the My Goals card's bar, so it
-- glides, glints and turns green with the rest of the tracker.
P.bar = S.bar(frame, 8)
P.bar:SetPoint("TOPLEFT", 12, BAR_Y)
P.bar:SetPoint("TOPRIGHT", -12, BAR_Y)
P.bar.label:Hide()
P.bar:EnableMouse(false)

-- ------------------------------------------------------------
-- Body: the steps, clipped so the window can fold them away smoothly
-- ------------------------------------------------------------
P.clip = CreateFrame("Frame", nil, frame)
P.clip:SetPoint("TOPLEFT", 3, -(BODY_TOP - 4))
P.clip:SetPoint("BOTTOMRIGHT", -3, 3)
if P.clip.SetClipsChildren then P.clip:SetClipsChildren(true) end
P.scroll = S.scroll(P.clip)
P.scroll.scroll:SetPoint("TOPLEFT", 9, -4)
P.content = P.scroll.content
P.scroll:Finalize()
-- the thumb sits close to the rim, clear of the step counts (What's new)
P.scroll.trackHit:ClearAllPoints()
P.scroll.trackHit:SetPoint("TOP", P.scroll.scroll, "TOPRIGHT", 9, 0)
P.scroll.trackHit:SetPoint("BOTTOM", P.scroll.scroll, "BOTTOMRIGHT", 9, 0)
FGT.EnableGoalLinks(P.content)
P.complete = Label(P.clip, 12, "Complete", C.DONE[1], C.DONE[2], C.DONE[3])
P.complete:SetPoint("TOPLEFT", 11, -6)
P.complete:Hide()
P.measure = Label(frame, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
P.measure:SetWidth(10000)
P.measure:SetWordWrap(false)
P.measure:Hide()
P.bodyDriver = CreateFrame("Frame", nil, frame)
P.sizeDriver = CreateFrame("Frame", nil, frame)

-- Resize grip: the main window's three dots, lit on hover.
P.grip = CreateFrame("Button", nil, frame)
P.grip:SetSize(14, 14)
P.grip:SetPoint("BOTTOMRIGHT", -3, 3)
P.grip.dots = {}
for _, spot in ipairs({{-2, 2}, {-2, 7}, {-7, 2}}) do
    local dot = S.flat(P.grip, C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], 0.5)
    dot:SetSize(2, 2)
    dot:SetPoint("BOTTOMRIGHT", spot[1], spot[2])
    P.grip.dots[#P.grip.dots + 1] = dot
end
local function LightGrip(on)
    local c = on and C.ACCENT or C.SUBTEXT
    for _, dot in ipairs(P.grip.dots) do dot:SetVertexColor(c[1], c[2], c[3], on and 0.95 or 0.5) end
end
P.grip:SetScript("OnEnter", function(self)
    LightGrip(true)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Drag to resize", C.TITLE[1], C.TITLE[2], C.TITLE[3])
    GameTooltip:Show()
end)
P.grip:SetScript("OnLeave", function(self)
    if not self:GetScript("OnUpdate") then LightGrip(false) end
    GameTooltip:Hide()
end)

local function StopMotion(handle)
    handle:SetScript("OnUpdate", nil)
    if handle == P.grip then
        LightGrip(P.grip:IsMouseOver())
        P:Refresh()
    end
    if P.dragging then P.dragging = nil; P:WakeFx() end
    P:Save()
end
local function StartMotion(handle, resize)
    if P.locked or not P.open then return end
    P.driver:SetScript("OnUpdate", nil)
    if resize then P:StopFollowing() end
    P.fraction = 1; frame:SetAlpha(1); P:Place(0); P:PaintShadow(); P:PaintPlaceholder()
    local x, y = GetCursorPosition()
    local left, top, width, height = P.left, P.top, P.width, P.height
    local scale = math.max(0.1, frame:GetEffectiveScale())
    local elapsed = 0
    handle.moved = false
    handle:SetScript("OnUpdate", function(self, dt)
        if not IsMouseButtonDown("LeftButton") then StopMotion(self); return end
        local cx, cy = GetCursorPosition()
        if math.abs(cx-x) + math.abs(cy-y) >= 4 * scale then
            if not self.moved and not resize then P.dragging = true; P:WakeFx() end
            self.moved = true
        end
        if not self.moved then return end
        if resize then P.autoFit = false end -- actual manual resizing takes precedence
        if resize then P.width, P.height = width + (cx-x)/scale, height - (cy-y)/scale
        else P.left, P.top = left + (cx-x)/scale, top - (cy-y)/scale end
        P:Place()
        elapsed = elapsed + dt
        if resize and elapsed >= 0.075 then elapsed = 0; P:Refresh() end
    end)
end
P.header:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    self.pressed, self.moved = true, false
    StartMotion(self, false)
end)
P.header:SetScript("OnMouseUp", function(self, button)
    local click = self.pressed and not self.moved and button == "LeftButton"
    self.pressed = nil
    StopMotion(self)
    if click then P:ToggleCollapsed() end
end)
P.header:SetScript("OnHide", function(self) self.pressed = nil; StopMotion(self) end)
P.grip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then LightGrip(true); StartMotion(self, true) end
end)
P.grip:SetScript("OnMouseUp", function(self) StopMotion(self); P:Refresh() end)
P.grip:SetScript("OnHide", function(self) StopMotion(self) end)
P.driver = CreateFrame("Frame", nil, frame)
frame:HookScript("OnHide", function()
    P.driver:SetScript("OnUpdate", nil)
    P.fx:SetScript("OnUpdate", nil)
    P:StopFollowing()
    P.wash, P.lift, P.dragging = 0, 0, nil
    P:PaintHeader()
end)

-- ------------------------------------------------------------
-- Settings: a small card under the gear, with the Settings page's own
-- switches and sliders
-- ------------------------------------------------------------
local OPTIONS_W = 252
P.options = CreateFrame("Frame", nil, frame, "BackdropTemplate")
P.options:SetFrameLevel(frame:GetFrameLevel() + 60)
P.options:SetWidth(OPTIONS_W)
P.options:SetClampedToScreen(true)
P.options:SetPoint("TOPRIGHT", P.header, "BOTTOMRIGHT", 2, -4)
P.options.fgtOwn = true
P.options:EnableMouse(true)
S.etch(P.options, S.styles.panel, 12)
FGT.AddGrime(P.options, 0.18, 12, 0.23, 0, 90)
P.options.drop = FGT.AddDropShadow(P.options, 30, 0.5, 6, 10)
P.options:Hide()
-- (the window is hidden here, so the card's OnHide never fired: hide its
-- shadow directly, or it shows with the window; OnShow brings it back)
P.options.drop:Hide()
P.optionControls = {}

local optionY = 10
local function OptionRow(height)
    local row = CreateFrame("Button", nil, P.options)
    row:SetPoint("TOPLEFT", 12, -optionY)
    row:SetPoint("TOPRIGHT", -12, -optionY)
    row:SetHeight(height)
    optionY = optionY + height
    return row
end
local function ToggleRow(text, get, set, hint)
    local row = OptionRow(26)
    row.label = Label(row, 11, text, C.TEXT[1], C.TEXT[2], C.TEXT[3])
    row.label:SetPoint("LEFT")
    local toggle = FGT.NewToggle(row, { get = get, set = set })
    toggle:ClearAllPoints()
    toggle:SetPoint("RIGHT", 0, 0)
    -- the whole row is the switch's hit area
    row:SetScript("OnClick", function() toggle:GetScript("OnClick")(toggle) end)
    row:SetScript("OnEnter", function(self)
        self.label:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3])
        if hint then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(hint, C.TEXT[1], C.TEXT[2], C.TEXT[3], true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.label:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
        GameTooltip:Hide()
    end)
    P.optionControls[#P.optionControls + 1] = toggle
    return row
end
local function Divider()
    optionY = optionY + 6
    local line = FGT.NewEmbossLine(P.options)
    line:SetPoint("TOPLEFT", 12, -optionY)
    line:SetPoint("TOPRIGHT", -12, -optionY)
    optionY = optionY + 8
end
local function SliderRow(text, get, apply)
    local row = OptionRow(26)
    row:EnableMouse(false)
    row.label = Label(row, 11, text, C.TEXT[1], C.TEXT[2], C.TEXT[3])
    row.label:SetPoint("LEFT")
    local slider = FGT.NewSlider(row, { min = 0, max = 100, step = 1, live = true,
        get = get, set = apply, apply = apply })
    slider:ClearAllPoints()
    slider:SetPoint("RIGHT", 0, 0)
    P.optionControls[#P.optionControls + 1] = slider
    return row
end

ToggleRow("Lock position", function() return P.locked end, function(on) P:SetLocked(on) end)
ToggleRow("Hide completed steps", function() return FGT.Setting("hideCompletedSteps") end, function(on)
    FGT.SetSetting("hideCompletedSteps", on and true or false); U.redraw(); P:Refresh()
end)
ToggleRow("Fit to steps", function() return P.autoFit end, function(on)
    P.autoFit = on and true or false
    if P.autoFit then P:FitSteps() end
    P:Save()
end, "The window grows and shrinks with its steps. Resizing it yourself turns this off.")
ToggleRow("Close main on pop-out", function() return P.closeMain end, function(on)
    P.closeMain = on and true or false; P:Save()
end)
Divider()
SliderRow("Background", function() return P.opacity end, function(v) P:SetOpacity(v) end)
SliderRow("Shadow", function() return P.shadowOpacity end, function(v) P:SetShadowOpacity(v) end)
Divider()

-- Quiet text actions along the bottom, like the guide's "Hide completed"
local links = OptionRow(20)
P.optionLinks = {}
local function LinkButton(text, action)
    local b = CreateFrame("Button", nil, links)
    b:SetHeight(20)
    b.text = Label(b, 10, text, C.INK2[1], C.INK2[2], C.INK2[3])
    b.text:SetPoint("LEFT")
    b:SetScript("OnEnter", function(self) self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
    b:SetScript("OnLeave", function(self) self.text:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3]) end)
    b:SetScript("OnClick", action)
    P.optionLinks[#P.optionLinks + 1] = b
    return b
end
LinkButton("Fit now", function() P:FitSteps(); P.options:Hide() end)
LinkButton("Reset position", function() P:ResetPosition(); P.options:Hide() end)
P.groupsButton = LinkButton("Expand all", function()
    local goal = FGT.GoalById(P.goalId)
    if not goal or not goal.sections then return end
    local expand = false
    for si in ipairs(goal.sections) do if FGT.PartSelected(goal, si) and not FGT.SectionIsOpen(goal, si) then expand = true end end
    for si in ipairs(goal.sections) do if FGT.PartSelected(goal, si) then FGT.sectionOpen[goal.id .. "_" .. si] = expand end end
    P:Refresh()
end)
P.options:SetHeight(optionY + 10)

function P:RefreshOptions()
    for _, control in ipairs(self.optionControls) do control:Refresh() end
    local goal = FGT.GoalById(self.goalId)
    local groups = goal and goal.sections and not self.singleSection
    if groups then
        local expand = false
        for si in ipairs(goal.sections) do
            if FGT.PartSelected(goal, si) and not FGT.SectionIsOpen(goal, si) then expand = true end
        end
        self.groupsButton.text:SetText(expand and "Expand all" or "Collapse all")
    end
    self.groupsButton:SetShown(groups and true or false)
    local x = 0
    for _, b in ipairs(self.optionLinks) do
        if b:IsShown() then
            b:SetWidth(math.ceil(b.text:GetStringWidth()) + 2)
            b:ClearAllPoints(); b:SetPoint("LEFT", links, "LEFT", x, 0)
            x = x + b:GetWidth() + 14
        end
    end
end

-- Opens with a short fade and drop from the gear; closes at once.
local optionsDriver = CreateFrame("Frame", nil, P.options)
local function PlaceOptions(drop)
    P.options:ClearAllPoints()
    P.options:SetPoint("TOPRIGHT", P.header, "BOTTOMRIGHT", 2, -4 + drop)
end
function P:ToggleOptions()
    if self.options:IsShown() then self.options:Hide(); return end
    self:RefreshOptions()
    self.options:Show()
    self.settings.lit = true; self.settings:RefreshIcon()
    local mode = Motion()
    if mode == "off" then PlaceOptions(0); self.options:SetAlpha(1); self.options.drop:SetAlpha(1); return end
    local t = 0
    PlaceOptions(mode == "full" and 4 or 0); self.options:SetAlpha(0); self.options.drop:SetAlpha(0)
    optionsDriver:SetScript("OnUpdate", function(driver, dt)
        t = t + dt
        local e = EaseOut(math.min(1, t / 0.14))
        P.options:SetAlpha(e); P.options.drop:SetAlpha(e)
        PlaceOptions(mode == "full" and 4 * (1 - e) or 0)
        if e >= 1 then driver:SetScript("OnUpdate", nil) end
    end)
end
P.options:HookScript("OnHide", function()
    optionsDriver:SetScript("OnUpdate", nil)
    P.options:SetAlpha(1); P.options.drop:SetAlpha(1); PlaceOptions(0)
    P.settings.lit = nil; P.settings:RefreshIcon()
end)

-- ------------------------------------------------------------
-- In the main guide: a recessed slot where the steps were
-- ------------------------------------------------------------
P.placeholder = CreateFrame("Frame", nil, U.content)
P.placeholder.fgtPopoutTransfer = true
P.placeholder:SetPoint("TOPLEFT")
P.placeholder:EnableMouse(false)
P.placeholder:Hide()
local recess = S.flat(P.placeholder, 0, 0, 0, 0.22)
recess:SetDrawLayer("BACKGROUND")
recess:SetAllPoints()
-- Plain alpha strips rather than gradient textures, so frame fading works.
for i = 1, 10 do
    for _, edge in ipairs({"TOP", "LEFT", "BOTTOM", "RIGHT"}) do
        local shadow = S.flat(P.placeholder, 0, 0, 0, (1 - i/11) * (edge == "TOP" and 0.42 or 0.24))
        shadow:SetDrawLayer("BACKGROUND")
        if edge == "TOP" or edge == "BOTTOM" then
            shadow:SetHeight(1)
            shadow:SetPoint(edge .. "LEFT", i-1, (edge == "TOP" and -1 or 1) * (i-1))
            shadow:SetPoint(edge .. "RIGHT", -(i-1), (edge == "TOP" and -1 or 1) * (i-1))
        else
            shadow:SetWidth(1)
            shadow:SetPoint("TOP" .. edge, (edge == "LEFT" and 1 or -1) * (i-1), -(i-1))
            shadow:SetPoint("BOTTOM" .. edge, (edge == "LEFT" and 1 or -1) * (i-1), i-1)
        end
    end
end
P.placeholder.text = Label(P.placeholder, 11, "Steps are popped out", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
P.placeholder.text:SetPoint("TOP", 0, -12)
-- "Bring back" as a small button with the dock arrow. Flat colors, not the
-- etched gradient: the slot fades with the transfer, and gradients don't.
local back = CreateFrame("Button", nil, P.placeholder, "BackdropTemplate")
P.placeholder.back = back
back:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 } })
back.fill = S.flat(back, 0, 0, 0, 1)
back.fill:SetDrawLayer("BACKGROUND")
back.fill:SetPoint("TOPLEFT", 2, -2)
back.fill:SetPoint("BOTTOMRIGHT", -2, 2)
back.sheen = S.flat(back, 1, 0.92, 0.70, 0.07)
back.sheen:SetDrawLayer("BORDER")
back.sheen:SetHeight(1)
back.sheen:SetPoint("TOPLEFT", 2, -2)
back.sheen:SetPoint("TOPRIGHT", -2, -2)
back.icon = back:CreateTexture(nil, "ARTWORK")
back.icon:SetTexture(FGT.Icon("dock"))
back.icon:SetSize(12, 12)
back.icon:SetPoint("LEFT", 9, 0)
back.text = Label(back, 10, "Bring back", C.TEXT[1], C.TEXT[2], C.TEXT[3])
back.text:SetPoint("LEFT", back.icon, "RIGHT", 5, 0)
back:SetSize(math.max(90, math.ceil(back.text:GetStringWidth()) + 38), 22)
back:SetPoint("TOP", P.placeholder.text, "BOTTOM", 0, -8)
local function PaintBack(hover)
    local st = hover and S.styles.btnHover or S.styles.button
    back.fill:SetVertexColor((st.top[1] + st.bottom[1]) / 2, (st.top[2] + st.bottom[2]) / 2, (st.top[3] + st.bottom[3]) / 2, 1)
    back:SetBackdropBorderColor(st.edge[1], st.edge[2], st.edge[3], 1)
    local c = hover and C.TITLE or C.TEXT
    back.text:SetTextColor(c[1], c[2], c[3])
end
PaintBack(false)
back:SetScript("OnEnter", function() PaintBack(true) end)
back:SetScript("OnLeave", function() PaintBack(false) end)
back:SetScript("OnMouseDown", function() back.icon:SetPoint("LEFT", 10, -1) end)
back:SetScript("OnMouseUp", function() back.icon:SetPoint("LEFT", 9, 0) end)
back:SetScript("OnClick", function() P:Close(true) end)

P.launch = CreateFrame("Button", nil, S.main)
FGT.popoutLaunch = P.launch
P.launch:SetSize(20, 20)
P.launch:SetPoint("LEFT", U.header, "RIGHT", 4, 0)
Tip(P.launch, "Pop out steps")
FGT.IconButton(P.launch, "pop-out", 13)
P.launch:SetScript("OnClick", function()
    local goal = U.selected()
    if goal and U.active(goal) then P:Open(goal.id) end
end)
P.launch:Hide()
P.launch:SetParent(U.header:GetParent())

function FGT.HandlePopoutCommand(msg)
    local command = strtrim(msg or ""):lower()
    if command == "popout" then
        local goal = U.selected()
        if goal then P:Open(goal.id) end
    elseif command == "dock" then P:Close(true)
    elseif command == "popout reset" then P:ResetPosition()
    elseif command == "popout debug" then
        -- the main guide's empty slot: raw step height, visible area, height used
        local d = P.slotDebug or {}
        print(string.format("|cffffd75eForever Goal Tracker:|r slot raw %s, visible %s, used %s, short page %s",
            tostring(d.raw), tostring(d.visible and math.floor(d.visible + 0.5)), tostring(d.used), tostring(d.short)))
    else return false end
    return true
end

local events = CreateFrame("Frame")
P.events = events
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("GLOBAL_MOUSE_DOWN")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local saved = Saved()
        if not saved then return end
        local open, goal, locked, opacity, collapsed = saved.open, saved.goal, saved.locked, saved.opacity, saved.collapsed
        local shadowOpacity = saved.shadowOpacity
        P.autoFit, P.closeMain = saved.autoFit ~= false, saved.closeMain == true
        P.width, P.height = tonumber(saved.width) or 360, tonumber(saved.height) or 300
        P.left, P.top = tonumber(saved.left), tonumber(saved.top)
        P.goalId = goal
        P:Place()
        P:SetOpacity(opacity)
        P:SetShadowOpacity(shadowOpacity)
        P:SetLocked(locked)
        if open and goal then P:Open(goal, collapsed or false) end
    elseif event == "GLOBAL_MOUSE_DOWN" then
        if P.options:IsShown() and not P.options:IsMouseOver() and not P.settings:IsMouseOver() then P.options:Hide() end
        P:FocusClick()
    elseif event == "PLAYER_LOGOUT" then
        P:Save()
        P.driver:SetScript("OnUpdate", nil)
        P.bodyDriver:SetScript("OnUpdate", nil)
        P.sizeDriver:SetScript("OnUpdate", nil)
        P.fx:SetScript("OnUpdate", nil)
        P.header:SetScript("OnUpdate", nil)
        P.grip:SetScript("OnUpdate", nil)
    elseif P.frame then P:Place(); P:Save(); P:Refresh() end
end)

P:Stack()
P:Place()
P:SetOpacity(0.85)
P:SetShadowOpacity(0.3)
P:SetLocked(false)
frame:SetScript("OnMouseDown", function() if P.open then P:Raise() end end)
S.main:HookScript("OnShow", function() P:FocusMain() end)
S.main:HookScript("OnMouseDown", function() P:FocusMain() end)
