// Cosmic Fit Inspector — Frontend
"use strict";

import {
  deleteProfile,
  getProfile,
  listProfiles,
  newProfileId,
  putProfile,
  readSession,
  writeSession,
} from "./storage.js";

const ZODIAC_SIGNS = [
  "",
  "Aries",
  "Taurus",
  "Gemini",
  "Cancer",
  "Leo",
  "Virgo",
  "Libra",
  "Scorpio",
  "Sagittarius",
  "Capricorn",
  "Aquarius",
  "Pisces",
];
const ZODIAC_GLYPHS = [
  "",
  "♈",
  "♉",
  "♊",
  "♋",
  "♌",
  "♍",
  "♎",
  "♏",
  "♐",
  "♑",
  "♒",
  "♓",
];

let state = {
  data: null,
  compareCache: {},
  compareDayCount: 2,
  presets: [],
  dailyFitEngines: [],
  serverDefaultEngineId: "production",
  lastBirthFingerprint: null,
};

const COMPARE_MIN_DAYS = 2;
const COMPARE_MAX_DAYS = 14;
const DEFAULT_DEVICE_LOCATION = Object.freeze({
  latitude: 53.91278879084434,
  longitude: -0.1653861958493343,
});
let persistTimer = null;
let restoringSession = false;

function defaultEngineId() {
  return state.serverDefaultEngineId || "production";
}

function currentDailyFitEngineId() {
  return document.getElementById("engine-select")?.value || defaultEngineId();
}

function applyDefaultDeviceLocationIfBlank() {
  const latInput = document.getElementById("device-lat");
  const lonInput = document.getElementById("device-lon");
  if (!latInput || !lonInput) return;

  if (!latInput.value.trim()) {
    latInput.value = String(DEFAULT_DEVICE_LOCATION.latitude);
  }
  if (!lonInput.value.trim()) {
    lonInput.value = String(DEFAULT_DEVICE_LOCATION.longitude);
  }
}

function compareCacheKey(dateISO, engineId = currentDailyFitEngineId()) {
  return `${engineId}:${dateISO}`;
}

function compareEngineAId() {
  return (
    document.getElementById("compare-engine-a")?.value || defaultEngineId()
  );
}

function compareEngineBId() {
  const engines = state.dailyFitEngines || [];
  const fallback = engines.length > 1 ? engines[1].id : defaultEngineId();
  return document.getElementById("compare-engine-b")?.value || fallback;
}

function setSelectValueIfKnown(selectId, value) {
  const sel = document.getElementById(selectId);
  if (!sel || !value) return;
  if ([...sel.options].some((o) => o.value === value)) {
    sel.value = value;
  }
}

function populateCompareEngineSelects() {
  for (const id of ["compare-engine-a", "compare-engine-b"]) {
    const sel = document.getElementById(id);
    if (!sel) continue;
    const prev = sel.value;
    sel.innerHTML = "";
    for (const engine of state.dailyFitEngines) {
      const opt = document.createElement("option");
      opt.value = engine.id;
      opt.textContent = engine.displayName;
      opt.title = engine.summary || "";
      sel.appendChild(opt);
    }
    if (prev && [...sel.options].some((o) => o.value === prev)) {
      sel.value = prev;
    }
  }
  setSelectValueIfKnown("compare-engine-a", defaultEngineId());
  const engines = state.dailyFitEngines || [];
  const secondEngine = engines.find((e) => e.id !== defaultEngineId())?.id;
  if (secondEngine) setSelectValueIfKnown("compare-engine-b", secondEngine);
}

function reconcileCompareCacheWithEngine(engineId) {
  const prefix = `${engineId}:`;
  const keys = Object.keys(state.compareCache);
  if (keys.some((k) => !k.startsWith(prefix))) {
    clearCompareCache();
  }
}

function syncEngineChip() {
  const sel = document.getElementById("engine-select");
  const chip = document.getElementById("engine-chip");
  if (!sel || !chip) return;
  const engineId = currentDailyFitEngineId();
  const meta = state.dailyFitEngines.find((e) => e.id === engineId);
  chip.textContent = engineId;
  chip.classList.toggle("experimental", !!meta?.isExperimental);
  chip.title =
    meta?.summary || "Daily Fit preset (not Style Guide engine version)";
}

// UK calendar dates (dd/mm/yyyy) — API still uses ISO yyyy-mm-dd
function formatDateUK(isoDate) {
  const [y, m, d] = isoDate.split("-");
  if (!y || !m || !d) return "";
  return `${d}/${m}/${y}`;
}

function parseDateUK(text) {
  const raw = (text || "").trim();
  if (!raw) return null;
  const uk = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (uk) {
    const day = parseInt(uk[1], 10);
    const month = parseInt(uk[2], 10);
    const year = parseInt(uk[3], 10);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    const iso = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
    const check = new Date(`${iso}T12:00:00Z`);
    if (
      check.getUTCFullYear() !== year ||
      check.getUTCMonth() + 1 !== month ||
      check.getUTCDate() !== day
    ) {
      return null;
    }
    return iso;
  }
  const iso = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (iso) return raw;
  return null;
}

function setResolvedLocation(result) {
  const label =
    result.label || document.getElementById("location-input").value.trim();
  document.getElementById("location-input").value = label;
  document.getElementById("latitude").value = String(result.latitude);
  document.getElementById("longitude").value = String(result.longitude);
  document.getElementById("latitude").dataset.resolvedLabel = label;
  document.getElementById("timezone-id").value = result.timeZoneId;
  document.getElementById("tz-chip").textContent = result.timeZoneId;
  const chip = document.getElementById("location-coords");
  chip.textContent = `${result.latitude.toFixed(4)}, ${result.longitude.toFixed(4)}`;
  chip.classList.remove("unresolved");
  schedulePersistSession();
}

function clearResolvedLocation() {
  document.getElementById("latitude").value = "";
  document.getElementById("longitude").value = "";
  delete document.getElementById("latitude").dataset.resolvedLabel;
  const chip = document.getElementById("location-coords");
  chip.textContent = "Not resolved — pick a suggestion or Submit to geocode";
  chip.classList.add("unresolved");
  schedulePersistSession();
}

async function resolveBirthLocation() {
  const label = document.getElementById("location-input").value.trim();
  if (!label) throw new Error("Location is required");

  const latEl = document.getElementById("latitude");
  const lat = parseFloat(latEl.value);
  const lon = parseFloat(document.getElementById("longitude").value);
  if (
    latEl.dataset.resolvedLabel === label &&
    Number.isFinite(lat) &&
    Number.isFinite(lon)
  ) {
    return {
      label,
      latitude: lat,
      longitude: lon,
      timeZoneId: document.getElementById("timezone-id").value,
    };
  }

  const res = await fetch(`/api/geocode?q=${encodeURIComponent(label)}`);
  if (!res.ok) throw new Error(`Geocode failed (${res.status})`);
  const data = await res.json();
  if (!data.results?.length) {
    throw new Error(
      `Could not resolve coordinates for "${label}". Pick a location from the suggestions list.`,
    );
  }
  const best = data.results[0];
  setResolvedLocation(best);
  return best;
}

// ── Session persistence ──

function readFormInputs() {
  const latEl = document.getElementById("latitude");
  const lat = parseFloat(latEl.value);
  const lon = parseFloat(document.getElementById("longitude").value);
  return {
    dailyFitEngineId: currentDailyFitEngineId(),
    preset: document.getElementById("preset-select").value,
    birthDate: document.getElementById("birth-date").value,
    birthTime: document.getElementById("birth-time").value || "00:00",
    unknownTime: document.getElementById("unknown-time").checked,
    locationLabel: document.getElementById("location-input").value.trim(),
    latitude: Number.isFinite(lat) ? lat : null,
    longitude: Number.isFinite(lon) ? lon : null,
    timezoneId: document.getElementById("timezone-id").value,
    resolvedLocationLabel: latEl.dataset.resolvedLabel || "",
    targetDate: document.getElementById("target-date").value,
    compareToggle: document.getElementById("compare-toggle").checked,
    compareDayCount: getCompareDayCount(),
    compareEnginesToggle: document.getElementById("compare-engines-toggle")
      .checked,
    compareEngineAId: compareEngineAId(),
    compareEngineBId: compareEngineBId(),
    activeProfileId:
      document.getElementById("saved-profile-select").value || "",
    profileId: document.getElementById("profile-id").value.trim() || "",
    deviceLat: document.getElementById("device-lat").value.trim() || "",
    deviceLon: document.getElementById("device-lon").value.trim() || "",
  };
}

function applyFormInputs(
  inputs,
  { persist = true, skipProfileSelect = false } = {},
) {
  if (!inputs) return;
  restoringSession = true;

  document.getElementById("preset-select").value = inputs.preset || "custom";
  if (inputs.dailyFitEngineId) {
    const engineSel = document.getElementById("engine-select");
    if (
      [...engineSel.options].some((o) => o.value === inputs.dailyFitEngineId)
    ) {
      engineSel.value = inputs.dailyFitEngineId;
    }
  }
  syncEngineChip();
  document.getElementById("birth-date").value = inputs.birthDate || "";
  document.getElementById("birth-time").value = inputs.birthTime || "00:00";
  document.getElementById("unknown-time").checked = !!inputs.unknownTime;
  document.getElementById("target-date").value = inputs.targetDate || "";
  document.getElementById("compare-toggle").checked = !!inputs.compareToggle;
  state.compareDayCount = clampCompareDayCount(
    inputs.compareDayCount ?? COMPARE_MIN_DAYS,
  );
  syncCompareDaysUI();
  document.getElementById("compare-engines-toggle").checked =
    !!inputs.compareEnginesToggle;
  setSelectValueIfKnown("compare-engine-a", inputs.compareEngineAId);
  setSelectValueIfKnown("compare-engine-b", inputs.compareEngineBId);
  syncCompareEnginesUI();

  if (
    inputs.locationLabel &&
    Number.isFinite(inputs.latitude) &&
    Number.isFinite(inputs.longitude)
  ) {
    setResolvedLocation({
      label: inputs.locationLabel,
      latitude: inputs.latitude,
      longitude: inputs.longitude,
      timeZoneId: inputs.timezoneId || "UTC",
    });
    if (inputs.resolvedLocationLabel) {
      document.getElementById("latitude").dataset.resolvedLabel =
        inputs.resolvedLocationLabel;
    }
  } else if (inputs.locationLabel) {
    document.getElementById("location-input").value = inputs.locationLabel;
    clearResolvedLocation();
  }

  document.getElementById("profile-id").value = inputs.profileId || "";
  document.getElementById("device-lat").value = inputs.deviceLat || "";
  document.getElementById("device-lon").value = inputs.deviceLon || "";

  if (!skipProfileSelect) {
    const sel = document.getElementById("saved-profile-select");
    const profileId = inputs.activeProfileId || "";
    if (profileId && [...sel.options].some((o) => o.value === profileId)) {
      sel.value = profileId;
    } else {
      sel.value = "";
    }
  }

  syncSavedProfileControlsFromSelection();
  restoringSession = false;
  if (persist) schedulePersistSession();
}

function schedulePersistSession() {
  if (restoringSession) return;
  clearTimeout(persistTimer);
  persistTimer = setTimeout(() => {
    writeSession({ inputs: readFormInputs(), savedAt: Date.now() });
  }, 200);
}

async function restoreSession() {
  const session = readSession();
  if (session?.inputs) {
    let inputs = { ...session.inputs };
    const knownIds = new Set((state.dailyFitEngines || []).map((e) => e.id));
    const defaultId = defaultEngineId();
    if (inputs.dailyFitEngineId && !knownIds.has(inputs.dailyFitEngineId)) {
      inputs.dailyFitEngineId = defaultId;
      document.getElementById("status-indicator").textContent =
        `Unknown engine id in saved session; using ${defaultId}`;
      writeSession({ inputs, savedAt: session.savedAt ?? Date.now() });
    } else if (!inputs.dailyFitEngineId) {
      inputs.dailyFitEngineId = defaultId;
    }
    if (inputs.compareEngineAId && !knownIds.has(inputs.compareEngineAId)) {
      inputs.compareEngineAId = defaultId;
    }
    if (inputs.compareEngineBId && !knownIds.has(inputs.compareEngineBId)) {
      const fallbackB =
        (state.dailyFitEngines || []).find((e) => e.id !== defaultId)?.id ||
        defaultId;
      inputs.compareEngineBId = fallbackB;
    }
    applyFormInputs(inputs, { persist: false, skipProfileSelect: true });
    applyDefaultDeviceLocationIfBlank();
    reconcileCompareCacheWithEngine(inputs.dailyFitEngineId || defaultId);
    const sel = document.getElementById("saved-profile-select");
    const profileId = session.inputs.activeProfileId || "";
    if (profileId && [...sel.options].some((o) => o.value === profileId)) {
      sel.value = profileId;
    }
    await syncSavedProfileControlsFromSelection();
    return;
  }

  const locLabel = document.getElementById("location-input").value.trim();
  if (locLabel) {
    document.getElementById("latitude").dataset.resolvedLabel = locLabel;
  }
  if (!document.getElementById("target-date").value) {
    setTodayUTC();
  }
  applyDefaultDeviceLocationIfBlank();
}

function clearSavedProfileSelection() {
  document.getElementById("saved-profile-select").value = "";
  updateSavedProfileControls();
  schedulePersistSession();
}

function savedProfileNameInput() {
  return document.getElementById("saved-profile-name");
}

function updateSavedProfileControls(selectedProfile = null) {
  const id = document.getElementById("saved-profile-select").value;
  const hasSelection = !!id;
  document.getElementById("delete-profile-btn").disabled = !hasSelection;
  document.getElementById("rename-profile-btn").disabled = !hasSelection;

  const nameInput = savedProfileNameInput();
  nameInput.disabled = !hasSelection;
  if (!hasSelection) {
    nameInput.value = "";
    return;
  }

  if (selectedProfile) {
    nameInput.value = selectedProfile.name || "";
  }
}

function profileNameFromLabelInput(fallbackName) {
  const label = savedProfileNameInput().value.trim();
  return label || fallbackName;
}

function isCustomProfileName(name, displayName) {
  return !!name && name !== displayName;
}

async function syncSavedProfileControlsFromSelection() {
  const id = document.getElementById("saved-profile-select").value;
  if (!id) {
    updateSavedProfileControls();
    return;
  }
  const profile = await getProfile(id);
  updateSavedProfileControls(profile);
}

async function refreshSavedProfilesSelect(selectedId = null) {
  const sel = document.getElementById("saved-profile-select");
  const profiles = await listProfiles();
  const current = selectedId ?? sel.value;
  sel.innerHTML = '<option value="">—</option>';
  for (const p of profiles) {
    const opt = document.createElement("option");
    opt.value = p.id;
    opt.textContent = p.name;
    sel.appendChild(opt);
  }
  if (current && profiles.some((p) => p.id === current)) {
    sel.value = current;
  } else if (!selectedId) {
    sel.value = "";
  }
  const active = profiles.find((p) => p.id === sel.value) || null;
  updateSavedProfileControls(active);
}

async function onSavedProfileChange() {
  const id = document.getElementById("saved-profile-select").value;
  if (!id) {
    schedulePersistSession();
    updateSavedProfileControls();
    return;
  }
  const profile = await getProfile(id);
  if (!profile?.inputs) {
    updateSavedProfileControls(profile);
    return;
  }
  updateSavedProfileControls(profile);
  applyFormInputs({
    ...profile.inputs,
    preset: "custom",
    activeProfileId: id,
  });
}

function birthFingerprintFromRequest(body) {
  const b = body.birth;
  return `${b.birthDate}|${b.birthTime}|${b.latitude}|${b.longitude}|${b.timeZoneId}|${b.unknownTime}`;
}

async function syncSavedProfileNameAfterSubmit() {
  const activeId = document.getElementById("saved-profile-select").value;
  if (!activeId || !state.data?.profile?.displayName) return;

  const profile = await getProfile(activeId);
  if (!profile) return;

  const displayName = state.data.profile.displayName;
  const inputs = readFormInputs();
  inputs.activeProfileId = activeId;
  inputs.preset = "custom";

  const inputsUnchanged =
    profile.inputs?.birthDate === inputs.birthDate &&
    (profile.inputs?.profileId || "") === (inputs.profileId || "");
  if (inputsUnchanged && (profile.customName || profile.name === displayName)) {
    return;
  }

  if (!profile.customName) {
    profile.name = displayName;
  }
  profile.updatedAt = Date.now();
  profile.inputs = inputs;
  await putProfile(profile);
  await refreshSavedProfilesSelect(activeId);
}

async function saveCurrentProfile() {
  const inputs = readFormInputs();
  if (!inputs.birthDate || !inputs.locationLabel) {
    showError("Enter birth date and location before saving a profile.");
    return;
  }
  hideError();

  let body;
  try {
    await resolveBirthLocation();
    body = buildRequest();
  } catch (e) {
    showError(e.message);
    return;
  }

  const birthFp = birthFingerprintFromRequest(body);
  if (!state.data || state.lastBirthFingerprint !== birthFp) {
    showError(
      "Submit first — the saved profile name matches the engine-generated display name.",
    );
    return;
  }

  const displayName = state.data.profile.displayName;
  const name = profileNameFromLabelInput(displayName);
  const customName = isCustomProfileName(name, displayName);
  const profiles = await listProfiles();
  const activeId = document.getElementById("saved-profile-select").value;
  const existingByName = profiles.find((p) => p.name === name);
  const existingById = activeId
    ? profiles.find((p) => p.id === activeId)
    : null;
  const now = Date.now();

  let profile;
  if (existingById) {
    profile = {
      ...existingById,
      name,
      customName: customName || existingById.customName,
      updatedAt: now,
      inputs: { ...inputs, preset: "custom", activeProfileId: existingById.id },
    };
  } else if (existingByName) {
    profile = {
      ...existingByName,
      name,
      customName: customName || existingByName.customName,
      updatedAt: now,
      inputs: {
        ...inputs,
        preset: "custom",
        activeProfileId: existingByName.id,
      },
    };
  } else {
    profile = {
      id: newProfileId(),
      name,
      customName,
      createdAt: now,
      updatedAt: now,
      inputs: { ...inputs, preset: "custom", activeProfileId: "" },
    };
    profile.inputs.activeProfileId = profile.id;
  }

  await putProfile(profile);
  await refreshSavedProfilesSelect(profile.id);
  document.getElementById("saved-profile-select").value = profile.id;
  updateSavedProfileControls(profile);
  schedulePersistSession();
  document.getElementById("status-indicator").textContent =
    `Saved profile “${name}”`;
}

async function renameSelectedProfile() {
  const id = document.getElementById("saved-profile-select").value;
  const name = savedProfileNameInput().value.trim();
  if (!id) return;
  if (!name) {
    showError("Enter a profile label before renaming.");
    return;
  }
  hideError();

  const profile = await getProfile(id);
  if (!profile) return;

  const displayName = state.data?.profile?.displayName || profile.name;
  profile.name = name;
  profile.customName = isCustomProfileName(name, displayName);
  profile.updatedAt = Date.now();
  await putProfile(profile);
  await refreshSavedProfilesSelect(id);
  document.getElementById("status-indicator").textContent =
    `Renamed profile to “${name}”`;
}

async function deleteSelectedProfile() {
  const id = document.getElementById("saved-profile-select").value;
  if (!id) return;
  const profile = await getProfile(id);
  await deleteProfile(id);
  document.getElementById("saved-profile-select").value = "";
  await refreshSavedProfilesSelect("");
  schedulePersistSession();
  document.getElementById("status-indicator").textContent =
    `Deleted profile “${profile?.name || "profile"}”`;
}

// ── Init ──

