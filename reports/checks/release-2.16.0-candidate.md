# Release 2.16.0 candidate, October 24, 2026

Karl asked for this release on October 24 and confirmed that the Classic Era build is ready. The Warcraft Forever beta is closed, so Forever could not be tested for this release. This record is the evidence for the candidate. Publication is recorded separately once it happens.

## Quality gate

- TOC, CHANGELOG and What's new all say 2.16.0 (What's new dated Oct 24, 2026). Interfaces stay 11509 and 16001.
- `tools/check.py`: real Lua 5.1 compilation of all 23 files, accidental-global checks and 109 Era/Forever runtime scenarios passed on this candidate. Output: `release-2.16.0-lua51.txt`.
- Ketho WoW API 0.22.3 and LuaLS diagnostics (`sh tools/run-luals.sh`): the first run found two `need-check-nil` warnings on one line of `GearPlanner.lua` (the enchant lookup for a slot read `selected.enchants` without a guard). Fixed by guarding `selected`; the rerun found no problems. 14,028 annotation load events confirmed. Output: `release-2.16.0-luals.json` and `.txt` (the second run). No broad suppressions and no new exceptions.

## Performance review (offline, not native)

The planner's weather effects (`PlannerEffects.lua`) run a second copy of the goal page's own particle engine on the backdrop. They step only while the planner is on screen and Settings > Images > Image effects is Full, and keep their particles while the planner is closed instead of rebuilding them. A throwaway bench built from `tools/perfbench.py` (real Lua 5.1, game API calls stubbed, so the addon's share only) measured per frame at 60 fps:

| Backdrop | Lua time | Garbage | Texture API calls | Particles |
|---|---|---|---|---|
| Dwarf (snow) | 100 µs | 0 B | 147 | 150 |
| Gnome (snow) | 94 µs | 0 B | 145 | 150 |
| Night elf (motes) | 17 µs | 0 B | 26 | 26 |
| Undead (ash motes) | 8 µs | 0 B | 14 | 14 |
| Orc (embers) | 13 µs | 0 B | 41 | 22 |

The troll, tauren and human have no particles, only the ambience layers (game animation groups, almost free). The snow is the busiest case, about 0.6% of a core at 60 fps by this measure, close to the goal pages' busiest banners (Warlord's cloth, 156 particles). Native CPU and rendering were not profiled.

The sheathe key uses an override binding that exists only while the planner is open (no keyboard capture, no `SetPropagateKeyboardInput`, which Core.lua records as unsafe on the Forever engine). The backdrop placement, drop shadow and set totals changes add no events or timers.

## Native evidence and what is not covered

Karl reviewed every change in Classic Era in game: all eight racial backdrops (grounding, drop shadow and weather, each tuned in his live review), the Z sheathe key, Set totals and the character menu in the sets drawer. The Gear Planner as a whole was reviewed in Era earlier.

Not covered: Warcraft Forever. The beta closed on October 23, before this round of testing. Nothing about the planner's Forever behavior was verified for this release, including the backdrops, weather effects and sheathe key on the Forever engine. The CHANGELOG developers' notes say so. Forever dependency gates stay disabled as before.

## Package and documentation

Local package simulation from `.pkgmeta` and `git ls-files`: 368 runtime files, 70.5 MB uncompressed (the eight new 3 MB backdrop textures in `Media/dressing-room`, the rest as before), every TOC file present including `PlannerEffects.lua`, `Bindings.xml`, the license and Cinzel Bold present, tools, reports, source artwork and the artwork originals excluded. The workflow ZIP still has to be verified after upload.

README and ROADMAP already describe the Gear Planner as shipped in 2.16.0. The exact bottom AI disclaimer rule is unchanged. Gallery review: the 12 gallery screenshots predate the Gear Planner, so the headline feature of this release has no gallery image. No new gallery or author-console description update is claimed; both need Karl, and a planner shot needs a demo scene first.
