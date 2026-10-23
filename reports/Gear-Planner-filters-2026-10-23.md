# Gear Planner: target level, wearable armor and picker filters

Unreleased, October 23, 2026 (Claude, PC). Follows the [enchants work](Gear-Planner-enchants-2026-10-23.md) the same day.

## Karl's direction

- Players plan best-in-slot at 20, 30, 40 and so on, not only at 60. Do not show maximum-level epics by default.
- Never soft-lock an armor type: a level 41 Hunter may still want leather (or cloth) for its stats. Forever has no community BiS lists yet, so the planner's own filters are the BiS tool there.
- A level 60 player may still chase a low-level item (feral Druids and a low-level helm), so low-level items must stay reachable.
- The filter row (Usable, All, Item level, Revealed) was unclear and clunky. Goal: smooth simplicity, clear labels, intuitive design.

## What changed

**Target level per set** (`build.level`, 1 to 60). New sets start at the character's level; presets and older sets are 60. It sits under the set name ("Level [60]"): type it, or scroll over it. It is a ceiling only: items needing a higher level are left out, lower-level items always stay. The planned items are never removed when the level changes.

**Wearable armor.** `Cat.Usable` now allows every armor type up to the heaviest the class wears at the target level (Hunters and Shamans mail at 40, Warriors and Paladins plate at 40; Warriors and Paladins wear mail from the start). This replaces the October 21 look-ahead that showed both types before 40: a level 20 player planning Cryptstalker makes a level 60 set.

**Picker filters.** Three labeled dropdowns that say what they show, sharing the row evenly:
- **Stat:** Any stat, Agility, Strength, Stamina, Intellect, Spirit, Attack power, Spell power, Healing, Hit, Crit, Defense. Keeps items with that stat, ranks by it, and rows show the value ("+23 Agility · iLvl 66 · ...").
- **Type:** the armor types (Any armor, Cloth, Leather, Mail, Plate) or weapon types (Sword, Bow, Shield, Held in off-hand, ...) the slot actually offers at that level; hidden when there is nothing to choose (rings, necks, cloaks). Remembered per slot.
- **Quality:** Any quality, Uncommon+, Rare+, Epic+.

Usable and Sort are gone: the list is always what the character can wear at the target level, best first. Revealed only (Forever) moved to the footer.

**Best first, then Show all.** An unsearched slot lists its best 25; the footer offers "Show all N". Search always covers the whole slot. Ranking: items already planned in this character's sets first, then the chosen stat, then item level.

## Data (`python3 tools/geardb.py`)

- **Leveling greens:** green items at every level are now included (only starter greens under level 5 and item level 10 are left out). 6,740 to 9,679 items; `GearData.lua` 410 KB to 725 KB. Slots are still parsed only when opened.
- **Stats:** a new last field per item, short codes (`a23,t23,i15,p8,c1`): a Agility, s Strength, t Stamina, i Intellect, p Spirit from ItemSparse `StatModifier_bonusStat/Amount`; from the item's Equip: spells (ItemEffect trigger 1, SpellEffect aura, base points + 1): A attack power (aura 99, or 124 for ranged-only), S spell power (13 on all schools), H healing (135), h hit (54, 55), c crit (52, 57), d defense (aura 30 skill 95, plus 25 per 1% dodge, parry or block). Checked: Giantstalker's Helmet +23 Agi, +23 Sta, +15 Int, +8 Spi, 1% crit; Devilsaur Leggings 46 AP, +12 Sta, 1% crit; Thunderfury +5 Agi, +8 Sta.
- Effects that are not plain stats (Thunderfury's proc, a feral helm's shapeshift energy) are not ranked; your own sets and future presets cover those.

## Checks

`tools/check.py`: 109 sessions pass on both clients, with rewritten planner tests for the dropdowns, Show all, target level, armor by level, low-level items kept and stats ([output](checks/gear-planner-filters-2026-10-23-lua51.txt)). Ketho/LuaLS: zero problems, annotations loaded ([results](checks/gear-planner-filters-2026-10-23-luals.json)). GearPlanner's main chunk dropped from 163 to 159 top-level locals.

## Native review (Karl, Classic Era)

1. The filter row: labels readable at full and narrow widths; the dropdown popup opens under its button, closes on a pick or a click elsewhere.
2. Head on a level 60 set: best 25, Show all, a Stat pick reorders and shows values, Type lists Cloth to Plate.
3. Change the level to 20: plate and level-21+ items disappear; scroll over the box.
4. Rings: no Type dropdown. Off hand: Shield and Held in off-hand where the class can use them.
5. Forever only (at launch): Revealed only in the footer.

## Gear set goals in My Goals (same day)

Karl asked for the leveling goal's character artwork on gear set goals (a Dwarf Hunter's set shows the Alliance Dwarf Hunter art) and for gear sets to stand apart in the list.