document.addEventListener("DOMContentLoaded", async () => {
  await loadPresets();
  await loadDailyFitEngines();
  populateCompareEngineSelects();
  await refreshSavedProfilesSelect();
  wireEvents();
  syncCompareDaysUI();
  syncCompareEnginesUI();
  await restoreSession();
});

function setTodayUTC() {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(now.getUTCDate()).padStart(2, "0");
  document.getElementById("target-date").value = formatDateUK(
    `${yyyy}-${mm}-${dd}`,
  );
  schedulePersistSession();
}

async function loadDailyFitEngines() {
  try {
    const [healthRes, enginesRes] = await Promise.all([
      fetch("/api/health"),
      fetch("/api/daily-fit-engines"),
    ]);
    if (healthRes.ok) {
      const health = await healthRes.json();
      state.serverDefaultEngineId =
        health.dailyFitEngineDefault || state.serverDefaultEngineId;
      state.buildStamp = health.buildStamp || null;
      const stampEl = document.getElementById("build-stamp");
      if (stampEl && state.buildStamp) {
        stampEl.textContent = "Built: " + state.buildStamp;
        stampEl.title = "Inspector binary build timestamp";
      }
    }
    state.dailyFitEngines = enginesRes.ok ? await enginesRes.json() : [];
    const sel = document.getElementById("engine-select");
    sel.innerHTML = "";
    for (const engine of state.dailyFitEngines) {
      const opt = document.createElement("option");
      opt.value = engine.id;
      opt.textContent = engine.displayName;
      opt.title = engine.summary || "";
      sel.appendChild(opt);
    }
    if (!sel.value) {
      sel.value = defaultEngineId();
    }
    syncEngineChip();
    populateCompareEngineSelects();
  } catch (e) {
    console.warn("Failed to load daily fit engines", e);
  }
}

async function loadPresets() {
  try {
    const res = await fetch("/api/presets");
    state.presets = await res.json();
    const sel = document.getElementById("preset-select");
    for (const p of state.presets) {
      const opt = document.createElement("option");
      opt.value = p.id;
      opt.textContent = `${p.label}`;
      sel.appendChild(opt);
    }
  } catch (e) {
    console.warn("Failed to load presets", e);
  }
}

function wireEvents() {
  document
    .getElementById("submit-btn")
    .addEventListener("click", () => doSubmit(false));
  document
    .getElementById("engine-select")
    .addEventListener("change", () => onEngineChange());
  document.getElementById("today-btn").addEventListener("click", () => {
    setTodayUTC();
    if (state.data) doSubmit(true);
  });
  document.getElementById("preset-select").addEventListener("change", () => {
    applyPreset();
    schedulePersistSession();
  });
  document
    .getElementById("saved-profile-select")
    .addEventListener("change", onSavedProfileChange);
  document
    .getElementById("save-profile-btn")
    .addEventListener("click", saveCurrentProfile);
  document
    .getElementById("rename-profile-btn")
    .addEventListener("click", renameSelectedProfile);
  document
    .getElementById("delete-profile-btn")
    .addEventListener("click", deleteSelectedProfile);
  savedProfileNameInput().addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !savedProfileNameInput().disabled) {
      e.preventDefault();
      renameSelectedProfile();
    }
  });
  document.getElementById("compare-toggle").addEventListener("change", () => {
    onCompareToggle();
    schedulePersistSession();
  });
  document.getElementById("compare-days-down").addEventListener("click", () => {
    onCompareDayCountChange(-1);
  });
  document.getElementById("compare-days-up").addEventListener("click", () => {
    onCompareDayCountChange(1);
  });
  document
    .getElementById("compare-engines-toggle")
    .addEventListener("change", () => {
      onCompareEnginesToggle();
      schedulePersistSession();
    });
  document.getElementById("compare-engine-a").addEventListener("change", () => {
    onCompareEnginePairChange();
    schedulePersistSession();
  });
  document.getElementById("compare-engine-b").addEventListener("change", () => {
    onCompareEnginePairChange();
    schedulePersistSession();
  });
  document
    .getElementById("drawer-close")
    .addEventListener("click", closeDrawer);
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeDrawer();
  });
  document.addEventListener("click", (e) => {
    if (!document.body.classList.contains("drawer-open")) return;
    const drawer = document.getElementById("drill-drawer");
    if (
      drawer &&
      !drawer.contains(e.target) &&
      !e.target.closest("[data-drill]")
    ) {
      closeDrawer();
    }
  });
  document.getElementById("target-date").addEventListener("change", () => {
    schedulePersistSession();
    if (state.data) doSubmit(true);
  });
  document.getElementById("birth-time").addEventListener("change", () => {
    document.getElementById("preset-select").value = "custom";
    clearSavedProfileSelection();
    schedulePersistSession();
  });
  document.getElementById("unknown-time").addEventListener("change", () => {
    document.getElementById("preset-select").value = "custom";
    clearSavedProfileSelection();
    schedulePersistSession();
  });

  document.querySelectorAll(".card-header").forEach((h) => {
    h.addEventListener("click", (e) => {
      if (e.target.closest(".export-btn")) return;
      const bodyId = h.dataset.toggle;
      const body = document.getElementById(bodyId);
      if (body) body.classList.toggle("collapsed");
      const icon = h.querySelector(".toggle-icon");
      if (icon)
        icon.textContent = body.classList.contains("collapsed") ? "▶" : "▼";
    });
  });

  document.querySelectorAll("[data-export]").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      exportSection(btn.dataset.export);
    });
  });

  // Location autocomplete
  let debounce;
  const locInput = document.getElementById("location-input");
  const locResults = document.getElementById("location-results");
  locInput.addEventListener("input", () => {
    clearTimeout(debounce);
    debounce = setTimeout(async () => {
      const q = locInput.value.trim();
      if (q.length < 3) {
        locResults.classList.remove("visible");
        return;
      }
      try {
        const res = await fetch(`/api/geocode?q=${encodeURIComponent(q)}`);
        const data = await res.json();
        locResults.innerHTML = "";
        if (data.results && data.results.length > 0) {
          for (const r of data.results) {
            const div = document.createElement("div");
            div.className = "result-item";
            div.textContent = r.label;
            div.addEventListener("click", () => {
              setResolvedLocation(r);
              locResults.classList.remove("visible");
              document.getElementById("preset-select").value = "custom";
              clearSavedProfileSelection();
            });
            locResults.appendChild(div);
          }
          locResults.classList.add("visible");
        } else {
          locResults.classList.remove("visible");
        }
      } catch (e) {
        locResults.classList.remove("visible");
      }
    }, 300);
  });

  document.addEventListener("click", (e) => {
    if (!e.target.closest(".location-group"))
      locResults.classList.remove("visible");
  });

  locInput.addEventListener("input", () => {
    document.getElementById("preset-select").value = "custom";
    clearSavedProfileSelection();
    clearResolvedLocation();
  });

  for (const id of ["birth-date", "birth-time"]) {
    document.getElementById(id).addEventListener("input", () => {
      document.getElementById("preset-select").value = "custom";
      clearSavedProfileSelection();
      schedulePersistSession();
    });
  }
  document
    .getElementById("target-date")
    .addEventListener("input", schedulePersistSession);

  document.getElementById("profile-id").addEventListener("input", () => {
    schedulePersistSession();
  });
}

function applyPreset() {
  const sel = document.getElementById("preset-select");
  const preset = state.presets.find((p) => p.id === sel.value);
  if (!preset) return;

  const bd = preset.birthDateUTC.slice(0, 10);
  const bt = preset.birthDateUTC.slice(11, 16);
  document.getElementById("birth-date").value = formatDateUK(bd);
  document.getElementById("birth-time").value = bt;
  document.getElementById("unknown-time").checked = false;
  setResolvedLocation({
    label: preset.label,
    latitude: preset.latitude,
    longitude: preset.longitude,
    timeZoneId: preset.timeZoneId,
  });
  clearSavedProfileSelection();
}

async function onEngineChange() {
  syncEngineChip();
  schedulePersistSession();
  const hadData = !!state.data;
  clearCompareCache();
  state.data = null;
  updateExportButtons();
  if (hadData) {
    await doSubmit(false);
  }
}

// ── Submit ──

async function doSubmit(dateOnly = false) {
  const btn = document.getElementById("submit-btn");
  btn.disabled = true;
  showLoading(true);
  hideError();

  let body;
  try {
    await resolveBirthLocation();
    body = buildRequest();
  } catch (e) {
    showError(e.message);
    btn.disabled = false;
    showLoading(false);
    return;
  }

  const birthFp = birthFingerprintFromRequest(body);
  const isDateOnlyChange = dateOnly && state.lastBirthFingerprint === birthFp;
  const birthChanged =
    state.lastBirthFingerprint !== null &&
    state.lastBirthFingerprint !== birthFp;
  if (isDateOnlyChange) {
    body.options.composeBlueprint = false;
  }
  if (birthChanged) {
    body.options.resetTarotHistory = true;
  }
  const birthYear = parseInt(body.birth.birthDate.slice(0, 4), 10);
  const targetYear = parseInt(body.targetDate.slice(0, 4), 10);
  const targetAge = targetYear - birthYear;
  if (targetAge > 50) {
    document.getElementById("status-indicator").textContent =
      `⚠️ targetAge=${targetAge} (>50) — progressed chart accuracy may degrade`;
  }

  try {
    const t0 = performance.now();
    const res = await fetch("/api/inspect", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`${res.status}: ${text}`);
    }
    state.data = await res.json();
    state.lastBirthFingerprint = birthFp;
    clearCompareCache();
    const elapsed = ((performance.now() - t0) / 1000).toFixed(2);
    const mode = isDateOnlyChange ? "date-only" : "full";
    document.getElementById("status-indicator").textContent =
      `Computed in ${elapsed}s (${mode})`;
    render(state.data);
    schedulePersistSession();
    await syncSavedProfileNameAfterSubmit();

    if (document.getElementById("compare-engines-toggle").checked) {
      await loadEngineCompare();
    } else if (document.getElementById("compare-toggle").checked) {
      await loadCompareRange();
    }
  } catch (e) {
    showError(e.message);
  } finally {
    btn.disabled = false;
    showLoading(false);
  }
}

function buildRequest({
  composeBlueprint = true,
  resetTarotHistory = false,
} = {}) {
  applyDefaultDeviceLocationIfBlank();

  const birthDateISO = parseDateUK(document.getElementById("birth-date").value);
  if (!birthDateISO) {
    throw new Error("Birth date must be dd/mm/yyyy (e.g. 11/12/1984)");
  }
  const targetDateISO = parseDateUK(
    document.getElementById("target-date").value,
  );
  if (!targetDateISO) {
    throw new Error("Daily Fit target date must be dd/mm/yyyy");
  }

  const time = document.getElementById("birth-time").value || "00:00";
  const unknownTime = document.getElementById("unknown-time").checked;

  const latitude = parseFloat(document.getElementById("latitude").value);
  const longitude = parseFloat(document.getElementById("longitude").value);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new Error(
      "Location coordinates are missing — pick a suggestion or Submit to geocode",
    );
  }

  const profileIdValue = document.getElementById("profile-id").value.trim() || null;

  const deviceLatStr = document.getElementById("device-lat").value.trim();
  const deviceLonStr = document.getElementById("device-lon").value.trim();
  const deviceLatitude = deviceLatStr ? parseFloat(deviceLatStr) : null;
  const deviceLongitude = deviceLonStr ? parseFloat(deviceLonStr) : null;

  return {
    preset: document.getElementById("preset-select").value,
    birth: {
      birthDate: birthDateISO,
      birthTime: unknownTime ? null : time,
      unknownTime,
      latitude,
      longitude,
      timeZoneId: document.getElementById("timezone-id").value,
      locationLabel: document.getElementById("location-input").value.trim(),
    },
    targetDate: targetDateISO,
    options: {
      composeBlueprint,
      includeProgressed: true,
      resetTarotHistory,
      profileId: profileIdValue,
      dailyFitEngineId: currentDailyFitEngineId(),
      deviceLatitude: Number.isFinite(deviceLatitude) ? deviceLatitude : null,
      deviceLongitude: Number.isFinite(deviceLongitude) ? deviceLongitude : null,
    },
  };
}

// ── Compare ──

function clampCompareDayCount(n) {
  return Math.min(
    COMPARE_MAX_DAYS,
    Math.max(COMPARE_MIN_DAYS, Number(n) || COMPARE_MIN_DAYS),
  );
}

function getCompareDayCount() {
  return clampCompareDayCount(state.compareDayCount);
}

function syncCompareDaysUI() {
  const toggle = document.getElementById("compare-toggle");
  const controls = document.getElementById("compare-span-controls");
  const valueEl = document.getElementById("compare-days-value");
  const count = getCompareDayCount();
  state.compareDayCount = count;
  if (valueEl) valueEl.textContent = String(count);
  if (controls) controls.classList.toggle("hidden", !toggle?.checked);
  const down = document.getElementById("compare-days-down");
  const up = document.getElementById("compare-days-up");
  if (down) down.disabled = count <= COMPARE_MIN_DAYS;
  if (up) up.disabled = count >= COMPARE_MAX_DAYS;
}

function syncCompareEnginesUI() {
  const toggle = document.getElementById("compare-engines-toggle");
  const controls = document.getElementById("compare-engines-controls");
  if (controls) controls.classList.toggle("hidden", !toggle?.checked);
}

function clearCompareCache() {
  state.compareCache = {};
}

function targetDateISO() {
  return parseDateUK(document.getElementById("target-date").value);
}

