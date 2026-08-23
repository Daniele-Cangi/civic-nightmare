# Authority access games

Trump, Ursula, and Lagarde each own a playable door procedure. These games
happen before the existing interior travel transition; they do not replace or
alter the character dialogue that follows.

## Shared contract

- The door asks `main.gd` to travel to `oval_office`, `eu_palace`, or `vault`.
- If its clearance bit is absent, `main.gd` archives the safe exterior
  checkpoint, freezes the world player, and starts the encounter module.
- The module owns its full-screen stage, local input and deterministic rules.
- Escape cancels safely to the exterior. A completed procedure emits a semantic
  result, not a generic score.
- `main.gd` records that result with `DossierManager`, saves the clearance bit,
  and resumes the ordinary room transition. Continue never restores halfway
  through a procedure.

## The Greatest Deal

The procedure is blackjack before it becomes satire. The HUD permanently shows
`TARGET: 21`, deal, certified score, Trump total, Citizen total, and remaining challenges. Both
hands are rendered as complete physical playing cards. Left/Right selects
`HIT` or `STAND`; Space confirms.

Five distinct deterministic hands create a fixed certified-majority match. Four
are winnable with readable play; one gives Trump a legitimate 21. The real
result is always displayed first, including exact scores or a bust. Trump then
introduces a separate gold certification event and claims every hand, even the
one he actually won. Special moves are never presented as cards in the Citizen
hand.

After the intervention, the player chooses Accept or Challenge. Accept certifies
Trump's point and advances; a correct Challenge certifies the Citizen point,
while an incorrect Challenge spends the objection and certifies Trump. Four
visible objections allow one error across five always-advancing deals. Three
Citizen points produce a majority, but either certified outcome opens the door
with different final language and dossier evidence. The dossier separately
retains blackjack play, certified points, false claims accepted, valid claims
accepted, and challenge accuracy. These are observations about play and
negotiation, not morality points.

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

## The 2% Miracle

Left and Right operate two physical flippers under a decaying baroque monetary
machine. A euro ball collides with visible policy and household bumpers while a
permanent header shows the live inflation indicator and its `2.00%` target.
Rate bumpers lower the publication; energy, rent, wages, and bank rescue move it
up. The player must keep the published value inside the narrow stability band
for two seconds rather than merely touch it.

Five interventions trigger a liquidity injection as multiball. Ten trigger a
rate shock that accelerates the table. A completely drained table restores one
systemic ball through a bailout and moves inflation upward. If the indicator
has not converged when the procedure expires, the methodology is revised and
publishes `2.0%`; this prevents the main quest from being blocked while making
the administrative outcome distinct from genuine stabilization.

The final presentation first certifies price stability, then explicitly leaves
purchasing power and household effects outside the measurement perimeter. The
dossier retains the route, policy and household hits, liquidity injection,
rate shock, bailouts, acceptable losses, and elapsed time.

The table owns **Jackpot Jive** as its dedicated music bed. Its flippers,
bumpers, liquidity injection, rate shock, systemic bailout, and certification
remain mixed above the track, which stops before Lagarde's existing dialogue.

## Verification

`tests/smoke_test.gd` proves blackjack totals, HIT/STAND progression, physical
card bodies, the strict real-result-before-interference sequence, a normal bust,
the lawful derogation path, deterministic pinball escalation and both monetary
routes, semantic results, module mounting, and save/restore of all three
clearance bits. CI runs parse, smoke, and Web export before deployment.
