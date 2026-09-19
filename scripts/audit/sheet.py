import sys
from PIL import Image, ImageDraw
out=sys.argv[1]; files=sys.argv[2:]
ims=[Image.open(f).convert("RGB") for f in files]
h=1400; ims=[i.resize((int(i.width*h/i.height),h)) for i in ims]
W=sum(i.width for i in ims)+20*(len(ims)-1)
S=Image.new("RGB",(W,h+40),(128,128,128)); x=0
d=ImageDraw.Draw(S)
for f,i in zip(files,ims):
    S.paste(i,(x,40)); d.text((x+8,10),f.split('/')[-1][:-4],fill=(255,255,255)); x+=i.width+20
S.save(out,quality=80)
