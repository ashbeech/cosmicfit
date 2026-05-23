# Daily Fit Sky Forward v2 — Implementation Spec

**Status:** Approved for implementation — pre-flight gaps closed (see §17).  
**Date:** 2026-05-21  
**Author:** AI agent (Cursor), audited by Ash  
**Scope:** `stage1_experimental` engine ONLY. Production and Legacy Baseline untouched.  
**Goal:** Drastically increase day-to-day variation across all Daily Fit surfaces while maintaining astrological accuracy.  
**Validation profile:** Briar (12/11/1984 12:00, London), 14-day compare 21/05–03/06/2026.

### Scope clarity: experimental ≠ production ship

This spec delivers **production-quality engineering of an experimental preset**, not a production rollout of the algorithm.

- **Production users are unaffected** — all changes are gated on `stage1_experimental`.
- **Stage 1 is not validated for the general population** — Briar (Scorpio / water-heavy, Neptune square Moon) is one stress profile. Constants such as `sigmoidSpread: 0.8`, lunar 50%, and essence amp 2.5 may need per-profile tuning before any promotion to `.standard`.
- **Ready to implement:** yes, after §17 checklist.
- **Ready to ship Stage 1 to all users:** no — experimental by design; Briar-only acceptance for v1.

---

## 0. Evidence of the problem (current output, Briar 14 days)

| Surface | Current range (14 days) | Acceptable target |
|---------|------------------------|-------------------|
| Axes (all 4) | 10, 10, 10, 10 — every day | 3–9, varying day-to-day |
| Silhouette M/F | 1.000 every day | 0.3–0.8 range |
| Silhouette A/R | 0.359 every day | 0.2–0.6 range |
| Silhouette S/D | 0.000 every day | 0.1–0.7 range |
| Contrast | 0.725 every day | 0.4–0.75 range |
| Metal tone | 0.594 (13/14 days) | 0.3–0.7 range |
| Vibrancy | 0.771–0.900 | 0.3–0.85 range |
| Essence #1 | SENSUAL (14/14 days) | ≥5 different #1s / 14 days |
| Essence top-3 | {sensual, minimal, polished/eclectic} | ≥5 unique orderings |
| Palette signature | black cherry 12/14 days | No single colour >7/14 days |
| Palette combos | ~4 distinct combos | ≥6 distinct combos |
| Textures | "vintage silk, washed cotton" every day | ≥3 different selections |
| Pattern | "nautical stripes" 13/14 days | Some days with no pattern |
| Vibe dominant | Drama 13/14 days | ≥3 different dominants |

---

## 1. Change: Sky-Only Axis Evaluation

### 1.1 Root cause

The current Stage 1 axis formula computes:

```
anchorRaw = natal+progressed raw score (no transits, no moon, no jitter)
dailyRaw  = full source raw score (natal+progressed+transits+moon+jitter)
anchorValue = scaleToAxis(anchorRaw, spread: 1.4)  → ~9.7 for Briar
dailyValue  = scaleToAxis(dailyRaw, spread: 2.0)   → ~9.9 for Briar
amplified   = anchorValue + 2.25 × (dailyValue − anchorValue) → ~10.0
clamped     = max(1, min(10, amplified)) → 10
```

The sigmoid (`tanh(raw * spread)`) saturates before the delta is computed. For Briar's chart (Scorpio sun, planets in Water/Fire with high element modifiers), both anchor and daily raw scores exceed the saturation threshold. The delta `(~10 − ~10)` is near zero; amplifying zero by 2.25 yields zero.

### 1.2 Current code

**File:** `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift`, lines 735–768

```swift
if mode == .stage1Experimental {
    let anchorRaw = computeAxisRawScore(
        axis: axis, ..., calibration: DailyFitCalibration.default,
        includeTransits: false, includeMoon: false, jitter: 0
    )
    let dailyRaw = computeAxisRawScore(
        axis: axis, ..., calibration: calibration,
        includeTransits: true, includeMoon: true, jitter: jitter
    )
    let anchorValue = scaleToAxis(anchorRaw, spread: DailyFitCalibration.default.axisTuning.sigmoidSpread)
    let dailyValue = scaleToAxis(dailyRaw, spread: calibration.axisTuning.sigmoidSpread)
    let amplified = anchorValue + stage1AxisDeltaAmplification * (dailyValue - anchorValue)
    scores[axis] = max(1.0, min(10.0, amplified))
}
```

### 1.3 Proposed code

Replace the Stage 1 block with **sky-only axis evaluation** — compute raw score from transits + moon only, then map through a gentler sigmoid (spread 0.8):

```swift
if mode == .stage1Experimental {
    // Sky-only: transits + moon + jitter — no natal/progressed contribution
    let skyRaw = computeAxisRawScoreSkyOnly(
        axis: axis,
        transits: transits,
        moonMods: moonMods,
        calibration: calibration,
        jitter: jitter
    )
    scores[axis] = scaleToAxis(skyRaw, spread: calibration.axisTuning.sigmoidSpread)
}
```

**Important:** Use `calibration.axisTuning.sigmoidSpread` — not a magic literal. The registry sets this to `0.8` for Stage 1; hardcoding would let tuning and code diverge silently.

New helper function:

```swift
private static func computeAxisRawScoreSkyOnly(
    axis: String,
    transits: [NatalChartCalculator.TransitAspect],
    moonMods: [String: Double],
    calibration: DailyFitCalibration,
    jitter: Double
) -> Double {
    var raw = 0.0
    for transit in transits {
        let w = calibration.planetAxisMap.weight(forPlanet: transit.transitPlanet, axis: axis)
        let em = axisElementModifiers[axis]?[
            signElement(forZodiacSign: transit.transitSign ?? "Aries")
        ] ?? 1.0
        raw += w * em * max(0.0, 1.0 - transit.orb / 10.0)
    }
    raw += moonMods[axis] ?? 0.0
    raw += jitter
    return raw
}
```

