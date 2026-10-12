# Claude handoff: October 8–11, 2026

Prepared October 12 at Karl's request. This is the current context for Claude
to continue refinement and, if Karl decides to proceed, prepare another update.
Read this and AGENTS.md before relying on older notes in CLAUDE.md. Historical
reports contain abandoned proposals and earlier release states; the current
behavior below and the final closeouts supersede those descriptions.

## Start here

- Shared branch is main. Source snapshot before this documentation update:
  `059d7478dd65c44e3c93d6243742c35a5456c968`.
- The PC checkout was clean and `git pull --ff-only` reported up to date.
  Recursive Media/artwork audit included ignored files and found nothing pending.
- Latest published version is **v2.11.1**, release commit `00bbf42` on October 11.
  The TOC still says 2.11.1. All subsequent evening changes are **Unreleased**.
  No new version, release tag, publication or scheduled release is authorized.
- Fresh current-source Lua 5.1/Era/Forever checks passed on October 12. Evidence:
  [current check](checks/claude-handoff-current-code-2026-10-12.txt).
- Ketho/LuaLS checks passed for the *published 2.11.1 snapshot on the Mac*.
  They have not been refreshed for the latest Materials/font/window changes.
  A fresh annotation-loaded diagnostic run is required before another release.
- Full four-day history: **385 commits and 1,080 changed paths**. The exhaustive
  [Git inventory](Claude-four-day-git-inventory-2026-10-12.md) includes every
  commit title, timestamp and changed file since baseline `0f0e707`.
  Use `git show <commit> -- <file>` for exact implementation diffs.

## Karl's priorities and decisions

Players should focus on playing. The addon should be **SIMPLE, HELPFUL, CLEAR**.
Use concise player copy, practical tips and a consistent visual hierarchy.
Do not repeat a hovered step in its tooltip. Preserve quest/item names, useful
locations, quantities, costs, exceptions and restrictions. Say Unconfirmed for
uncertain Forever rules and Source unknown when gear sources are missing.
Keep link tags and material parsing strings intact when editing copy.

Karl designs and tests in game, often giving live spoken reactions. Make the
requested adjustment, then give a short instruction for checking it. The grey
resting icon/gold hover pattern is preferred. Keep UI quiet; do not reintroduce
heavy buttons, oversized icons, repeated labels or cluttered Have / Need ratios.
Materials uses percentages and bars, with exact counts on hover by default.

Approved current direction: native Warcraft typography, slightly wider goals
list, bounded window resizing and a compact per-goal Materials drawer within
My Goals. The center guide flexes and scrolls. Optional hidden future steps is
a roadmap idea only. A Modern font selector is withdrawn, not unfinished work
to resume automatically. Earlier all-goal Materials tab/pinning ideas were
superseded by the per-goal drawer.

## October 8: notes, prerequisites and banner foundation

Code work and decisions, primarily Core.lua, Dependencies.lua and tooling:

- Personal notes on goal pages: painted note icon, note editor/modal, saved
  per-goal text, live character count, disabled empty saves, shaded backdrop,
  modal animation and improved control spacing. Only the note icon edits notes.
- Reset goal: refresh-style arrow, undo countdown and animation of restored
  progress. Later refined to the current mirrored/counterclockwise treatment.
- Classic prerequisite research across the then-79 goals, with stable guide
  addresses in `research_notes/Goal step dependency audit/`. Dependencies.lua
  implements gates, multiple parents and unlock behavior. Silver locks and
  breakaway unlock effects were approved. Level milestones themselves remain
  available objectives; subsequent actions may be locked by them.
- Large goal-banner redesign from Karl's supplied layout. Artwork blends into
  the panel, extends below the header, crops to bounds, fades on first visible
  opening and keeps the reward icon immediate. Saved-goal fade-driver visibility,
  background layering, clipping, top/right shadows and gradient transitions
  were corrected during iteration.
- Link painting moved into SetText so links do not flash their final color
  before the fade. Item fades update smoothly; scrolling edge fades softened.
- Artwork workflow separated untouched originals, approved masters, previews
  and installed runtime textures. Monochrome framing with baked left/bottom
  fades became the standard. Numerous weapon/raid/mount banners installed;
  rejected Rhok'delar imagery was replaced rather than kept as the live image.
- v2.9.0 released, with refreshed gallery shots and short changelog copy.
- The player-name-copy taint concern from replacing SetItemRef was recorded.
  It remains an open issue, not a completed fix; see the current risks below.
