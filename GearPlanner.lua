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
local POOL_ROWS = 12 -- grows to fill the picker's height when it opens (PlacePicker)

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
-- The level a new set plans for: the character's own. With no set open (the welcome) the picker
-- already lists gear for it, so a pick there starts a set that fits it (Karl, 2026-10-27: the
-- welcome listed level 60 gear, then flagged it on the level 10 set the pick started).
local function NewSetLevel() return math.max(1, math.min(60, Who().level or 60)) end
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
-- Layout: slots on the left, the character in the middle, the sets in a drawer on the right
-- ------------------------------------------------------------
-- (the 2026-10-23 redesign: reports/Gear-Planner-layout-2026-10-23.md)
local left = CreateFrame("Frame", nil, P, "BackdropTemplate")
left:SetPoint("TOPLEFT", U.list, "TOPLEFT")
left:SetPoint("BOTTOMLEFT", U.list, "BOTTOMLEFT")
left.natural = 300
left:SetWidth(left.natural)
U.etch(left, styles.panel)
-- My Gear Sets: a drawer on the right edge that slides like Materials (same handle, pace and
-- 22-unit strip when closed); the stage widens as it closes. One width always; when the window
-- has no room left for it beside the stage, it opens over the stage's right edge instead.
local SD = { open = true, fraction = 1, width = 260, STAGE = 380 }
SD.clip = CreateFrame("Frame", nil, P)
SD.clip:SetPoint("TOP", left, "TOP"); SD.clip:SetPoint("BOTTOM", left, "BOTTOM")
SD.clip:SetPoint("RIGHT", U.main, "RIGHT", -16, 0)
SD.clip:SetFrameLevel(P:GetFrameLevel() + 40) -- above the stage it may cover
if SD.clip.SetClipsChildren then SD.clip:SetClipsChildren(true) end
local drawer = CreateFrame("Frame", nil, SD.clip, "BackdropTemplate")
drawer:SetPoint("TOPLEFT", SD.clip, "TOPLEFT"); drawer:SetPoint("BOTTOMLEFT", SD.clip, "BOTTOMLEFT")
drawer:SetWidth(SD.width)
U.etch(drawer, styles.panel, 12)
if FGT.AddGrime then FGT.AddGrime(drawer, 0.18, 12, 0.37, 0, 140) end
drawer:EnableMouse(true)
-- the window edge's shadow while the drawer is tucked beneath it (Materials' edge shade)
SD.shadow = drawer:CreateTexture(nil, "OVERLAY", nil, 3)
SD.shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
SD.shadow:SetPoint("TOPRIGHT", SD.clip, "TOPRIGHT"); SD.shadow:SetPoint("BOTTOMRIGHT", SD.clip, "BOTTOMRIGHT")
SD.shadow:SetWidth(22)
-- everything in the drawer fades with the slide
SD.body = CreateFrame("Frame", nil, drawer)
SD.body:SetPoint("TOPLEFT"); SD.body:SetPoint("BOTTOMLEFT"); SD.body:SetWidth(SD.width)
SD.handle = CreateFrame("Button", nil, P)
SD.handle:SetSize(24, 48)
FGT.IconButton(SD.handle, "chevron-white", 10)
SD.handle.icon:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
SD.handle.glow:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
SD.handle:SetScript("OnEnter", function(self)
    self.icon:SetVertexColor(colors.ACCENT[1], colors.ACCENT[2], colors.ACCENT[3])
    self.glow:SetVertexColor(colors.ACCENT[1], colors.ACCENT[2], colors.ACCENT[3])
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(SD.open and "Hide gear sets" or "Show gear sets")
    GameTooltip:Show()
end)
SD.handle:SetScript("OnLeave", function(self)
    self.icon:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    self.glow:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    GameTooltip:Hide()
end)
local right = CreateFrame("Frame", nil, P, "BackdropTemplate")
right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
right:SetPoint("BOTTOMRIGHT", SD.clip, "BOTTOMLEFT", -12, 0)
U.etch(right, styles.panel)
SD.handle:SetFrameLevel(math.max(right:GetFrameLevel(), drawer:GetFrameLevel()) + 45)
-- the drawer's shadow on the stage while it covers part of it (outside the clip, so its own frame)
SD.castFrame = CreateFrame("Frame", nil, P)
SD.castFrame:SetAllPoints(SD.clip); SD.castFrame:SetFrameLevel(SD.clip:GetFrameLevel())
SD.cast = SD.castFrame:CreateTexture(nil, "BACKGROUND")
SD.cast:SetTexture("Interface\\Buttons\\WHITE8X8")
SD.cast:SetPoint("TOPRIGHT", SD.clip, "TOPLEFT"); SD.cast:SetPoint("BOTTOMRIGHT", SD.clip, "BOTTOMLEFT")
SD.cast:SetWidth(18)
U.gradient(SD.cast, { 0, 0, 0 }, { 0, 0, 0 }, 0, 0.5)
SD.cast:Hide()
-- Small windows: the slot column slims a little, then the drawer opens over the character.
function left.Fit()
    local main = U.main:GetWidth() or 0
    local width = main > 0 and math.max(240, math.min(left.natural, main * 0.24)) or left.natural
    if math.abs(width - left:GetWidth()) >= 0.5 then left:SetWidth(width); if left.Layout then left.Layout() end end
    if SD.Place then SD.Place() end
end
Label(SD.body, "My Gear Sets", 16, 16, -16)
-- Whose sets these are: a picker over every character on the roster.
local ownerBtn = CreateFrame("Button", nil, SD.body)
ownerBtn:SetPoint("TOPLEFT", 12, -42); ownerBtn:SetHeight(22)
local ownerLead = U.font(SD.body, 11); ownerLead:SetPoint("TOPLEFT", 16, -46); ownerLead:SetText("Plans for")
ownerLead:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
ownerBtn:ClearAllPoints(); ownerBtn:SetPoint("LEFT", ownerLead, "RIGHT", 2, 0)
local owner = U.font(ownerBtn, 11); owner:SetPoint("LEFT", 4, 0)
local ownerCaret = ownerBtn:CreateTexture(nil, "OVERLAY")
ownerCaret:SetTexture(FGT.Icon("chevron")); ownerCaret:SetSize(12, 12); ownerCaret:SetPoint("LEFT", owner, "RIGHT", 4, 0)
local charMenu = CreateFrame("Frame", nil, SD.body, "BackdropTemplate")
-- (from the drawer's own left edge, under the picker: the picker starts well in, and a menu from there ran past
-- the drawer, which clips it)
charMenu:SetPoint("TOPLEFT", SD.body, "TOPLEFT", 12, -68)
charMenu:SetFrameLevel(drawer:GetFrameLevel() + 30); charMenu:EnableMouse(true)
U.etch(charMenu, styles.panel); charMenu:Hide()
local charRows = {}
-- the drawer's "..." menu: what applies to every set (and the open one)
local options = Button(SD.body, "...", 30, 24); options:SetPoint("TOPRIGHT", -14, -14)
options.text:ClearAllPoints(); options.text:SetPoint("CENTER", 0, 3) -- the dots sit on the baseline
local new = Button(SD.body, "+ New", 68, 24); new:SetPoint("RIGHT", options, "LEFT", -6, 0)
local list = U.scroll(SD.body) -- (no height argument: 0 would make the bottom fade 0 tall)
-- Use an independent clipped viewport; no dependency on the guide layout.
list.scroll:ClearAllPoints(); list.scroll:SetPoint("TOPLEFT", 12, -76)
list.scroll:SetPoint("BOTTOMRIGHT", -12, 16)
local listEmpty = Label(SD.body, "No sets yet.", 11, 16, -84)
listEmpty:SetWidth(SD.width - 32); listEmpty:SetJustifyH("LEFT")
listEmpty:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
local rows, selected, draft, changing = {}, nil, nil, false
-- How much of the stage's width the drawer takes at a point in its slide: the stage keeps
-- SD.STAGE at the least, and past that the drawer covers its right edge.
function SD.Beside(fraction, area)
    area = area or ((U.main:GetWidth() or 0) - left:GetWidth() - 44)
    return math.min(math.max(1, 22 + (SD.width - 22) * fraction), math.max(22, area - SD.STAGE))
end
-- Place the drawer for its slide (fraction 0 closed, 1 open) and the window's room.
function SD.Place()
    local area = (U.main:GetWidth() or 0) - left:GetWidth() - 44
    local fraction = SD.fraction
    local shown = math.max(1, 22 + (SD.width - 22) * fraction)
    SD.clip:SetWidth(shown)
    local beside = SD.Beside(fraction, area)
    right:SetPoint("BOTTOMRIGHT", SD.clip, "BOTTOMRIGHT", -(beside + 12), 0)
    SD.covering = shown - beside > 1
    SD.cast:SetShown(SD.covering)
    drawer:SetWidth(SD.width); SD.body:SetWidth(SD.width)
    listEmpty:SetWidth(SD.width - 32)
    SD.handle:ClearAllPoints(); SD.handle:SetPoint("CENTER", SD.clip, "LEFT", -6, 0)
    -- IconButton's glyph points down: open points right (tuck it away), closed points left
    local rotation = SD.open and math.pi / 2 or -math.pi / 2
    SD.handle.icon:SetRotation(rotation); SD.handle.glow:SetRotation(rotation)
    -- Gradient alpha is encoded in its colors on these clients.
    U.gradient(SD.shadow, { 0, 0, 0 }, { 0, 0, 0 }, 0, 0.65 * (1 - fraction))
    SD.shadow:SetShown(fraction < 1)
    SD.body:SetAlpha(fraction); SD.body:SetShown(fraction > 0)
    if SD.afterPlace then SD.afterPlace() end
end
SD.driver = CreateFrame("Frame", nil, P)
-- One pace with Materials: 0.7 s, easing out.
function SD.SetOpen(open)
    SD.driver:SetScript("OnUpdate", nil)
    SD.open = open and true or false
    Prefs().setsClosed = (not SD.open) or nil
    GameTooltip:Hide()
    if SD.onToggle then SD.onToggle() end
    local start, target = SD.fraction, SD.open and 1 or 0
    if FGT.Setting("celebrations") == "off" then SD.fraction = target; SD.Place(); return end
    -- the character keeps one size through the slide (the narrower stage's) and only moves
    if SD.onSlide then
        local now = right:GetWidth() or 0
        SD.onSlide(math.min(now, now + SD.Beside(start) - SD.Beside(target)))
    end
    local elapsed, slide = 0, (FGT.materialsPanel and FGT.materialsPanel.SLIDE_TIME) or 0.7
    SD.driver:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local p = math.min(1, elapsed / slide)
        SD.fraction = start + (target - start) * (1 - (1 - p) ^ 3)
        SD.Place()
        if p >= 1 then self:SetScript("OnUpdate", nil); if SD.onSlide then SD.onSlide(nil) end end
    end)
end
SD.handle:SetScript("OnClick", function() SD.SetOpen(not SD.open) end)
P:HookScript("OnShow", function()
    SD.driver:SetScript("OnUpdate", nil); if SD.onSlide then SD.onSlide(nil) end
    SD.open = not Prefs().setsClosed
    SD.fraction = SD.open and 1 or 0
    SD.Place()
end)
P:HookScript("OnHide", function() SD.driver:SetScript("OnUpdate", nil); if SD.onSlide then SD.onSlide(nil) end end)
local ES -- the first-visit welcome card (built further down)
local draftOwner
local editingName = false

local header = CreateFrame("Frame", nil, right)
header:SetAllPoints(); header:SetFrameLevel(right:GetFrameLevel() + 12)
-- small gold-grey capitals over the band's two halves
local EYEBROW = { 0.66, 0.60, 0.45 }
-- The set's name, centred over the character. Hovering shows a pencil on its left and a faint
-- underline; a click turns it into the name box (Enter or clicking away keeps the name).
local setTitle = U.title(header, 20)
setTitle:SetPoint("TOP", right, "TOP", 0, -24); setTitle:SetJustifyH("CENTER"); setTitle:SetWordWrap(false)
local editName = CreateFrame("Button", nil, header)
editName:SetPoint("TOPLEFT", setTitle, "TOPLEFT", -4, 4); editName:SetPoint("BOTTOMRIGHT", setTitle, "BOTTOMRIGHT", 4, -4)
editName.pencil = editName:CreateTexture(nil, "OVERLAY")
editName.pencil:SetTexture(FGT.Icon("pencil-white")); editName.pencil:SetSize(15, 15)
editName.pencil:SetPoint("RIGHT", editName, "LEFT", -4, 0)
editName.pencil:SetVertexColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3]); editName.pencil:Hide()
editName.line = editName:CreateTexture(nil, "OVERLAY")
editName.line:SetColorTexture(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3], 0.35); editName.line:SetHeight(1)
editName.line:SetPoint("TOPLEFT", setTitle, "BOTTOMLEFT", 0, -3); editName.line:SetPoint("TOPRIGHT", setTitle, "BOTTOMRIGHT", 0, -3)
editName.line:Hide()
editName:SetScript("OnEnter", function(self)
    self.pencil:Show(); self.line:Show()
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Rename set", 1, 1, 1); GameTooltip:Show()
end)
editName:SetScript("OnLeave", function(self) self.pencil:Hide(); self.line:Hide(); GameTooltip:Hide() end)
local name = CreateFrame("EditBox", nil, header, "BackdropTemplate")
name:SetAutoFocus(false); name:SetMaxLetters(60); name:SetSize(320, 30)
U.etch(name, styles.row, 10)
FGT.RegisterFont(name, "body", 14, "")
name:SetTextColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3]); name:SetTextInsets(8, 8, 0, 0)
name:SetJustifyH("CENTER")
name:SetPoint("TOP", right, "TOP", 0, -20)
-- The chevron beside the name switches to another of this character's sets.
local switch = CreateFrame("Button", nil, header)
switch:SetSize(24, 24); switch:SetPoint("LEFT", setTitle, "RIGHT", 8, 0)
FGT.IconButton(switch, "chevron-white", 11)
switch.icon:SetVertexColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
switch.glow:SetVertexColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
local switchMenu = CreateFrame("Frame", nil, header, "BackdropTemplate")
switchMenu:SetPoint("TOP", setTitle, "BOTTOM", 0, -8)
switchMenu:SetFrameLevel(header:GetFrameLevel() + 30); switchMenu:EnableMouse(true)
U.etch(switchMenu, styles.panel); switchMenu:Hide()
switchMenu.rows = {}
-- Under the name: the character, their race and class, and a Library set when the pieces share one.
local subline = U.font(header, 11)
subline:SetPoint("TOP", setTitle, "BOTTOM", 0, -9); subline:SetJustifyH("CENTER")
subline:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
-- The set's level range, in the item picker under its filters: the picker lists gear the
-- character can wear at that level (a ceiling: lower-level items always show). Type it, or scroll.
-- "Gear for levels [min] – [max]": max is the level the set plans for (build.level; false = any,
-- missing = 60 for older sets); min (build.minLevel) hides older gear and is empty (any) by
-- default. An empty box shows a muted "Min" or "Max". (The picker parents these once it exists.)
local LV = {}
LV.label = U.font(P, 10); LV.label:SetText("Gear for levels")
LV.label:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
function LV.Box(hint)
    local box = CreateFrame("EditBox", nil, P, "BackdropTemplate")
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
LV.dash = U.font(P, 10); LV.dash:SetText("–"); LV.dash:SetPoint("LEFT", LV.min, "RIGHT", 6, 0)
LV.dash:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
LV.box = LV.Box("Max"); LV.box:SetPoint("LEFT", LV.dash, "RIGHT", 6, 0)

