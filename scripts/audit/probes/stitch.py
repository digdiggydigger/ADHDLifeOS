import json, subprocess, sys, time
from PIL import Image
U="02AE86FA-CE2F-4468-90D6-2B8708910993"; S=sys.argv[1]; name=sys.argv[2]; K=3
def ax():
    raw=subprocess.run(["idb","ui","describe-all","--udid",U,"--json"],capture_output=True,text=True).stdout
    out=[]
    def walk(xs):
        for x in xs:
            out.append(x); walk(x.get("children") or [])
    walk(json.loads(raw)); return out
def ref_y(els):
    for e in els:
        if e.get("AXUniqueId")=="homeTitle": return e["frame"]["y"]
base=ax(); y0=ref_y(base)
json.dump([{"id":e.get("AXUniqueId"),"label":(e.get("AXLabel") or "")[:60],"f":e.get("frame")} for e in base], open(f"{S}/{name}-ax.json","w"))
tall=Image.new("RGB",(402*K,4200*K),(255,0,255)); maxy=0
for step in range(12):
    subprocess.run(["xcrun","simctl","io",U,"screenshot","--type=png",f"{S}/frames/st.png"],capture_output=True)
    off=y0-ref_y(ax())
    im=Image.open(f"{S}/frames/st.png").convert("RGB")
    top=62 if step else 0
    zone=im.crop((0,top*K,402*K,600*K)); tall.paste(zone,(0,int(round((top+off)*K))))
    maxy=max(maxy,600+off); print("step",step,"offset",round(off,1))
    subprocess.run(["idb","ui","swipe","--udid",U,"--duration","2.0","200","560","200","200"],capture_output=True); time.sleep(1.5)
    if step and abs(off-prev)<5: break
    prev=off
tall.crop((0,0,402*K,int(maxy*K))).save(f"{S}/{name}-tall.jpg",quality=90); print("height",maxy)
