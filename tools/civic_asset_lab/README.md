# Civic Asset Lab

Offline scene generator for `Civic Nightmare`.

## What it does
- Generates deterministic SVG scene plates locally
- Provides a browser preview with animated frame playback
- Supports style profiles for cleaner or harsher art direction passes
- Exports spritesheet SVGs and metadata JSON for animated presets
- Provides optional local pixel dithering for raster preview
- Exports directly into `assets/generated`
- Avoids API calls and avoids name-based celebrity prompting

## Open the lab
Open [index.html](/C:/Users/dacan/OneDrive/Documenti/My%20Games/civic-nightmare/tools/civic_asset_lab/index.html) in a browser.

## Generate project assets
Run:

```powershell
node .\tools\civic_asset_lab\generate_assets.js
```

## Smoke test
Run:

```powershell
node .\tools\civic_asset_lab\test_asset_lab.js
```

## Production-oriented additions
- `Production`, `Editorial Clean`, `Brutalist Signal`, and `Nocturne` style profiles
- Preset category filtering inside the browser lab
- Animated preview for frame-based FX presets
- Spritesheet SVG + JSON atlas export for animated presets
- Richer manifest entries with `category`, `profile`, and `kind`

## Current exports
- `plaza_day1_backdrop.svg`
- `plaza_day2_backdrop.svg`
- `records_chamber_scene.svg`
- `turnstile_gate_scene.svg`
- `apartment_interlude_scene.svg`
- `trump_podium_annex_scene.svg`
- `musk_priority_lane_scene.svg`
- `vdl_packet_hall_scene.svg`
- `lagarde_housing_office_scene.svg`
- `citizen_actor_sprite.svg`
- `trump_actor_sprite.svg`
- `musk_actor_sprite.svg`
- `vdl_actor_sprite.svg`
- `lagarde_actor_sprite.svg`
- `records_window_actor_sprite.svg`
- `home_turnstile_actor_sprite.svg`
- `plaza_pixel_fx_overlay_<pressure>.svg`
- `annex_pixel_fx_overlay_<pressure>.svg`
- `transition_pixel_fx_overlay_<pressure>.svg`
- `podium_acceptance_fx_overlay_<pressure>.svg`
- `scanner_tap_fx_overlay_<pressure>.svg`
- `packet_handoff_fx_overlay_<pressure>.svg`
- `ledger_signing_fx_overlay_<pressure>.svg`
- `records_notice_poster.svg`
- `turnstile_direction_sign.svg`
- `barricade_decal_strip.svg`
- `dossier_sheet_cluster.svg`
- `checkpoint_stamp_mark.svg`
- `agency_seal_badge.svg`
- `queue_floor_arrows_day2.svg`
- `day2_document_overlay.svg`
- `dossier_commit_event_fx_overlay_<pressure>.svg`
- `records_stamp_event_fx_overlay_<pressure>.svg`
- `night_shift_event_fx_overlay_<pressure>.svg`
- `turnstile_release_event_fx_overlay_<pressure>.svg`

Pressure-sensitive variants are also exported for:
- `checkpoint_stamp_mark_<pressure>.svg`
- `agency_seal_badge_<pressure>.svg`
- `queue_floor_arrows_day2_<pressure>.svg`
- `day2_document_overlay_<pressure>.svg`

Animated frame sequences are also exported for gesture FX:
- `podium_acceptance_fx_overlay_<pressure>_f01..f05.svg`
- `scanner_tap_fx_overlay_<pressure>_f01..f05.svg`
- `packet_handoff_fx_overlay_<pressure>_f01..f05.svg`
- `ledger_signing_fx_overlay_<pressure>_f01..f05.svg`

Animated frame sequences are also exported for in-game event FX:
- `dossier_commit_event_fx_overlay_<pressure>_f01..f05.svg`
- `records_stamp_event_fx_overlay_<pressure>_f01..f05.svg`
- `night_shift_event_fx_overlay_<pressure>_f01..f05.svg`
- `turnstile_release_event_fx_overlay_<pressure>_f01..f05.svg`

Spritesheet exports are also generated for animated FX:
- `podium_acceptance_fx_overlay_<pressure>_sheet.svg` + `.json`
- `scanner_tap_fx_overlay_<pressure>_sheet.svg` + `.json`
- `packet_handoff_fx_overlay_<pressure>_sheet.svg` + `.json`
- `ledger_signing_fx_overlay_<pressure>_sheet.svg` + `.json`
- `dossier_commit_event_fx_overlay_<pressure>_sheet.svg` + `.json`
- `records_stamp_event_fx_overlay_<pressure>_sheet.svg` + `.json`
- `night_shift_event_fx_overlay_<pressure>_sheet.svg` + `.json`
- `turnstile_release_event_fx_overlay_<pressure>_sheet.svg` + `.json`
