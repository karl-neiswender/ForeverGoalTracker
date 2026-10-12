# Corrupted Ashbringer replacement

Karl requested: "edit this and replace the current Ashbringer art".
Source: Media/artwork/AshbringerC.jpg, preserved unchanged.
Built-in image_gen edit, shown in the conversation and installed as requested.
The original blade, skull medallion/runes, guard, grip and pommel remain visible
on the same diagonal, against the skull alcove. Baked left and bottom fades,
grayscale painterly treatment and 4:3 framing match the addon convention.
Karl then requested removal of the visible bottom-right watermark. A targeted
image_gen correction removed that text and filled the area with the existing
dark background. Copyright/artist attribution remains in the records.
James Ryman is now mapped
to the banner's in-game credit and recorded in ARTWORK-CREDITS.txt, based on
the original supplied image's explicit attribution.

Review: Media/final-images/weapons/ashbringer-ryman-review.png.
Corrected review: Media/final-images/weapons/ashbringer-ryman-review-clean.png.
Master: Media/final-images/weapons/ashbringer-ryman-master.png (1200x900,
technically normalized to neutral RGB grayscale).
Runtime: Media/ashbringer-banner.blp (512px DXT1, ten mips, 175948 bytes).
tools/artwork.py now rebuilds from the new master; runtime manifest source
updated. Original older master remains unchanged and preserved in Git.
Existing ashbringer goal mapping, 4:3 aspect and preprocessed=true retained;
no goal rules or progress changed, no unrelated banner replacements.

The compressor independently decoded the BLP and validated every mip range.
Full Lua 5.1/Era/Forever check: reports/checks/ashbringer-ryman-2026-10-12.txt.
Native appearance requires a full WoW restart because the BLP is replaced.
Source sync only; no version bump, release tag or CurseForge publication.

## Exact generation prompt

### Watermark correction

Edit ONLY the bottom-right credit/watermark text in this grayscale Corrupted Ashbringer banner. Remove the entire line reading '© Blizzard Entertainment - by James Ryman' and seamlessly fill that small area with the existing dark stone/background and smooth bottom gradient. Do not add any replacement text or signature. Preserve everything else exactly: full sword silhouette, blade/guard/hilt/pommel, glowing skull medallion, runes, skull alcove, masonry, framing, neutral grayscale, painting texture, contrast, broad baked LEFT gradient and soft baked BOTTOM gradient. Keep 4:3 landscape proportions. No other changes. The artist credit will remain separately in the addon's attribution records.

### Initial edit

Edit the supplied Corrupted Ashbringer painting into ONE 4:3 landscape Forever Goal Tracker banner, targeting a 1200x900 master. Faithfully preserve the EXACT distinctive sword silhouette, complete pointed asymmetric blade with its stepped/notched spine, floating skull medallion, rune shapes, broad angular guard, grip and pommel. Keep its original lower-left-to-upper-right diagonal orientation. Preserve the monumental skull-shaped stone alcove and masonry as the environment, the original painterly style, and genuine artist marks/credit. Reframe by extending the stone scene into landscape: the entire sword must remain visible with breathing room around the blade tip and pommel, concentrated high and toward the RIGHT; do not crop off the hilt, change the sword design, or add a hand/character. Keep the LEFT THIRD quiet for addon text. STRICTLY neutral black and white/grayscale, no purple/green/warm/cool tint. Translate the green magical skull aura and runes into a controlled soft pale grayscale light, retaining readable details rather than a blown-out white halo. Moderately enhanced contrast with rich painterly midtones. Bake a WIDE smooth dark neutral-charcoal gradient into the LEFT edge itself, blending gradually into the scene without a hard vertical strip. ALSO bake a SOFT dark BOTTOM gradient into roughly the lowest 100 pixels of the 1200x900 composition, smoothly reaching near-black neutral charcoal at the bottom edge without a horizontal strip. BOTH gradients must be present in the image artwork, not merely implied runtime shading. Preserve source identity and any existing authentic artist credit; do not add new text, logos, UI, borders, unrelated objects or extra characters. This replaces the existing Corrupted Ashbringer goal artwork.
