# DailyFit Production Audit — Fix Handoff

**Date:** 2026-06-10  
**Status:** Audit complete; **3 blockers identified with root causes and fix specs**  
**Audience:** AI developer with no prior conversation context  
**Engine:** `stage1_experimental` (Stage 1 Experimental / Sky Forward)  
**Extends:** [dailyfit_output_production_readiness_handoff.md](./dailyfit_output_production_readiness_handoff.md)  
**Visual report:** [Cosmic Fit production audit](/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/cosmic-fit-production-audit.canvas.tsx)

---

## 1. What You Are Fixing

Cosmic Fit delivers two user-facing artifacts:

| Artifact | What it is | Engine path |
|---|---|---|
| **Style Guide** | One-time (or rare refresh) blueprint: palette family, code lean-into/avoid, textures, occasions, hardware | `BlueprintComposer` → `CosmicBlueprint` |
| **Daily Fit** | Per-day output: tarot card + style edit (title, ritual, reflection), 3-colour palette, 6 sliders, essences, textures | `DailyFitPipeline` → `BlueprintLensEngine` (stage1) |

This handoff covers **production readiness gaps** found by a definitive output audit: real engine outputs for **223 users × 45 sequential days** (10,035 Daily Fits + 223 Style Guides), with tarot/variant recency state persisted across days exactly as a real user would experience it.

**Verdict:** Strong **guarded-beta / TestFlight** candidate. **Not broad-release ready** until the three blockers below are fixed and re-audited.

**Overall readiness score:** 68/100

---

## 2. Context You Need (No Prior Chat Required)

### 2.1 Key engine concepts

- **Chart anchor:** User's natal-chart-derived essence top-3 (stable per user).
- **Sky weather:** Today's transit-driven essence top-3 (changes daily).
- **Relationship:** How the day's narrative relates anchor vs weather — `reinforce`, `stretch`, `contrast`, or `soften`.
- **Tarot hard-block:** Cards selected in the last 3 days are removed from the candidate pool (`TarotRecencyTracker.cooldownDayCount = 3`).
- **Tarot soft penalty:** Days 4–10 apply a score penalty; minimum observed repeat gap across the audit cohort is **10 days**.
- **Variant:** Each of 78 tarot cards has **3 style-edit variants** (title + description + ritual + reflection). Same card can return after ~10+ days with a different variant.
- **Display position:** UI slider marker position (0–1), derived from raw engine value via a personal envelope (`PersonalScaleEnvelopeCalculator`). **Raw values on the payload are unchanged**; only display mapping is affected.

### 2.2 Important files (quick map)

| Area | Primary files |
|---|---|
| Tarot + variant selection | `BlueprintLensEngine.swift`, `NarrativeTarotBridgeSelector.swift`, `TarotRecencyTracker.swift`, `TarotVariantRotationTracker.swift` |
| Silhouette + scales | `BlueprintLensEngine.swift` (`deriveSilhouetteProfile`), `PersonalScaleEnvelope.swift`, `Stage1ScaleSensitivity` in `BlueprintLensEngine.swift` |
| Narrative intent / relationship | `DailyNarrativeSelector.swift`, `NarrativeIntentEngine.swift`, `NarrativeSelectionDirectives.swift` |
| Tarot scoring | `TarotCardScoring.swift` |
| Essence scoring | `BlueprintLensEngine.swift` (`essenceCategoryWeights`, `deriveStyleEssenceProfileStage1Experimental`) |
| Pipeline entry | `DailyFitPipeline.swift` |

### 2.3 Do not regress (working well)

These passed at scale in the audit — preserve while fixing blockers:

- **0** adjacent tarot repeats across 10,035 user-days
- **0** hard-block violations (3-day window)
- **12.7** avg unique cards per 14 days (target ≥ 11)
- **10.7** avg unique top-3 essence sets per 14 days (target ≥ 10)
- **100%** engine coherence-trace pass; **0.91** mean energy-vector cosine
- **0** days with missing user-facing fields (palette, sliders, style edit copy)
- **223/223** Style Guides with all 12 sections populated
- **50,175/50,175** inspector self-verdict checks passed

---

## 3. Audit Methodology (Reproduce Anytime)

### 3.1 Tools added in this audit

