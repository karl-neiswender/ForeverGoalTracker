local ADDON, FGT = ...
local U = FGT.MaterialsUI
local T = FGT.titleBarUI
local C = U.colors

-- A short release ledger, newest first. Add an entry here with every
-- release (same player-facing lines as CHANGELOG.md). The newest entry's
-- version is what makes the button glow for players who haven't seen it.
FGT.WHATS_NEW = {
    { version = "2.11.1", date = "Oct 11, 2026", items = {
        "Fix profession scanning and pick artwork from your character's professions",
        "New profession, reputation, dungeon, raid, mount and armor-set artwork",
        "Artist credits appear with the artwork",
        "Ctrl-click mount items and color variants to preview them",
        "Wolfsbane for Undead Paladins in Forever",
        "Clearer guide milestones and item sources",
    } },
    { version = "2.11.0", date = "Oct 10, 2026", items = {
        "Needed for hints on item tooltips",
        "Ctrl-click gear in guides to preview it on your character",
        "Show or hide completed guide steps",
        "Tier 2.5 armor sets, Stranglethorn Fishing Extravaganza and four AQ battle tank goals",
        "An ancient leather book behind the empty tracker",
    } },
    { version = "2.10.1", date = "Oct 9, 2026", items = {
        "Violet Sorcerer's Vestments goal",
        "More banner images",
    } },
    { version = "2.10.0", date = "Oct 9, 2026", items = {
        "Personal notes on goals",
        "Individual armor set goals",
        "Step locks on Classic Era",
        "Goal banner artwork",
    } },
    { version = "2.9.0", date = "Oct 8, 2026", items = {
        "More links in guides and tips",
        "Visual improvements and guide fixes",
    } },
}

local W = { open = false }
FGT.WhatsNew = W
local NEWEST = FGT.WHATS_NEW[1].version
local GOLD = { 0.80, 0.62, 0.16 }
local BRIGHT = { 1, 0.86, 0.35 }

local function DB() return ForeverGoalTrackerDB end
local function IsNew()
    local db = DB()
    return db and not db.demoBackup and db.whatsNewSeen ~= NEWEST
end

-- Mark the newest release seen. Fresh installs have nothing "new" to see.
local function Initialize()
    local db = DB()
    if db and db.whatsNewSeen == nil and FGT.firstRun then db.whatsNewSeen = NEWEST end
end

-- ------------------------------------------------------------
-- The button beside the settings gear
-- ------------------------------------------------------------
local btn = CreateFrame("Button", nil, T.bar)
W.button = btn
btn:SetHeight(22)
btn.glow = btn:CreateTexture(nil, "BACKGROUND")
btn.glow:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
btn.glow:SetBlendMode("ADD")
btn.glow:SetPoint("CENTER", 0, 0)
btn.glow:SetAlpha(0)
btn.text = U.font(btn, 11, "", unpack(C.SUBTEXT))
btn.text:SetText("What's new")
btn.text:SetPoint("CENTER", 0, 0)
btn:SetWidth(btn.text:GetStringWidth() + 14)
btn.glow:SetSize(btn:GetWidth() + 56, 40)
btn:SetPoint("RIGHT", T.gear, "LEFT", -6, 0)

local function Paint(k) -- k: 0 at rest .. 1 fully lit
    local r = C.SUBTEXT[1] + (BRIGHT[1] - C.SUBTEXT[1]) * k
    local g = C.SUBTEXT[2] + (BRIGHT[2] - C.SUBTEXT[2]) * k
    local b = C.SUBTEXT[3] + (BRIGHT[3] - C.SUBTEXT[3]) * k
    btn.text:SetTextColor(r, g, b)
    btn.glow:SetVertexColor(1, 0.82, 0.3)
    btn.glow:SetAlpha(0.45 * k)
end

function W.RefreshButton()
    btn:SetScript("OnUpdate", nil)
    if W.open or not IsNew() then
        btn.pulsing = false
        Paint(btn:IsMouseOver() and 1 or (W.open and 1 or 0))
        btn.glow:SetAlpha(0)
        return
    end
    if FGT.Setting("celebrations") == "off" then Paint(0.8); return end
    local t = 0
    btn:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        Paint(0.35 + 0.55 * (0.5 - 0.5 * math.cos(t * math.pi * 2 / 2.6)))
    end)
end
btn:SetScript("OnEnter", function()
    if not IsNew() or W.open then Paint(1) end
end)
btn:SetScript("OnLeave", function()
    if not IsNew() or W.open then Paint(W.open and 1 or 0) end
end)

-- ------------------------------------------------------------
-- The ledger window
-- ------------------------------------------------------------
local WIDTH = 360
local pop = CreateFrame("Frame", "ForeverGoalTrackerWhatsNew", U.main, "BackdropTemplate")
W.frame = pop
pop:SetFrameStrata("DIALOG")
pop:SetFrameLevel(U.main:GetFrameLevel() + 80)
pop:SetWidth(WIDTH)
pop:EnableMouse(true)
U.etch(pop, U.styles.panel, 12)
FGT.AddGrime(pop, 0.18, 12, 0.61, 0, 140)
pop:Hide()
tinsert(UISpecialFrames, "ForeverGoalTrackerWhatsNew")

local catcher = CreateFrame("Frame", nil, U.main)
catcher:SetAllPoints(U.main)
catcher:SetFrameStrata("DIALOG")
catcher:SetFrameLevel(pop:GetFrameLevel() - 1)
catcher:EnableMouse(true)
catcher:Hide()
catcher:SetScript("OnMouseDown", function() W.Close() end)

local title = U.title(pop, 13)
title:SetPoint("TOPLEFT", 16, -17)
title:SetText("What's new")

