-- Goals you aren't tracking speak up in chat when they finish, or when an item you hold counts
-- toward one, with a link that opens the goal in the Library (FGT.LibraryNotices; Karl, 2026-11-17).
local F, D = STUB_NS, ForeverGoalTrackerDB
local active, parts, characters, progress, firstRun = D.active, D.activeParts, D.characters, D.progress, F.firstRun
local level = UnitLevel
UnitLevel = function() return 1 end
F.firstRun = nil
D.active, D.activeParts, D.progress = {}, {}, {}
local alt = { name = "Collector", faction = "Alliance", level = 30, items = {}, quests = {}, reps = {}, skills = {} }
D.characters = { ["Collector-Other"] = alt }

local function said(text)
    local n = 0
    for _, line in pairs(STUB_PRINTS) do
        if type(line) == "string" and line:find(text, 1, true) then n = n + 1 end
    end
    return n
end

-- an untracked goal finishing: one line, with a Library link
STUB_PRINTS = {}
alt.items = { [1728] = 1 } -- Teebu's Blazing Longsword
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(said("addon:ForeverGoalTracker:library:teebus|h[Teebu's Blazing Longsword]|h") == 1, "completion line with a Library link")
assert(said("a Library goal you're not tracking") >= 1)
assert(said("checked off automatically") == 0, "goals you don't track stay out of the step count")
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(said("library:teebus|") == 1, "said once")

-- an item one step of an untracked goal needs
STUB_PRINTS = {}
alt.items[17204] = 1 -- Eye of Sulfuras
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(said("counts toward |cffffd100|Haddon:ForeverGoalTracker:library:sulfuras|h") == 1, "item step line")

-- a tracked goal: the usual step count, no Library line
STUB_PRINTS = {}
D.active.mount_dreadsteed, D.active.thunderfury = nil, true
alt.items[19019] = 1 -- Thunderfury itself completes its goal
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(said("library:thunderfury") == 0, "a tracked goal gets no Library line")
assert(said("checked off automatically") == 1, "tracked steps are still counted")

-- the setting turns the lines off
STUB_PRINTS = {}
F.SetSetting("libraryChat", false)
alt.items[18608] = 1 -- Benediction
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(said("library:benediction") == 0, "Library goals in chat: off")
F.SetSetting("libraryChat", true)

-- the link opens that goal's preview in the Library (a window wide enough for the drawer)
local U = F.MaterialsUI
U.main.GetWidth = function() return 1240 end
U.list.GetWidth = function() return 270 end
F.OpenLibraryGoal("teebus")
assert(F.LibraryPreview:IsSelected(F.GoalById("teebus")), "link opens the goal's preview")

D.active, D.activeParts, D.characters, D.progress, F.firstRun = active, parts, characters, progress, firstRun
UnitLevel = level
print("  untracked goals: finish and item lines, once each, tracked count, setting and Library link ok")
