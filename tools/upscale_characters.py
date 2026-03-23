"""
Upscale 16x16-grid character spritesheets to 32x32-grid using nearest-neighbor.
Characters are 16x32 (1 tile wide, 2 tiles tall) -> become 32x64.
"""
from PIL import Image
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(BASE, "assets", "packs", "civic_nightmare", "characters", "modern_office_16x16")
OUT = os.path.join(BASE, "assets", "characters")

os.makedirs(OUT, exist_ok=True)

# Characters and their animation sheets
CHARACTERS = ["Adam", "Alex", "Amelia", "Bob"]
SHEETS = [
    "{name}_16x16.png",          # walk
    "{name}_idle_anim_16x16.png", # idle anim
    "{name}_run_16x16.png",       # run
    "{name}_idle_16x16.png",      # idle static
]

for char in CHARACTERS:
    for pattern in SHEETS:
        filename = pattern.format(name=char)
        src_path = os.path.join(SRC, filename)
        if not os.path.exists(src_path):
            print(f"SKIP  {filename}: not found")
            continue
        img = Image.open(src_path)
        w, h = img.size
        up = img.resize((w * 2, h * 2), Image.NEAREST)
        # Output name: e.g. Adam_walk_32.png, Adam_idle_anim_32.png
        out_name = filename.replace("_16x16", "_32")
        out_path = os.path.join(OUT, out_name)
        up.save(out_path)
        print(f"OK    {out_name}: {w}x{h} -> {w*2}x{h*2}")

print("\nDone. Open the Godot editor to trigger reimport.")
