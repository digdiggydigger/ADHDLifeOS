"""Round 4c: six sprint controls on the card (composited on real sprint frames) + the focus screen."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageEnhance

S = os.path.dirname(os.path.abspath(__file__))
FR, LEAF, OUT = f"{S}/frames", f"{S}/r4-ctl", f"{S}/r4-ctl/composed"
os.makedirs(OUT, exist_ok=True)
K = 3
T = 772


def box(im, x0, y0, x1, y1):
    return im.crop((round(x0 * K), round(y0 * K), round(x1 * K), round(y1 * K)))


def fill(im, x0, y0, x1, y1, color):
    ImageDraw.Draw(im).rectangle((round(x0 * K), round(y0 * K), round(x1 * K) - 1, round(y1 * K) - 1), fill=color)


def card_on_frame(card_name, scheme):
    base = Image.open(f"{FR}/r2-sprint-{scheme}.jpg").convert("RGB")
    bg = base.getpixel((4 * K, 500 * K))
    leaf = Image.open(f"{LEAF}/{card_name}.png").convert("RGBA")
    h = leaf.height / K - 32
    disc = box(base, 306, 612, 390, 686)
    srow = box(base, 8, 622, 310, 680)
    card_top = 748 - h
    row_bottom = card_top - 8
    d = 680 - row_bottom
    fill(base, 0, 620 - d - 12, 402, T - 2, bg)
    base.paste(disc, (round(306 * K), round((612 - d) * K)))
    base.paste(srow, (round(8 * K), round((622 - d) * K)))
    base.paste(leaf, (0, round((card_top - 16) * K)), leaf)
    return base, h


def screen_on_frame(name, scheme):
    base = Image.open(f"{FR}/r2-sprint-{scheme}.jpg").convert("RGB")
    base = ImageEnhance.Brightness(base).enhance(0.55)
    leaf = Image.open(f"{LEAF}/{name}.png").convert("RGBA")
    base.paste(leaf, (0, round(62 * K)), leaf)
    return base


def main():
    ft = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 40)
    fc = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 28)
    cols = [("card-today", "Today (4 controls)"), ("card-V1-one-row", "V1 · six in one row"),
            ("card-V2-two-rows", "V2 · two rows"), ("card-V3-time-menu", "V3 · 'Add time' menu")]
    cw, y0, y1 = 603, 380, 874
    ch = round((y1 - y0) * K / 2)
    pad, head = 36, 150
    rows = 4
    W = pad + 4 * (cw + pad)
    H = head + 2 * (ch + 90) + 700 + 1400 + 200
    B = Image.new("RGB", (W, H), (245, 245, 247))
    d = ImageDraw.Draw(B)
    d.text((pad, 30), "Round 4c · Six sprint controls: Pause · +30 sec · +1 min · +5 min · Custom · End "
           "(real-token renders; card material approximated by the card surface)", font=ft, fill=(20, 20, 24))
    y = head
    heights = {}
    for scheme in ("L", "D"):
        d.text((pad, y), f"On the sprint card, {'light' if scheme == 'L' else 'dark'} (Tasks tab, bottom of screen)", font=fc, fill=(60, 60, 66))
        for c, (name, title) in enumerate(cols):
            im, h = card_on_frame(f"{name}-{scheme}-std", scheme)
            heights[name] = round(h)
            im.save(f"{OUT}/{name}-{scheme}.jpg", quality=88)
            x = pad + c * (cw + pad)
            if scheme == "L":
                d.text((x, y + 40), f"{title} · card {round(h)}pt", font=fc, fill=(20, 20, 24))
            B.paste(im.crop((0, y0 * K, 402 * K, y1 * K)).resize((cw, ch)), (x, y + 80))
        y += ch + 110
    d.text((pad, y), "At AX3 text size (each layout wraps)", font=fc, fill=(60, 60, 66))
    y += 40
    maxh = 0
    for c, (name, _) in enumerate(cols[1:], start=1):
        leaf = Image.open(f"{LEAF}/{name}-L-AX3.png").convert("RGBA")
        bgc = Image.new("RGB", leaf.size, (242, 243, 247)); bgc.paste(leaf, (0, 0), leaf)
        s = bgc.resize((cw, round(leaf.height * cw / leaf.width)))
        B.paste(s, (pad + c * (cw + pad), y)); maxh = max(maxh, s.height)
    y += maxh + 60
    d.text((pad, y), "The focus screen ('Focus screen + Details'): plain · with the Custom stepper open · dark · AX3", font=fc, fill=(60, 60, 66))
    y += 40
    for c, (name, scheme) in enumerate([("screen-plain-L-std", "L"), ("screen-custom-L-std", "L"),
                                         ("screen-plain-D-std", "D"), ("screen-plain-L-AX3", "L")]):
        im = screen_on_frame(name, scheme)
        im.save(f"{OUT}/{name}.jpg", quality=88)
        s = im.resize((cw, round(874 * K * cw / (402 * K))))
        B.paste(s, (pad + c * (cw + pad), y))
    y += round(874 * cw / 402) + 40
    B.crop((0, 0, W, y)).save(f"{S}/58-ROUND-4c-sprint-controls.jpg", quality=85)
    print(heights, (W, y))


if __name__ == "__main__":
    main()
