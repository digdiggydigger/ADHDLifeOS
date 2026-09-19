"""Composite the undo-bar probe renders onto real iPhone 18 Pro / 27.0 frames (round 2b)."""
import os
from PIL import Image, ImageDraw, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
FR, LEAF, OUT = f"{S}/frames", f"{S}/r2-bar", f"{S}/r2-bar/composed"
os.makedirs(OUT, exist_ok=True)
K = 3  # px per pt
T = 772  # tab bar card top (measured, both states)

# state -> frame, leaf copy, scheme, size, sprint?, has search row?, old inbox bar?
STATES = [
    ("tasks-L", "r2-tasks-L", "close", "L", "std", False, True, False),
    ("tasks-D", "r2-tasks-D", "close", "D", "std", False, True, False),
    ("tasks-AX3", "r2-tasks-A", "close", "L", "AX3", False, True, False),
    ("inbox-L", "r2-inbox-L", "triage", "L", "std", False, False, True),
    ("sprint-L", "r2-sprint-L", "sprint", "L", "std", True, True, False),
]


def box(im, x0, y0, x1, y1):
    return im.crop((round(x0 * K), round(y0 * K), round(x1 * K), round(y1 * K)))


def leaf(opt, copy, scheme, size):
    im = Image.open(f"{LEAF}/{opt}-{copy}-{scheme}-{size}.png").convert("RGBA")
    return im, im.height / K - 32  # 16pt shadow padding top and bottom


def fill(im, x0, y0, x1, y1, color):
    ImageDraw.Draw(im).rectangle((round(x0 * K), round(y0 * K), round(x1 * K) - 1, round(y1 * K) - 1), fill=color)


def compose(opt, state):
    name, frame, copy, scheme, size, sprint, search, oldbar = state
    base = Image.open(f"{FR}/{frame}.jpg").convert("RGB")
    bg = base.getpixel((4 * K, 500 * K))
    disc_top = 620 if sprint else 688
    row_bottom = disc_top + 60
    disc_src = Image.open(f"{FR}/{'r2-sprint-L' if sprint and scheme == 'L' else 'r2-sprint-D' if sprint else 'r2-tasks-D' if scheme == 'D' else 'r2-tasks-L'}.jpg").convert("RGB")
    disc = box(disc_src, 306, disc_top - 8, 390, min(disc_top + 72, 686 if sprint else 768))
    srow = box(base, 8, disc_top + 2, 310, disc_top + 60) if search else None
    lf, h = leaf(opt, copy, scheme, size)
    if oldbar:  # remove the inbox's existing bar (it sits under the disc row)
        fill(base, 0, 700, 402, T - 2, bg)
        base.paste(disc, (round(306 * K), round((disc_top - 8) * K)))
    if opt == "A":
        row_h = max(h, 60)
        top = row_bottom - row_h
        fill(base, 0, top - 12, 314, (686 if sprint else T - 2), bg)
        if row_h > 60:  # the row grows upward and the disc re-centres in it
            fill(base, 306, disc_top - 8, 402, disc_top + 72 if not sprint else 686, bg)
            base.paste(disc, (round(306 * K), round((row_bottom - row_h / 2 - 30 - 8) * K)))
        base.paste(lf, (0, round((row_bottom - row_h / 2 - h / 2 - 16) * K)), lf)
    elif opt == "B":
        card_bottom = 680 if sprint else row_bottom  # above the sprint card, else in its slot
        card_top = card_bottom - h
        new_row_bottom = card_top - 8
        d = row_bottom - new_row_bottom
        fill(base, 0, new_row_bottom - 60 - 12, 402, (686 if sprint else T - 2), bg)
        base.paste(disc, (round(306 * K), round((disc_top - 8 - d) * K)))
        if srow:
            base.paste(srow, (round(8 * K), round((disc_top + 2 - d) * K)))
        base.paste(lf, (0, round((card_top - 16) * K)), lf)
    elif opt == "C":
        pill_bottom = disc_top - 8
        base.paste(lf, (0, round((pill_bottom - h - 16) * K)), lf)
    base.save(f"{OUT}/{opt}-{name}.jpg", quality=90)
    return base


def board():
    ft = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 46)
    fc = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 44)
    titles = {
        "A": "A · Capsule in the disc row",
        "B": "B · Card above the tab bar",
        "C": "C · Floating pill",
    }
    y0, y1 = 430, 874  # show the bottom half of each screen
    cw, ch = 402 * K // 2, (y1 - y0) * K // 2
    pad, head, lab = 40, 140, 70
    rows = [s for s in STATES]
    W = pad + 3 * (cw + pad) + 260
    H = head + len(rows) * (ch + lab + pad)
    B = Image.new("RGB", (W, H), (245, 245, 247))
    d = ImageDraw.Draw(B)
    for c, opt in enumerate("ABC"):
        d.text((260 + pad + c * (cw + pad), 40), titles[opt], font=ft, fill=(20, 20, 24))
    for r, st in enumerate(rows):
        y = head + r * (ch + lab + pad)
        d.text((pad, y + ch // 2), st[0], font=fc, fill=(60, 60, 66))
        for c, opt in enumerate("ABC"):
            im = Image.open(f"{OUT}/{opt}-{st[0]}.jpg").crop((0, y0 * K, 402 * K, y1 * K)).resize((cw, ch))
            B.paste(im, (260 + pad + c * (cw + pad), y + lab))
    B.save(f"{S}/54-ROUND-2b-undo-bar-options.jpg", quality=85)
    print(B.size)


if __name__ == "__main__":
    for st in STATES:
        for opt in "ABC":
            compose(opt, st)
    board()
