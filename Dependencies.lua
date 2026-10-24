local ADDON, FGT = ...

-- First-pass Classic gates, reviewed against the prerequisite audit.
-- Forever remains ungated until its changed quest rules are verified.
-- /goals testlocks enables the audited Classic gates for one Forever
-- session's review. It does not assert that those quest rules are confirmed.
-- Only actual prerequisites belong here, never recommended raid order.
FGT.DEPENDENCIES = {
    classicOnly = true,
    benediction = { [2] = { all = {1} }, [3] = { all = {2} }, [5] = { all = {1,3,4} } },
    lokdelar = { [2] = { all = {1} }, [3] = { all = {2} }, [4] = { all = {2} },
        [5] = { all = {2} }, [6] = { all = {2} }, [7] = { all = {3,4,5,6} } },
    -- Other Thunderfury edges await the guide/evidence corrections in the audit.
    thunderfury = { [4] = { any = {2,3} } },
    att_mc = { [3] = { all = {1,2} } }, -- fragment pre-looting remains available
    att_bwl = { [3] = { all = {1} } }, -- a personal Drakkisath kill is not required in a cleared instance
    att_naxx = { [2] = { all = {1} }, [3] = { all = {1,2} } },
    key_brd = { [2] = { all = {1} } },
    key_ubrs = { [2] = { all = {1} } },
    att_ony_ally = {},
    att_ony_horde = { [9] = { all = {8} }, [10] = { all = {8} }, [11] = { all = {8} },
        [12] = { all = {9,10,11} }, [13] = { all = {12} }, [14] = { all = {13} } },
}
for i = 2, 11 do FGT.DEPENDENCIES.att_ony_ally[i] = { all = {i-1} } end
for i = 2, 8 do FGT.DEPENDENCIES.att_ony_horde[i] = { all = {i-1} } end

-- These guides now begin with an explicit level requirement. Keep the
-- established item/quest edges aligned; gathering remains parallel.
for _, id in ipairs({"benediction", "lokdelar", "att_mc", "att_bwl"}) do
    local moved = {}
    local dependencies = FGT.DEPENDENCIES[id]
    assert(type(dependencies) == "table", "Missing guide dependencies: " .. id)
    for key, rule in pairs(dependencies) do
        local shifted = {}
        for kind, keys in pairs(rule) do
            shifted[kind] = {}
            for i, prior in ipairs(keys) do shifted[kind][i] = prior+1 end
        end
        moved[key+1] = shifted
    end
    FGT.DEPENDENCIES[id] = moved
end

-- Add only individually verified Forever edges here. Keep this separate
-- from the Classic baseline so one reviewed chain never enables the rest.
-- Native UI/API tests alone do not establish quest prerequisite rules.
FGT.FOREVER_DEPENDENCIES = {}

function FGT.DependencyEntry(goal, key)
    if not goal then return end
    if type(key) == "number" then return goal.steps and goal.steps[key] end
    local si, pi, mi = tostring(key):match("^(%d+)_(%d+)_m(%d+)$")
    if not si then si, pi = tostring(key):match("^(%d+)_(%d+)_piece$") end
    local sec = si and goal.sections and goal.sections[tonumber(si)]
    local piece = sec and sec.pieces[tonumber(pi)]
    if mi then return piece and piece.materials and piece.materials[tonumber(mi)] end
    return piece
end

function FGT.DependencyMet(goal, key)
    local DB = ForeverGoalTrackerDB
    if DB and DB.progress and DB.progress[goal.id] and DB.progress[goal.id][key] then return true end
    local entry = FGT.DependencyEntry(goal, key)
    if type(entry) == "table" and FGT.PieceSkipped and FGT.PieceSkipped(entry) then return true end
    return type(entry) == "table" and entry.auto and FGT.StepRuleMet and FGT.StepRuleMet(entry.auto) or false
end

function FGT.StepPrerequisites(goal, key)
    local entry = FGT.DependencyEntry(goal, key)
    if type(entry) == "table" and entry.requires then return entry.requires end
    local dependencies = FGT.DEPENDENCIES
    if dependencies.classicOnly and FGT.isForever and not FGT.testDependencies then
        dependencies = FGT.FOREVER_DEPENDENCIES
    end
    local rules = goal and dependencies[goal.id]
    return rules and rules[key]
end

-- Requirement locks (Karl, 2026-10-24): a step the addon can always verify, and the character does not
-- meet, cannot be ticked by hand. Only rules the game itself can answer at any moment count: level,
-- reputation standing, skill rank and a quest flagged complete. Rules that depend on the addon having
-- watched it happen (boss kills, counters, statistics) are not locked, because a kill made before the
-- addon was installed cannot be seen. A rule with any other key is never locked. Like the order locks,
-- these apply on Classic Era only until Forever's rules are verified.
local LOCKABLE = { level = true, rep = true, skill = true, quest = true }
local RULE_SCOPE = { forFaction = true, forClass = true, forRace = true } -- who the step is for, not a requirement
local STANDINGS = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }

