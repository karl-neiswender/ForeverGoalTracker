-- Goal Library preview: click a card and a drawer shows the whole goal (its banner, description,
-- steps and hints) before you add it. Same drawer as Materials and My Gear Sets: 280 wide, 0.7 s
-- slide, opens over the list when the window is too small to sit beside it. Read-only: nothing
-- here can tick a step (Karl chose the banner header on the mockup, 2026-11-09).
local ADDON, FGT = ...
local U, LF = FGT.MaterialsUI, FGT.libState
local C, STYLE = U.colors, U.styles
local library = FGT.libraryPanel
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local WIDTH, STRIP, GAP, SLIDE_TIME = 280, 22, 12, 0.7
local LIST_MIN, ART_H, PAD, FOOT_H = 420, 158, 14, 46
-- The banner fades out by itself, so whatever the panel looks like there shows through and always
-- matches. Each band: from and to (pixels down the banner), then its opacity at each end.
local WHITE = { 1, 1, 1 }
local ART_BANDS = { { 0, 24, 0.72, 0.72 }, { 24, 94, 0.72, 0.19 }, { 94, ART_H, 0.19, 0 } }

local P = { open = false, seen = false, canOpen = true, fraction = 0, width = WIDTH, goal = nil,
    hintsOpen = false, sliding = false, rows = {}, hints = {} }
FGT.LibraryPreview = P

-- ------------------------------------------------------------
-- The drawer
-- ------------------------------------------------------------
local clip = CreateFrame("Frame", nil, library)
P.clip = clip
clip:SetClipsChildren(true)
clip:SetFrameLevel(library:GetFrameLevel() + 30)
clip:Hide()

local panel = CreateFrame("Frame", nil, clip, "BackdropTemplate")
P.panel = panel
U.etch(panel, STYLE.panel, 12)
if FGT.AddGrime then FGT.AddGrime(panel, 0.18, 12, 0.61, 0, 140) end
panel:EnableMouse(true)

local body = CreateFrame("Frame", nil, panel)
P.body = body
body:SetAllPoints(panel)

local scroll = U.scroll(body)
P.scroll = scroll
scroll.scroll:SetPoint("TOPLEFT", body, "TOPLEFT", 3, -3)
scroll.scroll:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -3, FOOT_H)
scroll:Finalize()
scroll.trackHit:ClearAllPoints()
scroll.trackHit:SetPoint("TOP", scroll.scroll, "TOPRIGHT", -3, -4)
scroll.trackHit:SetPoint("BOTTOM", scroll.scroll, "BOTTOMRIGHT", -3, 4)
local content = scroll.content

-- A soft shadow on the list while the drawer lies over it.
local peek = CreateFrame("Frame", nil, library)
peek:SetFrameLevel(clip:GetFrameLevel() + 1)
peek:SetPoint("TOPRIGHT", clip, "TOPLEFT", 0, 0)
peek:SetPoint("BOTTOMRIGHT", clip, "BOTTOMLEFT", 0, 0)
peek:SetWidth(16)
local peekTex = peek:CreateTexture(nil, "OVERLAY")
peekTex:SetAllPoints()
peekTex:SetTexture("Interface\\Buttons\\WHITE8X8")
U.gradient(peekTex, { 0, 0, 0 }, { 0, 0, 0 }, 0, 0.55)
peek:Hide()

local handle = CreateFrame("Button", nil, library)
P.handle = handle
handle:SetFrameLevel(clip:GetFrameLevel() + 15)
handle:SetSize(24, 48)
FGT.IconButton(handle, "chevron-white", 10)
handle.icon:SetVertexColor(unpack(C.SUBTEXT))
handle.glow:SetVertexColor(unpack(C.SUBTEXT))
handle:SetScript("OnEnter", function(self)
    self.icon:SetVertexColor(unpack(C.ACCENT))
    self.glow:SetVertexColor(unpack(C.ACCENT))
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(P.canOpen and (P.open and "Hide preview" or "Show preview") or "Widen the window to show the preview")
    GameTooltip:Show()
end)
handle:SetScript("OnLeave", function(self)
    self.icon:SetVertexColor(unpack(C.SUBTEXT))
    self.glow:SetVertexColor(unpack(C.SUBTEXT))
    GameTooltip:Hide()
end)
handle:Hide()

