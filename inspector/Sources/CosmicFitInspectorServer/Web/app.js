// Cosmic Fit Inspector — Frontend
'use strict';

const ZODIAC_SIGNS = ['','Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];
const ZODIAC_GLYPHS = ['','♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];

let state = { data: null, prevData: null, presets: [], lastBirthFingerprint: null };

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
}

function clearResolvedLocation() {
  document.getElementById('latitude').value = '';
  document.getElementById('longitude').value = '';
  delete document.getElementById('latitude').dataset.resolvedLabel;
  const chip = document.getElementById('location-coords');
  chip.textContent = 'Not resolved — pick a suggestion or Submit to geocode';
  chip.classList.add('unresolved');
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

// ── Init ──

document.addEventListener('DOMContentLoaded', async () => {
  setTodayUTC();
  const locLabel = document.getElementById('location-input').value.trim();
  document.getElementById('latitude').dataset.resolvedLabel = locLabel;
  await loadPresets();
  wireEvents();
});

function setTodayUTC() {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  document.getElementById('target-date').value = formatDateUK(`${yyyy}-${mm}-${dd}`);
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
  document.getElementById('preset-select').addEventListener('change', applyPreset);
  document.getElementById('compare-toggle').addEventListener('change', onCompareToggle);
  document.getElementById('drawer-close').addEventListener('click', closeDrawer);
  document.getElementById('target-date').addEventListener('change', () => { if (state.data) doSubmit(true); });

  document.querySelectorAll('.card-header').forEach(h => {
    h.addEventListener('click', () => {
      const bodyId = h.dataset.toggle;
      const body = document.getElementById(bodyId);
      if (body) body.classList.toggle('collapsed');
      const icon = h.querySelector('.toggle-icon');
      if (icon) icon.textContent = body.classList.contains('collapsed') ? '▶' : '▼';
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
    clearResolvedLocation();
  });

  for (const id of ['birth-date', 'birth-time', 'target-date']) {
    document.getElementById(id).addEventListener('input', () => {
      document.getElementById('preset-select').value = 'custom';
    });
  }
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

  const birthFp = `${body.birth.dateISO}|${body.birth.latitude}|${body.birth.longitude}|${body.birth.timeZoneId}`;
  const isDateOnlyChange = dateOnly && state.lastBirthFingerprint === birthFp;
  if (isDateOnlyChange) {
    body.options.composeBlueprint = false;
  }

  // Target age warning
  const birthYear = parseInt(body.birth.dateISO.slice(0, 4), 10);
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
    const elapsed = ((performance.now() - t0) / 1000).toFixed(2);
    const mode = isDateOnlyChange ? 'date-only' : 'full';
    document.getElementById('status-indicator').textContent = `Computed in ${elapsed}s (${mode})`;
    render(state.data);

    if (document.getElementById('compare-toggle').checked) {
      await loadPreviousDay();
    }
  } catch (e) {
    showError(e.message);
  } finally {
    btn.disabled = false;
    showLoading(false);
  }
}

function buildRequest() {
  const birthDateISO = parseDateUK(document.getElementById('birth-date').value);
  if (!birthDateISO) {
    throw new Error('Birth date must be dd/mm/yyyy (e.g. 11/12/1984)');
  }
  const targetDateISO = parseDateUK(document.getElementById('target-date').value);
  if (!targetDateISO) {
    throw new Error('Daily Fit target date must be dd/mm/yyyy (UTC calendar day)');
  }

  const time = document.getElementById('birth-time').value || '00:00';
  const unknownTime = document.getElementById('unknown-time').checked;
  const dateISO = `${birthDateISO}T${time}:00Z`;

  const latitude = parseFloat(document.getElementById('latitude').value);
  const longitude = parseFloat(document.getElementById('longitude').value);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new Error('Location coordinates are missing — pick a suggestion or Submit to geocode');
  }

  return {
    preset: document.getElementById('preset-select').value,
    birth: {
      dateISO,
      unknownTime,
      latitude,
      longitude,
      timeZoneId: document.getElementById('timezone-id').value,
      locationLabel: document.getElementById('location-input').value.trim()
    },
    targetDate: targetDateISO,
    options: { composeBlueprint: true, includeProgressed: true }
  };
}

// ── Compare ──

async function onCompareToggle() {
  const diffCard = document.getElementById('diff-card');
  if (document.getElementById('compare-toggle').checked && state.data) {
    diffCard.classList.remove('hidden');
    await loadPreviousDay();
  } else {
    diffCard.classList.add('hidden');
    state.prevData = null;
  }
}

async function loadPreviousDay() {
  const targetDate = parseDateUK(document.getElementById('target-date').value);
  if (!targetDate) return;
  const prev = new Date(targetDate + 'T00:00:00Z');
  prev.setUTCDate(prev.getUTCDate() - 1);
  const prevStr = prev.toISOString().slice(0, 10);

  const body = buildRequest();
  body.targetDate = prevStr;
  body.options.composeBlueprint = false;

  try {
    const res = await fetch('/api/inspect', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    if (res.ok) {
      state.prevData = await res.json();
      renderDiff(state.prevData, state.data);
    }
  } catch (e) { console.warn('Diff load failed', e); }
}

// ── Render ──

function render(data) {
  document.getElementById('display-name').textContent = data.profile.displayName;
  renderNatal(data.natal);
  renderBlueprint(data.blueprint);
  renderDailyFit(data.dailyFit);
  renderTrace(data.dailyFit.diagnostics);
  renderVerdicts(data.verdicts);
}

function renderNatal(natal) {
  const el = document.getElementById('natal-body');
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
  el.innerHTML = html;
}

function renderBlueprint(bp) {
  const el = document.getElementById('blueprint-body');
  if (!bp) { el.innerHTML = '<p class="text-muted">No blueprint computed.</p>'; return; }

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

  el.innerHTML = html;
  el.querySelectorAll('[data-drill]').forEach(el => el.addEventListener('click', (e) => openDrill(e.target.dataset.drill)));
}

function renderDailyFit(df) {
  const el = document.getElementById('dailyfit-body');
  const p = df.payload;
  let html = '';

  // Tarot
  html += `<div class="subsection"><div class="subsection-title">Tarot Card</div>
    <span class="drillable" data-drill="tarot">${esc(p.tarotCard?.name || 'Unknown')}</span></div>`;

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
      <div class="swatch-color drillable" style="background:${c.hexValue}" data-drill="colour:${c.name}"></div>
      <span class="swatch-name">${esc(c.name)}</span>
      <span class="swatch-hex">${c.hexValue}</span>
      <span class="swatch-name">${c.role}</span>
    </div>`;
  }
  html += '</div></div>';

  // Scale bars
  html += '<div class="subsection"><div class="subsection-title">Scales</div>';
  html += scaleBar('Vibrancy', p.vibrancy, 'vibrancy');
  html += scaleBar('Contrast', p.contrast, 'contrast');
  html += scaleBar('Metal Tone', p.metalTone, 'metalTone', 'Cool', 'Warm');
  html += '</div>';

  // Essence
  if (p.essenceProfile?.visibleCategories) {
    html += '<div class="subsection"><div class="subsection-title">Style Essence (Top 3)</div><div class="tag-list">';
    for (const e of p.essenceProfile.visibleCategories) {
      html += `<span class="tag drillable" data-drill="essence:${e.category}">${esc(e.category)} (${(e.score * 100).toFixed(0)}%)</span>`;
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
      html += `<tr class="drillable" data-drill="transit:${t.transitPlanet}"><td>${esc(t.transitPlanet)}</td><td>${esc(t.natalPlanet)}</td><td>${esc(t.aspect)}</td><td>${(t.strength * 100).toFixed(0)}%</td></tr>`;
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

  el.innerHTML = html;
  el.querySelectorAll('.drillable').forEach(el => el.addEventListener('click', (e) => openDrill(e.target.dataset.drill)));
}

function renderTrace(diag) {
  const el = document.getElementById('trace-body');
  if (!diag) { el.innerHTML = '<p>No diagnostics available.</p>'; return; }

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

  el.innerHTML = html;
  el.querySelectorAll('.accordion-header').forEach(h => {
    h.addEventListener('click', () => {
      const body = h.nextElementSibling;
      body.classList.toggle('open');
    });
  });
}

function renderVerdicts(verdicts) {
  const el = document.getElementById('verdict-body');
  if (!verdicts?.length) { el.innerHTML = '<p>No verdicts.</p>'; return; }
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
  el.innerHTML = html;
}

function renderDiff(prev, curr) {
  const el = document.getElementById('diff-body');
  if (!prev || !curr) { el.innerHTML = '<p>No comparison data.</p>'; return; }
  document.getElementById('diff-card').classList.remove('hidden');

  const pp = prev.dailyFit.payload;
  const cp = curr.dailyFit.payload;
  let html = '<div class="diff-container">';
  html += `<div class="diff-column"><h4>Previous Day</h4>${diffPayloadSummary(pp)}</div>`;
  html += `<div class="diff-column"><h4>Current Day</h4>${diffPayloadSummary(cp)}</div>`;
  html += '</div>';
  el.innerHTML = html;
}

function diffPayloadSummary(p) {
  let html = `<div><strong>Tarot:</strong> ${esc(p.tarotCard?.name || '?')}</div>`;
  html += '<div class="swatch-row" style="margin:4px 0">';
  for (const c of (p.dailyPalette?.colours || [])) {
    html += `<div class="swatch"><div class="swatch-color" style="background:${c.hexValue}"></div><span class="swatch-name">${esc(c.name)}</span></div>`;
  }
  html += '</div>';
  html += `<div>Vibrancy: ${p.vibrancy?.toFixed(3)} | Contrast: ${p.contrast?.toFixed(3)} | Metal: ${p.metalTone?.toFixed(3)}</div>`;
  if (p.essenceProfile?.visibleCategories) {
    html += `<div>Essence: ${p.essenceProfile.visibleCategories.map(e => e.category).join(', ')}</div>`;
  }
  return html;
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
