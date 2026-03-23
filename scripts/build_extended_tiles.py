import os
from PIL import Image, ImageDraw

def draw_rpg_tiles():
    # Expanding to a 4x4 grid (128x128 pixels, each tile is 32x32)
    img = Image.new("RGBA", (128, 128), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # 0,0: Grass
    draw.rectangle([0,0,31,31], fill=(50, 160, 50))
    draw.point([(5,5), (20,10), (15,25), (28,28), (4,28), (28,4)], fill=(30, 120, 30))

    # 1,0: Wood Floor
    draw.rectangle([32,0,63,31], fill=(139, 69, 19))
    draw.rectangle([32,0,63,31], outline=(100, 40, 10))
    draw.line([32,10, 63,10], fill=(100, 40, 10))
    draw.line([32,20, 63,20], fill=(100, 40, 10))

    # 2,0: Cobblestone Path
    draw.rectangle([64,0,95,31], fill=(100, 100, 100))
    for x in range(64, 96, 8):
        for y in range(0, 32, 8):
            draw.rectangle([x+1, y+1, x+6, y+6], fill=(130, 130, 130))

    # 0,1: Red Brick Wall (Oval Office / Standard)
    draw.rectangle([0,32,31,63], fill=(150, 40, 40))
    for y in range(32, 64, 8):
        draw.line([0, y, 31, y], fill=(100, 20, 20))
    for x in range(0, 32, 8):
        draw.line([x, 32, x, 63], fill=(100, 20, 20))

    # 1,1: Metal / Spaceship Floor (Musk)
    draw.rectangle([32,32,63,63], fill=(200, 200, 200))
    draw.rectangle([32,32,63,63], outline=(150, 150, 150))
    draw.rectangle([36,36,59,59], fill=(180, 180, 190))
    draw.line([32,32, 63,63], fill=(150, 150, 150))
    
    # 2,1: Metal Spaceship Wall (Musk)
    draw.rectangle([64,32,95,63], fill=(120, 130, 140))
    draw.rectangle([64,32,95,63], outline=(80, 90, 100))
    draw.line([64,48, 95,48], fill=(80, 90, 100)) # Panels
    
    # 0,2: Bank Vault Gold Wall (Lagarde)
    draw.rectangle([0,64,31,95], fill=(255, 215, 0)) # Gold base
    draw.rectangle([4,68,27,91], fill=(218, 165, 32), outline=(184, 134, 11)) # Safe door panel
    draw.ellipse([12,76,20,84], fill=(100,100,100)) # vault wheel
    
    # 1,2: Kremlin Dark Red/Grey Stone (Putin)
    draw.rectangle([32,64,63,95], fill=(100, 20, 20))
    for y in range(64, 96, 16):
        draw.line([32, y, 63, y], fill=(50, 10, 10))
    for x in range(32, 64, 16):
        draw.line([x, 64, x, 95], fill=(50, 10, 10))

    # 2,2: White Palace Marble Floor (Macron/VdL)
    draw.rectangle([64,64,95,95], fill=(240, 240, 245))
    draw.rectangle([64,64,95,95], outline=(200, 200, 210))
    for x in range(64, 96, 16):
        for y in range(64, 96, 16):
            draw.rectangle([x, y, x+15, y+15], outline=(220, 220, 230))
            
    # 3,2: White Palace Marble Wall
    draw.rectangle([96,64,127,95], fill=(230, 230, 240))
    draw.line([96,80, 127,80], fill=(200, 200, 210)) # Column trim
    draw.line([104,64, 104,95], fill=(255, 255, 255)) # Column ridge
    draw.line([120,64, 120,95], fill=(255, 255, 255)) # Column ridge

    img.save("assets/tiles/world_tiles.png", "PNG")
    print("Expanded RPG tileset generated.")

if __name__ == "__main__":
    draw_rpg_tiles()
