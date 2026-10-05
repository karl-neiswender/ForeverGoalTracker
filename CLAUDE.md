# Forever Goal Tracker

A World of Warcraft addon for **Warcraft Forever** (beta now, live launch November 2026). Players pick long-term goals from a built-in library (legendaries, mounts, reputations, raids, item sets, professions, PvP) and follow step-by-step guides, and steps tick automatically from game state across all of the player's characters.

- Author: Karl (GitHub `karl-neiswender`). Repo: https://github.com/karl-neiswender/ForeverGoalTracker
- Published on CurseForge as "Forever Goal Tracker", project ID 1728528 (approved 2026-10-05). Public page: https://www.curseforge.com/wow/addons/forever-goal-tracker
- License: MIT. Bundled Cinzel font is SIL OFL (`Fonts/OFL.txt`).

## Where this folder lives

This repo is checked out **directly into the game's AddOns folder**:

```
C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\ForeverGoalTracker\
```

Edits here are live: Karl types `/reload` in game to see Lua changes. New or replaced texture/font files (`.tga`, `.ttf`) need a full game restart, because the client caches them.

The SavedVariables file is at `_classic_beta_\WTF\Account\52647669#1\SavedVariables\ForeverGoalTracker.lua`. The old `KarlClassicGoals.lua` save next to it is a backup from before the rename. Leave it alone.

An older, separate copy of the addon (KarlClassicGoals v1.1.0) lives in `_classic_era_`. It is not part of this project, so don't touch it.

When Forever goes live (November), the addon and the SavedVariables need to move from `_classic_beta_` to the live client's folder.

## Files

| File | Purpose |
|---|---|
| `ForeverGoalTracker.toc` | `## Interface: 11509, 16001` (Classic Era + Forever). Load order: Data.lua, Library.lua, Core.lua. SavedVariables `ForeverGoalTrackerDB`. |
| `Data.lua` | The original 11 goals (Atiesh, Thunderfury, Sulfuras, Ashbringer, Rhok'delar, Lok'delar, Benediction, Frostsaber, level all classes, Tier 3, epic racial mounts). Builders for group goals (`autoLevels`, `BuildMountTasks` with `forRace`). |
| `Library.lua` | 54 more goals: reputations (incl. Ambassador per faction), mounts (incl. Dreadsteed, Charger), Quel'Serrar, raids (`BossSteps`, AQ20), attunements and dungeon keys (category `Attunement`, one goal each; Onyxia has one per faction), professions (`SKILL_ICONS`), gold, item sets (`TIER1`, `TIER2`, `DUNGEON1`, `DUNGEON2`, Embrace of the Viper), per-faction PvP. 65 goals in total. Set piece tuples are `{ name, itemId, source, icon }`; sources come from Wowhead "Dropped by" / "Reward from". |
| `Core.lua` | Everything else (~3,000 lines): DB, roster scanning, rules engine, UI, minimap button, slash commands. Namespace table `FGT`, addon folder name `ADDON`. |
| `Media/icon.tga` | 64px addon list icon (book logo). |
| `Media/minimap.tga` | 64px minimap button icon (green checkmark, circular alpha). Source: `Media/minimap-source.png`. |
| `Media/web.tga` | 256px corner cobweb for the empty state (white on transparent, tinted in code). |
| `Media/logo.png` | 1024px logo for GitHub/CurseForge. |
| `README.txt` | Player-facing readme that ships in the zip. `README.md` is the GitHub page. |
| `CHANGELOG.md` | Update for every version. |
| `.pkgmeta`, `.github/workflows/release.yml` | Release packaging (see below). |

## How it works

### Goal data
Each goal has an `id`, a `name`, `category`, `icon` and `faction`, plus `sections` of steps. A step can carry an `auto` rule. Group goals (classes, professions, mount races, set classes) have parts the player can select individually (`FGT.GroupParts`, `PartSelected`, `FGT.SelectedPartCount`). Active goals live in `DB.active`.

