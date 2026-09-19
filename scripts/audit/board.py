import sys
from PIL import Image, ImageDraw, ImageFont
# usage: board.py OUT "TITLE" file1 "caption1" file2 "caption2" ...
out, title = sys.argv[1], sys.argv[2]; pairs = list(zip(sys.argv[3::2], sys.argv[4::2]))
H = 1300; ims = [Image.open(f).convert("RGB") for f, _ in pairs]
ims = [i.resize((int(i.width * H / i.height), H)) for i in ims]
pad = 40; capH = 200; W = sum(i.width for i in ims) + pad * (len(ims) + 1)
try:
    ft = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 54); fc = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 34)
except Exception:
    ft = fc = ImageFont.load_default()
S = Image.new("RGB", (W, H + capH + 140), (245, 245, 247)); d = ImageDraw.Draw(S)
d.text((pad, 40), title, font=ft, fill=(20, 20, 24)); x = pad
for (f, cap), im in zip(pairs, ims):
    S.paste(im, (x, 140)); y = 140 + H + 16
    words = cap.split(); line = ""
    for w in words:
        t = (line + " " + w).strip()
        if d.textlength(t, font=fc) > im.width: d.text((x, y), line, font=fc, fill=(30, 30, 36)); y += 42; line = w
        else: line = t
    d.text((x, y), line, font=fc, fill=(30, 30, 36)); x += im.width + pad
S.save(out, quality=85)