| Script | Purpose |
|---|---|
| `tools/production_audit_harness.py` | Generates sequential multi-day outputs via inspector (`http://127.0.0.1:7777`). Resets tarot history **only on each user's day 1**; state persists across days. |
| `tools/production_audit_analyze.py` | Computes rotation, repetition, slider pinning, cohesion, gaps, blueprint completeness → `summary.json` + `summary.txt` |

### 3.2 How to run

```bash
# Terminal 1 — inspector (must be running)
cd inspector && ./run-inspector.sh

# Terminal 2 — generate (223 users × 45 days ≈ 15 min at parallel=4)
python3 tools/production_audit_harness.py \
  --days 45 --synthetic-stride 1 --parallel 4 \
  --out docs/fixtures/production_audit

# Analyze
python3 tools/production_audit_analyze.py \
  --in docs/fixtures/production_audit
```

**Output locations:**

- `docs/fixtures/production_audit/raw/<user_id>.jsonl` — trimmed per-day records
- `docs/fixtures/production_audit/blueprints/<user_id>.json` — full Style Guide (day 1)
- `docs/fixtures/production_audit/summary.json` — machine-readable metrics

### 3.3 Cohort composition

- **7 presets:** fire, earth, air, water, leo, maria, ash
- **216 synthetic charts:** 12 sun signs × 3 birth times × 3 locations × 2 birth years
- **Window:** 2026-06-10 → 2026-07-24 (45 days)
- **Total:** 10,035 Daily Fits

### 3.4 Unit test baseline

Full suite: **457 pass / 1 fail** (25.7 min)

The single failure is intentional guard coverage for Blocker F1:

- `NarrativeTarotBridge_Tests.repeatedCardsGetDifferentVariant` — asserts <60% exact title duplicates on returning cards; **currently fails at ~61%**

```bash
xcodebuild test -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"Cosmic FitTests/NarrativeTarotBridge_Tests"
```

---

## 4. Release Gates (Before Broad Release)

| Gate | Target | Audit measured | Pass? |
|---|---|---|:---:|
| Tarot hard-block violations | 0 | 0 | ✅ |
| Adjacent tarot repeats | 0 | 0 | ✅ |
| Avg unique cards / 14 days | ≥ 11 | 12.7 | ✅ |
| Avg unique top-3 essence sets / 14 days | ≥ 10 | 10.7 | ✅ |
| Repeated exact title + ritual (same card return) | 0 or justified | **3,179 / 5,228 (61%)** | ❌ |
| Users with slider pinned ≥80% of days | 0 real profiles | **~100 / 223** | ❌ |
| Pentacles suit share vs deck share | ~balanced | **1.4% vs 17.9%** | ❌ |
| Cohesion contradiction failures | 0 | 0 | ✅ |
| Style Guide completeness | 100% | 223/223 | ✅ |

---

## 5. Blocker F1 — Returning Cards Repeat Verbatim (P0)

### 5.1 Symptom

When a tarot card legitimately returns after the ~10-day cooldown, **61% of returns reuse the exact same title + daily ritual**. Example from audit:

- User `synth_079_leo_newyork`, **Queen of Wands**
- 2026-06-21 and 2026-07-06: identical **"The Magnet"** + identical mirror ritual

Each card has 3 variants available; users should not feel the same day repeating.

### 5.2 Objective cause chain

```
1. NarrativeTarotBridgeSelector.applyVariantRecencySwap() exists and is correct
   → If winning card would repeat same variantIndex as last time, swap to best alternate

2. BlueprintLensEngine (line ~135) builds lastVariantByCard via:
   TarotVariantRotationTracker.lastShownVariantMap(recentSelections: ...)

3. lastShownVariantMap() ONLY iterates cards in recentSelections
   → recentSelections = TarotRecencyTracker.getRecentSelections()
   → Window = EngineConfig.tarotRecencyWindowDays = 10 days

4. Hard-block (3d) + soft penalty (4–10d) prevent returns before day 10
   → Minimum repeat gap in audit: 10 days
   → When a card returns, it is NOT in recentSelections
   → lastVariantByCard map is EMPTY for that card

5. applyVariantRecencySwap() never fires
   → Audit: 0 variantRecencySwaps in 10,035 user-days

6. Meanwhile recordVariantShown() DOES persist last-shown index permanently
   → Key: lastVariantShown_{engineId}_{profileHash}_{cardName}
   → Data exists; it is just never consulted at return time
```