-- Header: banner, icon, category, name, difficulty and time, description
local artBands = {}
P.artBands = artBands
for i, band in ipairs(ART_BANDS) do
    local tex = content:CreateTexture(nil, "ARTWORK", nil, 0)
    tex:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -band[1])
    tex:SetHeight(band[2] - band[1])
    artBands[i] = tex
end
local credit = U.font(content, 7, "", 0.48, 0.48, 0.48)
credit:SetPoint("TOPRIGHT", artBands[1], "TOPRIGHT", -8, -6)
credit:SetAlpha(0.6)

local icon = FGT.PopoutUI.icon(content, 48)
P.icon = icon
local category = U.font(content, 9, "", unpack(C.ACCENT))
category:SetJustifyH("LEFT")
category:SetWordWrap(false)
local name = U.title(content, 16)
P.name = name
name:SetJustifyH("LEFT")
name:SetWordWrap(true)

local function NewChip()
    local chip = CreateFrame("Frame", nil, content, "BackdropTemplate")
    U.etch(chip, STYLE.panel, 8)
    chip:SetHeight(19)
    chip.text = U.font(chip, 9, "", unpack(C.INK2))
    chip.text:SetPoint("CENTER", 0, 0)
    return chip
end
local chips = { NewChip(), NewChip() }

local note = U.font(content, 11, "", unpack(C.INK2))
P.note = note
note:SetJustifyH("LEFT")
note:SetWordWrap(true)
local foreverNote = U.font(content, 10, "", unpack(C.FOREVER))
foreverNote:SetJustifyH("LEFT")
foreverNote:SetWordWrap(true)

local function Hairline()
    local line = U.flat(content, 1, 0.92, 0.7, 0.08)
    line:SetHeight(1)
    return line
end
local line1, line2 = Hairline(), Hairline()
local listTitle = U.title(content, 13)
P.listTitle = listTitle
local listCount = U.font(content, 10, "", unpack(C.SUBTEXT))
P.listCount = listCount

-- Hints fold like the goal page's
local hintBtn = CreateFrame("Button", nil, content)
P.hintBtn = hintBtn
hintBtn:SetHeight(22)
hintBtn.glyph = hintBtn:CreateTexture(nil, "ARTWORK")
hintBtn.glyph:SetSize(10, 10)
hintBtn.glyph:SetPoint("LEFT", 0, 0)
hintBtn.label = U.title(hintBtn, 13)
hintBtn.label:SetPoint("LEFT", hintBtn.glyph, "RIGHT", 6, 0)
hintBtn.label:SetText("Hints")
hintBtn.count = U.font(hintBtn, 10, "", unpack(C.SUBTEXT))
hintBtn.count:SetPoint("LEFT", hintBtn.label, "RIGHT", 6, 0)
hintBtn:SetScript("OnEnter", function(self) self.label:SetTextColor(1, 1, 1) end)
hintBtn:SetScript("OnLeave", function(self) self.label:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
hintBtn:SetScript("OnClick", function() P.hintsOpen = not P.hintsOpen; P:Draw() end)

-- Footer: always in view, under the scrolling part
local footLine = U.flat(body, 1, 0.92, 0.7, 0.08)
footLine:SetHeight(1)
footLine:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 3, FOOT_H)
footLine:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -3, FOOT_H)

local function NewFootButton()
    local b = CreateFrame("Button", nil, body, "BackdropTemplate")
    b:SetHeight(28)
    U.etch(b, STYLE.button, 10)
    b.text = U.font(b, 11, "", unpack(C.TEXT))
    b.text:SetPoint("CENTER", 0, 0)
    function b:Style(hover)
        if self.gold then
            self:SetEtch(STYLE.rowSel)
            local c = hover and { 1, 1, 1 } or C.TITLE
            self.text:SetTextColor(c[1], c[2], c[3])
        else
            self:SetEtch(hover and STYLE.btnHover or STYLE.button)
            self.text:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
        end
    end
    b:SetScript("OnEnter", function(self) self:Style(true) end)
    b:SetScript("OnLeave", function(self) self:Style(false) end)
    b:SetScript("OnClick", function(self) if self.action then self.action() end end)
    return b
end
P.tryBtn, P.mainBtn, P.sideBtn = NewFootButton(), NewFootButton(), NewFootButton()
P.tryBtn.text:SetText("Try on")

