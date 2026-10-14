# Pop-out first native review refinements: API and behavior checks

October 13, 2026, Mac. Version remains 2.13.0; no live release.

- Full `python3 tools/check.py`: 85 sessions passed, including the original
  pop-out tests and new refinement tests on Classic Era and Forever.
- LuaLS 3.19.1 with Ketho WoW API 0.22.3, Lua 5.1, unchanged Mac configuration:
  `Diagnosis completed, no problems found`. No diagnostic categories disabled
  and no new API exceptions introduced.
- Verified Ketho library loading is retained in
  `popout-refinement-annotation-loading.txt`; raw results and output are in
  `popout-refinement-luals-*`. This is the combined client annotation library,
  with client branches exercised by the separate runtime sessions.
- Tests cover layering above the main window, outside/inside/gear Settings
  clicks, fade-strip opacity including zero, the merged single-section header,
  drag versus click, locked header interaction, collapse restoration and full
  set preview without altering progress. Multiple groups retain their headings.
- Rendering remains pooled. Header collapse, layers and opacity update only
  on interaction or refresh. The global mouse listener performs a constant-time
  check and only acts while Settings is shown. No new polling or idle update.
- Karl's screenshot establishes the original native layout and his interaction
  feedback. The revised layout, click handling, opacity and frame ordering
  still need the next native review. In-game CPU is not measured by these checks.
