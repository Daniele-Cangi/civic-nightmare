# Authority facade art direction

The six required-signature exteriors are production hero assets rather than enlarged roof icons. They share one runtime contract:

- elevated three-quarter frontal/top-down RPG perspective;
- modern high-detail pixel art with coherent clusters and a limited palette;
- a strong, symmetrical silhouette at 352 px runtime width;
- roof visible from above and a readable entrance at the exact bottom center;
- upper-left key light with practical lights contained inside the building;
- transparent background, no cast shadow, text, logo, people, vehicles, or detached scenery.

## Generation prompt set

The assets were generated with the built-in image generation tool. Trump established the visual reference; the other five prompts used that image strictly as the style, angle, pixel-density, lighting, and silhouette-readability reference.

Common prompt:

> Create a production-ready hero building sprite for a Godot top-down 16-bit RPG overworld. Use modern high-end pixel art, a coherent 16-bit/32-bit hybrid, crisp deliberate pixel clusters, limited palette, strong readable silhouette, and enough detail to sit beside 32×32 world tiles. Show one complete freestanding building from an elevated three-quarter frontal/top-down perspective, centered with generous padding, roof visible, and a clearly usable entrance at the exact bottom center. Use a perfectly flat solid `#FF00FF` removable background. Do not include ground, scenery, people, vehicles, readable text, logos, watermark, cast shadow, contact shadow, or detached objects.

Architecture briefs:

- **Trump:** neo-baroque courthouse fused with a luxury casino and presidential monument; oval mass, dark layered roof, monumental gold eagle, ivory columns, navy glass, crimson carpet.
- **Musk:** black-glass rocket hangar fused with an automated headquarters; diamond silhouette, central stainless launch spine, graphite wings, cyan glass, vents and integrated antenna arrays.
- **Ursula:** monumental European glass bureaucracy palace becoming a regulatory labyrinth; cobalt crescent, formal ivory block, nested wings, gold medallions and integrated turnstile forms.
- **Putin:** brutalist Kremlin fortress fused with a hardened state bunker; red masonry, concrete core, oxidized green roofs, squat watchtowers, armored vents and sparse amber windows.
- **Lagarde:** octagonal central-bank temple fused with a precision vault; charcoal stone, stepped roof, brass mechanisms, teal-black windows and a usable circular vault entrance.
- **Macron:** elegant Élysée palace beginning to decay; pale neoclassical wings, midnight-blue mansard roof, restrained tricolor accents, mismatched repairs and one integrated scaffold.

## Runtime preparation

Generated chroma-key sources are converted to alpha with a soft matte and despill, then resized to 352 px width with nearest-neighbour sampling. Godot uses nearest texture filtering. The facade bottom edge is aligned to the existing doorway, while the procedural footprint continues to provide collision. A dark offset duplicate supplies the world-space shadow.
