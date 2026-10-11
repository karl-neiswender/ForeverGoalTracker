# Session handoff: October 10, 2026

## Current state

Karl has finished adding features for today. Next action is his in-game review, followed by fixes if needed. Do not add more features or publish a release before that review. The addon still reports version **2.10.1**; today's changes are **Unreleased**. No release tag or CurseForge upload was made for this work.

All implementation commits are on shared `main`, through `11ba600` (item tooltips and previews). Pull `main` on the Mac before continuing. Check for local changes first and ask Karl before pulling over them. SavedVariables remain local to each machine.

## Implemented today

- **Completed-step filter:** subtle Show completed / Hide completed text beside Step by step, shown by default. Saved as `hideCompletedSteps`. With hiding enabled, a newly completed step gets 0.55 seconds for its check animation, fades for 0.28 seconds, then remaining rows slide for 0.26 seconds. Switching goals, resetting and turning the filter off cancel pending transitions. The tween driver snapshots work before callbacks and checks tween identity, avoiding mutation during `pairs` iteration. Karl reproduced the old `invalid key to 'next'` error and confirmed the fix in game.
- **My Goals cards:** three layers only: eyebrow, name, progress bar. Eyebrow uses the detail-page category/class/faction information, replaced by completion status and date when finished. Difficulty removed from cards. NEW / UPDATED sits at top right; favoriting replaces it with the star. Fixed card height remains 72px. Faction-only cards have large, subtle monochrome etched insignia at top right. PvP names use Marshal Plate, Marshal Cloth, Warlord Plate, etc. Full titles remain on the goal page.
- **Scrollbars and reset:** subtle bronze scrollbar colors brighten on hover without widening. Reset arrow is horizontally mirrored and spins counterclockwise.
- **Tier 2.5:** nine independent AQ40 class-set goals, IDs `set_tier25_<class>`, built in `AQArmor.lua` before `ArmorSets.lua`. Five pieces per class; automatic ownership rules, token/material/reputation tips, headpiece thumbnails. Approved shared Skeram Cultist banner maps to the collection and its children. Sources remain unchanged.
- **Fishing Extravaganza:** `fishing_extravaganza`, with 150 Fishing, 40 Speckled Tastyfish (19807), and winning Master Angler (8193) or either prize (19970 / 19979). In Profession category and collect/grind suggestions. Approved Booty Bay banner installed.
- **AQ mounts:** separate `mount_qiraji_blue`, `mount_qiraji_green`, `mount_qiraji_yellow`, `mount_qiraji_red`; item IDs 21218, 21323, 21324, 21321, with automatic item/owned tracking. They share the prior AQ mount artwork under `mount_qiraji_aq-banner.blp`. `mount_qiraji` remains the Black Qiraji goal and now uses approved Scarab Lord artwork.
- **Item tooltips:** new `ItemTooltips.lua`, loaded after `Core.lua` in both the TOC and checker. “Needed for” shows unfinished tracked goals in native bags, loot, AH and chat item tooltips, plus addon item tooltips. Enabled by default through `itemNeeds`; Settings has an Item tooltips group. Modern hook uses `TooltipDataProcessor.AddTooltipPostCall`; legacy uses `OnTooltipSetItem`. Cleared tooltips reset duplicate suppression. Comparison tooltips stay clear.
- **Remaining supplies:** item rules respect race/faction scopes and alternative item IDs. Repeated collection milestones use the largest remaining target. Tier 3 manual material lines match the cached item's exact English name with the existing count/plural/location syntax; unfinished recipes share one stock subtraction per goal. AQ pieces carry `requiredItems` metadata for token, two idols and five of each scarab. Completing a piece removes those requirements. Counts use last recorded character inventories, including banks only after opened. Separate goals each report their own needs; this is not a combined shopping list or stock allocation system. Incidental mentions in tips are not treated as requirements.
- **Gear preview:** item hyperlink and row clicks call `FGT.PreviewItemClick`, using the game's DRESSUP modifier (Ctrl by default) and `DressUpItemLink`. Step icons forward to the row handler. The detail reward icon has its own preview handler. Preview clicks consume the action without checking off a step, even while item data loads. Tooltip preview hints appear on equippable cached items. Shift-click chat links and right-click Wowhead actions remain.

