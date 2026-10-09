# Final banner images

Approved edited masters only. Karl's ongoing image options remain in ../artwork; that folder may grow and is excluded from addon releases.

- blackwing-lair.jpg: approved by Karl on October 8, 2026. 1200 x 800, monochrome with stronger contrast, subject higher and right of center. Created with one ChatGPT image edit; painted details may differ from the original. Source option: ../artwork/blackwinglair.jpg. Goal: raid_bwl.

These JPEG masters are also excluded from addon releases. Only the selected, game-ready banner textures in Media are shipped. Saving an approved master here does not replace its in-game texture automatically. Karl approved installation of Blackwing Lair and all seven weapon masters on October 8; rebuild with `python tools/artwork.py --final-only`. Their game textures bypass runtime desaturation, retain their 3:2 framing, and keep the addon's existing dark gradients and fades.

Visual target for future edits: monochrome, stronger contrast while preserving detail, and the subject above the midpoint and right of center. Do not process or approve every candidate automatically; Karl is still collecting options.

- Slay Onyxia replacement approved (Karl / Codex, 2026-10-09): Karl selected Media/artwork/Hit_It_Very_Hard_full.jpg, reviewed the built-in imagegen monochrome treatment and explicitly said "good, commit". Approved master tall-1200x900/raid_ony.jpg is exact 1200x900, optimized JPEG quality90, with stronger contrast and baked soft left/bottom gradients. Original option unchanged. Compiler selects this final master, runtime aspect4/3 and preprocessed flag bypass redundant desaturation; previous color Onyxia mapping removed from EXTRA_BANNERS. Existing top-right framing, reveal and panel fades unchanged.
