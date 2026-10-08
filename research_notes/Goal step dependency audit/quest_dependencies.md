# Quest-chain, weapon, attunement and class-mount dependency audit

## What is covered and how should locks work?

### Takeaway
Research date: October 8, 2026. Exact current catalogue: 21 goals, 128 numbered flat steps. Classic requirements are a baseline, not confirmation for the incoming Forever beta build.

### Cited Findings
- Primary implementation baseline: [Questie Classic v10.0.0 database](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) and [corrections](https://github.com/Questie/Questie/blob/v10.0.0/Database/Corrections/classicQuestFixes.lua). Database key12 preQuestGroup=all prerequisites; key13 preQuestSingle=an allowed predecessor; key25 parentQuest=in progress. Stable version is intentional: master moved database paths.
- Actual local goal text from Data.lua/Library.lua and runtime catalogue after ADDON_LOADED migrations. Quests.lua and Npcs.lua were inspected: they map links/start NPCs, not prerequisite chains. Core migrations move saved ticks (tipsFix,stepsFix231); current step addresses below follow current data, not old save indices.

### Inferences
- Hard requirements are minimum direct edges, not every ancestor. AND/OR must be explicit. Local address `n` means that goal flat step n. Cross-goal evidence should work whether or not the other goal is tracked.
- All quest chains, soulbound components and attunements are character-specific. A roster tick from characterA plus materialB or reputationC does not prove any character can complete the action. Use locks as guide ordering only until character provenance exists; completion auto evidence must always override a lock. Never untick finished rows.
- Possession requirements differ from irreversible completion: historical material ticks remain after spending/trading. Keep count rules and quest state as proof rather than assuming saved ticks equal current inventory.
- Gathering and purchases remain available. Group key bypasses and joining cleared instances mean owning a key or personally killing every previous boss is not a universal lock condition.

### Gaps
- Forever quest/drop/riding rules not verified after the new beta build. Each Classic edge must retain an unconfirmed Forever status. The existence of an NPC in Forever does not confirm its quest conditions.

## What does every current step require?

### Takeaway
The following tables enumerate every owned current step including independent materials and provisional edges.

### Cited Findings

#### ashbringer — Corrupted Ashbringer (5 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| ashbringer:1 | Reach level 60. | None | independent / no lock | High Classic; unconfirmed Forever | No earlier step. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| ashbringer:2 | Get {att_naxx:attuned to Naxxramas} from Archmage Angela Dosantos at Light's Hope Chapel. | 1 | hard prerequisite | High Classic; unconfirmed Forever | Naxx attunement minimum level 60; att_naxx completion can satisfy this without tracking that goal. [source1](https://www.wowhead.com/classic/quest=9121); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| ashbringer:3 | Clear the Military Wing of {raid_naxx:Naxxramas} up to the Four Horsemen. | 2 | soft/contextual; no lock | Medium Classic; unconfirmed Forever | Naxx entry requires attunement on raiding character; already attuned alt / cleared instance evidence must override. [source1](https://www.wowhead.com/classic/quest=9121) |
| ashbringer:4 | Defeat the Four Horsemen. | 3 | soft/contextual; no lock | Medium Classic; unconfirmed Forever | Gothik is instance route progression, not a permanently required personal kill. Joining a raid already at Four Horsemen is allowed. [source1](https://www.wowhead.com/classic/item=22691) |
| ashbringer:5 | Loot Corrupted Ashbringer from the Four Horsemen Chest. | 4 | hard prerequisite | High Classic; unconfirmed Forever | Chest becomes available after encounter; item evidence overrides missing personal boss history. [source1](https://www.wowhead.com/classic/item=22691) |

#### frostsaber — Winterspring Frostsaber (8 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| frostsaber:1 | Reach level 40 and travel to Winterspring. | None | independent / no lock | Data conflict: Classic quest level58 versus current level40 | Classic Questie records quests4970/5201/5981 min58, so step1 cannot prove actual eligibility. [source1](https://www.wowhead.com/classic/quest=4970); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| frostsaber:2 | Start Rivern Frostwind's quests at Frostsaber Rock in Winterspring. | 1 | soft/contextual; no lock | Medium Classic; unconfirmed Forever | Current step1 level40 insufficient Classic quest gate. Do not encode until Forever level rules checked. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| frostsaber:3 | Turn in 'Frostsaber Provisions' daily until 1500/3000 Neutral. | 2 | soft/contextual; no lock | Medium Classic; unconfirmed Forever | Step2 first reputation point is implied by later cumulative milestone; avoid hiding farm. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| frostsaber:4 | Turn in 'Winterfall Intrusion' daily until Friendly. | 3 | hard prerequisite | High Classic; unconfirmed Forever | Winterfall Intrusion unlocks at1500 neutral; alternative quests still earn Friendly. [source1](https://www.wowhead.com/classic/quest=5201); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| frostsaber:5 | Reach Honored, then add 'Rampaging Giants' to your dailies. | 4 | soft/contextual; no lock | Medium Classic; unconfirmed Forever | Honored is cumulative reputation; Rampaging Giants unlocked there, but other repeatables still work. [source1](https://www.wowhead.com/classic/quest=5981); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| frostsaber:6 | Reach Exalted with the Wintersaber Trainers. | 5 | soft/contextual; no lock | Medium Classic; unconfirmed Forever | Exalted cumulative reputation; do not force use of particular repeatables. [source1](https://www.wowhead.com/classic/quest=5981); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| frostsaber:7 | Reach Exalted with Darnassus to learn Frostsaber riding (Night Elves skip this). | None | independent / no lock | High Classic; unconfirmed Forever | Independent Darnassus reputation grind; NightElf skips. Required to USE under old race riding rules, not necessarily BUY. [source1](https://www.wowhead.com/classic/item=13086) |
| frostsaber:8 | Buy the Reins of the Winterspring Frostsaber from Rivern Frostwind (about 900 gold). | 6 | hard prerequisite | High Classic; unconfirmed Forever | Purchase Wintersaber Exalted gate; Darnassus step7 relates riding, do not add as buy prerequisite without Forever verification. [source1](https://www.wowhead.com/classic/item=13086) |

#### atiesh — Atiesh, Greatstaff of the Guardian (10 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| atiesh:1 | Raid {raid_naxx:Naxxramas} and {raid_aq40:Ahn'Qiraj} on a Druid, Mage, Priest or Warlock. | None | independent / no lock | High Classic; unconfirmed Forever | Preparation, auto level60 does not prove class/raids. No lock. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| atiesh:2 | Collect 40 Splinters of Atiesh from Naxxramas bosses. | None | independent / no lock | High Classic; unconfirmed Forever | Collect splinters independently; Naxx attunement on same caster is external entry gate. [source1](https://www.wowhead.com/classic/item=22726) |
| atiesh:3 | Combine the 40 splinters into the Frame of Atiesh. | 2 | hard prerequisite | High Classic; unconfirmed Forever | 40 splinters consumed to form frame. [source1](https://www.wowhead.com/classic/item=22727) |
| atiesh:4 | Bring the Frame of Atiesh to Anachronos at the Caverns of Time in Tanaris. | 3 | hard prerequisite | High Classic; unconfirmed Forever | Frame starts9250. Also Anachronos requires nonhostile/Neutral Brood reputation; unrepresented external condition. [source1](https://www.wowhead.com/classic/quest=9250) |
| atiesh:5 | Loot the Staff Head of Atiesh from Kel'Thuzad in Naxxramas. | 4 | hard prerequisite | Medium drop gating; high chain; unconfirmed Forever | Accept9251 after9250 before quest-item boss loot; no order versus step6. [source1](https://www.wowhead.com/classic/quest=9251); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| atiesh:6 | Loot the Base of Atiesh from C'Thun in Ahn'Qiraj. | 4 | hard prerequisite | Medium drop gating; high chain; unconfirmed Forever | Accept9251 after9250 before quest-item boss loot; parallel with step5. [source1](https://www.wowhead.com/classic/quest=9251); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| atiesh:7 | Return both pieces to Anachronos. | 5 AND 6 | hard prerequisite | High Classic; unconfirmed Forever | Both pieces required for9251. [source1](https://www.wowhead.com/classic/quest=9251); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| atiesh:8 | Complete your class's purification quest from Anachronos. | None | data wording invalid; withhold lock | High inconsistency | Step says COMPLETE purification before defeating entity in step9, but9257/9269/9270/9271 completion includes entity defeat and final return. Should say PICK UP purification; then7→8→9→10. [source1](https://www.wowhead.com/classic/quest=9257); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| atiesh:9 | Defeat the guardian the staff summons on Festival Lane in Stratholme. | None | blocked by data correction | High chain; ambiguous current step8 | Requires purification quest ACTIVE after7, not completed current8. Encode only after rewording8. [source1](https://www.wowhead.com/classic/quest=9257) |
| atiesh:10 | Receive Atiesh, Greatstaff of the Guardian from Anachronos. | 9 | hard prerequisite | High Classic; unconfirmed Forever | Receive reward when turning in class purification; step8 current COMPLETE redundantly includes9/10. [source1](https://www.wowhead.com/classic/quest=9257); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### rhokdelar — Rhok'delar, Longbow of the Ancient Keepers (5 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| rhokdelar:1 | Get the Ancient Rune Etched Stave from 'Stave of the Ancients' (the {lokdelar:Lok'delar} goal). | None | independent / no lock | High Classic; unconfirmed Forever | External Lokdelar step7 yields stave; reward item/quest7636 evidence can satisfy without cross-goal active ticks. [source1](https://www.wowhead.com/classic/quest=7636) |
| rhokdelar:2 | Pick up 'A Proper String' from Stoma the Ancient in Felwood. | None | independent / no lock | High Classic; unconfirmed Forever | Requires The Ancient Leaf7632 = lokdelar step2, NOT stave completion in current step1. This can run alongside four demons. [source1](https://www.wowhead.com/classic/quest=7635); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| rhokdelar:3 | Loot the Mature Black Dragon Sinew from {raid_ony:Onyxia}. | None | independent / no lock | High Classic; unconfirmed Forever | Black sinew can be obtained before quest; own Onyxia attunement required to enter but avoid cross-goal lock. [source1](https://www.wowhead.com/classic/item=18705); [source2](https://www.wowhead.com/classic/quest=7635) |
| rhokdelar:4 | Turn in the sinew to Vartrus for the Enchanted Black Dragon Sinew. | 2 AND 3 | hard prerequisite | High Classic; unconfirmed Forever | Turn-in to STOMA, not Vartrus (current text wrong). [source1](https://www.wowhead.com/classic/quest=7635); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| rhokdelar:5 | Combine the stave and the Enchanted Black Dragon Sinew into Rhok'delar. | 1 AND 4 | hard prerequisite | High Classic; unconfirmed Forever | Stave and enchanted string both consumed. [source1](https://www.wowhead.com/classic/item=18713) |

#### lokdelar — Lok'delar, Stave of the Ancient Keepers (7 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| lokdelar:1 | Loot the Ancient Petrified Leaf from the Cache of the Firelord in {raid_mc:Molten Core}. | None | independent / no lock | High Classic; unconfirmed Forever | Independent raid drop; personal MC attunement optional shortcut. [source1](https://www.wowhead.com/classic/item=18703) |
| lokdelar:2 | Bring the leaf to Vartrus the Ancient in Felwood and pick up 'Stave of the Ancients'. | 1 | hard prerequisite | High Classic; unconfirmed Forever | Leaf starts7632, which unlocks7636. [source1](https://www.wowhead.com/classic/quest=7632); [source2](https://www.wowhead.com/classic/quest=7636); [source3](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| lokdelar:3 | Solo Artorius the Doombringer in Winterspring. | 2 | hard prerequisite | High Classic; unconfirmed Forever | 7636 active; all four demons available in parallel, not sequential. [source1](https://www.wowhead.com/classic/quest=7636); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| lokdelar:4 | Solo Klinfran the Crazed in Burning Steppes. | 2 | hard prerequisite | High Classic; unconfirmed Forever | 7636 active; all four demons available in parallel, not sequential. [source1](https://www.wowhead.com/classic/quest=7636); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| lokdelar:5 | Solo Solenor the Slayer in Silithus. | 2 | hard prerequisite | High Classic; unconfirmed Forever | 7636 active; all four demons available in parallel, not sequential. [source1](https://www.wowhead.com/classic/quest=7636); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| lokdelar:6 | Solo Simone the Seductress in Un'Goro Crater. | 2 | hard prerequisite | High Classic; unconfirmed Forever | 7636 active; all four demons available in parallel, not sequential. [source1](https://www.wowhead.com/classic/quest=7636); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| lokdelar:7 | Turn in the four demon heads to Vartrus for Lok'delar and the Ancient Rune Etched Stave. | 3 AND 4 AND 5 AND 6 | hard prerequisite | High Classic; unconfirmed Forever | Four demon heads all required. [source1](https://www.wowhead.com/classic/quest=7636); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### thunderfury — Thunderfury, Blessed Blade of the Windseeker (12 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| thunderfury:1 | Raid {raid_mc:Molten Core} on a weekly reset schedule. | None | independent / no lock | High Classic; unconfirmed Forever | Weekly raiding is preparation, level60 auto not actual history. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| thunderfury:2 | Loot the Bindings of the Windseeker (left) from Baron Geddon in Molten Core. | None | independent / no lock | High Classic; unconfirmed Forever | Independent binding loot; no ordering versus right binding. [source1](https://www.wowhead.com/classic/item=18563) |
| thunderfury:3 | Loot the Bindings of the Windseeker (right) from Garr in Molten Core. | None | independent / no lock | High Classic; unconfirmed Forever | Independent binding loot; no ordering versus left binding. [source1](https://www.wowhead.com/classic/item=18564) |
| thunderfury:4 | Start 'Examine the Vessel' with Highlord Demitrian in Silithus. | 2 OR 3 | hard prerequisite | High Classic; unconfirmed Forever | Either binding obtains Vessel19016 and starts7785. Do not require both. [source1](https://www.wowhead.com/classic/quest=7785); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| thunderfury:5 | Gather 10 Elementium Bars. | None | independent / no lock | High Classic; unconfirmed Forever | Buy bars or gather/smelt; do not hard-lock on raw materials6/7/8. [source1](https://www.wowhead.com/classic/item=17771) |
| thunderfury:6 | Gather 100 Arcanite Bars. | None | independent / no lock | High Classic; unconfirmed Forever | Parallel raw ingredient of step5, consumed in Elementium; NOT an extra final turn-in. [source1](https://www.wowhead.com/classic/quest=7786); [source2](https://www.wowhead.com/classic/item=17771) |
| thunderfury:7 | Gather 10 Fiery Cores (Molten Core). | None | independent / no lock | High Classic; unconfirmed Forever | Parallel raw ingredient of step5; NOT extra final turn-in. [source1](https://www.wowhead.com/classic/quest=7786); [source2](https://www.wowhead.com/classic/item=17771) |
| thunderfury:8 | Gather 30 Elemental Flux. | None | independent / no lock | High Classic; unconfirmed Forever | Parallel raw ingredient of step5; NOT extra final turn-in. [source1](https://www.wowhead.com/classic/quest=7786); [source2](https://www.wowhead.com/classic/item=17771) |
| thunderfury:9 | Loot the Essence of the Firelord from Ragnaros in Molten Core. | 4 | hard prerequisite | High Classic; unconfirmed Forever | Must ACCEPT7786 after7785 before Essence drops. Step4 says start but auto only completed7785; improve watch evidence. [source1](https://www.wowhead.com/classic/quest=7785); [source2](https://www.wowhead.com/classic/quest=7786) |
| thunderfury:10 | Turn in the bindings, the Essence and the materials to Demitrian ('Thunderaan the Windseeker'). | 2 AND 3 AND 4 AND 5 AND 9 | hard prerequisite | High Classic; unconfirmed Forever | Final summon turn-in requires both bindings,10 bars,Essence. Do not also require consumed raw ingredients6/7/8. [source1](https://www.wowhead.com/classic/quest=7786); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| thunderfury:11 | Defeat Prince Thunderaan in Silithus. | 10 | hard prerequisite | High Classic; unconfirmed Forever | Summons Prince; CURRENT auto quest7786 incorrectly ticks defeat at summon turn-in, before kill. [source1](https://www.wowhead.com/classic/quest=7786); [source2](https://www.wowhead.com/classic/quest=7787) |
| thunderfury:12 | Turn in 'Rise, Thunderfury!' to receive Thunderfury. | 11 | hard prerequisite | High Classic; unconfirmed Forever | Loot Dormant Wind Kissed Blade19018 to start7787. Completion proof overrides missed kill. [source1](https://www.wowhead.com/classic/quest=7787); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### benediction — Benediction / Anathema (5 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| benediction:1 | Loot The Eye of Divinity from Majordomo Executus in {raid_mc:Molten Core}. | None | independent / no lock | High Classic; unconfirmed Forever | Independent Eye raid drop. [source1](https://www.wowhead.com/classic/item=18646) |
| benediction:2 | Start 'The Balance of Light and Shadow' with Eris Havenfire near Stratholme. | 1 | hard prerequisite | High Classic; unconfirmed Forever | Eye equipped to see/interact with Eris and take7622. [source1](https://www.wowhead.com/classic/quest=7622); [source2](https://www.wowhead.com/classic/item=18646) |
| benediction:3 | Save 50 peasants (fewer than 15 deaths) to earn the Splinter of Nordrassil. | 2 | hard prerequisite | High Classic; unconfirmed Forever | Event for7622 rewards Splinter. [source1](https://www.wowhead.com/classic/quest=7622) |
| benediction:4 | Loot The Eye of Shadow from demons in southern Winterspring, or buy one. | None | independent / no lock | High Classic; unconfirmed Forever | Tradeable Eye of Shadow may be bought/farmed at any time. [source1](https://www.wowhead.com/classic/item=18665) |
| benediction:5 | Combine the Splinter of Nordrassil, the Eye of Shadow and the Eye of Divinity into Benediction. | 1 AND 3 AND 4 | hard prerequisite | High Classic; unconfirmed Forever | All three components required/consumed. [source1](https://www.wowhead.com/classic/item=18608) |

#### sulfuras — Sulfuras, Hand of Ragnaros (13 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| sulfuras:1 | Raid {raid_mc:Molten Core} on a weekly reset schedule. | None | independent / no lock | High Classic; unconfirmed Forever | Preparation; not valid hard gate to purchasing materials. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| sulfuras:2 | Loot the Eye of Sulfuras from Ragnaros in Molten Core. | None | independent / no lock | High Classic; unconfirmed Forever | Eye independent of all preparation/materials. [source1](https://www.wowhead.com/classic/item=17204) |
| sulfuras:3 | Get the Plans: Sulfuron Hammer from Lokhtos Darkbargainer in Blackrock Depths ('A Binding Contract'). | None | independent / no lock | High Classic; unconfirmed Forever | One Ingot required externally, not ALL eight of step4; plans can be bought; crafter may already know recipe. [source1](https://www.wowhead.com/classic/quest=7604); [source2](https://www.wowhead.com/classic/item=18592) |
| sulfuras:4 | Collect 8 Sulfuron Ingots from Golemagg the Incinerator in Molten Core. | None | independent / no lock | High Classic; unconfirmed Forever | Materials can be collected/bought in any order; Black Forge needed only if personally smelting Dark Iron. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:5 | Smelt 20 Dark Iron Bars at the Black Forge in Blackrock Depths. | None | independent / no lock | High Classic; unconfirmed Forever | Materials can be collected/bought in any order; Black Forge needed only if personally smelting Dark Iron. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:6 | Gather 50 Arcanite Bars. | None | independent / no lock | High Classic; unconfirmed Forever | Materials can be collected/bought in any order; Black Forge needed only if personally smelting Dark Iron. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:7 | Gather 25 Essence of Fire. | None | independent / no lock | High Classic; unconfirmed Forever | Materials can be collected/bought in any order; Black Forge needed only if personally smelting Dark Iron. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:8 | Gather 10 Blood of the Mountain (rare from Dark Iron deposits). | None | independent / no lock | High Classic; unconfirmed Forever | Materials can be collected/bought in any order; Black Forge needed only if personally smelting Dark Iron. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:9 | Gather 10 Lava Cores (Molten Core trash, BoE). | None | independent / no lock | High Classic; unconfirmed Forever | Materials can be collected/bought in any order; Black Forge needed only if personally smelting Dark Iron. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:10 | Gather 10 Fiery Cores (Molten Core trash, BoE). | None | independent / no lock | High Classic; unconfirmed Forever | Materials can be collected/bought in any order; Black Forge needed only if personally smelting Dark Iron. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:11 | Reach 300 Blacksmithing, or find a Blacksmith to craft it. | None | independent / no lock | High Classic; unconfirmed Forever | Can use another blacksmith; own skill rule cannot prove service found. [source1](https://www.wowhead.com/classic/item=18592) |
| sulfuras:12 | Craft the Sulfuron Hammer. | None | conditional crafting AND; no universal hard lock | High Classic; unconfirmed Forever | If personally commissioning craft needs4..10 and recipe on crafter/BS300. Hammer is BoE and may be bought, bypassing3..11. No universal checkbox gate. [source1](https://www.wowhead.com/classic/item=17193); [source2](https://www.wowhead.com/classic/item=18592) |
| sulfuras:13 | Combine the Sulfuron Hammer and the Eye of Sulfuras into Sulfuras. | 2 AND 12 | hard prerequisite | High Classic; unconfirmed Forever | Eye plus completed hammer required. [source1](https://www.wowhead.com/classic/item=17182) |

#### mount_dreadsteed — Dreadsteed (Warlock Epic Mount) (7 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| mount_dreadsteed:1 | Complete 'Mor'zul Bloodbringer' from a demon trainer in a capital city. | None | independent / no lock | High Classic; unconfirmed Forever | Warlock level60 start. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_dreadsteed:2 | Complete 'Rage of Blood'. | 1 | hard prerequisite | High Classic; unconfirmed Forever | 7563 follows7562. [source1](https://www.wowhead.com/classic/quest=7563); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_dreadsteed:3 | Complete 'Wildeyes'. | 2 | hard prerequisite | High Classic; unconfirmed Forever | 7564 follows7563. [source1](https://www.wowhead.com/classic/quest=7564); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_dreadsteed:4 | Complete 'Kroshius' Infernal Core'. | None | UNRELATED; remove/remap in guide fix | High Classic; unconfirmed Forever | 7603 is Inferno spell chain7601→7602→7603 atlevel50, not Dreadsteed. No dependency from3 and no dependency into5. [source1](https://www.wowhead.com/classic/quest=7603); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_dreadsteed:5 | Complete 'Imp Delivery'. | 3 + external7625 | hard prerequisite | High Classic; unconfirmed Forever | Imp Delivery7629 requires7564 AND Xorothian Stardust7625. Missing chain7623→7624→7625. [source1](https://www.wowhead.com/classic/quest=7629); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_dreadsteed:6 | Complete 'Arcanite'. | 3 + external7626 AND7627 AND7628 | hard prerequisite | High Classic; unconfirmed Forever | Arcanite7630 requires Bell/Wheel/Candle material turn-ins, available after7564; may parallel Imp Delivery, NOT gated by5. [source1](https://www.wowhead.com/classic/quest=7630); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_dreadsteed:7 | Defeat the Xorothian Dreadsteed in Dire Maul ('Dreadsteed of Xoroth'). | 5 AND 6 | hard prerequisite | High Classic; unconfirmed Forever | Dreadsteed quest7631 requires7629 AND7630; another warlock may supply reusable ritual tools; unrelated4 never gate. [source1](https://www.wowhead.com/classic/quest=7631); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source3](https://github.com/Questie/Questie/blob/v10.0.0/Database/Corrections/classicQuestFixes.lua) |

#### mount_charger — Charger (Paladin Epic Mount) (11 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| mount_charger:1 | Complete 'Lord Grayson Shadowbreaker' from Duthorian Rall in Stormwind City. | None | independent / no lock | High Classic; unconfirmed Forever | Paladin level60 starter. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:2 | Complete 'Emphasis on Sacrifice'. | 1 | hard prerequisite | High Classic; unconfirmed Forever |  [source1](https://www.wowhead.com/classic/quest=7637); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:3 | Complete 'To Show Due Judgment'. | 2 | hard prerequisite | High Classic; unconfirmed Forever |  [source1](https://www.wowhead.com/classic/quest=7639); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:4 | Complete 'Exorcising Terrordale'. | 3 | hard prerequisite | High Classic; unconfirmed Forever |  [source1](https://www.wowhead.com/classic/quest=7640); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:5 | Complete 'The Work of Grimand Elmore'. | 4 | uncertain ordering; withhold lock | Conflicting Classic evidence | Questie v10 records preQuestSingle7640; old comments describe separate branches. Guide corrections/new beta need verify before asserting parallel or strict gate. [source1](https://www.wowhead.com/classic/quest=7641); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:6 | Complete 'Collection of Goods'. | 5 | hard prerequisite | High Classic; unconfirmed Forever |  [source1](https://www.wowhead.com/classic/quest=7642); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:7 | Complete 'Ancient Equine Spirit'. | 6 AND 9 | hard prerequisite | High Classic; unconfirmed Forever | Completion7643 requires Feed item18775 from step9. Accept7643 after6 unlocks feed9; distinction creates cycle if use completed7 as prerequisite of9. [source1](https://www.wowhead.com/classic/quest=7643); [source2](https://www.wowhead.com/classic/quest=7645); [source3](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:8 | Complete 'Blessed Arcanite Barding'. | 7 | hard prerequisite | High Classic; unconfirmed Forever |  [source1](https://www.wowhead.com/classic/quest=7644); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:9 | Complete 'Manna-Enriched Horse Feed'. | 6 + quest7643 ACTIVE | active-quest prerequisite; NOT earlier completed-step gate | High Classic; unconfirmed Forever | Requires Ancient Equine Spirit7643 IN PROGRESS. Gather biscuits/gold beforehand; feed must complete before step7. Reorder rows or represent acceptance explicitly. [source1](https://www.wowhead.com/classic/quest=7645); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:10 | Complete 'The Divination Scryer'. | 8 | hard prerequisite | High Classic; unconfirmed Forever | No dependency on9 here:9 needed earlier for7. [source1](https://www.wowhead.com/classic/quest=7646); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| mount_charger:11 | Complete 'Judgment and Redemption' in {key_scholo:Scholomance} to earn the Charger. | 10 | hard prerequisite | High Classic; unconfirmed Forever | Personal key_scholo NOT required if party can open door. [source1](https://www.wowhead.com/classic/quest=7647); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### quelserrar — Quel'Serrar (5 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| quelserrar:1 | Loot Nostro's Compendium of Dragon Slaying in Dire Maul (rare). | None | independent / no lock | High Classic; unconfirmed Forever | Book tradeable; looting is one option, purchase bypasses. [source1](https://www.wowhead.com/classic/item=18401) |
| quelserrar:2 | Get the Unfired Ancient Blade from 'The Forging of Quel'Serrar' in the Dire Maul library. | 1 | hard prerequisite | High Classic; unconfirmed Forever | Book7507→7508 handoff→7509 provides blade. Current combined auto questTaken7508 may mark blade obtained too early. [source1](https://www.wowhead.com/classic/quest=7508); [source2](https://www.wowhead.com/classic/quest=7509); [source3](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| quelserrar:3 | Heat the blade in {raid_ony:Onyxia's} fire breath. | 2 | hard prerequisite | High Classic; unconfirmed Forever | Need Unfired blade before breath. [source1](https://www.wowhead.com/classic/quest=7509) |
| quelserrar:4 | Drive the Heated Ancient Blade into Onyxia's corpse before it cools. | 3 | hard prerequisite | High Classic; unconfirmed Forever | Need heated blade and killed Onyxia; warmth time-limited, old checkbox is history not current possession. [source1](https://www.wowhead.com/classic/quest=7509) |
| quelserrar:5 | Return the Treated Ancient Blade to receive Quel'Serrar. | 4 | hard prerequisite | High Classic; unconfirmed Forever | Treated blade turn-in. [source1](https://www.wowhead.com/classic/quest=7509) |

#### att_mc — Attunement: Molten Core (3 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| att_mc:1 | Pick up 'Attunement to the Core' from Lothos Riftwaker in Blackrock Mountain. | None | independent / no lock | High Classic; unconfirmed Forever | Min55 Classic; shortcut attunement not prerequisite of raidingMC. [source1](https://www.wowhead.com/classic/quest=7848) |
| att_mc:2 | Recover a Core Fragment at the Molten Core entry portal in Blackrock Depths. | 1 | soft/contextual; no lock | Medium Classic; unconfirmed Forever | Conservative: item pre-loot availability not independently verified. No lock until verified. [source1](https://www.wowhead.com/classic/quest=7848) |
| att_mc:3 | Return the Core Fragment to Lothos Riftwaker. | 1 AND 2 | hard prerequisite | High Classic; unconfirmed Forever | Accept quest and return fragment. [source1](https://www.wowhead.com/classic/quest=7848); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### att_ony_ally — Attunement: Onyxia's Lair (Alliance) (11 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| att_ony_ally:1 | Complete 'Dragonkin Menace' from Helendis Riverhorn in the Burning Steppes. | None | independent / no lock | High Classic; unconfirmed Forever |  [source1](https://www.wowhead.com/classic/quest=4182); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| att_ony_ally:2 | Complete the 'The True Masters' quests. | 1 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4224) |
| att_ony_ally:3 | Complete 'Marshal Windsor'. | 2 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4241) |
| att_ony_ally:4 | Complete 'Abandoned Hope'. | 3 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4242) |
| att_ony_ally:5 | Complete 'A Crumpled Up Note'. | 4 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4264) |
| att_ony_ally:6 | Complete 'A Shred of Hope'. | 5 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4282) |
| att_ony_ally:7 | Complete 'Jail Break!'. | 6 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4322) |
| att_ony_ally:8 | Complete 'Stormwind Rendezvous'. | 7 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6402) |
| att_ony_ally:9 | Complete 'The Great Masquerade'. | 8 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6403) |
| att_ony_ally:10 | Complete 'The Dragon's Eye'. | 9 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6501) |
| att_ony_ally:11 | Complete 'Drakefire Amulet' and receive the amulet. | 10 | hard prerequisite | High Classic; unconfirmed Forever | Same Alliance character chain; row2 compresses4183→4184→4185→4186→4223→4224. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6502) |

#### att_ony_horde — Attunement: Onyxia's Lair (Horde) (14 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| att_ony_horde:1 | Complete 'Warlord's Command' and turn it in to Warlord Goretooth in Kargath, Badlands. | None | independent / no lock | High Classic; unconfirmed Forever |  [source1](https://www.wowhead.com/classic/quest=4903); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| att_ony_horde:2 | Complete 'Eitrigg's Wisdom'. | 1 | hard prerequisite | High Classic; unconfirmed Forever | Same Horde character chain. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4941) |
| att_ony_horde:3 | Complete 'For The Horde!'. | 2 | hard prerequisite | High Classic; unconfirmed Forever | Same Horde character chain. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=4974) |
| att_ony_horde:4 | Complete 'What the Wind Carries'. | 3 | hard prerequisite | High Classic; unconfirmed Forever | Same Horde character chain. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6566) |
| att_ony_horde:5 | Complete 'The Champion of the Horde'. | 4 | hard prerequisite | High Classic; unconfirmed Forever | Same Horde character chain. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6567) |
| att_ony_horde:6 | Complete 'The Testament of Rexxar'. | 5 | hard prerequisite | High Classic; unconfirmed Forever | Same Horde character chain. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6568) |
| att_ony_horde:7 | Complete 'Oculus Illusions'. | 6 | hard prerequisite | High Classic; unconfirmed Forever | Same Horde character chain. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6569) |
| att_ony_horde:8 | Complete 'Emberstrife'. | 7 | hard prerequisite | High Classic; unconfirmed Forever | Same Horde character chain. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6570) |
| att_ony_horde:9 | Complete 'The Test of Skulls, Scryer'. | 8 | hard prerequisite | High Classic; unconfirmed Forever | Three first skull quests unlock together, no order among9,10,11. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6582) |
| att_ony_horde:10 | Complete 'The Test of Skulls, Somnus'. | 8 | hard prerequisite | High Classic; unconfirmed Forever | Three first skull quests unlock together, no order among9,10,11. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6583) |
| att_ony_horde:11 | Complete 'The Test of Skulls, Chronalis'. | 8 | hard prerequisite | High Classic; unconfirmed Forever | Three first skull quests unlock together, no order among9,10,11. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6584) |
| att_ony_horde:12 | Complete 'The Test of Skulls, Axtroz'. | 9 AND 10 AND 11 | hard prerequisite | High Classic; unconfirmed Forever | All three first skulls needed for Axtroz. [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6585) |
| att_ony_horde:13 | Complete 'Ascension...'. | 12 | hard prerequisite | High Classic; unconfirmed Forever |  [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6601) |
| att_ony_horde:14 | Complete 'Blood of the Black Dragon Champion' and receive the Drakefire Amulet. | 13 | hard prerequisite | High Classic; unconfirmed Forever |  [source1](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [source2](https://www.wowhead.com/classic/quest=6602) |

#### att_bwl — Attunement: Blackwing Lair (3 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| att_bwl:1 | Loot and read Blackhand's Command from the Scarshield Quartermaster in Blackrock Spire. | None | independent / no lock | High Classic; unconfirmed Forever | Min55 quest; orb shortcut optional, UBRS raid entrance alternative. [source1](https://www.wowhead.com/classic/quest=7761) |
| att_bwl:2 | Defeat General Drakkisath in {key_ubrs:Upper Blackrock Spire}. | None | independent / no lock | High Classic; unconfirmed Forever | Can kill Drakkisath without taking command; raid encounter independent; party key_ubrs enough. [source1](https://www.wowhead.com/classic/quest=7761) |
| att_bwl:3 | Touch Drakkisath's Brand behind him to gain the Mark of Drakkisath. | 1 AND 2 | hard prerequisite | High Classic; unconfirmed Forever | Quest active and boss cleared; prior personal kill evidence not necessary if joining cleared instance. [source1](https://www.wowhead.com/classic/quest=7761); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### att_naxx — Attunement: Naxxramas (2 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| att_naxx:1 | Reach Honored with the {rep_argentdawn:Argent Dawn}. | None | independent / no lock | High Classic; unconfirmed Forever | Honored Argent Dawn andlevel60 on character receiving attunement. [source1](https://www.wowhead.com/classic/quest=9121); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| att_naxx:2 | Get attuned at Light's Hope Chapel. | 1 | hard prerequisite | High Classic; unconfirmed Forever | Honored/Revered/Exalted quest alternatives9121/9122/9123; different costs. External rep_argentdawn whole goal Exalted unnecessary. [source1](https://www.wowhead.com/classic/quest=9121); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### key_ubrs — Key: Seal of Ascension (Upper Blackrock Spire) (2 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| key_ubrs:1 | Pick up 'Seal of Ascension'. | None | independent / no lock | High Classic; unconfirmed Forever | Min57; can collect gems/Unadorned Seal before pickup. [source1](https://www.wowhead.com/classic/quest=4742); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| key_ubrs:2 | Forge the Seal of Ascension. | 1 | hard prerequisite | High Classic; unconfirmed Forever | 4742 collection then4743 forging; condensed guide missing gem collection/handoff detail. [source1](https://www.wowhead.com/classic/quest=4742); [source2](https://www.wowhead.com/classic/quest=4743); [source3](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### key_scholo — Key: Skeleton Key (Scholomance) (1 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| key_scholo:1 | Complete 'The Key to Scholomance' and receive the Skeleton Key. | None | independent / no lock | High Classic; unconfirmed Forever | Only one row; internal chain unrepresented: faction opening quests→Skeletal Fragments→Mold Rhymes With...→Fire Plume Forged→Araj Scarab→5505/5511. Personal key not required to enter with group/lockpicker. [source1](https://www.wowhead.com/classic/quest=5505); [source2](https://www.wowhead.com/classic/quest=5511); [source3](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### key_brd — Key: Shadowforge Key (Blackrock Depths) (2 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| key_brd:1 | Complete the first 'Dark Iron Legacy'. | None | independent / no lock | High Classic; unconfirmed Forever | Talk to ghost while dead; no earlier row. [source1](https://www.wowhead.com/classic/quest=3801); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |
| key_brd:2 | Complete the second 'Dark Iron Legacy' and receive the Shadowforge Key. | 1 | hard prerequisite | High Classic; unconfirmed Forever | 3802 after3801; requires Ironfel from Fineous then shrine. Personal key not universal dungeon gate. [source1](https://www.wowhead.com/classic/quest=3802); [source2](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua) |

#### key_strat — Key: Key to the City (Stratholme) (1 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| key_strat:1 | Loot the Key to the City from Magistrate Barthilas. | None | independent / no lock | High Classic; unconfirmed Forever | Single boss loot; party key enough for gates. [source1](https://www.wowhead.com/classic/item=12382) |

#### key_dm — Key: Crescent Key (Dire Maul) (1 steps)

| Address | Exact current text | Earlier prerequisites | Classification | Confidence | Reason / source |
|---|---|---|---|---|---|
| key_dm:1 | Loot the Crescent Key from Pusillin in Dire Maul East. | None | independent / no lock | High Classic; unconfirmed Forever | Single boss loot; Pusillin conversation/chase within row; no earlier goal prerequisite. [source1](https://www.wowhead.com/classic/item=18249) |

### Inferences
- Best first-pass fan-out: Lokdelar2 unlocks3/4/5/6; Horde Onyxia8 unlocks9/10/11. Fan-in: Lokdelar7 needs all four heads; Horde Onyxia12 needs all three first skulls. Thunderfury4 demonstrates OR (either binding).

### Gaps
- Atiesh8 must be reworded from complete to accept before encoding9. Dreadsteed guide omits actual prerequisites and includes unrelated Inferno; do not ship locks on current list. Charger7/9 need acceptance-versus-completion state or corrected order; strictly earlier-completed-step data alone cannot model it. Charger7641 ordering has conflicting primary dataset versus historical commentary; keep withheld until checked.

## Which guide corrections and compatibility traps need a separate pass?

### Takeaway
Several guide issues are independent of lock UI and should be corrected with saved-tick remaps if rows move/remove.

### Cited Findings
- Dreadsteed current4 is unrelated Inferno spell quest. Actual7629 requires7564 AND7625;7630 requires7626/7627/7628;7631 requires7629 AND7630. [Questie](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [Kroshius](https://www.wowhead.com/classic/quest=7603).
- Rhokdelar4 names wrong turn-in NPC: Stoma is giver/end for7635. [A Proper String](https://www.wowhead.com/classic/quest=7635).
- Charger feed9 has parent7643 active, while7643 completion consumes the feed. [Questie](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua); [Ancient Equine Spirit](https://www.wowhead.com/classic/quest=7643); [Feed](https://www.wowhead.com/classic/quest=7645).
- Thunderfury raw ingredients form Elementium; final turn-in only needs bars,bindings,Essence. Auto quest7786 on defeat11 currently fires at summon turn-in10. [Thunderaan](https://www.wowhead.com/classic/quest=7786).
- Atiesh class purification includes Stratholme entity kill and final return; current8 says complete before9 kill. [Purification](https://www.wowhead.com/classic/quest=9257).
- Classic Frostsaber quests are repeatable (specialFlags1) and min58 in Questie, contrasting current level40 and daily wording. Verify Forever version before changing. [Questie](https://github.com/Questie/Questie/blob/v10.0.0/Database/Classic/classicQuestDB.lua).
- MC and BWL attunements are entry shortcuts. Personal UBRS/Scholo/DM/BRD keys can be supplied by party/lockpicking as appropriate. [Attunement guide](https://www.wowhead.com/classic/guide/classic-wow-attunements-and-keys-dungeons-raids).

### Inferences
- Do not infer locks from row number or automatic-rule coincidence. Thunderfury11 and Atiesh8 demonstrate that existing automatic completion rules/text can represent a different event from the action label.
- Sulfuras hammer purchase bypasses personal recipe/material/profession steps; strict craft-only gating would prevent a valid purchased hammer path.

### Gaps
- Exact level/race/riding/quest eligibility in Forever remains a beta-check task. Some drop pre-loot conditions (Core Fragment,Atiesh head/base) are conservative and explicitly withheld/provisional.
