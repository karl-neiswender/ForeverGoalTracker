"""Dump every player-facing string in the addon's data, for the language sweep.

    python tools/textdump.py [out.json]

Loads the addon against tools/wowstub.lua (like check.py) as both Classic Era
and Forever, then collects goal names, notes, steps, tips, piece and material
lines, NPC and quest text, and the string literals Core.lua shows in tooltips
and chat. Writes a list of { where, field, text } records. Run with the same
Lua 5.1 / Lupa environment as check.py.
"""
import json
import os
import re
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
if os.environ.get("FGT_LUPA"):
    sys.path.insert(0, os.environ["FGT_LUPA"])
from lupa import lua51

ROOT = os.path.dirname(here)
os.chdir(ROOT)
FILES = ["Data.lua", "Library.lua", "AQArmor.lua", "ArmorSets.lua", "Npcs.lua", "Quests.lua", "Dependencies.lua",
         "Filters.lua", "Core.lua", "ItemTooltips.lua", "Materials.lua", "WhatsNew.lua", "Ambience.lua"]
STUB = open(os.path.join(here, "wowstub.lua"), encoding="utf-8").read()

COLLECT = r'''
local out = {}
local function add(where, field, text)
  if type(text) == "string" and text ~= "" then out[#out + 1] = { where, field, text } end
end
local function Entry(where, v, name)
  if type(v) == "string" then add(where, name, v) end
end
for _, g in ipairs(STUB_NS.goals) do
  local id = g.id
  for _, f in ipairs({ "name", "short", "note", "foreverNote", "timeEstimate" }) do add(id, f, g[f]) end
  for i, t in ipairs(g.tips or {}) do add(id, "tip " .. i, t) end
  for i, s in ipairs(g.steps or {}) do
    if type(s) == "string" then add(id, "step " .. i, s) else add(id, "step " .. i, s.text); add(id, "step " .. i .. " name", s.name) end
  end
  for si, sec in ipairs(g.sections or {}) do
    add(id, "section " .. si, sec.name)
    for i, t in ipairs(sec.tips or {}) do add(id, "section " .. si .. " tip " .. i, t) end
    for pi, p in ipairs(sec.pieces or {}) do
      add(id, "piece " .. si .. "_" .. pi, p.text or p.name)
      for mi, m in ipairs(p.materials or {}) do add(id, "material " .. si .. "_" .. pi .. "_" .. mi, m) end
    end
  end
  if g.target then for k, v in pairs(g.target) do if type(v) == "string" then add(id, "target " .. k, v) end end end
end
for _, n in pairs(STUB_NS.NPCS or {}) do
  add("npc " .. tostring(n.id or n.name), "tag", n.tag); add("npc " .. tostring(n.id or n.name), "where", n.where)
end
return out
'''


def collect(forever):
    rt = lua51.LuaRuntime()
    rt.execute(STUB)
    if forever:
        rt.execute('GetBuildInfo = function() return "1.60.1", "70291", "", 16001 end')
        rt.execute("GetItemInfo = false")
    run = rt.eval('function(src, name, ns) local f = assert(loadstring(src, "@" .. name)); f("ForeverGoalTracker", ns) end')
    ns = rt.eval("{}")
    rt.globals().STUB_NS = ns
    for f in FILES:
        run(open(f, encoding="utf-8").read(), f, ns)
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN")')
    rows = rt.eval("(function() " + COLLECT + " end)()")
    return [(str(r[1]), str(r[2]), str(r[3])) for r in rows.values()]


def ui_strings():
    """String literals passed to AddLine, SetText, print and friends in Core.lua and its siblings."""
    out = []
    pat = re.compile(r'(?:AddLine|AddDoubleLine|SetText|print|Print|SetFormattedText|ShowTip)\(\s*(?:[\w.:\[\]]+\s*,\s*)?"((?:[^"\\]|\\.)*)"')
    for f in ("Core.lua", "ItemTooltips.lua", "Materials.lua", "WhatsNew.lua", "Filters.lua", "Ambience.lua"):
        for n, line in enumerate(open(f, encoding="utf-8").read().splitlines(), 1):
            for m in pat.finditer(line):
                text = m.group(1)
                if len(text) > 2 and re.search(r"[A-Za-z]{3}", text):
                    out.append((f + ":" + str(n), "ui", text))
    return out


def main():
    dest = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "reports", "copy-sweep", "textdump.json")
    seen, records = set(), []
    for forever in (False, True):
        for where, field, text in collect(forever):
            key = (where, field, text)
            if key not in seen:
                seen.add(key)
                records.append({"where": where, "field": field, "text": text, "client": "forever" if forever else "era"})
    for where, field, text in ui_strings():
        records.append({"where": where, "field": field, "text": text, "client": "both"})
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(records, fh, indent=0, ensure_ascii=False)
    print(len(records), "strings ->", dest)


if __name__ == "__main__":
    main()
