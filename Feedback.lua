local ADDON, FGT = ...
local U = FGT.MaterialsUI
local T = FGT.titleBarUI
local C = U.colors
local STYLE = U.styles

-- Send feedback: a bug, a goal request or an idea about this addon.
--
-- A game addon can't reach the internet or the clipboard, so the window builds
-- a link with the report already filled in (FGT.Feedback.URL); the player copies
-- it with Ctrl+C and pastes it into a browser. Only the link needs to change
-- if the form moves (see ENDPOINT).
local F = {}
FGT.Feedback = F

-- The form: Karl's Google Form "Forever Goal Tracker feedback" (no account needed).
-- Each answer is pre-filled by its entry number, read from the form on 2026-11-03;
-- a question added or replaced in the form gets a new number.
local ENDPOINT = {
    base = "https://docs.google.com/forms/d/e/1FAIpQLScQ1LAmSwELPvHvnB--CkHbEmEX7XDt3NzMvHvm6MQIluiEbw/viewform?usp=pp_url",
    kind = "entry.445946191", what = "entry.2062669808", details = "entry.332375755",
}
local MAX_TEXT = 600 -- characters the player can write
local MAX_URL = 4000 -- Google refuses very long links (12,000 characters failed)

local KINDS = {
    { key = "bug", label = "Bug", form = "Bug",
      hint = "For example: Catching the One Ring while fishing didn't count my fish." },
    { key = "goal", label = "Goal request", form = "Goal request",
      hint = "For example: Please add a goal for the Black War Tiger.\nShift-click an item to add it here." },
    { key = "idea", label = "Idea", form = "Idea",
      hint = "For example: Let me sort my goals by how close they are to done." },
}

