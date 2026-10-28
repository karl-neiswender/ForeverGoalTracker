# Seven goal and character banners, 2026-10-28

Installed by Codex in `f6d236e` ("Art: install seven approved goal and character banners"). Karl approved all
seven. The machine record of the job is [approved-seven-banners-2026-10-28.json](approved-seven-banners-2026-10-28.json);
this page is the readable record, written by Claude on Karl's request the same day after checking the install.
The untouched sources remain in `Media/artwork`. Each approved master is a neutral 1200 x 900 image in
`Media/final-images`; `tools/artwork.py` compiled 512px DXT1 BLPs with ten mip levels.

| Banner | Goal and who sees it | Original source | Master | Credit |
|---|---|---|---|---|
| `collect_the_1_ring` | The 1 Ring, everyone | `item-ring-3.jpg` | `collect_the_1_ring-master.png` | None: no signature on the source |
| `allclasses_undead_priest_male` | Leveling, Horde male Undead Priest | `horde-undead-male-priest-tier2-weapon-anathema-shadow.png` | `allclasses_undead_priest_male-master.png` | Bob Larkin |
| `allclasses_undead_priest_female` | Leveling, Horde female Undead Priest | `horde-undead-female-priest-pvp-cloth.png` | `allclasses_undead_priest_female-master.png` | Triston Elwell |
| `allclasses_human_rogue_female` | Leveling, Alliance female Human Rogue | `alliance-human-female-rogue-tier3-2.jpg` | `allclasses_human_rogue_female-master.png` | None: no signature on the source |
| `allclasses_human_hunter_male` | Leveling, Alliance male Human Hunter (Forever only) | `alliance-human-male-hunter-leveling.png` | `allclasses_human_hunter_male-master.png` | Jim Nelson |
| `dungeon_hunter_human_male` | Beaststalker and Beastmaster, Alliance male Human | `alliance-human-male-hunter-dungeonset.png` | `dungeon_hunter_human_male-master.png` | Leo Che (Concept Art House) |
| `allclasses_human_paladin_male` | Leveling, Alliance male Human Paladin | `alliance-human-male-warrior-leveling-2.jpg` | `allclasses_human_paladin_male-master.png` | None yet: see below |

Credits are in `Core.lua`'s artist list (`B.artArtists`) and show on the goal, never in the image.

**Missing credits.** Three banners have none, by the rule to credit only verified artists:
- The 1 Ring and the female Human Rogue: the sources carry no signature or card credit.
- The male Human Paladin: the source painting (a Human in a red tabard under arrow fire) is signed in its lower
  right corner, which reads roughly "Polder © 2012". That is not enough to name the artist with confidence, so no
  credit is assigned. Once the artist is confirmed, add the name for `allclasses_human_paladin_male-banner.blp`
  in `B.artArtists`.

**Wiring (checked by Claude, 2026-10-28).** Each leveling banner is an `allclasses` variant with faction, class,
race and sex (2 male, 3 female), so the other sex keeps its existing art: female Human Hunters and Paladins keep
`allclasses_human_hunter` and `allclasses_human_paladin` (both picture women). The dungeon Hunter image is a
variant of `set_dungeon1_hunter` and `set_dungeon2_hunter` for Alliance male Humans; everyone else keeps the
shared dungeon image. The 1 Ring has its own `collect_the_1_ring` entry. Every banner has its file, a runtime
manifest entry, an `artwork.py` entry and a checklist thumbnail and sex tag. The checklist's leveling rows,
previews and "Find these first" list were updated in `4495eab` to match.

Validation: `tools/check.py` passed (116 sessions). A full game restart is required to load the new textures;
native appearance is pending.
