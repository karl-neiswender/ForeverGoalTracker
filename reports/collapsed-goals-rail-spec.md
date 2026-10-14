# Collapsed goals list: the icon rail (agreed spec, 2026-10-14)

Brainstormed by Karl and Claude. Not built yet: wait for Karl's go.

## Why

Focus on the open goal and reduce clutter. On small screens (Karl's laptop),
opening the Materials drawer leaves the goal page very narrow; collapsing the
goals list to a rail gives the room back while keeping one-click goal switching.

## The rail

- The goals list collapses to a rail about the width of a card's icon area
  (about 56 to 64 units). Open by default; the choice is remembered across
  reloads. The empty tracker always shows the full list.
- Each rail item is the same card, narrowed: same height as a full card, the
  etched background kept, and every card state carried over (unselected, hover,
  selected, selected hover, the Forever blue versions and the finished versions).
  The open goal keeps its gold rim and faint comet.
- Icons only. Hovering an icon shows the goal's name only in a tooltip, like
  the gear shows "Settings".
- On each icon: a thin progress sliver under it; the favorite star in the icon's
  top-right corner with a soft shadow under the star; a green check when finished;
  a blue rim for Forever-new goals.
- A thin divider only between the favorites and the other goals.
- Top: a filter button opening a small card beside the rail with the list's own
  controls (search, sort, this character only). While a filter is on, the button
  stays lit and shows a count ("4 of 12").
- Bottom: "+" for Find your next goal, and the chevron to expand the full list.
- Faction watermarks on the cards fade out when collapsing, never show in the
  rail, and fade back in when the list opens.

## Motion: one morph, not a swap

- The cards themselves narrow into rail items; each icon stays where it is.
- The panel's right edge glides left and the goal page widens in step.
- Card text is trimmed from the right as the card closes and fades at the same
  time (a horizontal "closing card" wipe); opening reveals it left to right.
- Search box and Sort fade out, the filter button fades in (and back on opening).
- Full: the whole morph. Subtle: cross-fade between the two layouts, no slide.
  Off: instant. Very fluid; no idle drivers once settled.

## Not now

- No Focus toggle, no automatic rail when Materials opens.
- No reading-width cap on the goal page yet; tune it after the rail ships.
