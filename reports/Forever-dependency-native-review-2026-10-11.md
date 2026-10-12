# Forever dependency native review and rollout groundwork

## Native observations

Windows Computer Use selected the running _classic_beta_/WowB.exe window.
Lok'delar was open with preview enabled, 0/8 progress and six locked rows.

- Clicking a locked demon row left progress at 0/8 and showed Locked /
  Complete first with the Stave of the Ancients acceptance prerequisite.
- The native C_QuestLog.IsOnQuest and IsQuestFlaggedCompleted functions
  exist. Read-only calls returned false for Stave of the Ancients (7636)
  being active and The Ancient Leaf (7632) being completed on this character.
  They returned normally without a visible Lua error.
- Karl previously tested the manual leaf/quest/four-demon/reward unlock flow
  and reported that it worked and felt good.

The first coordinate click landed on the leaf after activation changed the
window geometry. The attempted coordinate undo did not clear it. A local
game command restored only that newly set leaf tick, then refreshed preview.
The original 0/8 state was visually confirmed before the locked-click test.
Preview stays enabled and Lok'delar stays selected. No quest, purchase,
combat, reset-all, logout or external chat message was performed.

## Code work

FGT.FOREVER_DEPENDENCIES is a separate explicit table for individually
verified Forever edges. It is EMPTY: no gameplay prerequisites were enabled
by these API/UI observations. Normal Forever looks only at that reviewed
table; /goals testlocks still uses the Classic baseline. Classic Era behavior
is unchanged. This permits gradual rollout without enabling unrelated rules.

New tests prove single-edge deployment, unreviewed sibling/goal availability,
preview separation, accepted/completed quest evidence with race/faction/class
filters, saved manual prerequisite acceptance and completed-child preservation.
The full Lua 5.1 Classic Era/Forever suite passes. Output:
checks/forever-dependency-rollout-2026-10-11.txt.

## Scope finding and remaining checks

The addon deliberately aggregates checklist progress across the roster.
Configured automatic race/faction/class filters are respected. Manual or
historical ticks have no owning-character identity and intentionally remain
valid. Locks therefore describe the shared guide's prerequisites, not proof
that the currently logged-in character can accept a quest. Multiple parent
steps can also be supplied by different characters. Do not describe these
locks as a complete character-eligibility system.

Positive native item/quest events still need checking at the relevant quest
stages. Native false responses establish API compatibility only. Each actual
Forever prerequisite edge, including alternate paths and level requirements,
still needs gameplay/source evidence before adding it to the reviewed table.
No new scan, polling or ongoing update; graph selection is constant-time.
Source only, Unreleased, no version bump or release tag.
