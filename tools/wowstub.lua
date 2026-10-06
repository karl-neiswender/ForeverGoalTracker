-- Minimal stand-in for the WoW API: every unknown global, method or
-- field is a permissive mock. Get* methods return 0 (numbers keep math
-- working); everything else returns a mock. Good enough to run the
-- addon's load path and catch nil-index errors.
local mock
local function newmock() return setmetatable({}, getmetatable(mock)) end
local mt = {}
mt.__index = function(t, k)
  if type(k) == "string" and k:match("^Get") then return function() return 0, 0, 0, 0 end end
  if type(k) == "string" and (k:match("^Is") or k:match("^Has")) then return function() return false end end
  local m = newmock(); rawset(t, k, m); return m
end
mt.__call = function() return newmock() end
for _, op in ipairs({"__add","__sub","__mul","__div","__unm","__pow","__mod"}) do mt[op] = function() return 0 end end
mt.__concat = function(a, b) return tostring(a) .. tostring(b) end
mt.__tostring = function() return "mock" end
mock = setmetatable({}, mt)
setmetatable(_G, { __index = function(t, k) if k == "ForeverGoalTrackerDB" then return nil end; return newmock() end })
-- a few real values the addon reads at load
GetBuildInfo = function() return "1.15.9", "0", "", 11509 end
UnitName = function() return "Tester" end
GetRealmName = function() return "Realm" end
UnitRace = function() return "Human", "Human" end
UnitClass = function() return "Warrior", "WARRIOR" end
UnitFactionGroup = function() return "Alliance" end
UnitLevel = function() return 60 end
GetFileIDFromPath = function() return 1 end
C_Timer = { After = function() end }
ForeverGoalTrackerDB = nil
