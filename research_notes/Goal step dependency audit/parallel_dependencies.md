# Progression, parallel goals and mounts: dependency audit

## Which current steps should receive dependency locks?

### Takeaway
Research date: October 8, 2026. Covers 34 exact goal IDs and every step/part below. Most are independent milestones, not blocked actions. Do not chain ascending numbers simply because a larger value implies a smaller value. The clearest candidates are reward purchase/turn-in actions after actual eligibility, with substantial Classic/Forever caveats.

### Cited Findings
Code catalogue and rule semantics are from [Data.lua](../../../Data.lua), [Library.lua](../../../Library.lua), and [Core.lua](../../../Core.lua), read from the current checkout. Source addresses below use `goal.steps[n]`, or `goal.sections[s].pieces[p]`; punctuation is preserved in flat steps. Display text removes terminal periods at runtime. These are audit addresses, not proposed SavedVariables keys.

#### Reputation: 9 IDs, all rows unlocked
Each of `rep_timbermaw` (faction 576), `rep_thorium` (59), `rep_argentdawn` (529), `rep_cenarion` (609), `rep_zandalar` (270), `rep_hydraxian` (749), `rep_nozdormu` (910) expands exactly to:

| Address | Exact step | Decision |
|---|---|---|
| steps[1] | Reach Friendly. | No lock |
| steps[2] | Reach Honored. | No lock; logically exceeds 1 but earning rep is already available |
| steps[3] | Reach Revered. | No lock; logically exceeds 1–2 |
| steps[4] | Reach Exalted. | No lock; logically exceeds 1–3 |

`rep_ambassador_ally`: steps[1] `Reach Exalted with Stormwind.`; [2] `Reach Exalted with Ironforge.`; [3] `Reach Exalted with Darnassus.`; [4] `Reach Exalted with Gnomeregan Exiles.` ALL independent, Alliance scope. `rep_ambassador_horde`: [1] `Reach Exalted with Orgrimmar.`; [2] `Reach Exalted with Thunder Bluff.`; [3] `Reach Exalted with Undercity.`; [4] `Reach Exalted with the Darkspear Trolls.` ALL independent, Horde scope. Each city may be completed by a different roster character; never require one capital before another. High confidence in no UI lock from [RepSteps/ambassador definitions](../../../Library.lua).

#### Professions and classes: 3 IDs, all rows unlocked
`prof_secondary`: steps[1] `Fishing 300.`; [2] `Cooking 300.`; [3] `First Aid 300.`

`prof_all`: steps[1] `Alchemy 300.`; [2] `Blacksmithing 300.`; [3] `Enchanting 300.`; [4] `Engineering 300.`; [5] `Herbalism 300.`; [6] `Leatherworking 300.`; [7] `Mining 300.`; [8] `Skinning 300.`; [9] `Tailoring 300.`

`allclasses`: steps[1] `Warrior`; [2] `Paladin`; [3] `Hunter`; [4] `Rogue`; [5] `Priest`; [6] `Shaman`; [7] `Mage`; [8] `Warlock`; [9] `Druid`. `autoLevels` draws continuous level/XP progress to 60; these are not manual checklist locks. All class/profession rows can be worked on concurrently across the roster. Profession pairs are helpful combinations, never dependencies. High confidence from [SkillStep and goals](../../../Library.lua), [autoLevels](../../../Data.lua), [progress/rules](../../../Core.lua).

#### Adjustable milestones and social: 5 IDs
`gold_5k`: steps[1] `Hold 1,000 gold on one character.`; [2] `Hold 2,500 gold on one character.`; [3] `Hold 5,000 gold on one character.` ALL no locks. Editable target T expands marks .2, .5, 1; text `Hold %s gold on one character.`. Save-once historical ticks persist after spending. Current money alone is not historical completion evidence for past savings. High confidence from [ApplyTargets/RuleMet](../../../Core.lua).

`social_friends`: steps[1] `Have 5 friends on your friends list.`; [2] `Have 10 friends on your friends list.`; [3] `Have 25 friends on your friends list.` ALL no locks. Target T marks .2, .4, 1; text `Have %s friends on your friends list.`. Lists can shrink; previously earned ticks remain. High confidence from [definitions](../../../Library.lua) and [rules](../../../Core.lua).

