# Daily Fit Redesign Audit & Assessment Report

**Date:** 10 May 2026
**Author:** AI Architecture Audit (Second Opinion)
**Scope:** Assess legacy Daily Fit pipeline, evaluate prior AI plan, recommend path forward

---

## 1. Executive Summary

The prior AI plan (`daily_fit_audit_c4ef4ff1.plan.md`) identifies the right *direction* — a Blueprint-first redesign — but is too surface-level and non-committal to act on. It reads as a planning outline that restates the problem rather than solving it. This report goes deeper: it maps every component of the current pipeline with a keep/discard/redesign verdict, identifies the specific architectural failures that make calibration impossible, and proposes a concrete foundation architecture with a clear input/output contract.

**Bottom line:** The legacy pipeline has sound *concepts* but unsound *execution*. Controlled rebuild is the right call. The prior plan got that right but didn't go far enough in specifying what the replacement looks like.

---

## 2. Assessment of Prior AI Plan

### What It Gets Right

| Aspect | Verdict |
|---|---|
| Identifies Blueprint as foundation | Correct |
| Weather out of scope for V1 | Correct |
| Mermaid flow diagram direction | Broadly correct |
| Keep list (deterministic seeding, tarot metadata, vibe breakdown concept, derived axes concept, recency tracking) | Mostly correct |
| "Controlled rebuild not patching" | Correct |

### What It Gets Wrong or Misses

| Gap | Why It Matters |
|---|---|
| **No diagnosis of the actual calibration problem** | The plan says "the current system mixes things in one fragile flow" but doesn't explain *why* calibration fails. Without this, the redesign will repeat the same mistakes. |
| **No concrete input/output contract** | It says "Daily Energy Lens" and "Selection Context" without defining what data those things contain, what their types are, what their ranges are. This is a design doc that would need another design doc before work could start. |
| **Doesn't address the dual-token problem** | The codebase has *two* competing token types: `StyleToken` (legacy Daily Fit) and `BlueprintToken` (new Blueprint). The plan doesn't acknowledge this or propose how the Daily Fit consumes Blueprint data. |
| **Misses the WeightingModel disaster** | `natalWeight` is `0.6` while `progressedWeight` is `20`. That's a 33x difference in scale that the `DistributionTargets` struct tries to fix post-hoc. This is *the* root cause of calibration fragility and the plan doesn't mention it. |
| **Omits the SemanticTokenGenerator monolith** | 4,100+ lines, 260KB. This is the real enemy. The plan lists it as a pipeline stage to "assess" but doesn't call out that it needs to be decomposed entirely. |
| **No mention of the 6-energy system's limitations** | The 21-point vibe breakdown is a reasonable concept but the token-to-energy mapping uses hardcoded string sets that overlap (e.g. "bold" maps to both Drama *and* Playful for Leo). No calibration knobs. |
| **Doesn't propose calibration architecture** | Says "centralised weights, explainable score breakdowns" as a bullet point. Doesn't explain how. |

### Verdict on the Plan

**Somewhere in between go and no-go.** The direction is sound but you cannot hand this to a developer and get a working system. It needs to be replaced with an opinionated architecture spec that has concrete types, defined stages, and explicit calibration surfaces.

---

## 3. Current Pipeline: What Exists

### 3.1 The Flow (As-Built)

```
User Profile (natal chart, birth data)
        │
        ▼
NatalChartCalculator ──► NatalChart struct (planets, houses, aspects, ascendant)
        │
        ├──► Progressed chart calculation
        │
        ▼
SemanticTokenGenerator.generateDailyFitTokens()
        │   Inputs: natal chart, progressed chart, transits, weather, lunar phase
        │   Output: [StyleToken] — flat array of ~80-150 weighted tokens
        │   PROBLEM: 4,100-line monolith, inconsistent weighting units
        │
        ▼
┌───────────────────────────────────────────────────┐
│  PARALLEL CONSUMERS OF THE TOKEN ARRAY            │
│                                                   │
│  VibeBreakdownGenerator → VibeBreakdown           │
│    (6 energies, 21 points total)                  │
│                                                   │
│  DerivedAxesEvaluator → DerivedAxes               │
│    (4 axes: action, tempo, strategy, visibility)  │
│          │                                        │
│          ▼                                        │
│  AxisVolatilityEngine → modulated DerivedAxes     │
│    (transit/moon/seed modulation)                  │
│                                                   │
│  TarotCardSelector → TarotCard                    │
│    (multi-stage: axis filter → vibe+axis score    │
│     → recency penalty → tie-break)                │
│          │                                        │
│          ▼                                        │
│  StyleEditSelector → StyleEditVariant             │
│    (cosine similarity on vibe/axes)               │
│                                                   │
│  DailyColourPaletteGenerator → [StyleToken]       │
│    (score style-guide colours for today)           │
│                                                   │
│  [COMMENTED OUT: textiles, colours, patterns,     │
│   shape, accessories, layering sections]          │
│                                                   │
└───────────────────────────────────────────────────┘
        │
        ▼
DailyVibeContent struct (assembled payload for UI)
        │
        ▼
DailyFitViewController / DailyVibeInterpretationViewController
```

