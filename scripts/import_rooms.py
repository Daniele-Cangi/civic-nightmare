import os
import shutil
from PIL import Image

artifact_dir = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1"

rooms = {
    "donald_trump": "oval_office_pixel_art_1774287121515.png",
    "elon_musk": "musk_office_pixel_1774288580539.png",
    "ursula_von_der_leyen": "eu_office_pixel_1774288612210.png",
    "christine_lagarde": "ecb_office_pixel_1774288693571.png",
    "vladimir_putin": "kremlin_office_pixel_1774288895119.png",
    "emmanuel_macron": "elysee_office_pixel_1774288928480.png"
}

out_dir = "assets/mockups"
os.makedirs(out_dir, exist_ok=True)

for cid, filename in rooms.items():
    src_path = os.path.join(artifact_dir, filename)
    dest_path = os.path.join(out_dir, f"office_{cid}.png")
    
    if not os.path.exists(src_path):
        print(f"Missing: {src_path}")
        continue
        
    print(f"Processing high-detail room for {cid}...")
    try:
        img = Image.open(src_path).convert("RGBA")
        sz = img.size
        # Massive high-detail images (e.g. 1024) need to be pixelated so they fit the 16-bit RPG style.
        # We crush them to 128x128 (high detail pixel art), then upscale Nearest to 512x512.
        # 512x512 covers a massive 16x16 tile area, which is perfect for a huge Boss Room.
        tiny_sz = (128, 128)
        tiny = img.resize(tiny_sz, Image.Resampling.LANCZOS)
        final = tiny.resize((512, 512), Image.Resampling.NEAREST)
        final.save(dest_path, "PNG")
        print(f"Saved {dest_path}")
    except Exception as e:
        print(f"Error processing {filename}: {e}")
