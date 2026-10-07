local ADDON, FGT = ...

-- Warcraft Forever reports interface 16xxx, Classic Era 11xxx (same
-- check as FGT.isForever in Core.lua, which loads after this file).
local FOREVER_CLIENT = (select(4, GetBuildInfo()) or 0) >= 16000

-- ============================================================
-- Category colors (r, g, b)
-- ============================================================
-- WoW item-quality-inspired accents that sit well on the charcoal theme.
FGT.categoryColors = {
    ["Legendary Weapon"] = { 1.00, 0.50, 0.00 },   -- legendary orange #ff8000
    ["Legendary Staff"]  = { 0.69, 0.40, 0.97 },   -- epic purple
    ["Mount"]            = { 0.50, 0.78, 1.00 },   -- #7fc8ff
    ["Mount Collection"] = { 0.50, 0.78, 1.00 },
    ["Tier Set"]         = { 1.00, 0.82, 0.00 },   -- gold #ffd100
    ["Item Set"]         = { 1.00, 0.82, 0.00 },
    ["Epic Weapon"]      = { 0.64, 0.21, 0.93 },   -- epic purple #a335ee
    ["Milestone"]        = { 0.62, 0.91, 0.44 },   -- #9fe870
}

-- ============================================================
-- Difficulty tiers (order = relative scale, color = r, g, b)
-- ============================================================
FGT.difficultyOrder = { "Moderate", "Hard", "Very Hard", "Extreme" }

-- Time estimates, fastest first. Goals use exactly these labels, and
-- "Sort: Duration" follows this order.
FGT.timeScale = { "Days", "1-2 Weeks", "2-4 Weeks", "1-2 Months", "3+ Months", "Years", "Ongoing", "Varies" }
FGT.timeRank = {}
for i, label in ipairs(FGT.timeScale) do FGT.timeRank[label] = i end
FGT.difficultyColors = {
    ["Moderate"]  = { 0.62, 0.91, 0.44 },   -- #9fe870
    ["Hard"]      = { 1.00, 0.82, 0.00 },   -- #ffd100
    ["Very Hard"] = { 1.00, 0.60, 0.24 },   -- #ff993d
    ["Extreme"]   = { 1.00, 0.48, 0.48 },   -- #ff7a7a
}

