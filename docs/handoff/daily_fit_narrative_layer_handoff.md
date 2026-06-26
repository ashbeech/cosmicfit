# Daily Fit — Narrative Layer: Adaptive Salience, Cohesive Narratives & Full Slider Range

**Status:** Plan ready — no code changes shipped yet.
**Date:** 2026-06-08
**Audience:** Product owner (Ash) and **sequential AI developers** — one developer per phase plan, not one developer for the whole build.
**Prerequisite reading:**
- [`daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md) — current `NarrativeIntentEngine` architecture
- [`daily_fit_sky_forward_v2_refactor_handoff.md`](daily_fit_sky_forward_v2_refactor_handoff.md) — sky-forward principle and history
- [`daily_fit_personal_scale_sliders_handoff.md`](daily_fit_personal_scale_sliders_handoff.md) — `PersonalScaleEnvelopeCalculator` design

**Engine scope:** `stage1_experimental` (`DailyFitEngineMode.stage1Experimental`) ONLY. Production must remain untouched until an explicit promotion decision.

**Origin conversation:** [Narrative Layer Plan](52de5e4e-f7ba-4a3b-aba2-fca4d858b305)

**Independent audit amendment:** This one-file handoff is now split into three phase-specific execution plans. Use these for implementation:
- [`daily_fit_narrative_layer_phase_1_foundation_plan.md`](daily_fit_narrative_layer_phase_1_foundation_plan.md) — Phase 0/1 measurement, cohort, and adaptive salience.
- [`daily_fit_narrative_layer_phase_2_coherence_plan.md`](daily_fit_narrative_layer_phase_2_coherence_plan.md) — Phase 2 narrative decision layer and hard coherence contract.
- [`daily_fit_narrative_layer_phase_3_validation_plan.md`](daily_fit_narrative_layer_phase_3_validation_plan.md) — Phase 3/4 six-slider normalization, final validation, cleanup audit, and promotion gate.

## Sequential AI developer workflow (read this first)

Ash assigns **one phase plan to one AI developer at a time**. Each developer implements **only their plan**, then stops. Ash reviews and approves before the next developer receives the next plan.

```
Plan 1 developer → implement + test + report + completion doc → Ash approves
        ↓
Plan 2 developer → verify Plan 1 artifacts → implement + test + report + completion doc → Ash approves
        ↓
Plan 3 developer → verify Plan 1–2 artifacts → implement + test + report + completion doc → Ash promotion decision
```

**Each developer's mandatory sequence:**

1. Read this overview (§1–2 only) plus **their** phase plan in full.
2. Run the phase plan's **prerequisite verification** checklist — do not code until it passes.
3. Implement **only** the scope in that plan.
4. Run unit tests and cohort harnesses specified in that plan.
5. Commit fixtures, canvases, and code.
6. Write the phase **completion document** (path in each plan's §0).
7. Summarize results for Ash with canvas links.
8. **Stop.** Do not open or implement the next phase plan unless Ash explicitly assigns it.

**Relay contract:** The next developer inherits **committed repo artifacts**, not chat history. If a prerequisite file, canvas, or completion doc is missing, the developer must stop and report the gap to Ash — not improvise or skip ahead.

| Plan | Handoff doc | Completion doc (written at end) |
|------|-------------|----------------------------------|
| 1 | `daily_fit_narrative_layer_phase_1_foundation_plan.md` | `docs/handoff/completions/narrative_layer_plan1_completion.md` |
| 2 | `daily_fit_narrative_layer_phase_2_coherence_plan.md` | `docs/handoff/completions/narrative_layer_plan2_completion.md` |
| 3 | `daily_fit_narrative_layer_phase_3_validation_plan.md` | `docs/handoff/completions/narrative_layer_plan3_completion.md` |

| Plan | Mandatory canvases (in `~/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/`) |
|------|----------------------------------------------------------------------------------------------|
| Plan 1 | `narrative-layer-phase1-baseline.canvas.tsx` (Phase 0 snapshot), `narrative-layer-phase1-exit.canvas.tsx` (before/after salience) |
| Plan 2 | `narrative-layer-phase2-shadow.canvas.tsx` (pre-routing gate), `narrative-layer-phase2-exit.canvas.tsx` (full routing + coherence) |
| Plan 3 | `narrative-layer-phase3-exit.canvas.tsx` (four-dimension validation + promotion panel) |

Do not start the next plan until the previous plan's tests, cohort reports, canvases, completion doc, AI analysis, and **Ash's explicit approval** are complete.

The most important audit correction is that aggregate coherence scoring is not sufficient on its own. User-visible contradiction checks are hard zero-tolerance gates: no opposition pairs within essences, and no cross-surface narrative contradictions after routing through `DailyNarrativePlan`.

---

## 1. Executive summary

### 1.1 What this work achieves

Three interconnected product goals, delivered through a unified architecture:

| # | Goal | Current state | Target |
|---|------|---------------|--------|
| **1** | **Essence rate of change** — daily variation in the top-3 essence tags | Stale: 3–5 distinct #1 across 60 days; `edgy`/`sensual` pinned by slow outer planets | Day-to-day variety driven by fast-moving signals; full 14-category space reachable |
| **2** | **Slider full range** — per-user marker movement 0→100% across all 6 sliders | Personal scaling exists for 3 of 6 sliders; no verification of actual range coverage | All 6 sliders personally scaled; markers verified to travel full range per user |
| **3** | **Cohesive narrative** — all UI surfaces tell one story per day | Each surface computed independently; `NarrativeIntentEngine` biases a subset post-hoc | A single `DailyNarrativePlan` decided before any surface, allocated to every element |

### 1.2 Why these must be solved together

Goal #3 (the narrative layer) subsumes the other two:
- The narrative layer **consumes** the adaptive salience model from #1 as its fuel.
- The narrative layer **assigns** slider levels from #2, making normalization a display concern downstream of the decided plan.

Building #1 or #2 in isolation would be partially overwritten by #3. The phased sequence ensures each piece is built once and reused.

### 1.3 Architectural summary

```
Phase 0: Measurement cohort + baseline reports (no engine changes)
Phase 1: Adaptive salience model (replaces fixed transit weights)
Phase 2: DailyNarrativePlan layer (replaces independent surface scoring)
Phase 3: Unified per-user normalization (extends to all 6 sliders)
Phase 4: Cohesion validation (automated scoring + promotion gate)
```

### 1.4 Hard constraints

| Required | Forbidden |
|----------|-----------|
| All changes behind `stage1_experimental` engine | Changing production selection paths |
| Deterministic output (same inputs + seed = same payload) | Adding new user-facing text/copy |
| Reuse existing authored copy (TarotCards.json) | Breaking frozen payload decode |
| Style Guide palette constraints respected | Departing from user's base colour palette |
| Production fingerprint guard passes | Force-pushing or altering production calibration |
| Full test suite green at every phase boundary | Improvising scoring formulas without tests |

---

## 2. Root-cause analysis (from rate-of-change audit)

### 2.1 Why essences are stale

**Source:** `docs/fixtures/essence_rate_of_change.json`, canvas report `essence-rate-of-change-audit.canvas.tsx`, inspector 60-day harness.

Two compounding bugs in the current stage1 path:

**Bug A — dominant transit selection up-weights slow planets.**

File: `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` ~lines 1174–1182

```swift
private static let transitPlanetWeights: [String: Double] = [
    "Moon": 0.3, "Mercury": 0.4, "Venus": 0.5, "Sun": 0.6, "Mars": 0.7,
    "Jupiter": 0.8, "Saturn": 0.85, "Uranus": 0.9, "Neptune": 0.9,
    "Pluto": 1.0,
]
```

Strength = `orbTightness × planetWeight × aspectWeight`. Pluto/Neptune/Uranus get 0.9–1.0 while the Moon (which moves ~13°/day) gets 0.3. The "top 3 dominant transits" that feed essence are almost always the slow outer planets, which don't change for weeks. `TransitWeightCalculator.applyPlanetSpeedWeighting` exists but has zero call sites.

**Bug B — planet→category map collides on pinned planets.**

File: `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` ~lines 1405–1409

```swift
private static let stage1TransitEssenceCategories: [String: StyleEssenceCategory] = [
    "Mars": .drama, "Venus": .romantic, "Sun": .magnetic,
    "Moon": .sensual, "Mercury": .playful, "Jupiter": .maximalist,
    "Saturn": .minimal, "Uranus": .edgy, "Neptune": .sensual, "Pluto": .edgy,
]
```

Uranus→edgy AND Pluto→edgy; Neptune→sensual AND Moon→sensual. Two ever-present outer planets stack the same categories.

**The magnitude imbalance seals it.** Transit boost: `min(strength, 0.50) × 0.35` → max +0.175 per category. Sky−chart vibe delta: `1.8 × (skyNorm − chartNorm)` where norms are `VibeBreakdown ÷ 21`, producing tiny fractions. The static outer-planet boost structurally dwarfs the daily sky read.

**Evidence from the audit (60-day window, 5 presets):**

| Metric | Mean across presets |
|--------|---------------------|
| Daily top-1 flip rate | 24% |
| Daily top-3 change rate | 52% |
| Distinct #1 essences / 60d | 3.6 |
| Categories appearing in top-3 / 14 | 8.0 |
| `playful` stddev | 0.003 (essentially zero) |
| `classic`/`utility`/`romantic` stddev | 0.01–0.02 (near floor) |

Transit dominance: For 4 of 5 users, the same 3 slow outer planets (Pluto/Neptune/Uranus) dominate the entire 60-day window.

### 2.2 Why sliders may not span full range

**Current state:** `PersonalScaleEnvelopeCalculator` remaps absolute engine values to `displayPosition` via `(value − floor) / (ceiling − floor)`, so a rich-saturation user's low day maps to 0%.

**Gaps:**
- **Only 3 of 6 sliders have personal scaling:** Vibrancy, Contrast, Metal Tone. The three Silhouette sliders (M/F, A/R, S/D) use raw absolute 0–1 values with no per-user normalization.
- **Envelope is analytical, not longitudinal.** Floor/ceiling come from `blueprint baseline ± calibration coefficient` — the theoretical reachable range, not observed min/max. Whether markers actually travel 0→100% is unproven.
- **No test histograms `displayPosition`.** `DailyFitDistribution_Tests` histograms absolute `payload.vibrancy`, not `scalePresentation.vibrancy.displayPosition`.

### 2.3 Why the narrative is incoherent

**Current pipeline** (from `DailyFitPipeline.generate`, lines 12–53):

```
DailyEnergySnapshot
    ├─→ resolveEssenceProfile (independent scoring)
    ├─→ deriveSilhouetteProfile (independent scoring)
    ├─→ NarrativeIntentEngine.resolve (partial post-hoc bias, stage1 only)
    │       └─→ resolveEssenceConflicts (swap opposing top-3)
    └─→ BlueprintLensEngine.generatePayload
            ├─→ selectTarotAndStyleEdit (independent, partial intent bias)
            ├─→ selectDailyPalette (independent, partial intent bias)
            ├─→ deriveVibrancy (independent, partial ScaleDirective)
            ├─→ deriveContrast (independent, partial ScaleDirective)
            ├─→ deriveMetalTone (independent, NO intent)
            ├─→ selectDailyTextures (independent, NO intent)
            └─→ selectDailyPattern (independent, NO intent)
```

Every surface reads the shared snapshot but applies its own formula with no coordination. `NarrativeIntentEngine` only biases tarot, palette, vibrancy/contrast, and essence conflicts. It does NOT touch silhouette, metal tone, textures, or pattern. It runs AFTER raw essence/silhouette are computed. It nudges selection — it does not decide a narrative.

---

## 3. Phase 0 — Measurement & synthetic cohort

**Goal:** Establish baselines for all three metrics; build the test user set and harnesses that every subsequent phase validates against. No engine changes.

### 3.0 Synthetic cohort generator

**New file:** `tools/synthetic_cohort.py`

Generate ~200 deterministic synthetic birth charts spanning:
- 12 sun signs × 4 moon signs × 4 ascendant groups = diverse astrological space
- 3 saturation baselines (soft / muted / rich)
- 3 contrast baselines (low / medium / high)
- 3 temperature baselines (cool / mixed / warm)

Output: `inspector/Resources/synthetic_cohort.json` (same schema as `presets.json`).

Seeded deterministically so re-runs produce identical charts.

### 3.1 Slider range harness

**New file:** `tools/slider_range_harness.py`

For each cohort member × 60 consecutive days, via inspector API:
- Capture `scalePresentation.{vibrancy,contrast,metalTone}.displayPosition`
- Capture raw `silhouetteProfile.{masculineFeminine,angularRounded,structuredDraped}`
- For each slider per user: min, max, range, % of [0,1] covered, histogram (10 bins)
- Aggregate: mean range coverage across cohort; % of users with range < 0.3 (stuck); % with range > 0.8 (healthy)
- Flag users where any slider never leaves a single tertile

**Output:** `docs/fixtures/slider_range_report.json` + `.txt`

### 3.2 Essence baseline refresh

Re-run existing `tools/essence_stage1_diagnostics_harness.py` against the synthetic cohort (or a representative subset of ~50 charts if full cohort is too slow):

```bash
python3 tools/essence_stage1_diagnostics_harness.py --days 60 --months 12 --presets <subset>
```

### 3.3 Canvas reports

Create two canvas reports summarizing the Phase 0 findings:
- Slider range report canvas
- Refreshed essence rate-of-change canvas (with cohort data, not just 5 presets)

These become the "before" snapshot that Phase 1–4 improvements are compared against.

### 3.4 Acceptance targets (commit as test baselines)

Define and commit target thresholds that subsequent phases must meet:

| Metric | Phase 0 baseline (expected) | Phase 1 target | Phase 2+ target |
|--------|----------------------------|----------------|-----------------|
| Essence top-1 flip rate (daily) | ~24% | ≥40% | ≥40% |
| Essence distinct #1 / 60d | ~3.6 | ≥6 | ≥6 |
| Essence categories in top-3 / 14 | ~8 | ≥10 | ≥10 |
| Vibrancy displayPosition range / 60d | measure | — | ≥0.6 per user |
| Contrast displayPosition range / 60d | measure | — | ≥0.5 per user |
| Silhouette range / 60d (each axis) | measure | — | ≥0.3 per user |
| Coherence score (Phase 2+) | N/A | N/A | ≥0.85 |

### 3.5 Phase 0 tests

| Test | Purpose |
|------|---------|
| Production fingerprint guard | Capture and lock production baseline before any code changes |
| Cohort determinism | Same cohort JSON on re-run = identical charts |
| Harness output schema | Slider range JSON conforms to expected structure |

### 3.6 Phase 0 files checklist

- [ ] `tools/synthetic_cohort.py`
- [ ] `inspector/Resources/synthetic_cohort.json`
- [ ] `tools/slider_range_harness.py`
- [ ] `docs/fixtures/slider_range_report.json`
- [ ] `docs/fixtures/slider_range_report.txt`
- [ ] Refreshed `docs/fixtures/essence_stage1_diagnostics.json`
- [ ] Canvas reports (slider range + essence refresh)
- [ ] Acceptance target constants committed in test file

### 3.7 Phase 0 exit criterion

We know, with data:
- Whether slider markers actually span 0→100% per user (and which don't)
- Current essence staleness quantified across a diverse cohort
- Baseline fingerprint locked for production regression

---

## 4. Phase 1 — Adaptive salience model

**Goal:** Replace fixed planet weights with a per-day relative salience score so that fast-moving, currently-active sky signals surface even when slow outer planets are present. This fixes essence staleness and provides the raw fuel for the Phase 2 narrative layer.

### 4.1 New type: `SkySalienceProfile`

**File:** `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift`

```swift
struct SkySalienceProfile: Codable, Equatable {
    struct SalienceEntry: Codable, Equatable {
        let planet: String
        let aspect: String
        let natalTarget: String
        let rawStrength: Double     // orbTightness × aspectWeight
        let speedFactor: Double     // 0.0–1.0: fast-moving = high
        let freshnessBonus: Double  // applying/exact = bonus; separating = penalty
        let salience: Double        // final normalized score
        let essenceCategory: StyleEssenceCategory?
    }

    let entries: [SalienceEntry]    // sorted by salience desc
    let topDrivers: [SalienceEntry] // top 3 by salience (used for essence boost)
    let dominantNarrative: String?  // e.g. "Venus exact trine Moon" — trace only
}
```

### 4.2 Salience calculation

**File:** `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift`

Replace `extractDominantTransits` for stage1 with a new `computeSkySalience` function:

```swift
static func computeSkySalience(
    from transits: [NatalChartCalculator.TransitAspect],
    date: Date
) -> SkySalienceProfile
```

**Formula per transit:**

```
orbTightness = max(0, 1 − |orb| / maxOrbForAspect)
aspectWeight = transitAspectWeights[aspect] ?? 0.5

speedFactor:
  Moon      → 1.0
  Mercury   → 0.9
  Venus     → 0.85
  Sun       → 0.8
  Mars      → 0.7
  Jupiter   → 0.4
  Saturn    → 0.3
  Uranus    → 0.2
  Neptune   → 0.15
  Pluto     → 0.1

freshnessBonus:
  orb < 0.5° (near exact)        → +0.3
  applying (orb sign negative)   → +0.1
  separating                     → −0.1
  orb > 3° (wide)                → −0.2

rawSalience = orbTightness × aspectWeight × speedFactor + freshnessBonus
```

**Per-day normalization:** divide all rawSalience values by the max in the day's set, so the most salient transit = 1.0 regardless of absolute magnitude. This ensures subtle-but-fresh transits surface when outer planets are merely background.

**Cap per category:** if multiple transits boost the same essence category, take the highest-salience one only (existing dedup logic preserved).

### 4.3 Updated planet→category map

Spread collisions so no two planets share the same essence category:

```swift
private static let stage1TransitEssenceCategories: [String: StyleEssenceCategory] = [
    "Mars": .drama,
    "Venus": .romantic,
    "Sun": .magnetic,
    "Moon": .playful,       // was .sensual — freed from Neptune collision
    "Mercury": .eclectic,   // was .playful — freed from Moon collision
    "Jupiter": .maximalist,
    "Saturn": .minimal,
    "Uranus": .effortless,  // was .edgy — freed from Pluto collision
    "Neptune": .sensual,
    "Pluto": .edgy,
]
```

**Rationale:** Moon→playful (Moon governs moods/play); Mercury→eclectic (Mercury governs variety/communication); Uranus→effortless (Uranus governs unconventionality/freedom). These are astrologically defensible reassignments.

**Note for implementer:** The specific category reassignments above are a starting proposal. Validate by re-running the essence harness post-change. If the product owner prefers different assignments, adjust — the critical constraint is **no two planets share a category**.

### 4.4 Rebalance boost vs delta

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift`

| Constant | Current | Proposed | Rationale |
|----------|---------|----------|-----------|
| `stage1TransitEssenceBoost` | 0.35 | 0.20 | Reduce transit influence so delta can compete |
| `stage1EssenceVibeDeltaAmplification` | 1.8 | 2.5 | Raise delta signal so daily sky variation surfaces |
| `stage1AxisEssenceMultiplier` | 1.6 | 1.6 | Unchanged |
| Salience strength cap | 0.50 | 0.50 | Unchanged |

**Effective max per transit:** `0.50 × 0.20 = 0.10` (down from 0.175). The day's delta must now genuinely reflect sky movement to steer the ranking.

### 4.5 Integration into snapshot

**File:** `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift`, `generateSnapshot`

When `effectiveMode == .stage1Experimental`:
- Compute `SkySalienceProfile` alongside existing `dominantTransits`
- Store on `DailyEnergySnapshot` as `skySalience: SkySalienceProfile?`
- Pass `skySalience.topDrivers` to `scoreEssenceCategories` instead of `dominantTransits.prefix(3)`

**File:** `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift`

Add to `DailyEnergySnapshot`:

```swift
let skySalience: SkySalienceProfile?  // nil in production
```

### 4.6 Phase 1 tests

| Test | File | Purpose |
|------|------|---------|
| Salience speed ordering | `SkySalience_Tests.swift` (new) | Moon transit outranks same-orb Pluto transit |
| Salience freshness bonus | same | Applying exact Venus > separating wide Pluto |
| Per-day normalization | same | Top salience always = 1.0 regardless of absolute magnitudes |
| Category dedup | same | Two transits boosting same category → only highest salience applies |
| No category collision | same | All 10 planets map to distinct categories |
| Essence variation improvement | `EssenceSalienceIntegration_Tests.swift` (new) | 60-day top-1 flip rate ≥40% for ≥3 of 5 original presets |
| Production unchanged | `ProductionFingerprintGuard_Tests.swift` | Production path produces identical output |
| Existing tests green | All `Cosmic FitTests/` | No regression |

**Harness re-run:** After code changes, re-run `tools/essence_stage1_diagnostics_harness.py --days 60` and compare against Phase 0 baseline. Commit updated fixture.

### 4.7 Phase 1 files checklist

- [ ] `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` — `computeSkySalience`, integration into `generateSnapshot`
- [ ] `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` — `SkySalienceProfile`, `SkySalienceProfile.SalienceEntry`
- [ ] `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — updated constants, consume `skySalience.topDrivers`
- [ ] `Cosmic FitTests/SkySalience_Tests.swift` (new)
- [ ] `Cosmic FitTests/EssenceSalienceIntegration_Tests.swift` (new)
- [ ] Updated `docs/fixtures/essence_stage1_diagnostics.json`

### 4.8 Phase 1 exit criterion

- Essence top-1 flip rate ≥40% across presets
- Essence distinct #1 / 60d ≥6
- `playful`, `classic`, `romantic` stddev > 0.02 (no longer frozen)
- Production fingerprint unchanged
- All existing tests green

---

## 5. Phase 2 — Narrative-decision layer

**Goal:** Insert a single forward-looking step that decides ONE cohesive narrative per day, then allocates to every UI surface. This replaces independent surface scoring with plan-driven allocation.

### 5.1 Core type: `DailyNarrativePlan`

**File:** `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` (or new `DailyNarrativePlan.swift`)

```swift
struct DailyNarrativePlan: Codable, Equatable {
    // --- Decision ---
    let relationship: NarrativeRelationship    // reinforce / stretch / soften / contrast
    let themeLexiconKey: String?               // trace/diagnostic only

    // --- Essence allocation ---
    let accentEssence: StyleEssenceCategory       // the day's lead category
    let supportingEssences: [StyleEssenceCategory] // 2 supporting; together = visible top-3
    let anchorEssences: [StyleEssenceCategory]     // chart anchor top-3 (ghost layer)

    // --- Intensity ---
    let intensityLevel: IntensityLevel             // .low / .moderate / .high / .peak
    let tempoEmphasis: TempoEmphasis               // .slow / .steady / .dynamic

    // --- Slider targets (pre-normalization) ---
    let targetVibrancy: Double                     // 0–1 absolute, allocated by plan
    let targetContrast: Double                     // 0–1 absolute
    let targetMetalTone: Double                    // 0–1 absolute
    let targetSilhouette: SilhouetteProfile        // allocated from plan

    // --- Selection directives ---
    let paletteDirective: PaletteDirective
    let tarotDirective: TarotDirective
    let scaleDirective: ScaleDirective?

    // --- Provenance ---
    let salienceDrivers: [String]                  // top 3 salience driver descriptions
    let skyJustification: String                   // human-readable trace: "Venus exact trine Moon drives romantic"
}

enum IntensityLevel: String, Codable, CaseIterable {
    case low, moderate, high, peak
}

enum TempoEmphasis: String, Codable, CaseIterable {
    case slow, steady, dynamic
}
```

### 5.2 Narrative state space

The plan is selected from a **structured combinatorial space**, not free text:

```
relationship (4) × accentEssence (14) × intensityLevel (4) × tempoEmphasis (3)
= 672 base configurations
```

Each configuration implies a deterministic allocation to every surface:
- `accentEssence` + `relationship` → palette slot rules, tarot target vector
- `intensityLevel` → vibrancy/contrast targets, statement slot count
- `tempoEmphasis` → silhouette axis emphasis, metal tone nudge direction

With supporting essences (2 from remaining 13) the effective space is ~672 × C(13,2) = ~52,416 distinct plans. In practice, the selector narrows to a handful of candidates per day based on sky salience.

### 5.3 Narrative selector

**New file:** `Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift`

```swift
enum DailyNarrativeSelector {
    static func select(
        snapshot: DailyEnergySnapshot,
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration,
        precomputedEssence: StyleEssenceProfile,
        precomputedSilhouette: SilhouetteProfile
    ) -> DailyNarrativePlan
}
```

**Selection algorithm:**

1. **Classify relationship** — preserve existing `NarrativeIntentEngine.classifyRelationship` logic (reinforce/stretch/soften/contrast from anchor vs weather overlap + opposition detection)

2. **Pick accent essence** — from sky salience top driver's category, cross-referenced with essence scoring. The accent should be the category that (a) the day's most salient transit supports AND (b) the sky−chart delta boosts.

3. **Pick supporting essences** — next 2 highest essence scores that are NOT the accent and NOT in opposition to the accent (opposition = coherence violation). If the relationship is `contrast`, one supporting essence may come from the anchor side.

4. **Derive intensity** — from sky salience concentration:
   - `peak`: top driver salience > 0.8 AND orb < 1°
   - `high`: top driver salience > 0.6
   - `moderate`: top driver salience > 0.3
   - `low`: all drivers have salience < 0.3 (quiet sky day)

5. **Derive tempo** — from Moon's position in the salience profile:
   - `dynamic`: Moon in top 3 salience drivers
   - `steady`: Moon present but not dominant
   - `slow`: Moon absent from top 5 or Moon in waning/balsamic phase

6. **Allocate slider targets** — deterministic mapping from plan decisions:

   | Surface | Allocation rule |
   |---------|----------------|
   | Vibrancy | Blueprint baseline + intensity modifier: low=−0.15, moderate=0, high=+0.10, peak=+0.20 |
   | Contrast | Blueprint baseline + relationship modifier: reinforce=+0.05, stretch=+0.10, soften=−0.10, contrast=+0.15 |
   | Metal tone | Blueprint baseline + sky temperature nudge (existing transit/lunar logic) |
   | Silhouette M/F | From sky axes, per existing stage1 `tanh` formula |
   | Silhouette A/R | From sky axes |
   | Silhouette S/D | From sky axes |

7. **Build directives** — palette slots, tarot target vector, scale caps from relationship (same logic as current `NarrativeIntentEngine.buildIntent` but with intensity/tempo added).

8. **Seed determinism** — all tie-breaks use `snapshot.dailySeed`.

### 5.4 Pipeline integration

**File:** `Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift`

Replace the current flow with:

```swift
static func generate(
    blueprint: CosmicBlueprint,
    snapshot: DailyEnergySnapshot,
    calibration: DailyFitCalibration = .default,
    dailyFitEngineId engineId: String? = nil
) -> DailyFitPayload {
    let mode = DailyFitEngineRegistry.resolvedMode(engineId: engineId)

    if mode == .stage1Experimental {
        let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
        let rawSilhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: mode
        )
        let plan = DailyNarrativeSelector.select(
            snapshot: snapshot,
            blueprint: blueprint,
            calibration: calibration,
            precomputedEssence: rawEssence,
            precomputedSilhouette: rawSilhouette
        )
        return BlueprintLensEngine.generatePayloadFromPlan(
            plan: plan,
            blueprint: blueprint,
            snapshot: snapshot,
            calibration: calibration,
            mode: mode,
            dailyFitEngineId: engineId
        )
    } else {
        // Production path — completely unchanged
        return BlueprintLensEngine.generatePayload(
            blueprint: blueprint, snapshot: snapshot,
            calibration: calibration, mode: mode,
            dailyFitEngineId: engineId
        )
    }
}
```

### 5.5 New payload generation from plan

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift`

