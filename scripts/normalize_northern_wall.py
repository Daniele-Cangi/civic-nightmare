#!/usr/bin/env python3
"""Normalize the generated northern-wall chroma source for the overworld."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


CANVAS_SIZE = (2176, 448)
GATE_ALIGNMENT_SHIFT = 19


def _remove_magenta_matte(image: Image.Image) -> Image.Image:
    keyed = image.convert("RGBA")
    output: list[tuple[int, int, int, int]] = []
    for red, green, blue, alpha in keyed.getdata():
        magenta_excess = (red + blue) * 0.5 - green
        is_matte = (
            red > 70
            and blue > 60
            and red > green * 1.2
            and blue > green * 1.2
            and abs(red - blue) < 100
            and magenta_excess > 35
        )
        output.append((0, 0, 0, 0) if is_matte else (red, green, blue, alpha))
    keyed.putdata(output)
    return keyed


def normalize(source: Path, destination: Path) -> None:
    image = _remove_magenta_matte(Image.open(source))
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"{source} contains no visible wall pixels")

    subject = image.crop(bounds)
    # Premultiplied resizing prevents the keyed matte color from bleeding back
    # into the fine roof, camera, and crenellation silhouettes.
    subject = subject.convert("RGBa").resize(
        CANVAS_SIZE,
        Image.Resampling.LANCZOS,
    ).convert("RGBA")
    # The generated arch sits 19 px to the right of the district plate's true
    # boulevard axis. Shift the composition left while stretching only a thin
    # slice at the far-right wall wing so the perimeter still reaches both map
    # edges without introducing a transparent seam.
    width, height = CANVAS_SIZE
    aligned = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    aligned.paste(subject.crop((GATE_ALIGNMENT_SHIFT, 0, width, height)), (0, 0))
    tail = subject.crop((width - GATE_ALIGNMENT_SHIFT, 0, width, height))
    tail = tail.convert("RGBa").resize(
        (GATE_ALIGNMENT_SHIFT * 2, height),
        Image.Resampling.LANCZOS,
    ).convert("RGBA")
    aligned.paste(tail, (width - GATE_ALIGNMENT_SHIFT * 2, 0))
    subject = aligned
    subject = _remove_magenta_matte(subject)
    subject.putdata([
        (0, 0, 0, 0) if alpha <= 4 else (red, green, blue, alpha)
        for red, green, blue, alpha in subject.getdata()
    ])
    destination.parent.mkdir(parents=True, exist_ok=True)
    subject.save(destination, "PNG", optimize=True)
    print(
        f"{source.name}: crop={bounds} source={image.size} "
        f"output={CANVAS_SIZE[0]}x{CANVAS_SIZE[1]}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    normalize(args.source, args.destination)


if __name__ == "__main__":
    main()