### 3.2 Component-by-Component Assessment

#### SemanticTokenGenerator (260KB, ~4,100 lines)
- **Role:** Generates all `StyleToken` arrays for both Style Guide and Daily Fit
- **Problem:** Monolith. Handles natal tokens, transit tokens, colour tokens, weather tokens, moon phase tokens, current sun tokens, daily signature tokens, fabric tokens, and more — all in one file with interleaved logic
- **Verdict:** DISCARD implementation, KEEP the concept of origin-tagged weighted tokens

#### WeightingModel
- **Role:** Holds weight constants for token generation
- **Problem:** `natalWeight = 0.6`, `progressedWeight = 20`, `moonPhaseWeight = 0.95`, `transitWeight = 0.55`. These are on completely different scales. The `DistributionTargets` struct then post-hoc scales everything to compensate. This is the #1 source of calibration fragility
- **Verdict:** DISCARD. Replace with a single normalised weighting surface

#### VibeBreakdownGenerator (887 lines)
- **Role:** Maps tokens to 6 energy buckets (Classic, Playful, Romantic, Utility, Drama, Edge), distributes 21 points
- **Strengths:** The 6-energy model is intuitive and useful. The 21-point budget forces trade-offs. Sun-sign personality multipliers are astrologically reasonable
- **Problems:** Token-to-energy mapping is hardcoded string matching. Overlapping sets. Sun-sign multipliers were manually tuned from comments showing previous values (e.g. Leo Drama was 2.1, now 1.5). No way to adjust one energy without manually checking all 12 sign blocks
- **Verdict:** REDESIGN. Keep the 6-energy model and 21-point budget. Replace string-matching with a proper mapping table. Centralise sun-sign multipliers into a data-driven config

#### DerivedAxesEvaluator (263 lines)
- **Role:** Evaluates 4 orthogonal style-manifestation axes from tokens
- **Strengths:** Clean concept. Action/Tempo/Strategy/Visibility is a useful dimensional model for "how style energy is expressed"
- **Problems:** Scaling formula `5.0 + (rawScore * 0.5)` means all axes cluster around 5-8 in practice. Transit tokens barely move the needle due to the base-5 floor. Moon phase tokens sometimes produce *negative* raw scores that get absorbed by the floor
- **Verdict:** REDESIGN. Keep the 4-axis model. Fix the scaling so axes actually use their full 1-10 range

#### AxisVolatilityEngine (127 lines)
- **Role:** Adds daily variation to axes via transit count, moon phase, token diversity, and deterministic seed
- **Strengths:** Multiplicative modulation is the right approach. Seed-based variation ensures determinism
- **Problems:** Modulation ranges are tiny (±10-15%). Combined with the base-5 clustering in the evaluator, this means axes barely move day to day. The `sin(seed * constant)` approach is fine for determinism but the constants are arbitrary
- **Verdict:** REDESIGN. Increase modulation range. Consider making this *additive* on top of a wider-ranging base evaluation rather than multiplicative on a narrow range

#### TarotCardSelector (1,059 lines)
- **Role:** Multi-stage card selection: axis filter → multi-factor score (50% vibe, 35% axes, 15% boost) → recency penalty → tie-break
- **Strengths:** Well-structured multi-stage approach. Recency tracking prevents repetition. Vibe-adaptive axis filtering is smart. The `EngineConfig` pattern for thresholds is good
- **Problems:** Overly complex for what it does. The fallback chains mean any calibration issue upstream cascades. Card axis data is on 0-100 scale while day axes are 1-10 (normalisation happens mid-scoring)
- **Verdict:** KEEP with simplification. The multi-stage approach and recency tracking are solid. Normalise axis scales at data load time, not scoring time

