# Western Aid Gate

The Western Aid Gate replaces the freestanding pixel-art bunker hatch on the
overworld. It sits on the western map boundary and frames the existing road as
a checkpoint: wartime fortification above the route, immaculate donor/media
infrastructure below it. The encounter flow remains unchanged:

`overworld road -> aid gate -> access gauntlet -> mountain bunker`

The production environment patch is saved at
`res://assets/backgrounds/western_aid_district_patch_v1.png` as a 560 x 700
opaque crop. It repeats the original district plate at its feathered outer
edges, so it reads as part of the map rather than a transparent landmark. The
previous gate cutout and legacy bunker art remain available as runtime
fallbacks.

## Generation record

Mode: built-in `image_gen`.

### Integrated environment prompt

```text
Use case: compositing
Asset type: exact overworld environment patch for a top-down political-satire videogame
Input images: Image 1 is the edit target and the absolute source of truth for canvas, geometry, perspective, road position, palette, texture density, haze, contrast and lighting. Image 2 is narrative reference only for the Western Aid Gate's wartime-versus-donor-media idea; do not copy its frontal perspective, floating platform, sharp photorealism or cyan status light.
Primary request: transform only the LEFT edge of Image 1 into an environment-integrated Western Aid checkpoint leading off-map to a hidden wartime bunker. It must look as if it was authored as part of Image 1, never like a transparent building pasted on top.
Composition/framing: preserve Image 1's exact portrait canvas and orthographic top-down map view. The existing horizontal road through the vertical center remains exactly where it is and must continue cleanly through a broad left-facing bunker passage at the far-left boundary. Keep the entire rightmost 40 percent visually unchanged. Confine new architecture to roughly the left 45 percent. Build an upper fortified wing into the existing upper-left retaining wall and a lower donor/media checkpoint directly into the existing lower-left pavement; leave the center road completely open from right to the left edge.
Subject/details: upper wing uses low-profile cracked reinforced concrete, embedded sandbags, a small anti-drone net, antennas and repaired blast damage. Lower wing uses grounded aid crates, one compact customs scanner, two small television cameras and a deliberately short faded red carpet painted or laid directly on dirty pavement, ending at a military barrier. Add restrained tire marks, soot, cable trenches, road repairs and concrete transitions that physically connect every object to the base map. Use only subtle weathered blue and muted yellow identification accents.
Satirical intent: a besieged wartime logistics checkpoint forced to remain camera-ready for international donors; bleak and bureaucratic, not heroic.
Style/medium: match Image 1 exactly: premium illustrated map plate, nearly orthographic top-down perspective, cool gray desaturated palette, lifted blacks, soft atmospheric wash, restrained edge sharpness, fine architectural linework and the same apparent scale. The gate must inherit the background's flatter rendering rather than Image 2's three-dimensional cutout look.
Invariants: preserve Image 1's road alignment and scale, all geometry outside the left integration zone, and especially the top, bottom and right canvas edges for seamless compositing. Preserve an unobstructed central driving/walking lane.
Constraints: opaque environment patch; no transparent/checkerboard background; no floating slab, island, balcony or diorama; no front-facing monumental arch; no player or human figures; no portraits; no cyan dot; no UI markers; no text, letters, numbers, logos, emblems, readable labels or watermark; no large clean flags; no object blocking the central road.
Avoid: pasted-on landmark, mismatched perspective, saturated colors, hard black shadows, ultra-sharp photorealism, sleek science fiction, heroic monument, medieval gate, pixel art.
```

The first 560 x 700 pixels of the relevant district crop were used as the edit
target. The generated result was resized to that exact contract, color-matched
against the unchanged right side of the original plate, and blended back into
the source crop with cosine-feathered top, bottom and right edges. The rightmost
edge is therefore pixel-identical to the original background.

## Previous transparent cutout record

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
