import os
import rembg
from PIL import Image
import io

def process_with_ai(src_path, dest_path):
    if not os.path.exists(src_path):
        print(f"File not found: {src_path}")
        return
        
    print(f"Applying ML U2-Net cleanup to {src_path}...")
    try:
        with open(src_path, "rb") as input_file:
            input_data = input_file.read()
            
        # Use rembg to remove background
        output_data = rembg.remove(input_data)
        
        # Load output to perform a slight alpha-level cleanup (aggressive residue removal)
        output_img = Image.open(io.BytesIO(output_data)).convert("RGBA")
        datas = output_img.getdata()
        new_data = []
        for item in datas:
            # If color is extremely close to white and almost transparent, kill it
            if item[0] > 240 and item[1] > 240 and item[2] > 240 and item[3] < 20: # Slightly lower threshold (240) to be safer
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        output_img.putdata(new_data)
        
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        output_img.save(dest_path, "PNG")
            
        print(f"Saved flawless ML-cleaned cutout to {dest_path}")
    except Exception as e:
        print(f"Error processing {src_path}: {e}")

# Batch Mapping with CORRECT Paths
BATCH_MAPPING = {
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\trump_terry_closeup_v13_arcade_1774746476078.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\trump_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\macron_raiden_closeup_v13_arcade_1774746488724.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\macron_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\lagarde_chunli_silver_v14_arcade_1774746717032.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\lagarde_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\putin_vega_closeup_v13_arcade_1774746522877.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\putin_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\musk_bison_closeup_v13_arcade_1774746534365.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\musk_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\vdl_cammy_closeup_v13_arcade_1774746550709.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\vdl_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\contamination_spectral_hero_v7_arcade_1774748192352.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\contamination_portrait.png",
}

if __name__ == "__main__":
    for src, dest in BATCH_MAPPING.items():
        process_with_ai(src.strip(), dest.strip())