#### DailyColourPaletteGenerator (337 lines)
- **Role:** Selects 3 daily colours from style guide, plus V4 deterministic rotation
- **Strengths:** The V4 path (`selectV4DailyColours`) is clean, simple, deterministic, and draws from the Blueprint palette. This is *already* doing what you want for colour
- **Problems:** The legacy path uses string-matching for vibe-to-colour alignment (hardcoded colour name lists). The V4 path exists but the legacy path is still the primary consumer
- **Verdict:** KEEP V4 path, DISCARD legacy path. The V4 path should become the *only* colour selection path

#### DailyVibeContent struct
- **Role:** The assembled payload consumed by UI
- **Strengths:** Clear struct with named fields
- **Problems:** Half the fields are commented out (textiles, colours, patterns, shape, accessories, layering). Contains both legacy `paletteColours` and new `v4DailyPalette`. Contains raw `styleTokens` array which the UI shouldn't need
- **Verdict:** REDESIGN as the clean output contract for the new pipeline

---

## 4. The Real Calibration Problem (Why the Legacy System Is Fragile)

The plan needs to understand *why* calibration is hard, not just that it is. There are four compounding issues:

### 4.1 Inconsistent Weight Scales
`natalWeight = 0.6` is applied as a multiplier inside token generation. `progressedWeight = 20` is applied... somewhere else in the generator. `moonPhaseWeight = 0.95`. These aren't on the same scale, so their relative influence is unknowable without tracing through the full 4,100-line generator. When you change one, you can't predict what happens to the distribution.

### 4.2 Post-Hoc Correction Instead of Normalised Input
`DistributionTargets.getScalingFactors()` computes scaling factors *after* tokens are generated to nudge the distribution toward targets. This is like adjusting the seasoning after the dish is burnt — it can help but it can't fix the underlying proportions. (And it's currently **disabled** in the vibe breakdown: `let scaledTokens = tokens` with a comment saying "DISTRIBUTION SCALING DISABLED FOR TESTING".)

### 4.3 Cascading Overrides
Sun-sign personality multipliers in `VibeBreakdownGenerator` multiply raw scores *after* token weights have already been accumulated. So the influence chain is: `baseWeight × priorityMultiplier × chartRulerMultiplier × WeightingModel.natalWeight → token.weight → baseWeight × 2.0 + bonus + sunSignBoost → score × sunSignMultiplier`. That's at least 6 layers of multiplication with no single place to see the combined effect.

### 4.4 String-Based Mapping Fragility
Token names are freeform strings. The energy mapping works by checking if `token.name.lowercased()` is in a hardcoded `Set<String>`. If the token generator produces "Structured" instead of "structured", or "bold-assertive" instead of "bold", the mapping silently fails. There's no compiler help, no runtime validation.

---

## 5. The Blueprint Foundation (What You Have to Work With)

The `CosmicBlueprint` model (`BlueprintModels.swift`) is **well-designed** and ready to serve as the Daily Fit's style envelope. Here's what's available:

### Palette (the most immediately useful section)
- `neutrals`: 4 neutral anchor colours (V4)
- `coreColours`: 4 core colours
- `accentColours`: 4 accent colours
- `supportColours`: 4 versatile complements (V4.2+)
- `lightAnchor` / `deepAnchor`: edge anchors (V4.3+)
- `luminarySignature` / `rulerSignature`: chart-derived hero colours (V4.4+)
- `family`: PaletteFamily (e.g. "Deep Autumn")
- `cluster`: PaletteCluster (e.g. "Deep Warm Structured")
- `variables`: DerivedVariables (depth, warmth, contrast, etc.)

### Textures
- `recommendedTextures`: top 4 (deterministic)
- `avoidTextures`: top 3 (deterministic)
- `sweetSpotKeywords`: top 2 (deterministic)

### Hardware
- `recommendedMetals`: deterministic list
- `recommendedStones`: deterministic list

### Patterns
- `recommendedPatterns`: deterministic list
- `avoidPatterns`: deterministic list

### Code (Style Directives)
- `leanInto`: 4-6 directives
- `avoid`: 4-6 directives
- `consider`: 3-4 directives

### Occasions
- `workText`, `intimateText`, `dailyText`: context-specific guidance

