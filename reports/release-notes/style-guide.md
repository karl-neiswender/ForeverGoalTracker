# Release notes style guide

Written 2026-10-13 from a look at Blizzard's own notes (Classic Era 1.15.3, Classic 1.15.5 and the WoW Forever beta development notes), then settled with Karl the same day. Decisions are marked **(Karl)**.

## What Blizzard does that we copy

1. **One vocabulary, used the same way every time.** A reader learns it once.
2. **Present tense and "now" for what exists.** "X now does Y."
3. **The old value in brackets** when it helps: "(was 15 seconds)".
4. **Fixes in the past tense:** "Fixed ...".
5. **Short, one-idea entries**, roughly 10 to 25 words.
6. **A neutral, matter-of-fact tone.** The notes state what changed. They do not sell it.

## What we do

### The in-game What's new window: short and sweet **(Karl)**

A flat list for each version, four to six lines. Every line starts with the same words:

| Line starts with | For |
|---|---|
| Added ... | something new that was not there before |
| You can now ... | a new ability |
| Changed ... (was ...) | a different behavior |
| Fixed ... | a named bug |
| Removed ... | something gone |
| Renamed ... (was ...) | a new name |

The closing line, when small tweaks went in, is the one fixed phrase: **UI improvements and bug fixes** **(Karl: "we do so many small tweaks")**. It stays. Only name a fix when it was a bug Karl saw himself; Karl has no data on what players saw, so nothing is listed as something players noticed **(Karl)**.

`tools/copycheck.py` enforces the verbs (and a 24-word limit) on every line of the ledger in `WhatsNew.lua`, so a line that drifts fails the check.

### CurseForge notes

The same lines as the window, in the same order, under the same heading. A **Developers' notes** paragraph may follow when a change needs its reason explained. It is neutral and factual, written the way Blizzard writes theirs, with no personal voice **(Karl)**. Known issues come last, one plain line each.

### Voice **(Karl)**

- Neutral. No humor, unless a line is genuinely, obviously cheeky; the default is none.
- Say "you" only for "You can now ...".
- Lead with what changed for the player, not how it is built.
- Goals, items, settings and menus appear exactly as they do in the game, in the same case.
- No marketing words (powerful, seamless, enhanced). No exclamation marks.
- "UI improvements and bug fixes" is the only generic line allowed.

## Before and after

| Before | After |
|---|---|
| New Goal Library filters, with a Progression sort for armor sets | Added Goal Library filters, with a Progression sort for armor sets |
| A Materials panel on each goal | Added a Materials panel to each goal |
| Search My Goals and show only this character's goals | You can now search My Goals and show only this character's goals |
| Ctrl-click mount items and color variants to preview them | You can now Ctrl-click mount items and color variants to preview them |
| Visual improvements and guide fixes | UI improvements and bug fixes |

The existing ledger (2.9.0 to 2.12.0) was rewritten this way on 2026-10-13. CHANGELOG.md keeps its older entries as written; new entries follow this guide.

## Rule replaced

CLAUDE.md said to keep the CHANGELOG short and roll polish into generic lines. The short part stays, and so does the single closing "UI improvements and bug fixes". What changes is the rest: every other line names the thing and uses the vocabulary above.
