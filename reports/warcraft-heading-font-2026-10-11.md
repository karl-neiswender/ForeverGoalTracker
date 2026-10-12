# Standard Warcraft headings

Karl requested replacing Cinzel in the addon title, goal titles, Step by
step and Tips headings with the font already used for body text.

The shared title role now uses Fonts\FRIZQT__.TTF, the same native Warcraft
font as the body role. This also updates tabs, Settings, wizard and dialog
headings consistently. Existing sizes, gold colors, shadows and spacing
remain. Shared role/registration helpers are retained; no font selector.

Cinzel and Open Sans originals/licenses remain in GitHub for future studies.
Other studies are excluded from release packaging; credits and README are updated.
No font files were replaced, so `/reload` is sufficient.

The full Lua 5.1 Classic Era/Forever checker passes, including heading/body
font agreement, typography helpers and fallback, links, narrow window
layout, recipes and dependency tests. Output:
checks/warcraft-heading-font-2026-10-11.txt. Native heading appearance still
needs Karl's review. Unreleased source; no version bump or release tag.
This supersedes older handoff references to active Cinzel headings.

## Panel-width follow-up

Karl confirmed the new font looks better but noticed the left panel became
narrower. The heading diff did not directly change anchors or panel dimensions,
but NewTab measured its visible label and the list panel used the combined tab
widths. Smaller label widths therefore widened the right panel indirectly.

Tab widths now use a hidden measurement with the previous Cinzel Bold font,
at the original 12-unit size and with the same rounding/padding. All visible
labels still use Warcraft. The list/detail anchors, window dimensions, bounds
and resize behavior are unchanged. Cinzel Bold and its OFL license remain in
release packaging solely to preserve that original measured footprint. No new
font files; `/reload` is sufficient. Measurement happens twice at startup,
with no timer or per-frame work. Full checker results:
checks/warcraft-panel-width-2026-10-11.txt. Native proportions await review.
