"""annot.py NAME — screenshot the sim and box every control < 44pt (red) or < 48pt (orange), labelled WxH."""
import json, subprocess, sys
from PIL import Image, ImageDraw, ImageFont
U = "02AE86FA-CE2F-4468-90D6-2B8708910993"; S = sys.argv[0].rsplit("/", 1)[0]; name = sys.argv[1]; K = 3
ONLY = set(sys.argv[2].split("|")) if len(sys.argv) > 2 else None
subprocess.run(["xcrun", "simctl", "io", U, "screenshot", "--type=png", f"{S}/frames/{name}.png"], capture_output=True)
raw = subprocess.run(["idb", "ui", "describe-all", "--udid", U, "--json"], capture_output=True, text=True).stdout
els = []
def walk(xs):
    for x in xs:
        els.append(x); walk(x.get("children") or [])
walk(json.loads(raw))
im = Image.open(f"{S}/frames/{name}.png").convert("RGB"); d = ImageDraw.Draw(im)
ft = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 30)
found = []
for e in els:
    t = e.get("type") or e.get("role") or ""
    if t not in ("Button", "CheckBox", "Link", "PopUpButton", "Switch", "Slider", "TextField", "Toggle"):
        continue
    if (e.get("AXUniqueId") or "").startswith("tabBar."):
        continue
    if ONLY is not None and (e.get("AXLabel") or "") not in ONLY:
        continue
    f = e.get("frame") or {}
    w, h, x, y = f.get("width", 0), f.get("height", 0), f.get("x", 0), f.get("y", 0)
    if not (0 <= y < 874 and w > 0 and h > 0) or min(w, h) >= 48:
        continue
    col = (230, 30, 50) if min(w, h) < 44 else (240, 140, 0)
    d.rectangle((x * K, y * K, (x + w) * K, (y + h) * K), outline=col, width=6)
    label = f"{round(w)}×{round(h)}"
    tw = d.textlength(label, font=ft)
    d.rectangle((x * K, (y + h) * K, x * K + tw + 12, (y + h) * K + 38), fill=col)
    d.text((x * K + 6, (y + h) * K + 2), label, font=ft, fill=(255, 255, 255))
    found.append((label, (e.get("AXLabel") or "")[:30]))
im.save(f"{S}/frames/{name}-annot.jpg", quality=85)
print(name, len(found), found[:14])
