# Publishing, descriptions and gallery

Load only for authorized release preparation, store copy or gallery work. A
request to edit, commit, sync artwork or prepare notes does not authorize a release.
Pushing a `v*` tag triggers `.github/workflows/release.yml` and CurseForge upload.

## Release checklist

1. Establish the exact candidate and Karl's release authorization. Resolve any
   outstanding functional/native review. Keep candidate-specific evidence; old
   passes do not validate changed code.
2. Run `tools/check.py` with real Lua 5.1 for Era/Forever. Run Ketho WoW API plus
   LuaLS diagnostics; prove packaged annotations actually loaded, retain results,
   review compatibility and accidental globals, fix actionable diagnostics and
   document verified client exceptions. Never suppress broadly. Missing setup or
   results blocks publication. PC runner: `sh tools/run-luals.sh`; setup details
   are in the compatibility reference if needed.
3. Review performance-sensitive paths and applicable native behavior with Karl.
   Offline benchmarks and annotations do not measure native CPU/rendering. State
   coverage honestly; do not claim human approval from automated results.
4. Update TOC version, CHANGELOG release entry and `FGT.WHATS_NEW` consistently.
   Keep release notes short and player-facing: major new features plus grouped
   UI improvements/bug fixes. Keep detailed development history in dated reports
   and Git, not the always-on instructions. Update ROADMAP's shipped items and
   relevant README/store copy.
5. Review gallery and description every release and report even "nothing to update".
   Identify stale shots from actual changed UI; do not retake everything for an
   unrelated patch. Use current `FGT.SHOTS`/demo scenes and gallery reports, not the
   archived numbered shot map. Add a demo scene before a new automated shot.
6. Inspect package version, TOC load order, expected runtime assets, integrity,
   exclusions and licenses. `.pkgmeta` excludes tools, reports, source artwork and
   review masters. Retain Cinzel Bold/OFL for hidden metrics; exclude font studies.
7. Commit/push the intended release when authorized, then create/push the approved
   version tag. Verify the workflow and resulting public ZIP. Distinguish workflow
   success, GitHub release availability and CurseForge processing/public availability.
   Confirm on CurseForge before calling it live there.

## Screenshots and external updates

`/goals shots` stages current demo scenes, captures and restores demo/photo state;
`tools/shots.py` crops the requested burst from the game's Screenshots directory.
Hover shots can need manual capture. Use `/goals demo off` and ensure real progress
is restored. Lua needs `/reload`; new assets need full restart. Verify updated
version text on Settings shots. Plan live-client retakes at launch, not in every task.

CurseForge project: 1728528, Forever Goal Tracker. Description/gallery edits are
external actions only when Karl asks. The author console is
`https://authors.curseforge.com/#/projects/1728528/description` (media: `/media`).
Check the file input carefully: gallery upload differs from release-file upload.
The public page can lag 30-60+ minutes; do not resave just because it is cached.
Preparing Markdown does not mean the author console was updated.

## Description policy

Use concise feature bullets, latest three releases and links to the full changelog
and roadmap. When Karl requests Markdown, supply a copyable raw Markdown block.
Do not restore the old "Made with the help of AI" sentence. End addon descriptions
with this exact block after all other content:

***

**AI Disclaimer**: Claude Code and ChatGPT Codex are tools to help build this addon. The idea, UI/UX, design, image sourcing, in-game testing, and final quality checks are mine. AI agents help with coding, updates, cross-checking in-game data, automation like screenshot capture, and first drafts of copy. Some artwork and UI assets are also generated or edited with AI, and tools with AI features. I review and test the work, make the final decisions, and take responsibility for what gets pushed.

The old README.txt disclosure mismatch is recorded in CURRENT for a later scoped
copy update. Do not treat that older text as a competing policy.
