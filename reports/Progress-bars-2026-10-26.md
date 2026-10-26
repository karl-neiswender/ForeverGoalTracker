# Progress bar redesign, October 26, 2026

Locked by Karl on 2026-10-26 after two rounds of mockups. Covers backlog items 11 (reputation bars), 17 (main bar) and 18 (goal bars), from the [backlog](Backlog-brainstorm-2026-10-24.md). Mockups: [first pass](mockups/progress-bars-2026-10-26.html), [second pass](mockups/progress-bars-v2-2026-10-26.html) (the reference).

## Goal

The bars are the most important thing in the window and felt light. Give them weight without changing the window's footprint, keep the gradient, pulsing light and bright tip, keep every bar visibly one family, and show fewer words by default.

## Decisions

**One component, four sizes.** Main bar 24 px, goal page 18 px, pop-out 10 px, My Goals card 6 px. Library cards and the icon rail keep their sizes but get the same look. Same track, fill, tip and glint everywhere.

**Header.** The tagline is removed. The title strip holds the title, gear and close. The main bar sits centered in the space between the strip and the tabs. The "N of N goals fully complete" line and the "N% overall" label are removed from view.

**Numbers on hover.** At rest the main bar shows no words. Hovering brightens its rim (the hint) and fades in the percentage and "4 / 9 goals" inside the bar, in two tones: dark over the fill, light over the track, switching exactly at the tip. After a short pause a tooltip adds what the bar cannot show (nearest goal to done, next milestone). When progress changes, the numbers show for about 2.5 seconds, then fade. Setting: Numbers, On hover (default) or Always.

**Light.** One light per bar: the bright tip. The idle glint travels along the fill and ends at the tip, which flares when it arrives. The tip's glow spills a few pixels past the bar's top and bottom edges, which is what gives the thin bars weight.

**What you just earned.** When progress goes up, the newly added stretch flashes bright and fades into the fill.

**Ticks.** Each bar uses the ticks that are true for it. Main bar: 25, 50 and 75 (it is an average of goals, so per-goal ticks would mislead). Ticks spark once when crossed. Setting: Tick marks, On (default) or Off.

**Goal bars are segmented, one segment per step.** Gaps between segments. A step with a count (skill, items, reputation, levels, kills) fills its segment partway. Past 12 steps, and for set goals with pieces and the leveling goal, the bar is one continuous bar with 25, 50 and 75 ticks. Finished segments settle into a quieter gold; green means only that the whole goal is done. The My Goals card bar stays one plain bar.

**Order.** Segments always stay in the step list's position, so a step done out of order fills in place and leaves a gap. The glowing tip sits on the step last advanced; when that step finishes, it moves to the first step that can be done. Steps the addon knows cannot be done yet (order locks and requirement locks) are hatched. Only real prerequisites hatch, never recommended order.

**Several things at once.** Several segments can be partly filled. One action that moves two steps flashes both trails; the tip goes to the one that moved most. No bar inside a bar: a step that is itself a multi-stage climb (Exalted with Stormwind) is one segment, filled an equal share per standing.

**Hover.** Hovering a segment shows one tooltip: the step, its count, and the goal's percentage. Hovering a step row lights its segment, and hovering a segment lights its row.

**Reputation.** Each standing is an equal-width share regardless of its points. A reputation tooltip names the standing you are in, then points ("4,200 / 6,000"), then how far to the next standing. Standing names use the game's reputation colors.

**Step list.** Every step in progress shows a thin bar under its row, with its count or standing. Finished and untouched steps do not.

**Wording.** No directional cues in player text ("above", "left"): name the steps instead.

**Motion.** Everything follows the existing Celebrations and effects settings, including Off, where every bar still reads correctly without animation.

## Not in this pass

- Reputation goals that start below Neutral (Timbermaw starts at Hostile). The design gives them their own segments (Hostile, Unfriendly, Neutral, then Friendly onward). That adds steps to existing goals, and steps are saved by position, so it needs a one-time progress remap. Until then the first segment fills only once the character reaches Neutral.
- Forever: reputation, map and font behavior stay unverified until live Forever (November 4).

## Build status (2026-10-26, PC, unreleased; committed the same day after Karl's review passes below)

