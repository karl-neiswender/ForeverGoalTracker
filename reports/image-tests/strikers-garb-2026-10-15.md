# Striker's Garb background review

Source: `Media/artwork/Azarak_Wolfsblood_TCG.jpg` (unchanged).
Review: `Media/final-images/strikers-garb-review-2026-10-15.png`.
Built-in imagegen edit. Karl approved the preview with "good"; installed.
Inspected: neutral grayscale, right-side hunter and wolf, quiet left side,
soft baked left and bottom gradients. Technical 1200 x 900 master conversion
and runtime encoding completed after approval.

Approved master: `Media/final-images/tier-sets/hunter/strikers-garb-master.png`
(1200 x 900). Runtime: `Media/set_tier25_hunter-banner.blp` (512px DXT1,
10 mip levels, 175948 bytes). Mapped to `set_tier25_hunter` at 4:3 with
`preprocessed=true`; other AQ40 class sets retain their shared background.
Rebuild mapping and runtime manifest updated. No recurring computation added;
only a static texture mapping changes at load. Full WoW restart required.

Validation: full `tools/check.py` passed under bundled Python with the PC's
Python 3.12 Lua 5.1 bindings preloaded; includes Era/Forever and updated AQ
artwork assertions. Output: `reports/checks/strikers-garb-2026-10-15.txt`.
Runtime BLP decoded independently inside the existing compressor.

Exact prompt:

Edit the supplied Azarak Wolfsblood artwork into one 4:3 landscape goal background for Striker's Garb in a Warcraft addon. Target master 1200x900. Strict neutral black and white grayscale, moderately increased contrast, detailed painterly midtones, controlled highlights. Preserve the original orc hunter's identity, red armor design translated faithfully to gray, pose, facial features, hands, weapons and wolf companion and any artist marks. Reframe main hunter high and toward the right with breathing room around helmet and shoulder spikes; keep wolf visible below and to his left. Extend the existing wooded environment naturally into a quiet left third for UI text; do not add characters or change armor. Bake a wide smooth neutral-charcoal LEFT darkening gradient strongest at left edge fading naturally into scene with no hard vertical strip. Also bake a soft BOTTOM darkening gradient across roughly lowest 100px of a 1200x900 master, ending near-black neutral charcoal at bottom edge, no hard horizontal strip. Both gradients must be part of the image itself. Preserve natural anatomy and complete visible weapon and hand geometry. No added text, UI, border, unrelated objects or extra characters.
