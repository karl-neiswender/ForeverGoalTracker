"""Stage only Partners in Crime's art mapping, leaving concurrent Core edits."""
import subprocess
data = subprocess.check_output(['git', 'show', 'HEAD:Core.lua'])
eol = b'\r\n' if b'\r\n' in data else b'\n'
anchor = b'    B.artPaths.social_cheers = "social_cheers-banner.blp"' + eol
addition = eol.join([
    b'    B.artPaths.set_partners_in_crime = "set_partners_in_crime-banner.blp"',
    b'    B.artAspects.set_partners_in_crime, B.preprocessed.set_partners_in_crime = 4/3, true',
]) + eol
assert data.count(anchor) == 1
blob = subprocess.check_output(['git', 'hash-object', '-w', '--stdin'], input=data.replace(anchor, anchor + addition)).decode().strip()
mode = subprocess.check_output(['git', 'ls-tree', 'HEAD', 'Core.lua']).decode().split()[0]
subprocess.run(['git', 'update-index', '--cacheinfo', mode, blob, 'Core.lua'], check=True)
