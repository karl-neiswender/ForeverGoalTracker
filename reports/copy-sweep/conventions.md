# Language conventions for Forever Goal Tracker

Written 2026-10-13 after a sweep of 3,783 player-facing strings (goal names, notes, steps, tips, piece and material lines, NPC lines, tooltips and chat text) on both clients. `tools/textdump.py` collects them and `tools/copycheck.py` checks them. The enforced rules also run inside `tools/check.py`, so a new string that breaks one fails the suite.

The copy was already close to consistent. Most of what follows writes down what Karl's earlier passes did, so it stays that way.

## Enforced (already followed; the sweep fixed the last six exceptions)

| Rule | Example |
|---|---|
| Steps are one action plus where. A step starts with a capital and ends with a period; every tip ends with a period. Part names (a class, a race) and pieces waiting on a source are exempt. | "Defeat Ragnaros in Molten Core." |
| No em or en dashes and no spaced hyphens in prose. A section name like "Warrior - Dreadnaught's Battlegear" keeps its hyphen, because the code reads it. | |
| One space between words. | |
| Straight quotes and apostrophes only. | |
| Reputation standings are capitalized: Friendly, Honored, Revered, Exalted. | "Alterac Valley's Exalted mount" (was "exalted") |
| Profession and skill names are capitalized. | "Train Riding once per character" (was "riding"), "Leatherworking patterns" (was "leatherworking") |
| Click hints use a hyphen and one capital: Shift-click, Right-click, Ctrl-click. | |
| "Turn in" is the verb, "turn-in" the noun. | "Turn in 'Master Angler'", "the turn-in wins" |
| "level 60" is lowercase in a sentence. | |

## Proposed (waiting for Karl's yes)

1. **Client names.** Say "Classic Era" for the old client, never bare "Classic". Say "Forever" in short copy (tips, chips, tooltips); keep "Warcraft Forever" only for the tagline and welcome text. Today the player sees "Classic", "Classic Era", "Forever", "WoW Forever" and "Warcraft Forever".
   - 5 tips say bare "Classic" (the Fishing tip and the four AQ mounts).
   - Three tooltips and chat lines say "WoW Forever": `Core.lua` lines 1480, 2141 and 11766 ("Not found in WoW Forever yet", "New in WoW Forever.", "Updated in WoW Forever.", "isn't revealed in WoW Forever yet").
2. **Gold.** Write "gold" in full in prose: "1,200 gold", not "1,200g" (3 places: Frostsaber and two Epic Racial Mounts tips).
3. **Hints.** After a hint colon, lowercase the first word unless it is a name: "Shift-click: link in chat" (2 places say "Link in chat"; every other hint is already lowercase).
4. **UI capitalization.** Buttons and headings use sentence case: "Find your next goal", "Edit goal", "Reset this goal". Named things stay capitalized: My Goals, Goal Library, Wowhead, Forever. One heading breaks it: "Step by Step" (suggest "Step by step").

## Notes for later passes

- **Source unknown / Unconfirmed.** Keep the two words as they are: "Source unknown" for gear with no known source, "unconfirmed" for Forever rules that are not verified.
- **"Complete".** It is both a step verb ("Complete 'Mor'zul Bloodbringer'") and a status label. That reads naturally and needs no change.
- **UI strings the scanner cannot see.** Some are built from pieces (`"Not found in " .. name`). They need an occasional read by eye; `tools/textdump.py` only finds whole string literals passed to AddLine, SetText and print.
