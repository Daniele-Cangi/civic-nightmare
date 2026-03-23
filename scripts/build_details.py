import os
from PIL import Image, ImageDraw

def draw_rpg_tiles():
    # Expanding to an 8x8 grid (256x256 pixels, each tile is 32x32)
    img = Image.new("RGBA", (256, 256), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # --- BASE TERRAINS (Row 0) ---
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
    # 3,0: Water
    draw.rectangle([96,0,127,31], fill=(40, 100, 200))
    draw.line([100,10, 105,10], fill=(80, 150, 255))
    draw.line([115,20, 120,20], fill=(80, 150, 255))

    # --- WALLS (Row 1) ---
    # 0,1: Red Brick Wall
    draw.rectangle([0,32,31,63], fill=(150, 40, 40))
    for y in range(32, 64, 8):
        draw.line([0, y, 31, y], fill=(100, 20, 20))
    for x in range(0, 32, 8):
        draw.line([x, 32, x, 63], fill=(100, 20, 20))
    # 1,1: Metal / Spaceship Floor
    draw.rectangle([32,32,63,63], fill=(200, 200, 200))
    draw.rectangle([32,32,63,63], outline=(150, 150, 150))
    draw.rectangle([36,36,59,59], fill=(180, 180, 190))
    # 2,1: Metal Spaceship Wall
    draw.rectangle([64,32,95,63], fill=(120, 130, 140))
    draw.rectangle([64,32,95,63], outline=(80, 90, 100))
    draw.line([64,48, 95,48], fill=(80, 90, 100))
    # 3,1: Bank Vault Gold Wall
    draw.rectangle([96,32,127,63], fill=(255, 215, 0))
    draw.rectangle([100,36,123,59], fill=(218, 165, 32), outline=(184, 134, 11))
    draw.ellipse([108,44,116,52], fill=(100,100,100))

    # --- MORE WALLS/FLOORS (Row 2) ---
    # 0,2: Kremlin Dark Red Wall
    draw.rectangle([0,64,31,95], fill=(100, 20, 20))
    for y in range(64, 96, 16):
        draw.line([0, y, 31, y], fill=(50, 10, 10))
    for x in range(0, 32, 16):
        draw.line([x, 64, x, 95], fill=(50, 10, 10))
    # 1,2: White Palace Marble Floor
    draw.rectangle([32,64,63,95], fill=(240, 240, 245))
    draw.rectangle([32,64,63,95], outline=(200, 200, 210))
    for x in range(32, 64, 16):
        for y in range(64, 96, 16):
            draw.rectangle([x, y, x+15, y+15], outline=(220, 220, 230))
    # 2,2: White Palace Marble Wall
    draw.rectangle([64,64,95,95], fill=(230, 230, 240))
    draw.line([64,80, 95,80], fill=(200, 200, 210))
    draw.line([72,64, 72,95], fill=(255, 255, 255))
    draw.line([88,64, 88,95], fill=(255, 255, 255))

    # --- PROPS & NATURE (Row 3) ---
    # 0,3: Tree Top (Leaves)
    draw.rectangle([0,96,31,127], fill=(0,0,0,0)) # transp background
    draw.ellipse([2,98,29,125], fill=(20, 100, 20))
    draw.ellipse([6,102,18,114], fill=(40, 140, 40)) # highlight
    # 1,3: Tree Trunk
    draw.rectangle([32,96,63,127], fill=(50, 160, 50)) # grass background
    draw.rectangle([44,96,51,120], fill=(100, 60, 20)) # trunk
    draw.line([46,96, 46,120], fill=(70, 40, 10)) # bark
    # 2,3: Bush / Flowers
    draw.rectangle([64,96,95,127], fill=(50, 160, 50)) # grass background
    draw.ellipse([70,102,88,120], fill=(30, 130, 30))
    draw.point([(75,105), (83,110), (74,115)], fill=(255, 50, 50)) # red flowers
    draw.point([(80,104), (72,110), (84,116)], fill=(255, 255, 50)) # yellow flowers
    # 3,3: Wooden Desk
    draw.rectangle([96,96,127,127], fill=(139, 69, 19)) # matches floor, but darker
    draw.rectangle([100,100,123,123], fill=(101, 67, 33), outline=(80, 50, 20))
    draw.line([100,105, 123,105], fill=(139, 90, 43))

    # --- INTERIOR PROPS (Row 4) ---
    # 0,4: Metal Desk (Musk)
    draw.rectangle([0,128,31,159], fill=(200, 200, 200)) # floor back
    draw.rectangle([4,132,27,155], fill=(100, 110, 120), outline=(50, 60, 70))
    draw.rectangle([8,136,23,151], fill=(180, 190, 200)) # bright top
    # 1,4: Server Rack (Musk)
    draw.rectangle([32,128,63,159], fill=(200, 200, 200)) # floor back
    draw.rectangle([36,130,59,157], fill=(40, 40, 45), outline=(20, 20, 20))
    for y in range(134, 155, 6):
        draw.line([40, y, 55, y], fill=(100, 100, 110))
        draw.point([(42, y)], fill=(50, 255, 50)) # blinking lights
        draw.point([(46, y)], fill=(50, 100, 255))
    # 2,4: Bookshelf (Palace)
    draw.rectangle([64,128,95,159], fill=(240, 240, 245)) # marble back
    draw.rectangle([68,130,91,157], fill=(80, 50, 30), outline=(60, 30, 10))
    draw.line([68, 140, 91, 140], fill=(60, 30, 10))
    draw.line([68, 150, 91, 150], fill=(60, 30, 10))
    # colorful books
    draw.rectangle([70,132,73,139], fill=(200, 50, 50))
    draw.rectangle([75,133,77,139], fill=(50, 200, 50))
    draw.rectangle([85,142,88,149], fill=(50, 50, 200))
    # 3,4: Gold Pile (Vault)
    draw.rectangle([96,128,127,159], fill=(240, 240, 245)) # Marble floor
    # Draw gold bars
    for ox, oy in [(106, 146), (112, 148), (102, 140), (108, 142), (114, 144), (106, 134)]:
        draw.rectangle([ox, oy, ox+8, oy+4], fill=(255, 215, 0), outline=(184, 134, 11))
    
    # 4,4: Flag / Banner (Kremlin)
    draw.rectangle([128,128,159,159], fill=(139, 69, 19)) # wood back
    draw.rectangle([138,130,149,157], fill=(200, 30, 30)) # red banner
    draw.rectangle([138,130,149,134], fill=(255, 215, 0)) # gold trim

    img.save("assets/tiles/world_tiles.png", "PNG")
    print("Mega 256x256 Tileset with Details generated.")

if __name__ == "__main__":
    draw_rpg_tiles()
