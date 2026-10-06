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
local FRAME_WIDTH  = 700
local FRAME_HEIGHT = 560
local MIN_FRAME_WIDTH  = 520
local MIN_FRAME_HEIGHT = 360
local MAX_FRAME_WIDTH  = 1100
local MAX_FRAME_HEIGHT = 900

-- The 1100x900 caps above are meaningless if they're bigger than the
-- player's actual screen (in UI units, which is what GetScreenWidth/
-- Height report, and exactly what SetSize/SetPoint use) - that's what
-- previously let the window grow taller than the screen and pushed the
-- resize grip off the bottom edge with no way to reach it. This clamps
-- against whichever is smaller, with a margin so the frame never runs
-- edge-to-edge.
local function GetEffectiveMaxSize()
    local screenW = GetScreenWidth and GetScreenWidth() or MAX_FRAME_WIDTH
    local screenH = GetScreenHeight and GetScreenHeight() or MAX_FRAME_HEIGHT
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
        if IsActive(g) then table.insert(out, g) end
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
    if ForeverGoalTrackerDB.frameWidth == nil then
        ForeverGoalTrackerDB.frameWidth = FRAME_WIDTH
    end
    if ForeverGoalTrackerDB.frameHeight == nil then
        ForeverGoalTrackerDB.frameHeight = FRAME_HEIGHT
    end
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
    for _, want in ipairs(AsList(rule.owned)) do
        if OwnsName(function(n) return n:find(want, 1, true) ~= nil end, roster) then return true, "owned" end
    end
    for _, pat in ipairs(AsList(rule.ownedPattern)) do
        if OwnsName(function(n) return n:find(pat) ~= nil end, roster) then return true, "ownedPattern" end
    end
    return false
end

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
        local n = GetItemInfo and GetItemInfo(id)
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
        if PartSelected(goal, i) then
            total = total + 1
            if IsStepDone(goal.id, i) then
                done = done + 1
            end
        end
    end
    return done, total
end

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
        if PartSelected(goal, i) then
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
}

function FGT.GoalById(id)
    if not FGT.goalIndex then
        FGT.goalIndex = {}
        for _, g in ipairs(FGT.goals) do FGT.goalIndex[g.id] = g end
    end
    return FGT.goalIndex[id]
end

function FGT.LinkText(s)
    return (s:gsub("{([%w_]+):([^}]+)}", function(id, label)
        local alias = FGT.LINK_ALIAS[id]
        if alias then id = alias() end
        if not FGT.GoalById(id) then return label end
        return "|cffffd75e|Hfgtgoal:" .. id .. "|h" .. label .. "|h|r"
    end))
end

-- Makes goal links inside a frame's text hoverable and clickable. While
-- the mouse is on a link, FGT.overLink is set so the step under it
-- doesn't tick (ToggleStep checks it).
function FGT.EnableGoalLinks(f)
    if not f.SetHyperlinksEnabled then return end -- very old clients: plain text
    f:SetHyperlinksEnabled(true)
    f:SetScript("OnHyperlinkEnter", function(self, link)
        local id = link:match("^fgtgoal:(.+)")
        local goal = id and FGT.GoalById(id)
        if not goal then return end
        FGT.overLink = id
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:AddLine(goal.name, C.TITLE[1], C.TITLE[2], C.TITLE[3])
        GameTooltip:AddLine(IsActive(goal) and "On your tracker. Click to open it." or "Click to track this goal.",
            C.INK2[1], C.INK2[2], C.INK2[3])
        GameTooltip:Show()
    end)
    f:SetScript("OnHyperlinkLeave", function()
        FGT.overLink = nil
        GameTooltip:Hide()
    end)
    f:SetScript("OnHyperlinkClick", function(self, link)
        local id = link:match("^fgtgoal:(.+)")
        GameTooltip:Hide()
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
    button   = { top = { 0.240, 0.225, 0.200 }, bottom = { 0.080, 0.075, 0.068 }, edge = { 0.42, 0.37, 0.26, 1 } },
    btnHover = { top = { 0.330, 0.300, 0.240 }, bottom = { 0.120, 0.110, 0.090 }, edge = { 0.85, 0.68, 0.20, 1 } },
    danger   = { top = { 0.420, 0.110, 0.090 }, bottom = { 0.140, 0.030, 0.030 }, edge = { 0.62, 0.22, 0.16, 1 } },
    dangerHv = { top = { 0.540, 0.150, 0.120 }, bottom = { 0.190, 0.045, 0.040 }, edge = { 0.90, 0.35, 0.25, 1 } },
    forever  = { top = { 0.040, 0.120, 0.200 }, bottom = { 0.015, 0.040, 0.075 }, edge = { 0.09, 0.36, 0.55, 1 } },
    -- Blue twins of row / rowHover / rowSel for things new in Forever.
    fRow     = { top = { 0.060, 0.110, 0.180 }, bottom = { 0.020, 0.036, 0.062 }, edge = { 0.09, 0.36, 0.55, 1 } },
    fHover   = { top = { 0.085, 0.160, 0.260 }, bottom = { 0.030, 0.058, 0.095 }, edge = { 0.25, 0.55, 1.00, 1 } },
    fSel     = { top = { 0.070, 0.240, 0.460 }, bottom = { 0.015, 0.075, 0.170 }, edge = { 0.55, 0.78, 1.00, 1 } },
}
-- Which blue twin replaces each gold state.
STYLE.foreverTwin = { [STYLE.row] = STYLE.fRow, [STYLE.rowHover] = STYLE.fHover, [STYLE.rowSel] = STYLE.fSel,
    [STYLE.panel] = STYLE.fRow, [STYLE.button] = STYLE.fRow, [STYLE.btnHover] = STYLE.fHover }

-- Vertical gradient on a texture (top color -> bottom color). SetGradient
-- takes (min = bottom, max = top). Falls back to a flat midpoint color.
local function ApplyVGradient(tex, top, bottom, topA, bottomA)
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
        if self.foreverNew then st = STYLE.foreverTwin[st] or st end
        ApplyVGradient(self.etchBg, st.top, st.bottom)
        self:SetBackdropBorderColor(st.edge[1], st.edge[2], st.edge[3], st.edge[4] or 1)
    end
    frame:SetEtch(style)
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
        return "In WoW Forever's database, but the steps aren't confirmed yet. They follow Classic Era and may differ."
    elseif s == "unconfirmed" then
        return "Not yet confirmed in WoW Forever. These steps follow Classic Era and may differ."
    end
end

