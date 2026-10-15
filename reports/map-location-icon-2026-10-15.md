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
