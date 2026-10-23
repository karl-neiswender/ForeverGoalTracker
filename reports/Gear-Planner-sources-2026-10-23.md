# Gear Planner: item sources from warcraftdb

Unreleased, October 23, 2026 (Claude, PC). Karl asked for the planner's item sources (boss,
dungeon or raid, quest) to come from [classic.warcraftdb.com](https://classic.warcraftdb.com/),
then added [forever.warcraftdb.com](https://forever.warcraftdb.com/) from the same people.
No release or tag.

## What changed

| File | Job |
| --- | --- |
| `tools/sourcedb.py` | Reads each planner item's Source, Dropped By, Reward From, Sold By and Contained In tabs from the sites' public JSON API (`/api/data/node/item/<id>` and `/tab/<slug>`). Caches one JSON file per item in `tools/.cache/warcraftdb/item` (Classic) and `.../forever` (ignored), so reruns fetch only what is missing. Four requests at a time for Classic, two for Forever, a quarter second apart. |
| `GearSources.lua` | Generated, do not edit. `FGT.GEARSOURCES` (Classic Era) and `FGT.GEARSOURCES_FOREVER`, one line per item: `id\|kind\|who\|place\|detail`. Loaded after `GearData.lua` (TOC, `tools/check.py`). |
| `GearCatalog.lua` | `Imported(id)` looks a line up only when an item is shown and keeps the result until `C.Release` (planner closes). |

Regenerate: `python3 tools/sourcedb.py` (both sites), `python3 tools/sourcedb.py forever` (one site),
`python3 tools/sourcedb.py --offline` (cache only). Run it again after `geardb.py` adds items.

## Rules

- Order in `C.Source`: hand-checked, Library sets, then an imported boss or quest, then the game's
  recipe, then the game's PvP rank (an imported quartermaster becomes the tip "Sold by ..."), then
  any other imported source, else Source unknown.
- Boss (from the site's Encounter Journal data): "Loot X from Garr in Molten Core", label
  "Garr · Molten Core". Two bosses say "A or B"; more say "a boss", label "Bosses · Molten Core".
  Stratholme and Scarlet Monastery keep the wing in the step. The site's instance names map to
  `FGT.DUNGEONS` names (`PLACE` in the tool), so every boss source gets the map pin on its picker
  row and its dungeon or raid name becomes a map link in goal steps (the existing `LinkDungeons`
  and `TagPlaces` path). All 29 instances in the data resolve.
- Quest: "Complete 'Name' in Zone for X", label "Quest · Zone". The site's class quest categories
  (Rogue, Shaman, ...) are not zones. Quests in a dungeon zone get the pin too.
- Dropped by more than 8 creatures and no boss: World drop. Fewer: "Drop · Name". The site has no
  creature locations for Classic, so named non-boss drops (Shadow Hunter Vosh'gajin) name no dungeon.
- Vendor: "Buy X from Name in Zone", label "Vendor · Zone".
- Forever client: Forever's quest or vendor line first. Its drops are loot players saw in the beta
  (each row has a sample like "4 / 15"), so a Classic line beats them; alone they carry the tip
  "Seen in the WoW Forever beta." A Classic line on Forever carries "Classic Era source;
  Unconfirmed in WoW Forever."

## Results

- Classic: 7,797 items fetched, 6,803 with a source: 1,511 boss, 1,438 quest, 2,790 world drop,
  425 named drop, 630 vendor, 9 container. Of the rest, 626 are crafted (the planner already says
  "<Profession> · craft or buy") and 365 have no source on the site.
- Forever: 4,820 items found (the 90 unrevealed Hyjal pieces are not there), 585 with a source:
  488 quest, 87 vendor, 10 beta drops. No boss data. 1,353 are crafted (recipes cover them).
  Of 368 items in both lists, 35 differ: Forever's own quest names ("WANTED: \"Hogger\"") and
  vendors named where Classic listed several. All 10 beta drops are Classic world drops seen on
  one or two creatures, so the Classic world drop wins.
- `GearSources.lua` is about 200 KB; one string per client, searched per item, no table built.
- The Forever site only lists items Forever's client has revealed, the same split as GearData's
  Forever status. It has no source for Thunderfury or Tier 3 yet.

## Keeping it current (Karl, 2026-10-23)

- Scheduled task "Gear Planner sources refresh" (desktop app, this PC): 7 AM and 9 PM from
  2026-11-04. Evenings only in launch week (Nov 4 to 17) and raid weeks (Dec 9 to 22, new raids).
  No commits; it restores the backups if `check.py` fails.
- `geardb.py --forever-build latest` rebuilds `GearData.lua` only when wago.tools (product `wowf`)
  has a newer Forever build. The tables cache now records its build (`tools/.cache/*-build.txt`),
  and `geardb.py` never goes below the build `GearData.lua` already names. Verified: with no new
  build it stops; a plain rebuild reproduces today's file byte for byte.
- `sourcedb.py --refresh-forever` asks again only for items without a source. Mondays, new
  builds and the first run after Dec 9 refetch every Forever item instead.
- Imported drops from a boss in `BOSS_PLACE` get that raid and pin. Forever's new raid bosses must
  be added there by hand, with an entrance in `FGT.DUNGEONS`; the task lists unplaced ones.
- Each client its own item (Karl: Classic uses Classic data, Forever uses Forever data; an item
  in Forever is the same, updated or new). `geardb.py` builds every shared item from both
  clients' tables. Classic lines in `blocks` are unchanged byte for byte. Where Forever differs,
  its version goes in `foreverBlocks` (same line format): flag 4 "Updated in Forever" for a
  change a player would notice (quality, item level, required level, name, type, class limit,
  slot, set, binding, faction, main stats by more than 1), flag 1 for equip-bonus differences
  only (the clients store those differently). The Forever client reads those lines in place
  of the Classic ones (`Replaced`, `Block`, `C.Get`); `Record` maps 4 to forever 1 plus
  `updated`, and `ForeverStatus` returns "updated". Beta build: 692 updated, 126 quiet, 97 of
  them gear only in Forever's version. 211 updates are PvP pieces: Forever's sets list new
  "Premier" items instead, so the old pieces have no set there.
- Forever stats: Forever's ItemSparse has no stat amounts. Each stat is a share
  (`StatPercentEditor`, 1/10000) of the RandPropPoints budget for its item level, quality and
  slot; equip bonuses are stats too (45 spell power, 41 healing, 42 spell damage, 38 and 39
  attack power, 12 defense; hit 10, crit 14, dodge 12, parry 15, block 5 rating per 1%).
  Checked on shared items: 2,365 of 2,576 match Classic exactly. The 1,661 Forever-only
  items had no stats before; they do now. `GearData.lua` is about 805 KB (was about 726).
- Beta-seen drops now say "Seen by WoW Forever players; Unconfirmed in the game's own data."

## Terms

Neither site publishes terms of use (warcraftdb.com has only a privacy policy) and both robots.txt
files allow everything. This differs from wowclassicdatabase.com, ruled out for its personal-use
terms. Suggestion: credit warcraftdb in the CurseForge description, or ask them, before 2.16.0.

## Checks

`python3 tools/check.py` passes on both clients. New coverage in `tools/gear-planner-tests.lua`:
imported boss label and step, raid pin (Zul'Gurub), several bosses, world drop without a pin, PvP
rank with the quartermaster tip, each client's own quest name, beta drops not replacing a world
drop, and the Forever Unconfirmed note. LuaLS not run (no API or hook
changes). Not seen in the game.

## Native review

1. `/reload`, Gear Planner, a slot: most rows now name a boss, quest, vendor or World drop.
2. A dungeon or raid row shows the pin; clicking it sets the map pin.
3. Add a set to Goals: boss steps link the dungeon or raid name to the map.
4. Forever (after launch): a hover tip says Seen in the beta or Unconfirmed where it applies.
