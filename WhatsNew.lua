local ADDON, FGT = ...
local U = FGT.MaterialsUI
local T = FGT.titleBarUI
local C = U.colors

-- A short release ledger, newest first. Add an entry here with every
-- release (same player-facing lines as CHANGELOG.md). The newest entry's
-- version is what makes the button glow for players who haven't seen it.
-- Keep it short, and write every line in the same words
-- (reports/release-notes/style-guide.md): "Added ...", "You can now ...",
-- "Changed ... (was ...)", "Fixed ...", "Removed ...", "Renamed ...", and
-- the closing "UI improvements and bug fixes" when small tweaks went in.
-- tools/copycheck.py enforces the verbs.
FGT.WHATS_NEW = {
    { version = "2.16.0", date = "Oct 23, 2026", items = {
        "Added Gear Planner: plan a gear set slot by slot on your character, with item search, filters and where each item comes from",
        "Added enchants and scopes to Gear Planner, tracked as goal steps with their materials",
        "Added a level range to each gear set, and gear set goals with your character's leveling artwork",
        "Added Library goal links in Gear Planner: legendaries and sets open or add their goal",
        "Added Start from my current gear, and hints when another character holds a piece of your set",
        "UI improvements and bug fixes",
    } },
    { version = "2.15.2", date = "Oct 17, 2026", items = {
        "Added Hide completed goals to My Goals, with the choice remembered after reloads",
        "Changed New & Updated to list matching sets and mounts individually",
        "Changed item set guides to show pieces directly, with expandable requirements for Tier 3 and Tier 2.5",
        "Changed completed goal cards to use darker backgrounds and green completion markers",
        "Fixed character filtering for Buff Other Players and wrapping in narrow item set guides",
        "UI improvements and bug fixes",
    } },
    { version = "2.15.1", date = "Oct 16, 2026", items = {
        "Added clickable dungeon names with entrance pins in guides",
        "Added map links for Light's Hope Chapel, City of Dalaran and both Ahn'Qiraj raids",
        "Added Darkspear Islands reputation goals and Teebu's Blazing Longsword",
        "Added more goal artwork and corrected several background selections",
        "UI improvements and bug fixes",
    } },
    { version = "2.15.0", date = "Oct 15, 2026", items = {
        "Added a map view for goal pages, with Show on map links for steps, reputations and two raids",
        "Added the Zin'rokh and Arcanite Reaper goals",
        "Added banners, blooms, fire and sunlight for more goals",
        "Changed the faction filter to hide the other faction's goals, even ones you added",
        "Changed the Charger to an Alliance goal (was both factions)",
        "UI improvements and bug fixes",
    } },
    { version = "2.14.0", date = "Oct 14, 2026", items = {
        "Added a pop-out window for a goal's steps",
        "Added a goals list that folds to a slim icon rail",
        "Added the Partners in Crime and Summon Players goals",
        "Added blown sand, star glints and more light to goal images",
        "Removed the Large goal photos setting",
        "UI improvements and bug fixes",
    } },
    { version = "2.13.0", date = "Oct 13, 2026", items = {
        "Added light to goal images, with an Image effects setting: Full, Subtle or Off",
        "Added Ambassador banners for each race's capital city",
        "You can now Ctrl-click an armor set's icon to try on the whole set",
        "Added social goals for guildmates, trades, buffs, campfires and emotes",
        "Changed goal suggestions to follow your professions",
        "UI improvements and bug fixes",
    } },
    { version = "2.12.0", date = "Oct 12, 2026", items = {
        "Added Goal Library filters, with a Progression sort for armor sets",
        "Added armor sets and racial mounts for your class or character",
        "You can now search My Goals and show only this character's goals",
        "Added a Materials panel to each goal",
        "Added this What's new button",
        "UI improvements and bug fixes",
    } },
    { version = "2.11.1", date = "Oct 11, 2026", items = {
        "Fixed profession scanning, and artwork now follows your character's professions",
        "Added profession, reputation, dungeon, raid, mount and armor-set artwork",
        "Added artist credits beside the artwork",
        "You can now Ctrl-click mount items and color variants to preview them",
        "Added Wolfsbane for Undead Paladins in Forever",
        "Changed guide milestones and item sources to read more clearly",
    } },
    { version = "2.11.0", date = "Oct 10, 2026", items = {
        "Added Needed for hints to item tooltips",
        "You can now Ctrl-click gear in guides to preview it on your character",
        "You can now show or hide completed guide steps",
        "Added Tier 2.5 armor sets, the Stranglethorn Fishing Extravaganza and four AQ battle tank goals",
        "Added an ancient leather book behind the empty tracker",
    } },
    { version = "2.10.1", date = "Oct 9, 2026", items = {
        "Added the Violet Sorcerer's Vestments goal",
        "Added more banner images",
    } },
    { version = "2.10.0", date = "Oct 9, 2026", items = {
        "You can now add personal notes to goals",
        "Added individual armor set goals",
        "Added step locks on Classic Era",
        "Added goal banner artwork",
    } },
    { version = "2.9.0", date = "Oct 8, 2026", items = {
        "Added more links in guides and tips",
        "UI improvements and bug fixes",
    } },
}

