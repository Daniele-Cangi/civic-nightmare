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

The short Putin access operation uses five original isolated runtime assets
generated with OpenAI built-in image generation without third-party source art.
The three corridor-enemy billboards were locally alpha-cropped and downscaled:

- `assets/encounters/putin_operation/matryoshka_security_unit_v1.png`;
- `assets/encounters/putin_operation/mobilization_copier_v1.png`;
- `assets/encounters/putin_operation/state_television_camera_v1.png`.

`assets/encounters/putin_operation/strategic_bear_washer_boss_v1.png` is an
original transparent full-body boss cutout generated specifically for this
project with OpenAI built-in image generation. It depicts a fictional military
bear using a worn front-loading washing machine as an absurd heavy weapon; the
simple helmet, appliance silhouette and illuminated drum were explicitly art
directed for the short final encounter. No third-party source image was used.

`assets/encounters/putin_operation/diplomatic_note_launcher_centered_v2.png`
was created in built-in image-edit mode from the original launcher, preserving
its paper-fed stamp mechanism and citizen sleeves while recomposing it as a
symmetrical, straight-ahead first-person sprite. Its neutral generated margin
is cut out by a tiny runtime canvas shader; this avoids shipping a second mask
or texture. The superseded diagonal source is retained outside the export
closure at
`asset_sources/legacy/putin_operation/diplomatic_note_launcher_diagonal_v1.png`.

The isolated figures were art-directed as original high-detail arcade
billboards for Civic Nightmare's pseudo-3D bureaucratic corridor. The corridor,
telegraphed projectiles, cover, splitting behaviour, final Potemkin defense,
Strategic Bear wash cycles, lighting and HUD are constructed at runtime.

## Project music

Unless a track-specific entry says otherwise, Civic Nightmare soundtracks are
generated using **Google Flow Music** and delivered by project owner Daniele
Cangi. Future soundtrack additions must preserve this tool disclosure, identify
their runtime conversion, and remain outside the MIT source-code grant.

`assets/audio/civic_nightmare_opening_drive.ogg` is **Coastline Dash**, an
instrumental generated specifically for Civic Nightmare using Google Flow
Music. The runtime file is a 48 kHz stereo Ogg Vorbis conversion of the supplied
WAV master; the editable/master file is not shipped. It remains project media
under the licensing boundary described above rather than becoming MIT-licensed
source code.

`assets/audio/civic_nightmare_putin_special_operation.ogg` is **Three-Minute
Special Operation**, generated specifically for Civic Nightmare using **Google
Flow Music** and delivered by project owner Daniele Cangi. The runtime file is
a lightly attenuated 48 kHz stereo Ogg Vorbis conversion of the supplied WAV
master; the master is not shipped. This disclosure records the generation tool
and delivery provenance without placing the output under the repository's MIT
source-code license.

## Marketing artwork

`asset_sources/marketing/civic_nightmare_itch_cover_v1.png` is an original
1260×1000 itch.io cover generated with OpenAI built-in image generation for
the project. It uses the project's own opening-drive background, battered car,
and citizen pose sheet only as visual references. The final composition is new,
contains no third-party source art, and is retained outside the exported runtime.

The five 1280×720 PNGs under `asset_sources/marketing/screenshots/` are direct,
unretouched framebuffer captures of the current Godot runtime. They contain only
project media already documented by this notice and are retained outside the
exported game for itch.io presentation. Their deterministic capture states and
approved upload order are recorded in `asset_sources/marketing/README.md`.

The three 1280×720 PNGs under `asset_sources/marketing/residences/` are likewise
direct, unretouched captures of the current Godot runtime. They show Trump,
Ursula von der Leyen, and Christine Lagarde inside their authored residences and
are retained outside the exported game for the repository README. Their framing
and presentation role are recorded in `asset_sources/marketing/README.md`.