-- Over the stage (Karl, 2026-10-24: the bottom band covered the character): a "Set totals" tab
-- in the bottom left corner opens the totals upward, one row per stat, and closes again each time
-- the planner opens. Short messages sit beside the tab. In My Goals has the top right corner.
local band = CreateFrame("Frame", nil, header)
band:SetAllPoints(right)
band.W, band.ROW = 220, 16
local function Eyebrow(parent, text)
    local f = U.font(parent, 9); f:SetText(text)
    f:SetTextColor(EYEBROW[1], EYEBROW[2], EYEBROW[3])
    return f
end
band.tab = Button(band, "Set totals", 100, 24, 11)
band.tab:SetPoint("BOTTOMLEFT", right, "BOTTOMLEFT", 16, 16)
band.tab.text:ClearAllPoints(); band.tab.text:SetPoint("LEFT", 10, 0)
band.tab.caret = band.tab:CreateTexture(nil, "OVERLAY")
band.tab.caret:SetTexture(FGT.Icon("chevron")); band.tab.caret:SetSize(10, 10); band.tab.caret:SetPoint("RIGHT", -9, 0)
band.panel = CreateFrame("Frame", nil, band, "BackdropTemplate")
band.panel:SetPoint("BOTTOMLEFT", band.tab, "TOPLEFT", 0, 6); band.panel:SetWidth(band.W)
U.etch(band.panel, styles.panel); band.panel:EnableMouse(true); band.panel:Hide()
band.totalsLabel = Eyebrow(band.panel, "SET TOTALS"); band.totalsLabel:SetPoint("TOPLEFT", 12, -12)
-- each row: the stat's name, the items' total in white, the enhancements' in green
band.rows = {}
function band.Row(i)
    local row = band.rows[i]
    if row then return row end
    row = {}
    row.name = U.font(band.panel, 11); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
    row.name:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    row.value = U.font(band.panel, 11); row.value:SetJustifyH("RIGHT")
    row.value:SetTextColor(0.91, 0.91, 0.91)
    row.bonus = U.font(band.panel, 11); row.bonus:SetJustifyH("LEFT"); row.bonus:SetTextColor(0.12, 1, 0)
    local y = -30 - (i - 1) * band.ROW
    row.name:SetPoint("TOPLEFT", 12, y); row.name:SetWidth(116)
    row.value:SetPoint("TOPRIGHT", band.panel, "TOPLEFT", 166, y)
    row.bonus:SetPoint("TOPLEFT", band.panel, "TOPLEFT", 172, y)
    band.rows[i] = row
    return row
end
-- "17 of 21 slots filled", then on its own line "Average item level 63 · 6 enhancements"
band.summary = U.font(band.panel, 10); band.summary:SetWidth(band.W - 24); band.summary:SetJustifyH("LEFT")
band.summary:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
-- short messages ("Added 9 equipped items.") beside the tab, open or closed
local status = U.font(band, 10)
status:SetPoint("LEFT", band.tab, "RIGHT", 10, 0); status:SetPoint("RIGHT", right, "RIGHT", -16, 0)
status:SetJustifyH("LEFT"); status:SetWordWrap(false)
status:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
-- In My Goals, at the top of the Equipment panel under its heading (Karl, 2026-10-24: it took
-- room from the character). Not yet: "Not in My Goals yet" and a gold Add button on one line.
-- Tracked: "3 of 17 collected" and "View in My Goals ›", the bar under them.
band.GOAL_H = 46
band.goal = CreateFrame("Frame", nil, left)
band.goal:SetPoint("TOPLEFT", left, "TOPLEFT", 16, -44); band.goal:SetPoint("TOPRIGHT", left, "TOPRIGHT", -16, -44)
band.goal:SetHeight(band.GOAL_H - 8)
band.goalText = U.font(band.goal, 11); band.goalText:SetPoint("LEFT", band.goal, "TOPLEFT", 0, -11)
band.goalText:SetWordWrap(false); band.goalText:SetJustifyH("LEFT")
band.goalText:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3])
band.bar = U.bar(band.goal, 6); band.bar:SetPoint("TOPLEFT", band.goal, "TOPLEFT", 0, -26)
band.bar.label:Hide()
local viewGoal = CreateFrame("Button", nil, band.goal)
viewGoal:SetSize(116, 18); viewGoal:SetPoint("RIGHT", band.goal, "TOPRIGHT", 0, -11)
viewGoal.text = U.font(viewGoal, 11); viewGoal.text:SetPoint("RIGHT"); viewGoal.text:SetText("View in My Goals ›")
viewGoal.text:SetTextColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
viewGoal:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.93, 0.6) end)
viewGoal:SetScript("OnLeave", function(self) self.text:SetTextColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3]) end)
local add = Button(band.goal, "Add to My Goals", 120, 22, 10)
add:SetPoint("RIGHT", band.goal, "TOPRIGHT", 0, -11)
band.goalText:SetPoint("RIGHT", add, "LEFT", -8, 0)
-- a rule under it, so the slot groups start fresh
band.goalRule = band.goal:CreateTexture(nil, "ARTWORK")
band.goalRule:SetColorTexture(styles.row.edge[1], styles.row.edge[2], styles.row.edge[3], 0.6); band.goalRule:SetHeight(1)
band.goalRule:SetPoint("BOTTOMLEFT", band.goal, "BOTTOMLEFT", 0, -4); band.goalRule:SetPoint("BOTTOMRIGHT", band.goal, "BOTTOMRIGHT", 0, -4)
-- The name, the character's line and the Library link sit centred over the character. While the
-- drawer opens over the stage (a narrow window), they move toward the stage's left edge only as
-- far as keeps them clear of it, so nothing important ends up under the drawer (Karl, 2026-10-24).
-- A long name is cut to the room.
band.TITLE_X = 28 -- the left margin once slid (clear of the rename pencil)
function band.FitTitle()
    local W, l = right:GetWidth() or 0, right:GetLeft()
    local edge = SD.clip:GetLeft()
    setTitle:SetWidth(0)
    -- t, 0 centred to 1 left-aligned: just far enough that the widest line keeps 16 clear of the
    -- drawer, so it moves with the drawer and with the window's edge rather than jumping
    local t = 0
    if W > 0 and l and SD.covering then
        local visible = math.min(W, (edge or (l + W)) - l)
        local link = band.libraryLink
        local half = math.max((setTitle:GetStringWidth() or 0) / 2 + 32, -- the switcher chevron
            (subline:GetStringWidth() or 0) / 2, link and link:IsShown() and link:GetWidth() / 2 or 0)
        local intrude = W / 2 + half + 16 - visible
        local travel = W / 2 - (band.TITLE_X + half)
        t = intrude <= 0 and 0 or (travel <= 1 and 1 or math.min(1, intrude / travel))
    end
    SD.cover = t
    if W > 0 and l then
        local visible = math.min(W, (edge or (l + W)) - l)
        local centred = 2 * (math.min(W / 2, visible - W / 2)) - 96 -- the switcher chevron and margins
        local leftward = visible - band.TITLE_X - 64
        local room = math.max(140, centred + (leftward - centred) * t)
        if (setTitle:GetStringWidth() or 0) > room then setTitle:SetWidth(room) end
    end
    local function X(w) return W / 2 + t * ((band.TITLE_X + w / 2) - W / 2) end
    local wt = math.min(setTitle:GetStringWidth() or 0, setTitle:GetWidth() > 0 and setTitle:GetWidth() or math.huge)
    local ws = subline:GetStringWidth() or 0
    local link = band.libraryLink -- (the Library link, made further down)
    local wh = link and link:GetWidth() or 0
    setTitle:SetPoint("TOP", right, "TOPLEFT", X(wt), -24)
    name:SetPoint("TOP", right, "TOPLEFT", X(name:GetWidth() or 320), -20)
    subline:SetPoint("TOP", setTitle, "BOTTOM", t * (ws - wt) / 2, -9)
    if link then link:SetPoint("TOP", subline, "BOTTOM", t * (wh - ws) / 2, -5) end
end

-- The drawer's "..." menu: one button per action, laid out from what applies.
local actions = CreateFrame("Frame", nil, SD.body, "BackdropTemplate")
actions:SetSize(206, 112); actions:SetPoint("TOPRIGHT", options, "BOTTOMRIGHT", 0, -6)
actions:SetFrameLevel(drawer:GetFrameLevel() + 30); actions:EnableMouse(true)
U.etch(actions, styles.panel); actions:Hide()
local MENU_W = 186
local newSet = Button(actions, "New set", MENU_W)
local newWorn = Button(actions, "New from what I'm wearing", MENU_W)
local WI = { menu = Button(actions, "Import from Wowhead", MENU_W) } -- the Wowhead import (built further down)
local rename = Button(actions, "Rename", MENU_W)
local fill = Button(actions, "Fill from equipped", MENU_W)
local duplicate = Button(actions, "Duplicate selected set", MENU_W)
local clear = Button(actions, "Clear selected set", MENU_W)
local usePreset = Button(actions, "", MENU_W)
local remove = Button(actions, "Remove from My Goals", MENU_W)
local removeAll = Button(actions, "Remove all sets from My Goals", MENU_W)
local delete = Button(actions, "Delete set", MENU_W)
local deleteAll = Button(actions, "Delete all sets...", MENU_W)
deleteAll.text:SetTextColor(1, 0.48, 0.40)
actions.rule = actions:CreateTexture(nil, "ARTWORK")
actions.rule:SetColorTexture(styles.row.edge[1], styles.row.edge[2], styles.row.edge[3], 0.8); actions.rule:SetHeight(1)
for _, b in ipairs({ newSet, newWorn, WI.menu, rename, fill, duplicate, clear, usePreset, remove, removeAll, delete, deleteAll }) do
    b.text:ClearAllPoints(); b.text:SetPoint("LEFT", 10, 0); b.text:SetJustifyH("LEFT")
end
local cleared, clearedBuild, clearedItems, clearedProgress
local deleteArmed, deleteAllArmed
options:SetScript("OnClick", function()
    deleteArmed, deleteAllArmed = nil, nil
    if actions:IsShown() then actions:Hide() else if SD.PaintMenu then SD.PaintMenu() end; actions:Show() end
end)
options:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Gear set options", 1, 1, 1); GameTooltip:Show()
end)
options:HookScript("OnLeave", function() GameTooltip:Hide() end)
SD.onToggle = function() actions:Hide(); charMenu:Hide() end

-- ------------------------------------------------------------
-- The character
-- ------------------------------------------------------------
local modelArea = CreateFrame("Frame", nil, right)
modelArea:SetPoint("TOPLEFT", 4, -4); modelArea:SetPoint("BOTTOMRIGHT", -4, 4)
modelArea:SetClipsChildren(true)
-- One high-resolution racial backdrop; layout restores the original portrait aspect.
local _, race = UnitRace("player")
local background = CreateFrame("Frame", nil, modelArea)
background:SetAllPoints()
background.texture = background:CreateTexture(nil, "BACKGROUND")
background.texture:SetAlpha(0.18)
background.races = { Human = true, Dwarf = true, Gnome = true, NightElf = true,
    Orc = true, Tauren = true, Troll = true, Scourge = true }
-- Backdrops with a set place to stand that an even crop would miss: the height (0 top, 1 bottom)
-- of that ground in the image, placed where the character's feet rest (FEET of the panel's height) as far
-- as covering the panel allows. Others crop evenly. The orc stands on the crest of its rock,
-- the night elf on its path, low enough to keep the treeline and the arch, the dwarf on the
-- cobbles rather than the snow beside them, the undead on the open path in front of the headstones. The tauren's grass has no single
-- spot: its ground is where the even crop already put the feet, so zooming out can follow them.
background.ground, background.FEET = { Orc = 0.70, NightElf = 0.77, Dwarf = 0.69, Scourge = 0.77, Tauren = 0.64 }, 0.78
function background:SetRace(raceFile)
    raceFile = self.races[raceFile] and raceFile or "Orc"
    if self.race == raceFile then return end
    self.race = raceFile
    self.texture:SetTexture("Interface\\AddOns\\ForeverGoalTracker\\Media\\dressing-room\\" .. raceFile)
    if self.Layout then self.Layout() end
    if FGT.PlannerEffects then FGT.PlannerEffects.SetRace(raceFile) end
end
-- What PlannerEffects.lua (loaded after this file) draws on: the backdrop's frame and picture, and
-- the stage it sits in.
FGT.plannerBackdrop = { frame = background, texture = background.texture, area = modelArea }
background:SetRace(race)
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
-- Model-space offsets (right-drag) move the character inside the full-panel drawing frame.
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
-- Another set: the character faces front again at the resting view. Choosing a slot leaves the
-- camera where the player put it (Karl, 2026-10-24: the stage controls replace the slot zoom).
local function RestCamera()
    TurnTo(0)
    MoveCamera(REST_ZOOM, 0, 0, 0.55)
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
-- What the model wears (Karl, 2026-10-24): the helm and cloak can be hidden, as in the game, and
-- its hands hold the melee weapons or the ranged one, never both (the ranged one took over the
-- daggers). Hunters show the ranged weapon by default, everyone else the melee ones; the stage's
-- toggles change that per class. The slot being chosen always shows.
local VIEW = { SLOTS = { HeadSlot = 1, BackSlot = 15, MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18 } }
local function Shown(id)
    local item = selected and Cat.Get(selected.slots[id])
    return item ~= nil and not NO_MODEL[item.inv]
end
-- both kinds of weapon planned: only then is there a choice
function VIEW.Both() return Shown(18) and (Shown(16) or Shown(17)) end
function VIEW.Ranged()
    if selectedSlot == "RangedSlot" then return true end
    if selectedSlot == "MainHandSlot" or selectedSlot == "SecondaryHandSlot" then return false end
    local choice = Prefs().weapons and Prefs().weapons[Who().class or ""]
    if choice then return choice == "ranged" end
    return Who().class == "HUNTER"
end
function VIEW.Skip(id)
    if id == 1 then return Prefs().hideHelm and selectedSlot ~= "HeadSlot" or false end
    if id == 15 then return Prefs().hideCloak and selectedSlot ~= "BackSlot" or false end
    if (id == 16 or id == 17 or id == 18) and VIEW.Both() then return (id == 18) ~= VIEW.Ranged() end
    return false
end
-- what the model shows now, to repaint only when choosing a slot changes it
function VIEW.Signature()
    local s = ""
    for _, id in ipairs({ 1, 15, 16, 17, 18 }) do s = s .. (VIEW.Skip(id) and "0" or "1") end
    return s
