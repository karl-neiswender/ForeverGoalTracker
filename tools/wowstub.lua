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
-- Unknown globals: calling one returns nil (the safe answer the addon
-- guards against, like "no data"), while indexing one gives methods, so
-- objects such as UIParent or GameTooltip still work.
local gmt = {}
for k, v in pairs(mt) do gmt[k] = v end
gmt.__call = function() return nil end
setmetatable(_G, { __index = function(t, k)
  if k == "ForeverGoalTrackerDB" then return nil end
  if type(k) == "string" and k:match("^C_") then return nil end -- optional game namespaces: the addon checks for them
  if type(k) == "string" and k:match("^GetNum") then return function() return 0 end end -- counts are always numbers
  return setmetatable({}, gmt)
end })
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
GetScreenWidth = function() return 1920 end
GetScreenHeight = function() return 1080 end
GetTime = function() return 100 end
time = function() return 1790000000 end
GetMoney = function() return 0 end
UnitXP = function() return 0 end
UnitXPMax = function() return 1 end
GetCursorPosition = function() return 0, 0 end
ForeverGoalTrackerDB = nil

-- Frames that remember their scripts and events, so tools/check.py can
-- fire ADDON_LOADED and PLAYER_LOGIN through the addon's real handlers.
STUB_FRAMES = {}
local fmt = {}
for k, v in pairs(mt) do fmt[k] = v end
fmt.__index = function(t, k)
  if k == "SetScript" then return function(self, name, fn) rawset(self, "_s_" .. name, fn) end end
  if k == "GetScript" then return function(self, name) return rawget(self, "_s_" .. name) end end
  if k == "HookScript" then return function(self, name, fn) rawset(self, "_s_" .. name, fn) end end
  if k == "RegisterEvent" then return function(self, ev)
    local e = rawget(self, "_ev") or {}; e[ev] = true; rawset(self, "_ev", e) end end
  if k == "UnregisterEvent" then return function(self, ev)
    local e = rawget(self, "_ev"); if e then e[ev] = nil end end end
  return mt.__index(t, k)
end
CreateFrame = function()
  local f = setmetatable({}, fmt)
  table.insert(STUB_FRAMES, f)
  return f
end
function STUB_FIRE(event, ...)
  for _, f in ipairs(STUB_FRAMES) do
    local e, h = rawget(f, "_ev"), rawget(f, "_s_OnEvent")
    if e and e[event] and h then h(f, event, ...) end
  end
end
C_Timer = { After = function(_, fn) fn() end }
STUB_PRINTS = {}
print = function(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
  table.insert(STUB_PRINTS, table.concat(t, " ")) end
strsplit = function(sep, s)
  local out = {}
  for piece in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = piece end
  return unpack(out)
end
