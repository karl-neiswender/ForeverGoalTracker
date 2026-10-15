# Epic Tauren and Undead mount backgrounds

Built-in imagegen edits; originals preserved unchanged.

Tauren source: `Media/artwork/Swift_Kodo_TCG.jpg`.
Review: `Media/final-images/epic-tauren-mount-review-2026-10-15.png`.
Karl approved with "tauren is good". Installed master:
`Media/final-images/mounts/swift-kodo-master.png` (1200x900).
Runtime: `Media/epicmounts_tauren-banner.blp`, 512px DXT1, 10 mip levels.
Existing racial selection mappings retained; previous master preserved.
Inspected grayscale, mount/handler framing, baked left/bottom fades.

Undead source: `Media/artwork/Skeletal_Warhorse_TCG.jpg`.
Review: `Media/final-images/epic-undead-mount-review-2026-10-15.png`.
Karl approved Undead with "yes good" after viewing the saved preview; installed.
Master: `Media/final-images/mounts/skeletal-warhorse-master.png` (1200x900).
Runtime: `Media/epicmounts_undead-banner.blp`, 512px DXT1, 10 mip levels.
Previous master preserved; existing racial mappings retained. Runtime decoded
independently by existing compressor. Full Era/Forever `tools/check.py` passed;
output retained in `reports/checks/epic-undead-mount-2026-10-15.txt`.

Tauren validation: runtime independently decoded by existing compressor.
Full Era/Forever `tools/check.py` passed, including racial artwork selection.
Output: `reports/checks/epic-mounts-2026-10-15.txt`. No new per-frame work;
same runtime filename and mappings. Restart WoW fully to refresh texture.

## Exact Tauren prompt

Edit source into one 4:3 landscape Warcraft addon background, target 1200x900 master. Strictly neutral black and white grayscale, moderately increased contrast, detailed painterly midtones, controlled highlights. Preserve source subjects, identity, armor, pose, anatomy, hands, reins, weapons, architecture and artist marks faithfully. Main subjects high toward RIGHT with breathing room; left third quiet for UI text. Extend source environment naturally. Bake a broad smooth LEFT neutral-charcoal darkening gradient strongest at left edge blending naturally without hard vertical boundary. ALSO bake soft BOTTOM darkening over approximately lowest 100px of a 1200x900 master, ending near-black neutral charcoal at bottom edge, no hard horizontal band. Both gradients must be in image itself. No added text, UI, frame, extra characters or unrelated objects. Epic Tauren mount background from Swift Kodo: retain the huge armored horned kodo as main focus and the existing tauren holding its reins in front, distinctive armor plates, chains, saddle, drum and horn geometry. Preserve recognizable massive kodo silhouette. Reframe pair to right, retain lakeside pine forest and mountain setting; do not turn tauren into rider.

## Exact Undead prompt

Edit source into one 4:3 landscape Warcraft addon background, target 1200x900 master. Strictly neutral black and white grayscale, moderately increased contrast, detailed painterly midtones, controlled highlights. Preserve source subjects, identity, armor, pose, anatomy, hands, reins, weapons, architecture and artist marks faithfully. Main subjects high toward RIGHT with breathing room; left third quiet for UI text. Extend source environment naturally. Bake a broad smooth LEFT neutral-charcoal darkening gradient strongest at left edge blending naturally without hard vertical boundary. ALSO bake soft BOTTOM darkening over approximately lowest 100px of a 1200x900 master, ending near-black neutral charcoal at bottom edge, no hard horizontal band. Both gradients must be in image itself. No added text, UI, frame, extra characters or unrelated objects. Epic Undead mount background from Skeletal Warhorse: retain exact rearing skeletal warhorse, skull head, curved horn, mane, skull saddle armor and flowing barding, ghostly hoof flames translated to controlled white light. Keep existing undead handler holding reins at its right, with original pose, armor and hands. Horse is main focus high toward right, retain eerie moonlit haunted forest and graveyard shapes. No extra bones or legs; keep hoof and rein geometry coherent.
