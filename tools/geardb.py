#!/usr/bin/env python3
"""Build GearData.lua, the Gear Planner's item database.

Source: wago.tools' public exports of the game's own client tables
(ItemSparse, Item, ItemSet, Faction; SpellEffect, SpellReagents and SkillLineAbility
for recipes; SpellName, SpellItemEnchantment, SpellEquippedItems, ItemEffect and
ItemXItemEffect for enchants) for Classic Era 1.15.9 and WoW Forever
1.60.1. Nothing is read from Wowhead.

  - Classic Era is complete (names, quality, slot, class limits), so it is the
    base. Season of Discovery ids (200000+) are dropped unless Forever has them.
  - Forever's tables are partly empty: items stay hidden until a player finds
    one after launch. An item that Forever's tables name is marked "in Forever"
    (flag 1); one that only Forever has is "new" (flag 2). Anything else is
    Classic only and shows as "Not revealed yet" on the Forever client.

Run:  python3 tools/geardb.py          (downloads once into tools/.cache)
      python3 tools/geardb.py --forever-build latest   (only when Forever has a newer build)
"""
import csv, os, re, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, ".cache")
OUT = os.path.join(HERE, "..", "GearData.lua")
BUILDS = {"era": "1.15.9.70003", "forever": "1.60.1.70532"}

os.makedirs(CACHE, exist_ok=True)


def version(v):
    return tuple(int(x) for x in v.split("."))


# GearData.lua names the Forever build it was made from; never go back to an older one.
if os.path.exists(OUT):
    with open(OUT, encoding="utf-8") as f:
        made = re.search(r"forever = '([\d.]+)'", f.read(2000))
    if made and version(made.group(1)) > version(BUILDS["forever"]):
        BUILDS["forever"] = made.group(1)

# --forever-build latest: rebuild from wago.tools' newest Forever build (product wowf),
# or stop when GearData already uses it. New patches add items and change old ones.
if "--forever-build" in sys.argv:
    req = urllib.request.Request("https://wago.tools/api/builds",
                                 headers={"User-Agent": "Mozilla/5.0 (ForeverGoalTracker geardb)"})
    with urllib.request.urlopen(req, timeout=60) as r:
        import json
        latest = json.loads(r.read().decode("utf-8"))["wowf"][0]["version"]
    if version(latest) <= version(BUILDS["forever"]):
        print("Forever build unchanged:", BUILDS["forever"])
        sys.exit(0)
    print("Forever build", BUILDS["forever"], "->", latest)
    BUILDS["forever"] = latest

# The downloaded tables belong to one build each; a new build downloads them again.
for client, build in BUILDS.items():
    marker = os.path.join(CACHE, "%s-build.txt" % client)
    if os.path.exists(marker):
        with open(marker) as f:
            if f.read().strip() != build:
                for name in os.listdir(CACHE):
                    if name.startswith(client + "-") and name.endswith(".csv"):
                        os.remove(os.path.join(CACHE, name))
    with open(marker, "w") as f:
        f.write(build)


def table(client, name):
    path = os.path.join(CACHE, "%s-%s.csv" % (client, name))
    if not os.path.exists(path):
        url = "https://wago.tools/db2/%s/csv?build=%s" % (name, BUILDS[client])
        print("downloading", url, file=sys.stderr)
        # the host refuses Python's default user agent
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (ForeverGoalTracker geardb)"})
        with urllib.request.urlopen(req, timeout=120) as r, open(path, "wb") as f:
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


# Stats for the planner's stat filter, as short codes: a Agility, s Strength, t Stamina,
# i Intellect, p Spirit (the item's own stats), and from its "Equip:" spells (ItemEffect
# trigger 1; SpellEffect aura, value = base points + 1): A attack power (99, or ranged-only
# 124), S spell power (13 on all schools), H healing (135), h hit (54, 55), c crit (52, 57),
# d defense (skill 95 via aura 30, plus 25 per 1% dodge 49, parry 47 or block 51, the
# game's own rate).
PRIMARY = {3: "a", 4: "s", 7: "t", 5: "i", 6: "p"}
STAT_ORDER = "astipASHhcd"


def item_spells(client):
    effects = table(client, "ItemEffect")
    out = {}
    if any("ParentItemID" in r for r in effects.values()):
        for r in effects.values():
            if r["TriggerType"] == "1":
                out.setdefault(r["ParentItemID"], []).append(r["SpellID"])
    else:  # Forever links items to their effects through ItemXItemEffect
        for r in table(client, "ItemXItemEffect").values():
            e = effects.get(r["ItemEffectID"])
            if e and e["TriggerType"] == "1":
                out.setdefault(r["ItemID"], []).append(e["SpellID"])
    return out


