"""Compile uploaded artwork to 512px BLP2/DXT1; leave originals untouched.

Requires Pillow with its DDS BC1 encoder. Uses the BLP2 layout documented by
https://github.com/Kanma/BLPConverter/blob/master/blp_internal.h
Colors are unchanged here; approved monochrome masters bypass runtime desaturation.
"""
from io import BytesIO
from pathlib import Path
import json
import struct
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Media/artwork"
FINAL = ROOT / "Media/final-images"
FINAL_BANNERS = {
    "pvp_set_mail_horde": "pvp/warlord-mail.jpg",
    "rep_timbermaw": "reputation/timbermaw.jpg",
    "mount_qiraji": "mounts/black-qiraji.jpg",
    "allclasses_dwarf_shaman": "leveling/dwarf-shaman.jpg",
    "pvp_drums_of_war": "pvp/drums-of-war.jpg",
    "epicmounts_undead": "mounts/undead-warhorse.jpg",
    "epicmounts_skyborne": "mounts/skyborne-location.jpg",
    "key_dm": "additional-goals/key_dm.jpg",
    "allclasses_undead_paladin": "leveling/undead-paladin.jpg",
    "allclasses_troll_mage": "leveling/troll-mage.jpg",
    "epicmounts_troll": "mounts/troll-raptor.jpg",
    "epicmounts_human": "mounts/human-palomino.jpg",
    "epicmounts_nightelf": "mounts/nightelf-nightsaber.jpg",
    "pvp_shared": "pvp/shared-pvp.jpg",
    "set_tier2_paladin": "tier-sets/paladin/tier2.jpg",
    "tier3_paladin": "tier-sets/paladin/tier3.jpg",
    "tier3_warlock": "tier-sets/warlock/tier3.jpg",
    "raid_zg": "zul-gurub/hakkar.jpg",
    "tier3_shaman": "tier-sets/shaman/tier3.jpg",
    "epicmounts_orc": "mounts/orc-wolf.jpg",
    "epicmounts_tauren": "mounts/tauren-kodo.jpg",
    "epicmounts_dwarf": "mounts/dwarf-ram.jpg",
    "epicmounts_gnome": "mounts/gnome-mechanostrider.jpg",
    "rep_argentdawn": "reputation/rep_argentdawn.jpg",
    **{goal: "tall-1200x900/" + goal + ".jpg" for goal in (
        "ashbringer", "atiesh", "sulfuras", "thunderfury",
        "quelserrar", "benediction", "raid_bwl", "raid_mc", "att_mc", "set_tier1",
        "lokdelar", "frostsaber", "set_viper", "rep_cenarion", "key_scholo")},
    "rhokdelar": "tall-1200x900/rhokdelar-hunter.jpg",
    "raid_ony": "tall-1200x900/raid_ony.jpg",
    "mount_dreadsteed": "tall-1200x900/mount_dreadsteed.jpg",
    "mount_deathcharger": "tall-1200x900/mount_deathcharger.jpg",
    "tier3": "tall-1200x900/naxxramas.jpg",
    "att_naxx": "tall-1200x900/naxxramas.jpg",
    "set_tier1_rogue": "tier-sets/rogue/tier1.jpg",
    "set_tier2_rogue": "tier-sets/rogue/tier2.jpg",
    "tier3_rogue": "tier-sets/rogue/tier3.jpg",
    "set_tier1_hunter": "tier-sets/hunter/tier1.jpg",
    "set_tier2_hunter": "tier-sets/hunter/tier2.jpg",
    "set_tier1_mage": "tier-sets/mage/tier1.jpg",
    "set_tier2_mage": "tier-sets/mage/tier2.jpg",
    "set_tier1_warrior": "tier-sets/warrior/tier1.jpg",
    "set_tier2_warrior": "tier-sets/warrior/tier2.jpg",
    "set_tier2_warrior-alliance": "tier-sets/warrior/tier2-alliance.jpg",
    "set_tier2_druid": "tier-sets/druid/tier2.jpg",
    "set_tier1_druid": "tier-sets/druid/tier1.jpg",
    "tier3_druid": "tier-sets/druid/tier3.jpg",
    "set_tier1_shaman": "tier-sets/shaman/tier1.jpg",
    "set_tier2_shaman": "tier-sets/shaman/tier2.jpg",
    "set_tier1_warlock": "tier-sets/warlock/tier1.jpg",
    "set_tier1_warlock-alliance": "tier-sets/warlock/tier1-alliance.jpg",
    "set_tier2_warlock": "tier-sets/warlock/tier2.jpg",
    "tier3_warrior": "tier-sets/warrior/tier3.jpg",
    "tier3_mage": "tier-sets/mage/tier3.jpg",
    "tier3_priest": "tier-sets/priest/tier3.jpg",
    "set_tier2_priest": "tier-sets/priest/tier2.jpg",
    "set_tier1_priest": "tier-sets/priest/tier1.jpg",
    "set_violet_sorcerer": "tall-1200x900/set_violet_sorcerer.jpg",
    "raid_hyjal": "tall-1200x900/raid_hyjal.jpg",
    "raid_barrow": "tall-1200x900/raid_barrow.jpg",
    "raid_aq20": "tall-1200x900/raid_aq20.jpg",
    "raid_aq40": "tall-1200x900/raid_aq40.jpg",
}
EXTRA_BANNERS = {
    "thunderfury": "thunderfury.png",
    "raid_bwl": "blackwinglair.jpg",
    "mount_charger": "paladin-mount-charger.jpg",
}


