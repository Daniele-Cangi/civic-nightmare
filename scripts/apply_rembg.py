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
        
        # Load output to perform a slight alpha-level cleanup
        output_img = Image.open(io.BytesIO(output_data)).convert("RGBA")
        datas = output_img.getdata()
        new_data = []
        for item in datas:
            # If color is extremely close to white and almost transparent, kill it
            if item[0] > 240 and item[1] > 240 and item[2] > 240 and item[3] < 20:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        output_img.putdata(new_data)
        
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        output_img.save(dest_path, "PNG")
            
        print(f"Saved flawless ML-cleaned cutout to {dest_path}")
    except Exception as e:
        print(f"Error processing {src_path}: {e}")

# Mapping of Pyongyang Square + Kim Jong-un (Chubby/Steak version) to game assets
BATCH_MAPPING = {
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\landmark_pyongyang_satire_1774779199106.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\landmark_pyongyang.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\kim_jong_un_chubby_steak_sprite_v2_arcade_1774779699817.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\kim_jong_un_sprite.png",
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\kim_jong_un_honda_steak_portrait_v14_arcade_1774779721550.png": r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\kim_jong_un_portrait.png",
}

if __name__ == "__main__":
    for src, dest in BATCH_MAPPING.items():
        process_with_ai(src.strip(), dest.strip())
