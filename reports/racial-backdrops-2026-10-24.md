# Racial dressing-room artwork, 2026-10-24

Eight new review PNGs in Media/artwork/dressing-room: human-bw.png,
dwarf-bw.png, gnome-bw.png, night-elf-bw.png, orc-bw.png, tauren-bw.png,
troll-bw.png and undead-bw.png. Each is 1143 x 1376, approximately 3.6x the
318 x 383 reference in each dimension. Generated originals are retained with
-generated-original in their names. Final PNGs normalize residual RGB tint to
grayscale using a luminance matrix. No runtime textures or Lua changed.

Source artwork: Blizzard Entertainment racial DressUpBackground textures,
assembled from four tiles per race in the Classic texture mirror:
https://github.com/Gethe/wow-ui-textures/tree/classic/DRESSUPFRAME
The assembled source references are preserved in the references subfolder.
Undead uses the Scourge texture name. These are AI-enhanced derivatives of
Blizzard artwork, not newly attributed original scenes or lossless upscales.

Method: built-in imagegen, one edit per race, followed by grayscale normalization.
Prompt for every race: preserve the supplied scene, camera, layout, architecture,
vegetation, sky and foreground silhouettes; reconstruct blurry textures with crisp
Warcraft painted-game-art detail; neutral black and white; increased contrast,
deep blacks, luminous highlights, separated midtones, readable shadows; preserve
atmosphere and central character space; full-bleed portrait at original aspect;
opaque; no added character, text, logo, border, frame or extra vignette.
Requested approximately 1590 x 1915 or highest supported close portrait size;
tool returned 1143 x 1376 consistently. Fine details are reconstructed and can
differ from the references. All eight visually reviewed; final dimensions and
sampled equal RGB channels checked. No native game test or installation.

## Installation approved and completed, 2026-10-24

Karl approved replacing the Gear Planner backdrops. Runtime assets now live in
Media/dressing-room/{Human,Dwarf,Gnome,NightElf,Orc,Tauren,Troll,Scourge}.tga.
Each is an opaque 1024 x 1024 RGB TGA (24-bit); the layout restores the original
318:383 portrait proportions and covers the panel with centered cropping.
GearPlanner.lua uses one texture rather than four tiles and switches it when
choosing a set or displaying the empty scene for another character. Unknown race
keys fall back to Orc. The 18% opacity, lighting, shades and character behavior
are retained. Selection avoids reloading an unchanged race; no new per-frame
allocations were introduced.

Checks: tools/check.py completed using Windows Lupa Lua 5.1, with updated
wide/tall coverage and eight-race selection regressions. Output retained in
checks/racial-backdrops-lua-2026-10-24.txt. All eight TGAs decoded with the expected
size and RGB format; git diff --check clean. The Windows test dependency is local
under ignored tools/.py/windows-runtime (preload lupa.lua51 from that folder
before running check.py because tools/.py contains incompatible native modules).

Copied only GearPlanner.lua and the eight textures to the plain Classic Era
installation; all nine copies verified by SHA-256. Full game restart required.
Native rendering and performance review remain pending. No commit or release.
