# Release 2.17.0 candidate (2026-11-04, PC, Claude)

Not tagged, not pushed. Karl's go-ahead is still needed for the `v2.17.0` tag.

- Candidate: `main` after `847aed9` plus the release-prep commit. TOC 2.17.0, interfaces 11509/16001.
  Includes the uncommitted work found at the start: class Dungeon Set 1 first in goal suggestions
  (Core.lua), `GearData.lua` rebuilt against Forever 1.60.1.70755, new `GearSources.lua` rows.
- `python tools/check.py`: exit 0, run on the final tree.
- Ketho WoW API + LuaLS (`sh tools/run-luals.sh`): annotations loaded (14,028 events). First run found
  6 warnings, all fixed without suppression: `Bars.lua` `NoOp` takes varargs, the tooltip shadow is read
  with `rawget`, `GearPlanner.lua` `selected` is typed `table|nil`. Rerun: no problems found.
- `tools/copycheck.py`: What's new lines pass the verb and length rules.
- TOC lists only files that exist. `Media/artwork` has no untracked or ignored originals.
- Not done: native review of the 2.17.0 changes in live Forever (Era was reviewed by Karl through
  November 3), gallery and description review, performance read of the new progress bar corners.
- Notes: the CHANGELOG folds about 40 single-weapon lines into one grouped line.
