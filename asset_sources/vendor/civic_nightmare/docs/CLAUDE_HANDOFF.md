# Claude Code Handoff

Use `C:\Users\dacan\Desktop\CivicNightmare_Assets\ready_for_claude` as the first asset root.

## Priority Order

1. For office and government interiors, prefer `tilesets/interiors_modern_free`.
2. For exterior maps, terrain, sidewalks, grass, water, and simple building shells, prefer `tilesets/overworld_ninja`.
3. For NPCs in civic buildings, prefer `characters/modern_office_16x16`.
4. For props and pickups, pull from `items_props/ninja`.
5. For UI, use `ui/ninja/dialog` and `ui/ninja/hud` first. Only use `ui/ninja/theme_wood` if the project can accept a rustic UI style.

## Fast Mapping

- Exterior ground: `tilesets/overworld_ninja/TilesetField.png`
- Nature and clutter: `tilesets/overworld_ninja/TilesetNature.png`
- Water: `tilesets/overworld_ninja/TilesetWater.png`
- Building shell: `tilesets/overworld_ninja/TilesetHouse.png`
- Modern interiors: `tilesets/interiors_modern_free/Interiors_free_16x16.png`
- Room layout helper: `tilesets/interiors_modern_free/Room_Builder_free_16x16.png`
- Office NPCs: `characters/modern_office_16x16/*.png`
- Books, bags, crates: `items_props/ninja/Object`
- Coins, keys, chests: `items_props/ninja/Treasure`
- Tools and maintenance props: `items_props/ninja/Tool`

## Constraints

- `Modern Interiors` free pack includes a non-commercial-only local license.
- If a needed asset is missing from this curated subset, check the full extracted packs in:
  - `C:\Users\dacan\Desktop\CivicNightmare_Assets\raw\ninja_adventure`
  - `C:\Users\dacan\Desktop\CivicNightmare_Assets\raw\modern_interiors_free`

## Safe Default Prompt

If you need Claude Code to wire these into a repo, tell it:

`Use C:\\Users\\dacan\\Desktop\\CivicNightmare_Assets\\ready_for_claude as the asset source. Prefer modern interior sheets for offices, modern 16x16 character sheets for civic NPCs, and ninja overworld sheets only for exterior terrain and props. Do not scan raw packs unless the curated subset is insufficient.`
