from PIL import Image
import os

def remove_white_bg(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()
    new_data = []
    for item in datas:
        if item[0] > 245 and item[1] > 245 and item[2] > 245:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    img.save(output_path, "PNG")

inp = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\landmark_vdl_hammer_pixel_satire_1774642136899.png"
outp = r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\landmark_vdl.png"
remove_white_bg(inp, outp)
print(f"Overwritten: {outp}")
