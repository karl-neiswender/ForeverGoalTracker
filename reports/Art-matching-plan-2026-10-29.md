# Art matching plan and work order, built 2026-10-29

Locked by Karl on 2026-10-29 (commit 5abd851). Companion to [Goal-art-checklist.html](Goal-art-checklist.html), which stays the record of what is mapped where. This page is the work queue: open the `.html` copy for thumbnails. Rebuild with `python tools/art-plan.py build`.

**Progress: 16 of 150 workable banners verified.** Queued 119, Installed 15, Verified 16, Blocked 3, Skipped (low-res) 22. 57 slots have no source image.

## Codex: start here

### Goal

Every image below is locked by Karl (2026-10-29, commit 5abd851). Turn each one into an approved, installed and mapped banner, and keep [Goal-art-checklist.html](Goal-art-checklist.html) accurate while you do. **Target: all P1 goal banners by Oct 31, P2 by Nov 2, as much of P3 as fits by Nov 3, so live Forever can be tested on Nov 4.** New textures need a full game restart, so everything has to be installed before then.

### Who does what

- **Codex:** generate, install and map, update the checklist, and record each batch.
- **Karl:** looks at each batch's review sheet and says approve or reject. His approval of the *picks* does not approve a generated banner.
- **Claude:** double-checks every installed batch (`verify`), marks it `verified`, and rebuilds this page. Only Claude marks a row `verified`.

### Rules that never bend

1. Never change, rename or delete anything in `Media/artwork`. Originals stay untouched. Karl will rename files himself.
2. Never install a banner Karl has not approved. Do not infer approval from a filename or an earlier approval.
3. Skip every row marked **Skipped (low-res)** or **Blocked**. Do not generate, upscale or install from them. Karl is finding larger files; when he does, `swap` brings the row back.
4. Use the picked file. Do not swap in the alternate or another image. If the picture contradicts the slot (wrong race, sex, class or set), stop: set the row `blocked` with a note and tell Karl.
5. Rows marked *inferred* were guessed from the file name. Check the picture matches before you start the row.
6. Never invent artist credits. Remove visible watermarks and signatures from the banner; keep credits on the goal as verified.
7. Touch only the files a batch needs. Stage only your own hunks, keep LF line endings, and commit one batch at a time. Claude and Codex share this tree.
8. Do not edit this plan's slots or order. Progress goes through `tools/art-plan.py` only.

### The batch loop (8 images per batch)

Work in batch order. `python tools/art-plan.py batch` prints the next one. Do all 8, then ask Karl to review. While he reviews you may generate the next batch, but install only what he has approved. A batch is finished when its rows are `verified`.

1. **Prepare.** For each row open the picked file, confirm it matches the slot, and read its targets (goal, race, class, sex and a suggested key; keep the key unless a nearby banner in `Core.lua` follows a different pattern). A TCG card scan needs the artwork cropped out of the frame first; keep nothing of the frame, text or numbers.
2. **Generate** one review image per row with the banner skill (`.agents/skills/forever-goal-tracker-banners/SKILL.md`): 4:3, 1200 x 900, strictly black and white, left gradient and bottom gradient baked in, subject high and right, no text or border. Save it as `Media/final-images/<key>-review-<date>-v1.png`.
3. **Pre-check** each review image: `python tools/art-plan.py check-master <file>`. It fails a wrong size, any color, or a missing left or bottom gradient. Fix those before Karl sees them.
4. **Record.** Source, output and exact prompt for every image go in `reports/image-tests/<batch>-<date>.md`.
5. **Show Karl** the sheet: `python tools/art-plan.py sheet <batch>`, then `python tools/art-plan.py set <ids> review`. Wait for his answer per image.
6. **Install the approved ones** (see the next section), then `set <ids> approved` and `set <ids> installed --banner <key>`.
7. **Rejected:** `set <id> rejected --note "his reason"`, regenerate once, show again. Rejected twice means `blocked` and ask Karl.
8. **Commit** the batch, then message Claude to verify. One line in `reports/CURRENT.md` per batch.

### Installing one approved banner

1. Copy the approved review image to the master path and add the key to `FINAL_BANNERS` in `tools/artwork.py` (same naming as the neighbors).
2. `python tools/artwork.py --final-only` writes the 512 px DXT1 BLP with 10 mips and the runtime manifest entry.
3. Register the path in `Core.lua`, 4:3 and `preprocessed=true`. **Item goals:** `B.artVariants.<goal> = {{path=..., aspect=4/3, preprocessed=true}}`. **Level Classes to 60:** a new entry in the `allclasses` list with `faction`, `class`, `race` and `sex` (`sex=2` male, `sex=3` female). **Tier, Dungeon and PvP sets:** a new entry on that set's variants with `faction`, `race` and `sex`; keep the existing entries. Equal weights tie to the first entry, so a replacement goes before the old one.
4. One image used for two slots (a Warrior and Paladin file, or Dungeon Set 1 and 2): one master and one BLP, registered for each slot.
5. Add one assertion per new banner to `tools/banner-tests.lua` (`B:ResolveArt(goal, who)` returns the new path).
6. Update the checklist (next section), then run `python tools/check.py` and `sh tools/sync-era.sh`.

### Updating the goal art checklist

The checklist is the record of what is mapped where. For every installed banner follow the *Goal art checklist* section of `reports/reference/artwork.md`:

- **Statuses:** edit the row in `GOALS` or `TABLES` (a goal with its own image is `done`, class and race art that could get a faction version is `share`), and put the banner key (without `-banner.blp`) in the note.
- **Level Classes to 60:** add the entry to `RC_ART` with `pic` (m, f or mf: who the picture shows) and `only` for a one-sex image. **Sets:** add the key to `SETPIC` (`m`, `f`, `mf` or `n`).
- **New goals** (the 15 Library goals from this week) already have rows; change `need` to `done` and replace the planned source with the banner key.
- **Found log:** one dated line in `FOUND` per banner. Update the header date and the *Find these first* list.
- **Thumbnails:** `python tools/art-checklist.py thumbs` rebuilds them from the banners, and also embeds the planned source images named in a note (`Planned:` or `Source image:`).
- Statuses must match the resolver in `Core.lua`, not the file names. Do not install or rename anything while editing the checklist.

### Done means verified

`python tools/art-plan.py verify <ids>` must pass for each item: the BLP (512 x 512 DXT1, 10 mips), the master (1200 x 900, neutral, both gradients), the manifest, the `Core.lua` path, the **resolver returning the new banner for the slot's race, class, faction and sex**, the checklist thumbnail and entries, and a record. Then `python tools/check.py` must pass. Claude runs both and marks the row `verified`.

### Stop and ask Karl when

- The picture does not match its slot, or a row says inferred and you are unsure.
- A target has no goal id or the resolver cannot express the slot.
- Two sources want one slot, or a replacement would change art Karl already approved.
- A test or `verify` fails twice for the same reason.
- You are behind schedule: stop starting new priorities and tell Karl what is left.

### Pace

Karl's review is one limit, generation is the other. Past sessions installed 5 to 8 banners at a time, so 8 per batch matches that. The plan has 150 workable banners; P1 is 34, P2 is 46, P3 is 60. Finishing all of P1 and P2 by Nov 4 needs about 16 installed per day. If review or generation runs slower, P1 first, then P2, and leave P3 for 2.16.1.

**Decided by Karl (2026-10-29): imagegen only.** Every banner, including clean paintings, is made with imagegen as the banner skill says. Do not use a deterministic crop, grayscale and gradient shortcut.

