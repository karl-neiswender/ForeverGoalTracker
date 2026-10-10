local ADDON, FGT = ...

-- ============================================================
-- Goal Library
-- ============================================================
-- Extra goals you can add from the Library tab. They join the 11
-- goals in Data.lua (which start out active) in one shared catalog;
-- only goals you've added show on the tracker and count toward the
-- overall bar.
--
-- Rule cheat-sheet (any one condition met on any character counts):
--   rep = { faction = id, standing = 5..8 }   5 Friendly .. 8 Exalted
--   item = id | { ids }, count = n            summed across characters
--   quest = id | { ids }                      turned in on any character
--   questTaken = id | { ids }                 picked up (in the log) or turned in
--   skill = { name = "Fishing", rank = 300 }
--   boss = "Ragnaros"                         a kill seen while the addon runs
--   owned / ownedPattern = names              bags, gear or mount collection
--   money = copper, level = n
--   guild = true                              any character has been in a guild
--   friends = n                               friends on a character's friends list
--   stat = { id = n, value = n, what = text } a Statistics window counter (Forever; goal needs = "stats")

FGT.categoryColors["Social"]     = { 1.00, 0.56, 0.69 } -- rose #ff8fb0
FGT.categoryColors["Reputation"] = { 0.40, 0.85, 0.55 }
FGT.categoryColors["Raid"]       = { 0.95, 0.40, 0.30 }
FGT.categoryColors["Profession"] = { 0.85, 0.70, 0.45 }
FGT.categoryColors["PvP"]        = { 0.55, 0.65, 1.00 }
FGT.categoryColors["Attunement"] = { 0.45, 0.82, 0.86 }

local STANDINGS = { [5] = "Friendly", [6] = "Honored", [7] = "Revered", [8] = "Exalted" }

-- Friendly -> Exalted, each standing auto-ticked from your reputation.
-- How to earn the reputation goes in the goal's tips.
local function RepSteps(factionId)
    local steps = {}
    for st = 5, 8 do
        table.insert(steps, { text = "Reach " .. STANDINGS[st] .. ".", auto = { rep = { faction = factionId, standing = st } } })
    end
    return steps
end

-- One step per boss, each auto-ticked when the kill is seen.
local function BossSteps(prefix, bosses)
    local steps = {}
    for _, line in ipairs(prefix) do table.insert(steps, line) end
    for _, b in ipairs(bosses) do
        -- a boss can be a list of name variants; the first is shown
        local label = type(b) == "table" and b[1] or b
        table.insert(steps, { text = "Defeat " .. label .. ".", auto = { boss = b } })
    end
    return steps
end

local SKILL_ICONS = {
    ["Alchemy"] = "trade_alchemy",
    ["Blacksmithing"] = "trade_blacksmithing",
    ["Enchanting"] = "trade_engraving",
    ["Engineering"] = "trade_engineering",
    ["Herbalism"] = "trade_herbalism",
    ["Leatherworking"] = "trade_leatherworking",
    ["Mining"] = "trade_mining",
    ["Skinning"] = "inv_misc_pelt_wolf_01",
    ["Tailoring"] = "trade_tailoring",
    ["Fishing"] = "trade_fishing",
    ["Cooking"] = "inv_misc_food_15",
    ["First Aid"] = "spell_holy_sealofsacrifice",
}

local function SkillStep(name, rank)
    return { text = name .. " " .. rank .. ".", icon = SKILL_ICONS[name],
             auto = { skill = { name = name, rank = rank } } }
end