def spell_stats(client):
    out = {}
    for r in table(client, "SpellEffect").values():
        if r["Effect"] != "6":
            continue
        aura, value, misc = num(r, "EffectAura"), num(r, "EffectBasePoints") + 1, num(r, "EffectMiscValue_0")
        if value <= 0:
            continue
        st = out.setdefault(r["SpellID"], {})
        if aura == 99:
            st["A"] = max(st.get("A", 0), value)
        elif aura == 124:
            st["R"] = max(st.get("R", 0), value)
        elif aura == 13 and misc & 126 == 126:
            st["S"] = max(st.get("S", 0), value)
        elif aura == 135:
            st["H"] = max(st.get("H", 0), value)
        elif aura in (54, 55):
            st["h"] = max(st.get("h", 0), value)
        elif aura in (52, 57, 552):
            st["c"] = max(st.get("c", 0), value)
        elif aura == 30 and misc == 95:
            st["d"] = st.get("d", 0) + value
        elif aura in (47, 49, 51):
            st["d"] = st.get("d", 0) + 25 * value
    return out


equip = {client: (item_spells(client), spell_stats(client)) for client in ("era", "forever")}


def stats_of(item_id, row, client):
    st = {}
    for i in range(10):
        code = PRIMARY.get(num(row, "StatModifier_bonusStat_%d" % i, -1))
        amount = num(row, "StatModifier_bonusAmount_%d" % i)
        if code and amount > 0:
            st[code] = st.get(code, 0) + amount
    spells, effects = equip[client]
    for spell in spells.get(item_id, []):
        for code, value in effects.get(spell, {}).items():
            if code == "R":  # ranged attack power counts when the item has no melee attack power
                code = "A" if not any("A" in effects.get(x, {}) for x in spells.get(item_id, [])) else None
            if code:
                st[code] = st.get(code, 0) + value
    return ",".join("%s%d" % (c, st[c]) for c in STAT_ORDER if st.get(c))


# Forever stores no stat amounts: each stat is a share (StatPercentEditor, 1/10000) of the
# item level's budget (RandPropPoints, by quality and slot), like the modern game. Its
# "Equip:" bonuses are stats too, hit, crit, dodge, parry and block as ratings. Checked
# against Classic Era on the shared items: 2,365 of 2,576 come out identical.
BUDGET = table("forever", "RandPropPoints")
BUDGET_SLOT = {1: 0, 5: 0, 7: 0, 17: 0, 20: 0, 3: 1, 6: 1, 8: 1, 10: 1, 12: 1,
               2: 2, 9: 2, 11: 2, 14: 2, 16: 2, 23: 2, 13: 3, 21: 3, 22: 3, 15: 4, 25: 4, 26: 4, 28: 4}
# stat id -> (code, Classic points per Forever point); 39 is ranged attack power
FOREVER_STAT = {3: ("a", 1), 4: ("s", 1), 7: ("t", 1), 5: ("i", 1), 6: ("p", 1), 38: ("A", 1),
                45: ("SH", 1), 42: ("S", 1), 41: ("H", 1), 31: ("h", 0.1), 32: ("c", 1 / 14.0),
                12: ("d", 1), 13: ("d", 25 / 12.0), 14: ("d", 25 / 15.0), 15: ("d", 25 / 5.0)}


