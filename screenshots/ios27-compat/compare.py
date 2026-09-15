#!/usr/bin/env python3
"""Phase D: lay 26.5 and 27.0 frames side by side and measure how much changed.

Usage: compare.py <frames-dir> <out-dir>
Expects <frames-dir>/<NN-name>-<os>-<appearance>.png for os in {26.5, 27.0}.
Writes <out-dir>/<NN-name>-<appearance>-26v27.jpg (26.5 | 27.0 | diff heat) and prints a
table: surface, appearance, % pixels differing (per-channel delta > 24/255), and the bounding
box of the difference, so a change can be located rather than guessed at.
"""
import os
import re
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

frames, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
THRESH = 24

pat = re.compile(r"^(\d\d-[a-z0-9-]+?)-(26\.5|27\.0)-(light|dark)\.png$")
groups = {}
for f in sorted(os.listdir(frames)):
    m = pat.match(f)
    if m:
        groups.setdefault((m.group(1), m.group(3)), {})[m.group(2)] = os.path.join(frames, f)

print("| surface | appearance | changed px | status bar | content | bottom band (search row + bar) |")
print("|---|---|---|---|---|---|")
for (name, appearance), by_os in sorted(groups.items()):
    if "26.5" not in by_os or "27.0" not in by_os:
        print(f"| {name} | {appearance} | MISSING {sorted(by_os)} | | | |")
        continue
    a = Image.open(by_os["26.5"]).convert("RGB")
    b = Image.open(by_os["27.0"]).convert("RGB")
    if a.size != b.size:
        b = b.resize(a.size)
    diff = ImageChops.difference(a, b)
    mask = diff.convert("L").point(lambda v: 255 if v > THRESH else 0)
    # per-channel max, not luminance: a hue shift with equal luminance still counts
    chan = [c.point(lambda v: 255 if v > THRESH else 0) for c in diff.split()]
    mask = ImageChops.lighter(ImageChops.lighter(chan[0], chan[1]), chan[2])
    total = a.size[0] * a.size[1]
    changed = sum(1 for v in mask.getdata() if v)
    bbox = mask.getbbox()
    pct = 100.0 * changed / total
    # Bands, in pixels at 3x: the status bar (clock text differs on every pair, by design),
    # the content, and the bottom band holding the search row / capture disc / tab bar.
    w, h = a.size
    bands = {"status": (0, 180), "content": (180, h - 340), "bottom": (h - 340, h)}
    band_pct = {}
    for k, (y0, y1) in bands.items():
        crop = mask.crop((0, y0, w, y1))
        band_pct[k] = 100.0 * sum(1 for v in crop.getdata() if v) / (w * (y1 - y0))
    heat = Image.merge("RGB", (mask, Image.new("L", a.size, 0), Image.new("L", a.size, 0)))
    heat = Image.blend(a.convert("RGB"), heat, 0.55)
    w, h = a.size
    gap = 24
    sheet = Image.new("RGB", (w * 3 + gap * 2, h + 72), (255, 255, 255))
    for i, im in enumerate((a, b, heat)):
        sheet.paste(im, (i * (w + gap), 72))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 40)
    except OSError:
        font = ImageFont.load_default()
    labels = ("iOS 26.5", "iOS 27.0", f"changed {pct:.2f}%")
    for i, t in enumerate(labels):
        d.text((i * (w + gap) + 24, 16), t, fill=(0, 0, 0), font=font)
    sheet = sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS)
    sheet.save(os.path.join(out, f"{name}-{appearance}-26v27.jpg"), quality=82)
    print(f"| {name} | {appearance} | {pct:.2f}% | {band_pct['status']:.2f}% | {band_pct['content']:.2f}% | {band_pct['bottom']:.2f}% |")