### 1.4 Sigmoid spread change

| Parameter | Current | Proposed | Rationale |
|-----------|---------|----------|-----------|
| `axisTuning.sigmoidSpread` in `stage1ExperimentalCalibration` | 2.0 | 0.8 | Sky-only raw scores are smaller magnitude (no natal planet sum). With spread 0.8, a raw score of ±1.0 maps to axes ~3–8 instead of saturating at extremes. |

### 1.5 What this achieves

- Axes respond to transits and lunar phase (which changes daily), not natal identity
- Lunar phase modulations (`moonPhaseAxisModulations`) produce ±0.3 on action/visibility — with spread 0.8, this creates ~2 axis-point variation just from moon alone
- Different transit planets active on different days push different axes
- Expected axis range: ~3–8 across 14 days (vs stuck at 10)

### 1.6 Why sky axes are transits + moon only (no natal, no current sun)

The original handoff Step 1 included current sun in sky axes. This spec deliberately limits sky-only axis evaluation to **transits + moon + jitter**:

- **Natal / progressed** are chart identity — including them re-saturates axes for water/fire-heavy profiles like Briar.
- **Current sun** moves ~1°/day and is already represented indirectly via lunar phase axis modulations (`moonPhaseAxisModulations`) and via sky vibe (§5B: sun at 20% of vibe weights). Adding sun to axis raw scores would double-count a slow signal and reduce transit/moon differentiation.
- **Sky vibe** (§8) carries current-sun character for tarot, palette, and pattern consumers that need sign-level energy.

If axis variation proves too flat after implementation, revisit sun as an axis input before touching production.

### 1.7 Cascading effects (unlocked by this change)

- **Silhouette:** axis deltas become non-zero → sliders move
- **Contrast:** `visibility / 10.0` no longer always 1.0
- **Pattern gate:** `visibility >= 6.0` will sometimes fail → pattern-free days
- **Texture scoring:** axis-driven scores will vary → different texture selections
- **Essence axis delta:** `(dailyAxis − chartAxis) / 9.0` becomes meaningful

---

## 2. Change: Silhouette — Sky-Axis-Centred, Drop Keyword Baseline

### 2.1 Root cause

Even if axes weren't saturated, the current formula starts from a **keyword baseline** (scanning Style Code `leanInto`/`consider`/`avoid` for words like "feminine", "structured"). For Briar's blueprint, this baseline is:
- mfBase = 1.0 (all keywords push feminine)
- arBase = 0.359
- sdBase = 0.0 (keywords push fully structured)

These are chart-identity values. The axis delta nudge (`visDelta * 0.45 * 1.25`) is at most ±0.0625 per unit of axis delta — far too small to move a baseline of 1.0 away from the ceiling or 0.0 away from the floor.

### 2.2 Current code

**File:** `BlueprintLensEngine.swift`, lines 1120–1128

```swift
if mode == .stage1Experimental, let chartAxes = snapshot.chartAxes {
    let visDelta = (snapshot.axes.visibility - chartAxes.visibility) / 9.0
    let actDelta = (snapshot.axes.action - chartAxes.action) / 9.0
    let strDelta = (snapshot.axes.strategy - chartAxes.strategy) / 9.0
    return SilhouetteProfile(
        masculineFeminine: max(0.0, min(1.0, mfBase + visDelta * 0.45 * s)),
        angularRounded:    max(0.0, min(1.0, arBase + actDelta * -0.36 * s)),
        structuredDraped:  max(0.0, min(1.0, sdBase + strDelta * -0.45 * s))
    )
}
```

### 2.3 Proposed code

For Stage 1, compute silhouette **directly from sky-only axes** centred at 0.5, with the keyword baseline stored as a reference only (like `chartAnchorScores` on essence):

```swift
if mode == .stage1Experimental {
    // Sky-driven silhouette: centred at neutral, modulated by today's sky axes
    let skyVis = snapshot.axes.visibility   // now ~3–8 from sky-only eval (step 1)
    let skyAct = snapshot.axes.action
    let skyStr = snapshot.axes.strategy

    let mf = max(0.0, min(1.0, 0.5 + (skyVis - 5.5) / 9.0 * 1.6))
    let ar = max(0.0, min(1.0, 0.5 + (skyAct - 5.5) / 9.0 * 1.4))
    let sd = max(0.0, min(1.0, 0.5 + (skyStr - 5.5) / 9.0 * 1.6))

    return SilhouetteProfile(
        masculineFeminine: mf,
        angularRounded: ar,
        structuredDraped: sd,
        chartAnchorMF: mfBase,      // NEW: stored for inspector display
        chartAnchorAR: arBase,
        chartAnchorSD: sdBase
    )
}
```

### 2.4 Formula explanation

| Variable | Formula | Range for axis 3–8 |
|----------|---------|---------------------|
| `mf` | `0.5 + (skyVis − 5.5) / 9.0 × 1.6` | 0.5 ± 0.44 → **0.06–0.94** |
| `ar` | `0.5 + (skyAct − 5.5) / 9.0 × 1.4` | 0.5 ± 0.39 → **0.11–0.89** |
| `sd` | `0.5 + (skyStr − 5.5) / 9.0 × 1.6` | 0.5 ± 0.44 → **0.06–0.94** |

With the centre at 5.5 (midpoint of the 1–10 range), sky axes in the 3–8 range produce silhouette values that span most of the 0–1 range — visible, meaningful daily movement.

### 2.5 Type addition

Add optional chart anchor fields to `SilhouetteProfile` (or a wrapper) so the inspector can show "normally you are X, today the sky says Y":

