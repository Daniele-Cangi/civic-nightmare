import os
from PIL import Image, ImageDraw

def generate_tiles():
    os.makedirs("assets/tiles", exist_ok=True)
    
    # 64x32 image (two 32x32 tiles)
    img = Image.new("RGBA", (64, 32), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    
    # Tile 0: Grass (Green with dots)
    draw.rectangle([0,0,31,31], fill=(44, 150, 44))
    draw.point([(5,5), (20,10), (15,25), (28,28), (4,29), (27,4)], fill=(0, 100, 0))
    
    # Tile 1: Room Floor (Wood/Carpet dark)
    draw.rectangle([32,0,63,31], fill=(100, 50, 50))
    draw.rectangle([32,0,63,31], outline=(50, 20, 20))
    
    img.save("assets/tiles/world_tiles.png", "PNG")
    print("Tiles generated successfully.")

if __name__ == "__main__":
    generate_tiles()
