import os
from PIL import Image

def process_and_normalize(folder):
    for filename in os.listdir(folder):
        if not filename.endswith(".png"): continue
        if "player" in filename: continue

        path = os.path.join(folder, filename)
        try:
            img = Image.open(path).convert("RGBA")
        except Exception:
            continue
            
        sz = img.size
        # If it is a gigantic AI image, we MUST shrink it structurally
        if max(sz) > 150:
            ratio = 64.0 / max(sz)
            new_size = (int(sz[0] * ratio), int(sz[1] * ratio))
            
            # Smooth downscale so it doesn't scramble pixels
            tiny = img.resize(new_size, Image.Resampling.LANCZOS)
            
            # Alpha thresholding to remove translucent halos
            data = tiny.getdata()
            new_data = []
            for item in data:
                if item[3] < 128:
                    new_data.append((0,0,0,0))
                else:
                    new_data.append((item[0], item[1], item[2], 255))
            tiny.putdata(new_data)
            
            # Upscale 2x using NEAREST to lock those chunky pixels in place natively
            final = tiny.resize((new_size[0]*2, new_size[1]*2), Image.Resampling.NEAREST)
            final.save(path, "PNG")
            print(f"Structurally Normalized to Pixel Art: {filename}")
        else:
            print(f"Skipping already optimized image: {filename}")

if __name__ == "__main__":
    process_and_normalize("assets/mockups")
