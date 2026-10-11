# Code quality review, 2026-10-11

## Result and limits

The local Lua 5.1 compile/load suite passed all 49 sessions on Classic Era and Forever configurations after the changes below. This is a targeted review, not a certification of performance or a complete API audit. The permissive WoW stub cannot prove every API signature or measure actual frame time in the game.

Ketho's WoW API extension provides LuaLS annotations and API IntelliSense. Neither it nor Lua Language Server is installed in this environment, so this review does not claim a clean Ketho/LuaLS diagnostic run. Source: https://github.com/Ketho/vscode-wow-api

## Reviewed

- Global exports: startup introduces binding labels, slash-command aliases, the saved-variable table and the toggle entry point. Named main/minimap frames are intentional WoW integration points. SetItemRef is intentionally wrapped for addon chat links and forwards other links to the previous handler. No unexpected startup globals appeared in the stub audit.
- API compatibility: item information uses the C_Item.GetItemInfo / GetItemInfo compatibility helper; optional event registration is guarded. Existing Forever tests remove the legacy item global. Statistics reads are throttled to ten seconds and excluded during logout.
- Scanning: frequent roster events are coalesced by ScanSoon with a half-second delay. Roster scanning is event-driven rather than a per-frame operation.
- Animation: guide and row drivers are attached to their UI parents or stop when finished. Shared link shimmer skips invisible labels; the wizard tween driver hides when idle and preserves mutation-safe iteration.
- Item tooltip hooks: installed once at login, use the modern tooltip processor where available, and limit additions to the main/item-reference tooltips. Remaining requirements are computed when a tooltip is opened, not every frame.

## Changes

- Reused the detail progress pulse's color tables rather than allocating two new tables per frame.
- Capped its gradient painting at 20 updates per second while preserving elapsed-time phase and immediate rendering when progress changes.
- Added an explicit global-export allowlist to each test session's load path, so future accidental globals fail the checks.

## Validation

- python3 tools/check.py: passed, 49 sessions, all nine addon Lua files compile under Lua 5.1.
- git diff --check: passed.

In-game CPU profiling and a Ketho/LuaLS run remain separate checks. Do not advertise those as completed. The addon remains subject to manual testing on the Forever beta as its APIs and content change.
