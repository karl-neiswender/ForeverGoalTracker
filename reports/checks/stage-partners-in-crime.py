"""Stage this goal alone from a checkout containing concurrent goal work."""
from pathlib import Path
import subprocess
baseline = subprocess.check_output(['git', 'show', 'HEAD:Library.lua'])
local = Path('Library.lua').read_bytes()
eol = b'\r\n' if b'\r\n' in baseline else b'\n'
local = local.replace(b'\r\n', b'\n').replace(b'\n', eol)
start = b'    {' + eol + b'        -- Wowhead Forever item-set 2131'
anchor = b'    {' + eol + b'        -- Wowhead Forever item-set 2134'
assert local.count(start) == baseline.count(anchor) == 1
block = local[local.index(start):local.index(anchor)]
assert b'id = "set_partners_in_crime"' in block
updated = baseline.replace(anchor, block + anchor)
blob = subprocess.check_output(['git', 'hash-object', '-w', '--stdin'], input=updated).decode().strip()
mode = subprocess.check_output(['git', 'ls-tree', 'HEAD', 'Library.lua']).decode().split()[0]
subprocess.run(['git', 'update-index', '--cacheinfo', mode, blob, 'Library.lua'], check=True)
check = Path('reports/checks/partners-in-crime-2026-10-14.txt')
check.write_text(check.read_text(encoding='utf-8').rstrip() + '\n', encoding='utf-8', newline='\n')
