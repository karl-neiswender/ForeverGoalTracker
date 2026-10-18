# Dwarf male focus and transitions — October 18, 2026

Karl requested recentering hands, waist, legs and feet on a male dwarf, changing one-sided focus to the viewer's left, and smoother transitions between gear sets and armor views. This continues the [earlier polish pass](Gear-Planner-polish-2026-10-18.md). Unreleased; no release tag or publication authorized.

## Changes

- Added male-dwarf-only profiles for hands, waist, legs and feet, with smaller vertical translations and slightly wider hand/foot views. Other bodies retain their existing vertical framing. Reversed the lateral offsets for shoulders, wrists, hands and feet to choose the opposite side.
- Changed slot transitions from 320 ms cubic easing to 550 ms quintic easing, with zero starting/ending acceleration. Retargeting starts at the currently displayed position. Wheel moves take 200 ms and retain the pending slot target instead of freezing midway through its pan.
- Added a separate 400 ms gear transition: ease to 30% opacity over 160 ms, dress the latest selection once, then ease back over 240 ms. Rapid selections replace the pending redraw. Camera movement no longer writes model opacity, so simultaneous camera/appearance animations do not interfere.
- Reuse the same character model when switching between builds belonging to the same character rather than calling SetUnit for every set. Initial loading and changing character still set the native unit. Motion is immediate with Celebrations Off, and both drivers stop on completion or panel hide.

## Verification

Full `python3 tools/check.py` passed, including simulated Era and Forever planner tests. New cases cover male-dwarf profile isolation, opposite-side offsets, intermediate camera positions, interruption without positional jumps, coalesced dressing, opacity ownership and animation cleanup. Output: `checks/gear-planner-dwarf-camera-lua.txt`.

LuaLS/Ketho results and verified annotation-loading evidence are retained in the matching `gear-planner-dwarf-camera-*` check reports. This shared annotation check is not native validation of either client or a completed release gate.

Performance review: the model is redressed once at the transition midpoint, not on every frame; camera and opacity updates use simple scalar math and stop at rest. No new inventory or catalogue scans were added. Native CPU measurement remains pending.

## Native review limitation

The running process was verified as `_classic_beta_/World of Warcraft Beta.app/Contents/MacOS/World of Warcraft -launcherlogin -uid wow_classic_beta`. The computer-use app resolver selected another client initially, then attempted a duplicate beta launch instead of attaching to the existing window; the duplicate reported a locked CAS container. No native screenshots or framing verification were obtained. The original beta process remained running. Do not infer that Karl closed the game from the tool's “App quit” error.

The new dwarf values are a tuning pass for Karl to review after `/reload`, not verified anatomical centers. Review hands, belt, legs and boots, the chosen shoulder/wrist side, rapid slot changes, and switching between saved sets. No texture restart is needed.

Artwork audit found no pending changes, deletions, additions or ignored files in Media/artwork.
