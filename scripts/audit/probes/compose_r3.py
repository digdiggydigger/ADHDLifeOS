import sys
from PIL import Image, ImageDraw, ImageFont
S=sys.argv[1]; K=3
tall=Image.open(f"{S}/today-L-tall.jpg").convert("RGB")
SEC={"header":(0,147),"routine":(147,335),"ring":(335,498),"hero":(498,806),"areasHead":(806,862),
     "areasAll":(806,1368),"dueNow":(1368,1513),"nudges":(1513,1709),"inbox":(1709,2094),
     "closedToday":(2100,2272),"closedWeek":(2272,2397),"weekReview":(2397,2489),"focus":(2489,2865),"trend":(2865,3125)}
def strip(names):
    parts=[tall.crop((0,SEC[n][0]*K,402*K,SEC[n][1]*K)) for n in names]
    h=sum(p.height for p in parts); out=Image.new("RGB",(402*K,h),(242,243,247)); y=0
    for p in parts: out.paste(p,(0,y)); y+=p.height
    return out
cols=[("Today now · 12 sections",None,"3,125pt = 3.6 screens. 'Due now' starts 1,368pt down."),
      ("A · Now first, rest below",["header","routine","hero","dueNow","nudges","inbox","areasHead","weekReview"],"Keeps nudges + the inbox peek on Today. Ring, streak, charts, closed lists move into Week review. Areas collapse to one row."),
      ("B · Today is only 'now'",["header","routine","hero","dueNow","weekReview"],"Routine, hero, due now (+ a due nudge when one is due). Areas live in the Areas tab, the inbox in Captures, the week behind one Week review row."),
      ("C · One next thing",["header","routine","dueNow"],"ONE card, then a short 'then' list. At a place (as now, the Gym) the routine takes the slot; elsewhere the hero does.")]
imgs=[tall if n is None else strip(n) for _,n,_ in cols]
sc=1/3; cw=int(402); pad=50; head=230
H=int(max(i.height for i in imgs)*sc)+head+40; W=pad+len(cols)*(cw+pad)
B=Image.new("RGB",(W,H),(250,250,252)); d=ImageDraw.Draw(B)
ft=ImageFont.truetype("/System/Library/Fonts/SFNS.ttf",30); fc=ImageFont.truetype("/System/Library/Fonts/SFNS.ttf",19); fl=ImageFont.truetype("/System/Library/Fonts/SFNS.ttf",17)
d.text((pad,20),"Round 3 · Today — which sections stay? (real pixels from the sim, rearranged; one column = one scroll)",font=ft,fill=(20,20,24))
for c,((title,_,note),im) in enumerate(zip(cols,imgs)):
    x=pad+c*(cw+pad); d.text((x,80),title,font=ft,fill=(20,20,24))
    words=note.split(); line=""; y=122
    for w in words:
        t=(line+" "+w).strip()
        if d.textlength(t,font=fc)>cw: d.text((x,y),line,font=fc,fill=(70,70,78)); y+=24; line=w
        else: line=t
    d.text((x,y),line,font=fc,fill=(70,70,78))
    s=im.resize((cw,int(im.height*sc))); B.paste(s,(x,head)); d.rectangle((x,head,x+cw-1,head+s.height-1),outline=(200,200,208))
    yl=head+772
    d.text((x,head-26),f"{im.height//K:,}pt · {im.height/K/874:.1f} screens",font=fl,fill=(30,110,200))
    if s.height>772-5:
        for xx in range(x,x+cw,14): d.line((xx,yl,xx+7,yl),fill=(230,40,60),width=3)
        d.text((x+4,yl+4),"screen 1 ends (tab bar)",font=fl,fill=(230,40,60))
    else:
        d.text((x,head+s.height+8),"fits on one screen",font=fl,fill=(30,140,70))
B.save(f"{S}/55-ROUND-3-today-options.jpg",quality=88); print(B.size)
