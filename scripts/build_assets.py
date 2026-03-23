import os
from PIL import Image, ImageDraw

def chroma_key(input_path, output_path):
    if not os.path.exists(input_path):
        return
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    new_data = []
    for item in data:
        # Green background removal
        if item[1] > item[0] + 30 and item[1] > item[2] + 30 and item[1] > 100:
            new_data.append((0, 0, 0, 0))
        # White removal (sometimes borders)
        elif item[0] > 230 and item[1] > 230 and item[2] > 230:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Processed {output_path}")

files = [
    (r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\musk_pure_sprite_1774291902786.png", "assets/mockups/musk_pure_sprite.png"),
    (r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\vdl_pure_sprite_1774291917085.png", "assets/mockups/vdl_pure_sprite.png"),
    (r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\lagarde_pure_sprite_1774291933026.png", "assets/mockups/lagarde_pure_sprite.png")
]
for p_in, p_out in files:
    chroma_key(p_in, p_out)

# GENERATE THE RPG TILESET
def draw_rpg_tiles():
    img = Image.new("RGBA", (128, 128), (0,0,0,0)) # 4x4 grid
    draw = ImageDraw.Draw(img)

    # 1. Grass (0,0)
    draw.rectangle([0,0,31,31], fill=(50, 160, 50))
    draw.point([(5,5), (20,10), (15,25), (28,28), (4,28), (28,4)], fill=(30, 120, 30))

    # 2. Wood Floor (1,0) (offset x=32)
    draw.rectangle([32,0,63,31], fill=(139, 69, 19))
    draw.rectangle([32,0,63,31], outline=(100, 40, 10))
    draw.line([32,10, 63,10], fill=(100, 40, 10))
    draw.line([32,20, 63,20], fill=(100, 40, 10))

    # 3. Path Cobblestone (2,0) (offset x=64)
    draw.rectangle([64,0,95,31], fill=(100, 100, 100))
    for x in range(64, 96, 8):
        for y in range(0, 32, 8):
            draw.rectangle([x+1, y+1, x+6, y+6], fill=(130, 130, 130))

    # 4. Brick Wall (0,1) (offset y=32)
    draw.rectangle([0,32,31,63], fill=(150, 40, 40))
    for y in range(32, 64, 8):
        draw.line([0, y, 31, y], fill=(100, 20, 20))
    for x in range(0, 32, 8): # Vertical mortar
        draw.line([x, 32, x, 63], fill=(100, 20, 20))
        
    img.save("assets/tiles/world_tiles.png", "PNG")
    print("Tileset generated.")

draw_rpg_tiles()
