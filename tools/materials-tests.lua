local F, D = STUB_NS, ForeverGoalTrackerDB
local function Find(rows,id)
    for _,row in ipairs(rows) do if row.id==id then return row end end
end
local goal = {id="materials_test", steps={
    {text="Gather 10 Sample Bars.",auto={item=12360,count=10}},
    {text="Gather 20 Sample Bars.",auto={item=12360,count=20}},
    {text="Loot a weapon.",auto={item=999}},
}}
local current = F.MaterialsUI.charKey()
D.characters = {[current]={race="Human",faction="Alliance",items={[12360]=5}}, Alt={race="Orc",faction="Horde",items={[12360]=7}}}
D.progress[goal.id]={}
local progress = STUB_SERIALIZE(D.progress)
local row = Find(F.MaterialRows(goal,true),12360)
assert(row.need==20 and row.have==12 and row.percent==60,"same stock uses largest milestone")
assert(#F.MaterialRows(goal,true)==1,"single loot reward is not a reagent")
assert(Find(F.MaterialRows(goal,false),12360).have==5,"current character filter")
goal.steps[1].auto.forFaction="Alliance"
goal.steps[2].auto.forFaction="Alliance"
assert(Find(F.MaterialRows(goal,true),12360).have==5,"faction scopes respected")
goal.steps[1].auto.forFaction=nil; goal.steps[2].auto.forFaction=nil
assert(STUB_SERIALIZE(D.progress)==progress,"collecting panel data does not tick anything")
D.progress[goal.id][2]=true
D.characters[current].items={}; D.characters.Alt.items={}
assert(Find(F.MaterialRows(goal,true),12360).have==20,"historical completed milestone stays collected")

local recipe = {id="materials_recipe",group=true,sections={
    {pieces={
        {materials={},requiredItems={{item=12360,count=3}}},
        {materials={},requiredItems={{item=12360,count=4}}},
    }},
    {pieces={{materials={},requiredItems={{item=12360,count=100}}}}},
}}
D.activeParts[recipe.id]={[1]=true}; D.progress[recipe.id]={}
D.characters[current].items={[12360]=2}
row=Find(F.MaterialRows(recipe,true),12360)
assert(row.need==7 and row.have==2,"selected recipe pieces add their quantities")
D.progress[recipe.id]["1_1_piece"]=true
row=Find(F.MaterialRows(recipe,true),12360)
assert(row.need==7 and row.have==5,"completed turn-in credited alongside remaining stock")
local manual={id="materials_manual",sections={{pieces={{materials={"3 Arcanite Bars","Unknown reagent from a boss"}}}}}}
D.progress[manual.id]={}
local oldInfo=F.ItemInfo
F.ItemInfo=function(id)
    if id=="Unknown reagent" then return nil end
    return oldInfo(id)
end
local manualRows=F.MaterialRows(manual,true)
row=Find(manualRows,12360)
assert(row and row.need==3,"manual material name resolves from existing item metadata")
local unknown
for _,entry in ipairs(manualRows) do if not entry.id then unknown=entry end end
assert(unknown and unknown.unknown,"unresolved item never presented as a verified zero count")
D.progress[manual.id]["1_1_m1"]=true
assert(Find(F.MaterialRows(manual,true),12360).have==3,"manual collection tick retained")
manual.sections[1].pieces[2]={materials={"4 Arcanite Bars"}}
D.characters[current].items={[12360]=3}
assert(Find(F.MaterialRows(manual,true),12360).have==3,"collected tick does not double-count stock still held")
D.progress[manual.id]["1_1_piece"]=true
assert(Find(F.MaterialRows(manual,true),12360).have==6,"owned piece proves its ingredients were consumed")
F.ItemInfo=oldInfo

local M,U=F.materialsPanel,F.MaterialsUI
assert(not M.open and M.fraction==0,"collapsed on fresh load")
local oldMainWidth,oldListWidth=U.main.GetWidth,U.list.GetWidth
local width=1000
U.main.GetWidth=function() return width end
U.list.GetWidth=function() return 300 end
D.active={sulfuras=true}; D.progress.sulfuras={}; F.SelectGoal("sulfuras")
local oldMotion=F.Setting("celebrations")
local oldPoint, oldGradient, oldContentAlpha = M.frame.SetPoint, U.gradient, M.scroll.scroll.SetAlpha
local leftAnchors, shade, contentAlpha = 0, nil, nil
M.scroll.scroll.SetAlpha=function(self,alpha) contentAlpha=alpha; oldContentAlpha(self,alpha) end
M.frame.SetPoint=function(self,point,...)
    assert(point=="TOPLEFT" or point=="BOTTOMLEFT","drawer travels from the outer right edge")
    leftAnchors=leftAnchors+1; oldPoint(self,point,...)
end
U.gradient=function(texture,left,right,a,b)
    if texture==M.edgeShade then shade=b/0.65 end
    oldGradient(texture,left,right,a,b)
end
F.SetSetting("celebrations","full")
M:Place()
local before=STUB_SERIALIZE(D.progress)
M:SetOpen(true)
local step=M.driver:GetScript("OnUpdate")
assert(step,"animation is active only during the transition")
step(M.driver,0.1)
assert(M.fraction>0 and M.fraction<1,"intermediate glide")
assert(contentAlpha==M.fraction,"contents fade in with opening")
assert(shade>0 and shade<1 and leftAnchors>0,"outer-edge shade fades during travel")
step(M.driver,0.2)
assert(M.fraction==1 and M.span==M.width and M.width==280 and not M.driver:GetScript("OnUpdate"),"glide finishes and removes update handler")
assert(shade==0,"open drawer has no tuck shadow")
assert(contentAlpha==1,"open contents are fully visible")
M:SetOpen(false)
local closing=M.driver:GetScript("OnUpdate")
closing(M.driver,0.1)
assert(contentAlpha>0 and contentAlpha<1,"contents fade out with closing")
closing(M.driver,0.2)
assert(M.fraction==0 and M.span==22,"closed drawer preserves its visible sliver")
assert(shade==1,"closed sliver carries the outer-edge shadow")
assert(contentAlpha==0,"closed sliver has no visible contents")
F.SetSetting("celebrations","off"); M:SetOpen(true)
assert(M.fraction==1,"motion-off opens immediately")
width=520; M:Place()
assert(not M.canOpen and not M.open and M.span==22,"narrow window preserves guide space")
assert(STUB_SERIALIZE(D.progress)==before,"open/close/resize never changes saved progress")
-- Removing the last goal restores the full empty guide; a grouped goal
-- selected through activeParts still has a drawer.
D.active={}; F.RefreshMaterials(); M:Place()
assert(M.span==0 and not M.open,"empty tracker has no hidden drawer footprint")
local mounts=F.GoalById("epic_racial_mounts")
-- Use a real grouped goal without assuming its historic catalogue ID.
for _,candidate in ipairs(F.goals) do if candidate.group and candidate.steps then mounts=candidate; break end end
if mounts then
    D.activeParts[mounts.id]={[1]=true}; F.SelectGoal(mounts.id)
    assert(U.goal() and U.goal().id==mounts.id,"grouped selection is recognized")
end
F.SetSetting("celebrations",oldMotion)
U.main.GetWidth,U.list.GetWidth=oldMainWidth,oldListWidth
M.frame.SetPoint,U.gradient=oldPoint,oldGradient
M.scroll.scroll.SetAlpha=oldContentAlpha
-- Pooled guide rows hide item bars after reuse, while gold bars still show.
local barMethods={}
for _,stepRow in ipairs(F.stepRows) do
    local bar=stepRow.miniBar
    barMethods[bar]={bar.Show,bar.Hide}
    bar.Show=function(self) self.testShown=true; barMethods[self][1](self) end
    bar.Hide=function(self) self.testShown=false; barMethods[self][2](self) end
end
D.active={sulfuras=true,gold_5k=true}; D.progress.sulfuras={}; D.progress.gold_5k={}
F.SelectGoal("sulfuras")
local collections=0
for _,stepRow in ipairs(F.stepRows) do
    local rule=stepRow.ruleEntry
    if rule and rule.item and rule.count and rule.count>1 then
        assert(not stepRow.miniBar.testShown,"collection step has no duplicate bar")
        collections=collections+1
    end
end
assert(collections>0,"collection fixture reached real guide rows")
F.SelectGoal("gold_5k")
local goldBar=false
for _,stepRow in ipairs(F.stepRows) do
    if stepRow.ruleEntry and stepRow.ruleEntry.money then goldBar=stepRow.miniBar.testShown end
end
assert(goldBar,"gold progress bar retained")
for bar,methods in pairs(barMethods) do bar.Show,bar.Hide=methods[1],methods[2] end
print("  per-goal stock, recipe sums, historical credit, scopes, alts, unknown items, slide lifecycle and narrow bounds pass")

-- A goal with a real shopping list slides the drawer open once, the first
-- time it is viewed. Goals with little or nothing to collect never do.
do
    width=1000; U.main.GetWidth=function() return width end
    local oldShown=U.main.IsShown; U.main.IsShown=function() return true end
    local oldAfter=C_Timer.After; C_Timer.After=function(_,fn) fn() end
    F.SetSetting("celebrations","off")
    M.open=false; M.fraction=0; D.materialsSeen=nil
    D.active={gold_5k=true,tier3_warrior=true}; D.progress.tier3_warrior=D.progress.tier3_warrior or {}
    F.SelectGoal("gold_5k")
    assert(not M.open,"a goal without a shopping list stays closed")
    -- A mid-size list bounces instead of opening, once.
    F.SetSetting("celebrations","full"); D.active.sulfuras=true; D.progress.sulfuras=D.progress.sulfuras or {}
    F.SelectGoal("sulfuras")
    local boop=M.driver:GetScript("OnUpdate")
    assert(boop and not M.open,"mid-size list bounces without opening")
    boop(M.driver,0.1); assert(M.bounce>0 and M.span>22,"bounce peeks out")
    boop(M.driver,10)
    assert(M.bounce==0 and M.span==22 and not M.open and not M.driver:GetScript("OnUpdate"),"bounce settles closed")
    F.SelectGoal("gold_5k"); F.SelectGoal("sulfuras")
    assert(not M.driver:GetScript("OnUpdate"),"bounce plays once per goal")
    F.SetSetting("celebrations","off")
    F.SelectGoal("tier3_warrior")
    assert(M.open and D.materialsSeen and D.materialsSeen.tier3_warrior,"recipe goal opens on first view rows="..#(M.data or {}).." can="..tostring(M.canOpen).." shown="..tostring(U.main:IsShown()).." goal="..tostring(M.goalId))
    M:SetOpen(false); F.SelectGoal("gold_5k"); F.SelectGoal("tier3_warrior")
    assert(not M.open,"later views do not reopen it")
    C_Timer.After=oldAfter; U.main.IsShown=oldShown
end

-- Recipe rows group into crafting materials, then tokens; single items
-- show a count instead of a percentage.
do
    local rows = F.MaterialRows(F.GoalById("tier3_warrior"), true)
    local lastGroup, order = 0, true
    local sawCrafting, sawToken = false, false
    for _, r in ipairs(rows) do
        assert(r.group, "every Tier 3 row has a group: " .. r.name)
        if r.group < lastGroup then order = false end
        lastGroup = r.group
        sawCrafting = sawCrafting or r.group == 1
        sawToken = sawToken or r.group == 2
    end
    assert(order and sawCrafting and sawToken, "crafting materials come before tokens")
    F.SelectGoal("tier3_warrior")
    local labels = {}
    for i = 1, #M.data do
        local row = M.rows[i]
        if row and row.groupLabel then labels[#labels + 1] = row.groupLabel end
    end
    assert(#labels == 2 and labels[1] == "Crafting materials" and labels[2] == "Tokens", "two group headers on Tier 3")
    local single
    for _, row in ipairs(M.rows) do
        if row.entry and row.entry.need == 1 then single = row end
    end
    assert(single and single.percent:GetText():match("/ 1$"), "rows show have / need counts")
end

-- Everything gathered or crafted without a special group is a crafting
-- material, so Sulfuras and Thunderfury show no stray "Other" heading.
do
    for _, id in ipairs({"sulfuras","thunderfury"}) do
        for _, r in ipairs(F.MaterialRows(F.GoalById(id), true)) do
            assert(r.group == 1, id .. " row " .. r.name .. " is a crafting material")
        end
    end
    assert(F.Setting("materialsBars") == true, "progress bars show by default")
end

-- What's new: glows until opened, marks the newest release seen, replays on reset.
do
    local N = F.WhatsNew
    assert(N and F.WHATS_NEW[1].version, "what's new module loaded")
    D.whatsNewSeen = nil; N.RefreshButton()
    assert(N.button:GetScript("OnUpdate") or F.Setting("celebrations") == "off", "unseen release pulses")
    F.SetSetting("celebrations", "off")
    N.Command()
    assert(N.open and D.whatsNewSeen == F.WHATS_NEW[1].version, "opening marks the newest release seen")
    assert(not N.button:GetScript("OnUpdate"), "glow stops once seen")
    N.Close()
    assert(not N.open, "closes")
    N.Command("reset")
    assert(D.whatsNewSeen == nil, "reset glows again")
end

-- Library filter column and the My Goals view (class/race/faction fit).
do
    local LF = F.libState
    local druid = { class = "DRUID", race = "NightElf", faction = "Alliance" }
    assert(F.GoalFits(F.GoalById("sulfuras"), druid), "Druids wield two-handed maces")
    assert(not F.GoalFits(F.GoalById("thunderfury"), druid), "Druids can't use one-handed swords")
    assert(not F.GoalFits(F.GoalById("mount_dreadsteed"), druid), "Dreadsteed is Warlock only")
    assert(F.GoalFits(F.GoalById("rep_argentdawn"), druid), "reputations are for everyone")
    assert(not F.GoalFits(F.GoalById("pvp_mount_horde"), druid), "Horde goals don't fit an Alliance character")
    assert(F.GoalFits(F.GoalById("tier3_druid"), druid) and not F.GoalFits(F.GoalById("tier3_mage"), druid), "armor goals follow their class")
    assert(F.GoalFits(F.GoalById("tier3"), { class = "DRUID" }), "collections fit when a class version exists")
    assert(not F.GoalFits(F.GoalById("wolfsbane"), { class = "PALADIN", race = "Human", faction = "Horde" }), "Wolfsbane is for Undead Paladins")

    -- Library: For a class narrows the cards and the category counts.
    D.active = {}; F.ShowTab("library")
    local function Count(key)
        for _, o in ipairs(LF.catDrop.options) do if o.key == key then return o.count end end
    end
    local allWeapons = Count("Epic Weapon")
    LF.forWho = "DRUID"; F.LayoutLibrary()
    assert(Count("Epic Weapon") < allWeapons, "Druid sees fewer weapons")
    LF.forWho = "any"; F.LayoutLibrary()
    local everything = Count("all")
    LF.show = "added"; F.LayoutLibrary()
    local added = Count("all")
    LF.show = "notadded"; F.LayoutLibrary()
    assert(added + Count("all") == everything and added < everything, "Added and Not added split the library")
    LF.Reset(); F.LayoutLibrary()
    assert(Count("all") > 60 and not LF.Active(), "reset clears every filter " .. tostring(Count("all")) .. " " .. tostring(LF.Active()))
    F.SetLibraryView("new")
    assert(LF.newOnly and LF.show == "all", "demo 'new' chip maps to the New & Updated toggle")
    LF.Reset()

    -- My Goals: This character hides goals the logged-in character can't do.
    D.active = { thunderfury = true, mount_dreadsteed = true, rep_argentdawn = true }
    F.ShowTab("tracker")
    local view = F.myGoalsView
    view:SetValue("me")
    local me = F.PlayerProfile()
    assert(me.class == "WARRIOR", "stub character is a Warrior")
    assert(F.MyGoalsShows(F.GoalById("thunderfury")) and not F.MyGoalsShows(F.GoalById("mount_dreadsteed")), "This character view")
    view:SetValue("all")
    assert(F.MyGoalsShows(F.GoalById("mount_dreadsteed")), "All goals view")
end

-- Filters that hide a search match say so, and one click shows it.
do
    local LF = F.libState
    F.ShowTab("library")
    LF.Reset()
    F.searchBox:SetText("Thunderfury"); F.libSearch = "thunderfury"
    LF.forWho = "PRIEST"; LF.forDrop:SetValue("PRIEST")
    F.LayoutLibrary()
    local tags = LF.ActiveTags()
    assert(#tags == 2 and tags[2][1] == "Priest", "one tag per active filter (search, For)")
    local text = LF.more:GetText() or ""
    assert(text:find("Thunderfury") and text:find("For: Priest"), "names the filter that hides the match: " .. text)
    LF.moreBtn:GetScript("OnClick")(LF.moreBtn)
    assert(LF.forWho == "any" and F.libSearch == "thunderfury", "Show it clears filters but keeps the search")
    -- removing a tag clears just that filter
    LF.show = "added"; F.LayoutLibrary()
    local before = #LF.ActiveTags()
    LF.tags[2].clear(); F.LayoutLibrary()
    assert(#LF.ActiveTags() == before - 1 and LF.show == "all", "a tag's X removes its filter")
    LF.Reset(); F.LayoutLibrary()
    assert(#LF.ActiveTags() == 0, "reset clears every tag")
end

-- With a class picked, armor collections become that class's own sets.
do
    local LF = F.libState
    F.ShowTab("library"); LF.Reset()
    local function Ids()
        local ids = {}
        for _, g in ipairs(LF.Results({ key = "Item Set" })) do ids[g.id] = true end
        return ids
    end
    local any = Ids()
    assert(any.tier3 and not any.tier3_rogue, "Anyone keeps the collections")
    LF.forWho = "ROGUE"; LF.forDrop:SetValue("ROGUE")
    local rogue = Ids()
    assert(rogue.tier3_rogue and rogue.set_tier1_rogue and not rogue.tier3 and not rogue.tier3_mage, "a class sees its own sets")
    local list = LF.Results({ key = "Item Set" })
    assert(LF.Tier(list[1]) <= LF.Tier(list[#list]), "sets sort as a progression")
    F.LayoutLibrary()
    assert(F.libCards.tier3_rogue and F.libCards.tier3_rogue:IsShown() ~= nil, "individual set cards are built")
    LF.Reset()
end

-- My character pulls their race's epic mount out of Epic Racial Mounts.
do
    local LF = F.libState
    F.ShowTab("library"); LF.Reset()
    local mounts = { key = "Mount", match = "^Mount" }
    local function Find(list, id) for _, g in ipairs(list) do if g.id == id then return g end end end
    assert(Find(LF.Results(mounts), "epicmounts"), "Anyone keeps Epic Racial Mounts whole")
    LF.forWho = "me"; LF.forDrop:SetValue("me")
    local list = LF.Results(mounts)
    local part = Find(list, "epicmounts#1")
    assert(part and not Find(list, "epicmounts") and part.name == "Swift Steed", "a Human sees the Swift Steed on its own")
    D.activeParts.epicmounts = {}
    F.LayoutLibrary()
    local card = F.libCards[part.id]
    card:GetScript("OnEnter")(card) -- hovering a part card (crashed: no steps)
    card:GetScript("OnLeave")(card)
    card.btn:GetScript("OnClick")(card.btn)
    assert(F.PartSelected(F.GoalById("epicmounts"), 1) and LF.On(part), "adding the card picks that part")
    card.btn:GetScript("OnClick")(card.btn)
    assert(not F.PartSelected(F.GoalById("epicmounts"), 1), "and removing it unpicks it")
    LF.forWho = "WARRIOR"; LF.forDrop:SetValue("WARRIOR")
    assert(Find(LF.Results(mounts), "epicmounts"), "a class alone (no race) keeps the group")
    LF.Reset()
end

-- My character brings your faction; Sort and Add all.
do
    local LF = F.libState
    F.ShowTab("library"); LF.Reset()
    LF.SetFor("me")
    assert(LF.faction == "Alliance", "My character picks your faction")
    local factionTag = false
    for _, t in ipairs(LF.ActiveTags()) do if t[1] == "Alliance" then factionTag = true end end
    assert(factionTag, "the faction shows as its own tag")
    LF.SetFor("any")
    assert(LF.faction == nil, "leaving My character gives the faction back")
    LF.SetFor("me"); LF.faction = "Horde"; LF.SetFor("any")
    assert(LF.faction == "Horde", "a faction you changed yourself stays")
    LF.Reset()

    LF.sort = "difficulty"; F.LayoutLibrary()
    assert(#LF.shown > 0, "sorted results")
    LF.sort = "alpha"; LF.sortDrop:SetValue("alpha")

    -- Progression: sets in the order you'd get them, other goals after
    LF.sort = "progression"; LF.show = "all"; F.LayoutLibrary()
    local lastRank = -1
    for _, g in ipairs(LF.shown) do
        local r = F.SetOrder(g)
        assert(r >= lastRank, "Progression order holds at " .. g.id)
        lastRank = r
    end
    assert(F.SetOrder({ id = "set_tier1" }) < F.SetOrder({ id = "set_tier2" }), "Tier 1 before Tier 2")
    assert(F.SetOrder({ id = "set_dungeon1" }) < F.SetOrder({ id = "set_tier1" }), "Dungeon Set 1 before Tier 1")
    assert(F.SetOrder({ id = "gold_5k" }) == 100, "non-sets come after the sets")
    LF.sort = "alpha"; LF.sortDrop:SetValue("alpha")

    -- My Goals search narrows the list and clears
    F.listSearch:SetText("zzzz-nothing")
    F.listSearch:SetText("")
    assert(F.listQuery == "", "search clears")

    D.active = {}; D.activeParts = {}
    F.searchBox:SetText("onyxia"); F.libSearch = "onyxia"
    F.LayoutLibrary()
    local missing = #LF.Missing()
    assert(missing > 0, "something to add")
    LF.addAll.onChange("cancel")
    assert(#LF.Missing() == missing, "Cancel adds nothing")
    local layouts, layout = 0, LF.Layout
    LF.Layout = function(...) layouts = layouts + 1; return layout(...) end
    LF.addAll.onChange("add")
    LF.Layout = layout
    assert(layouts <= 1, "Add all redraws the Library once, not once per goal (" .. layouts .. ")")
    assert(#LF.Missing() == 0, "Add all adds everything listed")
    assert(LF.addMode == "remove", "then the button offers Remove all")
    LF.addAll.onChange("remove")
    assert(#LF.Added() == 0, "Remove all removes everything listed")
    LF.Reset(); D.active = {}; D.activeParts = {}
end

-- the My Goals search box hides with Sort on the empty tracker (the stub
-- doesn't track visibility, so record the calls)
do
    local box, seen = STUB_NS.listSearch, {}
    rawset(box, "Hide", function() seen[#seen + 1] = "hide" end)
    rawset(box, "Show", function() seen[#seen + 1] = "show" end)
    box:SetText("atiesh")
    STUB_NS.ShowEmptyTracker()
    assert(seen[#seen] == "hide", "no search box on the empty tracker")
    assert(STUB_NS.listQuery == "", "the empty tracker clears the search")
end

-- Thunderfury's gem glows: the banner places it from the artwork's own coordinates
do
    local B = STUB_NS.goalBanner
    B.goal = STUB_NS.GoalById("thunderfury")
    B.hasArt = true
    B.sourceAspect = 4/3
    B:Fit()
    assert(B.uv and B.shownArtHeight, "banner measured its artwork")
    B.goal = STUB_NS.GoalById("atiesh")
    B:PlaceGlow()
    assert(B.glows.thunderfury and B.glows.ashbringer and B.glows.rep_argentdawn.rays and B.glows["benediction-alliance-banner.blp"].rays and B.glows["set_tier2_paladin-banner.blp"].rays and not B.glows.atiesh, "only goals with a glow spec get one")
end

-- Sulfuras embers rise and stay inside the art
do
    local B = STUB_NS.goalBanner
    B.goal = STUB_NS.GoalById("sulfuras")
    B.hasArt = true
    B.sourceAspect = 4/3
    B:Fit()
    -- the stub has no real sizes: give the art one, then place the lights
    rawset(B.art, "GetWidth", function() return 600 end)
    B.shownArtHeight, B.uv = 450, { 0.4, 1, 0, 1 }
    B:PlaceGlow()
    assert(B.glowSpec and B.glowSpec.embers, "Sulfuras has embers")
    assert(#B.emberDots == 0 or not B.emberDots[1].tex:IsShown(), "no embers with Celebrations off")
    local cel = STUB_NS.Setting("celebrations")
    STUB_NS.SetSetting("celebrations", "full")
    B:PlaceGlow()
    for _ = 1, 50 do B:StepEmbers(0.1) end
    assert(B.emberCount == B.glowSpec.embers.count, "one dot per ember")
    local before = B.emberFor
    B:PlaceGlow()
    assert(B.emberFor == before, "a re-layout keeps the embers in flight")
    STUB_NS.SetSetting("celebrations", cel)
    STUB_NS.SetSetting("imageEffects", false)
    B:PlaceGlow()
    assert(B.emberFor == nil, "Image effects off stops the embers")
    STUB_NS.SetSetting("imageEffects", true)
    B:PlaceGlow()
    assert(B.emberFor ~= nil, "Image effects on starts them again")
    -- the Settings page lists it under Images, and Effects is renamed
    local titles = {}
    for _, g in ipairs(STUB_NS.SETTINGS) do titles[g.title] = g end
    assert(titles["Images"] and titles["Celebrations and sound"] and not titles["Effects"], "settings groups")
    assert(titles["Images"].rows[1].key == "tallGoalArt" and titles["Images"].rows[2].key == "imageEffects", "Images rows")
    assert(STUB_NS.SETTING_DEFAULTS.imageEffects == true, "Image effects on by default")
end

-- every ember banner Karl picked resolves to embers (by image or by goal)
do
    local B = STUB_NS.goalBanner
    for _, id in ipairs({ "att_bwl", "raid_bwl", "mount_dreadsteed", "pvp_duelist", "pvp_hk", "set_tier1_shaman",
            "tier3_shaman", "att_mc", "raid_mc", "att_naxx", "raid_ony", "key_strat", "wolfsbane", "set_dungeon1_priest", "key_ubrs", "frostsaber", "rep_timbermaw", "pvp_av_horde", "tier3_mage", "pvp_mount_ally", "pvp_avmount_ally", "pvp_avmount_horde", "set_tier1_hunter", "pvp_av_ally", "pvp_set_mail_horde_shaman" }) do
        B.goal = STUB_NS.GoalById(id)
        assert(B.goal, "goal exists: " .. id)
        local spec = B:GlowSpec()
        assert(spec and spec.embers, "embers on " .. id)
        -- and they actually start (not just exist), with Celebrations on
        local cel = STUB_NS.Setting("celebrations")
        STUB_NS.SetSetting("celebrations", "full")
        B.hasArt = true
        rawset(B.art, "GetWidth", function() return 600 end)
        B.shownArtHeight, B.uv, B.emberFor = 450, { 0, 1, 0, 1 }, nil
        B:PlaceGlow()
        assert(B.emberFor == spec, "embers start on " .. id)
        STUB_NS.SetSetting("celebrations", cel)
    end
end

-- Cooking carries two particle sets (fire and snow); both start
do
    local B = STUB_NS.goalBanner
    local spec = B.glows["prof_cooking-banner.blp"]
    assert(#B.ParticleSets(spec) == 1 and spec.embers.fall and spec.glow ~= false, "cooking: snow and a flame glow, no embers")
    local cel = STUB_NS.Setting("celebrations")
    STUB_NS.SetSetting("celebrations", "full")
    B.glowSpec, B.glowLevel = spec, 0.5
    B.hasArt = true
    rawset(B.art, "GetWidth", function() return 600 end)
    B.shownArtHeight, B.uv = 450, { 0, 1, 0, 1 }
    B:ResetEmbers()
    assert(B.emberCount == 90, "90 flakes")
    for _ = 1, 30 do B:StepEmbers(0.2) end
    STUB_NS.SetSetting("celebrations", cel)
    B:HideEmbers()
end

-- a beam (Priest Tier 3) and sunrays (Judgement) start with their motes, and animate
do
    local B = STUB_NS.goalBanner
    rawset(B.art, "GetWidth", function() return 600 end)
    for _, case in ipairs({ { "tier3_priest", 1 }, { "set_tier2_paladin", 5 } }) do
        B.goal = STUB_NS.GoalById(case[1])
        B.hasArt, B.shownArtHeight, B.uv, B.emberFor = true, 450, { 0, 1, 0, 1 }, nil
        local spec = B:GlowSpec()
        assert(spec and (spec.beam or spec.sunrays), "light shafts on " .. case[1])
        B.glowSpec = spec
        B.glowLevel = 0.5
        B:ResetShafts()
        assert(B.shaftCount == case[2], "shaft count on " .. case[1])
        for k = 1, 20 do B:StepShafts(k*0.25) end
        B:ResetEmbers()
        assert(B.emberCount > 0, "motes on " .. case[1])
        for _ = 1, 20 do B:StepEmbers(0.25) end
        B:HideShafts(); B:HideEmbers()
    end
end

-- Karl's light list: every one resolves to a light and starts
do
    local B = STUB_NS.goalBanner
    rawset(B.art, "GetWidth", function() return 600 end)
    for _, id in ipairs({ "rep_ambassador_ally", "rep_ambassador_horde", "mount_charger", "fishing_extravaganza",
            "set_tier1_paladin", "lokdelar", "set_dungeon1_paladin", "att_ony_ally", "att_ony_horde", "rep_argentdawn",
            "set_forever_raid_warrior", "set_forever_raid_paladin", "set_forever_raid_priest", "set_forever_raid_rogue",
            "set_forever_raid_mage", "set_forever_raid_warlock", "set_forever_raid_druid",
            "rhokdelar", "gold_5k", "key_scholo", "set_dungeon1_warrior", "set_violet_sorcerer",
            "set_forever_raid_shaman", "set_forever_raid_hunter" }) do
        B.goal = STUB_NS.GoalById(id)
        assert(B.goal, "goal exists: " .. id)
        B.hasArt, B.shownArtHeight, B.uv, B.emberFor = true, 450, { 0, 1, 0, 1 }, nil
        local spec = B:GlowSpec()
        assert(spec, "light on " .. id)
        B:PlaceGlow()
        assert(B.glowSpec == spec, "light starts on " .. id)
        if spec.sunrays or spec.beam then assert((B.shaftCount or 0) > 0, "shafts on " .. id) end
        for k = 1, 5 do B:StepShafts(k*0.3); B:StepEmbers(0.3) end
        B:HideShafts(); B:HideEmbers(); B.emberFor = nil
    end
end

-- sunlight banners carry the wide layer (3 more shafts); Save Gold has coin glints
do
    local B = STUB_NS.goalBanner
    rawset(B.art, "GetWidth", function() return 600 end)
    B.hasArt, B.shownArtHeight, B.uv, B.glowLevel = true, 450, { 0, 1, 0, 1 }, 0.5
    B.goal = STUB_NS.GoalById("mount_charger"); B.glowSpec = B:GlowSpec(); B:ResetShafts()
    assert(B.shaftCount == 7 + 3, "charger: seven streaks and the wide layer")
    B.goal = STUB_NS.GoalById("gold_5k"); B.glowSpec = B:GlowSpec(); B:ResetShafts()
    assert(B.shaftCount == 1 + 7, "gold: a beam and seven glints")
    for k = 1, 40 do B:StepShafts(k*0.2) end
    B:HideShafts()
end
