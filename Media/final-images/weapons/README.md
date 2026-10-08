# Weapon banner imagegen pass

October 8, 2026. Seven individual edits using built-in ChatGPT imagegen. Saved here for Karl's visual review, not yet approved or installed as game textures. All are 1200 x 800 optimized JPEG masters. The full final-images folder remains excluded from releases.

| Master / goal ID | Original option in Media/artwork |
| --- | --- |
| ashbringer.jpg | ashbringer-color.jpg |
| atiesh.jpg | atiesh.jpg |
| sulfuras.jpg | Sulfuras_full.jpg |
| thunderfury.jpg | thunderfury.png |
| rhokdelar.jpg | Rhok'delar_full.jpg |
| benediction.jpg | anathema.jpg (Anathema illustration) |
| quelserrar.jpg | Quel'Delar_full.jpg (Karl approved this substitute) |

Comparison: reports/image-tests/weapon-pass-before-after.jpg. Full prompt and source manifest: reports/image-tests/weapon-pass-manifest.json. Technical export/comparison script: reports/image-tests/export-weapon-pass.py. Original options are untouched; current in-game banners remain unchanged. AI reframing alters some painted detail, despite preservation instructions.

Usage snapshot: five-hour account meter 12% before, 15% after; weekly 18% before and after. Rounded, account-wide values cannot isolate image-generation cost.

## Prompt used for each image

Edit the supplied illustration into one landscape 3:2 banner, target 1200x800. Apply neutral BLACK AND WHITE with moderately increased contrast (about 20%), retaining midtone painted detail and avoiding crushed shadows or blown highlights. Reframe the existing weapon so its identifying head/blade detail is centered around 65% across and 35% down, higher and right of center; keep the full recognizable weapon silhouette where possible. Scale down the weapon within the scene if required for this framing rather than cutting off the defining details. Leave quieter darker space on the left for UI text. Preserve the supplied weapon design, blade count, ornamentation, proportions, existing scene and original painted style as faithfully as possible. Change only framing and tonal treatment. No new characters, objects, weapon redesign, text, UI, borders, blur or baked vignette. Preserve any existing artist signature/copyright notice unobtrusively. Single finished artwork, not a before/after collage.

Each call appended its goal ID as the edit target and referenced only the corresponding original.
