# Asset inventory

Snapshot: 2026-08-20. Sizes are raw tracked file sizes, not Godot import-cache
or compressed web-build sizes. Literal `res://` references were used to identify
the conservative runtime closure; dynamic paths and declared fallbacks remain
runtime until a tested cleanup proves otherwise.

## Storage summary

| Area | Files | Raw size | Role |
| --- | ---: | ---: | --- |
| `assets/mockups/` | 78 | 23.11 MiB | Runtime portraits, poses, and selected fallbacks |
| `assets/backgrounds/` | 3 | 10.80 MiB | Runtime overworld plates |
| `assets/interiors/` | 11 | 7.59 MiB | Runtime authored interiors |
| `assets/landmarks/` | 13 | 4.66 MiB | Runtime exterior structures and gates |
| `assets/encounters/` | 8 | 11.69 MiB | Runtime bunker, authority-access stages, and Putin operation billboards/centered weapon |
| `assets/sequences/` | 6 | 14.24 MiB | Runtime opening-drive highway, citizen vehicle, and four civic road set pieces |
| `assets/audio/` | 6 | 13.34 MiB | Five runtime soundtracks plus their delivery note |
| `assets/tiles/` | 21 | 2.32 MiB | Runtime atlases plus legacy grids |
| `assets/runtime/props/` | 6 | <0.01 MiB | Promoted runtime copies of the six referenced vendor props |
| `asset_sources/vendor/` | 164 | 1.12 MiB | Licensed vendor/source pack, retained but not imported or exported |
| `asset_sources/legacy/` | 8 | 9.21 MiB | Superseded v2 world plate, six non-v2 combat portraits, and the diagonal Putin launcher source |
| `asset_sources/marketing/` | 7 | 9.84 MiB | Non-exported itch.io cover, five runtime screenshots, and their delivery record |
| `assets/sprites/` | 2 | 1.01 MiB | Runtime contamination asset and fallback |
| `assets/characters/` | 20 | 0.17 MiB | Small sprites; runtime and alternatives mixed |

Before this cleanup the checkout contained 841 tracked files / 71.58 MiB. The
deterministic Civic Asset Lab output accounted for 380 files / 8.60 MiB and had
no runtime references. It has been removed from tracking and now regenerates in
`tmp/generated/civic_asset_lab/`. Together with the small inventory/policy files
and six promoted props, the checkout before the authority-access games was
roughly 473 files / 63 MiB. The three authority-access runtime stages brought it
to about 69.8 MiB. The complete opening-drive art group now contributes 14.24
MiB of intentional runtime art: 4.65 MiB for its background and vehicle plus
9.59 MiB for four physical civic set pieces.

A local Godot 4.6 Standard Web export after separation produced a 37.93 MiB PCK,
down from the 43.44 MiB PCK in the previously deployed Pages tree. WASM remains
35.29 MiB because it is engine code, not project media.

The conservative literal runtime closure is now 119 files / about 85.07 MiB.
The gap is
not deleted automatically: it contains fallbacks, README media, vendor sources,
and older art whose provenance should be retained before removal. The three
authority-access stages add about 6.76 MiB of intentional runtime artwork.

## Ownership and promotion rule

| Location | Exported | Tracked | Intended contents |
| --- | --- | --- | --- |
| `assets/` | Yes | Yes | Runtime-ready art with a concrete code/data owner or declared fallback |
| `asset_sources/` | No (`.gdignore`) | Yes | Editable masters, licensed inputs, and deliberately retained archives |
| `tmp/generated/` | No | No | Reproducible previews and generator output |
| `.godot/` | No | No | Godot import cache |
| `build/` / `artifacts/` | No | No | Disposable export and CI output |

Promoting an image into `assets/` requires: a runtime reference, provenance or
generation note, confirmed rights, and parse/smoke/export verification.

## Runtime groups and provenance

| Group | Runtime owner | Provenance / rights source |
| --- | --- | --- |
| World plates and authority facades | `main.gd`, `AuthorityWorldPatchBuilder`, `WorldLandmarkBuilder` | Project-authored/generated art; repository media policy in `ASSET_NOTICE.md` |
| Interiors | `oval_office_room.gd` | Project-authored/generated art; room art-direction documents |
| Character portraits and expressions | `character_visual_catalog.gd`, dialogue/encounter modules | Mixed project-specific generated and curated art; see `ASSET_NOTICE.md` |
| Authored encounter stages | `bunker_access_gauntlet.gd`, `greatest_deal.gd`, `consensus_engine.gd`, `price_stability_pinball.gd`, `putin_special_operation.gd` | Project-authored/generated art; runtime promotion recorded in `ASSET_NOTICE.md` |
| Putin-operation figures | `putin_special_operation.gd` | Four original corridor/boss billboards, including the transparent Strategic Bear washing-machine cutout; OpenAI built-in generation provenance recorded in `ASSET_NOTICE.md` |
| Opening-drive art | `intro_sequence.gd` | Project-specific OpenAI-generated art; prompts and delivery contract recorded in `ASSET_NOTICE.md` and `docs/OPENING_DRIVE_SEQUENCE.md` |
| Opening-drive music | `intro_sequence.gd` | **Coastline Dash**, generated with Google Flow Music and delivered by project owner Daniele Cangi; runtime conversion and generation disclosure recorded in `ASSET_NOTICE.md` |
| Putin-operation music | `putin_special_operation.gd` | **Three-Minute Special Operation**, generated with Google Flow Music and delivered by project owner Daniele Cangi; runtime conversion and generation disclosure recorded in `ASSET_NOTICE.md` |
| Overworld music | `environment_effects.gd` | **Dead Man's Hand**, generated with Google Flow Music and delivered by project owner Daniele Cangi; intro-preserving loop conversion and generation disclosure recorded in `ASSET_NOTICE.md` |
| Greatest Deal music | `greatest_deal.gd` | **Snake Eyes**, generated with Google Flow Music and delivered by project owner Daniele Cangi; silent-tail removal, entrance-preserving loop conversion, and generation disclosure recorded in `ASSET_NOTICE.md` |
| itch.io marketing set | no runtime owner | Original generated cover plus five direct Godot framebuffer captures; prompt, capture states, and upload order recorded under `asset_sources/marketing/` |
| Six promoted civic props | `oval_office_room.gd` | Pixel-boy/LimeZu subset; retained source and licenses in `docs/ASSET_PACKS.md` |
| Civic Asset Lab previews | no runtime owner | Deterministic local generator; disposable output under `tmp/` |

## Large-file policy

Runtime PNGs remain in ordinary Git. No current `main` asset exceeds 6.4 MiB,
and every Actions checkout and web export needs the runtime files; LFS would add
bandwidth/quota friction without reducing the PCK. `.gitattributes` reserves LFS
for heavyweight editable formats under `asset_sources/` only. GitHub Pages
artifacts must remain ordinary deployed files, never LFS pointers.

## Deployment-history finding

The dominant repository-history cost was not `main`: the local `gh-pages`
history contained roughly 1.78 GiB of repeated PCK/WASM blobs. The deploy action
now uses `single-commit: true`, so the next successful main deployment replaces
that branch history with the current site only. This intentionally discards old
deployment commits, not source history or the live build.

## Follow-up candidates (not deleted in this batch)

- Thirteen unused grid/tile files (about 2.08 MiB).
- Unreferenced mockups and small character alternatives.

Move these in small provenance-preserving groups to `asset_sources/` or remove
them only after parse, smoke, web export, and a manual browser pass.