## Work queue

State: ☐ not verified, ☑ verified. Batches are in order; rows keep their id for good (`A001`...).

### Batch 1

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☑ | A001 | P1 | `weapon-black-amnesty.png` 745x1040 |  | Black Amnesty: `black_amnesty` / `black_amnesty` | Verified | card scan, crop first  |
| ☑ | A003 | P1 | `weapon-brain-hacker.png` 745x1040 |  | Brain Hacker: `brain_hacker` / `brain_hacker` | Verified | card scan, crop first  |
| ☑ | A004 | P1 | `item-cloak-of-flame.png` 745x1040 |  | Cloak of Flames: `cloak_of_flames` / `cloak_of_flames` | Verified | card scan, crop first  |
| ☑ | A005 | P1 | `item-cloak-of-the-shrouded-mists.png` 745x1040 |  | Cloak of the Shrouded Mists: `cloak_of_the_shrouded_mists` / `cloak_of_the_shrouded_mists` | Verified | card scan, crop first  |
| ☑ | A006 | P1 | `weapon-cold-forged-hammer.png` 745x1040 |  | Cold Forged Hammer: `cold_forged_hammer` / `cold_forged_hammer` | Verified | card scan, crop first  |
| ☑ | A007 | P1 | `weapon-Crackling_Staff.jpg` 1024x921 |  | Crackling Staff (Alliance): `crackling_staff` / `crackling_staff` | Verified |   |
| ☑ | A009 | P1 | `item-crown-of-the-ogre-king.png` 745x1040 |  | Crown of the Ogre King: `crown_of_the_ogre_king` / `crown_of_the_ogre_king` | Verified | card scan, crop first  |
| ☑ | A010 | P1 | `goal-dance.png` 745x1040 |  | Dance With Others: `social_dance_partners` / `social_dance_partners` | Verified | card scan, crop first  |

### Batch 2

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☑ | A012 | P1 | `item-drillborer-disk.png` 745x1040 |  | Drillborer Disk: `drillborer_disk` / `drillborer_disk` | Verified | card scan, crop first  |
| ☑ | A014 | P1 | `weapon-electrified-dagger.png` 745x1040 |  | Electrified Dagger (Alliance): `electrified_dagger` / `electrified_dagger` | Verified | card scan, crop first  |
| ☑ | A015 | P1 | `weapon-eskhandars-right-claw-tooth.png` 745x1040 |  | Eskhandar's Right Claw: `eskhandars_right_claw` / `eskhandars_right_claw` | Verified | card scan, crop first  |
| ☑ | A016 | P1 | `weapon-fang-of-the-crystal-spider.png` 745x1040 |  | Fang of the Crystal Spider: `fang_of_the_crystal_spider` / `fang_of_the_crystal_spider` | Verified | card scan, crop first  |
| ☑ | A017 | P1 | `weapon-felstriker.png` 745x1040 |  | Felstriker: `felstriker` / `felstriker` | Verified | card scan, crop first  |
| ☑ | A018 | P1 | `weapon-heartseeker.png` 745x1040 |  | Heartseeker: `heartseeker` / `heartseeker` | Verified | card scan, crop first  |
| ☑ | A019 | P1 | `item-skullflame-shield.png` 745x1040 |  | Skullflame Shield: `skullflame_shield` / `skullflame_shield` | Verified | card scan, crop first  |
| ☑ | A021 | P1 | `alliance-human-female-paladin-tier3-weapon-untamed-blade.png` 745x1040 |  | The Untamed Blade: `the_untamed_blade` / `the_untamed_blade` | Verified | card scan, crop first  |

### Batch 3

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A022 | P1 | `weapon-viking-warhammer.png` 745x1040 |  | Viking Warhammer: `viking_warhammer` / `viking_warhammer` | Installed | card scan, crop first  |
| ☐ | A024 | P1 | `weapon-Barman_Shanker.jpg` 1042x1200 |  | Barman Shanker: `barman_shanker` / `barman_shanker` | Installed |   |
| ☐ | A025 | P1 | `weapon-claw-frost-wyrm.jpg` 1024x1001 |  | Claw of the Frost Wyrm: `claw_of_the_frost_wyrm` / `claw_of_the_frost_wyrm` | Installed |   |
| ☐ | A027 | P1 | `weapon-Gurubashi_Dwarf_Destroyer.jpg` 1371x1200 |  | Gurubashi Dwarf Destroyer: `gurubashi_dwarf_destroyer` / `gurubashi_dwarf_destroyer` | Installed |   |
| ☐ | A028 | P1 | `weapon-hand-edward-odd.png` 745x1040 |  | Hand of Edward the Odd: `hand_of_edward_the_odd` / `hand_of_edward_the_odd` | Installed | card scan, crop first The card is titled Scepter of the Unholy. Confirm it is the right art for this mace. |
| ☐ | A029 | P1 | `weapon-Hypnotic_Blade.jpg` 1371x1200 |  | Hypnotic Blade: `hypnotic_blade` / `hypnotic_blade` | Installed |   |
| ☐ | A030 | P1 | `weapon-ice-barbed-spear.png` 745x1040 |  | Ice Barbed Spear: `ice_barbed_spear` / `ice_barbed_spear` | Installed | card scan, crop first  |
| ☐ | A031 | P1 | `weapon-staff-of-command.jpg` 1337x1200 |  | Lord Valthalak's Staff of Command: `lord_valthalaks_staff_of_command` / `lord_valthalaks_staff_of_command` | Installed |   |

### Batch 4

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A032 | P1 | `weapon-Masterwork_Stormhammer.png` 745x1040 |  | Masterwork Stormhammer: `masterwork_stormhammer` / `masterwork_stormhammer` | Installed | card scan, crop first  |
| ☐ | A033 | P1 | `weapon-phantom-blade.jpg` 682x615 |  | Phantom Blade: `phantom_blade` / `phantom_blade` | Installed |   |
| ☐ | A034 | P1 | `item-red-dragonscale-protector.jpg` 504x576 |  | Red Dragonscale Protector: `red_dragonscale_protector` / `red_dragonscale_protector` | Installed |  Older source with a dwarf holding it: alliance-dwarf-male-warrior-paladin-red-dragonscale-protector.jpg. |
| ☐ | A035 | P1 | `weapon-skuls-ghastly-touch-wand.png` 745x1040 |  | Skul's Ghastly Touch: `skuls_ghastly_touch` / `skuls_ghastly_touch` | Installed | card scan, crop first The card is titled Vengeful Gladiator's Piercing Touch. Confirm it is the right art for this wand. |
| ☐ | A036 | P1 | `weapon-staff-of-jordan.jpg` 704x541 |  | Staff of Jordan: `staff_of_jordan` / `staff_of_jordan` | Installed |   |
| ☐ | A037 | P1 | `weapon-wand-of-fates.jpg` 1024x795 |  | Wand of Fates: `wand_of_fates` / `wand_of_fates` | Installed |   |
| ☐ | A038 | P1 | `boss-nefarius.jpg` 3000x4000 |  | Attunement: Blackwing Lair (both): `att_bwl` / `att_bwl` | Installed | Karl's pick Karl's pick. Lord Victor Nefarius; goal inferred. My earlier pick, now the alternate: boss-nefarian-raid.jpg. Today it borrows the Clear Blackwing Lair image. Alt: raid-blackwinglair-boss-neltharion.jpg. |
| ☐ | A039 | P1 | `boss-hakkar.jpg` 2500x3277 |  | Exalted: Zandalar Tribe (both): `rep_zandalar` / `rep_zandalar` | Blocked |  Today it borrows Clear Zul'Gurub. Weakest match: nothing in the folder pictures the tribe. Medium confidence. |