local library = {

    -- ---------------- Reputation ----------------
    {
        id = "rep_timbermaw", library = true,
        icon = { "achievement_reputation_timbermaw", "inv_misc_monsterclaw_04" },
        name = "Exalted: Timbermaw Hold",
        short = "Timbermaw Hold",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "2-4 Weeks",
        note = "The furbolgs of Felwood and Winterspring. Rewards include safe passage through the Timbermaw tunnels and leatherworking patterns.",
        steps = RepSteps(576),
        tips = {
            "Kill Deadwood furbolgs in Felwood and Winterfall furbolgs in Winterspring for reputation.",
            "Turn in {item:21377:Deadwood Headdress Feathers} and {item:21383:Winterfall Spirit Beads} in batches of 5 at Timbermaw Hold.",
        },
    },
    {
        id = "rep_thorium", library = true,
        icon = { "achievement_reputation_thoriumbrotherhood", "trade_blacksmithing" },
        name = "Exalted: Thorium Brotherhood",
        short = "Thorium Brotherhood",
        category = "Reputation", difficulty = "Very Hard",
        timeEstimate = "3+ Months",
        note = "Lokhtos Darkbargainer's epic crafting recipes unlock as you climb, including fire resistance gear.",
        steps = RepSteps(59),
        tips = {
            "Turn in {item:11370:Dark Iron Ore} and {item:18942:Fiery Flux} to Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths) early on.",
            "From Honored on, turn in Molten Core materials such as {item:17011:Lava Cores} and {item:17010:Fiery Cores}.",
        },
    },
    {
        id = "rep_argentdawn", library = true,
        icon = { "achievement_reputation_argentcrusader", "spell_holy_holybolt" },
        name = "Exalted: Argent Dawn",
        short = "Argent Dawn",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "Honored opens the Naxxramas attunement; Exalted unlocks the best Argent Dawn shoulder enchants.",
        steps = RepSteps(529),
        tips = {
            "Wear an {item:12846:Argent Dawn Commission} while killing undead in the Plaguelands, Stratholme and Scholomance.",
            "Turn in Scourgestones at Light's Hope Chapel or Chillwind Camp.",
        },
    },
    {
        id = "rep_cenarion", library = true,
        icon = { "achievement_reputation_ogre", "inv_misc_herb_01" },
        name = "Exalted: Cenarion Circle",
        short = "Cenarion Circle",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "The druids of Silithus. Ruins of Ahn'Qiraj kills and Twilight cultist turn-ins carry most of the grind.",
        steps = RepSteps(609),
        tips = {
            "Do the Silithus quests at Cenarion Hold.",
            "Turn in {item:20404:Encrypted Twilight Texts} and run Ruins of Ahn'Qiraj for steady reputation.",
        },
    },
    {
        id = "rep_zandalar", library = true,
        icon = { "achievement_reputation_zandalar", "inv_misc_coin_01" },
        name = "Exalted: Zandalar Tribe",
        short = "Zandalar Tribe",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "Earned in Zul'Gurub. Unlocks the class-specific Zandalar armor sets and head/leg enchants.",
        steps = RepSteps(270),
        tips = {
            "Clear Zul'Gurub; every kill in the raid gives Zandalar reputation.",
            "Turn in sets of ZG coins and bijous at Yojamba Isle.",
        },
    },
    {
        id = "rep_hydraxian", library = true,
        icon = { "spell_frost_summonwaterelemental", "inv_misc_gem_pearl_04" },
        name = "Exalted: Hydraxian Waterlords",
        short = "Hydraxians",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "Needed to douse Molten Core's runes without Aqual Quintessence; Revered gives the Eternal Quintessence.",
        steps = RepSteps(749),
        tips = {
            "Speak with Duke Hydraxis on his island east of Azshara and do his quest chain.",
            "Kill Molten Core trash and bosses; each kill adds reputation.",
        },
    },
    {
        id = "rep_nozdormu", library = true,
        icon = { "achievement_reputation_nozdormu", "inv_misc_head_dragon_bronze", "inv_misc_head_dragon_01" },
        name = "Exalted: Brood of Nozdormu",
        short = "Brood of Nozdormu",
        category = "Reputation", difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "Starts at Hated. The rings from Anachronos upgrade as you climb, and the grind is famously long.",
        steps = RepSteps(910),
        tips = {
            "Complete 'The Charge of the Dragonflights' line to obtain your Signet Ring.",
            "Clear Temple of Ahn'Qiraj; kills and {item:21230:Ancient Qiraji Artifacts} raise reputation.",
        },
    },
    {
        id = "rep_ambassador_ally", library = true, faction = "Alliance",
        icon = { "spell_arcane_teleportstormwind", "inv_bannerpvp_02" },
        name = "Ambassador: Alliance Capitals",
        short = "Alliance Ambassador",
        category = "Reputation", difficulty = "Very Hard",
        timeEstimate = "3+ Months",
        note = "Exalted with all four Alliance capitals. Your own race's city is the easy one; the rest take turn-ins.",
        steps = {
            { text = "Reach Exalted with Stormwind.", icon = "spell_arcane_teleportstormwind", auto = { rep = { faction = 72, standing = 8 }, forFaction = "Alliance" } },
            { text = "Reach Exalted with Ironforge.", icon = "spell_arcane_teleportironforge", auto = { rep = { faction = 47, standing = 8 }, forFaction = "Alliance" } },
            { text = "Reach Exalted with Darnassus.", icon = "spell_arcane_teleportdarnassus", auto = { rep = { faction = 69, standing = 8 }, forFaction = "Alliance" } },
            { text = "Reach Exalted with Gnomeregan Exiles.", icon = "inv_misc_gear_01", auto = { rep = { faction = 54, standing = 8 }, forFaction = "Alliance" } },
        },
        tips = {
            "Each city has repeatable cloth turn-ins at its cloth quartermaster, the fastest route for most players.",
        },
    },
    {
        id = "rep_ambassador_horde", library = true, faction = "Horde",
        icon = { "spell_arcane_teleportorgrimmar", "inv_bannerpvp_01" },
        name = "Ambassador: Horde Capitals",
        short = "Horde Ambassador",
        category = "Reputation", difficulty = "Very Hard",
        timeEstimate = "3+ Months",
        note = "Exalted with all four Horde capitals. Your own race's city is the easy one; the rest take turn-ins.",
        steps = {
            { text = "Reach Exalted with Orgrimmar.", icon = "spell_arcane_teleportorgrimmar", auto = { rep = { faction = 76, standing = 8 }, forFaction = "Horde" } },
            { text = "Reach Exalted with Thunder Bluff.", icon = "spell_arcane_teleportthunderbluff", auto = { rep = { faction = 81, standing = 8 }, forFaction = "Horde" } },
            { text = "Reach Exalted with Undercity.", icon = "spell_arcane_teleportundercity", auto = { rep = { faction = 68, standing = 8 }, forFaction = "Horde" } },
            { text = "Reach Exalted with the Darkspear Trolls.", icon = "inv_misc_head_troll_01", auto = { rep = { faction = 530, standing = 8 }, forFaction = "Horde" } },
        },
        tips = {
            "Each city has repeatable cloth turn-ins at its cloth quartermaster, the fastest route for most players.",
        },
    },

    -- ---------------- Mounts ----------------
    {
        id = "mount_deathcharger", library = true,
        icon = "ability_mount_undeadhorse",
        name = "Deathcharger's Reins",
        short = "Deathcharger",
        category = "Mount", difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "Baron Rivendare's own steed. A tiny drop chance in the undead side of Stratholme.",
        steps = { -- (v2.3.1: the "get a group" step moved to tips; see stepsFix231 in Core.lua)
            { text = "Reach level 60.", auto = { level = 60 } },
            { text = "Defeat Baron Rivendare in {key_strat:Stratholme}.", auto = { boss = "Baron Rivendare" } },
            { text = "Loot Deathcharger's Reins from Baron Rivendare.", auto = { item = 13335, owned = { "Deathcharger" } } },
        },
        completeWith = { item = 13335, owned = { "Deathcharger" } },
        tips = {
            "Baron Rivendare is on Stratholme's undead side, through the service entrance, which the {key_strat:Key to the City} opens.",
            "Run it with a group, or solo once you're well geared. The drop chance is tiny, so expect many runs.",
        },
    },
    {
        id = "mount_raptor", library = true,
        icon = "ability_mount_raptor",
        name = "Swift Razzashi Raptor",
        short = "Razzashi Raptor",
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "1-2 Months",
        note = "Rare drop from Bloodlord Mandokir in Zul'Gurub.",
        steps = { -- (v2.3.1: "Join a raid" moved to tips; see stepsFix231 in Core.lua)
            { text = "Defeat Bloodlord Mandokir in {raid_zg:Zul'Gurub}.", auto = { boss = "Bloodlord Mandokir" } },
            { text = "Loot the Swift Razzashi Raptor from Bloodlord Mandokir.", auto = { item = 19872, owned = { "Swift Razzashi Raptor" } } },
        },
        completeWith = { item = 19872, owned = { "Swift Razzashi Raptor" } },
        tips = {
            "Zul'Gurub is a 20-player raid, so you'll need a raid group.",
        },
    },
    {
        id = "mount_tiger", library = true,
        icon = "ability_mount_jungletiger",
        name = "Swift Zulian Tiger",
        short = "Zulian Tiger",
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "1-2 Months",
        note = "Rare drop from High Priest Thekal in Zul'Gurub.",
        steps = { -- (v2.3.1: "Join a raid" moved to tips; see stepsFix231 in Core.lua)
            { text = "Defeat High Priest Thekal in {raid_zg:Zul'Gurub}.", auto = { boss = "High Priest Thekal" } },
            { text = "Loot the Swift Zulian Tiger from High Priest Thekal.", auto = { item = 19902, owned = { "Swift Zulian Tiger" } } },
        },
        completeWith = { item = 19902, owned = { "Swift Zulian Tiger" } },
        tips = {
            "Zul'Gurub is a 20-player raid, so you'll need a raid group.",
        },
    },
    {
        id = "mount_qiraji", library = true,
        icon = "inv_misc_qirajicrystal_05",
        name = "Black Qiraji Resonating Crystal",
        short = "Black Qiraji",
        category = "Mount", difficulty = "Extreme",
        timeEstimate = "Varies",
        note = "The black battle tank, originally awarded only to Scarab Lords who rang the gong at the opening of Ahn'Qiraj. Whether Forever offers it again depends on how its gate event runs.",
        steps = {
            "Complete the Scepter of the Shifting Sands quest chain.",
            "Ring the Scarab Gong in Silithus to open Ahn'Qiraj.",
            { text = "Own the Black Qiraji Resonating Crystal.", auto = { item = 21176, owned = { "Black Qiraji" } } },
        },
        completeWith = { item = 21176, owned = { "Black Qiraji" } },
        tips = {
            "The gong can only be rung once your realm's Ahn'Qiraj war effort is finished. Forever may run its own version of the event.",
        },
    },
    {
        id = "mount_dreadsteed", library = true,
        icon = "ability_mount_dreadsteed",
        name = "Dreadsteed (Warlock Epic Mount)",
        short = "Dreadsteed",
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "2-4 Weeks",
        note = "The Warlock's epic mount, earned through a level 60 quest chain that ends with a summoning ritual in Dire Maul. Quest IDs checked on Wowhead.",
        steps = {
            { text = "Complete 'Mor'zul Bloodbringer' from a demon trainer in a capital city.", auto = { quest = 7562 } },
            { text = "Complete 'Rage of Blood'.", auto = { quest = 7563 } },
            { text = "Complete 'Wildeyes'.", auto = { quest = 7564 } },
            { text = "Complete 'Kroshius' Infernal Core'.", auto = { quest = 7603 } },
            { text = "Complete 'Imp Delivery'.", auto = { quest = 7629 } },
            { text = "Complete 'Arcanite'.", auto = { quest = 7630 } },
            { text = "Defeat the Xorothian Dreadsteed in Dire Maul ('Dreadsteed of Xoroth').", auto = { quest = 7631 } },
        },
        completeWith = { quest = 7631 },
        tips = {
            "Warlock only, and the chain needs level 60.",
            "The chain starts with a demon trainer: Spackle Thornberry (Stormwind) or Jubahl Corpseseeker (Ironforge) for the Alliance, Martha Strain (Undercity) or Kurgul (Orgrimmar) for the Horde.",
            "The Dire Maul ritual is a group fight, so bring friends.",
        },
    },
    {
        id = "mount_charger", library = true,
        icon = "ability_mount_charger",
        name = "Charger (Paladin Epic Mount)",
        short = "Charger",
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "2-4 Weeks",
        note = "The Paladin's epic mount, earned through Lord Grayson Shadowbreaker's level 60 quest chain that ends in Scholomance. Quest IDs checked on Wowhead.",
        steps = {
            { text = "Complete 'Lord Grayson Shadowbreaker' from Duthorian Rall in Stormwind City.", auto = { quest = 7638 } },
            { text = "Complete 'Emphasis on Sacrifice'.", auto = { quest = 7637 } },
            { text = "Complete 'To Show Due Judgment'.", auto = { quest = 7639 } },
            { text = "Complete 'Exorcising Terrordale'.", auto = { quest = 7640 } },
            { text = "Complete 'The Work of Grimand Elmore'.", auto = { quest = 7641 } },
            { text = "Complete 'Collection of Goods'.", auto = { quest = 7642 } },
            { text = "Complete 'Ancient Equine Spirit'.", auto = { quest = 7643 } },
            { text = "Complete 'Blessed Arcanite Barding'.", auto = { quest = 7644 } },
            { text = "Complete 'Manna-Enriched Horse Feed'.", auto = { quest = 7645 } },
            { text = "Complete 'The Divination Scryer'.", auto = { quest = 7646 } },
            { text = "Complete 'Judgment and Redemption' in {key_scholo:Scholomance} to earn the Charger.", auto = { quest = 7647 } },
        },
        completeWith = { quest = 7647 },
        tips = {
            "Paladin only, and the chain needs level 60.",
            "Several steps ask for materials and gold, so read each quest's requirements before heading out.",
        },
    },

    -- ---------------- Weapons ----------------
    {
        id = "quelserrar", library = true,
        icon = "inv_sword_01",
        name = "Quel'Serrar",
        category = "Epic Weapon", difficulty = "Very Hard",
        timeEstimate = "Varies",
        note = "Tanking sword (Warrior and Paladin) forged in Onyxia's breath.",
        steps = {
            { text = "Loot Nostro's Compendium of Dragon Slaying in Dire Maul (rare).", auto = { item = 18401, quest = { 7508, 7509 } } },
            { text = "Get the Unfired Ancient Blade from 'The Forging of Quel'Serrar' in the Dire Maul library.",
              auto = { quest = { 7508, 7509 }, questTaken = { 7508, 7509 }, item = 18489 } },
            { text = "Heat the blade in {raid_ony:Onyxia's} fire breath.", auto = { item = { 18488, 18492, 18348 } } },
            { text = "Drive the Heated Ancient Blade into Onyxia's corpse before it cools.", auto = { item = { 18492, 18348 } },
              links = { { 18488, "Heated Ancient Blade" } } },
            { text = "Return the Treated Ancient Blade to receive Quel'Serrar.", auto = { item = 18348 },
              links = { { 18492, "Treated Ancient Blade" } } },
        },
        completeWith = { item = 18348 },
    },

    -- ---------------- Raids ----------------
    {
        id = "raid_mc", library = true, instance = { 409, "Molten Core" },
        icon = { "achievement_boss_ragnaros", "spell_fire_lavaspawn", "inv_misc_head_dragon_01" },
        name = "Clear Molten Core",
        short = "Molten Core",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "Boss kills tick off automatically when you're in the raid with the addon loaded.",
        steps = BossSteps({
            { text = "Complete {att_mc:Attunement to the Core} in Blackrock Depths.", auto = { quest = 7848 } },
        }, { "Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah", "Baron Geddon",
             "Golemagg the Incinerator", "Sulfuron Harbinger", "Majordomo Executus", "Ragnaros" }),
    },
    {
        id = "raid_ony", library = true, instance = { 249, "Onyxia's Lair" },
        icon = "inv_misc_head_dragon_01",
        name = "Slay Onyxia",
        short = "Onyxia",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "Needs the Drakefire Amulet from the faction-specific attunement chain.",
        steps = {
            { text = "Earn the Drakefire Amulet from the {att_ony:Onyxia attunement}.", auto = { item = 16309 } },
            { text = "Defeat Onyxia in Onyxia's Lair.", auto = { boss = "Onyxia" } },
            { text = "Loot the Head of Onyxia and turn it in at your capital city.", auto = { item = { 18422, 18423 } } },
        },
    },
    {
        id = "raid_bwl", library = true, instance = { 469, "Blackwing Lair" },
        icon = { "achievement_boss_nefarion", "inv_misc_head_dragon_black", "inv_misc_head_dragon_01" },
        name = "Clear Blackwing Lair",
        short = "Blackwing Lair",
        category = "Raid", difficulty = "Very Hard",
        timeEstimate = "2-4 Weeks",
        note = "Boss kills tick off automatically when you're in the raid with the addon loaded.",
        steps = BossSteps({
            { text = "Complete {att_bwl:Blackhand's Command} ({key_ubrs:Upper Blackrock Spire}) for attunement.", auto = { quest = 7761 } },
        }, { "Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer", "Firemaw",
             "Ebonroc", "Flamegor", "Chromaggus", "Nefarian" }),
    },
    {
        id = "raid_zg", library = true, instance = { 309, "Zul'Gurub" },
        icon = { "achievement_boss_hakkar", "inv_misc_coin_01" },
        name = "Clear Zul'Gurub",
        short = "Zul'Gurub",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "The 20-player troll raid. Gahz'ranka and the Edge of Madness boss are optional.",
        steps = BossSteps({}, { "High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li",
            "Bloodlord Mandokir", "Edge of Madness", "High Priest Thekal", "Gahz'ranka",
            "High Priestess Arlokk", "Jin'do the Hexxer", "Hakkar" }),
    },
    {
        id = "raid_aq20", library = true, instance = { 509, "Ruins of Ahn'Qiraj" },
        icon = { "achievement_boss_ossirian", "inv_misc_qirajicrystal_01" },
        name = "Clear Ruins of Ahn'Qiraj",
        short = "Ahn'Qiraj (AQ20)",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "The 20-player AQ raid in Silithus. Kills here also build Cenarion Circle reputation.",
        steps = BossSteps({}, { "Kurinnaxx", "General Rajaxx", "Moam", "Buru the Gorger",
            "Ayamiss the Hunter", "Ossirian the Unscarred" }),
        tips = {
            "Moam, Buru and Ayamiss are optional; the raid can go straight from Rajaxx to Ossirian.",
            "Ossirian is only vulnerable near the crystals around his room. Move him from crystal to crystal.",
        },
    },
    {
        id = "raid_aq40", library = true, instance = { 531, "Ahn'Qiraj Temple", "Temple of Ahn'Qiraj" },
        icon = { "achievement_boss_cthun", "inv_misc_qirajicrystal_05" },
        name = "Clear Temple of Ahn'Qiraj",
        short = "Ahn'Qiraj (AQ40)",
        category = "Raid", difficulty = "Very Hard",
        timeEstimate = "1-2 Months",
        note = "The 40-player AQ raid. The Bug Trio, Viscidus and Ouro are optional for reaching C'Thun.",
        steps = BossSteps({}, { "The Prophet Skeram", { "Silithid Royalty", "Bug Trio" }, "Battleguard Sartura",
            "Fankriss the Unyielding", "Viscidus", "Princess Huhuran", { "Twin Emperors", "Emperor Vek" }, "Ouro", "C'Thun" }),
    },
    {
        id = "raid_naxx", library = true, instance = { 533, "Naxxramas" },
        icon = { "achievement_boss_kelthuzad_01", "inv_misc_head_dragon_01" },
        name = "Clear Naxxramas",
        short = "Naxxramas",
        category = "Raid", difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "The hardest raid in the game: all four wings, Sapphiron and Kel'Thuzad.",
        steps = BossSteps({
            { text = "Get {att_naxx:attuned to Naxxramas} at Light's Hope Chapel.", auto = { quest = { 9121, 9122, 9123 } } },
        }, { "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean",
             "Loatheb", "Instructor Razuvious", "Gothik the Harvester", { "Four Horsemen" }, "Patchwerk",
             "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" }),
    },
    -- New in WoW Forever (Wowhead's Forever raids guide, 2026-09-13): both
    -- open December 9, 2026; bosses, entrances, attunements and loot are
    -- still hidden. One boss each is known from the game's Statistics
    -- window ("<boss> kills (<raid>)"), so that step ticks from the kill
    -- statistic or from a kill seen while the addon runs. Add the other
    -- bosses at the END of the steps as they're revealed (steps are saved
    -- by position). No `instance` yet: their map IDs are unknown.
    {
        id = "raid_hyjal", library = true, forever = "new",
        icon = { "spell_nature_starfall", "ability_druid_starfall" },
        name = "Clear Hyjal Summit",
        short = "Hyjal Summit",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "Varies",
        note = "A new 20-player raid in Mount Hyjal, opening December 9, 2026. More bosses join this guide as they're revealed.",
        foreverNote = "Its bosses, entrance and loot haven't been revealed yet; this guide grows as they are.",
        steps = {
            { text = "Defeat The Wild King in Hyjal Summit.",
              auto = { boss = "The Wild King", stat = { id = 63580, value = 1, what = "Wild King kills" } } },
        },
    },
    {
        id = "raid_barrow", library = true, forever = "new",
        icon = { "spell_nature_sleep", "spell_nature_starfall" },
        name = "Clear the Barrow Deeps",
        short = "Barrow Deeps",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "Varies",
        note = "A new 10-player raid where the Night Elves hold dangerous prisoners, with three entrances, one in Mount Hyjal. Opens December 9, 2026.",
        foreverNote = "Its bosses, entrances and loot haven't been revealed yet; this guide grows as they are.",
        steps = {
            { text = "Defeat Sonya Darkhallow in the Barrow Deeps.",
              auto = { boss = "Sonya Darkhallow", stat = { id = 63581, value = 1, what = "Sonya Darkhallow kills" } } },
        },
    },
    -- ---------------- Attunements and keys ----------------
    -- One goal each, so players add only the ones they need. IDs checked
    -- on Wowhead. Attunements are per character; a tick means at least
    -- one of your characters has it.
    {
        id = "att_mc", library = true,
        icon = "achievement_boss_ragnaros",
        name = "Attunement: Molten Core",
        short = "MC Attunement",
        category = "Attunement", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "Required to enter Molten Core. A short trip into Blackrock Depths to the raid's entry portal.",
        steps = {
            { text = "Pick up 'Attunement to the Core' from Lothos Riftwaker in Blackrock Mountain.", auto = { questTaken = 7848, quest = 7848 } },
            { text = "Recover a Core Fragment at the Molten Core entry portal in Blackrock Depths.", auto = { item = 18412, quest = 7848 } },
            { text = "Return the Core Fragment to Lothos Riftwaker.", auto = { quest = 7848 } },
        },
    },
    {
        id = "att_ony_ally", library = true, faction = "Alliance",
        icon = "inv_jewelry_talisman_11",
        name = "Attunement: Onyxia's Lair (Alliance)",
        short = "Onyxia Attunement",
        category = "Attunement", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "The Alliance chain to the Drakefire Amulet, which opens Onyxia's Lair. It runs through Blackrock Spire and Blackrock Depths and ends with a masquerade in Stormwind.",
        steps = {
            { text = "Complete 'Dragonkin Menace' from Helendis Riverhorn in the Burning Steppes.", auto = { quest = 4182 } },
            { text = "Complete the 'The True Masters' quests.", auto = { quest = 4224 } },
            { text = "Complete 'Marshal Windsor'.", auto = { quest = 4241 } },
            { text = "Complete 'Abandoned Hope'.", auto = { quest = 4242 } },
            { text = "Complete 'A Crumpled Up Note'.", auto = { quest = 4264 } },
            { text = "Complete 'A Shred of Hope'.", auto = { quest = 4282 } },
            { text = "Complete 'Jail Break!'.", auto = { quest = 4322 } },
            { text = "Complete 'Stormwind Rendezvous'.", auto = { quest = 6402 } },
            { text = "Complete 'The Great Masquerade'.", auto = { quest = 6403 } },
            { text = "Complete 'The Dragon's Eye'.", auto = { quest = 6501 } },
            { text = "Complete 'Drakefire Amulet' and receive the amulet.", auto = { quest = 6502, item = 16309 } },
        },
        completeWith = { item = 16309, quest = 6502 },
    },
    {
        id = "att_ony_horde", library = true, faction = "Horde",
        icon = "inv_jewelry_talisman_11",
        name = "Attunement: Onyxia's Lair (Horde)",
        short = "Onyxia Attunement",
        category = "Attunement", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "The Horde chain to the Drakefire Amulet, which opens Onyxia's Lair. It runs through Blackrock Spire, the Test of Skulls and Upper Blackrock Spire.",
        steps = {
            { text = "Complete 'Warlord's Command' and turn it in to Warlord Goretooth in Kargath, Badlands.", auto = { quest = 4903 } },
            { text = "Complete 'Eitrigg's Wisdom'.", auto = { quest = 4941 } },
            { text = "Complete 'For The Horde!'.", auto = { quest = 4974 } },
            { text = "Complete 'What the Wind Carries'.", auto = { quest = 6566 } },
            { text = "Complete 'The Champion of the Horde'.", auto = { quest = 6567 } },
            { text = "Complete 'The Testament of Rexxar'.", auto = { quest = 6568 } },
            { text = "Complete 'Oculus Illusions'.", auto = { quest = 6569 } },
            { text = "Complete 'Emberstrife'.", auto = { quest = 6570 } },
            { text = "Complete 'The Test of Skulls, Scryer'.", auto = { quest = 6582 } },
            { text = "Complete 'The Test of Skulls, Somnus'.", auto = { quest = 6583 } },
            { text = "Complete 'The Test of Skulls, Chronalis'.", auto = { quest = 6584 } },
            { text = "Complete 'The Test of Skulls, Axtroz'.", auto = { quest = 6585 } },
            { text = "Complete 'Ascension...'.", auto = { quest = 6601 } },
            { text = "Complete 'Blood of the Black Dragon Champion' and receive the Drakefire Amulet.", auto = { quest = 6602, item = 16309 } },
        },
        completeWith = { item = 16309, quest = 6602 },
    },
    {
        id = "att_bwl", library = true,
        icon = "achievement_boss_nefarion",
        name = "Attunement: Blackwing Lair",
        short = "BWL Attunement",
        category = "Attunement", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "Without the Mark of Drakkisath you can't use the orb into Blackwing Lair. The whole quest happens in Blackrock Spire.",
        steps = {
            { text = "Loot and read Blackhand's Command from the Scarshield Quartermaster in Blackrock Spire.", auto = { item = 18987, questTaken = 7761, quest = 7761 } },
            { text = "Defeat General Drakkisath in {key_ubrs:Upper Blackrock Spire}.", auto = { boss = "General Drakkisath", quest = 7761 } },
            { text = "Touch Drakkisath's Brand behind him to gain the Mark of Drakkisath.", auto = { quest = 7761 } },
        },
    },    {
        id = "att_naxx", library = true,
        icon = "achievement_boss_kelthuzad_01",
        name = "Attunement: Naxxramas",
        short = "Naxx Attunement",
        category = "Attunement", difficulty = "Hard",
        timeEstimate = "2-4 Weeks",
        note = "Taken at Light's Hope Chapel in the Eastern Plaguelands once you're Honored with the Argent Dawn.",
        steps = {
            { text = "Reach Honored with the {rep_argentdawn:Argent Dawn}.", auto = { rep = { faction = 529, standing = 6 }, quest = { 9121, 9122, 9123 } } },
            { text = "Get attuned at Light's Hope Chapel.", auto = { quest = { 9121, 9122, 9123 } } },
        },
        tips = {
            "Reaching Revered first makes the attunement cheaper.",
        },
    },
    {
        id = "key_ubrs", library = true,
        icon = "inv_jewelry_ring_01",
        name = "Key: Seal of Ascension (Upper Blackrock Spire)",
        short = "UBRS Key",
        category = "Attunement", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "The Seal of Ascension opens Upper Blackrock Spire. You build it from gems collected in Lower Blackrock Spire.",
        steps = {
            { text = "Pick up 'Seal of Ascension'.", auto = { questTaken = { 4742, 4743 }, quest = { 4742, 4743 }, item = 12344 } },
            { text = "Forge the Seal of Ascension.", auto = { item = 12344, quest = 4743, owned = { "Seal of Ascension" } } },
        },
    },
    {
        id = "key_scholo", library = true,
        icon = "inv_misc_key_11",
        name = "Key: Skeleton Key (Scholomance)",
        short = "Scholomance Key",
        category = "Attunement", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "The Skeleton Key opens Scholomance's front door.",
        steps = {
            { text = "Complete 'The Key to Scholomance' and receive the Skeleton Key.", auto = { item = 13704, quest = { 5505, 5511 }, owned = { "Skeleton Key" } } },
        },
    },
    {
        id = "key_brd", library = true,
        icon = "inv_misc_key_08",
        name = "Key: Shadowforge Key (Blackrock Depths)",
        short = "Shadowforge Key",
        category = "Attunement", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "Opens the Shadowforge doors inside Blackrock Depths.",
        steps = {
            { text = "Complete the first 'Dark Iron Legacy'.", auto = { quest = { 3801, 3802 }, item = 11000 } },
            { text = "Complete the second 'Dark Iron Legacy' and receive the Shadowforge Key.", auto = { item = 11000, quest = 3802, owned = { "Shadowforge Key" } } },
        },
    },
    {
        id = "key_strat", library = true,
        icon = "inv_misc_key_13",
        name = "Key: Key to the City (Stratholme)",
        short = "Stratholme Key",
        category = "Attunement", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "Opens the locked gates in Stratholme.",
        steps = {
            { text = "Loot the Key to the City from Magistrate Barthilas.", auto = { item = 12382, owned = { "Key to the City" } } },
        },
    },
    {
        id = "key_dm", library = true,
        icon = "inv_misc_key_10",
        name = "Key: Crescent Key (Dire Maul)",
        short = "Dire Maul Key",
        category = "Attunement", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "Opens the locked doors in Dire Maul's West and North wings.",
        steps = {
            { text = "Loot the Crescent Key from Pusillin in Dire Maul East.", auto = { item = 18249, owned = { "Crescent Key" } } },
        },
    },
    -- ---------------- Professions ----------------
    {
        id = "prof_secondary", library = true, group = true,
        icon = { "trade_fishing" },
        name = "Max Secondary Skills",
        short = "Secondary Skills",
        category = "Profession", difficulty = "Moderate",
        timeEstimate = "2-4 Weeks",
        note = "Fishing, Cooking and First Aid to 300 on any character. Pick the ones you want in the Library; each ticks itself from your skill levels.",
        steps = { SkillStep("Fishing", 300), SkillStep("Cooking", 300), SkillStep("First Aid", 300) },
    },
    {
        id = "prof_all", library = true, group = true,
        icon = { "trade_engineering" },
        name = "Max Primary Professions",
        short = "Professions",
        category = "Profession", difficulty = "Extreme",
        timeEstimate = "Ongoing",
        note = "Primary professions at 300 somewhere on your roster. Pick the ones you care about in the Library; each ticks itself from your skill levels.",
        steps = { SkillStep("Alchemy", 300), SkillStep("Blacksmithing", 300), SkillStep("Enchanting", 300),
                  SkillStep("Engineering", 300), SkillStep("Herbalism", 300), SkillStep("Leatherworking", 300),
                  SkillStep("Mining", 300), SkillStep("Skinning", 300), SkillStep("Tailoring", 300) },
    },


    -- Classic tournament rules, items and quest checked on Wowhead,
    -- 2026-10-10: /classic/guide/wow-classic-stranglethorn-vale-fishing-extravaganza
    {
        id = "fishing_extravaganza", library = true,
        name = "Win the Stranglethorn Fishing Extravaganza", short = "Fishing Extravaganza",
        icon = "trade_fishing", category = "Profession", difficulty = "Very Hard",
        timeEstimate = "Varies",
        note = "Race to bring 40 Speckled Tastyfish to Riggle Bassbait in Booty Bay before the other anglers. Win once and choose a tournament prize.",
        completeWith = { quest = 8193, item = { 19970, 19979 } },
        tips = {
            "The Classic tournament runs on Sundays. Check your realm's event schedule; Forever's timing and rules have not been verified.",
            "Fish in Pools of Tastyfish around Stranglethorn Vale. Booty Bay itself has no tournament pools. Fishing 225 or higher helps avoid fish getting away.",
            "Set your hearthstone in Booty Bay, keep it ready, and leave bag space for the catch. Riggle Bassbait stands on the central docks near the inn during the event.",
            "The first 'Master Angler' turn-in wins. Choose either {item:19970:Arcanite Fishing Pole} or {item:19979:Hook of the Master Angler}; owning either completes this goal.",
            "{item:19807:Speckled Tastyfish} expire after the event, so they cannot be saved for next week's tournament.",
        },
        steps = {
            { text = "Reach Fishing 150 on a character.", icon = "trade_fishing", auto = { skill = { name = "Fishing", rank = 150 } } },
            { text = "Catch 40 Speckled Tastyfish from Pools of Tastyfish in Stranglethorn Vale.", icon = "inv_misc_fish_21", auto = { item = 19807, count = 40 } },
            { text = "Turn in 'Master Angler' to Riggle Bassbait in Booty Bay before the other anglers.", icon = "trade_fishing", auto = { quest = 8193, item = { 19970, 19979 } } },
        },
    },

    -- ---------------- Milestones ----------------
    {
        id = "gold_5k", library = true, forever = "confirmed",
        icon = { "inv_misc_coin_02", "inv_misc_coin_01" },
        name = "Save 5,000 Gold",
        category = "Milestone", difficulty = "Hard",
        timeEstimate = "Varies",
        note = "Hold your gold target on a single character, with milestones on the way. Ticks itself from your gold.",
        -- Right-click > Change target. Steps are the marks (fractions of
        -- the target), rebuilt by FGT.ApplyTargets; the steps below are
        -- the default target's.
        target = { kind = "money", default = 5000, min = 100, max = 200000, marks = { 0.2, 0.5, 1 },
                   name = "Save %s Gold", step = "Hold %s gold on one character.", unit = "gold" },
        steps = {
            { text = "Hold 1,000 gold on one character.", auto = { money = 1000 * 10000 } },
            { text = "Hold 2,500 gold on one character.", auto = { money = 2500 * 10000 } },
            { text = "Hold 5,000 gold on one character.", auto = { money = 5000 * 10000 } },
        },
    },

    -- ---------------- Social ----------------
    {
        id = "social_guild", library = true, forever = "confirmed",
        icon = { "inv_shirt_guildtabard_01", "inv_misc_groupneedmore" },
        name = "Join a Guild",
        category = "Social", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "Find your people: join a guild and wear its colors. Ticks itself.",
        tips = {
            "Guilds recruit in the Guild Recruitment channel in capital cities, and in general chat.",
            "{item:5976:Guild Tabards} are sold by the Guild Master in each capital city once your guild has designed its tabard.",
        },
        steps = {
            { text = "Join a guild.", auto = { guild = true } },
            { text = "Buy a Guild Tabard from a Guild Master in a capital city.", auto = { item = 5976 } },
        },
    },
    {
        id = "social_friends", library = true, forever = "confirmed",
        icon = { "inv_misc_groupneedmore", "inv_misc_grouplooking" },
        name = "Make Friends",
        category = "Social", difficulty = "Moderate",
        timeEstimate = "Varies",
        note = "Add the people you enjoy playing with to your friends list. Ticks itself.",
        tips = {
            "Right-click a player's name and choose Add Friend, or type /friend and their name.",
        },
        target = { kind = "friends", default = 25, min = 5, max = 100, marks = { 0.2, 0.4, 1 },
                   step = "Have %s friends on your friends list.", unit = "friends" },
        steps = {
            { text = "Have 5 friends on your friends list.", auto = { friends = 5 } },
            { text = "Have 10 friends on your friends list.", auto = { friends = 10 } },
            { text = "Have 25 friends on your friends list.", auto = { friends = 25 } },
        },
    },
}

