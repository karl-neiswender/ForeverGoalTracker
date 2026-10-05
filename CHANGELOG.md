# Changelog

## 2.1.2

- Steps read as checklist items, without a closing period.
- Progress bars glide smoothly to their new value instead of jumping.
- Goal Library search box: filter goals by name or category as you type.
- "All" shows every goal. Filters with faction goals (PvP, Reputation, Attunements) get a Both / Alliance / Horde picker with faction crests, starting on Both. Replaces the Alliance and Horde filter chips.
- New goals: Clear Ruins of Ahn'Qiraj (AQ20); Ambassador (Exalted with all four capitals) for each faction; Dreadsteed and Charger epic class mounts; Dungeon Set 1 and Dungeon Set 2 (all 9 classes, with sources and item icons).
- New Attunements category: Molten Core, Onyxia (a full chain for each faction), Blackwing Lair and Naxxramas attunements, plus the Upper Blackrock Spire, Scholomance, Blackrock Depths, Stratholme and Dire Maul keys, each its own goal with its quest steps.
- Set pieces can show their item icon; dungeon keys on the keyring are now detected.
- The My Goals list shows short goal names (for example "Lok'delar"), so nothing gets cut off. The full name still shows when a goal is open and in its tooltip.
- Library cards only show a progress bar for goals on your tracker.
- Step numbers line up with their step text.
- New Tips section under a goal's steps. Steps are now only things you do; advice, strategy notes and optional extras moved to Tips. Existing checkmarks move with their steps.
- 13 more steps tick themselves: picking up a quest now counts (Rhok'delar, Lok'delar, Benediction, Quel'Serrar), plus the Lok'delar demon heads, the Quel'Serrar blades, the Drakefire Amulet and the Ashbringer Naxxramas kills.
- Tier 3 pieces fold open one at a time to show their materials, with a "1 / 3" count per piece. A piece is done when its materials are (or when you own it), so the piece, class and overall counts always agree.
- Tier 1 and Tier 2 set pieces now say where they drop (for example "Helm of Might from Garr").
- Embrace of the Viper: every piece has its item icon.
- New empty state for My Goals: cobwebs, a quiet "Empty" label and a button to the Goal Library. New installs open on it.
- Fixed the window height jumping when you grab the resize corner.
- Fixed the window jumping to odd spots when dragged or reopened.
- Lower memory use: automatic tracking skips steps that are already checked off.
- Consistent line height (120% of the font size) for all text that wraps.
- Short time estimates on one fixed scale (Days, 1-2 Weeks, 2-4 Weeks, 1-2 Months, 3+ Months, Years, Ongoing, Varies) that no longer run past the window edge. Sort by Duration follows the same scale.

## 2.1.1

- New minimap button icon (green checkmark).

## 2.1.0 (first public release)

- Goal Library with 48 goals across legendary and epic weapons, mounts, reputations, raids, item sets, professions, PvP and milestones.
- Pick individual parts of multi-part goals: classes to level, Tier 1/2/3 set classes, epic racial mount races, and professions.
- Separate Alliance and Horde PvP goals, with faction filters in the Library.
- Automatic tracking across all of your characters: levels, items (bags, gear and bank), quests, reputation, professions, gold, mounts, PvP rank, honorable kills and raid boss kills.
- New installs start with an empty tracker and open the Goal Library.
- Resizable, movable window that remembers its size and position.
- Slash commands: `/goals`, `/fgt`, `/forevergoals`; `/goals reset` resets the window.
