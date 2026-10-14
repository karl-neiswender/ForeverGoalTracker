# Pop-out sizing, focus and What's new style review

October 13, 2026, Mac. Version remains 2.13.0; no live publication.

The full Lua 5.1 compile/load/regression suite passed 87 sessions on the two
supported client paths. New tests cover text/content fitting without progress
changes, manual size precedence, no bar tooltip, opacity ramps, independent
shadow opacity, focus ownership through child controls, bounded frame levels,
opt-in main closing, docking, What's new's fade/rise and saved preferences.

Ketho WoW API 0.22.3 and LuaLS 3.19.1 with the unchanged Mac configuration:
`Diagnosis completed, no problems found`. Annotation loading is verified in
`popout-qol-annotation-loading.txt`; raw output and diagnostics are adjacent.
No diagnostic categories were disabled and no API exceptions were added.
Ketho is a combined client library; distinct Era/Forever behavior remains
covered by the two runtime sessions rather than a claimed Forever flavor.

GetMouseFoci is presence-checked, with a guarded rawget of legacy GetMouseFocus
for clients without it. This determines the top clicked window without a
polling timer. Focus uses fixed relative levels, not incrementing levels.

Auto-fit performs text measurement and one additional render on opening only.
It does not constantly resize after ticks or cached item updates. Manual drag
and resize remain transient. Grime and panel opacity repaint only on preference
changes. Edge-strip opacity preserves the original alpha curve. The shadow
fades with the existing opening driver; no new idle driver was introduced.

These checks do not measure native CPU or prove the visual fix in game.
Karl reported the preceding iteration working, then identified the rectangle
and requested this polish. The current style, sizing, focus and shadow behavior
still need his native `/reload` review. The source is not a release candidate.
