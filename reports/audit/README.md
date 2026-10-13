# Keeping our data current without scraping Wowhead

Written 2026-10-13. Wowhead has said it is adding protection against sites and addons that pull its pages repeatedly, and its robots.txt blocks AI crawlers outright. So nothing here fetches Wowhead on a schedule. The game itself is the main source of truth, and Wowhead's own front page is read by a person, once a day at most.

## 1. Ask the game (the main check)

In game, with the tracker's client of choice (Forever for Forever data):

1. `/goals audit`. It asks the game about every item, quest, faction and map the addon uses (about 800 items and 95 quests; roughly 25 seconds, 50 questions a second). Nothing runs at login.
2. Wait for "audit done", then `/reload` (the game writes saved data to disk on reload or logout).
3. `python tools/auditreport.py` reads the saved answers and writes `reports/audit/report-<date>.md`:
   - items and quests that are now **revealed** (Forever hides items until a player finds one),
   - steps that say **Source unknown** whose item has since been revealed,
   - **names that differ** from the game's (items and quest titles),
   - factions and maps that no longer exist,
   - what **changed since the last audit** (`reports/audit/last.json`).

Run it again after each Forever patch, or whenever you want to know. `/goals audit clear` removes the saved answers from your SavedVariables.

## 2. Community findings (a person looks once a day)

Wowhead Forever's front page lists the items and quests players have just found ("Latest Community Findings").

1. Open https://www.wowhead.com/forever yourself (at most once a day).
2. Run `tools/findings.js` in the browser console (or ask Claude to run it in the built-in browser). It reads the page you already loaded, so it makes no extra requests.
3. Save the result as `reports/audit/findings-YYYY-MM-DD.json`.
4. `python tools/findings.py` lists what the addon already uses, what is new since the last snapshot, and what we do not use yet.

The first snapshot is `findings-2026-10-13.json` (18 entries, none used by the addon yet).

## 3. Datamined tables (still to check)

Sites like wago.tools and wow.tools publish game database tables. Whether they carry a Forever build is not confirmed (the pages are dynamic and could not be read here). If one does, item and quest names, spells and maps could be compared offline in bulk. Karl may check the build list.

## 4. Wowhead itself

Karl is contacting Wowhead. Until they answer, nothing automated touches their site.
