# Code and content licensing boundary

The MIT License in [`LICENSE`](LICENSE) applies to Civic Nightmare's source code and software implementation.

Unless a file or its accompanying documentation explicitly says otherwise, that code license does **not** automatically apply to the project's existing visual art, portraits, sprites, images, audio, branding, or other media. Dialogue, story text, and other narrative content should likewise not be assumed to be MIT-licensed merely because they are stored in this repository.

Some media may be governed by its own license or usage terms. Known external pixel-art packs and their repository-local notices are summarized in [`docs/ASSET_PACKS.md`](docs/ASSET_PACKS.md).

When contributing media:

- submit only material you have the right to contribute;
- do not submit third-party copyrighted media with unclear usage rights;
- disclose whether the material is original, generated, or externally sourced;
- identify its source and applicable usage rights when externally sourced;
- identify the generation source or tool when appropriate for generated media;
- note meaningful modifications when that context helps reviewers.

This notice is a practical repository policy and is not a complete rights audit of every existing file.

Repository placement does not change rights. `assets/` is the exported runtime
set, `asset_sources/` is non-exported retained source material, and
`tmp/generated/` is disposable local output. The maintained storage and
provenance inventory is [`docs/ASSET_INVENTORY.md`](docs/ASSET_INVENTORY.md).

## Generated project artwork

The following project-specific battle assets were generated with OpenAI image generation and then locally cropped or chroma-keyed for runtime use:

- `assets/mockups/bezos_fulfillment_cathedral.png`
- `assets/mockups/bezos_battle_poses.png`
- `assets/mockups/citizen_battle_poses.png`

The following 1280×720 project-specific encounter stages were generated with
OpenAI image generation, then locally resized and promoted into the runtime:

- `assets/encounters/greatest_deal_stage_v1.png`
- `assets/encounters/consensus_engine_stage_v1.png`
- `assets/encounters/price_stability_pinball_stage_v1.png`

They were art-directed for Civic Nightmare and use existing repository artwork only as a style or character-design reference.

The playable opening drive uses six project-specific assets generated with
OpenAI built-in image generation and promoted without third-party source art:

- `assets/sequences/opening_drive_sunset_v2.png` — original 1672×941 saturated
  arcade-sunset highway and administrative-district background, regenerated
  from the project's v1 composition without external game art;
- `assets/sequences/opening_drive_car_v1.png` — original 1536×1024 transparent
  rear-view battered economy-car sprite;
- `assets/sequences/opening_drive_pothole_ceremony_v1.png` — original 1536×1024
  transparent official pothole-inauguration set piece;
- `assets/sequences/opening_drive_motorcade_v1.png` — original 1536×1024
  transparent armoured-motorcade set piece;
- `assets/sequences/opening_drive_tollbooth_v1.png` — original 1536×1024
  transparent three-lane mobile administrative toll;
- `assets/sequences/opening_drive_checkpoint_v1.png` — original 1536×1024
  transparent corroded checkpoint arch, authored without a barrier so the
  collapse remains animated at runtime.

The sequence adds its road motion, signs, hazards, privilege lane, toll logic,
receipt, scanner, failed barrier, smoke, damage and display layers in code.

## Original project music

`assets/audio/civic_nightmare_opening_drive.ogg` is **Coastline Dash**, an
original instrumental created and delivered directly by project owner Daniele
Cangi for Civic Nightmare. The runtime file is a 48 kHz stereo Ogg Vorbis
conversion of the supplied WAV master; the editable/master file is not shipped.
It remains project media under the licensing boundary described above rather
than becoming MIT-licensed source code.

## Marketing artwork

`asset_sources/marketing/civic_nightmare_itch_cover_v1.png` is an original
1260×1000 itch.io cover generated with OpenAI built-in image generation for
the project. It uses the project's own opening-drive background, battered car,
and citizen pose sheet only as visual references. The final composition is new,
contains no third-party source art, and is retained outside the exported runtime.
