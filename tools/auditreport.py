"""Turn the in-game data audit into a to-do list.

    python tools/auditreport.py [SavedVariables file] [--no-save]

In game: run /goals audit, wait for "audit done", then /reload (the game writes
saved data to disk on reload or logout). This script reads the saved answers,
compares them with what the addon relies on (the same Audit.Targets() the game
used), and compares with the last audit on file, then writes
reports/audit/report-<date>.md and remembers the answers in reports/audit/last.json
so the next run can say what changed.

It never touches the network. The game is the source of truth: an item is
"revealed" when this client knows it (Forever hides items until a player finds
one after launch), and names and quest titles are the game's own.
"""
import glob
import json
import os
import sys
import time

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, ".py"))
if os.environ.get("FGT_LUPA"):
    sys.path.insert(0, os.environ["FGT_LUPA"])
from lupa import lua51

ROOT = os.path.dirname(here)
os.chdir(ROOT)
FILES = ["Data.lua", "Library.lua", "AQArmor.lua", "ArmorSets.lua", "Npcs.lua", "Quests.lua", "Dependencies.lua",
         "Filters.lua", "Bars.lua", "Core.lua", "ItemTooltips.lua", "Materials.lua", "WhatsNew.lua", "Ambience.lua", "Audit.lua"]
STUB = open(os.path.join(here, "wowstub.lua"), encoding="utf-8").read()


def lua_to_py(v, depth=0):
    if depth > 8:
        return None
    t = lua51.lua_type(v) if hasattr(lua51, "lua_type") else None
    if t == "table" or hasattr(v, "items"):
        keys = list(v.keys())
        if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
            return [lua_to_py(v[k], depth + 1) for k in sorted(keys)]
        return {k: lua_to_py(x, depth + 1) for k, x in v.items()}
    return v


def load_targets(forever):
    rt = lua51.LuaRuntime()
    rt.execute(STUB)
    if forever:
        rt.execute('GetBuildInfo = function() return "1.60.1", "70291", "", 16001 end; GetItemInfo = false')
    run = rt.eval('function(src, name, ns) local f = assert(loadstring(src, "@" .. name)); f("ForeverGoalTracker", ns) end')
    ns = rt.eval("{}")
    rt.globals().STUB_NS = ns
    for f in FILES:
        run(open(f, encoding="utf-8").read(), f, ns)
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN")')
    flat = rt.eval('''(function()
      local T = STUB_NS.Audit.Targets()
      local out = {}
      for kind, set in pairs(T) do
        for id, s in pairs(set) do
          local names, uses = {}, {}
          for n in pairs(s.names) do names[#names + 1] = n end
          for _, u in ipairs(s.uses) do uses[#uses + 1] = u end
          out[#out + 1] = { kind, id, table.concat(names, "|"), table.concat(uses, "|"), s.srcUnknown and 1 or 0 }
        end
      end
      return out
    end)()''')
    targets = {"items": {}, "quests": {}, "factions": {}, "maps": {}}
    for row in flat.values():
        kind, ident, names, uses, unknown = row[1], int(row[2]), row[3], row[4], row[5]
        targets[kind][ident] = {"names": [n for n in names.split("|") if n], "uses": [u for u in uses.split("|") if u],
                                "unknown": bool(unknown)}
    return targets


def read_audit(path):
    rt = lua51.LuaRuntime()
    rt.execute(open(path, encoding="utf-8", errors="replace").read())
    audit = rt.eval("ForeverGoalTrackerDB and ForeverGoalTrackerDB.audit")
    if not audit:
        return None
    return {
        "when": int(audit["when"] or 0), "build": str(audit["build"]), "version": str(audit["version"]),
        "forever": bool(audit["forever"]),
        "caps": {k: bool(v) for k, v in audit["caps"].items()},
        "items": {int(k): {"n": (v["n"] or None) if isinstance(v["n"], str) else None, "e": int(v["e"] or 0)}
                  for k, v in audit["items"].items()},
        "quests": {int(k): (v if isinstance(v, str) else None) for k, v in audit["quests"].items()},
        "factions": {int(k): (v if isinstance(v, str) else None) for k, v in audit["factions"].items()},
        "maps": {int(k): (v if isinstance(v, str) else None) for k, v in audit["maps"].items()},
    }


def default_savedvars():
    pattern = os.path.abspath(os.path.join(ROOT, "..", "..", "..", "WTF", "Account", "*", "SavedVariables", "ForeverGoalTracker.lua"))
    found = glob.glob(pattern)
    return max(found, key=os.path.getmtime) if found else None


