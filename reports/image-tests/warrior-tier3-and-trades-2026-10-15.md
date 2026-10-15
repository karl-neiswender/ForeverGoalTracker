# Warrior Tier 3 and Make Trades previews

Built-in imagegen edits. Karl approved both previews with "good"; installed.

- Warrior source: `Media/artwork/Koringar_the_Heavy_TCG.jpg`.
- Warrior review: `Media/final-images/warrior-tier3-koringar-review-2026-10-15.png`.
- Trades source: `Media/artwork/Junkboxes_Needed_TCG.jpg`.
- Trades review: `Media/final-images/make-trades-review-2026-10-15.png`.

Originals preserved unchanged. Both inspected for grayscale, right-side subject
framing and baked left/bottom gradients. Resize approved masters to 1200 x 900
and compile with existing artwork pipeline after approval. Intended goals:
`tier3_warrior` and `social_trades`.

Approved 1200 x 900 masters:
`Media/final-images/tier-sets/warrior/tier3-koringar-master.png` and
`Media/final-images/social/make-trades-master.png`.
Runtime textures: `Media/tier3_warrior_koringar-banner.blp` and
`Media/social_trades-banner.blp`, each 512px DXT1 with 10 mip levels.
Both use 4:3 preprocessed artwork. Old Warrior texture retained for existing
Dwarf Warrior leveling usage. Rebuild map and runtime manifest updated.
Static mappings only; no new per-frame computation. Full WoW restart required.

Validation: compressor independently decoded both BLPs. Full Era/Forever
`tools/check.py` passed, including updated armor texture expectation, both new
goal mappings, 4:3/preprocessed metadata and unchanged Dwarf leveling selection.
Results: `reports/checks/warrior-tier3-and-trades-2026-10-15.txt`.

## Exact Warrior prompt

One 4:3 landscape Warcraft addon banner, target master 1200x900. Strict neutral grayscale black and white, moderately increased contrast, detailed painterly midtones and controlled highlights. Preserve the source subjects' identity, anatomy, pose, armor, hands, weapons, architecture and any existing artist marks. Place main action high toward RIGHT with breathing room; left third quiet for UI text. Bake a wide smooth LEFT neutral charcoal darkening gradient, strongest at left edge blending naturally without a boundary. Also bake a soft BOTTOM gradient over approximately lowest 100px of a 1200x900 master, ending near-black neutral charcoal at bottom edge, no hard horizontal strip. Both gradients must be part of image. No added text, UI, border, unrelated objects or extra characters. Edit Koringar the Heavy into the Warrior Tier 3 background. Preserve the tauren warrior, horned helmet, distinctive skull-faced Dreadnaught shoulder armor and enormous glowing sword faithfully, translate blue glow into controlled grayscale light. Reframe character toward right, extending original fortress environment naturally into quiet left area. Do not crop away horns or change weapon geometry.

## Exact Trades prompt

One 4:3 landscape Warcraft addon banner, target master 1200x900. Strict neutral grayscale black and white, moderately increased contrast, detailed painterly midtones and controlled highlights. Preserve the source subjects' identity, anatomy, pose, armor, hands, weapons, architecture and any existing artist marks. Place main action high toward RIGHT with breathing room; left third quiet for UI text. Bake a wide smooth LEFT neutral charcoal darkening gradient, strongest at left edge blending naturally without a boundary. Also bake a soft BOTTOM gradient over approximately lowest 100px of a 1200x900 master, ending near-black neutral charcoal at bottom edge, no hard horizontal strip. Both gradients must be part of image. No added text, UI, border, unrelated objects or extra characters. Edit Junkboxes Needed into a Make Trades goal background. Preserve the two existing characters, their armor and the closed wooden chest between them, and the snowy setting. Keep the human viewed from behind and the seated night elf facing him; retain the exchange interaction and hand positions. Reframe both people and chest together on the right two thirds, extend snowy forest naturally into darker quiet left third. Improve clarity gently from the small original while retaining its painted style; do not add coins, extra hands or characters.