New function `generatePayloadFromPlan` that reads the plan instead of independently scoring each surface:

```swift
static func generatePayloadFromPlan(
    plan: DailyNarrativePlan,
    blueprint: CosmicBlueprint,
    snapshot: DailyEnergySnapshot,
    calibration: DailyFitCalibration,
    mode: DailyFitEngineMode,
    dailyFitEngineId: String?
) -> DailyFitPayload
```

| Surface | Source in plan | Remaining independent logic |
|---------|---------------|---------------------------|
| Essence | `accentEssence` + `supportingEssences` → build `StyleEssenceProfile` with plan-assigned visible categories; raw `allScores` from original scoring preserved for ghost/trace | Score ordering follows plan; magnitudes from original scoring |
| Tarot | `tarotDirective.targetEnergyVector` | Card funnel still uses astro scoring; variant picked by cosine to plan vector |
| Palette | `paletteDirective` (maxStatementSlots, accentCategory, foundationCategory) | Colour scoring from existing formula; slot allocation from plan |
| Vibrancy | `plan.targetVibrancy` | Clamped to [0,1] |
| Contrast | `plan.targetContrast` | Clamped to [0,1] |
| Metal tone | `plan.targetMetalTone` | Clamped, then tertile-snapped for display on personal-band `displayPosition` (2026-06-26 restore) |
| Silhouette | `plan.targetSilhouette` | Direct assignment |
| Textures | Plan `intensityLevel` + `accentEssence` → texture scoring bias | Existing texture pool; sky energy alignment |
| Pattern | Plan `intensityLevel` + sky axes → gate + selection | Existing pattern pool |

