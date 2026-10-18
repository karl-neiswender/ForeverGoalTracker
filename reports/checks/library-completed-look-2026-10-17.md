# Completed Library card refinement, October 17, 2026

Unreleased visual refinement following Karl’s screenshot review.

- Completed cards use a darker background and border, with a dim blue twin for Forever cards.
- Completed title and metadata opacity is 65%; icon opacity is 35%. The card itself stays at full opacity so the Complete button and icon check remain bright.
- Restored the green Complete button and text on full cards and collection subrows.
- Added a centered green check to completed full-card icons. The check is independent of the dimmed item texture. Incomplete cards restore full text/icon opacity and hide the check on layout.
- No changes to goal IDs, progress, selection or saved data. No new events, timers or animation loops.
- Validation: full Lua 5.1 suite retained in `library-completed-look-2026-10-17-lua51.txt`. Existing completion-card regression updated for the darker surface.
- Native review: `/reload`, then compare completed and unfinished Library cards, Forever cards, button hover-to-remove, and completed collection subrows. No release tag or publication.
