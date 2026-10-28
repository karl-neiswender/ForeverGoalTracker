# Alliance Bloodfang night elf banner review, 2026-10-28

Status: Karl approved the corrected v2 review and it is installed for Alliance.

- Untouched source: `Media/artwork/alliance-nightelf-female-rogue-tier2.png`
- Review: `Media/final-images/bloodfang-alliance-nightelf-review-2026-10-28-v1.png`
- Approved correction: `Media/final-images/bloodfang-alliance-nightelf-review-2026-10-28-v2.png`
- Installed master: `Media/final-images/tier-sets/rogue/tier2-alliance-nightelf-master.png`
- Runtime: `Media/set_tier2_rogue-alliance-banner.blp`
- Intended goal: Alliance variant of `set_tier2_rogue` (Bloodfang Armor)
- Artist printed on the source card: Guangjian Huang. Credited on the Alliance goal.
- The original card is unchanged. Horde retains `set_tier2_rogue-banner.blp`.

The review flips the night elf to face left and places her on the right. The
armor spikes, pale hair, glowing hand and stone setting remain recognizable.
It is a neutral grayscale 4:3 landscape with quiet left space and baked left
and bottom fades. The card frame, labels and copyright text were removed.
Karl marked two spikes on the large shoulder at the right edge. V2 extends
both upward and outward, leaving the other shoulder as it was. Karl approved v2.
The approved review was resized to a neutral 1200 x 900 master and encoded to
a 512px DXT1 BLP with ten mip levels. `Core.lua` uses the Alliance faction
override, `tools/artwork.py` and the runtime manifest include the new asset,
and the checklist shows the Alliance and Horde images separately. A full game
restart is needed to see the texture. Native visual review is pending.
The checklist rebuilt 239 thumbnails with no missing files. `tools/check.py`
passed after the mapping change; retained output is
`reports/checks/bloodfang-alliance-check-2026-10-28.txt`.

## Exact prompt

> Use case: style-transfer and horizontal flip. Edit the supplied Shadowglen Stalker trading card illustration into a Forever Goal Tracker Alliance Bloodfang armor set banner. Preserve the original painting's pale female night elf rogue, long pale hair, pointed ears, recognizably angular red Bloodfang armor with oversized red shoulder spikes and glowing hand, and misty forest/stone architecture. HORIZONTALLY FLIP the character and original scene so the night elf faces LEFT, opposite the original card. Keep accurate armor, face, hands and anatomy. Remove all card frame, title, number, icons, stat/rules box, copyright, signature and other printed text. Make one 4:3 landscape weapon/armor banner, intended final 1200 x 900. Recompose with the night elf high on the RIGHT side facing inward toward a quiet left third for goal text, with breathing room around shoulder spikes and ears. Extend the forest and masonry organically across the left. Detailed painterly Warcraft style in STRICTLY NEUTRAL BLACK AND WHITE, moderate contrast, nuanced midtones and controlled highlights; all original red/cyan/orange becomes grayscale. Bake a broad smooth dark charcoal gradient into the LEFT edge, fading gradually into the painting without a hard vertical strip. Bake a second soft gradient across the lowest approximately 100 pixels, fading to near-black charcoal at the bottom edge with no hard strip. Both gradients must be part of the image. No new text, UI, border, unrelated objects or extra characters.

## Exact correction prompt

> Use case: precise-object-edit of the attached annotated grayscale 4:3 Alliance Bloodfang banner. The red hand-drawn circles mark EXACTLY TWO triangular metal spikes on the large near shoulder pauldron at the RIGHT EDGE of the image. Remove the red circles entirely. Extend ONLY those two circled pauldron spikes higher and taller, retaining their dark inset and bevel structure. Their tips must angle OUTWARD toward the outer RIGHT edge of the canvas, not inward toward the night elf's head. Preserve and integrate the pauldron geometry and lighting. The OTHER shoulder, left of the character's head with its already good long spikes, must be completely unchanged. Keep all other pixels and composition as close as possible: night elf's face, pale hair, pointed ears, pose, glowing hand, background, grayscale tones, quiet dark left third, baked left fade and near-black bottom fade. Do not change the image dimensions or framing. No red annotations, text, new objects, or additional spikes.
