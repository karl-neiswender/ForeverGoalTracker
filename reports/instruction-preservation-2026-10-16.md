# Instruction preservation and conflict record

Date: 2026-10-16. Scope: documentation only. Authority: Karl approved the proposed
restructuring with explicit task-based workflow rules and no commit/push approval.
This is an audit reference, not mandatory session reading.

## Preservation method

The complete previous AGENTS.md, CLAUDE.md and October 12 handoff were copied
byte-for-byte into `archive/instructions-2026-10-16`. Its manifest records original
paths, lengths and SHA-256 hashes. The original dated handoff also remains in place,
with a historical notice added. Other historical reports are unchanged. Unique
decisions, technical findings, rejected experiments and approval evidence remain
recoverable even when they are no longer active instructions.

## Rule-by-rule map

All destinations under `reference/` are task-triggered. Essential safeguards also
remain in the root rulebook. This checklist distinguishes preserved rules from
workflow changes explicitly authorized by Karl.

| Safeguard / prior location | Active destination | Result |
|---|---|---|
| Era/Forever interfaces and API wrappers; hard-won lesson 00 | AGENTS Compatibility; compatibility-testing | Preserved |
| Lua 5.1 200-local limit; helpers before use; multi-return lesson | AGENTS Compatibility; compatibility-testing | Preserved |
| No logout statistics/friends reads; engine asserts not caught by pcall | AGENTS Compatibility; compatibility-testing | Preserved |
| DB unavailable before ADDON_LOADED | AGENTS Progress; compatibility-testing | Preserved |
| Never replace SetItemRef; secure chat routing | AGENTS Compatibility; compatibility-testing | Preserved, stale open-bug claim retired |
| Unknown reputation is not known Neutral; KnownFactions | data-progress | Preserved |
| Never automatically untick earned steps | AGENTS Progress; data-progress | Preserved |
| Stable IDs, positional steps/parts, one-time migrations, sparse saves | AGENTS Progress; data-progress | Preserved |
| No migration for wording alone | AGENTS Progress; data-progress | Preserved |
| PieceProgress avoids double-counting materials/pieces | AGENTS Progress; data-progress | Preserved |
| Shared roster, scoped rules, reward completion, dates/undo | data-progress | Preserved |
| Forever graph disabled until individual verification; preview not proof | AGENTS Compatibility; data-progress; CURRENT | Preserved |
| Local SavedVariables; old backup and separate Era installation safety | AGENTS Progress; git-machines | Preserved |
| Demo state restoration; avoid corrupting player progress | AGENTS Progress; compatibility-testing; publishing | Preserved |
| Live checkout /reload versus cached-asset restart | AGENTS Progress; git-machines; artwork | Preserved |
| Shared main and platform paths; intended hunks and identity | git-machines | Preserved |
| Pull on every session, sync on every handback | AGENTS Triggers; git-machines | Replaced by approved task/closeout triggers |
| Status at editing start; dirty-tree pull requires consultation | AGENTS Triggers; git-machines | Preserved, no repeated unchanged checks |
| Recursive artwork inventory including ignored originals | AGENTS Triggers; artwork; git-machines | Once per relevant agreed closeout, not read-only tasks |
| Preserve/sync pending originals; installation needs separate approval | AGENTS Triggers; artwork | Preserved |
| No silent artwork deletions; verify committed additions and remote | AGENTS Triggers; git-machines; artwork | Preserved |
| Source attribution, licenses, manifests, grayscale banner treatment | artwork; existing banner skill | Preserved |
| Gold processing versus tintable white icons | artwork | Preserved |
| Native fonts; Cinzel hidden metrics only; no Modern revival | AGENTS UI; ui-performance | Preserved |
| Shared palette/widgets; detailParts; reused row reset | AGENTS UI; ui-performance | Preserved |
| Custom main-window movement; bounds; minimap radius | ui-performance | Preserved |
| Gradient alpha handling; hot path allocations; stop idle work | AGENTS Performance; ui-performance | Preserved |
| Grime on surfaces; quiet styling; practical tooltip hints | AGENTS UI; ui-performance | Preserved |
| NEW/UPDATED semantics and client/faction filters | AGENTS UI; data-progress; ui-performance | Preserved |
| Per-goal Materials; no mutation of progress | ui-performance; CURRENT | Preserved; stale settings retired |
| Action steps, practical tips, exact tags/names/parser strings | AGENTS UI; data-progress | Preserved |
| Unconfirmed / Source unknown / automatic wording | AGENTS UI; data-progress | Preserved |
| Item tip tags, real goal links, aliases, display-time periods | data-progress | Preserved |
| Item qualities and PvP title lessons | data-progress | Preserved |
| Verify data, do not infer Forever from Classic | AGENTS Compatibility; data-progress | Preserved |
| No automated Wowhead access pending permission | data-progress; existing audit README | Preserved; old scraper workflow retired |
| Measure unseen glitches; stop after two failed guesses | AGENTS Scope; compatibility-testing; ui-performance | Preserved |
| Karl's concise communication and no em dashes | AGENTS Scope | Preserved |
| Real Lua checks, both clients, stub limits, accidental globals | compatibility-testing; AGENTS Triggers | Preserved; docs-only exemption explicit |
| Ketho/LuaLS, loaded annotations, retained results, exceptions | AGENTS Triggers; compatibility-testing; publishing | Preserved |
| Missing gate blocks publishing; commits are not releases | AGENTS Triggers; publishing | Preserved |
| Native testing/performance not replaced by annotations or stub | AGENTS Compatibility; compatibility-testing; publishing | Preserved |
| Explicit release approval; tags trigger CurseForge | AGENTS Triggers; publishing | Preserved |
| TOC, changelog, WhatsNew, roadmap, package exclusions/license | publishing | Preserved |
| Store check each release; gallery review; workflow/ZIP verification | publishing | Preserved |
| Author-console authorization, caching and correct upload input | publishing | Preserved |
| Concise description/latest three releases/exact final disclaimer | publishing | Preserved; obsolete sentence retired |
| Dates, old screenshots, feature experiments, detailed file map | Exact archives and existing dated reports | Preserved as history, not routine reading |

