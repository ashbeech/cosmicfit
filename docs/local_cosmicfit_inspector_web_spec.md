# Local Cosmic Fit Inspector — Web Tool Specification

**Status:** Draft for implementation by a follow-on developer  
**Audience:** Engineers building a **localhost-only** debugging / calibration UI on macOS  
**Goal:** Visually inspect, compare across days, and explain **why** the Cosmic Fit pipeline produced a given Style Guide and Daily Fit output (including provenance and calibration test status) — **without** re-implementing the engine in JavaScript.

---

## 1. Executive summary

### 1.1 Product intent

Build a **local web application** (browser UI + small backend) that:

- Mirrors **profile inputs** aligned with onboarding / profile edit (birth date, birth time, location, geocoded lat/lon + timezone).
- Shows **Style Guide** output and **Daily Fit** output for a selected **target calendar day** (default: “today” in a defined timezone, typically UTC for parity with tests).
- Surfaces **full diagnostic traces** (what the device console shows today, but structured as HTML).
- Allows **fast switching** between **preset calibration users** and **ad-hoc** profiles.
- Shows **how outputs change day-to-day** (e.g. “Black Cherry” + high vibrancy today vs tomorrow — what inputs/scores changed).
- Overlays **calibration / regression signals** (pass / partial / fail) so the team can see whether the current run matches harness expectations.

### 1.2 Architectural answer (do we port to JavaScript?)

**No — a full JavaScript port of Cosmic Fit is not required and is discouraged.**

The Cosmic Fit engine lives in **Swift** (UIKit app + shared interpretation modules). The existing **XCTest** suites are **not** a drop-in HTTP server; they validate behaviour inside Xcode’s test runner.

**Recommended approach:**

| Layer | Technology | Role |
|-------|------------|------|
| **Engine** | Existing Swift code (`Cosmic_Fit` target / shared module) | Single source of truth — same types as the app |
| **Backend** | Small **local HTTP server** in Swift (e.g. Vapor, Hummingbird, or `swift-nio` minimal handler) **or** a `swift run` CLI that reads stdin JSON and prints JSON | Exposes `POST /api/session` / `POST /api/daily` etc. |
| **Frontend** | Static HTML + CSS + minimal JS (or a lightweight framework) | Layout, date picker, tabs, diff view, charts |

**Why not “just use XCTest as the server”?**

- Tests are invoked by `xcodebuild`; round-tripping through test launch per click is **slow** and brittle for interactive UI.
- Better: **extract** or **call** the same pure functions the tests already use (`DailyFitDiagnostics.generateReport`, `BlueprintComposer.compose`, `NatalChartCalculator`, etc.) from a **thin Swift executable** or **server target** that links the app logic.

**Optional hybrid:** A scheduled job exports JSON snapshots to `docs/inspector_cache/` and the web UI is read-only — useful for CI artefacts, worse for interactive “change date and see instantly”.

---

## 2. Users and presets

### 2.1 Preset users (minimum four)

Ship **four fixed profiles** that map to existing calibration / goldens in-repo (names are labels only):

1. **Ash-style** — align with `blueprint_input_user_1.json` / calibration hash `cal_ash` (exact birth + location from fixture).
2. **Maria-style** — `blueprint_input_user_2.json` / `cal_maria` equivalent.
3. **Water-dominant calibration** — from `DailyFitDistribution` / `Variation` harness (`cal_water`).
4. **Earth-dominant calibration** — (`cal_earth`).

(Exact preset list can be adjusted to match `DistributionProfiles` / `VariationProfiles` — implementer should read `Cosmic FitTests/DailyFit*_Tests.swift` for canonical hashes and chart sign arrays.)

### 2.2 Ad-hoc user

- Same fields as presets but editable.
- **Display name:** auto-assign from a **curated rotating list** (e.g. “Aurora”, “Cedar”, …) when the user hits Submit or when birth fields change — **no free-text name field required** in v1.

---

## 3. UI layout (full-width top bar)

### 3.1 Top control strip (horizontal, full viewport width)

Left-to-right, **single row** on desktop (collapse to stacked on narrow widths):