### 5.3 Root cause (one sentence)

**Variant recency lookup is gated on the 10-day card recency window, but cards only return after day 10+, so the swap mechanism never receives the data it needs.**

### 5.4 Fix specification

**File:** `Cosmic Fit/InterpretationEngine/TarotVariantRotationTracker.swift`

Add a method that queries persistent storage for **eligible cards in today's pool**, not recentSelections:

```swift
/// Build last-shown variant map for cards in today's eligible pool.
/// Used by bridge-path variant recency swap when a card returns after the
/// 10-day recency window (recentSelections will not contain it).
func lastShownVariantMapForEligibleCards(
    eligibleCardNames: [String],
    profileHash: String,
    dailyFitEngineId: String = DailyFitEngineRegistry.productionId
) -> [String: Int] {
    var map: [String: Int] = [:]
    for cardName in eligibleCardNames {
        if let idx = lastShownVariantIndex(
            forCard: cardName,
            profileHash: profileHash,
            dailyFitEngineId: dailyFitEngineId
        ) {
            map[cardName] = idx
        }
    }
    return map
}
```

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` (~line 135)

Replace:

```swift
let lastVariantByCard = TarotVariantRotationTracker.shared.lastShownVariantMap(
    recentSelections: recentSelections,
    profileHash: snapshot.profileHash,
    dailyFitEngineId: engineId
)
```

With:

```swift
let lastVariantByCard = TarotVariantRotationTracker.shared.lastShownVariantMapForEligibleCards(
    eligibleCardNames: eligibleCards.map(\.card.name),
    profileHash: snapshot.profileHash,
    dailyFitEngineId: engineId
)
```

**No changes needed** to `NarrativeTarotBridgeSelector.applyVariantRecencySwap()` — it already swaps when `lastVariantByCard[card.name]` matches `selected.variantIndex`.

### 5.5 Acceptance criteria

| Metric | Before | Target after fix |
|---|---:|---:|
| `variantRecencySwaps` in 10,035 days | 0 | > 0 (many) |
| Exact title+ritual repeat rate on card returns | 61% | < 20% (stretch: < 10%) |
| `repeatedCardsGetDifferentVariant` test | FAIL | PASS |
| Adjacent tarot repeats | 0 | 0 (must not regress) |
| Hard-block violations | 0 | 0 (must not regress) |

### 5.6 Verification

```bash
# Unit test
xcodebuild test ... -only-testing:"Cosmic FitTests/NarrativeTarotBridge_Tests/repeatedCardsGetDifferentVariant"

