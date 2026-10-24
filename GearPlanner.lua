local ADDON, FGT = ...
local U = FGT.MaterialsUI
local Cat = FGT.GearCatalog
local QUALITY = Cat.QUALITY
local P = CreateFrame("Frame", nil, U.main)
FGT.GearPlanner = P
P:SetAllPoints(U.main)
P:Hide()
local tab = FGT.NewPlannerTab("Gear Planner")
FGT.gearTab = tab
tab:SetPoint("LEFT", FGT.libraryTab, "RIGHT", 6, 0)
tab:SetScript("OnClick", function() FGT.ShowTab("gear") end)

-- Match the native character panel for every empty equipment slot.
-- Use slot names (HeadSlot, Finger0Slot, etc.) when adding planner slots.
function FGT.GearPlannerSlotTexture(slotName)
    -- not a real inventory slot name, so the game would reject it
    if slotName == "QuiverSlot" then return "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag" end
    local _, texture = GetInventorySlotInfo(slotName)
    if (type(texture) == "string" and texture ~= "") or (type(texture) == "number" and texture > 0) then
        return texture
    end
    return "Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. slotName:gsub("%d", ""):gsub("Slot$", "")
end
local slotIds = Cat.SLOT_INDEX
local colors, styles = U.colors, U.styles
-- Inventory types with no model to show: neck, rings, trinkets and relics.
local NO_MODEL = { [2] = true, [11] = true, [12] = true, [24] = true, [27] = true, [28] = true }
local ROW_H = 46
local POOL_ROWS = 12 -- enough to fill the tallest picker (460) without measuring a frame before it is laid out
local PICKER_MAX, PICKER_MIN = 460, 200

-- ------------------------------------------------------------
-- Saved data
-- ------------------------------------------------------------
-- ForeverGoalTrackerDB.gearPlanner = { version, prefs, characters[charKey] = { nextId, selected, builds } }
-- A build is { id, name, level (target level; 60 when missing), slots = { [slot number] = item id },
-- enchants = { [slot number] = spell }, tracked, goalId, goalItems, preset }. goalItems lines up with the goal steps: { slot, id } or { slot, enchant }.
local function Root()
    local db = ForeverGoalTrackerDB
    db.gearPlanner = db.gearPlanner or { version = 2, characters = {} }
    -- stat: a stat code or nil; kinds: the armor or weapon type chosen per slot
    db.gearPlanner.prefs = db.gearPlanner.prefs or { quality = 0, revealed = false, kinds = {} }
    return db.gearPlanner
end
-- Whose sets are open: the logged-in character unless another one is picked
-- (any character on the roster; sets, goals and credit stay with that character).
local planFor
local function PlanKey() return planFor or U.charKey() end
local RACE_IDS = { Human = 1, Orc = 2, Dwarf = 3, NightElf = 4, Scourge = 5, Tauren = 6, Gnome = 7, Troll = 8, Skyborne = 95 }
-- The planned character's class, race, faction, level and sex (UnitSex numbering).
local function Who()
    local key = PlanKey()
    if key == U.charKey() then
        local _, class = UnitClass("player")
        local _, race = UnitRace("player")
        return { key = key, me = true, name = UnitName("player"), class = class, race = race,
            faction = UnitFactionGroup("player"), level = UnitLevel("player"), sex = UnitSex and UnitSex("player") }
    end
    local c = (ForeverGoalTrackerDB.characters or {})[key] or {}
    return { key = key, me = false, name = c.name or key, class = c.class, race = c.race,
        faction = c.faction, level = c.level, sex = c.sex }
end
local function Store()
    local chars, key = Root().characters, PlanKey()
    chars[key] = chars[key] or { nextId = 1, builds = {} }
    return chars[key]
end
local function Prefs() return Root().prefs end

-- ------------------------------------------------------------
-- Goals for tracked sets
-- ------------------------------------------------------------
-- Planner goals stay out of the Library; their stable IDs survive renames and reloads.
local function SyncGoal(build, ownerKey)
    if not build.tracked or not build.id then return end
    local DB = ForeverGoalTrackerDB
    local ownerId = ownerKey:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)
    local id = "planner_" .. ownerId .. "_" .. build.id
    local goal = FGT.GoalById(id)
    local old, credit = build.goalItems or {}, {}
    local progress = DB.progress[id] or {}
    for i, item in ipairs(old) do
        if progress[i] then credit[item.slot .. ":" .. (item.enchant and ("e" .. item.enchant) or item.id)] = true end
    end
    if not goal then
        goal = { id = id, category = "Item Set", plannerOwner = ownerKey,
            difficulty = "Varies", duration = "Varies", steps = {} }
        FGT.goals[#FGT.goals + 1] = goal
        FGT.goalIndex = nil
    end
    goal.name = build.name
    goal.steps, goal.tips, build.goalItems = {}, {}, {}
    local nextProgress, copies, firstIcon, classic, unrevealed = {}, {}, nil, false, false
    -- Items with a Library goal link to it: a reward (Thunderfury) becomes "Complete the
    -- Thunderfury goal", which holds the whole path and its materials; set pieces keep their own
    -- step and the set's goal is named once in the tips.
    local owner = DB.characters and DB.characters[ownerKey]
    local setGoals, setGoalSeen = {}, {}
    for _, slot in ipairs(Cat.SLOT_ORDER) do
        local item = Cat.Get(build.slots[slot])
        if item then
            copies[item.id] = (copies[item.id] or 0) + 1
            local acquisition, advice = Cat.Acquisition(item)
            local finger = Cat.SLOT_NAMES[slot]:match("^Finger(%d)")
            local trinket = Cat.SLOT_NAMES[slot]:match("^Trinket(%d)")
            local suffix = finger and (finger == "0" and " (Finger 1)" or " (Finger 2)")
                or trinket and (trinket == "0" and " (Trinket 1)" or " (Trinket 2)") or ""
            -- A step per planned slot; the same item twice needs two owned copies.
            local step = { text = acquisition .. suffix,
                auto = { item = item.id, count = copies[item.id], forCharacter = ownerKey }, plannerSlot = slot,
                tip = advice, reagents = Cat.Reagents(item.id) }
            local library, kind = Cat.GoalFor(item.id, owner and owner.faction)
            if library and kind == "reward" then
                step.text = "Complete the {" .. library.id .. ":" .. (library.short or library.name) .. "} goal" .. suffix
                step.tip, step.reagents, advice = nil, nil, nil
            elseif library and not setGoalSeen[library.id] then
                setGoalSeen[library.id] = true
                setGoals[#setGoals + 1] = "{" .. library.id .. ":" .. (library.short or library.name) .. "}"
            end
            goal.steps[#goal.steps + 1] = step
            build.goalItems[#build.goalItems + 1] = { slot = slot, id = item.id }
            if advice then goal.tips[#goal.tips + 1] = "{item:" .. item.id .. ":" .. item.name .. "}: " .. advice end
            if credit[slot .. ":" .. item.id] then nextProgress[#goal.steps] = true end
            if U.watch then U.watch[item.id] = true end
            -- The planned enchant: a step of its own, done when the game shows it on that item.
            local e = build.enchants and Cat.Enchant(build.enchants[slot])
            if e and Cat.EnchantFits(e.spell, item) then
                goal.steps[#goal.steps + 1] = { text = Cat.EnchantStep(e, item),
                    auto = { enchant = e.effect, slot = slot, onItem = item.id, forCharacter = ownerKey },
                    plannerSlot = slot, reagents = e.reagents }
                build.goalItems[#build.goalItems + 1] = { slot = slot, enchant = e.spell }
                if credit[slot .. ":e" .. e.spell] then nextProgress[#goal.steps] = true end
            end
            firstIcon = firstIcon or item.icon
            if item.forever < 2 then classic = true else unrevealed = unrevealed or item.forever == 3 end
        end
    end
    if #setGoals > 0 then
        goal.tips[#goal.tips + 1] = (#setGoals == 1 and "Library goal for these pieces: " or "Library goals for these pieces: ")
            .. table.concat(setGoals, ", ") .. "."
    end
    local preset = build.preset and Cat.PRESETS[build.preset]
    if preset and preset.note then goal.tips[#goal.tips + 1] = preset.note end
    if FGT.isForever then
        if classic then goal.tips[#goal.tips + 1] = "Sources shown are from Classic Era. Availability in Forever is Unconfirmed." end
        if unrevealed then goal.tips[#goal.tips + 1] = "Some of these items are not revealed in Forever yet." end
    end
    DB.progress[id] = nextProgress
    goal.icon = firstIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    build.goalId = id
    FGT.EnsureGoalRow(goal)
    return goal
end
-- A gear set counts only its own character's items. When another character holds one, the
-- step says where, and whether it can be mailed: Bind on Pickup and quest items never can, a
-- Bind on Equip item can until someone wears it (worn copies are soulbound).
function FGT.PlannerElsewhere(goal, step)
    local rule = type(step) == "table" and step.auto
    if not (goal and goal.plannerOwner and rule and rule.forCharacter and type(rule.item) == "number") then return nil end
    local item = Cat.Get(rule.item)
    if not item then return nil end
    local chars = ForeverGoalTrackerDB and ForeverGoalTrackerDB.characters or {}
    local owner = chars[rule.forCharacter]
    local ownerName = owner and owner.name or "this set's character"
    local mail, bound
    for key, c in pairs(chars) do
        local count = key ~= rule.forCharacter and c.items and c.items[item.id] or 0
        if count > 0 then
            local worn = 0
            for _, id in pairs(c.worn or {}) do if id == item.id then worn = worn + 1 end end
            local loose = count - worn -- the game's item count includes worn items
            local mailable = item.bind == 0 or item.bind == 3 or (item.bind == 2 and loose > 0)
            if mailable then mail = mail or c.name else bound = bound or c.name end
        end
    end
    if mail then return "On " .. mail .. ": mail it to " .. ownerName end
    if bound then return bound .. " has one, but it's soulbound. " .. ownerName .. " needs their own" end
end
-- Another character's set shows that character's saved progress: say how fresh it is.
function FGT.PlannerFreshness(goal)
    if not (goal and goal.plannerOwner) or goal.plannerOwner == U.charKey() then return nil end
    local c = ForeverGoalTrackerDB and ForeverGoalTrackerDB.characters and ForeverGoalTrackerDB.characters[goal.plannerOwner]
    if not (c and c.name) then return nil end
    local ago = c.lastSeen and time and (time() - c.lastSeen) or nil
    local when = not ago and "at their last login"
        or ago < 3600 and "less than an hour ago"
        or ago < 86400 and (math.floor(ago / 3600) .. (ago < 7200 and " hour ago" or " hours ago"))
        or (math.floor(ago / 86400) .. (ago < 172800 and " day ago" or " days ago"))
    return c.name .. "'s gear, saved " .. when .. ". It updates when " .. c.name .. " logs in."
end
function FGT.LoadPlannerGoals()
    local DB = ForeverGoalTrackerDB
    for key, store in pairs(DB.gearPlanner and DB.gearPlanner.characters or {}) do
        for _, build in ipairs(store.builds or {}) do SyncGoal(build, key) end
    end
end

-- ------------------------------------------------------------
-- Small controls in the addon's own style
-- ------------------------------------------------------------
local function Label(parent, text, size, x, y)
    local f = U.font(parent, size or 12)
    f:SetPoint("TOPLEFT", x, y); f:SetText(text)
    return f
end
local function Hover(button, on)
    local wash = button.hoverWash
    if not wash then
        wash = CreateFrame("Frame", nil, button)
        wash:SetAllPoints(button)
        -- inside the etched border, so the chiseled corners stay clean
        local inset = (button.etchInset or 3) + 1
        local texture = wash:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOPLEFT", inset, -inset); texture:SetPoint("BOTTOMRIGHT", -inset, inset)
        texture:SetColorTexture(0.80, 0.62, 0.16, 0.13)
        wash:SetAlpha(0); button.hoverWash = wash
        button:HookScript("OnHide", function()
            wash:SetScript("OnUpdate", nil); wash:SetAlpha(0)
        end)
    end
    local start, target, elapsed = wash:GetAlpha(), on and 1 or 0, 0
    wash:SetScript("OnUpdate", nil)
    if FGT.Setting("celebrations") == "off" then wash:SetAlpha(target); if button.EdgeAt then button:EdgeAt(target) end; return end
    wash:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / 0.12)
        self:SetAlpha(start + (target - start) * t)
        if button.EdgeAt then button:EdgeAt(self:GetAlpha()) end
        if t == 1 then self:SetScript("OnUpdate", nil) end
    end)
end
-- One place decides how a button looks, so hover, selection and quality never fight.
-- The border and the inside warm up together: the fill stays put and the gold wash fades in over it
-- (Hover), while the border colour follows the same fade (EdgeAt), so neither snaps ahead of the other.
local function PaintButton(b)
    b:SetEtch(b.chosen and styles.rowSel or styles.button)
    local q = b.quality and QUALITY[b.quality]
    if q and b.SetBackdropBorderColor then b:SetBackdropBorderColor(q[1], q[2], q[3], b.chosen and 1 or 0.85)
    elseif not b.chosen and b.SetBackdropBorderColor then
        if not b.EdgeAt then
            function b:EdgeAt(t)
                local from, to = styles.button.edge, styles.btnHover.edge
                if self.chosen or (self.quality and QUALITY[self.quality]) then return end
                self:SetBackdropBorderColor(from[1] + (to[1] - from[1]) * t, from[2] + (to[2] - from[2]) * t,
                    from[3] + (to[3] - from[3]) * t, (from[4] or 1) + ((to[4] or 1) - (from[4] or 1)) * t)
            end
        end
        local wash = b.hoverWash
        b:EdgeAt(wash and wash:GetAlpha() or (b.hovered and 1 or 0))
    end
end
local function Button(parent, text, width, height, size)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, height or 28); U.etch(b, styles.button)
    b.text = U.font(b, size or 12); b.text:SetPoint("CENTER"); b.text:SetText(text)
    b:SetScript("OnEnter", function() b.hovered = true; Hover(b, true); PaintButton(b) end)
    b:SetScript("OnLeave", function() b.hovered = false; Hover(b, false); PaintButton(b) end)
    return b
end
-- The Library's search field: etched box, magnifier, hint text and a clear X.
local function SearchBox(parent, hintText)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetHeight(24); U.etch(box, styles.row, 10)
    box:SetAutoFocus(false)
    FGT.RegisterFont(box, "body", 11, "")
    box:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3])
    box:SetTextInsets(24, 20, 0, 0); box:SetMaxLetters(40)
    local glass = box:CreateTexture(nil, "OVERLAY")
    glass:SetTexture(FGT.Icon("search-white")); glass:SetSize(13, 13); glass:SetPoint("LEFT", 7, -1)
    glass:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    box.hint = U.font(box, 11); box.hint:SetPoint("LEFT", 24, 0)
    box.hint:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3]); box.hint:SetText(hintText)
    box.clear = CreateFrame("Button", nil, box)
    box.clear:SetSize(16, 16); box.clear:SetPoint("RIGHT", -4, 0)
    local x = box.clear:CreateTexture(nil, "ARTWORK")
    x:SetTexture(FGT.Icon("close-white")); x:SetSize(10, 10); x:SetPoint("CENTER")
    x:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    box.clear:SetScript("OnClick", function() box:SetText(""); box:ClearFocus() end)
    box.clear:Hide()
    box:HookScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        self.hint:SetShown(text == "" and not self:HasFocus()); self.clear:SetShown(text ~= "")
    end)
    box:SetScript("OnEditFocusGained", function(self)
        self.hint:Hide(); self:SetBackdropBorderColor(colors.GOLD2[1], colors.GOLD2[2], colors.GOLD2[3], 1)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self.hint:SetShown((self:GetText() or "") == "")
        self:SetBackdropBorderColor(styles.row.edge[1], styles.row.edge[2], styles.row.edge[3], 1)
    end)
    return box
end

-- ------------------------------------------------------------
-- Layout: set list on the left, editor on the right
-- ------------------------------------------------------------
local left = CreateFrame("Frame", nil, P, "BackdropTemplate")
left:SetPoint("TOPLEFT", U.list, "TOPLEFT")
left:SetPoint("BOTTOMLEFT", U.list, "BOTTOMLEFT")
left:SetWidth(FGT.trackerTab:GetWidth() + FGT.libraryTab:GetWidth() + 56)
-- Small windows: the set list slims down so the character gets the room.
left.natural = left:GetWidth()
function left.Fit()
    local main = U.main:GetWidth() or 0
    local width = main > 0 and math.max(210, math.min(left.natural, main * 0.22)) or left.natural
    if math.abs(width - left:GetWidth()) < 0.5 then return end
    left:SetWidth(width)
    if left.empty then left.empty:SetWidth(width - 32) end
    for _, row in ipairs(left.rows or {}) do
        row:SetWidth(math.max(120, width - 28)); row.text:SetWidth(math.max(100, width - 48))
    end
end
U.etch(left, styles.panel)
local right = CreateFrame("Frame", nil, P, "BackdropTemplate")
right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
right:SetPoint("BOTTOMRIGHT", U.main, "BOTTOMRIGHT", -16, 16)
U.etch(right, styles.panel)
Label(left, "My Gear Sets", 16, 16, -16)
-- Whose sets these are: a picker over every character on the roster.
local ownerBtn = CreateFrame("Button", nil, left)
ownerBtn:SetPoint("TOPLEFT", 12, -36); ownerBtn:SetHeight(22)
local owner = U.font(ownerBtn, 11); owner:SetPoint("LEFT", 4, 0)
local ownerCaret = ownerBtn:CreateTexture(nil, "OVERLAY")
ownerCaret:SetTexture(FGT.Icon("chevron")); ownerCaret:SetSize(12, 12); ownerCaret:SetPoint("LEFT", owner, "RIGHT", 4, 0)
local charMenu = CreateFrame("Frame", nil, left, "BackdropTemplate")
charMenu:SetPoint("TOPLEFT", ownerBtn, "BOTTOMLEFT", 0, -4)
charMenu:SetFrameLevel(left:GetFrameLevel() + 30); charMenu:EnableMouse(true)
U.etch(charMenu, styles.panel); charMenu:Hide()
local charRows = {}
local new = Button(left, "+ New", 68, 24); new:SetPoint("TOPRIGHT", -14, -14)
local list = U.scroll(left, 0, 0, 0, 0)
-- Use an independent clipped viewport; no dependency on the guide layout.
list.scroll:ClearAllPoints(); list.scroll:SetPoint("TOPLEFT", 12, -76)
list.scroll:SetPoint("BOTTOMRIGHT", -12, 16) -- (the rows end at -14, level with + New)
local listEmpty = Label(left, "No sets yet.", 11, 16, -84)
listEmpty:SetWidth(left:GetWidth() - 32); listEmpty:SetJustifyH("LEFT"); left.empty = listEmpty
listEmpty:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
local rows, selected, draft, changing = {}, nil, nil, false
left.rows = rows
local ES -- the first-visit welcome card (built further down)
local draftOwner
local editingName = false

local header = CreateFrame("Frame", nil, right)
header:SetAllPoints(); header:SetFrameLevel(right:GetFrameLevel() + 12)
local name = CreateFrame("EditBox", nil, header, "BackdropTemplate")
name:SetAutoFocus(false); name:SetMaxLetters(60); name:SetHeight(28)
U.etch(name, styles.row, 10)
FGT.RegisterFont(name, "body", 12, "")
name:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3]); name:SetTextInsets(8, 8, 0, 0)
name:SetPoint("TOPLEFT", right, "TOPLEFT", 24, -24)
name:SetWidth(340)
local nameLabel = Label(header, "Set name", 10, 22, -6)
nameLabel:ClearAllPoints(); nameLabel:SetPoint("BOTTOMLEFT", name, "TOPLEFT", 0, 4)
-- The set's target level, under its name: the picker lists gear the character can wear at that
-- level (a ceiling: lower-level items always show). Type it, or scroll over it.
-- "Showing gear for level [min] – [max]": the set's level range. Max is the level the set plans
-- for (build.level; false = any, missing = 60 for older sets); min (build.minLevel) hides older
-- gear and is empty (any) by default. An empty box shows a muted "Min" or "Max".
local LV = {}
LV.label = U.font(header, 10); LV.label:SetText("Showing gear for level")
LV.label:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
LV.label:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -11)
function LV.Box(hint)
    local box = CreateFrame("EditBox", nil, header, "BackdropTemplate")
    box:SetAutoFocus(false); box:SetNumeric(true); box:SetMaxLetters(2); box:SetSize(34, 20)
    U.etch(box, styles.row, 10)
    FGT.RegisterFont(box, "body", 11, "")
    box:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3])
    box:SetJustifyH("CENTER"); box:SetTextInsets(2, 2, 0, 0)
    box:EnableMouseWheel(true)
    box.any = U.font(box, 10); box.any:SetPoint("CENTER"); box.any:SetText(hint)
    box.any:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    box:HookScript("OnTextChanged", function(self) self.any:SetShown((self:GetText() or "") == "" and not self:HasFocus()) end)
    box:HookScript("OnEditFocusGained", function(self) self.any:Hide() end)
    return box
