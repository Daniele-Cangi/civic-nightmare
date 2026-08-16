# World Patch Visual System

## Purpose

Civic Nightmare uses high-detail illustrated facades over one authored civic ground plate. Those layers feel like one world only when the transition between them is designed as deliberately as either asset. A **world patch** is that transition and is the smallest complete exterior unit.

Each authority patch owns:

- one visual anchor: the facade;
- one terrain seam: a soft contact shadow plus a minimal threshold seam;
- one navigation contract: collision footprint, threshold, and entrance clearance;
- one entrance axis shared with the room doorway and NPC spawn;
- an optional physical raster motif that expresses the district without becoming UI.

The facade is therefore not a collectible sprite placed at a coordinate. It is one layer of a region.

## Lightweight style contract

### Projection and scale

- Keep the current elevated front/orthographic facade projection. Do not mix it with isometric props.
- Authority facades retain the shared 352 px width and paired row heights.
- Doors remain bottom-centre and line up with the exterior entrance tile.
- Character scale remains intentionally smaller than institutional architecture; readable thresholds and contact shadows make that contrast feel authored rather than accidental.
- Exterior background, facades, and authored raster motifs use linear filtering as one HD illustrated layer; low-resolution character sprites retain their own deliberate language.

### Palette and contrast

- The district plate carries local colour; facade patches repeat only one restrained foundation tone and one identifying edge colour.
- Ground integration remains lower contrast than the facade. It supports the landmark instead of competing with it.
- Saturated accents are reserved for narrative motifs: Trump gold/red spectacle, EU blue procedural routing, Macron ceremonial gold over visible repair.

### Detail density and silhouette

- Highest detail belongs to the facade and its entrance.
- The immediate contact zone is quieter; physical local props form a short visual sentence rather than a prop field.
- Collision follows the visible lower mass, never the projected roof or transparent image corners.
- The final tile before the doorway and the doorway tile itself must remain walkable.

### Shadows and edges

- Use one broad, soft contact shadow beneath the building mass.
- Never create a shadow by duplicating and offsetting the complete facade silhouette; that reads as a pasted sticker.
- Do not add a hard-edged foundation apron. A short low-alpha threshold seam may cover the exact transparent-image join without becoming a platform.
- Do not paint approach markings over the authored plaza. Paving geometry communicates circulation; the patch only preserves a clear threshold.

### Animation restraint

- Exterior motion should be sparse and local: a warning lamp, surveillance sweep, loose tarp, or unstable sign.
- Do not animate a whole facade to compensate for weak grounding.
- Motion must reinforce the authority's joke and may not reduce doorway readability.

## Current representative patches

- **Putin — control under siege:** a physical raster forecourt of blast walls, sandbags, searchlights, and anti-tank obstacles surrounds one deliberately clear ceremonial route. Its flanking masses own collision while the central threshold remains walkable.

Trump, Musk, Ursula, Lagarde, and Macron currently rely on facade, contact, and the authored plaza without procedural route graphics. Future district satire must arrive as grounded physical raster material with matching collision, not lines painted over the floor.

## Runtime ownership

`scripts/managers/authority_world_patch_builder.gd` owns patch profiles, collision rows, facade composition, ground contact, and optional physical motifs. `main.gd` supplies each existing building specification, registers returned collision cells, and continues to coordinate rooms, NPCs, paths, and story systems.

`WorldLandmarkBuilder` remains responsible for optional static landmarks such as the Great Wall, bunker, nuclear plant, and Pyongyang. Bezos currently enters the overworld as a drone encounter, not a stable landmark; a future Fulfillment Cathedral requires its own world-location decision before it can receive a patch.

## Adding a patch

1. Choose an existing building key, centre, entrance, and NPC spawn as one coordinate contract.
2. Define collision row spans from the visible lower mass of the final facade.
3. Keep the threshold and doorway cells clear.
4. Select a low-contrast foundation/edge palette sampled conceptually from the district.
5. Add at most one physical local motif with a clear narrative purpose.
6. Verify the patch at gameplay zoom and with the player approaching from the central corridor.
7. Extend the smoke assertions before changing unrelated districts.

Raster motifs remain children of the same patch, use linear filtering, preserve the entrance axis, and contribute explicit flanking collision cells when their mass occupies walkable ground.