-- The unlocks Karl's players make with Shift-click last for the game session: they survive /reload and
-- are cleared at the next login (see the event at the end of this file).
FGT.lockTried = {} -- steps whose lock was clicked once this session: their tooltip then shows the hint
function FGT.StepUnlocked(goal, key)
    local DB = ForeverGoalTrackerDB
    local per = DB and DB.unlocked and goal and DB.unlocked[goal.id]
    return per and per[key] == true or false
end
function FGT.UnlockStep(goal, key)
    local DB = ForeverGoalTrackerDB
    if not (DB and goal) then return end
    DB.unlocked = DB.unlocked or {}
    DB.unlocked[goal.id] = DB.unlocked[goal.id] or {}
    DB.unlocked[goal.id][key] = true
end

local function FactionName(id)
    local ok, name = pcall(GetFactionInfoByID, id)
    return ok and name or "that faction"
end

-- One short line for what the step needs, point blank.
function FGT.RequirementText(rule)
    if rule.level then return "Requires level " .. rule.level .. "." end
    if rule.rep then
        local faction = type(rule.rep.faction) == "table" and rule.rep.faction[1] or rule.rep.faction
        local standing = STANDINGS[rule.rep.standing or 0] or "a higher standing"
        local value = (rule.rep.value or 0) > 0 and (" " .. rule.rep.value) or ""
        return "Requires " .. standing .. value .. " with " .. FactionName(faction) .. "."
    end
    if rule.skill then return "Requires " .. tostring(rule.skill.name) .. " " .. tostring(rule.skill.rank) .. "." end
    if rule.quest then return "Quest not completed." end
end

-- The text above when this step is requirement-locked (verifiable, unmet, not unlocked), else nil.
function FGT.StepRequirement(goal, key)
    if FGT.noRequirementLocks then return nil end -- (a switch for tests that tick steps by clicking and are not about locks)
    if FGT.isForever and not FGT.testDependencies then return nil end
    local entry = FGT.DependencyEntry(goal, key)
    local rule = type(entry) == "table" and entry.auto
    if type(rule) ~= "table" then return nil end
    local lockable = false
    for k in pairs(rule) do
        if LOCKABLE[k] then lockable = true elseif not RULE_SCOPE[k] then return nil end
    end
    if not lockable or (FGT.StepRuleMet and FGT.StepRuleMet(rule)) then return nil end
    return FGT.RequirementText(rule)
end

