# Gear Planner: enchants

Unreleased, October 23, 2026 (Claude, PC). Karl's request: an enchant for each piece of gear, as a slightly smaller square in the UI. His decisions: scopes are the Ranged slot's enchant (ammo itself takes none), and the first version plans, tracks and feeds Materials.

## Data (generated; `python3 tools/geardb.py`)

`GearData.lua` gains `enchants` (Classic Era, 189) and `foreverEnchants` (Forever, 226). Line: `spell|enchantId|itemClass|invTypeMask|subclassMask|source|itemId|name|effect|reagents`.

- An enchant is a spell with SpellEffect `Effect = 53` (ENCHANT_ITEM); `EffectMiscValue_0` is the SpellItemEnchantment id that item links carry (`item:id:enchant:...`).
- What it fits: SpellEquippedItems (item class 2 weapons or 4 armor; inventory-type and subclass bit masks). Scopes fit bows, guns and crossbows; 2H enchants only two-handers; necklace enchants exist only on Forever.
- How it is applied: `E` Enchanting (SkillLineAbility 333; reagents from SpellReagents) or `I` an item (arcanums, armor kits, scopes, shoulder signets, spurs, shield spikes; ItemEffect `ParentItemID` on Era, ItemXItemEffect on Forever). An item-applied enchant lists its item as the one reagent, so Materials shows it.
- Filters: QA, test, `Copy of` and `[PH]` names. Season of Discovery spells (400000+) and items (200000+) are dropped from Era. Forever's tables also carry Season of Discovery leftovers under the same ids as Era (Dismantle, Retricutioner, Living Stats), so Forever keeps classic spells plus spells only Forever has (its new bracer, 2H, weapon, necklace and glove enchants, e.g. 1248xxx). Whether any shared Season of Discovery enchant is live in Forever is Unconfirmed.
- Names: Forever writes some effects with `$k1` placeholders; the builder fills them from `EffectPointsMin`.
- Class-specific Zul'Gurub arcanums (e.g. Animist's Caress) are listed for any class that can wear the item; their reputation and class limits are not modeled.
- The builder now sends a browser-style User-Agent: wago.tools returns 403 to Python's default one (the PC had no cache). Regenerating on the PC reproduced the committed file byte for byte before the enchant change.

## Player-facing

- Each slot whose planned item can take an enchant on this client shows a square at 62% of the slot size between the item and its name (27 px at full size). Empty: dim bag-slot texture, tooltip "Choose enchant". Click opens the picker in enchant mode (search only, no item filters; rows show the short name, effect, and Enchanting or Applied from the item). Right-click removes it.
- An enchant never outlives its item: unequipping, or replacing it with an item that cannot take that enchant, drops it on save (`EN.Prune`). Clear items keeps enchants for Undo. Duplicate copies them.
- The model tries the item on as `item:id:enchant`, so weapon glows can show (falls back to the plain item).
- Fill from equipped copies worn enchants from item links and now names items the database lacks ("Not in the planner's list: ...").

## Tracking

- `SyncGoal` adds a step after its item: "Enchant <item> with <enchant> (<effect>)" or "Apply <item-applied enchant> to <item>", with `auto = { enchant, slot, onItem, forCharacter }` and the enchant's reagents. Credit is keyed `slot:e<spell>` in `goalItems`, so it moves with the step like item credit.
- `RecordCharacter` saves `c.enchants[slot] = "itemId:enchantId"` for slots 1 to 19. The rule is met when the owner wears that enchant in that slot on the planned item. Steps never untick.
- `UNIT_INVENTORY_CHANGED` (player) is watched because enchanting a worn item changes the item, not the equipment. It also fires for every arrow shot, so `FGT.WornEnchantsChanged()` compares the worn links to the saved record and only then lets the normal debounced scan run.

## Checks

`tools/check.py`: 109 sessions pass, including the new enchant test on both clients ([output](checks/gear-planner-enchants-2026-10-23-lua51.txt)). Ketho/LuaLS: zero problems, 14,028 annotation loads ([results](checks/gear-planner-enchants-2026-10-23-luals.json), [log](checks/gear-planner-enchants-2026-10-23-luals.txt)); this also fixed three findings from the October 21 work (legacy `ContainerIDToInventoryID`, a recipe cache type, a fill nil annotation).

## Native review (Karl, Classic Era)

1. `/reload`, open a set: squares on Head, Shoulders, Back, Chest, Wrists, Hands, Legs, Feet, weapons and Ranged; none on Neck (Era), rings, trinkets, shirt, tabard, quiver, ammo. Also check a narrow window.
2. Click a square: enchant list, search, pick, tooltip with materials; right-click removes.
3. Crusader or Fiery on a weapon: does the model show the glow?
4. Add to Goals: the enchant step and its materials in Materials. Enchant a worn item: the step completes after a moment.
5. Fill from equipped on an enchanted character.

Forever-only enchants stay unverified until live Forever opens.