The library currently has **152 goal definitions**, including collection wrappers and client-specific entries; the visible count varies by client and faction.

## Artwork and cleanup

Faction emblem treatment: same 62px width and source scale, extended sampling to the bottom of the 72px card instead of stopping above the progress bar. Opacity reduced from 27% to 19%; separate fade regions replaced by one continuous wash fading toward bottom-left. `/reload` to review.

Faction fade tuning: left fade now covers only the first 20px rather than the full 62px emblem area. Bottom fade holds more opacity through the upper/middle shape, still reaching zero at its edge. Placement and maximum brightness unchanged; `/reload` to review.

Custom faction card edge fix: emblems nudged 3px down/left. Left fade now reaches zero at its sampling boundary, and bottom fade reaches zero on the final strip, removing hard crop edges inside the card. `/reload` to review.

Horde thumbnail correction: 81744 is not a loadable texture ID on Karl's Forever client (green missing-texture square). Faction-only Horde PvP thumbnails now use `inv_bannerpvp_01`, the named Horde banner counterpart to Alliance's `inv_bannerpvp_02`. Numeric resolver support retained for valid texture file IDs. `/reload` applies this fix.

Numeric icon fix: ResolveIcon now passes numeric texture IDs directly to SetTexture, including IDs in fallback lists. Fixes reload crash from Horde icon 81744. Banner tests exercise both forms. `/reload` applies the fix.

Frostwolf banner correction: generic PvP art variants previously won before the explicit banner path; Frostwolf now bypasses that shared variant fallback. Faction-only PvP goals and class-set children use Horde icon 81744 or Alliance War Mount's banner icon. This supersedes the Frostwolf tabard thumbnail. Lua-only `/reload` if the new banner texture was already loaded at restart.

Frostwolf Clan banner installed from Karl's The Eye of Command TCG source, with approved monochrome framing/fades and watermark removal. Source preserved; Glenn Rane credited in Settings and ARTWORK-CREDITS.txt. Frostwolf thumbnail changed to Frostwolf Battle Tabard icon. Per-goal banner override follows the shared PvP map to avoid being overwritten. Full WoW restart needed for new BLP.

Custom faction assets: Karl approved generated white transparent logo cutouts and requested replacement. PNG masters in `Media/final-images/factions`, 256px RGBA TGA textures `Media/faction-alliance.tga` and `Media/faction-horde.tga`. Both cards now use the same tint/opacity/fades instead of differently shaded client emblems. Originals unchanged; full WoW restart required.

Faction emblem nudge: slightly higher/right crop and 2px inset. Horde opacity raised independently from 27% to 44% to compensate for its darker client texture; Alliance strength unchanged. `/reload` to review.

Faction emblem adjustment: shifted the artwork 10px farther right by narrowing its visible sampling area and cropping its right side within card bounds. Both fades eased and opacity slightly increased to reveal more of the emblem. `/reload` to review.

Faction emblem redesign: removed all carved shadow/inset layers. One soft monochrome layer now samples a cropped upper-right emblem in a 76x44px area, with full left fade and stronger downward fade before the progress bar. Existing client texture; `/reload` to review selected and unselected cards.

Faction insignia refinement: smaller 90px footprint, cropped source margins and tighter top-right placement. Carved layers toned down; combined slight left/bottom fades blend the emblem into the card. Existing client artwork, Lua-only; `/reload` to review selected/unselected states.

Faction card follow-up: removed ALLIANCE/HORDE ONLY from My Goals eyebrows, retaining faction wording on detail pages. Background insignias now draw above card surface gradients with stronger carved shadow/highlight and a less faint left-side fade, improving selected/unselected visibility. Existing client textures; `/reload` to review.

