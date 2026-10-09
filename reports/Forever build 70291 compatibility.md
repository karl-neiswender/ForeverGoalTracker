# Forever 1.60.1.70291 compatibility check

October 8, 2026.

- User screenshot shows 1.60.1.70291; local `_classic_beta_/WowB.exe` ProductVersion and WoW `.build.info` confirm that installed build.
- Addon TOC already declares `11509, 16001`, including the 1.60.1 interface. Core identifies Forever with interface >= 16000. No build-specific runtime change or out-of-date bypass needed.
- Updated local Forever test environment's GetBuildInfo build from placeholder 0 to 70291. Legacy GetItemInfo remains unavailable in those sessions, testing the modern C_Item compatibility path.
- Real Lua 5.1 compilation and all existing stub load/session checks pass. Added explicit build-70291 startup, client detection, approved Molten Core banner and logout checks, plus the complete banner/image-fade suite in Forever mode.
- All 17 mapped runtime banner files are present. No new crash report dated October 8 was present when checked; latest local crash report was October 7. This alone does not establish successful live gameplay.

These tests simulate game APIs; they cannot prove that the new client has no API changes. In-game login, rendering, links, progress scanning and logout still need validation on the updated client. No live game controls were used and no SavedVariables were changed.

Re-run with `python tools/check.py`. Detailed local output: reports/image-tests/forever-70291-check.txt. This report and test tools are excluded from addon releases.
