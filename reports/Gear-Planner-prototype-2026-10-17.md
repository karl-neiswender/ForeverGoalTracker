# Gear Planner prototype: October 17, 2026

Unreleased source prototype, implemented at Karl's request. No release tag or publication authorized.

## Implemented

- Gear Planner tab with the existing tab styling and separate two-column content.
- Current-character builds in `ForeverGoalTrackerDB.gearPlanner.characters[Name-Realm]`, version 1. Stable numeric IDs and a per-character selected-build ID.
- New builds start as empty, session-only drafts. Naming a draft saves it automatically; subsequent name/item changes autosave. No separate Save button in this prototype.
- Current-character DressUpModel, undressed initially; native race dressing-room background quadrants with four edge fades.
- Head-only picker containing two sample helms for each of the nine supported classes: Tier 1 and Tier 3 entries copied from existing Library/Data tuples. This is not a full catalogue or newly verified Forever loot data. Sources are Classic-based and carry an Unconfirmed in Forever tooltip notice on Forever.
- Result clicks immediately try on/save the target and keep the picker open. Populated Head slot offers Replace and Unequip. Unequip affects only the build.
- Full character and Focus head controls, eased portrait zoom with a temporary model fade, mouse-wheel zoom and drag rotation. Celebrations Off uses an immediate transition.
- Independent planner width avoids inheriting the collapsed goals rail or Materials drawer allocation. Settings and existing tabs hide the planner.

No My Goals activation, ownership completion, crafting recipes, other equipment slots, enchant selection, build deletion/duplication or broad catalogue discovery is implemented yet. Existing goal progress is untouched. Names are required for initial persistence; the final naming/validation policy for tracked builds remains future work.

## Verification

- `python3 tools/check.py` completed with exit 0. Includes Classic Era and Forever planner tests for draft naming, autosave, stable identity, per-character isolation, replacement, unequip, keeping search open and tab switching. An additional saved-build check verifies serialized data survives the next simulated reload.
- [Retained Lua check output](checks/gear-planner-prototype-lua.txt).
- LuaLS 3.19.2 with Ketho 0.22.3 completed the workspace check with zero diagnostics using `reports/checks/release-2.11.1-luals-config.json`. [Results](checks/gear-planner-prototype-luals.json) and [3,506 loaded-annotation proof](checks/gear-planner-prototype-annotations.txt) retained. This is the shared annotation configuration, not a separate proof of each client's native runtime or a completed release review.
- Performance inspection: result catalogue is only 18 records, filtered to two for the character's class; saved-build rows are reused; no scan or model rebuild occurs on idle frames. Rotation updates run only during dragging; camera updates stop when settled or hidden. Native frame cost is unmeasured.
- Native review remains pending. The available WoW window was at a Retail login screen, so it could not establish Forever model, camera, background or layout behavior. Do not call these visuals verified from the stub or LuaLS results.

## Karl's native test

1. Restart the Forever client to load the new TOC module, then open `/goals` and Gear Planner.
2. Choose New build. Verify the character has no preview gear and the race background appears.
3. Enter a name. Verify it appears in the left list.
4. Click Head. Try both test helms. Verify each appears immediately, the picker stays open, and head focus frames the character correctly.
5. Use Full character, Focus head, mouse-wheel zoom and drag rotation. Review fade strength, head framing and clipping for the character's race.
6. Click the populated Head slot, then Replace or Unequip. Verify actual equipment and My Goals are unchanged.
7. Switch tabs, reopen the window and `/reload`. Verify the named build and head target persist.
8. Log into another character. Verify the first character's builds are absent. Review Settings, collapsed goals rail and open Materials before switching to Gear Planner.

Camera tuning across race/body proportions, texture quadrant fitting, missing-item/model behavior and narrow-window layout are the next native review priorities. The public version remains 2.15.2 until an authorized release.

See the [full build plan](Gear-Planner-build-plan.md) for confirmed scope and subsequent phases.