Built: `Bars.lua` (new, loaded before Core.lua: light, pulse, flare, earned trail, ticks, two-tone numbers, segments, one driver), `Media/stripes.tga` (hatch for locked segments), header (40 px strip, no tagline, 24 px main bar at y -59, hover numbers and tooltip), goal page segments with tooltips and step-row linking, continuous goal bar 18 px with a hover count, pop-out segments (10 px), My Goals card bar 6 px, reputation points in segment tooltips and step-row bars, `FGT.StepFraction`/`FGT.GoalFraction` (partial steps now count in every bar and in the overall percentage, including the login check-in), Settings, Progress bars (Numbers, Tick marks).

Checks: `tools/check.py` passes; Ketho/LuaLS zero problems with annotations loaded. Synced to Era. Native review in Era not done: needs a full game restart (new texture), then a look at every bar, hover, segment tooltips, a reputation goal, a goal with locked steps, the pop-out and Celebrations Off. Performance not measured (`/goals perf` with several goals open).

## Karl's first look, 2026-10-26 (changes, unreviewed)

Karl likes the bars but wanted more depth and asked about the tip and the hover fade. Changed in `Bars.lua` (bars 9 px and taller, so not the 6 px card bar):

- **Depth.** A shadow falls from the track's top edge over the track and the fill, the track's far end darkens, and the fill has a 1 px dark rim along its underside, so the bar reads as a lit rod in a carved groove.
- **Inner bloom.** A soft additive glow inside the fill, brightest at the tip and fading back about five bar heights and toward the fill's top and bottom. It pulses and flares with the tip.
- **Tip.** The spill glow was a full round glow centered on the tip, so half of it ran past the tip into the empty track (and past the bar's right end near 100%). It now uses only the glow's left half and ends at the bright core line. The core still breaks the bar's top and bottom edges.
- **Hover fade.** Hover rings and the main bar's numbers now fade out as fast as they fade in (0.12 s both ways, `FGT.Bars.HOVER_FADE`); before, out took 0.28 to 0.35 s. The pop-out header's hover wash still fades out slowly (0.28 s); not changed.

Checks pass and Era is synced; a `/reload` shows it (no new textures). Not yet seen in game.

Second pass, after Karl's screenshot (tip and fade fixed, bars still flat): the top shadow is deeper (62%, a third of the bar) with a 1 px dark line on the groove's top edge, a matching shadow rises from the bottom edge (50%), the fill has a soft highlight band just under the top shadow (additive, 22%), its start is shaded so both ends read rounded, and the underside rim is darker (50%). Same size rule (9 px and taller). Unseen in game.

Third pass (Karl: muddy; it should feel inset in the groove): the deep shadows moved under the fill, so they shade only the empty groove (top 65% over 45% of the height, bottom 45%). Over the fill there is only a thin contact shadow at the top (55%, about 14% of the height) and the 1 px edge line, then a brighter highlight band (28%); the start shade is lighter (25%). Karl is keeping this for now.

Hover border: more subtle, then subtler again at Karl's request: a quiet muted gold (0.55, 0.45, 0.26) at 32%, instead of bright gold at 60% (`RING_ON` in `Bars.lua`). Unseen in game.

Hover motion (Karl: the border still felt instant, and the main bar's tooltip lagged behind it):
- The border fades over 0.22 s (was 0.12) on an ease-out curve both ways, and its colour is blended premultiplied, so the change is spread over the whole fade instead of arriving at the end (blending black at full opacity into gold at 32% the plain way leaves most of the visible change for the last frames).
- The main bar's tooltip opens with the border (the 0.15 s delay is gone) and fades in on the same curve and time. Every bar tooltip (main bar, goal bar, goal page and pop-out segments) now fades out with the border instead of vanishing (`FGT.Bars.TipOut`); moving from one segment to the next carries the fade on rather than blinking.
- The main bar's numbers use the same 0.22 s.
- Fix (Karl: the shadow flashed on hover-off): the tooltip's drop shadow is a separate frame that ignores the tooltip's opacity, so it stayed dark while the tooltip faded out, then vanished. The bar fades now set the shadow's opacity with the tooltip's, and reset both when it hides.

Unseen in game; a `/reload` shows it.

## Engineering notes

- All bar animation runs on one shared, throttled driver that touches only visible bars and stops when idle. No per-frame allocation.
- Gradient textures do not fade with `SetAlpha`; fades redraw the gradient.
- Two-tone numbers are two font strings, each in its own clip frame, on the main bar only.
- 1 px ticks and segment gaps snap to whole pixels.
- Partial step progress comes from the existing step readouts (`RuleReadout`) plus reputation points; goal percentages count partial steps, so the overall average moves slightly.