end
LV.min = LV.Box("Min"); LV.min:SetPoint("LEFT", LV.label, "RIGHT", 6, 0)
LV.dash = U.font(header, 10); LV.dash:SetText("–"); LV.dash:SetPoint("LEFT", LV.min, "RIGHT", 6, 0)
LV.dash:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
LV.box = LV.Box("Max"); LV.box:SetPoint("LEFT", LV.dash, "RIGHT", 6, 0)
-- the room the sentence takes before the status line
function LV.Width() return (LV.label:GetStringWidth() or 120) + 34 + 6 + 12 + 6 + 34 + 6 end
local status = U.font(header, 10)
status:SetPoint("LEFT", LV.box, "RIGHT", 12, 0)
status:SetJustifyH("LEFT"); status:SetWordWrap(false)
local options = Button(header, "...", 30, 28)
options:SetPoint("TOPRIGHT", right, "TOPRIGHT", -16, -24)
local add = Button(header, "Add to Goals", 132)
add:SetPoint("RIGHT", options, "LEFT", -8, 0)
local viewGoal = Button(header, "View in Goals", 132)
viewGoal:SetPoint("RIGHT", options, "LEFT", -8, 0)
name:ClearAllPoints(); name:SetPoint("TOPLEFT", right, "TOPLEFT", 24, -24)
name:SetPoint("RIGHT", add, "LEFT", -16, 0)
local setTitle = U.font(header, 18)
setTitle:SetPoint("LEFT", name, "LEFT", 0, 0)
setTitle:SetPoint("RIGHT", add, "LEFT", -48, 0)
setTitle:SetWordWrap(false)
local editName = CreateFrame("Button", nil, header)
editName:SetSize(24, 28); editName:SetPoint("RIGHT", add, "LEFT", -16, 0)
FGT.IconButton(editName, "pencil-white", 14)
editName.icon:SetVertexColor(0.65, 0.65, 0.65)
editName:HookScript("OnEnter", function(self)
    self.icon:SetVertexColor(0.80, 0.62, 0.16)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Rename set", 1, 1, 1); GameTooltip:Show()
end)
editName:HookScript("OnLeave", function(self)
    self.icon:SetVertexColor(0.65, 0.65, 0.65); GameTooltip:Hide()
end)

-- The "..." menu: one button per action, laid out from what applies to the open set.
local actions = CreateFrame("Frame", nil, header, "BackdropTemplate")
actions:SetSize(176, 112); actions:SetPoint("TOPRIGHT", options, "BOTTOMRIGHT", 0, -6)
actions:SetFrameLevel(header:GetFrameLevel() + 20); actions:EnableMouse(true)
U.etch(actions, styles.panel); actions:Hide()
local rename = Button(actions, "Rename", 156)
local clear = Button(actions, "Clear items", 156)
local fill = Button(actions, "Fill from equipped", 156)
local duplicate = Button(actions, "Duplicate", 156)
local remove = Button(actions, "Remove from Goals", 156)
local delete = Button(actions, "Delete set", 156)
local cleared, clearedBuild, clearedItems, clearedProgress
local deleteArmed
options:SetScript("OnClick", function() deleteArmed = nil; actions:SetShown(not actions:IsShown()) end)
options:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Set options", 1, 1, 1); GameTooltip:Show()
end)
options:HookScript("OnLeave", function() GameTooltip:Hide() end)
local empty = Label(header, "Create a set to begin.", 14, 20, -100)
-- First visit: a way in that does not need the + New button on the other side of the screen.
local startNew = Button(header, "Create a set", 150); startNew:SetPoint("TOPLEFT", empty, "BOTTOMLEFT", 0, -12)
local startHunter = Button(header, "Hunter Pre-Raid BiS", 150); startHunter:SetPoint("LEFT", startNew, "RIGHT", 8, 0)

-- ------------------------------------------------------------
-- The character
-- ------------------------------------------------------------
local modelArea = CreateFrame("Frame", nil, right)
modelArea:SetPoint("TOPLEFT", 4, -4); modelArea:SetPoint("BOTTOMRIGHT", -4, 4)
modelArea:SetClipsChildren(true)
-- Blizzard Classic DressUpFrames.xml assembles a 318 x 383 background.
-- The right column is only 62 wide; equal quarters stretch its artwork.
local backgroundTiles = {
    { 0, 0, 256, 255 }, { 256, 0, 62, 255 },
    { 0, 255, 256, 128 }, { 256, 255, 62, 128 },
}
local _, race = UnitRace("player")
local background = CreateFrame("Frame", nil, modelArea)
background.race = race
background:SetAllPoints() -- child frame lets modelArea clip the cropped texture regions
for i = 1, 4 do
    local bg = background:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. (race or "Orc") .. i)
    -- Strictly black and white, like the goal art: no colour from the scenery.
    if bg.SetDesaturation then bg:SetDesaturation(1) end
    bg:SetDesaturated(true); bg:SetVertexColor(1, 1, 1)
    bg:SetAlpha(0.18)
    bg:SetPoint("TOPLEFT", modelArea, "TOPLEFT", 0, 0)
    -- Layout is set on resize so the quadrants remain a continuous background.
    modelArea["bg" .. i] = { texture = bg, rect = backgroundTiles[i] }
end
local model = CreateFrame("DressUpModel", nil, modelArea)
model:SetFrameLevel(background:GetFrameLevel() + 1)
if model.SetAutoDress then model:SetAutoDress(false) end
model:SetAllPoints(modelArea)
model:EnableMouse(true); model:EnableMouseWheel(true)
-- Above the model, only narrow lanes behind the labels: the slot columns (fixed width, strongest
-- at the panel edge, gone by the end of the names), the header and the weapon row. The character
-- itself is never dimmed, and zooming does not darken anything. Colours are the goal page's.
local textVeil = CreateFrame("Frame", nil, modelArea)
textVeil:SetAllPoints(); textVeil:SetFrameLevel(model:GetFrameLevel() + 1)
textVeil.SIDE, textVeil.TOP = { 0.012, 0.011, 0.008 }, { 0.02, 0.017, 0.012 } -- goal page's left and top shades
local textShades = {}
for i = 1, 4 do
    local t = textVeil:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(1, 1, 1, 1)
    textShades[i] = t
end
local function PaintTextVeil()
    local side, top = textVeil.SIDE, textVeil.TOP
    U.gradient(textShades[1], side, side, 0.6, 0)
    U.gradient(textShades[2], side, side, 0, 0.6)
    FGT.PopoutUI.vgradient(textShades[3], top, top, 0.7, 0)
    FGT.PopoutUI.vgradient(textShades[4], side, side, 0, 0.55)
end
PaintTextVeil()
-- The resting view is two wheel steps in (Karl, 2026-10-23: the full-body view sat too far
-- out); the wheel can still pull back to 0.
local MAX_ZOOM, REST_ZOOM = 1, 0.2
local zoom, facing, dragX = REST_ZOOM, 0, nil
local cameraAspect = 1
local selectedSlot
local slotButtons = {}
local camera = CreateFrame("Frame", nil, P)
-- Model-space offsets keep the drawing frame full-panel, avoiding clipped armor.
-- Positive Z raises the model; a small negative offset lowers focused armor.
local focusProfiles = {
    HeadSlot = {0.75, 0, -0.08},
    ShoulderSlot = {0.70, 0.32, 0.02}, ChestSlot = {0.58, 0, 0.28},
    ShirtSlot = {0.58, 0, 0.28}, TabardSlot = {0.50, 0, 0.35},
    WristSlot = {0.68, 0.40, 0.65}, HandsSlot = {0.68, 0.40, 0.78},
    WaistSlot = {0.60, 0, 0.65}, LegsSlot = {0.48, 0, 0.95},
    FeetSlot = {0.68, 0.18, 1.35}, BackSlot = {0.68, 0, 0.30},
}
-- Dwarf male has a shorter torso and lower hands than the general profile.
-- Tuned on Swagrid in the Forever beta; independent of other bodies.
local dwarfMaleFocus = {
    ChestSlot = {0.70, 0, 0.12}, ShirtSlot = {0.70, 0, 0.12},
    TabardSlot = {0.62, 0, 0.16}, BackSlot = {0.74, 0, 0.10},
    WristSlot = {0.68, 0.32, 0.30},
    HandsSlot = {0.64, 0.32, 0.31}, WaistSlot = {0.60, 0, 0.20},
    LegsSlot = {0.64, 0, 0.48}, FeetSlot = {0.66, 0.18, 0.66},
}
local offsetY, offsetZ, targetZoom, targetY, targetZ = 0, 0, REST_ZOOM, 0, 0
local function Ease(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end
-- Zoom drives two things: the portrait zoom up to 0.8, then the camera distance. Switching at a
-- single point changed the zoom speed suddenly there, so the hand-over is blended across 0.76 to
-- 0.84 (a smoothstep weight on the distance's share, integrated so both stay continuous). Outside
-- that range the values are exactly as before, so the tuned slot views (head 0.75, back 0.74 and
-- lower) frame the character as they did.
local function Handover(value)
    if value <= 0.76 then return 0 end
    if value >= 0.84 then return 0.04 + (value - 0.84) end
    local u = (value - 0.76) / 0.08
    return 0.08 * (u * u * u - u * u * u * u / 2)
end
local function ApplyZoom(value)
    zoom = value
    if background.PaintLight then background.PaintLight() end
    local shared = Handover(value)
    if model.SetCamDistanceScale then model:SetCamDistanceScale((1.3 - 2 * shared) * cameraAspect) end
    if model.SetPortraitZoom then model:SetPortraitZoom(value - shared) end
    if model.SetPosition then model:SetPosition(0, offsetY, offsetZ) end
end
local function MoveCamera(target, y, z, duration)
    local start, startY, startZ, elapsed = zoom, offsetY, offsetZ, 0
    targetZoom, targetY, targetZ = target, y, z
    camera:SetScript("OnUpdate", nil)
    if FGT.Setting("celebrations") == "off" then
        offsetY, offsetZ = y, z; ApplyZoom(target); return
    end
    camera:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / duration)
        local eased = Ease(t)
        offsetY = startY + (y - startY) * eased
        offsetZ = startZ + (z - startZ) * eased
        ApplyZoom(start + (target - start) * eased)
        if t == 1 then camera:SetScript("OnUpdate", nil) end
    end)
