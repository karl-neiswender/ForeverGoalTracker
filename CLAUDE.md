# Forever Goal Tracker

A World of Warcraft addon for **Warcraft Forever** (beta now, live launch November 2026). Players pick long-term goals from a built-in library (legendaries, mounts, reputations, raids, item sets, professions, PvP) and follow step-by-step guides, and steps tick automatically from game state across all of the player's characters.

- Author: Karl (GitHub `karl-neiswender`). Repo: https://github.com/karl-neiswender/ForeverGoalTracker
- Published on CurseForge as "Forever Goal Tracker", project ID 1728528 (approved 2026-10-05). Public page: https://www.curseforge.com/wow/addons/forever-goal-tracker
- License: MIT. Bundled Cinzel font is SIL OFL (`Fonts/OFL.txt`).

## Where this folder lives

Karl works on the addon from two machines, a Windows PC and a MacBook. Both have the Forever beta installed, and on each one this repo is checked out **directly into the game's AddOns folder**:

| Machine | Addon folder |
|---|---|
| PC | `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\ForeverGoalTracker\` |
| Mac | `/Users/karlneiswender/Projects/ForeverGoalTracker/`, with a symlink to it at `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/ForeverGoalTracker` |

Work out which machine you're on from the working directory before running platform-specific commands.

Edits are live on the machine you're running on: Karl types `/reload` in game to see Lua changes. New or replaced texture/font files (`.tga`, `.ttf`) need a full game restart, because the client caches them.

The SavedVariables file is at `_classic_beta_/WTF/Account/<account>/SavedVariables/ForeverGoalTracker.lua` (on the PC the account folder is `52647669#1`). The old `KarlClassicGoals.lua` save next to it on the PC is a backup from before the rename. Leave it alone.

An older, separate copy of the addon (KarlClassicGoals v1.1.0) lives in `_classic_era_` on the PC. It is not part of this project, so don't touch it.

When Forever goes live (November), the addon and the SavedVariables need to move from `_classic_beta_` to the live client's folder on both machines.

## Working across both machines

GitHub keeps the two checkouts in sync; `main` is the shared branch.
- **Starting a session:** run `git pull` first, so you work on the latest code from the other machine. If the working tree has uncommitted changes, ask Karl before pulling.
- **Ending a session (or when Karl switches machines):** commit and push to `main`, so the other machine can pull it. Don't leave work uncommitted on one machine.
- Saved progress does not sync. SavedVariables (ticked steps, scanned characters) are local to each machine, so the tracker can look different on the PC and the Mac. That's expected, not a bug.
- Remember that `git pull` changes the files the game loads, so Karl should `/reload` afterwards.

## Files

