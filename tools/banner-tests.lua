local F, D = STUB_NS, ForeverGoalTrackerDB
local B = F.goalBanner
do
    local goal = F.GoalById("glacial_blade")
    local path, aspect, preprocessed = B:ResolveArt("glacial_blade")
    assert(goal and goal.category == "PvP" and goal.faction == "Horde",
        "Glacial Blade retains its Horde PvP scope")
    assert(path == "glacial_blade-banner.blp" and aspect == 4/3 and preprocessed,
        "dedicated PvP weapon art takes precedence over the shared PvP fallback")
end
do
    local path, aspect, preprocessed = B:ResolveArt("social_lol")
    assert(path == "social_lol-banner.blp" and aspect == 4/3 and preprocessed,
        "Say LOL uses approved Tinker artwork")
    local originalContext = B.PlayerArtContext
    B.PlayerArtContext = function() return {faction="Alliance", class="SHAMAN", race="Dwarf"} end
    path, aspect, preprocessed = B:ResolveArt("allclasses")
    assert(path == "allclasses_dwarf_shaman-banner.blp" and aspect == 4/3 and preprocessed,
        "Alliance Dwarf Shaman leveling uses approved Barador artwork")
    for _, profile in ipairs({
        {faction="Horde", class="SHAMAN", race="Tauren"},
        {faction="Alliance", class="HUNTER", race="Dwarf"},
    }) do
        B.PlayerArtContext = function() return profile end
        assert(B:ArtPath("allclasses") ~= "allclasses_dwarf_shaman-banner.blp",
            "Dwarf Shaman art does not override other race/class/faction profiles")
    end
    B.PlayerArtContext = originalContext
end
do
    local path, aspect, preprocessed = B:ResolveArt("social_hugs")
    assert(F.GoalById("social_hugs") and path == "social_hugs-banner.blp"
        and aspect == 4/3 and preprocessed, "Give Hugs uses approved group embrace artwork")
end
do
    local path, aspect, preprocessed = B:ResolveArt("arcanite_reaper")
    assert(F.GoalById("arcanite_reaper") and path == "arcanite_reaper-banner.blp"
        and aspect == 4/3 and preprocessed, "Arcanite Reaper uses approved weapon artwork")
end
do
    local path, aspect, preprocessed = B:ResolveArt("teebus")
    assert(F.GoalById("teebus") and path == "teebus-banner.blp"
        and aspect == 4/3 and preprocessed, "Teebu's Blazing Longsword uses approved weapon artwork")
end
do
    local path, aspect, preprocessed = B:ResolveArt("raid_barrow")
    assert(F.GoalById("raid_barrow") and path == "raid_barrow-banner.blp"
        and aspect == 4/3 and preprocessed, "Burrow Deeps uses approved Timbermaw artwork")
end
do
    local originalContext = B.PlayerArtContext
    for _, entry in ipairs({
        { faction="Alliance", expected="set_tier1_hunter-alliance-banner.blp" },
        { faction="Horde", expected="set_tier1_hunter-banner.blp" },
    }) do
        B.PlayerArtContext = function() return {faction=entry.faction, class="HUNTER", race="Dwarf"} end
        local path, aspect, preprocessed = B:ResolveArt("set_tier1_hunter")
        assert(path == entry.expected and aspect == 4/3 and preprocessed,
            "Giantstalker uses the Alliance-only approved variant")
    end
    B.PlayerArtContext = originalContext
end
do
    for _, id in ipairs({"set_dungeon1_shaman", "set_dungeon2_shaman"}) do
        local path, aspect, preprocessed = B:ResolveArt(id)
        assert(F.GoalById(id) and path == id .. "-banner.blp" and aspect == 4/3 and preprocessed,
            "Elements and Five Thunders use approved Shaman artwork")
    end
end
for _, goal in ipairs(F.armorCollections.pvp_set_cloth_horde.armorChildren) do
    local path, aspect, preprocessed = B:ResolveArt(goal.id)
    assert(path == "pvp_set_cloth_horde-banner.blp" and aspect == 4/3 and preprocessed,
        "Horde cloth class goals inherit approved Thysta artwork")
end
do
    local originalContext = B.PlayerArtContext
    for _, faction in ipairs({"Alliance", "Horde"}) do
        B.PlayerArtContext = function() return {faction=faction, class="WARLOCK", race="Scourge"} end
        local path, aspect, preprocessed = B:ResolveArt("tier3_warlock")
        local expected = faction == "Horde" and "tier3_warlock-horde-banner.blp" or "tier3_warlock-alliance-banner.blp"
        assert(path == expected and aspect == 4/3 and preprocessed,
            "Horde Warlock Tier 3 uses Pagatha; Alliance retains approved variant")
    end
    B.PlayerArtContext = originalContext
end
do
    local originalContext = B.PlayerArtContext
    for _, faction in ipairs({"Alliance", "Horde"}) do
        B.PlayerArtContext = function() return {faction=faction, class="HUNTER", race="NightElf"} end
        local path, aspect, preprocessed = B:ResolveArt("set_tier2_hunter")
        local expected = faction == "Alliance" and "set_tier2_hunter-alliance-banner.blp" or "set_tier2_hunter-banner.blp"
        assert(path == expected and aspect == 4/3 and preprocessed,
            "Alliance Hunter Tier 2 uses Nordrassil Scout; Horde keeps existing art")
    end
    B.PlayerArtContext = originalContext
end
do
    local path, aspect, preprocessed = B:ResolveArt("social_guild_raid")
    assert(path == "social_guild_raid-banner.blp" and aspect == 4/3 and preprocessed,
        "Raids with Guildmates uses approved Nefarian group artwork")
