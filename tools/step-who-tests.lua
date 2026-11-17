-- Finished steps name the characters that met them (FGT.StepWho, FGT.StepWhoLine; Karl, 2026-11-17).
local F, D = STUB_NS, ForeverGoalTrackerDB
local saved = D.characters
D.characters = {
    ["Tester-Realm"] = { name = "Tester", level = 60, race = "Dwarf", faction = "Alliance", money = 0,
        items = {}, quests = {}, reps = {}, skills = { Riding = 75 } },
    ["Bryn-Realm"] = { name = "Bryn", level = 60, race = "Human", faction = "Alliance", money = 12000000,
        items = { [18776] = 1 }, quests = { [7786] = true }, reps = { [72] = { standing = 8, value = 999 } },
        skills = { Riding = 150 } },
    ["Ada-Realm"] = { name = "Ada", surname = "Stone", level = 42, race = "Gnome", faction = "Alliance",
        items = {}, quests = { [7786] = true }, reps = { [72] = { standing = 6, value = 10 } }, skills = {} },
    ["Cole-Realm"] = { name = "Cole", level = 60, race = "Orc", faction = "Horde", items = {}, quests = {}, reps = {}, skills = {} },
    ["Dax-Realm"] = { name = "Dax", level = 60, race = "Troll", faction = "Horde", items = {}, quests = {}, reps = {}, skills = {} },
}

local function same(a, b) return table.concat(a or {}, ",") == table.concat(b or {}, ",") end
assert(same(F.StepWho({ level = 60 }), { "Bryn", "Cole", "Dax", "Tester" }), "every level 60 character, sorted")
assert(same(F.StepWho({ level = 60, forFaction = "Alliance" }), { "Bryn", "Tester" }), "a scoped rule names only its characters")
assert(same(F.StepWho({ quest = 7786 }), { "Ada Stone", "Bryn" }), "quests, with full names")
assert(same(F.StepWho({ item = { 18777, 18776 } }), { "Bryn" }), "items: whoever holds one")
assert(same(F.StepWho({ rep = { faction = 72, standing = 8 } }), { "Bryn" }), "reputation needs the standing itself")
assert(same(F.StepWho({ skill = { name = "Riding", rank = 150 } }), { "Bryn" }))
assert(same(F.StepWho({ money = 1000 * 10000 }), { "Bryn" }))
assert(F.StepWho({ quest = 1 }) == nil and F.StepWho(nil) == nil, "nobody, or no rule: no names")

assert(F.StepWhoLine({ quest = 7786 }) == "Done on Ada Stone and Bryn")
assert(F.StepWhoLine({ item = 18776 }) == "Done on Bryn", "one other character")
assert(F.StepWhoLine({ level = 60 }) == "Done on Bryn, Cole, Dax +1 more", "three names, then a count")
assert(F.StepWhoLine({ skill = { name = "Riding", rank = 75 } }) == "Done on Bryn and Tester", "you are named beside the others")
D.characters["Bryn-Realm"].skills.Riding = 0
assert(F.StepWhoLine({ skill = { name = "Riding", rank = 75 } }) == nil, "only the character you play: nothing to say")

D.characters = saved
print("  finished steps name the characters that met them; only you, or nobody, adds no line")
