# Daily Fit Sky Forward v2 — "Universe Weather Report" Refactor Handoff

**Status:** Plan only — no code changes shipped yet.  
**Date:** 2026-05-21  
**Audience:** Engineer or AI agent implementing the refactor.  
**Prerequisite reading:** [`daily_fit_sky_forward_handoff.md`](daily_fit_sky_forward_handoff.md), [`daily_fit_palette_selection_handoff.md`](daily_fit_palette_selection_handoff.md)  
**Engine scope:** `stage1_experimental` (`DailyFitEngineMode.stage1Experimental`) ONLY. Production and Legacy Baseline must remain untouched.

---

## Step 0 — Sign multiplier policy (prerequisite, shipped 2026-05-22)

Before sky-forward v2 refactors, **`SignMultiplierPolicy`** on `DailyFitCalibration` formalizes Option A for `stage1_experimental`:

| Path | Policy |
|------|--------|
| Daily sky payload (`vibeProfile` / `skyVibeProfile`) | OFF |
| Chart anchor (`chartVibeProfile`) | ON |
| Production / legacy daily full-mix | ON (unchanged) |

Inspector diagnostics label post-multiplier trace honestly when daily policy is OFF. See [`daily_fit_sign_multiplier_policy_handoff.md`](daily_fit_sign_multiplier_policy_handoff.md).

---

## 1. Problem statement

Sky-forward Stage 1 was validated in the inspector (Briar, 14 days, 21/05–03/06/2026). While essence correctly shows "today vs chart anchor," every other surface remains too static to function as a daily universe weather report:

| Surface | 14-day observation | Root cause |
|---|---|---|
| **Essence top 3** | sensual #1 on 13/14 days | Neptune square Moon at 100% strength every day dominates sky vibe → sensual always wins delta |
| **Silhouette** | M/F=1.000, A/R=0.359, S/D=0.000 — identical all 14 days | Style Code keyword baseline at extremes; axis delta nudge can't move clamped values |
| **Palette** | black cherry appears ~12/14 days; same 4-colour family | Scores from blended amplified vibe (not sky slice); signature wins on drama; core-anchor guarantee limits picks |
| **Contrast** | 0.725 every day | Blueprint baseline + visibility axis; no sky-forward branch; axes saturated at 10 |
| **Vibrancy** | 0.77–0.90 (tiny range) | Same formula as production; drama/edge from blended vibe barely moves |
| **Metal tone** | 0.594 every day | Fixed blueprint baseline; no daily transit variation visible |
| **Textures** | vintage silk + washed cotton — all 14 days | Static scoring, no sky input |
| **Pattern** | nautical stripes — 13/14 days | Gate always passes (visibility=10, drama dominant); no rotation logic |
| **Axes (trace)** | All 10, all days | `stage1AxisDeltaAmplification = 2.25` overshoots → sigmoid clips to max |

**Conclusion:** The engine computes sky-forward essence correctly, but every other daily surface still reads like the user's fixed chart identity because axes are saturated, palette/scales read from blended vibe, and silhouette is keyword-baseline-dominated.

---

## 2. Design principle

> **Every displayed surface should derive primarily from today's sky slice, with the chart shown only as a reference frame — not blended into the output.**

The user should see visibly different outputs on different days because the sky is different, not because jitter broke a tie.

---

## 3. Refactor plan (7 steps)

### Step 1 — Fix axis saturation (CRITICAL — unlocks steps 2, 4, 6)

**Root cause:** `stage1AxisDeltaAmplification = 2.25` applied to axes that already saturate via sigmoid. For Briar, raw axis scores hit the sigmoid ceiling → all final axes land at 10.

**Fix:** For Stage 1, compute axes from **sky sources only** (transits + lunar + current sun) using the existing `stage1SkySourceWeights`. Remove the delta-amplification step for axes entirely — let the sky-only signal speak directly through the sigmoid.

**Implementation:**

In `DailyEnergyEngine.swift`, the axis evaluation path when `effectiveMode == .stage1Experimental`:

