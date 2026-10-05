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
            "Turn in Deadwood Headdress Feathers and Winterfall Spirit Beads in batches of 5 at Timbermaw Hold.",
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
            "Turn in Dark Iron Ore and Fiery Flux to Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths) early on.",
            "From Honored on, turn in Molten Core materials such as Lava Cores and Fiery Cores.",
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
            "Wear an Argent Dawn Commission while killing undead in the Plaguelands, Stratholme and Scholomance.",
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
            "Turn in Twilight Texts and run Ruins of Ahn'Qiraj for steady reputation.",
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
            "Clear Temple of Ahn'Qiraj; kills and Ancient Qiraji Artifacts raise reputation.",
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
            { text = "Exalted with Stormwind.", icon = "spell_arcane_teleportstormwind", auto = { rep = { faction = 72, standing = 8 }, forFaction = "Alliance" } },
            { text = "Exalted with Ironforge.", icon = "spell_arcane_teleportironforge", auto = { rep = { faction = 47, standing = 8 }, forFaction = "Alliance" } },
            { text = "Exalted with Darnassus.", icon = "spell_arcane_teleportdarnassus", auto = { rep = { faction = 69, standing = 8 }, forFaction = "Alliance" } },
            { text = "Exalted with Gnomeregan Exiles.", icon = "inv_misc_gear_01", auto = { rep = { faction = 54, standing = 8 }, forFaction = "Alliance" } },
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
            { text = "Exalted with Orgrimmar.", icon = "spell_arcane_teleportorgrimmar", auto = { rep = { faction = 76, standing = 8 }, forFaction = "Horde" } },
            { text = "Exalted with Thunder Bluff.", icon = "spell_arcane_teleportthunderbluff", auto = { rep = { faction = 81, standing = 8 }, forFaction = "Horde" } },
            { text = "Exalted with Undercity.", icon = "spell_arcane_teleportundercity", auto = { rep = { faction = 68, standing = 8 }, forFaction = "Horde" } },
            { text = "Exalted with the Darkspear Trolls.", icon = "inv_misc_head_troll_01", auto = { rep = { faction = 530, standing = 8 }, forFaction = "Horde" } },
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
        steps = {
            { text = "Reach level 60.", auto = { level = 60 } },
            "Get a group (or solo once geared) for Stratholme's undead side through the service entrance.",
            { text = "Defeat Baron Rivendare.", auto = { boss = "Baron Rivendare" } },
            { text = "Loot Deathcharger's Reins.", auto = { item = 13335, owned = { "Deathcharger" } } },
        },
        completeWith = { item = 13335, owned = { "Deathcharger" } },
    },
    {
        id = "mount_raptor", library = true,
        icon = "ability_mount_raptor",
        name = "Swift Razzashi Raptor",
        short = "Razzashi Raptor",
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "1-2 Months",
        note = "Rare drop from Bloodlord Mandokir in Zul'Gurub.",
        steps = {
            "Join a weekly Zul'Gurub (20-player) raid.",
            { text = "Defeat Bloodlord Mandokir.", auto = { boss = "Bloodlord Mandokir" } },
            { text = "Win the Swift Razzashi Raptor.", auto = { item = 19872, owned = { "Swift Razzashi Raptor" } } },
        },
        completeWith = { item = 19872, owned = { "Swift Razzashi Raptor" } },
    },
    {
        id = "mount_tiger", library = true,
        icon = "ability_mount_jungletiger",
        name = "Swift Zulian Tiger",
        short = "Zulian Tiger",
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "1-2 Months",
        note = "Rare drop from High Priest Thekal in Zul'Gurub.",
        steps = {
            "Join a weekly Zul'Gurub (20-player) raid.",
            { text = "Defeat High Priest Thekal.", auto = { boss = "High Priest Thekal" } },
            { text = "Win the Swift Zulian Tiger.", auto = { item = 19902, owned = { "Swift Zulian Tiger" } } },
        },
        completeWith = { item = 19902, owned = { "Swift Zulian Tiger" } },
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
            "Take part in your realm's Ahn'Qiraj war effort and the Scepter of the Shifting Sands chain.",
            "Be the one who rings the Scarab Gong, or follow your realm's version of the event.",
            { text = "Own the Black Qiraji Resonating Crystal.", auto = { item = 21176, owned = { "Black Qiraji" } } },
        },
        completeWith = { item = 21176, owned = { "Black Qiraji" } },
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
            { text = "Start the chain: pick up 'Mor'zul Bloodbringer' from Spackle Thornberry, the demon trainer in Stormwind City, and complete it.", auto = { quest = 7562 } },
            { text = "Complete 'Rage of Blood'.", auto = { quest = 7563 } },
            { text = "Complete 'Wildeyes'.", auto = { quest = 7564 } },
            { text = "Complete 'Kroshius' Infernal Core'.", auto = { quest = 7603 } },
            { text = "Complete 'Imp Delivery'.", auto = { quest = 7629 } },
            { text = "Complete 'Arcanite'.", auto = { quest = 7630 } },
            { text = "Complete 'Dreadsteed of Xoroth': perform the ritual in Dire Maul and defeat the Xorothian Dreadsteed.", auto = { quest = 7631 } },
        },
        completeWith = { quest = 7631 },
        tips = {
            "Warlock only, and the chain needs level 60.",
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
            { text = "Start the chain: pick up 'Lord Grayson Shadowbreaker' from Duthorian Rall in Stormwind City, and complete it.", auto = { quest = 7638 } },
            { text = "Complete 'Emphasis on Sacrifice'.", auto = { quest = 7637 } },
            { text = "Complete 'To Show Due Judgment'.", auto = { quest = 7639 } },
            { text = "Complete 'Exorcising Terrordale'.", auto = { quest = 7640 } },
            { text = "Complete 'The Work of Grimand Elmore'.", auto = { quest = 7641 } },
            { text = "Complete 'Collection of Goods'.", auto = { quest = 7642 } },
            { text = "Complete 'Ancient Equine Spirit'.", auto = { quest = 7643 } },
            { text = "Complete 'Blessed Arcanite Barding'.", auto = { quest = 7644 } },
            { text = "Complete 'Manna-Enriched Horse Feed'.", auto = { quest = 7645 } },
            { text = "Complete 'The Divination Scryer'.", auto = { quest = 7646 } },
            { text = "Complete 'Judgment and Redemption' in Scholomance to earn the Charger.", auto = { quest = 7647 } },
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
            { text = "Loot the Compendium of Dragon Slaying, a rare book drop in Dire Maul.", auto = { item = 18401, quest = { 7508, 7509 } } },
            { text = "Turn it in at the Dire Maul library to start 'The Forging of Quel'Serrar' and receive the Unfired Ancient Blade.",
              auto = { quest = { 7508, 7509 }, questTaken = { 7508, 7509 }, item = 18489 } },
            { text = "During an Onyxia fight, plant the blade where her fire breath will heat it.", auto = { item = { 18488, 18492, 18348 } } },
            { text = "Grab the Heated Ancient Blade and drive it into Onyxia's corpse before it cools.", auto = { item = { 18492, 18348 } } },
            { text = "Return the Treated Ancient Blade to receive Quel'Serrar.", auto = { item = 18348 } },
        },
        completeWith = { item = 18348 },
    },

    -- ---------------- Raids ----------------
    {
        id = "raid_mc", library = true,
        icon = { "achievement_boss_ragnaros", "spell_fire_lavaspawn", "inv_misc_head_dragon_01" },
        name = "Clear Molten Core",
        short = "Molten Core",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "Boss kills tick off automatically when you're in the raid with the addon loaded.",
        steps = BossSteps({
            { text = "Complete 'Attunement to the Core' in Blackrock Depths.", auto = { quest = 7848 } },
        }, { "Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah", "Baron Geddon",
             "Golemagg the Incinerator", "Sulfuron Harbinger", "Majordomo Executus", "Ragnaros" }),
    },
    {
        id = "raid_ony", library = true,
        icon = "inv_misc_head_dragon_01",
        name = "Slay Onyxia",
        short = "Onyxia",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "1-2 Weeks",
        note = "Needs the Drakefire Amulet from the faction-specific attunement chain.",
        steps = {
            { text = "Complete the Onyxia attunement chain and earn the Drakefire Amulet. It starts with 'Dragonkin Menace' (Alliance) or 'Warlord's Command' (Horde).", auto = { item = 16309 } },
            { text = "Defeat Onyxia.", auto = { boss = "Onyxia" } },
            { text = "Loot the Head of Onyxia and turn it in at your capital city.", auto = { item = { 18422, 18423 } } },
        },
    },
    {
        id = "raid_bwl", library = true,
        icon = { "achievement_boss_nefarion", "inv_misc_head_dragon_black", "inv_misc_head_dragon_01" },
        name = "Clear Blackwing Lair",
        short = "Blackwing Lair",
        category = "Raid", difficulty = "Very Hard",
        timeEstimate = "2-4 Weeks",
        note = "Boss kills tick off automatically when you're in the raid with the addon loaded.",
        steps = BossSteps({
            { text = "Complete 'Blackhand's Command' (Upper Blackrock Spire) for attunement.", auto = { quest = 7761 } },
        }, { "Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer", "Firemaw",
             "Ebonroc", "Flamegor", "Chromaggus", "Nefarian" }),
    },
    {
        id = "raid_zg", library = true,
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
        id = "raid_aq20", library = true,
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
        id = "raid_aq40", library = true,
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
        id = "raid_naxx", library = true,
        icon = { "achievement_boss_kelthuzad_01", "inv_misc_head_dragon_01" },
        name = "Clear Naxxramas",
        short = "Naxxramas",
        category = "Raid", difficulty = "Extreme",
        timeEstimate = "3+ Months",
        note = "The hardest raid in the game: all four wings, Sapphiron and Kel'Thuzad.",
        steps = BossSteps({
            { text = "Get attuned to Naxxramas at Light's Hope Chapel.", auto = { quest = { 9121, 9122, 9123 } } },
        }, { "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean",
             "Loatheb", "Instructor Razuvious", "Gothik the Harvester", { "Four Horsemen" }, "Patchwerk",
             "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" }),
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
            { text = "Start the chain: pick up 'Dragonkin Menace' from Helendis Riverhorn in the Burning Steppes, and complete it.", auto = { quest = 4182 } },
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
            { text = "Start the chain: pick up 'Warlord's Command' from Warlord Goretooth in Kargath, Badlands, and complete it.", auto = { quest = 4903 } },
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
            { text = "Loot Blackhand's Command, a rare drop from the Scarshield Quartermaster in Blackrock Spire, and read it.", auto = { item = 18987, questTaken = 7761, quest = 7761 } },
            { text = "Defeat General Drakkisath in Upper Blackrock Spire.", auto = { boss = "General Drakkisath", quest = 7761 } },
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
            { text = "Reach Honored with the Argent Dawn.", auto = { rep = { faction = 529, standing = 6 }, quest = { 9121, 9122, 9123 } } },
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


    -- ---------------- Milestones ----------------
    {
        id = "gold_5k", library = true,
        icon = { "inv_misc_coin_02", "inv_misc_coin_01" },
        name = "Save 5,000 Gold",
        category = "Milestone", difficulty = "Hard",
        timeEstimate = "Varies",
        note = "Hold 1k, 2.5k and 5k gold on a single character. Ticks itself from your gold.",
        steps = {
            { text = "1,000 gold on one character.", auto = { money = 1000 * 10000 } },
            { text = "2,500 gold on one character.", auto = { money = 2500 * 10000 } },
            { text = "5,000 gold on one character.", auto = { money = 5000 * 10000 } },
        },
    },
}