end
-- The sheathe key (the game's own, Z by default) puts the character's weapons away on the back or
-- hips, as in game. Kept across sessions in the planner's preferences, and reapplied after every
-- repaint, since a new set or character reloads the model.
local function Sheathed() return ForeverGoalTrackerDB and Prefs() and Prefs().sheathed or false end
local function ApplySheath()
    if model.SetSheathed then pcall(model.SetSheathed, model, Sheathed() and true or false) end
end
-- Dress the model with the planned items. Undress first, so removed items disappear.
local function PaintGear()
    if not model.TryOn then return end
    model:Undress()
    VIEW.painted = VIEW.Signature()
    for _, id in ipairs(Cat.SLOT_ORDER) do
        local item = selected and Cat.Get(selected.slots[id])
        if item and not NO_MODEL[item.inv] and not VIEW.Skip(id) then
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
    ApplySheath()
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
-- While the planner is open, the game's sheathe key toggles the character's weapons. An override
-- binding is the way to catch one key without taking the keyboard: typing in a text box is
-- unaffected (the game fires no bindings then) and every other key keeps its meaning. The
-- window's own owner frame is not protected, so this is allowed in combat too.
local sheathButton = CreateFrame("Button", "FGTGearPlannerSheath", P)
sheathButton:SetScript("OnClick", function()
    if not ForeverGoalTrackerDB or not Prefs() then return end
    Prefs().sheathed = not Sheathed() or nil
    ApplySheath()
end)
local function BindSheath()
    if not (SetOverrideBindingClick and ClearOverrideBindings) then return end
    pcall(ClearOverrideBindings, P)
    if not P:IsShown() then return end
    local first, second = "Z", nil
    if GetBindingKey then first, second = GetBindingKey("TOGGLESHEATH") end
    for _, key in ipairs({ first or false, second or false }) do
        if key then pcall(SetOverrideBindingClick, P, true, key, "FGTGearPlannerSheath", "LeftButton") end
    end
end
P:HookScript("OnShow", function() P:RegisterEvent("GET_ITEM_INFO_RECEIVED"); P:RegisterEvent("UPDATE_BINDINGS"); BindSheath() end)
P:HookScript("OnHide", function() P:UnregisterEvent("GET_ITEM_INFO_RECEIVED"); P:UnregisterEvent("UPDATE_BINDINGS"); BindSheath() end)
P:SetScript("OnEvent", function(_, event, itemId, ok)
    if event == "UPDATE_BINDINGS" then BindSheath(); return end
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
-- Right-drag moves the character, as in Blizzard's dressing room: the model follows the cursor,
-- a little less far when zoomed in. Another set puts it back in place.
local panX, panY
local function Pan()
    if not panX then return end
    if not IsMouseButtonDown("RightButton") then panX = nil; model:SetScript("OnUpdate", nil); return end
    local x, y = GetCursorPosition()
    local k = 1.6 / (math.max(1, modelArea:GetHeight()) * model:GetEffectiveScale()) * (1 - (zoom or 0) * 0.6)
    offsetY = math.max(-1.5, math.min(1.5, offsetY + (x - panX) * k))
    offsetZ = math.max(-1.5, math.min(1.5, offsetZ + (y - panY) * k))
    targetY, targetZ = offsetY, offsetZ
    panX, panY = x, y
    ApplyZoom(zoom)
end
model:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then
        turn:SetScript("OnUpdate", nil)
        dragX = GetCursorPosition(); model:SetScript("OnUpdate", Rotate)
    elseif button == "RightButton" then
        camera:SetScript("OnUpdate", nil)
        panX, panY = GetCursorPosition(); model:SetScript("OnUpdate", Pan)
    end
end)
model:SetScript("OnMouseUp", function() dragX, panX = nil, nil; model:SetScript("OnUpdate", nil) end)
-- The wheel glides: each frame the camera closes part of the remaining distance to where you have
-- scrolled (exponential ease-out), so quick clicks add up into one continuous move instead of
-- restarting a tween from a standstill each time. A return to the resting view in progress hands
-- over without a jump: its offsets glide on to their target from wherever they are.
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
    targetZoom = math.max(0, math.min(MAX_ZOOM, targetZoom + delta * 0.1))
    if FGT.Setting("celebrations") == "off" then
        camera:SetScript("OnUpdate", nil); offsetY, offsetZ = targetY, targetZ; ApplyZoom(targetZoom); return
    end
    camera:SetScript("OnUpdate", camera.Glide)
end)

-- Goal-art treatment belongs below the character and equipment controls.
-- Keep the same panel colors/top veil, with broad side fades and an eased bottom.
-- A soft light behind the character (the goal banners' Media/glow, additive, neutral white so the
-- scenery stays black and white), behind the body. Drawn above the
-- scenery and under the shading, so the edges stay dark; still, never animated. When zoomed, the
-- camera centres what is focused, so the light grows there. (A second faint pool at the feet was
-- dropped when the feet got their drop shadow: over dark ground it read as a stray white patch.)
-- On by default; /goals plannerlight switches it (Prefs().light == false is off).
background.light = background:CreateTexture(nil, "BORDER")
do
    local t = background.light
    t:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
    t:SetBlendMode("ADD"); t:SetVertexColor(1, 1, 1)
end
-- A drop shadow under the feet, in the edge shading's colour, over the light: it grounds the
-- character on any backdrop, and fades away as zooming takes the feet out of view. The feet rest
-- 78.5% down the panel and drop about half the zoom's change as the camera closes in. Pulled all
-- the way back, every race's feet reach about 70%, so zooming out rises from the resting line to
-- that. The resting line varies by race (short races stand higher).
background.shadowFeet = { Gnome = 0.755, Human = 0.80 }
background.shadow = background:CreateTexture(nil, "ARTWORK")
background.shadow:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\glow")
background.shadow:SetVertexColor(textVeil.SIDE[1], textVeil.SIDE[2], textVeil.SIDE[3])
function background.PaintLight()
    -- (layout can run before the saved data loads: the light is on until a saved choice says off)
    local on = not ForeverGoalTrackerDB or Prefs().light ~= false
    local w, h = modelArea:GetWidth() or 0, modelArea:GetHeight() or 0
    local closer = math.max(0, (zoom or REST_ZOOM) - REST_ZOOM) -- measured from the resting view
    local feet = math.max(0, 1 - closer * 2.5)
    if background.ground[background.race] and w > 0 then background.Place(w, h) end
    background.shadow:SetShown(h > 0 and feet > 0)
    if h > 0 then
        background.shadow:ClearAllPoints()
        local rest = background.shadowFeet[background.race] or 0.785
        background.shadow:SetPoint("CENTER", model, "CENTER", 0, -h * (rest + background.FeetMove() - 0.5))
        background.shadow:SetSize(math.min(w, h * 0.56), h * 0.105)
        background.shadow:SetAlpha(0.9 * feet)
    end
    background.light:SetShown(on and h > 0)
    if not on or h <= 0 then return end
    local grow = 1 + closer * 0.6
    background.light:ClearAllPoints(); background.light:SetPoint("CENTER", model, "CENTER", 0, h * 0.06)
    background.light:SetSize(math.min(w, h * 0.62 * grow), h * 0.85 * grow)
    background.light:SetAlpha(0.09)
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
-- How far the feet have moved from the resting line (a share of the panel's height, down is
-- positive): in with the camera 0.5 of the zoom, out to 70% when pulled all the way back, and
-- lower in narrower windows, where the camera comes closer (its distance scales with the aspect,
-- down to 1). The resting lines were measured at the default size (aspect 1.93). The backdrop
-- (`outOnly`) leaves the zooming in alone: the feet are out of view by then.
function background.FeetMove(outOnly)
    local rest = background.shadowFeet[background.race] or 0.785
    local fromRest = (zoom or REST_ZOOM) - REST_ZOOM
    if outOnly then fromRest = math.min(0, fromRest) end
    local zoomed = fromRest * (fromRest > 0 and 0.5 or (rest - 0.70) / REST_ZOOM)
    return zoomed + 0.157 * (1 / cameraAspect - 1 / 1.93)
