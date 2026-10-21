local F = STUB_NS
local function count(s, pattern) local _, n = s:gsub(pattern, ""); return n end
local text = F.LinkText("Run Lower Blackrock Spire, Upper Blackrock Spire and Scholomance, then Scholomance again.")
assert(count(text, "|Hfgtentrance:brs|h") == 2, "longest aliases resolve to the shared entrance")
assert(count(text, "|Hfgtentrance:scholo|h") == 2, "repeated mentions remain clickable")
for label in text:gmatch("|Hfgtentrance:[^|]+|h(.-)|h") do assert(not label:find("|H", 1, true), "links never nest") end
assert(F.LinkText(text) == text, "linking is idempotent")
assert(not F.LinkText("Reach Exalted with Gnomeregan Exiles."):find("fgtentrance"), "reputation is not a dungeon")
assert(not F.LinkText("Scholomancer"):find("fgtentrance"), "whole names only")
local tagged = F.LinkText("Visit {key_ubrs:Upper Blackrock Spire} and {item:1:Scholomance}.")
assert(not tagged:find("fgtentrance"), "explicit goal and item tags preserved")
local source = "|Hfgtquest:1|hThe Key to Scholomance|h"
assert(F.LinkDungeons(source) == source, "quest links preserved")
for _, n in ipairs(F.DUNGEONS) do
    assert(F.NpcById(n.id) == n and n.x > 0 and n.x < 100 and n.y > 0 and n.y < 100)
    if n.manual then
        -- Planner-only entrances: guides never auto-link them, but the planner's own tag opens the same route.
        assert(not F.LinkText("Visit " .. n.name .. "."):find("fgtentrance", 1, true), n.name .. " stays plain in guides")
        assert(F.LocationTag(n.id, n.name):find("Hfgtentrance:" .. n.id:gsub("^dungeon:", ""), 1, true), n.name)
    elseif not n.forever or F.isForever then
        assert(F.LinkText("Visit " .. n.name .. "."):find("|Hfgtentrance:", 1, true), n.name)
    end
end
local row = CreateFrame("Button")
F.EnableGoalLinks(row)
row:GetScript("OnHyperlinkEnter")(row, "fgtentrance:scholo")
assert(F.overLink == "map", "hover guards the step checkbox")
row:GetScript("OnHyperlinkLeave")(row)
assert(not F.overLink, "leave clears the checkbox guard")
local called
local old = F.MapLinkClick
F.MapLinkClick = function(id) called = id end
row:GetScript("OnHyperlinkClick")(row, "fgtentrance:scholo", "Scholomance", "LeftButton")
assert(called == "dungeon:scholo", "click reuses the map link route")
F.MapLinkClick = old
F.MapLinkClick("dungeon:unknown")
print("  dungeon names, boundaries, preserved links, repeated mentions and map routing pass")

assert(F.NpcById("dungeon:strat").mapZoom == 44, "Stratholme defaults to 44 percent")
assert(F.LinkText("Visit Light's Hope Chapel and Zul'Gurub."):find("fgtentrance:hub:rep_argentdawn", 1, true))
assert(F.LinkText("Visit Zul'Gurub."):find("fgtentrance:hub:raid_zg", 1, true))
local bwl = F.LinkText(F.GoalById("raid_bwl").steps[1].text)
assert(bwl:find("|Hfgtgoal:key_ubrs", 1, true) and bwl:find("|Hfgtentrance:brs", 1, true), "UBRS goal and map links coexist")
local dalaran = F.LinkText("Visit the City of Dalaran.")
assert((dalaran:find("|Hfgtentrance:dalaran", 1, true) ~= nil) == not not F.isForever, "Dalaran is Forever only")
local n = F.NpcById("dungeon:wc")
assert(n.x == 47.7 and n.y == 35, "reviewed Wailing Caverns entrance")
local originalShow, originalShown, originalWidth = F.Maplet.Show, F.goalBanner.IsShown, F.goalBanner.art.GetWidth
local originalHeight, originalTarget = F.goalBanner.shownArtHeight, F.Maplet.target
local shownZoom
F.goalBanner.IsShown = function() return true end
F.goalBanner.art.GetWidth = function() return 500 end
F.goalBanner.shownArtHeight = 200
F.Maplet.target = 0
F.Maplet.Show = function(self, spot, quiet, manual, zoom) shownZoom = zoom; return true end
F.MapLinkClick("dungeon:strat")
assert(shownZoom == 44, "default zoom reaches banner map")
F.MapLinkClick("dungeon:strat", 12)
assert(shownZoom == 12, "explicit zoom can override default")
F.Maplet.Show, F.goalBanner.IsShown, F.goalBanner.art.GetWidth = originalShow, originalShown, originalWidth
F.goalBanner.shownArtHeight, F.Maplet.target = originalHeight, originalTarget