-- Bright Forever-blue dot for font strings ("|T...|t", tinted #408cff).
-- The logo is too small to read at chip size, so labels use the dot.
FGT.FOREVER_DOT = "Interface\\AddOns\\" .. ADDON .. "\\Media\\dot"
-- The dot image carries its own soft glow, so the solid core is about
-- 40% of `size`; the glow also spaces it from the word after it. Nudged
-- down 3px to sit level with capital letters (measured in game).
function FGT.ForeverDot(size)
    return string.format("|T%s:%d:%d:0:-3:32:32:0:32:0:32:156:202:255|t", FGT.FOREVER_DOT, size, size)
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
        self.tip:SetShown(on and not complete)
        local look = complete and "done" or (self.blue and "blue" or "gold")
        if look ~= self.look then
            self.look = look
            if look == "done" then
                ApplyHGradient(self.fill, { 0.08, 0.32, 0.04 }, { 0.55, 1.00, 0.40 })
            elseif look == "blue" then
                -- new in Forever: deep Forever blue building to light blue
                ApplyHGradient(self.fill, { 0.01, 0.12, 0.36 }, { 0.40, 0.70, 1.00 })
                ApplyHGradient(self.tip, { 0.40, 0.70, 1.00 }, { 0.80, 0.92, 1.00 }, 0, 0.75)
            else
                ApplyHGradient(self.fill, { 0.32, 0.18, 0.01 }, { 1.00, 0.86, 0.30 })
                ApplyHGradient(self.tip, { 1.00, 0.85, 0.40 }, { 1.00, 0.95, 0.70 }, 0, 0.75)
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
    return bar
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
    if FGT.quietCelebrate then was = complete end -- undoing a reset: no fanfare
    FGT.doneSeen[key] = complete
    if row.fxKey and row.fxKey ~= key then FGT.EndCelebration(row) end
    if complete and was == false then
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
    local travel = math.max(0, f:GetWidth() - 103 - 2 * inset)
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
    if row.isDone and FGT.justTicked == goalId .. "|" .. key then
        FGT.justTicked = nil
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

    -- The ring keeps moving until it's gone: a gentle ease-out, and a
    -- fade that finishes first, so it never sits still while visible.
    local r = Clamp01(t / 0.55)
    local o = 7 * (1 - (1 - r) ^ 2)
    self.burst:ClearAllPoints()
    self.burst:SetPoint("TOPLEFT", -o, o)
    self.burst:SetPoint("BOTTOMRIGHT", o, -o)
    self.burst:SetAlpha((1 - r) ^ 2)

    ShineFrame(self, Clamp01((t - 0.06) / 0.55), self.fxInset)
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
    else
        row.popChip, row.popTex, row.popSize = nil, row.doneCheck, 20
    end
    row.fxT = 0
    row.burst:Show()
    ShowShine(row, true)
    CelebrateStep(row, 0)
    row:SetScript("OnUpdate", CelebrateStep)
end

-- The goal's progress bar: once its fill glides all the way to 100%,
-- a gold shine runs along it. Called by the bar itself (bar.celebrate).
local function BarShineStep(self, elapsed)
    self.shineT = self.shineT + elapsed
    local sh = Clamp01(self.shineT / 0.6)
    ShineFrame(self, sh, 1)
    if sh >= 1 then
        self:SetScript("OnUpdate", nil)
        ShowShine(self, false)
    end
end

function FGT.BarShine(bar)
    if not bar.shineL then MakeShine(bar, math.max(2, bar:GetHeight() - 2)) end
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
local FADE_STEPS = 6
local function CreateEdgeFade(parent, isTop)
    local height = 16
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(height)
    f:SetFrameStrata(parent:GetFrameStrata())
    f:SetFrameLevel(parent:GetFrameLevel() + 20)
    local c = C.PANEL
    local stepH = height / FADE_STEPS
    for i = 1, FADE_STEPS do
        -- i = 1 sits at the outer edge (nearly opaque panel color) and
        -- fades toward ~0 alpha by the inner edge, closest to the content.
        local alpha = 1 - ((i - 0.5) / FADE_STEPS)
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
local function CreateScrollArea(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)

    local fadeTop = CreateEdgeFade(parent, true)
    local fadeBottom = CreateEdgeFade(parent, false)

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
    local track = Flat(trackHit, 1, 1, 1, 0.05)
    track:SetPoint("TOP", trackHit, "TOP", 0, 0)
    track:SetPoint("BOTTOM", trackHit, "BOTTOM", 0, 0)
    track:SetWidth(3)

    local thumbHit = CreateFrame("Button", nil, trackHit)
    thumbHit:SetWidth(HIT_W)
    thumbHit:SetFrameLevel(trackHit:GetFrameLevel() + 1)
    thumbHit:EnableMouse(true)
    local thumb = Flat(thumbHit, C.GOLD2[1], C.GOLD2[2], C.GOLD2[3], 0.8)
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
        thumb:SetWidth(on and 5 or 3)
        thumb:SetVertexColor(on and C.ACCENT[1] or C.GOLD2[1], on and C.ACCENT[2] or C.GOLD2[2],
            on and C.ACCENT[3] or C.GOLD2[3], on and 1 or 0.8)
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
titleBar:SetHeight(52)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", BeginMove)
titleBar:SetScript("OnDragStop", EndMove)

-- Masthead: Cinzel title in gold, a muted tagline under it, and a gold
-- underline that fades out to the right.
local title = NewTitleString(titleBar, 20)
title:SetText(FGT.NAME)
title:SetPoint("TOPLEFT", 16, -10)

local tagline = NewFontString(titleBar, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
tagline:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
tagline:SetText(FGT.isForever and "Long-term goals for Warcraft Forever" or "Long-term goals for Classic Era")

local titleLine = NewFadeLine(titleBar)
titleLine:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 16, 0)
titleLine:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", -16, 0)

local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPRIGHT", -12, -12)
Etch(closeBtn, STYLE.button, 10)
local closeLabel = NewFontString(closeBtn, 12, "", C.INK2[1], C.INK2[2], C.INK2[3])
closeLabel:SetPoint("CENTER", 0, 1)
closeLabel:SetText("x")
closeBtn:SetScript("OnEnter", function(self)
    self:SetEtch(STYLE.dangerHv)
    closeLabel:SetTextColor(1, 1, 1)
end)
closeBtn:SetScript("OnLeave", function(self)
    self:SetEtch(STYLE.button)
    closeLabel:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3])
end)
closeBtn:SetScript("OnClick", function() main:Hide() end)

-- Overall progress bar
local overallBar = NewBar(main, 8)
overallBar:SetPoint("TOPLEFT", 16, -66)
overallBar:SetPoint("TOPRIGHT", -16, -66)

-- "N of 9 goals complete" summary line under the overall bar
local goalsCompleteText = NewFontString(main, 10, "", C.INK2[1], C.INK2[2], C.INK2[3])
goalsCompleteText:SetPoint("TOPLEFT", overallBar, "BOTTOMLEFT", 0, -4)

-- Tabs sit between the overall bar and the panels.
local TABS_TOP = -98
local PANEL_TOP = -132

-- Left panel (goal list) - "sticky": a fixed width set once via SetWidth,
-- never a second horizontal anchor, so resizing the window never
-- stretches or squishes it. Its height still tracks the window via the
-- TOPLEFT/BOTTOMLEFT anchor pair.
local listPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
listPanel:SetPoint("TOPLEFT", 16, PANEL_TOP)
listPanel:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 16, 16)
listPanel:SetWidth(LIST_WIDTH)
Etch(listPanel, STYLE.panel, 12)

-- Right panel (detail) - fully anchor-driven (both corners), so it
-- fluidly fills whatever space is left of the sticky left panel as the
-- window is resized, with no manual width/height bookkeeping needed.
local detailPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
detailPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 12, 0)
detailPanel:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -16, 16)
Etch(detailPanel, STYLE.panel, 12)

