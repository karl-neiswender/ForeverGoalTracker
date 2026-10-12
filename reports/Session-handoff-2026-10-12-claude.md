# Claude session handoff, 2026-10-12

Picks up after Codex's [October 8-11 context](Claude-context-2026-10-12.md). All work is on main and checked with `tools/check.py` and `tools/run-luals.sh`. Unreleased; no tag. Karl reviewed each item in game unless noted.

## Done
- **SetItemRef taint fixed** (Core.lua). The global is no longer replaced. Chat links are `|Haddon:ForeverGoalTracker:goal:<id>|h` via `EventRegistry` "SetItemRef" (Blizzard routes the `addon` type untainted on Era and Forever); old `fgt:` links are caught by a `hooksecurefunc` post-hook. Copy Character Name confirmed working.
- **Materials drawer**: bars glide as the panel slides (bars re-fit in OnSizeChanged); max width 280, names never wrap; Tier 3 ingredients and tokens resolve by item ID (table in Materials.lua) with instant icons, so no "?" icons; rows show `have / need` with percent in the tooltip; rows group under Crafting materials / Tokens / Turn-in items (AQ idols and scarabs) when a goal has two or more groups; options are Show completed (off by default), Show progress bars, Include other characters; finished rows dim, grey their icon and get a green check. First view of a goal with 3-8 materials (Thunderfury, Sulfuras) bounces the closed drawer (three soft rounds, gold arrow, edge shadow); 9+ rows (Tier 3, AQ sets) slide it open once (0.7 s). Once per goal in `DB.materialsSeen`; `/goals materialsreset` replays it. Scrollbar sits nearer the drawer edge.
- **Tooltips**: "Needed for" lines read `Goal · 17 more`; the last-scans note is gone; the drawer tooltip shows the collected line first; hints are `Shift-click: Link in chat` and `Right-click: Wowhead` on separate lines. Trade goods (`INVTYPE_NON_EQUIP_IGNORE`) no longer offer try-on.
- **What's new** (new file WhatsNew.lua, loaded last): button beside the gear glows gently when `DB.whatsNewSeen` is not the newest `FGT.WHATS_NEW` version, opens a dated release ledger with a gold wash, NEW label and faint breathing dot for unseen releases, drop shadow, white hover. `/goals whatsnew` and `/goals whatsnew reset`. **Release step: add the new release to the top of `FGT.WHATS_NEW`.**
- **Ketho/LuaLS gate passes on the PC.** Tools live outside the repo in `~/.cache/fgt-luals` (LuaLS 3.19.1, Ketho 0.22.3 *packaged* extension, 3,506 annotation files; the GitHub repo alone has only ~500). Run `sh tools/run-luals.sh`; it fails if annotations don't load. Evidence: reports/checks/luals-2026-10-12*.
- Test stub `SetFont` now rejects invalid flags like the game (caught a real crash).

## Lessons
- `NewFontString(parent, size, flags, r, g, b)`: the third argument is font flags, not text.
- When editing Lua through Python on Windows, `\` in string literals is easy to lose; LuaLS reports `err-esc`. Check texture paths after such edits. Files written by Python get CRLF; match each file's existing line endings (Core/Materials/etc. are CRLF in git, WhatsNew.lua and tools/wowstub.lua are LF).
- A shell `python3` call hangs on this PC (Store alias); use the bundled Python.

## Still open
- Native review of the whole Materials drawer under heavy use; Forever lock rules; description/gallery/changelog refresh before any release.
- Optional: put Tips in the drawer (discussed; only ~20 of 153 goals have 3+ materials). Not built.

## Later the same day: Goal Library filters and My Goals view (Karl reviewed in game)
- **Library filter column** in the goal list's spot (`LF` = `FGT.libState` in Core.lua's Library block): search, Show (All / Added / Not added), New & Updated only switch (Forever, `FGT.NewToggle` with a blue look), For dropdown (Anyone / My character / nine classes), Faction, Category dropdown with live counts, Reset filters at the top. All filters, faction included, are session-only. Gold dots mark changed sections.
- **Results header:** "Showing N goals for" plus removable tags per filter; Sort (A - Z / Difficulty / Duration, reuses `CompareGoals`); far-right **+ Add all / Remove all** with a confirm menu. Bulk changes run inside `LF.batch` so the window refreshes once (63 one-by-one refreshes froze the game: "script ran too long").
- **Hidden-match hint:** search matches hidden by filters get "X is hidden by your filters (For: Priest)" plus **Show it** (clears filters, keeps the search).
- **Who-can-use logic** in `Filters.lua` (`FGT.GoalFits`, `FGT.GOAL_CLASSES`, `FGT.GOAL_RACES`). Weapons follow Classic weapon skills: "can use", not "made for" (Karl agreed). My character also sets your faction (as a tag) and reverts it when you leave My character.
- **Hybrid sets:** For a class or My character, armor collections split into that class's own set cards (tier and class on the info line); Anyone keeps collections. My character also pulls your race's Epic Racial Mount out as its own card (`LF.RacePart`; card stands for the part, `LF.On` / `LF.Progress` handle both kinds).
- **My Goals "Show:" dropdown** (All goals / This character), view only; progress stays account-wide.
- `FGT.NewDropdown(parent, prefix, edge)` is the shared dropdown. `tools/check.py` now rejects stray control bytes in Lua (a lost backslash in `\194\183` drew empty squares in game).
