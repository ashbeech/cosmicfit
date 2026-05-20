// Cosmic Fit Inspector — Frontend
'use strict';

import {
  deleteProfile,
  getProfile,
  listProfiles,
  newProfileId,
  putProfile,
  readSession,
  writeSession
} from './storage.js';

const ZODIAC_SIGNS = ['','Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];
const ZODIAC_GLYPHS = ['','♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];

let state = { data: null, compareCache: {}, compareDayCount: 2, presets: [], lastBirthFingerprint: null };

const COMPARE_MIN_DAYS = 2;
const COMPARE_MAX_DAYS = 14;
let persistTimer = null;
let restoringSession = false;

// UK calendar dates (dd/mm/yyyy) — API still uses ISO yyyy-mm-dd
function formatDateUK(isoDate) {
  const [y, m, d] = isoDate.split('-');
  if (!y || !m || !d) return '';
  return `${d}/${m}/${y}`;
}

function parseDateUK(text) {
  const raw = (text || '').trim();
  if (!raw) return null;
  const uk = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (uk) {
    const day = parseInt(uk[1], 10);
    const month = parseInt(uk[2], 10);
    const year = parseInt(uk[3], 10);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    const iso = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const check = new Date(`${iso}T12:00:00Z`);
    if (check.getUTCFullYear() !== year || check.getUTCMonth() + 1 !== month || check.getUTCDate() !== day) {
      return null;
    }
    return iso;
  }
  const iso = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (iso) return raw;
  return null;
}

function setResolvedLocation(result) {
  const label = result.label || document.getElementById('location-input').value.trim();
  document.getElementById('location-input').value = label;
  document.getElementById('latitude').value = String(result.latitude);
  document.getElementById('longitude').value = String(result.longitude);
  document.getElementById('latitude').dataset.resolvedLabel = label;
  document.getElementById('timezone-id').value = result.timeZoneId;
  document.getElementById('tz-chip').textContent = result.timeZoneId;
  const chip = document.getElementById('location-coords');
  chip.textContent = `${result.latitude.toFixed(4)}, ${result.longitude.toFixed(4)}`;
  chip.classList.remove('unresolved');
  schedulePersistSession();
}

function clearResolvedLocation() {
  document.getElementById('latitude').value = '';
  document.getElementById('longitude').value = '';
  delete document.getElementById('latitude').dataset.resolvedLabel;
  const chip = document.getElementById('location-coords');
  chip.textContent = 'Not resolved — pick a suggestion or Submit to geocode';
  chip.classList.add('unresolved');
  schedulePersistSession();
}

async function resolveBirthLocation() {
  const label = document.getElementById('location-input').value.trim();
  if (!label) throw new Error('Location is required');

  const latEl = document.getElementById('latitude');
  const lat = parseFloat(latEl.value);
  const lon = parseFloat(document.getElementById('longitude').value);
  if (latEl.dataset.resolvedLabel === label && Number.isFinite(lat) && Number.isFinite(lon)) {
    return {
      label,
      latitude: lat,
      longitude: lon,
      timeZoneId: document.getElementById('timezone-id').value
    };
  }

  const res = await fetch(`/api/geocode?q=${encodeURIComponent(label)}`);
  if (!res.ok) throw new Error(`Geocode failed (${res.status})`);
  const data = await res.json();
  if (!data.results?.length) {
    throw new Error(`Could not resolve coordinates for "${label}". Pick a location from the suggestions list.`);
  }
  const best = data.results[0];
  setResolvedLocation(best);
  return best;
}

// ── Session persistence ──

function readFormInputs() {
  const latEl = document.getElementById('latitude');
  const lat = parseFloat(latEl.value);
  const lon = parseFloat(document.getElementById('longitude').value);
  return {
    preset: document.getElementById('preset-select').value,
    birthDate: document.getElementById('birth-date').value,
    birthTime: document.getElementById('birth-time').value || '00:00',
    unknownTime: document.getElementById('unknown-time').checked,
    locationLabel: document.getElementById('location-input').value.trim(),
    latitude: Number.isFinite(lat) ? lat : null,
    longitude: Number.isFinite(lon) ? lon : null,
    timezoneId: document.getElementById('timezone-id').value,
    resolvedLocationLabel: latEl.dataset.resolvedLabel || '',
    targetDate: document.getElementById('target-date').value,
    compareToggle: document.getElementById('compare-toggle').checked,
    compareDayCount: getCompareDayCount(),
    activeProfileId: document.getElementById('saved-profile-select').value || ''
  };
}

function applyFormInputs(inputs, { persist = true, skipProfileSelect = false } = {}) {
  if (!inputs) return;
  restoringSession = true;

  document.getElementById('preset-select').value = inputs.preset || 'custom';
  document.getElementById('birth-date').value = inputs.birthDate || '';
  document.getElementById('birth-time').value = inputs.birthTime || '00:00';
  document.getElementById('unknown-time').checked = !!inputs.unknownTime;
  document.getElementById('target-date').value = inputs.targetDate || '';
  document.getElementById('compare-toggle').checked = !!inputs.compareToggle;
  state.compareDayCount = clampCompareDayCount(inputs.compareDayCount ?? COMPARE_MIN_DAYS);
  syncCompareDaysUI();

  if (inputs.locationLabel && Number.isFinite(inputs.latitude) && Number.isFinite(inputs.longitude)) {
    setResolvedLocation({
      label: inputs.locationLabel,
      latitude: inputs.latitude,
      longitude: inputs.longitude,
      timeZoneId: inputs.timezoneId || 'UTC'
    });
    if (inputs.resolvedLocationLabel) {
      document.getElementById('latitude').dataset.resolvedLabel = inputs.resolvedLocationLabel;
    }
  } else if (inputs.locationLabel) {
    document.getElementById('location-input').value = inputs.locationLabel;
    clearResolvedLocation();
  }

  if (!skipProfileSelect) {
    const sel = document.getElementById('saved-profile-select');
    const profileId = inputs.activeProfileId || '';
    if (profileId && [...sel.options].some(o => o.value === profileId)) {
      sel.value = profileId;
    } else {
      sel.value = '';
    }
  }

  updateDeleteProfileButton();
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
    applyFormInputs(session.inputs, { persist: false, skipProfileSelect: true });
    const sel = document.getElementById('saved-profile-select');
    const profileId = session.inputs.activeProfileId || '';
    if (profileId && [...sel.options].some(o => o.value === profileId)) {
      sel.value = profileId;
    }
    updateDeleteProfileButton();
    return;
  }

  const locLabel = document.getElementById('location-input').value.trim();
  if (locLabel) {
    document.getElementById('latitude').dataset.resolvedLabel = locLabel;
  }
  if (!document.getElementById('target-date').value) {
    setTodayUTC();
  }
}

function clearSavedProfileSelection() {
  document.getElementById('saved-profile-select').value = '';
  updateDeleteProfileButton();
  schedulePersistSession();
}

function updateDeleteProfileButton() {
  const id = document.getElementById('saved-profile-select').value;
  document.getElementById('delete-profile-btn').disabled = !id;
}

async function refreshSavedProfilesSelect(selectedId = null) {
  const sel = document.getElementById('saved-profile-select');
  const profiles = await listProfiles();
  const current = selectedId ?? sel.value;
  sel.innerHTML = '<option value="">—</option>';
  for (const p of profiles) {
    const opt = document.createElement('option');
    opt.value = p.id;
    opt.textContent = p.name;
    sel.appendChild(opt);
  }
  if (current && profiles.some(p => p.id === current)) {
    sel.value = current;
  } else if (!selectedId) {
    sel.value = '';
  }
  updateDeleteProfileButton();
}

async function onSavedProfileChange() {
  const id = document.getElementById('saved-profile-select').value;
  if (!id) {
    schedulePersistSession();
    updateDeleteProfileButton();
    return;
  }
  const profile = await getProfile(id);
  if (!profile?.inputs) return;
  applyFormInputs({
    ...profile.inputs,
    preset: 'custom',
    activeProfileId: id
  });
}

function birthFingerprintFromRequest(body) {
  const b = body.birth;
  return `${b.birthDate}|${b.birthTime}|${b.latitude}|${b.longitude}|${b.timeZoneId}|${b.unknownTime}`;
}

async function syncSavedProfileNameAfterSubmit() {
  const activeId = document.getElementById('saved-profile-select').value;
  if (!activeId || !state.data?.profile?.displayName) return;

  const profile = await getProfile(activeId);
  if (!profile) return;

  const displayName = state.data.profile.displayName;
  const inputs = readFormInputs();
  inputs.activeProfileId = activeId;
  inputs.preset = 'custom';

  if (profile.name === displayName && profile.inputs?.birthDate === inputs.birthDate) {
    return;
  }

  profile.name = displayName;
  profile.updatedAt = Date.now();
  profile.inputs = inputs;
  await putProfile(profile);
  await refreshSavedProfilesSelect(activeId);
}

async function saveCurrentProfile() {
  const inputs = readFormInputs();
  if (!inputs.birthDate || !inputs.locationLabel) {
    showError('Enter birth date and location before saving a profile.');
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
    showError('Submit first — the saved profile name matches the engine-generated display name.');
    return;
  }

  const name = state.data.profile.displayName;
  const profiles = await listProfiles();
  const activeId = document.getElementById('saved-profile-select').value;
  const existingByName = profiles.find(p => p.name === name);
  const existingById = activeId ? profiles.find(p => p.id === activeId) : null;
  const now = Date.now();

  let profile;
  if (existingById) {
    profile = {
      ...existingById,
      name,
      updatedAt: now,
      inputs: { ...inputs, preset: 'custom', activeProfileId: existingById.id }
    };
  } else if (existingByName) {
    profile = {
      ...existingByName,
      updatedAt: now,
      inputs: { ...inputs, preset: 'custom', activeProfileId: existingByName.id }
    };
  } else {
    profile = {
      id: newProfileId(),
      name,
      createdAt: now,
      updatedAt: now,
      inputs: { ...inputs, preset: 'custom', activeProfileId: '' }
    };
    profile.inputs.activeProfileId = profile.id;
  }

  await putProfile(profile);
  await refreshSavedProfilesSelect(profile.id);
  document.getElementById('saved-profile-select').value = profile.id;
  updateDeleteProfileButton();
  schedulePersistSession();
  document.getElementById('status-indicator').textContent = `Saved profile “${name}”`;
}

async function deleteSelectedProfile() {
  const id = document.getElementById('saved-profile-select').value;
  if (!id) return;
  const profile = await getProfile(id);
  await deleteProfile(id);
  document.getElementById('saved-profile-select').value = '';
  await refreshSavedProfilesSelect('');
  schedulePersistSession();
  document.getElementById('status-indicator').textContent = `Deleted profile “${profile?.name || 'profile'}”`;
}

// ── Init ──

document.addEventListener('DOMContentLoaded', async () => {
  await loadPresets();
  await refreshSavedProfilesSelect();
  wireEvents();
  syncCompareDaysUI();
  await restoreSession();
});

function setTodayUTC() {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  document.getElementById('target-date').value = formatDateUK(`${yyyy}-${mm}-${dd}`);
  schedulePersistSession();
}

async function loadPresets() {
  try {
    const res = await fetch('/api/presets');
    state.presets = await res.json();
    const sel = document.getElementById('preset-select');
    for (const p of state.presets) {
      const opt = document.createElement('option');
      opt.value = p.id;
      opt.textContent = `${p.label}`;
      sel.appendChild(opt);
    }
  } catch (e) { console.warn('Failed to load presets', e); }
}

function wireEvents() {
  document.getElementById('submit-btn').addEventListener('click', () => doSubmit(false));
  document.getElementById('today-btn').addEventListener('click', () => { setTodayUTC(); if (state.data) doSubmit(true); });
  document.getElementById('preset-select').addEventListener('change', () => { applyPreset(); schedulePersistSession(); });
  document.getElementById('saved-profile-select').addEventListener('change', onSavedProfileChange);
  document.getElementById('save-profile-btn').addEventListener('click', saveCurrentProfile);
  document.getElementById('delete-profile-btn').addEventListener('click', deleteSelectedProfile);
  document.getElementById('compare-toggle').addEventListener('change', () => { onCompareToggle(); schedulePersistSession(); });
  document.getElementById('compare-days-down').addEventListener('click', () => { onCompareDayCountChange(-1); });
  document.getElementById('compare-days-up').addEventListener('click', () => { onCompareDayCountChange(1); });
  document.getElementById('drawer-close').addEventListener('click', closeDrawer);
  document.getElementById('target-date').addEventListener('change', () => {
    schedulePersistSession();
    if (state.data) doSubmit(true);
  });
  document.getElementById('birth-time').addEventListener('change', () => {
    document.getElementById('preset-select').value = 'custom';
    clearSavedProfileSelection();
    schedulePersistSession();
  });
  document.getElementById('unknown-time').addEventListener('change', () => {
    document.getElementById('preset-select').value = 'custom';
    clearSavedProfileSelection();
    schedulePersistSession();
  });

  document.querySelectorAll('.card-header').forEach(h => {
    h.addEventListener('click', (e) => {
      if (e.target.closest('.export-btn')) return;
      const bodyId = h.dataset.toggle;
      const body = document.getElementById(bodyId);
      if (body) body.classList.toggle('collapsed');
      const icon = h.querySelector('.toggle-icon');
      if (icon) icon.textContent = body.classList.contains('collapsed') ? '▶' : '▼';
    });
  });

  document.querySelectorAll('[data-export]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      exportSection(btn.dataset.export);
    });
  });

  // Location autocomplete
  let debounce;
  const locInput = document.getElementById('location-input');
  const locResults = document.getElementById('location-results');
  locInput.addEventListener('input', () => {
    clearTimeout(debounce);
    debounce = setTimeout(async () => {
      const q = locInput.value.trim();
      if (q.length < 3) { locResults.classList.remove('visible'); return; }
      try {
        const res = await fetch(`/api/geocode?q=${encodeURIComponent(q)}`);
        const data = await res.json();
        locResults.innerHTML = '';
        if (data.results && data.results.length > 0) {
          for (const r of data.results) {
            const div = document.createElement('div');
            div.className = 'result-item';
            div.textContent = r.label;
            div.addEventListener('click', () => {
              setResolvedLocation(r);
              locResults.classList.remove('visible');
              document.getElementById('preset-select').value = 'custom';
              clearSavedProfileSelection();
            });
            locResults.appendChild(div);
          }
          locResults.classList.add('visible');
        } else { locResults.classList.remove('visible'); }
      } catch (e) { locResults.classList.remove('visible'); }
    }, 300);
  });

  document.addEventListener('click', (e) => {
    if (!e.target.closest('.location-group')) locResults.classList.remove('visible');
  });

  locInput.addEventListener('input', () => {
    document.getElementById('preset-select').value = 'custom';
    clearSavedProfileSelection();
    clearResolvedLocation();
  });

  for (const id of ['birth-date', 'birth-time']) {
    document.getElementById(id).addEventListener('input', () => {
      document.getElementById('preset-select').value = 'custom';
      clearSavedProfileSelection();
      schedulePersistSession();
    });
  }
  document.getElementById('target-date').addEventListener('input', schedulePersistSession);
}