end
for _, goal in ipairs(F.armorCollections.pvp_set_leather_ally.armorChildren) do
    local path, aspect, preprocessed = B:ResolveArt(goal.id)
    assert(path == "pvp_set_leather_ally-banner.blp" and aspect == 4/3 and preprocessed,
        "Alliance leather class sets use approved Moonshadow art")
end
do
    local originalContext = B.PlayerArtContext
    for _, faction in ipairs({"Alliance", "Horde"}) do
        B.PlayerArtContext = function() return {faction=faction, class="WARRIOR", race="Human"} end
        local path, aspect, preprocessed = B:ResolveArt("tier3_warrior")
        local expected = faction == "Alliance" and "tier3_warrior-banner.blp" or "tier3_warrior_koringar-banner.blp"
        assert(path == expected and aspect == 4/3 and preprocessed,
            "Warrior Tier 3 uses Dwarf for Alliance and Koringar for Horde")
        for _, child in ipairs(F.armorCollections.set_dungeon2.armorChildren) do
            path, aspect, preprocessed = B:ResolveArt(child.id)
            expected = ({
                set_dungeon2_hunter = "set_dungeon2_hunter-banner.blp",
                set_dungeon2_shaman = "set_dungeon2_shaman-banner.blp",
            })[child.id] or "set_dungeon2-banner.blp"
            assert(path == expected and aspect == 4/3 and preprocessed,
                "dedicated Dungeon Set 2 art overrides the collection fallback")
        end
    end
    B.PlayerArtContext = originalContext
end
for id, expected in pairs({social_trades="social_trades-banner.blp"}) do
    local path, aspect, preprocessed = B:ResolveArt(id)
    assert(path == expected and aspect == 4/3 and preprocessed, "approved Warrior Tier 3 and Make Trades artwork")
end
for _, id in ipairs({"pvp_rank14_ally", "pvp_rank14_horde"}) do
    local path, aspect, preprocessed = B:ResolveArt(id)
    assert(path == "pvp_rank14-banner.blp" and aspect == 4/3 and preprocessed,
        "both Rank 14 goals use the approved shared medallion instead of the PvP fallback")
end
do
    local get, info, lines, lineInfo = GetProfessions, GetProfessionInfo, GetNumSkillLines, GetSkillLineInfo
    local characters = D.characters
    D.characters = {}
    GetNumSkillLines, GetSkillLineInfo = nil, nil
    GetProfessions = function() return 1, 2, nil, 4, 5, 6 end
    local names = {[1]="Enchanting", [2]="Tailoring", [4]="Fishing", [5]="Cooking", [6]="First Aid"}
    GetProfessionInfo = function(index) return names[index], nil, 125, 300 end
    STUB_FIRE("SKILL_LINES_CHANGED")
    local me = D.characters[UnitName("player") .. "-" .. GetRealmName()]
    assert(me.skills.Enchanting == 125 and me.skills["First Aid"] == 125,
        "modern profession scan records primary and secondary skills across nil slots")
    assert(B:ArtPath("prof_all") and B:ArtPath("prof_secondary"), "scanned professions select installed artwork")
    GetProfessions = function() return nil, nil, nil, 4 end
    STUB_FIRE("SKILL_LINES_CHANGED")
    assert(B:ArtPath("prof_secondary") == "prof_fishing-banner.blp", "secondary-only characters retain fishing artwork")
    GetProfessions, GetProfessionInfo = nil, nil
    GetNumSkillLines = function() return 1 end
    GetSkillLineInfo = function() return "Leatherworking", false, nil, 75 end
    STUB_FIRE("SKILL_LINES_CHANGED")
    assert(B:ArtPath("prof_all") == "prof_leatherworking-banner.blp", "legacy skill scan still selects artwork")
    GetProfessions, GetProfessionInfo, GetNumSkillLines, GetSkillLineInfo = get, info, lines, lineInfo
    D.characters = characters
    B.professionArtChoices = {}
end
do
    local characters, art, choices = D.characters, B.professionArt, B.professionArtChoices
    local key = UnitName("player") .. "-" .. GetRealmName()
    D.characters = {[key]={skills={Leatherworking=1}}, Alt={skills={Enchanting=300}}}
    B.professionArt = {Leatherworking="leather.blp", Enchanting="enchant.blp", Tailoring="tailor.blp",
        Mining="mining.blp", Fishing="fishing.blp", Cooking="cooking.blp"}
    B.professionArtChoices = {}
    assert(B:ArtPath("prof_all")=="leather.blp", "profession art ignores an alt's skills")
    D.characters[key].skills = {Enchanting=1, Tailoring=1}
    local picked = B:ArtPath("prof_all")
    assert(picked=="enchant.blp" or picked=="tailor.blp")
    for i=1,5 do assert(B:ArtPath("prof_all")==picked, "random profession art stays stable during redraws") end
    D.characters[key].skills = {Mining=1}
    assert(B:ArtPath("prof_all")=="mining.blp", "gathering uses the same selection")
    D.characters[key].skills = {Fishing=1, Cooking=1}
    picked = B:ArtPath("prof_secondary")
    assert(picked=="fishing.blp" or picked=="cooking.blp", "secondary skills use their own eligible pool")
    D.characters[key].skills = {}
    assert(B:ProfessionArt(F.GoalById("prof_all"))==nil, "unknown professions retain fallback art")
    D.characters, B.professionArt, B.professionArtChoices = characters, art, choices
end
assert(B:ArtPath("pvp_av_horde") == "pvp_av_horde-banner.blp", "Frostwolf-specific banner wins over shared PvP variants")
assert(F.GoalById("pvp_avmount_horde").icon[1] == "ability_mount_whitedirewolf", "the Frostwolf Howler keeps its white wolf")
assert(F.GoalById("pvp_av_horde").icon[1] == "achievement_pvp_h_16", "Horde PvP uses the Horde PvP rank icon (Karl, 2026-10-13)")
assert(F.GoalById("pvp_av_ally").icon[1] == "achievement_pvp_a_a", "Alliance PvP uses the Alliance PvP rank icon")
for _, id in ipairs({ "pvp_mount_horde", "pvp_wsg_horde", "pvp_set_plate_horde" }) do
    assert(F.GoalById(id).icon[1] == "achievement_pvp_h_16", id .. " uses the Horde icon")
