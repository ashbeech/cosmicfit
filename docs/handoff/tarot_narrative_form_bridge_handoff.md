# Daily Fit — Tarot Narrative Form Bridge (Silhouette / Structure Coherence)

**Date:** 2026-06-11  
**Status:** Ready for implementation  
**Audience:** Engineer or AI agent with codebase access — **no prior conversation context assumed**  
**Engine scope:** `stage1_experimental` (`DailyFitEngineMode.stage1Experimental`) ONLY  
**Triggered by:** Wren audit — King of Cups / The Diplomat copy contradicts Structured/Relaxed slider on the same Daily Fit screen

**Related docs:**

| Doc | Role |
|-----|------|
| [`daily_fit_narrative_tarot_bridge_handoff.md`](./daily_fit_narrative_tarot_bridge_handoff.md) | Parent: energy-only variant bridge (shipped) |
| [`daily_fit_narrative_layer_handoff.md`](./daily_fit_narrative_layer_handoff.md) | Plan 2: `DailyNarrativePlan` decides all surfaces before render |
| [`daily_fit_narrative_layer_phase_2_coherence_plan.md`](./daily_fit_narrative_layer_phase_2_coherence_plan.md) | Cross-surface coherence contract |
| [`tarot_recency_hard_block_handoff.md`](./tarot_recency_hard_block_handoff.md) | Tarot 3-day hard block (shipped) |
| [`dailyfit_production_audit_fix_handoff.md`](./dailyfit_production_audit_fix_handoff.md) | Broader production-readiness context |

**Fixture evidence (Ash export, 2026-06-11):**

- Daily fit: `cosmicfit_wren_dailyfit_2026-06-11_to_2026-06-24_14d.md`
- Trace: `cosmicfit_wren_trace_2026-06-11_to_2026-06-24_14d.md`
- Natal: `cosmicfit_wren_natal_2026-06-11_to_2026-06-24_14d.md`

---

## 0. Implementation handoff prompt (copy-paste)

```
Implement the Tarot Narrative Form Bridge per:

  docs/handoff/tarot_narrative_form_bridge_handoff.md

Read the full spec before coding. §5 (design), §6 (implementation), §8 (tests),
and §9 (acceptance) are hard gates.

## Mission

Stage-1 tarot selection already uses the narrative ENERGY story (essence categories →
tarotDirective.targetEnergyVector → variant energyEmphasis bridge). It does NOT use
the narrative FORM story (plan.targetSilhouette, structure slider, variant axesEmphasis).

Close that gap so the selected (card, variant) pair aligns with the same day's
silhouette targets — especially Structured/Relaxed — without adding new user-facing copy.

## Non-negotiable constraints

1. STAGE 1 ONLY — gate behind narrativeIntent != nil / generatePayloadFromPlan path.
   Production / legacy_baseline paths must remain byte-identical (ProductionFingerprintGuard).
2. ZERO NEW COPY — do not edit TarotCards.json descriptions.
3. Preserve existing energy bridge — extend, do not replace.
4. Preserve astro funnel — vibe + axis + transit − recency before bridge scoring.
5. Preserve tarot 3-day hard block (TarotRecencyTracker.getCooldownCards).
6. Deterministic — same plan + snapshot + seed + history → same (card, variant).
7. Thread new trace fields through inspector export (trace markdown only, not dailyfit UI).

## Required reading (in order)

1. This spec (primary)
2. Cosmic Fit/InterpretationEngine/NarrativeTarotBridgeSelector.swift
3. Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift (buildPlan → tarotDirective)
4. Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift (generatePayloadFromPlan, planToIntent)
5. Cosmic Fit/InterpretationEngine/DailyNarrativeCoherence.swift (scorePayloadCoherence)
6. Cosmic Fit/InterpretationEngine/TarotCard.swift (StyleEditVariant.axesEmphasis — deprecated StyleEditSelector used BOTH energy + axes)
7. Cosmic FitTests/NarrativeTarotBridge_Tests.swift

## Deliverables

1. Extended tarot directive + bridge scoring (energy + form)
2. Unit tests proving structure-aligned variant wins on high-structure days
3. Regression test on Wren 2026-06-11 (Diplomat must NOT win when structure extreme)
4. Inspector trace fields for form-bridge similarity
5. Sign-off fixture: docs/fixtures/tarot_form_bridge_signoff_YYYY-MM-DD.md

Run ProductionFingerprintGuard_Tests before AND after. Summarize files changed + Wren/Briar stats when done.
```