end
local turn = CreateFrame("Frame", nil, P)
local function TurnTo(target)
    turn:SetScript("OnUpdate", nil)
    -- Choose the shortest arc even after several manual rotations.
    local start = facing
    local delta = (target - start + math.pi) % (2 * math.pi) - math.pi
    -- Half-turns are equally short either way; use Karl's preferred direction.
    if math.abs(delta + math.pi) < 0.000001 then delta = math.pi end
    if FGT.Setting("celebrations") == "off" then
        facing = target; model:SetFacing(facing); return
    end
    local elapsed = 0
    turn:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / 0.65)
        facing = start + delta * Ease(t)
        model:SetFacing(facing)
        if t == 1 then turn:SetScript("OnUpdate", nil) end
    end)
end
local function Focus(slot)
    TurnTo(slot == "BackSlot" and math.pi or 0)
    local who = Who()
    local profile = who.race == "Dwarf" and who.sex ~= 3 and dwarfMaleFocus[slot]
        or focusProfiles[slot] or {REST_ZOOM, 0, 0}
    MoveCamera(profile[1], profile[2], profile[3], 0.55)
end
local function FadeIn(frame)
    frame:SetScript("OnUpdate", nil); frame:SetAlpha(1); frame:Show()
    if FGT.Setting("celebrations") == "off" then return end
    local elapsed = 0
    frame:SetAlpha(0)
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        self:SetAlpha(math.min(1, elapsed / 0.12))
        if elapsed >= 0.12 then self:SetScript("OnUpdate", nil) end
    end)
end
-- Dress the model with the planned items. Undress first, so removed items disappear.
local function PaintGear()
    if not model.TryOn then return end
    model:Undress()
    for _, id in ipairs(Cat.SLOT_ORDER) do
        local item = selected and Cat.Get(selected.slots[id])
        if item and not NO_MODEL[item.inv] then
            FGT.ItemInfo(item.id) -- request uncached item data before trying its appearance
            -- Weapons name their hand: without it the game puts a second one-hander in the main
            -- hand, replacing the first (a dual-wielding Rogue showed only the off-hand weapon).
            -- The enchant goes along, so weapon glows (Crusader, Fiery) show where the model draws them.
            local hand = id == 16 and "MAINHANDSLOT" or id == 17 and "SECONDARYHANDSLOT" or nil
            local e = selected and selected.enchants and Cat.Enchant(selected.enchants[id])
            if not pcall(model.TryOn, model, "item:" .. item.id, hand, e and e.effect or nil) then
                pcall(model.TryOn, model, "item:" .. item.id, hand)
            end
        end
    end
end
local appearance = CreateFrame("Frame", nil, P)
local appearanceAlpha, modelOwner = 1, nil
local function Dress(animate)
    appearance:SetScript("OnUpdate", nil)
    if not animate or FGT.Setting("celebrations") == "off" then
        PaintGear(); appearanceAlpha = 1; model:SetAlpha(1); return
    end
    local elapsed, swapped, startAlpha = 0, false, appearanceAlpha
    appearance:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 0.16 then
            appearanceAlpha = startAlpha + (0.30 - startAlpha) * Ease(elapsed / 0.16)
        else
            if not swapped then swapped = true; PaintGear() end
            appearanceAlpha = 0.30 + 0.70 * Ease(math.min(1, (elapsed - 0.16) / 0.24))
        end
        model:SetAlpha(appearanceAlpha)
        if elapsed >= 0.40 then appearance:SetScript("OnUpdate", nil) end
    end)
end
model:SetScript("OnModelLoaded", function() PaintGear(); ApplyZoom(zoom); model:SetFacing(facing) end)
-- Items the client had not loaded arrive later; repaint once for a burst of them.
P:HookScript("OnShow", function() P:RegisterEvent("GET_ITEM_INFO_RECEIVED") end)
P:HookScript("OnHide", function() P:UnregisterEvent("GET_ITEM_INFO_RECEIVED") end)
P:SetScript("OnEvent", function(_, _, itemId, ok)
    if ok == false or not P:IsShown() or not selected or P.itemRefreshPending then return end
    for _, id in pairs(selected.slots) do
        if id == itemId then
            P.itemRefreshPending = true
            C_Timer.After(0.1, function()
                P.itemRefreshPending = nil
                if P:IsShown() then Dress(false) end
            end)
            return
        end
    end
end)
local function Rotate()
    if not dragX then return end
    if not IsMouseButtonDown("LeftButton") then dragX = nil; model:SetScript("OnUpdate", nil); return end
    local x = GetCursorPosition()
    facing = facing + (x - dragX) * 0.01; dragX = x; model:SetFacing(facing)
end
model:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then
        turn:SetScript("OnUpdate", nil)
        if camera.onUse then camera.onUse() end
        dragX = GetCursorPosition(); model:SetScript("OnUpdate", Rotate)
    end
end)
model:SetScript("OnMouseUp", function() dragX = nil; model:SetScript("OnUpdate", nil) end)
-- The wheel glides: each frame the camera closes part of the remaining distance to where you have
-- scrolled (exponential ease-out), so quick clicks add up into one continuous move instead of
-- restarting a tween from a standstill each time. A slot focus in progress hands over without a
-- jump: its offsets glide on to their target from wherever they are.
-- (one shared step function: no allocation per click)
function camera.Glide(_, dt)
    local k = 1 - math.exp(-math.min(dt, 0.1) * 12) -- 12 per second: settles in about a third of a second
    local nextZoom = zoom + (targetZoom - zoom) * k
    offsetY = offsetY + (targetY - offsetY) * k
    offsetZ = offsetZ + (targetZ - offsetZ) * k
    if math.abs(targetZoom - nextZoom) < 0.0005 and math.abs(targetY - offsetY) < 0.0005
        and math.abs(targetZ - offsetZ) < 0.0005 then
        offsetY, offsetZ = targetY, targetZ
        ApplyZoom(targetZoom)
        camera:SetScript("OnUpdate", nil)
    else
        ApplyZoom(nextZoom)
    end
end
model:SetScript("OnMouseWheel", function(_, delta)
    if camera.onUse then camera.onUse() end
    targetZoom = math.max(0, math.min(MAX_ZOOM, targetZoom + delta * 0.1))
    if FGT.Setting("celebrations") == "off" then
        camera:SetScript("OnUpdate", nil); offsetY, offsetZ = targetY, targetZ; ApplyZoom(targetZoom); return
    end
    camera:SetScript("OnUpdate", camera.Glide)
end)

-- Goal-art treatment belongs below the character and equipment controls.
-- Keep the same panel colors/top veil, with broad side fades and an eased bottom.
-- A soft light behind the character (the goal banners' Media/glow, additive, neutral white so the
-- scenery stays black and white): one behind the body, a faint pool at the feet. Drawn above the
-- scenery and under the shading, so the edges stay dark; still, never animated. When zoomed, the
-- camera centres what is focused, so the light grows there and the floor pool fades with the feet.
-- On by default; /goals plannerlight switches it (Prefs().light == false is off).
background.light = background:CreateTexture(nil, "BORDER")
background.pool = background:CreateTexture(nil, "BORDER")
for _, t in ipairs({ background.light, background.pool }) do
    t:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
    t:SetBlendMode("ADD"); t:SetVertexColor(1, 1, 1)
end
function background.PaintLight()
    -- (layout can run before the saved data loads: the light is on until a saved choice says off)
    local on = not ForeverGoalTrackerDB or Prefs().light ~= false
    local w, h = modelArea:GetWidth() or 0, modelArea:GetHeight() or 0
    background.light:SetShown(on and h > 0); background.pool:SetShown(on and h > 0)
    if not on or h <= 0 then return end
    local closer = math.max(0, (zoom or REST_ZOOM) - REST_ZOOM) -- measured from the resting view
    local grow = 1 + closer * 0.6
    background.light:ClearAllPoints(); background.light:SetPoint("CENTER", model, "CENTER", 0, h * 0.06)
    background.light:SetSize(math.min(w, h * 0.62 * grow), h * 0.85 * grow)
    background.light:SetAlpha(0.09)
    background.pool:ClearAllPoints(); background.pool:SetPoint("CENTER", model, "CENTER", 0, -h * 0.22)
    background.pool:SetSize(math.min(w, h * 0.42), h * 0.09)
    background.pool:SetAlpha(math.max(0, 0.07 * (1 - closer * 2)))
end
function FGT.TogglePlannerLight()
    local pref = Prefs()
    pref.light = pref.light == false
    background.PaintLight()
    print("Forever Goal Tracker: Gear Planner light " .. (pref.light and "on" or "off") .. ".")
end
local shades = {}
for i = 1, 27 do
    shades[i] = background:CreateTexture(nil, "OVERLAY")
    shades[i]:SetColorTexture(1, 1, 1, 1)
