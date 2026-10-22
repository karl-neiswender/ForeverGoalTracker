#!/usr/bin/env python3
"""Build GearData.lua, the Gear Planner's item database.

Source: wago.tools' public exports of the game's own client tables
(ItemSparse, Item, ItemSet, Faction) for Classic Era 1.15.9 and WoW Forever
1.60.1. Nothing is read from Wowhead.

  - Classic Era is complete (names, quality, slot, class limits), so it is the
    base. Season of Discovery ids (200000+) are dropped unless Forever has them.
  - Forever's tables are partly empty: items stay hidden until a player finds
    one after launch. An item that Forever's tables name is marked "in Forever"
    (flag 1); one that only Forever has is "new" (flag 2). Anything else is
    Classic only and shows as "Not revealed yet" on the Forever client.

Run:  python3 tools/geardb.py          (downloads once into tools/.cache)
"""
import csv, os, re, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, ".cache")
OUT = os.path.join(HERE, "..", "GearData.lua")
BUILDS = {"era": "1.15.9.70003", "forever": "1.60.1.70532"}

os.makedirs(CACHE, exist_ok=True)


def table(client, name):
    path = os.path.join(CACHE, "%s-%s.csv" % (client, name))
    if not os.path.exists(path):
        url = "https://wago.tools/db2/%s/csv?build=%s" % (name, BUILDS[client])
        print("downloading", url, file=sys.stderr)
        with urllib.request.urlopen(url, timeout=120) as r, open(path, "wb") as f:
            f.write(r.read())
        time.sleep(1.5)  # be gentle with the host
    with open(path, newline="", encoding="utf-8") as f:
        return {row["ID"]: row for row in csv.DictReader(f)}


era_sparse, era_item = table("era", "ItemSparse"), table("era", "Item")
for_sparse, for_item = table("forever", "ItemSparse"), table("forever", "Item")
era_sets, for_sets = table("era", "ItemSet"), table("forever", "ItemSet")
era_fac, for_fac = table("era", "Faction"), table("forever", "Faction")

# Inventory types the planner can show (bags, ammo and quivers are not gear).
INV_OK = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28}  # 24 = ammo
# Quivers and ammo pouches (class 11) are bags to the game (inventory type 18); the planner
# files them under 27, the game's quiver type, so they get a slot of their own.
QUIVER_INV = 27
JUNK = re.compile(
    r"^(\(?(old|deprecated|test|dep|unused|zz)\b|\[(PH|TMP|DNT)\]|monster\b|npc\b|qa\b|\*\*|\d+ )"
    r"|\((old|test)\)|deprecated|depricated|\bunused\b|^hidden |\bdnd\b|\bPH\b", re.I)
REP = {4: "Friendly", 5: "Honored", 6: "Revered", 7: "Exalted"}
SKILL = {164: "Blacksmithing", 165: "Leatherworking", 197: "Tailoring", 171: "Alchemy",
         202: "Engineering", 333: "Enchanting", 755: "Jewelcrafting", 185: "Cooking",
         129: "First Aid", 356: "Fishing", 186: "Mining", 182: "Herbalism", 393: "Skinning"}
# Race masks (bit n-1 = race id n): Alliance Human 1, Dwarf 3, Night Elf 4, Gnome 7,
# Draenei 11; Horde Orc 2, Undead 5, Tauren 6, Troll 8, Blood Elf 10.
ALL_CLASSES = 1 | 2 | 4 | 8 | 16 | 64 | 128 | 256 | 1024  # the nine Classic classes
ALLIANCE = 1 | 4 | 8 | 64 | 1024
HORDE = 2 | 16 | 32 | 128 | 512


def num(row, key, default=0):
    try:
        return int(row.get(key, default) or default)
    except ValueError:
        return default


# Classic PvP gear carries no race limit in the tables; its faction is in the rank's name.
PVP_ALLIANCE = re.compile(r"\b(Marshal's|Knight-\w+'s|Knight's|Lieutenant Commander's|Commander's|"
                          r"Master Sergeant's|Sergeant Major's|Private's|Corporal's)")