| File | Purpose |
|---|---|
| `ForeverGoalTracker.toc` | `## Interface: 11509, 16001` (Classic Era + Forever). Load order: Data.lua, Library.lua, Core.lua. SavedVariables `ForeverGoalTrackerDB`. |
| `Data.lua` | The original 11 goals (Atiesh, Thunderfury, Sulfuras, Ashbringer, Rhok'delar, Lok'delar, Benediction, Frostsaber, level all classes, Tier 3, epic racial mounts). Builders for group goals (`autoLevels`, `BuildMountTasks` with `forRace`). |
| `Library.lua` | 54 more goals: reputations (incl. Ambassador per faction), mounts (incl. Dreadsteed, Charger), Quel'Serrar, raids (`BossSteps`, AQ20), attunements and dungeon keys (category `Attunement`, one goal each; Onyxia has one per faction), professions (`SKILL_ICONS`), gold, item sets (`TIER1`, `TIER2`, `DUNGEON1`, `DUNGEON2`, Embrace of the Viper), per-faction PvP. 65 goals in total. Set piece tuples are `{ name, itemId, source, icon }`; sources come from Wowhead "Dropped by" / "Reward from". |
| `Core.lua` | Everything else (~3,000 lines): DB, roster scanning, rules engine, UI, minimap button, slash commands. Namespace table `FGT`, addon folder name `ADDON`. |
| `Media/icon.tga` | 64px addon list icon (book logo). |
| `Media/minimap.tga` | 64px minimap button icon (green checkmark, circular alpha). Source: `Media/minimap-source.png`. |
| `Media/star.tga` | 64px five-point star for favorites (white with a soft dark edge, tinted gold in code). Drawn by a Python script, no source file. |
| `Media/web.tga` | 256px corner cobweb for the empty state (white on transparent, tinted in code). |
| `Media/logo.png` | 1024px logo for GitHub/CurseForge. |
| `README.txt` | Player-facing readme that ships in the zip. `README.md` is the GitHub page. |
| `CHANGELOG.md` | Update for every version. |
| `.pkgmeta`, `.github/workflows/release.yml` | Release packaging (see below). |
| `tools/check.py`, `tools/wowstub.lua` | Local Lua check (compile + load test). Not shipped. |

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
- Slash commands: `/goals`, `/fgt`, `/forevergoals`. `/goals reset` resets the window. `/goals testbanner` plays the goal-complete chat line and banner for the open goal without changing progress.
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
13. Code in Core.lua's main chunk runs at load, before the game has loaded `ForeverGoalTrackerDB` (it arrives with ADDON_LOADED). `LayoutGoalList` runs then, so anything it or the list refresh reads from the DB needs a `ForeverGoalTrackerDB and ...` guard. `tools/check.py` catches this.
14. Gradient textures (anything colored with `ApplyHGradient`/`ApplyVGradient`) ignore `SetAlpha` in game. To fade one, redraw its gradient with scaled alphas each frame (see the celebration shine). Plain textures and frames fade with `SetAlpha` as normal.
15. Chat links use the `fgt:` link type (`|Hfgt:goal:<id>|h[Name]|h`). `SetItemRef` is wrapped to catch them and passes every other link to the game's handler.

## Testing

There's no automated test suite. Testing happens in the Forever beta: edit, `/reload`, and Karl reports back with screenshots. Before handing back a change:
- Run `python3 tools/check.py` (needs Python 3; first time on a machine: `pip3 install --target tools/.py lupa`). It compiles the three Lua files with real Lua 5.1 (syntax, missing commas, the 200-local limit), then plays three sessions against `tools/wowstub.lua`, a stand-in for the WoW API, each in a fresh Lua state with the saved variables carried over: a fresh install, a login with goals, and a goal finishing while the window is closed. It prints what each session said in chat. It catches load-time Lua errors, not visual problems. When the stand-in trips on something the real game handles (it answers unknown API calls with nil), improve the stand-in rather than the addon.
- Watch the local count in Core.lua's main chunk (lesson 1).
- Ask Karl to `/reload` and check the change. If something misbehaves, `/console scriptErrors 1` shows Lua errors.

## Releasing

1. Bump `## Version:` in the `.toc` and add a `CHANGELOG.md` entry.
2. Commit and push to `main`.
3. Until automation is set up: build `ForeverGoalTracker-<version>.zip` containing a single `ForeverGoalTracker/` folder. Leave out README.md, .github, .gitignore, .pkgmeta, CLAUDE.md, tools, Media/logo.png and Media/minimap-source.png. Karl uploads it on CurseForge as a **Release** file for game version **1.60.1** (Forever).
4. Automated releases (pending): once CurseForge approves the project,
   - add `## X-Curse-Project-ID: <id>` to the `.toc`
   - Karl adds a `CF_API_KEY` secret on the GitHub repo
   - pushing a tag like `v2.1.2` then runs `.github/workflows/release.yml` (BigWigsMods/packager), which builds the zip and uploads it
   - on the first run, check that CurseForge filed it under the Forever game version. If not, set the version in `.pkgmeta`/the workflow.
   - Don't push version tags until all of this is in place.

