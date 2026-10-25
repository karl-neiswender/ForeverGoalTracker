"""Validate the approved weapon install with isolated Era/Forever states."""
import json, sys, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/"tools/.py/windows-runtime"))
from lupa import lua51
from PIL import Image, ImageChops
records=json.loads(Path(__file__).with_name("weapon-background-install-2026-10-25.json").read_text())
scope={"__file__":str(ROOT/"tools/check.py")}
exec((ROOT/"tools/check.py").read_text().split("\nok_all = True")[0],scope)
for forever in (False,True):
    assertions=[]
    for r in records:
        assertions.append('do local B=STUB_NS.goalBanner; local p,a,b=B:ResolveArt("'+r["id"]+'"); assert(p=="'+r["id"]+'-banner.blp" and a==4/3 and b, "'+r["id"]+' resolver: "..tostring(p).." "..tostring(a).." "..tostring(b)); end')
    scope["session"](None,after_login=" ".join(assertions),forever=forever)
    print("Verified 20 goal resolvers:", "Forever" if forever else "Era")
for r in records:
    with Image.open(ROOT/"Media/final-images/weapons"/(r["slug"]+"-master.png")) as im:
        assert im.size==(1200,900)
        rr,gg,bb=im.split()
        assert not ImageChops.difference(rr,gg).getbbox()
        assert not ImageChops.difference(gg,bb).getbbox()
    p=ROOT/"Media"/(r["id"]+"-banner.blp")
    data=p.read_bytes()
    magic,kind,enc,alpha,aenc,mips,w,h=struct.unpack("<4sI4BII",data[:20])
    assert (magic,enc,alpha,aenc,mips,w,h)==(b"BLP2",2,0,0,1,512,512)
    sizes=struct.unpack("<16I",data[84:148])
    assert sum(n>0 for n in sizes)==10
print("Verified 20 neutral 1200x900 masters and DXT1 BLPs with 10 mip levels")
