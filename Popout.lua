local ADDON, FGT = ...
local U, S = FGT.PopoutUI, FGT.MaterialsUI
local C = S.colors
local P = { open = false, rows = {}, headers = {}, fraction = 1, width = 360, height = 300,
    autoFit = true, closeMain = false, shadowOpacity = 0.3, mainLevel = S.main:GetFrameLevel() }
FGT.Popout = P

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
local function Surface(parent, r, g, b, alpha)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetColorTexture(r, g, b, alpha)
    return t
end
local function Tip(button, text)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(text, C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

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

function P:Raise()
    S.main:SetFrameLevel(self.mainLevel)
    self.frame:SetFrameStrata("HIGH")
    self.frame:SetFrameLevel(self.mainLevel + 100)
    self.shadow:SetFrameStrata("HIGH")
    self.shadow:SetFrameLevel(self.mainLevel + 99)
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

function P:Place(offset)
    if not self.frame then return end
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
    self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.left, -self.top + (offset or 0))
    self.frame:SetSize(self.width, self.collapsed and 32 or self.height)
    self.scroll.scroll:ClearAllPoints()
    self.scroll.scroll:SetPoint("TOPLEFT", 12, -42)
    self.scroll.scroll:SetSize(math.max(50, self.width - 36), math.max(1, self.height - 58))
    self.content:SetWidth(math.max(50, self.width - 36))
    self.scroll:Update()
    self.shadow:SetScale(scale)
    self.scroll.scroll:SetShown(not self.collapsed)
    self.grip:SetShown(not self.locked and not self.collapsed)
    if self.collapsed then
        self.scroll.trackHit:Hide()
        self.scroll.fadeTop:Hide()
        self.scroll.fadeBottom:SetScript("OnUpdate", nil)
        self.scroll.fadeBottom:Hide()
        self.complete:Hide()
    end
end

function P:SetOpacity(value)
    self.opacity = Clamp(tonumber(value) or 0.85, 0, 1)
    local style = S.styles.panel
    U.vgradient(self.chrome.etchBg, style.top, style.bottom, self.opacity, self.opacity)
    self.chrome:SetBackdropBorderColor(style.edge[1], style.edge[2], style.edge[3], self.opacity)
    self.chrome.etchHi:SetVertexColor(1, 0.92, 0.70, 0.07 * self.opacity)
    local grime = self.chrome.grimeParts
    grime[1]:SetVertexColor(1, 1, 1, 0.18 * self.opacity)
    U.vgradient(grime[2], {1,1,1}, {1,1,1}, 0.18 * self.opacity, 0.07 * self.opacity)
    grime[3]:SetVertexColor(1, 1, 1, 0.07 * self.opacity)
    for _, fade in ipairs({self.scroll.fadeTop, self.scroll.fadeBottom}) do
        local color = fade.stripColor
        for i, strip in ipairs(fade.strips) do
            strip:SetVertexColor(color[1], color[2], color[3], fade.stripAlphas[i] * self.opacity)
        end
    end
    if self.opacityText then self.opacityText:SetText(math.floor(self.opacity * 100 + 0.5) .. "%") end
    self:Save()
end

function P:SetShadowOpacity(value)
    self.shadowOpacity = Clamp(tonumber(value) or 0.3, 0, 1)
    self.shadow:SetAlpha(self.shadowOpacity * self.fraction)
    self.shadowText:SetText(math.floor(self.shadowOpacity * 100 + 0.5) .. "%")
    self:Save()
end

function P:FitSteps()
    if not self.open or self.collapsed or self.fitting then return end
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
    local screenH = UIParent:GetHeight()
    if screenH <= 0 then screenH = GetScreenHeight() end
    screenH = screenH / (FGT.windowScale or 1)
    self.height = Clamp(math.ceil(self.layout.height + 58), 80, math.max(80, screenH * 0.7))
    self:Place()
    self:Save()
    self.fitting = nil
end

