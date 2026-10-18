# Proposed release plan: October 17, 2026

Planning only, based on Karl’s review of 2.15.1. No implementation or live release is authorized by this document. Versions are working labels, with no promised dates. Preserve existing roadmap ideas unless shipped or explicitly withdrawn.

## Proposed sequence

Karl’s priority: **Gear Planner is the next big feature.** The remaining fixes and refinements belong in small patches as they are ready, without becoming a sequence of major releases that delays the planner.

| Release | Focus | Scope |
| --- | --- | --- |
| 2.15.x patches | Fixes and refinements | Character and Forever filters, guide cleanup, My Goals filters, completion safeguards, scope labels, reputation bars, links, material messages and visual refinements, in small reviewable batches |
| 2.16.0, next feature release | Gear Planner | Named gear sets, equipment-slot targets, item sources and adding the set to My Goals; slot search and the character preview developed toward the intended experience |
| Later research | Usage dashboard | Investigate feasibility and voluntary sharing separately from the planner |

The patch list is a backlog, not a prerequisite checklist for Gear Planner. Fix urgent correctness issues first, then develop the planner while releasing small batches of ready improvements. Do not wait for every filter, link or progress-bar refinement to finish. Patch numbering is tentative; split out work that proves larger than expected without automatically giving it priority over the planner.

Existing custom goals, feedback, update welcome and content ideas remain on the roadmap. General-purpose custom goals do not need to ship before Gear Planner. Reuse internal pieces where helpful without expanding the planner into a full custom-goal editor.

## 1. Filtering and discovery

- Audit both Library and My Goals eligibility. Reproduce Buff Other Players appearing for a Rogue; `social_buffs` describes four supported classes but has no entry in `FGT.GOAL_CLASSES`. Check actual tracked spells and Forever differences before choosing restrictions. Review other class, faction, race and profession cases too.
- New & Updated should expose matching individual parts directly: Skyborne in Epic Racial Mounts, and the matching Forever entries in Field Marshal’s and Warlord’s collections. Ordinary siblings should not appear in this filtered result. Preserve the existing parent/part identity, selection and saved progress; do not create duplicate goals. Review counts, search, faction/class filters and Add/Remove behavior together. UPDATED remains eligible as well as NEW.
- Add My Goals category filtering and Hide completed. Category is a filter; sort order remains a separate control. Define whether a finished part or the whole tracked goal determines visibility for collections.
- Recommendation: retain All goals as the initial default and remember an explicitly chosen This character view. Automatically hiding account projects on login could make tracked work appear lost. Review the default again after eligibility and scope labels are reliable. A clear Reset filters action and empty-state explanation should make hidden goals easy to recover.

Review: Rogue and supported buff classes; both factions; Classic Era and Forever; a mixed collection; completed and incomplete goals; narrow windows; filters combined with search and sorting.

## 2. Completion safety and tracking scope

- Separate three concepts in the UI: who can use a goal, which characters supply progress, and which goals the list displays.
- Current code: `RuleMet` checks profession ranks across the filtered recorded roster, and `RuleReadout` shows the best recorded rank. Profession goals are described as across characters. They are not inherently current-character-only. Saved snapshots can be stale; explain the contributing character and when a fresh scan is needed.
- Start with a concise scope label and contributor details on hover. A dropdown that changes progression scope is a separate feature, requiring decisions about independent ticks, manual completion, completion dates and migration. Do not imply that a display filter changes those rules.
- Reduce accidental checks through verified prerequisite gates and a deliberate manual-completion interaction. Prototype an explicit override for steps where automatic evidence is absent or stale. Missing API evidence must not automatically mean the player is ineligible; consumed items, unscanned alts and unverified Forever rules need a recovery path.
- Extend the existing prerequisite work only with verified client-specific evidence. Decide the override interaction in a prototype before applying it to every checkbox.

Review: accidental row click, intentional manual completion, undo, consumed materials, missing snapshots, offline alts, shared steps, completion rewards and previously saved progress. Existing goal IDs, step addresses and ticks must remain intact unless an explicit migration is supplied.

## 3. Guide cleanup and useful links