### Roster and rules
- `RecordCharacter()` snapshots the logged-in character into `DB.characters["Name-Realm"]`: level, XP, race, class, faction, items (bags, equipped, bank when it's open), quests, reputations, skills, money, owned mounts, PvP rank and honorable kills, plus boss kills from `ENCOUNTER_END`/`BOSS_KILL`.
- `RuleMet(rule)` checks a step's `auto` rule against the whole roster. A rule is met if **any** of its conditions holds. Conditions: `level`, `raceLevel`, `race`, `item`+`count` (summed across the roster), `quest` (turned in), `questTaken` (picked up or turned in; read from the quest log and remembered on the character), `rep` (faction id or list, `standing`, `value`), `skill`, `money`, `pvpRank`, `hk`, `owned`, `ownedPattern`, `boss`. Scope keys `forRace` and `forFaction` limit which characters count.
- `completeWith` on a goal completes the entire goal when the final reward is owned.
- `ApplyAutoRules()` ticks steps and **never unticks** them, because items get consumed along the way. Ticks are written to `autoLog` for debugging.
- Bag and money events are debounced with `C_Timer`.

### UI
- Palette in table `C`. Helpers: `Etch` (tooltip-border etched edge), `ApplyVGradient`/`ApplyHGradient` (`SetGradient` + `CreateColor` with a pcall fallback), `NewIcon`/`ResolveIcon` (falls back via `GetFileIDFromPath`), `NewBar` (amber-to-gold fill with an additive bright tip at the right end), `CreateScrollArea` (draggable thumb with a 12px hit area that doesn't move the window).
- Two tabs: **My Goals** (goal list on the left with a sort dropdown, step guide on the right) and **Goal Library** (cards with filter chips, `+ Add` / `Choose` / `Remove`).
- The window anchor is normalized to TOPLEFT before dragging. The frame uses `SetDontSavePosition`, saves its position in the DB, and re-measures resize bounds each time.
- The minimap button radius is `Minimap:GetWidth()/2 + 5`. Don't use a fixed 80, which sits off Forever's smaller minimap.
- Slash commands: `/goals`, `/fgt`, `/forevergoals`. `/goals reset` resets the window.
- First run: `DB.active` is missing, so it is set to `{}`, the window opens on My Goals, and a welcome message prints.
- Empty state (no goals on the tracker): cobwebs (`Media/web.tga`, mirrored for the right corner) in the goal list's top corners, an "Empty" label, the sort bar hidden, and a "Browse the Goal Library" button on the right. Built in `FGT.emptyUI`, toggled by `FGT.ShowEmptyTracker`/`HideEmptyTracker`.

## Hard-won lessons (don't regress these)

1. **Lua 5.1 allows at most 200 active local variables per function.** Core.lua's main chunk is near the limit. Put new state on `FGT` or inside `do ... end` blocks, and keep colors in `C`. A "too many local variables" error means the main chunk crossed the limit.
2. **Reputation for unmet factions reads as Neutral, 0.** Always check `KnownFactions()` (the reputation panel) before trusting `GetFactionInfoByID`. The first Wintersaber step uses `value >= 1` for the same reason.
3. **`local _, raceFile = UnitRace and UnitRace()` only captures one value.** Use `select(2, UnitRace("player"))`.
4. Define a local helper *above* its first use. Lua locals aren't hoisted.
5. Item quality labels: Atiesh, Thunderfury and Sulfuras are Legendary. Benediction, Corrupted Ashbringer, Rhok'delar, Lok'delar and Quel'Serrar are Epic. Lok'delar is Hunter-only.
6. Rank 11 PvP titles are Commander (Alliance) and Lieutenant General (Horde).
7. Icon names come from Wowhead (`https://www.wowhead.com/classic/item=ID&xml`). Item and quest IDs were cross-checked against QuestieDB.
8. Never untick steps automatically.
9. Don't use the game's `StartMoving`/`StartSizing` for the main window. They re-measured the window on grab and made it jump. Moving and resizing follow the cursor by hand (`FGT.mover`, the resize grip's OnUpdate), and a saved position is nudged on screen, never recentered.
10. All piece progress goes through `FGT.PieceProgress`: a piece with materials (Tier 3) counts only its materials and has no checkbox; a piece without materials is one checkbox. Counting a piece and its materials together made the bars disagree.
11. Steps are drawn without a closing period (`FGT.StepText`); write data normally and don't strip periods by hand. Steps are actions; advice goes in a goal's `tips`.
12. Steps are saved by position. If you remove or merge steps in an existing goal, add a one-time remap in the init code (see `tipsFix`) so saved ticks follow their steps.

## Testing

There's no automated test suite. Testing happens in the Forever beta: edit, `/reload`, and Karl reports back with screenshots. Before handing back a change:
- Check the Lua for syntax errors. Lua isn't installed on this PC, so the fallback is a balance check: strip strings and comments, then count `function|if|do|repeat` against `end|until`, plus `{}` and `()` pairs. It catches most slips but not a missing comma.
- Watch the local count in Core.lua's main chunk (lesson 1).
- Ask Karl to `/reload` and check the change. If something misbehaves, `/console scriptErrors 1` shows Lua errors.

## Releasing

1. Bump `## Version:` in the `.toc` and add a `CHANGELOG.md` entry.
2. Commit and push to `main`.
3. Until automation is set up: build `ForeverGoalTracker-<version>.zip` containing a single `ForeverGoalTracker/` folder. Leave out README.md, .github, .gitignore, .pkgmeta, CLAUDE.md, Media/logo.png and Media/minimap-source.png. Karl uploads it on CurseForge as a **Release** file for game version **1.60.1** (Forever).
4. Automated releases (pending): once CurseForge approves the project,
   - add `## X-Curse-Project-ID: <id>` to the `.toc`
   - Karl adds a `CF_API_KEY` secret on the GitHub repo
   - pushing a tag like `v2.1.2` then runs `.github/workflows/release.yml` (BigWigsMods/packager), which builds the zip and uploads it
   - on the first run, check that CurseForge filed it under the Forever game version. If not, set the version in `.pkgmeta`/the workflow.
   - Don't push version tags until all of this is in place.

Commits are made as `karl-neiswender <97697208+karl-neiswender@users.noreply.github.com>`.

Git for Windows is installed at `C:\Program Files\Git\cmd\git.exe` but may not be on PATH in Claude's shell; call it by full path with `-c safe.directory=*` (the repo is under Program Files). The GitHub sign-in is stored, so pushes work from Claude's shell. Release zips go in `C:\Users\kneis\Downloads`.

## Looking things up on Wowhead

Goal data (quest IDs, item IDs, drop sources, icons, chain starts) is verified on Wowhead Classic through the built-in browser, never written from memory.
- Item pages carry `WH.Gatherer.addData(...)` (name, icon, slot, item set) and a `dropped-by` Listview (NPC, drop count). Dungeon bosses are not flagged `boss` there, so read NPC names, not the flag.
- Quest start NPCs are filled in by script: open the page and read the rendered text ("Start: ...").
- Wowhead rate-limits hard (403 for several minutes). Fetch one page about every 1.2 s, run long batches in the background (the JS tool times out at 45 s), and stop on the first 403.

## Current state (2026-10-05)

- CurseForge approved the project (ID 1728528, now in the `.toc`); the public page may take a while to appear in search. v2.1.0 is the uploaded file. v2.1.2 (big update, includes 2.1.1) is committed and pushed, with its zip in Downloads for Karl to upload by hand.
- Release automation is set up (project ID in the `.toc`, `CF_API_KEY` secret on GitHub since 2026-10-05). Next version (2.1.3) is the first tag-driven release: push `v2.1.3`, watch the GitHub Action, check that CurseForge filed it under Forever 1.60.1 (if not, pass the game version to the packager in `release.yml`), and compare the uploaded zip with a hand-built one.
- Pending: CurseForge screenshots; move to the live client in November.
- Open questions: where Horde warlocks start the Dreadsteed chain (Wowhead only lists Spackle Thornberry in Stormwind); the memory check (Karl hasn't run the before/after `GetAddOnMemoryUsage` commands yet).
- Ideas not done yet: Tier 3 token drop sources, item icons for Tier 1 to 3 pieces, second goal batch (Qiraji battle tanks, Darkmoon Faire decks, Steamwheedle/Ravenholdt/Shen'dralar reputation, Bloodsail Admiral, fishing tournament, more class sets).

## Working with Karl

- Karl is a designer (web and digital design director). Give clear, brief explanations and skip coding jargon where possible.
- Never use em dashes in responses or in written copy.
- He tests in game and sends screenshots. Fix exactly what the screenshot shows, then say what to check.
