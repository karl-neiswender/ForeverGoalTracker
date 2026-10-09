"""Write Karl's goal-banner acquisition list from the saved Lua catalog."""
from pathlib import Path
import csv
import json
import re

ROOT = Path(__file__).resolve().parents[1]
CATALOG = json.loads((ROOT / "reports/Goal banner catalog.json").read_text(encoding="utf-8"))
ART = ROOT / "Media/artwork"
# Art direction, not assertions about Forever's unverified gameplay eligibility.
SPECS = '''
ashbringer|Corrupted Ashbringer sword close-up; optional Four Horsemen background|Corrupted version, not purified Ashbringer; weapon-only avoids class/race bias|
frostsaber|Winterspring Frostsaber in snowy Winterspring|Alliance theme; exact purple/pink mount, not a generic saber; Night Elf rider optional|Frostsaber_Matriarch_HS.jpg
atiesh|Atiesh staff, upright or diagonal, with Naxxramas atmosphere|Staff-only; if a wielder is shown, Druid/Mage/Priest/Warlock|
rhokdelar|Rhok'delar bow in Felwood, clearly showing its distinctive limbs|Hunter only if a wielder is shown; either faction|Rhok'delar_full.jpg
lokdelar|Lok'delar staff beside the Felwood ancient quest givers|Hunter only if a wielder is shown; do not substitute Rhok'delar bow|
thunderfury|Thunderfury sword close-up, lightning silhouette on the right|Weapon-only preferred; either faction; verify any wielder's compatibility in the target client|thunderfury.png
tier3|Full Tier 3 armor lineup or a clearly identifiable class set in Naxxramas|Nine class sets; see exact-name matrix below; boss image already usable as a shared theme|
benediction|Benediction and Anathema staff pair, or existing Anathema alone|Priest only if a wielder is shown; both factions|
epicmounts|Lineup of classic epic racial mounts; separate Alliance/Horde variants ideal|Mount identities matter; rider need not be the mount's native race; see mount list below|orc-wolf-mount.jpg
sulfuras|Sulfuras hammer close-up, embers or Molten Core behind it|Weapon-only preferred; both factions|
allclasses|Diverse group of level-60 adventurers representing the nine classes|All classes; balanced Alliance/Horde versions or a faction-neutral composition|pvp-alliance-horde-human-orc.jpg
rep_timbermaw|Timbermaw furbolgs or Timbermaw Hold entrance|Neutral reputation, both factions; actual furbolgs rather than player race|Furbolg_Spiritbinder_TCG.jpg
rep_thorium|Thorium Brotherhood forge, dark iron smiths, Lokhtos or Thorium Point|Neutral reputation; dwarf NPCs appropriate, no dwarf player requirement|
rep_argentdawn|Argent Dawn banner and Light's Hope Chapel, with Argent NPCs|Neutral reputation; avoid Argent Crusade/Wrath replacements|
rep_cenarion|Cenarion Circle druids at Cenarion Hold in Silithus|Neutral reputation; not restricted to Druid players|Moonwell_full.jpg
rep_zandalar|Zandalar Tribe on Yojamba Isle; trolls, shrines and jungle|Neutral reputation; troll NPCs appropriate, not Horde-only player content|
rep_hydraxian|Duke Hydraxis or a water elemental on the Azshara coast|Neutral reputation; water rather than fire elemental|Water_Invocation_full.jpg
rep_nozdormu|Anachronos/bronze dragon at Caverns of Time, or AQ bronze-dragon atmosphere|Neutral reputation; avoid unrelated dragonflights|
rep_ambassador_ally|Stormwind, Ironforge and Darnassus landmarks with Alliance heraldry|Alliance only; Human/Dwarf/Gnome/Night Elf city themes; not Horde scenery|
rep_ambassador_horde|Orgrimmar, Thunder Bluff and Undercity landmarks with Horde heraldry|Horde only; Orc/Tauren/Troll/Forsaken city themes; not Alliance scenery|
mount_deathcharger|Rivendare's Deathcharger, mounted or alone, in Stratholme|Exact skeletal horse reward; neutral goal, either-faction rider|
mount_raptor|Swift Razzashi Raptor in Zul'Gurub jungle|Exact raid mount, not a generic raptor; both factions|Sunscale_Raptor_full.jpg
mount_tiger|Swift Zulian Tiger in Zul'Gurub jungle|Exact orange/black striped reward; both factions|
mount_qiraji|Black Qiraji battle tank/silithid mount at the Scarab Wall|Exact black mount; not a colored AQ-only crystal mount|
mount_dreadsteed|Warlock epic Dreadsteed with fire hooves, in ritual/warlock setting|Warlock only if rider shown; either faction; Classic model preferred|warlock-mount-dreadsteed.jpg
mount_charger|Paladin Charger in gold/holy armor, mounted or alone|Paladin only if rider shown; Classic Alliance look; Forever faction/class combinations must match client|paladin-mount-charger.jpg
quelserrar|Quel'Serrar sword; existing approved Quel'Delar illustration can remain|Karl explicitly approved the substitute; actual Quel'Serrar reference would be an optional upgrade|
raid_mc|Ragnaros in Molten Core|Raid encounter, both factions; already covered|
raid_ony|Onyxia in her lair, wings/head on the right|Raid encounter, both factions; no faction-specific player needed|Onyxia_full.jpg
raid_bwl|Nefarian in Blackwing Lair, throne room or dragon silhouette|Both factions; Blackwing Lair, not Blackrock Caverns/Blackwing Descent|blackwinglair.jpg
raid_zg|Hakkar or recognizable Zul'Gurub temple vista|Both factions; original Zul'Gurub, not a later dungeon remake|
raid_aq20|Ossirian or Ruins of Ahn'Qiraj exterior/arena|Both factions; differentiate Ruins/AQ20 from Temple/AQ40|
raid_aq40|C'Thun or Twin Emperors inside Temple of Ahn'Qiraj|Both factions; differentiate Temple/AQ40 from Ruins/AQ20|
raid_naxx|Kel'Thuzad in Naxxramas|Both factions; original level-60 raid atmosphere|
raid_hyjal|Actual Forever Hyjal Summit vista or confirmed Forever boss scene|Forever-specific; do not use TBC Archimonde automatically|hyjal.jpg
raid_barrow|Actual Forever Barrow Deeps interior or confirmed encounter|Forever-specific; not an arbitrary night-elf cave|
att_mc|Blackrock Depths core-fragment portal or Lothos Riftwaker|Both factions; existing Blackrock/Ragnaros scene is an acceptable shared theme|
att_ony_ally|Marshal Windsor escorted through Stormwind or Lady Katrana reveal|Alliance only; Human Stormwind setting; avoid Horde quest-chain NPCs|onyxia1.jpg
att_ony_horde|Rexxar/Goretooth or Emberstrife in Horde attunement context|Horde only; avoid Marshal Windsor/Stormwind escort|
att_bwl|Blackrock Spire entrance, Scarshield Infiltrator or orb of command|Both factions; Blackrock mountain/entrance alternative acceptable|blackwinglair.jpg
att_naxx|Naxxramas exterior or Angela Dosantos at Light's Hope Chapel|Both factions; already covered by Naxx exterior|
key_ubrs|Seal of Ascension ring or Upper Blackrock Spire entrance|Both factions; exact ring if using item art|
key_scholo|Skeleton Key close-up with Scholomance gate/ruins|Both factions; verify key silhouette is the actual reward|The_Skeleton_Key_full.jpg
key_brd|Shadowforge Key, Dark Iron architecture or Franclorn Forgewright|Both factions; Blackrock Depths, not unrelated dwarf city|
key_strat|Key to the City with Stratholme gate or Magistrate Barthilas|Both factions; undead city atmosphere|
key_dm|Crescent Key or Dire Maul East ruins with Pusillin|Both factions; elven ruins, not generic troll jungle|
prof_secondary|Fishing, cooking and bandaging vignette or tool arrangement|Three activities; any race/class/faction; no combat armor requirement|
prof_all|Crafting tools, anvil, alchemy bottles and gathering resources|All nine primary professions; neutral tools work for both factions|
gold_5k|Gold coins, coin pouch or open chest in a tavern/bank|Faction-neutral; avoid a fixed amount because target can change|
social_guild|Guild group portrait, guild tabard or raid preparation scene|Either faction; separate variants optional; group rather than lone hero|
social_friends|Two or three adventurers sitting/camping/exploring together|Either faction; friendly social context rather than combat|Relentless_Adventurer_full.jpg
set_tier1|Actual Tier 1 class-set lineup or full-body geared character|Nine exact sets below; existing Majordomo image is a temporary thematic alternative|druid-nightelf-alliance-tier1.jpg
set_tier2|Actual Tier 2 class-set lineup or full-body geared character|Nine exact sets below; don't mistake Dragonstalker for Tier 3|Ten_Storm_Thrall_full.jpg
set_dungeon1|Full Dungeon Set 1/Tier 0 character lineup|Nine exact sets below; not raid/PvP armor|
set_dungeon2|Full Dungeon Set 2/Tier 0.5 character lineup|Nine exact upgraded sets below; distinguish from Tier 0|
set_viper|Armor of the Fang wearer in Wailing Caverns; snake motif|Leather set, not class-locked; Forever snake-bonus theme appropriate|Lady_Anacondra_full.jpg
set_forever_raid|Actual Forever raid armor on class models|Nine exact Forever sets below; don't substitute familiar Classic tiers|
pvp_rank14_ally|Alliance champion with Grand Marshal weapons in battleground setting|Alliance only; recognizably Alliance armor/heraldry|Knight-Captain_full.jpg
pvp_rank14_horde|Horde champion with High Warlord weapons in battleground setting|Horde only; recognizably Horde armor/heraldry|orc-horde-pvp.jpg
pvp_mount_ally|Alliance rank-11 black war mounts in battleground/city setting|Alliance only; see mount list, exact war variant not ordinary racial mount|pvp-alliance-ram-dwarf.jpg
pvp_mount_horde|Horde rank-11 black war mounts in battleground/city setting|Horde only; see mount list, exact war variant not ordinary racial mount|pvp-horde-orc-wolf.jpg
pvp_avmount_ally|Stormpike Battle Charger, an armored ram in snowy Alterac Valley|Alliance only; exact AV mount, not an ordinary ram|Stormpike_Battle_Ram_full.jpg
pvp_avmount_horde|Frostwolf Howler in snowy Alterac Valley|Horde only; exact AV wolf, not an ordinary timber wolf|
pvp_wsg_ally|Silverwing Sentinels flag room, Alliance flag runner or Silverwing outpost|Alliance only; Warsong Gulch context|
pvp_wsg_horde|Warsong Outriders flag room, Horde flag runner or Warsong outpost|Horde only; Warsong Gulch context|
pvp_ab_ally|League of Arathor forces defending an Arathi Basin flag|Alliance only; Arathi Basin not Alterac Valley|
pvp_ab_horde|Defilers forces defending an Arathi Basin flag|Horde only; Arathi Basin not Alterac Valley|
pvp_av_ally|Stormpike defenders at Dun Baldar bridge/bunker|Alliance only; Alterac Valley snow and Alliance fortifications|Dun_Baldar_Bridge_full.jpg
pvp_av_horde|Frostwolf defenders at Iceblood/Frostwolf fortifications|Horde only; Alterac Valley snow and Horde fortifications|Iceblood_Garrison_full.jpg
pvp_hk|Alliance vs Horde skirmish, one readable combat silhouette per side|Both factions; battleground/world PvP rather than duel|pvp-alliance-horde-human-orc.jpg
pvp_duelist|Two adventurers facing off with a duel flag between them|Either faction; duel, not a raid or mass battleground|
'''