### Batch 5

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A040 | P1 | `location-blackrock-mountain-gates.jpg` 872x981 |  | Key: Shadowforge Key (both): `key_brd` / `key_brd` | Queued |  Today it borrows the Seal of Ascension image. The Dark Iron gate face suits the Shadowforge gate. Alt: location-blackrock-spire-2.jpg. |
| ☐ | A041 | P1 | `alliance-dwarf-human-male-plate-campfire-2.jpg` 1024x1024 |  | Place Campfires (both): `social_campfires` / `social_campfires` | Queued | Karl's pick Karl's pick. Image of two plate-armored characters at a fire; goal inferred from the name. My earlier pick, now the alternate: goal-campfire.jpg. Today it borrows the Cooking image. Alt: alliance-dwarf-human-male-plate-campfire.jpg (two characters at a fire). |
| ☐ | A042 | P1 | `mount-raptor.jpg` 1520x1190 |  | Swift Razzashi Raptor (both): `mount_raptor` / `mount_raptor` | Queued |  Today it borrows the Clear Zul'Gurub image. Not mount-swift-raptor.jpg, which is the Troll epic mount banner. |
| ☐ | A043 | P2 | `alliance-dwarf-female-paladin-generic-leveling.jpg` 1050x1400 | `alliance-dwarf-female-warrior-paladin-generic-leveling.jpg` | Level Classes to 60: Dwarf Paladin F: `allclasses` / `allclasses_dwarf_paladin_female` | Queued |   |
| ☐ | A044 | P2 | `alliance-dwarf-female-priest-generic-leveling-3.jpg` 1280x1700 | `alliance-dwarf-female-priest-generic-leveling-2.jpg` | Level Classes to 60: Dwarf Priest F: `allclasses` / `allclasses_dwarf_priest_female` | Queued |   |
| ☐ | A045 | P2 | `alliance-dwarf-male-priest-leveling.jpg` 4642x3756 | `alliance-dwarf-male-priest-tier3.png` | Level Classes to 60: Dwarf Priest M: `allclasses` / `allclasses_dwarf_priest_male` | Queued |   |
| ☐ | A047 | P2 | `alliance-dwarf-female-shaman-generic.jpg` 1800x1461 |  | Level Classes to 60: Dwarf Shaman F: `allclasses` / `allclasses_dwarf_shaman_female` | Queued |   |
| ☐ | A048 | P2 | `alliance-dwarf-female-warrior-paladin-generic-leveling-2.jpg` 798x1024 | `alliance-dwarf-female-warrior-paladin-generic-leveling.jpg` | Level Classes to 60: Dwarf Warrior F: `allclasses` / `allclasses_dwarf_warrior_female` | Queued |   |

### Batch 6

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A049 | P2 | `alliance-gnome-male-mage-generic.png` 745x1040 | `alliance-gnome-male-mage-tier2.png` | Level Classes to 60: Gnome Mage M: `allclasses` / `allclasses_gnome_mage_male` | Queued | card scan, crop first  |
| ☐ | A050 | P2 | `alliance-gnome-male-priest-tier3.png` 745x1040 |  | Level Classes to 60: Gnome Priest M: `allclasses` / `allclasses_gnome_priest_male` | Queued | card scan, crop first  |
| ☐ | A051 | P2 | `alliance-skyborne-female-mage-generic.jpg` 1548x1200 |  | Level Classes to 60: High Order Skyborne Mage F: `allclasses` / `allclasses_skyborne_mage_female` | Queued |   |
| ☐ | A052 | P2 | `alliance-human-female-mage-generic.jpg` 2850x3661 | `alliance-human-female-mage-generic.png` | Level Classes to 60: Human Mage F: `allclasses` / `allclasses_human_mage_female` | Queued |   |
| ☐ | A053 | P2 | `alliance-human-male-mage-generic.jpg` 1012x812 | `alliance-human-male-mage-tier2.jpg` | Level Classes to 60: Human Mage M: `allclasses` / `allclasses_human_mage_male` | Queued |   |
| ☐ | A054 | P2 | `alliance-human-female-priest-generic-leveling.png` 745x1040 | `alliance-human-female-priest-tier1.jpg` | Level Classes to 60: Human Priest F: `allclasses` / `allclasses_human_priest_female` | Queued | card scan, crop first  |
| ☐ | A055 | P2 | `alliance-human-male-priest-tier2.jpg` 1189x1379 |  | Level Classes to 60: Human Priest M: `allclasses` / `allclasses_human_priest_male` | Queued |   |
| ☐ | A056 | P2 | `alliance-human-female-warlock-leveling.jpg` 1000x1143 | `alliance-human-female-warlock-tier2.jpg` | Level Classes to 60: Human Warlock F: `allclasses` / `allclasses_human_warlock_female` | Queued |   |

### Batch 7

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A057 | P2 | `alliance-human-male-warlock-tier1-2.png` 745x1040 | `alliance-human-male-warlock-tier1.png` | Level Classes to 60: Human Warlock M: `allclasses` / `allclasses_human_warlock_male` | Queued | card scan, crop first  |
| ☐ | A058 | P2 | `alliance-nightelf-female-druid-generic.jpg` 745x1040 | `alliance-nightelf-female-druid-leather-dungeonset.png` | Level Classes to 60: Night Elf Druid F: `allclasses` / `allclasses_nightelf_druid_female` | Queued | card scan, crop first  |
| ☐ | A060 | P2 | `alliance-nightelf-male-hunter-generic-2.jpg` 2000x1624 | `alliance-nightelf-male-hunter-generic-leveling-2.png` | Level Classes to 60: Night Elf Hunter M: `allclasses` / `allclasses_nightelf_hunter_male` | Queued |   |
| ☐ | A061 | P2 | `alliance-nightelf-female-priest-leveling.png` 745x1040 | `a-nightelf-female-priest-shadow.png` | Level Classes to 60: Night Elf Priest F: `allclasses` / `allclasses_nightelf_priest_female` | Queued | card scan, crop first  |
| ☐ | A062 | P2 | `alliance-nightelf-male-priest-leveling.png` 745x1040 |  | Level Classes to 60: Night Elf Priest M: `allclasses` / `allclasses_nightelf_priest_male` | Queued | card scan, crop first  |
| ☐ | A063 | P2 | `alliance-nightelf-male-rogue-generic.png` 621x500 | `alliance-nightelf-male-rogue-tier1.jpg` | Level Classes to 60: Night Elf Rogue M: `allclasses` / `allclasses_nightelf_rogue_male` | Queued |   |
| ☐ | A064 | P2 | `horde-orc-male-hunter-tier1.jpg` 1758x2048 | `horde-orc-male-hunter-tier2.jpg` | Level Classes to 60: Orc Hunter M: `allclasses` / `allclasses_orc_hunter_male` | Queued |   |
| ☐ | A065 | P2 | `horde-orc-female-mage-generic-leveling.jpg` 4367x3545 |  | Level Classes to 60: Orc Mage F: `allclasses` / `allclasses_orc_mage_female` | Queued |   |

