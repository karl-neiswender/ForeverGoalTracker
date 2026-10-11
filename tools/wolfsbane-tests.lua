local F, D = STUB_NS, ForeverGoalTrackerDB
local g = assert(F.GoalById("wolfsbane"))
assert(g.faction == "Horde" and g.forever == "new" and g.rewardItem == nil)
assert(F.LibraryVisible(g) == F.isForever, "Wolfsbane is only visible in Forever")
local active, chars, progress = D.active, D.characters, D.progress
D.active, D.characters, D.progress = { wolfsbane = true }, {}, { wolfsbane = {} }
local paladin = { name="Forsaken", race="Scourge", class="PALADIN", faction="Horde", items={}, quests={}, questsTaken={} }
D.characters["Forsaken-Other"] = paladin
D.characters["Warrior-Other"] = { race="Scourge", class="WARRIOR", faction="Horde", skills={ ["Two-Handed Swords"]=300 } }
STUB_FIRE("SKILL_LINES_CHANGED")
assert(not D.progress.wolfsbane[2], "a warrior's training does not complete the paladin prerequisite")
paladin.skills = { ["Two-Handed Swords"]=1 }
STUB_FIRE("SKILL_LINES_CHANGED")
assert(D.progress.wolfsbane[2], "known sword training completes the prerequisite")
paladin.questsTaken[95036] = true
paladin.items[6994], paladin.items[267361] = 1, 1
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress.wolfsbane[10] and D.progress.wolfsbane[11] and D.progress.wolfsbane[12])
assert(not D.progress.wolfsbane[14], "accepting the materials quest does not complete it")
paladin.items = {}
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress.wolfsbane[11] and D.progress.wolfsbane[12], "consumed materials retain progress")
for _, evidence in ipairs({"quest", "item"}) do
    D.progress.wolfsbane, paladin.quests, paladin.items = {}, {}, {}
    if evidence == "quest" then paladin.quests[95140] = true else paladin.items[267369] = 1 end
    STUB_FIRE("BAG_UPDATE_DELAYED")
    for i=1,#g.steps do assert(D.progress.wolfsbane[i], "final quest or sword completes the chain") end
end
for _, step in ipairs(g.steps) do
    assert(F.LinkText(step.text):find("fgtquest:", 1, true) or step.auto.item or step.auto.level or step.auto.skill, "quest steps have registered links")
end
D.active, D.characters, D.progress = active, chars, progress
print("  Wolfsbane: client visibility, quest pickup, sticky materials, reward completion and quest links ok")
