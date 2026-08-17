# Changelog

All notable project changes are documented here. Civic Nightmare uses continuous
web deployment and tagged releases for major public milestones.

## Unreleased

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
