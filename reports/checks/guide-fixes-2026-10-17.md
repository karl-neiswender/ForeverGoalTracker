# Character filters and guide fixes, October 17, 2026

Unreleased source changes. No version bump, release tag or publication.

- Buff Other Players uses the same four supported classes as the existing buff tracker: Mage, Druid, Priest and Paladin. Both Library For and My Goals This character use `GoalFits`; Anyone/All goals remains available.
- Arcanite Reaper step 2 uses its ordinary number. The Blacksmithing rule and prerequisites remain intact.
- Hyjal Summit and Barrow Deeps mark their binary boss objectives `hideProgressBar`. The shared renderer honors this in the main window and pop-out. Automatic boss/statistic rules and the goal-level bar remain intact.
- War mount step 2 names Lieutenant Karter in Stormwind City or Raider Bork in Orgrimmar. NPC names link through the existing NPC system; explicit city map tags resolve to the relevant PvP hall approach. These reuse existing map/pin APIs and event handling.

## Location evidence and limits

Checked October 17:

- [Wowhead Classic Lieutenant Karter](https://www.wowhead.com/classic/npc=12783/lieutenant-karter) lists the four Alliance war mounts. Its current map summary lists battlegrounds, so it is not used as city-coordinate evidence.
- [Classic mount guide](https://www.warcrafttavern.com/wow-classic/guides/mounts/) places Karter at Champions Hall in Old Town, Stormwind, 72.4, 50.8.
- [PvP vendor locations](https://www.warcrafttavern.com/tbc/guides/pvp-vendor-locations/) gives the original-city Hall of Legends approach in Orgrimmar at 39.9, 69.1 and lists Bork among the indoor vendors. This is an adjacent-client reference for the hall approach, not a verified exact Era NPC position.
- [Raider Bork history](https://warcraft.wiki.gg/wiki/Raider_Bork) records the later 3.2.2 move outside the Hall of Legends. Do not use the later outdoor mount vendor position as the original hall destination.
- [Wowhead Forever Karter](https://www.wowhead.com/forever/npc=12783/lieutenant-karter) does not provide a reliable city map; [Forever Bork](https://www.wowhead.com/forever/npc=12796/raider-bork) likewise lists battlegrounds in the extracted map summary.
- [WOWF.IO PvP](https://wowf.io/en/pvp) independently places both vendors inside their faction halls, but its approach coordinates differ. Those coordinates were not adopted without native confirmation.

Pins are explicitly hall approaches, not exact indoor NPC positions. Both destinations retain `unverifiedInForever`; NPC and map tooltips call the Forever position Unconfirmed. Native verification of both hall approaches is still needed, particularly the Horde reference shared with TBC. Rank requirements and mount ownership rules were not changed.

## Validation

- Focused Lua 5.1 scenarios pass on Era and Forever: class eligibility matches the tracker, ordinary numbering, pooled row bar visibility, pop-out bar suppression, vendor/city links, matching pins and uncertainty notices.
- Ketho/LuaLS: no diagnostics. Retained JSON and run/loading proof in `guide-fixes-2026-10-17-luals.json` and `.txt`; 14,027 annotation log references. Uses the existing Mac Lua 5.1 config and combined WoW annotation library. This source check is not a publication or a native-client compatibility claim.
- Full suite output: `guide-fixes-2026-10-17-lua51.txt`.
- Performance review: no new events, timers, scans or animation work. One constant-time boolean check is added to the existing row layout. Two NPCs and two map destinations join the existing lazy indexes.
- In-game review remains: Rogue and supported caster filters, Reaper step 2, both raid pages and pop-outs, both faction hall pins/city links. `/reload` loads these source changes.
