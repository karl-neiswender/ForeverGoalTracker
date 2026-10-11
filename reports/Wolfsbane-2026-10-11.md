# Wolfsbane goal, October 11, 2026

Added `wolfsbane`, a Horde-only, NEW Forever library goal for Undead Paladins. Matches the existing account-wide catalog behavior: other classes can browse class goals. Classic Era cannot browse this goal. No release/version bump.

16 steps cover all 13 quests, accepting the material quest and collecting the two dungeon materials separately. Quest 95042 covers purification of the Kor Gem. Item 267369 or completion of quest 95140 completes the whole goal. Dungeon material rules are scoped to Horde Undead so Alliance Verigan's Fist lumber does not count. Consumed materials stay checked; completing 95036 also supplies evidence for both material steps.

Sources read from Wowhead Forever on October 11:
- https://www.wowhead.com/forever/item=267369/wolfsbane
- Quest pages 91858, 91859, 91860, 91861, 91862, 96204, 95034, 95036, 95042, 95111, 95125, 95126, 95140, linked from the item page.
- Item links on those pages identify 6994, 267361, 267412, 267454, 6995, 272448 and 268484. Purified Kor Gem's linked ID was retrieved, but its own page timed out.

Quest IDs, objectives and final reward were checked against quest-page text. Level 18, Danitha's starting location, specific material locations and landing a Moonsilver Blade hit to remove the shield are supported by player comments, pending Karl's in-game verification. Quest-start tooltip text includes places directly; no unverified map coordinates added. Uses existing sword icon fallback and no new banner.

Full `python3 tools/check.py` passed on Classic Era and Forever, including new tests for visibility, quest pickup versus turn-in, consumed materials, final quest/item completion and registered quest links. Log: `reports/checks/wolfsbane-2026-10-11.log`. This adds data, with no new event handlers or recurring UI work. Ketho/LuaLS release diagnostics were not run for this source-only change; the live-release gate remains required before publishing.

In-game check: `/reload`, search Wolfsbane in the Goal Library, review NEW/Horde presentation, quest links and material progress on an Undead Paladin. No new texture means no full restart required.