---

## 1. Executive summary

### 1.1 What works today

Stage-1 Daily Fit builds a `DailyNarrativePlan` **before** surfaces render. Tarot selection **does** consume part of that plan:

- Relationship (reinforce / stretch / soften / contrast)
- Accent + supporting essences → `TarotDirective.targetEnergyVector`
- Card-level narrative category boost
- Variant **energy** bridge (`variant.energyEmphasis` vs target vector)

This is the “narrative tarot bridge” shipped in May 2026.

### 1.2 What is broken

The same plan also assigns **form** targets the tarot path ignores:

| Plan field | Used by tarot? |
|------------|----------------|
| `targetSilhouette` (MF / AR / **SD**) | **No** |
| `targetVibrancy` / `targetContrast` / `targetMetalTone` | **No** |
| `variant.axesEmphasis` in `TarotCards.json` | **No** (bridge reads `energyEmphasis` only) |

Result: a day can show **Structured/Relaxed ≈ 0.07** (strongly structured) while tarot copy says *“soft-structured blazer… soft enough to engage with.”*

### 1.3 What this handoff delivers

Extend the tarot bridge with a **form axis** that scores `variant.axesEmphasis` against a **plan-derived target axes vector** (structure channelled through the existing `strategy` emphasis key and sky `DerivedAxes`).

Energy bridge stays. Form bridge adds. Combined pair score selects the variant.

---

## 2. Problem statement (concrete repro)

### 2.1 Profile

| Field | Value |
|-------|-------|
| Display name | Wren |
| Profile hash | `609730200.0_37.9855765_23.7283762` |
| Birth | 1989-04-28 04:30, Athens (37.99°N, 23.73°E) |
| Engine | `stage1_experimental` |
| Device location (transits) | UK (~53.91°N, -0.17°W) |

### 2.2 Repro day: 2026-06-11 (from Ash export)

**Selected:** King of Cups / **The Diplomat** (variant index 1)

**Silhouette (same payload):**

| Axis | Value | Meaning |
|------|-------|---------|
| Structured / Relaxed | **0.073** | Strongly **structured** (0 = structured, 1 = relaxed) |
| Masculine / Feminine | 0.559 | Slight feminine |
| Angular / Rounded | 0.607 | Slight rounded |

**Sky axes:**

| Axis | Value |
|------|-------|
| Strategy (Structure) | **7.22** |
| Action | 8.18 |
| Tempo | 7.16 |
| Visibility | 6.88 |

**Narrative plan (trace):**

| Field | Value |
|-------|-------|
| Relationship | contrast |
| Accent | romantic |
| Weather top-3 (tarot target) | romantic, classic, maximalist |
| Anchor top-3 | classic, polished, romantic |

**Diplomat variant metadata (`TarotCards.json`):**

```json
"axesEmphasis": { "action": 9, "tempo": 7, "visibility": 18, "strategy": 21 }
```

`strategy: 21` = low structure emphasis in variant scoring space (0–100).

**Diplomat copy (unchangeable):** references *“soft-structured blazer”* and *“soft enough to engage with.”*

### 2.3 Why it was selected anyway

From trace `wren_trace_2026-06-11_to_2026-06-24_14d.md`:

1. **Not top astro card.** Base scorers: Judgement (1.140), The World (1.131), Three of Wands (1.128) — King of Cups **not in top 10**.
2. **Won energy bridge.** `variantBridgeSimilarity: 1.185`, `bridgeMargin: +0.022` — Diplomat’s `energyEmphasis` (classic 0.94, romantic 0.57) matched contrast-day tarot energy target.
3. **Form ignored.** `structuredDraped: 0.073` and `strategy: 21` never compared.

