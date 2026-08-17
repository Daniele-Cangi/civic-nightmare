# Western Aid Gate

The Western Aid Gate replaces the freestanding pixel-art bunker hatch on the
overworld. It sits on the western map boundary and frames the existing road as
a checkpoint: wartime fortification above the route, immaculate donor/media
infrastructure below it. The encounter flow remains unchanged:

`overworld road -> aid gate -> access gauntlet -> mountain bunker`

The production asset is saved at
`res://assets/landmarks/western_aid_gate_v1.png` as a 576 x 720 transparent PNG.
The legacy bunker art remains available only as a runtime fallback.

## Generation record

Mode: built-in `image_gen`.

### Base generation prompt

```text
Use case: stylized-concept
Asset type: transparent overworld landmark cutout for a modern illustrated political-satire videogame
Primary request: create a Western Aid Gate leading from a city road into a hidden wartime bunker; the architecture must communicate a besieged commander who is also permanently dependent on international donors, logistics and television presentation.
Scene/backdrop: no scene and no floor; a genuinely transparent background with clean alpha.
Subject: one tall border checkpoint oriented vertically, designed to span above and below a horizontal left-to-right road. The exact middle must contain a broad, clearly readable armored drive-through tunnel, open from left to right. Upper wing: cracked reinforced concrete, sandbags, anti-drone cages and netting, antennas, emergency sirens, scorched repair patches. Lower wing: unnaturally immaculate donor/media infrastructure with two TV cameras, one ring light, neutral flag stands, a short ceremonial carpet that abruptly ends at a military barricade, polished aid scanner, stacked green aid crates and conveyor rollers. Integrate the two halves into one plausible gate rather than two separate buildings. Subtle muted blue and weathered yellow light accents, without recognizable national symbols.
Style/medium: premium hand-painted game-environment cutout, contemporary stylized realism, decaying civic infrastructure, detailed but readable at roughly 250 screen pixels; match a modern high-detail game rather than pixel art or sleek science fiction.
Composition/framing: top-down three-quarter game view, tall 4:5 silhouette centered on canvas; the open horizontal passage must sit exactly at mid-height and remain visually unobstructed. Most architectural depth should project toward the right/east side, while a smaller rear portion can extend left/west beyond the map boundary. Strong separate upper and lower silhouettes suitable for two collision masses. No cast shadow beyond the footprint.
Lighting/mood: cold overcast daylight with red emergency practical lights and subdued blue-yellow accents; bleak, bureaucratic and darkly comic rather than heroic.
Materials/textures: chipped concrete, dirty sandbags, bent steel, polished donor-booth plastic, wet cables, battered shipping crates, camera equipment.
Constraints: genuinely transparent background; no backdrop, road, terrain, people, portrait, text, letters, numbers, logos, emblems, trademarks, readable labels or watermark; no objects blocking the central tunnel; clean alpha edges; game-ready isolated asset.
Avoid: generic cave hatch, medieval gate, futuristic sci-fi portal, pristine military base, pure war realism, patriotic propaganda, heroic monument, giant face, pixel art, cartoon clip art.
```

### Geometry correction prompt

```text
Use case: precise-object-edit
Asset type: transparent overworld landmark cutout for a modern illustrated videogame
Input images: Image 1 is the edit target and establishes the exact materials, satirical contrast, detail level, palette and transparent cutout style.
Primary request: reorient only the architecture and passage geometry so this is a west-map-border checkpoint crossed along a horizontal road. The drive-through tunnel must enter through a clearly visible opening on the LEFT edge and exit through a clearly visible opening on the RIGHT edge, running straight left-to-right across the exact vertical midpoint. The upper fortified mass must sit entirely above the road and the lower donor/media mass entirely below it. Do not retain a front-facing bottom entrance or a road aimed toward the top of the image.
Composition/framing: top-down three-quarter game view; tall 4:5 isolated silhouette. Show the structure as a long vertical border barrier with two separated solid wings, above and below a broad unobstructed horizontal central passage. The passage must be readable as open from left to right, with aligned tunnel floor/thresholds touching both side edges. Most depth projects east/right; smaller rear details extend west/left.
Invariants: preserve the cracked concrete, sandbags, anti-drone net, antennas, emergency lights, aid crates, cameras, ring light, flag stands, short red carpet ending at a barricade, scanner and darkly comic contrast between war damage and donor presentation. Preserve contemporary hand-painted stylized realism and clean transparent alpha.
Constraints: change the traffic orientation; no background, floor outside the structure, terrain, people, portrait, text, letters, numbers, logos, emblems, trademarks, readable labels, or watermark; no object may block the central left-right tunnel.
Avoid: a front-facing arch entered from the bottom, a vertical bottom-to-top road, medieval or sci-fi styling, pixel art.
```

### Background extraction prompt

```text
Use case: background-extraction
Asset type: game-ready transparent overworld landmark cutout
Input images: Image 1 is the edit target.
Primary request: remove the entire light gray checkerboard backdrop and convert it to genuine transparent alpha. Also remove only the long exposed asphalt road and curbs extending outside the checkpoint on the far left and far right; retain a short dark metal/concrete tunnel threshold only inside the gate footprint so the game's existing road can remain visible beneath the asset.
Invariants: preserve the Western Aid Gate architecture, exact left-to-right passage geometry, upper wartime fortification, lower donor/media checkpoint, every object, palette, lighting, proportions, camera angle and satirical contrast. Do not redesign, rotate, crop, simplify, repaint, move or add anything.
Constraints: genuinely transparent background with clean alpha edges and no checkerboard pixels; no new background or cast shadow; no text, logos, watermark, people or extra objects; keep the central horizontal passage open and unobstructed.
```

The generated extraction still contained a baked checkerboard. A deterministic
connected-component alpha cleanup removed only the bright neutral background
regions, then the cutout was resized to its runtime dimensions. No game artwork
was painted or rearranged during that cleanup.

### Mechanical barrier prompt

```text
Use case: stylized-concept
Asset type: transparent game prop overlay for the Western Aid Gate
Primary request: a single heavy mechanical checkpoint boom barrier blocking a horizontal roadway, viewed in top-down three-quarter game perspective. The compact armored motor housing and red warning lamp sit at the TOP end; one long narrow steel arm extends vertically DOWNWARD on screen across the lane. The arm has weathered alternating muted yellow and dark red diagonal hazard panels, reinforced hinges, exposed cables and a small hydraulic ram.
Style/medium: premium hand-painted game prop, contemporary stylized realism, matching a detailed decaying concrete military checkpoint; crisp silhouette and readable at about 70 to 100 screen pixels, not pixel art.
Composition/framing: isolated slender vertical object centered with generous transparent margin; approximately 1:3 object silhouette; no road or environment.
Lighting/mood: cold overcast daylight, restrained red emergency glow, worn and bureaucratic rather than futuristic.
Materials/textures: scratched painted steel, grease, chipped enamel, dirty bolts, small glass warning lens.
Constraints: genuinely transparent background with clean alpha; exactly one barrier assembly; no background, floor, road, people, text, letters, numbers, logos, emblems, flags, watermark or cast shadow.
Avoid: simple flat rectangle, traffic sign, medieval object, sleek sci-fi, cartoon clip art, bright toy colors.
```

The barrier is stored at
`res://assets/landmarks/western_aid_gate_barrier_v1.png` as a 32 x 128
transparent PNG. The clearance state hides the barrier and restores the open
passage after the access gauntlet, including after Continue.