-- ------------------------------------------------------------
-- What a goal lists
-- ------------------------------------------------------------
local function SectionDone(id, si, section)
    local done, total = 0, 0
    for pi, piece in ipairs(section.pieces or {}) do
        local d, t = FGT.PieceProgress(id, si, pi, piece)
        done, total = done + d, total + t
    end
    return total > 0 and done >= total
end

local function AddPieces(out, id, si, section)
    for pi, piece in ipairs(section.pieces or {}) do
        if not FGT.PieceSkipped(piece) then
            local d, t = FGT.PieceProgress(id, si, pi, piece)
            out[#out + 1] = { text = piece.text or piece.name, rule = piece.auto, entry = piece, done = t > 0 and d >= t, dot = true }
        end
    end
end

-- Rows for a goal, and the heading over them. Reads progress, never writes it.
local function Entries(goal)
    local out = {}
    if goal.partOf then
        local section = goal.partOf.sections[goal.partKey]
        AddPieces(out, goal.partOf.id, goal.partKey, section)
        return out, "Items to collect"
    end
    if goal.sections then
        if #goal.sections == 1 then
            AddPieces(out, goal.id, 1, goal.sections[1])
            return out, "Items to collect"
        end
        for _, part in ipairs(FGT.GroupParts(goal)) do
            out[#out + 1] = { text = part.label, done = SectionDone(goal.id, part.key, goal.sections[part.key]), dot = true }
        end
        return out, "What's included"
    end
    local shown = 0
    for i, entry in ipairs(goal.steps or {}) do
        if not FGT.PieceSkipped(entry) then
            shown = shown + 1
            local isTable = type(entry) == "table"
            out[#out + 1] = { text = isTable and entry.text or entry, rule = isTable and entry.auto or nil,
                entry = entry, done = FGT.StepFraction(goal, i) >= 1, number = shown }
        end
    end
    return out, "Steps"
end

local function Hex(c)
    return string.format("%02x%02x%02x", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function CategoryLine(goal)
    local rgb = FGT.categoryColors[goal.category] or C.ACCENT
    local _, tier = LF.Tier(goal)
    local text = goal.partLabel and string.upper(goal.partLabel)
        or tier and (string.upper(tier) .. "  ·  " .. FGT.ArmorClassLabel(goal.armorClass) .. "|cff" .. Hex(rgb))
        or string.upper(goal.category or "")
    if goal.faction then text = text .. "  ·  " .. string.upper(goal.faction) .. " ONLY" end
    return text, rgb
end

local function GetRow(pool, i, size, color)
    local row = pool[i]
    if not row then
        -- a Button: FGT.EnableGoalLinks asks its row for an OnClick (it has none, so no link can tick anything)
        row = CreateFrame("Button", nil, content)
        row.text = U.font(row, size, "", unpack(color))
        row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 22, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(true)
        FGT.Shimmer(row.text) -- goal links in the text shine
        row.num = U.font(row, size, "", unpack(C.GOLD2))
        row.num:SetPoint("TOPRIGHT", row, "TOPLEFT", 16, 0)
        row.num:SetJustifyH("RIGHT")
        row.check = row:CreateTexture(nil, "ARTWORK")
        row.check:SetTexture(FGT.Icon("check-white"))
        row.check:SetVertexColor(C.DONE[1], C.DONE[2], C.DONE[3])
        row.check:SetSize(12, 12)
        row.check:SetPoint("TOPRIGHT", row, "TOPLEFT", 16, 0)
        row.dot = U.flat(row, C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 0.9)
        row.dot:SetSize(4, 4)
        row.dot:SetRotation(math.rad(45))
        row.dot:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -5)
        FGT.EnableGoalLinks(row)
        pool[i] = row
    end
    return row
end

-- Draw the open goal. newGoal: it just changed, so start back at the top.
function P:Draw(newGoal)
    local goal = self.goal
    if not goal then return end
    local source = goal.partOf or goal
    local w = self.width - 6
    local inner = w - PAD * 2

    -- the goal page's banner for this character, cropped to the drawer's 16:9 slot
    local B, path, aspect, preprocessed = FGT.goalBanner, nil, nil, nil
    if B and B.ResolveArt then path, aspect, preprocessed = B:ResolveArt(source.id) end
    local hasArt = path ~= nil
    for _, tex in ipairs(artBands) do tex:SetShown(hasArt) end
    credit:SetText("")
    local y = PAD
    if hasArt then
        local fullH = w / (aspect or 1)
        local inset = fullH > ART_H and (1 - ART_H / fullH) / 2 or 0
        local span = 1 - inset * 2
        for i, tex in ipairs(artBands) do
            local band = ART_BANDS[i]
            tex:SetTexture(MEDIA .. path)
            tex:SetDesaturated(not preprocessed)
            tex:SetWidth(w)
            tex:SetTexCoord(0, 1, inset + span * band[1] / ART_H, inset + span * band[2] / ART_H)
            FGT.PopoutUI.vgradient(tex, WHITE, WHITE, band[3], band[4])
        end
        local artist = B.artArtists and B.artArtists[path]
        if artist then
            credit:SetText((path == "set_tier1_rogue-alliance-banner.blp" and "Art by " or "Artwork by ") .. artist)
        end
        y = ART_H - 52
    end

    -- icon and title, sharing a bottom edge
    local textW = inner - 48 - 10
    local catText, catRgb = CategoryLine(goal)
    category:SetWidth(textW)
    category:SetText(catText)
    category:SetTextColor(catRgb[1], catRgb[2], catRgb[3])
    name:SetWidth(textW)
    name:SetText(goal.name)
    local titleH = (category:GetStringHeight() or 10) + 3 + (name:GetStringHeight() or 18)
    local headH = math.max(48, titleH)
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -(y + headH - 48))
    icon:SetIcon(FGT.GoalIcon(goal), catRgb)
    category:ClearAllPoints()
    category:SetPoint("TOPLEFT", content, "TOPLEFT", PAD + 58, -(y + headH - titleH))
    name:ClearAllPoints()
    name:SetPoint("TOPLEFT", category, "BOTTOMLEFT", 0, -3)
    y = y + headH + 9

    local x = PAD
    for i, label in ipairs({ goal.difficulty or false, goal.timeEstimate or false }) do
        local chip = chips[i]
        chip:SetShown(label and true or false)
        if label then
            chip.text:SetText(label)
            chip:SetWidth(math.ceil(chip.text:GetStringWidth() or 30) + 16)
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
            x = x + chip:GetWidth() + 5
        end
    end
    if goal.difficulty or goal.timeEstimate then y = y + 19 + 9 end

    local noteText = goal.note or source.note
    note:SetShown(noteText ~= nil)
    if noteText then
        note:ClearAllPoints()
        note:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -y)
        note:SetWidth(inner)
        note:SetText(noteText)
        y = y + (note:GetStringHeight() or 14) + 8
    end
    local fnote = FGT.ForeverNote(source, true)
    foreverNote:SetShown(fnote ~= nil)
    if fnote then
        foreverNote:ClearAllPoints()
        foreverNote:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -y)
        foreverNote:SetWidth(inner)
        foreverNote:SetText(fnote)
        y = y + (foreverNote:GetStringHeight() or 13) + 8
    end

    line1:ClearAllPoints()
    line1:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -(y + 3))
    line1:SetWidth(inner)
    y = y + 12

    -- the list: numbers for steps, diamonds for items and parts, a green check once done
    local entries, heading = Entries(goal)
    local doneCount = 0
    for _, e in ipairs(entries) do if e.done then doneCount = doneCount + 1 end end
    listTitle:ClearAllPoints()
    listTitle:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -y)
    listTitle:SetText(heading)
    listCount:ClearAllPoints()
    listCount:SetPoint("BOTTOMLEFT", listTitle, "BOTTOMRIGHT", 8, 0)
    listCount:SetText(doneCount .. " / " .. #entries)
    y = y + 22

    local rim, quality = FGT.stepRim, FGT.stepQuality
    FGT.stepQuality = source.itemQuality -- item name color when the game doesn't know
    for i, e in ipairs(entries) do
        local row = GetRow(self.rows, i, 11, C.TEXT)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", PAD - 4, -y)
        row:SetWidth(inner + 4)
        row:SetAlpha(e.done and 0.55 or 1)
        row.text:SetWidth(inner + 4 - 22)
        row.text:SetText(FGT.StepText(e.text))
        FGT.SetStepLinks(row, e.rule, e.entry)
        row.check:SetShown(e.done)
        row.dot:SetShown(e.dot and not e.done or false)
        row.num:SetText((e.number and not e.done) and (e.number .. ".") or "")
        local h = (row.text:GetStringHeight() or 14) + 7
        row:SetHeight(h)
        row:Show()
        y = y + h
    end
    FGT.stepRim, FGT.stepQuality = rim, quality
    for i = #entries + 1, #self.rows do self.rows[i]:Hide() end

    -- hints
    local tips = source.tips or {}
    local showHints = #tips > 0
    line2:SetShown(showHints)
    hintBtn:SetShown(showHints)
    local tipsShown = 0
    if showHints then
        line2:ClearAllPoints()
        line2:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -(y + 3))
        line2:SetWidth(inner)
        y = y + 9
        hintBtn:ClearAllPoints()
        hintBtn:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -y)
        hintBtn:SetWidth(inner)
        hintBtn.glyph:SetTexture(FGT.Icon(self.hintsOpen and "minus" or "plus"))
        hintBtn.count:SetText("(" .. #tips .. ")")
        y = y + 26
        if self.hintsOpen then
            for i, tip in ipairs(tips) do
                local row = GetRow(self.hints, i, 10, C.INK2)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", content, "TOPLEFT", PAD - 4, -y)
                row:SetWidth(inner + 4)
                row.text:SetWidth(inner + 4 - 22)
                row.text:SetText(FGT.LinkText(tip))
                row.check:Hide(); row.num:SetText(""); row.dot:Show()
                local h = (row.text:GetStringHeight() or 13) + 7
                row:SetHeight(h)
                row:Show()
                y = y + h
                tipsShown = i
            end
        end
    end
    for i = tipsShown + 1, #self.hints do self.hints[i]:Hide() end

    content:SetWidth(w)
    content:SetHeight(y + 12)
    if newGoal then scroll.scroll:SetVerticalScroll(0) end
    scroll:Update()
    self:DrawFooter()
end

-- What the Add button means for this goal: mirrors the card's own button.
function P:DrawFooter()
    local goal = self.goal
    local partial, added, addLabel, removeLabel = false, false, "+ Add to My Goals", "Remove"
    if goal.group then
        local n, total = FGT.SelectedPartCount(goal), #FGT.GroupParts(goal)
        added, partial = n == total, n > 0 and n < total
        addLabel, removeLabel = partial and "+ Add rest" or "+ Add all to My Goals", "Remove all"
    else
        added = LF.On(goal)
    end
    local function Toggle() LF.ToggleGoal(goal) end
    local function Open() P:OpenGoal() end

    local main, side, try = self.mainBtn, self.sideBtn, self.tryBtn
    local canTry = FGT.SetPreviewIds(goal) and true or false
    if added then
        main.gold, main.action = false, Open
        main.text:SetText("Open goal")
        side.action = Toggle
        side.text:SetText(removeLabel)
    else
        main.gold, main.action = true, Toggle
        main.text:SetText(addLabel)
        side.action = partial and Open or nil
        side.text:SetText("Open goal")
    end
    local showSide = added or partial
    try:SetShown(canTry); side:SetShown(showSide)
    try.action = canTry and function() FGT.TrySetOn(goal) end or nil
    local SIDE_W, left, right = 72, PAD, PAD
    if canTry then
        try:ClearAllPoints()
        try:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", left, 9)
        try:SetWidth(SIDE_W - 8)
        left = left + SIDE_W - 8 + 6
    end
    if showSide then
        side:ClearAllPoints()
        side:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -right, 9)
        side:SetWidth(SIDE_W)
        right = right + SIDE_W + 6
    end
    main:ClearAllPoints()
    main:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", left, 9)
    main:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -right, 9)
    for _, b in ipairs({ main, side, try }) do b:Style(b:IsMouseOver()) end
