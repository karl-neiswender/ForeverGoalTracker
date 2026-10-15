# Horde Warlock Tier 3 preview

Source: `Media/artwork/Pagatha_Soulbinder_TCG.jpg`, preserved unchanged.
Review: `Media/final-images/horde-warlock-tier3-review-2026-10-15.png`.
Built-in imagegen edit; Karl approved with "good", installed.
Intended Horde variant for `tier3_warlock`, retaining current Alliance/default.
Inspected grayscale, warlock/companion framing, staff/hands and left/bottom fades.

Master: `Media/final-images/tier-sets/warlock/tier3-horde-pagatha-master.png`
(1200x900). Runtime: `Media/tier3_warlock-horde-banner.blp` (512px DXT1,
10 mip levels). Faction mapping retains Alliance and default images, 4:3 and
preprocessed metadata. No new per-frame work. Full WoW restart required.

Validation: existing compressor independently decoded runtime texture. Full
Era/Forever `tools/check.py` passed, including faction selection and artwork
metadata. Output: `reports/checks/horde-warlock-tier3-2026-10-15.txt`.

Exact prompt:

Edit supplied Pagatha Soulbinder TCG painting into ONE 4:3 landscape Warcraft addon background for Horde Warlock Tier 3, target 1200x900 master. Preserve exact masked undead warlock identity, hood, Plagueheart armor and distinctive huge horned shoulder pieces, robe ornamentation, raised staff, hands/claws and pose; preserve existing succubus companion behind and to her left, her face, horns, outfit and whip geometry. Faithful painterly artwork, no new characters or equipment. Strict neutral black and white grayscale, moderately increased contrast, detailed midtones and controlled highlights. Reframe main warlock high toward RIGHT with breathing room for staff tip and shoulder horns; keep companion visible nearby, extend original misty sparse forest environment naturally into quiet left third for UI text. Preserve anatomy, weapon geometry and any artist marks. Bake wide smooth LEFT neutral charcoal darkening gradient strongest at left edge fading naturally into scene, no hard vertical strip. ALSO bake a soft BOTTOM darkening gradient over approximately lowest 100px of a 1200x900 master, ending near-black neutral charcoal at bottom edge with no hard horizontal strip. Both gradients part of artwork itself. No added text, UI, border or unrelated objects.
