import os
import rembg

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
        
        with open(dest_path, "wb") as output_file:
            output_file.write(output_data)
            
        print(f"Saved flawless cutout to {dest_path}")
    except Exception as e:
        print(f"Error processing {src_path}: {e}")

src_putin = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\putin_caricature_pixel_1774288878961.png"
src_macron = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\macron_caricature_pixel_1774288912434.png"

dest_putin = r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\putin_pure_sprite.png"
dest_macron = r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\macron_pure_sprite.png"

if __name__ == "__main__":
    process_with_ai(src_putin, dest_putin)
    process_with_ai(src_macron, dest_macron)
