# Painted pop-out arrows

Built-in image_gen, October 13, 2026. Style reference: Media/icons/sheet-source.webp.
The generated up-right arrow was also the geometry reference for its companion.

Prompt set: one straight thick diagonal arrow pointing up-right for Pop out;
one companion pointing down-left for Send back. Match the original Warcraft
icon sheet's chunky thickness, broad hand-painted bevels, top-left pale yellow
highlights, rich gold shadow facets, hammered grain and thin dark contour.
Preserve proportions and lighting direction. Transparent background; no text,
surrounding window, second arrow, glow or extra symbols.

Unchanged generated originals are in Media/artwork/ui-icons/
pop-out-generated-original.png and dock-generated-original.png.
Full-resolution source copies are Media/icons/pop-out-source.png and
Media/icons/dock-source.png. Runtime assets are the matching .tga files.

Verified actual alpha transparency, then cropped to the alpha outline and
fitted to 58px inside a 64px texture with 3px padding, like the original sheet
pipeline. Uncompressed 32-bit BGRA TGAs use top-left origin. tools/gold.py
normalized hue to 45 degrees and mean saturation to 0.80. Visually compared
with gear, close and undo at 64px and 13px. No Lua behavior changes.
In-game review requires a full restart because textures are cached.
