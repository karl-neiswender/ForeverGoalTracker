local ADDON, FGT = ...

-- ============================================================
-- Quests named in steps and tips
-- ============================================================
-- A quest name in single quotes ('A Proper String') becomes a bright
-- yellow link with a gold "!" in front (FGT.LinkText). Hover shows who
-- starts it and where each of your characters stands on it; right-click
-- gives the Wowhead link. Only quoted names are linked, so an item that
-- shares a quest's name ("Frame of Atiesh") stays an item.
--
-- { name, { quest ids }, start = NPC id, startName }. daily = true: blue,
-- like the game's daily quests. startItem = { id, name }: an item that
-- begins the quest ("This Item Begins a Quest" on Wowhead). Several ids: the
-- faction or class versions of one quest (any of them counts). From
-- Wowhead Classic (2026-10-07); start is Wowhead's "Start:" NPC.
FGT.QUESTS = {
    -- Winterspring Frostsaber
    { "Frostsaber Provisions", { 4970 }, start = 10618, startName = "Rivern Frostwind", daily = true },
    { "Winterfall Intrusion", { 5201 }, start = 10618, startName = "Rivern Frostwind", daily = true },
    { "Rampaging Giants", { 5981 }, start = 10618, startName = "Rivern Frostwind", daily = true },
    -- Rhok'delar and Lok'delar
    { "A Proper String", { 7635 }, start = 14525, startName = "Stoma the Ancient" },
    { "Stave of the Ancients", { 7636 }, start = 14524, startName = "Vartrus the Ancient" },
    { "The Ancient Leaf", { 7632 }, startItem = { 18703, "Ancient Petrified Leaf" } },
    { "Ancient Sinew Wrapped Lamina", { 7634 }, start = 14526, startName = "Hastat the Ancient" },
    -- Atiesh
    { "The Charge of the Dragonflights", { 8555 }, start = 15192, startName = "Anachronos" },
    -- Dungeon Set 2: every class has its own version of these, so no ids
    -- (no status in the tooltip; right-click searches Wowhead)
    { "An Earnest Proposition", {}, perClass = true },
    { "Just Compensation", {}, perClass = true },
    { "Anthion's Parting Words", {}, perClass = true },
    { "Saving the Best for Last", {}, perClass = true },
    -- Thunderfury
    { "Examine the Vessel", { 7785 } },
    { "Thunderaan the Windseeker", { 7786 }, start = 14347, startName = "Highlord Demitrian" },
    { "Rise, Thunderfury!", { 7787 } },
    -- Benediction, Sulfuras, Quel'Serrar
    { "The Balance of Light and Shadow", { 7622 }, start = 14494, startName = "Eris Havenfire" },
    { "A Binding Contract", { 7604 }, startItem = { 18628, "Thorium Brotherhood Contract" } },
    { "The Forging of Quel'Serrar", { 7508, 7509 }, start = 14368, startName = "Lorekeeper Lydros",
      startItem = { 18401, "Nostro's Compendium of Dragon Slaying" } },
    -- Dreadsteed
    { "Mor'zul Bloodbringer", { 7562 }, startName = "a warlock demon trainer: Spackle Thornberry (Stormwind), Jubahl Corpseseeker (Ironforge), Martha Strain (Undercity) or Kurgul (Orgrimmar)" },
    { "Rage of Blood", { 7563 }, start = 14436, startName = "Mor'zul Bloodbringer" },
    { "Wildeyes", { 7564 }, start = 14436, startName = "Mor'zul Bloodbringer" },
    { "Kroshius' Infernal Core", { 7603 }, start = 14470, startName = "Impsy" },
    { "Imp Delivery", { 7629 }, start = 14437, startName = "Gorzeeki Wildeyes" },
    { "Arcanite", { 7630 }, start = 14437, startName = "Gorzeeki Wildeyes" },
    { "Dreadsteed of Xoroth", { 7631 }, start = 14436, startName = "Mor'zul Bloodbringer" },
    -- Charger
    { "Lord Grayson Shadowbreaker", { 7638 }, start = 6171, startName = "Duthorian Rall" },
    { "Emphasis on Sacrifice", { 7637 }, start = 928, startName = "Lord Grayson Shadowbreaker" },
    { "To Show Due Judgment", { 7639 }, start = 11406, startName = "High Priest Rohan" },
    { "Exorcising Terrordale", { 7640 }, start = 928, startName = "Lord Grayson Shadowbreaker" },
    { "The Work of Grimand Elmore", { 7641 }, start = 928, startName = "Lord Grayson Shadowbreaker" },
    { "Collection of Goods", { 7642 }, start = 1416, startName = "Grimand Elmore" },
    { "Ancient Equine Spirit", { 7643 }, start = 928, startName = "Lord Grayson Shadowbreaker" },
    { "Blessed Arcanite Barding", { 7644 }, start = 14566, startName = "Ancient Equine Spirit" },
    { "Manna-Enriched Horse Feed", { 7645 }, start = 2357, startName = "Merideth Carlson" },
    { "The Divination Scryer", { 7646 }, start = 928, startName = "Lord Grayson Shadowbreaker" },
    { "Judgment and Redemption", { 7647 }, start = 928, startName = "Lord Grayson Shadowbreaker" },
    -- attunements and keys
    { "The Dread Citadel - Naxxramas", { 9121, 9122, 9123 }, start = 16116, startName = "Archmage Angela Dosantos" },
    { "Attunement to the Core", { 7848 }, start = 14387, startName = "Lothos Riftwaker" },
    { "Blackhand's Command", { 7761 }, startItem = { 18987, "Blackhand's Command" } },
    { "Seal of Ascension", { 4742, 4743 }, start = 10299, startName = "Scarshield Infiltrator" },
    { "The Key to Scholomance", { 5505, 5511 }, startName = "Alchemist Arbington (Alliance) or Apothecary Dithers (Horde)" },
    { "Dark Iron Legacy", { 3801, 3802 }, start = 8888, startName = "Franclorn Forgewright" },
    -- Onyxia, Alliance
    { "Dragonkin Menace", { 4182 }, start = 9562, startName = "Helendis Riverhorn" },
    { "The True Masters", { 4224 }, start = 9560, startName = "Marshal Maxwell" },
    { "Marshal Windsor", { 4241 }, start = 9560, startName = "Marshal Maxwell" },
    { "Abandoned Hope", { 4242 }, start = 9023, startName = "Marshal Windsor" },
    { "A Crumpled Up Note", { 4264 }, startItem = { 11446, "A Crumpled Up Note" } },
    { "A Shred of Hope", { 4282 }, start = 9023, startName = "Marshal Windsor" },
    { "Jail Break!", { 4322 }, start = 9023, startName = "Marshal Windsor" },
    { "Stormwind Rendezvous", { 6402 }, start = 9560, startName = "Marshal Maxwell" },
    { "The Great Masquerade", { 6403 }, start = 12580, startName = "Reginald Windsor" },
    { "The Dragon's Eye", { 6501 }, start = 1748, startName = "Highlord Bolvar Fordragon" },
    { "Drakefire Amulet", { 6502 }, start = 10929, startName = "Haleh" },
    -- Onyxia, Horde
    { "Warlord's Command", { 4903 }, startItem = { 12563, "Warlord Goretooth's Command" } },
    { "Eitrigg's Wisdom", { 4941 }, start = 9077, startName = "Warlord Goretooth" },
    { "For The Horde!", { 4974 }, start = 4949, startName = "Thrall" },
    { "What the Wind Carries", { 6566 }, start = 4949, startName = "Thrall" },
    { "The Champion of the Horde", { 6567 }, start = 4949, startName = "Thrall" },
    { "The Testament of Rexxar", { 6568 }, start = 10182, startName = "Rexxar" },
    { "Oculus Illusions", { 6569 }, start = 11872, startName = "Myranda the Hag" },
    { "Emberstrife", { 6570 }, start = 11872, startName = "Myranda the Hag" },
    { "The Test of Skulls, Scryer", { 6582 }, start = 10321, startName = "Emberstrife" },
    { "The Test of Skulls, Somnus", { 6583 }, start = 10321, startName = "Emberstrife" },
    { "The Test of Skulls, Chronalis", { 6584 }, start = 10321, startName = "Emberstrife" },
    { "The Test of Skulls, Axtroz", { 6585 }, start = 10321, startName = "Emberstrife" },
    { "Ascension...", { 6601 }, start = 10321, startName = "Emberstrife" },
    { "Blood of the Black Dragon Champion", { 6602 }, start = 10182, startName = "Rexxar" },
}
