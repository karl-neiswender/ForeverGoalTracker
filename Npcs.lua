local ADDON, FGT = ...

-- ============================================================
-- NPCs named in steps and tips
-- ============================================================
-- Their names become teal links (FGT.LinkText): hover for where they
-- stand, click to put a pin on the map (a TomTom waypoint when TomTom is
-- installed), right-click for the Wowhead link. Only people you travel
-- to; raid and dungeon bosses stay plain text.
--
-- From Wowhead Classic (2026-10-07): id = NPC id, map = uiMapID, x/y in
-- percent. alias = shorter names steps use too ("Vartrus").
-- disguise = the friendly form a demon hides as, where the pin goes.
-- where = shown instead of a pin (inside an instance, no coordinates).
-- forever = true for Forever-only NPCs (Wowhead's /forever/ database).
-- f = { map, x, y }: a different spot on Forever. missingInForever = true:
-- not in Wowhead's Forever database (the tooltip says so on Forever).
-- Checked 2026-10-07: every Classic NPC below is in the Forever database.
FGT.NPCS = {
    -- Weapon trainer listed in Wowhead Forever, checked 2026-10-11.
    -- Archibald walks the War Quarter (Wowhead puts him within a few units of 57, 32).
    { id = 11870, name = "Archibald", tag = "Weapon Master", where = "Undercity, in the War Quarter", map = 1458, zone = "Undercity", x = 57.0, y = 32.4 },
    -- Wolfsbane's quest chain (Wowhead Forever, checked 2026-10-15): the giver of each step.
    { id = 246378, name = "Danitha Morr", forever = true, map = 1420, zone = "Tirisfal Glades", x = 22.0, y = 44.6, where = "At Bandarion Keep" },
    { id = 248840, name = "Trevan Rol", forever = true, map = 1421, zone = "Silverpine Forest", x = 43.4, y = 41.0, where = "At the Sepulcher" },
    { id = 259611, name = "Deathguard Baldren", forever = true, map = 1421, zone = "Silverpine Forest", x = 45.6, y = 41.8, where = "At the Sepulcher" },
    { id = 259620, name = "Lumina Windsinger", forever = true, map = 1421, zone = "Silverpine Forest", x = 43.2, y = 41.0, where = "At the Sepulcher (another Lumina is in Fenris Keep)" },
    { id = 259649, name = "Ulric Frostveil", forever = true, map = 1440, zone = "Ashenvale", x = 11.8, y = 34.5, where = "At the Zoram Strand" },
    { id = 3539, name = "Ott", forever = true, map = 1424, zone = "Hillsbrad Foothills", x = 60.4, y = 26.0, where = "In Tarren Mill" },
    -- Classic fishing tournament guide, Wowhead, 2026-10-10.
    { id = 15077, name = "Riggle Bassbait", tag = "Fishmaster", where = "Booty Bay, on the central docks near the inn during the fishing tournament" },
    -- AQ40 turn-ins: Classic IDs and instance location checked on Wowhead's
    -- Tier 2.5 guide, 2026-10-10. Forever positions are not yet verified.
    { id = 15502, name = "Andorgos", where = "Inside Temple of Ahn'Qiraj, near C'Thun's chamber" },
    { id = 15503, name = "Kandrostrasz", where = "Inside Temple of Ahn'Qiraj, near C'Thun's chamber" },
    { id = 15504, name = "Vethsera", where = "Inside Temple of Ahn'Qiraj, near C'Thun's chamber" },
    -- quest givers and turn-ins
    { id = 16116, name = "Archmage Angela Dosantos", tag = "Brotherhood of the Light", map = 1423, zone = "Eastern Plaguelands", x = 81.4, y = 58.2 },
    { id = 10618, name = "Rivern Frostwind", tag = "Wintersaber Trainers", map = 1452, zone = "Winterspring", x = 49.8, y = 9.8 },
    { id = 15192, name = "Anachronos", map = 1446, zone = "Tanaris", x = 65.2, y = 50.0 },
    { id = 14524, name = "Vartrus the Ancient", alias = { "Vartrus" }, map = 1448, zone = "Felwood", x = 48.8, y = 24.2 },
    { id = 14525, name = "Stoma the Ancient", map = 1448, zone = "Felwood", x = 48.6, y = 23.2 }, -- next to Vartrus
    { id = 14347, name = "Highlord Demitrian", alias = { "Demitrian" }, map = 1451, zone = "Silithus", x = 21.6, y = 8.4 },
    { id = 14494, name = "Eris Havenfire", alias = { "Eris" }, map = 1423, zone = "Eastern Plaguelands", x = 20.8, y = 18.4 },
    { id = 5520, name = "Spackle Thornberry", tag = "Demon Trainer", map = 1453, zone = "Stormwind City", x = 25.8, y = 77.6 },
    { id = 6171, name = "Duthorian Rall", map = 1453, zone = "Stormwind City", x = 39.8, y = 29.8 },
    { id = 14387, name = "Lothos Riftwaker", where = "Inside Blackrock Mountain, by the Molten Core portal",
      f = { 1428, 26.4, 24.6, "Burning Steppes" } }, -- Forever maps him outside
    { id = 12944, name = "Lokhtos Darkbargainer", alias = { "Lokhtos" }, tag = "The Thorium Brotherhood", where = "Inside Blackrock Depths, in the Grim Guzzler" },
    { id = 9562, name = "Helendis Riverhorn", map = 1428, zone = "Burning Steppes", x = 85.4, y = 68.8 },
    { id = 9077, name = "Warlord Goretooth", tag = "Kargath Expeditionary Force", map = 1418, zone = "Badlands", x = 5.8, y = 47.6 },
    -- named in tips (2026-10-07 sweep): out in the world, same spot on Forever
    { id = 6109, name = "Azuregos", map = 1447, zone = "Azshara", x = 48.0, y = 75.4 },
    { id = 13278, name = "Duke Hydraxis", map = 1447, zone = "Azshara", x = 79.2, y = 73.4 },
    -- quest givers (Quests.lua starts), checked on Wowhead Classic and
    -- Forever 2026-10-07: same spots on both
    { id = 14526, name = "Hastat the Ancient", map = 1448, zone = "Felwood", x = 48.2, y = 24.2 },
    { id = 14368, name = "Lorekeeper Lydros", where = "Inside Dire Maul, in the library" },
    { id = 14358, name = "Shen'dralar Ancient", where = "Inside Dire Maul, in the library" },
    { id = 13816, name = "Prospector Stonehewer", map = 1416, zone = "Alterac Mountains", x = 40.6, y = 79.6 },
    { id = 14436, name = "Mor'zul Bloodbringer", map = 1428, zone = "Burning Steppes", x = 12.6, y = 31.4 },
    { id = 14437, name = "Gorzeeki Wildeyes", map = 1428, zone = "Burning Steppes", x = 12.4, y = 31.4 },
    { id = 14470, name = "Impsy", tag = "Niby's Minion", map = 1448, zone = "Felwood", x = 41.4, y = 44.8 },
    { id = 6382, name = "Jubahl Corpseseeker", tag = "Demon Trainer", map = 1455, zone = "Ironforge", x = 52.8, y = 6.0 },
    { id = 5753, name = "Martha Strain", tag = "Demon Trainer", map = 1458, zone = "Undercity", x = 85.4, y = 15.8 },
    { id = 5815, name = "Kurgul", tag = "Demon Trainer", map = 1454, zone = "Orgrimmar", x = 47.4, y = 46.8 },
    { id = 928, name = "Lord Grayson Shadowbreaker", tag = "Paladin Trainer", map = 1453, zone = "Stormwind City", x = 37.2, y = 33.0 },
    { id = 11406, name = "High Priest Rohan", tag = "Priest Trainer", map = 1455, zone = "Ironforge", x = 23.4, y = 6.4 },
    { id = 1416, name = "Grimand Elmore", map = 1453, zone = "Stormwind City", x = 51.6, y = 12.2 },
    { id = 2357, name = "Merideth Carlson", tag = "Horse Breeder", map = 1424, zone = "Hillsbrad Foothills", x = 52.0, y = 55.6 },
    { id = 11056, name = "Alchemist Arbington", map = 1422, zone = "Western Plaguelands", x = 42.6, y = 83.8 },
    { id = 11057, name = "Apothecary Dithers", map = 1420, zone = "Tirisfal Glades", x = 83.2, y = 69.2 },
    { id = 8888, name = "Franclorn Forgewright", where = "Inside Blackrock Mountain, as a spirit by his statue" },
    { id = 10299, name = "Scarshield Infiltrator", tag = "Scarshield Legion", where = "Inside Blackrock Spire" },
    { id = 9560, name = "Marshal Maxwell", map = 1428, zone = "Burning Steppes", x = 84.6, y = 68.8 },
    { id = 9023, name = "Marshal Windsor", where = "Inside Blackrock Depths, in the prison" },
    { id = 12580, name = "Reginald Windsor", map = 1429, zone = "Elwynn Forest", x = 32.0, y = 49.2 },
    { id = 1748, name = "Highlord Bolvar Fordragon", map = 1453, zone = "Stormwind City", x = 77.4, y = 18.8 },
    { id = 10929, name = "Haleh", map = 1452, zone = "Winterspring", x = 54.4, y = 51.2 },
    { id = 4949, name = "Thrall", tag = "Warchief", map = 1454, zone = "Orgrimmar", x = 32.0, y = 37.8 },
    { id = 10182, name = "Rexxar", tag = "Champion of the Horde", map = 1443, zone = "Desolace", x = 39.4, y = 79.4,
      where = "Walks the road through Stonetalon Mountains, Desolace and Feralas" },
    { id = 11872, name = "Myranda the Hag", map = 1422, zone = "Western Plaguelands", x = 50.8, y = 77.8 },
    { id = 10321, name = "Emberstrife", map = 1445, zone = "Dustwallow Marsh", x = 56.2, y = 88.0 },
    -- Rhok'delar demons: each hides as a friendly NPC until you talk to them
    { id = 14535, name = "Artorius the Doombringer", disguise = "Artorius the Amiable", map = 1452, zone = "Winterspring", x = 51.4, y = 36.2 },
    { id = 14534, name = "Klinfran the Crazed", disguise = "Franklin the Friendly", map = 1428, zone = "Burning Steppes", x = 17.0, y = 54.0 },
    { id = 14530, name = "Solenor the Slayer", disguise = "Nelson the Nice", map = 1451, zone = "Silithus", x = 18.2, y = 78.2, f = { 1451, 20.2, 79.6 } },
    { id = 14533, name = "Simone the Seductress", disguise = "Simone the Inconspicuous", wanders = true, map = 1449, zone = "Un'Goro Crater", x = 24.2, y = 54.6 },
    -- Classic PvP halls, researched 2026-10-17; pins show the hall approach, not an
    -- exact indoor vendor position. Forever positions still need native confirmation.
    { id = 12783, name = "Lieutenant Karter", tag = "Mount Vendor", map = 1453, zone = "Stormwind City", x = 72.4, y = 50.8,
      where = "Inside Champions' Hall in Old Town. The pin shows the hall approach.", unverifiedInForever = true },
    { id = 12796, name = "Raider Bork", tag = "Mount Quartermaster", map = 1454, zone = "Orgrimmar", x = 39.9, y = 69.1,
      where = "Inside the Hall of Legends. The pin shows the hall approach.", unverifiedInForever = true },
    -- Alterac Valley mount vendors, outside the battleground
    { id = 13217, name = "Thanthaldis Snowgleam", tag = "Stormpike Supply Officer", map = 1416, zone = "Alterac Mountains", x = 39.4, y = 81.4 },
    { id = 13219, name = "Jekyll Flandring", tag = "Frostwolf Supply Officer", map = 1416, zone = "Alterac Mountains", x = 62.8, y = 59.4 },
    -- epic racial mount vendors (also VENDOR_NPC in Data.lua)
    { id = 384, name = "Katie Hunter", tag = "Horse Breeder", map = 1429, zone = "Elwynn Forest", x = 84.0, y = 65.4 },
    { id = 1261, name = "Veron Amberstill", tag = "Ram Breeder", map = 1426, zone = "Dun Morogh", x = 63.4, y = 50.6 },
    { id = 4730, name = "Lelanai", tag = "Saber Handler", map = 1457, zone = "Darnassus", x = 38.4, y = 15.6 },
    { id = 7955, name = "Milli Featherwhistle", tag = "Mechanostrider Merchant", map = 1426, zone = "Dun Morogh", x = 49.2, y = 48.0 },
    { id = 3362, name = "Ogunaro Wolfrunner", tag = "Kennel Master", map = 1454, zone = "Orgrimmar", x = 69.4, y = 12.4 },
    { id = 3685, name = "Harb Clawhoof", tag = "Kodo Mounts", map = 1412, zone = "Mulgore", x = 47.4, y = 58.4, f = { 1412, 46.6, 62.0 } },
    { id = 4731, name = "Zachariah Post", tag = "Undead Horse Merchant", map = 1420, zone = "Tirisfal Glades", x = 59.8, y = 52.6 },
    { id = 7952, name = "Zjolnir", tag = "Raptor Handler", map = 1411, zone = "Durotar", x = 55.2, y = 75.4 },
    { id = 265756, name = "Genn Fairweather", tag = "Stablemaster and Riding Trainer", forever = true, map = 2521, zone = "Zephras Isle", x = 53.8, y = 81.2 },
}

-- Where a reputation's goal page points its "Show on map" link: the faction's main hub, for the
-- Exalted goals that have one clear place (Karl, 2026-10-15). Keyed by goal id. They are not
-- people in steps, so they are never linked by name; npcId is the person whose spot it is (the
-- Wowhead link). Spots from Wowhead Classic and Forever (same on both, checked 2026-10-15):
-- Archmage Angela Dosantos stands in Light's Hope Chapel, Commander Mar'alith in Cenarion Hold.
-- Left out on purpose, no single place on a map: Timbermaw Hold (Felwood and Winterspring),
-- Thorium Brotherhood and Zandalar Tribe (inside Blackrock Depths and Zul'Gurub), the
-- Ambassador goals (four capitals).
FGT.HUBS = {
    rep_argentdawn = { id = "hub:rep_argentdawn", name = "Light's Hope Chapel", npcId = 16116, map = 1423, zone = "Eastern Plaguelands", x = 81.4, y = 58.2 },
    rep_cenarion = { id = "hub:rep_cenarion", name = "Cenarion Hold", npcId = 15181, map = 1451, zone = "Silithus", x = 49.2, y = 34.2 },
    rep_hydraxian = { id = "hub:rep_hydraxian", name = "Duke Hydraxis", npcId = 13278, map = 1447, zone = "Azshara", x = 79.2, y = 73.4 },
    -- Raid entrances (raid goals, the same link). World positions are the game's own dungeon entrance
    -- data (wago.tools JournalInstanceEntrance), turned into map spots with Classic Era's map bounds
    -- (UiMapAssignment, build 1.15.9.70003, 2026-10-15). The method reproduces the Zul'Gurub entrance
    -- Karl knows; Forever hasn't confirmed them. Left out: Molten Core and Blackwing Lair (the door
    -- is inside Blackrock Mountain, not clearly on one zone map) and Naxxramas
    -- (the game lists only Northrend's). Ahn'Qiraj positions below were supplied by Karl.
    raid_ony = { id = "hub:raid_ony", name = "Onyxia's Lair", unverifiedInForever = true, map = 1445, zone = "Dustwallow Marsh", x = 52.9, y = 78.1 },
    raid_zg = { id = "hub:raid_zg", name = "Zul'Gurub", unverifiedInForever = true, map = 1434, zone = "Stranglethorn Vale", x = 53.9, y = 17.6 },
    -- Shared entrance location confirmed by Karl, 2026-10-16.
    raid_aq20 = { id = "hub:raid_aq20", name = "Ruins of Ahn'Qiraj", map = 1451, zone = "Silithus", x = 29, y = 92.8 },
    raid_aq40 = { id = "hub:raid_aq40", name = "Temple of Ahn'Qiraj", alias = { "Ahn'Qiraj Temple" }, map = 1451, zone = "Silithus", x = 29, y = 92.8 },
    rep_nozdormu = { id = "hub:rep_nozdormu", name = "Caverns of Time", npcId = 15192, map = 1446, zone = "Tanaris", x = 65.2, y = 50.0 },
}

-- Outdoor approaches, not boss positions. Coordinate facts checked 2026-10-16 against
-- https://github.com/callie-g/HandyNotes_DungeonLocations-classic/blob/main/classic.lua
-- Cave and mountain entrances still require travelling inside to reach the portal.
-- Classic reference positions remain Unconfirmed on Forever.
-- levels = the usual Classic Era level range as text (warcrafttavern.com dungeon table, checked 2026-10-25;
-- wings share one range). Not the entry requirement. Forever ranges are unverified.
FGT.DUNGEONS = {
    -- Explicit {map:} tags in war-mount guides; do not auto-link city names elsewhere.
    { id = "dungeon:pvp_alliance", name = "Champions' Hall", map = 1453, zone = "Stormwind City", x = 72.4, y = 50.8,
      unverifiedInForever = true, where = "Hall approach in Old Town. Lieutenant Karter is inside." },
    { id = "dungeon:pvp_horde", name = "Hall of Legends", map = 1454, zone = "Orgrimmar", x = 39.9, y = 69.1,
      unverifiedInForever = true, where = "Hall approach. Raider Bork is inside." },
    { id = "dungeon:bfd", name = "Blackfathom Deeps", levels = "22-28", map = 1440, zone = "Ashenvale", x = 14, y = 13.1, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:uldaman", name = "Uldaman", levels = "36-45", map = 1418, zone = "Badlands", x = 44.53, y = 12.12, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:rfd", name = "Razorfen Downs", levels = "38-42", map = 1413, zone = "The Barrens", x = 49.13, y = 93.48, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:rfk", name = "Razorfen Kraul", levels = "29-34", map = 1413, zone = "The Barrens", x = 41.89, y = 89.5, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:wc", name = "Wailing Caverns", levels = "17-24", map = 1413, zone = "The Barrens", x = 47.7, y = 35, unverifiedInForever = false, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:brd", name = "Blackrock Depths", levels = "52-60", map = 1428, zone = "Burning Steppes", x = 29.94, y = 47.78, unverifiedInForever = true, where = "Enter Blackrock Mountain, then follow the route down to Blackrock Depths." },
    { id = "dungeon:brs", name = "Blackrock Spire", levels = "57-60", map = 1428, zone = "Burning Steppes", x = 29.94, y = 47.78, unverifiedInForever = true, where = "Enter Blackrock Mountain, then follow the route up to Blackrock Spire.", alias = { "Upper Blackrock Spire", "Lower Blackrock Spire" } },
    { id = "dungeon:mara", name = "Maraudon", levels = "45-51", map = 1443, zone = "Desolace", x = 29.1, y = 62.5, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:gnomer", name = "Gnomeregan", levels = "30-35", map = 1426, zone = "Dun Morogh", x = 24.46, y = 39.81, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:strat", name = "Stratholme", levels = "58-60", mapZoom = 44, map = 1423, zone = "Eastern Plaguelands", x = 30.85, y = 17, unverifiedInForever = true, where = "Shows the main entrance. The service entrance is separate." },
    { id = "dungeon:dm", name = "Dire Maul", levels = "58-60", map = 1444, zone = "Feralas", x = 59.11, y = 43.28, unverifiedInForever = true, where = "Shows the outdoor approach to Dire Maul. Follow the route to your wing." },
    { id = "dungeon:rfc", name = "Ragefire Chasm", levels = "13-18", map = 1454, zone = "Orgrimmar", x = 51.6, y = 49.83, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:sfk", name = "Shadowfang Keep", levels = "20-26", map = 1421, zone = "Silverpine Forest", x = 44.8, y = 67.8, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:stock", name = "The Stockade", levels = "25-29", map = 1453, zone = "Stormwind City", x = 40.28, y = 55.21, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal.", alias = { "Stockades", "Stockade" } },
    { id = "dungeon:st", name = "Sunken Temple", levels = "50-55", map = 1435, zone = "Swamp of Sorrows", x = 69.5, y = 52.5, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal.", alias = { "The Temple of Atal'hakkar", "Temple of Atal'Hakkar" } },
    { id = "dungeon:zf", name = "Zul'Farrak", levels = "40-47", map = 1446, zone = "Tanaris", x = 38.72, y = 20, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:sm", name = "Scarlet Monastery", levels = "30-45", map = 1420, zone = "Tirisfal Glades", x = 85.3, y = 32.2, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:scholo", name = "Scholomance", levels = "58-60", map = 1422, zone = "Western Plaguelands", x = 69, y = 72.9, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    { id = "dungeon:deadmines", name = "Deadmines", levels = "15-22", map = 1436, zone = "Westfall", x = 42.57, y = 71.71, unverifiedInForever = true, where = "Shows the outdoor approach. Continue inside to reach the instance portal." },
    -- Raid entrances for the Gear Planner's source links. `manual` keeps them out of the automatic
    -- name linking in other guides; the planner tags them itself. Positions checked 2026-10-19 against
    -- the same HandyNotes_DungeonLocations-classic file as above (Onyxia 52.9/77.7, Naxxramas 39.0/26.0,
    -- Blackrock Mountain 29.94/47.78). Molten Core and Blackwing Lair are reached through Blackrock Mountain.
    { id = "dungeon:mc", name = "Molten Core", manual = true, map = 1428, zone = "Burning Steppes", x = 29.94, y = 47.78, unverifiedInForever = true, where = "Enter Blackrock Mountain, then follow the route down through Blackrock Depths to Molten Core." },
    { id = "dungeon:bwl", name = "Blackwing Lair", manual = true, map = 1428, zone = "Burning Steppes", x = 29.94, y = 47.78, unverifiedInForever = true, where = "Enter Blackrock Mountain, then follow the route up through Blackrock Spire to Blackwing Lair." },
    { id = "dungeon:ony", name = "Onyxia's Lair", manual = true, map = 1445, zone = "Dustwallow Marsh", x = 52.9, y = 77.7, unverifiedInForever = true, where = "Shows the cave entrance in the Wyrmbog." },
    { id = "dungeon:naxx", name = "Naxxramas", manual = true, map = 1423, zone = "Eastern Plaguelands", x = 39, y = 26, unverifiedInForever = true, where = "Shows the floating necropolis. Enter at the portal in its base." },
    -- Entrance supplied by Karl during native review, 2026-10-16.
    { id = "dungeon:dalaran", name = "City of Dalaran", forever = true, map = 1421, zone = "Silverpine Forest", x = 69, y = 45.5, where = "Dungeon entrance." },
    -- Reuse the existing hub positions for named location links.
    FGT.HUBS.rep_argentdawn,
    FGT.HUBS.raid_zg,
    FGT.HUBS.raid_aq20,
    FGT.HUBS.raid_aq40,
}
