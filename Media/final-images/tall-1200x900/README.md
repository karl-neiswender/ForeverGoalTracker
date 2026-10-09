# Taller banner masters: 1200 x 900

**The old weapon-only Rhok'delar image is withdrawn.** Its `rhokdelar.jpg` is retained only as an archived option; do not install or ship it. Karl selected the night elf hunter source `Media/artwork/Snipe_full.jpg`, reviewed the replacement, and explicitly authorized commit and installation. The active master is **rhokdelar-hunter.jpg**, 1200 x 900; the compiler selects that filename. All sixteen approved taller banners are now installed.

Karl clarified that the extra 100px belongs in the actual image asset, not the addon layout, then explicitly selected all 16 final banners for this treatment. Existing 1200 x 800 masters remain available unchanged; runtime textures now use the fifteen approved taller versions.

Each image received one built-in ChatGPT image edit requesting a downward-only canvas extension, original subject scale/placement and monochrome treatment, and a baked soft dark gradient into the lower extension. The bottom fades toward neutral charcoal rather than adding a hard black strip. Artist notices were requested to remain visible. Generative editing is not pixel-exact: painted details and some framing can vary from the original, as visible in the previews.

Generated outputs were technically resized to exact 1200 x 900 (4:3) and optimized as JPEG quality 90. No local artistic manipulation was performed. Source options and 1200 x 800 approved masters were not overwritten. The folder remains excluded from release packages with all final-image masters.

The 16 files are named by goal id. Source/generated paths and prompt are recorded in reports/image-tests/taller-banner-pass.json; local generated-file paths are provenance, while the JPEG masters in this folder are portable. Preview sheets: reports/image-tests/taller-banner-review-1.jpg and taller-banner-review-2.jpg.

FINAL_BANNERS points to the fifteen original approved taller files plus rhokdelar-hunter.jpg, the compiler validates 1200 x 900, and Core.lua uses 4:3 source aspect for all sixteen textures. Rebuild with `python tools/artwork.py --final-only`. Each shipped BLP is 512px with ten mip levels, about 172 KiB; JPEG masters do not ship. The mistaken +100px layout height and enlarged procedural fade remain undone; the previously approved bounds/top-right anchor, first-open reveal and transparent edge fade remain. New runtime textures require a full client restart.
