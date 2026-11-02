"""Puts captured screenshots side by side, small, with their names: python tools/contact_sheet.py out.png a.png b.png ..."""
import sys
from PIL import Image, ImageDraw

out, files = sys.argv[1], sys.argv[2:]
w, h, cols = 640, 360, 3
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (w * cols, (h + 24) * rows), (30, 30, 30))
d = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    x, y = (i % cols) * w, (i // cols) * (h + 24)
    sheet.paste(Image.open(f).convert("RGB").resize((w, h)), (x, y + 24))
    d.text((x + 6, y + 6), f.replace("\\", "/").split("/")[-1], fill=(255, 255, 255))
sheet.save(out)