`pvp_hk`: steps[1] `Earn 1,000 honorable kills.`; [2] `Earn 5,000 honorable kills.`; [3] `Earn 10,000 honorable kills.`; [4] `Earn 25,000 honorable kills.` ALL no locks. T marks .04, .2, .4, 1; text `Earn %s honorable kills.`. Each threshold is one character's lifetime total, not summed roster HK. [Definition and rules](../../../Library.lua).

`pvp_duelist`: steps[1] `Win your first duel.`; [2] `Win 10 duels.`; [3] `Win 50 duels.`; [4] `Win 100 duels.` ALL no locks. T marks .01, .1, .5, 1 with first row always 1; text `Win %s duels.` and singular `Win your first duel.`. Forever-only stat 319, highest stored per-character counter. No prerequisite duel quest exists in current guide. [Definitions](../../../Library.lua), [statistics recording](../../../Core.lua).

For all adjustable goals, `Nice(v)` rounds below 100 to nearest integer with minimum 1, otherwise rounds to two significant figures; final mark uses exact T. Marks may duplicate at low targets; no dependency chain should be introduced between duplicate rows. [ApplyTargets](../../../Core.lua).

`social_guild`: steps[1] `Join a guild.` (independent); [2] `Buy a Guild Tabard from a Guild Master in a capital city.` (candidate 1 → 2, medium confidence). Blizzard's original manual describes guild creation/design making the tabard available for members to purchase; Wowhead lists capital vendors. Membership AND the guild having designed its tabard are conditions, while the code tracks only historical guild membership and item ownership. Recommend defer hard lock until current Forever vendor purchase behavior confirmed; it is buying, not wearing. [Blizzard manual](https://assets.blz-contentstack.com/v3/assets/blt3452e3b114fab0cd/blt2e9295db02a222fc/6025bcbb6968b53d529edb2a/media_manual_classic_enUS.pdf), [Guild Tabard item](https://www.wowhead.com/classic/item=5976/guild-tabard), [goal code](../../../Library.lua).

#### PvP standing/ranks and purchased mounts: 12 IDs
`pvp_wsg_ally` (890 Silverwing Sentinels), `pvp_wsg_horde` (889 Warsong Outriders), `pvp_ab_ally` (509 League of Arathor), `pvp_ab_horde` (510 The Defilers), `pvp_av_ally` (730 Stormpike Guard), `pvp_av_horde` (729 Frostwolf Clan): each expands steps[1] `Reach Friendly.`; [2] `Reach Honored.`; [3] `Reach Revered.`; [4] `Reach Exalted.`. Every row no lock. Faction-scoped; rep farming can proceed immediately. [RepGoal definition](../../../Library.lua).

`pvp_rank14_ally`: steps[1] `Reach Rank 6, Knight.`; [2] `Reach Rank 10, Lieutenant Commander.`; [3] `Reach Rank 12, Marshal.`; [4] `Reach Rank 13, Field Marshal.`; [5] `Reach Rank 14, Grand Marshal.`; [6] `Buy your rank 14 weapon from the PvP quartermaster.`