end
-- The dressing-room scenery has no darkening of its own, unlike the goal art (which bakes a wide
-- dark gradient into its side and a soft fade into its bottom 11%). These layers, under the
-- character, build the same look: dark sides (both, since slots sit on both), the goal page's top
-- fade, and a bottom that eases to near-black charcoal rather than to solid.
local function ShadeBackground(w, h)
    local side, top, floor = textVeil.SIDE, textVeil.TOP, styles.panel.bottom
    for i = 1, 2 do
        local t = shades[i]
        t:ClearAllPoints(); t:SetWidth(w * 0.34) -- reaches in close to the character
        t:SetPoint(i == 1 and "TOPLEFT" or "TOPRIGHT", modelArea)
        t:SetPoint(i == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT", modelArea)
        U.gradient(t, side, side, i == 1 and 1 or 0, i == 1 and 0 or 1)
    end
    local band = shades[3]
    band:ClearAllPoints(); band:SetPoint("TOPLEFT", modelArea); band:SetPoint("TOPRIGHT", modelArea)
    band:SetHeight(h * 0.28)
    FGT.PopoutUI.vgradient(band, top, top, 0.65, 0)
    local height = math.max(60, math.min(110, h * 0.12))
    for i = 1, 24 do
        local t = shades[i + 3]
        local p1, p2 = (i - 1) / 24, i / 24
        local y = h - height + height * p1
        t:ClearAllPoints(); t:SetPoint("TOPLEFT", modelArea, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", modelArea, "TOPRIGHT", 0, -y)
        t:SetHeight(height / 24)
        FGT.PopoutUI.vgradient(t, floor, floor, 0.92 * p1 * p1 * (3 - 2 * p1), 0.92 * p2 * p2 * (3 - 2 * p2))
    end
end
local function LayoutPreview(self, w, h)
    if w <= 0 or h <= 0 then return end
    -- One uniform scale for every tile; crop the assembled picture as a unit.
    local scale = math.max(w / 318, h / 383)
    local x, y = (w - 318 * scale) / 2, (h - 383 * scale) / 2
    for i = 1, 4 do
        local b = self["bg" .. i]
        local r = b.rect
        b.texture:ClearAllPoints()
        b.texture:SetPoint("TOPLEFT", self, "TOPLEFT", x + r[1] * scale, -y - r[2] * scale)
        b.texture:SetSize(r[3] * scale, r[4] * scale)
    end
    -- Draw across the full panel: a narrow model frame slices enlarged geometry.
    -- Compensate camera distance for its wider aspect instead of clipping the model.
    cameraAspect = math.max(1, w / h / 0.85)
    ShadeBackground(w, h)
    background.PaintLight()
    if textVeil.Place then textVeil.Place() end
    ApplyZoom(zoom)
end
modelArea:SetScript("OnSizeChanged", LayoutPreview)

-- ------------------------------------------------------------
-- Equipment slots
-- ------------------------------------------------------------
local controls = CreateFrame("Frame", nil, right)
controls:SetAllPoints(); controls:SetFrameLevel(model:GetFrameLevel() + 3)
local slots = {
    {"HeadSlot", "Head", "LEFT", 1}, {"NeckSlot", "Neck", "LEFT", 2},
    {"ShoulderSlot", "Shoulders", "LEFT", 3}, {"BackSlot", "Back", "LEFT", 4},
    {"ChestSlot", "Chest", "LEFT", 5}, {"ShirtSlot", "Shirt", "LEFT", 6},
    {"TabardSlot", "Tabard", "LEFT", 7}, {"WristSlot", "Wrists", "LEFT", 8},
    {"HandsSlot", "Hands", "RIGHT", 1}, {"WaistSlot", "Waist", "RIGHT", 2},
    {"LegsSlot", "Legs", "RIGHT", 3}, {"FeetSlot", "Feet", "RIGHT", 4},
    {"Finger0Slot", "Finger 1", "RIGHT", 5}, {"Finger1Slot", "Finger 2", "RIGHT", 6},
    {"Trinket0Slot", "Trinket 1", "RIGHT", 7}, {"Trinket1Slot", "Trinket 2", "RIGHT", 8},
    {"MainHandSlot", "Main Hand", "BOTTOM", 1},
    {"SecondaryHandSlot", "Off Hand", "BOTTOM", 2},
    {"RangedSlot", "Ranged", "BOTTOM", 3},
    {"QuiverSlot", "Quiver", "BOTTOM", 4},
    {"AmmoSlot", "Ammo", "BOTTOM", 5},
}
-- Paladins, Druids and Shamans keep a relic (Libram, Idol, Totem) in the ranged slot.
local function SlotLabel(slot)
    local class = Who().class
    if slot == "RangedSlot" and Cat.UsesRelic(class) then return "Relic" end
    for _, spec in ipairs(slots) do if spec[1] == slot then return spec[2] end end
    return slot
end
local function SlotTexture(slot)
    local class = Who().class
    if slot == "RangedSlot" and Cat.UsesRelic(class) then return "Interface\\PaperDoll\\UI-PaperDoll-Slot-Relic" end
    return FGT.GearPlannerSlotTexture(slot)
end
local slotSpec = {}
-- Enchants: each slot has a smaller square between the item and its name, shown when the
-- planned item can take an enchant on this client. A build keeps them as
-- `enchants = { [slot number] = enchant spell id }`. EN.mode: the picker lists enchants.
local EN = { mode = false, EMPTY = "Interface\\PaperDoll\\UI-Backpack-EmptySlot", SCALE = 0.62 }
-- Library goals: an item that a Library goal rewards (Thunderfury, Atiesh) or that is a piece of a
-- Library set carries a gold goal mark. Clicking it opens the same goal card the guides' gold
-- links open: "Open goal" when it is in My Goals, "+ Add to My Goals" when it is not.
local LG = { ICON = FGT.Icon("link-white") }
-- (both values: the goal, and "reward" or "set")
function LG.For(itemId)
    if itemId then return Cat.GoalFor(itemId, Who().faction) end
end
function LG.Active(goal) return FGT.IsGoalActive and FGT.IsGoalActive(goal) or false end
function LG.Label(goal) return goal.short or goal.name end
function LG.Tooltip(owner, goal, kind)
    local A = FGT.GOAL_RGB or { 0.95, 0.75, 0.30 }
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(goal.name, A[1], A[2], A[3])
    GameTooltip:AddLine(kind == "set" and "A Library set goal" or "A Library goal", 0.8, 0.75, 0.65)
    local active = LG.Active(goal)
    GameTooltip:AddLine(active and "In My Goals" or "Not in My Goals yet", 0.8, 0.75, 0.65)
    GameTooltip:AddLine(active and "Click: open the goal" or "Click: see the goal and add it",
        colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
    GameTooltip:Show()
end
-- The requirement as the game states it, red when it is above the set's level.
function LG.TooHigh(item) return item.req > 1 and item.req > (selected and selected.level or 60) end
function LG.ReqText(item)
    if item.req <= 1 then return "No level requirement" end
    return LG.TooHigh(item) and ("|cffff5a4aReq " .. item.req .. "|r") or ("Req " .. item.req)
end
function LG.Open(goal) if goal and FGT.OpenLinkCard then GameTooltip:Hide(); FGT.OpenLinkCard(goal.id) end end
-- The name sits past the enchant square when it shows.
function EN.Anchor(button)
    local spec, ench = slotSpec[button.plannerSlot], button.enchant
    local gap = ench.planned and (ench:GetWidth() + 4) or 0
    button.itemName:ClearAllPoints()
    if spec[3] == "RIGHT" then button.itemName:SetPoint("RIGHT", button, "LEFT", -8 - gap, 0)
    else button.itemName:SetPoint("LEFT", button, "RIGHT", 8 + gap, 0) end
    if button.nameWidth then button.itemName:SetWidth(math.max(30, button.nameWidth - gap)) end
end
-- Enchants only stay on a planned item that can take them.
function EN.Prune(build)
    if not (build and build.enchants) then return end
    for slot, spell in pairs(build.enchants) do
        if not Cat.EnchantFits(spell, Cat.Get(build.slots[slot])) then build.enchants[slot] = nil end
    end
    if next(build.enchants) == nil then build.enchants = nil end
end
for _, spec in ipairs(slots) do
    slotSpec[spec[1]] = spec
    local button = Button(controls, "", 44, 44)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3); button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.plannerSlot = spec[1]
    button.icon:SetTexture(FGT.GearPlannerSlotTexture(spec[1]))
    button.itemName = U.font(button, 11)
    button.itemName:SetText(""); button.itemName:SetWordWrap(false)
    button.itemName:SetShadowColor(0, 0, 0, 1); button.itemName:SetShadowOffset(1, -1)
    if spec[3] == "LEFT" or spec[3] == "BOTTOM" then
        -- every slot reads the same way: icon, then its name on one line
        button.itemName:SetPoint("LEFT", button, "RIGHT", 8, 0)
        button.itemName:SetJustifyH("LEFT")
    elseif spec[3] == "RIGHT" then
        button.itemName:SetPoint("RIGHT", button, "LEFT", -8, 0)
        button.itemName:SetJustifyH("RIGHT")
    end
    slotButtons[spec[1]] = button
    local ench = Button(controls, "", 27, 27)
    ench.icon = ench:CreateTexture(nil, "ARTWORK")
    ench.icon:SetPoint("TOPLEFT", 2, -2); ench.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    ench.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    ench:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ench.plannerSlot, ench.planned = spec[1], false
    ench:Hide()
    button.enchant = ench
end
local function LayoutSlots()
    local available = math.max(1, right:GetHeight() - 152)
    local size = math.min(44, available / 8 - 4)
    size = math.max(20, size)
    if controls.hint then controls.hint:ClearAllPoints(); controls.hint:SetPoint("BOTTOM", right, "BOTTOM", 0, 18 + size + 12) end
    -- The bottom row has three to five cells: ammo only for classes that shoot, a quiver only for Hunters.
    local class = Who().class
    local ammo, quiver = Cat.UsesAmmo(class), Cat.UsesQuiver(class)
    slotButtons.AmmoSlot:SetShown(ammo)
    slotButtons.QuiverSlot:SetShown(quiver)
    local cells = 3 + (ammo and 1 or 0) + (quiver and 1 or 0)
    for _, spec in ipairs(slots) do
        local button = slotButtons[spec[1]]
        button:SetSize(size, size); button:ClearAllPoints()
        if spec[3] == "BOTTOM" then
            -- Three equal cells across the bottom; each holds the icon and its name, shortened with "..." if long.
            local cell = math.max(110, math.min(240, ((right:GetWidth() or 600) - 44) / cells))
            button.nameWidth = cell - size - 20
            local at = spec[4] - ((spec[1] == "AmmoSlot" and not quiver) and 1 or 0)
            button:SetPoint("BOTTOMLEFT", right, "BOTTOM", (at - 1 - cells / 2) * cell + 8, 18)
        else
            button.nameWidth = math.max(40, math.min(160, (right:GetWidth() - size * 2 - 100) / 3))
            button:SetPoint("TOP" .. spec[3], right, "TOP" .. spec[3],
                spec[3] == "LEFT" and 22 or -22, -88 - (spec[4] - 1) * (size + 4))
        end
        local ench, small = button.enchant, math.floor(size * EN.SCALE + 0.5)
        ench:SetSize(small, small); ench:ClearAllPoints()
        if spec[3] == "RIGHT" then ench:SetPoint("RIGHT", button, "LEFT", -4, 0)
        else ench:SetPoint("LEFT", button, "RIGHT", 4, 0) end
        EN.Anchor(button)
    end
    if textVeil.Place then textVeil.Place() end
end
-- The label lanes follow the slot layout: icon, enchant square and name, then a short fade.
function textVeil.Place()
    local w, h = modelArea:GetWidth() or 0, modelArea:GetHeight() or 0
    local head = slotButtons.HeadSlot
    local size = head and head:GetWidth() or 44
    local lane = 22 + size + 4 + math.floor(size * EN.SCALE + 0.5) + 8 + (head and head.nameWidth or 120) + 16
    lane = math.max(60, math.min(lane, w * 0.45))
    for i = 1, 2 do
        local t = textShades[i]
        t:ClearAllPoints(); t:SetWidth(lane)
        t:SetPoint(i == 1 and "TOPLEFT" or "TOPRIGHT", modelArea)
        t:SetPoint(i == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT", modelArea)
    end
    local top, bottom = textShades[3], textShades[4]
    top:ClearAllPoints(); top:SetPoint("TOPLEFT", modelArea); top:SetPoint("TOPRIGHT", modelArea)
    top:SetHeight(math.min(92, h * 0.2)) -- the set name and level row
    bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", modelArea); bottom:SetPoint("BOTTOMRIGHT", modelArea)
    bottom:SetHeight(math.min(18 + size + 34, h * 0.25)) -- the weapon row and its hint
end
right:HookScript("OnSizeChanged", function(self)
    left.Fit()
    LayoutSlots()
    -- 64: the level label and box; the Library goal link takes its own room
    if LG.PaintHeader then LG.PaintHeader() else status:SetWidth(math.max(80, (self:GetWidth() or 0) - 48 - LV.Width())) end
end)
local head = slotButtons.HeadSlot
local hint = U.font(controls, 10)
hint:SetText("Drag to rotate · Scroll to zoom"); hint:SetPoint("BOTTOM", right, "BOTTOM", 0, 76)
-- One line of stage help above the weapon row, clear of the character: the next step while the set
-- is empty, otherwise how to turn and zoom, until the first drag or scroll.
controls.hint = hint
function hint.Paint(prompt)
    hint.prompt = prompt
    if prompt then hint:SetText("Choose a slot to start building your set.")
    else hint:SetText("Drag to rotate · Scroll to zoom") end
    hint:SetShown(prompt or not camera.used)
end
function camera.onUse() camera.used = true; hint:SetShown(hint.prompt or false) end
-- helper text, muted like the goal pages' hints so it never competes with the character
hint:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])

-- ------------------------------------------------------------
-- The item picker: search, filters and a recycled list
-- ------------------------------------------------------------
local PICKER_W = 304
local picker = CreateFrame("Frame", nil, controls, "BackdropTemplate")
picker:SetPoint("TOPLEFT", head, "TOPRIGHT", 10, 0)
picker:SetFrameLevel(controls:GetFrameLevel() + 5)
picker:EnableMouse(true)
picker:SetWidth(PICKER_W); picker:SetHeight(400); U.etch(picker, styles.panel); picker:Hide()
local search = SearchBox(picker, "Search items or sets")
search:SetPoint("TOPLEFT", 12, -12); search:SetPoint("TOPRIGHT", -12, -12)
-- Filters: labeled dropdowns that say what they show (a stat, an armor or weapon type, a
-- quality). The list is always best first and always what the set's character can wear at its
-- target level, so there is no Usable or Sort switch. Choices use false for "any".
local FL = { LIMIT = 25, expanded = false, rows = {} }
FL.QUALITY = { { 0, "Any quality" }, { 2, "Uncommon+" }, { 3, "Rare+" }, { 4, "Epic+" } }
FL.STAT = { { false, "Any stat" } }
for _, st in ipairs(Cat.STATS) do FL.STAT[#FL.STAT + 1] = { st[1], st[2] } end
-- One shared popup lists a dropdown's choices under it.
FL.popup = CreateFrame("Frame", nil, picker, "BackdropTemplate")
FL.popup:SetFrameLevel(picker:GetFrameLevel() + 20); FL.popup:EnableMouse(true)
U.etch(FL.popup, styles.panel); FL.popup:Hide()
picker:HookScript("OnHide", function() FL.popup:Hide() end)
function FL.Paint(b)
    local label = b.choices[1] and b.choices[1][2] or ""
    for _, c in ipairs(b.choices) do if c[1] == b.value then label = c[2] end end
    b.text:SetText(label)
    b.chosen = b.choices[1] ~= nil and b.value ~= b.choices[1][1]
    PaintButton(b)
end
function FL.Open(b)
    local popup, width = FL.popup, math.max(b:GetWidth(), 140)
    popup.owner = b
    for i, c in ipairs(b.choices) do
        local row = FL.rows[i]
        if not row then
            row = Button(popup, "", width - 8, 22, 10); FL.rows[i] = row
            row.text:ClearAllPoints(); row.text:SetPoint("LEFT", 8, 0); row.text:SetJustifyH("LEFT")
            row:SetScript("OnClick", function(self)
                local owner = popup.owner
                popup:Hide(); owner.value = self.value; FL.Paint(owner); owner.onPick(self.value)
            end)
        end
        row:SetWidth(width - 8); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 24)
        row.value = c[1]; row.text:SetText(c[2]); row.chosen = c[1] == b.value; PaintButton(row); row:Show()
    end
    for i = #b.choices + 1, #FL.rows do FL.rows[i]:Hide() end
    popup:SetSize(width, #b.choices * 24 + 8)
    popup:ClearAllPoints(); popup:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
    popup:Show()
end
function FL.Dropdown(tip)
    local b = Button(picker, "", 90, 22, 10)
    b.text:ClearAllPoints(); b.text:SetPoint("LEFT", 8, 0); b.text:SetPoint("RIGHT", -18, 0)
    b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false)
    b.caret = b:CreateTexture(nil, "OVERLAY")
    b.caret:SetTexture(FGT.Icon("chevron")); b.caret:SetSize(10, 10); b.caret:SetPoint("RIGHT", -6, 0)
    b.choices, b.value = {}, false
    b:SetScript("OnClick", function(self)
        if FL.popup:IsShown() and FL.popup.owner == self then FL.popup:Hide() else FL.Open(self) end
    end)
    b:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(tip, 1, 1, 1); GameTooltip:Show()
    end)
    b:HookScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end
FL.stat = FL.Dropdown("Only items with this stat, best first")
FL.kind = FL.Dropdown("Armor or weapon type")
FL.quality = FL.Dropdown("Lowest item quality shown")
FL.stat.choices, FL.quality.choices = FL.STAT, FL.QUALITY
-- The visible dropdowns share the row evenly.
function FL.Layout()
    local shown = {}
    for _, b in ipairs({ FL.stat, FL.kind, FL.quality }) do if b:IsShown() then shown[#shown + 1] = b end end
    local width = (PICKER_W - 24 - 4 * (#shown - 1)) / math.max(1, #shown)
    for i, b in ipairs(shown) do
        b:SetWidth(width); b:ClearAllPoints()
        if i == 1 then b:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -6)
        else b:SetPoint("LEFT", shown[i - 1], "RIGHT", 4, 0) end
    end
end
-- Footer: Forever's Revealed only on the left; the count or Show all on the right.
FL.revealed = Button(picker, "Revealed only", 104, 18, 9)
FL.revealed:SetPoint("BOTTOMLEFT", 12, 8)
FL.revealed:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Hide items Forever has not revealed yet", 1, 1, 1)
    GameTooltip:Show()
end)
FL.revealed:HookScript("OnLeave", function() GameTooltip:Hide() end)
FL.showAll = Button(picker, "", 110, 18, 9)
FL.showAll:SetPoint("BOTTOMRIGHT", -12, 8)
local pickerList = U.scroll(picker, 0, 0, 0, 0)
pickerList.scroll:ClearAllPoints()
pickerList.scroll:SetPoint("TOPLEFT", FL.stat, "BOTTOMLEFT", 0, -8)
pickerList.scroll:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -20, 30)
local pickerNote = Label(picker, "", 10, 12, -380)
pickerNote:ClearAllPoints(); pickerNote:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", 12, 10)
pickerNote:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -12, 10)
pickerNote:SetJustifyH("LEFT"); pickerNote:SetWordWrap(false)
pickerNote:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
local noResults = Label(picker, "", 11, 14, -96)
noResults:SetWidth(PICKER_W - 40); noResults:SetJustifyH("LEFT")
noResults:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
local found, foundCount, resultRows = {}, 0, {}
local menu = CreateFrame("Frame", nil, controls, "BackdropTemplate")
menu:SetSize(170, 108); menu:SetPoint("TOPLEFT", head, "TOPRIGHT", 8, 0)
U.etch(menu, styles.panel); menu:Hide()
menu:SetFrameLevel(controls:GetFrameLevel() + 5); menu:EnableMouse(true)
local function Deselect()
    GameTooltip:Hide()
    selectedSlot = nil; EN.mode = false; picker:Hide(); menu:Hide(); search:ClearFocus()
    for _, button in pairs(slotButtons) do
        button.chosen = false; PaintButton(button)
        button.enchant.chosen = false; PaintButton(button.enchant)
    end