### 5.6 Removing old guardrails

Once `generatePayloadFromPlan` is verified, the following become dead code for stage1:

| To remove/deprecate | File | Reason |
|---------------------|------|--------|
| `NarrativeIntentEngine.resolve` | `NarrativeIntentEngine.swift` | Superseded by `DailyNarrativeSelector` |
| `NarrativeSelectionDirectives.resolveEssenceConflicts` | `NarrativeSelectionDirectives.swift` | Plan prevents conflicts by construction |
| `NarrativeSelectionDirectives.applyNarrativePaletteScoring` | same | Plan's `paletteDirective` replaces |
| `NarrativeSelectionDirectives.selectViaNarrativeSlots` | same | same |
| `NarrativeTarotBridgeSelector.select` | `NarrativeTarotBridgeSelector.swift` | Plan's `tarotDirective` replaces |

**Migration strategy:** Do NOT delete these files immediately. Mark them as deprecated with a comment referencing this handoff. Keep them compilable for production path. Remove after Phase 4 validation.

### 5.7 Shadow mode (safe migration)

Before routing any surface through the plan, run the plan in **shadow mode** for validation:

1. Compute `DailyNarrativePlan` alongside existing pipeline
2. Compare plan-allocated values vs independently-computed values
3. Log divergence in diagnostics
4. Only route surfaces through the plan one at a time, in order:
   - Essence first (plan assigns top-3)
   - Then palette (plan assigns slots)
   - Then tarot (plan assigns target vector)
   - Then sliders (plan assigns targets)
   - Then silhouette/metal/textures/pattern
