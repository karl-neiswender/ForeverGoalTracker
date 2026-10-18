# Redundant map actions, October 17, 2026

Karl’s screenshot showed both a capital city link and Show on map on the same war-mount step.

The shared map-text helper now leaves steps with an existing location/map hyperlink intact. The vendor link and named city destination remain; NPC-only steps still receive Show on map. Applies to the shared main/pop-out renderer. No data, progress or map destination changes and no new events or timers.

Focused Era and Forever scenarios pass for both factions, including the retained NPC-only action. Full suite evidence: `redundant-map-link-2026-10-17-lua51.txt`. Native review: `/reload` and inspect both war-mount guides. Unreleased; no version bump or tag.
