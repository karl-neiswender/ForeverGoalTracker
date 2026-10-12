# Modern typography withdrawn

Karl's live review confirmed startup, centered opening, smaller maximum
window size and font switching work without Lua errors. He found Open Sans
Bold headings too chunky, especially on gold cards and titles, and requested
removing Warcraft Modern before release. A lighter weight may be explored
later; no replacement typography feature is requested now.

The Typography Settings group, font preference default, Modern profile and
runtime font measurements are removed. Startup clears the obsolete saved
typeStyle key; existing Modern users return to Cinzel headings and the native
body font. Other settings and goal progress are untouched.

The weak font registry, body/title roles, nominal sizes, line-spacing logic,
font fallback, internal profile application and layout refresh remain for
future typography work. They have no public selector. Open Sans source TTFs
and their license remain in GitHub, excluded by .pkgmeta from release ZIPs.
Shipping credits/readme and Unreleased changelog no longer advertise Modern.

Full Lua 5.1 Classic Era and Forever checks pass. Updated typography tests
load a saved Modern preference, verify removal from Settings and restoration
of Serif, then exercise temporary internal swaps, stable sizes, later-created
widgets and fallback. Output: checks/modern-withdrawal-2026-10-11.txt.

`/reload` removes the setting and restores Serif. No restart or new font file
is needed. Unreleased source only; no version bump or release tag.
This supersedes the earlier typography-groundwork and font-switch reports
where they describe a public font choice or startup measurement.
