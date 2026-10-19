# Gear Planner hover and acquisition copy

Unreleased, October 18, 2026. Karl approved the subtle warm gold hover and inline acquisition sources.

Planner controls, equipment slots and picker rows now fade in a 13% gold wash over 120 ms. Existing selected rims/checks and item quality colors remain. Celebrations Off applies the hover immediately. Each driver stops on completion or hide; pooled rows reset on hide. No inventory scanning or catalogue traversal occurs per frame.

Generated goal steps name the item, boss and dungeon directly. Dungeon names use the existing map-link renderer. Crafted, quest and Tier 3 turn-in rewards use their corresponding acquisition actions. Tips retain summoning instructions, prerequisites, turn-in advice, the Devilsaur bonus and the existing Unconfirmed Forever notice without repeating every drop source. Goal IDs, slot order, owner rules, quantities and credit remapping are unchanged. Existing goals rebuild on reload.

Verification: `python3 tools/check.py` passed for Era and Forever, including acquisition copy/map links, crafting, summoning advice, duplicate-ring ownership, progress preservation and bounded hover/reduced-motion behavior. Output: `checks/gear-planner-hover-lua.txt`. Fresh LuaLS 3.19.2 diagnostics returned zero problems; Ketho annotation loading was verified with 3,506 unique annotation URIs. Results and loading proof: `checks/gear-planner-hover-luals.json` and `checks/gear-planner-hover-luals.txt`. This shared workspace diagnostic is not separate native testing of both clients.

Native review remains: `/reload`, hover slots and picker results, verify selected outlines and quality colors, then open a planner goal to check wrapped source text and clickable dungeon names. No new texture asset or restart is needed. Artwork audit found no pending files, including ignored originals. No release tag or publication.
