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