end
-- Cover the panel without stretching the portrait composition. A backdrop with a set place to
-- stand is placed at the feet; pulling the camera back lifts the feet, so the ground follows them
-- up (the shadow's line, see PaintLight) instead of leaving the character over the sky.
function background.Place(w, h)
    if w <= 0 or h <= 0 then return end
    local scale = math.max(w / 318, h / 383)
    local x, y = (w - 318 * scale) / 2, (h - 383 * scale) / 2
    local ground = background.ground[background.race]
    if ground then
        y = math.max(h - 383 * scale, math.min(0, (background.FEET + background.FeetMove(true)) * h - ground * 383 * scale))
    end
    background.texture:ClearAllPoints()
    background.texture:SetPoint("TOPLEFT", modelArea, "TOPLEFT", x, -y)
    background.texture:SetSize(318 * scale, 383 * scale)
end
local function LayoutPreview(self, w, h)
    if w <= 0 or h <= 0 then return end
    -- Draw across the full panel: a narrow model frame slices enlarged geometry.
    -- Compensate camera distance for its wider aspect instead of clipping the model.
    cameraAspect = math.max(1, (model.frozenW or w) / h / 0.85)
    background.Place(w, h)
    ShadeBackground(w, h)
    background.PaintLight()
    if textVeil.Place then textVeil.Place() end
    ApplyZoom(zoom)
end
modelArea:SetScript("OnSizeChanged", LayoutPreview)
function background.Layout()
    local w, h = modelArea:GetWidth() or 0, modelArea:GetHeight() or 0
    if w > 0 and h > 0 then LayoutPreview(modelArea, w, h) end
end
-- While the sets drawer slides, the character's frame holds one width and follows the stage's
-- centre, instead of being resized every frame; it fills the stage again when the slide ends.
function SD.onSlide(stageW)
    if stageW then
        model.frozenW = math.max(1, stageW - 8)
        model:ClearAllPoints()
        model:SetPoint("TOP", modelArea, "TOP"); model:SetPoint("BOTTOM", modelArea, "BOTTOM")
        model:SetWidth(model.frozenW)
    elseif model.frozenW then
        model.frozenW = nil
        model:ClearAllPoints(); model:SetAllPoints(modelArea)
    else
        return
    end
    LayoutPreview(modelArea, modelArea:GetWidth() or 0, modelArea:GetHeight() or 0)
end

-- ------------------------------------------------------------
-- Equipment slots
-- ------------------------------------------------------------
-- Stage controls above the character: the turn buttons and their hints.
local controls = CreateFrame("Frame", nil, right)
controls:SetAllPoints(); controls:SetFrameLevel(model:GetFrameLevel() + 3)
-- The slot column, top to bottom, in four groups.
local GROUPS = { { "Armor", "ARMOR" }, { "Jewelry", "JEWELRY" }, { "Weapons", "WEAPONS" }, { "Extras", "EXTRAS" } }
local slots = {
    {"HeadSlot", "Head", "Armor"}, {"ShoulderSlot", "Shoulders", "Armor"}, {"BackSlot", "Back", "Armor"},
    {"ChestSlot", "Chest", "Armor"}, {"WristSlot", "Wrists", "Armor"}, {"HandsSlot", "Hands", "Armor"},
    {"WaistSlot", "Waist", "Armor"}, {"LegsSlot", "Legs", "Armor"}, {"FeetSlot", "Feet", "Armor"},
    {"NeckSlot", "Neck", "Jewelry"}, {"Finger0Slot", "Finger 1", "Jewelry"}, {"Finger1Slot", "Finger 2", "Jewelry"},
    {"Trinket0Slot", "Trinket 1", "Jewelry"}, {"Trinket1Slot", "Trinket 2", "Jewelry"},
    {"MainHandSlot", "Main Hand", "Weapons"}, {"SecondaryHandSlot", "Off Hand", "Weapons"},
    {"RangedSlot", "Ranged", "Weapons"}, {"AmmoSlot", "Ammo", "Weapons"}, {"QuiverSlot", "Quiver", "Weapons"},
    {"ShirtSlot", "Shirt", "Extras"}, {"TabardSlot", "Tabard", "Extras"},
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
function LG.TooHigh(item) return item.req > 1 and item.req > (LV.Target().level or 60) end
function LG.ReqText(item)
    if item.req <= 1 then return "No level requirement" end
    return LG.TooHigh(item) and ("|cffff5a4aReq " .. item.req .. "|r") or ("Req " .. item.req)
end
function LG.Open(goal) if goal and FGT.OpenLinkCard then GameTooltip:Hide(); FGT.OpenLinkCard(goal.id) end end
-- What the set's character wears and has: the logged-in character asks the game (bags, bank and
-- worn); another character shows what was saved at their last login.
function LG.Wears(itemId)
    local who = Who()
    if who.me and GetInventoryItemID then
        for slot = 1, 19 do if GetInventoryItemID("player", slot) == itemId then return true end end
        return false
    end
    local c = (ForeverGoalTrackerDB.characters or {})[who.key]
    for _, id in pairs(c and c.worn or {}) do if id == itemId then return true end end
    return false
end
function LG.Has(itemId)
    if LG.Wears(itemId) then return true end
    local who = Who()
    if who.me then
        local count = (C_Item and C_Item.GetItemCount) or rawget(_G, "GetItemCount")
        if count then
            local ok, n = pcall(count, itemId, true)
            if ok and (n or 0) > 0 then return true end
        end
    end
    local c = (ForeverGoalTrackerDB.characters or {})[who.key]
    return ((c and c.items and c.items[itemId]) or 0) > 0
end
-- A row reads: icon, name, the enhancement, the owned check. The name ends where the
-- enhancement begins (a "+" square, or the planned one's icon in a green frame).
function EN.Anchor(button)
    local ench = button.enchant
    local stop = (ench.applied:IsShown() and ench.applied) or (ench:IsShown() and ench) or button.owned
    button.itemName:ClearAllPoints()
    button.itemName:SetPoint("LEFT", button.icon, "RIGHT", 7, 0)
    button.itemName:SetPoint("RIGHT", stop, "LEFT", -6, 0)
end
-- Enchants only stay on a planned item that can take them.
function EN.Prune(build)
    if not (build and build.enchants) then return end
    for slot, spell in pairs(build.enchants) do
        if not Cat.EnchantFits(spell, Cat.Get(build.slots[slot])) then build.enchants[slot] = nil end
    end
    if next(build.enchants) == nil then build.enchants = nil end
end
-- The slot column: "Equipment" and how many slots are filled, then the groups' rows in a scroll
-- area with the shared scroll bar and edge fades (short windows scroll; nothing is cut off).
local SLOT_ROW, GROUP_H = 26, 24
left.title = Label(left, "Equipment", 16, 16, -16)
left.count = U.font(left, 11); left.count:SetPoint("TOPRIGHT", left, "TOPRIGHT", -16, -19)
left.count:SetJustifyH("RIGHT"); left.count:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
local slotList = U.scroll(left)
slotList.scroll:ClearAllPoints(); slotList.scroll:SetPoint("TOPLEFT", 10, -42)
slotList.scroll:SetPoint("BOTTOMRIGHT", -16, 12)
slotList:Finalize()
slotList.trackHit:ClearAllPoints()
slotList.trackHit:SetPoint("TOP", slotList.scroll, "TOPRIGHT", 8, 0)
slotList.trackHit:SetPoint("BOTTOM", slotList.scroll, "BOTTOMRIGHT", 8, 0)
local groupLabels = {}
for _, g in ipairs(GROUPS) do groupLabels[g[1]] = Eyebrow(slotList.content, g[2]) end
-- A planned enhancement shows its icon in a green frame (the effect is in its tooltip; Karl,
-- 2026-10-24: effect text ran long). Brighter green on hover, gold while its pop-out is open.
EN.EDGE = { edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
function EN.PaintApplied(t)
    if t.chosen then t:SetBackdropBorderColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3], 1)
    elseif t.hovered then t:SetBackdropBorderColor(0.55, 1, 0.48, 1)
    else t:SetBackdropBorderColor(0.12, 1, 0, 0.9) end
end
for _, spec in ipairs(slots) do
    slotSpec[spec[1]] = spec
    local button = Button(slotList.content, "", 200, SLOT_ROW - 2)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(18, 18); button.icon:SetPoint("LEFT", 4, 0); button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.plannerSlot = spec[1]
    button.icon:SetTexture(FGT.GearPlannerSlotTexture(spec[1]))
    button.itemName = U.font(button, 11)
    button.itemName:SetText(""); button.itemName:SetWordWrap(false); button.itemName:SetJustifyH("LEFT")
    -- an empty slot shows its name instead, smaller and grey
    button.slotName = U.font(button, 9); button.slotName:SetWordWrap(false); button.slotName:SetJustifyH("LEFT")
    button.slotName:SetPoint("LEFT", button.itemName, "LEFT"); button.slotName:SetPoint("RIGHT", button.itemName, "RIGHT")
    -- the owned check sits at the far right; its place is kept so the checks line up
    button.owned = button:CreateTexture(nil, "OVERLAY")
    button.owned:SetTexture(FGT.Icon("check")); button.owned:SetSize(12, 12); button.owned:SetPoint("RIGHT", -6, 0)
    button.owned:SetVertexColor(colors.DONE[1], colors.DONE[2], colors.DONE[3]); button.owned:SetAlpha(0)
    slotButtons[spec[1]] = button
    -- the "+" square: this item can take an enhancement and none is planned
    local ench = Button(button, "+", 18, 18, 12)
    ench:SetFrameLevel(button:GetFrameLevel() + 2)
    ench.text:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
    ench:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ench.plannerSlot, ench.planned = spec[1], false
    ench:SetPoint("RIGHT", button.owned, "LEFT", -6, 0)
    ench:Hide()
    button.enchant = ench
    -- the planned enhancement: its icon in a green frame
    local applied = CreateFrame("Button", nil, button, "BackdropTemplate")
    -- the "+" square's size, the icon inside the 1px frame
    applied:SetSize(18, 18); applied:SetFrameLevel(button:GetFrameLevel() + 2)
    applied:SetBackdrop(EN.EDGE)
    applied.icon = applied:CreateTexture(nil, "ARTWORK")
    applied.icon:SetPoint("TOPLEFT", 1, -1); applied.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    applied.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    applied:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    applied.plannerSlot = spec[1]
    applied:SetPoint("RIGHT", button.owned, "LEFT", -6, 0)
    applied:Hide(); EN.PaintApplied(applied)
    ench.applied = applied
end
-- Stack the groups: rows the character has (ammo only for classes that shoot, a quiver only for
-- Hunters), each group under its small heading.
local function LayoutSlots()
    local class = Who().class
    local ammo, quiver = Cat.UsesAmmo(class), Cat.UsesQuiver(class)
    slotButtons.AmmoSlot:SetShown(ammo)
    slotButtons.QuiverSlot:SetShown(quiver)
    local width = math.max(120, (slotList.scroll:GetWidth() or 260))
    local y = 0
    for _, g in ipairs(GROUPS) do
        local label = groupLabels[g[1]]
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", slotList.content, "TOPLEFT", 4, -(y + 8))
        y = y + GROUP_H
        for _, spec in ipairs(slots) do
            local button = slotButtons[spec[1]]
            if spec[3] == g[1] and button:IsShown() then
                button:ClearAllPoints(); button:SetPoint("TOPLEFT", slotList.content, "TOPLEFT", 0, -y)
                button:SetWidth(width)
                EN.Anchor(button)
                y = y + SLOT_ROW
            end
        end
        y = y + 4
    end
    slotList.content:SetWidth(width)
    slotList.content:SetHeight(math.max(1, y))
    band.bar:SetWidth(math.max(60, (left:GetWidth() or 300) - 32)) -- In My Goals' bar spans the column
    slotList:Update()
end
left.Layout = LayoutSlots
slotList.scroll:HookScript("OnSizeChanged", LayoutSlots)
-- Over the scenery: a darker band behind the name at the top and behind the totals at the bottom.
function textVeil.Place()
    local h = modelArea:GetHeight() or 0
    for i = 1, 2 do textShades[i]:Hide() end
    local top, bottom = textShades[3], textShades[4]
    top:ClearAllPoints(); top:SetPoint("TOPLEFT", modelArea); top:SetPoint("TOPRIGHT", modelArea)
    top:SetHeight(math.min(96, h * 0.2)) -- the set name and its line
    bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", modelArea); bottom:SetPoint("BOTTOMRIGHT", modelArea)
    bottom:SetHeight(math.min(120, h * 0.22)) -- the set totals tab
end
right:HookScript("OnSizeChanged", function()
    left.Fit()
    if textVeil.Place then textVeil.Place() end
end)
local head = slotButtons.HeadSlot

-- ------------------------------------------------------------
-- The item picker: search, filters and a recycled list
-- ------------------------------------------------------------
-- It pops out flush against the slot column, as tall as the column, over the edge of the stage.
-- It never reaches past the window: on a narrow window it narrows (to PICKER_MIN_W at the least).
local PICKER_W, PICKER_MIN_W = 340, 250
local picker = CreateFrame("Frame", nil, P, "BackdropTemplate")
picker:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0); picker:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 0, 0)
picker:SetFrameLevel(math.max(right:GetFrameLevel(), drawer:GetFrameLevel()) + 50)
picker:EnableMouse(true)
picker:SetWidth(PICKER_W); U.etch(picker, { top = { 0.08, 0.072, 0.062 }, bottom = { 0.022, 0.022, 0.022 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
picker:Hide()
-- a soft shadow on the stage beside it
picker.shade = picker:CreateTexture(nil, "BACKGROUND", nil, -8)
picker.shade:SetTexture("Interface\\Buttons\\WHITE8X8")
picker.shade:SetPoint("TOPLEFT", picker, "TOPRIGHT", -2, -4); picker.shade:SetPoint("BOTTOMLEFT", picker, "BOTTOMRIGHT", -2, 4)
picker.shade:SetWidth(18)
U.gradient(picker.shade, { 0, 0, 0 }, { 0, 0, 0 }, 0.55, 0)
picker.title = U.title(picker, 15); picker.title:SetPoint("TOPLEFT", 16, -16)
picker.close = CreateFrame("Button", nil, picker)
picker.close:SetSize(24, 24); picker.close:SetPoint("TOPRIGHT", -10, -11)
FGT.IconButton(picker.close, "close-white", 11)
picker.close.icon:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
picker.close:SetScript("OnEnter", function(self) self.icon:SetVertexColor(colors.ACCENT[1], colors.ACCENT[2], colors.ACCENT[3]) end)
picker.close:SetScript("OnLeave", function(self) self.icon:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3]) end)
local search = SearchBox(picker, "Search items or sets")
search:SetPoint("TOPLEFT", 12, -46); search:SetPoint("TOPRIGHT", -12, -46)
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
local pickerList = U.scroll(picker)
pickerList.scroll:ClearAllPoints()
pickerList.scroll:SetPoint("TOPLEFT", picker, "TOPLEFT", 12, -112)
pickerList.scroll:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -20, 30)
-- the level range lives here, under the filters (item mode only)
for _, part in ipairs({ LV.label, LV.min, LV.dash, LV.box }) do part:SetParent(picker) end
LV.min:SetFrameLevel(picker:GetFrameLevel() + 3); LV.box:SetFrameLevel(picker:GetFrameLevel() + 3)
local pickerNote = Label(picker, "", 10, 12, -380)
pickerNote:ClearAllPoints(); pickerNote:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", 12, 10)
pickerNote:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -12, 10)
pickerNote:SetJustifyH("LEFT"); pickerNote:SetWordWrap(false)
pickerNote:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
local noResults = Label(picker, "", 11, 14, -96)
noResults:SetWidth(PICKER_W - 40); noResults:SetJustifyH("LEFT")
noResults:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
local found, foundCount, resultRows = {}, 0, {}
-- A filled slot's picker starts with its planned item: Remove, and its goal (a Library goal to
-- open or add, or its own goal).
local menu = CreateFrame("Frame", nil, picker)
menu:SetHeight(58); menu:Hide()
menu.item = U.font(menu, 12); menu.item:SetPoint("TOPLEFT", 2, -4); menu.item:SetPoint("RIGHT", menu, "RIGHT", -76, 0)
menu.item:SetJustifyH("LEFT"); menu.item:SetWordWrap(false)
-- Everything in the picker stacks from the top: title, planned item, search, filters, level range,
-- then the list. Widths follow the picker's own width.
function FL.Layout()
    local w = picker:GetWidth() or PICKER_W
    local y = 44
    if menu:IsShown() then
        menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", 12, -y); menu:SetPoint("TOPRIGHT", -12, -y)
        y = y + menu:GetHeight() + 6
    end
    search:ClearAllPoints(); search:SetPoint("TOPLEFT", 12, -y); search:SetPoint("TOPRIGHT", -12, -y)
    y = y + 24 + 6
    local shown = {}
    for _, b in ipairs({ FL.stat, FL.kind, FL.quality }) do if b:IsShown() then shown[#shown + 1] = b end end
    local width = (w - 24 - 4 * (#shown - 1)) / math.max(1, #shown)
    for i, b in ipairs(shown) do
        b:SetWidth(width); b:ClearAllPoints()
        b:SetPoint("TOPLEFT", picker, "TOPLEFT", 12 + (i - 1) * (width + 4), -y)
    end
    if #shown > 0 then y = y + 22 + 8 end
    local level = not EN.mode
    for _, part in ipairs({ LV.label, LV.min, LV.dash, LV.box }) do part:SetShown(level) end
    if level then
        LV.label:ClearAllPoints(); LV.label:SetPoint("TOPLEFT", picker, "TOPLEFT", 14, -(y + 4))
        y = y + 20 + 8
    end
    pickerList.scroll:ClearAllPoints()
    pickerList.scroll:SetPoint("TOPLEFT", picker, "TOPLEFT", 12, -y)
    pickerList.scroll:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -20, 30)
    noResults:ClearAllPoints(); noResults:SetPoint("TOPLEFT", picker, "TOPLEFT", 14, -(y + 8)); noResults:SetWidth(w - 40)
    if LG.menuBtn then LG.menuBtn.text:SetWidth(math.max(80, w - 60)) end
end
local function Deselect()
    GameTooltip:Hide()
    selectedSlot = nil; EN.mode = false; picker:Hide(); menu:Hide(); search:ClearFocus()
    for _, button in pairs(slotButtons) do
        button.chosen = false; PaintButton(button)
        button.enchant.chosen = false; PaintButton(button.enchant)
        button.enchant.applied.chosen = false; EN.PaintApplied(button.enchant.applied)
    end
    -- a hidden helm or the other weapons go back once their slot is no longer being chosen
    -- (a gear fade under way repaints at its midpoint anyway)
    if VIEW.painted and VIEW.painted ~= VIEW.Signature() and not appearance:GetScript("OnUpdate") then PaintGear() end
end
picker.close:SetScript("OnClick", function() Deselect() end)
local clickAway = CreateFrame("Frame", nil, P)
P:HookScript("OnShow", function() clickAway:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
P:HookScript("OnHide", function() clickAway:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
clickAway:SetScript("OnEvent", function()
    if actions:IsShown() and not actions:IsMouseOver() and not options:IsMouseOver() then actions:Hide() end
    if FL.popup:IsShown() and not FL.popup:IsMouseOver() and not (FL.popup.owner and FL.popup.owner:IsMouseOver()) then
        FL.popup:Hide()
    end
    if charMenu:IsShown() and not charMenu:IsMouseOver() and not ownerBtn:IsMouseOver() then charMenu:Hide() end
    if switchMenu:IsShown() and not switchMenu:IsMouseOver() and not switch:IsMouseOver() then switchMenu:Hide() end
    if not selectedSlot then return end
    if picker:IsShown() and picker:IsMouseOver() then return end
    local row = slotButtons[selectedSlot]
    if row and (row:IsMouseOver() or row.enchant:IsMouseOver() or row.enchant.applied:IsMouseOver()) then return end
    -- the scenery stays usable while choosing: turning, zooming and moving keep the picker open
    if model:IsMouseOver() or controls:IsMouseOver() then return end
    Deselect()
end)
local replace = Button(menu, "Replace", 66, 22, 10); replace:SetPoint("TOPRIGHT", 0, -2); replace:Hide()
local unequip = Button(menu, "Remove", 66, 22, 10); unequip:SetPoint("TOPRIGHT", 0, -2)
unequip:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Empty this slot", 1, 1, 1); GameTooltip:Show()
end)
unequip:HookScript("OnLeave", function() GameTooltip:Hide() end)
-- The item's Library goal (open or add it), or, for any other item, its own goal.
LG.menuBtn = Button(menu, "", 150, 24, 10)
LG.menuBtn:SetPoint("TOPLEFT", 0, -30); LG.menuBtn:SetPoint("TOPRIGHT", 0, -30)
LG.menuBtn.text:SetWidth(240); LG.menuBtn.text:SetWordWrap(false); LG.menuBtn.text:SetJustifyH("CENTER")
-- A Library goal gets the guides' gold: gold text and border, and the picker's goal mark.
LG.menuBtn.mark = LG.menuBtn:CreateTexture(nil, "OVERLAY")
LG.menuBtn.mark:SetTexture(LG.ICON); LG.menuBtn.mark:SetSize(12, 12); LG.menuBtn.mark:Hide()
local Refresh, Results, PickSet

-- A short line for the set: how much of it is filled, and the average item level
-- (countOnly: just "17 of 21 filled", for the set cards).
local function Summary(build, countOnly)
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
    if countOnly then return string.format("%d of %d filled", count, slotsShown) end
    return string.format("%d of %d slots filled", count, slotsShown)
        .. (scored > 0 and string.format("\nAverage item level %d", math.floor(total / scored + 0.5)) or "")
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
-- The gallery's Gear Planner shot keeps the logged-in character's own model when the pretend character
-- shares their race and sex, so its hair and face are the player's, not the game's default (FGT.GearPlannerDemo).
local function OwnLook(who)
    if not FGT.demoOwnLook then return false end
    local _, race = UnitRace("player")
    return race == who.race and UnitSex ~= nil and UnitSex("player") == who.sex
end
local function Choose(build)
    actions:Hide(); cleared, clearedBuild, clearedItems, clearedProgress = nil, nil, nil, nil
    selected = build; changing = true; name:SetText(build and build.name or ""); changing = false
    editingName = false
    Deselect(); RestCamera()
    LayoutSlots()
    local who = Who()
    if modelOwner ~= who.key then
        modelOwner = who.key; model:SetUnit("player")
        -- another character: their race on the model where the game allows it (SetCustomRace
        -- takes 0 male, 1 female); otherwise this character's model wears their gear
        if not who.me and model.SetCustomRace and RACE_IDS[who.race or ""] and not OwnLook(who) then
            pcall(model.SetCustomRace, model, RACE_IDS[who.race], who.sex == 3 and 1 or 0)
        end
        background:SetRace(who.race)
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
    if item and not selected and selectedSlot then ES.StartFor() end -- the welcome: the pick starts a set
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
    if anchor and anchor.set > 0 and not selected and selectedSlot then ES.StartFor() end
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
-- What kind of enhancement it is, by its name: not every effect is an enchant.
function EN.Kind(e)
    local n = e.name or ""
    if e.enchanting then return "Enchant" end
    if n:find("Armor Kit") or n:find("Armor Patch") then return "Armor kit" end
    if n:find("Scope") or n:find("Accurascope") then return "Scope" end
    if n:find("Arcanum") then return "Arcanum" end
    if n:find("Libram") then return "Libram" end
    return "Enhancement"
end
-- "Enchant · Enchanting", "Armor kit · Applied from the item"
function EN.KindLine(e) return EN.Kind(e) .. " · " .. Cat.EnchantSource(e) end
-- The game writes effects both ways round ("Strength +9", "+3% Hit") and joins some
-- ("Attack Power +10 and Armor +40", "Defense +7/Stamina +10"): each part as { number, "%" or "", stat }.
function EN.Effects(e)
    local out, chunks = {}, {}
    for chunk in ((e and e.text) or ""):gmatch("[^/]+") do
        local a, b = chunk:match("^(.-) and (.+)$")
        if a and a:find("%d") and b:find("%d") then chunks[#chunks + 1] = a; chunks[#chunks + 1] = b
        else chunks[#chunks + 1] = chunk end
    end
    for _, chunk in ipairs(chunks) do
        chunk = chunk:match("^%s*(.-)%s*$")
        local n, pct, what = chunk:match("^%+(%d+)(%%?)%s+(.+)$")
        if not n then what, n, pct = chunk:match("^(.-)%s+%+(%d+)(%%?)$") end
        if n and what and what ~= "" then out[#out + 1] = { tonumber(n), pct, what } end
    end
    return out
end
-- An enhancement row: its short name, then what it does, its kind and how it is applied.
function EN.BindRow(row, e)
    row.icon:SetTexture(Cat.EnchantIcon(e))
    row.text:SetText(e.short); row.text:SetTextColor(0.12, 1, 0)
    row.quality = nil
    row.chosen = selected and selectedSlot and selected.enchants
        and selected.enchants[slotIds[selectedSlot]] == e.spell or false
    local effect = (e.text ~= "" and e.text ~= e.short) and (e.text .. " · ") or ""
    row.source:SetText(effect .. EN.KindLine(e))
    row.tag:SetText(row.chosen and "Selected" or ""); row.worn:SetText("")
    row.tags:SetWidth(math.max(1, row.tag:GetStringWidth() or 0))
    row.entrance = nil; row.pin:Hide(); row.setBtn:Hide(); row.goal = nil; row.goalBtn:Hide()
    row.tags:ClearAllPoints(); row.tags:SetPoint("TOPRIGHT", -8, -5)
    row.text:SetPoint("RIGHT", row.tags, "LEFT", -6, 0)
    PaintButton(row)
    row:Show()
end
-- Enhancement tooltip: name, effect, kind, how it is applied and what it costs.
function EN.Tooltip(owner, e, hint, place)
    GameTooltip:SetOwner(owner, place and "ANCHOR_NONE" or "ANCHOR_RIGHT")
    if place then GameTooltip:ClearAllPoints(); place(GameTooltip) end
    GameTooltip:SetText(e.name, 1, 1, 1)
    if e.text ~= "" and e.text ~= e.short then GameTooltip:AddLine(e.text, 0.12, 1, 0, true) end
    GameTooltip:AddLine(EN.KindLine(e), 0.8, 0.75, 0.65)
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
    row.source:SetText((state == "new" and "|cff66a6ffNew in Forever|r · " or state == "updated" and "|cff66a6ffUpdated in Forever|r · " or "")
        .. line .. " · " .. sourceLine)
    -- gold "Selected" for the set's item; grey "EQUIPPED" for what the character wears
    row.tag:SetText(row.chosen and "Selected" or "")
    row.worn:SetText(LG.Wears(item.id) and "EQUIPPED" or "")
    row.tags:SetWidth(math.max(1, row.tag:GetStringWidth() or 0, row.worn:GetStringWidth() or 0))
    local source = Cat.Source(item)
    local entrance = source and source.place and Cat.EntranceFor(source.place)
    row.entrance = entrance
    row.pin:SetShown(entrance ~= nil)
    row.setBtn:SetShown(item.set > 0 and Cat.SetName(item.set) ~= nil)
    -- the goal mark sits left of the map pin; the tags left of both; the name makes room
    row.goal, row.goalKind = LG.For(item.id)
    row.goalBtn:SetShown(row.goal ~= nil)
    row.goalBtn:ClearAllPoints()
    row.goalBtn:SetPoint("TOPRIGHT", entrance and -28 or -6, -4)
    row.tags:ClearAllPoints()
    row.tags:SetPoint("TOPRIGHT", -8 - (entrance and 22 or 0) - (row.goal and 22 or 0), -5)
    row.text:SetPoint("RIGHT", row.tags, "LEFT", -6, 0)
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
        -- tags beside the name: "Selected" (gold) over "EQUIPPED" (grey)
        row.tags = CreateFrame("Frame", nil, row); row.tags:SetSize(1, 30)
        row.tag = U.font(row.tags, 10); row.tag:SetPoint("TOPRIGHT"); row.tag:SetJustifyH("RIGHT")
        row.tag:SetTextColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
        row.worn = U.font(row.tags, 8); row.worn:SetPoint("TOPRIGHT", row.tag, "BOTTOMRIGHT", 0, -2); row.worn:SetJustifyH("RIGHT")
        row.worn:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
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
function FL.Level() return LV.Target().level or 60 end
function FL.MaxLevel() if LV.Target().level == false then return nil end return FL.Level() end
function FL.MinLevel() return LV.Target().minLevel end
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
    noResults:SetText(count == 0 and (text == "" and "No enhancements for this item." or "No matching enhancements.") or "")
    pickerNote:SetText(count == 0 and "" or (count .. (count == 1 and " enhancement" or " enhancements")))
end
-- Enhancements: the search and the list only (no filters, no level range). Items: the planned
-- item first when the slot has one, then the search, filters and level range.
function EN.PaintMode()
    FL.stat:SetShown(not EN.mode); FL.quality:SetShown(not EN.mode)
    if EN.mode then FL.kind:Hide() end
    FL.revealed:SetShown(not EN.mode and FGT.isForever and true or false)
    FL.showAll:Hide(); FL.popup:Hide()
    local label = selectedSlot and SlotLabel(selectedSlot) or ""
    picker.title:SetText(EN.mode and (label .. " enhancement") or label)
    local planned = not EN.mode and LG.Item()
    menu:SetShown(planned and true or false)
    if planned then
        local c = QUALITY[planned.q] or QUALITY[1]
        menu.item:SetText(planned.name); menu.item:SetTextColor(c[1], c[2], c[3])
        LG.PaintMenu()
    end
    FL.Layout()
    search.hint:SetText(EN.mode and ("Search " .. label:lower() .. " enhancements") or "Search items or sets")
    pickerNote:ClearAllPoints()
    if EN.mode then
        pickerNote:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", 12, 10); pickerNote:SetJustifyH("LEFT")
    else
        pickerNote:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -12, 10); pickerNote:SetJustifyH("RIGHT")
    end
    pickerNote:SetWidth((picker:GetWidth() or PICKER_W) - (EN.mode and 24 or 140))
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

-- Flush against the slot column, as tall as it; as wide as the window allows (never past its edge).
local function PlacePicker()
    local room = (U.main:GetRight() and left:GetRight()) and ((U.main:GetRight() - 16) - left:GetRight()) or PICKER_W
    picker:SetWidth(math.max(PICKER_MIN_W, math.min(PICKER_W, room)))
    -- enough recycled rows to fill the column's height
    POOL_ROWS = math.max(POOL_ROWS, math.ceil((left:GetHeight() or 460) / ROW_H) + 1)
end
-- stay: the picker was already open for another slot, so it stays solid rather than fading in
-- again from nothing (the welcome card showed through for a moment; Karl's recording, 2026-10-27)
local function OpenPicker(stay)
    if not selectedSlot then return end
    local row = slotButtons[selectedSlot]
    row.chosen = true; PaintButton(row)
    if EN.mode then
        local planned = row.enchant.applied
        if planned:IsShown() then planned.chosen = true; EN.PaintApplied(planned)
        else row.enchant.chosen = true; PaintButton(row.enchant) end
    end
    GameTooltip:Hide()
    FL.expanded = false
    if not EN.mode then FL.SetupKind() end
    PlacePicker(); search:SetText("")
    if stay == true then picker:SetScript("OnUpdate", nil); picker:SetAlpha(1); picker:Show() else FadeIn(picker) end
    PaintFilters(); EN.PaintMode(); LV.Show(); Results() -- (the level box: the welcome's level can change)
    -- the slot being chosen shows on the model even when hidden (helm, cloak, the other weapons)
    if VIEW.painted ~= VIEW.Signature() then PaintGear() end
end
P:HookScript("OnSizeChanged", function() if picker:IsShown() then PlacePicker(); FL.Layout(); EN.PaintMode() end end)

-- ------------------------------------------------------------
-- Slot buttons
-- ------------------------------------------------------------
for _, spec in ipairs(slots) do
    local slot = spec[1]
    local button = slotButtons[slot]
    -- A row opens the item picker beside the column (a filled slot shows its item first there).
    -- Off hand under a two-hand weapon has nothing to choose.
    button:SetScript("OnClick", function()
        if button.blocked then return end
        local open = picker:IsShown()
        Deselect(); selectedSlot = slot; OpenPicker(open)
    end)
    button:SetScript("OnEnter", function(self)
        self.hovered = true; Hover(self, true)
        PaintButton(self)
        local item = selected and Cat.Get(selected.slots[slotIds[slot]])
        if item then
            FGT.ShowItemTip(self, item.id, nil, item.name, false, function(tip)
                tip:AddLine(SlotLabel(slot), 0.8, 0.75, 0.65)
                tip:AddLine(" "); tip:AddLine(Cat.SourceLabel(item), 0.8, 0.75, 0.65, true)
                if LG.TooHigh(item) then
                    tip:AddLine("Requires level " .. item.req .. ". This set plans for level " .. (selected and selected.level or 60) .. ".", 1, 0.35, 0.29, true)
                end
                local goal = LG.For(item.id)
                if goal then
                    local A = FGT.GOAL_RGB or { 0.95, 0.75, 0.30 }
                    tip:AddLine("Library goal: " .. goal.name .. (LG.Active(goal) and " (in My Goals)" or ""), A[1], A[2], A[3], true)
                end
                if self.owned:GetAlpha() > 0 then tip:AddLine("You have it", colors.DONE[1], colors.DONE[2], colors.DONE[3]) end
                tip:AddLine("Click: change item", colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
            end, function(t) t:SetPoint("TOPLEFT", left, "TOPRIGHT", 8, 0) end)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(SlotLabel(slot), 1, 1, 1)
            GameTooltip:AddLine(self.blocked and "The two-hand weapon fills both hands" or "Choose item", 0.8, 0.75, 0.65)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self.hovered = false; Hover(self, false)
        PaintButton(self)
        GameTooltip:Hide()
    end)
    -- The enhancement: the "+" square (none planned) or the planned one's icon. Click: choose one;
    -- right-click the icon: remove it.
    local ench = button.enchant
    local function Choose(self, mouse)
        if not selected then return end
        if mouse == "RightButton" then
            if selected.enchants and selected.enchants[slotIds[slot]] then
                selected.enchants[slotIds[slot]] = nil
                Deselect(); Dress(true); Save(true); Refresh()
            end
            return
        end
        Deselect(); selectedSlot = slot; EN.mode = true
        OpenPicker()
    end
    ench:SetScript("OnClick", Choose)
    ench.applied:SetScript("OnClick", Choose)
    ench:SetScript("OnEnter", function(self)
        self.hovered = true; Hover(self, true); PaintButton(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Add enhancement", 1, 1, 1)
        GameTooltip:AddLine("An enchant, armor kit, scope or arcanum for this item", 0.8, 0.75, 0.65, true)
        GameTooltip:Show()
    end)
    ench:SetScript("OnLeave", function(self)
        self.hovered = false; Hover(self, false); PaintButton(self); GameTooltip:Hide()
    end)
    ench.applied:SetScript("OnEnter", function(self)
        self.hovered = true; EN.PaintApplied(self)
        local e = selected and selected.enchants and Cat.Enchant(selected.enchants[slotIds[slot]])
        if e then EN.Tooltip(self, e, "Click: change · Right-click: remove") end
    end)
    ench.applied:SetScript("OnLeave", function(self)
        self.hovered = false; EN.PaintApplied(self); GameTooltip:Hide()
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
    if show then button:ClearAllPoints(); button:SetPoint("TOPLEFT", 10, -menuY); menuY = menuY + 30 end
end
-- The drawer's "..." menu: new sets, the open set's actions, then the ones for every set.
function SD.PaintMenu()
    local store, who = Store(), Who()
    local tracked = selected and selected.goalId and ForeverGoalTrackerDB.active[selected.goalId]
    local anyTracked = false
    for _, build in ipairs(store.builds) do
        if build.goalId and ForeverGoalTrackerDB.active[build.goalId] then anyTracked = true end
    end
    local preset = Cat.PRESETS.hunter_preraid_wowhead
    menuY = 8
    Place(newSet, true)
    Place(newWorn, who.me and true or false) -- only the logged-in character's worn gear can be read
    Place(WI.menu, true)
    Place(fill, (who.me and selected ~= nil) and true or false)
    Place(duplicate, selected ~= nil and selected.id ~= nil)
    clear.text:SetText(clearedBuild == selected and "Undo clear" or "Clear selected set")
    Place(clear, selected ~= nil)
    usePreset.text:SetText("Use " .. preset.name)
    Place(usePreset, who.class == preset.class and who.faction == preset.faction)
    Place(remove, tracked and true or false)
    Place(rename, false); Place(delete, false) -- on the set cards
    actions.rule:ClearAllPoints()
    actions.rule:SetPoint("TOPLEFT", 14, -(menuY + 2)); actions.rule:SetPoint("TOPRIGHT", -14, -(menuY + 2))
    menuY = menuY + 6
    Place(removeAll, anyTracked)
    deleteAll.text:SetText(deleteAllArmed and "Click again to delete all" or "Delete all sets...")
    Place(deleteAll, #store.builds > 0)
    actions:SetHeight(menuY + 6)
end
-- A set card: its name and how far along it is; hovering shows Rename and Delete on its right.
function SD.Card(i)
    if rows[i] then return rows[i] end
    local row = Button(list.content, "", 180, 48); rows[i] = row
    row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 10, -8); row.text:SetPoint("RIGHT", row, "RIGHT", -64, 0)
    row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(false)
    row.state = U.font(row, 9); row.state:SetPoint("TOPLEFT", 10, -28); row.state:SetPoint("RIGHT", row, "RIGHT", -64, 0)
    row.state:SetJustifyH("LEFT"); row.state:SetWordWrap(false)
    row.state:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
    -- a set in My Goals shows its goal's progress along the card's foot
    row.bar = U.bar(row, 4); row.bar:SetPoint("TOPLEFT", 10, -39); row.bar.label:Hide(); row.bar:Hide()
    row:SetScript("OnClick", function(self) Store().selected = self.build.id; Choose(self.build) end)
    local function Action(icon, danger)
        local b = CreateFrame("Button", nil, row)
        b:SetSize(24, 24); b:SetFrameLevel(row:GetFrameLevel() + 3)
        FGT.IconButton(b, icon, 13)
        b.icon:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
        b:SetScript("OnLeave", function(self)
            self.icon:SetVertexColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
            GameTooltip:Hide(); row.ShowActions(row:IsMouseOver())
        end)
        b.hot = danger and { 1, 0.48, 0.40 } or colors.ACCENT
        b:Hide()
        return b
    end
    row.ren, row.del = Action("pencil-white"), Action("trash-white", true)
    row.del:SetPoint("RIGHT", -8, 0); row.ren:SetPoint("RIGHT", row.del, "LEFT", -2, 0)
    function row.ShowActions(on)
        row.ren:SetShown(on); row.del:SetShown(on)
        if not on then row.del.armed = nil end
    end
    for b, tip in pairs({ [row.ren] = "Rename", [row.del] = "Delete" }) do
        b:SetScript("OnEnter", function(self)
            self.icon:SetVertexColor(self.hot[1], self.hot[2], self.hot[3]); row.ShowActions(true)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.armed and "Click again to delete" or tip, 1, 1, 1); GameTooltip:Show()
        end)
    end
    row:HookScript("OnEnter", function() row.ShowActions(true) end)
    row:HookScript("OnLeave", function() row.ShowActions(row:IsMouseOver()) end)
    row.ren:SetScript("OnClick", function()
        local build = row.build
        Store().selected = build.id
        if build ~= selected then Choose(build) end
        if SD.Rename then SD.Rename() end
    end)
    row.del:SetScript("OnClick", function(self)
        if not self.armed then
            self.armed = true
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Click again to delete", 1, 1, 1); GameTooltip:Show()
            return
        end
        self.armed = nil; GameTooltip:Hide()
        if SD.Delete then SD.Delete(row.build) end
    end)
    return row
end
-- The chevron beside the set name: every set, the open one checked; "Manage gear sets..." opens the drawer.
function SD.PaintSwitch()
    local store, y, width = Store(), 6, 270
    for _, r in ipairs(switchMenu.rows) do r:Hide() end
    local i = 0
    for _, build in ipairs(store.builds) do
        if build.name ~= "" then
            i = i + 1
            local r = switchMenu.rows[i]
            if not r then
                r = Button(switchMenu, "", width - 12, 26, 11); switchMenu.rows[i] = r
                r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 26, 0); r.text:SetPoint("RIGHT", -8, 0)
                r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
                r.check = r:CreateTexture(nil, "OVERLAY"); r.check:SetTexture(FGT.Icon("check"))
                r.check:SetSize(11, 11); r.check:SetPoint("LEFT", 9, 0)
                r.check:SetVertexColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
                r:SetScript("OnClick", function(self) switchMenu:Hide(); Store().selected = self.build.id; Choose(self.build) end)
            end
            r.build = build; r.text:SetText(build.name); r.check:SetShown(build == selected)
            r.chosen = build == selected; PaintButton(r)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 6, -y); r:Show(); y = y + 28
        end
    end
    if not switchMenu.manage then
        switchMenu.manage = Button(switchMenu, "Manage gear sets...", width - 12, 24, 10)
        switchMenu.manage.text:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
        switchMenu.manage:SetScript("OnClick", function()
            switchMenu:Hide()
            if not SD.open then SD.SetOpen(true) end
        end)
    end
    switchMenu.manage:ClearAllPoints(); switchMenu.manage:SetPoint("TOPLEFT", 6, -(y + 4))
    switchMenu:SetSize(width, y + 4 + 24 + 8)
end
switch:SetScript("OnClick", function()
    if switchMenu:IsShown() then switchMenu:Hide() else SD.PaintSwitch(); switchMenu:Show() end
end)
switch:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Switch gear set", 1, 1, 1); GameTooltip:Show()
end)
switch:HookScript("OnLeave", function() GameTooltip:Hide() end)
-- Race and class as the game names them.
local RACE_NAMES = { NightElf = "Night Elf", Scourge = "Undead" }
local function RaceClass(who)
    local race = who.race and (RACE_NAMES[who.race] or who.race) or ""
    local class = who.class and ((LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[who.class])
        or (who.class:sub(1, 1) .. who.class:sub(2):lower())) or ""
    return (race .. " " .. class):match("^%s*(.-)%s*$")
end
-- The totals, one row per stat: "Agility  187  +51". Enhancement effects join the item stat of the
-- same name (and kind: a percentage stays apart from a flat number); others get rows of their own.
local PERCENT_STATS = { h = true, c = true }
band.ALIAS = { ["critical strike"] = "crit" }
function band.Paint(build, summary)
    local stats, byName = {}, {}
    for _, st in ipairs(Cat.STATS) do
        local s = { label = st[2], value = 0, pct = PERCENT_STATS[st[1]] and "%" or "", bonus = 0 }
        stats[#stats + 1] = s; byName[st[2]:lower() .. s.pct] = s
    end
    for _, slot in ipairs(Cat.SLOT_ORDER) do
        local item = Cat.Get(build.slots[slot])
        if item then for i, st in ipairs(Cat.STATS) do stats[i].value = stats[i].value + Cat.Stat(item, st[1]) end end
    end
    local extra = {}
    for _, spell in pairs(build.enchants or {}) do
        for _, p in ipairs(EN.Effects(Cat.Enchant(spell))) do
            local key = (band.ALIAS[p[3]:lower()] or p[3]:lower()) .. p[2]
            local s = byName[key]
            if not s then
                s = { label = p[3], value = 0, pct = p[2], bonus = 0 }
                byName[key] = s; extra[#extra + 1] = s
            end
            s.bonus = s.bonus + p[1]
        end
    end
    table.sort(extra, function(a, b) return a.label < b.label end)
    for _, s in ipairs(extra) do stats[#stats + 1] = s end
    local n = 0
    for _, s in ipairs(stats) do
        if s.value > 0 or s.bonus > 0 then
            n = n + 1
            local row = band.Row(n)
            row.name:SetText(s.label)
            row.value:SetText(s.value > 0 and (s.value .. s.pct) or "")
            row.bonus:SetText(s.bonus > 0 and ("+" .. s.bonus .. s.pct) or "")
            row.name:Show(); row.value:Show(); row.bonus:Show()
        end
    end
    if n == 0 then
        n = 1
        local row = band.Row(1)
        row.name:SetText("No items added yet."); row.name:SetWidth(band.W - 24)
        row.value:SetText(""); row.bonus:SetText("")
        row.name:Show(); row.value:Show(); row.bonus:Show()
    else
        band.rows[1].name:SetWidth(116)
    end
    for i = n + 1, #band.rows do local row = band.rows[i]; row.name:Hide(); row.value:Hide(); row.bonus:Hide() end
    band.count = n
    band.summary:ClearAllPoints(); band.summary:SetPoint("TOPLEFT", 12, -30 - n * band.ROW - 8)
    band.summary:SetText(summary or ""); band.summary:SetShown((summary or "") ~= "")
    local foot = band.summary:IsShown() and ((band.summary:GetStringHeight() or 12) + 8) or 0
    band.panel:SetHeight(30 + n * band.ROW + foot + 12)
end
-- The tab opens and closes the totals; the caret points the way they will go.
function band.SetOpen(open)
    band.open = open and true or false
    if band.open then FadeIn(band.panel) else band.panel:SetScript("OnUpdate", nil); band.panel:Hide() end
    band.tab.chosen = band.open; PaintButton(band.tab)
    band.tab.caret:SetRotation(band.open and 0 or math.pi) -- the chevron glyph points down
    if band.tab:IsMouseOver() then band.tab:GetScript("OnEnter")(band.tab) end
end
band.tab:SetScript("OnClick", function() band.SetOpen(not band.open) end)
band.tab:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(band.open and "Hide set totals" or "Show set totals", 1, 1, 1)
    GameTooltip:Show()
end)
band.tab:HookScript("OnLeave", function() GameTooltip:Hide() end)
P:HookScript("OnShow", function() band.SetOpen(false) end)
band.SetOpen(false)
-- Bottom right of the stage, against the drawer's edge: show or hide the helm and the cloak, as
-- the game does, and, when the set has both, which weapons the character holds.
band.view = CreateFrame("Frame", nil, band)
band.view:SetSize(1, 26)
-- 16 in from the stage's own edge, like the Set totals tab on the left. While the drawer covers
-- the stage they stay put, under it (Karl, 2026-10-26: following the drawer's edge pushed them
-- over Set totals on a small window); the status line then stops at the drawer instead.
function band.PlaceView()
    band.view:ClearAllPoints()
    band.view:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -16, 15)
    status:SetPoint("RIGHT", SD.covering and SD.clip or band.view, "LEFT", SD.covering and -16 or -10, 0)
end
band.PlaceView()
SD.afterPlace = function() band.FitTitle(); band.PlaceView() end
-- (eye: the helm and cloak buttons show the piece's icon, greyed while hidden; hovering swaps it
-- for an eye that previews the click: slashed to hide, open to show (Karl, 2026-10-24))
function band.ViewButton(slot, tip, eye)
    local b = Button(band.view, "", 26, 26)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(18, 18); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92); b.icon:SetPoint("CENTER")
    b.icon:SetTexture(FGT.GearPlannerSlotTexture(slot))
    if eye then
        b.eye = b:CreateTexture(nil, "ARTWORK")
        b.eye:SetSize(20, 20); b.eye:SetPoint("CENTER")
        b.eye:SetVertexColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3])
        b.eye:Hide()
    end
    b.tip = tip
    b:HookScript("OnEnter", function(self)
        self.over = true; band.PaintEye(self)
        local title, line = self.tip()
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(title, 1, 1, 1)
        if line then GameTooltip:AddLine(line, 0.8, 0.75, 0.65, true) end
        GameTooltip:Show()
    end)
    b:HookScript("OnLeave", function(self) self.over = false; band.PaintEye(self); GameTooltip:Hide() end)
    return b
end
-- at rest the piece's icon (greyed while hidden); under the cursor, the eye for what a click does
function band.PaintEye(b)
    if not b.eye then return end
    b.eye:SetTexture(FGT.Icon(b.hidden and "eye-white" or "eye-off-white"))
    b.eye:SetShown(b.over and true or false); b.icon:SetShown(not b.over)
end
band.helm = band.ViewButton("HeadSlot", function() return Prefs().hideHelm and "Show helm" or "Hide helm" end, true)
band.cloak = band.ViewButton("BackSlot", function() return Prefs().hideCloak and "Show cloak" or "Hide cloak" end, true)
band.weapons = band.ViewButton("MainHandSlot", function()
    if VIEW.Ranged() then return "Show melee weapons", "The character holds the ranged weapon." end
    return "Show ranged weapon", "The character holds the melee weapons."
end)
-- Reset position (Karl, 2026-10-26; renamed from Reset view, no description): after turning, zooming or moving the character, one click
-- glides it back to the resting view, facing front, as choosing another set does.
band.reset = band.ViewButton("HeadSlot", function()
    return "Reset position"
end)
band.reset.icon:SetTexture(FGT.Icon("refresh-white"))
band.reset.icon:SetTexCoord(1, 0, 0, 1) -- mirrored, like the goal page's reset arrow
band.reset.icon:SetSize(15, 15)
band.reset.icon:SetVertexColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3])
band.reset:SetScript("OnClick", function() RestCamera() end)
-- a hidden piece's icon is greyed (the eye comes on hover); the weapons button shows what is held now
function band.PaintView()
    local hasWeapons = selected ~= nil and VIEW.Both()
    band.weapons:SetShown(hasWeapons)
    local x = 0
    -- the reset sits apart, at the left end: it moves the camera, the others change what is worn
    for _, b in ipairs({ band.weapons, band.cloak, band.helm, band.reset }) do
        if b == band.reset then x = x + 8 end
        if b:IsShown() then b:ClearAllPoints(); b:SetPoint("RIGHT", band.view, "RIGHT", -x, 0); x = x + b:GetWidth() + 4 end
    end
    band.view:SetWidth(math.max(1, x - 4))
    local prefs = Prefs()
    for b, hidden in pairs({ [band.helm] = prefs.hideHelm or false, [band.cloak] = prefs.hideCloak or false }) do
        b.icon:SetDesaturated(hidden); b.icon:SetAlpha(hidden and 0.35 or 1)
        b.hidden = hidden; band.PaintEye(b)
    end
    band.weapons.icon:SetTexture(FGT.GearPlannerSlotTexture(VIEW.Ranged() and "RangedSlot" or "MainHandSlot"))
end
local function Toggled(self)
    band.PaintView(); Dress(true)
    if self:IsMouseOver() then self:GetScript("OnEnter")(self) end
end
band.helm:SetScript("OnClick", function(self) Prefs().hideHelm = not Prefs().hideHelm or nil; Toggled(self) end)
band.cloak:SetScript("OnClick", function(self) Prefs().hideCloak = not Prefs().hideCloak or nil; Toggled(self) end)
band.weapons:SetScript("OnClick", function(self)
    local prefs = Prefs()
    prefs.weapons = prefs.weapons or {}
    prefs.weapons[Who().class or ""] = VIEW.Ranged() and "melee" or "ranged"
    Toggled(self)
end)
Refresh = function()
    local store = Store()
    local who = Who()
    local color = who.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[who.class]
    local whoText = (color and color.colorStr and ("|c" .. color.colorStr) or "") .. (who.name or "") .. "|r"
    owner:SetText(whoText)
    ownerBtn:SetWidth(owner:GetStringWidth() + 26)
    -- the set cards
    for _, row in ipairs(rows) do row:Hide() end
    local visible = 0
    for _, build in ipairs(store.builds) do
        if build.name ~= "" then
            visible = visible + 1
            local row = SD.Card(visible)
            if row.build ~= build then row.del.armed = nil end
            row.build = build
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 2, -(visible - 1) * 54)
            row:SetWidth(math.max(120, SD.width - 28))
            row.text:SetText(build.name)
            local filled = Summary(build, true)
            local done, total = GoalProgressText(build)
            row.state:SetText((filled or "Empty") .. (done and (" · In My Goals " .. done .. "/" .. total) or ""))
            row.bar:SetShown(done ~= nil)
            if done then row.bar:SetWidth(math.max(60, SD.width - 48)); row.bar:SetProgress(done, total, "") end
            row.chosen = build == selected
            PaintButton(row)
            row:Show()
        end
    end
    listEmpty:SetShown(visible == 0)
    list.content:SetHeight(math.max(1, visible * 54)); list:Finalize(); list:Update()
    if ES.Paint then ES.Paint() end
    -- the stage: the name (or the box while naming), the switcher and the line under the name
    local editing = selected ~= nil and (editingName or selected.name == "")
    name:SetShown(editing)
    setTitle:SetText(selected and selected.name or "")
    setTitle:SetShown(selected ~= nil and not editing)
    editName:SetShown(selected ~= nil and not editing)
    switch:SetShown(selected ~= nil and not editing and visible > 1)
    if not switch:IsShown() then switchMenu:Hide() end
    subline:SetText(whoText .. "  |cff8a8a8a·|r  " .. RaceClass(who))
    subline:SetShown(selected ~= nil)
    modelArea:Show(); controls:SetShown(selected ~= nil); band:SetShown(selected ~= nil)
    -- In My Goals tops the Equipment panel; the slot list starts under it
    band.goal:SetShown(selected ~= nil)
    slotList.scroll:SetPoint("TOPLEFT", 10, selected and -(42 + band.GOAL_H) or -42)
    local tracked = selected and selected.goalId and ForeverGoalTrackerDB.active[selected.goalId]
    status:SetAlpha(1); status:SetText("")
    if selected then
        local summary = Summary(selected)
        local count = 0
        for _ in pairs(selected.enchants or {}) do count = count + 1 end
        -- (an empty set says so once, in the rows: no summary line under it)
        band.Paint(selected, summary and (summary
            .. (count > 0 and (" · " .. count .. (count == 1 and " enhancement" or " enhancements")) or "")))
        if tracked then
            local done, total = GoalProgressText(selected)
            band.goalText:SetText((done or 0) .. " of " .. (total or 0) .. " collected")
            band.bar:Show(); band.bar:SetProgress(done or 0, total or 0, "")
        else
            band.goalText:SetText(selected.name ~= "" and "Not in My Goals yet" or "Name your set first")
            band.bar:Hide()
        end
    end
    band.PaintView()
    add:SetShown(selected ~= nil and not tracked)
    viewGoal:SetShown(tracked and true or false)
    local canAdd = selected ~= nil and next(selected.slots) ~= nil
    add:SetEnabled(canAdd)
    add.chosen = canAdd
    PaintButton(add)
    add.text:SetAlpha(canAdd and 1 or 0.4)
    options:SetShown(true)
    if LG.PaintHeader then LG.PaintHeader() end
    LV.Show()
    SD.PaintMenu()
    -- the slot rows
    local main = selected and Cat.Get(selected.slots[16])
    local filled, shown = 0, 0
    for slot, button in pairs(slotButtons) do
        local item = selected and Cat.Get(selected.slots[slotIds[slot]])
        button.blocked = (slot == "SecondaryHandSlot" and not item and main and main.twoHand) and true or false
        button.icon:SetTexture(item and item.icon or SlotTexture(slot))
        button.icon:SetAlpha(item and 1 or 0.5)
        if item then
            -- a planned item this set's level can't wear yet: its level in red before the name
            button.itemName:SetText((LG.TooHigh(item) and ("|cffff5a4aLv " .. item.req .. "|r  ") or "") .. item.name)
            local c = QUALITY[item.q] or QUALITY[1]
            button.itemName:SetTextColor(c[1], c[2], c[3])
            button.itemName:Show(); button.slotName:Hide()
        else
            -- an empty slot says which slot it is, in small grey capitals
            button.slotName:SetText(SlotLabel(slot):upper() .. (button.blocked and " · TWO-HAND WEAPON" or ""))
            button.slotName:SetTextColor(button.blocked and 0.42 or colors.SUBTEXT[1], button.blocked and 0.42 or colors.SUBTEXT[2],
                button.blocked and 0.42 or colors.SUBTEXT[3])
            button.itemName:SetText(""); button.itemName:Hide(); button.slotName:Show()
        end
        button.quality = item and item.q or nil
        PaintButton(button)
        button.owned:SetAlpha(item and LG.Has(item.id) and 1 or 0)
        local ench = button.enchant
        local can = item ~= nil and Cat.CanEnchant(item)
        local e = can and selected and selected.enchants and Cat.Enchant(selected.enchants[slotIds[slot]])
        ench.planned = can and true or false
        ench:SetShown(can and not e or false)
        ench.applied:SetShown(e and true or false)
        if e then ench.applied.icon:SetTexture(Cat.EnchantIcon(e)); EN.PaintApplied(ench.applied) end
        PaintButton(ench)
        EN.Anchor(button)
        if button:IsShown() then shown = shown + 1; if item then filled = filled + 1 end end
    end
    left.count:SetText(selected and (filled .. " of " .. shown .. " filled") or "")
    band.FitTitle() -- now that the character's line and the Library link have their text
end

-- The Library set behind the planned pieces (two or more from one set): a gold link under the
-- character's line, opening that set's goal card (Open goal, or + Add to My Goals).
LG.header = CreateFrame("Button", nil, header)
LG.header:SetHeight(18); LG.header:SetPoint("TOP", subline, "BOTTOM", 0, -5)
LG.header.text = U.font(LG.header, 10); LG.header.text:SetPoint("CENTER")
do
    local A = FGT.GOAL_RGB or { 0.95, 0.75, 0.30 }
    LG.header.text:SetTextColor(A[1], A[2], A[3])
end
LG.header:SetScript("OnEnter", function(self) if self.goal then LG.Tooltip(self, self.goal, "set") end end)
LG.header:SetScript("OnLeave", function() GameTooltip:Hide() end)
LG.header:SetScript("OnClick", function(self) LG.Open(self.goal) end)
LG.header:Hide()
band.libraryLink = LG.header
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
    LG.header:SetShown(best ~= nil and subline:IsShown())
    if best then
        LG.header.text:SetText("Library goal: " .. LG.Label(best))
        LG.header:SetWidth((LG.header.text:GetStringWidth() or 120) + 4)
    end
end

-- The level range: typed (Enter or leaving the box keeps it, an empty box is any) or scrolled.
-- Scrolling past the ends reaches any: min below 1, max above 60. The box being changed stops at
-- the other one (Karl: min can never pass max): min 30 with max 10 becomes 10, and the max can't
-- drop below the min. Only the edited box changes, so clicking from one box to the other never
-- leaves a stale number behind.
-- Whose level range the boxes show and change: the open set's, or with no set open (the welcome) a
-- range of its own that a pick there hands to the set it starts (ES.StartFor). It follows the
-- character's level until changed, and is forgotten when the welcome is shown afresh (Karl,
-- 2026-10-27: the boxes would not scroll on the welcome).
function LV.Target()
    if selected then return selected end
    local range = LV.pending or {}
    LV.pending = range
    if not range.changed then range.level = NewSetLevel() end
    return range
