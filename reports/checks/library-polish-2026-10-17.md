# My Goals and Library polish, October 17, 2026

Unreleased source changes. No version bump, release tag or publication.

## Changes

- A text action below My Goals search toggles Hide completed goals / Show completed goals. Its setting is remembered; it does not remove goals or alter ticks. It combines with search and This character. Completion and reset refresh the filtered list immediately. The open guide remains available even when its completed card is hidden, so reset/undo stays accessible. Overall progress still counts all tracked goals.
- The folded goals rail includes the same action in its filter popup, with enough header height for the extra row. The filter icon lights while completed goals are hidden and its count follows list visibility.
- Plain, single-section item sets render without their redundant collapsible section header, even if that section was previously closed. Tier 1, Tier 2 and comparable lists use Items to collect. Ordered guides use Steps. Tier 3/AQ recipes retain their expandable section and material lists. All goal IDs, section keys and checkbox addresses stay unchanged.
- Completed Library cards and expanded collection parts no longer show the green wash. A small completion check, muted text and available completion date carry the status. Finished buttons use the normal subdued surface; hover still offers Remove. Forever cards keep their blue surface and NEW/UPDATED label, including when complete.
- New & Updated lists existing individual armor child goals and mount part cards directly. No new persistent goals are created. Add/Remove and bulk actions reuse existing child IDs or parent part selections. Category counts, search, Added/Not added, class and faction filters use those same result cards. Unrelated collection siblings stay out. With the filter off, collection browsing remains available.
- Skyborne's existing section now explicitly carries Alliance eligibility for its direct Library card. Mount rules, saved part order and progress remain unchanged.

## Validation

- Focused scenarios pass in fresh Lua 5.1 Era and Forever sessions, plus a save/reload check for the new filter.
- Scenarios cover hiding/recovering completed goals without deleting progress, immediate completion/reset visibility, rail filter status, old collapsed item-set sections, stable item checkbox keys, recipe headers, quiet completion, direct NEW/UPDATED results without duplicates, class/faction filtering and selecting only the Skyborne mount.
- Full suite evidence: `library-polish-2026-10-17-lua51.txt`.
- Ketho/LuaLS: no diagnostics with the existing Mac Lua 5.1 config and combined WoW annotation library. JSON and run/loading proof are retained in `library-polish-2026-10-17-luals.json` and `.txt`; 14027 annotation log references. Native client review remains separate.
- Performance review: no new game events, recurring timers or animations. The extra completion filter reads existing goal progress during list layout. Extracted part cards share a cached proxy per original part; the existing Library filter/layout pass supplies result counts. Plain-set detection walks that set's pieces once per guide render. No additional inventory scans or saved-progress migrations.

## Native review remaining

After `/reload`, check Hide completed goals in the open list and folded rail, including an all-completed list and combined search/character filters. Check Tier 1 and Tier 2 item layout, Tier 3/AQ recipes, and both simple and recipe pop-outs at narrow sizes. Review completed Library cards, dates, hover-to-remove and blue Forever identity. In New & Updated check Skyborne, both factions' PvP class sets, class/faction/category combinations, search, and individual/bulk Add/Remove. These automated checks do not establish native layout or in-game frame time.
