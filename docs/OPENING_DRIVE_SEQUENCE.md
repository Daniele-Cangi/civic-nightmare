# Opening drive sequence

`scripts/sequences/intro_sequence.gd` owns the playable approach that follows
the skippable `NewsBroadcastSequence` and precedes the existing overworld. It
does not own or inherit the broadcast's skip input. The sequence keeps
`main.gd`'s composition contract small:
`setup(owner, player)` freezes the world player, `process_frame(delta)` advances
the local state machine, and `finished` returns control and triggers the existing
autosave boundary.

## Experience contract

- Fixed authored frame: 1280×720, scaled to the active viewport.
- Duration: 89.8 seconds; the musical window ends at 88 seconds so the engine
  can die after a clean cadence.
- Input: left/right steering. The drive is mandatory gameplay and has no skip;
  only the preceding news broadcast exposes one.
- No failure state. Potholes produce shake, clunks and debris, but the journey
  always reaches the district.
- The visual joke is a sincere heroic arcade approach carrying a visibly
  unroadworthy economy car. The music must never perform the joke itself.
- The road is rebuilt in perspective every frame: long curves, alternating
  shoulder blocks, lane markers, signs and potholes share one centre function,
  so the scene turns as a system rather than sliding unrelated decorations.
- Road signs and deterioration arrive gradually; the first seconds remain
  readable enough to teach steering before four authored civic set pieces turn
  the road itself into the bureaucracy.
- The set pieces never remove steering or create a failure state. Avoiding the
  inauguration, following the corrected toll lane and surviving the checkpoint
  remain physical jokes inside the same driving grammar.

The authored timeline is approximately:

| Window | Presentation |
| --- | --- |
| 0–6 s | Repeated ignition attempts; the adventure promises more than the engine. |
| 6–19 s | Open highway, simple steering, first contradictory distance sign. |
| 19–31 s | A lavish ceremony inaugurates an unrepaired pothole. |
| 31–47 s | The car loses parts; an official motorcade creates its own gold lane and removes it after passing. |
| 47–68 s | A mobile administrative toll changes the valid lane and issues a receipt long enough to trail behind the car. |
| 68–78 s | Maximum motion and deterioration while the district remains majestic. |
| 78–88 s | A scanner rejects the vehicle; its rusted barrier collapses and the failure is recorded as access granted. |
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

Built-in OpenAI image generation produced the car and the four isolated civic
set pieces in original mode, and the v2 background as a style edit of the
project's own v1 composition:

- `assets/sequences/opening_drive_sunset_v2.png`: an original late-1980s
  arcade-highway genre treatment derived from the project's v1 composition,
  with a striped low sun, saturated coral/magenta/cyan separation and a
  monumental administrative district. It remains free of cars, UI, logos,
  readable text and lane markings so procedural road geometry stays authoritative.
- `assets/sequences/opening_drive_car_v1.png`: an original rear-view battered
  early-1980s economy hatchback, dented, rusty and rope-repaired, isolated on
  transparency without smoke, road, logos or text so runtime damage remains
  animatable.
- `assets/sequences/opening_drive_pothole_ceremony_v1.png`: a transparent
  red-carpet inauguration surrounding the road defect it claims to complete.
- `assets/sequences/opening_drive_motorcade_v1.png`: a transparent, overlong
  armoured official motorcade with blank ceremonial pennants and escorts.
- `assets/sequences/opening_drive_tollbooth_v1.png`: a transparent three-lane
  mobile procedure with contradictory barriers, scanners and an industrial
  receipt printer.
- `assets/sequences/opening_drive_checkpoint_v1.png`: a transparent corroded
  scanner arch whose central opening deliberately excludes the separately
  animated rust-failed barrier.

The resulting composition was verified in the actual Godot window at gameplay
resolution after the parse and smoke checks. Code owns the curved road surface,
alternating shoulders, perspective markers, edge streaks, road signs, potholes,
gold institutional lane, toll decisions, receipt trail, scanning beam, barrier
collapse, smoke, part loss, HUD and scanline treatment.
