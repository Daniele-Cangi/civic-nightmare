"""
Civic Nightmare - Pixel Art Tileset Generator
Generates a detailed 256x256 tileset (8x8 grid of 32x32 tiles)
replacing flat colored squares with proper pixel art.
"""
from PIL import Image, ImageDraw
import random
import math

TILE = 32
GRID = 8
random.seed(42)  # Deterministic output


def make_tileset():
    img = Image.new("RGBA", (GRID * TILE, GRID * TILE), (0, 0, 0, 0))

    # Row 0: GRASS, WOOD, PATH, WATER
    paste(img, draw_grass(), 0, 0)
    paste(img, draw_wood_floor(), 1, 0)
    paste(img, draw_path(), 2, 0)
    paste(img, draw_water(), 3, 0)
    # Extra grass variants in unused slots
    paste(img, draw_grass_variant(1), 4, 0)
    paste(img, draw_grass_variant(2), 5, 0)
    paste(img, draw_grass_flowers(), 6, 0)
    paste(img, draw_grass_dark(), 7, 0)

    # Row 1: BRICK, METAL_FLOOR, METAL_WALL, VAULT_WALL
    paste(img, draw_brick(), 0, 1)
    paste(img, draw_metal_floor(), 1, 1)
    paste(img, draw_metal_wall(), 2, 1)
    paste(img, draw_vault_wall(), 3, 1)
    # Extra wall variants
    paste(img, draw_brick_dark(), 4, 1)
    paste(img, draw_metal_panel(), 5, 1)
    paste(img, draw_vault_door(), 6, 1)
    paste(img, draw_concrete(), 7, 1)

    # Row 2: KREMLIN_WALL, MARBLE_FLOOR, MARBLE_WALL
    paste(img, draw_kremlin_wall(), 0, 2)
    paste(img, draw_marble_floor(), 1, 2)
    paste(img, draw_marble_wall(), 2, 2)
    paste(img, draw_carpet_red(), 3, 2)
    paste(img, draw_carpet_blue(), 4, 2)
    paste(img, draw_tile_floor(), 5, 2)
    paste(img, draw_window(), 6, 2)
    paste(img, draw_door(), 7, 2)

    # Row 3: TREE_TOP, TREE_TRUNK, BUSH, DESK_WOOD
    paste(img, draw_tree_top(), 0, 3)
    paste(img, draw_tree_trunk(), 1, 3)
    paste(img, draw_bush(), 2, 3)
    paste(img, draw_desk_wood(), 3, 3)
    paste(img, draw_flower_patch(), 4, 3)
    paste(img, draw_rock(), 5, 3)
    paste(img, draw_lamp_post(), 6, 3)
    paste(img, draw_bench(), 7, 3)

    # Row 4: DESK_METAL, SERVER, BOOKSHELF, GOLD, FLAG
    paste(img, draw_desk_metal(), 0, 4)
    paste(img, draw_server(), 1, 4)
    paste(img, draw_bookshelf(), 2, 4)
    paste(img, draw_gold(), 3, 4)
    paste(img, draw_flag(), 4, 4)
    paste(img, draw_filing_cabinet(), 5, 4)
    paste(img, draw_potted_plant(), 6, 4)
    paste(img, draw_clock(), 7, 4)

    # Row 5: Water edges and path edges
    paste(img, draw_water_edge_top(), 0, 5)
    paste(img, draw_water_edge_left(), 1, 5)
    paste(img, draw_water_edge_right(), 2, 5)
    paste(img, draw_water_edge_bottom(), 3, 5)
    paste(img, draw_path_edge_h(), 4, 5)
    paste(img, draw_path_edge_v(), 5, 5)
    paste(img, draw_path_corner(), 6, 5)
    paste(img, draw_path_cross(), 7, 5)

    # Row 6-7: Building top/facade elements
    paste(img, draw_roof_red(), 0, 6)
    paste(img, draw_roof_gray(), 1, 6)
    paste(img, draw_roof_gold(), 2, 6)
    paste(img, draw_chimney(), 3, 6)
    paste(img, draw_entrance_mat(), 4, 6)
    paste(img, draw_stairs(), 5, 6)
    paste(img, draw_column(), 6, 6)
    paste(img, draw_fountain(), 7, 6)

    paste(img, draw_sign_post(), 0, 7)
    paste(img, draw_trash_can(), 1, 7)
    paste(img, draw_mailbox(), 2, 7)
    paste(img, draw_barrier(), 3, 7)
    paste(img, draw_manhole(), 4, 7)
    paste(img, draw_grate(), 5, 7)
    paste(img, draw_shadow_overlay(), 6, 7)
    paste(img, draw_light_overlay(), 7, 7)

    return img


def paste(img, tile, gx, gy):
    img.paste(tile, (gx * TILE, gy * TILE))


# ================================================================
#  HELPER FUNCTIONS
# ================================================================

def noise_fill(draw, base_color, var_range=15, density=0.3):
    """Fill entire tile with noisy color variation."""
    r, g, b = base_color
    for y in range(TILE):
        for x in range(TILE):
            if random.random() < density:
                dr = random.randint(-var_range, var_range)
                dg = random.randint(-var_range, var_range)
                db = random.randint(-var_range, var_range)
                draw.point((x, y), fill=(
                    max(0, min(255, r + dr)),
                    max(0, min(255, g + dg)),
                    max(0, min(255, b + db)),
                    255
                ))


def clamp(v, lo=0, hi=255):
    return max(lo, min(hi, v))


def shade(color, amount):
    """Lighten (positive) or darken (negative) a color."""
    r, g, b = color[:3]
    return (clamp(r + amount), clamp(g + amount), clamp(b + amount), 255)


