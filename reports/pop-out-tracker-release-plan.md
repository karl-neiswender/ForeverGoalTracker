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
- Pop out the goal's steps area, preserving its existing checklist behavior.
- Use a thin text header with settings and close controls. The header is the
  drag handle; a corner grip resizes the open window.
- Include the ability to lock the window in place.
- Keep a recessed placeholder where the main steps were, preserving their
  layout footprint so Tips do not slide up.
- Provide a visible dock control, distinct from Close.
- Save placement, size, background opacity and lock state across goals and sessions.
- Use restrained overlapping fades and small settling movements, respecting
  Celebrations. No bounce, jiggle or flight across the screen.

## Agreed first-version direction

Karl approved the behavior below during planning. Exact dimensions, opacity
defaults, icon artwork and motion timing still need visual and native review.

### Opening and choosing a goal

- Right-click a My Goals card and choose `Pop out`.
- Popping out another goal replaces the goal in the existing pop-out and
  restores the previous goal's main steps.
- Browsing a different goal in the main window does not change the popped-out goal.
- Add a visible dock icon in the header, with the tooltip `Bring back to main
  window`. Prefer an arrow entering a window over a plain back/undo arrow.
  Dock restores the steps and opens the main guide on that goal.
- Close (X) dismisses the pop-out and restores its main steps without opening
  the main window or changing which goal the player is browsing.
- The header/title is the drag handle, so a normal header click should not dock it.
- Add a small pop-out action beside the main guide's Step by step heading,
  as well as the My Goals right-click entry, subject to visual review.
- Closing the main window leaves the pop-out visible. Escape may close the
  main guide but should not dismiss the persistent pop-out.
- Closing the pop-out keeps the goal and all its progress on My Goals.

### Main-window state while popped out

The empty state is a visual placeholder for the steps area, preserving the layout.

- Replace that goal's steps area with a slightly darker recessed surface,
  soft inner edge shadows, a quiet `Steps are popped out` message and a
  `Bring back` action. Let existing artwork remain subtly visible beneath it.
  Avoid a strong outline or deep bevel.
- Preserve the steps area's layout height when popping out so Tips do not
  move up. Adapt the placeholder to later main-window resizing rather than
  freezing an oversized blank region. Test expanded recipes and long guides.
- Keep the main title, artwork, Tips, Materials and My Goals list usable.
- Selecting another goal shows its normal guide without changing the pop-out.
- `Bring back` closes the pop-out and restores that goal's full guide. Closing
  the pop-out also restores its guide if that goal is currently selected.
- The placeholder's `Bring back` action performs the same docking action as
  the pop-out's header icon.
- The popped-out goal remains on My Goals with its live progress.

### Content and appearance

- A slim header with the goal name in simple text, dock, settings and close
  controls; the body is the goal's scrollable steps area.
- Preserve section headers, expand/collapse behavior, recipe ingredient rows,
  counts and the existing completed-step visibility preference. This replaces
  the earlier proposal for a separate three-step unfinished summary.
- Resize width and height from the bottom-right grip. Text wraps and the
  scroll viewport refits to the available size. Review practical minimum and
  maximum bounds in game before fixing dimensions.
- Try a thin goal progress bar immediately beneath the header in the mockup,
  keeping progress visible while scrolling without making the title bar bulky.
  Final dimensions and placement need visual review.
- Use the existing Warcraft font, quiet dark surface, thin etched border and
  gold controls. Retain the established blue treatment for Forever content.
- Keep section or piece names when they explain which mount, class or armor
  recipe a step belongs to. Only selected and client-visible parts appear.
- For armor recipes, preserve the ingredient checklist beneath each piece
  name and its expansion state. Do not invent a new piece checkbox or count
  ingredients twice.
- Show useful live readouts, such as reputation, skill and collection counts,
  using the same stock and progress meaning as the main guide.
- Keep locked steps visible with their prerequisite explanation. Guide order
  does not mean every goal must be completed sequentially.
- Keep artwork, Tips and the Materials drawer in the full guide. The compact
  window needs to stay easy to read over gameplay.

### Opacity and micro-interactions

- Provide a `Background opacity` slider in a small pop-out options menu.
  Affect both the body background and the header background together,
  retaining readable text, checks, icons and progress.
  Avoid fading the entire parent frame. Review any subtle header contrast
  treatment on bright scenery before adding separate opacity controls.
- Save opacity with the pop-out preferences independently of the main window.
  Review the default and slider range over both bright and dark game scenes.
- Pop out with a short eased fade and a tiny upward movement, overlapping
  the main steps fading away. Reveal the recessed placeholder as they vanish.
- Dock with a short fade and a tiny downward movement on the pop-out,
  overlapping the main steps fading in as the recessed shadow softens away.
  Let the main steps settle by roughly 2 to 3 pixels. If the main window is
  closed, open it on that goal before revealing its steps.
- Close uses a shorter fade and restores the main steps in place if their
  guide is visible. Never open the main window as a side effect of Close.
- Review roughly 0.2 seconds for the whole transfer in game. No bounce,
  jiggle or screen-spanning travel. Motion offsets never alter saved placement.
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
- A finished row follows the existing completed-step visibility preference.
  When hidden, let its check response finish before reflowing the rows. The
  next row must not move into place while the click is still being handled.
- When the whole goal finishes, leave a quiet `Complete` state visible until
  the player closes the pop-out or chooses another goal.
- Reuse the existing goal-complete announcement; do not add another toast or sound.

### Placement and saved state

- Drag using the header, excluding its dock, settings and close buttons. Use a
  bottom-right corner grip for width/height resizing.
- Lock disables both movement and resizing, hides the resize
  grip, and keeps checkboxes, scrolling, dock, settings and close working. Put Lock /
  Unlock in the compact settings menu to keep the header clean.
- Resizing changes space, wrapping and scroll bounds, not font size. Keep a
  readable minimum width/height and sensible screen-fit maximums.
- Remember the chosen goal, position, size, locked state and whether the
  pop-out is open across reloads and logins, on this machine.
- Use one shared saved position and size for the pop-out. Future goals reuse them;
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
   Also review the steps-area placeholder/Bring back flow, saved opacity,
   resizing and wrapping, lock/unlock, shared position/size across goals and
   sessions, completed-step preferences and interrupted animations.
5. Run `python3 tools/check.py`, including meaningful pop-out regressions.
6. Run Ketho/LuaLS diagnostics for supported clients, prove annotation loading,
   retain results, and fix actionable diagnostics. Review native performance.
7. Prepare the version, concise changelog, What's new, README, roadmap and
   description updates. Add a pop-out demo scene and gallery screenshot.
8. After Karl's final in-game approval and explicit release instruction,
   verify the package, publish, and verify the workflow and public ZIP.

## Later possibilities

Multiple goals, multiple windows, collapse-to-header, automatic fading on
mouse leave, custom goals, guild announcements and the illustrated update
welcome are outside this first pop-out release plan.

## Draft player-facing release line

You can now pop out a goal to follow and check off its steps while you play.
