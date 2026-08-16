# Optional landmark art direction

Optional landmarks use the same elevated frontal/orthographic camera and modern illustrated finish as the authority facades, but each silhouette must communicate its own joke before the player enters it. They are authored as transparent runtime-sized cutouts with one visually unambiguous entrance and collision shapes derived from the final image.

## Sam Altman — inference reactor

The public entrance is a tiny, immaculate keynote pavilion. It is overwhelmed by the physical cost of the promise: old generators, improvised cooling, domestic air conditioners, tarped servers, hoses, cables and a single inadequate solar panel. The glowing inference core is staged like an oracle.

Runtime contract:

- asset: `res://assets/landmarks/inference_reactor_demo_v1.png`
- canvas: 480 × 320 RGBA
- origin: bottom-centre at the existing nuclear-plant world anchor
- entrance: one central trigger leading to `neural_core`
- collision: upper infrastructure plus independent west and east service wings
- filtering: linear

Final generation prompt:

> Create an isolated overworld landmark for the satirical 2D game Civic Nightmare. Use the district plate only for the elevated frontal/orthographic camera, contemporary urban material scale and subdued daylight. Use the Trump facade only for the level of architectural caricature, dense authored detail, exaggerated readable silhouette and visual humour; do not copy its palace, gold, eagle, flags or architecture. Create a funny, immediately readable AI inference power plant associated with Sam Altman. At the exact bottom centre, place a comically small immaculate minimalist keynote pavilion with pure white curved walls, one dark glass entrance, a ceremonial red launch button under glass, velvet ropes and one immaculate potted plant. Directly above and behind it, place an absurdly oversized cyan inference-oracle treated like a sacred object. Reveal what powers the miracle around it: an asymmetrical mountain of old turbines, dented rental generators, domestic window air-conditioners stacked six high, tarped server racks, extension leads through open panels, emergency water tanks, garden hoses used as cooling lines and one hilariously inadequate solar panel. The left side suggests frantic energy supply and the right side frantic cooling. The joke must survive reduction to 512 pixels: a pristine religious product demo crushed by the ugly physical cost of the promise. Use a wide compact 3:2 silhouette, elevated frontal/orthographic game view, one bottom-centre entrance, solid lower left and right collision masses and a clear central approach. Render as a high-detail modern 2D game illustration in a slightly decayed present, not science fiction or sleek corporate concept art. Neutral overcast light, cold cyan oracle glow and sickly practical fluorescents. Isolate the object on pure `#FF00FF` for alpha extraction; do not include a checkerboard, ground plane, plaza, road, scenery, frame, UI, words, logos, flags, characters, smoke cloud, conventional cooling towers or a spaceship silhouette.
