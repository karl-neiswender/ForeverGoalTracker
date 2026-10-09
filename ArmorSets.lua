local ADDON, FGT = ...

-- Library collections retain their familiar class picker. The selected
-- appearances are independent goals everywhere else, with stable class IDs.
FGT.armorCollections = {}
do
    local children = {}
    for _, parent in ipairs(FGT.goals) do
        if parent.group and parent.sections and
            (parent.category == "Item Set" or parent.id:match("^pvp_set_")) then
            parent.libraryOnly = true
            parent.armorChildren = {}
            FGT.armorCollections[parent.id] = parent
            for si, section in ipairs(parent.sections) do
                local class, name = section.name:match("^(.-) %- (.+)$")
                assert(class and name, "Armor set needs a class and set name: " .. parent.id)
                local goal = {}
                for k, v in pairs(parent) do goal[k] = v end
                goal.id = parent.id .. "_" .. class:lower()
                goal.name = name .. " (" .. class .. ")"
                goal.short = nil
                goal.icon = section.pieces[1] and section.pieces[1].icon or section.icon
                goal.group, goal.libraryOnly, goal.armorChildren = nil, nil, nil
                goal.armorParent, goal.armorSection, goal.armorClass = parent.id, si, class
                goal.libraryChild = true
                goal.sections = { section }
                goal.forever = section.forever or parent.forever
                goal.note = parent.note:gsub("Pick the classes you want in the Library, then click", "Click")
                    :gsub("Pick the classes you want in the Library[;,] ?", "")
                    :gsub("Pick the sets you want in the Library[;,] ?", "")
                parent.armorChildren[si] = goal
                children[#children + 1] = goal
            end
        end
    end
    for _, goal in ipairs(children) do FGT.goals[#FGT.goals + 1] = goal end
end

function FGT.SetArmorPartActive(parent, key, on)
    local child = parent.armorChildren and parent.armorChildren[key]
    if not child then return end
    ForeverGoalTrackerDB.active[child.id] = on and true or nil
    return child
end

-- Run after older positional migrations. Keep old progress as a backup,
-- but never merge it again after a reset or removal of an individual set.
function FGT.MigrateArmorSets(DB)
    if DB.armorSetsSplit1 then return end
    -- An old demo save can contain the player's real grouped selections.
    if DB.demoBackup then
        for id in pairs(FGT.armorCollections) do
            if (DB.demoBackup.active and DB.demoBackup.active[id]) or
                next((DB.demoBackup.activeParts and DB.demoBackup.activeParts[id]) or {}) then
                FGT.MigrateArmorSets(DB.demoBackup)
                break
            end
        end
    end
    DB.armorSetsBackup1 = { active = {}, activeParts = {}, progress = {}, selected = DB.selected }
    for id, parent in pairs(FGT.armorCollections) do
        local selections = DB.activeParts[id] or {}
        local old = DB.progress[id] or {}
        DB.armorSetsBackup1.active[id] = DB.active[id]
        DB.armorSetsBackup1.activeParts[id] = selections
        DB.armorSetsBackup1.progress[id] = old
        local first
        for si, child in ipairs(parent.armorChildren) do
            if selections[si] then
                DB.active[child.id] = true
                first = first or child.id
            end
            local progress = DB.progress[child.id] or {}
            DB.progress[child.id] = progress
            for key, value in pairs(old) do
                local index, rest = tostring(key):match("^(%d+)(_.*)$")
                if tonumber(index) == si and progress["1" .. rest] == nil then
                    progress["1" .. rest] = value
                    if DB.autoLog and DB.autoLog[id .. ":" .. key] then
                        DB.autoLog[child.id .. ":1" .. rest] = DB.autoLog[id .. ":" .. key]
                    end
                end
            end
            for _, field in ipairs({"favorites", "notes"}) do
                if DB[field] and DB[field][id] ~= nil and DB[field][child.id] == nil then
                    DB[field][child.id] = DB[field][id]
                end
            end
            -- Already finished parts must not celebrate again on migration.
            local complete = #child.sections[1].pieces > 0
            for pi, piece in ipairs(child.sections[1].pieces) do
                if #piece.materials == 0 then
                    if not progress["1_" .. pi .. "_piece"] then complete = false end
                else
                    for mi in ipairs(piece.materials) do
                        if not progress["1_" .. pi .. "_m" .. mi] then complete = false end
                    end
                end
            end
            if complete then
                DB.goalsDone = DB.goalsDone or {}
                DB.goalsDone[child.id] = true
                if DB.goalDates and DB.goalDates[id] then DB.goalDates[child.id] = DB.goalDates[id] end
            end
        end
        DB.active[id], DB.activeParts[id] = nil, {}
        if DB.selected == id then DB.selected = first end
    end
    DB.armorSetsSplit1 = true
end

function FGT.CatalogGoalCount()
    local count = 0
    for _, goal in ipairs(FGT.goals) do
        if not goal.libraryOnly then count = count + 1 end
    end
    return count
end
