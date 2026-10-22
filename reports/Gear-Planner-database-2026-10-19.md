# Gear Planner: item database, search and set tools

Unreleased, October 19, 2026 (Claude, Mac). Follows Codex's October 17 and 18 work; read the [handoff](Gear-Planner-handoff-2026-10-17.md) first. No release or tag.

## What changed and why

The planner's catalogue was about 100 hand-typed items (Tier 3, one Tier 1 helm, 15 Hunter picks). A planner needs the whole slot database, so the item list is now generated from the game's own client tables and the code around it is split by job.

| File | Job |
| --- | --- |
| `tools/geardb.py` | Builds `GearData.lua` from wago.tools' public exports of the client tables (ItemSparse, Item, ItemSet, Faction) for Classic Era 1.15.9 and Forever 1.60.1. Downloads once into `tools/.cache` (ignored). Nothing is read from Wowhead. |
| `GearData.lua` | Generated. 6,740 gear items in 24 inventory-type blocks, 216 set names. About 410 KB (about 105 KB zipped), loads in about 2 ms. Do not edit by hand. |
| `GearCatalog.lua` | Lookup (`Get`), slot search (`Search`), class eligibility (`Usable`), sources (`Source`, `Acquisition`, `SourceLabel`, `EntranceFor`), whole sets (`SetItems`, `SlotFor`), presets. Parses a slot's block only when it is opened and frees it when the planner closes. |
| `GearPlanner.lua` | The tab: set list, header, character, slots, picker, set actions, goal sync. 940 lines before, 1,260 now: the larger picker and set tools outweigh the item data and rules that moved out (the catalogue adds 416). |

### What is in the database

- Classic Era is complete (names, quality, slot, class limits, icon), so it is the base. Season of Discovery ids (200000 and up) are dropped unless Forever has them.
- Forever's tables are partly empty because items stay hidden until a player finds one after launch. Each item carries a Forever status: `0` Classic only (Forever shows "Not revealed yet"), `1` named in Forever's tables, `2` Forever only, `3` Forever only and not revealed (the 90 Hyjal raid-set pieces, named from the Library). Forever-only items never show on Classic Era.
- Included: blue and better at any level, green only from level 35 or when part of a set, shirts and tabards of any quality. Excluded: test and deprecated items by name and by the game's deprecated flag.
- Class limits, armor type and weapon skills were checked against the game's own SkillRaceClassInfo table (all nine classes match). Alliance and Horde PvP gear is marked by faction; Classic stores that in the rank name, not the race mask.
- Reputation, PvP rank and profession requirements come from the item row and show as short notes.

Regenerate with `python3 tools/geardb.py` (delete `tools/.cache/*.csv` first to refresh the downloads). Run `python3 tools/check.py` afterward.

## Player-facing changes

- **Picker:** search by item name, set name, `#id` or a pasted item link; Enter plans the top result. Filters: Usable (class, armor type, weapon skills, dual wield, shields, relics, faction), quality floor (All, Rare+, Epic+), sort (item level, name, required level), and Revealed (Forever client only). Choices are remembered. The list shows every match and recycles about ten rows, so a 700-item weapon slot costs the same as a short one.
- **Rows:** quality-colored name and border, item level, required level, where it comes from, "New in Forever" and "Not revealed yet" marks, a map pin when the source is a dungeon or raid, and a **+ Set** button on set pieces that plans the whole game item set in one click. Hover shows the game tooltip (or the honest "Not revealed yet" one), the source and the set. Shift-click links, right-click opens Wowhead, Ctrl-click tries it on.
- **Slots:** the rim takes the item's quality color.
- **Header:** themed name field; a status line with slots planned, average item level and, once added, items collected; **View in Goals** replaces Add to Goals after adding.
- **Menu:** Rename, Clear items (Undo), **Fill from equipped**, **Duplicate**, Remove from Goals, **Delete set** (second click confirms; also removes the goal and its progress).
- **First visit:** Create a set button, and Hunter Pre-Raid BiS for Alliance Hunters.
- **Sets in My Gear Sets** show collection progress ("In My Goals · 5/16").
- **Goal page:** a gear set's goal shows the pencil, "Edit in Gear Planner" (owner only), which opens that set.
- **Pins:** Molten Core, Blackwing Lair, Onyxia's Lair and Naxxramas entrances were added to `FGT.DUNGEONS` (positions checked against the same HandyNotes reference the other entrances use). They are marked `manual`, so ordinary guide text does not start linking them; only planner steps do.

## Technical notes

- Goal steps, ids and progress credit work as before (`planner_<character>_<set>`, credit moves with the item and slot). Renaming a tracked set no longer rebuilds the goals list per letter (350 ms debounce); item changes still refresh at once.
- Sources come from three places, in order: hand-checked entries (the Hunter list, Tier 3 and its rings), the Library's set data (Tier 1, Tier 2, both dungeon sets, PvP, harvested at first use), then the game's own PvP-rank note. Everything else says "Source unknown". There is no drop-table data in the client, so most of the 6,700 items have no boss yet.
- Duplicate items use game data: an item the game marks unique (max count 1) moves between slots instead of duplicating.
- Memory: slot lists are parsed on demand and freed when the tab closes; only the open set's items stay resident. Search of the largest slot (about 700 items) takes about 2 ms cold in desktop Lua.