### Batch 8

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A066 | P2 | `horde-orc-male-mage-warlock-generic-leveling.jpg` 4367x3545 |  | Level Classes to 60: Orc Mage M: `allclasses` / `allclasses_orc_mage_male` | Queued |   |
| ☐ | A067 | P2 | `horde-orc-female-rogue-tier2.jpg` 1024x1325 |  | Level Classes to 60: Orc Rogue F: `allclasses` / `allclasses_orc_rogue_female` | Queued |   |
| ☐ | A068 | P2 | `horde-orc-female-shaman-tier2.png` 745x1040 | `horde-orc-female-shaman-tier1.jpg` | Level Classes to 60: Orc Shaman F: `allclasses` / `allclasses_orc_shaman_female` | Queued | card scan, crop first  |
| ☐ | A069 | P2 | `h-orc-male-shaman-generic-leveling.png` 745x1040 | `horde-orc-male-shaman-generic.jpg` | Level Classes to 60: Orc Shaman M: `allclasses` / `allclasses_orc_shaman_male` | Queued | card scan, crop first  |
| ☐ | A070 | P2 | `horde-orc-female-warlock-leveling.jpg` 742x650 |  | Level Classes to 60: Orc Warlock F: `allclasses` / `allclasses_orc_warlock_female` | Queued |   |
| ☐ | A071 | P2 | `horde-orc-male-warlock-tier1.jpg` 862x1000 | `horde-orc-male-warlock-tier2.jpg` | Level Classes to 60: Orc Warlock M: `allclasses` / `allclasses_orc_warlock_male` | Queued |   |
| ☐ | A072 | P2 | `horde-orc-female-warrior-leveling-2.jpg` 2500x3445 | `horde-orc-female-warrior-generic-leveling-2.png` | Level Classes to 60: Orc Warrior F: `allclasses` / `allclasses_orc_warrior_female` | Queued | Karl's pick  |
| ☐ | A073 | P2 | `horde-orc-male-warrior-generic-leveling-3.jpg` 984x1384 | `horde-orc-male-warrior-generic-leveling-2.jpg` | Level Classes to 60: Orc Warrior M: `allclasses` / `allclasses_orc_warrior_male` | Queued | Karl's pick  |

### Batch 9

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A075 | P2 | `horde-tauren-male-druid-leveling.jpg` 1200x1200 | `horde-tauren-male-shaman-druid-generic-leveling.png` | Level Classes to 60: Tauren Druid M: `allclasses` / `allclasses_tauren_druid_male` | Queued |   |
| ☐ | A076 | P2 | `horde-tauren-female-hunter-generic-leveling.png` 745x1040 |  | Level Classes to 60: Tauren Hunter F: `allclasses` / `allclasses_tauren_hunter_female` | Queued | card scan, crop first  |
| ☐ | A077 | P2 | `horde-tauren-male-hunter-generic-2.png` 745x1040 | `horde-tauren-male-hunter-generic-leveling.png` | Level Classes to 60: Tauren Hunter M: `allclasses` / `allclasses_tauren_hunter_male` | Queued | card scan, crop first  |
| ☐ | A078 | P2 | `h-tauren-female-shaman-generic-leveling.png` 745x1040 | `horde-tauren-female-shaman-leveling-2.jpg` | Level Classes to 60: Tauren Shaman F: `allclasses` / `allclasses_tauren_shaman_female` | Queued | card scan, crop first  |
| ☐ | A079 | P2 | `horde-tauren-male-shaman-leveling-2.png` 745x1040 | `horde-tauren-male-shaman-leveling.png` | Level Classes to 60: Tauren Shaman M: `allclasses` / `allclasses_tauren_shaman_male` | Queued | card scan, crop first  |
| ☐ | A080 | P2 | `horde-tauren-female-warrior-generic-leveling.png` 745x1040 | `horde-tauren-female-warrior-generic-leveling-reaper.jpg` | Level Classes to 60: Tauren Warrior F: `allclasses` / `allclasses_tauren_warrior_female` | Queued | card scan, crop first  |
| ☐ | A081 | P2 | `horde-troll-female-mage.png` 745x1040 |  | Level Classes to 60: Troll Mage F: `allclasses` / `allclasses_troll_mage_female` | Queued | card scan, crop first  |
| ☐ | A082 | P2 | `horde-troll-female-priest-generic.jpg` 1024x831 |  | Level Classes to 60: Troll Priest F: `allclasses` / `allclasses_troll_priest_female` | Queued |   |

### Batch 10

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A083 | P2 | `horde-troll-female-rogue-generic-leveling-2.png` 745x1040 | `horde-troll-female-rogue-generic-leveling.png` | Level Classes to 60: Troll Rogue F: `allclasses` / `allclasses_troll_rogue_female` | Queued | card scan, crop first  |
| ☐ | A084 | P2 | `horde-troll-male-shaman-generic.png` 745x1040 | `horde-troll-male-shaman-leveling.png` | Level Classes to 60: Troll Shaman M: `allclasses` / `allclasses_troll_shaman_male` | Queued | card scan, crop first  |
| ☐ | A085 | P2 | `horde-troll-male-warlock-generic.png` 745x1040 |  | Level Classes to 60: Troll Warlock M: `allclasses` / `allclasses_troll_warlock_male` | Queued | card scan, crop first  |
| ☐ | A086 | P2 | `horde-troll-male-warrior-leveling-2.jpg` 843x650 | `horde-troll-male-warrior-generic-2.jpg` | Level Classes to 60: Troll Warrior M: `allclasses` / `allclasses_troll_warrior_male` | Queued | Karl's pick  |
| ☐ | A087 | P2 | `horde-undead-female-mage-tier3.png` 745x1040 |  | Level Classes to 60: Undead Mage F: `allclasses` / `allclasses_undead_mage_female` | Queued | card scan, crop first  |
| ☐ | A088 | P2 | `horde-undead-male-mage-tier2.jpg` 500x675 |  | Level Classes to 60: Undead Mage M: `allclasses` / `allclasses_undead_mage_male` | Queued |   |
| ☐ | A089 | P2 | `horde-undead-female-warlock-leveling.jpg` 1024x831 | `horde-undead-female-warlock-tier3.jpg` | Level Classes to 60: Undead Warlock F: `allclasses` / `allclasses_undead_warlock_female` | Queued |   |
| ☐ | A091 | P2 | `horde-undead-female-warrior-paladin-generic-leveling.jpg` 4367x3545 |  | Level Classes to 60: Undead Warrior F: `allclasses` / `allclasses_undead_warrior_female`<br>Level Classes to 60: Undead Paladin F: `allclasses` / `allclasses_undead_paladin_female` | Queued | Karl's pick  |

