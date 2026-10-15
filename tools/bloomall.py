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

import numpy as np
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
    "set_tier2_druid-horde": "Stormrage Raiment (Horde art)",
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
    "rep_nozdormu": "Brood of Nozdormu (the stars and the nebula, not the pale dragon)",
    "pvp_rank14": "Grand Marshal / High Warlord (the halo around the helm, a subtle touch)",
    "wolfsbane": "Wolfsbane",
    "prof_cooking": "Cooking and Place Campfires (the campfire)",
    "social_buffs_mage": "Buff Others, Mage (staff crystal and sigil)",
    "social_buffs_druid": "Buff Others, Druid (the paw)",
    "pvp_set_plate_ally": "Marshal's plate (the crest)",
    "pvp_set_plate_horde": "Warlord's plate (the halo)",
    "pvp_mount_horde": "Horde war mount (horn breath and ground burst)",
    "allclasses_undead_paladin": "Leveling, Undead Paladin (hammer head and glowing eyes)",
    "rep_ambassador_ally_darnassus": "Darnassus (lanterns, glowing orbs and the canopy gap)",
    "rep_ambassador_horde_undercity": "Undercity (ceiling light, torches and waterfall bases)",
    "social_cheers": "Give Cheers (the foamy tankard and the wall lantern)",
    "set_tier2_warlock": "Warlock Tier 2, Nemesis (helmet eyes, dragon staff mouth, shoulder snake eyes and mouth)",
    # the morning banners of 2026-10-14 (Karl approved the previews)
    "social_summons": "Summon Players (the starry cloak and the eyes)",
    "set_partners_in_crime": "Partners in Crime (the gem and its white flames)",
    "social_waves": "Waves (the dynamite sparks)",
    "raid_naxx": "Naxxramas, Kel'Thuzad (the frost burst at the claw, the glow behind him quieter)",
    "social_guild": "Guild (the light flares and columns behind him, not his armor)",
    "social_guild_dungeon": "Dungeons with Guildmates, Gahz'rilla (the sky glare behind the right head, the eye)",
}