-- ------------------------------------------------------------
-- What the addon knows (never your character's name or realm)
-- ------------------------------------------------------------
local function Plain(s)
    s = tostring(s or "")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|H.-|h(.-)|h", "%1")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- an item or quest link as readable text with its id: "[Name] (item 123)"
local function LinkText(link)
    link = tostring(link or "")
    local kind, id, name = link:match("|H(%a+):(%d+)[^|]*|h%[(.-)%]|h")
    if kind then return string.format("[%s] (%s %s)", name, kind, id) end
    return Plain(link)
end

-- the last few things the tracker could have counted, newest last
local recent, RECENT_MAX = {}, 12
local function Log(text)
    recent[#recent + 1] = date("%H:%M:%S") .. "  " .. text
    if #recent > RECENT_MAX then table.remove(recent, 1) end
end

local watcher = CreateFrame("Frame")
for _, ev in ipairs({ "CHAT_MSG_LOOT", "QUEST_TURNED_IN" }) do
    pcall(watcher.RegisterEvent, watcher, ev) -- skip events a client lacks
end
watcher:SetScript("OnEvent", function(_, event, text, _, _, _, _, _, _, _, _, _, _, guid)
    pcall(function()
        if event == "CHAT_MSG_LOOT" then
            -- only your own loot: other players' names stay out of reports
            if not (text and guid and guid == UnitGUID("player")) then return end
            text = tostring(text):gsub("|Hitem:(%d+)[^|]*|h%[(.-)%]|h", "%2 (item %1)")
            Log("loot: " .. Plain(text))
        elseif event == "QUEST_TURNED_IN" then
            Log("quest turned in: " .. tostring(text))
        end
    end)
end)

-- Errors raised by this addon's own files (not other addons' or the game's).
-- The game's handler still runs; this only takes a copy.
local errors = {}
local function Capture(message)
    pcall(function()
        local text = tostring(message)
        if not text:find(ADDON, 1, true) then return end
        text = text:sub(1, 400)
        for _, e in ipairs(errors) do
            if e.text == text then e.count = e.count + 1; return end
        end
        local debugStack = rawget(_G, "debugstack")
        local stack = debugStack and debugStack(3, 6, 0) or ""
        errors[#errors + 1] = { text = text, count = 1, stack = tostring(stack):sub(1, 500) }
        if #errors > 3 then table.remove(errors, 1) end
    end)
end
local setHandler, getHandler = rawget(_G, "seterrorhandler"), rawget(_G, "geterrorhandler")
if setHandler and getHandler then
    local previous = getHandler()
    if previous then
        setHandler(function(message)
            Capture(message)
            return previous(message)
        end)
    end
end

local function Version()
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMeta and getMeta(ADDON, "Version") or "?"
end

-- ctx (all optional): goalId, step, readout, itemId, questId, about (a plain label)
-- kind: a KINDS entry; tracking activity and errors only go with bugs
local function Describe(ctx, kind)
    local lines = {}
    local function Add(s) lines[#lines + 1] = s end
    Add("Addon: Forever Goal Tracker " .. Version())
    local _, build = GetBuildInfo()
    Add("Client: " .. (FGT.isForever and "Forever" or "Classic Era") .. (build and (", build " .. build) or ""))
    local level, class, race, faction = UnitLevel("player"), UnitClass("player"), UnitRace("player"), UnitFactionGroup("player")
    Add(string.format("Character: level %s %s %s (%s)", tostring(level), tostring(race), tostring(class), tostring(faction)))
    local goal = ctx and ctx.goalId and FGT.GoalById(ctx.goalId)
    if goal then
        local done, total = FGT.GoalProgress(goal)
        Add(string.format("Goal: %s (%s), %d of %d done", Plain(goal.name), tostring(goal.id), done or 0, total or 0))
    end
    if ctx and ctx.step then Add("Step: " .. Plain(ctx.step)) end
    if ctx and ctx.readout then Add("Tracking right now: " .. Plain(ctx.readout)) end
    if ctx and ctx.itemId then Add("Item id: " .. tostring(ctx.itemId)) end
    if ctx and ctx.questId then Add("Quest id: " .. tostring(ctx.questId)) end
    if kind and kind.key ~= "bug" then return table.concat(lines, "\n") end
    if #recent > 0 then
        Add("")
        Add("Recent activity:")
        for _, l in ipairs(recent) do Add("  " .. l) end
    end
    if #errors > 0 then
        Add("")
        Add("Addon errors this session:")
        for _, e in ipairs(errors) do
            Add(string.format("  x%d %s", e.count, e.text))
            if e.stack ~= "" then Add("  " .. e.stack:gsub("\n", "\n  ")) end
        end
    end
    return table.concat(lines, "\n")
end
F.Describe = Describe

-- ------------------------------------------------------------
-- The link
-- ------------------------------------------------------------
local function Encode(s)
    return (tostring(s):gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

function F.URL(kind, text, ctx)
    text = Plain(text):sub(1, MAX_TEXT)
    local details = Describe(ctx, kind)
    local function Build(d)
        return string.format("%s&%s=%s&%s=%s&%s=%s", ENDPOINT.base, ENDPOINT.kind, Encode(kind.form),
            ENDPOINT.what, Encode(text), ENDPOINT.details, Encode(d))
    end
    local url = Build(details)
    while #url > MAX_URL and #details > 200 do -- shorten the details, never the player's words
        details = details:sub(1, math.floor(#details * 0.8)) .. "\n(trimmed)"
        url = Build(details)
    end
    return url
end

-- ------------------------------------------------------------
-- The window
-- ------------------------------------------------------------
local pop
local ctxNow, kindNow

local function Button(parent, label, width)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 90, 26)
    U.etch(b, STYLE.button, 10)
    b.text = U.font(b, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    b.text:SetPoint("CENTER")
    b.text:SetText(label)
    b.rest, b.hover = STYLE.button, STYLE.btnHover
    function b:Look(rest, hover) self.rest, self.hover = rest, hover; self:SetEtch(self:IsMouseOver() and hover or rest) end
    function b:Enable2(on)
        self.off = not on
        self:SetEnabled(on)
        self.text:SetTextColor(on and C.TEXT[1] or C.SUBTEXT[1], on and C.TEXT[2] or C.SUBTEXT[2], on and C.TEXT[3] or C.SUBTEXT[3])
        self:SetEtch(on and self.rest or STYLE.muted)
    end
    b:SetScript("OnEnter", function(self) if not self.off then self:SetEtch(self.hover) end end)
    b:SetScript("OnLeave", function(self) self:SetEtch(self.off and STYLE.muted or self.rest) end)
    return b
end

-- a quiet text button that turns gold on hover
local function TextLink(parent, label)
    local b = CreateFrame("Button", nil, parent)
    b.text = U.font(b, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    b.text:SetPoint("LEFT", 0, 0)
    b.text:SetText(label)
    b:SetSize(math.ceil(b.text:GetStringWidth()) + 4, 16)
    b:SetScript("OnEnter", function(self) self.text:SetTextColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3]) end)
    b:SetScript("OnLeave", function(self) self.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3]); GameTooltip:Hide() end)
    return b
end

function F.Close()
    if pop then pop:Hide() end
end

-- the privacy line, for what this report will carry
local function PrivacyText()
    local parts = "your addon version, class and level"
    if ctxNow and ctxNow.goalId then parts = parts .. ", the goal" end
    if kindNow.key == "bug" then parts = parts .. " and recent tracking" end
    return "Adds " .. parts .. ". Never your name or chat."
end

-- the chip that says what the report is about; only a guess (the goal that
-- happened to be open) can be removed
local function RefreshAbout()
    local chip = pop.chip
    local about = ctxNow and ctxNow.about
    if not about then chip:Hide(); return end
    chip.text:SetWidth(0)
    chip.text:SetText("About: " .. about)
    local w = math.min(math.ceil(chip.text:GetStringWidth()), 290)
    chip.text:SetWidth(w)
    chip.remove:SetShown(ctxNow.removable and true or false)
    chip:SetWidth(w + (ctxNow.removable and 30 or 16))
    chip:Show()
end

local function Fit()
    -- top padding, title, the subtitle's lines, then everything under it
    local h = 17 + pop.title:GetStringHeight() + 7 + pop.sub:GetStringHeight()
    if pop.write:IsShown() then
        h = h + 14 + 24 + 10 + 120 + 36 + pop.hint:GetStringHeight() + 18 + 26 + 16
    else
        h = h + 22 + 26 + 10 + pop.copyHint:GetStringHeight() + 10 + pop.after:GetStringHeight() + 18 + 26 + 16
    end
    pop:SetHeight(math.ceil(h))
end

local function Build()
    pop = CreateFrame("Frame", "ForeverGoalTrackerFeedback", UIParent, "BackdropTemplate")
    pop:SetFrameStrata("DIALOG")
    pop:SetFrameLevel(200)
    pop:SetSize(420, 340)
    pop:SetClampedToScreen(true)
    pop:EnableMouse(true)
    U.etch(pop, STYLE.window, 12)
    FGT.AddGrime(pop, 0.18, 12, 0.61, 0, 140)
    pop.shadow = FGT.AddDropShadow(pop, 56, 0.6, 10, 12)
    pop:Hide()
    tinsert(UISpecialFrames, "ForeverGoalTrackerFeedback")
    pop:SetScript("OnShow", function() pop.shadow:Show() end)
    pop:SetScript("OnHide", function() pop.shadow:Hide(); pop.box:ClearFocus(); pop.link:ClearFocus() end)

    pop.title = U.title(pop, 13)
    pop.title:SetPoint("TOPLEFT", 16, -17)
    pop.close = CreateFrame("Button", nil, pop)
    pop.close:SetSize(22, 22)
    pop.close:SetPoint("TOPRIGHT", -8, -10)
    pop.close:SetScript("OnClick", F.Close)
    FGT.IconButton(pop.close, "close", 13)
    pop.sub = U.font(pop, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
    pop.sub:SetPoint("TOPLEFT", pop.title, "BOTTOMLEFT", 0, -7)
    pop.sub:SetPoint("RIGHT", pop, "RIGHT", -16, 0)
    pop.sub:SetWordWrap(true)

    -- step one: write it
    local write = CreateFrame("Frame", nil, pop)
    write:SetAllPoints(pop)
    pop.write = write

    -- the kinds sit edge to edge as one control; the chosen one is lifted so its gold edge shows
    pop.pills = {}
    local prev
    for i, kind in ipairs(KINDS) do
        local pill = Button(write, kind.label, 12)
        pill:SetHeight(24)
        pill:SetWidth(math.ceil(pill.text:GetStringWidth()) + 26)
        if prev then pill:SetPoint("LEFT", prev, "RIGHT", -3, 0) else pill:SetPoint("TOPLEFT", pop.sub, "BOTTOMLEFT", 0, -14) end
        pill:SetScript("OnClick", function() F.SetKind(kind) end)
        pill.kind = kind
        pop.pills[i] = pill
        prev = pill
    end

    local field = CreateFrame("Frame", nil, write, "BackdropTemplate")
    field:SetPoint("TOPLEFT", pop.pills[1], "BOTTOMLEFT", 0, -10)
    field:SetPoint("RIGHT", pop, "RIGHT", -16, 0)
    field:SetHeight(120)
    field:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    field:SetBackdropColor(0, 0, 0, 0.6)
    field:SetBackdropBorderColor(C.BOX_RING[1], C.BOX_RING[2], C.BOX_RING[3], 1)
    pop.field = field
    local scroll = CreateFrame("ScrollFrame", nil, field)
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -4, 4)
    local box = CreateFrame("EditBox", nil, scroll)
    box:SetWidth(380)
    box:SetHeight(110)
    scroll:SetScrollChild(box)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    FGT.RegisterFont(box, "body", 12, "")
    box:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
    box:SetTextInsets(8, 8, 8, 8)
    box:SetMaxLetters(MAX_TEXT)
    pop.box = box
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 24)))
    end)
    scroll:SetScript("OnSizeChanged", function(self) box:SetWidth(self:GetWidth()) end)
    box:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local top, now = -y, scroll:GetVerticalScroll()
        local bottom = top + height + 8
        if top < now then scroll:SetVerticalScroll(math.max(0, top))
        elseif bottom > now + scroll:GetHeight() then scroll:SetVerticalScroll(math.max(0, bottom - scroll:GetHeight())) end
    end)
    -- clicking anywhere in the field types in it
    field:EnableMouse(true)
    field:SetScript("OnMouseDown", function() box:SetFocus() end)
    -- starts a little after the caret, so the blinking caret never sits on a letter
    pop.placeholder = U.font(field, 12, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    pop.placeholder:SetPoint("TOPLEFT", 15, -12)
    pop.placeholder:SetPoint("RIGHT", field, "RIGHT", -12, 0)
    pop.placeholder:SetWordWrap(true)
    pop.counter = U.font(write, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    pop.counter:SetPoint("TOPRIGHT", field, "BOTTOMRIGHT", 0, -8)

    local chip = CreateFrame("Frame", nil, write, "BackdropTemplate")
    chip:SetHeight(20)
    chip:SetPoint("TOPLEFT", field, "BOTTOMLEFT", 0, -6)
    chip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    chip:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
    chip:SetBackdropBorderColor(0.26, 0.24, 0.20, 1)
    chip.text = U.font(chip, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
    chip.text:SetPoint("LEFT", 8, 0)
    chip.text:SetWordWrap(false)
    chip.remove = CreateFrame("Button", nil, chip)
    chip.remove:SetSize(16, 16)
    chip.remove:SetPoint("RIGHT", -2, 0)
    chip.remove:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Not about this goal")
        GameTooltip:Show()
    end)
    chip.remove:SetScript("OnLeave", function() GameTooltip:Hide() end)
    FGT.IconButton(chip.remove, "close", 9)
    chip.remove:SetScript("OnClick", function()
        GameTooltip:Hide()
        ctxNow = nil
        RefreshAbout()
        pop.hint:SetText(PrivacyText())
    end)
    pop.chip = chip

    pop.hint = U.font(write, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    pop.hint:SetPoint("TOPLEFT", field, "BOTTOMLEFT", 0, -36)
    pop.hint:SetPoint("RIGHT", pop, "RIGHT", -16, 0)
    pop.hint:SetWordWrap(true)

    -- hover shows exactly what will be sent
    pop.included = TextLink(write, "What's included?")
    pop.included:SetPoint("BOTTOMLEFT", pop, "BOTTOMLEFT", 16, 21)
    pop.included:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("What's included")
        for line in (Describe(ctxNow, kindNow) .. "\n"):gmatch("(.-)\n") do
            if line ~= "" then GameTooltip:AddLine(line, C.INK2[1], C.INK2[2], C.INK2[3]) end
        end
        GameTooltip:Show()
    end)

    pop.cancel = Button(write, "Cancel", 84)
    pop.cancel:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -108, 16)
    pop.cancel:SetScript("OnClick", function()
        pop.sent = true -- Cancel throws the draft away; Escape keeps it
        F.Close()
    end)
    pop.next = Button(write, "Get link", 84)
    pop.next:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -16, 16)
    pop.next:Look(STYLE.rowSel, STYLE.goldHover)
    pop.next:SetScript("OnClick", function() F.Step2() end)

    box:SetScript("OnEscapePressed", F.Close) -- the draft is kept
    box:SetScript("OnTextChanged", function(self)
        local n = #self:GetText()
        pop.placeholder:SetShown(n == 0)
        pop.counter:SetText(n .. " / " .. MAX_TEXT)
        pop.next:Enable2(n > 0)
    end)

    -- step two: copy the link
    local send = CreateFrame("Frame", nil, pop)
    send:SetAllPoints(pop)
    send:Hide()
    pop.send = send
    local link = CreateFrame("EditBox", nil, send, "BackdropTemplate")
    link:SetHeight(26)
    link:SetPoint("TOPLEFT", pop.sub, "BOTTOMLEFT", 0, -22)
    link:SetPoint("RIGHT", pop, "RIGHT", -16, 0)
    link:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    link:SetBackdropColor(0, 0, 0, 0.6)
    link:SetBackdropBorderColor(C.BOX_RING[1], C.BOX_RING[2], C.BOX_RING[3], 1)
    link:SetAutoFocus(false)
    link:SetMaxLetters(0)
    FGT.RegisterFont(link, "body", 11, "")
    link:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
    link:SetTextInsets(8, 8, 0, 0)
    -- the link can't be edited: typing puts it back
    link:SetScript("OnTextChanged", function(self, user)
        if user and pop.url then self:SetText(pop.url); self:HighlightText() end
    end)
    link:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    link:SetScript("OnEscapePressed", F.Close)
    link:SetScript("OnEnterPressed", F.Close)
    pop.link = link
    pop.copyHint = U.font(send, 12, "", C.TITLE[1], C.TITLE[2], C.TITLE[3])
    pop.copyHint:SetPoint("TOPLEFT", link, "BOTTOMLEFT", 0, -10)
    pop.copyHint:SetText("Press Ctrl+C to copy the link, then paste it into your browser.")
    pop.after = U.font(send, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
    pop.after:SetPoint("TOPLEFT", pop.copyHint, "BOTTOMLEFT", 0, -10)
    pop.after:SetPoint("RIGHT", pop, "RIGHT", -16, 0)
    pop.after:SetWordWrap(true)
    pop.after:SetText("Your report will already be filled in. Press Submit at the end of the form. No account needed.")
    pop.back = Button(send, "Back", 84)
    pop.back:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -108, 16)
    pop.back:SetScript("OnClick", function() F.Step1() end)
    pop.done = Button(send, "Done", 84)
    pop.done:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -16, 16)
    pop.done:Look(STYLE.rowSel, STYLE.goldHover)
    pop.done:SetScript("OnClick", function()
        pop.sent = true -- the next report starts empty
        F.Close()
    end)
