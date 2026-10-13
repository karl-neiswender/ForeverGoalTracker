"""Language consistency check for every player-facing string.

    python tools/copycheck.py            # report: enforced rules and proposed rules
    python tools/copycheck.py --strict   # exit 1 when an enforced rule is broken

check.py runs the enforced rules on every check, so a new tip, step or tooltip
that breaks a convention fails the suite. Proposed rules are conventions waiting
for Karl's yes; they are reported, never enforced. The conventions themselves are
written up in reports/copy-sweep/conventions.md.

A rule gets one string at a time: {where, field, text, client}. Item, quest and
NPC link tags ({item:ID:Name}) are reduced to their shown names first, and the
colour codes are removed, so a rule reads what the player reads.
"""
import os
import re
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import textdump  # noqa: E402  (loads the addon against the stub, as check.py does)


def plain(text):
    text = re.sub(r"\{item:\d+:([^}]*)\}", r"\1", text)
    text = re.sub(r"\{[\w]+:([^}]*)\}", r"\1", text)
    return re.sub(r"\|c\w{8}|\|r", "", text)


SKILLS = "Alchemy|Blacksmithing|Enchanting|Engineering|Herbalism|Leatherworking|Mining|Skinning|Tailoring"
STANDINGS = "Friendly|Honored|Revered|Exalted"


def rule(id_, status, why):
    def wrap(fn):
        fn.id, fn.status, fn.why = id_, status, why
        return fn
    return wrap


# ---- enforced: mechanical rules Karl already follows -----------------------

@rule("no-dashes", "enforced", "No em or en dashes, and no spaced hyphen standing in for one in prose.")
def no_dashes(rec, t):
    # (a section name like "Warrior - Dreadnaught's Battlegear" is a structural separator the code reads)
    if rec["field"] == "ui" or re.fullmatch(r"section \d+", rec["field"]):
        return None
    if re.search("[—–]|\\s--\\s|\\s-\\s", t):
        return "dash used as punctuation"


@rule("no-double-space", "enforced", "One space between words (a colour-coded tag after a name is the one exception).")
def no_double_space(rec, t):
    if re.search(r"\S  \S", rec["text"]) and not re.search(r"  \|c\w{8}Source unknown", rec["text"]):
        return "double space"


@rule("straight-quotes", "enforced", "Straight quotes and apostrophes only (the font has no curly ones).")
def straight_quotes(rec, t):
    if re.search("[‘’“”]", t):
        return "curly quote"


@rule("standings", "enforced", "Reputation standings are capitalized: Friendly, Honored, Revered, Exalted.")
def standings(rec, t):
    m = re.search(r"\b(" + STANDINGS.lower() + r")\b", t)
    if m and not re.search(r"(?i)\bhonored (guest|member)", t):
        return "lowercase standing: " + m.group(1)


@rule("skill-names", "enforced", "Profession and skill names are capitalized (Riding, Leatherworking, First Aid).")
def skill_names(rec, t):
    m = re.search(r"\b(" + SKILLS.lower() + r")\b", t)
    if m:
        return "lowercase profession: " + m.group(1)
    m = re.search(r"(?i)\b(swift|journeyman|apprentice|expert|artisan|train|learn) riding\b", t)
    if m and m.group(0).split(" ")[-1] == "riding":
        return "lowercase skill: " + m.group(0)


@rule("click-hints", "enforced", "Click hints read Shift-click, Right-click, Ctrl-click, Left-click (hyphen, one capital).")
def click_hints(rec, t):
    m = re.search(r"\b(?:shift|right|ctrl|left)[ -]click\b|\b(?:Shift|Right|Ctrl|Left)[ ]click\b|\b(?:SHIFT|RIGHT)-CLICK", t)
    if m:
        return "click hint: " + m.group(0)


@rule("turn-in", "enforced", "'Turn in' is the verb, 'turn-in' the noun.")
def turn_in(rec, t):
    m = re.search(r"(?i)\b(to|will|then|please|and|can|must) turn-in\b|\bturn in (quests?|npcs?|items?)\b", t)
    if m:
        return "turn in / turn-in: " + m.group(0)


