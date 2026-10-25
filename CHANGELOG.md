# Changelog

## Unreleased

- Added Ashkandi, Greatsword of the Brotherhood, a Blackwing Lair sword dropped by Nefarian, to the Goal Library.
- Added Perdition's Blade, a Molten Core dagger dropped by Ragnaros, to the Goal Library.
- Added Obsidian Edged Blade, a Molten Core sword dropped by four of its bosses, to the Goal Library.
- Added Mograine's Might, a Scarlet Monastery mace dropped by Scarlet Commander Mograine, to the Goal Library.
- Added Mandokir's Sting, a Zul'Gurub bow dropped by Bloodlord Mandokir, to the Goal Library.
- Added Will of Arlokk, a Zul'Gurub healing staff dropped by High Priestess Arlokk, to the Goal Library.
- Added Krol Blade, a rare epic one-handed sword that level 53 to 60 creatures can drop, to the Goal Library.
- Added Jin'do's Judgement, a Zul'Gurub staff dropped by Jin'do the Hexxer, to the Goal Library.
- Added Inventor's Focal Sword, a Maraudon sword dropped by Tinkerer Gizlock, to the Goal Library.
- Added Illusionary Rod, a Scarlet Monastery staff dropped by Arcanist Doan, to the Goal Library.
- Added Halberd of Smiting, a Zul'Gurub polearm dropped by Bloodlord Mandokir, to the Goal Library.
- Added Gutgore Ripper, a Molten Core dagger dropped by Garr, to the Goal Library.
- Added Glacial Blade, a Frostwolf Clan dagger for the Horde, to the Goal Library.
- Added Gift of the Elven Magi, a Stratholme dagger dropped by Balnazzar, to the Goal Library.
- Added Frostguard, a Blacksmithing sword for Master Swordsmiths, to the Goal Library.
- Added Flame Wrath, a Blackrock Depths polearm dropped by Ambassador Flamelash, to the Goal Library.
- Added the Lava Dredger, a Molten Core mace from the Cache of the Firelord, to the Goal Library.
- Added Deathbringer, an Onyxia's Lair axe dropped by Onyxia, to the Goal Library.
- Added Bonereaver's Edge, a Molten Core sword dropped by Ragnaros, to the Goal Library.
- Added Slay Lord Kazzak, the Blasted Lands world boss, to the Goal Library, with a map pin to the Tainted Scar.
- Added Headmaster's Charge, a Scholomance staff dropped by Darkmaster Gandling, to the Goal Library.
- Added Aurastone Hammer, a Molten Core mace dropped by Garr, to the Goal Library.
- Added Destiny, a rare epic two-handed sword that level 52 to 60 creatures can drop, to the Goal Library.
- Added The 1 Ring, a very rare fishing catch, to the Goal Library in a new Collectibles category, with a count of the fish you have caught since you added the goal.
- Added locks on steps that need a level, reputation, skill or quest you have not reached. A click says what is needed, and Shift-click unlocks the step for the session.
- Updated the Onyxia's Lair attunement and raid notes with Blizzard's Forever route, and a reminder to keep the Drakefire Amulet in your inventory (it does not need to be equipped).

## 2.16.0

- Added Gear Planner: plan a gear set slot by slot on your character, with item search, filters and where each item comes from.
- Added enchants and scopes to Gear Planner, tracked as goal steps with their materials.
- Added a level range to each gear set, and gear set goals with your character's leveling artwork.
- Added Library goal links in Gear Planner: legendaries and sets open or add their goal.
- Added Start from my current gear, and hints when another character holds a piece of your set.
- Added a character preview with racial backdrops and weather, and Z to sheathe weapons in Gear Planner.
- UI improvements and bug fixes.

### Developers' notes

Gear Planner item lists are generated from the game's own client tables for Classic Era 1.15.9 and Warcraft Forever 1.60.1. Where an item comes from is imported from classic.warcraftdb.com and forever.warcraftdb.com; Forever's drops are loot players saw in the beta and remain Unconfirmed. Items Forever has changed show Forever's version, marked Updated in Forever.

Each set plans for a level range: gear above the set's highest level is left out, lower-level items always stay available, and every armor type your class can wear at that level is listed. Items with no level requirement are planned at the level of the content they come from.

A gear set counts only its own character's items. Items held by another character show where they are, and whether they can be mailed or are soulbound.

The addon now says once in chat when a newer version is out. It learns this from guildmates and group members who run the addon, since an addon cannot look anything up online; only the version number is shared, and Settings > Chat and alerts > Version reminders turns it off.

