# Molten Core banner imagegen pass

October 8, 2026. Three edits using built-in ChatGPT imagegen, approved by Karl and installed in their banners. Source options remain untouched. These JPEG masters are excluded from releases along with the entire final-images folder; only compressed game textures ship. Rebuild with `python tools/artwork.py --final-only`. The addon restores 3:2 proportions and bypasses desaturation for these final textures while retaining its existing gradients and fades.

| Master / existing banner | Original option in Media/artwork |
| --- | --- |
| raid_mc.jpg (Molten Core raid) | Ragnaros_the_Firelord_full.jpg |
| att_mc.jpg (Molten Core attunement) | blackrock-mountain.jpg |
| set_tier1.jpg (Tier 1) | Majordomo_Executus_full.jpg |

All outputs: 1200 x 800 optimized JPEG, black and white appearance, stronger contrast, main subject higher and right of center, quieter left side for text. Some generated pixels retain a very slight near-neutral tint. AI reframing reinterprets painted details; these are not exact crops.

Comparison: reports/image-tests/molten-core-pass-before-after.jpg. Full prompt/source manifest: reports/image-tests/molten-core-pass-manifest.json. Original artist signatures remain in source files; artwork attribution remains in ARTWORK-CREDITS.txt.

Three image-generation calls, no retries. Rounded account usage meter: five-hour 18% before and after; weekly 18% before, 19% after. These readings cannot isolate image-generation cost.

## Prompt used

Edit the supplied artwork into a single landscape 3:2 goal-banner image, target 1200x800. Match the approved previous passes: neutral black and white, stronger contrast (around 20%) while retaining painted midtone details, readable shadows, and controlled fire highlights. Reframe the main subject so the face/main detail sits around 65% across and 35% down, right of center and above midpoint. Leave quieter, darker space on the left for addon text. Preserve the original character anatomy, face, pose, armor, weapons, environment and painted style as faithfully as possible; change framing and tonal treatment only. Retain defining details rather than cutting off the face or weapons. Preserve existing artist signatures unobtrusively. No new characters or objects, redesign, text, UI, borders, blur, or baked vignette. One finished image, not a comparison collage.

Each call appended its subject as the edit target and referenced only the corresponding source.
