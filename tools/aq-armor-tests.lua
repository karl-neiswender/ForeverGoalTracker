local F, D = STUB_NS, ForeverGoalTrackerDB
local parent = F.GoalById("set_tier25")
assert(parent and parent.libraryOnly and F.LibraryVisible(parent))
assert(#parent.sections == 9 and #parent.armorChildren == 9)
local allItems = {}
for _, child in ipairs(parent.armorChildren) do
    assert(F.goalBanner:ArtPath(child.id) == "set_tier25-banner.blp", "all nine sets share approved AQ40 art")
    assert(F.goalBanner.artAspects[child.id] == 4/3 and F.goalBanner.preprocessed[child.id], "approved framing and grayscale treatment")
    assert(child.armorParent == parent.id and #child.sections == 1)
    assert(not child.forever and not child.faction, "Classic set retains unverified Forever notice and both factions")
    assert(#child.tips == 3 and #child.sections[1].pieces == 5, "general tips only; reagents live under each piece")
    assert(child.tips[3]:find("Neutral", 1, true) and child.tips[3]:find("Friendly", 1, true) and child.tips[3]:find("Honored", 1, true))
    for _, piece in ipairs(child.sections[1].pieces) do
        assert(not allItems[piece.auto.item], "45 distinct reward pieces")
        allItems[piece.auto.item] = true
        assert(#piece.materials == 4 and not piece.requiredItems, "token, two idols and two scarabs, like Tier 3")
        assert(piece.materials[1]:find(" from ", 1, true) and piece.materials[2]:match("^2 Idol") and piece.materials[3]:match("^5 ") and piece.materials[4]:match("^5 "))
    end
end
local mage = F.GoalById("set_tier25_mage")
assert(mage.sections[1].pieces[2].materials[1] == "Vek'nilash's Circlet from Emperor Vek'nilash", "circlet source uses correct twin")
assert(mage.sections[1].pieces[1].materials[2] == "2 Idol of the Sun", "idols are listed under the piece")
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
assert(done == 20 and total == 20, "set completes after five rewards, every material line included")
F.SelectGoal(rogue.id)
assert(F.goalBanner.title:GetText():find("Deathdealer", 1, true), "new goal page renders")
-- pieces ticked as owned before the material checklists keep them complete
local oldProgress, oldFix = D.progress[rogue.id], D.aqMaterialsFix
D.progress[rogue.id], D.aqMaterialsFix = { ["1_2_piece"] = true }, nil
F.MigrateAQMaterials(D)
for mi = 1, 4 do assert(D.progress[rogue.id]["1_2_m" .. mi], "owned piece keeps its materials ticked") end
assert(not D.progress[rogue.id]["1_3_m1"], "other pieces stay as they were")
D.progress[rogue.id], D.aqMaterialsFix = oldProgress, oldFix
D.active[rogue.id] = nil
D.characters["AQTest-Other"] = nil
print("  AQ40: nine class sets, 45 rewards, class guidance, roster auto ticks and sticky completion ok")
