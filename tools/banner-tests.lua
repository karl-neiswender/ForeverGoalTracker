local F, D = STUB_NS, ForeverGoalTrackerDB
local B = F.goalBanner
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
    assert(B:ArtPath("set_tier1_priest")=="set_tier1_priest-banner.blp", "Priest Tier 1 uses approved portrait for "..faction)
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
    assert(B:ArtPath("allclasses")=="rhokdelar-banner.blp", "dwarf hunter gets available Alliance hunter art despite mage-only selection")
    assert(B.hasArt and B.sourceAspect==4/3 and not desaturated)
    assert(B:ArtPath("epicmounts")=="epicmounts_dwarf-banner.blp", "logged-in dwarf favors ram over selected mounts")
    assert(B:ArtPath("pvp_hk")=="pvp_drums_of_war-banner.blp", "Alliance kills use shared Drums of War")
    assert(B:ArtPath("pvp_duelist")=="pvp_drums_of_war-banner.blp", "Alliance duels use shared Drums of War")
    assert(B:ArtPath("pvp_rank14_ally")=="set_tier2_warrior-alliance-banner.blp", "Alliance rank retains existing faction art")
    assert(B:ArtPath("pvp_mount_ally")=="pvp_mount_ally-banner.blp" and B:ArtPath("pvp_avmount_ally")=="pvp_mount_ally-banner.blp", "both Alliance PvP mounts use flipped ram")
    race = "NightElf"
    assert(B:ArtPath("allclasses")=="allclasses_nightelf_hunter-banner.blp", "Night Elf Hunter uses new leveling art")
    assert(B:ArtPath("tier3_warlock")=="tier3_warlock-alliance-banner.blp")
    assert(B:ArtPath("pvp_set_mail_horde_hunter")=="pvp_set_mail_horde-banner.blp", "Alliance player sees Warlord mail art on Horde Hunter set")
    assert(B:ArtPath("pvp_set_mail_horde_shaman")=="pvp_set_mail_horde-banner.blp", "Horde Shaman set inherits dedicated mail art")
    assert(B:ArtPath("pvp_rank14_horde")=="set_tier2_warrior-banner.blp", "Horde PvP goal ignores player's Alliance faction")
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
    assert(B:ArtPath("allclasses")=="pvp_shared-banner.blp", "human and dwarf priest leveling portraits remain race-specific")
    race, class, faction = "Troll", "MAGE", "Horde"
    assert(B:ArtPath("epicmounts")=="epicmounts_troll-banner.blp")
    assert(B:ArtPath("pvp_hk")=="pvp_drums_of_war-banner.blp")
    assert(B:ArtPath("pvp_duelist")=="pvp_drums_of_war-banner.blp")
    assert(B:ArtPath("pvp_rank14_horde")=="set_tier2_warrior-banner.blp", "Horde rank retains existing faction art")
    assert(B:ArtPath("pvp_rank14_ally")=="set_tier2_warrior-alliance-banner.blp", "Alliance PvP goal ignores player's Horde faction")
    class = "HUNTER"
    assert(B:ArtPath("allclasses")=="tier3_hunter-banner.blp", "Troll Hunter leveling uses Cryptstalker and white lion artwork")
    race = "Orc"
    assert(B:ArtPath("allclasses")=="allclasses_horde_hunter-banner.blp", "Horde Hunter uses new leveling art")
    assert(B:ArtPath("tier3_druid")=="tier3_druid-horde-banner.blp")
    assert(B:ArtPath("tier3_warlock")=="tier3_warlock-banner.blp", "Horde Warlock retains existing artwork")
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
    assert(B:ArtPath("allclasses")=="tier3_warrior-banner.blp", "available dwarf warrior is more specific than Alliance warrior")
    race = "Skyborne"
    assert(B:ArtPath("epicmounts")=="epicmounts_skyborne-banner.blp", "Skyborne gets approved island location")
    race = "UnknownRace"
    D.activeParts.epicmounts = {[2]=true}
    assert(B:ArtPath("epicmounts")=="epicmounts_dwarf-banner.blp", "missing race art can use sole same-faction selected mount")
    D.activeParts.epicmounts = {[8]=true}
    assert(B:ArtPath("epicmounts")=="epicmounts_human-banner.blp", "opposite faction selection cannot override faction fallback")
    race = "Gnome"
    assert(B:ArtPath("epicmounts")=="epicmounts_gnome-banner.blp", "Gnome gets approved mechanostrider even with other mounts selected")
    UnitRace, UnitClass, UnitFactionGroup = nil, nil, nil
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
assert(desaturated, "switching to older Charger artwork restores its existing monochrome look")
F.SelectGoal("raid_bwl")
assert(not desaturated, "switching back clears desaturation")
D.active.gold_5k = true
F.SelectGoal("gold_5k")
assert(B.hasArt and B:ArtPath("gold_5k")=="gold_5k-banner.blp" and B.sourceAspect==4/3 and not desaturated, "gold goal uses approved treasure banner")
D.active.social_friends = true
F.SelectGoal("social_friends")
assert(not B.hasArt, "unmapped goal clears previous artwork")
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