- Appearance/font/progress-style brainstorms were recorded. Most remain ideas,
  and later font decisions below supersede the original Classic/Modern plan.

Representative commits: `e89c457` notes, `0e65225` reset, `d24418b` dependencies,
`2f75410` silver locks, `0f87030` banner redesign, `9e349bc` immediate link paint.

## October 9: independent armor goals and artwork expansion

- ArmorSets.lua splits class armor sets into independently tracked goals with
  stable IDs (`<parent>_<class>`). Library collection wrappers retain class
  pickers. Activating a class chooses the child goal; materials and progress
  remain per child. The one-time armor migration preserves selected parts,
  sparse ticks, favorites, notes, completion status/date and selected goal.
  Do not merge old parent progress again after players reset children.
- Short-window goal content moved into a scroll viewport so headers, expanded
  recipes and long notes remain reachable. Compact titles, title-case short
  armor names, class colors and faction/class detail labels refined.
- Banner layout became responsive: preserve source aspect, anchor/crop at top
  right, adjust coverage to available panel dimensions and keep fades readable.
  Per-goal opacity tuning exists for review (`/goals banneropacity`).
- Artwork selection supports logged-in faction/class/race for leveling,
  racial mounts and PvP. A shared variant must not override an explicit goal
  image; later Frostwolf fix enforces that priority. Valid numeric texture IDs
  and lists are supported, but do not use an unverified file ID as a fallback.
- Added Violet Sorcerer's Vestments as a Forever-only goal with appropriate
  NEW styling and a Dalaran banner. Classic Era does not expose that goal.
- Broad approved banner coverage: class Tier 1/2/3, faction-specific armor and
  leveling images, racial mounts, PvP, Naxxramas/attunement, AQ/C'Thun, Hyjal,
  Barrow Deeps, Deathcharger, Dire Maul, Timbermaw, gold and other goal images.
  Use the inventory for each original, revision, approval and installation.
- Portable project banner skill added under `.agents/skills/`; read it before
  preparing new raster banners. Exact image prompts/reviews are retained under
  reports/image-tests. Preview existence does not mean installation approval.
- v2.10.0 and v2.10.1 released; refreshed/cropped gallery images saved.

Representative commits: `d54a542` independent armor goals, `5848e8c` viewport,
`aaa6bf9` Violet Sorcerer, `37cfb6e` character-based artwork, `665f31a` 2.10.1.

## October 10: guide filtering, recipe data, tooltips and UI polish

- Completed-step visibility is controlled beside Step by step and saved as
  `hideCompletedSteps`. New completions pause for the check animation, fade,
  then remaining rows slide upward. Goal switches, resets and filter changes
  cancel pending motion. The tween driver snapshots jobs and verifies identity
  before callback updates, fixing mutation during pairs iteration.
- My Goals cards stay 72 units high and have three layers: context eyebrow,
  compact goal name, progress bar. Difficulty is on the detail page. Finished
  cards show completion/date and a full bar. NEW/UPDATED sits top right and
  is replaced by the star when favorited. Class-set card eyebrows are plain
  `[CLASS] SET`, grey normally and gold/blue when selected; detail labels keep
  class/category colors. Faction restrictions use subtle background emblems.
- Scrollbars use etched bronze tones and do not widen on hover. Reset arrow
  is mirrored and rotates counterclockwise. Numeric icon handling corrected;
  invalid Horde texture 81744 replaced by named faction banner textures.
- AQArmor.lua adds nine independent Classic AQ40 Tier 2.5 class-set goals,
  five pieces each, ownership rules, token/idol/scarab/reputation tips and
  headpiece icons. `requiredItems` is structured recipe metadata. Shared
  Skeram Cultist artwork is approved. Do not treat Classic recipes as newly
  verified Forever rules just because the data is present.
- Fishing Extravaganza goal: 150 Fishing, 40 Speckled Tastyfish, Master Angler
  or either prize, with Booty Bay artwork. Four separate colored AQ battle
  tank goals were added; Black Qiraji retains its distinct Scarab Lord goal.
- ItemTooltips.lua provides default-on Needed for in bag/loot/AH/chat and
  addon item tooltips. Modern tooltip processor and guarded legacy hooks are
  installed once. Comparison tooltips avoid duplicates. Per-goal remaining
  counts respect selections/scopes, alternative IDs, largest repeated stock
  target and summed recipe needs. Tips alone do not become requirements.
