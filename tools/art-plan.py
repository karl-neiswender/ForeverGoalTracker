"""Art matching plan: work queue, progress and checks.

  python3 tools/art-plan.py build            rewrite reports/Art-matching-plan-2026-10-29.md and .html from the plan and status
  python3 tools/art-plan.py status           progress by priority and state
  python3 tools/art-plan.py batch [N]        the next batch (or batch N) of work items
  python3 tools/art-plan.py set ID... STATE [--banner KEY] [--note TEXT]
                                             move work items along: review, approved, installed, verified,
                                             rejected, blocked, queued
  python3 tools/art-plan.py swap ID FILE     Karl supplied a larger (or different) source for a work item
  python3 tools/art-plan.py sheet N          contact sheet of batch N (source next to the review image)
  python3 tools/art-plan.py check-master PNG...   check a 1200 x 900 master or review image
  python3 tools/art-plan.py verify ID...     check an installed work item end to end
  python3 tools/art-plan.py verify --key KEY --goal GOAL [--faction F] [--class C] [--race R] [--sex 2|3]
                                             the same checks for one banner (also works on banners already installed)

Run from the repo root. Needs Pillow and lupa (tools/.py, see check.py). The plan is frozen in
reports/art-plan/plan.json; progress lives in reports/art-plan/status.json. Only `swap` changes the plan.
"""
import base64, html, io, json, re, struct, sys
from datetime import date
from pathlib import Path

root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / "tools" / ".py"))
PLAN = root / "reports/art-plan/plan.json"
STATUS = root / "reports/art-plan/status.json"
MD = root / "reports/Art-matching-plan-2026-10-29.md"
HTML = root / "reports/Art-matching-plan-2026-10-29.html"
ART = root / "Media/artwork"
FINAL = root / "Media/final-images"
CHECKLIST = root / "reports/Goal-art-checklist.html"

STATES = ["queued", "review", "approved", "installed", "verified"]
SIDE = ["rejected", "blocked", "skipped_lowres"]
LABEL = {"queued": "Queued", "review": "In review", "approved": "Approved", "installed": "Installed", "verified": "Verified",
         "rejected": "Rejected", "blocked": "Blocked", "skipped_lowres": "Skipped (low-res)"}
PRI = {1: "P1 goal banners", 2: "P2 Level Classes to 60", 3: "P3 armor sets", 4: "P4 optional"}


def load():
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    status = json.loads(STATUS.read_text(encoding="utf-8")) if STATUS.exists() else {}
    return plan, status


def state_of(row, status):
    return status.get(row["id"], {}).get("state", row["state"])


def write_text(path, text):
    """Windows can briefly lock a file a browser or scanner has open, so retry."""
    import time
    for i in range(5):
        try:
            path.write_text(text, encoding="utf-8", newline="\n")
            return
        except OSError:
            if i == 4:
                raise
            time.sleep(1.5)


def save_status(status):
    STATUS.write_text(json.dumps(status, indent=1, sort_keys=True) + "\n", encoding="utf-8", newline="\n")


