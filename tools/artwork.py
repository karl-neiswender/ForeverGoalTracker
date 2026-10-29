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
    "allclasses_gnome_warlock_male": "leveling/gnome-warlock-male-master.png",
    "allclasses_gnome_warrior_female": "pvp/gnome-warrior-female-master.png",
    "collect_the_1_ring": "collect_the_1_ring-master.png",
    "allclasses_undead_priest_male": "allclasses_undead_priest_male-master.png",
    "allclasses_undead_priest_female": "allclasses_undead_priest_female-master.png",
    "allclasses_human_rogue_female": "allclasses_human_rogue_female-master.png",
    "allclasses_human_hunter_male": "allclasses_human_hunter_male-master.png",
    "dungeon_hunter_human_male": "dungeon_hunter_human_male-master.png",
    "allclasses_human_paladin_male": "allclasses_human_paladin_male-master.png",
    "allclasses_undead_rogue_female": "leveling/undead-rogue-female-master.png",
    "allclasses_undead_rogue_male": "leveling/undead-rogue-male-master.png",
    "allclasses_human_rogue_male": "leveling/human-rogue-male-master.png",
    "allclasses_gnome_warrior_male": "tier-sets/warrior/tier2-gnome-male-master.png",
    "core_hound_tooth": "core-hound-tooth-master.png",
    "bloodseeker": "bloodseeker-master.png",
    "blackcrow": "blackcrow-master.png",
    "brutality_blade": "brutality-blade-master.png",
    "set_tier2_rogue-alliance": "tier-sets/rogue/tier2-alliance-nightelf-master.png",
    "allclasses_gnome_warlock_female": "leveling/gnome-warlock-female-master.png",
    "allclasses_dwarf_hunter_female": "leveling/dwarf-hunter-female-master.png",
    "pvp_set_plate_ally_warrior_gnome_female": "pvp/gnome-warrior-female-master.png",
    "set_tier1_rogue_dwarf_female": "tier-sets/rogue/tier1-dwarf-female-master.png",
    "might_of_menethil": "might-of-menethil-master.png",
    "sulthraze": "sulthraze-master.png",
    "fiery_war_axe": "fiery-war-axe-master.png",
    "viskag": "viskag-bloodletter-master.png",
    "unstoppable_force": "unstoppable-force-master.png",
    "immovable_object": "immovable-object-master.png",
    "wand_of_biting_cold": "wand-of-biting-cold-master.png",
    "mass_of_mcgowan": "mass-of-mcgowan-master.png",
    "twig_of_the_world_tree": "twig-of-the-world-tree-master.png",
    "set_forever_raid_alliance": "set_forever_raid-master.png",
    "set_forever_raid_horde": "forever-hyjal-horde-master.png",
    "ancient_bone_bow": "ancient-bone-bow-master.png",
    "annihilator": "annihilator-master.png",
    "azuresong_mageblade": "azuresong-mageblade-master.png",
    "set_scarlet_crusade": "scarlet-crusade-master.png",
    "widows_remorse": "widows-remorse-master.png",
    "lobotomizer": "the-lobotomizer-master.png",
    "demonslayer": "demonslayer-master.png",
    "claw_of_the_black_drake": "claw-of-the-black-drake-master.png",
    "social_dances_alliance": "dance-alliance-master.png",
    "social_dances_horde": "dance-horde-master.png",
    "cloth_donations": "donate-cloth-master.png",
    "social_chests": "chests-master.png",
    "allclasses_troll_hunter_female": "leveling/troll-hunter-female-master.png",
    "allclasses_troll_warlock": "leveling/troll-warlock-master.png",
    "set_tier1_shaman_troll": "tier-sets/shaman/tier1-troll-master.png",
    "allclasses_troll_priest": "leveling/troll-priest-master.png",
    "tier3_rogue_troll": "tier-sets/rogue/tier3-troll-master.png",
    "allclasses_troll_rogue": "leveling/troll-rogue-master.png",
    "social_buffs_horde": "social/buffs-horde-master.png",
    "social_buffs_alliance": "social-buffs/alliance-buff-others-master.png",
    "pvp_troll_hunter_mail": "pvp/troll-hunter-mail-master.png",
    "allclasses_troll_hunter_male": "leveling/troll-hunter-male-master.png",
    "allclasses_orc_rogue": "leveling/orc-rogue-master.png",
    "allclasses_human_hunter": "leveling/human-hunter-master.png",
    "allclasses_human_paladin": "leveling/human-paladin-master.png",
    "allclasses_human_warrior_female": "leveling/human-warrior-female-master.png",
    "allclasses_human_warrior_male": "leveling/human-warrior-male-master.png",
    "tier3_rogue_human": "tier-sets/rogue/tier3-human-master.png",
    "allclasses_gnome_caster": "leveling/gnome-caster-master.png",
    "tier3_priest_gnome": "tier-sets/priest/tier3-gnome-master.png",
    "allclasses_gnome_rogue": "leveling/gnome-rogue-master.png",
    "allclasses_nightelf_warrior_male": "leveling/nightelf-warrior-male-master.png",
    "allclasses_nightelf_warrior_female": "leveling/nightelf-warrior-female-master.png",
    "allclasses_nightelf_rogue": "leveling/nightelf-rogue-master.png",
    "allclasses_dwarf_warrior": "leveling/dwarf-warrior-master.png",
    "allclasses_dwarf_rogue": "leveling/dwarf-rogue-master.png",
    "pvp_theramore_expedition": "reputations/theramore-expeditionary-force-master.png",
    "pvp_darkspear_raiders": "reputations/darkspear-raiders-master.png",
    "touch_of_chaos": "weapons/touch-of-chaos-master.png",
    "thrash_blade": "weapons/thrash-blade-master.png",
    "wand_of_eternal_light": "weapons/wand-of-eternal-light-master.png",
    "wraith_scythe": "weapons/wraith-scythe-master.png",
    "hammer_of_grace": "weapons/hammer-of-grace-master.png",
    "cruel_hand_of_timmy": "weapons/cruel-hand-of-timmy-master.png",
    "raid_kazzak": "raids/lord-kazzak-master.png",
    "raid_barrow": "raids/burrow-deeps-master.png",
    "social_lol": "social/say-lol-master.png",
    "social_hugs": "social/give-hugs-master.png",
    "arcanite_reaper": "weapons/arcanite-reaper-master.png",
    "teebus": "weapons/teebus-longsword-master.png",
    "pvp_set_cloth_horde": "pvp/warlord-cloth-thysta-clean-master.png",
    "set_tier25_leather": "tier-sets/aq40/leather-telrander-master.png",
    "set_tier25_plate": "tier-sets/aq40/plate-savin-master.png",
    "tier3_warlock-horde": "tier-sets/warlock/tier3-horde-pagatha-master.png",
    "set_tier2_hunter-alliance": "tier-sets/hunter/tier2-alliance-nordrassil-master.png",
    "social_guild_raid": "social/raids-with-guildmates-master.png",
    "pvp_set_leather_ally": "pvp/marshal-leather-moonshadow-master.png",
    "social_trades": "social/make-trades-master.png",
    "set_tier25_hunter": "tier-sets/hunter/strikers-garb-master.png",
    "pvp_rank14": "morning-2026-10-14/rank14-victory-backlit-master.png",
    "prof_blacksmithing-horde": "professions/blacksmithing-horde-master.png",
    "social_cheers": "social-cheers-master.png",
    "pvp_set_mail_ally": "pvp/marshal-mail-master.png",
    "rep_ambassador_horde_thunderbluff": "cities/thunderbluff-master.png",
    "rep_ambassador_horde_undercity": "cities/undercity-master.png",
    "rep_ambassador_ally_ironforge": "cities/ironforge-master.png",
    "rep_ambassador_ally_darnassus": "cities/darnassus-master.png",
    "pvp_mount_horde": "pvp/war-kodo-master.png",
    "social_friends": "social-friends-master.png",
    "pvp_set_plate_ally": "pvp/plate/marshal-master.png",
    "pvp_set_plate_horde": "pvp/plate/warlord-master.png",
    "social_buffs_mage": "social-buffs/mage-master.png",
    "social_buffs_druid": "social-buffs/druid-master.png",
    "social_buffs_paladin": "social-buffs/paladin-master.png",
    "social_buffs_priest": "social-buffs/priest-master.png",
    "att_ony_ally": "onyxia-alliance-master.png",
    "att_ony_horde": "onyxia-horde-master.png",
    "set_dungeon1_paladin": "lightforge-master.png",
    "allclasses_dwarf_paladin": "dwarf-paladin-master.png",
    "pvp_set_cloth_ally": "pvp/marshal-cloth-durgle-master.png",
    "set_dungeon1_shaman": "tier-sets/shaman/elements-five-thunders-master.png",
    "set_dungeon2_shaman": "tier-sets/shaman/elements-five-thunders-master.png",
    "set_tier1_hunter-alliance": "tier-sets/hunter/giantstalker-alliance-master.png",
    "set_dungeon1_warlock": "dreadmist-master.png",
    "set_dungeon2": "set_dungeon2-scholomance-master.png",
    "set_forever_raid": "set_forever_raid-master.png",
    "set_dungeon2_hunter": "beastmaster-hunter-master.png",
    "ashbringer": "weapons/ashbringer-ryman-master.png",
    "set_dungeon1_warrior": "tier-sets/warrior/valor-alliance-master.png",
    "pvp_set_mail_horde_shaman": "pvp/warlord-mail-shaman-master.png",
    "key_strat": "stratholme/master.png",
    "key_ubrs": "blackrock-spire/master.png",
    "prof_engineering-horde": "professions/engineering-horde-master.png",
    "prof_engineering": "professions/engineering-master.png",
    "prof_mining": "professions/mining-master.png",
    "rep_hydraxian": "reputations/hydraxian-waterlords-master.png",
    "rep_nozdormu": "morning-2026-10-14/brood-nozdormu-master.png",
    "rep_cenarion": "reputations/cenarion-circle-master.png",
    "prof_herbalism": "professions/herbalism-master.png",
    "prof_alchemy": "professions/alchemy-master.png",
    "prof_first_aid": "professions/first-aid-master.png",
    "prof_cooking": "professions/cooking-master.png",
    "prof_fishing": "professions/fishing-master.png",
    "prof_blacksmithing": "morning-2026-10-14/blacksmithing-alliance-master.png",
    "prof_leatherworking": "professions/leatherworking-master.png",
    "prof_enchanting": "professions/enchanting-master.png",
    "prof_tailoring": "professions/tailoring-master.png",
    "mount_charger": "mounts/charger-master.png",
    "raid_naxx": "morning-2026-10-14/naxxramas-kelthuzad-master.png",
    "social_waves": "morning-2026-10-14/social-wave-master.png",
    "social_guild": "morning-2026-10-14/social-guild-master.png",
    "social_guild_dungeon": "morning-2026-10-14/dungeons-with-guildmates-master.png",
    "social_summons": "morning-2026-10-14/warlock-summoning-master.png",
    "set_partners_in_crime": "morning-2026-10-14/partners-in-crime-master.png",
    "set_tier1_rogue-alliance": "tier-sets/rogue/tier1-alliance-master.png",
    "allclasses_dwarf_hunter": "leveling/dwarf-hunter-master.png",
    "raid_bwl": "blackwing-lair/classic-key-art-master.png",
    "set_dungeon1_hunter": "tier-sets/hunter/beaststalker-master.png",
    "benediction-alliance": "weapons/benediction-alliance-master.png",
    "rep_thorium": "reputations/thorium-brotherhood-master.png",
    "pvp_wsg_ally": "reputations/silverwing-sentinels-master.png",
    "pvp_wsg_horde": "reputations/warsong-outriders-master.png",
    "pvp_av_ally": "reputations/stormpike-guard-master.png",
    "wolfsbane": "weapons/wolfsbane-master.png",
    "mount_tiger": "mounts/swift-zulian-tiger-master.png",
    "pvp_av_horde": "pvp/frostwolf-master.png",
    "rep_ambassador_ally": "reputations/ambassador-alliance-master.png",
    "rep_ambassador_horde": "reputations/ambassador-horde-master.png",
    "mount_qiraji_aq": "mounts/aq-battle-tanks.jpg",
    "fishing_extravaganza": "fishing/booty-bay-review.png",
    "set_tier25": "tier-sets/aq40/tier25-review-v2.png",
    "tier3_hunter": "tier-sets/hunter/tier3.jpg",
    "tier3_warlock-alliance": "tier-sets/warlock/tier3-alliance.jpg",
    "set_tier2_warlock-alliance": "tier-sets/warlock/tier2-alliance.jpg",
    "set_tier2_druid-horde": "tier-sets/druid/tier2-horde.jpg",
    "set_tier1_paladin": "tier-sets/paladin/lawbringer-master.png",
    "allclasses_nightelf_hunter": "leveling/nightelf-hunter.jpg",
    "allclasses_horde_hunter": "leveling/horde-hunter.jpg",
    "pvp_mount_ally": "pvp/alliance-mounts.jpg",
    "gold_5k": "additional-goals/gold.jpg",
    "pvp_set_mail_horde": "pvp/warlord-mail.jpg",
    "rep_timbermaw": "reputation/timbermaw.jpg",
    "mount_qiraji": "mounts/scarab-lord-review.png",
    "zinrokh": "weapons/zinrokh-master.png",
    "sword_of_zeal": "weapons/sword-of-zeal-master.png",
    "staff_of_the_ruins": "weapons/staff-of-the-ruins-master.png",
    "staff_of_dominance": "weapons/staff-of-dominance-master.png",
    "spinal_reaper": "weapons/spinal-reaper-master.png",
    "set_tier1_priest-horde": "tier-sets/priest/tier1-horde-master.png",
    "silent_fang": "weapons/silent-fang-master.png",
    "shadowstrike": "weapons/shadowstrike-master.png",
    "rod_of_the_ogre_magi": "weapons/rod-of-the-ogre-magi-master.png",
    "hungering_cold": "weapons/hungering-cold-master.png",
    "maladath": "weapons/maladath-master.png",
    "destiny": "weapons/destiny-master.png",
    "ashkandi": "weapons/ashkandi-master.png",
    "bonereavers_edge": "weapons/bonereavers-edge-master.png",
    "deathbringer": "weapons/deathbringer-master.png",
    "flame_wrath": "weapons/flame-wrath-master.png",
    "frostguard": "weapons/frostguard-master.png",
    "gift_of_the_elven_magi": "weapons/gift-of-the-elven-magi-master.png",
    "glacial_blade": "weapons/glacial-blade-master.png",
    "gutgore_ripper": "weapons/gutgore-ripper-master.png",
    "halberd_of_smiting": "weapons/halberd-of-smiting-master.png",
    "illusionary_rod": "weapons/illusionary-rod-master.png",
    "inventors_focal_sword": "weapons/inventors-focal-sword-master.png",
    "jindos_judgement": "weapons/jindos-judgement-master.png",
    "krol_blade": "weapons/krol-blade-master.png",
    "mograines_might": "weapons/mograines-might-master.png",
    "obsidian_edged_blade": "weapons/obsidian-edged-blade-master.png",
    "headmasters_charge": "weapons/headmasters-charge-master.png",
    "aurastone_hammer": "weapons/aurastone-hammer-master.png",
    "lava_dredger": "weapons/lava-dredger-master.png",
    "will_of_arlokk": "weapons/will-of-arlokk-master.png",
    "mandokirs_sting": "weapons/mandokirs-sting-master.png",
    "perditions_blade": "weapons/perditions-blade-master.png",
    "allclasses_dwarf_shaman": "leveling/dwarf-shaman-barador-master.png",
    "pvp_drums_of_war": "pvp/drums-of-war.jpg",
    "epicmounts_undead": "mounts/skeletal-warhorse-master.png",
    "pvp_arathi": "pvp_arathi-master.png",
    "allclasses_tauren_warrior": "allclasses_tauren_warrior-master.png",
    "allclasses_alliance_warlock": "allclasses_alliance_warlock-master.png",
    "allclasses_horde_druid": "allclasses_horde_druid-master.png",
    "epicmounts_skyborne": "mounts/skyborne-mount-master.png",
    "allclasses_skyborne_rogue": "mounts/skyborne-location.jpg",
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
    "epicmounts_tauren": "mounts/swift-kodo-master.png",
    "epicmounts_dwarf": "mounts/dwarf-ram.jpg",
    "epicmounts_gnome": "mounts/gnome-mechanostrider.jpg",
    "rep_argentdawn": "reputation/rep_argentdawn.jpg",
    **{goal: "tall-1200x900/" + goal + ".jpg" for goal in (
        "atiesh", "sulfuras", "thunderfury",
        "quelserrar", "benediction", "raid_mc", "att_mc", "set_tier1",
        "lokdelar", "frostsaber", "set_viper", "key_scholo")},
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
    "tier3_warrior_koringar": "tier-sets/warrior/tier3-koringar-master.png",
    "tier3_mage": "tier-sets/mage/tier3.jpg",
    "tier3_priest": "tier-sets/priest/tier3.jpg",
    "set_tier2_priest": "tier-sets/priest/tier2.jpg",
    "set_tier1_priest": "tier-sets/priest/tier1-alliance-new-master.png",
    "set_tier1_priest-horde": "tier-sets/priest/tier1-horde-master.png",
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


# Banners that wait for their approved master (the file may not exist yet). Each is compiled the
# moment its master is in Media/final-images, after which `pending=true` comes off its variant in
# Core.lua (B.artVariants). Same 1200x900 monochrome treatment as the others, left and bottom
# gradients baked in.
PENDING_BANNERS = {
    "rep_ambassador_ally_ironforge": "reputations/ambassador-ironforge-master.png",
    "rep_ambassador_ally_darnassus": "reputations/ambassador-darnassus-master.png",
    "rep_ambassador_horde_thunderbluff": "reputations/ambassador-thunderbluff-master.png",
    "rep_ambassador_horde_undercity": "reputations/ambassador-undercity-master.png",
}


def build_final():
    """Compile approved masters only, without touching candidate artwork."""
    manifest = {}
    banners = dict(FINAL_BANNERS)
    for goal, filename in PENDING_BANNERS.items():
        if (FINAL / filename).exists():
            banners[goal] = filename
        else:
            print(goal, "waiting for", filename)
    for goal, filename in banners.items():
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