# Cohort re-audit — check summary.json:
#   repeatNarrative.totalExactTitleRitualRepeats
#   cohesion.totalVariantRecencySwaps (via per-day diag.variantRecencySwapped in raw JSONL)
python3 tools/production_audit_harness.py --days 45 --subset 50  # smoke
python3 tools/production_audit_analyze.py
```

---

## 6. Blocker F2 — Slider Rail-Pinning (P0)

### 6.1 Symptom

Four of six UI sliders appear **stuck at 0.0 or 1.0** for most users:

| Slider | User-days pinned at rail | Users pinned ≥80% of 45 days |
|---|---:|---:|
| Masculine / feminine | 72.9% | 101 / 223 |
| Angular / rounded | 59.4% | 78 / 223 |
| Structured / draped | 58.1% | 97 / 223 |
| Contrast | 55.8% | 113 / 223 |
| Vibrancy | 4.2% | 0 / 223 |
| Metal tone | 12.0% | 11 / 223 |

**Ash example:** structured/draped display = **1.00 for all 45 days**; angular/rounded ≈ 0.00 for 43/45 days.

### 6.2 Yes — raw variation exists

Daily axes move **4.5–5.3 points** on the 0–10 scale across 45 days. The engine is producing real day-to-day variation. The problem is entirely in the **display mapping layer**, not in missing engine data.

### 6.3 Objective cause chain (two separate bugs)

#### Bug A — Stage 1 silhouette ignores chart anchor baseline

**File:** `BlueprintLensEngine.deriveSilhouetteProfile()` (~line 1807)

In `stage1Experimental` mode, raw silhouette values are computed **purely from sky axes**:

```swift
let mf = 0.5 + tanh((skyVis - 5.5) / 4.5) * 0.45   // range ≈ [0.12, 0.88]
```

Keyword-scanned chart anchors (`mfBase`, `arBase`, `sdBase` from Style Guide `code.leanInto/avoid`) are computed but **only stored as `chartAnchorMF/AR/SD`** — never blended into the raw value. Every user with the same sky gets the same silhouette regardless of chart.

Contrast with vibrancy/metal tone, which correctly use blueprint baseline + sky modulation.

#### Bug B — Envelope too narrow for raw value range

**File:** `PersonalScaleEnvelopeCalculator.silhouetteEnvelope()` (~line 230)

Display envelope is centred on `chartAnchor` (typically 0.5) with half-spans:

- MF / AR: ±0.20 → floor 0.30, ceiling 0.70
- SD: ±0.25 → floor 0.25, ceiling 0.75

But raw tanh values land in **[0.12, 0.88]**. Any day with visibility > ~7.5 pushes MF above 0.70 → display clamps to **1.0**. Same for low axes → **0.0**.

```swift
// PersonalScaleEnvelopeCalculator.computeDisplayPosition
return max(0.0, min(1.0, (value - floor) / range))  // hard clamp
```

**Ash 2026-06-10:** visibility axis = 9.46 → raw MF = 0.818 → envelope [0.30, 0.70] → display = 1.0.

### 6.4 Fix specification (two coordinated changes — ship together)

#### Change 1 — Blend chart anchor into stage1 raw silhouette

**File:** `BlueprintLensEngine.swift`, `deriveSilhouetteProfile()` stage1 branch

Replace pure-sky tanh with **anchor baseline + reduced sky modulation** (mirror vibrancy/metal pattern):

```swift
if mode == .stage1Experimental {
    let skyMod = { (axis: Double) in tanh((axis - 5.5) / 4.5) * 0.20 }
    let mf = max(0.0, min(1.0, mfBase + skyMod(snapshot.axes.visibility)))
    let ar = max(0.0, min(1.0, arBase + skyMod(snapshot.axes.action)))
    let sd = max(0.0, min(1.0, sdBase + skyMod(snapshot.axes.strategy)))
    return SilhouetteProfile(
        masculineFeminine: mf,
        angularRounded: ar,
        structuredDraped: sd,
        chartAnchorMF: mfBase,
        chartAnchorAR: arBase,
        chartAnchorSD: sdBase
    )
}
```

**Why 0.20 amplitude (not 0.45):** With anchor-centred values, typical raw range becomes ~[baseline−0.20, baseline+0.20]. Users with differentiated keyword baselines (e.g. 0.3 vs 0.7) get genuinely different silhouettes. Sky still modulates daily.

**Note:** Many users (including Ash) have keyword baseline = 0.5 because Style Guide `code` paragraphs don't contain silhouette keywords (`angular`, `draped`, etc.). That is a separate Style Guide enrichment opportunity — not required for this fix, but worth a follow-up.

#### Change 2 — Widen envelope half-spans to match new modulation range

**File:** `BlueprintLensEngine.swift`, `Stage1ScaleSensitivity`

```swift
static let silhouetteSDPracticalHalfSpan: Double = 0.30   // was 0.25
static let silhouetteMFARPracticalHalfSpan: Double = 0.28  // was 0.20
```

With modulation ±0.20 and half-span ~0.28–0.30, typical days land at display ~0.50; extreme sky days reach ~0.20–0.80 — off the rails.

#### Change 3 (optional, P1) — Contrast envelope

Contrast pinning (56% of user-days) uses a separate envelope in `contrastEnvelope()`. If silhouette fix alone doesn't reduce contrast pinning below ~20%, widen `contrastPracticalHalfSpan` from 0.14 → 0.18 and re-audit. **Do not widen contrast before silhouette fix** — measure incrementally.

### 6.5 What NOT to do

- **Do not remove the envelope entirely** — it exists so users with extreme chart baselines see meaningful relative movement, not absolute 0–1 raw values.
- **Do not only widen the envelope without blending the baseline** — that makes the display range wider but keeps all users identical (shared sky problem remains).
- **Do not change raw payload values** — `PersonalScaleEnvelope` is display-only per file header comment.

### 6.6 Acceptance criteria

| Metric | Before | Target after fix |
|---|---:|---:|
| Users with any slider pinned ≥80% of 45 days | ~100 | < 20 |
| MF/AR/SD user-days pinned at 0 or 1 | 60–73% | < 25% |
| Ash structured/draped display range (45d) | 0.00 (stuck) | ≥ 0.15 |
| Per-user avg display range (MF/AR/SD) | ~0.33–0.51 raw range clipped | ≥ 0.20 display range |
| Vibrancy display range | Good (0.46 avg) | No regression |

### 6.7 Verification

```bash
python3 tools/production_audit_analyze.py  # check sliders.stuckUserCounts, sliders.avgDisplayRange