## Catalogue correction

At Karl's request, replaced all nine Tier 2 sample helms with Tier 3 helms because Tier 2 is not yet available in Forever. Tier 1 remains included. Existing saved targets are not rewritten; use Replace to choose a supported test helm. Native asset availability remains to be checked in game.

Validation after the catalogue correction: `python3 tools/check.py` passed (exit 0), including both client planner regressions updated for Dreadnaught Helmet. [Retained output](checks/gear-planner-tier3-lua.txt). The earlier LuaLS report applies to the initial prototype snapshot; this catalogue-only correction did not receive a fresh annotation pass.

## First screenshot review: preview framing correction

Karl's screenshot showed the race background stretched at its right-hand join and the character/helm clipped by the wide model viewport. Corrected the native background assembly using [Blizzard Classic DressUpFrames.xml](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_CharacterFrame/Classic/DressUpFrames.xml): left/right widths 256/62, top/bottom heights 255/128. All tiles share one uniform cover scale, centered and cropped inside a child frame; wider, darker edge fades blend the image into the panel. No raster assets were changed.

The model now uses a centered portrait-shaped viewport with top/bottom margins, rather than filling the entire wide panel. Full view adds camera distance; head focus eases toward portrait zoom. The set-name field is centered and capped at 340 units, and the save status is a small Saved label. These changes preserve build data and selected items.

Geometry regressions cover wide and tall windows, native tile aspect ratios, the narrow right column and model margins. Full Lua suite passed before the final clipping-frame adjustment; targeted Era/Forever planner regressions passed again after that adjustment. Native review is still required for final helm/feet framing, texture joins and the focus transition; the computer-use screenshot attempt timed out during this pass.

Framing-check evidence: [full Lua output](checks/gear-planner-framing-lua.txt), [LuaLS zero-diagnostic results](checks/gear-planner-framing-luals.json), and [loaded-annotation proof](checks/gear-planner-framing-annotations.txt). LuaLS ran during this pass; the final clipping change adds only a child Frame for the already-checked textures. No release gate or native validation is claimed.

## Native empty-slot thumbnails

At Karl's request, empty Head now uses the native character-panel thumbnail from `GetInventorySlotInfo("HeadSlot")`. Selecting a helm replaces it with the item icon; Unequip restores the thumbnail. `FGT.GearPlannerSlotTexture(slotName)` provides the same convention for future equipment slots. Head remains the only implemented equipment slot in this prototype.

Validation: `python3 tools/check.py` passed (exit 0), including both client planner regressions. [Retained output](checks/gear-planner-slot-icons-lua.txt).

## Full-panel background and safe focus range

Karl's next screenshot established that the earlier focus setting still clipped the helm. Background/modelArea now fills the entire right panel inside its border, including behind the name field and bottom controls. The name, label and Saved status sit on a raised transparent header layer. The model retains its own inset viewport, reserving header/footer room independently of the background.

Head focus and mouse-wheel zoom now share a maximum portrait zoom of 0.55, replacing 0.9/1.0, with camera-distance scale held at 1.3. The previous zoom-dependent distance reduction compounded the close-up. Model height reserves 140 units within the full-panel background; center is offset down 20 units. This is a conservative initial framing, not a verified fit for every race.

Native review succeeded by selecting the exact beta application path rather than the ambiguous WoW application name. After reloading and opening `/goals`, Swagrid's complete body, helmet and feet were visible in full view, and the race background extended behind the name field. A subsequent native focused view showed the entire helm with clearance at the top and intact shoulders; lower-body cropping during focus is intentional. Saved build/items were unchanged. Other races, resize extremes and final desired close-up strength remain review items. No release was published.

Validation: `python3 tools/check.py` passed (exit 0), including Era/Forever planner regressions and bounded wheel zoom. [Retained output](checks/gear-planner-full-panel-lua.txt). No fresh LuaLS run was made for this unreleased visual adjustment.

