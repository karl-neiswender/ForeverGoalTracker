local ADDON, FGT = ...
local U = FGT.MaterialsUI
local C = U.colors
FGT.SETTING_DEFAULTS.materialsCollected = false
FGT.SETTING_DEFAULTS.materialsCounts = false
FGT.SETTING_DEFAULTS.materialsAlts = true

local function List(v) return type(v) == "table" and v or (v and {v} or {}) end
local function Singular(name) return name:gsub("s$", "") end
local names, labels = {}, {}
local function Tags(text)
    for id, name in (text or ""):gmatch("{item:(%d+):([^}]+)}") do
        names[name] = tonumber(id); labels[tonumber(id)] = name
    end
end
for _, goal in ipairs(FGT.goals) do
    for _, text in ipairs(goal.tips or {}) do Tags(text) end
    for _, step in ipairs(goal.steps or {}) do
        if type(step) == "table" then
            Tags(step.text)
            local rule = step.auto
            local name = (step.text or ""):match("^Gather %d+ (.-)%.$")
                or (step.text or ""):match("^Collect %d+ (.-) from ")
            if name and rule and type(rule.item) == "number" then
                names[Singular(name)] = rule.item; labels[rule.item] = Singular(name)
            end
        end
    end
    for _, section in ipairs(goal.sections or {}) do
        for _, text in ipairs(section.tips or {}) do Tags(text) end
    end
end

-- Tier 3 ingredients are named in text only, and the game can't look an
-- item up by name until it is cached, so those rows showed "?" icons. IDs
-- from Wowhead Classic (checked 2026-10-12).
for id, name in pairs({
    [12360] = "Arcanite Bar", [15407] = "Cured Rugged Hide", [20725] = "Nexus Crystal",
    [14342] = "Mooncloth", [12363] = "Arcane Crystal",
    [22373] = "Wartorn Leather Scrap", [22374] = "Wartorn Chain Scrap",
    [22375] = "Wartorn Plate Scrap", [22376] = "Wartorn Cloth Scrap",
    [22349] = "Desecrated Breastplate", [22350] = "Desecrated Tunic", [22351] = "Desecrated Robe",
    [22352] = "Desecrated Legplates", [22353] = "Desecrated Helmet", [22354] = "Desecrated Pauldrons",
    [22355] = "Desecrated Bracers", [22356] = "Desecrated Waistguard", [22357] = "Desecrated Gauntlets",
    [22358] = "Desecrated Sabatons", [22359] = "Desecrated Legguards", [22360] = "Desecrated Headpiece",
    [22361] = "Desecrated Spaulders", [22362] = "Desecrated Wristguards", [22363] = "Desecrated Girdle",
    [22364] = "Desecrated Handguards", [22365] = "Desecrated Boots", [22366] = "Desecrated Leggings",
    [22367] = "Desecrated Circlet", [22368] = "Desecrated Shoulderpads", [22369] = "Desecrated Bindings",
    [22370] = "Desecrated Belt", [22371] = "Desecrated Gloves", [22372] = "Desecrated Sandals",
}) do
    names[name] = id; labels[id] = name
end

local function Resolve(name)
    if names[name] or names[Singular(name)] then return names[name] or names[Singular(name)] end
    local _, link = FGT.ItemInfo(name)
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if not id then
        _, link = FGT.ItemInfo(Singular(name))
        id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    end
    if id then names[name] = id end
    return id
end

-- Explicit recipe ingredients and countable collection steps only. Tips
-- contribute names/IDs, never quantities. No goal ticks are changed here.
local function Requirements(goal, visit, allParts)
    for i, step in ipairs(goal.steps or {}) do
        local rule = type(step) == "table" and step.auto
        if rule and rule.item and not rule.owned and not rule.ownedPattern
            and ((rule.count or 1) > 1 or (step.text or ""):match("^Gather ")
                or (step.text or ""):match("^Collect "))
            and (allParts or FGT.PartSelected(goal, i)) and not FGT.PieceSkipped(step) then
            visit(List(rule.item), rule.count or 1, i, "max", nil, rule)
        end
    end
    for si, section in ipairs(goal.sections or {}) do
        if allParts or FGT.PartSelected(goal, si) then
            for pi, piece in ipairs(section.pieces or {}) do
                if not FGT.PieceSkipped(piece) then
                    local prefix = si .. "_" .. pi
                    for _, ingredient in ipairs(piece.requiredItems or {}) do
                        visit({ingredient.item}, ingredient.count, prefix .. "_piece", "sum")
                    end
                    for mi, text in ipairs(piece.materials or {}) do
                        local count, name = text:match("^(%d+) (.+)$")
                        name = name or text
                        name = name:match("^(.-) from ") or name
                        local id = Resolve(name)
                        visit(id and {id} or {}, tonumber(count) or 1, prefix .. "_m" .. mi, "sum", name, nil, prefix .. "_piece")
                    end
                end
            end
        end
    end
