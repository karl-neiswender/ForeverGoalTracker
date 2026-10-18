# Roadmap

What's coming to Forever Goal Tracker, from small touches to big updates. Nothing here has a fixed date, and the order can change as Warcraft Forever evolves and as players tell us what they want most.

Have an idea or found a bug? Leave a comment on [CurseForge](https://www.curseforge.com/wow/addons/forever-goal-tracker) or open an issue on [GitHub](https://github.com/karl-neiswender/ForeverGoalTracker/issues).

## Next big feature: Gear Planner

Build a named target gear set by equipment slot, see where each item comes from and add the set to My Goals. The intended experience includes slot-specific item search, a rotatable character preview and dressing-room artwork. Start by verifying item and source coverage, then build the core planner and expand the preview and search.

The fixes and refinements below will ship in small patches as they are ready. They do not all need to be finished before Gear Planner.

## Implemented, awaiting in-game review and release

- Buff Other Players follows the supported classes in character-filtered views.
- Arcanite Reaper’s Blacksmithing step uses its step number.
- Hyjal Summit and the Barrow Deeps no longer repeat their binary objective as a small progress bar.
- War mount guides name each faction’s vendor and link the city to its PvP hall approach. Forever positions remain unconfirmed.

- My Goals can hide completed goals and remember that choice.
- Item set pages show their pieces directly under Items to collect, including Tier 3 and Tier 2.5; each item’s requirements remain expandable.
- Completed Library cards use a quieter completion treatment.
- New & Updated lists matching individual sets and mounts directly.

## Patch improvements: fixes and clearer guides

- **Goals that fit your character:** continue reviewing class, race, faction and profession filtering.

## Patch improvements: finding goals and understanding progress

- **More My Goals filters:** filter by category and remember your chosen character view.
- **Clear tracking scope:** show whether progress comes from your current character or your recorded characters, and which character contributes. Filtering a list should stay separate from changing how progress counts.
- **Fewer accidental completions:** strengthen verified prerequisite locks and explore a deliberate manual override for steps the addon cannot reliably verify.
- **Reputation progress:** show progress toward Friendly, Honored, Revered and Exalted, with the contributing character clearly identified.

## Patch improvements: guides and progress feedback

- **Dungeon level ranges:** add recommended levels to dungeon location tooltips, distinguishing recommendations from entry requirements.
- **Boss links:** give dungeon and raid bosses their own links with useful source and location information. Explore loot and model previews later.
- **Material loot messages:** optional chat updates when you collect a needed material, showing how many remain.
- **Progress bar design:** explore a stronger overall progress display and a goal bar above the title and icon, including the pop-out step tracker.
- **Toasts:** optional step-complete notices while the window is closed and milestone celebrations.

## Larger tools and ideas to explore

- **Custom goals:** create your own goals or copy a Library goal and edit it. Steps the game can track complete automatically; other steps can be checked manually.
- **Character overview:** compare reputation, leveling and profession progress across your recorded characters.
- **Usage dashboard research:** investigate whether voluntary, opt-in sharing could help us understand popular goals and progress. Data collection is an exploration, with no collection planned until feasibility, consent and privacy choices are settled.

## Other planned improvements

- **Feedback from inside the game:** write a suggestion or report a wrong step and get a link to send it.
- **Welcome after an update:** a skippable introduction with feature snapshots, short explanations and pages for larger updates.
- **More prerequisite checks:** verify dependent steps on Warcraft Forever before enabling locks; extend Classic Era coverage as guides are verified.
- **More Warcraft Forever content:** new raid bosses, loot sources, items, mounts and verified changes to existing guides.
- **More statistics goals:** expand goals based on the game’s tracked statistics.
- **More goals:** Darkmoon Faire decks, Steamwheedle Cartel, Ravenholdt and Shen’dralar reputations, Bloodsail Admiral and more class sets.
- **Guild announcements:** optional completion sharing with guildmates who use the addon, with guild chat off by default.
- **Share your wins:** copy a completion message for Discord.

## Maybe someday

- **Pop-out map:** a small, draggable map window for the next step.
- **Map entrances for more raids:** add entrances as locations are verified.
- **Reveal steps as you progress:** optionally hide locked step details. The full guide stays visible by default.
- **Discord companion app:** explore posting completed goals to a Discord channel.

The [release planning notes](reports/Release-plan-2026-10-17.md) describe the proposed order, design decisions and review checks. Version numbers are tentative; dates and publication are not committed.

## Recently shipped

- **2.15.1:** Clickable dungeon entrance links, map links for Light's Hope Chapel, City of Dalaran and Ahn'Qiraj, Darkspear reputation goals, Teebu's Blazing Longsword, artwork updates and bug fixes.

- **2.15.0:** A map view for goal pages with Show on map links and zoom, the Zin'rokh and Arcanite Reaper goals, more banners with blooms and effects, a stricter faction filter, UI improvements and bug fixes.
- **2.14.0:** A pop-out window for a goal's steps, a goals list that folds to an icon rail, Partners in Crime and Summon Players goals, blown sand, star glints and more light on goal images, UI improvements and bug fixes.
- **2.13.0:** Light on goal images with an Image effects setting, Ambassador banners for each race's capital, a try-on for whole armor sets, social goals for guildmates, trades, buffs, campfires and emotes, profession-aware suggestions, UI improvements and bug fixes.
- **2.12.0:** New Goal Library filters with a Progression sort, a Materials panel on each goal, My Goals search, What's new, UI improvements and bug fixes.
- **2.11.1:** Profession scanning fixes, mount previews, Wolfsbane, clearer guides, artwork credits and refreshed banners.
- **2.11.0:** Needed for item tooltips, Ctrl-click gear previews, completed-step filtering, new armor and mount goals, more artwork, UI improvements and bug fixes.
- **2.10.1:** UI improvements, more banner images, Violet Sorcerer's Vestments and bug fixes.

- **2.10.0:** personal notes, individual armor set goals, prerequisite locks on Classic Era, goal banner artwork, visual improvements and bug fixes.

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
