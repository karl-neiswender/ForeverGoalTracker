# Five Alliance character banners, 2026-10-28

Five grayscale 4:3 review images were prepared from untouched sources.
Karl explicitly marked the female Gnome Warlock image good, and it is
installed. Karl subsequently approved the other three first reviews, now
installed as character-specific banners. Karl scrapped
the male Gnome Warrior candidate because the low-resolution card source
could not support a faithful enlargement. Neither v1 nor v2 is installed
or mapped to a goal. V2 improved the helmet and shoulders but still depicted
the raised axe as too circular. The untouched original remains available.

| Intended slot | Untouched source | Review | State |
|---|---|---|---|
| Dwarf female Hunter leveling | `Media/artwork/alliance-dwarf-female-hunter-generic.jpg` | `Media/final-images/dwarf-female-hunter-review-2026-10-28-v1.png` | Approved and installed |
| Gnome male Warrior Tier 2 | `Media/artwork/alliance-gnome-male-warrior-tier2.jpg` | `Media/final-images/gnome-male-warrior-tier2-review-2026-10-28-v1.png`; `Media/final-images/gnome-male-warrior-tier2-review-2026-10-28-v2.png` | Scrapped, not installed |
| Gnome female Warrior PvP plate | `Media/artwork/alliance-gnome-female-warrior-pvpset-plate.png` | `Media/final-images/gnome-female-warrior-pvp-review-2026-10-28-v1.png` | Approved and installed |
| Gnome female Warlock leveling | `Media/artwork/alliance-gnome-female-warlock-leveling.png` | `Media/final-images/gnome-female-warlock-leveling-review-2026-10-28-v1.png` | Approved and installed |
| Dwarf female Rogue Tier 1 | `Media/artwork/alliance-dwarf-female-rogue-tier1.jpg` | `Media/final-images/dwarf-female-rogue-tier1-review-2026-10-28-v1.png` | Approved and installed |

Printed card credits: Weeble (female Gnome Warrior) credits Alex Horley
Orlandelli; Stella Forgebane (female Dwarf Rogue) credits Ralph Horsley.
Other credits are not verified. Do not invent them. The approved Warlock
source has no printed credit. The untouched source files remain in
`Media/artwork`.

## Installed female Gnome Warlock

The approved review became
`Media/final-images/leveling/gnome-warlock-female-master.png`, a neutral
1200 x 900 master, and `Media/allclasses_gnome_warlock_female-banner.blp`,
a 512px DXT1 BLP with ten mip levels. `Core.lua` selects it only for
Alliance female Gnome Warlocks; male Gnomes and other Alliance Warlocks
retain the existing Alliance Warlock art. The rebuild map, runtime manifest
and artwork checklist include the new banner. A full game restart is
required to see the texture. Native appearance is pending.
The checklist rebuilt 240 thumbnails with no missing files and `tools/check.py`
passed after the Warlock mapping. The retained log is
`reports/checks/gnome-warlock-female-check-2026-10-28.txt`.

## Installed approved character variants

The three additional reviews became neutral 1200 x 900 masters and 512px
DXT1 BLPs with ten mip levels:

- Female Dwarf Hunter leveling:
  `Media/allclasses_dwarf_hunter_female-banner.blp`. Male Dwarves retain
  `allclasses_dwarf_hunter-banner.blp`.
- Female Gnome Warrior PvP plate:
  `Media/pvp_set_plate_ally_warrior_gnome_female-banner.blp`. Other Alliance
  Warrior PvP characters retain `pvp_set_plate_ally-banner.blp`.
- Female Dwarf Rogue Nightslayer:
  `Media/set_tier1_rogue_dwarf_female-banner.blp`. Other Alliance Rogues
  retain `set_tier1_rogue-alliance-banner.blp`.

`Core.lua` selects character-specific variants. The PvP resolver now retains
race and sex only when the logged-in character's faction matches the PvP
goal's faction, while keeping the goal's faction for all viewers. The
checklist, rebuild map and runtime manifest include the new assets. The
original sources are untouched. Native visual review is pending; a full
game restart is needed for new textures.
The artwork checklist rebuilt 243 thumbnails with no missing files.
`tools/check.py` passed with targeted banner resolver coverage; retained
output: `reports/checks/three-alliance-classes-check-2026-10-28.txt`.

