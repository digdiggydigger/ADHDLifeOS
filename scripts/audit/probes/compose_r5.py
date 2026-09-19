"""Round 5: Today's one card (round 3 'C') composited under the real Today header, above the real tab bar."""
import os
from PIL import Image, ImageDraw, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
REPO = "/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS/screenshots/adhd-ux-audit"
LEAF, OUT = f"{S}/r5-hero", f"{S}/r5-hero/composed"
os.makedirs(OUT, exist_ok=True)
K = 3
BASES = {  # frame, header bottom (pt)
    "L": (f"{REPO}/09-s-home-L-p1.jpg", 136),
    "D": (f"{REPO}/full/s-home-D-p1.jpg", 140),
    "A": (f"{REPO}/full/s-home-A-p1.jpg", 218),
}
tall = Image.open(f"{S}/today-L-tall.jpg").convert("RGB")
ROUTINE = tall.crop((0, 147 * K, 402 * K, 335 * K))


def compose(leaf_name, base_key, routine=False):
    path, hb = BASES[base_key]
    base = Image.open(path).convert("RGB")
    bg = base.getpixel((4 * K, 120 * K))
    disc = base.crop(((348 - 40) * K, (718 - 40) * K, (348 + 40) * K, (718 + 40) * K))
    mask = Image.new("L", disc.size, 0)
    ImageDraw.Draw(mask).ellipse((6 * K, 6 * K, 74 * K, 74 * K), fill=255)
    ImageDraw.Draw(base).rectangle((0, hb * K, 402 * K, 770 * K), fill=bg)
    leaf = Image.open(f"{LEAF}/{leaf_name}.png").convert("RGBA")
    base.paste(leaf, (0, hb * K), leaf)
    if routine:
        base.paste(ROUTINE, (0, (hb + 8) * K))
    # anything taller than the screen is cut by the tab bar, as on the phone
    base.paste(Image.open(path).convert("RGB").crop((0, 770 * K, 402 * K, 874 * K)), (0, 770 * K))
    ImageDraw.Draw(base).rectangle((0, 838 * K, 402 * K, 874 * K), fill=bg)
    base.paste(disc, ((348 - 40) * K, (718 - 40) * K), mask)
    base.save(f"{OUT}/{leaf_name}.jpg", quality=88)
    return base, leaf.height / K


def main():
    ft = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 44)
    fc = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 30)
    sc = 0.45
    cw, ch = round(402 * K * sc), round(874 * K * sc)
    pad, head, lab = 36, 120, 60
    rows = [
        ("Pinned task, light", [("body-H1-start-first-L", "L"), ("body-H2-equal-pair-L", "L"), ("body-H3-routine-model-L", "L")]),
        ("Pinned task, dark", [("body-H1-start-first-D", "D"), ("body-H2-equal-pair-D", "D"), ("body-H3-routine-model-D", "D")]),
        ("Pinned task, AX3", [("body-H1-start-first-A", "A"), ("body-H2-equal-pair-A", "A"), ("body-H3-routine-model-A", "A")]),
        ("The card's other states (H1 style)", [("state-suggested-L", "L"), ("state-resume-L", "L"), ("state-leaveBy-L", "L"), ("state-routineSlot-L", "L")]),
    ]
    titles = ["H1 · Start first, Close quiet", "H2 · Start + Close, equal", "H3 · Routine-screen model"]
    state_titles = ["Suggested (Pin · Not this one)", "Paused (Resume card)", "Leave by (calendar)", "At a place (live routine)"]
    W = pad + 4 * (cw + pad)
    H = head + len(rows) * (ch + lab + pad)
    B = Image.new("RGB", (W, H), (245, 245, 247))
    d = ImageDraw.Draw(B)
    d.text((pad, 30), "Round 5 · Today's ONE card (your round 3 'C'): real header + tab bar, card and list rendered with the real tokens", font=ft, fill=(20, 20, 24))
    y = head
    for r, (rtitle, cells) in enumerate(rows):
        d.text((pad, y), rtitle, font=fc, fill=(60, 60, 66))
        for c, (name, key) in enumerate(cells):
            im, h = compose(name, key, routine=name.startswith("state-routine"))
            x = pad + c * (cw + pad)
            t = (state_titles if r == 3 else titles)[c]
            d.text((x, y + 34), t, font=fc, fill=(20, 20, 24))
            B.paste(im.resize((cw, ch)), (x, y + lab + 20))
        y += ch + lab + pad + 20
    B.crop((0, 0, W, y)).save(f"{S}/59-ROUND-5-hero-options.jpg", quality=85)
    print((W, y))


if __name__ == "__main__":
    main()
