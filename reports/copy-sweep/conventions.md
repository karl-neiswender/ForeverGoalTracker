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

## Also enforced since Karl's yes (2026-10-13)

1. **Client names.** "Classic Era" for the old client, never bare "Classic". "Forever" in short copy (tips, chips, tooltips); "Warcraft Forever" only in the tagline and welcome text. The strings "Not found in Forever yet", "New in Forever.", "Updated in Forever." and "that item isn't revealed in Forever yet" were changed, plus the Fishing and AQ mount tips.
2. **Gold.** Write "gold" in full in prose: "1,200 gold", "about 900 gold" (Frostsaber and two Epic Racial Mounts tips changed).
3. **Hints.** After a hint colon, lowercase the first word unless it is a name: "Shift-click: link in chat" (2 places changed).
4. **UI capitalization.** Buttons and headings use sentence case. Named things stay capitalized: My Goals, Goal Library, Wowhead, Forever. "Step by Step" became "Step by step".

## Notes for later passes

- **Source unknown / Unconfirmed.** Keep the two words as they are: "Source unknown" for gear with no known source, "unconfirmed" for Forever rules that are not verified.
- **"Complete".** It is both a step verb ("Complete 'Mor'zul Bloodbringer'") and a status label. That reads naturally and needs no change.
- **UI strings the scanner cannot see.** Some are built from pieces (`"Not found in " .. name`). They need an occasional read by eye; `tools/textdump.py` only finds whole string literals passed to AddLine, SetText and print.
