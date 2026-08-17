# Authority access games

Trump and Ursula each own a playable door procedure. These games happen before
the existing interior travel transition; they do not replace or alter either
character's dialogue.

## Shared contract

- The door asks `main.gd` to travel to `oval_office` or `eu_palace`.
- If its clearance bit is absent, `main.gd` archives the safe exterior
  checkpoint, freezes the world player, and starts the encounter module.
- The module owns its full-screen stage, local input and deterministic rules.
- Escape cancels safely to the exterior. A completed procedure emits a semantic
  result, not a generic score.
- `main.gd` records that result with `DossierManager`, saves the clearance bit,
  and resumes the ordinary room transition. Continue never restores halfway
  through a procedure.

## The Greatest Deal

Three face-up citizen cards are controlled with Left/Right and played with
Space. Every phase states its current rule; Trump then declares victory whether
or not the arithmetic supports it. The player chooses Accept or Challenge.

Accepting loses the current deal but creates leverage. `X` spends leverage to
freeze one later rule change. A correct challenge wins the deal; a false
challenge removes chips. The three deterministic hands teach cancellation,
gold-card multiplication, and a final recount that can be blocked or frozen.

The dossier retains accepted claims, successful and failed challenges,
leverage use, attempts, and remaining chips. These are observations about the
negotiation method, not morality points.

## The Consensus Engine

Arrow keys physically move the case dossier between a scanner, blue-ink stamp,
translation desk, submission port, and a moving 65% stamp. Space processes the
nearby station. The 27 perimeter lamps show procedural state rather than player
statistics.

Simple majority is first achieved and declared insufficient. Qualified
majority adds the moving population requirement. Unanimity leaves one red lamp
and an Annex B/C loop. The player may complete that loop or discover the lawful
emergency derogation; the latter is the only hold interaction and has an
explicit progress bar.

The dossier retains the route, expiry resets, misroutes, station actions and
attempts. A complete run ends with the deliberately impractical first page of
an 847-page approval before the normal Ursula room opens.

## Verification

`tests/smoke_test.gd` proves the deterministic winning rules, the strategic
Accept path, the lawful derogation path, semantic results, module mounting, and
save/restore of both clearance bits. CI runs parse, smoke, and Web export before
deployment.
