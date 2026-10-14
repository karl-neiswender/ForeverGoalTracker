# Next release: pop-out tracker

Prepared October 13, 2026. Proposed version: 2.14.0, following 2.13.0.
Planning only. No implementation or live publication is authorized by this document.

## Purpose

Keep the goal a player is working on visible while they play, with the main
tracker closed. It should feel like a small companion to the guide and use
the same saved progress, selected parts and prerequisite rules.

## Decisions Karl confirmed

- One goal at a time in one pop-out window.
- Players can check off steps directly, using the same rules as the main guide.
- The pop-out tracker is the proposed next release's headline feature.

## Proposed first version

These details are recommendations for design review, not additional confirmed decisions.

### Opening and choosing a goal

- Right-click a My Goals card and choose `Pop out`.
- Opening another goal replaces the goal in the existing pop-out.
- Browsing a different goal in the main window does not change the popped-out goal.
- Clicking the pop-out title opens that goal in the main guide.
- Closing the main window leaves the pop-out visible. Escape may close the
  main guide but should not dismiss the persistent pop-out.
- Closing the pop-out keeps the goal and all its progress on My Goals.

### Main-window state while popped out

Karl suggested an empty state for the main window while a goal is popped out.
Proposed treatment for review:

- Replace only that goal's guide area with a calm `This goal is popped out`
  message, its icon/name and a `Bring back` action. Keep the My Goals list usable.
- Selecting another goal shows its normal guide without changing the pop-out.
- `Bring back` closes the pop-out and restores that goal's full guide. Closing
  the pop-out also restores its guide if that goal is currently selected.
- Clicking the pop-out title performs the same Bring back action and opens
  the main window. This supersedes the earlier proposal to open a duplicate guide.
- The popped-out goal remains on My Goals with its live progress.

### Content and appearance

- Small goal icon, goal name, overall goal progress and unfinished steps.
- Start with roughly three visible steps; allow scrolling through the rest.
  Measure width and height in the first in-game prototype before fixing dimensions.
- Use the existing Warcraft font, quiet dark surface, thin etched border and
  gold controls. Retain the established blue treatment for Forever content.
- Keep section or piece names when they explain which mount, class or armor
  recipe a step belongs to. Only selected and client-visible parts appear.
- For armor recipes, show unfinished ingredient checklist lines beneath their
  piece name. Do not invent a new piece checkbox or count ingredients twice.
- Show useful live readouts, such as reputation, skill and collection counts,
  using the same stock and progress meaning as the main guide.
- Keep locked steps visible with their prerequisite explanation. Guide order
  does not mean every goal must be completed sequentially.
- Keep artwork, Tips and the Materials drawer in the full guide. The compact
  window needs to stay easy to read over gameplay.

### Opacity and micro-interactions

Karl suggested adjustable opacity and light opening/closing interactions.
Proposed treatment for review:

- Provide a `Background opacity` slider in a small pop-out options menu.
  Change the backing surface, retaining readable text, checks and progress.
- Save opacity with the pop-out preferences independently of the main window.
  Review the default and slider range over both bright and dark game scenes.
- Open with a short eased fade and a small settling movement; close with a
  shorter fade. Review roughly 0.15 to 0.2 seconds in game before fixing timing.
- Add a restrained checkbox response and smooth progress changes. Match the
  existing grey-rest/gold-hover controls; avoid permanent ambient animation.
- Honor Celebrations: Full uses the small movement and fades, Subtle uses
  fades only, and Off changes instantly. Stop animation drivers when finished.
- Handle rapid open/close and goal replacement without jumps, ghost windows,
  position drift or accidental clicks during a closing transition.
- True live blur of the game behind the window is not a committed feature.
  The inspected Blizzard backdrop implementation supports texture layers and
  alpha, not a live scene blur. No supported addon backdrop-blur API was found
  in this review. Use translucency and soft edges for the proposed treatment.
  Source: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua

### Interaction

