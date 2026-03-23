import os
from PIL import Image, ImageDraw

def generate_player():
    os.makedirs("assets/tiles", exist_ok=True)
    img = Image.new("RGBA", (32, 32), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Outline Head
    draw.rectangle([9, 1, 22, 13], outline=(0, 0, 0))
    # Head Base (Skin)
    draw.rectangle([10, 2, 21, 12], fill=(255, 204, 153))
    # Hair
    draw.rectangle([9, 1, 22, 5], fill=(50, 40, 30))
    draw.rectangle([8, 3, 10, 8], fill=(50, 40, 30))
    # Eyes
    draw.point([(13, 8), (18, 8)], fill=(0, 0, 0))

    # Body Outline
    draw.rectangle([7, 14, 24, 28], outline=(0, 0, 0))
    # Body Fill (Blue Suit)
    draw.rectangle([8, 14, 23, 27], fill=(40, 60, 120))
    # Tie
    draw.rectangle([15, 14, 16, 22], fill=(180, 40, 40))

    # Shoes
    draw.rectangle([10, 28, 13, 31], fill=(30, 30, 30), outline=(0,0,0))
    draw.rectangle([18, 28, 21, 31], fill=(30, 30, 30), outline=(0,0,0))

    # Save
    img.save("assets/tiles/player_sprite.png", "PNG")
    print("Player sprite generated.")

if __name__ == "__main__":
    generate_player()
