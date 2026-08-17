# Asset Packs

The retained external pixel-art source pack for this project lives at:

- `asset_sources/vendor/civic_nightmare/`

The six currently used props are promoted into `assets/runtime/props/`; the
vendor tree is ignored by Godot and never enters the web build.

This folder is a project-local copy of the curated subset prepared from:

- Pixel-boy `Ninja Adventure`
- LimeZu `Modern Interiors` free pack

## Recommended entry points

- Exterior terrain: `asset_sources/vendor/civic_nightmare/tilesets/overworld_ninja/`
- Office and civic interiors: `asset_sources/vendor/civic_nightmare/tilesets/interiors_modern_free/`
- Extra interior support: `asset_sources/vendor/civic_nightmare/tilesets/interiors_ninja/`
- Civilian and office NPCs: `asset_sources/vendor/civic_nightmare/characters/modern_office_16x16/`
- Props and pickups: `asset_sources/vendor/civic_nightmare/items_props/ninja/`
- Dialog and HUD UI: `asset_sources/vendor/civic_nightmare/ui/ninja/`

## Important files

- Pack overview: `asset_sources/vendor/civic_nightmare/README.md`
- Machine-readable index: `asset_sources/vendor/civic_nightmare/manifest.json`
- Claude handoff: `asset_sources/vendor/civic_nightmare/docs/CLAUDE_HANDOFF.md`

## Licensing caution

- `Modern Interiors` free pack is marked non-commercial in:
  - `asset_sources/vendor/civic_nightmare/licenses/Modern_Interiors_LICENSE.txt`
- Verify current upstream licensing for `Ninja Adventure` before shipping or distributing commercially.

## Godot note

The entire `asset_sources/` tree is intentionally ignored with `.gdignore`, so
documentation and licenses stay available without entering the Godot asset
browser or export. Keep the promoted runtime copies byte-identical unless a
provenance note documents a deliberate modification.