# Spot-check Ash
python3 -c "
import json
recs=[json.loads(l) for l in open('docs/fixtures/production_audit/raw/ash.jsonl')]
for s in ['structuredDraped','angularRounded','masculineFeminine']:
    vals=[r['displayPositions'][s] for r in recs]
    print(s, 'min', min(vals), 'max', max(vals), 'range', max(vals)-min(vals))
"

# Existing slider tests
xcodebuild test ... -only-testing:"Cosmic FitTests/SliderRangeAudit_Tests"
xcodebuild test ... -only-testing:"Cosmic FitTests/PersonalScaleEnvelope_Tests"
```

**Also verify in app UI** — confirm diamond/slider UI reads `scalePresentation.*.displayPosition`, not raw silhouette or contrast values.

---

## 7. Blocker F3 — Earth / Grounded Stories Starved (P1)

### 7.1 Symptom

A third of the narrative space is effectively unreachable:

| Signal | Measured | Expected (balanced) |
|---|---:|---:|
| Pentacles suit selections | 1.4% | ~17.9% (14/78 cards) |
| Cards never appearing (45d cohort) | 27 / 78 | ~0 |
| grounded essence in top-3 slots | 1.6% | meaningful share |
| classic / minimal / utility in top-3 | 1.7% / 1.0% / 0.0% | meaningful share |
| Days classified as "stretch" | 80% | lower; more "reinforce" |
| Days classified as "reinforce" | 9% | higher |

**Suit distribution vs deck:**

| Suit | % of selections | % of deck |
|---|---:|---:|
| Major Arcana | 35.9% | 28.2% |
| Wands | 33.4% | 17.9% |
| Cups | 18.1% | 17.9% |
| Swords | 11.3% | 17.9% |
| **Pentacles** | **1.4%** | **17.9%** |

Chart anchors **do** differ correctly per user (earth preset → romantic-sensual-classic; Maria → classic-polished-romantic — stable 45/45 days). But the **final broadcast story** is always magnetic/eclectic/romantic/maximalist because shared sky weather dominates selection.

### 7.2 Objective cause chain (three compounding layers)

#### Layer 1 — Tarot scoring favours high-drama cards

**File:** `TarotCardScoring.swift`

Score = vibe + axis + transit − recency + narrative boost.

- `planetEnergyAffinities` weights Mars/Pluto/Jupiter/Sun toward **drama/edge**
- Sky transits produce drama-heavy vibe profiles most days
- Pentacles / Hermit / Temperance cards have low drama affinity → low vibe score → rarely win funnel

#### Layer 2 — Essence scoring suppresses quiet categories

**File:** `BlueprintLensEngine.swift`, `essenceCategoryWeights` (~line 1536)

- `grounded` → utility 0.40 + classic 0.30 (quiet energies)
- `magnetic` → drama 0.35 + romantic 0.25 (loud energies)
- Axis modifiers favour high-visibility/high-action days → magnetic/maximalist/eclectic rise, grounded/minimal fall

Same weights feed `targetEnergyVector` for tarot narrative-category boost → earth-suited cards score lower.

#### Layer 3 — Relationship classifier defaults to stretch

**File:** `NarrativeIntentEngine.classifyRelationship()` (~line 113)

- `reinforce` only when anchor[0] == weather[0] OR overlap ≥ 2 categories
- `contrast` only on explicit opposition pairs
- **Everything else → stretch** (80% of days)

Stretch uses weather-only energy vector → system tells the sky's loud story, not the user's anchor identity.

### 7.3 Fix specification (implement incrementally, re-audit after each)

#### Adjustment 1 — Chart-anchor pull in tarot target vector (highest leverage)

**File:** `NarrativeIntentEngine.buildIntent()` or `NarrativeSelectionDirectives.targetEnergyVector()` call site

For `.stretch` (and optionally `.contrast`) days, blend anchor into tarot target vector at ~25% weight:

```swift
case .stretch, .contrast:
    let weatherVec = targetEnergyVector(weatherTop3: weatherTop3)
    let anchorVec = blendCategoryWeightRows(
        categories: anchorTop3, weights: [0.5, 0.35, 0.15]
    )
    tarotVector = zipEnergy(weatherVec, anchorVec, anchorWeight: 0.75)
    // 75% weather, 25% anchor — tune after audit
