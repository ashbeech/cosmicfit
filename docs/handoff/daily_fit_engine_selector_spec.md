# Daily Fit Engine Version Selector — Implementation Spec

**Status:** Production-ready spec (not implemented)  
**Date:** 2026-05-19  
**Audience:** Engineers or AI agents implementing selectable Daily Fit engine presets for inspector and iOS app  
**Related:** [daily_fit_stage2_calibration_handoff.md](./daily_fit_stage2_calibration_handoff.md)

> **Read §1.1, §3.2, and §22 before writing any code.** This spec is designed to prevent unnecessary refactors, logic duplication, and cross-preset regressions.

---

## 1. Executive summary

Cosmic Fit needs a way to run **different Daily Fit engine presets** (e.g. production vs legacy baseline vs future Stage 1 experimental) in the **inspector** and on **device**, without forking the codebase or changing `DailyFitCalibration.default` until a preset is promoted.

This spec defines:

- A single **`DailyFitEngineRegistry`** (canonical preset list)
- **Inspector:** header dropdown + API field + session persistence
- **App:** build-time config via `.env` / xcconfig / Info.plist, plus optional DEBUG runtime override
- **Frozen payloads, tarot recency, and compare cache** behaviour when the active engine changes

**Non-goals:**

- Selecting Style Guide / `BlueprintComposer` version
- Multiple compiled engine binaries
- Letting App Store Release users pick engine versions in UI
- Refactoring working UI, Style Guide pipeline, or Daily Fit rendering
- Moving algorithm code into preset-specific files (until `DailyFitEngineMode` requires it — see §5.4)

---

## 1.1 Implementation guardrails (mandatory)

The app and inspector are **stable today**. The selector is a **thin wiring layer** on top of existing `calibration:` parameters. Implementers must treat this as a **surgical integration**, not a redesign.

### Golden rule

**If a file is not listed in §16 as MUST or MAY, do not edit it.**

When a listed file is edited, change **only** what the phase requires. Do not “clean up”, rename, reformat unrelated code, or “improve” adjacent logic.

### Behaviour preservation (non-negotiable)

| Condition | Required outcome |
|-----------|------------------|
| `dailyFitEngineId == "production"` (or omitted → production) | **Bit-identical** Daily Fit output to today’s shipped behaviour for the same profile, date, blueprint, and tarot history state |
| Release build | **Always** production — no user-visible change from today |
| Inspector with default engine | Same math as app production path |
| Existing frozen payloads (legacy filename) | Still load and display; migration is additive (§8) |

**Verify:** Run `Cosmic FitTests` before and after; production preset must not change golden outputs unless goldens are intentionally regenerated for metadata fields only (`dailyFitEngineId` on payload).

### Forbidden changes (unless explicitly in §16 for a later phase)

- `DailyFitViewController.swift`, Daily Fit UI views, layout, animations, copy
- `BlueprintComposer.swift`, `ColourEngineV4/`, Style Guide narrative path
- `DailyFitCalibration.default` **values** during P0–P5 (only registry wiring and test migration)
- Refactoring `CosmicFitTabBarController` beyond passing `effectiveCalibration` into existing engine calls
- Duplicating weight constants in `EngineConfig`, new config structs, or inspector-only Swift when they belong in `DailyFitCalibration` (see §3.3)
- Adding `if dailyFitEngineId == …` branches scattered through engine code — use registry + `DailyFitEngineMode` (§5.4)
- Changing tarot selection **algorithm** (tie-break, cosine scoring, card loading) as part of selector work
- Touching Supabase sync, onboarding, or profile forms

### Allowed minimal patterns

```swift
// App call site — ONLY change: thread effective calibration
let cal = DailyFitEngineConfig.effectiveCalibration
let snapshot = DailyEnergyEngine.generateSnapshot(..., calibration: cal)
let payload = BlueprintLensEngine.generatePayload(..., calibration: cal)

// Inspector — ONLY change: resolve calibration from request
let cal = DailyFitEngineRegistry.calibration(for: engineId)
DailyFitDiagnostics.generateReport(..., calibration: cal)
```

Do **not** remove default parameters from public engine APIs. Existing call sites and tests rely on `calibration: .default`.

### Phase discipline

Implement **P0 → P8 in order**. Do not combine phases. Do not start P5 (Profile picker) before P1 (config) is merged and tested.

---

## 2. Problem and goal

### 2.1 Goals

- Keep **production** behaviour as default; switch away only for development.
- Run **candidate** presets in inspector and on device before merging to `DailyFitCalibration.default`.
- **Switch back** instantly (inspector UI) or on next build / DEBUG override (app).

### 2.2 User-visible success

- Inspector: change engine in header → Daily Fit output reflects selected preset; compare carousel stays consistent.
- App (DEBUG): change engine → today’s card regenerates under new preset (after invalidation rules).
- Release: always `production`, regardless of misconfigured plist.

---

## 3. Terminology

| Term today | Meaning | This spec |
|------------|---------|-----------|
| `BlueprintComposer.engineVersion` (e.g. `"2.0.0"`) | Style Guide pipeline version | **Unchanged** — not the Daily Fit selector |
| `DailyFitCalibration.default` | Production Daily Fit weights + Stage 2 | Preset id **`production`** |
| “Engine version” (product) | Which Daily Fit preset (+ optional mode) runs | **`dailyFitEngineId`** (string slug) |

**Registry** maps `dailyFitEngineId` → `DailyFitCalibration` (+ future `DailyFitEngineMode`).

### 3.1 Preset ids (initial)

| `dailyFitEngineId` | Purpose |
|--------------------|---------|
| `production` | Current shipped `.default` |
| `legacy_baseline` | Pre–Stage 2 weights (from exploration tests) |
| `stage1_experimental` | Future: Stage 1 code path (register only when behaviour differs) |

Use **semantic slugs**, not version numbers like `daily_fit_v4_7`. Optional `fingerprint` hash on each descriptor for reports.