# Where only one spot should glow (Karl's notes in the list): boxes in fractions of the master
REGIONS = {
    "pvp_mount_ally": [(0.60, 0.70, 0.36, 0.47)],                      # the charger's eye
    "set_tier1_mage": [(0.83, 0.98, 0.37, 0.53)],                      # the staff's gem
    "tier3_hunter": [(0.55, 0.69, 0.18, 0.40), (0.75, 0.88, 0.18, 0.42)],  # both shoulders
    "prof_cooking": [(0.60, 0.82, 0.24, 0.64)],                        # the campfire's flames
    "social_buffs_mage": [(0.43, 0.52, 0.02, 0.22), (0.66, 0.82, 0.04, 0.28)],  # staff crystal, sigil
    "social_buffs_druid": [(0.55, 0.82, 0.05, 0.30)],                  # the paw
    "pvp_set_plate_ally": [(0.64, 0.75, 0.30, 0.44)],                  # the lion crest
    "pvp_set_plate_horde": [(0.54, 0.76, 0.08, 0.34)],                 # behind the head, inside the halo
    "pvp_mount_horde": [(0.47, 0.58, 0.08, 0.22), (0.60, 0.90, 0.62, 0.90)],  # horn breath, ground burst
    "allclasses_undead_paladin": [(0.66, 0.94, 0.03, 0.30), (0.66, 0.75, 0.37, 0.44)],  # hammer head, eyes
    "rep_ambassador_ally_darnassus": [(0.64, 0.84, 0.00, 0.14), (0.50, 0.60, 0.73, 0.83), (0.63, 0.73, 0.70, 0.80),
                                      (0.36, 0.46, 0.68, 0.78), (0.86, 0.94, 0.72, 0.82), (0.33, 0.44, 0.22, 0.38)],  # canopy gap, orbs, lanterns
    "rep_ambassador_horde_undercity": [(0.64, 0.78, 0.00, 0.08), (0.37, 0.44, 0.32, 0.40), (0.95, 1.00, 0.33, 0.41),
                                       (0.50, 0.60, 0.60, 0.72), (0.80, 0.90, 0.60, 0.72)],  # ceiling light, torches, waterfall bases
    "social_cheers": [(0.82, 1.00, 0.02, 0.24), (0.38, 0.48, 0.10, 0.28)],  # tankard, lantern
    "social_summons": [(0.58, 0.80, 0.18, 0.86)],                      # the cloak and the eyes
    "set_partners_in_crime": [(0.40, 0.98, 0.10, 0.72)],               # the ring, gem and flames
    "social_waves": [(0.58, 0.93, 0.57, 0.79)],                        # the fuses' sparks
    # the star field and the nebula's glow on the left, the stars beside the horns and the two on the wing
    "pvp_rank14": [(0.46, 0.96, 0.06, 0.72)],                          # the halo and the helm's rim light
    "rep_nozdormu": [(0.18, 0.56, 0.0, 0.70), (0.62, 0.82, 0.0, 0.32), (0.84, 0.88, 0.21, 0.26),
                     (0.90, 0.95, 0.26, 0.33)],
}
# Other changes after Karl's first look in game (2026-10-13), passed to bloom.bake
OVERRIDES = {
    # the staff gem's glow larger again: a wider area and a much wider, softer spread
    "set_tier1_mage": dict(region=[(0.74, 1.00, 0.26, 0.62)], near=14.0, far=70.0),
    # quieter to the right of the eye (the haze Karl pointed at)
    "raid_aq40": dict(quiet=[((0.69, 0.88, 0.20, 0.60), 0.3)]),
    # the shoulders stay; the troll's tusks bloom less
    "tier3_hunter": dict(region=[(0.55, 0.69, 0.18, 0.40), (0.75, 0.88, 0.18, 0.42)],
                         quiet=[((0.74, 0.84, 0.26, 0.38), 0.25)]),
    # keep the eye in the chest at full strength, the shoulders and helmet quieter
    "set_tier2_hunter": dict(region=[(0.60, 0.74, 0.42, 0.58)], outside=0.4),
    # keep her eyes and the glow at her fingers; the chest and the background quieter
    "tier3_paladin": dict(region=[(0.64, 0.76, 0.24, 0.34), (0.80, 1.00, 0.18, 0.44)], outside=0.3),
    # the dragon's mouth glow larger (wider, softer spread)
    "raid_ony": dict(near=8.0, far=55.0, mix=(0.60, 0.85)),
    # Karl (2026-10-13): only the helmet's two eyes, the dragon staff's mouth, the shoulder snake's
    # eyes and its mouth. Each spot is baked on its own and scaled alone, so a small eye is not
    # lost beside the big glowing orb in the snake's mouth; weight sets how strongly each shows.
    "set_tier2_warlock": dict(spots=[
        ((0.535, 0.57, 0.285, 0.315), 0.55, dict(near=3.0, far=14.0)),            # helmet eyes
        ((0.585, 0.63, 0.255, 0.285), 0.55, dict(near=3.0, far=14.0)),
        ((0.43, 0.53, 0.655, 0.78), 0.6, {}),                                      # dragon staff mouth
        ((0.70, 0.73, 0.335, 0.375), 0.55, dict(near=3.0, far=14.0)),             # shoulder snake eyes
        ((0.752, 0.782, 0.33, 0.36), 0.55, dict(near=3.0, far=14.0)),
        ((0.77, 0.90, 0.38, 0.53), 0.7, {})]),                                     # shoulder snake mouth                                         # shoulder snake mouth
    # sparks are small: a tighter halo
    "social_waves": dict(region=[(0.58, 0.93, 0.57, 0.79)], near=3.0, far=18.0),
    # the frost burst at the claw; the bright streaks everywhere else at a quarter
    "raid_naxx": dict(region=[(0.74, 0.92, 0.04, 0.30)], outside=0.25),
    # the flares and the light column, with his bright shoulder plates hushed
    "social_guild": dict(region=[(0.28, 1.00, 0.00, 0.22)], quiet=[((0.36, 0.95, 0.08, 0.22), 0.3)]),
    # the glare breaking through the storm behind the right head, and the eye; the rest quiet
    "social_guild_dungeon": dict(region=[(0.70, 1.00, 0.04, 0.42), (0.40, 0.47, 0.48, 0.56)], outside=0.2),
}

