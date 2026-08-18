# Opening drive sequence

`scripts/sequences/intro_sequence.gd` owns the playable approach that follows
New Game and precedes the existing overworld. The sequence replaces the former
passive news montage without changing `main.gd`'s composition contract:
`setup(owner, player)` freezes the world player, `process_frame(delta)` advances
the local state machine, and `finished` returns control and triggers the existing
autosave boundary.

## Experience contract

- Fixed authored frame: 1280×720, scaled to the active viewport.
- Duration: 89.8 seconds; the musical window ends at 88 seconds so the engine
  can die after a clean cadence.
- Input: left/right steering and Space/Enter to skip.
- No failure state. Potholes produce shake, clunks and debris, but the journey
  always reaches the district.
- The visual joke is a sincere heroic arcade approach carrying a visibly
  unroadworthy economy car. The music must never perform the joke itself.
- Road signs, deterioration and bureaucratic contamination arrive gradually;
  the first seconds remain readable enough to teach steering.

The authored timeline is approximately:

| Window | Presentation |
| --- | --- |
| 0–6 s | Repeated ignition attempts; the adventure promises more than the engine. |
| 6–32 s | Open highway, simple steering, first contradictory distance signs. |
| 32–58 s | Busier road, civic instructions, potholes and the first lost parts. |
| 58–78 s | Maximum motion and deterioration while the district remains majestic. |
| 78–88 s | Arrival slowdown and final approach. |
| 88–89.8 s | Music resolves, engine fails, arrival is registered, world begins. |

## Music delivery contract

The separately commissioned master should be placed at:

`assets/audio/civic_nightmare_opening_drive.ogg`

The sequence checks that path at runtime. If it is absent, the drive still runs
with its local procedural engine and impact sounds; no placeholder music is
shipped and no load error is emitted.

Recommended delivery:

- original instrumental only, with documented contributor and usage rights;
- 4/4 at approximately 150–158 BPM (154 BPM is the timing reference);
- 80–90 seconds, ideally 88 seconds including the short ignition introduction;
- 48 kHz stereo Ogg Vorbis for the browser build;
- confident clean cadence at 88 seconds, not a long fade;
- safe browser master around -1 dBTP, leaving engine and impact transients room;
- no embedded engine, crash, dialogue or UI effects: music and gameplay sound
  remain independently mixable.

If the final master is materially shorter or longer, update `MUSIC_DURATION`,
`ARRIVAL_START`, `SEQUENCE_DURATION`, the authored schedules, this document and
the smoke assertions together. Do not time-stretch the track at runtime.

## Visual assets and generation record

Built-in OpenAI image generation produced both runtime images in original mode:

- `assets/sequences/opening_drive_sunset_v1.png`: an original late-1980s
  arcade-inspired sunset highway, kept free of cars, UI, logos and readable text,
  with a monumental administrative district on the horizon and enough clean road
  for procedural motion and gameplay overlays.
- `assets/sequences/opening_drive_car_v1.png`: an original rear-view battered
  early-1980s economy hatchback, dented, rusty and rope-repaired, isolated on
  transparency without smoke, road, logos or text so runtime damage remains
  animatable.

The resulting composition was verified in the actual Godot window at gameplay
resolution after the parse and smoke checks. Code owns the perspective markers,
edge streaks, road signs, potholes, smoke, part loss, HUD and scanline treatment.
