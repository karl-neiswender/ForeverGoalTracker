# Arcanite Reaper background

Source: `Media/artwork/Bloodied_Arcanite_Reaper_TCG.jpg`, unchanged.
Review: `Media/final-images/arcanite-reaper-review-2026-10-15.png`.
Built-in imagegen edit; Karl approved with "good". Installed for the existing
`arcanite_reaper` goal Claude added; no goal data changed here.
Master: `Media/final-images/weapons/arcanite-reaper-master.png` (1200x900).
Runtime: `Media/arcanite_reaper-banner.blp` (512px DXT1, 10 mip levels).
Inspected axe, hand, tauren, grayscale and baked left/bottom fades.
4:3 preprocessed static mapping, no new per-frame work. Full WoW restart required.
Compressor independently decoded texture. Full Era/Forever `tools/check.py`
passed, including the new banner mapping and metadata. Results:
`reports/checks/arcanite-reaper-art-2026-10-15.txt`.

Exact prompt:

Faithful image edit of supplied Bloodied Arcanite Reaper TCG painting for Arcanite Reaper Warcraft addon background. Preserve original huge double-bladed axe EXACTLY: crescent blade shapes, central skull, spikes, shaft, hand gripping it, raised pose, tauren warrior face/horns and armor, original painterly canvas texture and artist mark. Do not redesign the weapon or character. The AXE is the main focus, high toward right with breathing room around full blade and skull; retain visible tauren below it at right. Make one 4:3 landscape banner, target master 1200x900. Convert to strict neutral grayscale with moderate contrast, detailed midtones and controlled metallic highlights. Extend matching original jagged canyon and cloudy sky naturally into quiet left third for UI text. Bake broad smooth LEFT neutral-charcoal fade strongest at left edge blending naturally without vertical strip. ALSO bake soft BOTTOM charcoal fade over approximately lowest 100px of a 1200x900 master ending near-black at bottom without horizontal strip. Both gradients in image itself. No added text, UI, frame, extra characters or equipment. Source fidelity and axe geometry are paramount.
