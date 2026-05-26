# Daily Fit — Narrative Tarot Bridge (Stage 1 Experimental)

**Status:** Ready for implementation  
**Date:** 2026-05-23  
**Audience:** Engineer or AI agent with codebase access  
**Origin:** Product owner (Ash) — narrative cohesion must come from **existing tarot style-edit copy**, not new user-facing strings.

**Related docs:**

| Doc | Role |
|-----|------|
| [`daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](./daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md) | Parent spec: anchor/weather classification, palette/scales bias, no new copy |
| [`daily_fit_stage1_experimental_app_readiness_handoff.md`](./daily_fit_stage1_experimental_app_readiness_handoff.md) | App/inspector parity, Briar validation |
| [`docs/fixtures/narrative_unification_signoff_2026-05-23.md`](../fixtures/narrative_unification_signoff_2026-05-23.md) | Latest Briar narrative closure record |

---

## 0. Implementation handoff prompt (copy-paste)

Give the block below verbatim to an engineer or AI agent at the start of the task. The spec body (§1–§14) is the authoritative design; this prompt governs *how* to execute it.

---

```
Implement the Daily Fit Narrative Tarot Bridge feature per the spec in:

  docs/handoff/daily_fit_narrative_tarot_bridge_handoff.md

Read that document in full before writing code. Treat §5 (implementation spec),
§7 (production safety), §8 (tests), §9 (checklist), and §10 (acceptance criteria)
as hard gates — not suggestions.

## Mission

Make the existing tarot style-edit variant the narrative bridge for Stage 1 experimental
days. The user reads variant.description / dailyRitual / wardrobeReflection from
TarotCards.json — that copy must be selected as the best (card, variant) pair for the
day's resolved anchor/weather relationship. Do NOT add new user-facing strings.

Architecture: astrology builds the eligible tarot shortlist; narrative intent picks the
best existing copy inside that shortlist. Not a full narrative override of tarot.

## Non-negotiable constraints

1. STAGE 1 ONLY — bridge selector runs when narrativeIntent != nil (already gated to
   stage1Experimental + chart anchor). Production / Release paths must be byte-identical.
2. ZERO NEW COPY — no Daily Brief, theme headings, bridging sentences, or app UI labels.
3. DO NOT modify TarotCards.json content.
4. DO NOT change NarrativeIntentEngine classification rules unless you find a bug.
5. DO NOT change palette/scales/essence bias logic except where required to thread
   bridge trace through diagnostics.
6. Joint (card, variant) selection — variant scoring must NOT run only after card lock-in.
7. Astro funnel is mandatory — vibe + axis + transit − recency still filter candidates
   before bridge scoring. Never skip recency or transit.
8. Single source of truth — one selector used by both selectTarotAndStyleEdit and
   generatePayloadWithTrace (today these duplicate tarot scoring; dedupe them).
9. All Stage-1 narrative tests must use DailyFitPipeline.generate / generateWithTrace,
   not raw BlueprintLensEngine alone.
10. Run ProductionFingerprintGuard_Tests before AND after — must stay green.

## Required reading (in order, before coding)

1. docs/handoff/daily_fit_narrative_tarot_bridge_handoff.md (this spec — primary)
2. docs/handoff/daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md (parent context)
3. Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift — intent resolved before Stage 2
4. Cosmic Fit/InterpretationEngine/NarrativeIntentEngine.swift — targetEnergyVector rules
5. Cosmic Fit/InterpretationEngine/NarrativeSelectionDirectives.swift — cosine helpers, coherence
6. Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift — selectTarotAndStyleEdit,
   selectVariant, generatePayloadWithTrace (duplicated tarot loop ~457–540)
7. Cosmic FitTests/NarrativeTarotUnification_Tests.swift
8. Cosmic FitTests/NarrativeCoherence_Tests.swift
9. Cosmic FitTests/ProductionFingerprintGuard_Tests.swift

## Deliver in five steps — do not skip tests between steps

### Step 1 — Extract (no behaviour change yet)

- [ ] NEW NarrativeTarotBridgeSelector.swift — types + stub
- [ ] Extract shared scoreBaseCard(...) from BlueprintLensEngine
- [ ] Confirm nil-intent path still matches existing card ordering

Stop and run: ProductionFingerprintGuard_Tests, NarrativeTarotUnification_Tests.

### Step 2 — Joint selection (Stage-1 behaviour change)

- [ ] Implement Stage A astro funnel (top bridgeCandidatePoolSize cards)
- [ ] Implement Stage B variant bridge scoring + relationship modifiers
- [ ] Implement Stage C pairTotalScore selection + tie-break
- [ ] Branch selectTarotAndStyleEdit when narrativeIntent != nil
- [ ] Unify generatePayloadWithTrace tarot path with same selector
- [ ] Preserve soften min-drama rule and contrast 1.2× variant boost per spec §5.3

Stop and run: NarrativeTarotBridge_Tests (new), NarrativeTarotUnification_Tests,
ProductionFingerprintGuard_Tests.

### Step 3 — Trace export (Phase 1: trace only)

- [ ] NEW NarrativeBridgeTrace on PayloadTrace + DailyFitDiagnosticReport
- [ ] Extend NarrativeCoherenceTrace with variantBridgeSimilarity, bridgePass
- [ ] Inspector trace markdown: ### Narrative bridge (trace export ONLY — not dailyfit UI)
- [ ] Phase 1: bridgePass traced but does NOT fail overallPass yet

Stop and run full Cosmic FitTests. Rebuild inspector: cd inspector && ./run-inspector.sh

### Step 4 — Tune from exports

- [ ] Briar 14-day via SkyForwardV2Support / inspector export
- [ ] Write docs/fixtures/narrative_tarot_bridge_signoff_YYYY-MM-DD.md with:
      templateKey → card/variant → variantBridgeSimilarity → bridgePass per day
- [ ] Adjust variantBridgeWeight (start 0.25) and thresholds from real data
- [ ] Re-baseline DailyFitSkyForwardV2_Tests tarot expectations if joint selection shifts days
      (document rationale in signoff doc)

Contrast days to inspect: relationship == contrast AND overlapCount == 0.

### Step 5 — Enforce coherence (Phase 2 — only after Step 4 sign-off)

- [ ] Enable bridgePass in computeCoherenceTrace overallPass
- [ ] Briar 14-day: bridgePass >= 12/14 days
- [ ] Full test suite green

## Verification before calling done

1. ProductionFingerprintGuard_Tests — unchanged fingerprint / payloads.
2. Stage-1 Briar 14-day — every day has narrativeBridgeTrace with pairsEvaluated > 0.
3. jointSelectionCanBeatCardFirst test proves variant can change which card wins.
4. Inspector trace shows: variant similarity, pool best, pair margin, contrast weather wins.
5. Manual read on 2–3 contrast days: style-edit copy faces weather, not chart anchor alone.
6. No new strings in DailyFitViewController or dailyfit markdown export.
7. Sign-off fixture written with tuning notes and any re-baselined golden days.

## Code quality standards

- Match InterpretationEngine conventions (enum namespace, private static helpers, no print()).
- Minimal diff — do not refactor unrelated BlueprintLensEngine sections.
- Comments only for non-obvious bridge logic (soften min-drama, two-stage funnel).
- New trace types: Codable + Equatable.
- Deterministic: same inputs + seed + tarot history → same (card, variant).
- If tarot golden tests change, explain WHY in signoff doc (bridge beat card-first).

## Definition of done

All §10 acceptance criteria checked (Phase 1 minimum for merge; Phase 2 before Ash sign-off),
all §8 tests implemented and green, Steps 1–3 complete, Step 4 sign-off doc written,
ProductionFingerprintGuard_Tests green, inspector bridge trace visible.

Summarize when finished:
- Files changed
- Test counts added/updated
- Briar 14-day bridge stats (mean similarity, pass rate, days that changed card/variant)
- variantBridgeWeight and thresholds chosen
- Any deferred items (Wren variety, Phase 2 enforcement)
```

---

## 1. Executive summary

### 1.1 Problem

Narrative unification v1.1 resolved chart anchor vs sky weather in the engine and biased tarot, palette, essence presentation, and scales. However, tarot selection still works like this:

1. Pick a **card** using vibe + axis + transit − recency (+ small narrative card boost)
2. Then pick the best **style-edit variant** for that card only

The user reads the **style-edit variant** (`description`, `dailyRitual`, `wardrobeReflection`) — not the card name alone. On contrast days (e.g. `contrast.drama.minimal`), the engine knows the relationship but the selected existing copy may not feel like one intentional outfit story because the bridge variant was never allowed to influence which card won.

Auditors describe this as needing a “bridging line.” **Ash does not want new copy.** The bridge must be the **best-matching existing style-edit variant** from `TarotCards.json`.

### 1.2 Solution (one sentence)

**Stage 1 experimental only:** astrology builds an eligible tarot shortlist; narrative intent picks the best **(card, variant) pair** within that shortlist; trace exports objective bridge quality for QA tuning.

### 1.3 Design principle (read first)

| Layer | Role |
|-------|------|
| **Astro funnel** | Vibe, axis, transit, recency keep tarot honest and grounded in the day’s sky |
| **Narrative bridge** | Among eligible cards, the style-edit variant whose `energyEmphasis` best matches `intent.tarot.targetEnergyVector` wins |
| **Existing copy** | The selected variant’s JSON text is the product voice — zero new strings |

Do **not** let narrative bridge weight override astro so strongly that tarot feels random or disconnected from transits.

### 1.4 Scope

| In scope | Out of scope |
|----------|--------------|
| `stage1_experimental` / `DailyFitEngineMode.stage1Experimental` | Production / Release engine paths |
| Joint (card, variant) selection when `narrativeIntent != nil` | Rewriting `TarotCards.json` |
| Bridge trace + coherence metrics (inspector QA) | New user-visible paragraphs, headings, captions |
| Calibration tunables for bridge weights/thresholds | Silhouette, textures, pattern unification |
| Tests: Briar (+ Linden/Wren when fixtures exist) | Merging Stage 1 into production |

---

## 2. Definition of success

### 2.1 Product success (subjective, Ash sign-off)

On a Stage 1 day, the user reads only existing UI and feels:

- Tarot style-edit paragraph = today’s styling move
- Palette + essence triangle + scales agree with that move
- On contrast days: copy faces **weather** (today’s adapt signal), not chart anchor alone

No generated “Daily Brief,” theme headings, or bridging sentences.

### 2.2 Engineering success (objective)

For each Stage 1 day with `narrativeIntent != nil`:

1. Selected pair `(tarotCard, styleEditVariant)` came from **joint scoring** inside the astro funnel
2. `variantBridgeSimilarity = cosineSimilarity(variant.energyEmphasis, intent.tarot.targetEnergyVector)` is exported in trace
3. Selected pair is the highest `pairTotalScore` among all pairs in the candidate pool (deterministic tie-break)
4. `ProductionFingerprintGuard_Tests` remain green — production payloads bit-identical when `narrativeIntent == nil`
5. After threshold tuning: `NarrativeCoherenceTrace.overallPass == true` on Briar 14-day window

### 2.3 What “bridge” means in code

```text
NarrativeIntentEngine.resolve()
  → relationship, anchorTop3, weatherTop3, intent.tarot.targetEnergyVector

NarrativeTarotBridgeSelector.select()
  → (card, variant) where variant.energyEmphasis ≈ targetEnergyVector
  → user reads variant.description (existing JSON)

Palette / scales / essence presentation
  → already biased by same intent (unchanged in this spec)
```

---

## 3. Current architecture (baseline)

```text
DailyFitPipeline.generateWithTrace()
  ↓
resolveEssenceProfile()
  ↓
NarrativeIntentEngine.resolve()          → NarrativeIntent + NarrativeTrace
  ↓
BlueprintLensEngine.generatePayloadWithTrace(..., narrativeIntent:)
  ↓
selectTarotAndStyleEdit()
  ├── score all cards (vibe + axis + transit − recency + small card boost)
  ├── pick winning card
  └── selectVariant(for: card)           → best variant ON THAT CARD ONLY
  ↓
selectDailyPalette / deriveVibrancy / deriveContrast (biased)
  ↓
NarrativeSelectionDirectives.computeCoherenceTrace()
  └── tarotVariantWasScored == true      → weak gate (boolean only)
```

### 3.1 Key files today

| File | Role |
|------|------|
| `Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift` | Resolves intent before Stage 2; passes `narrativeIntent` |
| `Cosmic Fit/InterpretationEngine/NarrativeIntentEngine.swift` | Classification + `TarotDirective.targetEnergyVector` |
| `Cosmic Fit/InterpretationEngine/NarrativeSelectionDirectives.swift` | Energy vectors, palette bias, coherence heuristic |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | `selectTarotAndStyleEdit`, `selectVariant`, tarot scoring |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | `NarrativeCoherenceTrace`, `NarrativeSelectionTuning` |
| `Cosmic Fit/Resources/TarotCards.json` | 78 cards × 3 variants; `energyEmphasis` per variant |
| `Cosmic FitTests/NarrativeTarotUnification_Tests.swift` | Stage-1 variant scored; production rotation |
| `Cosmic FitTests/NarrativeCoherence_Tests.swift` | Briar relationship + coherence |
| `Cosmic FitTests/ProductionFingerprintGuard_Tests.swift` | Production must not change |

### 3.2 Existing target energy vectors (do not break)

From `NarrativeIntentEngine.buildIntent()`:

| Relationship | `intent.tarot.targetEnergyVector` |
|--------------|-----------------------------------|
| `reinforce` | 50/50 blend of anchor top-3 and weather top-3 category rows |
| `stretch` | Weather top-3 only |
| `contrast` | Weather top-3 only |
| `soften` | Weather top-3 × 0.7 scale factor |

Category → energy rows: `BlueprintLensEngine.essenceCategoryWeights(for:)`.  
Helpers: `NarrativeSelectionDirectives.targetEnergyVector`, `blendedReinforceVector`, `cosineSimilarity`, `energyDictionary`.

### 3.3 Known gap (example)

Briar 2026-05-23 export (contrast day):

- Anchor top-3: drama, maximalist, edgy  
- Weather top-3: minimal, sensual, polished  
- Template key: `contrast.drama.minimal`  
- Selected: Queen of Swords / **The Editor**  

Coherence trace passes (`tarotVariantWasScored == true`) because variant scoring ran — but card was locked before variant could compete across the deck. The Editor’s `energyEmphasis` is classic-heavy; a better bridge pair may exist elsewhere in the top-15 astro funnel.

---

## 4. Target architecture

```text
DailyFitPipeline.generateWithTrace()
  ↓
NarrativeIntentEngine.resolve()
  ↓
BlueprintLensEngine.generatePayloadWithTrace(..., narrativeIntent:)
  ↓
selectTarotAndStyleEdit()
  ├── if narrativeIntent == nil → EXISTING PATH (unchanged)
  └── if narrativeIntent != nil → NarrativeTarotBridgeSelector.select()
        Stage A: score all cards → astro funnel (top N)
        Stage B: for each card in funnel, score all styleEdits
        Stage C: pick best (card, variant) pair by pairTotalScore
  ↓
palette / scales (unchanged narrative bias)
  ↓
computeCoherenceTrace() + NarrativeBridgeTrace
```

**No circular dependency:** Intent is computed once from essence; bridge selector consumes intent; never re-score essence from tarot.

---

## 5. Implementation spec

### 5.1 New module: `NarrativeTarotBridgeSelector.swift`

Create `Cosmic Fit/InterpretationEngine/NarrativeTarotBridgeSelector.swift`.

```swift
enum NarrativeTarotBridgeSelector {

    struct Candidate: Equatable {
        let card: TarotCard
        let variant: StyleEditVariant
        let variantIndex: Int
        let baseCardScore: Double
        let variantBridgeScore: Double
        let pairTotalScore: Double
    }

    struct SelectionResult: Equatable {
        let candidate: Candidate
        let bridgeTrace: NarrativeBridgeTrace
        let funnelCardCount: Int
        let pairsEvaluated: Int
    }

    static func select(
        snapshot: DailyEnergySnapshot,
        allCards: [(card: TarotCard, normAxes: [String: Double])],
        recentSelections: [String],
        intent: NarrativeIntent,
        calibration: DailyFitCalibration,
        dailySeed: Int
    ) -> SelectionResult
}
```

Place next to `NarrativeSelectionDirectives.swift`. Keep `BlueprintLensEngine` as orchestrator; delegate Stage-1 narrative path to this selector.

### 5.2 Stage A — Astro funnel (unchanged formula)

For each card, compute **base card score** using the **existing** formula in `selectTarotAndStyleEdit` / `generatePayloadWithTrace`:

```swift
baseCardScore =
    vibeScore * weights.vibeWeight
  + axisScore * weights.axisWeight
  + transitBoost * weights.transitBoost
  - recencyPenalty
```

Optional: keep existing small card-level narrative boost (`categoryBoostWeight`) in Stage A — it is astro-adjacent and already shipped. Do **not** remove recency or transit from the funnel.

Sort descending. Take top **`bridgeCandidatePoolSize`** cards (default **15**).  
If fewer than 15 cards exist, use all.

Cards with empty `styleEdits` still enter the funnel but can only contribute a fallback variant (see §5.5).

### 5.3 Stage B — Variant bridge scoring

For each card in the funnel, for each `styleEdit` at index `i`:

```swift
let variantVector = NarrativeSelectionDirectives.energyDictionary(from: edit.energyEmphasis)
var variantBridgeScore = NarrativeSelectionDirectives.cosineSimilarity(
    variantVector,
    intent.tarot.targetEnergyVector
)
```

**Relationship modifiers on variant score:**

| Relationship | Rule |
|--------------|------|
| `contrast` | `variantBridgeScore *= 1.2` (weather-facing emphasis) |
| `soften` | After scoring all variants for a card, if choosing among top-3 variant scores, prefer minimum `energyEmphasis["drama"] ?? 0.5` (preserve existing soften behaviour from `selectVariant`) |
| `reinforce`, `stretch` | No extra multiplier |

**Contrast alignment check (for trace QA, optional gate in Phase 2):**

```swift
let weatherVec = NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: intent.weatherTop3)
let anchorVec  = NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: intent.anchorTop3)
let weatherAlignment = cosineSimilarity(variantVector, weatherVec)
let anchorAlignment  = cosineSimilarity(variantVector, anchorVec)
let contrastWeatherWins = weatherAlignment >= anchorAlignment
```

Export `contrastWeatherWins` on contrast days. Do **not** hard-fail coherence on this until tuned from exports.

### 5.4 Stage C — Pair total score

```swift
pairTotalScore = baseCardScore + tuning.variantBridgeWeight * variantBridgeScore
```

| Tunable | Default | Notes |
|---------|---------|-------|
| `variantBridgeWeight` | **0.25** | Start conservative; tune from Briar/Linden/Wren exports |
| `bridgeCandidatePoolSize` | **15** | Matches existing top-10 trace + headroom |
| `categoryBoostWeight` | **0.15** | Keep existing; applied in Stage A only |

**Tuning guidance:**

- If bridges feel weak but astro-good: raise `variantBridgeWeight` toward **0.35**
- If tarot feels disconnected from transits: lower `variantBridgeWeight` toward **0.15**
- Never zero out Stage A — astro funnel is mandatory

### 5.5 Selection and tie-break

1. Collect all `(card, variant)` pairs from funnel cards that have non-empty `styleEdits`
2. Sort by `pairTotalScore` descending
3. Tie-break: if top two within **`pairScoreTieEpsilon` (0.01)**, pick using `dailySeed % 2` among tied top pairs (mirror existing card tie-break)
4. Record selected card in `TarotRecencyTracker` (same as today)
5. Cards with no `styleEdits`: fallback to existing minimal `StyleEditVariant` constructor; `variantBridgeScore = 0`; mark `bridgePass = false`

### 5.6 Wire into `BlueprintLensEngine`

**`selectTarotAndStyleEdit`** — add branch at top:

```swift
if let intent = narrativeIntent, let tuning = calibration.narrativeSelection {
    let result = NarrativeTarotBridgeSelector.select(...)
    // store bridge trace on PayloadTrace (see §5.7)
    return (result.candidate.card, result.candidate.variant)
}
// existing path unchanged
```

**`generatePayloadWithTrace`** — replace duplicated inline tarot loop for Stage-1 narrative path with call to shared selector OR extract shared `scoreCardsForFunnel()` helper to avoid drift between `selectTarotAndStyleEdit` and trace path.

**Critical:** Both `generatePayload` and `generatePayloadWithTrace` must use the same selection logic (today trace duplicates scoring ~lines 457–540).

**`selectVariant`** — when called from narrative bridge path, selection is already done; do not re-score. Either:

- Return pre-selected variant from bridge result, or
- Pass `preselectedVariantIndex` to skip re-entry

Production / nil intent: `selectVariant` keeps rotation via `TarotVariantRotationTracker`.

### 5.7 Trace types

Add to `DailyFitTypes.swift`:

```swift
/// Inspector-only QA for tarot style-edit bridge quality (trace export).
struct NarrativeBridgeTrace: Codable, Equatable {
    let selectedCardName: String
    let selectedVariantTitle: String
    let selectedVariantIndex: Int
    let variantBridgeSimilarity: Double
    let bestPairTotalScore: Double
    let runnerUpPairTotalScore: Double
    let bridgeMargin: Double                    // best - runnerUp
    let bestVariantSimilarityInPool: Double       // max variantBridgeScore across all pairs evaluated
    let funnelCardCount: Int
    let pairsEvaluated: Int
    let contrastWeatherWins: Bool?              // non-nil only when relationship == contrast
    let bridgePass: Bool                        // see §5.8 Phase 1 vs Phase 2
}
```

Extend `BlueprintLensEngine.PayloadTrace`:

```swift
let narrativeBridgeTrace: NarrativeBridgeTrace?
```

Extend `NarrativeCoherenceTrace`:

```swift
let variantBridgeSimilarity: Double?
let bridgePass: Bool?
```

Keep `tarotVariantScored: Bool` for backwards compatibility (= bridge path used, not rotation fallback).

Extend `DailyFitDiagnosticReport` and inspector trace markdown (`inspector/.../Web/app.js`) with subsection:

```markdown
### Narrative bridge
- Selected: Queen of Swords / The Editor (variant index 0)
- Variant similarity: 0.71
- Best similarity in pool: 0.74
- Pair margin: 0.03
- Contrast weather wins: yes
- Bridge pass: pass
```

**Do not** add bridge fields to dailyfit user export / app UI.

### 5.8 Coherence gates — phased rollout

**Phase 1 (ship with refactor):** Trace only. `bridgePass` computed but **does not** fail `overallPass`.

```swift
bridgePass = variantBridgeSimilarity >= tuning.minVariantBridgeSimilarity
          && bridgeMargin >= tuning.minBridgeMargin
