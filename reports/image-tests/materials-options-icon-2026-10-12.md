# Materials options icon

Generated with the built-in image_gen tool on October 12 at Karl's request,
while Claude was working on backend code. No backend/Materials integration
files were edited as part of this icon task.

## Files and integration

- Untouched generated master: `Media/artwork/materials-options-sliders-2026-10-12.png`.
- Preserved shape reference: `Media/artwork/materials-options-shape-reference-2026-10-12.png`.
- Runtime source copy: `Media/icons/sliders-white-source.png`.
- Runtime texture: `Media/icons/sliders-white.tga`, 64x64, 32-bit RGBA.
- Converted preview: `reports/image-tests/materials-options-icon-64-2026-10-12.png`.

Claude can use `FGT.Icon("sliders-white")` in the materials options control,
tinting the neutral silver/white image with existing grey/gold icon colors.
This is a ready asset, not a claim that the new image is wired into the UI.
New texture files may require a full game restart before native inspection.
The painted silhouette matches the existing raster family; large circular
knobs remain readable at small sizes. No surrounding button or baked glow.

Conversion uses tools/icon.py with the bundled Windows Pillow preloaded
(tools/.py contains a machine-specific incompatible Pillow build). Its temporary
output was directed into the thread's writable visualization folder. Generated
alpha was preserved: master 1254x1254 RGBA, runtime alpha spans 0–255,
2,740 fully transparent pixels and 830 near-opaque pixels. Runtime 64-pixel
preview was visually inspected. No creative image edits were done in conversion.

## References

1. Karl's attached small two-slider glyph: layout only.
2. `Media/icons/sheet-white-source.webp`: painted neutral UI icon family.
3. `Media/icons/refresh-source.png`: silver variant bevel/texture treatment.

## Final generation prompt

Create ONE new transparent PNG raster UI icon for Forever Goal Tracker's
materials options. Reference 1 is ONLY the glyph layout: exactly TWO parallel
horizontal slider rails, each with ONE circular knob. Top knob left of center;
bottom knob right of center. Rails equal length, centered together, with ample
space between them. Reference 2 is the target style: match the existing Warcraft
UI icons' hand-painted, chunky faceted silver/neutral-white metal, crisp beveled
edges, pale upper-left highlights, charcoal lower-right facets, subtle worn
texture and tight dark silhouette outline. Reference 3 reinforces the painted
bevel/edge treatment; match its SILVER version only. Render the new sliders
glyph in that same family, not as a modern flat line icon. Make the rails thick
enough and the two round knobs large enough to remain unmistakable at 14–18
pixels, while preserving the simple two-line silhouette. Straight-on
orthographic, centered on a square canvas, roughly 80% canvas width with clean
breathing room. Single icon only, no sheet, no variations, no gear, no funnel,
no text, no badge or surrounding button/frame, no sparkles, no cast shadow
outside the silhouette, no glow, no gold or colored tint. Background must be
genuinely transparent alpha, including the gap between rails; do not reproduce
the black backgrounds from the references. The neutral silver/white artwork
must be suitable for runtime grey/gold tinting.