- Ctrl-click gear previews use the player's DRESSUP modifier. Guide text,
  icons, item tags and reward icons route to the preview without ticking a
  step, even while data loads. Shift-click links and right-click Wowhead remain.
- Empty tracker uses an ancient leather book, modular spine, binding bands,
  rolled edges and right corner fittings with responsive sizing. The trial
  middle lock/clasp was removed. Brown leather, bronze tint/contact shadows
  and subtle warm lighting were tuned. Historical mockups may show removed
  fittings, so inspect installed code/assets instead. Overall bar stays visible
  with no goals; summary text hides and fades in after adding the first goal.
- Faction cutouts/soft watermarks replaced carved stamps and were scaled,
  cropped and faded. Final tint is subtle, not the bright early experiments.
- Large goal photos default to full panel height and about 70% width with
  preserved aspect/top-right cropping; Settings restores previous sizing.
- Detail progress bar is 13 units high, etched, with a soft internal tip pulse.
  Its completion transition fades current brightness rather than flashing.
  Collapsed group surfaces fade toward the right; expanded groups stay opaque.
- Session default window size became 70% of UIParent width/height, with sizing
  retained during the session and reset on reload. October 11 later added
  explicit min/max bounds and corrected first-open centering.
- v2.11.0 shipped with verified ZIP/workflow. Eight gallery shots retaken and
  cropped; author-console gallery uploads/description pasting were left to Karl.

Detailed evidence: [October 10 handoff](Session-handoff-2026-10-10.md), whose
end-of-night section supersedes its initial Unreleased state.

## October 11 daytime: native mounts, guide migrations and 2.11.1

- Native mount preview discovery: mount items reported generic Learning spell
  55884; item-to-mount lookup returned nil and DressUpMountLink returned false
  for tested tiger/ram. Direct DressUpMount rendered the expected native mounts.
  ItemTooltips.lua now lazily indexes journal names once per session, uses
  direct lookup first, then exact-name fallback, and guards unsupported clients.
  Repeated Ctrl-clicks on racial mount groups cycle individual color variants.
  Native tiger preview was observed without changing goal progress.
- Added Forever-only Wolfsbane for Undead Paladins, level 18 and scoped sword
  training, correct rare reward styling, Undercity weapon-master link and banner.
  Learned weapon-skill rank 1 is binary and no longer displays a progress bar.
- Guide corrections: level milestones for legendaries/hunter weapons,
  Benediction/Charger/Dreadsteed and attunements; duplicate boss-kill steps
  removed from rare mount loot goals; optional Blacksmithing checkbox removed
  from Sulfuras but retained as advice; Dreadsteed ritual branches repaired;
  Atiesh quest acceptance tracked before guardian fight; Rhok'delar turn-in Stoma.
- `guideFix20261011Final` handles sparse ticks and the partially applied beta
  migration, after older migrations. `wolfsbaneTrainingFix` and existing Tier 3
  recipe/armor migrations remain. Dependency indices moved with actual steps.
  Wording-only edits do not need another migration.
- Modern profession scan uses all six GetProfessions return slots, including
  secondary skills when primary slots are absent. Profession banners follow
  logged-in skills and retain a stable random choice among eligible images.
  Faction-specific Engineering uses separate approved images.
- Artist credit is small neutral text at the lower-right guide edge, fades
  with the artwork and with tight width/height. Latest size is 7 UI units.
  Settings artwork-credit section was removed. Only verified artist mappings
  are displayed; do not invent attribution. Source attribution/license records
  are retained even when a displayed signature was removed from an approved
  edited banner.
- Added/refreshed approved profession, reputation, raid/dungeon, class, mount
  and faction images. Important final mappings: Stratholme artwork is for
  Stratholme Key and Devout, not Deathcharger; signature-free Bru'kan/Alex Horley
  is Warlord Mail shaman, with hunter mail unaffected. Original inputs remain
  unchanged and synced. Review/install manifests identify final variants.
- Unknown item-set drops explicitly say Source unknown. Forever/class/faction
  eyebrow restrictions and guide bottom fades were refined.
- Performance/global audit reuses progress pulse colors, caps gradient painting
  at 20 Hz, and rejects unexpected startup globals in the checker. It does not
  prove in-game frame time or remove the known SetItemRef replacement.
- Ketho 0.22.3/LuaLS 3.19.1 installed on Mac, 3,506 annotation files verified
  loaded; Era/Forever diagnostic passes returned zero problems using documented
  optional/legacy API exceptions. The annotation library is a client union,
  not a dedicated verified Forever flavor. Runtime branches still need checks.
