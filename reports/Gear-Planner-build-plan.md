# Gear Planner: specification and build plan

Recorded October 17, 2026 from Karl's planning discussion and mockup. Planning only: this document does not authorize implementation or publication. Gear Planner remains the next major feature; patch backlog work is not a prerequisite. Version numbers and dates are not committed.

Karl subsequently authorized the first prototype. See the [prototype implementation and test report](Gear-Planner-prototype-2026-10-17.md) for what is built and what still needs native review. The broader feature and release scope below remain a plan.

## Confirmed product decisions

- Add a Gear Planner tab using the existing two-column layout. The left column lists the current character's gear builds; the right contains the name, equipment slots, model and item picker.
- Builds are per character. Swagrid sees only Swagrid's builds; Barthalemew sees only Barthalemew's. No viewing or editing alt builds in the first iteration.
- A new build starts with no gear on the preview model. Do not fill unused slots with current equipment.
- Use the current character's in-game model and appearance. Use the character's race background, faded on all sides.
- Selecting an empty slot opens item search restricted to that equipment slot. Head search shows head items, for example.
- Clicking a search result immediately equips that target on the preview while keeping the picker open for comparison. This edits the plan, never actual equipment.
- Smoothly focus the camera on the selected gear area. Allow zooming out to the full character and returning to that selected area. Fade the model during zoom transitions. Support rotation.
- Empty equipment slots use the game's native character-panel thumbnails, resolved with GetInventorySlotInfo. Selected targets replace the placeholder with their item icon; Unequip restores the native placeholder.
- Clicking a populated slot offers Replace and Unequip. Unequip clears the planned target and removes its preview appearance.
- Builds can be saved without tracking them. Only the explicit Add to My Goals action adds a build to My Goals.
- A set name is required before adding a build to My Goals.
- Crafted gear is supported. Its goal page explains crafting and required materials.
- Enchants and other verified enhancements are a follow-up after the core planner, rather than first-release scope.

## Mockup reference and interpretation

Karl's supplied mockup shows My Gear Sets on the left, a name field above the model, equipment columns on either side, weapon slots below, a slot picker beside the selected slot and Add set to my goals at the lower right. The model is focused on a dwarf's head, with a faded race background. This description is the portable reference; the original attachment was supplied through temporary clipboard storage.

Recommended refinements, not yet approved: keep slot controls stationary while the camera moves; use item icons rather than checkbox-looking result controls; provide Full character / Focus slot controls; retain full view for nonvisible slots; use a restrained transition fade and an immediate camera change when animation is disabled. Confirm behavior against the addon settings rather than assuming every motion belongs to Celebrations.

## First-release boundaries

Build a manually chosen target set, useful acquisition information, a dressed preview and explicit tracking. Do not expand into automatic best-in-slot recommendations, stat scoring, full simulation, external imports, alternative targets per slot or a general-purpose custom-goal editor. Search coverage must be verified and described honestly; a complete Forever catalogue is not yet established.

## Proposed player flow

1. Open Gear Planner and choose New build or an existing build.
2. Enter a name and select equipment slots in either order.
3. Search within a slot, inspect tooltips and sources, and click items to compare them on the model.
4. Switch between focused and full-character views; rotate to inspect the result.
5. Save for later without tracking, or choose Add to My Goals after naming the set and choosing targets.
6. Return to edit the build or follow its acquisition objectives in My Goals.

The name requirement is confirmed. Requiring at least one target before tracking is recommended. Exact saving, picker-dismissal and tracked-edit behavior remain open below.

## Crafted targets and materials

The goal page must show how to craft selected crafted gear and what materials are needed. Proposed implementation: the finished item is the collection objective, with structured recipe information and the existing Materials drawer supplying ingredient totals. Retain recipe provenance and client applicability. Where verified, include recipe source, profession/skill requirement, quantities and binding restrictions. Use Source unknown for missing sources and Unconfirmed for uncertain Forever rules.

Recommended: owning the finished item satisfies that target even if bought or received from another crafter. Do not make gathering ingredients mandatory for an already-owned target. Distinguish a recipe's profession requirement from a requirement that the owner personally have that profession. Support someone else's crafting only where binding rules allow it. Avoid inventing ingredients from prose. Shared-material aggregation must follow existing stock-versus-recipe semantics, with duplicate recipe requirements counted appropriately.

## Proposed technical structure

Inspect current code before choosing exact filenames or interfaces. Keep the planner in separate modules with a narrow Core bridge; avoid adding substantial main-chunk locals to Core.lua.

- Persist versioned build records under stable character identity, with stable build IDs, names, equipment-slot records and an explicit tracked relationship. Display names are not identifiers.
- Key targets by equipment slot rather than list order. Two ring or trinket slots remain distinct. Leave room in the schema for future enhancements without implementing them now.
- Keep build saving separate from goal activation. Untracked builds must not affect My Goals, overall progress, item-needs tooltips or Materials.
- Integrate tracked builds with existing rule, tooltip, Materials and goal UI through a reviewed adapter. Do not generate unstable IDs when names or items change, or rewrite existing Library goals.
- Use a client-aware item catalogue with provenance for equipment type, restrictions, sources and recipes. Game cache lookups enrich known IDs; catalogue discovery and cache availability are separate problems.
- Load item data asynchronously, with explicit loading/unavailable states and stale-response protection when changing slots or builds.
- Create/reuse the model and picker on demand. Bound and pool result rows, debounce search and coalesce item updates. Camera/alpha animation drivers stop when settled or hidden. Avoid inventory scans, catalogue rescans or model rebuilding every frame.
- Verify model dressing, race backgrounds, rotation, camera framing and fade support on both clients before promising exact APIs. Start with a few race/body shapes; camera framing must not assume dwarf proportions.

