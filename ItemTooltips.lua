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
        tooltip:AddLine(entry.goal.name .. "  (" .. (entry.remaining > 0
            and (entry.remaining .. " more") or "Collected") .. ")", 0.88, 0.82, 0.69, true)
    end
    tooltip:AddLine("Counts include your tracked characters' last scans.", 0.55, 0.52, 0.47, true)
    return true
end

-- Use the player's DRESSUP modifier, Ctrl by default. Consume the click
-- even if details are still loading, so it never ticks a guide step.
function FGT.PreviewItemClick(id, button)
    if not id or button ~= "LeftButton" then return false end
    local modified = IsModifiedClick and IsModifiedClick("DRESSUP")
    if not modified then return false end
    local name, link = FGT.ItemInfo(id)
    if name and DressUpItemLink then
        DressUpItemLink(link or ("item:" .. id))
    elseif C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(id)
    end
    return true
end

function FGT.ItemCanPreview(id)
    local _, _, _, _, _, _, _, _, slot = FGT.ItemInfo(id)
    return type(slot) == "string" and slot ~= "" and slot ~= "INVTYPE_NON_EQUIP"
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
