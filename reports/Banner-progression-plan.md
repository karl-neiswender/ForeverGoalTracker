# Banner progression plan (2.17.x, not before Nov 4)

Karl's idea (2026-11-02): a character's banner changes as the character progresses, for the race, sex and class
combinations that have more than one image. This is a plan only. No code was written for it.

## The phases

The file names in `Media/artwork` carry Karl's phase numbers.

| Phase | Meaning | Picked by |
|---|---|---|
| ph1 | Start of the adventure, almost no gear | level |
| ph2 | A bit more gear, no shoulders | level |
| ph3 | About level 30 to 50 | level |
| ph4 | Fresh level 60, maybe dungeon gear | level |
| ph5 | Tier 1 | gear |
| ph6 | Tier 2 | gear |
| ph7 | Tier 3, or the PvP elite sets | gear |

In the artwork folder `dungeonset` files count as ph4, `tier1` to `tier3` as ph5 to ph7, and `pvpset` as ph7.

## What exists (2026-11-02)

Counted from the file names in `Media/artwork`, one image per phase at most, buff, backside, weapon and AQ-set cards left out.

- 91 race, sex and class combinations have at least one phased image.
- Phases covered per combination: 1 phase for 16, 2 for 15, 3 for 14, 4 for 27, 5 for 17, 6 for 2.
- Only three combinations have all of ph1 to ph4: male Dwarf Priest, male Gnome Rogue and female Troll Hunter.
- 42 combinations have both ph3 and ph4. Only 14 have any ph1 image, and 36 have a ph2.
- The fullest are male Night Elf Druid and female Orc Shaman (ph2 to ph7), then male Dwarf Priest (ph1 to ph4 and ph7), male Gnome Rogue (ph1 to ph5), male Human Warrior (ph1, ph3 to ph6) and male Orc Hunter (ph3 to ph7).

The image quality differs by phase: ph1 to ph4 are mostly ally and hero cards pictured in light gear, while ph5 to ph7 are gear shots. A character that changes from one to the other will look like a change of style, not just of gear. Karl should judge that on a sheet before any code.

## Design

1. **One new input, `stage`.** `B:BestArtVariant(variants, player)` in `Core.lua` already picks by faction, class, race and sex, with fallbacks. Add a `stage` field to a variant (1 to 7) and a `stage` value on the player (computed from level and gear). The pick becomes: the highest stage that is at most the player's stage, then the old fallbacks. A combination with only ph3 and ph5 art shows ph3 until Tier 1, and shows today's single banner below ph3. Nothing breaks for combinations with one image.
2. **Where it applies.** The Level Classes to 60 goal (`allclasses`) is the natural place for ph1 to ph4. Gear sets already have tier art, so ph5 to ph7 would only matter on `allclasses` for a level 60 character.
3. **Stage from level (ph1 to ph4).** A first guess: ph1 below level 15, ph2 from 15, ph3 from 30, ph4 from 55. Karl adjusts the cut-offs.
4. **Stage from gear (ph5 to ph7).** Needs a rule for how much of a set counts. For example, ph5 once the character owns or wears three Tier 1 pieces, ph6 for Tier 2, ph7 for Tier 3 or Marshal and Warlord pieces. The set item ids are in `ArmorSets.lua`. Gear is harder than level because the addon reads owned items from the roster scan, and Era and Forever differ.
5. **Which character.** The banner belongs to a goal, not to one character. `allclasses` is about the whole roster, so the stage should come from the character the goal is shown for (the same `player` table `BestArtVariant` already gets). Decide how it behaves when the goal shows several characters.
6. **Checklist.** `RC_ART` would need a stage column, and the grid would show a count of stages per cell. `tools/art-grid-check.py` already compares the grid with the addon and can be extended the same way.
7. **Cost.** Each banner is about 175 KB. The Media folder is 144 MB now with 441 banners. Giving the 42 combinations with ph3 and ph4 two extra images each is about 84 banners, about 15 MB. Filling every one of the 91 combinations to four phases would be roughly 200 to 250 more banners, about 35 to 45 MB. Only the banner on screen is loaded, so memory does not grow with the file count.

## Order of work

1. Decide the cut-offs and the gear rule with Karl.
2. Build the resolver change and the stage computation with no new art. The existing banners count as stage 4, so nothing changes on screen. Add tests in `tools/banner-tests.lua`.
3. Add ph3 and ph4 banners for the 42 combinations that have both, through the normal batch pipeline.
4. Add ph1 and ph2 where an image exists (14 and 36 combinations).
5. Add ph5 to ph7 on `allclasses` last.

## Open questions for Karl

- Do you want the banner to change on screen, or only the saved default per character?
- Is a style change between ph4 and ph5 acceptable, or should ph5 to ph7 stay on the set goals only?
- Should the stage come from the character shown, or the highest stage on the roster?
