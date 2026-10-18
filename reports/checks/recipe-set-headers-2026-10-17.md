# Tier 3 and Tier 2.5 outer headers, October 17, 2026

Karl approved extending the Tier 1/Tier 2 presentation to recipe sets.

- All standalone single-section armor sets omit the redundant outer set header. Tier 3 and Tier 2.5 now show their pieces directly under Items to collect.
- Each piece retains its expand/collapse control, completion count, green check and material/turn-in checklist. Material rows sit one level below their piece.
- Old outer-section collapsed state cannot hide the main-page item list. Multi-part collection selectors and pop-out window collapse behavior stay available.
- Rendering only: goal IDs, original section/piece/material keys, requirements, item rules and saved progress are unchanged. No migration, new events or timers.
- Focused Era and Forever scenarios verify both Tier 3 and Tier 2.5 item expansion and material checkbox keys, including an old closed outer section. The existing completed-step filter scenario verifies that finished recipe lists can still be hidden and restored.
- Full Lua 5.1 suite: `recipe-set-headers-2026-10-17-lua51.txt`. Native review: `/reload`, open a Tier 3 and Tier 2.5 goal, expand/collapse an item and check the main/pop-out layout. Unreleased; no release tag or publication.
