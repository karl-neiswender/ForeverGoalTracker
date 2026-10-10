local F, D = STUB_NS, ForeverGoalTrackerDB
local saved = { goals = F.goals, active = D.active, parts = D.activeParts,
    progress = D.progress, characters = D.characters, info = F.ItemInfo }
local goal = { id = "tooltip_test", name = "Test gear", steps = {
    { auto = { item = 12360, count = 10, forFaction = "Alliance" } },
    { auto = { item = 12360, count = 20, forFaction = "Alliance" } },
    { auto = { item = { 100, 101 }, count = 1 } },
} }
local other = { id = "tooltip_other", name = "Other gear", steps = {
    { auto = { item = 12360, count = 50 } },
} }
local group = { id = "tooltip_group", name = "Selected gear", group = true, sections = {
    { name = "Chosen", pieces = { { materials = { "2 Arcanite Bars", "Arcanite Bar from a boss" } } } },
    { name = "Ignored", pieces = { { materials = { "100 Arcanite Bars" } } } },
} }
local aq = F.GoalById("set_tier25_rogue")
local tier3 = F.GoalById("tier3_warrior")
F.goals = { goal, other, group, aq, tier3 }
D.active = { [goal.id] = true, [aq.id] = true, [tier3.id] = true }
D.activeParts = { [group.id] = { [1] = true } }
D.progress = { [goal.id] = {}, [group.id] = {}, [aq.id] = {} }
D.characters = {
    A = { faction = "Alliance", items = { [12360] = 4, [101] = 1, [20928] = 1 } },
    H = { faction = "Horde", items = { [12360] = 7 } },
}
F.ItemInfo = function(id)
    if id == 999 then return end
    return id == 12360 and "Arcanite Bar" or "Test helmet", "|Hitem:" .. id .. "|h[Item]|h", 4,
        nil, nil, nil, nil, nil, id == 12360 and "" or "INVTYPE_HEAD"
end
local function need(id, goalId)
    for _, n in ipairs(F.ItemNeeds(id)) do if n.goal.id == goalId then return n.remaining end end
end
assert(need(12360, goal.id) == 16, "scoped stock and collection milestones")
assert(need(12360, other.id) == nil, "untracked goals omitted")
assert(need(12360, group.id) == 0, "selected recipe materials share one stock count")
assert(need(100, goal.id) == 0, "alternative reward stock counts once")
assert(need(20928, aq.id) == 1, "AQ boots and shoulders need separate tokens")
D.progress[aq.id]["1_1_piece"] = true
assert(need(20928, aq.id) == 0, "completed AQ piece removes its ingredients")
D.progress[aq.id]["1_3_piece"] = true
assert(need(20928, aq.id) == nil, "all related AQ pieces finished")
D.progress[group.id]["1_1_m1"], D.progress[group.id]["1_1_m2"] = true, true
assert(need(12360, group.id) == nil, "finished material checklist omitted")
D.progress[goal.id][2] = true
assert(need(12360, goal.id) == 6, "unfinished target updates immediately")
D.progress[goal.id][1] = true
assert(need(12360, goal.id) == nil, "finished collection omitted")
D.progress[goal.id][1] = nil
local arcanite = 0
for _, piece in ipairs(tier3.sections[1].pieces) do
    for _, text in ipairs(piece.materials) do
        if text:find("Arcanite Bar", 1, true) then arcanite = arcanite + tonumber(text:match("^(%d+)")) end
    end
end
assert(need(12360, tier3.id) == arcanite - 11, "actual Tier 3 recipe total subtracts stock once")

