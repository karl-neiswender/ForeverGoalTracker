# Alliance PvP leather preview

Source: `Media/artwork/Moonshadow_TCG.jpg`, preserved unchanged.
Review: `Media/final-images/alliance-pvp-leather-review-2026-10-15.png`.
Built-in imagegen edit. Karl approved the preview with "good"; installed.
Inspected neutral grayscale, right-side subject, intact hands/staff and baked
left/bottom darkening. Intended Alliance leather collection and its class goals.

Master: `Media/final-images/pvp/marshal-leather-moonshadow-master.png` (1200x900).
Runtime: `Media/pvp_set_leather_ally-banner.blp` (512px DXT1, 10 mip levels).
Collection variant uses 4:3 and preprocessed=true; Rogue/Druid child goals
inherit via existing PvP resolver. Static mapping, no new recurring work.
Existing compressor independently decoded texture. Full Era/Forever checks
passed, including both leather class mappings and metadata; output retained in
`reports/checks/alliance-pvp-leather-2026-10-15.txt`. Full WoW restart required.

Exact prompt:

Edit supplied Moonshadow painting into one 4:3 landscape Warcraft addon background for Alliance PvP leather sets, target 1200x900 master. Preserve this exact female night elf's identity, face markings, long dark hair, ears, leather armor design, pose, both hands and full staff geometry, rocky perch and moon, and any existing artist marks. Strict neutral grayscale black and white with moderately increased contrast, detailed painterly midtones and controlled highlights. Position main character high toward right with breathing room, staff crossing naturally without distorted hands. Extend existing moonlit rocky landscape naturally toward left into a quiet left third for UI text; do not invent characters or unrelated objects. Bake broad smooth LEFT neutral charcoal darkening gradient strongest at left edge, blending softly into scene without a vertical boundary. ALSO bake soft BOTTOM darkening gradient across approximately lowest 100px of a 1200x900 master, ending near-black charcoal at bottom edge with no hard horizontal band. Both gradients must be in artwork itself. No added text, UI, border or extra characters.
