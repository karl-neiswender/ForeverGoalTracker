r"""Finds invalid backslash escapes in the addon's Lua string literals.

Lua 5.1 accepts "\A" and "\M" without complaint and quietly drops the backslash, so a texture
path written "Interface\AddOns\\..." compiles, loads and then fails to find its file in game
(the Priest's rays vanished on every banner that way, 2026-10-13). Valid escapes are \\ \" \'
\a \b \f \n \r \t \v, a line break and decimal codes (\0 to \9).

Used by tools/check.py; run it alone with:  python tools/escapecheck.py
"""
import os
import re
import sys

FILES = ["Data.lua", "Library.lua", "AQArmor.lua", "ArmorSets.lua", "Npcs.lua", "Quests.lua",
         "Dependencies.lua", "Filters.lua", "Core.lua", "ItemTooltips.lua", "Materials.lua",
         "WhatsNew.lua", "Ambience.lua", "Audit.lua"]
VALID = "\\\"'abfnrtv0123456789"
LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"' + "|" + r"'((?:[^'\\\n]|\\.)*)'")


def run(root=None):
    root = root or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    found = []
    for name in FILES:
        path = os.path.join(root, name)
        if not os.path.exists(path):
            continue
        for number, line in enumerate(open(path, encoding="utf-8").read().splitlines(), 1):
            if line.lstrip().startswith("--"):
                continue
            for match in LITERAL.finditer(line):
                body = match.group(1) if match.group(1) is not None else match.group(2)
                for esc in re.finditer(r"\\(.)", body):
                    if esc.group(1) not in VALID:
                        found.append((name, number, esc.group(0), line.strip()[:100]))
                        break
    return found


if __name__ == "__main__":
    bad = run()
    for name, number, esc, text in bad:
        print("ESCAPE     %s:%d has %s in a string: %s" % (name, number, esc, text))
    print("%d invalid escapes" % len(bad))
    sys.exit(1 if bad else 0)
