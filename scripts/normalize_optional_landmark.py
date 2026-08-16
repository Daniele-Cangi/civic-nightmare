#!/usr/bin/env python3
"""Prepare generated optional landmarks for the overworld runtime contract."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


EDGE_PADDING = 4


def _remove_magenta_key(image: Image.Image) -> Image.Image:
    """Convert a flat magenta background and its antialiasing into alpha."""
    keyed = image.convert("RGBA")
    output: list[tuple[int, int, int, int]] = []
    for red, green, blue, source_alpha in keyed.getdata():
        magenta_dominant = red > green + 20 and blue > green + 20
        if not magenta_dominant:
            output.append((red, green, blue, source_alpha))
            continue

        # Color-to-alpha against #ff00ff. This recovers the foreground color
        # from antialiased edge pixels instead of leaving a purple fringe.
        alpha = max(255 - red, green, 255 - blue)
        alpha = min(alpha, source_alpha)
        if alpha <= 6:
            output.append((0, 0, 0, 0))
            continue

        recovered_red = round((red - (255 - alpha)) * 255 / alpha)
        recovered_green = round(green * 255 / alpha)
        recovered_blue = round((blue - (255 - alpha)) * 255 / alpha)
        # JPEG-like colour noise in generated chroma keys can otherwise turn
        # low-alpha dark edges into luminous green pixels after unmatting.
        edge_red = max(0, min(255, recovered_red))
        edge_blue = max(0, min(255, recovered_blue))
        if alpha < 180 and recovered_green > max(edge_red, edge_blue) + 30:
            recovered_green = max(edge_red, edge_blue) + 30
        output.append((
            edge_red,
            max(0, min(255, recovered_green)),
            edge_blue,
            alpha,
        ))

    keyed.putdata(output)
    return keyed


def normalize(
    source: Path,
    destination: Path,
    width: int,
    height: int,
    hard_alpha: bool = False,
) -> None:
    image = _remove_magenta_key(Image.open(source))
    if hard_alpha:
        # The authored landmarks are opaque props. Threshold at source
        # resolution, then let the final resize rebuild a clean antialiased
        # edge without retaining chroma-compression colour noise.
        image.putalpha(image.getchannel("A").point(lambda value: 255 if value >= 96 else 0))
    bounds = image.getchannel("A").point(lambda value: 255 if value > 6 else 0).getbbox()
    if bounds is None:
        raise ValueError(f"{source} contains no visible pixels")

    subject = image.crop(bounds)
    scale = min(
        (width - EDGE_PADDING * 2) / subject.width,
        (height - EDGE_PADDING * 2) / subject.height,
    )
    target_size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(target_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    offset = ((width - subject.width) // 2, height - EDGE_PADDING - subject.height)
    canvas.alpha_composite(subject, offset)
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, "PNG", optimize=True)
    print(
        f"{source.name}: crop={bounds} content={target_size} "
        f"canvas={width}x{height} offset={offset}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--width", type=int, required=True)
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("--hard-alpha", action="store_true")
    args = parser.parse_args()
    normalize(args.source, args.destination, args.width, args.height, args.hard_alpha)


if __name__ == "__main__":
    main()