def dither_rect(draw, x0, y0, x1, y1, c1, c2):
    """Draw a dithered rectangle blending two colors."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            if (x + y) % 2 == 0:
                draw.point((x, y), fill=c1)
            else:
                draw.point((x, y), fill=c2)


# ================================================================
#  NATURAL TILES
# ================================================================

def draw_grass():
    t = Image.new("RGBA", (TILE, TILE), (58, 110, 48, 255))
    d = ImageDraw.Draw(t)
    # Texture variation
    for _ in range(180):
        x, y = random.randint(0, 31), random.randint(0, 31)
        shade_v = random.choice([-18, -12, -6, 6, 12, 18])
        d.point((x, y), fill=(clamp(58 + shade_v), clamp(110 + shade_v), clamp(48 + shade_v), 255))
    # Grass blade clusters
    for _ in range(8):
        bx, by = random.randint(2, 29), random.randint(2, 29)
        d.point((bx, by), fill=(48, 100, 38, 255))
        d.point((bx, by - 1), fill=(68, 120, 58, 255))
    return t


def draw_grass_variant(seed_offset):
    random.seed(42 + seed_offset * 100)
    t = Image.new("RGBA", (TILE, TILE), (52, 105, 42, 255))
    d = ImageDraw.Draw(t)
    for _ in range(160):
        x, y = random.randint(0, 31), random.randint(0, 31)
        sv = random.choice([-15, -8, 8, 15])
        d.point((x, y), fill=(clamp(52 + sv), clamp(105 + sv), clamp(42 + sv), 255))
    random.seed(42)
    return t


def draw_grass_flowers():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    colors = [(220, 200, 60, 255), (200, 80, 80, 255), (180, 120, 200, 255), (255, 255, 255, 255)]
    for _ in range(5):
        fx, fy = random.randint(3, 28), random.randint(3, 28)
        c = random.choice(colors)
        d.point((fx, fy), fill=c)
        d.point((fx + 1, fy), fill=c)
    return t


def draw_grass_dark():
    t = Image.new("RGBA", (TILE, TILE), (42, 88, 35, 255))
    d = ImageDraw.Draw(t)
    for _ in range(140):
        x, y = random.randint(0, 31), random.randint(0, 31)
        sv = random.choice([-12, -6, 6, 12])
        d.point((x, y), fill=(clamp(42 + sv), clamp(88 + sv), clamp(35 + sv), 255))
    return t


def draw_water():
    t = Image.new("RGBA", (TILE, TILE), (30, 60, 120, 255))
    d = ImageDraw.Draw(t)
    # Wave highlights
    for y in range(TILE):
        wave_x = int(4 * math.sin(y * 0.4)) + 8
        for x in range(TILE):
            dist = abs(x - wave_x) % 12
            if dist < 2:
                d.point((x, y), fill=(50, 90, 160, 255))
            elif dist < 3:
                d.point((x, y), fill=(40, 75, 140, 255))
    # Sparkle highlights
    for _ in range(6):
        sx, sy = random.randint(2, 29), random.randint(2, 29)
        d.point((sx, sy), fill=(100, 150, 210, 255))
    return t


def draw_path():
    t = Image.new("RGBA", (TILE, TILE), (150, 140, 120, 255))
    d = ImageDraw.Draw(t)
    # Stone texture
    for _ in range(200):
        x, y = random.randint(0, 31), random.randint(0, 31)
        sv = random.choice([-20, -10, 10, 20])
        d.point((x, y), fill=(clamp(150 + sv), clamp(140 + sv), clamp(120 + sv), 255))
    # Subtle cracks
    for _ in range(3):
        cx = random.randint(4, 28)
        cy = random.randint(4, 28)
        for i in range(4):
            nx = cx + random.choice([-1, 0, 1])
            ny = cy + i
            if 0 <= nx < 32 and 0 <= ny < 32:
                d.point((nx, ny), fill=(120, 112, 95, 255))
    # Stone border lines
    for x in range(TILE):
        if random.random() < 0.3:
            d.point((x, 10), fill=(130, 122, 105, 255))
            d.point((x, 21), fill=(130, 122, 105, 255))
    return t


def draw_tree_top():
    t = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))  # Transparent base
    d = ImageDraw.Draw(t)
    cx, cy = 16, 16
    # Layered foliage
    for r in range(14, 0, -1):
        brightness = 55 + (14 - r) * 6
        color = (clamp(brightness - 20), clamp(brightness + 30), clamp(brightness - 25), 255)
        for y in range(TILE):
            for x in range(TILE):
                dx, dy = x - cx, y - cy
                dist = math.sqrt(dx * dx + dy * dy) + random.random() * 3
                if dist < r:
                    d.point((x, y), fill=color)
    # Leaf detail
    for _ in range(40):
        lx = cx + random.randint(-11, 11)
        ly = cy + random.randint(-11, 11)
        if 0 <= lx < 32 and 0 <= ly < 32:
            sv = random.choice([-25, -15, 15, 25])
            d.point((lx, ly), fill=(clamp(75 + sv), clamp(130 + sv), clamp(65 + sv), 255))
    # Shadow on bottom
    for x in range(6, 26):
        for y in range(22, 28):
            px = t.getpixel((x, y))
            if px[3] > 0:
                d.point((x, y), fill=(clamp(px[0] - 20), clamp(px[1] - 20), clamp(px[2] - 20), 255))
    return t


def draw_tree_trunk():
    t = draw_grass()  # Grass base
    d = ImageDraw.Draw(t)
    # Trunk
    trunk_color = (90, 62, 35, 255)
    bark_dark = (70, 48, 28, 255)
    bark_light = (110, 78, 45, 255)
    d.rectangle([13, 4, 18, 31], fill=trunk_color)
    # Bark texture
    for y in range(4, 32):
        for x in range(13, 19):
            if random.random() < 0.3:
                d.point((x, y), fill=random.choice([bark_dark, bark_light]))
    # Bark edges (darker)
    for y in range(4, 32):
        d.point((13, y), fill=bark_dark)
        d.point((18, y), fill=bark_dark)
    # Root flare
    d.point((12, 28), fill=trunk_color)
    d.point((19, 28), fill=trunk_color)
    d.point((12, 29), fill=trunk_color)
    d.point((19, 29), fill=trunk_color)
    # Shadow at base
    for x in range(10, 22):
        d.point((x, 30), fill=(35, 80, 30, 255))
        d.point((x, 31), fill=(40, 85, 35, 255))
    return t


def draw_bush():
    t = draw_grass()  # Grass base
    d = ImageDraw.Draw(t)
    cx, cy = 16, 20
    for r in range(9, 0, -1):
        brightness = 50 + (9 - r) * 7
        color = (clamp(brightness - 10), clamp(brightness + 25), clamp(brightness - 15), 255)
        for y in range(TILE):
            for x in range(TILE):
                dx, dy = x - cx, (y - cy) * 1.3
                dist = math.sqrt(dx * dx + dy * dy) + random.random() * 2.5
                if dist < r:
                    d.point((x, y), fill=color)
    # Berry dots
    for _ in range(4):
        bx = cx + random.randint(-5, 5)
        by = cy + random.randint(-4, 3)
        d.point((bx, by), fill=(180, 50, 50, 255))
    return t


# ================================================================
#  BUILDING TILES
# ================================================================

def draw_brick():
    t = Image.new("RGBA", (TILE, TILE), (140, 65, 45, 255))
    d = ImageDraw.Draw(t)
    mortar = (180, 170, 150, 255)
    brick_h, brick_w = 6, 14
    for row in range(0, TILE, brick_h):
        offset = (brick_w // 2) if (row // brick_h) % 2 == 1 else 0
        # Horizontal mortar line
        for x in range(TILE):
            d.point((x, row), fill=mortar)
        # Vertical mortar lines
        for col in range(-offset, TILE + brick_w, brick_w):
            cx = col % TILE
            for y in range(row, min(row + brick_h, TILE)):
                d.point((cx % TILE, y), fill=mortar)
    # Brick color variation
    for _ in range(100):
        x, y = random.randint(0, 31), random.randint(0, 31)
        sv = random.choice([-15, -8, 8, 15])
        d.point((x, y), fill=(clamp(140 + sv), clamp(65 + sv), clamp(45 + sv), 255))
    return t


def draw_brick_dark():
    t = Image.new("RGBA", (TILE, TILE), (100, 45, 30, 255))
    d = ImageDraw.Draw(t)
    mortar = (140, 130, 115, 255)
    for row in range(0, TILE, 6):
        offset = 7 if (row // 6) % 2 == 1 else 0
        for x in range(TILE):
            d.point((x, row), fill=mortar)
        for col in range(-offset, TILE + 14, 14):
            for y in range(row, min(row + 6, TILE)):
                d.point((col % TILE, y), fill=mortar)
    noise_fill(d, (100, 45, 30), 12, 0.2)
    return t


def draw_metal_floor():
    t = Image.new("RGBA", (TILE, TILE), (80, 82, 90, 255))
    d = ImageDraw.Draw(t)
    # Grid pattern
    for x in range(0, TILE, 8):
        for y in range(TILE):
            d.point((x, y), fill=(65, 67, 75, 255))
    for y in range(0, TILE, 8):
        for x in range(TILE):
            d.point((x, y), fill=(65, 67, 75, 255))
    # Rivets at intersections
    for x in range(0, TILE, 8):
        for y in range(0, TILE, 8):
            d.point((x, y), fill=(100, 102, 110, 255))
            d.point((x + 1, y), fill=(95, 97, 105, 255))
            d.point((x, y + 1), fill=(95, 97, 105, 255))
    # Surface noise
    noise_fill(d, (80, 82, 90), 8, 0.15)
    return t


def draw_metal_wall():
    t = Image.new("RGBA", (TILE, TILE), (60, 62, 72, 255))
    d = ImageDraw.Draw(t)
    # Horizontal panel seams
    for y in [7, 15, 23]:
        for x in range(TILE):
            d.point((x, y), fill=(45, 47, 55, 255))
            d.point((x, y + 1), fill=(75, 77, 85, 255))
    # Rivets
    for y in [3, 11, 19, 27]:
        for x in [4, 12, 20, 28]:
            d.point((x, y), fill=(90, 92, 100, 255))
    # Top highlight
    for x in range(TILE):
        d.point((x, 0), fill=(80, 82, 92, 255))
    noise_fill(d, (60, 62, 72), 6, 0.1)
    return t


def draw_vault_wall():
    t = Image.new("RGBA", (TILE, TILE), (50, 52, 58, 255))
    d = ImageDraw.Draw(t)
    # Heavy reinforced panels
    d.rectangle([2, 2, 14, 14], fill=(55, 57, 63, 255), outline=(40, 42, 48, 255))
    d.rectangle([17, 2, 29, 14], fill=(55, 57, 63, 255), outline=(40, 42, 48, 255))
    d.rectangle([2, 17, 14, 29], fill=(55, 57, 63, 255), outline=(40, 42, 48, 255))
    d.rectangle([17, 17, 29, 29], fill=(55, 57, 63, 255), outline=(40, 42, 48, 255))
    # Bolts at corners
    for bx in [4, 12, 19, 27]:
        for by in [4, 12, 19, 27]:
            d.point((bx, by), fill=(85, 87, 95, 255))
    noise_fill(d, (50, 52, 58), 5, 0.08)
    return t


def draw_kremlin_wall():
    t = Image.new("RGBA", (TILE, TILE), (120, 35, 25, 255))
    d = ImageDraw.Draw(t)
    # Red brick with gold mortar (Kremlin style)
    mortar = (170, 150, 90, 255)
    for row in range(0, TILE, 5):
        offset = 7 if (row // 5) % 2 == 1 else 0
        for x in range(TILE):
            d.point((x, row), fill=mortar)
        for col in range(-offset, TILE + 14, 14):
            for y in range(row, min(row + 5, TILE)):
                d.point((col % TILE, y), fill=mortar)
    noise_fill(d, (120, 35, 25), 15, 0.2)
    # Crenellation hint at top
    for x in range(0, TILE, 6):
        d.rectangle([x, 0, x + 2, 3], fill=(100, 28, 18, 255))
    return t


def draw_marble_floor():
    t = Image.new("RGBA", (TILE, TILE), (210, 205, 200, 255))
    d = ImageDraw.Draw(t)
    # Veins
    for _ in range(3):
        vx, vy = random.randint(0, 31), random.randint(0, 31)
        for i in range(12):
            vx += random.choice([-1, 0, 1])
            vy += random.choice([-1, 0, 0, 1])
            vx = max(0, min(31, vx))
            vy = max(0, min(31, vy))
            d.point((vx, vy), fill=(185, 180, 175, 255))
    # Tile grid (subtle)
    for x in range(TILE):
        d.point((x, 15), fill=(195, 190, 185, 255))
        d.point((x, 16), fill=(220, 215, 210, 255))
    for y in range(TILE):
        d.point((15, y), fill=(195, 190, 185, 255))
        d.point((16, y), fill=(220, 215, 210, 255))
    noise_fill(d, (210, 205, 200), 8, 0.1)
    return t


def draw_marble_wall():
    t = Image.new("RGBA", (TILE, TILE), (195, 190, 185, 255))
    d = ImageDraw.Draw(t)
    # Shadow gradient at bottom
    for y in range(24, 32):
        darkness = (y - 24) * 3
        for x in range(TILE):
            d.point((x, y), fill=(clamp(195 - darkness), clamp(190 - darkness), clamp(185 - darkness), 255))
    # Highlight at top
    for x in range(TILE):
        d.point((x, 0), fill=(220, 215, 210, 255))
        d.point((x, 1), fill=(210, 205, 200, 255))
    # Veins
    for _ in range(2):
        vx, vy = random.randint(0, 31), random.randint(0, 31)
        for i in range(8):
            vx += random.choice([-1, 0, 1])
            vy += random.choice([-1, 0, 1])
            vx, vy = max(0, min(31, vx)), max(0, min(31, vy))
            d.point((vx, vy), fill=(175, 170, 165, 255))
    return t


def draw_wood_floor():
    t = Image.new("RGBA", (TILE, TILE), (130, 95, 55, 255))
    d = ImageDraw.Draw(t)
    # Planks (horizontal)
    plank_h = 8
    for row in range(0, TILE, plank_h):
        # Plank color variation
        sv = random.randint(-10, 10)
        base = (clamp(130 + sv), clamp(95 + sv), clamp(55 + sv), 255)
        d.rectangle([0, row, 31, row + plank_h - 1], fill=base)
        # Grain lines
        for y in range(row + 2, min(row + plank_h - 1, TILE)):
            gx = random.randint(0, 31)
            for i in range(random.randint(3, 8)):
                nx = gx + i
                if 0 <= nx < 32:
                    d.point((nx, y), fill=shade(base, -12))
        # Plank separator (dark line + highlight)
        for x in range(TILE):
            d.point((x, row), fill=(100, 72, 40, 255))
            if row + 1 < TILE:
                d.point((x, row + 1), fill=(145, 108, 65, 255))
    # Knots
    for _ in range(2):
        kx, ky = random.randint(4, 27), random.randint(4, 27)
        d.ellipse([kx - 2, ky - 1, kx + 2, ky + 1], fill=(105, 75, 42, 255))
    return t


# ================================================================
#  INTERIOR/FURNITURE TILES
# ================================================================

def draw_desk_wood():
    t = draw_wood_floor()  # Wood base
    d = ImageDraw.Draw(t)
    # Desk surface (darker, polished)
    d.rectangle([2, 6, 29, 25], fill=(95, 68, 38, 255))
    d.rectangle([3, 7, 28, 24], fill=(115, 82, 48, 255))
    # Edge highlight
    for x in range(3, 29):
        d.point((x, 7), fill=(135, 100, 60, 255))
    # Drawer line
    for x in range(5, 27):
        d.point((x, 15), fill=(90, 65, 35, 255))
    # Handle
    d.point((15, 16), fill=(170, 160, 130, 255))
    d.point((16, 16), fill=(170, 160, 130, 255))
    return t


def draw_desk_metal():
    t = draw_metal_floor()
    d = ImageDraw.Draw(t)
    d.rectangle([2, 6, 29, 25], fill=(90, 92, 100, 255))
    d.rectangle([3, 7, 28, 24], fill=(100, 102, 112, 255))
    for x in range(3, 29):
        d.point((x, 7), fill=(120, 122, 130, 255))
    for x in range(5, 27):
        d.point((x, 15), fill=(75, 77, 85, 255))
    d.point((15, 16), fill=(150, 152, 160, 255))
    d.point((16, 16), fill=(150, 152, 160, 255))
    return t


def draw_server():
    t = draw_metal_floor()
    d = ImageDraw.Draw(t)
    # Server rack
    d.rectangle([4, 2, 27, 29], fill=(35, 38, 45, 255))
    d.rectangle([5, 3, 26, 28], fill=(42, 45, 52, 255))
    # Rack units
    for uy in range(4, 27, 5):
        d.rectangle([6, uy, 25, uy + 3], fill=(48, 52, 60, 255))
        # Status LEDs
        d.point((8, uy + 1), fill=(50, 200, 80, 255))   # Green
        d.point((10, uy + 1), fill=(50, 200, 80, 255))   # Green
        d.point((12, uy + 1), fill=(200, 180, 50, 255))  # Amber
        # Vent slots
        for vx in range(16, 24, 2):
            d.point((vx, uy + 1), fill=(30, 32, 38, 255))
    return t


def draw_bookshelf():
    t = Image.new("RGBA", (TILE, TILE), (75, 52, 28, 255))
    d = ImageDraw.Draw(t)
    # Shelves
    shelf_h = 8
    book_colors = [
        (160, 40, 40, 255), (40, 60, 140, 255), (40, 120, 60, 255),
        (140, 100, 40, 255), (100, 40, 120, 255), (180, 140, 60, 255),
        (60, 60, 80, 255), (140, 80, 40, 255), (80, 120, 140, 255),
    ]
    for row in range(0, TILE, shelf_h):
        # Shelf plank
        for x in range(TILE):
            d.point((x, row), fill=(60, 42, 22, 255))
            if row + 1 < TILE:
                d.point((x, row + 1), fill=(90, 65, 38, 255))
        # Books
        bx = 2
        while bx < 30:
            bw = random.randint(2, 4)
            bh = random.randint(4, 6)
            bc = random.choice(book_colors)
            by = row + shelf_h - bh
            d.rectangle([bx, by, bx + bw - 1, row + shelf_h - 1], fill=bc)
            # Spine highlight
            d.line([(bx, by), (bx, row + shelf_h - 1)], fill=shade(bc, 25))
            bx += bw + 1
    return t


def draw_gold():
    t = draw_marble_floor()
    d = ImageDraw.Draw(t)
    # Gold bars stacked
    bar_color = (200, 170, 50, 255)
    bar_highlight = (240, 210, 80, 255)
    bar_shadow = (150, 125, 35, 255)
    # Bottom row
    for i in range(3):
        bx = 4 + i * 9
        d.rectangle([bx, 18, bx + 7, 25], fill=bar_color)
        d.line([(bx, 18), (bx + 7, 18)], fill=bar_highlight)
        d.line([(bx, 25), (bx + 7, 25)], fill=bar_shadow)
    # Top row (offset)
    for i in range(2):
        bx = 8 + i * 9
        d.rectangle([bx, 10, bx + 7, 17], fill=bar_color)
        d.line([(bx, 10), (bx + 7, 10)], fill=bar_highlight)
        d.line([(bx, 17), (bx + 7, 17)], fill=bar_shadow)
    # Scattered coins
    for _ in range(5):
        cx, cy = random.randint(3, 28), random.randint(22, 29)
        d.ellipse([cx - 1, cy, cx + 1, cy + 1], fill=(210, 180, 60, 255))
    return t


def draw_flag():
    t = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    # Pole
    d.line([(6, 2), (6, 30)], fill=(160, 150, 130, 255))
    d.point((6, 2), fill=(200, 190, 50, 255))  # Finial
    # Flag (waving)
    for y in range(4, 18):
        wave = int(2 * math.sin((y - 4) * 0.5))
        x_start = 8 + wave
        flag_w = 18
        # Three stripes (generic)
        stripe_h = 5
        if (y - 4) < stripe_h:
            color = (40, 60, 140, 255)
        elif (y - 4) < stripe_h * 2:
            color = (220, 220, 220, 255)
        else:
            color = (180, 40, 40, 255)
        d.line([(x_start, y), (x_start + flag_w, y)], fill=color)
    return t


def draw_carpet_red():
    t = Image.new("RGBA", (TILE, TILE), (140, 35, 30, 255))
    d = ImageDraw.Draw(t)
    # Border pattern
    d.rectangle([0, 0, 31, 31], outline=(170, 140, 50, 255))
    d.rectangle([2, 2, 29, 29], outline=(170, 140, 50, 255))
    # Inner pattern
    noise_fill(d, (140, 35, 30), 10, 0.15)
    # Center motif
    d.rectangle([12, 12, 19, 19], outline=(170, 140, 50, 255))
    return t


def draw_carpet_blue():
    t = Image.new("RGBA", (TILE, TILE), (30, 45, 110, 255))
    d = ImageDraw.Draw(t)
    d.rectangle([0, 0, 31, 31], outline=(140, 130, 50, 255))
    d.rectangle([2, 2, 29, 29], outline=(140, 130, 50, 255))
    noise_fill(d, (30, 45, 110), 10, 0.15)
    d.rectangle([12, 12, 19, 19], outline=(140, 130, 50, 255))
    return t


def draw_tile_floor():
    t = Image.new("RGBA", (TILE, TILE), (180, 175, 165, 255))
    d = ImageDraw.Draw(t)
    # Checkerboard tiles
    for ty in range(0, TILE, 16):
        for tx in range(0, TILE, 16):
            if ((tx + ty) // 16) % 2 == 0:
                d.rectangle([tx, ty, tx + 15, ty + 15], fill=(160, 155, 145, 255))
    # Grout lines
    for x in range(TILE):
        d.point((x, 15), fill=(140, 135, 125, 255))
        d.point((x, 16), fill=(190, 185, 175, 255))
    for y in range(TILE):
        d.point((15, y), fill=(140, 135, 125, 255))
        d.point((16, y), fill=(190, 185, 175, 255))
    return t


def draw_window():
    t = draw_marble_wall()
    d = ImageDraw.Draw(t)
    # Window frame
    d.rectangle([6, 4, 25, 27], fill=(120, 115, 110, 255))
    # Glass
    d.rectangle([8, 6, 23, 25], fill=(140, 170, 200, 255))
    # Reflection
    d.line([(10, 8), (14, 8)], fill=(180, 210, 235, 255))
    d.line([(10, 9), (12, 9)], fill=(170, 200, 225, 255))
    # Crossbar
    d.line([(8, 15), (23, 15)], fill=(130, 125, 120, 255))
    d.line([(15, 6), (15, 25)], fill=(130, 125, 120, 255))
    return t


def draw_door():
    t = draw_marble_wall()
    d = ImageDraw.Draw(t)
    d.rectangle([8, 4, 23, 31], fill=(95, 68, 38, 255))
    d.rectangle([9, 5, 22, 30], fill=(110, 80, 45, 255))
    # Panels
    d.rectangle([10, 6, 21, 14], outline=(95, 68, 38, 255))
    d.rectangle([10, 17, 21, 28], outline=(95, 68, 38, 255))
    # Handle
    d.point((20, 20), fill=(190, 170, 100, 255))
    d.point((20, 21), fill=(190, 170, 100, 255))
    return t


# ================================================================
#  DECORATION / PROPS
# ================================================================

def draw_flower_patch():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    colors = [(220, 60, 60, 255), (230, 200, 50, 255), (200, 100, 200, 255),
              (255, 150, 50, 255), (100, 150, 230, 255)]
    for _ in range(10):
        fx, fy = random.randint(4, 27), random.randint(4, 27)
        c = random.choice(colors)
        d.point((fx, fy), fill=c)
        d.point((fx + 1, fy), fill=c)
        d.point((fx, fy + 1), fill=c)
        # Stem
        d.point((fx, fy + 2), fill=(40, 90, 35, 255))
    return t


def draw_rock():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    # Large rock
    rock_base = (130, 125, 115, 255)
    rock_high = (155, 150, 140, 255)
    rock_dark = (100, 95, 85, 255)
    d.ellipse([8, 12, 24, 24], fill=rock_base)
    # Highlight
    for x in range(10, 18):
        d.point((x, 14), fill=rock_high)
    # Shadow
    for x in range(12, 24):
        d.point((x, 23), fill=rock_dark)
    noise_fill(d, (130, 125, 115), 10, 0.05)
    return t


def draw_lamp_post():
    t = draw_path()
    d = ImageDraw.Draw(t)
    # Pole
    d.line([(16, 8), (16, 30)], fill=(80, 80, 85, 255))
    d.line([(15, 8), (15, 30)], fill=(90, 90, 95, 255))
    # Lamp
    d.rectangle([12, 3, 19, 8], fill=(100, 95, 85, 255))
    d.rectangle([13, 4, 18, 7], fill=(240, 220, 140, 255))
    # Light glow
    for r in range(4, 8):
        alpha = max(0, 60 - r * 10)
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    px, py = 15 + dx, 5 + dy
                    if 0 <= px < 32 and 0 <= py < 32:
                        existing = t.getpixel((px, py))
                        blended = (
                            min(255, existing[0] + alpha),
                            min(255, existing[1] + alpha - 10),
                            min(255, existing[2] + alpha - 30),
                            255
                        )
                        d.point((px, py), fill=blended)
    return t


def draw_bench():
    t = draw_path()
    d = ImageDraw.Draw(t)
    # Bench seat
    d.rectangle([4, 14, 27, 18], fill=(110, 80, 45, 255))
    d.line([(4, 14), (27, 14)], fill=(130, 95, 55, 255))
    # Legs
    d.rectangle([6, 19, 8, 24], fill=(70, 70, 75, 255))
    d.rectangle([23, 19, 25, 24], fill=(70, 70, 75, 255))
    # Back
    d.rectangle([4, 10, 27, 13], fill=(100, 72, 40, 255))
    d.line([(4, 10), (27, 10)], fill=(120, 88, 50, 255))
    return t


def draw_filing_cabinet():
    t = draw_tile_floor()
    d = ImageDraw.Draw(t)
    d.rectangle([6, 4, 25, 28], fill=(120, 120, 125, 255))
    d.rectangle([7, 5, 24, 27], fill=(130, 130, 135, 255))
    # Drawers
    for dy in [6, 13, 20]:
        d.rectangle([8, dy, 23, dy + 5], outline=(110, 110, 115, 255))
        d.point((15, dy + 2), fill=(170, 165, 140, 255))
        d.point((16, dy + 2), fill=(170, 165, 140, 255))
    return t


def draw_potted_plant():
    t = draw_tile_floor()
    d = ImageDraw.Draw(t)
    # Pot
    d.rectangle([11, 22, 20, 28], fill=(160, 85, 45, 255))
    d.line([(10, 22), (21, 22)], fill=(145, 75, 38, 255))
    # Plant
    leaves = (50, 120, 45, 255)
    for _ in range(12):
        lx = 16 + random.randint(-7, 7)
        ly = 16 + random.randint(-8, 4)
        d.point((lx, ly), fill=leaves)
        d.point((lx + 1, ly), fill=shade(leaves, 10))
    # Stem
    d.line([(16, 18), (16, 22)], fill=(60, 90, 40, 255))
    return t


def draw_clock():
    t = draw_marble_wall()
    d = ImageDraw.Draw(t)
    cx, cy = 16, 14
    # Frame
    d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=(60, 55, 48, 255))
    d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(230, 225, 215, 255))
    # Hour markers
    for h in range(12):
        angle = h * 30 - 90
        mx = cx + int(5 * math.cos(math.radians(angle)))
        my = cy + int(5 * math.sin(math.radians(angle)))
        d.point((mx, my), fill=(40, 35, 30, 255))
    # Hands
    d.line([(cx, cy), (cx + 3, cy - 2)], fill=(40, 35, 30, 255))
    d.line([(cx, cy), (cx - 1, cy - 4)], fill=(40, 35, 30, 255))
    return t


def draw_metal_panel():
    t = Image.new("RGBA", (TILE, TILE), (70, 72, 80, 255))
    d = ImageDraw.Draw(t)
    d.rectangle([1, 1, 30, 30], fill=(75, 77, 85, 255))
    d.line([(1, 1), (30, 1)], fill=(90, 92, 100, 255))
    d.line([(1, 30), (30, 30)], fill=(55, 57, 65, 255))
    noise_fill(d, (75, 77, 85), 5, 0.08)
    return t


def draw_vault_door():
    t = draw_vault_wall()
    d = ImageDraw.Draw(t)
    d.ellipse([6, 6, 25, 25], fill=(65, 67, 73, 255))
    d.ellipse([8, 8, 23, 23], fill=(55, 57, 63, 255))
    # Handle wheel
    d.ellipse([12, 12, 19, 19], outline=(90, 92, 100, 255))
    d.point((15, 12), fill=(100, 102, 110, 255))
    d.point((15, 19), fill=(100, 102, 110, 255))
    d.point((12, 15), fill=(100, 102, 110, 255))
    d.point((19, 15), fill=(100, 102, 110, 255))
    return t


def draw_concrete():
    t = Image.new("RGBA", (TILE, TILE), (160, 155, 148, 255))
    d = ImageDraw.Draw(t)
    noise_fill(d, (160, 155, 148), 12, 0.25)
    for _ in range(2):
        cx = random.randint(5, 26)
        cy = random.randint(5, 26)
        for i in range(5):
            d.point((cx + random.choice([-1, 0, 1]), cy + i), fill=(140, 135, 128, 255))
    return t


# ================================================================
#  EDGES / TRANSITIONS
# ================================================================

def draw_water_edge_top():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    for y in range(16, 32):
        for x in range(32):
            if y > 18 or (y == 16 and random.random() < 0.3) or (y == 17 and random.random() < 0.6):
                d.point((x, y), fill=(30, 60, 120, 255))
    # Shore line
    for x in range(32):
        d.point((x, 17), fill=(140, 130, 100, 255))
        d.point((x, 18), fill=(120, 110, 85, 255))
    return t


def draw_water_edge_left():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    for x in range(16, 32):
        for y in range(32):
            d.point((x, y), fill=(30, 60, 120, 255))
    for y in range(32):
        d.point((16, y), fill=(140, 130, 100, 255))
        d.point((17, y), fill=(120, 110, 85, 255))
    return t


def draw_water_edge_right():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    for x in range(0, 16):
        for y in range(32):
            d.point((x, y), fill=(30, 60, 120, 255))
    for y in range(32):
        d.point((15, y), fill=(140, 130, 100, 255))
        d.point((14, y), fill=(120, 110, 85, 255))
    return t


def draw_water_edge_bottom():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    for y in range(0, 16):
        for x in range(32):
            d.point((x, y), fill=(30, 60, 120, 255))
    for x in range(32):
        d.point((x, 15), fill=(140, 130, 100, 255))
        d.point((x, 14), fill=(120, 110, 85, 255))
    return t


def draw_path_edge_h():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    for y in range(10, 22):
        for x in range(32):
            d.point((x, y), fill=(150, 140, 120, 255))
    for x in range(32):
        d.point((x, 10), fill=(130, 122, 105, 255))
        d.point((x, 21), fill=(130, 122, 105, 255))
    noise_fill(d, (150, 140, 120), 12, 0.1)
    return t


def draw_path_edge_v():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    for x in range(10, 22):
        for y in range(32):
            d.point((x, y), fill=(150, 140, 120, 255))
    for y in range(32):
        d.point((10, y), fill=(130, 122, 105, 255))
        d.point((21, y), fill=(130, 122, 105, 255))
    noise_fill(d, (150, 140, 120), 12, 0.1)
    return t


def draw_path_corner():
    t = draw_grass()
    d = ImageDraw.Draw(t)
    for x in range(10, 32):
        for y in range(10, 32):
            d.point((x, y), fill=(150, 140, 120, 255))
    noise_fill(d, (150, 140, 120), 12, 0.08)
    return t


def draw_path_cross():
    t = draw_path()
    return t


# ================================================================
#  ROOF / FACADE / URBAN
# ================================================================

def draw_roof_red():
    t = Image.new("RGBA", (TILE, TILE), (155, 55, 40, 255))
    d = ImageDraw.Draw(t)
    for y in range(0, TILE, 4):
        offset = 4 if (y // 4) % 2 == 1 else 0
        for x in range(offset, TILE + 8, 8):
            d.arc([x - 4, y, x + 4, y + 5], 0, 180, fill=(135, 45, 32, 255))
    noise_fill(d, (155, 55, 40), 10, 0.1)
    return t


def draw_roof_gray():
    t = Image.new("RGBA", (TILE, TILE), (110, 112, 118, 255))
    d = ImageDraw.Draw(t)
    for y in range(0, TILE, 3):
        for x in range(TILE):
            d.point((x, y), fill=(95, 97, 103, 255))
    noise_fill(d, (110, 112, 118), 8, 0.1)
    return t


def draw_roof_gold():
    t = Image.new("RGBA", (TILE, TILE), (180, 155, 50, 255))
    d = ImageDraw.Draw(t)
    for y in range(0, TILE, 4):
        for x in range(TILE):
            d.point((x, y), fill=(160, 138, 40, 255))
    noise_fill(d, (180, 155, 50), 12, 0.12)
    return t


def draw_chimney():
    t = draw_roof_red()
    d = ImageDraw.Draw(t)
    d.rectangle([10, 4, 21, 24], fill=(120, 60, 42, 255))
    d.rectangle([11, 5, 20, 23], fill=(135, 68, 48, 255))
    # Smoke
    d.point((15, 2), fill=(180, 180, 180, 128))
    d.point((16, 1), fill=(190, 190, 190, 96))
    return t


def draw_entrance_mat():
    t = draw_path()
    d = ImageDraw.Draw(t)
    d.rectangle([6, 10, 25, 21], fill=(80, 60, 40, 255))
    d.rectangle([7, 11, 24, 20], fill=(90, 70, 48, 255))
    d.rectangle([8, 12, 23, 19], outline=(70, 52, 32, 255))
    return t


def draw_stairs():
    t = Image.new("RGBA", (TILE, TILE), (160, 155, 145, 255))
    d = ImageDraw.Draw(t)
    step_h = 5
    for i, y in enumerate(range(0, TILE, step_h)):
        brightness = 140 + i * 4
        d.rectangle([0, y, 31, y + step_h - 1], fill=(brightness, brightness - 5, brightness - 15, 255))
        d.line([(0, y), (31, y)], fill=(brightness + 15, brightness + 10, brightness, 255))
        d.line([(0, y + step_h - 1), (31, y + step_h - 1)], fill=(brightness - 20, brightness - 25, brightness - 30, 255))
    return t


def draw_column():
    t = draw_marble_floor()
    d = ImageDraw.Draw(t)
    col_color = (185, 180, 172, 255)
    d.rectangle([10, 4, 21, 27], fill=col_color)
    # Top capital
    d.rectangle([8, 4, 23, 7], fill=shade(col_color, 10))
    # Base
    d.rectangle([8, 24, 23, 27], fill=shade(col_color, -10))
    # Fluting
    for y in range(8, 24):
        d.point((12, y), fill=shade(col_color, -15))
        d.point((15, y), fill=shade(col_color, -15))
        d.point((19, y), fill=shade(col_color, -15))
    # Highlights
    d.line([(13, 8), (13, 23)], fill=shade(col_color, 15))
    d.line([(17, 8), (17, 23)], fill=shade(col_color, 15))
    return t


def draw_fountain():
    t = draw_path()
    d = ImageDraw.Draw(t)
    # Basin
    d.ellipse([4, 8, 27, 27], fill=(140, 140, 150, 255))
    d.ellipse([6, 10, 25, 25], fill=(50, 80, 140, 255))
    # Water highlights
    d.point((14, 16), fill=(80, 120, 180, 255))
    d.point((18, 18), fill=(80, 120, 180, 255))
    # Center spout
    d.rectangle([14, 12, 17, 18], fill=(150, 148, 142, 255))
    # Water spray
    d.point((15, 10), fill=(120, 160, 210, 200))
    d.point((16, 9), fill=(120, 160, 210, 150))
    d.point((14, 11), fill=(120, 160, 210, 180))
    d.point((17, 11), fill=(120, 160, 210, 180))
    return t


# ================================================================
#  URBAN PROPS (Row 7)
# ================================================================

def draw_sign_post():
    t = draw_path()
    d = ImageDraw.Draw(t)
    d.line([(16, 10), (16, 30)], fill=(90, 85, 78, 255))
    d.rectangle([6, 4, 26, 12], fill=(40, 55, 80, 255))
    d.rectangle([7, 5, 25, 11], fill=(50, 65, 95, 255))
    # Text line
    for x in range(9, 24, 2):
        d.point((x, 8), fill=(200, 200, 210, 255))
    return t


def draw_trash_can():
    t = draw_path()
    d = ImageDraw.Draw(t)
    d.rectangle([10, 12, 21, 26], fill=(80, 85, 90, 255))
    d.rectangle([9, 10, 22, 13], fill=(90, 95, 100, 255))
    d.line([(10, 26), (21, 26)], fill=(65, 70, 75, 255))
    # Lid
    d.rectangle([8, 8, 23, 11], fill=(95, 100, 105, 255))
    d.line([(14, 8), (17, 8)], fill=(110, 115, 120, 255))
    return t


def draw_mailbox():
    t = draw_path()
    d = ImageDraw.Draw(t)
    d.rectangle([10, 8, 21, 26], fill=(40, 55, 140, 255))
    d.rectangle([11, 9, 20, 25], fill=(50, 65, 155, 255))
    # Slot
    d.line([(12, 15), (19, 15)], fill=(30, 40, 80, 255))
    # Stand
    d.rectangle([14, 26, 17, 30], fill=(80, 80, 85, 255))
    return t


def draw_barrier():
    t = draw_path()
    d = ImageDraw.Draw(t)
    # Posts
    d.rectangle([4, 10, 7, 26], fill=(190, 60, 50, 255))
    d.rectangle([24, 10, 27, 26], fill=(190, 60, 50, 255))
    # Bar
    d.rectangle([4, 14, 27, 18], fill=(200, 200, 200, 255))
    d.rectangle([4, 18, 27, 22], fill=(190, 60, 50, 255))
    return t


def draw_manhole():
    t = draw_path()
    d = ImageDraw.Draw(t)
    d.ellipse([6, 6, 25, 25], fill=(100, 98, 90, 255))
    d.ellipse([8, 8, 23, 23], fill=(110, 108, 100, 255))
    # Cross pattern
    d.line([(10, 15), (21, 15)], fill=(95, 93, 85, 255))
    d.line([(15, 10), (15, 21)], fill=(95, 93, 85, 255))
    return t


def draw_grate():
    t = Image.new("RGBA", (TILE, TILE), (60, 58, 55, 255))
    d = ImageDraw.Draw(t)
    for x in range(2, 30, 4):
        d.line([(x, 2), (x, 29)], fill=(80, 78, 75, 255))
    for y in range(2, 30, 4):
        d.line([(2, y), (29, y)], fill=(80, 78, 75, 255))
    # Dark gaps
    for x in range(4, 28, 4):
        for y in range(4, 28, 4):
            d.point((x, y), fill=(25, 22, 20, 255))
    return t


def draw_shadow_overlay():
    t = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 60))
    return t


def draw_light_overlay():
    t = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    cx, cy = 16, 16
    for y in range(TILE):
        for x in range(TILE):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if dist < 16:
                alpha = int(40 * (1.0 - dist / 16.0))
                d.point((x, y), fill=(255, 240, 200, alpha))
    return t


# ================================================================
#  MAIN
# ================================================================

if __name__ == "__main__":
    import os
    tileset = make_tileset()
    out_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "tiles", "world_tiles.png")
    tileset.save(out_path)
    print(f"Tileset saved to: {out_path}")
    print(f"Size: {tileset.size[0]}x{tileset.size[1]}")