## Armor placeholders, deeper zoom and click-away dismissal

At Karl's request, expanded the layout to the native 16 armor/accessory positions: Head, Neck, Shoulders, Back, Chest, Shirt, Tabard, Wrists, Hands, Waist, Legs, Feet, two Fingers and two Trinkets. Each uses GetInventorySlotInfo artwork; only Head has item choices. Other positions remain empty, selectable placeholders with a tooltip explaining that item selection comes later. Columns shrink with panel height to keep all eight rows above the bottom controls. The Head picker opens beside its slot rather than covering the placeholder column.

Clicking outside the selected slot and its open picker/menu deselects it and closes the panel, without changing its saved item or forcing the camera to full view. Picker result clicks still keep the picker open. Escape also deselects. A GLOBAL_MOUSE_DOWN listener is registered only while the planner is shown; no idle polling was added.

The earlier conservative 0.55 portrait cap is superseded: automatic head focus uses 0.75. Wheel zoom reaches native portrait zoom 0.8, then reduces camera-distance scale from 1.3 toward 0.9 for an additional close-up. Full view remains portrait zoom 0 with distance 1.3. Players can zoom out again with the wheel or Full character. Extreme close-ups intentionally allow the body to leave the viewport; native review of framing across races remains necessary.

Validation: full `python3 tools/check.py` passed (exit 0), including Era/Forever planner regressions, click-away dismissal, the placeholder count and extended wheel zoom. [Retained output](checks/gear-planner-slots-lua.txt). The new slot layout and deeper zoom still need native visual review. No fresh LuaLS diagnostics or release publication are claimed for this iteration.

## Model-frame clipping root cause

Karl's close-up screenshot showed straight horizontal/vertical cuts at the interior portrait frame. The earlier narrower viewport was the clipping boundary, not a solution to the camera framing. Removed that internal model rectangle: DressUpModel now anchors to the entire modelArea/right-panel interior. Layout never shrinks the model frame. Camera distance compensates for the panel aspect ratio, preserving the full-character view while retaining the closer focus and wheel zoom.

Native Forever review on Swagrid confirmed complete helmet and shoulder geometry at portrait zoom 0.75, then at portrait zoom 0.8 with the maximum wheel-distance reduction (0.9 times the aspect compensation). The previous straight cuts inside the panel were absent. The enlarged body can extend beyond the outer panel at close zoom, as intended; the entire model remains clipped to the outer panel. Name and control overlays remain above the model. No item, build or goal progress changed. This native check covers the observed dwarf/client, not every race or viewport size.

Validation: `python3 tools/check.py` passed (exit 0), including Era/Forever planner tests updated to reject a smaller interior model frame during resize. [Retained output](checks/gear-planner-drawing-area-lua.txt). No fresh LuaLS run or live release is claimed for this correction.

## Item names and bottom weapon slots

Karl requested inward-facing item labels: populated left-column slots show the name to their right, and populated right-column slots show it to their left. Added a shared itemName label to every slot with the appropriate anchoring/alignment, bounded width and no wrapping. The implemented Head picker fills its label in item-quality purple; Unequip clears it. Other slots remain empty and therefore have no item-name text.

Replaced Full character / Focus head buttons with native empty Main Hand, Off Hand and Ranged slots at the bottom center. All 19 equipment positions are now represented. These three slots remain placeholders with no weapon picker yet. Clicking Head focuses it (including when populated); mouse-wheel zoom remains the way to zoom out or move closer. Rotation, zoom limits, click-away behavior and build data are otherwise unchanged. The rotation/zoom hint sits above the weapon row.

Validation: full `python3 tools/check.py` passed (exit 0); final targeted planner regressions passed on simulated Era and Forever after adding focus-on-populated-slot behavior. Tests check populated/cleared name text and all 19 slots. [Retained full check](checks/gear-planner-item-labels-lua.txt). Native label overlap and bottom-row sizing still need visual review; no fresh LuaLS run or release is claimed.
