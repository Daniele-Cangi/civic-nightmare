# Southern Administrative Annex art direction

Kim Jong-un and Sam Altman no longer occupy unrelated corners of the main district. A single gate on its southern boundary leads to a smaller optional exterior whose geography supplies the joke: military inevitability and frictionless AI progress are two incompatible public performances running on the same neglected municipal infrastructure.

## Runtime contract

- Main-map gate: `res://assets/landmarks/southern_annex_gate_v1.png`, 576×288 RGBA, bottom-centred at world `y = 1024`.
- Area plate: `res://assets/backgrounds/southern_administrative_annex_v1.png`, 1536×1024 opaque RGBA.
- Area scene: `res://scenes/areas/southern_annex.tscn`, positioned away from the main world and registered through `RoomManager` as an exterior travel container.
- West bay: Kim's existing 448×352 broadcast-artillery landmark, centred on the authored medallion at local `(352, 640)`.
- East bay: Sam's existing 480×320 inference-reactor landmark, centred on the authored medallion at local `(1184, 640)`.
- Access thresholds are independent from landmark centres: Kim uses the red security threshold at `(272, 700)` and Sam uses the demonstration stairs at `(1184, 700)`. Return markers sit south of both triggers to prevent transition loops.
- The landmark roots, access triggers and collisions retain those gameplay coordinates. Only the rendered sprites receive plate-registration offsets: Kim `(-80, 95)` and Sam `(0, 102)`, placing the doors painted into the art over the corresponding background thresholds.
- The central gate passage is open; its two checkpoint wings are solid.
- Both interiors return to named markers in the annex. The annex returns north of the main-map gate trigger.
- Camera limits follow each opaque plate so no unauthored void appears at an edge.
- Save checkpoints persist both global position and exterior area identity.

## Gate

The gate is a decayed municipal arch split into two incompatible service desks. The western half stages authority with olive machinery, red curtain, sandbags and a theatrical floodlight. The eastern half stages competence with white glass, cyan light, a potted plant and an implausible stack of air conditioners. Obsolete shared utilities are tucked into their side alcoves; the middle remains a visibly traversable road.

Final generation prompt:

> Create an isolated front-facing elevated-orthographic videogame landmark for Civic Nightmare: a broad, low Southern Administrative Annex gate built from aging municipal concrete and brushed steel. Keep a large open central road passage beneath a blank civic plaque. Make its west checkpoint an olive/red propaganda booth with a theatrical curtain, floodlight, sandbags and raised red-white barrier. Make its east checkpoint an immaculate white/cyan corporate booth with glass, one potted plant, cooling hose, stacked domestic air conditioners and a raised blue-white barrier. Both halves depend on old printer hardware, loose cables and a rented yellow generator, but keep those utilities inside the side service alcoves. Wide compact silhouette, contemporary decayed materials, neutral daylight, high-detail modern illustrated game art, not pixel art or science fiction. Isolate the complete object on solid `#FF00FF`. No ground, road, scenery, characters, vehicles, flags, logos, UI or readable text.

The selected composition received one targeted edit before normalization:

> Preserve the gate exactly as designed. Remove the old printer, yellow generator, cable coils, loose boxes and every low prop from the central pedestrian/road corridor. Relocate those humorous obsolete municipal utilities into the side service alcoves without changing architecture, silhouette, camera, materials or lighting. Leave a generous uninterrupted magenta floor channel through the exact horizontal centre, suitable for a videogame walk-through trigger. Do not crop or redesign the gate and do not add any new object to the passage.

`scripts/normalize_optional_landmark.py` removes the magenta key, hardens the source alpha before the final antialiased resize, bottom-centres the subject and writes the 576×288 runtime canvas.

## Exterior plate

The west side is a state-propaganda production yard: parade markings, floodlight tracks, cables, sandbags and the visible plywood backs of prestige. The east is an AI demonstration campus: pale concrete, cyan channels, curated planting and a visibly desperate cooling problem. The south edge exposes patched pipes, rented boxes, analog meters, drainage and one leaking culvert shared by both visions.

Final generation prompt:

> Create a finished 1536×1024 full-frame videogame area background for Civic Nightmare. Match the existing district plate's elevated top-down/front orthographic camera, paving scale, material density and crisp high-resolution illustrated finish. Fill every pixel with authored environment; no transparency, frame, UI, text, people or vehicles. Integrate the rear face of the Southern Administrative Annex gate into the top-centre perimeter, with a broad road entering through it and splitting west/east around a shabby shared administration island. Build the west zone as an olive/red propaganda production yard with faded ceremonial carpet strips, television-camera cable trenches, parade marks, plywood scenic supports, sandbags and loudspeaker wiring. Leave a large clean empty landmark bay centred near `(480, 580)` for Kim's separate asset. Build the east zone as a pale-concrete/cyan AI demonstration campus with curated gravel, tiny gardens, cable covers, cooling grates, extension conduits, patched transformers and excessive external air conditioning. Leave a large clean empty landmark bay centred near `(1056, 580)` for Sam's separate asset. Along the southern edge reveal both zones feeding the same obsolete municipal service strip: cracked pipes, patched drains, analog meters, rented yellow utility boxes, mismatched cables and a leaking culvert. Preserve clear playable loops and connectors; use integrated seams, rails, drains and paving changes instead of carpet-like entrance rectangles. Neutral overcast daylight; warmer olive/red/rust west, colder white/cyan/steel east, civic gray/brown/yellow south. Modern decayed present, not pixel art, futuristic science fiction or aerial photography. Do not paint either landmark into the plate.
