# Five weapon banners: review, 2026-10-28

Status: **all five approved by Karl and installed**. Karl explicitly chose the
first Vis'kag review with the person. Approved reviews were converted to
neutral 1200 x 900 masters, encoded as 512px DXT1 BLPs with ten mip levels,
and wired into `Core.lua`. A full game restart is needed to see the new
textures. Native visual review is pending.

| Goal ID | Untouched source | Review to approve |
|---|---|---|
| `might_of_menethil` | `Media/artwork/weapon-might-of-menethil.jpg` | `Media/final-images/might-of-menethil-review-v1.png` |
| `sulthraze` | `Media/artwork/weapon-sulthraze.jpg` | `Media/final-images/sulthraze-review-v1.png` |
| `fiery_war_axe` | `Media/artwork/weapon-fiery-war-axe.jpg` | `Media/final-images/fiery-war-axe-review-v1.png` |
| `viskag` | `Media/artwork/weapon-viskag-the-bloodletter.jpg` | `Media/final-images/viskag-bloodletter-review-2026-10-28-v1.png` |
| `unstoppable_force` | `Media/artwork/weapon-the-unstoppable-force.jpg` | `Media/final-images/unstoppable-force-review-v1.png` |

Built with the built-in `image_gen` tool, one edit call per source. Vis'kag had
one targeted correction: v1 introduced an extra character; v2 removes that
character and keeps the sword, gripping arm and distant silhouette. This
session's v2 review is retained as
`Media/final-images/viskag-bloodletter-review-2026-10-28-v2.png` for
comparison. Existing tracked `viskag-review-v1.png` and `viskag-review-v2.png`
were restored after a name collision. All new reviews are 1448 x 1086 (4:3). Visual
inspection found distinct weapon shapes, quiet left thirds, left fades and
bottom fades. The source files were not modified by this work. The working-tree
Vis'kag source was already modified when this review began; preserve that edit.

No artist was verified from these sources. Do not invent credits.

## Installation and validation

- `reports/image-tests/install-five-weapons-2026-10-28.py` records the selected
  reviews and builds the masters and BLPs with `tools/artwork.py`'s compressor.
- `tools/artwork.py` rebuild map and `Media/final-images/runtime-manifest.json`
  include all five. The compressor independently decoded every BLP after
  writing it.
- Goal art variants are registered at 4:3 with `preprocessed=true`.
  The Gear Planner regression now checks The Unstoppable Force's own banner.
- The artwork checklist has five Done rows, no unlisted goals, and rebuilt
  embedded thumbnails (234; none missing).
- `tools/check.py` passed after the regression update. Retained output:
  `reports/checks/five-weapons-check-2026-10-28.txt`.
- The guarded `tools/sync-era.sh` copied the runtime changes to Classic Era on
  2026-10-28. A full game restart is required for the new BLPs.
- Native appearance on Classic Era and Forever has not been tested.

## Exact prompts

### Might of Menethil

> Use case: style-transfer. Edit target: supplied Might of Menethil weapon illustration. Make one 4:3 landscape Forever Goal Tracker weapon banner, target 1200x900. Preserve the exact broad spiked mace head, glowing curved blue energy shapes, dark wrapped handle, diagonal pose and atmospheric backdrop. Expand the scene naturally to landscape while moving the complete weapon high and toward the right with breathing room around its edges; the left third must be quiet for addon text. Detailed Warcraft painterly illustration in strictly neutral black and white, moderate contrast, detailed midtones and controlled highlights; translate all blue and purple glow into neutral grayscale light. Bake a wide smooth dark charcoal gradient into the LEFT edge blending gradually with no vertical strip, and a soft dark gradient across the lowest approximately 100 pixels fading to near-black at the bottom edge. Both gradients must be part of the image. No text, UI, border, signature, watermark, unrelated objects or extra characters.

### Sul'thraze

