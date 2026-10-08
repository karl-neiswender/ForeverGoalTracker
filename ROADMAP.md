# Roadmap

What's coming to Forever Goal Tracker, from small touches to big updates. Nothing here has a fixed date, and the order can change as Warcraft Forever evolves and as players tell us what they want most.

Have an idea or found a bug? Leave a comment on [CurseForge](https://www.curseforge.com/wow/addons/forever-goal-tracker) or open an issue on [GitHub](https://github.com/karl-neiswender/ForeverGoalTracker/issues).

## Next up

- **"Needed for" on items:** "Needed for Thunderfury" on items in your bags, the Auction House and loot.
- **Feedback from inside the game:** write a suggestion or report a wrong step in the addon and get a link to send it.
- **Welcome / What's new after an update:** a modal window when a player enters the game after an addon update, introducing the new features. Each feature gets a snapshot in the background with a subtle gradient vignette and text over it explaining the feature. Include a way to skip, pagination when there are multiple features, and subtle text animations or treatments as each page loads in and out.

## Bigger features

New tools that take more building.

- **Custom goals:** create your own goals with a title, difficulty, icon and your own steps, from serious to silly ("Give Billy five high fives"). Steps the game can track tick themselves; the rest you check off by hand. Or copy any Library goal and make it your own.
- **Materials tab:** a dashboard of every material your goals need, how many you have across all your characters, and how close you are. Right-click a "Collect 10 ..." step to pin that item to it.
- **Toasts:** a small note when a step ticks itself while the window is closed, and milestone cheers along the way ("50 down, keep going!").
- **Pop-out tracker:** keep one goal's steps on screen while you play, like the quest tracker.
- **Step dependencies (first Classic Era pass ready for testing):** steps that truly require earlier steps show a lock until their prerequisites are complete. Clicking a locked step gives the lock a small jiggle, with no red tint on the icon; its tooltip explains the missing prerequisites in muted red text. When unlocked, the lock breaks away to reveal the checkbox. One prerequisite can unlock several steps, and a step can require several prerequisites or either of two alternatives. Independent gathering stays available, and automatic evidence or an existing completion overrides the lock. Initial coverage: Lok'delar, Benediction, the first Thunderfury quest, Onyxia attunement for both factions, selected MC/BWL/Naxx attunement actions, and the UBRS/Shadowforge key chains. Full/Subtle/Off motion settings are respected. [Prerequisite research](reports/Goal%20step%20dependency%20audit.md) covers all current goals; the remaining guide corrections and incoming Forever build verification come before extending these gates. Gates remain off on unverified Forever clients.
- **Personal notes (approved in game):** a painted pencil-over-parchment icon opens an editor over the darkened addon window for a short note on each goal. Save turns gold when there is text; Delete note removes a saved note, and the close X discards unsaved edits. Notes start with "NOTE:" and sit between the goal description and the blue Forever notice, or above the progress bar when there is no notice. Add/edit is available only from the note icon; the displayed note is read-only.
- **Character overview:** see which of your characters is furthest along on reputation and leveling goals.
- **Guild announcements:** guildmates who use the addon see when you finish a goal, with an optional line in guild chat (off by default).
- **Share your wins:** a "Copy for Discord" button when you finish a goal.

## Big updates

Larger updates with lots of new content.

- **More Warcraft Forever content:** the new raids' bosses and loot sources as they're revealed, Forever's own items and mounts, and updated steps for Classic goals as Forever confirms them.
- **More goals from your character stats:** Warcraft Forever's Statistics window counts things like gold earned, quests completed and emotes. More goals that track themselves from it, like Duelist does.
- **More goals:** Qiraji battle tanks, Darkmoon Faire decks, Steamwheedle Cartel, Ravenholdt and Shen'dralar reputations, Bloodsail Admiral, the Stranglethorn Fishing Extravaganza, and more class sets.

## Maybe someday

- **Discord companion app:** a small desktop app that posts your finished goals to a Discord channel.

## Recently shipped

- **2.9.0:** visual improvements, more links in guides and tips, and guide fixes.
- **2.8.0:** quest links in every guide, with who starts each quest and where each of your characters stands on it; daily quests in blue; goal links that shimmer in gold.
- **2.7.0:** links in every guide: real item tooltips (shift-click to link in chat), NPC links with their location and a map pin or TomTom waypoint, and Wowhead links for items, NPCs and quests; a setting for where map pins go; hand-painted gold icons; darker tooltips; finished steps that fade back; and goal links that shine.
- **2.6.0:** WoW Forever's new raids (Hyjal Summit and the Barrow Deeps), Forever Raid Sets, and the Field Marshal's and Warlord's PvP sets by armor type; Find your next goal; Edit goal to change a goal's number; Social goals and a Social interest; Duelist from the Statistics window; raid lockouts on raid goals; and an optional screenshot when you finish a goal.
- **2.5.0:** goal suggestions: a welcome that asks what interests you and picks goals for your character; folder-style tabs; a Clear button to empty My Goals; tips that fold away; racial mount and Frostsaber steps that follow your race; a larger default window; and gentle animations throughout.
- **2.4.0:** a Settings page (gear in the title bar) to turn off chat lines, the banner or celebrations, pick a goal-complete sound and its volume channel, hide the minimap button, open on login, and set window scale and opacity; tracked characters you can remove; a keybind; and finished goals and parts marked Complete in green in the Goal Library.
- **2.3.1:** more goal links across the library, and steps you can't check off turned into tips.
- **2.3.0:** WoW Forever markers: a "not confirmed in WoW Forever yet" notice on Classic-based guides, NEW and UPDATED labels in Forever blue, and a "New & Updated" filter, starting with the Skyborne Swift Galestrider and the updated Embrace of the Viper. Plus goal links (click a linked goal in a step to add it), completion dates, undo after reset, Expand all / Collapse all, a cleaner goal card, a richer minimap tooltip and clearer step wording.
- **2.2.0:** favorites and a right-click menu, a login check-in, goal-complete banners and celebrations, real Tier 3 recipes and token sources, item icons for Tier 1 to 3.
- **2.1.2:** Goal Library search, attunements and dungeon keys, Dungeon Sets 1 and 2, AQ20, Ambassador, Dreadsteed and Charger, Tips under each goal.

See the [changelog](CHANGELOG.md) for everything.
