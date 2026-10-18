# Hunter pre-raid test build

Karl requested the top recommendations from the linked [Wowhead Hunter pre-raid guide](https://www.wowhead.com/classic/guide/hunter-dps-pre-raid-best-in-slot-bis-gear-wow-classic), saved in the planner and added to Swagrid's Goals with item tracking and acquisition notes. This guide describes Season of Mastery; Forever availability remains Unconfirmed.

## Build and tracking

Saved Hunter Pre-Raid BiS for the current Alliance Hunter using 16 slots / 15 distinct item IDs. Both rings are Tarnished Elven Ring; melee uses Huntsman's Harpoon, with offhand empty. Shirt and tabard are empty. Crafted and quest rewards are identified as such rather than described as drops.

The explicit `/goals testhunterpreraid` command saves and adds the build. Repeating it reopens the same preset without duplicating or overwriting edits. Other characters' sets remain unchanged. Items are also available individually in the Hunter slot pickers.

Duplicate item tracking now uses cumulative quantities: first ring needs one copy; second ring needs two owned copies. Progress remains scoped to this character. Unique trinkets cannot be planned twice, and a two-handed melee weapon clears the offhand.

## Source verification

- Corrected the guide's Pendant location: [Lord Valthalak](https://www.wowhead.com/classic/npc=16042/lord-valthalak) is summoned in Upper Blackrock Spire, not Dire Maul.
- [Urok Doomhowl](https://www.wowhead.com/classic/npc=10584/urok-doomhowl) is in Lower Blackrock Spire, not Upper.
- Backwood Helm comes from [The Treasure of the Shen'dralar](https://www.wowhead.com/classic/quest=7877/the-treasure-of-the-shendralar), after The Madness Within.
- Checked [Isalien / Huntsman's Harpoon](https://www.wowhead.com/classic/npc=16097/isalien), [Hunter book turn-in](https://www.wowhead.com/classic/item=18361/the-greatest-race-of-hunters), and [Bloodseeker's quest](https://www.wowhead.com/classic/quest=8271/hero-of-the-stormpike).
- Remaining selections, IDs and routes come from the guide's top-ranked item links. No drop rates copied.

## Native result and limits

Executed the import in World of Warcraft Beta on Swagrid. Verified saved name, all 16 planner slot labels, sidebar entry, My Goals entry, 0/16 checklist, separate Finger 1/Finger 2 rows, Materials requirement of two rings, and expanded source Tips. Reload preserved the set and tracking. Repeating the command did not duplicate it.

Several Classic item IDs return no C_Item.GetItemInfo data in this beta. The native addon tooltip explicitly reports Not revealed yet / Item details are unavailable in Forever. Consequently some item links are plain text, Materials uses Item ID fallbacks, and parts of the model preview are absent. This is not proof of confirmed Forever availability or a complete rendered outfit. The planned targets and sources are preserved.

Added a bounded item-data refresh: query missing appearance data, and coalesce successful GET_ITEM_INFO_RECEIVED events for the selected set into one repaint. Register only while the planner is shown; at most 19 selected slots examined per event, no polling ticker. Actual still-withheld item models cannot be restored by this refresh.

## Checks

`python3 tools/check.py` passed for Era and Forever, including 16-slot import, sources, duplicate-ring credit and idempotence. [Full Lua output](checks/gear-planner-hunter-preraid-lua.txt). Fresh Ketho/LuaLS: zero diagnostics, 3506 unique annotation files loaded. [Diagnostics](checks/gear-planner-hunter-preraid-luals.json), [run / loaded-library proof](checks/gear-planner-hunter-preraid-luals.txt).

Artwork audit found no pending or ignored changes under Media/artwork. No release/tag.
