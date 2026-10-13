# Next release, draft notes (not released; no version is authorized)

Written to `style-guide.md` from everything on `main` since 2.12.0. Bugs that existed only in unreleased builds are left out. The window gets the list; CurseForge gets the list plus the Developers' notes.

## What's new window (short)

- Added light to goal images: embers, snow, sunlight and a soft bloom on the brightest lights
- You can now Ctrl-click an armor set's icon to try on the whole set
- Added Image effects in Settings: Full, Subtle or Off
- Added social goals for dungeon bosses with guildmates, raiding with guildmates and trades
- Changed goal suggestions to follow your professions
- UI improvements and bug fixes

## CurseForge

### New

- Added light to goal images: embers, snow, sunlight and a soft bloom on the brightest lights, such as flames, gems, eyes and lightning, on 39 banners.
- You can now Ctrl-click an armor set's icon, on its goal page or its Library card, to try on every piece in the dressing room.
- Added Image effects in Settings under Images: Full, Subtle (the drifting clouds only) or Off (the image alone).
- Added a token, idol and scarab checklist to each Tier 2.5 armor piece, the same way Tier 3 lists its materials.
- Added a "Learn Fishing" first step to the Stranglethorn Fishing Extravaganza.
- Added social goals: Dungeons with Guildmates, Raids with Guildmates, Make Trades, Buff Others (Mages, Druids, Priests and Paladins), Place Campfires, and four emote goals from the Statistics window (Give Hugs, Give Cheers, Give Waves and Say LOL), on Forever. They count what you do, across all your characters.
- Changed the icon on Alliance and Horde PvP goals to the PvP rank achievement icons.

### Changes

- Changed goal suggestions to follow your professions. The Fishing Extravaganza is suggested only to characters with Fishing 225 or higher (was every character), and the secondary skills goal lists only the skills you know.
- Changed reputation, Ambassador, battleground reputation and profession goals to show no "Unconfirmed in Forever" notice. Their steps are standings and skill levels the game reports itself.
- Changed Tips to glide open and closed.
- Renamed "WoW Forever" to "Forever" and "Classic" to "Classic Era" in tips and tooltips.
- Renamed the Social interest in the welcome window to Socializing.
- Renamed the Ashbringer card on My Goals to Corrupted Ashbringer.
- Changed gold amounts in tips to "1,200 gold" (was "1,200g").
- UI improvements and bug fixes

### Developers' notes

Image effects are slow by design. Lights, blooms and embers change brightness by a limited amount per second, so nothing flashes. Subtle keeps only the clouds, and Off shows the image alone, for players who want less motion or lower memory use.

### Known issues

- Subtle shows no effects on Classic Era. The clouds use art that only Forever has.
