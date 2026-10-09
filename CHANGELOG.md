# Changelog

## Unreleased

- Armor goal class labels now use their WoW class colors.

- Fixed goal content escaping short windows. Short panels scroll the whole goal page; taller panels keep the fixed banner and independently scrolling steps.

- Compact armor-set names in My Goals now use title case to match the other goals.

- Installed approved Mage Tier 1 and Tier 2 banners. Armor goal cards use compact set names; the full set title stays on the detail page, with the class beside the category.

- Armor sets now track separately by class, including raid, dungeon, Forever and PvP sets. The Library keeps its grouped browsing. Existing selections and progress migrate automatically; each set has its own notes, reset, completion and banner. Installed five approved Rogue and Hunter tier banners.

- Replaced Slay Onyxia artwork with the approved monochrome orc-and-dragon banner, including soft left and bottom gradients.

- Installed the approved night elf hunter artwork as Rhok'delar's replacement banner, with monochrome treatment and soft left/bottom gradients.

- Installed fifteen approved 1200 x 900 banner assets with baked soft bottom gradients and correct 4:3 proportions. Rhok'delar remains without background artwork.

- Removed the Rhok'delar banner artwork pending a replacement image.

- Installed approved monochrome Lok'delar, Frostsaber, Embrace of the Viper, Cenarion Circle and Skeleton Key banners. Restored the original banner layout after clarifying that the requested extra 100px belongs in the image assets, rather than the addon rendering.

- Added faint, short inner shadows along the goal panel's top and right edges.

- Fixed saved-goal startup hiding the banner animation driver, which prevented the bottom fade strips and first-open animation from displaying.

- Slowed first-open background image fade to 1.1 seconds with smooth easing. Artwork stays anchored at the panel's top-right and fades to transparency at the bottom without a dark overlay.

- Reduced goal background artwork by 8% from its top-right anchor, removed the extra bottom veil, and cropped backgrounds inside the panel. First-open fades redraw artwork gradient opacity over 0.6 seconds; goal icons remain instant. Artwork stays on the original background layer so it remains visible.

- Updated local Forever compatibility checks for 1.60.1 build 70291: startup, client detection, banner layout/image fades and logout pass. Existing interface declaration remains 16001; in-client visual validation remains to be done.

- Goal background artwork gently fades in on the first opening of each goal per session. The square goal icon, text and progress appear immediately; repeat visits stay instant. Respects animations being turned off.

- Installed approved monochrome Ragnaros, Molten Core attunement and Majordomo/Tier 1 banners with 3:2 framing and no redundant addon desaturation.

- Installed approved monochrome weapon and Blackwing Lair banner images with stronger contrast and 3:2 framing. These final textures bypass addon desaturation; older color banners keep their existing treatment. Source options and final JPEG masters are excluded from releases.

- Added artwork credits in Settings, with an unofficial-addon notice and separate code/artwork licensing information.

- Added Thunderfury, Rhok’delar, Onyxia, Blackwing Lair, Dreadsteed and Charger banner artwork.

- Added matching banner artwork for Benediction/Anathema, Quel’Serrar, Molten Core and Naxxramas goals, Tier 1 and Tier 3 sets.

- Banner artwork uses native desaturation and compressed 512px textures with smaller mip levels; originals preserved.

- Goal banner redesign: larger icon/title, spacious outlined chips and description, with subtly vignetted Corrupted Ashbringer, Atiesh and Sulfuras artwork. The taller banner includes the step count above the progress bar at the bottom; personal notes appear above the description.

- Personal notes on each goal: a note icon opens an editor over a darkened window, with gold Save when text is entered, Delete note and a close X; your note appears above the goal description
- Note editor fades and gently pops into place over a greyed-out background; gold Save brightens on hover
- New painted refresh icon for Reset this goal, with a gentle turn when clicked
- Undo reset tooltip counts down the remaining 10-second undo window
- Undo reset restores checkmark animations and the goal progress bar's glide

- First Classic Era step-dependency pass: prerequisite locks, muted-red explanations, click jiggle and breakaway unlock animation. Parallel and alternative prerequisites supported; gathering and completed steps remain available. Forever gates await current-build verification.
- Personal note text is read-only; use the note icon to add or edit.

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