```

**Expected effect:** Pentacles/Hermit become selectable for classic/grounded-anchored users even on stretch days.

#### Adjustment 2 — Relax reinforce threshold

**File:** `NarrativeIntentEngine.classifyRelationship()`

After existing reinforce check, add:

```swift
else if overlapCount >= 1 {
    // Single-category overlap with similar energy profile → reinforce
    let anchorLead = essenceCategoryWeights[anchorTop3[0]] ?? [:]
    let weatherLead = essenceCategoryWeights[weatherTop3[0]] ?? [:]
    if cosineSimilarity(anchorLead, weatherLead) > 0.7 {
        return .reinforce
    }
}
```

**Expected effect:** Reinforce rate rises from ~9% toward ~20–25%. More "this is so me" days.

#### Adjustment 3 — Suit diversity nudge in card scoring (lighter touch)

**File:** `TarotCardScoring.scoreCard()`

Add small bonus (+0.03 to +0.05) for suits underrepresented in recent selections (e.g. if last 5 cards had no Pentacles, boost Pentacles candidates). Keeps selection quality while preventing permanent suit starvation.

#### Adjustment 4 — Tune planet energy affinities (optional, measure last)

**File:** `TarotCardScoring.planetEnergyAffinities`

Reduce drama weight on Jupiter/Pluto; increase classic/utility on Saturn. Changes which energies the sky produces — affects entire pipeline. **Only after Adjustments 1–2 are measured.**

### 7.4 What NOT to do

- **Do not force random Pentacles** — diversity nudge should be small and score-based, not quota-based.
- **Do not eliminate stretch days** — stretch is a valid narrative mode; the issue is 80% stretch with weather-only targeting.
- **Do not rewrite essence categories** — tune weights and blending, not the 14-category model.

### 7.5 Acceptance criteria (after Adjustments 1 + 2)

| Metric | Before | Target |
|---|---:|---:|
| Pentacles suit share | 1.4% | ≥ 8% |
| Distinct cards used (45d cohort) | 51 / 78 | ≥ 60 / 78 |
| grounded/classic/minimal in top-3 combined | < 5% | ≥ 12% |
| Reinforce day rate | 9% | ≥ 18% |
| Cohesion overall pass rate | 100% | ≥ 98% (no regression) |
| Tarot recency gates | pass | pass (no regression) |

### 7.6 Verification

```bash
python3 tools/production_audit_analyze.py
# Check: tarot.cardFrequencyTop10, cohesion.relationshipDistribution,
#        per-user essence top1Counts for earth/maria presets

# Preset spot-check (should show more classic/grounded for earth, maria)
python3 -c "
import json
from collections import Counter
for u in ['earth','maria']:
    c=Counter()
    for line in open(f'docs/fixtures/production_audit/raw/{u}.jsonl'):
        r=json.loads(line)
        c[r['essences']['rankedAll'][0]['category']]+=1
    print(u, dict(c.most_common(5)))
"
```

---

## 8. Recommended Implementation Order

```
Phase A — F1 variant recency (1–2 hours, isolated, high confidence)
  ├── TarotVariantRotationTracker.lastShownVariantMapForEligibleCards
  ├── BlueprintLensEngine call-site swap
  ├── NarrativeTarotBridge_Tests.repeatedCardsGetDifferentVariant → PASS
  └── Re-run audit harness (subset 50 users × 45d) → confirm swap count > 0, repeat rate ↓