```

Initial defaults (expect tuning):

| Key | Initial default | Enforce in overallPass? |
|-----|-----------------|-------------------------|
| `minVariantBridgeSimilarity` | **0.50** | Phase 2 only |
| `minBridgeMargin` | **0.01** | Phase 2 only |

**Phase 2 (after Briar/Linden/Wren export review):** Add to `computeCoherenceTrace`:

```swift
pass = pass && (bridgePass ?? true)
```

Tune thresholds from real exports — tarot JSON energy granularity may not support aggressive floors on day one.

---

## 6. Calibration

Extend `DailyFitCalibration.NarrativeSelectionTuning`:

```swift
struct NarrativeSelectionTuning: Equatable {
    // existing
    let categoryBoostWeight: Double
    let rolePreferenceBonus: Double
    // ...

    // NEW — tarot bridge
    let variantBridgeWeight: Double
    let bridgeCandidatePoolSize: Int
    let minVariantBridgeSimilarity: Double
    let minBridgeMargin: Double
    let pairScoreTieEpsilon: Double
}
```

Suggested `stage1Default` additions:

```swift
variantBridgeWeight: 0.25,
bridgeCandidatePoolSize: 15,
minVariantBridgeSimilarity: 0.50,
minBridgeMargin: 0.01,
pairScoreTieEpsilon: 0.01,
```

Update `DailyFitEngineRegistry` fingerprint string for stage-1 preset.  
Production preset: `narrativeSelection: nil` → bridge path never runs.

---

## 7. Production safety

| Check | Requirement |
|-------|-------------|
| Gating | Bridge selector runs only when `narrativeIntent != nil` && `calibration.narrativeSelection != nil` |
| Mode | `NarrativeIntentEngine` already returns nil unless `mode == .stage1Experimental` && chart anchor exists |
| Production path | `selectTarotAndStyleEdit` with `narrativeIntent == nil` — **byte-identical behaviour** |
| Fingerprint | `ProductionFingerprintGuard_Tests` must pass before and after |
| Determinism | Same profile + date + engine id + tarot history → same pair |
| Recency | Still applied in Stage A; selected card stored in `TarotRecencyTracker` |
| JSON | Do not modify `TarotCards.json` |
| App UI | Do not add labels, captions, or bridging copy |

---

## 8. Tests

### 8.1 New suite: `NarrativeTarotBridge_Tests.swift`

| Test | Assertion |
|------|-----------|
| `stage1UsesBridgeSelector` | Stage-1 Briar day → `payloadTrace.narrativeBridgeTrace != nil` |
| `jointSelectionCanBeatCardFirst` | Construct/snapshot day where card A wins base score but card B variant has higher bridge score within funnel → B selected |
| `bridgeTracePopulated` | `variantBridgeSimilarity`, `pairsEvaluated`, `funnelCardCount` present and sane |
| `productionUnchanged` | Production engine → `narrativeBridgeTrace == nil`, rotation path, fingerprint guard green |
| `deterministicPair` | Same inputs twice → same card + variant |
| `softenPrefersLowDramaVariant` | Soften relationship → among top variant scores, lowest drama emphasis wins |

### 8.2 Extend existing suites

**`NarrativeTarotUnification_Tests.swift`**

- Replace boolean-only assertions with bridge trace presence
- Keep `tarotVariantScored == true` on Stage-1

**`NarrativeCoherence_Tests.swift`**

- Briar 14-day: log `templateKey → variant title → variantBridgeSimilarity → bridgePass`
- Phase 1: do not require `overallPass` via bridge until thresholds tuned
- Phase 2: require `bridgePass == true` on ≥ 12/14 days

**`DailyFitSkyForwardV2_Tests.swift`**

- Re-baseline any tarot expectations that change under joint selection (document in commit)

### 8.3 Manual QA profiles

| Profile | Fixture in repo? | Action |
|---------|------------------|--------|
| **Briar** | Yes — `SkyForwardV2Support` | 14-day inspector export; review bridge trace block per day |
| **Linden** | Partial | Export 14-day; tune thresholds |
| **Wren** | Partial | Export 14-day; bridge pass + variety (variety is separate concern) |

Contrast days to inspect manually: any day with `relationship: contrast` and `overlapCount: 0`.

---

## 9. Implementation checklist (ordered)

### Step 1 — Extract selector (no behaviour change)

- [ ] Create `NarrativeTarotBridgeSelector.swift` with types + stub
- [ ] Extract shared `scoreBaseCard(...)` from `BlueprintLensEngine` to avoid duplicate loops
- [ ] Unit-test Stage A funnel matches existing card ordering for nil-intent path

### Step 2 — Joint selection (behaviour change, Stage-1 only)

- [ ] Implement Stages A–C in selector
- [ ] Branch `selectTarotAndStyleEdit` when `narrativeIntent != nil`
- [ ] Unify `generatePayloadWithTrace` tarot path with selector
- [ ] Verify recency tracker still updated once per day

### Step 3 — Trace export

- [ ] Add `NarrativeBridgeTrace` + extend `PayloadTrace`, `NarrativeCoherenceTrace`, `DailyFitDiagnosticReport`
- [ ] Inspector trace markdown subsection `### Narrative bridge`
- [ ] Phase 1: `bridgePass` traced but not in `overallPass`