end
function LV.Show()
    if not LV.min:HasFocus() then LV.min:SetText(FL.MinLevel() and tostring(FL.MinLevel()) or "") end
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
    local target = LV.Target()
    low, high = Clamp(low), Clamp(high)
    if low and high and low > high then
        if LV.changing == "min" then low = high else high = low end
    end
    local level = high or false
    local changed = target.minLevel ~= low or target.level ~= level
    target.minLevel, target.level = low, level
    if not selected then target.changed = true end
    LV.Show()
    if not changed then return end
    if selected then Save(true); Refresh() end
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
new:SetScript("OnClick", function() actions:Hide(); draft = { name = "", slots = {}, level = NewSetLevel() }; draftOwner = PlanKey(); Choose(draft); editingName = true; Refresh(); name:SetFocus() end)
newSet:SetScript("OnClick", function() new:GetScript("OnClick")() end)
usePreset:SetScript("OnClick", function() actions:Hide(); FGT.CreateHunterPreRaidBuild() end)

-- ------------------------------------------------------------
-- First visit: the welcome card
-- ------------------------------------------------------------
-- With no set open, the planner leads with the character: the same lit, black-and-white scene,
-- wearing what they wear now (the logged-in character; another character shows their race).
-- A card on the left side (free of slots, already on the dark side fade) says what the planner
-- does once, and offers one gold way in, plus importing from Wowhead. Only those two, ever
-- (Karl, 2026-10-27: no preset button here).
ES = ES or {}
ES.card = CreateFrame("Frame", nil, right, "BackdropTemplate")
ES.card:SetFrameLevel(header:GetFrameLevel() + 6); ES.card:EnableMouse(true)
U.etch(ES.card, { top = { 0.10, 0.09, 0.08 }, bottom = { 0.03, 0.03, 0.03 }, edge = { 0.78, 0.61, 0.10, 1 } }, 12)
ES.WIDTH = 300
ES.card:SetWidth(ES.WIDTH)
ES.title = U.title(ES.card, 18); ES.title:SetText("Plan your gear")
ES.title:SetPoint("TOPLEFT", 22, -22)
ES.body = U.font(ES.card, 11)
ES.body:SetText("Pick items for each slot, see them on your character, and track them as a goal.")
ES.body:SetPoint("TOPLEFT", ES.title, "BOTTOMLEFT", 0, -10); ES.body:SetWidth(256)
ES.body:SetJustifyH("LEFT"); ES.body:SetWordWrap(true)
ES.body:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
ES.create = Button(ES.card, "Create a gear set", 256, 32, 12)
ES.create.chosen = true; PaintButton(ES.create) -- the gold border: the one obvious way in
ES.create.text:SetTextColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
-- the second way in: a set from Wowhead (Karl, 2026-10-27; starting from worn gear stays in the "..." menu)
ES.import = Button(ES.card, "Import from Wowhead", 256, 32, 11) -- as tall as Create (Karl, 2026-10-27)
ES.create:SetScript("OnClick", function() new:GetScript("OnClick")() end)
-- a set already filled from what you wear, named so it saves at once (rename it any time)
function ES.StartWorn()
    new:GetScript("OnClick")()
    name:SetText("Current gear"); name:ClearFocus()
    editingName = false
    Save(true)
    fill:GetScript("OnClick")()
