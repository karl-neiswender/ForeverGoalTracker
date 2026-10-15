# Alliance Hunter Tier 2 background

Source: `Media/artwork/Nordrassil_Scout_TCG.jpg` (unchanged).
Review: `Media/final-images/alliance-hunter-tier2-review-2026-10-15.png`.
Built-in imagegen edit; Karl approved with "good". Installed as Alliance variant
of `set_tier2_hunter`; existing Horde/default image retained.
Master: `Media/final-images/tier-sets/hunter/tier2-alliance-nordrassil-master.png`
(1200x900). Runtime: `Media/set_tier2_hunter-alliance-banner.blp` (512px DXT1,
10 mip levels). Existing faction resolver preserves 4:3/preprocessed treatment.
Inspected grayscale, right-side framing, hands/bow and baked left/bottom fades.
Static faction mapping, no recurring processing added. Restart WoW fully.

Validation: runtime independently decoded by existing compressor. Full
Era/Forever `tools/check.py` passed including explicit Alliance/Horde artwork
selection and metadata assertions. Results retained in
`reports/checks/alliance-hunter-tier2-2026-10-15.txt`.

Exact prompt:

Edit supplied Nordrassil Scout TCG artwork into one 4:3 landscape Warcraft addon background for Alliance Hunter Tier 2, target master 1200x900. Preserve this exact female night elf hunter's identity, face/profile, white hair, dragon-head shoulder armor, all armor ornamentation, crouched scouting pose, both hands, elaborate vine-covered bow, taut bowstring and arrow geometry, and forest architecture, as well as existing artist marks and credit line. Strict neutral black and white grayscale, moderately increased contrast, detailed painterly midtones and controlled highlights. Reframe the hunter high and toward RIGHT with breathing room for shoulder horns, head and bow; extend original wooded environment naturally into quiet left third for UI text. Keep anatomy and complete visible bow/arrow geometry faithful, no extra weapons or people. Bake a wide smooth LEFT neutral-charcoal darkening gradient strongest at left edge blending gradually into scene without hard vertical strip. ALSO bake soft BOTTOM darkening gradient across approximately lowest 100 pixels of a 1200x900 master, ending near-black neutral charcoal at bottom edge with no hard horizontal strip. Both gradients in artwork itself. No added text, UI, frame, unrelated objects or extra characters.
