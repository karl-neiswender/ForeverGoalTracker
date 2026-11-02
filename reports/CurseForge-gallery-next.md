# Gallery plan for the next release (version to confirm)

Karl's call (2026-11-02): a fresh pass on the screenshot scenes. Eleven shots, in upload order, each one answering
a question a new Forever player has. Nothing here has been captured yet.

## Decisions

- **Thunderfury leads.** It explains the addon at a glance: an iconic long-haul goal with a path to it.
- **Wolfsbane stays and is second.** It is the Forever hook (an Undead Paladin's iconic item), so it is not swapped for anything.
- **Headline features come next:** Gear Planner, Materials, the map.
- **Dropped:** the welcome screen with the interest tiles (the suggestions shot shows the personalization), the Steamwheedle
  Cartel and artwork collage ideas, and "across your characters" and the "Needed for" tooltip (too hard to stage in the scenes).
- **Window size stays** at 1785 x 1000. At 820 pixels wide the text still reads.
- **Suggestions shot:** Raiding, PvP and The Grind picked, so the six rows show a mix.

## The eleven shots

| File | Scene | Retake on | Title | Description |
|---|---|---|---|---|
| `01-my-goals.png` | 1 | Era | Chase legendary goals, step by step | Follow a goal like Thunderfury from the first material to the final drop. Steps tick off as you play. |
| `02-wolfsbane.png` | 11 | **Forever** | Chase Forever's new goals | Wolfsbane is a Forever quest weapon for Horde Paladins. Follow its quest chain, with light and embers on the banner. |
| `03-gear-planner.png` | 13 | Era | Plan your gear, slot by slot | Pick items with filters, see where each one drops, add enchants and preview the set on your race's backdrop. |
| `04-materials.png` | 9 | Era | Know what you still need | See the materials and tokens a goal still needs, counted across your characters. |
| `05-links-and-hints.png` | 4 | Era | Guides that link everything | Items, quests and NPCs link in the guide, and Hints sit under the steps. Fold the goals list to give the guide more room. |
| `06-library-filters.png` | 10 | Era | Browse every goal | Filter by class, faction or category. Sort armor sets by progression. |
| `07-new-and-updated.png` | 2 | **Forever** | See what's new in Forever | Blue labels and the New & Updated filter show Forever's additions and changes. |
| `08-epic-mounts.png` | 3 | Era | Track the mounts you want | Pick which racial mounts to follow and see each mount's steps. |
| `09-find-your-next-goal.png` | 8 | **Forever** | Never run out of things to chase | Find your next goal suggests goals for your character and skips the ones you already track. |
| `10-suggestions.png` | 6 | Era | Goals picked for you | Suggestions follow your character and interests. Add them together or choose individual goals. |
| `11-settings.png` | 1 + settings | Era | Make it yours | Adjust image effects, sounds, alerts, map pins and window options. |

The three Forever shots were last taken on the 2.15.0 window (old "Tips" label, no Gear Planner tab). Retake them on live
Forever after November 4.

## What changed in the code

- `FGT.SHOTS` in `Core.lua` and `NAMES` / `FOREVER_ONLY` in `tools/shots.py` use the new order and file names.
- The map shot is **not in the gallery**: the map only draws the zone areas a character has explored, and Karl's character is low
  level, so it comes out empty. Scene 12 stays for `/goals demo 12`. Revisit with a character that has explored a zone.
- The overall bar's numbers are forced on while shots are taken (they otherwise show only on hover or just after progress moves),
  so every shot has them. The setting is put back afterwards.
- Scene 4 opens the goal's Hints (`hints = true`), so the links shot is not half empty.
- Scene 6 (suggestions) picks Raiding, PvP and The Grind.
- The welcome interests screen and the Steamwheedle, artwork, across-characters and Needed-for ideas were dropped.

## How to capture (Classic Era, in game)

1. `/reload`, size the window the same as before (1785 x 1000), close other windows.
2. If the Gear Planner shot comes out with blank gear, run `/goals demo 13`, wait until the character is dressed, then `/goals demo off`.
3. Run `/goals shots era`. It takes the eight Era shots in one go. To retake one, run `/goals shots 05` and then `python tools/shots.py --only 05`.
4. Run `python tools/shots.py --era` in the repo. It crops each shot and writes `Screenshots/NN-name.png`, leaving the three Forever shots as they are.
5. Review a contact sheet and each full-size image. Then upload in this order with the titles above.

On live Forever, `/goals shots` takes all eleven.
