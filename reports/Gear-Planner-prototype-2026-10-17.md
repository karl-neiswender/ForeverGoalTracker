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
