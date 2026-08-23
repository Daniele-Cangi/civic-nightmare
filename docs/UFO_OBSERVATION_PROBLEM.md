# UFO Observation Problem

## Purpose

The UFO is an anomaly, not a collectible. Its access game makes the evidence
system fail physically before the existing Einstein/Zuckerberg scene explains
anything: one registered citizen must be observed in several places at the same
time.

## Player grammar

- Arrow keys move the citizen between observation nodes.
- `Space` records the current route as a temporal echo.
- Phase I asks for one echo plus the present citizen across two nodes.
- Phase II asks for two echoes plus the present citizen across three nodes.
- A scanner can invalidate only the newest echo. It never erases the whole run,
  and occupied nodes are safe, so the challenge remains short and forgiving.
- One final `Space` certifies that the contradictory observations belong to a
  single identity.
- Once the citizen enters the beam, the observation is mandatory; `Esc` cannot
  convert it back into an optional cutscene.

The interface exposes actions and consequences, not a tutorial paragraph. Its
clocks disagree throughout, while the final ruling accepts the evidence and
postpones reconciliation.

## Ownership and persistence

`scripts/encounters/ufo_observation_problem.gd` owns the overlay, movement,
echo playback, scanner, audiovisual feedback, and semantic result. `main.gd`
only freezes/resumes the world, transfers to the existing UFO lab, and forwards
the completed result to `DossierManager`.

Only completion is persisted. Continue never resumes inside the minigame; it
returns to the safe checkpoint. The existing
`anomaly:ufo_time_discontinuity` event is the raw source of truth and lets older
saves infer that the access procedure has already occurred.

## Verification

`tests/smoke_test.gd` deterministically covers both phases, targeted scanner
invalidation, the 3-to-1 semantic result, dossier presentation, the
C.L.A.U.D.I.A. callback, and save compatibility.