end
for _, id in ipairs({ "pvp_mount_ally", "pvp_ab_ally", "pvp_set_cloth_ally" }) do
    assert(F.GoalById(id).icon[1] == "achievement_pvp_a_a", id .. " uses the Alliance icon")
end
assert(F.GoalById("pvp_rank14_horde").icon[1] == "achievement_pvp_h_14" and F.GoalById("pvp_rank14_ally").icon[1] == "achievement_pvp_a_14",
    "High Warlord and Grand Marshal keep their own achievement icons (Karl, 2026-10-14)")
assert(F.GoalById("social_guild_dungeon").icon[1] == "inv_misc_head_dragon_green", "Dungeons with Guildmates icon")
assert(F.GoalById("social_buffs").icon[1] == "inv_misc_rune_03", "Buff Others icon")
do
    local original, received = B.icon.tex.SetTexture
    B.icon.tex.SetTexture = function(_, value) received = value end
    B.icon:SetIcon(81744)
    assert(received == 81744, "numeric texture ID passed directly to SetTexture")
    B.icon:SetIcon({81744, "inv_bannerpvp_01"})
    assert(received == 81744, "numeric texture ID also supported in fallback lists")
    B.icon.tex.SetTexture = original
end
F.detailBody.GetWidth = function() return B.panel:GetWidth() - 14 end
local desaturated
B.art.SetDesaturated = function(_, value) desaturated=value end
local g = F.GoalById("ashbringer")
D.active[g.id] = true
F.SelectGoal(g.id)
assert(B.hasArt, "Ashbringer uses the correctly assigned supplied art")
F.SetGoalNote(g, "")
local px, py
B.description.SetPoint = function(_,point,relative,relativePoint,x,y)
    if point == "TOPLEFT" then px,py=x,y end
end
B.difficulty.IsShown = function() return true end
B.duration.IsShown = function() return true end
B.difficulty.GetWidth = function() return 85 end
B.duration.GetWidth = function() return 75 end
B.panel.GetWidth = function() return 600 end
B.tag.GetStringHeight = function() return 12 end
B.title.GetStringHeight = function() return 40 end
F.LayoutGoalBanner(g)
local normal = py
B.title.GetStringHeight = function() return 96 end
F.LayoutGoalBanner(g)
assert(py < normal, "long wrapped title pushes chips and description down")
B.title.GetStringHeight = function() return 40 end
B.panel.GetWidth = function() return 190 end
F.LayoutGoalBanner(g)
assert(py < normal and px == 22, "narrow badge row wraps above the description")
local descriptionAnchor
B.description.SetPoint = function(_,point,relative)
    if point == "TOPLEFT" then descriptionAnchor = relative end
end
F.SetGoalNote(g,"Bring resistance gear.")
F.LayoutForeverInfo(g)
assert(descriptionAnchor == F.personalNote, "description follows the personal note")
F.SetGoalNote(g,"")
F.LayoutForeverInfo(g)
assert(descriptionAnchor == F.detailBody, "empty note leaves no extra gap")
local coords
local artWidth, artHeight
B.art.SetSize = function(_,w,h) artWidth,artHeight=w,h end
local bottomShown = false
B.bottom.Show = function() bottomShown=true end
B.bottom.Hide = function() bottomShown=false end
B.bottom.SetShown = function(_,v) bottomShown=v end
B.art.SetTexCoord = function(_,...) coords={...} end
B.GetHeight = function() return 200 end
B.panel.GetHeight = function() return 600 end
B.panel.GetWidth = function() return 600 end
B:Fit()
assert(B.fullImageHeight == 592, "full-height artwork fills the panel")
assert(math.abs(artWidth-592*0.70)<0.001, "full-height artwork uses a broad left fade")
assert(math.abs((artWidth/artHeight)/((coords[2]-coords[1])/(coords[4]-coords[3]))-(B.sourceAspect or 1))<0.001,
    "full-height artwork preserves source proportions")
F.SetSetting("tallGoalArt", false)
B:Fit()
local expectedHeight = math.max(184,592*0.6*0.92/(B.sourceAspect or 1))
assert(math.abs(artWidth-592*0.6*0.92) < 0.001 and math.abs(B.fullImageHeight-expectedHeight)<0.001,
    "artwork scales with window width")
assert(math.abs(artHeight-(expectedHeight-math.min(140,expectedHeight*0.35))) < 0.001,
    "original bottom transparency is preserved without an extra height change")
assert(not bottomShown, "bottom veil stays removed during resize")
B.panel.GetWidth = function() return 1000 end
B:Fit()
assert(math.abs(artWidth-992*0.6*0.92)<0.001 and B.uv[1]==0 and B.uv[2]==1 and B.uv[3]==0,
    "wide window enlarges artwork while preserving the top-right crop")
B.panel.GetWidth = function() return 190 end
B:Fit()
assert(B.uv[1]>0 and B.uv[3]==0 and B.uv[4]==1, "tall cover crops horizontally")
B.panel.GetHeight = function() return 100 end
B:Fit()
assert(B.fullImageHeight == 92 and B.uv[4] < 1, "short panel crops artwork at its bottom without shrinking the subject")
assert(B.fadeStrips[1].fadeWeight > 0.99 and B.fadeStrips[64].fadeWeight < 0.001,
    "artwork itself fades smoothly to transparent at its bottom")
