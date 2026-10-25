"""Keep Media/artwork/INDEX.csv in step with the files in Media/artwork.

  python3 tools/artwork-index.py          create or update the index, then print what changed

One row per file directly in Media/artwork (subfolders are left out). Columns:
  file           the current name, in the convention reports/reference/artwork.md describes
  fits           the empty banner slot this could fill, free text (for example "leveling horde-priest")
  status         blank = not looked at yet, then candidate, used or rejected
  original_name  the name the file arrived with; filled in once and never changed
  sha1           the file's content, so a rename is recognised and the original name carries over

Rename files however you like, then run this. A row whose file is gone is matched to an
unlisted file with the same content; its fits, status and original_name move to the new name.
Files that match nothing get a new row. Rows left without a file are reported, not deleted.
Run from the repository root. Originals are only ever read.
"""
import csv
import hashlib
from pathlib import Path

root = Path(__file__).resolve().parent.parent
art = root / 'Media' / 'artwork'
index = art / 'INDEX.csv'
COLUMNS = ['file', 'fits', 'status', 'original_name', 'sha1']


def digest(path):
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def main():
    rows = []
    if index.exists():
        with open(index, newline='', encoding='utf-8') as f:
            rows = [{c: r.get(c, '') for c in COLUMNS} for r in csv.DictReader(f)]
    files = sorted(p.name for p in art.iterdir() if p.is_file() and p.name != index.name)
    listed = {r['file'] for r in rows}
    hashes = {name: digest(art / name) for name in files}
    for r in rows:
        if r['file'] in hashes and not r['sha1']:
            r['sha1'] = hashes[r['file']]
    unlisted = [n for n in files if n not in listed]
    renamed, added = 0, []
    for name in unlisted:
        # a row whose file has gone and whose content matches: this is a rename
        match = next((r for r in rows if r['file'] not in hashes and r['sha1'] == hashes[name]), None)
        if match:
            match['file'] = name
            renamed += 1
        else:
            rows.append({'file': name, 'fits': '', 'status': '', 'original_name': name, 'sha1': hashes[name]})
            added.append(name)
    missing = [r['file'] for r in rows if r['file'] not in hashes]
    rows.sort(key=lambda r: r['file'].lower())
    with open(index, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator='\n')
        w.writeheader()
        w.writerows(rows)
    print(f'{len(rows)} rows: {renamed} renamed, {len(added)} new, {len(missing)} without a file')
    for name in missing:
        print('  no file for:', name)


if __name__ == '__main__':
    main()
