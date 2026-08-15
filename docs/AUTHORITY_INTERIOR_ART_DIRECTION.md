# Authority interior art direction

The authority facades are the public lie. Their interiors are the machines required to keep that lie operational.

Every main-signature interior should therefore answer three questions before adding decoration:

1. What does this authority claim to be?
2. What work is being hidden to sustain that claim?
3. What can the player understand from the room before anyone speaks?

The answer must be architectural and comic, not a collection of national props. Interiors share the same rectangular `608×544` gameplay canvas, bottom-center entrance, central approach lane, NPC interaction contract, and room-transition scene. Their visible geometry may be fully authored when a generic tile layout would flatten the joke. Collision remains code-owned and must follow the visible furniture.

## Authored authority rooms

| Room | Public claim | Interior machine | Visual joke |
|---|---|---|---|
| Trump / Oval Studio | Success, attention and executive dominance | A presidential office rebuilt as a gold-plated broadcast set with ratings screens, cameras, mirrors and applause staging | The prestige is laminate, the cameras outnumber the visitors, and every mirror points toward the central chair. |
| Musk / Permanent Beta | A frictionless interplanetary future | An unfinished private launch room of temporary power, incompatible adapters, prototype debris and demonstrations running before completion | The most expensive console is still powered by a portable generator; the tunnel stops almost immediately. |
| Putin / Continuity Command | Total control and permanent readiness | A subterranean wartime command room of redundant surveillance, cables, generators, telephones and sealed files | The conference table is absurdly long for the room; the reassuring sky exists only on fake backlit windows. |
| Macron / Élysée Salon | Restored grandeur and effortless cultural wealth | A reception set held together by braces, extension leads, screens, buckets and deferred restoration | Everything inside the official camera angle is immaculate; the edges disclose the maintenance debt. |

The contrasts are deliberate. Trump manufactures attention, Musk demonstrates unfinished inevitability, Putin hides the outside world, and Macron hides the inside damage.

## Runtime contract

- Authored backgrounds are opaque full-room images in `assets/interiors/`.
- `scripts/oval_office_room.gd` selects them by room key and skips only the generic visual tile/prop pass.
- `RoomManager` still owns instancing, travel, player reparenting, stable return points and save/resume.
- The shared room scene still owns NPC spawning, dialogue access, exit triggers, lighting and boundaries.
- Furniture collisions are named and authored separately from the raster image so visual iteration does not migrate gameplay ownership into an asset.
- Images contain no characters, UI, text or baked interaction prompts.

## Generation and normalization

Built-in Imagegen produced each environment from a dedicated narrative and gameplay brief. The prompts specified a rectangular top-down/elevated RPG room, a clear bottom-center route, an uncluttered interaction zone, no characters or readable text, current-era managed decline and modern high-detail pixel art.

`scripts/normalize_interior_background.py` center-crops the generated source to the room aspect ratio, resizes it to `608×544`, and applies a light output sharpen. Godot renders the result with nearest texture filtering.

Future rooms should not copy the Putin or Macron layout. They should copy the contract and discover their own political machine.
