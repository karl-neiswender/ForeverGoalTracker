# Artwork and asset workflow

Load for source artwork, banner editing, runtime assets, attribution or an agreed
artwork sync. No asset generation, installation or whole-tree validation is implied
by opening this reference.

- Preserve original files unchanged in `Media/artwork`, including pending or
  rejected candidates. Approved masters live in `Media/final-images`; runtime
  assets and mappings are separate. Approval to sync originals is not approval to
  install a banner. Never silently commit deletions or discard local originals.
- For banner work, load the project's
  [banner skill](../../.agents/skills/forever-goal-tracker-banners/SKILL.md).
  Follow approved grayscale framing and baked left/bottom gradients. Preserve
  source attribution and licenses, even if an approved derivative omits a visible
  signature. Never invent artist credits or infer approval from a filename.
- Inspect the affected source/master/runtime manifests and goal mapping. Validate
  dimensions, alpha, aspect, format and in-game appearance for changed assets only.
  Native caching requires a full game restart for new/replaced textures or fonts.
- UI icons (buttons and toggles, loaded by `FGT.Icon("<name>")` from `Media/icons`), checked
  2026-10-24. Three files per icon:
  1. Untouched generated original: `Media/artwork/ui-icons/<name>-generated-original.png`.
  2. Runtime texture: `python3 tools/icon.py <original> <name> 64x64 Media/icons` (`python` on
     the PC, Pillow in `tools/.py`) writes `Media/icons/<name>.tga` (64 x 64, 32-bit RGBA)
     and keeps `Media/icons/<name>-source.png` (left out of the zip by `.pkgmeta`).
  3. Record the icon in a short report under `reports/` (see
     `reports/map-location-icon-2026-10-15.md`).
  Tintable icons are white or light grey on transparent, end in `-white` and take their color
  in code (`SetVertexColor`); match `Media/icons/sheet-white-source.webp`. Gold icons skip
  `-white` and go through `tools/gold.py`.
  Example (2026-10-24): `eye-white` and `eye-off-white`, the Gear Planner's helm and cloak
  toggles (`reports/eye-icons-2026-10-24.md`).
- Gold icon processing uses `tools/gold.py` after sheet slicing or interest-art
  conversion; the white/grey tintable set needs no gold processing. Retain originals
  and license files. Packaging excludes originals/review material via `.pkgmeta`.
- At a relevant agreed editing closeout or machine switch, perform one recursive
  inventory of artwork including ignored originals. Sync additions/updates even
  when not approved for installation. Confirm ignore coverage, committed files
  and remote containment before reporting synced. Reinspect only changed assets;
  routine read-only and documentation handbacks do not initiate an artwork sweep.

Historical treatments, rejected variants, prompts, exact prior approvals and
technical experiments remain in the archived instructions and existing reports.
Load the relevant record when resolving a mapping or regression, not every session.

## Goal art checklist (maintained table)

[Goal-art-checklist.html](../Goal-art-checklist.html) lists every goal's banner by faction
and class, with squares for Needed, Borrowed, Shared and Done, and a hover or click
preview of the installed image. Open it in a browser (it works offline). A private
copy is published as a Claude artifact and pinned in Karl's sidebar:
https://claude.ai/artifact/3K3FJyrdc3NHb3v7dfJciM. The file in the repo is the source;
the artifact is a copy that only changes when it is republished.

Keep it current whenever artwork or goals change (artwork closeout, a new banner, a new goal):

1. Statuses: edit the rows in the page's `<script>`. Class grid rows are `TABLES`, the full
   goal list is `GOALS`. A row is `[name, Alliance, Horde, note]` with `need`, `borrow`,
   `share`, `done` or `na`. Put a goal's banner file names (without `-banner.blp`) in the note;
   the page links them and builds the faction previews from them. Class grid previews come
   from `CLASSIMG`. Update the header date and the "Find these first" list.
2. Found log: add a dated line to `FOUND` for each image added or approved.
3. New goals: run `python3 tools/art-checklist.py goals`. It loads the addon and lists goals
   that have no row. Add a row (usually `GOALS`, under the matching category) and, for class
   and faction art, the class grid. A renamed goal shows up here too.
4. Thumbnails: run `python3 tools/art-checklist.py thumbs` after any banner changes. It rebuilds
   the embedded images from `Media/*-banner.blp`. A banner that has no file yet is reported.
5. Statuses must come from the resolver in `Core.lua` (`artPaths`, `artVariants`), not from
   file names alone. For a full re-audit use the
   [October 15 coverage audit](../image-tests/audit-banner-coverage-2026-10-15.py).
6. Republish the artifact copy when Karl wants it refreshed. It is the same page with the
   document, head and body tags removed, a `data-theme="dark"` palette block and side padding
   added (see the Artifact tool's page contract).
7. Do not install, rename or delete banners as a side effect of editing the checklist.

Source of the first data: the [October 15 coverage report](../banner-image-gaps-2026-10-15.md),
with the Say LOL, Beastmaster and Dreadnaught's fixes and Teebu's Blazing Longsword applied
on 2026-10-25.