| Control | Behaviour |
|---------|-----------|
| **Preset selector** | Dropdown: `Ash` · `Maria` · `Water` · `Earth` · `Custom` |
| **Generated display name** | Read-only chip (updates when preset changes or on submit for custom) |
| **Birth date** | Date picker (calendar UI) |
| **Birth time** | Time picker + **“Unknown time”** checkbox (matches app semantics: noon local etc. — mirror `OnboardingFormViewController` / `ProfileViewController`) |
| **Birth location** | Autocomplete text field — ideally reuse same geocoding path as app (or document limitation: paste lat/lon if autocomplete not wired in v1) |
| **Submit** | Recomputes natal chart, blueprint (if applicable), daily snapshot for selected **target day** |

**Below** the first row (still “header” region):

| Control | Behaviour |
|---------|-----------|
| **Target day for Daily Fit** | Date selector (day / month / year) — drives **Daily Fit** section only (see §4.3). Default: current day in **UTC** (match test harness) with a visible timezone label. |

### 3.2 Main scrollable output

Single column, generous whitespace, sections as **collapsible cards**:

1. **Natal chart (static)** — wheel or tabular longitudes (reuse whatever the app already can serialize; v1 can be JSON table + sign glyphs).
2. **Style Guide (Blueprint)** — structured sections matching app model (`CosmicBlueprint` / `PaletteSection` / hardware / code / pattern…).
3. **Daily Fit (selected target day)** — payload matching `DailyFitPayload` fields.
4. **Trace & provenance** — tree or accordion per subsystem (see §5).
5. **Calibration overlay** — test verdict strip (see §6).

---

## 4. Behavioural rules

### 4.1 What “Submit” recomputes

On submit (or preset change):

1. Resolve **birth instant** exactly as the iOS app does (timezone + unknown time rules).
2. Compute **natal chart** (`NatalChartCalculator` + same ephemeris bundle as app).
3. Optionally compute **progressed chart** for the target day (match production Daily Fit pipeline).
4. Build or load **blueprint**:
   - **Option A (preferred for fidelity):** Run full `BlueprintComposer.compose` with dataset + narrative cache (same files as app).
   - **Option B (faster stub):** Load frozen `blueprint_input_user_*.json` for presets only — document deviation from live compose.

5. Build **DailyEnergySnapshot** for `targetDate` + profile hash.
6. Run **`DailyFitDiagnostics.generateReport`** (returns `DailyFitPayload` + `DailyFitDiagnosticReport`) — this is the richest structured trace today.

### 4.2 Default day

- **Daily Fit target day** defaults to “today” (UTC unless user overrides display TZ in settings).
- **Style Guide** is mostly **natal**-driven; show a subtle note if any Style Guide fields use “generation date” vs birth.

### 4.3 Changing the date selector

- Updates **only** the Daily Fit pipeline inputs that depend on calendar day (transits, progressed positions, moon phase, daily seed, etc.).
- Does **not** change birth inputs unless the user edits the top bar and submits again.

### 4.4 Future dates

- Must be supported for exploratory calibration (transits / synthetic aspects as per engine).
- Show a **banner** if ephemeris or transit tables are incomplete beyond a horizon (engine truth — no silent fallback).

---

## 5. Trace & provenance (the “why Black Cherry + high vibrancy?” story)

### 5.1 Minimum viable trace (v1)

Expose structured JSON from **`DailyFitDiagnosticReport`** (already `Codable`) and render:

- **Stage 1 (Daily energy):** vibe breakdown, axes, dominant transits, lunar context, `dailySeed`, `profileHash`.
- **Stage 2 (Blueprint lens):** tarot score table (vibe / axis / transit boost / recency penalty / total), palette candidate scores, selected colours, diversity swap flag, texture scores, pattern gate, etc.

Also call or mirror **`BlueprintLensEngine.logDailyFitDiagnostics`** output **as structured fields**, not only stderr strings — v1 can parse existing print format only as a stopgap.

### 5.2 “Explain this field” drill-down

For each **user-visible output** (e.g. `dailyPalette.colours[0].name`, `vibrancy`, `tarotCard`):

- Click opens a **sidebar** listing contributing factors with numeric weights where available.
- For palette: show top-N scored candidates from trace vs chosen three.

