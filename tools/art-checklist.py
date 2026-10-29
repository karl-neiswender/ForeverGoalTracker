"""Maintain reports/Goal-art-checklist.html.

  python3 tools/art-checklist.py thumbs   rebuild the embedded thumbnails from Media/*-banner.blp and from the
                                          planned source images named in notes (`Planned: file.png`)
  python3 tools/art-checklist.py goals    list goals in the addon that have no row in the checklist

Run from the repository root. Needs Pillow (thumbs) and lupa (goals).
"""
import base64, io, json, re, sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
page = root / 'reports' / 'Goal-art-checklist.html'


def referenced_keys(text):
    """Every banner name the page links: GOALS notes plus CLASSIMG."""
    keys = set()
    start = text.index('var GOALS = ') + len('var GOALS = ')
    goals = json.loads(text[start:text.index(';\n', start)])
    known = {p.name[:-len('-banner.blp')] for p in (root / 'Media').glob('*-banner.blp')}
    for _, rows in goals:
        for row in rows:
            for k in known:
                if re.search(r'(^|[^\w-])' + re.escape(k) + r'(?![\w-])', row[3]):
                    keys.add(k)
    start = text.index('var CLASSIMG = ') + len('var CLASSIMG = ')
    for table in json.loads(text[start:text.index(';\n', start)]).values():
        for pair in table.values():
            keys.update(pair[0] + pair[1])
    return keys, goals


def thumbs():
    from PIL import Image
    text = page.read_text(encoding='utf-8')
    keys, listed = referenced_keys(text)
    img, missing = {}, []
    for k in sorted(keys):
        src = root / 'Media' / (k + '-banner.blp')
        if not src.exists():
            missing.append(k)
            continue
        im = Image.open(src).convert('RGB').resize((320, 240), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, 'JPEG', quality=68, optimize=True)
        img[k] = 'data:image/jpeg;base64,' + base64.b64encode(buf.getvalue()).decode()
    # Planned source images (a note says `Planned: file.png` or `Source image: file.png`) get a thumbnail too,
    # on a 4:3 dark card so a portrait scan is not stretched by the preview.
    planned = set()
    for _, rows in listed:
        for row in rows:
            planned.update(m.group(1) for m in re.finditer(r'(?:Planned|Source image): ([^\s;,()]+\.(?:jpe?g|png|webp))', row[3]))
    for f in sorted(planned):
        src = root / 'Media/artwork' / f
        if not src.exists():
            missing.append(f)
            continue
        Image.MAX_IMAGE_PIXELS = None
        im = Image.open(src).convert('RGB')
        im.thumbnail((320, 240), Image.LANCZOS)
        card = Image.new('RGB', (320, 240), (20, 20, 20))
        card.paste(im, ((320 - im.width) // 2, (240 - im.height) // 2))
        buf = io.BytesIO()
        card.save(buf, 'JPEG', quality=68, optimize=True)
        img[Path(f).stem] = 'data:image/jpeg;base64,' + base64.b64encode(buf.getvalue()).decode()
    block = re.search(r'var IMG = \{.*?\};\n</script>', text, re.S)
    text = text.replace(block.group(0), 'var IMG = ' + json.dumps(img) + ';\n</script>')
    page.write_text(text, encoding='utf-8', newline='\n')
    print(len(img), 'thumbnails written;', 'no banner file for:', missing or 'none')


def goals():
    from lupa import lua51
    text = page.read_text(encoding='utf-8')
    _, listed = referenced_keys(text)
    names = {row[0] for _, rows in listed for row in rows}
    files = [x.strip() for x in (root / 'ForeverGoalTracker.toc').read_text().splitlines() if x.strip().endswith('.lua')]
    rt = lua51.LuaRuntime()
    rt.execute((root / 'tools/wowstub.lua').read_text())
    run = rt.eval('function(src,name,ns) assert(loadstring(src,"@"..name))("ForeverGoalTracker", ns) end')
    ns = rt.table()
    rt.globals().STUB_NS = ns
    for f in files:
        run((root / f).read_text(encoding='utf-8'), f, ns)
    rt.execute('STUB_FIRE("ADDON_LOADED", "ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN")')
    extra = []
    for _, g in ns.goals.items():
        if g.libraryOnly:
            continue
        child = g.libraryChild
        g.libraryChild = None
        visible = ns.LibraryVisible(g)
        g.libraryChild = child
        if visible and g.name not in names:
            extra.append((g.category, g.name))
    for cat, name in sorted(extra, key=lambda x: (str(x[0]), x[1])):
        print(f'{cat}: {name}')
    print(len(extra), 'goals have no row in the checklist (renamed goals show here too)')


if __name__ == '__main__':
    {'thumbs': thumbs, 'goals': goals}.get(sys.argv[1] if len(sys.argv) > 1 else '', lambda: print(__doc__))()