## Evidence-based conflicts

| Conflict | Evidence inspected | Decision / remaining limit |
|---|---|---|
| 2.11.1 versus 2.15.0 versus later main | TOC, CHANGELOG, local tag at 98ce414, HEAD 7e0bec2 and post-tag log | Local version/tag 2.15.0; HEAD has unreleased work. Remote/public state not independently checked |
| SetItemRef still replaced versus fixed | Core.lua EventRegistry callback and hooksecurefunc block; old hard-won lesson 15 records native confirmation | Replacement is fixed in source; no fresh native test claimed |
| Fonts / Modern selector | Core.lua FONT FRIZQT and hidden Cinzel footprint; .pkgmeta | Native visible font; hidden Cinzel retained; no revived font feature |
| Materials option names/defaults | Materials.lua defaults/menu keys and rendering | showDone=false, bars=true, alts=true; old collected/count-toggle defaults retired |
| Forever gate rollout | Dependencies.lua empty FOREVER_DEPENDENCIES and preview branch | Remains unverified/default-disabled; no inferred eligibility |
| Required automated Wowhead fetching versus no scraping | reports/audit/README.md explicitly records access restriction and native/manual alternative | No automated site access pending permission; historical advice is not authority |
| Old AI sentence versus final disclaimer | Explicit AGENTS description policy corroborated by README.md and 2.15.0 draft | Final disclaimer is policy; README.txt mismatch remains untouched for later work |
| No PC tools / stale Mac-only checks | tools/run-luals.sh and dated October 15 report with annotation-load evidence | PC runner documented; historical pass does not validate later HEAD |
| Different package file counts/sizes | October 15 report describes simulated candidate package; archived CLAUDE describes final ZIP | Do not merge candidate and published evidence or repeat either as fresh verification |
| Gallery not retaken / old Settings version | reports/CurseForge-gallery-2.15.0.md records processed crops and visual review | Settings is 2.15.0; map-view retake and stale Materials artwork remain; no upload claim |
| Old Era replacement approval versus leave old install alone | Historical one-time task versus current explicit safety instructions | No standing permission to modify another install or backup |
| Blanket pull/audit/commit rules | Karl's 2026-10-16 restructuring request | Task triggers and explicit/agreed sync override old session mandates |
| Wildcard Git trust workaround | Current Git commands succeed without override | No wildcard trust by default; resolve only an actual ownership error narrowly |

No conflict was resolved by date alone. Source establishes implementation, not
human approval or external publication. Unverified external state and native
behavior remain explicitly limited in CURRENT. No unrelated source fix is implied.

## Reading graph and acceptance checks

Active reading requirements form a one-way graph: CLAUDE -> AGENTS -> CURRENT
(only for relevant work) and selected topic references. CURRENT has no mandatory
back-reference. Topic references do not demand rereading entry points or loading
every topic. Data research and banner work may load their specific existing
workflow/skill only when applicable. Archive links are optional historical lookup.

- Read-only question: relevant read only; no status/pull/audit/checks required.
- Documentation edit: one editing-start status and targeted document validation;
  no automatic artwork inventory, Lua suite, commit or push.
- Small Lua edit: final relevant suite plus focused tests; no auto-sync.
- Artwork change: affected-asset validation; one inventory at agreed sync closeout.
- Machine switch/agreed closeout: inventory and verified main synchronization.
- API change: compatibility diagnostics plus affected native review.
- Release: authorization and complete gates, package/store/publication review.

Final verification checks archive hashes, local links in active documents, intended
document-only changes and the rule matrix. Historical snapshots intentionally keep
original links and contradictions; their archive index explains original link bases.

### Completed verification

- PASS: all three snapshot SHA-256 hashes match the pre-edit manifest.
- PASS: the existing October 12 handoff retains its entire original body after
  the new historical notice. No other dated evidence report was edited.
- PASS: all relative Markdown links in the new active documents resolve.
- PASS: manual reading-trigger review found no mandatory cycle. Archive entry
  filenames use `.snapshot.md` to avoid automatic instruction-file discovery.
- PASS: the preservation matrix retains every identified critical safeguard;
  routine task scenarios above respect Karl's revised operation triggers.
- PASS: `git diff --check`; tracked edits are only AGENTS.md, CLAUDE.md and the
  historical handoff notice. New files are the handoff, references and archive/audit
  records. No Lua, artwork, release metadata or SavedVariables were changed.
- Sizes: AGENTS 7,117 bytes; CLAUDE 650 bytes; CURRENT 2,973 bytes. Combined entry
  documents are 10,740 bytes versus 352,647 bytes previously, a 97.0% reduction
  when all three are needed. References are loaded only for their task.
- Not run: Lua suite, LuaLS, native tests, artwork inventory, network release
  verification or sync. These are unrelated to this documentation-only handback.
- No pull was needed for this local evidence-based restructuring; the starting
  tree was clean. No commit, push, release tag or publication was performed.
