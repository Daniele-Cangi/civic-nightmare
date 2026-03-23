import shutil
import os

src_putin = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\putin_caricature_pixel_1774288878961.png"
src_macron = r"C:\Users\dacan\.gemini\antigravity\brain\e1ff93e5-feb9-40de-bb1e-b46aafdf7fd1\macron_caricature_pixel_1774288912434.png"

dest_putin = r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\putin_pure_sprite.png"
dest_macron = r"c:\Users\dacan\OneDrive\Documenti\My Games\civic-nightmare\assets\mockups\macron_pure_sprite.png"

try:
    shutil.copy(src_putin, dest_putin)
    shutil.copy(src_macron, dest_macron)
    print("Copied original AI artifacts into the game folder.")
except Exception as e:
    print(f"Error: {e}")
