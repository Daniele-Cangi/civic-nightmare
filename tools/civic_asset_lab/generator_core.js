(function (root, factory) {
  if (typeof module === "object" && module.exports) {
    module.exports = factory();
  } else {
    root.CivicAssetLab = factory();
  }
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  const palettes = {
    cold: {
      background: "#0e1722",
      skyTop: "#182436",
      skyBottom: "#3c5572",
      tileA: "#212a34",
      tileB: "#2d3946",
      avenue: "#4c627a",
      avenueDim: "#3a4a61",
      buildingDark: "#13202e",
      buildingMid: "#22364a",
      buildingLight: "#4f6c88",
      paper: "#f1e8d6",
      wire: "#9fc0da",
      barrier: "#6788a6",
      accentTime: "#79afd2",
      accentAccess: "#8f9fe0",
      accentTrust: "#9ba4b5",
      accentRent: "#c98f68",
      accentStress: "#c46362"
    },
    amber: {
      background: "#17120f",
      skyTop: "#281c18",
      skyBottom: "#7b5844",
      tileA: "#31261f",
      tileB: "#3d3128",
      avenue: "#755c4f",
      avenueDim: "#604d42",
      buildingDark: "#231d1e",
      buildingMid: "#3d302d",
      buildingLight: "#5f493f",
      paper: "#efe1ce",
      wire: "#ddc19e",
      barrier: "#af5d4b",
      accentTime: "#d0a77d",
      accentAccess: "#c9a4a1",
      accentTrust: "#b2a79e",
      accentRent: "#dc9162",
      accentStress: "#cf6d63"
    },
    night: {
      background: "#090910",
      skyTop: "#12131d",
      skyBottom: "#3d4052",
      tileA: "#1f212a",
      tileB: "#262933",
      avenue: "#4f5566",
      avenueDim: "#424756",
      buildingDark: "#10121a",
      buildingMid: "#292d39",
      buildingLight: "#5e6679",
      paper: "#f0e6d8",
      wire: "#b4b9c6",
      barrier: "#8f5a57",
      accentTime: "#7f93ae",
      accentAccess: "#8790b7",
      accentTrust: "#9a9aa5",
      accentRent: "#bc8d6c",
      accentStress: "#b16b67"
    }
  };

  const styleProfiles = {
    production: {
      label: "Production",
      scanlineAlpha: 1.0,
      scanlineStride: 4,
      frameAlpha: 1.0,
      shadowAlpha: 1.0,
      stripeAlpha: 1.0,
      outlineWidth: 2,
      outlineAlpha: 0.34,
      silhouetteScale: 1.0,
      highlightAlpha: 1.0
    },
    editorial: {
      label: "Editorial Clean",
      scanlineAlpha: 0.42,
      scanlineStride: 5,
      frameAlpha: 0.76,
      shadowAlpha: 0.82,
      stripeAlpha: 0.62,
      outlineWidth: 1,
      outlineAlpha: 0.22,
      silhouetteScale: 0.96,
      highlightAlpha: 1.08
    },
    brutalist: {
      label: "Brutalist Signal",
      scanlineAlpha: 1.28,
      scanlineStride: 3,
      frameAlpha: 1.18,
      shadowAlpha: 1.18,
      stripeAlpha: 1.24,
      outlineWidth: 3,
      outlineAlpha: 0.46,
      silhouetteScale: 1.08,
      highlightAlpha: 0.92
    },
    nocturne: {
      label: "Nocturne",
      scanlineAlpha: 0.88,
      scanlineStride: 4,
      frameAlpha: 0.92,
      shadowAlpha: 1.26,
      stripeAlpha: 0.74,
      outlineWidth: 2,
      outlineAlpha: 0.4,
      silhouetteScale: 1.02,
      highlightAlpha: 0.82
    }
  };

  const presetOrder = [
    "plaza_day1_backdrop",
    "plaza_day2_backdrop",
    "records_chamber_scene",
    "turnstile_gate_scene",
    "apartment_interlude_scene",
    "trump_podium_annex_scene",
    "musk_priority_lane_scene",
    "vdl_packet_hall_scene",
    "lagarde_housing_office_scene",
    "citizen_actor_sprite",
    "trump_actor_sprite",
    "musk_actor_sprite",
    "vdl_actor_sprite",
    "lagarde_actor_sprite",
    "records_window_actor_sprite",
    "home_turnstile_actor_sprite",
    "plaza_pixel_fx_overlay",
    "annex_pixel_fx_overlay",
    "transition_pixel_fx_overlay",
    "podium_acceptance_fx_overlay",
    "scanner_tap_fx_overlay",
    "packet_handoff_fx_overlay",
    "ledger_signing_fx_overlay",
    "dossier_commit_event_fx_overlay",
    "records_stamp_event_fx_overlay",
    "night_shift_event_fx_overlay",
    "turnstile_release_event_fx_overlay",
    "records_notice_poster",
    "turnstile_direction_sign",
    "barricade_decal_strip",
    "dossier_sheet_cluster",
    "checkpoint_stamp_mark",
    "agency_seal_badge",
    "queue_floor_arrows_day2",
    "day2_document_overlay"
  ];

  const presets = {
    plaza_day1_backdrop: { width: 1280, height: 720, palette: "cold", pressure: "trust", variant: "plaza_day1", label: "Plaza Day 1" },
    plaza_day2_backdrop: { width: 1280, height: 720, palette: "amber", pressure: "stress", variant: "plaza_day2", label: "Plaza Day 2" },
    records_chamber_scene: { width: 384, height: 224, palette: "cold", pressure: "time", variant: "records_chamber", label: "Records Chamber" },
    turnstile_gate_scene: { width: 384, height: 224, palette: "amber", pressure: "access", variant: "turnstile_gate", label: "Turnstile Gate" },
    apartment_interlude_scene: { width: 1280, height: 720, palette: "night", pressure: "rent", variant: "apartment_interlude", label: "Apartment Interlude" },
    trump_podium_annex_scene: { width: 920, height: 552, palette: "cold", pressure: "trust", variant: "trump_podium_annex", label: "Podium Annex" },
    musk_priority_lane_scene: { width: 920, height: 552, palette: "amber", pressure: "access", variant: "musk_priority_lane", label: "Priority Lane Tunnel" },
    vdl_packet_hall_scene: { width: 920, height: 552, palette: "cold", pressure: "time", variant: "vdl_packet_hall", label: "Packet Hall" },
    lagarde_housing_office_scene: { width: 920, height: 552, palette: "amber", pressure: "rent", variant: "lagarde_housing_office", label: "Housing Office" },
    citizen_actor_sprite: { width: 128, height: 176, palette: "cold", pressure: "trust", variant: "citizen_actor", label: "Citizen Actor Sprite" },
    trump_actor_sprite: { width: 128, height: 176, palette: "amber", pressure: "stress", variant: "trump_actor", label: "Trump Actor Sprite" },
    musk_actor_sprite: { width: 128, height: 176, palette: "cold", pressure: "access", variant: "musk_actor", label: "Musk Actor Sprite" },
    vdl_actor_sprite: { width: 128, height: 176, palette: "cold", pressure: "time", variant: "vdl_actor", label: "von der Leyen Actor Sprite" },
    lagarde_actor_sprite: { width: 128, height: 176, palette: "amber", pressure: "rent", variant: "lagarde_actor", label: "Lagarde Actor Sprite" },
    records_window_actor_sprite: { width: 160, height: 160, palette: "cold", pressure: "time", variant: "records_window_actor", label: "Records Window Actor Sprite" },
    home_turnstile_actor_sprite: { width: 160, height: 160, palette: "amber", pressure: "access", variant: "home_turnstile_actor", label: "Home Turnstile Actor Sprite" },
    plaza_pixel_fx_overlay: { width: 1280, height: 720, palette: "cold", pressure: "trust", variant: "plaza_pixel_fx", label: "Plaza Pixel FX Overlay" },
    annex_pixel_fx_overlay: { width: 920, height: 552, palette: "cold", pressure: "trust", variant: "annex_pixel_fx", label: "Annex Pixel FX Overlay" },
    transition_pixel_fx_overlay: { width: 984, height: 540, palette: "amber", pressure: "stress", variant: "transition_pixel_fx", label: "Transition Pixel FX Overlay" },
    podium_acceptance_fx_overlay: { width: 920, height: 552, palette: "cold", pressure: "trust", variant: "podium_acceptance_fx", label: "Podium Acceptance FX Overlay", frameCount: 5, defaultFrame: 3 },
    scanner_tap_fx_overlay: { width: 920, height: 552, palette: "amber", pressure: "access", variant: "scanner_tap_fx", label: "Scanner Tap FX Overlay", frameCount: 5, defaultFrame: 3 },
    packet_handoff_fx_overlay: { width: 920, height: 552, palette: "cold", pressure: "time", variant: "packet_handoff_fx", label: "Packet Handoff FX Overlay", frameCount: 5, defaultFrame: 3 },
    ledger_signing_fx_overlay: { width: 920, height: 552, palette: "amber", pressure: "rent", variant: "ledger_signing_fx", label: "Ledger Signing FX Overlay", frameCount: 5, defaultFrame: 3 },
    dossier_commit_event_fx_overlay: { width: 1280, height: 720, palette: "cold", pressure: "trust", variant: "dossier_commit_event_fx", label: "Dossier Commit Event FX Overlay", frameCount: 5, defaultFrame: 3 },
    records_stamp_event_fx_overlay: { width: 1280, height: 720, palette: "amber", pressure: "time", variant: "records_stamp_event_fx", label: "Records Stamp Event FX Overlay", frameCount: 5, defaultFrame: 3 },
    night_shift_event_fx_overlay: { width: 1280, height: 720, palette: "night", pressure: "rent", variant: "night_shift_event_fx", label: "Night Shift Event FX Overlay", frameCount: 5, defaultFrame: 3 },
    turnstile_release_event_fx_overlay: { width: 1280, height: 720, palette: "amber", pressure: "access", variant: "turnstile_release_event_fx", label: "Turnstile Release Event FX Overlay", frameCount: 5, defaultFrame: 3 },
    records_notice_poster: { width: 160, height: 224, palette: "cold", pressure: "time", variant: "records_poster", label: "Records Notice Poster" },
    turnstile_direction_sign: { width: 256, height: 96, palette: "amber", pressure: "access", variant: "turnstile_sign", label: "Turnstile Direction Sign" },
    barricade_decal_strip: { width: 256, height: 64, palette: "cold", pressure: "stress", variant: "barricade_decal", label: "Barricade Decal Strip" },
    dossier_sheet_cluster: { width: 192, height: 144, palette: "night", pressure: "trust", variant: "dossier_cluster", label: "Dossier Sheet Cluster" },
    checkpoint_stamp_mark: { width: 112, height: 112, palette: "amber", pressure: "stress", variant: "checkpoint_stamp", label: "Checkpoint Stamp Mark" },
    agency_seal_badge: { width: 128, height: 128, palette: "cold", pressure: "trust", variant: "agency_seal", label: "Agency Seal Badge" },
    queue_floor_arrows_day2: { width: 384, height: 128, palette: "amber", pressure: "access", variant: "queue_floor_arrows", label: "Queue Floor Arrows Day 2" },
    day2_document_overlay: { width: 320, height: 448, palette: "night", pressure: "stress", variant: "document_overlay", label: "Day 2 Document Overlay" }
  };

  function resolveStyleProfile(profileId) {
    return styleProfiles[profileId] || styleProfiles.production;
  }

  function categorizePreset(presetId, preset) {
    const variant = String((preset && preset.variant) || "");
    if (variant.includes("_actor") || presetId.includes("_actor_")) {
      return presetId.includes("window") || presetId.includes("turnstile") ? "checkpoint" : "actor";
    }
    if (variant.endsWith("_fx") || variant.includes("_fx_") || presetId.includes("_fx_")) {
      return "fx";
    }
    if (variant.includes("poster") || variant.includes("sign") || variant.includes("decal") || variant.includes("cluster") || variant.includes("seal") || variant.includes("stamp") || variant.includes("overlay")) {
      return "document";
    }
    return "scene";
  }

  function hashString(input) {
    let hash = 2166136261;
    const source = String(input || "");
    for (let index = 0; index < source.length; index += 1) {
      hash ^= source.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
  }

  function createRng(seedInput) {
    let state = hashString(seedInput || "civic-nightmare") || 1;
    return function next() {
      state ^= state << 13;
      state ^= state >>> 17;
      state ^= state << 5;
      return ((state >>> 0) % 100000) / 100000;
    };
  }

  function mixColor(hexA, hexB, t) {
    const a = parseHexColor(hexA);
    const b = parseHexColor(hexB);
    return toHexColor({
      r: Math.round(a.r + (b.r - a.r) * t),
      g: Math.round(a.g + (b.g - a.g) * t),
      b: Math.round(a.b + (b.b - a.b) * t)
    });
  }

  function parseHexColor(hex) {
    const value = hex.replace("#", "");
    return {
      r: parseInt(value.slice(0, 2), 16),
      g: parseInt(value.slice(2, 4), 16),
      b: parseInt(value.slice(4, 6), 16)
    };
  }

  function toHexColor(color) {
    return `#${color.r.toString(16).padStart(2, "0")}${color.g.toString(16).padStart(2, "0")}${color.b.toString(16).padStart(2, "0")}`;
  }

  function clamp01(value) {
    return Math.max(0, Math.min(1, value));
  }

  function lerpNumber(start, end, t) {
    return start + (end - start) * clamp01(t);
  }

  function resolveFrameProgress(config) {
    const frameCount = Math.max(1, Number(config.frameCount || 1));
    const frame = Math.max(1, Math.min(frameCount, Number(config.frame || 1)));
    const progress = frameCount <= 1 ? 1 : (frame - 1) / (frameCount - 1);
    return { frame, frameCount, progress };
  }

  function pressureAccent(palette, pressure) {
    switch (pressure) {
      case "time": return palette.accentTime;
      case "access": return palette.accentAccess;
      case "trust": return palette.accentTrust;
      case "rent": return palette.accentRent;
      case "stress": return palette.accentStress;
      default: return palette.wire;
    }
  }

  function svgRect(x, y, width, height, fill, opacity) {
    return `<rect x="${x}" y="${y}" width="${width}" height="${height}" fill="${fill}"${opacity == null ? "" : ` opacity="${opacity}"`}/>`;
  }

  function svgPolygon(points, fill, opacity, stroke, strokeWidth) {
    return `<polygon points="${points}" fill="${fill}"${opacity == null ? "" : ` opacity="${opacity}"`}${stroke ? ` stroke="${stroke}" stroke-width="${strokeWidth || 1}"` : ""}/>`;
  }

  function svgLine(x1, y1, x2, y2, stroke, strokeWidth, opacity) {
    return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${stroke}" stroke-width="${strokeWidth}"${opacity == null ? "" : ` opacity="${opacity}"`} stroke-linecap="square"/>`;
  }

  function svgCircle(cx, cy, radius, fill, opacity, stroke, strokeWidth) {
    return `<circle cx="${cx}" cy="${cy}" r="${radius}" fill="${fill}"${opacity == null ? "" : ` opacity="${opacity}"`}${stroke ? ` stroke="${stroke}" stroke-width="${strokeWidth || 1}"` : ""}/>`;
  }

  function diamond(cx, cy, hw, hh) {
    return `${cx},${cy - hh} ${cx + hw},${cy} ${cx},${cy + hh} ${cx - hw},${cy}`;
  }

  function ribbon(cx, cy, ax, ay, halfLength, halfWidth) {
    const axisLength = Math.sqrt(ax * ax + ay * ay) || 1;
    const nx = ax / axisLength;
    const ny = ay / axisLength;
    const px = -ny;
    const py = nx;
    const p1 = [cx - nx * halfLength - px * halfWidth, cy - ny * halfLength - py * halfWidth];
    const p2 = [cx + nx * halfLength - px * halfWidth, cy + ny * halfLength - py * halfWidth];
    const p3 = [cx + nx * halfLength + px * halfWidth, cy + ny * halfLength + py * halfWidth];
    const p4 = [cx - nx * halfLength + px * halfWidth, cy - ny * halfLength + py * halfWidth];
    return [p1, p2, p3, p4].map((point) => `${point[0]},${point[1]}`).join(" ");
  }

  function withSvgFrame(width, height, body) {
    return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" shape-rendering="crispEdges">\n${body}\n</svg>`;
  }

  function buildSky(width, height, palette) {
    const bands = [];
    const bandCount = 12;
    const bandHeight = Math.ceil((height * 0.4) / bandCount);
    for (let index = 0; index < bandCount; index += 1) {
      const t = index / Math.max(1, bandCount - 1);
      bands.push(svgRect(0, index * bandHeight, width, bandHeight + 1, mixColor(palette.skyTop, palette.skyBottom, t)));
    }
    return bands.join("");
  }

  function buildSkyline(width, height, palette, rng) {
    const horizon = [];
    const blockWidth = Math.round(width / 7);
    for (let index = 0; index < 7; index += 1) {
      const towerHeight = Math.round(height * (0.16 + rng() * 0.18));
      const x = index * blockWidth - 8 + Math.round(rng() * 18);
      const y = Math.round(height * 0.26) - towerHeight;
      const w = blockWidth - 12 + Math.round(rng() * 22);
      horizon.push(svgRect(x, y, w, towerHeight, index % 2 === 0 ? palette.buildingDark : palette.buildingMid));
      const windowColor = mixColor(palette.buildingLight, palette.paper, 0.18);
      for (let row = 0; row < 5; row += 1) {
        for (let column = 0; column < 4; column += 1) {
          if (rng() < 0.22) {
            continue;
          }
          horizon.push(svgRect(x + 12 + column * 18, y + 16 + row * 18, 8, 8, windowColor, 0.55));
        }
      }
    }
    return horizon.join("");
  }

  function buildPlazaField(width, height, palette, variant) {
    const elements = [];
    const originX = Math.round(width * 0.5);
    const originY = Math.round(height * 0.18);
    const tileWidth = width > 600 ? 82 : 24;
    const tileHeight = width > 600 ? 40 : 12;
    for (let row = 0; row < 8; row += 1) {
      for (let column = 0; column < 8; column += 1) {
        const centerX = originX + (column - row) * (tileWidth + 2);
        const centerY = originY + (column + row) * (tileHeight + 2);
        let fill = (row + column) % 2 === 0 ? palette.tileA : palette.tileB;
        if (row >= 2 && row <= 4) {
          fill = mixColor(fill, palette.avenue, 0.3);
        }
        elements.push(svgPolygon(diamond(centerX, centerY, tileWidth, tileHeight), fill));
      }
    }
    const stripY = variant === "plaza_day2" ? [270, 304, 338, 372, 406, 440] : [278, 312, 346, 380, 414, 448];
    stripY.forEach((centerY, index) => {
      elements.push(svgPolygon(diamond(originX, centerY, variant === "plaza_day2" ? 142 : 132, 10), index % 2 === 0 ? palette.avenue : palette.avenueDim));
    });
    return elements.join("");
  }

  function buildIsoBlock(cx, cy, hw, hh, depth, topColor) {
    const top = diamond(cx, cy, hw, hh).split(" ").map((point) => point.split(",").map(Number));
    const left = `${top[3][0]},${top[3][1]} ${top[0][0]},${top[0][1]} ${top[0][0]},${top[0][1] + depth} ${top[3][0]},${top[3][1] + depth}`;
    const right = `${top[0][0]},${top[0][1]} ${top[1][0]},${top[1][1]} ${top[1][0]},${top[1][1] + depth} ${top[0][0]},${top[0][1] + depth}`;
    const front = `${top[3][0]},${top[3][1]} ${top[2][0]},${top[2][1]} ${top[2][0]},${top[2][1] + depth} ${top[3][0]},${top[3][1] + depth}`;
    return [
      svgPolygon(left, mixColor(topColor, "#000000", 0.35)),
      svgPolygon(right, mixColor(topColor, "#000000", 0.18)),
      svgPolygon(front, mixColor(topColor, "#000000", 0.28)),
      svgPolygon(diamond(cx, cy, hw, hh), topColor)
    ].join("");
  }

  function buildCivicBlocks(width, height, palette, variant) {
    return [
      buildIsoBlock(width * 0.5, height * 0.18, 142, 28, variant === "plaza_day2" ? 76 : 68, palette.buildingLight),
      buildIsoBlock(width * 0.28, height * 0.51, 46, 22, 70, palette.buildingMid),
      buildIsoBlock(width * 0.72, height * 0.51, 46, 22, 70, palette.buildingMid),
      buildIsoBlock(width * 0.5, height * 0.77, variant === "plaza_day2" ? 128 : 118, 18, 34, palette.buildingDark)
    ].join("");
  }

  function buildBarricades(palette, variant) {
    const points = variant === "plaza_day2"
      ? [[468, 338], [812, 338], [468, 454], [812, 454], [560, 240], [720, 240], [560, 546], [720, 546]]
      : [[468, 338], [812, 338], [468, 454], [812, 454]];
    return points.map((point, index) => {
      const scale = variant === "plaza_day2" ? (index < 4 ? 48 : 24) : 30;
      return svgPolygon(diamond(point[0], point[1], scale, index < 4 ? 8 : 6), palette.barrier, index < 4 ? 1 : 0.9);
    }).join("");
  }

  function buildPressureRibbons(palette, pressure, variant) {
    const accent = pressureAccent(palette, pressure);
    const fill = mixColor(accent, palette.barrier, 0.36);
    const zones = variant === "plaza_day2"
      ? [[640, 248, 1, 0.12, 142, 18], [640, 585, 1, 0.12, 148, 20], [602, 524, 0.46, 1, 68, 12]]
      : [[640, 278, 1, 0.12, 132, 14], [640, 352, 0, 1, 96, 12], [676, 284, -0.58, 1, 58, 10]];
    return zones.map((zone, index) => {
      const shape = ribbon(zone[0], zone[1], zone[2], zone[3], zone[4], zone[5]);
      return [
        svgPolygon(shape, fill, 0.22),
        svgPolygon(shape, "none", null, accent, 2),
        svgPolygon(diamond(zone[0] + index * 4, zone[1] - index * 3, 10, 4), accent, 0.42)
      ].join("");
    }).join("");
  }

  function buildPaperDebris(palette, rng, anchorY) {
    const papers = [];
    for (let index = 0; index < 6; index += 1) {
      const x = 420 + index * 62 + Math.round(rng() * 8);
      const y = anchorY - index * 12 + Math.round(rng() * 6);
      papers.push(svgPolygon(`${x - 11},${y - 8} ${x + 9},${y - 3} ${x + 11},${y + 13} ${x - 8},${y + 6}`, palette.paper, 0.88));
    }
    return papers.join("");
  }

  function buildScanlines(width, height, profileId = "production") {
    const style = resolveStyleProfile(profileId);
    const lines = [];
    for (let y = 0; y < height; y += style.scanlineStride) {
      lines.push(svgRect(0, y, width, 1, "#000000", 0.08 * style.scanlineAlpha));
    }
    return lines.join("");
  }

  function buildPlazaScene(config) {
    const palette = palettes[config.palette];
    const rng = createRng(`${config.preset}:${config.seed}`);
    return withSvgFrame(
      config.width,
      config.height,
      [
        svgRect(0, 0, config.width, config.height, palette.background),
        buildSky(config.width, config.height, palette),
        buildSkyline(config.width, config.height, palette, rng),
        buildPlazaField(config.width, config.height, palette, config.variant),
        buildCivicBlocks(config.width, config.height, palette, config.variant),
        buildBarricades(palette, config.variant),
        buildPressureRibbons(palette, config.pressure, config.variant),
        buildPaperDebris(palette, rng, config.variant === "plaza_day2" ? 620 : 602),
        buildScanlines(config.width, config.height, config.profile)
      ].join("")
    );
  }

  function buildRecordsChamber(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const rng = createRng(`${config.preset}:${config.seed}`);
    const shapes = [
      svgRect(0, 0, config.width, config.height, palette.background),
      svgRect(0, 0, config.width, 74, palette.skyTop),
      svgRect(18, 28, config.width - 36, 46, palette.buildingDark),
      svgRect(28, 38, config.width - 56, 26, palette.buildingMid),
      svgRect(24, 96, config.width - 48, 94, palette.buildingMid),
      svgRect(42, 110, config.width - 84, 68, palette.buildingDark),
      svgRect(66, 144, config.width - 132, 38, palette.buildingLight),
      svgPolygon(ribbon(192, 92, 1, 0.12, 118, 8), accent, 0.18),
      svgPolygon(ribbon(192, 92, 1, 0.12, 118, 8), "none", null, accent, 2)
    ];
    for (let index = 0; index < 7; index += 1) {
      shapes.push(svgLine(76 + index * 34, 102, 76 + index * 34, 178, mixColor(accent, palette.paper, 0.16), 2, 0.38));
    }
    for (let index = 0; index < 5; index += 1) {
      shapes.push(svgPolygon(diamond(82 + index * 48 + Math.round(rng() * 4), 132 + Math.round(rng() * 14), 12, 5), palette.paper, 0.82));
    }
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildTurnstileGate(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const rng = createRng(`${config.preset}:${config.seed}`);
    const shapes = [
      svgRect(0, 0, config.width, config.height, palette.background),
      svgRect(0, 0, config.width, 78, palette.skyTop),
      svgRect(24, 84, config.width - 48, 104, palette.buildingDark),
      svgRect(58, 96, config.width - 116, 56, palette.buildingMid),
      svgRect(82, 116, config.width - 164, 82, palette.buildingLight),
      svgRect(160, 80, 64, 116, palette.buildingDark),
      svgRect(178, 80, 28, 116, accent, 0.56),
      svgPolygon(ribbon(192, 176, 1, 0.12, 118, 9), accent, 0.2),
      svgPolygon(ribbon(192, 176, 1, 0.12, 118, 9), "none", null, accent, 2)
    ];
    for (let index = 0; index < 6; index += 1) {
      shapes.push(svgLine(88, 112 + index * 16, config.width - 88, 112 + index * 16, mixColor(accent, palette.paper, 0.1), 2, 0.5));
    }
    for (let index = 0; index < 4; index += 1) {
      const x = 104 + index * 48 + Math.round(rng() * 8);
      shapes.push(svgPolygon(diamond(x, 192 - index * 4, 12, 4), palette.barrier, 0.85));
    }
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildApartmentScene(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const rng = createRng(`${config.preset}:${config.seed}`);
    const roomLeft = 282;
    const roomTop = 184;
    const roomWidth = 714;
    const roomHeight = 356;
    const shapes = [
      svgRect(0, 0, config.width, config.height, palette.background),
      buildSky(config.width, config.height, palette),
      svgRect(roomLeft, roomTop, roomWidth, roomHeight, palette.buildingDark),
      svgRect(roomLeft + 24, roomTop + 24, roomWidth - 48, roomHeight - 48, palette.buildingMid),
      svgRect(roomLeft + 64, roomTop + roomHeight - 118, 252, 76, palette.buildingLight),
      svgRect(roomLeft + 88, roomTop + roomHeight - 104, 214, 28, mixColor(palette.paper, palette.buildingLight, 0.38)),
      svgRect(roomLeft + roomWidth - 248, roomTop + roomHeight - 132, 174, 88, "#4d4038"),
      svgRect(roomLeft + roomWidth * 0.5 - 60, roomTop + 40, 120, 86, "#11141d"),
      svgRect(roomLeft + roomWidth * 0.5 - 46, roomTop + 54, 92, 58, mixColor(accent, palette.paper, 0.36), 0.72),
      svgPolygon(ribbon(640, 542, 1, 0, 184, 11), mixColor(accent, palette.barrier, 0.34), 0.14)
    ];
    for (let index = 0; index < 7; index += 1) {
      const x = roomLeft + roomWidth - 198 - index * 8;
      const y = roomTop + roomHeight - 118 + index * 7;
      shapes.push(svgPolygon(`${x - 28},${y + 16} ${x - 4},${y + 20} ${x - 12},${y + 52} ${x - 38},${y + 46}`, palette.paper, 0.9));
    }
    for (let index = 0; index < 5; index += 1) {
      const x = roomLeft + 420 + index * 42;
      const y = roomTop + 280 + Math.round(rng() * 10);
      shapes.push(svgLine(x, y, x + 24, y + 18, accent, 2, 0.24));
    }
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildTrumpPodiumAnnex(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const wash = mixColor(accent, palette.paper, 0.18);
    const w = config.width;
    const h = config.height;
    const shapes = [
      svgRect(0, 0, w, h, palette.background),
      svgRect(0, 0, w, 96, palette.skyTop),
      svgRect(42, 64, w - 84, 152, palette.buildingDark),
      svgRect(68, 88, w - 136, 112, palette.buildingMid),
      svgRect(114, 212, w - 228, 78, mixColor(palette.buildingMid, accent, 0.12)),
      svgRect(182, 248, w - 364, 56, palette.buildingLight),
      svgRect(0, 304, w, h - 304, mixColor(palette.buildingDark, palette.background, 0.18)),
      svgPolygon(ribbon(w * 0.5, 226, 1, 0, 220, 16), mixColor(accent, palette.barrier, 0.18), 0.26),
      svgPolygon(ribbon(w * 0.5, 226, 1, 0, 220, 16), "none", null, accent, 3),
      svgRect(w * 0.5 - 54, 214, 108, 142, palette.buildingDark),
      svgRect(w * 0.5 - 34, 230, 68, 82, accent, 0.72),
      svgRect(w * 0.5 - 18, 188, 36, 44, wash, 0.86)
    ];
    const bannerXs = [116, w - 176];
    bannerXs.forEach((x) => {
      shapes.push(svgRect(x, 82, 60, 184, mixColor(accent, palette.buildingDark, 0.18), 0.88));
      shapes.push(svgRect(x + 14, 96, 32, 88, wash, 0.64));
      shapes.push(svgPolygon(diamond(x + 30, 210, 18, 18), accent, 0.74));
      shapes.push(svgPolygon(diamond(x + 30, 210, 8, 8), palette.background, 0.58));
    });
    for (let row = 0; row < 3; row += 1) {
      for (let column = 0; column < 6; column += 1) {
        const seatX = 186 + column * 92 + (row % 2 === 0 ? 0 : 20);
        const seatY = 364 + row * 50;
        shapes.push(svgRect(seatX, seatY, 58, 18, palette.buildingMid, 0.92));
        shapes.push(svgRect(seatX + 10, seatY - 16, 38, 14, mixColor(palette.buildingLight, accent, 0.18), 0.78));
      }
    }
    shapes.push(svgLine(w * 0.5 - 190, 72, w * 0.5 - 62, 212, wash, 3, 0.32));
    shapes.push(svgLine(w * 0.5 + 190, 72, w * 0.5 + 62, 212, wash, 3, 0.32));
    shapes.push(buildScanlines(w, h, config.profile));
    return withSvgFrame(w, h, shapes.join(""));
  }

  function buildMuskPriorityLane(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const w = config.width;
    const h = config.height;
    const premium = mixColor(accent, palette.paper, 0.12);
    const fallback = mixColor(palette.buildingMid, palette.paper, 0.08);
    const shapes = [
      svgRect(0, 0, w, h, palette.background),
      svgRect(0, 0, w, 86, palette.skyTop),
      svgRect(42, 84, w - 84, h - 140, palette.buildingDark),
      svgRect(84, 124, w - 168, h - 212, palette.buildingMid),
      svgPolygon(ribbon(w * 0.34, h * 0.68, 1, 0.08, 250, 32), premium, 0.3),
      svgPolygon(ribbon(w * 0.72, h * 0.74, 1, 0.08, 210, 26), fallback, 0.22),
      svgRect(126, 184, w - 252, 18, mixColor(palette.paper, accent, 0.12), 0.34),
      svgRect(126, 222, w - 252, 8, mixColor(palette.paper, palette.buildingMid, 0.2), 0.24),
      svgRect(126, 260, w - 252, 8, mixColor(palette.paper, palette.buildingMid, 0.2), 0.24),
      svgRect(148, 150, 176, 42, accent, 0.6),
      svgRect(w - 324, 150, 176, 42, mixColor(palette.buildingMid, accent, 0.1), 0.72),
      svgRect(214, 312, 18, 108, accent, 0.72),
      svgRect(232, 352, 96, 22, accent, 0.44),
      svgRect(w - 250, 302, 18, 116, palette.barrier, 0.64),
      svgRect(w - 232, 350, 86, 22, palette.barrier, 0.34)
    ];
    const arrowYs = [336, 392, 448];
    arrowYs.forEach((y, index) => {
      const x = 156 + index * 118;
      shapes.push(svgPolygon(`${x},${y - 14} ${x + 34},${y} ${x},${y + 14} ${x + 12},${y}`, accent, 0.82));
    });
    const fallbackYs = [352, 410, 462];
    fallbackYs.forEach((y, index) => {
      const x = w - 338 + index * 94;
      shapes.push(svgPolygon(`${x},${y - 10} ${x + 24},${y} ${x},${y + 10} ${x + 8},${y}`, mixColor(palette.barrier, palette.paper, 0.08), 0.68));
    });
    for (let index = 0; index < 5; index += 1) {
      const x = 122 + index * 148;
      shapes.push(svgLine(x, 124, x, h - 74, mixColor(accent, palette.paper, 0.14), 2, 0.22));
    }
    shapes.push(buildScanlines(w, h, config.profile));
    return withSvgFrame(w, h, shapes.join(""));
  }

  function buildVdlPacketHall(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const w = config.width;
    const h = config.height;
    const shapes = [
      svgRect(0, 0, w, h, palette.background),
      svgRect(0, 0, w, 88, palette.skyTop),
      svgRect(54, 78, w - 108, h - 132, palette.buildingDark),
      svgRect(86, 120, w - 172, h - 204, palette.buildingMid),
      svgRect(110, 152, w - 220, 66, mixColor(palette.buildingLight, palette.paper, 0.1)),
      svgRect(140, 248, w - 280, 174, palette.buildingDark),
      svgPolygon(ribbon(w * 0.5, 266, 1, 0.04, 258, 20), mixColor(accent, palette.paper, 0.14), 0.24),
      svgPolygon(ribbon(w * 0.5, 266, 1, 0.04, 258, 20), "none", null, accent, 2)
    ];
    for (let index = 0; index < 4; index += 1) {
      const x = 168 + index * 150;
      shapes.push(svgRect(x, 166, 86, 160, mixColor(palette.buildingMid, palette.paper, 0.06), 0.92));
      shapes.push(svgRect(x + 12, 182, 62, 18, accent, 0.42));
      for (let row = 0; row < 5; row += 1) {
        shapes.push(svgRect(x + 14, 214 + row * 18, 52, 4, mixColor(palette.paper, palette.buildingMid, 0.24), 0.48));
      }
    }
    for (let index = 0; index < 3; index += 1) {
      const x = 188 + index * 196;
      shapes.push(svgRect(x, 346, 146, 30, palette.buildingLight, 0.84));
      shapes.push(svgRect(x + 16, 318, 112, 20, mixColor(accent, palette.paper, 0.12), 0.62));
    }
    shapes.push(svgLine(154, 152, 154, 438, mixColor(accent, palette.paper, 0.14), 3, 0.24));
    shapes.push(svgLine(w - 154, 152, w - 154, 438, mixColor(accent, palette.paper, 0.14), 3, 0.24));
    shapes.push(buildScanlines(w, h, config.profile));
    return withSvgFrame(w, h, shapes.join(""));
  }

  function buildLagardeHousingOffice(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const w = config.width;
    const h = config.height;
    const desk = mixColor(palette.buildingDark, palette.barrier, 0.12);
    const paper = mixColor(palette.paper, accent, 0.08);
    const shapes = [
      svgRect(0, 0, w, h, palette.background),
      svgRect(0, 0, w, 92, palette.skyTop),
      svgRect(58, 88, w - 116, h - 146, palette.buildingDark),
      svgRect(94, 128, w - 188, h - 228, palette.buildingMid),
      svgRect(128, 164, 246, 144, mixColor(palette.buildingLight, palette.paper, 0.08)),
      svgRect(406, 156, 360, 180, desk),
      svgRect(452, 206, 270, 38, mixColor(accent, palette.paper, 0.14), 0.58),
      svgRect(446, 354, 290, 62, palette.buildingLight, 0.78),
      svgRect(158, 338, 166, 88, mixColor(palette.barrier, palette.buildingDark, 0.14), 0.82),
      svgPolygon(ribbon(w * 0.5, 404, 1, 0, 222, 18), mixColor(accent, palette.barrier, 0.18), 0.22)
    ];
    for (let index = 0; index < 4; index += 1) {
      shapes.push(svgRect(152, 178 + index * 28, 190, 10, mixColor(palette.paper, palette.buildingMid, 0.24), 0.54));
    }
    const bars = [94, 128, 164, 202];
    bars.forEach((barHeight, index) => {
      shapes.push(svgRect(176 + index * 34, 292 - barHeight, 20, barHeight, mixColor(accent, palette.buildingLight, 0.18 + index * 0.08), 0.82));
    });
    for (let index = 0; index < 5; index += 1) {
      const x = 482 + index * 44;
      shapes.push(svgPolygon(`${x},382 ${x + 28},388 ${x + 18},434 ${x - 10},426`, paper, 0.94));
    }
    shapes.push(svgRect(782, 164, 54, 188, mixColor(accent, palette.buildingDark, 0.22), 0.84));
    shapes.push(svgRect(794, 184, 30, 126, paper, 0.16));
    shapes.push(buildScanlines(w, h, config.profile));
    return withSvgFrame(w, h, shapes.join(""));
  }

  function buildActorSprite(config, spec) {
    const palette = palettes[config.palette];
    const style = resolveStyleProfile(config.profile);
    const accent = spec.accent || pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const centerX = Math.round(width * 0.5);
    const shadowY = height - 22;
    const coat = spec.coat || palette.buildingMid;
    const skin = spec.skin || "#efcfba";
    const hair = spec.hair || mixColor(coat, palette.background, 0.28);
    const prop = spec.prop || accent;
    const torsoTop = spec.torsoTop || 66;
    const torsoBottom = spec.torsoBottom || 124;
    const torsoWidth = Math.round((spec.torsoWidth || 24) * style.silhouetteScale);
    const headY = spec.headY || 42;
    const headRadius = Math.round((spec.headRadius || 16) * (0.94 + (style.silhouetteScale - 1.0) * 0.5));
    const outlineColor = mixColor(coat, palette.background, 0.2);
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      svgPolygon(diamond(centerX, shadowY, 34, 14), mixColor(palette.background, palette.buildingDark, 0.18), 0.34 * style.shadowAlpha),
      svgPolygon(diamond(centerX, shadowY - 8, 22, 10), mixColor(accent, palette.background, 0.18), 0.12 * style.highlightAlpha),
      svgPolygon(`${centerX},${torsoTop} ${centerX + torsoWidth},${torsoTop + 18} ${centerX + torsoWidth - 2},${torsoBottom} ${centerX},${torsoBottom + 18} ${centerX - torsoWidth + 2},${torsoBottom} ${centerX - torsoWidth},${torsoTop + 18}`, coat, 0.98, outlineColor, style.outlineWidth),
      svgRect(centerX - 8, torsoTop + 16, 16, torsoBottom - torsoTop + 8, mixColor(coat, palette.paper, 0.08), 0.42 * style.highlightAlpha),
      svgPolygon(`${centerX - 10},${torsoTop + 22} ${centerX},${torsoTop + 34} ${centerX + 10},${torsoTop + 22} ${centerX},${torsoTop + 20}`, accent, 0.76 * style.highlightAlpha),
      svgCircle(centerX, headY, headRadius, skin, 0.98, mixColor(skin, palette.background, 0.22), style.outlineWidth),
      svgRect(centerX - headRadius + 2, headY - headRadius + 2, headRadius * 2 - 4, 10, hair, 0.9),
      svgRect(centerX - headRadius + 6, headY - headRadius + 10, headRadius * 2 - 12, 4, hair, 0.62 * style.highlightAlpha),
      svgRect(centerX - 3, torsoBottom + 8, 6, 26, mixColor(coat, palette.background, 0.18), 0.84 * style.shadowAlpha),
      svgRect(centerX - 18, torsoBottom + 24, 12, 6, mixColor(palette.background, coat, 0.12), 0.72 * style.shadowAlpha),
      svgRect(centerX + 6, torsoBottom + 24, 12, 6, mixColor(palette.background, coat, 0.12), 0.72 * style.shadowAlpha)
    ];

    if (spec.shoulderWidth) {
      shapes.push(svgRect(centerX - spec.shoulderWidth, torsoTop + 12, spec.shoulderWidth * 2, 10, mixColor(coat, palette.paper, 0.08), 0.32));
    }
    if (spec.propShape === "scanner") {
      shapes.push(svgRect(centerX + 18, torsoTop + 30, 20, 28, prop, 0.86));
      shapes.push(svgRect(centerX + 22, torsoTop + 36, 12, 8, palette.paper, 0.54));
      shapes.push(svgLine(centerX + 14, torsoTop + 44, centerX + 44, torsoTop + 44, accent, 2, 0.32));
    } else if (spec.propShape === "packet") {
      shapes.push(svgRect(centerX + 12, torsoTop + 24, 28, 38, mixColor(palette.paper, accent, 0.08), 0.96));
      shapes.push(svgRect(centerX + 16, torsoTop + 30, 18, 6, accent, 0.58));
      shapes.push(svgRect(centerX + 16, torsoTop + 42, 14, 4, mixColor(palette.paper, palette.buildingMid, 0.22), 0.58));
    } else if (spec.propShape === "ledger") {
      shapes.push(svgRect(centerX + 14, torsoTop + 26, 26, 34, mixColor(palette.paper, accent, 0.08), 0.94));
      shapes.push(svgLine(centerX + 18, torsoTop + 34, centerX + 34, torsoTop + 48, accent, 3, 0.46));
      shapes.push(svgPolygon(diamond(centerX + 32, torsoTop + 48, 6, 6), accent, 0.68));
    } else if (spec.propShape === "podium") {
      shapes.push(svgRect(centerX - 18, torsoBottom - 4, 36, 34, mixColor(prop, palette.background, 0.14), 0.96));
      shapes.push(svgRect(centerX - 14, torsoBottom + 4, 28, 10, accent, 0.72));
      shapes.push(svgRect(centerX - 8, torsoBottom + 18, 16, 10, mixColor(palette.paper, accent, 0.16), 0.42));
    } else if (spec.propShape === "bag") {
      shapes.push(svgRect(centerX + 12, torsoTop + 38, 18, 26, mixColor(prop, palette.background, 0.12), 0.88));
      shapes.push(svgLine(centerX + 10, torsoTop + 34, centerX + 28, torsoTop + 44, prop, 3, 0.42));
    }

    if (spec.faceStripe) {
      shapes.push(svgRect(centerX - 10, headY + 4, 20, 3, mixColor(hair, skin, 0.3), 0.46));
    }

    shapes.push(buildScanlines(width, height, config.profile));
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildCheckpointSprite(config, kind) {
    const palette = palettes[config.palette];
    const style = resolveStyleProfile(config.profile);
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const centerX = Math.round(width * 0.5);
    const baseY = height - 30;
    const body = kind === "records" ? palette.buildingMid : mixColor(palette.buildingDark, palette.barrier, 0.14);
    const outlineColor = mixColor(body, palette.background, 0.22);
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      svgPolygon(diamond(centerX, baseY, 40, 16), mixColor(palette.background, body, 0.14), 0.34 * style.shadowAlpha),
      svgPolygon(diamond(centerX, baseY - 10, 28, 10), mixColor(accent, palette.background, 0.18), 0.14 * style.highlightAlpha)
    ];

    if (kind === "records") {
      shapes.push(
        svgRect(centerX - 42, 42, 84, 92, body, 0.98),
        svgRect(centerX - 30, 56, 60, 52, mixColor(body, palette.paper, 0.08), 0.94 * style.highlightAlpha),
        svgRect(centerX - 18, 76, 36, 14, accent, 0.76 * style.highlightAlpha),
        svgRect(centerX - 12, 104, 24, 10, mixColor(palette.paper, accent, 0.18), 0.44 * style.highlightAlpha),
        svgRect(centerX - 58, 130, 116, 20, mixColor(body, palette.background, 0.1), 0.94 * style.shadowAlpha),
        svgRect(centerX - 42, 42, 84, 92, "none", null, outlineColor, style.outlineWidth)
      );
    } else {
      shapes.push(
        svgRect(centerX - 56, 54, 18, 76, body, 0.96),
        svgRect(centerX - 20, 42, 18, 88, body, 0.98),
        svgRect(centerX + 16, 42, 18, 88, body, 0.98),
        svgRect(centerX + 52, 54, 18, 76, body, 0.96),
        svgLine(centerX - 8, 78, centerX + 8, 78, accent, 4, 0.82 * style.highlightAlpha),
        svgLine(centerX - 18, 96, centerX + 18, 96, accent, 3, 0.58 * style.highlightAlpha),
        svgPolygon(diamond(centerX, 30, 12, 12), accent, 0.72 * style.highlightAlpha)
      );
    }

    shapes.push(buildScanlines(width, height, config.profile));
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildPixelFrame(width, height, accent, palette, profileId = "production") {
    const style = resolveStyleProfile(profileId);
    return [
      svgRect(0, 0, width, 10, accent, 0.14 * style.frameAlpha),
      svgRect(0, height - 10, width, 10, accent, 0.14 * style.frameAlpha),
      svgRect(0, 0, 10, height, accent, 0.1 * style.frameAlpha),
      svgRect(width - 10, 0, 10, height, accent, 0.1 * style.frameAlpha),
      svgRect(18, 18, 92, 10, accent, 0.5 * style.frameAlpha),
      svgRect(18, 18, 10, 72, accent, 0.5 * style.frameAlpha),
      svgRect(width - 110, 18, 92, 10, accent, 0.5 * style.frameAlpha),
      svgRect(width - 28, 18, 10, 72, accent, 0.5 * style.frameAlpha),
      svgRect(18, height - 28, 92, 10, accent, 0.5 * style.frameAlpha),
      svgRect(18, height - 90, 10, 72, accent, 0.5 * style.frameAlpha),
      svgRect(width - 110, height - 28, 92, 10, accent, 0.5 * style.frameAlpha),
      svgRect(width - 28, height - 90, 10, 72, accent, 0.5 * style.frameAlpha),
      svgRect(28, 28, width - 56, height - 56, mixColor(palette.background, accent, 0.08), 0.08 * style.frameAlpha)
    ].join("");
  }

  function buildShadowMask(width, height, accent, stride = 14, profileId = "production") {
    const style = resolveStyleProfile(profileId);
    const mask = [];
    for (let x = 0; x < width; x += stride) {
      mask.push(svgRect(x, 0, 4, height, accent, (x % (stride * 2) === 0 ? 0.035 : 0.02) * style.stripeAlpha));
    }
    return mask.join("");
  }

  function buildFxClusters(width, height, accent, palette, rng, count) {
    const clusters = [];
    for (let index = 0; index < count; index += 1) {
      const x = 48 + Math.round(rng() * (width - 96));
      const y = 40 + Math.round(rng() * (height - 80));
      const size = 6 + Math.round(rng() * 8);
      clusters.push(svgRect(x, y, size, size, mixColor(accent, palette.paper, 0.18), 0.22 + rng() * 0.12));
      clusters.push(svgRect(x + size + 4, y + 2, Math.max(4, size - 2), 2, accent, 0.18 + rng() * 0.08));
      clusters.push(svgRect(x - 10, y + size + 4, size + 18, 2, mixColor(palette.paper, accent, 0.18), 0.12 + rng() * 0.06));
    }
    return clusters.join("");
  }

  function buildPlazaPixelFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const rng = createRng(`${config.preset}:${config.seed}`);
    const width = config.width;
    const height = config.height;
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgPolygon(ribbon(width * 0.42, height * 0.34, 1, 0.08, 380, 22), mixColor(accent, palette.paper, 0.14), 0.14),
      svgPolygon(ribbon(width * 0.66, height * 0.68, 1, 0.06, 320, 20), mixColor(palette.paper, accent, 0.16), 0.1),
      svgRect(0, 0, width, 96, palette.background, 0.16),
      svgRect(0, height - 124, width, 124, palette.background, 0.12),
      buildShadowMask(width, height, accent, 16, config.profile),
      buildFxClusters(width, height, accent, palette, rng, 18),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildAnnexPixelFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const rng = createRng(`${config.preset}:${config.seed}`);
    const width = config.width;
    const height = config.height;
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 72, palette.background, 0.18),
      svgRect(0, height - 96, width, 96, palette.background, 0.16),
      svgPolygon(ribbon(width * 0.5, height * 0.46, 1, 0.0, 248, 14), mixColor(accent, palette.paper, 0.18), 0.16),
      svgPolygon(ribbon(width * 0.3, height * 0.72, 1, 0.12, 164, 10), mixColor(accent, palette.barrier, 0.18), 0.16),
      svgPolygon(ribbon(width * 0.74, height * 0.28, 1, -0.14, 156, 10), mixColor(palette.paper, accent, 0.12), 0.12),
      buildShadowMask(width, height, accent, 12, config.profile),
      buildFxClusters(width, height, accent, palette, rng, 14),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildTransitionPixelFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const rng = createRng(`${config.preset}:${config.seed}`);
    const width = config.width;
    const height = config.height;
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgPolygon(ribbon(width * 0.5, height * 0.5, 1, 0.0, 312, 24), mixColor(accent, palette.paper, 0.2), 0.22),
      svgPolygon(ribbon(width * 0.32, height * 0.52, 1, -0.28, 148, 10), mixColor(accent, palette.paper, 0.12), 0.2),
      svgPolygon(ribbon(width * 0.68, height * 0.48, 1, 0.28, 148, 10), mixColor(accent, palette.paper, 0.12), 0.2),
      svgRect(0, 0, width, 68, palette.background, 0.2),
      svgRect(0, height - 68, width, 68, palette.background, 0.2),
      buildShadowMask(width, height, accent, 10, config.profile),
      buildFxClusters(width, height, accent, palette, rng, 16),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildPodiumAcceptanceFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const centerX = Math.round(width * 0.5);
    const crestY = Math.round(height * 0.33);
    const frame = resolveFrameProgress(config);
    const crestOuter = 16 + Math.round(frame.progress * 20);
    const crestInner = 8 + Math.round(frame.progress * 10);
    const beamHalf = 22 + Math.round(frame.progress * 92);
    const aisleLift = 28 + Math.round(frame.progress * 72);
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 74, palette.background, 0.16),
      svgRect(0, height - 96, width, 96, palette.background, 0.18),
      svgPolygon(ribbon(centerX, height * 0.48, 1, 0.0, 260, 18), mixColor(accent, palette.paper, 0.18), 0.14),
      svgRect(centerX - 34, crestY + 52, 68, 188, mixColor(accent, palette.barrier, 0.2), 0.26),
      svgRect(centerX - (80 + Math.round(frame.progress * 18)), crestY + 156, 160 + Math.round(frame.progress * 36), 18, accent, 0.18 + frame.progress * 0.16),
      svgRect(centerX - (108 + Math.round(frame.progress * 16)), crestY + 176, 216 + Math.round(frame.progress * 32), 10, mixColor(palette.paper, accent, 0.18), 0.12 + frame.progress * 0.12),
      svgPolygon(diamond(centerX, crestY, crestOuter, crestOuter), accent, 0.42 + frame.progress * 0.4),
      svgPolygon(diamond(centerX, crestY, crestInner, crestInner), palette.paper, 0.5 + frame.progress * 0.18),
      svgLine(centerX - beamHalf, crestY + 12, centerX + beamHalf, crestY + 12, accent, 6, 0.16 + frame.progress * 0.2),
      svgLine(centerX - 22, crestY - aisleLift, centerX - 22, crestY - 8, mixColor(accent, palette.paper, 0.16), 4, 0.12 + frame.progress * 0.14),
      svgLine(centerX + 22, crestY - aisleLift, centerX + 22, crestY - 8, mixColor(accent, palette.paper, 0.16), 4, 0.12 + frame.progress * 0.14),
      svgLine(centerX - 144, crestY + 92, centerX + 144, crestY + 92, mixColor(accent, palette.paper, 0.14), 4, 0.08 + frame.progress * 0.16),
      buildShadowMask(width, height, accent, 14, config.profile),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildScannerTapFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const laneY = Math.round(height * 0.56);
    const frame = resolveFrameProgress(config);
    const beamX = Math.round(lerpNumber(252, 734, frame.progress));
    const beamWidth = 36 + Math.round(frame.progress * 18);
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 64, palette.background, 0.18),
      svgRect(0, height - 86, width, 86, palette.background, 0.2),
      svgPolygon(ribbon(width * 0.46, laneY, 1, 0.0, 408, 22), mixColor(accent, palette.paper, 0.16), 0.18),
      svgRect(166, laneY - 74, 84, 148, mixColor(accent, palette.barrier, 0.18), 0.22),
      svgRect(176, laneY - 60, 64, 18, accent, 0.16 + frame.progress * 0.18),
      svgRect(176, laneY - 24, 64, 12, mixColor(palette.paper, accent, 0.16), 0.14 + frame.progress * 0.16),
      svgRect(284, laneY - 96, 428, 18, mixColor(accent, palette.paper, 0.16), 0.14),
      svgRect(284, laneY - 46, 428, 14, accent, 0.12 + frame.progress * 0.16),
      svgRect(284, laneY + 2, 428, 10, mixColor(palette.paper, accent, 0.16), 0.22),
      svgRect(beamX - Math.round(beamWidth * 0.5), laneY - 112, beamWidth, 162, accent, 0.18 + frame.progress * 0.18),
      svgRect(beamX - 8, laneY - 126, 16, 188, mixColor(palette.paper, accent, 0.18), 0.24 + frame.progress * 0.18),
      svgLine(250, laneY - 18, 774, laneY - 18, accent, 4, 0.22),
      svgLine(250, laneY + 28, 774, laneY + 28, accent, 3, 0.16),
      svgLine(250, laneY + 64, 774, laneY + 64, mixColor(palette.paper, accent, 0.14), 3, 0.14),
      svgLine(beamX - 52, laneY + 14, beamX + 52, laneY + 14, accent, 5, 0.14 + frame.progress * 0.16),
      buildFxClusters(width, height, accent, palette, createRng(`${config.preset}:${config.seed}`), 10),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildPacketHandoffFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const frame = resolveFrameProgress(config);
    const packetX = Math.round(lerpNumber(226, 610, frame.progress));
    const packetY = Math.round(lerpNumber(330, 252, frame.progress));
    const trailX = Math.round(lerpNumber(308, 590, frame.progress));
    const trailY = Math.round(lerpNumber(344, 268, frame.progress));
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 72, palette.background, 0.14),
      svgRect(0, height - 92, width, 92, palette.background, 0.16),
      svgPolygon(ribbon(width * 0.34, height * 0.56, 1, -0.22, 194, 18), mixColor(accent, palette.paper, 0.18), 0.18),
      svgPolygon(ribbon(width * 0.62, height * 0.42, 1, 0.22, 216, 18), mixColor(accent, palette.barrier, 0.18), 0.16),
      svgRect(164, 292, 116, 70, mixColor(palette.paper, accent, 0.08), 0.42),
      svgRect(192, 308, 88, 12, accent, 0.12 + frame.progress * 0.16),
      svgRect(192, 332, 72, 8, mixColor(palette.paper, accent, 0.18), 0.12 + frame.progress * 0.14),
      svgRect(608, 212, 98, 148, mixColor(accent, palette.barrier, 0.2), 0.24),
      svgRect(624, 234, 66, 18, accent, 0.16 + frame.progress * 0.18),
      svgRect(624, 268, 66, 12, mixColor(palette.paper, accent, 0.18), 0.14 + frame.progress * 0.14),
      svgLine(286, 326, trailX, trailY, accent, 8, 0.16 + frame.progress * 0.18),
      svgLine(286, 352, trailX, trailY + 28, mixColor(palette.paper, accent, 0.16), 4, 0.12 + frame.progress * 0.1),
      svgRect(packetX - 38, packetY - 22, 76, 44, mixColor(palette.paper, accent, 0.08), 0.16 + frame.progress * 0.2),
      svgRect(packetX - 28, packetY - 10, 56, 10, accent, 0.18 + frame.progress * 0.18),
      svgRect(packetX - 28, packetY + 8, 44, 6, mixColor(palette.paper, accent, 0.18), 0.16 + frame.progress * 0.14),
      buildShadowMask(width, height, accent, 13, config.profile),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildLedgerSigningFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const frame = resolveFrameProgress(config);
    const strokeOne = clamp01(frame.progress / 0.34);
    const strokeTwo = clamp01((frame.progress - 0.28) / 0.3);
    const strokeThree = clamp01((frame.progress - 0.54) / 0.34);
    const sealSize = 10 + Math.round(frame.progress * 8);
    const shapes = [
      svgRect(0, 0, width, height, "none", 0),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 74, palette.background, 0.16),
      svgRect(0, height - 96, width, 96, palette.background, 0.18),
      svgRect(204, 156, 506, 240, mixColor(palette.paper, accent, 0.08), 0.12),
      svgRect(230, 184, 220, 18, accent, 0.14 + frame.progress * 0.18),
      svgRect(230, 222, 452, 4, mixColor(palette.paper, palette.buildingMid, 0.24), 0.42),
      svgRect(230, 258, 452, 4, mixColor(palette.paper, palette.buildingMid, 0.24), 0.42),
      svgRect(230, 294, 452, 4, mixColor(palette.paper, palette.buildingMid, 0.24), 0.42),
      svgRect(230, 330, 452, 4, mixColor(palette.paper, palette.buildingMid, 0.24), 0.42),
      svgLine(262, 338, Math.round(lerpNumber(262, 354, strokeOne)), Math.round(lerpNumber(338, 282, strokeOne)), accent, 8, 0.18 + strokeOne * 0.14),
      svgLine(352, 284, Math.round(lerpNumber(352, 424, strokeTwo)), Math.round(lerpNumber(284, 348, strokeTwo)), accent, 8, 0.18 + strokeTwo * 0.14),
      svgLine(426, 350, Math.round(lerpNumber(426, 534, strokeThree)), Math.round(lerpNumber(350, 254, strokeThree)), mixColor(palette.paper, accent, 0.16), 5, 0.14 + strokeThree * 0.1),
      svgPolygon(diamond(604, 314, sealSize, sealSize), accent, 0.34 + frame.progress * 0.38),
      svgPolygon(diamond(604, 314, Math.max(5, sealSize - 9), Math.max(5, sealSize - 9)), palette.paper, 0.42 + frame.progress * 0.16),
      buildFxClusters(width, height, accent, palette, createRng(`${config.preset}:${config.seed}`), 8),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildDossierCommitEventFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const frame = resolveFrameProgress(config);
    const paperX = Math.round(lerpNumber(260, 430, frame.progress));
    const paperY = Math.round(lerpNumber(438, 208, frame.progress));
    const sealSize = 22 + Math.round(frame.progress * 26);
    const burstAlpha = 0.12 + frame.progress * 0.22;
    const shapes = [
      svgRect(0, 0, width, height, palette.background, 0.94),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 112, palette.background, 0.28),
      svgRect(0, height - 122, width, 122, palette.background, 0.22),
      svgPolygon(ribbon(width * 0.48, height * 0.58, 1, 0.0, 468, 26), mixColor(accent, palette.paper, 0.18), 0.12 + frame.progress * 0.1),
      svgRect(paperX, paperY, 360, 216, mixColor(palette.paper, accent, 0.06), 0.86),
      svgRect(paperX + 26, paperY + 28, 170, 16, accent, 0.42 + frame.progress * 0.2),
      svgRect(paperX + 26, paperY + 64, 286, 6, mixColor(palette.paper, palette.buildingMid, 0.22), 0.54),
      svgRect(paperX + 26, paperY + 84, 252, 6, mixColor(palette.paper, palette.buildingMid, 0.22), 0.42),
      svgRect(paperX + 26, paperY + 104, 226, 6, mixColor(palette.paper, palette.buildingMid, 0.22), 0.42),
      svgRect(paperX + 210, paperY + 132, 112, 54, mixColor(accent, palette.paper, 0.18), 0.22 + frame.progress * 0.16),
      svgPolygon(diamond(paperX + 266, paperY + 160, sealSize, sealSize), accent, 0.34 + frame.progress * 0.38),
      svgPolygon(diamond(paperX + 266, paperY + 160, Math.max(8, sealSize - 10), Math.max(8, sealSize - 10)), palette.paper, 0.46 + frame.progress * 0.16),
      svgLine(paperX + 84, paperY + 180, paperX + 318, paperY + 180, accent, 5, burstAlpha),
      svgLine(paperX + 202, paperY + 88, paperX + 202, paperY + 212, accent, 5, burstAlpha),
      buildShadowMask(width, height, accent, 18, config.profile),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildRecordsStampEventFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const frame = resolveFrameProgress(config);
    const stampY = Math.round(lerpNumber(168, 346, frame.progress));
    const ringSize = 64 + Math.round(frame.progress * 26);
    const platenWidth = 200 + Math.round(frame.progress * 42);
    const shapes = [
      svgRect(0, 0, width, height, palette.background, 0.94),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(182, 420, 916, 160, mixColor(palette.buildingDark, palette.buildingMid, 0.28), 0.78),
      svgRect(248, 456, 760, 74, mixColor(palette.paper, accent, 0.06), 0.84),
      svgRect(280, 476, 220, 14, accent, 0.22 + frame.progress * 0.18),
      svgRect(280, 508, 408, 6, mixColor(palette.paper, palette.buildingMid, 0.22), 0.48),
      svgRect(760, 284, platenWidth, 32, mixColor(accent, palette.barrier, 0.18), 0.26),
      svgRect(824, 192, 82, 176, mixColor(accent, palette.barrier, 0.2), 0.28),
      `<circle cx="865" cy="${stampY}" r="${ringSize}" fill="none" stroke="${mixColor(accent, palette.paper, 0.18)}" stroke-width="14" opacity="${(0.18 + frame.progress * 0.5).toFixed(3)}"/>`,
      `<circle cx="865" cy="${stampY}" r="${Math.max(28, ringSize - 24)}" fill="none" stroke="${mixColor(accent, palette.paper, 0.12)}" stroke-width="8" opacity="${(0.12 + frame.progress * 0.34).toFixed(3)}"/>`,
      svgRect(806, stampY - 8, 118, 16, accent, 0.22 + frame.progress * 0.32),
      svgRect(822, stampY + 20, 86, 8, mixColor(palette.paper, accent, 0.18), 0.14 + frame.progress * 0.16),
      buildShadowMask(width, height, accent, 16, config.profile),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildNightShiftEventFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const frame = resolveFrameProgress(config);
    const shutterY = Math.round(lerpNumber(-220, 124, frame.progress));
    const windowGlow = 0.14 + frame.progress * 0.22;
    const shapes = [
      svgRect(0, 0, width, height, palette.background, 0.96),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 110, palette.background, 0.34),
      svgRect(0, height - 134, width, 134, palette.background, 0.28),
      svgRect(208, 136, 864, 448, mixColor(palette.buildingDark, palette.buildingMid, 0.24), 0.72),
      svgRect(266, 196, 198, 136, mixColor(palette.paper, accent, 0.08), windowGlow),
      svgRect(542, 176, 214, 148, mixColor(palette.paper, accent, 0.08), windowGlow * 0.92),
      svgRect(836, 214, 166, 122, mixColor(palette.paper, accent, 0.08), windowGlow * 0.86),
      svgRect(184, shutterY, 912, 196, mixColor(accent, palette.background, 0.22), 0.28 + frame.progress * 0.28),
      svgLine(184, shutterY + 42, 1096, shutterY + 42, accent, 5, 0.18 + frame.progress * 0.18),
      svgLine(184, shutterY + 96, 1096, shutterY + 96, accent, 5, 0.18 + frame.progress * 0.18),
      svgLine(184, shutterY + 150, 1096, shutterY + 150, accent, 5, 0.18 + frame.progress * 0.18),
      svgPolygon(ribbon(width * 0.5, height * 0.68, 1, 0.0, 520, 28), mixColor(accent, palette.paper, 0.12), 0.08 + frame.progress * 0.12),
      buildFxClusters(width, height, accent, palette, createRng(`${config.preset}:${config.seed}`), 16),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildTurnstileReleaseEventFx(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const width = config.width;
    const height = config.height;
    const frame = resolveFrameProgress(config);
    const gateOffset = Math.round(lerpNumber(0, 82, frame.progress));
    const pathAlpha = 0.12 + frame.progress * 0.24;
    const beaconSize = 14 + Math.round(frame.progress * 12);
    const shapes = [
      svgRect(0, 0, width, height, palette.background, 0.94),
      buildPixelFrame(width, height, accent, palette, config.profile),
      svgRect(0, 0, width, 96, palette.background, 0.24),
      svgRect(0, height - 118, width, 118, palette.background, 0.22),
      svgPolygon(ribbon(width * 0.5, height * 0.7, 1, 0.0, 472, 34), mixColor(accent, palette.paper, 0.18), pathAlpha),
      svgRect(314 - gateOffset, 182, 94, 304, mixColor(accent, palette.barrier, 0.18), 0.24),
      svgRect(468 - Math.round(gateOffset * 0.5), 154, 94, 332, mixColor(accent, palette.barrier, 0.18), 0.28),
      svgRect(718 + Math.round(gateOffset * 0.5), 154, 94, 332, mixColor(accent, palette.barrier, 0.18), 0.28),
      svgRect(872 + gateOffset, 182, 94, 304, mixColor(accent, palette.barrier, 0.18), 0.24),
      svgLine(448, 284, 832, 284, accent, 12, 0.14 + frame.progress * 0.18),
      svgLine(432, 354, 848, 354, accent, 8, 0.12 + frame.progress * 0.16),
      svgPolygon(diamond(640, 256, beaconSize, beaconSize), accent, 0.38 + frame.progress * 0.34),
      svgPolygon(diamond(640, 256, Math.max(7, beaconSize - 8), Math.max(7, beaconSize - 8)), palette.paper, 0.44 + frame.progress * 0.14),
      buildShadowMask(width, height, accent, 18, config.profile),
      buildScanlines(width, height, config.profile)
    ];
    return withSvgFrame(width, height, shapes.join(""));
  }

  function buildRecordsPoster(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const paperBase = mixColor(palette.paper, palette.buildingLight, 0.12);
    const shapes = [
      svgRect(0, 0, config.width, config.height, palette.buildingDark),
      svgRect(10, 10, config.width - 20, config.height - 20, paperBase),
      svgRect(16, 16, config.width - 32, 28, accent),
      svgRect(20, 54, config.width - 40, 12, palette.buildingMid, 0.85),
      svgRect(20, 72, config.width - 56, 6, mixColor(palette.buildingMid, palette.paper, 0.18), 0.82),
      svgRect(20, 88, config.width - 40, 6, mixColor(palette.buildingMid, palette.paper, 0.18), 0.82),
      svgRect(20, 104, config.width - 48, 6, mixColor(palette.buildingMid, palette.paper, 0.18), 0.82),
      svgRect(20, 132, config.width - 40, 46, mixColor(palette.paper, accent, 0.08)),
      svgRect(30, 142, 18, 18, accent, 0.88),
      svgRect(58, 146, config.width - 90, 8, palette.buildingMid, 0.72),
      svgRect(58, 160, config.width - 100, 6, palette.buildingMid, 0.5),
      svgRect(20, 188, config.width - 40, 18, palette.buildingDark, 0.84),
      svgPolygon(diamond(config.width - 30, 30, 10, 10), mixColor(accent, palette.paper, 0.18)),
      svgPolygon(diamond(config.width - 30, 30, 6, 6), accent)
    ];
    for (let row = 0; row < 3; row += 1) {
      shapes.push(svgRect(28, 132 + row * 16, config.width - 56, 2, mixColor(palette.buildingMid, palette.paper, 0.22), 0.42));
    }
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildTurnstileSign(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const panel = mixColor(palette.buildingDark, palette.buildingMid, 0.32);
    const shapes = [
      svgRect(0, 0, config.width, config.height, "none", 0),
      svgRect(6, 10, config.width - 12, config.height - 20, panel),
      svgRect(14, 18, config.width - 28, config.height - 36, mixColor(panel, palette.paper, 0.08)),
      svgRect(22, 26, 78, config.height - 52, accent, 0.82),
      svgPolygon("46,48 72,34 72,43 100,43 100,53 72,53 72,62", palette.background, 0.9),
      svgRect(118, 30, config.width - 144, 10, mixColor(palette.paper, accent, 0.18), 0.88),
      svgRect(118, 48, config.width - 158, 8, mixColor(palette.paper, palette.buildingMid, 0.24), 0.72),
      svgRect(118, 64, config.width - 132, 6, mixColor(palette.paper, palette.buildingMid, 0.28), 0.54),
      svgRect(config.width - 46, 26, 18, config.height - 52, accent, 0.6)
    ];
    for (let index = 0; index < 3; index += 1) {
      shapes.push(svgRect(126 + index * 24, 74, 14, 6, accent, 0.68 - index * 0.12));
    }
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildBarricadeDecal(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const chevrons = [];
    chevrons.push(svgRect(0, 0, config.width, config.height, mixColor(palette.barrier, palette.buildingDark, 0.24)));
    chevrons.push(svgRect(0, 8, config.width, config.height - 16, palette.barrier, 0.88));
    for (let index = 0; index < 8; index += 1) {
      const left = 12 + index * 30;
      chevrons.push(svgPolygon(`${left},12 ${left + 24},12 ${left + 12},32`, mixColor(accent, palette.paper, 0.12), 0.78));
      chevrons.push(svgPolygon(`${left + 12},32 ${left + 24},52 ${left},52`, mixColor(palette.buildingDark, palette.barrier, 0.18), 0.9));
    }
    chevrons.push(svgRect(14, 22, config.width - 28, 6, accent, 0.54));
    chevrons.push(svgRect(28, 36, config.width - 56, 4, mixColor(palette.paper, accent, 0.18), 0.46));
    chevrons.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, chevrons.join(""));
  }

  function buildDossierCluster(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const shapes = [
      svgRect(0, 0, config.width, config.height, "none", 0),
      svgPolygon("16,32 112,16 138,98 42,112", mixColor(palette.paper, palette.buildingLight, 0.1), 0.96),
      svgPolygon("42,24 156,28 150,118 36,114", palette.paper, 0.94),
      svgPolygon("66,34 176,52 160,132 50,114", mixColor(palette.paper, accent, 0.08), 0.92),
      svgRect(54, 42, 80, 12, accent, 0.8),
      svgRect(58, 62, 84, 6, mixColor(palette.buildingMid, palette.paper, 0.2), 0.76),
      svgRect(58, 76, 70, 5, mixColor(palette.buildingMid, palette.paper, 0.2), 0.56),
      svgRect(58, 88, 62, 5, mixColor(palette.buildingMid, palette.paper, 0.2), 0.56),
      svgRect(92, 96, 46, 24, mixColor(accent, palette.paper, 0.24), 0.58),
      svgPolygon(diamond(122, 108, 10, 10), accent, 0.82),
      svgPolygon(diamond(122, 108, 5, 5), palette.background, 0.68)
    ];
    for (let index = 0; index < 4; index += 1) {
      shapes.push(svgRect(18 + index * 6, 28 + index * 2, 4, 84, mixColor(palette.buildingMid, palette.paper, 0.14), 0.28));
    }
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildCheckpointStamp(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const ring = mixColor(accent, palette.paper, 0.16);
    const shapes = [
      svgRect(0, 0, config.width, config.height, "none", 0),
      `<circle cx="56" cy="56" r="44" fill="none" stroke="${ring}" stroke-width="8" opacity="0.82"/>`,
      `<circle cx="56" cy="56" r="28" fill="none" stroke="${ring}" stroke-width="4" opacity="0.54"/>`,
      svgRect(24, 50, 64, 12, ring, 0.86),
      svgRect(30, 66, 52, 6, ring, 0.56),
      svgLine(22, 24, 90, 92, ring, 5, 0.38),
      svgLine(22, 88, 90, 20, ring, 3, 0.24)
    ];
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildAgencySeal(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const outer = mixColor(accent, palette.paper, 0.18);
    const inner = mixColor(palette.buildingMid, palette.paper, 0.24);
    const shapes = [
      svgRect(0, 0, config.width, config.height, "none", 0),
      `<circle cx="64" cy="64" r="48" fill="${palette.buildingDark}" opacity="0.84"/>`,
      `<circle cx="64" cy="64" r="48" fill="none" stroke="${outer}" stroke-width="6" opacity="0.88"/>`,
      `<circle cx="64" cy="64" r="34" fill="none" stroke="${inner}" stroke-width="4" opacity="0.62"/>`,
      svgPolygon(diamond(64, 64, 18, 18), outer, 0.82),
      svgPolygon(diamond(64, 64, 9, 9), accent, 0.72),
      svgRect(40, 96, 48, 10, outer, 0.82),
      svgRect(46, 38, 36, 6, outer, 0.54)
    ];
    for (let index = 0; index < 8; index += 1) {
      const angle = (Math.PI * 2 * index) / 8;
      const x = 64 + Math.cos(angle) * 38;
      const y = 64 + Math.sin(angle) * 38;
      shapes.push(`<circle cx="${x.toFixed(2)}" cy="${y.toFixed(2)}" r="3" fill="${outer}" opacity="0.72"/>`);
    }
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildQueueFloorArrows(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const fill = mixColor(accent, palette.barrier, 0.26);
    const shapes = [
      svgRect(0, 0, config.width, config.height, "none", 0),
      svgPolygon(ribbon(108, 54, 1, 0.06, 92, 18), fill, 0.28),
      svgPolygon(ribbon(272, 82, 1, 0.08, 84, 18), fill, 0.24)
    ];
    const arrowSets = [
      [40, 54, 0],
      [106, 56, 1],
      [172, 60, 2],
      [238, 80, 3],
      [302, 84, 4]
    ];
    arrowSets.forEach((entry) => {
      const x = entry[0];
      const y = entry[1];
      const width = 18 + entry[2] % 2;
      shapes.push(svgPolygon(`${x},${y - 10} ${x + width},${y} ${x},${y + 10} ${x + 8},${y} `, accent, 0.72));
    });
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function buildDocumentOverlay(config) {
    const palette = palettes[config.palette];
    const accent = pressureAccent(palette, config.pressure);
    const panel = mixColor(palette.buildingDark, palette.buildingMid, 0.24);
    const paper = mixColor(palette.paper, accent, 0.06);
    const shapes = [
      svgRect(0, 0, config.width, config.height, panel, 0.92),
      svgRect(16, 16, config.width - 32, config.height - 32, paper, 0.1),
      svgRect(24, 24, config.width - 48, 22, accent, 0.74),
      svgRect(28, 60, config.width - 72, 8, mixColor(palette.paper, palette.buildingMid, 0.22), 0.72),
      svgRect(28, 78, config.width - 88, 6, mixColor(palette.paper, palette.buildingMid, 0.22), 0.54),
      svgRect(28, 94, config.width - 64, 6, mixColor(palette.paper, palette.buildingMid, 0.22), 0.54),
      svgRect(config.width - 88, 54, 44, 44, accent, 0.42)
    ];
    for (let row = 0; row < 10; row += 1) {
      const y = 138 + row * 24;
      shapes.push(svgRect(28, y, config.width - 76, 4, mixColor(palette.paper, palette.buildingMid, 0.22), 0.34));
      if (row % 2 === 0) {
        shapes.push(svgRect(28, y + 8, config.width - 118, 3, mixColor(palette.paper, palette.buildingMid, 0.18), 0.26));
      }
    }
    shapes.push(svgPolygon(diamond(config.width - 60, config.height - 52, 18, 18), accent, 0.58));
    shapes.push(svgPolygon(diamond(config.width - 60, config.height - 52, 8, 8), palette.background, 0.58));
    shapes.push(buildScanlines(config.width, config.height, config.profile));
    return withSvgFrame(config.width, config.height, shapes.join(""));
  }

  function generateAsset(options) {
    const preset = presets[options.preset] || presets.plaza_day1_backdrop;
    const config = {
      preset: options.preset || "plaza_day1_backdrop",
      width: Number(options.width || preset.width),
      height: Number(options.height || preset.height),
      palette: options.palette || preset.palette,
      pressure: options.pressure || preset.pressure,
      profile: options.profile || preset.profile || "production",
      seed: String(options.seed || preset.label || options.preset || "civic-nightmare"),
      variant: options.variant || preset.variant,
      label: preset.label,
      frameCount: Number(options.frameCount || preset.frameCount || 1),
      frame: Number(options.frame || preset.defaultFrame || 1)
    };

    let svg = "";
    switch (config.variant) {
      case "plaza_day1":
      case "plaza_day2":
        svg = buildPlazaScene(config);
        break;
      case "records_chamber":
        svg = buildRecordsChamber(config);
        break;
      case "turnstile_gate":
        svg = buildTurnstileGate(config);
        break;
      case "apartment_interlude":
        svg = buildApartmentScene(config);
        break;
      case "trump_podium_annex":
        svg = buildTrumpPodiumAnnex(config);
        break;
      case "musk_priority_lane":
        svg = buildMuskPriorityLane(config);
        break;
      case "vdl_packet_hall":
        svg = buildVdlPacketHall(config);
        break;
      case "lagarde_housing_office":
        svg = buildLagardeHousingOffice(config);
        break;
      case "citizen_actor":
        svg = buildActorSprite(config, {
          coat: "#dfe8f2",
          accent: pressureAccent(palettes[config.palette], config.pressure),
          hair: "#394655",
          prop: "#5e6e82",
          propShape: "bag",
          torsoWidth: 22,
          shoulderWidth: 20,
          faceStripe: true
        });
        break;
      case "trump_actor":
        svg = buildActorSprite(config, {
          coat: "#5c2a29",
          accent: "#dc9162",
          hair: "#f0c97d",
          prop: "#7d3126",
          propShape: "podium",
          torsoWidth: 26,
          shoulderWidth: 24,
          headRadius: 18
        });
        break;
      case "musk_actor":
        svg = buildActorSprite(config, {
          coat: "#1e3346",
          accent: "#79afd2",
          hair: "#2d3744",
          prop: "#8f9fe0",
          propShape: "scanner",
          torsoWidth: 23,
          shoulderWidth: 20,
          headRadius: 16
        });
        break;
      case "vdl_actor":
        svg = buildActorSprite(config, {
          coat: "#304762",
          accent: "#79afd2",
          hair: "#d4b26a",
          prop: "#9fc0da",
          propShape: "packet",
          torsoWidth: 22,
          shoulderWidth: 20,
          headRadius: 16
        });
        break;
      case "lagarde_actor":
        svg = buildActorSprite(config, {
          coat: "#514033",
          accent: "#dc9162",
          hair: "#d8ddd8",
          prop: "#c98f68",
          propShape: "ledger",
          torsoWidth: 22,
          shoulderWidth: 20,
          headRadius: 16
        });
        break;
      case "records_window_actor":
        svg = buildCheckpointSprite(config, "records");
        break;
      case "home_turnstile_actor":
        svg = buildCheckpointSprite(config, "turnstile");
        break;
      case "plaza_pixel_fx":
        svg = buildPlazaPixelFx(config);
        break;
      case "annex_pixel_fx":
        svg = buildAnnexPixelFx(config);
        break;
      case "transition_pixel_fx":
        svg = buildTransitionPixelFx(config);
        break;
      case "podium_acceptance_fx":
        svg = buildPodiumAcceptanceFx(config);
        break;
      case "scanner_tap_fx":
        svg = buildScannerTapFx(config);
        break;
      case "packet_handoff_fx":
        svg = buildPacketHandoffFx(config);
        break;
      case "ledger_signing_fx":
        svg = buildLedgerSigningFx(config);
        break;
      case "dossier_commit_event_fx":
        svg = buildDossierCommitEventFx(config);
        break;
      case "records_stamp_event_fx":
        svg = buildRecordsStampEventFx(config);
        break;
      case "night_shift_event_fx":
        svg = buildNightShiftEventFx(config);
        break;
      case "turnstile_release_event_fx":
        svg = buildTurnstileReleaseEventFx(config);
        break;
      case "records_poster":
        svg = buildRecordsPoster(config);
        break;
      case "turnstile_sign":
        svg = buildTurnstileSign(config);
        break;
      case "barricade_decal":
        svg = buildBarricadeDecal(config);
        break;
      case "dossier_cluster":
        svg = buildDossierCluster(config);
        break;
      case "checkpoint_stamp":
        svg = buildCheckpointStamp(config);
        break;
      case "agency_seal":
        svg = buildAgencySeal(config);
        break;
      case "queue_floor_arrows":
        svg = buildQueueFloorArrows(config);
        break;
      case "document_overlay":
        svg = buildDocumentOverlay(config);
        break;
      default:
        svg = buildPlazaScene(config);
        break;
    }

    const assetId = options.outputId || config.preset;
    const frameSuffix = options.frame && config.frameCount > 1 ? ` // F${String(config.frame).padStart(2, "0")}` : "";
    const assetLabel = options.outputId ? `${config.label} // ${config.pressure}${frameSuffix}` : config.label;
    return {
      id: assetId,
      label: assetLabel,
      width: config.width,
      height: config.height,
      palette: config.palette,
      pressure: config.pressure,
      profile: config.profile,
      profileLabel: resolveStyleProfile(config.profile).label,
      category: categorizePreset(config.preset, preset),
      seed: config.seed,
      frame: config.frame,
      frameCount: config.frameCount,
      svg
    };
  }

  function generateSequence(options) {
    const preset = presets[options.preset] || presets.plaza_day1_backdrop;
    const frameCount = Number(options.frameCount || preset.frameCount || 1);
    const frames = [];
    for (let frame = 1; frame <= frameCount; frame += 1) {
      frames.push(generateAsset({ ...options, frame, frameCount }));
    }
    return frames;
  }

  function extractSvgBody(svg) {
    const match = String(svg).match(/<svg[^>]*>([\s\S]*)<\/svg>\s*$/i);
    return match ? match[1] : String(svg);
  }

  function buildSpriteSheet(options) {
    const frames = generateSequence(options);
    const firstFrame = frames[0] || generateAsset(options);
    const frameWidth = firstFrame.width;
    const frameHeight = firstFrame.height;
    const columns = Math.max(1, Math.min(Number(options.columns || frames.length || 1), frames.length || 1));
    const rows = Math.max(1, Math.ceil((frames.length || 1) / columns));
    const width = frameWidth * columns;
    const height = frameHeight * rows;
    const body = [];
    const metadataFrames = [];

    frames.forEach((frameAsset, index) => {
      const x = (index % columns) * frameWidth;
      const y = Math.floor(index / columns) * frameHeight;
      body.push(`<g transform="translate(${x} ${y})">${extractSvgBody(frameAsset.svg)}</g>`);
      metadataFrames.push({
        index,
        frame: frameAsset.frame,
        x,
        y,
        width: frameWidth,
        height: frameHeight
      });
    });

    const sheetId = `${options.outputId || firstFrame.id}_sheet`;
    const metadata = {
      id: sheetId,
      label: `${firstFrame.label} // sheet`,
      category: firstFrame.category,
      profile: firstFrame.profile,
      pressure: firstFrame.pressure,
      palette: firstFrame.palette,
      seed: firstFrame.seed,
      frameWidth,
      frameHeight,
      frameCount: frames.length,
      columns,
      rows,
      width,
      height,
      frames: metadataFrames
    };

    return {
      ...metadata,
      svg: withSvgFrame(width, height, body.join("")),
      json: JSON.stringify(metadata, null, 2)
    };
  }

  function listPresets() {
    return presetOrder.map((id) => {
      const preset = presets[id];
      return {
        id,
        ...preset,
        category: categorizePreset(id, preset),
        animated: Number(preset.frameCount || 1) > 1
      };
    });
  }

  function listProfiles() {
    return Object.keys(styleProfiles).map((id) => ({ id, ...styleProfiles[id] }));
  }

  function listPresetCategories() {
    return ["scene", "actor", "checkpoint", "fx", "document"];
  }

  return {
    palettes,
    presets,
    presetOrder,
    styleProfiles,
    listProfiles,
    listPresetCategories,
    listPresets,
    generateAsset,
    generateSequence,
    buildSpriteSheet
  };
});