### 3.2 Exact versioning boundary (what a preset IS and IS NOT)

A **`dailyFitEngineId` preset** is a **named bundle of tunable parameters** passed into the **existing** Daily Fit pipeline. It is **not** a separate engine, binary, or fork of the codebase.

#### Included in every preset (via `DailyFitCalibration`)

| Field | Used in | What it controls |
|-------|---------|------------------|
| `sourceWeights` | `DailyEnergyEngine` | Natal / transits / lunar / progressed / currentSun blend into raw vibe scores |
| `signEnergyMap` | `DailyEnergyEngine` | Per-zodiac multipliers on the six `Energy` values before normalisation |
| `planetAxisMap` | `DailyEnergyEngine` → `DerivedAxesEvaluator` | Planet → action/tempo/strategy/visibility weights |
| `selectionWeights` | `BlueprintLensEngine.selectTarotAndStyleEdit` | Tarot scoring: vibe / axis / transitBoost coefficients |
| `axisTuning` | `DailyEnergyEngine` | Sigmoid spread + per-axis jitter range for derived axes |
| `stage2Sensitivity` | `BlueprintLensEngine` | Palette jitter, vibrancy/contrast coeffs, silhouette axis scale, metal nudge |

**Partially calibrated Stage 2 methods** (no `calibration:` parameter — output varies only indirectly because snapshot inputs change per preset; internal weights are hardcoded and **not tunable per preset** today):

| Method | File | Notes |
|--------|------|-------|
| `deriveStyleEssenceProfile` | `BlueprintLensEngine.swift` | Hardcoded `essenceCategoryWeights` / `essenceAxisModifiers` |
| `selectDailyTextures` | `BlueprintLensEngine.swift` | Hardcoded texture scoring |
| `selectDailyPattern` | `BlueprintLensEngine.swift` | Hardcoded pattern gate |

If these need per-preset tuning in future, extend `DailyFitCalibration` and thread `calibration:` through — do not add preset-id branches.

**Source of truth for struct shape:** `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` (`DailyFitCalibration`).

**Preset definitions live in one file:** `DailyFitEngineRegistry.swift` only. Do not define alternate calibrations in tests, inspector, or app config after migration.

#### Explicitly NOT included in a preset (shared across all ids)

These are **global** — changing them affects **every** preset and is **out of scope** for the selector unless a separate spec says otherwise:

| Category | Files / symbols | Notes |
|----------|-----------------|-------|
| **Pipeline algorithm** | `DailyEnergyEngine.swift`, `BlueprintLensEngine.swift` (control flow, formulas, normalisation) | Same code path for all presets; branch only via future `DailyFitEngineMode` |
| **`EngineConfig` constants** | `EngineConfig.swift` | Recency **window** only (`tarotRecencyWindowDays` → `TarotRecencyTracker`); see §3.3 for penalty math and dead constants |
| **Daily seed** | `DailySeedGenerator` | `profileHash + date` only (§9.2); shared for calibration A/B |
| **Chart / ephemeris** | `NatalChartCalculator`, Swiss Ephemeris, VSOP87 | Identical inputs for all presets |
| **Style Guide** | `BlueprintComposer`, `CosmicBlueprint`, datasets | Input to Stage 2; not selectable via Daily Fit id |
| **Tarot deck data** | `TarotCards.json` | Same deck for all presets |
| **Variant rotation logic** | `TarotVariantRotationTracker`, `selectVariant` | Algorithm shared; **state** namespaced per engine id (§9.1) |
| **UI / persistence shell** | Tab bar, `DailyFitViewController`, reveal flow | Only receives resolved `DailyFitPayload` |
| **Inspector verdict rules** | `VerdictRunner` | Runs on output; must use engine-namespaced recency keys after P3 (§17.1) |

#### Future: when calibration alone is insufficient (`DailyFitEngineMode`)

If a candidate needs **different algorithms** (e.g. Stage 1 redesign: fractional essence, alternate normalisation), the preset descriptor adds `mode: DailyFitEngineMode`. **Only then** may engine code branch on `mode` — in **central, documented** switch points (e.g. start of `generateSnapshot`, start of `generatePayload`), never per preset id string.

Register `stage1_experimental` **only when** `mode != .standard` or calibration differs **and** behaviour is implemented. Do not register a duplicate of production.

### 3.3 `EngineConfig` vs `DailyFitCalibration` — no duplication

Today there is **intentional split**:

- **`DailyFitCalibration`** — all weights that **already** flow through `calibration:` parameters (tarot scoring uses `calibration.selectionWeights`, not `EngineConfig.tarotVibeWeight`).
- **`EngineConfig`** — shared constants. **Not per-preset.**

**Dead constants in `EngineConfig` (do not wire or reference):**

| Constant | Value | Status |
|----------|-------|--------|
| `tarotVibeWeight` | 0.50 | Duplicate of `selectionWeights.vibeWeight` — **never read** in Daily Fit scoring |
| `tarotAxisWeight` | 0.35 | Duplicate of `selectionWeights.axisWeight` — **never read** |
| `tarotTokenBoostWeight` | 0.15 | Duplicate of `selectionWeights.transitBoost` — **never read** |
| `tarotRecencyStrongPenalty` | 0.18 | Feeds `TarotRecencyTracker.YESTERDAY_PENALTY_BASE` — used only by `getCooldownCards`, which is **never called** in production |

**Recency penalty math is hardcoded** in `BlueprintLensEngine.recencyPenalty` (ladder: 0.45 / 0.25 / 0.12 / 0.08, cap 0.7). It is **not** in `DailyFitCalibration` and **not** read from `EngineConfig`. Presets cannot tune recency penalty shape today. If per-preset recency tuning is needed later, add fields to `DailyFitCalibration` and thread through `recencyPenalty` — do not use `EngineConfig`.

**What `EngineConfig` actually affects in Daily Fit today:** only `tarotRecencyWindowDays` (10) via `TarotRecencyTracker.getRecentSelections` window filter.

