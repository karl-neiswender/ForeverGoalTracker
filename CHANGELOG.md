# Changelog

## Unreleased

- Goal Library: finished goals get the same finished look as on My Goals (green wash, greyed icon, no progress bar) with "Completed <date>" on their info line.
- Settings: sound choices go grey when you wouldn't hear them. If game sound is off (or Master is at 0%) the whole sound section dims; a channel that's unchecked or at 0% in Options > Sound dims on its own. Grey buttons can't be picked; hover one to see why ("Your music channel is disabled"). They update live as you change the game's sound settings.
- My Goals and Goal Library are now folder tabs: the open tab has a gold-edged box with rounded corners that curves into a line under the row. The Library no longer repeats its name inside the page.
- Epic Racial Mounts: any race in your faction can earn any of its racial mounts. Each mount now reads "Level a Horde character to level 60", "Reach Exalted with the Darkspear Trolls" (optional for Trolls), riding, gold and the purchase, and counts every character of the faction, not just that race. Your saved progress moves with the steps.

## 2.4.0

- Settings page: click the gear next to the close button (or type /goals settings). Turn off the login check-in, the goal-complete message or banner, and step updates in chat; set celebrations to Full, Subtle or Off; pick a sound for finished goals (Level up or Quest turn-in) and which game volume channel it plays on; hide the minimap button; open the window on login; change the window scale and opacity; reset the window; and remove old characters from the tracked list. Everything starts the way the addon already worked. Also listed under Options > AddOns.
- Keybind: Options > Keybindings > AddOns > Forever Goal Tracker opens and closes the tracker.
- Goal Library: finished parts of a goal (a race, a class, a profession) get the finished look, with a green check and a greyed icon instead of a full bar. Finished goals and parts show a green "Complete" button instead of "Added"; hover it to remove, as before.
- The goal-complete banner always shows above the tracker window, instead of behind its edges.
- Epic Racial Mounts has a short description; the details (reputation discount, colors) moved to Tips.

## 2.3.1

- Steps you can't check off ("Join a raid team", "Get a group") are now tips, in Corrupted Ashbringer, Deathcharger, Swift Razzashi Raptor and Swift Zulian Tiger. Your checkmarks move with their steps. Black Qiraji's steps are now concrete actions.
- More goal links: Molten Core, Onyxia, Naxxramas and Ahn'Qiraj in the legendary and epic weapon guides link to their raid goals, Upper Blackrock Spire links to its key, Scholomance (Charger) links to the Skeleton Key, the Zul'Gurub mounts link to the Zul'Gurub raid, and Deathcharger links to the Key to the City.

## 2.3.0

- WoW Forever notice: every goal is written from Classic Era data, and nothing is confirmed for WoW Forever until it shows up in Wowhead's Forever database after launch. Goals not confirmed yet carry a slim blue notice with the WoW Forever logo on the goal page, and a note in their tooltips (Forever client only).
- Two labels: NEW for things that only exist in WoW Forever, UPDATED for Classic content that Forever changed.
- Anything new in WoW Forever is themed in blue instead of gold (cards, open rows, progress bars, icon frames), with a light blue NEW label and a glowing dot. It only appears on the Forever client.
- Epic Racial Mounts: new Skyborne part, the Swift Galestrider (Genn Fairweather, Zephras Isle; about 1,200 gold with Journeyman Riding). All races' steps now use the same wording. On the Forever client the other races' riding step now says Journeyman Riding, as Forever calls it.
- Embrace of the Viper is marked UPDATED in WoW Forever: its new set bonus turns you into a snake (Forever client only).
- Goal Library: a blue "New & Updated" filter lists every goal that is new in WoW Forever or updated by it (Forever client only).
- Finished goals in My Goals drop their difficulty label, leaving room for COMPLETE.
- My Goals cards: a bigger icon, and once a goal is finished its progress bar turns into the day it was completed. Hovering a card shows how many steps are done.
- Completion dates: finished goals remember the day, shown on the card, its tooltip, the goal page and the minimap tooltip. (Goals finished before this update have no date.)
- Expand all / Collapse all for goals with several groups (mount races, set classes), and a group folds itself closed a moment after you finish it. Open groups are now remembered per goal.
- Undo: after "Reset this goal", the button offers "Undo reset" for 10 seconds.
- Clearer step wording across the library: each step now reads as one action with where to do it (for example "Loot The Eye of Divinity from Majordomo Executus in Molten Core"). Advice and drop chances moved to Tips.
- Goal links: when a step or tip depends on another goal (like the Naxxramas attunement or Honored with the Argent Dawn), that text is a gold link. Click it to add that goal to My Goals, or to open it if you already track it.
- The minimap button tooltip shows your overall progress and each favorite goal's next step.
- Level Classes to 60 and Save 5,000 Gold are confirmed for WoW Forever, so they no longer show the notice.

## 2.2.0

### New
- Favorites: right-click a goal in My Goals and choose Add to favorites. Favorites get a gold star and their own group at the top of the list, above a thin divider. Both groups follow the sort you pick.
- Right-click a goal in My Goals to remove it from your tracker. Its progress is kept if you add it back.
- On login and /reload, chat shows your overall progress with a random cheer ("You've completed 34% of your goals. Look at you go!") and a link to open the tracker.
- Finish a goal while the window is closed (a drop, a quest turn-in) and chat tells you, with a clickable link to the goal, while a "Goal complete" banner celebrates near the top of the screen. Click the banner to open the goal. Type /goals testbanner to preview it.

### Item sets
- Tier 3 pieces list their real recipe from the quartermaster: the Desecrated token, the exact number of Wartorn scraps, and the exact crafting materials. Ticks on the old placeholder crafting materials are cleared; token and scrap ticks stay.
- Each Desecrated token says which Naxxramas boss drops it (for example "Desecrated Helmet from Thaddius").
- New Tier 3 tips: Naxxramas attunement, every class's quartermaster, and where scraps drop.
- Tier 1, Tier 2 and Tier 3 pieces show their item icons.

### Celebrations and finished goals
- Ticking a step pops its checkmark in.
- When a group finishes while you watch (a mount race, a set class), a gold ring bursts out of its border, a metallic gold shine sweeps across, and a green check pops in.
- When a goal finishes, its progress bar gets a gold shine at 100% and its card in My Goals celebrates the same way.
- Finished groups and goals stay easy to spot: a green check in place of the count, a soft green glow, and a greyed-out icon. Finished goal cards get a big green check over the icon.

### Fixes
- A goal's progress bar no longer replays its fill animation each time you open the goal.
- Fixed the Shaman Tier 3 set name (The Earthshatterer).

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
