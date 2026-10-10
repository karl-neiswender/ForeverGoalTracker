local F, D = STUB_NS, ForeverGoalTrackerDB
local g = F.GoalById("fishing_extravaganza")
assert(g and F.LibraryVisible(g) and #g.steps == 3 and not g.forever)
local oldActive, oldCharacters, oldProgress = D.active, D.characters, D.progress
D.active, D.characters, D.progress = { [g.id] = true }, {}, { [g.id] = {} }
local angler = { name="Angler", faction="Horde", skills={ Fishing=149 }, items={ [19807]=39 }, quests={} }
D.characters["Angler-Other"] = angler
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(not D.progress[g.id][1] and not D.progress[g.id][2] and not D.progress[g.id][3])
angler.skills.Fishing, angler.items[19807] = 150, 40
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][1] and D.progress[g.id][2] and not D.progress[g.id][3], "preparation and fish do not win tournament")
angler.items[19807] = nil
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][2], "catch remains ticked after fish are consumed")
angler.quests[8193] = true
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][3], "winning turn-in completes tournament")
for _, reward in ipairs({19970,19979}) do
    D.progress[g.id], angler.quests, angler.items, angler.skills = {}, {}, { [reward]=1 }, {}
    STUB_FIRE("BAG_UPDATE_DELAYED")
    for i = 1, 3 do assert(D.progress[g.id][i], "either historical prize completes all earlier steps") end
end
F.SelectGoal(g.id)
assert(F.LinkText("'Master Angler'"):find("fgtquest:", 1, true), "winner quest is linked")
assert(F.LinkText("Riggle Bassbait"):find("fgtnpc:", 1, true), "turn-in NPC is linked")
D.active, D.characters, D.progress = oldActive, oldCharacters, oldProgress
print("  fishing: skill threshold, 40 fish, sticky catch, winning quest, either prize and goal links ok")