Commits are made as `karl-neiswender <97697208+karl-neiswender@users.noreply.github.com>`.

Git setup per machine:
- **PC:** Git for Windows is installed at `C:\Program Files\Git\cmd\git.exe` but may not be on PATH in Claude's shell; call it by full path with `-c safe.directory=*` (the repo is under Program Files). The GitHub sign-in is stored, so pushes work from Claude's shell. Release zips go in `C:\Users\kneis\Downloads`.
- **Mac:** plain `git` (Xcode command line tools). If a push asks for a GitHub sign-in, have Karl sign in once (for example with GitHub Desktop or `gh auth login`). Release zips go in `~/Downloads`.

## Looking things up on Wowhead

Goal data (quest IDs, item IDs, drop sources, icons, chain starts) is verified on Wowhead Classic through the built-in browser, never written from memory.
- Item pages carry `WH.Gatherer.addData(...)` (name, icon, slot, item set) and a `dropped-by` Listview (NPC, drop count). Dungeon bosses are not flagged `boss` there, so read NPC names, not the flag.
- Quest start NPCs are filled in by script: open the page and read the rendered text ("Start: ...").
- Wowhead rate-limits hard (403 for several minutes). Fetch one page about every 1.2 s, run long batches in the background (the JS tool times out at 45 s), and stop on the first 403.

## Current state (2026-10-05)

- CurseForge approved the project (ID 1728528, now in the `.toc`); the public page may take a while to appear in search. v2.1.2 (big update, includes 2.1.1) is the current file on CurseForge.
- Release automation works: tag `v2.1.2` (2026-10-05) was the first automatic release. The packager mapped the `.toc` interfaces to game versions 1.60.1 (Forever) and 1.15.9 (Classic Era) and uploaded to CurseForge. Releasing is now: bump the `.toc` version, add a CHANGELOG entry, commit, push, then `git tag -a vX.Y.Z` and push the tag. The full Action log needs a GitHub sign-in (Karl can read it); public API gives run status, annotations and the GitHub release.
- `.pkgmeta` now has `manual-changelog` (after 2.1.2, whose CurseForge changelog was generated from commit messages; Karl has fixed that one by hand).
- v2.2.0 released 2026-10-05 (tag `v2.2.0`): favorites and the right-click menu, login greeting, goal-complete chat link and banner, completion celebrations, real Tier 3 recipes and token sources, item icons for Tier 1 to 3.
- Pending: CurseForge screenshots; move to the live client in November.
- Open questions: where Horde warlocks start the Dreadsteed chain (Wowhead only lists Spackle Thornberry in Stormwind); the memory check (Karl hasn't run the before/after `GetAddOnMemoryUsage` commands yet).
- Next session idea (Karl, 2026-10-05): guild announcements when a guild member completes a goal. Likely approach: send a hidden addon message on the GUILD channel (`C_ChatInfo.SendAddonMessage`, or `SendAddonMessage` on older clients) when a goal finishes, so guildmates who also run the addon see a chat line or banner. An optional, off-by-default setting could also post a plain line in guild chat for members without the addon (that's public, so it must be the player's choice). Reference: the Attune addon posts a plain guild chat line like "[Attune] The Hall of Thanes attunement complete!" (seen 2026-10-05), only for whole attunements. Lean: whole goals only (maybe skip small milestones), a short tag like "[Forever Goals]", and ask the player once before posting in guild chat.
- Ideas not done yet: second goal batch (Qiraji battle tanks, Darkmoon Faire decks, Steamwheedle/Ravenholdt/Shen'dralar reputation, Bloodsail Admiral, fishing tournament, more class sets).

## Working with Karl

- Karl is a designer (web and digital design director). Give clear, brief explanations and skip coding jargon where possible.
- Never use em dashes in responses or in written copy.
- He tests in game and sends screenshots. Fix exactly what the screenshot shows, then say what to check.