```swift
// In DailyFitTypes.swift
struct SilhouetteProfile: Codable, Equatable {
    let masculineFeminine: Double
    let angularRounded: Double
    let structuredDraped: Double
    var chartAnchorMF: Double?   // NEW — nil in production
    var chartAnchorAR: Double?
    var chartAnchorSD: Double?
}
```

---

## 3. Change: Palette — Score from Sky Vibe, Pure Top-3

### 3.1 Root cause

Palette scoring currently uses `snapshot.vibeProfile` — the delta-amplified blended vibe where drama is always 5–6 for Briar. This means role-energy alignment scores barely change:
- Signature/accent colours align with drama+edge → always score high
- Core/neutral colours align with classic+utility → always score low
- Same top scorers every day → same palette picks

### 3.2 Current code

**File:** `BlueprintLensEngine.swift`, lines 591–598

```swift
let scored = scorePaletteCandidates(candidates, snapshot: snapshot, calibration: calibration)

switch calibration.stage2Sensitivity.paletteSelectionStrategy {
case .dramaSlots:
    selected = selectViaDramaSlots(scored: scored, snapshot: snapshot)
case .coreAnchoredRanking:
    selected = selectViaCoreAnchoredRanking(scored: scored)
}
```

And scoring (line ~626–650) uses:
```swift
let vibeTotal = 21.0
// ... for each candidate:
let baseScore = alignedEnergies.reduce(0.0) {
    $0 + Double(snapshot.vibeProfile.value(for: $1)) / vibeTotal
}
```

### 3.3 Proposed changes

**A. New palette strategy enum value:**

```swift
enum PaletteSelectionStrategy: String, Equatable {
    case dramaSlots
    case coreAnchoredRanking
    case pureSkyScoring      // NEW
}
```

**B. Registry change** — Stage 1 uses new strategy:

```swift
// In stage1ExperimentalCalibration:
paletteSelectionStrategy: .pureSkyScoring
```

**C. Scoring uses skyVibeProfile** when strategy is `.pureSkyScoring`:

```swift
case .pureSkyScoring:
    let skyScored = scorePaletteCandidates(
        candidates, snapshot: snapshot, calibration: calibration,
        vibeSource: snapshot.skyVibeProfile ?? snapshot.vibeProfile
    )
    selected = selectViaPureSkyScoring(scored: skyScored)
```

**D. Selection is pure top-3 by score** — no role guarantees:

```swift
private static func selectViaPureSkyScoring(
    scored: [(colour: BlueprintColour, score: Double)]
) -> [(colour: BlueprintColour, score: Double)] {
    var top3: [(colour: BlueprintColour, score: Double)] = []
    var usedHexes = Set<String>()
    for item in scored {
        if top3.count >= 3 { break }
        let key = normalizedPaletteHex(item.colour.hexValue)
        guard !usedHexes.contains(key) else { continue }
        usedHexes.insert(key)
        top3.append(item)
    }
    return top3
}
```

### 3.4 Why sky vibe gives more variation

The sky vibe (`skyVibeProfile`) is computed from transits (30%) + lunar (50%) + current sun (20%) **without sign multipliers** — see §5B. The lunar phase energy map changes character every ~3.7 days (8 phases over 29.5 days):

| Phase | Dominant energies |
|-------|-------------------|
| New Moon | utility, classic |
| Waxing Crescent | playful, edge |
| First Quarter | playful, edge |
| Waxing Gibbous | drama, romantic |
| Full Moon | drama, playful |
| Waning Gibbous | classic, romantic |
| Last Quarter | utility, edge |
| Waning Crescent | utility, edge |

With lunar at **50%** weight (see §5B), the dominant energy in the sky vibe shifts meaningfully every 2–4 days — different dominant = different palette alignment winners.

### 3.5 Also increase paletteJitter

| Parameter | Current | Proposed | Rationale |
|-----------|---------|----------|-----------|
| `paletteJitter` | 0.15 | 0.20 | More jitter helps break ties when two candidates score similarly from the same sky vibe day. Not the primary fix, but complementary. |

---

## 4. Change: Vibrancy & Contrast — Sky-Native Inputs

### 4.1 Vibrancy — use skyVibeProfile

**Current formula:**
```
vibrancy = clamp(baseline + (drama+edge − utility+classic)/21 × vibrancyCoeff, 0, 1)
```
Reads from `snapshot.vibeProfile` (amplified blend: drama always 5–6).

**Proposed (Stage 1):**
```swift
let vibe = (mode == .stage1Experimental)
    ? (snapshot.skyVibeProfile ?? snapshot.vibeProfile)
    : snapshot.vibeProfile
```

With sky vibe, the drama+edge vs utility+classic balance shifts with lunar phase and daily transits. Example:
- Waning Crescent sky: utility=0.35, edge=0.30 → pull wins → vibrancy drops
- Waxing Gibbous sky: drama=0.35, romantic=0.30 → push wins → vibrancy rises

### 4.2 Contrast — automatically fixed by step 1

**Current formula:**
```
contrast = clamp(baseline + (visibility/10 − 0.5) × contrastCoeff, 0, 1)
```

With axes stuck at 10: `(10/10 − 0.5) × 0.45 = 0.225` → contrast = baseline + 0.225 every day.

After step 1, visibility varies ~3–8:
- visibility=4: `(0.4 − 0.5) × 0.45 = −0.045` → contrast = baseline − 0.045
- visibility=8: `(0.8 − 0.5) × 0.45 = 0.135` → contrast = baseline + 0.135

Range swing: ~0.18 across days. Sufficient for visible change.

### 4.3 Also increase `contrastCoeff` for Stage 1

| Parameter | Current | Proposed | Rationale |
|-----------|---------|----------|-----------|
| `vibrancyCoeff` | 0.45 | 0.55 | Sky vibe has lower absolute scores than blended vibe; boost coefficient so the formula produces meaningful range. |
| `contrastCoeff` | 0.45 | 0.55 | Same reasoning — with sky-only axes in 3–8 range, higher coefficient produces more visible contrast movement. |

