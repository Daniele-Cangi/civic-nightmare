#!/usr/bin/env python3
"""Normalize a generated authority facade for the overworld runtime contract."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


ALPHA_CUTOFF = 8
CANVAS_WIDTH = 352
EDGE_PADDING = 4


def _clear_key_artifacts(image: Image.Image) -> Image.Image:
    """Remove residual magenta pixels without touching the intended palette."""
    cleaned = image.convert("RGBA")
    pixels = []
    for red, green, blue, alpha in cleaned.getdata():
        is_key_spill = (
            alpha > 0
            and red > 170
            and blue > 155
            and green < 100
            and abs(red - blue) < 80
        )
        if alpha <= ALPHA_CUTOFF or is_key_spill:
            pixels.append((0, 0, 0, 0))
        else:
            pixels.append((red, green, blue, alpha))
    cleaned.putdata(pixels)
    return cleaned


def normalize(source: Path, destination: Path, canvas_height: int) -> None:
    image = _clear_key_artifacts(Image.open(source))
    alpha_mask = image.getchannel("A").point(
        lambda value: 255 if value > ALPHA_CUTOFF else 0
    )
    bounds = alpha_mask.getbbox()
    if bounds is None:
        raise ValueError(f"{source} contains no visible pixels")

    subject = image.crop(bounds)
    max_width = CANVAS_WIDTH - EDGE_PADDING * 2
    max_height = canvas_height - EDGE_PADDING * 2
    scale = min(max_width / subject.width, max_height / subject.height)
    target_size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(target_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS_WIDTH, canvas_height), (0, 0, 0, 0))
    x = (CANVAS_WIDTH - subject.width) // 2
    y = canvas_height - EDGE_PADDING - subject.height
    canvas.alpha_composite(subject, (x, y))

    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, "PNG", optimize=True)
    print(
        f"{source.name}: crop={bounds} content={target_size} "
        f"canvas={CANVAS_WIDTH}x{canvas_height} offset=({x},{y})"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--height", type=int, required=True)
    args = parser.parse_args()
    normalize(args.source, args.destination, args.height)


if __name__ == "__main__":
    main()
