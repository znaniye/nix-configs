#!/usr/bin/env python3
"""Emit the battery readout's glyph cells as PBMs, pre-rotated for the panel."""

import argparse
import pathlib

from PIL import Image, ImageDraw, ImageFont

CHARS = "0123456789%"

BOLT = (
    "...##",
    "..##.",
    ".##..",
    "#####",
    "..##.",
    ".##..",
    "##...",
)


def cell(width, height):
    return Image.new("1", (width, height), 1)


def draw_char(char, font, width, height):
    image = cell(width, height)
    draw = ImageDraw.Draw(image)
    draw.fontmode = "1"

    left, top, right, bottom = draw.textbbox((0, 0), char, font=font)
    draw.text(
        ((width - (right - left)) // 2 - left, (height - (bottom - top)) // 2 - top),
        char,
        font=font,
        fill=0,
    )
    return image


def draw_bolt(width, height):
    image = cell(width, height)
    pixels = image.load()

    x0 = (width - len(BOLT[0])) // 2
    y0 = (height - len(BOLT)) // 2
    for y, row in enumerate(BOLT):
        for x, mark in enumerate(row):
            if mark == "#":
                pixels[x0 + x, y0 + y] = 0
    return image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--font", required=True)
    parser.add_argument("--size", type=int, default=10)
    parser.add_argument("--advance", type=int, default=6)
    parser.add_argument("--height", type=int, default=8)
    parser.add_argument("--out-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    font = ImageFont.truetype(args.font, args.size)

    cells = [draw_char(char, font, args.advance, args.height) for char in CHARS]
    cells.append(draw_bolt(args.advance, args.height))

    for index, image in enumerate(cells):
        image.transpose(Image.ROTATE_270).save(args.out_dir / f"glyph{index:02d}.pbm")


if __name__ == "__main__":
    main()