`pvp_rank14_horde`: steps[1] `Reach Rank 6, Stone Guard.`; [2] `Reach Rank 10, Champion.`; [3] `Reach Rank 12, General.`; [4] `Reach Rank 13, Warlord.`; [5] `Reach Rank 14, High Warlord.`; [6] same exact buy text. Rows 1–5: no locks; row 6 candidate 5 → 6 ONLY where the client vendor actually requires rank 14 (Classic intended rule, medium confidence; Forever unconfirmed). The last row is manual, lacks weapon ID/autodetection. A rank on another character is not purchaser eligibility; goal's historical/current rank is any eligible roster character. [RankStep/goals](../../../Library.lua). Wowhead rank-weapon items list vendor locations but parsed infobox did not expose vendor rank eligibility; old comments include later-expansion honor purchases and must not be treated as current rules. [Grand Marshal's Hand Cannon](https://www.wowhead.com/classic/item=18855/grand-marshals-hand-cannon).

`pvp_mount_ally`: steps[1] `Reach Rank 11, Commander.`; [2] `Buy a war mount from your faction's PvP quartermaster.`
`pvp_mount_horde`: steps[1] `Reach Rank 11, Lieutenant General.`; [2] same exact buy text. Candidate 1 → 2, medium confidence for Classic intent; HOLD on Forever until rank purchase eligibility confirmed. Reward names OR: Alliance Black War Steed / Black War Tiger / Black War Ram / Black Battlestrider; Horde Black War Wolf / Black War Raptor / Black War Kodo / Red Skeletal Warhorse. Ownership OR evidence supersedes locks and completes entire goal. Do not add city rep/racial riding dependencies from other goals merely to purchase: using and purchasing are distinct. [Goal code](../../../Library.lua), [Classic Black War Steed Bridle](https://www.wowhead.com/classic/item=18241/black-war-steed-bridle).

`pvp_avmount_ally`: steps[1] `Reach Exalted with the {pvp_av_ally:Stormpike Guard}.`; [2] `Buy the Stormpike Battle Charger from Thanthaldis Snowgleam in the Alterac Mountains.`
`pvp_avmount_horde`: steps[1] `Reach Exalted with the {pvp_av_horde:Frostwolf Clan}.`; [2] `Buy the Frostwolf Howler from Jekyll Flandring in the Alterac Mountains.` Candidate 1 → 2; no dependency on completing whole separate `pvp_av_*` goal. Classic Exalted purchase condition medium/high confidence, Forever medium until vendor confirmed. Item 19030/19029 OR owned name is proof and completes goal. Exalted must belong to purchaser, not another roster character. No Rank 3 gate (that is a discount), no Ironforge rep gate. [Classic item](https://www.wowhead.com/classic/item=19030/stormpike-battle-charger), [Forever item](https://www.wowhead.com/forever/item=19030/stormpike-battle-charger), [goal definitions](../../../Library.lua). Parsed item data establishes level 60 for USE; comments/guide establish purchase eligibility, so document this source limitation explicitly.

#### Drop/event mounts: 4 IDs
`mount_deathcharger`: steps[1] `Reach level 60.` (no lock); [2] `Defeat Baron Rivendare in {key_strat:Stratholme}.` (no dependency on 1; preparation level is not kill eligibility); [3] `Loot Deathcharger's Reins from Baron Rivendare.` (candidate 2 → 3, high confidence logical corpse-loot sequence). Ownership proof OR item 13335 completes goal even if kill was never seen. Do not require possession of Key to the City or `key_strat` goal: a group member can open a door. [Current source](../../../Library.lua), [Classic item](https://www.wowhead.com/classic/item=13335/deathchargers-reins). Scope: killing/looting character normally same encounter, but addon tracks any roster kill and any roster item. Warning: a loot step should not be forcibly locked solely because the boss kill event was missed.

`mount_raptor`: steps[1] `Defeat Bloodlord Mandokir in {raid_zg:Zul'Gurub}.` (independent); [2] `Loot the Swift Razzashi Raptor from Bloodlord Mandokir.` (candidate 1 → 2, logical drop sequence; item 19872/owned proof overrides). `mount_tiger`: steps[1] `Defeat High Priest Thekal in {raid_zg:Zul'Gurub}.` (independent); [2] `Loot the Swift Zulian Tiger from High Priest Thekal.` (candidate 1 → 2; item 19902/owned proof overrides). Neither requires full raid goal completion. High confidence in data-defined sequence; sources [current catalogue](../../../Library.lua), [raptor item](https://www.wowhead.com/classic/item=19872/swift-razzashi-raptor), [tiger item](https://www.wowhead.com/classic/item=19902/swift-zulian-tiger). Both item pages were fetched independently; parsed text supports drop source through player comments, but did not expose a structured drop table, so confidence in the strict current-build loot route remains medium until that is confirmed.

`mount_qiraji`: steps[1] `Complete the Scepter of the Shifting Sands quest chain.` (independent); [2] `Ring the Scarab Gong in Silithus to open Ahn'Qiraj.` (1 → 2 plus external realm event availability); [3] `Own the Black Qiraji Resonating Crystal.` (2 → 3 for the original quest route, item 21176/owned proof overrides). Classic quest explicitly requires Scepter and rewards crystal: high confidence in classic route. Forever event/unlock window unconfirmed; HOLD hard locks on Forever. Current step 2 oversimplifies ringing after another player opens gates; do not claim only the first ring qualifies. [Bang a Gong! objective/reward](https://www.wowhead.com/classic/quest=8743/bang-a-gong), [current goal](../../../Library.lua).

#### Epic racial mounts: 1 ID, 9 generated sections (44 pieces)
Exact lossless expansion of `epicmounts.sections[s].pieces[p]`, sections 1–8:

1. `Level a {Side} character to level 60`
2. `Reach Exalted with {RepName} (optional for {RacePlural})`
3. `Train {RidingLabel} Riding from your riding trainer`
4. `Save about 800-1,000 gold on that character`
5. `Buy {Article}{Mount} from {Vendor} ({Location})`

`RidingLabel` is `Journeyman` on Forever; `Expert` on Classic Era. `Article` is `a ` if multiple variant item IDs, `the ` otherwise. Every listed section has multiple IDs, including Undead's two, so every generated classic section buy step starts `Buy a `.

| s | Side | RepName | RacePlural / skipIfRace | Mount | Vendor | Location |
|---|---|---|---|---|---|---|
| 1 | Alliance | Stormwind | Humans / Human | Swift Steed | Katie Hunter | Eastvale Logging Camp, Elwynn Forest |
| 2 | Alliance | Ironforge | Dwarves / Dwarf | Swift Ram | Veron Amberstill | Amberstill Ranch, Dun Morogh |
| 3 | Alliance | Darnassus | Night Elves / NightElf | Swift Saber | Lelanai | Cenarion Enclave, Darnassus |
| 4 | Alliance | Gnomeregan Exiles | Gnomes / Gnome | Swift Mechanostrider | Milli Featherwhistle | Kharanos, Dun Morogh |
| 5 | Horde | Orgrimmar | Orcs / Orc | Swift Wolf | Ogunaro Wolfrunner | Valley of Honor, Orgrimmar |
| 6 | Horde | Thunder Bluff | Tauren / Tauren | Great Kodo | Harb Clawhoof | Bloodhoof Village, Mulgore |
| 7 | Horde | Undercity | Undead / Scourge | Skeletal Warhorse | Zachariah Post | Brill, Tirisfal Glades |
| 8 | Horde | the Darkspear Trolls | Trolls / Troll | Swift Raptor | Zjolnir | Sen'jin Village, Durotar |

Lossless purchase auto-rule OR alternatives from [Data.lua](../../../Data.lua): s1 item18777 Swift Brown Steed OR18776 Swift Palomino OR18778 Swift White Steed; `ownedPattern` `Swift .*Steed` OR `Swift Palomino`. s2 item18786 Swift Brown Ram OR18787 Swift Gray Ram OR18785 Swift White Ram; pattern `Swift .*Ram`. s3 item18766 Reins of the Swift Frostsaber OR18767 Reins of the Swift Mistsaber OR18902 Reins of the Swift Stormsaber; patterns `Swift Frostsaber` OR `Swift Mistsaber` OR `Swift Stormsaber`. s4 item18772 Swift Green Mechanostrider OR18773 Swift White Mechanostrider OR18774 Swift Yellow Mechanostrider; pattern `Swift .*Mechanostrider`. s5 item18797 Horn of the Swift Timber Wolf OR18796 Horn of the Swift Brown Wolf OR18798 Horn of the Swift Gray Wolf; pattern `Swift .*Wolf`. s6 item18794 Great Brown Kodo OR18795 Great Gray Kodo OR18793 Great White Kodo; pattern `Great .*Kodo`. s7 item18791 Purple Skeletal Warhorse OR13334 Green Skeletal Warhorse; pattern `Skeletal Warhorse`. s8 item18788 Swift Blue Raptor OR18789 Swift Olive Raptor OR18790 Swift Orange Raptor; pattern `Swift .*Raptor`. Any item OR any matching owned name suffices; no dependency on collecting all colors.

Each of these 40 pieces is individually classified: p1 no lock (leveling independent); p2 no lock (reputation independent and hidden/skipped on native race); p3 no hard lock pending client-specific riding facts; p4 no lock (money gathering parallel); p5 potential purchase-eligibility gate p2 OR native race, but HOLD blanket locks because item is Bind on Use on Classic, purchase/transfer/use distinctions and race exceptions matter. Do NOT gate p5 on p4's manually ticked estimate. Riding consumes money so requiring the full pre-training budget afterward creates a false blocker. Level 60 and riding requirements on item data are use requirements, not automatically purchase requirements. [BuildMountTasks](../../../Data.lua), [Classic Mechanostrider item](https://www.wowhead.com/classic/item=18774/swift-yellow-mechanostrider), [Classic riding guide](https://www.wowhead.com/classic/guide/wow-classic-mounts-riding-skill).

Classic mismatch to flag separately, not silently fix during dependency work: guide says racial riding skills, no additional epic-speed training, and race exclusions (Mechanostrider only Dwarf/Gnome; Tauren excluded from some racial mounts). Existing generic `Expert Riding`/rank150 and faction-wide any-race assumptions should not be copied into hard locks on Classic. Forever rules may differ, so don't regress Karl's in-game-approved faction-wide Forever behavior based on Classic rules. The guide-derived summary here stays below its 200-word source allowance.

`epicmounts.sections[9]` Skyborne, hidden on Classic Era, exact pieces:
1. `Level a Skyborne character to level 60` — no lock.
2. `Train Journeyman Riding from your riding trainer` — candidate 1 → 2 only if trainer confirms level60; not verified by spell data (passive Galestrider Riding spell itself says level1), HOLD.
3. `Save about 1,200 gold on that character` — no lock, can happen before level/training; historical budget estimate, never required at purchase time.
4. `Buy a Swift Galestrider from Genn Fairweather (Zephras Isle)` — no blanket lock yet; item use requires level60 AND Galestrider Riding, but buying eligibility not demonstrated. Existing source says 1,000g training +200g mount. No cross-race/capital rep gate can be inferred. All four current auto rules are race Skyborne scoped; riding shared label is generic, so avoid shared-string dependencies across factions/races. [Builder/source](../../../Data.lua), [Forever item: account-wide, level60, Galestrider Riding](https://www.wowhead.com/forever/item=269671/swift-empyrean-galestrider), [Galestrider Riding passive spell](https://www.wowhead.com/forever/spell=1285849/galestrider-riding), [official Skyborne introduction](https://news.blizzard.com/en-us/article/24302071/wow-forever-meet-the-new-skyborne).

Skyborne p4 OR item variants:269671 Swift Empyrean Galestrider,274933 Swift Umber Galestrider,269678 Swift Stormy Galestrider; OR owned pattern `Swift .*Galestrider`. The item pages mark account-wide mount, while existing auto rule restricts observed character to Skyborne; do not invent cross-race hard locks based on the current detector. [Source](../../../Data.lua), [Forever item](https://www.wowhead.com/forever/item=269671/swift-empyrean-galestrider).

### Inferences
- Default no locks for every rep/profession/class/statistics/money/friend milestone. Dependencies on logical implication add no gameplay benefit and can block legitimate manual historical completion.
- Real AND gates should be evaluated on the SAME eligible character; `exists character A with level60` AND `exists B with Exalted` is not `exists character with both`. Today's any-roster goal ticks cannot prove same-character eligibility.
- Native race OR Exalted applies to mount eligibility. Hidden p2 must never count as unmet. Current `PieceSkipped` uses logged-in race, not every stored character; avoid attaching dependency to an invisible row.
- Faction/race scopes remain exact. Shared `level60`/`riding` strings are display/progress sharing keys, not universal prerequisite identities. Do not require deselected mount sections, opposite faction parts, a whole Ambassador goal, or another class's progress.
- Existing ownership/completion detection always wins; completed rows never relock. New lock jiggles retain lock color, missing prerequisite tooltip muted red, unlocked lock breaks away. One prerequisite can release multiple reward steps; do not implement a linear index chain.
- Reputation/rank purchase prerequisites are eligibility advice if current state cannot be proved; hard gates should wait on external/source/in-game confirmation, especially after the new beta build.

### Gaps
- No reliable primary source in this pass confirms new-build Forever racial purchase/training price/level/reputation exceptions, rank11/rank14 vendor eligibility, or Scarab Gong event timing. Existing data comments are historical implementation evidence, not verification of the incoming build.
- Parsed Classic rank reward pages include incompatible TBC/retail comments and lack visible vendor rank fields. Do not use their honor-point comments to alter Classic or Forever locks.
- Drop pages for Swift Razzashi Raptor and Swift Zulian Tiger were fetched, but parsed output exposed historical comments rather than a structured drop table; source-defined kill→loot suggestions require structured source verification or in-game evidence before hard implementation.
- Guild purchase versus equip restriction and guild tabard design prerequisites need current-client confirmation. The goal step is buy, so do not turn equip requirements into a purchase lock.
- Trainer level requirement cannot be concluded from Galestrider Riding's level1 dummy passive. Need the actual Journeyman trainer purchase dialog or trainer ability data.