## Exact image prompts

Each initial prompt below ended with the same banner instruction:

> Make one 4:3 landscape Forever Goal Tracker banner intended for a 1200x900 master. Detailed painterly Warcraft style in strictly neutral black and white with moderate contrast, rich midtones and controlled highlights. Place the character high toward the RIGHT side with breathing room and leave a quiet left third for addon text. Bake a broad smooth dark charcoal gradient into the LEFT edge with no hard vertical strip, and a soft dark gradient across the lowest approximately 100 pixels fading to near-black at the bottom edge. Both fades are part of the image. No added text, UI, borders, watermarks, signatures, unrelated objects or extra characters.

### Dwarf female Hunter

> Use case: style-transfer. Preserve the original red-haired female dwarf hunter with two pigtails, green-and-gold armor, both hands and long gun, and her white striped sabertooth companion in the snowy pine forest. Keep the whole hunter and sabertooth identifiable, including gun barrel and beast's face. Remove the artist signature from the derivative; preserve the untouched source. Recompose to landscape without losing the character or pet.

### Gnome male Warrior Tier 2, first attempt

> Use case: style-transfer from a small World of Warcraft trading card. Remove the entire trading card frame, title, numbers, rules text, logo and copyright. Preserve the INNER PAINTING: a tiny male gnome warrior in bulky pointed Tier 2 Wrath plate armor and horned helm, standing heroically atop a pile of fallen armored foes, holding a spiked weapon in a stormy gold sky. Keep the gnome's short stature, armor silhouette, weapon and dramatic pose recognizable; enlarge with painterly detail rather than inventing a different warrior.

### Gnome female Warrior PvP plate

> Use case: style-transfer from the Weeble trading card. Remove all trading card frame, title, numbers, rules text, icons and copyright. Preserve the INNER PAINTING: fierce female gnome warrior with bright pigtails in ornate PvP plate armor, both hands gripping a huge silver double-edged sword, lunging forward against a warm fiery backdrop with blue swirling magic. Preserve her small stature, face, pigtails, armor and complete sword geometry; do not turn her into a human or add weapons.

### Gnome female Warlock leveling

> Use case: style-transfer. Preserve the playful purple-haired female gnome warlock in teal-purple robes with her long staff, open conjuring hand and sparkling violet magic, and the snarling demonic creature on the right. Keep gnome short stature, face, hands, staff and demon recognizable, translating all color and magic to neutral grayscale. Preserve the original painterly charm and scene.

### Dwarf female Rogue Tier 1

> Use case: style-transfer from the Stella Forgebane trading card. Remove entire trading card frame, title, numbers, rules text, icons and copyright. Preserve the INNER PAINTING: female dwarf rogue in dark angular Tier 1 Nightslayer leather armor with mask/hood, red scarf and compact blades, crouching on rocky ground against a warm glowing cavern or mountain scene. Preserve her short dwarf stature, armor, hands, blade geometry and crouched action pose; do not invent a different character.

### Gnome male Warrior Tier 2, targeted correction

> Use case: precise-object-edit. Image 1 is the grayscale landscape review to correct. Image 2 is the user's enlarged crop of the ACTUAL gnome warrior card art and is the authoritative reference for gear details. Keep Image 1's overall 4:3 composition, gnome's short scale and pose atop fallen armored enemies, sky, dark quiet left third, baked left fade and bottom fade. Correct the warrior's armor and weapon silhouette to match Image 2 closely: HELMET has an extremely tall asymmetrical angular horn rising on image-left, gold V trim around a narrow steel face mask, one shorter horn on image-right and a central round fitting. Do not give him a long beard or oversized face guard. Both SHOULDER PADS are comparatively small rounded overlapping plate pauldrons with gold trim, not large embellished shields. In the raised hand at image-right, the weapon is a narrow dark open hooked axe or claw head with several sparse curved outward black prongs and small red tips, NOT a circular sun-shaped bladed ring. The lowered hand at image-left holds the long spiked poleaxe from Image 2. Preserve the short compact torso and leg armor as in the card. Translate card colors to neutral black and white. Do not change the scene, add objects, text, UI, border, or extra characters.
