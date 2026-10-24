# Decision note: locking steps against accidental check-offs (backlog item 7)

Brainstormed with Karl on October 24, 2026. Nothing is built yet. This records what was decided, what is proposed, and what is still open. The idea comes from [the backlog](Backlog-brainstorm-2026-10-24.md).

## The problem

A step can be ticked by clicking anywhere on its row, whether or not the character meets it, and an earned tick can be undone by the same accidental click. A wrong tick can finish a whole goal, which fires the celebration, the chat message and the toast. Of 420 flat steps in 184 goals, 406 have an automatic rule the addon already evaluates, so hand ticking should be the exception.

## Decided (Karl)

1. **Strict locks.** A step the addon can verify and the character does not meet is locked. Locked means a normal click does nothing except explain.
2. **The explanation.** A normal click on a locked step jiggles it (the existing lock motion) and says what the step needs, in as few words as possible, point blank. Karl rejected "Not yet: your best character is level 41, this needs 60" as too wordy. The message states the requirement only, never the character's current state. Proposed lines: "Requires level 60.", "Requires Exalted with Argent Dawn.", "Requires Blacksmithing 300.", "Quest not completed.", "Mount not owned." 
3. **The hint.** After the first blocked click on a step, its tooltip gets a smaller line at the bottom: "Shift-click to unlock". It is not shown before that and not advertised elsewhere, because the aim is for the addon to track things itself.
4. **The escape.** Shift-click on a locked step removes the lock. It does not tick the step. A normal click then ticks or unticks it as usual. The same gesture works on an earned tick that needs removing.
5. **Unlocks are not kept.** An unlock lasts for the game session. It survives `/reload`. It is cleared by logging out and back in, switching characters, or quitting the game. Technique: keep the unlocked steps in the saved data and wipe them on `PLAYER_ENTERING_WORLD` when `isInitialLogin` is true; a reload sets `isReloadingUi` instead and keeps them.
6. **Examples Karl gave.** "Reach level 60" is locked while no recorded character is level 60. Looting the Thunderfury bindings and turning in the quest need level 60 first, so those steps are gated behind it.
7. **Forever.** The "not met" lock stays off on Forever until its rules are verified, as with the current prerequisite locks. The earned-tick lock is safe everywhere because it only trusts what the client reports.

## Proposed, awaiting Karl's yes

- **Phase 1 covers only rules the game can always verify:** level, reputation standing, skill rank, quest flagged complete, and collection items such as mounts. Rules that depend on the addon having watched it happen (boss kills, counters like buffs or summons, statistics) stay unlocked for now, because a kill made before the addon was installed cannot be seen and would wrongly lock the player out.
- **Earned ticks.** Record how each tick happened (earned from evidence or not), internally only: nothing about it is shown to the player, and lock the earned ones. Ticks already in saves have no record: a step that is verifiably met today is treated as earned, and the rest stay as they are. Earned progress is never unticked automatically.
- **Completion guard.** The celebration, chat message, toast and screenshot fire only when every step was earned. A goal finished through unlocked steps still completes, quietly. There is no "checked by hand" line, label or marker anywhere (Karl, 2026-10-24: he does not want that wording). Whether that quiet completion should ask first is still open.
- **Order rules.** Gates such as "bindings need level 60" come from the dependency table in `Dependencies.lua` (10 goals today, Classic Era only). Proposed pattern: an explicit "Reach level N" first step gates the rest of the goal except steps marked parallel (gathering materials). A goal-by-goal review decides the parallel steps, released in batches, starting from the dependency audit in `reports/`.

## Status

Build 1 is done and Karl confirmed it works in Classic Era (2026-10-24): requirement locks for level, reputation, skill and quest steps, the one-line message, the hint after the first blocked click, Shift-click unlock, and unlocks that last a session (kept on reload, cleared at login). Code in `Dependencies.lua` and the step row click in `Core.lua`; tests in `dependency-tests.lua`. Unreleased. Builds 2 and 3 below are not started.

## Build order

1. The lock for the Phase 1 rule types: explanation, hint, Shift-click unlock, session-only unlock memory. Era only.
2. The earned-tick marker and lock, then the completion guard.
3. The order-rule review, in batches.

Steps 1 and 2 are the candidates for before November 4. Test with the existing prerequisite-lock tests and the offline harness; real login and reload behavior needs checking in game.

## Open questions

- Completion guard: finish quietly with no label, or ask first?
- Phase 1 scope: confirm the always-verifiable rule types only.
- The exact one-line wording for each rule type (level, reputation, skill, quest, mount); the proposed lines above follow Karl's rule of simple and point blank.
