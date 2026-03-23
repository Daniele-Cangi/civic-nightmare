const fs = require("fs");
const path = require("path");
const core = require("./generator_core");

const outputDir = path.resolve(__dirname, "..", "..", "assets", "generated");
const pressures = ["time", "access", "trust", "rent", "stress"];
const defaultProfile = "production";
const gestureFxFrameCount = 5;
const eventFxFrameCount = 5;
const gestureFxPresets = [
  { preset: "podium_acceptance_fx_overlay", outputId: "podium_acceptance_fx_overlay", seed: "podium-acceptance-fx" },
  { preset: "scanner_tap_fx_overlay", outputId: "scanner_tap_fx_overlay", seed: "scanner-tap-fx" },
  { preset: "packet_handoff_fx_overlay", outputId: "packet_handoff_fx_overlay", seed: "packet-handoff-fx" },
  { preset: "ledger_signing_fx_overlay", outputId: "ledger_signing_fx_overlay", seed: "ledger-signing-fx" }
];
const eventFxPresets = [
  { preset: "dossier_commit_event_fx_overlay", outputId: "dossier_commit_event_fx_overlay", seed: "dossier-commit-event-fx" },
  { preset: "records_stamp_event_fx_overlay", outputId: "records_stamp_event_fx_overlay", seed: "records-stamp-event-fx" },
  { preset: "night_shift_event_fx_overlay", outputId: "night_shift_event_fx_overlay", seed: "night-shift-event-fx" },
  { preset: "turnstile_release_event_fx_overlay", outputId: "turnstile_release_event_fx_overlay", seed: "turnstile-release-event-fx" }
];

const jobs = [
  { preset: "plaza_day1_backdrop", seed: "civic-nightmare-day-1", pressure: "trust" },
  { preset: "plaza_day2_backdrop", seed: "civic-nightmare-day-2", pressure: "stress" },
  { preset: "records_chamber_scene", seed: "records-window-late-body", pressure: "time" },
  { preset: "turnstile_gate_scene", seed: "domestic-route-lowered", pressure: "access" },
  { preset: "apartment_interlude_scene", seed: "night-paper-room", pressure: "rent" },
  { preset: "trump_podium_annex_scene", seed: "attention-podium-side-room", pressure: "trust" },
  { preset: "musk_priority_lane_scene", seed: "priority-lane-throughput-tunnel", pressure: "access" },
  { preset: "vdl_packet_hall_scene", seed: "distributed-packet-validation-hall", pressure: "time" },
  { preset: "lagarde_housing_office_scene", seed: "housing-discipline-intake-office", pressure: "rent" },
  { preset: "citizen_actor_sprite", seed: "ordinary-citizen-body", pressure: "trust" },
  { preset: "trump_actor_sprite", seed: "executive-theater-body", pressure: "stress" },
  { preset: "musk_actor_sprite", seed: "platform-throughput-body", pressure: "access" },
  { preset: "vdl_actor_sprite", seed: "packet-governance-body", pressure: "time" },
  { preset: "lagarde_actor_sprite", seed: "monetary-discipline-body", pressure: "rent" },
  { preset: "records_window_actor_sprite", seed: "records-counter-body", pressure: "time" },
  { preset: "home_turnstile_actor_sprite", seed: "home-turnstile-body", pressure: "access" },
  { preset: "records_notice_poster", seed: "records-notice-visible-stack", pressure: "time" },
  { preset: "turnstile_direction_sign", seed: "home-lane-guidance", pressure: "access" },
  { preset: "barricade_decal_strip", seed: "managed-crossing", pressure: "stress" },
  { preset: "dossier_sheet_cluster", seed: "filed-human-remainder", pressure: "trust" }
];
const sheetJobs = [];

