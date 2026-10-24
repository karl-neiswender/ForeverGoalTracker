# Release 2.16.0, October 24, 2026

Karl authorized publication on October 24 after weighing publishing now against waiting for Warcraft Forever's launch on November 4. The candidate's evidence is in [release-2.16.0-candidate.md](release-2.16.0-candidate.md): `tools/check.py` (109 scenarios), Ketho/LuaLS with no problems after one nil guard, an offline performance read and the package simulation. Forever was not tested (its beta closed October 23) and the CHANGELOG says so.

## Publication

- Release commit `992d89b` on `main` (the remote matched the local commit after the push), annotated tag `v2.16.0` pushed 2026-10-24 19:09 UTC.
- Release workflow run 40124014633 succeeded (checkout, BigWigsMods packager). `release.json` lists classic 11509 and forever 16001.
- GitHub release v2.16.0 has `ForeverGoalTracker-v2.16.0.zip` (32,205,008 bytes, SHA-256 `5f7d7e4d4b42be7c0a2ddae40b0dada8b9712ff2c58d18da793e6318b21a5cba`) and `release.json`.
- The downloaded ZIP passes integrity, holds 368 files under one `ForeverGoalTracker` folder, and every file matches the tag (text compared after LF/CRLF normalization). TOC says 2.16.0 with both interfaces, every TOC file is present including `PlannerEffects.lua`, the eight `Media/dressing-room` textures are in, and no tools, reports, artwork originals or other development files are included.
- The CurseForge upload line is in the packager log, which needs an authenticated session to read, so it was not read. The public CurseForge files page still showed 2.15.2 (October 18) about two minutes after the tag, which is the expected lag. Later the same day (2026-10-24) the public CurseForge files page listed v2.16.0, uploaded October 24, for both the Forever and Classic game versions, so it is live there. Karl then uploaded the new gallery shots (the Classic Era retakes and the Gear Planner shot) in the author console.

## Next

- November 4: open live Forever first and check the planner (backdrops, drop shadow, weather, Z to sheathe, character picker, Set totals). Ship fixes as 2.16.1.
- The gallery has no Gear Planner image. Capture planner shots on live Forever (a demo scene first), then update the gallery and description.
