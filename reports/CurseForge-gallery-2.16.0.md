# Gallery plan for 2.16.0

Karl's call (2026-10-24): retake the gallery on Classic Era so it shows the current UI, keep the few shots that are specific to Forever, and add a Gear Planner shot (a level 60 Dwarf Rogue with the pre-raid best in slot set). Nothing here has been captured or uploaded yet. Preparing this file does not update the author console.

## What changes

| File | Plan | Why |
|---|---|---|
| `01-my-goals.png` | Retake on Era | The window now has a Gear Planner tab. |
| `02-wolfsbane.png` | **Keep** | Wolfsbane is a Forever quest weapon. |
| `03-map-view.png` | Retake on Era | See the note on the map shot below. |
| `04-links-and-tips.png` | Retake on Era | |
| `05-materials.png` | Retake on Era | It still shows the old Tauren Warrior Tier 3 artwork. |
| `06-library-filters.png` | Retake on Era | |
| `07-new-and-updated.png` | **Keep** | The blue NEW and UPDATED labels only exist on Forever. |
| `08-epic-mounts.png` | Retaken on Era, review | The capture shows the Skyborne row with a blue NEW label (Forever content), which Era's data also lists. |
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
| `13-gear-planner.png` | Gear Planner | Plan a gear set slot by slot, with item sources, enchants and a 3D preview on your race's backdrop. Shown: a level 60 Dwarf Rogue's pre-raid set. |
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
3. Run `/goals shots era`. To retake just one shot, run `/goals shots 03` (the number or the name) and then `python tools/shots.py --only 03`. It takes the ten Classic Era shots (everything except the three Forever-only ones) in one go, using a black photo backdrop and demo scenes, and puts everything back after. Keep the mouse off the window. The Gear Planner shot is last and waits 12 seconds for the model, the items and the snow to settle.
4. Wait for "done: 10 screenshots", then run `python tools/shots.py --era` in the repo. It crops each shot to the window and writes `Screenshots/NN-name.png`, leaving the three Forever shots untouched.
5. Review a contact sheet and each full-size image, then say so and I will update the notes and commit.

`/goals shots` with no argument still takes all 13 (use it on live Forever after November 4).

The Gear Planner scene (`/goals demo 13`) stages a pretend roster character, "Thurgrim", with the Rogue Pre-Raid BiS set open (Wowhead's dagger Rogue pre-raid "realistic" BiS, 17 items) and the Set totals expanded. When the logged-in character is also a Dwarf, the model keeps that character's own look, hair included; the addon cannot choose a hair colour itself. It never touches your real characters or sets: the pretend character and set are removed when the demo ends or another scene starts.

## About the map shot

`03-map-view` is not broken when it looks mostly empty. The map shows only the parts of the zone the logged-in character has discovered, as the game's own map does, so a low level character in Burning Steppes shows the mountain ranges and a pin on an undiscovered map. That is how it fills in as a character explores. `/goals map status` prints what the map layer is doing (tiles from the game, tiles drawn, alpha, zoom) if it ever needs checking. The captured `03-map-view.png` is the earlier close-up (Karl kept it on 2026-10-24: a zoomed-out retake is not much different). The scene itself now opens fully zoomed out (the Dreadsteed's step starts at 199%, a close-up of two tiles). For a fuller map, take the shot on a character that has explored the zone, or stage a goal whose NPC stands in a zone this character knows.