### 2.4 User-visible failure mode

On one screen the user sees:

- Essence triangle: romantic / classic / magnetic (plan-driven)
- Silhouette slider: pinned **Structured**
- Tarot card copy: **soft-structure** language

This is a **cross-surface narrative contradiction** — exactly what Plan 2 coherence was meant to prevent, but `DailyNarrativeCoherence.tarotMatch` only checks **energy**, not **form**.

---

## 3. Architecture context (read this first)

### 3.1 Pipeline order (stage-1)

```
DailyEnergyEngine.generateSnapshot()
    ↓
BlueprintLensEngine.resolveEssenceProfile()
BlueprintLensEngine.deriveSilhouetteProfile()   ← uses sky axes.strategy → structuredDraped
    ↓
DailyNarrativeSelector.select() → DailyNarrativePlan
    │   targetSilhouette = precomputedSilhouette   (line ~612)
    │   tarotDirective = targetEnergyVector only   (line ~636–657)
    ↓
BlueprintLensEngine.generatePayloadFromPlan()
    │   planToIntent(plan) → NarrativeIntent        (silhouette NOT passed)
    │   selectTarotAndStyleEditWithBridgeTrace()
    │       → NarrativeTarotBridgeSelector.select()
    ↓
DailyFitPayload (UI)
```

### 3.2 Current bridge formula

```swift
// NarrativeTarotBridgeSelector — Stage B
variantVector = energyDictionary(variant.energyEmphasis)
bridgeScore = cosineSimilarity(variantVector, intent.tarot.targetEnergyVector)

pairTotalScore = baseCardScore + variantBridgeWeight * bridgeScore
// variantBridgeWeight = 0.25 (stage1Default)
```

### 3.3 What card-level scoring already uses

`TarotCardScoring.scoreCard()` blends:

- `card.energyAffinity` vs vibe vector (50% / 40% stage1)
- `card.axesAffinity` vs **sky** `DerivedAxes` (35% / 30% stage1) — **not** `SilhouetteProfile`
- Transit boost, recency, narrative energy boost

So **card** selection partially sees sky Strategy axis, but **variant** selection does not see plan silhouette.

### 3.4 Historical precedent

`StyleEditSelector` (deprecated, not used in production) scored variants with **60% energy + 40% axes**:

```swift
// TarotCard.swift ~446–468 (deprecated)
return (energySimilarity * 0.6) + (axesSimilarity * 0.4)
```

The narrative bridge regressed to **energy-only** when shipped. This handoff restores axes scoring in a plan-aware way.

### 3.5 Coherence gap in validation

`DailyNarrativeCoherence.scorePayloadCoherence()`:

- `silhouetteMatch` — compares payload vs **plan** silhouette (passes when routing is faithful)
- `tarotMatch` — **energy only** (`plan.tarotDirective` vs `variant.energyEmphasis`)

No check that variant `axesEmphasis` aligns with `plan.targetSilhouette`.

---

## 4. Design decision

### 4.1 Options considered

| Option | Summary | Verdict |
|--------|---------|---------|
| **A. Extend `TarotDirective` with `targetAxesVector`** | Plan builds 4-axis target from silhouette + sky; bridge scores `variant.axesEmphasis` | **Recommended** |
| B. Pass full `DailyNarrativePlan` into bridge | Cleaner typing, bigger API change | Defer — use intent bridge |
| C. Keyword scan variant.description for “soft/structured” | Brittle, untestable | Reject |
| D. Edit Diplomat copy in TarotCards.json | Violates zero-new-copy / changes 78 cards | Reject |
| E. Hard gate: reject variants with strategy < threshold when SD < 0.15 | Too blunt; loses nuance | Use as **optional** coherence gate only |

### 4.2 Recommended approach: dual-channel bridge

**Channel 1 — Energy (unchanged):** `variant.energyEmphasis` vs `tarotDirective.targetEnergyVector`

