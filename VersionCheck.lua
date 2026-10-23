local ADDON, FGT = ...

-- ============================================================
-- Out-of-date reminder
-- ============================================================
-- An addon cannot look anything up online, so it learns about a newer version from other players
-- who run it (the way BigWigs and Deadly Boss Mods do): it shares its version number with your
-- guild and group over the game's hidden addon-message channel, and when it hears a higher number
-- than its own it says so once in chat. Nothing shows in chat for the sharing, and the only data
-- sent is the version string, to your own guild or group. Settings > Chat and alerts > Version
-- reminders turns it off (it then neither shares nor listens).
local V = {}
FGT.VersionCheck = V

V.PREFIX = "FGTVER" -- addon-message prefix (16 characters at most)
V.THROTTLE = 60     -- seconds before the same channel is told again

local function Meta()
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or rawget(_G, "GetAddOnMetadata")
    return getMeta and getMeta(ADDON, "Version") or nil
end

-- "2.16.0" -> a comparable number, or nil for anything that is not exactly three numbers.
function V.Number(text)
    local a, b, c = tostring(text or ""):match("^(%d+)%.(%d+)%.(%d+)$")
    if not a or #text > 16 then return nil end
    return tonumber(a) * 1000000 + tonumber(b) * 1000 + tonumber(c)
end

function V.Mine() return Meta() end

-- The reminder: once per session, and not again for a newer version it has already named.
function V.Receive(prefix, text)
    if prefix ~= V.PREFIX or not FGT.Setting("versionReminder") or V.warned then return false end
    local theirs, mine = V.Number(text), V.Number(V.Mine())
    if not theirs or not mine or theirs <= mine then return false end
    local DB = ForeverGoalTrackerDB
    if DB and DB.outdatedWarned and (V.Number(DB.outdatedWarned) or 0) >= theirs then V.warned = true; return false end
    V.warned = true
    if DB then DB.outdatedWarned = text end
    print("|cffffd75eForever Goal Tracker|r is out of date. Download the latest version on CurseForge.")
    return true
end

-- Sharing: guild after login, the group when it changes; never in combat or at logout.
V.sent = {}
function V.Send(channel)
    if FGT.loggingOut or not FGT.Setting("versionReminder") then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local mine = V.Mine()
    if not (mine and V.Number(mine)) then return end
    local now = GetTime and GetTime() or 0
    if V.sent[channel] and now - V.sent[channel] < V.THROTTLE then return end
    V.sent[channel] = now
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or rawget(_G, "SendAddonMessage")
    if send then pcall(send, V.PREFIX, mine, channel) end
end

function V.GroupChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    local instance = rawget(_G, "LE_PARTY_CATEGORY_INSTANCE")
    if instance and IsInGroup and IsInGroup(instance) then return "INSTANCE_CHAT" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

local events = CreateFrame("Frame")
V.events = events
for _, event in ipairs({ "PLAYER_LOGIN", "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, prefix, text)
    if event == "CHAT_MSG_ADDON" then
        V.Receive(prefix, text)
    elseif event == "PLAYER_LOGIN" then
        local register = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or rawget(_G, "RegisterAddonMessagePrefix")
        if register then pcall(register, V.PREFIX) end
        -- once the login rush has settled
        C_Timer.After(15, function() if IsInGuild and IsInGuild() then V.Send("GUILD") end end)
    elseif event == "GROUP_ROSTER_UPDATE" then
        local channel = V.GroupChannel()
        if channel then V.Send(channel) end
    end
end)