end

function P:OpenGoal()
    local goal, target = self.goal, nil
    if goal.partOf then
        target = goal.partOf
    elseif goal.armorChildren then
        for _, part in ipairs(FGT.GroupParts(goal)) do
            if FGT.PartSelected(goal, part.key) then target = goal.armorChildren[part.key]; break end
        end
    else
        target = goal
    end
    if not target then return end
    FGT.ShowTab("tracker")
    FGT.SelectGoal(target.id)
end

-- ------------------------------------------------------------
-- Opening and closing
-- ------------------------------------------------------------
function P:Place()
    local main = U.main
    local area = math.max(0, main:GetWidth() - U.list:GetWidth() - 44)
    self.width = math.min(WIDTH, math.max(STRIP, area - 60))
    self.canOpen = self.width >= 150
    self.overlay = area - GAP - self.width < LIST_MIN
    if not self.canOpen then self.open = false; self.fraction = 0 end

    local span = self.seen and (STRIP + (self.width - STRIP) * self.fraction) or 0
    local listSpan = self.seen and (STRIP + (self.width - STRIP) * (self.overlay and 0 or self.fraction)) or 0
    local right = -16 - (self.seen and (listSpan + GAP) or 0)
    if right ~= self.listRight then
        self.listRight = right
        library:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", right, 16)
    end

    clip:ClearAllPoints()
    clip:SetPoint("TOPRIGHT", U.list, "TOPRIGHT", main:GetWidth() - U.list:GetWidth() - 32, 0)
    clip:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -16, 16)
    clip:SetWidth(math.max(1, span))
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", clip, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMLEFT", clip, "BOTTOMLEFT", 0, 0)
    panel:SetWidth(self.width)

    handle:ClearAllPoints()
    handle:SetPoint("CENTER", clip, "LEFT", -6, 0)
    -- (the source glyph points down)
    local rotation = self.open and math.pi / 2 or -math.pi / 2
    handle.icon:SetRotation(rotation)
    handle.glow:SetRotation(rotation)
    clip:SetShown(self.seen)
    handle:SetShown(self.seen)
    body:SetShown(self.fraction > 0)
    body:SetAlpha(self.fraction) -- banner, text and buttons fade with the slide
    panel:EnableMouse(self.open)
    peek:SetShown(self.seen and self.overlay and self.fraction > 0)