**Channel 2 — Form (new):** `variant.axesEmphasis` vs `tarotDirective.targetAxesVector`

**Combined variant bridge:**

```swift
energySim = cosineSimilarity(energyDict(variant.energyEmphasis), targetEnergy)
axesSim     = cosineSimilarity(axesDict(variant.axesEmphasis), targetAxes)

bridgeScore = (1 - formBridgeWeight) * energySim + formBridgeWeight * axesSim
// OR additive: bridgeScore = energySim + formBridgeAxesWeight * axesSim
// Pick ONE formula in §6.2 — additive is closer to current architecture.
```

Prefer **additive decomposition** (matches existing `pairTotal = base + w_e * energySim + w_f * axesSim`) for traceability.

### 4.3 Target axes vector (plan-derived)

Build in `DailyNarrativeSelector.buildPlan()` when constructing `TarotDirective`:

| Key | Source | Notes |
|-----|--------|-------|
| `action` | `snapshot.axes.action / 10.0` | Sky-only, unchanged |
| `tempo` | `snapshot.axes.tempo / 10.0` | Sky-only |
| `visibility` | `snapshot.axes.visibility / 10.0` | Sky-only |
| `strategy` | **Blend** | Primary fix — see below |

**Strategy / structure blend** (maps silhouette → variant emphasis space):

```swift
let skyStrategy = snapshot.axes.strategy / 10.0          // 0–1
let silhouetteStructure = 1.0 - plan.targetSilhouette.structuredDraped  // 0=relaxed, 1=structured
let targetStrategy = clamp01(
    structureSkyWeight * skyStrategy
    + structureSilhouetteWeight * silhouetteStructure
)
// Proposed defaults: structureSkyWeight = 0.35, structureSilhouetteWeight = 0.65
// Tunable via NarrativeSelectionTuning
```

Rationale:

- `structuredDraped` is already computed from `sdBase + skyMod(snapshot.axes.strategy)` in stage-1 — feeding it back prevents the tarot layer from ignoring its own plan output.
- Variant `axesEmphasis.strategy` is 0–100 → normalize to 0–1 for cosine match.

**MF / AR:** Variant JSON has no masculineFeminine or angularRounded emphasis. Do **not** block on MF/AR in v1. Optional Phase 2: card-level `axesAffinity` already partially covers this at funnel stage.

### 4.4 Expected outcome on Wren 2026-06-11

With form bridge weighted meaningfully:

- Diplomat (`strategy: 21` → 0.21) should lose to variants with high `strategy` emphasis (e.g. Emperor variants ~80+, Chariot/Strength variants) **when** `silhouetteStructure ≈ 0.93`.
- King of Cups may still win on **energy** — but a **different variant** (e.g. The Anchor, strategy 21 vs The Healer strategy 28) or a different card entirely should rise.
- **Acceptance:** no selected variant with `axesEmphasis.strategy < 50` when `structuredDraped < 0.15` (hard coherence gate — §9).

---

## 5. Implementation specification

### 5.1 Types (`DailyFitTypes.swift`)

Extend `TarotDirective`:

```swift
struct TarotDirective: Equatable, Codable {
    let targetEnergyVector: [Energy: Double]
    /// Normalized 0–1 targets for action/tempo/strategy/visibility.
    /// `strategy` incorporates plan.targetSilhouette.structuredDraped.
    let targetAxesVector: [String: Double]
}
```

Add to `NarrativeSelectionTuning`:

```swift
let variantFormBridgeWeight: Double      // default 0.20 (start conservative)
let structureSkyWeight: Double             // default 0.35
let structureSilhouetteWeight: Double      // default 0.65
let minFormBridgeSimilarity: Double        // default 0.45 (trace gate)
let structureVariantStrategyFloor: Int     // default 50 — gate when SD < 0.15
let structureSliderThreshold: Double       // default 0.15 — "decisively structured"
```

Bump fingerprint via `DailyFitEngineRegistry` if tuning is part of stage1 preset.