5. At each step, run the full test suite + harnesses to confirm improvement

### 5.8 Phase 2 tests

| Test | File | Purpose |
|------|------|---------|
| Plan determinism | `DailyNarrativePlan_Tests.swift` (new) | Same snapshot + blueprint + seed = identical plan |
| Plan completeness | same | Every field of `DailyNarrativePlan` is non-default; no nil directives |
| Accent matches top salience | same | Plan's `accentEssence` is supported by top sky salience driver |
| No opposition in top-3 | same | `accentEssence` and `supportingEssences` contain no opposition pairs |
| Intensity from salience | same | `intensityLevel` matches salience concentration |
| Relationship preserved | same | Plan's `relationship` matches `NarrativeIntentEngine` classification (backward compat) |
| Slider targets in range | same | All target values in [0, 1] |
| Shadow mode divergence | `NarrativeShadow_Tests.swift` (new) | Log % of days where plan and independent pipeline agree on essence top-3, palette, etc. |
| Coherence score | `NarrativeCoherenceScore_Tests.swift` (new) | All surfaces align with plan ≥85% of the time |
| Production unchanged | `ProductionFingerprintGuard_Tests.swift` | Production path identical |
| Old guardrails unused | compile check | `NarrativeIntentEngine` still compiles but is not called in stage1 path |