for _, goal in ipairs(library) do
    table.insert(FGT.goals, goal)
end

-- AQ40 trash mounts: Classic names, IDs, icons and sources checked on
-- Wowhead's four crystal item pages, 2026-10-10. Independent color goals.
do
    for _, crystal in ipairs({
        { "Blue", 21218, "inv_misc_qirajicrystal_04" },
        { "Green", 21323, "inv_misc_qirajicrystal_03" },
        { "Yellow", 21324, "inv_misc_qirajicrystal_01" },
        { "Red", 21321, "inv_misc_qirajicrystal_02" },
    }) do
        local color, id, icon = crystal[1], crystal[2], crystal[3]
        local name = color .. " Qiraji Resonating Crystal"
        table.insert(FGT.goals, {
            id = "mount_qiraji_" .. color:lower(), library = true,
            name = name, short = color .. " Qiraji", icon = icon,
            category = "Mount", difficulty = color == "Red" and "Very Hard" or "Hard",
            timeEstimate = "Varies",
            note = "Collect the " .. color:lower() .. " Qiraji battle tank from trash enemies in Temple of Ahn'Qiraj. Ticks itself when the crystal or learned mount is owned.",
            steps = {
                { text = "Loot the " .. name .. " from trash enemies in Temple of Ahn'Qiraj.",
                  icon = icon, auto = { item = id, owned = { color .. " Qiraji" } } },
            },
            completeWith = { item = id, owned = { color .. " Qiraji" } },
            tips = {
                "These crystals drop in {raid_aq40:Temple of Ahn'Qiraj}, the 40-player raid, rather than Ruins of Ahn'Qiraj.",
                "In Classic, this mount can only be ridden inside Temple of Ahn'Qiraj and requires level 60. Forever's rules have not been verified.",
                "The red crystal drops less often than blue, green and yellow. None of these requires the Scarab Gong event for the {mount_qiraji:black battle tank}.",
            },
        })
    end
end

-- ============================================================
-- Item sets (Tier 1, Tier 2, dungeon sets)
-- ============================================================
-- Each class set is a section; each piece ticks itself when it shows
-- up in your bags, bank or gear on any character (by item ID or name).
-- Piece names and IDs from Wowhead's Classic item-set pages.
local function BuildSetSections(sets)
    local sections = {}
    for _, set in ipairs(sets) do
        local class, setName, pieces = set[1], set[2], set[3]
        local list = {}
        for _, p in ipairs(pieces) do
            -- p = { piece name, item id, where it comes from (Wowhead), item icon (optional) }
            table.insert(list, { name = p[1], text = p[3] and (p[1] .. " from " .. p[3] .. ".") or nil,
                                 icon = p[4], materials = {}, auto = { item = p[2], owned = { p[1] } } })
        end
        -- set[4] = true: a set new in WoW Forever (blue NEW part)
        table.insert(sections, { icon = "ClassIcon_" .. class, name = class .. " - " .. setName, pieces = list,
                                 forever = set[4] and "new" or nil })
    end
    return sections
end

