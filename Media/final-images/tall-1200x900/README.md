# Taller banner masters: 1200 x 900

**Rhok'delar is withdrawn for now at Karl's request.** The bowstring corrections were not approved. Its JPEG is retained only as an archived option; do not install or ship it. Rhok'delar currently has no background artwork, and is excluded from runtime artwork build mappings. The other fifteen taller masters remain approved and await installation.

Karl clarified that the extra 100px belongs in the actual image asset, not the addon layout, then explicitly selected all 16 final banners for this treatment. This folder contains the new review versions. Existing 1200 x 800 masters and currently installed runtime textures remain available unchanged.

Each image received one built-in ChatGPT image edit requesting a downward-only canvas extension, original subject scale/placement and monochrome treatment, and a baked soft dark gradient into the lower extension. The bottom fades toward neutral charcoal rather than adding a hard black strip. Artist notices were requested to remain visible. Generative editing is not pixel-exact: painted details and some framing can vary from the original, as visible in the previews.

Generated outputs were technically resized to exact 1200 x 900 (4:3) and optimized as JPEG quality 90. No local artistic manipulation was performed. Source options and 1200 x 800 approved masters were not overwritten. The folder remains excluded from release packages with all final-image masters.

The 16 files are named by goal id. Source/generated paths and prompt are recorded in reports/image-tests/taller-banner-pass.json; local generated-file paths are provenance, while the JPEG masters in this folder are portable. Preview sheets: reports/image-tests/taller-banner-review-1.jpg and taller-banner-review-2.jpg.

Karl approved the overall set and requested one correction to Rhok'delar: its lower bowstring was dangling past the bottom limb rather than connecting. A targeted image edit now connects the string to the lower limb; its corrected preview awaits confirmation. The other fifteen are visually approved. Runtime installation remains pending. To install later, point FINAL_BANNERS to these files, support 1200 x 900 in the compiler's validation, and use 4:3 source aspect for these 16 goals rather than the current 3:2. Keep runtime rendering correction separate: the mistaken +100px layout height and enlarged procedural fade have been undone; the previously approved bounds/top-right anchor and transparent edge fade remain.