end

function FGT.CollectMaterialWatch(watch)
    for _, goal in ipairs(FGT.goals) do
        Requirements(goal, function(ids) for _, id in ipairs(ids) do watch[id] = true end end, true)
    end
end

function FGT.MaterialRows(goal, includeAlts)
    local DB = ForeverGoalTrackerDB
    if not goal or not DB then return {} end
    local progress, grouped = (DB.progress or {})[goal.id] or {}, {}
    Requirements(goal, function(ids, count, key, mode, name, rule, spentKey)
        local identity = #ids > 0 and table.concat(ids, ",") or name
        -- Scope is part of the identity so two racial requirements never
        -- borrow stock from a character that cannot meet their rule.
        identity = identity .. ":" .. (rule and rule.forRace or "") .. ":" .. (rule and rule.forFaction or "")
        local row = grouped[identity]
        if not row then
            row = { ids=ids, id=ids[1], name=name, rule=rule, sum=0, paid=0, collected=0, max=0, maxPaid=0 }
            grouped[identity] = row
        end
        if mode == "sum" then
            row.sum = row.sum + count
            if progress[key] then
                row.collected = row.collected + count
                -- A manual "collected" tick can refer to stock still in
                -- bags. Only owning/finishing the piece proves it was spent.
                if not spentKey or progress[spentKey] then row.paid = row.paid + count end
            end
        else
            row.max = math.max(row.max, count)
            if progress[key] then row.maxPaid = math.max(row.maxPaid, count) end
        end
    end)
    local result = {}
    for _, row in pairs(grouped) do
        local held = 0
        for key, character in pairs(DB.characters or {}) do
            if (includeAlts or key == U.charKey())
                and (not row.rule or not row.rule.forRace or row.rule.forRace == character.race)
                and (not row.rule or not row.rule.forFaction or row.rule.forFaction == character.faction) then
                for _, id in ipairs(row.ids) do held = held + ((character.items or {})[id] or 0) end
            end
        end
        row.need = math.max(row.sum, row.max)
        row.have = math.min(row.need, math.max(row.maxPaid, row.collected, row.paid + held))
        row.percent = math.floor(row.have / math.max(1, row.need) * 100 + 0.5)
        row.unknown = not row.id and row.have < row.need
        local name, icon
        if row.id then
            local info = {FGT.ItemInfo(row.id)}
            name, icon = info[1], info[10]
        end
        row.name = name or row.name or labels[row.id] or ("Item " .. tostring(row.id))
        if not icon and row.id then
            -- The instant lookup needs no cache, so uncached items still get their icon.
            local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
            if instant then icon = select(5, instant(row.id)) end
        end
        row.icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        result[#result + 1] = row
    end
    table.sort(result, function(a,b) return a.name < b.name end)
    return result
end

local M = { open=false, fraction=0, bounce=0, rows={} }
FGT.materialsPanel = M
local clip = CreateFrame("Frame", nil, U.main)
M.clip = clip
clip:SetFrameLevel(U.detail:GetFrameLevel())
clip:SetPoint("TOPRIGHT", U.detail, "TOPRIGHT", 0, 0) -- re-anchored by Place
if clip.SetClipsChildren then clip:SetClipsChildren(true) end
local panel = CreateFrame("Frame", nil, clip, "BackdropTemplate")
M.frame = panel
panel:SetPoint("TOPLEFT", clip, "TOPLEFT", 0, 0)
panel:SetPoint("BOTTOMLEFT", clip, "BOTTOMLEFT", 0, 0)
U.etch(panel, U.styles.panel, 12)
FGT.AddGrime(panel, 0.18, 12, 0.37, 0, 140)
panel:EnableMouse(true)
local title = U.title(panel, 13)
title:SetPoint("TOPLEFT", 14, -17)
title:SetText("Materials")
local scroll = U.scroll(panel)
M.scroll = scroll
scroll.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
scroll.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 12)
scroll:Finalize()
local empty = U.font(scroll.content, 11, "", unpack(C.SUBTEXT))
empty:SetPoint("TOPLEFT", 0, -10)
empty:SetJustifyH("LEFT")

