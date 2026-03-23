import os

path = "scenes/main.tscn"
if not os.path.exists(path):
    print("File not found")
    exit()

with open(path, "r") as f:
    content = f.read()

# Generate the 64 lines
mappings = ""
for x in range(8):
    for y in range(8):
        mappings += f"{x}:{y}/0 = 0\n"

start_marker = "texture_region_size = Vector2i(32, 32)\n"
end_marker = "\n[sub_resource type=\"TileSet\""

if start_marker in content and end_marker in content:
    pre = content.split(start_marker)[0] + start_marker
    post = "\n[sub_resource type=\"TileSet\"" + content.split(end_marker)[1]
    
    new_content = pre + mappings.strip() + post
    with open(path, "w") as f:
        f.write(new_content)
    print("Tilemap Atlas patched with 64 coordinates.")
else:
    print("Could not find markers.")
