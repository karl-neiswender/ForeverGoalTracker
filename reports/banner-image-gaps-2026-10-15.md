# Background image coverage — October 15, 2026

Follow-up: Karl authorized both wiring fixes after this audit. Alliance Warrior
Tier 3 now selects the existing Dwarf image; Horde retains Koringar. Beastmaster
now selects its dedicated texture after the collection-wide fallback assignment.
All other Dungeon Set 2 classes retain their shared image. Full Era/Forever
checks passed, including both factions and every Dungeon Set 2 class;
evidence: `checks/warrior-beastmaster-art-fix-2026-10-15.txt`.
The inventory and JSON below retain the pre-fix audit snapshot.

Audit source: `f5303fe190603b9a11d44a25331d6639a0a11e67`. Real runtime resolver loaded under Lua 5.1/WoW stubs
for Era and Forever, including independent class-set goals accessed through their
collection pickers. Synthetic faction/race/class contexts test artwork routing;
this does not verify in-game rendering or every legal race/class combination.

Only **Say LOL** has no background. The two profession group goals are conditional:
art is selected from learned skills. All registered image files exist.

Legend: 🟢 image available; 🟦 same image shared across factions;
🟡 generic/other-goal fallback; 🔴 no image; ⚪ conditional/not applicable.
Shared artwork is coverage, not a blank goal or a mandatory replacement.

Remaining dedicated-art candidates:

| Goal/group | Alliance | Horde |
|---|---|---|
| Say LOL | 🔴 None | 🔴 None |
| PvP leather | 🟢 Moonshadow | 🟡 Warrior Tier 2 fallback |
| AQ cloth: Enigma, Oracle, Doomcaller | 🟡 Generic AQ background | 🟡 Generic AQ background |
| AQ mail: Stormcaller | 🟡 Generic AQ background | 🟡 Generic AQ background |
| Dungeon Set 1: Shadowcraft, Magister, Wildheart | 🟡 Dungeon Set 2 background | 🟡 Dungeon Set 2 background |
| Dungeon Set 1: Devout | 🟡 Stratholme key background | 🟡 Stratholme key background |
| Dungeon Set 2: all nine classes | 🟡 Shared dungeon scene | 🟡 Shared dungeon scene |
| Forever Hyjal sets: all nine classes | 🟡 Shared raid-set scene | 🟡 Shared raid-set scene |

Beastmaster has a dedicated `set_dungeon2_hunter-banner.blp` texture, but the
following collection-wide assignment in Core.lua overwrites its path. The live
resolver returns `set_dungeon2-banner.blp` for that goal. Audit only: no fix made.

Separate faction versions currently exist for Tier 1 Rogue/Warlock, Tier 2
Warrior/Hunter/Warlock/Druid, and Tier 3 Warlock. Other Tier 1–3 class goals use
one class illustration on both factions. Notably Warrior Tier 3 now uses Koringar
(the tauren) on both factions; Priest Tier 1–3 use their Alliance illustrations
on Horde too. These are optional faction-art gaps, separate from blank images.

AQ plate uses Savin for both classes/factions; leather uses Telrander; Hunter
uses Azarak. PvP plate/mail/cloth have faction artwork, Alliance leather has
Moonshadow, and Horde leather still uses the Warrior fallback. Epic racial
mounts cover all nine listed races; city Ambassador variants are installed.

The full table below lists all 166 independent/current Forever goals. Library-only
collection wrappers are excluded. Era has 133 goals under the same audit.
Exact per-context data: `image-tests/banner-coverage-2026-10-15.json`.
Reproduce: `image-tests/audit-banner-coverage-2026-10-15.py`.

## Full inventory

