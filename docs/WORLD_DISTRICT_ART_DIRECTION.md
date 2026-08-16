# World District Art Direction

## Runtime contract

- Final asset: `assets/backgrounds/world_district_plate_v3.png`.
- Runtime size: 2176×2048 px, exactly matching the overworld bounds.
- Placement: centered at world origin, linearly filtered, `z=-10`.
- Authority centers: `x = ±528` and `y = -683 / 0 / 683`. These are the nearest symmetric tile-centred positions to the plate's two quarter-width axes.
- The complete compound moves as one unit: facade, contact shadow, collision footprint, entrance, NPC, light, and optional physical motif.
- The plate is fully opaque and collision-neutral. It supplies flat traversable civic surfaces and the visible perimeter treatment; runtime systems continue to own navigation and collision.
- Legacy 32 px trees, bushes, flowers, rocks, and border tiles are suppressed whenever the HD plate loads. Invisible edge collision remains active, and the legacy decoration path remains available only as the missing-asset fallback.
- The north edge is intentionally no longer neutral ground: Xi's full-width Great Wall begins exactly at the map boundary and converts the central boulevard into its only visible administrative gate.
- No procedural carpet, runway, queue, or colored route is painted over the authored plazas.

## Visual standard

The overworld no longer imitates the low-resolution structure tiles that originally supplied the game. The authority facades established a different technical level: high-detail pre-rendered 2D illustration with convincing materials, controlled depth, and contemporary production density. The ground now belongs to that same layer.

The plate uses one coherent municipal material system across a two-column/three-row plan: large-format stone, civic concrete, dark asphalt, brushed metal seams, inset glass, drainage, restrained flush accents, and believable repair. District identity comes from material and palette rather than six disconnected biomes.

The six plaza accents remain restrained:

- graphite, steel, and sparse cyan for Musk;
- ivory stone and warm brass for Trump;
- cold gray with dark-red security seams for Putin;
- pale institutional stone and cobalt inlays for Ursula;
- weathered warm limestone and dusty-rose repair for Macron;
- charcoal-green stone and quiet brass for Lagarde.

Large calm facade footprints, the central boulevard, and the three east-west connections remain visually open. Building approaches are implied by continuous paving joints; nothing resembling UI tells the player where to walk.

## Generation and preparation

Built-in Imagegen generated the selected plate from the authority facades as rendering-quality references, without reusing the old plate as a style target. The prompt required a near-square 17:16 orthographic ground plane, six empty plaza pads on a strict 2×3 grid, one central boulevard, flat traversable materials, and no buildings, characters, freestanding props, text, route carpets, visible tile repetition, coarse 16-bit treatment, or photoreal aerial perspective.

The selected 1293×1217 source already matched the exact world ratio. It was resampled with high-quality bicubic filtering to 2176×2048, converted to an opaque RGB PNG, and retained as a new version rather than overwriting the previous plate.
