Forever Goal Tracker
====================

A goal tracker for Warcraft Forever. Pick long-term goals from a built-in
library, follow step-by-step guides, and let the addon track your progress
automatically across all of your characters. It also loads on Classic Era.

GETTING STARTED
---------------
1. Install the ForeverGoalTracker folder into your AddOns folder, e.g.
     World of Warcraft/_classic_beta_/Interface/AddOns/ForeverGoalTracker
   (the .toc file should sit directly inside ForeverGoalTracker).
2. Restart the game and make sure Forever Goal Tracker is enabled on the
   AddOns list at character select.
3. Type /goals or click the minimap button. Your tracker starts empty;
   click "Browse the Goal Library" to choose which goals to track.

SLASH COMMANDS
--------------
  /goals          Open or close the window (also /fgt, /forevergoals)
  /goals reset    Reset the window size and position

THE TWO TABS
------------
My Goals
  The goals you've added. Pick one on the left to see its guide on the
  right. Click a step to tick it by hand; hover a step to see what it
  tracks automatically. Tips under the steps hold advice and strategy.
  The bar at the top shows your overall progress, averaged across your
  goals.

Goal Library
  Every goal the addon knows (65 and counting). Search by name, or use
  the filter chips to browse by type; PvP, Reputation and Attunements
  also have a Both / Alliance / Horde picker. Click "+ Add" to put a
  goal on your tracker. Goals with several parts (classes, professions, mount races,
  set classes) have a "Choose" button so you can add only the parts you
  want.

AUTOMATIC TRACKING
------------------
Each character you log into is remembered. Steps tick themselves when a
rule is met on any of your characters:
  - Level and XP (per class and per race)
  - Items in your bags, gear, keyring and bank (open your bank once per
    character)
  - Quests picked up and completed
  - Reputation standing
  - Profession skill levels
  - Gold on hand
  - Mounts you own
  - PvP rank (current or highest ever) and lifetime honorable kills
  - Raid boss kills seen while the addon is running

Steps never untick on their own, because some items are used up along the
way. Owning a goal's final reward completes the whole goal. Faction goals
only count characters of that faction, and racial mount goals only count
characters of that race.

A character only appears in tracking after you've logged into it once
with the addon installed.

GOAL TYPES
----------
Legendary and epic weapons, mounts (including the Warlock and Paladin
epic mounts), reputations, raid clears, raid attunements and dungeon keys,
item sets (Dungeon Sets 1 and 2, Tier 1, 2 and 3, Embrace of the Viper),
professions, PvP ranks and reputations for each faction, and milestones
such as leveling every class.

NOTES
-----
Step guides are written for classic-era rules. Drop rates and costs are
estimates; check a live source such as Wowhead before planning a raid
night around one.

LICENSE
-------
MIT (see LICENSE.txt). The Cinzel font is included under the SIL Open
Font License (see Fonts/OFL.txt).
