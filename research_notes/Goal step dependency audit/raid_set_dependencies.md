# Raid and item-set step dependency audit

Research date: October 8, 2026 (America/New_York). Research only; production files untouched.

## Which current steps exist, and which can safely share a dependency template?

### Takeaway
The complete evaluated catalogue has **79 goals**, including hidden client/faction content. This audit owns **24 goals / 878 raw addresses / 806 counted tasks**. Exact evaluated text, item IDs, alternative role IDs, sources, section order and materials are preserved in `catalogue.json`, `addresses.json`, and the human-readable `raid_set_addresses.md` alongside this file.

### Cited Findings
- Inventory was evaluated with real Lua 5.1, `tools/wowstub.lua`, Data → Library → Npcs → Quests → Core, followed by ADDON_LOADED and PLAYER_LOGIN, separately at interface 11509 and 16001. It includes Core's fresh-login migration path. Keys are numeric for ordinary steps, `section_piece_piece` for pieces, and `section_piece_mN` for material rows. Tier 3 counts material rows rather than their parent pieces. These are facts of this checkout, not external game claims. — [Core source](../../Core.lua), [Data source](../../Data.lua), [Library source](../../Library.lua), [extraction script](extract_catalogue.py), [address script](address_inventory.py)
- Owned IDs and raw counts: tier3 357; raid_mc 11; raid_ony 3; raid_bwl 9; raid_zg 10; raid_aq20 6; raid_aq40 9; raid_naxx 16; raid_hyjal 1; raid_barrow 1; set_tier1 72; set_tier2 72; set_dungeon1 72; set_dungeon2 72; set_viper 5; set_forever_raid 54; pvp_set_plate_ally 12; pvp_set_mail_ally 12; pvp_set_leather_ally 12; pvp_set_cloth_ally 18; pvp_set_plate_horde 12; pvp_set_mail_horde 12; pvp_set_leather_horde 12; pvp_set_cloth_horde 18. — [Exact expanded addresses](raid_set_addresses.md)
- Class sections for classic tier/dungeon sets: 1 Warrior, 2 Paladin, 3 Hunter, 4 Rogue, 5 Priest, 6 Shaman, 7 Mage, 8 Warlock, 9 Druid. Tier3 differs: 1 Warrior, 2 Paladin, 3 Hunter, 4 Rogue, 5 Priest, 6 Druid, 7 Mage, 8 Warlock, 9 Shaman. All slot orders: 1 head, 2 shoulders, 3 chest, 4 hands, 5 legs, 6 belt, 7 wrists, 8 feet; six-piece Forever sets omit belt/wrists, making index6 feet. — [Evaluated catalogue](catalogue.json)

### Inferences
- Use the templates below to classify **every address** in the owned inventory. Unlisted dependencies explicitly mean no proposed hard lock, not unaudited.
- A boss appearing earlier on a raid map is insufficient proof of a hard access gate. Distinguish a normal clearing route from a required kill/door/event.
- Catalogue includes both factions and hidden Forever goals even on Era. The two extracted lists share all79 IDs and1177 raw addresses; visibility is a UI predicate, not absence of a goal from these tables.

### Gaps
- Runtime inventory does not simulate the incoming beta build or prove old Classic encounter rules remain in Forever.
- No current Tier3 ring step exists; nine-piece external set descriptions must not silently expand this eight-piece goal.

## Which raid steps are real prerequisites, and which are optional or bypassable?

### Takeaway
Raid progression is often shared-instance state, while this addon records personal kills across characters and weeks. Locks should be conservative; player ticks cannot faithfully prove which doors are currently open. Onyxia's entry item and Naxxramas's final-wing gate are clearer candidates than generic map-order locks.