end
local clickAway = CreateFrame("Frame", nil, P)
P:HookScript("OnShow", function() clickAway:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
P:HookScript("OnHide", function() clickAway:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
clickAway:SetScript("OnEvent", function()
    if actions:IsShown() and not actions:IsMouseOver() and not options:IsMouseOver() then actions:Hide() end
    if FL.popup:IsShown() and not FL.popup:IsMouseOver() and not (FL.popup.owner and FL.popup.owner:IsMouseOver()) then
        FL.popup:Hide()
    end
    if charMenu:IsShown() and not charMenu:IsMouseOver() and not ownerBtn:IsMouseOver() then charMenu:Hide() end
    if not selectedSlot then return end
    if picker:IsShown() and picker:IsMouseOver() then return end
    if menu:IsShown() and menu:IsMouseOver() then return end
    if slotButtons[selectedSlot] and slotButtons[selectedSlot]:IsMouseOver() then return end
    if slotButtons[selectedSlot] and slotButtons[selectedSlot].enchant:IsMouseOver() then return end
    Deselect()
end)
local replace = Button(menu, "Replace", 150); replace:SetPoint("TOPLEFT", 10, -8)
local unequip = Button(menu, "Unequip", 150); unequip:SetPoint("TOPLEFT", 10, -40)
-- Third action: the item's Library goal (open or add it), or, for any other item, its own goal.
LG.menuBtn = Button(menu, "", 150, 28, 11); LG.menuBtn:SetPoint("TOPLEFT", 10, -72)
LG.menuBtn.text:SetWidth(140); LG.menuBtn.text:SetWordWrap(false); LG.menuBtn.text:SetJustifyH("CENTER")
-- A Library goal gets the guides' gold: gold text and border, and the picker's goal mark.
LG.menuBtn.mark = LG.menuBtn:CreateTexture(nil, "OVERLAY")
LG.menuBtn.mark:SetTexture(LG.ICON); LG.menuBtn.mark:SetSize(12, 12); LG.menuBtn.mark:Hide()
local Refresh, Results, PickSet

-- A short line for the set: how much of it is planned, and the average item level.
local function Summary(build)
    local count, scored, total = 0, 0, 0
    for _, slot in ipairs(Cat.SLOT_ORDER) do
        local item = Cat.Get(build.slots[slot])
        if item then
            count = count + 1
            -- shirts, tabards, quivers and ammo say nothing about a set's strength
            if slot ~= 0 and slot ~= 4 and slot ~= 19 and slot ~= 20 then scored = scored + 1; total = total + item.ilvl end
        end
    end
    if count == 0 then return nil end
    local class = Who().class
    local slotsShown = 19 + (Cat.UsesAmmo(class) and 1 or 0) + (Cat.UsesQuiver(class) and 1 or 0)
    return string.format("%d of %d slots", count, slotsShown)
        .. (scored > 0 and string.format(" · average item level %d", math.floor(total / scored + 0.5)) or "")
end
local function GoalProgressText(build)
    local goal = build.goalId and FGT.GoalById(build.goalId)
    if not (goal and ForeverGoalTrackerDB.active[build.goalId]) then return nil end
    local done, progress = 0, ForeverGoalTrackerDB.progress[build.goalId] or {}
    for i = 1, #goal.steps do if progress[i] then done = done + 1 end end
    return done, #goal.steps
end

local pendingGoal
-- Typing a name should not rebuild the goals list on every letter.
local function RefreshGoalSoon(goal)
    if pendingGoal then pendingGoal = goal or pendingGoal; return end
    pendingGoal = goal or true
    C_Timer.After(0.35, function()
        local g = pendingGoal ~= true and pendingGoal or nil
        pendingGoal = nil
        FGT.RefreshPlannerGoals(g)
    end)
end
-- immediate: item changes refresh the goal list now; renames can wait for a pause in typing.
local function Save(immediate)
    if not selected then return end
    local value = (name:GetText() or ""):match("^%s*(.-)%s*$")
    if value == "" and selected.id then
        status:SetText("Enter a set name."); status:SetAlpha(1); return
    end
    selected.name = value
    EN.Prune(selected)
    if value ~= "" and draft == selected then
        local store = Store(); selected.id = store.nextId; store.nextId = store.nextId + 1
        store.builds[#store.builds + 1] = selected; store.selected = selected.id; draft = nil
    end
    if selected.tracked then
        local goal = SyncGoal(selected, PlanKey())
        if immediate then FGT.RefreshPlannerGoals(goal) else RefreshGoalSoon(goal) end
    end
    status:SetAlpha(1)
end
local function Choose(build)
    actions:Hide(); cleared, clearedBuild, clearedItems, clearedProgress = nil, nil, nil, nil
    selected = build; changing = true; name:SetText(build and build.name or ""); changing = false
    editingName = false
    Deselect(); Focus(false)
    LayoutSlots()
    local who = Who()
    if modelOwner ~= who.key then
        modelOwner = who.key; model:SetUnit("player")
        -- another character: their race on the model where the game allows it (SetCustomRace
        -- takes 0 male, 1 female); otherwise this character's model wears their gear
        if not who.me and model.SetCustomRace and RACE_IDS[who.race or ""] then
            pcall(model.SetCustomRace, model, RACE_IDS[who.race], who.sex == 3 and 1 or 0)
        end
        if background.race ~= who.race and who.race then
            background.race = who.race
            for i = 1, 4 do modelArea["bg" .. i].texture:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. who.race .. i) end
        end
        model:SetFacing(facing); Dress()
    else
        Dress(true)
    end
    LayoutPreview(modelArea, modelArea:GetWidth(), modelArea:GetHeight())
    status:SetText(""); status:SetAlpha(1)
    Refresh()
end

-- ------------------------------------------------------------
-- Picker rows (a small pool rebound as the list scrolls)
-- ------------------------------------------------------------
local FOREVER_BLUE = { 0.40, 0.65, 1 }
-- Plan an enchant on the selected slot's item.
function EN.Pick(e)
    if not (selected and selectedSlot and e) then return end
    selected.enchants = selected.enchants or {}
    selected.enchants[slotIds[selectedSlot]] = e.spell
    Dress(true); Save(true); Deselect(); Refresh()
end
local function PickItem(item)
    if item and item.spell then return EN.Pick(item) end
    if not selected or not selectedSlot or not item then return end
    local id = slotIds[selectedSlot]
    local moved = false
    if item.unique then
        for other, itemId in pairs(selected.slots) do
            if other ~= id and itemId == item.id then selected.slots[other] = nil; moved = true end
        end
    end
    if item.twoHand then selected.slots[17] = nil end
    if id == 17 then
        local main = Cat.Get(selected.slots[16])
        if main and main.twoHand then selected.slots[16] = nil end
    end
    selected.slots[id] = item.id
    Dress(true); Save(true); Deselect(); Refresh()
    if moved then status:SetText("Moved item to the selected slot.") end
end
-- Plan every piece of a game item set at once; pieces that do not fit are skipped.
PickSet = function(anchor)
    if not selected or not anchor or anchor.set <= 0 then return end
    local taken, count = {}, 0
    for _, item in ipairs(Cat.SetItems(anchor.set)) do
        local slot = Cat.SlotFor(item, taken)
        if slot and not taken[slot] then
            taken[slot] = true; count = count + 1
            selected.slots[slot] = item.id
            if item.twoHand then selected.slots[17] = nil; taken[17] = true end
        end
    end
    Dress(true); Save(true); Deselect(); Refresh()
    status:SetText(count > 0 and ("Added " .. count .. " pieces of " .. (Cat.SetName(anchor.set) or "the set") .. ".")
        or "That set has no pieces for this planner yet.")
end
-- The item tooltip goes on whichever side of the picker faces away from the character.
local function PlaceBesidePicker(tip)
    local px, rx = picker:GetCenter(), right:GetCenter()
    if px and rx and px > rx then tip:SetPoint("TOPRIGHT", picker, "TOPLEFT", -8, 0)
    else tip:SetPoint("TOPLEFT", picker, "TOPRIGHT", 8, 0) end
end
-- An enchant row: its short name, then what it does and how it is applied.
function EN.BindRow(row, e)
    row.icon:SetTexture(Cat.EnchantIcon(e))
    row.text:SetText(e.short); row.text:SetTextColor(1, 1, 1)
    row.quality = nil
    row.chosen = selected and selectedSlot and selected.enchants
        and selected.enchants[slotIds[selectedSlot]] == e.spell or false
    local effect = (e.text ~= "" and e.text ~= e.short) and (e.text .. " · ") or ""
    row.source:SetText((row.chosen and "|T" .. FGT.Icon("check") .. ":10:10|t " or "") .. effect .. Cat.EnchantSource(e))
    row.entrance = nil; row.pin:Hide(); row.setBtn:Hide(); row.goal = nil; row.goalBtn:Hide()
    row.text:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    PaintButton(row)
    row:Show()
end
-- Enchant tooltip: name, effect, how it is applied and what it costs.
function EN.Tooltip(owner, e, hint, place)
    GameTooltip:SetOwner(owner, place and "ANCHOR_NONE" or "ANCHOR_RIGHT")
    if place then GameTooltip:ClearAllPoints(); place(GameTooltip) end
    GameTooltip:SetText(e.name, 1, 1, 1)
    if e.text ~= "" and e.text ~= e.short then GameTooltip:AddLine(e.text, 0.12, 1, 0, true) end
    GameTooltip:AddLine(Cat.EnchantSource(e), 0.8, 0.75, 0.65)
    if e.enchanting then
        for _, r in ipairs(e.reagents) do
            local itemName = FGT.ItemInfo(r[1])
            GameTooltip:AddLine(r[2] .. " x " .. (itemName or ("item " .. r[1])), 0.8, 0.75, 0.65)
        end
    end
    if hint then GameTooltip:AddLine(hint, colors.TITLE[1], colors.TITLE[2], colors.TITLE[3]) end
    GameTooltip:Show()
end
local function BindRow(row, item, index)
    row.item = item
    row:ClearAllPoints(); row:SetPoint("TOPLEFT", pickerList.content, "TOPLEFT", 0, -(index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", pickerList.content, "TOPRIGHT", 0, -(index - 1) * ROW_H)
    if item.spell then return EN.BindRow(row, item) end
    row.icon:SetTexture(item.icon)
    row.text:SetText(item.name)
    local c = QUALITY[item.q] or QUALITY[1]
    row.text:SetTextColor(c[1], c[2], c[3])
    row.quality = item.q
    row.chosen = selected and selectedSlot and selected.slots[slotIds[selectedSlot]] == item.id
    local state = FGT.isForever and Cat.ForeverStatus(item)
    local statText = Prefs().stat and Cat.StatText(item, Prefs().stat)
    local line = (statText and (statText .. " · ") or "")
        .. (item.forever == 3 and "" or ("iLvl " .. item.ilvl .. " · ")) .. LG.ReqText(item)
    local sourceLine = Cat.SourceLabel(item)
    if state == "hidden" or item.forever == 3 then sourceLine = sourceLine .. " · Not revealed yet" end
    row.source:SetText((row.chosen and "|T" .. FGT.Icon("check") .. ":10:10|t " or "")
        .. (state == "new" and "|cff66a6ffNew in Forever|r · " or state == "updated" and "|cff66a6ffUpdated in Forever|r · " or "")
        .. line .. " · " .. sourceLine)
    local source = Cat.Source(item)
    local entrance = source and source.place and Cat.EntranceFor(source.place)
    row.entrance = entrance
    row.pin:SetShown(entrance ~= nil)
    row.setBtn:SetShown(item.set > 0 and Cat.SetName(item.set) ~= nil)
    -- the goal mark sits left of the map pin; the name makes room for whichever show
    row.goal, row.goalKind = LG.For(item.id)
    row.goalBtn:SetShown(row.goal ~= nil)
    row.goalBtn:ClearAllPoints()
    row.goalBtn:SetPoint("TOPRIGHT", entrance and -28 or -6, -4)
    row.text:SetPoint("RIGHT", row, "RIGHT", -8 - (entrance and 22 or 0) - (row.goal and 22 or 0), 0)
    PaintButton(row)
    row:Show()
end
local function Rebind()
    local first = math.floor((pickerList.scroll:GetVerticalScroll() or 0) / ROW_H)
    for i, row in ipairs(resultRows) do
        local item = found[first + i]
        if item then BindRow(row, item, first + i) else row.item = nil; row:Hide() end
    end
end
local function EnsureRows(count)
    for i = #resultRows + 1, count do
        local row = Button(pickerList.content, "", 200, ROW_H - 2)
        resultRows[i] = row
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(30, 30); row.icon:SetPoint("LEFT", 6, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 44, -7); row.text:SetPoint("RIGHT", row, "RIGHT", -28, 0)
        row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(false)
        row.source = U.font(row, 9); row.source:SetPoint("TOPLEFT", 44, -25); row.source:SetPoint("RIGHT", row, "RIGHT", -48, 0)
        row.source:SetJustifyH("LEFT"); row.source:SetWordWrap(false)
        row.source:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
        -- Fills every piece of the item's set (Dragonstalker, Lightforge, ...) in one click.
        row.setBtn = Button(row, "+ Set", 38, 16, 9)
        row.setBtn:SetPoint("BOTTOMRIGHT", -6, 5)
        row.setBtn:SetScript("OnClick", function() if row.item then PickSet(row.item) end end)
        row.setBtn:HookScript("OnEnter", function()
            local item = row.item
            if not item then return end
            GameTooltip:SetOwner(row.setBtn, "ANCHOR_TOP")
            GameTooltip:SetText("Add the whole set", 1, 1, 1)
            GameTooltip:AddLine(Cat.SetName(item.set) or "", 0.8, 0.75, 0.65)
            GameTooltip:Show()
        end)
        row.setBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
        row.setBtn:Hide()
        -- Entrance pin: sets the map pin for the dungeon or raid the item comes from.
        row.pin = CreateFrame("Button", nil, row)
        row.pin:SetSize(18, 18); row.pin:SetPoint("TOPRIGHT", -6, -4)
        row.pin.tex = row.pin:CreateTexture(nil, "ARTWORK")
        row.pin.tex:SetAllPoints(); row.pin.tex:SetTexture(FGT.Icon("map-location-white") or FGT.Icon("map-location"))
        row.pin.tex:SetVertexColor(0.65, 0.65, 0.65)
        row.pin:SetScript("OnEnter", function(self)
            self.tex:SetVertexColor(0.80, 0.62, 0.16)
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Show entrance on map", 1, 1, 1)
            if row.entrance then GameTooltip:AddLine(row.entrance.name .. ", " .. (row.entrance.zone or ""), 0.8, 0.75, 0.65) end
            GameTooltip:Show()
        end)
        row.pin:SetScript("OnLeave", function(self) self.tex:SetVertexColor(0.65, 0.65, 0.65); GameTooltip:Hide() end)
        row.pin:SetScript("OnClick", function() if row.entrance then FGT.ShowNpcOnMap(row.entrance.id) end end)
        row.pin:Hide()
        -- Goal mark: this item has a Library goal (gold, like the guides' goal links).
        row.goalBtn = CreateFrame("Button", nil, row)
        row.goalBtn:SetSize(18, 18)
        row.goalBtn.tex = row.goalBtn:CreateTexture(nil, "ARTWORK")
        row.goalBtn.tex:SetAllPoints(); row.goalBtn.tex:SetTexture(LG.ICON)
        local A = FGT.GOAL_RGB or { 0.95, 0.75, 0.30 }
        row.goalBtn.tex:SetVertexColor(A[1], A[2], A[3], 0.85)
        row.goalBtn:SetScript("OnEnter", function(self)
            self.tex:SetVertexColor(A[1], A[2], A[3], 1)
            if row.goal then LG.Tooltip(self, row.goal, row.goalKind) end
        end)
        row.goalBtn:SetScript("OnLeave", function(self) self.tex:SetVertexColor(A[1], A[2], A[3], 0.85); GameTooltip:Hide() end)
        row.goalBtn:SetScript("OnClick", function() LG.Open(row.goal) end)
        row.goalBtn:Hide()
        row:SetScript("OnClick", function(self, button)
            local item = self.item
            if not item then return end
            if item.spell then if button ~= "RightButton" then EN.Pick(item) end return end
            -- Shift-click links, right-click opens Wowhead, Ctrl-click tries it on: same as step items.
            if FGT.StepLinkClick({ itemId = item.id, text = { GetText = function() return item.name end } }, button) then return end
            PickItem(item)
        end)
        row:SetScript("OnEnter", function(self) self.hovered = true; Hover(self, true); PaintButton(self) end)
        row:SetScript("OnLeave", function(self) self.hovered = false; Hover(self, false); PaintButton(self) end)
        -- Only the thumbnail opens the item tooltip, beside the picker so it never covers the list.
        row.thumb = CreateFrame("Frame", nil, row)
        row.thumb:SetAllPoints(row.icon); row.thumb:EnableMouse(true)
        row.thumb:SetScript("OnMouseUp", function(_, button) row:GetScript("OnClick")(row, button) end)
        row.thumb:SetScript("OnLeave", function() row:GetScript("OnLeave")(row); GameTooltip:Hide() end)
        row.thumb:SetScript("OnEnter", function()
            row:GetScript("OnEnter")(row)
            local item = row.item
            if not item then return end
            if item.spell then return EN.Tooltip(row.thumb, item, "Click: plan this enchant", PlaceBesidePicker) end
            FGT.ShowItemTip(row.thumb, item.id, nil, item.name, false, function(tip)
                tip:AddLine(" ")
                tip:AddLine(Cat.SourceLabel(item), 0.8, 0.75, 0.65, true)
                local set = Cat.SetName(item.set)
                if set then tip:AddLine("Part of " .. set, 0.8, 0.75, 0.65) end
                if FGT.isForever and Cat.ForeverStatus(item) == "hidden" then
                    tip:AddLine("Not revealed in Forever yet", 1.00, 0.50, 0.42)
                end
                tip:AddLine("Click: plan this item", colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
            end, PlaceBesidePicker)
        end)
        row:Hide()
    end
end

-- The set's target level: a ceiling for what it plans (sets from before levels were added are 60).
-- The set's max level as a number (60 for "any" and for older sets: armor types and red flags
-- compare against it), the ceiling for the picker (nil for any) and its floor (nil for any).
function FL.Level() return selected and selected.level or 60 end
function FL.MaxLevel() if selected and selected.level == false then return nil end return FL.Level() end
function FL.MinLevel() return selected and selected.minLevel or nil end
-- Items already planned in this character's sets come first in an unsearched list.
function FL.First()
    local first = {}
    for _, build in ipairs(Store().builds) do
        for _, id in pairs(build.slots or {}) do first[id] = true end
    end
    return first
end
-- What every search in this slot shares, before the stat, type and text are chosen.
function FL.Options()
    local who = Who()
    return { class = who.class, faction = who.faction, usable = true, level = FL.MaxLevel(), minLevel = FL.MinLevel(),
        minQuality = Prefs().quality or 0,
        ammo = selected and (selectedSlot == "AmmoSlot" and Cat.AmmoFor(Cat.Get(selected.slots[18]))
            or selectedSlot == "QuiverSlot" and Cat.QuiverFor(Cat.Get(selected.slots[18]))) or nil,
        revealedOnly = FGT.isForever and Prefs().revealed or nil }
end
-- The type dropdown lists only the types this slot really offers; a remembered choice that no
-- longer fits (another level, another class) falls back to any.
function FL.SetupKind()
    local types = Cat.TypesFor(selectedSlot, FL.Options())
    local armor = true
    for _, sub in ipairs(types) do if sub < 401 or sub > 404 then armor = false end end
    local choices = { { false, armor and "Any armor" or "Any type" } }
    local remembered = (Prefs().kinds or {})[selectedSlot]
    local value = false
    for _, sub in ipairs(types) do
        choices[#choices + 1] = { sub, Cat.TYPE_NAMES[sub] }
        if sub == remembered then value = sub end
    end
    FL.kind.choices, FL.kind.value = choices, value
    FL.kind:SetShown(#types > 0)
end
local function PaintFilters()
    local pref = Prefs()
    FL.stat.value = pref.stat or false; FL.Paint(FL.stat)
    FL.quality.value = pref.quality or 0; FL.Paint(FL.quality)
    FL.Paint(FL.kind)
    FL.revealed.text:SetText((pref.revealed and "|T" .. FGT.Icon("check") .. ":10:10|t " or "") .. "Revealed only")
    FL.revealed.chosen = pref.revealed and true or false; PaintButton(FL.revealed)
end
-- The picker's enchant list for the selected slot's planned item.
function EN.Results(keepScroll)
    local item = selected and Cat.Get(selected.slots[slotIds[selectedSlot]])
    Cat.SearchEnchants(item, search:GetText(), found)
    local count = #found
    foundCount = count
    pickerList.content:SetHeight(math.max(1, count * ROW_H))
    if not keepScroll then pickerList.scroll:SetVerticalScroll(0) end
    EnsureRows(POOL_ROWS)
    pickerList:Finalize(); pickerList:Update(); Rebind()
    local text = search:GetText() or ""
    noResults:SetText(count == 0 and (text == "" and "No enchants for this item." or "No matching enchants.") or "")
    pickerNote:SetText(count == 0 and "" or (count .. (count == 1 and " enchant" or " enchants") .. " · Right-click the square to remove"))
end
-- Filters belong to items; the enchant list starts right under the search.
function EN.PaintMode()
    FL.stat:SetShown(not EN.mode); FL.quality:SetShown(not EN.mode)
    if EN.mode then FL.kind:Hide() end
    FL.revealed:SetShown(not EN.mode and FGT.isForever and true or false)
    FL.showAll:Hide(); FL.popup:Hide()
    FL.Layout()
    search.hint:SetText(EN.mode and "Search enchants" or "Search items or sets")
    pickerList.scroll:ClearAllPoints()
    pickerList.scroll:SetPoint("TOPLEFT", EN.mode and search or FL.stat, "BOTTOMLEFT", 0, -8)
    pickerList.scroll:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -20, 30)
    pickerNote:ClearAllPoints()
    if EN.mode then
        pickerNote:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", 12, 10); pickerNote:SetJustifyH("LEFT")
    else
        pickerNote:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -12, 10); pickerNote:SetJustifyH("RIGHT")
    end
    pickerNote:SetWidth(PICKER_W - (EN.mode and 24 or 140))
end
Results = function(keepScroll)
    if not selectedSlot then return end
    if EN.mode then return EN.Results(keepScroll) end
    local pref, text = Prefs(), search:GetText() or ""
    local opts = FL.Options()
    opts.stat, opts.kind, opts.text, opts.first = pref.stat or nil, FL.kind.value or nil, text, FL.First()
    local _, count = Cat.Search(selectedSlot, opts, found)
    -- An unsearched slot starts with its best few; Show all and search reach everything.
    local limited = text == "" and not FL.expanded and count > FL.LIMIT
    if limited then for i = #found, FL.LIMIT + 1, -1 do found[i] = nil end end
    foundCount = #found
    pickerList.content:SetHeight(math.max(1, foundCount * ROW_H))
    if not keepScroll then pickerList.scroll:SetVerticalScroll(0) end
    EnsureRows(POOL_ROWS)
    pickerList:Finalize(); pickerList:Update(); Rebind()
    local filtered = pref.stat or FL.kind.value or (pref.quality or 0) > 0 or (FGT.isForever and pref.revealed)
    noResults:SetText(count == 0 and ((text == "" and ("Nothing for this slot " .. LV.RangeText() .. ".")
        or "No matching items.") .. (filtered and "\nTry Any stat, Any type or Any quality." or "")) or "")
    FL.showAll.text:SetText("Show all " .. count)
    FL.showAll:SetShown(limited)
    pickerNote:SetText((limited or count == 0) and "" or (count .. (count == 1 and " item" or " items")))
end
-- Keep rows bound while scrolling (the scroll area calls Update on every move).
do
    local baseUpdate = pickerList.Update
    local lastFirst
    function pickerList:Update()
        baseUpdate(self)
        local first = math.floor((self.scroll:GetVerticalScroll() or 0) / ROW_H)
        if first ~= lastFirst then lastFirst = first; Rebind() end
    end
end
search:HookScript("OnTextChanged", function() Results(false) end)
search:SetScript("OnEscapePressed", Deselect)
search:SetScript("OnEnterPressed", function() if found[1] then PickItem(found[1]) end end)
FL.stat.onPick = function(value) Prefs().stat = value or nil; FL.expanded = false; PaintFilters(); Results() end
FL.quality.onPick = function(value) Prefs().quality = value; FL.expanded = false; FL.SetupKind(); PaintFilters(); Results() end
FL.kind.onPick = function(value)
    local pref = Prefs()
    pref.kinds = pref.kinds or {}
    pref.kinds[selectedSlot] = value or nil
    FL.expanded = false; PaintFilters(); Results()
end
FL.revealed:SetScript("OnClick", function()
    Prefs().revealed = not Prefs().revealed; FL.SetupKind(); PaintFilters(); FL.Layout(); Results()
end)
FL.showAll:SetScript("OnClick", function() FL.expanded = true; Results(true) end)

local function PositionPopup(frame)
    local button = slotButtons[selectedSlot]
    if not button then return end
    local spec = slotSpec[selectedSlot]
    frame:ClearAllPoints()
    local edge = spec[4] >= 5 and "BOTTOM" or "TOP"
    if spec[3] == "BOTTOM" then
        frame:SetPoint("BOTTOM", button, "TOP", 0, 8)
    elseif spec[3] == "RIGHT" then
        frame:SetPoint(edge .. "RIGHT", button, edge .. "LEFT", -10, 0)
    else
        frame:SetPoint(edge .. "LEFT", button, edge .. "RIGHT", 10, 0)
    end
end
-- One size and place for every slot: from under the set header down to just above the weapon
-- row. Only the side changes, so the list never shrinks because of where a slot sits.
local PICKER_TOP = 84
local function PlacePicker()
    local spec, size = slotSpec[selectedSlot], slotButtons[selectedSlot]:GetWidth() or 44
    local room = (right:GetHeight() or 600) - PICKER_TOP - (18 + size + 16)
    picker:SetHeight(math.max(PICKER_MIN, math.min(PICKER_MAX, room)))
    picker:ClearAllPoints()
    if spec[3] == "LEFT" then picker:SetPoint("TOPLEFT", right, "TOPLEFT", 22 + size + 10, -PICKER_TOP)
    elseif spec[3] == "RIGHT" then picker:SetPoint("TOPRIGHT", right, "TOPRIGHT", -(22 + size + 10), -PICKER_TOP)
    else picker:SetPoint("TOP", right, "TOP", 0, -PICKER_TOP) end
end
local function OpenPicker()
    if not selectedSlot then return end
    if not EN.mode then slotButtons[selectedSlot].chosen = true; PaintButton(slotButtons[selectedSlot]) end
    GameTooltip:Hide(); menu:Hide()
    FL.expanded = false
    if not EN.mode then FL.SetupKind() end
    PlacePicker(); FadeIn(picker); search:SetText("")
    PaintFilters(); EN.PaintMode(); Results(); Focus(selectedSlot)
end

-- ------------------------------------------------------------
-- Slot buttons
-- ------------------------------------------------------------
for _, spec in ipairs(slots) do
    local slot = spec[1]
    local button = slotButtons[slot]
    button:SetScript("OnClick", function()
        Deselect(); selectedSlot = slot; button.chosen = true; PaintButton(button)
        if selected and selected.slots[slotIds[slot]] then
            LG.PaintMenu(); PositionPopup(menu); FadeIn(menu); Focus(slot)
        else OpenPicker() end
    end)
    button:SetScript("OnEnter", function(self)
        self.hovered = true; Hover(self, true)
        self.icon:SetAlpha(1)
        PaintButton(self)
        if selectedSlot == slot and (menu:IsShown() or picker:IsShown()) then return end
        local item = selected and Cat.Get(selected.slots[slotIds[slot]])
        if item then
            FGT.ShowItemTip(self, item.id, nil, item.name, false, function(tip)
                tip:AddLine(" "); tip:AddLine(Cat.SourceLabel(item), 0.8, 0.75, 0.65, true)
                if LG.TooHigh(item) then
                    tip:AddLine("Requires level " .. item.req .. ". This set plans for level " .. (selected and selected.level or 60) .. ".", 1, 0.35, 0.29, true)
                end
                local goal = LG.For(item.id)
                if goal then
                    local A = FGT.GOAL_RGB or { 0.95, 0.75, 0.30 }
                    tip:AddLine("Library goal: " .. goal.name .. (LG.Active(goal) and " (in My Goals)" or ""), A[1], A[2], A[3], true)
                end
            end)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local shown = SlotLabel(slot)
            self.itemName:SetText(shown); self.itemName:SetTextColor(0.8, 0.75, 0.65)
            GameTooltip:SetText(shown, 1, 1, 1); GameTooltip:AddLine("Choose item", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self.hovered = false; Hover(self, false)
        PaintButton(self)
        self.icon:SetAlpha(selected and selected.slots[slotIds[slot]] and 1 or 0.65)
        if not (selected and selected.slots[slotIds[slot]]) then self.itemName:SetText("") end
        GameTooltip:Hide()
    end)
    -- Click: choose the enchant; right-click: remove it.
    local ench = button.enchant
    ench:SetScript("OnClick", function(self, mouse)
        if not selected then return end
        if mouse == "RightButton" then
            if selected.enchants and selected.enchants[slotIds[slot]] then
                selected.enchants[slotIds[slot]] = nil
                Deselect(); Dress(true); Save(true); Refresh()
            end
            return
        end
        Deselect(); selectedSlot = slot; EN.mode = true
        self.chosen = true; PaintButton(self)
        OpenPicker()
    end)
    ench:SetScript("OnEnter", function(self)
        self.hovered = true; Hover(self, true); PaintButton(self)
        if EN.mode and selectedSlot == slot and picker:IsShown() then return end
        local e = selected and selected.enchants and Cat.Enchant(selected.enchants[slotIds[slot]])
        if e then
            EN.Tooltip(self, e, "Click: change · Right-click: remove")
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Enchant", 1, 1, 1); GameTooltip:AddLine("Choose enchant", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    ench:SetScript("OnLeave", function(self)
        self.hovered = false; Hover(self, false); PaintButton(self); GameTooltip:Hide()
    end)
end
-- The slot's planned item: its Library goal, or a gear set of its own made from it (build.single).
function LG.Item() return selected and selectedSlot and Cat.Get(selected.slots[slotIds[selectedSlot]]) end
function LG.Solo(itemId)
    for _, build in ipairs(Store().builds) do
        if build.single == itemId and build.goalId and ForeverGoalTrackerDB.active[build.goalId] then return build end
    end
end
function LG.PaintMenu()
    local b, item = LG.menuBtn, LG.Item()
    local goal = item and LG.For(item.id)
    local A = FGT.GOAL_RGB or { 0.95, 0.75, 0.30 }
    if goal then
        b.text:SetText((LG.Active(goal) and "Open " or "+ Add ") .. LG.Label(goal) .. " goal")
        b.text:SetTextColor(A[1], A[2], A[3])
        -- the mark sits just left of the centred label
        b.mark:ClearAllPoints()
        b.mark:SetPoint("RIGHT", b, "CENTER", -math.min(64, (b.text:GetStringWidth() or 100) / 2) - 4, 0)
        b.mark:SetVertexColor(A[1], A[2], A[3]); b.mark:Show()
        b.text:ClearAllPoints(); b.text:SetPoint("CENTER", 8, 0)
    else
        b.text:SetText(item and LG.Solo(item.id) and "View in Goals" or "Track this item")
        b.text:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3])
        b.mark:Hide()
        b.text:ClearAllPoints(); b.text:SetPoint("CENTER")
    end
    b.chosen = goal ~= nil -- the gold border
    PaintButton(b)
end
LG.menuBtn:HookScript("OnEnter", function(self)
    local item = LG.Item()
    local goal, kind = nil, nil
    if item then goal, kind = LG.For(item.id) end
    if goal then return LG.Tooltip(self, goal, kind) end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(item and LG.Solo(item.id) and "View in Goals" or "Track this item", 1, 1, 1)
    GameTooltip:AddLine("Its own card in My Goals, with your character's art. It stays in this set too.", 0.8, 0.75, 0.65, true)
    GameTooltip:Show()
end)
LG.menuBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
LG.menuBtn:SetScript("OnClick", function()
    local item, current = LG.Item(), selected
    if not (item and current) then return end
    GameTooltip:Hide()
    local goal = LG.For(item.id)
    local solo = not goal and LG.Solo(item.id)
    local open = (goal and LG.Active(goal) and goal.id) or (solo and solo.goalId)
    local slot = slotIds[selectedSlot]
    Deselect()
    if open then FGT.ShowTab("tracker"); FGT.SelectGoal(open); return end
    if goal then
        FGT.SetGoalActive(goal, true)
        Refresh(); status:SetText("Added the " .. LG.Label(goal) .. " goal to My Goals.")
        return
    end
    -- its own gear set: the item (and its enchant), at this set's level, tracked at once
    local store = Store()
    local build = { id = store.nextId, name = item.name, slots = { [slot] = item.id }, level = current.level,
        single = item.id, tracked = true }
    local spell = current.enchants and current.enchants[slot]
    if spell then build.enchants = { [slot] = spell } end
    store.nextId = store.nextId + 1
    store.builds[#store.builds + 1] = build
    local own = SyncGoal(build, PlanKey())
    if own then ForeverGoalTrackerDB.active[own.id] = true; FGT.RefreshPlannerGoals(own) end
    Refresh(); status:SetText(item.name .. " is now its own goal in My Goals.")
end)
replace:SetScript("OnClick", OpenPicker)
unequip:SetScript("OnClick", function()
    if selected and selectedSlot then selected.slots[slotIds[selectedSlot]] = nil; Dress(true); Save(true); Refresh() end
    Deselect()
end)

-- ------------------------------------------------------------
-- Set list and header state
-- ------------------------------------------------------------
local menuY
local function Place(button, show)
    button:SetShown(show)
    if show then button:ClearAllPoints(); button:SetPoint("TOPLEFT", 10, -menuY); menuY = menuY + 34 end
end
Refresh = function()
    local store = Store()
    local who = Who()
    local color = who.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[who.class]
    owner:SetText((color and color.colorStr and ("|c" .. color.colorStr) or "") .. (who.name or "") .. "|r")
    ownerBtn:SetWidth(owner:GetStringWidth() + 26)
    for _, row in ipairs(rows) do row:Hide() end
    local visible = 0
    for _, build in ipairs(store.builds) do
        if build.name ~= "" then
            visible = visible + 1
            local i = visible
            local row = rows[i]
            if not row then row = Button(list.content, "", 180, 48); rows[i] = row
                row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 10, -7)
                row.state = U.font(row, 9); row.state:SetPoint("TOPLEFT", 10, -28)
            end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 2, -(i - 1) * 54)
            -- as wide as the + New button above, to its right edge
            row:SetWidth(math.max(120, left:GetWidth() - 28))
            row.text:SetWidth(math.max(100, left:GetWidth() - 48))
            row.text:SetText(build.name ~= "" and build.name or "Name your set")
            local done, total = GoalProgressText(build)
            row.state:SetText(done and ("In My Goals · " .. done .. "/" .. total) or "Draft")
            row.chosen = build == selected
            PaintButton(row)
            row:SetScript("OnClick", function() store.selected = build.id; Choose(build) end); row:Show()
        end
    end
    listEmpty:SetShown(visible == 0)
    list.content:SetHeight(math.max(1, visible * 54)); list:Finalize(); list:Update()
    empty:Hide(); startNew:Hide(); startHunter:Hide() -- replaced by the welcome card
    if ES.Paint then ES.Paint() end
    local editing = selected ~= nil and (editingName or selected.name == "")
    name:SetShown(editing); nameLabel:SetShown(editing)
    setTitle:SetText(selected and selected.name or "")
    setTitle:SetShown(selected ~= nil and not editing)
    editName:SetShown(selected ~= nil and not editing)
    modelArea:Show(); controls:SetShown(selected ~= nil)
    local tracked = selected and selected.goalId and ForeverGoalTrackerDB.active[selected.goalId]
    status:SetAlpha(1)
    if not selected then
        status:SetText("")
    else
        local summary = Summary(selected)
        local done, total = GoalProgressText(selected)
        if tracked then
            status:SetText("In My Goals · " .. (done or 0) .. " of " .. (total or 0) .. " collected" .. (summary and (" · " .. summary) or ""))
        elseif not summary then
            status:SetText("")
        else
            status:SetText((selected.name ~= "" and "Draft · Not in Goals" or "Name your set before adding it.") .. " · " .. summary)
        end
    end
    if hint.Paint then hint.Paint(selected ~= nil and not tracked and not Summary(selected)) end
    add:SetShown(selected ~= nil and not tracked)
    viewGoal:SetShown(tracked and true or false)
    local canAdd = selected ~= nil and next(selected.slots) ~= nil
    add:SetEnabled(canAdd)
    add.chosen = canAdd
    PaintButton(add)
    add.text:SetAlpha(canAdd and 1 or 0.4)
    options:SetShown(selected ~= nil)
    if LG.PaintHeader then LG.PaintHeader() end
    for _, part in ipairs({ LV.label, LV.min, LV.dash, LV.box }) do part:SetShown(selected ~= nil) end
    LV.Show()
    -- menu: only what applies, stacked from the top
    menuY = 8
    Place(rename, true)
    clear.text:SetText(clearedBuild == selected and "Undo clear" or "Clear items")
    Place(clear, true)
    Place(fill, Who().me) -- only the logged-in character's worn gear can be read
    Place(duplicate, selected ~= nil and selected.id ~= nil)
    Place(remove, tracked and true or false)
    delete.text:SetText(deleteArmed and "Click again to delete" or "Delete set")
    Place(delete, selected ~= nil and selected.id ~= nil)
    actions:SetHeight(menuY + 4)
    for slot, button in pairs(slotButtons) do
        local item = selected and Cat.Get(selected.slots[slotIds[slot]])
        button.icon:SetTexture(item and item.icon or SlotTexture(slot))
        -- a planned item this set's level can't wear yet: its level in red before the name
        button.itemName:SetText(item and ((LG.TooHigh(item) and ("|cffff5a4aLv " .. item.req .. "|r  ") or "") .. item.name) or "")
        local c = item and QUALITY[item.q]
        if c then button.itemName:SetTextColor(c[1], c[2], c[3]) end
        button.quality = item and item.q or nil
        button.icon:SetAlpha((item or button.chosen) and 1 or 0.65)
        PaintButton(button)
        local ench = button.enchant
        local can = item ~= nil and Cat.CanEnchant(item)
        local e = can and selected and selected.enchants and Cat.Enchant(selected.enchants[slotIds[slot]])
        ench.planned = can and true or false
        ench:SetShown(ench.planned)
        ench.icon:SetTexture(e and Cat.EnchantIcon(e) or EN.EMPTY)
        ench.icon:SetAlpha(e and 1 or 0.55)
        PaintButton(ench)
        EN.Anchor(button)
    end
end

-- The Library set behind the planned pieces (two or more from one set): a gold link at the right
-- of the level row, opening that set's goal card (Open goal, or + Add to My Goals).
LG.header = CreateFrame("Button", nil, header)
LG.header:SetHeight(20); LG.header:SetPoint("RIGHT", right, "TOPRIGHT", -16, -68)
LG.header.text = U.font(LG.header, 10); LG.header.text:SetPoint("RIGHT")
do
    local A = FGT.GOAL_RGB or { 0.95, 0.75, 0.30 }
    LG.header.text:SetTextColor(A[1], A[2], A[3])
end
LG.header:SetScript("OnEnter", function(self) if self.goal then LG.Tooltip(self, self.goal, "set") end end)
LG.header:SetScript("OnLeave", function() GameTooltip:Hide() end)
LG.header:SetScript("OnClick", function(self) LG.Open(self.goal) end)
LG.header:Hide()
function LG.PaintHeader()
    local counts, best, most = {}, nil, 1
    for _, id in pairs(selected and selected.slots or {}) do
        local goal, kind = LG.For(id)
        if goal and kind == "set" then
            counts[goal] = (counts[goal] or 0) + 1
            if counts[goal] > most then best, most = goal, counts[goal] end
        end
    end
    LG.header.goal = best
    LG.header:SetShown(best ~= nil)
    local room = 0
    if best then
        LG.header.text:SetText("Library goal: " .. LG.Label(best))
        local width = (LG.header.text:GetStringWidth() or 120) + 4
        LG.header:SetWidth(width); room = width + 12
    end
    status:SetWidth(math.max(80, (right:GetWidth() or 0) - 48 - LV.Width() - room))
end

-- The level range: typed (Enter or leaving the box keeps it, an empty box is any) or scrolled.
-- Scrolling past the ends reaches any: min below 1, max above 60. The box being changed stops at
-- the other one (Karl: min can never pass max): min 30 with max 10 becomes 10, and the max can't
-- drop below the min. Only the edited box changes, so clicking from one box to the other never
-- leaves a stale number behind.
function LV.Show()
    if not LV.min:HasFocus() then LV.min:SetText(selected and selected.minLevel and tostring(selected.minLevel) or "") end
    if not LV.box:HasFocus() then LV.box:SetText(FL.MaxLevel() and tostring(FL.MaxLevel()) or "") end
    for _, box in ipairs({ LV.min, LV.box }) do box.any:SetShown((box:GetText() or "") == "" and not box:HasFocus()) end
end
function LV.RangeText()
    local low, high = FL.MinLevel(), FL.MaxLevel()
    if low and high then return low == high and ("at level " .. low) or ("for levels " .. low .. " to " .. high) end
    if high then return "up to level " .. high end
    if low then return "from level " .. low .. " up" end
    return "at any level"
end
local function Clamp(n) return n and math.max(1, math.min(60, math.floor(n))) or nil end
-- min, max: numbers or nil (any)
function LV.Apply(low, high)
    if not selected then return end
    low, high = Clamp(low), Clamp(high)
    if low and high and low > high then
        if LV.changing == "min" then low = high else high = low end
    end
    local level = high or false
    local changed = selected.minLevel ~= low or selected.level ~= level
    selected.minLevel, selected.level = low, level
    LV.Show()
    if not changed then return end
    Save(true); Refresh()
    if selectedSlot and picker:IsShown() and not EN.mode then
        FL.expanded = false; FL.SetupKind(); PaintFilters(); FL.Layout(); Results()
    end
end
-- kept for older callers: set the max
function LV.Set(level) LV.changing = "max"; LV.Apply(FL.MinLevel(), level) end
function LV.Commit(which)
    LV.changing = which
    local typed = tonumber((which == "min" and LV.min or LV.box):GetText() or "")
    if which == "min" then LV.Apply(typed, FL.MaxLevel()) else LV.Apply(FL.MinLevel(), typed) end
end
for which, box in pairs({ min = LV.min, max = LV.box }) do
    box:SetScript("OnEnterPressed", function(self) LV.Commit(which); self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); LV.Show() end)
    box:SetScript("OnEditFocusLost", function() LV.Commit(which) end)
    box:SetScript("OnMouseWheel", function(_, delta)
        if not selected then return end
        LV.changing = which
        if which == "min" then
            local n = (FL.MinLevel() or 0) + (delta > 0 and 1 or -1)
            LV.Apply(n >= 1 and n or nil, FL.MaxLevel())
        else
            local n = (FL.MaxLevel() or 61) + (delta > 0 and 1 or -1)
            LV.Apply(FL.MinLevel(), n <= 60 and n or nil)
        end
    end)
    box:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        if which == "min" then
            GameTooltip:SetText("Lowest level", 1, 1, 1)
            GameTooltip:AddLine("Hides gear for lower levels. Leave it empty to show everything below the highest level.", 0.8, 0.75, 0.65, true)
        else
            GameTooltip:SetText("Highest level", 1, 1, 1)
            GameTooltip:AddLine("The level this set plans for: gear needing a higher level is left out. Leave it empty for every level.", 0.8, 0.75, 0.65, true)
        end
        GameTooltip:AddLine("Type a level, or scroll to change it", colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
        GameTooltip:Show()
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- ------------------------------------------------------------
-- Set actions
-- ------------------------------------------------------------
add:SetScript("OnClick", function()
    if not selected or not next(selected.slots) then return end
    if selected.name == "" then name:SetFocus(); return end
    name:ClearFocus(); actions:Hide()
    selected.tracked = true
    local goal = SyncGoal(selected, PlanKey())
    if not goal then return end
    ForeverGoalTrackerDB.active[goal.id] = true
    FGT.RefreshPlannerGoals(goal); Refresh()
end)
viewGoal:SetScript("OnClick", function()
    if not (selected and selected.goalId) then return end
    FGT.ShowTab("tracker"); FGT.SelectGoal(selected.goalId)
end)
new:SetScript("OnClick", function() draft = { name = "", slots = {}, level = math.max(1, math.min(60, Who().level or 60)) }; draftOwner = PlanKey(); Choose(draft); editingName = true; Refresh(); name:SetFocus() end)
startNew:SetScript("OnClick", function() new:GetScript("OnClick")() end)
startHunter:SetScript("OnClick", function() FGT.CreateHunterPreRaidBuild() end)

-- ------------------------------------------------------------
-- First visit: the welcome card
-- ------------------------------------------------------------
-- With no set open, the planner leads with the character: the same lit, black-and-white scene,
-- wearing what they wear now (the logged-in character; another character shows their race).
-- A card on the left side (free of slots, already on the dark side fade) says what the planner
-- does once, and offers one gold way in, plus starting from current gear and a fitting preset.
ES = ES or {}
ES.card = CreateFrame("Frame", nil, right, "BackdropTemplate")
ES.card:SetFrameLevel(header:GetFrameLevel() + 6); ES.card:EnableMouse(true)
U.etch(ES.card, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
ES.WIDTH = 300
ES.card:SetWidth(ES.WIDTH)
ES.title = U.title(ES.card, 18); ES.title:SetText("Plan your gear")
ES.title:SetPoint("TOPLEFT", 22, -22)
ES.body = U.font(ES.card, 11)
ES.body:SetText("Choose the items you want for each slot, see them on your character, and track them as a goal.")
ES.body:SetPoint("TOPLEFT", ES.title, "BOTTOMLEFT", 0, -10); ES.body:SetWidth(256)
ES.body:SetJustifyH("LEFT"); ES.body:SetWordWrap(true)
ES.body:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
ES.create = Button(ES.card, "Create a gear set", 256, 32, 12)
ES.create.chosen = true; PaintButton(ES.create) -- the gold border: the one obvious way in
ES.create.text:SetTextColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
ES.current = Button(ES.card, "Start from my current gear", 256, 28, 11)
ES.preset = Button(ES.card, "", 256, 24, 10)
ES.preset.text:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
ES.create:SetScript("OnClick", function() new:GetScript("OnClick")() end)
-- a set already filled from what you wear, named so it saves at once (rename it any time)
ES.current:SetScript("OnClick", function()
    new:GetScript("OnClick")()
    name:SetText("Current gear"); name:ClearFocus()
    editingName = false
    Save(true)
    fill:GetScript("OnClick")()
end)
ES.preset:SetScript("OnClick", function() FGT.CreateHunterPreRaidBuild() end)
for b, tip in pairs({ [ES.current] = "A new set filled with the items you are wearing now",
    [ES.preset] = "A ready-made set you can change" }) do
    b:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(tip, 1, 1, 1); GameTooltip:Show()
    end)
    b:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
ES.card:Hide()
-- Lay out what applies: the current-gear start for your own character, a preset when one fits.
function ES.Layout()
    local who = Who()
    local preset = Cat.PRESETS.hunter_preraid_wowhead
    local showPreset = who.class == preset.class and who.faction == preset.faction
    ES.current:SetShown(who.me and true or false)
    ES.preset:SetShown(showPreset)
    ES.preset.text:SetText("Use " .. preset.name)
    local y = 22 + (ES.title:GetStringHeight() or 20) + 10 + (ES.body:GetStringHeight() or 30) + 18
    for _, b in ipairs({ ES.create, ES.current, ES.preset }) do
        if b:IsShown() then
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", 22, -y)
            y = y + b:GetHeight() + 8
        end
    end
    ES.card:SetHeight(y + 14)
    ES.card:ClearAllPoints(); ES.card:SetPoint("LEFT", right, "LEFT", 36, 10)
end
-- The scene for the welcome: the character in their own gear, once per visit to the empty state.
function ES.Scene()
    local who = Who()
    modelOwner = nil -- the next set dresses the model as its own character
    model:SetUnit("player")
    if not who.me then
        if model.SetCustomRace and RACE_IDS[who.race or ""] then
            pcall(model.SetCustomRace, model, RACE_IDS[who.race], who.sex == 3 and 1 or 0)
        end
        model:Undress() -- another character's gear is not known to the model
    end
    if background.race ~= who.race and who.race then
        background.race = who.race
        for i = 1, 4 do modelArea["bg" .. i].texture:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. who.race .. i) end
    end
    appearance:SetScript("OnUpdate", nil); appearanceAlpha = 1; model:SetAlpha(1)
    model:SetFacing(facing)
    -- the welcome opens close in on the character with the scenery not yet there (FadeIn brings both)
    camera:SetScript("OnUpdate", nil)
    offsetY, offsetZ, targetZoom, targetY, targetZ = 0, 0, MAX_ZOOM, 0, 0
    ApplyZoom(MAX_ZOOM); background:SetAlpha(0)
    LayoutPreview(modelArea, modelArea:GetWidth(), modelArea:GetHeight())
end
-- Opening the first set from the welcome brings the planner to life, all on one clock: the card
-- fades out while the camera pulls back to the resting view, the scenery fades in, and the slot
-- squares (with their enchant squares) and the set's header fade in together. Instant with
-- animations off.
ES.DURATION = 0.9
ES.driver = CreateFrame("Frame", nil, right)
function ES.FadeIn()
    local order = {}
    for _, spec in ipairs(slots) do order[#order + 1] = slotButtons[spec[1]] end -- (hidden ammo or quiver: harmless)
    local function Set(a)
        for _, b in ipairs(order) do b:SetAlpha(a); b.enchant:SetAlpha(a) end
        header:SetAlpha(a); background:SetAlpha(a)
    end
    MoveCamera(REST_ZOOM, 0, 0, ES.DURATION)
    if FGT.Setting("celebrations") == "off" then
        Set(1); ES.card:Hide(); ES.card:SetAlpha(1)
        return
    end
    Set(0)
    ES.card:Show(); ES.card:SetAlpha(1)
    local elapsed, OUT = 0, 0.3
    ES.driver:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        ES.card:SetAlpha(1 - Ease(math.min(1, elapsed / OUT)))
        if elapsed >= OUT then ES.card:Hide() end
        Set(Ease(math.min(1, elapsed / ES.DURATION)))
        if elapsed >= ES.DURATION then
            Set(1); ES.card:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
        end
    end)
end
function ES.Paint()
    local welcome = selected == nil
    if welcome then
        ES.driver:SetScript("OnUpdate", nil); header:SetAlpha(1)
        ES.card:SetAlpha(1); ES.card:Show()
        if ES.state == nil then background:SetAlpha(0) end
        ES.Layout()
        if ES.state ~= Who().key then ES.state = Who().key; ES.Scene() end
    elseif ES.state then
        ES.state = nil
        ES.FadeIn()
    elseif not ES.driver:GetScript("OnUpdate") then
        ES.card:Hide() -- (a refresh during the fade leaves it running)
        background:SetAlpha(1)
    end
end
local function RenameSet()
    actions:Hide(); editingName = true; Refresh(); name:SetFocus(); name:HighlightText()
end
rename:SetScript("OnClick", RenameSet)
editName:SetScript("OnClick", RenameSet)
clear:SetScript("OnClick", function()
    if not selected then return end
    if clearedBuild == selected then
        selected.slots, selected.enchants = cleared, EN.cleared
        if selected.goalId then
            selected.goalItems = clearedItems
            ForeverGoalTrackerDB.progress[selected.goalId] = clearedProgress
        end
        cleared, clearedBuild, clearedItems, clearedProgress = nil, nil, nil, nil
    else
        cleared, clearedBuild, EN.cleared = selected.slots, selected, selected.enchants
        clearedItems = selected.goalItems
        clearedProgress = selected.goalId and ForeverGoalTrackerDB.progress[selected.goalId]
        selected.slots, selected.enchants = {}, nil
    end
    Deselect(); Dress(true); Save(true); Refresh()
end)
-- Start from what the character is wearing now: only items the database knows.
fill:SetScript("OnClick", function()
    if not selected then return end
    local count, skipped = 0, {}
    for _, slot in ipairs(Cat.SLOT_ORDER) do
        local id = GetInventoryItemID and GetInventoryItemID("player", slot) ---@type number?
        if slot == 20 then
            -- the quiver can sit in any of the four bag slots
            id = nil
            for _, bag in ipairs(FGT.BagSlots()) do
                local bagId = GetInventoryItemID and GetInventoryItemID("player", bag)
                local item = bagId and Cat.Get(bagId)
                if item and item.inv == 27 then id = bagId; break end
            end
        end
        local item = id and Cat.Get(id)
        if item then
            selected.slots[slot] = id; count = count + 1
            -- the worn enchant comes from the item link (item:id:enchant:...)
            local link = slot ~= 20 and GetInventoryItemLink and GetInventoryItemLink("player", slot)
            local e = link and Cat.EnchantByEffect(tonumber(link:match("item:%-?%d+:(%d+)")), item)
            selected.enchants = selected.enchants or {}
            selected.enchants[slot] = e and e.spell or nil
        elseif id then
            local itemName = FGT.ItemInfo(id)
            skipped[#skipped + 1] = itemName or ("item " .. id)
        end
    end
    actions:Hide(); Deselect(); Dress(true); Save(true); Refresh()
    local text = count > 0 and ("Added " .. count .. " equipped items.") or "No equipped items found in the database."
    if #skipped > 0 then text = text .. " Not in the planner's list: " .. table.concat(skipped, ", ") .. "." end
    status:SetText(text)
end)
duplicate:SetScript("OnClick", function()
    if not (selected and selected.id) then return end
    local store = Store()
    local copy = { id = store.nextId, name = selected.name .. " copy", slots = {}, level = selected.level }
    store.nextId = store.nextId + 1
    for slot, id in pairs(selected.slots) do copy.slots[slot] = id end
    if selected.enchants then
        copy.enchants = {}
        for slot, spell in pairs(selected.enchants) do copy.enchants[slot] = spell end
    end
    store.builds[#store.builds + 1] = copy; store.selected = copy.id
    actions:Hide(); Choose(copy)
end)
remove:SetScript("OnClick", function()
    if not selected or not selected.goalId then return end
    ForeverGoalTrackerDB.active[selected.goalId] = nil
    -- Keep the set and its credit so Add to Goals can restore it without loss.
    actions:Hide(); FGT.RefreshPlannerGoals(); Refresh()
end)
delete:SetScript("OnClick", function()
    if not (selected and selected.id) then return end
    if not deleteArmed then deleteArmed = true; Refresh(); return end
    deleteArmed = nil
    local store, DB = Store(), ForeverGoalTrackerDB
    if selected.goalId then
        DB.active[selected.goalId] = nil; DB.progress[selected.goalId] = nil
        local goal = FGT.GoalById(selected.goalId)
        if goal then goal.steps = {} end
    end
    for i, build in ipairs(store.builds) do if build == selected then table.remove(store.builds, i); break end end
    store.selected = store.builds[1] and store.builds[1].id or nil
    actions:Hide(); FGT.RefreshPlannerGoals()
    Choose(store.builds[1])
end)
name:SetScript("OnEditFocusLost", function()
    editingName = false
    if selected and selected.id and (name:GetText() or ""):match("^%s*$") then
        changing = true; name:SetText(selected.name); changing = false
    end
    Refresh()
end)
-- The first letter turns the draft into a saved set and redraws the planner; the box must keep
-- the cursor through that, so you can finish typing the name.
name:SetScript("OnTextChanged", function()
    if changing then return end
    local typing = name:HasFocus()
    Save(); Refresh()
    if typing and not name:HasFocus() then
        editingName = true; Refresh(); name:SetFocus()
    end
end)
name:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
name:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
name.hint = U.font(name, 11); name.hint:SetPoint("LEFT", 8, 0)
name.hint:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3]); name.hint:SetText("Name your set")
function name.PaintHint() name.hint:SetShown((name:GetText() or "") == "" and not name:HasFocus()) end
name:HookScript("OnTextChanged", name.PaintHint); name:HookScript("OnEditFocusGained", name.PaintHint)
name:HookScript("OnEditFocusLost", name.PaintHint); name:HookScript("OnShow", name.PaintHint)
name:HookScript("OnEditFocusGained", function()
    name:SetBackdropBorderColor(colors.GOLD2[1], colors.GOLD2[2], colors.GOLD2[3], 1)
end)
name:HookScript("OnEditFocusLost", function()
    name:SetBackdropBorderColor(styles.row.edge[1], styles.row.edge[2], styles.row.edge[3], 1)
end)
P:HookScript("OnShow", function()
    local store = Store(); selected = nil
    for _, build in ipairs(store.builds) do if build.id == store.selected then selected = build end end
    Choose((draftOwner == PlanKey() and draft) or selected or store.builds[1])
end)
P:HookScript("OnHide", function()
    camera:SetScript("OnUpdate", nil); model:SetScript("OnUpdate", nil); model:SetAlpha(1); dragX = nil
    turn:SetScript("OnUpdate", nil)
    appearance:SetScript("OnUpdate", nil); appearanceAlpha = 1
    picker:SetScript("OnUpdate", nil); menu:SetScript("OnUpdate", nil)
    actions:Hide(); Deselect(); name:ClearFocus(); GameTooltip:Hide()
    Cat.Release(selected and selected.slots) -- the slot lists are rebuilt on demand
end)

-- Plan for another character on the roster (nil or the logged-in key: yourself).
local function PlanFor(key)
    if key == U.charKey() then key = nil end
    if key == planFor then return end
    if P:IsShown() then Cat.Release(selected and selected.slots) end
    planFor, draft, selected = key, nil, nil
    if P:IsShown() then
        local store = Store()
        for _, build in ipairs(store.builds) do if build.id == store.selected then selected = build end end
        Choose(selected or store.builds[1])
    end
end
FGT.GearPlannerFor = PlanFor
local function CharacterList()
    local list = {}
    for key, c in pairs(ForeverGoalTrackerDB.characters or {}) do
        if c.class then list[#list + 1] = { key = key, c = c } end
    end
    table.sort(list, function(a, b) return (a.c.lastSeen or 0) > (b.c.lastSeen or 0) end)
    return list
end
ownerBtn:SetScript("OnClick", function()
    if charMenu:IsShown() then charMenu:Hide(); return end
    local list, y = CharacterList(), 8
    for _, row in ipairs(charRows) do row:Hide() end
    for i, entry in ipairs(list) do
        local row = charRows[i]
        if not row then row = Button(charMenu, "", 200, 24, 11); charRows[i] = row
            row.text:ClearAllPoints(); row.text:SetPoint("LEFT", 8, 0)
        end
        local c, color = entry.c, RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.c.class]
        row.text:SetText((color and color.colorStr and ("|c" .. color.colorStr) or "") .. (c.name or entry.key) .. "|r"
            .. (c.level and ("  |cff9a8f78· Level " .. c.level .. "|r") or ""))
        row.chosen = entry.key == PlanKey(); PaintButton(row)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 8, -y); row:Show(); y = y + 28
        row:SetScript("OnClick", function() charMenu:Hide(); PlanFor(entry.key) end)
    end
    charMenu:SetSize(216, y + 6); charMenu:Show()
end)
ownerBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Plan for another character", 1, 1, 1)
    GameTooltip:AddLine("Sets, goals and progress stay with that character.", 0.8, 0.8, 0.8, true); GameTooltip:Show()
end)
ownerBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
P:HookScript("OnHide", function() charMenu:Hide() end)

