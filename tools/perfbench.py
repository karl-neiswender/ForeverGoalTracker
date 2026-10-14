"""Bench the banner animation's Lua cost and garbage, offline.

    python tools/perfbench.py

Loads the addon against tools/wowstub.lua, then runs the banner light and
particle steps for a few thousand frames at 60 fps for each of several real
banners (snow, embers, sunlight, bloom, sparks) and reports, per frame:
  - Lua time (microseconds, real Lua 5.1 on this machine; the game's own API
    calls are stubbed out, so this is the addon's share, not the whole cost),
  - garbage made (bytes: closures, tables and colours the garbage collector
    must later clean up, which is what causes stutters in game),
  - how many texture API calls were issued (each costs in the real client).
It measures; it never changes the addon. Use it before and after an
optimization. Run with the same Lua 5.1 / Lupa environment as check.py.
"""
import os
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
if os.environ.get("FGT_LUPA"):
    sys.path.insert(0, os.environ["FGT_LUPA"])
from lupa import lua51

ROOT = os.path.dirname(here)
os.chdir(ROOT)
FILES = ["Data.lua", "Library.lua", "AQArmor.lua", "ArmorSets.lua", "Npcs.lua", "Quests.lua", "Dependencies.lua",
         "Filters.lua", "Core.lua", "ItemTooltips.lua", "Materials.lua", "Popout.lua", "Rail.lua", "WhatsNew.lua", "Ambience.lua", "Audit.lua"]
STUB = open(os.path.join(here, "wowstub.lua"), encoding="utf-8").read()

BENCH = r'''
local B = STUB_NS.goalBanner
local calls = 0
local METHODS = { "SetPoint", "ClearAllPoints", "SetSize", "SetAlpha", "SetTexCoord", "SetShown", "Show", "Hide",
                  "SetTexture", "SetGradient", "SetVertexColor", "SetWidth", "SetHeight", "SetBlendMode" }
local function Quiet(t)
  for _, m in ipairs(METHODS) do rawset(t, m, function() calls = calls + 1 end) end
  return t
end
-- every texture the banner makes counts its API calls instead of doing anything
local panel = B.panel
local original = panel.CreateTexture
rawset(panel, "CreateTexture", function(self, ...) return Quiet(original(self, ...)) end)
CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end -- a real table, like the game's
for _, t in ipairs({ B.glowTex, B.raysTex, B.bloomTex, B.art }) do Quiet(t) end
rawset(B.art, "GetWidth", function() return 700 end)
local results = {}
local function Run(label, goalId, frames)
  B.goal = STUB_NS.GoalById(goalId)
  B.hasArt, B.shownArtHeight, B.uv, B.sourceAspect, B.imageFade = true, 520, { 0, 1, 0, 1 }, 4/3, 1
  B.glowLevel = 0.5
  B.emberFor = nil
  B:PlaceGlow()
  if not B.glowSpec then results[#results + 1] = { label, "no light", 0, 0, 0 }; return end
  B:ResetEmbers(); B:ResetShafts(); B.emberFor = B.glowSpec
  B.bloomOn = B.glowSpec.bloom and true or false
  B.glowAnim.t = 0
  B.tickAcc = 0
  for _ = 1, 120 do B:Tick(1/60) end -- warm up
  collectgarbage(); collectgarbage("stop")
  calls = 0
  local mem0, t0 = collectgarbage("count"), os.clock()
  for _ = 1, frames do B:Tick(1/60) end -- the game calls this each frame; it steps 30 times a second
  local secs, mem1 = os.clock() - t0, collectgarbage("count")
  collectgarbage("restart")
  results[#results + 1] = { label, "", secs/frames*1e6, (mem1 - mem0)*1024/frames, calls/frames, B.emberCount or 0, B.shaftCount or 0 }
end
local CASES = {
  { "Frostsaber (snow 90)", "frostsaber" },
  { "UBRS key (embers 48)", "key_ubrs" },
  { "Sulfuras (embers 56)", "sulfuras" },
  { "Thunderfury (glow, bloom, glint)", "thunderfury" },
  { "Shaman Tier 2 (bloom, 9 sparks)", "set_tier2_shaman" },
  { "Alliance Ambassador (sunlight)", "rep_ambassador_ally" },
  { "Rhok'delar (sunlight, blooms)", "rhokdelar" },
  { "Judgement (rays, sunlight)", "set_tier2_paladin" },
  { "Save Gold (beam, glints)", "gold_5k" },
  { "Ruins of Ahn'Qiraj (sand 70, bloom)", "raid_aq20" },
}
for _, c in ipairs(CASES) do Run(c[1], c[2], 1800) end
print(string.format("%-36s %10s %12s %10s %8s %8s", "banner", "us/frame", "garbage B/f", "api calls", "embers", "shafts"))
for _, r in ipairs(results) do
  print(string.format("%-36s %10.1f %12.0f %10.0f %8d %8d", r[1], r[3], r[4], r[5], r[6] or 0, r[7] or 0))
end
'''


def main():
    rt = lua51.LuaRuntime()
    rt.execute(STUB)
    run = rt.eval('function(src, name, ns) local f = assert(loadstring(src, "@" .. name)); f("ForeverGoalTracker", ns) end')
    ns = rt.eval("{}")
    rt.globals().STUB_NS = ns
    import time
    t0 = time.perf_counter()
    per_file = []
    for f in FILES:
        rt.execute("collectgarbage(); collectgarbage()")
        before = rt.eval('collectgarbage("count")')
        run(open(f, encoding="utf-8").read(), f, ns)
        rt.execute("collectgarbage(); collectgarbage()")
        per_file.append((f, rt.eval('collectgarbage("count")') - before))
    load = time.perf_counter() - t0
    print("heap by file (KB):", ", ".join(f"{f[:-4]} {kb:.0f}" for f, kb in per_file))
    t0 = time.perf_counter()
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN")')
    login = time.perf_counter() - t0
    rt.execute("collectgarbage(); collectgarbage()")
    heap = rt.eval('collectgarbage("count")')
    print(f"load {load * 1000:.0f} ms (parse and run every file), login events {login * 1000:.0f} ms, "
          f"Lua heap after login {heap / 1024:.1f} MB (stub frames cost nothing, so the game adds its own frame memory)")
    rt.execute("STUB_PRINTS = {}")
    rt.execute("print = function(...) local t = {} for i = 1, select('#', ...) do t[#t+1] = tostring((select(i, ...))) end io.write(table.concat(t, ' '), '\\n') end")
    rt.execute(BENCH)


if __name__ == "__main__":
    main()
