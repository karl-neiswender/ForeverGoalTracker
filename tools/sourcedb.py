#!/usr/bin/env python3
"""Build GearSources.lua: where each Gear Planner item comes from in Classic Era.

The client tables have no loot tables, so sources come from classic.warcraftdb.com's
public data API (robots.txt allows all; Karl chose it 2026-10-23). For every Classic
item in GearData.lua it reads the item's Source (boss and instance, from the game's
Encounter Journal data), Dropped By, Reward From (quests), Sold By and Contained In tabs.

Responses are cached in tools/.cache/warcraftdb (ignored), one JSON file per item, so a
rerun only fetches what is missing. Delete the folder to refresh. Requests are spaced
out and run a few at a time.

    python3 tools/sourcedb.py            fetch what is missing, then write GearSources.lua
    python3 tools/sourcedb.py --offline  write GearSources.lua from the cache only
    python3 tools/sourcedb.py forever    fetch one site only (classic or forever), then write
    python3 tools/sourcedb.py --refresh-forever
                                         also ask Forever again for items with no source yet
"""
import json
import os
import re
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "GearSources.lua")
# Each site: its item API, its cache folder and the GearData Forever statuses it covers.
# The Forever site knows only items Forever's client has revealed (statuses 1 to 3).
SITES = {
    "classic": ("https://classic.warcraftdb.com/api/data/node/item/",
                os.path.join(ROOT, "tools", ".cache", "warcraftdb", "item"), (0, 1)),
    "forever": ("https://forever.warcraftdb.com/api/data/node/item/",
                os.path.join(ROOT, "tools", ".cache", "warcraftdb", "forever"), (1, 2, 3)),
}
AGENT = "ForeverGoalTracker-sourcedb/1.0 (World of Warcraft addon; one-off item source import)"
TABS = ("source", "dropped-by", "reward-from", "sold-by", "contained-in")
WORKERS, SPACING = 4, 0.25  # seconds between one worker's requests

# A drop from more NPCs than this, none of them a journal boss, is a world drop.
WORLD_DROP = 8


