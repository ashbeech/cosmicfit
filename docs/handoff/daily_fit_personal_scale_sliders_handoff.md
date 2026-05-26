# Daily Fit — Personal Scale Sliders (Vibrancy, Contrast, Metal Tone)

**Status:** Spec — ready for implementation  
**Date:** 2026-05-23  
**Audience:** Engineer or AI agent implementing user-relative scale presentation  
**Scope:** **Presentation layer + payload metadata** for Vibrancy, Contrast, and Metal Tone sliders. **Out of scope:** changing derivation math for metal tone vs Style Guide hardware, silhouette sliders, new user-facing copy, production engine promotion.

**Related docs:**

| Doc | Role |
|-----|------|
| [`daily_fit_sky_forward_handoff.md`](./daily_fit_sky_forward_handoff.md) | “Today vs chart anchor” product intent |
| [`daily_fit_stage1_experimental_app_readiness_handoff.md`](./daily_fit_stage1_experimental_app_readiness_handoff.md) | App vs inspector parity, Stage 1 UI gaps |
| [`daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](./daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md) | Narrative scale directives (`soften` caps) |
| [`docs/archive/daily_fit_rebuild/PHASE_4_PALETTE_TEXTURES_ASSEMBLY.md`](../archive/daily_fit_rebuild/PHASE_4_PALETTE_TEXTURES_ASSEMBLY.md) | Original Blueprint-as-Lens scale derivation |
| [`docs/archive/daily_fit_rebuild/PHASE_5_UI_INTEGRATION.md`](../archive/daily_fit_rebuild/PHASE_5_UI_INTEGRATION.md) | Current diamond-scale UI wiring |

---

## 0. Implementation handoff prompt (copy-paste)

Give the block below verbatim to an engineer or AI agent at the start of the task. The spec body (§1–§16) is the authoritative design; this prompt governs *how* to execute it.

---

```
Implement the Daily Fit Personal Scale Sliders feature per the spec in:

  docs/handoff/daily_fit_personal_scale_sliders_handoff.md

Read that document in full before writing code. Treat §6 (envelope formulas), §8 (edge cases),
§10 (tests), and §13 (acceptance criteria) as hard gates — not suggestions.

## Mission

Remap Vibrancy, Contrast, and Metal Tone slider diamonds from absolute 0–1 positions to
user-relative display positions derived from each user's Style Guide + active engine preset.
Preserve all absolute engine outputs on DailyFitPayload unchanged.

## Non-negotiable constraints

1. DISPLAY ONLY — do not change deriveVibrancy, deriveContrast, or deriveMetalTone formulas.
2. Do not remap or replace payload.vibrancy / contrast / metalTone stored values.
3. Do not add new user-facing copy (no "Your range", no metal names on the slider).
4. Do not modify production calibration, NarrativeIntentEngine, or engine fingerprints.
5. Do not personalize silhouette sliders in this pass.
6. Envelope bounds MUST live in InterpretationEngine (PersonalScaleEnvelope.swift) — never
   duplicate mapping math in DailyFitViewController.
7. Legacy frozen payloads without scalePresentation must still render (absolute fallback +
   metal 3-snap).

## Required reading (skim before coding)

- docs/handoff/daily_fit_personal_scale_sliders_handoff.md (this spec — primary)
- Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift — deriveVibrancy/Contrast/MetalTone
- Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift — refreshDiamondScalePositions,
  snapToThreePositions, buildVibrancyScale / buildContrastScale / buildMetalToneScale
- docs/handoff/daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md — soften caps (§15.6)

## Deliver in three phases — do not skip tests between phases

### Phase A — Engine metadata (mergeable on its own)

- [ ] NEW PersonalScaleEnvelope.swift — types, calculator, makePresentation()
- [ ] scalePresentation: PersonalScalePresentation? on DailyFitPayload (optional Codable)
- [ ] Wire into BlueprintLensEngine.generatePayload / generatePayloadWithTrace
- [ ] PersonalScaleEnvelope_Tests.swift — all P1–P10 from spec §10.1
- [ ] Integration: I1–I3 (payload populated, round-trip, legacy decode)
- [ ] Confirm absolute vibrancy/contrast/metalTone unchanged for fixed inputs vs baseline

Stop and run: xcodebuild test — PersonalScaleEnvelope_Tests, DailyFitTypes_Tests,
BlueprintLensEngine_Payload_Tests (T4.18, T4.26 must still pass).

### Phase B — UI remap

- [ ] DailyFitViewController uses displayPosition when scalePresentation != nil
- [ ] Remove metal tone snapToThreePositions for new payloads; keep for legacy fallback
- [ ] Add baseline tick on all three tracks (spec §7.1 — 2pt, muted cosmic blue @ 50%)
- [ ] UI tests U1–U2; DailyFitUIIntegration_Tests updated

Stop and run full Cosmic FitTests locally.

### Phase C — Inspector diagnostics

- [ ] DailyFitDiagnostics exports floor/ceiling/baseline/displayPosition per scale
- [ ] Inspector markdown trace rows under Vibrancy/Contrast/Metal Tone Derivation
- [ ] Optional verdict: displayPosition ∈ [0, 1] (non-blocking)

Rebuild inspector: cd inspector && ./run-inspector.sh

## Verification before calling done

1. Briar 14-day (stage1_experimental): I4 + I5 + §13 — metal displayPosition stddev > 0.05;
   contrast ≥ 3 distinct display positions; no metal day stuck at 0.5 by snap.
2. Soft-saturation fixture: low-vibrancy day displayPosition approaches 0.
3. High-contrast fixture: displayPosition floor effect (never near 0) — intentional.
4. Legacy JSON without scalePresentation decodes and renders without crash.
5. Inspector trace shows personal floor/ceiling/display alongside absolute values.

Use SkyForwardV2Support / Briar harness in DailyFitSkyForwardV2_Tests.swift for automated
14-day checks where possible; add tests if missing (I4, I5).

## Code quality standards

- Match existing InterpretationEngine conventions (private static helpers, no print(), no force-unwraps).
- Minimal diff — do not refactor unrelated DailyFitViewController sections.
- Single source of truth for envelope math; UI only reads precomputed displayPosition.
- Comments only for non-obvious envelope edge cases (E1 degenerate range, E2 clamp overshoot).
- New types get Codable + Equatable if attached to payload.

## Definition of done

All items in spec §13 Acceptance criteria checked, all §10 tests implemented and green,
phases A–C complete, no regressions to production fingerprint or absolute payload values.
Summarize: files changed, test counts, Briar 14-day display range stats, any deferred items from §15.
```

---

## 1. Executive summary

Daily Fit currently plots **absolute** engine values (0.0–1.0) on **universal** tracks. That miscommunicates the product story:

- A Medium Contrast user at **0.53** looks “low” on a population scale but is **slightly above their norm**.
- Briar’s Metal Tone varies **0.44 → 0.73** across 14 days but the UI **snaps every day to “Mixed”** (`snapToThreePositions`), so the slider never moves.
- A Soft Saturation user’s meaningful daily swing occupies a narrow band (e.g. 0.25–0.45) and never uses the full track width.

**Decision (Ash + astrology + fashion partners):** All three scales — **Vibrancy, Contrast, Metal Tone** — must display on a **personal range** per user. The diamond should travel from **one end of the track (personal minimum)** to the **other (personal maximum)**, preserving engine nuance while making “where you are today” legible *for you*.

**Critical constraint:** This is a **display remap**, not a derivation rewrite. Absolute `vibrancy`, `contrast`, and `metalTone` on `DailyFitPayload` **stay unchanged** for calibration, inspector traces, frozen payloads, and tests. Metal tone must **not** gain a stronger Style Guide hardware bond — engine logic remains as-is; only presentation becomes personal.

---

## 2. Product intent

### 2.1 What the user should feel

| Scale | Left pole (personal min) | Right pole (personal max) | Today’s read |
|-------|--------------------------|---------------------------|--------------|
| **Vibrancy** | As muted as this user ever gets | As rich/vivid as this user ever gets | “Today is toward my soft side / toward my bold side” |
| **Contrast** | As soft/low-contrast as this user ever gets | As bold/high-contrast as this user ever gets | “Today is a quieter contrast day / a sharper one” |
| **Metal tone** | As cool as this user ever gets | As warm as this user ever gets | “Today skews cool / mixed / warm **within my band**” |

The track is **not** “the whole world from 0 to 1.” It is **your wardrobe bandwidth** for that dimension, as defined by your Style Guide variables plus the engine’s daily modulation envelope.

### 2.2 What we are NOT doing

| Non-goal | Reason |
|----------|--------|
| Change `deriveMetalTone` to weight hardware metals more | Explicit product decision — metal tone stays sky-forward free; hardware already contributes 40% of baseline only |
| Show literal metal names on the slider | Avoid overclaiming “wear brass today”; keep Cool / Mixed / Warm semantics |
| Remap stored payload values to 0–1 | Breaks inspector, fingerprints, frozen JSON, calibration tests |
| Add generated explanatory copy | Narrative unification forbids new Daily Brief strings |
| Personalize silhouette sliders in this pass | Out of scope (separate baseline-tick work exists in sky-forward handoff §9.1) |

---

## 3. Current state (problem audit)

### 3.1 Engine (correct — keep)

All three scales are **blueprint-anchored + daily modulation**, clamped to `[0, 1]`:

```
finalAbsolute = clamp(baseline + dailyModulation + narrativeDirectiveEffects, 0, 1)
```

| Scale | Baseline source | Daily modulation (Stage 1) |
|-------|-----------------|----------------------------|
| Vibrancy | `palette.variables.saturation` → 0.25 / 0.50 / 0.75 | Sky vibe push/pull + tempo axis |
| Contrast | `palette.variables.contrast` → 0.25 / 0.50 / 0.75 | Visibility + strategy axes |
| Metal tone | 60% palette temperature + 40% metal keyword scan | Fire/water transits + lunar phase/degree |

Baselines and modulations are already traced in inspector (`ScaleDerivationTrace`) but **not exposed on `DailyFitPayload`**.

### 3.2 UI (broken for product intent)

`DailyFitViewController.refreshDiamondScalePositions()`:

```swift
updateDiamondScale(..., value: payload.vibrancy)      // absolute 0–1
updateDiamondScale(..., value: payload.contrast)      // absolute 0–1
let snappedMetal = Self.snapToThreePositions(payload.metalTone)  // collapses to {0, 0.5, 1}
updateDiamondScale(..., value: snappedMetal)
```

**Briar 14-day Metal Tone (absolute):** 0.437 – 0.728 → **all render as Mixed (0.5)**.  
**Briar 14-day Contrast (absolute):** 0.532 – 0.702 → clusters in the upper-middle of a universal track, never near either end.

---

## 4. Solution overview — Personal Scale Envelope

Introduce a **Personal Scale Envelope** per scale: `{ floor, ceiling, baseline, value }`.

- **`floor` / `ceiling`:** Deterministic personal min/max **absolute** values this user can reach under the active engine preset (see §6).
- **`baseline`:** Style Guide anchor (same as today’s `blueprintBaseline` in traces).
- **`value`:** Today’s absolute engine output (same as `payload.vibrancy` etc.).

**Display position** (what the diamond uses):

```
displayPosition = clamp((value - floor) / (ceiling - floor), 0, 1)
```

When `ceiling - floor` is below epsilon, fall back to `0.5` (degenerate range guard).

**Optional baseline tick** (recommended): show a subtle marker at:

```
baselinePosition = clamp((baseline - floor) / (ceiling - floor), 0, 1)
```

This gives “your usual” vs “today” without extra copy.

### 4.1 Layering model

```
┌─────────────────────────────────────────────────────────┐
│  Engine (unchanged)                                      │
│  deriveVibrancy / deriveContrast / deriveMetalTone       │
│  → absolute value on DailyFitPayload                       │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│  PersonalScaleEnvelope (NEW)                             │
│  Computed at payload assembly from blueprint + engine    │
│  → floor, ceiling, baseline per scale                    │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│  UI (DailyFitViewController)                             │
│  displayPosition = normalize(value, floor, ceiling)      │
│  Remove metal tone 3-position snap                       │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Architecture

### 5.1 New module: `PersonalScaleEnvelope.swift`

Location: `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift`

Responsibilities:

1. **`PersonalScaleKind`** enum: `.vibrancy`, `.contrast`, `.metalTone`
2. **`PersonalScaleEnvelope`** struct: `floor`, `ceiling`, `baseline`, `value`, `displayPosition`, `baselinePosition`
3. **`PersonalScaleEnvelopeCalculator`** — static methods to compute envelopes from:
   - `CosmicBlueprint`
   - `DailyFitCalibration`
   - `DailyFitEngineMode`
   - Optional `NarrativeSelectionTuning` (for directive-aware ceilings)
4. **`PersonalScalePresentation`** — bundle of three envelopes for payload/UI

**Single source of truth:** Envelope bounds MUST be computed in the InterpretationEngine (shared with inspector), not duplicated in UI.

### 5.2 Integration point

Compute envelopes inside `BlueprintLensEngine.generatePayload` / `generatePayloadWithTrace` **after** final absolute values are known:

```swift
let presentation = PersonalScaleEnvelopeCalculator.makePresentation(
    blueprint: blueprint,
    calibration: calibration,
    mode: effectiveMode,
    vibrancy: vibrancy,
    contrast: contrast,
    metalTone: metalTone
)
```

Attach to payload (§5.3). Inspector diagnostics can echo the same struct for QA.

### 5.3 Payload change

Add to `DailyFitPayload`:

```swift
/// User-relative scale metadata for UI presentation. nil on legacy frozen payloads.
let scalePresentation: PersonalScalePresentation?
```

**Backward compatibility:**

| Scenario | Behaviour |
|----------|-----------|
| New generation | `scalePresentation` populated |
| Frozen JSON without field | Decode as `nil` → UI falls back to **legacy absolute** positioning (current behaviour) |
| Field present | UI uses personal remap |

Do **not** bump engine fingerprint for this change alone — presentation metadata is derived from existing inputs and does not affect selection outcomes. Document in release notes only.

### 5.4 UI change

`DailyFitViewController`:

1. Remove `snapToThreePositions` for metal tone (or restrict to legacy fallback only).
2. `refreshDiamondScalePositions()` reads `payload.scalePresentation?.vibrancy.displayPosition` when non-nil.
3. Add optional baseline tick views on each track (small vertical tick or dot at `baselinePosition`).
4. Endpoint labels stay **semantic** (see §7) — they now mean personal poles, not population extremes.

---

## 6. Envelope bound computation (per scale)

Bounds are **analytical** — derived from blueprint enums + engine constants + axis/vibe legal ranges. They are **stable per (blueprint hash, engine id)** and do not require historical observation.

All bounds are clamped to `[0, 1]` after computation.

### 6.1 Shared inputs

| Input | Range | Source |
|-------|-------|--------|
| Axis values | 1.0 – 10.0 | `scaleToAxis` sigmoid output |
| Vibe integers | 0 – 10 each, sum = 21 | `VibeBreakdown` |
| Transit fire/water hits | 0 – 5 (dominant transit limit) | `snapshot.dominantTransits` |
| Lunar phase degrees | 0 – 360 | `snapshot.lunarContext` |

### 6.2 Contrast envelope

**Baseline** (`contrastBaseline`):

| `ContrastLevel` | Baseline |
|-----------------|----------|
| `.low` | 0.25 |
| `.medium` | 0.50 |
| `.high` | 0.75 |
| `nil` | 0.50 |

**Modulation extrema** (before narrative directives):

| Mode | Formula | Min modulation | Max modulation |
|------|---------|----------------|----------------|
| `.standard` | `(visNorm - 0.5) * contrastCoeff` | `(0.1 - 0.5) * coeff` | `(1.0 - 0.5) * coeff` |
| `.stage1Experimental` | `((visNorm - 0.5)*0.6 + (strNorm - 0.5)*0.4) * coeff` | `-0.22 * coeff` | `+0.22 * coeff` |

With Stage 1 `contrastCoeff = 0.55`: modulation ∈ **[−0.121, +0.121]**.

**Narrative directive adjustment (bounds only):**

| Relationship | Effect on achievable range |
|--------------|----------------------------|
| `soften` | Effective ceiling = `min(computedCeiling, softenContrastCap)` where cap = **0.70**; floor unchanged |
| `stretch` + `intenseAnchorRestrainedWeather` | Pulls toward baseline — narrows effective spread but does not expand beyond analytical bounds |
| `reinforce`, `contrast`, default stretch | No bound change |

**Conservative envelope (recommended for v1):**

```
contrastFloor   = clamp(baseline + minModulation, 0, 1)
contrastCeiling = clamp(baseline + maxModulation, 0, 1)
// Optionally tighten ceiling for Stage 1 presets:
if narrativeSelection != nil {
    contrastCeiling = min(contrastCeiling, softenContrastCap)
}
```

**Example — Briar (Medium contrast, Stage 1):**

| Field | Value |
|-------|-------|
| baseline | 0.50 |
| floor | 0.379 |
| ceiling | 0.621 (or 0.621 pre-cap; soften cap 0.70 does not bind) |
| Day min (2026-06-04) | 0.532 → **display 0.63** |
| Day max | 0.702 → **display 1.0** (clamped at ceiling) |

Previously 0.532 looked “mid-low” on a universal track; on the personal track it reads **upper-mid of her band** (not “low contrast” globally).

### 6.3 Vibrancy envelope

**Baseline** (`saturation`):

| Level | Baseline |
|-------|----------|
| `.soft` | 0.25 |
| `.muted` | 0.50 |
| `.rich` | 0.75 |
| `nil` | 0.50 |

**Modulation extrema:**

| Mode | Components | Approx min | Approx max |
|------|------------|------------|------------|
| `.standard` | `(push - pull) * vibrancyCoeff` | `−1.0 * coeff` | `+(20/21) * coeff` |
| `.stage1Experimental` | vibe term `* 0.80` + tempo `(tempoNorm - 0.5) * 0.30` | `≈ −0.92` | `≈ +0.91` |

**Narrative:** `soften` caps ceiling at **0.72** (`softenVibrancyCap`).

```
vibrancyFloor   = clamp(baseline + minModulation, 0, 1)
vibrancyCeiling = clamp(baseline + maxModulation, 0, 1)
if narrativeSelection != nil { vibrancyCeiling = min(vibrancyCeiling, softenVibrancyCap) }
```

Soft Summer (baseline 0.25): floor ≈ **0.0**, ceiling ≈ **0.72** (cap-bound) — full track usable.  
Deep Autumn (baseline 0.75): floor ≈ **0.0**, ceiling ≈ **1.0** — full track usable.

### 6.4 Metal tone envelope

**No engine changes.** Bounds reflect **existing** `deriveMetalTone` formula.

**Baseline:**

```
tempVal = { cool: 0.2, neutral: 0.5, warm: 0.8, nil: 0.5 }
metalLean = warmCount / max(1, warmCount + coolCount)   // from recommendedMetals keyword scan
baseline = tempVal * 0.6 + metalLean * 0.4
```

**Modulation extrema** (independent of which transits happen on a given day):

| Component | Stage 1 max |
|-----------|-------------|
| Fire nudge | `+min(fireHits * metalNudgePerHit, 0.30)` → up to **+0.30** at 5 hits |
| Water nudge | `−min(waterHits * metalNudgePerHit, 0.30)` → up to **−0.30** |
| Lunar named phase | `±0.03` |
| Lunar degree mod (Stage 1) | `(phaseDegrees/360 − 0.5) * 0.15` → **±0.075** |

**Conservative simultaneous extrema:**

```
maxPositiveNudge = nudgeCap + 0.03 + 0.075   // ≈ +0.405 Stage 1
maxNegativeNudge = nudgeCap + 0.03 + 0.075   // ≈ −0.405 Stage 1
metalFloor   = clamp(baseline - maxNegativeNudge, 0, 1)
metalCeiling = clamp(baseline + maxPositiveNudge, 0, 1)
```

**Example — Briar (baseline ≈ 0.594, Stage 1):**

| Field | Value |
|-------|-------|
| floor | ≈ 0.189 |
| ceiling | ≈ 0.999 |
| Observed 14d min 0.437 | display ≈ **0.31** |
| Observed 14d max 0.728 | display ≈ **0.67** |

Metal tone slider **moves visibly** across the personal band; Cool / Mixed / Warm labels remain valid as **directional** hints (see §7).

---

## 7. UI specification

### 7.1 Track behaviour

| Element | Spec |
|---------|------|
| Diamond position | `displayPosition * trackWidth` |
| Baseline tick | Optional 2pt vertical tick at `baselinePosition`; colour: muted cosmic blue @ 50% alpha |
| End labels | Keep existing: Vibrancy (implicit gradient), Contrast (halftone gradient), Metal Tone **Cool · Mixed · Warm** |
| Metal tone snap | **Remove** for payloads with `scalePresentation`; legacy fallback only |

**Label semantics after remap:**

- **Cool / Warm** on metal tone = personal poles, not “pure silver” vs “pure gold” globally.
- **Mixed** centre label = midpoint of **personal** range, which approximates “your neutral” — not necessarily engine value 0.5.

### 7.2 No new copy

Do not add “Your range”, “Today vs usual”, or metal name subtitles in v1. Baseline tick + full track travel is sufficient per narrative unification rules.

### 7.3 Accessibility

VoiceOver: expose absolute value in debug builds only; production reads “Vibrancy, {low|mid|high} for your palette” derived from displayPosition tertiles if needed later — **defer** unless requested.

---

## 8. Edge cases & scenarios

### 8.1 Matrix

| # | Scenario | Expected behaviour |
|---|----------|-------------------|
| E1 | `ceiling - floor < 0.001` | `displayPosition = 0.5`; log in DEBUG |
| E2 | `value` slightly outside `[floor, ceiling]` due to future engine tweak | Clamp display to `[0, 1]`; do not crash |
| E3 | Legacy frozen payload, no `scalePresentation` | Absolute positioning + metal 3-snap (current) |
| E4 | Soft saturation user | Wide upward room; floor near 0 — diamond can approach left end |
| E5 | High contrast user | Floor anchored ≥ 0.50 analytically — may never approach absolute 0 on personal track (correct: they don’t dress low-contrast) |
| E6 | Low contrast user | Ceiling ≤ 0.50 analytically — may never approach absolute 1 (correct) |
| E7 | Soften narrative day | `value` lower in band; diamond moves left; no special casing |
| E8 | User with gold + silver metals (mixed baseline ~0.6) | Metal track spans cool↔warm; sky can push either direction |
| E9 | Cool palette + all warm metals (or vice versa) | Baseline still blended 60/40; envelope remains valid |
| E10 | Production vs Stage 1 same blueprint | Different envelopes (different coeffs / metal nudge caps) — correct |
| E11 | Blueprint variable `nil` | Use default baselines (0.50) in envelope calculator |
| E12 | Inspector compare mode | Show both absolute and display position in trace (QA) |

### 8.2 Intentional “never hits zero” cases

A **High Contrast** user’s personal floor may be ~0.53 (baseline 0.75 − max mod). They will **never** see the diamond at the far left — because they **shouldn’t**, stylistically. That is correct Blueprint-as-Lens behaviour expressed through UI.

Partners should validate this on real Style Guides, not only Briar.

### 8.3 Metal tone — explicit non-change

| Question | Answer |
|----------|--------|
| Increase hardware metal weight? | **No** |
| Show recommended metal names? | **No** (v1) |
| Change deriveMetalTone? | **No** |
| Personal display only? | **Yes** |

Sky-forward transits and lunar phase remain the primary **daily** movers; personal remap makes that visible.

---

## 9. Inspector & diagnostics

Extend `ScaleDerivationTrace` or parallel struct:

```swift
struct ScalePresentationTrace: Codable {
    let floor: Double
    let ceiling: Double
    let baseline: Double
    let absoluteValue: Double
    let displayPosition: Double
    let baselinePosition: Double
}
```

Inspector markdown export (`### Vibrancy Derivation`) add rows:

| Field | Value |
|-------|-------|
| Personal floor | 0.379 |
| Personal ceiling | 0.621 |
| Display position | 0.693 |

Verdict runner: optional non-blocking check `displayPosition ∈ [0, 1]`.

---

## 10. Test plan

### 10.1 Unit tests — `PersonalScaleEnvelope_Tests.swift`

| ID | Test | Assert |
|----|------|--------|
| P1 | Contrast medium + Stage 1 coeffs | floor/ceiling match §6.2 formulas ±0.001 |
| P2 | Vibrancy soft vs rich same engine | soft floor < rich floor; envelopes differ |
| P3 | Metal tone baseline from temp + metals | matches manual calculation |
| P4 | `displayPosition` at floor | ≈ 0.0 |
| P5 | `displayPosition` at ceiling | ≈ 1.0 |
| P6 | `displayPosition` at baseline | ≈ `(baseline-floor)/(ceiling-floor)` |
| P7 | Degenerate envelope | returns 0.5 |
| P8 | Value above ceiling (injected) | clamps to 1.0 |
| P9 | Production vs Stage 1 same blueprint | envelopes differ |
| P10 | Soften cap tightens vibrancy/contrast ceiling | ceiling ≤ cap |

### 10.2 Integration tests

| ID | Test | Assert |
|----|------|--------|
| I1 | `generatePayload` includes `scalePresentation` | non-nil, three scales |
| I2 | Payload codable round-trip | presentation survives encode/decode |
| I3 | Legacy JSON decode without field | `scalePresentation == nil` |
| I4 | Briar 14-day window | metal `displayPosition` stddev > 0.05 (proves snap removal would matter) |
| I5 | Briar 14-day contrast | min display < max display; at least 3 distinct positions |

### 10.3 UI tests

| ID | Test | Assert |
|----|------|--------|
| U1 | Payload with presentation | diamond constraint uses displayPosition |
| U2 | Legacy payload | falls back to absolute |

### 10.4 Regression guards

- Existing `T4.18` contrast anchor tests — **unchanged** (absolute values).
- `vibrancy_contrast_metal_in_range` inspector verdict — **unchanged**.
- Production fingerprint guard — **unchanged**.

---

## 11. Implementation phases

### Phase A — Engine metadata (no UI)

1. Add `PersonalScaleEnvelope.swift` + calculator
2. Add `scalePresentation` to `DailyFitPayload` (optional Codable)
3. Wire in `BlueprintLensEngine.generatePayload`
4. Unit + integration tests (P1–P10, I1–I3)

### Phase B — UI remap

1. `DailyFitViewController`: consume `displayPosition`
2. Remove metal tone snap when presentation present
3. Add baseline ticks (optional but recommended)
4. UI tests (U1–U2)

### Phase C — Inspector

1. Presentation trace in diagnostics export
2. Briar 14-day manual sign-off: partners confirm sliders move meaningfully

**Estimated touch surface:** ~4 files new/modified in engine, ~1 UI file, ~1 inspector file, ~2 test files.

---

## 12. File change list

| File | Change |
|------|--------|
| `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` | **NEW** — envelope types + calculator |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | Add `scalePresentation` to payload |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Compute presentation at end of `generatePayload` |
| `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` | Export presentation trace |
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | Personal remap + remove snap + baseline tick |
| `Cosmic FitTests/PersonalScaleEnvelope_Tests.swift` | **NEW** |
| `Cosmic FitTests/DailyFitTypes_Tests.swift` | Codable round-trip for presentation |
| `Cosmic FitTests/DailyFitUIIntegration_Tests.swift` | Presentation populated |
| `inspector/...` | Trace rows (optional Phase C) |

**Do not modify:** `deriveMetalTone` logic, `NarrativeIntentEngine`, production calibration constants.

---

## 13. Acceptance criteria (sign-off)

- [ ] Briar 14-day: all three diamonds show **≥ 3 distinct positions** on personal tracks
- [ ] Briar metal tone: no day forced to centre by snap
- [ ] Soft saturation fixture: diamond can approach **left end** on low-vibrancy days
- [ ] High contrast fixture: diamond **never** below ~0.4 display (personal floor effect)
- [ ] Legacy frozen payloads render without crash (absolute fallback)
- [ ] Inspector shows floor/ceiling/baseline/display for QA
- [ ] Absolute payload values unchanged vs pre-refactor for same inputs
- [ ] Fashion + astrology partners confirm read on device: “I can tell today is softer/bolder **for me**”

---

## 14. Worked examples (Briar, Stage 1, Medium contrast / Rich vibrancy)

Absolute values from 2026-05-23 → 2026-06-05 export.

### Contrast

| Day | Absolute | Display (personal) | Read |
|-----|----------|-------------------|------|
| 2026-06-04 (low) | 0.532 | ~0.63 | Upper-mid of *my* band — not “low contrast” globally |
| 2026-06-01 (high) | 0.702 | ~1.00 | Near my personal max |

### Metal tone

| Day | Absolute | Display (personal) | Read |
|-----|----------|-------------------|------|
| 2026-05-23 | 0.437 | ~0.31 | Cooler-than-usual for me |
| 2026-06-02 | 0.728 | ~0.67 | Warm side of my band |

Previously all metal days showed **Mixed** at centre.

---

## 15. Open questions (defer unless blocking)

| # | Question | Default for v1 |
|---|----------|----------------|
| Q1 | Tighten ceiling using soften caps in envelope? | **Yes** — conservative, avoids diamond pegged at unreachable right edge on soften-heavy profiles |
| Q2 | Show baseline tick on all three scales? | **Yes** |
| Q3 | Silhouette personal remap in same pass? | **No** — separate ticket |
| Q4 | Re-label endpoints per blueprint (“Soft” vs “Muted”)? | **No** — keep current visual language |

---

## 16. Summary for implementer

1. **Keep engine absolutes** — calibration and inspector stay stable.  
2. **Compute personal floor/ceiling** analytically from blueprint + engine preset.  
3. **Remap only in UI** via `displayPosition = (value - floor) / (ceiling - floor)`.  
4. **Delete metal tone 3-snap** when presentation exists.  
5. **Do not strengthen metal ↔ Style Guide bond** — presentation only.  
6. **Ship envelope on payload** for app + inspector parity and legacy fallback.

This delivers the partner brief: full track travel **within the user’s meaningful range**, preserving daily nuance that is currently invisible on absolute or snapped scales.
