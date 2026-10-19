# Gear Planner drafts, header and empty slots

Unreleased UI pass approved by Karl on October 18, 2026.

- Every named saved set now appears in My Gear Sets. Rows distinguish Draft from In My Goals. Adding to Goals remains explicit; removing a goal leaves the saved draft available for re-adding.
- Saved names appear as headings with a grey pencil that turns gold on hover. New sets and Rename use the existing input. Leaving the input returns to the heading. Blank renames restore the saved name, including drafts.
- Empty slots rest at 65% icon opacity instead of 50%. Hover shows the slot name beside the icon and Choose item in its tooltip. Empty drafts show a concise starting instruction.

Verification: full `python3 tools/check.py` suite passed, including both simulated clients, draft visibility without activation, explicit activation, rename identity, clear/undo, remove/re-add and collection credit. Output: checks/gear-planner-drafts-header-lua.txt. Fresh Ketho/LuaLS evidence is retained beside it. No new scan or idle update driver was added; row refresh still reuses pooled controls and runs on user changes.

Native review remains: create/name a draft, leave the input, reopen it with the pencil, switch saved sets, add/remove/re-add a goal, and inspect empty-slot labels at narrow and wide window sizes. No native rendering or CPU test is claimed. Artwork audit found no pending originals, including ignored files. No release tag or publication.
