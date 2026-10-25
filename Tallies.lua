local ADDON, FGT = ...

-- Tallies (Karl, 2026-10-24): a count the addon keeps for one goal, starting at zero when the goal is added to
-- My Goals and ending when it is removed. Nothing else about the goal depends on it: it is a statistic to show
-- under a step, such as the fish caught while chasing The 1 Ring.
--
-- A goal names the event it counts: goal.tally = { event = "fishing", label = "fish caught so far" }, and the
-- step that shows the line carries tally = true. The count is one number for the whole account: it adds up what
-- every recorded character catches while the goal is on My Goals. Adding the goal starts it at zero; removing
-- the goal (or clearing My Goals) clears it, and adding the goal again starts afresh.
--
-- Events: "fishing" counts every catch, whatever the game hands over (junk too): the game's own fishing check
-- on the loot window. FGT.TallyEvent(name) is the one entry point a new kind of count needs.
local function Store()
    local DB = ForeverGoalTrackerDB
    if not DB then return nil end
    DB.tallies = DB.tallies or {}
    return DB.tallies
end

local function Active(goal)
    local DB = ForeverGoalTrackerDB
    return DB and DB.active and DB.active[goal.id] and true or false
end

function FGT.TallyStart(goal)
    if not (goal and goal.tally) then return end
    local tallies = Store()
    if tallies then tallies[goal.id] = 0 end
end

function FGT.TallyStop(goal)
    if not (goal and goal.tally) then return end
    local tallies = Store()
    if tallies then tallies[goal.id] = nil end
end

-- The count, or 0 for a goal that is not on My Goals (it never keeps one).
function FGT.TallyCount(goal)
    if not (goal and goal.tally and Active(goal)) then return 0 end
    local DB = ForeverGoalTrackerDB
    return (DB.tallies and DB.tallies[goal.id]) or 0
end

local function Commas(n)
    local s = tostring(math.floor(n))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (out:gsub("^,", ""))
end

-- "1,284 fish caught so far"
function FGT.TallyLine(goal)
    if not (goal and goal.tally) then return nil end
    return Commas(FGT.TallyCount(goal)) .. " " .. (goal.tally.label or "so far")
end

-- One thing that happened: every goal on My Goals that counts it goes up by one.
function FGT.TallyEvent(name)
    local tallies = Store()
    if not tallies then return end
    for _, goal in ipairs(FGT.goals or {}) do
        if goal.tally and goal.tally.event == name and Active(goal) then
            tallies[goal.id] = (tallies[goal.id] or 0) + 1
        end
    end
    if FGT.RefreshTallies then FGT.RefreshTallies() end
end

-- Fishing: the loot window of a catch. The game fires LOOT_OPENED once per window, and IsFishingLoot says
-- whether it is a fishing one. A catch is never counted twice inside a fifth of a second.
local lastCatch = 0
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("LOOT_OPENED")
watcher:SetScript("OnEvent", function()
    if not (IsFishingLoot and IsFishingLoot()) then return end
    local now = GetTime and GetTime() or 0
    if now - lastCatch < 0.2 and lastCatch ~= 0 then return end
    lastCatch = now
    FGT.TallyEvent("fishing")
end)
FGT.tallyWatcher = watcher