PVP_HORDE = re.compile(r"\b(Warlord's|General's|Champion's|Centurion's|Legionnaire's|Blood Guard's|"
                       r"Stone Guard's|Scout's|Grunt's|First Sergeant's|Senior Sergeant's)")


def faction_of(row):
    mask = num(row, "AllowableRace_0", -1)
    if mask not in (-1, 0) and mask < 2 ** 31:
        if mask & ALLIANCE and not mask & HORDE:
            return "A"
        if mask & HORDE and not mask & ALLIANCE:
            return "H"
        return ""
    if num(row, "RequiredPVPRank") >= 5 or num(row, "OppositeFactionItemID") or row["Display_lang"].startswith("Premier "):
        name = row["Display_lang"]
        if PVP_ALLIANCE.search(name) and not PVP_HORDE.search(name):
            return "A"
        if PVP_HORDE.search(name) and not PVP_ALLIANCE.search(name):
            return "H"
    return ""


def clean(name):
    return name.replace("|", "/").replace("\n", " ").strip()


def note_for(row, factions):
    bits = []
    rep, fid = num(row, "MinReputation"), num(row, "MinFactionID")
    if fid and rep in REP and fid in factions:
        bits.append("Requires %s with %s" % (REP[rep], factions[fid]))
    rank = num(row, "RequiredPVPRank")
    if rank >= 5:
        bits.append("Requires PvP rank %d" % (rank - 4))
    skill, srank = num(row, "RequiredSkill"), num(row, "RequiredSkillRank")
    if skill in SKILL:
        bits.append("Requires %s%s" % (SKILL[skill], " (%d)" % srank if srank > 1 else ""))
    return "; ".join(bits)


faction_names = {}
for fid, row in list(era_fac.items()) + list(for_fac.items()):
    faction_names[int(fid)] = row["Name_lang"]

items, sets_used = {}, {}


def consider(item_id, sparse, item, source_flag):
    row, meta = sparse[item_id], item.get(item_id)
    if not meta:
        return
    inv = num(meta, "InventoryType")
    if meta["ClassID"] == "11":
        inv = QUIVER_INV
    # gear is weapons (2) and armor (4); arrows and bullets are projectiles (6), quivers 11
    if inv not in INV_OK or meta["ClassID"] not in (("6",) if inv == 24 else ("11",) if inv == QUIVER_INV else ("2", "4")):
        return
    name = clean(row["Display_lang"])
    if not name or JUNK.search(name) or num(row, "Flags_0") & 0x10:
        return
    quality, ilvl, req = num(row, "OverallQualityID"), num(row, "ItemLevel"), num(row, "RequiredLevel")
    set_id = num(row, "ItemSet")
    cosmetic = inv in (4, 19, 24, QUIVER_INV)  # shirts, tabards, ammo and quivers: any quality
    if quality > 5 or quality < (1 if cosmetic else 2) or (ilvl <= 0 and not cosmetic):
        return
    if quality == 2 and not (req >= 35 or set_id or cosmetic):
        return
    # Armor must be a real armor type (cloth..plate, shields, relics); skip class 4/0 junk
    # except neck, finger, trinket, back, shirt, tabard and off-hand held items.
    sub = int(meta["ClassID"]) * 100 + num(meta, "SubclassID")
    mask = num(row, "AllowableClass", -1)
    if mask <= 0 or mask >= 2 ** 31 or mask & ALL_CLASSES == ALL_CLASSES:
        mask = 0  # no class limit
    items[int(item_id)] = dict(
        id=int(item_id), inv=inv, q=quality, ilvl=ilvl, req=req, mask=mask, sub=sub,
        icon=num(meta, "IconFileDataID"), flag=source_flag, set=set_id, fac=faction_of(row),
        uniq=1 if num(row, "MaxCount") == 1 else 0, name=name, note=note_for(row, faction_names))


