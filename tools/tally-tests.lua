-- The 1 Ring goal and the fishing tally (Karl, 2026-10-24): a count that starts when the goal is added to My
-- Goals, rises with every catch while it is there, and is cleared when the goal goes.
local F, D = STUB_NS, ForeverGoalTrackerDB
local g = F.GoalById("collect_the_1_ring")
assert(g and F.LibraryVisible(g), "The 1 Ring is in the Library")
assert(g.category == "Collectible" and g.difficulty == "Extreme" and g.timeEstimate == "Ongoing", "its labels are Collectible, Extreme and Ongoing")
assert(F.categoryColors["Collectible"], "the Collectible category has a colour")
assert(g.completeWith.item == 8350 and #g.steps == 2 and g.steps[2].tally, "owning item 8350 completes it; the catch step shows the tally")
assert(g.tally and g.tally.event == "fishing" and g.tally.label == "fish caught so far", "it counts fishing catches")

D.active, D.characters, D.progress, D.tallies = {}, {}, {}, nil
local clock = 100
GetTime = function() return clock end
local fishing = true
IsFishingLoot = function() return fishing end

-- not on My Goals: nothing is counted and nothing is kept
STUB_FIRE("LOOT_OPENED")
assert(F.TallyCount(g) == 0 and not (D.tallies and D.tallies[g.id]), "a goal that is not added counts nothing")

-- adding it starts at zero; each catch adds one
F.SetGoalActive(g, true)
assert(D.active[g.id] and F.TallyCount(g) == 0, "adding the goal starts the count at zero")
clock = clock + 1; STUB_FIRE("LOOT_OPENED")
assert(F.TallyCount(g) == 1, "a catch counts")
STUB_FIRE("LOOT_OPENED")
assert(F.TallyCount(g) == 1, "the same loot window is never counted twice")
clock = clock + 5; STUB_FIRE("LOOT_OPENED")
assert(F.TallyCount(g) == 2, "the next catch counts")
fishing = false; clock = clock + 5; STUB_FIRE("LOOT_OPENED")
assert(F.TallyCount(g) == 2, "loot that is not from fishing is not counted")
fishing = true

-- the line under the step: a short count with thousands separators
assert(F.TallyLine(g) == "2 fish caught so far", "the line reads like '2 fish caught so far'")
D.tallies[g.id] = 1284
assert(F.TallyLine(g) == "1,284 fish caught so far", "big counts get commas")
F.SelectGoal(g.id)
local text = F.stepRows[2].text:GetText() or ""
assert(text:find("1,284 fish caught so far", 1, true), "the catch step shows the count under it")
assert(not (F.stepRows[1].text:GetText() or ""):find("fish caught", 1, true), "only the catch step shows it")

-- removing the goal clears it; adding it again starts afresh
F.SetGoalActive(g, false)
assert(F.TallyCount(g) == 0 and D.tallies[g.id] == nil, "removing the goal clears the count")
clock = clock + 5; STUB_FIRE("LOOT_OPENED")
assert(F.TallyCount(g) == 0, "a removed goal does not count")
F.SetGoalActive(g, true)
assert(F.TallyCount(g) == 0, "adding it again starts afresh")
clock = clock + 5; STUB_FIRE("LOOT_OPENED")
assert(F.TallyCount(g) == 1, "and counts again")
-- clearing My Goals some other way never leaves an old count behind
D.active = {}
assert(F.TallyCount(g) == 0, "a goal no longer on My Goals reports no count")
F.SetGoalActive(g, true)
assert(F.TallyCount(g) == 0, "and adding it again resets it")

-- a goal without a tally is untouched
local plain = F.GoalById("fishing_extravaganza")
assert(not plain.tally and F.TallyLine(plain) == nil and F.TallyCount(plain) == 0, "goals without a tally have none")
F.SetGoalActive(g, false)
GetTime, IsFishingLoot = nil, nil
print("  The 1 Ring goal and its fishing tally: labels, start at zero, catches, no double count, line, clear on removal ok")
