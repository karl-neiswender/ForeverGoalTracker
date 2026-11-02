# Background work, 2026-11-02

Done while Karl tested the Era client. Codex was out for the day.

## 1. Powderfuse

Karl supplied the faction: Wowhead Forever faction 2827. The Cartel goal's fifth step (Forever only) now ticks
from that faction like the other four (Booty Bay 21, Ratchet 470, Gadgetzan 369, Everlook 577). Web searches
found no id, so Karl's link is the source. Check it in game on a Forever client.

## 2. Grid check

`python tools/art-grid-check.py` asks the addon which Level Classes to 60 banner each race, class and sex gets
and compares it with the checklist's `RC_ART` grid. Result today: 0 of the cells differ. Run it after any art batch
or mapping change; it exits 1 when a cell drifts.

## 3. Blocked rows

22 rows are blocked, but only three are blocked for lack of a usable image. The rest are rows Karl confirmed
already have art (A039, A040, A056, A084, A096, A102, A110, A119, A128, A131, A138, A143, A147 to A149, A166, A171)
and two optional additions (A173, A174), which need no work.

| Row | Why blocked | New option from the cards Karl added |
|---|---|---|
| A097 Tier 1 Priest H F (Tauren) | Imagegen failed five times | The slot's own alternate is a real card for an Undead female Priest (`horde-undead-female-priest-tier1-2.jpg`, 1050px; `-tier1.jpg` is a second version). Tauren is not a Priest race in Era, so retargeting the row to the Undead female is the better fix. |
| A121 Dungeon Set 1 Druid H | Source too detailed for the banner | No other Horde Druid dungeon set image exists. It keeps the shared dungeon scene. |
| A145 Dungeon Set 2 Warrior A | Imagegen failed (sword tip) | New: `alliance-nightelf-female-warrior-dungeonset.png` (745px, unused). It could replace the male Night Elf source, which is the one that failed. The row's own alternate is the Human male plate image. |

None of these was changed. Imagegen needs Codex, so any retry waits for it.

## 4. Progression

See [Banner-progression-plan.md](Banner-progression-plan.md).

## 5. Release notes draft (for Karl to place in CHANGELOG.md)

CHANGELOG.md has uncommitted edits from Karl, so this was not added there. Lines follow the usual style, then the
closing generic line.

- Added Exalted: Steamwheedle Cartel to the Goal Library, with a step for each of Booty Bay, Ratchet, Gadgetzan and Everlook, and Powderfuse on Forever.
- Added Aegis of the Blood God, Elemental Mage Staff, Cruel Barb, Blastershot Launcher and The Shatterer banners. (Elementium Reinforced Bulwark is already listed above.)
- Added leveling banners for female Gnome Rogues, female Orc Hunters, female Troll Warriors, female Dwarf Rogues, male Night Elf Druids, female Tauren Druids and male Undead Warlocks.
- Added Tier 3 Warrior art for female Humans, Warlord's Regalia art for male Orc Mages, and Dungeon Set art for Undead Paladins.
- Added larger artwork for Crimson Shocker, Draconian Deflector, Dwarven Hand Cannon, Wall of the Dead and Doomfinger.
- Changed the Dungeon Set, Tier 2 Hunter and PvP Druid banners for several races to their own artwork.
- UI improvements and bug fixes.

Wording check for Karl: the first lines name goals he can see in the Library. "Changed ... for several races" is
deliberately general because the checklist does not list each swap for the player.