This is a **rich, typed, deterministic** style envelope. The Daily Fit should treat this as the *unchanging foundation* that the daily astrology filters through.

---

## 6. Proposed V1 Architecture: Blueprint-Lens Pipeline

### 6.1 Core Principle

> The Blueprint defines *what* the user wears. The daily astrology defines *how* they wear it today.

The Blueprint is the stable wardrobe. The daily energy is the lens through which today's selection is made from that wardrobe. You never generate new style attributes on the fly — you select, emphasise, and combine from the existing Blueprint palette, textures, patterns, and directives.

### 6.2 Pipeline Stages

```
STAGE 1: DAILY ASTROLOGY SNAPSHOT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Inputs:
  - NatalChart (persisted)
  - Current transits (computed daily)
  - Lunar phase (computed daily)
  - Progressed chart (computed, changes slowly)
  - Date

Output: DailyEnergySnapshot
  - vibeProfile: VibeBreakdown (6 energies, 21 points)
  - axes: DerivedAxes (action, tempo, strategy, visibility — 1-10)
  - dominantTransits: [Transit] (top 3-5 most active)
  - lunarContext: LunarContext (phase name, waxing/waning, element)
  - dailySeed: Int (deterministic)

No style decisions here. Pure astrological distillation.


STAGE 2: BLUEPRINT LENS APPLICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Inputs:
  - CosmicBlueprint (persisted)
  - DailyEnergySnapshot (from Stage 1)

Output: DailyFitPayload
  - dailyPalette: DailyPalette (3 colours from blueprint, chosen by energy)
  - dailyTextures: [String] (2-3 from blueprint.textures.recommended, filtered by axes)
  - dailyPattern: String? (from blueprint.patterns.recommended, if axes/energy call for it)
  - tarotCard: TarotCard (selected by vibe + axes)
  - styleEditVariant: StyleEditVariant (from tarot card, matched to vibe)
  - energySummary: EnergySummary (human-readable vibe/axes description)
  - vibeBreakdown: VibeBreakdown (passed through for UI bars)
  - axes: DerivedAxes (passed through for UI)

All selections are FROM the Blueprint. The energy just determines which 
Blueprint elements get highlighted today.


STAGE 3: UI PAYLOAD ASSEMBLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Inputs:
  - DailyFitPayload (from Stage 2)
  - CosmicBlueprint (for full palette context)

Output: DailyFitViewModel (whatever the UI needs)

Purely a formatting/display concern. No scoring logic.
```

### 6.3 The Calibration Architecture

This is the key thing the prior plan missed. Every scoring decision should flow through a single, inspectable config:

```swift
struct DailyFitCalibration {
    
    // STAGE 1: How much each astrological source contributes 
    // to the energy snapshot. All values 0-1, must sum to 1.0.
    struct SourceWeights {
        let natal: Double        // ~0.40 — stable foundation
        let transits: Double     // ~0.25 — daily variation driver
        let lunarPhase: Double   // ~0.15 — emotional rhythm
        let progressed: Double   // ~0.15 — slow evolution
        let currentSun: Double   // ~0.05 — seasonal background
    }
    
    // STAGE 1: How each energy is boosted/dampened per sun sign.
    // All values are multipliers around 1.0 (0.8 = 20% reduction, 
    // 1.3 = 30% boost). Stored as a dictionary, loadable from JSON.
    typealias SignEnergyMultipliers = [String: [Energy: Double]]
    
    // STAGE 1: How each planet contributes to each axis.
    // Explicit mapping, no string matching.
    typealias PlanetAxisWeights = [String: [Axis: Double]]
    
    // STAGE 2: How the energy snapshot maps to Blueprint selection.
    struct SelectionWeights {
        let vibeWeight: Double   // How much vibe breakdown influences selection
        let axisWeight: Double   // How much axes influence selection
        let transitBoost: Double // Extra weight for colours whose planet is transited
    }
}
```

Every magic number in the current system becomes a named field in this struct. Want to make transits more influential? Change `transits` from 0.25 to 0.35 (and reduce something else since they sum to 1.0). Want Leo to be more dramatic? Change the Leo entry in `SignEnergyMultipliers`. One place, predictable effects, no cascading surprises.

### 6.4 What This Buys You

