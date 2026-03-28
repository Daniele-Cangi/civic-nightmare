from PIL import Image
import os

def remove_white_bg(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"Skipping: {input_path} (not found)")
        return
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()
    new_data = []
    for item in datas:
        # If it's very close to white
        if item[0] > 245 and item[1] > 245 and item[2] > 245:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Processed: {output_path}")

base_path = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1"
assets_path = r"C:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets"

files = [
    (os.path.join(base_path, "xi_jinping_pixel_sprite_1774634296919.png"), os.path.join(assets_path, "characters", "xi_jinping.png")),
    (os.path.join(base_path, "great_wall_pixel_landmark_1774634317833.png"), os.path.join(assets_path, "mockups", "landmark_great_wall.png")),
    (os.path.join(base_path, "xi_jinping_caricature_pixel_1774634704912.png"), os.path.join(assets_path, "mockups", "xi_jinping_caricature.png"))
]

for inp, outp in files:
    remove_white_bg(inp, outp)