-- Sort control - a dropdown button above the list. Built by hand (not
-- Blizzard's UIDropDownMenu template, which differs between clients).
local sortModes = {
    { key = "alpha",      label = "A - Z",      hint = "Alphabetical" },
    { key = "difficulty", label = "Difficulty", hint = "Easiest first" },
    { key = "duration",   label = "Duration",   hint = "Fastest first" },
    { key = "progress",   label = "Progress",   hint = "Most done first" },
}
local sortModeIndex = 1

-- Styled like the site's toolbar buttons: #3a3a3a, lighter on hover.
local sortBar = CreateFrame("Button", nil, listPanel, "BackdropTemplate")
sortBar:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 6, -6)
sortBar:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -6, -6)
sortBar:SetHeight(22)
Etch(sortBar, STYLE.button, 10)
local sortLabel = NewFontString(sortBar, 10, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
sortLabel:SetPoint("LEFT", sortBar, "LEFT", 8, 0)
-- Gold chevron drawn from two rotated bars, centered on the label's
-- line. Points down when closed, up while the menu is open.
local caret = CreateFrame("Frame", nil, sortBar)
caret:SetSize(12, 8)
caret:SetPoint("RIGHT", sortBar, "RIGHT", -9, 0)
local caretL = caret:CreateTexture(nil, "OVERLAY")
local caretR = caret:CreateTexture(nil, "OVERLAY")
for _, t in ipairs({ caretL, caretR }) do
    t:SetTexture(SOLID)
    t:SetSize(7, 2)
    t:SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
end
caretL:SetPoint("CENTER", caret, "CENTER", -2.4, 0)
caretR:SetPoint("CENTER", caret, "CENTER", 2.4, 0)
local caretText -- fallback if a client can't rotate textures
local function SetCaret(open)
    if caretL.SetRotation then
        local a = math.rad(45)
        caretL:SetRotation(open and a or -a)
        caretR:SetRotation(open and -a or a)
    else
        caretL:Hide(); caretR:Hide()
        if not caretText then
            caretText = NewFontString(caret, 10, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
            caretText:SetPoint("CENTER")
        end
        caretText:SetText(open and "^" or "v")
    end
end
SetCaret(false)

local sortMenu -- created below, once the sort functions exist
sortBar:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
sortBar:SetScript("OnLeave", function(self)
    if not (sortMenu and sortMenu:IsShown()) then self:SetEtch(STYLE.button) end
end)

-- Scrollable content area inside the goal list panel
local listScrollObj = CreateScrollArea(listPanel)
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
-- sort mode, current choice marked with the gold check. A transparent
-- catcher over the window closes it when you click anywhere else.
sortMenu = CreateFrame("Frame", nil, main, "BackdropTemplate")
sortMenu:SetPoint("TOPLEFT", sortBar, "BOTTOMLEFT", 0, -2)
sortMenu:SetPoint("TOPRIGHT", sortBar, "BOTTOMRIGHT", 0, -2)
sortMenu:SetFrameLevel(main:GetFrameLevel() + 60)
Etch(sortMenu, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
sortMenu:EnableMouse(true)
sortMenu:Hide()

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
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetSize(16, 16)
    row.check:SetPoint("LEFT", row, "LEFT", 2, 0)

    row.label = NewFontString(row, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    row.label:SetPoint("LEFT", row, "LEFT", 22, 0)
    row.label:SetText(mode.label)

    row.hint = NewFontString(row, 9, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    row.hint:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.hint:SetJustifyH("RIGHT")
    row.hint:SetText(mode.hint)

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

local function RefreshGoalList()
    -- first, so a goal finished just now already has its date below
    if FGT.CheckGoalCompletions then FGT.CheckGoalCompletions() end
    for _, row in pairs(goalRows) do
        local done, total = GoalProgress(row.goal)
        row.bar:SetProgress(done, total)
        local isSelected = (row.goal.id == selectedId)
        local isNew = FGT.ApplyForeverLook(row, row.goal)
        if isNew then row.newChip:SetLabel(FGT.ForeverDot(12) .. isNew, C.FOREVER_LIGHT) end
        -- Chip line under the name, left to right. A finished goal drops
        -- its difficulty: COMPLETE says all that matters now.
        local finished = total > 0 and done == total
        local prev
        for _, chip in ipairs({ row.diffChip, row.newChip, row.check }) do
            local show = (chip == row.diffChip and not finished)
                or (chip == row.newChip and isNew)
                or (chip == row.check and finished)
            chip:ClearAllPoints()
            if prev then
                chip:SetPoint("LEFT", prev, "RIGHT", 4, 0)
            else
                chip:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -4)
            end
            chip:SetShown(show)
            if show then prev = chip end
        end
        if isSelected then
            row:SetEtch(STYLE.rowSel)
            row.name:SetTextColor(1, 1, 1)
        else
            row:SetEtch(STYLE.row)
            row.name:SetTextColor(C.INK2[1], C.INK2[2], C.INK2[3])
        end
        local favs = ForeverGoalTrackerDB and ForeverGoalTrackerDB.favorites or {}
        local fav = favs[row.goal.id] and true or false
        row.star:SetShown(fav)
        row.name:SetPoint("RIGHT", fav and -26 or -8, 0)
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
        -- the bar's slot shows the completion date once the goal is done
        local on = complete and FGT.CompletedOn(row.goal)
        row.bar:SetShown(not complete)
        row.doneText:SetText(on and ("Completed " .. on) or "")
        row.doneText:SetShown(complete)
        FGT.CheckCelebration(row, "card_" .. row.goal.id, complete, FGT.CelebrateRow)
    end
end

local SelectGoal -- forward declare

local yStart = -8
FGT.ROW_H = 72 -- name, chips, then the bar (or the completion date)
local rowHeight = FGT.ROW_H
for i, goal in ipairs(FGT.goals) do
    local row = CreateFrame("Button", nil, listContent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 6, yStart - (i - 1) * (rowHeight + 4))
    row:SetPoint("RIGHT", listContent, "RIGHT", -6, 0)
    row:SetHeight(rowHeight)
    row.goal = goal
    Etch(row, STYLE.row, 12)

    -- Item icon, rimmed in the category's quality color.
    local catColor = FGT.categoryColors[goal.category] or C.ACCENT
    row.icon = NewIcon(row, 50) -- bottom lines up with the third text line
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -11)
    row.icon:SetIcon(goal.icon, catColor)

    row.name = NewFontString(row, 13, "", C.INK2[1], C.INK2[2], C.INK2[3])
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 9, -1)
    row.name:SetPoint("RIGHT", -8, 0)
    row.name:SetJustifyH("LEFT")
    -- the list uses the goal's short name; the full name shows on the right
    row.name:SetText(goal.short or goal.name)
    row.name:SetWordWrap(false)
    row.name:SetNonSpaceWrap(false)
    row.name:SetShadowColor(0, 0, 0, 1)
    row.name:SetShadowOffset(1, -1)

    local diffColor = FGT.difficultyColors[goal.difficulty] or C.SUBTEXT
    row.diffChip = NewChip(row, 8)
    row.diffChip:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -4)
    row.diffChip:SetLabel(string.upper(goal.difficulty or ""), diffColor)

    -- Forever-only goals: a blue NEW chip with the Forever logo.
    row.newChip = NewChip(row, 8)
    row.newChip:SetPoint("LEFT", row.diffChip, "RIGHT", 4, 0)
    row.newChip:SetLabel(FGT.ForeverDot(12) .. "NEW", C.FOREVER_LIGHT)
    row.newChip:SetBackdropBorderColor(C.FOREVER_DEEP[1], C.FOREVER_DEEP[2], C.FOREVER_DEEP[3], 1)
    row.newChip:Hide()

    row.check = NewChip(row, 8)
    row.check:SetPoint("LEFT", row.diffChip, "RIGHT", 4, 0)
    row.check:SetLabel("COMPLETE", C.DONE)
    row.check:SetBackdropBorderColor(0.16, 0.35, 0.10, 1)
    row.check:Hide()

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
        t:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        t:SetDesaturated(true)
        t:SetSize(part[3], part[3])
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
    row.star:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\star")
    row.star:SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
    row.star:SetSize(15, 15)
    row.star:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
    row.star:Hide()

    -- Last line, level with the icon's bottom: the progress bar, which a
    -- finished goal swaps for the day it was completed (same footprint,
    -- so cards never change height).
    row.bar = NewBar(row, 4)
    row.bar:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 9, 1)
    row.bar:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    row.bar.label:Hide()

    row.doneText = NewFontString(row, 10, "", 0.435, 0.604, 0.369) -- #6f9a5e
    row.doneText:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 9, -1)
    row.doneText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    row.doneText:SetJustifyH("LEFT")
    row.doneText:SetWordWrap(false)

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
        if goalRows[g.id] then goalRows[g.id]:SetShown(IsActive(g)) end
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
local DETAIL_ICON = 50
local detailIcon = NewIcon(detailPanel, DETAIL_ICON)
detailIcon:SetPoint("TOPLEFT", 16, -16)