for item_id in era_sparse:
    forever_has = item_id in for_sparse and for_sparse[item_id]["Display_lang"]
    if int(item_id) >= 200000 and not forever_has:
        continue  # Season of Discovery
    consider(item_id, era_sparse, era_item, 1 if forever_has else 0)
for item_id in for_sparse:
    if item_id not in era_sparse and for_sparse[item_id]["Display_lang"]:
        consider(item_id, for_sparse, for_item, 2)

# Forever's raid sets exist in its Item table but have no names yet (hidden until found after
# launch). The Library already carries their names, classes and icons, so those fill the gaps.
CLASS_BITS = {"Warrior": 1, "Paladin": 2, "Hunter": 4, "Rogue": 8, "Priest": 16, "Shaman": 64,
              "Mage": 128, "Warlock": 256, "Druid": 1024}
library = open(os.path.join(HERE, "..", "Library.lua"), encoding="utf-8").read()
block = library[library.index("local FOREVER_RAID = {"):]
block = block[:block.index("\n}\n")]
hidden_sets = {}
for line in block.split("\n"):
    head = re.match(r'\s*\{ "(\w+)", "([^"]+)", \{', line)
    if not head:
        continue
    cls, set_name = head.groups()
    set_id = hidden_sets.setdefault(set_name, 100000 + len(hidden_sets))
    for piece, item_id, icon in re.findall(r'\{ "([^"]+)", (\d+), "([^"]+)"', line):
        meta = for_item.get(item_id)
        if item_id in items or not meta or meta["ClassID"] not in ("2", "4") or num(meta, "InventoryType") not in INV_OK:
            continue
        items[int(item_id)] = dict(
            id=int(item_id), inv=num(meta, "InventoryType"), q=4, ilvl=65, req=60, mask=CLASS_BITS[cls],
            sub=int(meta["ClassID"]) * 100 + num(meta, "SubclassID"), icon="Interface\\Icons\\" + icon, flag=3,
            set=set_id, fac="", uniq=0, name=clean(piece), note="")
for set_name, set_id in hidden_sets.items():
    sets_used[set_id] = set_name

# Set names, for items that belong to a set that survived the filters.
for item in items.values():
    if item["set"] and item["set"] not in sets_used:
        name = (for_sets.get(str(item["set"])) or era_sets.get(str(item["set"])) or {}).get("Name_lang")
        if name:
            sets_used[item["set"]] = clean(name)
        else:
            item["set"] = 0

blocks = {}
for item in sorted(items.values(), key=lambda i: (-i["ilvl"], i["name"], i["id"])):
    line = "|".join(str(v) for v in (
        item["id"], item["q"], item["ilvl"], item["req"], item["mask"], item["sub"], item["icon"],
        item["flag"], item["set"], item["fac"], item["uniq"], item["name"], item["note"]))
    blocks.setdefault(item["inv"], []).append(line)

with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write("-- Generated by tools/geardb.py from the game's client tables; do not edit by hand.\n")
    f.write("-- Line: id|quality|itemLevel|requiredLevel|classMask|sub|iconFileID|forever|set|faction|unique|name|note\n")
    f.write("-- forever: 0 Classic only, 1 named in Forever's tables, 2 Forever only, 3 Forever only, not revealed yet.\n")
    f.write("local _, FGT = ...\nFGT.GEARDB = {\n")
    f.write("    builds = { era = %r, forever = %r },\n" % (BUILDS["era"], BUILDS["forever"]))
    f.write("    sets = {\n")
    for set_id in sorted(sets_used):
        f.write("        [%d] = %s,\n" % (set_id, '"%s"' % sets_used[set_id].replace('"', '\\"')))
    f.write("    },\n    blocks = {\n")
    for inv in sorted(blocks):
        f.write("        [%d] = [==[\n%s\n]==],\n" % (inv, "\n".join(blocks[inv])))
    f.write("    },\n}\n")

print("items:", len(items), "sets:", len(sets_used), "bytes:", os.path.getsize(OUT))
for inv in sorted(blocks):
    print(" inv", inv, len(blocks[inv]))