Known issues: when you plan for another character, the preview may show your character's race instead of theirs. Items Forever has not revealed yet are listed from Classic data and marked Not revealed yet.

This release was tested in Classic Era. The Warcraft Forever beta closed before the final round of testing, so how Gear Planner behaves on Forever, including its racial backdrops, weather effects and the sheathe key, is unconfirmed.

## 2.15.2

- Added Hide completed goals to My Goals, with the choice remembered after reloads.
- Changed New & Updated to list matching sets and mounts individually.
- Changed item set guides to show pieces directly, with expandable requirements for Tier 3 and Tier 2.5.
- Changed completed goal cards to use darker backgrounds and green completion markers.
- Fixed character filtering for Buff Other Players and wrapping in narrow item set guides.
- UI improvements and bug fixes.

### Developers' notes

War mount guides now name each faction’s vendor and link its capital city to the PvP hall approach. Forever positions remain unconfirmed. Steps with a location link no longer repeat Show on map.

Arcanite Reaper’s Blacksmithing step now shows its step number. Hyjal Summit and the Barrow Deeps no longer repeat their single objective as a small progress bar. Goal progress and item requirements are preserved.

## 2.15.1

- Added clickable dungeon names with entrance pins in guides.
- Added map links for Light's Hope Chapel, City of Dalaran and both Ahn'Qiraj raids.
- Added Darkspear Islands reputation goals and Teebu's Blazing Longsword.
- Added more goal artwork and corrected several background selections.
- Changed Stratholme map links to start at 44% zoom and clarified dungeon locations in several guides.
- Fixed Alliance Warrior Tier 3 to use its Dwarf artwork and Beastmaster to use its dedicated background.
- UI improvements and bug fixes.

## 2.15.0

- Added a map view to goal pages: a pin button fades the banner to the zone map, with a gold pin on the person your next step needs.
- Added Show on map links to steps, to the Exalted reputation goals and to the Onyxia and Zul'Gurub raid goals.
- You can now zoom the map with the mouse wheel or the slider, always around the pin.
- Added the Zin'rokh, Destroyer of Worlds and Arcanite Reaper goals, with the Reaper's ingredients in the Materials panel.
- Added banners for the new goals, the Marshal and Warlord cloth and leather sets, Make Trades and Raids with Guildmates.
- Added blooms, fire, snow and sunlight to more goal images.
- Changed the Goal Library's faction filter to hide the other faction's goals, even ones you have added.
- Changed the Field Marshal and Warlord sets to also show under Item Sets.
- Changed the Charger to an Alliance goal (was both factions).
- Changed steps to drop place names that the Show on map link now covers.
- Changed the Wolfsbane steps to name the quest givers, so they link to the map.
- Fixed the Horde Druid's Stormrage banner, which was filed under Dreamwalker.
- UI improvements and bug fixes

### Developers' notes

The map uses the game's own zone map tiles, with the areas your character has discovered drawn over them, so no map art ships with the addon. The map keeps the pin near the upper right of the banner and never shows past the bottom of the zone map; zoom starts from the widest view and each step can set its own starting zoom.

Raid entrance spots come from the game's dungeon entrance data, turned into zone-map coordinates with Classic Era's map bounds. They are not yet confirmed in Forever, and the tooltip says so there. Onyxia's Lair and Zul'Gurub are the two raids with a clear spot on one zone map.

