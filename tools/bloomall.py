"""Bake blooms for the banners Karl picked, and make before/after contact sheets.

    python tools/bloomall.py [out_dir] [--install]

For each image stem in STEMS (a banner's texture name without "-banner.blp") it
finds the approved master from Media/final-images/runtime-manifest.json, bakes
its bloom with tools/bloom.py, and writes <stem>-bloom.blp plus a before/after
preview into out_dir. Contact sheets (bloom-sheet-NN.jpg) group eight pairs each.
--install copies the BLPs into Media/ (a full game restart loads new textures).
The list of names Karl chose and the goals they map to are in reports/image-tests/
bloom-candidates-2026-10-13.md.
"""
import json
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
import bloom as B  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
FINAL = ROOT / "Media/final-images"

# stem: (label for the sheet, per-image overrides for bloom.bake)
STEMS = {
    "thunderfury": "Thunderfury (already in game as a grey TGA; moves to the same BLP format)",
    "set_tier2_shaman": "Shaman Tier 2, Ten Storms (same)",
    "raid_aq20": "Ruins of Ahn'Qiraj",
    "raid_aq40": "Temple of Ahn'Qiraj",
    "pvp_mount_ally": "Alliance war mount / Stormpike Charger (eyes)",
    "set_tier1_mage": "Arcanist Regalia (staff gem)",
    "ashbringer": "Corrupted Ashbringer",
    "atiesh": "Atiesh",
    "raid_bwl": "Blackwing Lair + attunement",
    "benediction": "Benediction",
    "benediction-alliance": "Benediction (Alliance art)",
    "set_tier1_druid": "Cenarion Raiment",
    "mount_charger": "Charger",
    "tier3_hunter": "Cryptstalker (shoulders)",
    "mount_deathcharger": "Deathcharger",
    "key_dm": "Dire Maul key",
    "set_tier2_hunter": "Dragonstalker",
    "mount_dreadsteed": "Dreadsteed",
    "tier3_druid": "Dreamwalker Raiment",
    "tier3_druid-horde": "Dreamwalker Raiment (Horde art)",
    "set_tier1_shaman": "Earthfury",
    "tier3_shaman": "Earthshatter",
    "tier3_mage": "Frostfire Regalia",
    "raid_hyjal": "Hyjal Summit",
    "att_mc": "Molten Core attunement",
    "raid_mc": "Molten Core",
    "att_naxx": "Naxxramas attunement (also Tier 3 fallback)",
    "set_tier2_mage": "Netherwind Regalia",
    "set_tier1_rogue": "Nightslayer",
    "set_tier1_rogue-alliance": "Nightslayer (Alliance art)",
    "raid_ony": "Slay Onyxia",
    "att_ony_ally": "Onyxia attunement (Alliance)",
    "att_ony_horde": "Onyxia attunement (Horde)",
    "tier3_paladin": "Redemption",
    "key_scholo": "Skeleton Key",
    "key_strat": "Stratholme key + The Devout",
    "sulfuras": "Sulfuras",
    "rep_thorium": "Thorium Brotherhood",
    "wolfsbane": "Wolfsbane",
}

# Where only one spot should glow (Karl's notes in the list): boxes in fractions of the master
REGIONS = {
    "pvp_mount_ally": [(0.60, 0.70, 0.36, 0.47)],                      # the charger's eye
    "set_tier1_mage": [(0.83, 0.98, 0.37, 0.53)],                      # the staff's gem
    "tier3_hunter": [(0.55, 0.69, 0.18, 0.40), (0.75, 0.88, 0.18, 0.42)],  # both shoulders
}
# Other changes after Karl's first look in game (2026-10-13), passed to bloom.bake
OVERRIDES = {
    # the staff gem's glow larger: a wider area and a wider, softer spread
    "set_tier1_mage": dict(region=[(0.78, 1.00, 0.30, 0.60)], near=10.0, far=50.0),
    # keep the eye in the chest at full strength, the shoulders and helmet quieter
    "set_tier2_hunter": dict(region=[(0.60, 0.74, 0.42, 0.58)], outside=0.4),
    # keep her eyes and the glow at her fingers; the chest and the background quieter
    "tier3_paladin": dict(region=[(0.64, 0.76, 0.24, 0.34), (0.80, 1.00, 0.18, 0.44)], outside=0.3),
    # the dragon's mouth glow larger (wider, softer spread)
    "raid_ony": dict(near=8.0, far=55.0, mix=(0.60, 0.85)),
}

TILE_W, TILE_H = 480, 360


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out_dir = Path(args[0]) if args else ROOT / "reports" / "image-tests" / "bloom"
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((FINAL / "runtime-manifest.json").read_text(encoding="utf-8"))
    font = ImageFont.load_default()
    tiles, report = [], []
    for stem, label in STEMS.items():
        info = manifest.get(stem)
        if not info:
            print("no master for", stem)
            continue
        master = FINAL / info["source"]
        if not master.exists():
            print("missing file", master)
            continue
        opts = dict(OVERRIDES.get(stem, {}))
        opts.setdefault("region", REGIONS.get(stem))
        alpha, bloom = B.bloom_alpha(master, **opts)
        data = B.encode_blp(alpha)
        (out_dir / f"{stem}-bloom.blp").write_bytes(data)
        worst, mean = B.alpha_error(data, alpha)
        pv = out_dir / f"{stem}-preview.jpg"
        B.preview(master, alpha, 0.6, pv, size=(TILE_W * 2, TILE_H))
        coverage = float((alpha > 40).mean())
        report.append((stem, label, len(data) // 1024, worst, round(mean, 2), round(coverage, 3)))
        im = Image.open(pv).convert("RGB")
        tile = Image.new("RGB", (TILE_W * 2 + 8, TILE_H + 22), (14, 14, 16))
        tile.paste(im, (0, 0))
        ImageDraw.Draw(tile).text((6, TILE_H + 6), f"{label}   [{stem}]   covers {coverage * 100:.0f}% of the picture", fill=(230, 230, 230), font=font)
        tiles.append(tile)
    per = 8
    for page in range(0, len(tiles), per):
        group = tiles[page:page + per]
        rows = (len(group) + 1) // 2
        sheet = Image.new("RGB", (2 * (TILE_W * 2 + 8) + 10, rows * (TILE_H + 28)), (8, 8, 9))
        for i, t in enumerate(group):
            sheet.paste(t, ((i % 2) * (TILE_W * 2 + 18), (i // 2) * (TILE_H + 28)))
        sheet.save(out_dir / f"bloom-sheet-{page // per + 1:02d}.jpg", quality=84)
    (out_dir / "bloom-report.json").write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(f"{len(report)} blooms, {sum(r[2] for r in report)} KB, {(len(tiles) + per - 1) // per} sheets -> {out_dir}")
    if "--install" in sys.argv:
        for stem, *_ in report:
            shutil.copy(out_dir / f"{stem}-bloom.blp", ROOT / "Media" / f"{stem}-bloom.blp")
        print("installed into Media/")


if __name__ == "__main__":
    main()