end
newWorn:SetScript("OnClick", function() actions:Hide(); ES.StartWorn() end)
-- Picking an item (or a whole item set) in the picker with no set open starts one, so the slots
-- work from the welcome too (Karl, 2026-10-27: the picker opened but nothing in it could be chosen).
-- Named so it saves at once; rename it any time. The slot being chosen carries over.
function ES.StartFor()
    local slot, range = selectedSlot, LV.pending
    new:GetScript("OnClick")()
    if range then selected.level, selected.minLevel = range.level, range.minLevel end
    LV.pending = nil
    name:SetText("New gear set"); name:ClearFocus()
    editingName = false
    Save(true)
    selectedSlot = slot
end

-- Import from Wowhead: paste a Classic Gear Planner link, see what it holds, and make it a new set
-- (never into the open one, so a paste can't overwrite a set in progress). Items and enchants the
-- planner doesn't know are named and left out. Reading the link: Cat.ReadWowheadLink.
WI.frame = CreateFrame("Frame", nil, P, "BackdropTemplate")
WI.frame:SetWidth(420); WI.frame:SetPoint("CENTER", right, "CENTER", 0, 40)
-- the window and the welcome card share one timeline (WI.Go, further down)
WI.FADE, WI.RISE, WI.Y = 0.45, 6, 0 -- dead center of the stage (Karl, 2026-10-28)
WI.CARD_OUT, WI.CARD_LEAD = 0.55, 0.3 -- the card's share of the timeline; where the window starts
WI.frame:SetFrameLevel(header:GetFrameLevel() + 40); WI.frame:EnableMouse(true)
U.etch(WI.frame, styles.panel); WI.frame:Hide()
WI.title = U.title(WI.frame, 16); WI.title:SetText("Import from Wowhead"); WI.title:SetPoint("TOPLEFT", 20, -20)
WI.body = U.font(WI.frame, 11); WI.body:SetWidth(380); WI.body:SetJustifyH("LEFT"); WI.body:SetWordWrap(true)
WI.body:SetText("In Wowhead's Classic Gear Planner, choose Link and copy the Classic Gear Planner address. Paste it here with Ctrl+V.")
WI.body:SetTextColor(colors.INK2[1], colors.INK2[2], colors.INK2[3])
WI.box = CreateFrame("EditBox", nil, WI.frame, "BackdropTemplate")
WI.box:SetSize(380, 26); WI.box:SetAutoFocus(false); WI.box:SetMaxLetters(2000)
U.etch(WI.box, styles.row, 10)
FGT.RegisterFont(WI.box, "body", 11, "")
WI.box:SetTextColor(colors.TEXT[1], colors.TEXT[2], colors.TEXT[3]); WI.box:SetTextInsets(8, 8, 0, 0)
WI.box.hint = U.font(WI.box, 11); WI.box.hint:SetPoint("LEFT", 8, 0); WI.box.hint:SetText("Wowhead link")
WI.box.hint:SetTextColor(colors.SUBTEXT[1], colors.SUBTEXT[2], colors.SUBTEXT[3])
WI.preview = U.font(WI.frame, 11); WI.preview:SetWidth(380); WI.preview:SetJustifyH("LEFT"); WI.preview:SetWordWrap(true)
WI.import = Button(WI.frame, "Import as a new set", 180, 28, 12)
WI.cancel = Button(WI.frame, "Cancel", 100, 28, 12)
function WI.Layout()
    local y = 20 + (WI.title:GetStringHeight() or 18) + 8
    WI.body:ClearAllPoints(); WI.body:SetPoint("TOPLEFT", 20, -y)
    y = y + (WI.body:GetStringHeight() or 28) + 12
    WI.box:ClearAllPoints(); WI.box:SetPoint("TOPLEFT", 20, -y)
    y = y + 26 + 10
    WI.preview:ClearAllPoints(); WI.preview:SetPoint("TOPLEFT", 20, -y)
    local text = WI.preview:GetText() or ""
    y = y + (text ~= "" and (WI.preview:GetStringHeight() or 14) + 14 or 4)
    WI.import:ClearAllPoints(); WI.import:SetPoint("TOPLEFT", 20, -y)
    WI.cancel:ClearAllPoints(); WI.cancel:SetPoint("LEFT", WI.import, "RIGHT", 8, 0)
    WI.frame:SetHeight(y + 28 + 20)
end
local function ClassName(class)
    if not class then return nil end
    local localized = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]
    return type(localized) == "string" and localized or (class:sub(1, 1) .. class:sub(2):lower())
