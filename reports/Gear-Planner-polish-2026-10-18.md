# Gear Planner polish — October 18, 2026

Karl authorized the small UI polish pass, armor-slot camera focus, explicit Add to Goals, and suppressing item tooltips over Replace/Unequip. These changes are unreleased; public version stays 2.15.2.

## Behavior

- Active equipment slots retain their selection rim through hover and item replacement. The picker marks the planned item with a selected background and check. Empty slots are dimmer, item-name widths adapt to the panel, and existing item tooltips provide full names.
- Pickers and action menus fade in over 120 ms. Wheel zoom eases over 140 ms; slot focus eases over 320 ms with a restrained model fade. The existing Celebrations Off choice makes these changes immediate. Animation drivers stop when settled or when the planner closes.
- Armor slots have individual zoom and model-position profiles. Shoulders, wrists, hands and feet target one side. Head focus is nudged down. Nonfocused accessory/weapon slots use the full view. The DressUpModel still fills the panel; no interior clipping frame was reintroduced.
- Clicking a slot hides its tooltip. Its tooltip stays suppressed while that slot's menu/picker is open. Other slots and picker results retain item inspection.
- Naming a draft still saves it, but only Add to Goals lists it in My Gear Sets and activates its collection goal in My Goals. Add requires a name and an item. Added sets keep saving edits automatically. Removing the goal also removes it from the planner's left list; the selected saved build can be added again.
- Personal goals use stable IDs containing a hex-encoded character identity and build ID. They are excluded from the Library and catalogue totals. Rules credit only the owning character's item snapshots. Existing goal cards, guides, completion handling and pop-outs render the generated goals.
- An ordered saved slot/item snapshot remaps checklist credit when a slot is inserted, removed or replaced. Renames retain credit. Goal reconstruction runs during ADDON_LOADED before watched items and normal startup progress are evaluated.
- Picker copy describes the limited catalogue and distinguishes unavailable slots from searches with no matches. Saved feedback fades after edits.

## Verification and remaining native review

`python3 tools/check.py` runs the full Lua 5.1 suite, both simulated clients, all nine classes, and new tracking regressions. The new cases check explicit list/goal activation, Library exclusion, owner-only collection credit, stable IDs on rename, item replacement/removal/insertion credit, fresh-state reload, selection markers, tooltip suppression, full-panel camera positioning and settled animation drivers. Retained output: `checks/gear-planner-polish-lua.txt`.

Workspace LuaLS returned zero diagnostics, with 3,506 unique Ketho annotation files verified loaded. Results (`checks/gear-planner-polish-luals.json`) and loading evidence (`checks/gear-planner-polish-annotations.txt`) are retained alongside that output. This uses the shared installed annotation configuration; it does not claim separate native validation of both clients or authorize a release.

Performance review: user-driven edits check auto rules only for the changed goal, rather than rescanning the catalogue per keystroke. Search result rows and equipment controls are reused. No new inventory scan or catalogue work runs per frame. Camera, save feedback and popup animation drivers stop when finished/hidden. This is source inspection, not a native CPU measurement.

Native review is still required after `/reload`: slot centering (especially one-sided armor across different races/body shapes), the slight downward head nudge, full/narrow window name readability, menu/picker placement, and Add to Goals in both lists. Camera positions are initial tuning values, not verified universal anatomical centers. Full item/source coverage and crafted-material guides remain future work.

Artwork audit: no added, modified, deleted or ignored pending files under Media/artwork. No release tag or publication was requested.
