local ADDON, FGT = ...

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
FGT.difficultyColors = {
    ["Moderate"]  = { 0.62, 0.91, 0.44 },   -- #9fe870
    ["Hard"]      = { 1.00, 0.82, 0.00 },   -- #ffd100
    ["Very Hard"] = { 1.00, 0.60, 0.24 },   -- #ff993d
    ["Extreme"]   = { 1.00, 0.48, 0.48 },   -- #ff7a7a
}

-- ============================================================
-- Tier 3 helper: builds the 8-piece list for one class's set.
-- Materials are a representative template (real token/scrap/crafting-
-- material TYPES, scaled by piece size) rather than hand-verified exact
-- quantities for all 72 pieces - the goal note says to double check
-- exact numbers at your quartermaster, same as the rest of this addon.
-- ============================================================
local TIER3_SLOTS = {
    { slot = "Helm",      size = "medium" },
    { slot = "Shoulder",  size = "small"  },
    { slot = "Chest",     size = "large"  },
    { slot = "Hands",     size = "small"  },
    { slot = "Legs",      size = "large"  },
    { slot = "Waist",     size = "small"  },
    { slot = "Wrist",     size = "small"  },
    { slot = "Feet",      size = "medium" },
}

local ARMOR_MATERIAL = {
    Plate   = "Arcanite Bar",
    Mail    = "Arcanite Bar",
    Leather = "Cured Rugged Hide",
    Cloth   = "Mooncloth",
}

local SIZE_QTY = {
    small  = { scraps = 6,  mat = 2 },
    medium = { scraps = 10, mat = 4 },
    large  = { scraps = 16, mat = 6 },
}

-- Epic riding mount helper: builds the 4-task checklist for one race's
-- mount (level to 60, train riding, save gold, buy from the vendor).
-- raceFile is the game's internal race name (UnitRace's 2nd return;
-- Undead is "Scourge"). ownedPatterns are Lua patterns matched against
-- mount and item names you own, to spot the purchase automatically.
local function BuildMountTasks(race, mountName, vendor, location, raceFile, ownedPatterns)
    return {
        { name = "Level a " .. race .. " character to level 60", materials = {},
          auto = { raceLevel = { race = raceFile, level = 60 } } },
        { name = "Train Expert Riding (100% speed) from your riding trainer", materials = {},
          auto = { skill = { name = "Riding", rank = 150 }, forRace = raceFile } },
        { name = "Save up roughly 800-1000 gold on that character (less with a home-city reputation discount)", materials = {},
          auto = { money = 800 * 10000, forRace = raceFile } },
        { name = "Buy the " .. mountName .. " from " .. vendor .. " in " .. location, materials = {},
          auto = { ownedPattern = ownedPatterns, forRace = raceFile } },
    }
end

local function BuildTier3Pieces(pieceNames, armorType)
    local mat = ARMOR_MATERIAL[armorType]
    local pieces = {}
    for i, slotInfo in ipairs(TIER3_SLOTS) do
        local qty = SIZE_QTY[slotInfo.size]
        local materials = {
            "Desecrated " .. slotInfo.slot .. " token (Naxxramas boss drop)",
            "Wartorn " .. armorType .. " Scraps x" .. qty.scraps .. " (trash mobs inside Naxxramas)",
            mat .. " x" .. qty.mat,
        }
        if slotInfo.size == "large" then
            table.insert(materials, "Nexus Crystal x1")
        end
        table.insert(pieces, {
            name = pieceNames[i],
            materials = materials,
            auto = { owned = { pieceNames[i] } },
        })
    end
    return pieces
end

