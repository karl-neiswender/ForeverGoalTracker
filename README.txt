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
  /goals             Open or close the window (also /fgt, /forevergoals)
  /goals settings    Open the Settings page
  /goals welcome     Get goal suggestions picked for your character
  /goals reset       Reset the window size and position
  /goals testbanner  Preview the goal-complete banner

You can also bind a key: Options > Keybindings > AddOns > Forever Goal
Tracker.

SETTINGS
--------
Click the gear next to the close button. Everything starts on, the way
the addon has always worked, and each option turns something off or
adjusts it: the login check-in, the goal-complete message and banner,
step updates in chat, celebrations (Full, Subtle or Off), a sound when a
goal completes (and which volume channel it uses), a screenshot when a
goal completes (off unless you turn it on), the minimap button,
opening the window on login, window scale and opacity, resetting the
window, and removing old characters from the tracked list. Changes apply
right away.

THE TWO TABS
------------
My Goals
  The goals you've added. Pick one on the left to see its guide on the
  right. Click a step to tick it by hand; hover a step to see what it
  tracks automatically. Tips under the steps hold advice and strategy.
  The bar at the top shows your overall progress, averaged across your
  goals.
  Right-click a goal on the left to add it to your favorites (they get a
  gold star and stay at the top of the list) or to remove it from your
  tracker. Removing keeps its progress in case you add it back.

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

WARCRAFT FOREVER
----------------
Step guides are written from Classic Era, where they're known to be
accurate. Until Wowhead's Forever database confirms a goal, its page shows
a small "not confirmed in WoW Forever yet" notice. Content that's new in
Forever is marked NEW, and Classic content Forever changed is marked
UPDATED, both in blue; the Library's "New & Updated" filter lists them.

Gold text in a step or tip is a link to another goal it depends on (an
attunement, a reputation, a raid). Click it to add that goal.

NOTES
-----
Drop rates and costs are estimates; check a live source such as Wowhead
before planning a raid night around one.

Made with the help of AI. Every change is tested in game and approved by
a human before release.

LICENSE
-------
MIT (see LICENSE.txt). The Cinzel font is included under the SIL Open
Font License (see Fonts/OFL.txt).
