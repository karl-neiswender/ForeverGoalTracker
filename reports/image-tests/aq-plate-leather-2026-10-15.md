# AQ plate and leather background previews

Sources preserved unchanged:
`Media/artwork/SavinLightguard.jpg` and `Media/artwork/Telrander_TCG.jpg`.
Built-in imagegen edits. Plate preview:
`Media/final-images/aq-plate-review-2026-10-15.png`.
Intended for `set_tier25_paladin` and `set_tier25_warrior`.
Leather intended for `set_tier25_druid` and `set_tier25_rogue`.
Karl approved both with "both good", then requested a shoulder overlap fix.
Plate approved for Paladin/Warrior. Leather rejected after shoulder correction:
Karl noted it did not match the original. Leather mapping withdrawn; new faithful
edit in progress. Druid/Rogue retain existing artwork until approved.
Existing Hunter image and other AQ classes remain unchanged.
Initial leather generation failed with network error; retried with built-in tool.

## Exact leather retry prompt

Edit supplied Telrander painting into ONE 4:3 landscape Warcraft addon banner shared by AQ40 Genesis and Deathdealer's leather sets, target master 1200x900. Preserve exact male night elf in ornate insect-like armor, masked helmet, beard, original heavy hammer in one hand and other raised fist, with huge spectral roaring saber cat behind him. Preserve identity, armor design, hands, pose, hammer geometry, spectral cat face and fangs, and existing artist mark. Strict neutral grayscale black and white, moderately increased contrast, painterly midtones, controlled highlights. Reframe night elf and spectral cat grouped high toward right with breathing room above ears; extend original haunted forest naturally into quiet left third for UI text. Bake wide smooth LEFT neutral-charcoal darkening strongest at left edge blending naturally without hard vertical boundary. ALSO bake soft BOTTOM darkening over approximately lowest 100px of a 1200x900 master ending near-black neutral charcoal at bottom edge without horizontal strip. Both gradients in artwork itself. No added text, UI, border, extra characters or unrelated objects.

## Exact shoulder correction prompt

Precise localized correction to this exact grayscale painting: the warrior's shoulder armor spike on IMAGE RIGHT, directly beneath the spectral saber cat's lower jaw, must be entirely IN FRONT OF the cat. Restore the continuous sharp triangular shoulder spike projecting diagonally up-right from the ornate right shoulder pauldron, with its metal edge and face clearly occluding the cat's chin/neck behind it. The cat is a background spirit behind the entire character and shoulder armor. Fix only that small depth-order overlap; do not move or redesign the cat, armor, spike or character. Keep all other content unchanged including composition, face, hammer, hands, forest, artist mark, grayscale contrast, left/bottom baked fades and dimensions. No annotation circles, added text, UI or borders.

First leather review: `Media/final-images/aq-leather-review-2026-10-15.png`.
Rejected correction: `Media/final-images/aq-leather-review-v2-2026-10-15.png`.
Rejected technical files preserved in `Media/final-images/rejected-aq-leather-2026-10-15/`.
Approved plate master: `Media/final-images/tier-sets/aq40/plate-savin-master.png`, 1200x900.
Installed runtime: `Media/set_tier25_plate-banner.blp`, 512px DXT1, 10 mip levels.
Mapped at 4:3 with preprocessed=true. No new per-frame work.
Full Era/Forever checks passed after withdrawing leather, including all nine AQ class image mappings;
results in `reports/checks/aq-plate-leather-2026-10-15.txt`. Compressor
independently decoded both runtime textures. Full WoW restart required.

## Exact plate prompt

Edit source into ONE 4:3 landscape Warcraft addon banner, target 1200x900 master. Strict neutral black and white grayscale, moderately increased contrast, painterly detailed midtones, controlled highlights. Preserve subjects' identity, face, armor, hands, weapons, pose and artist marks. Main subject high toward RIGHT with breathing room, left third quiet for UI text; naturally extend original setting. Bake broad smooth LEFT neutral charcoal darkening gradient strongest at left edge blending without hard vertical boundary. ALSO bake soft BOTTOM darkening over approximately lowest 100px of a 1200x900 master, ending near-black neutral charcoal at bottom edge with no horizontal strip. Both gradients part of image itself. No added text, UI, frame, extra characters or unrelated objects. Savin Lightguard background shared by AQ40 Avenger's and Conqueror's plate sets. Keep exact charging bearded dwarf, heavy ornate spiked armor, helmet, cape and upright long polearm with red inset translated into gray. Keep both hands gripping shaft in original pose and full spear tip visible with room above. Extend original barren forest and rocky ground to left. Preserve running leg anatomy and weapon geometry.
