from PIL import Image
import os
import glob

def clean_sprite(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()
    new_data = []
    for item in datas:
        # Remove white/near-white backgrounds (LM style cleanup)
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Cleaned and saved to: {output_path}")

# Target latest contamination generation
artifact_path = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\contamination_hitler_clean_pixel_1774693173297.png"
out = r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\sprites\npc_contamination.png"
clean_sprite(artifact_path, out)
