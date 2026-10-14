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

## Latest sizing, focus and style refinement

This section supersedes the first refinement's permanently-above-main ordering
and the original flat black panel styling.

- Removed the progress strip's tooltip and mouse interaction; its count is
  already in the header.
- Fixed the bottom rectangle: `Texture:SetAlpha` replaced each strip's varied
  alpha with one value. The new opacity update uses the original ramp values
  in `SetVertexColor`, keeping the fade shape at every opacity.
- Reused What's new's etched panel, subtle grime, gold heading, forty-unit
  soft shadow and cubic 0.2-second fade with a six-unit upward settling motion.
  Subtle stays fade-only and Off is instant. No new ambient animation.
- Background opacity redraws the panel and grime gradient alpha endpoints.
  Drop shadow opacity is independent (default 30%). The shadow's center is
  omitted so it cannot fill a transparent body with a dark rectangle.
- Auto-fit on opening is enabled by default. It measures the checklist text,
  fits width up to 520 UI units and height up to 70% of the screen, with
  scrolling for larger guides. Manual resizing disables Auto-fit and preserves
  the chosen size for future goals. Settings can fit the steps again.
- Settings adds Fit to steps now, Auto-fit on opening, Close main on pop-out
  (off by default), and Drop shadow opacity.
- Opening a pop-out brings it above the main window. Subsequent clicks bring
  the clicked window forward. Mouse-focus ancestry identifies the owner of a
  child control, and fixed frame levels prevent escalation on repeated clicks.
- Opting into Close main on pop-out hides the main window after opening the
  steps. Dock still opens the main guide. The setting applies on the next pop-out.
- Auto-fit, close-main and shadow preferences are stored alongside position,
  manual size, background opacity and collapse state.

87 two-client behavior sessions and a clean Ketho/LuaLS pass are retained in
`checks/popout-qol-*`. Native review of this iteration remains pending. Use
`/reload`; no new texture/font or TOC changes were added.

## Native review still required

Karl reviewed the initial prototype in game and supplied a Dragonstalker Armor
screenshot. His feedback led to the refinement below. The computer-control
connection timed out during the original attempt to inspect WoW, so no agent
native interaction pass or CPU measurements are claimed.

## Refinement after Karl's first in-game review

- The pop-out uses HIGH strata, 100 frame levels above the main window. Its
  layer is refreshed on opening and when the main window is shown or clicked.
- A global mouse-down listener dismisses Settings outside its panel. The gear
  keeps its normal toggle, and clicks inside Settings continue to work.
- The existing scroll-fade strips now have an opacity multiplier, independent
  of their normal scroll animation. Both fades disappear at zero background opacity.
- For one selected section, the pop-out header replaces its group heading.
  It shows the section name, count, expansion control and one goal preview icon.
  Several selected groups keep their independent headings.
- Clicking the header collapses the body to a 32-unit header; clicking again
  restores the saved expanded height. Dragging has a movement threshold and
  does not toggle expansion. Position lock still allows header clicks.
- Collapsed state is retained on reload. The corner grip hides while collapsed.
- Checklist rows and internal group headings omit item icons in the pop-out.
  The one header icon uses the existing whole-set Ctrl-click preview. Item
  names retain their links and individual preview actions.
- Single-section recipe rows have smaller indents so ingredient text and
  expansion controls still align after the duplicate heading and icons are removed.

The new two-client refinement tests cover these behaviors; retained results
are in `checks/popout-refinement-check.txt` and
`checks/popout-refinement-api-review.md`. This iteration still needs Karl's
native check with `/reload`; no new texture or TOC change was added.

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