## Build phases and acceptance criteria

### 1. Verify feasibility and data coverage

Audit current item tuples, recipe metadata, ownership snapshots, goal activation and dressing-room helpers. Prove slot metadata, uncached item behavior, Forever-only items, model dressing/undressing, camera controls, alpha and available race backgrounds on Classic Era and Forever. Record verified APIs, exceptions, source coverage and gaps in a retained report. Decide the initial catalogue boundary and data update process before building broad search. Do not promise API capability solely from annotations.

### 2. Prove one complete vertical slice

Use one current-character build, a required tracking name, one head slot and a small real catalogue. Start undressed; open head-only search; click successive results without closing the picker; focus the head, return to full view and refocus. Save/reload the build, explicitly add it to My Goals and verify ownership for its intended character. Prove another character cannot see it in the planner. Review the interaction in game before filling out every slot.

### 3. Complete persistence and equipment rules

Implement the chosen save model and build lifecycle. Add equipment slots, restrictions and conflict handling. Cover two-handed/off-hand combinations, dual wield, unique-equipped restrictions, duplicate rings/trinkets, shirts and tabards. Define how quantity and completion work for repeated item IDs. Build deletion, goal removal and target replacement must follow documented rules and preserve unrelated saved progress.

### 4. Expand item search and acquisition guides

Populate the agreed catalogue, enforce slot filtering and implement useful source information. Add verified crafted recipes, Materials integration and unknown-source states. Confirm cached/uncached results, client-specific content and item-link entry if approved. Test that searches never leak results from a previously selected slot.

### 5. Complete visual behavior

Implement the full two-column screen, saved-build list, populated-slot menu, compatible race backgrounds, all-side fades, rotation and camera transitions. Review selected/hover/focus states, long names, large result lists, missing models and window resize limits. Keep equipment controls accessible at every zoom. Explicitly review nonvisible slots and different race/body proportions. Camera movement must not lose the selected item or discard picker state.

### 6. Validate tracking and release readiness

Exercise fresh/reloaded saves, character switching, untracked versus tracked builds, renamed/edited/deleted builds, duplicate items, acquired/consumed/sold items, offline bank snapshots and completed goals that change. Verify item-needs and Materials include only tracked builds. Review main-window, goal-page and pop-out behavior where applicable. Retain targeted regression evidence and inspect performance-sensitive paths; measure native behavior with large catalogues and repeated camera/search interactions.

Before an authorized release, run python3 tools/check.py and the supported-client Ketho/LuaLS gate with proof that annotations loaded. Fix actionable diagnostics and retain results and justified client exceptions. Complete Karl's native review, update release documentation and verify packaging. Do not publish or tag until authorized and the release gate is complete.

## Open decisions before dependent implementation

| Topic | Recommendation / question |
| --- | --- |
| Saving | Karl permits autosave or a secondary Save for later / Save and exit button. Recommendation: autosave named builds with a small Saved status. Final choice remains open. |
| Unnamed drafts | May gear be selected before naming? Recommendation: session draft, with naming required for permanent saving and tracking. Decide reload/discard behavior explicitly. |
| Build management | Confirm New, Rename, Duplicate and Delete actions; decide duplicate-name handling. |
| My Goals visibility | Planner isolation is confirmed; whether tracked sets also hide from other characters' All goals view remains unconfirmed. Recommendation: owner-only visibility. |
| Completion scope | Recommendation: assigned character's equipment, bags and recorded bank. Confirm stale-bank messaging, historical acquisition credit, manual overrides and whether selling an item removes credit. Existing generic account-wide rules must not silently decide this. |
| Editing tracked builds | Recommendation: update the same goal, preserve unchanged targets and recalculate completion/date. Confirm behavior for replacements and empty builds. |
| Removing/deleting | Removing from My Goals should preferably retain the saved build. Decide whether deleting a tracked build also removes its goal and whether recovery is offered. |
| Picker and camera | Confirm dismissal behavior, focus after dismissal, mouse-wheel zoom, rotation retention and automatic framing on slot switches. |
| Item eligibility | Decide class/level/profession filters and whether unusable appearance choices are allowed. Slot-only filtering is confirmed. |
| Search coverage | Decide catalogue scope from phase 1 evidence, result sorting, source filters and optional item-link/ID entry. |
| Crafted acquisition | Confirm crafting oneself versus another crafter, alternative recipes and finished-item ownership credit. |
| Optional slots | Decide whether shirts/tabards are supported and whether they contribute to tracked completion. |

## Follow-up: enchants and enhancements

After the core planner, add a populated-slot action such as Add enchant, using the specific verified enhancement type. Reuse the picker for compatible options. Display the selected enhancement with a small adjacent icon and replace/remove actions. Include sources, materials and a separately defined applied-enhancement completion rule; materials alone do not prove application. Verify Forever support and restrictions. Embellishments are not confirmed scope. Recommended replacement rule: clear the enhancement when replacing its item unless the player explicitly keeps a compatible choice.

## Related planning

- [Public roadmap](../ROADMAP.md)
- [October 17 release planning](Release-plan-2026-10-17.md)

This specification supersedes earlier suggestions to fill untargeted preview slots with current equipment or allow editing alt builds in the first iteration. Update confirmed decisions as Karl resolves the open questions.