- Faction war mounts: replace generic step 2 with the verified NPC and city for each faction. Reuse NPC/location links and map pins. Research vendor names, access restrictions and coordinates separately for supported clients before editing data.
- Tier 1/Tier 2 and similar sets: flatten a redundant single collection section and remove repeated information. Recommend “Items to collect” for a collection and “Steps” for an ordered guide, rather than numbering unordered armor pieces. Keep real multi-part selectors and useful expand/collapse behavior.
- Arcanite Reaper: replace the Blacksmithing icon on step 2 with its normal number. Preserve the skill rule and prerequisite.
- Hyjal Summit and the Barrow Deeps: remove the duplicate progress bar under each single objective. Preserve the goal-level bar and automatic completion.
- Dungeon links: add verified recommended level ranges on hover, with hard entry requirements shown separately. Account for wings and Forever changes. Label unknown recommendations rather than importing unverified Classic values.
- Boss links: first deliver name, instance/location, relevant source information and a Wowhead action. Explore a loot window, 3-D model and useful level information separately. “Power range” needs a defined meaning and reliable data before inclusion.

Review: missing item data, unavailable map APIs, both clients, pop-out guide, narrow layouts and link clicks that must not accidentally complete a step.

## 4. Progress feedback and visual hierarchy

- Reputation: bars under the Friendly, Honored, Revered and Exalted milestones. Use one consistent character’s standing and value per readout; never combine characters into an artificial reputation total. Recommend progress within the current standing, with earlier milestones complete and future milestones clearly pending. Confirm handling for unusual reputation scales before rollout.
- Materials: optional chat messages such as “Looted 1 [item]. 12 more needed.” Use actual loot events, existing material needs and updated inventory counts. Define scope explicitly: start with tracked, unfinished goals, combine duplicate needs according to existing Materials semantics, batch rapid messages, and stay quiet after the need is met. Bank moves, trades, crafting and snapshot refreshes must not masquerade as loot. Pair this with the existing optional toast idea without duplicate notifications.
- Completed Library cards: prototype a small completion check/date and a muted treatment. Preserve readable item quality and Forever identity. Completion should not rely on color alone.
- Overall progress header: explore a stronger hierarchy and meaningful label/count before adding visual effects. Establish exactly what its denominator counts and how filters affect it. Review completed, empty and partially filtered lists.
- Goal progress bar: prototype above the icon/name/eyebrow cluster, then use the same hierarchy at the top of the pop-out tracker. Review long names, Materials open, resize limits and minimal pop-out widths. Avoid repeated bars that communicate the same progress.

## 5. Gear Planner: next major feature

Desired experience: a Gear Planner tab with a named target set, clickable equipment slots, slot-specific item search, source information and a rotatable 3-D character. Selecting an item can focus its preview. Use dressing-room-style artwork with side and bottom fades.

Stage 1: prove item/source availability on both clients. Decide how items not cached by the game can be found and how Forever-only items are covered. Do not promise a complete searchable catalogue until this is verified.

Stage 2: a small working planner with named sets, slot targets and verified source text. Add a set to My Goals as item objectives, preserving a stable identity when targets are edited. Define duplicate rings/trinkets, two-handed/off-hand combinations, class restrictions and how already-owned items count.

Stage 3: expand slot-filtered search and the character preview after performance and API review. Check unavailable models, preview equipment versus actual equipment, source uncertainty and cache misses. Reuse the custom-goal foundation where useful, but allow either feature to ship independently.

Follow-up after the core planner: enchants and other verified item enhancements, including armor kits where supported. A populated slot can offer Add enchant (or the specific enhancement type), opening the picker with compatible options. Show a chosen enhancement as a small icon beside its equipment slot, with replace/remove actions. Plan the saved slot records to accommodate enhancements, but keep their implementation outside the first release. The follow-up includes source and material information and a defined application-completion rule; collecting materials alone must not imply an enchant was applied. Verify Forever support, restrictions and tracking APIs before committing to individual systems. Embellishments remain unconfirmed. Replacing a target item should clear its enhancement unless the player explicitly keeps a compatible selection.

## 6. Usage dashboard discovery

Karl wants download/user totals, selected goals and progress trends. Treat these as separate questions. Downloads must not be presented as unique active users. No feasibility claim has been verified in this planning pass.

First investigate supported addon and companion/export options, available aggregate distribution statistics, and what would require a separate service. A local personal dashboard or voluntary export could be a smaller first experiment. Any shared usage feature needs explicit opt-in, a minimal data definition, retention/deletion choices and a clear explanation of what leaves the player’s machine. Do not collect data or build infrastructure during roadmap work.

## Release review

Each implementation release needs its own scope review and Karl’s native in-game checks. Run `python3 tools/check.py`, review performance-sensitive paths, and retain Ketho/LuaLS diagnostics for both supported clients with proof that annotations loaded before any authorized live release. Visual changes need main window and pop-out review. Planning version numbers are not permission to publish or push release tags.