def main():
    specs = {}
    for line in SPECS.strip().splitlines():
        key, shot, restrictions, candidate = line.split("|", 3)
        specs[key] = (shot, restrictions, candidate)
    core = (ROOT / "Core.lua").read_text(encoding="utf-8")
    paths = core.split("B.artPaths = {", 1)[1].split("}", 1)[0]
    assigned = dict(re.findall(r'(\w+)\s*=\s*"([^"]+)"', paths))
    rows = []
    for g in CATALOG:
        key = g["id"]
        if key.startswith("pvp_set_"):
            faction = g["faction"]
            shot = f"{faction} full {key.split('_')[2]} PvP armor lineup, or the correct class set on a character"
            restrictions = faction + " only; Forever Premier PvP sets, exact class/set names below; don't substitute raid armor"
            candidate = "orc-horde-pvp.jpg" if faction == "Horde" else "Knight-Captain_full.jpg"
        else:
            shot, restrictions, candidate = specs[key]
        if key in assigned:
            status, priority, file = "ASSIGNED", "Done / optional upgrade", assigned[key]
        elif candidate and (ART / candidate).exists():
            status, priority, file = "CANDIDATE: visual verification needed", "Review uploaded image", candidate
        else:
            status, priority, file = "FIND", "Find image", ""
        rows.append({"goal_id": key, "goal": g["name"], "category": g["category"],
                     "status": status, "priority": priority, "shot": shot,
                     "faction_class_race_requirements": restrictions, "existing_file": file})
    assert len(rows) == 79 and len({r['goal_id'] for r in rows}) == 79
    out = ROOT / "reports/Goal banner shot list.md"
    counts = {s: sum(r['status'].startswith(s) for r in rows) for s in ['ASSIGNED','CANDIDATE','FIND']}
    lines = ["# Goal banner shot list", "", "Prepared for Karl, October 8, 2026. Covers all 79 goals in the current Lua catalog.", "",
             f"**{counts['ASSIGNED']} assigned · {counts['CANDIDATE']} have an uploaded candidate · {counts['FIND']} still need a suitable image.**", "",
             "A candidate is selected by filename/theme, not yet visually approved or hooked up. Some recent filenames label tiers incorrectly; verify the actual armor. Existing banner assignments are preserved.", "",
             "## What to collect first", "",
             "1. Installed: 16 approved monochrome 1200 x 900 masters, including the night elf hunter replacement for Rhok'delar. Older Onyxia, Dreadsteed, Charger and Naxxramas-family images are assigned but still available for a matching final treatment.",
             "2. Find the missing raid subjects: Hakkar/Zul'Gurub, Ossirian/AQ20, C'Thun/AQ40 and real Forever Barrow Deeps imagery. Check the uploaded Hyjal image against the actual Forever zone.",
             "3. Find faction-specific PvP scenes: separate Alliance/Horde Warsong Gulch and Arathi Basin, Frostwolf Howler, and identifiable rank-11 war mounts.",
             "4. Find neutral reputation/quest-location art and profession/social scenes. These can often cover several related goals without a class/race requirement.",
             "5. Collect accurate armor-model shots as optional upgrades to the shared boss imagery. Start with Tier 2 and Dungeon Sets 1/2, which currently have no assigned banner.", "",
             "## Framing that works in this addon", "",
             "- Keep the main subject in the right half, with clear head/weapon/mount silhouettes. The left edge fades away beneath the title and text.",
             "- Final approved masters are 1200 x 900 (4:3), with soft baked left/bottom darkening. Collect uncropped originals with generous room around the subject; portrait art can be reframed during treatment.",
             "- Prefer 1024px or larger originals when available. The build makes 512px compressed game textures and restores source proportions when displayed.",
             "- Keep color originals in artwork. Selected final masters are monochrome with stronger contrast and bypass addon desaturation; older color banners keep runtime desaturation until their final pass.",
             "- For screenshots, hide interface/nameplates, remove floating damage text, and avoid foreground effects obscuring the subject. Full-body armor shots should show helm, shoulders, chest and legs clearly.",
             "- One shared banner is currently supported per goal. Class/race/faction variants below are collection options, not an already implemented automatic switching feature.", "",
             "## Faction and race rules for choosing art", "",
             "Faction labels below describe the image we need. They are not a claim that all Forever gameplay restrictions match Classic. Use the addon's explicit faction goals for PvP, Ambassador and Onyxia attunement. For neutral goals, item/environment art usually avoids the need for duplicate faction versions.", "",
             "Winterspring Frostsaber should use an Alliance-themed mount shot. Dreadsteed should have a Warlock rider if any; Charger a Paladin. The mount's native race does not necessarily restrict the rider. Forever includes Alliance Shamans, Horde Paladins and Skyborne content in this catalog, so don't apply Classic-only race/class combinations to Forever screenshots.", "",
             "## Complete goal inventory", ""]
    categories = list(dict.fromkeys(g['category'] for g in CATALOG))
    for category in categories:
        lines += ["### " + category, "", "| Goal | Status / existing file | Shot to find | Faction, class or race direction |", "|---|---|---|---|"]
        for r in rows:
            if r['category'] != category:
                continue
            state = r['status'] + (" — `"+r['existing_file']+"`" if r['existing_file'] else "")
            lines.append(f"| {r['goal']} (`{r['goal_id']}`) | {state} | {r['shot']} | {r['faction_class_race_requirements']} |")
        lines.append("")
    lines += ["## Exact armor-set references", "", "These are the actual selectable sets in the addon. A shared group banner can be a lineup; the individual class shots are optional assets for future selected-class artwork. Armor type alone is not enough to identify the correct tier.", ""]
    set_order = ['set_tier1','set_tier2','tier3','set_dungeon1','set_dungeon2','set_forever_raid']
    sets = [next(g for g in CATALOG if g['id'] == key) for key in set_order]
    by_class = {}
    for g in sets:
        for part in g['parts']:
            who, name = part['name'].split(' - ', 1)
            by_class.setdefault(who, {})[g['id']] = name
    lines += ["| Class | Tier 1 | Tier 2 | Tier 3 | Dungeon 1 / Tier 0 | Dungeon 2 / Tier 0.5 | Forever raid set |", "|---|---|---|---|---|---|---|"]
    for who, table in by_class.items():
        lines.append('| '+who+' | '+' | '.join(table[g['id']] for g in sets)+' |')
    lines += ["", "Choose a race that can actually play the class on the photographed client. For a faction-neutral set banner, a model-only render or balanced lineup avoids choosing a player faction. The existing file `Dragonstalker_tier3-hunter-moltencore.jpg` needs relabeling/verification: **Dragonstalker is Tier 2; Cryptstalker is Tier 3; Giantstalker is Tier 1** in this catalog.", "",
              "### Forever PvP sets: eight separate faction/armor goals", "", "The catalog contains these exact set names. Verify the Premier/Forever appearance rather than assuming Classic PvP armor is identical.", "", "| Goal / faction | Required class sets |", "|---|---|"]
    for g in CATALOG:
        if g['id'].startswith('pvp_set_'):
            lines.append('| '+g['name']+' — '+g['faction']+' | '+'; '.join(p['name'] for p in g['parts'])+' |')
    lines += ["", "## Racial and PvP mount variants", "", "For Epic Racial Mounts, collect a clean shot of each mount family. A broad faction lineup is enough for the current shared banner; these individual variants make later selected-part art possible.", "", "| Native race / theme | Mount family | Image faction |", "|---|---|---|"]
    mounts = [('Human','Swift Steed','Alliance'),('Dwarf','Swift Ram','Alliance'),('Night Elf','Swift Saber','Alliance'),('Gnome','Swift Mechanostrider','Alliance'),('Orc','Swift Timber Wolf','Horde'),('Tauren','Great Kodo','Horde'),('Forsaken / Undead','Skeletal Warhorse','Horde'),('Troll','Swift Raptor','Horde'),('Skyborne','Swift Galestrider','Forever; confirm character faction in client')]
    for row in mounts: lines.append('| '+' | '.join(row)+' |')
    lines += ["", "For rank-11 war-mount goals, get the actual war variants: **Alliance:** Black War Steed, Black War Ram, Black War Tiger, Black Battlestrider. **Horde:** Black War Wolf, Black War Kodo, Black War Raptor, Red Skeletal Warhorse. These are separate from **Stormpike Battle Charger** and **Frostwolf Howler**, the two AV reputation mounts.", "",
              "## Efficient reuse", "", "- Naxx exterior: Naxxramas attunement; Kel'Thuzad: raid goal; Horsemen/Baron: Ashbringer or Tier 3 theme. The correct armor is still the best eventual set-banner subject.",
              "- Onyxia lair: Slay Onyxia and a neutral attunement fallback. Prefer Windsor for Alliance and Rexxar/Goretooth for Horde when making the two faction chains distinct.",
              "- Blackrock vista: BWL attunement or UBRS/BRD keys if it really depicts the location. The currently named Blackrock trailer image actually depicts a fire boss, so don't assume every file named Blackrock is a mountain vista.",
              "- WSG, AB and AV: one approved faction scene can cover that faction's battleground reputation goal and supplement its PvP banners. Keep each battleground identifiable.",
              "- One neutral tools shot can initially cover both profession goals. A forge alone is a Blacksmithing image, not a complete representation of all professions.", ""]
    out.write_text('\n'.join(lines), encoding='utf-8', newline='\n')
    with (ROOT / 'reports/Goal banner shot list.csv').open('w', newline='', encoding='utf-8-sig') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader(); writer.writerows(rows)
    print(f"79 goals: {counts}; {len(by_class)} classes in armor matrix; saved Markdown and CSV.")


if __name__ == '__main__':
    main()
