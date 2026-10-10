local ADDON, FGT = ...

-- ============================================================
-- Palette (flat, modern, dark)
-- ============================================================
-- Charcoal + gold, in the style of talentsforever.com:
--   bg #121212, panel #1e1e1e, panel2 #262626, line #3a3a3a,
--   ink #e8e8e8, ink2 #bdbdbd, muted #8a8a8a,
--   gold #ffd100, gold2 #c89b1a, title gold #ffd75e, green #4fbf3a
-- Palette lives in one table (keeps the file under Lua's 200-local limit).
local C = {}
C.BG          = { 0.071, 0.071, 0.071, 0.98 }
C.PANEL       = { 0.035, 0.034, 0.032, 1 } -- matches the panel gradient mid-low
C.PANEL2      = { 0.149, 0.149, 0.149, 1 }
C.BORDER      = { 0.227, 0.227, 0.227, 1 }
C.ACCENT      = { 1.00, 0.82, 0.00 }      -- gold
C.GOLD2       = { 0.784, 0.608, 0.102 }   -- deep gold
C.TITLE       = { 1.00, 0.843, 0.369 }    -- heading gold
C.TEXT        = { 0.91, 0.91, 0.91 }
C.INK2        = { 0.741, 0.741, 0.741 }
C.SUBTEXT     = { 0.541, 0.541, 0.541 }
C.DONE        = { 0.31, 0.75, 0.23 }
C.ROW         = { 0.165, 0.165, 0.165, 1 } -- #2a2a2a
C.ROW_LINE    = { 0.20, 0.20, 0.20, 1 }    -- #333
C.ROW_HOVER   = { 0.243, 0.243, 0.243, 1 } -- #3e3e3e
C.ROW_SEL     = { 0.29, 0.259, 0.161, 1 }  -- #4a4229
C.BTN         = { 0.227, 0.227, 0.227, 1 } -- #3a3a3a
C.BTN_HOVER   = { 0.29, 0.29, 0.29, 1 }    -- #4a4a4a
C.BOX_RING    = { 0.42, 0.42, 0.42, 1 }    -- #6b6b6b
C.BOX_DONE_BG = { 0.18, 0.165, 0.12, 1 }   -- #2e2a1f
-- WoW Forever blues, for Forever-only goals and the "not confirmed yet" notice.
C.FOREVER      = { 0.251, 0.549, 1.00 }   -- #408cff, text and edges
C.FOREVER_MID  = { 0.000, 0.298, 0.749 }  -- #004cbf
C.FOREVER_DEEP = { 0.090, 0.357, 0.549 }  -- #175b8c
C.FOREVER_LIGHT = { 0.61, 0.79, 1.00 }    -- #9ccaff, NEW labels (reads on blue tiles)
C.FACTION_INSET = { 0.07, 0.07, 0.07 }
C.FACTION_SHADE = { 0, 0, 0 }
C.FACTION_EDGE = { 0.55, 0.55, 0.55 }

local FONT = "Fonts\\FRIZQT__.TTF"
local FONT_TITLE = "Interface\\AddOns\\" .. ADDON .. "\\Fonts\\Cinzel-Bold.ttf"

local SOLID = "Interface\\Buttons\\WHITE8x8"
local BACKDROP_SOLID = { bgFile = SOLID }
local BACKDROP_LINED = { bgFile = SOLID, edgeFile = SOLID, edgeSize = 1 }

-- Which client is this? Era/Anniversary reports 11xxx; the Warcraft
-- Forever beta runs on the modern engine and reports 16xxx. The same
-- files load in both (the .toc lists both interface numbers); this
-- flag only changes labels. Progress is saved separately per client
-- because each install folder keeps its own SavedVariables.
local CLIENT_INTERFACE = select(4, GetBuildInfo()) or 0
FGT.isForever = CLIENT_INTERFACE >= 16000
FGT.clientLabel = FGT.isForever and "FOREVER" or "CLASSIC"
FGT.NAME = "Forever Goal Tracker"
local TAG = "|cffffd75eForever Goal Tracker:|r " -- prefix for chat messages

-- Karl's UI icons (Media/icons, 64px): "<name>" painted gold, or
-- "<name>-white" in grey for icons tinted in code (SetVertexColor).
-- The glyph fills the square (3px padding), unlike Blizzard's check
-- texture, so sizes are smaller than the textures they replaced.
function FGT.Icon(name) return "Interface\\AddOns\\" .. ADDON .. "\\Media\\icons\\" .. name end

-- GetItemInfo moved to C_Item.GetItemInfo on the modern engine Forever runs
-- on (the old global is gone there: 2.7 work crashed on it); Classic Era
-- has the global. Same returns either way; nil when unavailable.
function FGT.ItemInfo(id)
    local f = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if f then return f(id) end
end

-- math.atan2 has been dropped from some newer clients' Lua environment
-- (only math.atan with one argument remains guaranteed). Use the real
-- one when it exists, otherwise compute the same thing by hand.
local Atan2 = math.atan2 or function(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    else
        return 0
    end
end

local LIST_WIDTH   = 216
local FRAME_WIDTH  = 1240 -- FGT.DefaultSize fits it to small screens
local FRAME_HEIGHT = 750
local MIN_FRAME_WIDTH  = 520
local MIN_FRAME_HEIGHT = 360
local MAX_FRAME_WIDTH  = 1240
local MAX_FRAME_HEIGHT = 900

-- The size caps above are meaningless if they're bigger than the
-- player's actual screen (in UI units, which is what GetScreenWidth/
-- Height report, and exactly what SetSize/SetPoint use) - that's what
-- previously let the window grow taller than the screen and pushed the
-- resize grip off the bottom edge with no way to reach it. This clamps
-- against whichever is smaller, with a margin so the frame never runs
-- edge-to-edge.
local function GetEffectiveMaxSize()
    -- measured in the window's own units, so a scaled window still fits
    local s = FGT.windowScale or 1
    local screenW = (GetScreenWidth and GetScreenWidth() or MAX_FRAME_WIDTH) / s
    local screenH = (GetScreenHeight and GetScreenHeight() or MAX_FRAME_HEIGHT) / s
    local maxW = math.min(MAX_FRAME_WIDTH, math.floor(screenW - 60))
    local maxH = math.min(MAX_FRAME_HEIGHT, math.floor(screenH - 60))
    return math.max(MIN_FRAME_WIDTH, maxW), math.max(MIN_FRAME_HEIGHT, maxH)
end

-- Single source of truth for "is this size safe to use" - applied both
-- when a saved size is loaded AND when a new size is saved, so a bad
-- value can never get written back out even if something upstream
-- (a client resize-bounds quirk, a stale SavedVariables entry) hands
-- us one.
local function ClampFrameSize(w, h)
    local maxW, maxH = GetEffectiveMaxSize()
    local cw = math.max(MIN_FRAME_WIDTH, math.min(maxW, w or FRAME_WIDTH))
    local ch = math.max(MIN_FRAME_HEIGHT, math.min(maxH, h or FRAME_HEIGHT))
    return cw, ch
end

-- The default window size: as large as FRAME_WIDTH x FRAME_HEIGHT,
-- shrunk evenly (keeping the shape) when the screen is smaller.
function FGT.DefaultSize()
    local maxW, maxH = GetEffectiveMaxSize()
    local w = math.min(FRAME_WIDTH, maxW)
    local h = math.floor(w * FRAME_HEIGHT / FRAME_WIDTH)
    if h > maxH then
        h = maxH
        w = math.floor(h * FRAME_WIDTH / FRAME_HEIGHT)
    end
    return ClampFrameSize(w, h)
end

-- ============================================================
-- Saved variables
-- ============================================================
-- Which goals are on your tracker. The original goals (Data.lua) start
-- active; Library goals start inactive until you add them.
-- Group goals (classes, professions, mount races, Tier 3 sets) are
-- added part by part. A part is a step index, or a section index for
-- goals built from sections.
function FGT.GroupParts(goal)
    local parts = {}
    if goal.sections then
        for si, section in ipairs(goal.sections) do
            -- Forever-only parts (the Skyborne mount) don't exist on Classic Era.
            if section.forever ~= "new" or FGT.isForever then
                table.insert(parts, { key = si, label = section.name, icon = section.icon, forever = section.forever })
            end
        end
    else
        for i, entry in ipairs(goal.steps) do
            local label = type(entry) == "table" and entry.text or entry
            label = label:gsub("%.$", "")
            table.insert(parts, { key = i, label = label, icon = type(entry) == "table" and entry.icon or nil })
        end
    end
    return parts
end

local function PartSelected(goal, key)
    if goal.armorChildren then
        local child = goal.armorChildren[key]
        return child and ForeverGoalTrackerDB and ForeverGoalTrackerDB.active
            and ForeverGoalTrackerDB.active[child.id] and true or false
    end
    if not goal.group then return true end
    local sel = ForeverGoalTrackerDB and ForeverGoalTrackerDB.activeParts
        and ForeverGoalTrackerDB.activeParts[goal.id]
    return sel and sel[key] and true or false
end
FGT.PartSelected = PartSelected

function FGT.SelectedPartCount(goal)
    local n = 0
    for _, part in ipairs(FGT.GroupParts(goal)) do
        if PartSelected(goal, part.key) then n = n + 1 end
    end
    return n
end

local function IsActive(goal)
    if not ForeverGoalTrackerDB then return false end
    if goal.group then return FGT.SelectedPartCount(goal) > 0 end
    return ForeverGoalTrackerDB.active and ForeverGoalTrackerDB.active[goal.id] and true or false
end

local function ActiveGoals()
    local out = {}
    for _, g in ipairs(FGT.goals) do
        if not g.libraryOnly and IsActive(g) then table.insert(out, g) end
    end
    return out
end
FGT.ActiveGoals = ActiveGoals

local function EnsureDB()
    if type(ForeverGoalTrackerDB) ~= "table" then
        ForeverGoalTrackerDB = {}
    end
    if type(ForeverGoalTrackerDB.progress) ~= "table" then
        ForeverGoalTrackerDB.progress = {}
    end
    -- First install: start with an empty tracker, whose empty state
    -- points people to the Library. Existing saves keep what they have.
    if type(ForeverGoalTrackerDB.active) ~= "table" then
        ForeverGoalTrackerDB.active = {}
        ForeverGoalTrackerDB.tab = "tracker"
        FGT.firstRun = true
    end
    if ForeverGoalTrackerDB.tab == nil then
        ForeverGoalTrackerDB.tab = "tracker"
    end
    -- Group goals that were on (or default to) the tracker before parts
    -- existed start with every part selected.
    if type(ForeverGoalTrackerDB.activeParts) ~= "table" then
        ForeverGoalTrackerDB.activeParts = {}
    end
    -- favorited goals sit in their own section at the top of My Goals
    if type(ForeverGoalTrackerDB.favorites) ~= "table" then
        ForeverGoalTrackerDB.favorites = {}
    end
    for _, g in ipairs(FGT.goals) do
        if g.group and ForeverGoalTrackerDB.activeParts[g.id] == nil then
            local sel = {}
            if ForeverGoalTrackerDB.active[g.id] then
                for _, part in ipairs(FGT.GroupParts(g)) do sel[part.key] = true end
            end
            ForeverGoalTrackerDB.activeParts[g.id] = sel
        end
    end
    if ForeverGoalTrackerDB.selected == nil then
        ForeverGoalTrackerDB.selected = FGT.goals[1] and FGT.goals[1].id or nil
    end
    if ForeverGoalTrackerDB.minimapPos == nil then
        ForeverGoalTrackerDB.minimapPos = 200
    end
    if ForeverGoalTrackerDB.sortMode == nil then
        ForeverGoalTrackerDB.sortMode = "alpha"
    end
    if ForeverGoalTrackerDB.frameWidth == nil or ForeverGoalTrackerDB.frameHeight == nil then
        ForeverGoalTrackerDB.frameWidth, ForeverGoalTrackerDB.frameHeight = FGT.DefaultSize()
    end
    -- One-time: windows still at the old default (700 x 560, never
    -- resized) move to the new 3:2 default. A size someone dragged stays.
    if not ForeverGoalTrackerDB.sizeFix250 then
        if ForeverGoalTrackerDB.frameWidth == 700 and ForeverGoalTrackerDB.frameHeight == 560 then
            ForeverGoalTrackerDB.frameWidth, ForeverGoalTrackerDB.frameHeight = FGT.DefaultSize()
        end
        ForeverGoalTrackerDB.sizeFix250 = true
    end
end

-- ============================================================
-- Settings (DB.settings). Defaults are how the addon behaved before
-- settings existed, so every option only turns something off or
-- adjusts it. The settings page itself is built further down.
-- ============================================================
FGT.SETTING_DEFAULTS = {
    greeting = true,         -- login check-in in chat
    completeChat = true,     -- "You just completed ..." chat line
    completeBanner = true,   -- goal-complete banner
    screenshot = false,      -- game screenshot when a goal finishes (Karl: off by default)
    stepChat = true,         -- "3 steps checked off", boss kills, level 60
    celebrations = "full",   -- "full" / "subtle" / "off"
    sound = "off",           -- sound when a goal completes: a key of FGT.SOUNDS
    soundChannel = "SFX",    -- the game volume slider it follows: Master, SFX, Ambience, Music, Dialog
    minimap = true,          -- minimap button shown
    openOnLogin = false,     -- open the window after login
    scale = 1,               -- window scale
    alpha = 1,               -- window opacity
    mapPins = "auto",        -- NPC map pins: "auto" (TomTom if installed), "tomtom", "game"
    hideCompletedSteps = false, -- guide filter, controlled beside Step by Step
    itemNeeds = true,        -- tracked goals on native bag, loot and AH item tooltips
}

function FGT.Setting(key)
    local s = ForeverGoalTrackerDB and ForeverGoalTrackerDB.settings
    local v = s and s[key]
    if v == nil then return FGT.SETTING_DEFAULTS[key] end
    return v
end

function FGT.SetSetting(key, value)
    if not ForeverGoalTrackerDB then return end
    ForeverGoalTrackerDB.settings = ForeverGoalTrackerDB.settings or {}
    -- store only what differs from the default, so future default
    -- changes still reach players who never touched the option
    if value == FGT.SETTING_DEFAULTS[key] then value = nil end
    ForeverGoalTrackerDB.settings[key] = value
end

local function IsStepDone(goalId, index)
    local g = ForeverGoalTrackerDB.progress[goalId]
    return g ~= nil and g[index] == true
end

local function SetStepDone(goalId, index, value)
    local g = ForeverGoalTrackerDB.progress[goalId]
    if not g then
        g = {}
        ForeverGoalTrackerDB.progress[goalId] = g
    end
    g[index] = value or nil
end

-- Composite progress key for one material line inside a Tier 3 piece.
local function MaterialKey(sectionIndex, pieceIndex, materialIndex)
    return sectionIndex .. "_" .. pieceIndex .. "_m" .. materialIndex
end

-- Composite progress key for a Tier 3 piece itself (the "I obtained this
-- piece" checkbox, separate from its materials checklist).
local function PieceKey(sectionIndex, pieceIndex)
    return sectionIndex .. "_" .. pieceIndex .. "_piece"
end

-- One piece's progress, the single rule every count uses. A piece with
-- materials (Tier 3) counts its materials only: it's done when they all
-- are, and owning it ticks them all. A piece without materials (a mount
-- task, a Tier 1/2 item) is a single checkbox.
function FGT.PieceProgress(goalId, si, pi, piece)
    local collection = FGT.armorCollections[goalId]
    if collection then goalId, si = collection.armorChildren[si].id, 1 end
    if FGT.PieceSkipped(piece) then return 0, 0 end -- not shown, not counted
    local n = #piece.materials
    if n == 0 then
        return IsStepDone(goalId, PieceKey(si, pi)) and 1 or 0, 1
    end
    local done = 0
    for mi = 1, n do
        if IsStepDone(goalId, MaterialKey(si, pi, mi)) then done = done + 1 end
    end
    return done, n
end

-- ============================================================
-- Character roster (account-wide)
-- ============================================================
-- An addon can only read the character that's logged in, so every
-- character records itself here on login, on every XP gain and on
-- level up. Goals that track levels read this table, so they know
-- about every character you've logged into at least once.
local MAX_LEVEL = 60

local function CharKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "?")
end

-- ------------------------------------------------------------
-- What to watch: collected once from every rule in Data.lua, so the
-- scanner only stores what some goal actually cares about.
-- ------------------------------------------------------------
local WATCH = { items = {}, quests = {}, taken = {}, factions = {}, skills = {}, names = {}, patterns = {} }
FGT.EMPTY = {}

local function AsList(v)
    if v == nil then return FGT.EMPTY end -- shared and read-only, no new table per call
    return type(v) == "table" and v or { v }
end

local function CollectRule(rule)
    if not rule then return end
    for _, id in ipairs(AsList(rule.item)) do WATCH.items[id] = true end
    for _, id in ipairs(AsList(rule.quest)) do WATCH.quests[id] = true end
    -- a picked-up quest also counts once it's turned in, so watch both
    for _, id in ipairs(AsList(rule.questTaken)) do
        WATCH.taken[id] = true
        WATCH.quests[id] = true
    end
    if rule.rep then
        for _, fid in ipairs(AsList(rule.rep.faction)) do WATCH.factions[fid] = true end
    end
    if rule.skill then WATCH.skills[rule.skill.name] = true end
    if rule.stat then
        WATCH.stats = WATCH.stats or {}
        WATCH.stats[rule.stat.id] = true
    end
    for _, n in ipairs(AsList(rule.owned)) do WATCH.names[n] = true end
    for _, pat in ipairs(AsList(rule.ownedPattern)) do WATCH.patterns[pat] = true end
end

local function BuildWatchList()
    for _, goal in ipairs(FGT.goals) do
        CollectRule(goal.completeWith)
        for _, entry in ipairs(goal.steps or {}) do
            if type(entry) == "table" then CollectRule(entry.auto) end
        end
        for _, section in ipairs(goal.sections or {}) do
            for _, piece in ipairs(section.pieces) do CollectRule(piece.auto) end
        end
    end
    -- every linked quest (Quests.lua), for the quest tooltips' status lines
    for _, q in ipairs(FGT.QUESTS or {}) do
        for _, id in ipairs(q[2]) do WATCH.quests[id] = true; WATCH.taken[id] = true end
    end
end

-- ------------------------------------------------------------
-- Version-safe wrappers (Era 1.15 and the Forever client expose some
-- of these under C_ namespaces, some as old globals).
-- ------------------------------------------------------------
local function ItemCount(id)
    local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
    local n = fn and fn(id, true) or 0
    local equipped = (C_Item and C_Item.IsEquippedItem) or IsEquippedItem
    if (n or 0) == 0 and equipped and equipped(id) then n = 1 end
    return n or 0
end

local function QuestDone(id)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(id) and true or false
    end
    return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(id) and true or false
end

-- Quest IDs currently in the quest log, as a set. Uses C_QuestLog.IsOnQuest
-- where the client has it, otherwise reads the log (questID is the 8th
-- return of GetQuestLogTitle).
function FGT.QuestsInLog(ids)
    local found = {}
    if C_QuestLog and C_QuestLog.IsOnQuest then
        for id in pairs(ids) do
            if C_QuestLog.IsOnQuest(id) then found[id] = true end
        end
        return found
    end
    if GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, (GetNumQuestLogEntries() or 0) do
            local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
            if not isHeader and questID and ids[questID] then found[questID] = true end
        end
    end
    return found
end

-- returns standingId (1 Hated .. 4 Neutral .. 8 Exalted), points into it
local function FactionStanding(fid)
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local d = C_Reputation.GetFactionDataByID(fid)
        if d and d.reaction then
            return d.reaction, (d.currentStanding or 0) - (d.currentReactionThreshold or 0)
        end
    end
    if GetFactionInfoByID then
        local name, _, standing, barMin, _, barValue = GetFactionInfoByID(fid)
        if name and standing then return standing, (barValue or 0) - (barMin or 0) end
    end
end

-- Factions that are actually in this character's reputation panel.
-- The game answers "Neutral, 0" for factions you've never met, so a
-- faction only counts once it shows up here. Returns nil if the client
-- offers no way to list them (then we fall back to trusting the value).
local function KnownFactions()
    local known, any = {}, false
    if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
        for i = 1, C_Reputation.GetNumFactions() do
            local d = C_Reputation.GetFactionDataByIndex(i)
            if d and d.factionID and not d.isHeader then known[d.factionID] = true; any = true end
        end
    elseif GetNumFactions and GetFactionInfo then
        for i = 1, GetNumFactions() do
            local _, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if factionID and not isHeader then known[factionID] = true; any = true end
        end
    end
    return any and known or nil
end

local function SkillRanks()
    local out = {}
    if GetNumSkillLines and GetSkillLineInfo then
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank = GetSkillLineInfo(i)
            if name and not isHeader and WATCH.skills[name] then out[name] = rank end
        end
    end
    return out
end

local function ContainerSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
    return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end
local function ContainerLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then return C_Container.GetContainerItemLink(bag, slot) end
    return GetContainerItemLink and GetContainerItemLink(bag, slot)
end

local function WatchedName(name)
    if not name then return false end
    if WATCH.names[name] then return true end
    for n in pairs(WATCH.names) do
        if name:find(n, 1, true) then return true end
    end
    for pat in pairs(WATCH.patterns) do
        if name:find(pat) then return true end
    end
    return false
end

-- Adds every watched item/mount name this character has to `owned`
-- (gear, bags, the bank when it's open, and the mount collection).
-- Names are only ever added, never removed, so a mount you learned
-- from its item or gear you replaced still counts.
local bankOpen = false
local function ScanOwnedNames(owned)
    local function add(link)
        local name = link and link:match("%[(.-)%]")
        if WatchedName(name) then owned[name] = true end
    end
    for slot = 1, 19 do add(GetInventoryItemLink("player", slot)) end
    -- -2 is the keyring, where dungeon keys live (no slots on clients
    -- without one, so it's harmless there)
    local bags = { 0, 1, 2, 3, 4, -2 }
    if bankOpen then
        table.insert(bags, -1)
        for b = 5, 11 do table.insert(bags, b) end
    end
    for _, bag in ipairs(bags) do
        for slot = 1, ContainerSlots(bag) do add(ContainerLink(bag, slot)) end
    end
    if C_MountJournal and C_MountJournal.GetMountIDs then
        for _, mid in ipairs(C_MountJournal.GetMountIDs() or {}) do
            local name, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mid)
            if isCollected and WatchedName(name) then owned[name] = true end
        end
    end
end

-- ------------------------------------------------------------
-- Statistics (Forever's Statistics window; not on Classic Era): the
-- game's own per-character counters, like duels won. Goals that use
-- them carry `needs = "stats"` and are hidden where the API is missing.
-- Values come back as text: "--" for none, "533", "292 (Humanoid)", or
-- money with coin icons ("5|T...GoldIcon...|t 56|T...SilverIcon...|t").
-- ------------------------------------------------------------
function FGT.HasStats() return GetStatisticsCategoryList ~= nil and GetStatistic ~= nil end

function FGT.StatNumber(q)
    q = tostring(q or "")
    if q:find("Icon") then -- money, in copper
        local function coin(kind)
            local n = q:match("([%d,]+)%s*|T[^|]*" .. kind .. "Icon")
            return n and tonumber((n:gsub(",", ""))) or 0
        end
        return coin("Gold") * 10000 + coin("Silver") * 100 + coin("Copper")
    end
    local n = q:gsub(",", ""):match("^%s*(%d+)")
    return tonumber(n) or 0
end

-- The watched statistics for the character you're on, by stat ID. The
-- game only lists them by category, so this walks every category; at
-- most once every 10 seconds unless forced.
function FGT.ReadStats(force)
    local watch = WATCH.stats
    if not (watch and FGT.HasStats()) or FGT.loggingOut then return nil end
    local now = GetTime and GetTime() or 0
    if not force and FGT.statsReadAt and now - FGT.statsReadAt < 10 then return nil end
    FGT.statsReadAt = now
    local out = {}
    for _, cat in pairs(GetStatisticsCategoryList() or {}) do
        local num = GetCategoryNumAchievements and GetCategoryNumAchievements(cat) or 0
        for i = 1, num do
            local quantity, _, statID = GetStatistic(cat, i)
            if statID and watch[statID] then out[statID] = FGT.StatNumber(quantity) end
        end
    end
    return out
end

local function RecordCharacter()
    if not ForeverGoalTrackerDB then return end
    local name = UnitName("player")
    if not name or name == "" then return end
    ForeverGoalTrackerDB.characters = ForeverGoalTrackerDB.characters or {}
    local c = ForeverGoalTrackerDB.characters[CharKey()] or {}
    ForeverGoalTrackerDB.characters[CharKey()] = c

    local _, classFile = UnitClass("player")
    local raceFile = UnitRace and select(2, UnitRace("player")) or nil
    c.name     = name
    c.realm    = GetRealmName and GetRealmName() or ""
    c.class    = classFile
    c.race     = raceFile
    c.level    = UnitLevel("player") or 1
    c.xp       = UnitXP and UnitXP("player") or 0
    c.xpMax    = UnitXPMax and UnitXPMax("player") or 0
    c.faction  = UnitFactionGroup and UnitFactionGroup("player") or nil
    c.money    = GetMoney and GetMoney() or 0
    c.lastSeen = time and time() or 0

    c.items = {}
    for id in pairs(WATCH.items) do
        local n = ItemCount(id)
        if n > 0 then c.items[id] = n end
    end
    c.quests = c.quests or {}
    for id in pairs(WATCH.quests) do
        if QuestDone(id) then c.quests[id] = true end
    end
    -- picked up: remembered even after it leaves the log (turned in or
    -- abandoned), since steps never untick
    c.questsTaken = c.questsTaken or {}
    for id in pairs(FGT.QuestsInLog(WATCH.taken)) do c.questsTaken[id] = true end
    c.reps = c.reps or {}
    local known = KnownFactions()
    for fid in pairs(WATCH.factions) do
        if known == nil or known[fid] then
            local standing, value = FactionStanding(fid)
            if standing then c.reps[fid] = { standing = standing, value = value } end
        else
            c.reps[fid] = nil -- never met: don't trust the default "Neutral"
        end
    end
    c.skills = SkillRanks()

    -- PvP: best of current and highest-ever rank (1..14), lifetime HKs.
    local ok = pcall(function()
        local best = 0
        if UnitPVPRank and GetPVPRankInfo then
            local _, n = GetPVPRankInfo(UnitPVPRank("player"))
            best = math.max(best, n or 0)
        end
        if GetPVPLifetimeStats then
            local hk, _, highest = GetPVPLifetimeStats()
            c.hk = math.max(c.hk or 0, hk or 0)
            if highest and GetPVPRankInfo then
                local _, n = GetPVPRankInfo(highest)
                best = math.max(best, n or 0)
            end
        end
        c.pvpRank = math.max(c.pvpRank or 0, best)
    end)
    c.owned = c.owned or {}
    ScanOwnedNames(c.owned)

    -- Social: ever in a guild, and the most friends seen on the list (both
    -- remembered: guild and friend data can arrive late after login).
    -- Not during logout (see PLAYER_LOGOUT).
    if not FGT.loggingOut then pcall(function()
        if IsInGuild and IsInGuild() then c.guilded = true end
        local friends = (C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetNumFriends())
            or (GetNumFriends and GetNumFriends()) or 0
        c.friends = math.max(c.friends or 0, friends or 0)
    end) end

    -- statistics (Forever): counters only grow, so keep the highest seen
    local ok2, stats = pcall(FGT.ReadStats, FGT.forceStats)
    FGT.forceStats = nil
    if ok2 and stats then
        c.stats = c.stats or {}
        for id, v in pairs(stats) do c.stats[id] = math.max(c.stats[id] or 0, v) end
    end
end

-- Exact level including the fraction of the current level's XP, so a
-- character at 34 and halfway to 35 counts as 34.5.
local function PreciseLevel(c)
    local lvl = c.level or 0
    if lvl >= MAX_LEVEL then return MAX_LEVEL end
    if c.xpMax and c.xpMax > 0 then
        lvl = lvl + math.min(0.999, (c.xp or 0) / c.xpMax)
    end
    return lvl
end

-- Highest character of a class: returns the record plus all records
-- of that class sorted highest first (for the tooltip).
local function BestOfClass(classFile)
    local list = {}
    for _, c in pairs(ForeverGoalTrackerDB and ForeverGoalTrackerDB.characters or {}) do
        if c.class == classFile then table.insert(list, c) end
    end
    table.sort(list, function(a, b) return PreciseLevel(a) > PreciseLevel(b) end)
    return list[1], list
end

-- A goal step that is driven by data instead of a manual checkbox.
local function IsAutoStep(entry)
    return type(entry) == "table" and entry.autoClass ~= nil
end

local function AutoStepFraction(entry)
    local best = BestOfClass(entry.autoClass)
    if not best then return 0 end
    return PreciseLevel(best) / MAX_LEVEL
end

-- ------------------------------------------------------------
-- Rule checks. A rule is satisfied if ANY of its conditions is met on
-- ANY character in the roster (items are summed across characters).
-- ------------------------------------------------------------
local STANDING = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }

local function Roster()
    return (ForeverGoalTrackerDB and ForeverGoalTrackerDB.characters) or {}
end

-- A rule with forRace only looks at characters of that race (epic
-- racial mounts: the Dwarf trains, saves and buys the ram).
local function RosterFor(rule)
    if not (rule and (rule.forRace or rule.forFaction)) then return Roster() end
    local out = {}
    for k, c in pairs(Roster()) do
        if (not rule.forRace or c.race == rule.forRace)
            and (not rule.forFaction or c.faction == rule.forFaction) then
            out[k] = c
        end
    end
    return out
end

-- A step that doesn't apply to you: the epic mount's Exalted step is
-- hidden (and left out of every count) while you play that race, who
-- can buy the mount without the reputation.
function FGT.PieceSkipped(piece)
    local race = type(piece) == "table" and piece.skipIfRace
    return race and UnitRace ~= nil and select(2, UnitRace("player")) == race or false
end

local function ItemTotal(ids, roster)
    local total = 0
    for _, c in pairs(roster or Roster()) do
        for _, id in ipairs(ids) do
            total = total + ((c.items and c.items[id]) or 0)
        end
    end
    return total
end

local function BestRep(fid, roster)
    local bestS, bestV
    for _, c in pairs(roster or Roster()) do
        local r = c.reps and c.reps[fid]
        if r and (not bestS or r.standing > bestS or (r.standing == bestS and r.value > bestV)) then
            bestS, bestV = r.standing, r.value
        end
    end
    return bestS, bestV
end

local function OwnsName(test, roster)
    for _, c in pairs(roster or Roster()) do
        for name in pairs(c.owned or {}) do
            if test(name) then return true end
        end
    end
    return false
end

local function RuleMet(rule)
    if not rule then return false end
    local roster = RosterFor(rule)
    if rule.level then
        for _, c in pairs(roster) do if (c.level or 0) >= rule.level then return true, "level " .. rule.level .. " (" .. tostring(c.name) .. ")" end end
    end
    if rule.raceLevel then
        for _, c in pairs(roster) do
            if c.race == rule.raceLevel.race and (c.level or 0) >= rule.raceLevel.level then return true, "raceLevel " .. c.race end
        end
    end
    if rule.race then
        for _, c in pairs(roster) do if c.race == rule.race then return true, "race " .. c.race end end
    end
    if rule.item and ItemTotal(AsList(rule.item), roster) >= (rule.count or 1) then return true, "item x" .. ItemTotal(AsList(rule.item), roster) end
    for _, id in ipairs(AsList(rule.quest)) do
        for _, c in pairs(roster) do if c.quests and c.quests[id] then return true, "quest " .. id end end
    end
    for _, id in ipairs(AsList(rule.questTaken)) do
        for _, c in pairs(roster) do
            if (c.questsTaken and c.questsTaken[id]) or (c.quests and c.quests[id]) then
                return true, "quest taken " .. id
            end
        end
    end
    if rule.rep then
        for _, fid in ipairs(AsList(rule.rep.faction)) do
            local st, val = BestRep(fid, roster)
            if st and (st > rule.rep.standing or (st == rule.rep.standing and val >= (rule.rep.value or 0))) then
                return true, string.format("rep %d standing=%d value=%s", fid, st, tostring(val))
            end
        end
    end
    if rule.boss then
        for _, want in ipairs(AsList(rule.boss)) do
            local w = want:lower()
            for _, c in pairs(roster) do
                for killed in pairs(c.bosses or {}) do
                    if killed:lower():find(w, 1, true) then return true, "boss " .. killed end
                end
            end
        end
    end
    if rule.skill then
        for _, c in pairs(roster) do
            if c.skills and (c.skills[rule.skill.name] or 0) >= rule.skill.rank then return true, "skill " .. rule.skill.name end
        end
    end
    if rule.money then
        for _, c in pairs(roster) do if (c.money or 0) >= rule.money then return true, "money" end end
    end
    if rule.pvpRank then
        for _, c in pairs(roster) do if (c.pvpRank or 0) >= rule.pvpRank then return true, "pvp rank " .. c.pvpRank end end
    end
    if rule.hk then
        for _, c in pairs(roster) do if (c.hk or 0) >= rule.hk then return true, "hk " .. c.hk end end
    end
    if rule.guild then
        for _, c in pairs(roster) do if c.guilded then return true, "guild (" .. tostring(c.name) .. ")" end end
    end
    if rule.friends then
        for _, c in pairs(roster) do if (c.friends or 0) >= rule.friends then return true, "friends " .. c.friends end end
    end
    if rule.stat then
        for _, c in pairs(roster) do
            local v = c.stats and c.stats[rule.stat.id] or 0
            if v >= rule.stat.value then return true, "stat " .. rule.stat.id .. " = " .. v end
        end
    end
    for _, want in ipairs(AsList(rule.owned)) do
        if OwnsName(function(n) return n:find(want, 1, true) ~= nil end, roster) then return true, "owned" end
    end
    for _, pat in ipairs(AsList(rule.ownedPattern)) do
        if OwnsName(function(n) return n:find(pat) ~= nil end, roster) then return true, "ownedPattern" end
    end
    return false
end
FGT.StepRuleMet = RuleMet -- prerequisite evidence uses the same roster rules

-- Short live readout for a step row: text, plus current/max when the
-- step has a count worth drawing as a bar.
local function RuleReadout(rule)
    if not rule then return nil end
    local roster = RosterFor(rule)
    if rule.item and rule.count and rule.count > 1 then
        local have = ItemTotal(AsList(rule.item), roster)
        return string.format("%d / %d", math.min(have, rule.count), rule.count), math.min(have, rule.count), rule.count
    end
    if rule.rep then
        local best
        for _, fid in ipairs(AsList(rule.rep.faction)) do
            local st = BestRep(fid, roster)
            if st and (not best or st > best) then best = st end
        end
        if best then return STANDING[best] or "?" end
        return "not met yet"
    end
    if rule.skill then
        local best = 0
        for _, c in pairs(roster) do best = math.max(best, (c.skills and c.skills[rule.skill.name]) or 0) end
        return string.format("%d / %d", best, rule.skill.rank), math.min(best, rule.skill.rank), rule.skill.rank
    end
    if rule.hk then
        local best = 0
        for _, c in pairs(roster) do best = math.max(best, c.hk or 0) end
        return string.format("%d / %d", math.min(best, rule.hk), rule.hk), math.min(best, rule.hk), rule.hk
    end
    if rule.pvpRank then
        local best = 0
        for _, c in pairs(roster) do best = math.max(best, c.pvpRank or 0) end
        return string.format("Rank %d / %d", best, rule.pvpRank), math.min(best, rule.pvpRank), rule.pvpRank
    end
    if rule.friends then
        local best = 0
        for _, c in pairs(roster) do best = math.max(best, c.friends or 0) end
        return string.format("%d / %d", math.min(best, rule.friends), rule.friends), math.min(best, rule.friends), rule.friends
    end
    if rule.stat then
        local best, want = 0, rule.stat.value
        for _, c in pairs(roster) do best = math.max(best, c.stats and c.stats[rule.stat.id] or 0) end
        return string.format("%d / %d", math.min(best, want), want), math.min(best, want), want
    end
    if rule.money then
        local best = 0
        for _, c in pairs(roster) do best = math.max(best, c.money or 0) end
        local g, goal = math.floor(best / 10000), math.floor(rule.money / 10000)
        return string.format("%dg / %dg", math.min(g, goal), goal), math.min(g, goal), goal
    end
    return nil
end

local function DescribeRule(rule)
    local parts = {}
    local function itemName(id)
        local n = FGT.ItemInfo(id)
        return n or ("item " .. id)
    end
    if rule.level then table.insert(parts, "any character reaches level " .. rule.level) end
    if rule.raceLevel then table.insert(parts, "a " .. rule.raceLevel.race .. " character reaches " .. rule.raceLevel.level) end
    if rule.item then
        local ids = AsList(rule.item)
        table.insert(parts, ((rule.count or 1) > 1 and ("you hold " .. rule.count .. "x ") or "you own ") .. itemName(ids[1]))
    end
    if rule.quest then table.insert(parts, "the quest is turned in") end
    if rule.questTaken then table.insert(parts, "you pick up the quest") end
    if rule.rep then
        table.insert(parts, "reputation reaches " .. (STANDING[rule.rep.standing] or "?")
            .. ((rule.rep.value or 0) > 0 and (" " .. rule.rep.value) or ""))
    end
    if rule.race then table.insert(parts, "you have a " .. rule.race .. " character") end
    if rule.boss then
        table.insert(parts, "you defeat " .. AsList(rule.boss)[1] .. " with the addon running")
    end
    if rule.skill then table.insert(parts, rule.skill.name .. " reaches " .. rule.skill.rank) end
    if rule.money then table.insert(parts, "a character has " .. math.floor(rule.money / 10000) .. " gold") end
    if rule.pvpRank then table.insert(parts, "your PvP rank (current or highest ever) reaches " .. rule.pvpRank) end
    if rule.hk then table.insert(parts, "a character reaches " .. rule.hk .. " lifetime honorable kills") end
    if rule.guild then table.insert(parts, "a character joins a guild") end
    if rule.friends then table.insert(parts, "a character has " .. rule.friends .. " friends on their friends list") end
    if rule.stat then
        table.insert(parts, "a character's " .. (rule.stat.what or "statistic") .. " reaches " .. rule.stat.value
            .. " (from the Statistics window)")
    end
    if rule.forRace then table.insert(parts, "(" .. rule.forRace .. " characters only)") end
    if rule.forFaction then table.insert(parts, "(" .. rule.forFaction .. " characters only)") end
    if rule.owned or rule.ownedPattern then table.insert(parts, "it shows up in your bags, gear or mount collection") end
    return table.concat(parts, ", or ")
end

-- Ticks every step whose rule is met. Never unticks: items get
-- consumed (the Eye of Sulfuras disappears into the mace), so once a
-- step has been seen done it stays done. A goal's completeWith rule
-- (owning the final reward) ticks the whole goal.
local function ApplyAutoRules()
    if not ForeverGoalTrackerDB then return 0 end
    if ForeverGoalTrackerDB.demoBackup then return 0 end -- demo mode: keep the staged progress as is
    local changed = 0
    -- Every automatic tick logs why (saved with the addon data), so a
    -- wrong tick can be traced to the rule and the numbers behind it.
    ForeverGoalTrackerDB.autoLog = ForeverGoalTrackerDB.autoLog or {}
    local function mark(goalId, key, why)
        if not IsStepDone(goalId, key) then
            SetStepDone(goalId, key, true)
            changed = changed + 1
            ForeverGoalTrackerDB.autoLog[goalId .. ":" .. tostring(key)] =
                (why or "?") .. " | " .. (date and date("%Y-%m-%d %H:%M:%S") or "")
        end
    end
    for _, goal in ipairs(FGT.goals) do
        if not goal.libraryOnly then
        local all = goal.completeWith and (RuleMet(goal.completeWith)) or false
        -- Steps already ticked are skipped: they can never untick, and
        -- re-checking hundreds of them on every bag change only made
        -- throwaway garbage.
        if goal.steps then
            for i, entry in ipairs(goal.steps) do
                if IsStepDone(goal.id, i) then
                    -- nothing to do
                elseif all then
                    mark(goal.id, i, "completeWith")
                elseif type(entry) == "table" and not entry.autoClass and entry.auto then
                    local met, why = RuleMet(entry.auto)
                    if met then mark(goal.id, i, why) end
                end
            end
        end
        for si, section in ipairs(goal.sections or {}) do
            for pi, piece in ipairs(section.pieces) do
                local met, why = false, nil
                local pd, pt = FGT.PieceProgress(goal.id, si, pi, piece)
                if not all and pd < pt then
                    met, why = RuleMet(piece.auto)
                end
                if all or met then
                    mark(goal.id, PieceKey(si, pi), all and "completeWith" or why)
                    -- the materials went into the piece, so they're done too
                    -- (Tier 3 only; mount tasks have no materials)
                    for mi in ipairs(piece.materials) do mark(goal.id, MaterialKey(si, pi, mi), "piece owned") end
                end
            end
        end
        end
    end
    return changed
end

local function GoalProgress(goal)
    -- Level-tracked goals count levels, not checkboxes: 9 classes x 60.
    if goal.autoLevels then
        local done, total = 0, 0
        for i, entry in ipairs(goal.steps) do
            if PartSelected(goal, i) then
            total = total + MAX_LEVEL
            if IsAutoStep(entry) then
                done = done + math.floor(AutoStepFraction(entry) * MAX_LEVEL + 1e-6)
            end
            end
        end
        return done, total
    end
    if goal.sections then
        local done, total = 0, 0
        for si, section in ipairs(goal.sections) do
            if PartSelected(goal, si) then
                for pi, piece in ipairs(section.pieces) do
                    local d, t = FGT.PieceProgress(goal.id, si, pi, piece)
                    done, total = done + d, total + t
                end
            end
        end
        return done, total
    end

    local done, total = 0, 0
    for i = 1, #goal.steps do
        if PartSelected(goal, i) and not FGT.PieceSkipped(goal.steps[i]) then
            total = total + 1
            if IsStepDone(goal.id, i) then
                done = done + 1
            end
        end
    end
    return done, total
end

FGT.GoalProgress = GoalProgress

-- Section-level (one class's set) progress, used by the Tier 3 header rows.
local function SectionProgress(goal, si, section)
    local done, total = 0, 0
    for pi, piece in ipairs(section.pieces) do
        local d, t = FGT.PieceProgress(goal.id, si, pi, piece)
        done, total = done + d, total + t
    end
    return done, total
end

-- Overall progress is the average of every goal's percentage, so a
-- 540-level goal doesn't drown out a 7-step one. Returned as
-- (points, 1000 * goals) to keep the bar math simple.
local function OverallProgress()
    local sum, count = 0, 0
    for _, g in ipairs(ActiveGoals()) do
        local d, t = GoalProgress(g)
        if t > 0 then sum = sum + d / t end
        count = count + 1
    end
    return math.floor(sum * 1000 + 0.5), count * 1000
end

-- How many whole goals (not just steps) are fully checked off.
local function CountGoalsComplete()
    local complete = 0
    for _, g in ipairs(ActiveGoals()) do
        local d, t = GoalProgress(g)
        if t > 0 and d == t then
            complete = complete + 1
        end
    end
    return complete
end

-- The first step still to do, in guide order, as display text (nil when
-- the goal is finished). Group goals only look at the parts you chose;
-- when several sections are chosen the section name leads ("Troll: ...").
function FGT.NextStep(goal)
    if goal.sections then
        local chosen = FGT.SelectedPartCount(goal)
        for si, section in ipairs(goal.sections) do
            if PartSelected(goal, si) then
                for pi, piece in ipairs(section.pieces) do
                    local d, t = FGT.PieceProgress(goal.id, si, pi, piece)
                    if d < t then
                        local text = FGT.StepText(piece.text or piece.name)
                        if chosen > 1 then text = section.name:gsub(" %- .*", "") .. ": " .. text end
                        return text
                    end
                end
            end
        end
        return nil
    end
    for i, entry in ipairs(goal.steps) do
        if PartSelected(goal, i) and not FGT.PieceSkipped(entry) then
            local text = type(entry) == "table" and entry.text or entry
            if IsAutoStep(entry) then
                if AutoStepFraction(entry) < 1 then return text .. " to level " .. MAX_LEVEL end
            elseif not IsStepDone(goal.id, i) then
                return FGT.StepText(text)
            end
        end
    end
    return nil
end

-- "12 of 18 steps done", or "3 of 9 classes at 60" for the leveling goal.
function FGT.StepCountText(goal)
    if goal.autoLevels then
        local n, at60 = 0, 0
        for i, entry in ipairs(goal.steps) do
            if PartSelected(goal, i) then
                n = n + 1
                if AutoStepFraction(entry) >= 1 then at60 = at60 + 1 end
            end
        end
        return string.format("%d of %d classes at %d", at60, n, MAX_LEVEL)
    end
    local d, t = GoalProgress(goal)
    return string.format("%d of %d steps done", d, t)
end

-- "Oct 6, 2026" for a saved completion time, or nil.
function FGT.CompletedOn(goal)
    local DB = ForeverGoalTrackerDB
    local t = DB and DB.goalDates and DB.goalDates[goal.id]
    if not t then return nil end
    return date("%b ", t) .. tonumber(date("%d", t)) .. date(", %Y", t)
end

-- Convert a 0-1 r,g,b table into a "RRGGBB" hex string for inline
-- |cffRRGGBB color codes in font strings.
local function HexColor(c)
    return string.format("%02x%02x%02x",
        math.floor((c[1] or 1) * 255 + 0.5),
        math.floor((c[2] or 1) * 255 + 0.5),
        math.floor((c[3] or 1) * 255 + 0.5))
end

-- ============================================================
-- Small helpers
-- ============================================================
local function Flat(parent, r, g, b, a)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture("Interface\\Buttons\\WHITE8x8")
    t:SetVertexColor(r, g, b, a or 1)
    return t
end

-- Line height across the type scale, as a multiple of the font size.
-- WoW draws a line at the font's size, and SetSpacing adds the rest
-- between wrapped lines.
FGT.LINE_HEIGHT = 1.2
function FGT.SetLineHeight(fs, size)
    fs:SetSpacing(math.floor(size * (FGT.LINE_HEIGHT - 1) + 0.5))
end

-- Steps read as checklist items, so they're shown without a closing
-- period (periods between sentences inside a step stay).
function FGT.StepText(s)
    return FGT.LinkText((tostring(s or ""):gsub("%.%s*$", "")))
end

-- ============================================================
-- Goal links: "{att_naxx:attuned to Naxxramas}" in step or tip text
-- becomes gold, clickable text that offers to track that goal. Only
-- goals that exist in the catalog become links; anything else shows as
-- plain text. Aliases pick a goal per faction.
-- ============================================================
FGT.LINK_ALIAS = {
    att_ony = function() return UnitFactionGroup("player") == "Horde" and "att_ony_horde" or "att_ony_ally" end,
    rep_ambassador = function() return UnitFactionGroup("player") == "Horde" and "rep_ambassador_horde" or "rep_ambassador_ally" end,
}

function FGT.GoalById(id)
    if not FGT.goalIndex then
        FGT.goalIndex = {}
        for _, g in ipairs(FGT.goals) do FGT.goalIndex[g.id] = g end
    end
    return FGT.goalIndex[id]
end

FGT.GOAL_HEX = "cc9e29"           -- goal links: the progress bar's deep gold (Karl)
FGT.GOAL_RGB = { 0.80, 0.62, 0.16 }

-- Goal link text as a metallic gold gradient (Karl, in place of the
-- moving shine): amber at both ends, bright gold in the middle. Each run
-- of one color is closed with |r (the game keeps a color stack).
do
    -- center: where the bright gold sits, 0 = first letter, 1 = last
    -- (default the middle); it glides left and right (the ticker below)
    -- the progress bar's golds (Karl): deep gold at rest, its bright gold
    -- where the glow passes. W: how far the glow blooms
    local EDGE, MID, W = FGT.GOAL_RGB, { 1.00, 0.91, 0.45 }, 0.8
    function FGT.GoldGradient(label, center)
        center = center or 0.5
        local chars = {}
        for c in label:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = c end
        local n, out, last = #chars, {}, nil
        for i, c in ipairs(chars) do
            local t = n > 1 and (i - 1) / (n - 1) or 0.5
            local d = math.min(1, math.abs(t - center) / W)
            local k = math.floor((math.cos(d * math.pi) + 1) / 2 * 8 + 0.5) / 8 -- steps, so runs share a color
            local hex = string.format("%02x%02x%02x",
                (EDGE[1] + (MID[1] - EDGE[1]) * k) * 255 + 0.5,
                (EDGE[2] + (MID[2] - EDGE[2]) * k) * 255 + 0.5,
                (EDGE[3] + (MID[3] - EDGE[3]) * k) * 255 + 0.5)
            if hex ~= last then
                if last then out[#out + 1] = "|r" end
                out[#out + 1] = "|cff" .. hex
                last = hex
            end
            out[#out + 1] = c
        end
        if last then out[#out + 1] = "|r" end
        return table.concat(out)
    end
end

function FGT.LinkText(s)
    -- {item:ID:name}: an item named in a tip (or a step that doesn't track
    -- it) links like the step items do (FGT.ItemTag, further down)
    s = (s:gsub("{item:(%d+):([^}]+)}", function(id, label)
        return FGT.ItemTag and FGT.ItemTag(tonumber(id), label) or label
    end))
    s = (s:gsub("{([%w_]+):([^}]+)}", function(id, label)
        local alias = FGT.LINK_ALIAS[id]
        if alias then id = alias() end
        if not FGT.GoalById(id) then return label end
        -- amber (Karl): apart from the bright yellow of quest links
        -- (the label stays plain here: the ticker paints the moving gradient)
        return "|cff" .. FGT.GOAL_HEX .. "|Hfgtgoal:" .. id .. "|h" .. label .. "|h|r"
    end))
    -- then quest names, then NPC names (below)
    if FGT.LinkQuests then s = FGT.LinkQuests(s) end
    return FGT.LinkNpcs and FGT.LinkNpcs(s) or s
end

-- ============================================================
-- Goal link shine (Karl): a slow band of light sweeps across gold goal
-- links in steps and tips, like the border comets. A font string can't
-- animate part of its text, so the link's letters are redrawn in
-- brighter gold as the band passes. FGT.Shimmer(fs) wraps a font
-- string's SetText/GetText so the rest of the code only ever sees the
-- plain text. Paused while the mouse is on the text (tooltips stay
-- steady), off with Celebrations off; finished steps' faded links
-- don't match the gold, so they don't shine.
-- ============================================================
do
    local list = {}
    local GOLD, HI = FGT.GOAL_RGB, { 1, 0.98, 0.9 } -- amber to near white
    local PERIOD, SWEEP, BAND = 4, 1.1, 2.5 -- seconds per cycle, seconds of sweep, half-width in letters

    local function Hex(k)
        return string.format("%02x%02x%02x",
            (GOLD[1] + (HI[1] - GOLD[1]) * k) * 255 + 0.5,
            (GOLD[2] + (HI[2] - GOLD[2]) * k) * 255 + 0.5,
            (GOLD[3] + (HI[3] - GOLD[3]) * k) * 255 + 0.5)
    end
    local function ShineLabel(label, phase)
        local chars = {}
        for c in label:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = c end
        local pos = phase * (#chars + 2 * BAND) - BAND
        -- each run of one color is closed with |r: the game keeps a stack
        -- of colors, and unclosed runs let the gold spill past the link
        local out, last = {}, nil
        for i, c in ipairs(chars) do
            local d = math.abs(i - pos)
            local k = d < BAND and (math.cos(d / BAND * math.pi) + 1) / 2 or 0
            local hex = Hex(math.floor(k * 10 + 0.5) / 10) -- steps, so runs share a color
            if hex ~= last then
                if last then out[#out + 1] = "|r" end
                out[#out + 1] = "|cff" .. hex
                last = hex
            end
            out[#out + 1] = c
        end
        if last then out[#out + 1] = "|r" end
        return table.concat(out)
    end
    -- the scanning gradient: the bright gold glides from one end of the
    -- link to the other and back, easing at each end (Karl)
    local SCAN = 8.5 -- seconds for a full left-right-left loop
    local function Scan(base, center)
        return (base:gsub("|cff" .. FGT.GOAL_HEX .. "|Hfgtgoal:([^|]+)|h(.-)|h|r", function(id, label)
            return "|cff" .. FGT.GOAL_HEX .. "|Hfgtgoal:" .. id .. "|h" .. FGT.GoldGradient(label, center) .. "|h|r"
        end))
    end
    FGT.ScanText = Scan -- (tools/check.py)
    local function Shine(base, phase)
        return (base:gsub("|cff" .. FGT.GOAL_HEX .. "|Hfgtgoal:([^|]+)|h(.-)|h|r", function(id, label)
            return "|cff" .. FGT.GOAL_HEX .. "|Hfgtgoal:" .. id .. "|h" .. ShineLabel(label, phase) .. "|h|r"
        end))
    end

    FGT.ShineText = Shine -- (tools/check.py)

    FGT.itemFade, FGT.linkPrevHex = {}, {} -- (see Fade below and FGT.LinkItemName)

    -- where the bright gold of goal links sits right now: an eased
    -- ping-pong, a little past both ends; in the middle with Celebrations off
    local function Center()
        if FGT.Setting("celebrations") == "off" then return 0.5 end
        return 0.5 - 0.6 * math.cos(2 * math.pi * GetTime() / SCAN)
    end

    -- item links whose details just arrived ease from the color they were
    -- drawn in to their real one (Karl: no snap). FGT.itemFade[id] =
    -- { t0, from hex }, set by the GET_ITEM_INFO_RECEIVED redraw.
    local finished = {}
    local function Fade(text, now)
        for id, f in pairs(FGT.itemFade) do
            local p = math.max(0, math.min(1, (now - f[1]) / 0.5))
            if p >= 1 then finished[id] = true end
            local e = 1 - (1 - p) ^ 2
            text = text:gsub("|cff(%x%x%x%x%x%x)(|Hitem:" .. id .. "|h)", function(hex, link)
                local out = ""
                for k = 1, 5, 2 do
                    local a, b = tonumber(f[2]:sub(k, k + 1), 16), tonumber(hex:sub(k, k + 1), 16)
                    out = out .. string.format("%02x", math.floor(a + (b - a) * e + 0.5))
                end
                return "|cff" .. out .. link
            end)
        end
        return text
    end

    -- what a text actually shows: goal links in their scanning gold, item
    -- links mid-fade. Used both when the text is set (so the very first
    -- frame is already right: setting the plain text and painting it a tick
    -- later flashed the final color, Karl) and by the ticker below.
    local function Paint(base, center, now)
        if type(base) ~= "string" then return base end
        local out = base
        if base:find("|Hfgtgoal:", 1, true) then out = Scan(out, center) end
        if next(FGT.itemFade) and base:find("|Hitem:", 1, true) then out = Fade(out, now) end
        return out
    end

    function FGT.Shimmer(fs)
        local set, get = fs.SetText, fs.GetText
        fs.fgtSet = set
        fs.SetText = function(self, t)
            self.fgtBase = t
            local shown = Paint(t, Center(), GetTime())
            self.fgtShown = shown
            set(self, shown)
        end
        fs.GetText = function(self)
            if self.fgtBase ~= nil then return self.fgtBase end
            return get(self)
        end
        table.insert(list, fs)
    end

    local ticker = CreateFrame("Frame")
    local acc = 0
    ticker:SetScript("OnUpdate", function(_, elapsed)
        -- every frame while an item link is fading (smooth), else 20 a second
        acc = acc + elapsed
        if acc < 0.05 and not next(FGT.itemFade) then return end
        acc = 0
        local center, now = Center(), GetTime()
        -- the open goal link card's title scans too (Karl)
        local L = FGT.linkCard
        if L and L:IsShown() and L.goal then
            local want = FGT.GoldGradient(L.goal.name, center)
            if want ~= L.nameShown then
                L.nameShown = want
                L.name:SetText(want)
            end
        end
        -- a goal link's tooltip title shines along with the links
        local tip = FGT.tipShine
        if tip then
            local title = _G.GameTooltipTextLeft1
            if not (GameTooltip:IsShown() and GameTooltip:IsOwned(tip.owner)) or not title then
                FGT.tipShine = nil
            else
                local want = FGT.GoldGradient(tip.name, center)
                if want ~= tip.shown then
                    tip.shown = want
                    title:SetText(want)
                end
            end
        end
        for _, fs in ipairs(list) do
            local base = fs.fgtBase
            -- never redraw under the cursor while it's on a link: a redraw
            -- rebuilds the link's hover area and the game thinks you left it
            -- (tooltip flicker). Hovering the rest of the text keeps shining.
            local onLink = FGT.overLink and fs:IsMouseOver()
            if type(base) == "string" and not onLink and fs:IsVisible() then
                local want = Paint(base, center, now)
                if want ~= fs.fgtShown then
                    fs.fgtShown = want
                    fs.fgtSet(fs, want)
                end
            end
        end
        for id in pairs(finished) do FGT.itemFade[id] = nil; finished[id] = nil end
    end)
end

-- ============================================================
-- NPC links (Npcs.lua): teal names in steps and tips. Hover shows where
-- they stand, click puts a pin on the map (a TomTom waypoint when TomTom
-- is installed), right-click gives the Wowhead link.
-- ============================================================
do
    local TEAL = "5fd4bd"
    local byId, names
    local function Index()
        if names then return end
        byId, names = {}, {}
        for _, n in ipairs(FGT.NPCS or {}) do
            if not n.forever or FGT.isForever then
                -- Forever's own spot, where it differs
                if FGT.isForever and n.f then
                    n.map, n.x, n.y, n.zone = n.f[1], n.f[2], n.f[3], n.f[4] or n.zone
                end
                byId[n.id] = n
                table.insert(names, { n.name, n.id })
                for _, a in ipairs(n.alias or {}) do table.insert(names, { a, n.id }) end
            end
        end
        -- longest first, so "Vartrus the Ancient" wins over "Vartrus"
        table.sort(names, function(a, b) return #a[1] > #b[1] end)
    end
    function FGT.NpcById(id) Index(); return byId[id] end

    local function Word(c) return c ~= "" and c:find("[%w']") ~= nil end
    function FGT.LinkNpcs(text)
        Index()
        local linked = {}
        for _, e in ipairs(names) do
            local name, id = e[1], e[2]
            if not linked[id] then
                local from = 1
                while true do
                    local s, e2 = text:find(name, from, true)
                    if not s then break end
                    local before, after = text:sub(s - 1, s - 1), text:sub(e2 + 1, e2 + 1)
                    -- whole words only, and never inside another link
                    if not Word(before) and not Word(after)
                        and not text:sub(1, s - 1):find("|H[^|]*|h[^|]*$") then
                        text = text:sub(1, s - 1) .. "|cff" .. TEAL .. "|Hfgtnpc:" .. id .. "|h"
                            .. name .. "|h|r" .. text:sub(e2 + 1)
                        linked[id] = true
                        break
                    end
                    from = e2 + 1
                end
            end
        end
        return text
    end

    local function Coords(n) return string.format("%.1f, %.1f", n.x, n.y) end

    function FGT.HasTomTom() return (TomTom and TomTom.AddWaypoint) and true or false end
    -- the map pins setting: TomTom only when it's installed and not turned
    -- off (a saved "tomtom" falls back to the game map if TomTom is removed)
    function FGT.UseTomTom()
        return FGT.HasTomTom() and FGT.Setting("mapPins") ~= "game"
    end

    -- the clear "why not" line (Karl): no pin inside dungeons, or not
    -- found in WoW Forever yet
    function FGT.NpcNote(n)
        if FGT.isForever and n.missingInForever then
            return "Not found in WoW Forever yet. This spot is from Classic Era."
        end
        if not n.map then return "No map pin: inside a dungeon, where the map can't show it." end
    end
    function FGT.NpcNoteColor(n)
        if FGT.isForever and n.missingInForever then return C.FOREVER_LIGHT[1], C.FOREVER_LIGHT[2], C.FOREVER_LIGHT[3], true end
        return 1, 0.62, 0.45, true
    end

    function FGT.ShowNpcTip(owner, id)
        local n = FGT.NpcById(id)
        if not n then return end
        GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
        GameTooltip:AddLine(n.name, 0.37, 0.83, 0.74)
        if n.tag then GameTooltip:AddLine("<" .. n.tag .. ">", C.INK2[1], C.INK2[2], C.INK2[3]) end
        if n.map then
            GameTooltip:AddLine(n.zone .. "  " .. Coords(n), C.TEXT[1], C.TEXT[2], C.TEXT[3])
            if n.where then GameTooltip:AddLine(n.where, C.INK2[1], C.INK2[2], C.INK2[3], true) end
        elseif n.where then
            GameTooltip:AddLine(n.where, C.TEXT[1], C.TEXT[2], C.TEXT[3], true)
        end
        if FGT.NpcNote(n) then GameTooltip:AddLine(FGT.NpcNote(n), FGT.NpcNoteColor(n)) end
        if n.disguise then
            GameTooltip:AddLine("Found disguised as " .. n.disguise .. (n.wanders and ", who wanders nearby" or "") .. ".",
                C.INK2[1], C.INK2[2], C.INK2[3], true)
        end
        GameTooltip:AddLine(" ")
        if n.map then
            local tomtom = FGT.UseTomTom()
            GameTooltip:AddLine(tomtom and "Shift-click to set a TomTom waypoint." or "Shift-click to show on your map.",
                C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
            GameTooltip:AddLine("Right-click for map and Wowhead options.", C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
        else
            GameTooltip:AddLine("Right-click for its Wowhead link.", C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
        end
        GameTooltip:Show()
    end

    function FGT.ShowNpcOnMap(id)
        local n = FGT.NpcById(id)
        if not n then return end
        if not n.map then
            print(TAG .. n.name .. " can't be shown on the map: " .. ((n.where or "no spot known"):gsub("^%u", string.lower)) .. ".")
            return
        end
        local x, y = n.x / 100, n.y / 100
        local label = n.disguise and (n.name .. " (as " .. n.disguise .. ")") or n.name
        if FGT.UseTomTom() then
            pcall(TomTom.AddWaypoint, TomTom, n.map, x, y,
                { title = label, from = "Forever Goal Tracker", persistent = false, minimap = true, world = true })
            print(TAG .. "TomTom waypoint set: " .. label .. ", " .. n.zone .. " " .. Coords(n) .. ".")
            return
        end
        -- the game's own map pin, where the client has it
        local pinned = false
        if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
            local can = not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(n.map)
            if can then
                pinned = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(n.map, x, y))
                if pinned and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                    pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
                end
            end
        end
        if not (InCombatLockdown and InCombatLockdown()) and OpenWorldMap then pcall(OpenWorldMap, n.map) end
        print(TAG .. (pinned and "map pin set: " or "") .. label .. ", " .. n.zone .. " " .. Coords(n) .. ".")
    end
end

-- ============================================================
-- Quest links (Quests.lua): a quest name in quotes becomes a bright
-- yellow link with the game's gold "!" in front (Karl). Hover shows who
-- starts it and where each of your characters stands; a plain click
-- ticks the step, shift-click puts the name in chat, right-click gives
-- the Wowhead link.
-- ============================================================
do
    local YELLOW, DAILY_BLUE = "fff23a", "5cb8ff"
    -- 15px, nudged 3px down: the icon's art sits high in its square
    local QUEST = "Interface\\GossipFrame\\AvailableQuestIcon"
    local DAILY = "Interface\\GossipFrame\\DailyQuestIcon"
    -- the blue daily "!" where the client has it, else the gold one
    if not (GetFileIDFromPath and GetFileIDFromPath(DAILY)) then DAILY = QUEST end
    local function Icon(path, dim)
        return "|T" .. path .. ":15:15:0:-3" .. (dim and ":32:32:0:32:0:32:120:120:120" or "") .. "|t"
    end
    FGT.QUEST_ICON, FGT.DAILY_ICON = Icon(QUEST), Icon(DAILY)
    -- the icons in front of links, and their greyed copies for finished
    -- steps (StyleCheckRow swaps them)
    FGT.LINK_ICONS = FGT.LINK_ICONS or {}
    table.insert(FGT.LINK_ICONS, { FGT.QUEST_ICON, Icon(QUEST, true) })
    if DAILY ~= QUEST then table.insert(FGT.LINK_ICONS, { FGT.DAILY_ICON, Icon(DAILY, true) }) end
    local order
    function FGT.LinkQuests(text)
        if not text:find("'", 1, true) then return text end
        if not order then
            order = {}
            for key, q in ipairs(FGT.QUESTS or {}) do table.insert(order, { "'" .. q[1] .. "'", key, q[1] }) end
            table.sort(order, function(a, b) return #a[1] > #b[1] end) -- longest first
        end
        for _, e in ipairs(order) do
            local s, e2 = text:find(e[1], 1, true)
            if s and not text:sub(1, s - 1):find("|H[^|]*|h[^|]*$") then
                local daily = FGT.QUESTS[e[2]].daily -- blue, like the game's daily quests (Karl)
                text = text:sub(1, s - 1) .. (daily and FGT.DAILY_ICON or FGT.QUEST_ICON)
                    .. "|cff" .. (daily and DAILY_BLUE or YELLOW) .. "|Hfgtquest:" .. e[2] .. "|h"
                    .. e[3] .. "|h|r" .. text:sub(e2 + 1)
            end
        end
        return text
    end

    -- "Turned in", "In your quest log" or "Picked up" for one character
    local function Status(c, ids, isMe)
        for _, id in ipairs(ids) do
            if c.quests and c.quests[id] then return "Turned in", 0.35, 0.85, 0.35 end
        end
        if isMe then
            local want = {}
            for _, id in ipairs(ids) do want[id] = true end
            if next(FGT.QuestsInLog(want)) then return "In your quest log", 1, 0.95, 0.23 end
        end
        for _, id in ipairs(ids) do
            if c.questsTaken and c.questsTaken[id] then return "Picked up", 1, 0.82, 0.4 end
        end
    end

    function FGT.ShowQuestTip(owner, key)
        local q = FGT.QUESTS and FGT.QUESTS[key]
        if not q then return end
        GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
        if q.daily then
            GameTooltip:AddLine(q[1], 0.36, 0.72, 1)
            GameTooltip:AddLine("Daily quest", 0.36, 0.72, 1)
        else
            GameTooltip:AddLine(q[1], 1, 0.95, 0.23)
        end
        if q.startName then
            -- where the giver stands: their zone, or the instance note
            local npc = q.start and FGT.NpcById and FGT.NpcById(q.start)
            local where = npc and ((npc.map and npc.zone and (" in " .. npc.zone))
                or (npc.where and (" (" .. npc.where:gsub("^%u", string.lower) .. ")"))) or ""
            GameTooltip:AddLine("Starts with " .. q.startName .. where, C.TEXT[1], C.TEXT[2], C.TEXT[3], true)
        end
        if q.startItem then -- "This Item Begins a Quest"
            GameTooltip:AddLine("Starts from an item: |cfff0dcb0" .. q.startItem[2] .. "|r", C.TEXT[1], C.TEXT[2], C.TEXT[3], true)
        end
        GameTooltip:AddLine(" ")
        if q.perClass then
            GameTooltip:AddLine("Every class has its own version of this quest.", C.INK2[1], C.INK2[2], C.INK2[3], true)
        else
            -- your characters, most recently played first
            local list, me = {}, CharKey()
            for k, c in pairs(Roster()) do table.insert(list, { k = k, c = c }) end
            table.sort(list, function(a, b) return (a.c.lastSeen or 0) > (b.c.lastSeen or 0) end)
            local shown = 0
            for _, e in ipairs(list) do
                local label, r, g, b = Status(e.c, q[2], e.k == me)
                if label and shown < 6 then
                    shown = shown + 1
                    local cc = RAID_CLASS_COLORS and e.c.class and RAID_CLASS_COLORS[e.c.class]
                    GameTooltip:AddDoubleLine(e.c.name or e.k, label,
                        cc and cc.r or C.TEXT[1], cc and cc.g or C.TEXT[2], cc and cc.b or C.TEXT[3], r, g, b)
                end
            end
            if shown == 0 then
                GameTooltip:AddLine("None of your characters have started it yet.", C.INK2[1], C.INK2[2], C.INK2[3], true)
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Shift-click to put its name in chat.", C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
        GameTooltip:AddLine("Right-click for its Wowhead link.", C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
        GameTooltip:Show()
    end

    function FGT.QuestChat(key)
        local q = FGT.QUESTS and FGT.QUESTS[key]
        if not q then return end
        if not (ChatEdit_InsertLink and ChatEdit_InsertLink(q[1])) and ChatFrame_OpenChat then
            ChatFrame_OpenChat(q[1])
        end
    end

    function FGT.QuestWowhead(key)
        local q = FGT.QUESTS and FGT.QUESTS[key]
        if not q then return end
        if q[2][1] then
            FGT.OpenWowheadCard("quest", q[2][1], q[1])
        else
            FGT.OpenWowheadCard("search", 0, q[1]) -- per-class quests: a search
        end
    end
end

-- Makes goal links inside a frame's text hoverable and clickable. While
-- the mouse is on a link, FGT.overLink is set so the step under it
-- doesn't tick (ToggleStep checks it).
function FGT.EnableGoalLinks(f)
    if not f.SetHyperlinksEnabled then return end -- very old clients: plain text
    f:SetHyperlinksEnabled(true)
    f:SetScript("OnHyperlinkEnter", function(self, link, text)
        -- an item name in a step (FGT.LinkItemName): the game's item tooltip
        local variantId = tonumber(link:match("^fgtvariants:(%d+)") or "")
        if variantId then
            FGT.overLink = "item"
            FGT.ShowVariantsTip(self, variantId, self.ruleEntry)
            return
        end
        local itemId = tonumber(link:match("^item:(%d+)") or "")
        if itemId then
            FGT.overLink = "item"
            local name = type(text) == "string" and text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1") or nil
            FGT.ShowItemTip(self, itemId, self.ruleEntry, name)
            return
        end
        local npcId = tonumber(link:match("^fgtnpc:(%d+)") or "")
        if npcId then
            FGT.overLink = "npc"
            FGT.ShowNpcTip(self, npcId)
            return
        end
        local questKey = tonumber(link:match("^fgtquest:(%d+)") or "")
        if questKey then
            FGT.overLink = "quest"
            FGT.ShowQuestTip(self, questKey)
            return
        end
        local id = link:match("^fgtgoal:(.+)")
        local goal = id and FGT.GoalById(id)
        if not goal then return end
        FGT.overLink = id
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        local A = FGT.GOAL_RGB -- the ticker paints the link's moving gradient on it
        GameTooltip:AddLine(goal.name, A[1], A[2], A[3])
        GameTooltip:AddLine(IsActive(goal) and "On your tracker. Click to open it." or "Click to track this goal.",
            C.INK2[1], C.INK2[2], C.INK2[3])
        GameTooltip:Show()
        FGT.tipShine = { owner = self, name = goal.name }
    end)
    f:SetScript("OnHyperlinkLeave", function(self)
        FGT.overLink = nil
        GameTooltip:Hide()
        -- back on the rest of a step row: its own tooltip again
        local enter = self.GetScript and self:GetScript("OnEnter")
        if enter and self:IsMouseOver() then enter(self) end
    end)
    f:SetScript("OnHyperlinkClick", function(self, link, text, button)
        GameTooltip:Hide()
        local npcId = tonumber(link:match("^fgtnpc:(%d+)") or "")
        if npcId then
            local n = FGT.NpcById(npcId)
            if button == "RightButton" then
                FGT.OpenWowheadCard("npc", npcId, n and n.name or text, nil, n)
                return
            elseif IsShiftKeyDown() then
                FGT.ShowNpcOnMap(npcId)
                return
            end
        end
        local questKey = tonumber(link:match("^fgtquest:(%d+)") or "")
        if questKey then
            if button == "RightButton" then
                FGT.QuestWowhead(questKey)
                return
            elseif IsShiftKeyDown() then
                FGT.QuestChat(questKey)
                return
            end
        end
        -- a plain click on an NPC, quest or item name ticks the step (below)
        local tick = (npcId or questKey) and true
        -- a mount type: right-click and shift-click use its first color
        local itemId = tonumber(link:match("^item:(%d+)") or link:match("^fgtvariants:(%d+)") or "")
        if itemId then
            if button == "RightButton" and link:find("^fgtvariants:") then
                FGT.OpenVariantsWowhead(itemId)
            elseif button == "RightButton" then
                FGT.OpenWowheadCard("item", itemId, text)
            elseif IsShiftKeyDown() then
                FGT.InsertItemLink(itemId)
            elseif FGT.PreviewItemClick(itemId, button) then
                return
            else
                tick = true
            end
        end
        if tick then
            -- like the rest of the row: the link makes a big part of it
            local click = self.GetScript and self:GetScript("OnClick")
            if click then
                local was = FGT.overLink
                FGT.overLink = nil
                click(self, "LeftButton")
                FGT.overLink = was
            end
            return
        end
        local id = link:match("^fgtgoal:(.+)")
        if id and FGT.OpenLinkCard then FGT.OpenLinkCard(id) end
    end)
end

local function NewFontString(parent, size, flags, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size, flags)
    fs:SetTextColor(r or C.TEXT[1], g or C.TEXT[2], b or C.TEXT[3])
    fs:SetJustifyH("LEFT")
    FGT.SetLineHeight(fs, size)
    return fs
end

-- Cinzel heading in gold with a dark drop shadow (the site's .brand /
-- h2 look). Falls back to the default font if the .ttf can't load.
local function NewTitleString(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if not fs:SetFont(FONT_TITLE, size, "") then
        fs:SetFont(FONT, size, "")
    end
    fs:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3])
    fs:SetShadowColor(0.2, 0.14, 0.02, 1)
    fs:SetShadowOffset(1, -1)
    fs:SetJustifyH("LEFT")
    FGT.SetLineHeight(fs, size)
    return fs
end

-- Flat fill + 1px outline in one call (rows, buttons, chips).
local function Skin(frame, bg, line)
    frame:SetBackdrop(line and BACKDROP_LINED or BACKDROP_SOLID)
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    if line then
        frame:SetBackdropBorderColor(line[1], line[2], line[3], line[4] or 1)
    end
end

-- A small outlined label pill, like the site's .chips.
local function NewChip(parent, size)
    local chip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Skin(chip, { 0.03, 0.03, 0.03, 0.9 }, { 0.26, 0.24, 0.20, 1 })
    chip.text = NewFontString(chip, size or 9, "", C.INK2[1], C.INK2[2], C.INK2[3])
    chip.text:SetPoint("CENTER", 0, 0)
    function chip:SetLabel(text, c)
        self.text:SetText(text)
        if c then self.text:SetTextColor(c[1], c[2], c[3]) end
        self:SetSize(math.ceil(self.text:GetStringWidth()) + 12, (size or 9) + 7)
    end
    return chip
end

-- Horizontal gold line that fades to transparent toward the right (the
-- masthead underline). Uses the ColorMixin SetGradient both Era 1.15
-- and Forever support; a flat line is the fallback.
local function NewFadeLine(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(SOLID)
    t:SetHeight(1)
    -- (remembered like ApplyHGradient's, so the wizard can grey it)
    t.fgtGdir, t.fgtG1, t.fgtG2, t.fgtGa1, t.fgtGa2 = "H", C.GOLD2, C.GOLD2, 1, 0
    local ok = CreateColor and pcall(t.SetGradient, t, "HORIZONTAL",
        CreateColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 1),
        CreateColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 0))
    if not ok then
        t:SetVertexColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 0.6)
    end
    return t
end

-- ============================================================
-- Etched look: dark vertical gradients + WoW's own tooltip border
-- ============================================================
-- Styles are { top, bottom, edge } colors. The border is the game's
-- "UI-Tooltip-Border" (the thin bevelled frame Blizzard uses on
-- tooltips) tinted per style, so everything reads as part of the game.
local ETCH_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"

local STYLE = {
    window   = { top = { 0.105, 0.095, 0.080 }, bottom = { 0.016, 0.016, 0.016 }, edge = { 0.78, 0.61, 0.10, 1 } },
    panel    = { top = { 0.060, 0.057, 0.052 }, bottom = { 0.022, 0.022, 0.022 }, edge = { 0.33, 0.29, 0.20, 1 } },
    row      = { top = { 0.150, 0.142, 0.130 }, bottom = { 0.050, 0.048, 0.045 }, edge = { 0.28, 0.26, 0.22, 1 } },
    rowHover = { top = { 0.225, 0.205, 0.170 }, bottom = { 0.085, 0.078, 0.065 }, edge = { 0.55, 0.47, 0.30, 1 } },
    rowSel   = { top = { 0.380, 0.290, 0.060 }, bottom = { 0.110, 0.080, 0.015 }, edge = { 1.00, 0.82, 0.00, 1 } },
    goldHover = { top = { 0.470, 0.365, 0.085 }, bottom = { 0.155, 0.115, 0.025 }, edge = { 1.00, 0.89, 0.30, 1 } },
    button   = { top = { 0.240, 0.225, 0.200 }, bottom = { 0.080, 0.075, 0.068 }, edge = { 0.42, 0.37, 0.26, 1 } },
    btnHover = { top = { 0.330, 0.300, 0.240 }, bottom = { 0.120, 0.110, 0.090 }, edge = { 0.85, 0.68, 0.20, 1 } },
    danger   = { top = { 0.420, 0.110, 0.090 }, bottom = { 0.140, 0.030, 0.030 }, edge = { 0.62, 0.22, 0.16, 1 } },
    dangerHv = { top = { 0.540, 0.150, 0.120 }, bottom = { 0.190, 0.045, 0.040 }, edge = { 0.90, 0.35, 0.25, 1 } },
    forever  = { top = { 0.040, 0.120, 0.200 }, bottom = { 0.015, 0.040, 0.075 }, edge = { 0.09, 0.36, 0.55, 1 } },
    -- finished goals and parts in the Library ("Complete" button)
    done     = { top = { 0.130, 0.300, 0.080 }, bottom = { 0.040, 0.110, 0.030 }, edge = { 0.31, 0.75, 0.23, 1 } },
    -- a finished goal's Library card: neutral grey under its green wash (Karl)
    doneCard = { top = { 0.115, 0.115, 0.112 }, bottom = { 0.040, 0.040, 0.040 }, edge = { 0.30, 0.30, 0.29, 1 } },
    -- Settings choices you won't hear (game sound or that channel off)
    muted    = { top = { 0.120, 0.118, 0.115 }, bottom = { 0.050, 0.050, 0.050 }, edge = { 0.24, 0.24, 0.23, 1 } },
    mutedSel = { top = { 0.190, 0.180, 0.160 }, bottom = { 0.070, 0.066, 0.060 }, edge = { 0.52, 0.46, 0.32, 1 } },
    -- Blue twins of row / rowHover / rowSel for things new in Forever.
    fRow     = { top = { 0.060, 0.110, 0.180 }, bottom = { 0.020, 0.036, 0.062 }, edge = { 0.09, 0.36, 0.55, 1 } },
    fHover   = { top = { 0.085, 0.160, 0.260 }, bottom = { 0.030, 0.058, 0.095 }, edge = { 0.25, 0.55, 1.00, 1 } },
    fSel     = { top = { 0.070, 0.240, 0.460 }, bottom = { 0.015, 0.075, 0.170 }, edge = { 0.55, 0.78, 1.00, 1 } },
    -- an open group row on a Forever goal: darker than fSel, so it reads as
    -- open without outshining the title (Karl)
    fOpen    = { top = { 0.045, 0.135, 0.260 }, bottom = { 0.012, 0.042, 0.095 }, edge = { 0.40, 0.66, 1.00, 1 } },
}
-- Which blue twin replaces each gold state.
STYLE.foreverTwin = { [STYLE.row] = STYLE.fRow, [STYLE.rowHover] = STYLE.fHover, [STYLE.rowSel] = STYLE.fSel,
    [STYLE.panel] = STYLE.fRow, [STYLE.button] = STYLE.fRow, [STYLE.btnHover] = STYLE.fHover }

-- Vertical gradient on a texture (top color -> bottom color). SetGradient
-- takes (min = bottom, max = top). Falls back to a flat midpoint color.
-- (each gradient remembers what it was given, as plain fields with no new
-- table per call, so the wizard can grey it and put it back: W.Grey)
local function ApplyVGradient(tex, top, bottom, topA, bottomA)
    tex.fgtGdir, tex.fgtG1, tex.fgtG2, tex.fgtGa1, tex.fgtGa2 = "V", top, bottom, topA, bottomA
    local ok = CreateColor and pcall(tex.SetGradient, tex, "VERTICAL",
        CreateColor(bottom[1], bottom[2], bottom[3], bottomA or 1),
        CreateColor(top[1], top[2], top[3], topA or 1))
    if not ok then
        tex:SetVertexColor((top[1] + bottom[1]) / 2, (top[2] + bottom[2]) / 2,
            (top[3] + bottom[3]) / 2, ((topA or 1) + (bottomA or 1)) / 2)
    end
end

-- Horizontal gradient (left color -> right color).
local function ApplyHGradient(tex, left, right, leftA, rightA)
    tex.fgtGdir, tex.fgtG1, tex.fgtG2, tex.fgtGa1, tex.fgtGa2 = "H", left, right, leftA, rightA
    local ok = CreateColor and pcall(tex.SetGradient, tex, "HORIZONTAL",
        CreateColor(left[1], left[2], left[3], leftA or 1),
        CreateColor(right[1], right[2], right[3], rightA or 1))
    if not ok then
        tex:SetVertexColor(right[1], right[2], right[3], ((leftA or 1) + (rightA or 1)) / 2)
    end
end

-- Turns any BackdropTemplate frame into an etched, gradient tile.
-- Re-call frame:SetEtch(style) to switch states (hover, selected...).
local function Etch(frame, style, edgeSize)
    edgeSize = edgeSize or 12
    local inset = math.floor(edgeSize / 4)
    frame:SetBackdrop({ edgeFile = ETCH_EDGE, edgeSize = edgeSize,
        insets = { left = inset, right = inset, top = inset, bottom = inset } })

    frame.etchBg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    frame.etchBg:SetTexture(SOLID)
    frame.etchBg:SetPoint("TOPLEFT", inset, -inset)
    frame.etchBg:SetPoint("BOTTOMRIGHT", -inset, inset)

    -- 1px inner top sheen, the "bevel" catching light.
    frame.etchHi = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    frame.etchHi:SetTexture(SOLID)
    frame.etchHi:SetHeight(1)
    frame.etchHi:SetPoint("TOPLEFT", inset, -inset)
    frame.etchHi:SetPoint("TOPRIGHT", -inset, -inset)
    frame.etchHi:SetVertexColor(1, 0.92, 0.70, 0.07)

    function frame:SetEtch(st)
        -- Things new in Forever wear blue instead of gold in every state.
        if self.foreverNew then st = (self.twin and self.twin[st]) or STYLE.foreverTwin[st] or st end
        ApplyVGradient(self.etchBg, st.top, st.bottom)
        self:SetBackdropBorderColor(st.edge[1], st.edge[2], st.edge[3], st.edge[4] or 1)
    end
    frame:SetEtch(style)
end

-- Large cropped insignia, carved into the card rather than sitting on
-- the text. Upper-left shadow and lower-right light suggest a recess.
-- Client textures avoid adding cached addon artwork for these emblems.
function FGT.AddFactionCardEtch(row, faction)
    if faction ~= "Alliance" and faction ~= "Horde" then return end
    local path = "Interface\\Timer\\" .. faction .. "-Logo"
    if GetFileIDFromPath and not GetFileIDFromPath(path) then return end
    row.factionEtch = {}
    for i, layer in ipairs({
        { C.FACTION_SHADE, 0.32, -1, 1 },
        { C.FACTION_EDGE, 0.10, 1, -1 },
        { C.FACTION_INSET, 0.22, 0, 0 },
    }) do
        local tex = row:CreateTexture(nil, "BACKGROUND", nil, -6 + i)
        tex:SetTexture(path)
        tex:SetDesaturated(true)
        -- 108px graphic, cropped to the card's interior instead of shrunk.
        tex:SetSize(108, 64)
        tex:SetTexCoord(0, 1, 0, 64 / 108)
        tex:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5 + layer[3], -4 + layer[4])
        ApplyHGradient(tex, layer[1], layer[1], layer[2] * 0.04, layer[2])
        row.factionEtch[i] = tex
    end
end

-- Embossed divider (Karl, 2026-10-07): a 1px dark shadow line over a 1px
-- bronze highlight, like the panel borders, so it reads as carved into the
-- panel rather than drawn on it. Bronze, not gold: gold lines compete with
-- the progress bars. Fades in on the left and out to the right. A frame
-- (2px tall) so it can be placed, shown and hidden like a texture.
function FGT.NewEmbossLine(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(2)
    -- shadow, then the brown of the panels' bottom edge (sampled from a
    -- screenshot: about 42, 36, 25), a hair brighter to read mid-panel
    local LINES = { { 0, 0, 0, 0.75 }, { 0.19, 0.16, 0.11, 0.55 } } -- quiet: a groove, not a line (Karl)
    for i, c in ipairs(LINES) do
        local col = { c[1], c[2], c[3] }
        local l, m, r = f:CreateTexture(nil, "ARTWORK"), f:CreateTexture(nil, "ARTWORK"), f:CreateTexture(nil, "ARTWORK")
        for _, t in ipairs({ l, m, r }) do
            t:SetTexture(SOLID)
            t:SetHeight(1)
        end
        local y = -(i - 1)
        l:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y)
        l:SetWidth(24)
        r:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, y)
        r:SetWidth(180)
        m:SetPoint("TOPLEFT", l, "TOPRIGHT")
        m:SetPoint("TOPRIGHT", r, "TOPLEFT")
        ApplyHGradient(l, col, col, 0, c[4])
        m:SetVertexColor(c[1], c[2], c[3], c[4])
        ApplyHGradient(r, col, col, c[4], 0)
    end
    return f
end

-- Subtle dirt texture over a window or panel fill (Karl, 2026-10-07):
-- Media/grime (512px, seamless) repeated at its real size inside the
-- etched border, above the fill and below everything else. alpha sets the
-- strength; offset (0-1) shifts where the tile starts, so panels next to
-- each other don't repeat in step. Only on the big surfaces: cards, rows,
-- buttons, tooltips and Forever blue stay flat.
do
    local GRIME = "Interface\\AddOns\\" .. ADDON .. "\\Media\\grime"
    local TILE = 512
    -- Strongest at the top, fading out downward (Karl: the texture lives
    -- mostly in the header and bleeds a little into the panels, leaving the
    -- lists clean): a body at full strength for `solid` px, then a strip
    -- whose vertex alpha runs to 0 over `fade` px (gradients ignore
    -- SetAlpha, lesson 14), then the rest at a faint floor: just enough
    -- grain to dither the panels' dark gradients, which otherwise show as
    -- bands (Karl). All three share one set of texture coordinates.
    local FLOOR = 0.07
    function FGT.AddGrime(frame, alpha, edgeSize, offset, solid, fade)
        local inset = math.floor((edgeSize or 12) / 4)
        solid, fade = solid or 0, fade or 140
        local body = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
        local strip = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
        local rest = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
        for _, t in ipairs({ body, strip, rest }) do
            t:SetTexture(GRIME, "REPEAT", "REPEAT")
        end
        rest:SetPoint("TOPLEFT", strip, "BOTTOMLEFT")
        rest:SetPoint("BOTTOMRIGHT", -inset, inset)
        rest:SetVertexColor(1, 1, 1, FLOOR)
        body:SetPoint("TOPLEFT", inset, -inset)
        body:SetPoint("TOPRIGHT", -inset, -inset)
        strip:SetPoint("TOPLEFT", body, "BOTTOMLEFT")
        strip:SetPoint("TOPRIGHT", body, "BOTTOMRIGHT")
        body:SetVertexColor(1, 1, 1, alpha)
        ApplyVGradient(strip, { 1, 1, 1 }, { 1, 1, 1 }, alpha, FLOOR)
        offset = offset or 0
        local function Fit()
            local w, h = frame:GetWidth() - 2 * inset, frame:GetHeight() - 2 * inset
            if w <= 0 or h <= 0 then return end
            local s = math.min(solid, h)
            local f = math.max(1, math.min(fade, h - s))
            body:SetHeight(math.max(0.01, s))
            body:SetShown(s > 0)
            strip:SetHeight(f)
            local x0, x1, y0 = offset, offset + w / TILE, offset * 0.6
            body:SetTexCoord(x0, x1, y0, y0 + s / TILE)
            strip:SetTexCoord(x0, x1, y0 + s / TILE, y0 + (s + f) / TILE)
            rest:SetShown(h - s - f > 0)
            rest:SetTexCoord(x0, x1, y0 + (s + f) / TILE, y0 + h / TILE)
        end
        frame:HookScript("OnSizeChanged", Fit)
        Fit()
        frame.grime = body
        return body
    end
end

-- ============================================================
-- WoW Forever status
-- ============================================================
-- Every goal is written from Classic Era data. Whether it exists in
-- Warcraft Forever, and works the same, is only known once it shows up
-- in Wowhead's Forever database (items are hidden there until someone
-- loots one after launch). A goal's `forever` field says what we know:
--   nil          not confirmed yet (the default)
--   "listed"     in Forever's database, but the steps aren't checked
--   "confirmed"  checked: same steps in Forever
--   "new"        only exists in Forever (hidden on Classic Era)
--   "updated"    in Classic too, but Forever changed it (the Viper set's
--                new bonus): marked UPDATED on Forever, plain on Classic Era
-- Both wear the blue theme on Forever; only the word differs (NEW /
-- UPDATED). A goal's `foreverNote` says what's new; it shows in the blue
-- goal-page notice.
FGT.FOREVER_BUG = "Interface\\AddOns\\" .. ADDON .. "\\Media\\forever"
FGT.testNew = {} -- /goals testnew: preview the "new" look (not saved)

function FGT.ForeverStatus(goal)
    if FGT.testNew[goal.id] then return "new" end
    if goal.forever == "updated" then
        return FGT.isForever and "updated" or "confirmed"
    end
    return goal.forever or "unconfirmed"
end

-- "NEW" or "UPDATED" when a goal (or part) gets the blue Forever look,
-- otherwise nil.
function FGT.ForeverWord(goal)
    local s = FGT.ForeverStatus(goal)
    if s == "new" then return "NEW" end
    if s == "updated" then return "UPDATED" end
end

-- One line for tooltips (short) and the goal page notice, or nil when
-- there's nothing to say. Unconfirmed goals only matter on Forever.
function FGT.ForeverNote(goal, short)
    local s = FGT.ForeverStatus(goal)
    if s == "new" or s == "updated" then
        return (not short and goal.foreverNote)
            or (s == "new" and "New in WoW Forever." or "Updated in WoW Forever.")
    end
    if not FGT.isForever then return nil end
    if s == "listed" then
        -- a goal can say what's unconfirmed about it (the PvP sets: the ranks)
        return (not short and goal.foreverNote)
            or "In WoW Forever's database, but the steps aren't confirmed yet. They follow Classic Era and may differ."
    elseif s == "unconfirmed" then
        -- a goal can say more (Tier 1 and 2: removed in Forever)
        return (not short and goal.foreverNote)
            or "Not yet confirmed in WoW Forever. These steps follow Classic Era and may differ."
    end
end

-- Bright Forever-blue dot for font strings ("|T...|t", tinted #408cff).
-- The logo is too small to read at chip size, so labels use the dot.
FGT.FOREVER_DOT = "Interface\\AddOns\\" .. ADDON .. "\\Media\\dot"
-- The dot image carries its own soft glow, so the solid core is about
-- 40% of `size`; the glow also spaces it from the word after it. Nudged
-- down 3px to sit level with capital letters (measured in game).
-- grey: the desaturated dot on finished goals' grey info line (Karl)
function FGT.ForeverDot(size, grey)
    local tint = grey and "125:125:120" or "156:202:255"
    return string.format("|T%s:%d:%d:0:-3:32:32:0:32:0:32:%s|t", FGT.FOREVER_DOT, size, size, tint)
end

-- "<dot>NEW" (or UPDATED) in light Forever blue, after a name.
function FGT.NewTag(word)
    return FGT.ForeverDot(14) .. "|cff9ccaff" .. (word or "NEW") .. "|r"
end

-- True when a goal is new or updated in Forever, or holds a part that is
-- (Epic Racial Mounts and its Skyborne mount). Drives the Library chip.
function FGT.HasForeverNew(goal)
    if FGT.ForeverWord(goal) then return true end
    for _, section in ipairs(goal.sections or {}) do
        if FGT.ForeverWord(section) then return true end
    end
    return false
end

-- Marks a tile (goal card, group header, Library row) as new or updated
-- in Forever: SetEtch then swaps its gold states for the blue twins.
-- Callers re-etch right after. Returns "NEW", "UPDATED" or nil.
function FGT.ApplyForeverLook(frame, goal)
    local word = FGT.ForeverWord(goal)
    frame.foreverNew = word and true or false
    if frame.bar and frame.bar.SetBlue then frame.bar:SetBlue(frame.foreverNew) end
    return word
end

-- A part's row (Library part row, goal page group row). A new part in an
-- older goal (the Skyborne mount) gets the blue look and its NEW tag; every
-- part of an all-new goal (Forever Raid Sets) gets the blue look without
-- the tag, since the goal already says NEW (Karl). Returns the tag word.
function FGT.ApplyPartLook(frame, part, goal)
    local word = FGT.ApplyForeverLook(frame, part)
    if not word and FGT.ForeverWord(goal) then
        frame.foreverNew = true
        if frame.bar and frame.bar.SetBlue then frame.bar:SetBlue(true) end
    end
    return word
end

-- ============================================================
-- Icons, loaded straight from the game's own Interface\Icons files
-- (names from Wowhead). A goal can list fallbacks; the first one the
-- client actually has wins, and the question mark is the last resort.
-- ============================================================
local function ResolveIcon(spec)
    if not spec then return nil end
    local list = type(spec) == "table" and spec or { spec }
    for _, name in ipairs(list) do
        local path = name:find("\\", 1, true) and name or ("Interface\\Icons\\" .. name)
        if not GetFileIDFromPath or GetFileIDFromPath(path) then
            return path
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Square icon slot: black well, 1px quality-colored rim, cropped art
-- (the default icon edge is trimmed like Blizzard's action buttons).
local function NewIcon(parent, size)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(size, size)
    Skin(f, { 0, 0, 0, 1 }, { 0, 0, 0, 1 })
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetPoint("TOPLEFT", 1, -1)
    f.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- soft inner shadow at the bottom of the icon
    f.shade = f:CreateTexture(nil, "OVERLAY")
    f.shade:SetTexture(SOLID)
    f.shade:SetPoint("BOTTOMLEFT", 1, 1)
    f.shade:SetPoint("BOTTOMRIGHT", -1, 1)
    f.shade:SetHeight(math.floor(size * 0.45))
    ApplyVGradient(f.shade, { 0, 0, 0 }, { 0, 0, 0 }, 0, 0.45)
    function f:SetIcon(spec, rim)
        local path = ResolveIcon(spec)
        if path then
            self.tex:SetTexture(path)
            self:Show()
        else
            self:Hide()
        end
        local c = rim or C.GOLD2
        self.rim = c -- (StyleCheckRow greys it on finished steps)
        self:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    end
    return f
end

-- Recessed progress track with a glossy vertical-gradient fill (the
-- XP-bar look): bright gold on top shading to deep amber, green once
-- the goal is complete. The text label sits under the bar's right end.
local function NewBar(parent, height)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetHeight(height)
    Skin(bar, { 0.012, 0.012, 0.012, 1 }, { 0, 0, 0, 1 })

    -- faint lit lip along the bottom edge so the track looks carved in
    local lip = bar:CreateTexture(nil, "BORDER")
    bar.lip = lip
    lip:SetTexture(SOLID)
    lip:SetHeight(1)
    lip:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
    lip:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    lip:SetVertexColor(1, 0.9, 0.6, 0.08)

    -- Fill: deep amber on the left building to blazing gold at the tip.
    bar.fill = bar:CreateTexture(nil, "ARTWORK", nil, 1)
    bar.fill:SetTexture(SOLID)
    bar.fill:SetPoint("TOPLEFT", 1, -1)
    bar.fill:SetPoint("BOTTOMLEFT", 1, 1)

    -- Darkens the lower half so the fill reads as a rounded, lit bar.
    bar.shade = bar:CreateTexture(nil, "ARTWORK", nil, 2)
    bar.shade:SetTexture(SOLID)
    bar.shade:SetAllPoints(bar.fill)
    ApplyVGradient(bar.shade, { 0, 0, 0 }, { 0, 0, 0 }, 0, 0.45)

    -- 1px highlight along the top edge.
    bar.sheen = bar:CreateTexture(nil, "OVERLAY", nil, 1)
    bar.sheen:SetTexture(SOLID)
    bar.sheen:SetPoint("TOPLEFT", bar.fill, "TOPLEFT", 0, 0)
    bar.sheen:SetPoint("TOPRIGHT", bar.fill, "TOPRIGHT", 0, 0)
    bar.sheen:SetHeight(1)
    ApplyHGradient(bar.sheen, { 1, 0.9, 0.6 }, { 1, 1, 0.9 }, 0.05, 0.8)

    -- Hot tip: an additive glow inside the end of the fill, so the bar
    -- is brightest exactly where progress stops (never past it).
    bar.tip = bar:CreateTexture(nil, "OVERLAY", nil, 2)
    bar.tip:SetTexture(SOLID)
    bar.tip:SetBlendMode("ADD")
    bar.tip:SetPoint("TOPRIGHT", bar.fill, "TOPRIGHT", 0, 0)
    bar.tip:SetPoint("BOTTOMRIGHT", bar.fill, "BOTTOMRIGHT", 0, 0)
    ApplyHGradient(bar.tip, { 1.00, 0.85, 0.40 }, { 1.00, 0.95, 0.70 }, 0, 0.75)

    bar.label = NewFontString(parent, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
    bar.label:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    bar.label:SetJustifyH("RIGHT")

    -- Fill and tip colors per look: { fill left, fill right, tip left, tip right }.
    local LOOKS = {
        done = { { 0.08, 0.32, 0.04 }, { 0.55, 1.00, 0.40 } },
        -- new in Forever: deep Forever blue building to light blue
        blue = { { 0.01, 0.12, 0.36 }, { 0.40, 0.70, 1.00 }, { 0.40, 0.70, 1.00 }, { 0.80, 0.92, 1.00 } },
        gold = { { 0.32, 0.18, 0.01 }, { 1.00, 0.86, 0.30 }, { 1.00, 0.85, 0.40 }, { 1.00, 0.95, 0.70 } },
    }
    local function Mix(a, b, p) return { a[1] + (b[1] - a[1]) * p, a[2] + (b[2] - a[2]) * p, a[3] + (b[3] - a[3]) * p } end

    -- Reaching 100% while you watch: the fill slides from gold (or blue)
    -- into green and the bright tip dims out, over 0.6 s, instead of both
    -- switching in one frame (Karl). Gradients ignore SetAlpha, so each
    -- frame redraws them (lesson 14).
    local FADE = 0.6
    local function FadeToDone(self, from)
        local f, d = LOOKS[from], LOOKS.done
        self.fading = 0
        self.fader = self.fader or CreateFrame("Frame", nil, self)
        self.fader:SetScript("OnUpdate", function(fr, elapsed)
            if self.look ~= "done" then -- dropped below 100% meanwhile
                self.fading = nil
                fr:SetScript("OnUpdate", nil)
                return
            end
            self.fading = self.fading + elapsed
            local p = math.min(1, self.fading / FADE)
            local e = 1 - (1 - p) ^ 2 -- ease out
            ApplyHGradient(self.fill, Mix(f[1], d[1], e), Mix(f[2], d[2], e))
            ApplyHGradient(self.tip, f[3], f[4], 0, 0.75 * (1 - e))
            if p >= 1 then
                self.fading = nil
                self.tip:Hide()
                fr:SetScript("OnUpdate", nil)
            end
        end)
    end

    -- Draws the fill at a fraction (0..1). The green "complete" look
    -- only kicks in once the fill has actually arrived at 100%.
    function bar:Render(pct)
        local inner = math.max(0, self:GetWidth() - 2)
        local fillW = math.max(0.01, inner * pct)
        self.fill:SetWidth(fillW)
        local on = pct > 0.0005
        local complete = pct >= 0.9995
        self.fill:SetShown(on)
        self.shade:SetShown(on)
        self.sheen:SetShown(on and height >= 6)
        self.tip:SetWidth(math.min(24, fillW))
        self.tip:SetShown(on and (not complete or self.fading ~= nil))
        local look = complete and "done" or (self.blue and "blue" or "gold")
        if look ~= self.look then
            local from = self.look
            self.look = look
            local L = LOOKS[look]
            if look == "done" and (from == "gold" or from == "blue") and self:IsVisible()
                and not self.instant and FGT.Setting("celebrations") ~= "off" then
                FadeToDone(self, from)
                self.tip:Show()
            else
                self.fading = nil
                if self.fader then self.fader:SetScript("OnUpdate", nil) end
                ApplyHGradient(self.fill, L[1], L[2])
                if L[3] then ApplyHGradient(self.tip, L[3], L[4], 0, 0.75) end
                if look == "done" then self.tip:Hide() end
            end
        end
    end

    -- Blue instead of gold, for goals and parts new in Forever.
    function bar:SetBlue(on)
        on = on and true or false
        if on ~= (self.blue or false) then
            self.blue = on
            if self.cur then self:Render(self.cur) end
        end
    end

    -- Glides toward the target: covers most of the gap quickly, then
    -- eases in (about half a second). Runs only while moving.
    local function Step(self, elapsed)
        local gap = self.target - self.cur
        if math.abs(gap) < 0.001 then
            self.cur = self.target
            self:SetScript("OnUpdate", nil)
            if self.celebrate and self.cur >= 0.9995 then FGT.BarShine(self) end
        else
            self.cur = self.cur + gap * math.min(1, elapsed * 9)
        end
        self:Render(self.cur)
    end

    function bar:SetProgress(done, total, customLabel)
        local pct = total > 0 and math.min(1, done / total) or 0
        self.label:SetText(customLabel or string.format("%d / %d  ·  %d%%", done, total, math.floor(pct * 100 + 0.5)))
        self.target = pct
        if self.shineL then -- a finished shine never lingers into a new glide
            self.shineL:Hide(); self.shineC:Hide(); self.shineR:Hide()
        end
        if self.instant or not self:IsVisible() then
            -- hidden bars (or pooled rows) jump straight there
            self.cur = (self.instant or self.cur ~= nil) and pct or 0
            self:Render(self.cur)
            if self.instant then self:SetScript("OnUpdate", nil) return end
        end
        self.cur = self.cur or 0
        if math.abs(self.target - self.cur) < 0.001 then
            self:Render(self.target) -- re-fit to the current width
        else
            self:SetScript("OnUpdate", Step)
        end
    end
    FGT.allBars = FGT.allBars or {}
    table.insert(FGT.allBars, bar) -- for the idle glint below
    return bar
end

-- Idle glint: every few seconds a faint light sweeps across the filled
-- part of each visible progress bar, top to bottom as a gentle wave.
-- It stays inside the fill (a clip frame on it), skips empty and
-- finished bars, and only plays with Celebrations on Full. Its own
-- driver, so it never takes over a bar's glide or 100% shine.
do
    local EVERY, SWEEP, WAVE = 4.5, 2.4, 0.08 -- seconds between, one slow sweep, delay per bar
    local LIGHT = { 1.00, 0.96, 0.80 }
    local active = {}
    local wait = 1.5
    local function Glint(bar)
        if bar.glint then return bar.glint end
        local clip = CreateFrame("Frame", nil, bar)
        clip:SetPoint("TOPLEFT", bar.fill, "TOPLEFT", 0, 0)
        clip:SetPoint("BOTTOMRIGHT", bar.fill, "BOTTOMRIGHT", 0, 0)
        if clip.SetClipsChildren then pcall(clip.SetClipsChildren, clip, true) end
        local g = { clip = clip }
        g.l = clip:CreateTexture(nil, "OVERLAY")
        g.r = clip:CreateTexture(nil, "OVERLAY")
        for _, t in ipairs({ g.l, g.r }) do
            t:SetTexture(SOLID)
            t:SetBlendMode("ADD")
            t:SetVertexColor(0, 0, 0, 0) -- new textures start white and shown:
            t:Hide()                     -- keep them dark until the sweep draws them
            t:SetPoint("TOP", clip, "TOP", 0, 0)
            t:SetPoint("BOTTOM", clip, "BOTTOM", 0, 0)
        end
        g.r:SetPoint("LEFT", g.l, "RIGHT", 0, 0)
        bar.glint = g
        return g
    end
    local driver = CreateFrame("Frame")
    driver:SetScript("OnUpdate", function(_, elapsed)
        wait = wait - elapsed
        if wait <= 0 then
            wait = EVERY
            if FGT.Setting and FGT.Setting("celebrations") == "full" then
                local list = {}
                for _, bar in ipairs(FGT.allBars or {}) do
                    if bar:IsVisible() and bar.fill:IsShown() and bar.look ~= "done" and (bar.cur or 0) > 0.02 then
                        table.insert(list, bar)
                    end
                end
                table.sort(list, function(a, b) return (a:GetTop() or 0) > (b:GetTop() or 0) end)
                for i, bar in ipairs(list) do active[bar] = -(i - 1) * WAVE end
            end
        end
        for bar, t in pairs(active) do
            t = t + elapsed
            active[bar] = t
            local g = Glint(bar)
            if t >= 0 then
                local p = t / SWEEP
                local fw = bar.fill:GetWidth()
                if p >= 1 or not bar:IsVisible() then
                    g.l:Hide(); g.r:Hide()
                    active[bar] = nil
                else
                    -- a wide, soft band gliding at an even pace (like a text shimmer)
                    local half = math.max(8, math.min(70, fw * 0.35))
                    local x = -2 * half + (fw + 2 * half) * p
                    local a = 0.22 * math.sin(math.pi * p) -- fades in, then out
                    g.l:SetWidth(half)
                    g.r:SetWidth(half)
                    g.l:ClearAllPoints()
                    g.l:SetPoint("TOP", g.clip, "TOP", 0, 0)
                    g.l:SetPoint("BOTTOM", g.clip, "BOTTOM", 0, 0)
                    g.l:SetPoint("LEFT", g.clip, "LEFT", x, 0)
                    ApplyHGradient(g.l, LIGHT, LIGHT, 0, a)
                    ApplyHGradient(g.r, LIGHT, LIGHT, a, 0)
                    g.l:Show(); g.r:Show()
                end
            end
        end
    end)
end

-- ============================================================
-- Completion celebration
-- ============================================================
-- Plays once, at the moment something turns complete while you're
-- looking at it: a group row, a goal card, a Tier 3 piece, a step's
-- checkbox, the goal's progress bar. FGT.doneSeen remembers what each
-- one looked like last time it was drawn, so opening a goal that's
-- already finished stays quiet. Lives on FGT to stay clear of the
-- main chunk's local limit.
FGT.doneSeen = {}

function FGT.CheckCelebration(row, key, complete, play)
    local was = FGT.doneSeen[key]
    if FGT.quietCelebrate then was = complete end -- silent redraws: no fanfare
    FGT.doneSeen[key] = complete
    if row.fxKey and row.fxKey ~= key then FGT.EndCelebration(row) end
    if complete and was == false then
        if FGT.Setting("celebrations") == "off" then return end
        row.fxKey = key
        play(row)
    end
end

do
local GLOW_A = 0.16
local DEEP, PALE = { 1.00, 0.62, 0.10 }, { 1.00, 0.95, 0.72 }

local function Clamp01(x) return x < 0 and 0 or (x > 1 and 1 or x) end
-- ease-out-back: shoots a little past 1, then settles
local function PopEase(t) local u = t - 1; return 1 + 2.6 * u * u * u + 1.6 * u * u end

-- Gradient textures ignore SetAlpha in game, so fades redraw them.
local function SetGlow(row, a)
    ApplyHGradient(row.doneGlow, C.DONE, C.DONE, 0, GLOW_A * a)
end

-- Three additive strips (deep gold edges, a pale bright core) that
-- sweep across a frame; built lazily for whatever frame shines.
local function MakeShine(f, height)
    f.shineL = f:CreateTexture(nil, "OVERLAY", nil, 1)
    f.shineC = f:CreateTexture(nil, "OVERLAY", nil, 2)
    f.shineR = f:CreateTexture(nil, "OVERLAY", nil, 1)
    for _, t in ipairs({ f.shineL, f.shineC, f.shineR }) do
        t:SetTexture(SOLID)
        t:SetBlendMode("ADD")
        t:SetVertexColor(0, 0, 0, 0)
        t:SetHeight(height)
        t:Hide()
    end
    f.shineL:SetWidth(48)
    f.shineC:SetWidth(7)
    f.shineR:SetWidth(48)
    f.shineC:SetPoint("LEFT", f.shineL, "RIGHT", 0, 0)
    f.shineR:SetPoint("LEFT", f.shineC, "RIGHT", 0, 0)
end

local function ShowShine(f, on)
    f.shineL:SetShown(on)
    f.shineC:SetShown(on)
    f.shineR:SetShown(on)
end

-- sh = 0..1 along the sweep. Steady speed the whole way (easing to a
-- stop read as a stall); a quick fade in, then a long soft fade out
-- while it keeps moving, with the bright core going first so it never
-- shrinks to a thin line.
local function ShineFrame(f, sh, inset)
    local band = f.shineL:GetWidth() + f.shineC:GetWidth() + f.shineR:GetWidth()
    local travel = math.max(0, f:GetWidth() - band - 2 * inset)
    f.shineL:ClearAllPoints()
    f.shineL:SetPoint("LEFT", f, "LEFT", inset + travel * sh, 0)
    local a = Clamp01(sh / 0.15)
    if sh > 0.45 then a = 0.5 + 0.5 * math.cos(math.pi * (sh - 0.45) / 0.55) end
    local core = a * a * a
    ApplyHGradient(f.shineL, DEEP, PALE, 0, 0.32 * a)
    ApplyHGradient(f.shineC, PALE, PALE, 0.5 * core, 0.5 * core)
    ApplyHGradient(f.shineR, PALE, DEEP, 0.32 * a, 0)
end

-- Adds the celebration layers to an etched tile (group rows, goal
-- cards): a faint green wash from the right for finished ones, a gold
-- ring that bursts out of the border, and the gold shine.
function FGT.AddCelebrationFX(row, inset, shineHeight)
    row.fxInset = inset
    row.doneGlow = row:CreateTexture(nil, "BACKGROUND", nil, -5)
    row.doneGlow:SetTexture(SOLID)
    row.doneGlow:SetPoint("TOPLEFT", inset, -inset)
    row.doneGlow:SetPoint("BOTTOMRIGHT", -inset, inset)
    SetGlow(row, 1)
    row.doneGlow:Hide()
    row.burst = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.burst:SetFrameLevel(row:GetFrameLevel() + 3)
    row.burst:SetBackdrop({ edgeFile = ETCH_EDGE, edgeSize = 10 })
    row.burst:SetBackdropBorderColor(1.00, 0.82, 0.00, 1)
    row.burst:Hide()
    MakeShine(row, shineHeight)
end

-- What pops: a checkmark texture (grows from nothing) or a chip frame
-- like the COMPLETE tag (scales up from nothing).
local function PopFrame(row, t)
    local c = Clamp01((t - 0.05) / 0.4)
    local s = PopEase(c)
    if row.popChip then
        row.popChip:SetScale(math.max(0.01, s))
        row.popChip:SetAlpha(Clamp01(c * 3))
        if row.bigCheck then
            -- the big check lands a beat after the tag
            local b = Clamp01((t - 0.12) / 0.4)
            row.bigCheck:SetScale(math.max(0.01, PopEase(b)))
            row.bigCheck:SetAlpha(Clamp01(b * 3))
        end
    elseif row.popTex then
        local px = math.max(0.01, row.popSize * s)
        row.popTex:SetSize(px, px)
        row.popTex:SetAlpha(Clamp01(c * 3))
    end
end

function FGT.EndCelebration(row)
    row:SetScript("OnUpdate", nil)
    row.fxT, row.fxKey = nil, nil
    if row.popChip then
        row.popChip:SetScale(1)
        row.popChip:SetAlpha(1)
        if row.bigCheck then
            row.bigCheck:SetScale(1)
            row.bigCheck:SetAlpha(1)
            row.checkGlow:SetAlpha(0)
            row.checkShadow:SetAlpha(0.75)
        end
    elseif row.popTex then
        row.popTex:SetSize(row.popSize, row.popSize)
        row.popTex:SetAlpha(1)
    end
    if row.burst then
        row.burst:Hide()
        ShowShine(row, false)
        SetGlow(row, 1)
    end
end

local function PopStep(self, elapsed)
    self.fxT = self.fxT + elapsed
    if self.fxT >= 0.5 then return FGT.EndCelebration(self) end
    PopFrame(self, self.fxT)
end

-- Small moment: a checkmark springs in, overshoots, and settles.
-- tex/size default to the Tier 3 piece's green check.
function FGT.PopCheck(row, tex, size)
    if row.fxT then FGT.EndCelebration(row) end
    row.popChip = nil
    row.popTex = tex or row.doneCheck
    row.popSize = size or 18
    row.fxT = 0
    PopFrame(row, 0)
    row:SetScript("OnUpdate", PopStep)
end

-- A step's checkbox pops when you tick it. ToggleStep notes what was
-- just ticked; the row drawing that step calls this.
function FGT.MaybePopTick(row, goalId, key)
    if row.isDone and (FGT.justTicked == goalId .. "|" .. key or FGT.restoringReset == goalId) then
        FGT.justTicked = nil
        if FGT.Setting("celebrations") == "off" then return end
        FGT.PopCheck(row, row.check, 22)
    end
end

-- Big moment: the pop, plus the gold ring bursting out of the border,
-- the shine sweeping across, and the green glow fading in.
local function CelebrateStep(self, elapsed)
    local t = self.fxT + elapsed
    self.fxT = t
    if t >= 0.7 then return FGT.EndCelebration(self) end
    PopFrame(self, t)

    -- Subtle celebrations keep the pop and the glow, without the ring
    -- burst and the shine.
    if not self.fxSubtle then
        -- The ring keeps moving until it's gone: a gentle ease-out, and a
        -- fade that finishes first, so it never sits still while visible.
        local r = Clamp01(t / 0.55)
        local o = 7 * (1 - (1 - r) ^ 2)
        self.burst:ClearAllPoints()
        self.burst:SetPoint("TOPLEFT", -o, o)
        self.burst:SetPoint("BOTTOMRIGHT", o, -o)
        self.burst:SetAlpha((1 - r) ^ 2)

        ShineFrame(self, Clamp01((t - 0.06) / 0.55), self.fxInset)
    end
    SetGlow(self, Clamp01(t / 0.6))
    if self.bigCheck then
        -- bright green glow as the check lands, easing into a soft shadow
        local g = Clamp01((t - 0.12) / 0.15) * (1 - Clamp01((t - 0.3) / 0.4))
        self.checkGlow:SetAlpha(0.9 * g)
        self.checkShadow:SetAlpha(0.75 * Clamp01((t - 0.25) / 0.45))
    end
end

-- Group rows pop their green check; goal cards pop the COMPLETE tag.
function FGT.CelebrateRow(row)
    if row.fxT then FGT.EndCelebration(row) end
    if row.check and row.check.SetLabel then
        row.popChip = row.check
    elseif row.bigCheck then
        row.popChip = row.bigCheck
        row.popTex, row.popSize = nil, nil
    else
        row.popChip, row.popTex, row.popSize = nil, row.doneCheck, 20
    end
    row.fxT = 0
    row.fxSubtle = FGT.Setting("celebrations") == "subtle"
    row.burst:SetShown(not row.fxSubtle)
    ShowShine(row, not row.fxSubtle)
    CelebrateStep(row, 0)
    row:SetScript("OnUpdate", CelebrateStep)
end

-- The goal's progress bar: once its fill glides all the way to 100%,
-- a gold shine runs along it. Called by the bar itself (bar.celebrate).
local function BarShineStep(self, elapsed)
    self.shineT = self.shineT + elapsed
    local sh = Clamp01(self.shineT / 0.9)
    ShineFrame(self, sh, 1)
    if sh >= 1 then
        self:SetScript("OnUpdate", nil)
        ShowShine(self, false)
    end
end

function FGT.BarShine(bar)
    if FGT.Setting("celebrations") ~= "full" then return end
    if not bar.shineL then MakeShine(bar, math.max(2, bar:GetHeight() - 2)) end
    -- a wide soft band sized to the bar (like the idle glint), bright core in the middle
    local side = math.max(12, math.min(70, bar:GetWidth() * 0.35))
    bar.shineL:SetWidth(side)
    bar.shineR:SetWidth(side)
    bar.shineT = 0
    ShineFrame(bar, 0, 1)
    ShowShine(bar, true)
    bar:SetScript("OnUpdate", BarShineStep)
end
end

-- A subtle top/bottom fade overlay, colored to match the panel behind it,
-- so a scrollable list hints that there's more content off-screen.
--
-- This is built from several stacked, flat-alpha strips instead of a real
-- gradient texture API. Real gradient APIs (SetGradientAlpha / SetGradient)
-- have proven to be a moving target across client updates - a client that
-- silently drops one used to take the whole addon down at load (see the
-- CreateScrollArea comment below). Solid-color strips only ever use
-- SetVertexColor, which has been stable since vanilla, so this can't break
-- the same way again.
-- soft: a gentler bottom (the goal list: bright finished or Forever cards
-- showed the full-strength fade as a dark band, Karl)
local function CreateEdgeFade(parent, isTop, soft)
    -- the bottom fade is taller, eases in, and ends on the panels' darker
    -- bottom shade, so it melts into the grime fading out there (Karl)
    -- the top is taller than a row with a progress bar, so a row slides
    -- under as a whole instead of leaving its bar behind (Karl); a solid
    -- lip at the edge was tried and made that worse
    local height = isTop and 40 or (soft and 36 or 28)
    local steps = height -- one strip per pixel: a smooth ramp, no visible steps (Karl: banding)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(height)
    f:SetFrameStrata(parent:GetFrameStrata())
    f:SetFrameLevel(parent:GetFrameLevel() + 20)
    -- top: the panel color with the faint grime blended in (Media/grime
    -- averages about #1e160f), a touch darker than the panel so rows feel
    -- like they slide under it; bottom: the panels' darker bottom shade
    local c = isTop and { 0.05, 0.045, 0.04 } or { 0.022, 0.022, 0.021 }
    local stepH = height / steps
    for i = 1, steps do
        -- i = 1 sits at the outer edge (nearly opaque panel color) and
        -- fades toward ~0 alpha by the inner edge, closest to the content.
        local alpha = 1 - ((i - 0.5) / steps)
        -- eased: soft where it meets the rows (gentler at the top, whose
        -- band is taller so a step with a progress bar fades as a whole)
        alpha = alpha ^ (isTop and 1.3 or (soft and 1.2 or 1.6))
        if soft and not isTop then alpha = alpha * 0.75 end
        local strip = Flat(f, c[1], c[2], c[3], alpha)
        strip:ClearAllPoints()
        if isTop then
            strip:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(i - 1) * stepH)
            strip:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -(i - 1) * stepH)
        else
            strip:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, (i - 1) * stepH)
            strip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, (i - 1) * stepH)
        end
        strip:SetHeight(stepH)
    end
    return f
end

-- A minimal mouse-wheel scroll area: a ScrollFrame + content frame, a thin
-- flat scrollbar, and top/bottom edge fades. Call :Finalize() once the
-- returned .scroll frame has been anchored, then use .content as the parent
-- for whatever gets listed inside it.
local function CreateScrollArea(parent, softBottom)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)

    local fadeTop = CreateEdgeFade(parent, true)
    local fadeBottom = CreateEdgeFade(parent, false, softBottom)

    -- Scrollbar. The visible track and thumb stay slim, but each sits in
    -- a wider invisible hit area that takes the mouse, so you can grab
    -- the thumb (or click the track) without dragging the whole window.
    local HIT_W = 12
    local trackHit = CreateFrame("Button", nil, parent)
    trackHit:SetFrameStrata(parent:GetFrameStrata())
    trackHit:SetFrameLevel(parent:GetFrameLevel() + 20)
    trackHit:SetWidth(HIT_W)
    trackHit:EnableMouse(true)
    trackHit:EnableMouseWheel(true)
    local track = Flat(trackHit, STYLE.row.edge[1], STYLE.row.edge[2], STYLE.row.edge[3], 0.20)
    track:SetPoint("TOP", trackHit, "TOP", 0, 0)
    track:SetPoint("BOTTOM", trackHit, "BOTTOM", 0, 0)
    track:SetWidth(3)

    local thumbHit = CreateFrame("Button", nil, trackHit)
    thumbHit:SetWidth(HIT_W)
    thumbHit:SetFrameLevel(trackHit:GetFrameLevel() + 1)
    thumbHit:EnableMouse(true)
    local thumb = Flat(thumbHit, STYLE.row.edge[1], STYLE.row.edge[2], STYLE.row.edge[3], 0.95)
    thumb:SetPoint("TOP", thumbHit, "TOP", 0, 0)
    thumb:SetPoint("BOTTOM", thumbHit, "BOTTOM", 0, 0)
    thumb:SetWidth(3)

    local obj = {
        scroll = scroll,
        content = content,
        fadeTop = fadeTop,
        fadeBottom = fadeBottom,
        track = track,
        thumb = thumb,
        trackHit = trackHit,
    }

    local function Metrics()
        local viewH = scroll:GetHeight()
        local contentH = content:GetHeight()
        local maxScroll = math.max(0, contentH - viewH)
        local thumbH = contentH > 0 and math.max(20, viewH * (viewH / contentH)) or viewH
        return viewH, contentH, maxScroll, thumbH, math.max(1, viewH - thumbH)
    end

    local function SetScroll(value)
        local _, _, maxScroll = Metrics()
        scroll:SetVerticalScroll(math.max(0, math.min(maxScroll, value)))
        obj:Update()
    end

    local function CursorY()
        local _, y = GetCursorPosition()
        return y / trackHit:GetEffectiveScale()
    end

    -- Thumb: grab and drag; the content follows the cursor 1:1 along
    -- the track. Brightens while hovered or dragged.
    local dragging = false
    local function Highlight(on)
        -- The same subdued bronze as etched borders, with a small lift
        -- on hover/drag instead of the progress bars' saturated yellow.
        local color = on and STYLE.button.edge or STYLE.row.edge
        thumb:SetVertexColor(color[1], color[2], color[3], on and 1 or 0.95)
    end
    thumbHit:SetScript("OnEnter", function() Highlight(true) end)
    thumbHit:SetScript("OnLeave", function() if not dragging then Highlight(false) end end)
    thumbHit:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        dragging = true
        local startY, startScroll = CursorY(), scroll:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local _, _, maxScroll, _, travel = Metrics()
            SetScroll(startScroll + (startY - CursorY()) * (maxScroll / travel))
        end)
    end)
    thumbHit:SetScript("OnMouseUp", function(self)
        dragging = false
        self:SetScript("OnUpdate", nil)
        Highlight(self:IsMouseOver())
    end)
    thumbHit:SetScript("OnHide", function(self)
        dragging = false
        self:SetScript("OnUpdate", nil)
    end)

    -- Track: click above or below the thumb to jump there.
    trackHit:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local top = self:GetTop()
        if not top then return end
        local _, _, maxScroll, thumbH, travel = Metrics()
        local pos = (top - CursorY()) - thumbH / 2
        SetScroll(math.max(0, math.min(travel, pos)) / travel * maxScroll)
    end)
    trackHit:SetScript("OnMouseWheel", function(_, delta)
        SetScroll(scroll:GetVerticalScroll() - delta * 36)
    end)

    function obj:Finalize()
        content:SetWidth(scroll:GetWidth())

        fadeTop:ClearAllPoints()
        fadeTop:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        fadeTop:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)

        fadeBottom:ClearAllPoints()
        fadeBottom:SetPoint("BOTTOMLEFT", scroll, "BOTTOMLEFT", 0, 0)
        fadeBottom:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)

        trackHit:ClearAllPoints()
        trackHit:SetPoint("TOP", scroll, "TOPRIGHT", 3, 0)
        trackHit:SetPoint("BOTTOM", scroll, "BOTTOMRIGHT", 3, 0)

        -- Keep the scroll child's width glued to the (now resizable)
        -- viewport, so text inside it re-wraps instead of clipping or
        -- leaving dead space after the window is resized.
        scroll:SetScript("OnSizeChanged", function(self)
            content:SetWidth(self:GetWidth())
            obj:Update()
        end)
    end

    function obj:Update()
        local viewH, contentH, maxScroll, thumbH, travel = Metrics()
        local current = scroll:GetVerticalScroll()
        if current > maxScroll then
            current = maxScroll
            scroll:SetVerticalScroll(current)
        end

        -- Rows slide under soft edge gradients, a sense of depth (Karl).
        -- (Fading each row's own alpha instead was tried and dropped: the
        -- rows looked like they vanished rather than went under.)
        fadeTop:SetShown(maxScroll > 1 and current > 1)
        fadeBottom:SetShown(maxScroll > 1 and current < maxScroll - 1)

        if maxScroll > 1 then
            trackHit:Show()
            local offset = (current / maxScroll) * travel
            thumbHit:SetHeight(thumbH)
            thumbHit:ClearAllPoints()
            thumbHit:SetPoint("TOP", trackHit, "TOP", 0, -offset)
        else
            trackHit:Hide()
        end
    end

    scroll:SetScript("OnMouseWheel", function(self, delta)
        SetScroll(self:GetVerticalScroll() - delta * 36)
    end)

    return obj
end

-- ============================================================
-- Main frame
-- ============================================================
local main = CreateFrame("Frame", "ForeverGoalTrackerFrame", UIParent, "BackdropTemplate")
main:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
main:SetPoint("CENTER")
main:SetFrameStrata("HIGH")
main:SetMovable(true)
main:EnableMouse(true)
main:SetClampedToScreen(true)
main:RegisterForDrag("LeftButton")
-- We save the position ourselves; stop the game's layout cache from
-- also restoring it (two systems placing one window = random jumps).
if main.SetDontSavePosition then main:SetDontSavePosition(true) end
Etch(main, STYLE.window, 16)
FGT.AddGrime(main, 0.25, 16, 0, 150, 220) -- the header, fading out below it

-- Pin the window by its top-left corner in plain screen coordinates.
-- Moving or sizing a frame that's still anchored by its CENTER makes
-- the game convert the anchor on the first drag, using stale numbers,
-- which is what made the window jump the first time you grabbed it.
local function NormalizeAnchor()
    local left, top = main:GetLeft(), main:GetTop()
    if not (left and top) then return end
    main:ClearAllPoints()
    main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

local function SavePosition()
    if not ForeverGoalTrackerDB then return end
    local left, top = main:GetLeft(), main:GetTop()
    if left and top then
        ForeverGoalTrackerDB.frameLeft, ForeverGoalTrackerDB.frameTop = left, top
    end
end

-- Moving is done by hand, like resizing: the game's StartMoving could
-- re-measure the window when grabbed and drop it somewhere odd. Here the
-- window moves exactly as far as the cursor has moved since the grab,
-- kept fully on screen.
local isMoving, isSizing = false, false
FGT.mover = CreateFrame("Frame")
FGT.mover:Hide()
FGT.mover:SetScript("OnUpdate", function()
    local st = FGT.moveStart
    if not st then return end
    local s = main:GetEffectiveScale()
    local mx, my = GetCursorPosition()
    local w, h = main:GetWidth(), main:GetHeight()
    local sw, sh = GetScreenWidth(), GetScreenHeight()
    local left = math.max(0, math.min(sw - w, st.left + (mx / s - st.x)))
    local top = math.max(h, math.min(sh, st.top + (my / s - st.y)))
    main:ClearAllPoints()
    main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end)
local function BeginMove()
    if isSizing then return end
    NormalizeAnchor()
    local left, top = main:GetLeft(), main:GetTop()
    if not (left and top) then return end
    local s = main:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    FGT.moveStart = { x = cx / s, y = cy / s, left = left, top = top }
    isMoving = true
    FGT.mover:Show()
end
local function EndMove()
    if not isMoving then return end
    FGT.mover:Hide()
    FGT.moveStart = nil
    isMoving = false
    NormalizeAnchor()
    SavePosition()
end
main:SetScript("OnDragStart", BeginMove)
main:SetScript("OnDragStop", EndMove)

-- Warm gold haze bleeding down from the masthead, fading to black.
local topGlow = main:CreateTexture(nil, "BACKGROUND", nil, -5)
topGlow:SetTexture(SOLID)
topGlow:SetPoint("TOPLEFT", 4, -4)
topGlow:SetPoint("TOPRIGHT", -4, -4)
topGlow:SetHeight(110)
ApplyVGradient(topGlow, { 0.78, 0.55, 0.10 }, { 0.78, 0.55, 0.10 }, 0.13, 0)
main:Hide()

-- Resizable window. SetResizeBounds is the newer unified API; older
-- clients only have the separate Set{Min,Max}Resize pair, so try the
-- new one first and fall back rather than assuming either exists.
-- Bounds are computed against the actual screen (see GetEffectiveMaxSize)
-- so the window can never be told to grow bigger than the screen itself.
-- The screen size isn't final while the addon is still loading (the UI
-- scale is applied later), so bounds are re-measured every time the
-- window opens and right before every resize drag, not just once.
main:SetResizable(true)
local function UpdateResizeBounds()
    local maxW, maxH = GetEffectiveMaxSize()
    if main.SetResizeBounds then
        main:SetResizeBounds(MIN_FRAME_WIDTH, MIN_FRAME_HEIGHT, maxW, maxH)
    else
        main:SetMinResize(MIN_FRAME_WIDTH, MIN_FRAME_HEIGHT)
        main:SetMaxResize(maxW, maxH)
    end
end
UpdateResizeBounds()

-- Belt-and-suspenders: don't just trust SetResizeBounds/SetMinResize/
-- SetMaxResize to actually hold the line during a live drag - clamp in
-- real time too, so the window is physically unable to grow past the
-- screen (or below the usable minimum) no matter what. This is what's
-- supposed to stop the window from ever again snapping to the screen
-- height and dragging the resize grip off the bottom edge with it.
-- Only corrects sizes set by code; during a live resize drag the game's
-- own bounds are in charge (correcting mid-drag fought the drag and
-- caused the snapping to odd widths).
main:SetScript("OnSizeChanged", function(self)
    if isSizing then return end
    local w, h = self:GetWidth(), self:GetHeight()
    local cw, ch = ClampFrameSize(w, h)
    if math.abs(w - cw) > 0.5 or math.abs(h - ch) > 0.5 then
        self:SetSize(cw, ch)
    end
end)

-- Resize grip (bottom-right corner). The drag itself is native to the
-- client and cheap; the actual re-layout (re-wrapping step text,
-- repositioning goal rows) is deferred to mouse-up so a live drag
-- doesn't re-run a 300+ row Tier 3 layout every frame. That handler is
-- wired further down, once SelectGoal/LayoutGoalList exist.
local resizeGrip = CreateFrame("Button", nil, main)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", -2, 2)
local function GripDot(x, y, size)
    local dot = Flat(resizeGrip, C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], 0.6)
    dot:SetSize(size, size)
    dot:SetPoint("BOTTOMRIGHT", resizeGrip, "BOTTOMRIGHT", x, y)
    return dot
end
GripDot(-2, 2, 2)
GripDot(-2, 7, 2)
GripDot(-7, 2, 2)
resizeGrip:SetScript("OnEnter", function() GameTooltip:SetOwner(resizeGrip, "ANCHOR_LEFT"); GameTooltip:AddLine("Drag to resize"); GameTooltip:Show() end)
resizeGrip:SetScript("OnLeave", function() GameTooltip:Hide() end)
-- Sizing is done by hand instead of the game's StartSizing, which
-- re-measured the window on mouse-down and could snap the height before
-- the mouse even moved. Here the size changes only by how far the
-- cursor travels from where it was pressed, so a plain click is a no-op.
resizeGrip:SetScript("OnMouseDown", function(self)
    if isMoving then return end
    UpdateResizeBounds()
    NormalizeAnchor()
    isSizing = true
    local s = main:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    FGT.sizeStart = { x = cx / s, y = cy / s, w = main:GetWidth(), h = main:GetHeight() }
    self:SetScript("OnUpdate", function()
        local st = FGT.sizeStart
        if not st then return end
        local sc = main:GetEffectiveScale()
        local mx, my = GetCursorPosition()
        local w, h = ClampFrameSize(st.w + (mx / sc - st.x), st.h - (my / sc - st.y))
        -- keep the bottom-right corner on screen, since the window is
        -- clamped to it and would otherwise get pushed instead of sized
        local left, top = main:GetLeft(), main:GetTop()
        if left and top then
            w = math.min(w, math.max(MIN_FRAME_WIDTH, GetScreenWidth() - left))
            h = math.min(h, math.max(MIN_FRAME_HEIGHT, top))
        end
        if math.abs(main:GetWidth() - w) > 0.5 or math.abs(main:GetHeight() - h) > 0.5 then
            main:SetSize(w, h)
        end
    end)
end)

-- Title bar
local titleBar = CreateFrame("Frame", nil, main)
titleBar:SetPoint("TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", 0, 0)
titleBar:SetHeight(56)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", BeginMove)
titleBar:SetScript("OnDragStop", EndMove)

-- Masthead: Cinzel title in gold, a muted tagline under it, and a gold
-- underline that fades out to the right.
local title = NewTitleString(titleBar, 20)
title:SetText(FGT.NAME)
title:SetPoint("TOPLEFT", 16, -14)

local tagline = NewFontString(titleBar, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
tagline:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
tagline:SetText(FGT.isForever and "Long-term goals for Warcraft Forever" or "Long-term goals for Classic Era")

local titleLine = NewFadeLine(titleBar)
titleLine:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 16, 0)
titleLine:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", -16, 0)

-- Expand / collapse markers: Karl's plus and minus icons drawn over the
-- old "+" / "-" text, which stays (invisible) so spacing doesn't change.
function FGT.SetPlusMinus(fs, open)
    if not fs.pm then
        fs.pm = fs:GetParent():CreateTexture(nil, "OVERLAY")
        fs.pm:SetSize(11, 11)
        fs.pm:SetPoint("CENTER", fs, "CENTER", 0, 0)
        fs:SetAlpha(0)
        -- the icon lives on the parent, so it follows the text's Show/Hide
        hooksecurefunc(fs, "Show", function() fs.pm:Show() end)
        hooksecurefunc(fs, "Hide", function() fs.pm:Hide() end)
        hooksecurefunc(fs, "SetShown", function(_, on) fs.pm:SetShown(on) end)
    end
    fs.pm:SetShown(fs:IsShown())
    fs:SetText(open and "-" or "+")
    fs.pm:SetTexture(FGT.Icon(open and "minus" or "plus"))
end
-- An icon button with no box (Karl): the painted icon, a little dimmed at
-- rest, full strength plus an additive copy on hover so it brightens.
-- btn.lit = true keeps it lit (the gear while Settings is open).
function FGT.IconButton(btn, name, size)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(size, size)
    btn.icon:SetPoint("CENTER", 0, 0)
    btn.icon:SetTexture(FGT.Icon(name))
    btn.glow = btn:CreateTexture(nil, "OVERLAY")
    btn.glow:SetAllPoints(btn.icon)
    btn.glow:SetTexture(FGT.Icon(name))
    btn.glow:SetBlendMode("ADD")
    function btn:RefreshIcon()
        local on = self.lit or self:IsMouseOver()
        self.icon:SetAlpha(on and 1 or 0.82)
        self.glow:SetAlpha(self:IsMouseOver() and 0.35 or (self.lit and 0.15 or 0))
    end
    btn:HookScript("OnEnter", btn.RefreshIcon)
    btn:HookScript("OnLeave", btn.RefreshIcon)
    btn:HookScript("OnMouseDown", function(self) self.icon:SetPoint("CENTER", 1, -1) end)
    btn:HookScript("OnMouseUp", function(self) self.icon:SetPoint("CENTER", 0, 0) end)
    btn:RefreshIcon()
end

-- Darker, more solid tooltips for the addon's own tooltips (Karl). The
-- game's tooltip is shared by the whole UI, so this only happens while
-- its owner is in our window (or our minimap button or banner). The
-- game redraws its own tooltip background, so instead of recoloring it we
-- add our own layers under it: a solid near-black backing inside the
-- border and the soft drop shadow (FGT.AddDropShadow), shown only for our
-- tooltips. The compare tooltips ("Equipped") follow GameTooltip.
do
    local function Ours(owner)
        while owner do
            if owner == main or owner == FGT.minimapButton or owner.fgtOwn then return true end
            owner = owner.GetParent and owner:GetParent() or nil
        end
        return false
    end
    local function Backer(tip)
        if tip.fgtBack then return end
        local b = tip:CreateTexture(nil, "BACKGROUND", nil, -8)
        b:SetPoint("TOPLEFT", 3, -3)
        b:SetPoint("BOTTOMRIGHT", -3, 3)
        b:SetColorTexture(0.03, 0.025, 0.02, 0.93)
        tip.fgtBack = b
        tip.fgtShadow = FGT.AddDropShadow(tip, 44, 0.38, 5, 12)
        -- AddDropShadow shows the shadow on every show; keep it to ours
        tip:HookScript("OnShow", function(self) self.fgtShadow:SetShown(self.fgtBack:IsShown()) end)
    end
    local function SetDark(tip, on)
        if not tip then return end
        if on then Backer(tip) end
        if tip.fgtBack then
            tip.fgtBack:SetShown(on)
            tip.fgtShadow:SetShown(on and tip:IsShown())
        end
    end
    FGT.SetTipDark = SetDark
    hooksecurefunc(GameTooltip, "SetOwner", function(self, owner)
        self.fgtDark = Ours(owner)
        SetDark(self, self.fgtDark)
    end)
    for _, name in ipairs({ "ShoppingTooltip1", "ShoppingTooltip2" }) do
        local t = _G[name]
        if t and t.HookScript then
            t:HookScript("OnShow", function(self) SetDark(self, GameTooltip.fgtDark and true or false) end)
        end
    end
end

local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPRIGHT", -12, -12)
FGT.IconButton(closeBtn, "close", 16)
closeBtn:SetScript("OnClick", function() main:Hide() end)

-- Overall progress bar
local overallBar = NewBar(main, 8)
overallBar:SetPoint("TOPLEFT", 16, -70)
overallBar:SetPoint("TOPRIGHT", -16, -70)

-- "N of 9 goals complete" summary line under the overall bar
local goalsCompleteText = NewFontString(main, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
goalsCompleteText:SetPoint("TOPLEFT", overallBar, "BOTTOMLEFT", 0, -4)

-- Tabs sit between the overall bar and the panels.
local TABS_TOP = -102
local PANEL_TOP = -142

-- Left panel (goal list) - "sticky": a fixed width set once via SetWidth,
-- never a second horizontal anchor, so resizing the window never
-- stretches or squishes it. Its height still tracks the window via the
-- TOPLEFT/BOTTOMLEFT anchor pair.
local listPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
listPanel:SetPoint("TOPLEFT", 16, PANEL_TOP)
listPanel:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 16, 16)
listPanel:SetWidth(LIST_WIDTH)
Etch(listPanel, STYLE.panel, 12)
FGT.AddGrime(listPanel, 0.18, 12, 0.37, 0, 140)

-- Right panel (detail) - fully anchor-driven (both corners), so it
-- fluidly fills whatever space is left of the sticky left panel as the
-- window is resized, with no manual width/height bookkeeping needed.
local detailPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
detailPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 12, 0)
detailPanel:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -16, 16)
Etch(detailPanel, STYLE.panel, 12)
FGT.AddGrime(detailPanel, 0.18, 12, 0.71, 0, 140)
do -- Short inner shadows stay inside the etched edge, below content.
    local top = detailPanel:CreateTexture(nil, "BORDER", nil, 0)
    top:SetTexture(SOLID)
    top:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 4,-4)
    top:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -4,-4)
    top:SetHeight(14)
    ApplyVGradient(top, {0,0,0}, {0,0,0}, 0.26,0)
    local right = detailPanel:CreateTexture(nil, "BORDER", nil, 0)
    right:SetTexture(SOLID)
    right:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -4,-4)
    right:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -4,4)
    right:SetWidth(10)
    ApplyHGradient(right, {0,0,0}, {0,0,0}, 0,0.24)
end

-- Sort control - a dropdown button above the list. Built by hand (not
-- Blizzard's UIDropDownMenu template, which differs between clients).
local sortModes = {
    { key = "alpha",      label = "A - Z" },
    { key = "difficulty", label = "Difficulty" },
    { key = "duration",   label = "Duration" },
    { key = "progress",   label = "Progress" },
}
local sortModeIndex = 1

-- Styled like the site's toolbar buttons: #3a3a3a, lighter on hover.
local sortBar = CreateFrame("Button", nil, listPanel, "BackdropTemplate")
sortBar:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 6, -6)
sortBar:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -6 - 58, -6) -- room for Clear
sortBar:SetHeight(22)
Etch(sortBar, STYLE.button, 10)
local sortLabel = NewFontString(sortBar, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
sortLabel:SetPoint("LEFT", sortBar, "LEFT", 8, 0)
-- Karl's gold chevron (Media/icons/chevron), centered on the label's
-- line. Points down when closed; flipped up while the menu is open.
local caret = CreateFrame("Frame", nil, sortBar)
caret:SetSize(14, 14)
caret:SetPoint("RIGHT", sortBar, "RIGHT", -6, 0)
caret.icon = caret:CreateTexture(nil, "OVERLAY")
caret.icon:SetAllPoints(caret)
caret.icon:SetTexture(FGT.Icon("chevron"))
local function SetCaret(open)
    caret.icon:SetTexCoord(0, 1, open and 1 or 0, open and 0 or 1)
end
SetCaret(false)

local sortMenu -- created below, once the sort functions exist
sortBar:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
sortBar:SetScript("OnLeave", function(self)
    if not (sortMenu and sortMenu:IsShown()) then self:SetEtch(STYLE.button) end
end)

-- Scrollable content area inside the goal list panel
local listScrollObj = CreateScrollArea(listPanel, true) -- softer bottom fade over bright cards
listScrollObj.scroll:SetPoint("TOPLEFT", sortBar, "BOTTOMLEFT", 0, -4)
listScrollObj.scroll:SetPoint("BOTTOMRIGHT", listPanel, "BOTTOMRIGHT", -10, 4)
listScrollObj:Finalize()
local listContent = listScrollObj.content

-- ============================================================
-- Goal list rows
-- ============================================================
local goalRows = {}
local selectedId = nil

-- Sorts a fresh copy of FGT.goals by the given mode's comparator and
-- repositions the already-created row frames to match - the rows
-- themselves are never recreated, only moved.
local difficultyRank = {}
for i, d in ipairs(FGT.difficultyOrder) do
    difficultyRank[d] = i
end

local function CompareGoals(mode, a, b)
    if mode == "difficulty" then
        local ra, rb = difficultyRank[a.difficulty] or 0, difficultyRank[b.difficulty] or 0
        if ra ~= rb then return ra < rb end
    elseif mode == "duration" then
        local ra, rb = FGT.timeRank[a.timeEstimate] or 0, FGT.timeRank[b.timeEstimate] or 0
        if ra ~= rb then return ra < rb end
    elseif mode == "progress" then
        local da, ta = GoalProgress(a)
        local db, tb = GoalProgress(b)
        local pa = ta > 0 and da / ta or 0
        local pb = tb > 0 and db / tb or 0
        if pa ~= pb then return pa > pb end -- most progress first
    end
    -- alphabetical by what the list actually shows
    return (a.short or a.name) < (b.short or b.name)
end

local LayoutGoalList -- forward declare, defined after listScrollObj exists

local function UpdateSortLabel()
    sortLabel:SetText("|cffbdbdbdSort:|r  " .. sortModes[sortModeIndex].label)
end

local function SetSortMode(index)
    sortModeIndex = index
    if ForeverGoalTrackerDB then
        ForeverGoalTrackerDB.sortMode = sortModes[sortModeIndex].key
    end
    UpdateSortLabel()
    LayoutGoalList()
end

-- Dropdown menu: etched gold-rimmed panel under the button, one row per
-- sort mode, the same width as the button. Names line up with "Sort:",
-- and the current choice gets a gold check on the right, under the caret
-- (Karl). A transparent catcher over the window closes it when you click
-- anywhere else.
sortMenu = CreateFrame("Frame", nil, main, "BackdropTemplate")
sortMenu:SetPoint("TOPLEFT", sortBar, "BOTTOMLEFT", 0, -2)
sortMenu:SetPoint("TOPRIGHT", sortBar, "BOTTOMRIGHT", 0, -2)
sortMenu:SetFrameLevel(main:GetFrameLevel() + 60)
Etch(sortMenu, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
sortMenu:EnableMouse(true)
sortMenu:Hide()

-- Soft drop shadow for popups: Media/shadow.tga (a round blur, drawn by
-- tools/shadow.py) as a nine-slice in a frame just under the popup,
-- nudged down. The blur starts a little inside the popup's edge, so what
-- shows is only the soft outer falloff, with rounded corners.
-- spread: blur width in pixels; inset: how far inside the edge it starts.
function FGT.AddDropShadow(f, spread, alpha, drop, inset)
    -- defaults tuned in game with Karl: wide, faint and soft
    spread, alpha, drop, inset = spread or 30, alpha or 0.55, drop or 6, inset or 8
    local s = CreateFrame("Frame", nil, f:GetParent())
    s:SetFrameStrata(f:GetFrameStrata())
    s:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
    s:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -drop - inset)
    s:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, -drop + inset)
    local TEX = "Interface\\AddOns\\" .. ADDON .. "\\Media\\shadow"
    local A, B = 0.49, 0.51 -- the center lines, stretched for edges and middle
    local R = spread
    -- each piece: its top-left (point of s, x, y), its bottom-right
    -- (point of s, x, y), then texcoords left, right, top, bottom
    local pieces = {
        { "TOPLEFT", -R, R, "TOPLEFT", 0, 0,          0, 0.5, 0, 0.5 },  -- corners
        { "TOPRIGHT", 0, R, "TOPRIGHT", R, 0,         0.5, 1, 0, 0.5 },
        { "BOTTOMLEFT", -R, 0, "BOTTOMLEFT", 0, -R,   0, 0.5, 0.5, 1 },
        { "BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", R, -R,  0.5, 1, 0.5, 1 },
        { "TOPLEFT", 0, R, "TOPRIGHT", 0, 0,          A, B, 0, 0.5 },    -- top
        { "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", 0, -R,   A, B, 0.5, 1 },    -- bottom
        { "TOPLEFT", -R, 0, "BOTTOMLEFT", 0, 0,       0, 0.5, A, B },    -- left
        { "TOPRIGHT", 0, 0, "BOTTOMRIGHT", R, 0,      0.5, 1, A, B },    -- right
        { "TOPLEFT", 0, 0, "BOTTOMRIGHT", 0, 0,       A, B, A, B },      -- middle
    }
    for _, p in ipairs(pieces) do
        local t = s:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(TEX)
        t:SetVertexColor(0, 0, 0, alpha)
        t:SetPoint("TOPLEFT", s, p[1], p[2], p[3])
        t:SetPoint("BOTTOMRIGHT", s, p[4], p[5], p[6])
        t:SetTexCoord(p[7], p[8], p[9], p[10])
    end
    s:SetShown(f:IsShown())
    f:HookScript("OnShow", function() s:Show() end)
    f:HookScript("OnHide", function() s:Hide() end)
    f.shadow = s
    return s
end
FGT.AddDropShadow(sortMenu)

local sortCatcher = CreateFrame("Button", nil, main)
sortCatcher:SetAllPoints(main)
sortCatcher:SetFrameLevel(main:GetFrameLevel() + 55)
sortCatcher:Hide()

local MENU_ROW = 24
local sortMenuRows = {}
local function RefreshSortMenu()
    for i, row in ipairs(sortMenuRows) do
        local current = (i == sortModeIndex)
        row.check:SetShown(current)
        if current then
            row.label:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
        else
            row.label:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
        end
    end
end

local function CloseSortMenu()
    sortMenu:Hide()
    sortCatcher:Hide()
    SetCaret(false)
    sortBar:SetEtch(sortBar:IsMouseOver() and STYLE.btnHover or STYLE.button)
end

local function OpenSortMenu()
    RefreshSortMenu()
    sortMenu:Show()
    sortCatcher:Show()
    SetCaret(true)
    sortBar:SetEtch(STYLE.btnHover)
end

for i, mode in ipairs(sortModes) do
    local row = CreateFrame("Button", nil, sortMenu)
    row:SetHeight(MENU_ROW)
    row:SetPoint("TOPLEFT", sortMenu, "TOPLEFT", 4, -4 - (i - 1) * MENU_ROW)
    row:SetPoint("TOPRIGHT", sortMenu, "TOPRIGHT", -4, -4 - (i - 1) * MENU_ROW)

    row.hl = row:CreateTexture(nil, "BACKGROUND")
    row.hl:SetTexture(SOLID)
    row.hl:SetAllPoints(row)
    ApplyHGradient(row.hl, C.ACCENT, C.ACCENT, 0.18, 0.02)
    row.hl:Hide()

    row.check = row:CreateTexture(nil, "OVERLAY")
    row.check:SetTexture(FGT.Icon("check"))
    row.check:SetSize(12, 12)
    row.check:SetPoint("RIGHT", row, "RIGHT", -5, 0) -- centered under the chevron

    row.label = NewFontString(row, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0) -- lines up with "Sort:"
    row.label:SetText(mode.label)

    row:SetScript("OnEnter", function(self) self.hl:Show() end)
    row:SetScript("OnLeave", function(self) self.hl:Hide() end)
    row:SetScript("OnClick", function()
        SetSortMode(i)
        CloseSortMenu()
    end)
    sortMenuRows[i] = row
end
sortMenu:SetHeight(#sortModes * MENU_ROW + 8)

sortBar:SetScript("OnClick", function()
    if sortMenu:IsShown() then CloseSortMenu() else OpenSortMenu() end
end)
sortCatcher:SetScript("OnClick", CloseSortMenu)
main:HookScript("OnHide", CloseSortMenu)
-- Closing mid-drag (Escape) must not leave the window stuck to the mouse.
main:HookScript("OnHide", function()
    if isMoving or isSizing then
        main:StopMovingOrSizing()
        resizeGrip:SetScript("OnUpdate", nil)
        FGT.sizeStart = nil
        FGT.mover:Hide()
        FGT.moveStart = nil
        isMoving, isSizing = false, false
        NormalizeAnchor()
        SavePosition()
    end
end)

-- Shared context line on the goal page and on its My Goals card.
function FGT.GoalEyebrow(goal)
    local category = goal.armorParent and goal.armorParent:match("^pvp_set_") and "PvP Set" or goal.category
    return string.upper(category) .. (goal.armorClass
        and ("  |cff77736a\194\183|r  " .. FGT.ArmorClassLabel(goal.armorClass)) or "")
        .. (goal.faction and ("  |cff77736a\194\183|r  " .. string.upper(goal.faction) .. " ONLY") or "")
end

local function RefreshGoalList()
    -- first, so a goal finished just now already has its date below
    if FGT.CheckGoalCompletions then FGT.CheckGoalCompletions() end
    for _, row in pairs(goalRows) do
        local done, total = GoalProgress(row.goal)
        row.bar:SetProgress(done, total)
        local isSelected = (row.goal.id == selectedId)
        local isNew = FGT.ApplyForeverLook(row, row.goal)
        if isNew then row.newChip:SetLabel(FGT.ForeverDot(12) .. isNew, C.FOREVER_LIGHT) end
        local finished = total > 0 and done == total
        local on = finished and FGT.CompletedOn(row.goal)
        row.eyebrow:SetText(finished and (on and ("Completed " .. on) or "Completed") or FGT.GoalEyebrow(row.goal))
        local eyebrowColor = finished and C.DONE or C.SUBTEXT
        row.eyebrow:SetTextColor(eyebrowColor[1], eyebrowColor[2], eyebrowColor[3])
        if isSelected then
            row:SetEtch(STYLE.rowSel)
            row.name:SetTextColor(1, 1, 1)
        else
            row:SetEtch(STYLE.row)
            row.name:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3])
        end
        -- the open goal: a very slow, faint streak around its border, like
        -- a picked interest tile (added the first time a card is opened;
        -- the comet code loads after this list's first draw)
        if isSelected and not row.comet and FGT.AddBorderComet then
            FGT.AddBorderComet(row, 2, 0.3, 10)
            row.comet.vis = 0 -- fades in
        end
        if row.comet then
            row.comet.on = isSelected
            -- gone at once from the card you left (a fade lingered there,
            -- Karl); the new one still fades in
            if not isSelected then row.comet.vis = 0 end
            row.comet.color = isNew and C.FOREVER_LIGHT or nil
        end
        local favs = ForeverGoalTrackerDB and ForeverGoalTrackerDB.favorites or {}
        local fav = favs[row.goal.id] and true or false
        row.star:SetShown(fav)
        local showNew = isNew and not fav
        row.newChip:SetShown(showNew and true or false)
        row.newChip:ClearAllPoints()
        row.newChip:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
        local rightInset = fav and 28 or (showNew and (row.newChip:GetWidth() + 14) or 8)
        row.eyebrow:SetPoint("RIGHT", -rightInset, 0)
        row.name:SetPoint("RIGHT", -8, 0)
        local complete = finished
        row.doneGlow:SetShown(complete)
        row.bigCheck:SetShown(complete)
        row.icon.tex:SetDesaturated(complete)
        row.icon.tex:SetAlpha(complete and 0.45 or 1)
        local rim = row.catColor
        if complete then
            local g = rim[1] * 0.3 + rim[2] * 0.59 + rim[3] * 0.11
            row.icon:SetBackdropBorderColor(g, g, g, 1)
        else
            row.icon:SetBackdropBorderColor(rim[1], rim[2], rim[3], 1)
        end
        row.bar:Show()
        FGT.CheckCelebration(row, "card_" .. row.goal.id, complete, FGT.CelebrateRow)
    end
end

local SelectGoal -- forward declare

local yStart = -8
FGT.ROW_H = 72 -- eyebrow/completion date, name, then progress bar
local rowHeight = FGT.ROW_H
for i, goal in ipairs(FGT.goals) do
    local row = CreateFrame("Button", nil, listContent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 6, yStart - (i - 1) * (rowHeight + 4))
    row:SetPoint("RIGHT", listContent, "RIGHT", -6, 0)
    row:SetHeight(rowHeight)
    row.goal = goal
    Etch(row, STYLE.row, 12)
    FGT.AddFactionCardEtch(row, goal.faction)

    -- Item icon, rimmed in the category's quality color.
    local catColor = FGT.categoryColors[goal.category] or C.ACCENT
    row.icon = NewIcon(row, 50) -- bottom lines up with the third text line
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -11)
    row.icon:SetIcon(goal.icon, catColor)

    row.eyebrow = NewFontString(row, 9, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    row.eyebrow:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 9, 0)
    row.eyebrow:SetPoint("RIGHT", -8, 0)
    row.eyebrow:SetJustifyH("LEFT")
    row.eyebrow:SetText(FGT.GoalEyebrow(goal))
    row.eyebrow:SetWordWrap(false)
    row.eyebrow:SetNonSpaceWrap(false)

    row.name = NewFontString(row, 13, "", C.INK2[1], C.INK2[2], C.INK2[3])
    row.name:SetPoint("TOPLEFT", row.eyebrow, "BOTTOMLEFT", 0, -7)
    row.name:SetPoint("RIGHT", -8, 0)
    row.name:SetJustifyH("LEFT")
    -- the list uses the goal's short name; the full name shows on the right
    row.name:SetText(goal.short or goal.name)
    row.name:SetWordWrap(false)
    row.name:SetNonSpaceWrap(false)
    row.name:SetShadowColor(0, 0, 0, 1)
    row.name:SetShadowOffset(1, -1)

    -- Forever-only goals: a blue NEW chip with the Forever logo.
    row.newChip = NewChip(row, 8)
    row.newChip:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
    row.newChip:SetLabel(FGT.ForeverDot(12) .. "NEW", C.FOREVER_LIGHT)
    row.newChip:SetBackdropBorderColor(C.FOREVER_DEEP[1], C.FOREVER_DEEP[2], C.FOREVER_DEEP[3], 1)
    row.newChip:Hide()

    -- Finished goals: a big green check over the greyed-out icon, with
    -- a soft shadow under it. It pops in wrapped in a green glow that
    -- settles into the shadow (FGT.CelebrateRow).
    row.catColor = catColor
    row.bigCheck = CreateFrame("Frame", nil, row)
    row.bigCheck:SetSize(50, 50)
    row.bigCheck:SetPoint("CENTER", row.icon, "CENTER", 0, 0)
    row.bigCheck:SetFrameLevel(row.icon:GetFrameLevel() + 2)
    for _, part in ipairs({
        { "checkShadow", "BACKGROUND", 40, 1, -2, { 0, 0, 0 }, 0.75, "BLEND" },
        { "checkGlow", "BORDER", 54, 0, 0, { 0.55, 1.00, 0.40 }, 0, "ADD" },
        { "checkMark", "ARTWORK", 36, 0, 0, { 0.45, 0.95, 0.30 }, 1, "BLEND" },
    }) do
        local t = row.bigCheck:CreateTexture(nil, part[2])
        t:SetTexture(FGT.Icon("check-white"))
        t:SetDesaturated(true)
        t:SetSize(part[3] * 0.72, part[3] * 0.72)
        t:SetPoint("CENTER", part[4], part[5] + 1)
        t:SetVertexColor(part[6][1], part[6][2], part[6][3])
        t:SetAlpha(part[7])
        t:SetBlendMode(part[8])
        row[part[1]] = t
    end
    row.bigCheck:Hide()
    FGT.AddCelebrationFX(row, 3, 64)

    -- gold star in the top-right corner of favorited goals
    row.star = row:CreateTexture(nil, "OVERLAY")
    row.star:SetTexture(FGT.Icon("star")) -- Karl's painted gold star
    row.star:SetSize(15, 15)
    row.star:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
    row.star:Hide()

    -- Last line, level with the icon's bottom: progress, including the
    -- full bar on completed goals. Their date replaces the eyebrow.
    row.bar = NewBar(row, 4)
    row.bar:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 9, 1)
    row.bar:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    row.bar.label:Hide()

    row:SetScript("OnEnter", function(self)
        if self.goal.id ~= selectedId then
            self:SetEtch(STYLE.rowHover)
            self.name:SetTextColor(1, 1, 1)
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.goal.name)
        local gc = FGT.categoryColors[self.goal.category] or C.ACCENT
        GameTooltip:AddLine(self.goal.category, gc[1], gc[2], gc[3])
        local dc = FGT.difficultyColors[self.goal.difficulty] or C.SUBTEXT
        GameTooltip:AddLine(self.goal.difficulty or "", dc[1], dc[2], dc[3])
        if self.goal.timeEstimate then
            GameTooltip:AddLine(self.goal.timeEstimate, C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
        end
        local fnote = FGT.ForeverNote(self.goal, true)
        if fnote then GameTooltip:AddLine(fnote, C.FOREVER[1], C.FOREVER[2], C.FOREVER[3], true) end
        local d, t = GoalProgress(self.goal)
        if t > 0 and d == t then
            local on = FGT.CompletedOn(self.goal)
            GameTooltip:AddLine(on and ("Completed " .. on) or "Complete", C.DONE[1], C.DONE[2], C.DONE[3])
        else
            GameTooltip:AddLine(FGT.StepCountText(self.goal), C.INK2[1], C.INK2[2], C.INK2[3])
        end
        GameTooltip:AddLine("Right-click for options", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        RefreshGoalList()
        GameTooltip:Hide()
    end)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            GameTooltip:Hide()
            FGT.OpenGoalMenu(self)
        else
            SelectGoal(self.goal.id)
        end
    end)

    goalRows[goal.id] = row
end

LayoutGoalList = function()
    local sorted = ActiveGoals()
    for _, g in ipairs(FGT.goals) do
        if goalRows[g.id] then goalRows[g.id]:SetShown(not g.libraryOnly and IsActive(g)) end
    end
    -- Favorites first, then the rest; each group follows the sort.
    local mode = sortModes[sortModeIndex].key
    -- (this also runs once at load, before the saved variables exist)
    local favs = ForeverGoalTrackerDB and ForeverGoalTrackerDB.favorites or {}
    table.sort(sorted, function(a, b)
        local fa, fb = favs[a.id] and true or false, favs[b.id] and true or false
        if fa ~= fb then return fa end
        return CompareGoals(mode, a, b)
    end)

    -- A thin gold divider between the two groups, brightest in the
    -- middle and fading out toward both ends.
    local divider = FGT.favDivider
    if not divider then
        divider = CreateFrame("Frame", nil, listContent)
        divider:SetHeight(1)
        local l, r = divider:CreateTexture(nil, "ARTWORK"), divider:CreateTexture(nil, "ARTWORK")
        for _, t in ipairs({ l, r }) do t:SetTexture(SOLID); t:SetHeight(1) end
        l:SetPoint("LEFT"); l:SetPoint("RIGHT", divider, "CENTER")
        r:SetPoint("LEFT", divider, "CENTER"); r:SetPoint("RIGHT")
        ApplyHGradient(l, C.GOLD2, C.GOLD2, 0, 0.45)
        ApplyHGradient(r, C.GOLD2, C.GOLD2, 0.45, 0)
        FGT.favDivider = divider
    end
    divider:Hide()

    local y = yStart
    for i, g in ipairs(sorted) do
        local row = goalRows[g.id]
        if i > 1 and favs[sorted[i - 1].id] and not favs[g.id] then
            y = y - 6
            divider:ClearAllPoints()
            divider:SetPoint("TOPLEFT", listContent, "TOPLEFT", 16, y)
            divider:SetPoint("RIGHT", listContent, "RIGHT", -16, 0)
            divider:Show()
            y = y - 11
        end
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 6, y)
            row:SetPoint("RIGHT", listContent, "RIGHT", -6, 0)
        end
        y = y - (rowHeight + 4)
    end

    -- "Find your next goal" after the last card (built after this runs at load)
    local fm = FGT.FindMoreButton and FGT.FindMoreButton()
    if fm then
        -- hidden in demos (keeps shots 1 to 4 as they are) unless the scene shows it
        local show = #sorted > 0 and (FGT.demoFind or not (ForeverGoalTrackerDB and ForeverGoalTrackerDB.demoBackup))
        fm:SetShown(show)
        if show then
            y = y - 8
            fm:ClearAllPoints()
            fm:SetPoint("TOPLEFT", listContent, "TOPLEFT", 6, y)
            fm:SetPoint("RIGHT", listContent, "RIGHT", -6, 0)
            y = y - (fm:GetHeight() + 10)
        end
    end

    local totalListHeight = -y
    listContent:SetHeight(math.max(totalListHeight, listScrollObj.scroll:GetHeight()))
    listScrollObj:Update()
end

UpdateSortLabel()
LayoutGoalList()

-- ============================================================
-- Detail panel contents
-- ============================================================
-- Small uppercase category label in its category color, above the title
-- (the site's tooltip "small" style).
-- Large item icon at the top-left of the goal page.
-- A real scroll viewport clips all goal widgets to the panel. On short
-- windows the header and steps scroll together; taller windows retain the
-- familiar fixed banner and independently scrolling steps.
do
    local view = CreateScrollArea(detailPanel)
    view.scroll:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 4, -4)
    view.scroll:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -10, 4)
    view.content:SetHeight(600)
    view:Finalize()
    view.scroll:HookScript("OnHide", function()
        view.trackHit:Hide(); view.fadeTop:Hide(); view.fadeBottom:Hide()
    end)
    view.scroll:HookScript("OnShow", function() view:Update() end)
    FGT.detailViewport, FGT.detailBody = view, view.content
end

local DETAIL_ICON = 70
local detailIcon = NewIcon(FGT.detailBody, DETAIL_ICON)
detailIcon:SetPoint("TOPLEFT", 22, -24)
-- Goals with one final reward (weapons, mounts): hovering the big icon
-- shows that item, compared with what you're wearing (Karl). The reward
-- is the goal's `rewardItem`, or the first item of its `completeWith`.
detailIcon:EnableMouse(true)
detailIcon:SetScript("OnEnter", function(self)
    local id = FGT.detailReward
    if id then FGT.ShowItemTip(self, id, nil, FGT.detailRewardName, true) end
end)
detailIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
detailIcon:SetScript("OnMouseUp", function(_, button)
    FGT.PreviewItemClick(FGT.detailReward, button)
end)

local detailTag = NewFontString(FGT.detailBody, 10, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
detailTag:SetPoint("TOPLEFT", detailIcon, "TOPRIGHT", 12, -1)

local detailTitle = NewTitleString(FGT.detailBody, 20)
detailTitle:SetPoint("TOPLEFT", detailTag, "BOTTOMLEFT", 0, -8)
detailTitle:SetPoint("RIGHT", -22, 0)
detailTitle:SetWordWrap(true)

-- Difficulty + time estimate as two chips.
local detailDiffChip = NewChip(FGT.detailBody, 9)
detailDiffChip:SetPoint("TOPLEFT", detailIcon, "BOTTOMLEFT", 0, -20)

local detailTimeChip = NewChip(FGT.detailBody, 9)
detailTimeChip:SetPoint("LEFT", detailDiffChip, "RIGHT", 10, 0)

local detailNote = NewFontString(FGT.detailBody, 12, "", C.INK2[1], C.INK2[2], C.INK2[3])
detailNote:SetPoint("TOPLEFT", detailDiffChip, "BOTTOMLEFT", 0, -24)
detailNote:SetPoint("RIGHT", -22, 0)
detailNote:SetWordWrap(true)
detailNote:SetJustifyH("LEFT")

-- Personal notes are separate from the Library's description and progress.
do
    local n = CreateFrame("Frame", nil, FGT.detailBody)
    n:EnableMouse(false) -- display only; the note icon is the sole editor entry point
    n:SetPoint("TOPLEFT", detailNote, "BOTTOMLEFT", 0, -10)
    n:SetPoint("RIGHT", FGT.detailBody, "RIGHT", -22, 0)
    n.text = NewFontString(n, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
    n.text:SetPoint("TOPLEFT")
    n.text:SetPoint("RIGHT")
    n.text:SetWordWrap(true)
    n.text:SetJustifyH("LEFT")
    n:Hide()
    FGT.personalNote = n

    function FGT.GoalNote(goal)
        local notes = ForeverGoalTrackerDB and ForeverGoalTrackerDB.notes
        local text = notes and goal and notes[goal.id]
        return type(text) == "string" and text or ""
    end

    function FGT.SetGoalNote(goal, text)
        local DB = ForeverGoalTrackerDB
        if not (DB and goal and FGT.GoalById(goal.id)) then return end
        text = (text or ""):gsub("\r", ""):match("^%s*(.-)%s*$")
        DB.notes = DB.notes or {}
        DB.notes[goal.id] = text ~= "" and text or nil
        if selectedId == goal.id then SelectGoal(goal.id, true) end
    end

    local b = CreateFrame("Button", nil, FGT.detailBody)
    b:SetSize(22, 22)
    FGT.detailNoteBtn = b
    function FGT.StyleNoteButton()
        b:RefreshIcon()
    end
    b:SetScript("OnEnter", function(self)
        FGT.StyleNoteButton()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(FGT.GoalNote(self.goal) ~= "" and "Edit personal note" or "Add personal note", C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() FGT.StyleNoteButton(); GameTooltip:Hide() end)
    b:SetScript("OnClick", function(self) if self.goal then FGT.OpenNoteCard(self.goal) end end)
    FGT.IconButton(b, "note", 15) -- same dim/rest and additive hover as Settings and Close

    function FGT.LayoutPersonalNote(goal)
        local text = FGT.GoalNote(goal)
        b.goal = goal
        b:SetShown(goal ~= nil)
        FGT.StyleNoteButton()
        n:SetShown(text ~= "")
        if text == "" then return detailNote end
        -- User text stays literal, even if it contains WoW formatting codes.
        n.text:SetWidth(math.max(120, FGT.detailBody:GetWidth() - 44))
        n.text:SetText("|cffcc9e29NOTE:|r " .. text:gsub("|", "||"))
        n:SetHeight(math.max(14, math.ceil(n.text:GetStringHeight())))
        return detailNote
    end

    function FGT.CloseNoteCard(instant)
        local T = FGT.noteCard
        if not T then return end
        local W = FGT.welcome
        if instant ~= true and T:IsShown() and T.greyActive and W.Motion() ~= "off" then
            if T.closing then return end
            T.closing = true
            T.box:ClearFocus()
            W.Tween("noteOpen", nil)
            local alpha, scale, shade = T:GetAlpha(), T:GetScale(), T.greyAmount or 1
            W.Tween("noteClose", 0.18, function(p)
                local e = W.EaseOut(p)
                T:SetAlpha(alpha * (1 - e))
                T.shadow:SetAlpha(alpha * (1 - e))
                T:SetScale(W.Motion() == "full" and scale * (1 - 0.015 * e) or 1)
                T.greyAmount = shade * (1 - e)
                T.dim:SetVertexColor(0, 0, 0, 0.72 * T.greyAmount)
                W.SetGrey(T.greyAmount)
            end, function() FGT.CloseNoteCard(true) end)
            return
        end
        if W and W.Tween then W.Tween("noteOpen", nil); W.Tween("noteClose", nil) end
        if T.greyActive then W.Grey(false) end
        T.greyActive, T.greyAmount, T.closing = nil, nil, nil
        T.box:ClearFocus(); T:Hide(); T.catcher:Hide(); T.goal = nil
        T:SetAlpha(1); T:SetScale(1)
        if T.shadow then T.shadow:SetAlpha(1) end
    end

    function FGT.SaveNoteCard()
        local T = FGT.noteCard
        if not (T and T.goal) or T.closing then return end
        local goal, text = T.goal, T.box:GetText()
        if not (text and text:find("%S")) then return end
        FGT.CloseNoteCard(true) -- restore colors before redrawing the saved note
        FGT.SetGoalNote(goal, text)
    end

    function FGT.DeleteNoteCard()
        local T = FGT.noteCard
        if not (T and T.goal) or T.closing then return end
        local goal = T.goal
        FGT.CloseNoteCard(true)
        FGT.SetGoalNote(goal, "")
    end

    function FGT.StyleNoteControls()
        local T = FGT.noteCard
        if not (T and T.save) then return end
        local hasText = (T.box:GetText() or ""):find("%S") ~= nil
        -- Count UTF-8 characters, rather than bytes, for accented text too.
        local _, count = (T.box:GetText() or ""):gsub("[^\128-\191]", "")
        T.hint:SetText(string.format("%d / 240 characters", count))
        T.save.gold = hasText
        T.save:SetEnabled(hasText)
        local hover = T.save:IsMouseOver()
        T.save:SetEtch(hasText and (hover and STYLE.goldHover or STYLE.rowSel) or STYLE.muted)
        T.save.text:SetTextColor(unpack(hasText and (hover and { 1, 0.95, 0.75 } or C.TITLE) or C.SUBTEXT))
        local saved = FGT.GoalNote(T.goal) ~= ""
        T.delete:SetEnabled(saved)
        T.delete:SetEtch(saved and (T.delete:IsMouseOver() and STYLE.dangerHv or STYLE.button) or STYLE.muted)
        local c = saved and { 1, 0.5, 0.42 } or C.SUBTEXT
        T.delete.text:SetTextColor(c[1], c[2], c[3])
    end

    function FGT.OpenNoteCard(goal)
        FGT.CloseNoteCard(true)
        GameTooltip:Hide()
        if FGT.CloseTargetCard then FGT.CloseTargetCard() end
        local T = FGT.noteCard
        if not T then
            T = CreateFrame("Frame", nil, main, "BackdropTemplate")
            FGT.noteCard = T
            T:SetSize(330, 270)
            T:SetFrameLevel(main:GetFrameLevel() + 60)
            T:SetClampedToScreen(true)
            T:EnableMouse(true)
            Etch(T, STYLE.rowSel, 12)
            FGT.AddDropShadow(T, 64, 0.85, 8, 10) -- broad, soft and dark behind the note card
            T.catcher = CreateFrame("Button", nil, main)
            T.catcher:SetAllPoints(main)
            T.catcher:SetFrameLevel(main:GetFrameLevel() + 55)
            T.catcher:RegisterForClicks("AnyUp")
            T.catcher:EnableMouseWheel(true)
            T.catcher:SetScript("OnMouseWheel", function() end)
            T.catcher:SetScript("OnClick", FGT.CloseNoteCard)
            T.dim = T.catcher:CreateTexture(nil, "BACKGROUND")
            T.dim:SetTexture(SOLID)
            T.dim:SetPoint("TOPLEFT", 4, -4)
            T.dim:SetPoint("BOTTOMRIGHT", -4, 4)
            T.dim:SetVertexColor(0, 0, 0, 0.72) -- same dark layer as the welcome wizard
            T.close = CreateFrame("Button", nil, T)
            T.close:SetSize(20, 20)
            T.close:SetPoint("TOPRIGHT", -10, -10)
            T.close:SetScript("OnClick", FGT.CloseNoteCard)
            FGT.IconButton(T.close, "close", 13)
            T.title = NewTitleString(T, 13)
            T.title:SetPoint("TOPLEFT", 14, -14)
            T.title:SetPoint("RIGHT", T, "RIGHT", -42, 0)
            T.title:SetText("Add personal note")
            T.sub = NewFontString(T, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
            T.sub:SetPoint("TOPLEFT", T.title, "BOTTOMLEFT", 0, -6)
            T.sub:SetPoint("RIGHT", T, "RIGHT", -14, 0)
            T.sub:SetWordWrap(true)
            T.sub:SetJustifyH("LEFT")
            T.field = CreateFrame("Frame", nil, T, "BackdropTemplate")
            T.field:SetPoint("TOPLEFT", T.sub, "BOTTOMLEFT", 0, -12)
            T.field:SetPoint("BOTTOMRIGHT", T, "BOTTOMRIGHT", -14, 65)
            Skin(T.field, { 0, 0, 0, 0.6 }, C.BOX_RING)
            T.scroll = CreateFrame("ScrollFrame", nil, T.field)
            T.scroll:SetPoint("TOPLEFT", 4, -4)
            T.scroll:SetPoint("BOTTOMRIGHT", -4, 4)
            T.box = CreateFrame("EditBox", nil, T.scroll)
            T.box:SetWidth(294)
            T.box:SetHeight(110)
            T.scroll:SetScrollChild(T.box)
            T.box:SetMultiLine(true)
            T.box:SetAutoFocus(false)
            T.box:SetFont(FONT, 12, "")
            T.box:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
            T.box:SetTextInsets(8, 8, 8, 8)
            T.box:SetMaxLetters(240)
            T.box:SetScript("OnEscapePressed", FGT.CloseNoteCard)
            T.box:SetScript("OnTextChanged", FGT.StyleNoteControls)
            T.scroll:EnableMouseWheel(true)
            T.scroll:SetScript("OnMouseWheel", function(self, delta)
                self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 24)))
            end)
            T.scroll:SetScript("OnSizeChanged", function(self) T.box:SetWidth(self:GetWidth()) end)
            T.box:SetScript("OnCursorChanged", function(_, _, y, _, height)
                local top = -y
                local current = T.scroll:GetVerticalScroll()
                local bottom = top + height + 8
                if top < current then T.scroll:SetVerticalScroll(math.max(0, top))
                elseif bottom > current + T.scroll:GetHeight() then
                    T.scroll:SetVerticalScroll(math.max(0, bottom - T.scroll:GetHeight()))
                end
            end)
            T.hint = NewFontString(T, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
            T.hint:SetPoint("BOTTOMLEFT", 14, 47)
            T.hint:SetText("0 / 240 characters")
            for i, label in ipairs({ "Save", "Delete note" }) do
                local btn = CreateFrame("Button", nil, T, "BackdropTemplate")
                btn:SetSize(90, 24)
                btn:SetPoint("BOTTOMLEFT", 14 + (i - 1) * 100, 14)
                Etch(btn, STYLE.button, 10)
                btn.text = NewFontString(btn, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
                btn.text:SetPoint("CENTER")
                btn.text:SetText(label)
                btn:SetScript("OnEnter", FGT.StyleNoteControls)
                btn:SetScript("OnLeave", FGT.StyleNoteControls)
                btn:SetScript("OnClick", i == 1 and FGT.SaveNoteCard or FGT.DeleteNoteCard)
                if i == 1 then T.save = btn else T.delete = btn end
            end
            T:Hide(); T.catcher:Hide()
        end
        T.goal = goal
        T:ClearAllPoints()
        T:SetPoint("CENTER", main, "CENTER")
        T.sub:SetText(goal.name)
        T.box:SetText(FGT.GoalNote(goal))
        FGT.StyleNoteControls()
        T.scroll:SetVerticalScroll(0)
        T.catcher:Show(); T:Show()
        T.box:SetFocus()
        local W = FGT.welcome
        W.Grey(true)
        T.greyActive = true
        local full = W.Motion() == "full"
        W.Tween("noteOpen", 0.28, function(p)
            local e = W.EaseOut(p)
            T.greyAmount = e
            T.dim:SetVertexColor(0, 0, 0, 0.72 * e)
            W.SetGrey(e)
            T:SetAlpha(e)
            T.shadow:SetAlpha(e)
            local u = p - 1
            local pop = 1 + 1.7 * u * u * u + 0.7 * u * u
            T:SetScale(full and (0.96 + 0.04 * pop) or 1)
        end, function() T:SetAlpha(1); T:SetScale(1); T.shadow:SetAlpha(1) end)
    end
    main:HookScript("OnHide", function() FGT.CloseNoteCard(true) end)
end

-- WoW Forever: a NEW chip beside the difficulty chips, and a slim blue
-- notice under the description for goals not confirmed in Forever yet.
do
    local chip = NewChip(FGT.detailBody, 9)
    chip:SetLabel(FGT.ForeverDot(13) .. "NEW IN FOREVER", C.FOREVER_LIGHT)
    chip:SetBackdropBorderColor(C.FOREVER_DEEP[1], C.FOREVER_DEEP[2], C.FOREVER_DEEP[3], 1)
    chip:Hide()
    FGT.detailNewChip = chip

    -- "COMPLETED OCT 6, 2026" on finished goals
    local done = NewChip(FGT.detailBody, 9)
    done:SetBackdropBorderColor(0.16, 0.35, 0.10, 1)
    done:Hide()
    FGT.detailDoneChip = done

    local n = CreateFrame("Frame", nil, FGT.detailBody, "BackdropTemplate")
    n:SetPoint("TOPLEFT", detailNote, "BOTTOMLEFT", 0, -12)
    n:SetPoint("RIGHT", -16, 0)
    Etch(n, STYLE.forever, 10)
    n:SetBackdropBorderColor(0, 0, 0, 0)
    ApplyHGradient(n.etchBg, STYLE.forever.top, STYLE.forever.top, 1, 0)
    ApplyHGradient(n.etchHi, STYLE.forever.edge, STYLE.forever.edge, 0.7, 0)
    local bottom = n:CreateTexture(nil, "BACKGROUND")
    bottom:SetTexture(SOLID)
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", 2, 2)
    bottom:SetPoint("BOTTOMRIGHT", -2, 2)
    ApplyHGradient(bottom, STYLE.forever.edge, STYLE.forever.edge, 0.7, 0)
    n.text = NewFontString(n, 10, "", 0.72, 0.84, 1.00)
    n.text:SetPoint("TOPLEFT", n, "TOPLEFT", 10, -9)
    n.text:SetJustifyH("LEFT")
    n.text:SetWordWrap(true)
    n:Hide()
    FGT.foreverNotice = n
end

-- Raid lockout: on a raid goal (data field `instance` = { mapId, name, other name }),
-- a "SAVED UNTIL TUE" chip when the character you're on is saved there.
-- The game sends lockouts after RequestRaidInfo (UPDATE_INSTANCE_INFO);
-- they're kept for this session only, since they change every week.
do
    local chip = NewChip(FGT.detailBody, 9)
    chip:SetBackdropBorderColor(0.45, 0.22, 0.16, 1)
    chip:EnableMouse(true)
    chip:SetScript("OnEnter", function(self)
        if not self.reset then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Saved this week", C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:AddLine(string.format("This character is saved to %s until %s.",
            self.raid, date("%A at %H:%M", self.reset)), C.INK2[1], C.INK2[2], C.INK2[3], true)
        GameTooltip:Show()
    end)
    chip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    chip:Hide()
    FGT.detailLockChip = chip
    FGT.lockouts = {}

    -- seconds until reset -> absolute time, by map ID and by name
    local function ReadLockouts()
        local out = {}
        local n = GetNumSavedInstances and GetNumSavedInstances() or 0
        for i = 1, n do
            local name, _, reset, _, locked, extended, _, _, _, _, _, _, _, mapId = GetSavedInstanceInfo(i)
            if name and reset and reset > 0 and (locked or extended) then
                local at = time() + reset
                out[name] = at
                if mapId then out[mapId] = at end
            end
        end
        FGT.lockouts = out
        if FGT.lockGoal and FGT.detailBody:IsVisible() then FGT.LayoutLockout(FGT.lockGoal, FGT.lockAnchor) end
    end
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    pcall(f.RegisterEvent, f, "UPDATE_INSTANCE_INFO")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            if RequestRaidInfo then RequestRaidInfo() end
        else
            pcall(ReadLockouts)
        end
    end)

    -- anchor: the chip it sits after
    function FGT.LayoutLockout(goal, anchor)
        FGT.lockGoal, FGT.lockAnchor = goal, anchor
        local inst = goal.instance
        local at = inst and (FGT.lockouts[inst[1]] or FGT.lockouts[inst[2]] or (inst[3] and FGT.lockouts[inst[3]]))
        if at and at > time() then
            chip.reset, chip.raid = at, inst[2]
            chip:SetLabel("SAVED UNTIL " .. string.upper(date("%a", at)), C.INK2)
            chip:ClearAllPoints()
            chip:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
            chip:Show()
        else
            chip.reset = nil
            chip:Hide()
        end
    end
end

-- "Edit goal": a quiet pencil at the top right of the goal page, only on
-- goals you can edit (a `target`). Opens the same card as right-click >
-- Edit goal. Grey at rest, gold on hover, with an "Edit goal" tooltip.
do
    local b = CreateFrame("Button", nil, FGT.detailBody)
    b:SetSize(22, 22)
    b:SetPoint("TOPRIGHT", FGT.detailBody, "TOPRIGHT", -12, -12)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexture(FGT.Icon("pencil-white")) -- grey, tinted gold on hover
    b.icon:SetSize(15, 15)
    b.icon:SetPoint("CENTER")
    local function Tint(on)
        local c = on and C.ACCENT or C.SUBTEXT
        b.icon:SetVertexColor(c[1], c[2], c[3], on and 1 or 0.8)
    end
    Tint(false)
    b:SetScript("OnEnter", function(self)
        Tint(true)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Edit goal", C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() Tint(false); GameTooltip:Hide() end)
    b:SetScript("OnClick", function(self)
        GameTooltip:Hide()
        if self.goal and FGT.OpenTargetCard then FGT.OpenTargetCard(self.goal) end
    end)
    b:Hide()
    FGT.detailEditBtn = b
    function FGT.UpdateEditButton(goal)
        b.goal = goal
        b:SetShown(goal and goal.target ~= nil)
        -- the reset arrow sits left of the pencil (or in its place), and a
        -- long title stays clear of both
        local resetShown = goal and not goal.autoLevels
        if FGT.resetBtn then
            FGT.resetBtn:ClearAllPoints()
            FGT.resetBtn:SetPoint("TOPRIGHT", FGT.detailBody, "TOPRIGHT", b:IsShown() and -46 or -20, -22)
        end
        local icons = (b:IsShown() and 1 or 0) + (resetShown and 1 or 0)
        FGT.detailNoteBtn:ClearAllPoints()
        FGT.detailNoteBtn:SetPoint("TOPRIGHT", FGT.detailBody, "TOPRIGHT", -20 - 26 * icons, -22)
        icons = icons + 1
        -- The title begins below the action icons and can use the full width.
        detailTitle:SetPoint("RIGHT", FGT.detailBody, "RIGHT", -22, 0)
        b:ClearAllPoints(); b:SetPoint("TOPRIGHT", FGT.detailBody, "TOPRIGHT", -20, -22)
    end
end

local detailBar = NewBar(FGT.detailBody, 8)
detailBar.celebrate = true -- gold shine when it glides to 100%
detailBar.label:ClearAllPoints()
detailBar.label:SetPoint("BOTTOMLEFT", detailBar, "TOPLEFT", 0, 4)
detailBar.label:SetJustifyH("LEFT")
do -- The banner track keeps its bevel inside the bar, without an extra line underneath.
    detailBar.lip:Hide()
    Skin(detailBar, {0.045,0.042,0.035,1}, {0.24,0.21,0.15,1})
    local track = detailBar:CreateTexture(nil, "BACKGROUND", nil, 1)
    track:SetTexture(SOLID)
    track:SetPoint("TOPLEFT", 1,-1)
    track:SetPoint("BOTTOMRIGHT", -1,1)
    ApplyVGradient(track, {0.045,0.042,0.035}, {0.10,0.09,0.065}, 1,1)
    local shadow = detailBar:CreateTexture(nil, "BORDER")
    shadow:SetTexture(SOLID)
    shadow:SetHeight(2)
    shadow:SetPoint("TOPLEFT", 1,-1)
    shadow:SetPoint("TOPRIGHT", -1,-1)
    ApplyVGradient(shadow, {0,0,0}, {0,0,0}, 0.75,0)
    local bevel = detailBar:CreateTexture(nil, "BORDER")
    bevel:SetTexture(SOLID)
    bevel:SetHeight(1)
    bevel:SetPoint("BOTTOMLEFT", 1,1)
    bevel:SetPoint("BOTTOMRIGHT", -1,1)
    bevel:SetVertexColor(0.28,0.24,0.16,0.8)
end
detailBar:SetPoint("TOPLEFT", detailNote, "BOTTOMLEFT", 0, -12)
detailBar:SetPoint("RIGHT", -22, 0)

do -- Banner art lives behind the real widgets; no duplicate UI renderer.
    local B = CreateFrame("Frame", nil, detailPanel)
    B:EnableMouse(false)
    B:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 4, -4)
    B:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -4, -4)
    B:SetHeight(500) -- measured below; independent of the text scroll offset
    B.background = detailPanel:CreateTexture(nil, "BACKGROUND", nil, -4)
    B.background:SetTexture(SOLID)
    B.background:SetAllPoints(B)
    B.border = CreateFrame("Frame", nil, B)
    B.border:SetHeight(2)
    B.border:SetPoint("BOTTOMLEFT", B, "BOTTOMLEFT")
    B.border:SetPoint("BOTTOMRIGHT", B, "BOTTOMRIGHT")
    -- The banner ends in a soft blend now, rather than a separate ruled edge.
    B.border:SetAlpha(0)
    ApplyVGradient(B.background, STYLE.panel.top, STYLE.panel.bottom, 0, 0)
    B.art = detailPanel:CreateTexture(nil, "BACKGROUND", nil, -3)
    B.art:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -4,-4)
    -- Fade the actual image alpha, avoiding a colored rectangle at its left edge.
    ApplyHGradient(B.art, {1,1,1}, {1,1,1}, 0,0.18)
    B.fadeStrips = {}
    for i=1,64 do
        local t = detailPanel:CreateTexture(nil, "BACKGROUND", nil, -3)
        B.fadeStrips[i] = t
        t:Hide()
    end
    B.left = detailPanel:CreateTexture(nil, "BACKGROUND", nil, -2)
    B.top = detailPanel:CreateTexture(nil, "BACKGROUND", nil, -1)
    B.bottom = detailPanel:CreateTexture(nil, "BACKGROUND", nil, -1)
    for _, t in ipairs({B.left,B.top,B.bottom}) do t:SetTexture(SOLID) end
    B.left:SetPoint("TOPLEFT", B.art, "TOPLEFT")
    B.top:SetPoint("TOPRIGHT", B, "TOPRIGHT")
    B.bottom:SetPoint("BOTTOMRIGHT", B, "BOTTOMRIGHT")
    ApplyHGradient(B.left, {0.012,0.011,0.008}, {0.012,0.011,0.008}, 1, 0)
    ApplyVGradient(B.top, {0.02,0.017,0.012}, {0.02,0.017,0.012}, 0.65, 0)
    B.bottom:Hide() -- removed bottom veil; never draw below the panel
    B.artPaths = {
        thunderfury = "thunderfury-banner.blp",
        rhokdelar = "rhokdelar-banner.blp",
        raid_ony = "raid_ony-banner.blp",
        raid_bwl = "raid_bwl-banner.blp",
        mount_dreadsteed = "mount_dreadsteed-banner.blp",
        mount_charger = "mount_charger-banner.blp",

        quelserrar = "quelserrar-banner.blp",
        ashbringer = "ashbringer-banner.blp", atiesh = "atiesh-banner.blp", sulfuras = "sulfuras-banner.blp",
        benediction = "benediction-banner.blp",
        raid_mc = "raid_mc-banner.blp",
        att_mc = "att_mc-banner.blp",
        set_tier1 = "set_tier1-banner.blp",
        set_tier25 = "set_tier25-banner.blp",
        fishing_extravaganza = "fishing_extravaganza-banner.blp",
        rep_ambassador_horde = "rep_ambassador_horde-banner.blp",
        raid_naxx = "raid_naxx-banner.blp",
        tier3 = "tier3-banner.blp",
        att_naxx = "att_naxx-banner.blp",
        lokdelar = "lokdelar-banner.blp", frostsaber = "frostsaber-banner.blp",
        set_viper = "set_viper-banner.blp", rep_cenarion = "rep_cenarion-banner.blp",
        key_scholo = "key_scholo-banner.blp",
        rep_argentdawn = "rep_argentdawn-banner.blp",
    }
    B.artAspects = {
        rep_ambassador_horde = 4/3,
        fishing_extravaganza = 4/3,
        set_tier25 = 4/3,
        thunderfury = 4/3,
        rhokdelar = 4/3,
        raid_ony = 4/3,
        raid_bwl = 4/3,
        mount_dreadsteed = 4/3,
        mount_charger = 0.7501831501831502,

        quelserrar = 4/3,
        ashbringer = 4/3, atiesh = 4/3, sulfuras = 4/3,
        benediction = 4/3,
        raid_mc = 4/3,
        att_mc = 4/3,
        set_tier1 = 4/3,
        raid_naxx = 0.6679712981082844,
        tier3 = 4/3,
        att_naxx = 4/3,
        lokdelar = 4/3, frostsaber = 4/3, set_viper = 4/3,
        rep_cenarion = 4/3, key_scholo = 4/3,
        rep_argentdawn = 4/3,
        epicmounts = 4/3,
    }
    -- Faction variants share their goal's aspect ratio and monochrome treatment.
    -- Choose from the logged-in character, independent of Library filters/roster.
    B.factionArtPaths = {
        tier3_warlock = {Alliance = "tier3_warlock-alliance-banner.blp"},
        set_tier2_warlock = {Alliance = "set_tier2_warlock-alliance-banner.blp"},
        tier3_druid = {Horde = "tier3_druid-horde-banner.blp"},
        set_tier1_warlock = {
            Alliance = "set_tier1_warlock-alliance-banner.blp",
            Horde = "set_tier1_warlock-banner.blp",
        },
        set_tier1_priest = {
            Alliance = "set_tier1_priest-banner.blp",
        },
        set_tier2_priest = {
            Alliance = "set_tier2_priest-banner.blp",
        },
        tier3_priest = {
            Alliance = "tier3_priest-banner.blp",
        },
        set_tier2_warrior = {
            Alliance = "set_tier2_warrior-alliance-banner.blp",
            Horde = "set_tier2_warrior-banner.blp",
        },
    }
    -- Optional character variants: every specified condition must match.
    -- Most specific compatible artwork wins; list order breaks equal scores.
    -- Only approved runtime textures belong here, never source/review files.
    B.artVariants = {
        allclasses = {
            {path="tier3_hunter-banner.blp", faction="Horde", class="HUNTER", race="Troll"},
            {path="allclasses_nightelf_hunter-banner.blp", faction="Alliance", class="HUNTER", race="NightElf"},
            {path="allclasses_horde_hunter-banner.blp", faction="Horde", class="HUNTER"},
            {path="allclasses_dwarf_shaman-banner.blp", faction="Alliance", class="SHAMAN", race="Dwarf"},
            {path="allclasses_undead_paladin-banner.blp", faction="Horde", class="PALADIN", race="Scourge"},
            {path="allclasses_troll_mage-banner.blp", faction="Horde", class="MAGE", race="Troll"},
            {path="allclasses_troll_mage-banner.blp", faction="Horde", class="MAGE"},
            {path="set_tier1_priest-banner.blp", faction="Alliance", class="PRIEST", race="Human"},
            {path="set_tier2_priest-banner.blp", faction="Alliance", class="PRIEST", race="Dwarf"},
            {path="rhokdelar-banner.blp", faction="Alliance", class="HUNTER"},
            {path="set_tier1_mage-banner.blp", faction="Alliance", class="MAGE", race="Human"},
            {path="set_tier1_mage-banner.blp", faction="Alliance", class="MAGE"},
            {path="tier3_warrior-banner.blp", faction="Alliance", class="WARRIOR", race="Dwarf"},
            {path="set_tier2_warrior-alliance-banner.blp", faction="Alliance", class="WARRIOR", race="NightElf"},
            {path="set_tier2_warrior-alliance-banner.blp", faction="Alliance", class="WARRIOR"},
            {path="set_tier2_warrior-banner.blp", faction="Horde", class="WARRIOR"},
            {path="set_tier2_druid-banner.blp", faction="Alliance", class="DRUID"},
            {path="set_tier2_paladin-banner.blp", faction="Alliance", class="PALADIN"},
            {path="set_tier2_shaman-banner.blp", faction="Horde", class="SHAMAN", race="Tauren"},
            {path="set_tier1_shaman-banner.blp", faction="Horde", class="SHAMAN"},
            {path="set_tier1_warlock-banner.blp", faction="Horde", class="WARLOCK"},
        },
        epicmounts = {
            {path="epicmounts_human-banner.blp", faction="Alliance", race="Human", part=1},
            {path="epicmounts_dwarf-banner.blp", faction="Alliance", race="Dwarf", part=2},
            {path="epicmounts_nightelf-banner.blp", faction="Alliance", race="NightElf", part=3},
            {path="epicmounts_gnome-banner.blp", faction="Alliance", race="Gnome", part=4},
            {path="epicmounts_orc-banner.blp", faction="Horde", race="Orc", part=5},
            {path="epicmounts_troll-banner.blp", faction="Horde", race="Troll", part=8},
            {path="epicmounts_tauren-banner.blp", faction="Horde", race="Tauren", part=6},
            {path="epicmounts_undead-banner.blp", faction="Horde", race="Scourge", part=7},
            {path="epicmounts_skyborne-banner.blp", faction="Alliance", race="Skyborne", part=9},
        },
    }
    B.pvpArtVariants = {
        {path="set_tier2_warrior-alliance-banner.blp", faction="Alliance"},
        {path="set_tier2_warrior-banner.blp", faction="Horde"},
    }
    -- Shared combat artwork for kills and duels on either faction.
    B.artVariants.pvp_hk = {{path="pvp_drums_of_war-banner.blp"}}
    B.artVariants.pvp_duelist = {{path="pvp_drums_of_war-banner.blp"}}
    B.artVariants.pvp_set_mail_horde = {{path="pvp_set_mail_horde-banner.blp"}}
    B.artVariants.pvp_mount_ally = {{path="pvp_mount_ally-banner.blp"}}
    B.artVariants.pvp_avmount_ally = {{path="pvp_mount_ally-banner.blp"}}
    function B:PlayerArtContext()
        -- Use stable file tokens, not localized class/race display names.
        local race, class
        if UnitRace then race = select(2, UnitRace("player")) end
        if UnitClass then class = select(2, UnitClass("player")) end
        return {race=race, class=class, faction=UnitFactionGroup and UnitFactionGroup("player")}
    end
    function B:BestArtVariant(variants, player)
        local best, score = nil, -1
        for _, variant in ipairs(variants or {}) do
            if (not variant.faction or variant.faction == player.faction)
                and (not variant.class or variant.class == player.class)
                and (not variant.race or variant.race == player.race) then
                local weight = (variant.class and 100 or 0) + (variant.race and 20 or 0)
                    + (variant.faction and 10 or 0)
                if weight > score then best, score = variant, weight end
            end
        end
        return best
    end
    function B:ResolveArt(id)
        local player = self:PlayerArtContext()
        local goal = FGT.GoalById(id)
        local pvp = goal and goal.category == "PvP"
        if pvp then
            player = {faction=goal.faction}
        end
        local choices = self.artVariants[id]
            or (pvp and goal.armorParent and self.artVariants[goal.armorParent])
            or (pvp and self.pvpArtVariants)
        local best = self:BestArtVariant(choices, player)
        if not best and id == "epicmounts" then
            -- Missing race art: prefer a sole selected mount in this faction.
            local selected = ForeverGoalTrackerDB and ForeverGoalTrackerDB.activeParts
                and ForeverGoalTrackerDB.activeParts.epicmounts or {}
            local count, part = 0, nil
            for key, active in pairs(selected) do
                if active then count, part = count + 1, key end
            end
            for _, variant in ipairs(choices) do
                if count == 1 and variant.part == part and variant.faction == player.faction then best = variant end
            end
            -- A faction mount is the final fallback when its race has no art.
            if not best then
                for _, variant in ipairs(choices) do
                    if variant.faction == player.faction then best = variant; break end
                end
            end
        end
        if best then return best.path, best.aspect or 4/3, best.preprocessed ~= false end
        local variants = self.factionArtPaths[id]
        return (variants and variants[player.faction]) or self.artPaths[id],
            self.artAspects[id] or 1, self.preprocessed[id] or false
    end
    function B:ArtPath(id)
        local path = self:ResolveArt(id)
        return path
    end
    -- Approved monochrome masters need no runtime desaturation.
    -- Older color banners keep their existing look until their final pass.
    B.preprocessed = {
        rep_ambassador_horde=true,
        fishing_extravaganza=true,
        set_tier25=true,
        tier3=true, att_naxx=true,
        rep_argentdawn=true,
        epicmounts=true,
        ashbringer=true, atiesh=true, sulfuras=true, thunderfury=true,
        rhokdelar=true, raid_ony=true, mount_dreadsteed=true,
        quelserrar=true, benediction=true, raid_bwl=true,
        raid_mc=true, att_mc=true, set_tier1=true,
        lokdelar=true, frostsaber=true, set_viper=true, rep_cenarion=true, key_scholo=true,
    }
    -- Individual sets can carry their own banner; other sets retain the
    -- collection's existing artwork until a dedicated image is approved.
    for _, parent in pairs(FGT.armorCollections) do
        for _, child in ipairs(parent.armorChildren) do
            B.artPaths[child.id] = B.artPaths[parent.id]
            B.artAspects[child.id] = B.artAspects[parent.id]
            B.preprocessed[child.id] = B.preprocessed[parent.id]
        end
    end
    for _, id in ipairs({"set_tier1_rogue", "set_tier2_rogue", "tier3_rogue",
            "set_tier1_hunter", "set_tier2_hunter", "tier3_hunter", "set_tier1_mage", "set_tier2_mage",
            "set_tier1_warrior", "set_tier2_warrior", "set_tier1_druid", "set_tier2_druid",
            "set_tier1_shaman", "set_tier2_shaman", "tier3_druid", "set_tier1_warlock", "set_tier2_warlock",
            "tier3_warrior", "tier3_mage", "tier3_priest", "tier3_shaman", "tier3_warlock", "tier3_paladin", "set_tier2_paladin", "set_tier1_priest", "set_tier2_priest", "set_violet_sorcerer", "raid_hyjal", "raid_barrow",
            "raid_aq20", "raid_aq40", "mount_deathcharger", "raid_zg", "key_dm", "mount_qiraji", "rep_timbermaw", "gold_5k", "set_tier1_paladin"}) do
        B.artPaths[id] = id .. "-banner.blp"
        B.artAspects[id], B.preprocessed[id] = 4/3, true
    end
    for _, id in ipairs({"rep_zandalar", "mount_raptor", "mount_tiger"}) do
        B.artPaths[id] = B.artPaths.raid_zg
        B.artAspects[id], B.preprocessed[id] = 4/3, true
    end
    -- Keep the approved lone battle tank shared by the four AQ40 colors,
    -- independently of future artwork on the Scarab Lord's black mount.
    for _, color in ipairs({"blue", "green", "yellow", "red"}) do
        local id = "mount_qiraji_" .. color
        B.artPaths[id] = "mount_qiraji_aq-banner.blp"
        B.artAspects[id], B.preprocessed[id] = 4/3, true
    end
    -- Shared artwork for PvP ranks, mounts, reputation and class sets.
    for _, goal in ipairs(FGT.goals) do
        if goal.category == "PvP" then
            B.artPaths[goal.id] = "pvp_shared-banner.blp"
            B.artAspects[goal.id], B.preprocessed[goal.id] = 4/3, true
        end
    end
    -- Leveling art follows the logged-in character, independent of selected
    -- classes and the account roster. Shared art covers missing variants.
    B.artPaths.allclasses = "pvp_shared-banner.blp"
    B.artAspects.allclasses, B.preprocessed.allclasses = 4/3, true
    -- Brightness tuning multiplies the existing reveal and bottom fades.
    -- Approved defaults go here; in-game overrides are saved per goal.
    B.artOpacity = {}
    function B:GetArtOpacity()
        local id = self.goal and self.goal.id
        local db = ForeverGoalTrackerDB
        local value = id and db and db.bannerOpacity and db.bannerOpacity[id]
        if value == nil then value = id and self.artOpacity[id] end
        return math.max(0, math.min(1, tonumber(value) or 1))
    end
    B.imageSeen = {} -- per-session, never written to SavedVariables
    function B:SetImageFade(amount)
        self.imageFade = amount
        -- Keep art on the panel's working background layer, below text.
        local alpha = 0.18*amount*self:GetArtOpacity()
        ApplyHGradient(self.art, {1,1,1}, {1,1,1}, 0,alpha)
        for _,t in ipairs(self.fadeStrips) do
            ApplyHGradient(t, {1,1,1}, {1,1,1}, 0,alpha*(t.fadeWeight or 0))
        end
    end
    function B:StopImageFade()
        self:SetScript("OnUpdate", nil)
        self.revealGoal = nil
        self:SetImageFade(1)
    end
    function B:RevealImages()
        if not self.goal or not self:IsVisible() then return end
        local id = self.goal.id
        if self.revealGoal == id then return end -- progress/layout refreshes keep the fade
        self:StopImageFade()
        self.revealGoal = id
        if self.imageSeen[id] or FGT.Setting("celebrations") == "off" then
            self.imageSeen[id] = true
            return
        end
        self:SetImageFade(0)
        self.revealElapsed = 0
        self:SetScript("OnUpdate", function(frame, elapsed)
            frame.revealElapsed = frame.revealElapsed + elapsed
            local p = math.min(1, frame.revealElapsed/1.1)
            if FGT.Setting("celebrations") == "off" then p = 1 end
            frame:SetImageFade(p*p*(3-2*p))
            if p == 1 then
                frame.imageSeen[id] = true
                frame:SetScript("OnUpdate", nil)
            end
        end)
    end
    function B:Fit()
        local w = math.max(1, detailPanel:GetWidth()-8)
        -- Let artwork continue beneath the compact header before fading out.
        local h = math.max(math.max(1, self:GetHeight())*0.92,
            w*0.6*0.92/(self.sourceAspect or 1))
        -- Scale with window width; crop from the top-right of the source.
        local aw = w*0.6*0.92
        local shownHeight = math.min(h, math.max(1, detailPanel:GetHeight()-8))
        self.fullImageHeight = shownHeight
        local fadeHeight = math.min(140,shownHeight*0.35)
        local solidHeight = shownHeight-fadeHeight
        self.art:SetSize(aw,solidHeight)
        -- Restore the source proportions while covering the artwork area.
        local ratio = aw/h/(self.sourceAspect or 1)
        if ratio >= 1 then
            self.uv = {0,1,0,(1/ratio)*shownHeight/h}
        else
            self.uv = {1-ratio,1,0,shownHeight/h}
        end
        local u = self.uv
        local span = u[4]-u[3]
        self.art:SetTexCoord(u[1],u[2],u[3],u[3]+span*solidHeight/shownHeight)
        for i,t in ipairs(self.fadeStrips) do
            local y1 = solidHeight+fadeHeight*(i-1)/#self.fadeStrips
            local y2 = solidHeight+fadeHeight*i/#self.fadeStrips
            t:ClearAllPoints()
            t:SetPoint("TOPRIGHT", self.art, "TOPRIGHT", 0,-y1)
            t:SetSize(aw,y2-y1)
            t:SetTexCoord(u[1],u[2],u[3]+span*y1/shownHeight,u[3]+span*y2/shownHeight)
            local p = (i-0.5)/#self.fadeStrips
            t.fadeWeight = 1-p*p*(3-2*p)
            t:SetShown(self.hasArt and self:IsShown())
        end
        self:SetImageFade(self.imageFade or 1)
        self.left:SetSize(aw*0.78,shownHeight)
        self.top:SetSize(w,math.min(shownHeight,h*0.28))
        -- Sample the panel's own gradient at the artwork's actual vertical position.
        -- The remaining top treatment follows the panel's actual shade.
        local panelHeight = math.max(1, detailPanel:GetHeight()-8)
        local function PanelColor(y)
            local p = math.min(1, math.max(0,y/panelHeight))
            local c = {}
            for i=1,3 do c[i] = STYLE.panel.top[i] + (STYLE.panel.bottom[i]-STYLE.panel.top[i])*p end
            return c
        end
        local topColor = PanelColor(0)
        ApplyHGradient(self.left, topColor, topColor, 0,0)
        ApplyVGradient(self.top, topColor, PanelColor(h*0.28), 0.65,0)
        self.bottom:Hide()
    end
    B:SetScript("OnSizeChanged", function(self) self:Fit() end)
    B:SetScript("OnHide", function(self)
        self:StopImageFade()
        for _,t in ipairs({self.background,self.border,self.art,self.left,self.top,self.bottom}) do t:Hide() end
        for _,t in ipairs(self.fadeStrips) do t:Hide() end
    end)
    B:SetScript("OnShow", function(self)
        self.background:Show()
        self.border:Show()
        for _,t in ipairs({self.art,self.left,self.top}) do t:SetShown(self.hasArt and true or false) end
        self.bottom:Hide()
        self:Fit()
        self:RevealImages()
    end)
    B:Hide()
    FGT.goalBanner = B
    B.title, B.tag, B.icon, B.description, B.panel = detailTitle, detailTag, detailIcon, detailNote, detailPanel
    B.difficulty, B.duration = detailDiffChip, detailTimeChip
    function FGT.LayoutGoalBanner(goal)
        B.goal = goal
        local rowHeight = math.max(DETAIL_ICON, (detailTag:GetStringHeight() or 12) + 8 + (detailTitle:GetStringHeight() or 24) + 8 + 22)
        for _,chip in ipairs({detailDiffChip,detailTimeChip}) do
            chip:SetSize(math.ceil(chip.text:GetStringWidth())+24,22)
            chip:SetBackdrop({bgFile=SOLID,edgeFile=ETCH_EDGE,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
            chip:SetBackdropColor(0.02,0.02,0.015,0.75)
            chip:SetBackdropBorderColor(0.34,0.30,0.20,1)
        end
        -- Completion/Forever/lockout badges wrap instead of entering the description.
        local firstX = 22 + DETAIL_ICON + 12
        local x, y = firstX, 24+rowHeight-22
        for _,chip in ipairs({detailDiffChip,detailTimeChip,FGT.detailNewChip,FGT.detailDoneChip,FGT.detailLockChip}) do
            if chip:IsShown() then
                local width = chip:GetWidth()
                if x > firstX and x+width > FGT.detailBody:GetWidth()-22 then x,y = firstX,y+30 end
                chip:ClearAllPoints(); chip:SetPoint("TOPLEFT", FGT.detailBody, "TOPLEFT", x,-y)
                x = x+width+10
            end
        end
        detailNote:ClearAllPoints()
        local personal = FGT.personalNote
        personal:ClearAllPoints()
        personal:SetPoint("TOPLEFT", FGT.detailBody, "TOPLEFT", 22,-(y+22+24))
        personal:SetPoint("RIGHT", FGT.detailBody, "RIGHT", -22,0)
        if FGT.GoalNote(goal) ~= "" then
            detailNote:SetPoint("TOPLEFT", personal, "BOTTOMLEFT", 0,-14)
        else
            detailNote:SetPoint("TOPLEFT", FGT.detailBody, "TOPLEFT", 22,-(y+22+8))
        end
        detailNote:SetPoint("RIGHT", FGT.detailBody, "RIGHT", -22,0)
        FGT.detailHeaderHeight = y + 22 + (FGT.GoalNote(goal) ~= "" and 24 or 8)
            + (FGT.GoalNote(goal) ~= "" and personal:GetHeight() + 14 or 0)
            + math.max(12, detailNote:GetStringHeight() or 12)
            + (FGT.foreverNotice:IsShown() and FGT.foreverNotice:GetHeight() + 12 or 0)
            + 32 + 8 + 10 + 2 + 10 + 14 + 8
        B:SetHeight(FGT.detailHeaderHeight + 68)
        if FGT.UpdateDetailViewport then FGT.UpdateDetailViewport() end
        local art, aspect, preprocessed = B:ResolveArt(goal.id)
        B.hasArt = art ~= nil
        B.sourceAspect = aspect
        if art then
            B.art:SetTexture("Interface\\AddOns\\"..ADDON.."\\Media\\"..art)
            B.art:SetDesaturated(not preprocessed)
            for _,t in ipairs(B.fadeStrips) do
                t:SetTexture("Interface\\AddOns\\"..ADDON.."\\Media\\"..art)
                t:SetDesaturated(not preprocessed)
            end
            B:SetImageFade(B.imageFade or 1)
        end
        for _,t in ipairs({B.art,B.left,B.top}) do t:SetShown(B.hasArt) end
        B.bottom:Hide()
        -- Textures live on detailPanel, but their fade driver must be shown too.
        -- Existing saved goals can bypass HideEmptyTracker's first-run Show path.
        B:Show()
        B:Fit()
        B:RevealImages()
    end
end

-- Shows or hides the Forever chip and notice for a goal, and hangs the
-- progress bar under whichever is last.
function FGT.LayoutForeverInfo(goal)
    local descriptionEnd = FGT.LayoutPersonalNote(goal)
    local chip = FGT.detailNewChip
    chip:ClearAllPoints()
    chip:SetPoint("LEFT", detailTimeChip:IsShown() and detailTimeChip or detailDiffChip, "RIGHT", 6, 0)
    local word = FGT.ForeverWord(goal)
    if word then chip:SetLabel(FGT.ForeverDot(13) .. word .. " IN FOREVER", C.FOREVER_LIGHT) end
    chip:SetShown(word ~= nil)
    detailBar:SetBlue(word ~= nil)

    local dc = FGT.detailDoneChip
    if FGT.CheckGoalCompletions then FGT.CheckGoalCompletions() end -- date a goal finished just now
    local d, t = GoalProgress(goal)
    local on = t > 0 and d == t and FGT.CompletedOn(goal)
    dc:ClearAllPoints()
    dc:SetPoint("LEFT", word and chip or (detailTimeChip:IsShown() and detailTimeChip or detailDiffChip), "RIGHT", 6, 0)
    if on then dc:SetLabel("COMPLETED " .. string.upper(on), C.DONE) end
    dc:SetShown(on and true or false)
    FGT.LayoutLockout(goal, on and dc or (word and chip) or (detailTimeChip:IsShown() and detailTimeChip or detailDiffChip))

    local n = FGT.foreverNotice
    n:ClearAllPoints()
    n:SetPoint("TOPLEFT", descriptionEnd, "BOTTOMLEFT", 0, -12)
    n:SetPoint("RIGHT", FGT.detailBody, "RIGHT", -22, 0)
    -- New goals only get the notice when there's something to explain.
    local note = (not word or goal.foreverNote) and FGT.ForeverNote(goal)
    detailBar:ClearAllPoints()
    detailBar:SetPoint("RIGHT", -22, 0)
    if note then
        local w = math.max(120, FGT.detailBody:GetWidth() - 44)
        n.text:SetWidth(w - 20)
        n.text:SetText(note)
        n:SetHeight(math.max(30, math.ceil(n.text:GetStringHeight()) + 18))
        n:Show()
        detailBar:SetPoint("TOPLEFT", n, "BOTTOMLEFT", 0, -32)
    else
        n:Hide()
        detailBar:SetPoint("TOPLEFT", descriptionEnd, "BOTTOMLEFT", 0, -32)
    end
    FGT.LayoutGoalBanner(goal)
end

local divider = CreateFrame("Frame", nil, FGT.detailBody) -- invisible layout anchor above the steps
divider:SetHeight(2)
FGT.stepsDivider = divider -- (the tips line ends where this one does)
divider:SetPoint("TOPLEFT", detailBar, "BOTTOMLEFT", 0, -10)
divider:SetPoint("RIGHT", -16, 0)

local stepsHeader = NewTitleString(FGT.detailBody, 12)
stepsHeader:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -10)
stepsHeader:SetText("Step by Step")

-- A quiet guide filter. Only the layout changes; saved ticks and progress
-- always include completed steps, even when they are hidden.
do
    local b = CreateFrame("Button", nil, FGT.detailBody)
    b:SetPoint("LEFT", stepsHeader, "RIGHT", 14, 0)
    b.text = NewFontString(b, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
    b.text:SetPoint("LEFT")
    b:SetScript("OnEnter", function(self) self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
    b:SetScript("OnLeave", function(self) self.text:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3]) end)
    b:SetScript("OnClick", function()
        FGT.SetSetting("hideCompletedSteps", not FGT.Setting("hideCompletedSteps"))
        if selectedId then SelectGoal(selectedId, true) end
    end)
    FGT.completedStepsBtn = b
end

function FGT.ShowStepSection(goal, si, section)
    if not PartSelected(goal, si) then return false end
    local done, total = SectionProgress(goal, si, section)
    return not FGT.HideGuideEntry("section:" .. si, total > 0 and done == total)
end

-- "Expand all" / "Collapse all" on the right of the heading, for goals
-- with two or more groups chosen (mount races, set classes). Groups only;
-- Tier 3 pieces keep their materials folded.
do
    local b = CreateFrame("Button", nil, FGT.detailBody)
    b:SetPoint("TOPRIGHT", divider, "BOTTOMRIGHT", -8, -10)
    b.text = NewFontString(b, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
    b.text:SetPoint("RIGHT")
    b:SetScript("OnEnter", function(self) self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
    b:SetScript("OnLeave", function(self) self.text:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3]) end)
    b:Hide()
    FGT.expandAllBtn = b
end

-- Shows the button for a goal and labels it: "Expand all" while any
-- chosen group is closed, otherwise "Collapse all".
function FGT.UpdateExpandAll(goal)
    local b = FGT.expandAllBtn
    if not goal.sections then b:Hide() return end
    local visible = 0
    local anyClosed = false
    for si, section in ipairs(goal.sections) do
        if FGT.ShowStepSection(goal, si, section) then
            visible = visible + 1
            if not FGT.SectionIsOpen(goal, si) then anyClosed = true end
        end
    end
    if visible < 2 then b:Hide() return end
    b.text:SetText(anyClosed and "Expand all" or "Collapse all")
    b:SetSize(math.ceil(b.text:GetStringWidth()) + 4, 16)
    b:SetScript("OnClick", function()
        for si, section in ipairs(goal.sections) do
            if FGT.ShowStepSection(goal, si, section) then FGT.sectionOpen[goal.id .. "_" .. si] = anyClosed end
        end
        SelectGoal(goal.id, true) -- (RefreshSteps is declared further down)
    end)
    b:Show()
end

local stepsScrollObj = CreateScrollArea(FGT.detailBody)
stepsScrollObj.scroll:SetPoint("TOPLEFT", stepsHeader, "BOTTOMLEFT", 0, -8)
-- down to the panel's inner edge (its border is 3px), so the bottom
-- gradient meets the edge with no gap (no reset button below any more)
stepsScrollObj.scroll:SetPoint("BOTTOMRIGHT", FGT.detailBody, "BOTTOMRIGHT", -24, 3)
stepsScrollObj:Finalize()
local stepsContainer = stepsScrollObj.content
local RefreshSteps -- shared by guide motion and the row click handlers below
-- Keep newly completed entries for their check animation, then fade them
-- away before moving the surviving entries to their new positions.
function FGT.CancelGuideMotion()
    local W = FGT.welcome
    if W and W.Tween then W.Tween("guideExit", nil); W.Tween("guideSlide", nil) end
    local layout = FGT.guideLayout
    if layout then
        for _, node in ipairs(layout.nodes) do
            node.frame:SetAlpha(1)
            node.frame:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", node.x, -node.y)
        end
        if layout.height then stepsContainer:SetHeight(layout.height); stepsScrollObj:Update() end
    end
end

function FGT.FinishGuideHeight(height)
    height = math.max(1, height)
    FGT.guideLayout.height = height
    -- Keep the scroll bounds large enough for the old row positions until
    -- the slide ends, especially when the player is near the bottom.
    stepsContainer:SetHeight(math.max(height, FGT.guideSlideHeight or 0))
    stepsScrollObj:Update()
end

function FGT.BeginGuideLayout(goal)
    FGT.CancelGuideMotion()
    local old = FGT.guideLayout
    local same = old and old.goal == goal.id
    FGT.guideLayout = {goal = goal.id, nodes = {}, byKey = {},
        previous = same and old.byKey or {},
        pending = same and old.pending or {}}
    if not FGT.Setting("hideCompletedSteps") or FGT.Setting("celebrations") == "off" or FGT.quietCelebrate then
        FGT.guideLayout.previous, FGT.guideLayout.pending = {}, {}
    end
end

function FGT.HideGuideEntry(key, done)
    if not FGT.Setting("hideCompletedSteps") or not done then
        if FGT.guideLayout then FGT.guideLayout.pending[key] = nil end
        return false
    end
    local layout = FGT.guideLayout
    local prior = layout and layout.previous[key]
    if prior and prior.done == false then layout.pending[key] = true end
    return not (layout and layout.pending[key])
end

function FGT.PlaceGuideEntry(frame, key, y, done, x)
    local layout = FGT.guideLayout
    local identity = layout.goal .. "|" .. key
    if frame.guideIdentity ~= identity and frame.fxT then FGT.EndCelebration(frame) end
    frame.guideIdentity = identity
    local node = {frame = frame, key = key, y = y, x = x or 0, done = done}
    layout.nodes[#layout.nodes + 1], layout.byKey[key] = node, node
    frame:SetAlpha(1)
end

function FGT.EndGuideLayout(goal)
    local layout, W = FGT.guideLayout, FGT.welcome
    if not next(layout.pending) or not W or not W.Tween then return end
    W.Tween("guideExit", 0.28, function(p)
        for _, node in ipairs(layout.nodes) do
            if layout.pending[node.key] then node.frame:SetAlpha(1 - W.EaseOut(p)) end
        end
    end, function()
        if FGT.guideLayout ~= layout or selectedId ~= goal.id then return end
        layout.pending = {}
        FGT.guideSlideHeight = layout.height
        RefreshSteps(goal)
        FGT.guideSlideHeight = nil
        local fresh = FGT.guideLayout
        W.Tween("guideSlide", 0.26, function(p)
            local eased = W.EaseOut(p)
            for _, node in ipairs(fresh.nodes) do
                local before = layout.byKey[node.key]
                if before then
                    local y = before.y + (node.y - before.y) * eased
                    node.frame:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", node.x, -y)
                end
            end
        end, function()
            stepsContainer:SetHeight(fresh.height)
            stepsScrollObj:Update()
        end)
    end, 0.55)
end

function FGT.LayoutStepControls()
    local b = FGT.completedStepsBtn
    local expandWidth = FGT.expandAllBtn:IsShown() and (FGT.expandAllBtn:GetWidth() + 20) or 0
    local narrow = stepsHeader:GetStringWidth() + 14 + b:GetWidth() + expandWidth > FGT.detailBody:GetWidth() - 44
    b:ClearAllPoints()
    if narrow then
        b:SetPoint("TOPLEFT", stepsHeader, "BOTTOMLEFT", 0, -6)
    else
        b:SetPoint("LEFT", stepsHeader, "RIGHT", 14, 0)
    end
    stepsScrollObj.scroll:ClearAllPoints()
    stepsScrollObj.scroll:SetPoint("TOPLEFT", narrow and b or stepsHeader, "BOTTOMLEFT", 0, -8)
    stepsScrollObj.scroll:SetPoint("BOTTOMRIGHT", FGT.detailBody, "BOTTOMRIGHT", -24, 3)
end
-- Tips are drawn straight on the list, so it carries their goal links.
stepsContainer:EnableMouse(true)
FGT.EnableGoalLinks(stepsContainer)
stepsContainer:SetHeight(1)
FGT.detailStepsScroll = stepsScrollObj
function FGT.UpdateDetailViewport()
    local view = FGT.detailViewport
    if view.updating then return end
    view.updating = true
    local height = math.max(1, view.scroll:GetHeight())
    local header = FGT.detailHeaderHeight or 0
    view.short = height < header + 100
    view.content:SetHeight(view.short and (header + math.max(100, stepsContainer:GetHeight()) + 8) or height)
    if not view.short then view.scroll:SetVerticalScroll(0) end
    if view.short then stepsScrollObj.scroll:SetVerticalScroll(0) end
    stepsScrollObj:Update()
    view:Update()
    view.updating = nil
end
FGT.detailViewport.scroll:HookScript("OnSizeChanged", FGT.UpdateDetailViewport)
stepsContainer:HookScript("OnSizeChanged", FGT.UpdateDetailViewport)
do
    local original = stepsScrollObj.scroll:GetScript("OnMouseWheel")
    stepsScrollObj.scroll:SetScript("OnMouseWheel", function(self, delta)
        if FGT.detailViewport.short then
            local outer = FGT.detailViewport.scroll
            outer:GetScript("OnMouseWheel")(outer, delta)
        else
            original(self, delta)
        end
    end)
end


-- "Reset this goal": a quiet undo-arrow icon at the top right, next to the
-- Edit goal pencil (Karl: no big red button at the bottom, so the steps
-- run to the panel's edge). Grey at rest, soft red on hover; gold while
-- a reset can be undone. After a reset it offers "Undo reset" for 10
-- seconds, holding a copy of the goal's ticks (and its finished state and
-- date): FGT.resetUndo = { id, progress, done, date } while that's possible.
local resetBtn = CreateFrame("Button", nil, FGT.detailBody)
resetBtn:SetSize(22, 22)
resetBtn:SetPoint("TOPRIGHT", FGT.detailBody, "TOPRIGHT", -12, -12)
resetBtn.icon = resetBtn:CreateTexture(nil, "ARTWORK")
resetBtn.icon:SetTexture(FGT.Icon("refresh-white"))
resetBtn.icon:SetTexCoord(1, 0, 0, 1) -- mirror the arrow horizontally
resetBtn.icon:SetSize(15, 15)
resetBtn.icon:SetPoint("CENTER")
FGT.resetBtn = resetBtn
function FGT.StyleResetButton()
    local undo = FGT.resetUndo
    local hover = resetBtn:IsMouseOver()
    resetBtn.icon:SetTexture(FGT.Icon(undo and "refresh" or "refresh-white"))
    local c = undo and { 1, 1, 1 } or (hover and { 1, 0.55, 0.5 }) or C.SUBTEXT
    resetBtn.icon:SetVertexColor(c[1], c[2], c[3], (undo or hover) and 1 or 0.8)
    if hover then
        GameTooltip:SetOwner(resetBtn, "ANCHOR_LEFT")
        if undo then
            GameTooltip:AddLine("Undo reset", C.TITLE[1], C.TITLE[2], C.TITLE[3])
            GameTooltip:AddLine("Puts back the ticks you just cleared.", C.INK2[1], C.INK2[2], C.INK2[3], true)
            GameTooltip:AddLine(string.format("%d seconds left", math.max(0, math.ceil(undo.expires - GetTime()))), C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
        else
            GameTooltip:AddLine("Reset this goal", 1, 0.6, 0.55)
            GameTooltip:AddLine("Clears its ticks. You can undo it for 10 seconds.", C.INK2[1], C.INK2[2], C.INK2[3], true)
        end
        GameTooltip:Show()
    elseif GameTooltip:IsOwned(resetBtn) then
        GameTooltip:Hide()
    end
end
resetBtn:SetScript("OnEnter", FGT.StyleResetButton)
resetBtn:SetScript("OnLeave", FGT.StyleResetButton)
resetBtn:SetScript("OnUpdate", function(self, elapsed)
    if self.spin then
        self.spin = self.spin + elapsed
        local t = math.min(1, self.spin / 0.65)
        -- One clockwise turn with a soft start and stop.
        self.icon:SetRotation(2 * math.pi * (t * t * (3 - 2 * t)))
        if t == 1 then self.spin = nil; self.icon:SetRotation(0) end
    end
    local undo = FGT.resetUndo
    local seconds = undo and math.max(0, math.ceil(undo.expires - GetTime()))
    if undo and seconds == 0 then
        FGT.resetUndo = nil
        FGT.StyleResetButton()
    elseif seconds ~= self.undoSeconds then
        if self:IsMouseOver() and GameTooltip:IsOwned(self) then FGT.StyleResetButton() end
    end
    self.undoSeconds = seconds
end)
resetBtn:SetScript("OnHide", function(self)
    self.spin = nil
    self.icon:SetRotation(0)
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end)
resetBtn:SetScript("OnClick", function()
    if not selectedId then return end
    local DB = ForeverGoalTrackerDB
    local undo = FGT.resetUndo
    if undo and GetTime() >= undo.expires then FGT.resetUndo = nil; undo = nil end
    if FGT.Setting("celebrations") ~= "off" then resetBtn.spin = 0 end
    if undo and undo.id == selectedId then
        -- Restore the saved state with the usual bar glide and check pops.
        DB.progress[undo.id] = undo.progress
        if DB.goalsDone then DB.goalsDone[undo.id] = undo.done end
        if DB.goalDates then DB.goalDates[undo.id] = undo.date end
        FGT.resetUndo = nil
        FGT.restoringReset = selectedId
        SelectGoal(selectedId)
        FGT.restoringReset = nil
    else
        local copy = {}
        for k, v in pairs(DB.progress[selectedId] or {}) do copy[k] = v end
        undo = { id = selectedId, progress = copy,
            done = DB.goalsDone and DB.goalsDone[selectedId],
            date = DB.goalDates and DB.goalDates[selectedId], expires = GetTime() + 10 }
        FGT.resetUndo = undo
        DB.progress[selectedId] = {}
        SelectGoal(selectedId)
        C_Timer.After(10, function()
            if FGT.resetUndo == undo then
                FGT.resetUndo = nil
                FGT.StyleResetButton()
            end
        end)
    end
    FGT.StyleResetButton()
end)

-- ============================================================
-- Step row pool
-- ============================================================
local stepRowPool = {}

local function GetStepRow(index)
    local row = stepRowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, stepsContainer)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp") -- right-click: Wowhead link
    row:SetPoint("LEFT", stepsContainer, "LEFT", 0, 0)
    row:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
    FGT.EnableGoalLinks(row)

    row.box = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.box:SetSize(16, 16)
    row.box:SetPoint("TOPLEFT", 2, -2)
    -- Checkbox styled like a talent slot: black well with a gray ring,
    -- ring turns white on hover and gold once checked ("maxed").
    Skin(row.box, { 0, 0, 0, 1 }, C.BOX_RING)

    -- Hover: a soft warm wash that fades in on the left and out to the
    -- right, a little taller than the row, so text never meets a hard edge
    -- (Karl). Three pieces behind the text; row.hover shows and hides them.
    do
        -- (a soft vignette texture was tried and dropped: it looked cheap)
        local A, W, PAD = 0.025, { 1, 0.95, 0.85 }, 5
        local l, m, r = Flat(row, 1, 1, 1, 1), Flat(row, 1, 1, 1, 1), Flat(row, 1, 1, 1, 1)
        l:SetWidth(40)
        r:SetWidth(160)
        ApplyHGradient(l, W, W, 0, A)
        m:SetVertexColor(W[1], W[2], W[3], A)
        ApplyHGradient(r, W, W, A, 0)
        local parts = { l, m, r }
        row.hover = {}
        -- sized to the text (and the progress bar under it, if any), not
        -- the row, with PAD px of room above and below; it starts fading in
        -- at the checkbox's right edge, so the box itself stays clear (Karl)
        function row.hover:Show()
            local rowTop, rowLeft = row:GetTop(), row:GetLeft()
            local tTop, tBottom = row.text:GetTop(), row.text:GetBottom()
            local y, h, x = 3, (row:GetHeight() or 20) + 6, 20
            if rowTop and tTop and tBottom then
                if row.miniBar:IsShown() and row.miniBar:GetBottom() then
                    tBottom = math.min(tBottom, row.miniBar:GetBottom())
                end
                y, h = (tTop - rowTop) + PAD, (tTop - tBottom) + 2 * PAD
            end
            if rowLeft and row.box:GetRight() then x = row.box:GetRight() - rowLeft + 2 end
            l:ClearAllPoints(); r:ClearAllPoints(); m:ClearAllPoints()
            l:SetPoint("TOPLEFT", row, "TOPLEFT", x, y)
            r:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, y)
            m:SetPoint("TOPLEFT", l, "TOPRIGHT")
            m:SetPoint("TOPRIGHT", r, "TOPLEFT")
            for _, t in ipairs(parts) do t:SetHeight(h); t:Show() end
        end
        function row.hover:Hide() for _, t in ipairs(parts) do t:Hide() end end
        row.hover:Hide()
    end
    row:SetScript("OnEnter", function(self)
        self.hover:Show()
        if self.depLocked then FGT.ShowStepLockTip(self); return end
        if not self.isDone and not self.autoEntry then
            self.box:SetBackdropBorderColor(1, 1, 1, 1)
        end
        if self.autoEntry then
            local _, list = BestOfClass(self.autoEntry.autoClass)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.autoEntry.text, C.TITLE[1], C.TITLE[2], C.TITLE[3])
            if #list == 0 then
                GameTooltip:AddLine("No character of this class seen yet. Log into one once and it's tracked from then on.",
                    C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
            else
                for _, c in ipairs(list) do
                    GameTooltip:AddDoubleLine(c.name .. (c.realm ~= "" and (" - " .. c.realm) or ""),
                        string.format("%.1f", PreciseLevel(c)), 0.9, 0.9, 0.9, 1, 0.82, 0)
                end
                GameTooltip:AddLine("Updates automatically as you level.", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
            end
            GameTooltip:Show()
        elseif self.ruleEntry then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Tracked automatically", C.TITLE[1], C.TITLE[2], C.TITLE[3])
            GameTooltip:AddLine("Checks itself off when " .. DescribeRule(self.ruleEntry) .. ".",
                0.9, 0.9, 0.9, true)
            local now = RuleReadout(self.ruleEntry)
            if now then
                GameTooltip:AddDoubleLine("Right now", now, C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], 1, 0.82, 0)
            end
            GameTooltip:AddLine("You can still click to tick it by hand.", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
            if self.itemId then
                GameTooltip:AddLine("Hover the item's name or icon for its tooltip. Right-click for its Wowhead link.",
                    C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
            elseif self.questId then
                GameTooltip:AddLine("Right-click for the quest's Wowhead link.", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
            end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.hover:Hide()
        if not self.isDone then
            self.box:SetBackdropBorderColor(C.BOX_RING[1], C.BOX_RING[2], C.BOX_RING[3], 1)
        end
    end)

    -- The game's own gold checkmark, so a checked step looks exactly
    -- like a ticked Blizzard checkbox.
    row.check = row.box:CreateTexture(nil, "OVERLAY")
    row.check:SetTexture(FGT.Icon("check"))
    row.check:SetSize(15, 15)
    row.check:SetPoint("CENTER", 0, 0)
    row.check:Hide()

    row.num = NewFontString(row, 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    -- numbers right-aligned in a fixed column, so "10." lines up with "9."
    -- (rows without a number keep their old, tighter spacing), and set a
    -- touch lower so the first line of text centers on the checkbox (Karl)
    row.num:SetPoint("TOPLEFT", row.box, "TOPRIGHT", 8, -2)
    row.num:SetJustifyH("RIGHT")
    hooksecurefunc(row.num, "SetText", function(self, t)
        self:SetWidth((t and t ~= "") and 18 or 0.1)
    end)

    -- Optional per-step icon (used by "Level Every Class to 60").
    row.icon = NewIcon(row, 20)
    row.icon:SetPoint("TOPLEFT", row.box, "TOPRIGHT", 8, 2)
    row.icon:Hide()
    -- hovering the icon shows the item's tooltip (Karl); clicks pass on to
    -- the row, so the icon still ticks the step like before
    row.icon:EnableMouse(true)
    row.icon:SetScript("OnEnter", function()
        local enter = row:GetScript("OnEnter")
        if enter then enter(row) end -- the row's hover highlight
        if row.itemId then FGT.ShowItemTip(row.icon, row.itemId, row.ruleEntry, row.itemNames and row.itemNames[1]) end
    end)
    row.icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
        local leave = row:GetScript("OnLeave")
        if leave and not row:IsMouseOver() then leave(row) end
    end)
    row.icon:SetScript("OnMouseUp", function(_, button)
        if row:IsMouseOver() then row:Click(button) end
    end)

    row.text = NewFontString(row, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    FGT.Shimmer(row.text) -- goal links in the step shine
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(true)

    -- Level-tracked rows: a level readout on the right and a thin bar
    -- under the text that fills as the character levels.
    row.levelText = NewFontString(row, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
    row.levelText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
    row.levelText:SetJustifyH("RIGHT")
    row.levelText:Hide()
    row.miniBar = NewBar(row, 5)
    row.miniBar.label:Hide()
    row.miniBar:Hide()
    row.miniBar.instant = true -- pooled rows get reused across goals; no gliding

    -- Set pieces with a materials list: a +/- fold toggle in the
    -- checkbox's spot and a "1 / 3" count on the right. Materials get a
    -- faint guide line on their left so they read as part of the piece.
    row.toggle = NewFontString(row, 12, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
    row.toggle:SetPoint("TOPLEFT", row, "TOPLEFT", 20, -3)
    row.toggle:SetWidth(12)
    row.toggle:SetJustifyH("CENTER")
    row.toggle:Hide()
    row.count = NewFontString(row, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    row.count:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -4)
    row.count:SetJustifyH("RIGHT")
    row.count:Hide()
    -- green check that replaces the count once every material is done
    row.doneCheck = row:CreateTexture(nil, "OVERLAY")
    row.doneCheck:SetTexture(FGT.Icon("check-white"))
    row.doneCheck:SetSize(13, 13)
    row.doneCheck:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5, 0)
    row.doneCheck:SetDesaturated(true)
    row.doneCheck:SetVertexColor(C.DONE[1], C.DONE[2], C.DONE[3])
    row.doneCheck:Hide()
    row.guide = Flat(row, C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 0.22)
    row.guide:SetWidth(1)
    row.guide:Hide()

    -- Places the text after the number, or after the icon when the step
    -- has one (the number is hidden then; the icon says it all).
    function row:SetStepIcon(spec)
        -- every render starts as a plain manual row
        self.autoEntry = nil
        self.ruleEntry = nil
        self.itemId, self.questId = nil, nil -- what the row links to (FGT.SetStepLinks)
        self.pieceKey = nil
        self.levelText:Hide()
        self.miniBar:Hide()
        self.toggle:Hide()
        self.count:Hide()
        self.doneCheck:Hide()
        self.guide:Hide()
        self.box:Show()
        self.icon:ClearAllPoints()
        self.icon:SetPoint("TOPLEFT", self.box, "TOPRIGHT", 8, 2)
        self.text:ClearAllPoints()
        if spec then
            self.icon:SetIcon(spec, FGT.stepRim or C.GOLD2)
            self.icon:Show()
            self.num:Hide()
            self.text:SetPoint("LEFT", self.icon, "RIGHT", 8, 0)
        else
            self.icon:Hide()
            self.num:Show()
            self.text:SetPoint("TOPLEFT", self.num, "TOPRIGHT", 4, 1)
        end
        self.text:SetPoint("RIGHT", self, "RIGHT", 0, 0)
    end
    row:SetStepIcon(nil)

    stepRowPool[index] = row
    return row
end

local function ToggleStep(goalId, index)
    if FGT.overLink then return end -- the click was on a goal link in the step
    if FGT.StepLocked(FGT.GoalById(goalId), index) then return end
    local nowDone = not IsStepDone(goalId, index)
    SetStepDone(goalId, index, nowDone)
    -- A shared step (riding, reaching 60 for the racial mounts) is the
    -- same in every part, so ticking it by hand ticks it everywhere.
    local goal = FGT.GoalById(goalId)
    local si, pi = tostring(index):match("^(%d+)_(%d+)_piece$")
    local piece = goal and goal.sections and si and goal.sections[tonumber(si)]
        and goal.sections[tonumber(si)].pieces[tonumber(pi)]
    if piece and piece.shared then
        for s2, sec in ipairs(goal.sections) do
            for p2, other in ipairs(sec.pieces) do
                if other.shared == piece.shared then SetStepDone(goalId, PieceKey(s2, p2), nowDone) end
            end
        end
    end
    FGT.justTicked = nowDone and (goalId .. "|" .. index) or nil
    SelectGoal(goalId, true)
end

-- Shared checked/unchecked visual state for any pooled checkbox row
-- (flat steps, Tier 3 pieces, and Tier 3 materials all use this).
local function StyleCheckRow(row, done)
    row.isDone = done and true or false
    if done then
        row.check:Show()
        -- a lighter fill, so the gold check stands out from its box (Karl)
        row.box:SetBackdropColor(C.BOX_DONE_BG[1], C.BOX_DONE_BG[2], C.BOX_DONE_BG[3], 0.45)
        row.box:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
        row.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        row.num:SetTextColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
        -- links keep their own color, so fade them too: halfway to the
        -- dimmed text, a hint of the item's quality left (Karl)
        local text = row.text:GetText()
        if type(text) == "string" and text:find("|H", 1, true) then
            -- the icons in front of links (quest "!", goal chain) grey too
            for _, pair in ipairs(FGT.LINK_ICONS or FGT.EMPTY) do
                local plain, dim = pair[1], pair[2]
                local s, e = text:find(plain, 1, true)
                while s do
                    text = text:sub(1, s - 1) .. dim .. text:sub(e + 1)
                    s, e = text:find(plain, s + #dim, true)
                end
            end
            row.text:SetText((text:gsub("|cff(%x%x)(%x%x)(%x%x)", function(r, g, b)
                local function mix(x, s) return math.floor((tonumber(x, 16) / 255 * 0.45 + s * 0.55) * 255 + 0.5) end
                return string.format("|cff%02x%02x%02x", mix(r, C.SUBTEXT[1]), mix(g, C.SUBTEXT[2]), mix(b, C.SUBTEXT[3]))
            end)))
        end
    else
        row.check:Hide()
        row.box:SetBackdropColor(0, 0, 0, 1)
        row.box:SetBackdropBorderColor(C.BOX_RING[1], C.BOX_RING[2], C.BOX_RING[3], 1)
        row.text:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
        row.num:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    end
    -- a finished step's item icon steps back: grey and faded
    if row.icon and row.icon.tex then
        row.icon.tex:SetDesaturated(done and true or false)
        row.icon:SetAlpha(done and 0.5 or 1)
        local c = done and { 0.42, 0.42, 0.42 } or row.icon.rim or C.GOLD2
        row.icon:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    end
end

-- Re-anchors a pooled row's checkbox at the given left indent, so the
-- same row pool can render top-level steps, Tier 3 pieces (indented),
-- and Tier 3 materials (indented further) without separate pools.
local function SetRowIndent(row, indent)
    row.box:ClearAllPoints()
    row.box:SetPoint("TOPLEFT", indent, -2)
end

-- ============================================================
-- Tier 3 collapsible class headers
-- ============================================================
local headerRowPool = {}
FGT.sectionOpen = {} -- "goalId_section" -> true (opened) / false (closed by you); nil = default
-- Default: a goal with just one chosen part (one mount, one class's set)
-- shows it open; with several, they start closed.
function FGT.SectionIsOpen(goal, si)
    local v = FGT.sectionOpen[goal.id .. "_" .. si]
    if v == nil then return FGT.SelectedPartCount(goal) == 1 end
    return v
end
FGT.pieceExpanded = {} -- "goalId_section_piece" -> true while its materials are shown

local function GetHeaderRow(index)
    local row = headerRowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, stepsContainer, "BackdropTemplate")
    row.twin = { [STYLE.rowSel] = STYLE.fOpen } -- softer blue when open (Forever goals)
    row:SetPoint("LEFT", stepsContainer, "LEFT", 0, 0)
    row:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
    row:SetHeight(30)
    Etch(row, STYLE.row, 10)

    row.arrow = NewFontString(row, 10, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
    row.arrow:SetPoint("LEFT", 6, 0)
    row.arrow:SetWidth(10)
    row.arrow:SetJustifyH("CENTER")

    -- class / mount icon for the section
    row.icon = NewIcon(row, 20)
    row.icon:SetPoint("LEFT", row.arrow, "RIGHT", 6, 0)

    row.name = NewFontString(row, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.name:SetShadowColor(0, 0, 0, 1)
    row.name:SetShadowOffset(1, -1)
    row.name:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.count = NewFontString(row, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    row.count:SetPoint("RIGHT", -8, 0)

    -- Finished sections: a faint green wash from the right, the gold
    -- celebration layers, and a green check in place of the count (the
    -- game's checkmark, recolored).
    FGT.AddCelebrationFX(row, 2, 26)
    row.doneCheck = row:CreateTexture(nil, "OVERLAY")
    row.doneCheck:SetTexture(FGT.Icon("check-white"))
    row.doneCheck:SetSize(14, 14)
    row.doneCheck:SetPoint("RIGHT", -5, 1)
    row.doneCheck:SetDesaturated(true)
    row.doneCheck:SetVertexColor(C.DONE[1], C.DONE[2], C.DONE[3])
    row.doneCheck:Hide()

    -- Expanded headers wear the "selected" gold look; collapsed ones are
    -- plain tiles that lighten on hover. Finished ones sit back quietly,
    -- like checked steps, until hovered or opened.
    function row:ApplyState(hovered)
        local quiet = self.complete and not hovered and not self.expanded
        self.icon:SetAlpha(quiet and 0.7 or 1)
        self.icon.tex:SetDesaturated(quiet)
        -- the gold rim goes grey too (same brightness, no color)
        local rim = self.foreverNew and C.FOREVER or C.GOLD2
        if quiet then
            local g = rim[1] * 0.3 + rim[2] * 0.59 + rim[3] * 0.11
            self.icon:SetBackdropBorderColor(g, g, g, 1)
        else
            self.icon:SetBackdropBorderColor(rim[1], rim[2], rim[3], 1)
        end
        self.arrow:SetAlpha(quiet and 0.6 or 1)
        if self.expanded then
            self:SetEtch(STYLE.rowSel)
            self.name:SetTextColor(1, 1, 1)
        else
            self:SetEtch(hovered and STYLE.rowHover or STYLE.row)
            if hovered then
                self.name:SetTextColor(1, 1, 1)
            elseif quiet then
                self.name:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
            else
                self.name:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3])
            end
        end
    end
    row:SetScript("OnEnter", function(self) self:ApplyState(true) end)
    row:SetScript("OnLeave", function(self) self:ApplyState(false) end)

    headerRowPool[index] = row
    return row
end

-- RefreshSteps is forward-declared above the guide animation callbacks.

-- Renders a Tier 3 goal: one collapsible header per class, and (when
-- expanded) its 8 pieces, each with its own indented materials checklist.
-- Only jump back to the top when a different goal is opened; ticking a
-- step or expanding a section keeps your place in the list.
local lastRenderedGoal = nil
local function ResetScrollIfNewGoal(goal)
    if goal.id ~= lastRenderedGoal then
        stepsScrollObj.scroll:SetVerticalScroll(0)
        lastRenderedGoal = goal.id
    end
end

-- Tips: advice with no checkbox (goal.tips), listed under the steps.
-- Lives on FGT to stay clear of the main chunk's local limit.
-- Tips fold open and closed under a "+ Tips (3)" header; closed by
-- default, remembered per goal until /reload.
FGT.tipsOpen = {}
function FGT.LayoutTips(goal, yOffset, width)
    local T = FGT.tipsUI
    if not T then
        T = { rows = {} }
        T.line = FGT.NewEmbossLine(stepsContainer) -- above the tips
        T.btn = CreateFrame("Button", nil, stepsContainer)
        T.arrow = NewFontString(T.btn, 12, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
        T.arrow:SetPoint("LEFT", T.btn, "LEFT", 0, 0)
        T.header = NewTitleString(T.btn, 12)
        T.header:SetPoint("LEFT", T.btn, "LEFT", 14, 0)
        T.count = NewFontString(T.btn, 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        T.count:SetPoint("LEFT", T.header, "RIGHT", 6, 0)
        T.btn:SetScript("OnEnter", function() T.header:SetTextColor(1, 1, 1) end)
        T.btn:SetScript("OnLeave", function() T.header:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
        T.btn:SetScript("OnClick", function()
            local id = T.goalId
            FGT.tipsOpen[id] = not FGT.tipsOpen[id] or nil
            SelectGoal(id, true)
        end)
        FGT.tipsUI = T
    end
    local tips = goal.tips or {}
    local open = FGT.tipsOpen[goal.id]
    T.goalId = goal.id
    for i = (open and #tips or 0) + 1, #T.rows do
        T.rows[i]:Hide()
        T.rows[i].dot:Hide()
    end
    if #tips == 0 then
        T.line:Hide()
        T.btn:Hide()
        return yOffset
    end

    yOffset = yOffset + 8
    T.line:ClearAllPoints()
    T.line:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
    FGT.PlaceGuideEntry(T.line, "tips:line", yOffset)
    -- same right end as the divider above the steps, so both fade alike
    T.line:SetPoint("RIGHT", FGT.stepsDivider, "RIGHT", 0, 0)
    T.line:Show()
    yOffset = yOffset + 9
    T.header:SetText("Tips")
    FGT.SetPlusMinus(T.arrow, open)
    T.count:SetText(open and "" or ("(" .. #tips .. ")"))
    local hh = (T.header:GetStringHeight() or 12) + 6
    T.btn:ClearAllPoints()
    T.btn:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
    FGT.PlaceGuideEntry(T.btn, "tips:button", yOffset)
    T.btn:SetSize(math.ceil(T.header:GetStringWidth() + T.count:GetStringWidth()) + 40, hh)
    T.btn:Show()
    yOffset = yOffset + hh + (open and 8 or 4)
    if not open then return yOffset end

    for i, tip in ipairs(tips) do
        local row = T.rows[i]
        if not row then
            row = NewFontString(stepsContainer, 12, "", C.INK2[1], C.INK2[2], C.INK2[3])
            FGT.Shimmer(row) -- goal links in the tip shine
            row:SetWordWrap(true)
            row:SetShadowColor(0, 0, 0, 1)
            row:SetShadowOffset(1, -1)
            -- small gold diamond as the bullet
            row.dot = Flat(stepsContainer, C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 0.9)
            row.dot:SetSize(4, 4)
            row.dot:SetRotation(math.rad(45))
            T.rows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 14, -yOffset)
        FGT.PlaceGuideEntry(row, "tips:" .. i, yOffset, nil, 14)
        row:SetWidth(math.max(50, width - 18))
        row:SetText(FGT.LinkText(tip))
        row:Show()
        row.dot:ClearAllPoints()
        row.dot:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 3, -yOffset - 5)
        FGT.PlaceGuideEntry(row.dot, "tips:dot:" .. i, yOffset + 5, nil, 3)
        row.dot:Show()
        yOffset = yOffset + (row:GetStringHeight() or 14) + 8
    end
    return yOffset
end

local function RefreshTierSections(goal)
    ResetScrollIfNewGoal(goal)
    local width = stepsContainer:GetWidth()
    local yOffset = 0
    local rowIndex = 0
    local headerIndex = 0

    for si, section in ipairs(goal.sections) do
        if FGT.ShowStepSection(goal, si, section) then
        headerIndex = headerIndex + 1
        local header = GetHeaderRow(headerIndex)
        header:SetParent(stepsContainer)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
        header:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)

        local openKey = goal.id .. "_" .. si
        local expanded = FGT.SectionIsOpen(goal, si)
        FGT.SetPlusMinus(header.arrow, expanded)
        -- a part that's new in Forever (the Skyborne mount): blue look + NEW
        local partNew = FGT.ApplyPartLook(header, section, goal)
        header.name:SetText(partNew and (section.name .. "   " .. FGT.NewTag(partNew)) or section.name)
        header.icon:SetIcon(section.icon or goal.icon, header.foreverNew and C.FOREVER or C.GOLD2)
        header.expanded = expanded and true or false

        local sd, st = SectionProgress(goal, si, section)
        header.complete = st > 0 and sd == st
        FGT.PlaceGuideEntry(header, "section:" .. si, yOffset, header.complete)
        header.count:SetText(sd .. " / " .. st)
        header.count:SetShown(not header.complete)
        header.doneCheck:SetShown(header.complete)
        header.doneGlow:SetShown(header.complete)
        header:ApplyState(header:IsMouseOver())
        -- An open group that finishes just now folds itself closed once
        -- its celebration has played, so its quiet finished look shows.
        local justDone = header.complete and FGT.doneSeen[openKey] == false and not FGT.quietCelebrate
        FGT.CheckCelebration(header, openKey, header.complete, FGT.CelebrateRow)
        if justDone and expanded and not FGT.Setting("hideCompletedSteps") then
            C_Timer.After(1.4, function()
                if FGT.SectionIsOpen(goal, si) and selectedId == goal.id then
                    FGT.sectionOpen[openKey] = false
                    RefreshSteps(goal)
                end
            end)
        end

        header:SetScript("OnClick", function()
            FGT.sectionOpen[openKey] = not FGT.SectionIsOpen(goal, si)
            RefreshSteps(goal)
        end)
        header:Show()
        yOffset = yOffset + header:GetHeight() + 4

        if expanded then
            for pi, piece in ipairs(section.pieces) do
                local md, mt = FGT.PieceProgress(goal.id, si, pi, piece)
                if not FGT.PieceSkipped(piece) and not FGT.HideGuideEntry("piece:" .. si .. ":" .. pi, md == mt) then -- (closes after the materials)
                rowIndex = rowIndex + 1
                local row = GetStepRow(rowIndex)
                row:SetParent(stepsContainer)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
                row:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
                SetRowIndent(row, 18)
                row:SetStepIcon(piece.icon) -- item icon when the set data has one
                FGT.ClearStepLock(row) -- grouped collection rows are independent in this pass
                FGT.SetStepLinks(row, piece.auto, piece)

                -- Pieces with materials fold open individually (closed by
                -- default) and show how many of their materials are done.
                local hasMats = #piece.materials > 0
                local pieceKey = goal.id .. "_" .. si .. "_" .. pi
                local open = hasMats and FGT.pieceExpanded[pieceKey]

                row.num:SetText("")
                row.text:SetText(FGT.StepText(piece.text or piece.name))
                FGT.LinkItemName(row) -- the piece's name as an item link
                row.text:SetWidth(math.max(50, width - 18 - 44 - (hasMats and 44 or 0) - (piece.icon and 14 or 0)))
                StyleCheckRow(row, md == mt)
                FGT.PlaceGuideEntry(row, "piece:" .. si .. ":" .. pi, yOffset, md == mt)
                if not hasMats then FGT.MaybePopTick(row, goal.id, PieceKey(si, pi)) end

                if hasMats then
                    -- No checkbox: the piece is done when its materials are.
                    -- The +/- takes the checkbox's spot, like the class headers.
                    row.box:Hide()
                    row.toggle:ClearAllPoints()
                    row.toggle:SetPoint("TOPLEFT", row, "TOPLEFT", 20, -3)
                    FGT.SetPlusMinus(row.toggle, open)
                    row.toggle:Show()
                    row.count:SetText(md .. " / " .. mt)
                    row.count:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
                    row.count:SetShown(md < mt)
                    row.doneCheck:SetShown(md == mt)
                    FGT.CheckCelebration(row, pieceKey, md == mt, FGT.PopCheck)
                    row.pieceKey = pieceKey
                end

                local textHeight = row.text:GetStringHeight() or 14
                local rowHeight2 = math.max(22, textHeight + 8)
                row:SetHeight(rowHeight2)
                row:SetScript("OnClick", function(self, button)
                    if FGT.StepLinkClick(self, button) then return end
                    if self.pieceKey then
                        FGT.pieceExpanded[self.pieceKey] = not FGT.pieceExpanded[self.pieceKey]
                        RefreshSteps(goal)
                    else
                        ToggleStep(goal.id, PieceKey(si, pi)) -- mount tasks: the row is the checkbox
                    end
                end)
                row:Show()
                yOffset = yOffset + rowHeight2 + (open and 2 or 4)

                if open then
                    for mi, materialText in ipairs(piece.materials) do
                        if not FGT.HideGuideEntry("material:" .. si .. ":" .. pi .. ":" .. mi, IsStepDone(goal.id, MaterialKey(si, pi, mi))) then
                        rowIndex = rowIndex + 1
                        local mrow = GetStepRow(rowIndex)
                        mrow:SetParent(stepsContainer)
                        mrow:ClearAllPoints()
                        mrow:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
                        mrow:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
                        SetRowIndent(mrow, 40)
                        mrow:SetStepIcon(nil)
                        FGT.ClearStepLock(mrow)

                        mrow.num:SetText("")
                        mrow.text:SetText(FGT.StepText(materialText))
                        mrow.text:SetWidth(math.max(50, width - 40 - 44))
                        StyleCheckRow(mrow, IsStepDone(goal.id, MaterialKey(si, pi, mi)))
                        FGT.PlaceGuideEntry(mrow, "material:" .. si .. ":" .. pi .. ":" .. mi, yOffset, mrow.isDone)
                        FGT.MaybePopTick(mrow, goal.id, MaterialKey(si, pi, mi))
                        if not mrow.isDone then
                            mrow.text:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3])
                        end

                        local mTextHeight = mrow.text:GetStringHeight() or 14
                        local mRowHeight = math.max(20, mTextHeight + 4)
                        mrow:SetHeight(mRowHeight)
                        -- guide line under the piece's checkbox, joining its materials
                        mrow.guide:ClearAllPoints()
                        mrow.guide:SetPoint("TOPLEFT", mrow, "TOPLEFT", 26, (mi == 1) and 2 or 3)
                        mrow.guide:SetPoint("BOTTOMLEFT", mrow, "BOTTOMLEFT", 26, (mi == #piece.materials) and 8 or 0)
                        mrow.guide:Show()
                        mrow:SetScript("OnClick", function(self, button)
                            if FGT.StepLinkClick(self, button) then return end
                            ToggleStep(goal.id, MaterialKey(si, pi, mi))
                        end)
                        mrow:Show()
                        yOffset = yOffset + mRowHeight + 3
                        end
                    end
                    yOffset = yOffset + 4
                end
                end
            end
        end
        end
    end

    for i = headerIndex + 1, #headerRowPool do
        headerRowPool[i]:Hide()
    end
    for i = rowIndex + 1, #stepRowPool do
        stepRowPool[i]:Hide()
    end

    FGT.UpdateExpandAll(goal)
    FGT.LayoutStepControls()
    yOffset = FGT.LayoutTips(goal, yOffset, width)
    FGT.FinishGuideHeight(yOffset)
end

RefreshSteps = function(goal)
    FGT.BeginGuideLayout(goal)
    local filter = FGT.completedStepsBtn
    filter.text:SetText(FGT.Setting("hideCompletedSteps") and "Show completed" or "Hide completed")
    filter:SetSize(math.ceil(filter.text:GetStringWidth()) + 4, 16)
    filter:Show()
    -- icon frames on this goal's steps: blue on Forever-new goals
    FGT.stepRim = FGT.ForeverWord(goal) and C.FOREVER or C.GOLD2
    FGT.stepQuality = goal.itemQuality -- item name color when the game doesn't know
    if goal.sections then
        RefreshTierSections(goal)
        FGT.EndGuideLayout(goal)
        return
    end

    ResetScrollIfNewGoal(goal)
    local width = stepsContainer:GetWidth()
    local yOffset = 0
    local shown = 0
    for i, entry in ipairs(goal.steps) do
        local stepText = FGT.StepText(type(entry) == "table" and entry.text or entry)
        local stepIcon = type(entry) == "table" and entry.icon or nil
        local row = GetStepRow(i)
        if not PartSelected(goal, i) or FGT.PieceSkipped(entry) then
            row:Hide() -- part of a group you haven't added, or a step your race skips
        else
        shown = shown + 1
        local complete = IsAutoStep(entry) and AutoStepFraction(entry) >= 1 or
            (not IsAutoStep(entry) and IsStepDone(goal.id, i))
        if FGT.HideGuideEntry("step:" .. i, complete) then
            row:Hide()
        else
        row:SetParent(stepsContainer)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
        SetRowIndent(row, 2)

        row.num:SetText(shown .. ".")
        row:SetStepIcon(stepIcon)

        local rowHeight2
        if IsAutoStep(entry) then
            FGT.ClearStepLock(row)
            -- Level-tracked row: no manual checkbox, it reads the roster.
            row.autoEntry = entry
            local best = BestOfClass(entry.autoClass)
            local lvl = best and PreciseLevel(best) or 0
            local done = lvl >= MAX_LEVEL
            if best then
                row.text:SetText(stepText .. "  |cff8a8a8a" .. best.name .. "|r")
                row.levelText:SetText(done and string.format("|cff9fe870Level %d / %d|r", MAX_LEVEL, MAX_LEVEL)
                    or string.format("Level %d / %d", math.floor(lvl), MAX_LEVEL))
            else
                row.text:SetText(stepText .. "  |cff6b6b6bnot seen yet|r")
                row.levelText:SetText("|cff6b6b6b-|r")
            end
            row.levelText:Show()
            StyleCheckRow(row, done)
            -- Read-only row: no checkbox, the class icon takes its spot
            -- and the level readout + bar show progress.
            row.box:Hide()
            row.icon:ClearAllPoints()
            row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
            row.text:SetWidth(math.max(50, width - 32 - 70))
            if not best then row.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3]) end

            row.miniBar:ClearAllPoints()
            row.miniBar:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -6)
            row.miniBar:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            row.miniBar:Show()
            row.miniBar:SetProgress(math.floor(lvl * 100), MAX_LEVEL * 100)

            local textHeight = row.text:GetStringHeight() or 14
            rowHeight2 = math.max(34, textHeight + 20)
            row:SetHeight(rowHeight2)
            row:SetScript("OnClick", nil)
        else
            row.text:SetText(stepText)
            row.text:SetWidth(math.max(50, width - (stepIcon and 58 or 46)))
            -- item links first, so a finished step fades them too (Karl)
            FGT.SetStepLinks(row, type(entry) == "table" and entry.auto or nil, entry)

            StyleCheckRow(row, IsStepDone(goal.id, i))
            FGT.MaybePopTick(row, goal.id, i)
            FGT.StyleStepLock(row, goal, i)

            local textHeight = row.text:GetStringHeight() or 14
            rowHeight2 = math.max(stepIcon and 26 or 20, textHeight + 6)

            -- Steps with a detection rule: readout on the right, plus a
            -- bar for anything countable (materials, skill, gold).
            local rule = type(entry) == "table" and entry.auto or nil
            row.ruleEntry = rule
            if rule then
                local _, cur, max = RuleReadout(rule)
                if cur and max and not IsStepDone(goal.id, i) then
                    row.miniBar:ClearAllPoints()
                    row.miniBar:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -6)
                    row.miniBar:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                    row.miniBar:Show()
                    row.miniBar:SetProgress(cur, max)
                    rowHeight2 = rowHeight2 + 12
                end
            end
            row:SetHeight(rowHeight2)

            row:SetScript("OnClick", function(self, button)
                if FGT.StepLinkClick(self, button) then return end
                if FGT.StepLocked(goal, i) then
                    FGT.PlayLockMotion(self, "jiggle")
                    FGT.ShowStepLockTip(self)
                    return
                end
                ToggleStep(goal.id, i)
            end)
        end

        row:Show()
        FGT.PlaceGuideEntry(row, "step:" .. i, yOffset, complete)
        yOffset = yOffset + rowHeight2 + 6
        end
        end
    end

    -- hide unused pooled rows (both flat-step rows and any leftover
    -- Tier 3 header rows from a previous goal's hierarchical render)
    for i = #goal.steps + 1, #stepRowPool do
        stepRowPool[i]:Hide()
    end
    for i = 1, #headerRowPool do
        headerRowPool[i]:Hide()
    end

    FGT.UpdateExpandAll(goal)
    FGT.LayoutStepControls()
    yOffset = FGT.LayoutTips(goal, yOffset, width)
    FGT.FinishGuideHeight(yOffset)
    FGT.EndGuideLayout(goal)
end

SelectGoal = function(id, skipListRefresh)
    local parent = FGT.armorCollections[id]
    if parent then
        for _, child in ipairs(parent.armorChildren) do
            if IsActive(child) then id = child.id break end
        end
    end
    if FGT.noteCard and FGT.noteCard.goal and FGT.noteCard.goal.id ~= id then FGT.CloseNoteCard(true) end
    local goal
    for _, g in ipairs(FGT.goals) do
        if g.id == id and not g.libraryOnly and IsActive(g) then goal = g break end
    end
    if not goal then
        goal = ActiveGoals()[1]
        if not goal then
            FGT.ShowEmptyTracker()
            return
        end
        id = goal.id
    end
    FGT.HideEmptyTracker()
    selectedId = id
    ForeverGoalTrackerDB.selected = id

    detailTitle:SetText(goal.name)
    local cw = goal.completeWith
    FGT.detailReward = not goal.sections and (goal.rewardItem or (cw and AsList(cw.item)[1])) or nil
    FGT.detailRewardName = goal.name
    local catColor = FGT.categoryColors[goal.category] or C.ACCENT
    detailIcon:SetIcon(goal.icon, catColor)
    detailTag:SetText(FGT.GoalEyebrow(goal))
    detailTag:SetTextColor(catColor[1], catColor[2], catColor[3])

    local diffColor = FGT.difficultyColors[goal.difficulty] or C.SUBTEXT
    detailDiffChip:SetLabel(string.upper(goal.difficulty or ""), diffColor)
    if goal.timeEstimate then
        detailTimeChip:SetLabel(goal.timeEstimate, C.INK2)
        detailTimeChip:Show()
    else
        detailTimeChip:Hide()
    end

    -- Keep descriptions in the data for tooltips; temporarily hide banner copy.
    detailNote:SetText("")
    detailNote:Hide()
    FGT.UpdateEditButton(goal)
    FGT.LayoutForeverInfo(goal)

    resetBtn:SetShown(not goal.autoLevels)
    if FGT.resetUndo and FGT.resetUndo.id ~= goal.id then FGT.resetUndo = nil end -- undo is per goal
    FGT.StyleResetButton()
    local done, total = GoalProgress(goal)
    -- The bar is shared by every goal: opening a different goal jumps
    -- straight to its value, so it only glides when progress changes.
    detailBar.instant = detailBar.goalId ~= goal.id or FGT.quietCelebrate or nil
    detailBar.goalId = goal.id
    if goal.autoLevels then
        detailBar:SetProgress(done, total, string.format("%d / %d levels  ·  %d%%",
            done, total, math.floor(done / math.max(1, total) * 100 + 0.5)))
    else
        detailBar:SetProgress(done, total)
    end
    detailBar.instant = nil

    RefreshSteps(goal)
    if FGT.detailViewport.goalId ~= goal.id then
        FGT.detailViewport.scroll:SetVerticalScroll(0)
        FGT.detailViewport.goalId = goal.id
    end
    FGT.UpdateDetailViewport()
    RefreshGoalList()
    local d2, t2 = OverallProgress()
    overallBar:SetProgress(d2, t2, string.format("%d%% overall", math.floor(d2 / math.max(1, t2) * 100 + 0.5)))
    goalsCompleteText:SetText(string.format("%d of %d goals fully complete", CountGoalsComplete(), #ActiveGoals()))
end

do -- scoped: keeps these locals out of the file's 200-local budget
-- ============================================================
-- Tabs: My Goals | Goal Library
-- ============================================================
local function RefreshOverall()
    local d, t = OverallProgress()
    overallBar:SetProgress(d, t, string.format("%d%% overall", math.floor(d / math.max(1, t) * 100 + 0.5)))
    goalsCompleteText:SetText(string.format("%d of %d goals fully complete", CountGoalsComplete(), #ActiveGoals()))
end
FGT.RefreshOverall = RefreshOverall

-- Folder tabs: the active tab is a box with rounded top corners, a gold
-- glow along its top edge and no bottom edge. Its sides curve outward
-- into a thin line that runs under the row and fades out by the middle
-- of the window. Inactive tabs are just text.
local TAB_H = 30
local TAB_CURVE = 8 -- size of the curved corners where the tab meets the line
local TAB_STYLE = { top = { 0.150, 0.125, 0.070 }, bottom = { 0.060, 0.057, 0.052 }, edge = { 0.78, 0.61, 0.10, 1 } }
local TAB_LINE = STYLE.panel.edge
local TAB_CORNER = "Interface\\AddOns\\" .. ADDON .. "\\Media\\tabcorner-"
-- the curves are a dimmer gold than the box edge, which the border art darkens
local TAB_CURVE_GOLD = { 0.45, 0.36, 0.09 }
local tabs = {}
local tabLineL = main:CreateTexture(nil, "ARTWORK")
local tabLineR = main:CreateTexture(nil, "ARTWORK")
for _, t in ipairs({ tabLineL, tabLineR }) do
    t:SetTexture(SOLID)
    t:SetHeight(1)
end

-- The line breaks under the active tab, so the tab reads as open.
local function PlaceTabLine()
    local on
    for _, t in ipairs(tabs) do if t.active then on = t end end
    local y = TABS_TOP - TAB_H + 1
    tabLineL:ClearAllPoints()
    tabLineR:ClearAllPoints()
    tabLineL:SetPoint("TOPLEFT", main, "TOPLEFT", 16, y)
    if on then
        tabLineL:SetPoint("TOPRIGHT", on, "BOTTOMLEFT", 3 - TAB_CURVE, 1)
        tabLineR:SetPoint("TOPLEFT", on, "BOTTOMRIGHT", TAB_CURVE - 3, 1)
        tabLineR:SetPoint("TOPRIGHT", main, "TOP", 0, y)
        ApplyHGradient(tabLineL, TAB_LINE, TAB_LINE, 1, 1)
        ApplyHGradient(tabLineR, TAB_LINE, TAB_LINE, 1, 0)
        tabLineR:Show()
    else
        tabLineL:SetPoint("TOPRIGHT", main, "TOP", 0, y)
        ApplyHGradient(tabLineL, TAB_LINE, TAB_LINE, 1, 0)
        tabLineR:Hide()
    end
end

local function NewTab(label)
    local tab = CreateFrame("Button", nil, main)
    tab:SetHeight(TAB_H)
    -- The box hangs below a clip frame that ends where the curves begin,
    -- which hides the box's bottom edge but keeps the rounded top corners.
    local clip = CreateFrame("Frame", nil, tab)
    clip:SetPoint("TOPLEFT", 0, 0)
    clip:SetPoint("BOTTOMRIGHT", 0, TAB_CURVE)
    local clips = clip.SetClipsChildren and pcall(clip.SetClipsChildren, clip, true)
    tab.box = CreateFrame("Frame", nil, clip, "BackdropTemplate")
    tab.box:SetPoint("TOPLEFT", 0, 0)
    tab.box:SetPoint("BOTTOMRIGHT", 0, clips and -14 or 0)
    Etch(tab.box, TAB_STYLE, 14)
    -- gold glow fading down from the top edge
    local glow = tab.box:CreateTexture(nil, "ARTWORK")
    glow:SetTexture(SOLID)
    glow:SetPoint("TOPLEFT", 3, -3)
    glow:SetPoint("TOPRIGHT", -3, -3)
    glow:SetHeight(12)
    ApplyVGradient(glow, C.ACCENT, C.ACCENT, 0.22, 0)
    -- bright gold line along the top, strongest in the middle
    local hiL = tab.box:CreateTexture(nil, "ARTWORK", nil, 1)
    local hiR = tab.box:CreateTexture(nil, "ARTWORK", nil, 1)
    for _, t in ipairs({ hiL, hiR }) do
        t:SetTexture(SOLID)
        t:SetHeight(1)
    end
    hiL:SetPoint("TOPLEFT", 3, -3)
    hiL:SetPoint("TOPRIGHT", tab.box, "TOP", 0, -3)
    hiR:SetPoint("TOPLEFT", tab.box, "TOP", 0, -3)
    hiR:SetPoint("TOPRIGHT", -3, -3)
    local hiGold = { 1.00, 0.88, 0.45 }
    ApplyHGradient(hiL, hiGold, hiGold, 0.25, 0.95)
    ApplyHGradient(hiR, hiGold, hiGold, 0.95, 0.25)

    -- Below the clip: the tab's fill carries on down to the line, and
    -- each side curves outward into it (gold fading to the line color).
    tab.feet = CreateFrame("Frame", nil, tab)
    tab.feet:SetAllPoints()
    local f = (TAB_H - TAB_CURVE) / (TAB_H - TAB_CURVE + 14) -- box gradient at the clip edge
    local fr, fg, fb = TAB_STYLE.top[1] + (TAB_STYLE.bottom[1] - TAB_STYLE.top[1]) * f,
        TAB_STYLE.top[2] + (TAB_STYLE.bottom[2] - TAB_STYLE.top[2]) * f,
        TAB_STYLE.top[3] + (TAB_STYLE.bottom[3] - TAB_STYLE.top[3]) * f
    local strip = tab.feet:CreateTexture(nil, "BACKGROUND")
    strip:SetTexture(SOLID)
    strip:SetVertexColor(fr, fg, fb, 1)
    strip:SetPoint("BOTTOMLEFT", 3, 0)
    strip:SetPoint("BOTTOMRIGHT", -3, 0)
    strip:SetHeight(TAB_CURVE)
    for side = 1, 2 do
        local fill = tab.feet:CreateTexture(nil, "BACKGROUND", nil, 1)
        local line = tab.feet:CreateTexture(nil, "ARTWORK")
        fill:SetTexture(TAB_CORNER .. "fill")
        line:SetTexture(TAB_CORNER .. "line")
        fill:SetVertexColor(fr, fg, fb, 1)
        for _, t in ipairs({ fill, line }) do
            t:SetSize(TAB_CURVE, TAB_CURVE)
            if side == 1 then
                t:SetPoint("BOTTOMRIGHT", tab, "BOTTOMLEFT", 3, 0)
            else
                t:SetPoint("BOTTOMLEFT", tab, "BOTTOMRIGHT", -3, 0)
                t:SetTexCoord(1, 0, 0, 1) -- mirrored
            end
        end
        if side == 1 then
            ApplyHGradient(line, TAB_LINE, TAB_CURVE_GOLD, 1, 1)
        else
            ApplyHGradient(line, TAB_CURVE_GOLD, TAB_LINE, 1, 1)
        end
    end

    -- the label sits above the box
    local over = CreateFrame("Frame", nil, tab)
    over:SetAllPoints()
    over:SetFrameLevel(tab.box:GetFrameLevel() + 2)
    tab.text = NewTitleString(over, 12)
    tab.text:SetPoint("CENTER", 0, -1)
    tab.text:SetText(label)
    tab:SetWidth(math.ceil(tab.text:GetStringWidth()) + 40)
    tab:SetScript("OnEnter", function(self)
        if not self.active then self.text:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3]) end
    end)
    tab:SetScript("OnLeave", function(self)
        if not self.active then self.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3]) end
    end)
    function tab:SetActive(on)
        self.active = on
        self.box:SetShown(on)
        self.feet:SetShown(on)
        if on then
            self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3])
        else
            self.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        end
        PlaceTabLine()
    end
    table.insert(tabs, tab)
    return tab
end

local trackerTab = NewTab("My Goals")
trackerTab:SetPoint("TOPLEFT", main, "TOPLEFT", 16, TABS_TOP)
local libraryTab = NewTab("Goal Library")
libraryTab:SetPoint("LEFT", trackerTab, "RIGHT", 6, 0)
-- the goal list lines up with the right edge of the Goal Library tab
listPanel:SetWidth(trackerTab:GetWidth() + 6 + libraryTab:GetWidth())

-- A bright gold streak that circles a button's border, fading out behind
-- it like a comet's tail (talentsforever.com's "Back to Class" button).
-- It follows the border's rounded corners and eases in and out on each
-- lap (4.5 s). Still when Celebrations are off. inset = where the
-- border line starts inside the frame.
do
    local LAP, T, R, DOTS = 4.5, 2, 4, 4 -- lap time, line width, corner radius, dots per corner
    local T_DEFAULT = T -- f.comet.width overrides T per comet (thinner on small buttons)
    local GOLD = { 1.00, 0.89, 0.48 }
    -- arc centers (from the frame's corners) and start angles, in order
    local ARCS = {
        tr = { 1, 0, -90 }, br = { 1, 1, 0 }, bl = { 0, 1, 90 }, tl = { 0, 0, 180 },
    }
    -- a straight piece on edge 1-4; a and b run along the edge from its first corner
    local function Place(f, tex, edge, a, b, fa, fb)
        local w, h, c = f:GetWidth(), f:GetHeight(), f.comet.inset + T / 2
        local GOLD = f.comet.color or GOLD -- optional tint (blue on Forever-new goals)
        tex:ClearAllPoints()
        if edge == 1 then -- top, left to right
            tex:SetPoint("TOPLEFT", f, "TOPLEFT", c + a, -(c - T / 2))
            tex:SetSize(b - a, T)
            ApplyHGradient(tex, GOLD, GOLD, fa, fb)
        elseif edge == 2 then -- right, top to bottom
            tex:SetPoint("TOPLEFT", f, "TOPLEFT", w - c - T / 2, -(c + a))
            tex:SetSize(T, b - a)
            ApplyVGradient(tex, GOLD, GOLD, fa, fb)
        elseif edge == 3 then -- bottom, right to left
            tex:SetPoint("TOPLEFT", f, "TOPLEFT", w - c - b, -(h - c - T / 2))
            tex:SetSize(b - a, T)
            ApplyHGradient(tex, GOLD, GOLD, fb, fa)
        else -- left, bottom to top
            tex:SetPoint("TOPLEFT", f, "TOPLEFT", c - T / 2, -(h - c - b))
            tex:SetSize(T, b - a)
            ApplyVGradient(tex, GOLD, GOLD, fb, fa)
        end
        tex:Show()
    end
    local function Tex(cm, pool, i)
        local tex = cm[pool][i]
        if not tex then
            tex = cm.layer:CreateTexture(nil, "OVERLAY")
            tex:SetTexture(SOLID)
            tex:SetBlendMode("ADD")
            cm[pool][i] = tex
        end
        return tex
    end
    local function Draw(f)
        local cm = f.comet
        T = cm.width or T_DEFAULT
        local w, h = f:GetWidth(), f:GetHeight()
        local c = cm.inset + T / 2
        local lw, lh = w - 2 * c - 2 * R, h - 2 * c - 2 * R
        local n, nd = 0, 0
        local peakA = cm.alpha * cm.vis -- fades with the on/off switch
        if lw > 0 and lh > 0 and peakA > 0.005 and FGT.Setting("celebrations") ~= "off" then
            local A = math.pi * R / 2
            local segs = { { 1, lw }, { "tr", A }, { 2, lh }, { "br", A }, { 3, lw }, { "bl", A }, { 4, lh }, { "tl", A } }
            local P = 2 * (lw + lh) + 4 * A
            -- cm.ref: move like another button's comet (same speed and tail
            -- in pixels), so buttons of different sizes match
            local lap, Pt = cm.lap or LAP, P
            local ref = cm.ref
            if ref and ref:GetWidth() > 0 then
                local rc = (ref.comet and ref.comet.inset or cm.inset) + T / 2
                Pt = 2 * (ref:GetWidth() - 2 * rc - 2 * R + ref:GetHeight() - 2 * rc - 2 * R) + 4 * A
                lap = (ref.comet and ref.comet.lap or LAP) * P / Pt
            end
            -- gentle ease: a little slower at the start of a lap, quicker
            -- through the middle, never below half speed (no "stuck" look)
            local x = (cm.t / lap) % 1
            x = x - 0.5 * math.sin(2 * math.pi * x) / (2 * math.pi)
            local peak = x * P
            local tail, head = Pt * 0.22, Pt * 0.08
            local function Alpha(pos)
                local u = (pos - peak) % P
                if u > P / 2 then u = u - P end
                if u <= 0 and u >= -tail then return peakA * (1 + u / tail) end
                if u > 0 and u <= head then return peakA * (1 - u / head) end
                return 0
            end
            local pieces = { { peak - tail, peak, 0, peakA }, { peak, peak + head, peakA, 0 } }
            local start = 0
            for _, sg in ipairs(segs) do
                local kind, len = sg[1], sg[2]
                if type(kind) == "number" then
                    for _, pc in ipairs(pieces) do
                        for shift = -P, P, P do -- the streak wraps past the start
                            local a0, a1 = pc[1] + shift, pc[2] + shift
                            local s0, s1 = math.max(a0, start), math.min(a1, start + len)
                            if s1 - s0 > 0.5 then
                                local fa = pc[3] + (pc[4] - pc[3]) * (s0 - a0) / (a1 - a0)
                                local fb = pc[3] + (pc[4] - pc[3]) * (s1 - a0) / (a1 - a0)
                                n = n + 1
                                Place(f, Tex(cm, "tex", n), kind, R + s0 - start, R + s1 - start, fa, fb)
                            end
                        end
                    end
                else
                    -- a rounded corner: a few small dots along the quarter circle
                    local arc = ARCS[kind]
                    local cx = (arc[1] == 1) and (w - c - R) or (c + R)
                    local cy = (arc[2] == 1) and (h - c - R) or (c + R)
                    for k = 0, DOTS - 1 do
                        local q = (k + 0.5) / DOTS
                        local al = Alpha(start + q * len)
                        if al > 0.02 then
                            local ang = math.rad(arc[3] + 90 * q)
                            local px, py = cx + R * math.cos(ang), cy + R * math.sin(ang)
                            nd = nd + 1
                            local dot = Tex(cm, "dots", nd)
                            dot:ClearAllPoints()
                            dot:SetPoint("TOPLEFT", f, "TOPLEFT", px - T / 2, -(py - T / 2))
                            dot:SetSize(T, T)
                            local g = cm.color or GOLD
                            dot:SetVertexColor(g[1], g[2], g[3], al)
                            dot:Show()
                        end
                    end
                end
                start = start + len
            end
        end
        for i = n + 1, #cm.tex do cm.tex[i]:Hide() end
        for i = nd + 1, #cm.dots do cm.dots[i]:Hide() end
    end
    -- lap: seconds per lap (default 4.5). f.comet.on = false fades it out
    -- (and true back in) over about half a second.
    function FGT.AddBorderComet(f, inset, alpha, lap)
        local layer = CreateFrame("Frame", nil, f)
        layer:SetAllPoints()
        layer:SetFrameLevel(f:GetFrameLevel() + 3)
        f.comet = { inset = inset or 2, alpha = alpha or 0.9, lap = lap, t = 0, tex = {}, dots = {},
                    layer = layer, on = true, vis = 1 }
        layer:SetScript("OnUpdate", function(_, elapsed)
            local cm = f.comet
            cm.t = cm.t + elapsed
            local want = cm.on and 1 or 0
            cm.vis = cm.vis + (want - cm.vis) * math.min(1, elapsed * 4)
            Draw(f)
        end)
    end
end

-- Empty tracker (first open, or every goal removed): cobwebs in the
-- goal list's top corners like an empty quest log, a quiet "Empty"
-- label, and on the right a short note with a button to the Library.
local emptyNote = NewFontString(detailPanel, 12, "", C.INK2[1], C.INK2[2], C.INK2[3])
emptyNote:SetPoint("CENTER", detailPanel, "CENTER", 0, 24)
emptyNote:SetWidth(380)
emptyNote:SetJustifyH("CENTER")
-- Lines are broken by hand (no single word left on a line); the box is
-- wide enough that none of them wraps on its own.
emptyNote:SetText("No goals on your tracker yet.\n\nGet a few picked for your character,\nor choose your own.")
emptyNote:Hide()

do
    local E = {}
    -- Modular book: fixed spine ends, cropped/mirrored strips, separate
    -- raised bands and two right-side fittings. Grain never stretches.
    local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
    local function BookSurface(panel, fittings)
        local art = CreateFrame("Frame", nil, panel)
        art:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -3)
        art:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 3)
        art:EnableMouse(false)
        art.leather = art:CreateTexture(nil, "BACKGROUND")
        art.leather:SetTexture(MEDIA .. "empty-book-leather")
        art.leather:SetDesaturated(true)
        art.tiles = { art.leather }
        art.corners = {}
        if fittings then
            local function piece(name, layer)
                local t = art:CreateTexture(nil, "ARTWORK", nil, layer or -2)
                t:SetTexture(MEDIA .. "empty-book-" .. name)
                t:SetDesaturated(true)
                return t
            end
            art.spine = { top = piece("spine"), bottom = piece("spine"), tiles = {}, bands = {} }
            art.edges = { top = {}, bottom = {} }
            for i = 1, 5 do art.spine.bands[i] = piece("band", -1) end
            art.NewBookPiece = piece
            -- The source is a top-left fitting. Mirror its texture instead
            -- of rotating the sampling rectangle, keeping both edge arms
            -- flush and the inward flourish facing the leather field.
            for _, spec in ipairs({ { "TOPRIGHT", 0, 1, -4 },
                                    { "BOTTOMRIGHT", 1, 0, 4 } }) do
                local corner = art:CreateTexture(nil, "ARTWORK", nil, 1)
                corner:SetTexture(MEDIA .. "empty-book-corner")
                corner:SetDesaturated(true)
                corner:SetPoint(spec[1], art, spec[1], -4, spec[4])
                corner:SetTexCoord(1, 0, spec[2], spec[3])
                -- Separate contact shadow stays down/right on every corner.
                local shadow = art:CreateTexture(nil, "ARTWORK", nil, 0)
                shadow:SetTexture(MEDIA .. "empty-book-corner")
                shadow:SetPoint(spec[1], art, spec[1], -3, spec[4] - 2)
                shadow:SetTexCoord(1, 0, spec[2], spec[3])
                shadow:SetVertexColor(0, 0, 0, 0.55)
                art.corners[#art.corners + 1] = { metal = corner, shadow = shadow }
            end
        end
        -- All artwork sits below this darkness, keeping the empty-state
        -- copy/buttons readable. Plain alpha also follows the frame fade.
        art.darkness = art:CreateTexture(nil, "OVERLAY")
        art.darkness:SetAllPoints(art)
        art.darkness:SetColorTexture(0.025, 0.022, 0.019, fittings and 0.68 or 0.77)
        function art:Fit()
            local w, h = self:GetWidth(), self:GetHeight()
            if w <= 0 or h <= 0 then return end
            -- Mirror alternate tiles so the generated edge pixels meet
            -- exactly. Crop the final tiles; never stretch the grain.
            local used = 0
            for y = 0, math.ceil(h / 512) - 1 do
                for x = 0, math.ceil(w / 512) - 1 do
                    used = used + 1
                    local tile = self.tiles[used]
                    if not tile then
                        tile = self:CreateTexture(nil, "BACKGROUND")
                        tile:SetTexture(MEDIA .. "empty-book-leather")
                        tile:SetDesaturated(true)
                        self.tiles[used] = tile
                    end
                    local tw, th = math.min(512, w - x * 512), math.min(512, h - y * 512)
                    local u, v = x % 2, y % 2
                    tile:ClearAllPoints()
                    tile:SetPoint("TOPLEFT", self, "TOPLEFT", x * 512, -y * 512)
                    tile:SetSize(tw, th)
                    tile:SetTexCoord(u, u + (u == 0 and 1 or -1) * tw / 512,
                        v, v + (v == 0 and 1 or -1) * th / 512)
                    tile:Show()
                end
            end
            for i = used + 1, #self.tiles do self.tiles[i]:Hide() end
            if self.spine then
                local spine = self.spine
                local sw = math.min(48, w * 0.16)
                local scale = sw / 48
                local cap = math.min(16 * scale, h / 2)
                self.spineWidth = sw
                -- Sample the central silhouette, excluding transparent
                -- source margins. End folds retain their proportions.
                spine.top:ClearAllPoints()
                spine.top:SetPoint("TOPLEFT", self, "TOPLEFT", 2, 0)
                spine.top:SetSize(sw, cap)
                spine.top:SetTexCoord(0.31, 0.69, 0, cap / (192 * scale))
                spine.bottom:ClearAllPoints()
                spine.bottom:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 2, 0)
                spine.bottom:SetSize(sw, cap)
                spine.bottom:SetTexCoord(0.31, 0.69, 1 - cap / (192 * scale), 1)
                local remaining, unit, count = h - 2 * cap, 160 * scale, 0
                while remaining > 0.001 do
                    count = count + 1
                    local t = spine.tiles[count]
                    if not t then t = self.NewBookPiece("spine"); spine.tiles[count] = t end
                    local th = math.min(unit, remaining)
                    local v = count % 2 == 1 and 1 / 12 or 11 / 12
                    t:ClearAllPoints()
                    t:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -cap - (count - 1) * unit)
                    t:SetSize(sw, th)
                    t:SetTexCoord(0.31, 0.69, v, v + (count % 2 == 1 and 1 or -1) * th / (192 * scale))
                    t:Show()
                    remaining = remaining - th
                end
                for i = count + 1, #spine.tiles do spine.tiles[i]:Hide() end
                -- Short books lose bands rather than crowding the folds.
                local bands = math.max(0, math.min(5, math.floor((h - 2 * cap) / (90 * scale))))
                for i, t in ipairs(spine.bands) do
                    t:SetShown(i <= bands)
                    if i <= bands then
                        t:ClearAllPoints()
                        t:SetPoint("TOPLEFT", self, "TOPLEFT", 0,
                            -cap - (h - 2 * cap) * i / (bands + 1) + 6 * scale)
                        t:SetSize(sw + 4 * scale, 12 * scale)
                        t:SetTexCoord(0.055, 0.945, 0.28, 0.72)
                    end
                end
                -- Thin rolled cover edges repeat horizontally at a fixed
                -- scale, under the spine and right metal caps.
                for _, side in ipairs({ "top", "bottom" }) do
                    local pool, n, span = self.edges[side], 0, math.max(0, w - sw - 6)
                    while span > 0.001 do
                        n = n + 1
                        local t = pool[n]
                        if not t then t = self.NewBookPiece("edge", -3); pool[n] = t end
                        local tw, u = math.min(128, span), (n - 1) % 2
                        t:ClearAllPoints()
                        local anchor = side == "top" and "TOPLEFT" or "BOTTOMLEFT"
                        t:SetPoint(anchor, self, anchor, sw + (n - 1) * 128,
                            side == "top" and -2 or 2)
                        t:SetSize(tw, math.min(12, h / 4))
                        t:SetTexCoord(u, u + (u == 0 and 1 or -1) * tw / 128,
                            side == "top" and 0.36 or 0.62, side == "top" and 0.62 or 0.36)
                        t:Show()
                        span = span - tw
                    end
                    for i = n + 1, #pool do pool[i]:Hide() end
                end
            end
            -- Normally 88px. Only shrink in exceptionally tiny bounds so
            -- opposing corners cannot collide or escape the panel.
            local size = math.max(1, math.min(88, (w - 16) / 2, (h - 16) / 2))
            for _, corner in ipairs(self.corners) do
                corner.metal:SetSize(size, size)
                corner.shadow:SetSize(size, size)
            end
        end
        art:SetScript("OnSizeChanged", function(self) self:Fit() end)
        art:Fit()
        return art
    end
    E.art = BookSurface(listPanel, false)
    E.bg = E.art.leather
    E.detailArt = BookSurface(detailPanel, true)

    E.label = NewTitleString(E.art, 13)
    E.label:SetDrawLayer("OVERLAY")
    E.label:SetPoint("CENTER", listPanel, "CENTER", 0, 0)
    E.label:SetText("Empty")
    E.label:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    E.label:SetShadowColor(0, 0, 0, 1)

    -- Primary: the welcome wizard's suggestions, straight to "What interests you?"
    E.help = CreateFrame("Button", nil, detailPanel, "BackdropTemplate")
    E.help:SetHeight(36)
    Etch(E.help, STYLE.rowSel, 12)
    E.help.text = NewTitleString(E.help, 14)
    E.help.text:SetPoint("CENTER", 0, 0)
    E.help.text:SetText("Help me get started")
    E.help:SetWidth(math.ceil(E.help.text:GetStringWidth()) + 64)
    E.help:SetPoint("TOP", emptyNote, "BOTTOM", 0, -20)
    E.help:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
    E.help:SetScript("OnLeave", function(self) self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
    E.help:SetScript("OnClick", function() if FGT.OpenWelcome then FGT.OpenWelcome(2) end end)
    FGT.AddBorderComet(E.help, 2, 0.9)

    -- Secondary: a quiet text link under it
    E.button = CreateFrame("Button", nil, detailPanel)
    E.button.text = NewFontString(E.button, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
    E.button.text:SetPoint("CENTER", 0, 0)
    E.button.text:SetText("or browse the Goal Library")
    E.button:SetSize(math.ceil(E.button.text:GetStringWidth()) + 12, 22)
    E.button:SetPoint("TOP", E.help, "BOTTOM", 0, -10)
    E.button:SetScript("OnEnter", function(self) self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
    E.button:SetScript("OnLeave", function(self) self.text:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3]) end)
    E.button:SetScript("OnClick", function() if FGT.ShowTab then FGT.ShowTab("library") end end)

    E.parts = { E.art, E.detailArt, E.label, E.button, E.help }
    for _, p in ipairs(E.parts) do p:Hide() end
    FGT.emptyUI = E
end

-- "Find your next goal": a button after the last goal card that opens the
-- welcome wizard's suggestions, skipping goals you already have. Same gold
-- look and comet as "Help me get started" (Karl). Placed by LayoutGoalList.
function FGT.FindMoreButton()
    local b = FGT.findMore
    if b then return b end
    b = CreateFrame("Button", nil, listContent, "BackdropTemplate")
    b:SetHeight(40)
    Etch(b, STYLE.rowSel, 12) -- gold, like "Help me get started" (Karl)
    b.text = NewTitleString(b, 13)
    b.text:SetPoint("CENTER", 0, 0)
    b.text:SetText("Find your next goal")
    b:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Find your next goal", C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:AddLine("Suggestions for the character you're on, skipping goals you already have.",
            C.INK2[1], C.INK2[2], C.INK2[3], true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function()
        GameTooltip:Hide()
        if FGT.OpenWelcome then FGT.OpenWelcome(nil, true) end
    end)
    FGT.AddBorderComet(b, 2, 0.9) -- same comet as "Help me get started"
    b.comet.ref = FGT.emptyUI.help -- and the same speed, though this button is wider
    FGT.findMore = b
    return b
end

local detailParts -- every detail-panel element hidden by the empty state
function FGT.ShowEmptyTracker()
    FGT.CancelGuideMotion()
    FGT.guideLayout = nil
    FGT.CloseNoteCard(true)
    local appearing = not emptyNote:IsVisible()
    selectedId = nil
    for _, part in ipairs(detailParts) do part:Hide() end
    emptyNote:Show()
    for _, p in ipairs(FGT.emptyUI.parts) do p:Show() end
    sortBar:Hide() -- nothing to sort
    RefreshGoalList()
    RefreshOverall()
    -- the message, button and link fade (and rise) in when they appear
    if appearing then FGT.AnimateEmpty() end
end
-- The message, button and link sit in one container that fades in while
-- growing from 94% (no slide), when they appear and when the window
-- opens on an empty tracker. Subtle: fade only. Off: instant.
do
    local cluster = CreateFrame("Frame", nil, detailPanel)
    cluster:SetSize(1, 1)
    cluster:SetPoint("CENTER", detailPanel, "CENTER", 0, 24)
    emptyNote:SetParent(cluster)
    emptyNote:ClearAllPoints()
    emptyNote:SetPoint("CENTER", cluster, "CENTER", 0, 0)
    FGT.emptyUI.help:SetParent(cluster)
    FGT.emptyUI.button:SetParent(cluster)
    FGT.emptyCluster = cluster
end
function FGT.AnimateEmpty()
    local W, cl, art = FGT.welcome, FGT.emptyCluster, FGT.emptyUI.art
    if not (W and W.Tween) then return end
    local full = W.Motion() == "full"
    W.Tween("empty", 0.7, function(p)
        local e = W.EaseOut(p)
        cl:SetAlpha(e)
        art:SetAlpha(e) -- the painted panel fades in with the message
        FGT.emptyUI.detailArt:SetAlpha(e)
        cl:SetScale(full and (0.94 + 0.06 * e) or 1)
    end, function()
        cl:SetAlpha(1); art:SetAlpha(1); FGT.emptyUI.detailArt:SetAlpha(1); cl:SetScale(1)
    end)
end
main:HookScript("OnShow", function()
    if emptyNote:IsShown() then FGT.AnimateEmpty() end
end)
function FGT.HideEmptyTracker()
    if not emptyNote:IsShown() then return end
    emptyNote:Hide()
    for _, p in ipairs(FGT.emptyUI.parts) do p:Hide() end
    sortBar:Show()
    for _, part in ipairs(detailParts) do part:Show() end
end
detailParts = { FGT.detailViewport.scroll, detailIcon, detailTag, detailTitle, detailDiffChip, detailTimeChip, detailNote,
    detailBar, detailBar.label, divider, stepsHeader, stepsScrollObj.scroll, resetBtn,
    FGT.detailNewChip, FGT.detailDoneChip, FGT.foreverNotice, FGT.expandAllBtn, FGT.detailLockChip, FGT.detailEditBtn,
    FGT.personalNote, FGT.detailNoteBtn, FGT.goalBanner, FGT.completedStepsBtn }

-- "Clear" next to the sort bar: removes every goal from My Goals in one
-- go, after a confirm in the right-click menu's style. Progress is kept
-- (adding a goal back brings its ticks back), like removing one goal.
do
    local btn = CreateFrame("Button", nil, sortBar, "BackdropTemplate") -- hides with the sort bar
    btn:SetSize(52, 22)
    btn:SetPoint("LEFT", sortBar, "RIGHT", 6, 0)
    Etch(btn, STYLE.button, 10)
    btn.text = NewFontString(btn, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText("Clear")
    btn:SetScript("OnEnter", function(self)
        self:SetEtch(STYLE.btnHover)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Remove all goals", C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:AddLine("Your progress is kept if you add them back.", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self) self:SetEtch(STYLE.button); GameTooltip:Hide() end)

    local M = CreateFrame("Frame", nil, main, "BackdropTemplate")
    M:SetFrameLevel(main:GetFrameLevel() + 60)
    M:SetWidth(200)
    M:SetHeight(2 * MENU_ROW + 8)
    Etch(M, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
    M:EnableMouse(true)
    M:Hide()
    M.catcher = CreateFrame("Button", nil, main)
    M.catcher:SetAllPoints(main)
    M.catcher:SetFrameLevel(main:GetFrameLevel() + 55)
    M.catcher:RegisterForClicks("AnyUp")
    M.catcher:Hide()
    local function Close() M:Hide(); M.catcher:Hide() end
    M.catcher:SetScript("OnClick", Close)
    main:HookScript("OnHide", Close)
    M.rows = {}
    for i = 1, 2 do
        local row = CreateFrame("Button", nil, M)
        row:SetHeight(MENU_ROW)
        row:SetPoint("TOPLEFT", M, "TOPLEFT", 4, -4 - (i - 1) * MENU_ROW)
        row:SetPoint("TOPRIGHT", M, "TOPRIGHT", -4, -4 - (i - 1) * MENU_ROW)
        row.hl = row:CreateTexture(nil, "BACKGROUND")
        row.hl:SetTexture(SOLID)
        row.hl:SetAllPoints(row)
        ApplyHGradient(row.hl, C.ACCENT, C.ACCENT, 0.18, 0.02)
        row.hl:Hide()
        row.icon = row:CreateTexture(nil, "ARTWORK") -- Karl's UI icons
        row.icon:SetSize(13, 13)
        row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.label = NewFontString(row, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
        row.label:SetPoint("LEFT", row, "LEFT", 27, 0)
        row:SetScript("OnEnter", function(self) self.hl:Show() end)
        row:SetScript("OnLeave", function(self) self.hl:Hide() end)
        M.rows[i] = row
    end
    FGT.clearMenu = M
    M.rows[1].label:SetTextColor(1.00, 0.50, 0.42)
    M.rows[1].icon:SetTexture(FGT.Icon("trash"))
    M.rows[2].icon:SetTexture(FGT.Icon("close"))
    M.rows[2].label:SetText("Cancel")
    M.rows[2]:SetScript("OnClick", Close)
    M.rows[1]:SetScript("OnClick", function()
        Close()
        local DB = ForeverGoalTrackerDB
        DB.active = {}
        for id in pairs(DB.activeParts) do DB.activeParts[id] = {} end
        DB.favorites = {}
        SelectGoal(nil)
        LayoutGoalList()
        FGT.RefreshOverall()
        if FGT.LayoutLibrary then FGT.LayoutLibrary() end
    end)
    btn:SetScript("OnClick", function()
        if M:IsShown() then Close() return end
        local n = #ActiveGoals()
        M.rows[1].label:SetText(n == 1 and "Remove 1 goal" or string.format("Remove all %d goals", n))
        M:ClearAllPoints()
        M:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -4)
        M:Show()
        M.catcher:Show()
    end)
end

-- ------------------------------------------------------------
-- Library panel
-- ------------------------------------------------------------
local libraryPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
libraryPanel:SetPoint("TOPLEFT", main, "TOPLEFT", 16, PANEL_TOP)
libraryPanel:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -16, 16)
Etch(libraryPanel, STYLE.panel, 12)
FGT.AddGrime(libraryPanel, 0.18, 12, 0.13, 0, 140)
libraryPanel:Hide()

-- No heading here: the Goal Library tab above already names the page.
local libSummary = NewFontString(libraryPanel, 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
libSummary:SetPoint("LEFT", libraryPanel, "TOPLEFT", 14, -20)

-- Category filter chips (wrap onto extra lines on narrow windows).
local FILTERS = {
    { key = "all",        label = "All" },
    { key = "added",      label = "Added" },
    { key = "Legendary",  label = "Legendary", match = "^Legendary" },
    { key = "Epic Weapon", label = "Epic Weapons" },
    { key = "Mount",      label = "Mounts", match = "^Mount" },
    { key = "Reputation", label = "Reputation" },
    { key = "Raid",       label = "Raids" },
    { key = "Attunement", label = "Attunements" },
    { key = "Item Set",   label = "Item Sets" },
    { key = "Profession", label = "Professions" },
    { key = "PvP",        label = "PvP" },
    { key = "Milestone",  label = "Milestones" },
    { key = "Social",     label = "Social" },
}
-- Forever client: a blue "New & Updated" chip after Added (goals new
-- in Forever or updated by it).
if FGT.isForever then
    table.insert(FILTERS, 3, { key = "new", label = FGT.ForeverDot(14) .. "New & Updated", forever = true })
end
local libFilter = "all"
local filterChips = {}
local libScroll = CreateScrollArea(libraryPanel)
local LayoutLibrary -- forward

for i, f in ipairs(FILTERS) do
    local chip = CreateFrame("Button", nil, libraryPanel, "BackdropTemplate")
    chip:SetHeight(20)
    Etch(chip, STYLE.button, 8)
    chip.text = NewFontString(chip, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
    chip.text:SetPoint("CENTER", 0, 0)
    chip.text:SetText(f.label)
    chip:SetWidth(math.ceil(chip.text:GetStringWidth()) + 18)
    chip.filter = f
    chip.foreverNew = f.forever -- blue twin styles (STYLE.foreverTwin)
    chip:SetScript("OnClick", function()
        libFilter = f.key
        libScroll.scroll:SetVerticalScroll(0)
        LayoutLibrary()
    end)
    chip:SetScript("OnEnter", function(self) if libFilter ~= f.key then self:SetEtch(STYLE.btnHover) end end)
    chip:SetScript("OnLeave", function(self) if libFilter ~= f.key then self:SetEtch(STYLE.button) end end)
    filterChips[i] = chip
end

-- Faction picker, shown under the chips on filters that hold faction
-- goals: Both / [crest] Alliance / [crest] Horde. Starts on Both.
do
    local seg = { buttons = {} }
    local OPTIONS = {
        { key = "Both" },
        { key = "Alliance", crest = "Interface\\TargetingFrame\\UI-PVP-Alliance", color = { 0.30, 0.55, 1.00 } },
        { key = "Horde",    crest = "Interface\\TargetingFrame\\UI-PVP-Horde",    color = { 0.91, 0.28, 0.24 } },
    }
    -- Defaults to Both: goals aren't tied to the character you're on,
    -- since players plan for alts on either side.
    function seg.Current()
        return (ForeverGoalTrackerDB and ForeverGoalTrackerDB.libFaction) or "Both"
    end
    for i, opt in ipairs(OPTIONS) do
        local b = CreateFrame("Button", nil, libraryPanel, "BackdropTemplate")
        b:SetHeight(22)
        Etch(b, STYLE.button, 8)
        b.text = NewFontString(b, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
        b.text:SetText(opt.key)
        local w = math.ceil(b.text:GetStringWidth())
        if opt.crest then
            -- the emblem sits in the top-left part of the target-frame texture
            b.crest = b:CreateTexture(nil, "ARTWORK")
            b.crest:SetTexture(opt.crest)
            b.crest:SetTexCoord(0, 0.62, 0, 0.62)
            b.crest:SetSize(16, 16)
            b.crest:SetPoint("LEFT", 8, 0)
            b.text:SetPoint("LEFT", b.crest, "RIGHT", 4, 0)
            b:SetWidth(w + 40)
        else
            b.text:SetPoint("CENTER", 0, 0)
            b:SetWidth(w + 24)
        end
        b.opt = opt
        b:SetScript("OnClick", function()
            ForeverGoalTrackerDB.libFaction = opt.key
            libScroll.scroll:SetVerticalScroll(0)
            LayoutLibrary()
        end)
        b:SetScript("OnEnter", function(self) if seg.Current() ~= opt.key then self:SetEtch(STYLE.btnHover) end end)
        b:SetScript("OnLeave", function() seg.Refresh() end)
        b:Hide()
        seg.buttons[i] = b
    end
    function seg.Refresh()
        local cur = seg.Current()
        for _, b in ipairs(seg.buttons) do
            local on = (b.opt.key == cur)
            b:SetEtch(on and STYLE.rowSel or STYLE.button)
            local c = b.opt.color or (on and C.TITLE or C.INK2)
            b.text:SetTextColor(c[1], c[2], c[3])
            b.text:SetAlpha((on or not b.opt.color) and 1 or 0.7)
            if b.crest then b.crest:SetDesaturated(not on); b.crest:SetAlpha(on and 1 or 0.6) end
        end
    end
    FGT.factionSeg = seg
end

-- Search box, top right of the Library header. Filters as you type by
-- goal name, short name and category, within the selected chip.
do
    local box = CreateFrame("EditBox", nil, libraryPanel, "BackdropTemplate")
    box:SetSize(190, 22)
    box:SetPoint("TOPRIGHT", libraryPanel, "TOPRIGHT", -14, -9)
    Skin(box, { 0, 0, 0, 0.6 }, C.BOX_RING)
    box:SetAutoFocus(false)
    box:SetFont(FONT, 11, "")
    box:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
    box:SetTextInsets(22, 20, 0, 0)
    box:SetMaxLetters(40)

    local glass = box:CreateTexture(nil, "OVERLAY")
    glass:SetTexture(FGT.Icon("search-white")) -- tinted like the hint text
    glass:SetSize(13, 13)
    glass:SetPoint("LEFT", 6, -1)
    glass:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])

    local hint = NewFontString(box, 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    hint:SetPoint("LEFT", 22, 0)
    hint:SetText("Search goals")

    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(16, 16)
    clear:SetPoint("RIGHT", -4, 0)
    -- grey X, tinted like the hint text; white on hover
    clear.icon = clear:CreateTexture(nil, "ARTWORK")
    clear.icon:SetSize(10, 10)
    clear.icon:SetPoint("CENTER", 0, 0)
    clear.icon:SetTexture(FGT.Icon("close-white"))
    clear.icon:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    clear:SetScript("OnEnter", function(self) self.icon:SetVertexColor(1, 1, 1) end)
    clear:SetScript("OnLeave", function(self) self.icon:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3]) end)
    clear:SetScript("OnClick", function() box:SetText(""); box:ClearFocus() end)
    clear:Hide()

    box:SetScript("OnTextChanged", function(self)
        local q = (self:GetText() or ""):lower():match("^%s*(.-)%s*$")
        FGT.libSearch = q
        hint:SetShown(q == "" and not self:HasFocus())
        clear:SetShown(q ~= "")
        libScroll.scroll:SetVerticalScroll(0)
        LayoutLibrary()
    end)
    box:SetScript("OnEditFocusGained", function(self) hint:Hide(); self:SetBackdropBorderColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 1) end)
    box:SetScript("OnEditFocusLost", function(self)
        hint:SetShown((self:GetText() or "") == "")
        self:SetBackdropBorderColor(C.BOX_RING[1], C.BOX_RING[2], C.BOX_RING[3], 1)
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    FGT.libSearch = ""
    FGT.searchBox = box
end

-- Search and faction rules, applied on top of the chip filter.
function FGT.LibraryVisible(goal)
    if goal.libraryChild then return false end
    -- Forever-only goals can't be earned on Classic Era.
    if goal.forever == "new" and not FGT.isForever then return false end
    if goal.needs == "stats" and not FGT.HasStats() then return false end -- no Statistics window
    if goal.needs == "forever" and not FGT.isForever then return false end -- Forever-only items
    if goal.faction and not IsActive(goal) and libFilter ~= "all" then
        -- All shows everything; filters with faction goals (PvP,
        -- Reputation, Attunements) follow the Alliance / Horde / Both picker
        local want = FGT.factionSeg.Current()
        if want ~= "Both" and goal.faction ~= want then return false end
    end
    local q = FGT.libSearch
    if q and q ~= "" then
        local hay = (goal.name .. " " .. (goal.short or "") .. " " .. (goal.category or "") .. " " .. (goal.faction or "")):lower()
        for _, child in ipairs(goal.armorChildren or {}) do hay = hay .. " " .. child.name:lower() end
        if not hay:find(q, 1, true) then return false end
    end
    return true
end

local function CurrentFilter()
    for _, f in ipairs(FILTERS) do if f.key == libFilter then return f end end
    return FILTERS[1]
end

local function FilterMatches(f, goal)
    if f.key == "all" then return true end
    if f.key == "added" then return IsActive(goal) end
    if f.key == "new" then return FGT.HasForeverNew(goal) end
    if f.faction then return goal.faction == f.key end
    if f.match then return goal.category:find(f.match) ~= nil end
    return goal.category == f.key
end

-- One card per goal in the catalog: icon, name, category / difficulty /
-- time, a progress bar, and an Add / Remove button on the right.
local CARD_H = 64
local libCards = {}
FGT.libCards = libCards -- for FGT.ApplyTargets (outside this block)

local libExpanded = {}

-- Sets the Library view from outside (demo mode): a filter chip and,
-- optionally, one group goal with its parts list open.
function FGT.SetLibraryView(filterKey, expandId)
    libFilter = filterKey or "all"
    for k in pairs(libExpanded) do libExpanded[k] = nil end
    if expandId then libExpanded[expandId] = true end
    libScroll.scroll:SetVerticalScroll(0)
end

local function AfterSelectionChange(goal, nowActive)
    LayoutGoalList()
    if nowActive and not selectedId then
        SelectGoal(goal.id)
    elseif not nowActive and selectedId == goal.id then
        SelectGoal(nil)
    elseif selectedId then
        SelectGoal(selectedId, true)
    end
    RefreshOverall()
    LayoutLibrary()
end

local function SetPartActive(goal, key, on)
    if goal.armorChildren then
        local child = FGT.SetArmorPartActive(goal, key, on)
        AfterSelectionChange(child, on)
        return
    end
    local sel = ForeverGoalTrackerDB.activeParts[goal.id] or {}
    ForeverGoalTrackerDB.activeParts[goal.id] = sel
    sel[key] = on or nil
    AfterSelectionChange(goal, IsActive(goal))
end

local function SetGoalActive(goal, on)
    if goal.armorChildren then
        local first
        for _, part in ipairs(FGT.GroupParts(goal)) do
            local child = FGT.SetArmorPartActive(goal, part.key, on)
            first = first or child
        end
        AfterSelectionChange(first, on)
        return
    end
    if goal.group then
        local sel = {}
        if on then
            for _, part in ipairs(FGT.GroupParts(goal)) do sel[part.key] = true end
        end
        ForeverGoalTrackerDB.activeParts[goal.id] = sel
        AfterSelectionChange(goal, on)
        return
    end
    ForeverGoalTrackerDB.active[goal.id] = on or nil
    LayoutGoalList()
    if on and not selectedId then
        SelectGoal(goal.id)
    elseif not on and selectedId == goal.id then
        SelectGoal(nil)
    elseif selectedId then
        SelectGoal(selectedId, true)
    end
    RefreshOverall()
    LayoutLibrary()
end

-- ============================================================
-- Right-click menu on a My Goals card: favorite / unfavorite the goal,
-- or remove it from the tracker (its progress is kept). Styled like the
-- sort menu; any click outside closes it.
-- ============================================================
function FGT.CloseGoalMenu()
    local M = FGT.goalMenu
    if M then
        M:Hide()
        M.catcher:Hide()
    end
end

function FGT.OpenGoalMenu(card)
    local M = FGT.goalMenu
    if not M then
        M = CreateFrame("Frame", nil, main, "BackdropTemplate")
        M:SetFrameLevel(main:GetFrameLevel() + 60)
        M:SetClampedToScreen(true)
        M:SetWidth(180)
        Etch(M, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
        M:EnableMouse(true)
        M.catcher = CreateFrame("Button", nil, main)
        M.catcher:SetAllPoints(main)
        M.catcher:SetFrameLevel(main:GetFrameLevel() + 55)
        M.catcher:RegisterForClicks("AnyUp")
        M.catcher:SetScript("OnClick", FGT.CloseGoalMenu)
        M.rows = {}
        for i = 1, 3 do
            local row = CreateFrame("Button", nil, M)
            row:SetHeight(MENU_ROW)
            row.hl = row:CreateTexture(nil, "BACKGROUND")
            row.hl:SetTexture(SOLID)
            row.hl:SetAllPoints(row)
            ApplyHGradient(row.hl, C.ACCENT, C.ACCENT, 0.18, 0.02)
            row.hl:Hide()
            row.icon = row:CreateTexture(nil, "ARTWORK") -- Karl's UI icons
            row.icon:SetSize(13, 13)
            row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
            row.label = NewFontString(row, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
            row.label:SetPoint("LEFT", row, "LEFT", 27, 0)
            row:SetScript("OnEnter", function(self) self.hl:Show() end)
            row:SetScript("OnLeave", function(self) self.hl:Hide() end)
            M.rows[i] = row
        end
        -- 1: favorite toggle
        M.rows[1]:SetScript("OnClick", function()
            local id = M.goal.id
            local favs = ForeverGoalTrackerDB.favorites
            favs[id] = (not favs[id]) or nil
            FGT.CloseGoalMenu()
            LayoutGoalList()
            RefreshGoalList()
        end)
        -- 2: remove from My Goals
        M.rows[2].label:SetText("Remove from My Goals")
        M.rows[2].icon:SetTexture(FGT.Icon("trash"))
        M.rows[1].icon:SetTexture(FGT.Icon("star"))
        M.rows[3].icon:SetTexture(FGT.Icon("pencil"))
        M.rows[2].label:SetTextColor(1.00, 0.50, 0.42)
        M.rows[2]:SetScript("OnClick", function()
            local goal = M.goal
            FGT.CloseGoalMenu()
            ForeverGoalTrackerDB.favorites[goal.id] = nil
            SetGoalActive(goal, false)
        end)
        -- 3: edit goal: change its target (goals built on one number, like gold)
        M.rows[3].label:SetText("Edit goal")
        M.rows[3]:SetScript("OnClick", function()
            local goal = M.goal
            FGT.CloseGoalMenu()
            if FGT.OpenTargetCard then FGT.OpenTargetCard(goal) end
        end)
        -- new frames start shown
        M:Hide()
        M.catcher:Hide()
        FGT.goalMenu = M
    end

    M.goal = card.goal
    local fav = ForeverGoalTrackerDB.favorites[card.goal.id]
    M.rows[1].label:SetText(fav and "Remove from favorites" or "Add to favorites")
    -- favorite, edit goal (when the goal has a target), remove last
    local order = { M.rows[1] }
    if card.goal.target then table.insert(order, M.rows[3]) end
    table.insert(order, M.rows[2])
    M.rows[3]:SetShown(card.goal.target ~= nil)
    for i, row in ipairs(order) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", M, "TOPLEFT", 4, -4 - (i - 1) * MENU_ROW)
        row:SetPoint("TOPRIGHT", M, "TOPRIGHT", -4, -4 - (i - 1) * MENU_ROW)
    end
    M:SetHeight(#order * MENU_ROW + 8)

    -- open at the cursor
    local x, y = GetCursorPosition()
    local scale = M:GetEffectiveScale()
    M:ClearAllPoints()
    M:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    M:Show()
    M.catcher:Show()
end

-- ============================================================
-- Goal link card: clicking a goal link in a step or tip opens a small
-- card for that goal (icon, name, what it is) with "+ Add to My Goals",
-- or "Open goal" once it's on your tracker. Clicking anywhere else
-- closes it, like the right-click menu.
-- ============================================================
function FGT.CloseLinkCard()
    local L = FGT.linkCard
    if L then L:Hide(); L.catcher:Hide() end
end

function FGT.OpenLinkCard(id)
    local goal = FGT.GoalById(id)
    if not goal then return end
    local L = FGT.linkCard
    if not L then
        L = CreateFrame("Frame", nil, main, "BackdropTemplate")
        L:SetFrameLevel(main:GetFrameLevel() + 60)
        L:SetClampedToScreen(true)
        L:SetWidth(270)
        Etch(L, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
        L:EnableMouse(true)
        L.catcher = CreateFrame("Button", nil, main)
        L.catcher:SetAllPoints(main)
        L.catcher:SetFrameLevel(main:GetFrameLevel() + 55)
        L.catcher:RegisterForClicks("AnyUp")
        L.catcher:SetScript("OnClick", FGT.CloseLinkCard)

        L.icon = NewIcon(L, 36)
        L.icon:SetPoint("TOPLEFT", 12, -12)
        L.tag = NewFontString(L, 9, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
        L.tag:SetPoint("TOPLEFT", L.icon, "TOPRIGHT", 10, -1)
        L.name = NewTitleString(L, 13)
        L.name:SetPoint("TOPLEFT", L.tag, "BOTTOMLEFT", 0, -3)
        L.name:SetPoint("RIGHT", L, "RIGHT", -12, 0)
        L.name:SetJustifyH("LEFT")
        L.name:SetWordWrap(true)
        L.note = NewFontString(L, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
        L.note:SetJustifyH("LEFT")
        L.note:SetWordWrap(true)
        L.note:SetWidth(270 - 24)

        L.btn = CreateFrame("Button", nil, L, "BackdropTemplate")
        L.btn:SetSize(150, 24)
        Etch(L.btn, STYLE.button, 10)
        L.btn.text = NewFontString(L.btn, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
        L.btn.text:SetPoint("CENTER")
        -- gold like "Find your next goal" while it adds; plain for Open goal
        function L.btn:Style(hover)
            if self.gold then
                self:SetEtch(STYLE.rowSel)
                local c = hover and { 1, 1, 1 } or C.TITLE
                self.text:SetTextColor(c[1], c[2], c[3])
            else
                self:SetEtch(hover and STYLE.btnHover or STYLE.button)
                self.text:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
            end
        end
        L.btn:SetScript("OnEnter", function(self) self:Style(true) end)
        L.btn:SetScript("OnLeave", function(self) self:Style(false) end)
        L.btn:SetScript("OnClick", function()
            local g = L.goal
            if IsActive(g) then
                -- already tracked: take you to it
                FGT.CloseLinkCard()
                if FGT.ShowTab then FGT.ShowTab("tracker") end
                SelectGoal(g.id)
            else
                -- done: close the card, the chat line confirms it
                FGT.CloseLinkCard()
                GameTooltip:Hide()
                SetGoalActive(g, true)
                print(TAG .. g.name .. " added to My Goals.")
            end
        end)
        -- a slow shine around the card, and the "Help me get started" gold
        -- comet on Add while the goal isn't on your list (Karl)
        FGT.AddBorderComet(L, 2, 0.4, 9)
        FGT.AddBorderComet(L.btn, 2, 0.9, 6) -- its own slow lap: copying the big button's speed raced on this small one
        L.btn.comet.width = 1 -- a thinner line on this small button (Karl)
        -- new frames start shown: hide them so the first open is placed
        -- at the cursor below (it took three clicks to open before)
        L:Hide()
        L.catcher:Hide()
        FGT.linkCard = L
    end

    L.goal = goal
    local catColor = FGT.categoryColors[goal.category] or C.ACCENT
    L.icon:SetIcon(goal.icon, catColor)
    L.tag:SetText(string.upper(goal.category)
        .. (goal.faction and ("  \194\183  " .. string.upper(goal.faction) .. " ONLY") or ""))
    L.tag:SetTextColor(catColor[1], catColor[2], catColor[3])
    L.name:SetText(goal.name)
    L.nameShown = nil -- (the gradient ticker repaints it)
    L.note:ClearAllPoints()
    L.note:SetPoint("TOPLEFT", L, "TOPLEFT", 12, -12 - math.max(36, 16 + L.name:GetStringHeight()) - 10)
    L.note:SetText(goal.note or "")
    local active = IsActive(goal)
    L.btn.text:SetText(active and "Open goal" or "+ Add to My Goals")
    L.btn.comet.on = not active
    L.btn.comet.vis = active and 0 or 1 -- no fade on open
    L.btn.gold = not active
    L.btn:Style(L.btn:IsMouseOver())
    L.btn:ClearAllPoints()
    L.btn:SetPoint("TOPLEFT", L.note, "BOTTOMLEFT", 0, -12)
    L:SetHeight(12 + math.max(36, 16 + L.name:GetStringHeight()) + 10 + L.note:GetStringHeight() + 12 + 24 + 12)

    -- open at the cursor (first time) and stay put while it updates
    if not L:IsShown() then
        local x, y = GetCursorPosition()
        local scale = L:GetEffectiveScale()
        L:ClearAllPoints()
        L:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)
    end
    L:Show()
    L.catcher:Show()
end

-- Label alone: dead center. Label + checkmark: center the pair, i.e.
-- shift the label right by half the checkmark's width (12px + 4px gap).
local function CenterCardLabel(card)
    card.btnText:ClearAllPoints()
    card.btnText:SetPoint("CENTER", card.btn, "CENTER", card.btnCheck:IsShown() and 8 or 0, 0)
end

local function StyleCardButtonInner(card)
    local goal = card.goal
    local hover = card.btn:IsMouseOver()
    local on = IsActive(goal)
    if goal.group then
        local n, total = FGT.SelectedPartCount(goal), #FGT.GroupParts(goal)
        on = (n == total)
        if n > 0 and n < total then
            card.btn:SetEtch(hover and STYLE.btnHover or STYLE.button)
            card.btnText:SetText("+ Add rest")
            card.btnText:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
            card.btnCheck:Hide()
            return
        end
    end
    -- a tracked goal that's finished says Complete, in green
    local d, t = GoalProgress(goal)
    local done = on and t > 0 and d >= t
    -- gold check; the grey one tinted green once it's done
    card.btnCheck:SetTexture(FGT.Icon(done and "check-white" or "check"))
    if done then
        card.btnCheck:SetVertexColor(C.DONE[1], C.DONE[2], C.DONE[3])
    else
        card.btnCheck:SetVertexColor(1, 1, 1)
    end
    if done and not hover then
        card.btn:SetEtch(STYLE.done)
        card.btnText:SetText("Complete")
        card.btnText:SetTextColor(0.62, 0.95, 0.50)
        card.btnCheck:Show()
    elseif on then
        card.btn:SetEtch(hover and STYLE.dangerHv or STYLE.rowSel)
        card.btnText:SetText(hover and (goal.group and "Remove all" or "Remove") or "Added")
        card.btnText:SetTextColor(1, hover and 0.8 or 0.85, hover and 0.8 or 0.3)
        card.btnCheck:SetShown(not hover)
    else
        card.btn:SetEtch(hover and STYLE.btnHover or STYLE.button)
        card.btnText:SetText(goal.group and "+ Add all" or "+ Add")
        card.btnText:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
        card.btnCheck:Hide()
    end
end

local function StyleCardButton(card)
    StyleCardButtonInner(card)
    CenterCardLabel(card)
end

local function GetCard(goal)
    local card = libCards[goal.id]
    if card then return card end
    card = CreateFrame("Frame", nil, libScroll.content, "BackdropTemplate")
    card:SetHeight(CARD_H)
    Etch(card, STYLE.row, 12)
    card.goal = goal

    local catColor = FGT.categoryColors[goal.category] or C.ACCENT
    card.icon = NewIcon(card, 42)
    card.icon:SetPoint("LEFT", card, "LEFT", 10, 0)
    card.icon:SetIcon(goal.icon, catColor)
    card.baseRim = catColor -- finished cards swap it for grey

    card.btn = CreateFrame("Button", nil, card, "BackdropTemplate")
    card.btn:SetSize(92, 26)
    card.btn:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    Etch(card.btn, STYLE.button, 10)
    card.btnText = NewFontString(card.btn, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    card.btnText:SetPoint("CENTER", 0, 0)
    card.btnText:SetJustifyH("CENTER")
    card.btnCheck = card.btn:CreateTexture(nil, "OVERLAY")
    card.btnCheck:SetTexture(FGT.Icon("check"))
    card.btnCheck:SetSize(12, 12)
    card.btnCheck:SetPoint("RIGHT", card.btnText, "LEFT", -4, 0) -- room between check and word (Karl)
    card.btn:SetScript("OnEnter", function() StyleCardButton(card) end)
    card.btn:SetScript("OnLeave", function() StyleCardButton(card) end)
    card.btn:SetScript("OnClick", function()
        if goal.group then
            local all = FGT.SelectedPartCount(goal) == #FGT.GroupParts(goal)
            SetGoalActive(goal, not all)
        else
            SetGoalActive(goal, not IsActive(goal))
        end
    end)

    -- Group goals: a "Choose" toggle opens the list of parts below.
    if goal.group then
        card.pick = CreateFrame("Button", nil, card, "BackdropTemplate")
        card.pick:SetSize(78, 26)
        card.pick:SetPoint("RIGHT", card.btn, "LEFT", -6, 0)
        Etch(card.pick, STYLE.button, 10)
        card.pickText = NewFontString(card.pick, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
        card.pickText:SetPoint("CENTER", 0, 0)
        card.pickText:SetJustifyH("CENTER")
        card.pick:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
        card.pick:SetScript("OnLeave", function(self)
            self:SetEtch(libExpanded[goal.id] and STYLE.rowSel or STYLE.button)
        end)
        card.pick:SetScript("OnClick", function()
            libExpanded[goal.id] = not libExpanded[goal.id]
            LayoutLibrary()
        end)
        card.subs = {}
    end

    card.name = NewFontString(card, 13, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, -1)
    card.name:SetPoint("RIGHT", card.pick or card.btn, "LEFT", -10, 0)
    card.name:SetWordWrap(false)
    card.name:SetText(goal.name)
    card.name:SetShadowColor(0, 0, 0, 1)
    card.name:SetShadowOffset(1, -1)

    local diffColor = FGT.difficultyColors[goal.difficulty] or C.SUBTEXT
    card.meta = NewFontString(card, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    card.meta:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
    card.meta:SetPoint("RIGHT", card.pick or card.btn, "LEFT", -10, 0)
    card.meta:SetWordWrap(false)
    card.metaBase = string.format("|cff%s%s|r  ·  |cff%s%s|r  ·  %s",
        HexColor(catColor), string.upper(goal.category),
        HexColor(diffColor), string.upper(goal.difficulty or ""), goal.timeEstimate or "")
    if goal.faction then
        local fc = goal.faction == "Alliance" and "4d8cff" or "e8483c"
        card.metaBase = string.format("|cff%s%s|r  ·  ", fc, string.upper(goal.faction)) .. card.metaBase
    end
    card.metaPlain = card.metaBase
    card.meta:SetText(card.metaBase)

    card.bar = NewBar(card, 4)
    card.bar:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 10, 1)
    card.bar:SetPoint("RIGHT", card.pick or card.btn, "LEFT", -10, 0)
    card.bar.label:Hide()
    -- finished goals: green wash like the My Goals cards (shown in LayoutLibrary)
    FGT.AddCelebrationFX(card, 3, 56)

    -- hover the card for the full description
    card:EnableMouse(true)
    card:SetScript("OnEnter", function(self)
        self:SetEtch(STYLE.rowHover)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(goal.name, C.TITLE[1], C.TITLE[2], C.TITLE[3])
        if goal.note then GameTooltip:AddLine(goal.note, 0.9, 0.9, 0.9, true) end
        local fnote = FGT.ForeverNote(goal, true)
        if fnote then GameTooltip:AddLine(fnote, C.FOREVER[1], C.FOREVER[2], C.FOREVER[3], true) end
        local d, t = GoalProgress(goal)
        GameTooltip:AddLine(string.format("%d of %d steps done", d, t), C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function(self)
        self:SetEtch(self.restStyle or STYLE.row) -- grey again on finished cards
        GameTooltip:Hide()
    end)

    libCards[goal.id] = card
    return card
end

-- Progress of a single part (for the little bar under each part, and
-- the Complete button). Above StyleSubButton, its first user.
local function PartProgress(goal, key)
    if goal.sections then
        return SectionProgress(goal, key, goal.sections[key])
    end
    local entry = goal.steps[key]
    if IsAutoStep(entry) then
        return math.floor(AutoStepFraction(entry) * 100), 100
    end
    return IsStepDone(goal.id, key) and 1 or 0, 1
end

-- One row per part of a group goal, shown under its card when expanded.
local SUB_H = 32
local function StyleSubButton(sub)
    local on = FGT.PartSelected(sub.goal, sub.key)
    local hover = sub.btn:IsMouseOver()
    local d, t = PartProgress(sub.goal, sub.key)
    if on and t > 0 and d >= t and not hover then
        -- finished part: Complete in green (hover still offers Remove)
        sub.btn:SetEtch(STYLE.done)
        sub.btnText:SetText("Complete")
        sub.btnText:SetTextColor(0.62, 0.95, 0.50)
    elseif on then
        sub.btn:SetEtch(hover and STYLE.dangerHv or STYLE.rowSel)
        sub.btnText:SetText(hover and "Remove" or "Added")
        sub.btnText:SetTextColor(1, hover and 0.8 or 0.85, hover and 0.8 or 0.3)
    else
        sub.btn:SetEtch(hover and STYLE.btnHover or STYLE.button)
        sub.btnText:SetText("+ Add")
        sub.btnText:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
    end
end

local function GetSub(card, index, part)
    local sub = card.subs[index]
    if not sub then
        sub = CreateFrame("Frame", nil, libScroll.content, "BackdropTemplate")
        sub:SetHeight(SUB_H)
        Etch(sub, STYLE.panel, 10)
        sub.icon = NewIcon(sub, 20)
        sub.icon:SetPoint("LEFT", sub, "LEFT", 10, 0)
        sub.label = NewFontString(sub, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
        sub.label:SetPoint("LEFT", sub.icon, "RIGHT", 8, 0)
        sub.btn = CreateFrame("Button", nil, sub, "BackdropTemplate")
        sub.btn:SetSize(78, 22)
        sub.btn:SetPoint("RIGHT", sub, "RIGHT", -8, 0)
        Etch(sub.btn, STYLE.button, 8)
        sub.btnText = NewFontString(sub.btn, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
        sub.btnText:SetPoint("CENTER", 0, 0)
        sub.btnText:SetJustifyH("CENTER")
        sub.btn:SetScript("OnEnter", function() StyleSubButton(sub) end)
        sub.btn:SetScript("OnLeave", function() StyleSubButton(sub) end)
        sub.btn:SetScript("OnClick", function()
            SetPartActive(sub.goal, sub.key, not FGT.PartSelected(sub.goal, sub.key))
        end)
        sub.bar = NewBar(sub, 3)
        sub.bar:SetPoint("BOTTOMLEFT", sub.icon, "BOTTOMRIGHT", 8, -3)
        sub.bar:SetPoint("RIGHT", sub.btn, "LEFT", -10, 0)
        sub.bar.label:Hide()
        -- Finished parts: the same quiet look as finished group rows on
        -- the goal page (green wash, green check, grey icon, no bar).
        FGT.AddCelebrationFX(sub, 3, 26)
        sub.doneCheck = sub:CreateTexture(nil, "OVERLAY")
        sub.doneCheck:SetTexture(FGT.Icon("check-white"))
        sub.doneCheck:SetSize(13, 13)
        sub.doneCheck:SetPoint("LEFT", sub.label, "RIGHT", 6, 1)
        sub.doneCheck:SetDesaturated(true)
        sub.doneCheck:SetVertexColor(C.DONE[1], C.DONE[2], C.DONE[3])
        sub.doneCheck:Hide()
        card.subs[index] = sub
    end
    sub.goal, sub.key = card.goal, part.key
    local partNew = FGT.ApplyPartLook(sub, part, card.goal)
    sub.label:SetText(partNew and (part.label .. "   " .. FGT.NewTag(partNew)) or part.label)
    sub:SetEtch(STYLE.panel) -- blue twin when the part is new
    sub.icon:SetIcon(part.icon or card.goal.icon, sub.foreverNew and C.FOREVER or C.GOLD2)
    StyleSubButton(sub)
    return sub
end

LayoutLibrary = function()
    -- filter chips: flow left to right, wrapping to a new line as needed
    local maxW = math.max(200, libraryPanel:GetWidth() - 28)
    local x, y = 0, 0
    for _, chip in ipairs(filterChips) do
        local w = chip:GetWidth()
        if x > 0 and x + w > maxW then x = 0; y = y - 24 end
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", libraryPanel, "TOPLEFT", 14 + x, -40 + y)
        x = x + w + 5
        local on = (libFilter == chip.filter.key)
        chip:SetEtch(on and STYLE.rowSel or STYLE.button)
        if chip.filter.forever then
            local c = on and { 1, 1, 1 } or C.FOREVER_LIGHT
            chip.text:SetTextColor(c[1], c[2], c[3])
        elseif on then chip.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3])
        else chip.text:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3]) end
    end
    -- The faction picker gets its own row under the chips, on any filter
    -- that holds faction goals (PvP, Reputation, Attunements). Not on All,
    -- which shows both, or Added, which shows what you track.
    local seg = FGT.factionSeg
    local showSeg = false
    if libFilter ~= "all" and libFilter ~= "added" then
        for _, g in ipairs(FGT.goals) do
            if g.faction and FilterMatches(CurrentFilter(), g) then showSeg = true break end
        end
    end
    if showSeg then
        y = y - 28
        local sx = 0
        for _, b in ipairs(seg.buttons) do
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", libraryPanel, "TOPLEFT", 14 + sx, -40 + y)
            sx = sx + b:GetWidth() + 4
        end
        seg.Refresh()
    end
    for _, b in ipairs(seg.buttons) do b:SetShown(showSeg) end
    libScroll.scroll:ClearAllPoints()
    libScroll.scroll:SetPoint("TOPLEFT", libraryPanel, "TOPLEFT", 10, -40 + y - 30)
    libScroll.scroll:SetPoint("BOTTOMRIGHT", libraryPanel, "BOTTOMRIGHT", -18, 10)
    libScroll.content:SetWidth(libScroll.scroll:GetWidth())

    -- cards: active goals first within the filter, then alphabetical
    local list = {}
    for _, g in ipairs(FGT.goals) do
        local card = libCards[g.id]
        if card then
            card:Hide()
            for _, sub in ipairs(card.subs or {}) do sub:Hide() end
        end
        if FilterMatches(CurrentFilter(), g) and FGT.LibraryVisible(g) then
            table.insert(list, g)
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    local cy = 0
    for _, g in ipairs(list) do
        local card = GetCard(g)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", libScroll.content, "TOPLEFT", 4, -cy)
        card:SetPoint("RIGHT", libScroll.content, "RIGHT", -4, 0)
        -- Forever-only goals: blue wash and rim, NEW at the front of the meta line.
        local isNew = FGT.ApplyForeverLook(card, g)
        card:SetEtch(STYLE.row)
        card.restStyle = STYLE.row
        card.metaBase = isNew and (FGT.NewTag(isNew) .. "  ·  " .. card.metaPlain) or card.metaPlain
        -- Finished goals: the quiet finished look (green wash, grey icon,
        -- softer name, no bar) and the completion date on the info line.
        local gd, gt = GoalProgress(g)
        local finished = IsActive(g) and gt > 0 and gd >= gt
        if finished then
            -- the whole card goes grey (Karl): no blue, grey border, grey
            -- icon and frame, one grey info line without its colors or the
            -- NEW dot; the green wash and the green Complete button stay
            local on = FGT.CompletedOn(g)
            local plain = card.metaPlain:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            card.metaBase = (isNew and FGT.ForeverDot(14, true) or "") .. "|cff7d7d78" .. (isNew and (isNew .. "  ·  ") or "") .. plain
                .. "  ·  " .. (on and ("Completed " .. on) or "Complete") .. "|r"
            card.foreverNew = false
            card:SetEtch(STYLE.doneCard)
            card.restStyle = STYLE.doneCard
        end
        card.icon:SetIcon(g.icon, finished and { 0.40, 0.40, 0.39 } or card.baseRim)
        card.doneGlow:SetShown(finished)
        card.icon.tex:SetDesaturated(finished)
        card.icon.tex:SetAlpha(finished and 0.6 or 1)
        local nc = finished and C.SUBTEXT or C.TEXT
        card.name:SetTextColor(nc[1], nc[2], nc[3])
        card.meta:SetText(card.metaBase)
        local d, t = GoalProgress(g)
        card.bar:SetProgress(d, t)
        -- only goals on the tracker can make progress, so only they get a
        -- bar; a finished goal shows its date instead
        card.bar:SetShown(IsActive(g) and not finished)
        StyleCardButton(card)
        card:Show()
        cy = cy + CARD_H + 6

        if g.group then
            local parts = FGT.GroupParts(g)
            local n = FGT.SelectedPartCount(g)
            card.meta:SetText(card.metaBase .. string.format("  ·  |cffffd75e%d of %d chosen|r", n, #parts))
            local open = libExpanded[g.id]
            card.pickText:SetText(open and "Hide" or "Choose")
            card.pick:SetEtch(open and STYLE.rowSel or STYLE.button)
            if open then
                for i, part in ipairs(parts) do
                    local sub = GetSub(card, i, part)
                    sub:ClearAllPoints()
                    sub:SetPoint("TOPLEFT", libScroll.content, "TOPLEFT", 40, -cy)
                    sub:SetPoint("RIGHT", libScroll.content, "RIGHT", -4, 0)
                    local pd, pt = PartProgress(g, part.key)
                    local chosen = FGT.PartSelected(g, part.key)
                    local finished = chosen and pt > 0 and pd >= pt
                    sub.bar:SetProgress(pd, pt)
                    sub.bar:SetShown(chosen and not finished)
                    sub.doneGlow:SetShown(finished)
                    sub.doneCheck:SetShown(finished)
                    sub.icon.tex:SetDesaturated(finished)
                    sub.icon.tex:SetAlpha(finished and 0.6 or 1)
                    local lc = finished and C.SUBTEXT or C.TEXT
                    sub.label:SetTextColor(lc[1], lc[2], lc[3])
                    sub:Show()
                    cy = cy + SUB_H + 3
                end
                cy = cy + 6
            end
        end
    end
    libScroll.content:SetHeight(math.max(1, cy))
    libScroll:Update()

    -- nothing matched the search / chip
    if not FGT.libNoMatch then
        FGT.libNoMatch = NewFontString(libraryPanel, 12, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        FGT.libNoMatch:SetJustifyH("CENTER")
    end
    FGT.libNoMatch:ClearAllPoints()
    FGT.libNoMatch:SetPoint("TOP", libScroll.scroll, "TOP", 0, -40)
    FGT.libNoMatch:SetText((FGT.libSearch ~= "") and ("No goals match \"" .. FGT.searchBox:GetText() .. "\".") or "No goals here yet.")
    FGT.libNoMatch:SetShown(#list == 0)

    libSummary:SetText(string.format("%d of %d goals on your tracker", #ActiveGoals(), FGT.CatalogGoalCount()))
end
libScroll:Finalize()
FGT.LayoutLibrary = LayoutLibrary

local function ShowTab(which)
    FGT.CloseNoteCard(true)
    ForeverGoalTrackerDB.tab = which
    if FGT.CloseSettings then FGT.CloseSettings() end -- a tab click leaves Settings
    local lib = (which == "library")
    trackerTab:SetActive(not lib)
    libraryTab:SetActive(lib)
    listPanel:SetShown(not lib)
    detailPanel:SetShown(not lib)
    libraryPanel:SetShown(lib)
    if lib then
        LayoutLibrary()
    else
        LayoutGoalList()
        SelectGoal(selectedId or ForeverGoalTrackerDB.selected, true)
    end
end
FGT.ShowTab = ShowTab
-- for the Settings page (built in its own block below)
FGT.trackerTab, FGT.libraryTab, FGT.libraryPanel = trackerTab, libraryTab, libraryPanel
trackerTab:SetScript("OnClick", function() ShowTab("tracker") end)
libraryTab:SetScript("OnClick", function() ShowTab("library") end)
libraryPanel:SetScript("OnSizeChanged", function() if libraryPanel:IsShown() then LayoutLibrary() end end)

end

do -- scoped (200-local budget)
-- ============================================================
-- Settings page
-- ============================================================
-- Opened from the gear in the title bar. It takes the place of the tab
-- content inside the main window, so it always matches the window's
-- size, and scrolls like the step list. The page is built from
-- FGT.SETTINGS (groups of rows); adding an option is one row there plus
-- its default in FGT.SETTING_DEFAULTS. Groups flow into two columns
-- (whichever is shorter), or one column on a narrow window.
local S = { built = false, groups = {}, controls = {} }

local panel = CreateFrame("Frame", nil, main, "BackdropTemplate")
panel:SetPoint("TOPLEFT", main, "TOPLEFT", 16, PANEL_TOP)
panel:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -16, 16)
Etch(panel, STYLE.panel, 12)
FGT.AddGrime(panel, 0.18, 12, 0.53, 0, 140)
panel:Hide()
FGT.settingsPanel = panel

S.header = NewTitleString(panel, 14)
S.header:SetPoint("TOPLEFT", 14, -12)
S.header:SetText("Settings")
S.sub = NewFontString(panel, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
S.sub:SetPoint("LEFT", S.header, "RIGHT", 10, -1)
do
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = getMeta and getMeta(ADDON, "Version")
    S.sub:SetText((version and ("Version " .. version .. "  ·  ") or "") .. "Changes apply right away")
end

S.scroll = CreateScrollArea(panel)
S.scroll.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -40)
S.scroll.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 10)
S.scroll:Finalize()

-- ------------------------------------------------------------
-- Building blocks. Every row is a frame with :Layout(width) that
-- returns its height; controls sit at the row's top right.
-- ------------------------------------------------------------
local function NewRow(parent, label, desc)
    local r = CreateFrame("Frame", nil, parent)
    r.label = NewFontString(r, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    r.label:SetPoint("TOPLEFT", 0, -9)
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(true)
    r.label:SetText(label or "")
    if desc then
        r.desc = NewFontString(r, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        r.desc:SetPoint("TOPLEFT", r.label, "BOTTOMLEFT", 0, -3)
        r.desc:SetJustifyH("LEFT")
        r.desc:SetWordWrap(true)
        r.desc:SetText(desc)
    end
    -- hairline between rows (hidden on a group's first row)
    r.line = r:CreateTexture(nil, "BACKGROUND")
    r.line:SetTexture(SOLID)
    r.line:SetHeight(1)
    r.line:SetPoint("TOPLEFT")
    r.line:SetPoint("TOPRIGHT")
    r.line:SetVertexColor(1, 0.92, 0.7, 0.07)
    function r:Layout(w)
        local ctl = self.control
        local cw = ctl and (ctl:GetWidth() + 14) or 0
        -- A wide control (a long row of choices) would squeeze the text,
        -- so it moves under the label instead of beside it.
        local stacked = ctl and (w - cw) < 150
        local tw = stacked and w or math.max(60, w - cw)
        self.label:SetWidth(tw)
        local h = self.label:GetStringHeight() or 12
        if self.desc then
            self.desc:SetWidth(tw)
            h = h + 3 + (self.desc:GetStringHeight() or 10)
        end
        if ctl then
            ctl:ClearAllPoints()
            if stacked then
                ctl:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(9 + h + 8))
                h = h + 8 + ctl:GetHeight()
            else
                ctl:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, ctl.topOffset or -8)
                h = math.max(h, ctl:GetHeight())
            end
        end
        h = h + 18
        self:SetSize(w, h)
        return h
    end
    return r
end

-- On/off switch: a pill track with a 1px rim and a vertical gradient
-- like the buttons (gold when on, dark when off), and a round knob with
-- its own top-lit gradient and a soft shadow. Shapes are Media/pill and
-- Media/knob (white, tinted here).
local PILL = "Interface\\AddOns\\" .. ADDON .. "\\Media\\pill"
local KNOB = "Interface\\AddOns\\" .. ADDON .. "\\Media\\knob"
local TOGGLE_LOOK = {
    on  = { rim = { 0.85, 0.68, 0.20 }, top = { 0.55, 0.42, 0.10 }, bottom = { 0.22, 0.16, 0.03 },
            knobTop = { 1.00, 0.96, 0.78 }, knobBottom = { 0.92, 0.70, 0.22 } },
    off = { rim = { 0.32, 0.30, 0.26 }, top = { 0.17, 0.16, 0.15 }, bottom = { 0.05, 0.05, 0.05 },
            knobTop = { 0.66, 0.65, 0.62 }, knobBottom = { 0.36, 0.35, 0.33 } },
}
local function NewToggle(row, spec)
    local t = CreateFrame("Button", nil, row)
    t:SetSize(36, 18)
    t:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -8)
    t.rim = t:CreateTexture(nil, "BACKGROUND")
    t.rim:SetTexture(PILL)
    t.rim:SetAllPoints(t)
    t.fill = t:CreateTexture(nil, "BORDER")
    t.fill:SetTexture(PILL)
    t.fill:SetPoint("TOPLEFT", 1, -1)
    t.fill:SetPoint("BOTTOMRIGHT", -1, 1)
    t.shadow = t:CreateTexture(nil, "ARTWORK", nil, 1)
    t.shadow:SetTexture(KNOB)
    t.shadow:SetSize(14, 14)
    t.shadow:SetVertexColor(0, 0, 0, 0.55)
    t.knob = t:CreateTexture(nil, "ARTWORK", nil, 2)
    t.knob:SetTexture(KNOB)
    t.knob:SetSize(14, 14)
    function t:Refresh()
        local on = FGT.Setting(spec.key) and true or false
        local L = on and TOGGLE_LOOK.on or TOGGLE_LOOK.off
        local lift = self:IsMouseOver() and 0.12 or 0
        self.rim:SetVertexColor(math.min(1, L.rim[1] + lift), math.min(1, L.rim[2] + lift), math.min(1, L.rim[3] + lift))
        ApplyVGradient(self.fill, L.top, L.bottom)
        ApplyVGradient(self.knob, L.knobTop, L.knobBottom)
        local x = on and 20 or 2
        self.knob:ClearAllPoints()
        self.knob:SetPoint("LEFT", self, "LEFT", x, 0)
        self.shadow:ClearAllPoints()
        self.shadow:SetPoint("LEFT", self, "LEFT", x, -1)
    end
    t:SetScript("OnEnter", function(self) self:Refresh() end)
    t:SetScript("OnLeave", function(self) self:Refresh() end)
    t:SetScript("OnClick", function(self)
        FGT.SetSetting(spec.key, not FGT.Setting(spec.key))
        self:Refresh()
        if spec.apply then spec.apply(FGT.Setting(spec.key)) end
    end)
    return t
end

-- A row of small buttons, one per option; the chosen one is gold.
local function NewChoice(row, spec)
    local f = CreateFrame("Frame", nil, row)
    f:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -6)
    f.topOffset = -6
    f.buttons = {}
    local x = 0
    for i, opt in ipairs(spec.options) do
        local b = CreateFrame("Button", nil, f, "BackdropTemplate")
        Etch(b, STYLE.button, 8)
        b.text = NewFontString(b, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
        b.text:SetPoint("CENTER", 0, 0)
        b.text:SetText(opt[2])
        b:SetSize(math.ceil(b.text:GetStringWidth()) + 18, 22)
        b:SetPoint("LEFT", f, "LEFT", x, 0)
        x = x + b:GetWidth() + 3
        b.value = opt[1]
        b:SetScript("OnClick", function(self)
            if self.mutedWhy then return end -- greyed out: you wouldn't hear it
            FGT.SetSetting(spec.key, opt[1])
            f:Refresh()
            if spec.apply then spec.apply(opt[1]) end
        end)
        b:SetScript("OnEnter", function(self)
            if self.mutedWhy then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(self.mutedWhy, 1, 1, 1)
                GameTooltip:Show()
            elseif FGT.Setting(spec.key) ~= self.value then
                self:SetEtch(STYLE.btnHover)
            end
        end)
        b:SetScript("OnLeave", function() f:Refresh(); GameTooltip:Hide() end)
        f.buttons[i] = b
    end
    f:SetSize(math.max(1, x - 3), 22)
    -- spec.muted() / spec.optionMuted(value) return why you won't hear it
    -- (the game's sound settings); those buttons go grey and can't be clicked.
    function f:Refresh()
        local rowWhy = spec.muted and spec.muted()
        if spec.mutedDesc and row.desc then row.desc:SetText(rowWhy and spec.mutedDesc or spec.desc) end
        local lc = rowWhy and C.SUBTEXT or C.TEXT
        row.label:SetTextColor(lc[1], lc[2], lc[3])
        for _, b in ipairs(self.buttons) do
            local on = FGT.Setting(spec.key) == b.value
            b.mutedWhy = rowWhy or (spec.optionMuted and spec.optionMuted(b.value))
            local off = b.mutedWhy ~= nil
            if off then
                b:SetEtch(on and STYLE.mutedSel or STYLE.muted)
                local c = on and C.MUTED_SEL or C.MUTED
                b.text:SetTextColor(c[1], c[2], c[3])
            else
                b:SetEtch(on and STYLE.rowSel or STYLE.button)
                local c = on and C.TITLE or C.INK2
                b.text:SetTextColor(c[1], c[2], c[3])
            end
        end
    end
    return f
end

-- Slider in whole percent steps (stored as a fraction, 100% = 1).
-- spec.live applies while dragging (opacity); otherwise on release
-- (scale, which would move the slider under the cursor).
local function NewSlider(row, spec)
    local f = CreateFrame("Frame", nil, row)
    f:SetSize(150, 18)
    f:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -8)
    f.value = NewFontString(f, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
    f.value:SetPoint("RIGHT", 0, 0)
    f.value:SetWidth(38)
    f.value:SetJustifyH("RIGHT")
    local track = CreateFrame("Frame", nil, f, "BackdropTemplate")
    track:SetPoint("LEFT", f, "LEFT", 6, 0)
    track:SetSize(100, 4)
    Skin(track, { 0.012, 0.012, 0.012, 1 }, { 0, 0, 0, 1 })
    local fill = track:CreateTexture(nil, "ARTWORK")
    fill:SetTexture(SOLID)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    fill:SetVertexColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
    local thumb = CreateFrame("Frame", nil, f, "BackdropTemplate")
    thumb:SetSize(10, 16)
    Skin(thumb, { 0.38, 0.29, 0.06, 1 }, C.ACCENT)
    local hit = CreateFrame("Button", nil, f)
    hit:SetPoint("TOPLEFT", track, "TOPLEFT", -6, 8)
    hit:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 6, -8)
    local lo, hi, step = spec.min, spec.max, spec.step -- whole percents
    local function Draw(pct)
        local p = (pct - lo) / (hi - lo)
        fill:SetWidth(math.max(0.01, 98 * p))
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", track, "LEFT", 100 * p, 0)
        f.value:SetText(pct .. "%")
    end
    local function FromCursor()
        local x = GetCursorPosition() / track:GetEffectiveScale()
        local p = math.max(0, math.min(1, (x - track:GetLeft()) / track:GetWidth()))
        return lo + math.floor(p * (hi - lo) / step + 0.5) * step
    end
    hit:SetScript("OnMouseDown", function(self)
        self:SetScript("OnUpdate", function()
            local pct = FromCursor()
            f.pending = pct
            Draw(pct)
            if spec.live and spec.apply then spec.apply(pct / 100) end
        end)
    end)
    hit:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
        local pct = f.pending or math.floor(FGT.Setting(spec.key) * 100 + 0.5)
        f.pending = nil
        FGT.SetSetting(spec.key, pct / 100)
        Draw(pct)
        if spec.apply then spec.apply(pct / 100) end
    end)
    function f:Refresh() Draw(math.floor(FGT.Setting(spec.key) * 100 + 0.5)) end
    return f
end

local function NewButton(parent, text, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    Etch(b, STYLE.button, 8)
    b.text = NewFontString(b, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    b.text:SetPoint("CENTER", 0, 0)
    function b:SetLabel(t)
        self.text:SetText(t)
        self:SetSize(math.max(64, math.ceil(self.text:GetStringWidth()) + 20), 22)
    end
    b:SetLabel(text)
    b:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
    b:SetScript("OnLeave", function(self) self:SetEtch(STYLE.button) end)
    b:SetScript("OnClick", onClick)
    return b
end

-- ------------------------------------------------------------
-- Tracked characters: most recently played first, 8 at a time with a
-- "Show all" link. Remove asks once ("Confirm") before it deletes.
-- ------------------------------------------------------------
local CHAR_SHOWN = 8
local function CharacterList(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.line = f:CreateTexture(nil, "BACKGROUND") -- unused hairline, keeps rows uniform
    f.line:Hide()
    f.items = {}
    f.more = CreateFrame("Button", nil, f)
    f.more:SetHeight(18)
    f.more.text = NewFontString(f.more, 10, "", C.TITLE[1], C.TITLE[2], C.TITLE[3])
    f.more.text:SetPoint("LEFT")
    f.more:SetScript("OnClick", function()
        S.showAllChars = not S.showAllChars
        FGT.LayoutSettings()
    end)
    f.note = NewFontString(f, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    f.note:SetJustifyH("LEFT")
    f.note:SetWordWrap(true)
    f.note:SetText("A character is added when you log into it. Removing one drops its saved items, quests and reputation from the totals; steps already ticked stay ticked.")

    local function NewItem()
        local it = CreateFrame("Frame", nil, f)
        it:SetHeight(30)
        it.name = NewFontString(it, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
        it.name:SetPoint("TOPLEFT", 0, -3)
        it.name:SetJustifyH("LEFT")
        it.name:SetWordWrap(false)
        it.detail = NewFontString(it, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        it.detail:SetPoint("TOPLEFT", it.name, "BOTTOMLEFT", 0, -2)
        it.detail:SetJustifyH("LEFT")
        it.detail:SetWordWrap(false)
        it.me = NewFontString(it, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        it.me:SetPoint("RIGHT", it, "RIGHT", 0, 0)
        it.me:SetText("this character")
        it.remove = NewButton(it, "Remove", function(self)
            if self.armed then
                ForeverGoalTrackerDB.characters[it.key] = nil
                FGT.LayoutSettings()
            else
                -- first click arms it; the second removes
                self.armed = true
                self:SetLabel("Confirm")
                self:SetEtch(STYLE.dangerHv)
                C_Timer.After(3, function()
                    if self.armed then
                        self.armed = nil
                        self:SetLabel("Remove")
                        self:SetEtch(STYLE.button)
                    end
                end)
            end
        end)
        it.remove:SetScript("OnLeave", function(self) self:SetEtch(self.armed and STYLE.dangerHv or STYLE.button) end)
        it.remove:SetPoint("RIGHT", it, "RIGHT", 0, 0)
        return it
    end

    function f:Layout(w)
        local DB = ForeverGoalTrackerDB
        local list = {}
        for key, c in pairs(DB and DB.characters or {}) do
            list[#list + 1] = { key = key, c = c }
        end
        table.sort(list, function(a, b) return (a.c.lastSeen or 0) > (b.c.lastSeen or 0) end)
        local shown = S.showAllChars and #list or math.min(#list, CHAR_SHOWN)
        local me = CharKey()
        local y = 6
        for i = 1, shown do
            local it = self.items[i] or NewItem()
            self.items[i] = it
            local c = list[i].c
            it.key = list[i].key
            local cc = RAID_CLASS_COLORS and c.class and RAID_CLASS_COLORS[c.class]
            it.name:SetText(c.name or it.key)
            if cc then it.name:SetTextColor(cc.r, cc.g, cc.b) else it.name:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3]) end
            local className = (LOCALIZED_CLASS_NAMES_MALE and c.class and LOCALIZED_CLASS_NAMES_MALE[c.class]) or ""
            it.detail:SetText(string.format("Level %d %s  ·  %s", c.level or 1, className, c.realm or ""))
            local isMe = it.key == me
            it.me:SetShown(isMe)
            it.remove:SetShown(not isMe)
            it.remove.armed = nil
            it.remove:SetLabel("Remove")
            it.remove:SetEtch(STYLE.button)
            it.name:SetWidth(w - 90)
            it.detail:SetWidth(w - 90)
            it:ClearAllPoints()
            it:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -y)
            it:SetWidth(w)
            it:Show()
            y = y + 34
        end
        for i = shown + 1, #self.items do self.items[i]:Hide() end
        if #list > CHAR_SHOWN then
            self.more.text:SetText(S.showAllChars and "Show fewer" or ("Show all " .. #list))
            self.more:SetWidth(self.more.text:GetStringWidth() + 4)
            self.more:ClearAllPoints()
            self.more:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -y)
            self.more:Show()
            y = y + 22
        else
            self.more:Hide()
        end
        self.note:SetWidth(w)
        self.note:ClearAllPoints()
        self.note:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(y + 4))
        y = y + 4 + (self.note:GetStringHeight() or 20) + 6
        self:SetSize(w, y)
        return y
    end
    return f
end

-- ------------------------------------------------------------
-- What's on the page. Row types: toggle, choice, slider, button, and
-- info (text only), custom (build(parent) returns a frame with :Layout(width)).
-- ------------------------------------------------------------
local function KeybindLabel()
    local key = GetBindingKey and GetBindingKey("FGT_TOGGLE")
    return key or "Not set"
end

-- The game's own sound settings (Options > Sound), read live and never
-- changed here. Used to grey out sound choices you wouldn't hear.
C.MUTED     = { 0.40, 0.39, 0.37 }
C.MUTED_SEL = { 0.62, 0.56, 0.40 }
FGT.CHANNEL_CVARS = {
    Master   = { vol = "Sound_MasterVolume", name = "Master" },
    SFX      = { on = "Sound_EnableSFX",      vol = "Sound_SFXVolume",      name = "Effects" },
    Ambience = { on = "Sound_EnableAmbience", vol = "Sound_AmbienceVolume", name = "Ambience" },
    Music    = { on = "Sound_EnableMusic",    vol = "Sound_MusicVolume",    name = "Music" },
    Dialog   = { on = "Sound_EnableDialog",   vol = "Sound_DialogVolume",   name = "Dialog" },
}
function FGT.SoundCVar(name)
    local get = (C_CVar and C_CVar.GetCVar) or GetCVar
    local ok, v = pcall(get, name)
    return ok and tonumber(v) or nil
end
-- All game sound is off, or Master is at 0%.
function FGT.SoundOff()
    if FGT.SoundCVar("Sound_EnableAllSound") == 0 or FGT.SoundCVar("Sound_MasterVolume") == 0 then
        return "Your game sound is disabled"
    end
end
-- That channel is unchecked or its slider is at 0%.
function FGT.ChannelMuted(ch)
    local cv = FGT.CHANNEL_CVARS[ch]
    if not cv then return end
    if (cv.on and FGT.SoundCVar(cv.on) == 0) or FGT.SoundCVar(cv.vol) == 0 then
        return "Your " .. cv.name:lower() .. " channel is disabled"
    end
end

FGT.SETTINGS = {
    { title = "Item tooltips", rows = {
        { type = "toggle", key = "itemNeeds", label = "Show Needed for",
          desc = "Show unfinished tracked goals on items in bags, loot and the Auction House, with remaining amounts from your characters' last scans" },
    } },
    { title = "Chat and alerts", rows = {
        { type = "toggle", key = "greeting", label = "Login check-in",
          desc = "Your overall progress in chat a few seconds after you log in" },
        { type = "toggle", key = "completeChat", label = "Goal complete message",
          desc = "A line in chat with a link to the goal you finished" },
        { type = "toggle", key = "completeBanner", label = "Goal complete banner",
          desc = "A tile near the top of the screen when a goal finishes" },
        { type = "toggle", key = "screenshot", label = "Screenshot when a goal finishes",
          desc = "Saved in the game's Screenshots folder, like pressing Print Screen" },
        { type = "toggle", key = "stepChat", label = "Step updates in chat",
          desc = "\"3 steps checked off\", boss kills and characters reaching 60" },
        { type = "button", label = "Try the goal-complete alerts",
          desc = "Plays the message, banner, sound and screenshot, whatever they're set to",
          text = "Preview", onClick = function() FGT.TestBanner() end },
    } },
    { title = "Effects", rows = {
        { type = "choice", key = "celebrations", label = "Celebrations",
          desc = "When a step, group or goal finishes. Subtle keeps the checkmark pop only.",
          options = { { "full", "Full" }, { "subtle", "Subtle" }, { "off", "Off" } } },
        { type = "choice", key = "sound", label = "Sound when a goal completes",
          desc = "Picking one plays it",
          options = { { "off", "Off" }, { "levelup", "Level up" }, { "questturnin", "Quest turn-in" } },
          muted = function() return FGT.SoundOff() end,
          mutedDesc = "Game sound is off in Options > Sound",
          apply = function(v) FGT.PlayGoalSound(v) end },
        { type = "choice", key = "soundChannel", label = "Sound channel",
          desc = "Which of the game's volume sliders the sound follows",
          options = { { "Master", "Master" }, { "SFX", "Effects" }, { "Ambience", "Ambience" },
                      { "Music", "Music" }, { "Dialog", "Dialog" } },
          muted = function() return FGT.SoundOff() end,
          optionMuted = function(v) return FGT.ChannelMuted(v) end,
          apply = function() FGT.PlayGoalSound(FGT.Setting("sound")) end },
    } },
    { title = "Window and minimap", rows = {
        { type = "toggle", key = "minimap", label = "Minimap button",
          apply = function(on) if FGT.minimapButton then FGT.minimapButton:SetShown(on) end end },
        { type = "toggle", key = "openOnLogin", label = "Open on login",
          desc = "Show this window each time you log in" },
        { type = "button", label = "Goal suggestions", desc = "Pick what you enjoy and get goals for this character",
          text = "Open", onClick = function() FGT.OpenWelcome(2) end },
        { type = "slider", key = "scale", label = "Scale", min = 70, max = 130, step = 5,
          apply = function(v) FGT.ApplyWindowScale(v) end },
        { type = "slider", key = "alpha", label = "Opacity", min = 50, max = 100, step = 5, live = true,
          apply = function(v) main:SetAlpha(v) end },
        { type = "button", label = "Keybind", desc = "Set it in Options, Keybindings, AddOns",
          text = KeybindLabel, onClick = function()
              local ok = Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID
                  and pcall(Settings.OpenToCategory, Settings.KEYBINDINGS_CATEGORY_ID)
              if not ok then print(TAG .. "set a key in Options > Keybindings > AddOns > Forever Goal Tracker.") end
          end },
        { type = "button", label = "Window size and position", desc = "Back to the default size, centered",
          text = "Reset", onClick = function() FGT.ResetWindow() end },
    } },
    { title = "NPC map pins", rows = {
        { type = "choice", key = "mapPins", label = "Where map pins go",
          desc = "When you shift-click an NPC or use Show on map. Automatic uses TomTom if it's installed.",
          options = { { "auto", "Automatic" }, { "tomtom", "TomTom" }, { "game", "Game map" } },
          optionMuted = function(v) if v == "tomtom" and not FGT.HasTomTom() then return "TomTom isn't installed" end end },
    } },
    { title = "Tracked characters", rows = {
        { type = "custom", build = CharacterList },
    } },
    { title = "Artwork and credits", rows = {
        { type = "info", label = "Blizzard Entertainment",
          desc = "World of Warcraft and Hearthstone artwork: copyright Blizzard Entertainment. All rights reserved." },
        { type = "info", label = "Alex Horley" },
        { type = "info", label = "AI-assisted artwork",
          desc = "Some original addon artwork was created with assistance from ChatGPT and Nano Banana." },
        { type = "info", label = "Cinzel font",
          desc = "Cinzel is included under the SIL Open Font License. See Fonts/OFL.txt." },
        { type = "info", label = "Unofficial community addon",
          desc = "Forever Goal Tracker is not affiliated with or endorsed by Blizzard Entertainment." },
        { type = "info", label = "Artwork and code licenses",
          desc = "The addon's MIT license applies to its code. Third-party artwork retains its applicable rights and is not covered by that license. These credits are acknowledgments, not a grant of permission." },
    } },
}

function FGT.BuildSettings()
    if S.built then return end
    S.built = true
    for gi, spec in ipairs(FGT.SETTINGS) do
        local g = CreateFrame("Frame", nil, S.scroll.content, "BackdropTemplate")
        Etch(g, STYLE.row, 12)
        g.title = NewTitleString(g, 13)
        g.title:SetPoint("TOPLEFT", 12, -12)
        g.title:SetText(spec.title)
        g.rows = {}
        for _, rs in ipairs(spec.rows) do
            local r
            if rs.type == "custom" then
                r = rs.build(g)
            else
                r = NewRow(g, rs.label, rs.desc)
                if rs.type == "toggle" then
                    r.control = NewToggle(r, rs)
                elseif rs.type == "choice" then
                    r.control = NewChoice(r, rs)
                elseif rs.type == "slider" then
                    r.control = NewSlider(r, rs)
                elseif rs.type == "button" then
                    local btn = NewButton(r, "", rs.onClick)
                    btn:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -6)
                    btn.topOffset = -6
                    -- text may be a function (the keybind shows the current key)
                    function btn:Refresh()
                        self:SetLabel(type(rs.text) == "function" and rs.text() or rs.text)
                    end
                    r.control = btn
                end
            end
            if r.control and r.control.Refresh then table.insert(S.controls, r.control) end
            table.insert(g.rows, r)
        end
        S.groups[gi] = g
    end
end

-- Lays the groups out for the current window size.
function FGT.LayoutSettings()
    if not (S.built and panel:IsShown()) then return end
    local W = S.scroll.scroll:GetWidth()
    if not W or W < 50 then return end
    S.scroll.content:SetWidth(W)
    local gap = 12
    local cols = (W >= 560) and 2 or 1
    local colW = math.floor((W - gap * (cols - 1)) / cols)
    local colY = {}
    for c = 1, cols do colY[c] = 0 end
    for _, g in ipairs(S.groups) do
        -- the group's own height for this width
        g:SetWidth(colW)
        local y, inner = 36, colW - 24 -- below the group title
        for i, r in ipairs(g.rows) do
            local h = r:Layout(inner)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", g, "TOPLEFT", 12, -y)
            r.line:SetShown(i > 1)
            y = y + h
        end
        g:SetHeight(y + 8)
        -- into the shorter column
        local col = 1
        for c = 2, cols do if colY[c] < colY[col] then col = c end end
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", S.scroll.content, "TOPLEFT", (col - 1) * (colW + gap), -colY[col])
        colY[col] = colY[col] + y + 8 + gap
    end
    local total = 0
    for c = 1, cols do total = math.max(total, colY[c]) end
    S.scroll.content:SetHeight(math.max(1, total - gap))
    S.scroll:Update()
end

function FGT.RefreshSettings()
    for _, ctl in ipairs(S.controls) do ctl:Refresh() end
end

panel:SetScript("OnSizeChanged", function() FGT.LayoutSettings() end)

-- Follow the game's sound settings while the page is open (Ctrl+S, or a
-- volume slider in Options > Sound). Not every change fires CVAR_UPDATE,
-- so the page checks twice a second and redraws only when one changed.
do
    local watched = { "Sound_EnableAllSound" }
    for _, cv in pairs(FGT.CHANNEL_CVARS) do
        if cv.on then watched[#watched + 1] = cv.on end
        watched[#watched + 1] = cv.vol
    end
    local last, wait = nil, 0
    panel:HookScript("OnUpdate", function(_, elapsed)
        wait = wait - elapsed
        if wait > 0 or not S.built then return end
        wait = 0.5
        local parts = {}
        for i, name in ipairs(watched) do parts[i] = tostring(FGT.SoundCVar(name) == 0) end
        local now = table.concat(parts, ",")
        if last and now ~= last then
            FGT.RefreshSettings()
            FGT.LayoutSettings()
        end
        last = now
    end)
end

-- ------------------------------------------------------------
-- Opening and closing. The gear sits left of the close button.
-- ------------------------------------------------------------
-- Karl's gold gear (Media/icons/gear), no box, matching the close X
-- beside it. It stays a little lit while Settings is open.
local gear = CreateFrame("Button", nil, titleBar)
gear:SetSize(22, 22)
gear:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
gear:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Settings")
    GameTooltip:Show()
end)
gear:SetScript("OnLeave", function() GameTooltip:Hide() end)
FGT.IconButton(gear, "gear", 17) -- after SetScript: SetScript would drop its hooks

function FGT.UpdateGear()
    gear.lit = panel:IsShown()
    gear:RefreshIcon()
end
FGT.UpdateGear()
gear:SetScript("OnClick", function()
    if panel:IsShown() then FGT.LeaveSettings() else FGT.OpenSettings() end
end)

function FGT.OpenSettings()
    FGT.CloseNoteCard(true)
    if not main:IsShown() then FGT.ToggleFrame() end
    FGT.BuildSettings()
    if FGT.CloseGoalMenu then FGT.CloseGoalMenu() end
    if FGT.CloseLinkCard then FGT.CloseLinkCard() end
    listPanel:Hide()
    detailPanel:Hide()
    FGT.libraryPanel:Hide()
    FGT.trackerTab:SetActive(false)
    FGT.libraryTab:SetActive(false)
    panel:Show()
    FGT.UpdateGear()
    FGT.RefreshSettings()
    S.scroll.scroll:SetVerticalScroll(0)
    FGT.LayoutSettings()
end

-- Hides the page without touching the tabs (ShowTab calls this).
function FGT.CloseSettings()
    if panel:IsShown() then
        panel:Hide()
        FGT.UpdateGear()
    end
end

-- Back to the tab you were on.
function FGT.LeaveSettings()
    if panel:IsShown() then
        FGT.ShowTab(ForeverGoalTrackerDB and ForeverGoalTrackerDB.tab or "tracker")
    end
end
main:HookScript("OnHide", function() FGT.LeaveSettings() end)

-- ------------------------------------------------------------
-- Window scale and reset
-- ------------------------------------------------------------
-- Keeps the window's top-left corner where it is on screen while the
-- scale changes; PlaceWindow then re-checks size and position.
function FGT.ApplyWindowScale(s)
    s = s or 1
    FGT.windowScale = s
    local old = main:GetScale()
    if math.abs(old - s) < 0.001 then return end
    local l, t = main:GetLeft(), main:GetTop()
    main:SetScale(s)
    if l and t and ForeverGoalTrackerDB then
        ForeverGoalTrackerDB.frameLeft, ForeverGoalTrackerDB.frameTop = l * old / s, t * old / s
    end
    FGT.PlaceWindow()
    FGT.LayoutSettings()
end

function FGT.ResetWindow()
    local DB = ForeverGoalTrackerDB
    if not DB then return end
    DB.frameWidth, DB.frameHeight = FGT.DefaultSize()
    DB.frameLeft, DB.frameTop = nil, nil
    FGT.PlaceWindow()
    LayoutGoalList()
    if selectedId then SelectGoal(selectedId, true) end
    FGT.LayoutSettings()
end

-- ------------------------------------------------------------
-- Options > AddOns: a short page with a button to the real settings.
-- ------------------------------------------------------------
do
    local op = CreateFrame("Frame")
    op.name = FGT.NAME
    local t = op:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText(FGT.NAME)
    local d = op:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    d:SetText("Settings live in the tracker window, behind the gear icon.")
    local b = NewButton(op, "Open settings", function()
        if SettingsPanel and SettingsPanel:IsShown() then pcall(HideUIPanel, SettingsPanel) end
        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then pcall(HideUIPanel, InterfaceOptionsFrame) end
        FGT.OpenSettings()
    end)
    b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        pcall(function()
            local cat = Settings.RegisterCanvasLayoutCategory(op, FGT.NAME)
            Settings.RegisterAddOnCategory(cat)
        end)
    elseif InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, op)
    end
end

end

-- Key Bindings (Bindings.xml): Options > Keybindings > AddOns.
BINDING_HEADER_FOREVERGOALTRACKER = "Forever Goal Tracker"
BINDING_NAME_FGT_TOGGLE = "Open or close the tracker"
function ForeverGoalTracker_Toggle() FGT.ToggleFrame() end

-- ============================================================
-- Toggle / init
-- ============================================================
function FGT.ToggleFrame()
    if main:IsShown() then
        main:Hide()
    else
        local a = FGT.Setting("alpha") -- fade in to the chosen opacity
        main:SetAlpha(0)
        main:Show()
        if UIFrameFadeIn then
            UIFrameFadeIn(main, 0.15, 0, a)
        else
            main:SetAlpha(a)
        end
    end
end

-- ============================================================
-- Chat greeting, finished-goal announcements and the banner
-- ============================================================
do -- scoped (200-local budget)
local CHEERS = {
    "You got this!", "Look at you go!", "Let's get it!", "One step closer.",
    "Keep that momentum.", "Legends are built one step at a time.", "Onward, hero!",
    "Today's a good day for progress.", "The grind is paying off.",
    "Your future self says thanks.", "Small steps, epic loot.", "Nothing can stop you now.",
    "Fortune favors the persistent.", "Every run counts.", "Keep stacking those wins.",
    "You're on a roll.", "Make it a legendary day.", "Azeroth won't conquer itself.",
    "Steady hands, big rewards.", "The best loot goes to the stubborn.",
}
local PRAISE = {
    "Well earned.", "Legendary.", "Take a bow.", "What a moment.",
    "One for the history books.", "Nicely done.",
}
local function Pick(list) return list[math.random(#list)] end

-- Clickable chat links. The chat frame hands every clicked link to
-- SetItemRef; ours ("fgt:...") open the tracker, everything else goes
-- on to the game's own handler untouched.
local function GoalLink(goal)
    return "|cffffd100|Hfgt:goal:" .. goal.id .. "|h[" .. goal.name .. "]|h|r"
end
local OPEN_LINK = "|cffffd100|Hfgt:open|h[Open tracker]|h|r"

function FGT.OpenToGoal(id)
    if not main:IsShown() then FGT.ToggleFrame() end
    if id and #ActiveGoals() > 0 then
        FGT.ShowTab("tracker")
        SelectGoal(id)
    elseif #ActiveGoals() == 0 then
        FGT.ShowTab("library")
    end
end

local gameSetItemRef = SetItemRef
SetItemRef = function(link, text, button, chatFrame)
    if type(link) == "string" and link:sub(1, 4) == "fgt:" then
        local _, kind, id = strsplit(":", link)
        FGT.OpenToGoal(kind == "goal" and id or nil)
        return
    end
    return gameSetItemRef(link, text, button, chatFrame)
end

-- 1. A few seconds after login or /reload, once the login chatter has
-- passed: overall progress and a random cheer.
function FGT.LoginGreeting()
    if not FGT.Setting("greeting") then return end
    local function say()
        local goals = ActiveGoals()
        if #goals == 0 then
            print(TAG .. "your tracker is empty. " .. OPEN_LINK .. " to pick your first goal.")
            return
        end
        local d, t = OverallProgress()
        local pct = d / math.max(1, t) * 100
        pct = (pct >= 100) and 100 or math.floor(pct)
        local cheer
        if pct >= 100 then
            cheer = "Every goal complete. Time to pick new ones!"
        elseif pct == 0 then
            cheer = "Every legend starts at zero. Let's get it!"
        else
            cheer = Pick(CHEERS)
        end
        print(TAG .. string.format("You've completed |cffffffff%d%%|r of your goals. %s ", pct, cheer) .. OPEN_LINK)
    end
    if C_Timer and C_Timer.After then C_Timer.After(4, say) else say() end
end

-- 2. The banner: a gold-edged tile near the top of the screen with the
-- goal's icon and name. It plays the same celebration as the list,
-- holds for a few seconds (longer while hovered), and opens the goal
-- when clicked. Several at once queue up.
local toast, queue = nil, {}
local HOLD, FADE_IN, FADE_OUT = 6, 0.25, 0.6

local function BuildToast()
    toast = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    toast:SetSize(340, 64)
    toast.fgtOwn = true -- our tooltips are drawn darker
    toast:SetPoint("TOP", UIParent, "TOP", 0, -70)
    -- one layer above the tracker window (HIGH), so the window's lines
    -- and panels never draw across the banner
    toast:SetFrameStrata("DIALOG")
    Etch(toast, STYLE.window, 12)
    toast.icon = NewIcon(toast, 42)
    toast.icon:SetPoint("LEFT", toast, "LEFT", 12, 0)
    toast.label = NewTitleString(toast, 10)
    toast.label:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 10, -3)
    toast.label:SetText("Goal complete")
    toast.name = NewFontString(toast, 14, "", 1, 1, 1)
    toast.name:SetPoint("TOPLEFT", toast.label, "BOTTOMLEFT", 0, -5)
    toast.name:SetPoint("RIGHT", toast, "RIGHT", -40, 0)
    toast.name:SetJustifyH("LEFT")
    toast.name:SetWordWrap(false)
    toast.doneCheck = toast:CreateTexture(nil, "OVERLAY")
    toast.doneCheck:SetTexture(FGT.Icon("check-white"))
    toast.doneCheck:SetSize(14, 14)
    toast.doneCheck:SetPoint("RIGHT", toast, "RIGHT", -10, 1)
    toast.doneCheck:SetDesaturated(true)
    toast.doneCheck:SetVertexColor(C.DONE[1], C.DONE[2], C.DONE[3])
    FGT.AddCelebrationFX(toast, 3, 56)
    toast.doneGlow:Show()
    toast:SetScript("OnClick", function(self)
        local id = self.goalId
        self.life = HOLD + FADE_IN -- skip straight to the fade out
        FGT.OpenToGoal(id)
    end)
    -- Fade and timing run on a child frame: the celebration itself
    -- uses the banner's own OnUpdate.
    toast.driver = CreateFrame("Frame", nil, toast)
    toast.driver:SetScript("OnUpdate", function(_, elapsed)
        local t = toast
        -- hovering holds it on screen (but never mid-fade)
        local holding = t.life >= FADE_IN and t.life < FADE_IN + HOLD and t:IsMouseOver()
        if not holding then t.life = t.life + elapsed end
        local life = t.life
        if life < FADE_IN then
            t:SetAlpha(life / FADE_IN)
        elseif life < FADE_IN + HOLD then
            t:SetAlpha(1)
            if not t.played then
                t.played = true
                if FGT.Setting("celebrations") ~= "off" then FGT.CelebrateRow(t) end
            end
        elseif life < FADE_IN + HOLD + FADE_OUT then
            t:SetAlpha(1 - (life - FADE_IN - HOLD) / FADE_OUT)
        else
            t:Hide()
            FGT.NextToast()
        end
    end)
    toast:Hide()
end

function FGT.NextToast()
    local goal = table.remove(queue, 1)
    if not goal then return end
    if not toast then BuildToast() end
    toast.goalId = goal.id
    toast.icon:SetIcon(goal.icon, FGT.categoryColors[goal.category] or C.ACCENT)
    toast.name:SetText(goal.name)
    toast.life, toast.played = 0, false
    toast:SetAlpha(0)
    toast:Show()
end

-- force: /goals testbanner shows both whatever the settings say.
local function Announce(goal, force)
    if force or FGT.Setting("completeChat") then
        print(TAG .. "You just completed " .. GoalLink(goal) .. "! " .. Pick(PRAISE))
    end
    if force or FGT.Setting("completeBanner") then
        table.insert(queue, goal)
        if not (toast and toast:IsShown()) then FGT.NextToast() end
    end
end

-- Optional sound when a whole goal finishes (off by default). Sound kit
-- IDs from Wowhead's UI sounds (https://www.wowhead.com/sounds/user-interface):
-- 888 LEVELUP, 878 igQuestListComplete (the quest turn-in chime).
FGT.SOUNDS = { levelup = 888, questturnin = 878 }

function FGT.PlayGoalSound(which)
    local id = FGT.SOUNDS[which]
    if id and PlaySound then pcall(PlaySound, id, FGT.Setting("soundChannel")) end
end

function FGT.GoalCompleteSound()
    FGT.PlayGoalSound(FGT.Setting("sound"))
end

-- Optional screenshot when a goal finishes (Settings, off by default).
-- Waits a moment so the banner (or the card's celebration) is in the
-- picture; goals finishing together give one screenshot. The game saves
-- it in its Screenshots folder; addons can't choose the name or place.
function FGT.GoalScreenshot()
    if not FGT.Setting("screenshot") or FGT.shotPending or not Screenshot then return end
    FGT.shotPending = true
    C_Timer.After(1.2, function()
        FGT.shotPending = nil
        pcall(Screenshot)
    end)
end

-- /goals testbanner: plays the announcement for the open goal (or the
-- first goal on the tracker) without changing any progress.
function FGT.TestBanner()
    local DB = ForeverGoalTrackerDB
    local goal
    for _, g in ipairs(FGT.goals) do
        if DB and g.id == DB.selected then goal = g end
    end
    goal = goal or ActiveGoals()[1] or FGT.goals[1]
    print(TAG .. "Test banner (no progress changed):")
    Announce(goal, true)
    FGT.GoalCompleteSound() -- the chosen sound and channel, like a real finish
    FGT.GoalScreenshot()
end

-- Remembers which goals are finished (DB.goalsDone) so each one is
-- announced once, the moment it finishes. Goals finished with the
-- window open celebrate in the list instead, so they're only noted.
-- The first run after updating just takes stock, quietly.
function FGT.CheckGoalCompletions()
    local DB = ForeverGoalTrackerDB
    if not DB then return end
    local first = type(DB.goalsDone) ~= "table"
    if first then DB.goalsDone = {} end
    -- When each goal was finished (time()), for "Completed Oct 6, 2026".
    -- Goals already finished before dates existed simply have none.
    if type(DB.goalDates) ~= "table" then DB.goalDates = {} end
    local quiet = first or main:IsShown() or DB.demoBackup -- no banners for demo goals
    for _, g in ipairs(ActiveGoals()) do
        local d, t = GoalProgress(g)
        if t > 0 and d == t then
            if not DB.goalsDone[g.id] then
                DB.goalsDone[g.id] = true
                if not first then DB.goalDates[g.id] = time() end
                if not first and not DB.demoBackup then FGT.GoalCompleteSound(); FGT.GoalScreenshot() end
                if not quiet then Announce(g) end
            end
        else
            DB.goalsDone[g.id] = nil
            DB.goalDates[g.id] = nil
        end
    end
end
end

-- Let Escape close the window like any other Blizzard panel. Registering
-- with UISpecialFrames is the standard way and works on every client.
-- (The old OnKeyDown + SetPropagateKeyboardInput approach throws an
-- ADDON_ACTION_BLOCKED error in combat on the modern engine that
-- Warcraft Forever runs on, and could eat keypresses.)
tinsert(UISpecialFrames, "ForeverGoalTrackerFrame")

-- ScrollFrame/content heights measured while the window (and everything
-- inside it) is still hidden aren't always reliable, so re-measure both
-- scroll areas the moment the window actually becomes visible.
main:SetScript("OnShow", function()
    if FGT.PlaceWindow then FGT.PlaceWindow() end -- screen is final by now
    LayoutGoalList()
    listScrollObj:Update()
    if FGT.ShowTab and ForeverGoalTrackerDB then FGT.ShowTab(ForeverGoalTrackerDB.tab) end
    if selectedId then
        SelectGoal(selectedId, true)
    end
end)

-- Size and position the window from saved data, measured against the
-- real screen at this moment. Saved spot missing or off-screen ->
-- centered. Always ends anchored TOPLEFT so drags start clean.
function FGT.PlaceWindow()
    if not ForeverGoalTrackerDB then return end
    UpdateResizeBounds()
    local w, h = ClampFrameSize(ForeverGoalTrackerDB.frameWidth, ForeverGoalTrackerDB.frameHeight)
    main:SetSize(w, h)
    ForeverGoalTrackerDB.frameWidth, ForeverGoalTrackerDB.frameHeight = w, h
    local left, top = ForeverGoalTrackerDB.frameLeft, ForeverGoalTrackerDB.frameTop
    local sc = FGT.windowScale or 1 -- positions are in the window's own (scaled) units
    local sw, sh = GetScreenWidth() / sc, GetScreenHeight() / sc
    main:ClearAllPoints()
    if left and top then
        -- nudge a saved spot back on screen rather than recentering, so a
        -- fraction of a pixel of UI-scale rounding can't move the window
        left = math.max(0, math.min(sw - w, left))
        top = math.max(h, math.min(sh, top))
        main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    else
        main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", math.floor((sw - w) / 2), math.floor((sh + h) / 2))
    end
end

-- Finish wiring the resize grip now that LayoutGoalList/SelectGoal
-- exist: once the user releases the drag, save the new size and
-- reflow the goal list and the currently-open goal's steps to the
-- new width.
resizeGrip:SetScript("OnMouseUp", function(self)
    if not isSizing then return end
    self:SetScript("OnUpdate", nil)
    FGT.sizeStart = nil
    isSizing = false
    NormalizeAnchor()
    SavePosition()
    local cw, ch = ClampFrameSize(main:GetWidth(), main:GetHeight())
    if math.abs(main:GetWidth() - cw) > 0.5 or math.abs(main:GetHeight() - ch) > 0.5 then
        main:SetSize(cw, ch)
    end
    if ForeverGoalTrackerDB then
        ForeverGoalTrackerDB.frameWidth = cw
        ForeverGoalTrackerDB.frameHeight = ch
    end
    LayoutGoalList()
    if selectedId then
        SelectGoal(selectedId, true)
    end
end)

-- ============================================================
-- Minimap button
-- ============================================================
local minimapButton = CreateFrame("Button", "ForeverGoalTrackerMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
FGT.minimapButton = minimapButton -- for the "Minimap button" setting
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local mmBackground = minimapButton:CreateTexture(nil, "BACKGROUND")
mmBackground:SetSize(20, 20)
mmBackground:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
mmBackground:SetPoint("TOPLEFT", 7, -5)

local mmIcon = minimapButton:CreateTexture(nil, "ARTWORK")
mmIcon:SetSize(21, 21)
mmIcon:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\minimap")
mmIcon:SetPoint("TOPLEFT", 6, -5)

local mmBorder = minimapButton:CreateTexture(nil, "OVERLAY")
mmBorder:SetSize(53, 53)
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmBorder:SetPoint("TOPLEFT")

local function UpdateMinimapButtonPosition()
    local angle = math.rad(ForeverGoalTrackerDB.minimapPos or 200)
    -- Sit on the rim of whatever size minimap this client has (a fixed
    -- 80 put the button just outside Forever's smaller minimap).
    local radius = (Minimap:GetWidth() or 140) / 2 + 5
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

minimapButton:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(Atan2(py - my, px - mx))
        ForeverGoalTrackerDB.minimapPos = angle
        UpdateMinimapButtonPosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapButton:SetScript("OnClick", function()
    FGT.ToggleFrame()
end)

minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(FGT.NAME)
    -- Progress at a glance: overall, then each favorite's next step.
    local active = ForeverGoalTrackerDB and ActiveGoals() or {}
    if #active > 0 then
        local d, t = OverallProgress()
        GameTooltip:AddLine(string.format("%d%% overall  ·  %d of %d goals complete",
            math.floor(d / math.max(1, t) * 100 + 0.5), CountGoalsComplete(), #active), C.INK2[1], C.INK2[2], C.INK2[3])
        local favs = ForeverGoalTrackerDB.favorites or {}
        local list = {}
        for _, g in ipairs(active) do if favs[g.id] then table.insert(list, g) end end
        table.sort(list, function(a, b) return (a.short or a.name) < (b.short or b.name) end)
        local star = "|T" .. FGT.Icon("star") .. ":12:12|t "
        for i, g in ipairs(list) do
            if i > 5 then break end
            local gd, gt = GoalProgress(g)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(star .. (g.short or g.name), string.format("%d%%", math.floor(gd / math.max(1, gt) * 100 + 0.5)),
                C.TITLE[1], C.TITLE[2], C.TITLE[3], C.INK2[1], C.INK2[2], C.INK2[3])
            local nxt = FGT.NextStep(g)
            local on = not nxt and FGT.CompletedOn(g)
            if nxt then
                GameTooltip:AddLine("Next: " .. nxt, C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
            else
                GameTooltip:AddLine(on and ("Completed " .. on) or "Complete", C.DONE[1], C.DONE[2], C.DONE[3])
            end
        end
        GameTooltip:AddLine(" ")
    end
    GameTooltip:AddLine("Click to open your checklist", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag to move this button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON then return end
    EnsureDB()
    BuildWatchList()
    -- v1.6 one-time fix: v1.5 counted any character for the epic mount
    -- riding/gold/purchase tasks, so clear those ticks and let the new
    -- race-specific rules re-check them.
    -- v1.6.2 one-time fix: the "met the Wintersaber Trainers" step could
    -- tick off from the game's default Neutral answer for unmet factions.
    -- Clear it (and the bogus saved standings) and let the fixed rule
    -- re-check.
    if not ForeverGoalTrackerDB.repFix then
        local p = ForeverGoalTrackerDB.progress.frostsaber
        if p then p[2] = nil end
        for _, c in pairs(ForeverGoalTrackerDB.characters or {}) do
            for fid, r in pairs(c.reps or {}) do
                if r.standing == 4 and (r.value or 0) == 0 then c.reps[fid] = nil end
            end
        end
        ForeverGoalTrackerDB.repFix = true
    end
    if not ForeverGoalTrackerDB.mountRaceFix then
        local p = ForeverGoalTrackerDB.progress.epicmounts
        if p then
            for key in pairs(p) do
                if key:match("^%d+_[234]_piece$") then p[key] = nil end
            end
        end
        ForeverGoalTrackerDB.mountRaceFix = true
    end
    -- v2.1.2 one-time fix: tips moved out of the step lists, so saved
    -- ticks shift to their step's new number (false = step removed).
    if not ForeverGoalTrackerDB.tipsFix then
        local rep = { [1] = false, [2] = false, [3] = 1, [4] = 2, [5] = 3, [6] = 4 }
        local pvpMount = { [1] = false, [2] = 1, [3] = 2 }
        local remap = {
            ashbringer = { [7] = 6, [8] = false, [9] = false },
            benediction = { [4] = 3, [5] = 4, [6] = 5, [7] = false },
            lokdelar = { [8] = 7 },
            rhokdelar = { [6] = false },
            set_viper = { [6] = false },
            pvp_mount_ally = pvpMount, pvp_mount_horde = pvpMount,
            pvp_avmount_ally = pvpMount, pvp_avmount_horde = pvpMount,
        }
        for _, id in ipairs({ "rep_timbermaw", "rep_thorium", "rep_argentdawn", "rep_cenarion",
                "rep_zandalar", "rep_hydraxian", "rep_nozdormu", "pvp_wsg_ally", "pvp_wsg_horde",
                "pvp_ab_ally", "pvp_ab_horde", "pvp_av_ally", "pvp_av_horde" }) do
            remap[id] = rep
        end
        for id, map in pairs(remap) do
            local old = ForeverGoalTrackerDB.progress[id]
            if old then
                local new = {}
                for k, v in pairs(old) do
                    local to = map[k]
                    if to == nil then
                        new[k] = new[k] or v
                    elseif to then
                        new[to] = new[to] or v
                    end
                end
                ForeverGoalTrackerDB.progress[id] = new
            end
        end
        ForeverGoalTrackerDB.tipsFix = true
    end
    -- v2.3.1 one-time fix: steps you can't check off ("Join a raid team",
    -- "Get a group") became tips, so later ticks move up one.
    if not ForeverGoalTrackerDB.stepsFix231 then
        local zg = { [1] = false, [2] = 1, [3] = 2 }
        local remap = {
            ashbringer = { [3] = false, [4] = 3, [5] = 4, [6] = 5 },
            mount_deathcharger = { [2] = false, [3] = 2, [4] = 3 },
            mount_raptor = zg, mount_tiger = zg,
        }
        for id, map in pairs(remap) do
            local old = ForeverGoalTrackerDB.progress[id]
            if old then
                local new = {}
                for k, v in pairs(old) do
                    local to = map[k]
                    if to == nil then
                        new[k] = new[k] or v
                    elseif to then
                        new[to] = new[to] or v
                    end
                end
                ForeverGoalTrackerDB.progress[id] = new
            end
        end
        ForeverGoalTrackerDB.stepsFix231 = true
    end
    -- One-time fix: racial mounts gained an Exalted step at position 2
    -- (any race of the faction can buy them), so steps 2-4 of the eight
    -- Classic races move down one. Skyborne (part 9) keeps its 4 steps.
    if not ForeverGoalTrackerDB.mountsFix then
        local p = ForeverGoalTrackerDB.progress.epicmounts
        if p then
            local new = {}
            for key, v in pairs(p) do
                local s, i, rest = key:match("^(%d+)_(%d+)(_.*)$")
                s, i = tonumber(s), tonumber(i)
                if s and s <= 8 and i >= 2 then key = s .. "_" .. (i + 1) .. rest end
                new[key] = new[key] or v
            end
            ForeverGoalTrackerDB.progress.epicmounts = new
        end
        ForeverGoalTrackerDB.mountsFix = true
    end
    -- One-time fix: the racial mounts' Exalted step used to tick itself
    -- when any character of that race existed, which showed a tick to
    -- other races who still need the reputation. It now ticks only at
    -- Exalted, so clear the ticks that rule made (the auto log says why).
    if not ForeverGoalTrackerDB.exaltedRaceFix then
        local p = ForeverGoalTrackerDB.progress.epicmounts
        local log = ForeverGoalTrackerDB.autoLog or {}
        if p then
            for si = 1, 8 do
                local key = si .. "_2_piece"
                local why = log["epicmounts:" .. key]
                if p[key] and why and why:match("^race ") then
                    p[key] = nil
                    log["epicmounts:" .. key] = nil
                end
            end
        end
        ForeverGoalTrackerDB.exaltedRaceFix = true
    end
    -- Same for the Winterspring Frostsaber's Darnassus step (step 7).
    if not ForeverGoalTrackerDB.frostRaceFix then
        local p = ForeverGoalTrackerDB.progress.frostsaber
        local log = ForeverGoalTrackerDB.autoLog or {}
        local why = log["frostsaber:7"]
        if p and p[7] and why and why:match("^race ") then
            p[7] = nil
            log["frostsaber:7"] = nil
        end
        ForeverGoalTrackerDB.frostRaceFix = true
    end
    -- v2.2.0 one-time fix: Tier 3 materials were a placeholder list and are
    -- now each piece's real recipe. The token and scraps lines kept their
    -- place; the crafting materials changed, so clear their ticks (owned
    -- pieces tick them again).
    if not ForeverGoalTrackerDB.t3RecipeFix then
        local p = ForeverGoalTrackerDB.progress.tier3
        if p then
            for key in pairs(p) do
                local m = key:match("^%d+_%d+_m(%d+)$")
                if m and tonumber(m) >= 3 then p[key] = nil end
            end
        end
        ForeverGoalTrackerDB.t3RecipeFix = true
    end
    -- The combined "All Attunements and Keys" goal became nine separate
    -- goals; if it was on the tracker, put all nine there instead.
    if ForeverGoalTrackerDB.active.raid_attunements then
        for _, id in ipairs({ "att_mc", "att_ony", "att_bwl", "att_naxx", "key_ubrs",
                "key_scholo", "key_brd", "key_strat", "key_dm" }) do
            ForeverGoalTrackerDB.active[id] = true
        end
        ForeverGoalTrackerDB.active.raid_attunements = nil
        ForeverGoalTrackerDB.progress.raid_attunements = nil
        if ForeverGoalTrackerDB.selected == "raid_attunements" then ForeverGoalTrackerDB.selected = "att_mc" end
    end
    -- Onyxia's attunement then split by faction (the chains share no quests).
    if ForeverGoalTrackerDB.active.att_ony then
        local f = UnitFactionGroup and UnitFactionGroup("player")
        ForeverGoalTrackerDB.active.att_ony_ally = (f ~= "Horde") or nil
        ForeverGoalTrackerDB.active.att_ony_horde = (f ~= "Alliance") or nil
        ForeverGoalTrackerDB.active.att_ony = nil
        ForeverGoalTrackerDB.progress.att_ony = nil
        if ForeverGoalTrackerDB.selected == "att_ony" then ForeverGoalTrackerDB.selected = "att_mc" end
    end
    -- Molten Core and Blackwing Lair attunements grew from one step to
    -- three; the old single tick (the turn-in) now belongs on step 3.
    for _, id in ipairs({ "att_mc", "att_bwl" }) do
        local p = ForeverGoalTrackerDB.progress[id]
        if p and p[1] and not ForeverGoalTrackerDB.attuneSteps then p[3] = true end
    end
    ForeverGoalTrackerDB.attuneSteps = true
    FGT.MigrateArmorSets(ForeverGoalTrackerDB)
    if FGT.ApplyTargets then FGT.ApplyTargets() end -- player-set targets (gold, honorable kills)
    ApplyAutoRules() -- re-check against the saved roster from earlier sessions

    -- Re-clamp against the CURRENT screen every load, not just the
    -- fixed size caps - this is what self-heals a previously
    -- saved oversized window (or one saved on a bigger monitor) back
    -- to something that actually fits and keeps the resize grip
    -- reachable. Scale first: placement measures in scaled units.
    FGT.windowScale = FGT.Setting("scale")
    main:SetScale(FGT.windowScale)
    main:SetAlpha(FGT.Setting("alpha"))
    FGT.PlaceWindow()

    for i, m in ipairs(sortModes) do
        if m.key == ForeverGoalTrackerDB.sortMode then
            sortModeIndex = i
            break
        end
    end
    UpdateSortLabel()
    LayoutGoalList()

    SelectGoal(ForeverGoalTrackerDB.selected)
    FGT.ShowTab(ForeverGoalTrackerDB.tab)
    local d, t = OverallProgress()
    overallBar:SetProgress(d, t, string.format("%d%% overall", math.floor(d / math.max(1, t) * 100 + 0.5)))

    UpdateMinimapButtonPosition()
    minimapButton:SetShown(FGT.Setting("minimap"))
    -- re-place once the minimap has its final size after login
    if C_Timer and C_Timer.After then C_Timer.After(1, UpdateMinimapButtonPosition) end

    if FGT.firstRun then
        print(TAG .. "welcome! Type |cffffffff/goals|r or click the minimap button, then add goals from the Goal Library.")
    end
    self:UnregisterEvent("ADDON_LOADED")
end)

-- Handy for other code (and testing) to jump to a goal.
FGT.SelectGoal = function(id) SelectGoal(id) end
FGT.headerRows = headerRowPool
FGT.stepRows = stepRowPool

do -- scoped (200-local budget)
-- ============================================================
-- Keep the roster current
-- ============================================================
-- Records the logged-in character on login, every XP tick and every
-- level up, then refreshes the window if it's open. XP ticks are
-- throttled to one redraw per second.
local lastRedraw = 0
local function RefreshOpenWindow()
    FGT.CheckGoalCompletions() -- announces goals finished while closed
    if not main:IsShown() then return end
    if ForeverGoalTrackerDB and ForeverGoalTrackerDB.tab == "library" and FGT.LayoutLibrary then
        FGT.LayoutLibrary()
        if FGT.RefreshOverall then FGT.RefreshOverall() end
    elseif selectedId then
        SelectGoal(selectedId, true)
    end
end

-- Full scan + rule pass. Bag and money events can fire in bursts, so
-- they're coalesced into one scan half a second after the last one.
local function ScanNow(announce)
    RecordCharacter()
    local changed = ApplyAutoRules()
    if changed > 0 and announce and not FGT.firstRun and FGT.Setting("stepChat") then
        print(TAG .. string.format("%d step%s checked off automatically.",
            changed, changed == 1 and "" or "s"))
    end
    RefreshOpenWindow()
end

-- ============================================================
-- Edit goal: goals built on one number (gold, honorable kills) carry
-- a `target` in their data. Right-click > Edit goal (or the pencil on the goal page) saves the
-- player's number in DB.targets[id]; the name and steps are rebuilt from
-- it (each step a fraction of the target, rounded to two significant
-- figures), and the goal's ticks are re-checked from scratch.
-- ============================================================
do
    local function Nice(v)
        if v < 100 then return math.max(1, math.floor(v + 0.5)) end
        local mag = 10 ^ (math.floor(math.log10(v)) - 1)
        return math.floor(v / mag + 0.5) * mag
    end
    local function Commas(n)
        local s = tostring(math.floor(n))
        while true do
            local k
            s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
            if k == 0 then return s end
        end
    end
    FGT.Commas = Commas

    function FGT.TargetOf(goal)
        local t = goal.target
        if not t then return nil end
        local saved = ForeverGoalTrackerDB and ForeverGoalTrackerDB.targets and ForeverGoalTrackerDB.targets[goal.id]
        return saved or t.default
    end

    function FGT.ApplyTargets()
        for _, goal in ipairs(FGT.goals) do
            local t = goal.target
            if t then
                local value = FGT.TargetOf(goal)
                if t.name then
                    goal.name = string.format(t.name, Commas(value))
                    -- cards set their name once when built
                    local row, card = goalRows[goal.id], FGT.libCards and FGT.libCards[goal.id]
                    if row then row.name:SetText(goal.short or goal.name) end
                    if card then card.name:SetText(goal.name) end
                end
                for i, frac in ipairs(t.marks) do
                    -- a goal with a `one` text always starts at its first (Duelist: first duel)
                    local n = (i == 1 and t.one) and 1 or (frac == 1) and value or Nice(value * frac)
                    local step = goal.steps[i]
                    step.text = (n == 1 and t.one) or string.format(t.step, Commas(n))
                    step.auto = step.auto or {}
                    if t.kind == "money" then step.auto.money = n * 10000
                    elseif t.kind == "stat" then step.auto.stat = { id = t.stat, value = n, what = t.what }
                    else step.auto[t.kind] = n end
                end
            end
        end
    end

    -- value nil: back to the default
    function FGT.SetTarget(goal, value)
        local DB = ForeverGoalTrackerDB
        if not (DB and goal.target) then return end
        DB.targets = DB.targets or {}
        if value == goal.target.default then value = nil end
        DB.targets[goal.id] = value
        FGT.ApplyTargets()
        -- the old ticks were for other numbers: check again from scratch
        DB.progress[goal.id] = {}
        if FGT.resetUndo and FGT.resetUndo.id == goal.id then FGT.resetUndo = nil end
        FGT.quietCelebrate = true -- a lower target you already reach: no fireworks
        ApplyAutoRules()
        LayoutGoalList()
        RefreshOpenWindow()
        FGT.quietCelebrate = nil
        print(TAG .. goal.name .. ": target set to " .. Commas(FGT.TargetOf(goal)) .. " " .. goal.target.unit .. ".")
    end

    -- The card: goal name, a number box, Save, and "Reset to default".
    function FGT.CloseTargetCard()
        local T = FGT.targetCard
        if T then T:Hide(); T.catcher:Hide(); T.box:ClearFocus() end
    end

    function FGT.OpenTargetCard(goal)
        FGT.CloseNoteCard(true)
        local T = FGT.targetCard
        if not T then
            T = CreateFrame("Frame", nil, main, "BackdropTemplate")
            T:SetFrameLevel(main:GetFrameLevel() + 60)
            T:SetClampedToScreen(true)
            T:SetSize(260, 146)
            Etch(T, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
            T:EnableMouse(true)
            T.catcher = CreateFrame("Button", nil, main)
            T.catcher:SetAllPoints(main)
            T.catcher:SetFrameLevel(main:GetFrameLevel() + 55)
            T.catcher:RegisterForClicks("AnyUp")
            T.catcher:SetScript("OnClick", FGT.CloseTargetCard)

            T.title = NewTitleString(T, 13)
            T.title:SetPoint("TOPLEFT", 14, -14)
            T.title:SetText("Edit goal")
            T.sub = NewFontString(T, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
            T.sub:SetPoint("TOPLEFT", T.title, "BOTTOMLEFT", 0, -4)
            T.sub:SetPoint("RIGHT", T, "RIGHT", -14, 0)
            T.sub:SetJustifyH("LEFT")

            T.box = CreateFrame("EditBox", nil, T, "BackdropTemplate")
            T.box:SetSize(130, 24)
            T.box:SetPoint("TOPLEFT", T.sub, "BOTTOMLEFT", 0, -12)
            Skin(T.box, { 0, 0, 0, 0.6 }, C.BOX_RING)
            T.box:SetAutoFocus(false)
            T.box:SetFont(FONT, 12, "")
            T.box:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
            T.box:SetTextInsets(8, 8, 0, 0)
            T.box:SetMaxLetters(9)
            T.unit = NewFontString(T, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
            T.unit:SetPoint("LEFT", T.box, "RIGHT", 8, 0)
            T.warn = NewFontString(T, 10, "", 1.00, 0.50, 0.42)
            T.warn:SetPoint("TOPLEFT", T.box, "BOTTOMLEFT", 0, -6)

            T.save = CreateFrame("Button", nil, T, "BackdropTemplate")
            T.save:SetSize(90, 24)
            T.save:SetPoint("BOTTOMLEFT", T, "BOTTOMLEFT", 14, 14)
            Etch(T.save, STYLE.button, 10)
            T.save.text = NewFontString(T.save, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
            T.save.text:SetPoint("CENTER")
            T.save.text:SetText("Save")
            T.save:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
            T.save:SetScript("OnLeave", function(self) self:SetEtch(STYLE.button) end)

            T.reset = CreateFrame("Button", nil, T)
            T.reset.text = NewFontString(T.reset, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
            T.reset.text:SetPoint("CENTER")
            T.reset:SetPoint("LEFT", T.save, "RIGHT", 10, 0)
            T.reset:SetScript("OnEnter", function(self) self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3]) end)
            T.reset:SetScript("OnLeave", function(self) self.text:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3]) end)
            T.reset:SetScript("OnClick", function()
                local g = T.goal
                FGT.CloseTargetCard()
                FGT.SetTarget(g, nil)
            end)

            local function Save()
                local t = T.goal.target
                local n = tonumber(((T.box:GetText() or ""):gsub("[,%.%s]", "")))
                if not n or n < t.min or n > t.max then
                    T.warn:SetText("Pick a number from " .. Commas(t.min) .. " to " .. Commas(t.max) .. ".")
                    return
                end
                local g = T.goal
                FGT.CloseTargetCard()
                FGT.SetTarget(g, math.floor(n))
            end
            T.save:SetScript("OnClick", Save)
            T.box:SetScript("OnEnterPressed", Save)
            T.box:SetScript("OnEscapePressed", FGT.CloseTargetCard)
            T.box:SetScript("OnTextChanged", function() T.warn:SetText("") end)
            -- new frames start shown
            T:Hide()
            T.catcher:Hide()
            FGT.targetCard = T
        end

        T.goal = goal
        local t = goal.target
        T.sub:SetText(goal.name)
        T.unit:SetText(t.unit)
        T.box:SetText(Commas(FGT.TargetOf(goal)))
        T.warn:SetText("")
        local custom = FGT.TargetOf(goal) ~= t.default
        T.reset.text:SetText("Reset to " .. Commas(t.default))
        T.reset:SetSize(math.ceil(T.reset.text:GetStringWidth()) + 8, 24)
        T.reset:SetShown(custom)

        local x, y = GetCursorPosition()
        local scale = T:GetEffectiveScale()
        T:ClearAllPoints()
        T:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)
        T:Show()
        T.catcher:Show()
        T.box:SetFocus()
        T.box:HighlightText()
    end
end

-- ============================================================
-- Item and Wowhead links on steps. A step whose rule names an item
-- (set pieces, materials to gather) shows the game's item tooltip on
-- hover and links the item in chat on shift-click; right-click opens a
-- small card with the Wowhead page (item, or else quest) selected for
-- Ctrl+C, since addons can't open a browser.
-- ============================================================
do
    -- items whose name or quality wasn't loaded yet when their step was
    -- drawn; the open goal redraws when the game sends their details
    local waiting = {}

    -- entry: the step itself, whose `links` name other items the text
    -- mentions ({ { id, name }, ... }: Lok'delar's Ancient Rune Etched Stave)
    function FGT.SetStepLinks(row, rule, entry)
        row.itemId = rule and AsList(rule.item)[1] or nil
        row.questId = rule and (AsList(rule.quest)[1] or AsList(rule.questTaken)[1]) or nil
        row.itemNames = rule and rule.owned and AsList(rule.owned) or nil
        row.extraLinks = type(entry) == "table" and entry.links or nil
        FGT.LinkItemName(row)
    end

    -- standard WoW quality colors, for when the game can't tell us
    local QUALITY_HEX = { [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd", [4] = "a335ee", [5] = "ff8000" }

    -- Item names inside the step text become links in their quality color
    -- (purple epic, blue rare...), so hovering a name shows the item
    -- (Karl). Colors come from the game, or else from the goal's data
    -- (FGT.stepQuality: set pieces stay purple even where Forever removed
    -- them), or white. Names come from the game or our data; a plural "s"
    -- joins the link ("Elementium Bars").
    function FGT.LinkItemName(row)
        local text = row.text:GetText()
        -- (names already inside a link are skipped below, so {item:} tags
        -- and a second pass are safe)
        if type(text) ~= "string" then return end
        -- { id, names... }: the step's extra items first, then the rule's
        -- first item, so a longer name is linked before a shorter one it
        -- holds ("Eye of Sulfuras" before "Sulfuras")
        local items = {}
        for _, l in ipairs(row.extraLinks or {}) do table.insert(items, { l[1], { l[2] }, l.variants and l }) end
        if row.itemId then
            local names = {}
            for _, n in ipairs(row.itemNames or {}) do table.insert(names, n) end
            table.insert(items, { row.itemId, names })
        end
        local done = {}
        for _, it in ipairs(items) do
            local id, names, variants = it[1], it[2], it[3]
            -- a mount type sold in several colors ("Swift Ram"): its own link,
            -- whose tooltip lists the colors (FGT.ShowVariantsTip)
            local linkType = "item:" .. id
            if variants then
                FGT.variants = FGT.variants or {}
                FGT.variants[id] = { name = names[1], items = variants.variants, npc = variants.npc, vendor = variants.vendor }
                linkType = "fgtvariants:" .. id
            end
            local name, _, quality = FGT.ItemInfo(id)
            if variants then name = nil end -- "Swift Ram", not "Swift Brown Ram"
            if not name then
                -- (never ask again for an item the game said it doesn't have:
                -- its "no" answer redrew the list, which asked again, in a loop)
                if not variants and not FGT.itemMissing[id] then
                    waiting[id] = true
                    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
                end
            else
                table.insert(names, 1, name)
                -- "Lok'delar, Stave of the Ancient Keepers" is "Lok'delar" in steps
                local short = name:match("^(.-), ")
                if short then table.insert(names, 2, short) end
            end
            quality = quality or FGT.stepQuality
            -- white and grey items would vanish in the near-white step text,
            -- so they get a pale parchment tone instead (softer than the gold
            -- goal links); green and up keep the game's quality colors (Karl)
            local hex = (quality == 1 and "f0dcb0") or (quality == 0 and "b3a68c") or QUALITY_HEX[quality] or "f0dcb0"
            local color = "|cff" .. hex
            -- drawn before the game sent the item: remember the color, so
            -- the real one can fade in when it arrives
            if not name and not variants then FGT.linkPrevHex[id] = hex end
            local linked = false
            for _, n in ipairs(names) do
                -- the first spot that isn't already inside a link ('Rise,
                -- Thunderfury!' is a quest link; the item comes after it)
                local from = 1
                while not done[n] and not linked do
                    local s, e = text:find(n, from, true)
                    if not s then break end
                    if not text:sub(1, s - 1):find("|H[^|]*|h[^|]*$") then -- not inside a link
                        if text:sub(e + 1, e + 1) == "s" then e = e + 1 end
                        text = text:sub(1, s - 1) .. color .. "|H" .. linkType .. "|h"
                            .. text:sub(s, e) .. "|h|r" .. text:sub(e + 1)
                        done[n] = true
                        linked = true
                    else
                        from = e + 1
                    end
                end
                if linked then break end
            end
        end
        row.text:SetText(text)
    end

    -- Items the game can't give us: Forever keeps new items (the raid
    -- sets) hidden until players find them after launch, so their details
    -- never arrive. The server says so (success = false), or we give up
    -- after a couple of seconds (FGT.itemAskedAt).
    FGT.itemMissing, FGT.itemAskedAt = {}, {}
    local function Unavailable(id)
        local asked = FGT.itemAskedAt[id]
        return FGT.itemMissing[id] or (asked and GetTime() - asked > 2)
    end
    FGT.ItemUnavailable = Unavailable

    -- {item:ID:name} in steps and tips (FGT.LinkText): the item's link in
    -- its quality color (white and grey items in parchment, like step
    -- links); asks the game for the item so the page redraws when it comes
    function FGT.ItemTag(id, label)
        local _, _, q = FGT.ItemInfo(id)
        if not q and not FGT.itemMissing[id] then
            waiting[id] = true
            if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        end
        local hex = (q == 1 and "f0dcb0") or (q == 0 and "b3a68c") or QUALITY_HEX[q] or "f0dcb0"
        if not q then FGT.linkPrevHex[id] = hex end
        return "|cff" .. hex .. "|Hitem:" .. id .. "|h" .. label .. "|h|r"
    end

    local f = CreateFrame("Frame")
    pcall(f.RegisterEvent, f, "GET_ITEM_INFO_RECEIVED")
    f:SetScript("OnEvent", function(_, _, id, ok)
        if ok == false then
            FGT.itemMissing[id] = true
            waiting[id] = nil -- nothing new to draw
        end
        -- the open tooltip was waiting for this item: show the real one now
        if FGT.tip and FGT.tip.id == id and GameTooltip:IsOwned(FGT.tip.owner) then
            FGT.ShowItemTip(FGT.tip.owner, id, FGT.tip.rule, FGT.tip.name, FGT.tip.compare)
        end
        if ok == false or not waiting[id] then return end
        waiting[id] = nil
        -- the redraw below lands in 0.3 s; the link eases to its color from there
        FGT.itemFade[id] = { GetTime() + 0.3, FGT.linkPrevHex[id] or "e8e8e8" }
        if f.pending then return end
        f.pending = true
        C_Timer.After(0.3, function() -- several items often arrive together
            f.pending = nil
            if main:IsShown() and selectedId then SelectGoal(selectedId, true) end
        end)
    end)

    -- The game's tooltip for an item, at the cursor (Karl), then how the
    -- step tracks it and what clicks do.
    -- name: the item's name from our data, shown when the game doesn't have it
    -- compare: also show the game's comparison with what you're wearing
    function FGT.ShowItemTip(owner, id, rule, name, compare)
        FGT.tip = { owner = owner, id = id, rule = rule, name = name, compare = compare }
        GameTooltip.fgtNeedsItem = nil
        GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
        local known = FGT.ItemInfo(id)
        if known then
            GameTooltip:SetHyperlink("item:" .. id)
        else
            -- not loaded: ask once, say "loading" briefly, then say it isn't
            -- in the game yet instead of the game's endless "Retrieving..."
            if not FGT.itemMissing[id] and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
            GameTooltip:AddLine(name or "Item", 1, 1, 1)
            if Unavailable(id) then
                -- WoW Forever hides every item until a player finds one after
                -- launch (Wowhead: "Item #... doesn't exist"), Classic ones
                -- included, so there it's "not revealed yet". On Classic Era
                -- an item the game can't give really isn't in the game.
                if FGT.isForever then
                    GameTooltip:AddLine("Not revealed yet", 1.00, 0.50, 0.42)
                    GameTooltip:AddLine("WoW Forever shows this item's details once players find it after launch.",
                        C.INK2[1], C.INK2[2], C.INK2[3], true)
                else
                    GameTooltip:AddLine("Not in the game", 1.00, 0.50, 0.42)
                    GameTooltip:AddLine("The game has no details for this item.", C.INK2[1], C.INK2[2], C.INK2[3], true)
                end
            else
                FGT.itemAskedAt[id] = FGT.itemAskedAt[id] or GetTime()
                GameTooltip:AddLine("Loading item details...", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
                C_Timer.After(2.1, function() -- still hovering? show the outcome
                    if FGT.tip and FGT.tip.id == id and GameTooltip:IsOwned(owner) then
                        FGT.ShowItemTip(owner, id, rule, name, compare)
                    end
                end)
            end
        end
        if rule then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Checks itself off when " .. DescribeRule(rule) .. ".", C.TITLE[1], C.TITLE[2], C.TITLE[3], true)
            local now = RuleReadout(rule)
            if now then
                GameTooltip:AddDoubleLine("Right now", now, C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], 1, 0.82, 0)
            end
        end
        FGT.AddItemNeeds(GameTooltip, id)
        if known and FGT.ItemCanPreview(id) then
            GameTooltip:AddLine("Ctrl-click to try it on.", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
        end
        if not compare then
            GameTooltip:AddLine(known and "Shift-click to link it in chat. Right-click for its Wowhead link."
                or "Right-click for its Wowhead link.", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
        end
        GameTooltip:Show()
        -- the game's side-by-side comparison with your equipped item
        if compare and known and GameTooltip_ShowCompareItem then pcall(GameTooltip_ShowCompareItem, GameTooltip) end
    end

    -- A mount type sold in several colors ("Swift Ram", Karl): its name in
    -- epic purple, then each color with its icon, marked Owned when any
    -- of your characters has it (in bags, or learned in the mount
    -- collection), then how the step tracks it.
    function FGT.ShowVariantsTip(owner, firstId, rule)
        local v = FGT.variants and FGT.variants[firstId]
        if not v then return end
        local EPIC = { 0.64, 0.21, 0.93 }
        GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
        GameTooltip:AddLine(v.name, EPIC[1], EPIC[2], EPIC[3])
        GameTooltip:AddLine(string.format("Epic mount, sold in %d colors:", #v.items), 1, 1, 1)
        for _, it in ipairs(v.items) do
            local id, ourName = it[1], it[2]
            local name = FGT.ItemInfo(id) or ourName
            local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
                or (GetItemIcon and GetItemIcon(id))
            local owned = ItemTotal({ id }) > 0 or OwnsName(function(n) return n == name or n == ourName end)
            GameTooltip:AddDoubleLine((icon and ("|T" .. icon .. ":16:16|t ") or "") .. name,
                owned and "Owned" or "", EPIC[1], EPIC[2], EPIC[3], C.DONE[1], C.DONE[2], C.DONE[3])
        end
        if rule then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Checks itself off when you own any of them.", C.TITLE[1], C.TITLE[2], C.TITLE[3], true)
        end
        GameTooltip:AddLine(v.npc and ("Right-click for " .. v.vendor .. "'s Wowhead page, with every color.")
            or "Right-click for the Wowhead link.", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3], true)
        GameTooltip:Show()
    end

    -- a mount type's Wowhead link: its vendor's Sells tab (every color), else the first color
    function FGT.OpenVariantsWowhead(firstId)
        local v = FGT.variants and FGT.variants[firstId]
        if v and v.npc then
            FGT.OpenWowheadCard("npc", v.npc, v.name .. ": every color, sold by " .. v.vendor, "#sells")
        else
            FGT.OpenWowheadCard("item", firstId, v and v.name)
        end
    end

    -- puts the item's link in the chat box (opening it if needed)
    function FGT.InsertItemLink(id)
        local _, link = FGT.ItemInfo(id)
        if not link and Unavailable(id) then
            print(TAG .. (FGT.isForever and "that item isn't revealed in WoW Forever yet, so it can't be linked."
                or "that item isn't in the game, so it can't be linked."))
        elseif not link then
            FGT.itemAskedAt[id] = FGT.itemAskedAt[id] or GetTime()
            if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
            print(TAG .. "that item's details are still loading. Shift-click again in a moment.")
        elseif not (ChatEdit_InsertLink and ChatEdit_InsertLink(link)) then
            if ChatFrame_OpenChat then ChatFrame_OpenChat(link) end
        end
    end

    -- true when the click was a link action (the step doesn't tick)
    function FGT.StepLinkClick(row, button)
        if FGT.overLink then return true end -- the name's own link handled it
        if button == "RightButton" then
            if row.itemId and FGT.variants and FGT.variants[row.itemId] then
                GameTooltip:Hide()
                FGT.OpenVariantsWowhead(row.itemId)
            elseif row.itemId or row.questId then
                GameTooltip:Hide()
                FGT.OpenWowheadCard(row.itemId and "item" or "quest", row.itemId or row.questId, row.text:GetText())
            end
            return true
        end
        if IsShiftKeyDown() and row.itemId then
            FGT.InsertItemLink(row.itemId)
            return true
        end
        if FGT.PreviewItemClick(row.itemId, button) then return true end
        return false
    end

    -- The card: "Wowhead link", what it's for, the address selected.
    function FGT.CloseWowheadCard()
        local K = FGT.wowheadCard
        if K then K:Hide(); K.catcher:Hide(); K.box:ClearFocus() end
    end

    -- kind: item, quest or npc; anchor: a page section, like "#sells"
    -- npc: an FGT.NPCS entry; its card also shows where they stand and a
    -- button for the map pin (or TomTom waypoint)
    function FGT.OpenWowheadCard(kind, id, label, anchor, npc)
        local K = FGT.wowheadCard
        if not K then
            K = CreateFrame("Frame", nil, main, "BackdropTemplate")
            K:SetFrameLevel(main:GetFrameLevel() + 60)
            K:SetClampedToScreen(true)
            K:SetSize(340, 112)
            Etch(K, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
            K:EnableMouse(true)
            K.catcher = CreateFrame("Button", nil, main)
            K.catcher:SetAllPoints(main)
            K.catcher:SetFrameLevel(main:GetFrameLevel() + 55)
            K.catcher:RegisterForClicks("AnyUp")
            K.catcher:SetScript("OnClick", FGT.CloseWowheadCard)
            K.title = NewTitleString(K, 13)
            K.title:SetPoint("TOPLEFT", 14, -12)
            K.title:SetText("Wowhead link")
            K.sub = NewFontString(K, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
            K.sub:SetPoint("TOPLEFT", K.title, "BOTTOMLEFT", 0, -4)
            K.sub:SetPoint("RIGHT", K, "RIGHT", -14, 0)
            K.sub:SetJustifyH("LEFT")
            K.sub:SetWordWrap(false)
            K.box = CreateFrame("EditBox", nil, K, "BackdropTemplate")
            K.box:SetHeight(24)
            K.box:SetPoint("TOPLEFT", K.sub, "BOTTOMLEFT", 0, -10)
            K.box:SetPoint("RIGHT", K, "RIGHT", -14, 0)
            Skin(K.box, { 0, 0, 0, 0.6 }, C.BOX_RING)
            K.box:SetAutoFocus(false)
            K.box:SetFont(FONT, 11, "")
            K.box:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
            K.box:SetTextInsets(8, 8, 0, 0)
            -- the address can't be edited: typing puts it back
            K.box:SetScript("OnTextChanged", function(self, user)
                if user then self:SetText(K.url); self:HighlightText() end
            end)
            K.box:SetScript("OnEscapePressed", FGT.CloseWowheadCard)
            K.box:SetScript("OnEnterPressed", FGT.CloseWowheadCard)
            K.box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
            K.hint = NewFontString(K, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
            K.hint:SetPoint("TOPLEFT", K.box, "BOTTOMLEFT", 0, -6)
            K.hint:SetText("Press Ctrl+C to copy, then paste it into your browser.")
            -- NPC cards: where they stand, and a map button
            K.place = NewFontString(K, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
            K.place:SetPoint("TOPLEFT", K.sub, "BOTTOMLEFT", 0, -10)
            K.place:SetPoint("RIGHT", K, "RIGHT", -14, 0)
            K.place:SetJustifyH("LEFT")
            K.map = CreateFrame("Button", nil, K, "BackdropTemplate")
            Etch(K.map, STYLE.button, 8)
            K.map.text = NewFontString(K.map, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
            K.map.text:SetPoint("CENTER", 0, 0)
            function K.map:SetLabel(t)
                self.text:SetText(t)
                self:SetSize(math.max(64, math.ceil(self.text:GetStringWidth()) + 20), 22)
            end
            K.map:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
            K.map:SetScript("OnLeave", function(self) self:SetEtch(STYLE.button) end)
            K.map:SetScript("OnClick", function()
                if K.npc then FGT.ShowNpcOnMap(K.npc.id) end
                FGT.CloseWowheadCard()
            end)
            K.map:SetPoint("TOPLEFT", K.place, "BOTTOMLEFT", 0, -8)
            -- new frames start shown
            K:Hide()
            K.catcher:Hide()
            FGT.wowheadCard = K
        end
        local site = FGT.isForever and "forever" or "classic"
        if kind == "search" then -- (per-class quests have no single page)
            K.url = string.format("https://www.wowhead.com/%s/search?q=%s", site, (label or ""):gsub(" ", "+"))
        else
            K.url = string.format("https://www.wowhead.com/%s/%s=%d", site, kind, id) .. (anchor or "")
        end
        local name = kind == "item" and not anchor and FGT.ItemInfo(id) or nil
        K.sub:SetText(name or (label and label:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")) or "")
        K.box:SetText(K.url)
        -- the URL box sits under the NPC's place and map button, if any
        K.npc = npc
        K.box:ClearAllPoints()
        if npc then
            K.title:SetText(npc.name)
            K.sub:SetText(npc.tag and ("<" .. npc.tag .. ">") or (npc.disguise and ("Found as " .. npc.disguise) or ""))
            local note = FGT.NpcNote(npc)
            local nr, ng, nb = FGT.NpcNoteColor(npc)
            K.place:SetText((npc.map and (npc.zone .. "  " .. string.format("%.1f, %.1f", npc.x, npc.y)) or (npc.where or ""))
                .. (note and string.format("\n|cff%02x%02x%02x%s|r", nr * 255, ng * 255, nb * 255, note) or ""))
            K.place:Show()
            K.map:SetShown(npc.map and true or false)
            K.map:SetLabel(FGT.UseTomTom() and "Set TomTom waypoint" or "Show on map")
            K.box:SetPoint("TOPLEFT", npc.map and K.map or K.place, "BOTTOMLEFT", 0, -10)
            K:SetHeight((npc.map and 176 or 142) + (note and 14 or 0) + ((not npc.map and npc.where) and 14 or 0))
        else
            K.title:SetText("Wowhead link")
            K.place:Hide()
            K.map:Hide()
            K.box:SetPoint("TOPLEFT", K.sub, "BOTTOMLEFT", 0, -10)
            K:SetHeight(112)
        end
        K.box:SetPoint("RIGHT", K, "RIGHT", -14, 0)
        local x, y = GetCursorPosition()
        local scale = K:GetEffectiveScale()
        K:ClearAllPoints()
        K:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)
        K:Show()
        K.catcher:Show()
        K.box:SetFocus()
        K.box:HighlightText()
    end
end

local scanPending = false
local function ScanSoon()
    if scanPending then return end
    scanPending = true
    local run = function() scanPending = false; ScanNow(true) end
    if C_Timer and C_Timer.After then C_Timer.After(0.5, run) else run() end
end

local rosterWatcher = CreateFrame("Frame")
for _, ev in ipairs({
    "PLAYER_LOGIN", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "PLAYER_LOGOUT",
    "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_MONEY",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED",
    "UPDATE_FACTION", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "SKILL_LINES_CHANGED",
    "NEW_MOUNT_ADDED", "COMPANION_LEARNED", "PLAYER_PVP_RANK_CHANGED", "PLAYER_PVP_KILLS_CHANGED",
    "PLAYER_GUILD_UPDATE", "FRIENDLIST_UPDATE", "DUEL_FINISHED",
}) do
    pcall(rosterWatcher.RegisterEvent, rosterWatcher, ev) -- skip events a client lacks
end
-- Boss kills: ENCOUNTER_END (success) and BOSS_KILL both report the
-- encounter's name; it's stored on the character that was there.
local function RecordBossKill(name)
    if not (name and ForeverGoalTrackerDB) then return end
    RecordCharacter()
    local me = Roster()[CharKey()]
    if not me then return end
    me.bosses = me.bosses or {}
    me.bosses[name] = true
    local changed = ApplyAutoRules()
    if changed > 0 and FGT.Setting("stepChat") then
        print(TAG .. string.format("%s defeated, %d step%s checked off.",
            name, changed, changed == 1 and "" or "s"))
    end
    RefreshOpenWindow()
end
pcall(rosterWatcher.RegisterEvent, rosterWatcher, "ENCOUNTER_END")
pcall(rosterWatcher.RegisterEvent, rosterWatcher, "BOSS_KILL")

rosterWatcher:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4, arg5)
    if event == "ENCOUNTER_END" then
        if arg5 == 1 then RecordBossKill(arg2) end -- id, name, difficulty, size, success
        return
    end
    if event == "BOSS_KILL" then RecordBossKill(arg2); return end -- id, name
    if event == "BANKFRAME_OPENED" then bankOpen = true end
    if event == "BANKFRAME_CLOSED" then bankOpen = false; return end
    if event == "PLAYER_LOGOUT" then
        -- last save on the way out. FGT.loggingOut skips the Statistics and
        -- friends reads: the game tears down systems during logout, and
        -- GetStatistic then hit ASSERT(s_lootInitialized) and crashed the
        -- Forever beta client on exit (2.6.0). The values read while playing
        -- are already saved.
        FGT.loggingOut = true
        RecordCharacter()
        return
    end
    if event == "DUEL_FINISHED" then
        -- the duel counters update a moment after the duel ends
        C_Timer.After(2, function() FGT.forceStats = true; ScanSoon() end)
        return
    end

    if event == "PLAYER_LEVEL_UP" then
        local before = Roster()[CharKey()]
        local oldLevel = before and before.level
        RecordCharacter()
        local me = Roster()[CharKey()]
        if me and arg1 then
            -- UnitLevel can lag a frame behind the event; trust the event.
            me.level, me.xp = arg1, 0
            if arg1 >= MAX_LEVEL and (oldLevel or 0) < MAX_LEVEL and FGT.Setting("stepChat") then
                print(TAG .. string.format("%s reached %d. Class marked complete.", me.name, MAX_LEVEL))
            end
        end
        ApplyAutoRules()
        RefreshOpenWindow()
        return
    end

    if event == "PLAYER_XP_UPDATE" then
        -- XP only moves level bars; skip the full scan, throttle redraws.
        local me = Roster()[CharKey()]
        if me then
            me.xp = UnitXP and UnitXP("player") or me.xp
            me.xpMax = UnitXPMax and UnitXPMax("player") or me.xpMax
        end
        local now = GetTime and GetTime() or 0
        if now - lastRedraw < 1 then return end
        lastRedraw = now
        RefreshOpenWindow()
        return
    end

    if event == "PLAYER_LOGIN" then
        -- ask the server for the friends list (FRIENDLIST_UPDATE rescans)
        pcall(function()
            if C_FriendList and C_FriendList.ShowFriends then C_FriendList.ShowFriends()
            elseif ShowFriends then ShowFriends() end
        end)
        ScanNow(true)
        if not FGT.firstRun then FGT.LoginGreeting() end
        if FGT.Setting("openOnLogin") and not main:IsShown() then FGT.ToggleFrame() end
        return
    end
    ScanSoon()
end)

end

-- ============================================================
-- Demo mode (/goals demo 1-4, /goals demo off): staged goals and
-- progress for gallery screenshots. Your real data is copied to
-- DB.demoBackup first and put back on "off" (it survives a /reload in
-- between). Automatic ticking pauses while a demo is on.
-- ============================================================
do
local SAVED = { "active", "activeParts", "progress", "favorites", "goalsDone", "goalDates", "selected", "tab", "targets",
    "interests", "welcomeSeen" } -- the wizard scenes save interests on close

-- scene extras that live outside the saved data: undo them between scenes
local function ClearExtras()
    if FGT.demoLock then FGT.lockouts[FGT.demoLock] = nil; FGT.demoLock = nil end
    FGT.demoFind = nil
    if FGT.CloseWelcome then FGT.CloseWelcome(true) end
end

local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = Copy(x) end
    return t
end

-- One staged roster shared by every scene, so shots match each other.
local function Stage(DB)
    DB.active, DB.activeParts, DB.progress = {}, {}, {}
    DB.favorites, DB.goalsDone, DB.goalDates = {}, {}, {}
    local day = 86400
    -- flat goals: tick the first share of their steps (1 = finished)
    local function Flat(id, share, daysAgo)
        local g = FGT.GoalById(id)
        if not g then return end
        DB.active[id] = true
        local n = math.floor(#g.steps * share + 0.5)
        if share > 0 and n == 0 then n = 1 end
        for i = 1, n do SetStepDone(id, i, true) end
        if share >= 1 then
            DB.goalsDone[id] = true
            DB.goalDates[id] = time() - (daysAgo or 3) * day
        end
    end
    Flat("thunderfury", 0.6)
    Flat("atiesh", 0.3)
    Flat("quelserrar", 1, 15)
    Flat("benediction", 1, 4)
    Flat("rep_argentdawn", 0.5)
    Flat("raid_mc", 0.6)
    Flat("att_naxx", 0.5)
    Flat("set_viper", 0.6)
    Flat("ashbringer", 0.4)
    -- Epic Racial Mounts: Human done, Dwarf 4/5, Night Elf 2/5, Gnome 1/5,
    -- and the Skyborne Galestrider (part 9, new in Forever) 2/4.
    DB.activeParts.epicmounts = { [1] = true, [2] = true, [3] = true, [4] = true, [9] = true }
    for si, n in pairs({ [1] = 5, [2] = 4, [3] = 2, [4] = 1, [9] = 2 }) do
        for pi = 1, n do SetStepDone("epicmounts", PieceKey(si, pi), true) end
    end
    DB.favorites = { thunderfury = true, epicmounts = true, atiesh = true }
    return Flat
end

-- The view for each scene. Optional extras (scenes 5 to 7):
--   setup(DB, Flat)  more staged goals or targets, on top of the shared roster
--   welcome = step   opens the welcome wizard with `interests` picked
--   lock = mapId     a pretend raid lockout (the SAVED UNTIL chip)
--   find = true      shows "Find your next goal" (hidden in demos otherwise)
--   bottom = true    scrolls the goal list to the end
local SCENES = {
    [1] = { tab = "tracker", goal = "thunderfury" },                     -- hero: My Goals + a guide
    [2] = { tab = "library", filter = "new", expand = "epicmounts" },    -- New & Updated, Skyborne row
    [3] = { tab = "tracker", goal = "epicmounts",                        -- groups: finished, counts, NEW open
            open = { "epicmounts_9" } },
    [4] = { tab = "tracker", goal = "ashbringer" },                      -- links, tips, Forever notice
    -- welcome wizard over an empty tracker, as a new player sees it
    [5] = { tab = "tracker", welcome = 2, interests = { raid = true, loot = true },   -- interests, two picked
            setup = function(DB) DB.active, DB.activeParts = {}, {} end },
    [6] = { tab = "tracker", welcome = 3, interests = { raid = true, loot = true },   -- goals to get started
            setup = function(DB) DB.active, DB.activeParts = {}, {} end },
    -- what's new in 2.6: Social goals, a changed gold target, the lockout
    -- chip on Molten Core, and "Find your next goal" at the end of the list
    [7] = { tab = "tracker", goal = "raid_mc", lock = 409, find = true, bottom = true,
            setup = function(DB, Flat)
                DB.targets = { gold_5k = 10000 }
                Flat("gold_5k", 0.34)
                Flat("social_guild", 0.5)
                Flat("social_friends", 0.67)
            end },
    -- gallery shot 5: Embrace of the Viper (UPDATED in Forever) open, and
    -- "Find your next goal" at the end of the list
    [8] = { tab = "tracker", goal = "set_viper", find = true, bottom = true,
            setup = function(DB, Flat)
                DB.targets = { gold_5k = 10000 }
                Flat("gold_5k", 0.34)
            end },
}

-- /goals shots: every gallery screenshot in one go (Karl). Black photo
-- backdrop, then each scene in gallery order, a pause for its animations,
-- and the game's Screenshot(); demo off at the end. The game saves them
-- in its Screenshots folder; tools/shots.py crops them to the window and
-- names them (Screenshots/01-my-goals.png ...). Lossless TGA for the run,
-- the player's format and quality put back after.
FGT.SHOTS = {
    { scene = 1, file = "01-my-goals" },
    { scene = 2, file = "02-new-and-updated" },
    { scene = 3, file = "03-epic-mounts" },
    { scene = 4, file = "04-links-and-tips" },
    { scene = 8, file = "05-find-your-next-goal" },
    { scene = 5, file = "06-welcome" },
    { scene = 6, file = "07-suggestions" },
    { scene = 1, settings = true, file = "08-settings" },
}
function FGT.TakeShots()
    if FGT.shooting then print(TAG .. "already taking screenshots.") return end
    if not Screenshot then print(TAG .. "this client can't take screenshots from an addon.") return end
    local getCVar = (C_CVar and C_CVar.GetCVar) or GetCVar
    local setCVar = (C_CVar and C_CVar.SetCVar) or SetCVar
    local saved = getCVar and { getCVar("screenshotFormat"), getCVar("screenshotQuality") } or {}
    if setCVar then pcall(setCVar, "screenshotFormat", "tga"); pcall(setCVar, "screenshotQuality", "10") end
    FGT.shooting = true
    SlashCmdList["FOREVERGOALTRACKER"]("photo black")
    print(TAG .. "taking " .. #FGT.SHOTS .. " screenshots. Keep your mouse off the window.")
    local function Finish(stopped)
        FGT.shooting = nil
        if FGT.CloseSettings then FGT.CloseSettings() end
        FGT.Demo("off")
        SlashCmdList["FOREVERGOALTRACKER"]("photo off")
        if setCVar then
            if saved[1] then pcall(setCVar, "screenshotFormat", saved[1]) end
            if saved[2] then pcall(setCVar, "screenshotQuality", saved[2]) end
        end
        print(TAG .. (stopped and "screenshots stopped (the window closed)." or
            ("done: " .. #FGT.SHOTS .. " screenshots in the game's Screenshots folder. Tell Claude to process the shots.")))
    end
    local function Step(i)
        if not main:IsShown() then Finish(true) return end
        local shot = FGT.SHOTS[i]
        if not shot then Finish() return end
        if FGT.CloseSettings then FGT.CloseSettings() end
        FGT.Demo(tostring(shot.scene))
        if shot.settings and FGT.OpenSettings then FGT.OpenSettings() end
        -- let tabs, fades and the wizard settle, then shoot
        C_Timer.After(i == 1 and 3 or 2.2, function()
            if not main:IsShown() then Finish(true) return end
            -- no stray tooltip (the mouse resting on a character in the world)
            GameTooltip:Hide()
            pcall(Screenshot)
            C_Timer.After(1.2, function() Step(i + 1) end)
        end)
    end
    Step(1)
end

local function Redraw()
    FGT.quietCelebrate = true -- staged finishes shouldn't set off fireworks
    LayoutGoalList()
    RefreshGoalList()
    if FGT.LayoutLibrary then FGT.LayoutLibrary() end
    FGT.quietCelebrate = nil
end

function FGT.Demo(arg)
    local DB = ForeverGoalTrackerDB
    if not DB then return end
    if arg == "off" then
        if not DB.demoBackup then print(TAG .. "demo mode isn't on.") return end
        for _, k in ipairs(SAVED) do DB[k] = DB.demoBackup[k] end
        DB.demoBackup = nil
        ClearExtras()
        if FGT.ApplyTargets then FGT.ApplyTargets() end
        for k in pairs(FGT.sectionOpen) do FGT.sectionOpen[k] = nil end
        if FGT.SetLibraryView then FGT.SetLibraryView("all") end
        FGT.quietCelebrate = true
        if FGT.ShowTab then FGT.ShowTab(DB.tab or "tracker") end
        if DB.selected then SelectGoal(DB.selected, true) end
        FGT.quietCelebrate = nil
        Redraw()
        print(TAG .. "demo off. Your own goals and progress are back.")
        return
    end
    local scene = SCENES[tonumber(arg) or 1]
    if not scene then print(TAG .. "demo scenes are 1 to " .. #SCENES .. ", or /goals demo off.") return end
    if not DB.demoBackup then
        local b = {}
        for _, k in ipairs(SAVED) do b[k] = Copy(DB[k]) end
        DB.demoBackup = b
    end
    ClearExtras()
    local Flat = Stage(DB)
    DB.targets = {}
    if scene.setup then scene.setup(DB, Flat) end
    if FGT.ApplyTargets then FGT.ApplyTargets() end
    if scene.lock then
        FGT.lockouts[scene.lock] = time() + 3 * 86400
        FGT.demoLock = scene.lock
    end
    FGT.demoFind = scene.find
    for k in pairs(FGT.sectionOpen) do FGT.sectionOpen[k] = nil end
    for _, key in ipairs(scene.open or {}) do FGT.sectionOpen[key] = true end
    if not main:IsShown() then FGT.ToggleFrame() end
    FGT.quietCelebrate = true
    listScrollObj.scroll:SetVerticalScroll(0)
    if scene.goal then SelectGoal(scene.goal) end
    if scene.tab == "library" and FGT.SetLibraryView then FGT.SetLibraryView(scene.filter, scene.expand) end
    if FGT.ShowTab then FGT.ShowTab(scene.tab) end
    FGT.quietCelebrate = nil
    Redraw()
    if scene.bottom then
        -- after the list has been measured
        C_Timer.After(0.05, function()
            local s = listScrollObj.scroll
            s:SetVerticalScroll(s:GetVerticalScrollRange())
            listScrollObj:Update()
        end)
    end
    if scene.welcome and FGT.OpenWelcome then FGT.OpenWelcome(scene.welcome, nil, scene.interests) end
    print(TAG .. "demo scene " .. (tonumber(arg) or 1) .. " of " .. #SCENES .. ". Your real data is safe; /goals demo off brings it back.")
end
end

SLASH_FOREVERGOALTRACKER1 = "/goals"
SLASH_FOREVERGOALTRACKER2 = "/fgt"
SLASH_FOREVERGOALTRACKER3 = "/forevergoals"
SlashCmdList["FOREVERGOALTRACKER"] = function(msg)
    msg = tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    local opacity = msg:match("^banneropacity%s*(.*)$")
    if opacity then
        local banner, db = FGT.goalBanner, ForeverGoalTrackerDB
        if not db or not banner.goal or not banner.hasArt then
            print(TAG .. "Open a goal with banner artwork first.")
            return
        end
        local percent = tonumber(opacity)
        if opacity == "reset" or (percent and percent >= 0 and percent <= 100) then
            db.bannerOpacity = db.bannerOpacity or {}
            db.bannerOpacity[banner.goal.id] = opacity ~= "reset" and percent/100 or nil
            banner:SetImageFade(banner.imageFade or 1)
        elseif opacity ~= "" then
            print(TAG .. "Use /goals banneropacity 0-100, or /goals banneropacity reset.")
            return
        end
        print(TAG .. banner.goal.name .. " banner opacity: " .. math.floor(banner:GetArtOpacity()*100+0.5) .. "%.")
        return
    end
    if msg == "testbanner" then
        FGT.TestBanner()
        return
    end
    if msg == "settings" or msg == "options" or msg == "config" then
        FGT.OpenSettings()
        return
    end
    if msg == "shots" then
        FGT.TakeShots()
        return
    end
    local demo = msg:match("^demo%s*(%w*)$")
    if demo then
        FGT.Demo(demo ~= "" and demo or "1")
        return
    end
    -- /goals photo [black|green|white]: a solid full-screen backdrop right
    -- under the window, for clean screenshots of just the panel. Green is
    -- pure #00FF00 so it keys out to transparency. Same command again
    -- (or /goals photo off) turns it off.
    local photo = msg:match("^photo%s*(%a*)$")
    if photo then
        local P = FGT.photoBackdrop
        if not P then
            P = CreateFrame("Frame", nil, UIParent)
            P:SetAllPoints(UIParent)
            P:SetFrameStrata("HIGH")
            P:SetFrameLevel(0) -- the window and its menus sit above it
            P.tex = P:CreateTexture(nil, "BACKGROUND")
            P.tex:SetTexture(SOLID)
            P.tex:SetAllPoints(P)
            P:Hide()
            -- closing the window (Escape, X) also ends photo mode
            main:HookScript("OnHide", function() P:Hide() end)
            FGT.photoBackdrop = P
        end
        local colors = { black = { 0, 0, 0 }, green = { 0, 1, 0 }, white = { 1, 1, 1 } }
        if photo == "off" or (photo == "" and P:IsShown()) then
            P:Hide()
            print(TAG .. "photo mode off.")
            return
        end
        local c = colors[photo] or colors.black
        P.tex:SetVertexColor(c[1], c[2], c[3], 1)
        P:Show()
        if not main:IsShown() then FGT.ToggleFrame() end
        print(TAG .. "photo mode on (" .. (colors[photo] and photo or "black") .. "). Type /goals photo again to turn it off.")
        return
    end
    if msg == "welcome" then
        FGT.OpenWelcome(1) -- the welcome wizard again; your goals stay as they are
        return
    end
    if msg == "stats" then
        -- Saves every statistic the game tracks (Forever's Statistics
        -- window: categories, stat IDs, names, values) into the saved
        -- variables as DB.statsDump, for planning stats-based goals. Read it
        -- from the SavedVariables file after a /reload.
        if not (GetStatisticsCategoryList and GetStatistic) then
            print(TAG .. "this client has no Statistics window.")
            return
        end
        local out, n = {}, 0
        for _, cat in pairs(GetStatisticsCategoryList() or {}) do
            local catName, parent = GetCategoryInfo(cat)
            local num = GetCategoryNumAchievements and GetCategoryNumAchievements(cat) or 0
            for i = 1, num do
                local quantity, skip, statID = GetStatistic(cat, i)
                if statID then
                    local name = select(2, GetAchievementInfo(statID))
                    n = n + 1
                    out[n] = string.format("%s | %s | %d | %s | %s%s", tostring(parent), tostring(catName), statID,
                        tostring(name), tostring(quantity), skip and " | skip" or "")
                end
            end
        end
        ForeverGoalTrackerDB.statsDump = { at = date("%Y-%m-%d %H:%M"), char = UnitName("player"), list = out }
        print(TAG .. string.format("saved %d statistics. Type /reload so they're written to disk.", n))
        return
    end
    if msg == "lockouts" then
        -- What the game reports (same as Raid Info), and which raid goal
        -- each lockout matches, to check the SAVED UNTIL chip's data.
        local n = GetNumSavedInstances and GetNumSavedInstances() or 0
        if n == 0 then print(TAG .. "the game reports no lockouts for this character.") end
        for i = 1, n do
            local name, _, reset, _, locked, extended, _, isRaid, _, _, _, _, _, mapId = GetSavedInstanceInfo(i)
            local goal
            for _, g in ipairs(FGT.goals) do
                if g.instance and (g.instance[1] == mapId or g.instance[2] == name or g.instance[3] == name) then goal = g end
            end
            print(TAG .. string.format("%s (map %s)%s, resets %s%s -> %s", tostring(name), tostring(mapId),
                isRaid and "" or " [dungeon]", reset and reset > 0 and date("%a %b %d at %H:%M", time() + reset) or "?",
                (locked or extended) and "" or " [not locked]", goal and goal.name or "no goal"))
        end
        return
    end
    if msg == "testlockout" then
        -- Preview: pretends this character is saved to the open raid goal's
        -- raid (resets in 3 days) until /reload. Run again to turn it off.
        local goal = selectedId and FGT.GoalById(selectedId)
        local inst = goal and goal.instance
        if not inst then
            print(TAG .. "open a raid goal on My Goals first (Molten Core, Onyxia, Naxxramas...).")
            return
        end
        local on = not FGT.lockouts[inst[1]]
        FGT.lockouts[inst[1]] = on and (time() + 3 * 86400) or nil
        FGT.lockouts[inst[2]] = nil
        SelectGoal(selectedId, true)
        print(TAG .. (on and ("previewing a lockout for " .. inst[2] .. ".") or "lockout preview off."))
        return
    end
    if msg == "addall" then
        -- Testing: every goal this client can show (both factions), with
        -- every part of group goals.
        local DB = ForeverGoalTrackerDB
        local n, first = 0, nil
        for _, g in ipairs(FGT.goals) do
            local ok = not (g.forever == "new" and not FGT.isForever)
                and not (g.needs == "stats" and not FGT.HasStats())
                and not (g.needs == "forever" and not FGT.isForever)
            if ok and not g.libraryOnly and not IsActive(g) then
                if g.group then
                    local sel = DB.activeParts[g.id] or {}
                    DB.activeParts[g.id] = sel
                    for _, part in ipairs(FGT.GroupParts(g)) do sel[part.key] = true end
                else
                    DB.active[g.id] = true
                end
                n = n + 1
                first = first or g.id
            end
        end
        FGT.ShowTab("tracker")
        FGT.SelectGoal(selectedId or first)
        FGT.RefreshOverall()
        if FGT.LayoutLibrary then FGT.LayoutLibrary() end
        print(TAG .. string.format("added %d goal%s to My Goals.", n, n == 1 and "" or "s"))
        return
    end
    if msg == "resetall" or msg == "resetall undo" then
        -- Testing: clears the ticks of every goal on My Goals. Run twice
        -- within 10 seconds to confirm; "/goals resetall undo" brings the
        -- ticks back (until /reload).
        local DB = ForeverGoalTrackerDB
        if msg == "resetall undo" then
            local b = FGT.resetAllBackup
            if not b then print(TAG .. "nothing to undo.") return end
            DB.progress, DB.goalsDone, DB.goalDates = b.progress, b.done, b.dates
            FGT.resetAllBackup = nil
            FGT.quietCelebrate = true
            if selectedId then SelectGoal(selectedId, true) end
            FGT.quietCelebrate = nil
            FGT.RefreshOverall()
            if FGT.LayoutLibrary then FGT.LayoutLibrary() end
            print(TAG .. "progress restored.")
            return
        end
        if not (FGT.resetAllAsked and GetTime() - FGT.resetAllAsked < 10) then
            FGT.resetAllAsked = GetTime()
            print(TAG .. "this clears the ticks on every goal on My Goals. Type |cffffffff/goals resetall|r again within 10 seconds to confirm.")
            return
        end
        FGT.resetAllAsked = nil
        local function Copy(t)
            local out = {}
            for k, v in pairs(t or {}) do out[k] = type(v) == "table" and Copy(v) or v end
            return out
        end
        FGT.resetAllBackup = { progress = Copy(DB.progress), done = Copy(DB.goalsDone), dates = Copy(DB.goalDates) }
        local n = 0
        for _, g in ipairs(ActiveGoals()) do
            DB.progress[g.id] = {}
            if DB.goalsDone then DB.goalsDone[g.id] = nil end
            if DB.goalDates then DB.goalDates[g.id] = nil end
            n = n + 1
        end
        FGT.resetUndo = nil
        if selectedId then SelectGoal(selectedId, true) end
        FGT.RefreshOverall()
        if FGT.LayoutLibrary then FGT.LayoutLibrary() end
        print(TAG .. string.format("reset %d goal%s. Steps the game can check will tick again on the next scan. Undo with |cffffffff/goals resetall undo|r.", n, n == 1 and "" or "s"))
        return
    end
    if msg == "testnew" then
        -- Preview: shows the open goal as "new in Forever" until /reload.
        if not selectedId then
            print(TAG .. "open a goal on My Goals first.")
            return
        end
        FGT.testNew[selectedId] = not FGT.testNew[selectedId] or nil
        SelectGoal(selectedId, true)
        if FGT.LayoutLibrary then FGT.LayoutLibrary() end
        print(TAG .. (FGT.testNew[selectedId] and "previewing this goal as new in Forever." or "preview off."))
        return
    end
    if msg == "reset" then
        -- Manual escape hatch: puts the window back to its default size
        -- and re-centers it, in case it's ever stuck too big, too small,
        -- or somewhere the resize grip can't be reached.
        FGT.ResetWindow() -- same as the Reset button in Settings
        if not main:IsShown() then
            FGT.ToggleFrame()
        end
        print(TAG .. "window size and position reset.")
    else
        FGT.ToggleFrame()
    end
end

do -- scoped (200-local budget)
-- ============================================================
-- Welcome wizard
-- ============================================================
-- Pops over the darkened window the first time it opens, for everyone,
-- once (DB.welcomeSeen; existing players see it after updating too).
--   1. Two choices: pick your own goals / get help (for players who
--      already track goals: keep my goals / help me find more).
--   2. What do you like to do? Six interests, pick any number.
--   3. Goals to get started: suggestions for the logged-in character,
--      ticked, then "Add N goals".
-- Suggestions read the same progress as the tracker, so finished goals
-- are skipped and partly done ones read "Complete ...". Attunements are
-- never suggested (finding those is part of the fun); the raid goals
-- lead there. /goals welcome and Settings open it again.
local W = { picked = {}, list = {} }
FGT.welcome = W

local INTERESTS = {
    { key = "raid",    label = "Raiding",    phrase = "raiding",    icon = { "inv_misc_head_dragon_01" }, art = "raiding" },
    { key = "pvp",     label = "PvP",        phrase = "PvP",        icon = "pvp", art = "pvp" },
    { key = "loot",    label = "Epic Loot",  phrase = "epic loot",  icon = { "inv_sword_39" }, art = "loot" },
    { key = "collect", label = "Collecting", phrase = "collecting", icon = { "ability_mount_ridinghorse" }, art = "collecting" },
    { key = "grind",   label = "The Grind",  phrase = "the grind",  icon = { "inv_misc_coin_02" }, art = "grind" },
    { key = "social",  label = "Social",     phrase = "being social", icon = { "inv_misc_groupneedmore" }, art = "social" },
}
local MAX_ROWS = 6    -- rows in all, so the list fits without scrolling
local MAX_SETS = 2    -- item sets among the suggestions
local MAX_TRACKED = 4 -- matching goals already on My Goals, shown dimmed (only if there's room)

-- English part names in the goal data, by the game's race and class tokens.
local RACE_PART = { Human = "Human", Dwarf = "Dwarf", NightElf = "Night Elf", Gnome = "Gnome", Orc = "Orc",
    Tauren = "Tauren", Scourge = "Undead", Troll = "Troll", Skyborne = "Skyborne" }
local CLASS_PART = { WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid" }
-- Legendary and epic weapons each class can use, best fit first.
local WEAPONS = {
    WARRIOR = { "thunderfury", "quelserrar", "sulfuras", "ashbringer" },
    PALADIN = { "thunderfury", "sulfuras", "quelserrar", "ashbringer" },
    HUNTER  = { "rhokdelar", "lokdelar" },
    ROGUE   = { "thunderfury" },
    PRIEST  = { "benediction", "atiesh" },
    SHAMAN  = { "sulfuras" },
    MAGE    = { "atiesh" },
    WARLOCK = { "atiesh" },
    DRUID   = { "atiesh", "sulfuras" },
}
-- A legendary whose guide already runs through a raid replaces that raid.
local COVERS = { thunderfury = "raid_mc", sulfuras = "raid_mc", atiesh = "raid_naxx", ashbringer = "raid_naxx" }
local PRIMARY = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism",
    "Leatherworking", "Mining", "Skinning", "Tailoring" }

local function Me()
    local raceName, race = UnitRace("player")
    local className, class = UnitClass("player")
    return { race = race, raceName = raceName or "", class = class, className = className or "",
             faction = UnitFactionGroup("player"), level = UnitLevel("player") or 1 }
end

-- Set of the parts whose label starts with `name` ("Warrior - ...",
-- "Warrior", "Alchemy 300"), or nil when the goal has no such part.
local function PartKeys(goal, names)
    local set
    for _, part in ipairs(FGT.GroupParts(goal)) do
        for _, name in ipairs(names) do
            if part.label == name or part.label:sub(1, #name + 1) == name .. " " then
                set = set or {}
                set[part.key] = true
            end
        end
    end
    return set
end

-- Progress over the given parts (all of them when keys is nil),
-- whether or not the goal is on the tracker.
local function Progress(goal, keys)
    local d, t = 0, 0
    if goal.sections then
        for si, section in ipairs(goal.sections) do
            if not keys or keys[si] then
                local a, b = SectionProgress(goal, si, section)
                d, t = d + a, t + b
            end
        end
    elseif goal.autoLevels then
        for i, entry in ipairs(goal.steps) do
            if not keys or keys[i] then
                t = t + MAX_LEVEL
                if IsAutoStep(entry) then d = d + math.floor(AutoStepFraction(entry) * MAX_LEVEL + 1e-6) end
            end
        end
    else
        for i, entry in ipairs(goal.steps) do
            if (not keys or keys[i]) and not FGT.PieceSkipped(entry) then
                t = t + 1
                if IsStepDone(goal.id, i) then d = d + 1 end
            end
        end
    end
    return d, t
end

local function Finished(id)
    local g = FGT.GoalById(id)
    if not g then return true end
    local d, t = Progress(g)
    return t > 0 and d >= t
end

local function OnlyKey(keys)
    local only
    for k in pairs(keys or {}) do
        if only then return nil end
        only = k
    end
    return only
end

-- One suggestion: the goal plus the parts to add (group goals), or nil
-- when it doesn't apply (other faction, Forever-only on Classic Era, or
-- finished). Goals already on My Goals come back with tracked = true:
-- they're listed (dimmed) so you can see they were considered.
local function Entry(me, id, keys, why)
    local parent = FGT.armorCollections[id]
    if parent then
        local key = OnlyKey(keys)
        if not key then return nil end
        id, keys = parent.armorChildren[key].id, nil
    end
    local g = FGT.GoalById(id)
    if not g then return nil end
    if g.faction and g.faction ~= me.faction then return nil end
    if g.forever == "new" and not FGT.isForever then return nil end
    if g.needs == "stats" and not FGT.HasStats() then return nil end
    if g.needs == "forever" and not FGT.isForever then return nil end
    if g.removedInForever and FGT.isForever then return nil end -- can't be finished there
    local set, tracked
    if g.group then
        set = {}
        for k in pairs(keys or {}) do
            if not PartSelected(g, k) then set[k] = true end
        end
        if not next(set) then
            if not keys or not next(keys) then return nil end
            set, tracked = keys, true
        end
    elseif IsActive(g) then
        tracked = true
    end
    -- "Find your next goal": only goals you don't have yet
    if tracked and W.find then return nil end
    local d, t = Progress(g, set)
    if t > 0 and d >= t then return nil end
    local e = { goal = g, keys = set, d = d, t = t, why = why, on = not tracked, tracked = tracked }
    -- blue Forever look: a new part (the Skyborne mount) or a new/updated goal
    local only = OnlyKey(set)
    local look = (only and g.sections and g.sections[only]) or g
    e.word = FGT.ForeverWord(look) or (not g.group and FGT.ForeverWord(g)) or nil
    e.look = e.word and look or nil
    return e
end

-- Display name: the part for one-part picks ("Swift Timber Wolf",
-- "Tier 1: Felheart Raiment"), "Complete ..." once it's partly done.
local function Title(e, me)
    local g = e.goal
    local name = g.name
    local only = OnlyKey(e.keys)
    if g.autoLevels then
        if only then return "Level your " .. me.className .. " to " .. MAX_LEVEL end
        return "Level more classes to " .. MAX_LEVEL
    end
    if g.sections and only then
        local sec = g.sections[only].name
        local what = sec:match(" %- (.+)$") or sec
        if g.id == "epicmounts" or g.id:find("^pvp_set_") then
            name = what -- "Swift Timber Wolf", "Field Marshal's Battlegear"
        else
            name = g.name:gsub(" Set Appearances", ""):gsub(" %(.-%)$", "") .. ": " .. what
        end
    end
    return name
end
W.Title = Title

-- Suggestions for the logged-in character and the picked interests.
local function Suggest(picked)
    local me = Me()
    local seen = {}
    local function push(list, e)
        if e and not seen[e.goal.id] then
            seen[e.goal.id] = true
            table.insert(list, e)
        end
    end

    -- Always: reach 60 if no character has, and this character's epic
    -- mount (Warlocks and Paladins: their class mount instead).
    local fixed = {}
    local has60 = (me.level >= MAX_LEVEL)
    for _, c in pairs(Roster()) do
        if (c.level or 0) >= MAX_LEVEL then has60 = true end
    end
    local leveling = FGT.GoalById("allclasses")
    if not has60 and leveling then
        push(fixed, Entry(me, "allclasses", PartKeys(leveling, { CLASS_PART[me.class] or "" }), "Everything opens up at 60"))
    end
    if me.class == "WARLOCK" then
        push(fixed, Entry(me, "mount_dreadsteed", nil, "The Warlock's own epic mount"))
    elseif me.class == "PALADIN" then
        push(fixed, Entry(me, "mount_charger", nil, "The Paladin's own epic mount"))
    else
        local mounts = FGT.GoalById("epicmounts")
        local keys = mounts and PartKeys(mounts, { RACE_PART[me.race] or "" })
        if keys then
            push(fixed, Entry(me, "epicmounts", keys,
                me.race == "Skyborne" and "The Skyborne's own epic mount" or ("The " .. me.raceName .. " epic mount")))
        end
    end

    -- the character's class set; for classes with several versions (one
    -- per role, Forever sets), only the first, so a suggestion stays one set
    local function ClassPart(id)
        local g = FGT.GoalById(id)
        local keys = g and PartKeys(g, { CLASS_PART[me.class] or "" })
        if not keys then return nil end
        local first
        for k in pairs(keys) do if not first or k < first then first = k end end
        return { [first] = true }
    end
    local ARMOR = { WARRIOR = "plate", PALADIN = "plate", HUNTER = "mail", SHAMAN = "mail",
                    ROGUE = "leather", DRUID = "leather", PRIEST = "cloth", MAGE = "cloth", WARLOCK = "cloth" }

    local lists = {}
    for _, it in ipairs(INTERESTS) do
        if picked[it.key] then
            local list = {}
            local tag = it.label
            if it.key == "raid" then
                -- next raid you haven't cleared, its tier set, then the side raids
                local prog = { "raid_mc", "raid_bwl", "raid_aq40", "raid_naxx" }
                local tierOf = { raid_mc = "set_tier1", raid_bwl = "set_tier2", raid_aq40 = "set_tier25", raid_naxx = "tier3" }
                local nextRaid, after, current
                for i, id in ipairs(prog) do
                    if not Finished(id) then
                        local rg = FGT.GoalById(id)
                        if W.find and rg and IsActive(rg) then
                            -- already working on this raid: offer its set, then move up
                            current = current or id
                        else
                            nextRaid, after = id, prog[i + 1]
                            break
                        end
                    end
                end
                if current and tierOf[current] then
                    push(list, Entry(me, tierOf[current], ClassPart(tierOf[current]), tag))
                end
                if nextRaid then
                    push(list, Entry(me, nextRaid, nil, tag))
                    if tierOf[nextRaid] then push(list, Entry(me, tierOf[nextRaid], ClassPart(tierOf[nextRaid]), tag)) end
                end
                if nextRaid == "raid_mc" or nextRaid == "raid_bwl" then push(list, Entry(me, "raid_ony", nil, tag)) end
                push(list, Entry(me, "raid_zg", nil, tag))
                -- Forever's new raids (Entry skips them on Classic Era)
                push(list, Entry(me, "raid_barrow", nil, tag))
                push(list, Entry(me, "raid_hyjal", nil, tag))
                push(list, Entry(me, "set_forever_raid", ClassPart("set_forever_raid"), tag))
                if after then push(list, Entry(me, after, nil, tag)) end
            elseif it.key == "loot" then
                local sets = {}
                if me.class == "DRUID" then push(sets, Entry(me, "set_viper", nil, tag)) end
                push(sets, Entry(me, "set_dungeon1", ClassPart("set_dungeon1"), tag))
                push(sets, Entry(me, "set_dungeon2", ClassPart("set_dungeon2"), tag))
                push(sets, Entry(me, "set_tier25", ClassPart("set_tier25"), tag))
                local weapons = {}
                for _, id in ipairs(WEAPONS[me.class] or {}) do push(weapons, Entry(me, id, nil, tag)) end
                -- the class's signature weapons lead, at any level
                for _, e in ipairs(weapons) do table.insert(list, e) end
                for _, e in ipairs(sets) do table.insert(list, e) end
            elseif it.key == "collect" then
                push(list, Entry(me, "fishing_extravaganza", nil, tag))
                push(list, Entry(me, "mount_raptor", nil, tag))
                push(list, Entry(me, "mount_tiger", nil, tag))
                if me.faction == "Alliance" then push(list, Entry(me, "frostsaber", nil, tag)) end
                push(list, Entry(me, "mount_deathcharger", nil, tag))
                push(list, Entry(me, "mount_qiraji", nil, tag))
                for _, color in ipairs({"blue", "green", "yellow", "red"}) do
                    push(list, Entry(me, "mount_qiraji_" .. color, nil, tag))
                end
            elseif it.key == "pvp" then
                local f = (me.faction == "Horde") and "horde" or "ally"
                -- the PvP set for your faction and armor type (Forever), your class's set chosen
                local pvpSet = "pvp_set_" .. (ARMOR[me.class] or "") .. "_" .. f
                for _, id in ipairs({ "pvp_avmount_" .. f, "pvp_wsg_" .. f, "pvp_ab_" .. f, "pvp_mount_" .. f,
                                      pvpSet, "pvp_hk", "pvp_av_" .. f, "pvp_rank14_" .. f }) do
                    push(list, Entry(me, id, id == pvpSet and ClassPart(id) or nil, tag))
                end
            elseif it.key == "grind" then
                push(list, Entry(me, "fishing_extravaganza", nil, tag))
                -- the professions this character already knows
                local mine = Roster()[CharKey()]
                local known = {}
                for _, p in ipairs(PRIMARY) do
                    if mine and mine.skills and (mine.skills[p] or 0) > 0 then table.insert(known, p) end
                end
                local profs = FGT.GoalById("prof_all")
                if profs and #known > 0 then push(list, Entry(me, "prof_all", PartKeys(profs, known), tag)) end
                push(list, Entry(me, "rep_argentdawn", nil, tag))
                push(list, Entry(me, "rep_timbermaw", nil, tag))
                push(list, Entry(me, "gold_5k", nil, tag))
                if has60 and leveling then
                    -- leveling other classes
                    local others = {}
                    for i, entry in ipairs(leveling.steps) do
                        if IsAutoStep(entry) and AutoStepFraction(entry) < 1 then others[i] = true end
                    end
                    push(list, Entry(me, "allclasses", others, tag))
                end
                push(list, Entry(me, "rep_cenarion", nil, tag))
                push(list, Entry(me, (me.faction == "Horde") and "rep_ambassador_horde" or "rep_ambassador_ally", nil, tag))
                local sec = FGT.GoalById("prof_secondary")
                if sec then push(list, Entry(me, "prof_secondary", PartKeys(sec, { "Fishing", "Cooking", "First Aid" }), tag)) end
                for _, id in ipairs({ "rep_thorium", "rep_zandalar", "rep_hydraxian", "rep_nozdormu" }) do
                    push(list, Entry(me, id, nil, tag))
                end
            elseif it.key == "social" then
                push(list, Entry(me, "social_guild", nil, tag))
                push(list, Entry(me, "social_friends", nil, tag))
            end
            -- goals you've already started go first
            local started, rest = {}, {}
            for _, e in ipairs(list) do table.insert(e.d > 0 and started or rest, e) end
            for _, e in ipairs(rest) do table.insert(started, e) end
            table.insert(lists, started)
        end
    end

    -- Take turns between the interests, so each one is represented. A
    -- raid whose legendary is already in is skipped, and a legendary
    -- replaces its raid if the raid came first.
    local function RoundRobin(from, max, maxTracked)
        local picks, chosen, idx = {}, {}, {}
        local new, old, sets = 0, 0, 0
        local progress = true
        while new < max and progress do
            progress = false
            for li, list in ipairs(from) do
                if new >= max then break end
                local i = idx[li] or 1
                while list[i] do
                    local e = list[i]
                    local id = e.goal.id
                    i = i + 1
                    -- at most two item sets in all (dungeon and tier sets look alike)
                    local covered = (e.tracked and old >= maxTracked)
                        or (e.goal.category == "Item Set" and sets >= MAX_SETS)
                    for leg, raid in pairs(COVERS) do
                        if raid == id and chosen[leg] then covered = true end
                    end
                    if not covered then
                        local raid = COVERS[id]
                        if raid and chosen[raid] then
                            for pi, p in ipairs(picks) do
                                if p.goal.id == raid then
                                    table.remove(picks, pi)
                                    if p.tracked then old = old - 1 else new = new - 1 end
                                    break
                                end
                            end
                            chosen[raid] = nil
                        end
                        table.insert(picks, e)
                        chosen[id] = true
                        if e.tracked then old = old + 1 else new = new + 1 end
                        if e.goal.category == "Item Set" then sets = sets + 1 end
                        progress = true
                        break
                    end
                end
                idx[li] = i
            end
        end
        return picks
    end
    -- leveling and the mount come first; interests fill the rest
    local newFixed = 0
    for _, e in ipairs(fixed) do if not e.tracked then newFixed = newFixed + 1 end end
    local picks = RoundRobin(lists, math.max(0, MAX_ROWS - newFixed), MAX_TRACKED)

    -- Nothing left for those interests: offer a few from all of them.
    W.fallback = false
    local anyNew = false
    for _, e in ipairs(picks) do if not e.tracked then anyNew = true end end
    if not anyNew and not picked.__all then
        local all = { __all = true }
        for _, it in ipairs(INTERESTS) do all[it.key] = true end
        local fixedIds = {}
        for _, e in ipairs(fixed) do fixedIds[e.goal.id] = true end
        local added = 0
        for _, e in ipairs((Suggest(all))) do
            if not fixedIds[e.goal.id] and not e.tracked and added < 4 then
                table.insert(picks, e)
                added = added + 1
            end
        end
        W.fallback = added > 0
    end

    -- Under 60: easier goals first, the long-haul dream last.
    if me.level < MAX_LEVEL then
        local rank = {}
        for i, d in ipairs(FGT.difficultyOrder) do rank[d] = i end
        for i, e in ipairs(picks) do e.order = i end
        table.sort(picks, function(a, b)
            local ra, rb = rank[a.goal.difficulty] or 9, rank[b.goal.difficulty] or 9
            if ra ~= rb then return ra < rb end
            return a.order < b.order
        end)
    end

    -- new suggestions first, then the ones already on My Goals
    local out = {}
    for pass = 1, 2 do
        for _, list in ipairs({ fixed, picks }) do
            for _, e in ipairs(list) do
                if (pass == 1) == (not e.tracked) and #out < MAX_ROWS then table.insert(out, e) end
            end
        end
    end
    return out, me
end
W.Suggest = Suggest

-- "an Orc Warlock who loves raiding, PvP and the grind"
local function PickedLine(me, picked)
    local words = {}
    for _, it in ipairs(INTERESTS) do
        if picked[it.key] then table.insert(words, it.phrase) end
    end
    local loves
    if #words == 1 then
        loves = words[1]
    else
        loves = table.concat(words, ", ", 1, #words - 1) .. " and " .. words[#words]
    end
    local who = me.raceName .. " " .. me.className
    local article = who:match("^[AEIOUaeiou]") and "an" or "a"
    return string.format("Picked for %s %s who loves %s", article, who, loves)
end

-- ------------------------------------------------------------
-- UI
-- ------------------------------------------------------------
local function Button(parent, text, primary)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetHeight(28)
    Etch(b, STYLE.button, 10)
    b.text = NewTitleString(b, 12)
    b.text:SetPoint("CENTER", 0, 0)
    b.primary = primary
    function b:SetLabel(t)
        self.text:SetText(t)
        self:SetWidth(math.max(110, math.ceil(self.text:GetStringWidth()) + 40))
    end
    function b:SetOn(on)
        self.enabled = on
        if not on then
            self:SetEtch(STYLE.muted)
            self.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        else
            self:SetEtch(self.primary and STYLE.rowSel or STYLE.button)
            local c = self.primary and C.TITLE or C.TEXT
            self.text:SetTextColor(c[1], c[2], c[3])
        end
    end
    b:SetScript("OnEnter", function(self)
        if self.enabled then self:SetEtch(self.primary and STYLE.rowSel or STYLE.btnHover) end
        if self.enabled and self.primary then self.text:SetTextColor(1, 1, 1) end
    end)
    b:SetScript("OnLeave", function(self) self:SetOn(self.enabled) end)
    b:SetScript("OnClick", function(self) if self.enabled and self.onClick then self.onClick() end end)
    b:SetLabel(text)
    b:SetOn(true)
    return b
end

-- Small grey text link ("No thanks", "x").
local function TextLink(parent, text, size)
    local b = CreateFrame("Button", nil, parent)
    b.text = NewFontString(b, size or 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    b.text:SetPoint("CENTER", 0, 0)
    b.text:SetText(text)
    b:SetSize(math.ceil(b.text:GetStringWidth()) + 8, (size or 11) + 8)
    b:SetScript("OnEnter", function(self) self.text:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3]) end)
    b:SetScript("OnLeave", function(self) self.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3]) end)
    return b
end

-- Interest tile micro-interactions, every frame while a tile shows:
-- hover grows the icon ~10% and brightens its glow; a click pops it
-- (springy bounce plus a small wiggle); a picked tile's glow breathes.
-- Full: all of it. Subtle: glow only. Off: still.
function W.TileMotion(t, elapsed)
    local motion = W.Motion()
    local on = W.picked[t.it.key]
    local k = math.min(1, elapsed * 12)
    local want = (motion == "full") and ((t.hover and 1.10) or (on and 1.04) or 1) or 1
    t.s = (t.s or 1) + (want - (t.s or 1)) * k
    local pop, rot = 0, 0
    if t.popT then
        t.popT = t.popT + elapsed
        if t.popT > 0.7 then
            t.popT = nil
        elseif motion == "full" then
            local d = math.exp(-t.popT * 7)
            pop = 0.16 * d * math.cos(t.popT * 18)
            rot = 0.13 * d * math.sin(t.popT * 24) -- about 7 degrees, settling
        end
    end
    local sc = t.s + pop
    local glowWant = 0.22
    if motion ~= "off" then
        if t.hover then glowWant = 0.40
        elseif on then glowWant = 0.32 + 0.08 * math.sin(GetTime() * 2.4) end
    end
    t.g = (t.g or 0.22) + (glowWant - (t.g or 0.22)) * k
    if t.art then
        t.art:SetSize(56 * sc, 56 * sc)
        if t.art.SetRotation then t.art:SetRotation(rot) end
        t.glow:SetSize(88 * (0.9 + 0.1 * sc), 88 * (0.9 + 0.1 * sc))
        t.glow:SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], t.g)
    else
        t.icon:SetSize(40 * sc, 40 * sc)
    end
end

local ROW_H = 54

local function Build()
    if W.frame then return end
    -- darkened window behind the card; takes the clicks
    local f = CreateFrame("Frame", nil, main)
    f:SetAllPoints(main)
    f:SetFrameLevel(main:GetFrameLevel() + 70)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function() end)
    local dim = f:CreateTexture(nil, "BACKGROUND")
    dim:SetTexture(SOLID)
    dim:SetPoint("TOPLEFT", 4, -4)
    dim:SetPoint("BOTTOMRIGHT", -4, 4)
    dim:SetVertexColor(0, 0, 0, 0.72)
    W.dim = dim
    f:Hide()
    W.frame = f

    local card = CreateFrame("Frame", nil, f, "BackdropTemplate")
    Etch(card, STYLE.window, 16)
    card:EnableMouse(true)
    W.card = card

    -- the same gold X as the window's close button (Karl)
    local close = CreateFrame("Button", nil, card)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -10)
    close:SetScript("OnClick", function() FGT.CloseWelcome() end)
    FGT.IconButton(close, "close", 13)

    W.title = NewTitleString(card, 20)
    W.title:SetPoint("TOP", card, "TOP", 0, -26)
    W.sub = NewFontString(card, 12, "", C.INK2[1], C.INK2[2], C.INK2[3])
    W.sub:SetPoint("TOP", W.title, "BOTTOM", 0, -10)
    W.sub:SetJustifyH("CENTER")

    -- Step 1: two big choice cards
    W.choices = {}
    for i = 1, 2 do
        local c = CreateFrame("Button", nil, card, "BackdropTemplate")
        Etch(c, STYLE.row, 12)
        c.icon = NewIcon(c, 40)
        c.icon:SetPoint("TOP", c, "TOP", 0, -20)
        c.name = NewTitleString(c, 14)
        c.name:SetPoint("TOP", c.icon, "BOTTOM", 0, -12)
        c.desc = NewFontString(c, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
        c.desc:SetPoint("TOP", c.name, "BOTTOM", 0, -8)
        c.desc:SetJustifyH("CENTER")
        c:SetScript("OnEnter", function(self) self:SetEtch(STYLE.rowSel) end)
        c:SetScript("OnLeave", function(self) self:SetEtch(STYLE.row) end)
        c:SetScript("OnClick", function(self) if self.onClick then self.onClick() end end)
        W.choices[i] = c
    end
    -- the suggested path: moving gold border and a label
    local help = W.choices[2]
    FGT.AddBorderComet(help, 2, 0.9)
    help.tag = NewChip(help, 9)
    help.tag:SetPoint("TOP", help.desc, "BOTTOM", 0, -12)
    help.tag:SetLabel("RECOMMENDED", C.TITLE)

    -- Step 2: interest tiles
    W.tiles = {}
    for i, it in ipairs(INTERESTS) do
        local t = CreateFrame("Button", nil, card, "BackdropTemplate")
        Etch(t, STYLE.row, 12)
        t.it = it
        t.icon = NewIcon(t, 40)
        t.icon:SetPoint("CENTER", t, "TOP", 0, -36)
        -- custom art (Media/interests/<name>.tga): shown whole, no rim or
        -- crop, with a very soft gold glow behind it
        if it.art then
            t.icon:Hide()
            t.glow = t:CreateTexture(nil, "ARTWORK", nil, 1)
            t.glow:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
            t.glow:SetBlendMode("ADD")
            t.glow:SetSize(88, 88)
            t.glow:SetPoint("CENTER", t, "TOP", 0, -40)
            t.glow:SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.22)
            t.art = t:CreateTexture(nil, "ARTWORK", nil, 2)
            t.art:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\interests\\" .. it.art)
            t.art:SetSize(56, 56)
            t.art:SetPoint("CENTER", t, "TOP", 0, -40)
        end
        t.name = NewTitleString(t, 12)
        t.name:SetPoint("BOTTOM", t, "BOTTOM", 0, 14)
        t.name:SetText(it.label)
        function t:Refresh()
            local on = W.picked[self.it.key]
            self.comet.on = on and true or false
            self:SetEtch(on and STYLE.rowSel or (self.hover and STYLE.rowHover or STYLE.row))
            local c = on and C.TITLE or C.INK2
            self.name:SetTextColor(c[1], c[2], c[3])
        end
        t:SetScript("OnEnter", function(self) self.hover = true; self:Refresh() end)
        t:SetScript("OnLeave", function(self) self.hover = false; self:Refresh() end)
        t:SetScript("OnClick", function(self)
            W.picked[self.it.key] = (not W.picked[self.it.key]) or nil
            self.popT = 0 -- the pop and wiggle (TileMotion)
            self:Refresh()
            W.next:SetOn(next(W.picked) ~= nil)
        end)
        -- a slow, soft gold streak circles the border while the tile is picked
        FGT.AddBorderComet(t, 2, 0.4, 6.5)
        t.comet.on, t.comet.vis = false, 0
        t:SetScript("OnUpdate", W.TileMotion)
        W.tiles[i] = t
    end

    -- Step 3: suggestion rows in a scroll area
    W.scroll = CreateScrollArea(card)
    W.rows = {}
    W.note = NewFontString(card, 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])

    -- footer buttons (shared by steps 2 and 3)
    W.back = TextLink(card, "Back", 12)
    W.next = Button(card, "Next", true)
    W.add = Button(card, "Add goals", true)
    W.back:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 18, 20)
    W.next:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -20, 16)
    W.add:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -20, 16)
    W.next.onClick = function() W.Show(3) end
    W.add.onClick = function() W.AddChosen() end

    W.scroll:Finalize()
end

local function GetRow(i)
    local row = W.rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, W.scroll.content, "BackdropTemplate")
    row:SetHeight(ROW_H - 6)
    Etch(row, STYLE.row, 10)
    row.box = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.box:SetSize(16, 16)
    row.box:SetPoint("LEFT", row, "LEFT", 12, 0)
    Skin(row.box, { 0, 0, 0, 1 }, C.BOX_RING)
    row.check = row.box:CreateTexture(nil, "OVERLAY")
    row.check:SetTexture(FGT.Icon("check"))
    row.check:SetSize(15, 15)
    row.check:SetPoint("CENTER", 0, 0)
    row.icon = NewIcon(row, 36)
    row.icon:SetPoint("LEFT", row.box, "RIGHT", 12, 0)
    -- right side: "On My Goals" for goals you already track
    row.extra = NewFontString(row, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
    row.extra:SetJustifyH("RIGHT")
    row.name = NewFontString(row, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    row.name:SetPoint("BOTTOMLEFT", row.icon, "RIGHT", 10, 1)
    row.name:SetPoint("RIGHT", row, "RIGHT", -120, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.meta = NewFontString(row, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    row.meta:SetPoint("TOPLEFT", row.icon, "RIGHT", 10, -3)
    row.meta:SetPoint("RIGHT", row, "RIGHT", -120, 0)
    row.meta:SetJustifyH("LEFT")
    row.meta:SetWordWrap(false)
    function row:Refresh()
        local e = self.entry
        if e.tracked then
            -- already on My Goals: quiet, no checkbox, can't be toggled
            self:SetEtch(STYLE.muted)
            self.box:Hide()
            self.icon:SetAlpha(0.55)
            self.name:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
            return
        end
        self.box:Show()
        self.icon:SetAlpha(1)
        self.name:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
        local st = e.on and STYLE.rowSel or (self.hover and STYLE.rowHover or STYLE.row)
        self:SetEtch(st)
        self.check:SetShown(e.on)
        if e.on then
            self.box:SetBackdropColor(C.BOX_DONE_BG[1], C.BOX_DONE_BG[2], C.BOX_DONE_BG[3], 0.45)
            self.box:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
        else
            self.box:SetBackdropColor(0, 0, 0, 1)
            self.box:SetBackdropBorderColor(C.BOX_RING[1], C.BOX_RING[2], C.BOX_RING[3], 1)
        end
    end
    row:SetScript("OnEnter", function(self)
        self.hover = true
        self:Refresh()
        local g = self.entry.goal
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(g.name, C.TITLE[1], C.TITLE[2], C.TITLE[3])
        if g.note then GameTooltip:AddLine(g.note, 0.9, 0.9, 0.9, true) end
        if self.entry.tracked then
            GameTooltip:AddLine("Already on My Goals.", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        end
        local fn = FGT.ForeverNote(self.entry.look or g, true)
        if fn then GameTooltip:AddLine(fn, C.FOREVER_LIGHT[1], C.FOREVER_LIGHT[2], C.FOREVER_LIGHT[3], true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hover = false
        self:Refresh()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        if self.entry.tracked then return end
        self.entry.on = not self.entry.on
        self:Refresh()
        W.UpdateAdd()
    end)
    W.rows[i] = row
    return row
end

function W.UpdateAdd()
    local n = 0
    for _, e in ipairs(W.list) do if e.on then n = n + 1 end end
    W.add:SetLabel(n == 1 and "Add 1 goal" or string.format("Add %d goals", n))
    W.add:SetOn(n > 0)
end

local function FillRows(me)
    local y = 0
    for i, e in ipairs(W.list) do
        local row = GetRow(i)
        row.entry = e
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", W.scroll.content, "TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", W.scroll.content, "RIGHT", -6, 0)
        local g = e.goal
        local only = OnlyKey(e.keys)
        local icon = (g.sections and only and g.sections[only].icon) or g.icon
        -- blue twin styles for things new in Forever
        row.foreverNew = e.word and true or false
        row.icon:SetIcon(icon, row.foreverNew and C.FOREVER or C.GOLD2)
        local title = Title(e, me)
        row.name:SetText(e.word and (title .. "   " .. FGT.NewTag(e.word)) or title)
        local dc = FGT.difficultyColors and FGT.difficultyColors[g.difficulty]
        local diff = g.difficulty and (dc and ("|cff" .. HexColor(dc) .. g.difficulty .. "|r") or g.difficulty) or ""
        local parts = { e.why }
        if g.difficulty then table.insert(parts, diff) end
        if g.timeEstimate then table.insert(parts, g.timeEstimate) end
        row.meta:SetText(table.concat(parts, "  ·  "))
        -- right side: "On My Goals" for goals you already track
        row.extra:SetText(e.tracked and "On My Goals" or "")
        row.extra:ClearAllPoints()
        row.extra:SetPoint("RIGHT", row, "RIGHT", -14, 0)
        row.hover = false
        row:Refresh()
        row:Show()
        y = y + ROW_H
    end
    for i = #W.list + 1, #W.rows do W.rows[i]:Hide() end
    W.scroll.content:SetHeight(math.max(1, y))
    W.scroll.scroll:SetVerticalScroll(0)
    W.scroll:Update()
end

-- Shows one step. The card is at most 640 x 520 and shrinks with the window.
function W.Show(step)
    Build()
    W.step = step
    local mw, mh = main:GetWidth(), main:GetHeight()
    local cw = math.min(step == 2 and 720 or 640, mw - 40) -- step 2: room for six tiles
    local ch = (step == 3) and math.min(520, mh - 40) or math.min(330, mh - 40)
    W.sub:SetWidth(cw - 60)
    if step == 1 then
        -- just tall enough: title, intro line, the cards
        W.sub:SetText("Forever Goal Tracker keeps your long-term goals in one place and checks off steps as you play.")
        ch = math.min(26 + 26 + 10 + math.ceil(W.sub:GetStringHeight()) + 24 + 170 + 26, mh - 40)
    end
    W.card:ClearAllPoints()
    W.card:SetSize(cw, ch)
    W.card:SetPoint("CENTER", W.frame, "CENTER", 0, 0)

    for _, c in ipairs(W.choices) do c:Hide() end
    for _, t in ipairs(W.tiles) do t:Hide() end
    for _, r in ipairs(W.rows) do r:Hide() end
    W.scroll.scroll:Hide()
    W.scroll.content:SetHeight(1) -- nothing to scroll: hides its bar and edge fades
    W.scroll:Update()
    W.note:Hide()
    W.back:Hide(); W.next:Hide(); W.add:Hide()
    W.sub:SetWidth(cw - 60)

    local me = Me()
    local who = me.raceName .. " " .. me.className
    if step == 1 then
        local n = #ActiveGoals()
        W.title:SetText(n > 0 and "Welcome back!" or "Welcome!")
        W.sub:SetText("Forever Goal Tracker keeps your long-term goals in one place and checks off steps as you play.")
        local gap = 16
        local w = math.floor((cw - 48 - gap) / 2)
        local own, help = W.choices[1], W.choices[2]
        for i, c in ipairs(W.choices) do
            c:SetSize(w, 170)
            c:ClearAllPoints()
            c:SetPoint("TOPLEFT", W.sub, "BOTTOM", -(cw - 48) / 2 + (i - 1) * (w + gap), -24)
            c.desc:SetWidth(w - 30)
            c:SetEtch(STYLE.row)
            c:Show()
        end
        if n > 0 then
            own.icon:SetIcon({ "inv_misc_book_09", "inv_misc_book_07" })
            own.name:SetText("Keep my goals")
            own.desc:SetText(string.format("Carry on with the %d goal%s on your tracker.", n, n == 1 and "" or "s"))
            own.onClick = function() FGT.CloseWelcome() end
            help.name:SetText("Help me find more")
        else
            own.icon:SetIcon({ "inv_misc_book_09", "inv_misc_book_07" })
            own.name:SetText("I'll pick my own")
            own.desc:SetText(string.format("Browse all %d goals in the Goal Library.", FGT.CatalogGoalCount()))
            own.onClick = function()
                FGT.CloseWelcome(true)
                FGT.ShowTab("library")
            end
            help.name:SetText("Help me get started")
        end
        help.icon:SetIcon({ "inv_misc_map_01", "inv_misc_map02" })
        help.desc:SetText("Tell us what you enjoy and get goals picked for your " .. who .. ".")
        help.onClick = function() W.Show(2) end
        W.Enter(W.choices)
    elseif step == 2 then
        W.title:SetText("What interests you?")
        W.sub:SetText("Pick as many as you like.")
        local gap = 8
        local n = #W.tiles
        local tw = math.floor((cw - 48 - gap * (n - 1)) / n)
        for i, t in ipairs(W.tiles) do
            t:SetSize(tw, 104)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", W.card, "TOPLEFT", 24 + (i - 1) * (tw + gap), -110)
            local icon = t.it.icon
            if icon == "pvp" then
                icon = (me.faction == "Horde") and { "inv_bannerpvp_01" } or { "inv_bannerpvp_02" }
            end
            if t.art then t.icon:Hide() else t.icon:SetIcon(icon) end
            t.hover = false
            t:Refresh()
            t:Show()
        end
        -- Back only when you came from the welcome screen
        W.back:SetShown(W.startStep == 1)
        W.back:SetScript("OnClick", function() W.Show(1) end)
        W.next:Show()
        W.next:SetOn(next(W.picked) ~= nil)
        W.Enter(W.tiles)
    else
        W.title:SetText(W.find and "Your next goals" or "Goals to get started")
        local list
        list, me = Suggest(W.picked)
        W.list = list
        if W.fallback then
            W.sub:SetText("You're ahead of us on those! Here are a few other things to chase.")
        else
            W.sub:SetText(PickedLine(me, W.picked))
        end
        W.scroll.scroll:ClearAllPoints()
        W.scroll.scroll:SetPoint("TOPLEFT", W.card, "TOPLEFT", 22, -86)
        W.scroll.scroll:SetPoint("BOTTOMRIGHT", W.card, "BOTTOMRIGHT", -28, 86)
        W.scroll.scroll:Show()
        W.scroll.content:SetWidth(W.scroll.scroll:GetWidth())
        FillRows(me)
        local shown = {}
        for i = 1, #W.list do shown[i] = W.rows[i] end
        W.Enter(shown)
        W.note:ClearAllPoints()
        W.note:SetPoint("BOTTOM", W.card, "BOTTOM", 0, 60)
        W.note:SetText(#list > 0 and "Add or remove goals anytime from the Goal Library."
            or "Nothing to suggest right now. The Goal Library has everything.")
        W.note:Show()
        W.back:Show()
        W.back:SetScript("OnClick", function() W.Show(2) end)
        W.add:Show()
        W.UpdateAdd()
    end
end

function W.AddChosen()
    local DB = ForeverGoalTrackerDB
    local first, n = nil, 0
    for _, e in ipairs(W.list) do
        if e.on then
            if e.goal.group then
                local sel = DB.activeParts[e.goal.id] or {}
                DB.activeParts[e.goal.id] = sel
                for k in pairs(e.keys) do sel[k] = true end
            else
                DB.active[e.goal.id] = true
            end
            n = n + 1
            first = first or e.goal.id
        end
    end
    FGT.CloseWelcome(true)
    if n == 0 then return end
    FGT.ShowTab("tracker")
    FGT.SelectGoal(first)
    FGT.RefreshOverall()
    if FGT.LayoutLibrary then FGT.LayoutLibrary() end
    print(TAG .. string.format("added %d goal%s to My Goals. Good luck out there!", n, n == 1 and "" or "s"))
end

-- step: 1 (the two choices, default) or 2 (straight to the interests).
-- find: "Find your next goal" from the end of My Goals; skips goals you
-- already have and starts on step 3 with your saved interests.
-- demoPicked: demo scenes 5 and 6 open it with these interests picked.
function FGT.OpenWelcome(step, find, demoPicked)
    local DB = ForeverGoalTrackerDB
    if not DB then return end
    if DB.demoBackup and not demoPicked then
        -- demo goals carry staged ticks and favorites; adding to them would mislead
        print(TAG .. "goal suggestions are off in demo mode. Type |cffffffff/goals demo off|r first.")
        return
    end
    if not main:IsShown() then
        DB.welcomeSeen = true -- the OnShow hook below won't open it a second time
        FGT.ToggleFrame()
    end
    if FGT.CloseSettings then FGT.CloseSettings() end
    if FGT.CloseGoalMenu then FGT.CloseGoalMenu() end
    if FGT.CloseLinkCard then FGT.CloseLinkCard() end
    if FGT.CloseTargetCard then FGT.CloseTargetCard() end
    if FGT.CloseNoteCard then FGT.CloseNoteCard(true) end
    DB.welcomeSeen = true -- shown once; closing it any way counts
    W.picked = {} -- always starts with nothing picked
    for k, v in pairs(demoPicked or {}) do W.picked[k] = v end
    W.find = find and true or nil
    if find then
        -- your interests from last time; none saved yet: ask first
        for k, v in pairs(DB.interests or {}) do W.picked[k] = v end
        step = next(W.picked) and 3 or 2
    end
    W.startStep = step or 1
    W.Tween("close", nil) -- reopened mid-close
    W.closing = nil
    W.Show(step or 1)
    W.frame:Show()
    W.Grey(true)
    W.AnimateIn()
end

-- instant: no fade-out (when the window changes right after, like adding
-- goals or going to the Library, so colors aren't restored over new ones)
function FGT.CloseWelcome(instant)
    if W.frame and W.frame:IsShown() and not instant and W.Motion() ~= "off" and not W.closing then
        W.closing = true
        W.Tween("open", nil)
        W.Tween("close", 0.28, function(p)
            local q = 1 - p
            W.card:SetAlpha(q)
            if W.Motion() == "full" then W.card:SetScale(0.97 + 0.03 * q) end
            W.SetGrey(1 - W.EaseOut(p))
        end, function()
            W.closing = nil
            FGT.CloseWelcome(true)
        end)
        return
    end
    W.closing = nil
    W.Tween("open", nil)
    W.Tween("close", nil)
    if W.frame then W.frame:Hide() end
    W.Grey(false)
    if ForeverGoalTrackerDB and next(W.picked) then
        local keep = {}
        for k, v in pairs(W.picked) do keep[k] = v end
        ForeverGoalTrackerDB.interests = keep -- for a later "For you" sort
    end
end

-- While the wizard is up, the window behind it goes grey as well as
-- dark: images desaturate, text and border colors turn to their grey
-- (luminance) value. Everything is put back when it closes. (Gradient
-- fills can't be greyed, but the dark layer covers them.)
local grey = nil
local function Lum(r, g, b) return 0.30 * r + 0.59 * g + 0.11 * b end
local function Collect(frame)
    for _, r in ipairs({ frame:GetRegions() }) do
        if r:IsObjectType("Texture") then
            if r.IsDesaturated and not r:IsDesaturated() then table.insert(grey.tex, r) end
            -- colors set in code don't desaturate: gold lines (vertex
            -- color) and gradients (remembered by ApplyV/HGradient)
            if r.fgtGdir then
                local a, b = r.fgtG1, r.fgtG2
                grey.grad[r] = { r.fgtGdir, { a[1], a[2], a[3] }, { b[1], b[2], b[3] }, r.fgtGa1, r.fgtGa2 }
            elseif r.GetVertexColor then
                local vr, vg, vb, va = r:GetVertexColor()
                if vr and not (vr == 1 and vg == 1 and vb == 1) then grey.vc[r] = { vr, vg, vb, va } end
            end
        elseif r:IsObjectType("FontString") then
            local cr, cg, cb, ca = r:GetTextColor()
            if cr then grey.fs[r] = { cr, cg, cb, ca } end
        end
    end
    if frame.GetBackdropBorderColor and frame.GetBackdrop and frame:GetBackdrop() then
        local cr, cg, cb, ca = frame:GetBackdropBorderColor()
        if cr then grey.bd[frame] = { cr, cg, cb, ca } end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        -- Both modal cards stay in color while the addon behind them greys.
        local T = FGT.noteCard
        if child ~= W.frame and child ~= T and (not T or (child ~= T.catcher and child ~= T.shadow)) then Collect(child) end
    end
end
-- amount 0 = full color, 1 = grey (and the dark layer at full strength)
function W.SetGrey(amount)
    if W.dim then W.dim:SetVertexColor(0, 0, 0, 0.72 * amount) end
    if not grey then return end
    for _, t in ipairs(grey.tex) do
        if t.SetDesaturation then t:SetDesaturation(amount) else t:SetDesaturated(amount > 0.5) end
    end
    for fs, c in pairs(grey.fs) do
        local l = Lum(c[1], c[2], c[3])
        fs:SetTextColor(c[1] + (l - c[1]) * amount, c[2] + (l - c[2]) * amount, c[3] + (l - c[3]) * amount, c[4])
    end
    for f, c in pairs(grey.bd) do
        local l = Lum(c[1], c[2], c[3])
        f:SetBackdropBorderColor(c[1] + (l - c[1]) * amount, c[2] + (l - c[2]) * amount, c[3] + (l - c[3]) * amount, c[4])
    end
    local function G(c)
        local l = Lum(c[1], c[2], c[3])
        return { c[1] + (l - c[1]) * amount, c[2] + (l - c[2]) * amount, c[3] + (l - c[3]) * amount }
    end
    for t, c in pairs(grey.vc) do
        local g = G(c)
        t:SetVertexColor(g[1], g[2], g[3], c[4])
    end
    for t, g in pairs(grey.grad) do
        if g[1] == "V" then ApplyVGradient(t, G(g[2]), G(g[3]), g[4], g[5])
        else ApplyHGradient(t, G(g[2]), G(g[3]), g[4], g[5]) end
    end
end
function W.Grey(on)
    if on and not grey then
        grey = { tex = {}, fs = {}, bd = {}, vc = {}, grad = {} }
        pcall(Collect, main)
        W.SetGrey(1)
    elseif not on and grey then
        W.SetGrey(0)
        for _, t in ipairs(grey.tex) do t:SetDesaturated(false) end
        grey = nil
    end
end

-- ------------------------------------------------------------
-- Motion. One OnUpdate drives every running tween; the Celebrations
-- setting picks how much moves: full (fades, grow and rise), subtle
-- (fades only) or off (instant).
-- ------------------------------------------------------------
function W.Motion() return FGT.Setting("celebrations") or "full" end
function W.EaseOut(p) return 1 - (1 - p) ^ 3 end
local EaseOut = W.EaseOut
local tweens = {}
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(_, elapsed)
    -- Callbacks can rebuild the guide and add/cancel tweens. Iterate a
    -- snapshot so those changes cannot invalidate Lua 5.1's next key.
    local pending = {}
    for key, tw in pairs(tweens) do
        pending[#pending + 1] = { key, tw }
    end
    for _, entry in ipairs(pending) do
        local key, tw = entry[1], entry[2]
        -- A previous callback may have cancelled or replaced this entry.
        if tweens[key] == tw then
            tw.t = tw.t + elapsed
            local p = math.min(1, tw.t / tw.dur)
            if p >= 0 then tw.fn(p) end
            if p >= 1 and tweens[key] == tw then
                tweens[key] = nil
                if tw.done then tw.done() end
            end
        end
    end
    if not next(tweens) then driver:Hide() end
end)
-- W.Tween(key, seconds, fn(p), done, delay); seconds nil cancels the key
function W.Tween(key, dur, fn, done, delay)
    if not dur then tweens[key] = nil return end
    if W.Motion() == "off" then fn(1); if done then done() end return end
    tweens[key] = { t = -(delay or 0), dur = dur, fn = fn, done = done }
    fn(0)
    driver:Show()
end

-- Opening: dark layer and grey fade in, the card grows in from 95%
-- with a soft settle and fades in.
local function EaseBack(p) local u = p - 1; return 1 + 1.7 * u * u * u + 0.7 * u * u end
function W.AnimateIn()
    local full = W.Motion() == "full"
    W.Tween("open", 0.34, function(p)
        W.SetGrey(EaseOut(p))
        W.card:SetAlpha(math.min(1, p * 1.6))
        W.card:SetScale(full and (0.95 + 0.05 * EaseBack(p)) or 1)
    end, function() W.card:SetScale(1); W.card:SetAlpha(1) end)
end

-- Step content rises into place one item after another.
function W.Enter(items)
    local full = W.Motion() == "full"
    for i, f in ipairs(items) do
        local pts = {}
        for k = 1, (f:GetNumPoints() or 0) do pts[k] = { f:GetPoint(k) } end
        local rise = full
        W.Tween("enter" .. i, 0.26, function(p)
            local e = EaseOut(p)
            f:SetAlpha(e)
            if rise and #pts > 0 then
                f:ClearAllPoints()
                for _, pt in ipairs(pts) do
                    f:SetPoint(pt[1], pt[2], pt[3], pt[4] or 0, (pt[5] or 0) - 10 * (1 - e))
                end
            end
        end, nil, 0.04 * (i - 1))
    end
end

-- Escape (or any close of the window) closes the wizard for good.
main:HookScript("OnHide", function() if W.frame and W.frame:IsShown() then FGT.CloseWelcome(true) end end)

-- First time the window opens (fresh installs and updates alike).
main:HookScript("OnShow", function()
    local DB = ForeverGoalTrackerDB
    if DB and not DB.welcomeSeen and not DB.demoBackup and not (W.frame and W.frame:IsShown()) then
        FGT.OpenWelcome(1)
    end
end)
end