-- From a planner goal's page: open the set it came from, on whichever character owns it.
function FGT.OpenGearSet(goal)
    local owner = goal and goal.plannerOwner
    if not (owner and (owner == U.charKey() or (ForeverGoalTrackerDB.characters or {})[owner])) then return false end
    PlanFor(goal.plannerOwner)
    local store = Store()
    for _, build in ipairs(store.builds) do
        if build.goalId == goal.id then
            store.selected = build.id; draft = nil
            FGT.ShowTab("gear")
            if P:IsShown() then Choose(build) end
            return true
        end
    end
    return false
end

-- ------------------------------------------------------------
-- Ready-made sets
-- ------------------------------------------------------------
-- Explicit test-build import; never changes another character or an existing set.
function FGT.CreateHunterPreRaidBuild()
    local presetId = "hunter_preraid_wowhead"
    local preset = Cat.PRESETS[presetId]
    local who = Who()
    if who.class ~= preset.class or who.faction ~= preset.faction then
        print("Forever Goal Tracker: This test build is for an Alliance Hunter."); return
    end
    local store = Store()
    local build
    for _, existing in ipairs(store.builds) do
        if existing.preset == presetId then build = existing; break end
    end
    if not build then
        build = { id = store.nextId, name = preset.name, slots = {}, preset = presetId, level = 60 }
        store.nextId = store.nextId + 1
        for slot, id in pairs(preset.slots) do build.slots[slot] = id end
        store.builds[#store.builds + 1] = build
    end
    build.tracked = true
    local goal = SyncGoal(build, PlanKey())
    if not goal then return end
    ForeverGoalTrackerDB.active[goal.id] = true; store.selected = build.id
    FGT.RefreshPlannerGoals(goal); FGT.ShowTab("gear"); Choose(build)
    return build, goal
end
-- Expose only prototype operations needed by regression checks.
FGT.GearPlannerTest = { store = Store, new = function() new:GetScript("OnClick")() end,
    name = name, setTitle = setTitle, editName = editName, add = add, viewGoal = viewGoal, options = options, actions = actions,
    clear = clear, remove = remove, rename = rename, fill = fill, duplicate = duplicate, delete = delete,
    camera = camera, turn = turn, appearance = appearance, menu = menu, replace = replace, rows = rows, head = head,
    picker = picker, results = resultRows, unequip = unequip, search = search, filters = { stat = FL.stat,
        kind = FL.kind, quality = FL.quality, revealed = FL.revealed, showAll = FL.showAll, popup = FL.popup, rows = FL.rows },
    list = pickerList, found = function() return found, foundCount end,
    modelArea = modelArea, model = model, clickAway = clickAway, slots = slotButtons, status = status, level = LV.box, minLevel = LV.min,
    goalMenu = LG.menuBtn, libraryHeader = LG.header, welcome = ES }
