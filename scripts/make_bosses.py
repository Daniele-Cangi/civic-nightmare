import os
from PIL import Image, ImageDraw

def draw_putin():
    img = Image.new("RGBA", (32, 32), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    
    # Body
    draw.rectangle([7, 16, 24, 31], fill=(40, 40, 45), outline=(0,0,0))
    # Shirt & Tie
    draw.rectangle([13, 16, 18, 20], fill=(220, 220, 220))
    draw.rectangle([15, 17, 16, 25], fill=(180, 40, 40))
    
    # Head & Face
    draw.rectangle([9, 4, 22, 15], fill=(250, 210, 180), outline=(0,0,0))
    
    # Bear Hat (Ushanka)
    draw.rectangle([7, 1, 24, 6], fill=(101, 67, 33), outline=(0,0,0))
    draw.rectangle([6, 3, 8, 9], fill=(80, 50, 20), outline=(0,0,0)) # Ear flaps
    draw.rectangle([23, 3, 25, 9], fill=(80, 50, 20), outline=(0,0,0))

    # Face details (Eyes strict)
    draw.point([(13, 10), (14, 10)], fill=(0,0,0))
    draw.point([(17, 10), (18, 10)], fill=(0,0,0))
    draw.line([14, 13, 17, 13], fill=(0,0,0)) # Mouth
    
    # Upscale
    img = img.resize((128, 128), Image.Resampling.NEAREST)
    img.save("assets/mockups/putin_pure_sprite.png", "PNG")

def draw_macron():
    img = Image.new("RGBA", (32, 32), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    
    # Body (Blue sharp suit)
    draw.rectangle([8, 15, 23, 31], fill=(30, 40, 100), outline=(0,0,0))
    # Shirt & Tie
    draw.rectangle([13, 15, 18, 19], fill=(240, 240, 255))
    draw.rectangle([15, 16, 16, 23], fill=(30, 30, 30))
    
    # Head & Face
    draw.rectangle([10, 3, 21, 14], fill=(255, 215, 190), outline=(0,0,0))
    
    # Hair (Swoop back)
    draw.rectangle([9, 1, 22, 4], fill=(60, 40, 20), outline=(0,0,0))
    draw.rectangle([21, 4, 23, 7], fill=(60, 40, 20))
    
    # Sunglasses (Ray-Bans)
    draw.rectangle([11, 7, 15, 9], fill=(20, 20, 20), outline=(0,0,0))
    draw.rectangle([16, 7, 20, 9], fill=(20, 20, 20), outline=(0,0,0))
    draw.line([15, 7, 16, 7], fill=(0,0,0)) # Bridge
    draw.line([10, 7, 11, 7], fill=(0,0,0)) # Stems
    draw.line([20, 7, 21, 7], fill=(0,0,0)) 
    
    # Mouth
    draw.line([14, 12, 17, 12], fill=(0,0,0)) # Confident smirk
    
    # Upscale
    img = img.resize((128, 128), Image.Resampling.NEAREST)
    img.save("assets/mockups/macron_pure_sprite.png", "PNG")

if __name__ == "__main__":
    draw_putin()
    draw_macron()
    print("Hand-coded Boss Sprites Generated.")