- Karl approved and shipped v2.11.1. Workflow 38175702919 succeeded, public ZIP
  inspected for version, assets, exclusions and integrity. Release metadata:
  Classic 11509, Forever 16001. Retained package/publication evidence is in
  reports/checks/release-2.11.1-*.
- CurseForge description was shortened to features/latest three releases with
  full changelog/roadmap links and Karl's exact final AI disclaimer. Markdown
  was prepared for him to paste; do not claim the author console was updated.

Evidence: [October 11 handoff](Session-handoff-2026-10-11.md), final shipped
section; [release API review](checks/release-2.11.1-api-review.md), whose later
publication state is superseded by [published evidence](checks/release-2.11.1-published.json).

## October 11 evening: current Unreleased code

### Typography and width

An initial Serif/Modern Settings feature used Cinzel versus Open Sans and a
weak widget registry. Native startup probe SetText-before-font failure was
fixed; a switch-time out-of-scope RefreshOverall call became FGT.RefreshOverall.
The stub now chains HookScript correctly, and tests disable the leaked global
so the permissive mock cannot hide that error again.

Karl disliked the chunky Modern headings and withdrew the selector. Saved
`DB.settings.typeStyle` is retired at startup. Registry, roles, nominal sizes,
line spacing, fallback and internal profile/layout helpers remain. **All
visible headings and body text now use Fonts\\FRIZQT__.TTF.** There is no
public font choice. Do not restore Cinzel visually or resume Modern automatically.

The old tab labels determined the list panel width. Native text narrowed tabs
and the left panel indirectly. Two hidden Cinzel Bold measurements preserve
the original tab footprint; Cinzel Bold and OFL remain packaged for that only.
Other Cinzel/Open Sans studies are preserved in GitHub but excluded from ZIPs.
Karl then widened the list in small native-reviewed increments. Current width:
combined original tab footprint plus **50 UI units**, not 22/34/40. Overall
window dimensions did not increase to accommodate those increments.

### Window, copy and icon polish

- Window minimum is 75% and maximum 110% of the 70%-screen default in each
  dimension, subject to screen-fit/margins and small-screen safeguards. The
  first 125% maximum was rejected as too large. First opening after reload
  centers the default; movement/resizing persists only within that session.
- Personal-note icon matches the Edit icon's grey rest/gold hover treatment.
- Broad copy pass shortened steps, tips and shared UI messages while preserving
  IDs, rules, ordering, links and parsed material strings. Automatic step
  tooltips retain Tracked automatically/readouts/hints but drop repeated
  Completes when text. No wording-only progress migration.

### Forever locks: preview only

- `/goals testlocks on|off|status` enables a session-only Classic gate preview.
  Reload ends it. Classic Era gates continue normally.
- `FGT.FOREVER_DEPENDENCIES` is a separate **empty** rollout table for individual
  verified Forever edges. Default Forever gates remain disabled.
- Native locked Lok'delar demon click preserved 0/8 and showed prerequisites.
  C_QuestLog active/completed functions exist and returned false normally for
  this unstarted chain. These checks establish UI/API behavior, not positive
  quest events or proof of every gameplay prerequisite.
- Karl manually tested the leaf/acceptance/four-demon/reward unlock flow and
  liked it. The automated coordinate test briefly ticked the leaf accidentally;
  that one tick was restored and original 0/8 verified. No outstanding test
  progress corruption should be carried into a new session.
- Locks are shared-roster checklist gates, not current-character eligibility.
  Auto scopes are honored; manual/historical ticks have no character owner,
  and parents may have been completed by different characters.
- Optional hidden/blurred future steps is Maybe someday only; no implementation.

See [native dependency report](Forever-dependency-native-review-2026-10-11.md).

### Mount costs and uncertain rules

Karl supplied Forever costs before faction discounts: non-epic racial mount
20g, epic 200g; Apprentice 100g at 60%, Journeyman 1,000g at 100%. Racial epic
guides now budget **1,200g** with separate training/mount tips, including
Skyborne. Classic Era estimates and special quest/raid/PvP mounts are unchanged.
Existing earned ticks are not erased because the target changed.

He also supplied a trusted, explicitly tentative mount explanation: account-wide
ownership but per-character racial riding access, Exalted other-race access,
first 60% mount possibly free, fixed mount speeds, companion possibly scaling.
These were discussed, not installed as verified rules/tips. Do not replace
the 20g/200g costs with that excerpt's older 10g/100g speculation. Automatic
Exalted unlock behavior and companion substitutions remain unverified. Do
not treat riding eligibility as proven by account-wide ownership.