The busiest new banners (Raids with Guildmates and Warlord's cloth, each with about 150 particles) cost about 0.1 ms per frame at 60 frames a second, with no new memory use.

### Known issues

- Molten Core, Blackwing Lair, Ruins and Temple of Ahn'Qiraj, Naxxramas, Hyjal Summit and the Barrow Deeps have no Show on map link, because their entrances are not on one clear zone map yet.

## 2.14.0

- Added a pop-out window for a goal's steps. Pop it out from the guide, keep it on screen while you play, resize it, change its opacity and bring it back with one click.
- Added a goals list that folds to a slim icon rail, so the goal page gets more room. The handle sits on the list's edge, and the choice is remembered.
- Added Partners in Crime, a Forever-only goal to collect both rings.
- Added Summon Players, a Warlock goal that counts the Ritual of Summoning rituals you begin.
- Added blown sand, with a steady wind, to the Ahn'Qiraj, Cenarion Circle and Qiraji mount banners, all Tier 2.5 sets and Dungeons with Guildmates.
- Added glints to the stars on the Brood of Nozdormu banner, and more light motes to the Stormwind Ambassador and the Grand Marshal and High Warlord banners.
- Added banners for Partners in Crime, Summon Players, Waves, Guild, Dungeons with Guildmates and the Grand Marshal and High Warlord goals.
- Changed the main window's resize grip to light up gold on hover.
- Changed Classic Era to show the drifting clouds and leaves, using art made for the addon.
- Changed the Grand Marshal and High Warlord goals to use their achievement icons.
- Changed goal images to fade their light effects while a panel opens or closes, so nothing lags behind the art.
- Removed the Large goal photos setting. Goal images are always large.
- UI improvements and bug fixes

### Developers' notes

The pop-out is a single interactive window. It always sits in front of the main window, and clicking either window does not change which is on top. Banner particles are clipped to the artwork's edges and scale with it as the side panels open and close.

Sand and wind follow the same limits as the other image effects: nothing flashes. Image effects Subtle and Off still apply. Each particle moves at most about 80 times a second, so a fast frame rate does not raise the cost. A banner with 110 particles measured about 25 ms of every second at 192 frames a second, in game.

## 2.13.0

- Added light to goal images: embers, snow, sunlight, windy leaves and a soft bloom on the brightest lights, such as flames, gems, eyes and lightning, on many banners.
- Added an Image effects setting under Images in Settings: Full, Subtle (the drifting clouds only) or Off (the image alone).
- Added Ambassador banners for each race's capital: Ironforge for Dwarves and Gnomes, Darnassus for Night Elves, Thunder Bluff for Tauren and Undercity for the Undead.
- Added banners for Buff Others (one each for Mage, Druid, Priest and Paladin), Making Friends, Give Cheers, the Marshal and Warlord plate sets and the Horde war mount.
- You can now Ctrl-click an armor set's icon, on its goal page or its Library card, to try on every piece in the dressing room.
- Added social goals: Dungeons with Guildmates, Raids with Guildmates, Make Trades, Buff Others (Mages, Druids, Priests and Paladins), Place Campfires, and four emote goals from the Statistics window (Give Hugs, Give Cheers, Give Waves and Say LOL), on Forever. They count what you do, across all your characters.
- Added a token, idol and scarab checklist to each Tier 2.5 armor piece, the same way Tier 3 lists its materials.
- Added a "Learn Fishing" first step to the Stranglethorn Fishing Extravaganza.
- Added artist credits for more of the artwork.
- Changed goal suggestions to follow your professions. The Fishing Extravaganza is suggested only to characters with Fishing 225 or higher (was every character), and the secondary skills goal lists only the skills you know.
- Changed reputation, Ambassador, battleground reputation and profession goals to show no "Unconfirmed in Forever" notice. Their steps are standings and skill levels the game reports itself.
- Changed Tips to glide open and closed.
- Changed the icon on Alliance and Horde PvP goals to the PvP rank achievement icons.
- Changed gold amounts in tips to "1,200 gold" (was "1,200g").
- Renamed "WoW Forever" to "Forever" and "Classic" to "Classic Era" in tips and tooltips.
- Renamed the Social interest in the welcome window to Socializing.
- Renamed the Ashbringer card on My Goals to Corrupted Ashbringer.
- Fixed the addon's memory use climbing quickly while the tracker was open.
- UI improvements and bug fixes

### Developers' notes

Image effects are slow by design. Lights, blooms and particles change brightness by a limited amount per second, so nothing flashes. Subtle keeps only the clouds, and Off shows the image alone, for players who want less motion or lower memory use.

The tracker used to create about 5 MB of short-lived memory a second while it was open, mostly from the border animation on goal cards, which the game cleaned up in bursts. It now creates almost none. The effects themselves cost about 1 to 6 ms of every second, measured in game.

### Known issues

- Subtle shows no effects on Classic Era. The clouds use art that only Forever has.

## 2.12.0

- New Goal Library filters: search, show added or not, filter for your character or any class, faction and category, with sorting (including Progression for armor sets) and Add all
- Filter for a class or your character to see its armor sets (and your race's mount) as their own goals
- Search My Goals, and show only the goals your current character can do
- Materials panel on each goal: everything it still needs, counted across your characters
- What's new button with a short release ledger
- Soft drifting dust on the goal page in Forever
- Forever racial mount budgets updated to 1,200g
- UI improvements
- Bug fixes, including Copy Character Name being blocked after clicking a chat link

## 2.11.1

- Fix profession scanning and select artwork from the logged-in character’s professions
- Add and refresh profession, reputation, dungeon, raid, mount and armor-set artwork
- Show artist credits with the artwork, with smoother fades on goal pages
- Ctrl-click mount items and color variants in guides to preview them
- Add Wolfsbane for Undead Paladins in Forever, including weapon training
- Clarify guide milestones and item sources while preserving saved progress
- Improve progress-bar animation performance

## 2.11.0

- Needed for hints on item tooltips, with remaining supplies for tracked goals
- Ctrl-click gear in guides to preview it on your character
- Show or hide completed guide steps
- Tier 2.5 armor sets, Stranglethorn Fishing Extravaganza and four AQ battle tank goals
- More artwork, including an ancient leather book behind the empty tracker
- UI improvements
- Bug fixes

## 2.10.1

- UI improvements
- More banner images
- Violet Sorcerer's Vestments goal
- Bug fixes

## 2.10.0

- Personal notes on goals
- Individual armor set goals
- Prerequisite locks on Classic Era
- Goal banner artwork
- Visual improvements
- Bug fixes

## 2.9.0

- Visual improvements
- More links in guides and tips
- Guide fixes and bug fixes

## 2.8.0

- Quest links: hover a quest in a guide to see who starts it and where each of your characters stands on it
- Daily quests show in blue
- Goal links shimmer in gold, so they stand apart from quest links
- Guide fixes: A Proper String starts with Stoma the Ancient, Thunderfury's Bindings now link
- UI improvements and bug fixes

## 2.7.0

- Item tooltips: hover an item in a guide to see its real tooltip, shift-click to link it in chat
- NPC links: hover an NPC to see where they are, shift-click to put a pin on your map (TomTom supported)
- Wowhead links: right-click an item, NPC or step to copy its Wowhead page
- New setting: choose where map pins go (TomTom or the game map)
- New hand-painted gold icons throughout
- UI improvements and bug fixes

## 2.6.1

- Fixed a crash when logging out or exiting WoW Forever

## 2.6.0

- New WoW Forever raids: Hyjal Summit and the Barrow Deeps
- Forever Raid Sets, plus the Field Marshal's and Warlord's PvP sets
- Find your next goal: suggestions picked for you at the end of My Goals
- Edit goal: change the number on goals like Save 5,000 Gold
- New Social goals, and a Social interest in the welcome wizard
- New goal: Duelist
- Raid goals show when you're saved this week
- Optional screenshot when you finish a goal (off by default)
- UI improvements and bug fixes

## 2.5.2

- Smaller download

## 2.5.1

- Hand-drawn interest icons in the welcome wizard
- A new painted look for the empty tracker
- UI improvements

## 2.5.0

- Welcome wizard: tell it what you enjoy and get goals picked for your character
- Clear all your goals at once
- Any race in your faction can now earn any of its epic racial mounts
- Larger default window
- UI improvements and bug fixes

## 2.4.0

- Settings page: turn messages, banners, celebrations and sounds on or off, hide the minimap button, scale the window, and more
- Optional sound when you finish a goal
- Keybind to open and close the tracker
- UI improvements

## 2.3.1

- More goal links across the Goal Library
- Clearer steps in a few goals

## 2.3.0

- WoW Forever markers: see what's new or changed in Forever, and what isn't confirmed yet
- New Skyborne mount: the Swift Galestrider
- Goal links: click a linked goal in a step to add it
- Completion dates on finished goals
- Undo after resetting a goal
- Expand all / Collapse all for goals with many parts
- Clearer step wording across the library
- UI improvements

## 2.2.0

- Favorites and a right-click menu on My Goals
- A goal-complete banner and celebrations
- Real Tier 3 recipes and token sources
- Item icons for Tier 1 to 3
- UI improvements and bug fixes

## 2.1.2

- Goal Library search
- New goals: Ruins of Ahn'Qiraj, Ambassador, Dreadsteed, Charger, Dungeon Sets 1 and 2
- Attunements and dungeon keys
- Tips under each goal
- More steps tick themselves
- UI improvements and bug fixes

## 2.1.1

- New minimap button icon

## 2.1.0 (first public release)

- Goal Library with 48 goals: legendary and epic weapons, mounts, reputations, raids, item sets, professions, PvP and milestones
- Automatic tracking across all of your characters
- Pick the parts you want from bigger goals (classes, set classes, mount races, professions)
