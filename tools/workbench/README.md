# Offline workbench

Open `start.cmd` on Windows, then visit http://127.0.0.1:8765. Close the terminal to stop it. On macOS: `python3 tools/workbench/server.py`.

The current review checkout is on `codex/offline-workbench`, inside `tools/.worktrees/offline-workbench`. Its files are separate from the approved addon files the game loads. The browser footer shows the source checkout.

## What you can test

- Browse the full goal library, add goals (all parts for grouped goals), and tick checkboxes.
- Save, edit and delete personal notes; blank Save is disabled; the counter stops at 240 Unicode characters.
- Reset a goal and undo within the actual ten-second Lua deadline.
- Load synthetic level, money, quest and loot scenarios through the addon's automatic rules.
- Reload draft Lua changes while retaining test progress. Run the existing Lua checks from the browser.

The server loads the actual Data, Library, Npcs, Quests and Core Lua files in Lua 5.1. Counts, checkbox mutations, shared steps, reset/undo, completion checks, note storage and automatic rules use the addon's functions. The private helper lookup is confined to the offline adapter, with no changes to production Lua.

## Scope of the preview

This is an interactive browser approximation, not a WoW client emulator. It uses the bundled gold icons, fonts and textures. The browser layout, note editor and CSS animations are separate from WoW's frame drawing. Editing a Lua UI layout or animation does **not** automatically change the browser renderer; update the preview alongside it. Native frame positioning, hyperlink tooltips, sound, combat restrictions, minimap behavior, real events and new beta APIs still require an in-game check. This first version covers goals, notes and progress, not every Settings or wizard page.

Test saves live in `tools/workbench/.state/session.lua`, ignored by Git. They never read or write the real WTF/SavedVariables files. Loading an empty roster does not untick past progress, matching the addon. Restart/reload clears an outstanding undo window, matching a game reload. Reset individual goals to clear their test ticks.

## Approval workflow

1. Make changes in the draft checkout. Use Reload changes to load them in the test runtime.
2. Review the preview and run Lua checks. Record decisions in CLAUDE.md / ROADMAP.md so both assistants can follow them.
3. After Karl approves, reconcile current main (including Claude's changes), commit and push the approved changes to main.
4. In game, `/reload` for Lua changes, or restart for new textures/fonts. Check the native rendering and beta-specific behavior.

The workbench has no Git push button and never merges/publishes by itself.

## Dependencies and checks

Python 3.10+ with Pillow and Lupa's Lua 5.1 module. Uses the existing `tools/.py` dependencies, including the primary checkout's copy from a Git worktree. On a new machine: `python -m pip install --target tools/.py lupa Pillow`.

Run `python tools/workbench/test_workbench.py` for adapter integration checks, and `python tools/check.py` for the addon suite. HTTP binds only to 127.0.0.1; unexpected Host/Origin requests are rejected. No remote assets or services are used.
