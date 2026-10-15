# Bloom and effect pass, 2026-10-15

Karl asked for a bloom and effect pass over the banner images added in the last day. Each master was
read on a 0.1 grid (see `tools/gridview.py`); lights were placed from that, blooms baked with
`tools/bloomall.py` (strength per image in `B.bloomStrength`), effects in `B.glows` (Core.lua).

| Banner | Bloom | Effect |
|---|---|---|
| Zin'rokh | the burst at the blade's tip, the eye in the guard | sparks thrown off the burst |
| Warlord's cloth (Horde) | the spell sparks at both hands (0.6) | sparkles drifting off each hand |
| Marshal's cloth (Alliance) | the arcane streams and lightning (0.4) | arcane dust in the streams |
| Marshal's leather (Alliance) | the full moon (0.5) | a soft glow on the moon, a few night motes |
| Warlock Tier 3 (Horde art) | the mask's eyes, the succubus's eyes, the shoulder gem (0.5) | none |
| Raids with Guildmates | the glare behind the dragon's head (0.4) | dust in the light at its feet |
| Warrior Tier 3 (Koringar) | the visor and the mace's lightning (0.5) | none |
| Undead epic mount | the ghost flames and the moon (0.5) | ghost-fire sparks off the hooves |
| Striker's Garb (AQ40 Hunter) | none | daylight through the trees, motes |
| Dragonstalker, Alliance art | none | daylight over the valley, motes |
| Make Trades | none | falling snow |

Skipped on purpose (no light source in the picture, or nothing that would not read as noise):
Arcanite Reaper, AQ40 plate and leather, Tauren epic mount. Stormrage (Horde art) already had its bloom
from the 2026-10-13 pass; only its name changed.

Needs a full game restart (eight new bloom textures). Not yet seen in game.