local close = CreateFrame("Button", nil, pop)
close:SetSize(22, 22)
close:SetPoint("TOPRIGHT", -8, -10)
close:SetScript("OnClick", function() W.Close() end)
FGT.IconButton(close, "close", 13)

local scroll = U.scroll(pop)
scroll.scroll:SetPoint("TOPLEFT", pop, "TOPLEFT", 14, -46)
scroll.scroll:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -22, 12)
scroll:Finalize()
scroll.trackHit:ClearAllPoints()
scroll.trackHit:SetPoint("TOP", scroll.scroll, "TOPRIGHT", 9, 0)
scroll.trackHit:SetPoint("BOTTOM", scroll.scroll, "BOTTOMRIGHT", 9, 0)

local blocks = {}
local function Block(i)
    local b = blocks[i]
    if b then return b end
    b = CreateFrame("Frame", nil, scroll.content)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    b.bg:SetAllPoints()
    b.version = U.font(b, 13, "", unpack(C.TITLE or C.TEXT))
    b.version:SetPoint("TOPLEFT", 10, -9)
    b.date = U.font(b, 10, "", unpack(C.SUBTEXT))
    b.date:SetPoint("TOPRIGHT", -10, -11)
    b.new = U.font(b, 9, "", unpack(BRIGHT))
    b.new:SetText("NEW")
    b.new:SetPoint("LEFT", b.version, "RIGHT", 8, 0)
    b.lines = {}
    blocks[i] = b
    return b
end

function W.Layout(prevSeen)
    local width = WIDTH - 14 - 22
    scroll.content:SetWidth(width)
    local seenAt = #FGT.WHATS_NEW + 1
    if prevSeen then
        for i, entry in ipairs(FGT.WHATS_NEW) do
            if entry.version == prevSeen then seenAt = i break end
        end
    end
    local y = 2
    for i, entry in ipairs(FGT.WHATS_NEW) do
        local b = Block(i)
        local isNew = i < seenAt
        b:SetWidth(width)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", 0, -y)
        b.version:SetText(entry.version)
        b.date:SetText(entry.date)
        b.new:SetShown(isNew)
        local h = 34
        for li, text in ipairs(entry.items) do
            local line = b.lines[li]
            if not line then
                line = { dot = U.font(b, 11, "", unpack(GOLD)), text = U.font(b, 11, "", unpack(C.TEXT)) }
                line.dot:SetText("•")
                line.text:SetJustifyH("LEFT")
                b.lines[li] = line
            end
            line.dot:ClearAllPoints(); line.dot:SetPoint("TOPLEFT", 12, -h)
            line.text:ClearAllPoints(); line.text:SetPoint("TOPLEFT", 26, -h)
            line.text:SetWidth(width - 26 - 12)
            line.text:SetText(text)
            line.dot:Show(); line.text:Show()
            h = h + math.max(14, line.text:GetStringHeight()) + 5
        end
        for li = #entry.items + 1, #b.lines do b.lines[li].dot:Hide(); b.lines[li].text:Hide() end
        h = h + 8
        b:SetHeight(h)
        -- New releases sit on a soft gold wash; older ones stay plain.
        if isNew then
            U.gradient(b.bg, GOLD, GOLD, 0.22, 0.02)
            b.bg:Show()
        else
            b.bg:Hide()
        end
        b.version:SetTextColor(unpack(isNew and BRIGHT or C.INK2))
        b:Show()
        y = y + h + 8
    end
    for i = #FGT.WHATS_NEW + 1, #blocks do blocks[i]:Hide() end
    scroll.content:SetHeight(y)
    scroll.scroll:SetVerticalScroll(0)
    scroll:Update()
end

-- Open/close with a short fade and rise (fades only when motion is reduced).
local driver = CreateFrame("Frame", nil, pop)
local function Place(rise)
    pop:ClearAllPoints()
    pop:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 14, -6 + rise)
end
local function Sized()
    local room = U.main:GetHeight() - 90
    pop:SetHeight(math.max(160, math.min(440, room)))
end

function W.Open()
    if W.open then return end
    local db = DB()
    if not db then return end
    FGT.CloseNoteCard(true)
    Sized()
    local prev = db.whatsNewSeen
    db.whatsNewSeen = NEWEST
    W.open = true
    W.RefreshButton()
    W.Layout(prev)
    catcher:Show(); pop:Show()
    local mode = FGT.Setting("celebrations")
    if mode == "off" then Place(0); pop:SetAlpha(1); return end
    local t = 0
    Place(-6); pop:SetAlpha(0)
    driver:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        local p = math.min(1, t / 0.2)
        local e = 1 - (1 - p) ^ 3
        pop:SetAlpha(e)
        Place(mode == "full" and -6 * (1 - e) or 0)
        if p >= 1 then driver:SetScript("OnUpdate", nil) end
    end)
end

function W.Close()
    if not W.open and not pop:IsShown() then return end
    driver:SetScript("OnUpdate", nil)
    W.open = false
    pop:Hide(); catcher:Hide()
    W.RefreshButton()
end

btn:SetScript("OnClick", function()
    if W.open then W.Close() else W.Open() end
end)
pop:SetScript("OnHide", function() if W.open then W.Close() end end)
U.main:HookScript("OnHide", function() W.Close() end)
U.main:HookScript("OnShow", function() Initialize(); W.RefreshButton() end)

-- /goals whatsnew [reset]
function W.Command(arg)
    if arg == "reset" then
        if DB() then DB().whatsNewSeen = nil end
        W.Close(); W.RefreshButton()
        print("|cffffd75eForever Goal Tracker:|r What's new will glow again.")
        return
    end
    if not U.main:IsShown() then FGT.ToggleFrame() end
    W.Open()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function() Initialize(); W.RefreshButton() end)
W.RefreshButton()
