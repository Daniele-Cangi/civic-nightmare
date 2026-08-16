# Authority facade art direction

The six required-signature exteriors are character portraits expressed through architecture. They depict a recognizable contemporary civic order in managed decline: every authority keeps the system looking functional by denying failure in a different way.

## Narrative contract

| Authority | Official claim | Architectural contradiction |
| --- | --- | --- |
| Trump | Everything is magnificent. | Gold, staging, and media lighting cover structural neglect. |
| Musk | The future is almost ready. | A contemporary factory remains in permanent-beta construction. |
| Ursula | The procedure is transparent. | Glass entrances multiply until access becomes impossible. |
| Putin | Everything is under control. | A ceremonial residence has been consumed by wartime defenses. |
| Lagarde | The situation is stable. | Calm and luxury upstairs depend on moving consequences downstairs. |
| Macron | The grandeur remains intact. | An expensive official facade conceals unresolved decay. |

The satire must survive without dialogue, signage, or character portraits. At gameplay scale, each building needs one large readable contradiction rather than many tiny jokes.

## Shared runtime contract

- elevated three-quarter frontal/top-down RPG perspective;
- modern high-detail illustrated 2D game art with crisp material definition and a restrained palette;
- one complete freestanding contemporary building with a readable entrance at the exact bottom center;
- strong silhouette at 352 px runtime width;
- upper-left key light with practical lights contained inside the building;
- transparent background with no baked cast shadow, people, vehicles, readable text, logos, watermark, or detached scenery;
- paired canvas heights by district row: 330 px top, 320 px middle, 298 px bottom.

## Production briefs

- **Trump — spectacle as maintenance:** White House massing fused with a luxury resort and casino entrance. An immaculate gold-and-ivory center is flanked by gold-wrapped scaffold columns, roof tarps, mismatched repairs, overworked utilities, media lights, and one conspicuously renovated wing.
- **Musk — the present in permanent beta:** a contemporary automotive factory, data center, and launch-company campus. A polished black-glass center sits between unfinished prefab wings, exposed cable trays, patchy solar arrays, and a conventional rocket stage under maintenance. Crossed structural trusses create the dominant `X` silhouette without signage.
- **Ursula — inaccessible transparency:** a Berlaymont-inspired cobalt-glass headquarters. Nested vestibules, redundant portals, modular annexes, sealed transparent entrances, and barrier corridors turn formal openness into an architectural labyrinth.
- **Putin — ceremonial siege:** a Kremlin-inspired red-brick residence transformed into a hardened active fortress. Anti-drone cages, armored windows, blast walls, sandbags, cameras, antennae, and bunker systems surround one absurdly pristine gilded entrance and red carpet.
- **Lagarde — stratified stability:** a contemporary central bank divided vertically. Immaculate warm upper floors sit above patched public infrastructure, narrowed stairs, shuttered services, trapped receipts, and an elegant economic dial mechanically clamped to its calm position.
- **Macron — grandeur as scenery:** an Élysée-inspired palace whose polished ceremonial center survives between mismatched roof repairs and an entire damaged wing hidden behind a trompe-l'oeil construction scrim on gilded scaffolding.

## Generation and preparation

Built-in Imagegen generated each facade from a dedicated production brief on a removable `#FF00FF` background. Putin established the new density and camera contract; the remaining images used an approved facade only as a style, angle, scale, crispness, and lighting reference, never as an architectural template.

The installed chroma-key helper removes flat backgrounds with a soft matte and despill. `scripts/normalize_authority_facade.py` then clears residual key pixels, crops the visible subject, downsamples it with high-quality filtering, centers it horizontally, bottom-aligns its entrance, and writes the correct 352 px runtime canvas. Exterior facades now use linear texture filtering so their pre-rendered material detail shares one visual scale with the HD district plate. Procedural footprints remain the collision source.