Title Forever chip follow-up: brighter blue border now breathes on the existing five-second cycle, static with Celebrations Off. Its inline dot lowered 2px to center with the text. My Goals NEW/UPDATED label treatment unchanged. `/reload` to review.

Forever badge polish: My Goals NEW/UPDATED labels have no box. Detail NEW/UPDATED IN FOREVER chips now use the same 22px height, padding and etched corner border as difficulty/duration, retaining blue edging. Both have a soft blue underlight breathing on a five-second cycle, held still with Celebrations Off. Uses existing texture; `/reload` to review.

Warm radial book lighting trial: a broad oval using the existing soft shadow texture with additive amber at 7% alpha, spanning the upper-left 90% width / 72% height of the cover. ARTWORK layer 2 lights leather, spine, edges and corner metal together, below welcome text/buttons. Scales inside the cover bounds; Lua-only, `/reload` to review.

Summary text fade slowed to 1.2 seconds at Karl's request. Suggested next visual treatment, not implemented: a faint warm upper-area light on the book to match the cobweb panel's brighter upper region; retain current spine and bronze fittings.

Correction to empty progress polish: overall bar stays visible even with no goals and is now 10px tall (previously 8px). Only the summary text underneath, including the percent, hides while empty. Adding the first goal fades both labels in over 0.45 seconds; motion Off shows them immediately. Removing all goals cancels the fade and hides the labels.

Final Mac empty-state polish: broad soft central shadow wash quiets leather behind welcome copy; corner contact shadows eased to 62%. Overall bar, percent label and goal completion count now hide with zero tracked goals and return when goals are added. Brown palette and spine lighting retained. Existing textures only; `/reload` applies changes.

Third Mac visual follow-up: corner fittings tinted aged bronze to match the brown leather. Spine's right contact shadow widened from 24 to 40px and strengthened from 80% to 95% at its root, fading smoothly to transparent. Lua-only; `/reload` to review.

Second Mac visual follow-up: restored the cobweb source's original brown by removing runtime desaturation. Empty book leather, spine, binding bands and rolled edges now use a dark brown tint; metal corner fittings remain neutral. Existing texture files are unchanged; `/reload` applies this color pass.

In-game review follow-up on Mac: restored the preserved `empty-bg` cobweb artwork over the empty goals-list panel. Book fittings now sit above the leather darkness with brighter neutral shading, stronger offset corner shadows, and smooth contact shadows under the spine and rolled edges. Existing textures only; `/reload` applies the change. Ambassador backgrounds are now approved and installed for both factions; originals, reviews, masters and runtime assets are synced.

Latest follow-up: Karl approved the spine in the in-place mockup, questioned the corner orientation and requested removing the middle lock. The lock and its contact shadow are now removed from `BookSurface`, along with their resize logic. Originals and textures remain preserved. Right caps use explicit mirrored texture coordinates instead of rotation: upper-right `(1,0,0,1)`, lower-right `(1,0,1,0)` from the top-left source, with matching contact shadows. This keeps the outer metal arms on the panel's top/right and bottom/right edges. Spine/bands/edges are unchanged. Full Lua5.1 Era/Forever suite passes. Lua-only change: `/reload` if the book textures are already loaded. Generated `ancient-book-in-tracker-mockup-2026-10-10.png` is a historical approximate mockup, not an actual screenshot, and still shows the now-removed lock; do not use it as the current installed reference.

Latest book revision: Karl restored the spine idea and requested only right-side metal caps. This supersedes the four-corner/no-spine descriptions below. `FGT.emptyUI.detailArt` now has a narrow left spine with fixed folded ends, mirrored/cropped middle strips, up to five separate raised binding bands, two thin repeating rolled leather edges, two right metal caps and the existing centered clasp. Spine width is normally 48px, capped at 16% of the panel width. Short heights reduce band count; tall heights spread them apart. The left goal-list panel retains leather only. No decorative inner border was added. New unchanged originals: `ancient-book-spine-2026-10-10.png`, `ancient-book-band-2026-10-10.png`, `ancient-book-edge-2026-10-10.png` in `Media/artwork`; corresponding `Media/empty-book-*.tga` runtime assets and source copies. Exact prompts, conversion and layout notes: `reports/image-tests/ancient-book-spine-install-2026-10-10.json`. Full Lua 5.1 checker passes on Era and Forever, including spine coverage/scale, band bounds, edge tile pooling and empty-state transitions. Full client restart needed; inspect short/tall and narrow/wide empty windows in game. No release/version change.

