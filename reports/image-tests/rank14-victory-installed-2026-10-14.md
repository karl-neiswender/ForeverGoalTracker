# Shared Rank 14 victory banner installed

Karl approved the smoky, backlit version with light motes and requested installation for both Horde and Alliance rank goals. Grand Marshal (pvp_rank14_ally) and High Warlord (pvp_rank14_horde) share pvp_rank14-banner.blp through explicit variants, taking priority over the generic faction PvP fallback. Both use 4:3 and preprocessed=true.

Approved review: Media/final-images/morning-2026-10-14/rank14-victory-backlit-review.png. Master: rank14-victory-backlit-master.png in the same directory, 1200x900. Existing tools/artwork.py exporter produces one 512px DXT1 BLP with ten mip levels and independently decodes it. Rebuild map and runtime manifest updated. Exact prompts and prior variants retained. No new animation/light effects, goal changes or pop-out edits.

Checks: reports/checks/rank14-banner-2026-10-14.txt. Full game restart needed to load the new texture. Source sync only; no release tag.
