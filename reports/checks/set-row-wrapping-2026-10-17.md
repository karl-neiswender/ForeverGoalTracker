# Narrow set-row wrapping, October 17, 2026

Karl’s Tier 2.5 screenshot showed wrapped item text extending above its row and into the completion-count column with both side panels open.

- Grouped item labels inherited a vertical-center anchor beside the icon and a right anchor that conflicted with the later explicit width. They now use a single TOPLEFT anchor and an explicit width that subtracts the icon/toggle column and count column.
- The count column reserves its measured text width plus padding, with a minimum 44-unit inset. The row height is still based on the resulting wrapped text height, so lines extend downward without clipping above the icon.
- Applies to the shared grouped-item renderer, including recipe sets, ordinary sets and pop-out item rows. No guide wording, saved progress or requirement changes. No new events, scans or timers.
- Full Lua 5.1 suite passed: `set-row-wrapping-2026-10-17-lua51.txt`.
- Separate focused Era and Forever runs passed the added layout regression: guide widths 220/360/620, a wide count, one top anchor, reserved right column and simulated multi-line row-height growth. The regression lives in `tools/library-polish-tests.lua`.
- Native review: `/reload`, reopen the pictured Tier 2.5 goal with My Goals and Materials expanded, and check long labels plus expanded material rows. Also compare a wide guide and pop-out. Automated font measurements are simulated; native wrapping still needs visual review. Unreleased; no tag or publication.
