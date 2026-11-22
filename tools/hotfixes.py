#!/usr/bin/env python3
"""Read item rows from the Forever client's hotfix cache (Cache/ADB/enUS/DBCache.bin).

Forever sends many items from the server instead of shipping them in the client tables:
the tables that wago.tools exports list them with no name or stats, or not at all. The
game keeps every hotfix it has received in DBCache.bin, so the live client knows these
items once it has met them (Engraved Band, 260219, was the first one noticed).

read(path) returns {"ItemSparse": {id: row}, "Item": {id: row}} with the same column names
as wago.tools' CSV exports, so geardb.py can treat a hotfix row like a table row.

Row layouts come from WoWDBDefs (ItemSparse layout 6FCC3191, Item layout 9A2A4834, both
listed for 1.60.1). Each record must use exactly its stated size; a record that does not
is skipped and counted, which is how a layout change in a later build shows up.
"""
import os, struct, sys

# Field types in table order: s string, f float, i/I signed/unsigned 32 bit, h/H 16 bit,
# b/B 8 bit. "x*n" repeats a type for an array (columns Name_0 .. Name_n-1).
LAYOUTS = {
    "ItemSparse": (0x919BE54E, [
        ("Description_lang", "s"), ("Display3_lang", "s"), ("Display2_lang", "s"),
        ("Display1_lang", "s"), ("Display_lang", "s"), ("ExpansionID", "i"),
        ("DmgVariance", "f"), ("LimitCategory", "i"), ("DurationInInventory", "I"),
        ("QualityModifier", "f"), ("BagFamily", "I"), ("StartQuestID", "i"),
        ("LanguageID", "i"), ("ItemRange", "f"), ("StatPercentageOfSocket", "f*10"),
        ("StatPercentEditor", "i*10"), ("StatModifier_bonusStat", "i*10"), ("Stackable", "i"),
        ("MaxCount", "i"), ("MinReputation", "i"), ("RequiredAbility", "I"),
        ("AllowableRace", "i*2"), ("SellPrice", "I"), ("BuyPrice", "I"),
        ("VendorStackCount", "I"), ("PriceVariance", "f"), ("PriceRandomValue", "f"),
        ("Flags", "i*5"), ("OppositeFactionItemID", "i"), ("ModifiedCraftingReagentItemID", "i"),
        ("ContentTuningID", "i"), ("PlayerLevelToItemLevelCurveID", "i"),
        ("ItemLevelOffsetCurveID", "i"), ("ItemLevelOffsetItemLevel", "i"),
        ("ItemSquishEraID", "i"), ("ItemNameDescriptionID", "H"),
        ("RequiredTransmogHoliday", "H"), ("RequiredHoliday", "H"), ("Gem_properties", "H"),
        ("Socket_match_enchantment_ID", "H"), ("TotemCategoryID", "H"), ("InstanceBound", "H"),
        ("ZoneBound", "H*2"), ("ItemSet", "H"), ("LockID", "H"), ("PageID", "H"),
        ("ItemDelay", "H"), ("MinFactionID", "H"), ("RequiredSkillRank", "H"),
        ("RequiredSkill", "H"), ("ItemLevel", "H"), ("AllowableClass", "h"),
        ("ArtifactID", "B"), ("SpellWeight", "B"), ("SpellWeightCategory", "B"),
        ("SocketType", "B*3"), ("SheatheType", "B"), ("Material", "B"), ("PageMaterialID", "B"),
        ("Bonding", "B"), ("DamageType", "B"), ("ContainerSlots", "B"), ("RequiredPVPMedal", "B"),
        ("RequiredPVPRank", "b"), ("RequiredLevel", "b"), ("InventoryType", "b"),
        ("OverallQualityID", "b"), ("AmmunitionType", "B")]),
    "Item": (0x50238EC2, [
        ("ClassID", "i"), ("SubclassID", "B"), ("Material", "B"), ("InventoryType", "b"),
        ("SheatheType", "B"), ("ItemPetFoodID", "i"), ("Sound_override_subclassID", "b"),
        ("IconFileDataID", "i"), ("ItemGroupSoundsID", "I"), ("ContentTuningID", "i"),
        ("ModifiedCraftingReagentItemID", "i"), ("AmmunitionType", "B"), ("CraftingQualityID", "i"),
        ("ItemSquishEraID", "i"), ("RecraftReagentCountPercentage", "f"), ("OrderSource", "B")]),
}
SIZE = {"f": 4, "i": 4, "I": 4, "h": 2, "H": 2, "b": 1, "B": 1}
ENTRY = struct.Struct("<4siiIIIIB3x")  # magic, region, push, unique, table hash, record, size, status
VALID = 1  # status 1 is a live row; 2 removes the record, 3 and 4 invalidate it


def default_path():
    """The live Forever client's cache on the PC or the Mac, if present."""
    for root in (r"C:\Program Files (x86)\World of Warcraft", "/Applications/World of Warcraft",
                 "/c/Program Files (x86)/World of Warcraft"):
        path = os.path.join(root, "_forever_", "Cache", "ADB", "enUS", "DBCache.bin")
        if os.path.exists(path):
            return path
    return None


def _fields(spec):
    for name, kind in spec:
        if "*" in kind:
            kind, n = kind.split("*")
            for i in range(int(n)):
                yield "%s_%d" % (name, i), kind
        else:
            yield name, kind


def _parse(data, spec):
    row, pos = {}, 0
    for name, kind in _fields(spec):
        if kind == "s":
            end = data.index(b"\0", pos)
            row[name] = data[pos:end].decode("utf-8", "replace")
            pos = end + 1
        else:
            value = struct.unpack_from("<" + kind, data, pos)[0]
            row[name] = ("%.9g" % value) if kind == "f" else str(value)
            pos += SIZE[kind]
    return row, pos


def read(path=None):
    """Returns (build, {table: {id string: row}}, skipped count). Empty when no cache exists."""
    path = path or default_path()
    out = {name: {} for name in LAYOUTS}
    if not path or not os.path.exists(path):
        return None, out, 0
    with open(path, "rb") as f:
        data = f.read()
    magic, ver, build = struct.unpack_from("<4sII", data, 0)
    if magic != b"XFTH" or ver != 9:
        raise ValueError("unknown DBCache.bin format: %r version %d" % (magic, ver))
    by_hash = {h: (name, spec) for name, (h, spec) in LAYOUTS.items()}
    pos, skipped = 12 + 32, 0  # header: magic, version, build, 32 byte hash
    while pos + ENTRY.size <= len(data):
        magic, _, _, _, table, record, size, status = ENTRY.unpack_from(data, pos)
        if magic != b"XFTH":
            raise ValueError("DBCache.bin entry out of step at byte %d" % pos)
        body = data[pos + ENTRY.size:pos + ENTRY.size + size]
        pos += ENTRY.size + size
        if table not in by_hash:
            continue
        name, spec = by_hash[table]
        if status != VALID:
            out[name].pop(str(record), None)
            continue
        try:
            row, used = _parse(body, spec)
        except (ValueError, struct.error):
            used = -1
        if used != size:
            skipped += 1
            continue
        row["ID"] = str(record)
        out[name][str(record)] = row
    return "1.60.1.%d" % build, out, skipped


if __name__ == "__main__":
    build, tables, skipped = read(sys.argv[1] if len(sys.argv) > 1 else None)
    print("build", build, {k: len(v) for k, v in tables.items()}, "skipped", skipped)
    for item_id in sys.argv[2:]:
        print(tables["ItemSparse"].get(item_id), tables["Item"].get(item_id))
