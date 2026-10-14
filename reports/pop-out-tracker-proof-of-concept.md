# Pop-out steps tracker proof of concept

October 13, 2026. Source changes for review, version remains 2.13.0.
No tag or publication.

## Try it

Restart WoW to load the new TOC-listed module. Open a goal and type
`/goals popout`, use the small action beside Step by step, or right-click
its My Goals card and choose Pop out steps.

- The header drags the window. The bottom-right grip resizes it.
- The dock icon brings the steps back and opens the main guide on that goal.
- X restores the main steps without opening the main window.
- Settings contains Lock position, Reset position, completed-step visibility,
  group expansion and a Background opacity slider.
- `/goals dock` docks the window; `/goals popout reset` recovers its position.

Checkboxes affect real goal progress, exactly as the main guide does.
Use demo data or expendable test progress when reviewing checkboxes. Inspect
existing progress before and after a test; do not reset unrelated progress.

## Implemented behavior

One goal is independently selected in the pop-out. The main guide can browse
another goal without changing it. The existing checklist renderer has a
separate display context with separate row/header pools, shared progress keys,
recipe expansion, link actions and prerequisite gates. No second rule engine.

The main steps leave a dark recessed placeholder with soft inner shadows and
Bring back. Its height is retained so Tips do not move up; a main-guide width
change remeasures it. Tips, artwork and Materials stay in the main guide.

The header is thin, with dock/settings/close controls and a three-unit progress
strip below it. Background opacity affects the header and body while content
remains readable. Lock prevents movement and resizing, with controls and steps
remaining interactive. Goal, position, size, opacity, lock and open state are
saved per machine across sessions.

Opening and docking overlap a short pop-out fade with the steps/placeholder
fade. Full adds a three-unit pop-out movement, Subtle fades only, and Off is
instant. A new goal cancels any closing callback. There is no flying window,
bounce, jiggle or new permanent idle animation driver.

Roster scans refresh the pop-out with the main window closed. Item-cache
refreshes redraw its links too. Goal-link and Wowhead cards can appear from
the pop-out with the main window closed. Removing its goal closes the pop-out.

## Automated verification

The Lua 5.1 suite covers Era and Forever load paths, accidental globals and
existing regressions. New behavior tests exercise shared ticks, preservation
of the browsed goal, locks, ingredient keys, handled links, automatic progress
with the main window hidden, opacity, drag/resize/clamping, docking versus
closing, interrupted transitions, delayed completed-row removal and saved
preferences. Output is retained in `checks/popout-proof-check.txt`.

Ketho/LuaLS results and annotation-loading proof are retained in
`checks/popout-proof-api-review.md`. This is a source/API review, not native
rendering or a completed release gate.

## Native review still required

The computer-control connection timed out while attempting to inspect WoW.
No native screenshot, interaction pass or CPU measurements are claimed.

Review first with a simple weapon guide, then an expanded Tier 3/Tier 2.5
recipe. Check the thin header, long names, dock icon, smallest size, wrapping,
scrollbar, zero/low opacity over bright scenery, recessed placeholder and Tips
position, link tooltips and clicks, interruption, lock/unlock and restoration
after reload. Check that the tracker is usable during combat on both clients.

Use the existing performance tools for a native memory/CPU review with only
the pop-out visible and with both windows open. The renderer builds rows only
on refresh; dragging/resizing and transfer drivers stop when finished.

## Remaining design polish

The dock control uses a small native texture outline and arrow for now; its
final visual should be reviewed at actual size. Opening/docking timing and
opacity defaults are prototype values. Progress updates are immediate in the
thin strip; a subtle progress glide and a small main-step settling movement
remain possible refinements after the first native review.
