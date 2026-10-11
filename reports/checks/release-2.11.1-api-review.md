# 2.11.1 API compatibility review

Ketho WoW API 0.22.3 and LuaLS 3.19.1 are installed on this Mac. The headless check explicitly loads Ketho’s 3,506 annotation files with Lua 5.1. Annotation-loading evidence and raw diagnostics are retained beside this report. No diagnostic categories are disabled.

Ketho ships a combined client annotation library rather than a Warcraft Forever-specific API profile. Classic Era (11509) and Forever (16001) were reviewed separately against guarded runtime paths and the two-client behavior suite. Forever native mount rendering was verified earlier in this session; the modern profession scan was checked in game by Karl. These checks do not measure in-game CPU or replace final manual review.

## Explicit annotation exceptions

The configured global names below are specific external symbols, not permission for arbitrary addon globals. The behavior suite independently rejects unexpected addon global writes.

- ForeverGoalTrackerDB is declared by the TOC SavedVariables field.
- TomTom is an optional third-party addon, used only after presence checks.
- Classic quest/reputation/skill/container APIs: IsQuestFlaggedCompleted, GetNumQuestLogEntries, GetQuestLogTitle, GetFactionInfoByID, GetNumFactions, GetFactionInfo, GetNumSkillLines, GetSkillLineInfo, GetContainerNumSlots, GetContainerItemLink. Their modern C_ alternatives are preferred; legacy calls are checked for availability before use. The Era suite tests legacy skill scanning; the Forever suite tests modern professions and missing legacy item info.
- GetAddOnMetadata, InterfaceOptions_AddCategory and InterfaceOptionsFrame are legacy settings integration. Modern metadata/settings routes are used when available, with guarded legacy fallbacks.
- UnitPVPRank/GetPVPRankInfo and GetNumFriends/ShowFriends are guarded legacy roster/friends fallbacks. Missing functions leave the supported modern paths or safe default in place.

## New and changed API paths

- GetProfessions/GetProfessionInfo: Ketho flavor metadata marks both 0xF; both globals are tested before calls. Scan all six result slots with numeric indexing so missing primary slots cannot hide secondary skills.
- Mount previews: direct native item lookup first, one lazy cached journal-name scan second. DressUpMount and C_MountJournal presence checks protect unsupported clients. No new per-frame journal scan. Existing native Forever verification is recorded in the session handoff.
- GetStatistic returns text rather than a numeric achievement ID in Ketho annotations. The statistics debug command now obtains the ID from GetAchievementInfo(category,index), whose overload is annotated.
- Dynamic UI fields (tooltip darkness, toast, wizard grey state) are explicitly annotated; the collector now also guards missing grey state. Setting overloads document numeric scale/opacity and the boolean minimap choice.

## Performance review

Profession banner selection scans only the current goal’s profession steps at layout time and keeps its random choice until its eligible pool changes. Credits fade with artwork and resize, without another timer. Mount-name indexing is lazy once per session. The progress highlight reuses color tables and updates at 20 Hz. Bottom gradients are constructed once as 50 strips. No new continuous scan, disk IO or roster-wide artwork lookup was introduced.

## Final results

Both retained LuaLS passes have zero diagnostics using the combined Ketho library and explicit legacy/optional globals listed above. The configuration intentionally uses the same annotation union for Era and Forever; client distinctions are covered by the separate runtime paths and manual compatibility review, rather than claiming a native Forever annotation flavor exists. Full Lua 5.1 compile/load, accidental-global and regression sessions passed for Era and Forever after cleanup. Package integrity and runtime BLP bounds passed.

## Publication

Version is 2.11.1. No release tag has been created or pushed. Karl’s final in-game checks remain pending.
