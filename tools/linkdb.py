#!/usr/bin/env python3
"""Build GearLinks.lua: who sells a Gear Planner item, which quest gives it, and where they stand.

GearSources.lua (tools/sourcedb.py) names a vendor or a quest for many items, as text. This adds
what the goal page needs to link them: each vendor's NPC id and map spot, and each quest's id, its
side and the NPC who starts it (with that NPC's spot). Same site and terms as sourcedb.py
(classic.warcraftdb.com and forever.warcraftdb.com, Karl's choice 2026-10-23).

It reads sourcedb.py's item cache (run that first), then fetches the quest and NPC pages it needs
into tools/.cache/warcraftdb/<site>-quest and <site>-npc (ignored), so a rerun only fetches what is
missing.

    python3 tools/linkdb.py            fetch what is missing, then write GearLinks.lua
    python3 tools/linkdb.py --offline  write GearLinks.lua from the cache only
"""
import json
import os
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sourcedb  # noqa: E402  (its cache, fetch helper and item list)

ROOT = sourcedb.ROOT
OUT = os.path.join(ROOT, "GearLinks.lua")
HOSTS = {"classic": "https://classic.warcraftdb.com/api/data/node/",
         "forever": "https://forever.warcraftdb.com/api/data/node/"}
CACHE = os.path.join(ROOT, "tools", ".cache", "warcraftdb")
MAX_VENDORS = 12  # per item; the game picks one for the set's faction


def clean(s):
    return re.sub(r"\s+", " ", (s or "").replace("|", "/")).strip()


def sides(reaction):
    """'A', 'H', 'AH' or '' from the site's reaction badges (friendly to whom)."""
    out = ""
    for part in re.findall(r'<span class="npc-reaction ([^"]+)">(.*?)</span>', reaction or ""):
        if "friendly" in part[0]:
            out += "A" if "faction-alliance" in part[1] else "H" if "faction-horde" in part[1] else ""
    return "".join(sorted(set(out)))


def source_kinds(site):
    """item id -> 'V' or 'Q' for the items GearSources.lua sources from a vendor or a quest."""
    name = "GEARSOURCES" if site == "classic" else "GEARSOURCES_FOREVER"
    with open(os.path.join(ROOT, "GearSources.lua"), encoding="utf-8") as f:
        text = f.read()
    block = re.search(r"FGT\.%s = \[==\[\n(.*?)\n\]==\]" % name, text, re.S).group(1)
    out = {}
    for line in block.split("\n"):
        m = re.match(r"^(\d+)\|([VQ])\|", line)
        if m:
            out[int(m.group(1))] = m.group(2)
    return out


def item_rows(site, item_id, tab):
    path = os.path.join(sourcedb.SITES[site][1], "%d.json" % item_id)
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        rec = json.load(f)
    return ((rec.get("tabs") or {}).get(tab) or {}).get("rows") or []


def node_path(site, kind, node_id):
    return os.path.join(CACHE, "%s-%s" % (site, kind), "%d.json" % node_id)


def fetch_nodes(site, kind, ids):
    folder = os.path.dirname(node_path(site, kind, 0))
    os.makedirs(folder, exist_ok=True)
    todo = sorted(i for i in ids if not os.path.exists(node_path(site, kind, i)))
    print("%s %s: %d needed, %d to fetch" % (site, kind, len(ids), len(todo)), flush=True)
    done, lock, start = [0], threading.Lock(), time.time()

    def work(node_id):
        node = sourcedb.get(HOSTS[site] + kind + "/" + str(node_id))
        time.sleep(sourcedb.SPACING)
        path = node_path(site, kind, node_id)
        with open(path + ".tmp", "w", encoding="utf-8") as f:
            json.dump(node or {}, f, ensure_ascii=False)
        os.replace(path + ".tmp", path)
        with lock:
            done[0] += 1
            if done[0] % 200 == 0:
                print("  %d/%d (%.0fs)" % (done[0], len(todo), time.time() - start), flush=True)

    with ThreadPoolExecutor(2 if site == "forever" else sourcedb.WORKERS) as pool:
        for _ in pool.map(work, todo):
            pass


def load(site, kind, node_id):
    path = node_path(site, kind, node_id)
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        return json.load(f) or {}