Matching book clasp added at Karl's request: `Media/artwork/ancient-book-clasp-2026-10-10.png`, runtime `Media/empty-book-clasp.tga` (256px alpha). Worn pewter scrollwork/keyhole/hinge matches the corner-fitting reference. It anchors RIGHT at the empty goal page's vertical center, normally 96x64px, with the same desaturation, contact shadow and darkness overlay. Scales down only when needed to fit between the corners; hidden if there is no available space. Decorative only, inherits the book frame's empty-state visibility and fade. First generated option preserved as `ancient-book-clasp-first-2026-10-10.png`. Prompts, transparency refinement and rebuild notes: `reports/image-tests/ancient-book-clasp-install-2026-10-10.json`. Source PNG copy excluded from releases; runtime TGA included. Full Era/Forever suite and extended book resize checks pass. Restart the client to review this new texture.

Book artwork installed after Karl explicitly requested generating and adding it: sources `Media/artwork/ancient-book-corner-2026-10-10.png` and `ancient-book-leather-2026-10-10.png`; runtime textures `Media/empty-book-corner.tga` (256px alpha) and `Media/empty-book-leather.tga` (512px opaque). Prompt/rebuild/authorization notes: `reports/image-tests/ancient-book-install-2026-10-10.json`. Supersedes the earlier concept-only status below. Four fixed 88px fittings rotate around the empty right goal panel; the left empty list has matching leather. Separate down/right contact shadows keep lighting consistent. Leather uses cropped mirrored tiles at a constant 512px scale and runtime desaturation; dark overlays keep it subtle. Both art frames share the existing empty-state visibility and fade. The old cobweb source/runtime is retained but no longer displayed by this empty state. The source PNG copies are excluded from release packaging. `empty-book-tests.lua` passes on Era and Forever for resize bounds, tile scale/pooling, fixed fitting sizing, empty/add/remove transitions and paired fades. Restart the client and review the empty tracker at several sizes, then add a goal and confirm all book artwork disappears. No release was published.

Book concept revision: Karl liked the direction and then requested removing the spine entirely. `Media/artwork/ancient-book-cover-no-spine-2026-10-10.png` is the current reference, with continuous leather and four fittings at the actual outer corners. The old spine concept is preserved as provenance only. Use separate leather and corner assets going forward; omit the spine strip. Prompt is recorded in `reports/image-tests/ancient-book-no-spine-2026-10-10.json`. No runtime installation yet.

After housekeeping, Karl explicitly requested a new empty-state art concept: an ancient closed leather book in monochrome, with four fixed corner fittings, a separate leather field and a left spine strip for flexible window dimensions. A coherent full-cover reference was generated first using built-in imagegen and saved as `Media/artwork/ancient-book-cover-concept-2026-10-10.png`; prompt/provenance is in `reports/image-tests/ancient-book-empty-state-2026-10-10.json`. This is a concept for review, not installed artwork. The separate runtime assets and resizing behavior are not implemented. Do not treat this reference as an approved installed banner or stretch it directly across all window sizes.

All **257 tracked artwork originals** in `Media/artwork` were audited recursively, including ignored additions. There were no pending originals or deletions at handoff. Artwork originals and final masters stay in GitHub for both machines; `.pkgmeta` excludes `Media/artwork`, `Media/final-images`, tools and reports from releases. Banner installation approval remains separate from source syncing.

The Stormwind / Orgrimmar ambassador photos Karl mentioned are still missing from the synced artwork folder. He will add them later; do not substitute unrelated images. No ambassador banner was installed in this session.

