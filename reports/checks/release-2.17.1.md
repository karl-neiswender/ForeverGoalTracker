# Release 2.17.1 (2026-11-07, PC, Claude)

Karl authorized the release in chat on 2026-11-07 ("we are good to release to CF").

- Candidate: `main` at the 2.17.1 release commit. TOC 2.17.1, interfaces 11509/16001. Contents since
  `v2.17.0`: Taldramir goal, Forever build 1.60.1.70862 Gear Planner data, Cozy Sleeping Bag goal
  with linked quests and note objects (Npcs.lua objects and faction spots), Coldflame Saber goal.
- Not in the release: Codex's uncommitted Core.lua edit that hides realm names on Forever.
- `python tools/check.py`: exit 0 on the final tree (includes the new Cozy Sleeping Bag sessions).
- Ketho WoW API + LuaLS (`sh tools/run-luals.sh`): no problems found, annotations loaded
  (14,029 events).
- `tools/copycheck.py`: every rule 0 found.
- No new runtime files; TOC load order unchanged.
- Gallery: nothing to update (no changed screens shown in the gallery). Description: its latest
  releases list can gain 2.17.1 when Karl next edits the CurseForge page.
- Not done: native review in live Forever of the two new goals (Karl saw the sleeping bag goal load
  in game before its links were added).
