# Warcraft Forever launch checklist (November 4, 2026)

Everything that could not be done while the Forever beta was closed (it ended October 23). 2.16.0 shipped on October 24 tested on Classic Era only, and says so in its changelog. Do these in order on the live Forever client; fixes ship as 2.16.1. Nothing here is done yet.

## 1. Open the addon on live Forever and look for errors

- Load the game with the addon on and check for Lua errors (a popup, or BugSack/`/console scriptErrors 1`). The newest code that has never run on Forever: `PlannerEffects.lua`, the sheathe key, the backdrop placement and shadow, and the step locks.
- Copy the addon in by hand (`sh tools/sync-era.sh` shows the pattern for Era). Never install it through the CurseForge app and never link the folder (see the notes on the October 23 junction).

## 2. Gear Planner on Forever

- Backdrops: all eight, with the grounding, drop shadow (default, zoomed out, narrow window) and weather (snow, motes, embers, clouds, leaves). Check `/goals plannerlight` and Settings > Images (Full, Subtle, Off).
- Z sheathes and draws the weapons; typing a Z in the set name box still types a Z; Z returns to the game's own sheathe when the planner closes.
- The character picker menu stays inside the sets drawer; Set totals shows the average item level on its own line.
- Plan for another character: the preview shows their race (known issue in 2.16.0: it may show yours).
- Forever items: the "Updated in Forever" and "Not revealed yet" marks, sources, and a set with Forever-only pieces.

## 3. Step locks on Forever

Requirement locks are off on Forever by design (`Dependencies.lua`, `FGT.StepRequirement`). After launch, check that the level, reputation, skill and quest rules answer correctly on Forever (changed quest rules are the risk), then decide whether to switch them on. The order locks still use `FGT.testDependencies` / `/goals testlocks`.

## 4. Skyborne backdrop (artwork ready, not installed)

Codex made it on October 24: `Media/artwork/dressing-room/skyborne-bw.png` (1143 x 1376, a mossy stone terrace, a hanging banner, distant spires), with the untouched generation and the Blizzard reference beside it, and the report `reports/skyborne-backdrop-2026-10-24.md`. Hook it up once the Skyborne race is playable, in this order:

1. Make the runtime texture: `python tools/backdrop_tga.py Media/artwork/dressing-room/skyborne-bw.png Media/dressing-room/Skyborne.tga`. The tool was checked against the shipped Orc texture and reproduces it exactly (opaque 1024 x 1024 RGB TGA, 24-bit).
2. On live Forever, learn the race key the game gives a Skyborne: `/run print(select(2, UnitRace("player")))`. `RACE_IDS` in `GearPlanner.lua` already maps Skyborne to 95; the key must match.
3. In `GearPlanner.lua`: add `Skyborne = true` to `background.races`.
4. Check the preview shows a Skyborne with `SetCustomRace(95, sex)` for another character, and with `SetUnit("player")` for a Skyborne player.
5. Tune the placement as for the other races: take a default and a zoomed-out and narrow-window screenshot and set the ground line (`background.ground`, where the stone terrace under the feet sits, around 0.78 of the image height to start) and the shadow line (`background.shadowFeet`) so the feet land on the stone.
6. Choose its weather in `PlannerEffects.lua` (`SPECS`): the scene has clouds and a canopy, so the ambience layers already suit it; add particles only if it needs them.
7. Add `Skyborne` to the eight-race tests in `tools/gear-planner-tests.lua` (race selection and ground), run `python tools/check.py`, then sync and `/reload`.
8. Commit the artwork originals and the report with the install, and record the install in a short report like `racial-backdrops-2026-10-24.md`.

Without this step a Skyborne player gets the Orc backdrop (unknown race keys fall back to Orc).

## 5. Gallery and store page

- The three Forever-only shots (`02-wolfsbane`, `07-new-and-updated`, `09-find-your-next-goal`) were taken on the 2.15.0 window and lack the Gear Planner tab. Retake them on Forever with `/goals shots` (all 13) or one at a time with `/goals shots 02`, then `python tools/shots.py --only 02`.
- `08-epic-mounts` on Era shows the Skyborne row with a blue NEW label; on Forever that is now correct.
- Update the CurseForge description if Forever behavior changed what it should say about Forever support (the 2.16.0 text says Forever is unconfirmed).

## 6. Data checks that were waiting for launch

- `/goals ejprobe` once on live Forever: its Encounter Journal was empty in the beta, so boss drop sources could not come from the game (see `reports/CURRENT.md`).
- Verify the Forever dependency edges one at a time before enabling any (see `Dependencies.lua`).
- Check the Forever vendor and NPC positions that were marked Unconfirmed.

## 7. Then release 2.16.1

Fix what the checks above find, update the CHANGELOG and What's new, run the full gate (`tools/check.py`, `sh tools/run-luals.sh`, performance read), and publish only with Karl's authorization. The unreleased step locks are already in the CHANGELOG's Unreleased section.