local detailTag = NewFontString(detailPanel, 10, "", C.ACCENT[1], C.ACCENT[2], C.ACCENT[3])
detailTag:SetPoint("TOPLEFT", detailIcon, "TOPRIGHT", 12, -1)

local detailTitle = NewTitleString(detailPanel, 18)
detailTitle:SetPoint("TOPLEFT", detailTag, "BOTTOMLEFT", 0, -4)
detailTitle:SetPoint("RIGHT", -16, 0)
detailTitle:SetWordWrap(true)

-- Difficulty + time estimate as two chips.
local detailDiffChip = NewChip(detailPanel, 9)
detailDiffChip:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -8)

local detailTimeChip = NewChip(detailPanel, 9)
detailTimeChip:SetPoint("LEFT", detailDiffChip, "RIGHT", 6, 0)

local detailNote = NewFontString(detailPanel, 11, "", C.INK2[1], C.INK2[2], C.INK2[3])
detailNote:SetPoint("TOPLEFT", detailDiffChip, "BOTTOMLEFT", -(DETAIL_ICON + 12), -12)
detailNote:SetPoint("RIGHT", -16, 0)
detailNote:SetWordWrap(true)
detailNote:SetJustifyH("LEFT")

-- WoW Forever: a NEW chip beside the difficulty chips, and a slim blue
-- notice under the description for goals not confirmed in Forever yet.
do
    local chip = NewChip(detailPanel, 9)
    chip:SetLabel(FGT.ForeverDot(13) .. "NEW IN FOREVER", C.FOREVER_LIGHT)
    chip:SetBackdropBorderColor(C.FOREVER_DEEP[1], C.FOREVER_DEEP[2], C.FOREVER_DEEP[3], 1)
    chip:Hide()
    FGT.detailNewChip = chip

    -- "COMPLETED OCT 6, 2026" on finished goals
    local done = NewChip(detailPanel, 9)
    done:SetBackdropBorderColor(0.16, 0.35, 0.10, 1)
    done:Hide()
    FGT.detailDoneChip = done

    local n = CreateFrame("Frame", nil, detailPanel, "BackdropTemplate")
    n:SetPoint("TOPLEFT", detailNote, "BOTTOMLEFT", 0, -12)
    n:SetPoint("RIGHT", -16, 0)
    Etch(n, STYLE.forever, 10)
    n.bug = n:CreateTexture(nil, "ARTWORK")
    n.bug:SetTexture(FGT.FOREVER_BUG)
    n.bug:SetSize(18, 18)
    n.bug:SetPoint("TOPLEFT", 9, -6)
    n.text = NewFontString(n, 10, "", 0.72, 0.84, 1.00)
    n.text:SetPoint("TOPLEFT", n.bug, "TOPRIGHT", 8, -3)
    n.text:SetJustifyH("LEFT")
    n.text:SetWordWrap(true)
    n:Hide()
    FGT.foreverNotice = n
end

local detailBar = NewBar(detailPanel, 8)
detailBar.celebrate = true -- gold shine when it glides to 100%
detailBar:SetPoint("TOPLEFT", detailNote, "BOTTOMLEFT", 0, -12)
detailBar:SetPoint("RIGHT", -16, 0)

-- Shows or hides the Forever chip and notice for a goal, and hangs the
-- progress bar under whichever is last.
function FGT.LayoutForeverInfo(goal)
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

    local n = FGT.foreverNotice
    -- New goals only get the notice when there's something to explain.
    local note = (not word or goal.foreverNote) and FGT.ForeverNote(goal)
    detailBar:ClearAllPoints()
    detailBar:SetPoint("RIGHT", -16, 0)
    if note then
        local w = math.max(120, detailPanel:GetWidth() - 32)
        n.text:SetWidth(w - 9 - 18 - 8 - 10)
        n.text:SetText(note)
        n:SetHeight(math.max(30, math.ceil(n.text:GetStringHeight()) + 18))
        n:Show()
        detailBar:SetPoint("TOPLEFT", n, "BOTTOMLEFT", 0, -14)
    else
        n:Hide()
        detailBar:SetPoint("TOPLEFT", detailNote, "BOTTOMLEFT", 0, -12)
    end
end

local divider = NewFadeLine(detailPanel)
divider:SetPoint("TOPLEFT", detailBar, "BOTTOMLEFT", 0, -24)
divider:SetPoint("RIGHT", -16, 0)

local stepsHeader = NewTitleString(detailPanel, 12)
stepsHeader:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -10)
stepsHeader:SetText("Step by Step")

-- "Expand all" / "Collapse all" on the right of the heading, for goals
-- with two or more groups chosen (mount races, set classes). Groups only;
-- Tier 3 pieces keep their materials folded.
do
    local b = CreateFrame("Button", nil, detailPanel)
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
    if not goal.sections or FGT.SelectedPartCount(goal) < 2 then b:Hide() return end
    local anyClosed = false
    for si in ipairs(goal.sections) do
        if PartSelected(goal, si) and not FGT.sectionOpen[goal.id .. "_" .. si] then anyClosed = true end
    end
    b.text:SetText(anyClosed and "Expand all" or "Collapse all")
    b:SetSize(math.ceil(b.text:GetStringWidth()) + 4, 16)
    b:SetScript("OnClick", function()
        for si in ipairs(goal.sections) do
            if PartSelected(goal, si) then FGT.sectionOpen[goal.id .. "_" .. si] = anyClosed or nil end
        end
        SelectGoal(goal.id, true) -- (RefreshSteps is declared further down)
    end)
    b:Show()
end

