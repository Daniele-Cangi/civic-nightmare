import os
from PIL import Image

def strip_boss(filename):
    path = os.path.join("assets/mockups", filename)
    if not os.path.exists(path): return
    
    img = Image.open(path).convert("RGBA")
    data = img.getdata()
    new_data = []
    
    for item in data:
        # Chroma green or White-ish background removal
        is_green = item[1] > item[0] + 20 and item[1] > item[2] + 20 and item[1] > 80
        is_light = item[0] > 200 and item[1] > 200 and item[2] > 200
        
        if is_green or is_light:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(path, "PNG")
    print(f"Stripped background from {filename}")

if __name__ == "__main__":
    strip_boss("putin_pure_sprite.png")
    strip_boss("macron_pure_sprite.png")