function offsetDateISO(baseISO, dayOffset) {
  const d = new Date(`${baseISO}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + dayOffset);
  return d.toISOString().slice(0, 10);
}

function getCompareDateRange() {
  const target = targetDateISO();
  if (!target) return [];
  const count = getCompareDayCount();
  const dates = [];
  for (let i = 0; i < count; i += 1) {
    dates.push(offsetDateISO(target, i));
  }
  return dates;
}

function compareActive() {
  if (document.getElementById("compare-engines-toggle")?.checked) return false;
  if (!document.getElementById("compare-toggle").checked || !state.data)
    return false;
  const range = getCompareDateRange();
  if (range.length < 2) return false;
  return range
    .slice(1)
    .every((iso) => !!state.compareCache[compareCacheKey(iso)]);
}

function engineCompareActive() {
  if (
    !document.getElementById("compare-engines-toggle")?.checked ||
    !state.data
  )
    return false;
  const target = targetDateISO();
  if (!target) return false;
  const engineA = compareEngineAId();
  const engineB = compareEngineBId();
  if (!engineA || !engineB || engineA === engineB) return false;
  return (
    !!inspectDataForEngine(engineA, target) &&
    !!inspectDataForEngine(engineB, target)
  );
}

function inspectDataForEngine(engineId, dateISO = targetDateISO()) {
  if (!dateISO) return null;
  if (engineId === currentDailyFitEngineId() && state.data) {
    const metaEngine = state.data.meta?.dailyFitEngineId;
    if (!metaEngine || metaEngine === engineId) return state.data;
  }
  return state.compareCache[compareCacheKey(dateISO, engineId)] || null;
}

function inspectDataForCompareDate(iso) {
  const target = targetDateISO();
  if (iso === target) return state.data;
  return state.compareCache[compareCacheKey(iso)] || null;
}

function compareCarouselHtml(paneHtmlFns) {
  const dates = getCompareDateRange();
  let html =
    '<div class="compare-split" role="region" aria-label="Day compare carousel">';
  paneHtmlFns.forEach((paneHtmlFn, i) => {
    const iso = dates[i];
    const label = formatDateUK(iso);
    const engineId = currentDailyFitEngineId();
    const isTarget = i === 0;
    const paneCls = isTarget
      ? "compare-pane compare-pane-target"
      : "compare-pane compare-pane-forward";
    const prefix = isTarget ? "Target · " : "";
    html += `<div class="${paneCls}" data-date-iso="${esc(iso)}" data-engine-id="${esc(engineId)}">
      <div class="compare-pane-label">${prefix}${esc(label)} UTC · ${esc(engineId)}</div>
      <div class="compare-pane-content">${paneHtmlFn()}</div>
    </div>`;
  });
  html += "</div>";
  return html;
}

function compareEnginesSplitHtml(panes) {
  const target = targetDateISO();
  const label = formatDateUK(target);
  let html =
    '<div class="compare-split compare-split-engines" role="region" aria-label="Engine compare">';
  for (const pane of panes) {
    html += `<div class="compare-pane compare-pane-engine" data-date-iso="${esc(target)}" data-engine-id="${esc(pane.engineId)}">
      <div class="compare-pane-label">${esc(label)} UTC · ${esc(pane.engineId)}</div>
      <div class="compare-pane-content">${pane.html()}</div>
    </div>`;
  }
  html += "</div>";
  return html;
}

function mountCompareSection(
  bodyId,
  { buildPanes, buildEngineComparePanes = null, staticNote = null },
) {
  const el = document.getElementById(bodyId);
  const panes = buildPanes();
  const targetPaneHtml = panes[0]?.html ?? (() => "");

  if (staticNote && (compareActive() || engineCompareActive())) {
    el.innerHTML = `<p class="compare-static-note">${staticNote}</p>${targetPaneHtml()}`;
  } else if (engineCompareActive() && buildEngineComparePanes) {
    const enginePanes = buildEngineComparePanes();
    el.innerHTML = compareEnginesSplitHtml(enginePanes);
  } else if (compareActive() && panes.length > 1) {
    el.innerHTML = compareCarouselHtml(panes.map((p) => p.html));
    const carousel = el.querySelector(".compare-split");
    if (carousel) carousel.scrollLeft = 0;
  } else {
    el.innerHTML = targetPaneHtml();
  }
  postRenderSection(el);
}

function updateCompareStatus() {
  if (!compareActive()) return;
  const dates = getCompareDateRange();
  if (dates.length < 2) return;
  const first = formatDateUK(dates[0]);
  const last = formatDateUK(dates[dates.length - 1]);
  const count = dates.length;
  const engineId = currentDailyFitEngineId();
  document.getElementById("status-indicator").textContent =
    count === 2
      ? `Compare: ${first} vs ${last} (UTC) · ${engineId}`
      : `Compare: ${first} → ${last} (${count} days, UTC) · ${engineId}`;
}

async function fetchInspectForDate(dateISO) {
  return fetchInspectForEngine(dateISO, currentDailyFitEngineId());
}

async function fetchInspectForEngine(dateISO, engineId) {
  const body = buildRequest({ composeBlueprint: false });
  body.targetDate = dateISO;
  body.options.dailyFitEngineId = engineId;
  const res = await fetch("/api/inspect", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json();
}

function disableCompareEnginesMode() {
  const toggle = document.getElementById("compare-engines-toggle");
  if (toggle) toggle.checked = false;
  syncCompareEnginesUI();
}

function disableCompareDaysMode() {
  const toggle = document.getElementById("compare-toggle");
  if (toggle) toggle.checked = false;
  syncCompareDaysUI();
}

async function onCompareToggle() {
  syncCompareDaysUI();
  if (document.getElementById("compare-toggle").checked) {
    disableCompareEnginesMode();
    if (!state.data) {
      showError("Submit first, then enable compare.");
      document.getElementById("compare-toggle").checked = false;
      syncCompareDaysUI();
      return;
    }
    hideError();
    await loadCompareRange();
  } else {
    clearCompareCache();
    hideError();
    if (state.data) renderAllSections(state.data);
  }
}

async function onCompareEnginesToggle() {
  syncCompareEnginesUI();
  if (document.getElementById("compare-engines-toggle").checked) {
    disableCompareDaysMode();
    if (!state.data) {
      showError("Submit first, then enable engine compare.");
      document.getElementById("compare-engines-toggle").checked = false;
      syncCompareEnginesUI();
      return;
    }
    hideError();
    await loadEngineCompare();
  } else {
    clearCompareCache();
    hideError();
    if (state.data) renderAllSections(state.data);
  }
}

async function onCompareEnginePairChange() {
  if (!document.getElementById("compare-engines-toggle").checked || !state.data)
    return;
  const engineA = compareEngineAId();
  const engineB = compareEngineBId();
  if (engineA === engineB) {
    showError("Pick two different engines to compare.");
    return;
  }
  hideError();
  await loadEngineCompare();
}

async function onCompareDayCountChange(delta) {
  const next = clampCompareDayCount(getCompareDayCount() + delta);
  if (next === getCompareDayCount()) return;
  state.compareDayCount = next;
  syncCompareDaysUI();
  schedulePersistSession();
  if (document.getElementById("compare-toggle").checked && state.data) {
    await loadCompareRange();
  }
}

async function loadCompareRange() {
  const target = targetDateISO();
  if (!target) {
    showError("Set a Daily Fit target date before comparing.");
    document.getElementById("compare-toggle").checked = false;
    syncCompareDaysUI();
    return false;
  }
  if (!state.data) return false;

  const dates = getCompareDateRange();
  const toFetch = dates
    .slice(1)
    .filter((iso) => !state.compareCache[compareCacheKey(iso)]);

  if (toFetch.length === 0) {
    if (state.data) {
      renderAllSections(state.data);
      updateCompareStatus();
    }
    return true;
  }

  try {
    await resolveBirthLocation();
  } catch (e) {
    showError(`Compare failed: ${e.message}`);
    document.getElementById("compare-toggle").checked = false;
    syncCompareDaysUI();
    return false;
  }

  showLoading(true);
  try {
    // Chronological order so TarotRecencyTracker sees prior days in this batch
    // (matches opening the app once per UTC day).
    for (const iso of toFetch) {
      const data = await fetchInspectForDate(iso);
      state.compareCache[compareCacheKey(iso)] = data;
    }
    if (state.data) {
      renderAllSections(state.data);
      updateCompareStatus();
    }
    return true;
  } catch (e) {
    clearCompareCache();
    showError(`Compare failed: ${e.message}`);
    document.getElementById("compare-toggle").checked = false;
    syncCompareDaysUI();
    if (state.data) renderAllSections(state.data);
    return false;
  } finally {
    showLoading(false);
  }
}

async function loadEngineCompare() {
  const target = targetDateISO();
  if (!target) {
    showError("Set a Daily Fit target date before comparing engines.");
    document.getElementById("compare-engines-toggle").checked = false;
    syncCompareEnginesUI();
    return false;
  }
  if (!state.data) return false;

  const engineA = compareEngineAId();
  const engineB = compareEngineBId();
  if (engineA === engineB) {
    showError("Pick two different engines to compare.");
    document.getElementById("compare-engines-toggle").checked = false;
    syncCompareEnginesUI();
    return false;
  }

  const toFetch = [];
  if (!inspectDataForEngine(engineA, target))
    toFetch.push({ iso: target, engineId: engineA });
  if (!inspectDataForEngine(engineB, target))
    toFetch.push({ iso: target, engineId: engineB });

  if (toFetch.length === 0) {
    if (state.data) {
      renderAllSections(state.data);
      updateEngineCompareStatus();
    }
    return true;
  }

  try {
    await resolveBirthLocation();
  } catch (e) {
    showError(`Engine compare failed: ${e.message}`);
    document.getElementById("compare-engines-toggle").checked = false;
    syncCompareEnginesUI();
    return false;
  }

  showLoading(true);
  try {
    for (const { iso, engineId } of toFetch) {
      const data = await fetchInspectForEngine(iso, engineId);
      state.compareCache[compareCacheKey(iso, engineId)] = data;
    }
    if (state.data) {
      renderAllSections(state.data);
      updateEngineCompareStatus();
    }
    return true;
  } catch (e) {
    clearCompareCache();
    showError(`Engine compare failed: ${e.message}`);
    document.getElementById("compare-engines-toggle").checked = false;
    syncCompareEnginesUI();
    if (state.data) renderAllSections(state.data);
    return false;
  } finally {
    showLoading(false);
  }
}

function updateEngineCompareStatus() {
  if (!engineCompareActive()) return;
  const target = formatDateUK(targetDateISO());
  const engineA = compareEngineAId();
  const engineB = compareEngineBId();
  document.getElementById("status-indicator").textContent =
    `Engine compare: ${target} UTC · ${engineA} vs ${engineB}`;
}

let activeDrillNode = null;

function postRenderSection(root) {
  root.querySelectorAll("[data-drill]").forEach((node) => {
    node.addEventListener("click", (e) => {
      e.stopPropagation();
      if (!node.dataset.drill) return;
      if (activeDrillNode) activeDrillNode.classList.remove("drill-active");
      activeDrillNode = node;
      node.classList.add("drill-active");
      openDrill(node.dataset.drill, resolveDrillContext(node));
    });
  });
  root.querySelectorAll(".accordion-header").forEach((h) => {
    h.addEventListener("click", () =>
      h.nextElementSibling.classList.toggle("open"),
    );
  });
}

// ── Render ──

function render(data) {
  renderAllSections(data);
}

function renderAllSections(data) {
  document.getElementById("display-name").textContent =
    data.profile.displayName;
  renderNatal(data.natal);
  renderBlueprint(data.blueprint);
  renderDailyFit(data.dailyFit);
  renderTrace(data.dailyFit.diagnostics);
  renderVerdicts(data.verdicts);
  updateExportButtons();
}

function buildNatalHtml(natal) {
  if (!natal) return '<p class="text-muted">No natal chart data.</p>';
  let html =
    '<table class="data-table"><thead><tr><th>Planet</th><th>Sign</th><th>Longitude</th><th>Position</th><th>Retro</th></tr></thead><tbody>';
  for (const p of natal.planets) {
    const sign = ZODIAC_SIGNS[p.zodiacSign] || "?";
    const glyph = ZODIAC_GLYPHS[p.zodiacSign] || "";
    html += `<tr>
      <td>${p.symbol} ${p.name}</td>
      <td>${glyph} ${sign}</td>
      <td>${p.longitude.toFixed(4)}</td>
      <td>${p.zodiacPosition}</td>
      <td>${p.isRetrograde ? "℞" : ""}</td>
    </tr>`;
  }
  html += "</tbody></table>";

  html +=
    '<div class="subsection"><div class="subsection-title">Angles &amp; Points</div>';
  html += `<table class="data-table"><tbody>
    <tr><td>Ascendant</td><td>${natal.ascendant.toFixed(4)}° ${signFromDeg(natal.ascendant)}</td></tr>
    <tr><td>Midheaven (MC)</td><td>${natal.midheaven.toFixed(4)}° ${signFromDeg(natal.midheaven)}</td></tr>
    <tr><td>Descendant</td><td>${natal.descendant.toFixed(4)}°</td></tr>
    <tr><td>IC</td><td>${natal.imumCoeli.toFixed(4)}°</td></tr>
    <tr><td>North Node</td><td>${natal.northNode.toFixed(4)}°</td></tr>
    <tr><td>Lunar Phase</td><td>${natal.lunarPhase.toFixed(2)}°</td></tr>
  </tbody></table></div>`;

  html +=
    '<div class="subsection"><div class="subsection-title">House Cusps (Placidus)</div>';
  html += '<div class="tag-list">';
  natal.houseCusps.forEach((c, i) => {
    html += `<span class="tag">H${i + 1}: ${c.toFixed(1)}°</span>`;
  });
  html += "</div></div>";
  return html;
}

function buildComparePanes(renderForData) {
  if (!compareActive()) {
    return [{ html: () => renderForData(state.data, true) }];
  }
  const range = getCompareDateRange();
  return range.map((iso) => {
    const data = inspectDataForCompareDate(iso);
    return { html: () => renderForData(data, !!data) };
  });
}

function buildEngineComparePanes(renderForData) {
  if (!engineCompareActive()) {
    return [{ html: () => renderForData(state.data, true) }];
  }
  const engineA = compareEngineAId();
  const engineB = compareEngineBId();
  return [engineA, engineB].map((engineId) => {
    const data = inspectDataForEngine(engineId);
    return {
      engineId,
      html: () => renderForData(data, !!data),
    };
  });
}

function renderNatal(natal) {
  mountCompareSection("natal-body", {
    staticNote: "Natal chart is unchanged day-to-day — shown once below.",
    buildPanes: () => [{ html: () => buildNatalHtml(natal) }],
  });
}

function buildBlueprintHtml(bp) {
  if (!bp) return '<p class="text-muted">No blueprint computed.</p>';

  let html = "";

  // Style Core
  if (bp.styleCore?.narrativeText) {
    html += `<div class="subsection"><div class="subsection-title">Style Core</div>
      <p class="narrative-text">${esc(bp.styleCore.narrativeText)}</p></div>`;
  }

  // Palette
  html += '<div class="subsection"><div class="subsection-title">Palette</div>';
  const bands = [
    ["Neutrals", bp.palette?.neutrals],
    ["Core", bp.palette?.coreColours],
    ["Accents", bp.palette?.accentColours],
    ["Support", bp.palette?.supportColours],
  ];
  for (const [label, colours] of bands) {
    if (colours && colours.length > 0) {
      html += `<div style="margin:8px 0"><strong style="font-size:11px;color:var(--text-muted)">${label}</strong>`;
      html += '<div class="swatch-row">';
      for (const c of colours) {
        html += `<div class="swatch">
          <div class="swatch-color drillable" style="background:${c.hexValue}" title="${c.name} (${c.hexValue})" data-drill="blueprint-colour:${c.name}"></div>
          <span class="swatch-name">${esc(c.name)}</span>
          <span class="swatch-hex">${c.hexValue}</span>
        </div>`;
      }
      html += "</div></div>";
    }
  }

  // Anchors and signatures
  const special = [
    ["Light Anchor", bp.palette?.lightAnchor],
    ["Deep Anchor", bp.palette?.deepAnchor],
    ["Luminary Sig", bp.palette?.luminarySignature],
    ["Ruler Sig", bp.palette?.rulerSignature],
  ];
  html += '<div style="display:flex;gap:12px;margin-top:8px;flex-wrap:wrap">';
  for (const [label, c] of special) {
    if (c) {
      html += `<div class="swatch"><div class="swatch-color drillable" style="background:${c.hexValue}" title="${c.name}" data-drill="blueprint-colour:${c.name}"></div>
        <span class="swatch-name">${label}</span><span class="swatch-hex">${c.hexValue}</span></div>`;
    }
  }
  html += "</div></div>";

  if (bp.palette?.family || bp.palette?.cluster) {
    html += '<div class="subsection"><div class="subsection-title">Palette Engine</div><div class="tag-list">';
    if (bp.palette.family)
      html += `<span class="tag drillable" data-drill="blueprint-meta:family">${esc(String(bp.palette.family))}</span>`;
    if (bp.palette.cluster)
      html += `<span class="tag drillable" data-drill="blueprint-meta:cluster">${esc(String(bp.palette.cluster))}</span>`;
    if (bp.palette.secondaryPull)
      html += `<span class="tag drillable" data-drill="blueprint-meta:secondaryPull">Pull: ${esc(String(bp.palette.secondaryPull))}</span>`;
    html += "</div></div>";
  }

  // Textures
  if (bp.textures) {
    html +=
      '<div class="subsection"><div class="subsection-title">Textures</div>';
    if (bp.textures.recommendedTextures?.length)
      html += `<div><strong>Recommended:</strong> <div class="tag-list">${bp.textures.recommendedTextures.map((t) => `<span class="tag drillable" data-drill="blueprint-texture:${esc(t)}">${esc(t)}</span>`).join("")}</div></div>`;
    if (bp.textures.avoidTextures?.length)
      html += `<div style="margin-top:6px"><strong>Avoid:</strong> <div class="tag-list">${bp.textures.avoidTextures.map((t) => `<span class="tag drillable" data-drill="blueprint-texture:${esc(t)}">${esc(t)}</span>`).join("")}</div></div>`;
    if (bp.textures.goodText)
      html += `<p class="narrative-text" style="margin-top:6px">${esc(bp.textures.goodText)}</p>`;
    html += "</div>";
  }

  // Hardware
  if (bp.hardware) {
    html +=
      '<div class="subsection"><div class="subsection-title">Hardware</div>';
    if (bp.hardware.recommendedMetals?.length)
      html += `<div class="tag-list">${bp.hardware.recommendedMetals.map((m) => `<span class="tag">${esc(m)}</span>`).join("")}</div>`;
    if (bp.hardware.recommendedStones?.length)
      html += `<div class="tag-list" style="margin-top:4px">${bp.hardware.recommendedStones.map((s) => `<span class="tag">${esc(s)}</span>`).join("")}</div>`;
    if (bp.hardware.metalsText)
      html += `<p class="narrative-text" style="margin-top:6px">${esc(bp.hardware.metalsText)}</p>`;
    html += "</div>";
  }

  // Code
  if (bp.code) {
    html +=
      '<div class="subsection"><div class="subsection-title">Style Code</div>';
    if (bp.code.leanInto?.length)
      html += `<div><strong>Lean Into:</strong> <div class="tag-list">${bp.code.leanInto.map((c) => `<span class="tag">${esc(c)}</span>`).join("")}</div></div>`;
    if (bp.code.avoid?.length)
      html += `<div style="margin-top:4px"><strong>Avoid:</strong> <div class="tag-list">${bp.code.avoid.map((c) => `<span class="tag">${esc(c)}</span>`).join("")}</div></div>`;
    if (bp.code.consider?.length)
      html += `<div style="margin-top:4px"><strong>Consider:</strong> <div class="tag-list">${bp.code.consider.map((c) => `<span class="tag">${esc(c)}</span>`).join("")}</div></div>`;
    html += "</div>";
  }

  // Pattern
  if (bp.pattern) {
    html +=
      '<div class="subsection"><div class="subsection-title">Patterns</div>';
    if (bp.pattern.recommendedPatterns?.length)
      html += `<div class="tag-list">${bp.pattern.recommendedPatterns.map((p) => `<span class="tag drillable" data-drill="blueprint-pattern:${esc(p)}">${esc(p)}</span>`).join("")}</div>`;
    if (bp.pattern.narrativeText)
      html += `<p class="narrative-text" style="margin-top:6px">${esc(bp.pattern.narrativeText)}</p>`;
    html += "</div>";
  }

  // Occasions
  if (bp.occasions) {
    html +=
      '<div class="subsection"><div class="subsection-title">Occasions</div>';
    if (bp.occasions.workText)
      html += `<p class="narrative-text"><strong>Work:</strong> ${esc(bp.occasions.workText)}</p>`;
    if (bp.occasions.intimateText)
      html += `<p class="narrative-text"><strong>Intimate:</strong> ${esc(bp.occasions.intimateText)}</p>`;
    if (bp.occasions.dailyText)
      html += `<p class="narrative-text"><strong>Daily:</strong> ${esc(bp.occasions.dailyText)}</p>`;
    html += "</div>";
  }

  return html;
}

function renderBlueprint(bp) {
  mountCompareSection("blueprint-body", {
    staticNote: "Style Guide is frozen per profile — unchanged day-to-day.",
    buildPanes: () => [{ html: () => buildBlueprintHtml(bp) }],
  });
}

function buildDailyFitHtml(df, allowDrill = true) {
  if (!df?.payload) return '<p class="text-muted">No Daily Fit data.</p>';
  const p = df.payload;
  const drill = allowDrill ? "drillable" : "";
  let html = "";

  // Tarot
  html += `<div class="subsection"><div class="subsection-title">Tarot Card</div>
    <span class="${drill}" data-drill="tarot">${esc(p.tarotCard?.name || "Unknown")}</span></div>`;

  // Style Edit
  if (p.styleEditVariant) {
    html += `<div class="subsection"><div class="subsection-title">Style Edit</div>
      <strong class="${drill}" data-drill="styleEdit">${esc(p.styleEditVariant.title || "")}</strong>`;
    if (p.styleEditVariant.dailyRitual)
      html += `<p class="narrative-text">${esc(p.styleEditVariant.dailyRitual)}</p>`;
    if (p.styleEditVariant.wardrobeReflection)
      html += `<p class="narrative-text" style="margin-top:4px"><em>${esc(p.styleEditVariant.wardrobeReflection)}</em></p>`;
    html += "</div>";
  }

  // Daily Palette
  html +=
    '<div class="subsection"><div class="subsection-title">Daily Palette</div><div class="swatch-row">';
  for (const c of p.dailyPalette?.colours || []) {
    html += `<div class="swatch">
      <div class="swatch-color ${drill}" style="background:${c.hexValue}" data-drill="colour:${c.name}"></div>
      <span class="swatch-name">${esc(c.name)}</span>
      <span class="swatch-hex">${c.hexValue}</span>
      <span class="swatch-name">${c.role}</span>
    </div>`;
  }
  html += "</div></div>";

  // Scale bars
  html += '<div class="subsection"><div class="subsection-title">Scales</div>';
  html += scaleBar("Vibrancy", p.vibrancy, allowDrill ? "vibrancy" : null);
  html += scaleBar("Contrast", p.contrast, allowDrill ? "contrast" : null);
  html += scaleBar(
    "Metal Tone",
    p.metalTone,
    allowDrill ? "metalTone" : null,
    "Cool",
    "Warm",
  );
  html += "</div>";

  // Essence (all 14 categories; top 3 highlighted)
  html += buildEssenceProfileHtml(p.essenceProfile, allowDrill);

  // Essence conflict resolution trace (Stage 1 only)
  const ect = df.diagnostics?.essenceConflictTrace;
  if (ect?.suppressions?.length) {
    html += '<div class="subsection" style="border-left:3px solid var(--warn,#c9a227);padding-left:8px">';
    html += '<div class="subsection-title">Essence Conflict Resolution</div>';
    for (const s of ect.suppressions) {
      html += `<p style="margin:4px 0"><strong>${esc(s.suppressedCategory.toUpperCase())}</strong> (score ${(s.suppressedScore * 100).toFixed(1)}%) suppressed — conflicts with <strong>${esc(s.keptCategory.toUpperCase())}</strong>`;
      if (s.replacementCategory) {
        html += ` → promoted <strong>${esc(s.replacementCategory.toUpperCase())}</strong> (score ${((s.replacementScore || 0) * 100).toFixed(1)}%)`;
      }
      html += `</p>`;
    }
    html += '</div>';
  }

  // Silhouette
  if (p.silhouetteProfile) {
    html +=
      '<div class="subsection"><div class="subsection-title">Silhouette Profile</div>';
    html += scaleBar(
      "M / F",
      p.silhouetteProfile.masculineFeminine,
      allowDrill ? "silhouette:mf" : null,
      "Masculine",
      "Feminine",
    );
    html += scaleBar(
      "A / R",
      p.silhouetteProfile.angularRounded,
      allowDrill ? "silhouette:ar" : null,
      "Angular",
      "Rounded",
    );
    html += scaleBar(
      "S / D",
      p.silhouetteProfile.structuredDraped,
      allowDrill ? "silhouette:sd" : null,
      "Structured",
      "Relaxed",
    );
    html += "</div>";
  }

  // Vibe Breakdown (6 energies)
  html += buildVibeBreakdownHtml(p.vibeBreakdown, allowDrill);

  // Textures & Pattern
  if (p.dailyTextures?.length) {
    html += `<div class="subsection"><div class="subsection-title">Daily Textures</div><div class="tag-list">${p.dailyTextures.map((t) => `<span class="tag ${drill}" data-drill="texture:${esc(t)}">${esc(t)}</span>`).join("")}</div></div>`;
  }
  if (p.dailyPattern) {
    html += `<div class="subsection"><div class="subsection-title">Daily Pattern</div><span class="tag ${drill}" data-drill="pattern">${esc(p.dailyPattern)}</span></div>`;
  }

  // Transits
  if (p.dominantTransits?.length) {
    html +=
      '<div class="subsection"><div class="subsection-title">Dominant Transits</div>';
    html +=
      '<table class="data-table"><thead><tr><th>Transit</th><th>Natal</th><th>Aspect</th><th>Strength</th></tr></thead><tbody>';
    for (const t of p.dominantTransits) {
      html += `<tr class="${drill}" data-drill="transit:${t.transitPlanet}"><td>${esc(t.transitPlanet)}</td><td>${esc(t.natalPlanet)}</td><td>${esc(t.aspect)}</td><td>${(t.strength * 100).toFixed(0)}%</td></tr>`;
    }
    html += "</tbody></table></div>";
  }

  // Lunar
  if (p.lunarContext) {
    html += `<div class="subsection"><div class="subsection-title">Lunar Context</div>
      <span class="tag ${drill}" data-drill="lunar">${esc(p.lunarContext.phaseName)}</span>
      <span class="tag ${drill}" data-drill="lunar">${p.lunarContext.isWaxing ? "Waxing" : "Waning"}</span>
      <span class="tag ${drill}" data-drill="lunar">${esc(p.lunarContext.element)}</span>
      <span class="tag ${drill}" data-drill="lunar">${p.lunarContext.phaseDegrees.toFixed(1)}°</span></div>`;
  }

  return html;
}

function renderDailyFit(df) {
  mountCompareSection("dailyfit-body", {
    buildPanes: () =>
      buildComparePanes((data, allowDrill) =>
        buildDailyFitHtml(data?.dailyFit, allowDrill),
      ),
    buildEngineComparePanes: () =>
      buildEngineComparePanes((data, allowDrill) =>
        buildDailyFitHtml(data?.dailyFit, allowDrill),
      ),
  });
}

function buildTraceHtml(diag, blueprintDiag = null) {
  if (!diag && !blueprintDiag) return "<p>No diagnostics available.</p>";

  let html = "";

  html += buildBlueprintDiagnosticsAccordion(blueprintDiag);

  if (!diag) return html;

  // Source Contributions
  html += accordion("Source Contributions", () => {
    const sc = diag.sourceContributions;
    return `<table class="data-table"><tbody>
      <tr><td>Natal</td><td>${(sc.natalShare * 100).toFixed(1)}%</td></tr>
      <tr><td>Transits</td><td>${(sc.transitShare * 100).toFixed(1)}%</td></tr>
      <tr><td>Lunar</td><td>${(sc.lunarShare * 100).toFixed(1)}%</td></tr>
      <tr><td>Progressed</td><td>${(sc.progressedShare * 100).toFixed(1)}%</td></tr>
      <tr><td>Current Sun</td><td>${(sc.currentSunShare * 100).toFixed(1)}%</td></tr>
    </tbody></table>`;
  });

  // Energy Scores
  html += accordion("Raw Energy Scores", () => kv(diag.rawEnergyScores));
  html += accordion(postMultiplierScoresLabel(diag), () =>
    kv(diag.postMultiplierScores),
  );
  html += accordion("Raw Axis Scores", () => kv(diag.rawAxisScores));

  // Stage 1 Attribution (Phase 3)
  if (diag.stage1Attribution?.byEnergy?.length) {
    html += accordion("Stage 1 · Per-input Energy Attribution", () => {
      const attr = diag.stage1Attribution;
      let t = `<p style="margin-bottom:8px">Engine mode: <strong>${esc(attr.engineMode)}</strong></p>`;
      for (const bd of attr.byEnergy) {
        t += `<details style="margin:6px 0"><summary><strong>${esc(vibeEnergyDisplayName(bd.energy))}</strong> — raw: ${Number(bd.totalRaw).toFixed(4)}, ${esc(postMultiplierShortLabel(diag))}: ${Number(bd.totalPostMultiplier).toFixed(4)}</summary>`;
        t += renderEnergyAttributionTable(bd, null, diag);
        t += "</details>";
      }
      const mults = attr.signMultiplierApplied;
      const appliedToDaily = attr.signMultipliersAppliedToDailyVibe !== false;
      if (mults && Object.keys(mults).length) {
        const multTitle = appliedToDaily
          ? "Sun-sign multipliers"
          : "Sun-sign multipliers (not applied to daily vibe)";
        t += `<details style="margin:6px 0"><summary><strong>${multTitle}</strong></summary>`;
        if (!appliedToDaily) {
          t += '<p style="font-size:0.85em;margin:4px 0">Daily sky payload skips natal Sun signEnergyMap. Chart anchor still uses multipliers when policy enables it.</p>';
        }
        t += '<table class="data-table"><thead><tr><th>Energy</th><th>Multiplier</th></tr></thead><tbody>';
        for (const [k, v] of Object.entries(mults).sort((a, b) => b[1] - a[1])) {
          t += `<tr><td>${esc(vibeEnergyDisplayName(k))}</td><td>${Number(v).toFixed(3)}</td></tr>`;
        }
        t += "</tbody></table></details>";
      }
      t += renderChartAnchorMultipliersTable(attr.chartAnchorSignMultiplierApplied);
      return t;
    });
  }

  if (diag.stage1AxisAttribution?.byAxis?.length) {
    html += accordion("Stage 1 · Per-input Axis Attribution", () => {
      const attr = diag.stage1AxisAttribution;
      let t = `<p style="margin-bottom:8px">Engine mode: <strong>${esc(attr.engineMode)}</strong> · sigmoid spread: ${Number(attr.sigmoidSpread).toFixed(2)}</p>`;
      for (const bd of attr.byAxis) {
        const name = AXIS_DISPLAY_NAMES[bd.axis] || bd.axis;
        t += `<details style="margin:6px 0"><summary><strong>${esc(name)}</strong> — raw: ${Number(bd.rawScore).toFixed(4)}, final: ${Number(bd.finalAxisValue).toFixed(2)}</summary>`;
        t += renderAxisAttributionTable(bd);
        t += "</details>";
      }
      return t;
    });
  }

  // Tarot Scores
  html += accordion("Tarot Card Scores (Top 15)", () => {
    const sorted = [...(diag.tarotCardScores || [])]
      .sort((a, b) => b.totalScore - a.totalScore)
      .slice(0, 15);
    let t =
      '<table class="data-table"><thead><tr><th>Card</th><th>Vibe</th><th>Axis</th><th>Transit</th><th>Recency</th><th>Total</th></tr></thead><tbody>';
    for (const s of sorted) {
      const isSelected = s.cardName === diag.selectedTarotCard;
      t += `<tr${isSelected ? ' style="background:rgba(124,111,247,0.1)"' : ""}>
        <td>${esc(s.cardName)}${isSelected ? " ★" : ""}</td>
        <td>${s.vibeScore.toFixed(3)}</td><td>${s.axisScore.toFixed(3)}</td>
        <td>${s.transitBoost.toFixed(3)}</td><td>${s.recencyPenalty.toFixed(3)}</td>
        <td><strong>${s.totalScore.toFixed(3)}</strong></td></tr>`;
    }
    t += "</tbody></table>";
    return t;
  });

  // Palette Trace
  html += accordion("Palette Selection Trace", () => {
    const pt = diag.paletteSelectionTrace;
    if (!pt) return "N/A";
    let t = `<p>Strategy: <strong>${pt.selectionStrategy || "dramaSlots"}</strong> | Candidates: ${pt.candidateCount} | Diversity swap: ${pt.diversitySwapApplied ? "Yes" : "No"}${pt.coreAnchorSwapApplied ? " | Core anchor swap: Yes" : ""}</p>`;
    t +=
      '<table class="data-table"><thead><tr><th>Colour</th><th>Role</th><th>Score</th></tr></thead><tbody>';
    for (const c of pt.topScoredColours || []) {
      t += `<tr><td>${esc(c.name)}</td><td>${c.role}</td><td>${c.score.toFixed(4)}</td></tr>`;
    }
    t += "</tbody></table>";
    return t;
  });

  // Texture Trace
  html += accordion("Texture Trace", () => {
    const tt = diag.textureSelectionTrace;
    if (!tt) return "N/A";
    let t =
      '<table class="data-table"><thead><tr><th>Texture</th><th>Score</th></tr></thead><tbody>';
    for (const s of tt.scores || []) {
      t += `<tr><td>${esc(s.name)}</td><td>${s.score.toFixed(4)}</td></tr>`;
    }
    t += "</tbody></table>";
    return t;
  });

  // Pattern
  html += accordion("Pattern Decision", () => {
    const pd = diag.patternDecision;
    if (!pd) return "N/A";
    return `<table class="data-table"><tbody>
      <tr><td>Gate passed</td><td>${pd.gateCheckPassed ? "Yes" : "No"}</td></tr>
      <tr><td>Visibility</td><td>${pd.visibilityValue.toFixed(3)}</td></tr>
      <tr><td>Dominant energy</td><td>${esc(pd.dominantEnergy)}</td></tr>
      <tr><td>Selected</td><td>${pd.selectedPattern || "None"}</td></tr>
    </tbody></table>`;
  });

  // Scale Traces
  html += accordion("Scale Derivation Traces", () => {
    let t = "";
    for (const [label, trace, envKey] of [
      ["Vibrancy", diag.vibrancyTrace, "vibrancy"],
      ["Contrast", diag.contrastTrace, "contrast"],
      ["Metal Tone", diag.metalToneTrace, "metalTone"],
    ]) {
      if (trace) {
        t += `<div style="margin:6px 0"><strong>${label}:</strong> baseline=${trace.blueprintBaseline.toFixed(3)}, modulation=${trace.modulation.toFixed(3)}, final=${trace.finalValue.toFixed(3)}`;
        const env = diag.personalScalePresentation?.[envKey];
        if (env) {
          t += ` | <em>personal:</em> floor=${env.floor.toFixed(3)}, ceiling=${env.ceiling.toFixed(3)}, display=${env.displayPosition.toFixed(3)}, baselineTick=${env.baselinePosition.toFixed(3)}`;
        }
        t += `</div>`;
      }
    }
    return t;
  });

  // Calibration
  html += accordion("Calibration Snapshot", () =>
    formatCalibrationSnapshotHtml(diag.calibrationSnapshot),
  );

  // Full JSON
  html += accordion(
    "Full Diagnostic JSON",
    () => `<pre class="json-block">${esc(JSON.stringify(diag, null, 2))}</pre>`,
  );
  return html;
}

function renderTrace(diag) {
  mountCompareSection("trace-body", {
    buildPanes: () =>
      buildComparePanes((data, _allowDrill) =>
        buildTraceHtml(data?.dailyFit?.diagnostics, data?.blueprintDiagnostics),
      ),
    buildEngineComparePanes: () =>
      buildEngineComparePanes((data, _allowDrill) =>
        buildTraceHtml(data?.dailyFit?.diagnostics, data?.blueprintDiagnostics),
      ),
  });
}

function buildVerdictsHtml(verdicts) {
  if (!verdicts?.length) return "<p>No verdicts.</p>";
  let html = "";
  for (const v of verdicts) {
    const icon =
      v.status === "pass" ? "✅" : v.status === "partial" ? "⚠️" : "❌";
    const cls = `verdict-status-${v.status}`;
    html += `<div class="verdict-row">
      <span class="verdict-icon">${icon}</span>
      <span class="verdict-id ${cls}">${esc(v.id)}</span>
      <span class="verdict-detail">Expected: ${esc(v.expected)} | Actual: ${esc(v.actual)}</span>
    </div>`;
  }
  return html;
}

function renderVerdicts(verdicts) {
  mountCompareSection("verdict-body", {
    buildPanes: () =>
      buildComparePanes((data, _allowDrill) =>
        buildVerdictsHtml(data?.verdicts),
      ),
    buildEngineComparePanes: () =>
      buildEngineComparePanes((data, _allowDrill) =>
        buildVerdictsHtml(data?.verdicts),
      ),
  });
}

// ── Drill-down Drawer ──

function resolveDrillContext(clickNode) {
  const pane = clickNode?.closest?.(".compare-pane");
  const dateISO = pane?.dataset?.dateIso || targetDateISO();
  const engineId = pane?.dataset?.engineId || currentDailyFitEngineId();
  let data = state.data;
  if (dateISO !== targetDateISO() || engineId !== currentDailyFitEngineId()) {
    data = inspectDataForEngine(engineId, dateISO) || state.data;
  }
  return { data, dateISO, engineId };
}

function renderDerivationTimeline(steps) {
  return steps
    .map(
      (step, i) => `<div class="derivation-step">
      <div class="derivation-step-header">
        <span class="derivation-step-num">${step.number ?? i + 1}</span>
        <span class="derivation-step-title">${esc(step.title)}</span>
      </div>
      ${step.description ? `<p class="derivation-step-desc">${esc(step.description)}</p>` : ""}
      <div class="derivation-step-body">${step.body}</div>
    </div>`,
    )
    .join("");
}

function renderDrillMeta(ctx) {
  if (!ctx?.dateISO) return "";
  return `<p class="drill-meta">${esc(formatDateUK(ctx.dateISO))} UTC · ${esc(ctx.engineId || currentDailyFitEngineId())}</p>`;
}

function renderSourceContributionsTable(sc) {
  if (!sc) return "<p>No source contribution data.</p>";
  return `<table class="data-table"><tbody>
    <tr><td>Natal chart</td><td>${pct(sc.natalShare)}</td></tr>
    <tr><td>Transits</td><td>${pct(sc.transitShare)}</td></tr>
    <tr><td>Lunar</td><td>${pct(sc.lunarShare)}</td></tr>
    <tr><td>Progressed</td><td>${pct(sc.progressedShare)}</td></tr>
    <tr><td>Current Sun</td><td>${pct(sc.currentSunShare)}</td></tr>
  </tbody></table>`;
}

function renderEnergyScoresTable(scores, highlightKey = null) {
  if (!scores) return "<p>No energy scores.</p>";
  let html = '<table class="data-table"><thead><tr><th>Energy</th><th>Score</th></tr></thead><tbody>';
  for (const [k, v] of Object.entries(scores).sort((a, b) => b[1] - a[1])) {
    const hi = highlightKey && k === highlightKey ? ' style="background:rgba(124,111,247,0.15)"' : "";
    html += `<tr${hi}><td>${esc(k)}</td><td>${Number(v).toFixed(4)}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

// ── Phase 3: Per-input energy attribution helpers ──

const ESSENCE_ENERGY_MAP = {
  edgy: ["edge", "drama"],
  romantic: ["romantic", "classic"],
  classic: ["classic", "utility"],
  utility: ["utility", "classic"],
  drama: ["drama", "edge"],
  playful: ["playful", "drama"],
  polished: ["classic", "utility"],
  effortless: ["playful", "utility"],
  sensual: ["romantic", "drama"],
  magnetic: ["drama", "romantic"],
  grounded: ["utility", "classic"],
  eclectic: ["playful", "edge"],
  minimal: ["utility", "classic"],
  maximalist: ["drama", "playful"],
};

function renderEnergyAttributionTable(breakdown, highlightEnergy = null, diag = null) {
  if (!breakdown?.entries?.length)
    return "<p>No per-input attribution data available.</p>";

  const entries = breakdown.entries.slice(0, 15);
  let html =
    '<table class="data-table"><thead><tr><th>Source</th><th>Input</th><th>Raw</th><th>Weighted</th></tr></thead><tbody>';
  for (const e of entries) {
    const hi =
      highlightEnergy && e.energy === highlightEnergy
        ? ' style="background:rgba(124,111,247,0.12)"'
        : "";
    html += `<tr${hi}><td>${esc(e.source)}</td><td>${esc(e.label)}</td><td>${Number(e.rawContribution).toFixed(4)}</td><td>${Number(e.weightedContribution).toFixed(4)}</td></tr>`;
  }
  html += "</tbody></table>";

  if (breakdown.totalRaw != null) {
    const secondLabel = diag ? postMultiplierShortLabel(diag) : "Post-multiplier";
    html += `<p style="margin-top:4px;font-size:0.85em">Total raw: ${Number(breakdown.totalRaw).toFixed(4)} · ${esc(secondLabel)}: ${Number(breakdown.totalPostMultiplier).toFixed(4)}</p>`;
  }
  return html;
}

function renderEnergyAttributionForTransit(attribution, transitPlanet) {
  if (!attribution?.byEnergy) return "<p>No attribution data.</p>";

  const rows = [];
  for (const bd of attribution.byEnergy) {
    const matching = (bd.entries || []).filter(
      (e) => e.source === "transit" && e.label.startsWith(transitPlanet + " "),
    );
    const total = matching.reduce((s, e) => s + e.weightedContribution, 0);
    if (total !== 0 || matching.length > 0) {
      rows.push({ energy: bd.energy, total, entries: matching });
    }
  }

  if (!rows.length) return `<p>No transit entries found for ${esc(transitPlanet)}.</p>`;

  rows.sort((a, b) => Math.abs(b.total) - Math.abs(a.total));

  let html =
    '<table class="data-table"><thead><tr><th>Energy</th><th>Contribution</th><th>Details</th></tr></thead><tbody>';
  for (const r of rows) {
    const details = r.entries
      .map((e) => `${esc(e.label)}: ${Number(e.weightedContribution).toFixed(4)}`)
      .join("<br>");
    html += `<tr><td>${esc(vibeEnergyDisplayName(r.energy))}</td><td><strong>${Number(r.total).toFixed(4)}</strong></td><td style="font-size:0.85em">${details || "—"}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

// Silhouette / scale axes: which Stage 1 axis drives each slider.
const SILHOUETTE_AXIS_CONFIG = {
  mf: {
    label: "Masculine / Feminine",
    drivingAxis: "visibility",
    semantic:
      "How visible or expressive the day's energy feels — higher visibility nudges toward feminine presentation (softer, more seen).",
    stage1Formula: (axisVal) =>
      `0.5 + tanh((${axisVal} − 5.5) / 4.5) × 0.45`,
  },
  ar: {
    label: "Angular / Rounded",
    drivingAxis: "action",
    semantic:
      "Pace and forward drive — higher action nudges toward angular, sharp silhouettes.",
    stage1Formula: (axisVal) =>
      `0.5 + tanh((${axisVal} − 5.5) / 4.5) × 0.45`,
  },
  sd: {
    label: "Structured / Relaxed",
    drivingAxis: "strategy",
    semantic:
      "Planning vs flow — higher strategy nudges toward structured, tailored lines.",
    stage1Formula: (axisVal) =>
      `0.5 + tanh((${axisVal} − 5.5) / 4.5) × 0.45`,
  },
};

const AXIS_DISPLAY_NAMES = {
  action: "Action",
  tempo: "Tempo",
  strategy: "Strategy",
  visibility: "Visibility",
};

function renderAxisAttributionTable(breakdown, maxRows = 15) {
  if (!breakdown?.entries?.length) {
    return "<p>No per-input axis attribution data available.</p>";
  }
  const entries = breakdown.entries.slice(0, maxRows);
  let html =
    '<table class="data-table"><thead><tr><th>Source</th><th>Input</th><th>Contribution</th></tr></thead><tbody>';
  for (const e of entries) {
    html += `<tr><td>${esc(e.source)}</td><td>${esc(e.label)}</td><td>${Number(e.contribution).toFixed(4)}</td></tr>`;
  }
  html += "</tbody></table>";
  html += `<p style="margin-top:4px;font-size:0.85em">Raw axis score (pre-sigmoid): <strong>${Number(breakdown.rawScore).toFixed(4)}</strong> → final axis (1–10): <strong>${Number(breakdown.finalAxisValue).toFixed(2)}</strong></p>`;
  return html;
}

function buildStage1AxisAttributionStep(ctx, axisKey) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const attr = diag?.stage1AxisAttribution;
  if (!attr?.byAxis?.length) return null;
  const bd = attr.byAxis.find((b) => b.axis === axisKey);
  if (!bd) return null;
  return {
    title: `Per-input attribution · ${AXIS_DISPLAY_NAMES[axisKey] || axisKey} axis`,
    description:
      "Each row is a transit, planet placement, lunar nudge, or jitter term that pushed this axis before the silhouette formula runs.",
    body: renderAxisAttributionTable(bd),
  };
}

function buildStage1AttributionSteps(ctx, highlightEnergy = null) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const attribution = diag?.stage1Attribution;
  if (!attribution?.byEnergy?.length) return [];

  const steps = [];

  if (highlightEnergy) {
    const bd = attribution.byEnergy.find((b) => b.energy === highlightEnergy);
    if (bd) {
      steps.push({
        title: `Per-input attribution · ${vibeEnergyDisplayName(highlightEnergy)}`,
        description: `Top contributors to ${vibeEnergyDisplayName(highlightEnergy)} energy from all sources.`,
        body: renderEnergyAttributionTable(bd, highlightEnergy, diag),
      });
    }
  } else {
    for (const bd of attribution.byEnergy) {
      steps.push({
        title: `Attribution · ${vibeEnergyDisplayName(bd.energy)}`,
        body: renderEnergyAttributionTable(bd, null, diag),
      });
    }
  }

  const mults = attribution.signMultiplierApplied;
  const appliedToDaily = attribution.signMultipliersAppliedToDailyVibe !== false;
  if (mults && Object.keys(mults).length) {
    let multHtml = '<table class="data-table"><thead><tr><th>Energy</th><th>Multiplier</th></tr></thead><tbody>';
    for (const [k, v] of Object.entries(mults).sort((a, b) => b[1] - a[1])) {
      const hi = highlightEnergy && k === highlightEnergy ? ' style="background:rgba(124,111,247,0.12)"' : "";
      multHtml += `<tr${hi}><td>${esc(vibeEnergyDisplayName(k))}</td><td>${Number(v).toFixed(3)}</td></tr>`;
    }
    multHtml += "</tbody></table>";
    multHtml += `<p style="margin-top:4px;font-size:0.85em">Engine mode: ${esc(attribution.engineMode)}</p>`;
    if (!appliedToDaily) {
      multHtml += '<p style="margin-top:4px;font-size:0.85em">Not applied to daily vibe (sky path). Post-multiplier trace equals raw on the payload path.</p>';
    }
    steps.push({
      title: appliedToDaily ? "Sun-sign multipliers" : "Sun-sign multipliers (not applied to daily vibe)",
      description: appliedToDaily
        ? "Applied after accumulation — converts raw scores to post-multiplier scores."
        : "Chart-anchor reference only — daily sky bars use unfiltered accumulation.",
      body: multHtml,
    });
  }

  const chartMults = attribution.chartAnchorSignMultiplierApplied;
  if (chartMults && Object.keys(chartMults).length) {
    steps.push({
      title: "Chart-anchor Sun-sign multipliers",
      description: "Applied on chartVibeProfile comparison slice only — not on daily sky payload bars.",
      body: renderChartAnchorMultipliersBody(chartMults),
    });
  }

  return steps;
}

function findBlueprintColour(name, blueprint) {
  if (!blueprint?.palette) return null;
  const bands = [
    ["Neutrals", blueprint.palette.neutrals],
    ["Core", blueprint.palette.coreColours],
    ["Accents", blueprint.palette.accentColours],
    ["Support", blueprint.palette.supportColours],
  ];
  for (const [band, colours] of bands) {
    const match = colours?.find((c) => c.name === name);
    if (match) return { colour: match, band };
  }
  const specials = [
    ["Light Anchor", blueprint.palette.lightAnchor],
    ["Deep Anchor", blueprint.palette.deepAnchor],
    ["Luminary Signature", blueprint.palette.luminarySignature],
    ["Ruler Signature", blueprint.palette.rulerSignature],
  ];
  for (const [band, colour] of specials) {
    if (colour?.name === name) return { colour, band };
  }
  return null;
}

function formatColourProvenanceRows(p) {
  if (!p) return [["Provenance", "Unknown"]];
  const rows = [["Kind", p.kind || "unknown"]];
  for (const [k, v] of Object.entries(p)) {
    if (k === "kind") continue;
    rows.push([
      k.replace(/([A-Z])/g, " $1").replace(/^./, (s) => s.toUpperCase()),
      typeof v === "number" ? v.toFixed(4) : String(v ?? "—"),
    ]);
  }
  return rows;
}

function provenanceTable(p) {
  const rows = formatColourProvenanceRows(p);
  let html = '<table class="data-table"><tbody>';
  for (const [label, value] of rows) {
    html += `<tr><td>${esc(label)}</td><td>${esc(value)}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function renderPaletteMetaTable(palette) {
  if (!palette) return "<p>No palette metadata.</p>";
  let html = '<table class="data-table"><tbody>';
  if (palette.family) html += `<tr><td>Family</td><td>${esc(String(palette.family))}</td></tr>`;
  if (palette.cluster) html += `<tr><td>Cluster</td><td>${esc(String(palette.cluster))}</td></tr>`;
  if (palette.secondaryPull)
    html += `<tr><td>Secondary pull</td><td>${esc(String(palette.secondaryPull))}</td></tr>`;
  if (palette.overrideFlags) {
    for (const [k, v] of Object.entries(palette.overrideFlags)) {
      html += `<tr><td>${esc(k)}</td><td>${esc(String(v))}</td></tr>`;
    }
  }
  if (palette.variables) {
    for (const [k, v] of Object.entries(palette.variables)) {
      html += `<tr><td>${esc(k)}</td><td>${typeof v === "number" ? v.toFixed(3) : esc(String(v))}</td></tr>`;
    }
  }
  html += "</tbody></table>";
  return html;
}

function blueprintDiagnostics(ctx) {
  return ctx?.data?.blueprintDiagnostics || null;
}

function renderChartInputTable(input, boundaryFlags = []) {
  if (!input) return "<p>No chart input.</p>";
  const rows = [
    ["Ascendant", input.ascendant],
    ["Venus", input.venus],
    ["Sun", input.sun],
    ["Moon", input.moon],
    ["Mercury", input.mercury],
    ["Mars", input.mars],
    ["Saturn", input.saturn],
    ["Jupiter", input.jupiter],
    ["Pluto", input.pluto],
  ];
  let html =
    '<table class="data-table"><thead><tr><th>Driver</th><th>Sign</th><th>Degree</th></tr></thead><tbody>';
  for (const [label, placement] of rows) {
    if (!placement) continue;
    const deg =
      placement.degree != null ? `${Number(placement.degree).toFixed(1)}°` : "—";
    html += `<tr><td>${esc(label)}</td><td>${esc(placement.sign || "—")}</td><td>${deg}</td></tr>`;
  }
  html += "</tbody></table>";
  if (boundaryFlags?.length) {
    html += `<p style="margin-top:8px"><strong>Sign-boundary flags</strong> (&lt;1° from cusp):</p>`;
    html += '<table class="data-table"><tbody>';
    for (const flag of boundaryFlags) {
      html += `<tr><td>${esc(flag.driverKey)}</td><td>${esc(flag.sign)}</td><td>${Number(flag.degreeFromCusp).toFixed(2)}°</td></tr>`;
    }
    html += "</tbody></table>";
  }
  return html;
}

function renderRawVariableScoresTable(scores, label = "Variable") {
  if (!scores) return "<p>No raw scores.</p>";
  const rows = [
    ["Depth", scores.depth],
    ["Warmth", scores.warmth],
    ["Saturation", scores.saturation],
    ["Contrast", scores.contrast],
    ["Structure", scores.structure],
  ];
  let html = `<table class="data-table"><thead><tr><th>${esc(label)}</th><th>Score</th></tr></thead><tbody>`;
  for (const [name, value] of rows) {
    html += `<tr><td>${esc(name)}</td><td>${Number(value).toFixed(0)}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function renderNormalizedDriversTable(normalized) {
  if (!normalized?.drivers?.length) return "<p>No normalized drivers.</p>";
  let html =
    '<table class="data-table"><thead><tr><th>Driver</th><th>Sign</th><th>Weight</th></tr></thead><tbody>';
  for (const d of [...normalized.drivers].sort((a, b) => b.weight - a.weight)) {
    html += `<tr><td>${esc(d.key)}</td><td>${esc(d.sign)}</td><td>${d.weight}</td></tr>`;
  }
  html += "</tbody></table>";
  if (normalized.hasPluto) {
    html += `<p style="margin-top:8px">Pluto included: <strong>${esc(normalized.plutoSign || "—")}</strong></p>`;
  }
  return html;
}

function renderDerivedVariablesTable(vars) {
  if (!vars) return "<p>No derived variables.</p>";
  let html = '<table class="data-table"><tbody>';
  for (const [k, v] of Object.entries(vars)) {
    html += `<tr><td>${esc(k)}</td><td>${esc(String(v))}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function renderOverrideFlagsTable(flags) {
  if (!flags) return "<p>No override flags.</p>";
  const active = Object.entries(flags).filter(([, v]) => v === true);
  if (!active.length) return "<p>No chart overrides applied.</p>";
  let html = '<table class="data-table"><tbody>';
  for (const [k, v] of active) {
    html += `<tr><td>${esc(k)}</td><td>${esc(String(v))}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function renderFamilyOutcomeTable(trace, highlightField = null) {
  if (!trace) return "<p>No family decision data.</p>";
  const rows = [
    ["Family", trace.family],
    ["Cluster", trace.cluster],
    ["Secondary pull", trace.secondaryPull || "—"],
  ];
  let html = '<table class="data-table"><tbody>';
  for (const [label, value] of rows) {
    const hi =
      highlightField &&
      label.toLowerCase().replace(/\s+/g, "") === highlightField.toLowerCase()
        ? ' style="background:rgba(124,111,247,0.15)"'
        : "";
    html += `<tr${hi}><td>${esc(label)}</td><td>${esc(String(value ?? "—"))}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function renderVariationTraceTable(variation) {
  if (!variation?.substitutions?.length) {
    return `<p>No per-user substitutions${variation?.pullFamily ? ` (pull: ${esc(variation.pullFamily)}, strength ${variation.pullStrength})` : ""}.</p>`;
  }
  let html =
    '<table class="data-table"><thead><tr><th>Band</th><th>Slot</th><th>Original</th><th>Replaced</th><th>From family</th></tr></thead><tbody>';
  for (const sub of variation.substitutions) {
    html += `<tr><td>${esc(sub.band)}</td><td>${sub.slotIndex}</td><td>${esc(sub.originalColour)}</td><td>${esc(sub.replacedWith)}</td><td>${esc(sub.fromFamily)}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function renderAccentSlotsTable(accentSlots, highlightPlanet = null) {
  if (!accentSlots?.length) return "<p>No accent slot trace.</p>";
  let html =
    '<table class="data-table"><thead><tr><th>Role</th><th>Label</th><th>Hex</th><th>Planet</th><th>Sign</th><th>Sat. override</th></tr></thead><tbody>';
  for (const slot of accentSlots) {
    const hi =
      highlightPlanet && slot.sourcePlanet === highlightPlanet
        ? ' style="background:rgba(124,111,247,0.15)"'
        : "";
    html += `<tr${hi}><td>${esc(slot.role)}</td><td>${esc(slot.displayName)}</td><td>${esc(slot.hex)}</td><td>${esc(slot.sourcePlanet)}</td><td>${esc(slot.sourceSign)}</td><td>${slot.saturationOverrideApplied ? "Yes" : "No"}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function buildFamilyDecisionTraceSteps(ctx, options = {}) {
  const diag = blueprintDiagnostics(ctx);
  const trace = diag?.familyDecisionTrace;
  if (!trace) return [];

  const { highlightField = null, highlightPlanet = null } = options;
  const steps = [
    {
      title: "Chart input → colour drivers",
      description: "Planetary signs fed into the V4 colour engine.",
      body: renderChartInputTable(diag.chartInput, diag.boundaryFlags),
    },
    {
      title: "Weighted driver normalization",
      description: "Core and outer placements after sign-weight aggregation.",
      body: renderNormalizedDriversTable(trace.normalizedDrivers),
    },
    {
      title: "Raw variable scores",
      description: "Integer scores before and after chart modifiers.",
      body:
        renderRawVariableScoresTable(trace.rawScoresBeforeModifiers, "Before modifiers") +
        '<p style="margin-top:8px"><strong>After modifiers:</strong></p>' +
        renderRawVariableScoresTable(trace.rawScoresAfterModifiers, "After modifiers"),
    },
    {
      title: "Derived variables & overrides",
      description: "Enum variables mapped from raw scores; chart-specific overrides applied.",
      body:
        '<p><strong>Before overrides:</strong></p>' +
        renderDerivedVariablesTable(trace.variablesBeforeOverrides) +
        '<p style="margin-top:8px"><strong>Override flags:</strong></p>' +
        renderOverrideFlagsTable(trace.overrideFlags) +
        '<p style="margin-top:8px"><strong>After overrides (canonical):</strong></p>' +
        renderDerivedVariablesTable(trace.variablesAfterOverrides),
    },
    {
      title: "Family & cluster selection",
      description: "Final palette family, cluster, and optional secondary pull.",
      body: renderFamilyOutcomeTable(trace, highlightField),
    },
  ];

  if (trace.variation?.substitutions?.length || trace.variation?.pullFamily) {
    steps.push({
      title: "Per-user variation",
      body: renderVariationTraceTable(trace.variation),
    });
  }

  if (diag.accentSlots?.length) {
    steps.push({
      title: "Chart-derived accent slots",
      description: "V4.5 accent resolution from planetary signs.",
      body: renderAccentSlotsTable(diag.accentSlots, highlightPlanet),
    });
  }

  return steps;
}

function buildBlueprintDiagnosticsAccordion(diag) {
  if (!diag?.familyDecisionTrace) return "";
  const ctx = { data: { blueprintDiagnostics: diag } };
  let html = accordion("Style Guide · Colour Engine Decision Tree", () =>
    renderDerivationTimeline(buildFamilyDecisionTraceSteps(ctx)),
  );

  if (diag.midheavenSign) {
    html += accordion("Style Guide · Midheaven Narrative Overlay", () => {
      const applied = diag.midheavenOverlayApplied ? "Yes" : "No";
      return `<table class="data-table"><tbody>
        <tr><td>Midheaven sign</td><td>${esc(diag.midheavenSign)}</td></tr>
        <tr><td>MC narrative overlay applied</td><td>${applied}</td></tr>
      </tbody></table>`;
    });
  }

  return html;
}

function renderBlueprintColourDrill(name, ctx) {
  const bp = ctx.data?.blueprint;
  const found = findBlueprintColour(name, bp);
  const decisionSteps = buildFamilyDecisionTraceSteps(ctx, {
    highlightPlanet:
      found?.colour?.provenance?.kind === "chartDerivedAccent"
        ? found.colour.provenance.sourcePlanet
        : null,
  });
  const steps = [
    ...decisionSteps,
    {
      title: "Output · palette context",
      description: "Fixed per profile — derived from natal chart at blueprint compose time.",
      body: renderPaletteMetaTable(bp?.palette),
    },
  ];
  if (found) {
    steps.push({
      title: "Output · colour placement",
      body: `<table class="data-table"><tbody>
        <tr><td>Name</td><td>${esc(found.colour.name)}</td></tr>
        <tr><td>Hex</td><td>${esc(found.colour.hexValue)}</td></tr>
        <tr><td>Band</td><td>${esc(found.band)}</td></tr>
        <tr><td>Role</td><td>${esc(found.colour.role || "—")}</td></tr>
      </tbody></table>`,
    });
    steps.push({
      title: "Output · chart & engine provenance",
      description: "How the colour engine grounded this swatch in planetary/chart input.",
      body: provenanceTable(found.colour.provenance),
    });
  } else {
    steps.push({
      title: "Colour not found",
      body: `<p>No Style Guide swatch named <strong>${esc(name)}</strong>.</p>`,
    });
  }
  return {
    title: `Style Guide · ${name}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderDailyColourDrill(name, ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const payload = ctx.data?.dailyFit?.payload;
  const pt = diag?.paletteSelectionTrace;
  const selected = (pt?.selectedColours || payload?.dailyPalette?.colours || []).find(
    (c) => c.name === name,
  );
  const steps = [
    {
      title: "Stage 1 · Sky inputs",
      description: "Weighted mix of natal, transits, lunar, progressed, and current Sun.",
      body: renderSourceContributionsTable(diag?.sourceContributions),
    },
    {
      title: "Stage 1 · Energy scores",
      description: "Accumulated energies that feed Stage 2 palette scoring.",
      body: payloadEnergyScoresSection(diag, { includeRaw: true }),
    },
    {
      title: "Stage 2 · Candidate pool",
      body: `<table class="data-table"><tbody>
        <tr><td>Strategy</td><td>${esc(pt?.selectionStrategy || "dramaSlots")}</td></tr>
        <tr><td>Candidates evaluated</td><td>${pt?.candidateCount ?? "—"}</td></tr>
        <tr><td>Diversity swap</td><td>${pt?.diversitySwapApplied ? "Yes" : "No"}</td></tr>
        <tr><td>Core anchor swap</td><td>${pt?.coreAnchorSwapApplied ? "Yes" : "No"}</td></tr>
      </tbody></table>`,
    },
    {
      title: "Stage 2 · Scoring & selection",
      description: "Top scored candidates; highlighted row is this colour if present.",
      body: (() => {
        let html =
          '<table class="data-table"><thead><tr><th>Colour</th><th>Role</th><th>Score</th></tr></thead><tbody>';
        for (const c of pt?.topScoredColours || []) {
          const hi = c.name === name ? ' style="background:rgba(124,111,247,0.15)"' : "";
          html += `<tr${hi}><td>${esc(c.name)}</td><td>${esc(c.role)}</td><td>${c.score.toFixed(4)}</td></tr>`;
        }
        html += "</tbody></table>";
        if (selected) {
          html += `<p style="margin-top:8px"><strong>Selected role:</strong> ${esc(selected.role)}</p>`;
        }
        return html;
      })(),
    },
  ];
  return {
    title: `Daily Palette · ${name}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderScaleDrill(type, ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const trace = diag?.[`${type}Trace`];
  const label = type.charAt(0).toUpperCase() + type.slice(1);
  const contrastAxis = "visibility";
  const steps = [
    {
      title: "Stage 1 · Input mix",
      body: renderSourceContributionsTable(diag?.sourceContributions),
    },
    {
      title: "Stage 1 · Final axis scores",
      description: "All four axes after sigmoid (1–10). Contrast uses visibility; vibrancy uses vibe energies.",
      body: (() => {
        const fa = diag?.finalAxes;
        if (!fa) return renderEnergyScoresTable(diag?.rawAxisScores);
        return `<table class="data-table"><tbody>
          <tr><td>Action</td><td>${Number(fa.action).toFixed(2)}</td></tr>
          <tr><td>Tempo</td><td>${Number(fa.tempo).toFixed(2)}</td></tr>
          <tr><td>Strategy</td><td>${Number(fa.strategy).toFixed(2)}</td></tr>
          <tr><td>Visibility</td><td>${Number(fa.visibility).toFixed(2)}</td></tr>
        </tbody></table>`;
      })(),
    },
  ];
  if (type === "contrast") {
    const axisStep = buildStage1AxisAttributionStep(ctx, contrastAxis);
    if (axisStep) steps.push(axisStep);
  } else if (type === "vibrancy") {
    steps.push(...buildStage1AttributionSteps(ctx));
  }
  steps.push({
    title: "Stage 2 · Style Guide baseline → modulation → final",
    body: trace
      ? `<table class="data-table"><tbody>
            <tr><td>Blueprint baseline</td><td>${trace.blueprintBaseline.toFixed(4)}</td></tr>
            <tr><td>Energy modulation</td><td>${trace.modulation.toFixed(4)}</td></tr>
            <tr><td>Final value</td><td><strong>${trace.finalValue.toFixed(4)}</strong></td></tr>
          </tbody></table>`
      : "<p>No trace data.</p>",
  });
  return {
    title: `${label} derivation`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderEssenceDrill(category, ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const payload = ctx.data?.dailyFit?.payload;
  const ep = diag?.essenceProfile || payload?.essenceProfile;
  const today = (ep?.allScores || []).find((e) => e.category === category);
  const anchor = (ep?.chartAnchorScores || []).find((e) => e.category === category);
  const visible = new Set((ep?.visibleCategories || []).map((e) => e.category));
  const steps = [
    {
      title: "Stage 1 · Input mix",
      body: renderSourceContributionsTable(diag?.sourceContributions),
    },
    {
      title: "Category scores",
      body: `<table class="data-table"><tbody>
        <tr><td>Category</td><td>${esc(category.toUpperCase())}</td></tr>
        <tr><td>Today</td><td>${today ? pct(today.score) : "—"}</td></tr>
        <tr><td>Chart anchor</td><td>${anchor ? pct(anchor.score) : "—"}</td></tr>
        <tr><td>Visible today (top 3)</td><td>${visible.has(category) ? "Yes ★" : "No"}</td></tr>
      </tbody></table>`,
    },
  ];

  const dominantEnergies = ESSENCE_ENERGY_MAP[category];
  const attribution = diag?.stage1Attribution;
  if (dominantEnergies?.length && attribution?.byEnergy?.length) {
    let attrHtml = `<p style="margin-bottom:6px"><strong>${esc(category.charAt(0).toUpperCase() + category.slice(1))}</strong> is driven primarily by: ${dominantEnergies.map(e => esc(vibeEnergyDisplayName(e))).join(", ")}</p>`;
    for (const energy of dominantEnergies) {
      const bd = attribution.byEnergy.find((b) => b.energy === energy);
      if (bd) {
        attrHtml += `<p style="margin-top:8px"><strong>${esc(vibeEnergyDisplayName(energy))} contributors:</strong></p>`;
        attrHtml += renderEnergyAttributionTable(bd, energy);
      }
    }
    steps.push({
      title: "Per-input attribution (dominant energies)",
      description: "Which inputs drive the energies that feed this essence category.",
      body: attrHtml,
    });
  }

  steps.push({
    title: "All 14 categories",
    body: buildEssenceProfileHtml(ep, false),
  });

  return {
    title: `Style Essence · ${category}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderSilhouetteDrill(axis, ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const payload = ctx.data?.dailyFit?.payload;
  const st = diag?.silhouetteTrace;
  const sp = payload?.silhouetteProfile;
  const cfg = SILHOUETTE_AXIS_CONFIG[axis] || SILHOUETTE_AXIS_CONFIG.mf;
  const drivingAxis = cfg.drivingAxis;
  const axisVal =
    diag?.finalAxes?.[drivingAxis] ?? payload?.axes?.[drivingAxis];
  const chartAnchor =
    axis === "mf"
      ? sp?.chartAnchorMF ?? st?.baselineMF
      : axis === "ar"
        ? sp?.chartAnchorAR ?? st?.baselineAR
        : sp?.chartAnchorSD ?? st?.baselineSD;
  const finalVal =
    axis === "mf"
      ? (st?.finalMF ?? sp?.masculineFeminine)
      : axis === "ar"
        ? (st?.finalAR ?? sp?.angularRounded)
        : (st?.finalSD ?? sp?.structuredDraped);
  const engineMode = diag?.stage1AxisAttribution?.engineMode
    || diag?.stage1Attribution?.engineMode
    || payload?.dailyFitEngineId
    || "—";
  const isStage1 = String(engineMode).includes("stage1") || String(engineMode).includes("experimental");

  const steps = [
    {
      title: "What this slider means",
      description: cfg.semantic,
      body: `<table class="data-table"><tbody>
        <tr><td>Slider</td><td>${esc(cfg.label)}</td></tr>
        <tr><td>Driven by axis</td><td><strong>${esc(AXIS_DISPLAY_NAMES[drivingAxis] || drivingAxis)}</strong> (${drivingAxis})</td></tr>
        <tr><td>Engine</td><td>${esc(engineMode)}</td></tr>
      </tbody></table>`,
    },
    {
      title: "Stage 1 · Sky input mix (energies)",
      description: "Aggregate share of natal / transits / lunar / progressed / Sun feeding today's vibe scores.",
      body: renderSourceContributionsTable(diag?.sourceContributions),
    },
  ];

  const axisStep = buildStage1AxisAttributionStep(ctx, drivingAxis);
  if (axisStep) steps.push(axisStep);

  steps.push({
    title: "Stage 1 · Axis → slider formula",
    description: isStage1
      ? "Stage 1 experimental: slider is centred at 0.5 and shaped only by today's sky axis (not the Style Guide keyword anchor)."
      : "Standard: Style Guide keyword baseline plus a small axis nudge.",
    body: (() => {
      let html = `<table class="data-table"><tbody>
        <tr><td>${esc(AXIS_DISPLAY_NAMES[drivingAxis])} axis (1–10)</td><td><strong>${axisVal != null ? Number(axisVal).toFixed(2) : "—"}</strong></td></tr>`;
      if (chartAnchor != null) {
        html += `<tr><td>Chart anchor (Code keywords)</td><td>${fmtNum(chartAnchor)} <span style="font-size:0.85em;color:var(--muted)">reference only in stage1</span></td></tr>`;
      }
      html += `<tr><td>Final slider (0–1)</td><td><strong>${fmtNum(finalVal)}</strong></td></tr>`;
      html += "</tbody></table>";
      if (isStage1 && axisVal != null) {
        html += `<p style="margin-top:8px;font-size:0.9em"><strong>Formula:</strong> ${esc(cfg.stage1Formula(Number(axisVal).toFixed(2)))}</p>`;
      }
      return html;
    })(),
  });

  steps.push({
    title: "All silhouette axes",
    body: `<table class="data-table"><tbody>
        <tr><td>M / F</td><td>${fmtNum(sp?.masculineFeminine)}</td></tr>
        <tr><td>A / R</td><td>${fmtNum(sp?.angularRounded)}</td></tr>
        <tr><td>S / D</td><td>${fmtNum(sp?.structuredDraped)}</td></tr>
      </tbody></table>`,
  });

  return {
    title: `Silhouette · ${cfg.label}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderTransitDrill(name, ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const payload = ctx.data?.dailyFit?.payload;
  const transit = (payload?.dominantTransits || []).find((t) => t.transitPlanet === name);
  const attribution = diag?.stage1Attribution;
  const steps = [
    {
      title: "Stage 1 · Input mix",
      description: "Transit share of today's energy snapshot.",
      body: renderSourceContributionsTable(diag?.sourceContributions),
    },
    {
      title: "Selected transit",
      body: transit
        ? `<table class="data-table"><tbody>
            <tr><td>Transiting</td><td>${esc(transit.transitPlanet)}</td></tr>
            <tr><td>Natal</td><td>${esc(transit.natalPlanet)}</td></tr>
            <tr><td>Aspect</td><td>${esc(transit.aspect)}</td></tr>
            <tr><td>Strength</td><td>${pct(transit.strength)}</td></tr>
          </tbody></table>`
        : `<p>Transit <strong>${esc(name)}</strong> not in dominant set.</p>`,
    },
  ];

  if (attribution?.byEnergy?.length) {
    steps.push({
      title: `Energy impact of ${name}`,
      description: `Per-energy contribution of all ${name} transit aspects.`,
      body: renderEnergyAttributionForTransit(attribution, name),
    });
  }

  steps.push({
    title: "All transit summaries",
    body: (() => {
      let html =
        '<table class="data-table"><thead><tr><th>Transit</th><th>Natal</th><th>Aspect</th><th>Strength</th></tr></thead><tbody>';
      for (const t of diag?.transitSummaries || []) {
        const hi = t.transitPlanet === name ? ' style="background:rgba(124,111,247,0.15)"' : "";
        html += `<tr${hi}><td>${esc(t.transitPlanet)}</td><td>${esc(t.natalPlanet)}</td><td>${esc(t.aspect)}</td><td>${pct(t.strength)}</td></tr>`;
      }
      html += "</tbody></table>";
      return html;
    })(),
  });

  return {
    title: `Transit · ${name}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderTarotDrill(ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const sorted = [...(diag?.tarotCardScores || [])].sort(
    (a, b) => b.totalScore - a.totalScore,
  );
  const steps = [
    {
      title: "Stage 1 · Energy context",
      body:
        renderSourceContributionsTable(diag?.sourceContributions) +
        '<p style="margin-top:8px"><strong>Daily payload energies:</strong></p>' +
        renderEnergyScoresTable(diag?.postMultiplierScores),
    },
    {
      title: "Stage 2 · Card scoring",
      description: "All cards ranked by vibe + axis + transit boost − recency penalty.",
      body: (() => {
        let html =
          '<table class="data-table"><thead><tr><th>Card</th><th>Total</th><th>Vibe</th><th>Axis</th><th>Boost</th><th>Penalty</th></tr></thead><tbody>';
        for (const s of sorted) {
          const hi = s.cardName === diag?.selectedTarotCard ? ' style="background:rgba(124,111,247,0.15)"' : "";
          html += `<tr${hi}><td>${esc(s.cardName)}</td><td><strong>${s.totalScore.toFixed(3)}</strong></td>
            <td>${s.vibeScore.toFixed(3)}</td><td>${s.axisScore.toFixed(3)}</td>
            <td>${s.transitBoost.toFixed(3)}</td><td>${s.recencyPenalty.toFixed(3)}</td></tr>`;
        }
        html += "</tbody></table>";
        return html;
      })(),
    },
    {
      title: "Selection output",
      body: `<table class="data-table"><tbody>
        <tr><td>Selected card</td><td><strong>${esc(diag?.selectedTarotCard || "—")}</strong></td></tr>
        <tr><td>Variant rotation</td><td>${diag?.variantRotationIndex ?? "—"}</td></tr>
        <tr><td>Style edit</td><td>${esc(diag?.selectedStyleEdit || "—")}</td></tr>
      </tbody></table>`,
    },
  ];
  return {
    title: "Tarot selection",
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderTextureDrill(name, ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const tt = diag?.textureSelectionTrace;
  const steps = [
    {
      title: "Stage 1 · Energy context",
      body: payloadEnergyScoresSection(diag),
    },
    {
      title: "Texture scoring",
      body: (() => {
        let html =
          '<table class="data-table"><thead><tr><th>Texture</th><th>Score</th></tr></thead><tbody>';
        for (const s of tt?.scores || []) {
          const hi = s.name === name ? ' style="background:rgba(124,111,247,0.15)"' : "";
          html += `<tr${hi}><td>${esc(s.name)}</td><td>${s.score.toFixed(4)}</td></tr>`;
        }
        html += "</tbody></table>";
        html += `<p style="margin-top:8px"><strong>Selected:</strong> ${esc((tt?.selected || []).join(", ") || "—")}</p>`;
        return html;
      })(),
    },
  ];
  return {
    title: `Texture · ${name}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderPatternDrill(ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const pd = diag?.patternDecision;
  const steps = [
    {
      title: "Stage 1 · Dominant energy",
      body: payloadEnergyScoresSection(diag, { highlight: pd?.dominantEnergy }),
    },
    {
      title: "Pattern gate & selection",
      body: pd
        ? `<table class="data-table"><tbody>
            <tr><td>Gate passed</td><td>${pd.gateCheckPassed ? "Yes" : "No"}</td></tr>
            <tr><td>Visibility</td><td>${pd.visibilityValue.toFixed(3)}</td></tr>
            <tr><td>Dominant energy</td><td>${esc(pd.dominantEnergy)}</td></tr>
            <tr><td>Selected pattern</td><td><strong>${esc(pd.selectedPattern || "None")}</strong></td></tr>
          </tbody></table>`
        : "<p>No pattern decision data.</p>",
    },
  ];
  return {
    title: "Daily pattern",
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderVibeDrill(energy, ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const payload = ctx.data?.dailyFit?.payload;
  const raw = diag?.rawEnergyScores?.[energy];
  const post = diag?.postMultiplierScores?.[energy];
  const final = payload?.vibeBreakdown?.[energy];
  const postLabel = signMultipliersAppliedToDailyVibe(diag)
    ? "Post-multiplier"
    : "Pre-normalisation (no sign mult on daily vibe)";
  const steps = [
    {
      title: "Stage 1 · Input mix",
      body: renderSourceContributionsTable(diag?.sourceContributions),
    },
    {
      title: "Energy pipeline",
      body: `<table class="data-table"><tbody>
        <tr><td>Energy</td><td>${esc(vibeEnergyDisplayName(energy))}</td></tr>
        <tr><td>Raw score</td><td>${raw != null ? Number(raw).toFixed(4) : "—"}</td></tr>
        <tr><td>${esc(postLabel)}</td><td>${post != null ? Number(post).toFixed(4) : "—"}</td></tr>
        <tr><td>Final vibe points (/21)</td><td><strong>${final != null ? Number(final).toFixed(1) : "—"}</strong></td></tr>
      </tbody></table>`,
    },
    ...buildStage1AttributionSteps(ctx, energy),
    {
      title: "All six energies",
      body: payloadEnergyScoresSection(diag),
    },
  ];
  return {
    title: `Vibe · ${vibeEnergyDisplayName(energy)}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderLunarDrill(ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const payload = ctx.data?.dailyFit?.payload;
  const lunar = payload?.lunarContext || diag?.lunarContext;
  const steps = [
    {
      title: "Stage 1 · Lunar weight",
      body: renderSourceContributionsTable(diag?.sourceContributions),
    },
    {
      title: "Lunar context",
      body: lunar
        ? `<table class="data-table"><tbody>
            <tr><td>Phase</td><td>${esc(lunar.phaseName)}</td></tr>
            <tr><td>Waxing / Waning</td><td>${lunar.isWaxing ? "Waxing" : "Waning"}</td></tr>
            <tr><td>Element</td><td>${esc(lunar.element)}</td></tr>
            <tr><td>Phase degrees</td><td>${lunar.phaseDegrees.toFixed(1)}°</td></tr>
          </tbody></table>`
        : "<p>No lunar context.</p>",
    },
  ];
  return {
    title: "Lunar context",
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderStyleEditDrill(ctx) {
  const diag = ctx.data?.dailyFit?.diagnostics;
  const payload = ctx.data?.dailyFit?.payload;
  const variant = payload?.styleEditVariant;
  const steps = [
    {
      title: "Tarot-driven rotation",
      body: `<table class="data-table"><tbody>
        <tr><td>Selected tarot</td><td>${esc(diag?.selectedTarotCard || "—")}</td></tr>
        <tr><td>Variant index</td><td>${diag?.variantRotationIndex ?? "—"}</td></tr>
        <tr><td>Style edit id</td><td>${esc(diag?.selectedStyleEdit || "—")}</td></tr>
      </tbody></table>`,
    },
    {
      title: "Rendered variant",
      body: variant
        ? `<p><strong>${esc(variant.title || "")}</strong></p>
           ${variant.dailyRitual ? `<p>${esc(variant.dailyRitual)}</p>` : ""}
           ${variant.wardrobeReflection ? `<p><em>${esc(variant.wardrobeReflection)}</em></p>` : ""}`
        : "<p>No style edit variant.</p>",
    },
  ];
  return {
    title: "Style edit",
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderBlueprintMetaDrill(field, ctx) {
  const palette = ctx.data?.blueprint?.palette;
  const highlightMap = {
    family: "family",
    cluster: "cluster",
    secondaryPull: "secondarypull",
  };
  const steps = buildFamilyDecisionTraceSteps(ctx, {
    highlightField: highlightMap[field] || field,
  });
  steps.push({
    title: "Output · palette metadata",
    description: "Serialized fields on the Style Guide palette section.",
    body: renderPaletteMetaTable(palette),
  });
  return {
    title: `Style Guide · ${field}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function renderBlueprintTagDrill(kind, value, ctx) {
  const bp = ctx.data?.blueprint;
  const steps = buildFamilyDecisionTraceSteps(ctx);
  steps.push({
    title: "Output · Style Guide context",
    body: renderPaletteMetaTable(bp?.palette),
  });
  steps.push({
    title: `${kind} in blueprint`,
    body: `<p><strong>${esc(value)}</strong> is part of the fixed Style Guide ${kind} recommendation set for this profile.</p>
           <p class="derivation-step-desc">Per-texture/per-pattern scoring traces are not yet serialized in the API — see Daily Fit texture/pattern drill-down for scored daily selections.</p>`,
  });
  return {
    title: `Style Guide · ${value}`,
    html: renderDrillMeta(ctx) + renderDerivationTimeline(steps),
  };
}

function openDrill(key, ctx = null) {
  const context = ctx || { data: state.data, dateISO: targetDateISO(), engineId: currentDailyFitEngineId() };
  if (!context.data) return;
  const drawer = document.getElementById("drill-drawer");
  const title = document.getElementById("drawer-title");
  const content = document.getElementById("drawer-content");
  drawer.classList.remove("hidden");
  document.body.classList.add("drawer-open");

  const [type, ...rest] = key.split(":");
  const name = rest.join(":");
  let result = { title: key, html: "" };

  if (type === "blueprint-colour") result = renderBlueprintColourDrill(name, context);
  else if (type === "colour") result = renderDailyColourDrill(name, context);
  else if (type === "palette") result = renderDailyColourDrill(name, context);
  else if (type === "tarot") result = renderTarotDrill(context);
  else if (type === "vibrancy" || type === "contrast" || type === "metalTone")
    result = renderScaleDrill(type, context);
  else if (type === "essence") result = renderEssenceDrill(name, context);
  else if (type === "silhouette") result = renderSilhouetteDrill(name || "mf", context);
  else if (type === "transit") result = renderTransitDrill(name, context);
  else if (type === "texture") result = renderTextureDrill(name, context);
  else if (type === "pattern") result = renderPatternDrill(context);
  else if (type === "vibe") result = renderVibeDrill(name, context);
  else if (type === "lunar") result = renderLunarDrill(context);
  else if (type === "styleEdit") result = renderStyleEditDrill(context);
  else if (type === "blueprint-meta") result = renderBlueprintMetaDrill(name, context);
  else if (type === "blueprint-texture" || type === "blueprint-pattern")
    result = renderBlueprintTagDrill(type.replace("blueprint-", ""), name, context);
  else
    result = {
      title: key,
      html: `<pre class="json-block">${esc(JSON.stringify(context.data, null, 2))}</pre>`,
    };

  title.textContent = result.title;
  content.innerHTML = result.html;
}

function closeDrawer() {
  document.getElementById("drill-drawer").classList.add("hidden");
  document.body.classList.remove("drawer-open");
  if (activeDrillNode) {
    activeDrillNode.classList.remove("drill-active");
    activeDrillNode = null;
  }
}

// ── Markdown export ──

const EXPORT_SECTION_LABELS = {
  natal: "Natal Chart",
  dailyfit: "Daily Fit",
  trace: "Trace & Provenance",
  verdicts: "Verdicts",
};

function updateExportButtons() {
  const data = state.data;
  const flags = {
    natal: !!data?.natal,
    dailyfit: !!data?.dailyFit,
    trace: !!data?.dailyFit?.diagnostics,
    verdicts: !!(data && Array.isArray(data.verdicts)),
  };
  document.querySelectorAll("[data-export]").forEach((btn) => {
    btn.disabled = !flags[btn.dataset.export];
  });
}

function exportSection(section) {
  if (!state.data) return;
  const markdown = buildSectionMarkdown(section);
  if (!markdown) return;
  downloadMarkdown(exportFilename(section), markdown);
  flashExportStatus(EXPORT_SECTION_LABELS[section] || section);
}

function flashExportStatus(label) {
  const el = document.getElementById("status-indicator");
  const prev = el.textContent;
  el.textContent = `Exported ${label} (.md)`;
  setTimeout(() => {
    if (el.textContent === `Exported ${label} (.md)`) el.textContent = prev;
  }, 2500);
}

function exportFilename(section) {
  const name = slugify(state.data.profile.displayName);
  if (isMultiDayCompareExport()) {
    const dates = getCompareDateRange();
    if (dates.length > 1) {
      const first = dates[0];
      const last = dates[dates.length - 1];
      const suffix =
        dates.length === 2
          ? `${first}_vs_${last}`
          : `${first}_to_${last}_${dates.length}d`;
      return `cosmicfit_${name}_${section}_${suffix}.md`;
    }
  }
  if (engineCompareActive()) {
    const target =
      parseDateUK(document.getElementById("target-date").value) ||
      "unknown-date";
    return `cosmicfit_${name}_${section}_${target}_${compareEngineAId()}_vs_${compareEngineBId()}.md`;
  }
  const target =
    parseDateUK(document.getElementById("target-date").value) || "unknown-date";
  return `cosmicfit_${name}_${section}_${target}.md`;
}

/** True when day-compare export should include multiple dates. */
function isMultiDayCompareExport() {
  return (
    document.getElementById("compare-toggle")?.checked &&
    getCompareDateRange().length > 1
  );
}

/** Days (or engine variants) to include in markdown export. */
function exportDayEntries() {
  if (isMultiDayCompareExport()) {
    return getCompareDateRange()
      .map((dateISO) => ({
        label: `${formatDateUK(dateISO)} (${dateISO})`,
        dateISO,
        data: inspectDataForCompareDate(dateISO),
      }))
      .filter((entry) => entry.data);
  }
  if (engineCompareActive()) {
    const target = targetDateISO();
    return [compareEngineAId(), compareEngineBId()]
      .map((engineId) => ({
        label: `${formatDateUK(target)} · ${engineId}`,
        dateISO: target,
        engineId,
        data: inspectDataForEngine(engineId, target),
      }))
      .filter((entry) => entry.data);
  }
  const target = targetDateISO();
  if (state.data) {
    return [
      {
        label: target ? `${formatDateUK(target)} (${target})` : "Target day",
        dateISO: target,
        data: state.data,
      },
    ];
  }
  return [];
}

function slugify(text) {
  return (
    (text || "profile")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/^_|_$/g, "") || "profile"
  );
}

function downloadMarkdown(filename, content) {
  const blob = new Blob([content], { type: "text/markdown;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

function buildSectionMarkdown(section) {
  const data = state.data;
  if (!data) return null;

  const entries = exportDayEntries();
  const builders = {
    natal: () => markdownNatal(data.natal),
    dailyfit: () => markdownDailyFitExport(entries),
    trace: () => markdownTraceExport(entries),
    verdicts: () => markdownVerdictsExport(entries),
  };
  const body = builders[section]?.();
  if (body == null) return null;

  return [
    markdownExportHeader(EXPORT_SECTION_LABELS[section] || section),
    markdownInputsBlock(),
    "---",
    "",
    body,
  ].join("\n");
}

function markdownExportHeader(sectionLabel) {
  const data = state.data;
  const meta = data.meta || {};
  const computedAt = meta.computedAt
    ? new Date(meta.computedAt).toISOString()
    : new Date().toISOString();
  return [
    `# Cosmic Fit Inspector — ${sectionLabel}`,
    "",
    `- **Exported:** ${computedAt}`,
    `- **Display name:** ${data.profile.displayName}`,
    `- **Profile hash:** ${meta.profileHash || "—"}`,
    `- **Engine version:** ${meta.engineVersion || "—"}`,
    `- **Daily Fit engine:** ${meta.dailyFitEngineDisplayName || meta.dailyFitEngineId || "—"} (\`${meta.dailyFitEngineId || "—"}\`)`,
    `- **Daily Fit fingerprint:** ${meta.dailyFitEngineFingerprint || "—"}`,
    `- **Inspector build:** ${state.buildStamp || "—"}`,
    "",
  ].join("\n");
}

function markdownInputsBlock() {
  const birth = state.data.profile?.birth;
  const targetUK = document.getElementById("target-date").value;
  const targetISO = parseDateUK(targetUK);
  const rows = [
    ["Daily Fit engine", currentDailyFitEngineId()],
    ["Preset", document.getElementById("preset-select").value],
    ["Birth date", document.getElementById("birth-date").value],
    ["Birth time", document.getElementById("birth-time").value || "00:00"],
    [
      "Birth time unknown",
      document.getElementById("unknown-time").checked ? "yes" : "no",
    ],
    ["Location", document.getElementById("location-input").value.trim()],
    ["Latitude", document.getElementById("latitude").value],
    ["Longitude", document.getElementById("longitude").value],
    ["Timezone", document.getElementById("timezone-id").value],
    ["Profile ID", document.getElementById("profile-id").value.trim() || "(auto)"],
    ["Device location (lat)", document.getElementById("device-lat").value.trim() || "(none)"],
    ["Device location (lon)", document.getElementById("device-lon").value.trim() || "(none)"],
    ["Daily Fit target (UK)", targetUK],
    ["Daily Fit target (ISO day)", targetISO || "—"],
  ];
  if (isMultiDayCompareExport()) {
    const dates = getCompareDateRange();
    rows.push(["Compare mode", "multi-day"]);
    rows.push(["Compare days", String(dates.length)]);
    rows.push(["Compare range (ISO)", dates.join(" → ")]);
    rows.push(["Days with data in export", String(exportDayEntries().length)]);
  } else if (engineCompareActive()) {
    rows.push(["Compare mode", "engines"]);
    rows.push(["Engine A", compareEngineAId()]);
    rows.push(["Engine B", compareEngineBId()]);
  }
  if (birth) {
    rows.push(["Birth date (API)", birth.birthDate]);
    rows.push(["Birth time (API)", birth.birthTime ?? "—"]);
  }
  return "## Profile inputs\n\n" + mdTable(["Field", "Value"], rows);
}

function markdownNatal(natal) {
  if (!natal) return "_No natal chart data._\n";
  let md = "## Natal Chart\n\n";

  const planetRows = natal.planets.map((p) => {
    const sign = ZODIAC_SIGNS[p.zodiacSign] || "?";
    const glyph = ZODIAC_GLYPHS[p.zodiacSign] || "";
    return [
      `${p.symbol} ${p.name}`,
      `${glyph} ${sign}`,
      p.longitude.toFixed(4),
      p.zodiacPosition,
      p.isRetrograde ? "℞" : "",
    ];
  });
  md +=
    "### Planets\n\n" +
    mdTable(["Planet", "Sign", "Longitude", "Position", "Retro"], planetRows);

  md +=
    "### Angles & Points\n\n" +
    mdTable(
      ["Point", "Value"],
      [
        [
          "Ascendant",
          `${natal.ascendant.toFixed(4)}° ${signFromDeg(natal.ascendant)}`,
        ],
        [
          "Midheaven (MC)",
          `${natal.midheaven.toFixed(4)}° ${signFromDeg(natal.midheaven)}`,
        ],
        ["Descendant", `${natal.descendant.toFixed(4)}°`],
        ["IC", `${natal.imumCoeli.toFixed(4)}°`],
        ["North Node", `${natal.northNode.toFixed(4)}°`],
        ["South Node", `${natal.southNode.toFixed(4)}°`],
        ["Lunar Phase", `${natal.lunarPhase.toFixed(2)}°`],
      ],
    );

  const cuspRows = natal.houseCusps.map((c, i) => [
    `House ${i + 1}`,
    `${c.toFixed(1)}°`,
  ]);
  md += "### House Cusps (Placidus)\n\n" + mdTable(["House", "Cusp"], cuspRows);

  if (natal.wholeSignHouseCusps?.length) {
    const wsRows = natal.wholeSignHouseCusps.map((c, i) => [
      `House ${i + 1}`,
      `${c.toFixed(1)}°`,
    ]);
    md +=
      "### House Cusps (Whole Sign)\n\n" + mdTable(["House", "Cusp"], wsRows);
  }

  return md;
}

function markdownDailyFitExport(entries) {
  if (!entries.length) return "_No Daily Fit data._\n";
  if (entries.length === 1) {
    return markdownDailyFit(entries[0].data.dailyFit, entries[0].label);
  }

  let md = `## Daily Fit — ${entries.length}-day export\n\n`;
  md += markdownDailyFitSummaryTable(entries);
  md += "\n---\n\n";
  for (const entry of entries) {
    md += markdownDailyFit(entry.data.dailyFit, entry.label);
    md += "\n---\n\n";
  }
  return md;
}

function markdownDailyFitSummaryTable(entries) {
  const rows = entries.map(({ label, data }) => {
    const p = data?.dailyFit?.payload;
    if (!p) return [label, "—", "—", "—", "—", "—"];
    const top3 = (p.essenceProfile?.visibleCategories || [])
      .map((e) => e.category)
      .join(", ");
    const palette = (p.dailyPalette?.colours || [])
      .map((c) => c.name)
      .join(", ");
    return [
      label,
      p.tarotCard?.name || "—",
      top3 || "—",
      palette || "—",
      fmtNum(p.vibrancy),
      fmtNum(p.contrast),
    ];
  });
  return (
    "### Summary\n\n" +
    mdTable(
      ["Day", "Tarot", "Essence top 3", "Palette", "Vibrancy", "Contrast"],
      rows,
    )
  );
}

function markdownTraceExport(entries) {
  if (!entries.length) return "_No trace / diagnostics data._\n";
  if (entries.length === 1) {
    return markdownTrace(
      entries[0].data.dailyFit?.diagnostics,
      entries[0].label,
    );
  }
  let md = `## Trace & Provenance — ${entries.length}-day export\n\n`;
  for (const entry of entries) {
    md += markdownTrace(entry.data.dailyFit?.diagnostics, entry.label);
    md += "\n---\n\n";
  }
  return md;
}

function markdownVerdictsExport(entries) {
  if (!entries.length) return "_No verdict rows._\n";
  if (entries.length === 1) {
    return markdownVerdicts(entries[0].data.verdicts, entries[0].label);
  }
  let md = `## Verdicts — ${entries.length}-day export\n\n`;
  for (const entry of entries) {
    md += markdownVerdicts(entry.data.verdicts, entry.label);
    md += "\n---\n\n";
  }
  return md;
}

function markdownDailyFit(dailyFit, dayLabel = null) {
  if (!dailyFit?.payload) return "_No Daily Fit data._\n";
  const p = dailyFit.payload;
  let md = dayLabel ? `## Daily Fit — ${dayLabel}\n\n` : "## Daily Fit\n\n";

  md += "### Tarot\n\n";
  md += `- **Card:** ${p.tarotCard?.name || "Unknown"}\n\n`;

  if (p.styleEditVariant) {
    md += "### Style Edit\n\n";
    md += `- **Title:** ${p.styleEditVariant.title || ""}\n`;
    if (p.styleEditVariant.dailyRitual)
      md += `\n${p.styleEditVariant.dailyRitual}\n\n`;
    if (p.styleEditVariant.wardrobeReflection) {
      md += `\n_${p.styleEditVariant.wardrobeReflection}_\n\n`;
    }
  }

  const paletteRows = (p.dailyPalette?.colours || []).map((c) => [
    c.name,
    c.hexValue,
    c.role,
  ]);
  md +=
    "### Daily Palette\n\n" + mdTable(["Colour", "Hex", "Role"], paletteRows);

  md +=
    "### Scales\n\n" +
    mdTable(
      ["Scale", "Value"],
      [
        ["Vibrancy", fmtNum(p.vibrancy)],
        ["Contrast", fmtNum(p.contrast)],
        ["Metal tone", fmtNum(p.metalTone)],
      ],
    );

  if (
    p.essenceProfile?.allScores?.length ||
    p.essenceProfile?.visibleCategories?.length
  ) {
    const top3 = new Set(
      (p.essenceProfile.visibleCategories || []).map((e) => e.category),
    );
    const scoreByCategory = Object.fromEntries(
      (p.essenceProfile.allScores || []).map((e) => [e.category, e.score]),
    );
    const anchorByCategory = Object.fromEntries(
      (p.essenceProfile.chartAnchorScores || []).map((e) => [e.category, e.score]),
    );
    const hasAnchor = (p.essenceProfile.chartAnchorScores || []).length > 0;
    const essenceRows = STYLE_ESSENCE_CATEGORIES.map((category) => {
      const row = [
        category.toUpperCase(),
        `${((scoreByCategory[category] ?? 0) * 100).toFixed(1)}%`,
      ];
      if (hasAnchor) {
        row.push(
          anchorByCategory[category] != null
            ? `${(anchorByCategory[category] * 100).toFixed(1)}%`
            : "—",
        );
      }
      row.push(top3.has(category) ? "top 3 today" : "");
      return row;
    }).sort((a, b) => parseFloat(b[1]) - parseFloat(a[1]));
    const headers = hasAnchor
      ? ["Category", "Today", "Chart anchor", ""]
      : ["Category", "Score", ""];
    md +=
      "### Style Essence (14 categories)\n\n" +
      (hasAnchor
        ? "_Today's outside energy vs chart anchor. Top 3 today = adapt signal._\n\n"
        : "") +
      mdTable(headers, essenceRows);
  }

  if (p.silhouetteProfile) {
    const sp = p.silhouetteProfile;
    md +=
      "### Silhouette Profile\n\n" +
      mdTable(
        ["Axis", "Value"],
        [
          ["Masculine / Feminine", fmtNum(sp.masculineFeminine)],
          ["Angular / Rounded", fmtNum(sp.angularRounded)],
          ["Structured / Relaxed", fmtNum(sp.structuredDraped)],
        ],
      );
  }

  if (p.vibeBreakdown) {
    const ranked = rankedVibeEntries(p.vibeBreakdown);
    const vibeRows = ranked.map(({ key, value }) => [
      vibeEnergyDisplayName(key),
      String(value),
      `${((value / 21.0) * 100).toFixed(1)}%`,
    ]);
    md +=
      "### Vibe Breakdown (6 energies)\n\n" +
      mdTable(["Energy", "Points", "Share"], vibeRows);
    if (ranked[0]) {
      md += `**Dominant:** ${vibeEnergyDisplayName(ranked[0].key)}`;
      if (ranked[1])
        md += ` · **Secondary:** ${vibeEnergyDisplayName(ranked[1].key)}`;
      md += "\n\n";
    }
  }

  if (p.dailyTextures?.length) {
    md += `### Daily Textures\n\n${p.dailyTextures.map((t) => `- ${t}`).join("\n")}\n\n`;
  }
  if (p.dailyPattern) {
    md += `### Daily Pattern\n\n- ${p.dailyPattern}\n\n`;
  }

  if (p.dominantTransits?.length) {
    const transitRows = p.dominantTransits.map((t) => [
      t.transitPlanet,
      t.natalPlanet,
      t.aspect,
      `${(t.strength * 100).toFixed(0)}%`,
    ]);
    md +=
      "### Dominant Transits\n\n" +
      mdTable(["Transit", "Natal", "Aspect", "Strength"], transitRows);
  }

  if (p.lunarContext) {
    const lc = p.lunarContext;
    md +=
      "### Lunar Context\n\n" +
      mdTable(
        ["Field", "Value"],
        [
          ["Phase", lc.phaseName],
          ["Waxing / Waning", lc.isWaxing ? "Waxing" : "Waning"],
          ["Element", lc.element],
          ["Phase degrees", `${lc.phaseDegrees.toFixed(1)}°`],
        ],
      );
  }

  md += "### Full Daily Fit payload (JSON)\n\n" + mdJsonBlock(p);
  return md;
}

function markdownVerdicts(verdicts, dayLabel = null) {
  let md = dayLabel ? `## Verdicts — ${dayLabel}\n\n` : "## Verdicts\n\n";
  if (!verdicts?.length) {
    md += "_No verdict rows for this run._\n";
    return md;
  }

  const rows = verdicts.map((v) => {
    const icon =
      v.status === "pass"
        ? "pass"
        : v.status === "partial"
          ? "partial"
          : "fail";
    return [v.id, icon, v.expected, v.actual, v.docRef || ""];
  });
  md += mdTable(["ID", "Status", "Expected", "Actual", "Doc ref"], rows);
  return md;
}

function markdownTrace(diag, dayLabel = null) {
  if (!diag)
    return dayLabel
      ? `## Trace — ${dayLabel}\n\n_No trace data._\n`
      : "_No trace / diagnostics data._\n";
  let md = dayLabel
    ? `## Trace & Provenance — ${dayLabel}\n\n`
    : "## Trace & Provenance\n\n";

  if (diag.sourceContributions) {
    const sc = diag.sourceContributions;
    md +=
      "### Source Contributions\n\n" +
      mdTable(
        ["Source", "Share"],
        [
          ["Natal", pct(sc.natalShare)],
          ["Transits", pct(sc.transitShare)],
          ["Lunar", pct(sc.lunarShare)],
          ["Progressed", pct(sc.progressedShare)],
          ["Current Sun", pct(sc.currentSunShare)],
        ],
      );
  }

  if (diag.rawEnergyScores) {
    md += "### Raw Energy Scores\n\n" + mdObjectTable(diag.rawEnergyScores);
  }
  if (diag.postMultiplierScores) {
    md +=
      `### ${postMultiplierScoresLabel(diag)}\n\n` +
      mdObjectTable(diag.postMultiplierScores);
  }
  if (diag.rawAxisScores) {
    md += "### Raw Axis Scores\n\n" + mdObjectTable(diag.rawAxisScores);
  }

  if (diag.tarotCardScores?.length) {
    const sorted = [...diag.tarotCardScores]
      .sort((a, b) => b.totalScore - a.totalScore)
      .slice(0, 15);
    const rows = sorted.map((s) => [
      s.cardName + (s.cardName === diag.selectedTarotCard ? " ★" : ""),
      s.vibeScore.toFixed(3),
      s.axisScore.toFixed(3),
      s.transitBoost.toFixed(3),
      s.recencyPenalty.toFixed(3),
      s.totalScore.toFixed(3),
    ]);
    md += "### Tarot Card Scores (Top 15)\n\n";
    md += `- **Selected:** ${diag.selectedTarotCard || "—"}\n`;
    md += `- **Variant index:** ${diag.variantRotationIndex ?? "—"}\n`;
    md += `- **Style edit:** ${diag.selectedStyleEdit || "—"}\n\n`;
    md += mdTable(
      ["Card", "Vibe", "Axis", "Transit", "Recency", "Total"],
      rows,
    );
  }

  if (diag.paletteSelectionTrace) {
    const pt = diag.paletteSelectionTrace;
    md += "### Palette Selection Trace\n\n";
    md += `- **Candidates:** ${pt.candidateCount}\n`;
    md += `- **Strategy:** ${pt.selectionStrategy || "dramaSlots"}\n`;
    md += `- **Diversity swap:** ${pt.diversitySwapApplied ? "Yes" : "No"}\n`;
    if (pt.coreAnchorSwapApplied) md += `- **Core anchor swap:** Yes\n`;
    md += "\n";
    const rows = (pt.topScoredColours || []).map((c) => [
      c.name,
      c.role,
      c.score.toFixed(4),
    ]);
    md += mdTable(["Colour", "Role", "Score"], rows);
  }

  if (diag.textureSelectionTrace?.scores?.length) {
    const rows = diag.textureSelectionTrace.scores.map((s) => [
      s.name,
      s.score.toFixed(4),
    ]);
    md += "### Texture Trace\n\n" + mdTable(["Texture", "Score"], rows);
  }

  if (diag.patternDecision) {
    const pd = diag.patternDecision;
    md +=
      "### Pattern Decision\n\n" +
      mdTable(
        ["Field", "Value"],
        [
          ["Gate passed", pd.gateCheckPassed ? "Yes" : "No"],
          ["Visibility", pd.visibilityValue.toFixed(3)],
          ["Dominant energy", pd.dominantEnergy],
          ["Selected pattern", pd.selectedPattern || "None"],
        ],
      );
  }

  for (const [label, key, envKey] of [
    ["Vibrancy", "vibrancyTrace", "vibrancy"],
    ["Contrast", "contrastTrace", "contrast"],
    ["Metal Tone", "metalToneTrace", "metalTone"],
  ]) {
    const trace = diag[key];
    if (!trace) continue;
    const rows = [
      ["Blueprint baseline", trace.blueprintBaseline.toFixed(3)],
      ["Modulation", trace.modulation.toFixed(3)],
      ["Final (absolute)", trace.finalValue.toFixed(3)],
    ];
    const env = diag.personalScalePresentation?.[envKey];
    if (env) {
      rows.push(
        ["Personal floor", env.floor.toFixed(3)],
        ["Personal ceiling", env.ceiling.toFixed(3)],
        ["Personal baseline", env.baseline.toFixed(3)],
        ["Display position", env.displayPosition.toFixed(3)],
        ["Baseline tick position", env.baselinePosition.toFixed(3)],
      );
    }
    md += `### ${label} Derivation\n\n`;
    md += mdTable(["Field", "Value"], rows);
  }

  if (diag.narrativeTrace) {
    const nt = diag.narrativeTrace;
    md += "### Narrative Resolution\n\n";
    md += mdTable(
      ["Field", "Value"],
      [
        ["Anchor top-3", (nt.anchorTop3 || []).join(", ")],
        ["Weather top-3", (nt.weatherTop3 || []).join(", ")],
        ["Overlap count", String(nt.overlapCount)],
        ["Relationship", nt.chosenRelationship],
        ["Template key", nt.templateKey],
        ["Silhouette Δ M/F", nt.silhouetteDeltaMF != null ? nt.silhouetteDeltaMF.toFixed(3) : "—"],
        ["Silhouette Δ A/R", nt.silhouetteDeltaAR != null ? nt.silhouetteDeltaAR.toFixed(3) : "—"],
        ["Silhouette Δ S/D", nt.silhouetteDeltaSD != null ? nt.silhouetteDeltaSD.toFixed(3) : "—"],
      ],
    );
  }

  if (diag.narrativeIntentTrace || diag.narrativeCoherenceTrace) {
    md += "### Narrative selection\n\n";
    const nit = diag.narrativeIntentTrace;
    const nct = diag.narrativeCoherenceTrace;
    const pt = diag.paletteSelectionTrace;
    if (nit) {
      md += `- Relationship: ${nit.relationship}\n`;
      md += `- Anchor: ${(nit.anchorTop3 || []).join(", ")}\n`;
      md += `- Weather: ${(nit.weatherTop3 || []).join(", ")}\n`;
      if (nit.coherenceGap) md += `- Coherence gap: ${nit.coherenceGap}\n`;
    }
    if (pt?.narrativeBiasApplied) {
      const slotCount = pt.statementSlotsUsed ?? "—";
      const accentMatch = nct?.paletteAccentRoleMatch ? "pass" : "fail";
      md += `- Palette bias: applied (${slotCount} statement slot${slotCount === 1 ? "" : "s"}, accent role match: ${accentMatch})\n`;
    } else {
      md += `- Palette bias: not applied\n`;
    }
    if (nct) {
      md += `- Tarot variant: ${nct.tarotVariantScored ? "scored (not rotation)" : "rotation fallback"}\n`;
      md += `- Coherence: ${nct.overallPass ? "pass" : "fail (palette statement slots: " + nct.paletteStatementSlotCount + ")"}\n`;
    }
    md += "\n";
  }

  if (diag.essenceConflictTrace?.suppressions?.length) {
    md += "### Essence conflict resolution\n\n";
    for (const s of diag.essenceConflictTrace.suppressions) {
      md += `- **${s.suppressedCategory.toUpperCase()}** (${(s.suppressedScore * 100).toFixed(1)}%) suppressed — conflicts with **${s.keptCategory.toUpperCase()}**`;
      if (s.replacementCategory) {
        md += ` → promoted **${s.replacementCategory.toUpperCase()}** (${((s.replacementScore || 0) * 100).toFixed(1)}%)`;
      }
      md += `\n`;
    }
    md += "\n";
  }

  if (diag.narrativeBridgeTrace) {
    md += "### Narrative bridge\n\n";
    const bt = diag.narrativeBridgeTrace;
    md += `- Selected: ${bt.selectedCardName} / ${bt.selectedVariantTitle} (variant index ${bt.selectedVariantIndex})\n`;
    md += `- Variant similarity: ${bt.variantBridgeSimilarity.toFixed(2)}\n`;
    md += `- Best similarity in pool: ${bt.bestVariantSimilarityInPool.toFixed(2)}\n`;
    md += `- Pair margin: ${bt.bridgeMargin.toFixed(3)}\n`;
    if (bt.contrastWeatherWins != null) {
      md += `- Contrast weather wins: ${bt.contrastWeatherWins ? "yes" : "no"}\n`;
    }
    md += `- Bridge pass: ${bt.bridgePass ? "pass" : "fail"}\n`;
    md += `- Funnel cards: ${bt.funnelCardCount}, pairs evaluated: ${bt.pairsEvaluated}\n`;
    md += "\n";
  }

  if (diag.calibrationSnapshot) {
    md += formatCalibrationSnapshotMarkdown(diag.calibrationSnapshot);
  }

  md += "### Full Diagnostic JSON\n\n" + mdJsonBlock(diag);
  return md;
}

function mdTable(headers, rows) {
  if (!rows.length) return "_No data_\n\n";
  const head = `| ${headers.join(" | ")} |`;
  const sep = `| ${headers.map(() => "---").join(" | ")} |`;
  const body = rows
    .map((r) => `| ${r.map((c) => mdCell(c)).join(" | ")} |`)
    .join("\n");
  return `${head}\n${sep}\n${body}\n\n`;
}

function mdObjectTable(obj) {
  const rows = Object.entries(obj).map(([k, v]) => [
    k,
    typeof v === "number" ? v.toFixed(4) : String(v),
  ]);
  return mdTable(["Key", "Value"], rows);
}

function mdCell(value) {
  return String(value ?? "")
    .replace(/\|/g, "\\|")
    .replace(/\n/g, " ");
}

function mdJsonBlock(obj) {
  return "```json\n" + JSON.stringify(obj, null, 2) + "\n```\n\n";
}

function fmtNum(n) {
  return typeof n === "number" ? n.toFixed(3) : "—";
}

function pct(n) {
  return typeof n === "number" ? `${(n * 100).toFixed(1)}%` : "—";
}

// ── Vibe & essence display (Inspector) ──

/** Six Stage 1 vibe energies (21-point budget). Not the 14-category Style Essence radar. */
const VIBE_ENERGY_KEYS = [
  "classic",
  "playful",
  "romantic",
  "utility",
  "drama",
  "edge",
];

/** All 14 Style Essence categories (matches StyleEssenceCategory in Swift). */
const STYLE_ESSENCE_CATEGORIES = [
  "edgy",
  "romantic",
  "classic",
  "utility",
  "drama",
  "playful",
  "polished",
  "effortless",
  "sensual",
  "magnetic",
  "grounded",
  "eclectic",
  "minimal",
  "maximalist",
];

function vibeEnergyDisplayName(key) {
  if (key === "edge") return "Edge";
  return key.charAt(0).toUpperCase() + key.slice(1);
}

function rankedVibeEntries(vibeBreakdown) {
  if (!vibeBreakdown) return [];
  return VIBE_ENERGY_KEYS.map((key) => ({
    key,
    value: Number(vibeBreakdown[key]) || 0,
  })).sort((a, b) => b.value - a.value);
}

function buildVibeBreakdownHtml(vibeBreakdown, allowDrill = false) {
  if (!vibeBreakdown) return "";
  const drill = allowDrill ? "drillable" : "";
  const ranked = rankedVibeEntries(vibeBreakdown);
  const dominant = ranked[0]?.key;
  const secondary = ranked[1]?.key;
  let html =
    '<div class="subsection"><div class="subsection-title">Vibe Breakdown (6 energies · 21 pts)</div>';
  if (dominant) {
    html += `<p class="text-muted" style="margin:0 0 8px">Dominant: <strong>${esc(vibeEnergyDisplayName(dominant))}</strong>`;
    if (secondary)
      html += ` · Secondary: <strong>${esc(vibeEnergyDisplayName(secondary))}</strong>`;
    html += ` · Total: ${Number(vibeBreakdown.total ?? ranked.reduce((s, e) => s + e.value, 0))}</p>`;
  }
  for (const { key, value } of ranked) {
    const markers = [];
    if (key === dominant) markers.push("dominant");
    if (key === secondary) markers.push("secondary");
    const suffix = markers.length ? ` (${markers.join(", ")})` : "";
    html += `<div class="scale-bar-container ${drill}" data-drill="vibe:${key}">
      <span class="scale-bar-label">${vibeEnergyDisplayName(key)}${suffix}</span>
      <div class="scale-bar-track"><div class="scale-bar-fill" style="width:${Math.max(0, Math.min(100, (value / 21.0) * 100))}%"></div></div>
      <span class="scale-bar-value">${value.toFixed(1)} / 21</span>
    </div>`;
  }
  html += "</div>";
  return html;
}

function buildEssenceProfileHtml(essenceProfile, allowDrill = true) {
  if (!essenceProfile) return "";
  const drill = allowDrill ? "drillable" : "";
  const top3 = new Set(
    (essenceProfile.visibleCategories || []).map((e) => e.category),
  );
  const scoreByCategory = Object.fromEntries(
    (essenceProfile.allScores || []).map((e) => [e.category, e.score]),
  );
  const anchorByCategory = Object.fromEntries(
    (essenceProfile.chartAnchorScores || []).map((e) => [e.category, e.score]),
  );
  const anchorTop3 = new Set(
    (essenceProfile.chartAnchorScores || [])
      .slice()
      .sort((a, b) => b.score - a.score)
      .slice(0, 3)
      .map((e) => e.category),
  );
  const hasAnchor = (essenceProfile.chartAnchorScores || []).length > 0;
  const missing = STYLE_ESSENCE_CATEGORIES.filter(
    (c) => scoreByCategory[c] == null,
  );
  const allScores = STYLE_ESSENCE_CATEGORIES.map((category) => ({
    category,
    score: scoreByCategory[category] ?? 0,
    anchor: anchorByCategory[category] ?? null,
  })).sort((a, b) => b.score - a.score);

  let html =
    '<div class="subsection"><div class="subsection-title">Style Essence (14 categories)</div>';
  if (hasAnchor) {
    html += '<p class="text-muted" style="margin-bottom:8px">Today\'s outside energy (top 3 ★) vs your chart anchor (◆). Adapt when they diverge.</p>';
  }
  if (missing.length) {
    html += `<p class="text-muted" style="color:var(--warn,#c9a227)">Missing scores: ${esc(missing.join(", "))}</p>`;
  }
  html +=
    '<table class="data-table"><thead><tr><th>Category</th><th>Today</th>';
  if (hasAnchor) html += '<th>Chart anchor</th>';
  html += '<th></th></tr></thead><tbody>';
  for (const entry of allScores) {
    const isTop = top3.has(entry.category);
    const isAnchorTop = anchorTop3.has(entry.category);
    const diverges = hasAnchor && isTop !== isAnchorTop && (isTop || isAnchorTop);
    const rowStyle = isTop ? ' style="background:rgba(124,111,247,0.12)"' : "";
    html += `<tr${rowStyle} class="${drill}" data-drill="essence:${entry.category}">
      <td>${esc(entry.category.toUpperCase())}</td>
      <td>${(entry.score * 100).toFixed(1)}%</td>`;
    if (hasAnchor) {
      html += `<td>${entry.anchor != null ? `${(entry.anchor * 100).toFixed(1)}%` : '—'}</td>`;
    }
    html += `<td>${isTop ? "★ today" : ""}${isAnchorTop ? " ◆ chart" : ""}${diverges ? " · adapt" : ""}</td>`;
    html += '</tr>';
  }
  html += "</tbody></table></div>";
  return html;
}

// ── Helpers ──

function signFromDeg(deg) {
  const idx = Math.floor(deg / 30) + 1;
  return `${ZODIAC_GLYPHS[idx] || ""} ${ZODIAC_SIGNS[idx] || ""}`;
}

function scaleBar(label, value, drillKey, leftLabel, rightLabel) {
  const pct = Math.max(0, Math.min(100, (value || 0) * 100));
  const drillAttr = drillKey ? ` data-drill="${drillKey}"` : "";
  const cls = drillKey ? " drillable" : "";
  let html = `<div class="scale-bar-container">`;
  if (leftLabel)
    html += `<span class="scale-bar-label" style="font-size:10px">${leftLabel}</span>`;
  else html += `<span class="scale-bar-label">${label}</span>`;
  html += `<div class="scale-bar-track"><div class="scale-bar-fill" style="width:${pct}%"></div></div>`;
  html += `<span class="scale-bar-value${cls}"${drillAttr}>${(value || 0).toFixed(3)}</span>`;
  if (rightLabel)
    html += `<span class="scale-bar-label" style="font-size:10px;text-align:left">${rightLabel}</span>`;
  html += "</div>";
  return html;
}

function accordion(title, contentFn) {
  return `<div class="accordion-item">
    <div class="accordion-header">${title} <span class="toggle-icon">▶</span></div>
    <div class="accordion-body">${contentFn()}</div>
  </div>`;
}

function signMultiplierPolicyFromDiagnostics(diag) {
  return diag?.calibrationSnapshot?.signMultiplierPolicy ?? null;
}

function signMultipliersAppliedToDailyVibe(diag) {
  const attr = diag?.stage1Attribution;
  if (typeof attr?.signMultipliersAppliedToDailyVibe === "boolean") {
    return attr.signMultipliersAppliedToDailyVibe;
  }
  const policy = signMultiplierPolicyFromDiagnostics(diag);
  if (typeof policy?.applyToDailyVibe === "boolean") {
    return policy.applyToDailyVibe;
  }
  return true;
}

function postMultiplierScoresLabel(diag) {
  return signMultipliersAppliedToDailyVibe(diag)
    ? "Post-Multiplier Energy Scores"
    : "Pre-normalisation scores (sign multipliers not applied to daily vibe)";
}

function postMultiplierShortLabel(diag) {
  return signMultipliersAppliedToDailyVibe(diag) ? "Post-mult" : "Pre-norm (daily path)";
}

function payloadEnergyScoresSection(diag, options = {}) {
  const { highlight = null, includeRaw = false } = options;
  let html = "";
  if (includeRaw) {
    html += '<p style="margin-top:8px"><strong>Raw (sky accumulation):</strong></p>';
    html += renderEnergyScoresTable(diag?.rawEnergyScores, highlight);
  }
  html += `<p style="margin-top:8px"><strong>${esc(postMultiplierScoresLabel(diag))}:</strong></p>`;
  html += renderEnergyScoresTable(diag?.postMultiplierScores, highlight);
  return html;
}

function renderChartAnchorMultipliersTable(mults) {
  if (!mults || !Object.keys(mults).length) return "";
  let html =
    '<details style="margin:6px 0"><summary><strong>Chart-anchor Sun-sign multipliers</strong></summary>';
  html += renderChartAnchorMultipliersBody(mults);
  html += "</details>";
  return html;
}

function renderChartAnchorMultipliersBody(mults) {
  if (!mults || !Object.keys(mults).length) return "";
  let html =
    '<p style="font-size:0.85em;margin:4px 0">Reference frame for chartVibeProfile — not applied to daily sky payload bars.</p>';
  html += '<table class="data-table"><thead><tr><th>Energy</th><th>Multiplier</th></tr></thead><tbody>';
  for (const [k, v] of Object.entries(mults).sort((a, b) => b[1] - a[1])) {
    html += `<tr><td>${esc(vibeEnergyDisplayName(k))}</td><td>${Number(v).toFixed(3)}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function formatCalibrationSnapshotHtml(cs) {
  if (!cs) return "N/A";
  let html = "";
  if (cs.dailyFitEngineId) {
    html += `<div style="margin-bottom:8px"><strong>Engine:</strong> ${esc(cs.dailyFitEngineId)}</div>`;
  }
  if (cs.fingerprint) {
    html += `<div style="margin-bottom:8px"><strong>Fingerprint:</strong> <code>${esc(cs.fingerprint)}</code></div>`;
  }
  if (cs.signMultiplierPolicy) {
    const daily = cs.signMultiplierPolicy.applyToDailyVibe ? "ON" : "OFF";
    const anchor = cs.signMultiplierPolicy.applyToChartAnchor ? "ON" : "OFF";
    html += `<div style="margin-bottom:8px"><strong>Sign multiplier policy:</strong> daily vibe ${daily}, chart anchor ${anchor}</div>`;
  }
  if (cs.sourceWeights)
    html += "<strong>Source Weights:</strong>" + kv(cs.sourceWeights);
  if (cs.selectionWeights)
    html += "<strong>Selection Weights:</strong>" + kv(cs.selectionWeights);
  if (cs.axisTuning)
    html += "<strong>Axis Tuning:</strong>" + kv(cs.axisTuning);
  if (cs.stage2Sensitivity)
    html += "<strong>Stage 2 Sensitivity:</strong>" + kv(cs.stage2Sensitivity);
  return html || "N/A";
}

function formatCalibrationSnapshotMarkdown(cs) {
  if (!cs) return "";
  let md = "### Calibration Snapshot\n\n";
  if (cs.dailyFitEngineId) md += `- **Engine:** ${cs.dailyFitEngineId}\n`;
  if (cs.fingerprint) md += `- **Fingerprint:** \`${cs.fingerprint}\`\n`;
  if (cs.signMultiplierPolicy) {
    const daily = cs.signMultiplierPolicy.applyToDailyVibe ? "ON" : "OFF";
    const anchor = cs.signMultiplierPolicy.applyToChartAnchor ? "ON" : "OFF";
    md += `- **Sign multiplier policy:** daily vibe ${daily}, chart anchor ${anchor}\n`;
  }
  if (cs.dailyFitEngineId || cs.fingerprint) md += "\n";
  if (cs.sourceWeights)
    md += "**Source weights**\n\n" + mdObjectTable(cs.sourceWeights);
  if (cs.selectionWeights)
    md += "**Selection weights**\n\n" + mdObjectTable(cs.selectionWeights);
  if (cs.axisTuning) md += "**Axis tuning**\n\n" + mdObjectTable(cs.axisTuning);
  if (cs.stage2Sensitivity)
    md += "**Stage 2 sensitivity**\n\n" + mdObjectTable(cs.stage2Sensitivity);
  return md;
}

function kv(obj) {
  if (!obj) return "N/A";
  let html = '<table class="data-table"><tbody>';
  for (const [k, v] of Object.entries(obj)) {
    html += `<tr><td>${esc(k)}</td><td>${typeof v === "number" ? v.toFixed(4) : esc(String(v))}</td></tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function esc(s) {
  if (!s) return "";
  const d = document.createElement("div");
  d.textContent = s;
  return d.innerHTML;
}
function showLoading(v) {
  document.getElementById("loading").classList.toggle("hidden", !v);
}
function showError(msg) {
  const el = document.getElementById("error-banner");
  el.textContent = msg;
  el.classList.remove("hidden");
}
function hideError() {
  document.getElementById("error-banner").classList.add("hidden");
}
