# Alliance PvP cloth background review

Source: `Media/artwork/Durgle_Wizzledab_TCG.jpg` (unchanged).
Review: `Media/final-images/alliance-pvp-cloth-review-2026-10-15.png`.
Built-in imagegen edit. Karl requested removal of the lower-left mark, then
approved the revised preview with "good". Installed after approval.
Intended replacement: `pvp_set_cloth_ally-banner.blp`, retaining the existing
Alliance cloth collection and child mappings. Preserve previous master.
Inspected grayscale, right-side subject, left/bottom fades and artist mark.

Revised review: `Media/final-images/alliance-pvp-cloth-review-v2-2026-10-15.png`.
Master: `Media/final-images/pvp/marshal-cloth-durgle-master.png` (1200 x 900).
Runtime: `Media/pvp_set_cloth_ally-banner.blp` (512px DXT1, 10 mip levels).
Existing collection/child mappings retained. Previous master preserved.
No Lua or per-frame processing changes. Restart WoW fully to refresh texture.

Validation: existing compressor independently decoded the runtime BLP; 4:3
master and 10 mip levels verified. Full Era/Forever `tools/check.py` passed;
output saved in `reports/checks/alliance-pvp-cloth-2026-10-15.txt`.

Exact revision prompt: Precise localized edit: remove ONLY the small handwritten
signature/watermark in the extreme lower-left corner of this grayscale fantasy
banner. Seamlessly fill that small area with the surrounding dark rocky ground
and neutral charcoal bottom fade. Keep all other image content unchanged: exact
mage, face, helmet, armor, magic streams, floating rocks, landscape, grayscale
contrast, framing, dimensions, wide left darkening and bottom darkening gradients.
Do not add text or any mark. Do not change or regenerate the rest of the scene.

Exact prompt:

Edit supplied Durgle Wizzledab TCG painting into ONE 4:3 landscape Warcraft addon background, target master 1200x900. Preserve this exact gnome mage identity, stern face, white beard, spiky helmet and armor, casting pose and flowing magical energy, painterly medium and artist signature. Strictly neutral grayscale black and white, moderately increased contrast, rich detailed midtones, controlled highlights so magic is luminous but not blown out. Reframe mage high and toward RIGHT with space above helmet spikes, extending original floating-rock storm landscape naturally to the left; keep left third quiet for UI text. Preserve anatomy, hands and armor shapes; no extra characters or invented equipment. Remove source's plain black outer border. Bake in a broad soft LEFT darkening gradient, neutral charcoal strongest at left edge blending gradually into the scene with no visible boundary. ALSO bake in soft BOTTOM darkening across approximately lowest 100 pixels of a 1200x900 master, ending near-black neutral charcoal at bottom edge with a natural smooth transition, no horizontal strip. Both gradients must be in the image itself. Keep artist mark visible as in source. No added text, UI or frame.