```swift
// Instead of: anchor + amplification × (daily − anchor)
// Do: evaluate axes from sky-only sources directly
let skyAxes = evaluateAxesFromSources(
    natalChart: natalChart,    // still needed for planet positions
    progressedChart: progressedChart,
    transits: transits,
    moonPhaseDegrees: moonPhaseDegrees,
    calibration: calibration,
    weights: stage1SkySourceWeights,  // natal=0, progressed=0, transits=0.50, lunar=0.35, sun=0.15
    includeNatalContribution: false
)
```

This replaces the current delta-amplification block (~line 735–767) for Stage 1.

**Expected result:** Axes should vary between ~3–8 depending on daily transits/lunar, not peg at 10.

**File:** `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift`

---

### Step 2 — Silhouette: sky-axis-driven, drop keyword baseline dominance

**Current (Stage 1):**
```
mf = mfBase (from Style Code keywords) + visDelta × 0.45 × scale
```
Where `mfBase` is often 0.0 or 1.0 (extreme chart identity).

**Proposed (Stage 1):**
```swift
// Sky-driven silhouette: centred at 0.5, modulated by sky-only axes
let skyVis = skyAxes.visibility  // from step 1 fix
let skyAct = skyAxes.action
let skyStr = skyAxes.strategy

let mf = clamp(0...1, 0.5 + (skyVis - 5.0) / 10.0 * 0.8)
let ar = clamp(0...1, 0.5 + (skyAct - 5.0) / 10.0 * 0.7)
let sd = clamp(0...1, 0.5 + (skyStr - 5.0) / 10.0 * 0.8)
```

The chart keyword baseline becomes `chartAnchorSilhouette` — stored for display comparison (like `chartAnchorScores` on essence), but NOT blended into the daily output.

**Additions to `DailyFitTypes.swift`:**
```swift
// On DailyFitPayload or SilhouetteProfile:
let chartAnchorSilhouette: SilhouetteProfile?  // nil in production
```

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — `deriveSilhouetteProfile` Stage 1 branch (~line 1120).

---

### Step 3 — Palette: score from sky vibe, not blended vibe

**Current:** `scorePaletteCandidates` uses `snapshot.vibeProfile` (delta-amplified blend).

**Proposed (Stage 1):** Score against `snapshot.skyVibeProfile` directly. Sky vibe reflects what the universe is doing today without natal drama inflating every day.

Additionally: **remove the core-anchor guarantee** for Stage 1. Pure top-3 by score. If a core colour wins on merit, great; if not, let the sky pick freely.

**Implementation:**

Add a new palette selection strategy or branch within `selectDailyPalette`:

```swift
case .pureSkyScoring:
    // Score from skyVibeProfile, take top 3 unique by score, no role guarantees
    let skyScored = scorePaletteCandidates(candidates, snapshot: snapshot, calibration: calibration, useVibeSource: .sky)
    selected = skyScored.prefix(3).map { ... }
```

Or more simply, when `mode == .stage1Experimental`, pass `snapshot.skyVibeProfile ?? snapshot.vibeProfile` to the existing scoring function and use a no-guarantee top-3 selection.

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — `selectDailyPalette` (~line 572) and `scorePaletteCandidates` (~line 620).

**Registry change:** Update `stage1ExperimentalCalibration` to use a new strategy enum value (e.g. `.pureSkyScoring`) or gate on mode directly.

---

### Step 4 — Vibrancy & Contrast: modulate from sky vibe / sky axes

**Current:**
- Vibrancy: `baseline + (drama+edge − utility+classic)/21 × vibrancyCoeff` — reads from blended `snapshot.vibeProfile`
- Contrast: `baseline + (visibility−5)/10 × contrastCoeff` — reads from blended axes (saturated at 10)

