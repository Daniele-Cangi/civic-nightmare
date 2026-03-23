# Civic Nightmare Asset Prep

Prepared on 2026-03-23 for fast use in Claude Code or a game repo.

This folder is the curated subset. The full extracted packs are still available in:

- `C:\Users\dacan\Desktop\CivicNightmare_Assets\raw\ninja_adventure`
- `C:\Users\dacan\Desktop\CivicNightmare_Assets\raw\modern_interiors_free`

## Folder Map

- `tilesets/overworld_ninja`
  - 11 outdoor sheets from Ninja Adventure.
  - Best starting points: `TilesetField.png`, `TilesetNature.png`, `TilesetWater.png`, `TilesetHouse.png`.
- `tilesets/interiors_ninja`
  - 4 interior support sheets from Ninja Adventure.
  - Useful for mixed fantasy/civic interiors or filler props.
- `tilesets/interiors_modern_free`
  - 16x16 modern interior sheets from LimeZu.
  - Best starting points: `Interiors_free_16x16.png`, `Room_Builder_free_16x16.png`.
- `characters/modern_office_16x16`
  - 32 character sheets.
  - Includes Adam, Alex, Amelia, Bob with idle, run, phone, and sit variants.
- `items_props/ninja`
  - Curated object, resource, treasure, potion, and tool props.
  - Good for books, crates, bags, coins, keys, cans, tools, and HUD pickups.
- `ui/ninja/dialog`
  - Dialogue windows and yes/no prompts.
- `ui/ninja/theme_wood`
  - Inventory cells, buttons, tabs, panels, sliders.
- `ui/ninja/hud`
  - Hearts and mini life bar assets.

## Suggested Use In Project

1. Use `tilesets/interiors_modern_free` for offices, archives, control rooms, and public service interiors.
2. Use `tilesets/overworld_ninja` for exteriors, paths, grass, water, terrain, and low-rise buildings.
3. Use `characters/modern_office_16x16` for civilians, clerks, analysts, receptionists, and municipal NPCs.
4. Pull props from `items_props/ninja` for desks, loot, interactables, signage stand-ins, and collectibles.
5. Treat `ui/ninja/theme_wood` as optional. It is usable, but visually more rustic than the modern interior pack.

## Known Sheet Sizes

- `tilesets/overworld_ninja/TilesetField.png`: `80x240`
- `tilesets/interiors_ninja/TilesetInterior.png`: `256x320`
- `tilesets/interiors_modern_free/Interiors_free_16x16.png`: `256x1424`
- `characters/modern_office_16x16/Adam_16x16.png`: `384x224`
- `ui/ninja/dialog/DialogBox.png`: `300x58`

These packs are intended for 16x16 workflows, but sheet layouts differ. Slice by sheet layout, not by folder name alone.

## Source Notes

- Ninja Adventure source page: `https://pixel-boy.itch.io/ninja-adventure-asset-pack`
- Modern Interiors source page: `https://limezu.itch.io/moderninteriors`
- Included local license for Modern Interiors free pack: `licenses/Modern_Interiors_LICENSE.txt`

## Licensing Caution

- `Modern Interiors` free pack explicitly allows non-commercial use only according to the included local license.
- `Ninja Adventure` licensing terms are not bundled here in a local text file. Verify the current source page before shipping or commercial distribution.