- **Art:** `B:ResolveArt` gives a goal with `plannerOwner` the leveling (`allclasses`) variant chosen by the owner's faction, class and race from the roster, not the logged-in character, so an alt's set keeps the alt's art. Classes without their own art (e.g. Alliance Rogue) get the shared leveling art. Glows, snow and blooms follow the image path as before.
- **Label:** `FGT.GoalEyebrow` says `GEAR SET · NAME` (the owner's name in class color) instead of `ITEM SET`, which Library sets such as Tier 1 also use.
- **Grouping:** My Goals orders Favorites, then gear sets, then the rest, with the existing gold divider at each boundary (`FGT.favDividers`). A favorited gear set stays with the favorites.
- Not added: a new painted badge icon. The label already says what the group is; a badge can follow if Karl paints one, like the favorite star.
- Checks: `tools/check.py` 109 sessions with a new art and label test; Ketho/LuaLS zero problems. Native review in Era pending: divider spacing with two boundaries, label length on narrow cards.

## Library goals for planned items, and Track on its own (same day)

Karl: when a planned item or set is already a Library goal (Atiesh, Thunderfury, the legendaries, sets), link to that goal or add it; and let items or sets become goals of their own. Keep it clean, simple, with clear actions.

- **Lookup** (`Cat.GoalFor(itemId, faction)`): built once from the goals themselves: `completeWith.item` and `rewardItem` ("reward": Thunderfury, Atiesh, Arcanite Reaper, Quel'Serrar, Benediction...) and Library set pieces (`sections[].pieces[].auto.item`, "set"). A reward goal beats a set; a class's own set beats its collection; faction-only goals match the planned character. Only goals this client can offer (`FGT.LibraryAvailable`, new: `LF.Available` with class sets allowed). New Library goals link with no extra data.
- **One action everywhere:** every goal link opens the same goal card the guides' gold links open, which says "Open goal" or "+ Add to My Goals" (`FGT.OpenLinkCard`). Core now exposes `FGT.SetGoalActive` and `FGT.IsGoalActive` so the planner adds goals exactly as the Library does.
- **Picker:** a gold link mark on rows whose item has a Library goal, left of the map pin; tooltip names the goal and whether it is in My Goals.
- **Slot:** the planned item's tooltip says "Library goal: ..."; its menu (Replace, Unequip) gains a third action: "Add goal: Thunderfury" / "Open goal: Thunderfury", or for other items "Track on its own" / "Open its goal".
- **Header:** two or more pieces of one Library set show a gold "Library goal: Giantstalker Armor" link at the right of the level row.
- **The gear set goal:** a reward item's step becomes "Complete the {thunderfury:Thunderfury} goal" (a gold goal link) and drops its own recipe materials, so Materials never counts them twice; it still completes when the item is owned. Library set pieces keep their own steps, and one tip names their set goal(s).
- **Track on its own:** makes a one-item gear set (`build.single = itemId`, the slot's enchant, this set's level), tracked at once: its own card with the owner's art and GEAR SET label. It also appears in My Gear Sets, where it can be edited like any set. Offered in the slot menu only, so the list rows stay simple.
- Fixed during testing: `LG.For` lost the goal's kind through `x and f()` (Lua keeps one value); the header never found sets until fixed.
- Checks: `tools/check.py` 109 sessions with a new Library-links test ([output](checks/gear-planner-library-links-2026-10-23-lua51.txt)); Ketho/LuaLS zero problems ([results](checks/gear-planner-library-links-2026-10-23-luals.json)).
- Native review (Era): the goal mark beside the map pin on narrow pickers; the third menu button's label length; the goal card opening from inside the planner; Track on its own appearing in My Goals with the character's art.

## Gear sets across characters (same day)

Karl: on a Mage, do I see my Hunter's goals, and does looting on the Mage tick them? Plus: Bind on Pickup and worn Bind on Equip items can't be mailed.

How it works (unchanged rules): My Goals is account-wide. A gear set's steps count only its owner's items (`forCharacter`); Library goals (Thunderfury, recipes) sum every character's items, so a binding looted on the Mage ticks the Thunderfury goal, while the Hunter's gear set step "Complete the Thunderfury goal" ticks when the Hunter owns the sword. Each character's bags and worn gear save when it is logged in; the bank only while open; the mailbox never.

Added:
- **This character view:** `FGT.GoalFits` keeps a gear set only for its owner (`FGT.PlayerProfile` now carries the character key). Previously gear sets passed every class and faction check.
- **Bind types:** `GearData.lua` gains a last field, the game's Bonding (0 none, 1 pickup, 2 equip, 3 use, 4 quest; Forever-only raid pieces 1). `RecordCharacter` saves `c.worn[slot] = itemId`.
- **Hints** (`FGT.PlannerElsewhere`, shown in muted text under an unticked gear set step): "On Frostbolt: mail it to Swagrid" for a mailable copy (no bind, Bind on Use, or a Bind on Equip copy not worn; the game's item count includes worn items), otherwise "Frostbolt has one, but it's soulbound. Swagrid needs their own". Never credit: the step still waits for the owner.
- **Freshness** (`FGT.PlannerFreshness`, card tooltip): "Swagrid's gear, saved 2 days ago. It updates when Swagrid logs in." Only for another character's set.
- Not covered: whether a specific copy in bags became soulbound some other way (e.g. a Bind on Use item already used); the hint follows the item's bind type and whether it is worn. Other characters' counts need that character to log in once after this update.
- Checks: `tools/check.py` 109 sessions with a new cross-character test ([output](checks/gear-planner-characters-2026-10-23-lua51.txt)); Ketho/LuaLS zero problems ([results](checks/gear-planner-characters-2026-10-23-luals.json)).

## Planner backdrop layering (same day)

Karl: tidy the darkening overlays; keep focus on the character; match the goal pages; keep the race dressing-room backdrop (no leveling art behind the model, no glow); make the scenery fully black and white. Goal art bakes its darkening into the image (wide left gradient, soft fade over the bottom ~11% to near-black charcoal) and the addon adds runtime fades; the dressing-room scenery has none, so layers must build the same look.

- **Scenery:** `SetDesaturation(1)` where available plus `SetDesaturated(true)` and a neutral vertex colour; still 18% opacity like goal art.
- **Under the character (baked-gradient stand-ins):** dark sides on both edges (28% of the width, goal page's left-shade colour `0.012, 0.011, 0.008`, 1 to 0), the goal page's top fade (`0.02, 0.017, 0.012`, 0.65 to 0 over 28%), and a bottom fade to near-black charcoal (panel bottom colour, 0 to 0.92) over 12% of the height (60 to 110 px), replacing the 140 px fade to solid.
- **Over the character:** the 42%-of-width side veils that grew from 0.55 to 0.85 with zoom are gone. Narrow label lanes replace them: fixed width from the slot layout (icon, enchant square, name, 16 px), 0.6 at the panel edge to 0; a top band behind the name and level row (92 px, 0.7 to 0); a bottom band behind the weapon row (0 to 0.55). Nothing changes with zoom.
- Checks: `tools/check.py` 109 sessions; Ketho/LuaLS zero problems. Not verified in game: readability of long slot names over bright armor at narrow widths, and whether the floor fade reads as ground. Tune strengths from Karl's Era screenshots.

### Tuning after Karl's first Era screenshot (Dwarf Rogue, default size, no zoom)

Confirmed in game: scenery fully black and white, character undimmed, floor reads as ground. Then:
- Side fades under the character widened from 28% to 34% of the width, to calm the busy scenery beside the silhouette.
- "Drag to rotate · Scroll to zoom" uses the muted subtext colour, like the goal pages' hints.
- **Light** (`background.light`, `background.pool`, `Media/glow`, additive, neutral white, static): behind the body (alpha 0.09, 62% x 85% of the height, a little above centre, growing with zoom) and a floor pool at the feet (alpha 0.07, fading out as you zoom). Drawn above the scenery and under the shading. On by default; `/goals plannerlight` switches it and remembers the choice (`gearPlanner.prefs.light`).
- Checks: `tools/check.py` 109 sessions including the toggle; Ketho/LuaLS zero problems. Next: compare light on and off, a filled set, a narrow window and a zoomed slot.
- Second Era screenshot pair: Karl likes the light on by default. Resting camera moved two wheel steps in (`REST_ZOOM` 0.2: start, set changes and the unfocused profile); the wheel still reaches 0. The light's zoom growth and floor-pool fade are measured from the resting view. Clicking away from a focused slot keeps its zoom, as before. New test: the camera rests at 0.2 after a set change.
- **Smooth zoom:** the wheel no longer starts a 0.2 s ease-in-out tween per click (each restart began from a standstill, so fast scrolling stepped). It sets the target and `camera.Glide` closes part of the remaining distance each frame (exponential ease-out, 12 per second, settles in about 0.3 s), so quick clicks or trackpad streams become one continuous move; a slot focus in progress hands its offsets over without a jump. Slot focus and turning keep their timed smootherstep. Animations off: instant. The portrait-zoom to camera-distance hand-over at 0.8 (a sudden speed change) is blended across 0.76 to 0.84; values are identical outside that range, so the tuned slot views (head 0.75, back 0.74 and lower) are unchanged. Tests: glide monotonic, second click continues the move, settles exactly; the older wheel-limit test now settles frame by frame.
- **Bug, dual wield (Karl, Era, Dwarf Rogue):** only one weapon showed: the off-hand (Ravenholdt Slicer) replaced the main hand (Bland Dagger) on the model. `PaintGear` called `TryOn(link)` without a hand, and the game put a second one-hander in the main hand. It now passes `MAINHANDSLOT` or `SECONDARYHANDSLOT` (`DressUpModel:TryOn(link, handSlotName, spellEnchantID)`), and the enchant goes in its own argument instead of the link. Test added. Not verified in game yet.
- **"Any level" (Karl, Era):** about 2,000 items have no level requirement in the client tables (raid drops such as Onyxia Tooth Pendant, Zul'Gurub necks, dungeon sets, quest rewards such as Backwood Helm), 717 of them item level 50+. That matches Classic tooltips, but as a pure ceiling it let level-60 rewards top a level 10 list. `Cat.PlanLevel(item)` uses the requirement, or for none the content level (item level minus 5, capped at 60), for the target-level filter. Rows say "No level requirement" instead of "Any level". A real requirement above the set's level shows red: "Req 60" on rows, "Lv 60" before a planned slot's name, and a tooltip line. No-requirement items are never red (they can be worn). Test added. To confirm in game: hover one of these items; the tooltip should have no "Requires Level" line.
- **Level range (Karl's sentence):** the header reads "Showing gear for level [min] – [max]". Max is `build.level` (the set's planning level; `false` = any, missing = 60 for older sets; new sets start at the character's level); min is `build.minLevel` (a floor, empty = any by default). Both boxes are typed (Enter or clicking away keeps it, empty = any, Escape cancels) or scrolled; scrolling past the ends reaches any (min below 1, max above 60). A range that would turn around moves the other end. The floor uses `Cat.PlanLevel` like the ceiling (`opts.minLevel` in `Cat.Search`). With any max, armor types and red flags use 60. Empty boxes show a muted "Any". The empty-slot message names the range ("Nothing for this slot up to level 20."). Dropped by Karl: a "from my level" shortcut. Tests added; Ketho/LuaLS zero problems.
- Karl, Era: an empty min read "Any" (confusing), and he reached min 30 with max 10 (the "other end follows" rule went stale when clicking from one box into the other, since the focused box kept its old number). Now the empty boxes say "Min" and "Max", and the box being changed stops at the other one (min never passes max; max never drops below min), so only the edited box changes. Tests updated.
- Slot menu third button (Karl, Era): label now centred; "Track on its own" is "Track this item", then "View in Goals" (the header's wording). A Library goal gets the guides' gold: gold text and border plus the picker's goal mark, reading "+ Add Darkmantle goal", then "Open Darkmantle goal". Tests updated.

## First-visit welcome (same day)

Karl's screenshot of a first visit: the same message three times ("No gear sets yet", "Create a set to begin." twice), an empty black panel, a small grey button in a corner, no explanation, and the quick starts hidden. Now:
- The scene always shows: the character in the black-and-white backdrop with the light and fades, wearing their current gear (`model:SetUnit("player")`; another character shows their race, undressed). Slots stay hidden until a set exists.
- A welcome card (`ES`) on the left side of the scene (free of slots, on the dark side fade, never over the character), styled like the goal preview card (dark panel, gold edge): "Plan your gear", one line ("Choose the items you want for each slot, see them on your character, and track them as a goal."), a gold primary **Create a gear set**, **Start from my current gear** (own character only: makes a set named "Current gear", saved and filled from what is worn), and **Use Hunter Pre-Raid BiS** when that preset fits.
- Said once: the top status line is empty without a set; the left list says only "No sets yet." (muted). The old header text and buttons are hidden.
- Tests added (card shown on a first visit, own character in the scene, current-gear start, preset only when it fits); Ketho/LuaLS zero problems. Native review pending: card position and size at default and narrow widths, and the scene for another character.
- Karl's first-open screenshot: the card nearly touched the character while the right half was empty, and "goal." sat alone on the last line. On the welcome screen the model now draws in the space right of the card (`ES.Frame`: model anchored 36 + 300 px from the left; the full panel returns when a set opens), so the character centres beside the card in exact pixels at any width; the light and floor pool anchor to the model, so they follow. Copy shortened to "Choose items for each slot, see them on your character, and track them as a goal." Test extended.
- Karl: the "character beside the card" pass missed the mark; the first welcome was closer, and the magic he wanted is the slots fading in when the button is clicked. Reverted `ES.Frame` and the copy change (character centred in the full scene again). Opening the first set from the welcome now runs `ES.FadeIn`: the card fades out (0.18 s) while the slot squares and their enchant squares fade in one after another in layout order (20 ms apart, 0.3 s each, smootherstep), with the set header; about 0.8 s, instant with animations off. Refreshes during the fade leave it running (they had hidden the card at once). Test: slots start hidden, alpha only rises, everything ends at 1 and the fade stops.