function applyPreset() {
  const sel = document.getElementById('preset-select');
  const preset = state.presets.find(p => p.id === sel.value);
  if (!preset) return;

  const bd = preset.birthDateUTC.slice(0, 10);
  const bt = preset.birthDateUTC.slice(11, 16);
  document.getElementById('birth-date').value = formatDateUK(bd);
  document.getElementById('birth-time').value = bt;
  document.getElementById('unknown-time').checked = false;
  setResolvedLocation({
    label: preset.label,
    latitude: preset.latitude,
    longitude: preset.longitude,
    timeZoneId: preset.timeZoneId
  });
  clearSavedProfileSelection();
}

// ── Submit ──

async function doSubmit(dateOnly = false) {
  const btn = document.getElementById('submit-btn');
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
  const birthChanged = state.lastBirthFingerprint !== null && state.lastBirthFingerprint !== birthFp;
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
    document.getElementById('status-indicator').textContent = `⚠️ targetAge=${targetAge} (>50) — progressed chart accuracy may degrade`;
  }

  try {
    const t0 = performance.now();
    const res = await fetch('/api/inspect', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`${res.status}: ${text}`);
    }
    state.data = await res.json();
    state.lastBirthFingerprint = birthFp;
    clearCompareCache();
    const elapsed = ((performance.now() - t0) / 1000).toFixed(2);
    const mode = isDateOnlyChange ? 'date-only' : 'full';
    document.getElementById('status-indicator').textContent = `Computed in ${elapsed}s (${mode})`;
    render(state.data);
    schedulePersistSession();
    await syncSavedProfileNameAfterSubmit();

    if (document.getElementById('compare-toggle').checked) {
      await loadCompareRange();
    }
  } catch (e) {
    showError(e.message);
  } finally {
    btn.disabled = false;
    showLoading(false);
  }
}

