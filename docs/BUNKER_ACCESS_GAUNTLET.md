# Bunker access gauntlet

The western bunker route is a short playable contradiction rather than a longer walking corridor. The citizen crosses one shared logistics floor where bombardment enters from the exterior and funding leaves through administrative machinery. The joke is environmental and mechanical: both are treated as transfer traffic.

## Runtime grammar

- The encounter lasts 55 seconds after a brief controls-only reveal.
- Arrow keys move; `SPACE` performs a short dash with a visible cooldown.
- Bombs announce their impact area before falling. A hit removes one of four case sheets and knocks the citizen away.
- Wrapped funding moves through fixed lanes. Contact does not directly damage the citizen; it slows movement long enough to make the next bomb more dangerous.
- The first phase teaches bomb telegraphs, the second adds funding traffic, and the final phase combines both at higher density.
- Losing all case sheets produces `PROCESS RETURNED` and restarts the encounter automatically. There is no log, tutorial prose, or separate retry screen.
- Surviving emits one semantic `access_granted` result and continues through the existing hidden-bunker door.

The Fantozzi-like citizen poses are reused from the Bezos encounter so the playable identity stays consistent. Bombs, transfer packages, warning rings, damage feedback, HUD, and audio are code-owned because their geometry and timing must remain exact. The authored raster is restricted to the static environment.

## Persistence and dossier

The game writes its latest safe exterior checkpoint immediately before the encounter. It never serializes a bomb, timer, partial health state, or mid-run position. A quit or reload therefore returns outside the bunker; a completed run persists `bunker_access_complete` and never demands the corridor again.

Completion creates `investigation:bunker_access_corridor` with attempts, bomb hits, funding contacts, dash count, and elapsed time as raw evidence. Administrative Hold translates that evidence into bureaucratic language rather than exposing it as an RPG statistic. The existing bunker sequence separately records the deliberate protocol deviation after entry.

## Visual asset

`assets/encounters/bunker_aid_corridor_v1.png` is a 16:9 modern illustrated environment with a clear floor between an exterior blast gate and a fortified authorization door. Detail remains around the perimeter so hazards and the citizen silhouette remain readable.

The production image was generated with the built-in `imagegen` tool in generation mode. Final prompt:

> Use case: stylized-concept-art, production game background asset. Create a single widescreen 16:9 environmental background for the Godot game “Civic Nightmare”, intended to fill a 1280×720 gameplay viewport. Scene: a short enclosed wartime transfer corridor viewed in a clear elevated frontal / shallow top-down hybrid perspective, with an open battered blast gate on the far left and a massive fortified bunker authorization door on the far right. The central floor from roughly 8% to 92% width and 32% to 84% height must remain visually open, flat, and immediately readable as a dodge arena. Place environmental detail only along the back wall and extreme edges: cracked concrete, sandbags, exposed pipes, fluorescent strips, red emergency lamps, cable trays, pallet jacks, aid crates, administrative conveyor hardware, a few dollar-green wrapped pallets. Satirical visual premise: incoming bombardment and outgoing funding bureaucracy share the same corridor, but communicate this through props and composition, not written exposition. Style: highly detailed modern hand-painted game environment, decaying present-day military bureaucracy, grounded and recognizable, cohesive with premium illustrated adventure-game backgrounds; absolutely not pixel art, not futuristic sci-fi, not cyberpunk. Palette: dirty blue-gray concrete, desaturated olive, restrained dollar-green and dull gold accents, red warning light. Strong depth, contact shadows, subtle smoke/dust, dramatic but readable lighting. No characters, no people, no missiles or bombs in flight, no loose money bundles in the playable floor, no user interface, no labels, no flags, no logos, no readable text, no watermark. Make the two doors and open central arena unmistakable at gameplay scale.
