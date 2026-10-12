# Window size bounds

Karl approved independent width/height limits at 75–125% of the default.
The baseline stays at 70% of UIParent's screen dimensions, measured in the
window's own units so the Scale setting is respected.

FGT.WindowSizeBounds is the shared source for default size, resize API
bounds, placement, programmatic size clamping and live drag limits. Minimums
round upward and maximums downward. The existing readable floor (520x360)
is retained where it fits; a 60-unit screen margin takes priority on tiny
screens or high scales. Near an edge, available anchor space can further
limit the drag. The drag's screen width now uses the same UIParent/scale
coordinates as placement.

Example at 1920x1080 UI dimensions and 100% addon scale:

| Size | Width | Height |
| --- | ---: | ---: |
| Minimum | 1008 | 567 |
| Default | 1344 | 756 |
| Maximum | 1680 | 945 |

Obsolete fixed maximum constants were removed. Resized dimensions remain
session-only as before; Reset restores the default. No new setting or timer.
Bounds calculations stay constant-time within the existing drag update.

Full Lua 5.1 Classic Era and Forever suite passes. Added behavior checks
cover 640x480 through 3840x2160 screens, scales 70/100/130%, independent
width/height clamping, valid placement, modern and legacy bounds APIs,
click-without-drag, live resize limits and mouse-up session dimensions.
Existing short-window, font, recipe and banner layout checks also pass.
Retained output: checks/window-bounds-2026-10-12.txt.

Unreleased source change, no version bump or release tag. `/reload` loads
it. In-game review should check both font styles, long names/recipes and
Settings at minimum/default/maximum, plus dragging near screen edges.
Stub checks cannot establish native visual quality.