function buildRequest({ composeBlueprint = true, resetTarotHistory = false, profileId = null } = {}) {
  const birthDateISO = parseDateUK(document.getElementById('birth-date').value);
  if (!birthDateISO) {
    throw new Error('Birth date must be dd/mm/yyyy (e.g. 11/12/1984)');
  }
  const targetDateISO = parseDateUK(document.getElementById('target-date').value);
  if (!targetDateISO) {
    throw new Error('Daily Fit target date must be dd/mm/yyyy');
  }

  const time = document.getElementById('birth-time').value || '00:00';
  const unknownTime = document.getElementById('unknown-time').checked;

  const latitude = parseFloat(document.getElementById('latitude').value);
  const longitude = parseFloat(document.getElementById('longitude').value);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new Error('Location coordinates are missing — pick a suggestion or Submit to geocode');
  }

  return {
    preset: document.getElementById('preset-select').value,
    birth: {
      birthDate: birthDateISO,
      birthTime: unknownTime ? null : time,
      unknownTime,
      latitude,
      longitude,
      timeZoneId: document.getElementById('timezone-id').value,
      locationLabel: document.getElementById('location-input').value.trim()
    },
    targetDate: targetDateISO,
    options: {
      composeBlueprint,
      includeProgressed: true,
      resetTarotHistory,
      profileId
    }
  };
}

// ── Compare ──

function clampCompareDayCount(n) {
  return Math.min(COMPARE_MAX_DAYS, Math.max(COMPARE_MIN_DAYS, Number(n) || COMPARE_MIN_DAYS));
}

function getCompareDayCount() {
  return clampCompareDayCount(state.compareDayCount);
}

function syncCompareDaysUI() {
  const toggle = document.getElementById('compare-toggle');
  const controls = document.getElementById('compare-span-controls');
  const valueEl = document.getElementById('compare-days-value');
  const count = getCompareDayCount();
  state.compareDayCount = count;
  if (valueEl) valueEl.textContent = String(count);
  if (controls) controls.classList.toggle('hidden', !toggle?.checked);
  const down = document.getElementById('compare-days-down');
  const up = document.getElementById('compare-days-up');
  if (down) down.disabled = count <= COMPARE_MIN_DAYS;
  if (up) up.disabled = count >= COMPARE_MAX_DAYS;
}

function clearCompareCache() {
  state.compareCache = {};
}

function targetDateISO() {
  return parseDateUK(document.getElementById('target-date').value);
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
  if (!document.getElementById('compare-toggle').checked || !state.data) return false;
  const range = getCompareDateRange();
  if (range.length < 2) return false;
  return range.slice(1).every(iso => !!state.compareCache[iso]);
}

function inspectDataForCompareDate(iso) {
  const target = targetDateISO();
  if (iso === target) return state.data;
  return state.compareCache[iso] || null;
}

function compareCarouselHtml(paneHtmlFns) {
  const dates = getCompareDateRange();
  let html = '<div class="compare-split" role="region" aria-label="Day compare carousel">';
  paneHtmlFns.forEach((paneHtmlFn, i) => {
    const iso = dates[i];
    const label = formatDateUK(iso);
    const isTarget = i === 0;
    const paneCls = isTarget ? 'compare-pane compare-pane-target' : 'compare-pane compare-pane-forward';
    const prefix = isTarget ? 'Target · ' : '';
    html += `<div class="${paneCls}">
      <div class="compare-pane-label">${prefix}${esc(label)} UTC</div>
      <div class="compare-pane-content">${paneHtmlFn()}</div>
    </div>`;
  });
  html += '</div>';
  return html;
}