> Use case: style-transfer. Edit target: supplied Sul'thraze the Lasher weapon illustration. Make one 4:3 landscape Forever Goal Tracker weapon banner, target 1200x900. Preserve the complete distinctive broad black blade with angular silver edge, engraved runes, purple jewel guard and short wrapped hilt, its diagonal pose and Zul'Farrak sandstone architecture. Reframe high toward the right with breathing room around all weapon tips; expand the sandstone scene naturally toward the left, keeping the left third quiet for addon text. Detailed Warcraft painterly illustration, strictly neutral black and white with moderate contrast, detailed midtones, controlled highlights; turn green and purple glow into neutral grayscale. Bake a broad smooth dark charcoal gradient from the LEFT edge with no vertical seam and a soft dark gradient over the lowest approximately 100 pixels fading to near-black at bottom. Both fades must be inside the image. No added text, UI, border, signature, watermark, unrelated objects or extra characters.

### Fiery War Axe

> Use case: style-transfer. Edit target: supplied Fiery War Axe illustration. Make one 4:3 landscape Forever Goal Tracker weapon banner, target 1200x900. Preserve the recognizable double-edged black war axe, gold metal details, purple grip, ring-shaped pommel, diagonal pose and flames beneath it. Keep the complete axe high toward the right with breathing room for both blades and handle; extend its atmospheric fire scene to the left and leave the left third quiet for addon text. Detailed Warcraft painterly illustration in strictly neutral black and white, moderate contrast and nuanced midtones; turn orange flame into neutral luminous grayscale. Bake a broad smooth dark charcoal gradient into the LEFT side with no visible strip, plus a soft dark gradient across the lowest approximately 100 pixels fading down to near-black. Both fades must be inside the artwork. No added text, UI, border, signatures, watermarks, unrelated objects or characters.

### Vis'kag, first attempt

> Use case: style-transfer. Edit target: supplied Vis'kag the Bloodletter weapon illustration. Make one 4:3 landscape Forever Goal Tracker weapon banner, target 1200x900. Preserve the distinctive curved broad blue-black blade with two claw-like points, fiery orange inner edge, square blue ornament at the hilt, gloved hand and shadowy dragon silhouette in the mist. Extend the scene naturally into a wide landscape; keep the complete sword and hand high toward the right with breathing room and a quiet left third for addon text. Detailed Warcraft painterly illustration, strictly neutral black and white, moderate contrast, textured midtones, controlled highlights; make the fiery edge luminous silver-white and preserve the blade silhouette. Bake a wide smooth dark charcoal gradient from the LEFT edge with no vertical strip, plus a soft dark gradient along the lowest approximately 100 pixels fading to near-black at bottom. Both gradients are inside the artwork. No added text, UI, border, signature, watermark, unrelated objects or extra characters.

### Vis'kag, correction

> Use case: precise-object-edit. Image 1 is the review image to correct; Image 2 is the original weapon reference. Keep the existing 4:3 neutral grayscale banner, sword silhouette, right-side weapon placement, dark quiet left third, baked left gradient and near-black bottom fade. Remove the added character's visible torso, legs, head and free arm. Show only the original image's sword, the gloved hand and forearm gripping it, and the misty background with the distant dragon silhouette. Preserve the distinctive curved blade with two claw-like points and the square hilt ornament. Fill removed areas with matching mist and shadow, no other new objects, text, UI or borders.

### The Unstoppable Force

> Use case: style-transfer. Edit target: supplied The Unstoppable Force weapon illustration. Make one 4:3 landscape Forever Goal Tracker weapon banner, target 1200x900. Preserve the exact rugged spiked hammer head, jagged silver metal plates, glowing inset eye, dark smoke, long wooden haft and snowy rocks. Expand the scene naturally to landscape; place the complete mace high toward the right with breathing room around spikes and haft and a quiet left third for addon text. Detailed Warcraft painterly illustration in strictly neutral black and white, moderate contrast, rich midtones and controlled highlights; render smoke and glow in grayscale. Bake a broad smooth dark charcoal gradient at the LEFT edge blending into the scene with no visible strip, and a soft dark gradient across the lowest approximately 100 pixels fading down to near-black. Both fades must be in the artwork. No added text, UI, border, signature, watermark, unrelated objects or extra characters.