def forever_stats(item_id, row, game_inv):
    quality = num(row, "OverallQualityID")
    level = BUDGET.get(row["ItemLevel"])
    column = {4: "Epic", 5: "Epic", 3: "Superior"}.get(quality, "Good")
    slot = BUDGET_SLOT.get(game_inv)
    budget = float(level["%sF_%d" % (column, slot)]) if level and slot is not None else 0
    st, ranged = {}, 0
    for i in range(10):
        stat, share = num(row, "StatModifier_bonusStat_%d" % i, -1), num(row, "StatPercentEditor_%d" % i)
        value = share * budget * 0.0001
        if share <= 0:
            continue
        if stat == 39:
            ranged += value
        elif stat in FOREVER_STAT:
            codes, scale = FOREVER_STAT[stat]
            for code in codes:
                st[code] = st.get(code, 0) + value * scale
    if ranged and not st.get("A"):
        st["A"] = ranged  # ranged attack power counts when the item has no melee attack power
    out = {c: int(v + 0.5) for c, v in st.items() if int(v + 0.5) > 0}
    # equip spells Forever kept (rare) add to the stats
    spells, effects = equip["forever"]
    for spell in spells.get(item_id, []):
        for code, value in effects.get(spell, {}).items():
            code = "A" if code == "R" and not out.get("A") else (None if code == "R" else code)
            if code:
                out[code] = out.get(code, 0) + value
    return ",".join("%s%d" % (c, out[c]) for c in STAT_ORDER if out.get(c))


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
    # greens at every level (leveling plans need them), except starter gear
    if quality == 2 and req < 5 and ilvl < 10 and not (set_id or cosmetic):
        return
    # Armor must be a real armor type (cloth..plate, shields, relics); skip class 4/0 junk
    # except neck, finger, trinket, back, shirt, tabard and off-hand held items.
    sub = int(meta["ClassID"]) * 100 + num(meta, "SubclassID")
    mask = num(row, "AllowableClass", -1)
    if mask <= 0 or mask >= 2 ** 31 or mask & ALL_CLASSES == ALL_CLASSES:
        mask = 0  # no class limit
    forever = sparse is for_sparse
    return dict(
        id=int(item_id), inv=inv, q=quality, ilvl=ilvl, req=req, mask=mask, sub=sub,
        icon=num(meta, "IconFileDataID"), flag=source_flag, set=set_id, fac=faction_of(row),
        uniq=1 if num(row, "MaxCount") == 1 else 0, name=name, note=note_for(row, faction_names),
        stats=forever_stats(item_id, row, num(meta, "InventoryType")) if forever else stats_of(item_id, row, "era"),
        bind=min(num(row, "Bonding"), 4))


# Classic Era shows Classic's items, Forever shows Forever's. An item in both is the same
# (one line), updated in Forever (its Forever version goes in forever_items), or only in one.
SAME = ("inv", "q", "ilvl", "req", "mask", "sub", "icon", "set", "fac", "uniq", "name", "note", "stats", "bind")
# A change a player would notice marks the item "Updated in Forever" (flag 4). Equip bonuses
# alone do not: the two clients store them differently, so their small differences are
# mostly measurement, and Forever just shows its own numbers.
VISIBLE = ("inv", "q", "ilvl", "req", "mask", "sub", "set", "fac", "bind", "name")


def primary_changed(a, b):
    """Main stats differ by more than the budget formula's rounding (one point)."""
    pa, pb = ({x[0]: int(x[1:]) for x in s.split(",") if x and x[0] in "astip"} for s in (a, b))
    return any(k not in pa or k not in pb or abs(pa[k] - pb[k]) > 1 for k in set(pa) | set(pb))


forever_items = {}
for item_id in era_sparse:
    forever_has = item_id in for_sparse and for_sparse[item_id]["Display_lang"]
    if int(item_id) >= 200000 and not forever_has:
        continue  # Season of Discovery
    era_rec = consider(item_id, era_sparse, era_item, 1 if forever_has else 0)
    if era_rec:
        items[era_rec["id"]] = era_rec
    if forever_has:
        for_rec = consider(item_id, for_sparse, for_item, 1)
        if for_rec and era_rec and not for_rec["icon"]:
            for_rec["icon"] = era_rec["icon"]  # Forever has not shipped every icon yet
        if for_rec and (not era_rec or any(for_rec[k] != era_rec[k] for k in SAME)):
            if not era_rec or any(for_rec[k] != era_rec[k] for k in VISIBLE) \
                    or primary_changed(for_rec["stats"], era_rec["stats"]):
                for_rec["flag"] = 4
            forever_items[for_rec["id"]] = for_rec
for item_id in for_sparse:
    if item_id not in era_sparse and for_sparse[item_id]["Display_lang"]:
        rec = consider(item_id, for_sparse, for_item, 2)
        if rec:
            items[rec["id"]] = rec

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
            set=set_id, fac="", uniq=0, name=clean(piece), note="", stats="", bind=1)  # raid set pieces bind on pickup
for set_name, set_id in hidden_sets.items():
    sets_used[set_id] = set_name

# Set names, for items that belong to a set that survived the filters.
for item in list(items.values()) + list(forever_items.values()):
    if item["set"] and item["set"] not in sets_used:
        name = (for_sets.get(str(item["set"])) or era_sets.get(str(item["set"])) or {}).get("Name_lang")
        if name:
            sets_used[item["set"]] = clean(name)
        else:
            item["set"] = 0

def block_lines(source):
    out = {}
    for item in sorted(source.values(), key=lambda i: (-i["ilvl"], i["name"], i["id"])):
        line = "|".join(str(v) for v in (
            item["id"], item["q"], item["ilvl"], item["req"], item["mask"], item["sub"], item["icon"],
            item["flag"], item["set"], item["fac"], item["uniq"], item["name"], item["note"], item["stats"], item["bind"]))
        out.setdefault(item["inv"], []).append(line)
    return out


