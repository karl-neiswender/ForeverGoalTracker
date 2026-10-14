# Background image gaps — October 14, 2026

Audited source commit 5021dd3d6243f70df3afcc76c6368aa2f69559a0 after git pull confirmed current main. Loaded the real addon and artwork resolver under Lua 5.1/WoW stubs for Classic Era and Forever, with faction/class/race contexts. Library-only armor collection parents excluded; their independent goals included. Shared images count as coverage. This checks mappings and files, not in-game rendering or artistic suitability.

Six goals have no background in either supported client:

- Key: Shadowforge Key (Blackrock Depths) — key_brd
- Dungeons with Guildmates — social_guild_dungeon
- Raids with Guildmates — social_guild_raid
- Make Trades — social_trades
- Give Hugs — social_hugs
- Say LOL — social_lol

Max Primary Professions and Max Secondary Skills deliberately choose artwork from learned skills, so they are conditional rather than missing. All mapped texture files exist. Other item-set goals have dedicated or shared backgrounds; shared art does not imply every class has a unique illustration. Character-specific variations are outside the six blank-goal count.

Reproducible audit: reports/image-tests/audit-banner-coverage-2026-10-14.py. Full goal/path results: reports/image-tests/banner-coverage-2026-10-14.json. This supersedes the October 12 gap list.
