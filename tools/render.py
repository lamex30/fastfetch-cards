#!/usr/bin/env python3
"""Render ANSI terminal output (stdin) to a PNG that looks like a terminal window.
usage: fastfetch -a saturn | tools/render.py out.png"""
import re, sys
from PIL import Image, ImageDraw, ImageFont

FONT = sys.argv[2] if len(sys.argv) > 2 else \
    "~/.local/share/fonts/JetBrainsMonoNerd/JetBrainsMonoNerdFontMono-Regular.ttf"
SIZE, SCALE = 15, 2
PAL = {30: "#2a2a3a", 31: "#e8a2af", 32: "#a6d9a8", 33: "#f0d9a0", 34: "#9fb8ee",
       35: "#cba6f7", 36: "#94d8d0", 37: "#c3c6d8", 90: "#6c7086", 91: "#f0b4c0",
       92: "#b8e6ba", 93: "#f6e4b4", 94: "#b4c8f4", 95: "#d9bcfa", 96: "#ace4dc", 97: "#f2f2f8"}
FG, BG, FRAME = "#d4d6e4", "#161620", "#22222f"

import os
font = ImageFont.truetype(os.path.expanduser(FONT), SIZE * SCALE)
cw = round(font.getlength("M")); ch = round(SIZE * SCALE * 1.3)
lines = sys.stdin.read().rstrip("\n").split("\n")
while lines and not lines[0].strip(): lines.pop(0)
cells = []
for line in lines:
    row, color, pos = [], FG, 0
    for m in re.finditer(r"\x1b\[([0-9;]*)m|(.)", line):
        if m.group(1) is not None:
            for c in (m.group(1) or "0").split(";"):
                c = int(c or 0)
                color = FG if c in (0, 39) else PAL.get(c, color)
        else:
            row.append((m.group(2), color))
    while row and row[-1][0] == " ": row.pop()
    cells.append(row)
cols = max(len(r) for r in cells)
pad, bar = 28 * SCALE, 34 * SCALE
W, H = cols * cw + 2 * pad, len(cells) * ch + 2 * pad + bar
img = Image.new("RGB", (W, H), FRAME)
d = ImageDraw.Draw(img)
d.rounded_rectangle([0, 0, W - 1, H - 1], 14 * SCALE, fill=BG, outline="#33334a", width=SCALE)
d.rectangle([SCALE, bar - SCALE, W - 1 - SCALE, bar], fill="#1d1d29")
for i, c in enumerate(("#e8a2af", "#f0d9a0", "#a6d9a8")):
    x, y, r = 22 * SCALE + i * 20 * SCALE, bar // 2, 6 * SCALE
    d.ellipse([x - r, y - r, x + r, y + r], fill=c)
for y, row in enumerate(cells):
    for x, (char, color) in enumerate(row):
        if char != " ":
            d.text((pad + x * cw, bar + pad + y * ch), char, font=font, fill=color)
# rounded transparent corners
mask = Image.new("L", (W, H), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, H - 1], 14 * SCALE, fill=255)
out = Image.new("RGBA", (W, H)); out.paste(img, mask=mask)
out = out.resize((W // SCALE, H // SCALE), Image.LANCZOS)
out.save(sys.argv[1], optimize=True)