blocks, forever_blocks = block_lines(items), block_lines(forever_items)

# Recipes: a profession spell that creates a gear item (SpellEffect 24, CREATE_ITEM), its
# reagents (SpellReagents) and its profession (SkillLineAbility). Each client has its own,
# since Forever changes some recipes and adds new ones.
def recipes_for(client):
    created = {}
    for row in table(client, "SpellEffect").values():
        if row["Effect"] == "24" and row["EffectItemType"].isdigit() and (int(row["EffectItemType"]) in items or int(row["EffectItemType"]) in forever_items):
            created.setdefault(row["SpellID"], int(row["EffectItemType"]))
    skill = {}
    for row in table(client, "SkillLineAbility").values():
        if row["Spell"] in created and num(row, "SkillLine") in SKILL:
            skill[row["Spell"]] = num(row, "SkillLine")
    out = {}
    for row in table(client, "SpellReagents").values():
        spell = row["SpellID"]
        if spell not in created or spell not in skill:
            continue
        parts = ["%d:%d" % (num(row, "Reagent_%d" % i), num(row, "ReagentCount_%d" % i))
                 for i in range(8) if num(row, "Reagent_%d" % i) > 0]
        if parts:
            line = "%d|%s" % (skill[spell], ",".join(parts))
            item_id = created[spell]
            # an item made by several spells keeps the first; they are versions of one recipe
            out.setdefault(item_id, line)
    return out


recipes = {client: recipes_for(client) for client in ("era", "forever")}


# Permanent enchants: a spell with SpellEffect 53 (ENCHANT_ITEM; its misc value is the
# SpellItemEnchantment id that item links carry), what it fits (SpellEquippedItems), and how it
# is applied: an Enchanting spell (SkillLineAbility 333) or an item (arcanums, armor kits,
# scopes, shoulder signets; ItemEffect). Season of Discovery spells (400000+) and items
# (200000+) are dropped from Era; Forever keeps those plus the spells only it has, since its
# tables also carry Season of Discovery leftovers under the same ids as Era.
SOD_SPELL, SOD_ITEM = 400000, 200000
ENCHANT_JUNK = re.compile(r"^(QA|Test |Copy of )|\[PH\]|QAEnch", re.I)


def enchant_spells(client):
    return {row["SpellID"] for row in table(client, "SpellEffect").values() if row["Effect"] == "53"}


def enchants_for(client, era_spells):
    sparse = for_sparse if client == "forever" else era_sparse
    names = {k: r["Name_lang"] for k, r in table(client, "SpellName").items()}
    effects = table(client, "SpellItemEnchantment")
    equipped = {r["SpellID"]: r for r in table(client, "SpellEquippedItems").values()}
    enchanting = {r["Spell"] for r in table(client, "SkillLineAbility").values() if r["SkillLine"] == "333"}
    item_effects = table(client, "ItemEffect")
    spell_item = {}
    if any("ParentItemID" in r for r in item_effects.values()):
        for r in sorted(item_effects.values(), key=lambda r: int(r["ID"])):
            spell_item.setdefault(r["SpellID"], r["ParentItemID"])
    else:  # Forever links items to their effects through ItemXItemEffect
        by_effect = {k: r["SpellID"] for k, r in item_effects.items()}
        for r in sorted(table(client, "ItemXItemEffect").values(), key=lambda r: int(r["ID"])):
            spell = by_effect.get(r["ItemEffectID"])
            if spell:
                spell_item.setdefault(spell, r["ItemID"])
    reagents = {}
    for r in table(client, "SpellReagents").values():
        parts = ["%d:%d" % (num(r, "Reagent_%d" % i), num(r, "ReagentCount_%d" % i))
                 for i in range(8) if num(r, "Reagent_%d" % i) > 0]
        if parts:
            reagents.setdefault(r["SpellID"], ",".join(parts))

    def effect_text(eid):
        row = effects.get(eid)
        if not row:
            return ""
        return clean(re.sub(r"\$k(\d)", lambda m: str(num(row, "EffectPointsMin_%d" % (int(m.group(1)) - 1))),
                            row["Name_lang"]))

    out, seen = [], set()
    for row in sorted(table(client, "SpellEffect").values(), key=lambda r: (int(r["SpellID"]), int(r["ID"]))):
        spell = row["SpellID"]
        if row["Effect"] != "53" or spell in seen:
            continue
        seen.add(spell)
        sid = int(spell)
        if sid >= SOD_SPELL and (client == "era" or spell in era_spells):
            continue
        fit = equipped.get(spell)
        if not fit or fit["EquippedItemClass"] not in ("2", "4"):
            continue
        item_id = spell_item.get(spell)
        if spell in enchanting:
            source, name, cost = "E", names.get(spell, ""), reagents.get(spell, "")
            item_id = 0
        elif item_id and item_id in sparse:
            if int(item_id) >= SOD_ITEM and (client == "era" or item_id in era_sparse):
                continue
            source, name, cost = "I", sparse[item_id]["Display_lang"], "%s:1" % item_id
        else:
            continue
        name = re.sub(r"\s+", " ", clean(name))
        if not name or ENCHANT_JUNK.search(name) or JUNK.search(name):
            continue
        out.append("|".join(str(v) for v in (
            sid, num(row, "EffectMiscValue_0"), fit["EquippedItemClass"], num(fit, "EquippedItemInvTypes"),
            num(fit, "EquippedItemSubclass"), source, item_id or 0, name, effect_text(row["EffectMiscValue_0"]), cost)))
    return out


