# Release candidate 2.15.1, 2026-10-16

Karl explicitly authorized the minor patch publication after native entrance-link review.

- Exact runtime candidate: TOC and WhatsNew 2.15.1; Lua 5.1 compilation and 102 Era/Forever sessions pass (release-2.15.1-lua51.txt).
- Ketho packaged annotations and LuaLS: no problems; 14,028 annotation load events verified (release-2.15.1-luals.txt/.json). No new game APIs; existing guarded map and safe hyperlink routes preserved.
- Hot paths: entrance name index sorts once; linking runs during text construction, with no per-frame work added. The existing next-step watcher and idle animation behavior are unchanged. Native CPU/taint profiling was not rerun for this patch.
- Karl reviewed the feature in game and supplied Dalaran, Wailing Caverns and Ahn'Qiraj entrance corrections. Automated tests cover map routing, hover guard, explicit link preservation, both client environments and default Stratholme zoom. Live saves unchanged.
- Package simulation: 352 files, TOC modules present, version 2.15.1, map-location icon and runtime assets included, font and artwork licenses retained, ZIP integrity passed. Development files, source artwork and unused fonts excluded. Full manifest in release-2.15.1-package.txt. Final published ZIP will be checked after workflow completion.
- Changelog, What's new, README map description and roadmap updated. Description review: entrance links expand the existing map feature; no author-console description edit required for this patch. Gallery review: existing map screenshot still needs the previously identified in-game retake, and the old Settings image shows 2.15.0. No new screenshot is being presented as 2.15.1.
- Artwork inventory reused: 445 files including ignored originals; no artwork changes in this session. Existing added artwork since 2.15.0 is already committed.
- Separate instruction restructuring (AGENTS.md, CLAUDE.md, current/reference/archive handoffs) remains local and is excluded from this release commit.
