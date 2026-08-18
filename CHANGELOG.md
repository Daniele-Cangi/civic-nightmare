# Changelog

All notable project changes are documented here. Civic Nightmare uses continuous
web deployment and tagged releases for major public milestones.

## Unreleased

### Added

- A short skippable CRT news broadcast before the mandatory opening drive, with
  three authored civic reports, live ticker, signal transitions, and broadcast
  hum generated at runtime.
- **Coastline Dash**, the original 48 kHz stereo arcade-driving soundtrack for
  the mandatory approach, with a clean cadence aligned to the engine-death beat.
- New 5:4 itch.io key art presenting the battered car, passport citizen, and
  monumental administrative district as one readable arcade-poster composition.
- Five unretouched 1280×720 itch.io gameplay screenshots covering the mandatory
  drive, Xi's northern gate, Trump's disputed blackjack result, Ursula's
  847-page approval, and Lagarde's systemic-ball bailout.
- A playable approximately 90-second sunset highway opening with direct
  steering, perspective road motion, contradictory civic signs, potholes,
  increasing smoke, visible part loss, and an administrative arrival beat.
- Original runtime artwork for the administrative highway and battered citizen
  vehicle, plus a documented and verified runtime music path.
- Four escalating road set pieces: an official pothole inauguration, a
  privilege-only motorcade lane, a self-correcting mobile toll, and a decayed
  checkpoint whose failed barrier is interpreted as authorization.
- **The Greatest Deal**, a three-round Trump entry procedure built around
  readable blackjack hands, visible totals, HIT/STAND decisions, post-result
  special moves, and a sharply separated acceptance or challenge phase.
- Full opaque playing-card faces replace outlined card placeholders, including
  coherent overlapping hands and a separate physical card for Trump events.
- **The Consensus Engine**, a physical 27-approval Ursula entry procedure with
  moving dossiers, scanners, stamps, translations, expiring approvals, and two
  legitimate unanimity routes.
- Persistent access clearance and semantic dossier evidence for both authority
  procedures, plus deterministic smoke coverage for their rules and save flow.
- Compatibility inference for existing 2.0 dossiers: a signature already on
  file clears its newly introduced entrance procedure retroactively.
- **The 2% Miracle**, a Lagarde entry procedure built as a physical monetary
  pinball with a visible inflation target, rate and household bumpers,
  liquidity injection, rate shock, systemic bailout, and methodology fallback.
- Distinct dossier evidence for real stabilization versus statistical
  adjustment, plus deterministic rules, visual asset, save compatibility, and
  smoke coverage for Lagarde's access clearance.

### Changed

- Web exports now use Godot's single-threaded runtime, removing the
  `SharedArrayBuffer` and cross-origin-isolation requirement that blocked the
  itch.io build without special frame headers.
- Approaching Xi's northern gate now raises the actual gameplay camera smoothly,
  exposing the monumental wall composition shown in the approved screenshot.
- New Game now follows one explicit opening route: skippable broadcast,
  mandatory playable drive, then the existing overworld and autosave boundary.
- The administrative approach is mandatory gameplay: its skip input and prompt
  have been removed, while unrelated news/video presentation remains untouched.
- The opening drive now uses a stronger original late-1980s arcade background,
  animated perspective curves, alternating roadside blocks and curve-aware
  placement for the car, signs and potholes.
- Sparse roadside gags now build into physical civic procedures while retaining
  one steering grammar, no fail state and no interruption of the heroic drive.
- The former passive montage is no longer coupled to the driving code; the new
  broadcast and active arcade approach are separate sequence owners joined by
  one composition-level handoff.
- Refreshed the README's visual identity and gallery to use current runtime art,
  replacing the superseded nuclear-plant mockup with the inference reactor and
  adding representative 2.0 landmarks, interiors, anomalies, and combat art.

### Fixed

- Lagarde's restored systemic ball now follows a protected central service arc
  onto an inner flipper instead of immediately draining into repeated bailouts.
- The monetary table's two south-edge rails now have matching physical guides;
  fixed physics substeps prevent fast balls from tunnelling through them while
  preserving the intentional drain between the flippers.

## [2.0.0] - 2026-08-17

### Release title

**Civic Nightmare 2.0 — The Dossier Update**

### Added

- Semantic behavioural evidence for all six required signatures.
- Cross-quest patterns and contradictions based on observable response mode,
  pressure channel, authority form, and protected or conceded resource.
- Dossier-driven terminal routing, room notices, clerk posture, and C.L.A.U.D.I.A.
  session tone.
- Pull-request parse, smoke, and web-export gates in GitHub Actions.
- Asset inventory, source/runtime/generated boundaries, and release checklist.

### Changed

- Choice evidence stores the visible choice label and migrates older dossier
  events deterministically.
- Pages deployments retain one deployment commit instead of accumulating PCK
  and WASM history.
- Civic Asset Lab output is disposable and regenerates under `tmp/generated/`.
- The licensed vendor pack is retained under non-exported `asset_sources/`; only
  its six referenced props remain in the runtime tree.
- The superseded world plate and six old combat portraits are retained as
  non-exported legacy sources instead of shipping in the game.

### Removed

- 380 unused, reproducible generated SVG/JSON files from the tracked runtime tree.
