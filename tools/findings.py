"""Compare Wowhead Forever's community findings with what the addon uses.

    python tools/findings.py [findings.json]

The input is a snapshot made by tools/findings.js (by hand, at most once a day;
it reads the front page you already have open, so it adds no requests). With no
argument it uses the newest reports/audit/findings-*.json and compares it with
the one before. It reports:
  - findings that the addon already uses (an item or quest in our data was found
    by a player: a step marked 'Source unknown' may now be answerable),
  - findings that are new since the previous snapshot,
  - findings in classes of content we track but do not use yet (set pieces,
    quests) as a prompt to look, never as an instruction.
It never touches the network.
"""
import glob
import json
import os
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import auditreport  # noqa: E402

ROOT = auditreport.ROOT


def pretty(slug):
    return slug.replace("-", " ").title()


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "reports", "audit", "findings-*.json")))
    path = sys.argv[1] if len(sys.argv) > 1 else (files[-1] if files else None)
    if not path:
        sys.exit("no findings snapshot yet: run tools/findings.js on the Forever front page and save the result")
    snap = json.load(open(path, encoding="utf-8"))
    earlier = [f for f in files if os.path.abspath(f) != os.path.abspath(path) and f < path]
    prev = json.load(open(earlier[-1], encoding="utf-8")) if earlier else None
    targets = auditreport.load_targets(True)
    mine = {"item": targets["items"], "quest": targets["quests"]}
    known = {(r["kind"], r["id"]) for r in (prev or {}).get("rows", [])}

    print(f"{snap['count']} findings from {snap['fetched'][:16]} (compared with "
          f"{prev['fetched'][:10] if prev else 'nothing earlier'})\n")
    ours = [r for r in snap["rows"] if r["kind"] in mine and r["id"] in mine[r["kind"]]]
    print(f"Already in our data: {len(ours)}")
    for r in ours:
        t = mine[r["kind"]][r["id"]]
        flag = "  <- a step says 'Source unknown'" if t.get("unknown") else ""
        print(f"  {r['kind']} {r['id']} {pretty(r['slug'])} ({r['age']}): {', '.join(t['uses'][:2])}{flag}")
    new = [r for r in snap["rows"] if (r["kind"], r["id"]) not in known]
    print(f"\nNew since the last snapshot: {len(new)}")
    for r in new:
        print(f"  {r['kind']} {r['id']} {pretty(r['slug'])} ({r['age']})")
    print("\nNot in our data (a prompt to look, not an instruction):")
    for r in snap["rows"]:
        if r["kind"] in mine and r["id"] not in mine[r["kind"]]:
            print(f"  {r['kind']} {r['id']} {pretty(r['slug'])}")


if __name__ == "__main__":
    main()
