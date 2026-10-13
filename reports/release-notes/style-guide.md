# Release notes style guide (proposal)

Written 2026-10-13 from a look at Blizzard's own notes: the Classic Era 1.15.3 notes, the Classic 1.15.5 notes, and the WoW Forever beta development notes thread (October 8). The goal is notes that read like a person who cares wrote them, in the same steady voice every time, for the **What's new** window in game and for CurseForge.

## What Blizzard does that we are not doing yet

1. **A fixed skeleton.** Title, version, date, then the same headings in the same order every time. The beta notes use Bug Fixes, Changes and Updates, then content sections (Classes, Items, Quests, User Interface), then Known Issues. A player who has read one set of notes can find things in the next.
2. **A small vocabulary, used the same way every time.**
   - New things: a plain statement of what it does and where it is.
   - Changes: present tense with "now": "X now does Y."
   - What it used to be: in brackets, in the same entry: "(was 15 seconds)".
   - Bug fixes: past tense, the symptom first: "Fixed", "Resolved", "Corrected".
   - Removals and renames: stated flatly, no apology.
   - Things coming: future tense: "will open".
3. **Specific over generic.** Every entry names the thing and the effect. They never write "bug fixes" or "improvements" as a line; they list what was fixed.
4. **The reason, set apart.** A short italic "Developers' notes" under a change says why: what the team was trying to do, a tradeoff, a reversal. It is optional and used for the changes that need it, not for every line.
5. **An honest Known issues list** at the end, with the same plain wording.
6. **A human tone.** Candid, a little dry, now and then a touch of humor. Short sentences; one idea per entry; roughly 10 to 25 words.

## What we do

The in-game window is small, so we keep Blizzard's skeleton and vocabulary but cut the length.

**Shape of one release** (4 parts, each optional; skip a part rather than pad it):

1. **A headline:** one sentence, in the voice of a person, that says what the release is about.
2. **New:** what you can now do. At most 6 lines.
3. **Changes:** what behaves differently. Say what it was in brackets when that helps. At most 6 lines.
4. **Fixes:** what was broken, named by what the player saw. No limit, but one line each.
5. **Developer's note** (optional, one short paragraph, in Karl's voice): why we built the headline feature, or a tradeoff.
6. **Known issues** (optional): anything we know is still off, in plain words.

**Voice**
- Say "you" when it helps: "You can now Ctrl-click an armor set's icon to try on the whole set."
- Lead with the player's gain, not the code.
- Present tense and "now" for what exists; past tense for fixes; "will" for what's coming.
- Real names for things: goals, items, settings and menus appear exactly as in the game, in the case the game uses.
- No marketing words (powerful, seamless, enhanced), no "improved" without saying what improved, no exclamation marks except in the Developer's note.
- A little warmth is welcome. A dry joke is fine now and then. Never at the player's expense.

**Vocabulary** (the same verb for the same thing, every release)

| Use | For |
|---|---|
| Added | something new that was not there before |
| You can now | a new ability |
| Changed | a different behavior; add "(was ...)" |
| Fixed | a bug, named by the symptom |
| Removed | something gone |
| Renamed | a new name; give the old one in brackets |

**CurseForge vs in game.** The same entries, the in-game window shows the headline and the first lines of each part; CurseForge shows all of it plus the Developer's note.

## Rules we are replacing

- **"UI improvements" and "Bug fixes" as lines.** They told players nothing. Name the fix. The old rule ("one generic line for polish") was about keeping the notes short; the fix is to keep the notes short by choosing the few things players will notice, not by hiding them.
- **Noun-phrase entries** ("A Materials panel on each goal"). They read like a feature list. Use a sentence.

## Before and after, from real releases

| Before (2.12.0) | After |
|---|---|
| New Goal Library filters, with a Progression sort for armor sets | Added filters to the Goal Library, so you can narrow it to your class, faction or type. Armor sets now have a Progression sort, from Dungeon sets to Tier 3. |
| A Materials panel on each goal | Added a Materials panel to every goal. It lists each ingredient and how many you hold across your characters. |
| Search My Goals and show only this character's goals | You can now search My Goals, and show only the goals that fit the character you are playing. |
| UI improvements and bug fixes | (name the three or four that players would notice) |

## Open questions for Karl

1. **Developer's note:** do you want it, in your voice? It is the part of Blizzard's notes that people quote, and it fits a one-person addon well.
2. **Humor:** how much? I would keep it to the headline and the Developer's note.
3. **Dates:** keep "Oct 12, 2026", or write "October 12, 2026"? Blizzard writes the full date.
4. **Fixes list:** are you comfortable naming real bugs by their symptom, even small ones? Players tend to trust notes that admit them.
