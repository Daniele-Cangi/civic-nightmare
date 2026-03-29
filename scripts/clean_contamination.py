from collections import deque
from pathlib import Path
from PIL import Image


PROJECT_ROOT = Path(r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare")
PORTRAIT_PATH = PROJECT_ROOT / "assets" / "mockups" / "contamination_portrait.png"

# Tight square crop around face, chest and hands opening the coat.
PORTRAIT_CROP_BOX = (220, 128, 944, 852)
OUTPUT_SIZE = (1024, 1024)


def _remove_bright_edge_noise(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    bright_mask = [[False for _ in range(width)] for _ in range(height)]
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            brightness = (r + g + b) / 3.0
            spread = max(r, g, b) - min(r, g, b)
            if brightness >= 205 and spread <= 42:
                bright_mask[y][x] = True

    visited = [[False for _ in range(width)] for _ in range(height)]
    to_clear = set()
    dirs = ((1, 0), (-1, 0), (0, 1), (0, -1))

    for sy in range(height):
        for sx in range(width):
            if not bright_mask[sy][sx] or visited[sy][sx]:
                continue
            queue = deque([(sx, sy)])
            visited[sy][sx] = True
            component = []
            touches_transparent = False

            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for dx, dy in dirs:
                    nx = x + dx
                    ny = y + dy
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        touches_transparent = True
                        continue
                    nr, ng, nb, na = pixels[nx, ny]
                    if na == 0:
                        touches_transparent = True
                    if bright_mask[ny][nx] and not visited[ny][nx]:
                        visited[ny][nx] = True
                        queue.append((nx, ny))

            if touches_transparent and len(component) <= 20:
                to_clear.update(component)

    for x, y in to_clear:
        pixels[x, y] = (0, 0, 0, 0)

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if 0 < a < 255:
                brightness = (r + g + b) / 3.0
                spread = max(r, g, b) - min(r, g, b)
                if brightness >= 175 and spread <= 60:
                    darken = max(0.45, a / 255.0)
                    pixels[x, y] = (
                        int(r * darken),
                        int(g * darken),
                        int(b * darken),
                        a,
                    )

    return img


def rebuild_contamination_portrait() -> None:
    if not PORTRAIT_PATH.exists():
        raise FileNotFoundError(f"Missing portrait: {PORTRAIT_PATH}")

    img = Image.open(PORTRAIT_PATH).convert("RGBA")
    cropped = img.crop(PORTRAIT_CROP_BOX)
    cleaned = _remove_bright_edge_noise(cropped)
    final = cleaned.resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
    final.save(PORTRAIT_PATH, "PNG")
    print(f"Rebuilt portrait: {PORTRAIT_PATH}")


if __name__ == "__main__":
    rebuild_contamination_portrait()
