# UI conventions and performance

Load for visual, interaction, layout, tooltip or animation changes. Existing
source is the implementation reference; historical experiments are not new work.

- Reuse `C`, STYLE, shared widgets, `FGT.Icon`, etching, bars, dropdowns, sliders
  and toggles. All visible text uses Warcraft's native font. Cinzel Bold is only
  hidden tab-width measurement; retain its OFL license and packaging. Do not revive
  the retired Modern selector or old all-goal Materials tab.
- Keep My Goals view filtering separate from account-wide progress. Preserve
  Forever blue NEW/UPDATED behavior, done/favorite states, faction visibility,
  class/race restrictions and accessible click hints. Library totals are dynamic.
- New detail widgets belong in `detailParts` so the empty state hides them. Reused
  rows must reset all state, links, textures and visibility; test reuse where relevant.
- Main-window movement/resizing follows the custom cursor path, not Blizzard's
  `StartMoving`/`StartSizing`. Preserve positioning and screen bounds. Archived
  session values do not override current layout code. Minimap radius follows its
  width, not a fixed 80. Do not add main-chunk locals carelessly.
- Use native item tooltips and safe hyperlink routing. Clicking a link must not
  accidentally tick the row. Preserve shift/right-click behavior and per-character
  quest status. Personal note text is display-only; its edit control opens the editor.
- Grime belongs on broad surfaces, not content rows, cards, icons or tooltips.
  Preserve edge fades and the reviewed quiet styling; avoid decorative gold lines
  competing with progress bars. Keep tooltip content practical and concise.
- Gradient textures do not fade correctly through `SetAlpha`; redraw gradient
  alpha for them. Reuse color objects rather than allocating `CreateColor` per
  frame. Stop idle drivers, filter irrelevant events and debounce expensive refreshes.
- Respect current animation settings, including Off. Preserve effect layering and
  faded banner edges. Banners may follow live character race/class, not arbitrary
  roster selections. Apply only the affected banner's mappings/assets.
- Materials is per goal, collapsed on reload, and observational: never alters
  progress. Current options are `materialsShowDone=false`, `materialsBars=true`,
  `materialsAlts=true`. Inspect Materials.lua for current count rendering and sizing;
  October 11 percentage/count-toggle descriptions are superseded.
  Current rows show have / need; percentages are in tooltips.
- Popout.lua, Rail.lua and Maplet.lua own their respective interactions. Consult
  their source and targeted tests instead of copying the old Core-only file map.

For native visual issues, use screenshots/measurements and explain what Karl
should check. After two failed attempts, stop guessing. `/goals tipsdebug`,
`/goals perf`, `/goals gcprobe` and the offline perfbench serve different purposes;
passing offline tests does not establish native rendering, taint or frame time.
Lua edits need `/reload`; new or replaced cached assets need a full restart.

Detailed retired choices, numerical tuning and approval history remain in the
instruction archive and dated feature reports. Search a relevant topic there only
when current source or a regression investigation needs that historical evidence.
