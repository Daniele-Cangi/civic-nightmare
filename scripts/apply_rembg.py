import os
import rembg
from PIL import Image
import io

def process_with_ai(src_path, dest_path):
    if not os.path.exists(src_path):
        print(f"File not found: {src_path}")
        return
        
    print(f"Applying U2-Net to {src_path}...")
    try:
        with open(src_path, "rb") as input_file:
            input_data = input_file.read()
            
        output_data = rembg.remove(input_data)
        
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        
        with open(dest_path, "wb") as output_file:
            output_file.write(output_data)
            
        print(f"Saved flawless cutout to {dest_path}")
    except Exception as e:
        print(f"Error processing {src_path}: {e}")

# Mapping of source generated images (Big Head Version 9) to game assets
BATCH_MAPPING = {
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\putin_bighead_bomb_v9_pixel_1774730931345.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\putin_pure_sprite.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\vdl_bighead_wings_v9_pixel_1774730953497.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\vdl_pure_sprite.png",
}

if __name__ == "__main__":
    for src, dest in BATCH_MAPPING.items():
        process_with_ai(src.strip(), dest.strip())
