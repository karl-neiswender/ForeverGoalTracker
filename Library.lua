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
--   skill = { name = "Fishing", rank = 300 }
--   boss = "Ragnaros"                         a kill seen while the addon runs
--   owned / ownedPattern = names              bags, gear or mount collection
--   money = copper, level = n

FGT.categoryColors["Reputation"] = { 0.40, 0.85, 0.55 }
FGT.categoryColors["Raid"]       = { 0.95, 0.40, 0.30 }
FGT.categoryColors["Profession"] = { 0.85, 0.70, 0.45 }
FGT.categoryColors["PvP"]        = { 0.55, 0.65, 1.00 }

local STANDINGS = { [5] = "Friendly", [6] = "Honored", [7] = "Revered", [8] = "Exalted" }

-- Friendly -> Exalted, each standing auto-ticked from your reputation.
local function RepSteps(factionId, howTo)
    local steps = {}
    for _, line in ipairs(howTo) do table.insert(steps, line) end
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
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "2-3 weeks of furbolg farming", timeRank = 2,
        note = "The furbolgs of Felwood and Winterspring. Rewards include safe passage through the Timbermaw tunnels and leatherworking patterns.",
        steps = RepSteps(576, {
            "Kill Deadwood furbolgs in Felwood and Winterfall furbolgs in Winterspring for reputation.",
            "Turn in Deadwood Headdress Feathers and Winterfall Spirit Beads in batches of 5 at Timbermaw Hold.",
        }),
    },
    {
        id = "rep_thorium", library = true,
        icon = { "achievement_reputation_thoriumbrotherhood", "trade_blacksmithing" },
        name = "Exalted: Thorium Brotherhood",
        category = "Reputation", difficulty = "Very Hard",
        timeEstimate = "Months of Molten Core and Blackrock Depths turn-ins", timeRank = 4,
        note = "Lokhtos Darkbargainer's epic crafting recipes unlock as you climb, including fire resistance gear.",
        steps = RepSteps(59, {
            "Turn in Dark Iron Ore and Fiery Flux to Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths) early on.",
            "From Honored on, turn in Molten Core materials such as Lava Cores and Fiery Cores.",
        }),
    },
    {
        id = "rep_argentdawn", library = true,
        icon = { "achievement_reputation_argentcrusader", "spell_holy_holybolt" },
        name = "Exalted: Argent Dawn",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "3-6 weeks", timeRank = 2,
        note = "Honored opens the Naxxramas attunement; Exalted unlocks the best Argent Dawn shoulder enchants.",
        steps = RepSteps(529, {
            "Wear an Argent Dawn Commission while killing undead in the Plaguelands, Stratholme and Scholomance.",
            "Turn in Scourgestones at Light's Hope Chapel or Chillwind Camp.",
        }),
    },
    {
        id = "rep_cenarion", library = true,
        icon = { "achievement_reputation_ogre", "inv_misc_herb_01" },
        name = "Exalted: Cenarion Circle",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "Several weeks of Silithus and AQ20", timeRank = 3,
        note = "The druids of Silithus. Ruins of Ahn'Qiraj kills and Twilight cultist turn-ins carry most of the grind.",
        steps = RepSteps(609, {
            "Do the Silithus quests at Cenarion Hold.",
            "Turn in Twilight Texts and run Ruins of Ahn'Qiraj for steady reputation.",
        }),
    },
    {
        id = "rep_zandalar", library = true,
        icon = { "achievement_reputation_zandalar", "inv_misc_coin_01" },
        name = "Exalted: Zandalar Tribe",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "1-2 months of Zul'Gurub", timeRank = 3,
        note = "Earned in Zul'Gurub. Unlocks the class-specific Zandalar armor sets and head/leg enchants.",
        steps = RepSteps(270, {
            "Clear Zul'Gurub; every kill in the raid gives Zandalar reputation.",
            "Turn in sets of ZG coins and bijous at Yojamba Isle.",
        }),
    },
    {
        id = "rep_hydraxian", library = true,
        icon = { "spell_frost_summonwaterelemental", "inv_misc_gem_pearl_04" },
        name = "Exalted: Hydraxian Waterlords",
        category = "Reputation", difficulty = "Hard",
        timeEstimate = "Weeks of Molten Core clears", timeRank = 3,
        note = "Needed to douse Molten Core's runes without Aqual Quintessence; Revered gives the Eternal Quintessence.",
        steps = RepSteps(749, {
            "Speak with Duke Hydraxis on his island east of Azshara and do his quest chain.",
            "Kill Molten Core trash and bosses; each kill adds reputation.",
        }),
    },
    {
        id = "rep_nozdormu", library = true,
        icon = { "achievement_reputation_nozdormu", "inv_misc_head_dragon_bronze", "inv_misc_head_dragon_01" },
        name = "Exalted: Brood of Nozdormu",
        category = "Reputation", difficulty = "Extreme",
        timeEstimate = "Months of Temple of Ahn'Qiraj", timeRank = 5,
        note = "Starts at Hated. The rings from Anachronos upgrade as you climb, and the grind is famously long.",
        steps = RepSteps(910, {
            "Complete 'The Charge of the Dragonflights' line to obtain your Signet Ring.",
            "Clear Temple of Ahn'Qiraj; kills and Ancient Qiraji Artifacts raise reputation.",
        }),
    },

    -- ---------------- Mounts ----------------
    {
        id = "mount_deathcharger", library = true,
        icon = "ability_mount_undeadhorse",
        name = "Deathcharger's Reins",
        category = "Mount", difficulty = "Extreme",
        timeEstimate = "Countless Stratholme runs (~1% drop)", timeRank = 5,
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
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "Weeks of Zul'Gurub (rare drop)", timeRank = 3,
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
        category = "Mount", difficulty = "Very Hard",
        timeEstimate = "Weeks of Zul'Gurub (rare drop)", timeRank = 3,
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
        category = "Mount", difficulty = "Extreme",
        timeEstimate = "Depends on your realm's gate event", timeRank = 5,
        note = "The black battle tank, originally awarded only to Scarab Lords who rang the gong at the opening of Ahn'Qiraj. Whether Forever offers it again depends on how its gate event runs.",
        steps = {
            "Take part in your realm's Ahn'Qiraj war effort and the Scepter of the Shifting Sands chain.",
            "Be the one who rings the Scarab Gong, or follow your realm's version of the event.",
            { text = "Own the Black Qiraji Resonating Crystal.", auto = { item = 21176, owned = { "Black Qiraji" } } },
        },
        completeWith = { item = 21176, owned = { "Black Qiraji" } },
    },

    -- ---------------- Weapons ----------------
    {
        id = "quelserrar", library = true,
        icon = "inv_sword_01",
        name = "Quel'Serrar",
        category = "Epic Weapon", difficulty = "Very Hard",
        timeEstimate = "Rare book drop plus an Onyxia kill", timeRank = 3,
        note = "Tanking sword (Warrior and Paladin) forged in Onyxia's breath.",
        steps = {
            "Loot Foror's Compendium of Dragon Slaying, a rare drop in Dire Maul.",
            { text = "Turn it in at the Dire Maul library to start 'The Forging of Quel'Serrar' and receive the Unfired Ancient Blade.",
              auto = { quest = { 7508, 7509 } } },
            "During an Onyxia fight, plant the blade where her fire breath will heat it.",
            "Grab the Heated Ancient Blade and drive it into Onyxia's corpse before it cools.",
            { text = "Return the Treated Ancient Blade to receive Quel'Serrar.", auto = { item = 18348 } },
        },
        completeWith = { item = 18348 },
    },

    -- ---------------- Raids ----------------
    {
        id = "raid_mc", library = true,
        icon = { "achievement_boss_ragnaros", "spell_fire_lavaspawn", "inv_misc_head_dragon_01" },
        name = "Clear Molten Core",
        category = "Raid", difficulty = "Hard",
        timeEstimate = "A few raid nights", timeRank = 2,
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
        category = "Raid", difficulty = "Hard",
        timeEstimate = "Attunement chain plus a raid night", timeRank = 2,
        note = "Needs the Drakefire Amulet from the faction-specific attunement chain.",
        steps = {
            "Complete the Onyxia attunement chain and earn the Drakefire Amulet.",
            { text = "Defeat Onyxia.", auto = { boss = "Onyxia" } },
            { text = "Loot the Head of Onyxia and turn it in at your capital city.", auto = { item = { 18422, 18423 } } },
        },
    },
    {
        id = "raid_bwl", library = true,
        icon = { "achievement_boss_nefarion", "inv_misc_head_dragon_black", "inv_misc_head_dragon_01" },
        name = "Clear Blackwing Lair",
        category = "Raid", difficulty = "Very Hard",
        timeEstimate = "Several raid nights", timeRank = 3,
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
        category = "Raid", difficulty = "Hard",
        timeEstimate = "A couple of raid nights", timeRank = 2,
        note = "The 20-player troll raid. Gahz'ranka and the Edge of Madness boss are optional.",
        steps = BossSteps({}, { "High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li",
            "Bloodlord Mandokir", "Edge of Madness", "High Priest Thekal", "Gahz'ranka",
            "High Priestess Arlokk", "Jin'do the Hexxer", "Hakkar" }),
    },
    {
        id = "raid_aq40", library = true,
        icon = { "achievement_boss_cthun", "inv_misc_qirajicrystal_05" },
        name = "Clear Temple of Ahn'Qiraj",
        category = "Raid", difficulty = "Very Hard",
        timeEstimate = "Weeks of progression", timeRank = 4,
        note = "The 40-player AQ raid. The Bug Trio, Viscidus and Ouro are optional for reaching C'Thun.",
        steps = BossSteps({}, { "The Prophet Skeram", { "Silithid Royalty", "Bug Trio" }, "Battleguard Sartura",
            "Fankriss the Unyielding", "Viscidus", "Princess Huhuran", { "Twin Emperors", "Emperor Vek" }, "Ouro", "C'Thun" }),
    },
    {
        id = "raid_naxx", library = true,
        icon = { "achievement_boss_kelthuzad_01", "inv_misc_head_dragon_01" },
        name = "Clear Naxxramas",
        category = "Raid", difficulty = "Extreme",
        timeEstimate = "Months of progression", timeRank = 5,
        note = "The hardest raid in the game: all four wings, Sapphiron and Kel'Thuzad.",
        steps = BossSteps({
            { text = "Get attuned to Naxxramas at Light's Hope Chapel.", auto = { quest = { 9121, 9122, 9123 } } },
        }, { "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean",
             "Loatheb", "Instructor Razuvious", "Gothik the Harvester", { "Four Horsemen" }, "Patchwerk",
             "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" }),
    },

    -- ---------------- Professions ----------------
    {
        id = "prof_secondary", library = true, group = true,
        icon = { "trade_fishing" },
        name = "Max Secondary Skills",
        category = "Profession", difficulty = "Moderate",
        timeEstimate = "A few weeks alongside leveling", timeRank = 2,
        note = "Fishing, Cooking and First Aid to 300 on any character. Pick the ones you want in the Library; each ticks itself from your skill levels.",
        steps = { SkillStep("Fishing", 300), SkillStep("Cooking", 300), SkillStep("First Aid", 300) },
    },
    {
        id = "prof_all", library = true, group = true,
        icon = { "trade_engineering" },
        name = "Max Primary Professions",
        category = "Profession", difficulty = "Extreme",
        timeEstimate = "Ongoing across your alts", timeRank = 5,
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
        timeEstimate = "Depends on your gold-making", timeRank = 3,
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
            table.insert(list, { name = p[1], materials = {}, auto = { item = p[2], owned = { p[1] } } })
        end
        table.insert(sections, { icon = "ClassIcon_" .. class, name = class .. " - " .. setName, pieces = list })
    end
    return sections
end

local TIER1 = {
    { "Warrior", "Battlegear of Might", { { "Helm of Might", 16866 }, { "Pauldrons of Might", 16868 }, { "Breastplate of Might", 16865 }, { "Gauntlets of Might", 16863 }, { "Legplates of Might", 16867 }, { "Belt of Might", 16864 }, { "Bracers of Might", 16861 }, { "Sabatons of Might", 16862 } } },
    { "Paladin", "Lawbringer Armor", { { "Lawbringer Helm", 16854 }, { "Lawbringer Spaulders", 16856 }, { "Lawbringer Chestguard", 16853 }, { "Lawbringer Gauntlets", 16860 }, { "Lawbringer Legplates", 16855 }, { "Lawbringer Belt", 16858 }, { "Lawbringer Bracers", 16857 }, { "Lawbringer Boots", 16859 } } },
    { "Hunter", "Giantstalker Armor", { { "Giantstalker's Helmet", 16846 }, { "Giantstalker's Epaulets", 16848 }, { "Giantstalker's Breastplate", 16845 }, { "Giantstalker's Gloves", 16852 }, { "Giantstalker's Leggings", 16847 }, { "Giantstalker's Belt", 16851 }, { "Giantstalker's Bracers", 16850 }, { "Giantstalker's Boots", 16849 } } },
    { "Rogue", "Nightslayer Armor", { { "Nightslayer Cover", 16821 }, { "Nightslayer Shoulder Pads", 16823 }, { "Nightslayer Chestpiece", 16820 }, { "Nightslayer Gloves", 16826 }, { "Nightslayer Pants", 16822 }, { "Nightslayer Belt", 16827 }, { "Nightslayer Bracelets", 16825 }, { "Nightslayer Boots", 16824 } } },
    { "Priest", "Vestments of Prophecy", { { "Circlet of Prophecy", 16813 }, { "Mantle of Prophecy", 16816 }, { "Robes of Prophecy", 16815 }, { "Gloves of Prophecy", 16812 }, { "Pants of Prophecy", 16814 }, { "Girdle of Prophecy", 16817 }, { "Vambraces of Prophecy", 16819 }, { "Boots of Prophecy", 16811 } } },
    { "Shaman", "The Earthfury", { { "Earthfury Helmet", 16842 }, { "Earthfury Epaulets", 16844 }, { "Earthfury Vestments", 16841 }, { "Earthfury Gauntlets", 16839 }, { "Earthfury Legguards", 16843 }, { "Earthfury Belt", 16838 }, { "Earthfury Bracers", 16840 }, { "Earthfury Boots", 16837 } } },
    { "Mage", "Arcanist Regalia", { { "Arcanist Crown", 16795 }, { "Arcanist Mantle", 16797 }, { "Arcanist Robes", 16798 }, { "Arcanist Gloves", 16801 }, { "Arcanist Leggings", 16796 }, { "Arcanist Belt", 16802 }, { "Arcanist Bindings", 16799 }, { "Arcanist Boots", 16800 } } },
    { "Warlock", "Felheart Raiment", { { "Felheart Horns", 16808 }, { "Felheart Shoulder Pads", 16807 }, { "Felheart Robes", 16809 }, { "Felheart Gloves", 16805 }, { "Felheart Pants", 16810 }, { "Felheart Belt", 16806 }, { "Felheart Bracers", 16804 }, { "Felheart Slippers", 16803 } } },
    { "Druid", "Cenarion Raiment", { { "Cenarion Helm", 16834 }, { "Cenarion Spaulders", 16836 }, { "Cenarion Vestments", 16833 }, { "Cenarion Gloves", 16831 }, { "Cenarion Leggings", 16835 }, { "Cenarion Belt", 16828 }, { "Cenarion Bracers", 16830 }, { "Cenarion Boots", 16829 } } },
}

local TIER2 = {
    { "Warrior", "Battlegear of Wrath", { { "Helm of Wrath", 16963 }, { "Pauldrons of Wrath", 16961 }, { "Breastplate of Wrath", 16966 }, { "Gauntlets of Wrath", 16964 }, { "Legplates of Wrath", 16962 }, { "Waistband of Wrath", 16960 }, { "Bracelets of Wrath", 16959 }, { "Sabatons of Wrath", 16965 } } },
    { "Paladin", "Judgement Armor", { { "Judgement Crown", 16955 }, { "Judgement Spaulders", 16953 }, { "Judgement Breastplate", 16958 }, { "Judgement Gauntlets", 16956 }, { "Judgement Legplates", 16954 }, { "Judgement Belt", 16952 }, { "Judgement Bindings", 16951 }, { "Judgement Sabatons", 16957 } } },
    { "Hunter", "Dragonstalker Armor", { { "Dragonstalker's Helm", 16939 }, { "Dragonstalker's Spaulders", 16937 }, { "Dragonstalker's Breastplate", 16942 }, { "Dragonstalker's Gauntlets", 16940 }, { "Dragonstalker's Legguards", 16938 }, { "Dragonstalker's Belt", 16936 }, { "Dragonstalker's Bracers", 16935 }, { "Dragonstalker's Greaves", 16941 } } },
    { "Rogue", "Bloodfang Armor", { { "Bloodfang Hood", 16908 }, { "Bloodfang Spaulders", 16832 }, { "Bloodfang Chestpiece", 16905 }, { "Bloodfang Gloves", 16907 }, { "Bloodfang Pants", 16909 }, { "Bloodfang Belt", 16910 }, { "Bloodfang Bracers", 16911 }, { "Bloodfang Boots", 16906 } } },
    { "Priest", "Vestments of Transcendence", { { "Halo of Transcendence", 16921 }, { "Pauldrons of Transcendence", 16924 }, { "Robes of Transcendence", 16923 }, { "Handguards of Transcendence", 16920 }, { "Leggings of Transcendence", 16922 }, { "Belt of Transcendence", 16925 }, { "Bindings of Transcendence", 16926 }, { "Boots of Transcendence", 16919 } } },
    { "Shaman", "The Ten Storms", { { "Helmet of Ten Storms", 16947 }, { "Epaulets of Ten Storms", 16945 }, { "Breastplate of Ten Storms", 16950 }, { "Gauntlets of Ten Storms", 16948 }, { "Legplates of Ten Storms", 16946 }, { "Belt of Ten Storms", 16944 }, { "Bracers of Ten Storms", 16943 }, { "Greaves of Ten Storms", 16949 } } },
    { "Mage", "Netherwind Regalia", { { "Netherwind Crown", 16914 }, { "Netherwind Mantle", 16917 }, { "Netherwind Robes", 16916 }, { "Netherwind Gloves", 16913 }, { "Netherwind Pants", 16915 }, { "Netherwind Belt", 16818 }, { "Netherwind Bindings", 16918 }, { "Netherwind Boots", 16912 } } },
    { "Warlock", "Nemesis Raiment", { { "Nemesis Skullcap", 16929 }, { "Nemesis Spaulders", 16932 }, { "Nemesis Robes", 16931 }, { "Nemesis Gloves", 16928 }, { "Nemesis Leggings", 16930 }, { "Nemesis Belt", 16933 }, { "Nemesis Bracers", 16934 }, { "Nemesis Boots", 16927 } } },
    { "Druid", "Stormrage Raiment", { { "Stormrage Cover", 16900 }, { "Stormrage Pauldrons", 16902 }, { "Stormrage Chestguard", 16897 }, { "Stormrage Handguards", 16899 }, { "Stormrage Legguards", 16901 }, { "Stormrage Belt", 16903 }, { "Stormrage Bracers", 16904 }, { "Stormrage Boots", 16898 } } },
}

local sets = {
    {
        id = "set_tier1", library = true, group = true,
        icon = "inv_helmet_09",
        name = "Tier 1 Set Appearances",
        category = "Item Set", difficulty = "Hard",
        timeEstimate = "Weeks of Molten Core per set", timeRank = 3,
        note = "The Molten Core sets. Most pieces drop from Molten Core bosses; belts and bracers come from Molten Core trash. Pick the classes you want in the Library; each piece ticks itself when you own it.",
        sections = BuildSetSections(TIER1),
    },
    {
        id = "set_tier2", library = true, group = true,
        icon = "inv_helmet_71",
        name = "Tier 2 Set Appearances",
        category = "Item Set", difficulty = "Very Hard",
        timeEstimate = "Months of Blackwing Lair per set", timeRank = 4,
        note = "Helms come from Onyxia, legs from Ragnaros, and the rest from Blackwing Lair. Pick the classes you want in the Library; each piece ticks itself when you own it.",
        sections = BuildSetSections(TIER2),
    },
    {
        id = "set_viper", library = true,
        icon = "inv_shirt_16",
        name = "Embrace of the Viper",
        category = "Item Set", difficulty = "Moderate",
        timeEstimate = "A handful of Wailing Caverns runs", timeRank = 1,
        note = "A five-piece leather set from Wailing Caverns. A druid wearing all five is transformed into a serpent, with coloring that depends on race.",
        steps = {
            { text = "Armor of the Fang (chest) from Lord Pythas.", icon = "inv_shirt_16", auto = { item = 6473, owned = { "Armor of the Fang" } } },
            { text = "Leggings of the Fang from Lord Cobrahn.", auto = { item = 10410, owned = { "Leggings of the Fang" } } },
            { text = "Footpads of the Fang from Lord Serpentis.", auto = { item = 10411, owned = { "Footpads of the Fang" } } },
            { text = "Belt of the Fang from Lady Anacondra.", auto = { item = 10412, owned = { "Belt of the Fang" } } },
            { text = "Gloves of the Fang, a rare drop from Druids of the Fang.", auto = { item = 10413, owned = { "Gloves of the Fang" } } },
            "Equip all five on a druid to take serpent form.",
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
    for _, line in ipairs(how) do table.insert(steps, line) end
    for st = 5, 8 do
        table.insert(steps, { text = "Reach " .. ({ [5] = "Friendly", [6] = "Honored", [7] = "Revered", [8] = "Exalted" })[st] .. ".",
                              auto = { rep = { faction = factionId, standing = st }, forFaction = faction } })
    end
    return {
        id = id, library = true, faction = faction,
        icon = icon, name = "Exalted: " .. name,
        category = "PvP", difficulty = "Hard",
        timeEstimate = "Several weeks of " .. bg, timeRank = 3,
        note = string.format("The %s %s battleground faction. Exalted unlocks its best rewards.", faction, bg),
        steps = steps,
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
        timeEstimate = "Months of top-of-bracket honor", timeRank = 5,
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
        category = "PvP", difficulty = "Very Hard",
        timeEstimate = "Weeks of steady honor", timeRank = 4,
        note = "The epic PvP mount, sold to " .. RANKS[f][11] .. "s and above: " .. table.concat(mounts, ", ") .. ".",
        steps = {
            "Earn honor every week in battlegrounds and world PvP to climb the ranks.",
            RankStep(f, 11),
            { text = "Buy a war mount from your faction's PvP quartermaster.", auto = { owned = mounts, forFaction = f } },
        },
        completeWith = { owned = mounts, forFaction = f },
    })

    local avMount = A and "Stormpike Battle Charger" or "Frostwolf Howler"
    table.insert(pvp, {
        id = "pvp_avmount_" .. key, library = true, faction = f,
        icon = A and { "ability_mount_mountainram", "inv_bannerpvp_02" } or { "ability_mount_whitedirewolf", "ability_mount_blackdirewolf" },
        name = avMount,
        category = "PvP", difficulty = "Hard",
        timeEstimate = "Several weeks of Alterac Valley", timeRank = 3,
        note = "Alterac Valley's exalted mount for the " .. (A and "Stormpike Guard" or "Frostwolf Clan") .. ".",
        steps = {
            "Play Alterac Valley; turn in armor scraps, blood and crystals between matches.",
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
    timeEstimate = "Ongoing", timeRank = 4,
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