def short(uses):
    return ", ".join(uses[:3]) + (" ..." if len(uses) > 3 else "")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path = args[0] if args else default_savedvars()
    if not path or not os.path.exists(path):
        sys.exit("no SavedVariables file found; pass its path")
    audit = read_audit(path)
    if not audit:
        sys.exit("no audit in that file: run /goals audit in game, then /reload")
    targets = load_targets(audit["forever"])
    os.makedirs(os.path.join(ROOT, "reports", "audit"), exist_ok=True)
    last_path = os.path.join(ROOT, "reports", "audit", "last.json")
    last = json.load(open(last_path, encoding="utf-8")) if os.path.exists(last_path) else None
    if last and last.get("forever") != audit["forever"]:
        last = None  # a different client's answers are not comparable

    lines = []
    out = lines.append
    when = time.strftime("%Y-%m-%d %H:%M", time.localtime(audit["when"]))
    out(f"# Data audit, {when}")
    out("")
    out(f"Client: {'Forever' if audit['forever'] else 'Classic Era'}, version {audit['version']}, build {audit['build']}. "
        f"Compared with {'the audit on file' if last else 'nothing yet (this is the first audit for this client)'}.")
    caps = audit["caps"]
    blind = [k for k, v in caps.items() if not v]
    if blind:
        out("")
        out("This client could not answer: " + ", ".join(blind) + ". Those sections are incomplete.")

    revealed = {i for i, v in audit["items"].items() if v["n"] or v["e"]}
    hidden = {i for i in audit["items"] if i not in revealed}
    out("")
    out("## Summary")
    out("")
    out(f"- Items: {len(revealed)} revealed, {len(hidden)} not revealed, of {len(audit['items'])} we rely on.")
    titled = [q for q, t in audit["quests"].items() if t]
    out(f"- Quests: {len(titled)} titles found of {len(audit['quests'])}.")
    out(f"- Factions: {sum(1 for v in audit['factions'].values() if v)} found of {len(audit['factions'])}. "
        f"Maps: {sum(1 for v in audit['maps'].values() if v)} found of {len(audit['maps'])}.")

    if last:
        was = {int(i) for i in last["revealed"]}
        newly = sorted(revealed - was)
        gone = sorted(was - revealed)
        out("")
        out(f"## Changed since {time.strftime('%Y-%m-%d', time.localtime(last['when']))}")
        out("")
        out(f"- Newly revealed items: {len(newly)}" + ("" if not newly else ""))
        for i in newly[:60]:
            t = targets["items"].get(i, {"uses": []})
            out(f"  - {i} {audit['items'][i]['n'] or '(name not loaded yet)'}: {short(t['uses'])}")
        if gone:
            out(f"- No longer revealed: {len(gone)} ({', '.join(map(str, gone[:20]))})")

    out("")
    out("## Steps that say 'Source unknown' whose item is now revealed")
    out("")
    rows = [(i, t) for i, t in targets["items"].items() if t["unknown"] and i in revealed]
    if not rows:
        out("None.")
    for i, t in sorted(rows):
        out(f"- {i} {audit['items'][i]['n'] or '(name not loaded yet)'}: {short(t['uses'])}. "
            "Check Wowhead's Community findings for a source, then update the step.")

    out("")
    out("## Names that differ from ours")
    out("")
    diff = []
    for i, t in targets["items"].items():
        game = audit["items"].get(i, {}).get("n")
        if game and t["names"] and game not in t["names"]:
            diff.append((i, game, t))
    if not diff:
        out("None.")
    for i, game, t in sorted(diff):
        out(f"- item {i}: game says '{game}', we say {' / '.join(repr(n) for n in t['names'])}. Used: {short(t['uses'])}")
    qdiff = []
    for q, t in targets["quests"].items():
        title = audit["quests"].get(q)
        if title and t["names"] and title not in t["names"]:
            qdiff.append((q, title, t))
    for q, title, t in sorted(qdiff):
        out(f"- quest {q}: game says '{title}', we say {' / '.join(repr(n) for n in t['names'])}.")

    out("")
    out("## Not found on this client")
    out("")
    missing = [f"faction {i}" for i, v in audit["factions"].items() if not v] + \
              [f"map {i} ({', '.join(targets['maps'].get(i, {}).get('names', []))}: {short(targets['maps'].get(i, {}).get('uses', []))})"
               for i, v in audit["maps"].items() if not v]
    out("\n".join("- " + m for m in missing) if missing else "None.")
    unrevealed_used = sorted(hidden)
    out("")
    out(f"## Items still not revealed ({len(unrevealed_used)})")
    out("")
    out("Expected on Forever until a player finds them after launch. Grouped by where we use them:")
    by_goal = {}
    for i in unrevealed_used:
        for u in targets["items"].get(i, {"uses": ["(unused)"]})["uses"][:1]:
            by_goal.setdefault(u.split(" ")[0], []).append(i)
    for g, ids in sorted(by_goal.items(), key=lambda kv: -len(kv[1]))[:25]:
        out(f"- {g}: {len(ids)} items")

    report = os.path.join(ROOT, "reports", "audit", "report-" + time.strftime("%Y%m%d") + ".md")
    open(report, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    if "--no-save" not in sys.argv:
        json.dump({"when": audit["when"], "forever": audit["forever"], "build": audit["build"],
                   "revealed": sorted(revealed)}, open(last_path, "w", encoding="utf-8"))
    print("\n".join(lines[:22]))
    print("...\nfull report:", report)


if __name__ == "__main__":
    main()
