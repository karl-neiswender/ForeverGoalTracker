<p align="center"><img src="Media/logo.png" width="160" alt="Forever Goal Tracker logo"></p>

# Forever Goal Tracker

A goal tracker addon for **Warcraft Forever**. Choose long-term goals from a built-in library, follow step-by-step guides, and let the addon track your progress automatically across all of your characters. It also loads on Classic Era.

## Features

- **Goal suggestions:** a short welcome asks what interests you (Raiding, PvP, Epic Loot, Collecting, The Grind, Social) and picks starting goals for the character you're on: its class, race, faction and level. **Find your next goal**, at the end of My Goals, suggests what to chase next.
- **Goal Library with 147 goals:** legendary and epic weapons, rare and class mounts, reputations, raid clears (including Forever's new Hyjal Summit and Barrow Deeps), raid attunements and dungeon keys, item sets (Dungeon Sets 1 and 2, Tier 1, 2, 2.5 and 3, Forever's raid sets and Violet Sorcerer's Vestments), PvP ranks and sets, professions, social goals and milestones. Search by name or filter by type.
- **Step-by-step guides** for every goal.
- **Automatic tracking across your characters:** level and XP, items in bags, gear and bank, quests, reputation, professions, gold, mounts, PvP rank, honorable kills, raid boss kills, guild and friends, and WoW Forever's Statistics window (like duels won).
- **Edit goal:** change the number on goals like Save 5,000 Gold.
- **Personal notes:** click the note icon on a goal page to save a reminder above its description. Use the note icon to edit it; use Delete note to remove it, or the close X to discard unsaved edits.
- **Goal artwork:** monochrome banners with soft fades and individual class-set artwork. Leveling banners favor your logged-in character's class and faction, racial mounts favor your race, and PvP banners follow your faction. Shared artwork fills gaps where a matching image is unavailable.
- **Prerequisite locks on Classic Era:** dependent steps unlock as you finish their prerequisites.
- **Raid lockouts:** raid goals show when the character you're on is saved this week.
- **Pick the parts you want** of multi-part goals: individual classes, professions or mount races. Armor sets stay grouped in the Library, but each selected class set becomes its own goal with separate progress, notes and artwork.
- **Separate Alliance and Horde goals**, with faction filters.
- **Favorites:** right-click a goal to star it and keep it at the top of your list, or to remove it.
- **Built for Warcraft Forever:** NEW and UPDATED markers in Forever blue, a "New & Updated" filter, and a notice on guides not yet confirmed in Forever.
- **Goal links:** steps and tips link to the goals they depend on; click one to add it.
- **Item, NPC and quest links:** hover an item in a guide for its real tooltip (shift-click links it in chat). Hover an NPC to see where they stand, and shift-click to put a pin on your map or a TomTom waypoint. Hover a quest to see who starts it and where each of your characters stands on it. Right-click any of them for its Wowhead link.
- **Settings:** the gear in the title bar turns off chat lines, the banner or celebrations, adds a goal-complete sound or screenshot, hides the minimap button, and sets window scale and opacity. Everything starts on.
- **Celebrations** when you finish a step, a group or a goal, plus a chat message and an on-screen banner when a goal finishes while the window is closed. A progress check-in greets you on login.

Made with the help of AI. Every change is tested in game and approved by a human before release.

## Roadmap

See what's coming next in [ROADMAP.md](ROADMAP.md).

## Install

Download the latest release from CurseForge, or copy this repository's files into
`World of Warcraft/_classic_beta_/Interface/AddOns/ForeverGoalTracker`, then restart the game.

## Usage

| Command | What it does |
|---|---|
| `/goals` (also `/fgt`, `/forevergoals`) | Open or close the window |
| `/goals reset` | Reset the window size and position |
| `/goals settings` | Open the Settings page |
| `/goals welcome` | Get goal suggestions for your character |
| `/goals testbanner` | Preview the goal-complete banner |

A key binding is available under Options > Keybindings > AddOns.

Click **Help me get started** for suggestions, or open the **Goal Library** tab and click **+ Add** on the goals you want, then follow them on **My Goals**. Steps tick themselves as you play; you can also click any step to tick it by hand.

## Project layout

| File | Contents |
|---|---|
| `Data.lua` | The original goal definitions and shared helpers |
| `Library.lua` | The rest of the Goal Library catalog |
| `Npcs.lua` | NPCs the guides link to, with their map spots |
| `Quests.lua` | Quests the guides link to, with who starts them |
| `Core.lua` | UI, tracking engine and saved data |
| `Media/` | Addon icons |
| `Fonts/` | Cinzel font (SIL Open Font License) |

## Releasing

Pushing a tag such as `v2.1.1` runs the GitHub Actions workflow in `.github/workflows/release.yml`, which packages the addon with the [BigWigs packager](https://github.com/BigWigsMods/packager) and uploads it to CurseForge. It needs a `CF_API_KEY` repository secret and the CurseForge project ID in the `.toc`.

## License

MIT, see [LICENSE.txt](LICENSE.txt). The Cinzel font is included under the SIL Open Font License (see `Fonts/OFL.txt`).
