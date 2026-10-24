# Backlog and brainstorm list, October 24, 2026

Karl's brain-dump note from the weekend of October 17-18, reviewed against what has shipped (2.15.1, 2.15.2 and 2.16.0) and written up as one list. Each open item needs a short brainstorm before any code. Karl wants to work through some of them before Warcraft Forever's launch on November 4. This list is the working copy; [ROADMAP.md](../ROADMAP.md) is the public summary.

Wording in the note was interpreted as: "Forever aids" = the Forever raids Hyjal Summit and the Barrow Deeps; "Arkonite Reaper" = Arcanite Reaper; "field martial" = Field Marshal; "hoard" = Horde; "Michael's filtering" = My Goals filtering.

## Already done (check in game, then close)

| # | Idea | Where it shipped |
|---|---|---|
| 1 | "Show goals for this character" listed Buff Others on a Rogue | 2.15.2 fixed character filtering for Buff Other Players. The goal is limited to Mage, Druid, Priest and Paladin in `Library.lua`. Confirm on a Rogue. |
| 2 | New & Updated showed groups (mount collection, Field Marshal and Warlord sets) | 2.15.2: matching sets and mounts are listed individually. |
| 4 | Item set goals: a large yellow collapsible list, a "step-by-step" title with no steps | 2.15.2: pieces are shown directly, with expandable requirements for Tier 3 and Tier 2.5 only. Confirm Tier 1 and 2 read right. |
| 5 | Arcanite Reaper: blacksmithing icon in step two | 2.15.2: the step shows its number. |
| 6 | Hyjal Summit and Barrow Deeps: one step with its own progress bar | 2.15.2: the repeated bar is gone. |
| 9 | Hide completed goals in My Goals | 2.15.2, remembered across reloads. |
| 15 | Completed goals look distracting in the Library | Partly: 2.15.2 made completed cards darker with green markers. Karl to judge whether that is enough (see item 15 below). |
| 16 | A best-in-slot gear tracker with a 3D character, slot search and a dressing-room backdrop | 2.16.0, the Gear Planner. Follow-ups are in the roadmap (more classes, a Source filter, sharing a set). |

## Partly done

**3. War mount step: name the vendor with a link, link the city, add a map pin.** Step 2 of the Alliance and Horde War Mount goals already names "Lieutenant Karter in Stormwind City" and "Raider Bork in Orgrimmar" with a city map link. The vendors are plain text, not NPC links, so there is no hover and no pin.
- Brainstorm: the two NPCs need entries in `Npcs.lua` (id, map, coordinates from Wowhead Classic) so the existing NPC link, tooltip and pin system picks them up. Check whether the Forever spots differ.
- Size: small. Era-verifiable. Good first item.

## Open

**7. Stop accidental check-offs.** A step can be ticked by hand even when the character clearly does not meet it.
- Why it matters most: wrong ticks pollute progress and the completion celebrations. Earned progress is never untoggled automatically, so a mistake stays.
- Options to weigh: (a) lock steps the addon can verify and show why, with a deliberate override (Shift-click, or a "Mark done anyway" prompt); (b) leave steps open but ask for confirmation when the addon knows it is unmet; (c) keep the tick but show a quiet warning mark; (d) an undo toast after any manual tick. My lean: (a) for steps the addon verifies (level, reputation, quest, item, skill), (d) as the safety net, and nothing for steps it cannot verify.
- Open questions: which step types count as verifiable on Era? What does a locked step look like without nagging? Does the override need to be remembered per step?
- Constraint: prerequisite locks exist on Classic Era only; Forever stays unverified until launch.

**8. More My Goals filtering, in line with the Library.** Add a category filter (raid, item set, social, mount, reputation, and so on) and decide whether "this character" should be the default view.
- Pushback welcome, here is mine: a "this character" default can silently hide account-wide goals and confuse anyone with alts, so remember the last choice per account instead of forcing it, and show a visible chip ("Showing: Rogue goals") so the filter is never invisible.
- Brainstorm: match the Library's filter panel layout, or keep the compact row? What belongs in the My Goals row versus a filter drawer?

**10. Show clearly whether a goal tracks this character or the whole account.** Professions look per-character today, while other goals count across the roster.
- Ideas: a small scope label on each goal ("This character", "Account"), a toggle or dropdown on goals that can do both, and the contributing character named in the progress text.
- Rule from the roadmap: filtering a list stays separate from changing how progress counts.