### Batch 11

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A092 | P2 | `horde-undead-male-warrior-paladin-generic-leveling.jpg` 2500x3333 | `horde-undead-male-warrior-leveling-generic-pvp.jpg` | Level Classes to 60: Undead Warrior M: `allclasses` / `allclasses_undead_warrior_male`<br>Level Classes to 60: Undead Paladin M: `allclasses` / `allclasses_undead_warrior_male` | Queued | Karl's pick replacement proposal: slot already has art |
| ☐ | A093 | P3 | `alliance-nightelf-female-druid-tier1-2.png` 745x1040 |  | Tier 1 Druid A F: `set_tier1_druid` / `set_tier1_druid_nightelf_female` | Queued | card scan, crop first  |
| ☐ | A094 | P3 | `horde-tauren-druid-female-tier1.png` 745x1040 | `horde-tauren-female-druid-tier1-2.png` | Tier 1 Druid H F: `set_tier1_druid` / `set_tier1_druid_tauren_female` | Queued | card scan, crop first  |
| ☐ | A095 | P3 | `alliance-human-female-hunter-tier1.png` 745x1040 |  | Tier 1 Hunter A F: `set_tier1_hunter` / `set_tier1_hunter_human_female` | Queued | card scan, crop first  |
| ☐ | A096 | P3 | `alliance-human-male-priest-benediction-tier1.jpg` 862x1000 |  | Tier 1 Priest A M: `set_tier1_priest` / `set_tier1_priest_human_male` | Queued |   |
| ☐ | A097 | P3 | `horde-tauren-female-priest-shadow-tier1.png` 745x1040 | `horde-undead-female-priest-tier1-2.jpg` | Tier 1 Priest H F: `set_tier1_priest` / `set_tier1_priest_tauren_female` | Queued | card scan, crop first  |
| ☐ | A098 | P3 | `alliance-human-female-rogue-tier1.png` 745x1040 |  | Tier 1 Rogue A F: `set_tier1_rogue` / `set_tier1_rogue_human_female` | Queued | card scan, crop first  |
| ☐ | A099 | P3 | `h-orc-female-shaman-tier1-hero.png` 745x1040 | `horde-orc-female-shaman-tier1.jpg` | Tier 1 Shaman H F: `set_tier1_shaman` / `set_tier1_shaman_orc_female` | Queued | card scan, crop first  |

### Batch 12

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A100 | P3 | `horde-troll-female-warlock-tier1.png` 745x1040 |  | Tier 1 Warlock H F: `set_tier1_warlock` / `set_tier1_warlock_troll_female` | Queued | card scan, crop first  |
| ☐ | A101 | P3 | `horde-orc-female-warrior-tier1.png` 745x1040 |  | Tier 1 Warrior H F: `set_tier1_warrior` / `set_tier1_warrior_orc_female` | Queued | Karl's pick, card scan, crop first  |
| ☐ | A102 | P3 | `horde-tauren-female-druid-tier2.jpg` 862x1200 |  | Tier 2 Druid H F: `set_tier2_druid` / `set_tier2_druid_tauren_female` | Queued |   |
| ☐ | A104 | P3 | `horde-orc-female-hunter-tier2-rhokdalar.png` 745x1040 |  | Tier 2 Hunter H F: `set_tier2_hunter` / `set_tier2_hunter_orc_female` | Queued | card scan, crop first  |
| ☐ | A105 | P3 | `alliance-human-female-mage-tier2.jpg` 1238x1437 |  | Tier 2 Mage A F: `set_tier2_mage` / `set_tier2_mage_human_female` | Queued |   |
| ☐ | A106 | P3 | `alliance-nightelf-female-priest-tier2-shadow.jpg` 4000x3259 | `alliance-human-female-priest-tier2.jpg` | Tier 2 Priest A F: `set_tier2_priest` / `set_tier2_priest_nightelf_female` | Queued |   |
| ☐ | A107 | P3 | `alliance-human-male-rogue-tier2-2.jpg` 747x600 | `alliance-dwarf-male-rogue-tier2.jpg` | Tier 2 Rogue A M: `set_tier2_rogue` / `set_tier2_rogue_human_male` | Queued |   |
| ☐ | A108 | P3 | `horde-orc-female-shaman-tier2-2.png` 745x1040 |  | Tier 2 Shaman H F: `set_tier2_shaman` / `set_tier2_shaman_orc_female` | Queued | card scan, crop first  |

### Batch 13

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A109 | P3 | `alliance-human-male-warlock-tier2-2.jpg` 800x1067 | `alliance-human-male-warlock-tier2.png` | Tier 2 Warlock A M: `set_tier2_warlock` / `set_tier2_warlock_human_male` | Queued |   |
| ☐ | A110 | P3 | `alliance-nightelf-female-warrior-tier2.jpg` 1024x1365 | `alliance-nightelf-female-warrior-tier2.png` | Tier 2 Warrior A F: `set_tier2_warrior` / `set_tier2_warrior_nightelf_female` | Queued |   |
| ☐ | A111 | P3 | `alliance-nightelf-female-druid-tier3.jpg` 559x800 | `alliance-nightelf-female-druid-tier3-3.png` | Tier 3 Druid A F: `tier3_druid` / `tier3_druid_nightelf_female` | Queued | Karl's pick  |
| ☐ | A112 | P3 | `horde-tauren-female-druid-tier3-2.png` 745x1040 |  | Tier 3 Druid H F: `tier3_druid` / `tier3_druid_tauren_female` | Queued | card scan, crop first  |
| ☐ | A113 | P3 | `horde-orc-female-hunter-tier3.png` 745x1040 |  | Tier 3 Hunter H F: `tier3_hunter` / `tier3_hunter_orc_female` | Queued | card scan, crop first  |
| ☐ | A114 | P3 | `alliance-gnome-female-mage-tier3.jpg` 1517x1200 | `alliance-gnome-female-mage-tier3.png` | Tier 3 Mage A F: `tier3_mage` / `tier3_mage_gnome_female` | Queued |   |
| ☐ | A115 | P3 | `horde-orc-female-mage-tier3.png` 745x1040 |  | Tier 3 Mage H F: `tier3_mage` / `tier3_mage_orc_female` | Queued | card scan, crop first  |
| ☐ | A116 | P3 | `alliance-dwarf-female-paladin-tier3-2.jpg` 1024x1024 | `alliance-dwarf-female-paladin-tier3.jpg` | Tier 3 Paladin A F: `tier3_paladin` / `tier3_paladin_dwarf_female` | Queued |   |

### Batch 14

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A117 | P3 | `horde-troll-male-priest-tier3.png` 745x1040 | `horde-undead-male-priest-tier3.png` | Tier 3 Priest H M: `tier3_priest` / `tier3_priest_troll_male` | Queued | card scan, crop first  |
| ☐ | A118 | P3 | `horde-orc-female-rogue-tier3.png` 745x1040 |  | Tier 3 Rogue H F: `tier3_rogue` / `tier3_rogue_orc_female` | Queued | card scan, crop first  |
| ☐ | A119 | P3 | `horde-orc-male-shaman-tier3-2.jpg` 1280x749 | `horde-orc-male-shaman-tier3.jpg` | Tier 3 Shaman H M: `tier3_shaman` / `tier3_shaman_orc_male` | Queued |   |
| ☐ | A120 | P3 | `alliance-nightelf-female-druid-dungeonset-2.png` 745x1040 | `alliance-nightelf-female-druid-leather-dungeonset.png` | Dungeon Set 1 Druid A: `set_dungeon1_druid` / `set_dungeon1_druid_nightelf` | Queued | card scan, crop first  |
| ☐ | A121 | P3 | `horde-tauren-male-druid-dungeonset.png` 745x1040 |  | Dungeon Set 1 Druid H: `set_dungeon1_druid` / `set_dungeon1_druid_tauren` | Queued | card scan, crop first  |
| ☐ | A122 | P3 | `alliance-nightelf-female-hunter-dungeonset.jpg` 600x471 | `alliance-human-male-hunter-dungeonset.png` | Dungeon Set 1 Hunter A: `set_dungeon1_hunter` / `set_dungeon1_hunter_nightelf` | Queued | Karl's pick  |
| ☐ | A123 | P3 | `horde-tauren-male-hunter-generic-leveling-dungeonset.png` 745x1040 |  | Dungeon Set 1 Hunter H: `set_dungeon1_hunter` / `set_dungeon1_hunter_tauren`<br>Dungeon Set 2 Hunter H: `set_dungeon2_hunter` / `set_dungeon2_hunter_tauren` | Queued | card scan, crop first  |
| ☐ | A124 | P3 | `alliance-human-male-mage-generic-dungeonset.png` 745x1040 |  | Dungeon Set 1 Mage A: `set_dungeon1_mage` / `set_dungeon1_mage_human`<br>Dungeon Set 2 Mage A: `set_dungeon2_mage` / `set_dungeon2_mage_human` | Queued | card scan, crop first  |