**Coherence score definition:**

```
coherenceScore = mean of:
  - essenceMatch:   1 if visible top-3 == plan's [accent, supporting1, supporting2], else 0
  - paletteMatch:   1 if statement slot count == plan's maxStatementSlots, else 0
  - tarotMatch:     1 if selected variant's energy vector cosine > 0.5 with plan vector, else 0
  - sliderMatch:    1 if |payload.vibrancy − plan.targetVibrancy| < 0.05, else 0
  - silhouetteMatch: 1 if all 3 axes within 0.1 of plan targets, else 0
```

Target: ≥0.85 mean across cohort × 60 days.

### 5.9 Phase 2 files checklist

- [ ] `Cosmic Fit/InterpretationEngine/DailyNarrativePlan.swift` (new — or in `DailyFitTypes.swift`)
- [ ] `Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift` (new)
- [ ] `Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift` — route stage1 through plan
- [ ] `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — `generatePayloadFromPlan`
- [ ] `Cosmic Fit/InterpretationEngine/NarrativeIntentEngine.swift` — mark deprecated
- [ ] `Cosmic Fit/InterpretationEngine/NarrativeSelectionDirectives.swift` — mark deprecated
- [ ] `Cosmic Fit/InterpretationEngine/NarrativeTarotBridgeSelector.swift` — mark deprecated
- [ ] `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` — new types
- [ ] `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` — plan trace
- [ ] `inspector/Sources/CosmicFitInspectorServer/Web/app.js` — plan trace display
- [ ] `Cosmic FitTests/DailyNarrativePlan_Tests.swift` (new)
- [ ] `Cosmic FitTests/NarrativeShadow_Tests.swift` (new)
- [ ] `Cosmic FitTests/NarrativeCoherenceScore_Tests.swift` (new)

### 5.10 Phase 2 exit criterion

- Coherence score ≥0.85 across cohort × 60 days
- Essence variation targets still met (Phase 1 levels maintained or improved)
- All surfaces traceable to the plan in diagnostics
- Shadow mode divergence documented and understood
- Production fingerprint unchanged
- All existing tests green
- Old guardrails marked deprecated but still compile

---

## 6. Phase 3 — Unified per-user normalization

**Goal:** Extend personal-scale remapping to all 6 sliders, and verify actual full-range travel using the Phase 0 harness.

### 6.1 Extend `PersonalScaleEnvelopeCalculator`

**File:** `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift`

Add envelope functions for the three silhouette axes:

```swift
static func silhouetteEnvelope(
    axis: SilhouetteAxis,
    blueprint: CosmicBlueprint,
    calibration: DailyFitCalibration,
    mode: DailyFitEngineMode,
    value: Double
) -> PersonalScaleEnvelope
```

**Envelope strategy:** determined by Phase 0 data.

- **If Phase 0 shows analytical envelopes deliver ≥0.6 range coverage** for vibrancy/contrast: keep the analytical approach for silhouette (blueprint baseline ± axis modulation range).
- **If Phase 0 shows analytical envelopes produce stuck sliders:** implement a **calibrated longitudinal envelope** — use the synthetic cohort's 60-day simulation to compute each user's actual min/max for each axis, then use those as floor/ceiling.

### 6.2 Update `PersonalScalePresentation`

**File:** `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift`

Add silhouette display positions:

```swift
struct PersonalScalePresentation: Codable, Equatable {
    let vibrancy: PersonalScaleEnvelope
    let contrast: PersonalScaleEnvelope
    let metalTone: PersonalScaleEnvelope
    let masculineFeminine: PersonalScaleEnvelope?  // nil on legacy
    let angularRounded: PersonalScaleEnvelope?
    let structuredDraped: PersonalScaleEnvelope?
}
```

### 6.3 Update UI to use silhouette displayPosition

**File:** `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift`

In `refreshDiamondScalePositions()` (~line 2441), for silhouette sliders:

```swift
if let sp = payload.scalePresentation {
    // ... existing vibrancy/contrast/metal ...
    if let mf = sp.masculineFeminine {
        sliderTargetValues[3] = mf.displayPosition
    } else {
        sliderTargetValues[3] = payload.silhouetteProfile.masculineFeminine
    }
    // ... same for A/R, S/D ...
}
```

### 6.4 Phase 3 tests

| Test | Purpose |
|------|---------|
| Silhouette envelope construction | Floor/ceiling correct for known blueprint |
| Silhouette displayPosition at floor = 0.0 | Same pattern as existing vibrancy P4 test |
| Silhouette displayPosition at ceiling = 1.0 | Same pattern as existing vibrancy P5 test |
| All 6 sliders have displayPosition | Pipeline output has non-nil for all 6 |
| Slider range re-run | Re-run `tools/slider_range_harness.py` — assert ≥0.5 range per slider per user |
| Legacy decode | Old payloads without silhouette envelopes decode with nil, fallback to raw values |
| Production unchanged | Silhouette envelope only computed in stage1 |

### 6.5 Phase 3 files checklist

- [ ] `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` — silhouette envelopes
- [ ] `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` — extended `PersonalScalePresentation`
- [ ] `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — pass silhouette to envelope calculator
- [ ] `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` — use silhouette displayPosition
- [ ] `Cosmic FitTests/PersonalScaleEnvelope_Tests.swift` — silhouette cases
- [ ] Updated `docs/fixtures/slider_range_report.json`