local W = { open = false }
FGT.WhatsNew = W
local NEWEST = FGT.WHATS_NEW[1].version
local GOLD = { 0.80, 0.62, 0.16 }
local RULE = { 0.45, 0.38, 0.26 }
local BRIGHT = { 1, 0.86, 0.35 }
local REST = { 0.66, 0.55, 0.38 } -- warm bronze, from the UI's etched edges

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
btn.text = U.font(btn, 12, "", unpack(REST))
btn.text:SetText("What's new")
btn.text:SetPoint("CENTER", 0, 0)
btn:SetWidth(btn.text:GetStringWidth() + 14)
btn.glow:SetSize(btn:GetWidth() + 44, 34)
btn:SetPoint("RIGHT", T.gear, "LEFT", -6, 0)

local function Paint(k) -- k: 0 at rest .. 1 fully lit
    local r = REST[1] + (BRIGHT[1] - REST[1]) * k
    local g = REST[2] + (BRIGHT[2] - REST[2]) * k
    local b = REST[3] + (BRIGHT[3] - REST[3]) * k
    if btn.hover then return end
    btn.text:SetTextColor(r, g, b)
    btn.glow:SetVertexColor(1, 0.82, 0.3)
    btn.glow:SetAlpha(0.16 * k)
end

function W.RefreshButton()
    btn:SetScript("OnUpdate", nil)
    if W.open or not IsNew() then
        btn.pulsing = false
        Paint(W.open and 1 or 0)
        if btn.hover then btn.text:SetTextColor(1, 1, 1) end
        btn.glow:SetAlpha(btn.hover and 0.07 or 0)
        return
    end
    if FGT.Setting("celebrations") == "off" then Paint(0.55); return end
    local t = 0
    btn:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        Paint(0.25 + 0.4 * (0.5 - 0.5 * math.cos(t * math.pi * 2 / 2.8)))
    end)
end
-- Hovering turns the text pure white with a lighter glow, glowing or not.
local function Hover(on)
    btn.hover = on
    if on then
        btn.text:SetTextColor(1, 1, 1)
        btn.glow:SetVertexColor(1, 0.9, 0.6)
        btn.glow:SetAlpha(0.07)
    elseif IsNew() and not W.open then
        -- the pulse driver repaints on its next frame (or Paint below)
        if FGT.Setting("celebrations") == "off" then Paint(0.55) end
    else
        Paint(W.open and 1 or 0)
        btn.glow:SetAlpha(0)
    end
