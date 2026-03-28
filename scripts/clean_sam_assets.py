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

# Sam Altman Sprite
remove_white_bg(
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\sam_altman_pixel_sprite_1774645905794.png",
    r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\characters\sam_altman.png"
)
# Sam Altman Caricature
remove_white_bg(
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\sam_altman_caricature_pixel_new_1774645934929.png",
    r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\sam_altman_caricature.png"
)
# Nuclear Plant
remove_white_bg(
    r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\nuclear_plant_pixel_landmark_new_1774645957073.png",
    r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\landmark_nuclear_plant.png"
)
print("Sam Altman assets cleaned and saved.")
