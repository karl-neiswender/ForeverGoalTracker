# October 13 pop-out handoff

## Current state

Version remains 2.13.0. The pop-out tracker is an Unreleased proof of concept
on main, intended for the next feature release. No release tag or publication
is authorized. The October 12 context report remains the background reference;
this note and the pop-out reports supersede its status for this feature.

Karl tested the prototype and subsequent refinements in game and said they
were working and looking good. The final image-generated arrow replacements
have not yet had a reported in-game check. Fully restart WoW for these textures;
ordinary Lua-only changes use /reload. This Mac checkout is the live addon via
the game AddOns symlink. SavedVariables stay local to each machine.

## Agreed design and final behavior

- One independently selected goal in the pop-out. Browsing the main guide does
  not replace it. Checklist credit, rules, links and locks are shared.
- Pop out only steps. Tips, artwork and Materials stay in the main guide.
  A recessed placeholder preserves the steps footprint so Tips do not slide up.
- Thin draggable header, resize grip and position lock. Header click collapses
  the body; dragging does not collapse it. A single selected group uses its
  group heading as the window heading. Several groups retain their own headings.
- Omit checklist item icons. One header icon supports Ctrl-click whole-set
  preview. Names still provide individual item links and actions.
- Up-right arrow pops out; down-left brings steps back and opens the main guide
  on that goal. X restores steps without opening the main window.
- Match What's new panel styling and short slide-up/fade-in. No bounce or jiggle.
  Full uses motion, Subtle fades only, Off is immediate. Drivers stop when idle.
- Background opacity affects the panel, heading, grime and edge fades, not text.
  Drop-shadow opacity is separate, default 30%. Omit its center to avoid a dark
  rectangle through the transparent window. Progress-strip hover was removed.
- Auto-fit on opening defaults on. Width caps at 520 UI units and height at 70%
  of the screen; longer content scrolls. Actual manual resizing disables Auto-fit
  and saves the chosen size. Settings offers Fit now and Auto-fit on opening.
- Close main on pop-out is optional and defaults off. Opening initially brings
  the pop-out above main; clicking either window brings it forward. Fixed frame
  levels avoid cumulative escalation. Outside clicks dismiss pop-out Settings.
- Position, size, open goal/state, collapse, lock, opacity, auto-fit and close-main
  preferences persist across goals and sessions on that machine.

## Implementation and verification

Popout.lua loads after Materials and before WhatsNew. Core's checklist renderer
accepts a separate view context with independent row/header pools, while retaining
the same progress keys and callbacks. FGT.PopoutUI is the rendering bridge;
FGT.Popout owns the pop-out state. Scans and item-cache refreshes update it even
when main is hidden. Dialogs can be owned by the pop-out. Removing its goal closes it.

The bottom-gradient correction preserves each strip's original vertex-alpha ramp.
Shared helpers retain grime pieces, shadow pieces and edge-fade strip/color/alpha
metadata so the pop-out can adjust backgrounds without fading its content.

Latest substantive Lua pass: 87 behavior sessions across Era and Forever passed.
Ketho/LuaLS reported zero diagnostics; 10,531 annotation load/association records
proved the library actually loaded. Evidence: reports/checks/popout-qol-*.
Icon wiring subsequently passed tools/check.py. Final arrow replacement changes
artwork only. No dedicated Forever annotation flavor or native performance pass
is claimed. Existing verified optional/legacy API exceptions remain documented;
no new broad diagnostic suppression was introduced.

The native automation connection timed out earlier. Karl's tests are the native
evidence available; do not claim an agent-run in-game or CPU verification.

## Icon artwork and correction

Karl explicitly wanted image generation to match the painted icon family. The
first programmatic arrows were replaced using built-in image_gen, with
Media/icons/sheet-source.webp as the style reference and the generated up-right
arrow as an additional reference for its companion. Match thickness, scale,
bevels, grain and gold before treating future icon additions as finished.

Unchanged originals are in Media/artwork/ui-icons/*-generated-original.png;
runtime textures are Media/icons/pop-out.tga and dock.tga. Source copies are
*-source.png. Both have actual transparency, 64px size, 3px padding and the shared
tools/gold.py color adjustment. Original artwork is excluded from release packages.
Prompt and asset notes: reports/checks/popout-painted-arrow-assets.md.

## Remaining before a release

Review final arrows after restarting, bottom fade at zero/low opacity over bright
scenery, auto-fit and manual-size retention, small-window wrapping, Tier 3/Tier 2.5
recipes, multiple groups, placeholder/Tips/Materials, link clicks/tooltips, docking,
lock, reset/undo, removal, reload restoration, interrupted transitions and combat
on both supported clients. Measure memory/CPU with only pop-out and with both views.
Fix demonstrated issues and rerun relevant diagnostics after substantive changes.

Before an explicitly authorized release: fresh required Ketho/LuaLS and local
checks, native review, packaging review, version/changelog/What's new/readme/roadmap
updates, demo/gallery preparation, then publication verification. Do not tag merely
because this prototype's source checks pass.

## Source history

- d29d37d: interactive prototype and shared checklist context.
- 22f8c3c: group header, initial layering, Settings dismissal and opacity refinement.
- 66f783d: auto-fit, click focus, What's new styling, shadow slider and bottom fade.
- ea86682: temporary programmatic arrow icons, superseded.
- cbd05bc: final image-generated painted arrows and preserved originals.

All above commits and artwork were verified on remote main. This documentation
will be committed and pushed as the final session handoff. Continue from the latest
main; do not revive the superseded permanent-above-main layering or dock outline.

Karl wants a project partner who offers judgment and constructive pushback.
Brainstorm ideas are proposals, not automatically accepted requirements. Keep
player copy simple, helpful and clear, and avoid em dashes in communication.
