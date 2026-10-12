# October 11 live review fixes

Karl confirmed startup no longer errors, concise tips read well and minimum
window bounds look good. His font switch then failed at Core.lua:8383.

- Typography layout called RefreshOverall outside its local scope. It now
  calls FGT.RefreshOverall, the existing export. Regression checks explicitly
  make the leaked global unavailable; the permissive stub previously masked it.
- Automatic step tooltips keep Tracked automatically, useful readouts and
  click hints, but remove the repeated Completes when sentence. Item tooltips
  retain their context-specific tracking explanation.
- Maximum window size is now 110% of the default in each dimension, about
  77% of the screen, reduced from 125% (87.5% of the screen). The approved
  75% minimum and screen-fit safeguards remain.
- First open each session now centers the default window. A persisted
  top-left anchor from another size previously offset its center. Position
  choices remain during that session; Reset still centers the window.

Tests cover switching styles, both window-bounds APIs, scales/screen sizes,
live resizing, first-open centering and same-session position retention.
The stub now chains HookScript callbacks like the game, instead of replacing
the original callback. Full Lua 5.1 Classic Era/Forever suite passes:
checks/live-review-fixes-2026-10-11.txt.

Lua-only changes: `/reload`, then retry Serif/Modern, tooltips and maximum
resize. Native review of these fixes is pending. Unreleased; no release tag.