**Rules for implementers:**

1. **Do not** copy `DailyFitCalibration` fields into `EngineConfig` or vice versa.
2. **Do not** add new tunables to `EngineConfig` as part of this project.
3. If a weight should vary per preset → it belongs in `DailyFitCalibration` (extend struct + thread through existing `calibration:` params).
4. If tarot recency should vary per preset in future → extend registry with optional recency overrides **or** namespace keys (§9.1), not duplicate scoring weights in `EngineConfig`.
5. **`fingerprint`** must hash all six `DailyFitCalibration` fields (stable JSON or sorted key encoding) — not `EngineConfig`.

---

## 4. Architecture

```
                    ┌─────────────────────────────┐
                    │  DailyFitEngineRegistry      │
                    │  (single source of truth)    │
                    └──────────────┬──────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           ▼                       ▼                       ▼
   DailyFitEngineConfig     Inspector request        App build config
   (app only)               options.dailyFitEngineId  DAILY_FIT_ENGINE_ID
           │                       │                  (Info.plist)
           ▼                       ▼                       ▼
   effectiveCalibration    InspectorEngine          CosmicFitTabBarController
   (per process)           generateReport(cal)      generateSnapshot(cal)
           │                       │                       │
           └───────────────────────┴───────────────────────┘
                                   ▼
                    DailyEnergyEngine + BlueprintLensEngine
```

**Principle:** Same Swift module and inspector symlinks; only **which preset/mode** is passed into existing `calibration:` parameters (and future mode branches).

**Inspector:** **Stateless per request** — resolve engine from `request.options.dailyFitEngineId` only. **Do not** use a global mutable `activeEngineId` on the registry (avoids races in `InspectorEngine` actor).

**App:** `DailyFitEngineConfig.effectiveEngineId` is process-wide (build + DEBUG override).

---

## 5. Core module: `DailyFitEngineRegistry`

**Location:** `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift`  
Must live in the **app engine tree** (symlinked by inspector), not inspector-only.

### 5.1 Public API (sketch)

```swift
struct DailyFitEngineDescriptor: Equatable {
    let id: String              // e.g. "production"
    let displayName: String     // e.g. "Production (Stage 2)"
    let summary: String         // one-line for UI
    let isExperimental: Bool
    let calibration: DailyFitCalibration
    let fingerprint: String     // stable hash of calibration for diff reports
    // let mode: DailyFitEngineMode  // future
}

enum DailyFitEngineRegistry {
    static let productionId = "production"
    static let allDescriptors: [DailyFitEngineDescriptor]
    static func descriptor(for id: String) -> DailyFitEngineDescriptor?
    static func calibration(for id: String) -> DailyFitCalibration
}
```

### 5.2 Preset definitions

- Move **`legacyBaseline`** from test-only `CalibrationPresets` in `DailyFitCalibrationExploration_Tests.swift` into registry; tests import registry.
- **`production`** calibration = `DailyFitCalibration.default` (keep `.default` as alias for backward compatibility).
- New candidates: add registry rows only; do **not** change `.default` until promotion.

**`legacy_baseline` canonical values** (must match exploration test today — copy verbatim, do not re-tune):

| Field | `production` (`.default`) | `legacy_baseline` |
|-------|-------------------------|-------------------|
| `sourceWeights` | natal 0.28, transits 0.35, lunar 0.22, progressed 0.10, sun 0.05 | natal 0.40, transits 0.25, lunar 0.15, progressed 0.15, sun 0.05 |
| `signEnergyMap` | (production map) | **same as production** |
| `planetAxisMap` | (production map) | **same as production** |
| `selectionWeights` | 0.50 / 0.35 / 0.15 | **same as production** |
| `axisTuning` | spread 1.4, jitter 0.18 | spread 2.0, jitter 0.1 |
| `stage2Sensitivity` | palette 0.08, vibrancy 0.35, contrast 0.40, silhouette 2.0, metal 0.10 | palette 0.001, vibrancy 0.15, contrast 0.20, silhouette 1.0, metal 0.05 |

### 5.3 Registry invariants

- **`allDescriptors` is the only list** of valid ids — inspector API, app config validation, and tests derive from it.
- **`production` descriptor must reference** `DailyFitCalibration.default` by identity (same struct instance or `.default` literal), never a copied duplicate that could drift.
- **Fingerprints** computed at compile time or lazily once — must change iff any of the six calibration fields change.
- **No runtime mutation** of registry entries or calibrations.

**Fingerprint algorithm (mandatory — do not invent alternatives):**

`DailyFitCalibration` is not `Codable`; fingerprints must use deterministic hand serialization:

1. Build a canonical string from all six fields in fixed order: `sourceWeights` → `signEnergyMap` → `planetAxisMap` → `selectionWeights` → `axisTuning` → `stage2Sensitivity`.
2. Dictionary keys (`signEnergyMap`, `planetAxisMap`) sorted alphabetically at every nesting level.
3. `Energy` enum values serialized as `rawValue` strings (e.g. `"classic"`, `"playful"`).
4. Doubles formatted with fixed precision (e.g. `"%.6f"`) to avoid platform float drift.
5. SHA-256 hash of the UTF-8 canonical string → lowercase hex (first 12 chars sufficient for display; store full hash in descriptor).

Implement as `DailyFitEngineRegistry.fingerprint(for: DailyFitCalibration) -> String` in the registry file. Add unit test: same calibration → same fingerprint; `production` ≠ `legacy_baseline`.

### 5.4 Future: `DailyFitEngineMode` (Stage 1 redesign)

When quantization / essence decoupling ships:

```swift
enum DailyFitEngineMode {
    case standard           // current normaliseToTwentyOne
    case stage1Experimental // transit nudges, fractional essence, etc.
}
```

Preset descriptor carries `mode`; `DailyEnergyEngine` branches on `mode`, not scattered flags.

### 5.5 Invalid id handling

Unknown id in `.env`, plist, or inspector request:

