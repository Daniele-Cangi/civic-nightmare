import os
from PIL import Image
try:
    from rembg import remove
    HAS_REMBG = True
except ImportError:
    HAS_REMBG = False

def process(input_path, output_path, size=(128, 128)):
    print(f"Processing {input_path}...")
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found")
        return
        
    if HAS_REMBG:
        with open(input_path, 'rb') as i:
            input_data = i.read()
            output_data = remove(input_data)
            with open(output_path, 'wb') as o:
                o.write(output_data)
        img = Image.open(output_path)
    else:
        img = Image.open(input_path).convert("RGBA")
        datas = img.getdata()
        new_data = []
        for item in datas:
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        img.putdata(new_data)
    
    img = img.resize(size, Image.Resampling.LANCZOS)
    img.save(output_path)
    print(f"Saved: {output_path}")

base = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1"
dest = r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare"

# Assets
process(os.path.join(base, "zelensky_pixel_sprite_move_1774661968665.png"), os.path.join(dest, "assets/mockups/zelensky_move.png"))
process(os.path.join(base, "death_pixel_sprite_grotesque_1774661984114.png"), os.path.join(dest, "assets/mockups/death_move.png"))