### Batch 15

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A125 | P3 | `horde-troll-male-mage-dungeonset-2.png` 745x1040 | `horde-troll-male-mage-dungeonset.png` | Dungeon Set 1 Mage H: `set_dungeon1_mage` / `set_dungeon1_mage_troll` | Queued | card scan, crop first  |
| ☐ | A127 | P3 | `alliance-dwarf-male-priest-dungeonset.jpg` 1024x837 |  | Dungeon Set 1 Priest A: `set_dungeon1_priest` / `set_dungeon1_priest_dwarf` | Queued |   |
| ☐ | A128 | P3 | `horde-undead-male-cloth-dungeonset.jpg` 1051x1200 |  | Dungeon Set 1 Priest H: `set_dungeon1_priest` / `set_dungeon1_priest_undead`<br>Dungeon Set 2 Priest H: `set_dungeon2_priest` / `set_dungeon2_priest_undead` | Queued |   |
| ☐ | A131 | P3 | `horde-orc-female-shaman-dungeonset.jpg` 1024x795 | `horde-tauren-female-shaman-dungeonset.png` | Dungeon Set 1 Shaman H: `set_dungeon1_shaman` / `set_dungeon1_shaman_orc` | Queued |   |
| ☐ | A132 | P3 | `alliance-gnome-female-warlock-generic-leveling-dungeonset.jpg` 1125x1500 |  | Dungeon Set 1 Warlock A: `set_dungeon1_warlock` / `set_dungeon1_warlock_gnome` | Queued |   |
| ☐ | A133 | P3 | `horde-orc-male-warlock-dungeonset.png` 745x1040 | `horde-orc-male-warlock-dungeonset.jpg` | Dungeon Set 1 Warlock H: `set_dungeon1_warlock` / `set_dungeon1_warlock_orc` | Queued | card scan, crop first  |
| ☐ | A134 | P3 | `alliance-dwarf-male-warrior-dungeonset-plate.png` 745x1040 | `alliance-human-male-dungeonset-plate.jpg` | Dungeon Set 1 Warrior A: `set_dungeon1_warrior` / `set_dungeon1_warrior_dwarf` | Queued | card scan, crop first  |
| ☐ | A136 | P3 | `alliance-nightelf-female-druid-dungeonset.png` 745x1040 | `alliance-nightelf-female-druid-leather-dungeonset.png` | Dungeon Set 2 Druid A: `set_dungeon2_druid` / `set_dungeon2_druid_nightelf` | Queued | card scan, crop first  |

### Batch 16

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A137 | P3 | `horde-troll-female-leather-dungeonset1.png` 745x1040 |  | Dungeon Set 2 Druid H: `set_dungeon2_druid` / `set_dungeon2_druid_troll` | Queued | card scan, crop first  |
| ☐ | A138 | P3 | `alliance-dwarf-male-hunter-dungeonset.jpg` 4200x5409 | `alliance-human-male-hunter-dungeonset.png` | Dungeon Set 2 Hunter A: `set_dungeon2_hunter` / `set_dungeon2_hunter_dwarf` | Queued |   |
| ☐ | A139 | P3 | `horde-troll-male-mage-dungeonset-4.png` 745x1040 | `horde-troll-male-mage-dungeonset.png` | Dungeon Set 2 Mage H: `set_dungeon2_mage` / `set_dungeon2_mage_troll` | Queued | card scan, crop first  |
| ☐ | A141 | P3 | `alliance-nightelf-female-priest-dungeonset.png` 745x1040 |  | Dungeon Set 2 Priest A: `set_dungeon2_priest` / `set_dungeon2_priest_nightelf` | Queued | card scan, crop first  |
| ☐ | A142 | P3 | `horde-orc-male-shaman-dungeonset.png` 745x1040 | `horde-tauren-female-shaman-dungeonset.png` | Dungeon Set 2 Shaman H: `set_dungeon2_shaman` / `set_dungeon2_shaman_orc` | Queued | card scan, crop first  |
| ☐ | A143 | P3 | `alliance-gnome-male-warlock-dungeonset1.png` 745x1040 |  | Dungeon Set 2 Warlock A: `set_dungeon2_warlock` / `set_dungeon2_warlock_gnome` | Queued | card scan, crop first  |
| ☐ | A145 | P3 | `alliance-nightelf-male-warrior-dungeonset.png` 745x1040 | `alliance-human-male-dungeonset-plate.jpg` | Dungeon Set 2 Warrior A: `set_dungeon2_warrior` / `set_dungeon2_warrior_nightelf` | Queued | card scan, crop first  |
| ☐ | A146 | P3 | `horde-undead-female-aqset-cloth.jpg` 745x1040 |  | Cloth: Enigma Vestments (Mage), Doomcaller's Attire (Warlock), Garments of the Oracle (Priest): `set_tier25` / `set_tier25_cloth` | Queued | card scan, crop first One image per armor type; map it to the goals in the title. |

### Batch 17

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A147 | P3 | `alliance-nightelf-male-druid-aqset-leather.jpg` 918x1200 |  | Leather: Deathdealer's Embrace (Rogue), Genesis Raiment (Druid): `set_tier25` / `set_tier25_leather` | Queued |  One image per armor type; map it to the goals in the title. |
| ☐ | A148 | P3 | `horde-orc-male-hunter-aqset-mail.jpg` 861x1200 |  | Mail: Striker's Garb (Hunter), Stormcaller's Garb (Shaman): `set_tier25` / `set_tier25_mail` | Queued |  One image per armor type; map it to the goals in the title. |
| ☐ | A149 | P3 | `alliance-dwarf-male-aqset-plate.jpg` 861x1200 |  | Plate: Conqueror's Battlegear (Warrior), Avenger's Battlegear (Paladin): `set_tier25` / `set_tier25_plate` | Queued |  One image per armor type; map it to the goals in the title. |
| ☐ | A150 | P3 | `alliance-dwarf-male-paladin-pvpset-plate.png` 745x1040 | `alliance-human-male-paladin-pvpset-plate.jpg` | Field Marshal's Aegis (Paladin) M: `None` / `pvp_field_marshal_s_aegis_paladin_m` | Queued | card scan, crop first PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A151 | P3 | `alliance-human-female-priest-pvpset-cloth.png` 745x1040 |  | Field Marshal's Raiment (Priest) F: `None` / `pvp_field_marshal_s_raiment_priest_f` | Queued | card scan, crop first PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A152 | P3 | `alliance-human-female-mage-pvpset-cloth.jpg` 929x750 | `alliance-human-female-mage-pvpset-cloth-2.jpg` | Field Marshal's Regalia (Mage) F: `None` / `pvp_field_marshal_s_regalia_mage_f` | Queued |  PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A154 | P3 | `alliance-gnome-female-warlock-pvpset-cloth.png` 745x1040 | `alliance-human-female-warlock-pvpset-cloth.jpg` | Field Marshal's Threads (Warlock) F: `None` / `pvp_field_marshal_s_threads_warlock_f` | Queued | card scan, crop first PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A155 | P3 | `alliance-nightelf-male-rogue-pvpset-leather-2.png` 745x1040 | `alliance-nightelf-male-rogue-pvpset-leather-3.png` | Field Marshal's Vestments (Rogue) M: `None` / `pvp_field_marshal_s_vestments_rogue_m` | Queued | card scan, crop first PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |

### Batch 18

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A156 | P3 | `horde-troll-female-warrior-plate-pvpset.png` 745x1040 |  | Warlord's Battlegear (Warrior) F: `None` / `pvp_warlord_s_battlegear_warrior_f` | Queued | card scan, crop first PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A157 | P3 | `horde-tauren-female-shaman-pvpset-mail.jpg` 500x442 |  | Warlord's Earthshaker (Shaman) F: `None` / `pvp_warlord_s_earthshaker_shaman_f` | Queued |  PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A158 | P3 | `horde-tauren-female-druid-pvpset-leather.jpg` 700x530 |  | Warlord's Sanctuary (Druid) F: `None` / `pvp_warlord_s_sanctuary_druid_f` | Queued |  PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A159 | P3 | `horde-tauren-male-druid-pvpset-leather.jpg` 1041x1200 |  | Warlord's Sanctuary (Druid) M: `None` / `pvp_warlord_s_sanctuary_druid_m` | Queued |  PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A160 | P3 | `horde-orc-male-warlock-pvpset-cloth.jpg` 550x788 | `horde-orc-male-warlock-pvpset-cloth-2.jpg` | Warlord's Threads (Warlock) M: `None` / `pvp_warlord_s_threads_warlock_m` | Queued |  PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| ☐ | A161 | P4 | `alliance-gnome-male-warlock-generic-leveling.png` 745x1040 |  | Level Classes to 60: Gnome Warlock M: `allclasses` / `allclasses_gnome_warlock_male` | Queued | Karl's pick, card scan, crop first replacement proposal: slot already has art |
| ☐ | A162 | P4 | `horde-undead-male-rogue-generic-leveling-3.jpg` 1024x867 |  | Level Classes to 60: Undead Rogue M: `allclasses` / `allclasses_undead_rogue_male` | Queued | Karl's pick replacement proposal: slot already has art |
| ☐ | A163 | P4 | `alliance-nightelf-male-hunter-tier1.jpg` 1050x1200 |  | Tier 1 Hunter A M: `set_tier1_hunter` / `set_tier1_hunter_nightelf_male` | Queued | Karl's pick replacement proposal: slot already has art |

### Batch 19

| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |
|---|---|---|---|---|---|---|---|
| ☐ | A164 | P4 | `horde-tauren-male-hunter-tier1.png` 745x1040 |  | Tier 1 Hunter H M: `set_tier1_hunter` / `set_tier1_hunter_tauren_male` | Queued | Karl's pick, card scan, crop first replacement proposal: slot already has art |
| ☐ | A165 | P4 | `horde-orc-male-warrior-tier1-2.jpg` 1494x1200 |  | Tier 1 Warrior H M: `set_tier1_warrior` / `set_tier1_warrior_orc_male` | Queued | Karl's pick replacement proposal: slot already has art |
| ☐ | A166 | P4 | `alliance-nightelf-female-hunter-tier2.jpg` 900x698 |  | Tier 2 Hunter A F: `set_tier2_hunter` / `set_tier2_hunter_nightelf_female` | Queued | Karl's pick replacement proposal: slot already has art |
| ☐ | A167 | P4 | `horde-tauren-male-shaman-tier2-2.png` 745x1040 |  | Tier 2 Shaman H M: `set_tier2_shaman` / `set_tier2_shaman_tauren_male` | Queued | Karl's pick, card scan, crop first replacement proposal: slot already has art |
| ☐ | A169 | P4 | `horde-orc-male-rogue-tier3.png` 745x1040 |  | Tier 3 Rogue H M: `tier3_rogue` / `tier3_rogue_orc_male` | Queued | Karl's pick, card scan, crop first replacement proposal: slot already has art |
| ☐ | A170 | P4 | `horde-tauren-female-shaman-tier3.jpg` 1000x775 |  | Tier 3 Shaman H F: `tier3_shaman` / `tier3_shaman_tauren_female` | Queued | Karl's pick replacement proposal: slot already has art |
| ☐ | A171 | P4 | `alliance-nightelf-female-druid-pvpset-leather.jpg` 900x787 |  | Field Marshal's Sanctuary (Druid) F: `None` / `pvp_field_marshal_s_sanctuary_druid_f` | Queued | Karl's pick replacement proposal: slot already has art |

## Skipped or blocked (Codex: do not touch)

Karl: find a larger copy of each low-res file, then `python tools/art-plan.py swap <id> <newfile>`.

| Id | State | Source image | Size | Slots |
|---|---|---|---|---|
| A002 | Skipped (low-res) | `weapon-blastershot-launcher.jpg` | 220x308 | Blastershot Launcher  |
| A008 | Skipped (low-res) | `weapon-crimson-shocker.jpg` | 220x308 | Crimson Shocker  |
| A011 | Skipped (low-res) | `item-draconian-deflector.jpg` | 200x279 | Draconian Deflector  |
| A013 | Skipped (low-res) | `weapon-dwarven-hand-cannon.jpg` | 200x279 | Dwarven Hand Cannon  |
| A020 | Skipped (low-res) | `weapon-the-shatterer.jpg` | 200x279 | The Shatterer  |
| A023 | Skipped (low-res) | `item-wall-of-the-dead.jpg` | 200x279 | Wall of the Dead  |
| A026 | Skipped (low-res) | `weapon-doomfinger-wand.jpg` | 348x310 | Doomfinger  |
| A039 | Blocked | `boss-hakkar.jpg` | 2500x3277 | Exalted: Zandalar Tribe (both) Today it borrows Clear Zul'Gurub. Weakest match: nothing in the folder pictures the tribe. Medium confidence. |
| A046 | Skipped (low-res) | `alliance-dwarf-female-rogue-tier1.jpg` | 312x440 | Level Classes to 60: Dwarf Rogue F  |
| A059 | Skipped (low-res) | `alliance-nightelf-male-druid-generic.jpg` | 200x279 | Level Classes to 60: Night Elf Druid M  |
| A074 | Skipped (low-res) | `horde-tauren-female-druid-leather-leveling-generic.jpg` | 312x440 | Level Classes to 60: Tauren Druid F  |
| A090 | Skipped (low-res) | `horde-undead-male-warlock-generic.jpg` | 220x308 | Level Classes to 60: Undead Warlock M  |
| A103 | Skipped (low-res) | `alliance-nightelf-male-hunter-tier2-2.jpg` | 312x440 | Tier 2 Hunter A M  |
| A126 | Skipped (low-res) | `alliance-human-male-paladin-dungeonset-2.jpg` | 220x308 | Dungeon Set 1 Paladin A  |
| A129 | Skipped (low-res) | `alliance-gnome-male-rogue-dungeonset-ashtongue-blade.jpg` | 312x440 | Dungeon Set 1 Rogue A; Dungeon Set 2 Rogue A  |
| A130 | Skipped (low-res) | `horde-orc-male-rogue-dungeonset.jpg` | 220x308 | Dungeon Set 1 Rogue H; Dungeon Set 2 Rogue H  |
| A135 | Skipped (low-res) | `horde-tauren-female-warrior-dungeonset.jpg` | 312x440 | Dungeon Set 1 Warrior H; Dungeon Set 2 Warrior H  |
| A140 | Skipped (low-res) | `alliance-human-male-paladin-dungeonset.jpg` | 220x308 | Dungeon Set 2 Paladin A  |
| A144 | Skipped (low-res) | `horde-orc-male-warlock-dungeonset-2.jpg` | 312x440 | Dungeon Set 2 Warlock H  |
| A153 | Skipped (low-res) | `alliance-nightelf-male-druid-pvpset-leather.jpg` | 200x285 | Field Marshal's Sanctuary (Druid) M PvP set ids are armorChildren of the pvp_set_* collections; find the child id in Core.lua. |
| A168 | Skipped (low-res) | `alliance-dwarf-male-rogue-tier3.jpg` | 220x308 | Tier 3 Rogue A M replacement proposal: slot already has art |
| A172 | Skipped (low-res) | `set-herod-the-scarlet-champion.jpg` | 312x440 | Chain of the Scarlet Crusade The set already has its own banner; this card is 312x440. |
| A173 | Blocked | `goal-gold-horde.jpg` | 1000x842 | Save 5,000 Gold (Horde) Renamed from Cutpurse_full.jpg; the gold goal is done with one shared image. |
| A174 | Blocked | `profession-tailoring-2.jpg` | 512x512 | Tailoring profession banner Profession banners are done; this would be an addition. |
| A175 | Skipped (low-res) | `horde-tauren-druid-cat-3.jpg` | 220x308 | Tauren Druid (sex not in name) No sex in the file name, and 220x308. |

