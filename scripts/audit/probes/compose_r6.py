"""Round 6: one task composer (C1/C2/C3) beside today's two composers."""
import os
from PIL import Image, ImageDraw, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
REPO = "/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS/screenshots/adhd-ux-audit"
LEAF, OUT = f"{S}/r6-comp", f"{S}/r6-comp/composed"
os.makedirs(OUT, exist_ok=True)
K = 3
SB = {"L": Image.open(f"{REPO}/22-cap-02-task-composer.jpg").convert("RGB").crop((0, 0, 402 * K, 56 * K)),
      "D": Image.open(f"{REPO}/full/s-home-D-p1.jpg").convert("RGB").crop((0, 0, 402 * K, 56 * K)),
      "A": Image.open(f"{REPO}/22-cap-02-task-composer.jpg").convert("RGB").crop((0, 0, 402 * K, 56 * K))}


def screen(name, key):
    leaf = Image.open(f"{LEAF}/{name}.png").convert("RGB")
    canvas = Image.new("RGB", (402 * K, 874 * K), leaf.getpixel((5, 5)))
    canvas.paste(SB[key], (0, 0))
    canvas.paste(leaf, (0, 56 * K))
    canvas.save(f"{OUT}/{name}.jpg", quality=88)
    return canvas


def main():
    ft = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 44)
    fc = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 30)
    sc = 0.45
    cw, ch = round(402 * K * sc), round(874 * K * sc)
    pad, head, lab = 36, 120, 70
    W = pad + 5 * (cw + pad)
    rows = [
        ("Today: TWO doors, TWO different composers", [(f"{REPO}/22-cap-02-task-composer.jpg", "Disc → Task: forced 'due today'"),
                                                        (f"{REPO}/49-toolbar-plus-new-task.jpg", "Tasks '+': a different sheet"),
                                                        (f"{REPO}/50-undated-task-missing-from-board.jpg", "'Not yet' task missing from the board"),
                                                        (f"{REPO}/21-cap-01-fan.jpg", "Fan: 'Everything goes to the inbox'")]),
        ("ONE composer, light", [("C1-title-three-chips-L", "C1 · Title + 3 chips"), ("C2-title-next-step-L", "C2 · Title + next step"), ("C3-everything-folded-L", "C3 · Everything, folded")]),
        ("ONE composer, dark", [("C1-title-three-chips-D", ""), ("C2-title-next-step-D", ""), ("C3-everything-folded-D", "")]),
        ("ONE composer, AX3", [("C1-title-three-chips-A", ""), ("C2-title-next-step-A", ""), ("C3-everything-folded-A", "")]),
    ]
    H = head + len(rows) * (ch + lab + pad + 20)
    B = Image.new("RGB", (W, H), (245, 245, 247))
    d = ImageDraw.Draw(B)
    d.text((pad, 30), "Round 6 · One task composer, whichever door you use (real-token renders; Cancel → 'Close' per round 2)", font=ft, fill=(20, 20, 24))
    y = head
    for r, (rtitle, cells) in enumerate(rows):
        d.text((pad, y), rtitle, font=fc, fill=(60, 60, 66))
        for c, (src, title) in enumerate(cells):
            if r == 0:
                im = Image.open(src).convert("RGB")
            else:
                im = screen(src, src[-1])
            x = pad + c * (cw + pad)
            if title:
                d.text((x, y + 36), title, font=fc, fill=(20, 20, 24))
            B.paste(im.resize((cw, ch)), (x, y + lab + 10))
        y += ch + lab + pad + 20
    B.crop((0, 0, W, y)).save(f"{S}/60-ROUND-6-composer-options.jpg", quality=85)
    print((W, y))


if __name__ == "__main__":
    main()