function P:SetLocked(locked)
    self.locked = locked and true or false
    self.header:SetScript("OnUpdate", nil)
    self.grip:SetScript("OnUpdate", nil)
    self.grip:SetShown(not self.locked and not self.collapsed)
    self.lockText:SetText(self.locked and "Unlock position" or "Lock position")
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
    local mode = FGT.Setting("celebrations")
    local from, target, elapsed = self.fraction, show and 1 or 0, 0
    local function Paint(t)
        self.fraction = from + (target - from) * t
        self.frame:SetAlpha(self.fraction)
        self.shadow:SetAlpha(self.shadowOpacity * self.fraction)
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
        Paint(show and (1 - (1 - t)^3) or (t * t * (3 - 2 * t)))
        if t == 1 then
            self.driver:SetScript("OnUpdate", nil)
            if done then done() end
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
    local section = self.singleSection and goal.sections[self.singleSection]
    self.title:SetText((section and section.name or goal.name) .. (total > 0 and done >= total and " · Complete" or ""))
    self.headerCount:SetText(done .. " / " .. total)
    self.headerIcon:SetIcon(FGT.GoalIcon(goal), FGT.ForeverWord(goal) and C.FOREVER or C.GOLD2)
    FGT.SetPlusMinus(self.arrow, not self.collapsed)
    self.completedButton.text:SetText(FGT.Setting("hideCompletedSteps") and "Show completed steps" or "Hide completed steps")
    self.groupsButton:SetShown(goal.sections ~= nil)
    self.autoFitButton.text:SetText("Auto-fit on opening: " .. (self.autoFit and "On" or "Off"))
    self.closeMainButton.text:SetText("Close main on pop-out: " .. (self.closeMain and "On" or "Off"))
    self.progress = total > 0 and done / total or 0
    local color = total > 0 and done >= total and C.DONE or (FGT.ForeverWord(goal) and C.FOREVER or C.ACCENT)
    self.fill:SetColorTexture(color[1], color[2], color[3], 1)
    self.fill:SetWidth(math.max(0.1, (self.width - 2) * self.progress))
    self.complete:SetShown(total > 0 and done >= total and #self.layout.nodes == 0)
    self.countText = done .. " / " .. total
    self:Place()
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
    self.options:Hide()
    self.slotHeight, self.slotWidth, self.layout, self.hidePending = nil, nil, nil, nil
    self.skipPrevious = nil
    self.singleSection, self.collapsed, self.restoreCollapsed = nil, false, collapsed
    self.goalId, self.open, self.closing = id, true, nil
    self.slotId = id
    self.scroll.scroll:SetVerticalScroll(0)
    self.fraction = fraction
    self:Place()
    self:Raise()
    self.frame:SetAlpha(self.fraction)
    self.shadow:SetAlpha(self.shadowOpacity * self.fraction)
    self.frame:Show()
    self:Refresh()
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
        S.main:SetFrameLevel(self.mainLevel)
        self:Place()
        self.placeholder:Hide()
        U.redraw()
    end)
end

-- Keep Tips at their original position. A width change remeasures the
-- slot; ticks and recipe expansion in the pop-out do not collapse it.
function FGT.PopoutStepHeight(goal, height, width)
    if (P.open or P.closing) and P.slotId == goal.id then
        if not P.slotHeight or P.slotWidth ~= width then P.slotHeight, P.slotWidth = height, width end
        return P.slotHeight
    end
    return height
end

function P:PaintPlaceholder()
    local selected = U.selected()
    local active = (self.open or self.closing) and selected and selected.id == self.slotId
    self.placeholder:SetShown(active and true or false)
    if not active then return end
    self.placeholder:SetAlpha(self.fraction)
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
    P.placeholder:SetSize(math.max(50, width), math.max(36, height - 6))
    P.placeholder.text:ClearAllPoints()
    P.placeholder.text:SetPoint("TOP", 0, -math.min(60, math.max(12, height * 0.25)))
    P:PaintPlaceholder()
    local active = (P.open or P.closing) and goal.id == P.slotId
    if active then FGT.completedStepsBtn:Hide(); FGT.expandAllBtn:Hide() end
    P.launch:SetShown(U.active(goal) and not active)
    if not active then FGT.LayoutStepControls() end