for _, goal in ipairs(library) do
    table.insert(FGT.goals, goal)
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
        table.insert(sections, { icon = "ClassIcon_" .. class, name = class .. " - " .. setName, pieces = list })
    end
    return sections
end

local TIER1 = {
    { "Warrior", "Battlegear of Might", { { "Helm of Might", 16866, "Garr" }, { "Pauldrons of Might", 16868, "Sulfuron Harbinger" }, { "Breastplate of Might", 16865, "Golemagg the Incinerator" }, { "Gauntlets of Might", 16863, "Lucifron" }, { "Legplates of Might", 16867, "Magmadar" }, { "Belt of Might", 16864, "Molten Core trash" }, { "Bracers of Might", 16861, "Molten Core trash" }, { "Sabatons of Might", 16862, "Gehennas" } } },
    { "Paladin", "Lawbringer Armor", { { "Lawbringer Helm", 16854, "Garr" }, { "Lawbringer Spaulders", 16856, "Baron Geddon" }, { "Lawbringer Chestguard", 16853, "Golemagg the Incinerator" }, { "Lawbringer Gauntlets", 16860, "Gehennas" }, { "Lawbringer Legplates", 16855, "Magmadar" }, { "Lawbringer Belt", 16858, "Molten Core trash" }, { "Lawbringer Bracers", 16857, "Molten Core trash" }, { "Lawbringer Boots", 16859, "Lucifron" } } },
    { "Hunter", "Giantstalker Armor", { { "Giantstalker's Helmet", 16846, "Garr" }, { "Giantstalker's Epaulets", 16848, "Sulfuron Harbinger" }, { "Giantstalker's Breastplate", 16845, "Golemagg the Incinerator" }, { "Giantstalker's Gloves", 16852, "Shazzrah" }, { "Giantstalker's Leggings", 16847, "Magmadar" }, { "Giantstalker's Belt", 16851, "Molten Core trash" }, { "Giantstalker's Bracers", 16850, "Molten Core trash" }, { "Giantstalker's Boots", 16849, "Gehennas" } } },
    { "Rogue", "Nightslayer Armor", { { "Nightslayer Cover", 16821, "Garr" }, { "Nightslayer Shoulder Pads", 16823, "Sulfuron Harbinger" }, { "Nightslayer Chestpiece", 16820, "Golemagg the Incinerator" }, { "Nightslayer Gloves", 16826, "Gehennas" }, { "Nightslayer Pants", 16822, "Magmadar" }, { "Nightslayer Belt", 16827, "Molten Core trash" }, { "Nightslayer Bracelets", 16825, "Molten Core trash" }, { "Nightslayer Boots", 16824, "Shazzrah" } } },
    { "Priest", "Vestments of Prophecy", { { "Circlet of Prophecy", 16813, "Garr" }, { "Mantle of Prophecy", 16816, "Sulfuron Harbinger" }, { "Robes of Prophecy", 16815, "Golemagg the Incinerator" }, { "Gloves of Prophecy", 16812, "Gehennas" }, { "Pants of Prophecy", 16814, "Magmadar" }, { "Girdle of Prophecy", 16817, "Molten Core trash" }, { "Vambraces of Prophecy", 16819, "Molten Core trash" }, { "Boots of Prophecy", 16811, "Shazzrah" } } },
    { "Shaman", "The Earthfury", { { "Earthfury Helmet", 16842, "Garr" }, { "Earthfury Epaulets", 16844, "Baron Geddon" }, { "Earthfury Vestments", 16841, "Golemagg the Incinerator" }, { "Earthfury Gauntlets", 16839, "Gehennas" }, { "Earthfury Legguards", 16843, "Magmadar" }, { "Earthfury Belt", 16838, "Molten Core trash" }, { "Earthfury Bracers", 16840, "Molten Core trash" }, { "Earthfury Boots", 16837, "Lucifron" } } },
    { "Mage", "Arcanist Regalia", { { "Arcanist Crown", 16795, "Garr" }, { "Arcanist Mantle", 16797, "Baron Geddon" }, { "Arcanist Robes", 16798, "Golemagg the Incinerator" }, { "Arcanist Gloves", 16801, "Shazzrah" }, { "Arcanist Leggings", 16796, "Magmadar" }, { "Arcanist Belt", 16802, "Molten Core trash" }, { "Arcanist Bindings", 16799, "Molten Core trash" }, { "Arcanist Boots", 16800, "Lucifron" } } },
    { "Warlock", "Felheart Raiment", { { "Felheart Horns", 16808, "Garr" }, { "Felheart Shoulder Pads", 16807, "Baron Geddon" }, { "Felheart Robes", 16809, "Golemagg the Incinerator" }, { "Felheart Gloves", 16805, "Lucifron" }, { "Felheart Pants", 16810, "Magmadar" }, { "Felheart Belt", 16806, "Molten Core trash" }, { "Felheart Bracers", 16804, "Molten Core trash" }, { "Felheart Slippers", 16803, "Shazzrah" } } },
    { "Druid", "Cenarion Raiment", { { "Cenarion Helm", 16834, "Garr" }, { "Cenarion Spaulders", 16836, "Baron Geddon" }, { "Cenarion Vestments", 16833, "Golemagg the Incinerator" }, { "Cenarion Gloves", 16831, "Shazzrah" }, { "Cenarion Leggings", 16835, "Magmadar" }, { "Cenarion Belt", 16828, "Molten Core trash" }, { "Cenarion Bracers", 16830, "Molten Core trash" }, { "Cenarion Boots", 16829, "Lucifron" } } },
}

