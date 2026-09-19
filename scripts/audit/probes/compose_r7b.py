"""Round 7b: three composer layouts, keyboard up (the real use) and down."""
import os
from PIL import Image, ImageDraw, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
REPO = "/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS/screenshots/adhd-ux-audit"
LEAF, OUT = f"{S}/r7-layout", f"{S}/r7-layout/composed"
os.makedirs(OUT, exist_ok=True)
K = 3
SB = {"L": Image.open(f"{REPO}/22-cap-02-task-composer.jpg").convert("RGB").crop((0, 0, 402 * K, 56 * K)),
      "D": Image.open(f"{REPO}/full/s-home-D-p1.jpg").convert("RGB").crop((0, 0, 402 * K, 56 * K)),
      "A": Image.open(f"{REPO}/22-cap-02-task-composer.jpg").convert("RGB").crop((0, 0, 402 * K, 56 * K))}
KB = {"L": (209, 212, 219), "D": (43, 43, 47)}
ft_kb = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 54)


def screen(name):
    key = name[-1]
    up = "-up-" in name
    leaf = Image.open(f"{LEAF}/{name}.png").convert("RGB")
    canvas = Image.new("RGB", (402 * K, 874 * K), leaf.getpixel((5, 5)))
    canvas.paste(SB[key], (0, 0))
    canvas.paste(leaf, (0, 56 * K))
    if up:
        d = ImageDraw.Draw(canvas)
        top = (56 + 482) * K
        d.rounded_rectangle((0, top, 402 * K, 874 * K), radius=30 * K, fill=KB[key])
        d.text((402 * K / 2 - 330, top + 130 * K), "keyboard (336pt)", font=ft_kb,
               fill=(120, 120, 128) if key == "L" else (150, 150, 158))
    canvas.save(f"{OUT}/{name}.jpg", quality=88)
    return canvas


def main():
    ft = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 44)
    fc = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 30)
    sc = 0.45
    cw, ch = round(402 * K * sc), round(874 * K * sc)
    pad, head, lab = 36, 120, 60
    titles = {"L1-tidy-grid": "L1 · Tidy grid (one shape, equal widths)",
              "L2-form-card": "L2 · Form card (labelled rows)",
              "L3-keyboard-toolbar": "L3 · Rides on the keyboard"}
    rows = [("Keyboard UP, light (how you'll actually see it) · the keyboard is a drawn 336pt block: the sim hides it", "up-L"), ("Keyboard UP, dark", "up-D"),
            ("Keyboard down, light", "down-L"), ("AX3, keyboard down", "down-A")]
    W = pad + 3 * (cw + pad)
    H = head + len(rows) * (ch + lab + pad + 30)
    B = Image.new("RGB", (W, H), (245, 245, 247))
    d = ImageDraw.Draw(B)
    d.text((pad, 30), "Round 7b · Your composer content, three layouts (real tokens)", font=ft, fill=(20, 20, 24))
    y = head
    for rtitle, suffix in rows:
        d.text((pad, y), rtitle, font=fc, fill=(60, 60, 66))
        for c, layout in enumerate(titles):
            im = screen(f"{layout}-{suffix}")
            x = pad + c * (cw + pad)
            if suffix == "up-L":
                d.text((x, y + 34), titles[layout], font=fc, fill=(20, 20, 24))
            B.paste(im.resize((cw, ch)), (x, y + lab + 20))
        y += ch + lab + pad + 30
    B.crop((0, 0, W, y)).save(f"{S}/64-ROUND-7b-composer-layouts.jpg", quality=85)
    print((W, y))


if __name__ == "__main__":
    main()
