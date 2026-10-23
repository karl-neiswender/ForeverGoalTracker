# Compatibility and validation

Load for Lua/API, test tooling or diagnostic work. This is a task reference, not
a request to run checks on every session. Paths below are relative to the root.

## Validation triggers

| Change | Validation before handback |
|---|---|
| Documentation only | Relevant facts, relative links, diff and preservation checks |
| Artwork only | Affected source/master/runtime mappings, dimensions, format, attribution and native appearance; Lua suite only if Lua mappings changed |
| Lua, runtime goal data or TOC | `python3 tools/check.py` once after final relevant edits, plus affected regressions |
| API, hooks or compatibility | Above plus Ketho/LuaLS; native behavior on affected clients |
| Animation, layout or hot paths | Applicable suite plus targeted native review and performance measurement |
| Authorized release | Full checks on the release candidate, retained diagnostics, native review and publishing checklist |

A passing result is reusable only while its inputs and relevant environment are
unchanged. Do not add redundant tests that merely mirror trivial edits. Fix real
failures; do not broaden suppression to make a gate green. Say what was not tested.

## Runtime and API safeguards

- Lua 5.1 limits each function, including a file's main chunk, to 200 active locals.
  Put new state in `FGT` or narrow `do ... end` scopes; colors belong in `C`.
- Locals are not hoisted. Define helpers above their callers. Lua logical operators
  collapse multiple returns: use `select(2, UnitRace("player"))` when appropriate,
  not `local _, raceFile = UnitRace and UnitRace()`.
- Forever's modern engine removed some old globals. Use `FGT.ItemInfo`; inspect
  compatibility before new item/spell calls. Extend the Forever stub's removed-API
  fixtures when needed. The stub deliberately makes old `GetItemInfo` unavailable.
- Guard all early DB reads until `ADDON_LOADED`. Never read statistics/friends
  through shutting-down APIs at `PLAYER_LOGOUT`; maintain `FGT.loggingOut` guards.
  An engine assert cannot be caught with `pcall`.
- Keep `addon` chat links on EventRegistry's `SetItemRef` callback; keep old `fgt:`
  links on a `hooksecurefunc` post-hook. Never replace global `SetItemRef`.
- Extend stubs for legitimate API behavior without hiding accidental globals,
  broken hook chaining or out-of-scope locals. Keep TOC and checker's FILES aligned
  when adding/removing modules. Do not hard-code an obsolete load-order list.

## Running checks when required

`tools/check.py` uses platform-native Lupa's `lua51`, compiles TOC modules and
exercises fresh/reloaded saves, both client environments and regression cases.
One-time setup is `pip3 install --target tools/.py lupa` with the intended runtime.
Do not assume the Mac's copied native modules work on Windows. On this PC, bundled
Python was available under
`C:/Users/kneis/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
Resolve the installed runtime once if that path no longer exists. PATH's Python
may be a Windows Store alias. Legacy balance/locals PowerShell scripts are not
substitutes for the real Lua compiler and loader.

On PC, `sh tools/run-luals.sh` runs the Ketho/LuaLS gate through Git for Windows.
Setup/evidence: [October 12](../checks/luals-2026-10-12.md) and
[October 15](../checks/luals-2026-10-15.md). Load these only when diagnostics/setup
requires them. Verify actual annotation loading and retain diagnostic output.
Installing extensions alone is insufficient. Review Era/Forever branches and
client-specific exceptions: the annotation library is a union, not proof of all
Forever behavior. Inspect output and diagnostic results, not just shell exit status.

Never run a live release if Ketho (`ketho.wow-api`), LuaLS (`sumneko.lua`), loaded
annotations or usable results are missing. Complete setup and report the block.
Ordinary source commits and artwork syncing need no release tag.

Native validation remains necessary for rendering, taint, interactions and CPU.
Use `/console scriptErrors 1` for Lua errors; `/goals perf` and `/goals gcprobe`
measure relevant runtime costs. `tools/perfbench.py` is offline evidence only.
Use `/goals tipsdebug` for relevant flicker investigations. After two failed visual
fixes, stop speculative editing and obtain measurements. Check demo mode and restore
it with `/goals demo off`; never reset real progress to make a test convenient.