Existing dependency runtimes, the ignored offline workbench and previous release logs are retained. They are not disposable source files. Only generated Python bytecode caches may be removed during cleanup.

## Validation

`tools/check.py` compiles all nine loaded Lua files with real Lua 5.1, then runs startup and behavior sessions for Classic Era and Forever (including the removed legacy `GetItemInfo` global). The full checker passed after the implementation. It catches syntax/local-limit/load/behavior regressions, but does not establish in-game visual or native API behavior.

Relevant checks: `item-tooltip-tests.lua`, `completed-step-tests.lua`, `completed-step-motion-tests.lua`, `aq-armor-tests.lua`, `fishing-tests.lua`, `qiraji-tests.lua`, plus the existing armor migration, banner, short-window and dependency checks. Tooltip tests cover both hook paths, duplicates/rebuilds, selection/completion changes, scopes, alternative stock, actual Tier 3 totals, AQ ingredient totals, settings and preview versus normal clicks.

Mac: `python3 tools/check.py` after installing platform-native Lupa as described in AGENTS.md. On this PC, the bundled Python runtime and Windows Lupa under `C:/Users/kneis/AppData/Local/Temp/fgt-lua-check` were used because `tools/.py` contains a different platform's dependency build:

```powershell
& 'C:\Users\kneis\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -c 'import sys, runpy; sys.path.insert(0, "C:/Users/kneis/AppData/Local/Temp/fgt-lua-check"); from lupa import lua51; runpy.run_path("tools/check.py", run_name="__main__")'
```

## Karl's in-game review checklist

Restart the client after pulling new artwork. Lua-only follow-up fixes need `/reload`.

1. Narrow and wide My Goals panels: card names, eyebrow/class/faction text, etched faction insignia, favorite versus NEW / UPDATED, completed date and full bar.
2. Hide completed steps; finish individual steps, several automatic steps and a grouped/material step. Check the pause, fade, upward slide and absence of Lua errors. Toggle the filter, switch goals and reset during a transition.
3. Scrollbar normal/hover/drag states; reset icon orientation, counterclockwise spin and undo.
4. All nine AQ armor sets: independent cards, headpiece thumbnail, shared Skeram banner, tips and ownership progress.
5. Fishing goal: Booty Bay banner and three steps; blue/green/yellow/red AQ mounts share the old AQ art, Black Qiraji uses Scarab Lord art.
6. With a material goal active, hover its item in bags, loot, AH and chat. Confirm Needed for and remaining amounts. Complete the relevant step or remove the goal, then hover again. Verify no duplicates, and that the Settings switch disables it. Open banks on relevant alts before assessing counts.
7. AQ tokens / idols / scarabs and Tier 3 shared materials: remaining totals fall when pieces or material lines finish; unselected groups do not contribute.
8. Ctrl-click an available armor/weapon link, step icon, item tag in tips and reward icon. Dressing room opens on the character and progress does not change. Ordinary clicks, Shift-click chat links and right-click Wowhead still work. Items Forever has not revealed cannot be meaningfully previewed until their data is available.
9. Small window, expanded recipes, Settings and demo scenes retain their existing bounds and scrolling behavior.

## Existing follow-ups and release prep

- Forever prerequisite gates are still deliberately off pending verification. Do not claim they are active.
- The existing `SetItemRef` replacement / player-name-copy taint issue remains a separate open follow-up in AGENTS.md. Today's item tooltip hooks do not replace it, and this session did not resolve it.
- Public gallery shots 01, 03, 04 and 05 now have changed cards and/or guide controls; review/retake before the next release. The saved Settings shot also needs a retake for the new tooltip group and eventual version bump. A manual tooltip screenshot could illustrate Needed for after Karl checks it in game.
- README files and ROADMAP describe the new features. CHANGELOG keeps brief player-facing Unreleased notes; this handoff and git history hold the details. When Karl authorizes a release after review, choose the version then, update the store description's goal count/features/roadmap, check screenshots, and use the normal release workflow. No “Saturday CurseForge push” task or release title is needed.