function mountCompareSection(bodyId, { buildPanes, staticNote = null }) {
  const el = document.getElementById(bodyId);
  const panes = buildPanes();
  const targetPaneHtml = panes[0]?.html ?? (() => '');

  if (staticNote && compareActive()) {
    el.innerHTML = `<p class="compare-static-note">${staticNote}</p>${targetPaneHtml()}`;
  } else if (compareActive() && panes.length > 1) {
    el.innerHTML = compareCarouselHtml(panes.map(p => p.html));
    const carousel = el.querySelector('.compare-split');
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
  document.getElementById('status-indicator').textContent = count === 2
    ? `Compare: ${first} vs ${last} (UTC)`
    : `Compare: ${first} → ${last} (${count} days, UTC)`;
}

async function fetchInspectForDate(dateISO) {
  const body = buildRequest({ composeBlueprint: false });
  body.targetDate = dateISO;
  const res = await fetch('/api/inspect', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json();
}

async function onCompareToggle() {
  syncCompareDaysUI();
  if (document.getElementById('compare-toggle').checked) {
    if (!state.data) {
      showError('Submit first, then enable compare.');
      document.getElementById('compare-toggle').checked = false;
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

async function onCompareDayCountChange(delta) {
  const next = clampCompareDayCount(getCompareDayCount() + delta);
  if (next === getCompareDayCount()) return;
  state.compareDayCount = next;
  syncCompareDaysUI();
  schedulePersistSession();
  if (document.getElementById('compare-toggle').checked && state.data) {
    await loadCompareRange();
  }
}

async function loadCompareRange() {
  const target = targetDateISO();
  if (!target) {
    showError('Set a Daily Fit target date before comparing.');
    document.getElementById('compare-toggle').checked = false;
    syncCompareDaysUI();
    return false;
  }
  if (!state.data) return false;

  const dates = getCompareDateRange();
  const toFetch = dates.slice(1).filter(iso => !state.compareCache[iso]);

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
    document.getElementById('compare-toggle').checked = false;
    syncCompareDaysUI();
    return false;
  }

  showLoading(true);
  try {
    // Chronological order so TarotRecencyTracker sees prior days in this batch
    // (matches opening the app once per UTC day).
    for (const iso of toFetch) {
      const data = await fetchInspectForDate(iso);
      state.compareCache[iso] = data;
    }
    if (state.data) {
      renderAllSections(state.data);
      updateCompareStatus();
    }
    return true;
  } catch (e) {
    clearCompareCache();
    showError(`Compare failed: ${e.message}`);
    document.getElementById('compare-toggle').checked = false;
    syncCompareDaysUI();
    if (state.data) renderAllSections(state.data);
    return false;
  } finally {
    showLoading(false);
  }
}

function postRenderSection(root) {
  root.querySelectorAll('[data-drill]').forEach(node => {
    node.addEventListener('click', (e) => {
      e.stopPropagation();
      if (node.dataset.drill) openDrill(node.dataset.drill);
    });
  });
  root.querySelectorAll('.accordion-header').forEach(h => {
    h.addEventListener('click', () => h.nextElementSibling.classList.toggle('open'));
  });
}

// ── Render ──

function render(data) {
  renderAllSections(data);
}

function renderAllSections(data) {
  document.getElementById('display-name').textContent = data.profile.displayName;
  renderNatal(data.natal);
  renderBlueprint(data.blueprint);
  renderDailyFit(data.dailyFit);
  renderTrace(data.dailyFit.diagnostics);
  renderVerdicts(data.verdicts);
  updateExportButtons();
}

function buildNatalHtml(natal) {
  if (!natal) return '<p class="text-muted">No natal chart data.</p>';
  let html = '<table class="data-table"><thead><tr><th>Planet</th><th>Sign</th><th>Longitude</th><th>Position</th><th>Retro</th></tr></thead><tbody>';
  for (const p of natal.planets) {
    const sign = ZODIAC_SIGNS[p.zodiacSign] || '?';
    const glyph = ZODIAC_GLYPHS[p.zodiacSign] || '';
    html += `<tr>
      <td>${p.symbol} ${p.name}</td>
      <td>${glyph} ${sign}</td>
      <td>${p.longitude.toFixed(4)}</td>
      <td>${p.zodiacPosition}</td>
      <td>${p.isRetrograde ? '℞' : ''}</td>
    </tr>`;
  }
  html += '</tbody></table>';

  html += '<div class="subsection"><div class="subsection-title">Angles &amp; Points</div>';
  html += `<table class="data-table"><tbody>
    <tr><td>Ascendant</td><td>${natal.ascendant.toFixed(4)}° ${signFromDeg(natal.ascendant)}</td></tr>
    <tr><td>Midheaven (MC)</td><td>${natal.midheaven.toFixed(4)}° ${signFromDeg(natal.midheaven)}</td></tr>
    <tr><td>Descendant</td><td>${natal.descendant.toFixed(4)}°</td></tr>
    <tr><td>IC</td><td>${natal.imumCoeli.toFixed(4)}°</td></tr>
    <tr><td>North Node</td><td>${natal.northNode.toFixed(4)}°</td></tr>
    <tr><td>Lunar Phase</td><td>${natal.lunarPhase.toFixed(2)}°</td></tr>
  </tbody></table></div>`;

  html += '<div class="subsection"><div class="subsection-title">House Cusps (Placidus)</div>';
  html += '<div class="tag-list">';
  natal.houseCusps.forEach((c, i) => { html += `<span class="tag">H${i + 1}: ${c.toFixed(1)}°</span>`; });
  html += '</div></div>';
  return html;
}

function buildComparePanes(renderForData) {
  if (!compareActive()) {
    return [{ html: () => renderForData(state.data, true) }];
  }
  const range = getCompareDateRange();
  return range.map((iso, i) => {
    const isTarget = i === 0;
    const data = inspectDataForCompareDate(iso);
    return { html: () => renderForData(data, isTarget) };
  });
}

function renderNatal(natal) {
  mountCompareSection('natal-body', {
    staticNote: 'Natal chart is unchanged day-to-day — shown once below.',
    buildPanes: () => [{ html: () => buildNatalHtml(natal) }]
  });
}

function buildBlueprintHtml(bp) {
  if (!bp) return '<p class="text-muted">No blueprint computed.</p>';

  let html = '';

  // Style Core
  if (bp.styleCore?.narrativeText) {
    html += `<div class="subsection"><div class="subsection-title">Style Core</div>
      <p class="narrative-text">${esc(bp.styleCore.narrativeText)}</p></div>`;
  }

  // Palette
  html += '<div class="subsection"><div class="subsection-title">Palette</div>';
  const bands = [
    ['Neutrals', bp.palette?.neutrals],
    ['Core', bp.palette?.coreColours],
    ['Accents', bp.palette?.accentColours],
    ['Support', bp.palette?.supportColours],
  ];
  for (const [label, colours] of bands) {
    if (colours && colours.length > 0) {
      html += `<div style="margin:8px 0"><strong style="font-size:11px;color:var(--text-muted)">${label}</strong>`;
      html += '<div class="swatch-row">';
      for (const c of colours) {
        html += `<div class="swatch">
          <div class="swatch-color" style="background:${c.hexValue}" title="${c.name} (${c.hexValue})" data-drill="palette:${c.name}"></div>
          <span class="swatch-name">${esc(c.name)}</span>
          <span class="swatch-hex">${c.hexValue}</span>
        </div>`;
      }
      html += '</div></div>';
    }
  }

  // Anchors and signatures
  const special = [
    ['Light Anchor', bp.palette?.lightAnchor],
    ['Deep Anchor', bp.palette?.deepAnchor],
    ['Luminary Sig', bp.palette?.luminarySignature],
    ['Ruler Sig', bp.palette?.rulerSignature],
  ];
  html += '<div style="display:flex;gap:12px;margin-top:8px;flex-wrap:wrap">';
  for (const [label, c] of special) {
    if (c) {
      html += `<div class="swatch"><div class="swatch-color" style="background:${c.hexValue}" title="${c.name}"></div>
        <span class="swatch-name">${label}</span><span class="swatch-hex">${c.hexValue}</span></div>`;
    }
  }
  html += '</div></div>';

  // Textures
  if (bp.textures) {
    html += '<div class="subsection"><div class="subsection-title">Textures</div>';
    if (bp.textures.recommendedTextures?.length) html += `<div><strong>Recommended:</strong> <div class="tag-list">${bp.textures.recommendedTextures.map(t => `<span class="tag">${esc(t)}</span>`).join('')}</div></div>`;
    if (bp.textures.avoidTextures?.length) html += `<div style="margin-top:6px"><strong>Avoid:</strong> <div class="tag-list">${bp.textures.avoidTextures.map(t => `<span class="tag">${esc(t)}</span>`).join('')}</div></div>`;
    if (bp.textures.goodText) html += `<p class="narrative-text" style="margin-top:6px">${esc(bp.textures.goodText)}</p>`;
    html += '</div>';
  }

  // Hardware
  if (bp.hardware) {
    html += '<div class="subsection"><div class="subsection-title">Hardware</div>';
    if (bp.hardware.recommendedMetals?.length) html += `<div class="tag-list">${bp.hardware.recommendedMetals.map(m => `<span class="tag">${esc(m)}</span>`).join('')}</div>`;
    if (bp.hardware.recommendedStones?.length) html += `<div class="tag-list" style="margin-top:4px">${bp.hardware.recommendedStones.map(s => `<span class="tag">${esc(s)}</span>`).join('')}</div>`;
    if (bp.hardware.metalsText) html += `<p class="narrative-text" style="margin-top:6px">${esc(bp.hardware.metalsText)}</p>`;
    html += '</div>';
  }

  // Code
  if (bp.code) {
    html += '<div class="subsection"><div class="subsection-title">Style Code</div>';
    if (bp.code.leanInto?.length) html += `<div><strong>Lean Into:</strong> <div class="tag-list">${bp.code.leanInto.map(c => `<span class="tag">${esc(c)}</span>`).join('')}</div></div>`;
    if (bp.code.avoid?.length) html += `<div style="margin-top:4px"><strong>Avoid:</strong> <div class="tag-list">${bp.code.avoid.map(c => `<span class="tag">${esc(c)}</span>`).join('')}</div></div>`;
    if (bp.code.consider?.length) html += `<div style="margin-top:4px"><strong>Consider:</strong> <div class="tag-list">${bp.code.consider.map(c => `<span class="tag">${esc(c)}</span>`).join('')}</div></div>`;
    html += '</div>';
  }

  // Pattern
  if (bp.pattern) {
    html += '<div class="subsection"><div class="subsection-title">Patterns</div>';
    if (bp.pattern.recommendedPatterns?.length) html += `<div class="tag-list">${bp.pattern.recommendedPatterns.map(p => `<span class="tag">${esc(p)}</span>`).join('')}</div>`;
    if (bp.pattern.narrativeText) html += `<p class="narrative-text" style="margin-top:6px">${esc(bp.pattern.narrativeText)}</p>`;
    html += '</div>';
  }

  // Occasions
  if (bp.occasions) {
    html += '<div class="subsection"><div class="subsection-title">Occasions</div>';
    if (bp.occasions.workText) html += `<p class="narrative-text"><strong>Work:</strong> ${esc(bp.occasions.workText)}</p>`;
    if (bp.occasions.intimateText) html += `<p class="narrative-text"><strong>Intimate:</strong> ${esc(bp.occasions.intimateText)}</p>`;
    if (bp.occasions.dailyText) html += `<p class="narrative-text"><strong>Daily:</strong> ${esc(bp.occasions.dailyText)}</p>`;
    html += '</div>';
  }

  return html;
}

function renderBlueprint(bp) {
  mountCompareSection('blueprint-body', {
    staticNote: 'Style Guide is frozen per profile — unchanged day-to-day.',
    buildPanes: () => [{ html: () => buildBlueprintHtml(bp) }]
  });
}

function buildDailyFitHtml(df, allowDrill = true) {
  if (!df?.payload) return '<p class="text-muted">No Daily Fit data.</p>';
  const p = df.payload;
  const drill = allowDrill ? 'drillable' : '';
  let html = '';

  // Tarot
  html += `<div class="subsection"><div class="subsection-title">Tarot Card</div>
    <span class="${drill}" data-drill="tarot">${esc(p.tarotCard?.name || 'Unknown')}</span></div>`;

  // Style Edit
  if (p.styleEditVariant) {
    html += `<div class="subsection"><div class="subsection-title">Style Edit</div>
      <strong>${esc(p.styleEditVariant.title || '')}</strong>`;
    if (p.styleEditVariant.dailyRitual) html += `<p class="narrative-text">${esc(p.styleEditVariant.dailyRitual)}</p>`;
    if (p.styleEditVariant.wardrobeReflection) html += `<p class="narrative-text" style="margin-top:4px"><em>${esc(p.styleEditVariant.wardrobeReflection)}</em></p>`;
    html += '</div>';
  }

  // Daily Palette
  html += '<div class="subsection"><div class="subsection-title">Daily Palette</div><div class="swatch-row">';
  for (const c of (p.dailyPalette?.colours || [])) {
    html += `<div class="swatch">
      <div class="swatch-color ${drill}" style="background:${c.hexValue}" data-drill="colour:${c.name}"></div>
      <span class="swatch-name">${esc(c.name)}</span>
      <span class="swatch-hex">${c.hexValue}</span>
      <span class="swatch-name">${c.role}</span>
    </div>`;
  }
  html += '</div></div>';

  // Scale bars
  html += '<div class="subsection"><div class="subsection-title">Scales</div>';
  html += scaleBar('Vibrancy', p.vibrancy, allowDrill ? 'vibrancy' : null);
  html += scaleBar('Contrast', p.contrast, allowDrill ? 'contrast' : null);
  html += scaleBar('Metal Tone', p.metalTone, allowDrill ? 'metalTone' : null, 'Cool', 'Warm');
  html += '</div>';

  // Essence
  if (p.essenceProfile?.visibleCategories) {
    html += '<div class="subsection"><div class="subsection-title">Style Essence (Top 3)</div><div class="tag-list">';
    for (const e of p.essenceProfile.visibleCategories) {
      html += `<span class="tag ${drill}" data-drill="essence:${e.category}">${esc(e.category)} (${(e.score * 100).toFixed(0)}%)</span>`;
    }
    html += '</div></div>';
  }

  // Silhouette
  if (p.silhouetteProfile) {
    html += '<div class="subsection"><div class="subsection-title">Silhouette Profile</div>';
    html += scaleBar('M / F', p.silhouetteProfile.masculineFeminine, null, 'Masculine', 'Feminine');
    html += scaleBar('A / R', p.silhouetteProfile.angularRounded, null, 'Angular', 'Rounded');
    html += scaleBar('S / D', p.silhouetteProfile.structuredDraped, null, 'Structured', 'Draped');
    html += '</div>';
  }

  // Vibe Breakdown
  if (p.vibeBreakdown) {
    html += '<div class="subsection"><div class="subsection-title">Vibe Breakdown</div>';
    const vibes = Object.entries(p.vibeBreakdown).filter(([k]) => k !== 'total');
    for (const [k, v] of vibes) {
      html += scaleBar(k, v / 21.0, null);
    }
    html += '</div>';
  }

  // Textures & Pattern
  if (p.dailyTextures?.length) {
    html += `<div class="subsection"><div class="subsection-title">Daily Textures</div><div class="tag-list">${p.dailyTextures.map(t => `<span class="tag">${esc(t)}</span>`).join('')}</div></div>`;
  }
  if (p.dailyPattern) {
    html += `<div class="subsection"><div class="subsection-title">Daily Pattern</div><span class="tag">${esc(p.dailyPattern)}</span></div>`;
  }

  // Transits
  if (p.dominantTransits?.length) {
    html += '<div class="subsection"><div class="subsection-title">Dominant Transits</div>';
    html += '<table class="data-table"><thead><tr><th>Transit</th><th>Natal</th><th>Aspect</th><th>Strength</th></tr></thead><tbody>';
    for (const t of p.dominantTransits) {
      html += `<tr class="${drill}" data-drill="transit:${t.transitPlanet}"><td>${esc(t.transitPlanet)}</td><td>${esc(t.natalPlanet)}</td><td>${esc(t.aspect)}</td><td>${(t.strength * 100).toFixed(0)}%</td></tr>`;
    }
    html += '</tbody></table></div>';
  }

  // Lunar
  if (p.lunarContext) {
    html += `<div class="subsection"><div class="subsection-title">Lunar Context</div>
      <span class="tag">${esc(p.lunarContext.phaseName)}</span>
      <span class="tag">${p.lunarContext.isWaxing ? 'Waxing' : 'Waning'}</span>
      <span class="tag">${esc(p.lunarContext.element)}</span>
      <span class="tag">${p.lunarContext.phaseDegrees.toFixed(1)}°</span></div>`;
  }

  return html;
}

function renderDailyFit(df) {
  mountCompareSection('dailyfit-body', {
    buildPanes: () => buildComparePanes((data, allowDrill) => buildDailyFitHtml(data?.dailyFit, allowDrill))
  });
}

function buildTraceHtml(diag) {
  if (!diag) return '<p>No diagnostics available.</p>';

  let html = '';

  // Source Contributions
  html += accordion('Source Contributions', () => {
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
  html += accordion('Raw Energy Scores', () => kv(diag.rawEnergyScores));
  html += accordion('Post-Multiplier Energy Scores', () => kv(diag.postMultiplierScores));
  html += accordion('Raw Axis Scores', () => kv(diag.rawAxisScores));

  // Tarot Scores
  html += accordion('Tarot Card Scores (Top 15)', () => {
    const sorted = [...(diag.tarotCardScores || [])].sort((a, b) => b.totalScore - a.totalScore).slice(0, 15);
    let t = '<table class="data-table"><thead><tr><th>Card</th><th>Vibe</th><th>Axis</th><th>Transit</th><th>Recency</th><th>Total</th></tr></thead><tbody>';
    for (const s of sorted) {
      const isSelected = s.cardName === diag.selectedTarotCard;
      t += `<tr${isSelected ? ' style="background:rgba(124,111,247,0.1)"' : ''}>
        <td>${esc(s.cardName)}${isSelected ? ' ★' : ''}</td>
        <td>${s.vibeScore.toFixed(3)}</td><td>${s.axisScore.toFixed(3)}</td>
        <td>${s.transitBoost.toFixed(3)}</td><td>${s.recencyPenalty.toFixed(3)}</td>
        <td><strong>${s.totalScore.toFixed(3)}</strong></td></tr>`;
    }
    t += '</tbody></table>';
    return t;
  });

  // Palette Trace
  html += accordion('Palette Selection Trace', () => {
    const pt = diag.paletteSelectionTrace;
    if (!pt) return 'N/A';
    let t = `<p>Candidates: ${pt.candidateCount} | Diversity swap: ${pt.diversitySwapApplied ? 'Yes' : 'No'}</p>`;
    t += '<table class="data-table"><thead><tr><th>Colour</th><th>Role</th><th>Score</th></tr></thead><tbody>';
    for (const c of (pt.topScoredColours || [])) {
      t += `<tr><td>${esc(c.name)}</td><td>${c.role}</td><td>${c.score.toFixed(4)}</td></tr>`;
    }
    t += '</tbody></table>';
    return t;
  });

  // Texture Trace
  html += accordion('Texture Trace', () => {
    const tt = diag.textureSelectionTrace;
    if (!tt) return 'N/A';
    let t = '<table class="data-table"><thead><tr><th>Texture</th><th>Score</th></tr></thead><tbody>';
    for (const s of (tt.scores || [])) {
      t += `<tr><td>${esc(s.name)}</td><td>${s.score.toFixed(4)}</td></tr>`;
    }
    t += '</tbody></table>';
    return t;
  });

  // Pattern
  html += accordion('Pattern Decision', () => {
    const pd = diag.patternDecision;
    if (!pd) return 'N/A';
    return `<table class="data-table"><tbody>
      <tr><td>Gate passed</td><td>${pd.gateCheckPassed ? 'Yes' : 'No'}</td></tr>
      <tr><td>Visibility</td><td>${pd.visibilityValue.toFixed(3)}</td></tr>
      <tr><td>Dominant energy</td><td>${esc(pd.dominantEnergy)}</td></tr>
      <tr><td>Selected</td><td>${pd.selectedPattern || 'None'}</td></tr>
    </tbody></table>`;
  });

  // Scale Traces
  html += accordion('Scale Derivation Traces', () => {
    let t = '';
    for (const [label, trace] of [['Vibrancy', diag.vibrancyTrace], ['Contrast', diag.contrastTrace], ['Metal Tone', diag.metalToneTrace]]) {
      if (trace) {
        t += `<div style="margin:6px 0"><strong>${label}:</strong> baseline=${trace.blueprintBaseline.toFixed(3)}, modulation=${trace.modulation.toFixed(3)}, final=${trace.finalValue.toFixed(3)}</div>`;
      }
    }
    return t;
  });

  // Calibration
  html += accordion('Calibration Snapshot', () => {
    const cs = diag.calibrationSnapshot;
    if (!cs) return 'N/A';
    return '<strong>Source Weights:</strong>' + kv(cs.sourceWeights) + '<strong>Selection Weights:</strong>' + kv(cs.selectionWeights);
  });

  // Full JSON
  html += accordion('Full Diagnostic JSON', () => `<pre class="json-block">${esc(JSON.stringify(diag, null, 2))}</pre>`);
  return html;
}

function renderTrace(diag) {
  mountCompareSection('trace-body', {
    buildPanes: () => buildComparePanes((data, _allowDrill) => buildTraceHtml(data?.dailyFit?.diagnostics))
  });
}

function buildVerdictsHtml(verdicts) {
  if (!verdicts?.length) return '<p>No verdicts.</p>';
  let html = '';
  for (const v of verdicts) {
    const icon = v.status === 'pass' ? '✅' : v.status === 'partial' ? '⚠️' : '❌';
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
  mountCompareSection('verdict-body', {
    buildPanes: () => buildComparePanes((data, _allowDrill) => buildVerdictsHtml(data?.verdicts))
  });
}

// ── Drill-down Drawer ──

function openDrill(key) {
  if (!state.data) return;
  const drawer = document.getElementById('drill-drawer');
  const title = document.getElementById('drawer-title');
  const content = document.getElementById('drawer-content');
  drawer.classList.remove('hidden');

  const diag = state.data.dailyFit.diagnostics;
  const payload = state.data.dailyFit.payload;
  const [type, ...rest] = key.split(':');
  const name = rest.join(':');

  if (type === 'tarot') {
    title.textContent = 'Tarot Selection Detail';
    const sorted = [...(diag.tarotCardScores || [])].sort((a, b) => b.totalScore - a.totalScore);
    let html = `<p><strong>Selected:</strong> ${esc(diag.selectedTarotCard)}</p>`;
    html += `<p><strong>Variant Index:</strong> ${diag.variantRotationIndex}</p>`;
    html += `<p><strong>Style Edit:</strong> ${esc(diag.selectedStyleEdit)}</p>`;
    html += '<table class="data-table"><thead><tr><th>Card</th><th>Total</th><th>Vibe</th><th>Axis</th><th>Boost</th><th>Penalty</th></tr></thead><tbody>';
    for (const s of sorted) {
      const isSel = s.cardName === diag.selectedTarotCard;
      html += `<tr${isSel ? ' style="background:rgba(124,111,247,0.15)"' : ''}><td>${esc(s.cardName)}</td>
        <td><strong>${s.totalScore.toFixed(3)}</strong></td><td>${s.vibeScore.toFixed(3)}</td>
        <td>${s.axisScore.toFixed(3)}</td><td>${s.transitBoost.toFixed(3)}</td><td>${s.recencyPenalty.toFixed(3)}</td></tr>`;
    }
    html += '</tbody></table>';
    content.innerHTML = html;
  } else if (type === 'colour' || type === 'palette') {
    title.textContent = `Palette Detail: ${name}`;
    const pt = diag.paletteSelectionTrace;
    let html = `<p><strong>Candidates evaluated:</strong> ${pt?.candidateCount || '?'}</p>`;
    html += `<p><strong>Diversity swap:</strong> ${pt?.diversitySwapApplied ? 'Yes' : 'No'}</p>`;
    html += '<h4 style="margin:12px 0 6px">Top Scored Candidates</h4>';
    html += '<table class="data-table"><thead><tr><th>Colour</th><th>Role</th><th>Score</th></tr></thead><tbody>';
    for (const c of (pt?.topScoredColours || [])) {
      const highlight = c.name === name;
      html += `<tr${highlight ? ' style="background:rgba(124,111,247,0.15)"' : ''}><td>${esc(c.name)}</td><td>${c.role}</td><td>${c.score.toFixed(4)}</td></tr>`;
    }
    html += '</tbody></table>';
    content.innerHTML = html;
  } else if (type === 'vibrancy' || type === 'contrast' || type === 'metalTone') {
    const traceKey = type + 'Trace';
    const trace = diag[traceKey];
    title.textContent = `${type.charAt(0).toUpperCase() + type.slice(1)} Derivation`;
    let html = '';
    if (trace) {
      html += `<table class="data-table"><tbody>
        <tr><td>Blueprint Baseline</td><td>${trace.blueprintBaseline.toFixed(4)}</td></tr>
        <tr><td>Energy Modulation</td><td>${trace.modulation.toFixed(4)}</td></tr>
        <tr><td>Final Value</td><td>${trace.finalValue.toFixed(4)}</td></tr>
      </tbody></table>`;
      html += '<h4 style="margin:12px 0 6px">Contributing Factors</h4>';
      html += '<p>Source contributions that fed this scale:</p>';
      const sc = diag.sourceContributions;
      html += `<table class="data-table"><tbody>
        <tr><td>Natal</td><td>${(sc.natalShare * 100).toFixed(1)}%</td></tr>
        <tr><td>Transit</td><td>${(sc.transitShare * 100).toFixed(1)}%</td></tr>
        <tr><td>Lunar</td><td>${(sc.lunarShare * 100).toFixed(1)}%</td></tr>
        <tr><td>Progressed</td><td>${(sc.progressedShare * 100).toFixed(1)}%</td></tr>
      </tbody></table>`;
    } else {
      html = '<p>No trace data available.</p>';
    }
    content.innerHTML = html;
  } else if (type === 'essence') {
    title.textContent = 'Style Essence Detail';
    const ep = diag.essenceProfile || payload.essenceProfile;
    let html = '<table class="data-table"><thead><tr><th>Category</th><th>Score</th></tr></thead><tbody>';
    for (const c of (ep?.visibleCategories || [])) {
      html += `<tr><td>${esc(c.category)}</td><td>${(c.score * 100).toFixed(1)}%</td></tr>`;
    }
    html += '</tbody></table>';
    content.innerHTML = html;
  } else if (type === 'silhouette') {
    title.textContent = 'Silhouette Derivation';
    const st = diag.silhouetteTrace;
    let html = '';
    if (st) {
      html += `<table class="data-table"><tbody>
        <tr><td>M/F Blueprint Baseline</td><td>${st.mfBaseline?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>M/F Modulation</td><td>${st.mfModulation?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>M/F Final</td><td>${st.mfFinal?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>A/R Blueprint Baseline</td><td>${st.arBaseline?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>A/R Modulation</td><td>${st.arModulation?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>A/R Final</td><td>${st.arFinal?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>S/D Blueprint Baseline</td><td>${st.sdBaseline?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>S/D Modulation</td><td>${st.sdModulation?.toFixed(3) || 'N/A'}</td></tr>
        <tr><td>S/D Final</td><td>${st.sdFinal?.toFixed(3) || 'N/A'}</td></tr>
      </tbody></table>`;
    } else { html = '<p>No silhouette trace data.</p>'; }
    content.innerHTML = html;
  } else if (type === 'transit') {
    title.textContent = `Transit Detail: ${name}`;
    const transit = (payload.dominantTransits || []).find(t => t.transitPlanet === name);
    let html = '';
    if (transit) {
      html += `<table class="data-table"><tbody>
        <tr><td>Transiting Planet</td><td>${esc(transit.transitPlanet)}</td></tr>
        <tr><td>Natal Planet</td><td>${esc(transit.natalPlanet)}</td></tr>
        <tr><td>Aspect</td><td>${esc(transit.aspect)}</td></tr>
        <tr><td>Strength</td><td>${(transit.strength * 100).toFixed(1)}%</td></tr>
      </tbody></table>`;
    }
    html += '<h4 style="margin:12px 0 6px">All Transit Summaries</h4>';
    html += '<table class="data-table"><thead><tr><th>Transit</th><th>Natal</th><th>Aspect</th><th>Strength</th></tr></thead><tbody>';
    for (const t of (diag.transitSummaries || [])) {
      html += `<tr><td>${esc(t.transitPlanet)}</td><td>${esc(t.natalPlanet)}</td><td>${esc(t.aspect)}</td><td>${(t.strength * 100).toFixed(0)}%</td></tr>`;
    }
    html += '</tbody></table>';
    content.innerHTML = html;
  } else {
    title.textContent = key;
    content.innerHTML = `<pre class="json-block">${esc(JSON.stringify(state.data, null, 2))}</pre>`;
  }
}

function closeDrawer() {
  document.getElementById('drill-drawer').classList.add('hidden');
}

// ── Markdown export ──

const EXPORT_SECTION_LABELS = {
  natal: 'Natal Chart',
  dailyfit: 'Daily Fit',
  trace: 'Trace & Provenance',
  verdicts: 'Verdicts'
};

function updateExportButtons() {
  const data = state.data;
  const flags = {
    natal: !!(data?.natal),
    dailyfit: !!(data?.dailyFit),
    trace: !!(data?.dailyFit?.diagnostics),
    verdicts: !!(data && Array.isArray(data.verdicts))
  };
  document.querySelectorAll('[data-export]').forEach(btn => {
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
  const el = document.getElementById('status-indicator');
  const prev = el.textContent;
  el.textContent = `Exported ${label} (.md)`;
  setTimeout(() => {
    if (el.textContent === `Exported ${label} (.md)`) el.textContent = prev;
  }, 2500);
}

function exportFilename(section) {
  const name = slugify(state.data.profile.displayName);
  const target = parseDateUK(document.getElementById('target-date').value) || 'unknown-date';
  return `cosmicfit_${name}_${section}_${target}.md`;
}

function slugify(text) {
  return (text || 'profile').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'profile';
}

function downloadMarkdown(filename, content) {
  const blob = new Blob([content], { type: 'text/markdown;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
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

  const builders = {
    natal: () => markdownNatal(data.natal),
    dailyfit: () => markdownDailyFit(data.dailyFit),
    trace: () => markdownTrace(data.dailyFit?.diagnostics),
    verdicts: () => markdownVerdicts(data.verdicts)
  };
  const body = builders[section]?.();
  if (body == null) return null;

  return [
    markdownExportHeader(EXPORT_SECTION_LABELS[section] || section),
    markdownInputsBlock(),
    '---',
    '',
    body
  ].join('\n');
}

function markdownExportHeader(sectionLabel) {
  const data = state.data;
  const meta = data.meta || {};
  const computedAt = meta.computedAt ? new Date(meta.computedAt).toISOString() : new Date().toISOString();
  return [
    `# Cosmic Fit Inspector — ${sectionLabel}`,
    '',
    `- **Exported:** ${computedAt}`,
    `- **Display name:** ${data.profile.displayName}`,
    `- **Profile hash:** ${meta.profileHash || '—'}`,
    `- **Engine version:** ${meta.engineVersion || '—'}`,
    ''
  ].join('\n');
}

function markdownInputsBlock() {
  const birth = state.data.profile?.birth;
  const targetUK = document.getElementById('target-date').value;
  const targetISO = parseDateUK(targetUK);
  const rows = [
    ['Preset', document.getElementById('preset-select').value],
    ['Birth date', document.getElementById('birth-date').value],
    ['Birth time', document.getElementById('birth-time').value || '00:00'],
    ['Birth time unknown', document.getElementById('unknown-time').checked ? 'yes' : 'no'],
    ['Location', document.getElementById('location-input').value.trim()],
    ['Latitude', document.getElementById('latitude').value],
    ['Longitude', document.getElementById('longitude').value],
    ['Timezone', document.getElementById('timezone-id').value],
    ['Daily Fit target (UK)', targetUK],
    ['Daily Fit target (ISO day)', targetISO || '—']
  ];
  if (birth) {
    rows.push(['Birth date (API)', birth.birthDate]);
    rows.push(['Birth time (API)', birth.birthTime ?? '—']);
  }
  return '## Profile inputs\n\n' + mdTable(['Field', 'Value'], rows);
}

function markdownNatal(natal) {
  if (!natal) return '_No natal chart data._\n';
  let md = '## Natal Chart\n\n';

  const planetRows = natal.planets.map(p => {
    const sign = ZODIAC_SIGNS[p.zodiacSign] || '?';
    const glyph = ZODIAC_GLYPHS[p.zodiacSign] || '';
    return [
      `${p.symbol} ${p.name}`,
      `${glyph} ${sign}`,
      p.longitude.toFixed(4),
      p.zodiacPosition,
      p.isRetrograde ? '℞' : ''
    ];
  });
  md += '### Planets\n\n' + mdTable(['Planet', 'Sign', 'Longitude', 'Position', 'Retro'], planetRows);

  md += '### Angles & Points\n\n' + mdTable(['Point', 'Value'], [
    ['Ascendant', `${natal.ascendant.toFixed(4)}° ${signFromDeg(natal.ascendant)}`],
    ['Midheaven (MC)', `${natal.midheaven.toFixed(4)}° ${signFromDeg(natal.midheaven)}`],
    ['Descendant', `${natal.descendant.toFixed(4)}°`],
    ['IC', `${natal.imumCoeli.toFixed(4)}°`],
    ['North Node', `${natal.northNode.toFixed(4)}°`],
    ['South Node', `${natal.southNode.toFixed(4)}°`],
    ['Lunar Phase', `${natal.lunarPhase.toFixed(2)}°`]
  ]);

  const cuspRows = natal.houseCusps.map((c, i) => [`House ${i + 1}`, `${c.toFixed(1)}°`]);
  md += '### House Cusps (Placidus)\n\n' + mdTable(['House', 'Cusp'], cuspRows);

  if (natal.wholeSignHouseCusps?.length) {
    const wsRows = natal.wholeSignHouseCusps.map((c, i) => [`House ${i + 1}`, `${c.toFixed(1)}°`]);
    md += '### House Cusps (Whole Sign)\n\n' + mdTable(['House', 'Cusp'], wsRows);
  }

  return md;
}

function markdownDailyFit(dailyFit) {
  if (!dailyFit?.payload) return '_No Daily Fit data._\n';
  const p = dailyFit.payload;
  let md = '## Daily Fit\n\n';

  md += '### Tarot\n\n';
  md += `- **Card:** ${p.tarotCard?.name || 'Unknown'}\n\n`;

  if (p.styleEditVariant) {
    md += '### Style Edit\n\n';
    md += `- **Title:** ${p.styleEditVariant.title || ''}\n`;
    if (p.styleEditVariant.dailyRitual) md += `\n${p.styleEditVariant.dailyRitual}\n\n`;
    if (p.styleEditVariant.wardrobeReflection) {
      md += `\n_${p.styleEditVariant.wardrobeReflection}_\n\n`;
    }
  }

  const paletteRows = (p.dailyPalette?.colours || []).map(c => [c.name, c.hexValue, c.role]);
  md += '### Daily Palette\n\n' + mdTable(['Colour', 'Hex', 'Role'], paletteRows);

  md += '### Scales\n\n' + mdTable(['Scale', 'Value'], [
    ['Vibrancy', fmtNum(p.vibrancy)],
    ['Contrast', fmtNum(p.contrast)],
    ['Metal tone', fmtNum(p.metalTone)]
  ]);

  if (p.essenceProfile?.visibleCategories?.length) {
    const essenceRows = p.essenceProfile.visibleCategories.map(e => [
      e.category,
      `${(e.score * 100).toFixed(0)}%`
    ]);
    md += '### Style Essence (Top 3)\n\n' + mdTable(['Category', 'Score'], essenceRows);
  }

  if (p.silhouetteProfile) {
    const sp = p.silhouetteProfile;
    md += '### Silhouette Profile\n\n' + mdTable(['Axis', 'Value'], [
      ['Masculine / Feminine', fmtNum(sp.masculineFeminine)],
      ['Angular / Rounded', fmtNum(sp.angularRounded)],
      ['Structured / Draped', fmtNum(sp.structuredDraped)]
    ]);
  }

  if (p.vibeBreakdown) {
    const vibeRows = Object.entries(p.vibeBreakdown)
      .filter(([k]) => k !== 'total')
      .map(([k, v]) => [k, String(v)]);
    md += '### Vibe Breakdown\n\n' + mdTable(['Vibe', 'Score'], vibeRows);
    if (p.vibeBreakdown.total != null) {
      md += `**Total:** ${p.vibeBreakdown.total}\n\n`;
    }
  }

  if (p.dailyTextures?.length) {
    md += `### Daily Textures\n\n${p.dailyTextures.map(t => `- ${t}`).join('\n')}\n\n`;
  }
  if (p.dailyPattern) {
    md += `### Daily Pattern\n\n- ${p.dailyPattern}\n\n`;
  }

  if (p.dominantTransits?.length) {
    const transitRows = p.dominantTransits.map(t => [
      t.transitPlanet,
      t.natalPlanet,
      t.aspect,
      `${(t.strength * 100).toFixed(0)}%`
    ]);
    md += '### Dominant Transits\n\n' + mdTable(['Transit', 'Natal', 'Aspect', 'Strength'], transitRows);
  }

  if (p.lunarContext) {
    const lc = p.lunarContext;
    md += '### Lunar Context\n\n' + mdTable(['Field', 'Value'], [
      ['Phase', lc.phaseName],
      ['Waxing / Waning', lc.isWaxing ? 'Waxing' : 'Waning'],
      ['Element', lc.element],
      ['Phase degrees', `${lc.phaseDegrees.toFixed(1)}°`]
    ]);
  }

  md += '### Full Daily Fit payload (JSON)\n\n' + mdJsonBlock(p);
  return md;
}

function markdownVerdicts(verdicts) {
  let md = '## Verdicts\n\n';
  if (!verdicts?.length) {
    md += '_No verdict rows for this run._\n';
    return md;
  }

  const rows = verdicts.map(v => {
    const icon = v.status === 'pass' ? 'pass' : v.status === 'partial' ? 'partial' : 'fail';
    return [v.id, icon, v.expected, v.actual, v.docRef || ''];
  });
  md += mdTable(['ID', 'Status', 'Expected', 'Actual', 'Doc ref'], rows);
  return md;
}

function markdownTrace(diag) {
  if (!diag) return '_No trace / diagnostics data._\n';
  let md = '## Trace & Provenance\n\n';

  if (diag.sourceContributions) {
    const sc = diag.sourceContributions;
    md += '### Source Contributions\n\n' + mdTable(['Source', 'Share'], [
      ['Natal', pct(sc.natalShare)],
      ['Transits', pct(sc.transitShare)],
      ['Lunar', pct(sc.lunarShare)],
      ['Progressed', pct(sc.progressedShare)],
      ['Current Sun', pct(sc.currentSunShare)]
    ]);
  }

  if (diag.rawEnergyScores) {
    md += '### Raw Energy Scores\n\n' + mdObjectTable(diag.rawEnergyScores);
  }
  if (diag.postMultiplierScores) {
    md += '### Post-Multiplier Energy Scores\n\n' + mdObjectTable(diag.postMultiplierScores);
  }
  if (diag.rawAxisScores) {
    md += '### Raw Axis Scores\n\n' + mdObjectTable(diag.rawAxisScores);
  }

  if (diag.tarotCardScores?.length) {
    const sorted = [...diag.tarotCardScores].sort((a, b) => b.totalScore - a.totalScore).slice(0, 15);
    const rows = sorted.map(s => [
      s.cardName + (s.cardName === diag.selectedTarotCard ? ' ★' : ''),
      s.vibeScore.toFixed(3),
      s.axisScore.toFixed(3),
      s.transitBoost.toFixed(3),
      s.recencyPenalty.toFixed(3),
      s.totalScore.toFixed(3)
    ]);
    md += '### Tarot Card Scores (Top 15)\n\n';
    md += `- **Selected:** ${diag.selectedTarotCard || '—'}\n`;
    md += `- **Variant index:** ${diag.variantRotationIndex ?? '—'}\n`;
    md += `- **Style edit:** ${diag.selectedStyleEdit || '—'}\n\n`;
    md += mdTable(['Card', 'Vibe', 'Axis', 'Transit', 'Recency', 'Total'], rows);
  }

  if (diag.paletteSelectionTrace) {
    const pt = diag.paletteSelectionTrace;
    md += '### Palette Selection Trace\n\n';
    md += `- **Candidates:** ${pt.candidateCount}\n`;
    md += `- **Diversity swap:** ${pt.diversitySwapApplied ? 'Yes' : 'No'}\n\n`;
    const rows = (pt.topScoredColours || []).map(c => [c.name, c.role, c.score.toFixed(4)]);
    md += mdTable(['Colour', 'Role', 'Score'], rows);
  }

  if (diag.textureSelectionTrace?.scores?.length) {
    const rows = diag.textureSelectionTrace.scores.map(s => [s.name, s.score.toFixed(4)]);
    md += '### Texture Trace\n\n' + mdTable(['Texture', 'Score'], rows);
  }

  if (diag.patternDecision) {
    const pd = diag.patternDecision;
    md += '### Pattern Decision\n\n' + mdTable(['Field', 'Value'], [
      ['Gate passed', pd.gateCheckPassed ? 'Yes' : 'No'],
      ['Visibility', pd.visibilityValue.toFixed(3)],
      ['Dominant energy', pd.dominantEnergy],
      ['Selected pattern', pd.selectedPattern || 'None']
    ]);
  }

  for (const [label, key] of [['Vibrancy', 'vibrancyTrace'], ['Contrast', 'contrastTrace'], ['Metal Tone', 'metalToneTrace']]) {
    const trace = diag[key];
    if (!trace) continue;
    md += `### ${label} Derivation\n\n`;
    md += mdTable(['Field', 'Value'], [
      ['Blueprint baseline', trace.blueprintBaseline.toFixed(3)],
      ['Modulation', trace.modulation.toFixed(3)],
      ['Final', trace.finalValue.toFixed(3)]
    ]);
  }

  if (diag.calibrationSnapshot) {
    const cs = diag.calibrationSnapshot;
    md += '### Calibration Snapshot\n\n';
    if (cs.sourceWeights) md += '**Source weights**\n\n' + mdObjectTable(cs.sourceWeights);
    if (cs.selectionWeights) md += '**Selection weights**\n\n' + mdObjectTable(cs.selectionWeights);
  }

  md += '### Full Diagnostic JSON\n\n' + mdJsonBlock(diag);
  return md;
}

function mdTable(headers, rows) {
  if (!rows.length) return '_No data_\n\n';
  const head = `| ${headers.join(' | ')} |`;
  const sep = `| ${headers.map(() => '---').join(' | ')} |`;
  const body = rows.map(r => `| ${r.map(c => mdCell(c)).join(' | ')} |`).join('\n');
  return `${head}\n${sep}\n${body}\n\n`;
}

function mdObjectTable(obj) {
  const rows = Object.entries(obj).map(([k, v]) => [k, typeof v === 'number' ? v.toFixed(4) : String(v)]);
  return mdTable(['Key', 'Value'], rows);
}

function mdCell(value) {
  return String(value ?? '').replace(/\|/g, '\\|').replace(/\n/g, ' ');
}

function mdJsonBlock(obj) {
  return '```json\n' + JSON.stringify(obj, null, 2) + '\n```\n\n';
}

function fmtNum(n) {
  return typeof n === 'number' ? n.toFixed(3) : '—';
}

function pct(n) {
  return typeof n === 'number' ? `${(n * 100).toFixed(1)}%` : '—';
}

// ── Helpers ──

function signFromDeg(deg) {
  const idx = Math.floor(deg / 30) + 1;
  return `${ZODIAC_GLYPHS[idx] || ''} ${ZODIAC_SIGNS[idx] || ''}`;
}

function scaleBar(label, value, drillKey, leftLabel, rightLabel) {
  const pct = Math.max(0, Math.min(100, (value || 0) * 100));
  const drillAttr = drillKey ? ` data-drill="${drillKey}"` : '';
  const cls = drillKey ? ' drillable' : '';
  let html = `<div class="scale-bar-container">`;
  if (leftLabel) html += `<span class="scale-bar-label" style="font-size:10px">${leftLabel}</span>`;
  else html += `<span class="scale-bar-label">${label}</span>`;
  html += `<div class="scale-bar-track"><div class="scale-bar-fill" style="width:${pct}%"></div></div>`;
  html += `<span class="scale-bar-value${cls}"${drillAttr}>${(value || 0).toFixed(3)}</span>`;
  if (rightLabel) html += `<span class="scale-bar-label" style="font-size:10px;text-align:left">${rightLabel}</span>`;
  html += '</div>';
  return html;
}

function accordion(title, contentFn) {
  return `<div class="accordion-item">
    <div class="accordion-header">${title} <span class="toggle-icon">▶</span></div>
    <div class="accordion-body">${contentFn()}</div>
  </div>`;
}

function kv(obj) {
  if (!obj) return 'N/A';
  let html = '<table class="data-table"><tbody>';
  for (const [k, v] of Object.entries(obj)) {
    html += `<tr><td>${esc(k)}</td><td>${typeof v === 'number' ? v.toFixed(4) : esc(String(v))}</td></tr>`;
  }
  html += '</tbody></table>';
  return html;
}

function esc(s) { if (!s) return ''; const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
function showLoading(v) { document.getElementById('loading').classList.toggle('hidden', !v); }
function showError(msg) { const el = document.getElementById('error-banner'); el.textContent = msg; el.classList.remove('hidden'); }
function hideError() { document.getElementById('error-banner').classList.add('hidden'); }
