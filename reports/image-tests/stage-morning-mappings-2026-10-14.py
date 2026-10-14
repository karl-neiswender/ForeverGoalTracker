"""Stage only the approved banner mappings, preserving concurrent Core edits."""
import subprocess
data = subprocess.check_output(['git', 'show', 'HEAD:Core.lua'])
eol = b'\r\n' if b'\r\n' in data else b'\n'
anchor = b'    B.artPaths.social_cheers = "social_cheers-banner.blp"' + eol
addition = eol.join([
    b'    B.artPaths.social_waves = "social_waves-banner.blp"',
    b'    B.artPaths.social_guild = "social_guild-banner.blp"',
    b'    B.artAspects.social_waves, B.preprocessed.social_waves = 4/3, true',
    b'    B.artAspects.social_guild, B.preprocessed.social_guild = 4/3, true',
]) + eol
assert data.count(anchor) == 1
data = data.replace(anchor, anchor + addition)
for line in [
    b'        ["raid_naxx-banner.blp"] = "Mike Sutfin",',
    b'        ["prof_blacksmithing-banner.blp"] = "Akkapoj T.",',
    b'        ["rep_nozdormu-banner.blp"] = "Zoltan Boros",',
]:
    assert data.count(line + eol) == 1
    data = data.replace(line + eol, b'')
blob = subprocess.check_output(['git', 'hash-object', '-w', '--stdin'], input=data).decode().strip()
subprocess.run(['git', 'update-index', '--cacheinfo', '100644', blob, 'Core.lua'], check=True)