### Materials: final native-reviewed direction

`Materials.lua` loads after ItemTooltips.lua. Core.lua exposes a narrow
`FGT.MaterialsUI` bridge with shared fonts, bars, scroll areas, styling,
selected-goal access, watched items and guide layout. No new main-chunk locals.

- **Per selected goal**, not all active goals. Explicit ingredients/countable
  item-collection steps; no requirements invented from tips. No manual pins.
- Default collapsed each reload. Same-session window hiding/reopening retains
  open/closed state. Sliders preferences persist in DB.settings.
- Closed shows 22 units of the actual panel surface, plus a 12-unit gap. Open
  uses up to 210 units inside the unchanged window; center guide flexes/scrolls.
  Very narrow windows leave it closed until sufficient guide space is available.
- Panel comes inward from under the **far-right outer edge**, rather than being
  revealed from under the guide. Its left edge travels with the allocated clip.
  Tuck gradient is on the right only while closing/closed and absent when open.
- Current handle is a **10-unit grey chevron centered in the gap**, gold on
  hover, no box/grime/shadow. Invisible hit area 24x48. It moves with the panel
  and reverses direction. Earlier etched-button proposals were superseded.
- 0.26-second eased glide; animation driver stops at completion/hide. Guide
  reflow is throttled to 75 ms, at most three intermediate reflows, then a final
  refresh. Celebrations Off skips motion. No permanent idle update was added.
- Latest change fades title, sliders control, list and scrollbar with the slide.
  Surface/sliver/arrow remain visible. This latest fade still needs final native
  review; do not label it verified solely from passing stub tests.
- Small icons, names, percentages and existing bars. Exact collected/remaining
  counts on hover, or inline when enabled. No Have / Need ratio clutter.
- Two parallel slider rails/knobs open local options: `materialsCollected`
  false, `materialsCounts` false, `materialsAlts` true by default.
- Item-count mini-bars under collection/catch guide steps are now removed;
  their rules, links, readouts and ticks remain. Skill/gold/level and other
  non-item bars stay. Pooled-row tests verify reuse does not revive item bars.
- Source quantities: flat auto item/count collection, AQ `requiredItems`, Tier 3
  manual lines. Same stock milestones use maximum target; separate recipe
  quantities sum. Selected parts and race/faction scopes respected. Saved
  collection ticks credit stock, but do not double-count it still held in bags.
  Completed/owned pieces credit spent ingredients separately.
- Item IDs unresolved from manual names show Count unavailable instead of fake
  zero progress. Names/IDs resolve from existing tags or client cache. New IDs
  enter the watch list and capture current-character stock; alts require new
  scans. Item-info events are relevance-filtered and coalesced. No goal ticks
  are created, reset or migrated by this panel.
- Native review confirmed no startup errors, working sliding, the corrected
  travel direction and subtle arrow. Final fade/removal, filters, recipes,
  scrolling and CPU behavior still deserve a full release review.

Evidence: [Materials report](materials-panel-2026-10-11.md), tests
`tools/materials-tests.lua`, retained materials-panel/slide-fix/arrow/fade
check reports. Original HTML prototypes are thread-local; source code and
the synced implementation report are the portable reference for Claude/Mac.

## File map for continuing work

| File | Current responsibility / important changes |
|---|---|
| Core.lua | Shared DB/roster/rules/UI, notes, locks and animation, banner rendering, scroll viewports, guide filtering, typography registry, window sizing, list width, Materials bridge/watch/refresh integration and removed collection bars. |
| Materials.lua | Requirements/stock aggregation, live drawer geometry, clipping, fades, local options, pooled rows, event relevance/debounce. |
| ItemTooltips.lua | Needed for computation/hook installation, gear previews and lazy mount-name/color lookup. |
| Dependencies.lua | Classic prerequisite graph, shared-progress semantics, session preview and empty separate Forever table. |
| Data.lua / Library.lua | Goal definitions, clear copy, new goals, corrected milestones/quests, Forever racial costs, set tuples. |
| ArmorSets.lua | Independent class-set goals and one-time migration of grouped selections/progress. |
| AQArmor.lua | Nine Tier 2.5 sets and explicit token/idol/scarab ingredients. |
| Npcs.lua / Quests.lua | Source NPCs/quest starts and watched IDs; exact links must survive wording changes. |
| ForeverGoalTracker.toc | Current complete load order: Data, Library, AQArmor, ArmorSets, Npcs, Quests, Dependencies, Core, ItemTooltips, Materials. Interface 11509/16001; version remains 2.11.1. |
| tools/check.py / wowstub.lua | Lua 5.1 compilation, startup/reload scenarios, accidental-global allowlist, properly chained hooks and targeted regression suites for both clients. |
| .pkgmeta / release.yml | Packaging exclusions and tag-triggered CurseForge workflow. Include Cinzel Bold/OFL for hidden layout metrics; exclude other font studies and source/review/tool folders. |
| Media/artwork / final-images / goal runtime assets | Untouched source originals, approved masters, baked runtime textures; all synced. Verify installation via manifests, not by guessing from names. |
| CHANGELOG.md / ROADMAP.md / README files | Unreleased list, Materials in testing, current player-facing descriptions. Do not claim evening work is shipped. |
| reports / Screenshots | Review evidence, package/diagnostics logs, original image prompts and gallery crops. Some pictures/reports are historical, not current-state proof. |