era_enchant_spells = enchant_spells("era")
enchants = {client: enchants_for(client, era_enchant_spells) for client in ("era", "forever")}

with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write("-- Generated by tools/geardb.py from the game's client tables; do not edit by hand.\n")
    f.write("-- Line: id|quality|itemLevel|requiredLevel|classMask|sub|iconFileID|forever|set|faction|unique|name|note|stats|bind\n")
    f.write("-- bind: 0 none, 1 on pickup, 2 on equip, 3 on use, 4 quest item (the game's Bonding).\n")
    f.write("-- stats: a Agility, s Strength, t Stamina, i Intellect, p Spirit, A attack power, S spell power,\n")
    f.write("-- H healing, h hit %, c crit %, d defense (skill; 25 per 1% dodge, parry or block).\n")
    f.write("-- forever: 0 Classic only, 1 named in Forever's tables, 2 Forever only, 3 Forever only, not revealed yet.\n")
    f.write("-- foreverBlocks hold Forever's version of items it changed: forever 4 updated, 1 same item\n")
    f.write("-- (only equip bonuses read differently). The Forever client uses them in place of blocks.\n")
    f.write("local _, FGT = ...\nFGT.GEARDB = {\n")
    f.write("    builds = { era = %r, forever = %r },\n" % (BUILDS["era"], BUILDS["forever"]))
    f.write("    sets = {\n")
    for set_id in sorted(sets_used):
        f.write("        [%d] = %s,\n" % (set_id, '"%s"' % sets_used[set_id].replace('"', '\\"')))
    f.write("    },\n    blocks = {\n")
    for inv in sorted(blocks):
        f.write("        [%d] = [==[\n%s\n]==],\n" % (inv, "\n".join(blocks[inv])))
    f.write("    },\n")
    # Forever's own version of items it changed (same line format); the Forever client reads
    # these in place of the Classic line. Brand-new Forever items are in blocks (forever 2).
    f.write("    foreverBlocks = {\n")
    for inv in sorted(forever_blocks):
        f.write("        [%d] = [==[\n%s\n]==],\n" % (inv, "\n".join(forever_blocks[inv])))
    f.write("    },\n")
    # recipes: item id -> "skillLine|reagent:count,..."; Forever lists only where it differs from Era
    f.write("    recipes = {\n")
    for item_id in sorted(recipes["era"]):
        f.write("        [%d] = %r,\n" % (item_id, recipes["era"][item_id]))
    f.write("    },\n    foreverRecipes = {\n")
    for item_id in sorted(recipes["forever"]):
        if recipes["forever"][item_id] != recipes["era"].get(item_id):
            f.write("        [%d] = %r,\n" % (item_id, recipes["forever"][item_id]))
    f.write("    },\n")
    # enchants: spell|enchantId|itemClass|invTypeMask|subclassMask|source (E Enchanting, I item)|
    # itemId|name|effect|reagent:count,...  Each client has its full list.
    for key, client in (("enchants", "era"), ("foreverEnchants", "forever")):
        f.write("    %s = [==[\n%s\n]==],\n" % (key, "\n".join(enchants[client])))
    f.write("}\n")

print("items:", len(items), "sets:", len(sets_used), "bytes:", os.path.getsize(OUT))
print("recipes: era", len(recipes["era"]), "forever", len(recipes["forever"]))
print("enchants: era", len(enchants["era"]), "forever", len(enchants["forever"]))
for inv in sorted(blocks):
    print(" inv", inv, len(blocks[inv]))