-- While the drawer peeks out over the guide, its left edge casts a soft
-- shadow onto it so it reads as sitting on top.
local peek = CreateFrame("Frame", nil, U.main)
M.peekShadow = peek
peek:SetPoint("TOPRIGHT", clip, "TOPLEFT", 0, 0)
peek:SetPoint("BOTTOMRIGHT", clip, "BOTTOMLEFT", 0, 0)
peek:SetWidth(16)
local peekTex = peek:CreateTexture(nil, "OVERLAY")
peekTex:SetAllPoints()
peekTex:SetTexture("Interface\Buttons\WHITE8X8")
peek:Hide()

-- The outer window edge casts a shadow only while the drawer is tucked
-- beneath it. The panel's left edge travels inward as it is revealed.
local shadow = panel:CreateTexture(nil, "OVERLAY", nil, 3)
M.edgeShade = shadow
shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
shadow:SetPoint("TOPRIGHT", clip, "TOPRIGHT", 0, 0)
shadow:SetPoint("BOTTOMRIGHT", clip, "BOTTOMRIGHT", 0, 0)
shadow:SetWidth(22)
U.gradient(shadow, {0,0,0}, {0,0,0}, 0, 0.65)

local handle = CreateFrame("Button", nil, U.main)
M.handle = handle
handle:SetFrameLevel(U.main:GetFrameLevel() + 45)
handle:SetSize(24, 48)
handle:SetScript("OnEnter", function(self)
    self.icon:SetVertexColor(unpack(C.ACCENT))
    self.glow:SetVertexColor(unpack(C.ACCENT))
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(M.canOpen and (M.open and "Hide materials" or "Show materials") or "Widen the window to show materials")
    GameTooltip:Show()
end)
handle:SetScript("OnLeave", function(self)
    self.icon:SetVertexColor(unpack(C.SUBTEXT))
    self.glow:SetVertexColor(unpack(C.SUBTEXT))
    GameTooltip:Hide()
end)
FGT.IconButton(handle, "chevron-white", 10)
handle.icon:SetVertexColor(unpack(C.SUBTEXT))
handle.glow:SetVertexColor(unpack(C.SUBTEXT))

local filter = CreateFrame("Button", nil, panel)
M.filter = filter
filter:SetSize(24, 24)
filter:SetPoint("TOPRIGHT", -9, -10)
for i=1,2 do
    local line = U.flat(filter, unpack(C.SUBTEXT))
    line:SetSize(14, 1)
    line:SetPoint("CENTER", 0, i == 1 and 3 or -3)
    local knob = filter:CreateTexture(nil, "ARTWORK")
    knob:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\knob")
    knob:SetSize(5, 5)
    knob:SetPoint("CENTER", i == 1 and -3 or 3, i == 1 and 3 or -3)
    knob:SetVertexColor(unpack(C.SUBTEXT))
