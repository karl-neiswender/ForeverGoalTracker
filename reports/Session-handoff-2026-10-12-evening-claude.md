# Session handoff, evening of 2026-10-12 (Claude, PC)

Written for Karl, Codex or a later Claude session. Read AGENTS.md and CLAUDE.md first; this adds what happened after 2.12.0 shipped. CLAUDE.md has the per-banner settings as short dated bullets; this file is the map.

## State

- **Released:** 2.12.0 (tag `v2.12.0`, CurseForge upload succeeded, store description and gallery updated by Karl). Zip checked: 216 files, no tools, reports, screenshots or source art inside.
- **Unreleased on `main`** (75 commits since the tag, all pushed): banner effects, the Images settings group, Tips motion, a few small fixes. CHANGELOG.md has an `## Unreleased` section with two lines; widen it at release time.
- **Checks at the end of the session:** `python tools/check.py` exit 0 (Classic Era and Forever sessions), Ketho/LuaLS `Diagnosis completed, no problems found` with 14,028 annotation load events. No release or tag is authorized.
- **Known stale:** gallery screenshot 08 (Settings) predates the new Images group; retake with `/goals shots` before the next release. A few effects have not been reviewed by Karl in game (see "Not yet reviewed").

## What was built

### Settings
- New **Images** group: "Large goal photos" (`tallGoalArt`, moved here) and **"Image effects"** (`imageEffects`, default on). It turns off every banner light, ray, ember, snow, shaft and the page's drifting dust and clouds, and applies at once. These no longer follow Celebrations.
- The old **Effects** group is now **Celebrations and sound** (Karl did not name it; change if wanted).

### Banner effect system (Core.lua, the goal banner block `B.glows`)
Everything is table-driven: `B.glows[key] = spec`, where the key is a goal id or an image path (so shared images like `set_forever_raid-banner.blp` and `pvp_drums_of_war-banner.blp` light every goal using them). `B:GlowSpec()` checks the image first, then the goal.

Effect kinds, all slow and faint, **never flashing** (Karl rejected an erratic lightning version as a seizure risk; keep it that way):
- **glow** (`Media/glow`) and **rays** (`Media/rays`, turning once per `turn` seconds, `rays` = size in glow widths), with `strength` and `raysStrength`.
- **Embers** (`embers = { box, field, count, blurShare, rise }`): sharp sparks plus soft blurred ones for depth.
- **Snow** (`embers.fall = true`; helpers `Snow(count)`, `SnowOnly(count)`): flakes fall 10 to 18 s, melt over the bottom 40%. `embers` may be a list (`B.ParticleSets`).
- **Floating motes** (`embers.float = true`).
- **Beam** (`beam = { u, top, bottom, width, strength }`, `Media/beam.tga`, wide top).
- **Sunrays** (`sunrays = { u, v, angle, spread, count, length, ... }`): `streaks` (visible, fade fully in and out, 16 to 30 s), `broad`, `parallel` (natural sunlight; a fan from one point reads as a spotlight, Karl), `wide` layer (very faint), `wideCount`, `thin`.
- **Blooms** (`blooms = { { u, v, size, strength } }`) and **gleams** (`Media/gleam.tga`, coin glints).
- Helpers `Motes`, `Sunlight(sunrays, box, motes, extra)`, `Snow`, `SnowOnly`.

Shared plumbing: a **light mask** (`Media/light-mask.tga`) gives every light the art's own fades (left, top, bottom), so lights sit under the darkening; `B:ClipLight` trims lights to the artwork; the page's drifting dust steps aside on any banner with particles (`FGT.ambience.SetDust`, `dust = true` on a spec keeps both).

Textures drawn by scripts: `tools/rays.py` (rays), `tools/beams.py` (beam, shaft, shaft-wide, streak, gleam, light-mask). New textures need a **full game restart**; Lua-only edits need `/reload`.

