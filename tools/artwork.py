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
    **{goal: "tall-1200x900/" + goal + ".jpg" for goal in (
        "ashbringer", "atiesh", "sulfuras", "thunderfury",
        "quelserrar", "benediction", "raid_bwl", "raid_mc", "att_mc", "set_tier1",
        "lokdelar", "frostsaber", "set_viper", "rep_cenarion", "key_scholo")},
    "rhokdelar": "tall-1200x900/rhokdelar-hunter.jpg",
    "raid_ony": "tall-1200x900/raid_ony.jpg",
}
EXTRA_BANNERS = {
    "thunderfury": "thunderfury.png",
    "raid_bwl": "blackwinglair.jpg",
    "mount_dreadsteed": "warlock-mount-dreadsteed.jpg",
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
