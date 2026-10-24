# Gear Planner layout redesign (locked 2026-10-23)

Karl approved this layout on 2026-10-23 after a mock review. Nothing is built yet.
The mock is the [Gear Planner three-column mock](https://claude.ai/artifact/NyA5kmWQt3U51YinwVDyhP)
(private canvas, four frames: resting, item picker, enhancement pop-out, sets closed).
It uses sample Hunter pre-raid data, stand-in fonts (Marcellus, Archivo Narrow for Friz)
and a silhouette for the model; colors come from `STYLE` and `C` in Core.lua.

Why: the paper doll hid item names behind hover, the picker covered the model, and
the empty state said nothing. A slot list reads at a glance, and the model stays visible
while choosing.

## Layout: three columns, like My Goals

1. **Left, slot list (300px).** Compact 26px rows in four groups: Armor, Jewelry,
   Weapons, Extras (Shirt, Tabard). Header "Equipment" with "x of 21 filled".
   - Filled row: icon, item name in quality color, then the enhancement, then the
     owned check at the far right edge.
   - Empty row: slot name in small grey capitals ("QUIVER"). Off hand under a
     two-hand weapon reads "OFF HAND · TWO-HAND WEAPON" and is not clickable.
   - Hover on any row: tooltip with the slot name and the existing item tooltip.
   - Owned check (green): you have the item, worn, in bags or in bank. One mark.
   - No legend under the list.
   - Short windows: the list scrolls, with the same scroll bar and bottom fade as
     the scrolling panels on the other tabs. The group headers scroll with the rows.
2. **Center, stage.** Keeps the race backdrop (`DressUpBackground-<race>`, black and
   white), the light behind the character and the pool at the feet.
   - Title: set name in Cinzel gold. Hover shows a pencil on its left and a dashed
     underline; click renames in place, Enter or clicking away confirms, an empty name
     keeps the old one. Chevron beside it opens a set switcher
     (all sets, fill count and item level, gold check on the current one,
     "Manage gear sets…" at the bottom opens the right column).
   - Subline: character name in class color · race and class.
   - No buttons in the stage corners (View in Goals and the stage "…" are gone).
   - Under the model: "‹ Drag to turn ›" turn buttons; below that, a smaller dim line
     "Scroll to zoom · Right-drag to move".
   - Bottom band, two-column grid with matching rows:
     - Left: "SET TOTALS", item stat totals in white (17px), then enhancement totals
       in green (summed per stat, e.g. +51 Agility, +3% Hit), then
       "x of 21 slots filled · average item level · n enhancements".
     - Right (180px): "IN MY GOALS", "x of y pieces owned", the progress bar, and the
       "View in My Goals ›" link under the bar.
3. **Right, My Gear Sets (340px), a drawer like Materials.**
   - Same handle as Materials: grey chevron, 24×48 hit area in the gap, gold on
     hover, "Hide/Show gear sets" tooltip; points right when open, left when closed.
   - Same motion: `M.SLIDE_TIME` 0.7 s, ease-out cubic; closed is a 22px strip with
     the inner-edge shadow; content fades with the slide; the stage widens.
   - Header: "My Gear Sets", "+ New", and a "…" button styled like "+ New"
     (default, gold-edge hover, gold gradient while its menu is open; centered dots).
   - "Plans for <character>" picker, then set cards. Card hover shows Rename (pencil)
     and Delete (trash, red on hover) on the right.
   - "…" menu: New set, New from what I'm wearing, Duplicate selected set,
     Clear selected set, Add a preset from the Library…, separator,
     Remove all sets from My Goals, Delete all sets… (red, confirms).

## Pop-outs beside the slot list

Both open flush against the left column, its full height, 340px wide, gold edge and
drop shadow, over the left part of the stage. Close with ×. The row being edited
turns gold.

They must stay inside the window. On a narrow window the pop-out narrows (down to a
minimum) instead of reaching past the window's right edge; past that minimum it covers
the sets drawer rather than leaving the window. On a short window the result list
scrolls with the shared scroll bar and bottom fade, and the search and filters stay
fixed at the top.

- **Item picker** (click a row): title is the slot name; search; Stat, Type and
  Quality filters; "Gear for levels [min] – [max]" (moved here from the header; still
  saved per set as `build.level` / `build.minLevel`); results with ilvl · type ·
  source and stat; the set's current item tagged gold "Selected"; items you wear
  tagged grey "EQUIPPED"; "Show all". Hovering a result tries it on the model.
- **Enhancement pop-out** (click the enhancement spot): title "<Slot> enhancement",
  search, list only (no filters, no level range). Each entry names its kind and
  source: Enchant · Enchanting, Armor kit · Leatherworking, Scope · Engineering,
  Arcanum · Zandalar Tribe.

## Enhancements

"Enhancement" is the umbrella word (not every effect is an enchant). Only slots that
take one, and only once the slot has an item: head, shoulder, back, chest, wrist,
hands, legs, feet, main hand, off hand (shields), ranged.

- Empty: dashed square with "+". Hover brightens it and says "Add enhancement";
  while its pop-out is open it is gold.
- Set: bright green stat text ("+7 Agi"). Hover shows name, effect, kind and source
  plus "Click: change · Right-click: remove"; click reopens the pop-out (gold outline
  while open); right-click removes.
- Temporary effects (oils, sharpening stones) are out of scope.

## What carries over and what is new

Carries over: wheel zoom with glide (`camera.Glide`), slot focus zoom (`Focus`),
drag to rotate, turn buttons, race backdrop and light, enchant data and
`build.enchants`, filters and target level, Library links, sources.

New work:
- Right-drag to move (pan) the model, the way Blizzard's dressing room does; nothing
  pans today. Confirm the native feel in game.
- Slot list rows replacing the paper doll (`LayoutSlots`, slot buttons).
- Pop-out placement beside the list (`PlacePicker`, `PositionPopup`).
- Sets drawer on the Materials pattern; title rename and set switcher; card actions;
  panel "…" menu; stats band with enhancement totals.

## Things today's planner does that the mock did not show (build defaults)

Found while reading `GearPlanner.lua` before the build. Defaults below; Karl can change them
at review.

- **Add to Goals** (an untracked set): the In My Goals block shows "Not in My Goals yet" and
  a gold "Add to My Goals" button where the bar sits. Once tracked it shows the count, bar and
  "View in My Goals ›". "Remove from My Goals" for one set goes in the sets "…" menu.
- **Status messages** ("Added 9 equipped items", "Moved item to the selected slot"): shown for
  a few seconds in the summary line under the set totals, then the summary returns.
- **Clicking a filled row** used to open Replace / Unequip / goal: it now opens the item
  picker straight away. The picker's header shows the planned item with "Remove" and, when
  the item has one, its Library goal link (Open goal / + Add goal / Track this item).
- **Library set link** ("Library goal: Giantstalker"): added to the stage subline after
  race and class.
- **Welcome card** (no set yet): stays on the stage, left side, as today.
- **Fill from equipped** for the open set, **Undo clear**: in the sets "…" menu.
- **Planning for another character**: the "Plans for" picker in the sets drawer.
- **Requires a higher level**: a filled row's item name gets the red "Lv 62" prefix as today.

## Build order

1. Frame layout: slot column left, stage center, sets drawer right (Materials handle and
   slide), with the sets list, character picker and + New moved into the drawer.
2. Slot rows: groups, names, enhancement spot, owned check, scrolling with the shared fade.
3. Pop-outs beside the slot column: placement and width clamp, item and enhancement modes,
   Selected and EQUIPPED tags, the filled-slot header.
4. Stage: title with hover pencil and Enter rename, set switcher, subline, hint lines,
   right-drag pan.
5. Bottom band: item and enhancement totals, summary, In My Goals block.
6. Drawer details: card Rename and Delete, the "…" menu.
7. Update `tools/gear-planner-tests.lua`, run `tools/check.py`, sync to Era, Karl's review.

## Build status (2026-10-23, PC)

Built in `GearPlanner.lua`, uncommitted. `tools/check.py` passes (109 sessions, Era and
Forever); `tools/gear-planner-tests.lua` gained a layout block (drawer slide and memory, rows,
blocked off hand, owned and EQUIPPED marks, green enhancements and band totals, effect parsing,
cards, switcher, Remove all, Delete all, turn buttons, right-drag, Enter rename). Synced to Era.

Not verified natively: everything visual (sizes, spacing, the drawer slide, the pop-out over
the stage, the band against the character's feet), right-drag direction and speed (the factor in
`Pan` is a first guess), the welcome card on the new stage. Ketho/LuaLS not rerun.

Choices made while building, for Karl's review:
- Clicking the stage (turning, zooming, moving) keeps the item picker open; × or a click
  outside the stage closes it.
- The Library set link sits on its own line under the character's line.
- The stage hint keeps showing (it no longer hides after the first drag).
- The effect text in the game's data runs both ways ("Strength +9", "+3% Hit") and some are
  joined ("Attack Power +10 and Armor +40"); rows show one short effect, or the enchant's name
  when there are several.

## Live review changes (Karl, 2026-10-24, Era)

These replace the matching parts of the spec above.
- Planned enhancement: its icon in a green 1px frame (brighter on hover, gold while its
  pop-out is open); the effect lives in the tooltip. The empty "+" square is unchanged.
  Enchanting enhancements mostly share one spell icon in Classic; kits, scopes and arcanums
  show their item's icon.
- No slot zoom: choosing a slot leaves the camera alone. Another set still returns to the
  resting view. Turn buttons, "Drag to turn" and "Scroll to zoom · Right-drag to move" are
  gone; only the empty-set prompt remains under the character.
- Set totals: a "Set totals" tab at the stage's bottom left (tooltip Show/Hide set totals)
  opens a 220px panel upward, one row per stat (name, items' total in white, enhancements'
  bonus in green), then the summary line. Closed each time the planner opens. Status messages
  sit beside the tab.
- In My Goals: top right of the stage, right-aligned, against the drawer's edge.
- Sets drawer: 260px always (no flexing), always opens. When the stage would drop under
  380px, the drawer opens over the stage's right edge with a shadow instead of closing.
- While the drawer slides, the character's frame keeps one width and only moves; it fills the
  stage again when the slide ends (Karl: smooth in Era, 2026-10-24).
- Second pass: the planned enhancement is 18px like the "+" square, icon inside the frame.
  The slot list, sets list and picker results now have their bottom fade (they passed a 0
  fade height). The model holds the melee weapons or the ranged one, never both: Hunters
  ranged by default, everyone else melee; a stage toggle (bottom right, with Hide/Show helm
  and Hide/Show cloak) changes it per class. The slot being chosen always shows on the model.
  Saved in `prefs.hideHelm`, `prefs.hideCloak`, `prefs.weapons[class]`.
- Third pass: no empty-set prompt on the stage. In My Goals moved to the top of the Equipment
  panel under its heading (status and Add button, or count, "View in My Goals ›" and a bar
  spanning the column), with a rule above the slot groups. Tracked set cards show a 4px progress
  bar along their foot. A hidden helm or cloak gets a red diagonal stroke over its dimmed icon.
- Fourth pass: while the drawer opens over the stage, the name, character line and Library link
  slide with it (`SD.cover`, 0 to 1) from centred to left-aligned 28px in. The stage toggles sit
  16px from the visible edge, like the Set totals tab. Empty totals read "No items added yet."
  with no summary line. Karl will draw `eye-white` / `eye-off-white` for the helm and cloak
  toggles (paths in the artwork reference); the stroke stays until then.
- Fifth pass: the title cluster jumped left as soon as the drawer touched the stage; it now
  moves only as far as keeps its widest line 16px clear of the drawer (`SD.cover` from
  `band.FitTitle`). Bug: renaming a tracked set left its My Goals list card on the old name
  (cards set their name once when built); `FGT.RefreshPlannerGoals` now renames the card.
- Sixth pass: no tooltip on "Start from my current gear"; filling from worn gear no longer
  shows a message (the list of skipped grey items was cut off). Karl confirmed the rename fix
  in Era and approved committing the session.

## Open

- Pop-out minimum width on very narrow windows: pick it in game.

Decided 2026-10-23 after locking: right-drag (not Ctrl-drag) moves the model; Enter
confirms a rename; short windows scroll the slot list and pop-out results with the
shared scroll bar and bottom fade; pop-outs never extend past the window.
Timing (Karl, 2026-10-23): build and test this layout in Era before shipping 2.16.0.
