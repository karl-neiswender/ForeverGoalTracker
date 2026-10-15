# Horde Warlord cloth background

Source: `Media/artwork/Thysta_Spiritlasher_TCG.jpg`, preserved unchanged.
Review: `Media/final-images/horde-pvp-cloth-review-2026-10-15.png`.
Built-in imagegen edit; Karl approved with "good". Installed for
`pvp_set_cloth_horde` and its class goals through existing PvP resolver.
Master: `Media/final-images/pvp/warlord-cloth-thysta-master.png` (1200x900).
Runtime: `Media/pvp_set_cloth_horde-banner.blp` (512px DXT1, 10 mip levels).
Inspected grayscale, caster/armor framing, hands and baked left/bottom fades.
4:3 preprocessed mapping; no new per-frame work. Full WoW restart required.
Compressor independently decoded runtime. Full Era/Forever `tools/check.py`
passed, including inherited Horde cloth class mappings and image metadata.
Results: `reports/checks/horde-pvp-cloth-2026-10-15.txt`.

## Mark removal

Karl requested removal of the symbol on the rock and an update, then approved
the edited output with "good". Built-in imagegen; original and first master retained.
Review: `Media/final-images/horde-pvp-cloth-review-v2-2026-10-15.png`.
Current master: `Media/final-images/pvp/warlord-cloth-thysta-clean-master.png`.
Same runtime texture and mappings; rebuild map/manifest updated. Existing
compressor independently decoded updated 512px DXT1 with 10 mip levels.
Inspected the removed mark, scene, grayscale and left/bottom fades.

Exact edit prompt:

Precise localized edit: remove ONLY the small pale artist symbol/signature on the front face of the rock near the lower middle of this grayscale banner (about 55 percent from left, 77 percent from top). Fill that tiny area seamlessly with matching dark painted rock texture. Preserve everything else unchanged: exact orc caster, face, skull headdress, armor, hands/flames, robe, cliff shape, background army, framing, grayscale tones and baked left and bottom charcoal fades. No added text or marks. Do not redraw or alter rest of scene.

Exact image prompt:

Faithful edit of original Thysta Spiritlasher TCG painting for a Warcraft addon Horde Warlord cloth set background. Keep original orc caster EXACTLY recognizable: same face, skull headdress, spiky shoulders, red/black robes translated to gray, hands held outward with fire, stance on cliff, original body/armor proportions and painterly brushwork. Do not redesign or bulk up armor. Convert to strictly neutral grayscale with moderate contrast and controlled flame highlights. Make one 4:3 landscape banner, target 1200x900 master. Position intact character/cliff toward RIGHT, high with breathing room above headdress; extend matching original smoky battlefield to left for quiet UI text space. Preserve any artist marks. Bake broad smooth neutral-charcoal LEFT fade strongest at left edge, blending gradually with no hard strip. Also bake soft BOTTOM neutral charcoal fade across approximately lowest 100px, ending near-black at bottom with no hard strip. No added text, UI, borders or new characters. Only grayscale, framing/outpainting and two fades; fidelity to original character and armor is paramount.
