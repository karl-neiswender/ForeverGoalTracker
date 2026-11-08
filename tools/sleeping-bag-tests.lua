-- Cozy Sleeping Bag (Karl, 2026-11-07): a Forever-only Collectible whose steps link every quest and every
-- note object on the ground, with map spots and Wowhead object pages, per faction where the spots differ.
local F, D = STUB_NS, ForeverGoalTrackerDB
local g = assert(F.GoalById("cozy_sleeping_bag"))
assert(g.category == "Collectible" and g.forever == "new" and g.needs == "forever")
assert(F.LibraryVisible(g) == F.isForever, "the sleeping bag goal is only visible in Forever")
assert(g.completeWith.quest == 79976 and g.completeWith.item == 211527)

if F.isForever then
    local mine = UnitFactionGroup and UnitFactionGroup("player")
    local function links(i) return F.LinkText(g.steps[i].text) end
    -- every step after the level step names its quest as a link
    for i = 2, #g.steps do
        assert(links(i):find("fgtquest:", 1, true), "step " .. i .. " links its quest")
    end
    -- and the note object it is found at, as an object with a map spot
    local objects = { [4] = 424005, [5] = 424012, [6] = 424007, [7] = 406918, [8] = 424006 }
    for i, id in pairs(objects) do
        assert(links(i):find("fgtnpc:" .. id, 1, true), "step " .. i .. " links object " .. id)
        local n = F.NpcById(id)
        assert(n and n.object and n.map and n.x and n.y, "object " .. id .. " has a spot and opens Wowhead's object page")
    end
    -- the two note spots follow the player's faction
    local remains = mine == "Horde" and 415106 or 415107
    assert(links(2):find("fgtnpc:" .. remains, 1, true), "the Burned-Out Remains link is the player's faction's")
    assert(links(3):find("fgtnpc:424010", 1, true), "the Nailed Plank is linked")
    local plank = F.NpcById(424010)
    if mine then
        assert(plank.faction == mine, "the Nailed Plank entry is the player's faction's")
        assert(plank.zone ~= F.NpcById(remains).zone, "the plank is in the other zone from the remains")
    end
    assert(links(8):find("item:211527", 1, true), "the last step links the sleeping bag")

    -- progress: any faction's first quest counts, and the last quest or the bag completes everything
    local active, chars, progress = D.active, D.characters, D.progress
    D.active, D.characters, D.progress = { cozy_sleeping_bag = true }, {}, { cozy_sleeping_bag = {} }
    local c = { name = "Camper", class = "MAGE", faction = mine or "Alliance", level = 14, items = {}, quests = {}, questsTaken = {} }
    D.characters["Camper-Other"] = c
    c.questsTaken[79007] = true
    STUB_FIRE("BAG_UPDATE_DELAYED")
    assert(D.progress.cozy_sleeping_bag[2] and not D.progress.cozy_sleeping_bag[3], "picking up the Horde note ticks the first note step only")
    c.items[211527] = 1
    STUB_FIRE("BAG_UPDATE_DELAYED")
    for i = 1, #g.steps do assert(D.progress.cozy_sleeping_bag[i], "owning the bag completes step " .. i) end
    D.active, D.characters, D.progress = active, chars, progress
end
