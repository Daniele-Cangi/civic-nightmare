import os
from PIL import Image

# Mapping of Fighting Game Parody versions (V11) to temp zoomed versions
ZOO_MAPPING = {
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\trump_terry_v11_arcade_1774731895912.png": "trump_zoomed.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\macron_raiden_v11_arcade_1774731912963.png": "macron_zoomed.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\lagarde_chunli_v11_arcade_1774731928969.png": "lagarde_zoomed.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\putin_vega_v11_arcade_1774731948129.png": "putin_zoomed.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\musk_bison_v11_arcade_1774731959900.png": "musk_zoomed.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\vdl_cammy_v11_arcade_1774731974613.png": "vdl_zoomed.png",
}

TEMP_DIR = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\temp_zoom"
os.makedirs(TEMP_DIR, exist_ok=True)

def zoom_and_upscale(src, dest_name):
    if not os.path.exists(src):
        print(f"Not found: {src}")
        return
        
    img = Image.open(src)
    w, h = img.size
    
    # Smart Crop for 128x128 sprites:
    # Usually the head is in the top-middle.
    # We take a 72x72 square centered on the face.
    # Coordinates: Left=28, Top=10, Right=100, Bottom=82
    left = 28
    top = 5
    right = 100
    bottom = 77
    
    crop = img.crop((left, top, right, bottom))
    
    # Upscale back to 128x128 with Nearest Neighbor to preserve pixels
    final = crop.resize((128, 128), Image.NEAREST)
    
    dest_path = os.path.join(TEMP_DIR, dest_name)
    final.save(dest_path)
    print(f"Created zoomed icon: {dest_path}")

if __name__ == "__main__":
    for src, name in ZOO_MAPPING.items():
        zoom_and_upscale(src, name)