1. **Blueprint colours only**: Deep Autumn users never see pastels because colours are selected *from their palette*, not generated fresh
2. **Daily variation that respects identity**: A full moon shifts the emphasis from core colours to accent colours, not from autumn tones to spring tones
3. **Inspectable calibration**: Every scoring decision traces back to a named weight. `print(calibration)` shows the full configuration
4. **Testable in isolation**: Stage 1 can be tested with fixture charts. Stage 2 can be tested with fixture blueprints + fixture snapshots. No need to run the full app
5. **No string matching for energy mapping**: Planet-to-axis and token-to-energy mappings use enums and typed dictionaries

---

## 7. Keep / Discard / Redesign Decision List

| Component | Decision | Reason |
|---|---|---|
| `NatalChartCalculator` + foundation layer | **KEEP** (untouched) | Rock solid, well-tested |
| `CosmicBlueprint` / `BlueprintModels` | **KEEP** (untouched) | Well-designed, typed, versioned |
| `BlueprintStorage` | **KEEP** (untouched) | Simple, works |
| `DailySeedGenerator` | **KEEP** | Deterministic seeding is essential for reproducibility |
| `TarotCards.json` + `TarotCard` model | **KEEP** | Rich metadata, energy affinities, axis affinities already defined |
| `StyleEditVariant` system | **KEEP** | Cosine-similarity variant selection is sound |
| `TarotRecencyTracker` | **KEEP** | Prevents stale repetition, works correctly |
| `V4DailyPalette` selection | **KEEP** | Already does Blueprint-first colour selection correctly |
| `VibeBreakdown` struct | **KEEP** the model, **REDESIGN** the generator | 6-energy / 21-point concept is good; generation needs data-driven mapping |
| `DerivedAxes` struct | **KEEP** the model, **REDESIGN** the evaluator | 4-axis concept is good; evaluation needs wider range and proper scaling |
| `TarotCardSelector` | **KEEP** with simplification | Multi-stage approach works; remove legacy scoring paths, normalise scales at load |
| `SemanticTokenGenerator` | **DISCARD** | 4,100-line monolith, unrecoverable. Daily Fit tokens should be generated by a new, focused, <300-line generator |
| `WeightingModel` / `DistributionTargets` | **DISCARD** | Incoherent scale, post-hoc band-aids. Replace with `DailyFitCalibration` |
| `DailyColourPaletteGenerator` (legacy path) | **DISCARD** | String-matching colour alignment. V4 path replaces it |
| `AxisVolatilityEngine` | **DISCARD** | Merge its concerns (transit modulation, moon modulation) into the redesigned evaluator. Separate "volatility" engine is over-abstraction for ±12% adjustments |
| `StyleToken` (for Daily Fit use) | **DISCARD** | Too many fields (tier, effortLevel, tags, oppositeOf). Daily Fit should consume Blueprint data directly, not re-tokenise it |
| `DailyVibeContent` | **DISCARD** | Replace with `DailyFitPayload` — clean output contract, no commented-out fields |
| `DailyVibeGenerator` | **DISCARD** | The orchestrator. Replace with a clean 2-stage pipeline function |
| Weather integration | **DISCARD** | Already partially removed. Not useful for style energy. Could return as a future contextual feature |
| Maria's Style Brief generator | **DISCARD** | Sun-sign switch statement generating canned text. If copy is needed, derive from tarot card's style edit |
| `InterpretationTextLibrary` / template text | **DISCARD** for Daily Fit | Was for legacy section copy. Daily Fit V1 doesn't need generated prose sections |

---

## 7b. Additional Bugs & Hazards Found During Deep Audit

The exploration agents uncovered several issues beyond the architectural concerns above. These reinforce the case for rebuild rather than patching:

| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 1 | **`StyleEditSelector` normalises vibe energies by `/100` instead of `/21`** — labels say cosine similarity but the scale is wrong, compressing all vibe influence to ~21% of its intended range | `TarotCard.swift` (`selectBestVariant`) | High — style edit selection is miscalibrated |
| 2 | **`DailyVibeContent.derivedAxes` is never assigned** — the modulated axes are computed but the assignment line is commented out. Anything reading `derivedAxes` from persisted content gets the default `(5, 5, 5, 5)` | `DailyVibeGenerator.swift` ~line 931 | High — persisted data is wrong |
| 3 | **`AxisVolatilityEngine.calculateMoonPhaseModulation` has inverted logic** — `fullMoonFactor = abs(phase - 0.5) * 2` is *largest* near new moon (phase ≈ 0.0), opposite to the inline comment "Full moon = higher visibility/action" | `AxisVolatilityEngine.swift` ~line 71 | Medium — moon modulation is backwards |
| 4 | **Dual moon phase sources** — tab controller passes `moonPhase` into `generateDailyFitTokens`, but `generateMoonPhaseTokens()` recomputes from `Date()` internally. Usually aligned, but conceptually duplicated and fragile | `SemanticTokenGenerator.swift` | Low — works in practice, architecturally unsound |
| 5 | **`InterpretationTextLibraryShim` returns empty data** — planet-in-sign tables are empty stubs, so `tokenizeForPlanetInSign` falls back to empty elemental arrays. Natal/progressed/current-Sun library-driven tokens effectively vanish | `InterpretationTextLibraryShim.swift` | High — most natal token content is silently missing |
| 6 | **`TransitCapper` header says 35% cap, `EngineConfig.transitCap` is 0.65 (65%)** — stale documentation, actual behaviour is permissive | `TransitCapper.swift` + `EngineConfig.swift` | Low — behaviour is fine, docs misleading |
| 7 | **`CosmicFitTabBarController` never passes `styleGuideColours`** — the tab flow calls `generateDailyVibe` with default `[]`, so legacy `selectDailyColours` always sees zero Style Guide colours. Only V4 palette path actually works | `CosmicFitTabBarController.swift` | Medium — legacy colour path is silently dead |
| 8 | **Tarot card axes are 0-100, day axes are 1-10** — normalisation happens mid-scoring (`card.axes.action / 10.0`) rather than at load time, making the scoring logic harder to reason about | `TarotCardSelector.swift` ~line 500 | Low — works but fragile |

These bugs are *symptoms* of the architectural problems described in section 4. Fixing them individually would be whack-a-mole; the redesign addresses them structurally.

---

## 8. Open Questions for Discussion

Before implementation, I'd want your input on:

1. **Tarot as anchor vs tarot as one-of-many**: Currently the tarot card is the emotional/narrative centrepiece of the Daily Fit. Should it remain the primary "headline" of the daily output, or should the Blueprint-filtered energy summary take that role?

2. **How many "sections" for V1?**: You said you don't want to go into sections yet, which I respect. For the foundation, I'm proposing the payload carries: palette, textures, pattern (optional), tarot + style edit, vibe bars, axes. Is that the right scope, or do you want to trim further?

3. **Progressed chart significance**: The progressed chart changes very slowly (progressed Moon moves ~1 degree/month). In the new model, do you want it as a Stage 1 input (as proposed), or should it only affect the Blueprint itself (generated once, baked in)?

4. **Energy names**: The 6 energies (Classic, Playful, Romantic, Utility, Drama, Edge) — are these the right buckets? They feel right for fashion but "Utility" is the odd one out now that weather is removed. Should it be renamed or replaced?

5. **Calibration JSON vs code**: Should `DailyFitCalibration` be a Swift struct with compile-time constants (faster iteration during dev, harder to tweak after ship) or a JSON file loaded at startup (slower iteration during dev, can be updated via config push)?

---

## 9. Recommended Next Steps

1. **Agree on this architecture** — discuss the open questions above, adjust the pipeline stages if needed
2. **Define the `DailyEnergySnapshot` and `DailyFitPayload` types** — concrete Swift structs with all fields typed
3. **Build Stage 1 in isolation** — new `DailyEnergyEngine` that takes natal chart + transits + moon + progressed and outputs `DailyEnergySnapshot`. Test with fixture data
4. **Build Stage 2 in isolation** — new `BlueprintLensEngine` that takes `CosmicBlueprint` + `DailyEnergySnapshot` and outputs `DailyFitPayload`. Test with fixture data
5. **Wire into existing UI** — replace `DailyVibeGenerator.generateDailyVibe()` call with new pipeline
6. **Calibrate** — run across test users and dates, adjust `DailyFitCalibration` weights until results feel right
7. **Strip dead code** — remove all legacy Daily Fit files that are no longer referenced

This is a rebuild, but it's a *focused* rebuild. The astronomical layer is untouched. The Blueprint layer is untouched. The UI layer needs minimal changes (it just consumes a different payload struct). The rebuild zone is the ~2,500 lines between "raw astrology" and "UI payload" — and the replacement should be under 800 lines total.

---

*This report is a first-draft assessment. It's meant to be discussed, challenged, and refined before any code is written.*
