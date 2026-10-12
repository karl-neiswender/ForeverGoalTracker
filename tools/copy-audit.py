"""Compare goal mechanics and named links with a Git revision after copy edits.

Run with the same Lua 5.1/Lupa environment as check.py. Display prose is
excluded; goal IDs, order, automatic rules, prerequisites, links, recipes,
selections and other metadata must match. This does not judge prose accuracy.
"""
import collections
import json
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).parent / ".py"))
from lupa import lua51
from lupa.lua51 import lua_type

FILES = ["Data.lua", "Library.lua", "AQArmor.lua", "ArmorSets.lua", "Npcs.lua",
         "Quests.lua", "Dependencies.lua", "Core.lua", "ItemTooltips.lua"]
BASE = sys.argv[1] if len(sys.argv) > 1 else "HEAD"
old = {f: subprocess.check_output(["git", "show", f"{BASE}:{f}"]).decode("utf-8") for f in FILES}
new = {f: Path(f).read_text(encoding="utf-8") for f in FILES}


def mechanics(value, path=""):
    kind = lua_type(value)
    if kind == "table":
        out = {}
        for key, child in value.items():
            if key in {"text", "note", "tips", "foreverNote", "description"}:
                continue
            # Profession/friends target templates and mount checklist names
            # are display text. Item/goal/section names remain part of the audit.
            if key == "step" and path.endswith(".target"):
                continue
            if key == "name" and value["auto"] is not None and value["materials"] is not None:
                continue
            if isinstance(key, (int, float)) and path.endswith(".steps") and isinstance(child, str):
                out[str(key)] = "<manual step>"
            else:
                out[str(key)] = mechanics(child, f"{path}.{key}")
        return out
    if kind == "function":
        return "<function>"
    return value


def load(sources, forever):
    rt = lua51.LuaRuntime()
    rt.execute(Path("tools/wowstub.lua").read_text(encoding="utf-8"))
    if forever:
        rt.execute('GetBuildInfo = function() return "1.60.1", "70291", "", 16001 end; GetItemInfo = false')
    ns = rt.table()
    run = rt.eval('function(src,name,ns) assert(loadstring(src,"@"..name))("ForeverGoalTracker",ns) end')
    for file in FILES:
        run(sources[file], file, ns)
    return ns


result = {"base": BASE, "clients": []}
def differences(a, b, path=""):
    if isinstance(a, dict) and isinstance(b, dict):
        for key in a.keys() | b.keys():
            yield from differences(a.get(key), b.get(key), path + "." + key)
    elif a != b:
        yield {"path": path, "before": a, "after": b}

for forever in (False, True):
    before, after = load(old, forever), load(new, forever)
    changed = list(differences(mechanics(before["goals"]), mechanics(after["goals"])))
    assert not changed, "Goal mechanics changed: " + json.dumps(changed[:12], ensure_ascii=True)
    assert mechanics(before["DEPENDENCIES"]) == mechanics(after["DEPENDENCIES"]), "Prerequisites changed"
    assert mechanics(before["QUESTS"]) == mechanics(after["QUESTS"]), "Quest metadata changed"
    before_text, after_text = "\n".join(old.values()), "\n".join(new.values())
    tags = lambda text: collections.Counter(re.findall(r"\{(item:\d+|[a-z][a-z0-9_]*):", text))
    lost = tags(before_text) - tags(after_text)
    assert not lost, f"Lost link tags: {lost}"
    for quest in before["QUESTS"].values():
        name = "'" + quest[1] + "'"
        assert after_text.count(name) >= before_text.count(name), f"Lost quoted quest name: {name}"
    result["clients"].append({"client": "Forever" if forever else "Classic Era",
        "goals": len(after["goals"]), "mechanics_unchanged": True,
        "material_strings_unchanged": True, "prerequisites_unchanged": True,
        "existing_link_tags_preserved": True, "quoted_quest_names_preserved": True})
print(json.dumps(result, indent=2))