### 6.6 Phase 3 exit criterion

- All 6 sliders have `displayPosition` in stage1 payloads
- Per-user range coverage ≥0.5 for all sliders across 60 days (measured by harness)
- No user has any slider stuck in a single tertile for the full 60 days
- Legacy decode unaffected
- Production unchanged

---

## 7. Phase 4 — Cohesion validation & promotion gate

**Goal:** Prove the combined system delivers coherent daily variation without losing sky accuracy or user specificity. Gate for production promotion.

### 7.1 Cohesion report harness

**New file:** `tools/narrative_cohesion_harness.py`

For each cohort member × 60 days:
- Capture `DailyNarrativePlan` from diagnostics
- Capture final payload
- Compute coherence score per day (§5.8 definition)
- Compute sky accuracy score: does the plan's `accentEssence` match the day's top salience driver's category?
- Compute user applicability score: are palette colours from the user's base palette? Is metal tone within blueprint constraints?
- Aggregate across cohort

**Output:** `docs/fixtures/narrative_cohesion_report.json`

### 7.2 Four validation dimensions

| Dimension | Metric | Target |
|-----------|--------|--------|
| **Variation** | Essence top-1 flip rate / 60d | ≥40% |
| | Slider range coverage per user | ≥0.5 per slider |
| | Distinct palette combos / 60d | ≥20 |
| **Coherence** | Coherence score (all surfaces align with plan) | ≥0.85 mean |
| | No opposition pairs in visible essence top-3 | 100% |
| **Sky accuracy** | Accent essence matches top salience driver | ≥70% |
| | Plan's `salienceDrivers` are real transits | 100% |
| | Deterministic (same inputs = same output) | 100% |
| **User applicability** | Palette colours from user's Style Guide palette | 100% |
| | Metal tone within blueprint temperature range | 100% |
| | Blueprint saturation baseline respected | ≥95% (plan may stretch) |

### 7.3 Regression against Phase 0

Side-by-side comparison:
- Phase 0 essence staleness → Phase 4 essence variation
- Phase 0 slider range → Phase 4 slider range
- Phase 0 no coherence metric → Phase 4 coherence score

### 7.4 Canvas report

Final canvas report showing all four dimensions with before/after comparison.

### 7.5 Phase 4 files checklist

- [ ] `tools/narrative_cohesion_harness.py`
- [ ] `docs/fixtures/narrative_cohesion_report.json`
- [ ] Canvas report
- [ ] Promotion recommendation document (if metrics pass)

### 7.6 Phase 4 exit criterion

All targets in §7.2 met. Production promotion is a separate decision made by the product owner after reviewing the report.

---

## 8. Safe refactor strategy — how to go from old to new without breaking anything

### 8.1 Principle: additive-first, then route, then deprecate

Never delete working code before its replacement is proven. The sequence is:

