# Gear Planner handoff: October 17, 2026

Latest native review: [male dwarf camera correction](Gear-Planner-native-camera-2026-10-18.md) — verified the four corrected views in World of Warcraft Beta after reload.

Earlier October 18 refinement: [dwarf male focus and smoother transitions](Gear-Planner-dwarf-camera-2026-10-18.md). Native centering remains pending.

Continued October 18: [polish, slot focus and explicit goal tracking](Gear-Planner-polish-2026-10-18.md) supersedes the tracking and camera descriptions below. Native review of that pass remains pending.

Karl approved this as a useful first pass and asked to commit/push to main, then continue tomorrow. No release was requested or published. Public version remains 2.15.2.

## Read first

- [Specification and build plan](Gear-Planner-build-plan.md): confirmed decisions and open scope questions.
- [Implementation and validation history](Gear-Planner-prototype-2026-10-17.md): chronological corrections; later sections supersede earlier camera/catalogue descriptions.

## Current implementation

`GearPlanner.lua`, loaded last in the TOC, uses a small Core tab bridge and existing MaterialsUI/PopoutUI style helpers. The new tab lists only the logged-in character's builds. Named builds autosave; unnamed drafts are session-only. No builds enter My Goals yet, and existing goal progress is untouched.

All 19 native equipment positions appear. Empty slots use GetInventorySlotInfo artwork. The catalogue contains the eight Tier 3 armor pieces and unique class ring for each of nine classes, plus a Tier 1 helm per class (90 entries). Tier 2 was deliberately removed because Karl says it is not available in Forever. Armor data comes from the existing Tier 3 collection; ring IDs/names/icons were verified using Wowhead Classic tooltip data. Acquisition sources remain Classic-based and Unconfirmed on Forever.

Pickers filter by class and slot; choose an item to dress/save immediately while keeping the picker open. Populated slots offer Replace/Unequip. Names face inward beside icons. The unique ring can move between finger slots, never duplicate. All chosen visible armor is redressed together. Slots outside catalogue coverage show no matching results. Clicking outside the selected slot and its picker/menu deselects/closes; it does not change items. Escape closes too.

The native character starts undressed. Racial art covers the right panel behind the name field, uses correct native 318x383 tile proportions, grayscale and goal-style shading. Bottom camera buttons were replaced by main-hand/off-hand/ranged placeholders. Wheel zoom controls distance; clicking Head focuses it. Other selections return to full-body view; body-area camera targets remain future work.

**Important camera correction:** an interior portrait-shaped model frame caused straight cuts through helmets/shoulders. Do not restore it or solve this by restricting zoom. DressUpModel now fills the whole panel drawing area; camera distance compensates for its aspect. Native Swagrid review confirmed intact helmet/shoulder geometry at focused and maximum zoom. Only the outer panel crops the enlarged body.

Latest change: a separate noninteractive gradient veil ABOVE the model but BELOW labels/icons/header, stronger with zoom. This protects names from bright enlarged armor while leaving the center clear. Karl has not yet visually reviewed this final veil strength. Existing background shading remains below the character.

## Validation and next review

Full python3 tools/check.py suites passed throughout, including both client paths, all nine classes, class/slot filtering, independent unequip, unique ring placement, serialization/reload, resize and zoom. Latest retained output: reports/checks/gear-planner-text-veil-lua.txt. Tier 3 workspace LuaLS run returned zero diagnostics with 3,506 Ketho annotation files loaded; subsequent visual changes have not had a fresh annotation pass. See the implementation report for exact snapshot limits. Native review covers the observed dwarf and earlier full/focused geometry, not every race, viewport or final overlay.

Tomorrow, first review the final text veil, full Tier 3 dressing, left/right and lower-row popups, click-away behavior, and names at narrow sizes. Then choose the next build-plan phase with Karl. Remaining work includes broader item/source coverage, crafted-item instructions/materials, My Goals integration, complete build management, per-slot camera framing and further native/performance review. Enchants/enhancements remain a later feature. Do not assume the full feature or a release is authorized by this handoff.

Artwork audit at closeout found no added, changed or ignored pending files under Media/artwork. Source through e788138 was already pushed to main before this handoff. SavedVariables stay local; no progress or files outside this repository were edited for closeout.
