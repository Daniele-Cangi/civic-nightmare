"""Build optimized runtime portraits from chroma-keyed image-generation output."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tmp" / "imagegen"
OUTPUT_DIR = ROOT / "assets" / "mockups"
PORTRAITS = (
    "trump",
    "musk",
    "vdl",
    "lagarde",
    "putin",
    "macron",
)
RUNTIME_SIZE = (128, 128)
SAFE_CONTENT_SIZE = 116


def build_portrait(slug: str) -> Path:
    source = SOURCE_DIR / f"{slug}_transparent_v2.png"
    destination = OUTPUT_DIR / f"{slug}_combat_portrait_v2.png"
    if not source.exists():
        raise FileNotFoundError(source)

    with Image.open(source) as opened:
        rgba = opened.convert("RGBA")
        # Resize premultiplied channels so transparent chroma pixels cannot
        # leak green into the antialiased silhouette at runtime resolution.
        resized = rgba.convert("RGBa").resize(
            RUNTIME_SIZE,
            Image.Resampling.LANCZOS,
        ).convert("RGBA")

    bounds = resized.getchannel("A").getbbox()
    if bounds is not None:
        subject = resized.crop(bounds)
        scale = min(
            1.0,
            SAFE_CONTENT_SIZE / subject.width,
            SAFE_CONTENT_SIZE / subject.height,
        )
        fitted_size = (
            max(1, round(subject.width * scale)),
            max(1, round(subject.height * scale)),
        )
        if fitted_size != subject.size:
            subject = subject.convert("RGBa").resize(
                fitted_size,
                Image.Resampling.LANCZOS,
            ).convert("RGBA")
        resized = Image.new("RGBA", RUNTIME_SIZE, (0, 0, 0, 0))
        resized.paste(
            subject,
            ((RUNTIME_SIZE[0] - subject.width) // 2,
             (RUNTIME_SIZE[1] - subject.height) // 2),
        )

    pixels = list(resized.getdata())
    resized.putdata([
        (0, 0, 0, 0) if alpha <= 4 else (red, green, blue, alpha)
        for red, green, blue, alpha in pixels
    ])
    resized.save(destination, "PNG", optimize=True)
    return destination


def main() -> None:
    for portrait in PORTRAITS:
        output = build_portrait(portrait)
        print(output.relative_to(ROOT))


if __name__ == "__main__":
    main()