local stepsScrollObj = CreateScrollArea(detailPanel)
stepsScrollObj.scroll:SetPoint("TOPLEFT", stepsHeader, "BOTTOMLEFT", 0, -8)
stepsScrollObj.scroll:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -24, 40)
stepsScrollObj:Finalize()
local stepsContainer = stepsScrollObj.content
-- Tips are drawn straight on the list, so it carries their goal links.
stepsContainer:EnableMouse(true)
FGT.EnableGoalLinks(stepsContainer)
stepsContainer:SetHeight(1)

local resetBtn = CreateFrame("Button", nil, detailPanel, "BackdropTemplate")
resetBtn:SetSize(110, 22)
resetBtn:SetPoint("BOTTOMRIGHT", -14, 12)
-- The site's "remove" action colors: #5a1f1f with #ffbfbf text.
Etch(resetBtn, STYLE.danger, 10)
local resetLabel = NewFontString(resetBtn, 10, "", 1, 0.75, 0.75)
resetLabel:SetPoint("CENTER")
resetLabel:SetText("Reset this goal")
-- After a reset the button offers "Undo reset" for 10 seconds, holding
-- a copy of the goal's ticks (and its finished state and date).
-- FGT.resetUndo = { id, progress, done, date } while that's possible.
function FGT.StyleResetButton()
    local undo = FGT.resetUndo
    local hover = resetBtn:IsMouseOver()
    if undo then
        resetBtn:SetEtch(hover and STYLE.btnHover or STYLE.button)
        resetLabel:SetText("Undo reset")
        resetLabel:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
    else
        resetBtn:SetEtch(hover and STYLE.dangerHv or STYLE.danger)
        resetLabel:SetText("Reset this goal")
        resetLabel:SetTextColor(1, 0.75, 0.75)
    end
end
resetBtn:SetScript("OnEnter", FGT.StyleResetButton)
resetBtn:SetScript("OnLeave", FGT.StyleResetButton)
resetBtn:SetScript("OnClick", function()
    if not selectedId then return end
    local DB = ForeverGoalTrackerDB
    local undo = FGT.resetUndo
    if undo and undo.id == selectedId then
        -- Put everything back, quietly: no celebration for ticks you had.
        DB.progress[undo.id] = undo.progress
        if DB.goalsDone then DB.goalsDone[undo.id] = undo.done end
        if DB.goalDates then DB.goalDates[undo.id] = undo.date end
        FGT.resetUndo = nil
        FGT.quietCelebrate = true
        SelectGoal(selectedId)
        FGT.quietCelebrate = nil
    else
        local copy = {}
        for k, v in pairs(DB.progress[selectedId] or {}) do copy[k] = v end
        undo = { id = selectedId, progress = copy,
            done = DB.goalsDone and DB.goalsDone[selectedId],
            date = DB.goalDates and DB.goalDates[selectedId] }
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
    row:SetPoint("LEFT", stepsContainer, "LEFT", 0, 0)
    row:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
    FGT.EnableGoalLinks(row)

    row.box = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.box:SetSize(16, 16)
    row.box:SetPoint("TOPLEFT", 2, -2)
    -- Checkbox styled like a talent slot: black well with a gray ring,
    -- ring turns white on hover and gold once checked ("maxed").
    Skin(row.box, { 0, 0, 0, 1 }, C.BOX_RING)

    row.hover = Flat(row, 1, 1, 1, 0.04)
    row.hover:SetAllPoints(row)
    row.hover:Hide()
    row:SetScript("OnEnter", function(self)
        self.hover:Show()
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
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetSize(22, 22)
    row.check:SetPoint("CENTER", 1, 1)
    row.check:Hide()

    row.num = NewFontString(row, 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    -- sits 2px lower than the text top so the smaller number shares its baseline
    row.num:SetPoint("TOPLEFT", row.box, "TOPRIGHT", 8, -1)

    -- Optional per-step icon (used by "Level Every Class to 60").
    row.icon = NewIcon(row, 20)
    row.icon:SetPoint("TOPLEFT", row.box, "TOPRIGHT", 8, 2)
    row.icon:Hide()

    row.text = NewFontString(row, 12, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
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
    row.doneCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.doneCheck:SetSize(18, 18)
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
            self.icon:SetIcon(spec, C.GOLD2)
            self.icon:Show()
            self.num:Hide()
            self.text:SetPoint("LEFT", self.icon, "RIGHT", 8, 0)
        else
            self.icon:Hide()
            self.num:Show()
            self.text:SetPoint("TOPLEFT", self.num, "TOPRIGHT", 4, 2)
        end
        self.text:SetPoint("RIGHT", self, "RIGHT", 0, 0)
    end
    row:SetStepIcon(nil)

    stepRowPool[index] = row
    return row
end

local function ToggleStep(goalId, index)
    if FGT.overLink then return end -- the click was on a goal link in the step
    local nowDone = not IsStepDone(goalId, index)
    SetStepDone(goalId, index, nowDone)
    FGT.justTicked = nowDone and (goalId .. "|" .. index) or nil
    SelectGoal(goalId, true)
end

-- Shared checked/unchecked visual state for any pooled checkbox row
-- (flat steps, Tier 3 pieces, and Tier 3 materials all use this).
local function StyleCheckRow(row, done)
    row.isDone = done and true or false
    if done then
        row.check:Show()
        row.box:SetBackdropColor(C.BOX_DONE_BG[1], C.BOX_DONE_BG[2], C.BOX_DONE_BG[3], 1)
        row.box:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
        row.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        row.num:SetTextColor(C.GOLD2[1], C.GOLD2[2], C.GOLD2[3])
    else
        row.check:Hide()
        row.box:SetBackdropColor(0, 0, 0, 1)
        row.box:SetBackdropBorderColor(C.BOX_RING[1], C.BOX_RING[2], C.BOX_RING[3], 1)
        row.text:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3])
        row.num:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
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
FGT.sectionOpen = {} -- "goalId_section" -> true while that group is open
FGT.pieceExpanded = {} -- "goalId_section_piece" -> true while its materials are shown

local function GetHeaderRow(index)
    local row = headerRowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, stepsContainer, "BackdropTemplate")
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
    row.doneCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.doneCheck:SetSize(20, 20)
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

local RefreshSteps -- forward declare, so the header click handler below
                    -- can re-run the full refresh after toggling expansion.

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
function FGT.LayoutTips(goal, yOffset, width)
    local T = FGT.tipsUI
    if not T then
        T = { rows = {} }
        T.line = NewFadeLine(stepsContainer)
        T.header = NewTitleString(stepsContainer, 12)
        T.header:SetText("Tips")
        FGT.tipsUI = T
    end
    local tips = goal.tips or {}
    for i = #tips + 1, #T.rows do
        T.rows[i]:Hide()
        T.rows[i].dot:Hide()
    end
    if #tips == 0 then
        T.line:Hide()
        T.header:Hide()
        return yOffset
    end

    yOffset = yOffset + 8
    T.line:ClearAllPoints()
    T.line:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
    T.line:SetPoint("RIGHT", stepsContainer, "RIGHT", -16, 0)
    T.line:Show()
    yOffset = yOffset + 11
    T.header:ClearAllPoints()
    T.header:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
    T.header:Show()
    yOffset = yOffset + (T.header:GetStringHeight() or 12) + 10

    for i, tip in ipairs(tips) do
        local row = T.rows[i]
        if not row then
            row = NewFontString(stepsContainer, 12, "", C.INK2[1], C.INK2[2], C.INK2[3])
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
        row:SetWidth(math.max(50, width - 18))
        row:SetText(FGT.LinkText(tip))
        row:Show()
        row.dot:ClearAllPoints()
        row.dot:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 3, -yOffset - 5)
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
        if PartSelected(goal, si) then
        headerIndex = headerIndex + 1
        local header = GetHeaderRow(headerIndex)
        header:SetParent(stepsContainer)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
        header:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)

        local openKey = goal.id .. "_" .. si
        local expanded = FGT.sectionOpen[openKey]
        header.arrow:SetText(expanded and "-" or "+")
        -- a part that's new in Forever (the Skyborne mount): blue look + NEW
        local partNew = FGT.ApplyForeverLook(header, section)
        header.name:SetText(partNew and (section.name .. "   " .. FGT.NewTag(partNew)) or section.name)
        header.icon:SetIcon(section.icon or goal.icon, C.GOLD2)
        header.expanded = expanded and true or false

        local sd, st = SectionProgress(goal, si, section)
        header.complete = st > 0 and sd == st
        header.count:SetText(sd .. " / " .. st)
        header.count:SetShown(not header.complete)
        header.doneCheck:SetShown(header.complete)
        header.doneGlow:SetShown(header.complete)
        header:ApplyState(header:IsMouseOver())
        -- An open group that finishes just now folds itself closed once
        -- its celebration has played, so its quiet finished look shows.
        local justDone = header.complete and FGT.doneSeen[openKey] == false and not FGT.quietCelebrate
        FGT.CheckCelebration(header, openKey, header.complete, FGT.CelebrateRow)
        if justDone and expanded then
            C_Timer.After(1.4, function()
                if FGT.sectionOpen[openKey] and selectedId == goal.id then
                    FGT.sectionOpen[openKey] = nil
                    RefreshSteps(goal)
                end
            end)
        end

        header:SetScript("OnClick", function()
            FGT.sectionOpen[openKey] = not FGT.sectionOpen[openKey] or nil
            RefreshSteps(goal)
        end)
        header:Show()
        yOffset = yOffset + header:GetHeight() + 4

        if expanded then
            for pi, piece in ipairs(section.pieces) do
                rowIndex = rowIndex + 1
                local row = GetStepRow(rowIndex)
                row:SetParent(stepsContainer)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
                row:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
                SetRowIndent(row, 18)
                row:SetStepIcon(piece.icon) -- item icon when the set data has one

                -- Pieces with materials fold open individually (closed by
                -- default) and show how many of their materials are done.
                local hasMats = #piece.materials > 0
                local pieceKey = goal.id .. "_" .. si .. "_" .. pi
                local open = hasMats and FGT.pieceExpanded[pieceKey]
                local md, mt = FGT.PieceProgress(goal.id, si, pi, piece)

                row.num:SetText("")
                row.text:SetText(FGT.StepText(piece.text or piece.name))
                row.text:SetWidth(math.max(50, width - 18 - 44 - (hasMats and 44 or 0) - (piece.icon and 14 or 0)))
                StyleCheckRow(row, md == mt)
                if not hasMats then FGT.MaybePopTick(row, goal.id, PieceKey(si, pi)) end

                if hasMats then
                    -- No checkbox: the piece is done when its materials are.
                    -- The +/- takes the checkbox's spot, like the class headers.
                    row.box:Hide()
                    row.toggle:ClearAllPoints()
                    row.toggle:SetPoint("TOPLEFT", row, "TOPLEFT", 20, -3)
                    row.toggle:SetText(open and "-" or "+")
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
                row:SetScript("OnClick", function(self)
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
                        rowIndex = rowIndex + 1
                        local mrow = GetStepRow(rowIndex)
                        mrow:SetParent(stepsContainer)
                        mrow:ClearAllPoints()
                        mrow:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
                        mrow:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
                        SetRowIndent(mrow, 40)
                        mrow:SetStepIcon(nil)

                        mrow.num:SetText("")
                        mrow.text:SetText(FGT.StepText(materialText))
                        mrow.text:SetWidth(math.max(50, width - 40 - 44))
                        StyleCheckRow(mrow, IsStepDone(goal.id, MaterialKey(si, pi, mi)))
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
                        mrow:SetScript("OnClick", function()
                            ToggleStep(goal.id, MaterialKey(si, pi, mi))
                        end)
                        mrow:Show()
                        yOffset = yOffset + mRowHeight + 3
                    end
                    yOffset = yOffset + 4
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
    yOffset = FGT.LayoutTips(goal, yOffset, width)
    stepsContainer:SetHeight(math.max(1, yOffset))
    stepsScrollObj:Update()
end

RefreshSteps = function(goal)
    if goal.sections then
        RefreshTierSections(goal)
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
        if not PartSelected(goal, i) then
            row:Hide() -- part of a group you haven't added
        else
        shown = shown + 1
        row:SetParent(stepsContainer)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", stepsContainer, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", stepsContainer, "RIGHT", 0, 0)
        SetRowIndent(row, 2)

        row.num:SetText(shown .. ".")
        row:SetStepIcon(stepIcon)

        local rowHeight2
        if IsAutoStep(entry) then
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

            StyleCheckRow(row, IsStepDone(goal.id, i))
            FGT.MaybePopTick(row, goal.id, i)

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

            row:SetScript("OnClick", function()
                ToggleStep(goal.id, i)
            end)
        end

        row:Show()
        yOffset = yOffset + rowHeight2 + 6
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
    yOffset = FGT.LayoutTips(goal, yOffset, width)
    stepsContainer:SetHeight(math.max(1, yOffset))
    stepsScrollObj:Update()
