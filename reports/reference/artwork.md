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
