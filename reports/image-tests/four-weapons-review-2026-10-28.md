# Four trading-card weapon banners, 2026-10-28

Karl approved the next batch and chose Brutality Blade's first review after
seeing a corrected version. All four are installed.

| Goal ID | Untouched source | Review | Printed artist credit | State |
|---|---|---|---|---|
| `core_hound_tooth` | `Media/artwork/weapon-core-hound-tooth.png` | `Media/final-images/core-hound-tooth-review-2026-10-28-v1.png` | Michael Sutfin | Installed |
| `brutality_blade` | `Media/artwork/weapon-brutality-blade.png` | `Media/final-images/brutality-blade-review-2026-10-28-v1.png`; corrected `Media/final-images/brutality-blade-review-2026-10-28-v2.png` | Jim Nelson | Installed v1 |
| `bloodseeker` | `Media/artwork/weapon-bloodseeker.png` | `Media/final-images/bloodseeker-review-2026-10-28-v1.png` | Ralph Horsley | Installed |
| `blackcrow` | `Media/artwork/weapon-blackcrow.png` | `Media/final-images/blackcrow-review-2026-10-28-v1.png` | Bob Eggleton | Installed |

The sources are World of Warcraft trading cards. Printed artist credits were
read from the source cards. The original source files were not modified by
this work. The reviews are grayscale landscape crops with left and bottom
fades and no card frames or text. Brutality v1 added an animal head absent
from the card; v2 removed it. Karl specifically chose v1, which is installed.

The four installed reviews became neutral 1200 x 900 masters and 512px DXT1
BLPs with ten mips. `Core.lua` maps those four goal IDs and shows their
printed artist credits. `tools/artwork.py` and the runtime manifest list the
masters. The checklist has Done rows and thumbnails. `tools/check.py` passed
after the four runtime mappings, including Lua 5.1 compilation and both
client fixtures. Retained output:
`reports/checks/four-weapons-check-2026-10-28.txt`. The checklist rebuilt 238
thumbnails with no missing files. Native visual review and a full game restart
remain needed.
