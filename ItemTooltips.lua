local ADDON, FGT = ...

-- Read current selections and ticks at hover time, so a reset, removed
-- goal or newly finished step cannot leave stale shopping hints behind.
local function List(value)
    if type(value) == "table" then return value end
    return value and { value } or {}
end

local function Matches(rule, id)
    for _, item in ipairs(List(rule and rule.item)) do
        if item == id then return true end
    end
end

local function Held(id, rule)
    local n = 0
    for _, c in pairs(ForeverGoalTrackerDB.characters or {}) do
        if (not rule or not rule.forRace or rule.forRace == c.race)
            and (not rule or not rule.forFaction or rule.forFaction == c.faction) then
            for _, item in ipairs(List(rule and rule.item or id)) do
                n = n + ((c.items and c.items[item]) or 0)
            end
        end
    end
    return n
end

-- Tier 3's material lines are intentionally manual checklists. Match
-- the cached item's exact name, allowing only our count/plural/location
-- syntax, rather than treating incidental mentions in tips as needs.
local function MaterialCount(text, name)
    if not name then return end
    local count, label = text:match("^(%d+) (.+)$")
    label = label or text
    label = label:match("^(.-) from ") or label
    if label == name or label == name .. "s" then return tonumber(count) or 1 end
end

function FGT.ItemNeeds(id)
    local DB = ForeverGoalTrackerDB
    local out = {}
    if not DB or not DB.active or not DB.progress then return out end
    local name = FGT.ItemInfo(id)
    for _, goal in ipairs(FGT.ActiveGoals()) do
        local progress = DB.progress[goal.id] or {}
        local done, total = FGT.GoalProgress(goal)
        if total > 0 and done < total then
            local amount, materials, held, matched = 0, 0, 0, false
            local function Rule(rule)
                if Matches(rule, id) then
                    matched = true
                    -- Collection milestones refer to the same stock. Keep
                    -- the largest remaining target, not the sum of them.
                    amount = math.max(amount, math.max(0, (rule.count or 1) - Held(id, rule)))
                end
            end
            for i, step in ipairs(goal.steps or {}) do
                if FGT.PartSelected(goal, i) and not progress[i] and not FGT.PieceSkipped(step)
                    and type(step) == "table" then Rule(step.auto) end
            end
            for si, section in ipairs(goal.sections or {}) do
                if FGT.PartSelected(goal, si) then
                    for pi, piece in ipairs(section.pieces) do
                        local pd, pt = FGT.PieceProgress(goal.id, si, pi, piece)
                        if pd < pt then
                            Rule(piece.auto)
                            for _, ingredient in ipairs(piece.requiredItems or {}) do
                                if ingredient.item == id then materials = materials + ingredient.count end
                            end
                            for mi, text in ipairs(piece.materials or {}) do
                                if not progress[si .. "_" .. pi .. "_m" .. mi] then
                                    local count = MaterialCount(text, name)
                                    if count then materials = materials + count end
                                end
                            end
                        end
                    end
                end
            end
            if materials > 0 then
                matched = true
                held = Held(id)
                amount = math.max(amount, math.max(0, materials - held))
            end
            if matched then out[#out + 1] = { goal = goal, remaining = amount } end
        end
    end
    table.sort(out, function(a, b) return a.goal.name < b.goal.name end)
    return out
end

function FGT.AddItemNeeds(tooltip, id)
    if not FGT.Setting("itemNeeds") or tooltip.fgtNeedsItem == id then return end
    local needs = FGT.ItemNeeds(id)
    if #needs == 0 then return end
    tooltip.fgtNeedsItem = id
    tooltip:AddLine(" ")
    tooltip:AddLine("Needed for", 0.80, 0.62, 0.16)
    for _, entry in ipairs(needs) do
        tooltip:AddLine(entry.goal.name .. " |cff9c917a· " .. (entry.remaining > 0
            and (entry.remaining .. " more") or "Collected") .. "|r", 0.88, 0.82, 0.69, true)
    end
    return true
end

-- Mount items in Forever report a shared "Learning" spell, and native
-- item-to-mount lookup returns nil. Use the library's exact mount names.
local mountItemNames, mountNames = {}, nil
local function MountName(name)
    return name:gsub("^Reins of the ", ""):gsub("^Horn of the ", "")
end
local function MountEntry(entry)
    if type(entry) ~= "table" then return end
    local rule = entry.auto
    if rule and rule.item and rule.owned then
        local ids = type(rule.item) == "table" and rule.item or {rule.item}
        for _, id in ipairs(ids) do mountItemNames[id] = rule.owned[1] end
    end
    for _, link in ipairs(entry.links or {}) do
        for _, variant in ipairs(link.variants or {}) do
            mountItemNames[variant[1]] = MountName(variant[2])
        end
    end
end
for _, goal in ipairs(FGT.goals) do
    if goal.category == "Mount" or goal.category == "Mount Collection" then
        for _, entry in ipairs(goal.steps or {}) do MountEntry(entry) end
        for _, section in ipairs(goal.sections or {}) do
            for _, entry in ipairs(section.pieces or {}) do MountEntry(entry) end
        end
    end
end
-- Owned-pattern labels on the AQ goals are deliberately short.
for color, id in pairs({Blue=21218, Green=21323, Yellow=21324, Red=21321, Black=21176}) do
    mountItemNames[id] = color.." Qiraji Battle Tank"
end
function FGT.ItemMountID(id)
    if not DressUpMount or not C_MountJournal then return end
    local journal = C_MountJournal
    local mount = journal.GetMountFromItem and journal.GetMountFromItem(id)
    if mount and mount > 0 then return mount end
    local name = mountItemNames[id]
    if not name or not journal.GetMountIDs or not journal.GetMountInfoByID then return end
    -- One lazy scan per session, never while painting or animating rows.
    if not mountNames then
        mountNames = {}
        for _, mid in ipairs(journal.GetMountIDs() or {}) do
            local label = journal.GetMountInfoByID(mid)
            if label then mountNames[label] = mid end
        end
    end
    return mountNames[name]
end

-- Use the player's DRESSUP modifier, Ctrl by default. Consume the click
-- even if details are still loading, so it never ticks a guide step.
function FGT.PreviewItemClick(id, button, variants)
    if not id or button ~= "LeftButton" then return false end
    local modified = IsModifiedClick and IsModifiedClick("DRESSUP")
    if not modified then return false end
    if variants and #variants > 1 then
        local cycle = FGT.mountPreviewCycle
        local index = cycle and cycle.id == id and (cycle.index % #variants)+1 or 1
        FGT.mountPreviewCycle = {id=id, index=index}
        id = variants[index][1]
    end
    local name, link = FGT.ItemInfo(id)
    local mount = FGT.ItemMountID(id)
    if mount then
        DressUpMount(mount)
    elseif name and DressUpItemLink then
        DressUpItemLink(link or ("item:" .. id))
    elseif C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(id)
    end
    return true
end

-- An armor set's pieces in order, one item id each (the first id when a piece
-- lists several versions). Only a goal that is one set (a single section of
-- pieces) qualifies; the Library's grouped wrappers and other goals give nil.
function FGT.SetPreviewIds(goal)
    local sections = goal and goal.sections
    if not sections or #sections ~= 1 then return nil end
    local ids = {}
    for _, piece in ipairs(sections[1].pieces or {}) do
        local item = piece.auto and piece.auto.item
        local id = type(item) == "table" and item[1] or item
        if type(id) == "number" then ids[#ids + 1] = id end
    end
    return #ids >= 2 and ids or nil
end

-- Ctrl-click on a set's big icon (the DRESSUP click, like the item previews):
-- the game's dressing room opens on your character with every piece of the
-- set on. Pieces the game has no details for (Forever hides items until a
-- player finds one) can't be tried on: they are asked for a few times, then
-- named in one chat line.
function FGT.PreviewSetClick(goal, button)
    if button ~= "LeftButton" or not (IsModifiedClick and IsModifiedClick("DRESSUP")) then return false end
    local ids = FGT.SetPreviewIds(goal)
    if not ids or not DressUpItemLink then return false end
    -- start from your own character: an open dressing room is reset first, so an
    -- earlier preview's pieces don't stay on in slots this set doesn't cover
    local frame = DressUpFrame
    local reset = frame and (frame.ResetButton or _G.DressUpFrameResetButton)
    if frame and frame.IsShown and frame:IsShown() and reset and reset.Click then pcall(reset.Click, reset) end
    local pending, tried = {}, 0
    local function Try(list)
        local missed = {}
        for _, id in ipairs(list) do
            local name, link = FGT.ItemInfo(id)
            if name and link then
                if FGT.ItemCanPreview(id) then
                    pcall(DressUpItemLink, link)
                    tried = tried + 1
                end
            else
                missed[#missed + 1] = id
                if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
            end
        end
        return missed
    end
    pending = Try(ids)
    local attempts = 0
    local function Retry()
        attempts = attempts + 1
        pending = Try(pending)
        if #pending > 0 and attempts < 3 and C_Timer then
            C_Timer.After(0.7, Retry)
        elseif #pending > 0 then
            print("|cffffd75eForever Goal Tracker:|r " .. string.format(
                "%d of %d pieces of %s can't be tried on yet: the game has no details for them%s.",
                #pending, #ids, goal.name, FGT.isForever and " (Forever shows an item once a player has found it)" or ""))
        end
    end
    if #pending > 0 and C_Timer then C_Timer.After(0.7, Retry) end
    return true
end

function FGT.ItemCanPreview(id)
    if FGT.ItemMountID(id) then return true end
    local _, _, _, _, _, _, _, _, slot = FGT.ItemInfo(id)
    -- Modern clients report "INVTYPE_NON_EQUIP_IGNORE" for trade goods, and
    -- bags and ammo can't be tried on either.
    return type(slot) == "string" and slot ~= "" and not slot:find("^INVTYPE_NON_EQUIP")
        and slot ~= "INVTYPE_BAG" and slot ~= "INVTYPE_QUIVER" and slot ~= "INVTYPE_AMMO"
end

local function Clear(tooltip) tooltip.fgtNeedsItem = nil end
local function OnItem(tooltip, data)
    -- Comparison windows stay focused on equipment comparisons.
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    local id = data and data.id
    if not id then
        local _, link = tooltip:GetItem()
        id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    end
    if type(id) == "number" then return FGT.AddItemNeeds(tooltip, id) end
end

function FGT.InstallItemTooltipHooks()
    if FGT.itemTooltipHooks then return end
    FGT.itemTooltipHooks = true
    local modern = TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
        tooltip:HookScript("OnTooltipCleared", Clear)
        if not modern then
            tooltip:HookScript("OnTooltipSetItem", function(self)
                if OnItem(self) then self:Show() end -- resize after adding lines
            end)
        end
    end
    if modern then TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItem) end
end

-- Both native tooltip implementations are ready by PLAYER_LOGIN.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", FGT.InstallItemTooltipHooks)
