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
