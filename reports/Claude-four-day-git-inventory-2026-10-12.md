# Four-day Git inventory: October 8–11, 2026

Source snapshot: 059d7478dd65c44e3c93d6243742c35a5456c968
Baseline immediately before the interval: 0f0e7073c2ce7c2a584825bae069815cbd2ab4fb
Commits in the Eastern-time interval: 385

This is an exhaustive commit-title and changed-path index. Read Claude-context-2026-10-12.md for current behavior and superseded decisions. Original assets, historical previews and code changes are all included; a preview commit alone does not establish approval or installation.

## Commits, oldest first

    19f94e4 | 2026-10-08T00:00:24-04:00 | Edge gradients: top matches the bottom (28px, eased); steps list reaches the panel's inner edge
    e877264 | 2026-10-08T00:02:40-04:00 | Top edge gradient starts with a 6px solid lip so clipped rows never show a hard cut
    a9bbe19 | 2026-10-08T00:04:13-04:00 | Top edge gradient: no solid lip; taller (40px) and gentler so rows with a progress bar fade as a whole
    9e349bc | 2026-10-08T00:12:31-04:00 | Links are painted the moment text is set (no flash of the final color before the fade); item fades run every frame
    141cf83 | 2026-10-08T00:14:27-04:00 | Release 2.9.0
    8ed100f | 2026-10-08T00:15:14-04:00 | CLAUDE.md: 2.9.0 shipped
    7e9ae33 | 2026-10-08T00:16:53-04:00 | Changelog: 2.9.0 kept short
    82ee0fd | 2026-10-08T00:17:43-04:00 | CLAUDE.md: polish releases get generic changelog lines
    3d9158f | 2026-10-08T00:22:47-04:00 | Screenshots retaken for 2.9 (automatic); shots.py crops to the window block only; /goals shots hides tooltips before each shot
    9dee376 | 2026-10-08T00:24:24-04:00 | Gallery screenshots for 2.9.0, clean run
    d52e384 | 2026-10-08T00:31:49-04:00 | CLAUDE.md: next session topics (fonts, scroll bar)
    3e284a9 | 2026-10-08T00:33:49-04:00 | Goal list: softer bottom fade (36px, 75%, gentler) so bright cards don't show a dark band
    2f8990e | 2026-10-08T00:34:28-04:00 | CLAUDE.md: next session also covers the Library filter bar
    6bdec98 | 2026-10-08T00:35:34-04:00 | CLAUDE.md: filter bar goal (simple, no icons)
    e500cd7 | 2026-10-08T00:40:11-04:00 | CLAUDE.md: taint bug (SetItemRef replacement blocks Copy Character Name) first on next session's list
    0306879 | 2026-10-08T00:49:53-04:00 | CLAUDE.md: ctrl-click to preview gear (next session)
    3ba2542 | 2026-10-08T00:50:58-04:00 | CLAUDE.md: Wowhead Forever community findings as a data source
    a71a957 | 2026-10-08T08:13:40-04:00 | CLAUDE.md: appearance settings ideas
    a037856 | 2026-10-08T08:19:58-04:00 | CLAUDE.md: progress style applies everywhere
    f013067 | 2026-10-08T08:21:57-04:00 | CLAUDE.md: progress style decisions (no cap, flex, numbers-only)
    c121716 | 2026-10-08T08:24:29-04:00 | CLAUDE.md: first Appearance group agreed
    673fd51 | 2026-10-08T08:27:02-04:00 | CLAUDE.md: Classic / Modern font style
    1b093a3 | 2026-10-08T08:28:28-04:00 | CLAUDE.md: Modern font candidates
    454b3aa | 2026-10-08T08:29:46-04:00 | CLAUDE.md: Marcellus for Modern headings
    efb490b | 2026-10-08T08:31:18-04:00 | CLAUDE.md: same text footprint for both font styles
    2e0f041 | 2026-10-08T09:59:15-04:00 | Document post-update welcome and feature tour idea
    0e65225 | 2026-10-08T10:14:15-04:00 | Replace goal reset icon and show undo countdown
    2e72c5e | 2026-10-08T10:19:55-04:00 | Animate restored goal progress when undoing reset
    dc3489d | 2026-10-08T10:27:50-04:00 | Record personal notes layout and icon ideas
    216c220 | 2026-10-08T10:31:36-04:00 | Add painted personal note icon assets
    e89c457 | 2026-10-08T10:38:15-04:00 | Add personal notes to goal pages
    b5ee10c | 2026-10-08T10:58:07-04:00 | Refine personal note editor controls and backdrop
    c84ed40 | 2026-10-08T11:08:01-04:00 | Animate note modal and grey its backdrop
    8e54558 | 2026-10-08T11:12:34-04:00 | Add a wider darker shadow to the note window
    1098011 | 2026-10-08T11:16:46-04:00 | Disable empty note saves and update editor title
    994c9a9 | 2026-10-08T11:27:15-04:00 | Show live note character count and brighten goal subtitle
    4babe7b | 2026-10-08T11:31:38-04:00 | Match note icon hover to standard icon buttons
    d9e0382 | 2026-10-08T11:55:48-04:00 | Record step dependency animation and prerequisite design
    3723e73 | 2026-10-08T12:14:59-04:00 | Audit prerequisites across all 79 goals
    a4814fa | 2026-10-08T12:16:26-04:00 | Normalize dependency research file formatting
    b1f9915 | 2026-10-08T12:50:04-04:00 | Document Classic Era installation for native UI testing
    a1504fa | 2026-10-08T12:55:02-04:00 | Limit personal note editing to the note icon
    d24418b | 2026-10-08T13:04:09-04:00 | Add Classic step prerequisite locks and unlock motion
    2f75410 | 2026-10-08T13:24:54-04:00 | Use silver step locks and breakaway pieces
    a999629 | 2026-10-08T13:27:00-04:00 | Record approval of silver dependency locks
    0f87030 | 2026-10-08T13:37:57-04:00 | Redesign goal banners from the supplied Figma layout
    684ce28 | 2026-10-08T13:45:38-04:00 | Expand goal banners and correct legendary artwork
    3a9ab5f | 2026-10-08T13:45:56-04:00 | Preserve repository text line endings
    4ea9e8d | 2026-10-08T13:49:32-04:00 | Place goal counter above banner progress bar
    e2b50ad | 2026-10-08T13:52:02-04:00 | Refine banner counter and bottom border
    c13b0a7 | 2026-10-08T13:54:44-04:00 | Match banner bevel and strengthen empty progress track
    1573553 | 2026-10-08T13:57:05-04:00 | Restore visible banner border and progress container
    ec4fe30 | 2026-10-08T13:59:55-04:00 | Blend goal banner artwork into panel gradient
    e987538 | 2026-10-08T14:05:31-04:00 | Compress uploaded artwork and desaturate banners natively
    cb37568 | 2026-10-08T14:08:45-04:00 | Assign remaining uploaded artwork to goal banners
    a1a0dd0 | 2026-10-08T14:16:46-04:00 | Fade artwork left edge and extend below goal progress
    728fbf5 | 2026-10-08T14:19:05-04:00 | Extend banner into guide and tighten heading spacing
    215fd53 | 2026-10-08T14:20:48-04:00 | Record approval of goal banner redesign
    f5c7c9b | 2026-10-08T17:27:49-04:00 | Document complete goal banner shot list
    a17f6a5 | 2026-10-08T17:35:22-04:00 | Add six approved weapon raid and mount banners
    ea04dbf | 2026-10-08T17:46:43-04:00 | Add transparent artwork credits to Settings
    3789d18 | 2026-10-08T17:54:10-04:00 | Separate approved banner masters from artwork options
    ba6c1de | 2026-10-08T17:59:42-04:00 | Save monochrome weapon banner imagegen pass for review
    ba16b92 | 2026-10-08T18:02:26-04:00 | Install approved monochrome banner textures without redundant desaturation
    45a55e2 | 2026-10-08T18:29:25-04:00 | Save Molten Core monochrome banner imagegen previews
    4edba2a | 2026-10-08T21:48:58-04:00 | Install approved Molten Core banner artwork
    bfb9fba | 2026-10-08T21:51:55-04:00 | Fade goal images on their first visible opening
    6113621 | 2026-10-08T21:53:10-04:00 | Keep goal icon instant during background image fade
    04766a1 | 2026-10-08T21:58:21-04:00 | Check addon compatibility with Forever build 70291
    3e51433 | 2026-10-08T22:05:26-04:00 | Refine goal artwork scale clipping and background fade
    a12dc77 | 2026-10-08T22:07:55-04:00 | Restore visible banner layer and crop within panel bounds
    386fcea | 2026-10-08T22:13:18-04:00 | Soften banner image reveal and transparent bottom blend
    c49e62c | 2026-10-08T22:16:33-04:00 | Show banner fade driver when loading saved goals
    7c240fc | 2026-10-08T22:20:48-04:00 | Add subtle top and right goal panel inner shadows
    0866aef | 2026-10-08T22:23:55-04:00 | Record reviewed additional banner artwork candidates
    4a3490c | 2026-10-08T22:33:04-04:00 | Save five additional monochrome banner treatments for review
    6e7de65 | 2026-10-08T22:37:07-04:00 | Install approved banners and extend their bottom blend
    1c5a3ce | 2026-10-08T22:50:19-04:00 | Save 1200x900 banner assets with baked bottom fades
    f05e992 | 2026-10-08T22:52:53-04:00 | Connect Rhokdelar bowstring to the lower limb
    4e284d3 | 2026-10-08T22:59:56-04:00 | Withdraw Rhokdelar banner artwork pending replacement
    9c7807d | 2026-10-08T23:02:15-04:00 | Install fifteen approved taller banner assets
    2afb322 | 2026-10-08T23:08:33-04:00 | Install approved night elf hunter banner for Rhokdelar
    24d4e9a | 2026-10-08T23:10:33-04:00 | Refresh goal banner audit after approved image installations
    e3a3c80 | 2026-10-08T23:17:16-04:00 | Record identified tier armor artwork candidates
    1525cc2 | 2026-10-08T23:25:25-04:00 | Save approved rogue tier banner masters for later use
    2dd57c9 | 2026-10-08T23:31:24-04:00 | Save approved hunter tier banner masters for later use
    c724697 | 2026-10-08T23:31:48-04:00 | Normalize hunter export script line endings
    09a694d | 2026-10-09T00:36:29-04:00 | Install approved monochrome Slay Onyxia banner
    d54a542 | 2026-10-09T01:02:57-04:00 | Track individual armor sets as independent goals
    7357f9e | 2026-10-09T01:16:03-04:00 | Install Mage tier banners and simplify armor goal labels
    7dd1fea | 2026-10-09T01:19:00-04:00 | Use title case for compact armor set names
    5848e8c | 2026-10-09T01:26:46-04:00 | Keep short-window goal content inside a scroll viewport
    22b6a83 | 2026-10-09T01:29:35-04:00 | Use class colors on armor goal class labels
    59be3e5 | 2026-10-09T01:36:42-04:00 | Release 2.10.0
    00d472f | 2026-10-09T01:41:25-04:00 | Record successful CurseForge 2.10.0 upload
    d358381 | 2026-10-09T01:46:42-04:00 | Record Forever prerequisite locks as next session follow-up
    5434810 | 2026-10-09T01:49:39-04:00 | Refresh gallery screenshots with approved banner UI
    96b0f93 | 2026-10-09T10:29:41-04:00 | Prepare Hyjal and Barrow Deeps banner reviews
    83365de | 2026-10-09T10:34:41-04:00 | Add per-goal banner opacity tuning
    5cb38b1 | 2026-10-09T10:41:44-04:00 | Prepare Charger and Dreadsteed banner reviews
    cb1e75a | 2026-10-09T10:44:12-04:00 | Move Dreadsteed artist attribution to Settings
    519b460 | 2026-10-09T10:46:03-04:00 | Install approved Dreadsteed banner and simplify artist credit
    72a2e1f | 2026-10-09T10:49:22-04:00 | Prepare Warrior Tier 1 and Tier 2 banner reviews
    505e74e | 2026-10-09T10:50:37-04:00 | Install approved Warrior Tier 1 and Tier 2 banners
    8959129 | 2026-10-09T10:55:07-04:00 | Prepare Druid Tier 1, 2 and 3 banner reviews
    1555ec7 | 2026-10-09T11:01:09-04:00 | Repair missing staff curve in Druid Tier 2 banner review
    940e572 | 2026-10-09T11:02:31-04:00 | Install approved Druid Tier 2 banner with repaired staff
    c86e208 | 2026-10-09T11:48:08-04:00 | Choose Warrior Tier 2 banner by logged-in faction
    c8b9e9d | 2026-10-09T11:54:14-04:00 | Install approved Shaman Tier 2 banner for both factions
    f020ae8 | 2026-10-09T12:20:03-04:00 | Install approved Warlock Tier 1 and Tier 2 banners
    276598b | 2026-10-09T12:22:22-04:00 | Prepare Warrior Tier 3 banner review
    6850df1 | 2026-10-09T12:24:36-04:00 | Install approved Warrior Tier 3 banner
    aaa6bf9 | 2026-10-09T12:34:54-04:00 | Add Violet Sorcerer's Vestments Forever goal and banner review
    3a27102 | 2026-10-09T12:36:38-04:00 | Install approved Dalaran banner for Violet Sorcerer's Vestments
    40ea8bf | 2026-10-09T12:48:04-04:00 | Install Hyjal Summit and Barrow Deeps raid banners
    13b4075 | 2026-10-09T12:58:04-04:00 | Prepare Ahn'Qiraj C'Thun and Mage Tier 3 banner reviews
    1cd288a | 2026-10-09T13:04:17-04:00 | Install approved Mage Tier 3 banner
    7302450 | 2026-10-09T13:06:08-04:00 | Install approved Ahn'Qiraj and C'Thun banners
    0b6b917 | 2026-10-09T13:18:35-04:00 | Prepare Baron Rivendare Deathcharger banner review
    d33910c | 2026-10-09T13:19:42-04:00 | Install approved Deathcharger banner
    082ab8a | 2026-10-09T13:32:19-04:00 | Remove unapproved Tier 3 fallback and prepare Naxxramas review
    7266d0d | 2026-10-09T13:32:45-04:00 | Normalize handoff document line endings
    16ca6c8 | 2026-10-09T13:34:14-04:00 | Install approved floating Naxxramas Tier 3 and attunement banners
    94aa0e3 | 2026-10-09T13:46:46-04:00 | Install approved Druid Tier 1 and prepare selected Shaman Tier 1 review
    948c055 | 2026-10-09T13:48:44-04:00 | Install approved Druid Tier 3 and Shaman Tier 1 banners
    c7eddbe | 2026-10-09T14:21:58-04:00 | Sync remaining PC source artwork for Mac access
    cd3aa95 | 2026-10-09T14:27:15-04:00 | Document imagegen banner gradients in portable project skill
    26a8ffb | 2026-10-09T17:09:08-04:00 | Install approved goal banners and racial mount artwork
    37cfb6e | 2026-10-09T17:54:53-04:00 | Select leveling mount and PvP banners by logged-in character
    5ede26b | 2026-10-09T18:01:13-04:00 | Record complete banner artwork gap audit
    8cf2c37 | 2026-10-09T18:04:36-04:00 | Prepare Swift Mechanostrider banner review
    3c9a490 | 2026-10-09T18:05:43-04:00 | Install approved Gnome Swift Mechanostrider banner
    0dd2593 | 2026-10-09T19:07:47-04:00 | Prepare kneeling Night Elf Priest Tier 3 banner review
    f04384d | 2026-10-09T19:09:27-04:00 | Install approved Priest Tier 3 Alliance and default banner
    0735f5b | 2026-10-09T19:12:26-04:00 | Require artwork originals to be committed and synced each session
    a283932 | 2026-10-09T19:18:01-04:00 | Prepare mirrored dwarf Priest Tier 2 banner review
    ccde36c | 2026-10-09T19:20:11-04:00 | Focus Priest Tier 2 banner review on dwarf and armor
    6193e87 | 2026-10-09T19:21:46-04:00 | Install Priest Tier 2 banner and dwarf priest leveling variant
    b3a6fa7 | 2026-10-09T19:25:31-04:00 | Prepare Anduin Priest Tier 1 banner review
    0fe7dfa | 2026-10-09T19:29:24-04:00 | Match Benediction staff ornaments in Priest Tier 1 review
    a1ed14e | 2026-10-09T19:33:58-04:00 | Simplify circled Benediction finial in Priest Tier 1 review
    f2281fa | 2026-10-09T19:35:25-04:00 | Install approved Priest Tier 1 and human priest leveling banner
    a9cfccd | 2026-10-09T19:37:58-04:00 | Replace epic Dwarf ram banner with approved Swift Ram artwork
    52286d1 | 2026-10-09T19:42:40-04:00 | Install approved Alliance Felheart Warlock Tier 1 banner
    c516259 | 2026-10-09T19:54:18-04:00 | Install Troll Mage leveling banner and sync new artwork originals
    5f80bab | 2026-10-09T19:56:00-04:00 | Sync remaining new artwork, previews and session reports
    6542b13 | 2026-10-09T19:56:57-04:00 | Normalize saved check reports for cross-platform syncing
    b564378 | 2026-10-09T20:45:10-04:00 | Save four banner reviews and new artwork originals
    7e05928 | 2026-10-09T20:46:45-04:00 | Add painted Warcraft style undead paladin banner review
    0412c5e | 2026-10-09T20:49:45-04:00 | Install approved mount Dire Maul and undead paladin banners
    587ccb2 | 2026-10-09T20:51:35-04:00 | Save Drums of War shared PvP banner review
    ed4113d | 2026-10-09T20:52:49-04:00 | Install approved Drums of War PvP banner for kills and duels
    f5cbfc3 | 2026-10-09T20:54:32-04:00 | Save Alliance dwarf shaman leveling banner review
    89ce410 | 2026-10-09T20:56:37-04:00 | Install approved Alliance dwarf shaman leveling banner
    fc23e2c | 2026-10-09T21:04:17-04:00 | Save upscaled black Qiraji banner review and source art
    7b78a97 | 2026-10-09T21:05:01-04:00 | Install approved black Qiraji mount banner
    ed6c361 | 2026-10-09T21:10:29-04:00 | Save Timbermaw reputation banner review
    59a9ed7 | 2026-10-09T21:11:03-04:00 | Install approved Timbermaw reputation banner
    a6581f7 | 2026-10-09T21:20:26-04:00 | Save Warlord mail banner review and new source artwork
    3bc675a | 2026-10-09T21:22:01-04:00 | Remove lower-left mark from Warlord mail banner review
    0fc6ffa | 2026-10-09T21:22:40-04:00 | Install approved Horde Warlord mail set banner
    ea81511 | 2026-10-09T21:22:49-04:00 | Sync new Quel Serrar source artwork
    92658b6 | 2026-10-09T21:24:02-04:00 | Save gold savings banner review
    b868798 | 2026-10-09T21:26:20-04:00 | Remove lower-left watermark from gold banner review
    ecc1ba9 | 2026-10-09T21:26:58-04:00 | Install approved gold savings banner
    c603d4d | 2026-10-09T21:27:28-04:00 | Update banner validation for approved gold artwork
    50883ad | 2026-10-09T21:56:50-04:00 | Save seven class leveling set and PvP mount banner reviews
    16dbc95 | 2026-10-09T21:59:54-04:00 | Install seven approved class leveling set and PvP mount banners
    eace7aa | 2026-10-09T22:26:34-04:00 | Add Cryptstalker hunter banner review and artwork references
    f84c706 | 2026-10-09T22:28:59-04:00 | Remove extra lion fang from Cryptstalker banner review
    be71789 | 2026-10-09T22:30:58-04:00 | Remove small tree from hunter banner review
    6233938 | 2026-10-09T22:34:51-04:00 | Correct Cryptstalker shoulders to one spike each
    2ecf43f | 2026-10-09T22:37:00-04:00 | Deepen grayscale treatment for Cryptstalker banner
    34b26fe | 2026-10-09T22:39:54-04:00 | Match hunter banner to grayscale painted reference
    46578ca | 2026-10-09T22:44:06-04:00 | Restore Cryptstalker spike height and shoulder glow
    1436e98 | 2026-10-09T22:47:36-04:00 | Match Cryptstalker pads to left and right references
    add1f78 | 2026-10-09T22:51:14-04:00 | Install approved Cryptstalker Hunter Tier 3 banner
    383142f | 2026-10-09T22:53:34-04:00 | Use Cryptstalker artwork for Troll Hunter leveling
    c580066 | 2026-10-09T23:09:14-04:00 | Resolve PvP artwork by goal and label faction-only goals
    da0fac1 | 2026-10-09T23:17:26-04:00 | Set first-open window size and hide goal banner descriptions
    cfd1ed4 | 2026-10-09T23:24:15-04:00 | Tighten Forever alert spacing and fade its treatment
    eddfbc9 | 2026-10-09T23:33:48-04:00 | Place goal labels beneath title and space personal notes
    1fc0106 | 2026-10-09T23:40:47-04:00 | Fit banner artwork by height from top-right corner
    ac52bf2 | 2026-10-09T23:43:32-04:00 | Restore responsive banner artwork size with top-right cropping
    48299b2 | 2026-10-09T23:47:39-04:00 | Extend artwork below compact goal headers before fading
    665f31a | 2026-10-09T23:54:12-04:00 | Release 2.10.1
    bae9674 | 2026-10-10T00:10:44-04:00 | Refresh cropped gallery screenshots for 2.10.1
    9703d46 | 2026-10-10T00:12:04-04:00 | Preserve complete addon windows in gallery crops
    b8e637c | 2026-10-10T10:39:05-04:00 | Add completed step visibility toggle to goal guides
    0b84493 | 2026-10-10T10:48:07-04:00 | Animate completed guide steps before hiding them
    2000d0c | 2026-10-10T10:55:12-04:00 | Add etched faction card emblems and shorten PvP set labels
    96ae6b3 | 2026-10-10T11:02:08-04:00 | Replace card difficulty with goal context eyebrows
    0bcf510 | 2026-10-10T11:06:03-04:00 | Simplify goal cards to three lines and move status markers
    557e09c | 2026-10-10T11:07:53-04:00 | Replace card status labels with star when favorited
    88c5951 | 2026-10-10T11:11:32-04:00 | Match scrollbar colors to subtle etched borders
    ac602f4 | 2026-10-10T11:12:55-04:00 | Keep scrollbar width fixed on hover
    8d87246 | 2026-10-10T11:14:35-04:00 | Mirror reset icon and spin counterclockwise
    59ec99a | 2026-10-10T11:24:39-04:00 | Add Classic AQ40 Tier 2.5 armor goals
    ed0c48c | 2026-10-10T11:38:14-04:00 | Fix tween callbacks changing the animation loop
    b0d8a46 | 2026-10-10T11:42:18-04:00 | Use headpiece thumbnails for Tier 2.5 class goals
    2ece49b | 2026-10-10T11:47:51-04:00 | Prepare Skeram Cultist banner review for Tier 2.5
    2a80ac4 | 2026-10-10T11:49:55-04:00 | Restore missing leg in Tier 2.5 banner review
    f6c8046 | 2026-10-10T11:51:24-04:00 | Install approved Skeram banner for all Tier 2.5 sets
    d53932d | 2026-10-10T12:00:22-04:00 | Add fishing extravaganza goal and Booty Bay banner review
    14e60c5 | 2026-10-10T12:01:27-04:00 | Install approved Booty Bay fishing tournament banner
    b422b04 | 2026-10-10T12:17:23-04:00 | Add four AQ40 battle tank goals and Scarab Lord banner review
    d6a130b | 2026-10-10T12:18:24-04:00 | Install approved Scarab Lord banner for Black Qiraji
    11ba600 | 2026-10-10T12:34:07-04:00 | Add tracked item needs tooltips and dressing room previews
    da7b033 | 2026-10-10T12:39:46-04:00 | Document October 10 handoff and pending in-game review
    ae2cdf6 | 2026-10-10T15:05:00-04:00 | Save ancient book empty-state artwork concept
    6db682e | 2026-10-10T15:07:07-04:00 | Remove spine from ancient book artwork concept
    9b83de0 | 2026-10-10T15:15:15-04:00 | Add ancient leather book artwork to the empty tracker
    38ad492 | 2026-10-10T15:23:16-04:00 | Add matching right-edge clasp to the empty book
    e99dd5d | 2026-10-10T15:40:59-04:00 | Restore a modular spine with right-side book fittings
    c6e96c4 | 2026-10-10T15:44:00-04:00 | Save assembled book preview for mobile review
    f04e2ae | 2026-10-10T18:36:32-04:00 | Save book empty-state mockup for mobile review
    af59c0c | 2026-10-10T18:42:16-04:00 | Remove book lock and align right corner fittings
    f1b0319 | 2026-10-10T18:42:37-04:00 | Preserve handoff document line endings
    bae97f2 | 2026-10-10T19:14:34-04:00 | Prepare faction ambassador artwork for review
    182dcc4 | 2026-10-10T19:17:45-04:00 | Install approved Horde Ambassador banner and revise Alliance preview
    7e03401 | 2026-10-10T19:20:08-04:00 | Install approved Alliance Ambassador contrast pass
    4b05131 | 2026-10-10T19:23:53-04:00 | Restore empty-list cobwebs and deepen book lighting
    8965a4b | 2026-10-10T19:27:32-04:00 | Restore brown cobweb artwork and tint empty book leather
    eb2fcf8 | 2026-10-10T19:30:14-04:00 | Warm book corners to bronze and deepen spine shadow
    b152f55 | 2026-10-10T19:33:23-04:00 | Polish empty book focus and hide empty progress summary
    71641d9 | 2026-10-10T19:37:09-04:00 | Keep empty progress bar visible and fade summary after first goal
    850619a | 2026-10-10T19:43:31-04:00 | Slow progress summary fade to 1.2 seconds
    9a4e01d | 2026-10-10T19:47:41-04:00 | Add subtle warm radial lighting over empty book
    d6a9d5c | 2026-10-10T19:57:38-04:00 | Unify Forever chips and add subtle blue pulse
    22f2ef2 | 2026-10-10T20:03:25-04:00 | Brighten Forever title chip border and align its dot
    977b759 | 2026-10-10T20:14:32-04:00 | Replace card faction wording with clearer etched insignias
    648e3c1 | 2026-10-10T20:19:08-04:00 | Refine faction insignia placement and soft edge fades
    5266371 | 2026-10-10T20:21:30-04:00 | Replace carved faction stamps with soft corner artwork
    cce9c69 | 2026-10-10T20:24:12-04:00 | Shift faction emblems right and ease their fades
    c7edb3c | 2026-10-10T20:26:12-04:00 | Nudge faction emblems upward and brighten Horde
    972f0d9 | 2026-10-10T20:29:19-04:00 | Preserve faction logo artwork originals
    7cefdc8 | 2026-10-10T20:33:03-04:00 | Install approved transparent faction emblems and sync artwork
    29a1b48 | 2026-10-10T20:40:33-04:00 | Install approved Frostwolf banner, tabard icon and artist credit
    4a33689 | 2026-10-10T20:47:56-04:00 | Fix Frostwolf art priority and unify faction PvP thumbnails
    801a0e4 | 2026-10-10T20:51:58-04:00 | Support numeric texture IDs in icon resolver
    06ffbe4 | 2026-10-10T20:53:54-04:00 | Use named Horde banner texture for PvP thumbnails
    0513ee9 | 2026-10-10T20:57:42-04:00 | Fade faction emblem crop edges and nudge placement
    319b3d1 | 2026-10-10T21:03:51-04:00 | Ease faction emblem fades while preserving transparent edges
    1f6072a | 2026-10-10T21:07:18-04:00 | Extend faction artwork to card bottom with softer diagonal fade
    e198be6 | 2026-10-10T21:10:05-04:00 | Ease left emblem fade and soften bottom edge
    5c93bbd | 2026-10-10T21:16:41-04:00 | Soften faction card watermarks with continuous alpha artwork
    a008156 | 2026-10-10T21:26:42-04:00 | Enlarge faction watermarks and crop top right edges
    5026fb1 | 2026-10-10T21:28:25-04:00 | Increase faction card emblem scale again
    d0da134 | 2026-10-10T21:30:05-04:00 | Nudge faction card emblems up and right
    38f9899 | 2026-10-10T21:32:01-04:00 | Shift faction card emblems farther right
    e40171b | 2026-10-10T21:34:24-04:00 | Move faction emblems five pixels up and right
    ea60e32 | 2026-10-10T21:38:04-04:00 | Brighten selected card eyebrows in matching colors
    9302818 | 2026-10-10T21:43:09-04:00 | Use plain class set eyebrows on goal list cards
    2715838 | 2026-10-10T22:15:14-04:00 | Offer full height goal artwork with original sizing toggle
    961bda1 | 2026-10-10T22:16:10-04:00 | Verify full height artwork proportions and original sizing fallback
    e67eb36 | 2026-10-10T22:20:20-04:00 | Broaden tall artwork left fade for a gentler transition
    9533576 | 2026-10-10T22:25:08-04:00 | Simplify large goal photos setting wording
    a73d211 | 2026-10-10T22:28:51-04:00 | Fade Forever notice wash before right panel edge
    47800ad | 2026-10-10T22:32:54-04:00 | Add subtle right transparency to collapsed step group headers
    623c8f8 | 2026-10-10T22:36:45-04:00 | Initialize group fade geometry and bake alpha into gradients
    802529d | 2026-10-10T22:39:44-04:00 | Enlarge detail progress track with etched rim and soft transparency
    b6d6887 | 2026-10-10T22:42:28-04:00 | Reduce detail progress bar height to thirteen pixels
    6996fea | 2026-10-10T22:45:26-04:00 | Shorten Forever notice fade and tint selected group counts
    7be11d5 | 2026-10-10T22:49:11-04:00 | Soften goal page progress tip and add slow subtle bloom
    a5fd63e | 2026-10-10T22:51:20-04:00 | Replace external progress halo with subtle internal tip pulse
    1b80d57 | 2026-10-10T22:54:49-04:00 | Fade soft progress tip smoothly from its current brightness at completion
    924cf9e | 2026-10-10T22:59:54-04:00 | Default window to screen proportions and retain resizing only per session
    5c7fe1a | 2026-10-10T23:01:26-04:00 | Set default window dimensions to seventy percent of screen
    cdd131b | 2026-10-10T23:03:31-04:00 | Remove fixed size caps that shrink screen relative window defaults
    fdc81ba | 2026-10-10T23:06:05-04:00 | Measure screen relative window sizing in UIParent coordinates
    4ddd74a | 2026-10-10T23:06:49-04:00 | Recalculate session default size on first window opening
    4dd260c | 2026-10-10T23:18:43-04:00 | Release 2.11.0
    fcb77d1 | 2026-10-10T23:30:54-04:00 | Refresh cropped gallery screenshots for version 2.11.0
    1ff856e | 2026-10-10T23:47:05-04:00 | Record published release and final session handoff for tomorrow
    6b5a603 | 2026-10-11T00:40:40-04:00 | Sync new artwork originals and clarify Stormpike source filename
    cb5a298 | 2026-10-11T00:45:30-04:00 | Sync additional Swift Zulian Tiger artwork originals
    ca6dec3 | 2026-10-11T00:52:03-04:00 | Add armored Swift Zulian Tiger banner preview
    b83a79a | 2026-10-11T00:56:31-04:00 | Refine tiger helmet and glowing eyes in banner preview
    5c3093b | 2026-10-11T00:59:49-04:00 | Match tiger helmet reference silhouette in preview
    87bf437 | 2026-10-11T01:03:05-04:00 | Correct tiger nose guard perspective in preview
    9dc6016 | 2026-10-11T01:07:12-04:00 | Clean up tiger cheeks and tongue in banner preview
    9382abd | 2026-10-11T01:10:50-04:00 | Restore TCG tiger facial proportions in preview
    f845192 | 2026-10-11T01:13:45-04:00 | Finish tiger banner with bright white glowing eyes
    5e450d4 | 2026-10-11T01:16:26-04:00 | Install approved Swift Zulian Tiger goal artwork
    e3e8775 | 2026-10-11T01:26:05-04:00 | Audit addon globals and reduce progress pulse overhead
    428f2f0 | 2026-10-11T01:42:13-04:00 | Require Ketho API diagnostics before live releases
    8a3198e | 2026-10-11T10:42:03-04:00 | Add Forever Wolfsbane quest weapon goal
    16405fc | 2026-10-11T11:04:57-04:00 | Install approved Wolfsbane banner and sync artwork originals
    f3f0752 | 2026-10-11T11:41:09-04:00 | Add mount previews, fading artwork credits and clearer guide milestones
    8e139fb | 2026-10-11T11:45:20-04:00 | Correct Wolfsbane rare weapon styling
    0827ab7 | 2026-10-11T11:52:59-04:00 | Add scoped sword training prerequisite to Wolfsbane
    b29c84c | 2026-10-11T11:54:42-04:00 | Hide progress bar for learned weapon skills
    970d52c | 2026-10-11T11:55:54-04:00 | Use Undead race name in rule tooltips
    b4d060b | 2026-10-11T11:57:40-04:00 | Refine artwork credit size and bottom fade spacing
    e864cb6 | 2026-10-11T12:00:20-04:00 | Simplify Wolfsbane training tooltip wording
    17c7b17 | 2026-10-11T12:01:51-04:00 | Clarify sword training tooltip and link Undercity weapon master
    836d764 | 2026-10-11T12:04:13-04:00 | Move artwork credit left and soften opacity
    4e54c10 | 2026-10-11T12:05:57-04:00 | Fine tune artwork credit opacity and placement
    bc59749 | 2026-10-11T12:07:04-04:00 | Remove artwork credits section from Settings
    41ca4f0 | 2026-10-11T12:09:37-04:00 | Color faction restrictions and show Wolfsbane Paladin restriction
    85d591c | 2026-10-11T12:10:57-04:00 | Keep class restriction eyebrow on goal detail only
    f3665b7 | 2026-10-11T12:13:52-04:00 | Extend smooth goal panel bottom fade by ten pixels
    aa862c0 | 2026-10-11T12:23:55-04:00 | Smooth both ends of goal page bottom shadow and increase height
    7dcdf69 | 2026-10-11T12:26:57-04:00 | Shorten Violet Sorcerer Forever banner description
    342130c | 2026-10-11T12:30:00-04:00 | Label unknown item set sources in grey
    206a6ed | 2026-10-11T12:43:19-04:00 | Prepare four reputation banner previews for review
    17edb6c | 2026-10-11T12:51:24-04:00 | Install four approved reputation banners and artist credits
    d49c091 | 2026-10-11T12:57:29-04:00 | Install Jimmy Lo Alliance Benediction and Night Elf Priest artwork
    d041591 | 2026-10-11T13:15:01-04:00 | Prepare Beaststalker banner preview for review
    126e46b | 2026-10-11T13:16:15-04:00 | Install approved Beaststalker Armor banner with artist credit
    a0eca8a | 2026-10-11T13:20:19-04:00 | Prepare shared Blackwing Lair banner preview and sync source artwork
    709a145 | 2026-10-11T13:26:36-04:00 | Install approved shared Blackwing Lair raid and attunement banner
    56bb41b | 2026-10-11T13:32:33-04:00 | Prepare Alliance Dwarf Hunter leveling banner preview
    e2cab9e | 2026-10-11T13:33:26-04:00 | Install approved Alliance Dwarf Hunter leveling banner
    b9111fb | 2026-10-11T13:34:13-04:00 | Update Dwarf Hunter banner regression expectation
    a085bc1 | 2026-10-11T13:48:07-04:00 | Prepare profession and goal banner reviews with player skill selection
    40763e5 | 2026-10-11T13:51:04-04:00 | Remove rogue banner signature in review and prepare Glenn Rane credit
    35345fd | 2026-10-11T13:53:43-04:00 | Install approved profession Charger Naxxramas and Alliance rogue banners
    656b8c4 | 2026-10-11T13:57:38-04:00 | Sync Nat Pagle source artwork
    f5f7ebe | 2026-10-11T13:58:13-04:00 | Prepare Nat Pagle fishing banner review
    555676a | 2026-10-11T14:10:46-04:00 | Install approved Nat Pagle fishing profession banner
    4765b81 | 2026-10-11T14:17:42-04:00 | Sync new profession and Peruse artwork originals
    c15e9ad | 2026-10-11T14:19:26-04:00 | Prepare Alchemy First Aid and Cooking banner reviews
    02ee83e | 2026-10-11T14:24:15-04:00 | Install approved Alchemy First Aid and Cooking banners
    af3057c | 2026-10-11T14:32:17-04:00 | Sync Herbalism artwork originals
    bbba1c8 | 2026-10-11T14:32:59-04:00 | Prepare Herbalism banner review with Romain De Santi credit
    3118238 | 2026-10-11T14:34:56-04:00 | Install approved Herbalism banner with Romain De Santi credit
    c066cf0 | 2026-10-11T14:45:47-04:00 | Scan modern profession APIs for profession artwork selection
    3324cc7 | 2026-10-11T15:00:07-04:00 | Fade artist credits in with goal artwork
    2d5ef44 | 2026-10-11T15:09:59-04:00 | Sync Cenarion Hold artwork original
    8ba98ba | 2026-10-11T15:10:46-04:00 | Prepare Cenarion Circle banner review
    9fe9fb8 | 2026-10-11T15:13:48-04:00 | Install approved Cenarion Circle banner and update reputation thumbnail
    e9d5e7a | 2026-10-11T15:20:58-04:00 | Sync Soridormi and Caverns of Time source artwork
    e31a448 | 2026-10-11T15:21:50-04:00 | Prepare Brood of Nozdormu Soridormi banner review
    6c870b4 | 2026-10-11T15:23:38-04:00 | Install approved Brood of Nozdormu banner with Zoltan Boros credit
    9e1982e | 2026-10-11T15:29:15-04:00 | Sync Conjure Elementals source artwork
    2d92538 | 2026-10-11T15:30:23-04:00 | Prepare Hydraxian Waterlords banner review
    b82cd2c | 2026-10-11T15:35:05-04:00 | Revise Hydraxian banner to preserve reference village
    dd68b25 | 2026-10-11T15:37:03-04:00 | Install revised Hydraxian Waterlords banner with artist credit
    93eb997 | 2026-10-11T15:51:56-04:00 | Sync Mining and Brukan source artwork
    cfe0f7a | 2026-10-11T15:52:52-04:00 | Prepare Mining banner review with Patrick McEvoy credit
    cf01a49 | 2026-10-11T15:54:35-04:00 | Install approved Mining banner with Patrick McEvoy credit
    4396581 | 2026-10-11T15:58:58-04:00 | Sync Engineering source artwork
    8b82735 | 2026-10-11T15:59:41-04:00 | Prepare Engineering banner review
    6170c79 | 2026-10-11T16:02:57-04:00 | Install approved Engineering profession banner and sync artwork
    4e508d7 | 2026-10-11T16:05:17-04:00 | Prepare Horde Engineering artwork preview
    a96f701 | 2026-10-11T16:06:27-04:00 | Use approved faction-specific Engineering artwork
    6aab0fd | 2026-10-11T16:15:12-04:00 | Sync Blackrock Spire source artwork
    f8ae5b1 | 2026-10-11T16:15:38-04:00 | Prepare Blackrock Spire banner preview
    3845f23 | 2026-10-11T16:16:38-04:00 | Install approved Blackrock Spire banner
    a7ae3a0 | 2026-10-11T16:42:30-04:00 | Sync Stratholme source artwork
    9dff511 | 2026-10-11T16:43:33-04:00 | Prepare Stratholme banner without loading screen UI
    ba1baf4 | 2026-10-11T16:45:09-04:00 | Install approved artwork for Stratholme Key only
    ef901a4 | 2026-10-11T16:47:53-04:00 | Prepare Warlord Mail shaman banner preview
    839fb59 | 2026-10-11T16:50:57-04:00 | Prepare signature-free shaman preview with Alex Horley credit
    70cff1d | 2026-10-11T16:52:32-04:00 | Install credited shaman art and Stratholme Devout banner
    00bbf42 | 2026-10-11T17:08:06-04:00 | Prepare 2.11.1 patch release with API and package checks
    944b22b | 2026-10-11T17:18:53-04:00 | Record successful 2.11.1 release and published package verification
    c4a1266 | 2026-10-11T17:29:06-04:00 | Refresh CurseForge description for 2.11.1
    a551ab5 | 2026-10-11T17:33:04-04:00 | Simplify CurseForge description and recent releases
    77608c1 | 2026-10-11T17:36:22-04:00 | Save concise description preferences and exact AI disclaimer
    7190614 | 2026-10-11T17:38:04-04:00 | Close session with cross-platform handoff and synced release state
    4b2d853 | 2026-10-11T20:31:25-04:00 | Add Warcraft Serif and Modern typography settings
    d3c62e4 | 2026-10-11T20:37:25-04:00 | Match personal note icon to goal edit styling
    a558899 | 2026-10-11T20:42:44-04:00 | Prepare Forever step-lock preview for in-game review
    85abf78 | 2026-10-11T21:03:04-04:00 | Simplify goal guides and shared UI wording
    345c1e8 | 2026-10-11T21:09:06-04:00 | Bound window resizing around the default size
    3f5abaa | 2026-10-11T21:13:41-04:00 | Update Forever racial mount and riding costs
    bf47a60 | 2026-10-11T21:32:13-04:00 | Set font before measuring startup sample text
    f65e6d3 | 2026-10-11T21:39:52-04:00 | Fix font switching and refine live-review UI behavior
    51b1785 | 2026-10-11T21:44:53-04:00 | Withdraw Modern font choice and retain typography helpers
    699d061 | 2026-10-11T21:45:15-04:00 | Normalize typography test line endings
    151fa0c | 2026-10-11T21:51:59-04:00 | Record optional step reveal as a future roadmap idea
    a0c97f1 | 2026-10-11T22:03:52-04:00 | Prepare isolated Forever dependency rollout with native review
    c79d22e | 2026-10-11T22:07:22-04:00 | Use the standard Warcraft font for all headings
    0b866d1 | 2026-10-11T22:13:14-04:00 | Preserve original panel widths with Warcraft headings
    84c2d3d | 2026-10-11T22:15:05-04:00 | Widen goals list by 22 UI units
    e8f894e | 2026-10-11T22:16:25-04:00 | Give goals list another 12 UI units of width
    90ba2b1 | 2026-10-11T22:17:49-04:00 | Set goals list width offset to 40 UI units
    e7b9ee5 | 2026-10-11T22:19:35-04:00 | Give goals list another 10 UI units of width
    e38dcb0 | 2026-10-11T23:03:47-04:00 | Add sliding per-goal Materials panel
    1aed686 | 2026-10-11T23:09:42-04:00 | Slide Materials from outer edge and fade tuck shadow
    7a4542e | 2026-10-11T23:12:45-04:00 | Use subtle Materials arrow centered in panel gap
    de9c148 | 2026-10-11T23:18:02-04:00 | Fade Materials contents and remove duplicate collection bars
    059d747 | 2026-10-11T23:21:29-04:00 | Record evening closeout and next release review