### 5.2 Plan builder (`DailyNarrativeSelector.swift`)

In `buildPlan()`, after `targetSilhouette` is known:

```swift
let targetAxes = NarrativeSelectionDirectives.targetAxesVector(
    snapshot: snapshot,
    silhouette: precomputedSilhouette,  // same as targetSilhouette
    tuning: tuning
)
let tarotDirective = TarotDirective(
    targetEnergyVector: tarotVector,
    targetAxesVector: targetAxes
)
```

Add helper to `NarrativeSelectionDirectives.swift`:

```swift
static func targetAxesVector(
    snapshot: DailyEnergySnapshot,
    silhouette: SilhouetteProfile,
    tuning: NarrativeSelectionTuning
) -> [String: Double]

static func axesDictionary(from emphasis: [String: Int]) -> [String: Double]
// Normalize Int 0–100 → Double 0–1, keys: action, tempo, strategy, visibility
```

### 5.3 Bridge selector (`NarrativeTarotBridgeSelector.swift`)

For each (card, variant) pair:

```swift
let energySim = cosineSimilarity(energyDict(variant.energyEmphasis), targetEnergy)
let axesSim   = cosineSimilarity(axesDict(variant.axesEmphasis), targetAxes)

let bridgeScore = energySim  // keep raw energy sim for trace
let formScore   = axesSim

let pairTotal = entry.baseScore
    + tuning.variantBridgeWeight * energySim
    + tuning.variantFormBridgeWeight * axesSim
```

Extend `Candidate` and `NarrativeBridgeTrace`:

```swift
// Candidate
let variantFormBridgeScore: Double

// NarrativeBridgeTrace (new fields)
let variantFormBridgeSimilarity: Double?
let formBridgePass: Bool?
let combinedBridgeSimilarity: Double?  // optional weighted combo for dashboards
```

Update `bridgePass`:

```swift
bridgePass = energySim >= minVariantBridgeSimilarity
          && axesSim >= minFormBridgeSimilarity
          && margin >= minBridgeMargin
```

Phase 1: `formBridgePass` traced, does **not** fail `overallPass`.  
Phase 2: enable after Wren + Briar sign-off (mirror energy bridge rollout).

### 5.4 Intent bridge (`BlueprintLensEngine.planToIntent`)

`NarrativeIntent.tarot` already carries `TarotDirective` — no structural change once `TarotDirective` is extended. Verify all `TarotDirective(` call sites construct both vectors.

**Fallback for nil legacy intents:** `targetAxesVector` from snapshot axes only (production path unaffected).

### 5.5 Coherence (`DailyNarrativeCoherence.swift`)

Extend `scorePayloadCoherence()`:

```swift
let tarotEnergyMatch = cosineSimilarity(plan.tarot.targetEnergyVector, variantEnergy) > 0.5
let tarotFormMatch   = cosineSimilarity(plan.tarot.targetAxesVector, variantAxes) > 0.5
let tarotMatch = tarotEnergyMatch && tarotFormMatch ? 1.0 : 0.0
```

Add `validateTarotForm(plan:payload:)` to `validate()` cross-surface checks:

```swift
if plan.targetSilhouette.structuredDraped < tuning.structureSliderThreshold {
    let strat = payload.styleEditVariant.axesEmphasis["strategy"] ?? 50
    if strat < tuning.structureVariantStrategyFloor {
        violations.append("tarot variant strategy \(strat) contradicts structure slider \(plan.targetSilhouette.structuredDraped)")
    }
}
```

**Note:** This is a **post-selection validator**. The bridge fix should prevent violations; the gate catches regressions.

### 5.6 Diagnostics / inspector trace

Extend trace markdown section `### Narrative bridge`:

```markdown
- Energy similarity: 1.185
- **Form similarity: 0.412**        ← NEW
- **Form bridge pass: false**         ← NEW
- Selected: …
```

JSON: add fields to `narrativeBridgeTrace` in `DailyFitDiagnosticReport`.

### 5.7 Files to touch (expected)

