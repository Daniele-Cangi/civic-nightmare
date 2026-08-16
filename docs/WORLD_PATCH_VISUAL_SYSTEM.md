# World Patch Visual System

## Purpose

Civic Nightmare uses detailed illustrated pixel-art facades over one authored civic ground plate. Those layers feel like one world only when the transition between them is designed as deliberately as either asset. A **world patch** is that transition and is the smallest complete exterior unit.

Each authority patch owns:

- one visual anchor: the facade;
- one terrain seam: contact shadow plus shallow foundation apron;
- one navigation contract: collision footprint, threshold, and approach width;
- one entrance axis shared with the room doorway and NPC spawn;
- one restrained local motif that expresses the district without becoming UI.

The facade is therefore not a collectible sprite placed at a coordinate. It is one layer of a region.

## Lightweight style contract

### Projection and scale

- Keep the current elevated front/orthographic facade projection. Do not mix it with isometric props.
- Authority facades retain the shared 352 px width and paired row heights.
- Doors remain bottom-centre and line up with the exterior entrance tile.
- Character scale remains intentionally smaller than institutional architecture; readable thresholds and contact shadows make that contrast feel authored rather than accidental.

### Palette and contrast

- The district plate carries local colour; facade patches repeat only one dark foundation tone, one identifying edge colour, and one route colour.
- Ground integration remains lower contrast than the facade. It supports the landmark instead of competing with it.
- Saturated accents are reserved for narrative motifs: Trump gold/red spectacle, EU blue procedural routing, Macron ceremonial gold over visible repair.

### Detail density and silhouette

- Highest detail belongs to the facade and its entrance.
- The immediate apron is quieter; local marks form a short visual sentence rather than a prop field.
- Collision follows the visible lower mass, never the projected roof or transparent image corners.
- The final tile before the doorway and the doorway tile itself must remain walkable.

### Shadows and edges

- Use a broad, banded contact shadow beneath the building mass.
- Never create a shadow by duplicating and offsetting the complete facade silhouette; that reads as a pasted sticker.
- A shallow foundation apron may cover the exact transparent-image seam, but must preserve the plate's texture and geometry through restrained alpha.
- Approach markings begin inside the threshold and continue into the existing path network.

### Animation restraint

- Exterior motion should be sparse and local: a warning lamp, surveillance sweep, loose tarp, or unstable sign.
- Do not animate a whole facade to compensate for weak grounding.
- Motion must reinforce the authority's joke and may not reduce doorway readability.

## Current representative patches

- **Trump — spectacle:** a red-carpet funnel and excessive gold access markers convert a civic entrance into an event.
- **Ursula — procedure:** one short walk is divided into formal queue lanes and gates; access is visible and unnecessarily mediated.
- **Macron — managed decline:** a ceremonial inlay remains polished while repair seams and temporary barriers occupy its edges.
- **Putin — control under siege:** a physical raster forecourt of blast walls, sandbags, searchlights, and anti-tank obstacles surrounds one deliberately clear ceremonial route. Its flanking masses own collision while the central threshold remains walkable.

Musk and Lagarde already use the same structural patch contract and collision ownership. Their current motifs are intentionally lighter first passes: prototype launch marks and tiered stability lines. They are the next visual-detail candidates.

## Runtime ownership

`scripts/managers/authority_world_patch_builder.gd` owns patch profiles, collision rows, facade composition, ground contact, and local approach motifs. `main.gd` supplies each existing building specification, registers returned collision cells, and continues to coordinate rooms, NPCs, paths, and story systems.

`WorldLandmarkBuilder` remains responsible for optional static landmarks such as the Great Wall, bunker, nuclear plant, and Pyongyang. Bezos currently enters the overworld as a drone encounter, not a stable landmark; a future Fulfillment Cathedral requires its own world-location decision before it can receive a patch.

## Adding a patch

1. Choose an existing building key, centre, entrance, and NPC spawn as one coordinate contract.
2. Define collision row spans from the visible lower mass of the final facade.
3. Keep the threshold and doorway cells clear.
4. Select a low-contrast foundation/edge/route palette sampled conceptually from the district.
5. Add at most one local motif with a clear narrative purpose.
6. Verify the patch at gameplay zoom and with the player approaching from the central corridor.
7. Extend the smoke assertions before changing unrelated districts.

Raster motifs may replace a procedural motif when the satire depends on recognizable physical props. They remain children of the same patch, use nearest filtering, preserve the entrance axis, and contribute explicit flanking collision cells when their mass occupies walkable ground.