## Changed paths since baseline

    A	.agents/skills/forever-goal-tracker-banners/SKILL.md
    M	.gitignore
    M	.pkgmeta
    A	AGENTS.md
    A	AQArmor.lua
    A	ARTWORK-CREDITS.txt
    A	ArmorSets.lua
    M	CHANGELOG.md
    M	CLAUDE.md
    M	Core.lua
    M	Data.lua
    A	Dependencies.lua
    A	Fonts/OpenSans-Bold.ttf
    A	Fonts/OpenSans-OFL.txt
    A	Fonts/OpenSans-Regular.ttf
    M	ForeverGoalTracker.toc
    A	ItemTooltips.lua
    M	Library.lua
    A	Materials.lua
    A	Media/allclasses_dwarf_hunter-banner.blp
    A	Media/allclasses_dwarf_shaman-banner.blp
    A	Media/allclasses_horde_hunter-banner.blp
    A	Media/allclasses_nightelf_hunter-banner.blp
    A	Media/allclasses_troll_mage-banner.blp
    A	Media/allclasses_undead_paladin-banner.blp
    A	Media/artwork/395136-swift-zulian-tiger.jpg
    A	Media/artwork/Ahn'Qiraj_War_WoW_Classic_Wallpaper.jpg
    A	Media/artwork/AhnQirajWarClassic.jpg
    A	Media/artwork/AllianceLogo.png
    A	Media/artwork/Arcane_Sanctum_TCG_Frost_Mage.jpg
    A	Media/artwork/Arcane_Sanctum_TCG_Frost_Mage.webp
    A	Media/artwork/Arcanite_Reaper_full.jpg
    A	Media/artwork/Ashbringer3CoverArtworkB.jpg
    A	Media/artwork/AshbringerC.jpg
    A	Media/artwork/Ashenvale_TCG.jpg
    A	Media/artwork/Assault_on_Ahn'Qiraj.jpg
    A	Media/artwork/Avatar_of_the_Wild_TCG.jpg
    A	Media/artwork/BG22_HERO_200p_art.jpg
    A	Media/artwork/Baron_Rivendare_full.jpg
    A	Media/artwork/Battleground_Battlemaster_HS.jpg
    A	Media/artwork/Beaststalker_Tavish_full.jpg
    A	Media/artwork/Blackrock_mountain_gates_comic.jpg
    A	Media/artwork/Blacksmithing_Hammer_full.jpg
    A	Media/artwork/Blackwing_Lair_Classic_key_art copy.jpg
    A	Media/artwork/Blackwing_Lair_Classic_key_art.jpg
    A	Media/artwork/Bladefist's_Breadth_TCG.jpg
    A	Media/artwork/Booty_Bay_by_wtsmq.jpg
    A	Media/artwork/Bru'kan_(Book_of_Mercenaries_2)_full.jpg
    A	Media/artwork/C'Thun_Ahn'Qiraj_jorgejacinto.jpg
    A	Media/artwork/Campfire_full.jpg
    A	Media/artwork/Caverns_of_Time_TCG.jpg
    A	Media/artwork/Celee_Cogfreeze_TCG.jpg
    A	Media/artwork/Cenarion_Hold_HS.jpg
    A	Media/artwork/Chronicle_Scarab_Wall.jpg
    A	Media/artwork/Classic_Hardcore_key_art copy.jpg
    A	Media/artwork/Classic_Hardcore_key_art.jpg
    A	Media/artwork/Conjure_Elementals_TCG.jpg
    A	Media/artwork/Core_Hound_moltencore-raid.jpg
    A	Media/artwork/Curse_from_Beyond_TCG_card.png
    A	Media/artwork/DagranThaurissan_HS.jpg
    A	Media/artwork/Deacon_Johanna_full.jpg
    A	Media/artwork/Dire_Maul_WoW_Classic.jpg
    A	Media/artwork/Dragonstalker_tier3-hunter-moltencore.jpg
    A	Media/artwork/Druid_of_the_Plains_full.jpg
    A	Media/artwork/Drums_of_War_TCG_art.jpg
    A	Media/artwork/Dun_Baldar_Bridge_full.jpg
    A	Media/artwork/Dun_Baldar_Bunker_full (1).jpg
    A	Media/artwork/Dun_Baldar_Bunker_full-stormpikeguard.jpg
    A	Media/artwork/Durotan_TCG.jpg
    A	Media/artwork/Earthen_Ring_Farseer_full.jpg
    A	Media/artwork/Earthfury_Thrall_full.jpg
    A	Media/artwork/Echoes_of_the_Shifting_Sands.jpg
    A	Media/artwork/Edwin,_Defias_Kingpin_full.jpg
    A	Media/artwork/Elven_Archer_full.jpg
    A	Media/artwork/Exploring_Azeroth_-_Orgrimmar.jpg
    A	Media/artwork/Exploring_Azeroth_-_Stormwind.jpg
    A	Media/artwork/Field_of_Strife_full.jpg
    A	Media/artwork/Fire_Elemental_full.jpg
    A	Media/artwork/First_Aid_Kit_HS.jpg
    A	Media/artwork/First_Flame_full.jpg
    A	Media/artwork/Furbolg_Spiritbinder_TCG.jpg
    A	Media/artwork/Garrote_full.jpg
    A	Media/artwork/Ghostly_Charger_TCG.jpg
    A	Media/artwork/Giantstalker_Rexxar_full.jpg
    A	Media/artwork/Grand_Widow_Faerlina_full.jpg
    A	Media/artwork/Guarded_by_the_Light_TCG.jpg
    A	Media/artwork/Hakkar,_the_Soulflayer_full.jpg
    A	Media/artwork/Healing_Rain_full.jpg
    A	Media/artwork/Heroes_of_Azeroth.jpg
    A	Media/artwork/Hit_It_Very_Hard_full.jpg
    A	Media/artwork/HordeLogo.png
    A	Media/artwork/Ice_Barrier_full.jpg
    A	Media/artwork/Iceblood_Garrison_full.jpg
    A	Media/artwork/Interrogator_Whitemane_full.jpg
    A	Media/artwork/Kel'Thuzad_full.jpg
    A	Media/artwork/King's_Ransom_full.jpg
    A	Media/artwork/Kodorider_full.jpg
    A	Media/artwork/Lady_Anacondra_full.jpg
    A	Media/artwork/Leatherworking_Kit_full.jpg
    A	Media/artwork/Lie_in_Wait_full.jpg
    A	Media/artwork/Lunira_Swiftbreath_TCG.jpg
    A	Media/artwork/Maestra_of_the_Masquerade_full.jpg
    A	Media/artwork/Magma_Hound_full.jpg
    A	Media/artwork/Majordomo_Executus_full.jpg
    A	Media/artwork/Man_the_Cannons_full.jpg
    A	Media/artwork/Mass_Dispel_TCG copy.jpg
    A	Media/artwork/Mass_Dispel_TCG.jpg
    A	Media/artwork/Masten_Everspirit_full.webp
    A	Media/artwork/Mias_the_Fair_TCG.jpg
    A	Media/artwork/Moonwell_full.jpg
    A	Media/artwork/Morova_of_the_Sands_TCG.jpg
    A	Media/artwork/Mulgore_tcg.jpg
    A	Media/artwork/Nat_Pagle_HS.jpg
    A	Media/artwork/Naxx_-_trailer_Naxx.jpg
    A	Media/artwork/Naxxramas_TCG_key_art.jpg
    A	Media/artwork/Northwatch_Commander_full.jpg
    A	Media/artwork/OnyxiaTCG.jpg
    A	Media/artwork/Onyxia_full.jpg
    A	Media/artwork/Overlord_Runthak_full.jpg
    A	Media/artwork/Overlord_Saurfang_full.jpg
    A	Media/artwork/Peruse_full.jpg
    A	Media/artwork/Provoke_full.jpg
    A	Media/artwork/Quel'Delar_full.jpg
    A	Media/artwork/Quel'Serrar_TCG_Card.png
    A	Media/artwork/Ragnaros_the_Firelord_full.jpg
    A	Media/artwork/Raid_Boss_Onyxia_full.jpg
    A	Media/artwork/Rhok'delar_full.jpg
    A	Media/artwork/Ring_of_Courage_full.jpg
    A	Media/artwork/Runed_Mithril_Rod_full.jpg
    A	Media/artwork/Sally_Whitemane_full.jpg
    A	Media/artwork/Samuel_Grey_TCG.jpg
    A	Media/artwork/Saurfang_the_Younger,_Kor'kron_Warlord_TCG.jpg
    A	Media/artwork/Savage_Striker_full.jpg
    A	Media/artwork/Selective_Breeder_full.jpg
    A	Media/artwork/Sense_Demons_full.jpg
    A	Media/artwork/Shadowcloth_Needle_full.jpg
    A	Media/artwork/Shadowform_full.jpg
    A	Media/artwork/Skeram_Cultist.jpg
    A	Media/artwork/Smokescreen_full.jpg
    A	Media/artwork/Snipe_full.jpg
    A	Media/artwork/Snowfall_Graveyard_full.jpg
    A	Media/artwork/Soridormi_full.jpg
    A	Media/artwork/Stratholme_loading_screen.jpg
    A	Media/artwork/Sulfuras_full.jpg
    A	Media/artwork/Sullivan_Holmes_TCG_Card.jpg
    A	Media/artwork/Sunscale_Raptor_full.jpg
    A	Media/artwork/Swift Zulian Tiger (1).png
    A	Media/artwork/Swift Zulian Tiger (2).png
    A	Media/artwork/Swift Zulian Tiger copy.png
    A	Media/artwork/Swift Zulian Tiger.png
    A	Media/artwork/Swift_Mechanostrider_TCG.jpg
    A	Media/artwork/Swift_Nightsaber_TCG.jpg
    A	Media/artwork/Swift_Palomino_TCG.jpg
    A	Media/artwork/Swift_Ram_TCG.jpg
    A	Media/artwork/Swift_Raptor_TCG.jpg
    A	Media/artwork/TCGTiger.webp
    A	Media/artwork/The_Alchemist_HS.jpg
    A	Media/artwork/The_Defias_Brotherhood_TCG.jpg
    A	Media/artwork/The_Eye_of_Command_TCG.jpg
    A	Media/artwork/The_Scarab_Lord.jpg
    A	Media/artwork/The_Skeleton_Key_full.jpg
    A	Media/artwork/Totemic_Call_TCG.jpg
    A	Media/artwork/Ultramarine_Qiraji_Battle_Tank_TCG.jpg
    A	Media/artwork/Undercity_Valiant_HS.png
    A	Media/artwork/Vindicator_Borovon_TCG.jpg
    A	Media/artwork/Vital_Adventurer_full.jpg
    A	Media/artwork/War_Golem.jpg
    A	Media/artwork/Warsong_Envoy_HS.jpg
    A	Media/artwork/WoW_Forever_Announce_Key_Art_-_Alliance.jpg
    A	Media/artwork/WoW_Forever_Cinematic_Still_11.jpeg
    A	Media/artwork/WoW_Forever_Cinematic_Still_4.jpeg
    A	Media/artwork/Worgen_Samwise.jpg
    A	Media/artwork/Wormwood_TCG.jpg
    A	Media/artwork/Zealotry_TCG_card.png
    A	Media/artwork/allaince-human-mage.jpg
    A	Media/artwork/alliance-nightelf-epicmount-saber.jpg
    A	Media/artwork/alliance-nightelf-warrior-tier2.jpg
    A	Media/artwork/alliance-warlock-tier2.jpg
    A	Media/artwork/anathema-source.jpg
    A	Media/artwork/anathema.jpg
    A	Media/artwork/ancient-book-assembled-preview-2026-10-10.png
    A	Media/artwork/ancient-book-band-2026-10-10.png
    A	Media/artwork/ancient-book-clasp-2026-10-10.png
    A	Media/artwork/ancient-book-clasp-first-2026-10-10.png
    A	Media/artwork/ancient-book-corner-2026-10-10.png
    A	Media/artwork/ancient-book-cover-concept-2026-10-10.png
    A	Media/artwork/ancient-book-cover-no-spine-2026-10-10.png
    A	Media/artwork/ancient-book-edge-2026-10-10.png
    A	Media/artwork/ancient-book-in-tracker-mockup-2026-10-10.png
    A	Media/artwork/ancient-book-leather-2026-10-10.png
    A	Media/artwork/ancient-book-spine-2026-10-10.png
    A	Media/artwork/argent-dawn.jpg
    A	Media/artwork/ashbringer-banner-source.png
    A	Media/artwork/ashbringer-bw.png
    A	Media/artwork/ashbringer-color.jpg
    A	Media/artwork/atiesh-banner-source.jpg
    A	Media/artwork/atiesh-source.jpg
    A	Media/artwork/atiesh.jpg
    A	Media/artwork/baron-naxx.jpg
    A	Media/artwork/blackrock-mountain---trailer1-source.jpg
    A	Media/artwork/blackrock-mountain.jpg
    A	Media/artwork/blackwinglair.jpg
    A	Media/artwork/buy-swift-zulian-tiger-wow2.webp
    A	Media/artwork/cenarion-circle.jpg
    A	Media/artwork/corehound-moltencore.jpg
    A	Media/artwork/corrupted-ashbringer-source.jpg
    A	Media/artwork/dalaran.jpg
    A	Media/artwork/deadmines-2.jpg
    A	Media/artwork/dirmaul.jpg
    A	Media/artwork/druid (2).jpg
    A	Media/artwork/druid-alliance-nightelf-tier2-2.jpg
    A	Media/artwork/druid-alliance-nightelf-tier2.jpg
    A	Media/artwork/druid-alliance.jpg
    A	Media/artwork/druid-horde.jpg
    A	Media/artwork/druid-nightelf-alliance-tier1.jpg
    A	Media/artwork/druid-tier3.jpg
    A	Media/artwork/dwarf-alliance-epicmount-ram.jpg
    A	Media/artwork/dwarf-alliance-ram-mount.jpg
    A	Media/artwork/dwarf-priest-alliance (2).jpg
    A	Media/artwork/dwarf-priest-alliance.jpg
    A	Media/artwork/dwarf-shaman-alliance.jpg
    A	Media/artwork/fanart-1218-full.jpg
    A	Media/artwork/frostsaber.jpg
    A	Media/artwork/furnolg-raid-burrow.jpg
    A	Media/artwork/garr-moltencore-boss.jpg
    A	Media/artwork/horde-druid.jpg
    A	Media/artwork/horde-kodo-mount-tauren.jpg
    A	Media/artwork/horde-master-mail-pvp.jpg
    A	Media/artwork/horde-orc-hunter.jpg
    A	Media/artwork/horde-orc-warlock-tier2.jpg
    A	Media/artwork/horde-orc-warrior-tier2.jpg
    A	Media/artwork/horde-tauren-epicmount-kodo.jpg
    A	Media/artwork/horde-troll-mage.jpg
    A	Media/artwork/horde-warlock-tier2-horde.jpg
    A	Media/artwork/human-alliance-mage-spell.jpg
    A	Media/artwork/human-alliance-mage-tier1.jpg
    A	Media/artwork/human-alliance-mage-tier2.jpg
    A	Media/artwork/human-alliance-paladin-charger-mount-epic.jpg
    A	Media/artwork/human-alliance-paladin-tier3.jpg
    A	Media/artwork/human-alliance-priest-benediction-tier1.jpg
    A	Media/artwork/human-alliance-priest-tier1.jpg
    A	Media/artwork/human-alliance-priest-tier2.jpg
    A	Media/artwork/human-mage-alliance-tier2.jpg
    A	Media/artwork/human-priest-alliance-tier1.jpg
    A	Media/artwork/human-rogue-alliance-perditionblade.jpg
    A	Media/artwork/human-warrior-alliance-mount-epic.jpg
    A	Media/artwork/hunter-tier3-references/Cryptstalker Spaulders (1).png
    A	Media/artwork/hunter-tier3-references/Cryptstalker Spaulders.png
    A	Media/artwork/hunter-tier3-references/Echeyakee (1).png
    A	Media/artwork/hunter-tier3-references/Echeyakee (2).png
    A	Media/artwork/hunter-tier3-references/Echeyakee.png
    A	Media/artwork/hunter-tier3-references/Troll Male Hunter - Wowhead Dressing Room (5).png
    A	Media/artwork/hunter-tier3-references/Troll Male Hunter - Wowhead Dressing Room (6).png
    A	Media/artwork/hunter-tier3-references/Troll Male Hunter - Wowhead Dressing Room (7).png
    A	Media/artwork/hunter-tier3-references/Troll Male Hunter - Wowhead Dressing Room (8).png
    A	Media/artwork/hunter-tier3-references/Troll Male Hunter - Wowhead Dressing Room (9).png
    A	Media/artwork/hunter-tier3-references/grayscale-finish-reference.png
    A	Media/artwork/hyjal-raid.jpg
    A	Media/artwork/hyjal.jpg
    A	Media/artwork/kelthuzad-source.jpg
    A	Media/artwork/lokdelar.png
    A	Media/artwork/mage-skyborne-alliance.jpg
    A	Media/artwork/majordomo-executus-source.jpg
    A	Media/artwork/mount-paladin-charger-epic.jpg
    A	Media/artwork/mount_charger-banner-source.jpg
    A	Media/artwork/mount_dreadsteed-banner-source.jpg
    A	Media/artwork/naxx---trailer-baron-source.jpg
    A	Media/artwork/naxx---trailer-naxx-source.jpg
    A	Media/artwork/nightelf-alliance-hunter-tier2.jpg
    A	Media/artwork/nightelf-alliance-nightsaber-mount.jpg
    A	Media/artwork/og-image-herbalism.jpg
    A	Media/artwork/onyxia1.jpg
    A	Media/artwork/orc-horde-pvp.jpg
    A	Media/artwork/orc-horde-shaman-tier2.jpg
    A	Media/artwork/orc-horde-shaman.jpg
    A	Media/artwork/orc-horde-warlock-tier1.jpg
    A	Media/artwork/orc-horde-warrior-tier2.jpg
    A	Media/artwork/orc-horde-warrior.jpg
    A	Media/artwork/orc-horde-wolf-mount.jpg
    A	Media/artwork/orc-horde-wolf-mount2.jpg
    A	Media/artwork/orc-wolf-mount.jpg
    A	Media/artwork/paladin-class-blessing.jpg
    A	Media/artwork/paladin-mount-charger.jpg
    A	Media/artwork/prepared/anathema.blp
    A	Media/artwork/prepared/atiesh.blp
    A	Media/artwork/prepared/blackrock-mountain---trailer1.blp
    A	Media/artwork/prepared/corrupted-ashbringer.blp
    A	Media/artwork/prepared/kelthuzad.blp
    A	Media/artwork/prepared/majordomo-executus.blp
    A	Media/artwork/prepared/manifest.json
    A	Media/artwork/prepared/naxx---trailer-baron.blp
    A	Media/artwork/prepared/naxx---trailer-naxx.blp
    A	Media/artwork/prepared/queldelar.blp
    A	Media/artwork/prepared/ragnaros-the-firelord.blp
    A	Media/artwork/prepared/sulfuras.blp
    A	Media/artwork/priest-alliance-nightelf-tier3.jpg
    A	Media/artwork/priest-tier3.jpg
    A	Media/artwork/pvp-alliance-horde-human-orc.jpg
    A	Media/artwork/pvp-alliance-ram-dwarf.jpg
    A	Media/artwork/pvp-horde-orc-wolf.jpg
    A	Media/artwork/queldelar-source.jpg
    A	Media/artwork/ragnaros-the-firelord-source.jpg
    A	Media/artwork/raid_bwl-banner-source.jpg
    A	Media/artwork/raid_ony-banner-source.jpg
    A	Media/artwork/rhokdelar-banner-source.jpg
    A	Media/artwork/rogue-gnome-allaince-tier1b.jpg
    A	Media/artwork/rogue-gnome-alliance-tier1.jpg
    A	Media/artwork/rogue-nightelf-alliance-tier3.jpg
    A	Media/artwork/scarab-event.jpg
    A	Media/artwork/shaman-orc-horde-tier1.jpg
    A	Media/artwork/shaman-orc-horde-tier3.jpg
    A	Media/artwork/shaman-orc-horde.jpg
    A	Media/artwork/shaman-troll-horde-tenstorms.jpg
    A	Media/artwork/snake-wailing-caverns.jpg
    A	Media/artwork/stormpike-pvp-ram-mount.jpg
    A	Media/artwork/sulfuras-banner-source.jpg
    A	Media/artwork/sulfuras-source.jpg
    A	Media/artwork/tauren-horde-shaman-tier2.jpg
    A	Media/artwork/tauren-horde-shaman.jpg
    A	Media/artwork/thunderfury-banner-source.png
    A	Media/artwork/thunderfury-shaman.jpg
    A	Media/artwork/thunderfury.png
    A	Media/artwork/troll-raptor-mount-horse.jpg
    A	Media/artwork/troll-shaman-horde-tenstorms.jpg
    A	Media/artwork/undead-forsaken-warlock-horde.jpg
    A	Media/artwork/undead-horde-mount-warhorse.jpg
    A	Media/artwork/undead-mount.jpg
    A	Media/artwork/undead-priest-hord-anathama.jpg
    A	Media/artwork/undead-priest-horde-tier1.jpg
    A	Media/artwork/undead-warlock-horde-tier3.jpg
    A	Media/artwork/warlock-mount-dreadsteed-2.jpg
    A	Media/artwork/warlock-mount-dreadsteed.jpg
    A	Media/artwork/warlock.jpg
    A	Media/artwork/warrior-dwarf-alliance-tier3.jpg
    A	Media/artwork/warrior-might-armor-tier1.jpg
    A	Media/artwork/wow-classic-engineering.webp
    A	Media/artwork/wow-zul-gurub.jpg
    A	Media/artwork/zepheras-isle.jpeg
    A	Media/ashbringer-banner.blp
    A	Media/atiesh-banner.blp
    A	Media/att_mc-banner.blp
    A	Media/att_naxx-banner.blp
    A	Media/benediction-alliance-banner.blp
    A	Media/benediction-banner.blp
    A	Media/empty-book-band-source.png
    A	Media/empty-book-band.tga
    A	Media/empty-book-clasp-source.png
    A	Media/empty-book-clasp.tga
    A	Media/empty-book-corner-source.png
    A	Media/empty-book-corner.tga
    A	Media/empty-book-edge-source.png
    A	Media/empty-book-edge.tga
    A	Media/empty-book-leather-source.png
    A	Media/empty-book-leather.tga
    A	Media/empty-book-spine-source.png
    A	Media/empty-book-spine.tga
    A	Media/epicmounts_dwarf-banner.blp
    A	Media/epicmounts_gnome-banner.blp
    A	Media/epicmounts_human-banner.blp
    A	Media/epicmounts_nightelf-banner.blp
    A	Media/epicmounts_orc-banner.blp
    A	Media/epicmounts_skyborne-banner.blp
    A	Media/epicmounts_tauren-banner.blp
    A	Media/epicmounts_troll-banner.blp
    A	Media/epicmounts_undead-banner.blp
    A	Media/faction-alliance.tga
    A	Media/faction-horde.tga
    A	Media/faction-soft-alliance.tga
    A	Media/faction-soft-horde.tga
    A	Media/final-images/README.md
    A	Media/final-images/additional-goals/README.md
    A	Media/final-images/additional-goals/frostsaber.jpg
    A	Media/final-images/additional-goals/gold.jpg
    A	Media/final-images/additional-goals/key_dm.jpg
    A	Media/final-images/additional-goals/key_scholo.jpg
    A	Media/final-images/additional-goals/lokdelar.jpg
    A	Media/final-images/additional-goals/rep_cenarion.jpg
    A	Media/final-images/additional-goals/set_viper.jpg
    A	Media/final-images/blackrock-spire/master.png
    A	Media/final-images/blackrock-spire/review-2026-10-11.png
    A	Media/final-images/blackwing-lair.jpg
    A	Media/final-images/blackwing-lair/classic-key-art-master.png
    A	Media/final-images/blackwing-lair/classic-key-art-review.png
    A	Media/final-images/factions/alliance-soft.png
    A	Media/final-images/factions/alliance-white.png
    A	Media/final-images/factions/horde-soft.png
    A	Media/final-images/factions/horde-white.png
    A	Media/final-images/fishing/booty-bay-review.png
    A	Media/final-images/leveling/dwarf-hunter-master.png
    A	Media/final-images/leveling/dwarf-hunter-review.png
    A	Media/final-images/leveling/dwarf-shaman.jpg
    A	Media/final-images/leveling/horde-hunter.jpg
    A	Media/final-images/leveling/nightelf-hunter.jpg
    A	Media/final-images/leveling/troll-mage-review.png
    A	Media/final-images/leveling/troll-mage.jpg
    A	Media/final-images/leveling/undead-paladin.jpg
    A	Media/final-images/molten-core/README.md
    A	Media/final-images/molten-core/att_mc.jpg
    A	Media/final-images/molten-core/raid_mc.jpg
    A	Media/final-images/molten-core/set_tier1.jpg
    A	Media/final-images/mount-reviews/charger-review.png
    A	Media/final-images/mount-reviews/deathcharger-review.png
    A	Media/final-images/mount-reviews/dreadsteed-review-v2.png
    A	Media/final-images/mount-reviews/dreadsteed-review.png
    A	Media/final-images/mounts/aq-battle-tanks.jpg
    A	Media/final-images/mounts/black-qiraji.jpg
    A	Media/final-images/mounts/charger-master.png
    A	Media/final-images/mounts/charger-review-2026-10-11.png
    A	Media/final-images/mounts/dwarf-ram-review.png
    A	Media/final-images/mounts/dwarf-ram-tcg-review.png
    A	Media/final-images/mounts/dwarf-ram.jpg
    A	Media/final-images/mounts/gnome-mechanostrider-review.png
    A	Media/final-images/mounts/gnome-mechanostrider.jpg
    A	Media/final-images/mounts/human-palomino-review-v2.png
    A	Media/final-images/mounts/human-palomino-review.png
    A	Media/final-images/mounts/human-palomino.jpg
    A	Media/final-images/mounts/nightelf-nightsaber-review.png
    A	Media/final-images/mounts/nightelf-nightsaber.jpg
    A	Media/final-images/mounts/orc-wolf-review.png
    A	Media/final-images/mounts/orc-wolf.jpg
    A	Media/final-images/mounts/scarab-lord-review.png
    A	Media/final-images/mounts/skyborne-location.jpg
    A	Media/final-images/mounts/swift-zulian-tiger-master.png
    A	Media/final-images/mounts/tauren-kodo-review.png
    A	Media/final-images/mounts/tauren-kodo.jpg
    A	Media/final-images/mounts/troll-raptor-review.png
    A	Media/final-images/mounts/troll-raptor.jpg
    A	Media/final-images/mounts/undead-warhorse.jpg
    A	Media/final-images/naxxramas/naxxramas-review-2026-10-11.png
    A	Media/final-images/naxxramas/tcg-key-art-master.png
    A	Media/final-images/pending/APPROVALS.md
    A	Media/final-images/pending/alliance-paladin-tier1-review.png
    A	Media/final-images/pending/alliance-pvp-mounts-review.png
    A	Media/final-images/pending/alliance-warlock-tier2-review.png
    A	Media/final-images/pending/alliance-warlock-tier3-review.png
    A	Media/final-images/pending/black-qiraji-review.png
    A	Media/final-images/pending/dire-maul-key-review.png
    A	Media/final-images/pending/dwarf-shaman-leveling-review.png
    A	Media/final-images/pending/gold-goal-review-v2.png
    A	Media/final-images/pending/gold-goal-review.png
    A	Media/final-images/pending/horde-druid-tier3-review.png
    A	Media/final-images/pending/horde-hunter-leveling-review.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review-v2.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review-v3.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review-v4.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review-v5.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review-v6.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review-v7.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review-v8.png
    A	Media/final-images/pending/hunter-tier3-cryptstalker-review.png
    A	Media/final-images/pending/nightelf-hunter-leveling-review.png
    A	Media/final-images/pending/pvp-drums-of-war-review.png
    A	Media/final-images/pending/pvp-warlord-mail-review-v2.png
    A	Media/final-images/pending/pvp-warlord-mail-review.png
    A	Media/final-images/pending/seven-banner-contact-sheet.jpg
    A	Media/final-images/pending/skyborne-racial-mount-review.png
    A	Media/final-images/pending/timbermaw-review.png
    A	Media/final-images/pending/undead-paladin-leveling-review-v2.png
    A	Media/final-images/pending/undead-paladin-leveling-review.png
    A	Media/final-images/pending/undead-racial-mount-review.png
    A	Media/final-images/professions/alchemy-master.png
    A	Media/final-images/professions/alchemy-review-2026-10-11.png
    A	Media/final-images/professions/blacksmithing-master.png
    A	Media/final-images/professions/blacksmithing-review-2026-10-11.png
    A	Media/final-images/professions/cooking-master.png
    A	Media/final-images/professions/cooking-review-2026-10-11.png
    A	Media/final-images/professions/enchanting-master.png
    A	Media/final-images/professions/enchanting-review-2026-10-11.png
    A	Media/final-images/professions/engineering-horde-master.png
    A	Media/final-images/professions/engineering-horde-review-2026-10-11.png
    A	Media/final-images/professions/engineering-master.png
    A	Media/final-images/professions/engineering-review-2026-10-11.png
    A	Media/final-images/professions/first-aid-master.png
    A	Media/final-images/professions/first-aid-review-2026-10-11.png
    A	Media/final-images/professions/fishing-master.png
    A	Media/final-images/professions/fishing-review-2026-10-11.png
    A	Media/final-images/professions/herbalism-master.png
    A	Media/final-images/professions/herbalism-review-2026-10-11.png
    A	Media/final-images/professions/leatherworking-master.png
    A	Media/final-images/professions/leatherworking-review-2026-10-11.png
    A	Media/final-images/professions/mining-master.png
    A	Media/final-images/professions/mining-review-2026-10-11.png
    A	Media/final-images/professions/tailoring-master.png
    A	Media/final-images/professions/tailoring-review-2026-10-11.png
    A	Media/final-images/pvp/alliance-mounts.jpg
    A	Media/final-images/pvp/drums-of-war.jpg
    A	Media/final-images/pvp/frostwolf-clean-review.png
    A	Media/final-images/pvp/frostwolf-master.png
    A	Media/final-images/pvp/frostwolf-review.png
    A	Media/final-images/pvp/shared-pvp-review.png
    A	Media/final-images/pvp/shared-pvp.jpg
    A	Media/final-images/pvp/warlord-mail-shaman-master.png
    A	Media/final-images/pvp/warlord-mail-shaman-review-2026-10-11.png
    A	Media/final-images/pvp/warlord-mail-shaman-review-v2-2026-10-11.png
    A	Media/final-images/pvp/warlord-mail.jpg
    A	Media/final-images/raid-reviews/ahnqiraj-review.png
    A	Media/final-images/raid-reviews/barrow-deeps-review.png
    A	Media/final-images/raid-reviews/cthun-review.png
    A	Media/final-images/raid-reviews/hyjal-review.png
    A	Media/final-images/raid-reviews/naxxramas-review.png
    A	Media/final-images/reputation/rep_argentdawn-review-v2.png
    A	Media/final-images/reputation/rep_argentdawn-review-v3.png
    A	Media/final-images/reputation/rep_argentdawn-review.png
    A	Media/final-images/reputation/rep_argentdawn.jpg
    A	Media/final-images/reputation/timbermaw.jpg
    A	Media/final-images/reputations/ambassador-alliance-contrast-review.png
    A	Media/final-images/reputations/ambassador-alliance-master.png
    A	Media/final-images/reputations/ambassador-alliance-review-v2.png
    A	Media/final-images/reputations/ambassador-alliance-review.png
    A	Media/final-images/reputations/ambassador-horde-master.png
    A	Media/final-images/reputations/ambassador-horde-review.png
    A	Media/final-images/reputations/brood-nozdormu-master.png
    A	Media/final-images/reputations/brood-nozdormu-review-2026-10-11.png
    A	Media/final-images/reputations/cenarion-circle-master.png
    A	Media/final-images/reputations/cenarion-circle-review-2026-10-11.png
    A	Media/final-images/reputations/hydraxian-waterlords-master.png
    A	Media/final-images/reputations/hydraxian-waterlords-review-2026-10-11.png
    A	Media/final-images/reputations/hydraxian-waterlords-review-v2-2026-10-11.png
    A	Media/final-images/reputations/silverwing-sentinels-master.png
    A	Media/final-images/reputations/silverwing-sentinels-review.png
    A	Media/final-images/reputations/stormpike-guard-master.png
    A	Media/final-images/reputations/stormpike-guard-review.png
    A	Media/final-images/reputations/thorium-brotherhood-master.png
    A	Media/final-images/reputations/thorium-brotherhood-review.png
    A	Media/final-images/reputations/warsong-outriders-master.png
    A	Media/final-images/reputations/warsong-outriders-review.png
    A	Media/final-images/runtime-manifest.json
    A	Media/final-images/set-reviews/violet-sorcerer-review.png
    A	Media/final-images/stratholme/master.png
    A	Media/final-images/stratholme/review-2026-10-11.png
    A	Media/final-images/swift-zulian-tiger-armored-preview.png
    A	Media/final-images/swift-zulian-tiger-face-v5-preview.png
    A	Media/final-images/swift-zulian-tiger-face-v6-preview.png
    A	Media/final-images/swift-zulian-tiger-glowing-eyes.png
    A	Media/final-images/swift-zulian-tiger-helmet-v2-preview.png
    A	Media/final-images/swift-zulian-tiger-helmet-v3-preview.png
    A	Media/final-images/swift-zulian-tiger-helmet-v4-preview.png
    A	Media/final-images/tall-1200x900/README.md
    A	Media/final-images/tall-1200x900/ashbringer.jpg
    A	Media/final-images/tall-1200x900/atiesh.jpg
    A	Media/final-images/tall-1200x900/att_mc.jpg
    A	Media/final-images/tall-1200x900/benediction.jpg
    A	Media/final-images/tall-1200x900/frostsaber.jpg
    A	Media/final-images/tall-1200x900/key_scholo.jpg
    A	Media/final-images/tall-1200x900/lokdelar.jpg
    A	Media/final-images/tall-1200x900/mount_deathcharger.jpg
    A	Media/final-images/tall-1200x900/mount_dreadsteed.jpg
    A	Media/final-images/tall-1200x900/naxxramas.jpg
    A	Media/final-images/tall-1200x900/quelserrar.jpg
    A	Media/final-images/tall-1200x900/raid_aq20.jpg
    A	Media/final-images/tall-1200x900/raid_aq40.jpg
    A	Media/final-images/tall-1200x900/raid_barrow.jpg
    A	Media/final-images/tall-1200x900/raid_bwl.jpg
    A	Media/final-images/tall-1200x900/raid_hyjal.jpg
    A	Media/final-images/tall-1200x900/raid_mc.jpg
    A	Media/final-images/tall-1200x900/raid_ony.jpg
    A	Media/final-images/tall-1200x900/rep_cenarion.jpg
    A	Media/final-images/tall-1200x900/rhokdelar-hunter-review.jpg
    A	Media/final-images/tall-1200x900/rhokdelar-hunter.jpg
    A	Media/final-images/tall-1200x900/rhokdelar.jpg
    A	Media/final-images/tall-1200x900/set_tier1.jpg
    A	Media/final-images/tall-1200x900/set_violet_sorcerer.jpg
    A	Media/final-images/tall-1200x900/set_viper.jpg
    A	Media/final-images/tall-1200x900/sulfuras.jpg
    A	Media/final-images/tall-1200x900/thunderfury.jpg
    A	Media/final-images/tier-sets/aq40/tier25-review-v2.png
    A	Media/final-images/tier-sets/aq40/tier25-review.png
    A	Media/final-images/tier-sets/druid/tier1-review.png
    A	Media/final-images/tier-sets/druid/tier1.jpg
    A	Media/final-images/tier-sets/druid/tier2-review-v2.png
    A	Media/final-images/tier-sets/druid/tier2-review.png
    A	Media/final-images/tier-sets/druid/tier2.jpg
    A	Media/final-images/tier-sets/druid/tier3-horde.jpg
    A	Media/final-images/tier-sets/druid/tier3-review.png
    A	Media/final-images/tier-sets/druid/tier3.jpg
    A	Media/final-images/tier-sets/hunter/README.md
    A	Media/final-images/tier-sets/hunter/beaststalker-master.png
    A	Media/final-images/tier-sets/hunter/beaststalker-review.png
    A	Media/final-images/tier-sets/hunter/tier1.jpg
    A	Media/final-images/tier-sets/hunter/tier2.jpg
    A	Media/final-images/tier-sets/hunter/tier3.jpg
    A	Media/final-images/tier-sets/mage/README.md
    A	Media/final-images/tier-sets/mage/tier1-review.jpg
    A	Media/final-images/tier-sets/mage/tier1.jpg
    A	Media/final-images/tier-sets/mage/tier2-review.jpg
    A	Media/final-images/tier-sets/mage/tier2.jpg
    A	Media/final-images/tier-sets/mage/tier3-review.png
    A	Media/final-images/tier-sets/mage/tier3.jpg
    A	Media/final-images/tier-sets/paladin/tier1.jpg
    A	Media/final-images/tier-sets/paladin/tier2-review.png
    A	Media/final-images/tier-sets/paladin/tier2.jpg
    A	Media/final-images/tier-sets/paladin/tier3-review.png
    A	Media/final-images/tier-sets/paladin/tier3.jpg
    A	Media/final-images/tier-sets/priest/tier1-review-v2.png
    A	Media/final-images/tier-sets/priest/tier1-review-v3.png
    A	Media/final-images/tier-sets/priest/tier1-review.png
    A	Media/final-images/tier-sets/priest/tier1.jpg
    A	Media/final-images/tier-sets/priest/tier2-review-v2.png
    A	Media/final-images/tier-sets/priest/tier2-review.png
    A	Media/final-images/tier-sets/priest/tier2.jpg
    A	Media/final-images/tier-sets/priest/tier3-review.png
    A	Media/final-images/tier-sets/priest/tier3.jpg
    A	Media/final-images/tier-sets/rogue/README.md
    A	Media/final-images/tier-sets/rogue/rogue-tier1-no-signature-review-2026-10-11.png
    A	Media/final-images/tier-sets/rogue/rogue-tier1-review-2026-10-11.png
    A	Media/final-images/tier-sets/rogue/tier1-alliance-master.png
    A	Media/final-images/tier-sets/rogue/tier1.jpg
    A	Media/final-images/tier-sets/rogue/tier2.jpg
    A	Media/final-images/tier-sets/rogue/tier3.jpg
    A	Media/final-images/tier-sets/shaman/tier1-review.png
    A	Media/final-images/tier-sets/shaman/tier1.jpg
    A	Media/final-images/tier-sets/shaman/tier2-review.png
    A	Media/final-images/tier-sets/shaman/tier2.jpg
    A	Media/final-images/tier-sets/shaman/tier3-review-v2.png
    A	Media/final-images/tier-sets/shaman/tier3-review.png
    A	Media/final-images/tier-sets/shaman/tier3.jpg
    A	Media/final-images/tier-sets/warlock/tier1-alliance-review.png
    A	Media/final-images/tier-sets/warlock/tier1-alliance.jpg
    A	Media/final-images/tier-sets/warlock/tier1-review.png
    A	Media/final-images/tier-sets/warlock/tier1.jpg
    A	Media/final-images/tier-sets/warlock/tier2-alliance.jpg
    A	Media/final-images/tier-sets/warlock/tier2-review.png
    A	Media/final-images/tier-sets/warlock/tier2.jpg
    A	Media/final-images/tier-sets/warlock/tier3-alliance.jpg
    A	Media/final-images/tier-sets/warlock/tier3-review.png
    A	Media/final-images/tier-sets/warlock/tier3.jpg
    A	Media/final-images/tier-sets/warrior/tier1-review.png
    A	Media/final-images/tier-sets/warrior/tier1.jpg
    A	Media/final-images/tier-sets/warrior/tier2-alliance-review.png
    A	Media/final-images/tier-sets/warrior/tier2-alliance.jpg
    A	Media/final-images/tier-sets/warrior/tier2-review.png
    A	Media/final-images/tier-sets/warrior/tier2.jpg
    A	Media/final-images/tier-sets/warrior/tier3-review.png
    A	Media/final-images/tier-sets/warrior/tier3.jpg
    A	Media/final-images/weapons/README.md
    A	Media/final-images/weapons/ashbringer.jpg
    A	Media/final-images/weapons/atiesh.jpg
    A	Media/final-images/weapons/benediction-alliance-master.png
    A	Media/final-images/weapons/benediction-alliance-review.png
    A	Media/final-images/weapons/benediction.jpg
    A	Media/final-images/weapons/quelserrar.jpg
    A	Media/final-images/weapons/rhokdelar.jpg
    A	Media/final-images/weapons/sulfuras.jpg
    A	Media/final-images/weapons/thunderfury.jpg
    A	Media/final-images/weapons/wolfsbane-master.png
    A	Media/final-images/wolfsbane-review-2026-10-11.png
    A	Media/final-images/zul-gurub/hakkar-review.png
    A	Media/final-images/zul-gurub/hakkar.jpg
    A	Media/fishing_extravaganza-banner.blp
    A	Media/frostsaber-banner.blp
    A	Media/gold_5k-banner.blp
    A	Media/icons/note-source.png
    A	Media/icons/note-white.tga
    A	Media/icons/note.tga
    A	Media/icons/refresh-source.png
    A	Media/icons/refresh-white.tga
    A	Media/icons/refresh.tga
    A	Media/key_dm-banner.blp
    A	Media/key_scholo-banner.blp
    A	Media/key_strat-banner.blp
    A	Media/key_ubrs-banner.blp
    A	Media/lokdelar-banner.blp
    A	Media/mount_charger-banner.blp
    A	Media/mount_deathcharger-banner.blp
    A	Media/mount_dreadsteed-banner.blp
    A	Media/mount_qiraji-banner.blp
    A	Media/mount_qiraji_aq-banner.blp
    A	Media/mount_tiger-banner.blp
    A	Media/prof_alchemy-banner.blp
    A	Media/prof_blacksmithing-banner.blp
    A	Media/prof_cooking-banner.blp
    A	Media/prof_enchanting-banner.blp
    A	Media/prof_engineering-banner.blp
    A	Media/prof_engineering-horde-banner.blp
    A	Media/prof_first_aid-banner.blp
    A	Media/prof_fishing-banner.blp
    A	Media/prof_herbalism-banner.blp
    A	Media/prof_leatherworking-banner.blp
    A	Media/prof_mining-banner.blp
    A	Media/prof_tailoring-banner.blp
    A	Media/pvp_av_ally-banner.blp
    A	Media/pvp_av_horde-banner.blp
    A	Media/pvp_drums_of_war-banner.blp
    A	Media/pvp_mount_ally-banner.blp
    A	Media/pvp_set_mail_horde-banner.blp
    A	Media/pvp_set_mail_horde_shaman-banner.blp
    A	Media/pvp_shared-banner.blp
    A	Media/pvp_wsg_ally-banner.blp
    A	Media/pvp_wsg_horde-banner.blp
    A	Media/quelserrar-banner.blp
    A	Media/raid_aq20-banner.blp
    A	Media/raid_aq40-banner.blp
    A	Media/raid_barrow-banner.blp
    A	Media/raid_bwl-banner.blp
    A	Media/raid_hyjal-banner.blp
    A	Media/raid_mc-banner.blp
    A	Media/raid_naxx-banner.blp
    A	Media/raid_ony-banner.blp
    A	Media/raid_zg-banner.blp
    A	Media/rep_ambassador_ally-banner.blp
    A	Media/rep_ambassador_horde-banner.blp
    A	Media/rep_argentdawn-banner.blp
    A	Media/rep_cenarion-banner.blp
    A	Media/rep_hydraxian-banner.blp
    A	Media/rep_nozdormu-banner.blp
    A	Media/rep_thorium-banner.blp
    A	Media/rep_timbermaw-banner.blp
    A	Media/rhokdelar-banner.blp
    A	Media/set_dungeon1_hunter-banner.blp
    A	Media/set_tier1-banner.blp
    A	Media/set_tier1_druid-banner.blp
    A	Media/set_tier1_hunter-banner.blp
    A	Media/set_tier1_mage-banner.blp
    A	Media/set_tier1_paladin-banner.blp
    A	Media/set_tier1_priest-banner.blp
    A	Media/set_tier1_rogue-alliance-banner.blp
    A	Media/set_tier1_rogue-banner.blp
    A	Media/set_tier1_shaman-banner.blp
    A	Media/set_tier1_warlock-alliance-banner.blp
    A	Media/set_tier1_warlock-banner.blp
    A	Media/set_tier1_warrior-banner.blp
    A	Media/set_tier25-banner.blp
    A	Media/set_tier2_druid-banner.blp
    A	Media/set_tier2_hunter-banner.blp
    A	Media/set_tier2_mage-banner.blp
    A	Media/set_tier2_paladin-banner.blp
    A	Media/set_tier2_priest-banner.blp
    A	Media/set_tier2_rogue-banner.blp
    A	Media/set_tier2_shaman-banner.blp
    A	Media/set_tier2_warlock-alliance-banner.blp
    A	Media/set_tier2_warlock-banner.blp
    A	Media/set_tier2_warrior-alliance-banner.blp
    A	Media/set_tier2_warrior-banner.blp
    A	Media/set_violet_sorcerer-banner.blp
    A	Media/set_viper-banner.blp
    A	Media/sulfuras-banner.blp
    A	Media/thunderfury-banner.blp
    A	Media/tier3-banner.blp
    A	Media/tier3_druid-banner.blp
    A	Media/tier3_druid-horde-banner.blp
    A	Media/tier3_hunter-banner.blp
    A	Media/tier3_mage-banner.blp
    A	Media/tier3_paladin-banner.blp
    A	Media/tier3_priest-banner.blp
    A	Media/tier3_rogue-banner.blp
    A	Media/tier3_shaman-banner.blp
    A	Media/tier3_warlock-alliance-banner.blp
    A	Media/tier3_warlock-banner.blp
    A	Media/tier3_warrior-banner.blp
    A	Media/wolfsbane-banner.blp
    M	Npcs.lua
    M	Quests.lua
    M	README.md
    M	README.txt
    M	ROADMAP.md
    M	Screenshots/01-my-goals.png
    M	Screenshots/02-new-and-updated.png
    M	Screenshots/03-epic-mounts.png
    M	Screenshots/04-links-and-tips.png
    M	Screenshots/05-find-your-next-goal.png
    M	Screenshots/06-welcome.png
    M	Screenshots/07-suggestions.png
    A	Screenshots/08-settings.png
    A	reports/Armor artwork identifications.md
    A	reports/Armor set goals.json
    A	reports/Armor set goals.md
    A	reports/Code-quality-review-2026-10-11.md
    A	reports/CurseForge-description-2.10.0.md
    A	reports/CurseForge-description-2.11.0.md
    A	reports/CurseForge-description-2.11.1.md
    A	reports/Forever build 70291 compatibility.md
    A	reports/Forever-dependency-native-review-2026-10-11.md
    A	reports/Forever-dependency-review-2026-10-12.md
    A	reports/Forever-racial-mount-costs-2026-10-12.md
    A	reports/Goal banner catalog.json
    A	reports/Goal banner shot list.csv
    A	reports/Goal banner shot list.md
    A	reports/Goal step dependency audit.csv
    A	reports/Goal step dependency audit.json
    A	reports/Goal step dependency audit.md
    A	reports/Goal step dependency audit.validation.json
    A	reports/New artwork review 2026-10-08.md
    A	reports/Session-handoff-2026-10-10.md
    A	reports/Session-handoff-2026-10-11.md
    A	reports/Wolfsbane-2026-10-11.md
    A	reports/banner-image-gaps-2026-10-09.md
    A	reports/checks/alchemy-first-aid-cooking-install-2026-10-11.txt
    A	reports/checks/alliance-priest-banner-2026-10-11.txt
    A	reports/checks/artist-credit-reveal-2026-10-11.txt
    A	reports/checks/beaststalker-banner-2026-10-11.txt
    A	reports/checks/blackrock-spire-banner-install-2026-10-11.txt
    A	reports/checks/brood-nozdormu-install-2026-10-11.txt
    A	reports/checks/bwl-key-art-banner-2026-10-11.txt
    A	reports/checks/cenarion-circle-install-2026-10-11.txt
    A	reports/checks/copy-mechanics-2026-10-12.json
    A	reports/checks/copy-pass-2026-10-12.txt
    A	reports/checks/dwarf-hunter-leveling-banner-2026-10-11.txt
    A	reports/checks/engineering-banner-install-2026-10-11.txt
    A	reports/checks/engineering-horde-banner-install-2026-10-11.txt
    A	reports/checks/fishing-banner-install-2026-10-11.txt
    A	reports/checks/font-startup-fix-2026-10-11.txt
    A	reports/checks/forever-dependency-preview-2026-10-12.txt
    A	reports/checks/forever-dependency-rollout-2026-10-11.txt
    A	reports/checks/forever-mount-costs-2026-10-12.txt
    A	reports/checks/goals-list-40-2026-10-11.txt
    A	reports/checks/goals-list-50-2026-10-11.txt
    A	reports/checks/herbalism-banner-install-2026-10-11.txt
    A	reports/checks/hydraxian-waterlords-install-2026-10-11.txt
    A	reports/checks/live-review-fixes-2026-10-11.txt
    A	reports/checks/materials-arrow-2026-10-11.txt
    A	reports/checks/materials-fade-2026-10-11.txt
    A	reports/checks/materials-panel-2026-10-11.txt
    A	reports/checks/materials-slide-fix-2026-10-11.txt
    A	reports/checks/mining-banner-install-2026-10-11.txt
    A	reports/checks/modern-withdrawal-2026-10-11.txt
    A	reports/checks/mount-credit-guide-2026-10-11.txt
    A	reports/checks/personal-note-icon-2026-10-12.txt
    A	reports/checks/profession-art-selection-2026-10-11.txt
    A	reports/checks/profession-scan-fix-2026-10-11.txt
    A	reports/checks/release-2.11.1-annotation-loading.txt
    A	reports/checks/release-2.11.1-api-review.md
    A	reports/checks/release-2.11.1-code-2026-10-11.txt
    A	reports/checks/release-2.11.1-luals-config.json
    A	reports/checks/release-2.11.1-luals-diagnostics.json
    A	reports/checks/release-2.11.1-luals-era-run.txt
    A	reports/checks/release-2.11.1-luals-forever-diagnostics.json
    A	reports/checks/release-2.11.1-luals-forever-run.txt
    A	reports/checks/release-2.11.1-luals-initial-diagnostics.json
    A	reports/checks/release-2.11.1-luals-run.txt
    A	reports/checks/release-2.11.1-package.json
    A	reports/checks/release-2.11.1-published.json
    A	reports/checks/reputation-banners-2026-10-11.txt
    A	reports/checks/rogue-art-credit-2026-10-11.txt
    A	reports/checks/seven-banner-install-2026-10-11.txt
    A	reports/checks/stratholme-key-banner-install-2026-10-11.txt
    A	reports/checks/type-style-2026-10-12.txt
    A	reports/checks/warcraft-heading-font-2026-10-11.txt
    A	reports/checks/warcraft-panel-width-2026-10-11.txt
    A	reports/checks/warlord-shaman-devout-banner-install-2026-10-11.txt
    A	reports/checks/wider-goals-list-2026-10-11.txt
    A	reports/checks/wider-goals-list-followup-2026-10-11.txt
    A	reports/checks/window-bounds-2026-10-12.txt
    A	reports/checks/wolfsbane-2026-10-11.log
    A	reports/checks/wolfsbane-banner-2026-10-11.log
    A	reports/checks/wolfsbane-training-2026-10-11.txt
    A	reports/copy-edits-2026-10-12.json
    A	reports/copy-pass-2026-10-12.md
    A	reports/image-tests/additional-banner-pass-before-after.jpg
    A	reports/image-tests/additional-banner-pass.json
    A	reports/image-tests/alchemy-first-aid-cooking-2026-10-11.json
    A	reports/image-tests/alliance-priest-banner-2026-10-11.json
    A	reports/image-tests/ambassador-2026-10-10.json
    A	reports/image-tests/ambassador-final-2026-10-10.json
    A	reports/image-tests/ambassador-revision-2026-10-10.json
    A	reports/image-tests/ancient-book-clasp-install-2026-10-10.json
    A	reports/image-tests/ancient-book-empty-state-2026-10-10.json
    A	reports/image-tests/ancient-book-in-tracker-mockup-2026-10-10.json
    A	reports/image-tests/ancient-book-install-2026-10-10.json
    A	reports/image-tests/ancient-book-no-spine-2026-10-10.json
    A	reports/image-tests/ancient-book-spine-install-2026-10-10.json
    A	reports/image-tests/aq-banner-install-check.txt
    A	reports/image-tests/aq-mage-banner-pass-2026-10-09.json
    A	reports/image-tests/aq40-tier25-2026-10-10.json
    A	reports/image-tests/aq40-tier25-correction-2026-10-10.json
    A	reports/image-tests/aq40-tier25-generated-v2.png
    A	reports/image-tests/aq40-tier25-generated.png
    A	reports/image-tests/argent-dawn-pass-2026-10-09.json
    A	reports/image-tests/argent-dawn-pass-v2-2026-10-09.json
    A	reports/image-tests/argent-dawn-pass-v3-2026-10-09.json
    A	reports/image-tests/armor-set-check.txt
    A	reports/image-tests/art-search-0.jpg
    A	reports/image-tests/art-search-1.jpg
    A	reports/image-tests/art-search-2.jpg
    A	reports/image-tests/art-search-3.jpg
    A	reports/image-tests/art-search-4.jpg
    A	reports/image-tests/artist-credit-check.txt
    A	reports/image-tests/banner-bounds-fade-check.txt
    A	reports/image-tests/banner-build-2026-10-09.md
    A	reports/image-tests/banner-gap-audit-2026-10-09.json
    A	reports/image-tests/banner-soft-bottom-check.txt
    A	reports/image-tests/banner-visibility-fix-check.txt
    A	reports/image-tests/banner-visible-bottom-check.txt
    A	reports/image-tests/beaststalker-banner-2026-10-11.json
    A	reports/image-tests/black-qiraji-install-check.txt
    A	reports/image-tests/black-qiraji-review.json
    A	reports/image-tests/blackrock-spire-banner-2026-10-11.json
    A	reports/image-tests/blackwing-lair-after-1200x800.jpg
    A	reports/image-tests/blackwing-lair-before-after.png
    A	reports/image-tests/brood-nozdormu-2026-10-11.json
    A	reports/image-tests/bwl-key-art-banner-2026-10-11.json
    A	reports/image-tests/cenarion-circle-2026-10-11.json
    A	reports/image-tests/character-banner-check.txt
    A	reports/image-tests/class-label-check.txt
    A	reports/image-tests/deathcharger-banner-pass-2026-10-09.json
    A	reports/image-tests/deathcharger-install-check.txt
    A	reports/image-tests/dreadsteed-credit-pass-2026-10-09.json
    A	reports/image-tests/dreadsteed-install-check.txt
    A	reports/image-tests/druid-tier-pass-2026-10-09.json
    A	reports/image-tests/druid-tier1-install-check.txt
    A	reports/image-tests/druid-tier2-install-check.txt
    A	reports/image-tests/druid-tier2-staff-repair-2026-10-09.json
    A	reports/image-tests/druid3-shaman1-install-check.txt
    A	reports/image-tests/dwarf-hunter-leveling-banner-2026-10-11.json
    A	reports/image-tests/dwarf-ram-pass-2026-10-09.json
    A	reports/image-tests/dwarf-ram-tcg-install-check.txt
    A	reports/image-tests/dwarf-ram-tcg-pass-2026-10-09.json
    A	reports/image-tests/dwarf-shaman-install-check.txt
    A	reports/image-tests/dwarf-shaman-leveling-review.json
    A	reports/image-tests/engineering-banner-2026-10-11.json
    A	reports/image-tests/engineering-horde-banner-2026-10-11.json
    A	reports/image-tests/export-additional-banner-pass.py
    A	reports/image-tests/export-hunter-tier-pass.py
    A	reports/image-tests/export-molten-core-pass.py
    A	reports/image-tests/export-rogue-tier-pass.py
    A	reports/image-tests/export-taller-banner-pass.py
    A	reports/image-tests/export-weapon-pass.py
    A	reports/image-tests/faction-banner-check.txt
    A	reports/image-tests/faction-cutouts-2026-10-10.json
    A	reports/image-tests/faction-soft-watermarks-2026-10-10.json
    A	reports/image-tests/felheart-alliance-install-check.txt
    A	reports/image-tests/felheart-alliance-pass-2026-10-09.json
    A	reports/image-tests/fishing-banner-2026-10-11.json
    A	reports/image-tests/fishing-extravaganza-2026-10-10.json
    A	reports/image-tests/fishing-extravaganza-generated.png
    A	reports/image-tests/forever-70291-check.txt
    A	reports/image-tests/four-banner-install-check.txt
    A	reports/image-tests/four-banner-review-2026-10-09.json
    A	reports/image-tests/frostwolf-2026-10-10.json
    A	reports/image-tests/gnome-mechanostrider-install-check.txt
    A	reports/image-tests/gnome-mechanostrider-pass-2026-10-09.json
    A	reports/image-tests/goal-image-fade-check.txt
    A	reports/image-tests/gold-goal-clean-review.json
    A	reports/image-tests/gold-goal-install-check.txt
    A	reports/image-tests/gold-goal-review.json
    A	reports/image-tests/hakkar-pass-2026-10-09.json
    A	reports/image-tests/herbalism-banner-2026-10-11.json
    A	reports/image-tests/human-palomino-pass-2026-10-09.json
    A	reports/image-tests/human-palomino-pass-v2-2026-10-09.json
    A	reports/image-tests/hunter-tier-pass.json
    A	reports/image-tests/hunter-tier3-cryptstalker.json
    A	reports/image-tests/hydraxian-waterlords-2026-10-11.json
    A	reports/image-tests/hydraxian-waterlords-v2-2026-10-11.json
    A	reports/image-tests/mage-tier-pass.json
    A	reports/image-tests/mage-tier3-install-check.txt
    A	reports/image-tests/mining-banner-2026-10-11.json
    A	reports/image-tests/molten-core-install-check.txt
    A	reports/image-tests/molten-core-pass-before-after.jpg
    A	reports/image-tests/molten-core-pass-manifest.json
    A	reports/image-tests/mount-banner-pass-2026-10-09.json
    A	reports/image-tests/naxxramas-banner-pass-2026-10-09.json
    A	reports/image-tests/naxxramas-install-check.txt
    A	reports/image-tests/nightelf-nightsaber-pass-2026-10-09.json
    A	reports/image-tests/onyxia-replacement.json
    A	reports/image-tests/orc-wolf-pass-2026-10-09.json
    A	reports/image-tests/paladin-tier2-pass-2026-10-09.json
    A	reports/image-tests/paladin-tier3-pass-2026-10-09.json
    A	reports/image-tests/panel-inner-shadow-check.txt
    A	reports/image-tests/priest-tier1-install-check.txt
    A	reports/image-tests/priest-tier1-pass-2026-10-09.json
    A	reports/image-tests/priest-tier1-v2-pass-2026-10-09.json
    A	reports/image-tests/priest-tier1-v3-pass-2026-10-09.json
    A	reports/image-tests/priest-tier2-install-check.txt
    A	reports/image-tests/priest-tier2-pass-2026-10-09.json
    A	reports/image-tests/priest-tier2-v2-pass-2026-10-09.json
    A	reports/image-tests/priest-tier3-install-check.txt
    A	reports/image-tests/priest-tier3-pass-2026-10-09.json
    A	reports/image-tests/profession-mount-raid-banners-2026-10-11.json
    A	reports/image-tests/pvp-drums-of-war-install-check.txt
    A	reports/image-tests/pvp-drums-of-war-review.json
    A	reports/image-tests/pvp-warlord-mail-clean-review.json
    A	reports/image-tests/pvp-warlord-mail-install-check.txt
    A	reports/image-tests/pvp-warlord-mail-review.json
    A	reports/image-tests/raid-banner-install-check.txt
    A	reports/image-tests/raid-banner-pass-2026-10-09.json
    A	reports/image-tests/reputation-banners-2026-10-11.json
    A	reports/image-tests/rhokdelar-hunter-review.md
    A	reports/image-tests/rhokdelar-string-review-v2.jpg
    A	reports/image-tests/rhokdelar-string-review-v3.jpg
    A	reports/image-tests/rogue-signature-removal-2026-10-11.json
    A	reports/image-tests/rogue-tier-pass.json
    A	reports/image-tests/scarab-lord-2026-10-10.json
    A	reports/image-tests/scarab-lord-generated.png
    A	reports/image-tests/seven-banner-install-check.txt
    A	reports/image-tests/seven-banner-reviews.json
    A	reports/image-tests/shaman-tier1-pass-2026-10-09.json
    A	reports/image-tests/shaman-tier2-install-check.txt
    A	reports/image-tests/shaman-tier2-pass-2026-10-09.json
    A	reports/image-tests/shaman-tier3-pass-2026-10-09.json
    A	reports/image-tests/shaman-tier3-pass-v2-2026-10-09.json
    A	reports/image-tests/shared-pvp-pass-2026-10-09.json
    A	reports/image-tests/short-window-check.txt
    A	reports/image-tests/stratholme-banner-2026-10-11.json
    A	reports/image-tests/swift-zulian-tiger-armored-preview.md
    A	reports/image-tests/swift-zulian-tiger-face-v5.md
    A	reports/image-tests/swift-zulian-tiger-face-v6.md
    A	reports/image-tests/swift-zulian-tiger-glowing-eyes.md
    A	reports/image-tests/swift-zulian-tiger-helmet-v2.md
    A	reports/image-tests/swift-zulian-tiger-helmet-v3.md
    A	reports/image-tests/swift-zulian-tiger-helmet-v4.md
    A	reports/image-tests/taller-banner-pass.json
    A	reports/image-tests/taller-banner-review-1.jpg
    A	reports/image-tests/taller-banner-review-2.jpg
    A	reports/image-tests/tauren-kodo-pass-2026-10-09.json
    A	reports/image-tests/tier3-unapproved-fallback-check.txt
    A	reports/image-tests/timbermaw-install-check.txt
    A	reports/image-tests/timbermaw-review.json
    A	reports/image-tests/troll-mage-install-check.txt
    A	reports/image-tests/troll-mage-pass-2026-10-09.json
    A	reports/image-tests/troll-raptor-pass-2026-10-09.json
    A	reports/image-tests/undead-paladin-painted-review.json
    A	reports/image-tests/violet-sorcerer-2026-10-09.json
    A	reports/image-tests/violet-sorcerer-check.txt
    A	reports/image-tests/violet-sorcerer-install-check.txt
    A	reports/image-tests/warlock-install-check.txt
    A	reports/image-tests/warlock-tier-pass-2026-10-09.json
    A	reports/image-tests/warlock-tier3-pass-2026-10-09.json
    A	reports/image-tests/warlord-mail-shaman-banner-2026-10-11.json
    A	reports/image-tests/warlord-mail-shaman-signature-removal-2026-10-11.json
    A	reports/image-tests/warrior-install-check.txt
    A	reports/image-tests/warrior-tier-pass-2026-10-09.json
    A	reports/image-tests/warrior-tier2-alliance-pass-2026-10-09.json
    A	reports/image-tests/warrior-tier3-install-check.txt
    A	reports/image-tests/warrior-tier3-pass-2026-10-09.json
    A	reports/image-tests/weapon-pass-before-after.jpg
    A	reports/image-tests/weapon-pass-manifest.json
    A	reports/image-tests/wide-artwork-search.jpg
    A	reports/image-tests/wolfsbane-banner-2026-10-11.json
    A	reports/live-review-fixes-2026-10-11.md
    A	reports/materials-panel-2026-10-11.md
    A	reports/modern-withdrawal-2026-10-11.md
    A	reports/release-2.10.0-check.txt
    A	reports/screenshots-2.10.0-review.jpg
    A	reports/type-style-groundwork-2026-10-12.md
    A	reports/warcraft-heading-font-2026-10-11.md
    A	reports/window-size-bounds-2026-10-12.md
    A	research_notes/Goal step dependency audit/address_inventory.py
    A	research_notes/Goal step dependency audit/addresses.json
    A	research_notes/Goal step dependency audit/catalogue.json
    A	research_notes/Goal step dependency audit/extract_catalogue.py
    A	research_notes/Goal step dependency audit/inventory_assertions.json
    A	research_notes/Goal step dependency audit/parallel_dependencies.md
    A	research_notes/Goal step dependency audit/parallel_step_audit.json
    A	research_notes/Goal step dependency audit/per_goal_overview.md
    A	research_notes/Goal step dependency audit/quest_dependencies.md
    A	research_notes/Goal step dependency audit/quest_dependency_edges.json
    A	research_notes/Goal step dependency audit/quest_owned_ids.json
    A	research_notes/Goal step dependency audit/quest_step_audit.json
    A	research_notes/Goal step dependency audit/raid_set_addresses.md
    A	research_notes/Goal step dependency audit/raid_set_dependencies.md
    A	research_notes/Goal step dependency audit/raid_set_step_audit.json
    A	research_notes/Goal step dependency audit/raid_set_step_audit.py
    A	research_notes/Goal step dependency audit/synthesize_report.py
    A	research_notes/Goal step dependency audit/write_quest_notes.py
    A	tools/aq-armor-tests.lua
    A	tools/armor-tests.lua
    A	tools/artwork.py
    A	tools/banner-art.md
    A	tools/banner-tests.lua
    M	tools/check.py
    A	tools/completed-step-motion-tests.lua
    A	tools/completed-step-tests.lua
    A	tools/copy-audit.py
    A	tools/dependency-tests.lua
    A	tools/empty-book-tests.lua
    A	tools/fishing-tests.lua
    A	tools/forever-dependency-rollout-tests.lua
    A	tools/guide-edit-tests.lua
    A	tools/item-tooltip-tests.lua
    A	tools/materials-tests.lua
    A	tools/mount-cost-tests.lua
    A	tools/mount-preview-tests.lua
    A	tools/qiraji-tests.lua
    A	tools/refresh.py
    A	tools/short-window-tests.lua
    A	tools/shotlist.py
    M	tools/shots.py
    A	tools/type-style-tests.lua
    A	tools/window-size-tests.lua
    A	tools/wolfsbane-tests.lua
    M	tools/wowstub.lua
