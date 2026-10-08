local ADDON, FGT = ...

-- First-pass Classic gates, reviewed against the prerequisite audit.
-- Forever remains ungated until its changed quest rules are verified.
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
    att_naxx = { [2] = { all = {1} } },
    key_brd = { [2] = { all = {1} } },
    key_ubrs = { [2] = { all = {1} } },
    att_ony_ally = {},
    att_ony_horde = { [9] = { all = {8} }, [10] = { all = {8} }, [11] = { all = {8} },
        [12] = { all = {9,10,11} }, [13] = { all = {12} }, [14] = { all = {13} } },
}
for i = 2, 11 do FGT.DEPENDENCIES.att_ony_ally[i] = { all = {i-1} } end
for i = 2, 8 do FGT.DEPENDENCIES.att_ony_horde[i] = { all = {i-1} } end

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
    if FGT.DEPENDENCIES.classicOnly and FGT.isForever then return end
    local rules = goal and FGT.DEPENDENCIES[goal.id]
    return rules and rules[key]
end

function FGT.StepLocked(goal, key)
    local missing = { all = {}, any = {} }
    if not goal or FGT.DependencyMet(goal, key) then return false, missing end
    local rule = FGT.StepPrerequisites(goal, key)
    if not rule then return false, missing end
    for _, prior in ipairs(rule.all or {}) do
        if not FGT.DependencyMet(goal, prior) then missing.all[#missing.all+1] = prior end
    end
    local anyMet = false
    for _, prior in ipairs(rule.any or {}) do
        if FGT.DependencyMet(goal, prior) then anyMet = true; break end
    end
    if not anyMet then for _, prior in ipairs(rule.any or {}) do missing.any[#missing.any+1] = prior end end
    return #missing.all > 0 or #missing.any > 0, missing
end

function FGT.ShowStepLockTip(row)
    if FGT.overLink then return end
    local _, missing = FGT.StepLocked(row.depGoal, row.depKey)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Step locked", 1, 0.84, 0.4)
    local function lines(keys, heading)
        if #keys == 0 then return end
        GameTooltip:AddLine(heading, 0.9, 0.48, 0.43, true)
        for _, key in ipairs(keys) do
            local entry = FGT.DependencyEntry(row.depGoal, key)
            local text = type(entry) == "table" and (entry.text or entry.name) or entry
            GameTooltip:AddLine("• " .. FGT.StepText(text or tostring(key)), 0.88, 0.66, 0.61, true)
        end
    end
    lines(missing.all, "Complete these prerequisites first:")
    lines(missing.any, "Complete either prerequisite:")
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
    L.icon:SetTexture(FGT.Icon("lock")); L.icon:SetSize(18,18); L.icon:SetPoint("CENTER")
    for _, name in ipairs({"left", "right"}) do
        local t = L:CreateTexture(nil, "OVERLAY")
        t:SetTexture(FGT.Icon("lock")); t:SetSize(9,18)
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
