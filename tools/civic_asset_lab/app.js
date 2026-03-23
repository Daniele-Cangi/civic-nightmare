(function () {
  const core = window.CivicAssetLab;
  const presetCategorySelect = document.getElementById("presetCategory");
  const presetSelect = document.getElementById("preset");
  const pressureSelect = document.getElementById("pressure");
  const profileSelect = document.getElementById("profile");
  const resolutionInput = document.getElementById("resolution");
  const colorLevelsInput = document.getElementById("colorLevels");
  const ditheringInput = document.getElementById("dithering");
  const animateInput = document.getElementById("animatePreview");
  const seedInput = document.getElementById("seed");
  const statusValue = document.getElementById("statusValue");
  const resolutionValue = document.getElementById("resolutionValue");
  const colorLevelsValue = document.getElementById("colorLevelsValue");
  const canvas = document.getElementById("preview");
  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  const metaBlock = document.getElementById("metaBlock");
  const svgDownload = document.getElementById("downloadSvg");
  const pngDownload = document.getElementById("downloadPng");
  const spritesheetDownload = document.getElementById("downloadSpritesheet");
  const jsonDownload = document.getElementById("downloadJson");
  const renderButton = document.getElementById("renderButton");

  let currentAsset = null;
  let currentFrames = [];
  let currentSheet = null;
  let currentPreset = null;
  let animationTimer = null;
  let frameIndex = 0;

  function applyFloydSteinberg(imageData, width, height, levels) {
    const buffer = new Float32Array(imageData.data);
    const factor = 255 / Math.max(1, levels - 1);
    for (let y = 0; y < height; y += 1) {
      for (let x = 0; x < width; x += 1) {
        const index = (y * width + x) * 4;
        for (let channel = 0; channel < 3; channel += 1) {
          const oldValue = buffer[index + channel];
          const newValue = Math.round(oldValue / factor) * factor;
          const error = oldValue - newValue;
          buffer[index + channel] = newValue;
          if (x + 1 < width) buffer[index + channel + 4] += error * 7 / 16;
          if (y + 1 < height) {
            if (x > 0) buffer[index + channel + (width - 1) * 4] += error * 3 / 16;
            buffer[index + channel + width * 4] += error * 5 / 16;
            if (x + 1 < width) buffer[index + channel + (width + 1) * 4] += error * 1 / 16;
          }
        }
      }
    }
    for (let index = 0; index < imageData.data.length; index += 1) {
      imageData.data[index] = buffer[index];
    }
  }

  function triggerDownload(url, filename) {
    const link = document.createElement("a");
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  function downloadText(content, filename, mimeType) {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    triggerDownload(url, filename);
    URL.revokeObjectURL(url);
  }

  function stopAnimation() {
    if (animationTimer !== null) {
      window.clearInterval(animationTimer);
      animationTimer = null;
    }
  }

  function getSelectedPreset() {
    const presetId = presetSelect.value;
    return core.listPresets().find((entry) => entry.id === presetId) || null;
  }

  function populateProfiles() {
    core.listProfiles().forEach((profile) => {
      const option = document.createElement("option");
      option.value = profile.id;
      option.textContent = profile.label;
      profileSelect.appendChild(option);
    });
    profileSelect.value = "production";
  }

  function populateCategories() {
    const allOption = document.createElement("option");
    allOption.value = "all";
    allOption.textContent = "all";
    presetCategorySelect.appendChild(allOption);
    core.listPresetCategories().forEach((category) => {
      const option = document.createElement("option");
      option.value = category;
      option.textContent = category;
      presetCategorySelect.appendChild(option);
    });
    presetCategorySelect.value = "all";
  }

  function populatePresets() {
    const selectedCategory = presetCategorySelect.value;
    const previousValue = presetSelect.value;
    const presets = core.listPresets().filter((preset) => selectedCategory === "all" || preset.category === selectedCategory);

    presetSelect.innerHTML = "";
    presets.forEach((preset) => {
      const option = document.createElement("option");
      option.value = preset.id;
      const animatedSuffix = preset.animated ? " // anim" : "";
      option.textContent = `${preset.label} // ${preset.category}${animatedSuffix}`;
      presetSelect.appendChild(option);
    });

    if (presets.some((preset) => preset.id === previousValue)) {
      presetSelect.value = previousValue;
    }
  }

  function updateMeta(frameAsset, preset, sheet) {
    const frameMode = frameAsset.frameCount > 1 ? `Frame ${String(frameAsset.frame).padStart(2, "0")} / ${frameAsset.frameCount}` : "Static";
    metaBlock.textContent = [
      `Preset: ${frameAsset.label}`,
      `Category: ${preset.category}`,
      `Profile: ${frameAsset.profileLabel}`,
      `Pressure: ${frameAsset.pressure}`,
      `Seed: ${frameAsset.seed}`,
      `Output: ${frameAsset.width}x${frameAsset.height}`,
      `Preview: ${canvas.width}x${canvas.height}`,
      `Sequence: ${frameMode}`,
      `Sheet: ${sheet.width}x${sheet.height} // ${sheet.columns}x${sheet.rows}`
    ].join("\n");
  }

  function drawSvgOnCanvas(svg, assetWidth, assetHeight) {
    return new Promise((resolve, reject) => {
      const image = new Image();
      image.onload = function onLoad() {
        const resolution = Number(resolutionInput.value);
        const scale = resolution / assetWidth;
        canvas.width = resolution;
        canvas.height = Math.round(assetHeight * scale);
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.imageSmoothingEnabled = false;
        ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
        if (ditheringInput.checked) {
          const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
          applyFloydSteinberg(imageData, canvas.width, canvas.height, Number(colorLevelsInput.value));
          ctx.putImageData(imageData, 0, 0);
        }
        resolve();
      };
      image.onerror = reject;
      image.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
    });
  }

  async function renderFrame(index) {
    if (!currentFrames.length) return;
    frameIndex = index % currentFrames.length;
    currentAsset = currentFrames[frameIndex];
    await drawSvgOnCanvas(currentAsset.svg, currentAsset.width, currentAsset.height);
    updateMeta(currentAsset, currentPreset, currentSheet);
    statusValue.textContent = currentFrames.length > 1 && animateInput.checked ? "ANIMATING" : "RENDERED_OK";
  }

  async function renderAsset() {
    stopAnimation();
    currentPreset = getSelectedPreset();
    if (!currentPreset) return;

    const baseOptions = {
      preset: currentPreset.id,
      pressure: pressureSelect.value,
      profile: profileSelect.value,
      seed: seedInput.value.trim() || `${currentPreset.id}:${pressureSelect.value}:${profileSelect.value}`
    };

    statusValue.textContent = "GENERATING";
    currentFrames = core.generateSequence(baseOptions);
    currentSheet = core.buildSpriteSheet({
      ...baseOptions,
      columns: Math.min(currentFrames.length || 1, 5)
    });

    await renderFrame(0);
    if (animateInput.checked && currentFrames.length > 1) {
      animationTimer = window.setInterval(() => {
        renderFrame((frameIndex + 1) % currentFrames.length);
      }, 180);
    }
  }

  function downloadSvgFile() {
    if (!currentAsset) return;
    downloadText(currentAsset.svg, `${currentAsset.id}.svg`, "image/svg+xml;charset=utf-8");
  }

  function downloadPngFile() {
    if (!currentAsset) return;
    triggerDownload(canvas.toDataURL("image/png"), `${currentAsset.id}.png`);
  }

  function downloadSpritesheetFile() {
    if (!currentSheet) return;
    downloadText(currentSheet.svg, `${currentSheet.id}.svg`, "image/svg+xml;charset=utf-8");
  }

  function downloadJsonFile() {
    if (!currentSheet) return;
    downloadText(currentSheet.json, `${currentSheet.id}.json`, "application/json;charset=utf-8");
  }

  presetCategorySelect.addEventListener("change", () => {
    populatePresets();
    renderAsset();
  });
  presetSelect.addEventListener("change", renderAsset);
  pressureSelect.addEventListener("change", renderAsset);
  profileSelect.addEventListener("change", renderAsset);
  ditheringInput.addEventListener("change", renderAsset);
  animateInput.addEventListener("change", renderAsset);
  resolutionInput.addEventListener("input", () => {
    resolutionValue.textContent = `${resolutionInput.value}px`;
  });
  resolutionInput.addEventListener("change", renderAsset);
  colorLevelsInput.addEventListener("input", () => {
    colorLevelsValue.textContent = `${colorLevelsInput.value} levels`;
  });
  colorLevelsInput.addEventListener("change", renderAsset);
  renderButton.addEventListener("click", renderAsset);
  svgDownload.addEventListener("click", downloadSvgFile);
  pngDownload.addEventListener("click", downloadPngFile);
  spritesheetDownload.addEventListener("click", downloadSpritesheetFile);
  jsonDownload.addEventListener("click", downloadJsonFile);

  populateProfiles();
  populateCategories();
  populatePresets();
  resolutionValue.textContent = `${resolutionInput.value}px`;
  colorLevelsValue.textContent = `${colorLevelsInput.value} levels`;
  renderAsset();
})();
