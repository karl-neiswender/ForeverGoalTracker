# Artist-credit follow-up — October 13, 2026

Revisited the ten named withheld candidates from the first pass. Four now have explicit attribution plus a visual match to the local original and installed master. Six remain blank. This pass does not constitute a complete fresh audit of the earlier 39 retained credits.

Credits acknowledge original illustrations adapted for banners. AI reconstruction, extension and grayscale edits are not attributed to the original artist. The installed Cryptstalker is a newly generated scene using a pose/style reference and therefore remains uncredited.

## Resolved

| Banner | Source artist | Evidence |
|---|---|---|
| Give Cheers (`social_cheers`) | Sean O'Daniels | [Hearthstone card](https://hearthstone.wiki.gg/wiki/Party_of_Four) and [Warcraft illustration file](https://warcraft.wiki.gg/wiki/File:Rise_and_Be_Recognized_TCG.jpg) both explicitly name the artist. Published full image matches the raised tankard, armored dwarf, seated rifleman and companions. The previous double-apostrophe concern is resolved by the current visible pages. |
| Thorium Brotherhood (`rep_thorium`) | Samwise Didier | [Exact file](https://warcraft.wiki.gg/wiki/File:War_Golem.jpg) names Samwise Didier, describes comic cover #10 and cites Sons of the Storm. The published image matches the local original, including its signature, golem, three dwarves and archway. The misspelled surname appears in an old upload comment; the current summary names the artist correctly. |
| Naxxramas raid (`raid_naxx`) | Mike Sutfin | [Exact file](https://warcraft.wiki.gg/wiki/File:Naxxramas_TCG_key_art.jpg) explicitly names Mike Sutfin and records the front/back images from his portfolio. Published composite and local original match Kel'Thuzad, three abominations, ghost, skeletons and skull arch. The old artist website could not be retrieved; no independent live-portfolio verification is claimed. |
| Giantstalker (`set_tier1_hunter`) | Tim Shevtsov | [Art Tavern's portfolio](https://www.artstation.com/artwork/28o1wg), titled Hearthstone Hero tiers pt.6, displays the exact painting and credits “Tier 1 (green) - Tim Shevtsov.” The [wiki file](https://hearthstone.wiki.gg/wiki/File:Giantstalker_Rexxar_full.jpg) agrees. This resolves the conflicting historical Lullabi/Zemskov patch note on the card page. One older portfolio link returned 404. |

For each of these four, visually compared the published artwork, local original and installed master. Read the saved editing record to confirm direct adaptation:

- Cheers: `reports/image-tests/social-cheers-2026-10-13.md` (includes low-resolution AI detail reconstruction).
- Thorium: `reports/image-tests/reputation-banners-2026-10-11.json`.
- Naxxramas: `reports/image-tests/profession-mount-raid-banners-2026-10-11.json`.
- Giantstalker: `reports/image-tests/hunter-tier-pass.json`.

Original/master/runtime SHA-256 hashes and source links are saved in `artwork-artist-evidence-2026-10-13.json` under `review_pass: follow-up`.

## Still blank

- Cryptstalker: saved prompt explicitly requests an original illustration and limits Selective Breeder to pose/style reference. Karl's correction is retained.
- Blackwing Lair: [exact file page](https://warcraft.wiki.gg/wiki/File:Blackwing_Lair_Classic_key_art.jpg) explicitly says the artist is unknown. Do not transfer a credit from other Blackrock art.
- AQ battle tanks: [Ultramarine file page](https://warcraft.wiki.gg/wiki/File:Ultramarine_Qiraji_Battle_Tank_TCG.jpg) supplies no individual artist. Also, the located black-qiraji editing record targets `mount_qiraji`, not `mount_qiraji_aq`; this record alone cannot establish the latter's lineage.
- Cooking, Alchemy and Horde Engineering: no usable explicit attribution established in this follow-up. Direct title/file lookups did not resolve the credit. No name added.

Also read both Skeram Cultist editing records. They request preservation/restoration of the supplied painting's anatomy, rather than a new character based only on a reference. This addresses that specific lineage concern but is not a fresh independent online verification of its artist.

## Validation

Only four static artist mappings and attribution documents changed. No new events, locals or per-frame work. No original or runtime image changes. Lua 5.1 checker passed (exit 0), including Era and Forever scenarios. git diff --check passed. Recursive artwork audit including ignored files found no pending originals. Full Lua checker output is retained in `checks/artwork-artist-followup-2026-10-13.txt`. No release tag or live release.
