# World District Art Direction

## Runtime contract

- Final asset: `assets/backgrounds/world_district_plate_v2.png`.
- Runtime size: 2176×2048 px, exactly matching the overworld bounds.
- Placement: centered at world origin, nearest-neighbour filtered, `z=-10`.
- Authority alignment contract: visible facade centers sit near world coordinates `x = ±528` and `y = -683 / 0 / 683`, the centers of the plate's six panels. Logical building centers vary slightly by facade because image heights and doorway offsets differ; runtime placement keeps facade, collision, entrance, NPC, light, and route together.
- All six authorities have bespoke collision footprints matched to the visible lower mass of their facade sprites; their obsolete procedural silhouettes are not retained invisibly.
- The plate is fully opaque and collision-neutral. It supplies visible civic paving; `AuthorityWorldPatchBuilder` adds the local terrain seam, approach motif, facade, and collision while the remaining props and triggers stay runtime-owned layers.
- The field atlas remains a fallback only; its opaque center cells are used if the plate cannot load.

## Final prompt set

Built-in Imagegen was used with the six authority facades as style references. The generation prompt requested one orthographic, edge-to-edge, modern pixel-art civic ground map arranged as two columns by three rows, with quiet landmark clearings connected by a restrained central administrative corridor. District briefs were graphite/cyan launch campus for Musk, manicured ivory/lawn grounds for Trump, snow/red-stone security grounds for Putin, cobalt institutional plaza for Ursula, dusty-rose repaired civic garden for Macron, and dark-green/brass financial paving for Lagarde.

The selected second pass preserved that layout and palette while removing every raised or obstacle-like element. Trees, walls, railings, lamps, machinery, and props were converted to walkable inlaid paving, painted edging, drainage lines, surface repairs, and subtle ground mosaics. It also softened hard horizontal transitions with shared grey-blue municipal paving.

Negative constraints for both passes: no buildings, characters, vehicles, readable text, flags, logos, UI, watermarks, perspective horizon, isometric camera, transparent gaps, horizontal banding, tile-grid seams, or collectible-looking details.

## Processing

The selected square source was normalized to a 1088×1088 pixel-art working grid, enlarged with nearest-neighbour sampling, and cropped symmetrically to the exact 2176×2048 world ratio. The source remains a visual layer only; it does not redefine navigation geometry.