**Proposed (Stage 1):**
- Vibrancy: same formula but read from `snapshot.skyVibeProfile`
- Contrast: same formula but read from sky-only axes (after step 1 fix, these won't be saturated)

**Implementation:**

In `deriveVibrancy` and `deriveContrast`, add a mode parameter:

```swift
private static func deriveVibrancy(
    from palette: PaletteSection,
    snapshot: DailyEnergySnapshot,
    calibration: DailyFitCalibration = .default,
    mode: DailyFitEngineMode = .standard
) -> Double {
    let vibe = (mode == .stage1Experimental) ? (snapshot.skyVibeProfile ?? snapshot.vibeProfile) : snapshot.vibeProfile
    let axes = (mode == .stage1Experimental) ? (snapshot.chartAxes.map { _ in snapshot.axes } ?? snapshot.axes) : snapshot.axes
    // ... rest unchanged, using `vibe` and `axes`
}
```

Note: after step 1, `snapshot.axes` for Stage 1 will already be sky-driven (not saturated), so contrast will naturally vary.

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — `deriveVibrancy` (~line 770), `deriveContrast` (~line 793).

---

### Step 5 — Essence: reduce Neptune monoculture

**Problem:** Neptune square Moon at 100% strength persists for weeks (outer planet, tight orb). It dominates the sky vibe → sensual always wins the delta.

**Options (implement one or combine):**

#### Option A: Cap per-planet transit contribution
In `stage1SkySourceWeights` path or in `accumulateTransitContribution`, cap a single transit planet's total energy contribution to e.g. 30% of the transit budget. This prevents one tight outer-planet aspect from dominating.

#### Option B: Rebalance sky source weights
Increase lunar weight (moon moves ~13°/day, changes character daily) vs transits:
```swift
// Current:  transits=0.50, lunar=0.35, sun=0.15
// Proposed: transits=0.35, lunar=0.45, sun=0.20
```

#### Option C: Reduce essence delta amplification
Lower `stage1EssenceVibeDeltaAmplification` from 4.0 to ~2.0–2.5 so that smaller daily differences in other categories can compete with the dominant Neptune signal.

#### Recommended: combine B + C
Rebalance to give lunar more weight (it actually changes daily) AND reduce amplification so the delta doesn't just magnify the same dominant transit.

**File:** `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` (weights), `BlueprintLensEngine.swift` (amplification constant).

---

### Step 6 — Textures & Pattern: sky-responsive

#### Textures

**Current:** Static scores from blueprint pool — `vintage silk: 1.4, washed cotton: 1.1, ...` — no daily variation.

**Proposed:** Add sky vibe alignment to texture scoring (similar to palette `roleEnergyAlignment`):

```swift
let textureEnergyAlignment: [String: [Energy]] = [
    "vintage silk": [.romantic, .drama],
    "washed cotton": [.utility, .classic],
    "heritage knits": [.classic, .romantic],
    "soft flannel": [.utility, .playful],
]
```

Score textures against `skyVibeProfile` so selection changes with the day's energy.

#### Pattern

After step 1 fixes axis saturation, the pattern gate (`visibility ≥ 6 && dominant ∈ {drama, playful, edge}`) will sometimes fail — giving pattern-free days naturally.

Additionally, instead of always selecting the same pattern, rotate selection based on sky dominant energy:
```swift
let patternEnergyMap: [Energy: [String]] = [
    .drama: ["dark tonal herringbone", "dark embossed crest detail"],
    .romantic: ["vintage florals", "soft gingham"],
    .playful: ["nautical stripes", "ethnic-inspired prints"],
    // ...
]
```

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — texture selection (~line 1200+) and pattern selection.

---

### Step 7 — Inspector: show sky vibe separately

**Current:** Vibe Breakdown shows the 6-energy blended profile (delta-amplified). The user can't see "what the sky alone is doing."

**Proposed:** Add a "Sky Vibe (6 energies)" section to the Daily Fit pane when `chartAnchorScores` is present (i.e. Stage 1). Display `skyVibeProfile` from the payload diagnostics.

Also show sky-only axes vs chart axes, so the user sees the universe weather separate from their chart fingerprint.

**Implementation:**
- Expose `skyVibeProfile` and `chartVibeProfile` in the inspector JSON diagnostics (they're already computed, just not serialized to the API response)
- Add a `buildSkyVibeBreakdownHtml` section in `app.js`

**File:** `inspector/Sources/CosmicFitInspectorServer/Web/app.js`, inspector response serialization in `InspectorEngine.swift`.

---

## 4. Implementation order (dependencies)

```
Step 1 (axis fix) ─────┬──→ Step 2 (silhouette)
                        ├──→ Step 4 (vibrancy/contrast)
                        └──→ Step 6 (pattern gate)

Step 3 (palette from sky vibe) ── independent

Step 5 (essence tuning) ── independent

Step 7 (inspector UI) ── after steps 1–6 produce better data
```

**Recommended session order:** 1 → 2 → 3 → 4 → 5 → 6 → 7

Steps 1–4 can likely be done in a single focused session. Step 5 is tuning. Steps 6–7 are polish.

---

## 5. Key files (edit map)

| File | Changes |
|---|---|
| `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` | Step 1 (sky-only axes), Step 5 (sky weights / transit cap) |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Steps 2, 3, 4, 6 (silhouette, palette, scales, textures/pattern) |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | Step 2 (chartAnchorSilhouette type addition) |
| `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift` | Step 3 (palette strategy enum if needed), Step 5 (weight changes) |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Step 7 (sky vibe UI) |
| `inspector/Sources/CosmicFitInspectorLib/InspectorEngine.swift` | Step 7 (serialize sky/chart vibe to response) |
| `Cosmic FitTests/BlueprintLensEngine_Payload_Tests.swift` | New Stage 1 assertions |
| `Cosmic FitTests/DailyFitEngineRegistry_Tests.swift` | Updated Stage 1 output-diff tests |

---

## 6. Guardrails

- **All changes gated on `mode == .stage1Experimental`** — production and legacy paths must pass all existing tests unchanged
- **Branch on mode at central entry points only** — do not scatter `if engineId == "stage1_experimental"` in scoring loops (per spec §5.4)
- **Add Briar 14-day regression fixture** — confirm daily variation improves (target: ≥5 distinct essence top-3 orderings, ≥3 distinct palette combos, silhouette movement across days)
- **No promotion to production** without explicit sign-off from Ash

---

## 7. Validation criteria (how to know it worked)

Run Briar 14-day compare in inspector with Stage 1 selected. You should see:

| Surface | Target variation |
|---|---|
| Essence top 3 | ≥5 unique orderings / 14 days |
| Silhouette sliders | Values move across days (not all pinned) |
| Palette | ≥4 distinct 3-colour combos / 14 days; signature not always present |
| Vibrancy | Range spans ≥0.2 across 14 days |
| Contrast | Not identical every day |
| Textures | ≥2 different selections across 14 days |
| Pattern | Some days with no pattern (gate fails) |
| Axes (trace) | Not all 10; values vary 3–9 |

---

## 8. What NOT to change

- `DailyFitCalibration.default` (production calibration)
- Production engine mode path (`.standard`)
- Style Guide / Blueprint composition
- Tarot selection algorithm (already varies via recency + scores)
- Frozen payload storage logic
- Inspector display logic (it's a passthrough — fix the engine, not the UI rendering)

---

## 9. Prior conversation context

This plan was developed in a Cursor session on 2026-05-21 that:
1. Confirmed sky-forward is implemented and running on `stage1_experimental`
2. Ran 14-day inspector tests showing insufficient variation
3. Traced each surface to identify why it's static
4. Diagnosed axis saturation as the keystone blocker
5. Identified palette, silhouette, and scales as needing sky-native scoring paths

The prior sky-forward implementation handoff is at [`daily_fit_sky_forward_handoff.md`](daily_fit_sky_forward_handoff.md). The palette analysis is at [`daily_fit_palette_selection_handoff.md`](daily_fit_palette_selection_handoff.md).