end

SelectGoal = function(id, skipListRefresh)
    local goal
    for _, g in ipairs(FGT.goals) do
        if g.id == id and IsActive(g) then goal = g break end
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
    local catColor = FGT.categoryColors[goal.category] or C.ACCENT
    detailIcon:SetIcon(goal.icon, catColor)
    detailTag:SetText(string.upper(goal.category))
    detailTag:SetTextColor(catColor[1], catColor[2], catColor[3])

    local diffColor = FGT.difficultyColors[goal.difficulty] or C.SUBTEXT
    detailDiffChip:SetLabel(string.upper(goal.difficulty or ""), diffColor)
    if goal.timeEstimate then
        detailTimeChip:SetLabel(goal.timeEstimate, C.INK2)
        detailTimeChip:Show()
    else
        detailTimeChip:Hide()
    end

    detailNote:SetText(goal.note or "")
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

local function NewTab(label)
    local tab = CreateFrame("Button", nil, main, "BackdropTemplate")
    tab:SetHeight(26)
    Etch(tab, STYLE.button, 10)
    tab.text = NewTitleString(tab, 12)
    tab.text:SetPoint("CENTER", 0, 0)
    tab.text:SetText(label)
    tab:SetWidth(math.ceil(tab.text:GetStringWidth()) + 40)
    tab:SetScript("OnEnter", function(self) if not self.active then self:SetEtch(STYLE.btnHover) end end)
    tab:SetScript("OnLeave", function(self) if not self.active then self:SetEtch(STYLE.button) end end)
    function tab:SetActive(on)
        self.active = on
        self:SetEtch(on and STYLE.rowSel or STYLE.button)
        if on then
            self.text:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3])
        else
            self.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
        end
    end
    return tab