### Step 4 — Tests + Briar export

- [ ] Add `NarrativeTarotBridge_Tests.swift`
- [ ] Run Briar 14-day export; write tuning notes to `docs/fixtures/narrative_tarot_bridge_signoff_YYYY-MM-DD.md`
- [ ] Adjust `variantBridgeWeight` / thresholds based on exports

### Step 5 — Enforce coherence (Phase 2)

- [ ] Enable `bridgePass` in `overallPass` once sign-off doc approved
- [ ] Re-run full test suite + production fingerprint guard

---

## 10. Acceptance criteria

### Must pass before merge

- [ ] Stage-1 path uses joint (card, variant) selection
- [ ] Production path unchanged; `ProductionFingerprintGuard_Tests` green
- [ ] `NarrativeBridgeTrace` exported in inspector trace for Stage-1 days
- [ ] No new user-visible strings in app or dailyfit markdown export
- [ ] `NarrativeTarotBridge_Tests` + existing narrative tests green
- [ ] Briar 14-day: every day has non-nil bridge trace with `pairsEvaluated > 0`

### Must pass before Ash on-device sign-off (Phase 2)

- [ ] Briar 14-day: ≥ 12/14 days `bridgePass == true` after threshold tuning
- [ ] Contrast days: manual read confirms style-edit copy faces weather, not anchor
- [ ] Fashion/astro partners: “engine is honest; product voice feels unified” on sampled days