## Open risks and next review

1. **Known SetItemRef taint:** Core.lua still assigns a wrapper to the Blizzard
   global. The copy-player-name blocked-action issue is still recorded in
   AGENTS.md; no safe-hook replacement was implemented in these four days.
   Check native behavior and fix the routing safely rather than assuming the
   accidental-global allowlist or a published ZIP proves this issue resolved.
2. **Materials native review:** latest fades/bar removal, local filters, small
   sizes, scroll bounds, open-state behavior, repeated toggles/mid-animation
   interruptions, large expanded Tier 3/AQ recipes, bank/alt snapshots, unknown
   Forever item data and actual CPU cost of intermediate reflow.
3. **Forever prerequisites:** only add individual edges after positive source/
   gameplay evidence. Keep unverified siblings open; false API responses alone
   do not justify enabling the Classic graph on Forever.
4. **Documentation/screenshot release consistency:** refresh gallery/description
   for new Materials/fonts only when preparing an authorized release. Existing
   CurseForge author-console images/text were not automatically updated.
5. **Portable tools:** Mac release diagnostic config has Mac-specific paths.
   PC must locate/install LuaLS plus Ketho and verify annotation loading anew.
   Bundled PC Python exists even though older docs say no Python on the PC.

## Verification and release workflow

Use AGENTS.md's required gate. On PC the working checker command is:

```powershell
& 'C:/Users/kneis/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -c 'import sys,runpy; sys.path.insert(0,"C:/Users/kneis/AppData/Local/Temp/fgt-lua-check"); from lupa import lua51; runpy.run_path("tools/check.py",run_name="__main__")'
```

The lupa path is machine-local; if unavailable, complete dependency setup.
The stub compiles/executes real Lua 5.1 but does not render or measure native
frame time. Assertions intentionally exercise missing APIs, progress migration,
scopes, repeated loads, animation lifecycle, typography and narrow layout.
Ketho/LuaLS is a separate required pre-release API/global diagnostic gate.
Retain annotation-loading evidence, review client paths/exceptions and fix
actionable errors. Installing the extension alone is not a diagnostic pass.

When Karl authorizes an update after review: choose the version then, update
TOC/changelog/README/roadmap/descriptions/screenshots as applicable, run all
required checks, verify packaging and excluded originals, then follow the
tag-triggered release workflow. Verify workflow and public ZIP afterward.
His end-of-night commit request and possible update discussion were not release
approval. Source commits and artwork sync may proceed without a release tag.

## Cross-machine and communication continuity

- PC is the live AddOns checkout; Mac project is linked into the beta AddOns
  directory. Pull main before editing; ask if that checkout is dirty.
- Commit and push at closeout. Audit artwork recursively, including ignored
  originals, before saying syncing is complete. Do not discard/delete originals.
- SavedVariables/progress are local to each machine. Do not touch the older
  Classic Era KarlClassicGoals copy or its saved-variable backup.
- Existing Lua changes need `/reload`; new/replaced cached textures/fonts need
  a full game restart. New load-order/module changes were reviewed after restart.
- Keep descriptions concise, latest three releases with full-history links.
  AGENTS.md records the exact bottom AI disclaimer; copy it exactly rather than
  paraphrasing. Description author-console paste remains Karl's action unless
  he explicitly asks for it to be performed.
- This morning's task is context/sync only. No new addon feature or release was
  requested. Claude should continue with Karl's next review/implementation ask.
