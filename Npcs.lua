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
