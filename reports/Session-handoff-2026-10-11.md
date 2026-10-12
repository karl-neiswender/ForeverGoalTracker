# Session handoff, October 11, 2026

Source changes for the next release. No release tag or CurseForge publication.

- Ctrl-click mounts in addon guide links, rows, tips and reward icons uses the native direct mount preview. Mount items in Forever return a generic Learning spell (55884); item-to-mount lookup returns nil. Native DressUpMountLink returned false for both tiger and epic ram. DressUpMount(96) rendered Swift White Ram, and DressUpMount(111) rendered Swift Zulian Tiger. Actual Ctrl-click on the tiger guide rendered the tiger without changing 0/2 progress before the final guide simplification.
- Exact mount names from the library match journal entries. A lazy scan caches the journal once per session, guarded for clients without native mount previews. Individual racial color variants are mapped independently. Repeated Ctrl-clicks on a mount type cycle its colors; tooltip explains this. Tests cover color cycling, native lookup, unsupported clients and preserving other click actions.
- Artwork credits: 6 UI units, neutral grey, bottom right inside the scrollbar. Smooth resize fade across panel widths 350–520 and heights 280–430. In-game Wolfsbane credit visible at normal size and disappeared at 750x450 window size. Artist names are shown only for verified mappings: Samwise Didier (Wolfsbane), Glenn Rane (Frostwolf), Karl Kopinski (Alliance Felheart). Other banners remain blank pending attribution; no guesses.
- Guide pass replaces weekly raid preparation with level 60 milestones for Atiesh, Thunderfury and Sulfuras. Adds level steps for Wolfsbane (18), hunter weapons/Benediction/Charger/Dreadsteed/Naxx attunement (60), MC/BWL attunements (55). Keeps the existing unverified Forever Frostsaber level baseline; simplifies its reputation milestones and moves travel/quest advice to tips.
- Removes duplicate boss-kill milestones from tiger, raptor and Deathcharger guides; loot remains the goal. Removes the optional 300 Blacksmithing checkbox from Sulfuras, retaining crafting advice. Removes the unrelated Inferno quest from Dreadsteed and restores six missing ritual-branch quests. Atiesh purification now tracks quest acceptance before the guardian fight. Rhok’delar sinew turn-in corrected to Stoma.
- Sparse saved ticks remapped once, after older migrations. Final migration supports the partial beta reload used during development. Repeat-login and partial-beta fixtures pass. Classic dependency indices move with added level rows; Forever gates remain disabled.
- Full python3 tools/check.py suite passed for Lua 5.1, Classic and Forever, including accidental global checks, mount behavior, resize layout, migration idempotence and existing regressions. Retained output: reports/checks/mount-credit-guide-2026-10-11.txt. Performance review: no new continuous updates; one lazy journal scan, constant-time cached previews, credit updates only on layout/resize.
- Quest minimums and Dreadsteed branches checked against https://raw.githubusercontent.com/Questie/Questie/v10.0.0/Database/Classic/classicQuestDB.lua and the retained dependency audit. These are Classic baselines, not verified Forever prerequisite gates.
- Original artwork recursively checked, including ignored files: no new, modified, deleted or ignored originals awaiting sync.
- No live release requested. Fresh Ketho/LuaLS diagnostics are still required before the next release tag, per AGENTS.md.

## 2.11.1 release candidate (latest)

Karl requested preparation while performing final in-game checks. Version, changelog and roadmap are prepared for 2.11.1. Ketho 0.22.3/LuaLS 3.19.1 installed and annotations verified loaded. Final diagnostic passes report zero problems with individually documented legacy/optional API exceptions; no categories disabled. Retained API review: reports/checks/release-2.11.1-api-review.md. Full Lua 5.1/Era/Forever checks pass, including progress migrations, profession selection, mount previews and accidental globals.

Cleanup corrects the statistics debug command’s achievement-ID lookup, documents dynamic UI fields/settings and guards the wizard grey-state collector. Approved art includes profession faction selection, credited shaman Warlord Mail and Stratholme Key/Devout. Deathcharger art is unchanged. Candidate ZIP at /private/tmp/ForeverGoalTracker-2.11.1-candidate.zip passes integrity/texture bounds; 199 files, 117 runtime BLPs, source artwork/reviews/tools excluded. No release tag or live publication. Wait for Karl’s final in-game checks and release instruction.

## 2.11.1 shipped (supersedes candidate publication status)

Karl confirmed final in-game checks passed. Tag v2.11.1 points to 00bbf42. Release workflow 38175702919 completed successfully, including the BigWigs packager configured for CurseForge. GitHub release published at https://github.com/karl-neiswender/ForeverGoalTracker/releases/tag/v2.11.1. Downloaded published ZIP verified: correct TOC version, new shaman/Stratholme/Horde Engineering textures present, excluded source/review/tool folders absent, ZIP integrity passed. Metadata declares Classic 11509 and Forever 16001. Evidence in reports/checks/release-2.11.1-published.json.

## Final closeout for PC and Mac (latest)