### Explicit non-goals

- [ ] Wren template/essence diversification (separate ticket — do not block bridge on this)
- [ ] Personal scale envelope work (`daily_fit_personal_scale_sliders_handoff.md`)
- [ ] Production merge of Stage 1

---

## 11. Risk register

| Risk | Mitigation |
|------|------------|
| Tarot JSON `energyEmphasis` too coarse for fine bridges | Trace `bestVariantSimilarityInPool`; tune weight not JSON in v1 |
| Joint selection shifts Briar golden tarot days | Re-baseline tests with documented rationale; compare 14-day exports side-by-side |
| Over-weighting bridge breaks transit feel | Keep astro funnel; start `variantBridgeWeight` at 0.25 |
| Trace/code drift between payload and trace paths | Single selector function used by both paths |
| Threshold false failures | Phase 1 trace-only; Phase 2 enforce after export review |

---

## 12. File change list

| File | Change |
|------|--------|
| `Cosmic Fit/InterpretationEngine/NarrativeTarotBridgeSelector.swift` | **NEW** — funnel + joint pair selection |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Branch to bridge selector; dedupe tarot scoring |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | `NarrativeBridgeTrace`; extend tuning + coherence |
| `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` | Pass bridge trace to report |
| `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift` | New tuning keys in fingerprint |
| `Cosmic Fit/InterpretationEngine/NarrativeSelectionDirectives.swift` | Optional: accept bridge metrics in `computeCoherenceTrace` |
| `Cosmic FitTests/NarrativeTarotBridge_Tests.swift` | **NEW** |
| `Cosmic FitTests/NarrativeTarotUnification_Tests.swift` | Extend assertions |
| `Cosmic FitTests/NarrativeCoherence_Tests.swift` | 14-day bridge log |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Trace markdown: `### Narrative bridge` |
| `docs/fixtures/narrative_tarot_bridge_signoff_*.md` | **NEW** after tuning — sign-off record |