end

function F.SetKind(kind)
    kindNow = kind
    for _, pill in ipairs(pop.pills) do
        local on = pill.kind == kind
        pill:Look(on and STYLE.rowSel or STYLE.button, on and STYLE.goldHover or STYLE.btnHover)
        pill:SetFrameLevel(pop.write:GetFrameLevel() + (on and 3 or 1))
    end
    pop.placeholder:SetText(kind.hint)
    pop.hint:SetText(PrivacyText())
end

function F.Step1()
    pop.title:SetText("Send feedback")
    pop.sub:SetText("Report a bug, ask for a goal, or share an idea.\nYou'll finish in your browser.")
    pop.send:Hide(); pop.write:Show()
    Fit()
    pop.box:SetFocus()
end

function F.Step2()
    local text = pop.box:GetText()
    if text == "" then return end
    pop.url = F.URL(kindNow, text, ctxNow)
    pop.title:SetText("Almost done")
    pop.sub:SetText("Your feedback is ready to send.")
    pop.write:Hide(); pop.send:Show()
    Fit()
    pop.link:SetText(pop.url)
    pop.link:SetFocus()
    pop.link:HighlightText()
end

-- A shift-clicked item or quest goes into the box while you're typing in it.
function F.TakeLink(link)
    if not (pop and pop:IsShown() and pop.write:IsShown() and pop.box:HasFocus()) then return false end
    pop.box:Insert(LinkText(link) .. " ")
    return true