- v2.11.1 is shipped and Karl's in-game checks passed. Source, approved masters/runtime textures, artwork originals, validation results and description files are committed on main. No further live publication is pending.
- Updated concise CurseForge Markdown is reports/CurseForge-description-2.11.1.md: simple features, latest three releases, full changelog/roadmap links. The exact AI disclaimer must be the final content of every description. Preferences are saved in AGENTS.md. Description files were prepared for Karl to paste; do not claim the CurseForge description editor was updated automatically.
- Artwork credits fade with the image; current credit font is 7 UI units. Profession artwork follows logged-in skills, including gathering and secondary professions, with a stable random choice among eligible images. Horde Engineering uses the mechanical hammer; Alliance uses the dwarf. Warlord Mail shaman uses signature-free Bru'kan art with Alex Horley credit; Hunter keeps its prior mail art. Stratholme loading art has UI removed and is installed for Stratholme Key and Vestments of the Devout only; Deathcharger remains unchanged.
- Recursive artwork audit included ignored files: no pending originals, modifications or deletions. Main matched remote before closeout; this closeout is committed and pushed as the final sync.
- On either machine, pull main before editing. If that checkout has local changes, ask before pulling. Restart WoW after pulling new/replaced textures; Lua-only changes need /reload. SavedVariables remain local to each machine.
- Mac Ketho/LuaLS installs are machine-local; the retained config contains Mac paths. On PC, install/locate both extensions and adapt annotation paths for the next release check. Do not assume this Mac installation or Python dependency build works on Windows.

## PC live review and Unreleased follow-up (October 11 evening)

Karl verified centered opening, the minimum window size and the revised
110% maximum in game. He approved the shorter tips. Startup and font-switch
Lua errors were fixed, and he confirmed both fixes in game.

Warcraft Modern is withdrawn at Karl's request: Open Sans Bold headings
looked too chunky. The font selector is removed and saved Modern preferences
return to Serif. Internal typography helpers remain; unused Open Sans files
stay in GitHub but are excluded from releases. Details and checks:
modern-withdrawal-2026-10-11.md. This supersedes earlier typography plans.

Other follow-ups remain Unreleased: matched note/Edit icon colors, concise
guides/tooltips, session-only `/goals testlocks` Forever preview and revised
racial mount cost guidance (1,000g Journeyman training + 200g mount, before
discounts). Forever locks stay off by default. No new release was requested.
All changes must be synced to main; native review can continue after `/reload`.

Native dependency follow-up: a locked Lok'delar demon click remained at 0/8
and displayed its prerequisite tooltip. Both modern quest-status APIs exist
and returned false normally for this character's unstarted hunter chain.
The temporary leaf tick from a misaligned coordinate click was restored and
0/8 verified. Preview remains on. Code now has an empty separate Forever
dependency table for gradual verified-edge rollout; no rules are enabled by
default. Shared checklist progress is not current-character eligibility.
Details: Forever-dependency-native-review-2026-10-11.md.

Latest heading style: Karl requested replacing Cinzel with the standard
Warcraft body font. All title-role text now uses Fonts\FRIZQT__.TTF at its
existing size/color/shadow. No selector; typography helpers remain. Cinzel
and Open Sans studies are preserved in GitHub and excluded from releases.
Details/checks: warcraft-heading-font-2026-10-11.md. `/reload` to review.

Panel-width correction: Karl confirmed Warcraft headings look better, but
the tabs' narrower text indirectly narrowed the left goals panel. Original
tab/list widths now use hidden Cinzel Bold measurements at the previous size;
visible labels remain Warcraft. Cinzel Bold/license stay packaged for those
two startup measurements. Window bounds and anchors remain unchanged.
Details/checks: warcraft-heading-font-2026-10-11.md.

Karl requested another 22 UI units of width for the left goals list after
reviewing truncated titles. Added beyond the restored original tab footprint;
the right panel uses the remaining space. Overall window size is unchanged.
Checks: checks/wider-goals-list-2026-10-11.txt. `/reload` for native review.

After native review Karl requested a little more width. Added another 12 UI
units, now 34 beyond the original footprint. Overall window size is unchanged.
Checks: checks/wider-goals-list-followup-2026-10-11.txt.

Latest width: Karl requested 40 UI units beyond the original footprint,
replacing the 34-unit offset. Checks: checks/goals-list-40-2026-10-11.txt.

Karl requested another 10 UI units after review; the final current offset is
50 beyond the original tab footprint. Overall window size is unchanged.
Checks: checks/goals-list-50-2026-10-11.txt.

Materials drawer: Karl approved the mockup and requested the first addon
implementation. New Materials.lua loads after ItemTooltips.lua and provides
a per-goal drawer, tucked-away sliver, moving etched handle, short glide,
bars/percentages, counts on hover and a sliders menu. The center guide flexes
inside the unchanged overall window. Defaults: collapsed each reload, hide
collected, hide inline counts, include tracked alts. All changes remain
Unreleased; native review is next. See materials-panel-2026-10-11.md and its
retained full checker output for data/counting limitations and validation.

Native Materials review: Karl confirmed no load errors and working sliding.
He clarified the drawer should emerge from under the outer right edge, with
the gradient visible only while tucked away. Panel now travels with its left
edge; right-edge shade fades away on opening. Guide rows reflow at most three
times mid-transition, then refresh at completion. Checks and details:
materials-panel-2026-10-11.md; checks/materials-slide-fix-2026-10-11.txt.