-- Epic riding mount helper: builds the checklist for one race's mount.
-- raceFile is the game's internal race name (UnitRace's 2nd return;
-- Undead is "Scourge"). ownedPatterns are Lua patterns matched against
-- mount and item names you own, to spot the purchase automatically.
-- Every race reads the same way; only the names, place and gold change.
-- gold = { label, minimum } for the savings step (default Classic Era's
-- 800-1,000: riding training plus the mount).
-- home = { faction, factionId, factionName, race plural }: any character of that
-- faction can buy it (level 60, Exalted with the race's home city; that
-- race itself skips the reputation). 5 steps. Without home (Skyborne,
-- whose rules for other races aren't known yet) it's the 4 race-only steps.
-- items: the mount's color variants as { item id, name } (Wowhead Classic,
-- checked 2026-10-07); any one ticks the buy step, and the step's mount
-- name becomes a link whose tooltip lists every color (ariants).
-- Wowhead NPC IDs of the mount vendors (Classic, Genn on Forever; checked
-- 2026-10-07): the mount type's Wowhead link opens the vendor's "Sells"
-- tab, which lists every color (Karl: one color's page felt clunky).
local VENDOR_NPC = { ["Katie Hunter"] = 384, ["Veron Amberstill"] = 1261, ["Lelanai"] = 4730,
    ["Milli Featherwhistle"] = 7955, ["Ogunaro Wolfrunner"] = 3362, ["Harb Clawhoof"] = 3685,
    ["Zachariah Post"] = 4731, ["Zjolnir"] = 7952, ["Genn Fairweather"] = 265756 }
local function BuildMountTasks(race, mountName, vendor, location, raceFile, ownedPatterns, gold, home, items)
    gold = gold or { "800-1,000", 800 }
    local ids = {}
    for i, it in ipairs(items or {}) do ids[i] = it[1] end
    -- "Buy a Swift Ram" when it comes in several colors, "Buy the ..." for one
    local article = (#ids > 1) and "a " or "the "
    local link = items and { { ids[1], mountName, variants = items, npc = VENDOR_NPC[vendor], vendor = vendor } }
    if home then
        local side, repId, repName, races = home[1], home[2], home[3], home[4]
        return {
            { name = "Level a " .. side .. " character to level 60", materials = {}, shared = "level60",
              auto = { level = 60, forFaction = side } },
            { name = "Reach Exalted with " .. repName .. " (optional for " .. races .. ")", materials = {},
              auto = { rep = { faction = repId, standing = 8 }, forFaction = side },
              skipIfRace = raceFile }, -- hidden while you play that race (FGT.PieceSkipped)
            { name = "Train " .. (FOREVER_CLIENT and "Journeyman" or "Expert") .. " Riding from your riding trainer", materials = {}, shared = "riding",
              auto = { skill = { name = "Riding", rank = 150 }, forFaction = side } },
            { name = "Save about " .. gold[1] .. " gold on that character", materials = {},
              auto = { money = gold[2] * 10000, forFaction = side } },
            { name = "Buy " .. article .. mountName .. " from " .. vendor .. " (" .. location .. ")", materials = {},
              auto = { ownedPattern = ownedPatterns, item = ids, forFaction = side },
              links = link },
        }
    end
    return {
        { name = "Level a " .. race .. " character to level 60", materials = {},
          auto = { raceLevel = { race = raceFile, level = 60 } } },
        -- Warcraft Forever renamed the skill: Journeyman Riding is what
        -- teaches swift mounts there. Same skill rank, 150.
        { name = "Train " .. (FOREVER_CLIENT and "Journeyman" or "Expert") .. " Riding from your riding trainer", materials = {}, shared = "riding",
          auto = { skill = { name = "Riding", rank = 150 }, forRace = raceFile } },
        { name = "Save about " .. gold[1] .. " gold on that character", materials = {},
          auto = { money = gold[2] * 10000, forRace = raceFile } },
        { name = "Buy " .. article .. mountName .. " from " .. vendor .. " (" .. location .. ")", materials = {},
          auto = { ownedPattern = ownedPatterns, item = ids, forRace = raceFile },
          links = link },
    }
end

-- ============================================================
-- Tier 3: your class's quartermaster at Light's Hope Chapel makes each
-- piece from a Desecrated token, Wartorn scraps and crafting materials.
-- Recipes, item IDs and icons from Wowhead (each piece's quest); token
-- sources from the tokens' "Dropped by" tabs.
-- ============================================================
-- Where each slot's token comes from, in piece order (helm to feet).
local TIER3_TOKEN_SOURCE = {
    "Thaddius",
    "Patchwerk, Grobbulus or Gluth",
    "the Four Horsemen Chest",
    "Maexxna",
    "Loatheb",
    "Noth the Plaguebringer, Heigan the Unclean or Gluth",
    "Anub'Rekhan, Grand Widow Faerlina or Gluth",
    "Instructor Razuvious, Gothik the Harvester or Gluth",
}

-- { class, set name, quartermaster, scrap type, pieces }
-- piece = { name, item id, icon, token, scraps, material, count, material, count }
local TIER3 = {
    { "Warrior", "Dreadnaught's Battlegear", "Korfax, Champion of the Light", "Plate", {
        { "Dreadnaught Helmet", 22418, "inv_helmet_58", "Desecrated Helmet", 15, "Arcanite Bar", 5, "Nexus Crystal", 1 },
        { "Dreadnaught Pauldrons", 22419, "inv_shoulder_29", "Desecrated Pauldrons", 12, "Arcanite Bar", 2, "Cured Rugged Hide", 3 },
        { "Dreadnaught Breastplate", 22416, "inv_chest_plate02", "Desecrated Breastplate", 25, "Arcanite Bar", 4, "Nexus Crystal", 2 },
        { "Dreadnaught Gauntlets", 22421, "inv_gauntlets_28", "Desecrated Gauntlets", 8, "Arcanite Bar", 1, "Cured Rugged Hide", 5 },
        { "Dreadnaught Legplates", 22417, "inv_pants_plate_05", "Desecrated Legplates", 20, "Arcanite Bar", 4, "Cured Rugged Hide", 3 },
        { "Dreadnaught Waistguard", 22422, "inv_belt_27", "Desecrated Waistguard", 8, "Arcanite Bar", 1, "Cured Rugged Hide", 5 },
        { "Dreadnaught Bracers", 22423, "inv_bracer_15", "Desecrated Bracers", 6, "Arcanite Bar", 1, "Nexus Crystal", 1 },
        { "Dreadnaught Sabatons", 22420, "inv_boots_plate_06", "Desecrated Sabatons", 12, "Arcanite Bar", 2, "Cured Rugged Hide", 3 },
    } },
    { "Paladin", "Redemption Armor", "Commander Eligor Dawnbringer", "Plate", {
        { "Redemption Headpiece", 22428, "inv_helmet_15", "Desecrated Headpiece", 15, "Arcanite Bar", 5, "Cured Rugged Hide", 2 },
        { "Redemption Spaulders", 22429, "inv_shoulder_14", "Desecrated Spaulders", 12, "Arcanite Bar", 2, "Nexus Crystal", 2 },
        { "Redemption Tunic", 22425, "inv_chest_chain_15", "Desecrated Tunic", 25, "Arcanite Bar", 4, "Cured Rugged Hide", 3 },
        { "Redemption Handguards", 22426, "inv_gauntlets_25", "Desecrated Handguards", 8, "Arcanite Bar", 1, "Cured Rugged Hide", 5 },
        { "Redemption Legguards", 22427, "inv_pants_mail_15", "Desecrated Legguards", 20, "Arcanite Bar", 4, "Nexus Crystal", 2 },
        { "Redemption Girdle", 22431, "inv_belt_22", "Desecrated Girdle", 8, "Arcanite Bar", 1, "Nexus Crystal", 3 },
        { "Redemption Wristguards", 22424, "inv_bracer_02", "Desecrated Wristguards", 6, "Arcanite Bar", 1, "Cured Rugged Hide", 2 },
        { "Redemption Boots", 22430, "inv_boots_chain_05", "Desecrated Boots", 12, "Arcanite Bar", 2, "Cured Rugged Hide", 3 },
    } },
    { "Hunter", "Cryptstalker Armor", "Huntsman Leopold", "Chain", {
        { "Cryptstalker Headpiece", 22438, "inv_helmet_15", "Desecrated Headpiece", 15, "Arcanite Bar", 4, "Nexus Crystal", 2 },
        { "Cryptstalker Spaulders", 22439, "inv_shoulder_14", "Desecrated Spaulders", 12, "Arcanite Bar", 2, "Cured Rugged Hide", 3 },
        { "Cryptstalker Tunic", 22436, "inv_chest_chain_15", "Desecrated Tunic", 25, "Arcanite Bar", 4, "Cured Rugged Hide", 3 },
        { "Cryptstalker Handguards", 22441, "inv_gauntlets_25", "Desecrated Handguards", 8, "Arcanite Bar", 1, "Cured Rugged Hide", 5 },
        { "Cryptstalker Legguards", 22437, "inv_pants_mail_15", "Desecrated Legguards", 20, "Arcanite Bar", 3, "Cured Rugged Hide", 5 },
        { "Cryptstalker Girdle", 22442, "inv_belt_22", "Desecrated Girdle", 8, "Arcanite Bar", 1, "Nexus Crystal", 3 },
        { "Cryptstalker Wristguards", 22443, "inv_bracer_02", "Desecrated Wristguards", 6, "Arcanite Bar", 1, "Cured Rugged Hide", 2 },
        { "Cryptstalker Boots", 22440, "inv_boots_chain_05", "Desecrated Boots", 12, "Arcanite Bar", 1, "Nexus Crystal", 3 },
    } },
    { "Rogue", "Bonescythe Armor", "Rohan the Assassin", "Leather", {
        { "Bonescythe Helmet", 22478, "inv_helmet_58", "Desecrated Helmet", 15, "Cured Rugged Hide", 8, "Nexus Crystal", 1 },
        { "Bonescythe Pauldrons", 22479, "inv_shoulder_29", "Desecrated Pauldrons", 12, "Cured Rugged Hide", 5, "Nexus Crystal", 1 },
        { "Bonescythe Breastplate", 22476, "inv_chest_plate02", "Desecrated Breastplate", 25, "Arcanite Bar", 2, "Cured Rugged Hide", 6 },
        { "Bonescythe Gauntlets", 22481, "inv_gauntlets_28", "Desecrated Gauntlets", 8, "Arcanite Bar", 1, "Cured Rugged Hide", 5 },
        { "Bonescythe Legplates", 22477, "inv_pants_plate_05", "Desecrated Legplates", 20, "Arcanite Bar", 1, "Cured Rugged Hide", 8 },
        { "Bonescythe Waistguard", 22482, "inv_belt_27", "Desecrated Waistguard", 8, "Cured Rugged Hide", 5, "Nexus Crystal", 1 },
        { "Bonescythe Bracers", 22483, "inv_bracer_15", "Desecrated Bracers", 6, "Arcanite Bar", 1, "Cured Rugged Hide", 2 },
        { "Bonescythe Sabatons", 22480, "inv_boots_plate_06", "Desecrated Sabatons", 12, "Cured Rugged Hide", 3, "Nexus Crystal", 2 },
    } },
    { "Priest", "Vestments of Faith", "Father Inigo Montoy", "Cloth", {
        { "Circlet of Faith", 22514, "inv_crown_01", "Desecrated Circlet", 15, "Mooncloth", 3, "Nexus Crystal", 3 },
        { "Shoulderpads of Faith", 22515, "inv_shoulder_25", "Desecrated Shoulderpads", 12, "Mooncloth", 2, "Cured Rugged Hide", 3 },
        { "Robe of Faith", 22512, "inv_chest_cloth_43", "Desecrated Robe", 25, "Mooncloth", 4, "Nexus Crystal", 2 },
        { "Gloves of Faith", 22517, "inv_gauntlets_17", "Desecrated Gloves", 8, "Mooncloth", 4 },
        { "Leggings of Faith", 22513, "inv_pants_cloth_05", "Desecrated Leggings", 20, "Mooncloth", 4, "Nexus Crystal", 2 },
        { "Belt of Faith", 22518, "inv_belt_08", "Desecrated Belt", 8, "Arcane Crystal", 2, "Mooncloth", 2 },
        { "Bindings of Faith", 22519, "inv_bracer_13", "Desecrated Bindings", 6, "Arcane Crystal", 1, "Nexus Crystal", 1 },
        { "Sandals of Faith", 22516, "inv_boots_fabric_01", "Desecrated Sandals", 12, "Mooncloth", 2, "Cured Rugged Hide", 3 },
    } },
    { "Druid", "Dreamwalker Raiment", "Rayne", "Leather", {
        { "Dreamwalker Headpiece", 22490, "inv_helmet_15", "Desecrated Headpiece", 15, "Cured Rugged Hide", 6, "Nexus Crystal", 2 },
        { "Dreamwalker Spaulders", 22491, "inv_shoulder_14", "Desecrated Spaulders", 12, "Cured Rugged Hide", 5, "Nexus Crystal", 1 },
        { "Dreamwalker Tunic", 22488, "inv_chest_chain_15", "Desecrated Tunic", 25, "Cured Rugged Hide", 6, "Nexus Crystal", 2 },
        { "Dreamwalker Handguards", 22493, "inv_gauntlets_25", "Desecrated Handguards", 8, "Cured Rugged Hide", 5, "Nexus Crystal", 1 },
        { "Dreamwalker Legguards", 22489, "inv_pants_mail_15", "Desecrated Legguards", 20, "Cured Rugged Hide", 8, "Nexus Crystal", 1 },
        { "Dreamwalker Girdle", 22494, "inv_belt_22", "Desecrated Girdle", 8, "Mooncloth", 3, "Cured Rugged Hide", 2 },
        { "Dreamwalker Wristguards", 22495, "inv_bracer_02", "Desecrated Wristguards", 6, "Arcane Crystal", 1, "Cured Rugged Hide", 2 },
        { "Dreamwalker Boots", 22492, "inv_boots_chain_05", "Desecrated Boots", 12, "Mooncloth", 3, "Cured Rugged Hide", 2 },
    } },
    { "Mage", "Frostfire Regalia", "Archmage Angela Dosantos", "Cloth", {
        { "Frostfire Circlet", 22498, "inv_crown_01", "Desecrated Circlet", 15, "Mooncloth", 3, "Nexus Crystal", 3 },
        { "Frostfire Shoulderpads", 22499, "inv_shoulder_25", "Desecrated Shoulderpads", 12, "Mooncloth", 2, "Cured Rugged Hide", 3 },
        { "Frostfire Robe", 22496, "inv_chest_cloth_43", "Desecrated Robe", 25, "Mooncloth", 4, "Nexus Crystal", 2 },
        { "Frostfire Gloves", 22501, "inv_gauntlets_17", "Desecrated Gloves", 8, "Mooncloth", 4 },
        { "Frostfire Leggings", 22497, "inv_pants_cloth_05", "Desecrated Leggings", 20, "Mooncloth", 4, "Nexus Crystal", 2 },
        { "Frostfire Belt", 22502, "inv_belt_03", "Desecrated Belt", 8, "Arcane Crystal", 2, "Mooncloth", 2 },
        { "Frostfire Bindings", 22503, "inv_bracer_13", "Desecrated Bindings", 6, "Arcane Crystal", 1, "Nexus Crystal", 1 },
        { "Frostfire Sandals", 22500, "inv_boots_fabric_01", "Desecrated Sandals", 12, "Mooncloth", 2, "Cured Rugged Hide", 3 },
    } },
    { "Warlock", "Plagueheart Raiment", "Mataus the Wrathcaster", "Cloth", {
        { "Plagueheart Circlet", 22506, "inv_crown_01", "Desecrated Circlet", 15, "Mooncloth", 3, "Nexus Crystal", 3 },
        { "Plagueheart Shoulderpads", 22507, "inv_shoulder_25", "Desecrated Shoulderpads", 12, "Mooncloth", 2, "Cured Rugged Hide", 3 },
        { "Plagueheart Robe", 22504, "inv_chest_cloth_43", "Desecrated Robe", 25, "Mooncloth", 4, "Nexus Crystal", 2 },
        { "Plagueheart Gloves", 22509, "inv_gauntlets_17", "Desecrated Gloves", 8, "Mooncloth", 4 },
        { "Plagueheart Leggings", 22505, "inv_pants_cloth_05", "Desecrated Leggings", 20, "Mooncloth", 4, "Nexus Crystal", 2 },
        { "Plagueheart Belt", 22510, "inv_belt_03", "Desecrated Belt", 8, "Arcane Crystal", 2, "Mooncloth", 2 },
        { "Plagueheart Bindings", 22511, "inv_bracer_13", "Desecrated Bindings", 6, "Arcane Crystal", 1, "Nexus Crystal", 1 },
        { "Plagueheart Sandals", 22508, "inv_boots_fabric_01", "Desecrated Sandals", 12, "Mooncloth", 2, "Cured Rugged Hide", 3 },
    } },
    { "Shaman", "The Earthshatterer", "Rimblat Earthshatter", "Chain", {
        { "Earthshatter Headpiece", 22466, "inv_helmet_15", "Desecrated Headpiece", 15, "Arcanite Bar", 4, "Nexus Crystal", 2 },
        { "Earthshatter Spaulders", 22467, "inv_shoulder_14", "Desecrated Spaulders", 12, "Arcanite Bar", 2, "Mooncloth", 2 },
        { "Earthshatter Tunic", 22464, "inv_chest_chain_15", "Desecrated Tunic", 25, "Arcanite Bar", 4, "Cured Rugged Hide", 3 },
        { "Earthshatter Handguards", 22469, "inv_gauntlets_25", "Desecrated Handguards", 8, "Arcanite Bar", 1, "Cured Rugged Hide", 5 },
        { "Earthshatter Legguards", 22465, "inv_pants_mail_15", "Desecrated Legguards", 20, "Arcanite Bar", 3, "Cured Rugged Hide", 5 },
        { "Earthshatter Girdle", 22470, "inv_belt_22", "Desecrated Girdle", 8, "Arcanite Bar", 1, "Nexus Crystal", 3 },
        { "Earthshatter Wristguards", 22471, "inv_bracer_02", "Desecrated Wristguards", 6, "Arcanite Bar", 1, "Cured Rugged Hide", 2 },
        { "Earthshatter Boots", 22468, "inv_boots_chain_05", "Desecrated Boots", 12, "Arcanite Bar", 1, "Nexus Crystal", 3 },
    } },
}

local function Tier3Count(n, name)
    if n == 1 or name == "Mooncloth" then return n .. " " .. name end
    return n .. " " .. name .. "s"
end

local function BuildTier3Sections()
    local sections = {}
    for _, set in ipairs(TIER3) do
        local class, setName, scrap, pieces = set[1], set[2], set[4], set[5]
        local list = {}
        for i, p in ipairs(pieces) do
            local materials = {
                p[4] .. " from " .. TIER3_TOKEN_SOURCE[i],
                Tier3Count(p[5], "Wartorn " .. scrap .. " Scrap") .. " from Naxxramas trash",
            }
            for m = 6, #p, 2 do
                table.insert(materials, Tier3Count(p[m + 1], p[m]))
            end
            table.insert(list, { name = p[1], icon = p[3], materials = materials,
                                 auto = { item = p[2], owned = { p[1] } } })
        end
        table.insert(sections, { icon = "ClassIcon_" .. class, name = class .. " - " .. setName, pieces = list })
    end
    return sections
end

-- One tip naming every class's quartermaster.
local function Tier3QuartermasterTip()
    local names = {}
    for _, set in ipairs(TIER3) do
        table.insert(names, set[3] .. " (" .. set[1] .. ")")
    end
    return "Quartermasters at Light's Hope Chapel: " .. table.concat(names, ", ") .. "."
end

-- ============================================================
-- Goal data
-- Each goal: id, name, short (optional list name), category, difficulty,
-- timeEstimate (one of FGT.timeScale, which also sets the duration sort),
-- note (optional caveat/flavor), and either:
--   steps    = a flat ordered list of step descriptions, or
--   sections = a class > piece > materials hierarchy (Tier 3 only)
-- ============================================================
FGT.goals = {

    {
        id = "ashbringer",
        completeWith = { item = { 22691, 22709 } },
        icon = "inv_sword_2h_ashbringercorrupt",
        name = "Corrupted Ashbringer",
        short = "Ashbringer",
        itemQuality = 4, -- epic purple links even though the game has no details
        category = "Epic Weapon",
        difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "This is the raid-dropped sword itself. The 'purified' legendary upgrade needs content beyond the original 1-60 game, so under classic rules this goal is really about the Corrupted Ashbringer drop.",
        steps = {
            -- (v2.3.1: "Join a raid team" moved to tips; see stepsFix231 in Core.lua)
            { text = "Reach level 60.", auto = { level = 60 } },
            { text = "Get {att_naxx:attuned to Naxxramas} from Archmage Angela Dosantos at Light's Hope Chapel.", auto = { quest = { 9121, 9122, 9123 } } },
            { text = "Clear the Military Wing of {raid_naxx:Naxxramas} up to the Four Horsemen.", auto = { boss = "Gothik the Harvester" } },
            { text = "Defeat the Four Horsemen.", auto = { boss = "Four Horsemen" } },
            -- the game has no details for 22691 (Wowhead: removed from the game), so the name links from here
            { text = "Loot Corrupted Ashbringer from the Four Horsemen Chest.", auto = { item = { 22691, 22709 } },
              links = { { 22691, "Corrupted Ashbringer" } } },
        },
        tips = {
            "You'll need a 40-player raid that clears Naxxramas every week.",
            "Attunement needs Honored with the {rep_argentdawn:Argent Dawn} and a Righteous Orb: 5 Arcane Crystals and 2 Nexus Crystals at Honored, fewer at Revered.",
            "The chest appears after the Four Horsemen die. Keep clearing weekly until the sword drops.",
            "The Four Horsemen are Highlord Mograine, Thane Korth'azz, Sir Zeliek and Baron Rivendare. Raids use either a 2-tank rotation or a synced 4-group kill.",
            "The drop chance is very low, and the sword is Bind on Pickup, so only one raider can get it per kill.",
            "Equip the sword and visit the Scarlet Monastery Cathedral for a hidden scene with Balnazzar.",
            "Unequip it before visiting Argent Dawn NPCs. Wielding it makes them hostile.",
        },
    },

    {
        id = "frostsaber",
        completeWith = { item = 13086, owned = { "Winterspring Frostsaber" } },
        icon = "ability_mount_pinktiger",
        name = "Winterspring Frostsaber",
        short = "Frostsaber",
        category = "Mount",
        difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "Alliance-only mount, ~900g at Exalted. Non-Night Elves also need Darnassus Exalted to learn Tiger Riding.",
        steps = {
            { text = "Reach level 40 and travel to Winterspring.", auto = { level = 40 } },
            { text = "Start Rivern Frostwind's quests at Frostsaber Rock in Winterspring.", auto = { rep = { faction = 589, standing = 4, value = 1 } } },
            { text = "Turn in 'Frostsaber Provisions' daily until 1500/3000 Neutral.", auto = { rep = { faction = 589, standing = 4, value = 1500 } } },
            { text = "Turn in 'Winterfall Intrusion' daily until Friendly.", auto = { rep = { faction = 589, standing = 5 } } },
            { text = "Reach Honored, then add 'Rampaging Giants' to your dailies.", auto = { rep = { faction = 589, standing = 6 } } },
            { text = "Reach Exalted with the Wintersaber Trainers.", auto = { rep = { faction = 589, standing = 8 } } },
            { text = "Reach Exalted with Darnassus to learn Frostsaber riding (Night Elves skip this).", auto = { rep = { faction = 69, standing = 8 } },
              skipIfRace = "NightElf" }, -- hidden while you play a Night Elf (FGT.PieceSkipped)
            { text = "Buy the Reins of the Winterspring Frostsaber from Rivern Frostwind (about 900 gold).", auto = { item = 13086, owned = { "Winterspring Frostsaber" } } },
        },
        tips = {
            "Level 60 makes the trip and the daily kills much safer.",
            "'Frostsaber Provisions' takes 5 Shardtooth Meat (Shardtooth bears) and 5 Chillwind Meat (Chillwind chimaeras), both in Winterspring.",
            "'Winterfall Intrusion' asks for 5 Winterfall Shaman and 5 Winterfall Ursa at Winterfall Village; the 'Rampaging Giants' are near Frostsaber Rock.",
            "Exalted is the long part: expect several weeks even doing every turn-in daily.",
        },
    },

    {
        id = "atiesh",
        completeWith = { item = { 22589, 22630, 22631, 22632 }, quest = { 9257, 9269, 9270, 9271 } },
        icon = "inv_staff_medivh",
        name = "Atiesh, Greatstaff of the Guardian",
        short = "Atiesh",
        category = "Legendary Weapon",
        difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "Only for Druid, Mage, Priest, or Warlock. Requires access to Naxxramas, Ahn'Qiraj 40, and Stratholme.",
        steps = {
            { text = "Raid {raid_naxx:Naxxramas} and {raid_aq40:Ahn'Qiraj} on a Druid, Mage, Priest or Warlock.", auto = { level = 60 } },
            { text = "Collect 40 Splinters of Atiesh from Naxxramas bosses.", auto = { item = 22726, count = 40 } },
            { text = "Combine the 40 splinters into the Frame of Atiesh.", auto = { item = 22727, quest = 9250 } },
            { text = "Bring the Frame of Atiesh to Anachronos at the Caverns of Time in Tanaris.", auto = { quest = 9250 } },
            { text = "Loot the Staff Head of Atiesh from Kel'Thuzad in Naxxramas.", auto = { item = 22733 } },
            { text = "Loot the Base of Atiesh from C'Thun in Ahn'Qiraj.", auto = { item = 22734 } },
            { text = "Return both pieces to Anachronos.", auto = { quest = 9251 } },
            "Complete your class's purification quest from Anachronos.",
            "Defeat the guardian the staff summons on Festival Lane in Stratholme.",
            { text = "Receive Atiesh, Greatstaff of the Guardian from Anachronos.", auto = { item = { 22589, 22630, 22631, 22632 }, quest = { 9257, 9269, 9270, 9271 } } },
        },
        tips = {
            "Each class (Druid, Mage, Priest, Warlock) gets its own short purification questline and its own version of the staff.",
            "Atiesh gives a raid-wide aura, so guilds often hand the splinters to a support player.",
        },
    },

    {
        id = "rhokdelar",
        icon = "inv_weapon_bow_01",
        name = "Rhok'delar, Longbow of the Ancient Keepers",
        short = "Rhok'delar",
        category = "Epic Weapon",
        difficulty = "Hard",
        timeEstimate = "2-4 Weeks",
        note = "Hunter-only epic bow. It's built from the Ancient Rune Etched Stave you earn in the Lok'delar chain, so do that goal first. Since patch 1.8 one Hunter ends up with both weapons.",
        steps = {
            { text = "Get the Ancient Rune Etched Stave from 'Stave of the Ancients' (the {lokdelar:Lok'delar} goal).", auto = { item = 18707, quest = 7636 } },
            { text = "Pick up 'A Proper String' from Stoma the Ancient in Felwood.", auto = { questTaken = 7635 } },
            { text = "Loot the Mature Black Dragon Sinew from {raid_ony:Onyxia}.", auto = { item = 18705, quest = 7635 } },
            { text = "Turn in the sinew to Vartrus for the Enchanted Black Dragon Sinew.", auto = { item = 18724, quest = 7635 } },
            { text = "Combine the stave and the Enchanted Black Dragon Sinew into Rhok'delar.", auto = { item = { 18713, 20488 } } },
        },
        tips = {
            "Optional: kill Azuregos in Azshara for a Mature Blue Dragon Sinew, then turn in 'Ancient Sinew Wrapped Lamina' for the matching epic quiver.",
        },
    },

    {
        id = "lokdelar",
        completeWith = { item = { 18715, 20487 } },
        icon = "inv_staff_21",
        name = "Lok'delar, Stave of the Ancient Keepers",
        short = "Lok'delar",
        category = "Epic Weapon",
        difficulty = "Hard",
        timeEstimate = "2-4 Weeks",
        note = "Hunter-only epic staff, the first half of the Ancient Keepers chain. The same turn-in also gives the Ancient Rune Etched Stave used to make Rhok'delar.",
        steps = {
            { text = "Loot the Ancient Petrified Leaf from the Cache of the Firelord in {raid_mc:Molten Core}.", auto = { item = 18703, quest = 7632 } },
            { text = "Bring the leaf to Vartrus the Ancient in Felwood and pick up 'Stave of the Ancients'.", auto = { quest = 7632, questTaken = 7636 } },
            { text = "Solo Artorius the Doombringer in Winterspring.", auto = { owned = { "Artorius's Head" }, quest = 7636 } },
            { text = "Solo Klinfran the Crazed in Burning Steppes.", auto = { owned = { "Klinfran's Head" }, quest = 7636 } },
            { text = "Solo Solenor the Slayer in Silithus.", auto = { owned = { "Solenor's Head" }, quest = 7636 } },
            { text = "Solo Simone the Seductress in Un'Goro Crater.", auto = { owned = { "Simone's Head" }, quest = 7636 } },
            { text = "Turn in the four demon heads to Vartrus for Lok'delar and the Ancient Rune Etched Stave.", auto = { item = { 18715, 20487 }, quest = 7636 },
              links = { { 18707, "Ancient Rune Etched Stave" } } }, -- other items the step names (shown as item links)
        },
        tips = {
            "Fight each demon alone. If another player helps, the fight is forfeit.",
            "Keep the Ancient Rune Etched Stave: it becomes Rhok'delar.",
        },
    },

    {
        id = "thunderfury",
        completeWith = { item = 19019, quest = 7787 },
        icon = "inv_sword_39",
        name = "Thunderfury, Blessed Blade of the Windseeker",
        short = "Thunderfury",
        category = "Legendary Weapon",
        difficulty = "Very Hard",
        timeEstimate = "3+ Months",
        note = "The classic legendary. Both bindings are roughly a 3% drop each, so this is usually a long farm even with consistent weekly clears.",
        steps = {
            { text = "Raid {raid_mc:Molten Core} on a weekly reset schedule.", auto = { level = 60 } },
            { text = "Loot the Bindings of the Windseeker (left) from Baron Geddon in Molten Core.", auto = { item = 18563, quest = 7785 } },
            { text = "Loot the Bindings of the Windseeker (right) from Garr in Molten Core.", auto = { item = 18564, quest = 7785 } },
            { text = "Start 'Examine the Vessel' with Highlord Demitrian in Silithus.", auto = { quest = 7785 } },
            { text = "Gather 10 Elementium Bars.", auto = { item = 17771, count = 10 } },
            { text = "Gather 100 Arcanite Bars.", auto = { item = 12360, count = 100 } },
            { text = "Gather 10 Fiery Cores (Molten Core).", auto = { item = 17010, count = 10 } },
            { text = "Gather 30 Elemental Flux.", auto = { item = 18567, count = 30 } },
            { text = "Loot the Essence of the Firelord from Ragnaros in Molten Core.", auto = { item = { 19017, 18566 }, quest = 7786 } },
            { text = "Turn in the bindings, the Essence and the materials to Demitrian ('Thunderaan the Windseeker').", auto = { quest = 7786 } },
            { text = "Defeat Prince Thunderaan in Silithus.", auto = { quest = 7786 } },
            { text = "Turn in 'Rise, Thunderfury!' to receive Thunderfury.", auto = { item = 19019, quest = 7787 } },
        },
        tips = {
            "Each Binding of the Windseeker is a rare drop, roughly 3%, so plan on many weekly Molten Core clears.",
            "You need one binding in hand to start 'Examine the Vessel'.",
        },
    },

    {
        id = "tier3",
        itemQuality = 4, -- piece names' color when the game doesn't know the item
        group = true, -- pick class sets individually in the Library
        icon = "inv_helmet_58",
        name = "Tier 3 Set Appearances",
        short = "Tier 3 Sets",
        category = "Item Set",
        difficulty = "Extreme",
        timeEstimate = "Years",
        note = "The Naxxramas sets. Bosses drop Desecrated tokens, and your class's quartermaster at Light's Hope Chapel (Eastern Plaguelands) turns each token, Wartorn scraps and crafting materials into a piece. Pick the classes you want in the Library, then click a piece to see its materials.",
        sections = BuildTier3Sections(),
        tips = {
            "You need to be {att_naxx:attuned to Naxxramas} (Honored with the {rep_argentdawn:Argent Dawn}, plus a Righteous Orb) on each character that raids it.",
            Tier3QuartermasterTip(),
            "Wartorn scraps drop from trash all over Naxxramas. Each armor type has its own scrap (cloth, leather, chain or plate).",
            "A piece ticks itself when you own it, along with its materials. Tick materials by hand as you collect them.",
        },
    },

    {
        id = "benediction",
        completeWith = { item = { 18608, 18609 } },
        icon = "inv_staff_30",
        name = "Benediction / Anathema",
        short = "Benediction",
        category = "Epic Weapon",
        difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "Priest-only. One staff with two forms: Benediction (Holy) and Anathema (Shadow).",
        steps = {
            { text = "Loot The Eye of Divinity from Majordomo Executus in {raid_mc:Molten Core}.", auto = { item = 18646, quest = 7622 } },
            { text = "Start 'The Balance of Light and Shadow' with Eris Havenfire near Stratholme.", auto = { questTaken = 7622 } },
            { text = "Save 50 peasants (fewer than 15 deaths) to earn the Splinter of Nordrassil.", auto = { item = 18659, quest = 7622 } },
            { text = "Loot The Eye of Shadow from demons in southern Winterspring, or buy one.", auto = { item = 18665 } },
            { text = "Combine the Splinter of Nordrassil, the Eye of Shadow and the Eye of Divinity into Benediction.", auto = { item = { 18608, 18609 } } },
        },
        tips = {
            "The peasant event runs 5+ minutes. If it fails, Eris resets after about 15 minutes.",
            "Right-click the finished staff to swap between Benediction (Holy) and Anathema (Shadow). Swapping has a 30-minute cooldown.",
        },
    },

    {
        id = "epicmounts",
        itemQuality = 4, -- epic mounts: purple names even before the game loads them
        group = true, -- pick races individually in the Library
        icon = "ability_mount_mountainram",
        name = "Epic Racial Mounts",
        category = "Mount Collection",
        difficulty = "Hard",
        timeEstimate = "Ongoing",
        note = "The epic mount of each race in your faction: a level 60, swift riding trained, and gold. Any race can buy one at Exalted with its home city. Pick the mounts you want.",
        tips = {
            "Your own race's mount needs no reputation. Another race's mount needs Exalted with that race's home city (Darkspear Trolls for the raptor, Ironforge for the ram).",
            "Honored with the vendor's city gives a small discount.",
            "Collecting them all on one character means Exalted with every city in your faction; the {rep_ambassador:Ambassador} goal covers that.",
            "Each vendor sells a few colors of the same mount for the same price, and any of them counts.",
        },
        sections = {
            {
                icon = "ability_mount_ridinghorse",
                name = "Human - Swift Steed",
                pieces = BuildMountTasks("Human", "Swift Steed", "Katie Hunter", "Eastvale Logging Camp, Elwynn Forest", "Human", { "Swift .*Steed", "Swift Palomino" }, nil, { "Alliance", 72, "Stormwind", "Humans" }, { { 18777, "Swift Brown Steed" }, { 18776, "Swift Palomino" }, { 18778, "Swift White Steed" } }),
            },
            {
                icon = "ability_mount_mountainram",
                name = "Dwarf - Swift Ram",
                pieces = BuildMountTasks("Dwarf", "Swift Ram", "Veron Amberstill", "Amberstill Ranch, Dun Morogh", "Dwarf", { "Swift .*Ram" }, nil, { "Alliance", 47, "Ironforge", "Dwarves" }, { { 18786, "Swift Brown Ram" }, { 18787, "Swift Gray Ram" }, { 18785, "Swift White Ram" } }),
            },
            {
                icon = "ability_mount_whitetiger",
                name = "Night Elf - Swift Saber",
                pieces = BuildMountTasks("Night Elf", "Swift Saber", "Lelanai", "Cenarion Enclave, Darnassus", "NightElf", { "Swift Frostsaber", "Swift Mistsaber", "Swift Stormsaber" }, nil, { "Alliance", 69, "Darnassus", "Night Elves" }, { { 18766, "Reins of the Swift Frostsaber" }, { 18767, "Reins of the Swift Mistsaber" }, { 18902, "Reins of the Swift Stormsaber" } }),
            },
            {
                icon = "ability_mount_mechastrider",
                name = "Gnome - Swift Mechanostrider",
                pieces = BuildMountTasks("Gnome", "Swift Mechanostrider", "Milli Featherwhistle", "Kharanos, Dun Morogh", "Gnome", { "Swift .*Mechanostrider" }, nil, { "Alliance", 54, "Gnomeregan Exiles", "Gnomes" }, { { 18772, "Swift Green Mechanostrider" }, { 18773, "Swift White Mechanostrider" }, { 18774, "Swift Yellow Mechanostrider" } }),
            },
            {
                icon = "ability_mount_blackdirewolf",
                name = "Orc - Swift Timber Wolf",
                pieces = BuildMountTasks("Orc", "Swift Wolf", "Ogunaro Wolfrunner", "Valley of Honor, Orgrimmar", "Orc", { "Swift .*Wolf" }, nil, { "Horde", 76, "Orgrimmar", "Orcs" }, { { 18797, "Horn of the Swift Timber Wolf" }, { 18796, "Horn of the Swift Brown Wolf" }, { 18798, "Horn of the Swift Gray Wolf" } }),
            },
            {
                icon = "ability_mount_kodo_03",
                name = "Tauren - Great Kodo",
                pieces = BuildMountTasks("Tauren", "Great Kodo", "Harb Clawhoof", "Bloodhoof Village, Mulgore", "Tauren", { "Great .*Kodo" }, nil, { "Horde", 81, "Thunder Bluff", "Tauren" }, { { 18794, "Great Brown Kodo" }, { 18795, "Great Gray Kodo" }, { 18793, "Great White Kodo" } }),
            },
            {
                icon = "ability_mount_undeadhorse",
                name = "Undead - Skeletal Warhorse",
                pieces = BuildMountTasks("Undead", "Skeletal Warhorse", "Zachariah Post", "Brill, Tirisfal Glades", "Scourge", { "Skeletal Warhorse" }, nil, { "Horde", 68, "Undercity", "Undead" }, { { 18791, "Purple Skeletal Warhorse" }, { 13334, "Green Skeletal Warhorse" } }),
            },
            {
                icon = "ability_mount_raptor",
                name = "Troll - Swift Raptor",
                pieces = BuildMountTasks("Troll", "Swift Raptor", "Zjolnir", "Sen'jin Village, Durotar", "Troll", { "Swift .*Raptor" }, nil, { "Horde", 530, "the Darkspear Trolls", "Trolls" }, { { 18788, "Swift Blue Raptor" }, { 18789, "Swift Olive Raptor" }, { 18790, "Swift Orange Raptor" } }),
            },
            -- New in Warcraft Forever, so it's last (parts are saved by
            -- position) and only listed on the Forever client. Wowhead
            -- Forever, 2026-10-06: Swift Empyrean / Umber / Stormy
            -- Galestrider, 200g each from Genn Fairweather on Zephras Isle,
            -- level 60, Galestrider Riding (part of Journeyman Riding, 1,000g).
            -- Race "Skyborne" checked in game (race ID 95).
            {
                icon = "inv_craneskyborneswiftmount_c60_blue",
                name = "Skyborne - Swift Galestrider",
                forever = "new",
                -- 1,200 gold = Journeyman Riding (1,000) + the mount (200).
                -- Genn Fairweather is also the riding trainer there.
                pieces = BuildMountTasks("Skyborne", "Swift Galestrider", "Genn Fairweather", "Zephras Isle",
                    "Skyborne", { "Swift .*Galestrider" }, { "1,200", 1200 }, nil, { { 269671, "Swift Empyrean Galestrider" }, { 274933, "Swift Umber Galestrider" }, { 269678, "Swift Stormy Galestrider" } }),
            },
        },
    },

    {
        id = "sulfuras",
        completeWith = { item = 17182 },
        icon = "inv_hammer_unique_sulfuras",
        name = "Sulfuras, Hand of Ragnaros",
        short = "Sulfuras",
        category = "Legendary Weapon",
        difficulty = "Very Hard",
        timeEstimate = "3+ Months",
        note = "Two-handed legendary mace. You need the Eye of Sulfuras from Ragnaros and a Sulfuron Hammer crafted by a 300 Blacksmith (you or someone you trust). Combining them is instant, with no quest turn-in.",
        steps = {
            { text = "Raid {raid_mc:Molten Core} on a weekly reset schedule.", auto = { level = 60 } },
            { text = "Loot the Eye of Sulfuras from Ragnaros in Molten Core.", auto = { item = 17204 } },
            { text = "Get the Plans: Sulfuron Hammer from Lokhtos Darkbargainer in Blackrock Depths ('A Binding Contract').", auto = { item = 18592, quest = 7604 } },
            { text = "Collect 8 Sulfuron Ingots from Golemagg the Incinerator in Molten Core.", auto = { item = 17203, count = 8 } },
            { text = "Smelt 20 Dark Iron Bars at the Black Forge in Blackrock Depths.", auto = { item = 11371, count = 20 } },
            { text = "Gather 50 Arcanite Bars.", auto = { item = 12360, count = 50 } },
            { text = "Gather 25 Essence of Fire.", auto = { item = 7078, count = 25 } },
            { text = "Gather 10 Blood of the Mountain (rare from Dark Iron deposits).", auto = { item = 11382, count = 10 } },
            { text = "Gather 10 Lava Cores (Molten Core trash, BoE).", auto = { item = 17011, count = 10 } },
            { text = "Gather 10 Fiery Cores (Molten Core trash, BoE).", auto = { item = 17010, count = 10 } },
            { text = "Reach 300 Blacksmithing, or find a Blacksmith to craft it.", auto = { skill = { name = "Blacksmithing", rank = 300 } } },
            { text = "Craft the Sulfuron Hammer.", auto = { item = 17193 } },
            { text = "Combine the Sulfuron Hammer and the Eye of Sulfuras into Sulfuras.", auto = { item = 17182 } },
        },
        tips = {
            "The Eye of Sulfuras is a rare drop from Ragnaros, roughly 3%.",
            "'A Binding Contract' costs one Sulfuron Ingot and needs no Thorium Brotherhood reputation. Lokhtos is in the Grim Guzzler.",
        },
    },

    {
        id = "allclasses",
        forever = "confirmed", -- leveling 1-60 works the same in Forever
        group = true, -- pick classes individually in the Library
        autoLevels = true,
        icon = { "achievement_level_60", "inv_crown_01" },
        name = "Level Classes to 60",
        category = "Milestone",
        difficulty = "Very Hard",
        timeEstimate = "Ongoing",
        note = "Tracked automatically. Every character you log into is remembered, and each class shows its highest character's level, filling as you earn XP. A class completes when any character of it hits 60. Characters you haven't logged into since installing show as not seen yet.",
        steps = {
            { text = "Warrior",  icon = "ClassIcon_Warrior", autoClass = "WARRIOR" },
            { text = "Paladin",  icon = "ClassIcon_Paladin", autoClass = "PALADIN" },
            { text = "Hunter",   icon = "ClassIcon_Hunter",  autoClass = "HUNTER" },
            { text = "Rogue",    icon = "ClassIcon_Rogue",   autoClass = "ROGUE" },
            { text = "Priest",   icon = "ClassIcon_Priest",  autoClass = "PRIEST" },
            { text = "Shaman",   icon = "ClassIcon_Shaman",  autoClass = "SHAMAN" },
            { text = "Mage",     icon = "ClassIcon_Mage",    autoClass = "MAGE" },
            { text = "Warlock",  icon = "ClassIcon_Warlock", autoClass = "WARLOCK" },
            { text = "Druid",    icon = "ClassIcon_Druid",   autoClass = "DRUID" },
        },
    },
}
