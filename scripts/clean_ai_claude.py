import os
from PIL import Image
try:
    from rembg import remove
    HAS_REMBG = True
except ImportError:
    HAS_REMBG = False

def process(input_path, output_path, size=(128, 128)):
    print(f"Processing {input_path}...")
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

# AI Sprite
process(
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\ai_claude_pixel_sprite_1774648431046.png",
    r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\ai_claude_sprite.png",
    (128, 128)
)

# AI Caricature
process(
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\ai_claude_caricature_new_1774648457663.png",
    r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\ai_claude_caricature.png",
    (128, 128)
)
