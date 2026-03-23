"""
Upscale 16x16 pack tilesets to 32x32 using nearest-neighbor.
This preserves pixel-art crispness and matches the game's 32x32 tile grid.
"""
from PIL import Image
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACK = os.path.join(BASE, "assets", "packs", "civic_nightmare", "tilesets")
OUT = os.path.join(BASE, "assets", "tiles")

SOURCES = {
    "nature_32":        os.path.join(PACK, "overworld_ninja", "TilesetNature.png"),
    "field_32":         os.path.join(PACK, "overworld_ninja", "TilesetField.png"),
    "water_32":         os.path.join(PACK, "overworld_ninja", "TilesetWater.png"),
    "floor_32":         os.path.join(PACK, "overworld_ninja", "TilesetFloor.png"),
    "house_32":         os.path.join(PACK, "overworld_ninja", "TilesetHouse.png"),
    "interior_floor_32": os.path.join(PACK, "interiors_ninja", "TilesetInteriorFloor.png"),
    "interior_wall_32": os.path.join(PACK, "interiors_ninja", "TilesetInterior.png"),
    "modern_interior_32": os.path.join(PACK, "interiors_modern_free", "Interiors_free_16x16.png"),
    "room_builder_32":  os.path.join(PACK, "interiors_modern_free", "Room_Builder_free_16x16.png"),
}

for name, path in SOURCES.items():
    if not os.path.exists(path):
        print(f"SKIP  {name}: source not found at {path}")
        continue
    img = Image.open(path)
    w, h = img.size
    up = img.resize((w * 2, h * 2), Image.NEAREST)
    out_path = os.path.join(OUT, f"{name}.png")
    up.save(out_path)
    print(f"OK    {name}: {w}x{h} -> {w*2}x{h*2}  =>  {out_path}")

print("\nDone. Open the Godot editor to trigger reimport.")
