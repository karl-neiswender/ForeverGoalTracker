local F, D = STUB_NS, ForeverGoalTrackerDB
local active, chars, progress = D.active, D.characters, D.progress
D.active, D.characters, D.progress = {}, {}, {}
local holder = { name="TankTest", faction="Horde", items={}, owned={} }
D.characters["TankTest-Other"] = holder
local mounts = { blue=21218, green=21323, yellow=21324, red=21321 }
for color, item in pairs(mounts) do
    local g = F.GoalById("mount_qiraji_" .. color)
    assert(g and F.LibraryVisible(g) and #g.steps == 1 and not g.faction and not g.forever)
    assert(g.steps[1].auto.item == item)
    assert(F.goalBanner:ArtPath(g.id) == "mount_qiraji_aq-banner.blp")
    assert(F.goalBanner.preprocessed[g.id] and F.goalBanner.artAspects[g.id] == 4/3)
    D.active[g.id], D.progress[g.id] = true, {}
end
holder.items[21176], holder.owned["Black Qiraji Battle Tank"] = 1, true
STUB_FIRE("BAG_UPDATE_DELAYED")
for color in pairs(mounts) do
    assert(not D.progress["mount_qiraji_" .. color][1], "black mount does not complete colored goals")
end
for color, item in pairs(mounts) do
    local id = "mount_qiraji_" .. color
    holder.items[item] = 1
    STUB_FIRE("BAG_UPDATE_DELAYED")
    assert(D.progress[id][1], "crystal ownership ticks from another character")
    holder.items[item] = nil
    STUB_FIRE("BAG_UPDATE_DELAYED")
    assert(D.progress[id][1], "consumed crystals remain ticked")
    D.progress[id] = {}
    holder.owned[color:sub(1,1):upper() .. color:sub(2) .. " Qiraji Battle Tank"] = true
    STUB_FIRE("BAG_UPDATE_DELAYED")
    assert(D.progress[id][1], "learned mount also completes its color")
end
D.active, D.characters, D.progress = active, chars, progress
print("  Qiraji: four independent colors, correct crystals, learned mounts, sticky progress and shared banner ok")