### 4.4 Method signature change

Add `mode` parameter to both functions:

```swift
private static func deriveVibrancy(
    from palette: PaletteSection,
    snapshot: DailyEnergySnapshot,
    calibration: DailyFitCalibration = .default,
    mode: DailyFitEngineMode = .standard    // NEW
) -> Double
```

---

## 5. Change: Essence — Cap Transit Dominance, Rebalance Sky Weights

### 5.1 Root cause: Neptune monoculture

Neptune square Moon is at 100% strength for Briar for the entire 14-day window (outer planet, tight orb — moves ~2° per year). In the transit essence boost system:

```swift
private static let stage1TransitEssenceCategories: [String: StyleEssenceCategory] = [
    ..., "Neptune": .sensual, "Moon": .sensual, ...
]
```

Both Neptune AND Moon map to `.sensual`. With two top-2 transits both boosting sensual at `strength × 0.35`, sensual gets `+0.70` raw score every single day — overwhelming all other category signals.

### 5.2 Proposed changes (three independent levers)

#### A. Cap per-transit strength at 0.50 and deduplicate category boosts

**Current** (line 947–954):
```swift
if stage1Mode {
    for transit in dominantTransits.prefix(2) {
        if let boosted = stage1TransitEssenceCategories[transit.transitPlanet],
           boosted == category {
            raw += transit.strength * stage1TransitEssenceBoost
        }
    }
}
```

**Proposed:**
```swift
if stage1Mode {
    var boostedCategories = Set<StyleEssenceCategory>()
    for transit in dominantTransits.prefix(3) {
        if let boosted = stage1TransitEssenceCategories[transit.transitPlanet],
           boosted == category,
           !boostedCategories.contains(boosted) {
            let cappedStrength = min(transit.strength, 0.50)
            raw += cappedStrength * stage1TransitEssenceBoost
            boostedCategories.insert(boosted)
        }
    }
}
```

**Effect:** Max single-category transit boost goes from `2 × 1.0 × 0.35 = 0.70` to `1 × 0.50 × 0.35 = 0.175`. This is a **4x reduction** in Neptune's advantage over other signals.

#### B. Rebalance `stage1SkySourceWeights` — more lunar, less transit

| Source | Current weight | Proposed weight | Rationale |
|--------|---------------|-----------------|-----------|
| Transits | 0.50 | 0.30 | Transits move slowly (outer planets nearly static over 14 days); reduce dominance |
| Lunar | 0.35 | 0.50 | Moon moves ~13°/day, changes sign every 2.5 days — highest daily variance source |
| Current sun | 0.15 | 0.20 | Sun changes sign monthly — moderate variation |

```swift
private static let stage1SkySourceWeights = DailyFitCalibration.SourceWeights(
    natal: 0, transits: 0.30, lunarPhase: 0.50, progressed: 0, currentSun: 0.20
)
```

**Effect on sky vibe:** Lunar phase determines 50% of sky energy character. Over 14 days the moon traverses ~5 phase changes, giving 5 distinct energy profiles:
- Day 1–3: Waxing Crescent (playful, edge)
- Day 4–6: First Quarter (playful, edge)
- Day 7–9: Waxing Gibbous (drama, romantic)
- Day 10–12: Full Moon (drama, playful)
- Day 13–14: Waning Gibbous (classic, romantic)

#### C. Reduce `stage1EssenceVibeDeltaAmplification` from 4.0 to 2.5

**Current:**
```swift
private static let stage1EssenceVibeDeltaAmplification = 4.0
```

**Proposed:**
```swift
private static let stage1EssenceVibeDeltaAmplification = 2.5
```

**Rationale:** With higher amplification, whatever category has the largest delta (sky − chart) is magnified so much that no other category can compete. At 2.5, the magnification is still significant but allows secondary categories to score competitively when the top delta is dominated by a slow-moving transit.

### 5.3 Combined expected effect on essence

With all three changes:
- Neptune transit boost capped and deduplicated: sensual loses its guaranteed +0.70
- Lunar weight at 50%: sky vibe character rotates every 2–3 days
- Lower amplification: multiple categories can score within range of each other

Expected: ≥5 different #1 categories across 14 days, with top-3 orderings reflecting lunar phase shifts and transit mix.

---

## 6. Change: Metal Tone — Increase Transit Sensitivity

### 6.1 Current formula

```swift
let fireNudge = min(Double(fireHits) * calibration.stage2Sensitivity.metalNudgePerHit, 0.10)
let waterNudge = min(Double(waterHits) * calibration.stage2Sensitivity.metalNudgePerHit, 0.10)
```

Cap of 0.10 means even 3 fire transits produce the same nudge as 1. With `metalNudgePerHit = 0.10`, the cap is reached on the first hit. Metal tone can only ever move ±0.10 from baseline.

### 6.2 Proposed changes

| Parameter | Current | Proposed | Effect |
|-----------|---------|----------|--------|
| `metalNudgePerHit` | 0.10 | 0.12 | Slightly larger per-hit nudge |
| Fire/water nudge cap | 0.10 | 0.30 | Allow cumulative transit influence |
| Add lunar phase influence | none | warm bias in waxing, cool in waning | Moon phase directly modulates metal tone |

**Proposed code:**

```swift
let fireNudge = min(Double(fireHits) * calibration.stage2Sensitivity.metalNudgePerHit, 0.30)
let waterNudge = min(Double(waterHits) * calibration.stage2Sensitivity.metalNudgePerHit, 0.30)

// Stage 1: add lunar cycle modulation (warm near full moon, cool near new moon)
let lunarMetalMod: Double
if mode == .stage1Experimental {
    let fraction = snapshot.lunarContext.phaseDegrees / 360.0
    lunarMetalMod = (fraction - 0.5) * 0.15  // ±0.075 range
} else {
    lunarMetalMod = 0.0
}

return max(0.0, min(1.0, baseline + fireNudge - waterNudge + lunarNudge + lunarMetalMod))
```