**Do not modify:** `TarotCards.json`, `DailyFitViewController` copy, production calibration preset, `NarrativeIntentEngine` classification rules (unless bug found).

---

## 13. Reference — pair selection pseudocode

```swift
func select(...) -> SelectionResult {
    let tuning = calibration.narrativeSelection!
    let target = intent.tarot.targetEnergyVector

    // Stage A
    var funnel = allCards.map { scoreBaseCard($0, ...) }
    funnel.sort { $0.baseCardScore > $1.baseCardScore }
    let pool = Array(funnel.prefix(tuning.bridgeCandidatePoolSize))

    // Stage B + C
    var pairs: [Candidate] = []
    for entry in pool {
        guard let edits = entry.card.styleEdits, !edits.isEmpty else { continue }
        for (i, edit) in edits.enumerated() {
            var bridge = cosineSimilarity(energyDictionary(edit.energyEmphasis), target)
            if intent.relationship == .contrast { bridge *= 1.2 }
            let total = entry.baseCardScore + tuning.variantBridgeWeight * bridge
            pairs.append(Candidate(
                card: entry.card, variant: edit, variantIndex: i,
                baseCardScore: entry.baseCardScore,
                variantBridgeScore: bridge, pairTotalScore: total
            ))
        }
    }

    // Soften: per-card min-drama among top-3 variant scores (apply before global sort)
    if intent.relationship == .soften {
        pairs = applySoftenMinDramaRule(pairs, pool)
    }

    pairs.sort { $0.pairTotalScore > $1.pairTotalScore }
    let best = pairs[0]
    let runnerUp = pairs.count > 1 ? pairs[1].pairTotalScore : best.pairTotalScore
    let maxSim = pairs.map(\.variantBridgeScore).max() ?? 0

    let trace = NarrativeBridgeTrace(
        selectedCardName: best.card.name,
        selectedVariantTitle: best.variant.title,
        selectedVariantIndex: best.variantIndex,
        variantBridgeSimilarity: best.variantBridgeScore,
        bestPairTotalScore: best.pairTotalScore,
        runnerUpPairTotalScore: runnerUp,
        bridgeMargin: best.pairTotalScore - runnerUp,
        bestVariantSimilarityInPool: maxSim,
        funnelCardCount: pool.count,
        pairsEvaluated: pairs.count,
        contrastWeatherWins: contrastCheckIfNeeded(best, intent),
        bridgePass: best.variantBridgeScore >= tuning.minVariantBridgeSimilarity
                 && (best.pairTotalScore - runnerUp) >= tuning.minBridgeMargin
    )
    return SelectionResult(candidate: best, bridgeTrace: trace, ...)
}
```

---

## 14. Summary for implementer

1. **Problem:** Variant scoring runs after card lock-in; coherence only checks that scoring ran.  
2. **Fix:** Astro funnel → joint (card, variant) pair selection → existing JSON copy is the bridge.  
3. **Constraint:** Stage 1 only; zero new user copy; production untouched.  
4. **Balance:** Astro creates eligibility; narrative picks best existing copy inside the pool — not a full override.  
5. **QA:** Export numeric bridge trace first; enforce thresholds in Phase 2 after Briar/Linden/Wren tuning.  
6. **Success:** User reads the same tarot UI and feels one intentional outfit story on contrast days without a generated bridging sentence.
