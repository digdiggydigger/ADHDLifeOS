import json, subprocess, sys, time
U="02AE86FA-CE2F-4468-90D6-2B8708910993"
key=sys.argv[1]; by_label="--label" in sys.argv
raw=subprocess.run(["idb","ui","describe-all","--udid",U,"--json"],capture_output=True,text=True).stdout
def walk(xs):
    for x in xs:
        yield x; yield from walk(x.get("children") or [])
for e in walk(json.loads(raw)):
    v=(e.get("AXLabel") if by_label else e.get("AXUniqueId")) or ""
    f=e.get("frame") or {}
    if v==key and 0<=f.get("y",-1)<874:
        x=f["x"]+f["width"]/2; y=f["y"]+f["height"]/2
        subprocess.run(["idb","ui","tap","--udid",U,str(round(x)),str(round(y))]); time.sleep(1.4)
        print("tapped",key,round(x),round(y)); break
else: print("NOT FOUND",key)
