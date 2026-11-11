# Release 2.18.1 (2026-11-11, PC, Claude)

Karl authorized publishing in chat on 2026-11-11 ("Yes, 2.18.1").

- Candidate: `main` at the 2.18.1 release commit (TOC 2.18.1, CHANGELOG, `FGT.WHATS_NEW`, ROADMAP).
  Contents since `v2.18.0`: Forsaken Charger goal (Forever, Undead Paladin), My Goals starting on This character,
  Forever full character names without realms, Forever labels on dungeon weapons, new Forever item sources, Gear
  Planner data for Forever build 70888, Library preview banner fade.
- Not in the candidate: Codex's uncommitted GearSources.lua edits, the eye icon files and the CurseForge drafts.
  Diagnostics ran on the working tree (with GearSources.lua data edits); `tools/check.py` was rerun on a clean
  export of the release commit before tagging.
- `python tools/check.py`: exit 0, 128 sessions.
- Ketho WoW API + LuaLS (`sh tools/run-luals.sh`): no problems found, annotations loaded (14,028 events).
- `tools/copycheck.py`: every rule 0 found.
- Package: no new Lua files or runtime assets; the charger reuses `allclasses_undead_paladin-banner.blp`. The ZIP is
  built only by the tag workflow.
- Native: not checked in game before the tag (charger goal and art, weapon labels, My Goals default). Karl reviewed
  the full-name and preview fade changes earlier.
- Performance: no hot-path changes beyond `FilterOn` reading the view value; no native measurement.
- Gallery: not compared shot by shot. Shots that show My Goals with goals for other characters now open on This
  character in a fresh session, so they may need the view set to All goals on retake. Description: its latest
  releases list needs 2.18.1 (and 2.18.0). Neither has been updated.