-- ============================================================
-- Goal data
-- Each goal: id, name, category, difficulty, timeEstimate, timeRank
-- (1=fastest .. 5=slowest, used only for the "sort by duration" option),
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
        category = "Epic Weapon",
        difficulty = "Extreme",
        timeEstimate = "Months of weekly Naxx clears (pure RNG)",
        timeRank = 4,
        note = "This is the raid-dropped sword itself. The 'purified' legendary upgrade needs content beyond the original 1-60 game, so under classic rules this goal is really about the Corrupted Ashbringer drop.",
        steps = {
            { text = "Reach level 60 and gear up for a 40-player Naxxramas raid (aim for at least pre-raid BiS from dungeons/world drops).", auto = { level = 60 } },
            { text = "Get attuned to Naxxramas: reach Honored with the Argent Dawn, then turn in a Righteous Orb (needs 5 Arcane Crystal + 2 Nexus Crystal at Honored, less at Revered) to Archmage Angela Dosantos at Light's Hope Chapel, Eastern Plaguelands.", auto = { quest = { 9121, 9122, 9123 } } },
            "Join or build a guild raid team that clears Naxxramas on a weekly reset schedule.",
            "Clear trash and bosses through the Military Wing up to the Four Horsemen encounter (Highlord Mograine, Thane Korth'azz, Sir Zeliek, Baron Rivendare).",
            "Defeat all four Horsemen together in the same attempt (either the 2-tank 'square' strat or a full 4-group synced kill).",
            "Open the chest that spawns after the kill - Corrupted Ashbringer has a very low, unofficial-estimate drop chance, on par with other raid-legendary RNG drops like the Bindings of the Windseeker.",
            { text = "It's Bind on Pickup and unique, so only one raider can loot it per kill - repeat weekly clears (with a loot council or roll system) until it drops.", auto = { item = { 22691, 22709 } } },
            "Optional lore moment: equip the sword and visit Scarlet Monastery Cathedral to trigger a cutscene with Balnazzar.",
            "Unequip the sword before approaching Argent Dawn NPCs (like at Light's Hope Chapel) - wielding it flags you Hated with them and they'll attack on sight.",
        },
    },

    {
        id = "frostsaber",
        completeWith = { item = 13086, owned = { "Winterspring Frostsaber" } },
        icon = "ability_mount_pinktiger",
        name = "Winterspring Frostsaber",
        category = "Mount",
        difficulty = "Hard",
        timeEstimate = "3-6 weeks of daily turn-ins",
        timeRank = 2,
        note = "Alliance-only mount, ~900g at Exalted. Non-Night Elves also need Darnassus Exalted to learn Tiger Riding.",
        steps = {
            { text = "Be level 40+ (level 60 recommended for safe travel) and head to Winterspring.", auto = { level = 40 } },
            { text = "Find Rivern Frostwind at Frostsaber Rock (south-central Winterspring) and pick up the introductory quest chain.", auto = { rep = { faction = 589, standing = 4, value = 1 } } },
            { text = "Turn in 'Frostsaber Provisions' once per day (5 Shardtooth Meat + 5 Chillwind Meat, farmed from Winterspring wolves/yetis) to build Wintersaber Trainers reputation from Neutral toward 1500/3000.", auto = { rep = { faction = 589, standing = 4, value = 1500 } } },
            { text = "At 1500/3000 Neutral, switch to the repeatable 'Winterfall Intrusion' - kill 5 Winterfall Shaman + 5 Winterfall Ursa at Winterfall Village and turn in once per day.", auto = { rep = { faction = 589, standing = 5 } } },
            { text = "Once Honored, add 'Rampaging Giants' (kill giants near Frostsaber Rock) as a second daily turn-in to speed up the grind to Exalted.", auto = { rep = { faction = 589, standing = 6 } } },
            { text = "Keep repeating the daily turn-ins all the way to Exalted with Wintersaber Trainers - this is the long pole, typically several weeks even doing every turn-in daily.", auto = { rep = { faction = 589, standing = 8 } } },
            { text = "If you are not a Night Elf, also reach Exalted with Darnassus (via Darnassus tabard dungeon runs or turn-ins) to unlock Tiger/Frostsaber Riding.", auto = { rep = { faction = 69, standing = 8 }, race = "NightElf" } },
            { text = "Buy Reins of the Winterspring Frostsaber from Rivern Frostwind for roughly 900 gold (small discount if Exalted rep gives a price break).", auto = { item = 13086, owned = { "Winterspring Frostsaber" } } },
        },
    },

    {
        id = "atiesh",
        completeWith = { item = { 22589, 22630, 22631, 22632 }, quest = { 9257, 9269, 9270, 9271 } },
        icon = "inv_staff_medivh",
        name = "Atiesh, Greatstaff of the Guardian",
        category = "Legendary Weapon",
        difficulty = "Extreme",
        timeEstimate = "Several months, gated by both Naxx and AQ40 progression",
        timeRank = 4,
        note = "Only for Druid, Mage, Priest, or Warlock. Requires access to Naxxramas, Ahn'Qiraj 40, and Stratholme.",
        steps = {
            { text = "Play a Druid, Mage, Priest, or Warlock and be raiding both Naxxramas and Ahn'Qiraj 40 regularly.", auto = { level = 60 } },
            { text = "Farm Splinters of Atiesh, a random-chance drop from most Naxxramas bosses, until you have 40.", auto = { item = 22726, count = 40 } },
            { text = "Combine the 40 splinters into the Frame of Atiesh.", auto = { item = 22727, quest = 9250 } },
            { text = "Take the Frame of Atiesh to Anachronos at the Caverns of Time entrance in Tanaris to start the class-specific quest chain.", auto = { quest = 9250 } },
            { text = "Obtain the Staff Head of Atiesh, a guaranteed(ish) drop from Kel'Thuzad in Naxxramas.", auto = { item = 22733 } },
            { text = "Obtain the Base of Atiesh, a guaranteed(ish) drop from C'Thun in Ahn'Qiraj (AQ40).", auto = { item = 22734 } },
            { text = "Return both pieces to Anachronos to continue the chain.", auto = { quest = 9251 } },
            "Complete your class-specific purification quest from Anachronos (varies: Druid/Mage/Priest/Warlock each get a distinct short questline).",
            "Travel to Stratholme (Festival Lane) with the purified staff, clear a path through the undead, and defeat the summoned guardian encounter.",
            { text = "Return to Anachronos to receive Atiesh, Greatstaff of the Guardian - it grants a raid-wide buff, so guilds often prioritize it for a support-focused player.", auto = { item = { 22589, 22630, 22631, 22632 }, quest = { 9257, 9269, 9270, 9271 } } },
        },
    },

    {
        id = "rhokdelar",
        icon = "inv_weapon_bow_01",
        name = "Rhok'delar, Longbow of the Ancient Keepers",
        category = "Epic Weapon",
        difficulty = "Hard",
        timeEstimate = "2-4 weeks once Molten Core-geared",
        timeRank = 1,
        note = "Hunter-only epic bow. It's built from the Ancient Rune Etched Stave you earn in the Lok'delar chain, so do that goal first. Since patch 1.8 one Hunter ends up with both weapons.",
        steps = {
            { text = "Finish 'Stave of the Ancients' (see the Lok'delar goal) to receive the Ancient Rune Etched Stave.", auto = { item = 18707, quest = 7636 } },
            "Pick up 'A Proper String' from Vartrus the Ancient in Felwood (Irontree Woods).",
            { text = "Kill Onyxia in Onyxia's Lair and loot the Mature Black Dragon Sinew (Hunter quest drop).", auto = { item = 18705, quest = 7635 } },
            { text = "Turn the sinew in to Vartrus to receive the Enchanted Black Dragon Sinew.", auto = { item = 18724, quest = 7635 } },
            { text = "Combine the Ancient Rune Etched Stave with the Enchanted Black Dragon Sinew to create Rhok'delar.", auto = { item = { 18713, 20488 } } },
            { text = "Optional: kill Azuregos in Azshara for a Mature Blue Dragon Sinew and turn in 'Ancient Sinew Wrapped Lamina' for the matching epic quiver.", auto = { quest = 7634 } },
        },
    },

    {
        id = "lokdelar",
        completeWith = { item = { 18715, 20487 } },
        icon = "inv_staff_21",
        name = "Lok'delar, Stave of the Ancient Keepers",
        category = "Epic Weapon",
        difficulty = "Hard",
        timeEstimate = "2-4 weeks once Molten Core-geared",
        timeRank = 1,
        note = "Hunter-only epic staff, the first half of the Ancient Keepers chain. The same turn-in also gives the Ancient Rune Etched Stave used to make Rhok'delar.",
        steps = {
            { text = "Raid Molten Core on a Hunter and loot the Ancient Petrified Leaf from the Cache of the Firelord after Majordomo Executus.", auto = { item = 18703, quest = 7632 } },
            { text = "Bring the leaf to Vartrus the Ancient in Felwood (Irontree Woods) and pick up 'Stave of the Ancients'.", auto = { quest = 7632 } },
            "Solo Artorius the Doombringer in Winterspring (no pet help, no other players).",
            "Solo Klinfran the Crazed in Burning Steppes.",
            "Solo Solenor the Slayer in Silithus.",
            "Solo Simone the Seductress in Un'Goro Crater.",
            { text = "Return all four demon heads to Vartrus.", auto = { quest = 7636 } },
            { text = "Receive Lok'delar, plus the Ancient Rune Etched Stave for Rhok'delar.", auto = { item = { 18715, 20487 }, quest = 7636 } },
        },
    },

    {
        id = "thunderfury",
        completeWith = { item = 19019, quest = 7787 },
        icon = "inv_sword_39",
        name = "Thunderfury, Blessed Blade of the Windseeker",
        category = "Legendary Weapon",
        difficulty = "Very Hard",
        timeEstimate = "Months of weekly MC clears (both bindings ~3% each)",
        timeRank = 4,
        note = "The classic legendary. Both bindings are roughly a 3% drop each, so this is usually a long farm even with consistent weekly clears.",
        steps = {
            { text = "Raid Molten Core on a weekly reset schedule.", auto = { level = 60 } },
            { text = "Loot the left Binding of the Windseeker from Baron Geddon (roughly 3% drop chance).", auto = { item = 18563, quest = 7785 } },
            { text = "Loot the right Binding of the Windseeker from Garr (roughly 3% drop chance).", auto = { item = 18564, quest = 7785 } },
            { text = "With a binding in hand, speak to Highlord Demitrian in Silithus ('Examine the Vessel') to start the questline.", auto = { quest = 7785 } },
            { text = "Gather 10 Elementium Bars.", auto = { item = 17771, count = 10 } },
            { text = "Gather 100 Arcanite Bars.", auto = { item = 12360, count = 100 } },
            { text = "Gather 10 Fiery Cores (Molten Core).", auto = { item = 17010, count = 10 } },
            { text = "Gather 30 Elemental Flux.", auto = { item = 18567, count = 30 } },
            { text = "Defeat Ragnaros in Molten Core to obtain the Essence of the Firelord.", auto = { item = { 19017, 18566 }, quest = 7786 } },
            { text = "Turn in both bindings, the Essence of the Firelord and the materials to Demitrian ('Thunderaan the Windseeker').", auto = { quest = 7786 } },
            { text = "Help your raid defeat the summoned Prince Thunderaan.", auto = { quest = 7786 } },
            { text = "Turn in the Dormant Wind Kissed Blade ('Rise, Thunderfury!') to receive Thunderfury.", auto = { item = 19019, quest = 7787 } },
        },
    },

    {
        id = "tier3",
        group = true, -- pick class sets individually in the Library
        icon = "inv_helmet_58",
        name = "Tier 3 Set Appearances",
        category = "Item Set",
        difficulty = "Extreme",
        timeEstimate = "Years - a full Naxx tier clear per class/character",
        timeRank = 5,
        note = "Tier 3 comes from Naxxramas via a token-and-crafting system: bosses drop 'Desecrated' class tokens, which you combine with Wartorn Scraps and class/slot-specific profession materials at your class's quartermaster near Light's Hope Chapel (Eastern Plaguelands). You'll need Naxxramas attunement (Honored Argent Dawn + a Righteous Orb) on each character first. Click a class to expand its 8 pieces; each piece has its own materials checklist. Exact quantities are a template - verify at your quartermaster since they vary slightly by piece.",
        sections = {
            {
                icon = "ClassIcon_Warrior",
                name = "Warrior - Dreadnaught's Battlegear",
                pieces = BuildTier3Pieces({
                    "Dreadnaught Helmet", "Dreadnaught Pauldrons", "Dreadnaught Breastplate",
                    "Dreadnaught Gauntlets", "Dreadnaught Legplates", "Dreadnaught Waistguard",
                    "Dreadnaught Bracers", "Dreadnaught Sabatons",
                }, "Plate"),
            },
            {
                icon = "ClassIcon_Paladin",
                name = "Paladin - Redemption Armor",
                pieces = BuildTier3Pieces({
                    "Redemption Headpiece", "Redemption Spaulders", "Redemption Tunic",
                    "Redemption Handguards", "Redemption Legguards", "Redemption Girdle",
                    "Redemption Wristguards", "Redemption Boots",
                }, "Plate"),
            },
            {
                icon = "ClassIcon_Hunter",
                name = "Hunter - Cryptstalker Armor",
                pieces = BuildTier3Pieces({
                    "Cryptstalker Headpiece", "Cryptstalker Spaulders", "Cryptstalker Tunic",
                    "Cryptstalker Handguards", "Cryptstalker Legguards", "Cryptstalker Girdle",
                    "Cryptstalker Wristguards", "Cryptstalker Boots",
                }, "Mail"),
            },
            {
                icon = "ClassIcon_Rogue",
                name = "Rogue - Bonescythe Armor",
                pieces = BuildTier3Pieces({
                    "Bonescythe Helmet", "Bonescythe Pauldrons", "Bonescythe Breastplate",
                    "Bonescythe Gauntlets", "Bonescythe Legplates", "Bonescythe Waistguard",
                    "Bonescythe Bracers", "Bonescythe Sabatons",
                }, "Leather"),
            },
            {
                icon = "ClassIcon_Priest",
                name = "Priest - Vestments of Faith",
                pieces = BuildTier3Pieces({
                    "Circlet of Faith", "Shoulderpads of Faith", "Robe of Faith",
                    "Gloves of Faith", "Leggings of Faith", "Belt of Faith",
                    "Bindings of Faith", "Sandals of Faith",
                }, "Cloth"),
            },
            {
                icon = "ClassIcon_Druid",
                name = "Druid - Dreamwalker Raiment",
                pieces = BuildTier3Pieces({
                    "Dreamwalker Headpiece", "Dreamwalker Spaulders", "Dreamwalker Tunic",
                    "Dreamwalker Handguards", "Dreamwalker Legguards", "Dreamwalker Girdle",
                    "Dreamwalker Wristguards", "Dreamwalker Boots",
                }, "Leather"),
            },
            {
                icon = "ClassIcon_Mage",
                name = "Mage - Frostfire Regalia",
                pieces = BuildTier3Pieces({
                    "Frostfire Circlet", "Frostfire Shoulderpads", "Frostfire Robe",
                    "Frostfire Gloves", "Frostfire Leggings", "Frostfire Belt",
                    "Frostfire Bindings", "Frostfire Sandals",
                }, "Cloth"),
            },
            {
                icon = "ClassIcon_Warlock",
                name = "Warlock - Plagueheart Raiment",
                pieces = BuildTier3Pieces({
                    "Plagueheart Circlet", "Plagueheart Shoulderpads", "Plagueheart Robe",
                    "Plagueheart Gloves", "Plagueheart Leggings", "Plagueheart Belt",
                    "Plagueheart Bindings", "Plagueheart Sandals",
                }, "Cloth"),
            },
            {
                icon = "ClassIcon_Shaman",
                name = "Shaman - Earthshatter Regalia",
                pieces = BuildTier3Pieces({
                    "Earthshatter Headpiece", "Earthshatter Spaulders", "Earthshatter Tunic",
                    "Earthshatter Handguards", "Earthshatter Legguards", "Earthshatter Girdle",
                    "Earthshatter Wristguards", "Earthshatter Boots",
                }, "Mail"),
            },
        },
    },

    {
        id = "benediction",
        completeWith = { item = { 18608, 18609 } },
        icon = "inv_staff_30",
        name = "Benediction / Anathema",
        category = "Epic Weapon",
        difficulty = "Hard",
        timeEstimate = "3-6 weeks once raiding Molten Core",
        timeRank = 2,
        note = "Priest-only. One staff, two forms - right-click to swap between Benediction (Holy) and Anathema (Shadow) on a 30-minute cooldown.",
        steps = {
            { text = "Raid Molten Core and loot The Eye of Divinity from Majordomo Executus.", auto = { item = 18646, quest = 7622 } },
            { text = "Travel to the Eastern Plaguelands and speak with Eris Havenfire (northwest, near Stratholme) to start 'The Balance of Light and Shadow'.", auto = { quest = 7622 } },
            { text = "Complete the escort event: heal and protect 50 peasants from undead attackers, keeping deaths under 15 (expect the attempt to run 5+ minutes; if it fails, Eris resets after about 15 minutes).", auto = { quest = 7622 } },
            { text = "Receive the Splinter of Nordrassil as your reward.", auto = { item = 18659, quest = 7622 } },
            { text = "Obtain The Eye of Shadow, which drops from elite demons in southern Winterspring (it's also tradeable/BoE, so it can be bought off the Auction House instead of farmed).", auto = { item = 18665 } },
            { text = "Combine the Splinter of Nordrassil with the Eye of Shadow and the Eye of Divinity to complete the staff.", auto = { item = { 18608, 18609 } } },
            { text = "Right-click the finished staff any time to swap between Benediction (Holy) and Anathema (Shadow) - 30-minute cooldown between swaps.", auto = { item = { 18608, 18609 } } },
        },
    },

    {
        id = "epicmounts",
        group = true, -- pick races individually in the Library
        icon = "ability_mount_mountainram",
        name = "Epic Racial Mounts",
        category = "Mount Collection",
        difficulty = "Hard",
        timeEstimate = "Ongoing - limited by gold and having a level 60 of each race",
        timeRank = 3,
        note = "Reputation is NOT required to buy these - it only gives a small discount (roughly 10% off at Honored with your home city). You need a level 60 character of each race, riding skill trained, and gold. The real bottleneck is usually having 8 different races leveled to 60, not the gold itself. Each vendor sells a few color variants of the same mount for the same price - pick whichever color you like. Click a race to expand its 4-task checklist.",
        sections = {
            {
                icon = "ability_mount_ridinghorse",
                name = "Human - Swift Steed",
                pieces = BuildMountTasks("Human", "Swift Steed", "Katie Hunter", "Eastvale Logging Camp, Elwynn Forest", "Human", { "Swift .*Steed", "Swift Palomino" }),
            },
            {
                icon = "ability_mount_mountainram",
                name = "Dwarf - Swift Ram",
                pieces = BuildMountTasks("Dwarf", "Swift Ram", "Veron Amberstill", "Amberstill Ranch, Dun Morogh", "Dwarf", { "Swift .*Ram" }),
            },
            {
                icon = "ability_mount_whitetiger",
                name = "Night Elf - Swift Stormsaber",
                pieces = BuildMountTasks("Night Elf", "Reins of the Swift Stormsaber", "Lelanai", "Cenarion Enclave, Darnassus", "NightElf", { "Swift Frostsaber", "Swift Mistsaber", "Swift Stormsaber" }),
            },
            {
                icon = "ability_mount_mechastrider",
                name = "Gnome - Swift Mechanostrider",
                pieces = BuildMountTasks("Gnome", "Swift Mechanostrider", "Milli Featherwhistle", "Kharanos, Dun Morogh", "Gnome", { "Swift .*Mechanostrider" }),
            },
            {
                icon = "ability_mount_blackdirewolf",
                name = "Orc - Swift Timber Wolf",
                pieces = BuildMountTasks("Orc", "Horn of the Swift Timber Wolf", "Ogunaro Wolfrunner", "Valley of Honor, Orgrimmar", "Orc", { "Swift .*Wolf" }),
            },
            {
                icon = "ability_mount_kodo_03",
                name = "Tauren - Great Kodo",
                pieces = BuildMountTasks("Tauren", "Great Kodo", "Harb Clawhoof", "Bloodhoof Village, Mulgore", "Tauren", { "Great .*Kodo" }),
            },
            {
                icon = "ability_mount_undeadhorse",
                name = "Undead - Skeletal Warhorse",
                pieces = BuildMountTasks("Undead", "Skeletal Warhorse", "Zachariah Post", "Brill, Tirisfal Glades", "Scourge", { "Skeletal Warhorse" }),
            },
            {
                icon = "ability_mount_raptor",
                name = "Troll - Swift Raptor",
                pieces = BuildMountTasks("Troll", "Swift Raptor", "Zjolnir", "Sen'jin Village, Durotar", "Troll", { "Swift .*Raptor" }),
            },
        },
    },

    {
        id = "sulfuras",
        completeWith = { item = 17182 },
        icon = "inv_hammer_unique_sulfuras",
        name = "Sulfuras, Hand of Ragnaros",
        category = "Legendary Weapon",
        difficulty = "Very Hard",
        timeEstimate = "Months of weekly MC clears (Eye ~3%)",
        timeRank = 4,
        note = "Two-handed legendary mace. You need the Eye of Sulfuras from Ragnaros and a Sulfuron Hammer crafted by a 300 Blacksmith (you or someone you trust). Combining them is instant, with no quest turn-in.",
        steps = {
            { text = "Raid Molten Core on a weekly reset schedule.", auto = { level = 60 } },
            { text = "Loot the Eye of Sulfuras from Ragnaros (rare, roughly 3%).", auto = { item = 17204 } },
            { text = "Turn a Sulfuron Ingot in to Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths) via 'A Binding Contract' for the Plans: Sulfuron Hammer. No reputation needed.", auto = { item = 18592, quest = 7604 } },
            { text = "Collect 8 Sulfuron Ingots (Golemagg the Incinerator, Molten Core).", auto = { item = 17203, count = 8 } },
            { text = "Smelt 20 Dark Iron Bars at the Black Forge in Blackrock Depths.", auto = { item = 11371, count = 20 } },
            { text = "Gather 50 Arcanite Bars.", auto = { item = 12360, count = 50 } },
            { text = "Gather 25 Essence of Fire.", auto = { item = 7078, count = 25 } },
            { text = "Gather 10 Blood of the Mountain (rare from Dark Iron deposits).", auto = { item = 11382, count = 10 } },
            { text = "Gather 10 Lava Cores (Molten Core trash, BoE).", auto = { item = 17011, count = 10 } },
            { text = "Gather 10 Fiery Cores (Molten Core trash, BoE).", auto = { item = 17010, count = 10 } },
            { text = "Reach 300 Blacksmithing (or line up a 300 Blacksmith to craft it for you).", auto = { skill = { name = "Blacksmithing", rank = 300 } } },
            { text = "Craft the Sulfuron Hammer.", auto = { item = 17193 } },
            { text = "With both the Sulfuron Hammer and the Eye of Sulfuras in your bags, combine them to create Sulfuras, Hand of Ragnaros.", auto = { item = 17182 } },
        },
    },

    {
        id = "allclasses",
        group = true, -- pick classes individually in the Library
        autoLevels = true,
        icon = { "achievement_level_60", "inv_crown_01" },
        name = "Level Classes to 60",
        category = "Milestone",
        difficulty = "Very Hard",
        timeEstimate = "Ongoing - one full leveling run per class",
        timeRank = 5,
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
