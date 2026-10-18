local F, D = STUB_NS, ForeverGoalTrackerDB
local buffs = F.GoalById("social_buffs")
assert(F.GoalFits(buffs, {}), "Anyone still includes the account goal")
for _, class in ipairs(F.CLASSES) do
    assert(F.GoalFits(buffs, {class=class.token}) == not not F.BUFF_CLASSES[class.token],
        "character filter matches the supported buff tracker: " .. class.token)
end
local reaper = F.GoalById("arcanite_reaper")
D.active[reaper.id], D.progress[reaper.id] = true, {}
F.SetSetting("hideCompletedSteps", false)
F.SetSetting("celebrations", "off")
F.SelectGoal(reaper.id)
assert(F.stepRows[2].num:GetText() == "2.", "Blacksmithing keeps its normal step number")
local function watch(frame)
    frame.Show = function(self) self.visible = true end
    frame.Hide = function(self) self.visible = false end
    frame.IsShown = function(self) return self.visible == true end
end
for _, row in ipairs(F.stepRows) do watch(row.miniBar) end
-- Pool reuse must hide the binary raid bar without removing real count bars.
for _, id in ipairs({"raid_hyjal", "raid_barrow"}) do
    D.active[id], D.progress[id] = true, {}
    F.SelectGoal(id)
    assert(not F.stepRows[1].miniBar.visible, "binary boss objective has no redundant bar")
    assert(F.stepRows[1].ruleEntry.stat, "automatic statistics tracking stays intact")
end
F.SelectGoal(reaper.id)
assert(F.stepRows[2].miniBar.visible, "profession count bar still appears on a reused row")
if F.isForever then
    assert(F.Popout:Open(reaper.id))
    for _, row in ipairs(F.Popout.rows) do watch(row.miniBar) end
    assert(F.Popout:Open("raid_hyjal"))
    assert(not F.Popout.rows[1].miniBar.visible, "pop-out uses the same bar visibility")
    F.Popout:Close()
end
local oldMap = C_Map
C_Map = C_Map or {}
for _, side in ipairs({{"ally",12783,"pvp_alliance"}, {"horde",12796,"pvp_horde"}}) do
    local g = F.GoalById("pvp_mount_" .. side[1])
    local linked = F.LinkText(g.steps[2].text)
    assert(linked:find("|Hfgtnpc:" .. side[2], 1, true), "correct vendor links")
    assert(linked:find("|Hfgtentrance:" .. side[3], 1, true), "city links to the relevant hall")
    assert(F.MapLinkText(linked) == linked, "linked city needs no duplicate Show on map")
    assert(F.MapLinkText(F.LinkText("Visit " .. F.NpcById(side[2]).name)):find("|Hfgtmap:" .. side[2], 1, true), "NPC-only steps keep their map action")
    local npc = F.NpcById(side[2])
    local hall = F.NpcById("dungeon:" .. side[3])
    assert(npc.map == hall.map and npc.x == hall.x and npc.y == hall.y, "city and vendor pins agree")
    assert((F.NpcNote(npc) ~= nil) == not not F.isForever, "Forever location uncertainty stays visible")
end
C_Map = oldMap
print("  guide fixes: supported buff classes, step numbers, pooled count bars, vendor/city links and pins pass")