-- Exercise both native tooltip hook paths, clear/rebuild and duplicate
-- suppression. Real bag/loot/AH tooltips all use this same item callback.
local oldTip, oldRef, oldProcessor, oldEnum = GameTooltip, ItemRefTooltip, TooltipDataProcessor, Enum
local oldHooks = F.itemTooltipHooks
local function tip()
    local t = CreateFrame("Frame")
    t.lines = {}
    t.AddLine = function(self, text) self.lines[#self.lines + 1] = text end
    t.GetItem = function() return "Arcanite Bar", "item:12360" end
    return t
end
GameTooltip, ItemRefTooltip = tip(), tip()
TooltipDataProcessor = nil
F.itemTooltipHooks = nil
F.InstallItemTooltipHooks()
GameTooltip:GetScript("OnTooltipSetItem")(GameTooltip)
local n = #GameTooltip.lines
assert(n > 0 and GameTooltip.lines[2] == "Needed for", "legacy item hook appends needs")
GameTooltip:GetScript("OnTooltipSetItem")(GameTooltip)
assert(#GameTooltip.lines == n, "no duplicate on repeated item hook")
GameTooltip:GetScript("OnTooltipCleared")(GameTooltip)
GameTooltip.lines = {}
GameTooltip:GetScript("OnTooltipSetItem")(GameTooltip)
assert(#GameTooltip.lines == n, "rebuilt tooltip restores needs")
F.SetSetting("itemNeeds", false)
ItemRefTooltip:GetScript("OnTooltipSetItem")(ItemRefTooltip)
assert(#ItemRefTooltip.lines == 0, "setting disables needs")
F.SetSetting("itemNeeds", true)
local callback
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) assert(kind == 0); callback = fn end }
Enum = { TooltipDataType = { Item = 0 } }
GameTooltip, ItemRefTooltip = tip(), tip()
F.itemTooltipHooks = nil
F.InstallItemTooltipHooks()
assert(not GameTooltip:GetScript("OnTooltipSetItem"), "modern path avoids removed script")
callback(GameTooltip, { id = 12360 })
callback(ItemRefTooltip, { id = 12360 })
assert(#GameTooltip.lines == n and #ItemRefTooltip.lines == n, "modern item and chat tooltips")
local compare = tip()
callback(compare, { id = 12360 })
assert(#compare.lines == 0, "equipment comparison kept clear")
GameTooltip, ItemRefTooltip, TooltipDataProcessor, Enum = oldTip, oldRef, oldProcessor, oldEnum
F.itemTooltipHooks = oldHooks

-- Drive the actual hyperlink and row dispatchers. Preview must consume
-- the click before the ordinary step toggle, including uncached items.
local oldMod, oldDress, oldShift = IsModifiedClick, DressUpItemLink, IsShiftKeyDown
local modified, preview, ticks = true, nil, 0
IsModifiedClick = function(kind) return kind == "DRESSUP" and modified end
IsShiftKeyDown = function() return false end
DressUpItemLink = function(link) preview = link end
assert(F.PreviewItemClick(100, "LeftButton") and preview:find("item:100", 1, true))
assert(F.PreviewItemClick(999, "LeftButton"), "loading item click still consumed")
assert(not F.PreviewItemClick(100, "RightButton"), "right click retains Wowhead behavior")
assert(F.ItemCanPreview(100) and not F.ItemCanPreview(12360), "preview hint only for equipment")
local row = CreateFrame("Button")
row.itemId = 100
row:SetScript("OnClick", function(self, button) if not F.StepLinkClick(self, button) then ticks = ticks + 1 end end)
F.EnableGoalLinks(row)
row:GetScript("OnHyperlinkClick")(row, "item:100", "Test helmet", "LeftButton")
assert(ticks == 0, "preview hyperlink never ticks")
row:GetScript("OnClick")(row, "LeftButton")
assert(ticks == 0, "preview row never ticks")
modified = false
row:GetScript("OnHyperlinkClick")(row, "item:100", "Test helmet", "LeftButton")
assert(ticks == 1, "plain hyperlink click still ticks")
IsModifiedClick, DressUpItemLink, IsShiftKeyDown = oldMod, oldDress, oldShift
F.goals, D.active, D.activeParts, D.progress, D.characters, F.ItemInfo =
    saved.goals, saved.active, saved.parts, saved.progress, saved.characters, saved.info
print("  native tooltip hooks, selected groups, finished steps, recipe totals, stock scopes and preview clicks ok")
