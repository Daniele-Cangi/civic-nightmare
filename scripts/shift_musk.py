import os
from PIL import Image

def shift_image_down(file_path, pixels):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return
        
    img = Image.open(file_path).convert("RGBA")
    w, h = img.size
    
    # Create a new transparent canvas
    new_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # Paste the original image shifted down
    new_img.paste(img, (0, pixels))
    
    new_img.save(file_path)
    print(f"Shifted {file_path} down by {pixels} pixels.")

if __name__ == "__main__":
    target = r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\musk_combat_portrait.png"
    shift_image_down(target, 8)