end

local driver = CreateFrame("Frame", nil, library)
local function FinishSlide()
    driver:SetScript("OnUpdate", nil)
    P.sliding = false
    FGT.railBusy = false
    if library:IsShown() then FGT.LayoutLibrary() end
end

function P:SetOpen(open)
    driver:SetScript("OnUpdate", nil)
    GameTooltip:Hide()
    self.open = open and self.canOpen or false
    local start, target = self.fraction, self.open and 1 or 0
    if FGT.Setting("celebrations") == "off" then
        self.fraction = target
        self:Place()
        FinishSlide()
        return
    end
    local elapsed = 0
    self.sliding = true
    FGT.railBusy = true
    driver:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local p = math.min(1, elapsed / SLIDE_TIME)
        P.fraction = start + (target - start) * (1 - (1 - p) ^ 3)
        P:Place()
        if p >= 1 then FinishSlide() end
    end)
end

function P:IsSelected(goal) return self.open and self.goal == goal end

-- A click on a Library card. The same card again closes the drawer; another swaps it in place.
function P:CardClick(goal)
    self:Place()
    if not self.canOpen then return end
    GameTooltip:Hide()
    if self.open and self.goal == goal then
        self:SetOpen(false)
        LF.PaintSelection()
        return
    end
    self.goal, self.hintsOpen, self.seen = goal, false, true
    self:Place()
    self:Draw(true)
    if not self.open then self:SetOpen(true) end
    LF.PaintSelection()
end

-- After the Library redraws (filters, adding a goal, a resized window).
function P:Refresh()
    LF.PaintSelection()
    if self.goal and self.open and not self.sliding then
        self:Place()
        self:Draw()
    end
end

handle:SetScript("OnClick", function()
    P:SetOpen(not P.open)
    LF.PaintSelection()
end)
U.main:HookScript("OnSizeChanged", function() if library:IsShown() then P:Place() end end)
library:HookScript("OnShow", function() P:Place() end)
library:HookScript("OnHide", function()
    driver:SetScript("OnUpdate", nil)
    if P.sliding then
        P.sliding, FGT.railBusy = false, false
        P.fraction = P.open and 1 or 0
    end
end)

-- An item the game had not sent yet: redraw once its name and color arrive.
local events = CreateFrame("Frame")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
local queued = false
events:SetScript("OnEvent", function()
    if queued or not (P.open and P.goal and library:IsVisible()) then return end
    queued = true
    C_Timer.After(0.2, function()
        queued = false
        if P.open and P.goal and library:IsVisible() and not P.sliding then P:Draw() end
    end)
end)
