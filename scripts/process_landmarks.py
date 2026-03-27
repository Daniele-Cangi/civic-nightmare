import os
import rembg
from PIL import Image
import io

artifact_dir = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1"
dest_dir = r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups"

landmarks = {
    "trump": "trump_tower_pixel_1774616361786.png",
    "musk": "spacex_starship_pixel_1774616686197.png",
    "macron": "eiffel_tower_pixel_1774616567366.png",
    "putin": "armata_tank_pixel_1774616836701.png",
    "lagarde": "gold_vault_pixel_art_1774616641515_1774616937544.png",
    "vdl": "eu_stars_monument_pixel_1774617034560.png"
}

def process_landmark(name, filename):
    src_path = os.path.join(artifact_dir, filename)
    dest_path = os.path.join(dest_dir, f"landmark_{name}.png")
    
    if not os.path.exists(src_path):
        print(f"File not found: {src_path}")
        return
        
    print(f"Processing {name} ({filename})...")
    try:
        with open(src_path, "rb") as input_file:
            input_data = input_file.read()
            
        # 1. AI Background Removal
        output_data = rembg.remove(input_data)
        
        # 2. Pixelation and Scaling
        img = Image.open(io.BytesIO(output_data)).convert("RGBA")
        
        # We want landmarks to be quite big but still pixelated.
        # Let's target 128x128 or 256x256 depending on the original aspect ratio.
        # Most of these are tall (Eiffel, Trump Tower).
        w, h = img.size
        target_h = 256
        aspect = w / h
        target_w = int(target_h * aspect)
        
        # Crush to a small resolution for authentic pixel art feel, then upscale nearest
        crush_h = 128
        crush_w = int(crush_h * aspect)
        
        tiny = img.resize((crush_w, crush_h), Image.Resampling.LANCZOS)
        final = tiny.resize((target_w, target_h), Image.Resampling.NEAREST)
        
        final.save(dest_path, "PNG")
        print(f"Saved {dest_path}")
    except Exception as e:
        print(f"Error processing {name}: {e}")

if __name__ == "__main__":
    os.makedirs(dest_dir, exist_ok=True)
    for name, filename in landmarks.items():
        process_landmark(name, filename)