B.panel.GetHeight = function() return 600 end
F.SetSetting("tallGoalArt", true)
-- A saved-goal startup may have no empty-state transition to show the driver.
local driverShown = false
local originalShow, originalIsShown = B.Show, B.IsShown
B.Show = function() driverShown=true end
B.IsShown = function() return driverShown end
local stripVisible = {}
for i,t in ipairs(B.fadeStrips) do
    t.SetShown = function(_,v) stripVisible[i]=v end
end
F.LayoutGoalBanner(g)
assert(driverShown, "saved-goal layout explicitly shows the animation driver")
for i=1,#B.fadeStrips do assert(stripVisible[i], "bottom fade strip stays visible: "..i) end
B.Show, B.IsShown = originalShow, originalIsShown
for id in pairs(B.artPaths) do
    assert(F.GoalById(id), "artwork maps to an existing goal: " .. id)
    D.active[id] = true
    F.SelectGoal(id)
    -- Legacy collection links open an individual set, which may have its own art.
    local selected = B.goal.id
    assert(B.hasArt and B.sourceAspect == B.artAspects[selected], id .. " uses supplied art with original proportions")
    assert(desaturated == (not B.preprocessed[selected]), id .. " selects the correct desaturation state on reused art")
    if B.preprocessed[selected] then assert(B.sourceAspect == 4/3, "taller final masters retain 4:3 proportions") end
end
for _, id in ipairs({"raid_mc", "att_mc", "set_tier1"}) do
    F.SelectGoal(id)
    assert(B.preprocessed[id] and not desaturated and B.sourceAspect == 4/3,
        id .. " uses the approved monochrome Molten Core master")