- Checkboxes perform the same manual action as their main-guide counterparts.
  Automatic-only rows retain their existing interaction restrictions.
- Preserve item/quest/NPC tooltips and the existing applicable click actions,
  including chat links, Wowhead, map pins and gear or mount previews.
- Clicking a link must never also check off its row.
- A finished row briefly shows its check before leaving the unfinished list.
  The next row must not move into place while the click is still being handled.
- When the whole goal finishes, leave a quiet `Complete` state visible until
  the player closes the pop-out or chooses another goal.
- Reuse the existing goal-complete announcement; do not add another toast or sound.

### Placement and saved state

- Drag using the header; provide a lock-position control and a close control.
- Remember the chosen goal, position, locked state and whether the pop-out is
  open across reloads and logins, on this machine.
- Use one shared saved position for the pop-out window. Future goals reuse it;
  replacing a goal, restoring it to the main guide or reopening the pop-out
  must not reset that position. Keep animation offsets out of saved coordinates.
- Clamp the window to the screen after resolution or UI-scale changes.
- Provide a reset-position action for recovering the window.
- Removing the popped-out goal from My Goals closes its pop-out. Resetting or
  editing its target refreshes it using the same progress as the main guide.
- If the goal is unavailable on the current client, clear the display safely.
- Review behavior during combat, character changes and demo scenes in game.

## Implementation approach

- Add a separate `Popout.lua` module and a narrow shared UI/progress bridge.
  Keep new Core.lua main-chunk locals within Lua 5.1's limit.
- Share row identities, progress computation and manual-change handling.
  Avoid a second rules engine or copies of saved checklist data.
- The current `ToggleStep` ends by selecting its goal in the main guide.
  Separate the progress action from that presentation side effect so a
  pop-out click can update both views without changing the browsed goal.
- The current `RefreshOpenWindow` returns when the main frame is hidden.
  Refresh the pop-out independently after roster scans, automatic progress,
  manual edits, resets, target edits and selected-part changes.
- `FGT.NextStep` returns display text only. Use structured row addresses for
  checkboxes, locks and recipe ingredients rather than parsing its text.
- Reuse existing roster snapshots and debounced events. Do not add background
  polling, independent inventory scans or decorative continuous animations.
- Persist only pop-out preferences. Existing goal IDs, step order and progress
  keys remain authoritative; no goal-data migration is planned.

## Focused refinement work

- Check small-window wrapping, hover/click consistency and Materials behavior.
- Measure memory and CPU with only the pop-out visible and with both views open.
- Fix issues demonstrated by the review; keep unrelated features for later.
- Remove outdated roadmap descriptions for already shipped Materials work.

## Review and release sequence

1. Review a visual mockup and confirm content density and controls.
2. Build the smallest in-game prototype and review it with Karl.
3. Check a simple quest guide, a counter goal, a grouped racial mount, a flat
   armor collection and Tier 3/Tier 2.5 ingredient recipes.
4. Verify shared/manual ticks, automatic completion with the main window
   closed, locked steps, selected parts, links, reset/undo, target changes,
   removal, completion, reload restoration, screen bounds and combat behavior.
   Also review the main-panel placeholder/Bring back flow, saved opacity,
   shared placement across goals and sessions, and interrupted animations.
5. Run `python3 tools/check.py`, including meaningful pop-out regressions.
6. Run Ketho/LuaLS diagnostics for supported clients, prove annotation loading,
   retain results, and fix actionable diagnostics. Review native performance.
7. Prepare the version, concise changelog, What's new, README, roadmap and
   description updates. Add a pop-out demo scene and gallery screenshot.
8. After Karl's final in-game approval and explicit release instruction,
   verify the package, publish, and verify the workflow and public ZIP.

## Later possibilities

Multiple goals, multiple windows, custom goals, guild announcements and the
illustrated update welcome are outside this first pop-out release plan.

## Draft player-facing release line

You can now pop out a goal to follow and check off its steps while you play.