Phase B — F2 silhouette display (2–4 hours, test Ash + cohort)
  ├── deriveSilhouetteProfile stage1: anchor + skyMod(0.20)
  ├── Stage1ScaleSensitivity half-span widen
  ├── PersonalScaleEnvelope_Tests + SliderRangeAudit_Tests
  ├── Full audit harness → slider pinning metrics
  └── App UI spot-check (Ash profile, 14 days)

Phase C — F3 story breadth (4–8 hours, incremental)
  ├── Adjustment 1: anchor blend in tarot vector (stretch/contrast)
  ├── Re-audit → measure Pentacles + reinforce rate
  ├── Adjustment 2: relax reinforce threshold (if reinforce still < 15%)
  ├── Re-audit
  ├── Adjustment 3: suit diversity nudge (if Pentacles still < 5%)
  └── Adjustment 4: planet affinities (only if needed)

Phase D — Full gate re-run
  ├── production_audit_harness.py full 223 × 45d
  ├── production_audit_analyze.py
  ├── Full xcodebuild test suite → 458/458 pass
  └── Update docs/fixtures/production_audit/summary.json in repo
```

---

## 9. Confidence Scorecard (For Prioritisation)

| Feature area | Score | Notes |
|---|:---:|---|
| Astrological computation & determinism | 92 | Verdicts pass; chart anchors stable |
| Output completeness | 95 | Zero broken days in 10,035 |
| Tarot rotation & recency | 93 | Hard-block works; F1 is variant-only |
| Within-day narrative cohesion | 84 | No contradictions found |
| Day-to-day variation (24h) | 82 | Essence/palette turnover strong |
| Style Guide quality | 86 | Complete, non-templated |
| **Returning-card narrative freshness** | **35** | **F1 — fix first** |
| **Slider UI perception** | **42** | **F2 — fix second** |
| **Story-to-chart personalisation** | **48** | **F3 — fix third** |

---

## 10. Important Warnings

1. **Do not revert unrelated dirty-tree changes** — broad narrative, colour, slider, and fixture work is in flight.
2. **Do not break tarot hard-block** — F1 fix touches the same code path as recency; run `NarrativeTarotBridge_Tests/cooldownHardBlock` after changes.
3. **Inspector must be running** for harness scripts — engine is not invoked from Python directly.
4. **`dailyPattern` null on some days is intentional** — gated by visibility/energy; not a gap.
5. **This is a polish/readiness pass**, not a narrative system rewrite — preserve cohesion and recency wins.

---

## 11. Completion Criteria (Broad Release)

The next dev can call Stage 1 production-ready when:

1. **F1:** Exact title+ritual repeat rate on card returns < 20%; `repeatedCardsGetDifferentVariant` passes.
2. **F2:** < 20 users with any slider pinned ≥80% of 45 days; Ash (and similar profiles) show ≥0.15 display range on all silhouette sliders.
3. **F3:** Pentacles ≥ 8% of selections; ≥ 60 distinct cards in 45-day cohort; reinforce rate ≥ 18%.
4. Full **223 × 45d audit** re-run confirms all release gates in §4 pass.
5. Full unit suite **458/458** pass.
6. No regression on tarot recency, cohesion pass rate, or Style Guide completeness.

---

## 12. Related Docs

| Doc | Relevance |
|---|---|
| [dailyfit_output_production_readiness_handoff.md](./dailyfit_output_production_readiness_handoff.md) | Original 14-day audit + gate targets (superseded by §4 metrics here) |
| [tarot_recency_hard_block_handoff.md](./tarot_recency_hard_block_handoff.md) | Hard-block implementation (do not regress) |
| [daily_fit_personal_scale_sliders_handoff.md](./daily_fit_personal_scale_sliders_handoff.md) | Envelope design intent |
| [daily_fit_narrative_tarot_bridge_handoff.md](./daily_fit_narrative_tarot_bridge_handoff.md) | Bridge selector architecture |
| `tools/production_audit_harness.py` | Definitive output generator |
| `docs/fixtures/production_audit/summary.json` | Latest audit metrics |
