# Marketing artwork

`civic_nightmare_itch_cover_v1.png` is the approved itch.io cover master.

- Canvas: 1260×1000 PNG, exact 315:250 / 5:4 itch.io cover ratio.
- Safe delivery: upload the master directly; itch.io can derive its 630×500 and
  315×250 listing presentations without changing the crop.
- Runtime: no owner. `asset_sources/.gdignore` keeps it outside Godot import and
  Web export.
- Generation: OpenAI built-in image generation, 2026-08-18.
- Reference image 1: `assets/sequences/opening_drive_sunset_v2.png` for palette,
  sunset highway, and distant administrative architecture.
- Reference image 2: `assets/sequences/opening_drive_car_v1.png` for the battered
  economy-car design.
- Reference image 3: `assets/mockups/citizen_battle_poses.png` for the citizen's
  body, clothing, passport, and paperwork language.
- Processing: generated output was center-cropped by less than one percent and
  resized with Lanczos filtering to the exact 1260×1000 delivery canvas. No
  generative edit was applied after selection.

## Final prompt

```text
Use case: ads-marketing
Asset type: itch.io videogame cover, exact 5:4 landscape composition, designed to remain readable at 315x250 thumbnail size.
Primary request: Create a completely new illustrated key-art cover for the satirical videogame Civic Nightmare. It should look like the sincere, gloriously excessive box art for an ambitious late-1980s Japanese arcade road adventure, while the actual hero and vehicle reveal the bureaucratic absurdity.
Input images: Image 1 is a palette, atmosphere, sunset-highway and administrative-district reference; Image 2 is the battered economy car design reference; Image 3 is the citizen character identity and clothing reference. Reinterpret them into one unified new illustration, not a collage and not a screenshot.
Scene/backdrop: A monumental administrative district fills the distant horizon at the end of a dramatic central highway. The architecture should suggest six distinct absurd institutions as one coherent skyline, imposing, contemporary, slightly decayed, bureaucratic rather than generic futuristic. A huge striped sunset and faint CRT scan texture frame the district.
Subject: In the lower foreground, the battered beige economy hatchback from Image 2 is stopped crookedly, smoking and losing one small body panel. Beside it stands the anxious, thin citizen from Image 3 in a worn brown suit, white shirt and red striped tie, clutching a dark blue passport and a chaotic folder of stamped documents. He is clearly readable at thumbnail scale, overwhelmed but still facing the district.
Style/medium: Original polished game-cover illustration; modern high-detail rendering unified with deliberate late-1980s arcade poster color separation and subtle pixel/CRT texture. Strong clean silhouettes, not photorealistic, not childish.
Composition/framing: Exact 5:4 landscape. Strong central road perspective. Keep the citizen and car together across the bottom third, large enough to read. Keep the upper quarter relatively uncluttered for the title. Monumental district centered behind them. No portraits or collage panels.
Lighting/mood: Heroic coral-magenta sunset, cyan-blue shadows, excessive gold institutional highlights. Warm, exhilarating and adventurous; the satire comes from the miserable car and impossible bureaucracy, not from goofy rendering.
Text (verbatim): "CIVIC NIGHTMARE" as one large, perfectly legible title across the upper quarter. Below it, much smaller but still clear: "THE BUREAUCRACY RPG".
Typography: bold original arcade-cabinet title lettering fused with official government-seal geometry; cream-white letters with restrained gold/red shadow; preserve exact spelling.
Constraints: render both text lines exactly once and verbatim; no other readable text anywhere; no real political faces; no recognizable government logos, flags, corporate logos, trademarks or watermarks; no extra main characters; no weapons; no futuristic spacecraft; no neon cyberpunk city; no photorealism; no border; maintain generous safe margins so a centered 5:4 crop does not cut title, citizen, car or district.
```
