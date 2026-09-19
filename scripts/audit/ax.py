import json, subprocess, sys
U="02AE86FA-CE2F-4468-90D6-2B8708910993"
raw=subprocess.run(["idb","ui","describe-all","--udid",U,"--json"],capture_output=True,text=True).stdout
try: items=json.loads(raw)
except Exception: print("AX FAIL", raw[:300]); sys.exit()
def walk(xs):
    for x in xs:
        yield x
        yield from walk(x.get("children") or [])
only_small = "--small" in sys.argv
for e in walk(items):
    t=e.get("type"); f=e.get("frame") or {}
    if t in ("Application",): continue
    w,h=round(f.get("width",0)),round(f.get("height",0)); x,y=round(f.get("x",0)),round(f.get("y",0))
    if y+h<0 or y>874: vis="off"
    else: vis=""
    lab=(e.get("AXLabel") or "")[:70]; uid=e.get("AXUniqueId") or ""
    flag=""
    if t in ("Button","Link","TextField","SecureTextField","Switch","Slider","Cell"):
        if min(w,h)<44: flag="<44!"
        elif min(w,h)<48: flag="<48"
    if only_small and not flag: continue
    print(f"{t[:10]:10} {flag:5} {x:4},{y:5} {w:3}x{h:<4} {vis:3} {lab} [{uid}]")
