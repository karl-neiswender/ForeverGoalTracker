# Dungeon entrance links, 2026-10-16

- Dungeon names in linked step/tip text use the existing map-location icon and soft gold map-link color. Clicks reuse MapLinkClick and its banner/world-map fallback. Existing explicit item, quest and goal links take priority.
- Added 19 Classic dungeon outdoor approaches, with shared Upper/Lower Blackrock Spire aliases. Cave/mountain approaches are explained in tooltips; these are not indoor navigation. Forever locations say Unconfirmed.
- Coordinate facts checked against the maintained primary source: https://github.com/callie-g/HandyNotes_DungeonLocations-classic/blob/main/classic.lua . No external implementation code or artwork copied.
- Lua 5.1 compilation and 102 sessions passed, including new Classic Era and Forever link regressions. See dungeon-links-2026-10-16.txt.
- Ketho/LuaLS: no problems found; 14,028 Ketho annotation load events verified. See dungeon-luals-2026-10-16.txt and .json. An initial diagnostic run used a metadata directory inside an ignored folder; rerunning with the installed compiler cache restored standard type annotations.
- No per-frame work added. Name matches are sorted once, then applied when display text is built.
- Native rendering, clicks, entrance positions, taint and CPU not tested. Use /reload and review in game. SavedVariables unchanged. No commit, push or release.
- Closeout artwork inventory: 445 files recursively, including ignored originals; artwork unchanged.
