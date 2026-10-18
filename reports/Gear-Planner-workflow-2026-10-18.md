# Gear Planner set workflow refinement

Karl requested a redesign of the clunky left-panel actions and the naming/add/remove/clear flow.

## Interaction

- Sidebar is navigation: My Gear Sets, character name, compact + New in the heading, then the added set list. The list begins 70 UI units higher. An empty list explains how to add a set.
- The set name and Add to Goals share the editor header. Add is gold when items are selected, unavailable for an empty set, and focuses the name field if the set is unnamed. Adding remains explicit.
- A quiet status line distinguishes Draft / Not in Goals from In My Goals / Changes saved. The old FontString SetScript calls were invalid in the native client; the replacement uses no label animation or update callback.
- The ellipsis menu contains Rename, Clear items (changes to Undo clear), and Remove from Goals when applicable. Clicking outside closes it.
- Clear preserves a local snapshot of slots and collection credit for Undo until selecting another set. Removing from Goals removes the active goal and sidebar row while leaving the current set editable; Add restores its stable goal ID and progress. Neither action deletes the set.
- Blank edits to an added set's name restore its saved name on focus loss.

Existing per-character named draft autosave is retained. Drafts are not listed in the sidebar, following Karl's earlier explicit-add requirement. No permanent delete was added.

## Verification

- Native review in World of Warcraft Beta on Swagrid: sidebar/header, status line and menu; Clear items removed the preview targets and Undo clear restored all original Cryptstalker pieces. Explicit Add created the sidebar row and saved status; Remove from Goals removed the row and restored the draft/Add state without changing any pieces. The initial unadded state was restored after testing.
- `python3 tools/check.py` passed, including new clear/undo, remove/re-add and blank-rename checks on both clients. Full output: [workflow Lua checks](checks/gear-planner-workflow-lua.txt).
- Performance: no new ticker, model update, bag scan or event registration. Status no longer runs per frame. Goal rebuilds use the existing event-driven refresh bridge.
- Artwork audit: no pending or ignored changes under Media/artwork. No release/tag.

Fresh Ketho/LuaLS run finished with zero diagnostics after fixing two actionable annotation warnings (tooltip color arguments and an explicit selected-set nil guard). The configured Ketho 0.22.3 library loaded 3506 unique annotation file URIs. Retained [diagnostic results](checks/gear-planner-workflow-luals.json) and [run output / annotation proof](checks/gear-planner-workflow-luals.txt).
