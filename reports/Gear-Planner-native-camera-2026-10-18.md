# Native dwarf camera review — October 18, 2026

Continues [dwarf focus and transitions](Gear-Planner-dwarf-camera-2026-10-18.md). Karl identified the running app as **World of Warcraft Beta** and authorized chat commands for testing. `cua.getApp("World of Warcraft Beta")` successfully attached; the earlier path/bundle-ID attempts were unreliable. Keyboard chat commands worked even though automated coordinate clicks only produced hover.

## Native observations and correction

Reviewed Swagrid, male dwarf, wearing the existing planned Cryptstalker set at Karl's current large window size. The first review found hands somewhat high and belt, legs and boots clearly high, matching Karl's feedback. The viewer-left hand was centered horizontally. Replace/Unequip remained visible without the item tooltip covering it.

Changed only the male-dwarf vertical offsets, keeping zoom and lateral offsets:

| Slot | Previous Z | Reviewed Z |
|---|---:|---:|
| Hands | 0.46 | 0.31 |
| Waist | 0.42 | 0.20 |
| Legs | 0.70 | 0.40 |
| Feet | 0.99 | 0.66 |

Ran `/reload`, reopened Gear Planner, and selected each of the four slots again through its actual click handler. The final native screenshots in the chat show hands, waist and leg armor around the middle of the panel; boots no longer sit at the top. The native idle pose moves the hands slightly. This confirms the observed male dwarf/window/set, not every race, animation, rotation, window aspect or item silhouette.

## Safe native test method

The addon namespace is private. Find the existing slot button by its itemName label, then call Click; do not replace or unequip planned items. Example (local execution, no outgoing chat message):

```lua
/run local f=EnumerateFrames();while f do if f.itemName and f.itemName:GetText()=="Cryptstalker Handguards" then f:Click();break end f=EnumerateFrames(f) end
```

Use the equivalent exact names for Cryptstalker Girdle, Cryptstalker Legguards and Cryptstalker Boots. The planner must be visible while its camera animation runs. `/goals` reopens it; `/reload` loads source changes. An initial exploratory `/run` temporarily repositioned only the native preview model; reload cleared that experiment before all final views were checked. No item targets, checklist credit or build names were intentionally changed. The preexisting tracked name `k` remained intact after reopening.

## Checks

The full `python3 tools/check.py` suite passed after these constant changes, including Era/Forever planner regressions. Retained output: `checks/gear-planner-native-camera-lua.txt`. The earlier zero-diagnostic LuaLS/Ketho check covers the same APIs; this follow-up changes four numeric offsets and a comment only, with no new API calls. No fresh release gate or publication is claimed.

Artwork audit found no pending added, modified, deleted or ignored files in Media/artwork. These are unreleased source changes.

## Wrist follow-up

Karl also requested wrists. Native review showed the existing general profile placed the viewer-left cuff high and slightly right of center. Added a male-dwarf override `{0.68, 0.32, 0.30}` (zoom, lateral, vertical), replacing the inherited `{0.68, 0.40, 0.65}` for this body only. Reloaded and selected Cryptstalker Wristguards through the same local command. The cuff now sits near the center; the action menu remains clear at the lower left. Left the wrist preview selected for Karl to review. No planned items were changed.

Full Lua suite retained in `checks/gear-planner-native-wrists-lua.txt`; no new API or animation changes. Artwork audit remains clean.

## Back-slot rotation

Karl requested turning the character around for Back armor. Back now eases to the rear view over 650 ms; selecting another slot returns to the front. Rotation takes the shortest arc from the current facing, including after manual spins. It has an independent driver so wheel zoom does not interrupt the turn. Dragging the model cancels the automatic turn, and hiding the planner cancels its driver. Celebrations Off turns immediately. OnModelLoaded reapplies the current facing.

Native verification after reload: selected Back through the slot's click handler and observed Swagrid facing away; then selected Head and observed him facing forward. No planned items were changed. Back has no catalogue entries yet, so its picker correctly reports no available items.

The full Lua suite passed, with added regressions for intermediate rotation, final rear/front facing, independent wheel zoom, manual takeover and hidden-driver cleanup. Retained output: `checks/gear-planner-back-view-lua.txt`. Existing SetFacing and frame APIs are unchanged; no fresh LuaLS release gate is claimed. Performance: one bounded scalar interpolation driver runs only during a turn, with no inventory or catalogue work. Artwork audit remains clean.