- Fall back to **`production`**
- Log warning (DEBUG) and show warning in inspector status line

---

## 6. App: `.env` → build → runtime

### 6.1 iOS does not read `.env` at runtime

Today:

- `.env` = Python / tooling + documentation
- App config = **`Dev.xcconfig` / `Prod.xcconfig`** → `Cosmic-Fit-Info.plist` → `Bundle.main` (see `SupabaseConfig.swift`)

**Pattern:**

| Layer | Role |
|-------|------|
| `.env` | Human source of truth: `DAILY_FIT_ENGINE_ID=production` |
| `Dev.xcconfig` / `Prod.xcconfig` | `DAILY_FIT_ENGINE_ID = production` |
| `Cosmic-Fit-Info.plist` | `DAILY_FIT_ENGINE_ID` = `$(DAILY_FIT_ENGINE_ID)` |
| `DailyFitEngineConfig.swift` | Reads plist; validates against registry |

**Optional (later):** `tools/sync_env_to_xcconfig.sh` patches only `DAILY_FIT_ENGINE_ID` (must not overwrite Supabase keys).

### 6.2 `DailyFitEngineConfig` (new)

**Location:** `Cosmic Fit/Core/Config/DailyFitEngineConfig.swift`

```swift
enum DailyFitEngineConfig {
    static let buildTimeEngineId: String   // from Info.plist
    #if DEBUG
    static var runtimeOverrideEngineId: String?  // UserDefaults
    #endif
    static var effectiveEngineId: String { ... }
    static var effectiveCalibration: DailyFitCalibration { ... }
}
```

### 6.3 Release vs DEBUG behaviour

| Build | Effective engine |
|-------|------------------|
| **Release** | **Always `production`** — ignore plist non-production values |
| **DEBUG** | `runtimeOverride ?? buildTimeEngineId` (validated via registry) |

`Prod.xcconfig` should still set `DAILY_FIT_ENGINE_ID = production` for clarity.

### 6.4 App selection mechanism (decided)

- **Build default:** `.env` documented → copy to `Dev.xcconfig` → rebuild
- **DEBUG runtime:** Profile screen dropdown → `UserDefaults` override → invalidate + regenerate (see §8)

### 6.5 App call sites (minimal diff only)

Replace implicit `.default` at **Daily Fit generation** entry points only:

| File | Allowed change | Forbidden |
|------|----------------|-----------|
| `CosmicFitTabBarController.swift` | In `generateAndCacheDailyVibe` / `generateDailyPayload`: resolve `let cal = DailyFitEngineConfig.effectiveCalibration`, pass to `DailyEnergyEngine.generateSnapshot(..., calibration: cal)` and `BlueprintLensEngine.generatePayload(..., calibration: cal)` | Reorganise tab bar, change reveal logic, alter blueprint generation, modify UI state |
| `BlueprintLensEngine.logDailyFitDiagnostics` | Add optional `calibration:` param (P4) | Change diagnostic format beyond calibration accuracy |

**Do not** thread calibration through Style Guide composition or `DailyFitViewController`.

### 6.6 DEBUG visibility

- Banner on Daily Fit tab: `Engine: <displayName> (debug)`
- Profile: engine picker + note that Release is locked to production

---

## 7. Inspector: header selector + API

### 7.1 UI — header placement

First control group in `#control-strip` row 1 (before birth preset):

```html
<label for="engine-select">Engine</label>
<select id="engine-select"></select>
<span id="engine-chip" class="engine-chip">production</span>
```

- Populate from `GET /api/daily-fit-engines`
- Persist in session: `dailyFitEngineId` in `readFormInputs` / `applyFormInputs` / `storage.js`
- Compare pane labels: `Target · 18/05/2026 UTC · production`
- Experimental presets: distinct styling + tooltip

### 7.2 API

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/daily-fit-engines` | List `{ id, displayName, summary, isExperimental, fingerprint }` |
| `GET` | `/api/health` | Extend with `dailyFitEngineDefault` (server env default) + registry count |
| `POST` | `/api/inspect` | `options.dailyFitEngineId` (default: server default or `production`) |

**Extend `ResponseMeta`:**

```json
{
  "engineVersion": "2.0.0",
  "dailyFitEngineId": "production",
  "dailyFitEngineDisplayName": "Production (Stage 2)",
  "dailyFitEngineFingerprint": "…"
}
```

- `engineVersion` = Blueprint composer version (unchanged)
- `dailyFitEngineId` = Daily Fit preset

### 7.3 `InspectorEngine.resolve`

```swift
let engineId = request.options?.dailyFitEngineId
    ?? InspectorDefaults.dailyFitEngineId  // from env at server start