## Checks

`python3 tools/check.py` passes (both clients). New coverage in `tools/gear-planner-tests.lua`: every Library set piece is in the database, preset slots fit, lookup and release, class and faction eligibility, search and sort, sources and pins, the recycled list and scroll rebinding, filter persistence, whole sets, set actions, edit button ownership, and the debounce. The dungeon-link test now expects manual entrances to stay plain in guides.

Ketho/LuaLS (3.19.2 with Ketho 0.22.3, run on the Mac from the installed VS Code extensions): no problems, 14,028 annotation load events confirmed. [Results](checks/gear-planner-database-luals.json), [proof](checks/gear-planner-database-luals.txt), [Lua suite output](checks/gear-planner-database-lua.txt). This is the shared workspace diagnostic, not native testing, and the generated `GearData.lua` is excluded from it. Nothing here has been seen in the game. The layout numbers (picker 304 wide, filter row, row 46 tall) are unverified until Karl looks.

## Native review checklist

1. `/reload`, open Gear Planner, click Head: the picker lists many items, scrolls with the wheel and the thumb, and the rows never overlap their text.
2. Type in the search; click the filter buttons; reopen the picker (choices persist).
3. Click a row: the model dresses, the row shows a check, the list does not jump to the top.
4. **+ Set** on a Dragonstalker or Lightforge piece; check the model and the status line.
5. The pin on a dungeon-sourced row sets a map pin; the goal step's dungeon name is a link.
6. Add to Goals, then pencil on the goal page, then back into the planner.
7. Fill from equipped, Duplicate, Delete (twice).
8. Forever client: rows for Classic-only items say "Not revealed yet"; Revealed hides them; a Hyjal raid-set piece shows "New in Forever".
9. Narrow and short windows: picker height, filter row, status line.

## Suggestions and open questions for Karl

1. **Drop sources.** The client has no loot tables. Options: (a) hand-add sources as sets are curated (what exists now); (b) import an open item-to-boss dataset such as Questie's (GPL-3.0, so a licensing decision for an MIT addon); (c) ask Wowhead (you already planned to contact them). A quick probe could also test whether Forever ships the Encounter Journal (`/run print(EJ_GetNumLoot)`), which would give boss loot at runtime for free.
2. **Crafted gear and materials.** The recipe data the planner needs (profession, reagents) is also not in the client tables. Best next step after sources: structured recipes feeding the Materials drawer.
3. **Share a set** as a short text string (paste in chat or Discord, import with one click).
4. **Compare tooltip** (the game's side-by-side with the equipped item) on picker rows; one flag away in `FGT.ShowItemTip`, held back because it makes the tooltip crowded.
5. **Hover preview** of a result on the model before clicking. Held back: your spec says click to equip, and hover swaps would mean a fade per row.
6. **Level filter** (hide items above a level), if you want a "while leveling" use.
7. Karl-approval items: whether the entrances for Molten Core, Blackwing Lair, Onyxia and Naxxramas should also auto-link in ordinary guides (today they only link in planner steps), and whether the Hunter preset should stay behind `/goals testhunterpreraid` or appear for Alliance Hunters in the empty state (it does now).

## Later the same day (Karl's review in Classic Era)

Fixed after Karl's screenshots, all on `main` and synced to the Mac's Era test copy (`_classic_era_/Interface/AddOns/ForeverGoalTracker`, a plain copy, not a symlink; copy changed files again after edits):
- Weapon row: icon then name on one line, in equal cells (three, or four with ammo); long names shorten with "...".
- Picker: one size and place for every slot (under the header, above the weapon row); picking an item or **+ Set** closes it; the item tooltip opens only from the thumbnail, beside the picker.
- Usable filter shows the class's main armor type only. Before level 40 it also shows the type the class wears from 40 (Karl, 2026-10-21, Forever beta: a level 20 Hunter lost Cryptstalker), so leveling characters can plan endgame sets.
- Ammo slot (inventory slot 0) for Hunters, Warriors and Rogues, matched to the planned ranged weapon (arrows or bullets); 28 ammo items added to the database. Paladins, Druids and Shamans see the Ranged slot as **Relic**.

**Open, Karl to decide next session:** most items say "Source unknown" because the client has no loot tables (sources are known in Classic, just not to the addon). Options: import an item-to-boss dataset (Questie or AtlasLootClassic, both GPL), ask Wowhead, or curate raid by raid. Interim idea: change the wording to "Source not added yet · Right-click: Wowhead" (needs Karl's OK, since "Source unknown" is the house wording). Also still pending: removing short-lived conjured items like Andonisus from the database (generator filter on items with an expiry timer).
