# Gold bug icon

The feedback title bar uses `FGT.Icon("bug-gold")` at 17 px.

- Runtime texture: `Media/icons/bug-gold.tga` (64 x 64, RGBA).
- Source copy: `Media/icons/bug-gold-source.png`.
- Untouched generated original: `Media/artwork/ui-icons/bug-gold-generated-original.png`.
- The existing untracked `Media/icons/bug.tga` was preserved.

Built-in imagegen used the user's simple bug silhouette and
`Media/icons/sheet-source.webp` as style references. The prompt requested a
symmetrical front-facing bug with a rounded head, oval split body, two antennae,
six straight legs, faceted chiseled gold, amber recesses, upper-left highlights,
a dark brown outline, and a transparent background. No tile, glow, or text.

Converted with `tools/icon.py` and palette matched with `tools/gold.py`.
Restart WoW fully to see the new texture.