end
btn:SetScript("OnEnter", function() Hover(true) end)
btn:SetScript("OnLeave", function() Hover(false) end)

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
pop.shadow = FGT.AddDropShadow(pop, 40, 0.3, 12, 12) -- faint and soft, sitting a little low
pop.shadow:Hide()
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
    -- the glow breathes behind a dot that never changes size
    b.halo = b:CreateTexture(nil, "ARTWORK")
    b.halo:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
    b.halo:SetBlendMode("ADD")
    b.halo:SetVertexColor(1, 0.82, 0.3)
    b.halo:SetSize(22, 22)
    b.halo:SetAlpha(0.015)
    b.dot = b:CreateTexture(nil, "OVERLAY")
    b.dot:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\dot")
    b.dot:SetVertexColor(1, 0.82, 0.3)
    b.dot:SetSize(14, 14)
    b.dot:SetPoint("LEFT", b.version, "RIGHT", 5, 0)
    b.halo:SetPoint("CENTER", b.dot, "CENTER", 0, 0)
    b.new = U.font(b, 9, "", unpack(BRIGHT))
    b.new:SetText("NEW")
    b.new:SetPoint("LEFT", b.dot, "RIGHT", 1, 0)
    b.lines = {}
    -- a faint rule under the block, fading out toward both ends
    b.ruleL = b:CreateTexture(nil, "ARTWORK"); b.ruleR = b:CreateTexture(nil, "ARTWORK")
    for _, t in ipairs({ b.ruleL, b.ruleR }) do t:SetTexture("Interface\\Buttons\\WHITE8X8"); t:SetHeight(1) end
    b.ruleL:SetPoint("BOTTOMLEFT", 8, -5); b.ruleL:SetPoint("BOTTOMRIGHT", b, "BOTTOM", 0, -5)
    b.ruleR:SetPoint("BOTTOMLEFT", b, "BOTTOM", 0, -5); b.ruleR:SetPoint("BOTTOMRIGHT", -8, -5)
    U.gradient(b.ruleL, RULE, RULE, 0, 0.5); U.gradient(b.ruleR, RULE, RULE, 0.5, 0)
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
        b.new:SetShown(isNew); b.dot:SetShown(isNew); b.halo:SetShown(isNew)
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
        -- the rule sits right on the gold wash's bottom edge; plain blocks center it in the gap
        local drop = isNew and 0 or -5
        b.ruleL:ClearAllPoints(); b.ruleL:SetPoint("BOTTOMLEFT", 8, drop); b.ruleL:SetPoint("BOTTOMRIGHT", b, "BOTTOM", 0, drop)
        b.ruleR:ClearAllPoints(); b.ruleR:SetPoint("BOTTOMLEFT", b, "BOTTOM", 0, drop); b.ruleR:SetPoint("BOTTOMRIGHT", -8, drop)
        b.ruleL:SetShown(i < #FGT.WHATS_NEW); b.ruleR:SetShown(i < #FGT.WHATS_NEW)
        b:Show()
        y = y + h + 10
    end
    for i = #FGT.WHATS_NEW + 1, #blocks do blocks[i]:Hide() end
    scroll.content:SetHeight(y)
    scroll.scroll:SetVerticalScroll(0)
    scroll:Update()
end

-- Open/close with a short fade and rise (fades only when motion is reduced).
local pulser = CreateFrame("Frame", nil, pop)
local function StartPulse()
    pulser:SetScript("OnUpdate", nil)
    if FGT.Setting("celebrations") == "off" then
        for _, b in ipairs(blocks) do b.halo:SetAlpha(0.02) end
        return
    end
    local t = 0
    pulser:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        -- a slow breath: the cosine wave eased once more (smootherstep),
        -- so it lingers softly at the top and bottom before turning
        local k = 0.5 - 0.5 * math.cos(t * math.pi * 2 / 4.6)
        k = k * k * k * (k * (k * 6 - 15) + 10)
        for _, b in ipairs(blocks) do
            if b.dot:IsShown() then b.halo:SetAlpha(0.008 + 0.032 * k) end
        end
    end)
end
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
    StartPulse()
    catcher:Show(); pop:Show(); pop.shadow:Show()
    local mode = FGT.Setting("celebrations")
    if mode == "off" then Place(0); pop:SetAlpha(1); pop.shadow:SetAlpha(1); return end
    local t = 0
    Place(-6); pop:SetAlpha(0); pop.shadow:SetAlpha(0)
    driver:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        local p = math.min(1, t / 0.2)
        local e = 1 - (1 - p) ^ 3
        pop:SetAlpha(e); pop.shadow:SetAlpha(e)
        Place(mode == "full" and -6 * (1 - e) or 0)
        if p >= 1 then driver:SetScript("OnUpdate", nil) end
    end)
end

function W.Close()
    if not W.open and not pop:IsShown() then return end
    driver:SetScript("OnUpdate", nil); pulser:SetScript("OnUpdate", nil)
    W.open = false
    pop:Hide(); pop.shadow:Hide(); catcher:Hide()
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
