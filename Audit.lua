local ADDON, FGT = ...

-- ============================================================
-- Data audit (/goals audit)
-- ============================================================
-- Asks the game itself about every item, quest, faction and map the addon
-- relies on, so the data can be kept honest without leaning on a website:
-- is the item revealed on this client (Forever hides items until a player
-- finds one), what does the game call it, does the quest title match ours,
-- does the faction or map still exist. Nothing runs at login; the command
-- queues the questions a few at a time, writes the answers to
-- ForeverGoalTrackerDB.audit (saved at /reload or logout) and prints a
-- summary. tools/auditreport.py turns the saved answers into a to-do list.
local A = {}
FGT.Audit = A

local TAG = "|cffffd75eForever Goal Tracker:|r "
local PER_STEP, STEP = 15, 0.3 -- 15 questions every 0.3 s: about 50 a second, gentle on the server
local SETTLE = 5               -- seconds to wait for late answers

local function List(v)
    if type(v) == "table" then return v end
    if v == nil then return {} end
    return { v }
end

-- Everything we rely on, and where, so a report can say "Thunderfury step 4".
-- Returns { items = { [id] = { uses = {...}, names = { [name] = true } } },
--           quests = { ... }, factions = { ... }, maps = { [id] = { uses, names } } }
function A.Targets()
    local T = { items = {}, quests = {}, factions = {}, maps = {} }
    local function slot(kind, id)
        if type(id) ~= "number" then return nil end
        local s = T[kind][id]
        if not s then s = { uses = {}, names = {} }; T[kind][id] = s end
        return s
    end
    local function use(kind, id, where, name)
        local s = slot(kind, id)
        if not s then return end
        if #s.uses < 5 then s.uses[#s.uses + 1] = where end
        if name then s.names[name] = true end
    end
    local function tags(text, where)
        for id, name in (text or ""):gmatch("{item:(%d+):([^}]+)}") do use("items", tonumber(id), where, name) end
    end
    -- unknown: the step says "Source unknown", so an item that is now revealed is worth a look
    local function rule(r, where, unknown)
        if type(r) ~= "table" then return end
        for _, id in ipairs(List(r.item)) do
            use("items", id, where)
            if unknown and T.items[id] then T.items[id].srcUnknown = true end
        end
        for _, id in ipairs(List(r.quest)) do use("quests", id, where) end
        for _, id in ipairs(List(r.questTaken)) do use("quests", id, where) end
        if type(r.rep) == "table" then
            for _, id in ipairs(List(r.rep.faction)) do use("factions", id, where) end
        end
    end
    local function links(list, where)
        for _, l in ipairs(list or {}) do
            use("items", l.id, where, l.name)
            for _, v in ipairs(l.variants or {}) do use("items", v.id, where, v.name) end
        end
    end
    for _, g in ipairs(FGT.goals or {}) do
        local id = g.id
        rule(g.completeWith, id .. " completes")
        use("items", g.rewardItem, id .. " reward")
        tags(g.note, id .. " note")
        for i, t in ipairs(g.tips or {}) do tags(t, id .. " tip " .. i) end
        for i, s in ipairs(g.steps or {}) do
            local where = id .. " step " .. i
            if type(s) == "table" then
                rule(s.auto, where, type(s.text) == "string" and s.text:find("Source unknown", 1, true))
                tags(s.text, where)
                links(s.links, where)
            end
        end
        for si, sec in ipairs(g.sections or {}) do
            for i, t in ipairs(sec.tips or {}) do tags(t, id .. " section " .. si .. " tip " .. i) end
            for pi, p in ipairs(sec.pieces or {}) do
                local where = id .. " piece " .. si .. "_" .. pi
                rule(p.auto, where, type(p.text) == "string" and p.text:find("Source unknown", 1, true))
                tags(p.text, where)
                links(p.links, where)
                for _, req in ipairs(p.requiredItems or {}) do use("items", req.item, where) end
            end
        end
    end
    for _, q in ipairs(FGT.QUESTS or {}) do
        for _, id in ipairs(q[2] or {}) do use("quests", id, "quest " .. q[1], q[1]) end
        if q.startItem then use("items", q.startItem[1], "quest " .. q[1] .. " start", q.startItem[2]) end
    end
    for _, n in ipairs(FGT.NPCS or {}) do
        if n.map then use("maps", n.map, "npc " .. n.name, n.zone) end
        if n.f and n.f[1] then use("maps", n.f[1], "npc " .. n.name .. " (Forever)", n.f[4] or n.zone) end
    end
    return T
end

local function Count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

-- Which of the game's calls this client has, recorded with the answers so a
-- report knows what could and could not be checked.
local function Capabilities()
    return {
        itemInstant = ((C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant) ~= nil,
        itemLoad = (C_Item and C_Item.RequestLoadItemDataByID) ~= nil,
        questTitle = (C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo)) ~= nil,
        questLoad = (C_QuestLog and C_QuestLog.RequestLoadQuestByID) ~= nil,
        factions = GetFactionInfoByID ~= nil,
        maps = (C_Map and C_Map.GetMapInfo) ~= nil,
    }
