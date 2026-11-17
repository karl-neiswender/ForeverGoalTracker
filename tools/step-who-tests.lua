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

-- under the step: only steps tied to one character (quests, items, mounts), worded "On ..."
assert(F.StepWhoLine({ quest = 7786 }) == "On Ada Stone and Bryn")
assert(F.StepWhoLine({ item = 18776 }) == "On Bryn", "one other character")
assert(F.StepWhoLine({ level = 60 }) == nil, "any character counts for a level: tooltip only")
assert(F.StepWhoLine({ skill = { name = "Riding", rank = 75 } }) == nil, "skills: tooltip only")
D.characters["Tester-Realm"].items = { [18777] = 1 }
assert(F.StepWhoLine({ item = 18777 }) == nil, "only the character you play: nothing under the step")

-- tooltips: every finished step, "Done on" and then one name a line, you included
local lines, tip = {}, GameTooltip
GameTooltip = setmetatable({ AddLine = function(_, text) lines[#lines + 1] = text end }, { __index = tip })
assert(F.AddStepWhoTip({ level = 60 }) and table.concat(lines, "|") == "Done on|   Bryn|   Cole|   Dax|   Tester",
    "one name a line, so none breaks in two")
lines = {}
assert(F.AddStepWhoTip({ item = 18777 }) and lines[2] == "   Tester", "the tooltip still names you")
lines = {}
assert(not F.AddStepWhoTip({ quest = 1 }) and #lines == 0, "nobody: no lines")
GameTooltip = tip

D.characters = saved
print("  finished steps: names in tooltips; under the step only for quests, items and mounts on another character")
