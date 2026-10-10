local F, D = STUB_NS, ForeverGoalTrackerDB
local rogue, hunter = F.GoalById("set_tier1_rogue"), F.GoalById("set_tier1_hunter")
assert(rogue and hunter and not rogue.group and not hunter.group)
assert(D.active[rogue.id] and D.active[hunter.id], "both selected sets migrate independently")
assert(D.selected == hunter.id, "old selected collection opens its first selected class")
assert(D.progress[rogue.id]["1_1_piece"] and D.progress[hunter.id]["1_2_piece"], "piece keys remap to the individual section")
assert(not D.progress[hunter.id]["1_1_piece"], "another class's progress does not leak")
assert(D.progress.tier3_rogue["1_1_m1"], "Tier 3 material keys survive")
assert(D.notes[rogue.id] == "Keep this note" and D.favorites[hunter.id], "notes and favorites survive")
assert(D.goalDates[rogue.id] == 123456, "known completion date survives")
assert(D.armorSetsBackup1.progress.set_tier1, "old positional data retained as backup")
for _, goal in ipairs(F.ActiveGoals()) do assert(not goal.libraryOnly, "collections never appear in tracker or overall totals") end
for _, parent in pairs(F.armorCollections) do
    assert(parent.libraryOnly and not F.LibraryVisible(parent.armorChildren[1]))
    for si, child in ipairs(parent.armorChildren) do
        assert(not child.group and #child.sections == 1 and child.armorSection == si)
        assert(child.sections[1] == parent.sections[si], "all item IDs, variants and recipes retained")
    end
end
F.SelectGoal(rogue.id)
assert(F.goalBanner.goal.id == rogue.id and F.goalBanner.sourceAspect == 4/3)
assert(F.goalBanner.artPaths[rogue.id] ~= F.goalBanner.artPaths[hunter.id], "dedicated class banners")
local oldAfter = C_Timer.After
C_Timer.After = function() end
local reset = F.resetBtn:GetScript("OnClick")
reset()
assert(not D.progress[rogue.id]["1_1_piece"] and D.progress[hunter.id]["1_2_piece"], "reset touches only this set")
F.MigrateArmorSets(D)
assert(not D.progress[rogue.id]["1_1_piece"], "migration cannot resurrect reset progress")
reset()
assert(D.progress[rogue.id]["1_1_piece"], "undo restores only this set")
C_Timer.After = oldAfter
F.SetLibraryView("all", "set_tier1")
F.LayoutLibrary()
local card = F.libCards.set_tier1
local sub = card.subs[rogue.armorSection]
sub.btn:GetScript("OnClick")(sub.btn)
assert(not D.active[rogue.id] and D.active[hunter.id], "Library Remove affects one set")
assert(D.progress[rogue.id]["1_1_piece"], "removal keeps that set's progress")
sub.btn:GetScript("OnClick")(sub.btn)
assert(D.active[rogue.id] and D.active[hunter.id], "Library Add creates independent goal")
assert(F.PartSelected(F.GoalById("set_tier1"), rogue.armorSection), "collection picker follows child selection")
local d, t = F.PieceProgress("set_tier1", rogue.armorSection, 1, rogue.sections[1].pieces[1])
assert(d == 1 and t == 1, "Library progress reads individual goal")
if not F.isForever then
    assert(not F.LibraryVisible(F.GoalById("set_forever_raid")))
    assert(not F.LibraryVisible(F.GoalById("pvp_set_plate_ally")), "Forever PvP collections hidden in Era")
end
print("  individual armor goals, migration, materials, notes, dates, reset/undo, Library picker and dedicated banners ok")

local might = F.GoalById("set_tier1_warrior")
assert(might.short == "Might" and might.name == "Battlegear of Might", "compact list and full title")
D.active[might.id] = true
F.SelectGoal(might.id)
assert(F.goalBanner.tag:GetText():find("WARRIOR", 1, true), "class moves beside category")
assert(not F.goalBanner.title:GetText():find("(Warrior)", 1, true), "title omits class suffix")
for _, id in ipairs({"set_tier1_mage", "set_tier2_mage"}) do
    assert(F.goalBanner.preprocessed[id] and F.goalBanner.artAspects[id] == 4/3, "approved mage artwork")
    assert(F.goalBanner.artPaths[id] == id .. "-banner.blp", "dedicated mage banner mapping")
end

local oldColors = RAID_CLASS_COLORS
RAID_CLASS_COLORS = { WARRIOR = { r = 199/255, g = 156/255, b = 110/255 } }
F.SelectGoal(might.id)
assert(F.goalBanner.tag:GetText():find("|cffc79c6eWARRIOR|r", 1, true), "class label uses the client's class color")
assert(F.goalBanner.tag:GetText():find("ITEM SET  |cff77736a", 1, true), "category and muted dot retain their treatment")
RAID_CLASS_COLORS = nil
assert(F.ArmorClassLabel("Mage") == "|cff69ccf0MAGE|r", "standard class color fallback")
assert(F.ArmorClassLabel("Priest") == "|cffffffffPRIEST|r", "white Priest label")
RAID_CLASS_COLORS = oldColors

local dedicatedTier3 = {
    tier3_rogue=true, tier3_warrior=true, tier3_mage=true, tier3_druid=true,
    tier3_shaman=true, tier3_warlock=true, tier3_paladin=true, tier3_priest=true,
}
for _, child in ipairs(F.GoalById("tier3").armorChildren) do
    if not dedicatedTier3[child.id] then
        assert(F.goalBanner:ArtPath(child.id) == "tier3-banner.blp", "Tier 3 without dedicated art inherits Naxx artwork")
        assert(F.goalBanner.preprocessed[child.id] and F.goalBanner.artAspects[child.id] == 4/3)
    else
        local faction = UnitFactionGroup and UnitFactionGroup("player")
        local variants = F.goalBanner.factionArtPaths[child.id]
        local expected = (variants and variants[faction]) or child.id .. "-banner.blp"
        assert(F.goalBanner:ArtPath(child.id) == expected, "Tier 3 uses its dedicated class and faction artwork")
        assert(F.goalBanner.preprocessed[child.id] and F.goalBanner.artAspects[child.id] == 4/3)
    end
end

local violet = F.GoalById("set_violet_sorcerer")
assert(violet and #violet.steps == 5 and not violet.faction)
assert(F.LibraryVisible(violet) == F.isForever, "Violet set is available only on Forever")
if F.isForever then
    local frame = {}
    assert(F.ApplyForeverLook(frame, violet) == "NEW" and frame.foreverNew, "new set uses blue treatment")
    D.active[violet.id] = true
    D.characters["VioletTest-Other"] = {name="VioletTest", faction="Horde", items={}}
    local items = D.characters["VioletTest-Other"].items
    for i, step in ipairs(violet.steps) do
        assert(not F.StepRuleMet(step.auto), "unowned pieces stay incomplete")
        items[step.auto.item] = 1
        STUB_FIRE("BAG_UPDATE_DELAYED")
        assert(D.progress[violet.id][i], "each piece ticks from another character's inventory")
        items[step.auto.item] = nil
        STUB_FIRE("BAG_UPDATE_DELAYED")
        assert(D.progress[violet.id][i], "selling a piece cannot undo its tick")
    end
    print("  Violet set: Forever visibility, blue treatment, five roster item ticks and sticky progress ok")
end
