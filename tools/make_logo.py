"""Draws the launcher's wordmark (launcher/logo.png) and turns it into launcher/logo_png.h.

Usage: python tools/make_logo.py
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = "C:/Windows/Fonts/impact.ttf"
GREEN = (118, 196, 52, 255)
DARK = (14, 30, 10, 255)
LIGHT = (235, 240, 230, 255)


def text(draw, xy, s, size, fill, stroke):
    font = ImageFont.truetype(FONT, size)
    draw.text(xy, s, font=font, fill=fill, stroke_width=stroke, stroke_fill=DARK, anchor="mm")


def main():
    w, h = 1400, 440
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    text(d, (w // 2, 62), "THE INCREDIBLE", 92, LIGHT, 6)
    text(d, (w // 2, 222), "HULK", 250, GREEN, 10)
    text(d, (w // 2, 384), "RECOMPILED", 72, LIGHT, 5)
    out = ROOT / "launcher" / "logo.png"
    out.parent.mkdir(exist_ok=True)
    img.save(out)
    tool = ROOT / "third_party" / "trg-launcher" / "launcher2" / "tools" / "png_to_header.py"
    subprocess.run([sys.executable, str(tool), str(out), str(out.with_name("logo_png.h")), "kHulkLogoPng"], check=True)


if __name__ == "__main__":
    main()