@rule("step-shape", "enforced", "A step starts with a capital and ends with a period; a tip ends with a period.")
def step_shape(rec, t):
    f = rec["field"]
    if "Source unknown" in t or (f.startswith("step ") and len(t.split()) <= 2):
        return None  # a part name (a class, a race) or a piece waiting on its source, not a sentence
    if (f.startswith("step ") and not f.endswith(" name")) or " tip " in f or f.startswith("tip "):
        if t and not t[0].isupper() and t[0] not in "'\"(0123456789":
            return "does not start with a capital"
        if not t.rstrip().endswith((".", "!", "?")) and not re.search(r"\)$", t):
            return "does not end with a period"


@rule("level-60", "enforced", "'level 60' is lowercase mid-sentence.")
def level_60(rec, t):
    if re.search(r"[a-z,;] Level \d", t):
        return "Level 60 capitalized mid-sentence"


# ---- proposed: need Karl's yes before they are enforced --------------------

@rule("client-names", "proposed",
      "Name the client 'Classic Era' (not 'Classic') and the other client 'Forever' in short copy.")
def client_names(rec, t):
    if re.search(r"\bClassic\b(?! Era)", t):
        return "bare 'Classic'"
    if re.search(r"\bWoW Forever\b", t):
        return "'WoW Forever' (short copy says 'Forever')"


@rule("gold-spelled", "proposed", "Write 'gold' in full in prose ('1,200 gold'), not '1,200g'.")
def gold_spelled(rec, t):
    m = re.search(r"~?\b\d[\d,]*g\b", t)
    if m:
        return "gold shorthand: " + m.group(0)


@rule("hint-colon", "proposed", "Hints read 'Shift-click: link in chat': lowercase after the colon, except names (Wowhead).")
def hint_colon(rec, t):
    m = re.search(r"-click: ([A-Z][a-z]+)\b", t)
    if m and m.group(1) not in ("Wowhead", "TomTom"):
        return "capital after the colon: " + m.group(0)


@rule("ui-sentence-case", "proposed",
      "Buttons, headings and hints use sentence case; only named things stay capitalized (My Goals, Goal Library, Wowhead, Forever).")
def ui_sentence_case(rec, t):
    if rec["field"] != "ui":
        return None
    words = re.findall(r"[A-Za-z']+", t)
    if re.search(r"[.:!?]\s", t) or t.endswith("."):
        return None  # sentences and "Label: text" hints are judged by the other rules
    if len(words) >= 3 and words[0][0].isupper():
        small = {"of", "the", "to", "a", "an", "and", "in", "for", "from", "with", "by", "on", "at", "or"}
        caps = [w for w in words[1:] if w[0].isupper() and w.lower() not in small]
        named = {"My", "Goals", "Goal", "Library", "Wowhead", "Forever", "Classic", "Era", "Alliance", "Horde", "TomTom"}
        stray = [w for w in caps if w not in named]
        if stray:
            return "Title Case: " + ", ".join(stray)


RULES = [no_dashes, no_double_space, straight_quotes, standings, skill_names, click_hints, turn_in, step_shape,
         level_60, client_names, gold_spelled, hint_colon, ui_sentence_case]


def run(records=None):
    """Returns { rule id: [(where, field, message, text)] }."""
    if records is None:
        seen, records = set(), []
        for forever in (False, True):
            for where, field, text in textdump.collect(forever):
                key = (where, field, text)
                if key not in seen:
                    seen.add(key)
                    records.append({"where": where, "field": field, "text": text, "client": "forever" if forever else "era"})
        for where, field, text in textdump.ui_strings():
            records.append({"where": where, "field": field, "text": text, "client": "both"})
    found = {r.id: [] for r in RULES}
    for rec in records:
        t = plain(rec["text"])
        for r in RULES:
            msg = r(rec, t)
            if msg:
                found[r.id].append((rec["where"], rec["field"], msg, t[:110]))
    return found


def main():
    strict = "--strict" in sys.argv
    found = run()
    bad = 0
    for r in RULES:
        hits = found[r.id]
        tag = "ENFORCED" if r.status == "enforced" else "proposed"
        print(f"{tag:9} {r.id}: {len(hits)} found. {r.why}")
        for where, field, msg, text in hits[:12]:
            print(f"            {where} / {field}: {msg}  |  {text}")
        if r.status == "enforced":
            bad += len(hits)
    if strict and bad:
        sys.exit(1)


if __name__ == "__main__":
    main()
