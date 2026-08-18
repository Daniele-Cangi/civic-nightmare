# Northern Great Wall Art Direction

## Narrative purpose

Xi's exterior is not another building inside one of the six civic plazas. It owns the northern limit of the world. The historic wall has been renovated into a contemporary access-control system: heritage, surveillance, infrastructure, and state theatre become one continuous administrative border.

The central Tiananmen-inspired gate communicates the encounter before dialogue. Its ceremonial red facade and official portrait promise national continuity; cameras, scanners, loudspeakers, cables, cold status lights, and an absurd concentration of checkpoints reveal what that continuity requires. The visual joke is a Great Wall operating as a literal great firewall.

## Runtime contract

- Asset: `assets/landmarks/northern_great_wall_v1.png`.
- Canvas: 2176×448 transparent RGBA, exactly the overworld width.
- Placement: the raster origin is `(-1088, -1427)` so its visible front line lands exactly on the playable north boundary at `y = -1024`; the wall mass remains outside the map.
- Layering: the wall remains behind the two northern authority facades; the central gate occupies the open boulevard between them.
- Gate: one traversable opening on the boulevard's exact visual axis at world `x = 0`, with its `red_command` trigger centered at `y = -976`. The normalization pass shifts the generated arch 19 px left to match that axis.
- Camera: crossing the northern approach gradually raises the overworld framing by 150 px, revealing the gate mass while keeping the citizen on the avenue. Leaving the approach or entering a room restores the neutral camera position.
- Return point: exiting Xi places the player at `(16, -896)`, south of the trigger, preventing an immediate re-entry loop.
- Collision: two shallow solid wings follow the visible wall front while a 128 px central channel remains open.
- Fallback: the former `landmark_great_wall.png` cutout is created only if the full-width asset is unavailable.

The hidden bunker moved from the north-west corner to the western margin between rows. It remains peripheral optional content without puncturing or masquerading as part of Xi's border.

## Production

Built-in Imagegen used the HD world plate and two approved authority facades as rendering-quality references. The production prompt required an extremely wide continuous wall, strict central symmetry, a compact Tiananmen-inspired gate, modern surveillance contamination, an open passage, no readable text, no isolated isometric fragment, and no coarse pixel-art treatment.

The built-in transparent export returned a visible checker matte, so the selected composition received a single background-only chroma pass. `scripts/normalize_northern_wall.py` removes that matte, resizes in premultiplied-alpha space, clears residual key pixels, and writes the exact runtime canvas without altering the architecture.
