# Materials panel — first implementation

Karl approved the three-column mockup and requested an addon implementation.
Materials belongs to the selected goal, rather than every active goal.

The drawer is collapsed each reload. It leaves a 22-unit sliver of the actual
etched panel, with a 12-unit gap and a shaded edge. Opening reveals up to 210
units within the current window; the center guide uses its existing scroll
areas. The handle travels with the drawer edge in a 0.26-second ease-out,
with matching etched styling, grime, gold chevron and a small drop shadow.
Celebrations Off skips motion. The animation driver stops when finished or
hidden. Narrow windows keep the drawer closed until enough space is available.

Rows show small item icons, names, percentages and the existing progress bar.
Exact collected/remaining counts appear on hover; Show counts adds them below
the bar. The two-rail sliders control opens a local menu: Show collected,
Show counts, Include other characters. Preferences persist; drawer opening
does not. It hides on the Library, Settings and empty tracker.

Requirements come from countable item-collection rules, explicit AQ armor
ingredients and Tier 3 manual recipe lines. Tips supply known names/IDs but
never quantities. Shared stock milestones use their largest target; separate
recipe turn-ins add quantities. Selected parts and racial/faction scopes are
respected. Completed checklist entries credit collected ingredients. Completed
pieces credit spent ingredients separately, so a manual collection tick does
not double-count materials still held in bags. No ticks,
rules, step order or existing progress migrations are changed.

Item snapshots now watch explicit recipe ingredients too. Manual recipe
names resolve through existing tagged/collection IDs or the client's item
cache. Unresolved IDs show Count unavailable, rather than a verified zero.
When a name resolves after login, the new ID is watched and this character's
stock is captured. Other characters require another scan on those characters;
the tooltip explains that counts use their last scans. Item-info events are
coalesced. No item lookups run in the animation driver. After native review,
guide reflow is throttled to once per 75 ms during the 0.26-second transition
(at most three intermediate reflows), then refreshed fully at the end. This
keeps wrapped rows aligned while the center changes width, without rebuilding
the guide on every frame or continuously while idle.
Rows and bars are pooled. Main-chunk locals remain within the Lua 5.1 limit.

Validation: full tools/check.py suite on Lua 5.1, Classic Era and Forever,
including new requirement aggregation, roster scopes, historical credit,
unknown IDs, drawer animation lifecycle, empty/grouped goals and narrow
windows. Retained output: checks/materials-panel-2026-10-11.txt. Native visual
and input review remains Karl's next check. Source only: no version bump,
release tag or CurseForge publication. Fresh Ketho/LuaLS release diagnostics
remain required before publishing.

## Native slide-direction correction

Karl confirmed load without Lua errors and working open/close, then clarified
that Materials must come from under the outer right window edge. Anchoring
the full-width panel to the clip's left edge now moves it inward as the clip
expands; the original right anchor exposed stationary content from beneath
the guide instead. The shade now lives on the panel at its outer right edge,
with gradient alpha reduced throughout opening and hidden when fully open.
There is no tuck shade beside the center guide or on either open panel edge.
The gap, closed sliver, overall window size and moving handle are retained.
Updated full checks: checks/materials-slide-fix-2026-10-11.txt. Native recheck
is next; Lua-only edits, `/reload` is sufficient.

Karl confirmed the corrected motion matches his intent. He requested a more
subtle handle: now a 10-unit grey arrow, centered in the 12-unit panel gap,
turning gold on hover. The etched button, grime and shadow are removed.
The invisible 24x48 hit area and moving/reversing arrow behavior remain.
Checks: checks/materials-arrow-2026-10-11.txt.
