---
name: forever-goal-tracker-banners
description: Prepare or edit Forever Goal Tracker raster banner artwork with the approved grayscale framing and baked left and bottom gradients. Use alongside imagegen for this addon's goal, raid, mount and class-set banners.
---

# Forever Goal Tracker banners

Use the built-in imagegen workflow for artistic edits. Apply these requirements to each banner prompt unless Karl requests a change:

- One 4:3 landscape banner; approved master 1200 x 900 pixels.
- Strictly neutral black and white, moderately increased contrast, detailed painterly midtones and controlled highlights.
- Preserve the source's subjects, identity, armor, hands, weapons, architecture, pose and artist marks.
- Place the main subject high and toward the right, with breathing room. Keep the left third quiet for addon text.
- **Bake a wide, smooth dark gradient into the LEFT side of the image**, strongest at the left edge and blending gradually into the scene. Use neutral charcoal without a hard vertical strip or visible boundary.
- **Bake a soft dark gradient into the BOTTOM of the image**, across approximately the lowest 100 pixels of the 1200 x 900 master, fading downward to near-black neutral charcoal at the bottom edge. Preserve a natural transition with no hard horizontal strip.
- Include BOTH gradients in the generated artwork itself. The addon's runtime fades supplement these baked gradients.
- No added text, UI, border, unrelated objects or extra characters.

Inspect the result for both gradients, neutral color, subject framing and complete weapon/hand geometry. If a requirement is missing, request a targeted imagegen correction.

Preserve original source files and generated review images. Save project reviews under Media/final-images. Record source, output and exact prompts in reports/image-tests. Show the edited review for Karl's approval before installing it; an existing explicit approval authorizes installation.

After approval, use the existing tools/artwork.py pipeline for technical resizing/encoding and a 512px DXT1 BLP with ten mip levels. Wire the correct goal ID at 4:3 with preprocessed=true; update the rebuild map and runtime manifest. Retain approved class and faction overrides. New or replaced textures require a full WoW restart.
