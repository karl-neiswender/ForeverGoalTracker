# Light bloom candidates (Karl, 2026-10-13)

Karl's list of banners that have a light worth blooming, mapped to banner images (stems) by `tools/bloomall.py`. Previews were made before anything was installed. Blooms are white-plus-alpha BLP files (`Media/<stem>-bloom.blp`, about 87 KB each); a spec asks for one with `bloom = { "<stem>-bloom", strength = 0.6 }`.

Four entries bloom only the spot Karl named (REGIONS in `tools/bloomall.py`): the Stormpike Charger's eye, the Arcanist staff gem, Cryptstalker's shoulders and the Zulian Tiger's eyes.

| Name on the list | Image | Size | Alpha error (max / mean) | Share of picture that blooms |
|---|---|---|---|---|
| Ruins of Ahn'Qiraj | raid_aq20 | 86 KB | 11 / 0.26 | 8% |
| Temple of Ahn'Qiraj | raid_aq40 | 86 KB | 11 / 0.24 | 7% |
| Alliance war mount / Stormpike Charger (eyes) | pvp_mount_ally | 86 KB | 15 / 0.05 | 1% |
| Arcanist Regalia (staff gem) | set_tier1_mage | 86 KB | 11 / 0.06 | 2% |
| Corrupted Ashbringer | ashbringer | 86 KB | 13 / 0.15 | 3% |
| Atiesh | atiesh | 86 KB | 14 / 0.37 | 10% |
| Blackwing Lair + attunement | raid_bwl | 86 KB | 11 / 0.17 | 3% |
| Benediction | benediction | 86 KB | 12 / 0.18 | 4% |
| Benediction (Alliance art) | benediction-alliance | 86 KB | 13 / 0.5 | 15% |
| Cenarion Raiment | set_tier1_druid | 86 KB | 14 / 0.52 | 14% |
| Charger | mount_charger | 86 KB | 9 / 0.3 | 12% |
| Cryptstalker (shoulders) | tier3_hunter | 86 KB | 14 / 0.13 | 3% |
| Deathcharger | mount_deathcharger | 86 KB | 14 / 0.34 | 8% |
| Dire Maul key | key_dm | 86 KB | 11 / 0.32 | 8% |
| Dragonstalker | set_tier2_hunter | 86 KB | 14 / 0.43 | 9% |
| Dreadsteed | mount_dreadsteed | 86 KB | 12 / 0.32 | 9% |
| Dreamwalker Raiment | tier3_druid | 86 KB | 14 / 0.3 | 6% |
| Dreamwalker Raiment (Horde art) | tier3_druid-horde | 86 KB | 11 / 0.25 | 6% |
| Earthfury | set_tier1_shaman | 86 KB | 13 / 0.59 | 17% |
| Earthshatter | tier3_shaman | 86 KB | 14 / 0.43 | 10% |
| Frostfire Regalia | tier3_mage | 86 KB | 11 / 0.37 | 10% |
| Hyjal Summit | raid_hyjal | 86 KB | 11 / 0.46 | 17% |
| Molten Core attunement | att_mc | 86 KB | 11 / 0.53 | 16% |
| Molten Core | raid_mc | 86 KB | 13 / 0.37 | 10% |
| Naxxramas attunement (also Tier 3 fallback) | att_naxx | 86 KB | 14 / 0.27 | 6% |
| Netherwind Regalia | set_tier2_mage | 86 KB | 10 / 0.43 | 17% |
| Nightslayer | set_tier1_rogue | 86 KB | 10 / 0.32 | 9% |
| Nightslayer (Alliance art) | set_tier1_rogue-alliance | 86 KB | 13 / 0.26 | 6% |
| Slay Onyxia | raid_ony | 86 KB | 11 / 0.43 | 12% |
| Onyxia attunement (Alliance) | att_ony_ally | 86 KB | 12 / 0.16 | 3% |
| Onyxia attunement (Horde) | att_ony_horde | 86 KB | 11 / 0.24 | 7% |
| Redemption | tier3_paladin | 86 KB | 11 / 0.2 | 7% |
| Skeleton Key | key_scholo | 86 KB | 14 / 0.29 | 7% |
| Stratholme key + The Devout | key_strat | 86 KB | 13 / 0.13 | 3% |
| Sulfuras | sulfuras | 86 KB | 15 / 0.33 | 8% |
| Thorium Brotherhood | rep_thorium | 86 KB | 11 / 0.39 | 14% |
| Wolfsbane | wolfsbane | 86 KB | 11 / 0.38 | 13% |
| Swift Zulian Tiger (eyes) | mount_tiger | 86 KB | 13 / 0.05 | 1% |

Goals that share an image get its bloom: Blackwing Lair and its attunement (raid_bwl), Stratholme key and The Devout (key_strat), the Naxxramas attunement and the Tier 3 sets without their own art (att_naxx), both Dreamwalker, Benediction and Nightslayer art variants.
