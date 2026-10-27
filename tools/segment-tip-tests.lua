-- Progress bar segment tooltips (Karl, 2026-10-27): a short step name, a progress line with the
-- count and the segment's own percent (or Done / Not done for a yes-or-no step), then the goal's
-- share. No links or colour codes in the title, and no quantity in it when the count is shown.
local F, D = STUB_NS, ForeverGoalTrackerDB
D.characters = {}

-- the title
local T = F.StepTitle
assert(T("Reach Exalted with Stormwind.", false, true) == "Reach Exalted with Stormwind", "trailing full stop dropped")
assert(T({ text = "Collect 20 Sulfuron Ingots." }, true) == "Collect Sulfuron Ingots", "a leading quantity goes when the count is shown")
assert(T({ text = "Collect 20 Sulfuron Ingots." }, false) == "Collect 20 Sulfuron Ingots", "and stays when it is not")
assert(T({ text = "Reach level 60." }, false) == "Reach level 60", "a number that is part of the step stays")
assert(T({ text = "Gather 1,200x Runecloth." }, true) == "Gather Runecloth", "commas and an x are quantity too")
assert(T({ text = "Loot |cffa335ee|Hitem:19019|h[Thunderfury]|h|r from Garr.", short = "Get Thunderfury" }) == "Get Thunderfury", "short overrides the text")
local linked = T({ text = "Loot |cffa335ee|Hitem:19019|h[Thunderfury]|h|r from Garr." })
assert(linked == "Loot Thunderfury", "item links become plain names: " .. linked)
assert(not linked:find("|", 1, true) and not linked:find("[", 1, true), "no escape codes or brackets left")
for _, text in ipairs({ "Complete {att_mc:Attunement to the Core} in Blackrock Depths.",
    "Earn the Drakefire Amulet from the {att_ony:Onyxia attunement}.", "Get {att_naxx:attuned to Naxxramas} at Light's Hope Chapel." }) do
    assert(T({ text = text }) == "Complete Attunement", "an attunement step is titled Complete Attunement: " .. text)
end
assert(T({ text = "Complete {att_mc:Attunement to the Core}.", short = "Get the Core" }) == "Get the Core", "short still wins")
assert(T({ text = "Defeat Onyxia in Onyxia's Lair." }) == "Defeat Onyxia", "a kill drops its place")
assert(T({ text = "Defeat Lord Kazzak in the Tainted Scar in the Blasted Lands." }) == "Defeat Lord Kazzak", "all of the place goes")
assert(T({ text = "Loot the Head of Onyxia and turn it in at Stormwind Keep." }) == "Loot the Head of Onyxia", "a loot step drops the turn-in")
assert(T({ text = "Loot Plans: Frostguard from Foreman Marcrid in Western Plaguelands." }) == "Loot Plans: Frostguard", "and who it drops from")
local pick = T({ text = "Pick up 'Seal of Ascension' inside Blackrock Spire." })
assert(pick == "Pick up Seal of Ascension", "a pick-up step drops its place: " .. pick)
assert(T({ text = "Defeat Thaddius and Feugen." }) == "Defeat Thaddius and Feugen", "two bosses stay together")
assert(T({ text = "Speak with the elder in the city." }) == "Speak with the elder in the city", "only action and Reach steps are trimmed")
assert(T({ text = "Defeat Onyxia in Onyxia's Lair.", short = "Kill Onyxia now" }) == "Kill Onyxia now", "short still wins")
assert(T({ text = "Reach Exalted with the Stormpike Guard." }) == "Reach Exalted", "with-faction is dropped from a Reach step")
assert(T({ text = "Reach Exalted with the Stormpike Guard." }, false, true) == "Reach Exalted with the Stormpike Guard", "unless asked to keep it")
local long = T({ text = "Earn the Drakefire Amulet from the Onyxia attunement chain in Burning Steppes." })
assert(#long <= 43 and long:sub(-3) == "..." and not long:find("%s%.%.%.$"), "a long title is cut at a word: " .. long)

-- the tooltip
local lines
F.Bars.TipIn = function() end -- (placement is Bars.lua's, not under test here)
GameTooltip = { SetOwner = function() lines = {} end, Show = function() end, Hide = function() end,
    NumLines = function() return #lines end, AddLine = function(_, text) lines[#lines + 1] = text end }
local goal = { id = "zz_segment_tip", name = "Test", steps = {
    { text = "Reach level 60.", auto = { level = 60 } },
    { text = "Defeat Onyxia in Onyxia's Lair.", auto = { boss = "Onyxia" } },
    { text = "Gather 18 Arcanite Bars.", auto = { item = 12360, count = 18 } },
    { text = "Reach Exalted with Stormwind.", auto = { rep = { faction = 72, standing = 8 } } },
} }
D.active[goal.id], D.progress[goal.id] = true, {}

F.ShowSegmentTip(UIParent, goal, 1)
assert(lines[1] == "Reach level 60", "level step title: " .. tostring(lines[1]))
assert(lines[2]:match("^Level 0 / 60") and lines[2]:match("0%%$"), "level progress line: " .. tostring(lines[2]))
assert(lines[3]:match("^Goal %d+%%$") and #lines == 3, "the goal's share closes the tooltip")

F.ShowSegmentTip(UIParent, goal, 2)
assert(lines[1] == "Defeat Onyxia" and lines[2] == "Not done" and #lines == 3,
    "a yes-or-no step shows Not done, never 0 / 0: " .. table.concat(lines, " | "))

F.ShowSegmentTip(UIParent, goal, 3)
assert(lines[1] == "Gather Arcanite Bars", "the quantity moves to the progress line: " .. tostring(lines[1]))
assert(lines[2] == "0 / 18  \194\183  0%", "count and percent share one line: " .. tostring(lines[2]))

F.ShowSegmentTip(UIParent, goal, 4)
assert(lines[1] == "Reach Exalted" and lines[#lines]:match("^Goal"), "reputation title and goal line: " .. tostring(lines[1]))

D.progress[goal.id] = { [2] = true }
F.ShowSegmentTip(UIParent, goal, 2)
assert(lines[2] == "Done" and #lines == 3, "a finished step says Done, with no percent")
GameTooltip = nil
print("  segment tooltips ok")

-- steps that would share a title keep their faction, so segments stay tellable apart
GameTooltip = { SetOwner = function() lines = {} end, Show = function() end, Hide = function() end,
    NumLines = function() return #lines end, AddLine = function(_, text) lines[#lines + 1] = text end }
local twins = { id = "zz_twins", name = "Twins", steps = {
    { text = "Reach Exalted with Stormwind.", auto = { rep = { faction = 72, standing = 8 } } },
    { text = "Reach Exalted with Ironforge.", auto = { rep = { faction = 47, standing = 8 } } },
} }
D.active[twins.id], D.progress[twins.id] = true, {}
F.ShowSegmentTip(UIParent, twins, 1)
assert(lines[1] == "Reach Exalted with Stormwind", "twin steps keep the faction: " .. tostring(lines[1]))
GameTooltip = nil