# ---------------------------------------------------------------- checks
def master_stats(path):
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    with Image.open(path) as im:
        size = im.size
        im = im.convert("RGB")
        w, h = im.size
        px = im.load()

        def mean(x0, x1, y0, y1):
            s = n = 0
            for y in range(y0, y1, 6):
                for x in range(x0, x1, 6):
                    r, g, b = px[x, y]
                    s += (r + g + b) / 3
                    n += 1
            return s / max(n, 1)
        dev = 0.0
        n = 0
        for y in range(0, h, 30):
            for x in range(0, w, 30):
                r, g, b = px[x, y]
                dev += max(r, g, b) - min(r, g, b)
                n += 1
        return dict(size=size, left=mean(0, max(w // 20, 1), 0, max(h - 120, 1)), bottom=mean(0, w, max(h - 20, 0), h),
                    mid=mean(w // 3, w * 11 // 12, h // 9, h * 2 // 3), colordev=dev / max(n, 1))


def check_master(path):
    """Returns (problems, stats). Thresholds come from the 210 approved masters (left <= 41, bottom <= 27, color dev <= 5.3)."""
    problems = []
    try:
        st = master_stats(path)
    except Exception as e:
        return [f"cannot open: {e}"], {}
    if st["size"] != (1200, 900):
        problems.append(f"size {st['size'][0]}x{st['size'][1]}, expected 1200x900")
    if st["colordev"] > 6:
        problems.append(f"not neutral black and white (color deviation {st['colordev']:.1f}, approved masters are 5.3 or less)")
    if st["left"] > 45 or st["left"] > st["mid"] * 0.6:
        problems.append(f"left gradient too light (edge {st['left']:.0f}, middle {st['mid']:.0f}; approved masters are 41 or less)")
    if st["bottom"] > 30 or st["bottom"] > st["mid"] * 0.5:
        problems.append(f"bottom gradient too light (edge {st['bottom']:.0f}, middle {st['mid']:.0f}; approved masters are 27 or less)")
    return problems, st


def blp_problems(path):
    from PIL import Image
    problems = []
    data = path.read_bytes()
    if data[:4] != b"BLP2":
        return ["not a BLP2 file"]
    ver, enc, adepth, aenc, mips, w, h = struct.unpack("<I4BII", data[4:20])[0], *struct.unpack("<4B", data[8:12]), *struct.unpack("<II", data[12:20])
    offsets = struct.unpack("<16I", data[20:84])
    n = sum(1 for o in offsets if o)
    if (w, h) != (512, 512):
        problems.append(f"{w}x{h}, expected 512x512")
    if enc != 2:
        problems.append("not DXT compressed")
    if n != 10:
        problems.append(f"{n} mip levels, expected 10")
    try:
        with Image.open(path) as im:
            im.load()
            if im.size != (512, 512):
                problems.append("decoded size is not 512x512")
    except Exception as e:
        problems.append(f"does not decode: {e}")
    return problems


def load_addon():
    from lupa import lua51
    files = [x.strip() for x in (root / "ForeverGoalTracker.toc").read_text(encoding="utf-8").splitlines() if x.strip().endswith(".lua")]
    rt = lua51.LuaRuntime()
    rt.execute((root / "tools/wowstub.lua").read_text(encoding="utf-8"))
    run = rt.eval('function(src,name,ns) assert(loadstring(src,"@"..name))("ForeverGoalTracker", ns) end')
    ns = rt.table()
    rt.globals().STUB_NS = ns
    for f in files:
        run((root / f).read_text(encoding="utf-8"), f, ns)
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN")')
    return rt, ns


def verify_banner(key, goal, who_list, checklist_kind, rt_ns=None):
    """One banner: files, manifest, mapping and checklist. Returns a list of problems."""
    problems = []
    blp = root / "Media" / f"{key}-banner.blp"
    if not blp.exists():
        return [f"Media/{blp.name} does not exist"]
    problems += [f"BLP: {p}" for p in blp_problems(blp)]
    art = (root / "tools/artwork.py").read_text(encoding="utf-8")
    m = re.search(r'"%s":\s*"([^"]+)"' % re.escape(key), art)
    if not m:
        problems.append("tools/artwork.py has no FINAL_BANNERS entry")
    else:
        master = FINAL / m.group(1)
        if not master.exists():
            problems.append(f"master Media/final-images/{m.group(1)} is missing")
        else:
            p, _ = check_master(master)
            problems += [f"master: {x}" for x in p]
    manifest = json.loads((FINAL / "runtime-manifest.json").read_text(encoding="utf-8"))
    ent = manifest.get(key)
    if not ent:
        problems.append("runtime-manifest.json has no entry (run python3 tools/artwork.py --final-only)")
    elif ent.get("mips") != 10 or abs(ent.get("aspect", 0) - 4 / 3) > 0.01:
        problems.append("runtime-manifest entry is not 10 mips at 4:3")
    core = (root / "Core.lua").read_text(encoding="utf-8")
    if f'"{key}-banner.blp"' not in core:
        problems.append("Core.lua never mentions the banner path")
    if goal and who_list:
        rt, ns = rt_ns or load_addon()
        for who in who_list:
            tbl = rt.table()
            for k, v in who.items():
                if v is not None:
                    tbl[k] = v
            got = ns.goalBanner.ResolveArt(ns.goalBanner, goal, tbl)
            got = got[0] if isinstance(got, tuple) else got
            if got != f"{key}-banner.blp":
                problems.append(f"resolver gives {got} for {goal} {dict((k, v) for k, v in who.items() if v is not None)}, expected {key}-banner.blp")
    text = CHECKLIST.read_text(encoding="utf-8")
    if not re.search(r'"%s":\s*"data:image' % re.escape(key), text):
        problems.append("no thumbnail for this key in Goal-art-checklist.html (run python3 tools/art-checklist.py thumbs)")
    if checklist_kind == "leveling" and not re.search(r'k:\s*"%s"' % re.escape(key), text):
        problems.append("RC_ART in Goal-art-checklist.html has no entry for this key")
    if checklist_kind == "set" and not re.search(r'"%s":\s*"[mfn]+"' % re.escape(key), text):
        problems.append("SETPIC in Goal-art-checklist.html has no entry for this key")
    if checklist_kind == "item" and key not in text[text.index("var GOALS"):text.index("var CLASSIMG")]:
        problems.append("no GOALS row in Goal-art-checklist.html names this banner")
    rec = [p for p in (root / "reports/image-tests").glob("*") if p.is_file() and p.suffix in (".md", ".json") and key in p.read_text(encoding="utf-8", errors="ignore")]
    if not rec:
        problems.append("no record in reports/image-tests mentions this key")
    return problems


def who_for(target):
    spec = target.get("resolve")
    if not spec:
        return None, []
    goal = spec["goal"]
    base = {k: v for k, v in spec.items() if k != "goal"}
    if "faction" not in base or not base["faction"]:
        return goal, [dict(base, faction="Alliance"), dict(base, faction="Horde")]
    return goal, [base]


def kind_of(row, target):
    if row["group"] == "leveling":
        return "leveling"
    if row["group"] in ("tier", "dungeon", "pvp", "aq"):
        return "set"
    return "item"


def cmd_verify(args):
    status_ok = True
    if "--key" in args:
        def opt(name, cast=str):
            return cast(args[args.index(name) + 1]) if name in args else None
        who = {"faction": opt("--faction"), "class": opt("--class"), "race": opt("--race"), "sex": opt("--sex", int)}
        who_list = [who] if any(who.values()) else ([dict(faction="Alliance"), dict(faction="Horde")] if opt("--goal") else [])
        probs = verify_banner(opt("--key"), opt("--goal"), who_list, None)
        print(opt("--key"), "FAIL" if probs else "ok")
        for p in probs:
            print("   -", p)
        return 1 if probs else 0
    plan, status = load()
    rows = {r["id"]: r for r in plan["rows"]}
    rt_ns = None
    for rid in args:
        row = rows.get(rid)
        if not row:
            print(rid, "is not a work item")
            status_ok = False
            continue
        st = status.get(rid, {})
        if state_of(row, status) not in ("installed", "verified"):
            print(rid, "is", state_of(row, status), "- verify runs on installed items")
            status_ok = False
            continue
        rt_ns = rt_ns or load_addon()
        keys = [t.get("key") for t in row["targets"]]
        for t in row["targets"]:
            key = st.get("banner") or t.get("key")
            goal, who_list = who_for(t)
            probs = verify_banner(key, goal, who_list, kind_of(row, t), rt_ns)
            if not t.get("resolve"):
                probs.append("manual: no automatic resolver check for this target; open it in game")
            hard = [p for p in probs if not p.startswith("manual:")]
            print(f"{rid} {t['label']} [{key}]: {'FAIL' if hard else 'ok'}")
            for p in probs:
                print("   -", p)
            status_ok = status_ok and not hard
    return 0 if status_ok else 1


def cmd_check_master(args):
    bad = 0
    for a in args:
        probs, st = check_master(Path(a))
        print(a, "FAIL" if probs else "ok", {k: (round(v, 1) if isinstance(v, float) else v) for k, v in st.items()})
        for p in probs:
            print("   -", p)
        bad += bool(probs)
    return 1 if bad else 0


# ---------------------------------------------------------------- queue commands
def cmd_status():
    plan, status = load()
    from collections import Counter
    total = Counter()
    for pr in (1, 2, 3, 4):
        c = Counter(state_of(r, status) for r in plan["rows"] if r["priority"] == pr)
        print(f"{PRI[pr]:26} " + "  ".join(f"{LABEL[s]} {c[s]}" for s in STATES + SIDE if c[s]) + f"   (total {sum(c.values())})")
        total.update(c)
    done = total["verified"]
    work = sum(v for k, v in total.items() if k not in ("skipped_lowres", "blocked"))
    print(f"\nVerified {done} of {work} workable items; {total['skipped_lowres']} skipped for low resolution; {total['blocked']} blocked; {len(plan['gaps'])} slots have no source image.")
    return 0


def cmd_batch(args):
    plan, status = load()
    if args:
        n = int(args[0])
    else:
        open_batches = sorted({r["batch"] for r in plan["rows"] if r["batch"] and state_of(r, status) == "queued"})
        if not open_batches:
            print("Nothing is queued.")
            return 0
        n = open_batches[0]
    print(f"Batch {n}")
    for r in plan["rows"]:
        if r["batch"] == n:
            s = state_of(r, status)
            print(f"  {r['id']} [{LABEL[s]}] {r['file']} ({r['w']}x{r['h']}){' CARD' if r['card'] else ''}")
            for t in r["targets"]:
                print(f"       -> {t['label']}  key {t['key']}  goal {t.get('goal')}")
    return 0


def cmd_set(args):
    plan, status = load()
    opts = {}
    ids = []
    i = 0
    state = None
    while i < len(args):
        a = args[i]
        if a in ("--banner", "--note"):
            opts[a[2:]] = args[i + 1]
            i += 2
            continue
        if a in STATES + SIDE:
            state = a
        else:
            ids.append(a)
        i += 1
    rows = {r["id"]: r for r in plan["rows"]}
    if not state or not ids:
        print(__doc__)
        return 1
    for rid in ids:
        row = rows.get(rid)
        if not row:
            print(rid, "is not a work item")
            return 1
        cur = state_of(row, status)
        if cur == "skipped_lowres" and state != "queued":
            print(rid, "is skipped for low resolution; use `swap` when Karl supplies a larger file")
            return 1
        if state in STATES and cur in STATES and STATES.index(state) > STATES.index(cur) + 1:
            print(rid, f"is {cur}; it cannot jump to {state}")
            return 1
        entry = status.setdefault(rid, {})
        entry["state"] = state
        entry["date"] = date.today().isoformat()
        if "banner" in opts:
            entry["banner"] = opts["banner"]
        elif state == "installed" and "banner" not in entry:
            entry["banner"] = row["targets"][0]["key"]
        if "note" in opts:
            entry["note"] = opts["note"]
        print(rid, cur, "->", state)
    save_status(status)
    return 0


def cmd_swap(args):
    plan, status = load()
    rid, newfile = args[0], args[1]
    rows = {r["id"]: r for r in plan["rows"]}
    row = rows[rid]
    p = ART / newfile
    if not p.exists():
        print("no such file in Media/artwork:", newfile)
        return 1
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    with Image.open(p) as im:
        w, h = im.size
    row.setdefault("previous", []).append(row["file"])
    row.update(file=newfile, w=w, h=h, low=min(w, h) < plan["lowpx"], card=bool(0.704 < w / h < 0.728 and w <= 760))
    if row["low"]:
        print("still low-res:", w, h)
    else:
        status.setdefault(rid, {}).update(state="queued", date=date.today().isoformat(), note=f"source swapped to {newfile}")
        last = max(r["batch"] or 0 for r in plan["rows"])
        size = sum(1 for r in plan["rows"] if r["batch"] == last)
        row["batch"] = last if size < plan["batch_size"] else last + 1
    PLAN.write_text(json.dumps(plan, indent=1) + "\n", encoding="utf-8", newline="\n")
    save_status(status)
    print(rid, "now uses", newfile, f"({w}x{h})", "batch", row["batch"])
    return 0


def cmd_sheet(args):
    from PIL import Image, ImageDraw
    Image.MAX_IMAGE_PIXELS = None
    plan, status = load()
    n = int(args[0])
    rows = [r for r in plan["rows"] if r["batch"] == n]
    if not rows:
        print("no such batch")
        return 1
    W, H = 360, 270
    im = Image.new("RGB", (2 * W, len(rows) * (H + 26)), (24, 24, 24))
    d = ImageDraw.Draw(im)
    for i, r in enumerate(rows):
        y = i * (H + 26)
        key = r["targets"][0]["key"]
        rev = sorted(FINAL.glob(f"{key}-review*.png")) or sorted(FINAL.glob(f"**/{key}*review*.png"))
        for j, p in enumerate([ART / r["file"], rev[-1] if rev else None]):
            if p and p.exists():
                with Image.open(p) as src:
                    src = src.convert("RGB")
                    src.thumbnail((W - 6, H - 6))
                    im.paste(src, (j * W + 3, y + 3))
            else:
                d.text((j * W + 10, y + 10), "no review image yet", fill=(255, 120, 120))
        d.text((6, y + H), f"{r['id']}  {r['targets'][0]['label']}  ->  {key}", fill=(255, 220, 120))
    out = FINAL / "review-sheets"
    out.mkdir(parents=True, exist_ok=True)
    path = out / f"batch-{n:02d}.jpg"
    im.save(path, quality=85)
    print("wrote", path.relative_to(root))
    return 0


# ---------------------------------------------------------------- documents
WORK_ORDER = [
    ("Goal", None),
    ("p", "Every image below is locked by Karl (2026-10-29, commit 5abd851). Turn each one into an approved, installed and mapped banner, and keep "
          "[Goal-art-checklist.html](Goal-art-checklist.html) accurate while you do. **Target: all P1 goal banners by Oct 31, P2 by Nov 2, as much of P3 "
          "as fits by Nov 3, so live Forever can be tested on Nov 4.** New textures need a full game restart, so everything has to be installed before then."),
    ("Who does what", None),
    ("ul", ["**Codex:** generate, install and map, update the checklist, and record each batch.",
            "**Karl:** looks at each batch's review sheet and says approve or reject. His approval of the *picks* does not approve a generated banner.",
            "**Claude:** double-checks every installed batch (`verify`), marks it `verified`, and rebuilds this page. Only Claude marks a row `verified`."]),
    ("Rules that never bend", None),
    ("ol", ["Never change, rename or delete anything in `Media/artwork`. Originals stay untouched. Karl will rename files himself.",
            "Never install a banner Karl has not approved. Do not infer approval from a filename or an earlier approval.",
            "Skip every row marked **Skipped (low-res)** or **Blocked**. Do not generate, upscale or install from them. Karl is finding larger files; when he does, `swap` brings the row back.",
            "Use the picked file. Do not swap in the alternate or another image. If the picture contradicts the slot (wrong race, sex, class or set), stop: set the row `blocked` with a note and tell Karl.",
            "Rows marked *inferred* were guessed from the file name. Check the picture matches before you start the row.",
            "Never invent artist credits. Remove visible watermarks and signatures from the banner; keep credits on the goal as verified.",
            "Touch only the files a batch needs. Stage only your own hunks, keep LF line endings, and commit one batch at a time. Claude and Codex share this tree.",
            "Do not edit this plan's slots or order. Progress goes through `tools/art-plan.py` only."]),
    ("The batch loop (8 images per batch)", None),
    ("p", "Work in batch order. `python tools/art-plan.py batch` prints the next one. Do all 8, then ask Karl to review. While he reviews you may generate the next batch, "
          "but install only what he has approved. A batch is finished when its rows are `verified`."),
    ("ol", ["**Prepare.** For each row open the picked file, confirm it matches the slot, and read its targets (goal, race, class, sex and a suggested key; keep the key unless a nearby banner in `Core.lua` follows a different pattern). A TCG card scan needs the artwork cropped out of the frame first; keep nothing of the frame, text or numbers.",
            "**Generate** one review image per row with the banner skill (`.agents/skills/forever-goal-tracker-banners/SKILL.md`): 4:3, 1200 x 900, strictly black and white, left gradient and bottom gradient baked in, subject high and right, no text or border. Save it as `Media/final-images/<key>-review-<date>-v1.png`.",
            "**Pre-check** each review image: `python tools/art-plan.py check-master <file>`. It fails a wrong size, any color, or a missing left or bottom gradient. Fix those before Karl sees them.",
            "**Record.** Source, output and exact prompt for every image go in `reports/image-tests/<batch>-<date>.md`.",
            "**Show Karl** the sheet: `python tools/art-plan.py sheet <batch>`, then `python tools/art-plan.py set <ids> review`. Wait for his answer per image.",
            "**Install the approved ones** (see the next section), then `set <ids> approved` and `set <ids> installed --banner <key>`.",
            "**Rejected:** `set <id> rejected --note \"his reason\"`, regenerate once, show again. Rejected twice means `blocked` and ask Karl.",
            "**Commit** the batch, then message Claude to verify. One line in `reports/CURRENT.md` per batch."]),
    ("Installing one approved banner", None),
    ("ol", ["Copy the approved review image to the master path and add the key to `FINAL_BANNERS` in `tools/artwork.py` (same naming as the neighbors).",
            "`python tools/artwork.py --final-only` writes the 512 px DXT1 BLP with 10 mips and the runtime manifest entry.",
            "Register the path in `Core.lua`, 4:3 and `preprocessed=true`. **Item goals:** `B.artVariants.<goal> = {{path=..., aspect=4/3, preprocessed=true}}`. **Level Classes to 60:** a new entry in the `allclasses` list with `faction`, `class`, `race` and `sex` (`sex=2` male, `sex=3` female). **Tier, Dungeon and PvP sets:** a new entry on that set's variants with `faction`, `race` and `sex`; keep the existing entries. Equal weights tie to the first entry, so a replacement goes before the old one.",
            "One image used for two slots (a Warrior and Paladin file, or Dungeon Set 1 and 2): one master and one BLP, registered for each slot.",
            "Add one assertion per new banner to `tools/banner-tests.lua` (`B:ResolveArt(goal, who)` returns the new path).",
            "Update the checklist (next section), then run `python tools/check.py` and `sh tools/sync-era.sh`."]),
    ("Updating the goal art checklist", None),
    ("p", "The checklist is the record of what is mapped where. For every installed banner follow the *Goal art checklist* section of `reports/reference/artwork.md`:"),
    ("ul", ["**Statuses:** edit the row in `GOALS` or `TABLES` (a goal with its own image is `done`, class and race art that could get a faction version is `share`), and put the banner key (without `-banner.blp`) in the note.",
            "**Level Classes to 60:** add the entry to `RC_ART` with `pic` (m, f or mf: who the picture shows) and `only` for a one-sex image. **Sets:** add the key to `SETPIC` (`m`, `f`, `mf` or `n`).",
            "**New goals** (the 15 Library goals from this week) already have rows; change `need` to `done` and replace the planned source with the banner key.",
            "**Found log:** one dated line in `FOUND` per banner. Update the header date and the *Find these first* list.",
            "**Thumbnails:** `python tools/art-checklist.py thumbs` rebuilds them from the banners, and also embeds the planned source images named in a note (`Planned:` or `Source image:`).",
            "Statuses must match the resolver in `Core.lua`, not the file names. Do not install or rename anything while editing the checklist."]),
    ("Done means verified", None),
    ("p", "`python tools/art-plan.py verify <ids>` must pass for each item: the BLP (512 x 512 DXT1, 10 mips), the master (1200 x 900, neutral, both gradients), the manifest, the `Core.lua` path, "
          "the **resolver returning the new banner for the slot's race, class, faction and sex**, the checklist thumbnail and entries, and a record. Then `python tools/check.py` must pass. Claude runs both and marks the row `verified`."),
    ("Stop and ask Karl when", None),
    ("ul", ["The picture does not match its slot, or a row says inferred and you are unsure.",
            "A target has no goal id or the resolver cannot express the slot.",
            "Two sources want one slot, or a replacement would change art Karl already approved.",
            "A test or `verify` fails twice for the same reason.",
            "You are behind schedule: stop starting new priorities and tell Karl what is left."]),
    ("Pace", None),
    ("p", "Karl's review is the limit, not generation. Past sessions installed 5 to 8 banners at a time, so 8 per batch matches that. The plan has {queued} workable banners; "
          "P1 is {p1}, P2 is {p2}, P3 is {p3}. Finishing all of P1 and P2 by Nov 4 needs about {perday} installed per day. If review or generation runs slower, P1 first, then P2, and "
          "leave P3 for 2.16.1."),
    ("p", "**Open decision for Karl:** clean paintings (not card scans, 700 px or more) could get a deterministic crop, grayscale and baked gradients instead of an imagegen edit, which is faster and cannot change the art. "
          "{clean} workable images qualify. Default: use imagegen as the skill says; switch only if Karl approves that approach on a pilot batch."),
]


def sections_md(plan, status):
    from collections import Counter
    q = [r for r in plan["rows"] if state_of(r, status) not in ("skipped_lowres", "blocked")]
    p = Counter(r["priority"] for r in q)
    clean = sum(1 for r in q if not r["card"] and min(r["w"], r["h"]) >= 700)
    fmt = dict(queued=len(q), p1=p[1], p2=p[2], p3=p[3], perday=round((p[1] + p[2]) / 5), clean=clean)
    out = []
    for kind, val in WORK_ORDER:
        if kind == "Goal" or val is None:
            out.append(("h3", kind))
        elif kind == "p":
            out.append(("p", val.format(**fmt) if "{" in val else val))
        else:
            out.append((kind, val))
    return out


def md_inline(s):
    s = html.escape(s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", s)
    s = re.sub(r"\*(.+?)\*", r"<i>\1</i>", s)
    s = re.sub(r"`(.+?)`", r"<code>\1</code>", s)
    s = re.sub(r"\[(.+?)\]\((.+?)\)", r"<a href='\2'>\1</a>", s)
    return s


def thumb(f, cache={}):
    if f in cache:
        return cache[f]
    try:
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = None
        with Image.open(ART / f) as im:
            im = im.convert("RGB")
            im.thumbnail((170, 128))
            b = io.BytesIO()
            im.save(b, "JPEG", quality=68)
            cache[f] = "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()
    except Exception:
        cache[f] = ""
    return cache[f]


def build():
    plan, status = load()
    rows = plan["rows"]
    from collections import Counter
    counts = Counter(state_of(r, status) for r in rows)
    work = [r for r in rows if state_of(r, status) not in ("skipped_lowres", "blocked")]
    verified = sum(1 for r in work if state_of(r, status) == "verified")
    today = date.today().isoformat()
    sec = sections_md(plan, status)

    # ---------- markdown
    md = [f"# Art matching plan and work order, built {today}", "",
          "Locked by Karl on 2026-10-29 (commit 5abd851). Companion to [Goal-art-checklist.html](Goal-art-checklist.html), which stays the record of what is mapped where. "
          "This page is the work queue: open the `.html` copy for thumbnails. Rebuild with `python tools/art-plan.py build`.", "",
          f"**Progress: {verified} of {len(work)} workable banners verified.** "
          + ", ".join(f"{LABEL[s]} {counts[s]}" for s in STATES + SIDE if counts[s]) + f". {len(plan['gaps'])} slots have no source image.", "",
          "## Codex: start here", ""]
    for kind, val in sec:
        if kind == "h3":
            md += [f"### {val}", ""]
        elif kind == "p":
            md += [val, ""]
        elif kind == "ul":
            md += [f"- {x}" for x in val] + [""]
        else:
            md += [f"{i}. {x}" for i, x in enumerate(val, 1)] + [""]
    md += ["## Work queue", "", "State: ☐ not verified, ☑ verified. Batches are in order; rows keep their id for good (`A001`...).", ""]
    for b in sorted({r["batch"] for r in rows if r["batch"]}):
        md += [f"### Batch {b}", "", "| | Id | Pri | Source image | Alt | Targets (goal, key) | State | Notes |", "|---|---|---|---|---|---|---|---|"]
        for r in [r for r in rows if r["batch"] == b]:
            s = state_of(r, status)
            tg = "<br>".join(f"{t['label']}: `{t.get('goal')}` / `{t['key']}`" for t in r["targets"])
            fl = ", ".join(x for x in (("Karl's pick" if r["karl"] else ""), ("inferred" if r.get("inferred") else ""), ("card scan, crop first" if r["card"] else "")) if x)
            md.append(f"| {'☑' if s == 'verified' else '☐'} | {r['id']} | P{r['priority']} | `{r['file']}` {r['w']}x{r['h']} | {('`' + r['alt'] + '`') if r['alt'] else ''} | {tg} | {LABEL[s]} | {fl} {r['notes']} |")
        md.append("")
    skipped = [r for r in rows if state_of(r, status) in ("skipped_lowres", "blocked")]
    md += ["## Skipped or blocked (Codex: do not touch)", "", "Karl: find a larger copy of each low-res file, then `python tools/art-plan.py swap <id> <newfile>`.", "",
           "| Id | State | Source image | Size | Slots |", "|---|---|---|---|---|"]
    for r in skipped:
        md.append(f"| {r['id']} | {LABEL[state_of(r, status)]} | `{r['file']}` | {r['w']}x{r['h']} | {'; '.join(t['label'] for t in r['targets'])} {r['notes']} |")
    md += ["", "## Slots with no source image", "", "No picture in the folder fits these. They need new art or a source from Karl; nothing to do for Codex.", ""]
    md += [f"- {g['id']}: {g['slot']}" for g in plan["gaps"]] + [""]
    md += ["## Corrections from Karl's review", ""] + [f"- `{c['file']}`: {c['why']}" for c in plan["corrections"]] + [""]
    md += ["## Source files that still need the naming convention", "", "Not renamed. Karl renames these himself.", "", "| Now | Proposed |", "|---|---|"]
    md += [f"| `{k}` | `{v}` |" for k, v in plan["renames"].items()] + [""]
    st = plan["stage"]
    md += ["## Idea: leveling art that follows the character's level", "",
           f"Karl's idea: the Level Classes to 60 banner shows the character in three looks (levels 1 to 20, 21 to 40, 41 to 60). Not started. Of {st['tot']} race, class and sex slots, "
           f"the folder has art for stage 1 on {st['cov'][0]}, stage 2 on {st['cov'][1]}, stage 3 on {st['cov'][2]}, and all three on {len(st['full'])}. "
           "The resolver change is small (a `stage` field scored below faction); the cost is the art and about 30 to 59 MB of banners. Decide after Nov 4.", ""]
    MD.write_text("\n".join(md), encoding="utf-8", newline="\n")

    # ---------- html
    H = ["<!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Art matching plan and work order</title><style>"
         ":root{--bg:#f6f4ef;--card:#fff;--text:#23211c;--muted:#6b665c;--line:#e2ddd0;--ok:#3a9d5d;--warn:#b8860b;--bad:#c0392b;--info:#3b7dd8}"
         "@media (prefers-color-scheme:dark){:root{--bg:#17160f;--card:#211f17;--text:#eee9da;--muted:#a39d8b;--line:#38342a;--ok:#62c585;--warn:#e0b64a;--bad:#ef7070;--info:#6fa5ee}}"
         "body{margin:0;background:var(--bg);color:var(--text);font:15px/1.5 system-ui,-apple-system,'Segoe UI',sans-serif}main{max-width:1150px;margin:0 auto;padding:22px 16px 70px}"
         "h1{margin:0 0 6px}h2{margin:36px 0 8px;border-bottom:2px solid var(--line);padding-bottom:4px}h3{margin:20px 0 6px}p,li{max-width:84ch}.sub{color:var(--muted)}"
         "code{background:rgba(127,127,127,.15);padding:1px 5px;border-radius:4px;font-size:.9em}"
         ".start{background:var(--card);border:1px solid var(--line);border-left:6px solid var(--info);border-radius:8px;padding:6px 20px 14px;margin:14px 0}"
         ".bar{height:14px;background:var(--line);border-radius:7px;overflow:hidden;margin:6px 0}.bar>i{display:block;height:100%;background:var(--ok)}"
         ".sum{display:flex;gap:10px;flex-wrap:wrap;margin:8px 0}.sum div{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:6px 12px}.sum b{font-size:1.2rem;display:block}"
         "table{border-collapse:collapse;width:100%;margin:8px 0}td,th{border-bottom:1px solid var(--line);padding:6px 8px;vertical-align:top;text-align:left}th{font-size:.82rem;color:var(--muted)}"
         "td.i{width:190px}img{display:block;max-width:170px;max-height:128px;border-radius:4px;background:#000}.fn{font-size:.78rem;color:var(--muted);word-break:break-all}"
         ".st{display:inline-block;border-radius:999px;padding:1px 9px;font-size:.78rem;font-weight:600;border:1px solid var(--line)}"
         ".st.verified{background:var(--ok);color:#fff;border-color:var(--ok)}.st.installed,.st.approved{color:var(--ok);border-color:var(--ok)}.st.review{color:var(--info);border-color:var(--info)}"
         ".st.rejected,.st.blocked{color:var(--bad);border-color:var(--bad)}.st.skipped_lowres{color:var(--warn);border-color:var(--warn)}"
         "tr.skip{background:rgba(192,57,43,.10)}.f{font-size:.82rem;color:var(--muted)}.tg{font-size:.85rem}"
         "</style></head><body><main>"]
    H.append(f"<h1>Art matching plan and work order</h1><p class='sub'>Built {today}. Locked by Karl on 2026-10-29 (commit 5abd851). Companion to "
             "<a href='Goal-art-checklist.html'>Goal-art-checklist.html</a>, which stays the record of what is mapped where. Rebuild with <code>python tools/art-plan.py build</code>.</p>")
    pct = round(100 * verified / max(len(work), 1))
    H.append(f"<div class='sum'><div><b>{verified}/{len(work)}</b>verified</div>" + "".join(f"<div><b>{counts[s]}</b>{LABEL[s]}</div>" for s in STATES[:-1] + SIDE if counts[s]) +
             f"<div><b>{len(plan['gaps'])}</b>no source image</div></div><div class='bar'><i style='width:{pct}%'></i></div>")
    for pr in (1, 2, 3, 4):
        rs = [r for r in work if r["priority"] == pr]
        if rs:
            v = sum(1 for r in rs if state_of(r, status) == "verified")
            H.append(f"<div class='f'>{PRI[pr]}: {v} of {len(rs)} verified</div>")
    H.append("<h2>Codex: start here</h2><div class='start'>")
    for kind, val in sec:
        if kind == "h3":
            H.append(f"<h3>{html.escape(val)}</h3>")
        elif kind == "p":
            H.append(f"<p>{md_inline(val)}</p>")
        elif kind == "ul":
            H.append("<ul>" + "".join(f"<li>{md_inline(x)}</li>" for x in val) + "</ul>")
        else:
            H.append("<ol>" + "".join(f"<li>{md_inline(x)}</li>" for x in val) + "</ol>")
    H.append("</div><h2>Work queue</h2><p class='sub'>☑ means verified by Claude. Batches go in order. A row keeps its id for good.</p>")
    for b in sorted({r["batch"] for r in rows if r["batch"]}):
        H.append(f"<h3 id='batch{b}'>Batch {b}</h3><table><thead><tr><th></th><th>Id</th><th>Source image</th><th>Targets (goal / key)</th><th>State</th><th>Notes</th></tr></thead><tbody>")
        for r in [r for r in rows if r["batch"] == b]:
            s = state_of(r, status)
            tg = "".join(f"<div class='tg'>{html.escape(t['label'])}<div class='f'><code>{html.escape(str(t.get('goal')))}</code> / <code>{html.escape(t['key'] or '')}</code></div></div>" for t in r["targets"])
            fl = ", ".join(x for x in (("Karl's pick" if r["karl"] else ""), ("inferred: check the picture matches" if r.get("inferred") else ""), ("card scan: crop the art out of the frame" if r["card"] else "")) if x)
            alt = f"<div class='f'>alt: {html.escape(r['alt'])}</div>" if r["alt"] else ""
            H.append(f"<tr><td>{'☑' if s == 'verified' else '☐'}</td><td><b>{r['id']}</b><div class='f'>P{r['priority']}</div></td><td class='i'>"
                     f"{('<img src=\"' + thumb(r['file']) + '\" alt=\"\">') if thumb(r['file']) else ''}<div class='fn'>{html.escape(r['file'])} ({r['w']}x{r['h']})</div>{alt}</td>"
                     f"<td>{tg}</td><td><span class='st {s}'>{LABEL[s]}</span></td><td class='f'>{html.escape(fl)} {html.escape(r['notes'])}</td></tr>")
        H.append("</tbody></table>")
    H.append("<h2>Skipped or blocked: Codex, do not touch</h2><p class='sub'>Karl: find a larger copy of each low-res file, then <code>python tools/art-plan.py swap &lt;id&gt; &lt;newfile&gt;</code>.</p>"
             "<table><thead><tr><th>Id</th><th>Source image</th><th>State</th><th>Slots</th></tr></thead><tbody>")
    for r in skipped:
        H.append(f"<tr class='skip'><td><b>{r['id']}</b></td><td class='i'>{('<img src=\"' + thumb(r['file']) + '\" alt=\"\">') if thumb(r['file']) else ''}<div class='fn'>{html.escape(r['file'])} ({r['w']}x{r['h']})</div></td>"
                 f"<td><span class='st {state_of(r, status)}'>{LABEL[state_of(r, status)]}</span></td><td class='f'>{html.escape('; '.join(t['label'] for t in r['targets']))} {html.escape(r['notes'])}</td></tr>")
    H.append("</tbody></table><h2>Slots with no source image</h2><p class='sub'>No picture in the folder fits these. They need new art or a source from Karl. Nothing for Codex.</p><ul>")
    H += [f"<li>{g['id']}: {html.escape(g['slot'])}</li>" for g in plan["gaps"]]
    H.append("</ul><h2>Corrections from Karl's review</h2><ul>" + "".join(f"<li><code>{html.escape(c['file'])}</code>: {html.escape(c['why'])}</li>" for c in plan["corrections"]) + "</ul>")
    H.append("<h2>Source files that still need the naming convention</h2><p class='sub'>Not renamed. Karl renames these himself.</p><table><tbody>" +
             "".join(f"<tr><td><code>{html.escape(k)}</code></td><td><code>{html.escape(v)}</code></td></tr>" for k, v in plan["renames"].items()) + "</tbody></table>")
    H.append(f"<h2>Idea: leveling art that follows the character's level</h2><p>Not started. Of {st['tot']} race, class and sex slots the folder has art for stage 1 on {st['cov'][0]}, stage 2 on {st['cov'][1]}, "
             f"stage 3 on {st['cov'][2]}, and all three on {len(st['full'])}. Decide after Nov 4.</p></main></body></html>")
    HTML.write_text("".join(H), encoding="utf-8", newline="\n")
    print("wrote", MD.relative_to(root), f"({MD.stat().st_size} bytes) and", HTML.relative_to(root), f"({HTML.stat().st_size} bytes)")
    return 0


def main():
    a = sys.argv[1:]
    cmd = a[0] if a else ""
    rest = a[1:]
    fn = {"build": lambda: build(), "status": cmd_status, "batch": lambda: cmd_batch(rest), "set": lambda: cmd_set(rest), "swap": lambda: cmd_swap(rest),
          "sheet": lambda: cmd_sheet(rest), "check-master": lambda: cmd_check_master(rest), "verify": lambda: cmd_verify(rest)}.get(cmd)
    if not fn:
        print(__doc__)
        return 1
    return fn() or 0


if __name__ == "__main__":
    sys.exit(main())