end
-- The logged-in faction picks Warrior Tier 2 art on both clients.
local originalFaction = UnitFactionGroup
local texture, originalTexture = nil, B.art.SetTexture
B.art.SetTexture = function(_, path) texture=path end
for _, faction in ipairs({"Alliance", "Horde", "Neutral"}) do
    UnitFactionGroup = function(unit) assert(unit=="player"); return faction end
    F.SelectGoal("set_tier1_warlock")
    local warlockArt = faction=="Alliance" and "set_tier1_warlock-alliance-banner.blp" or "set_tier1_warlock-banner.blp"
    assert(B:ArtPath("set_tier1_warlock")==warlockArt, "Warlock Tier 1 selects approved faction artwork for "..faction)
    assert(not desaturated and B.sourceAspect==4/3, "Felheart faction artwork keeps approved treatment and proportions")
    F.SelectGoal("set_tier1_priest")
    local priestArt = faction=="Horde" and "set_tier1_priest-horde-banner.blp" or "set_tier1_priest-banner.blp"
    assert(B:ArtPath("set_tier1_priest")==priestArt, "Priest Tier 1 uses approved faction portrait for "..faction)
    assert(not desaturated and B.sourceAspect==4/3, "Priest Tier 1 keeps approved treatment and proportions")
    F.SelectGoal("tier3_priest")
    assert(B:ArtPath("tier3_priest")=="tier3_priest-banner.blp", "Priest Tier 3 keeps approved Alliance/default art for "..faction)
    assert(not desaturated and B.sourceAspect==4/3, "Priest Tier 3 keeps approved treatment and proportions")
    F.SelectGoal("set_tier2_priest")
    assert(B:ArtPath("set_tier2_priest")=="set_tier2_priest-banner.blp", "Priest Tier 2 keeps approved Alliance/default art for "..faction)
    assert(not desaturated and B.sourceAspect==4/3, "Priest Tier 2 keeps approved treatment and proportions")
    F.SelectGoal("set_tier2_warrior")
    local filename = faction=="Alliance" and "set_tier2_warrior-alliance-banner.blp" or "set_tier2_warrior-banner.blp"
    assert(texture:sub(-#filename)==filename, "logged-in faction selects "..filename)
    assert(not desaturated and B.sourceAspect==4/3, "faction variants keep approved treatment")
    F.SelectGoal("set_tier1_warrior")
    assert(texture:sub(-#"set_tier1_warrior-banner.blp")=="set_tier1_warrior-banner.blp",
        "faction variants leave other goals unchanged")
end
UnitFactionGroup = nil
F.SelectGoal("set_tier2_warrior")
assert(B:ArtPath("set_tier2_warrior")==B.artPaths.set_tier2_warrior,
    "unavailable faction API keeps the existing banner")
UnitFactionGroup, B.art.SetTexture = originalFaction, originalTexture
-- Live character context, not selected group parts or another roster entry.
do
    local savedRace, savedClass, savedFaction = UnitRace, UnitClass, UnitFactionGroup
    local savedParts = D.activeParts
    local race, class, faction = "Dwarf", "HUNTER", "Alliance"
    UnitRace = function(unit) assert(unit=="player"); return "Localized race", race end
    UnitClass = function(unit) assert(unit=="player"); return "Localized class", class end
    UnitFactionGroup = function(unit) assert(unit=="player"); return faction end
    D.activeParts = {allclasses={[7]=true}, epicmounts={[1]=true,[8]=true}}
    F.SelectGoal("allclasses")
    assert(B:ArtPath("allclasses")=="allclasses_dwarf_hunter-banner.blp", "dwarf hunter uses approved portrait despite mage-only selection")
    assert(B.hasArt and B.sourceAspect==4/3 and not desaturated)
    assert(B:ArtPath("epicmounts")=="epicmounts_dwarf-banner.blp", "logged-in dwarf favors ram over selected mounts")
    assert(B:ArtPath("pvp_hk")=="pvp_drums_of_war-banner.blp", "Alliance kills use shared Drums of War")
    assert(B:ArtPath("pvp_duelist")=="pvp_drums_of_war-banner.blp", "Alliance duels use shared Drums of War")
    assert(B:ArtPath("pvp_rank14_ally")=="pvp_rank14-banner.blp", "Alliance rank uses shared backlit medallion")
    assert(B:ArtPath("pvp_mount_ally")=="pvp_mount_ally-banner.blp" and B:ArtPath("pvp_avmount_ally")=="pvp_mount_ally-banner.blp", "both Alliance PvP mounts use flipped ram")
    race = "NightElf"
    assert(B:ArtPath("allclasses")=="allclasses_nightelf_hunter-banner.blp", "Night Elf Hunter uses new leveling art")
    assert(B:ArtPath("tier3_warlock")=="tier3_warlock-alliance-banner.blp")
    assert(B:ArtPath("pvp_set_mail_horde_hunter")=="pvp_troll_hunter_mail-banner.blp", "Alliance player sees approved Troll Warlord mail art on Horde Hunter set")
    assert(B:ArtPath("pvp_set_mail_horde_shaman")=="pvp_set_mail_horde_shaman-banner.blp", "Horde Shaman set uses dedicated Bru'kan art")
    assert(B:ArtPath("set_dungeon1_priest")=="key_strat-banner.blp", "Devout set uses approved Stratholme art")
    assert(B:ArtPath("pvp_rank14_horde")=="pvp_rank14-banner.blp", "Horde rank uses shared medallion even on an Alliance character")
    assert(B:ArtPath("set_tier2_warlock")=="set_tier2_warlock-alliance-banner.blp")
    assert(B:ArtPath("set_tier1_paladin")=="set_tier1_paladin-banner.blp")
    race = "Dwarf"
    class = "PRIEST"
    F.SelectGoal("allclasses")
    assert(B:ArtPath("allclasses")=="set_tier2_priest-banner.blp", "dwarf priest leveling uses approved dwarf Tier 2 portrait despite selected parts")
    assert(B.sourceAspect==4/3 and not desaturated)
    race = "Human"
    F.SelectGoal("allclasses")
    assert(B:ArtPath("allclasses")=="set_tier1_priest-banner.blp", "human priest leveling uses approved Anduin portrait")
    assert(B.sourceAspect==4/3 and not desaturated)
    race = "NightElf"
    assert(B:ArtPath("allclasses")=="benediction-alliance-banner.blp", "night elf priest leveling uses Jimmy Lo artwork")
    assert(B:ArtPath("benediction")=="benediction-alliance-banner.blp", "Alliance Benediction uses Jimmy Lo artwork")
    race, class, faction = "Troll", "MAGE", "Horde"
    assert(B:ArtPath("benediction")=="benediction-banner.blp", "Horde retains the original Benediction artwork")
    assert(B:ArtPath("epicmounts")=="epicmounts_troll-banner.blp")
    assert(B:ArtPath("pvp_hk")=="pvp_drums_of_war-banner.blp")
    assert(B:ArtPath("pvp_duelist")=="pvp_drums_of_war-banner.blp")
    assert(B:ArtPath("pvp_rank14_horde")=="pvp_rank14-banner.blp", "Horde rank uses shared backlit medallion")
    assert(B:ArtPath("pvp_rank14_ally")=="pvp_rank14-banner.blp", "Alliance rank uses shared medallion even on a Horde character")
    class = "HUNTER"
    assert(B:ArtPath("allclasses")=="tier3_hunter-banner.blp", "Troll Hunter leveling uses Cryptstalker and white lion artwork")
    race = "Orc"
    assert(B:ArtPath("allclasses")=="allclasses_horde_hunter-banner.blp", "Horde Hunter uses new leveling art")
    assert(B:ArtPath("tier3_druid")=="tier3_druid-banner.blp", "Horde Dreamwalker uses the shared Tier 3 Druid art")
    assert(B:ArtPath("set_tier2_druid")=="set_tier2_druid-horde-banner.blp", "Horde Stormrage has its own art")
    assert(B:ArtPath("tier3_warlock")=="tier3_warlock-horde-banner.blp", "Horde Warlock uses approved Pagatha artwork")
    race, class = "Troll", "MAGE"
    F.SelectGoal("allclasses")
    assert(B:ArtPath("allclasses")=="allclasses_troll_mage-banner.blp", "troll mage leveling uses approved troll portrait")
    assert(B.sourceAspect==4/3 and not desaturated)
    race = "Scourge"
    assert(B:ArtPath("allclasses")=="allclasses_troll_mage-banner.blp", "other Horde mages use approved Horde mage fallback")
    race = "Troll"
    -- Register future approved Mage variants and check exact-race precedence.
    local registeredCandidates = B.artVariants.allclasses
    local candidates = {}
    B.artVariants.allclasses = candidates
    candidates[#candidates+1] = {path="horde-mage-test.blp",faction="Horde",class="MAGE",aspect=1.5,preprocessed=false}
    candidates[#candidates+1] = {path="troll-mage-test.blp",faction="Horde",class="MAGE",race="Troll"}
    assert(B:ArtPath("allclasses")=="troll-mage-test.blp", "race/class match beats faction/class regardless of insertion order")
    race = "Scourge"
    local path, aspect, processed = B:ResolveArt("allclasses")
    assert(path=="horde-mage-test.blp" and aspect==1.5 and processed==false, "variant carries its own aspect and desaturation")
    B.artVariants.allclasses = registeredCandidates
    race, class, faction = "Dwarf", "SHAMAN", "Alliance"
    F.SelectGoal("allclasses")
    assert(B:ArtPath("allclasses")=="allclasses_dwarf_shaman-banner.blp", "Alliance Dwarf Shaman gets approved leveling portrait")
    assert(B.sourceAspect==4/3 and not desaturated)
    race = "Human"
    assert(B:ArtPath("allclasses")~="allclasses_dwarf_shaman-banner.blp", "Shaman portrait requires Dwarf race")
    race, faction = "Dwarf", "Horde"
    assert(B:ArtPath("allclasses")~="allclasses_dwarf_shaman-banner.blp", "Dwarf Shaman portrait requires Alliance")
    race, class, faction = "Scourge", "PALADIN", "Horde"
    F.SelectGoal("allclasses")
    assert(B:ArtPath("allclasses")=="allclasses_undead_paladin-banner.blp", "Undead Paladin gets approved painted leveling portrait")
    assert(B.sourceAspect==4/3 and not desaturated)
    assert(B:ArtPath("epicmounts")=="epicmounts_undead-banner.blp", "Undead gets skeletal warhorse")
    class = "PRIEST"
    assert(B:ArtPath("allclasses")~="allclasses_undead_paladin-banner.blp", "Undead portrait requires Paladin class")
    class, race = "PALADIN", "BloodElf"
    assert(B:ArtPath("allclasses")~="allclasses_undead_paladin-banner.blp", "Paladin portrait requires Undead race")
    local dmPath, dmAspect, dmProcessed = B:ResolveArt("key_dm")
    assert(dmPath=="key_dm-banner.blp" and dmAspect==4/3 and dmProcessed, "Dire Maul has approved preprocessed banner")
    race, class, faction = "Dwarf", "WARRIOR", "Alliance"
    assert(B:ArtPath("allclasses")=="allclasses_dwarf_warrior-banner.blp", "dedicated dwarf warrior is more specific than Alliance warrior")
    race = "Skyborne"
    assert(B:ArtPath("epicmounts")=="epicmounts_skyborne-banner.blp", "Skyborne gets approved island location")
    race = "UnknownRace"
    D.activeParts.epicmounts = {[2]=true}
    assert(B:ArtPath("epicmounts")=="epicmounts_dwarf-banner.blp", "missing race art can use sole same-faction selected mount")
    D.activeParts.epicmounts = {[8]=true}
    assert(B:ArtPath("epicmounts")=="epicmounts_human-banner.blp", "opposite faction selection cannot override faction fallback")
    race = "Gnome"
    assert(B:ArtPath("epicmounts")=="epicmounts_gnome-banner.blp", "Gnome gets approved mechanostrider even with other mounts selected")
    -- Ambassador banners by race: the city for its races, the current image for everyone else.
    -- Variants stay pending (and so unused) until their textures exist; this turns them on in
    -- memory to prove the selection rules.
    class = "MAGE"
    faction, race = "Alliance", "Dwarf"
    local pendingFlags = {}
    for _, id in ipairs({"rep_ambassador_ally", "rep_ambassador_horde"}) do
        for i, v in ipairs(B.artVariants[id]) do
            assert(not v.pending, "approved city art is active")
        end
    end
    assert(B:ArtPath("rep_ambassador_ally")=="rep_ambassador_ally_ironforge-banner.blp", "approved city art is active")
    for _, id in ipairs({"rep_ambassador_ally", "rep_ambassador_horde"}) do
        for _, v in ipairs(B.artVariants[id]) do pendingFlags[v] = v.pending or false; v.pending = nil end
    end
    local alliance = { Dwarf="rep_ambassador_ally_ironforge-banner.blp", Gnome="rep_ambassador_ally_ironforge-banner.blp",
        NightElf="rep_ambassador_ally_darnassus-banner.blp", Human="rep_ambassador_ally-banner.blp",
        Skyborne="rep_ambassador_ally-banner.blp", UnknownRace="rep_ambassador_ally-banner.blp" }
    faction = "Alliance"
    for r, path in pairs(alliance) do race = r; assert(B:ArtPath("rep_ambassador_ally")==path, "Alliance " .. r .. " gets " .. path) end
    local horde = { Tauren="rep_ambassador_horde_thunderbluff-banner.blp", Scourge="rep_ambassador_horde_undercity-banner.blp",
        Orc="rep_ambassador_horde-banner.blp", Troll="rep_ambassador_horde-banner.blp",
        Skyborne="rep_ambassador_horde-banner.blp", UnknownRace="rep_ambassador_horde-banner.blp" }
    faction = "Horde"
    for r, path in pairs(horde) do race = r; assert(B:ArtPath("rep_ambassador_horde")==path, "Horde " .. r .. " gets " .. path) end
    -- the other faction's goal never takes this faction's city, whatever the race
    faction, race = "Horde", "Tauren"
    assert(B:ArtPath("rep_ambassador_ally")=="rep_ambassador_ally-banner.blp", "a Horde character viewing the Alliance goal sees the default")
    for v, pending in pairs(pendingFlags) do v.pending = pending or nil end
    UnitRace, UnitClass, UnitFactionGroup = nil, nil, nil
    assert(B:ArtPath("rep_ambassador_ally")=="rep_ambassador_ally-banner.blp", "no character APIs: the default image")
    assert(B:ArtPath("allclasses")=="pvp_shared-banner.blp")
    assert(B:ArtPath("pvp_hk")=="pvp_drums_of_war-banner.blp", "shared combat art works without character APIs")
    assert(not B:ArtPath("epicmounts"), "unknown character cannot leak previous mount")
    UnitRace, UnitClass, UnitFactionGroup = savedRace, savedClass, savedFaction
    D.activeParts = savedParts
    print("  character banners: faction/class/race priority, live login, racial mounts, PvP, metadata and absent-API fallback ok")
end
D.active.raid_bwl = true
F.SelectGoal("raid_bwl")
assert(not desaturated, "final Blackwing Lair artwork bypasses desaturation")
D.active.raid_ony = true
F.SelectGoal("raid_ony")
assert(B.preprocessed.raid_ony and not desaturated and B.sourceAspect == 4/3, "approved Onyxia master bypasses desaturation at 4:3")
D.active.mount_dreadsteed = true
F.SelectGoal("mount_dreadsteed")
assert(B.preprocessed.mount_dreadsteed and not desaturated and B.sourceAspect == 4/3,
    "approved Dreadsteed master retains its monochrome look and landscape proportions")
D.active.mount_charger = true
F.SelectGoal("mount_charger")
assert(not desaturated and B.sourceAspect == 4/3, "approved Charger artwork retains baked monochrome treatment")
assert(B:ArtPath("raid_naxx") == "raid_naxx-banner.blp" and B.preprocessed.raid_naxx,
    "Naxxramas raid uses its approved replacement")
assert(B.professionArt.Leatherworking == "prof_leatherworking-banner.blp"
    and B.professionArt.Enchanting == "prof_enchanting-banner.blp", "approved profession artwork is connected")
F.SelectGoal("raid_bwl")
assert(not desaturated, "switching back clears desaturation")
D.active.gold_5k = true
F.SelectGoal("gold_5k")
assert(B.hasArt and B:ArtPath("gold_5k")=="gold_5k-banner.blp" and B.sourceAspect==4/3 and not desaturated, "gold goal uses approved treasure banner")
D.active.social_friends = true
F.SelectGoal("social_friends")
assert(B.hasArt and B:ArtPath("social_friends") == "social_friends-banner.blp", "Making Friends uses approved artwork")
D.active.social_guild = true
F.SelectGoal("social_guild")
assert(B.hasArt and B:ArtPath("social_guild") == "social_guild-banner.blp",
    "Join a Guild uses approved artwork")
D.active.social_lol = true
local lolArt = B.artPaths.social_lol
B.artPaths.social_lol = nil -- exercise the fallback even now that every content goal has art
F.SelectGoal("social_lol")
assert(not B.hasArt, "unmapped goal clears previous artwork")
B.artPaths.social_lol = lolArt
-- Only the background artwork fades; the square goal icon remains immediate.
B:StopImageFade()
B.imageSeen = {}
local visible = false
local iconAlphaWrites = 0
local originalIconAlpha = B.icon.SetAlpha
B.icon.SetAlpha = function() iconAlphaWrites=iconAlphaWrites+1 end
B.IsVisible = function() return visible end
F.SetSetting("celebrations", "full")
B.goal = F.GoalById("raid_mc")
B:RevealImages()
assert(not B.imageSeen.raid_mc and not B.revealGoal, "hidden layouts do not consume first-open reveal")
visible = true
B:RevealImages()
assert(B.imageFade == 0 and B:GetScript("OnUpdate"), "first visible open starts at zero")
assert(B.art.fgtGa2 == 0, "artwork gradient starts fully transparent")
local tick = B:GetScript("OnUpdate")
tick(B, 0.2)
local mid = B.imageFade
assert(mid > 0 and mid < 1, "fade eases through intermediate opacity")
assert(math.abs(B.art.fgtGa2-0.18*mid) < 0.0001, "artwork gradient follows the fade")
B:RevealImages()
assert(B.imageFade == mid and B:GetScript("OnUpdate") == tick, "layout refresh does not restart fade")
F.LayoutGoalBanner(B.goal)
assert(B.imageFade == mid and math.abs(B.art.fgtGa2-0.18*mid)<0.0001,
    "texture refresh preserves the running gradient fade")
-- a bloom is painted at the fade's level as soon as it is placed: never a frame at full strength
if B.bloomOn then
    assert(B.bloomTex.fgtQ2 and B.bloomTex.fgtQ2 <= math.floor(0.6*0.54*mid*255 + 1.5), "the bloom follows the first-open fade (" .. tostring(B.bloomTex.fgtQ2) .. ")")
    assert(B.glowTex.fgtQ2 and B.glowTex.fgtQ2 < 0.2*255*0.54*mid + 2, "so does the glow")
end
tick(B, 0.9)
assert(B.imageFade == 1 and B.imageSeen.raid_mc and not B:GetScript("OnUpdate"), "fade completes and stops its ticker")
B:StopImageFade(); B:RevealImages()
assert(B.imageFade == 1 and not B:GetScript("OnUpdate"), "repeat visits are immediate")
B.goal = F.GoalById("att_mc")
B:RevealImages()
assert(B.imageFade == 0, "another goal gets its own first reveal")
B:GetScript("OnUpdate")(B, 0.1)
B:GetScript("OnHide")(B)
assert(B.imageFade == 1 and not B:GetScript("OnUpdate") and not B.imageSeen.att_mc,
    "hide cancels fade without leaving dimmed artwork or consuming unseen goal")
F.SetSetting("celebrations", "subtle")
B:RevealImages()
assert(B:GetScript("OnUpdate"), "subtle motion still fades")
F.SetSetting("celebrations", "off")
B:GetScript("OnUpdate")(B, 0.01)
assert(B.imageFade == 1 and not B:GetScript("OnUpdate"), "motion off completes a running fade immediately")
B.goal = F.GoalById("gold_5k")
B:RevealImages()
assert(B.imageFade == 1 and B.imageSeen.gold_5k and not B:GetScript("OnUpdate"), "motion off skips new fades too")
F.SetSetting("celebrations", "full")
assert(iconAlphaWrites == 0, "background reveal never changes the square goal icon opacity")
B.icon.SetAlpha = originalIconAlpha
-- Per-goal tuning must scale all gradient strips and survive goal switches.
F.SelectGoal("raid_mc")
B:StopImageFade()
SlashCmdList.FOREVERGOALTRACKER("banneropacity 60")
assert(D.bannerOpacity.raid_mc == 0.6 and math.abs(B.art.fgtGa2-0.108)<0.0001,
    "saved opacity scales the existing banner strength")
for _, strip in ipairs(B.fadeStrips) do
    assert(math.abs(strip.fgtGa2-0.108*strip.fadeWeight)<0.0001,
        "opacity preserves the smooth bottom fade")
end
B:SetImageFade(0.5)
assert(math.abs(B.art.fgtGa2-0.054)<0.0001, "opacity multiplies rather than replacing reveal fade")
F.SelectGoal("raid_bwl"); B:StopImageFade()
assert(B:GetArtOpacity()==1 and math.abs(B.art.fgtGa2-0.18)<0.0001,
    "tuning one banner leaves other banners at their default")
F.SelectGoal("raid_mc"); B:StopImageFade()
assert(B:GetArtOpacity()==0.6, "saved tuning follows the goal on return")
SlashCmdList.FOREVERGOALTRACKER("banneropacity 101")
assert(B:GetArtOpacity()==0.6, "invalid tuning is rejected")
SlashCmdList.FOREVERGOALTRACKER("banneropacity reset")
assert(D.bannerOpacity.raid_mc==nil and math.abs(B.art.fgtGa2-0.18)<0.0001,
    "reset restores the approved banner default")
local hidden=0
for _,t in ipairs({B.background,B.border,B.art,B.left,B.top,B.bottom}) do t.Hide=function() hidden=hidden+1 end end
B:GetScript("OnHide")(B)
assert(hidden==6, "empty-state hide clears all background layers")
print("  banner title reflow, badge wrapping, artwork switching, aspect crop and empty-state layers ok")

-- Credit follows the resolved banner, stays quiet on small bounds, and
-- never carries an artist across to unattributed artwork.
for _, id in ipairs({"rep_thorium", "pvp_wsg_ally", "pvp_wsg_horde", "pvp_av_ally", "pvp_darkspear_raiders", "pvp_theramore_expedition"}) do
    local path, aspect, preprocessed = B:ResolveArt(id)
    assert(path == id .. "-banner.blp", "dedicated reputation art overrides shared PvP: " .. id)
    assert(aspect == 4/3 and preprocessed, "approved reputation art retains its framing")
end
do
    local width, height, alpha, label = 650, 600
    local ow, oh = B.panel.GetWidth, B.panel.GetHeight
    local oa, ot = B.credit.SetAlpha, B.credit.SetText
    local goal = B.goal
    B.panel.GetWidth = function() return width end
    B.panel.GetHeight = function() return height end
    B.credit.SetAlpha = function(_, a) alpha=a end
    B.credit.SetText = function(_, text) label=text end
    B.goal = F.GoalById("wolfsbane"); B:Fit()
    assert(alpha == 0.90 and label == "Artwork by Samwise Didier")
    height = 250; B:Fit(); assert(alpha == 0, "short credit hidden")
    height, width = 600, 330; B:Fit(); assert(alpha == 0, "narrow credit hidden")
    width = 435; B:Fit(); assert(alpha > 0 and alpha < 1, "credit eases between bounds")
    B.goal = F.GoalById("atiesh"); B:Fit(); assert(label == "", "unknown artist stays blank")
    B.panel.GetWidth, B.panel.GetHeight = ow, oh
    B.credit.SetAlpha, B.credit.SetText, B.goal = oa, ot, goal
end

-- The twenty weapon goal backgrounds (2026-10-25) keep the page's drifting leaves and clouds: none has a
-- light or particle spec, so nothing turns the leaves off, and the ambience layers exist (two leaf layers
-- and two clouds). Settings > Images > Image effects decides whether they play.
do
    local A = F.ambience
    assert(A and #A.layers == 4, "the goal page has its leaf and cloud layers")
    local steady = 0
    for _, l in ipairs(A.layers) do if l.steady then steady = steady + 1 end end
    assert(steady == 2, "two cloud layers, two leaf layers")
    local ids = {
        "bonereavers_edge", "deathbringer", "flame_wrath", "frostguard", "gift_of_the_elven_magi",
        "glacial_blade", "gutgore_ripper", "halberd_of_smiting", "illusionary_rod", "inventors_focal_sword",
        "jindos_judgement", "krol_blade", "mograines_might", "obsidian_edged_blade", "headmasters_charge",
        "aurastone_hammer", "lava_dredger", "will_of_arlokk", "mandokirs_sting", "perditions_blade",
    }
    local originalContext, originalGoal = B.PlayerArtContext, B.goal
    B.PlayerArtContext = function() return {faction="Horde", class="WARRIOR", race="Orc"} end
    for _, id in ipairs(ids) do
        local goal = F.GoalById(id)
        assert(goal, id .. " is a goal")
        local path, aspect, preprocessed = B:ResolveArt(id)
        assert(path == id .. "-banner.blp" and aspect == 4/3 and preprocessed, id .. " resolves to its own banner")
        B.goal = goal
        local spec = B:GlowSpec()
        assert(not (spec and spec.embers and not spec.dust), id .. " has no particles that would hide the drifting leaves")
    end
    B.PlayerArtContext, B.goal = originalContext, originalGoal
    print("  weapon backgrounds: twenty banners resolve and keep the drifting leaves and clouds ok")
end

-- Sex-specific artwork must not leak across characters or override another race.
do
    local variants = B.artVariants.allclasses
    for sex, suffix in pairs({[2]="male", [3]="female"}) do
        local pick = B:BestArtVariant(variants, {faction="Alliance", class="WARRIOR", race="NightElf", sex=sex})
        assert(pick and pick.path == "allclasses_nightelf_warrior_" .. suffix .. "-banner.blp", "Night Elf Warrior sex-specific banner")
    end
    local dwarf = B:BestArtVariant(variants, {faction="Alliance", class="WARRIOR", race="Dwarf", sex=3})
    assert(dwarf and dwarf.path == "allclasses_dwarf_warrior-banner.blp", "Night Elf sex variants preserve Dwarf artwork")
    local unknown = B:BestArtVariant(variants, {faction="Alliance", class="WARRIOR", race="NightElf"})
    assert(unknown and not unknown.sex, "missing saved sex keeps shared fallback")
end