local TIER1 = {
    { "Warrior", "Battlegear of Might", { { "Helm of Might", 16866, "Garr", "inv_helmet_09" }, { "Pauldrons of Might", 16868, "Sulfuron Harbinger", "inv_shoulder_15" }, { "Breastplate of Might", 16865, "Golemagg the Incinerator", "inv_chest_plate16" }, { "Gauntlets of Might", 16863, "Lucifron", "inv_gauntlets_10" }, { "Legplates of Might", 16867, "Magmadar", "inv_pants_04" }, { "Belt of Might", 16864, "Molten Core trash", "inv_belt_09" }, { "Bracers of Might", 16861, "Molten Core trash", "inv_bracer_19" }, { "Sabatons of Might", 16862, "Gehennas", "inv_boots_plate_04" } } },
    { "Paladin", "Lawbringer Armor", { { "Lawbringer Helm", 16854, "Garr", "inv_helmet_05" }, { "Lawbringer Spaulders", 16856, "Baron Geddon", "inv_shoulder_20" }, { "Lawbringer Chestguard", 16853, "Golemagg the Incinerator", "inv_chest_plate03" }, { "Lawbringer Gauntlets", 16860, "Gehennas", "inv_gauntlets_29" }, { "Lawbringer Legplates", 16855, "Magmadar", "inv_pants_04" }, { "Lawbringer Belt", 16858, "Molten Core trash", "inv_belt_27" }, { "Lawbringer Bracers", 16857, "Molten Core trash", "inv_bracer_18" }, { "Lawbringer Boots", 16859, "Lucifron", "inv_boots_plate_09" } } },
    { "Hunter", "Giantstalker Armor", { { "Giantstalker's Helmet", 16846, "Garr", "inv_helmet_05" }, { "Giantstalker's Epaulets", 16848, "Sulfuron Harbinger", "inv_shoulder_10" }, { "Giantstalker's Breastplate", 16845, "Golemagg the Incinerator", "inv_chest_chain_03" }, { "Giantstalker's Gloves", 16852, "Shazzrah", "inv_gauntlets_10" }, { "Giantstalker's Leggings", 16847, "Magmadar", "inv_pants_mail_03" }, { "Giantstalker's Belt", 16851, "Molten Core trash", "inv_belt_28" }, { "Giantstalker's Bracers", 16850, "Molten Core trash", "inv_bracer_17" }, { "Giantstalker's Boots", 16849, "Gehennas", "inv_boots_chain_13" } } },
    { "Rogue", "Nightslayer Armor", { { "Nightslayer Cover", 16821, "Garr", "inv_helmet_41" }, { "Nightslayer Shoulder Pads", 16823, "Sulfuron Harbinger", "inv_shoulder_25" }, { "Nightslayer Chestpiece", 16820, "Golemagg the Incinerator", "inv_chest_cloth_07" }, { "Nightslayer Gloves", 16826, "Gehennas", "inv_gauntlets_21" }, { "Nightslayer Pants", 16822, "Magmadar", "inv_pants_06" }, { "Nightslayer Belt", 16827, "Molten Core trash", "inv_belt_23" }, { "Nightslayer Bracelets", 16825, "Molten Core trash", "inv_bracer_02" }, { "Nightslayer Boots", 16824, "Shazzrah", "inv_boots_08" } } },
    { "Priest", "Vestments of Prophecy", { { "Circlet of Prophecy", 16813, "Garr", "inv_helmet_34" }, { "Mantle of Prophecy", 16816, "Sulfuron Harbinger", "inv_shoulder_02" }, { "Robes of Prophecy", 16815, "Golemagg the Incinerator", "inv_chest_cloth_03" }, { "Gloves of Prophecy", 16812, "Gehennas", "inv_gauntlets_14" }, { "Pants of Prophecy", 16814, "Magmadar", "inv_pants_08" }, { "Girdle of Prophecy", 16817, "Molten Core trash", "inv_belt_22" }, { "Vambraces of Prophecy", 16819, "Molten Core trash", "inv_bracer_09" }, { "Boots of Prophecy", 16811, "Shazzrah", "inv_boots_07" } } },
    { "Shaman", "The Earthfury", { { "Earthfury Helmet", 16842, "Garr", "inv_helmet_09" }, { "Earthfury Epaulets", 16844, "Baron Geddon", "inv_shoulder_29" }, { "Earthfury Vestments", 16841, "Golemagg the Incinerator", "inv_chest_chain_11" }, { "Earthfury Gauntlets", 16839, "Gehennas", "inv_gauntlets_11" }, { "Earthfury Legguards", 16843, "Magmadar", "inv_pants_03" }, { "Earthfury Belt", 16838, "Molten Core trash", "inv_belt_14" }, { "Earthfury Bracers", 16840, "Molten Core trash", "inv_bracer_16" }, { "Earthfury Boots", 16837, "Lucifron", "inv_boots_plate_06" } } },
    { "Mage", "Arcanist Regalia", { { "Arcanist Crown", 16795, "Garr", "inv_helmet_53" }, { "Arcanist Mantle", 16797, "Baron Geddon", "inv_shoulder_02" }, { "Arcanist Robes", 16798, "Golemagg the Incinerator", "inv_chest_cloth_03" }, { "Arcanist Gloves", 16801, "Shazzrah", "inv_gauntlets_14" }, { "Arcanist Leggings", 16796, "Magmadar", "inv_pants_08" }, { "Arcanist Belt", 16802, "Molten Core trash", "inv_belt_30" }, { "Arcanist Bindings", 16799, "Molten Core trash", "inv_belt_29" }, { "Arcanist Boots", 16800, "Lucifron", "inv_boots_07" } } },
    { "Warlock", "Felheart Raiment", { { "Felheart Horns", 16808, "Garr", "inv_helmet_08" }, { "Felheart Shoulder Pads", 16807, "Baron Geddon", "inv_shoulder_23" }, { "Felheart Robes", 16809, "Golemagg the Incinerator", "inv_chest_cloth_09" }, { "Felheart Gloves", 16805, "Lucifron", "inv_gauntlets_19" }, { "Felheart Pants", 16810, "Magmadar", "inv_pants_cloth_14" }, { "Felheart Belt", 16806, "Molten Core trash", "inv_belt_13" }, { "Felheart Bracers", 16804, "Molten Core trash", "inv_bracer_07" }, { "Felheart Slippers", 16803, "Shazzrah", "inv_boots_cloth_05" } } },
    { "Druid", "Cenarion Raiment", { { "Cenarion Helm", 16834, "Garr", "inv_helmet_09" }, { "Cenarion Spaulders", 16836, "Baron Geddon", "inv_shoulder_07" }, { "Cenarion Vestments", 16833, "Golemagg the Incinerator", "inv_chest_cloth_06" }, { "Cenarion Gloves", 16831, "Shazzrah", "inv_gauntlets_07" }, { "Cenarion Leggings", 16835, "Magmadar", "inv_pants_06" }, { "Cenarion Belt", 16828, "Molten Core trash", "inv_belt_06" }, { "Cenarion Bracers", 16830, "Molten Core trash", "inv_bracer_03" }, { "Cenarion Boots", 16829, "Lucifron", "inv_boots_08" } } },
}