end

function FGT.HidePopoutGuide()
    P.launch:Hide()
    P.placeholder:Hide()
    P.mainRows = nil
end

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

P.header = CreateFrame("Frame", nil, frame)
P.header:SetPoint("TOPLEFT", 3, -2)
P.header:SetPoint("TOPRIGHT", -3, -2)
P.header:SetHeight(25)
P.header:EnableMouse(true)
P.arrow = Label(P.header, 10, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
P.arrow:SetWidth(10)
P.arrow:SetPoint("LEFT", 5, 0)
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
P.title = S.title(P.header, 13)
P.title:SetText("")
P.title:SetPoint("LEFT", P.headerIcon, "RIGHT", 7, 0)
P.title:SetPoint("RIGHT", -128, 0)
P.title:SetWordWrap(false)
P.title:SetJustifyH("LEFT")
P.headerCount = Label(P.header, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
P.headerCount:SetPoint("RIGHT", -77, 0)
P.headerCount:SetWidth(44)
P.headerCount:SetJustifyH("RIGHT")

local function HeaderButton(offset, hint, action, icon)
    local b = CreateFrame("Button", nil, P.header)
    b:SetSize(22, 24)
    b:SetPoint("RIGHT", offset, 0)
    Tip(b, hint)
    b:SetScript("OnClick", action)
    if icon then FGT.IconButton(b, icon, 13) end
    return b
end
P.close = HeaderButton(-1, "Close pop-out", function() P:Close(false) end, "close")
P.settings = HeaderButton(-24, "Pop-out settings", function() P.options:SetShown(not P.options:IsShown()) end, "gear")
P.dock = HeaderButton(-47, "Bring back to main window", function() P:Close(true) end, "dock")

P.bar = CreateFrame("Frame", nil, frame)
P.bar:SetPoint("TOPLEFT", 1, -28)
P.bar:SetPoint("TOPRIGHT", -1, -28)
P.bar:SetHeight(3)
P.bar:EnableMouse(false)
P.fill = Surface(P.bar, C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
P.fill:SetPoint("TOPLEFT"); P.fill:SetHeight(3)

P.scroll = S.scroll(frame)
P.scroll.scroll:SetPoint("TOPLEFT", 12, -42)
P.scroll.scroll:SetPoint("BOTTOMRIGHT", -24, 16)
P.content = P.scroll.content
P.scroll:Finalize()
FGT.EnableGoalLinks(P.content)
P.complete = Label(frame, 12, "Complete", C.DONE[1], C.DONE[2], C.DONE[3])
P.complete:SetPoint("TOPLEFT", 14, -45)
P.complete:Hide()
P.measure = Label(frame, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
P.measure:SetWidth(10000)
P.measure:SetWordWrap(false)
P.measure:Hide()

P.grip = CreateFrame("Button", nil, frame)
P.grip:SetSize(18, 18)
P.grip:SetPoint("BOTTOMRIGHT", -2, 2)
P.grip.text = Label(P.grip, 12, "//", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
P.grip.text:SetPoint("CENTER")
Tip(P.grip, "Drag to resize")

local function StopMotion(handle)
    handle:SetScript("OnUpdate", nil)
    if handle == P.grip then P:Refresh() end
    P:Save()
end
local function StartMotion(handle, resize)
    if P.locked or not P.open then return end
    P.driver:SetScript("OnUpdate", nil)
    P.fraction = 1; frame:SetAlpha(1); P.shadow:SetAlpha(P.shadowOpacity); P:Place(); P:PaintPlaceholder()
    local x, y = GetCursorPosition()
    local left, top, width, height = P.left, P.top, P.width, P.height
    local scale = math.max(0.1, frame:GetEffectiveScale())
    local elapsed = 0
    handle.moved = false
    handle:SetScript("OnUpdate", function(self, dt)
        if not IsMouseButtonDown("LeftButton") then StopMotion(self); return end
        local cx, cy = GetCursorPosition()
        if math.abs(cx-x) + math.abs(cy-y) >= 4 * scale then self.moved = true end
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
P.grip:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" then StartMotion(self, true) end end)
P.grip:SetScript("OnMouseUp", function(self) StopMotion(self); P:Refresh() end)
P.grip:SetScript("OnHide", function(self) StopMotion(self) end)
P.driver = CreateFrame("Frame", nil, frame)
frame:HookScript("OnHide", function() P.driver:SetScript("OnUpdate", nil) end)

P.options = CreateFrame("Frame", nil, frame, "BackdropTemplate")
P.options:SetFrameLevel(frame:GetFrameLevel() + 60)
P.options:SetSize(260, 280)
P.options:SetClampedToScreen(true)
P.options:SetPoint("TOPRIGHT", P.header, "BOTTOMRIGHT", 0, -5)
P.options.fgtOwn = true
P.options:EnableMouse(true)
P.options:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8})
P.options:SetBackdropColor(0.035, 0.03, 0.025, 0.98)
P.options:SetBackdropBorderColor(0.4, 0.32, 0.18, 1)
P.options:Hide()
local function Option(y, label, action)
    local b = CreateFrame("Button", nil, P.options)
    b:SetPoint("TOPLEFT", 12, -y); b:SetPoint("TOPRIGHT", -12, -y); b:SetHeight(20)
    b.text = Label(b, 11, label, C.TEXT[1], C.TEXT[2], C.TEXT[3])
    b.text:SetPoint("LEFT")
    b:SetScript("OnClick", action)
    b:SetScript("OnEnter", function(self) self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
    b:SetScript("OnLeave", function(self) self.text:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3]) end)
    return b
end
P.lockButton = Option(10, "Lock position", function() P:SetLocked(not P.locked) end)
P.lockText = P.lockButton.text
Option(34, "Reset position", function() P:ResetPosition(); P.options:Hide() end)
P.completedButton = Option(58, "Show / hide completed steps", function()
    FGT.SetSetting("hideCompletedSteps", not FGT.Setting("hideCompletedSteps")); U.redraw(); P:Refresh()
end)
P.groupsButton = Option(82, "Expand / collapse groups", function()
    local goal = FGT.GoalById(P.goalId)
    if not goal or not goal.sections then return end
    local expand = false
    for si in ipairs(goal.sections) do if FGT.PartSelected(goal, si) and not FGT.SectionIsOpen(goal, si) then expand = true end end
    for si in ipairs(goal.sections) do if FGT.PartSelected(goal, si) then FGT.sectionOpen[goal.id .. "_" .. si] = expand end end
    P:Refresh()
end)
Option(110, "Fit to steps now", function() P:FitSteps(); P.options:Hide() end)
P.autoFitButton = Option(134, "Auto-fit on opening: On", function()
    P.autoFit = not P.autoFit
    if P.autoFit then P:FitSteps() end
    P:Refresh(); P:Save()
end)
Tip(P.autoFitButton, "Resizing keeps your chosen size and turns this off.")
P.closeMainButton = Option(158, "Close main on pop-out: Off", function()
    P.closeMain = not P.closeMain; P:Refresh(); P:Save()
end)
local opacityLabel = Label(P.options, 10, "Background opacity", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
opacityLabel:SetPoint("TOPLEFT", 12, -185)
P.opacityText = Label(P.options, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
P.opacityText:SetPoint("TOPRIGHT", -12, -185)
P.slider = CreateFrame("Slider", nil, P.options)
P.slider:SetPoint("TOPLEFT", 12, -211); P.slider:SetPoint("TOPRIGHT", -12, -211); P.slider:SetHeight(12)
P.slider:SetOrientation("HORIZONTAL"); P.slider:SetMinMaxValues(0, 100)
P.slider:SetValueStep(1); P.slider:SetObeyStepOnDrag(true)
local rail = Surface(P.slider, 0.2, 0.17, 0.12, 1)
rail:SetPoint("LEFT"); rail:SetPoint("RIGHT"); rail:SetHeight(2)
local thumb = P.slider:CreateTexture(nil, "ARTWORK")
thumb:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\knob")
thumb:SetSize(12, 12)
P.slider:SetThumbTexture(thumb)
P.slider:SetScript("OnValueChanged", function(_, value) P:SetOpacity(value / 100) end)
local shadowLabel = Label(P.options, 10, "Drop shadow opacity", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
shadowLabel:SetPoint("TOPLEFT", 12, -237)
P.shadowText = Label(P.options, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
P.shadowText:SetPoint("TOPRIGHT", -12, -237)
P.shadowSlider = CreateFrame("Slider", nil, P.options)
P.shadowSlider:SetPoint("TOPLEFT", 12, -259); P.shadowSlider:SetPoint("TOPRIGHT", -12, -259)
P.shadowSlider:SetHeight(12)
P.shadowSlider:SetOrientation("HORIZONTAL"); P.shadowSlider:SetMinMaxValues(0, 100)
P.shadowSlider:SetValueStep(1); P.shadowSlider:SetObeyStepOnDrag(true)
local shadowRail = Surface(P.shadowSlider, 0.2, 0.17, 0.12, 1)
shadowRail:SetPoint("LEFT"); shadowRail:SetPoint("RIGHT"); shadowRail:SetHeight(2)
local shadowThumb = P.shadowSlider:CreateTexture(nil, "ARTWORK")
shadowThumb:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\knob")
shadowThumb:SetSize(12, 12); P.shadowSlider:SetThumbTexture(shadowThumb)
P.shadowSlider:SetScript("OnValueChanged", function(_, value) P:SetShadowOpacity(value / 100) end)

P.placeholder = CreateFrame("Frame", nil, U.content)
P.placeholder.fgtPopoutTransfer = true
P.placeholder:SetPoint("TOPLEFT")
P.placeholder:EnableMouse(false)
P.placeholder:Hide()
local recess = Surface(P.placeholder, 0, 0, 0, 0.22)
recess:SetAllPoints()
-- Plain alpha strips rather than gradient textures, so frame fading works.
for i = 1, 10 do
    for _, edge in ipairs({"TOP", "LEFT", "BOTTOM", "RIGHT"}) do
        local shadow = Surface(P.placeholder, 0, 0, 0, (1 - i/11) * (edge == "TOP" and 0.42 or 0.24))
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
P.placeholder.text = Label(P.placeholder, 12, "Steps are popped out", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
P.placeholder.text:SetPoint("CENTER", 0, 13)
P.placeholder.back = CreateFrame("Button", nil, P.placeholder)
P.placeholder.back:SetSize(110, 24); P.placeholder.back:SetPoint("CENTER", 0, -13)
P.placeholder.back:ClearAllPoints()
P.placeholder.back:SetPoint("TOP", P.placeholder.text, "BOTTOM", 0, -6)
P.placeholder.back.text = Label(P.placeholder.back, 11, "Bring back", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
P.placeholder.back.text:SetPoint("CENTER")
P.placeholder.back:SetScript("OnClick", function() P:Close(true) end)

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
        P.slider:SetValue(P.opacity * 100)
        P.shadowSlider:SetValue(P.shadowOpacity * 100)
        P:SetLocked(locked)
        if open and goal then P:Open(goal, collapsed or false) end
    elseif event == "GLOBAL_MOUSE_DOWN" then
        if P.options:IsShown() and not P.options:IsMouseOver() and not P.settings:IsMouseOver() then P.options:Hide() end
        P:FocusClick()
    elseif event == "PLAYER_LOGOUT" then
        P:Save()
        P.driver:SetScript("OnUpdate", nil)
        P.header:SetScript("OnUpdate", nil)
        P.grip:SetScript("OnUpdate", nil)
    elseif P.frame then P:Place(); P:Save(); P:Refresh() end
end)

P:Place()
P:SetOpacity(0.85)
P:SetShadowOpacity(0.3)
P:SetLocked(false)
frame:SetScript("OnMouseDown", function() if P.open then P:Raise() end end)
S.main:HookScript("OnShow", function() P:FocusMain() end)
S.main:HookScript("OnMouseDown", function() P:FocusMain() end)