def compress(source, target):
    with Image.open(source) as original:
        aspect = original.width / original.height
        image = original.convert("RGB").resize((512, 512), Image.Resampling.LANCZOS)
    payloads = []
    level = image
    while True:
        dds = BytesIO()
        level.save(dds, format="DDS", pixel_format="DXT1")
        data = dds.getvalue()
        assert data[:4] == b"DDS " and data[84:88] == b"DXT1"
        block = data[128:]
        assert len(block) == ((level.width+3)//4)*((level.height+3)//4)*8
        payloads.append(block)
        if level.width == 1:
            break
        level = level.resize((level.width//2, level.height//2), Image.Resampling.LANCZOS)
    offset = 148 + 1024
    offsets, lengths = [], []
    for data in payloads:
        offsets.append(offset)
        lengths.append(len(data))
        offset += len(data)
    header = struct.pack("<4sI4BII", b"BLP2", 1, 2, 0, 0, 1, 512, 512)
    header += struct.pack("<16I", *(offsets + [0]*(16-len(offsets))))
    header += struct.pack("<16I", *(lengths + [0]*(16-len(lengths))))
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(header + bytes(1024) + b"".join(payloads))
    # Independently decode the container, and validate every mip's range.
    with Image.open(target) as decoded:
        decoded.load()
        assert decoded.size == (512, 512) and decoded.mode == "RGB"
    assert offset == target.stat().st_size
    return {"source": source.name, "aspect": aspect, "bytes": offset,
            "mips": len(payloads), "equivalent_tga_bytes": 512*512*3+44}


def build_selected():
    """Build only the six approved additions, preserving other artwork work."""
    manifest_path = ART / "prepared/manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for goal, filename in EXTRA_BANNERS.items():
        original = ART / filename
        source = ART / (goal + "-banner-source" + original.suffix)
        if not source.exists():
            source.write_bytes(original.read_bytes())
        manifest[goal + "-banner"] = compress(source, ROOT / "Media" / (goal + "-banner.blp"))
        print(goal, manifest[goal + "-banner"]['aspect'])
    manifest_path.write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8", newline="\n")


def build_final():
    """Compile approved masters only, without touching candidate artwork."""
    manifest = {}
    for goal, filename in FINAL_BANNERS.items():
        source = FINAL / filename
        with Image.open(source) as image:
            assert image.size == (1200, 900), (goal, image.size)
        manifest[goal] = compress(source, ROOT / "Media" / (goal + "-banner.blp"))
        manifest[goal]["source"] = filename
        print(goal, manifest[goal]["bytes"], "bytes; aspect", manifest[goal]["aspect"])
    (FINAL / "runtime-manifest.json").write_text(
        json.dumps(manifest, indent=2)+"\n", encoding="utf-8", newline="\n")


def main():
    build_selected()
    manifest = json.loads((ART / "prepared/manifest.json").read_text())
    # Tracked normalized originals also make the build reproducible on the Mac.
    sources = {p.stem[:-7]: p for p in ART.glob("*-source.jpg")
               if "-banner-source" not in p.stem}
    # Only uploaded originals, never recursively recompress prepared assets.
    for source in sorted(ART.glob("*.jpg")):
        if "-source" in source.stem:
            continue
        name = source.stem.lower().replace("_", "-").replace("'", "")
        if name.endswith("-full"):
            name = name[:-5]
        preserved = ART / (name + "-source.jpg")
        if not preserved.exists():
            preserved.write_bytes(source.read_bytes())
        sources[name] = preserved
    for name, preserved in sorted(sources.items()):
        manifest[name] = compress(preserved, ART / "prepared" / (name + ".blp"))
    # Retain the currently approved crops and source of the three active banners.
    for name in ("ashbringer", "atiesh", "sulfuras"):
        source = next(ART.glob(name + "-banner-source.*"))
        manifest[name + "-banner"] = compress(source, ROOT / "Media" / (name + "-banner.blp"))
    runtime = {
        "quelserrar": "queldelar",
        "benediction": "anathema", "raid_mc": "ragnaros-the-firelord",
        "att_mc": "blackrock-mountain---trailer1", "set_tier1": "majordomo-executus",
        "raid_naxx": "kelthuzad", "tier3": "naxx---trailer-baron",
        "att_naxx": "naxx---trailer-naxx",
    }
    for goal, art in runtime.items():
        (ROOT / "Media" / (goal + "-banner.blp")).write_bytes(
            (ART / "prepared" / (art + ".blp")).read_bytes())
    (ART / "prepared/manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8", newline="\n")
    print(f"Compressed {len(manifest)} textures; each 512px BLP with 10 mip levels.")
    old = sum(v["equivalent_tga_bytes"] for v in manifest.values())
    new = sum(v["bytes"] for v in manifest.values())
    print(f"Equivalent raw TGA: {old:,} bytes; BLP: {new:,} bytes ({100*(1-new/old):.1f}% smaller).")


if __name__ == "__main__":
    import sys
    if "--final-only" in sys.argv:
        build_final()
    elif "--selected-only" in sys.argv:
        build_selected()
        build_final()
    else:
        main()
        build_final()