def items():
    """(id, forever status) for every item in GearData.lua, once. Forever's versions of
    changed items (foreverBlocks, status 4 or 1) are items both clients have."""
    out, seen = [], set()
    with open(os.path.join(ROOT, "GearData.lua"), encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^(\d+)\|(?:[^|]*\|){6}(\d)\|", line)
            if m and int(m.group(1)) not in seen:
                seen.add(int(m.group(1)))
                out.append((int(m.group(1)), 1 if m.group(2) == "4" else int(m.group(2))))
    return out


def get(url, tries=4):
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": AGENT, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            time.sleep(2 * (attempt + 1))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ConnectionError):
            time.sleep(2 * (attempt + 1))
    raise RuntimeError("failed: " + url)


def fetch(item_id, site):
    api, cache, _ = SITES[site]
    path = os.path.join(cache, "%d.json" % item_id)
    if os.path.exists(path):
        return
    node = get(api + str(item_id))
    time.sleep(SPACING)
    record = {"id": item_id, "found": node is not None, "source": None, "tabs": {}}
    if node:
        record["source"] = (node.get("data") or {}).get("source")
        for tab in node.get("tabs") or []:
            if tab["slug"] in TABS:
                page = get("%s%d/tab/%s?page=1" % (api, item_id, tab["slug"]))
                time.sleep(SPACING)
                record["tabs"][tab["slug"]] = {"total": tab.get("count"), "rows": (page or {}).get("rows") or []}
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(record, f, ensure_ascii=False)
    os.replace(tmp, path)


def fetch_all(ids, site, workers=WORKERS):
    cache = SITES[site][1]
    os.makedirs(cache, exist_ok=True)
    todo = [i for i in ids if not os.path.exists(os.path.join(cache, "%d.json" % i))]
    print("%s: %d items, %d to fetch" % (site, len(ids), len(todo)), flush=True)
    done, lock, start = [0], threading.Lock(), time.time()

    def work(i):
        fetch(i, site)
        with lock:
            done[0] += 1
            if done[0] % 250 == 0:
                print("  %d/%d (%.0fs)" % (done[0], len(todo), time.time() - start), flush=True)

    with ThreadPoolExecutor(workers) as pool:
        for _ in pool.map(work, todo):
            pass


# ------------------------------------------------------------------
# Turning the site's rows into short source lines
# ------------------------------------------------------------------
# The site's instance names, as the addon's dungeon list (FGT.DUNGEONS) spells them.
PLACE = {
    "Ahn'Qiraj (Ruins)": "Ruins of Ahn'Qiraj",
    "Ahn'Qiraj (Temple)": "Temple of Ahn'Qiraj",
    "Ahn'Qiraj Temple": "Temple of Ahn'Qiraj",
    "Stratholme (Undead)": "Stratholme",
    "Stratholme (Live)": "Stratholme",
    "Stratholme (Living)": "Stratholme",
    "Dire Maul (East)": "Dire Maul East",
    "Dire Maul (West)": "Dire Maul West",
    "Dire Maul (North)": "Dire Maul North",
    "Blackrock Spire (Upper)": "Upper Blackrock Spire",
    "Blackrock Spire (Lower)": "Lower Blackrock Spire",
    "Upper Blackrock Spire": "Upper Blackrock Spire",
    "Lower Blackrock Spire": "Lower Blackrock Spire",
    "Scarlet Monastery (Armory)": "Scarlet Monastery",
    "Scarlet Monastery (Cathedral)": "Scarlet Monastery",
    "Scarlet Monastery (Graveyard)": "Scarlet Monastery",
    "Scarlet Monastery (Library)": "Scarlet Monastery",
    "The Deadmines": "Deadmines",
    "The Temple of Atal'hakkar": "Sunken Temple",
    "Temple of Atal'hakkar": "Sunken Temple",
    "The Temple of Atal'Hakkar": "Sunken Temple",
    "Temple of Atal'Hakkar": "Sunken Temple",
    "Stormwind Stockade": "The Stockade",
}
WING = {
    "Stratholme (Undead)": "undead side",
    "Stratholme (Live)": "living side",
    "Stratholme (Living)": "living side",
    "Scarlet Monastery (Armory)": "Armory",
    "Scarlet Monastery (Cathedral)": "Cathedral",
    "Scarlet Monastery (Graveyard)": "Graveyard",
    "Scarlet Monastery (Library)": "Library",
}


# Quest "zones" that are really the site's class quest categories.
NOT_PLACES = {"Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"}


def place(name):
    name = (name or "").strip()
    return PLACE.get(name, name)


def plain(text):
    """Strip the site's HTML (vendor locations are links)."""
    text = re.sub(r"<[^>]+>", "", text or "").strip()
    return "" if text in ("—", "-") else text


def either(names, limit=2):
    names = list(dict.fromkeys(n for n in names if n))
    if not names or len(names) > limit:
        return None
    return " or ".join(names)


def clean(s):
    return re.sub(r"\s+", " ", (s or "").replace("|", "/")).strip()


def line_for(rec):
    """id|kind|who|place|detail, or None. Kinds: B boss, N named NPC drop, W world drop,
    Q quest, V vendor, O container."""
    tabs = rec["tabs"]
    bosses = (tabs.get("source") or {}).get("rows") or []
    bosses = [r for r in bosses if r.get("instance_name")]
    if bosses:
        places = list(dict.fromkeys(place(r["instance_name"]) for r in bosses))
        if len(places) == 1:
            who = either([r["name"] for r in bosses]) or "several bosses"
            wings = list(dict.fromkeys(WING.get(r["instance_name"].strip(), "") for r in bosses))
            return ("B", who, places[0], wings[0] if len(wings) == 1 else "")
        return ("B", either([r["name"] for r in bosses]) or "several bosses", either(places) or "", "")
    quests = (tabs.get("reward-from") or {}).get("rows") or []
    if quests:
        names = list(dict.fromkeys(r["name"] for r in quests if r.get("name")))
        names = ";".join(names) if len(names) <= 2 else ""
        zones = list(dict.fromkeys(place(r.get("zone")) for r in quests
                                   if r.get("zone") and r["zone"] not in NOT_PLACES))
        return ("Q", names or "", zones[0] if len(zones) == 1 else "", "")
    containers = (tabs.get("contained-in") or {}).get("rows") or []
    drops = tabs.get("dropped-by") or {}
    drop_rows = drops.get("rows") or []
    if drop_rows:
        total = drops.get("total") or len(drop_rows)
        seen = "beta" if any("sample" in r for r in drop_rows) else ""  # Forever: observed loot
        if total > WORLD_DROP:
            return ("W", "", "", seen)
        return ("N", either([r["name"] for r in drop_rows]) or "several creatures", "", seen)
    vendors = (tabs.get("sold-by") or {}).get("rows") or []
    if vendors:
        locs = list(dict.fromkeys(plain(r.get("location")) for r in vendors if plain(r.get("location"))))
        who = either([r["name"] for r in vendors], 1)
        return ("V", who or "", locs[0] if len(locs) == 1 else "", "")
    if containers:
        return ("O", either([r.get("name") for r in containers]) or "", "", "")
    return None


def lines_for(site, ids):
    cache = SITES[site][1]
    lines, kinds, missing = [], {}, 0
    for item_id in ids:
        path = os.path.join(cache, "%d.json" % item_id)
        if not os.path.exists(path):
            missing += 1
            continue
        with open(path, encoding="utf-8") as f:
            out = line_for(json.load(f))
        if out:
            kinds[out[0]] = kinds.get(out[0], 0) + 1
            lines.append("%d|%s" % (item_id, "|".join(clean(x) for x in out)))
    print("%s: %d sources %s; %d items not fetched" % (site, len(lines), kinds, missing))
    return lines


def write(by_site):
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- Generated by tools/sourcedb.py from classic.warcraftdb.com and forever.warcraftdb.com;\n")
        f.write("-- do not edit by hand. Line: id|kind|who|place|detail. Kinds: B boss (who in place;\n")
        f.write("-- detail is a wing), N named creature drop, W world drop, Q quest (who: one or two\n")
        f.write("-- names split by ;), V vendor (place is its zone), O container.\n")
        f.write("-- GEARSOURCES is Classic Era. GEARSOURCES_FOREVER covers items Forever has revealed; its\n")
        f.write("-- drops are loot players saw in the beta, not the game's own tables.\n")
        f.write("local _, FGT = ...\n")
        for name, site in (("GEARSOURCES", "classic"), ("GEARSOURCES_FOREVER", "forever")):
            f.write("FGT.%s = [==[\n%s\n]==]\n" % (name, "\n".join(by_site[site])))


def forget_unsourced(site, ids):
    """Drop cached items that have no source yet, so the next fetch asks again.
    Forever's data grows as players reveal items; found sources rarely change."""
    cache, dropped = SITES[site][1], 0
    for item_id in ids:
        path = os.path.join(cache, "%d.json" % item_id)
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            if line_for(json.load(f)):
                continue
        os.remove(path)
        dropped += 1
    print("%s: asking again for %d items without a source" % (site, dropped), flush=True)


def main():
    all_items = items()
    only = [a for a in sys.argv[1:] if a in SITES]
    by_site = {}
    for site, (_, _, statuses) in SITES.items():
        ids = [i for i, s in all_items if s in statuses]
        if "--refresh-forever" in sys.argv and site == "forever":
            forget_unsourced(site, ids)
        if "--offline" not in sys.argv and (not only or site in only):
            fetch_all(ids, site, 2 if site == "forever" else WORKERS)
        by_site[site] = lines_for(site, ids)
    write(by_site)


if __name__ == "__main__":
    main()
