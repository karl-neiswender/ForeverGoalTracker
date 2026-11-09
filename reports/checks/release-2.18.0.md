# Release 2.18.0 (2026-11-09, PC, Claude)

Karl authorized publishing in chat on 2026-11-09 ("Yes, publish").

- Candidate: `main` at the 2.18.0 release commit (TOC 2.18.0, CHANGELOG, `FGT.WHATS_NEW`, ROADMAP).
  Contents since `v2.17.1`: Goal Library preview, four Forever item sets, three Forever dungeon map links, newer
  Wowhead planner links.
- Not in the candidate: Codex's uncommitted Core.lua edits that hide realm names on Forever, GearSources.lua, the eye
  icon files. The diagnostics below ran on the working tree, which still had those edits; `tools/check.py` was
  rerun on a clean export of the release commit before tagging.
- `python tools/check.py`: exit 0, 126 sessions.
- Ketho WoW API + LuaLS (`sh tools/run-luals.sh`): no problems found, annotations loaded (14,028 events).
- `tools/copycheck.py`: every rule 0 found.
- Package: `LibraryPreview.lua` is in the TOC, `Media/icons/preview-plus-white.tga` is tracked, no Lua references the
  untracked eye icon. `.pkgmeta` excludes the `-source` icon copies and `Media/artwork`. The ZIP itself is built only by
  the tag workflow, so it is not inspected yet.
- Native, live Forever (Karl): drawer fade, open-drawer tooltip, blank cards gone. Not checked in game: the four new
  item sets and three map links (from player guides), and Classic Era with the preview.
- Performance: `LayoutLibrary` now hides fewer cards and the drawer animates only during its slide; no native CPU
  measurement was taken.
- Gallery: no shot shows the preview, so it is a candidate for a new shot; the 2.17.0 draft's stale Settings version
  note still applies. Description: its latest releases list needs 2.18.0. Neither has been updated.