## Slots with no source image

No picture in the folder fits these. They need new art or a source from Karl; nothing to do for Codex.

- G001: Cruel Barb
- G002: Gnome Rogue F
- G003: High Order Skyborne Warrior M
- G004: High Order Skyborne Warrior F
- G005: High Order Skyborne Hunter M
- G006: High Order Skyborne Hunter F
- G007: High Order Skyborne Mage M
- G008: High Order Skyborne Druid M
- G009: High Order Skyborne Druid F
- G010: Orc Hunter F
- G011: Troll Warrior F
- G012: Troll Shaman F
- G013: Windshaper Skyborne Warrior M
- G014: Windshaper Skyborne Warrior F
- G015: Windshaper Skyborne Hunter M
- G016: Windshaper Skyborne Hunter F
- G017: Windshaper Skyborne Shaman M
- G018: Windshaper Skyborne Shaman F
- G019: Windshaper Skyborne Druid M
- G020: Windshaper Skyborne Druid F
- G021: Tier 1 Hunter H F
- G022: Tier 1 Mage A M
- G023: Tier 1 Mage H M
- G024: Tier 1 Paladin A F
- G025: Tier 1 Paladin H F
- G026: Tier 1 Rogue H F
- G027: Tier 1 Shaman A F
- G028: Tier 1 Warlock A F
- G029: Tier 1 Warrior A F
- G030: Tier 2 Druid A F
- G031: Tier 2 Mage H F
- G032: Tier 2 Paladin A F
- G033: Tier 2 Paladin H F
- G034: Tier 2 Priest H F
- G035: Tier 2 Shaman A F
- G036: Tier 2 Warlock H F
- G037: Tier 2 Warrior H F
- G038: Tier 3 Hunter A F
- G039: Tier 3 Paladin H F
- G040: Tier 3 Shaman A M
- G041: Tier 3 Warlock A M
- G042: Tier 3 Warlock H M
- G043: Tier 3 Warrior A F
- G044: Tier 3 Warrior H F
- G045: Field Marshal's Battlegear (Warrior) M
- G046: Field Marshal's Earthshaker (Shaman) F
- G047: Field Marshal's Pursuit (Hunter) F
- G048: Warlord's Aegis (Paladin) F
- G049: Warlord's Pursuit (Hunter) F
- G050: Warlord's Raiment (Priest) M
- G051: Warlord's Regalia (Mage) M
- G052: Warlord's Vestments (Rogue) M
- G053: Warlord's Vestments (Rogue) F
- G054: Dungeon Set 1 Paladin H
- G055: Dungeon Set 2 Paladin H
- G056: Dungeon Set 1 Shaman A
- G057: Dungeon Set 2 Shaman A

## Corrections from Karl's review

- `alliance-human-female-paladin-tier1.jpg`: Karl, 2026-10-29: she wears the Paladin dungeon set, not Tier 1. The checklist already shows Lightforge Armor (set_dungeon1_paladin) with a female image, so this is probably its source. Never pick it for another slot.

## Source files that still need the naming convention

Not renamed. Karl renames these himself.

| Now | Proposed |
|---|---|
| `a-dwarf-male-paladin-generic-heal-4.png` | `alliance-dwarf-male-paladin-generic-heal-4.png` |
| `a-nightelf-female-priest-shadow.png` | `alliance-nightelf-female-priest-shadow.png` |
| `h-orc-female-shaman-tier1-hero.png` | `horde-orc-female-shaman-tier1-hero.png` |
| `h-orc-male-shaman-generic-leveling.png` | `horde-orc-male-shaman-generic-leveling.png` |
| `h-tauren-female-shaman-generic-leveling.png` | `horde-tauren-female-shaman-generic-leveling.png` |
| `h-undead-female-rogue-generic-leveling.png` | `horde-undead-female-rogue-generic-leveling-2.png` |
| `weapon-Argent_Crusader.jpg` | `weapon-argent-crusader.jpg` |
| `weapon-Barman_Shanker.jpg` | `weapon-barman-shanker.jpg` |
| `weapon-Benediction.png` | `weapon-benediction-2.png` |
| `weapon-Crackling_Staff.jpg` | `weapon-crackling-staff-2.jpg` |
| `weapon-Gurubashi_Dwarf_Destroyer.jpg` | `weapon-gurubashi-dwarf-destroyer.jpg` |
| `weapon-Hypnotic_Blade.jpg` | `weapon-hypnotic-blade.jpg` |
| `weapon-Masterwork_Stormhammer.png` | `weapon-masterwork-stormhammer.png` |
| `weapon-The_Bringer_of_Death.png` | `weapon-the-bringer-of-death.png` |
| `weapon-The_Unstoppable_Force_2.jpg` | `weapon-the-unstoppable-force-2.jpg` |
| `weapon-claw-frost-wyrm.jpg` | `weapon-claw-of-the-frost-wyrm.jpg` |
| `weapon-doomfinger-wand.jpg` | `weapon-doomfinger.jpg` |
| `weapon-hand-edward-odd.png` | `weapon-hand-of-edward-the-odd.png` |
| `weapon-skuls-ghastly-touch-wand.png` | `weapon-skuls-ghastly-touch.png` |
| `weapon-staff-of-command.jpg` | `weapon-lord-valthalaks-staff-of-command.jpg` |

## Idea: leveling art that follows the character's level

Karl's idea: the Level Classes to 60 banner shows the character in three looks (levels 1 to 20, 21 to 40, 41 to 60). Not started. Of 92 race, class and sex slots, the folder has art for stage 1 on 73, stage 2 on 26, stage 3 on 58, and all three on 16. The resolver change is small (a `stage` field scored below faction); the cost is the art and about 30 to 59 MB of banners. Decide after Nov 4.