let calibration = DailyFitEngineRegistry.calibration(for: engineId)
let (payload, report) = DailyFitDiagnostics.generateReport(..., calibration: calibration)
```

### 7.4 Inspector server default

```bash
DAILY_FIT_ENGINE_ID=legacy_baseline swift run cosmicfit-inspector
```

Sets default for requests that omit `dailyFitEngineId`. Persisted browser session overrides.

### 7.5 Compare modes

| Mode | v1 (required) | v2 (optional) |
|------|---------------|---------------|
| **Compare days** | Same `dailyFitEngineId`, multiple UTC dates | — |
| **Compare engines** | — | Same date, two engine columns |

---

## 8. Frozen payloads and engine switches

### 8.1 Problem

`DailyFitFrozenPayloadStorage` uses `{profileKey}_{yyyy-MM-dd}.json` with **no engine id**. Revealed days show old preset after switching engine.

### 8.2 Policy (decided)

| Mechanism | Behaviour |
|-----------|-----------|
| **Filename** | `{profileKey}_{dailyFitEngineId}_{yyyy-MM-dd}.json` |
| **Payload JSON** | Optional `dailyFitEngineId: String?` — encode on save; missing on decode → `"production"` |
| **Load mismatch** | If stored id ≠ `effectiveEngineId` → treat stale → regenerate |
| **Reveal flag** | `DailyFitRevealPersistence.revealedFlagKey` → `CardRevealed_yyyy-MM-dd` (no engine id today). **P2:** either namespace key to include engine id, **or** rely on existing stale-flag recovery in tab bar (revealed + missing/mismatched frozen file → clear flag + regenerate). Document chosen approach in P2 PR. |
| **DEBUG engine override change** | Invalidate today’s freeze for active profile (clear reveal flag or delete that day’s file) |
| **Force refresh** | Existing `removeAll()` — unchanged |
| **Orphan files** | Old `{profile}_{date}.json` without engine segment may remain until force refresh; acceptable |

### 8.3 Reveal mid-day sequence

1. User reveals under `production` → frozen saved with `dailyFitEngineId: production`
2. User switches to `legacy_baseline` in DEBUG
3. Without invalidation → still sees production freeze (**bug**)
4. **Required:** engine change triggers invalidation for active profile (today minimum)

---

## 9. Tarot, variant rotation, and daily seed

### 9.1 Tarot recency and variant rotation (decided: per-engine)

Isolate keys by `dailyFitEngineId`:

- `TarotRecencyTracker.storageKey(profileHash:date:)` → include engine id
- `TarotVariantRotationTracker.storageKey(card:profileHash:)` → include engine id

Old keys remain in UserDefaults; acceptable for DEBUG. Recommend **reset tarot history** when switching engines in inspector (extend policy: optional auto-reset on engine dropdown change, or document manual use of existing `resetTarotHistory`).

### 9.2 Daily seed (decided: shared seed for calibration-only A/B)

`DailySeedGenerator` hashes `profileHash + date` only — **does not** include engine id.

| Policy | Use |
|--------|-----|
| **S1 — Shared seed** (default for calibration presets) | Same RNG tie-breaks; isolate effect of weight changes |
| **S2 — Seed includes engine id** | Use when `DailyFitEngineMode` diverges |

Document in registry descriptor when S2 applies.

---

## 10. Diagnostics and logging gaps (must fix)

### 10.1 `logDailyFitDiagnostics` mismatch

Today `BlueprintLensEngine.logDailyFitDiagnostics` prints and re-scores tarot using **`DailyFitCalibration.default`** even when payload used another preset.

**Fix:** Pass `calibration` or `dailyFitEngineId` into `logDailyFitDiagnostics`; use for printed weights and tarot re-score block.

### 10.2 `CalibrationSummary` incomplete

`DailyFitDiagnosticReport.calibrationSnapshot` only records source + selection weights — not `axisTuning` or `stage2Sensitivity`.

**Fix:** Extend summary or add `dailyFitEngineId` + `fingerprint` to report; show in inspector Trace tab.

---

## 11. Inspector compare cache (must fix in P0)

**Bug:** `state.compareCache` keyed only by `dateISO`. Changing engine dropdown leaves days 2–N on previous engine.

**Fix:**

- Cache key: `` `${dailyFitEngineId}:${dateISO}` `` (or nested map)
- On `#engine-select` change:
  1. `clearCompareCache()`
  2. Clear or invalidate `state.data` (target day still shows old engine until re-submitted)
  3. If a prior Submit exists (`state.data` was set): auto-resubmit via `doSubmit()` **or** require user to Submit again — **prefer auto-resubmit** so target pane updates immediately
  4. If compare enabled after resubmit: `loadCompareRange()` to re-fetch days 2–N under new engine
- Add `dailyFitEngineId` to `options` in **`buildRequest()`** (single construction point) — `fetchInspectForDate` inherits it via `buildRequest({ composeBlueprint: false })`; do not add engine id only in compare fetch path
- `composeBlueprint: false` date-only fetches still send engine id

**Note:** Compare fetches are **not read-only** — each `POST /api/inspect` writes tarot recency state. Chronological fetch order is intentional (day 2 influences day 3). After engine switch + re-fetch, tarot history for the new engine starts clean (once P3 namespacing is in place).

---

## 12. Scope: Daily Fit only

### 12.1 In scope

| Layer | Components |
|-------|------------|
| **Preset registry** | `DailyFitEngineRegistry`, fingerprints, validation |
| **Resolution** | App config, inspector request field, effective calibration |
| **Engine inputs** | `calibration:` (and future `mode:`) into existing Stage 1/2 APIs |
| **Stateful isolation** | Frozen payloads, tarot recency/variant keys namespaced by engine id |
| **Inspector UX** | Header dropdown, compare cache, response meta, session persistence |
| **DEBUG app UX** | Profile picker, banner (P5) — no Release UI |

### 12.2 Out of scope (do not modify)

| Layer | Components |
|-------|------------|
| **Style Guide** | `BlueprintComposer`, `ColourEngineV4/`, narrative cache, `engineVersion` |
| **Daily Fit UI** | `DailyFitViewController`, card layout, animations, radar rendering |
| **Cloud** | Supabase sync (stores blueprint only) |
| **Onboarding / profile** | Birth form, geocoding (except DEBUG engine picker row) |
| **Separate binaries** | No second inspector target, no forked engine module |

### 12.3 Shared engine code (modify only with `DailyFitEngineMode` — P7+)

`DailyEnergyEngine.swift` and `BlueprintLensEngine.swift` algorithm changes affect **all** presets. For calibration-only presets (P0–P6), these files should receive **no logic changes** — only new parameters already plumbed (`calibration:`).

---

## 13. Promotion and multi-version development

### 13.1 Promotion workflow (calibration → production)

1. Register candidate in registry (`isExperimental: true`).
2. Validate in inspector (profiles, date ranges, compare days).
3. Run `DailyFitCalibrationExploration_Tests` against `DailyFitEngineRegistry.allDescriptors`.
4. When ready: update **`DailyFitCalibration.default` values** in `DailyFitTypes.swift` **or** repoint `production` descriptor to new calibration — **one source, not both diverging**.
5. Reset `.env` / xcconfig to `production`.
6. Update golden fixtures; document force refresh for testers.
7. Remove or keep experimental id as alias only if still needed for regression (document in registry `summary`).