```
1. Add new types/functions alongside existing ones
2. Run new code in shadow mode (compute but don't use)
3. Route one surface at a time through the new path
4. Verify each routing with tests + harness re-run
5. Mark old code as deprecated after all surfaces routed
6. Remove deprecated code only after Phase 4 validation
```

### 8.2 Surface-by-surface routing order

| Order | Surface | Risk | Verification |
|-------|---------|------|--------------|
| 1 | Essence top-3 | Low — plan assigns categories directly | Essence harness + visual inspection |
| 2 | Palette | Medium — slot allocation changes colour picks | Palette trace + visual inspection |
| 3 | Tarot + variant | Medium — variant selection changes copy shown | Tarot trace; existing JSON copy still used |
| 4 | Vibrancy + Contrast | Low — plan assigns absolute values | Slider range harness |
| 5 | Silhouette | Low — plan assigns from sky axes | Slider range harness |
| 6 | Metal tone | Low — small nudge from plan | Visual inspection |
| 7 | Textures | Low — selection bias, not new content | Visual inspection |
| 8 | Pattern | Low — gate + selection | Visual inspection |

### 8.3 Rollback strategy

At any point, reverting to the old path requires only changing the `DailyFitPipeline.generate` stage1 branch to bypass `DailyNarrativeSelector` and call the existing independent scoring. Since old functions are not deleted until Phase 4, this is a one-line change.

### 8.4 Production isolation

| Guard | Mechanism |
|-------|-----------|
| Engine mode check | `if mode == .stage1Experimental` gates all new code |
| Production fingerprint | `ProductionFingerprintGuard_Tests` fails if production output changes |
| Registry | Release builds always use `production` engine id |
| Calibration | Production calibration has no `NarrativeSelectionTuning` → `narrativeIntent == nil` |

---

## 9. Implementation order (full sequence)

```
Phase 0
  0.1  Build synthetic cohort generator
  0.2  Build slider range harness
  0.3  Run slider range report (60d × cohort)
  0.4  Re-run essence diagnostics harness against cohort
  0.5  Create canvas reports (before snapshots)
  0.6  Commit acceptance targets as test baselines
  0.7  Capture production fingerprint
       → checkpoint commit "Phase 0 — measurement baseline"

Phase 1
  1.1  Add SkySalienceProfile type
  1.2  Implement computeSkySalience in DailyEnergyEngine
  1.3  Update planet→category map (no collisions)
  1.4  Rebalance transit boost vs delta amplification
  1.5  Integrate skySalience into snapshot (stage1 only)
  1.6  Write salience unit tests
  1.7  Write integration tests (60d variation)
  1.8  Re-run essence harness; confirm improvement
  1.9  Verify production fingerprint unchanged
       → checkpoint commit "Phase 1 — adaptive salience"

Phase 2
  2.1  Define DailyNarrativePlan type + supporting enums
  2.2  Implement DailyNarrativeSelector.select
  2.3  Implement shadow mode — compute plan alongside existing pipeline
  2.4  Write plan unit tests (determinism, completeness, no oppositions)
  2.5  Implement generatePayloadFromPlan in BlueprintLensEngine
  2.6  Route essence through plan; test
  2.7  Route palette through plan; test
  2.8  Route tarot through plan; test
  2.9  Route sliders through plan; test
  2.10 Route silhouette/metal/textures/pattern through plan; test
  2.11 Write coherence score tests
  2.12 Mark old guardrails as deprecated
  2.13 Re-run essence harness; confirm variation maintained
  2.14 Verify production fingerprint unchanged
       → checkpoint commit "Phase 2 — narrative layer"

Phase 3
  3.1  Add silhouette envelope functions
  3.2  Extend PersonalScalePresentation
  3.3  Update DailyFitViewController for silhouette displayPosition
  3.4  Write envelope tests
  3.5  Re-run slider range harness; confirm full travel
  3.6  Verify production fingerprint unchanged
       → checkpoint commit "Phase 3 — unified normalization"

Phase 4
  4.1  Build narrative cohesion harness
  4.2  Run full 4-dimension validation (variation, coherence, sky accuracy, user applicability)
  4.3  Create final canvas report with before/after
  4.4  Document promotion recommendation
       → checkpoint commit "Phase 4 — validation complete"
```

---

## 10. Key files map (all phases)

### New files

| File | Phase | Purpose |
|------|-------|---------|
| `tools/synthetic_cohort.py` | 0 | Cohort generator |
| `tools/slider_range_harness.py` | 0 | Slider range measurement |
| `tools/narrative_cohesion_harness.py` | 4 | Cohesion validation |
| `Cosmic FitTests/SkySalience_Tests.swift` | 1 | Salience unit tests |
| `Cosmic FitTests/EssenceSalienceIntegration_Tests.swift` | 1 | 60-day variation tests |
| `Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift` | 2 | Plan selector |
| `Cosmic FitTests/DailyNarrativePlan_Tests.swift` | 2 | Plan unit tests |
| `Cosmic FitTests/NarrativeShadow_Tests.swift` | 2 | Shadow mode validation |
| `Cosmic FitTests/NarrativeCoherenceScore_Tests.swift` | 2 | Coherence scoring |

### Modified files

| File | Phase(s) | Changes |
|------|----------|---------|
| `DailyEnergyEngine.swift` | 1 | `computeSkySalience`, snapshot integration |
| `DailyFitTypes.swift` | 1, 2, 3 | `SkySalienceProfile`, `DailyNarrativePlan`, extended `PersonalScalePresentation` |
| `BlueprintLensEngine.swift` | 1, 2 | Constants rebalance, `generatePayloadFromPlan` |
| `DailyFitPipeline.swift` | 2 | Route stage1 through plan |
| `PersonalScaleEnvelope.swift` | 3 | Silhouette envelopes |
| `DailyFitViewController.swift` | 3 | Silhouette displayPosition |
| `DailyFitDiagnostics.swift` | 2 | Plan trace fields |
| `DailyFitEngineRegistry.swift` | 1, 2 | Stage1 calibration updates |
| `app.js` (inspector) | 2 | Plan trace display |

### Deprecated (do not delete until Phase 4)

| File | Phase deprecated |
|------|------------------|
| `NarrativeIntentEngine.swift` | 2 |
| `NarrativeSelectionDirectives.swift` | 2 |
| `NarrativeTarotBridgeSelector.swift` | 2 |

---

## 11. Testing strategy — four-category framework

Every phase must demonstrate all four categories are satisfied:

### 11.1 Variation tests

Prove the system produces day-to-day change that the user notices.

