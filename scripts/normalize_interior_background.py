"""Normalize authored room art to Civic Nightmare's 19x17 indoor canvas."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageFilter


ROOM_SIZE = (608, 544)


def normalize(source: Path, destination: Path) -> None:
    with Image.open(source) as opened:
        image = opened.convert("RGB")

    source_width, source_height = image.size
    target_ratio = ROOM_SIZE[0] / ROOM_SIZE[1]
    source_ratio = source_width / source_height

    if source_ratio > target_ratio:
        crop_width = round(source_height * target_ratio)
        left = (source_width - crop_width) // 2
        image = image.crop((left, 0, left + crop_width, source_height))
    else:
        crop_height = round(source_width / target_ratio)
        top = (source_height - crop_height) // 2
        image = image.crop((0, top, source_width, top + crop_height))

    image = image.resize(ROOM_SIZE, Image.Resampling.LANCZOS)
    image = image.filter(ImageFilter.UnsharpMask(radius=0.8, percent=115, threshold=3))

    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, "PNG", optimize=True)
    print(f"{source} -> {destination} ({image.width}x{image.height})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    normalize(args.source, args.destination)


if __name__ == "__main__":
    main()
