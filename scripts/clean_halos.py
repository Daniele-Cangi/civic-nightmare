import os
from PIL import Image

def iterative_clean(filename):
    path = os.path.join("assets/mockups", filename)
    if not os.path.exists(path): return
    
    img = Image.open(path).convert("RGBA")
    width, height = img.size
    
    pass_count = 0
    changed = True
    while changed and pass_count < 15: # safety break
        changed = False
        pass_count += 1
        new_img = Image.new("RGBA", (width, height), (0,0,0,0))
        for y in range(height):
            for x in range(width):
                item = img.getpixel((x, y))
                if item[3] == 0: continue
                
                is_edge = False
                for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
                    nx, ny = x+dx, y+dy
                    if 0 <= nx < width and 0 <= ny < height:
                        if img.getpixel((nx, ny))[3] == 0:
                            is_edge = True
                            break
                            
                should_delete = False
                if is_edge:
                    # R, G, B
                    r, g, b, a = item
                    luma = (r + g + b) / 3.0
                    
                    # 1. White / Light Grey background halos
                    if luma > 150 and abs(r-g) < 40 and abs(g-b) < 40:
                        should_delete = True
                    # 2. Greenish chroma bleeding
                    elif g > r + 10 and g > b + 10 and luma > 80:
                        should_delete = True
                        
                if not should_delete:
                    new_img.putpixel((x, y), item)
                else:
                    changed = True
                    
        img = new_img
        
    img.save(path, "PNG")
    print(f"Eroded halo from {filename} after {pass_count} passes.")

if __name__ == "__main__":
    iterative_clean("putin_pure_sprite.png")
    iterative_clean("macron_pure_sprite.png")
