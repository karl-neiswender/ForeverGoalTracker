# Raids with Guildmates background

Source: `Media/artwork/Nefarian_TCG.jpg`, preserved unchanged.
Review: `Media/final-images/raids-with-guildmates-review-2026-10-15.png`.
Built-in imagegen edit. Karl approved with "good"; installed for `social_guild_raid`.
Inspected neutral grayscale, right-side dragon, visible raid group, left/bottom fades.
Master: `Media/final-images/social/raids-with-guildmates-master.png` (1200x900).
Runtime: `Media/social_guild_raid-banner.blp` (512px DXT1, 10 mip levels).
Static 4:3 preprocessed mapping; no new per-frame work. Restart WoW fully.

Validation: compressor independently decoded runtime BLP. Full Era/Forever
`tools/check.py` passed including the new goal's image mapping and metadata;
results retained in `reports/checks/raids-with-guildmates-2026-10-15.txt`.

Exact prompt:

Edit supplied Nefarian TCG painting into ONE 4:3 landscape Warcraft addon background for Raids with Guildmates, target 1200x900 master. Preserve original Nefarian identity, massive dragon anatomy, horned head, spread wings, claws, pose, Blackwing Lair fortress architecture, and existing small adventurers fighting together at his feet. Emphasize the existing group facing a huge raid boss, retain visible adventurers without adding unrelated characters. Strict neutral grayscale black and white, moderately increased contrast, detailed painterly midtones, controlled highlights in original fire and mouth. Reframe dragon high toward RIGHT with breathing room for horns, existing raid members visible near lower-right and middle; extend original fortress naturally to leave left third quiet for UI text. Preserve source geometry, original painterly style and any artist marks. Bake a wide soft LEFT neutral-charcoal darkening gradient strongest at left edge blending gradually into scene, no hard vertical strip. ALSO bake soft BOTTOM darkening gradient across approximately lowest 100px of a 1200x900 master, ending near-black charcoal at bottom edge with no hard horizontal strip. Both gradients must be part of artwork itself; keep adventurers readable above bottom fade. No added text, UI, frame or unrelated objects.