end
-- Reads the box and says what an import would bring; Import works only on a link it can read.
function WI.Read()
    local result, problem = Cat.ReadWowheadLink(WI.box:GetText())
    WI.result = result
    local lines = {}
    if result then
        local items, enchants = 0, 0
        for _ in pairs(result.slots) do items = items + 1 end
        for _ in pairs(result.enchants) do enchants = enchants + 1 end
        local head = {}
        if result.class then head[#head + 1] = ClassName(result.class) end
        if result.level then head[#head + 1] = "Level " .. result.level end
        head[#head + 1] = items .. (items == 1 and " item" or " items")
        if enchants > 0 then head[#head + 1] = enchants .. (enchants == 1 and " enchant" or " enchants") end
        lines[1] = table.concat(head, " · ")
        if #result.missing > 0 then
            local names = {}
            for _, id in ipairs(result.missing) do
                local itemName = FGT.ItemInfo(id)
                names[#names + 1] = type(itemName) == "string" and itemName or ("item " .. id)
            end
            lines[#lines + 1] = "|cffd9b38cNot in the planner's list: " .. table.concat(names, ", ") .. "|r"
        end
        if result.skipped > 0 then
            lines[#lines + 1] = "|cffd9b38c" .. result.skipped .. (result.skipped == 1 and " enchant" or " enchants")
                .. " the planner doesn't know will be left out.|r"
        end
        local who = Who()
        if result.class and who.class and result.class ~= who.class then
            lines[#lines + 1] = "|cffd9b38cThis set is for a " .. ClassName(result.class) .. ". " .. (who.name or "This character")
                .. " is a " .. ClassName(who.class) .. ".|r"
        end
        if items == 0 then WI.result = nil end
    elseif problem then
        lines[1] = "|cffff7a66" .. problem .. "|r"
    end
    WI.preview:SetText(table.concat(lines, "\n"))
    WI.import:SetEnabled(WI.result ~= nil); WI.import:SetAlpha(WI.result and 1 or 0.45)
    WI.Layout()
end
-- Opening and closing are one timeline, WI.p from 0 (closed) to 1 (open) over WI.FADE, run
-- backward to close, so a reversal mid-way just turns around. Over the welcome the card fades out
-- first and the window follows, overlapping a little, so the two never sit on top of each other
-- (Karl's recording, 2026-10-27: the window jumped in on its own curve while the card was still
-- there, and Cancel dropped it in one frame). The window rises WI.RISE into place like the bars'
-- tooltips. WI.hidCard: true while the card is part of it; "keep" when an import opens its set
-- and the card stays away. Instant with animations off.
WI.p, WI.target = 0, 0
WI.driver = CreateFrame("Frame", nil, right)
function WI.Apply()
    local p = WI.p
    local lead = WI.lead or 0 -- the window waits for the card only when there is one
    local w = math.max(0, math.min(1, (p - lead) / (1 - lead)))
    local e = 1 - (1 - w) ^ 3
    WI.frame:ClearAllPoints(); WI.frame:SetPoint("CENTER", right, "CENTER", 0, WI.Y - WI.RISE * (1 - e))
    WI.frame:SetAlpha(e)
    if WI.hidCard == true then
        local c = 1 - Ease(math.min(1, p / WI.CARD_OUT))
        ES.card:SetAlpha(c); ES.card:SetShown(c > 0)
    end
end
function WI.Finish()
    WI.driver:SetScript("OnUpdate", nil)
    WI.p = WI.target; WI.Apply()
    if WI.target == 0 then
        WI.box:ClearFocus(); WI.frame:Hide(); WI.frame:SetAlpha(1)
        if WI.hidCard == true then ES.card:SetAlpha(1); ES.card:SetShown(selected == nil) end
        WI.hidCard = nil
    end
end
function WI.Go(target, instant)
    WI.target = target
    if instant or FGT.Setting("celebrations") == "off" then WI.Finish(); return end
    WI.driver:SetScript("OnUpdate", function(_, dt)
        local step = dt / WI.FADE
        WI.p = WI.target > WI.p and math.min(WI.target, WI.p + step) or math.max(WI.target, WI.p - step)
        if WI.p == WI.target then WI.Finish() else WI.Apply() end
    end)
end
function WI.Open()
    actions:Hide()
    WI.box:SetText(""); WI.Read()
    if selected == nil and (ES.card:IsShown() or WI.hidCard) then WI.hidCard = true end
    WI.lead = WI.hidCard and WI.CARD_LEAD or 0
    WI.Apply(); WI.frame:Show(); WI.box:SetFocus()
    WI.Go(1)
end
-- keepCard: an import is opening its set, so the card stays away; instant: the planner closed
function WI.Close(keepCard, instant)
    WI.box:ClearFocus()
    if keepCard == true and WI.hidCard then WI.hidCard = "keep" end
    if WI.frame:IsShown() then WI.Go(0, instant) end
end
-- The new set takes the link's class in its name ("Wowhead Rogue"), its level, items and enchants.
function WI.Import()
    local result = WI.result
    if not result then return end
    local store = Store()
    local build = { id = store.nextId, name = "Wowhead" .. (result.class and (" " .. ClassName(result.class)) or " set"),
        slots = {}, level = result.level or 60 }
    store.nextId = store.nextId + 1
    for slot, id in pairs(result.slots) do build.slots[slot] = id end
    if next(result.enchants) then
        build.enchants = {}
        for slot, spell in pairs(result.enchants) do build.enchants[slot] = spell end
    end
    store.builds[#store.builds + 1] = build; store.selected = build.id
    WI.Close(true); Choose(build)
    return build
end
WI.menu:SetScript("OnClick", WI.Open)
ES.import:SetScript("OnClick", WI.Open)
WI.import:SetScript("OnClick", WI.Import)
WI.cancel:SetScript("OnClick", function() WI.Close() end)
WI.box:SetScript("OnTextChanged", function(self)
    self.hint:SetShown((self:GetText() or "") == ""); WI.Read()
end)
WI.box:SetScript("OnEnterPressed", WI.Import)
WI.box:SetScript("OnEscapePressed", function() WI.Close() end)
WI.box:SetScript("OnEditFocusGained", function(self)
    self:SetBackdropBorderColor(colors.GOLD2[1], colors.GOLD2[2], colors.GOLD2[3], 1)
end)
WI.box:SetScript("OnEditFocusLost", function(self)
    self:SetBackdropBorderColor(styles.row.edge[1], styles.row.edge[2], styles.row.edge[3], 1)
end)
WI.import.chosen = true; PaintButton(WI.import)
WI.import.text:SetTextColor(colors.TITLE[1], colors.TITLE[2], colors.TITLE[3])
P:HookScript("OnHide", function() WI.Close(false, true) end)
-- (the buttons say what they do; Karl, 2026-10-24: no tooltip)
ES.card:Hide()
-- With no set open, the item picker opens over the card: the card fades away while it is open and
-- back when it closes (Karl's recording, 2026-10-27: closing the picker dropped it back in one frame).
-- The import window runs its own timeline (WI.hidCard), which takes over.
ES.hold = CreateFrame("Frame", nil, right)
function ES.Away(away)
    away = away and true or false
    if WI.hidCard then ES.away = nil; return end
    if selected ~= nil then return end -- a set is opening: ES.FadeIn sees ES.away and keeps the card away
    if (ES.away or false) == away then return end
    ES.away = away or nil
    local card = ES.card
    local from, to = card:IsShown() and card:GetAlpha() or 0, away and 0 or 1
    ES.hold:SetScript("OnUpdate", nil)
    -- (switching slots hides and shows the picker in one go: the card never got going)
    if FGT.Setting("celebrations") == "off" or (away and from <= 0) then card:SetAlpha(1); card:SetShown(not away); return end
    card:SetAlpha(from); card:Show()
    local elapsed, DURATION = 0, away and 0.2 or 0.3
    ES.hold:SetScript("OnUpdate", function(self, dt)
        if WI.hidCard or selected ~= nil then self:SetScript("OnUpdate", nil); return end
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / DURATION)
        card:SetAlpha(from + (to - from) * Ease(t))
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            if away then card:Hide(); card:SetAlpha(1) end
        end
    end)
end
picker:HookScript("OnShow", function() ES.Away(true) end)
picker:HookScript("OnHide", function() ES.Away(false) end)
-- Lay out the two ways in: create and import.
function ES.Layout()
    ES.import:Show() -- any character: a Wowhead set needs nothing worn
    local y = 22 + (ES.title:GetStringHeight() or 20) + 10 + (ES.body:GetStringHeight() or 30) + 18
    for _, b in ipairs({ ES.create, ES.import }) do
        if b:IsShown() then
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", 22, -y)
            y = y + b:GetHeight() + 8
        end
    end
    ES.card:SetHeight(y + 14)
    -- pinned to the stage's bottom-left corner, the same gap from both edges (Karl, 2026-10-28)
    ES.card:ClearAllPoints(); ES.card:SetPoint("BOTTOMLEFT", right, "BOTTOMLEFT", 36, 36)
end
-- The scene for the welcome: the character in their own gear, once per visit to the empty state.
function ES.Scene()
    local who = Who()
    LV.pending = nil -- a fresh welcome starts again at the character's level
    modelOwner = nil -- the next set dresses the model as its own character
    model:SetUnit("player")
    if not who.me then
        if model.SetCustomRace and RACE_IDS[who.race or ""] then
            pcall(model.SetCustomRace, model, RACE_IDS[who.race], who.sex == 3 and 1 or 0)
        end
        model:Undress() -- another character's gear is not known to the model
    end
    background:SetRace(who.race)
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
    local cardGone = WI.hidCard or ES.away -- the import window or the picker already faded it out: it stays away
    WI.hidCard, ES.away = nil, nil; ES.hold:SetScript("OnUpdate", nil)
    if FGT.Setting("celebrations") == "off" then
        Set(1); ES.card:Hide(); ES.card:SetAlpha(1)
        return
    end
    Set(0)
    if cardGone then ES.card:Hide() else ES.card:Show(); ES.card:SetAlpha(1) end
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
        if not WI.hidCard and not ES.away then ES.card:SetAlpha(1); ES.card:Show() end
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
SD.Rename = RenameSet
rename:SetScript("OnClick", RenameSet)
editName:SetScript("OnClick", RenameSet)
clear:SetScript("OnClick", function()
    if not selected then return end
    actions:Hide()
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
-- Start from what the character is wearing now: only items the database knows. The rest (grey
-- starting gear, mostly) is left out quietly: the line naming it ran long and was cut off (Karl,
-- 2026-10-24), and the filled rows already show what came across.
fill:SetScript("OnClick", function()
    if not selected then return end
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
            selected.slots[slot] = id
            -- the worn enchant comes from the item link (item:id:enchant:...)
            local link = slot ~= 20 and GetInventoryItemLink and GetInventoryItemLink("player", slot)
            local e = link and Cat.EnchantByEffect(tonumber(link:match("item:%-?%d+:(%d+)")), item)
            selected.enchants = selected.enchants or {}
            selected.enchants[slot] = e and e.spell or nil
        end
    end
    actions:Hide(); Deselect(); Dress(true); Save(true); Refresh()
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
-- Deleting a set takes its goal and progress with it; the next set opens (or the welcome).
local function DropBuild(build)
    local store, DB = Store(), ForeverGoalTrackerDB
    if build.goalId then
        DB.active[build.goalId] = nil; DB.progress[build.goalId] = nil
        local goal = FGT.GoalById(build.goalId)
        if goal then goal.steps = {} end
    end
    for i, b in ipairs(store.builds) do if b == build then table.remove(store.builds, i); break end end
    if clearedBuild == build then cleared, clearedBuild, clearedItems, clearedProgress = nil, nil, nil, nil end
end
function SD.Delete(build)
    if not (build and build.id) then return end
    DropBuild(build)
    local store = Store()
    actions:Hide(); FGT.RefreshPlannerGoals()
    if build == selected then
        store.selected = store.builds[1] and store.builds[1].id or nil
        Choose(store.builds[1])
    else
        Refresh()
    end
end
delete:SetScript("OnClick", function()
    if not (selected and selected.id) then return end
    if not deleteArmed then deleteArmed = true; Refresh(); return end
    deleteArmed = nil
    SD.Delete(selected)
end)
-- Every set for this character: two clicks, like a single delete.
deleteAll:SetScript("OnClick", function()
    if not deleteAllArmed then deleteAllArmed = true; SD.PaintMenu(); return end
    deleteAllArmed = nil
    local store = Store()
    for i = #store.builds, 1, -1 do DropBuild(store.builds[i]) end
    store.selected = nil; draft = nil
    actions:Hide(); FGT.RefreshPlannerGoals()
    Choose(nil)
end)
-- Takes every set off My Goals; the sets and their credit stay, so Add to My Goals restores them.
removeAll:SetScript("OnClick", function()
    for _, build in ipairs(Store().builds) do
        if build.goalId then ForeverGoalTrackerDB.active[build.goalId] = nil end
    end
    actions:Hide(); FGT.RefreshPlannerGoals(); Refresh()
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
        if not row then row = Button(charMenu, "", SD.width - 40, 24, 11); charRows[i] = row
            row.text:ClearAllPoints(); row.text:SetPoint("LEFT", 8, 0)
        end
        local c, color = entry.c, RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.c.class]
        row.text:SetText((color and color.colorStr and ("|c" .. color.colorStr) or "") .. (c.name or entry.key) .. "|r"
            .. (c.level and ("  |cff9a8f78· Level " .. c.level .. "|r") or ""))
        row.chosen = entry.key == PlanKey(); PaintButton(row)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 8, -y); row:Show(); y = y + 28
        row:SetScript("OnClick", function() charMenu:Hide(); PlanFor(entry.key) end)
    end
    charMenu:SetSize(SD.width - 24, y + 6); charMenu:Show()
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
-- The gallery's Gear Planner shot (demo scene 13, see Core.lua): a pretend roster character with a
-- ready-made set open, on the stage. Nothing of it is kept: the character and the set are removed
-- when the demo ends or another scene begins, so the player's own sets and roster are never touched.
--   spec = { key, name, class, race, faction, level, sex, preset (a Cat.PRESETS id), totals }
function FGT.GearPlannerDemo(spec)
    local db = ForeverGoalTrackerDB
    local preset = db and Cat.PRESETS[spec.preset]
    if not preset then return false end
    FGT.GearPlannerDemoOff()
    db.characters = db.characters or {}
    db.characters[spec.key] = { name = spec.name, class = spec.class, race = spec.race, faction = spec.faction,
        level = spec.level, sex = spec.sex, lastSeen = time() }
    FGT.demoPlannerKey = spec.key
    FGT.demoOwnLook = spec.ownLook or nil
    if spec.ownLook then
        -- the same race as the player: take their sex too, so the model matches the label
        local _, race = UnitRace("player")
        if race == spec.race and UnitSex then db.characters[spec.key].sex = UnitSex("player") end
    end
    PlanFor(spec.key)
    local store = Store()
    local build = { id = 1, name = preset.name, slots = {}, preset = spec.preset, level = spec.level or 60 }
    for slot, id in pairs(preset.slots) do build.slots[slot] = id end
    store.builds, store.nextId, store.selected = { build }, 2, 1
    FGT.ShowTab("gear")
    if P:IsShown() then Choose(build) end
    band.SetOpen(spec.totals and true or false)
    return true
end
-- Puts the player's own planner back and removes the pretend character and its set.
function FGT.GearPlannerDemoOff()
    local key = FGT.demoPlannerKey
    if not key then return end
    FGT.demoPlannerKey, FGT.demoOwnLook = nil, nil
    PlanFor(nil)
    local db = ForeverGoalTrackerDB
    if db.characters then db.characters[key] = nil end
    local root = db.gearPlanner
    if root and root.characters then root.characters[key] = nil end
    band.SetOpen(false)
end
-- Expose only prototype operations needed by regression checks.
FGT.GearPlannerTest = { store = Store, new = function() new:GetScript("OnClick")() end,
    name = name, setTitle = setTitle, editName = editName, add = add, viewGoal = viewGoal, options = options, actions = actions,
    clear = clear, remove = remove, rename = rename, fill = fill, duplicate = duplicate, delete = delete,
    camera = camera, turn = turn, appearance = appearance, menu = menu, replace = replace, rows = rows, head = head,
    picker = picker, results = resultRows, unequip = unequip, search = search, filters = { stat = FL.stat,
        kind = FL.kind, quality = FL.quality, revealed = FL.revealed, showAll = FL.showAll, popup = FL.popup, rows = FL.rows },
    list = pickerList, found = function() return found, foundCount end,
    modelArea = modelArea, background = background, model = model, sheathButton = sheathButton, bindSheath = BindSheath, clickAway = clickAway, slots = slotButtons, status = status, level = LV.box, minLevel = LV.min,
    goalMenu = LG.menuBtn, libraryHeader = LG.header, welcome = ES,
    drawer = SD, charMenu = charMenu, ownerButton = ownerBtn, slotList = slotList, switch = switch, switchMenu = switchMenu, subline = subline, band = band,
    newSet = newSet, newWorn = newWorn, usePreset = usePreset, removeAll = removeAll, deleteAll = deleteAll,
    enhancement = EN, wowhead = WI }
