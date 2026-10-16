local F, D = STUB_NS, ForeverGoalTrackerDB
local g = F.GoalById("teebus")
assert(g and F.LibraryVisible(g) and g.category == "Epic Weapon" and g.forever == "confirmed")
assert(g.completeWith.item == 1728 and #g.steps == 2 and not g.faction)
for _, class in ipairs({"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "MAGE", "WARLOCK"}) do
    assert(F.GoalFits(g, {class=class}), "one-handed sword users see Teebu's")
end
for _, class in ipairs({"PRIEST", "SHAMAN", "DRUID"}) do
    assert(not F.GoalFits(g, {class=class}), "unsupported classes are filtered out")
end
local active, characters, progress = D.active, D.characters, D.progress
local level = UnitLevel
UnitLevel = function() return 1 end
D.active, D.characters, D.progress = {[g.id]=true}, {}, {[g.id]={}}
local alt = {name="Collector", faction="Alliance", level=59, items={}, quests={}}
D.characters["Collector-Other"] = alt
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(not D.progress[g.id][1] and not D.progress[g.id][2], "no unearned progress")
alt.items = {[1728]=1}
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][1] and D.progress[g.id][2], "historical ownership on an alt completes the goal")
alt.items = {}
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][2], "ownership credit stays after the sword leaves the snapshot")
D.active, D.characters, D.progress = active, characters, progress
UnitLevel = level
print("  Teebu's: class filters, level threshold, alt ownership and sticky credit ok")