def gather(site):
    """Item lines plus the vendor and quest ids they name."""
    kinds = source_kinds(site)
    items, vendors, quests = [], {}, set()
    for item_id, kind in sorted(kinds.items()):
        if kind == "V":
            picked = []
            for r in item_rows(site, item_id, "sold-by"):
                npc = r.get("npc_id")
                side = sides(r.get("reaction"))
                if npc and side and npc not in picked:
                    picked.append(npc)
                    vendors[npc] = side
            if picked:
                items.append((item_id, "V", picked[:MAX_VENDORS]))
        else:
            ids = [r["id"] for r in item_rows(site, item_id, "reward-from") if r.get("id")]
            if ids:
                quests.update(ids)
                items.append((item_id, "Q", ids[:4]))
    return items, vendors, quests


def npc_line(site, npc_id, side=None):
    node = load(site, "npc", npc_id)
    data, extra = node.get("data") or {}, node.get("extra") or {}
    name = clean(data.get("name"))
    if not name:
        return None
    if side is None:
        side = sides(data.get("reaction"))
    nmap = extra.get("npc_map") or {}
    zones = {f.get("id"): f.get("name") for f in nmap.get("floors") or []}
    pin = next((p for p in nmap.get("pins") or [] if p.get("ui_map_id") in zones), None)
    spot = ["", "", "", ""]
    if pin:
        spot = [str(pin["ui_map_id"]), "%.1f" % (pin["u"] * 100), "%.1f" % (pin["v"] * 100),
                clean(zones[pin["ui_map_id"]])]
    return "%d|%s|%s|%s|%s" % (npc_id, name, clean(data.get("title")), side, "|".join(spot))


def quest_info(site, quest_id):
    data = load(site, "quest", quest_id).get("data") or {}
    name = clean(data.get("name"))
    if not name:
        return None, None
    side = {"Alliance": "A", "Horde": "H"}.get(data.get("side"), "AH")
    start = re.search(r'data-tooltip="npc:(\d+)"', data.get("starts") or "")
    starter = int(start.group(1)) if start else None
    level = data.get("level") or ""
    return "%d|%s|%s|%s|%s" % (quest_id, name, side, starter or "", level), starter


def build(site, offline):
    items, vendors, quests = gather(site)
    if not offline:
        fetch_nodes(site, "quest", quests)
    quest_lines, starters = [], set()
    for qid in sorted(quests):
        line, starter = quest_info(site, qid)
        if line:
            quest_lines.append(line)
            if starter:
                starters.add(starter)
    if not offline:
        fetch_nodes(site, "npc", set(vendors) | starters)
    npc_lines = []
    for npc in sorted(set(vendors) | starters):
        line = npc_line(site, npc, vendors.get(npc))
        if line:
            npc_lines.append(line)
    item_lines = ["%d|%s|%s" % (i, k, ",".join(str(x) for x in ids)) for i, k, ids in items]
    pinned = sum(1 for l in npc_lines if l.split("|")[4])
    print("%s: %d items, %d quests, %d NPCs (%d with a map spot)" % (
        site, len(item_lines), len(quest_lines), len(npc_lines), pinned))
    return item_lines, quest_lines, npc_lines


def main():
    offline = "--offline" in sys.argv
    out = {site: build(site, offline) for site in ("classic", "forever")}
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- Generated by tools/linkdb.py from classic.warcraftdb.com and forever.warcraftdb.com;\n")
        f.write("-- do not edit by hand. Links for the Gear Planner's vendor and quest steps (GearCatalog.lua).\n")
        f.write("-- GEARLINKS: item|V|vendor NPC ids or item|Q|quest ids. GEARQUESTS: id|name|side|starting\n")
        f.write("-- NPC|level (side A, H or AH). GEARNPCS: id|name|title|friendly to (A, H, AH)|uiMapID|x|y|zone.\n")
        f.write("-- The _FOREVER lists are Forever's own; Forever falls back to the Classic ones.\n")
        f.write("local _, FGT = ...\n")
        for suffix, site in (("", "classic"), ("_FOREVER", "forever")):
            items, quests, npcs = out[site]
            for name, lines in (("GEARLINKS", items), ("GEARQUESTS", quests), ("GEARNPCS", npcs)):
                f.write("FGT.%s%s = [==[\n%s\n]==]\n" % (name, suffix, "\n".join(lines)))


if __name__ == "__main__":
    main()
