# Asset Packs

The curated external pixel-art pack for this project lives at:

- `assets/packs/civic_nightmare/`

This folder is a project-local copy of the curated subset prepared from:

- Pixel-boy `Ninja Adventure`
- LimeZu `Modern Interiors` free pack

## Recommended entry points

- Exterior terrain: `assets/packs/civic_nightmare/tilesets/overworld_ninja/`
- Office and civic interiors: `assets/packs/civic_nightmare/tilesets/interiors_modern_free/`
- Extra interior support: `assets/packs/civic_nightmare/tilesets/interiors_ninja/`
- Civilian and office NPCs: `assets/packs/civic_nightmare/characters/modern_office_16x16/`
- Props and pickups: `assets/packs/civic_nightmare/items_props/ninja/`
- Dialog and HUD UI: `assets/packs/civic_nightmare/ui/ninja/`

## Important files

- Pack overview: `assets/packs/civic_nightmare/README.md`
- Machine-readable index: `assets/packs/civic_nightmare/manifest.json`
- Claude handoff: `assets/packs/civic_nightmare/docs/CLAUDE_HANDOFF.md`

## Licensing caution

- `Modern Interiors` free pack is marked non-commercial in:
  - `assets/packs/civic_nightmare/licenses/Modern_Interiors_LICENSE.txt`
- Verify current upstream licensing for `Ninja Adventure` before shipping or distributing commercially.

## Godot note

`assets/packs/civic_nightmare/docs/` and `assets/packs/civic_nightmare/licenses/` are intentionally ignored with `.gdignore` so documentation stays in the repo without cluttering the Godot asset browser.