end

local function QuestTitle(id)
    local f = C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo)
    if not f then return nil end
    local ok, title = pcall(f, id)
    return ok and type(title) == "string" and title ~= "" and title or nil
end

local function Instant(id)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not f then return nil end
    local ok, got = pcall(f, id)
    return ok and got ~= nil
end

function A.Run()
    local DB = ForeverGoalTrackerDB
    if not DB then return end
    if A.running then print(TAG .. "an audit is already running.") return end
    local T = A.Targets()
    local queue = {}
    for id in pairs(T.items) do queue[#queue + 1] = { "items", id } end
    for id in pairs(T.quests) do queue[#queue + 1] = { "quests", id } end
    table.sort(queue, function(a, b) if a[1] ~= b[1] then return a[1] < b[1] end return a[2] < b[2] end)
    local caps = Capabilities()
    A.running = true
    local frame = A.frame or CreateFrame("Frame")
    A.frame = frame
    local seen = {}
    frame:SetScript("OnEvent", function(_, event, id) seen[event .. ":" .. tostring(id)] = true end)
    if frame.RegisterEvent then
        pcall(frame.RegisterEvent, frame, "GET_ITEM_INFO_RECEIVED")
        pcall(frame.RegisterEvent, frame, "QUEST_DATA_LOAD_RESULT")
    end
    print(TAG .. string.format("auditing %d items, %d quests, %d factions and %d maps. This takes about %d seconds.",
        Count(T.items), Count(T.quests), Count(T.factions), Count(T.maps), math.ceil(#queue/PER_STEP*STEP) + SETTLE))
    local at = 1
    local function Finish()
        if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
        local result = { when = time and time() or 0, caps = caps, items = {}, quests = {}, factions = {}, maps = {} }
        local version, build = "", ""
        if GetBuildInfo then version, build = GetBuildInfo() end
        result.version, result.build, result.forever = version, build, FGT.isForever and true or false
        local revealed, hidden, mismatched, qTitled, qMismatch = 0, 0, 0, 0, 0
        for id, s in pairs(T.items) do
            local name = FGT.ItemInfo(id)
            local exists = Instant(id)
            result.items[id] = { n = name or false, e = exists and 1 or 0 }
            if name or exists then revealed = revealed + 1 else hidden = hidden + 1 end
            if name and next(s.names) and not s.names[name] then mismatched = mismatched + 1 end
        end
        for id, s in pairs(T.quests) do
            local title = QuestTitle(id)
            result.quests[id] = title or false
            if title then
                qTitled = qTitled + 1
                if next(s.names) and not s.names[title] then qMismatch = qMismatch + 1 end
            end
        end
        for id in pairs(T.factions) do
            local ok, name = false, nil
            if GetFactionInfoByID then ok, name = pcall(GetFactionInfoByID, id) end
            result.factions[id] = ok and type(name) == "string" and name or false
        end
        for id in pairs(T.maps) do
            local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
            result.maps[id] = info and info.name or false
        end
        DB.audit = result
        A.running = false
        A.last = { revealed = revealed, hidden = hidden, mismatched = mismatched, qTitled = qTitled, qMismatch = qMismatch }
        print(TAG .. string.format("audit done. Items: %d revealed, %d not revealed on this client, %d with a different name than ours.",
            revealed, hidden, mismatched))
        print(TAG .. string.format("Quests: %d titles found (%d differ from ours), of %d. Type |cffffffff/reload|r to save the answers, then run tools/auditreport.py.",
            qTitled, qMismatch, Count(T.quests)))
        if not (caps.itemInstant and caps.itemLoad) then
            print(TAG .. "this client cannot answer every question (see the report for which); results are partial.")
        end
    end
    local function Step()
        for _ = 1, PER_STEP do
            local q = queue[at]
            if not q then break end
            at = at + 1
            if q[1] == "items" then
                if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, q[2]) else FGT.ItemInfo(q[2]) end
            elseif C_QuestLog and C_QuestLog.RequestLoadQuestByID then
                pcall(C_QuestLog.RequestLoadQuestByID, q[2])
            end
        end
        if at <= #queue then C_Timer.After(STEP, Step) else C_Timer.After(SETTLE, Finish) end
    end
    Step()
end

function A.Command(arg)
    local DB = ForeverGoalTrackerDB
    if arg == "clear" then
        if DB then DB.audit = nil end
        print(TAG .. "the saved audit was removed.")
        return
    end
    if arg == "status" then
        local a = DB and DB.audit
        if not a then print(TAG .. "no audit saved yet. Type /goals audit.") return end
        print(TAG .. string.format("the saved audit is from build %s (%s).", tostring(a.build), a.forever and "Forever" or "Classic Era"))
        return
    end
    A.Run()
end
