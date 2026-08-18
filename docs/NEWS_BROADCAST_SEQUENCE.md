# News broadcast sequence

`scripts/sequences/news_broadcast_sequence.gd` owns the short television
prologue between **New Game** and the mandatory opening drive. It is a separate
presentation boundary rather than a mode inside `IntroSequence`.

## Experience contract

- Fixed authored frame: 1280×720, scaled to the active viewport.
- Duration: 21.5 seconds, including CRT boot and shutdown.
- Input: Space/accept skips only this broadcast after the signal appears.
- Three six-second reports establish the world's satire without explaining the
  quest: conflict as quarterly performance, human-centered job replacement, and
  a public-service warning about the passport district.
- The final report names the player's destination and roadworthy-vehicle
  requirement, creating a direct visual joke when the battered car appears.
- Visuals, signal noise, ticker movement, type-on headlines, scanlines, and the
  low broadcast hum are code-owned; no external news footage or audio ships.

## Runtime handoff

The sequence exposes the same narrow presentation shape as the other opening
modules: `setup(owner, player)`, `process_frame(delta)`, and `finished`.
`main.gd` freezes world systems while either opening sequence is active. When
the bulletin finishes naturally or is skipped, `main.gd` removes it and mounts
`IntroSequence`; input is not forwarded, so the action used to skip the news
cannot also skip or complete the drive.

Continue bypasses both opening sequences and restores the latest safe exterior
checkpoint. Neither the broadcast timeline nor the middle of the drive is a
persisted resume location.