for (const pressure of pressures) {
  jobs.push(
    {
      preset: "plaza_pixel_fx_overlay",
      outputId: `plaza_pixel_fx_overlay_${pressure}`,
      seed: `plaza-pixel-fx-${pressure}`,
      pressure
    },
    {
      preset: "annex_pixel_fx_overlay",
      outputId: `annex_pixel_fx_overlay_${pressure}`,
      seed: `annex-pixel-fx-${pressure}`,
      pressure
    },
    {
      preset: "transition_pixel_fx_overlay",
      outputId: `transition_pixel_fx_overlay_${pressure}`,
      seed: `transition-pixel-fx-${pressure}`,
      pressure
    },
    {
      preset: "checkpoint_stamp_mark",
      outputId: `checkpoint_stamp_mark_${pressure}`,
      seed: `checkpoint-validated-${pressure}`,
      pressure
    },
    {
      preset: "agency_seal_badge",
      outputId: `agency_seal_badge_${pressure}`,
      seed: `distributed-authority-${pressure}`,
      pressure
    },
    {
      preset: "queue_floor_arrows_day2",
      outputId: `queue_floor_arrows_day2_${pressure}`,
      seed: `domestic-lane-enforced-${pressure}`,
      pressure
    },
    {
      preset: "day2_document_overlay",
      outputId: `day2_document_overlay_${pressure}`,
      seed: `day-two-cumulative-review-${pressure}`,
      pressure
    }
  );

  for (const gestureFx of gestureFxPresets) {
    sheetJobs.push({
      preset: gestureFx.preset,
      outputId: `${gestureFx.outputId}_${pressure}`,
      seed: `${gestureFx.seed}-${pressure}`,
      pressure,
      columns: gestureFxFrameCount
    });
    jobs.push({
      preset: gestureFx.preset,
      outputId: `${gestureFx.outputId}_${pressure}`,
      seed: `${gestureFx.seed}-${pressure}`,
      pressure
    });

    for (let frame = 1; frame <= gestureFxFrameCount; frame += 1) {
      const frameTag = String(frame).padStart(2, "0");
      jobs.push({
        preset: gestureFx.preset,
        outputId: `${gestureFx.outputId}_${pressure}_f${frameTag}`,
        seed: `${gestureFx.seed}-${pressure}`,
        pressure,
        frame,
        frameCount: gestureFxFrameCount
      });
    }
  }

  for (const eventFx of eventFxPresets) {
    sheetJobs.push({
      preset: eventFx.preset,
      outputId: `${eventFx.outputId}_${pressure}`,
      seed: `${eventFx.seed}-${pressure}`,
      pressure,
      columns: eventFxFrameCount
    });
    jobs.push({
      preset: eventFx.preset,
      outputId: `${eventFx.outputId}_${pressure}`,
      seed: `${eventFx.seed}-${pressure}`,
      pressure
    });

    for (let frame = 1; frame <= eventFxFrameCount; frame += 1) {
      const frameTag = String(frame).padStart(2, "0");
      jobs.push({
        preset: eventFx.preset,
        outputId: `${eventFx.outputId}_${pressure}_f${frameTag}`,
        seed: `${eventFx.seed}-${pressure}`,
        pressure,
        frame,
        frameCount: eventFxFrameCount
      });
    }
  }
}

fs.mkdirSync(outputDir, { recursive: true });

const manifest = [];
for (const job of jobs) {
  const asset = core.generateAsset({ ...job, profile: job.profile || defaultProfile });
  const outputPath = path.join(outputDir, `${asset.id}.svg`);
  fs.writeFileSync(outputPath, asset.svg, "utf8");
  manifest.push({
    id: asset.id,
    label: asset.label,
    category: asset.category,
    width: asset.width,
    height: asset.height,
    palette: asset.palette,
    pressure: asset.pressure,
    profile: asset.profile,
    seed: asset.seed,
    frame: asset.frame,
    frameCount: asset.frameCount,
    kind: "asset",
    file: `assets/generated/${asset.id}.svg`
  });
}

for (const sheetJob of sheetJobs) {
  const sheet = core.buildSpriteSheet({ ...sheetJob, profile: sheetJob.profile || defaultProfile });
  const svgPath = path.join(outputDir, `${sheet.id}.svg`);
  const jsonPath = path.join(outputDir, `${sheet.id}.json`);
  fs.writeFileSync(svgPath, sheet.svg, "utf8");
  fs.writeFileSync(jsonPath, sheet.json, "utf8");
  manifest.push({
    id: sheet.id,
    label: sheet.label,
    category: sheet.category,
    width: sheet.width,
    height: sheet.height,
    palette: sheet.palette,
    pressure: sheet.pressure,
    profile: sheet.profile,
    seed: sheet.seed,
    frameCount: sheet.frameCount,
    columns: sheet.columns,
    rows: sheet.rows,
    kind: "spritesheet",
    file: `assets/generated/${sheet.id}.svg`,
    metadata: `assets/generated/${sheet.id}.json`
  });
}

fs.writeFileSync(
  path.join(outputDir, "manifest.json"),
  JSON.stringify({ generatedAt: new Date().toISOString(), assets: manifest }, null, 2),
  "utf8"
);

console.log(`Generated ${manifest.length} civic assets in ${outputDir}`);
