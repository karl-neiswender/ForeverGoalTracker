# Map location icon

New gold map marker available as `FGT.Icon("map-location")`.

- Runtime texture: `Media/icons/map-location.tga` (64 x 64, RGBA).
- Untouched generated original: `Media/icons/map-location-source.png`.
- Existing `pin` icon remains unchanged.
- Generated with built-in imagegen using `Media/icons/sheet-source.webp` as
  the style reference; converted with `tools/icon.py` and palette matched with
  `tools/gold.py`. Transparent background and center hole retained.
- Restart WoW fully before testing a new texture.

Prompt: Create one upright teardrop map location marker with a circular open
hole and sharp downward tip, matching the reference sheet's painted Warcraft
gold icons: thick sculpted gold, angular chiseled bevels, rich amber recessed
facets, warm upper-left highlights, subtle hammered texture, dark brown outline,
simple silhouette readable at 16–32 px. Front view, centered on transparent
square canvas with padding. No text, map, frame, glow, extra objects or ground
shadow.

## Location off variant

Use `FGT.Icon("map-location-off")` for the disabled-location state.
Runtime texture: `Media/icons/map-location-off.tga` (64 x 64, RGBA).
Untouched original: `Media/icons/map-location-off-source.png`.
Created with built-in imagegen, converted and palette matched with the same tools.

Edit prompt: Preserve the original pin design, framing, transparent background,
hammered gold texture, chiseled bevels and upper-left lighting. Add one bold
straight diagonal gold strike-through from upper right to lower left, extending
slightly past the pin edges. Give the slash matching gold bevels, amber facets
and a thin dark brown contour for readability at 16–32 px. No text, red, extra
circle, glow or other icons.

Direction corrected at Karl's request: slash descends from upper right to bottom
left (`/`). The first version's original is preserved unchanged in
`Media/artwork/icons/map-location-off-first-direction-source.png`. The corrected
variant keeps the same runtime name. Edit used built-in imagegen to change only
the slash orientation, preserving the pin, lighting, framing and transparency.
