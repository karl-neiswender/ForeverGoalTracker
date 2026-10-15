local F, D = STUB_NS, ForeverGoalTrackerDB
local g = F.GoalById("zinrokh")
assert(g and F.LibraryVisible(g) and g.category == "Epic Weapon" and not g.forever)
assert(g.completeWith.item == 19854 and #g.steps == 2 and not g.faction)
for _, class in ipairs({"WARRIOR", "PALADIN", "HUNTER"}) do
    assert(F.GoalFits(g, {class=class}), "two-handed sword users see Zin'rokh")
end
for _, class in ipairs({"ROGUE", "MAGE", "WARLOCK", "PRIEST", "SHAMAN", "DRUID"}) do
    assert(not F.GoalFits(g, {class=class}), "unsupported classes are filtered out")
end
local active, characters, progress = D.active, D.characters, D.progress
local level = UnitLevel
UnitLevel = function() return 1 end
D.active, D.characters, D.progress = {[g.id]=true}, {}, {[g.id]={}}
local alt = {name="Collector", faction="Horde", level=59, items={}, quests={}}
D.characters["Collector-Other"] = alt
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(not D.progress[g.id][1] and not D.progress[g.id][2], "no unearned progress")
alt.level = 60
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][1] and not D.progress[g.id][2], "level alone does not earn weapon")
D.progress[g.id], alt.level, alt.items = {}, 59, {[19854]=1}
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][1] and D.progress[g.id][2], "historical ownership on an alt completes the goal")
alt.items = {}
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(D.progress[g.id][2], "ownership credit stays after sword leaves snapshot")
assert(F.LinkText(g.tips[1]):find("fgtgoal:raid_zg", 1, true), "raid tip resolves existing goal")
D.active, D.characters, D.progress = active, characters, progress
UnitLevel = level
print("  Zin'rokh: class filters, level threshold, alt ownership, sticky credit and raid link ok")