| File | Change |
|------|--------|
| `DailyFitTypes.swift` | `TarotDirective`, `NarrativeSelectionTuning`, `NarrativeBridgeTrace`, `Candidate` |
| `NarrativeSelectionDirectives.swift` | `targetAxesVector`, `axesDictionary`, coherence trace |
| `DailyNarrativeSelector.swift` | Emit `targetAxesVector` in `buildPlan` |
| `NarrativeTarotBridgeSelector.swift` | Dual-channel scoring + trace |
| `DailyNarrativeCoherence.swift` | Form-aware tarotMatch + optional gate |
| `NarrativeIntentEngine.swift` | Legacy `TarotDirective` construction if any |
| `DailyFitEngineRegistry.swift` | Fingerprint bump if tuning changes |
| `Cosmic FitTests/NarrativeTarotBridge_Tests.swift` | New form-bridge tests |
| `Cosmic FitTests/NarrativeCoherence_Tests.swift` | Structure contradiction gate |
| `Cosmic FitTests/ProductionFingerprintGuard_Tests.swift` | Re-baseline stage1 only |
| Inspector trace renderer | If separate from diagnostics auto-export |

**Do NOT modify:** `TarotCards.json`, production preset payloads, `DailyFitViewController` UI strings.

---

## 6. Tuning & rollout

### 6.1 Suggested starting weights

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `variantBridgeWeight` | 0.25 | Keep (energy) |
| `variantFormBridgeWeight` | **0.20** | Conservative; form should matter but not swamp energy |
| `structureSilhouetteWeight` | **0.65** | Slider is the user-visible structure signal |
| `structureSkyWeight` | **0.35** | Sky strategy already feeds silhouette |
| `minFormBridgeSimilarity` | 0.45 | Trace-only initially |
| `structureVariantStrategyFloor` | 50 | When `structuredDraped < 0.15` |

### 6.2 Tuning protocol

1. Export Wren 14-day (`2026-06-11` → `2026-06-24`) with new trace fields.
2. Export Briar 14-day (existing harness).
3. Count days where `structuredDraped < 0.15` AND selected variant `strategy < 50` — target **0** after fix.
4. Count days where form bridge changes card or variant vs energy-only replay — document in sign-off.
5. Manual read: 3 high-structure days + 3 high-relaxed days — copy should match slider extremity.

Write: `docs/fixtures/tarot_form_bridge_signoff_YYYY-MM-DD.md`

### 6.3 Phase 2 enforcement (after sign-off)

- `formBridgePass` contributes to `NarrativeCoherenceTrace.overallPass`
- `DailyNarrativeCoherence.validate()` structure gate is **hard** (plan rejection) if feasible without collapsing candidate pool — otherwise post-selection fail in trace only

---

## 7. Test plan

### 7.1 New unit tests (`NarrativeTarotBridge_Tests.swift`)

| Test | Assertion |
|------|-----------|
| `formBridge_highStructure_prefersHighStrategyVariant` | Synthetic plan: `structuredDraped = 0.05`. Same card, variant A `strategy: 20`, variant B `strategy: 85` → B wins pair total |
| `formBridge_lowStructure_prefersLowStrategyVariant` | `structuredDraped = 0.90` → inverse |
| `formBridge_canChangeWinningCard` | Two cards in funnel; lower energy card wins on form axis |
| `formBridge_nilAxes_emphasis_empty_safe` | Missing keys → 0 contribution, no crash |
| `productionPath_unchanged` | `narrativeIntent == nil` → identical selection as before |

### 7.2 Coherence tests (`NarrativeCoherence_Tests.swift`)

| Test | Assertion |
|------|-----------|
| `structureGate_flagsDiplomatOnStructuredDay` | Wren-like plan + Diplomat variant → violation |
| `structureGate_silentOnRelaxedDay` | `structuredDraped = 0.8` → no violation |

### 7.3 Golden / regression

