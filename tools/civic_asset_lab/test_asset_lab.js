const assert = require("assert");
const core = require("./generator_core");

const presets = core.listPresets();
const profiles = core.listProfiles();
assert(presets.length >= 35, `Expected expanded preset list, got ${presets.length}`);
assert(profiles.length >= 4, `Expected style profiles, got ${profiles.length}`);

for (const preset of presets) {
  const asset = core.generateAsset({
    preset: preset.id,
    pressure: preset.pressure,
    seed: `smoke:${preset.id}`
  });

  assert.strictEqual(asset.width, preset.width, `${preset.id} width mismatch`);
  assert.strictEqual(asset.height, preset.height, `${preset.id} height mismatch`);
  assert.ok(asset.svg.startsWith("<?xml"), `${preset.id} missing xml header`);
  assert.ok(asset.svg.includes("<svg "), `${preset.id} missing svg root`);
  assert.ok(asset.svg.includes(`viewBox="0 0 ${preset.width} ${preset.height}"`), `${preset.id} missing expected viewBox`);
  assert.ok(asset.svg.includes("shape-rendering=\"crispEdges\""), `${preset.id} missing crisp edge rendering`);
  assert.ok(asset.category, `${preset.id} missing category`);
  assert.ok(asset.profile, `${preset.id} missing profile`);
}

const pressureProbe = core.generateAsset({
  preset: "checkpoint_stamp_mark",
  pressure: "stress",
  seed: "smoke:pressure-probe",
  outputId: "checkpoint_stamp_mark_stress_probe"
});

assert.strictEqual(pressureProbe.id, "checkpoint_stamp_mark_stress_probe", "outputId override failed");
assert.ok(pressureProbe.svg.includes("<circle"), "pressure probe did not generate expected geometry");

const gestureProbe = core.generateAsset({
  preset: "ledger_signing_fx_overlay",
  pressure: "rent",
  seed: "smoke:gesture-probe",
  frame: 5,
  frameCount: 5
});

assert.ok(gestureProbe.svg.includes("<line"), "gesture probe did not generate expected line geometry");
assert.strictEqual(gestureProbe.frameCount, 5, "gesture probe did not preserve frame count");

const animationFrameA = core.generateAsset({
  preset: "scanner_tap_fx_overlay",
  pressure: "access",
  seed: "smoke:animated-fx",
  frame: 1,
  frameCount: 5
});
const animationFrameB = core.generateAsset({
  preset: "scanner_tap_fx_overlay",
  pressure: "access",
  seed: "smoke:animated-fx",
  frame: 5,
  frameCount: 5
});

assert.notStrictEqual(animationFrameA.svg, animationFrameB.svg, "animated FX frames should not collapse into the same SVG");

const eventFrameA = core.generateAsset({
  preset: "records_stamp_event_fx_overlay",
  pressure: "time",
  seed: "smoke:event-fx",
  frame: 1,
  frameCount: 5
});
const eventFrameB = core.generateAsset({
  preset: "records_stamp_event_fx_overlay",
  pressure: "time",
  seed: "smoke:event-fx",
  frame: 5,
  frameCount: 5
});

assert.notStrictEqual(eventFrameA.svg, eventFrameB.svg, "event FX frames should not collapse into the same SVG");

const profileA = core.generateAsset({
  preset: "citizen_actor_sprite",
  pressure: "trust",
  seed: "smoke:profile",
  profile: "editorial"
});
const profileB = core.generateAsset({
  preset: "citizen_actor_sprite",
  pressure: "trust",
  seed: "smoke:profile",
  profile: "brutalist"
});

assert.notStrictEqual(profileA.svg, profileB.svg, "style profiles should affect output");

const spriteSheet = core.buildSpriteSheet({
  preset: "scanner_tap_fx_overlay",
  pressure: "access",
  seed: "smoke:sheet",
  profile: "production",
  frameCount: 5,
  columns: 5
});

assert.ok(spriteSheet.svg.includes("<g transform=\"translate("), "spritesheet should place frames in translated groups");
assert.ok(spriteSheet.json.includes("\"frameCount\": 5"), "spritesheet metadata should preserve frame count");
assert.strictEqual(spriteSheet.columns, 5, "spritesheet columns mismatch");

console.log(`Asset lab smoke test passed for ${presets.length} presets.`);