end

local trackerTab = NewTab("My Goals")
trackerTab:SetPoint("TOPLEFT", main, "TOPLEFT", 16, TABS_TOP)
local libraryTab = NewTab("Goal Library")
libraryTab:SetPoint("LEFT", trackerTab, "RIGHT", 6, 0)
-- the goal list lines up with the right edge of the Goal Library tab
listPanel:SetWidth(trackerTab:GetWidth() + 6 + libraryTab:GetWidth())

-- Empty tracker (first open, or every goal removed): cobwebs in the
-- goal list's top corners like an empty quest log, a quiet "Empty"
-- label, and on the right a short note with a button to the Library.
local emptyNote = NewFontString(detailPanel, 12, "", C.INK2[1], C.INK2[2], C.INK2[3])
emptyNote:SetPoint("CENTER", detailPanel, "CENTER", 0, 24)
emptyNote:SetWidth(320)
emptyNote:SetJustifyH("CENTER")
emptyNote:SetText("No goals on your tracker yet.\n\nPick the ones you want to chase from the Goal Library.")
emptyNote:Hide()

do
    local E = {}
    local web = "Interface\\AddOns\\" .. ADDON .. "\\Media\\web"
    E.webL = listPanel:CreateTexture(nil, "ARTWORK")
    E.webL:SetTexture(web)
    E.webL:SetSize(110, 110)
    E.webL:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 3, -3)
    E.webL:SetVertexColor(0.75, 0.72, 0.66, 0.45)
    E.webR = listPanel:CreateTexture(nil, "ARTWORK")
    E.webR:SetTexture(web)
    E.webR:SetTexCoord(1, 0, 0, 1) -- mirrored for the right corner
    E.webR:SetSize(110, 110)
    E.webR:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -3, -3)
    E.webR:SetVertexColor(0.75, 0.72, 0.66, 0.45)

    E.label = NewTitleString(listPanel, 13)
    E.label:SetPoint("CENTER", listPanel, "CENTER", 0, 40)
    E.label:SetText("Empty")
    E.label:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    E.label:SetShadowColor(0, 0, 0, 1)

    E.button = CreateFrame("Button", nil, detailPanel, "BackdropTemplate")
    E.button:SetHeight(28)
    Etch(E.button, STYLE.button, 10)
    E.button.text = NewTitleString(E.button, 12)
    E.button.text:SetPoint("CENTER", 0, 0)
    E.button.text:SetText("Browse the Goal Library")
    E.button:SetWidth(math.ceil(E.button.text:GetStringWidth()) + 40)
    E.button:SetPoint("TOP", emptyNote, "BOTTOM", 0, -16)
    E.button:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
    E.button:SetScript("OnLeave", function(self) self:SetEtch(STYLE.button) end)
    E.button:SetScript("OnClick", function() if FGT.ShowTab then FGT.ShowTab("library") end end)

    E.parts = { E.webL, E.webR, E.label, E.button }
    for _, p in ipairs(E.parts) do p:Hide() end
    FGT.emptyUI = E
end

local detailParts -- every detail-panel element hidden by the empty state
function FGT.ShowEmptyTracker()
    selectedId = nil
    for _, part in ipairs(detailParts) do part:Hide() end
    emptyNote:Show()
    for _, p in ipairs(FGT.emptyUI.parts) do p:Show() end
    sortBar:Hide() -- nothing to sort
    RefreshGoalList()
    RefreshOverall()
end
function FGT.HideEmptyTracker()
    if not emptyNote:IsShown() then return end
    emptyNote:Hide()
    for _, p in ipairs(FGT.emptyUI.parts) do p:Hide() end
    sortBar:Show()
    for _, part in ipairs(detailParts) do part:Show() end
end
detailParts = { detailIcon, detailTag, detailTitle, detailDiffChip, detailTimeChip, detailNote,
    detailBar, detailBar.label, divider, stepsHeader, stepsScrollObj.scroll, resetBtn,
    FGT.detailNewChip, FGT.detailDoneChip, FGT.foreverNotice, FGT.expandAllBtn }

-- ------------------------------------------------------------
-- Library panel
-- ------------------------------------------------------------
local libraryPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
libraryPanel:SetPoint("TOPLEFT", main, "TOPLEFT", 16, PANEL_TOP)
libraryPanel:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -16, 16)
Etch(libraryPanel, STYLE.panel, 12)
libraryPanel:Hide()

local libHeader = NewTitleString(libraryPanel, 14)
libHeader:SetPoint("TOPLEFT", 14, -12)
libHeader:SetText("Goal Library")

local libSummary = NewFontString(libraryPanel, 10, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
libSummary:SetPoint("LEFT", libHeader, "RIGHT", 10, -1)

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
    glass:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    glass:SetSize(13, 13)
    glass:SetPoint("LEFT", 6, -1)
    glass:SetVertexColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])

    local hint = NewFontString(box, 11, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    hint:SetPoint("LEFT", 22, 0)
    hint:SetText("Search goals")

    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(16, 16)
    clear:SetPoint("RIGHT", -4, 0)
    clear.text = NewFontString(clear, 12, "", C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3])
    clear.text:SetPoint("CENTER", 0, 0)
    clear.text:SetText("x")
    clear:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
    clear:SetScript("OnLeave", function(self) self.text:SetTextColor(C.SUBTEXT[1], C.SUBTEXT[2], C.SUBTEXT[3]) end)
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
    -- Forever-only goals can't be earned on Classic Era.
    if goal.forever == "new" and not FGT.isForever then return false end
    if goal.faction and not IsActive(goal) and libFilter ~= "all" then
        -- All shows everything; filters with faction goals (PvP,
        -- Reputation, Attunements) follow the Alliance / Horde / Both picker
        local want = FGT.factionSeg.Current()
        if want ~= "Both" and goal.faction ~= want then return false end
    end
    local q = FGT.libSearch
    if q and q ~= "" then
        local hay = (goal.name .. " " .. (goal.short or "") .. " " .. (goal.category or "") .. " " .. (goal.faction or "")):lower()
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

local libExpanded = {}

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
    local sel = ForeverGoalTrackerDB.activeParts[goal.id] or {}
    ForeverGoalTrackerDB.activeParts[goal.id] = sel
    sel[key] = on or nil
    AfterSelectionChange(goal, IsActive(goal))
end