end
filter:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine("Materials options"); GameTooltip:Show() end)
filter:SetScript("OnLeave", function() GameTooltip:Hide() end)
local options = CreateFrame("Frame", nil, panel, "BackdropTemplate")
M.options = options
options:SetPoint("TOPLEFT", 8, -40)
options:SetPoint("TOPRIGHT", -8, -40)
options:SetHeight(100)
options:SetFrameLevel(panel:GetFrameLevel()+35)
options:EnableMouse(true)
U.etch(options, U.styles.panel, 10)
options:Hide()
local optionRows = {}
for i, entry in ipairs({{"materialsCollected","Show collected"}, {"materialsCounts","Show counts"}, {"materialsAlts","Include other characters"}}) do
    local button = CreateFrame("Button", nil, options)
    button:SetHeight(30)
    button:SetPoint("TOPLEFT", 6, -5-(i-1)*30)
    button:SetPoint("TOPRIGHT", -6, -5-(i-1)*30)
    button.mark = U.font(button, 11, "", unpack(C.ACCENT))
    button.mark:SetPoint("LEFT", 0, 0)
    button.label = U.font(button, 10, "", unpack(C.TEXT))
    button.label:SetPoint("LEFT", 28, 0)
    button.label:SetPoint("RIGHT", -2, 0)
    button.label:SetJustifyH("LEFT")
    button.label:SetText(entry[2])
    button.key = entry[1]
    button:SetScript("OnClick", function(self)
        FGT.SetSetting(self.key, not FGT.Setting(self.key))
        FGT.RefreshMaterials()
    end)
    optionRows[#optionRows+1] = button
end
filter:SetScript("OnClick", function() options:SetShown(not options:IsShown()) end)

local function LayoutRows()
    local width = math.max(1, panel:GetWidth()-30)
    scroll.content:SetWidth(width)
    empty:SetWidth(width)
    local y = 0
    for _, row in ipairs(M.rows) do
        if row:IsShown() then
            row:SetWidth(width)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
            row.name:SetWidth(math.max(1,width-52))
            local textH = math.max(16,row.name:GetStringHeight())
            row.bar:ClearAllPoints(); row.bar:SetPoint("TOPLEFT",0,-textH-6); row.bar:SetWidth(width)
            row.count:ClearAllPoints(); row.count:SetPoint("TOPLEFT",row.bar,"BOTTOMLEFT",0,-5)
            row.count:SetWidth(width)
            local countH = FGT.Setting("materialsCounts") and math.max(16,row.count:GetStringHeight()+5) or 0
            local height = textH + 22 + countH
            row:SetHeight(height); y = y + height + 10
        end
    end
    scroll.content:SetHeight(math.max(1,y,empty:IsShown() and 60 or 0))
    scroll:Update()
    if not M.open then scroll.trackHit:Hide() end
end

function FGT.RefreshMaterials()
    local goal = U.goal()
    if not goal then
        M.open=false; M.fraction=0
        if M.driver then M.driver:SetScript("OnUpdate",nil) end
        M:Place(); clip:Hide(); handle:Hide(); shadow:Hide(); options:Hide()
        return
    end
    for _, button in ipairs(optionRows) do button.mark:SetText(FGT.Setting(button.key) and "On" or "Off") end
    local data = FGT.MaterialRows(goal, FGT.Setting("materialsAlts"))
    -- Names in manual recipes may resolve after login. Start watching the
    -- newly revealed ID and take its current bag/bank snapshot immediately.
    local added = false
    local DB = ForeverGoalTrackerDB
    local character = DB.characters and DB.characters[U.charKey()]
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    for _, entry in ipairs(data) do
        for _, id in ipairs(entry.ids) do
            if not U.watch[id] then
                U.watch[id] = true; added = true
                if character and getCount then
                    local count = getCount(id, true)
                    if type(count) == "number" then
                        character.items = character.items or {}
                        character.items[id] = count > 0 and count or nil
                    end
                end
            end
        end
    end
    if added then data = FGT.MaterialRows(goal, FGT.Setting("materialsAlts")) end
    M.data = data
    local visible = 0
    for _, entry in ipairs(data) do
        if FGT.Setting("materialsCollected") or entry.have < entry.need then
            visible = visible + 1
            local row = M.rows[visible]
            if not row then
                row = CreateFrame("Button", nil, scroll.content)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row.icon = row:CreateTexture(nil,"ARTWORK")
                row.icon:SetSize(14,14); row.icon:SetPoint("TOPLEFT",0,0)
                row.name = U.font(row,11,"",unpack(C.TEXT)); row.name:SetPoint("TOPLEFT",20,0); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
                row.percent = U.font(row,10,"",unpack(C.INK2)); row.percent:SetPoint("TOPRIGHT",0,0)
                row.bar = U.bar(row,6); row.bar.label:Hide()
                row.count = U.font(row,10,"",unpack(C.SUBTEXT)); row.count:SetJustifyH("LEFT")
                row:SetScript("OnEnter", function(self)
                    local e = self.entry
                    if e.id then FGT.ShowItemTip(self,e.id,nil,e.name) else GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine(e.name) end
                    GameTooltip:AddLine(e.unknown and "Item count unavailable" or string.format("%d collected · %d remaining",e.have,e.need-e.have),unpack(C.TEXT))
                    GameTooltip:AddLine(FGT.Setting("materialsAlts") and "Counts use tracked characters' last scans." or "Counts use this character's last scan.",unpack(C.SUBTEXT))
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function() FGT.tip=nil; GameTooltip:Hide() end)
                row:SetScript("OnClick", function(self,button)
                    if not self.entry.id then return end
                    if button == "RightButton" then FGT.OpenWowheadCard("item",self.entry.id,self.entry.name)
                    elseif IsShiftKeyDown() then
                        local _, link = FGT.ItemInfo(self.entry.id)
                        if link then ChatEdit_InsertLink(link) end
                    else FGT.PreviewItemClick(self.entry.id,button) end
                end)
                M.rows[visible] = row
            end
            row.entry = entry
            row.name:SetText(entry.name); row.icon:SetTexture(entry.icon)
            row.percent:SetText(entry.unknown and "—" or (entry.percent .. "%"))
            row.bar.instant=true; row.bar:SetProgress(entry.have,entry.need,""); row.bar.instant=nil
            row.count:SetText(entry.unknown and "Count unavailable" or (entry.have .. " collected · " .. (entry.need-entry.have) .. " remaining"))
            row.count:SetShown(FGT.Setting("materialsCounts")); row:EnableMouse(M.open); row:Show()
        end
    end
    for i=visible+1,#M.rows do M.rows[i]:Hide() end
    empty:SetText(#data == 0 and "No materials needed." or "All materials collected.")
    empty:SetShown(visible == 0)
    if M.goalId ~= goal.id then scroll.scroll:SetVerticalScroll(0); M.goalId=goal.id; options:Hide() end
    M:Place()
    -- A real shopping list draws the eye the first time that goal is viewed
    -- with the window up: Tier 3 and AQ sets (9+ rows) slide the drawer open,
    -- smaller lists (3 to 8) give it a little bounce.
    -- Once per goal ever; /goals materialsreset starts over.
    if #data >= 3 and U.main:IsShown() and not DB.demoBackup then
        DB.materialsSeen = DB.materialsSeen or {}
        if not DB.materialsSeen[goal.id] then
            if M.open then
                DB.materialsSeen[goal.id] = true
            elseif M.canOpen then
                DB.materialsSeen[goal.id] = true
                local id = goal.id
                local bigList = #data >= 9
                C_Timer.After(0.35, function()
                    if M.goalId == id and not M.open and U.main:IsShown() then
                        if bigList then M:SetOpen(true) else M:Bounce() end
                    end
                end)
            end
        end
    end
end

function M:Place()
    local area = math.max(0,U.main:GetWidth()-U.list:GetWidth()-44)
    self.width = math.min(280,math.max(22,area-160))
    self.canOpen = self.width >= 150
    if not self.canOpen then self.open=false; self.fraction=0 end
    local hasGoal = U.goal() ~= nil
    -- A bounce peeks out over the guide without moving it.
    local span = hasGoal and (22 + (self.width-22)*(self.fraction+self.bounce)) or 0
    local guideSpan = hasGoal and (22 + (self.width-22)*self.fraction) or 0
    self.span = span
    clip:ClearAllPoints()
    clip:SetPoint("TOPRIGHT",U.list,"TOPRIGHT",U.main:GetWidth()-U.list:GetWidth()-32,0)
    clip:SetPoint("BOTTOMRIGHT",U.main,"BOTTOMRIGHT",-16,16)
    clip:SetWidth(math.max(1,span))
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT",clip,"TOPLEFT",0,0)
    panel:SetPoint("BOTTOMLEFT",clip,"BOTTOMLEFT",0,0)
    panel:SetWidth(self.width)
    U.detail:ClearAllPoints()
    U.detail:SetPoint("TOPLEFT",U.list,"TOPRIGHT",12,0)
    U.detail:SetPoint("BOTTOMRIGHT",U.main,"BOTTOMRIGHT",-16-guideSpan-(hasGoal and 12 or 0),16)
    -- Center the glyph in the 12-unit gap; keep the invisible hit area wider.
    handle:ClearAllPoints(); handle:SetPoint("CENTER",clip,"LEFT",-6,0)
    -- IconButton's texture is named icon (the source glyph points down).
    local rotation = self.open and math.pi/2 or -math.pi/2
    handle.icon:SetRotation(rotation)
    handle.glow:SetRotation(rotation)
    local visible = U.detail:IsShown() and hasGoal
    -- While peeking out over the guide, sit above it.
    clip:SetFrameLevel(U.detail:GetFrameLevel()+(self.bounce>0 and 30 or 0))
    peek:SetFrameLevel(clip:GetFrameLevel()+1)
    if self.bounce>0 and hasGoal then
        U.gradient(peekTex, {0,0,0}, {0,0,0}, 0, 0.55*math.min(1,self.bounce/0.025))
        peek:Show()
    else
        peek:Hide()
    end
    clip:SetShown(visible); handle:SetShown(visible)
    -- Gradient alpha is encoded in its colors on these clients.
    U.gradient(shadow, {0,0,0}, {0,0,0}, 0, 0.65*(1-self.fraction))
    shadow:SetShown(visible and self.fraction < 1)
    panel:EnableMouse(self.open)
    scroll.scroll:EnableMouse(self.open)
    scroll.scroll:EnableMouseWheel(self.open)
    scroll.scroll:SetShown(self.fraction > 0)
    scroll.scroll:SetAlpha(self.fraction)
    scroll.trackHit:SetAlpha(self.fraction)
    filter:SetShown(self.fraction > 0)
    filter:SetAlpha(self.fraction)
    filter:EnableMouse(self.open)
    title:SetShown(self.fraction > 0)
    title:SetAlpha(self.fraction)
    for _, row in ipairs(self.rows) do row:EnableMouse(self.open) end
    scroll.trackHit:EnableMouse(self.open)
    -- The thumb hit area is a child of the track; hide the whole track
    -- while tucked away so its independent input cannot capture the edge.
    if not self.open then scroll.trackHit:Hide() end
    if not self.open then options:Hide() end
    LayoutRows()
end

local driver = CreateFrame("Frame",nil,U.main)
M.driver = driver
function M:SetOpen(open)
    driver:SetScript("OnUpdate",nil)
    self.bounce = 0
    self.open = open and self.canOpen or false
    options:Hide(); GameTooltip:Hide()
    local start, target = self.fraction,self.open and 1 or 0
    if FGT.Setting("celebrations") == "off" then
        self.fraction=target; self:Place(); U.redraw(); return
    end
    local elapsed, lastReflow = 0, 0
    driver:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        local p=math.min(1,elapsed/0.26)
        M.fraction=start+(target-start)*(1-(1-p)^3)
        M:Place()
        if p>=1 then
            driver:SetScript("OnUpdate",nil); U.redraw()
        elseif elapsed-lastReflow >= 0.075 then
            lastReflow=elapsed
            U.reflow()
        end
    end)
end
-- A friendly double "boop": the closed drawer eases out and back twice,
-- then repeats twice more, each time smaller, to catch the eye without
-- nagging. It stops the moment you open it or change goals.
local REACH = 0.025
local BURSTS = { {0, REACH}, {2.6, REACH}, {5.4, REACH} } -- start (s), reach (fraction)
local BURST_TIME = 0.8
function M:Bounce()
    if self.open or not self.canOpen or FGT.Setting("celebrations") ~= "full" then return end
    driver:SetScript("OnUpdate",nil)
    local id, elapsed, lastBounce = self.goalId, 0, 0
    local total = BURSTS[#BURSTS][1] + BURST_TIME
    driver:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if M.goalId ~= id or M.open then M.bounce=0; driver:SetScript("OnUpdate",nil); M:Place(); return end
        local value = 0
        for _, burst in ipairs(BURSTS) do
            local p = (elapsed-burst[1])/BURST_TIME
            if p > 0 and p < 1 then
                value = burst[2]*0.5*(1-math.cos(p*math.pi*4)) -- two soft bumps
            end
        end
        if elapsed >= total then value = 0 end
        if value ~= lastBounce then M.bounce=value; lastBounce=value; M:Place() end
        if elapsed >= total then driver:SetScript("OnUpdate",nil) end
    end)
end
handle:SetScript("OnClick",function() M:SetOpen(not M.open) end)
U.main:HookScript("OnSizeChanged",function() M:Place() end)
U.detail:HookScript("OnShow",function() M:Place(); FGT.RefreshMaterials() end)
U.detail:HookScript("OnHide",function() driver:SetScript("OnUpdate",nil); M.bounce=0; M.fraction=M.open and 1 or 0; clip:Hide(); handle:Hide(); shadow:Hide(); options:Hide() end)
U.main:HookScript("OnHide",function() driver:SetScript("OnUpdate",nil); M.bounce=0; M.fraction=M.open and 1 or 0; options:Hide() end)
U.main:HookScript("OnShow",function() M:Place(); FGT.RefreshMaterials() end)
local events = CreateFrame("Frame")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
local refreshQueued = false
events:SetScript("OnEvent",function(_,_,id,success)
    local relevant = false
    for _, row in ipairs(M.data or {}) do
        if row.unknown then relevant=true; break end
        for _, item in ipairs(row.ids) do if item==id then relevant=true; break end end
        if relevant then break end
    end
    if success and relevant and not refreshQueued and U.main:IsShown() and U.detail:IsShown() then
        refreshQueued=true
        C_Timer.After(0.1,function() refreshQueued=false; if U.main:IsShown() and U.detail:IsShown() then FGT.RefreshMaterials() end end)
    end
end)
M:Place()