end
do
    -- a post-hook: the chat box keeps working, and nothing of the game's is replaced
    local owner, name, util = _G, "ChatEdit_InsertLink", rawget(_G, "ChatFrameUtil")
    if not rawget(_G, name) and util and util.InsertLink then owner, name = util, "InsertLink" end
    local hook = rawget(_G, "hooksecurefunc")
    if hook and rawget(owner, name) then
        hook(owner, name, function(link) F.TakeLink(link) end)
    end
end

-- ctx (optional) says what the report is about: { goalId, step, readout, itemId, questId, about }
-- With none, the goal that's open is suggested, and the player can remove it.
-- kind (optional): "bug", "goal" or "idea"
function F.Open(ctx, kindKey)
    if not pop then Build() end
    if not ctx then
        local goal = U.goal()
        ctx = goal and { goalId = goal.id, about = Plain(goal.short or goal.name), removable = true } or nil
    end
    ctxNow = ctx
    -- an unsent draft survives closing the window (Escape, Cancel or a stray click)
    if pop.sent or pop.box:GetText() == "" then
        pop.sent = nil
        pop.box:SetText("")
        local kind = KINDS[1]
        for _, k in ipairs(KINDS) do if k.key == kindKey then kind = k end end
        F.SetKind(kind)
    else
        local kind = kindNow
        for _, k in ipairs(KINDS) do if k.key == kindKey then kind = k end end
        F.SetKind(kind)
    end
    RefreshAbout()
    pop:ClearAllPoints()
    if U.main:IsShown() then pop:SetPoint("CENTER", U.main, "CENTER", 0, 0) else pop:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
    pop.url = nil
    pop.next:Enable2(pop.box:GetText() ~= "")
    pop:Show()
    F.Step1()