function FGT.StepLocked(goal, key)
    local missing = { all = {}, any = {} }
    if not goal or FGT.DependencyMet(goal, key) or FGT.StepUnlocked(goal, key) then return false, missing end
    local rule = FGT.StepPrerequisites(goal, key)
    if rule then
        for _, prior in ipairs(rule.all or {}) do
            if not FGT.DependencyMet(goal, prior) then missing.all[#missing.all+1] = prior end
        end
        local anyMet = false
        for _, prior in ipairs(rule.any or {}) do
            if FGT.DependencyMet(goal, prior) then anyMet = true; break end
        end
        if not anyMet then for _, prior in ipairs(rule.any or {}) do missing.any[#missing.any+1] = prior end end
    end
    if #missing.all > 0 or #missing.any > 0 then return true, missing end
    missing.requirement = FGT.StepRequirement(goal, key)
    return missing.requirement ~= nil, missing
end

function FGT.ShowStepLockTip(row)
    if FGT.overLink then return end
    local _, missing = FGT.StepLocked(row.depGoal, row.depKey)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if missing.requirement then
        GameTooltip:AddLine(missing.requirement, 1, 0.84, 0.4, true)
    else
        GameTooltip:AddLine("Locked", 1, 0.84, 0.4)
    end
    local function lines(keys, heading)
        if #keys == 0 then return end
        GameTooltip:AddLine(heading, 0.9, 0.48, 0.43, true)
        for _, key in ipairs(keys) do
            local entry = FGT.DependencyEntry(row.depGoal, key)
            local text = type(entry) == "table" and (entry.text or entry.name) or entry
            GameTooltip:AddLine("• " .. FGT.StepText(text or tostring(key)), 0.88, 0.66, 0.61, true)
        end
    end
    lines(missing.all, "Complete first:")
    lines(missing.any, "Complete one:")
    -- after the first blocked click on this step, a small hint at the bottom (not advertised before that)
    if FGT.lockTried[tostring(row.depGoal and row.depGoal.id) .. "|" .. tostring(row.depKey)] then
        GameTooltip:AddLine("Shift-click to unlock", 0.6, 0.6, 0.6)
        local n = GameTooltip:NumLines()
        local line = n and _G and _G["GameTooltipTextLeft" .. n]
        if line and line.SetFontObject and GameFontNormalSmall then line:SetFontObject(GameFontNormalSmall) end
    end
    GameTooltip:Show()
end

function FGT.EndLockMotion(row)
    if not row.lockLayer then return end
    local L = row.lockLayer
    L:SetScript("OnUpdate", nil)
    L.motion, L.elapsed = nil, nil
    L.icon:ClearAllPoints(); L.icon:SetPoint("CENTER")
    L.icon:SetRotation(0); L.icon:SetAlpha(0.82)
    L.left:Hide(); L.right:Hide()
    L.icon:SetShown(row.depLocked and true or false)
    row.box:SetAlpha(1)
    L:SetShown(row.depLocked and true or false)
end

function FGT.CreateStepLock(row)
    if row.lockLayer then return end
    local L = CreateFrame("Frame", nil, row)
    L:SetSize(20, 20)
    L:SetPoint("CENTER", row.box, "CENTER")
    L:SetFrameLevel(row:GetFrameLevel() + 4)
    L:EnableMouse(false)
    L.icon = L:CreateTexture(nil, "OVERLAY")
    L.icon:SetTexture(FGT.Icon("lock-white")); L.icon:SetSize(18,18); L.icon:SetPoint("CENTER")
    for _, name in ipairs({"left", "right"}) do
        local t = L:CreateTexture(nil, "OVERLAY")
        t:SetTexture(FGT.Icon("lock-white")); t:SetSize(9,18)
        t:SetTexCoord(name == "left" and 0 or 0.5, name == "left" and 0.5 or 1, 0, 1)
        t:Hide(); L[name] = t
    end
    L:Hide(); row.lockLayer = L
    row:HookScript("OnHide", function(self) FGT.EndLockMotion(self) end)
end

function FGT.PlayLockMotion(row, kind)
    FGT.CreateStepLock(row)
    FGT.EndLockMotion(row)
    local mode = FGT.Setting("celebrations")
    if mode == "off" then return end
    local L = row.lockLayer
    L.motion, L.elapsed = kind, 0
    L:Show()
    if kind == "unlock" and mode ~= "subtle" then
        L.icon:Hide(); L.left:Show(); L.right:Show()
    else L.icon:Show() end
    if kind == "unlock" then row.box:SetAlpha(0) end
    L:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local duration = kind == "unlock" and 0.42 or 0.34
        local t = math.min(1, self.elapsed / duration)
        if kind == "jiggle" then
            if mode == "subtle" then self.icon:SetAlpha(0.82 - 0.3 * math.sin(t * math.pi))
            else
                local wave = math.sin(t * math.pi * 6) * (1-t)
                self.icon:ClearAllPoints(); self.icon:SetPoint("CENTER", wave * 2.5, 0)
                self.icon:SetRotation(wave * 0.14)
            end
        else
            row.box:SetAlpha(math.min(1, t * 2))
            if mode == "subtle" then self.icon:SetAlpha(0.82 * (1-t))
            else
                local spread = (1 - (1-t)^3) * 10
                self.left:ClearAllPoints(); self.left:SetPoint("CENTER", -4.5-spread, -t*4)
                self.right:ClearAllPoints(); self.right:SetPoint("CENTER", 4.5+spread, -t*4)
                self.left:SetRotation(t*0.3); self.right:SetRotation(-t*0.3)
                self.left:SetAlpha(0.82*(1-t)); self.right:SetAlpha(0.82*(1-t))
            end
        end
        if t == 1 then FGT.EndLockMotion(row) end
    end)
end

function FGT.StyleStepLock(row, goal, key)
    local identity = goal.id .. "|" .. tostring(key)
    local same = row.depIdentity == identity
    local wasLocked = same and row.depLocked
    local locked = FGT.StepLocked(goal, key)
    if same and locked ~= row.depLocked and GameTooltip:IsOwned(row) then GameTooltip:Hide() end
    if not same or locked ~= row.depLocked then FGT.EndLockMotion(row) end
    row.depIdentity, row.depGoal, row.depKey, row.depLocked = identity, goal, key, locked
    if locked then
        FGT.CreateStepLock(row)
        row.box:Hide(); row.lockLayer:Show(); row.lockLayer.icon:Show()
    else
        if row.lockLayer and not row.lockLayer.motion then FGT.EndLockMotion(row) end
        if wasLocked then FGT.PlayLockMotion(row, "unlock") end
    end
end

function FGT.ClearStepLock(row)
    row.depIdentity, row.depGoal, row.depKey, row.depLocked = nil, nil, nil, nil
    FGT.EndLockMotion(row)
end

-- The session ends at the next login, not at a reload: PLAYER_ENTERING_WORLD says which (isInitialLogin is
-- true for a login, character switch or new game start, isReloadingUi for /reload).
local session = CreateFrame("Frame")
session:RegisterEvent("PLAYER_ENTERING_WORLD")
session:SetScript("OnEvent", function(_, _, isInitialLogin)
    if isInitialLogin and ForeverGoalTrackerDB then ForeverGoalTrackerDB.unlocked = nil end
end)
FGT.unlockSession = session