### 13.2 Working on a new engine version (best practice)

This project expects **few presets** (typically 2–3). Complexity comes from **discipline**, not file proliferation.

#### Where work happens

| Work type | Location | Rule |
|-----------|----------|------|
| **New weight tuning** | New row in `DailyFitEngineRegistry.swift` | Copy production calibration, change only intended fields; set `isExperimental: true` |
| **Algorithm redesign** | `DailyEnergyEngine` / `BlueprintLensEngine` + new `DailyFitEngineMode` | Branch on `mode` at **≤2 central entry points**; default branch must preserve current behaviour |
| **Inspector validation** | Inspector UI + exploration tests | Select experimental id in header; never change server global default in committed code |
| **App device testing** | DEBUG Profile picker or `Dev.xcconfig` | Never ship non-production in Release |

#### What NOT to do

- Create `DailyEnergyEngine_v2.swift` or duplicate engine files per preset
- Add `if engineId == "stage1_experimental"` in scoring loops — use `mode`
- Tune `DailyFitCalibration.default` while developing a candidate (keeps production bit-identical)
- Register a preset before its calibration/mode is implemented (empty or duplicate presets forbidden)

#### Branch / PR convention (recommended)

- **Selector wiring PRs** (P0–P6): no `.default` value changes, no algorithm changes
- **Candidate tuning PRs**: registry row + tests only
- **Stage 1 algorithm PRs**: `DailyFitEngineMode` + `stage1_experimental` in same PR; production mode path must pass all existing tests unchanged

#### Concurrent development scenario

| Developer A | Developer B | Safe? |
|-------------|-------------|-------|
| Adds `legacy_baseline` to registry | Adds inspector dropdown | Yes — orthogonal if registry merged first |
| Tweaks `stage1_experimental` mode branch | Tweaks `production` calibration in `.default` | **No** — serialize; production changes require promotion workflow |
| Changes shared tarot algorithm | Adds P2 frozen filename migration | **Risky** — coordinate; shared code affects all presets |

### 13.3 AI agent handoff: “which version am I editing?”

Before any engine work, the agent must answer:

1. **Is this calibration-only or algorithm?** → Calibration: registry only. Algorithm: `DailyFitEngineMode` + central branch.
2. **Which preset id?** → Must exist in `DailyFitEngineRegistry.allDescriptors` or be added there first.
3. **Must production stay bit-identical?** → Yes for P0–P6 and any PR that doesn’t explicitly promote.
4. **Inspector or app?** → Inspector uses request field; app uses `DailyFitEngineConfig` — never hardcode ids in engine core.

---

## 14. Usage scenarios (Inspector, app, CI, future platforms)

| Scenario | Engine resolution | Expected behaviour |
|----------|-------------------|---------------------|
| **Inspector — default session** | `options.dailyFitEngineId` from session storage, else server env default, else `production` | Each `POST /api/inspect` independent; same id across compare days |
| **Inspector — switch engine mid-session** | New id in dropdown → clear compare cache → re-fetch | Days 1–N all same new id; tarot reset recommended |
| **Inspector — compare two dates** | Single `dailyFitEngineId`, multiple dates | Labels show date + engine id |
| **Inspector — compare two engines (P6)** | Single date, two ids | Side-by-side columns; separate tarot state per id |
| **App Release build** | Hard-coded effective `production` | Identical to pre-selector ship |
| **App DEBUG — xcconfig `legacy_baseline`** | Build-time id until Profile override | Today’s card invalidates on first launch with new id (P2) |
| **App DEBUG — Profile override** | `UserDefaults` wins over plist | Invalidate today + regenerate; banner updates |
| **App — user revealed card yesterday** | Frozen file keyed by engine id | Switching engine does not show yesterday’s freeze as today’s card |
| **CI / unit tests** | Explicit `calibration:` or registry id in test | **Never** rely on `effectiveEngineId` or env unless dedicated exploration job |
| **Golden tests** | `production` only | Fail if production preset output changes unexpectedly |
| **Future Android** | Same registry **data** (JSON export of calibrations + mode enum), same ids | Reimplement pipeline in Kotlin; **do not** invent parallel preset names |

### 14.1 Cross-platform contract (future Android / other clients)

When a non-Swift client is added, treat the registry as a **portable contract**:

| Export | Contents |
|--------|----------|
| **`daily_fit_engine_manifest.json`** (generated from registry at build time or checked in) | Array of `{ id, displayName, fingerprint, mode, calibration: { … six fields … } }` |
| **Stable ids** | Same slugs across iOS, inspector, Android |
| **Fingerprint** | SHA of normalised calibration JSON — used in bug reports and A/B diff tooling |
| **Not exported** | Swift-only `EngineConfig`, UI strings, UserDefaults keys |

iOS remains source of truth until a dedicated sync step exists; manifest is **derived**, not hand-edited.

---

## 15. Testing strategy

| Layer | Requirement |
|-------|-------------|
| Unit | Registry: every id resolves; unknown → production + warning |
| Unit | `legacy_baseline` ≠ `production` on fixed chart/date (≥1 surface differs) |
| Inspector tests | API returns correct `dailyFitEngineId`; engine change clears compare cache |
| CI | `DAILY_FIT_ENGINE_ID` unset; tests use explicit calibration, not `effectiveEngineId` |
| Exploration | Loop `DailyFitEngineRegistry.allDescriptors` instead of duplicate `CalibrationPresets` |
| Goldens | Pin to `production`; embed `dailyFitEngineId` when regenerating |

### 15.1 Acceptance criteria

**Inspector**

- [ ] Changing engine clears compare cache and re-loads carousel when compare is on
- [ ] Each compare pane label includes `dailyFitEngineId`
- [ ] Trace/diagnostics show preset fingerprint (including Stage 2 params)
- [ ] `GET /api/health` reports server default engine + registry count

**App (DEBUG)**