end

function F.ForStep(row)
    local goal
    if row.popoutView and FGT.Popout and FGT.Popout.goalId then goal = FGT.GoalById(FGT.Popout.goalId) end
    goal = goal or U.goal()
    local step = row.text and row.text:GetText()
    local readout = row.ruleEntry and FGT.RuleReadout and FGT.RuleReadout(row.ruleEntry)
    F.Open({
        goalId = goal and goal.id, step = step, readout = readout, itemId = row.itemId, questId = row.questId,
        about = step and Plain(step):sub(1, 70) or nil,
    })
end

-- /goals feedback (also bug, report, idea, request)
function FGT.HandleFeedbackCommand(msg)
    local word = tostring(msg or ""):lower():match("^%s*(%S+)")
    if word == "feedback" or word == "bug" or word == "report" then F.Open(nil, "bug"); return true end
    if word == "idea" then F.Open(nil, "idea"); return true end
    if word == "request" then F.Open(nil, "goal"); return true end
end

-- ------------------------------------------------------------
-- The title bar icon: with the gear and close, the icons sit together
-- and What's new moves out to their side
-- ------------------------------------------------------------
local btn = CreateFrame("Button", nil, T.bar)
btn:SetSize(22, 22)
btn:SetPoint("RIGHT", T.gear, "LEFT", -4, 0)
if FGT.WhatsNew and FGT.WhatsNew.button then
    FGT.WhatsNew.button:ClearAllPoints()
    FGT.WhatsNew.button:SetPoint("RIGHT", btn, "LEFT", -8, 0)
end
btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Send feedback")
    GameTooltip:AddLine("Report a bug or ask for a goal", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
FGT.IconButton(btn, "bug-gold", 17) -- after SetScript: SetScript would drop its hooks
btn:SetScript("OnClick", function()
    GameTooltip:Hide()
    if pop and pop:IsShown() then F.Close() else F.Open() end
end)