| Profile | Date | Before | After (expected) |
|---------|------|--------|------------------|
| Wren | 2026-06-11 | King of Cups / Diplomat | **Not** Diplomat if structure gate active; higher-strategy variant or card |
| Briar | 14-day | Baseline in sign-off | Document card/variant deltas ≤ 30% of days |

### 7.4 Commands

```bash
xcodebuild test -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:"Cosmic FitTests/NarrativeTarotBridge_Tests" \
  -only-testing:"Cosmic FitTests/NarrativeCoherence_Tests" \
  -only-testing:"Cosmic FitTests/ProductionFingerprintGuard_Tests"
```

Rebuild inspector: `cd inspector && ./run-inspector.sh`

---

## 8. Acceptance criteria

### 8.1 Phase 1 (merge)

- [ ] `TarotDirective` includes `targetAxesVector`; all stage-1 plan paths populate it
- [ ] Bridge pair score uses energy + form weights; trace exports both similarities
- [ ] `ProductionFingerprintGuard_Tests` green — **production preset byte-identical**
- [ ] New unit tests green (§7.1–7.2)
- [ ] Wren 2026-06-11: `variantFormBridgeSimilarity` logged; Diplomat no longer wins pair total OR variant index changes to higher-strategy sibling on same card
- [ ] Zero edits to `TarotCards.json`
- [ ] Sign-off fixture written

### 8.2 Phase 2 (Ash sign-off)

- [ ] Wren 14-day: **0** days with `structuredDraped < 0.15` and variant `strategy < 50`
- [ ] Briar 14-day: manual read — no egregious form contradictions on structure-extreme days
- [ ] `formBridgePass` wired into `overallPass` (optional hard gate)

---

## 9. Non-goals (explicit)

- Editing tarot copy text
- MF / AR variant matching (JSON lacks fields — future metadata enrichment)
- Production (`legacy_baseline`) behaviour changes
- Vibrancy / contrast / metal tone in tarot bridge (palette/scales already plan-driven)
- Re-litigating energy bridge weights (unless tuning requires minor rebalance)

---

## 10. Inspector vs app parity (FAQ for implementer)

Ash asked why inspector exports differ from the iOS app. **Same engine code**; **different state**:

| Factor | Inspector | iOS app |
|--------|-----------|---------|
| Tarot recency storage | `UserDefaults` suite `com.cosmicfit.inspector` | App `UserDefaults` |
| Variant rotation | Inspector suite | App storage |
| Visible essence cooldown | `VisibleEssenceRecencyTracker` — **not** re-pointed to inspector suite in bootstrap | App history |
| Accent recency | Standard defaults per process | App history |
| Multi-day export | Sequential — each day mutates trackers for the next | App has unrelated prior history |

**Does not differ:** ephemeris, natal chart, blueprint composition, calibration fingerprint, scoring formulas.

When validating this fix, use a **sequential 14-day inspector export** starting `2026-06-11` (Ash's window) with `resetTarotHistory: true` on day 1 only — matching the attached fixtures' methodology.

---

## 11. Appendix — Wren 2026-06-11 trace snapshot

```
Selected:     King of Cups / The Diplomat
structuredDraped: 0.073
sky strategy:     7.22
Relationship:     contrast
Weather top-3:    romantic, classic, maximalist

Base astro top-3: Judgement, The World, Three of Wands
Bridge margin:    +0.022
Energy sim:       1.185
Form sim:         (not computed today — implement)

Diplomat axesEmphasis.strategy: 21
Diplomat energyEmphasis.classic: 0.94
Diplomat energyEmphasis.romantic: 0.57
```

**Interpretation:** Energy bridge did its job. Form bridge was never invoked. This handoff adds the missing channel.

---

## 12. Definition of done (summary)

1. Tarot variant selection uses **both** narrative energy **and** narrative form (silhouette → strategy emphasis).
2. High-structure days prefer high-`strategy` variants; contradiction rate → 0 on Wren audit window.
3. Traces prove energy vs form contributions per day.
4. Production untouched; stage-1 fingerprint re-baselined with documented rationale.
5. Sign-off fixture committed.

---

*End of handoff.*