**Expected:** Metal tone varies ~0.3–0.7 across 14 days (vs 0.594 fixed).

---

## 7. Change: Textures & Pattern — Sky-Responsive

### 7.1 Textures: automatically fixed by step 1

Texture scoring already uses normalised axes:

```swift
let axesNorm: [String: Double] = [
    "action":     snapshot.axes.action / 10.0,
    "tempo":      snapshot.axes.tempo / 10.0,
    "strategy":   snapshot.axes.strategy / 10.0,
    "visibility": snapshot.axes.visibility / 10.0,
]
```

Currently all axes = 10, so all axesNorm = 1.0 — the texture with highest "visibility" affinity always wins (silk: 0.8 visibility → score 0.8). After step 1 fixes axes, different days will have different axis profiles → different texture winners.

**No code change needed for v1** — step 1 cascades here automatically via axis-driven scoring.

**Caveat:** Unlike palette and essence (which read `skyVibeProfile` directly), textures remain axis-cascade only. If inspector shows texture stickiness after Steps 1 and 8, a follow-up pass can score from `skyVibeProfile` similar to palette. Do not block v1 on this.

### 7.2 Pattern: gate fixed by step 1; rotation is Stage 1 only

Pattern gate:
```swift
guard snapshot.axes.visibility >= 6.0,
      dominant == .drama || dominant == .playful || dominant == .edge
```

After step 1, visibility will sometimes be <6.0 → gate fails → no pattern that day. Additionally, with sky vibe used for vibeProfile (step 3), the dominant energy will shift off drama on some days → gate fails on different grounds.

**No code change needed** for the gate. However, for days that DO get a pattern, add **near-top rotation** among candidates scoring ≥80% of the top score.

**Must be mode-gated:** `selectDailyPattern` already seeds ties. The new “top 80%” rotation must run **only when `mode == .stage1Experimental`**. Without this gate, production pattern behaviour changes silently.

```swift
// Stage 1 only — production keeps existing tie-break / top-scorer path
if mode == .stage1Experimental {
    let topPatterns = scored.filter { $0.1 >= scored[0].1 * 0.8 }
    var rng = SeededRandomGenerator(seed: snapshot.dailySeed)
    return topPatterns.randomElement(using: &rng)?.0 ?? scored.first?.0
}
```

Pass `mode` into `selectDailyPattern` (or read it from snapshot context) — same pattern as vibrancy/contrast.

---

## 8. Change: Vibe Profile (blended) — Use Sky Vibe for Stage 1

### 8.1 Root cause

The blended `vibeProfile` used for tarot/pattern/texture is still dominated by drama for Briar because:
- `stage1AnchorSourceWeights` = production default (natal 28%, transits 35%, lunar 22%)
- `calibration.sourceWeights` = stage1 experimental (natal 16%, transits 44%, lunar 30%)
- Delta amplification 2.75× amplifies whatever direction the daily moves from anchor

For Briar, both anchor and daily land with high drama (natal chart is drama-heavy). The delta is small; amplification doesn't help.

### 8.2 Proposed change

For Stage 1, use **`skyVibeProfile` directly** as the main `vibeProfile` (not the delta-amplified blend). This is the most radical change but the most philosophically aligned with sky-forward.

#### Snapshot assembly order (implementation gap)

Today `generateSnapshot` builds `vibeProfile` **before** `skyVibe`:

```swift
let vibeProfile = generateVibeProfile(...)   // line ~65 — runs first
// ...
skyVibe = generatePartialVibeProfile(...)    // line ~97 — runs later
return DailyEnergySnapshot(vibeProfile: vibeProfile, skyVibeProfile: skyVibe, ...)
```

Setting `vibeProfile = skyVibe` therefore requires one of:

1. **Reorder:** compute `skyVibe` first, then assign `vibeProfile = skyVibe` for Stage 1; or
2. **Second pass:** build snapshot fields, then overwrite `vibeProfile` before return.

Prefer **reorder** — compute chart/sky partial vibes and axes, then derive the Stage 1 `vibeProfile` from `skyVibe` in one pass. Apply the same reorder in `generateSnapshotWithTrace`.

```swift
// After skyVibe is computed:
var vibeProfile: VibeBreakdown
if effectiveMode == .stage1Experimental, let skyVibe {
    vibeProfile = skyVibe   // Sky vibe IS the daily vibe for Stage 1
} else {
    vibeProfile = generateVibeProfile(...)
}
```

#### Remove the competing Stage 1 vibe path

After §8.2, Stage 1 no longer needs delta-amplified vibe. **Remove or clearly deprecate:**

- `generateVibeProfileStage1Amplified` and its call site in `generateVibeProfile`
- `stage1VibeDeltaAmplification` (listed as removed in §9)

Do not leave two Stage 1 vibe stories in the codebase — that invites drift and makes inspector diffs ambiguous.

**Rationale:** The sky-forward principle is "Daily Fit = today's outside energy." The blended delta-amplified vibe was a transitional approach. For Stage 1 experimental, the clean expression is: daily vibe = sky vibe. Period. The chart is the reference frame shown alongside, not mixed in.

**Impact:**
- Tarot selection scores from sky vibe → different dominant energies → different card pools
- Pattern gate reads from sky vibe dominant → sometimes non-drama dominant
- All downstream consumers get the sky's actual character

### 8.3 Alternative (less radical)

If the above is too aggressive, keep the delta-amplified blend but with much higher transit/lunar emphasis in `stage1ExperimentalCalibration.sourceWeights`:

```swift
// stage1ExperimentalCalibration sourceWeights:
// Current:  natal=0.16, transits=0.44, lunar=0.30, progressed=0.07, sun=0.03
// Proposed: natal=0.05, transits=0.35, lunar=0.45, progressed=0.03, sun=0.12
```

This makes the daily blend 92% sky-sourced, 8% natal — transit/lunar dominance without completely removing natal. Combined with amplification, this might produce enough variation without breaking tarot continuity.

**Recommendation:** Implement the radical version (§8.2) for Stage 1 — we can always A/B in the inspector against a separate "sky-forward-moderate" preset later.

---

## 9. Summary of constant changes

### In `DailyEnergyEngine.swift`

| Constant / value | Current | Proposed | Status |
|------------------|---------|----------|--------|
| `stage1SkySourceWeights.transits` | 0.50 | 0.30 | Changed |
| `stage1SkySourceWeights.lunarPhase` | 0.35 | 0.50 | Changed |
| `stage1SkySourceWeights.currentSun` | 0.15 | 0.20 | Changed |
| `stage1AxisDeltaAmplification` | 2.25 | *removed* (sky-only eval replaces it) | Removed |
| Axis sigmoid spread for Stage 1 | 2.0 | 0.8 | Changed (in registry calibration) |
| `stage1VibeDeltaAmplification` | 2.75 | *removed* (sky vibe used directly) | Removed |

### In `BlueprintLensEngine.swift`

| Constant / value | Current | Proposed | Status |
|------------------|---------|----------|--------|
| `stage1EssenceVibeDeltaAmplification` | 4.0 | 2.5 | Changed |
| `stage1TransitEssenceBoost` | 0.35 | 0.35 (unchanged) | Kept |
| Transit strength cap | none (uses raw 0–1) | 0.50 | Added |
| Transit category dedup | none | Set-based dedup | Added |
| Silhouette formula | keyword baseline + delta nudge | sky-axis centred at 0.5 | Replaced |
| Silhouette sensitivity | 0.45 × 1.25 = 0.5625 | 1.6 | Increased |
| Metal nudge cap | 0.10 | 0.30 | Increased |

### In `DailyFitEngineRegistry.swift` (`stage1ExperimentalCalibration`)

| Parameter | Current | Proposed | Rationale |
|-----------|---------|----------|-----------|
| `axisTuning.sigmoidSpread` | 2.0 | 0.8 | Prevent sky-only axes from saturating |
| `stage2Sensitivity.vibrancyCoeff` | 0.45 | 0.55 | Wider vibrancy range from sky vibe |
| `stage2Sensitivity.contrastCoeff` | 0.45 | 0.55 | Wider contrast range from sky axes |
| `stage2Sensitivity.paletteJitter` | 0.15 | 0.20 | Break palette scoring ties |
| `stage2Sensitivity.metalNudgePerHit` | 0.10 | 0.12 | Slightly larger metal transit influence |
| `stage2Sensitivity.paletteSelectionStrategy` | `.coreAnchoredRanking` | `.pureSkyScoring` | Free-flowing palette from sky vibe |

### In `DailyFitTypes.swift`

| Addition | Purpose |
|----------|---------|
| `PaletteSelectionStrategy.pureSkyScoring` | New enum case |
| `SilhouetteProfile.chartAnchorMF/AR/SD` | Optional fields for inspector display |

---

## 10. Files changed (edit map)

| File | Sections affected | Nature of change |
|------|-------------------|------------------|
| `DailyEnergyEngine.swift` | `evaluateAxes` Stage 1 block; `stage1SkySourceWeights`; `generateSnapshot` (use skyVibe as main vibeProfile) | Rewrite Stage 1 axis path; update weights; change vibeProfile assignment |
| `BlueprintLensEngine.swift` | `deriveSilhouetteProfile`; `deriveVibrancy`; `deriveContrast`; `selectDailyPalette`; `scorePaletteCandidates`; `scoreEssenceCategories` transit boost | Silhouette rewrite; add mode params to vibrancy/contrast; new palette strategy; transit cap+dedup |
| `DailyFitTypes.swift` | `PaletteSelectionStrategy` enum; `SilhouetteProfile` struct | Add `.pureSkyScoring`; add optional chart anchor fields |
| `DailyFitEngineRegistry.swift` | `stage1ExperimentalCalibration` | Update calibration values; fingerprint will change (expected) |
| `DailyEnergyEngine.swift` | New helper `computeAxisRawScoreSkyOnly` | New function |
| `BlueprintLensEngine.swift` | New function `selectViaPureSkyScoring` | New function |
| `BlueprintLensEngine.swift` | `deriveMetalTone` | Increase cap; add lunar modulation for Stage 1 |
| `BlueprintLensEngine.swift` | `selectDailyPattern` | Add seed-based near-top rotation; **gate on `stage1Experimental`** |
| `DailyEnergyEngine.swift` | `generateVibeProfile`, `generateVibeProfileStage1Amplified` | Remove Stage 1 amplified path; reorder snapshot assembly |

---

## 11. What MUST NOT change

| Item | Reason |
|------|--------|
| `DailyFitCalibration.default` | Production calibration — shipped to users |
| Production engine mode path (`.standard`) | All standard-mode code paths unchanged |
| Legacy Baseline preset | Regression reference |
| Style Guide / Blueprint composition | Palette pool is correct; only scoring/selection changes |
| Tarot selection algorithm | Already varies via recency + scores; not a stickiness problem |
| `DailyFitFrozenPayloadStorage` logic | Frozen payloads are a device-side concern, not engine |
| Inspector display/rendering logic (v1) | Fix the engine, not the renderer for this pass |
| Inspector JSON/UI for silhouette chart anchors | §2.5 adds `chartAnchorMF/AR/SD` to the payload — engine stores them, but the “reference frame” UX from the handoff will not appear until inspector JSON/UI is updated (follow-up, not a v1 blocker) |
| Any `if engineId == "..."` string checks | Must branch on `mode` or calibration at central entry points only |