| What | How | Target |
|------|-----|--------|
| Essence top-1 flips | 60-day harness, count consecutive days with different #1 | ≥40% |
| Essence distinct #1 | 60-day harness, count unique #1 categories | ≥6 / 60d |
| Essence category coverage | 60-day harness, count categories ever in top-3 | ≥10 / 14 |
| Slider range | 60-day harness, displayPosition min→max per user | ≥0.5 per slider |
| Palette diversity | 60-day harness, count distinct 3-colour combos | ≥20 / 60d |
| Silhouette movement | 60-day harness, stddev of each axis | >0.05 |

### 11.2 Coherence tests

Prove all surfaces tell one consistent story each day.

| What | How | Target |
|------|-----|--------|
| Essence vs plan | visible top-3 == plan's [accent, supporting1, supporting2] | ≥95% |
| Palette vs plan | statement slots ≤ plan's maxStatementSlots | 100% |
| Tarot vs plan | variant energy cosine with plan vector > 0.5 | ≥80% |
| Slider vs plan | |vibrancy − target| < 0.05 | ≥90% |
| No opposition in top-3 | accent not opposed to any supporting essence | 100% |
| Coherence score aggregate | mean of all above | ≥0.85 |

### 11.3 Sky accuracy tests

Prove the narrative is driven by actual sky conditions, not arbitrary.

| What | How | Target |
|------|-----|--------|
| Accent matches salience | plan accentEssence == top salience driver's category | ≥70% |
| Salience drivers are real | plan salienceDrivers correspond to actual transits in snapshot | 100% |
| Determinism | same date + chart = same plan + payload | 100% |
| Fast movers surface | Moon/Venus/Mercury appear as accent driver at least once per 30d per user | ≥80% of users |
| Slow movers don't dominate | Pluto/Neptune/Uranus are sole accent driver < 50% of days | ≥80% of users |

### 11.4 User applicability tests

Prove the plan respects the user's Style Guide identity.

| What | How | Target |
|------|-----|--------|
| Palette from blueprint | all 3 selected colours in user's approved palette pool | 100% |
| Metal in range | metal tone within blueprint temperature ±0.15 | 100% |
| Saturation baseline respected | plan.targetVibrancy within blueprint baseline ±0.25 | ≥95% |
| Contrast baseline respected | plan.targetContrast within blueprint baseline ±0.25 | ≥95% |
| Legacy decode safe | old payloads without plan fields decode correctly | 100% |
| Production unchanged | production fingerprint exact match | 100% |

---

## 12. Definition of done (per phase)

### Phase 0
- [ ] Synthetic cohort committed and deterministic
- [ ] Slider range report generated with data for all 6 sliders
- [ ] Essence diagnostics refreshed against cohort
- [ ] Canvas reports (before snapshots) created
- [ ] Acceptance targets committed as test constants
- [ ] Production fingerprint captured and locked

### Phase 1
- [ ] `SkySalienceProfile` type implemented and populated
- [ ] Speed-weighted, freshness-aware salience scoring working
- [ ] No two planets share an essence category
- [ ] Essence top-1 flip rate ≥40% across presets
- [ ] Essence distinct #1 / 60d ≥6
- [ ] `playful`/`classic`/`romantic` no longer frozen (stddev > 0.02)
- [ ] Production fingerprint unchanged
- [ ] All existing tests green

### Phase 2
- [ ] `DailyNarrativePlan` type defined with full state space
- [ ] `DailyNarrativeSelector` computes plan deterministically
- [ ] Shadow mode validated
- [ ] All surfaces routed through plan (essence → palette → tarot → sliders → rest)
- [ ] Coherence score ≥0.85 across cohort
- [ ] Essence variation targets maintained
- [ ] Old guardrails marked deprecated
- [ ] Production fingerprint unchanged
- [ ] All existing tests green

### Phase 3
- [ ] All 6 sliders have `displayPosition` in stage1 payloads
- [ ] Silhouette envelopes producing non-degenerate ranges
- [ ] Slider range coverage ≥0.5 per slider per user
- [ ] No slider stuck in single tertile for full 60 days
- [ ] Legacy decode unaffected
- [ ] Production fingerprint unchanged

### Phase 4
- [ ] Cohesion harness passing all four validation dimensions
- [ ] Before/after canvas report demonstrating improvement
- [ ] Promotion recommendation documented
- [ ] All deprecated code still compiles (removal is a follow-up)

---

## 13. Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Planet→category reassignment feels astrologically wrong | Essence categories lose meaning | Validate with product owner; assignments are a starting proposal, not final |
| Narrative plan over-constrains variation | Slider/palette becomes repetitive under certain sky conditions | State space is >50K possibilities; test with diverse cohort; add jitter within plan-allocated ranges |
| Salience normalization makes quiet sky days noisy | On days with no strong transits, weak signals amplified into false narratives | `IntensityLevel.low` caps modulation; plan can default to reinforce-anchor on quiet days |
| Silhouette longitudinal envelope needs historical data | Can't compute without running 60-day sim per user | Use synthetic cohort simulation; analytical fallback if sim infeasible in production |
| Phase 2 scope creep | Narrative layer becomes a multi-month project | Strict state space (no free text); shadow mode catches problems early; surface-by-surface routing |
| Production contamination | Regression in shipped product | Fingerprint guard; engine mode gate; separate calibration |

---

## 14. Glossary

| Term | Definition |
|------|------------|
| **Salience** | Per-day, speed-weighted, freshness-aware transit strength score |
| **Narrative plan** | Single decided allocation of accent essence + intensity + tempo + slider targets + directives |
| **Accent essence** | The day's lead style-essence category chosen by the plan |
| **Supporting essences** | Two additional categories completing the visible top-3 |
| **Coherence score** | 0–1 metric measuring alignment of all surfaces with the decided plan |
| **Personal scale envelope** | Per-user min/max/baseline for a slider axis; maps absolute value to displayPosition 0–1 |
| **Shadow mode** | Running the plan alongside existing pipeline without using its output |
| **Surface** | Any UI element in Daily Fit: essence, palette, tarot, sliders, silhouette, metal, textures, pattern |

---

## 15. Related docs

- [`daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md) — predecessor narrative architecture (now to be superseded)
- [`daily_fit_sky_forward_v2_refactor_handoff.md`](daily_fit_sky_forward_v2_refactor_handoff.md) — sky-forward principle
- [`daily_fit_sky_forward_v2_implementation_spec.md`](daily_fit_sky_forward_v2_implementation_spec.md) — sky-forward implementation
- [`daily_fit_personal_scale_sliders_handoff.md`](daily_fit_personal_scale_sliders_handoff.md) — current personal scale design
- [`daily_fit_engine_selector_spec.md`](daily_fit_engine_selector_spec.md) — engine registry
- Canvas: `essence-rate-of-change-audit.canvas.tsx` — the audit that motivated this work
- Fixtures: `docs/fixtures/essence_rate_of_change.json`, `docs/fixtures/essence_stage1_diagnostics.json`
- Harnesses: `tools/essence_rate_of_change_harness.py`, `tools/essence_stage1_diagnostics_harness.py`