- [ ] Effective calibration matches selected engine after Profile change without rebuild
- [ ] DEBUG banner shows `dailyFitEngineId`
- [ ] Switching engine invalidates today’s frozen payload for current profile
- [ ] `logDailyFitDiagnostics` matches effective calibration

**App (Release)**

- [ ] `effectiveEngineId` always `production` regardless of plist

**Regression**

- [ ] Full `Cosmic FitTests` pass with no `DAILY_FIT_ENGINE_ID` in environment
- [ ] `production` preset output unchanged on fixed fixture vs pre-implementation baseline

---

## 16. Implementation phases

| Phase | Deliverable | Do **not** |
|-------|-------------|------------|
| **P0** | `DailyFitEngineRegistry` + fingerprints; move `legacy_baseline` from tests; inspector API + header dropdown; **compare cache by engine**; meta fields; session persistence | Change `.default` values; touch app tab bar; refactor engine algorithms |
| **P1** | `DailyFitEngineConfig` + plist/xcconfig/`.env.example`; Release hard-lock; wire tab bar call sites | Add Profile UI; change frozen storage format |
| **P2** | Frozen filename namespace + optional `dailyFitEngineId` on payload + DEBUG invalidation on switch | Break loading of legacy `{profile}_{date}.json` files |
| **P3** | Per-engine tarot/variant keys; inspector tarot reset policy on engine change | Change tarot scoring formulas |
| **P4** | Fix `logDailyFitDiagnostics` + extend `CalibrationSummary` / trace UI | Rewrite diagnostics layout |
| **P5** | DEBUG Profile engine picker + Daily Fit banner | Any Release-visible engine UI |
| **P6** | Compare-two-engines column in inspector (optional) | Required for P0–P5 completion |
| **P7** | `DailyFitEngineMode` + `stage1_experimental` when Stage 1 code exists | Register experimental without mode implementation |
| **P8** | `.env` → xcconfig sync script (optional) | Overwrite unrelated xcconfig keys |

---

## 17. Files to touch (explicit allowlist)

### 17.1 MUST create or modify (by phase)

| Phase | File | Change summary |
|-------|------|----------------|
| P0 | `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift` | **New** — sole preset definitions |
| P0 | `Cosmic FitTests/DailyFitCalibrationExploration_Tests.swift` | Import registry; delete duplicate `CalibrationPresets` |
| P0 | `inspector/.../InspectorRequest.swift`, `InspectorEngine.swift`, `InspectorResponse.swift` | `dailyFitEngineId` field + resolve calibration |
| P0 | `inspector/.../InspectorDefaults.swift` | **New** — server env default |
| P0 | `inspector/.../Routes.swift`, `Web/*` | API + dropdown + compare cache fix |
| P1 | `Cosmic Fit/Core/Config/DailyFitEngineConfig.swift` | **New** |
| P1 | `Cosmic-Fit-Info.plist`, `Dev.xcconfig.example`, `.env.example` | Build key |
| P1 | `Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift` | Pass `effectiveCalibration` only |
| P2 | `DailyFitFrozenPayloadStorage.swift`, `DailyFitTypes.swift` | Filename + optional payload field |
| P3 | `TarotRecencyTracker.swift`, `TarotVariantRotationTracker.swift` | Key suffix with engine id |
| P3 | `inspector/.../VerdictRunner.swift` | Pass engine id into `checkTarotRecency` so recency verdict uses namespaced tracker keys |
| P4 | `BlueprintLensEngine.swift`, `DailyFitDiagnostics.swift` | Diagnostics accuracy |
| P5 | `ProfileViewController.swift` | DEBUG picker + banner hook only |

### 17.2 MUST NOT modify (unless separate approved spec)

| File / area | Reason |
|-------------|--------|
| `DailyFitViewController.swift` and Daily Fit views | UI stable; payload-driven |
| `BlueprintComposer.swift`, `ColourEngineV4/**` | Style Guide — separate version axis |
| `DailyFitCalibration.default` **values** during P0–P5 | Preserves regression baseline |
| `EngineConfig.swift` | Shared constants — not preset surface (§3.3) |
| `OnboardingFormViewController.swift` | Unrelated |
| `SupabaseSyncService.swift` | No Daily Fit engine field in cloud today |

### 17.3 MAY modify (minimal, when phase requires)

| File | Condition |
|------|-----------|
| `DailyFitTypes.swift` | Add optional `dailyFitEngineId` on `DailyFitPayload` (P2); do not restructure types |
| `inspector/README.md`, root `README.md` | Document config only |
| New test files | Registry unit tests, inspector engine id tests |

### 17.4 Symlink rule (inspector)

Inspector compiles app engine via symlinks under `inspector/Sources/CosmicFitInspectorLib/`. **`DailyFitEngineRegistry.swift` must live in `Cosmic Fit/InterpretationEngine/`** so inspector and app share one definition — never duplicate registry in `inspector/Sources`.

New `.swift` files placed in `Cosmic Fit/InterpretationEngine/` are **auto-discovered** by the inspector SPM target via the existing `InterpretationEngine` symlink — no Package.swift or target membership changes required. Do not create a copy under `inspector/Sources/`.

---

## 18. Edge cases and notes

### 18.1 Timezone

- Frozen files use **`TimeZone.current`**; inspector compare labels use **UTC**.
- Engine selector does not change this; document in inspector UI.

### 18.2 `resetTarotHistory`

- Existing `options.resetTarotHistory` on inspect.
- **Recommended (P3):** auto-set `resetTarotHistory: true` on first inspect after engine dropdown change, or document manual reset in inspector README.

### 18.3 XCTest / CI

- Do not set `DAILY_FIT_ENGINE_ID` in CI unless running a dedicated preset comparison job.
- Unit tests must pass explicit `calibration:` — never assume `DailyFitEngineConfig.effectiveEngineId` unless testing that config type directly.

### 18.4 Experimental preset duplicate of production