---

## 12. Implementation order (dependencies)

```
Step 1 (sky-only axes) ─────────┬──→ Step 2 (silhouette)
                                 ├──→ Step 4 (contrast — auto-fixed)
                                 ├──→ Step 7 (textures/pattern — auto-fixed)
                                 │
Step 8 (vibeProfile = skyVibe) ──┼──→ Step 3 (palette scores from sky)
                                 ├──→ Step 4 (vibrancy from sky vibe)
                                 └──→ Step 7 (pattern gate from sky dominant)
                                 
Step 5 (essence tuning) ──────── independent (operates on separate skyVibeProfile/chartVibeProfile)

Step 6 (metal tone) ──────────── independent
```

**Recommended order:** 1 → 8 → 2 → 3 → 4 → 5 → 6 → 7

Steps 1 and 8 are the keystone changes. Everything else is either automatic (fixed by axis/vibe fixes) or tuning.

---

## 13. Testing strategy

### 13.1 Existing tests that must still pass (production/legacy)

All tests in `BlueprintLensEngine_Payload_Tests.swift` and `DailyFitAshTodayTomorrow_Tests.swift` that use production or legacy_baseline presets must pass unchanged. These validate standard mode paths.

### 13.2 Stage 1 tests to update (explicit file list)

Do not rely on “update Stage 1 fixtures” in the abstract — these named tests will fail CI if missed:

| File | Test / ID | Current assertion | New assertion |
|------|-----------|-------------------|---------------|
| `BlueprintLensEngine_Payload_Tests.swift` | **T4.32** `testStage1ExperimentalIsCoreAnchored` | `paletteSelectionStrategy == .coreAnchoredRanking` | `== .pureSkyScoring` |
| `DailyFitEngineRegistry_Tests.swift` | `stage1FingerprintDiffersFromProduction` | Hash differs from production | Hash WILL change again (update expected if asserted) |
| `DailyFitEngineRegistry_Tests.swift` | `stage1ExperimentalDiffersFromProduction` | Fixed fixture diff vs production | Re-baseline vibe/essence/palette/scales if assertions are exact |
| `DailyFitEngineRegistry_Tests.swift` | `stage1ExperimentalDescriptor` | Calibration + mode descriptors | Verify `pureSkyScoring`, `sigmoidSpread == 0.8`, updated weights |
| `inspector/.../DailyFitEngineRegistryInspectorTests.swift` | Fingerprint / descriptor tests | Mirror app registry | Keep inspector lib in sync with app registry changes |
| `TarotEngineNamespaceMigration_Tests.swift` | Stage 1 payload fixture | Uses `stage1_experimental` id | Re-baseline if tarot selection changes under sky vibe |
| T4.27–T4.33 (`BlueprintLensEngine_Payload_Tests.swift`) | coreAnchoredRanking suite | Role guarantees | **Unchanged** — these use `Fixtures.coreAnchoredCalibration`, not Stage 1 preset |

Add new Stage 1–specific tests (pure sky scoring, sky-only axes) in `BlueprintLensEngine_Payload_Tests.swift` or a dedicated `DailyFitSkyForwardV2_Tests.swift` — prefer a dedicated file if Briar 14-day fixtures are large.

### 13.3 New tests to add

#### A. Golden date fixtures (merge gates — deterministic)

Prefer **fixed date + ephemeris → expected band** over statistical thresholds alone. Add 2–3 Briar golden fixtures alongside the 14-day window:

| Fixture | Date | Assert (examples) |
|---------|------|-------------------|
| Briar golden A | 2026-05-21 | Axis visibility in band 4–7; essence #1 ≠ locked sensual if cap works |
| Briar golden B | 2026-05-28 | Different axis profile than A; palette hex set differs from A |
| Briar golden C | 2026-06-03 | Silhouette MF/AR/SD not equal to golden A; vibe dominant documented |

Store expected values as ranges or ordered sets, not fragile exact floats, unless the pipeline is fully deterministic (it should be for fixed seed + date).

#### B. Briar 14-day smoke tests (non-blocking or soft thresholds)

These validate the stress profile but are **profile- and window-dependent** — a quiet transit week may legitimately fail std-dev gates:

| Test | Assertion | Gate |
|------|-----------|------|
| Sky-only axes (Stage 1) | Axes are NOT all 10 for Briar across 14 days | Smoke |
| Axis variation | std-dev of each axis across 14 days > 0.5 | Smoke — not sole merge gate |
| Silhouette variation | Not all values identical across 14 days | Smoke |
| Palette variation | ≥4 distinct 3-colour combos across 14 days | Smoke |
| Essence variation | ≥3 different #1 categories across 14 days | Smoke |
| Contrast not stuck | Not all identical across 14 days | Smoke |
| Production unchanged | Production preset output identical to pre-change baseline | **Hard gate** |
| Legacy baseline unchanged | Legacy preset output identical to pre-change baseline | **Hard gate** |
| Transit cap | Single transit at strength=1.0 contributes max 0.175 to essence (0.50 × 0.35) | Hard gate |
| Fire / earth / air presets | No regressions on non-Briar calibration profiles (Ash harness, Maria if available) | Hard gate |

**Do not rely only on statistical thresholds for merge gates.** Manual inspector sign-off (§13.4) remains appropriate for Briar 14-day targets.

### 13.4 Inspector validation (manual, Ash sign-off)

Run Briar 14-day compare in Inspector with Stage 1 selected. Compare against §0 targets:

| Surface | Target |
|---------|--------|
| Axes | 3–9 range, varying |
| Silhouette | All three sliders move |
| Contrast | Not identical every day |
| Vibrancy | Range ≥ 0.2 |
| Metal tone | Range ≥ 0.15 |
| Essence top-3 | ≥5 unique orderings |
| Palette | ≥6 distinct combos; no colour > 7/14 |
| Textures | ≥3 different selections |
| Pattern | Some days no pattern |
| Vibe dominant | ≥3 different dominants |

---

## 14. Risk assessment

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Sky-only axes too volatile (swings wildly day-to-day) | Low | Sigmoid spread 0.8 still provides soft clamping; axis range will be ~3–8 not 1–10 |
| Silhouette values cluster at 0.5 (everything neutral) | Low | Sensitivity multiplier 1.6 ensures axes in 3–8 produce values across 0.1–0.9 |
| Palette becomes incoherent (random colours unrelated to user) | Low | Colours still drawn from the user's Style Guide pool — only scoring changes, not the pool |
| Essence becomes meaningless noise | Medium | Dedup by **category** (not planet) fixes sensual monoculture but may yield weak or flip-floppy #1s on low-signal days. Monitor in inspector — if noise rather than weather, reduce lunar weight (§5B) in a quick second pass. |
| Production path accidentally affected | Low | All changes gated on `mode == .stage1Experimental` or `.pureSkyScoring` strategy enum. Existing test suite provides safety net. |
| Fingerprint changes break inspector comparison | Certain | Expected and acceptable — fingerprint should change because the algorithm changed. Document in release notes. |

---

## 15. Reversibility

All changes are confined to:
1. `stage1ExperimentalCalibration` (constant values in registry)
2. Code paths gated on `mode == .stage1Experimental`
3. New enum cases / optional struct fields (additive, non-breaking)

To revert: restore the previous `stage1ExperimentalCalibration` values and the gated code paths. Production is never touched.

---

## 16. Summary: what changes vs what stays

### Changes (Stage 1 only)

1. **Axes:** Sky-only evaluation (transits + moon), no natal, spread 0.8
2. **Vibe (main):** = sky vibe directly (no delta-amplified blend)
3. **Silhouette:** Sky-axis-centred at 0.5, sensitivity 1.6, chart baseline stored as reference
4. **Palette:** Score from sky vibe, pure top-3 selection, no role guarantees
5. **Vibrancy:** Read from sky vibe, increased coefficient
6. **Contrast:** Automatically fixed by axis fix; increased coefficient
7. **Essence:** Reduced amplification (4.0 → 2.5), transit cap 0.50, category dedup, rebalanced sky weights (lunar 50%)
8. **Metal tone:** Higher nudge cap, lunar cycle modulation
9. **Textures:** Axis cascade fix for v1; sky-vibe scoring is optional follow-up if stickiness remains
10. **Pattern:** Gate fixed by axis/vibe changes; near-top seed rotation **Stage 1 only**

### Stays the same

- Production engine path
- Legacy Baseline path
- Style Guide / Blueprint composition
- Colour pool for palette
- Tarot selection
- All consumer-facing API shapes (additive optional fields only)
- Chart anchor storage (payload fields); inspector **display** of chart anchors is follow-up work

---

## 17. Implementation checklist (pre-flight)

Complete these before or during the first coding PR:

1. **Snapshot assembly:** Compute `skyVibe` before assigning `vibeProfile` in Stage 1; apply same order in `generateSnapshotWithTrace`. Remove `generateVibeProfileStage1Amplified` / `stage1VibeDeltaAmplification` — no competing Stage 1 vibe path.
2. **Calibration, not literals:** Stage 1 axis scaling uses `calibration.axisTuning.sigmoidSpread` (registry value `0.8`), never a hardcoded spread in engine code.
3. **Pattern rotation gate:** Near-top (80%) seed rotation in `selectDailyPattern` runs **only** for `stage1Experimental`.
4. **Tests:** Update **T4.32** → `pureSkyScoring`; re-baseline fingerprint / Stage 1 fixture tests listed in §13.2; add 2–3 Briar golden date fixtures (§13.3A).
5. **Merge gates:** Production + legacy tests green; golden fixtures pass; fire/earth/air preset spot-checks pass; Briar 14-day statistical tests are smoke-only unless promoted after review.
6. **Inspector sign-off:** Ash runs Briar 14-day compare (§13.4) — targets met, no incoherent palette/essence noise.
7. **Optional follow-ups (not v1 blockers):** Inspector UI for silhouette chart anchors; texture scoring from `skyVibeProfile` if axes-only cascade is too weak; §8.3 “moderate blend” preset if tarot/palette feels too disconnected from chart identity.

### Definition of done

- Production and legacy baseline tests **green** (unchanged output).
- Stage 1 implementation matches §1–§9 with §17 checklist closed.
- Briar inspector targets (§13.4) met on 14-day compare.
- No regressions on fire/earth/air presets (Ash harness minimum).
- Fingerprint change for `stage1_experimental` documented; not a production fingerprint change.

---

## 18. Architecture verdict (implementation review)

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Problem diagnosis | Strong | Evidence table + saturation math |
| Separation of concerns | Strong | Sky/chart split, calibration-driven, mode gates |
| Minimality | Good | Reuses existing scoring paths |
| Reversibility | Strong | Registry + gated branches |
| Test plan | Good — completed by §13.2–§13.3 | Golden fixtures + explicit test list |
| Production safety | Strong | If §11 guardrails and production tests stay green |
| Ready to ship Stage 1 to **all users** | No | Experimental by design |
| Ready to **implement** | Yes | After §17 checklist |

Promotion to `.standard` requires multi-profile inspector review and possibly the §8.3 moderate-blend fallback if sky-only tarot/palette coherence feels too disconnected from chart identity.

---

*End of spec.*
