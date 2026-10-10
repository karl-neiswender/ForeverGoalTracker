local ADDON, FGT = ...

-- Classic AQ40 Tier 2.5, checked against Wowhead Classic on 2026-10-10:
-- https://www.wowhead.com/classic/guide/temple-ahnqiraj-aq40-tier-25-classic-wow
-- Stable piece order: boots, helm, shoulders, legs, chest.
-- Tuples: name, reward ID, icon, token ID, idol ID, scarab IDs.
local sets = {
    { "Druid", "Genesis Raiment", {
        { "Genesis Boots", 21355, "inv_boots_cloth_07", 20932, 20878, 20858, 20860 },
        { "Genesis Helm", 21353, "inv_helmet_06", 20930, 20879, 20859, 20863 },
        { "Genesis Shoulderpads", 21354, "inv_shoulder_03", 20932, 20881, 20859, 20864 },
        { "Genesis Trousers", 21356, "inv_pants_leather_01", 20931, 20882, 20858, 20862 },
        { "Genesis Vest", 21357, "inv_chest_leather_08", 20933, 20878, 20861, 20865 },
    } },
    { "Hunter", "Striker's Garb", {
        { "Striker's Footguards", 21365, "inv_boots_chain_08", 20928, 20879, 20858, 20864 },
        { "Striker's Diadem", 21366, "inv_helmet_73", 20930, 20881, 20861, 20865 },
        { "Striker's Pauldrons", 21367, "inv_shoulder_36", 20928, 20882, 20862, 20865 },
        { "Striker's Leggings", 21368, "inv_pants_mail_11", 20931, 20874, 20860, 20864 },
        { "Striker's Hauberk", 21370, "inv_chest_chain_04", 20929, 20879, 20859, 20863 },
    } },
    { "Mage", "Enigma Vestments", {
        { "Enigma Boots", 21344, "inv_boots_cloth_03", 20932, 20874, 20860, 20862 },
        { "Enigma Circlet", 21347, "inv_helmet_06", 20926, 20875, 20861, 20865 },
        { "Enigma Shoulderpads", 21345, "inv_shoulder_03", 20932, 20876, 20858, 20861 },
        { "Enigma Leggings", 21346, "inv_pants_cloth_08", 20927, 20877, 20860, 20864 },
        { "Enigma Robes", 21343, "inv_chest_cloth_11", 20933, 20874, 20859, 20863 },
    } },
    { "Paladin", "Avenger's Battlegear", {
        { "Avenger's Greaves", 21388, "inv_boots_chain_07", 20932, 20877, 20861, 20863 },
        { "Avenger's Crown", 21387, "inv_helmet_72", 20930, 20878, 20858, 20862 },
        { "Avenger's Pauldrons", 21391, "inv_shoulder_35", 20932, 20879, 20859, 20862 },
        { "Avenger's Legguards", 21390, "inv_pants_plate_02", 20931, 20881, 20865, 20861 },
        { "Avenger's Breastplate", 21389, "inv_chest_plate03", 20929, 20877, 20860, 20864 },
    } },
    { "Priest", "Garments of the Oracle", {
        { "Footwraps of the Oracle", 21349, "inv_boots_cloth_07", 20928, 20876, 20861, 20859 },
        { "Tiara of the Oracle", 21348, "inv_helmet_06", 20926, 20877, 20860, 20864 },
        { "Mantle of the Oracle", 21350, "inv_shoulder_03", 20928, 20878, 20860, 20865 },
        { "Trousers of the Oracle", 21352, "inv_pants_cloth_07", 20927, 20879, 20859, 20863 },
        { "Vestments of the Oracle", 21351, "inv_chest_cloth_10", 20933, 20876, 20858, 20862 },
    } },
    { "Rogue", "Deathdealer's Embrace", {
        { "Deathdealer's Boots", 21359, "inv_boots_08", 20928, 20881, 20862, 20864 },
        { "Deathdealer's Helm", 21360, "inv_helmet_04", 20930, 20882, 20863, 20859 },
        { "Deathdealer's Spaulders", 21361, "inv_shoulder_03", 20928, 20874, 20860, 20863 },
        { "Deathdealer's Leggings", 21362, "inv_pants_leather_07", 20927, 20875, 20858, 20862 },
        { "Deathdealer's Vest", 21364, "inv_chest_leather_08", 20929, 20881, 20861, 20865 },
    } },
    { "Shaman", "Stormcaller's Garb", {
        { "Stormcaller's Footguards", 21373, "inv_boots_chain_07", 20932, 20877, 20861, 20863 },
        { "Stormcaller's Diadem", 21372, "inv_helmet_73", 20930, 20878, 20858, 20862 },
        { "Stormcaller's Pauldrons", 21376, "inv_shoulder_03", 20932, 20879, 20859, 20862 },
        { "Stormcaller's Leggings", 21375, "inv_pants_mail_10", 20931, 20881, 20865, 20861 },
        { "Stormcaller's Hauberk", 21374, "inv_chest_chain_13", 20929, 20877, 20860, 20864 },
    } },
    { "Warlock", "Doomcaller's Attire", {
        { "Doomcaller's Footwraps", 21338, "inv_boots_cloth_02", 20932, 20875, 20863, 20865 },
        { "Doomcaller's Circlet", 21337, "inv_helmet_06", 20926, 20876, 20860, 20864 },
        { "Doomcaller's Mantle", 21335, "inv_shoulder_03", 20932, 20877, 20861, 20864 },
        { "Doomcaller's Trousers", 21336, "inv_pants_cloth_02", 20931, 20878, 20859, 20863 },
        { "Doomcaller's Robes", 21334, "inv_chest_cloth_12", 20933, 20875, 20862, 20858 },
    } },
    { "Warrior", "Conqueror's Battlegear", {
        { "Conqueror's Greaves", 21333, "inv_boots_plate_05", 20928, 20882, 20865, 20859 },
        { "Conqueror's Crown", 21329, "inv_helmet_72", 20926, 20874, 20862, 20858 },
        { "Conqueror's Spaulders", 21330, "inv_shoulder_35", 20928, 20875, 20863, 20858 },
        { "Conqueror's Legguards", 21332, "inv_pants_plate_03", 20927, 20876, 20861, 20865 },
        { "Conqueror's Breastplate", 21331, "inv_chest_plate12", 20929, 20882, 20860, 20864 },
    } },
}
local items = {
    [20926] = "Vek'nilash's Circlet", [20927] = "Ouro's Intact Hide",
    [20928] = "Qiraji Bindings of Command", [20929] = "Carapace of the Old God",
    [20930] = "Vek'lor's Diadem", [20931] = "Skin of the Great Sandworm",
    [20932] = "Qiraji Bindings of Dominance", [20933] = "Husk of the Old God",
    [20874] = "Idol of the Sun", [20875] = "Idol of Night", [20876] = "Idol of Death",
    [20877] = "Idol of the Sage", [20878] = "Idol of Rebirth", [20879] = "Idol of Life",
    [20881] = "Idol of Strife", [20882] = "Idol of War",
    [20858] = "Stone Scarab", [20859] = "Gold Scarab", [20860] = "Silver Scarab",
    [20861] = "Bronze Scarab", [20862] = "Crystal Scarab", [20863] = "Clay Scarab",
    [20864] = "Bone Scarab", [20865] = "Ivory Scarab",
}
local bosses = {
    [20926] = "Emperor Vek'nilash", [20930] = "Emperor Vek'lor",
    [20927] = "Ouro", [20931] = "Ouro", [20929] = "C'Thun", [20933] = "C'Thun",
    [20928] = "Princess Huhuran or Viscidus", [20932] = "Princess Huhuran or Viscidus",
}
local npcs = { "Kandrostrasz", "Andorgos", "Andorgos", "Kandrostrasz", "Vethsera" }
local reputation = { "Neutral", "Friendly", "Neutral", "Friendly", "Honored" }
local function item(id) return "{item:" .. id .. ":" .. items[id] .. "}" end
local sections = {}
for _, set in ipairs(sets) do
    local pieces, tips = {}, {
        "The turn-in NPCs are inside {raid_aq40:Temple of Ahn'Qiraj}, near C'Thun's chamber, accessible after defeating The Prophet Skeram.",
        "Idols and scarabs come from AQ40 trash and scarab coffers. Keep them for your armor turn-ins.",
    }
    for pi, p in ipairs(set[3]) do
        pieces[pi] = {
            name = p[1], text = "Collect " .. p[1] .. " from " .. npcs[pi] .. " in Temple of Ahn'Qiraj.",
            icon = p[3], materials = {}, auto = { item = p[2], owned = { p[1] } },
            requiredItems = { { item = p[4], count = 1 }, { item = p[5], count = 2 },
                              { item = p[6], count = 5 }, { item = p[7], count = 5 } },
        }
        tips[#tips + 1] = "{item:" .. p[2] .. ":" .. p[1] .. "}: bring 1 " .. item(p[4]) ..
            " (from " .. bosses[p[4]] .. "), 2 " .. item(p[5]) .. ", 5 " .. item(p[6]) ..
            " and 5 " .. item(p[7]) .. " to " .. npcs[pi] .. ". Requires " .. reputation[pi] ..
            " with the Brood of Nozdormu."
    end
    sections[#sections + 1] = {
        name = set[1] .. " - " .. set[2], icon = "ClassIcon_" .. set[1],
        goalIcon = pieces[2].icon, pieces = pieces, tips = tips,
    }
end
FGT.goals[#FGT.goals + 1] = {
    id = "set_tier25", library = true, group = true, itemQuality = 4,
    name = "Tier 2.5 Set Appearances", short = "Tier 2.5 Sets", icon = "inv_helmet_72",
    category = "Item Set", difficulty = "Very Hard", timeEstimate = "3+ Months",
    note = "The five-piece Ahn'Qiraj sets, known as Tier 2.5. Exchange AQ40 boss tokens, idols and scarabs with Brood of Nozdormu reputation. Pick the classes you want in the Library; each piece ticks itself when you own it.",
    sections = sections,
}
