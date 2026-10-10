local F, D = STUB_NS, ForeverGoalTrackerDB
local parent = F.GoalById("set_tier25")
assert(parent and parent.libraryOnly and F.LibraryVisible(parent))
assert(#parent.sections == 9 and #parent.armorChildren == 9)
local allItems = {}
for _, child in ipairs(parent.armorChildren) do
    assert(child.armorParent == parent.id and #child.sections == 1)
    assert(not child.forever and not child.faction, "Classic set retains unverified Forever notice and both factions")
    assert(#child.tips == 7 and #child.sections[1].pieces == 5)
    assert(child.tips[3]:find("Neutral", 1, true) and child.tips[4]:find("Friendly", 1, true))
    assert(child.tips[7]:find("Honored", 1, true))
    for _, piece in ipairs(child.sections[1].pieces) do
        assert(not allItems[piece.auto.item], "45 distinct reward pieces")
        allItems[piece.auto.item] = true
        assert(#piece.materials == 0, "collecting materials alone cannot finish armor")
    end
end
local mage = F.GoalById("set_tier25_mage")
assert(mage.tips[4]:find("Emperor Vek'nilash", 1, true), "circlet source uses correct twin")
assert(mage.tips[3]:find("{item:20874:Idol of the Sun}", 1, true), "materials have item links")
local rogue = F.GoalById("set_tier25_rogue")
D.active[rogue.id] = true
D.progress[rogue.id] = {}
D.characters["AQTest-Other"] = { name="AQTest", faction="Horde", items={} }
local inventory = D.characters["AQTest-Other"].items
inventory[20928] = 2
STUB_FIRE("BAG_UPDATE_DELAYED")
assert(not D.progress[rogue.id]["1_1_piece"], "tokens do not count as completed armor")
for pi, piece in ipairs(rogue.sections[1].pieces) do
    inventory[piece.auto.item] = 1
    STUB_FIRE("BAG_UPDATE_DELAYED")
    assert(D.progress[rogue.id]["1_" .. pi .. "_piece"], "reward ownership ticks across characters")
    inventory[piece.auto.item] = nil
    STUB_FIRE("BAG_UPDATE_DELAYED")
    assert(D.progress[rogue.id]["1_" .. pi .. "_piece"], "ticks survive consumed or sold items")
end
local done, total = 0, 0
for pi, piece in ipairs(rogue.sections[1].pieces) do
    local d, t = F.PieceProgress(rogue.id, 1, pi, piece)
    done, total = done + d, total + t
end
assert(done == 5 and total == 5, "set completes after five rewards")
F.SelectGoal(rogue.id)
assert(F.goalBanner.title:GetText():find("Deathdealer", 1, true), "new goal page renders")
D.active[rogue.id] = nil
D.characters["AQTest-Other"] = nil
print("  AQ40: nine class sets, 45 rewards, class guidance, roster auto ticks and sticky completion ok")
