# Forever dependency review

Prepared for Karl's later in-game review. Windows Computer Use found no
running WoW window; no native gameplay, rendering or quest-chain test was
performed. SavedVariables on disk were not edited.

## Result

The lock engine has no Classic-exclusive API requirement. It uses existing
row ticks and the shared roster rules for items, accepted/completed quests,
levels and reputation. The roster already uses C_QuestLog completion and
active-quest APIs when available, with the Era fallback retained.

The disabling condition is Dependencies.lua's classicOnly flag. It is
retained by default because the full prerequisite graph has not been
verified against Forever gameplay. A session-only override is now available:

- `/goals testlocks on`: preview the audited Classic prerequisites in Forever.
- `/goals testlocks status`: report mode and locked-step count for the open goal.
- `/goals testlocks off`: immediately restore normal Forever behavior.
- `/goals testlocks`: toggle the preview.
- `/reload`: discard the preview automatically.

The command does not tick steps, clear progress, add goals or save a new
setting. Normal manual clicks and automatic progress tracking still work.
Classic Era behavior is unchanged.

## Automated checks

Full tools/check.py passes on Lua 5.1, Classic Era and Forever. The same
dependency behavior suite now runs on both clients: graph references and
cycles, blocked clicks, hyperlink precedence, one-to-many demon unlocks,
all-of and any-of rules, completed/owned evidence overriding locks, jiggle
and breakaway motion, reduced/off effects and pooled-row cleanup. Forever
tests also cover commands, progress preservation and default-off after a
fresh session. A C_QuestLog fixture exercises normal startup scanning with
The Ancient Leaf completed and Stave of the Ancients in the quest log,
opening all four demon branches. These are simulated API checks.

Output: reports/checks/forever-dependency-preview-2026-10-12.txt.
No new timer, roster scan or continuous update was introduced. The command
refreshes only the selected guide and counts its locked rows; animation
updates retain their existing bounded durations.

## In-game review

1. `/reload`, open an unfinished Lok'delar goal, then `/goals testlocks on`.
2. Hover/click a locked demon step. Check prerequisite tooltip, lock jiggle
   and unchanged progress. Item/quest hyperlinks must retain their behavior.
3. Complete the leaf handoff/start step when appropriate: all four demons
   should unlock together. The final reward should wait for all four heads.
4. On Thunderfury, either binding should open Examine the Vessel. Gathering
   rows stay available. On Benediction, the Eye of Shadow stays available
   while the peasant event and assembly respect their prerequisites.
5. Test normal, Subtle and Off celebrations; switch goals during animation.
6. `/goals testlocks off` clears locks immediately; `/reload` also ends preview.
   Do not reset real progress just to create a locked test state.

The existing audited set also covers MC, BWL, Naxxramas, Shadowforge Key,
UBRS Key and both Onyxia chains. Inspect these separately before default
activation. This change does not add the withheld audit proposals or new
Forever-only chains.

## Quest-data limitation

The public Forever database lists [Attunement to the Core](https://www.wowhead.com/forever/quest=7848/attunement-to-the-core)
and [The Ancient Leaf](https://www.wowhead.com/forever/quest=7632/the-ancient-leaf).
Their listings support quest availability, not every prerequisite edge or
live behavior. Classic source audit remains reports/Goal step dependency
audit.md. Default activation awaits the actual Forever review; no release
tag or publication was made.
