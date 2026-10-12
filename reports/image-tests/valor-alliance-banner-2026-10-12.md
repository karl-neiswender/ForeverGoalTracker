# Alliance/default Battlegear of Valor banner review

Requested by Karl for the Warrior Dungeon Set 1 goal, set_dungeon1_warrior.
Source: Media/artwork/Andiss_Butcherson_TCG_Card.jpg, preserved unchanged.
Review: Media/final-images/set_dungeon1_warrior-alliance-review.png.
Corrected review: Media/final-images/set_dungeon1_warrior-alliance-review-v2.png.
Built-in image_gen edit. Karl approved the review: "good".
Installed for set_dungeon1_warrior as the Alliance/default Valor image.

Generated review is 1448x1086, exactly 4:3, visually grayscale with small
residual channel differences (maximum 13). The technical master is normalized
to exactly neutral RGB grayscale. Visible card
frame/type/cost/rules/footer removed; warrior, plate armor, hands and weapon
remain the focus high/right. Wide left darkening and soft bottom darkening
are baked into the image. Approved master:
Media/final-images/tier-sets/warrior/valor-alliance-master.png (1200x900).
Runtime: Media/set_dungeon1_warrior-banner.blp (512px DXT1, ten mip levels,
175948 bytes). tools/artwork.py rebuild map and runtime manifest updated.
Core maps the goal at 4:3 with preprocessed=true, preserving existing faction
override tables. Only the Valor goal was wired, not warrior leveling art.
No goal/progress changes. Artist attribution is
not verified by the supplied card, so do not invent a credit.

Existing tools/artwork.py compressor validated the BLP container by decoding
it and checking every mip range. Full checker output:
reports/checks/valor-banner-install-2026-10-12.txt. New texture requires a
full game restart for native review. Source/code sync only; no release tag.

## Targeted shoulder correction

After approving the banner composition, Karl noted that the pauldron on the
right side of the image must have a smooth, rounded studded dome rather than
a projecting spike. Preserved reference:
Media/artwork/Valor-pauldron-reference-2026-10-12.png. Built-in image_gen edited
only that requested armor shape; the left shoulder remains spiked. Version 1
review is retained, and the canonical master/runtime texture use version 2.
The previous composition approval plus specific correction request authorized
the targeted replacement; Karl then explicitly approved version 2: "good apply
to the addon". No unrelated image/design changes were requested.

### Exact correction prompt

Targeted correction to image 1, the grayscale Valor banner. Change ONLY the large pauldron on the RIGHT side of the image (the warrior's left shoulder). Image 2 is an armor-shape reference ONLY: that right-hand pauldron has a rounded smooth domed top, small round studs/rivets, and a substantial angular raised rim; it does NOT have any long pointed spike rising from its top. Remove the tall curved spike and any extra protruding top spikes from that right-hand shoulder in image 1. Repaint just that shoulder as the matching rounded, riveted Valor pauldron, preserving its size, lighting and painted grayscale texture. Keep the spiked shoulder on the LEFT side of image 1 unchanged. Preserve EVERYTHING else exactly: warrior face, hair, beard, breastplate, hands, weapon, pose, camera, subject placement, background, image aspect, painterly style, contrast and existing gradients. Remain STRICT neutral black and white. Retain the baked broad LEFT dark gradient and the baked soft BOTTOM dark gradient across the lowest approximately 100 pixels of a 1200x900 master; both must remain natural without hard strips. No new text, UI, border, color or objects. Produce one 4:3 landscape corrected banner.

## Exact edit prompt

Edit the supplied Andiss Butcherson Warcraft TCG card into ONE 4:3 landscape addon banner, aiming for a 1200x900 master. Extract and faithfully preserve the original painted human warrior: rugged face, reddish braided beard rendered in grayscale, massive distinctive Battlegear of Valor shoulder plates, layered plate armor, gauntleted hands, and the existing weapon across the lower foreground. Keep his identity, pose, armor construction, visible hand and weapon geometry, and original painterly style. Remove ONLY the trading-card presentation: title, cost gem, ornamental card frame, rules text, footer, logos and all card UI. Preserve any genuine artist mark in the painting. Recompose by extending the original muted background horizontally into a believable quiet setting, keeping the warrior high and toward the RIGHT with breathing room, not jammed into the top or right edge; his face and defining pauldrons should remain clearly visible. Keep the LEFT THIRD quiet for addon text. STRICT neutral black and white/grayscale only, moderately stronger contrast, detailed painterly midtones and controlled armor highlights; no warm or cool tint. Bake a WIDE SMOOTH DARK GRADIENT into the LEFT side itself, strongest at the left edge and naturally blending into the scene in neutral charcoal, without a vertical strip or hard boundary. ALSO bake a SOFT DARK BOTTOM GRADIENT across roughly the lowest 100 pixels of the 1200x900 composition, gently fading downward to near-black neutral charcoal at the bottom edge, without a horizontal strip. Both baked gradients are essential. No added text, UI, border, extra characters, unrelated objects, new weapons or exaggerated glow. This is the Alliance/default warrior Battlegear of Valor goal image; retain the source art rather than redesigning the character.