local TIER2 = {
    { "Warrior", "Battlegear of Wrath", { { "Helm of Wrath", 16963, "Onyxia" }, { "Pauldrons of Wrath", 16961, "Chromaggus" }, { "Breastplate of Wrath", 16966, "Nefarian" }, { "Gauntlets of Wrath", 16964, "Firemaw, Ebonroc or Flamegor" }, { "Legplates of Wrath", 16962, "Ragnaros" }, { "Waistband of Wrath", 16960, "Vaelastrasz the Corrupt" }, { "Bracelets of Wrath", 16959, "Razorgore the Untamed" }, { "Sabatons of Wrath", 16965, "Broodlord Lashlayer" } } },
    { "Paladin", "Judgement Armor", { { "Judgement Crown", 16955, "Onyxia" }, { "Judgement Spaulders", 16953, "Chromaggus" }, { "Judgement Breastplate", 16958, "Nefarian" }, { "Judgement Gauntlets", 16956, "Firemaw, Ebonroc or Flamegor" }, { "Judgement Legplates", 16954, "Ragnaros" }, { "Judgement Belt", 16952, "Vaelastrasz the Corrupt" }, { "Judgement Bindings", 16951, "Razorgore the Untamed" }, { "Judgement Sabatons", 16957, "Broodlord Lashlayer" } } },
    { "Hunter", "Dragonstalker Armor", { { "Dragonstalker's Helm", 16939, "Onyxia" }, { "Dragonstalker's Spaulders", 16937, "Chromaggus" }, { "Dragonstalker's Breastplate", 16942, "Nefarian" }, { "Dragonstalker's Gauntlets", 16940, "Firemaw, Ebonroc or Flamegor" }, { "Dragonstalker's Legguards", 16938, "Ragnaros" }, { "Dragonstalker's Belt", 16936, "Vaelastrasz the Corrupt" }, { "Dragonstalker's Bracers", 16935, "Razorgore the Untamed" }, { "Dragonstalker's Greaves", 16941, "Broodlord Lashlayer" } } },
    { "Rogue", "Bloodfang Armor", { { "Bloodfang Hood", 16908, "Onyxia" }, { "Bloodfang Spaulders", 16832, "Chromaggus" }, { "Bloodfang Chestpiece", 16905, "Nefarian" }, { "Bloodfang Gloves", 16907, "Firemaw, Ebonroc or Flamegor" }, { "Bloodfang Pants", 16909, "Ragnaros" }, { "Bloodfang Belt", 16910, "Vaelastrasz the Corrupt" }, { "Bloodfang Bracers", 16911, "Razorgore the Untamed" }, { "Bloodfang Boots", 16906, "Broodlord Lashlayer" } } },
    { "Priest", "Vestments of Transcendence", { { "Halo of Transcendence", 16921, "Onyxia" }, { "Pauldrons of Transcendence", 16924, "Chromaggus" }, { "Robes of Transcendence", 16923, "Nefarian" }, { "Handguards of Transcendence", 16920, "Firemaw, Ebonroc or Flamegor" }, { "Leggings of Transcendence", 16922, "Ragnaros" }, { "Belt of Transcendence", 16925, "Vaelastrasz the Corrupt" }, { "Bindings of Transcendence", 16926, "Razorgore the Untamed" }, { "Boots of Transcendence", 16919, "Broodlord Lashlayer" } } },
    { "Shaman", "The Ten Storms", { { "Helmet of Ten Storms", 16947, "Onyxia" }, { "Epaulets of Ten Storms", 16945, "Chromaggus" }, { "Breastplate of Ten Storms", 16950, "Nefarian" }, { "Gauntlets of Ten Storms", 16948, "Firemaw, Ebonroc or Flamegor" }, { "Legplates of Ten Storms", 16946, "Ragnaros" }, { "Belt of Ten Storms", 16944, "Vaelastrasz the Corrupt" }, { "Bracers of Ten Storms", 16943, "Razorgore the Untamed" }, { "Greaves of Ten Storms", 16949, "Broodlord Lashlayer" } } },
    { "Mage", "Netherwind Regalia", { { "Netherwind Crown", 16914, "Onyxia" }, { "Netherwind Mantle", 16917, "Chromaggus" }, { "Netherwind Robes", 16916, "Nefarian" }, { "Netherwind Gloves", 16913, "Firemaw, Ebonroc or Flamegor" }, { "Netherwind Pants", 16915, "Ragnaros" }, { "Netherwind Belt", 16818, "Vaelastrasz the Corrupt" }, { "Netherwind Bindings", 16918, "Razorgore the Untamed" }, { "Netherwind Boots", 16912, "Broodlord Lashlayer" } } },
    { "Warlock", "Nemesis Raiment", { { "Nemesis Skullcap", 16929, "Onyxia" }, { "Nemesis Spaulders", 16932, "Chromaggus" }, { "Nemesis Robes", 16931, "Nefarian" }, { "Nemesis Gloves", 16928, "Firemaw, Ebonroc or Flamegor" }, { "Nemesis Leggings", 16930, "Ragnaros" }, { "Nemesis Belt", 16933, "Vaelastrasz the Corrupt" }, { "Nemesis Bracers", 16934, "Razorgore the Untamed" }, { "Nemesis Boots", 16927, "Broodlord Lashlayer" } } },
    { "Druid", "Stormrage Raiment", { { "Stormrage Cover", 16900, "Onyxia" }, { "Stormrage Pauldrons", 16902, "Chromaggus" }, { "Stormrage Chestguard", 16897, "Nefarian" }, { "Stormrage Handguards", 16899, "Firemaw, Ebonroc or Flamegor" }, { "Stormrage Legguards", 16901, "Ragnaros" }, { "Stormrage Belt", 16903, "Vaelastrasz the Corrupt" }, { "Stormrage Bracers", 16904, "Razorgore the Untamed" }, { "Stormrage Boots", 16898, "Broodlord Lashlayer" } } },
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

local sets = {
    {
        id = "set_tier1", library = true, group = true,
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
        id = "set_viper", library = true,
        icon = "inv_shirt_16",
        name = "Embrace of the Viper",
        short = "Viper Set",
        category = "Item Set", difficulty = "Moderate",
        timeEstimate = "Days",
        note = "A five-piece leather set from Wailing Caverns. A druid wearing all five is transformed into a serpent, with coloring that depends on race.",
        steps = {
            { text = "Armor of the Fang (chest) from Lord Pythas.", icon = "inv_shirt_16", auto = { item = 6473, owned = { "Armor of the Fang" } } },
            { text = "Leggings of the Fang from Lord Cobrahn.", icon = "inv_pants_11", auto = { item = 10410, owned = { "Leggings of the Fang" } } },
            { text = "Footpads of the Fang from Lord Serpentis.", icon = "inv_boots_04", auto = { item = 10411, owned = { "Footpads of the Fang" } } },
            { text = "Belt of the Fang from Lady Anacondra.", icon = "inv_belt_30", auto = { item = 10412, owned = { "Belt of the Fang" } } },
            { text = "Gloves of the Fang, a rare drop from Druids of the Fang.", icon = "inv_gauntlets_18", auto = { item = 10413, owned = { "Gloves of the Fang" } } },
        },
    },
}

for _, goal in ipairs(sets) do
    table.insert(FGT.goals, goal)
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
            { text = "Reach Exalted with the " .. (A and "Stormpike Guard" or "Frostwolf Clan") .. ".",
              auto = { rep = { faction = A and 730 or 729, standing = 8 }, forFaction = f } },
            { text = "Buy the " .. avMount .. ".", auto = { owned = { avMount }, forFaction = f } },
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
    steps = {
        { text = "1,000 honorable kills.", auto = { hk = 1000 } },
        { text = "5,000 honorable kills.", auto = { hk = 5000 } },
        { text = "10,000 honorable kills.", auto = { hk = 10000 } },
        { text = "25,000 honorable kills.", auto = { hk = 25000 } },
    },
})

for _, goal in ipairs(pvp) do
    table.insert(FGT.goals, goal)
end
