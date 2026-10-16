# Say LOL and Alliance Dwarf Shaman previews

Karl selected source #2 for Say LOL and #4 for Alliance Dwarf Shaman leveling.
Built-in imagegen edits. Karl approved with "Both are good"; installed.

LOL source: `Media/artwork/Tinker_Burnfizzle_TCG.jpg` (unchanged).
Review: `Media/final-images/say-lol-review-2026-10-15.png`.
Intended mapping: `social_lol`.

Shaman source: `Media/artwork/Barador,_Wildhammer_Timewalker_TCG.jpg` (unchanged).
Review: `Media/final-images/dwarf-shaman-barador-review-2026-10-15.png`.
Intended replacement: `allclasses_dwarf_shaman-banner.blp`; existing mapping
matches faction Alliance, class SHAMAN, race Dwarf. Other profiles unchanged.

Inspected grayscale, right-side framing, subject/hand geometry and baked fades.

Installed 1200x900 masters: `Media/final-images/social/say-lol-master.png` and
`Media/final-images/leveling/dwarf-shaman-barador-master.png`.
Runtime textures: `Media/social_lol-banner.blp` and
`Media/allclasses_dwarf_shaman-banner.blp`, each 512px DXT1 with 10 mip levels.
4:3 preprocessed artwork, existing Dwarf/Alliance/Shaman mapping retained.
Previous Dwarf master preserved. Static mapping, no new per-frame work.
Both textures independently decoded by existing compressor. Restart WoW fully.

Full Era/Forever tools/check.py passed, including LOL mapping, Dwarf Shaman
selection and exclusions for other profiles. Missing-art fallback test now
temporarily removes the LOL mapping instead of assuming it remains blank.
Results: `reports/checks/lol-dwarf-shaman-art-2026-10-15.txt`.

## Exact LOL prompt

Faithful edit of supplied painting into one 4:3 landscape Warcraft addon banner, target master1200x900. Preserve exact original character identity, face, expression, armor/clothes, hands, pose and painterly brushwork; do not redesign. Strict neutral grayscale black and white, moderate contrast, detailed midtones, controlled highlights. Main subject high toward RIGHT with breathing room, quiet left third for UI text, extend matching source setting naturally to left. Bake broad smooth LEFT neutral charcoal darkening strongest at left edge blending without hard vertical boundary. ALSO bake soft BOTTOM charcoal darkening across lowest approximately100px of1200x900 master ending near-black at bottom with no hard strip. Both fades part of artwork. Preserve artist marks. No added text,UI,border,extra characters or unrelated objects. For Say LOL: keep Tinker Burnfizzle's exact wide laughing mouth, exuberant eyes, wild white eyebrows and beard, flame in raised hand and mechanical equipment. Make laughter the readable focus; retain original surrounding devices and warm chaos translated into grayscale. Do not change race or add teeth/hands.

## Exact Shaman prompt

Faithful edit of supplied painting into one 4:3 landscape Warcraft addon banner, target master1200x900. Preserve exact original character identity, face, expression, armor/clothes, hands, pose and painterly brushwork; do not redesign. Strict neutral grayscale black and white, moderate contrast, detailed midtones, controlled highlights. Main subject high toward RIGHT with breathing room, quiet left third for UI text, extend matching source setting naturally to left. Bake broad smooth LEFT neutral charcoal darkening strongest at left edge blending without hard vertical boundary. ALSO bake soft BOTTOM charcoal darkening across lowest approximately100px of1200x900 master ending near-black at bottom with no hard strip. Both fades part of artwork. Preserve artist marks. No added text,UI,border,extra characters or unrelated objects. For Alliance DWARF SHAMAN LEVELING: preserve Barador's exact dwarf identity, face tattoos, braided beard, large original hands, lightning casting pose, armor and straps. Keep both hands and lightning geometry coherent. Retain original rocky and stormy scene, extend subdued background naturally. No armor set redesign or new weapon.