### Cited Findings
- Molten Core attunement is a shortcut; players can reach its actual portal through BRD. BWL similarly has its original entrance through UBRS and an attunement shortcut. — [Attunements and keys](https://www.wowhead.com/classic/guide/classic-wow-attunements-and-keys-dungeons-raids), [MC attunement](https://www.wowhead.com/classic/guide/molten-core-attunement-wow-classic)
- Onyxia requires the Drakefire Amulet. — [MC and Onyxia attunement](https://www.wowhead.com/classic/news/molten-core-onyxias-lair-attunement-wow-classic-353602)
- Majordomo's Classic encounter appears after the first eight bosses and doused runes; defeating him permits summoning Ragnaros. The strategy page specifies seven runes, while the NPC introduction incorrectly says eight. Do not copy the rune count from that introduction. — [Majordomo strategy](https://www.wowhead.com/classic/guide/majordomo-executus-molten-core-strategy-wow-classic), [NPC](https://www.wowhead.com/classic/npc=12018/majordomo-executus)
- BWL is largely linear; its three drakes all drop possible Tier2 gloves. A conventional boss order alone does not demonstrate every drake locks the next. — [BWL overview](https://www.wowhead.com/classic/guide/blackwing-lair-raid-overview-classic-wow), [Flamegor](https://www.wowhead.com/classic/npc=11981/flamegor)
- Hakkar can be attempted with priests alive; they grant extra abilities. The usual priest clear is a difficulty treatment, not an absolute encounter-unlock rule. Mandokir, Jin'do, Gahz'ranka and Edge of Madness are optional for Hakkar. — [Hakkar NPC data and explanation](https://www.wowhead.com/classic/npc=14834/hakkar-the-soulflayer), [Blizzard-announced priest-alive challenge](https://www.wowhead.com/classic/news/classic-season-of-mastery-hakkar-bonus-loot-326171)
- AQ40's main sequence is Skeram, Sartura, Fankriss, Huhuran, Twin Emperors, C'Thun; Bug Trio, Viscidus and Ouro are optional. — [AQ40 zone](https://www.wowhead.com/classic/zone=3428/ahnqiraj)
- AQ20 has no personal attunement. Its optional bosses are Moam, Buru and Ayamiss; Kurinnaxx precedes the Rajaxx event. — [AQ20 zone](https://www.wowhead.com/classic/zone=3429/ruins-of-ahnqiraj), [Kurinnaxx](https://www.wowhead.com/classic/npc=15348/kurinnaxx). Caveat: detailed mandatory/optional route wording in the zone page is user commentary, so exact access edges need stronger validation.
- Sapphiron is accessible after all four wings, then guards Kel'Thuzad. Wings can be tackled independently. — [Sapphiron Classic NPC](https://www.wowhead.com/classic/npc=15989/sapphiron), [Grobbulus NPC with wing breakdown](https://www.wowhead.com/classic/npc=15931/grobbulus)
- Forever's new raid overview does not establish precise encounter access rules or boss-to-set-piece sources. — [Forever raid hub](https://www.wowhead.com/forever/guide/raids-overview-hub-dates-locations)

### Inferences
Exact raid map below distinguishes **candidate Classic gates** from **route guidance only**. Every current numeric step is covered. Auto-detected completion must override any lock; never untick completion when prerequisites change. These are planning recommendations, not verified Forever rules.

| Goal / step addresses | Proposed treatment |
|---|---|
| raid_mc:1 attunement | Available; shortcut only |
| raid_mc:2 Lucifron,3 Magmadar,4 Gehennas,5 Garr,6 Shazzrah,7 Baron Geddon,8 Golemagg,9 Sulfuron | Available independently; no full sequential chain |
| raid_mc:10 Majordomo | Candidate all-of2–9; rune condition is unrepresented, so those ticks alone are necessary-guide evidence, not sufficient instance-state proof |
| raid_mc:11 Ragnaros | Candidate10; shared summoning/weekly instance caveat |
| raid_ony:1 Amulet | Available |
| raid_ony:2 Onyxia | Candidate1, checked on the raiding character rather than some other alt |
| raid_ony:3 Head/turn-in | Candidate2; step auto currently means head ownership, not turn-in proof; do not claim quest completed |
| raid_bwl:1 attunement | Available; must not lock2 |
| raid_bwl:2 Razorgore | Available |
| raid_bwl:3 Vaelastrasz,4 Broodlord,5 Firemaw,6 Ebonroc,7 Flamegor,8 Chromaggus,9 Nefarian | Conventional route2→3→4→5→6→7→8→9. Exact hard gates/reordering of drakes not verified; leave available until gate evidence is obtained |
| raid_zg:1 Jeklik,2 Venoxis,3 Mar'li,4 Mandokir,5 Edge of Madness,6 Thekal,7 Gahz'ranka,8 Arlokk,9 Jin'do,10 Hakkar | All available; no priest hard lock. Optional summons require reagents/conditions absent from current steps; describe in tips rather than fabricate checkbox prerequisites |
| raid_aq20:1 Kurinnaxx | Available |
| raid_aq20:2 Rajaxx | Candidate1, requires event validation on current client |
| raid_aq20:3 Moam,4 Buru,5 Ayamiss,6 Ossirian | No hard mutual chain; optional bosses must not lock6. Route availability after1/2 remains verification gap |
| raid_aq40:1 Skeram,2 Bug Trio,3 Sartura,4 Fankriss,5 Viscidus,6 Huhuran,7 Twin Emperors,8 Ouro,9 C'Thun | Main route1→3→4→6→7→9; exact physical access gates require validation before hard locks. Optional2/5/8 never gate9 |
| raid_naxx:1 attunement | Available |
| raid_naxx:2 Anub'Rekhan,3 Faerlina,4 Maexxna | Spider route2→3→4; candidate wing route, exact earlier-door behavior not verified |
| raid_naxx:5 Noth,6 Heigan,7 Loatheb | Plague route5→6→7; independent of Spider wing |
| raid_naxx:8 Razuvious,9 Gothik,10 Horsemen | Military route8→9→10; independent of other wings |
| raid_naxx:11 Patchwerk,12 Grobbulus,13 Gluth,14 Thaddius | Construct route11→12→13→14; independent of other wings |
| raid_naxx:2/5/8/11 first bosses | Candidate1 (personal entry); one entry prerequisite fans out to all four wings |
| raid_naxx:15 Sapphiron | Candidate all-of4,7,10,14; wing-end kills capture the four-wing gate without serializing wings |
| raid_naxx:16 Kel'Thuzad | Candidate15 |
| raid_hyjal:1 Wild King; raid_barrow:1 Sonya | Unknown prerequisites; no lock |

- Prefer no hard raid locks initially: joining a raid partway through means the raid killed the prerequisite without the player getting a tick. A lock would block accurate manual recording. If raid locks are added, expose a bypass or use live encounter/instance evidence, not exclusively historical goal ticks.
- Onyxia's combined loot/turn-in step deserves a later data-quality review, distinct from this research-only task.

### Gaps
- No source examined proves all normal early Naxx wing kill orders are mandatory physical gates. They remain route advice, not production edges.
- BWL drake reordering, AQ access paths and encounters changed by the incoming Forever build need direct validation. Conservative classifications above deliberately avoid inventing rules.
- Classic and Forever raid access/lockout rules may differ; no official current-build source here confirms equivalence.

## Which item, material and upgrade steps have dependencies?

### Takeaway
Ordinary set collection is parallel. Dungeon Set2 is the important exception: four staged quest rewards create one-to-many unlocks within each class, but full Dungeon Set1 completion is unnecessary. Tier3's materials remain collectable in parallel; its missing crafting-unlock quest is a data gap.

### Cited Findings
- Dungeon Set1 belts, wrists and gloves are BoE for every class; upgrades are staged, so the full D1 set is not needed to begin D2. D2 consumes the matching D1 items. — [Dungeon set quest guide](https://www.wowhead.com/classic/guide/dungeon-sets-1-2-quests-wow-classic)
- Classic Tier3 crafting quests require Echoes of War9033 after Naxxramas attunement. The armor is token/scrap/material turn-ins, while its ring drops directly; the current addon does not include rings. — [Tier3 crafting guide](https://www.wowhead.com/classic/guide/naxxramas-tier-3-armor-set-wow-classic), [Echoes of War](https://www.wowhead.com/classic/quest=9033/echoes-of-war)
- Four Hunter/Alliance primary quest records independently verify each reward grouping and matching consumed D1 items: wrists8906; belt/hands8931; feet/legs/shoulders8952; head/chest9000. These are examples, not universal IDs. — [An Earnest Proposition8906](https://www.wowhead.com/classic/quest=8906/an-earnest-proposition), [Just Compensation8931](https://www.wowhead.com/classic/quest=8931/just-compensation), [Anthion's Parting Words8952](https://www.wowhead.com/classic/quest=8952/anthions-parting-words), [Saving the Best for Last9000](https://www.wowhead.com/classic/quest=9000/saving-the-best-for-last)
- The current builders store ordinary sets as item-ownership pieces without material rows; Forever role variants merge alternative IDs into one class/slot, not separate sequential tasks. PvP source rank is inferred from piece names and explicitly marked unconfirmed in Forever. — [Library builder](../../Library.lua), [Expanded catalogue](catalogue.json)

### Inferences
Lossless exhaustive templates follow. `si` and `pi` always refer to original saved section/piece positions, never filtered on-screen row order.

| Exact goal/address expansion | Classification / candidate prerequisite |
|---|---|
| set_tier1: `si=1..9`, `pi=1..8`, key `si_pi_piece` | All72 pieces independent. Belt6/wrists7 especially must not require personally killing bosses or owning another piece |
| set_tier2: `si=1..9`, `pi=1..8` | All72 independent. Getting chest3 does not require owning wrists7/waist6/boots8/gloves4/shoulders2 even though their bosses are earlier in BWL |
| set_dungeon1: `si=1..9`, `pi=1..8` | All72 independent, including purchasable BoE hands4/belt6/wrists7; group keys are not personal collection prerequisites |
| tier3: `si=1..9`, `pi=1..8`, every existing `mi` from catalogue | All285 material rows independent. Token material1, scrap material2, crafting materials3+ must not lock each other. 72 parent pieces have no manual checkbox and are not counted tasks |
| tier3: all72 parent pieces | No sibling-piece dependency. A future explicit turn-in task could require that piece's materials AND Echoes of War9033, not complete all other armor |
| set_viper:1 Armor,2 Leggings,3 Footpads,4 Belt,5 Gloves | All5 independent; no Lord/Lady boss chain implied |
| set_forever_raid: `si=1..9`, `pi=1..6` | All54 available. Boss sources and access prerequisites unknown; do not copy classic Tier1/2/3 gates |
| pvp_set_plate/mail/leather_ally/horde: `si=1..2`, `pi=1..6`; pvp_set_cloth_ally/horde: `si=1..3`, `pi=1..6` | All108 merged pieces have no piece-to-piece prerequisites. Potential rank gates are per-character and independent: pi1/3 rank13, pi2/5 rank12, pi4 rank10, pi6 rank9. These ranks derive from names, not confirmed Forever purchase rules; no hard locks yet |
| set_dungeon2: every `si=1..9`, piece7 wrists | Stage1; available. Matching D1 wrists are consumed, but acquiring all D1 pieces is not required |
| set_dungeon2: each same `si`, pieces4 hands AND6 belt | Stage2; candidate both depend on same-class D2 piece7, unlocking together. Do not make4 depend on6 or6 depend on4 |
| set_dungeon2: each same `si`, pieces2 shoulders AND5 legs AND8 feet | Stage3; candidate all depend on same-class prior stage4+6 (or stage2 quest completion), unlocking together; no chain among2/5/8 |
| set_dungeon2: each same `si`, pieces1 head AND3 chest | Stage4; candidate all depend on same-class prior stage2+5+8 (or stage3 quest completion), unlocking together; neither depends on its same-stage sibling |

- D2 stage completion is best backed by per-class/per-faction quest evidence, not item ticks alone. A character may discard an earlier reward; an alt's stage does not unlock this character's quest. Ownership auto rules remain override evidence for completed pieces.
- D2 stage reward quests, in order: An Earnest Proposition → Just Compensation → Anthion's Parting Words → Saving the Best for Last. The exact long intervening chain is external to current goal rows. Useful quest-chain references: [An Earnest Proposition8911](https://www.wowhead.com/classic/quest=8911/an-earnest-proposition), [A Supernatural Device8922](https://www.wowhead.com/classic/quest=8922/a-supernatural-device), [Just Compensation](https://www.wowhead.com/classic/search?q=Just%20Compensation), [Anthion's Parting Words](https://www.wowhead.com/classic/search?q=Anthion%27s%20Parting%20Words), [Saving the Best for Last](https://www.wowhead.com/classic/search?q=Saving%20the%20Best%20for%20Last). Search links identify variants rather than falsely implying one universal ID.
- Stage2 includes Mux's device/distiller/ectoplasm/core/rod tasks before faction return. Stage3 includes Anthion's rescue/materials/Falrin/banner/Theldren route. Stage4 includes Bodley's elemental/component/summoned-boss/Alcaz/amulet/Valthalak route. These intermediate quests are not current checkboxes, so new dependencies must not refer to invented saved indices. See linked quest guide; exact variant IDs should be derived from game/Questie data before adding new rows.
- Never lock tradeable materials behind reputation, raid attunement or profession skill merely because crafting/turn-in needs them. Anyone can buy materials earlier.

### Gaps
- Echoes of War is absent from both the Tier3 goal and its current tips. It should be documented separately before adding turn-in locks; adding/reordering material rows requires saved-progress migration.
- Full class/faction D2 quest IDs and source-level Questie prerequisite records were not extracted here. Current perClass quest metadata intentionally has no IDs. Stage-level recommendations are supported, but per-character quest gating needs additional variant data.
- Forever PvP ranks, vendors, honor costs, raid tier sources and Classic loot changes remain unconfirmed. Gold sets/blue sets should stay collectable independently until authoritative rules establish otherwise.
