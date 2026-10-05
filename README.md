<p align="center"><img src="Media/logo.png" width="160" alt="Forever Goal Tracker logo"></p>

# Forever Goal Tracker

A goal tracker addon for **Warcraft Forever**. Choose long-term goals from a built-in library, follow step-by-step guides, and let the addon track your progress automatically across all of your characters. It also loads on Classic Era.

## Features

- **Goal Library with 65 goals:** legendary and epic weapons, rare and class mounts, reputations, raid clears, raid attunements and dungeon keys, item sets (Dungeon Sets 1 and 2, Tier 1 to 3), professions, PvP ranks and milestones. Search by name or filter by type.
- **Step-by-step guides** for every goal.
- **Automatic tracking across your characters:** level and XP, items in bags, gear and bank, quests, reputation, professions, gold, mounts, PvP rank, honorable kills and raid boss kills.
- **Pick the parts you want** of multi-part goals: individual classes, professions, mount races or Tier set classes.
- **Separate Alliance and Horde goals**, with faction filters.

## Install

Download the latest release from CurseForge, or copy this repository's files into
`World of Warcraft/_classic_beta_/Interface/AddOns/ForeverGoalTracker`, then restart the game.

## Usage

| Command | What it does |
|---|---|
| `/goals` (also `/fgt`, `/forevergoals`) | Open or close the window |
| `/goals reset` | Reset the window size and position |

Open the **Goal Library** tab, click **+ Add** on the goals you want, then follow them on **My Goals**. Steps tick themselves as you play; you can also click any step to tick it by hand.

## Project layout

| File | Contents |
|---|---|
| `Data.lua` | The original goal definitions and shared helpers |
| `Library.lua` | The rest of the Goal Library catalog |
| `Core.lua` | UI, tracking engine and saved data |
| `Media/` | Addon icons |
| `Fonts/` | Cinzel font (SIL Open Font License) |

## Releasing

Pushing a tag such as `v2.1.1` runs the GitHub Actions workflow in `.github/workflows/release.yml`, which packages the addon with the [BigWigs packager](https://github.com/BigWigsMods/packager) and uploads it to CurseForge. It needs a `CF_API_KEY` repository secret and the CurseForge project ID in the `.toc`.

## License

MIT, see [LICENSE.txt](LICENSE.txt). The Cinzel font is included under the SIL Open Font License (see `Fonts/OFL.txt`).