Banners with effects (Karl's lists): see CLAUDE.md. In short: glows/rays on Thunderfury, Ashbringer, Argent Dawn, Benediction (Alliance art), Judgement Armor, Lightforge, Fishing (rays), Cooking (flame glow + snow); embers on Sulfuras, BWL, MC, Naxx attunement, Onyxia (and both attunements), Dreadsteed, Stratholme key, UBRS key, Wolfsbane, Earthfury, Earthshatter; snow on Frostsaber, Timbermaw, Frostwolf, Frostfire, the war mounts, Dwarf ram, Howler, Giantstalker, Dwarf Hunter leveling, Nightslayer (Alliance image), Stormpike, Warlord's Earthshaker, Cooking; sunlight/beams on the Ambassadors, Charger, Forever raid sets, Fishing, Lawbringer, Lok'delar, Rhok'delar (with blooms), Save Gold (with glints), Skeleton Key, Valor, Violet Sorcerer, Faith, Duelist and Honorable Kills (with embers).

Karl said no snow on Druid banners.

### Other changes
- **My Goals search box** and **Library Progression sort** (Dungeon 1, Dungeon 2, Forever Raid, Tier 1, 2, 2.5, 3, PvP; `FGT.SetOrder`).
- **Goal page chips** quieter (plain case, grey), tighter spacing.
- **Epic Racial Mounts thumbnail** follows the logged-in character's race (`FGT.GoalIcon`).
- **Bottom shade** (`FadeEdge`, `holdShade`, `easeShade`) eases out at the end of a list only when scrolling, never on page open.
- **Tips** glide: opening glides the guide down while the tips fade in; closing glides back up (to where you were, else by the tips' height) while they fade out, then folds. Toggling redraws only the tips (`FGT.RedrawTips`), not the page. The "(n)" count does not change.
- **Step edge-fade** (`FGT.StepsEdgeFade`) now follows the shade's alpha (`FGT.edgeListeners`).
- Demo scenes 9 (Materials) and 10 (Library filters) join `/goals shots` (10 shots now; `tools/shots.py` names them).

## The Tips flash: what happened and the lesson

Karl hit a flash when opening and closing Tips. I made several guesses (whole-page redraw, step edge-fade, stale scroll range) and fixed them one at a time; two were real but none was the cause. I then built `/goals tipsdebug` (arm it, click Tips, `/reload`, read `ForeverGoalTrackerDB.tipsDebug` from `WTF/Account/52647669#1/SavedVariables/ForeverGoalTracker.lua`). The first recording showed the real bug: starting a glide ended the previous glide through `Finish()`, which also released the shade hold the caller had just set, so the shade eased in over the Tips row. Fixed with `Finish(keepHold)`. Karl confirmed smooth.

**Lesson (Karl, a lot of his tokens were spent):** for motion or visual glitches you cannot see, **add a way to measure before changing anything** and say plainly when guessing. Use `/goals tipsdebug` as the template.

## Practical notes

- **Backslashes:** inline Python and shell commands lose single backslashes in texture paths. Write Lua paths with `chr(92)`, a `@@` placeholder, or put the patch in a script file. `tools/check.py` rejects control bytes, and a quick `od -c` on the written line is a cheap check.
- **Line endings:** Core.lua is currently LF; some other files are CRLF. Match each file.
- **Placement method:** a zoomed 0.02 grid over the master image (crop, then grid) finds exact points far better than 0.1 contact sheets. Masters live under `Media/final-images/` (not shipped).
- **Particle settings read from the wrong place** once (UBRS: embers-only banners were skipped by the glow's top-80% check). Tests now check every ember banner actually starts, not just that it has settings.
- **Pre-existing edits to Core.lua's local count:** keep new state on `FGT` or inside `do` blocks (200-local limit).
- **Codex** still owns asset generation and artwork loading and linking. Four new source images were untracked at the end of the session (`Media/artwork/Eastern_Plaguelands_full.jpg`, `Ironforge_full.jpg`, `Sword_of_a_Thousand_Truths_full.jpg`, `Westfall_full.jpg`) and were committed as sources only; none is mapped to a goal.

## Not yet reviewed by Karl in game

The 14 first-round ember banners after the final retune (BWL, MC, Naxx attunement, Onyxia, Dreadsteed, Stratholme key, Wolfsbane, Earthfury, Earthshatter, Honorable Kills/Duelist embers), UBRS key embers, the two Onyxia attunements, Cooking's flame glow, the snow banners after the last retune, and Thunderfury (approved "for now").

## Parked

Tips in the Materials drawer; a "Set tier" sort for individual armor sets; moving the changelog and store-page refresh to release time; native review of the Materials drawer under heavy use; Forever step locks (still disabled by design); in-game feedback, custom goals, pop-out tracker (ROADMAP.md).