| Goal | Alliance | Horde |
|---|---|---|
| Attunement: Blackwing Lair | 🟦 `raid_bwl-banner.blp` | 🟦 `raid_bwl-banner.blp` |
| Attunement: Molten Core | 🟦 `att_mc-banner.blp` | 🟦 `att_mc-banner.blp` |
| Attunement: Naxxramas | 🟦 `att_naxx-banner.blp` | 🟦 `att_naxx-banner.blp` |
| Attunement: Onyxia's Lair (Alliance) | 🟢 `att_ony_ally-banner.blp` | ⚪ — |
| Attunement: Onyxia's Lair (Horde) | ⚪ — | 🟢 `att_ony_horde-banner.blp` |
| Key: Crescent Key (Dire Maul) | 🟦 `key_dm-banner.blp` | 🟦 `key_dm-banner.blp` |
| Key: Key to the City (Stratholme) | 🟦 `key_strat-banner.blp` | 🟦 `key_strat-banner.blp` |
| Key: Seal of Ascension (Upper Blackrock Spire) | 🟦 `key_ubrs-banner.blp` | 🟦 `key_ubrs-banner.blp` |
| Key: Shadowforge Key (Blackrock Depths) | 🟦 `key_ubrs-banner.blp` | 🟦 `key_ubrs-banner.blp` |
| Key: Skeleton Key (Scholomance) | 🟦 `key_scholo-banner.blp` | 🟦 `key_scholo-banner.blp` |
| Benediction / Anathema | 🟢 `benediction-alliance-banner.blp` | 🟢 `benediction-banner.blp` |
| Corrupted Ashbringer | 🟦 `ashbringer-banner.blp` | 🟦 `ashbringer-banner.blp` |
| Lok'delar, Stave of the Ancient Keepers | 🟦 `lokdelar-banner.blp` | 🟦 `lokdelar-banner.blp` |
| Quel'Serrar | 🟦 `quelserrar-banner.blp` | 🟦 `quelserrar-banner.blp` |
| Rhok'delar, Longbow of the Ancient Keepers | 🟦 `rhokdelar-banner.blp` | 🟦 `rhokdelar-banner.blp` |
| Zin'rokh, Destroyer of Worlds | 🟦 `zinrokh-banner.blp` | 🟦 `zinrokh-banner.blp` |
| Arcanist Regalia | 🟦 `set_tier1_mage-banner.blp` | 🟦 `set_tier1_mage-banner.blp` |
| Avenger's Battlegear | 🟦 `set_tier25_plate-banner.blp` | 🟦 `set_tier25_plate-banner.blp` |
| Battlegear of Glory | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Battlegear of Heroism | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Battlegear of Might | 🟦 `set_tier1_warrior-banner.blp` | 🟦 `set_tier1_warrior-banner.blp` |
| Battlegear of Valor | 🟦 `set_dungeon1_warrior-banner.blp` | 🟦 `set_dungeon1_warrior-banner.blp` |
| Battlegear of Wrath | 🟢 `set_tier2_warrior-alliance-banner.blp` | 🟢 `set_tier2_warrior-banner.blp` |
| Beastmaster Armor | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Beaststalker Armor | 🟦 `set_dungeon1_hunter-banner.blp` | 🟦 `set_dungeon1_hunter-banner.blp` |
| Bloodfang Armor | 🟦 `set_tier2_rogue-banner.blp` | 🟦 `set_tier2_rogue-banner.blp` |
| Bonescythe Armor | 🟦 `tier3_rogue-banner.blp` | 🟦 `tier3_rogue-banner.blp` |
| Cenarion Raiment | 🟦 `set_tier1_druid-banner.blp` | 🟦 `set_tier1_druid-banner.blp` |
| Conqueror's Battlegear | 🟦 `set_tier25_plate-banner.blp` | 🟦 `set_tier25_plate-banner.blp` |
| Cryptstalker Armor | 🟦 `tier3_hunter-banner.blp` | 🟦 `tier3_hunter-banner.blp` |
| Darkmantle Armor | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Deathdealer's Embrace | 🟦 `set_tier25_leather-banner.blp` | 🟦 `set_tier25_leather-banner.blp` |
| Deathmist Raiment | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Demonheart Raiment | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Doomcaller's Attire | 🟡 `set_tier25-banner.blp` | 🟡 `set_tier25-banner.blp` |
| Dragonstalker Armor | 🟢 `set_tier2_hunter-alliance-banner.blp` | 🟢 `set_tier2_hunter-banner.blp` |
| Dreadmist Raiment | 🟦 `set_dungeon1_warlock-banner.blp` | 🟦 `set_dungeon1_warlock-banner.blp` |
| Dreadnaught's Battlegear | 🟦 `tier3_warrior_koringar-banner.blp` | 🟦 `tier3_warrior_koringar-banner.blp` |
| Dreamwalker Raiment | 🟦 `tier3_druid-banner.blp` | 🟦 `tier3_druid-banner.blp` |
| Embrace of the Viper | 🟦 `set_viper-banner.blp` | 🟦 `set_viper-banner.blp` |
| Enigma Vestments | 🟡 `set_tier25-banner.blp` | 🟡 `set_tier25-banner.blp` |
| Felheart Raiment | 🟢 `set_tier1_warlock-alliance-banner.blp` | 🟢 `set_tier1_warlock-banner.blp` |
| Feralheart Raiment | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Frostfire Regalia | 🟦 `tier3_mage-banner.blp` | 🟦 `tier3_mage-banner.blp` |
| Garments of the Oracle | 🟡 `set_tier25-banner.blp` | 🟡 `set_tier25-banner.blp` |
| Genesis Raiment | 🟦 `set_tier25_leather-banner.blp` | 🟦 `set_tier25_leather-banner.blp` |
| Giantstalker Armor | 🟦 `set_tier1_hunter-banner.blp` | 🟦 `set_tier1_hunter-banner.blp` |
| Grimstitch Armor | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Grovekeeper Raiment | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Judgement Armor | 🟦 `set_tier2_paladin-banner.blp` | 🟦 `set_tier2_paladin-banner.blp` |
| Justice Armor | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Lawbringer Armor | 🟦 `set_tier1_paladin-banner.blp` | 🟦 `set_tier1_paladin-banner.blp` |
| Lightforge Armor | 🟦 `set_dungeon1_paladin-banner.blp` | 🟦 `set_dungeon1_paladin-banner.blp` |
| Magister's Regalia | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Manaflare Regalia | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Nemesis Raiment | 🟢 `set_tier2_warlock-alliance-banner.blp` | 🟢 `set_tier2_warlock-banner.blp` |
| Netherwind Regalia | 🟦 `set_tier2_mage-banner.blp` | 🟦 `set_tier2_mage-banner.blp` |
| Nightslayer Armor | 🟢 `set_tier1_rogue-alliance-banner.blp` | 🟢 `set_tier1_rogue-banner.blp` |
| Partners in Crime | 🟦 `set_partners_in_crime-banner.blp` | 🟦 `set_partners_in_crime-banner.blp` |
| Plagueheart Raiment | 🟢 `tier3_warlock-alliance-banner.blp` | 🟢 `tier3_warlock-horde-banner.blp` |
| Redemption Armor | 🟦 `tier3_paladin-banner.blp` | 🟦 `tier3_paladin-banner.blp` |
| Shadowcraft Armor | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Sorcerer's Regalia | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Soulforge Armor | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Stormcaller's Garb | 🟡 `set_tier25-banner.blp` | 🟡 `set_tier25-banner.blp` |
| Stormrage Raiment | 🟢 `set_tier2_druid-banner.blp` | 🟢 `set_tier2_druid-horde-banner.blp` |
| Striker's Garb | 🟦 `set_tier25_hunter-banner.blp` | 🟦 `set_tier25_hunter-banner.blp` |
| The Earthfury | 🟦 `set_tier1_shaman-banner.blp` | 🟦 `set_tier1_shaman-banner.blp` |
| The Earthshatterer | 🟦 `tier3_shaman-banner.blp` | 🟦 `tier3_shaman-banner.blp` |
| The Elements | 🟦 `set_dungeon1_shaman-banner.blp` | 🟦 `set_dungeon1_shaman-banner.blp` |
| The Five Thunders | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| The Spiritcaller | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| The Ten Storms | 🟦 `set_tier2_shaman-banner.blp` | 🟦 `set_tier2_shaman-banner.blp` |
| Vestments of Conviction | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Vestments of Faith | 🟦 `tier3_priest-banner.blp` | 🟦 `tier3_priest-banner.blp` |
| Vestments of Prophecy | 🟦 `set_tier1_priest-banner.blp` | 🟦 `set_tier1_priest-banner.blp` |
| Vestments of Transcendence | 🟦 `set_tier2_priest-banner.blp` | 🟦 `set_tier2_priest-banner.blp` |
| Vestments of the Devout | 🟡 `key_strat-banner.blp` | 🟡 `key_strat-banner.blp` |
| Vestments of the Virtuous | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Violet Sorcerer's Vestments | 🟦 `set_violet_sorcerer-banner.blp` | 🟦 `set_violet_sorcerer-banner.blp` |
| Wildheart Raiment | 🟡 `set_dungeon2-banner.blp` | 🟡 `set_dungeon2-banner.blp` |
| Wildstalker Armor | 🟡 `set_forever_raid-banner.blp` | 🟡 `set_forever_raid-banner.blp` |
| Atiesh, Greatstaff of the Guardian | 🟦 `atiesh-banner.blp` | 🟦 `atiesh-banner.blp` |
| Sulfuras, Hand of Ragnaros | 🟦 `sulfuras-banner.blp` | 🟦 `sulfuras-banner.blp` |
| Thunderfury, Blessed Blade of the Windseeker | 🟦 `thunderfury-banner.blp` | 🟦 `thunderfury-banner.blp` |
| Level Classes to 60 | 🟢 `allclasses_alliance_warlock-banner.blp`, `allclasses_dwarf_hunter-banner.blp`, `allclasses_dwarf_paladin-banner.blp`, `allclasses_dwarf_shaman-banner.blp`, `allclasses_nightelf_hunter-banner.blp`, `benediction-alliance-banner.blp`, `pvp_shared-banner.blp`, `rhokdelar-banner.blp`, `set_tier1_mage-banner.blp`, `set_tier1_priest-banner.blp`, `set_tier2_druid-banner.blp`, `set_tier2_paladin-banner.blp`, `set_tier2_priest-banner.blp`, `set_tier2_warrior-alliance-banner.blp`, `tier3_warrior-banner.blp` | 🟢 `allclasses_horde_druid-banner.blp`, `allclasses_horde_hunter-banner.blp`, `allclasses_tauren_warrior-banner.blp`, `allclasses_troll_mage-banner.blp`, `allclasses_undead_paladin-banner.blp`, `pvp_shared-banner.blp`, `set_tier1_shaman-banner.blp`, `set_tier1_warlock-banner.blp`, `set_tier2_shaman-banner.blp`, `set_tier2_warrior-banner.blp`, `tier3_hunter-banner.blp` |
| Save 5,000 Gold | 🟦 `gold_5k-banner.blp` | 🟦 `gold_5k-banner.blp` |
| Black Qiraji Resonating Crystal | 🟦 `mount_qiraji-banner.blp` | 🟦 `mount_qiraji-banner.blp` |
| Blue Qiraji Resonating Crystal | 🟦 `mount_qiraji_aq-banner.blp` | 🟦 `mount_qiraji_aq-banner.blp` |
| Charger (Paladin Epic Mount) | 🟢 `mount_charger-banner.blp` | ⚪ — |
| Deathcharger's Reins | 🟦 `mount_deathcharger-banner.blp` | 🟦 `mount_deathcharger-banner.blp` |
| Dreadsteed (Warlock Epic Mount) | 🟦 `mount_dreadsteed-banner.blp` | 🟦 `mount_dreadsteed-banner.blp` |
| Green Qiraji Resonating Crystal | 🟦 `mount_qiraji_aq-banner.blp` | 🟦 `mount_qiraji_aq-banner.blp` |
| Red Qiraji Resonating Crystal | 🟦 `mount_qiraji_aq-banner.blp` | 🟦 `mount_qiraji_aq-banner.blp` |
| Swift Razzashi Raptor | 🟦 `raid_zg-banner.blp` | 🟦 `raid_zg-banner.blp` |
| Swift Zulian Tiger | 🟦 `mount_tiger-banner.blp` | 🟦 `mount_tiger-banner.blp` |
| Winterspring Frostsaber | 🟦 `frostsaber-banner.blp` | 🟦 `frostsaber-banner.blp` |
| Yellow Qiraji Resonating Crystal | 🟦 `mount_qiraji_aq-banner.blp` | 🟦 `mount_qiraji_aq-banner.blp` |
| Epic Racial Mounts | 🟢 `epicmounts_dwarf-banner.blp`, `epicmounts_gnome-banner.blp`, `epicmounts_human-banner.blp`, `epicmounts_nightelf-banner.blp`, `epicmounts_skyborne-banner.blp` | 🟢 `epicmounts_orc-banner.blp`, `epicmounts_tauren-banner.blp`, `epicmounts_troll-banner.blp`, `epicmounts_undead-banner.blp` |
| Max Primary Professions | ⚪ Learned-skill choice | ⚪ Learned-skill choice |
| Max Secondary Skills | ⚪ Learned-skill choice | ⚪ Learned-skill choice |
| Win the Stranglethorn Fishing Extravaganza | 🟦 `fishing_extravaganza-banner.blp` | 🟦 `fishing_extravaganza-banner.blp` |
| Alliance War Mount (Rank 11) | 🟢 `pvp_mount_ally-banner.blp` | ⚪ — |
| Duelist | 🟦 `pvp_drums_of_war-banner.blp` | 🟦 `pvp_drums_of_war-banner.blp` |
| Exalted: Frostwolf Clan | ⚪ — | 🟢 `pvp_av_horde-banner.blp` |
| Exalted: League of Arathor | 🟢 `pvp_arathi-banner.blp` | ⚪ — |
| Exalted: Silverwing Sentinels | 🟢 `pvp_wsg_ally-banner.blp` | ⚪ — |
| Exalted: Stormpike Guard | 🟢 `pvp_av_ally-banner.blp` | ⚪ — |
| Exalted: The Defilers | ⚪ — | 🟢 `pvp_arathi-banner.blp` |
| Exalted: Warsong Outriders | ⚪ — | 🟢 `pvp_wsg_horde-banner.blp` |
| Field Marshal's Aegis | 🟢 `pvp_set_plate_ally-banner.blp` | ⚪ — |
| Field Marshal's Battlegear | 🟢 `pvp_set_plate_ally-banner.blp` | ⚪ — |
| Field Marshal's Earthshaker | 🟢 `pvp_set_mail_ally-banner.blp` | ⚪ — |
| Field Marshal's Pursuit | 🟢 `pvp_set_mail_ally-banner.blp` | ⚪ — |
| Field Marshal's Raiment | 🟢 `pvp_set_cloth_ally-banner.blp` | ⚪ — |
| Field Marshal's Regalia | 🟢 `pvp_set_cloth_ally-banner.blp` | ⚪ — |
| Field Marshal's Sanctuary | 🟢 `pvp_set_leather_ally-banner.blp` | ⚪ — |
| Field Marshal's Threads | 🟢 `pvp_set_cloth_ally-banner.blp` | ⚪ — |
| Field Marshal's Vestments | 🟢 `pvp_set_leather_ally-banner.blp` | ⚪ — |
| Frostwolf Howler | ⚪ — | 🟢 `pvp_av_horde-banner.blp` |
| Grand Marshal | 🟢 `pvp_rank14-banner.blp` | ⚪ — |
| High Warlord | ⚪ — | 🟢 `pvp_rank14-banner.blp` |
| Honorable Kills | 🟦 `pvp_drums_of_war-banner.blp` | 🟦 `pvp_drums_of_war-banner.blp` |
| Horde War Mount (Rank 11) | ⚪ — | 🟢 `pvp_mount_horde-banner.blp` |
| Stormpike Battle Charger | 🟢 `pvp_mount_ally-banner.blp` | ⚪ — |
| Warlord's Aegis | ⚪ — | 🟢 `pvp_set_plate_horde-banner.blp` |
| Warlord's Battlegear | ⚪ — | 🟢 `pvp_set_plate_horde-banner.blp` |
| Warlord's Earthshaker | ⚪ — | 🟢 `pvp_set_mail_horde_shaman-banner.blp` |
| Warlord's Pursuit | ⚪ — | 🟢 `pvp_set_mail_horde-banner.blp` |
| Warlord's Raiment | ⚪ — | 🟢 `pvp_set_cloth_horde-banner.blp` |
| Warlord's Regalia | ⚪ — | 🟢 `pvp_set_cloth_horde-banner.blp` |
| Warlord's Sanctuary | ⚪ — | 🟡 `set_tier2_warrior-banner.blp` |
| Warlord's Threads | ⚪ — | 🟢 `pvp_set_cloth_horde-banner.blp` |
| Warlord's Vestments | ⚪ — | 🟡 `set_tier2_warrior-banner.blp` |
| Clear Blackwing Lair | 🟦 `raid_bwl-banner.blp` | 🟦 `raid_bwl-banner.blp` |
| Clear Hyjal Summit | 🟦 `raid_hyjal-banner.blp` | 🟦 `raid_hyjal-banner.blp` |
| Clear Molten Core | 🟦 `raid_mc-banner.blp` | 🟦 `raid_mc-banner.blp` |
| Clear Naxxramas | 🟦 `raid_naxx-banner.blp` | 🟦 `raid_naxx-banner.blp` |
| Clear Ruins of Ahn'Qiraj | 🟦 `raid_aq20-banner.blp` | 🟦 `raid_aq20-banner.blp` |
| Clear Temple of Ahn'Qiraj | 🟦 `raid_aq40-banner.blp` | 🟦 `raid_aq40-banner.blp` |
| Clear Zul'Gurub | 🟦 `raid_zg-banner.blp` | 🟦 `raid_zg-banner.blp` |
| Clear the Barrow Deeps | 🟦 `raid_barrow-banner.blp` | 🟦 `raid_barrow-banner.blp` |
| Slay Onyxia | 🟦 `raid_ony-banner.blp` | 🟦 `raid_ony-banner.blp` |
| Arcanite Reaper | 🟦 `arcanite_reaper-banner.blp` | 🟦 `arcanite_reaper-banner.blp` |
| Wolfsbane | ⚪ — | 🟢 `wolfsbane-banner.blp` |
| Ambassador: Alliance Capitals | 🟢 `rep_ambassador_ally-banner.blp`, `rep_ambassador_ally_darnassus-banner.blp`, `rep_ambassador_ally_ironforge-banner.blp` | ⚪ — |
| Ambassador: Horde Capitals | ⚪ — | 🟢 `rep_ambassador_horde-banner.blp`, `rep_ambassador_horde_thunderbluff-banner.blp`, `rep_ambassador_horde_undercity-banner.blp` |
| Exalted: Argent Dawn | 🟦 `rep_argentdawn-banner.blp` | 🟦 `rep_argentdawn-banner.blp` |
| Exalted: Brood of Nozdormu | 🟦 `rep_nozdormu-banner.blp` | 🟦 `rep_nozdormu-banner.blp` |
| Exalted: Cenarion Circle | 🟦 `rep_cenarion-banner.blp` | 🟦 `rep_cenarion-banner.blp` |
| Exalted: Hydraxian Waterlords | 🟦 `rep_hydraxian-banner.blp` | 🟦 `rep_hydraxian-banner.blp` |
| Exalted: Thorium Brotherhood | 🟦 `rep_thorium-banner.blp` | 🟦 `rep_thorium-banner.blp` |
| Exalted: Timbermaw Hold | 🟦 `rep_timbermaw-banner.blp` | 🟦 `rep_timbermaw-banner.blp` |
| Exalted: Zandalar Tribe | 🟦 `raid_zg-banner.blp` | 🟦 `raid_zg-banner.blp` |
| Buff Others | 🟦 `social_buffs_druid-banner.blp`, `social_buffs_mage-banner.blp`, `social_buffs_paladin-banner.blp`, `social_buffs_priest-banner.blp` | 🟦 `social_buffs_druid-banner.blp`, `social_buffs_mage-banner.blp`, `social_buffs_paladin-banner.blp`, `social_buffs_priest-banner.blp` |
| Dungeons with Guildmates | 🟦 `social_guild_dungeon-banner.blp` | 🟦 `social_guild_dungeon-banner.blp` |
| Give Cheers | 🟦 `social_cheers-banner.blp` | 🟦 `social_cheers-banner.blp` |
| Give Hugs | 🟦 `social_hugs-banner.blp` | 🟦 `social_hugs-banner.blp` |
| Give Waves | 🟦 `social_waves-banner.blp` | 🟦 `social_waves-banner.blp` |
| Join a Guild | 🟦 `social_guild-banner.blp` | 🟦 `social_guild-banner.blp` |
| Make Friends | 🟦 `social_friends-banner.blp` | 🟦 `social_friends-banner.blp` |
| Make Trades | 🟦 `social_trades-banner.blp` | 🟦 `social_trades-banner.blp` |
| Place Campfires | 🟦 `prof_cooking-banner.blp` | 🟦 `prof_cooking-banner.blp` |
| Raids with Guildmates | 🟦 `social_guild_raid-banner.blp` | 🟦 `social_guild_raid-banner.blp` |
| Say LOL | 🔴 None | 🔴 None |
| Summon Players | 🟦 `social_summons-banner.blp` | 🟦 `social_summons-banner.blp` |
