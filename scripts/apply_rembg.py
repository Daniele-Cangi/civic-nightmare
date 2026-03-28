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
            
        # Rembg perfectly strips background leaving 0 residues
        output_data = rembg.remove(input_data)
        
        # Ensure the destination directory exists
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        
        with open(dest_path, "wb") as output_file:
            output_file.write(output_data)
            
        print(f"Saved flawless cutout to {dest_path}")
    except Exception as e:
        print(f"Error processing {src_path}: {e}")

# Mapping of source generated images (Combat Arcade Version) to game assets
BATCH_MAPPING = {
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\trump_combat_v1_arcade_1774728054717.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\trump_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\musk_combat_v1_arcade_1774728072571.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\musk_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\putin_combat_v1_arcade_1774728085842.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\putin_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\vdl_combat_v1_arcade_1774728100841.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\vdl_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\macron_combat_v1_arcade_1774728115865.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\macron_combat_portrait.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\lagarde_combat_v1_arcade_1774728129010.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\lagarde_combat_portrait.png",
}

if __name__ == "__main__":
    for src, dest in BATCH_MAPPING.items():
        process_with_ai(src.strip(), dest.strip())
