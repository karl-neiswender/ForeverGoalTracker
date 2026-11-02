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

CHANGELOG.md has uncommitted edits from Karl, so this was not added there. Karl's call (2026-11-02): the artwork is
one general line, and only the new goals are named.

- Added Exalted: Steamwheedle Cartel to the Goal Library, with a step for each of Booty Bay, Ratchet, Gadgetzan and Everlook, and Powderfuse on Forever.
- Added Cruel Barb, Phantom Blade, Gurubashi Dwarf Destroyer, Elemental Mage Staff and Aegis of the Blood God to the Goal Library.
- Added more goal artwork, including leveling banners for more races and sexes and new Tier, Dungeon Set and PvP set banners.
- UI improvements and bug fixes.

Check before pasting: none of these goals is in CHANGELOG.md yet (Elementium Reinforced Bulwark already is). Aegis of
the Blood God is in Karl's uncommitted Library.lua edits, so drop it if that goal is not shipping.