**11. A progress bar under the reputation steps** (Friendly, Honored, Revered, Exalted).
- Shows the character's progress through each standing; name the contributing character. Era data is available from the faction APIs.
- Brainstorm: one bar spanning all four steps with tick marks, or a bar per step? Behavior when the best standing is on an alt.

**12. Boss links in steps.** Raid and dungeon bosses get a link with a hover: a 3D model, a loot list, or a level or power range.
- Options: a tooltip with the boss, location and key drops (data from the Gear Planner's source tables), a model preview (the addon already does try-ons and mount previews), or a Wowhead link. Start with the tooltip.
- Open question: where does the boss data come from for Forever's new bosses, since its Encounter Journal is empty (see CURRENT.md).

**13. Level ranges on dungeon location links.** A recommended level range in the dungeon tooltip, kept separate from the entry requirement.
- Dungeon entrance links and pins shipped in 2.15.1; this adds a data field per dungeon. Data entry from Wowhead, so a content task more than a code task.

**14. A usage dashboard.** What goals people pick and how far they get.
- Honest feasibility: an addon cannot send data over the internet, and the roadmap rules out collecting anything until consent and privacy are settled. Options: (a) an opt-in "copy my anonymous summary" string that a player pastes into a form, low volume but fully consented; (b) CurseForge's own download counts only; (c) a companion desktop app that reads SavedVariables and uploads, which needs a backend and is a much bigger project.
- Suggestion: park it as research, and do (a) later if it is wanted at all.

**15. A subtler look for completed goals in the Library.**
- 2.15.2 already darkened completed cards and made the markers green. Karl to look at the current Library (a screenshot with several completed goals) and say what still distracts: the green chip, the dimming, or the card color. A quick mockup of two or three treatments would settle it.

**17. Redesign the main progress bar at the top of the window.** Karl: it is the most important bar and lacks reverence.
- Directions to sketch: a taller bar with the percentage and goal counts built in, milestone ticks, a quiet shimmer or glow tied to the existing image-effects setting (so it stays off in Off and still in Subtle), and what it says when empty or complete.
- Needs mockups first, so this is a design session before any code.

**18. Move each goal's progress bar above the title and icon cluster, and above the pop-out step tracker too.**
- Brainstorm: does it read as the goal's headline? How tall is it on small windows? How does it sit with the new overall bar (item 17)? Do items 17 and 18 as one design pass so the two bars look related.

**19. A chat message when you loot a needed material** ("Looted Arcanite Bar, 7 to go").
- The addon already has a "Needed for" system and step updates in chat. Make it optional, throttled (one line per item per few seconds, not per stack), and off or quiet by default so it never floods the chat.
- Small and Era-verifiable.

**20. Show where your character is on the map view** (added by Karl, October 24).
- The idea: a silver circle for the character on the goal map, next to the gold pin that pulses for the NPC or dungeon entrance, so you can see the distance at a glance.
- What exists: the map layer draws a zone map under the banner with a gold pin; `/goals here` already reads your position with `C_Map.GetBestMapForUnit` and `C_Map.GetPlayerMapPosition`. The silver tint in `Maplet.lua` is only the map button's style so far, so this is new.
- Brainstorm: show it only when you are in the same zone as the pin (otherwise nothing, or a small edge arrow toward it); the zoomed view may not contain you, so an edge indicator may be needed; how often to update (a few times a second, only while the map is visible); the look (a steady silver ring, no ping, so it never competes with the gold pin); a facing arrow from `GetPlayerFacing`; instances and other places where the game gives no position; whether Forever's map API behaves the same (unverified until launch).
- Not scheduled: later, after the Era-verifiable list below.

## Suggested order before November 4 (eleven days)

Everything below can be built and checked in Classic Era, with no dependency on Forever data. Freeze new features around October 31 so the week of the launch is for testing Forever and shipping 2.16.1.

1. **Item 3, war mount NPC links and pins.** Small, data-only, a quick win.
2. **Item 7, accidental check-offs.** The most valuable usability fix; needs a real brainstorm first.
3. **Item 8 with item 10, My Goals filters and the scope label.** Design them together, since the filter chip and the scope label share the same space.
4. **Item 11, reputation progress bars.**
5. **Items 17 and 18, the two progress bars.** One design session with mockups.
6. **Item 19, material loot messages**, if time allows.

Later or research: item 12 (boss links), item 13 (level ranges, content work), item 14 (dashboard research). Item 15 waits for Karl's look at the current Library.

Brainstorm one item at a time, in this order. Each session ends with a short written decision (what, how it looks, what it does not do) before implementation.
