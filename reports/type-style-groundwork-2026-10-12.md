# Typography groundwork

Settings > Typography offers Warcraft Serif (default) and Warcraft Modern.
Serif preserves existing Cinzel Bold headings and WoW Friz Quadrata body
text. Modern uses bundled static Open Sans Bold headings and Regular body
text, including addon edit boxes and credits. Native game tooltips keep
the game's typography.

The first startup measures fixed heading and body samples through the
native font engine. Modern sizes use the ratio of the existing and new
text widths, bounded to 85–115% of the original nominal size. The fallback
heading ratio is 110%; PIL measurements of representative headings gave
Cinzel/Open Sans ratios of 1.043–1.179. Wrapped font strings retain their
original line advance. No fonts are modified or stretched. Individual
strings can still wrap differently because glyph proportions differ.

Weak font registration covers existing, pooled and later-created widgets.
Switching reapplies original nominal sizes, remeasures Settings choice
buttons and relays out visible content; the normal startup layout handles
saved choices. There are no new timers or per-frame font measurements.
Missing fonts fall back to Serif and then the native body font.

Static OpenSans-Regular.ttf and OpenSans-Bold.ttf were downloaded unchanged
from https://github.com/googlefonts/opensans/tree/main/fonts/ttf.
Their unchanged license is Fonts/OpenSans-OFL.txt from that repository.

Full Lua 5.1 Classic Era/Forever suite passed; retained output:
reports/checks/type-style-2026-10-12.txt. Typography tests exercise existing
widgets, repeated switches, restored sizes/line advance, lazy creation,
fallback and progress preservation. Stub tests do not verify native visual
metrics or actual line wrapping.

In-game review: fully restart for the new TTFs, then switch both styles in
Settings. Check long goal titles, cards, narrow Settings, multiline steps
and tips, grouped recipes, search and note fields, welcome wizard, empty
tracker and completion banner. Resize narrow/wide and confirm the saved
Modern choice survives /reload. Adjust role ratios/sample text if needed
after visual review. This is Unreleased source work; no version bump or tag.