# Blooms baked in zones (a texture per band of the picture, each breathing on its own beat in
# Core.lua's B.bloomParts). The listed v fractions are where one zone gives way to the next, with
# ramps that add up to a whole, so the zones together are exactly the one bloom, seamlessly.
# A plain list cuts the picture into bands from top to bottom. A dict with an `angle` cuts it along
# a direction instead (degrees, measured in the master's own pixels, 0 = left to right, negative =
# up to the right), the cuts being fractions of the picture's extent along it: Thunderfury's
# follow its blade, from the tip at the lower left up to the gem.
ZONES = {"atiesh": [0.30, 0.50, 0.68],
         "thunderfury": {"angle": -32, "cuts": [0.40, 0.55, 0.68]}}
ZONE_RAMP = 0.05

TILE_W, TILE_H = 480, 360


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out_dir = Path(args[0]) if args else ROOT / "reports" / "image-tests" / "bloom"
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((FINAL / "runtime-manifest.json").read_text(encoding="utf-8"))
    font = ImageFont.load_default()
    tiles, report = [], []
    # --only a,b,c bakes just those stems (the others are left as they are)
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    for stem, label in STEMS.items():
        if only and stem not in only:
            continue
        info = manifest.get(stem)
        if not info:
            print("no master for", stem)
            continue
        master = FINAL / info["source"]
        if not master.exists():
            print("missing file", master)
            continue
        opts = dict(OVERRIDES.get(stem, {}))
        spots = opts.pop("spots", None)
        opts.setdefault("region", REGIONS.get(stem))
        if spots:
            opts.pop("region", None)
            parts = [B.bloom_alpha(master, region=[box], **{**opts, **extra})[0].astype("float32") * weight
                     for box, weight, extra in spots]
            alpha = np.maximum.reduce(parts).astype("uint8")
        else:
            alpha, bloom = B.bloom_alpha(master, **opts)
        data = B.encode_blp(alpha)
        zone_spec = ZONES.get(stem)
        if zone_spec:
            h_, w_ = alpha.shape
            vs = ((np.arange(h_) + 0.5) / h_)[:, None] * np.ones((1, w_))
            us = ((np.arange(w_) + 0.5) / w_)[None, :] * np.ones((h_, 1))
            if isinstance(zone_spec, dict):
                cuts = zone_spec["cuts"]
                th = np.radians(zone_spec["angle"])
                # position along the direction, in the master's pixels (1200 x 900), spread over 0 to 1
                proj = us * 1200 * np.cos(th) + vs * 900 * np.sin(th)
                coord = (proj - proj.min()) / (proj.max() - proj.min())
            else:
                cuts, coord = zone_spec, vs

            def below(cut):  # 0 before the cut, 1 after it, smooth over the ramp
                x = np.clip((coord - (cut - ZONE_RAMP)) / (2 * ZONE_RAMP), 0, 1)
                return x * x * (3 - 2 * x)
            edges = [np.ones_like(coord)] + [below(c) for c in cuts] + [np.zeros_like(coord)]
            for k in range(len(edges) - 1):
                weight = edges[k] - edges[k + 1]
                zone = np.round(alpha.astype(np.float32) * weight).astype(np.uint8)
                (out_dir / f"{stem}-bloom-{k + 1}.blp").write_bytes(B.encode_blp(zone))
        else:
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
            if stem in ZONES:
                zs = ZONES[stem]
                for k in range(len(zs["cuts"] if isinstance(zs, dict) else zs) + 1):
                    shutil.copy(out_dir / f"{stem}-bloom-{k + 1}.blp", ROOT / "Media" / f"{stem}-bloom-{k + 1}.blp")
            else:
                shutil.copy(out_dir / f"{stem}-bloom.blp", ROOT / "Media" / f"{stem}-bloom.blp")
        print("installed into Media/")


if __name__ == "__main__":
    main()
