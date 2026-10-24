# Gallery plan for 2.16.0

Karl's call (2026-10-24): retake the gallery on Classic Era so it shows the current UI, keep the few shots that are specific to Forever, and add a Gear Planner shot (a level 60 Dwarf Hunter with the pre-raid best in slot set). Nothing here has been captured or uploaded yet. Preparing this file does not update the author console.

## What changes

| File | Plan | Why |
|---|---|---|
| `01-my-goals.png` | Retake on Era | The window now has a Gear Planner tab. |
| `02-wolfsbane.png` | **Keep** | Wolfsbane is a Forever quest weapon. |
| `03-map-view.png` | Retake on Era | The 2.15.0 capture showed no zone map (see the note below). |
| `04-links-and-tips.png` | Retake on Era | |
| `05-materials.png` | Retake on Era | It still shows the old Tauren Warrior Tier 3 artwork. |
| `06-library-filters.png` | Retake on Era | |
| `07-new-and-updated.png` | **Keep** | The blue NEW and UPDATED labels only exist on Forever. |
| `08-epic-mounts.png` | Retake on Era | Era has the eight racial mounts without the Skyborne row. |
| `09-find-your-next-goal.png` | **Keep** | Embrace of the Viper is UPDATED in Forever. |
| `10-welcome.png` | Retake on Era | |
| `11-suggestions.png` | Retake on Era | |
| `12-settings.png` | Retake on Era | It will show 2.16.0 and the current options. |
| `13-gear-planner.png` | **New, on Era** | The headline feature of 2.16.0. |

The kept shots were taken on Forever with the 2.15.0 window, so they lack the Gear Planner tab. Retake them on live Forever after November 4 if the mismatch bothers you.

## Upload order and copy

Feature the Gear Planner second.

| File | Title | Description |
|---|---|---|
| `01-my-goals.png` | My Goals | Favorites, progress and a step-by-step guide. Progress is tracked across your characters. |
| `13-gear-planner.png` | Gear Planner | Plan a gear set slot by slot, with item sources, enchants and a 3D preview on your race's backdrop. Shown: a level 60 Dwarf Hunter's pre-raid set. |
| `02-wolfsbane.png` | Goal artwork | Illustrated goal backgrounds with optional light and particle effects. Wolfsbane is a Forever quest weapon for Horde Paladins. |
| `03-map-view.png` | Find your next step | See the zone map and a pin for the person your next step needs. |
| `04-links-and-tips.png` | Links, tips and a folding list | Linked items, quests and NPCs in the guide. Fold the goals list to give the guide more room. |
| `05-materials.png` | Materials | See the materials and tokens a goal still needs, counted across your characters. |
| `06-library-filters.png` | Goal Library | Filter by class, faction or category. Sort armor sets by progression. |
| `07-new-and-updated.png` | New and updated in Forever | Find Forever additions and updates with blue labels and the New & Updated filter. |
| `08-epic-mounts.png` | Choose your mounts | Pick which racial mounts to track and follow each mount's steps. |
| `09-find-your-next-goal.png` | Find your next goal | Get suggestions for your character, skipping goals you already track. |
| `10-welcome.png` | What interests you? | Choose the activities you enjoy to get goal suggestions. |
| `11-suggestions.png` | Goals picked for you | Suggestions follow your character and interests. Add them together or choose individual goals. |
| `12-settings.png` | Make it yours | Adjust image effects, sounds, alerts, map pins and window options. |

## How to capture (Classic Era, in game)

1. `/reload`, then size the window as you want the gallery to look (the earlier shots are 1785 x 1000). Close other windows.
2. Optional, if the Gear Planner shot comes out with blank gear: run `/goals demo 13`, wait until the character is dressed, then `/goals demo off`. That lets the client load the item data once.
3. Run `/goals shots era`. It takes the ten Classic Era shots (everything except the three Forever-only ones) in one go, using a black photo backdrop and demo scenes, and puts everything back after. Keep the mouse off the window. The Gear Planner shot is last and waits 12 seconds for the model, the items and the snow to settle.
4. Wait for "done: 10 screenshots", then run `python tools/shots.py --era` in the repo. It crops each shot to the window and writes `Screenshots/NN-name.png`, leaving the three Forever shots untouched.
5. Review a contact sheet and each full-size image, then say so and I will update the notes and commit.

`/goals shots` with no argument still takes all 13 (use it on live Forever after November 4).

The Gear Planner scene (`/goals demo 13`) stages a pretend roster character, "Thurgrim", with the Hunter Pre-Raid BiS set open and the Set totals expanded. It never touches your real characters or sets: the pretend character and set are removed when the demo ends or another scene starts.

## Earlier note kept from 2.15.0

The map view needs the zone map to be visible when the shot is taken; the 2.15.0 capture showed only the Dreadsteed artwork and a pin. If `/goals shots era` again shows no map, retake `03-map-view` alone: open the goal's map, wait for the zone map, and use `/goals photo black` with a single screenshot.