### 5.3 Day-to-day diff (v1.1 nice-to-have)

- “Compare to previous day” toggle: side-by-side or unified diff for `DailyFitPayload` + key trace metrics.

---

## 6. Calibration / test overlay (ticks and crosses)

### 6.1 Goal

Show whether the **current computed result** satisfies selected automated checks — **without** pretending the browser runs XCTest.

### 6.2 Implementation strategies

| Strategy | Pros | Cons |
|----------|------|------|
| **A. Server runs Swift assertions** | Exact same logic as CI | Must compile server with test helpers or duplicate assertion code |
| **B. Server returns raw JSON; browser runs a small rule pack** | Fast UI | Drifts from XCTest unless generated from same fixtures |
| **C. Nightly job writes `verdicts.json` next to profiles** | Simple read-only UI | Stale until rebuild |

**Recommendation:** **Strategy A** for presets — the Swift server links a **`InspectorVerification`** module that imports shared assertion helpers (extracted from test targets into a small **shared** Swift package / framework if needed).

### 6.3 Visual language

Per check row:

- ✅ Pass  
- ⚠️ Partial (soft threshold, e.g. cosine distance borderline)  
- ❌ Fail  

Include **check name**, **expected**, **actual**, **link to doc** (e.g. `docs/test_green_handoff.md` section).

### 6.4 Initial check bundle (examples)

- Daily Fit goldens subset (dominant energy / essence band) when profile matches a golden case.
- Tarot frequency cap over 30-day sweep **for this profile only** (lighter than full suite).
- Palette collision rules when second preset selected for same day.

(Implementer: start with **3–5 high-signal checks**; expand iteratively.)

---

## 7. API sketch (backend)

All endpoints **localhost only**, bind `127.0.0.1`.

```http
POST /api/inspect
Content-Type: application/json

{
  "preset": "ash | maria | water | earth | custom",
  "birth": { ... },           // required if custom
  "targetDate": "2026-05-13", // ISO date (UTC)
  "options": {
    "composeBlueprint": true,
    "includeProgressed": true
  }
}
```

Response: single JSON document:

```json
{
  "meta": { "engineVersion": "...", "computedAt": "..." },
  "profile": { "displayName": "...", "hash": "..." },
  "natal": { },
  "progressed": { },
  "blueprint": { },
  "dailyFit": {
    "payload": { },
    "diagnostics": { }
  },
  "verdicts": [ { "id": "...", "status": "pass|partial|fail", "detail": "..." } ]
}
```

---

## 8. Security & scope

- **No remote hosting in v1** — refuse non-loopback binds.
- **No authentication** required (local only) — document risk if tunneling.
- Do **not** embed production Supabase keys in the inspector.

---

## 9. Delivery phases

| Phase | Scope |
|-------|--------|
| **P0** | Swift local server + static HTML; presets; target day selector; JSON pretty-print of `DailyFitDiagnosticReport` + payload |
| **P1** | Styled sections; natal summary; blueprint compose path; provenance drill-down |
| **P2** | Day diff; custom profiles; location autocomplete |
| **P3** | Verdict engine + extracted shared assertion helpers |

---

## 10. Open questions for product owner

1. **Blueprint source of truth** for custom profiles: live `BlueprintComposer` vs fixture-only for v1?
2. **Timezone default** for “today”: UTC (test parity) vs user’s macOS local?
3. **Progressed chart** policy for far-future dates — any caps / warnings?
4. Should **Style Guide** react to a “as-of generation date” separate from Daily Fit day?

---

## 11. References in this repo

- `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` — `DailyFitDiagnosticReport`, `generateReport`
- `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — `logDailyFitDiagnostics`, payload assembly
- `Cosmic Fit/UI/ViewControllers/OnboardingFormViewController.swift` / `ProfileViewController.swift` — birth datetime + timezone combination rules
- `Cosmic FitTests/DailyFitDistribution_Tests.swift`, `DailyFitVariation_Tests.swift` — preset profile definitions
- `docs/test_green_handoff.md` — broader calibration runbook

---

## Document history

| Date | Author | Note |
|------|--------|------|
| 2026-05-13 | Planning session | Initial draft |