local TIER2 = {
    { "Warrior", "Battlegear of Wrath", { { "Helm of Wrath", 16963, "Onyxia", "inv_helmet_71" }, { "Pauldrons of Wrath", 16961, "Chromaggus", "inv_shoulder_34" }, { "Breastplate of Wrath", 16966, "Nefarian", "inv_chest_plate16" }, { "Gauntlets of Wrath", 16964, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_10" }, { "Legplates of Wrath", 16962, "Ragnaros", "inv_pants_04" }, { "Waistband of Wrath", 16960, "Vaelastrasz the Corrupt", "inv_belt_09" }, { "Bracelets of Wrath", 16959, "Razorgore the Untamed", "inv_bracer_19" }, { "Sabatons of Wrath", 16965, "Broodlord Lashlayer", "inv_boots_plate_04" } } },
    { "Paladin", "Judgement Armor", { { "Judgement Crown", 16955, "Onyxia", "inv_helmet_74" }, { "Judgement Spaulders", 16953, "Chromaggus", "inv_shoulder_37" }, { "Judgement Breastplate", 16958, "Nefarian", "inv_chest_plate03" }, { "Judgement Gauntlets", 16956, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_29" }, { "Judgement Legplates", 16954, "Ragnaros", "inv_pants_04" }, { "Judgement Belt", 16952, "Vaelastrasz the Corrupt", "inv_belt_27" }, { "Judgement Bindings", 16951, "Razorgore the Untamed", "inv_bracer_18" }, { "Judgement Sabatons", 16957, "Broodlord Lashlayer", "inv_boots_plate_09" } } },
    { "Hunter", "Dragonstalker Armor", { { "Dragonstalker's Helm", 16939, "Onyxia", "inv_helmet_05" }, { "Dragonstalker's Spaulders", 16937, "Chromaggus", "inv_shoulder_10" }, { "Dragonstalker's Breastplate", 16942, "Nefarian", "inv_chest_chain_03" }, { "Dragonstalker's Gauntlets", 16940, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_10" }, { "Dragonstalker's Legguards", 16938, "Ragnaros", "inv_pants_03" }, { "Dragonstalker's Belt", 16936, "Vaelastrasz the Corrupt", "inv_belt_28" }, { "Dragonstalker's Bracers", 16935, "Razorgore the Untamed", "inv_bracer_17" }, { "Dragonstalker's Greaves", 16941, "Broodlord Lashlayer", "inv_boots_plate_07" } } },
    { "Rogue", "Bloodfang Armor", { { "Bloodfang Hood", 16908, "Onyxia", "inv_helmet_41" }, { "Bloodfang Spaulders", 16832, "Chromaggus", "inv_shoulder_23" }, { "Bloodfang Chestpiece", 16905, "Nefarian", "inv_chest_cloth_07" }, { "Bloodfang Gloves", 16907, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_21" }, { "Bloodfang Pants", 16909, "Ragnaros", "inv_pants_06" }, { "Bloodfang Belt", 16910, "Vaelastrasz the Corrupt", "inv_belt_23" }, { "Bloodfang Bracers", 16911, "Razorgore the Untamed", "inv_bracer_02" }, { "Bloodfang Boots", 16906, "Broodlord Lashlayer", "inv_boots_08" } } },
    { "Priest", "Vestments of Transcendence", { { "Halo of Transcendence", 16921, "Onyxia", "inv_helmet_24" }, { "Pauldrons of Transcendence", 16924, "Chromaggus", "inv_shoulder_02" }, { "Robes of Transcendence", 16923, "Nefarian", "inv_chest_cloth_03" }, { "Handguards of Transcendence", 16920, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_14" }, { "Leggings of Transcendence", 16922, "Ragnaros", "inv_pants_08" }, { "Belt of Transcendence", 16925, "Vaelastrasz the Corrupt", "inv_belt_22" }, { "Bindings of Transcendence", 16926, "Razorgore the Untamed", "inv_bracer_09" }, { "Boots of Transcendence", 16919, "Broodlord Lashlayer", "inv_boots_07" } } },
    { "Shaman", "The Ten Storms", { { "Helmet of Ten Storms", 16947, "Onyxia", "inv_helmet_69" }, { "Epaulets of Ten Storms", 16945, "Chromaggus", "inv_shoulder_33" }, { "Breastplate of Ten Storms", 16950, "Nefarian", "inv_chest_chain_11" }, { "Gauntlets of Ten Storms", 16948, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_11" }, { "Legplates of Ten Storms", 16946, "Ragnaros", "inv_pants_03" }, { "Belt of Ten Storms", 16944, "Vaelastrasz the Corrupt", "inv_belt_14" }, { "Bracers of Ten Storms", 16943, "Razorgore the Untamed", "inv_bracer_16" }, { "Greaves of Ten Storms", 16949, "Broodlord Lashlayer", "inv_boots_plate_06" } } },
    { "Mage", "Netherwind Regalia", { { "Netherwind Crown", 16914, "Onyxia", "inv_helmet_70" }, { "Netherwind Mantle", 16917, "Chromaggus", "inv_shoulder_32" }, { "Netherwind Robes", 16916, "Nefarian", "inv_chest_cloth_03" }, { "Netherwind Gloves", 16913, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_14" }, { "Netherwind Pants", 16915, "Ragnaros", "inv_pants_08" }, { "Netherwind Belt", 16818, "Vaelastrasz the Corrupt", "inv_belt_22" }, { "Netherwind Bindings", 16918, "Razorgore the Untamed", "inv_bracer_09" }, { "Netherwind Boots", 16912, "Broodlord Lashlayer", "inv_boots_07" } } },
    { "Warlock", "Nemesis Raiment", { { "Nemesis Skullcap", 16929, "Onyxia", "inv_helmet_08" }, { "Nemesis Spaulders", 16932, "Chromaggus", "inv_shoulder_19" }, { "Nemesis Robes", 16931, "Nefarian", "inv_chest_leather_01" }, { "Nemesis Gloves", 16928, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_19" }, { "Nemesis Leggings", 16930, "Ragnaros", "inv_pants_07" }, { "Nemesis Belt", 16933, "Vaelastrasz the Corrupt", "inv_belt_13" }, { "Nemesis Bracers", 16934, "Razorgore the Untamed", "inv_bracer_07" }, { "Nemesis Boots", 16927, "Broodlord Lashlayer", "inv_boots_05" } } },
    { "Druid", "Stormrage Raiment", { { "Stormrage Cover", 16900, "Onyxia", "inv_helmet_09" }, { "Stormrage Pauldrons", 16902, "Chromaggus", "inv_shoulder_07" }, { "Stormrage Chestguard", 16897, "Nefarian", "inv_chest_chain_16" }, { "Stormrage Handguards", 16899, "Firemaw, Ebonroc or Flamegor", "inv_gauntlets_25" }, { "Stormrage Legguards", 16901, "Ragnaros", "inv_pants_06" }, { "Stormrage Belt", 16903, "Vaelastrasz the Corrupt", "inv_belt_06" }, { "Stormrage Bracers", 16904, "Razorgore the Untamed", "inv_bracer_03" }, { "Stormrage Boots", 16898, "Broodlord Lashlayer", "inv_boots_08" } } },
}

-- Dungeon Set 1 (Tier 0): drops from Scholomance, Stratholme and Blackrock
-- Spire. Sources, icons and IDs from Wowhead's item pages ("Dropped by").
local DUNGEON1 = {
    { "Warrior", "Battlegear of Valor", { { "Helm of Valor", 16731, "Darkmaster Gandling (Scholomance)", "inv_helmet_02" }, { "Spaulders of Valor", 16733, "Warchief Rend Blackhand (Upper Blackrock Spire)", "inv_shoulder_30" }, { "Breastplate of Valor", 16730, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_plate03" }, { "Gauntlets of Valor", 16737, "Ramstein the Gorger (Stratholme)", "inv_gauntlets_26" }, { "Legplates of Valor", 16732, "Baron Rivendare (Stratholme)", "inv_pants_04" }, { "Belt of Valor", 16736, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_34" }, { "Bracers of Valor", 16735, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_bracer_18" }, { "Boots of Valor", 16734, "Kirtonos the Herald (Scholomance)", "inv_boots_plate_03" } } },
    { "Paladin", "Lightforge Armor", { { "Lightforge Helm", 16727, "Darkmaster Gandling (Scholomance)", "inv_helmet_08" }, { "Lightforge Spaulders", 16729, "The Beast (Upper Blackrock Spire)", "inv_shoulder_10" }, { "Lightforge Breastplate", 16726, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_plate03" }, { "Lightforge Gauntlets", 16724, "Timmy the Cruel (Stratholme)", "inv_gauntlets_19" }, { "Lightforge Legplates", 16728, "Baron Rivendare (Stratholme)", "inv_pants_04" }, { "Lightforge Belt", 16723, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_11" }, { "Lightforge Bracers", 16722, "Lord Alexei Barov or trash in Scholomance", "inv_bracer_14" }, { "Lightforge Boots", 16725, "Grand Crusader Dathrohan (Stratholme)", "inv_boots_plate_03" } } },
    { "Hunter", "Beaststalker Armor", { { "Beaststalker's Cap", 16677, "Darkmaster Gandling (Scholomance)", "inv_helmet_24" }, { "Beaststalker's Mantle", 16679, "Overlord Wyrmthalak (Lower Blackrock Spire)", "inv_shoulder_10" }, { "Beaststalker's Tunic", 16674, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_chain_03" }, { "Beaststalker's Gloves", 16676, "War Master Voone (Lower Blackrock Spire)", "inv_gauntlets_10" }, { "Beaststalker's Pants", 16678, "Baron Rivendare (Stratholme)", "inv_pants_03" }, { "Beaststalker's Belt", 16680, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_28" }, { "Beaststalker's Bindings", 16681, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_bracer_17" }, { "Beaststalker's Boots", 16675, "Nerub'enkan (Stratholme)", "inv_boots_plate_07" } } },
    { "Rogue", "Shadowcraft Armor", { { "Shadowcraft Cap", 16707, "Darkmaster Gandling (Scholomance)", "inv_helmet_41" }, { "Shadowcraft Spaulders", 16708, "Cannon Master Willey (Stratholme)", "inv_shoulder_07" }, { "Shadowcraft Tunic", 16721, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_leather_07" }, { "Shadowcraft Gloves", 16712, "Shadow Hunter Vosh'gajin (Lower Blackrock Spire)", "inv_gauntlets_24" }, { "Shadowcraft Pants", 16709, "Baron Rivendare (Stratholme)", "inv_pants_02" }, { "Shadowcraft Belt", 16713, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_03" }, { "Shadowcraft Bracers", 16710, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_bracer_07" }, { "Shadowcraft Boots", 16711, "Rattlegore (Scholomance)", "inv_boots_08" } } },
    { "Priest", "Vestments of the Devout", { { "Devout Crown", 16693, "Darkmaster Gandling (Scholomance)", "inv_crown_01" }, { "Devout Mantle", 16695, "Solakar Flamewreath (Upper Blackrock Spire)", "inv_shoulder_02" }, { "Devout Robe", 16690, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_cloth_11" }, { "Devout Gloves", 16692, "Archivist Galford (Stratholme)", "inv_gauntlets_14" }, { "Devout Skirt", 16694, "Baron Rivendare (Stratholme)", "inv_pants_08" }, { "Devout Belt", 16696, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_10" }, { "Devout Bracers", 16697, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_31" }, { "Devout Sandals", 16691, "Maleki the Pallid (Stratholme)", "inv_boots_05" } } },
    { "Shaman", "The Elements", { { "Coif of Elements", 16667, "Darkmaster Gandling (Scholomance)", "inv_helmet_04" }, { "Pauldrons of Elements", 16669, "Gyth (Upper Blackrock Spire)", "inv_shoulder_29" }, { "Vest of Elements", 16666, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_chain_11" }, { "Gauntlets of Elements", 16672, "Pyroguard Emberseer (Upper Blackrock Spire)", "inv_gauntlets_11" }, { "Kilt of Elements", 16668, "Baron Rivendare (Stratholme)", "inv_pants_03" }, { "Cord of Elements", 16673, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_16" }, { "Bindings of Elements", 16671, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_bracer_02" }, { "Boots of Elements", 16670, "Highlord Omokk (Lower Blackrock Spire)", "inv_boots_wolf" } } },
    { "Mage", "Magister's Regalia", { { "Magister's Crown", 16686, "Darkmaster Gandling (Scholomance)", "inv_crown_02" }, { "Magister's Mantle", 16689, "Ras Frostwhisper (Scholomance)", "inv_shoulder_23" }, { "Magister's Robes", 16688, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_cloth_25" }, { "Magister's Gloves", 16684, "Doctor Theolen Krastinov (Scholomance)", "inv_gauntlets_17" }, { "Magister's Leggings", 16687, "Baron Rivendare (Stratholme)", "inv_pants_06" }, { "Magister's Belt", 16685, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_08" }, { "Magister's Bindings", 16683, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_jewelry_ring_23" }, { "Magister's Boots", 16682, "Hearthsinger Forresten (Stratholme)", "inv_boots_02" } } },
    { "Warlock", "Dreadmist Raiment", { { "Dreadmist Mask", 16698, "Darkmaster Gandling (Scholomance)", "inv_helmet_29" }, { "Dreadmist Mantle", 16701, "Jandice Barov (Scholomance)", "inv_misc_bone_taurenskull_01" }, { "Dreadmist Robe", 16700, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_cloth_49" }, { "Dreadmist Wraps", 16705, "Lorekeeper Polkelt (Scholomance)", "inv_gauntlets_32" }, { "Dreadmist Leggings", 16699, "Baron Rivendare (Stratholme)", "inv_pants_08" }, { "Dreadmist Belt", 16702, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_belt_12" }, { "Dreadmist Bracers", 16703, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_bracer_13" }, { "Dreadmist Sandals", 16704, "Baroness Anastari (Stratholme)", "inv_boots_05" } } },
    { "Druid", "Wildheart Raiment", { { "Wildheart Cowl", 16720, "Darkmaster Gandling (Scholomance)", "inv_helmet_27" }, { "Wildheart Spaulders", 16718, "Gizrul the Slavener (Lower Blackrock Spire)", "inv_shoulder_01" }, { "Wildheart Vest", 16706, "General Drakkisath (Upper Blackrock Spire)", "inv_chest_plate06" }, { "Wildheart Gloves", 16717, "The Unforgiven (Stratholme)", "inv_gauntlets_17" }, { "Wildheart Kilt", 16719, "Baron Rivendare (Stratholme)", "inv_pants_08" }, { "Wildheart Belt", 16716, "The Ravenian (Scholomance)", "inv_belt_15" }, { "Wildheart Bracers", 16714, "random dungeon trash (Stratholme, Scholomance, Blackrock Spire)", "inv_bracer_09" }, { "Wildheart Boots", 16715, "Mother Smolderweb (Lower Blackrock Spire)", "inv_boots_08" } } },
}

-- Dungeon Set 2 (Tier 0.5): every piece is a quest reward from the upgrade
-- chain, and the quest depends only on the slot (checked per item on Wowhead).
local DUNGEON2 = {
    { "Warrior", "Battlegear of Heroism", { { "Helm of Heroism", 21999, "the quest 'Saving the Best for Last'", "inv_helmet_02" }, { "Spaulders of Heroism", 22001, "the quest 'Anthion's Parting Words'", "inv_shoulder_30" }, { "Breastplate of Heroism", 21997, "the quest 'Saving the Best for Last'", "inv_chest_plate03" }, { "Gauntlets of Heroism", 21998, "the quest 'Just Compensation'", "inv_gauntlets_26" }, { "Legplates of Heroism", 22000, "the quest 'Anthion's Parting Words'", "inv_pants_04" }, { "Belt of Heroism", 21994, "the quest 'Just Compensation'", "inv_belt_34" }, { "Bracers of Heroism", 21996, "the quest 'An Earnest Proposition'", "inv_bracer_18" }, { "Boots of Heroism", 21995, "the quest 'Anthion's Parting Words'", "inv_boots_plate_03" } } },
    { "Paladin", "Soulforge Armor", { { "Soulforge Helm", 22091, "the quest 'Saving the Best for Last'", "inv_helmet_08" }, { "Soulforge Spaulders", 22093, "the quest 'Anthion's Parting Words'", "inv_shoulder_10" }, { "Soulforge Breastplate", 22089, "the quest 'Saving the Best for Last'", "inv_chest_plate03" }, { "Soulforge Gauntlets", 22090, "the quest 'Just Compensation'", "inv_gauntlets_19" }, { "Soulforge Legplates", 22092, "the quest 'Anthion's Parting Words'", "inv_pants_04" }, { "Soulforge Belt", 22086, "the quest 'Just Compensation'", "inv_belt_11" }, { "Soulforge Bracers", 22088, "the quest 'An Earnest Proposition'", "inv_bracer_14" }, { "Soulforge Boots", 22087, "the quest 'Anthion's Parting Words'", "inv_boots_plate_03" } } },
    { "Hunter", "Beastmaster Armor", { { "Beastmaster's Cap", 22013, "the quest 'Saving the Best for Last'", "inv_helmet_24" }, { "Beastmaster's Mantle", 22016, "the quest 'Anthion's Parting Words'", "inv_shoulder_10" }, { "Beastmaster's Tunic", 22060, "the quest 'Saving the Best for Last'", "inv_chest_chain_03" }, { "Beastmaster's Gloves", 22015, "the quest 'Just Compensation'", "inv_gauntlets_10" }, { "Beastmaster's Pants", 22017, "the quest 'Anthion's Parting Words'", "inv_pants_03" }, { "Beastmaster's Belt", 22010, "the quest 'Just Compensation'", "inv_belt_28" }, { "Beastmaster's Bindings", 22011, "the quest 'An Earnest Proposition'", "inv_bracer_17" }, { "Beastmaster's Boots", 22061, "the quest 'Anthion's Parting Words'", "inv_boots_plate_07" } } },
    { "Rogue", "Darkmantle Armor", { { "Darkmantle Cap", 22005, "the quest 'Saving the Best for Last'", "inv_helmet_41" }, { "Darkmantle Spaulders", 22008, "the quest 'Anthion's Parting Words'", "inv_shoulder_07" }, { "Darkmantle Tunic", 22009, "the quest 'Saving the Best for Last'", "inv_chest_leather_07" }, { "Darkmantle Gloves", 22006, "the quest 'Just Compensation'", "inv_gauntlets_24" }, { "Darkmantle Pants", 22007, "the quest 'Anthion's Parting Words'", "inv_pants_02" }, { "Darkmantle Belt", 22002, "the quest 'Just Compensation'", "inv_belt_03" }, { "Darkmantle Bracers", 22004, "the quest 'An Earnest Proposition'", "inv_bracer_07" }, { "Darkmantle Boots", 22003, "the quest 'Anthion's Parting Words'", "inv_boots_08" } } },
    { "Priest", "Vestments of the Virtuous", { { "Virtuous Crown", 22080, "the quest 'Saving the Best for Last'", "inv_crown_01" }, { "Virtuous Mantle", 22082, "the quest 'Anthion's Parting Words'", "inv_shoulder_02" }, { "Virtuous Robe", 22083, "the quest 'Saving the Best for Last'", "inv_chest_cloth_11" }, { "Virtuous Gloves", 22081, "the quest 'Just Compensation'", "inv_gauntlets_14" }, { "Virtuous Skirt", 22085, "the quest 'Anthion's Parting Words'", "inv_pants_08" }, { "Virtuous Belt", 22078, "the quest 'Just Compensation'", "inv_belt_10" }, { "Virtuous Bracers", 22079, "the quest 'An Earnest Proposition'", "inv_belt_31" }, { "Virtuous Sandals", 22084, "the quest 'Anthion's Parting Words'", "inv_boots_05" } } },
    { "Shaman", "The Five Thunders", { { "Coif of The Five Thunders", 22097, "the quest 'Saving the Best for Last'", "inv_helmet_04" }, { "Pauldrons of The Five Thunders", 22101, "the quest 'Anthion's Parting Words'", "inv_shoulder_29" }, { "Vest of The Five Thunders", 22102, "the quest 'Saving the Best for Last'", "inv_chest_chain_11" }, { "Gauntlets of The Five Thunders", 22099, "the quest 'Just Compensation'", "inv_gauntlets_11" }, { "Kilt of The Five Thunders", 22100, "the quest 'Anthion's Parting Words'", "inv_pants_03" }, { "Cord of The Five Thunders", 22098, "the quest 'Just Compensation'", "inv_belt_16" }, { "Bindings of The Five Thunders", 22095, "the quest 'An Earnest Proposition'", "inv_bracer_02" }, { "Boots of The Five Thunders", 22096, "the quest 'Anthion's Parting Words'", "inv_boots_wolf" } } },
    { "Mage", "Sorcerer's Regalia", { { "Sorcerer's Crown", 22065, "the quest 'Saving the Best for Last'", "inv_crown_02" }, { "Sorcerer's Mantle", 22068, "the quest 'Anthion's Parting Words'", "inv_shoulder_23" }, { "Sorcerer's Robes", 22069, "the quest 'Saving the Best for Last'", "inv_chest_cloth_25" }, { "Sorcerer's Gloves", 22066, "the quest 'Just Compensation'", "inv_gauntlets_17" }, { "Sorcerer's Leggings", 22067, "the quest 'Anthion's Parting Words'", "inv_pants_06" }, { "Sorcerer's Belt", 22062, "the quest 'Just Compensation'", "inv_belt_08" }, { "Sorcerer's Bindings", 22063, "the quest 'An Earnest Proposition'", "inv_jewelry_ring_23" }, { "Sorcerer's Boots", 22064, "the quest 'Anthion's Parting Words'", "inv_boots_02" } } },
    { "Warlock", "Deathmist Raiment", { { "Deathmist Mask", 22074, "the quest 'Saving the Best for Last'", "inv_helmet_29" }, { "Deathmist Mantle", 22073, "the quest 'Anthion's Parting Words'", "inv_misc_bone_taurenskull_01" }, { "Deathmist Robe", 22075, "the quest 'Saving the Best for Last'", "inv_chest_cloth_49" }, { "Deathmist Wraps", 22077, "the quest 'Just Compensation'", "inv_gauntlets_32" }, { "Deathmist Leggings", 22072, "the quest 'Anthion's Parting Words'", "inv_pants_08" }, { "Deathmist Belt", 22070, "the quest 'Just Compensation'", "inv_belt_12" }, { "Deathmist Bracers", 22071, "the quest 'An Earnest Proposition'", "inv_bracer_13" }, { "Deathmist Sandals", 22076, "the quest 'Anthion's Parting Words'", "inv_boots_05" } } },
    { "Druid", "Feralheart Raiment", { { "Feralheart Cowl", 22109, "the quest 'Saving the Best for Last'", "inv_helmet_27" }, { "Feralheart Spaulders", 22112, "the quest 'Anthion's Parting Words'", "inv_shoulder_01" }, { "Feralheart Vest", 22113, "the quest 'Saving the Best for Last'", "inv_chest_plate06" }, { "Feralheart Gloves", 22110, "the quest 'Just Compensation'", "inv_gauntlets_17" }, { "Feralheart Kilt", 22111, "the quest 'Anthion's Parting Words'", "inv_pants_08" }, { "Feralheart Belt", 22106, "the quest 'Just Compensation'", "inv_belt_15" }, { "Feralheart Bracers", 22108, "the quest 'An Earnest Proposition'", "inv_bracer_09" }, { "Feralheart Boots", 22107, "the quest 'Anthion's Parting Words'", "inv_boots_08" } } },
}

-- ------------------------------------------------------------
-- WoW Forever sets. Pieces are { name, item id, icon }; the builders
-- below turn them into the { name, id, source, icon } tuples above.
-- Item IDs, names and icons from Wowhead's Forever item-set pages
-- (2026-10-07). Forever gives some classes several versions of a set
-- (one per role); they look the same, so ForeverSections merges them.
-- ------------------------------------------------------------

-- The raid sets from Forever's first new raids (icons are named for Hyjal
-- Summit). Which boss drops what isn't revealed yet, so no sources.
local FOREVER_RAID = {
    { "Warrior", "Battlegear of Glory", { { "Helm of Glory", 280904, "inv_helm_plate_raidwarriorhyjalc60_d_01" }, { "Shoulders of Glory", 280903, "inv_shoulder_plate_raidwarriorhyjalc60_d_01" }, { "Breastplate of Glory", 280902, "inv_chest_plate_raidwarriorhyjalc60_d_01" }, { "Gauntlets of Glory", 280899, "inv_glove_plate_raidwarriorhyjalc60_d_01" }, { "Legplates of Glory", 280901, "inv_pant_plate_raidwarriorhyjalc60_d_01" }, { "Greaves of Glory", 280900, "inv_boot_plate_raidwarriorhyjalc60_d_01" } } },
    { "Warrior", "Battleplate of Glory", { { "Greathelm of Glory", 280910, "inv_helm_plate_raidwarriorhyjalc60_d_01" }, { "Pauldrons of Glory", 280909, "inv_shoulder_plate_raidwarriorhyjalc60_d_01" }, { "Chestguard of Glory", 280908, "inv_chest_plate_raidwarriorhyjalc60_d_01" }, { "Handguards of Glory", 280905, "inv_glove_plate_raidwarriorhyjalc60_d_01" }, { "Legguards of Glory", 280907, "inv_pant_plate_raidwarriorhyjalc60_d_01" }, { "Sabatons of Glory", 280906, "inv_boot_plate_raidwarriorhyjalc60_d_01" } } },
    { "Paladin", "Justice Armor", { { "Justice Headpiece", 280936, "inv_helm_plate_raidpaladinhyjalc60_d_01" }, { "Justice Epaulets", 280935, "inv_shoulder_plate_raidpaladinhyjalc60_d_01" }, { "Justice Tunic", 280934, "inv_chest_plate_raidpaladinhyjalc60_d_01" }, { "Justice Gloves", 280931, "inv_glove_plate_raidpaladinhyjalc60_d_01" }, { "Justice Legplates", 280933, "inv_pant_plate_raidpaladinhyjalc60_d_01" }, { "Justice Treads", 280932, "inv_boot_plate_raidpaladinhyjalc60_d_01" } } },
    { "Paladin", "Justice Battlegear", { { "Justice Crown", 280930, "inv_helm_plate_raidpaladinhyjalc60_d_01" }, { "Justice Spaulders", 280929, "inv_shoulder_plate_raidpaladinhyjalc60_d_01" }, { "Justice Breastplate", 280928, "inv_chest_plate_raidpaladinhyjalc60_d_01" }, { "Justice Gauntlets", 280925, "inv_glove_plate_raidpaladinhyjalc60_d_01" }, { "Justice Leggings", 280927, "inv_pant_plate_raidpaladinhyjalc60_d_01" }, { "Justice Greaves", 280926, "inv_boot_plate_raidpaladinhyjalc60_d_01" } } },
    { "Paladin", "Justice Battleplate", { { "Justice Greathelm", 280937, "inv_helm_plate_raidpaladinhyjalc60_d_01" }, { "Justice Pauldrons", 280942, "inv_shoulder_plate_raidpaladinhyjalc60_d_01" }, { "Justice Chestguard", 280941, "inv_chest_plate_raidpaladinhyjalc60_d_01" }, { "Justice Handguards", 280938, "inv_glove_plate_raidpaladinhyjalc60_d_01" }, { "Justice Legguards", 280940, "inv_pant_plate_raidpaladinhyjalc60_d_01" }, { "Justice Sabatons", 280939, "inv_boot_plate_raidpaladinhyjalc60_d_01" } } },
    { "Hunter", "Wildstalker Armor", { { "Wildstalker's Helm", 280898, "inv_helm_mail_raidhunterhyjalc60_d_01" }, { "Wildstalker's Spaulders", 280897, "inv_shoulder_l_mail_raidhunterhyjalc60_d_01" }, { "Wildstalker's Breastplate", 280896, "inv_chest_mail_raidhunterhyjalc60_d_01" }, { "Wildstalker's Gauntlets", 280893, "inv_glove_mail_raidhunterhyjalc60_d_01" }, { "Wildstalker's Legguards", 280895, "inv_pant_mail_raidhunterhyjalc60_d_01" }, { "Wildstalker's Greaves", 280894, "inv_boot_mail_raidhunterhyjalc60_d_01" } } },
    { "Rogue", "Grimstitch Armor", { { "Grimstitch Mask", 280877, "inv_helm_leather_raidroguehyjalc60_d_01" }, { "Grimstitch Spaulders", 280876, "inv_shoulder_leather_raidroguehyjalc60_d_01" }, { "Grimstitch Chestpiece", 280879, "inv_robe_leather_raidroguehyjalc60_d_01" }, { "Grimstitch Gloves", 280875, "inv_glove_leather_raidroguehyjalc60_d_01" }, { "Grimstitch Pants", 280872, "inv_pant_leather_raidroguehyjalc60_d_01" }, { "Grimstitch Boots", 280878, "inv_boot_leather_raidroguehyjalc60_d_01" } } },
    { "Priest", "Vestments of Conviction", { { "Halo of Conviction", 280918, "inv_helm_cloth_raidpriesthyjalc60_d_01" }, { "Pauldrons of Conviction", 280917, "inv_shoulder_r_cloth_raidpriesthyjalc60_d_01" }, { "Robes of Conviction", 280912, "inv_robe_cloth_raidpriesthyjalc60_d_01" }, { "Handguards of Conviction", 280913, "inv_glove_cloth_raidpriesthyjalc60_d_01" }, { "Leggings of Conviction", 280915, "inv_pant_cloth_raidpriesthyjalc60_d_01" }, { "Boots of Conviction", 280914, "inv_boot_cloth_raidpriesthyjalc60_d_01" } } },
    { "Priest", "Raiments of Conviction", { { "Crown of Conviction", 280924, "inv_helm_cloth_raidpriesthyjalc60_d_01" }, { "Mantle of Conviction", 280923, "inv_shoulder_r_cloth_raidpriesthyjalc60_d_01" }, { "Garb of Conviction", 280919, "inv_robe_cloth_raidpriesthyjalc60_d_01" }, { "Gloves of Conviction", 280920, "inv_glove_cloth_raidpriesthyjalc60_d_01" }, { "Pants of Conviction", 280922, "inv_pant_cloth_raidpriesthyjalc60_d_01" }, { "Treads of Conviction", 280921, "inv_boot_cloth_raidpriesthyjalc60_d_01" } } },
    { "Shaman", "The Spiritcaller", { { "Spiritcaller Helmet", 280951, "inv_helm_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Epaulets", 280944, "inv_shoulder_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Breastplate", 280950, "inv_chest_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Gauntlets", 280949, "inv_glove_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Pants", 280947, "inv_pant_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Greaves", 280945, "inv_boot_mail_raidshamanhyjalc60_d_01" } } },
    { "Shaman", "The Spiritcaller's Rage", { { "Spiritcaller Crown", 280957, "inv_helm_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Spaulders", 280956, "inv_shoulder_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Armor", 280955, "inv_chest_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Grips", 280952, "inv_glove_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Leggings", 280954, "inv_pant_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Treads", 280953, "inv_boot_mail_raidshamanhyjalc60_d_01" } } },
    { "Shaman", "The Spiritcaller's Storm", { { "Spiritcaller Headdress", 280963, "inv_helm_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Mantle", 280962, "inv_shoulder_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Embrace", 280961, "inv_chest_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Gloves", 280958, "inv_glove_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Kilt", 280960, "inv_pant_mail_raidshamanhyjalc60_d_01" }, { "Spiritcaller Boots", 280959, "inv_boot_mail_raidshamanhyjalc60_d_01" } } },
    { "Mage", "Manaflare Regalia", { { "Manaflare Crown", 280455, "inv_helm_cloth_raidmagehyjalc60_d_01" }, { "Manaflare Mantle", 280454, "inv_shoulder_cloth_raidmagehyjalc60_d_01" }, { "Manaflare Robes", 280450, "inv_chest_cloth_raidmagehyjalc60_d_01" }, { "Manaflare Gloves", 280451, "inv_glove_cloth_raidmagehyjalc60_d_01" }, { "Manaflare Pants", 280453, "inv_pant_cloth_raidmagehyjalc60_d_01" }, { "Manaflare Boots", 280452, "inv_boot_cloth_raidmagehyjalc60_d_01" } } },
    { "Warlock", "Demonheart Raiment", { { "Demonheart Skullcap", 280887, "inv_helm_cloth_raidwarlockhyjalc60_d_01" }, { "Demonheart Spaulders", 280882, "inv_shoulder_cloth_raidwarlockhyjalc60_d_01" }, { "Demonheart Robes", 280883, "inv_chest_cloth_raidwarlockhyjalc60_d_01" }, { "Demonheart Gloves", 280888, "inv_glove_cloth_raidwarlockhyjalc60_d_01" }, { "Demonheart Leggings", 280886, "inv_pant_cloth_raidwarlockhyjalc60_d_01" }, { "Demonheart Boots", 280889, "inv_boot_cloth_raidwarlockhyjalc60_d_01" } } },
    { "Druid", "Grovekeeper Raiment", { { "Grovekeeper Cover", 280977, "inv_helm_leather_raiddruidhyjalc60_d_01" }, { "Grovekeeper Pauldrons", 280976, "inv_shoulder_leather_raiddruidhyjalc60_d_01" }, { "Grovekeeper Chestguard", 280974, "inv_robe_leather_raiddruidhyjalc60_d_01" }, { "Grovekeeper Handguards", 280965, "inv_glove_leather_raiddruidhyjalc60_d_01" }, { "Grovekeeper Legguards", 280971, "inv_pant_leather_raiddruidhyjalc60_d_01" }, { "Grovekeeper Boots", 280967, "inv_boot_leather_raiddruidhyjalc60_d_01" } } },
}

-- Forever's PvP sets ("Premier ..." pieces). The rank in each piece's name
-- is the PvP rank that unlocks it; PvpSections turns it into the source.
-- A trailing true marks sets new in Forever (Horde Paladins, Alliance
-- Shamans, and the extra role versions for Priests, Druids and Shamans).
local PVP_ALLY_PLATE = {
    { "Warrior", "Field Marshal's Battlegear", { { "Premier Field Marshal's Plate Helm", 272787, "inv_helmet_05" }, { "Premier Marshal's Plate Shoulderguards", 272789, "inv_shoulder_20" }, { "Premier Field Marshal's Plate Armor", 272786, "inv_chest_plate03" }, { "Premier Lieutenant Commander's Plate Gauntlets", 272793, "inv_gauntlets_29" }, { "Premier Marshal's Plate Legguards", 272788, "inv_pants_04" }, { "Premier Knight-Champion's Plate Boots", 272792, "inv_boots_plate_09" } } },
    { "Paladin", "Field Marshal's Aegis", { { "Premier Field Marshal's Luminous Faceguard", 273332, "inv_helmet_05" }, { "Premier Marshal's Luminous Pauldrons", 273334, "inv_shoulder_20" }, { "Premier Field Marshal's Luminous Chestplate", 273331, "inv_chest_plate03" }, { "Premier Lieutenant Commander's Luminous Gloves", 273329, "inv_gauntlets_29" }, { "Premier Marshal's Luminous Legplates", 273333, "inv_pants_04" }, { "Premier Knight-Champion's Luminous Boots", 273330, "inv_boots_plate_09" } } },
    { "Paladin", "Field Marshal's Vindication", { { "Premier Field Marshal's Chevalier Faceguard", 272783, "inv_helmet_05" }, { "Premier Marshal's Chevalier Pauldrons", 272785, "inv_shoulder_20" }, { "Premier Field Marshal's Chevalier Chestplate", 272782, "inv_chest_plate03" }, { "Premier Lieutenant Commander's Chevalier Gloves", 272780, "inv_gauntlets_29" }, { "Premier Marshal's Chevalier Legplates", 272784, "inv_pants_04" }, { "Premier Knight-Champion's Chevalier Boots", 272781, "inv_boots_plate_09" } }, true },
}
local PVP_ALLY_MAIL = {
    { "Hunter", "Field Marshal's Pursuit", { { "Premier Field Marshal's Chainmail Helm", 272774, "inv_helmet_05" }, { "Premier Marshal's Chainmail Spaulders", 272777, "inv_shoulder_10" }, { "Premier Field Marshal's Chainmail Breastplate", 272775, "inv_chest_chain_03" }, { "Premier Lieutenant Commander's Chainmail Grips", 272772, "inv_gauntlets_10" }, { "Premier Marshal's Chainmail Legguards", 272776, "inv_pants_mail_17" }, { "Premier Knight-Champion's Chainmail Boots", 272771, "inv_boots_plate_07" } } },
    { "Shaman", "Field Marshal's Earthshaker", { { "Premier Field Marshal's Flatmail Helm", 274188, "inv_helmet_09" }, { "Premier Marshal's Flatmail Spaulders", 274190, "inv_shoulder_29" }, { "Premier Field Marshal's Flatmail Armor", 274187, "inv_chest_chain_11" }, { "Premier Lieutenant Commander's Flatmail Gauntlets", 274184, "inv_gauntlets_11" }, { "Premier Marshal's Flatmail Leggings", 274189, "inv_pants_mail_15" }, { "Premier Knight-Champion's Flatmail Boots", 274183, "inv_boots_plate_06" } }, true },
    { "Shaman", "Field Marshal's Thunderfist", { { "Premier Field Marshal's Scalemail Helm", 274203, "inv_helmet_09" }, { "Premier Marshal's Scalemail Spaulders", 274205, "inv_shoulder_29" }, { "Premier Field Marshal's Scalemail Armor", 274202, "inv_chest_chain_11" }, { "Premier Lieutenant Commander's Scalemail Gauntlets", 274199, "inv_gauntlets_11" }, { "Premier Marshal's Scalemail Leggings", 274204, "inv_pants_mail_15" }, { "Premier Knight-Champion's Scalemail Boots", 274198, "inv_boots_plate_06" } }, true },
    { "Shaman", "Field Marshal's Wartide", { { "Premier Field Marshal's Linkmail Helm", 274211, "inv_helmet_09" }, { "Premier Marshal's Linkmail Spaulders", 274213, "inv_shoulder_29" }, { "Premier Field Marshal's Linkmail Armor", 274210, "inv_chest_chain_11" }, { "Premier Lieutenant Commander's Linkmail Gauntlets", 274207, "inv_gauntlets_11" }, { "Premier Marshal's Linkmail Leggings", 274212, "inv_pants_mail_15" }, { "Premier Knight-Champion's Linkmail Boots", 274206, "inv_boots_plate_06" } }, true },
}
local PVP_ALLY_LEATHER = {
    { "Rogue", "Field Marshal's Vestments", { { "Premier Field Marshal's Leather Mask", 272764, "inv_helmet_41" }, { "Premier Marshal's Leather Epaulets", 272766, "inv_shoulder_23" }, { "Premier Field Marshal's Leather Chestpiece", 272762, "inv_chest_cloth_07" }, { "Premier Lieutenant Commander's Leather Handgrips", 272763, "inv_gauntlets_21" }, { "Premier Marshal's Leather Leggings", 272765, "inv_pants_06" }, { "Premier Knight-Champion's Leather Footguards", 272755, "inv_boots_08" } } },
    { "Druid", "Field Marshal's Sanctuary", { { "Premier Field Marshal's Beasthide Helmet", 272760, "inv_helmet_41" }, { "Premier Marshal's Beasthide Spaulders", 272758, "inv_shoulder_23" }, { "Premier Field Marshal's Beasthide Breastplate", 272761, "inv_chest_cloth_07" }, { "Premier Lieutenant Commander's Beasthide Gauntlets", 272757, "inv_gauntlets_21" }, { "Premier Marshal's Beasthide Legguards", 272759, "inv_pants_06" }, { "Premier Knight-Champion's Beasthide Boots", 272768, "inv_boots_08" } } },
    { "Druid", "Field Marshal's Refuge", { { "Premier Field Marshal's Dreamhide Helmet", 273402, "inv_helmet_41" }, { "Premier Marshal's Dreamhide Spaulders", 273400, "inv_shoulder_23" }, { "Premier Field Marshal's Dreamhide Breastplate", 273403, "inv_chest_cloth_07" }, { "Premier Lieutenant Commander's Dreamhide Gauntlets", 273399, "inv_gauntlets_21" }, { "Premier Marshal's Dreamhide Legguards", 273401, "inv_pants_06" }, { "Premier Knight-Champion's Dreamhide Boots", 273404, "inv_boots_08" } }, true },
    { "Druid", "Field Marshal's Wildhide", { { "Premier Field Marshal's Lunarhide Helmet", 273394, "inv_helmet_41" }, { "Premier Marshal's Lunarhide Spaulders", 273392, "inv_shoulder_23" }, { "Premier Field Marshal's Lunarhide Breastplate", 273395, "inv_chest_cloth_07" }, { "Premier Lieutenant Commander's Lunarhide Gauntlets", 273391, "inv_gauntlets_21" }, { "Premier Marshal's Lunarhide Legguards", 273393, "inv_pants_06" }, { "Premier Knight-Champion's Lunarhide Boots", 273396, "inv_boots_08" } }, true },
}
local PVP_ALLY_CLOTH = {
    { "Priest", "Field Marshal's Raiment", { { "Premier Field Marshal's Voidcloth Headdress", 272818, "inv_helmet_24" }, { "Premier Marshal's Voidcloth Mantle", 272820, "inv_shoulder_02" }, { "Premier Field Marshal's Voidcloth Vestments", 272821, "inv_chest_cloth_02" }, { "Premier Lieutenant Commander's Voidcloth Gloves", 272824, "inv_gauntlets_14" }, { "Premier Marshal's Voidcloth Pants", 272819, "inv_pants_06" }, { "Premier Knight-Champion's Voidcloth Sandals", 272823, "inv_boots_07" } } },
    { "Priest", "Field Marshal's Investiture", { { "Premier Field Marshal's Mooncloth Headdress", 273421, "inv_helmet_24" }, { "Premier Marshal's Mooncloth Mantle", 273423, "inv_shoulder_02" }, { "Premier Field Marshal's Mooncloth Vestments", 273424, "inv_chest_cloth_02" }, { "Premier Lieutenant Commander's Mooncloth Gloves", 273427, "inv_gauntlets_14" }, { "Premier Marshal's Mooncloth Pants", 273422, "inv_pants_06" }, { "Premier Knight-Champion's Mooncloth Sandals", 273426, "inv_boots_07" } }, true },
    { "Mage", "Field Marshal's Regalia", { { "Premier Field Marshal's Silk Coronet", 272750, "inv_helmet_24" }, { "Premier Marshal's Silk Spaulders", 272753, "inv_shoulder_23" }, { "Premier Field Marshal's Silk Vestments", 272752, "inv_chest_cloth_12" }, { "Premier Lieutenant Commander's Silk Gloves", 272749, "inv_gauntlets_14" }, { "Premier Marshal's Silk Leggings", 272751, "inv_pants_08" }, { "Premier Knight-Champion's Silk Footwraps", 272746, "inv_boots_cloth_03" } } },
    { "Warlock", "Field Marshal's Threads", { { "Premier Field Marshal's Dreadweave Coronal", 272802, "inv_helmet_24" }, { "Premier Marshal's Dreadweave Shoulders", 272804, "inv_shoulder_02" }, { "Premier Field Marshal's Dreadweave Robe", 272805, "inv_chest_cloth_09" }, { "Premier Lieutenant Commander's Dreadweave Gloves", 272808, "inv_gauntlets_14" }, { "Premier Marshal's Dreadweave Leggings", 272803, "inv_pants_cloth_09" }, { "Premier Knight-Champion's Dreadweave Boots", 272807, "inv_boots_07" } } },
}
local PVP_HORDE_PLATE = {
    { "Warrior", "Warlord's Battlegear", { { "Premier Warlord's Mortarplate Headpiece", 272507, "inv_helmet_09" }, { "Premier General's Mortarplate Shoulders", 272509, "inv_shoulder_11" }, { "Premier Warlord's Mortarplate Armor", 272506, "inv_chest_plate16" }, { "Premier Champion's Mortarplate Gauntlets", 272513, "inv_gauntlets_10" }, { "Premier General's Mortarplate Leggings", 272508, "inv_pants_04" }, { "Premier Centurion's Mortarplate Boots", 272510, "inv_boots_plate_04" } } },
    { "Paladin", "Warlord's Aegis", { { "Premier Warlord's Lamellar Faceguard", 274253, "inv_helmet_05" }, { "Premier General's Lamellar Pauldrons", 274255, "inv_shoulder_20" }, { "Premier Warlord's Lamellar Chestplate", 274252, "inv_chest_plate03" }, { "Premier Champion's Lamellar Gloves", 274250, "inv_gauntlets_29" }, { "Premier General's Lamellar Legplates", 274254, "inv_pants_04" }, { "Premier Centurion's Lamellar Boots", 274251, "inv_boots_plate_09" } }, true },
    { "Paladin", "Warlord's Vindication", { { "Premier Warlord's Scaled Faceguard", 274239, "inv_helmet_05" }, { "Premier General's Scaled Pauldrons", 274241, "inv_shoulder_20" }, { "Premier Warlord's Scaled Chestplate", 274238, "inv_chest_plate03" }, { "Premier Champion's Scaled Gloves", 274236, "inv_gauntlets_29" }, { "Premier General's Scaled Legplates", 274240, "inv_pants_04" }, { "Premier Centurion's Scaled Boots", 274237, "inv_boots_plate_09" } }, true },
}
local PVP_HORDE_MAIL = {
    { "Hunter", "Warlord's Pursuit", { { "Premier Warlord's Chain Helmet", 272531, "inv_helmet_09" }, { "Premier General's Chain Shoulders", 272533, "inv_shoulder_29" }, { "Premier Warlord's Chain Chestpiece", 272530, "inv_chest_chain_11" }, { "Premier Champion's Chain Gloves", 272536, "inv_gauntlets_11" }, { "Premier General's Chain Legguards", 272532, "inv_pants_mail_16" }, { "Premier Centurion's Chain Sabatons", 272534, "inv_boots_plate_06" } } },
    { "Shaman", "Warlord's Earthshaker", { { "Premier Warlord's Linked Helm", 272543, "inv_helmet_09" }, { "Premier General's Linked Spaulders", 272545, "inv_shoulder_29" }, { "Premier Warlord's Linked Armor", 272542, "inv_chest_chain_11" }, { "Premier Champion's Linked Gauntlets", 272539, "inv_gauntlets_11" }, { "Premier General's Linked Leggings", 272544, "inv_pants_mail_15" }, { "Premier Centurion's Linked Boots", 272538, "inv_boots_plate_06" } } },
    { "Shaman", "Warlord's Thunderfist", { { "Premier Warlord's Mail Helm", 273341, "inv_helmet_09" }, { "Premier General's Mail Spaulders", 273343, "inv_shoulder_29" }, { "Premier Warlord's Mail Armor", 273340, "inv_chest_chain_11" }, { "Premier Champion's Mail Gauntlets", 273337, "inv_gauntlets_11" }, { "Premier General's Mail Leggings", 273342, "inv_pants_mail_15" }, { "Premier Centurion's Mail Boots", 273336, "inv_boots_plate_06" } }, true },
    { "Shaman", "Warlord's Wartide", { { "Premier Warlord's Ringmail Helm", 273349, "inv_helmet_09" }, { "Premier General's Ringmail Spaulders", 273351, "inv_shoulder_29" }, { "Premier Warlord's Ringmail Armor", 273348, "inv_chest_chain_11" }, { "Premier Champion's Ringmail Gauntlets", 273345, "inv_gauntlets_11" }, { "Premier General's Ringmail Leggings", 273350, "inv_pants_mail_15" }, { "Premier Centurion's Ringmail Boots", 273344, "inv_boots_plate_06" } }, true },
}
local PVP_HORDE_LEATHER = {
    { "Rogue", "Warlord's Vestments", { { "Premier Warlord's Shadowhide Helm", 272526, "inv_helmet_09" }, { "Premier General's Shadowhide Spaulders", 272527, "inv_shoulder_07" }, { "Premier Warlord's Shadowhide Breastplate", 272528, "inv_chest_chain_16" }, { "Premier Champion's Shadowhide Mitts", 272525, "inv_gauntlets_25" }, { "Premier General's Shadowhide Legguards", 272529, "inv_pants_06" }, { "Premier Centurion's Shadowhide Treads", 272523, "inv_boots_08" } } },
    { "Druid", "Warlord's Sanctuary", { { "Premier Warlord's Dragonhide Helmet", 272515, "inv_helmet_09" }, { "Premier General's Dragonhide Epaulets", 272516, "inv_shoulder_07" }, { "Premier Warlord's Dragonhide Hauberk", 272514, "inv_chest_chain_16" }, { "Premier Champion's Dragonhide Gloves", 272520, "inv_gauntlets_25" }, { "Premier General's Dragonhide Leggings", 272517, "inv_pants_06" }, { "Premier Centurion's Dragonhide Boots", 272519, "inv_boots_08" } } },
    { "Druid", "Warlord's Refuge", { { "Premier Warlord's Kodohide Helmet", 273414, "inv_helmet_09" }, { "Premier General's Kodohide Epaulets", 273415, "inv_shoulder_07" }, { "Premier Warlord's Kodohide Hauberk", 273413, "inv_chest_chain_16" }, { "Premier Champion's Kodohide Gloves", 273419, "inv_gauntlets_25" }, { "Premier General's Kodohide Leggings", 273416, "inv_pants_06" }, { "Premier Centurion's Kodohide Boots", 273418, "inv_boots_08" } }, true },
    { "Druid", "Warlord's Wildhide", { { "Premier Warlord's Wyrmhide Helmet", 273406, "inv_helmet_09" }, { "Premier General's Wyrmhide Epaulets", 273407, "inv_shoulder_07" }, { "Premier Warlord's Wyrmhide Hauberk", 273405, "inv_chest_chain_16" }, { "Premier Champion's Wyrmhide Gloves", 273411, "inv_gauntlets_25" }, { "Premier General's Wyrmhide Leggings", 273408, "inv_pants_06" }, { "Premier Centurion's Wyrmhide Boots", 273410, "inv_boots_08" } }, true },
}
local PVP_HORDE_CLOTH = {
    { "Priest", "Warlord's Raiment", { { "Premier Warlord's Satin Cowl", 272575, "inv_helmet_08" }, { "Premier General's Satin Mantle", 272574, "inv_shoulder_19" }, { "Premier Warlord's Satin Robes", 272576, "inv_chest_leather_01" }, { "Premier Champion's Satin Gloves", 272572, "inv_gauntlets_27" }, { "Premier General's Satin Leggings", 272577, "inv_pants_07" }, { "Premier Centurion's Satin Boots", 272570, "inv_boots_05" } } },
    { "Priest", "Warlord's Investiture", { { "Premier Warlord's Silken Cowl", 273434, "inv_helmet_08" }, { "Premier General's Silken Mantle", 273433, "inv_shoulder_19" }, { "Premier Warlord's Silken Robes", 273435, "inv_chest_leather_01" }, { "Premier Champion's Silken Gloves", 273431, "inv_gauntlets_27" }, { "Premier General's Silken Leggings", 273436, "inv_pants_07" }, { "Premier Centurion's Silken Boots", 273429, "inv_boots_05" } }, true },
    { "Mage", "Warlord's Regalia", { { "Premier Warlord's Magus Cowl", 272498, "inv_helmet_08" }, { "Premier General's Magus Amice", 272501, "inv_shoulder_19" }, { "Premier Warlord's Magus Raiment", 272500, "inv_chest_leather_01" }, { "Premier Champion's Magus Handguards", 272505, "inv_gauntlets_19" }, { "Premier General's Magus Trousers", 272499, "inv_pants_07" }, { "Premier Centurion's Magus Boots", 272504, "inv_boots_05" } } },
    { "Warlock", "Warlord's Threads", { { "Premier Warlord's Felweave Hood", 272559, "inv_helmet_08" }, { "Premier General's Felweave Mantle", 272558, "inv_shoulder_19" }, { "Premier Warlord's Felweave Robe", 272560, "inv_chest_leather_01" }, { "Premier Champion's Felweave Gloves", 272556, "inv_gauntlets_19" }, { "Premier General's Felweave Pants", 272561, "inv_pants_07" }, { "Premier Centurion's Felweave Boots", 272554, "inv_boots_05" } } },
}

-- { name, id, icon } pieces -> BuildSetSections tuples. With rank = true,
-- the source is the PvP rank named in the piece ("Premier Marshal's ...").
local PVP_RANKS = {
    { "Field Marshal's", "PvP rank 13 (Field Marshal)" }, { "Marshal's", "PvP rank 12 (Marshal)" },
    { "Lieutenant Commander's", "PvP rank 10 (Lieutenant Commander)" }, { "Knight%-Champion's", "PvP rank 9 (Knight-Champion)" },
    { "Warlord's", "PvP rank 13 (Warlord)" }, { "General's", "PvP rank 12 (General)" },
    { "Champion's", "PvP rank 10 (Champion)" }, { "Centurion's", "PvP rank 9 (Centurion)" },
}
-- A class's versions of a set look the same (only the stats differ), so
-- they become ONE part (Karl, 2026-10-07): named after the class's first
-- version, and each piece ticks from that slot's piece in ANY version
-- (pieces are listed in the same slot order in every version). The part
-- is NEW only when every version is new in Forever.
local function ForeverSections(list, rank)
    local out, byClass = {}, {}
    for _, set in ipairs(list) do
        local class = set[1]
        local merged = byClass[class]
        if not merged then
            merged = { class, set[2], {}, set[4] }
            byClass[class] = merged
            table.insert(out, merged)
        elseif not set[4] then
            merged[4] = nil
        end
        for i, p in ipairs(set[3]) do
            local piece = merged[3][i]
            if not piece then
                local source
                if rank then
                    -- the rank right after "Premier " (Field Marshal's before Marshal's)
                    local after = p[1]:gsub("^Premier ", "")
                    for _, r in ipairs(PVP_RANKS) do
                        if after:find("^" .. r[1]) then source = r[2] break end
                    end
                end
                piece = { p[1], {}, source, p[3], {} }
                merged[3][i] = piece
            end
            table.insert(piece[2], p[2])
            table.insert(piece[5], p[1])
        end
    end
    local sections = BuildSetSections(out)
    -- every version's item ID and name counts for the piece
    for si, set in ipairs(out) do
        for pi, p in ipairs(set[3]) do
            sections[si].pieces[pi].auto = { item = p[2], owned = p[5] }
        end
    end
    return sections
end

-- The eight PvP set goals: faction x armor type, each class's sets as parts.
local PVP_SET_GOALS = {
    { "ally", "Alliance", "Field Marshal's", "Plate", "Warriors and Paladins", PVP_ALLY_PLATE, "inv_helmet_05" },
    { "ally", "Alliance", "Field Marshal's", "Mail", "Hunters and Shamans", PVP_ALLY_MAIL, "inv_helmet_09" },
    { "ally", "Alliance", "Field Marshal's", "Leather", "Rogues and Druids", PVP_ALLY_LEATHER, "inv_helmet_41" },
    { "ally", "Alliance", "Field Marshal's", "Cloth", "Priests, Mages and Warlocks", PVP_ALLY_CLOTH, "inv_helmet_24" },
    { "horde", "Horde", "Warlord's", "Plate", "Warriors and Paladins", PVP_HORDE_PLATE, "inv_helmet_09" },
    { "horde", "Horde", "Warlord's", "Mail", "Hunters and Shamans", PVP_HORDE_MAIL, "inv_helmet_09" },
    { "horde", "Horde", "Warlord's", "Leather", "Rogues and Druids", PVP_HORDE_LEATHER, "inv_helmet_09" },
    { "horde", "Horde", "Warlord's", "Cloth", "Priests, Mages and Warlocks", PVP_HORDE_CLOTH, "inv_helmet_08" },
}

local sets = {
    {
        id = "set_tier1", library = true, group = true,
        itemQuality = 4, -- piece names' color when the game doesn't know the item
        -- On Wowhead Forever the set exists but its pieces are hidden ("Item
        -- #16846 doesn't exist"): not revealed yet, not removed (2026-10-07;
        -- an earlier "removed" call misread that message)
        icon = "inv_helmet_09",
        name = "Tier 1 Set Appearances",
        short = "Tier 1 Sets",
        category = "Item Set", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "The Molten Core sets. Most pieces drop from Molten Core bosses; belts and bracers come from Molten Core trash. Pick the classes you want in the Library; each piece ticks itself when you own it.",
        sections = BuildSetSections(TIER1),
    },
    {
        id = "set_tier2", library = true, group = true,
        itemQuality = 4, -- piece names' color when the game doesn't know the item
        -- On Wowhead Forever the set exists but its pieces are hidden ("Item
        -- #16846 doesn't exist"): not revealed yet, not removed (2026-10-07;
        -- an earlier "removed" call misread that message)
        icon = "inv_helmet_71",
        name = "Tier 2 Set Appearances",
        short = "Tier 2 Sets",
        category = "Item Set", difficulty = "Very Hard",
        timeEstimate = "3+ Months",
        note = "Helms come from Onyxia, legs from Ragnaros, and the rest from Blackwing Lair. Pick the classes you want in the Library; each piece ticks itself when you own it.",
        sections = BuildSetSections(TIER2),
    },
    {
        id = "set_dungeon1", library = true, group = true,
        itemQuality = 3, -- piece names' color when the game doesn't know the item
        icon = "inv_helmet_02",
        name = "Dungeon Set 1 (Tier 0)",
        short = "Dungeon Set 1",
        category = "Item Set", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "The blue level-60 dungeon sets from Scholomance, Stratholme and Blackrock Spire. Pick the classes you want in the Library; each piece ticks itself when you own it.",
        sections = BuildSetSections(DUNGEON1),
        tips = {
            "Darkmaster Gandling, General Drakkisath and Baron Rivendare drop the helm, chest and legs for every class, so those three runs are worth repeating.",
            "Most belts and bracers are random trash drops, so they can turn up in any of the three dungeons.",
        },
    },
    {
        id = "set_dungeon2", library = true, group = true,
        itemQuality = 3, -- piece names' color when the game doesn't know the item
        icon = "inv_helmet_08",
        name = "Dungeon Set 2 (Tier 0.5)",
        short = "Dungeon Set 2",
        category = "Item Set", difficulty = "Very Hard",
        timeEstimate = "1-2 Months",
        note = "The upgraded dungeon sets. Every piece comes from a long quest chain that trades in your Dungeon Set 1 pieces plus materials and gold. The chain starts with 'An Earnest Proposition' from Deliana in Ironforge (Alliance) or Mokvar in Orgrimmar (Horde). Pick the classes you want in the Library; each piece ticks itself when you own it.",
        sections = BuildSetSections(DUNGEON2),
        tips = {
            "The chain starts with 'An Earnest Proposition' (bracers), then 'Just Compensation' (belt and gloves), 'Anthion's Parting Words' (shoulders, legs, boots) and 'Saving the Best for Last' (helm and chest).",
            "Keep your Dungeon Set 1 pieces: each upgrade quest needs the matching Set 1 piece.",
        },
    },
    {
        -- Updated in Warcraft Forever: same pieces, new set bonuses (Wowhead
        -- Forever, item-set=162, 2026-10-06) and the druid serpent form.
        id = "set_viper", library = true, forever = "updated",
        icon = "inv_shirt_16",
        name = "Embrace of the Viper",
        short = "Viper Set",
        category = "Item Set", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "A five-piece leather set from Wailing Caverns.",
        foreverNote = "Updated in WoW Forever with a new set bonus that turns you into a snake.",
        steps = {
            { text = "Loot Armor of the Fang from Lord Pythas.", icon = "inv_shirt_16", auto = { item = 6473, owned = { "Armor of the Fang" } } },
            { text = "Loot Leggings of the Fang from Lord Cobrahn.", icon = "inv_pants_11", auto = { item = 10410, owned = { "Leggings of the Fang" } } },
            { text = "Loot Footpads of the Fang from Lord Serpentis.", icon = "inv_boots_04", auto = { item = 10411, owned = { "Footpads of the Fang" } } },
            { text = "Loot Belt of the Fang from Lady Anacondra.", icon = "inv_belt_30", auto = { item = 10412, owned = { "Belt of the Fang" } } },
            { text = "Loot Gloves of the Fang from Druids of the Fang (rare).", icon = "inv_gauntlets_18", auto = { item = 10413, owned = { "Gloves of the Fang" } } },
        },
    },
    {
        -- New in WoW Forever (Karl, 2026-10-07): the class sets of the first
        -- new raids, early in raiding (around Onyxia). Don't mention the item
        -- level Wowhead shows; max level is 60.
        id = "set_forever_raid", library = true, group = true, forever = "new",
        itemQuality = 4,
        icon = "inv_helm_plate_raidwarriorhyjalc60_d_01",
        name = "Forever Raid Set Appearances",
        short = "Forever Raid Sets",
        category = "Item Set", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "The new class sets from WoW Forever's first new raids, Hyjal Summit and the Barrow Deeps, which open December 9, 2026. Pick the sets you want in the Library; each piece ticks itself when you own it.",
        foreverNote = "Which boss drops each piece isn't revealed yet; sources are added as they are.",
        sections = ForeverSections(FOREVER_RAID),
    },
    {
        -- Wowhead Forever item-set 2134 and all five item pages, 2026-10-09.
        -- Only the Mantle and Robes have revealed drop sources so far.
        id = "set_violet_sorcerer", library = true, forever = "new", needs = "forever",
        itemQuality = 3,
        icon = "inv_chest_cloth_25",
        name = "Violet Sorcerer's Vestments",
        short = "Violet Sorcerer's",
        category = "Item Set", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "Collect the five pieces of this new cloth set in Warcraft Forever. Each piece ticks itself when you own it.",
        foreverNote = "A new five-piece set with mana regeneration and an Arcane elemental summon bonus. Sources for the Leggings, Sandals and Wraps are not revealed yet.",
        steps = {
            { text = "Loot Violet Sorcerer's Mantle from Shade of the Archmage in the City of Dalaran.", icon = "inv_shoulder_02",
              auto = { item = 273051, owned = { "Violet Sorcerer's Mantle" } } },
            { text = "Loot Violet Sorcerer's Robes from Arcanic Enigma in the City of Dalaran.", icon = "inv_chest_cloth_25",
              auto = { item = 273044, owned = { "Violet Sorcerer's Robes" } } },
            { text = "Collect Violet Sorcerer's Leggings.", icon = "inv_pants_06",
              auto = { item = 286988, owned = { "Violet Sorcerer's Leggings" } } },
            { text = "Collect Violet Sorcerer's Sandals.", icon = "inv_boots_05",
              auto = { item = 286987, owned = { "Violet Sorcerer's Sandals" } } },
            { text = "Collect Violet Sorcerer's Wraps.", icon = "inv_gauntlets_06",
              auto = { item = 286989, owned = { "Violet Sorcerer's Wraps" } } },
        },
        tips = {
            "{item:273051:Violet Sorcerer's Mantle} and {item:273044:Violet Sorcerer's Robes} bind on pickup. The other three pieces bind on equip, so they can be traded before being equipped.",
            "The full set requires level 30 to wear every piece. It has no class restriction listed.",
            "Four pieces can improve mana regeneration while casting; the effect is stronger in Strongholds and Cities. Five pieces can summon an Arcane elemental when you deal spell damage.",
        },
    },
}

for _, goal in ipairs(sets) do
    table.insert(FGT.goals, goal)
end

-- Forever's PvP sets, one goal per faction and armor type. Hidden on
-- Classic Era (`needs = "forever"`): these "Premier" pieces only exist
-- in Forever. Status "listed": in Wowhead's Forever database, but how
-- Forever's PvP ranks work isn't confirmed yet.
for _, g in ipairs(PVP_SET_GOALS) do
    local key, faction, title, armor, who, list, icon = g[1], g[2], g[3], g[4], g[5], g[6], g[7]
    table.insert(FGT.goals, {
        id = "pvp_set_" .. armor:lower() .. "_" .. key, library = true, group = true,
        itemQuality = 4,
        faction = faction, forever = "listed", needs = "forever",
        icon = icon,
        name = title .. " " .. armor .. " Sets",
        short = title .. " " .. armor,
        category = "PvP", difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "The " .. faction .. " PvP " .. armor:lower() .. " sets for " .. who .. ". Each piece unlocks at a PvP rank, from rank 9 (boots) to rank 13 (helm and chest). Pick the sets you want in the Library; each piece ticks itself when you own it.",
        foreverNote = "In WoW Forever's database. The ranks come from each piece's name; how Forever's PvP ranks work isn't confirmed yet.",
        sections = ForeverSections(list, true),
    })
end

-- ============================================================
-- PvP (one goal per faction)
-- ============================================================
-- Rank steps tick from your current or highest-ever PvP rank; the
-- faction's own characters are the only ones that count.
local RANKS = {
    Alliance = { [6] = "Knight", [10] = "Lieutenant Commander", [11] = "Commander",
                 [12] = "Marshal", [13] = "Field Marshal", [14] = "Grand Marshal" },
    Horde    = { [6] = "Stone Guard", [10] = "Champion", [11] = "Lieutenant General",
                 [12] = "General", [13] = "Warlord", [14] = "High Warlord" },
}
local BANNER = { Alliance = { "inv_bannerpvp_02", "inv_bannerpvp_01" }, Horde = { "inv_bannerpvp_01", "inv_bannerpvp_02" } }

local function RankStep(faction, n)
    return { text = string.format("Reach Rank %d, %s.", n, RANKS[faction][n]),
             auto = { pvpRank = n, forFaction = faction } }
end

local function RepGoal(id, faction, factionId, name, bg, icon, how)
    local steps = {}
    for st = 5, 8 do
        table.insert(steps, { text = "Reach " .. ({ [5] = "Friendly", [6] = "Honored", [7] = "Revered", [8] = "Exalted" })[st] .. ".",
                              auto = { rep = { faction = factionId, standing = st }, forFaction = faction } })
    end
    return {
        id = id, library = true, faction = faction,
        icon = icon, name = "Exalted: " .. name, short = name,
        category = "PvP", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = string.format("The %s %s battleground faction. Exalted unlocks its best rewards.", faction, bg),
        steps = steps,
        tips = how,
    }
end

local pvp = {}
for _, f in ipairs({ "Alliance", "Horde" }) do
    local A = (f == "Alliance")
    local key = A and "ally" or "horde"

    table.insert(pvp, {
        id = "pvp_rank14_" .. key, library = true, faction = f,
        icon = BANNER[f],
        name = A and "Grand Marshal" or "High Warlord",
        category = "PvP", difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "The top PvP rank and its rank 14 weapons. Rank steps tick themselves from your current or highest-ever rank.",
        steps = {
            RankStep(f, 6), RankStep(f, 10), RankStep(f, 12), RankStep(f, 13), RankStep(f, 14),
            "Buy your rank 14 weapon from the PvP quartermaster.",
        },
    })

    local mounts = A and { "Black War Steed", "Black War Tiger", "Black War Ram", "Black Battlestrider" }
                     or { "Black War Wolf", "Black War Raptor", "Black War Kodo", "Red Skeletal Warhorse" }
    table.insert(pvp, {
        id = "pvp_mount_" .. key, library = true, faction = f,
        icon = BANNER[f],
        name = (A and "Alliance" or "Horde") .. " War Mount (Rank 11)",
        short = (A and "Alliance" or "Horde") .. " War Mount",
        category = "PvP", difficulty = "Very Hard",
        timeEstimate = "1-2 Months",
        note = "The epic PvP mount, sold to " .. RANKS[f][11] .. "s and above: " .. table.concat(mounts, ", ") .. ".",
        steps = {
            RankStep(f, 11),
            { text = "Buy a war mount from your faction's PvP quartermaster.", auto = { owned = mounts, forFaction = f } },
        },
        tips = { "Earn honor every week in battlegrounds and world PvP. Rank depends on your honor compared with everyone else's." },
        completeWith = { owned = mounts, forFaction = f },
    })

    local avMount = A and "Stormpike Battle Charger" or "Frostwolf Howler"
    table.insert(pvp, {
        id = "pvp_avmount_" .. key, library = true, faction = f,
        icon = A and { "ability_mount_mountainram", "inv_bannerpvp_02" } or { "ability_mount_whitedirewolf", "ability_mount_blackdirewolf" },
        name = avMount,
        short = A and "Stormpike Charger" or nil,
        category = "PvP", difficulty = "Hard",
        timeEstimate = "1-2 Months",
        note = "Alterac Valley's exalted mount for the " .. (A and "Stormpike Guard" or "Frostwolf Clan") .. ".",
        tips = { "Play Alterac Valley, and turn in armor scraps, blood and crystals between matches." },
        steps = {
            { text = "Reach Exalted with the {pvp_av_" .. key .. ":" .. (A and "Stormpike Guard" or "Frostwolf Clan") .. "}.",
              auto = { rep = { faction = A and 730 or 729, standing = 8 }, forFaction = f } },
            -- item 19030 / 19029 (Wowhead Classic); the vendors stand outside AV
            { text = "Buy the " .. avMount .. " from " .. (A and "Thanthaldis Snowgleam" or "Jekyll Flandring") .. " in the Alterac Mountains.",
              auto = { owned = { avMount }, item = A and 19030 or 19029, forFaction = f } },
        },
        completeWith = { owned = { avMount }, forFaction = f },
    })

    table.insert(pvp, RepGoal("pvp_wsg_" .. key, f, A and 890 or 889,
        A and "Silverwing Sentinels" or "Warsong Outriders", "Warsong Gulch",
        { "inv_misc_rune_07", BANNER[f][1] },
        { "Win and play Warsong Gulch; flag captures and wins give the most reputation." }))
    table.insert(pvp, RepGoal("pvp_ab_" .. key, f, A and 509 or 510,
        A and "League of Arathor" or "The Defilers", "Arathi Basin",
        { "inv_jewelry_amulet_07", BANNER[f][1] },
        { "Play Arathi Basin; holding bases and winning give the most reputation." }))
    table.insert(pvp, RepGoal("pvp_av_" .. key, f, A and 730 or 729,
        A and "Stormpike Guard" or "Frostwolf Clan", "Alterac Valley",
        { "inv_jewelry_necklace_21", BANNER[f][1] },
        { "Play Alterac Valley and do its turn-in quests between matches." }))
end

table.insert(pvp, {
    id = "pvp_hk", library = true,
    icon = { "inv_sword_48", "inv_sword_04" },
    name = "Honorable Kills",
    category = "PvP", difficulty = "Hard",
    timeEstimate = "Ongoing",
    note = "Lifetime honorable kills on a single character. Ticks itself from your PvP stats.",
    target = { kind = "hk", default = 25000, min = 100, max = 1000000, marks = { 0.04, 0.2, 0.4, 1 },
               step = "Earn %s honorable kills.", unit = "honorable kills" },
    steps = {
        { text = "Earn 1,000 honorable kills.", auto = { hk = 1000 } },
        { text = "Earn 5,000 honorable kills.", auto = { hk = 5000 } },
        { text = "Earn 10,000 honorable kills.", auto = { hk = 10000 } },
        { text = "Earn 25,000 honorable kills.", auto = { hk = 25000 } },
    },
})

-- Duels won, from Forever's Statistics window (stat 319, per character;
-- `needs = "stats"` hides it on Classic Era, which has no such window).
table.insert(pvp, {
    id = "pvp_duelist", library = true, forever = "confirmed", needs = "stats",
    icon = { "ability_dualwield", "inv_sword_04" },
    name = "Duelist",
    category = "PvP", difficulty = "Moderate",
    timeEstimate = "Ongoing",
    note = "Prove yourself one duel at a time. Ticks itself from your Statistics window.",
    tips = {
        "Right-click a player's portrait and choose Duel to challenge them.",
    },
    target = { kind = "stat", stat = 319, what = "duels won", default = 100, min = 20, max = 10000,
               marks = { 0.01, 0.1, 0.5, 1 }, step = "Win %s duels.", one = "Win your first duel.", unit = "duels" },
    steps = {
        { text = "Win your first duel.", auto = { stat = { id = 319, value = 1, what = "duels won" } } },
        { text = "Win 10 duels.", auto = { stat = { id = 319, value = 10, what = "duels won" } } },
        { text = "Win 50 duels.", auto = { stat = { id = 319, value = 50, what = "duels won" } } },
        { text = "Win 100 duels.", auto = { stat = { id = 319, value = 100, what = "duels won" } } },
    },
})

for _, goal in ipairs(pvp) do
    table.insert(FGT.goals, goal)
end
