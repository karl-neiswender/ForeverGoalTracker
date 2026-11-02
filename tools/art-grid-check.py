"""Compare the checklist's race and class grid with what the addon really shows.

  python3 tools/art-grid-check.py

For every race, class and sex in Goal-art-checklist.html's grid, this asks the addon (through the
same Lua runtime art-plan.py verify uses) which Level Classes to 60 banner that character gets, and
compares it with the image the grid claims (RC_ART). It prints each cell where they differ, so the
hand-copied RC_ART table cannot drift from Core.lua unnoticed.

Run from the repository root. Needs lupa (tools/.py, see check.py).
"""
import importlib.util, re, sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / "tools" / ".py"))
spec = importlib.util.spec_from_file_location("artplan", root / "tools/art-plan.py")
artplan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(artplan)

text = (root / "reports/Goal-art-checklist.html").read_text(encoding="utf-8")


def block(start, end):
    i = text.index(start)
    return text[i:text.index(end, i)]


races = []
for m in re.finditer(r'\{ name: "([^"]+)", token: "(\w+)", side: "(\w+)"(, forever: true)?, era: \[([^\]]*)\], fnew: \[([^\]]*)\] \}',
                     block("var RACES = [", "];")):
    q = lambda s: re.findall(r'"(\w+)"', s)
    races.append(dict(name=m.group(1), token=m.group(2), side=m.group(3), classes=q(m.group(5)) + q(m.group(6))))
art = []
for m in re.finditer(r'\{ f: "(\w+)", c: "(\w+)"(?:, r: "(\w+)")?, k: "([^"]+)"(?:, shows: "(\w+)")?(?:, only: "(\w)")?(?:, pic: "(\w+)")? \}',
                     block("var RC_ART = [", "];")):
    art.append(dict(f=m.group(1), c=m.group(2), r=m.group(3), k=m.group(4), only=m.group(6)))


def claimed(race, cls, sex):
    """The image the grid shows (the same pick as the page's rcPick)."""
    best, score = None, -1
    for v in art:
        if v["f"] != race["side"] or v["c"] != cls or (v["r"] and v["r"] != race["token"]):
            continue
        if v["only"] and v["only"] != sex:
            continue
        w = 100 + (20 if v["r"] else 0) + 10 + (1 if v["only"] else 0)
        if w > score:
            best, score = v, w
    return best["k"] if best else None


rt, ns = artplan.load_addon()
bad = 0
for race in races:
    for cls in race["classes"]:
        for sex, sx in (("m", 2), ("f", 3)):
            tbl = rt.table()
            tbl["faction"], tbl["class"], tbl["race"], tbl["sex"] = race["side"], cls.upper(), race["token"], sx
            got = ns.goalBanner.ResolveArt(ns.goalBanner, "allclasses", tbl)
            got = got[0] if isinstance(got, tuple) else got
            real = re.sub(r"-banner\.blp$", "", got) if got else None
            want = claimed(race, cls, sex)
            if real != want:
                bad += 1
                print(f"{race['side'][0]} {race['name']} {cls} {sex.upper()}: addon gives {real}, grid claims {want}")
print(f"{bad} cells differ")
sys.exit(1 if bad else 0)
