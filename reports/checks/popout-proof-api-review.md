# Pop-out proof of concept API review

October 13, 2026, Mac. Ketho WoW API 0.22.3 and LuaLS 3.19.1.

The headless diagnostic check used the retained Mac configuration at
`release-2.11.1-luals-config.json`, Lua 5.1, and the installed Ketho annotation
library. No diagnostic categories were disabled. The explicit legacy/optional
API exceptions already reviewed in `release-2.11.1-api-review.md` are unchanged.

Final result: `Diagnosis completed, no problems found`. Raw diagnostics,
output and verified annotation-loading records are retained beside this file
as `popout-proof-luals-*` and `popout-proof-annotation-loading.txt`.

The initial diagnostic run reported duplicate dispatch/placeholder definitions
and a missing SavedVariables guard. These were fixed by using one placeholder
handler, a normal slash-dispatch extension point and a saved-data presence check.

Ketho provides a combined client annotation library. This check does not claim
a dedicated Forever API flavor. Separate Era/Forever behavior sessions in
`popout-proof-check.txt` exercise the shared checklist, existing Classic locks
and default Forever gate policy, ingredient keys and existing link behavior.

Performance review: rows are pooled and the existing roster scan/debounce is
reused. Transfer updates run for at most 0.2 seconds; drag and resize updates
run only during their interaction, with resize reflow throttled to 75 ms and
a final refresh. Drivers stop on release, lock, hide and logout. The existing
goal-link ticker includes visible pop-out links while the main frame is closed.
No second inventory scan, rule engine or new permanent idle timer was added.

Native rendering, interaction, combat and CPU/memory review remain pending.
The computer-control tool timed out when attempting to inspect WoW. This is
prototype evidence, not authorization to publish or a completed live release gate.
