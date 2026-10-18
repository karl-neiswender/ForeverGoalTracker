# Release 2.15.2, October 17, 2026

Karl explicitly authorized publication of this round of updates after native screenshot review, including confirmation of the recipe-row wrapping fix.

## Quality gate

- Final runtime candidate: TOC and What's new 2.15.2. Real Lua 5.1 compilation, accidental-global checks and 106 Era/Forever runtime scenarios passed. Output: `release-2.15.2-lua51.txt`.
- Fresh Ketho WoW API 0.22.3 / LuaLS 3.19.2 diagnostics: zero problems. 14,027 annotation load references verified, including the FontString, Frame and ScriptRegionResizing definitions used by the layout changes. Raw diagnostics and loading evidence: `release-2.15.2-luals.json` and `.txt`.
- Ketho provides a combined annotation library, not a dedicated Forever profile. This release uses the same explicit legacy/optional-symbol configuration as the prior verified Mac release. Classic Era 11509 and Forever 16001 paths were checked separately by the runtime suite and API review below. No diagnostic categories were broadly suppressed and no new exceptions were added.

## API compatibility and performance review

No new game API dependency was added since 2.15.1. New UI calls reuse supported Frame/Texture/FontString methods already used throughout the addon. Era and Forever use the same row layout, completion styles and filtering helpers. Forever-only child/part cards retain client availability checks. Existing guarded map and hyperlink routes handle the new named city destinations; legacy roster/container/settings API fallbacks and optional TomTom behavior are unchanged. The explicit annotation exceptions and their client guards remain documented in `release-2.11.1-api-review.md`.

No new game events, recurring timers or animation loops were introduced. The completed-goal filter reads existing progress during layout; the rail count follows layout. Extracted mount proxies are cached by original parent/part identity. Recipe labels measure their count column during layout and grow down with wrapped text. No new inventory scan or per-frame catalogue search. Native CPU profiling was not repeated, and headless checks do not measure native frame time.

## Native evidence and preserved data

Karl approved the completed-card treatment in Library and My Goals and explicitly confirmed that the narrow recipe layout fix worked in game. Source scenarios cover completed-goal hide/recovery, original item/material keys, class/faction and New & Updated filtering, part Add/Remove, main/pop-out rendering and client guards. No progress migration, step reordering or rule changes. War mount pins are hall approaches and retain an Unconfirmed notice on Forever; Horde coordinates remain an adjacent-client reference pending native verification. No new exact-position confirmation is claimed.

## Package and documentation

Local package simulation: 352 runtime files, modules and licenses present, 2.15.2 TOC and both interface numbers verified, ZIP integrity passed. Development tools/reports, unused font studies and artwork originals excluded. Manifest: `release-2.15.2-package.txt`. Final workflow ZIP must also be verified after upload.

Changelog and in-game What's new share six concise release lines; explanatory notes preserve guide details and uncertainty. README documents the filter and direct item lists. Roadmap moves this batch into 2.15.2 and keeps Gear Planner next. The exact bottom AI disclaimer is unchanged. Existing gallery was reviewed as prior-version imagery; no newly captured release gallery or author-console description update is claimed.

Artwork audit: 445 original files under Media/artwork, including an ignored/untracked check. No local artwork changes or deletions. Existing originals are already on main.