- Do not register `stage1_experimental` until behaviour differs; Release hard-lock prevents accidental ship.
- Add unit test: `production` and `legacy_baseline` fingerprints **must differ**.

### 18.5 UI confusion: two “engine versions”

- Tooltip: **Blueprint** `engineVersion` (Style Guide) vs **Daily Fit** `dailyFitEngineId` (daily card pipeline).

### 18.6 Inspector session restore

- If restored `dailyFitEngineId` differs from keys in `compareCache`, clear cache on load.

### 18.7 Unknown or deprecated engine id in saved session

- Fall back to `production`, show warning in status line, persist corrected id back to session storage.

### 18.8 Unknown engine id in legacy frozen filename

- Treat as stale → regenerate under current `effectiveEngineId` (same as load mismatch in §8).

### 18.9 App killed mid-switch (DEBUG Profile picker)

- On next launch, read override from UserDefaults; if frozen file engine id ≠ effective id, invalidate today (§8).

### 18.10 Multiple profiles / charts on device

- Engine id is **global per app install** (DEBUG override and build config), not per profile — same as today’s single calibration. Document in Profile picker copy.

### 18.11 `composeBlueprint: false` inspector requests

- Still require `dailyFitEngineId` in request body for Daily Fit portion; blueprint cache unaffected.

### 18.12 Promoting calibration while users have experimental frozen files

- Orphan experimental freezes remain on disk until force refresh; acceptable. Promotion does not migrate old files.

### 18.13 Accidental scope creep (AI implementer)

- If a task requires editing a §17.2 MUST NOT file, **stop** and split work — wire selector first in allowlisted files, then open a separate spec/PR for other changes.

---

## 19. Risk register

| Risk | Severity | Mitigation |
|------|----------|------------|
| Unnecessary refactor of stable UI/engine | **High** | §1.1, §17 allowlist |
| Stale compare cache after engine change | **High** | §11 |
| Misleading DEBUG console logs | **Medium** | §10.1 |
| Frozen payload after engine switch | **High** | §8 |
| CI flakiness from env var | **Medium** | §15, §18.3 |
| Registry / inspector drift | **Low** | Single file in engine module (§17.4) |
| Confusion with Blueprint `engineVersion` | **Medium** | §18.5 |
| Duplicate logic in `EngineConfig` vs calibration | **Medium** | §3.3 |
| Stage 1 not representable as calibration-only | **Medium** | `DailyFitEngineMode` before Stage 1 code (§5.4) |
| Production behaviour drift during implementation | **High** | Bit-identical rule §1.1; golden tests §15 |

---

## 20. Decisions log (resolved)

| ID | Question | Decision |
|----|----------|----------|
| D1 | Scope of “engine” | Daily Fit only |
| D2 | App selection | Build default via xcconfig + DEBUG Profile picker |
| D3 | `.env` vs xcconfig | Manual copy documented first; sync script optional later |
| D4 | Release safety | Hard-lock `production` in non-DEBUG |
| D5 | Frozen payloads | Namespace + JSON field + regenerate on mismatch |
| D6 | Inspector compare engines v1 | Day compare with engine in label; side-by-side engines v2 |
| D7 | Tarot recency | Per `dailyFitEngineId` |
| D8 | Preset naming | Semantic slugs |
| D9 | Invalid id | Fallback to `production` + warning |
| D10 | Initial presets | `production` + `legacy_baseline` only at P0 |
| D11 | Daily seed | Shared (S1) for calibration A/B; per-engine (S2) when mode diverges |
| D12 | Inspector global state | Request-scoped only; no mutable registry active id |
| D13 | Unnecessary file edits | Explicit MUST / MUST NOT allowlist (§17) |
| D14 | Preset tunable surface | Exactly `DailyFitCalibration` six fields (§3.2) |
| D15 | Multi-version dev | Registry + mode branching; no per-preset engine forks (§13.2) |

---

## 21. Related artifacts

| Artifact | Path |
|----------|------|
| Stage 2 calibration handoff | `docs/handoff/daily_fit_stage2_calibration_handoff.md` |
| Exploration presets (to migrate) | `Cosmic FitTests/DailyFitCalibrationExploration_Tests.swift` |
| Inspector README | `inspector/README.md` |
| Production calibration source of truth | `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` |
| Calibration struct definition | `DailyFitTypes.swift` → `DailyFitCalibration` |
| Current app Daily Fit entry | `CosmicFitTabBarController.swift` → `generateAndCacheDailyVibe` |

---

## 22. AI implementer checklist (sign-off before PR)

Use this as a PR description template. **All boxes must be checked.**

### Scope

- [ ] Every edited file appears in §17.1 or §17.3 for the claimed phase(s)
- [ ] No §17.2 files modified
- [ ] Phase order respected (P0 before P1, etc.)
- [ ] `DailyFitCalibration.default` values unchanged (unless explicit promotion PR)

### Correctness

- [ ] `production` preset uses `.default` — not a copied struct
- [ ] `legacy_baseline` matches §5.2 table verbatim
- [ ] Unknown ids fall back to `production` with warning
- [ ] Release build ignores non-production plist values
- [ ] Inspector resolves engine per request (no global mutable active id)

### Regression

- [ ] `Cosmic FitTests` pass locally without `DAILY_FIT_ENGINE_ID` in environment
- [ ] Production golden / exploration output unchanged for `production` id
- [ ] Existing legacy frozen payloads still decode (P2+)

### Inspector (if P0+)

- [ ] Compare cache keyed by `dailyFitEngineId:dateISO`
- [ ] Engine change clears cache and re-fetches compare range
- [ ] Response meta includes `dailyFitEngineId` + fingerprint

### App (if P1+)

- [ ] Tab bar passes `effectiveCalibration` only — no other tab bar changes
- [ ] DEBUG invalidates today on engine switch (P2+)

### Documentation

- [ ] `inspector/README.md` updated if behaviour visible to users
- [ ] `.env.example` documents `DAILY_FIT_ENGINE_ID` (P1+)

---

*End of spec.*
