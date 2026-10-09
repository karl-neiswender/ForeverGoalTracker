# Character-aware banner artwork

Core.lua's goalBanner.artVariants registers optional variants per goal. Entries use an approved runtime `path`, and optional `faction`, `class`, `race`, `aspect`, and `preprocessed` values. Class and race use the second return values from UnitClass/UnitRace (e.g. MAGE, NightElf, Scourge). All conditions on an entry must match the logged-in character; the roster and Library filters do not participate.

Priority is race + class, faction + class, class, race, faction, then shared goal art. Matching weights are class 100, race 20, faction 10; first entry wins ties. Add new approved Troll Mage art with faction Horde, class MAGE, race Troll to allclasses. Also add a faction/class entry for the same image if it should serve other Horde mages. Do not label an Alliance character as Horde just to fill a gap.

ResolveArt returns filename, aspect, and preprocessed flag together, so reused art keeps its own proportions and color treatment. Variant defaults are 4:3 and preprocessed=true. ArtPath remains a filename-only wrapper for existing callers. The established factionArtPaths table still handles Warrior Tier 2; individual class-set goals otherwise retain their specific artwork.

Current allclasses artwork covers approved Alliance Hunter/Mage/Warrior/Druid/Paladin, Alliance Human and Dwarf Priest, and Horde Hunter/Warrior/Shaman/Warlock. Other Priest races, Horde Mage, Horde Druid, Alliance Shaman and faction-specific Rogue leveling variants use shared art until approved variants are registered.

Epic racial mounts include approved Human, Dwarf, Night Elf, Gnome, Orc, Troll and Tauren images and prefer the current race, then a sole selected same-faction mount if race art is missing, then a same-faction mount. `part` values identify the existing section position without changing saved progress. PvP goals share the approved Alliance night elf Warrior Tier 2 and Horde orc Warrior Tier 2 images by faction, with the original shared PvP banner for unknown faction.

Only approved runtime BLPs may be registered. New banner artwork must follow .agents/skills/forever-goal-tracker-banners/SKILL.md, with baked left and bottom gradients. Update tools/artwork.py and the runtime manifest when adding a new texture. Tests in banner-tests.lua cover both clients, specificity, missing art/APIs, and layout metadata.

Priest Tier 3 uses the approved kneeling night elf for Alliance and as the shared default, including Horde until a Horde image is approved. Add that future image as the Horde entry in factionArtPaths.tier3_priest; retain the shared default.

Priest Tier 2 uses the approved mirrored close-up of the dwarf from wow-zul-gurub.jpg for Alliance and as the shared default until Horde artwork is approved. The same texture is reused by allclasses when the logged-in character is an Alliance Dwarf Priest. No additional texture is needed for leveling.

Priest Tier 1 uses the approved Anduin Prophecy portrait with the corrected Benediction tip. The same texture is reused by allclasses for a logged-in Alliance Human Priest; Dwarf Priests retain their Tier 2 portrait.

Warlock Tier 1 selects the approved human Felheart illustration from Curse from Beyond for Alliance and retains the original orc banner for Horde and unknown faction. The full original TCG card remains in Media/artwork.