local function SetGoalActive(goal, on)
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
            row.label = NewFontString(row, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
            row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
            row:SetScript("OnEnter", function(self) self.hl:Show() end)
            row:SetScript("OnLeave", function(self) self.hl:Hide() end)
            M.rows[i] = row
        end
        M:SetHeight(2 * MENU_ROW + 8)

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
        M.rows[2].label:SetTextColor(1.00, 0.50, 0.42)
        M.rows[2]:SetScript("OnClick", function()
            local goal = M.goal
            FGT.CloseGoalMenu()
            ForeverGoalTrackerDB.favorites[goal.id] = nil
            SetGoalActive(goal, false)
        end)
        FGT.goalMenu = M
    end

    M.goal = card.goal
    local fav = ForeverGoalTrackerDB.favorites[card.goal.id]
    M.rows[1].label:SetText(fav and "Remove from favorites" or "Add to favorites")

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
        L.btn:SetScript("OnEnter", function(self) self:SetEtch(STYLE.btnHover) end)
        L.btn:SetScript("OnLeave", function(self) self:SetEtch(STYLE.button) end)
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
        FGT.linkCard = L
    end

    L.goal = goal
    local catColor = FGT.categoryColors[goal.category] or C.ACCENT
    L.icon:SetIcon(goal.icon, catColor)
    L.tag:SetText(string.upper(goal.category))
    L.tag:SetTextColor(catColor[1], catColor[2], catColor[3])
    L.name:SetText(goal.name)
    L.note:ClearAllPoints()
    L.note:SetPoint("TOPLEFT", L, "TOPLEFT", 12, -12 - math.max(36, 16 + L.name:GetStringHeight()) - 10)
    L.note:SetText(goal.note or "")
    local active = IsActive(goal)
    L.btn.text:SetText(active and "Open goal" or "+ Add to My Goals")
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
-- shift the label right by half the checkmark's width (16px + 1px gap).
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
    if on then
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

    card.btn = CreateFrame("Button", nil, card, "BackdropTemplate")
    card.btn:SetSize(92, 26)
    card.btn:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    Etch(card.btn, STYLE.button, 10)
    card.btnText = NewFontString(card.btn, 11, "", C.TEXT[1], C.TEXT[2], C.TEXT[3])
    card.btnText:SetPoint("CENTER", 0, 0)
    card.btnText:SetJustifyH("CENTER")
    card.btnCheck = card.btn:CreateTexture(nil, "OVERLAY")
    card.btnCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    card.btnCheck:SetSize(16, 16)
    card.btnCheck:SetPoint("RIGHT", card.btnText, "LEFT", -1, 0)
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
        self:SetEtch(STYLE.row)
        GameTooltip:Hide()
    end)

    libCards[goal.id] = card
    return card
end

-- One row per part of a group goal, shown under its card when expanded.
local SUB_H = 32
local function StyleSubButton(sub)
    local on = FGT.PartSelected(sub.goal, sub.key)
    local hover = sub.btn:IsMouseOver()
    if on then
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
        card.subs[index] = sub
    end
    sub.goal, sub.key = card.goal, part.key
    local partNew = FGT.ApplyForeverLook(sub, part)
    sub.label:SetText(partNew and (part.label .. "   " .. FGT.NewTag(partNew)) or part.label)
    sub:SetEtch(STYLE.panel) -- blue twin when the part is new
    sub.icon:SetIcon(part.icon or card.goal.icon, partNew and C.FOREVER or C.GOLD2)
    StyleSubButton(sub)
    return sub
end

-- Progress of a single part (for the little bar under each part).
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
        card.metaBase = isNew and (FGT.NewTag(isNew) .. "  ·  " .. card.metaPlain) or card.metaPlain
        card.meta:SetText(card.metaBase)
        local d, t = GoalProgress(g)
        card.bar:SetProgress(d, t)
        -- only goals on the tracker can make progress, so only they get a bar
        card.bar:SetShown(IsActive(g))
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
                    sub.bar:SetProgress(pd, pt)
                    sub.bar:SetShown(FGT.PartSelected(g, part.key))
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

    libSummary:SetText(string.format("%d of %d goals on your tracker", #ActiveGoals(), #FGT.goals))
end
libScroll:Finalize()
FGT.LayoutLibrary = LayoutLibrary

local function ShowTab(which)
    ForeverGoalTrackerDB.tab = which
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
trackerTab:SetScript("OnClick", function() ShowTab("tracker") end)
libraryTab:SetScript("OnClick", function() ShowTab("library") end)
libraryPanel:SetScript("OnSizeChanged", function() if libraryPanel:IsShown() then LayoutLibrary() end end)

end

-- ============================================================
-- Toggle / init
-- ============================================================
function FGT.ToggleFrame()
    if main:IsShown() then
        main:Hide()
    else
        main:SetAlpha(0)
        main:Show()
        if UIFrameFadeIn then
            UIFrameFadeIn(main, 0.15, 0, 1)
        else
            main:SetAlpha(1)
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
    toast:SetPoint("TOP", UIParent, "TOP", 0, -70)
    toast:SetFrameStrata("HIGH")
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
    toast.doneCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    toast.doneCheck:SetSize(20, 20)
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
                FGT.CelebrateRow(t)
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

local function Announce(goal)
    print(TAG .. "You just completed " .. GoalLink(goal) .. "! " .. Pick(PRAISE))
    table.insert(queue, goal)
    if not (toast and toast:IsShown()) then FGT.NextToast() end
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
    Announce(goal)
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
    local quiet = first or main:IsShown()
    for _, g in ipairs(ActiveGoals()) do
        local d, t = GoalProgress(g)
        if t > 0 and d == t then
            if not DB.goalsDone[g.id] then
                DB.goalsDone[g.id] = true
                if not first then DB.goalDates[g.id] = time() end
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
    local sw, sh = GetScreenWidth(), GetScreenHeight()
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
        local star = "|TInterface\\AddOns\\" .. ADDON .. "\\Media\\star:12:12:0:0:64:64:0:64:0:64:255:209:0|t "
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
    ApplyAutoRules() -- re-check against the saved roster from earlier sessions

    -- Re-clamp against the CURRENT screen every load, not just the
    -- fixed 1100x900 caps - this is what self-heals a previously
    -- saved oversized window (or one saved on a bigger monitor) back
    -- to something that actually fits and keeps the resize grip
    -- reachable.
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
    if changed > 0 and announce and not FGT.firstRun then
        print(TAG .. string.format("%d step%s checked off automatically.",
            changed, changed == 1 and "" or "s"))
    end
    RefreshOpenWindow()
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
    if changed > 0 then
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
    if event == "PLAYER_LOGOUT" then RecordCharacter(); return end

    if event == "PLAYER_LEVEL_UP" then
        local before = Roster()[CharKey()]
        local oldLevel = before and before.level
        RecordCharacter()
        local me = Roster()[CharKey()]
        if me and arg1 then
            -- UnitLevel can lag a frame behind the event; trust the event.
            me.level, me.xp = arg1, 0
            if arg1 >= MAX_LEVEL and (oldLevel or 0) < MAX_LEVEL then
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
        ScanNow(true)
        if not FGT.firstRun then FGT.LoginGreeting() end
        return
    end
    ScanSoon()
end)

end

SLASH_FOREVERGOALTRACKER1 = "/goals"
SLASH_FOREVERGOALTRACKER2 = "/fgt"
SLASH_FOREVERGOALTRACKER3 = "/forevergoals"
SlashCmdList["FOREVERGOALTRACKER"] = function(msg)
    msg = tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "testbanner" then
        FGT.TestBanner()
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
        if ForeverGoalTrackerDB then
            ForeverGoalTrackerDB.frameWidth = FRAME_WIDTH
            ForeverGoalTrackerDB.frameHeight = FRAME_HEIGHT
        end
        ForeverGoalTrackerDB.frameLeft, ForeverGoalTrackerDB.frameTop = nil, nil
        FGT.PlaceWindow()
        LayoutGoalList()
        if selectedId then
            SelectGoal(selectedId, true)
        end
        if not main:IsShown() then
            FGT.ToggleFrame()
        end
        print(TAG .. "window size and position reset.")
    else
        FGT.ToggleFrame()
    end
end
