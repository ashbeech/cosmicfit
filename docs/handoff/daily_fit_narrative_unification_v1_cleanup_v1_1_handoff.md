# Daily Fit — Narrative Unification: v1 Cleanup + v1.1 Implementation Handoff

**Status:** Implementation complete — formal closure 2026-05-23  
**Date:** 2026-05-23 (amended post-audit)  
**Audience:** Engineer or AI agent implementing the full cleanup and unification work  
**Origin:** Product owner (Ash) — v1 narrative resolver shipped with generated user-facing copy and new app UI blocks. **That was not the intended product outcome.** The goal is **narrative cohesion through existing UI selections**, not new paragraphs.

**Audit readiness:** ~95% for end-to-end delivery after §15 addendum. Phase A alone ≈40% of total product goal.

---

## 1. Executive summary

### 1.1 What Ash actually wants

**Narrative = what the app already shows, unified.**

The daily story should emerge from coherent **selection** of:

- Tarot card + style-edit variant (existing JSON copy only)
- Top essence categories (radar / triangle)
- Daily palette (3 colours from Style Guide)
- Vibrancy, contrast, metal tone scales

The user should **not** see newly generated engine prose such as “Your base is dramatic… Today's sky asks you to intensify with…” or theme headings like “Dramatic Magnetic” unless Ash has explicitly authored and approved that copy for a specific UI slot (she has not).

### 1.2 What v1 shipped (misaligned)

v1 added `DailyNarrativeResolver`, which:

- Classifies chart anchor vs sky weather (`reinforce` / `stretch` / `soften` / `contrast`) — **keep this logic**
- Generates **new template copy** (`resolvedTheme`, `instruction`, `avoid`, captions) — **remove from user surfaces**
- Attaches `narrativeBrief` to payload after Stage 2 — **selection already happened; too late for cohesion**
- Surfaces brief in **app UI** (`DailyFitViewController` new labels) — **revert**
- Surfaces brief in **Inspector** HTML/markdown exports — **demote to internal trace only**

### 1.3 What this handoff delivers

| Phase | Name | Outcome |
|-------|------|---------|
| **A** | v1 cleanup | App UI restored to designed layout; no generated copy shown to users; inspector exports cleaned |
| **B** | v1.1 unification | Anchor/weather logic drives **selection** of tarot, palette, essence presentation, scales — **zero new user-facing strings** |

**Scope:** `stage1_experimental` engine only for unification biasing. Production / Release behaviour must remain unchanged.

### 1.4 Explicitly out of scope (v1.1)

Do **not** unify or bias in v1.1 unless listed in §5:

- Silhouette profile selection/scoring
- Daily textures selection
- Daily pattern selection
- Metal tone nudging (defer to v1.2)
- Tarot JSON content rewrites
- New user-visible strings of any kind
- Production / legacy engine selection paths

---

## 2. Hard constraints — read first

| Required | Forbidden |
|----------|-----------|
| Unify tarot, palette, essence **presentation**, scales via selection bias | Add new user-visible text blocks, headings, captions, or instructions |
| Use **existing** tarot/style-edit copy from `TarotCards.json` | Generate template sentences for the app |
| Keep anchor/weather **classification logic** (4 relationships — see §3.2) | Ship unapproved narrative copy to production UI |
| Inspector **trace export only** for QA (relationship, bias, coherence flags) | “Daily Brief” in dailyfit HTML/markdown exports |
| Stage-1-only biasing behind `DailyFitEngineMode.stage1Experimental` | Changing production selection when `narrativeIntent == nil` |
| Deterministic output (same inputs + seed → same payload) | Breaking frozen payload **decode** (legacy `narrativeBrief` key tolerated) |
| Stage-1 narrative tests use **`DailyFitPipeline.generate`**, not raw `BlueprintLensEngine` alone | Tests that bypass pipeline for stage-1 coherence assertions |
| Run full test suite; update tests to match new contract | Leaving dead narrative UI labels in `DailyFitViewController` |

**Definition of narrative success (v1.1):** On a stage-1 day, tarot pick, palette roles, essence top-3, and scale values **feel like one direction** in the existing UI — without reading any new paragraph.

---

## 3. Architecture today (v1)

```
DailyEnergyEngine.generateSnapshot()           Stage 1
        ↓
BlueprintLensEngine.generatePayload()          Stage 2 — tarot, palette, essence selected HERE
        ↓
DailyNarrativeResolver.resolve()               Post-hoc — reads essence, writes copy
        ↓
DailyFitPayload (+ optional narrativeBrief)
        ↓
DailyFitViewController                         Shows brief + existing widgets (REVERT in Phase A)
```

**Core bug:** Narrative is **annotated after selection**. v1.1 must **bias selection using narrative intent computed from essence anchor/weather**.

### 3.1 Key files (current v1)

| File | Role |
|------|------|
| `Cosmic Fit/InterpretationEngine/DailyNarrativeResolver.swift` | Classification + copy templates — **refactor** |
| `Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift` | Assembly; attaches brief after Stage 2 — **reorder** |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Tarot, palette, essence selection — **add intent bias** |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | `DailyNarrativeBrief`, `NarrativeTrace`, payload field — **restructure** |
| `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` | Reports `narrativeBrief` + `narrativeTrace` |
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | Narrative labels + captions — **remove** |
| `Cosmic Fit/UI/Views/EssenceTriangleView.swift` | Top-3 radar — **presentation update** |
| `Cosmic Fit/Resources/TarotCards.json` | Existing card + style-edit copy — **do not rewrite** |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Daily Brief HTML/markdown — **remove user brief; keep trace export** |
| `Cosmic FitTests/DailyNarrativeResolver_Tests.swift` | Copy-focused tests — **replace** |

### 3.2 Classification rules to preserve (do not break)

**Four relationships only in v1.1** — do **not** add a fifth `ground` enum case (deferred to v1.2; see §5.9).

Priority order (first match wins):

1. **reinforce** — anchor top-1 == weather top-1 OR ≥2 shared categories in top-3  
2. **contrast** — opposition pair in **leading top-2** on each side (`minimal↔maximalist`, `polished↔edgy`, `classic↔eclectic`, `grounded↔playful`). Rank-3 opposition alone does **not** trigger contrast.  
3. **soften** — weather top-2 ⊆ intense bold `{drama, edgy, maximalist, magnetic}` AND anchor top-2 ⊆ restrained `{polished, classic, minimal, romantic, grounded, effortless}` AND `overlapCount >= 1`  
4. **stretch** — default; wins over soften when mean silhouette delta > 0.12 OR visibility lift > 1.0 above chart anchor  

**Theme lexicon** (`polished.drama` → "Polished Drama", etc.): **Remove from user path in Phase A.** Optional internal `themeLexiconKey: String?` on `NarrativeTrace` for inspector QA only — **does not drive selection** in v1.1.

Source: `DailyNarrativeResolver.swift`, `DailyNarrativeResolver_Tests.swift`.

### 3.3 Validation profiles (Linden / Wren / Briar)

| Profile | Automated in repo? | How to validate |
|---------|-------------------|-----------------|
| **Briar** | Yes — `SkyForwardV2Support` in `DailyFitSkyForwardV2_Tests.swift` | 14-day pipeline tests |
| **Linden** | **No** — add §15.1 fixture OR manual-only | See §15.1 |
| **Wren** | **No** — add §15.1 fixture OR manual-only | See §15.1 |

**Do not** claim Linden/Wren golden tests pass until §15.1 fixtures are implemented.

---

## 4. Phase A — v1 cleanup (implement first)

### A1. Remove narrative brief from app UI

**File:** `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift`

Remove entirely:

- `narrativeThemeLabel`, `narrativeInstructionLabel`, `narrativeAvoidLabel`, `narrativeSupportingHeaderLabel`
- `essenceCaptionLabel`, `paletteCaptionLabel`, `scalesCaptionLabel`
- All narrative/caption constraint plumbing and `updateNarrativeLayoutConstraints(hasBrief:)`
- All `updateContentFromPayload()` brief population
- Reveal/hide animation arrays referencing narrative labels

**Restore** layout: after tarot divider → **style edit paragraph** pins directly (pre-v1 production layout).

Existing UI order (unchanged):

```
Tarot card + title
Style Edit (variant title, description, daily ritual, wardrobe reflection)
Outfit breakdown / palette / scales / essence triangle / silhouette …
```

### A2. Stop generating user-facing copy

**File:** `Cosmic Fit/InterpretationEngine/DailyNarrativeResolver.swift` → refactor to **`NarrativeIntentEngine.swift`**

- **Keep:** classification, anchor/weather top-3, overlap, silhouette deltas, `NarrativeTrace`
- **Remove:** `buildInstructionAndAvoid`, `buildResolvedTheme` display strings, all caption generators, `DailyNarrativeBrief` **encoding** on new payloads
- **Update** `DailyNarrativeBrief` doc comment in `DailyFitTypes.swift` from “Source of truth for user-facing narrative” → **“Deprecated v1 copy container; decode-only for legacy freezes. Not generated or displayed.”**

Keep optional `narrativeBrief` key **decode-only** for legacy frozen JSON.

### A3. Pipeline attachment

**File:** `Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift`

- `generate()` — no brief copy on payload after Phase A
- `generateWithTrace()` — returns `narrativeTrace` only (no brief)

### A4. Clean inspector exports

**File:** `inspector/Sources/CosmicFitInspectorServer/Web/app.js`

| Export function | Remove | Keep / add |
|-----------------|--------|------------|
| `buildDailyFitHtml` | Daily Brief block, “Supporting detail — Style Edit” | Existing tarot/palette/essence/scales |
| `markdownDailyFit` | Same | Same |
| `markdownTrace` / trace HTML builders | — | `narrativeTrace` + §5.11 fields |

**New bias/coherence fields go in trace export only** — not in dailyfit export.

### A5. Diagnostics

**File:** `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift`

- Stop populating `narrativeBrief` on `DailyFitDiagnosticReport`
- Populate `narrativeTrace` + (Phase B) `narrativeIntentTrace` per §5.11

### A6. Tests (Phase A)

| Test file | Action |
|-----------|--------|
| `DailyNarrativeResolver_Tests.swift` | Rename → `NarrativeIntentEngine_Tests`; remove copy asserts |
| `DailyNarrative14DayValidation_Tests` | Assert trace + relationship per day, not brief copy |
| `DailyFitUIIntegration_Tests` | `narrativeBrief == nil` on stage-1 pipeline output |
| `DailyFitSkyForwardV2_Tests` | Remove `narrativeBrief != nil` expectation |
| `DailyFitFrozenPayloadStorage_Tests` | Legacy decode with old brief OK; **add:** load legacy freeze in UI path does not show brief labels (structural — labels removed) |
| `DailyFitCoherence_Tests` | Production unchanged |

### A7. Phase A acceptance

- [ ] App Daily Fit: **no** narrative labels; layout matches pre-v1
- [ ] Release build unchanged
- [ ] Inspector **dailyfit** export: no Daily Brief
- [ ] Inspector **trace** export: relationship + anchor/weather
- [ ] `DailyNarrativeBrief` comment updated; no new brief encoded
- [ ] All tests green

---

## 5. Phase B — v1.1 selection unification

### 5.1 Target pipeline

```
Stage 1: DailyEnergySnapshot
        ↓
Stage 2a: resolveEssenceProfile(snapshot, mode)     ← extract; run FIRST
        ↓
Stage 2b: NarrativeIntentEngine.resolve(essence, snapshot, mode)
        ↓
Stage 2c: BlueprintLensEngine.generatePayload(..., essence: precomputed, narrativeIntent:)
          → tarot, palette, scales (biased); essence scores unchanged
        ↓
Stage 2d: DailyFitPayload (no user copy)
        ↓
DailyFitDiagnostics: NarrativeTrace + NarrativeIntentTrace + extended PaletteTrace
```

**No circular dependency:** Essence scores first → intent once → selection consumes intent. **Never** re-score essence from intent.

### 5.2 Types

See §15.2 for full Swift structs. Add tunables to `DailyFitCalibration.Stage2Sensitivity` or new `NarrativeSelectionTuning` nested struct (§15.6).

**Gating:** `NarrativeIntent?` non-nil only when `mode == .stage1Experimental` && `chartAnchorScores != nil`.

### 5.3 Relationship → selection policy (summary)

| Relationship | maxStatementSlots | Tarot card boost | Tarot variant | Scales |
|--------------|-------------------|------------------|---------------|--------|
| reinforce | 2 | 0.5×anchor + 0.5×weather energy blend | Match blend | Full sky modulation |
| stretch | 1 | Weather top-1 energy vector | Match weather top-1 | Elevated; no dual max |
| soften | 1 | Weather vector × 0.7 | Lowest `drama` in `energyEmphasis` | Cap + baseline pull (§15.6) |
| contrast | 1 (exactly) | Weather top-1 × 1.2 weight | Match weather top-1 only | Moderate vibrancy; contrast OK |

Full palette algorithm: **§15.3** (not optional).

### 5.4 Palette implementation (pointer)

**Do not implement from §5.3 summary alone.** Implement **§15.3** exactly:

- Full 14-category → role preference map
- `scorePaletteCandidatesWithIntent(...)` formula with named weights
- New `selectViaNarrativeSlots(...)` called from `selectDailyPalette` when `intent != nil` && strategy == `.pureSkyScoring`
- Scoring **and** slot allocation both apply

### 5.5 Tarot + variant (summary)

**Card score** (stage-1 only, additive):

```swift
let cardVector = energyAffinityDictionary(from: card.energyAffinity) // String keys → Energy
let boost = cosineSimilarity(cardVector, intent.tarot.targetEnergyVector)
total += boost * calibration.narrativeSelection.categoryBoostWeight
```

**Target energy vector** — blend weather top-3 via `essenceCategoryWeights` rows (§15.4).

**Variant selection** (stage-1 only):

```swift
let variantVector = energyEmphasisDictionary(variant.energyEmphasis) // helper §15.4
score = cosineSimilarity(variantVector, intent.tarot.targetEnergyVector)
// tie-break: dailySeed % variants.count
```

**Production / nil intent:** existing rotation via `TarotVariantRotationTracker`.

**Card-level vs variant-level:** Card boost uses relationship-specific vector (reinforce = blend; others = weather-accent). Variant always uses weather-accent vector unless reinforce (then blend).

### 5.6 Scales

When `ScaleDirective` active (from intent):

```swift
if let cap = directive.vibrancyCap { final = min(final, cap) }
if directive.pullTowardBaseline {
    final = baseline * tuning softenBaselineBlend + final * (1 - tuning softenBaselineBlend)
}
```

Defaults in calibration: `softenVibrancyCap = 0.72`, `softenContrastCap = 0.70`, `softenBaselineBlend = 0.70` (§15.6).

### 5.7 Essence triangle — **required spec (Option A)**

**File:** `Cosmic Fit/UI/Views/EssenceTriangleView.swift`

**No new copy.** Use existing category display names from radar labels.

| Layer | Data source | Visual |
|-------|-------------|--------|
| **Weather (primary)** | `visibleCategories` top-3 | Solid stroke `#cosmicBlue` @ 0.5 alpha; filled star icons; full label opacity |
| **Anchor (ghost)** | `chartAnchorScores` top-3 | Dashed stroke `#cosmicBlue` @ 0.15 alpha; **no** star icons; labels @ 0.35 opacity, smaller font (−2pt) |

**Geometry:** Same 14-axis radar; anchor vertices at anchor **score** radius (not weather score). Max 6 label positions — if anchor and weather share a category, draw **weather label only** (single label, solid).

**API:**

```swift
func configure(with profile: StyleEssenceProfile, presentation: EssencePresentationDirective?)
```

When `presentation == nil` (production): current single-triangle behaviour unchanged.

**Inspector:** No triangle visual required — `buildEssenceProfileHtml` already shows today + anchor columns. App is the gap.

**Acceptance:** Screenshot or UI test — ghost triangle visible on stage-1; production screenshot unchanged.

### 5.8 Internal API threading (mandatory refactor checklist)

`BlueprintLensEngine.generatePayload` **today** orders tarot → palette → … → essence **last**. Both `generatePayload` and `generatePayloadWithTrace` **must** be updated together (trace path duplicates tarot scoring ~lines 348–430).

| Function | New parameters | Behaviour when `intent == nil` |
|----------|----------------|--------------------------------|
| `resolveEssenceProfile(from:mode:)` | — | Extract; call **first** from pipeline or start of `generatePayload` |
| `generatePayload` / `generatePayloadWithTrace` | `narrativeIntent: NarrativeIntent?`, optional precomputed `essence` | Current code path exactly |
| `selectTarotAndStyleEdit` | `intent: NarrativeIntent?` | Unchanged |
| `selectVariant(for:profileHash:dailyFitEngineId:)` | `intent: NarrativeIntent?` | Rotation |
| `selectDailyPalette` | `intent: NarrativeIntent?` | Current strategy |
| `scorePaletteCandidates` | `intent: NarrativeIntent?` | Current formula |
| `selectViaPureSkyScoring` | Replace with `selectViaNarrativeSlots` when intent != nil | Pure top-3 |
| `deriveVibrancy` / `deriveContrast` | `scaleDirective: ScaleDirective?` | Unchanged |

**`DailyFitPipeline.generate` orchestration:**

```swift
let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
let intent = mode == .stage1Experimental
    ? NarrativeIntentEngine.resolve(essence: essence, snapshot: snapshot, mode: mode)
    : nil
let payload = BlueprintLensEngine.generatePayload(
    blueprint: blueprint, snapshot: snapshot, calibration: calibration,
    dailyFitEngineId: engineId, mode: mode,
    precomputedEssence: essence, narrativeIntent: intent
)
```

### 5.9 Briar day-1 edge case — **defer `ground` to v1.2**

**Decision:** Do **not** add `NarrativeRelationship.ground` in v1.1.

**v1.1 workaround** for intense anchor + restrained weather + zero overlap (synthetic edge case — **not** Briar 2026-05-23 after sky-forward dedup):

- Classify as **stretch** (existing rule 4)
- Apply **stretch palette slots** but add scoring bonus for `foundationRolePreference` when `weatherTop2 ⊆ restrained && anchorTop2 ⊆ intense` (flag on `PaletteDirective`: `preferFoundationOverStatement: Bool`)
- Set `NarrativeTrace.coherenceGap = "intenseAnchorRestrainedWeather"` for inspector QA
- Scales: apply `pullTowardBaseline` partial blend (same as soften, 0.5 blend not 0.7)

**Briar 2026-05-23 (verified 2026-05-23):** With stage-1 sky-forward essence, anchor and weather both rank **drama** top-1 → **reinforce** (rule 1), `coherenceGap == nil`. See `docs/fixtures/narrative_unification_signoff_2026-05-23.md`.

**v1.2:** Consider proper `ground` relationship if workaround insufficient.

### 5.10 Trace schema (single source of truth)

**Problem:** `BlueprintLensEngine.PayloadTrace` and `DailyFitDiagnosticReport` use different structs. Inspector reads **`DailyFitDiagnosticReport`** via API JSON — not raw `PayloadTrace`.

**Extend these Swift types** in `DailyFitDiagnostics.swift`:

```swift
struct NarrativeIntentTrace: Codable, Equatable {
    let relationship: String
    let anchorTop3: [String]
    let weatherTop3: [String]
    let accentCategory: String
    let foundationCategory: String
    let overlapCount: Int
    let themeLexiconKey: String?          // internal QA only
    let coherenceGap: String?             // e.g. intenseAnchorRestrainedWeather
}

struct NarrativeCoherenceTrace: Codable, Equatable {
    let paletteAccentRoleMatch: Bool      // ≥1 selected colour has accent/statement/signature role
    let paletteStatementSlotCount: Int
    let tarotCategoryBoostApplied: Bool
    let tarotVariantScored: Bool          // false if rotation fallback
    let overallPass: Bool                 // AND of above + relationship-specific rules §15.5
}
```

**Extend `PaletteTrace`:**

```swift
    let narrativeBiasApplied: Bool?
    let statementSlotsUsed: Int?
    let selectionPath: String?            // "narrativeSlots" | "pureSkyScoring" | "dramaSlots"
```

**Extend `NarrativeTrace`** (or merge into `NarrativeIntentTrace` — pick one, avoid duplication):

Keep `chosenRelationship`, `templateKey` (= `"stretch.drama.magnetic"` relationship.anchor1.weather1 for QA), silhouette deltas.

**`DailyFitDiagnosticReport` fields:**

```swift
    let narrativeIntentTrace: NarrativeIntentTrace?
    let narrativeCoherenceTrace: NarrativeCoherenceTrace?
    // Remove narrativeBrief after Phase A
```

**Inspector rendering** — **`markdownTraceExport` / trace HTML only** (`app.js`):

Add subsection `### Narrative selection` under each day:

```markdown
### Narrative selection
- Relationship: stretch
- Anchor: romantic, drama, sensual
- Weather: magnetic, edgy, eclectic
- Palette bias: applied (1 statement slot, accent role match: pass)
- Tarot variant: scored (not rotation)
- Coherence: pass
```

**Do not** add these fields to `markdownDailyFit` / `buildDailyFitHtml`.

---

## 6. Production safety & freeze policy

| Check | Requirement |
|-------|-------------|
| Release `effectiveEngineId` | Always `production` |
| `narrativeIntent` on production | Always `nil` |
| `intent == nil` code paths | Bit-identical to **baseline** (§7.2) |
| Determinism | Tie-breaks use `snapshot.dailySeed` only |

### 6.1 Production fingerprint baseline (mandatory before any Phase B code)

**Baseline commit:** Record hash **before** Phase B changes:

```
git rev-parse HEAD
# Pre-work reference: 47b73b5508d7ea056502a27036acbd560f96a60f (2026-05-23 — update if branch moved)
```

**Procedure:**

1. Checkout baseline commit (or branch tip before Phase B)
2. Run `ProductionFingerprintCapture_Tests` (implement) — saves fingerprint for `CoherenceProfiles.ashProfile` day 0, production engine, via `DailyFitPipeline.generate`
3. Commit fingerprint string into test file as `expectedProductionFingerprint`
4. Phase B tests must match **exactly** when `narrativeIntent == nil`

Use same fingerprint function as `SkyForwardV2Support.payloadFingerprint`.

### 6.2 Stage-1 freeze invalidation (v1.1)

After v1.1 changes selection logic, **old stage-1 frozen payloads are stale** (wrong tarot/palette vs new biasing).

**Required action:** Bump `DailyFitEngineRegistry.stage1ExperimentalDescriptor.fingerprint` when v1.1 ships (recalculated from calibration + code version tag), **OR** document one-time purge:

```swift
// DEBUG only — run once on v1.1 upgrade
DailyFitFrozenPayloadStorage.shared.purgeEngineId(DailyFitEngineRegistry.stage1ExperimentalId)
```

Existing freezes with `narrativeBrief` copy: harmless after Phase A UI removal; selections still stale until re-reveal.

**Namespacing unchanged:** `{profileKey}_{engineId}_{yyyy-MM-dd}.json`

---

## 7. Tests (Phase B)

### 7.1 Test entry point rule

**All stage-1 narrative/coherence tests must call:**

```swift
DailyFitPipeline.generate(blueprint:snapshot:calibration:dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId)
```

Not `BlueprintLensEngine.generatePayload` directly (except isolated unit tests for palette slot function with injected intent).

### 7.2 New / replaced suites

| Suite | Purpose |
|-------|---------|
| `NarrativeIntentEngine_Tests` | Classification parity (no copy) |
| `NarrativePaletteUnification_Tests` | §15.3 slot counts + role rules per relationship |
| `NarrativeTarotUnification_Tests` | Variant scoring; category boost changes ranking |
| `NarrativeCoherence_Tests` | `NarrativeCoherenceTrace.overallPass` for fixture days |
| `ProductionFingerprintGuard_Tests` | Matches §6.1 baseline |
| `DailyFitCoherence_Tests` (extend) | Stage-1 contradiction rate |

### 7.3 Golden fixtures

| Fixture | Profile | Date(s) | Expected relationship | Key assert |
|---------|---------|---------|----------------------|------------|
| Briar reinforce | `SkyForwardV2Support` | 2026-05-26 | reinforce | `weatherTop1 == drama == anchorTop1`; ≥1 statement slot |
| Briar reinforce (May 23) | `SkyForwardV2Support` | 2026-05-23 | reinforce | ≥2 shared top-3 categories (sensual+drama); `coherenceGap == nil`; ≤2 statement slots; `overallPass` |
| Briar stretch+gap (synthetic) | `NarrativeIntentEngine_Tests` | n/a | stretch | `coherenceGap == intenseAnchorRestrainedWeather`; unit fixture only |
| Wren contrast | `NarrativeFixtures.wren` | 2026-05-23 | contrast | Exactly 1 accent/statement role; `overallPass` |
| Wren stretch | `NarrativeFixtures.wren` | 2026-06-03 | stretch | ≤1 statement slot |
| Linden stretch | `NarrativeFixtures.linden` | 2026-05-23 | stretch | ≤1 statement slot; 14-day all stretch |
| Production Ash | `CoherenceProfiles.ashProfile` | 2026-05-10 | n/a | Fingerprint == baseline |

**Linden/Wren fixtures:** Implement §15.1 in `Cosmic FitTests/NarrativeFixtures.swift` before claiming automated coverage.

### 7.4 Manual-only validation (Ash)

If §15.1 fixtures not complete: re-export from Inspector with profile hash + dates:

| User | Profile hash | Contrast / special dates |
|------|--------------|--------------------------|
| Wren | `609730200.0_37.9855765_23.7283762` | 2026-05-23 → 2026-05-28 (contrast) |
| Linden | `1759731240.0_53.7439438_-0.3402508` | All 14d stretch window 2026-05-23 → 2026-06-05 |
| Briar | `469108800.0_51.5074_-0.1278` | 2026-05-23 reinforce (drama top-1); 2026-05-26 reinforce |

Export **trace** (not dailyfit) and verify `NarrativeCoherenceTrace.overallPass`.

---

## 8. Inspector validation

### 8.1 Rebuild inspector (required after Swift changes)

```bash
cd /path/to/cosmicfit/inspector
./run-inspector.sh
```

Symlinked app sources pick up engine changes. Verify header **Inspector build** timestamp updates. See `inspector/README.md`.

**Xcode note:** iOS app uses `PBXFileSystemSynchronizedRootGroup` — new Swift files under `Cosmic Fit/` auto-include. **Inspector Swift package:** add new files to `Package.swift` targets if outside symlinked paths. **New test files:** add to `Cosmic Fit.xcodeproj` test target if not auto-synced.

### 8.2 Export surfaces

| Export | narrative fields |
|--------|------------------|
| `markdownDailyFit` / dailyfit HTML | **None** |
| `markdownTrace` / trace HTML | Full §5.10 trace |
| Diagnostic JSON API | `narrativeIntentTrace`, `narrativeCoherenceTrace` |

---

## 9. Implementation order

```
1. Phase A: UI removal + layout restore
2. Phase A: Stop copy generation; update types/comments; inspector dailyfit cleanup
3. Phase A: Tests → commit checkpoint "v1 cleanup"
4. Capture production fingerprint baseline (§6.1) on baseline commit
5. Phase B: NarrativeIntentEngine + types + calibration tunables
6. Phase B: Pipeline reorder + BlueprintLensEngine threading (both generatePayload paths)
7. Phase B: Palette §15.3 + tests
8. Phase B: Tarot boost + variant scoring + tests
9. Phase B: Scale caps + tests
10. Phase B: EssenceTriangleView dual-layer
11. Phase B: Diagnostics trace + app.js markdownTrace
12. Phase B: NarrativeFixtures (Linden/Wren) + golden tests
13. Bump stage1 fingerprint or purge freezes; Ash manual re-export
```

---

## 10. Files checklist

### Phase A
- [ ] `DailyFitViewController.swift`
- [ ] `DailyNarrativeResolver.swift` → `NarrativeIntentEngine.swift`
- [ ] `DailyFitPipeline.swift`
- [ ] `DailyFitTypes.swift` (comment + deprecate brief generation)
- [ ] `DailyFitDiagnostics.swift`
- [ ] `inspector/.../Web/app.js` (dailyfit exports)
- [ ] Test files §A6

### Phase B
- [ ] `BlueprintLensEngine.swift` (both payload + trace paths)
- [ ] `NarrativeIntentEngine.swift`
- [ ] `NarrativeSelectionDirectives.swift` (maps, slot allocator — new)
- [ ] `DailyFitPipeline.swift`
- [ ] `DailyFitTypes.swift` (intent types, calibration tunables)
- [ ] `DailyFitDiagnostics.swift` (trace structs)
- [ ] `EssenceTriangleView.swift`
- [ ] `Cosmic FitTests/NarrativeFixtures.swift` (new)
- [ ] `Cosmic FitTests/NarrativePaletteUnification_Tests.swift` (new)
- [ ] `Cosmic FitTests/NarrativeTarotUnification_Tests.swift` (new)
- [ ] `Cosmic FitTests/NarrativeCoherence_Tests.swift` (new)
- [ ] `Cosmic FitTests/ProductionFingerprintGuard_Tests.swift` (new)
- [ ] `inspector/.../Web/app.js` (trace export only)
- [ ] `DailyFitEngineRegistry.swift` — bump stage1 fingerprint after v1.1
- [ ] Verify `Cosmic Fit.xcodeproj` includes new test targets (sync group or manual)

---

## 11. Definition of done

### v1 cleanup
- [ ] Zero generated copy in app
- [ ] Inspector dailyfit: no Daily Brief
- [ ] Classification tests pass
- [ ] Production fingerprint captured

### v1.1
- [ ] Palette uses `selectViaNarrativeSlots` on stage-1
- [ ] Tarot variant scored on stage-1
- [ ] Essence dual-layer triangle on stage-1
- [ ] Trace export shows bias + coherence pass/fail
- [ ] Briar automated golden tests pass
- [ ] Linden/Wren fixtures pass OR manual trace checklist signed off
- [ ] Production fingerprint guard passes
- [ ] Stage-1 freezes invalidated / fingerprint bumped
- [ ] **No new user-facing strings**

---

## 12. Reference — v1 misalignment

v1 generated template copy (theme, instruction, avoid, captions) — **not** pre-existing product content. v1.1 applies classification to **selection only**.

Pre-existing user-visible copy: tarot JSON, Style Guide colour names, existing `DailyFitViewController` section structure.

---

## 13. Related docs

- `docs/handoff/daily_fit_sky_forward_v2_refactor_handoff.md`
- `docs/handoff/daily_fit_palette_selection_handoff.md`
- `docs/handoff/inspector_derivation_drilldown_handoff.md`
- `Cosmic FitTests/DailyFitCoherence_Tests.swift`

---

## 14. Resolved product decisions (no longer open)

| Question | Decision |
|----------|----------|
| Essence triangle | **Option A** — ghost anchor layer (§5.7) |
| `ground` relationship | **Defer v1.2** — workaround §5.9 |
| Tarot JSON `essenceAffinity` | **Defer** — energy proxy via `essenceCategoryWeights` (§15.4) |
| New user copy | **Never** in v1.1 |
| Theme lexicon | Trace-only `themeLexiconKey`; not user-facing |
| Textures / pattern / silhouette | **Out of scope** v1.1 |

---

## 15. Implementation spec addendum

### 15.1 Linden & Wren test fixtures (implement in Phase B)

**File:** `Cosmic FitTests/NarrativeFixtures.swift`

Add profiles matching Inspector exports (Ash validated 2026-05-23). Use simplified blueprint (clone Briar blueprint pattern with profile-specific palette names) unless full Style Guide available.

#### Wren

```swift
static let wrenHash = "609730200.0_37.9855765_23.7283762"
// Natal signs: derive from Inspector natal chart OR use Athens 1989-04-28 04:30 preset when added to inspector presets.json
// Until natal signs confirmed in repo: use CoherenceProfiles-style approximation:
// Capricorn sun chart → classic/polished anchor (match export anchor top-3: classic, polished, romantic)
static let wrenNatalSigns = [10, 2, 10, 10, 4, 10, 10, 4, 10, 10]  // VERIFY against inspector /api/inspect before locking test
static let wrenProgressedSigns = wrenNatalSigns  // placeholder — replace from inspector

static let wrenContrastDates: [Date] = [ISO 2026-05-23 ... 2026-05-28]
static let wrenStretchDate = ISO 2026-06-03
// Expected anchor top-3: classic, polished, romantic (stable 14d)
// Expected 2026-05-23 weather top-3: maximalist, edgy, eclectic → contrast
```

**Implementer must:** Run Inspector for Wren, copy exact natal/progressed planet signs from API response into fixture, replace placeholder signs, re-run once to lock expected relationship per golden date.

#### Linden

```swift
static let lindenHash = "1759731240.0_53.7439438_-0.3402508"
// Hull 2025-10-06 07:14 — VERIFY natal signs from inspector
static let lindenNatalSigns = [/* from inspector */]
static let lindenStretchDate = ISO 2026-05-23
// Expected anchor top-3: romantic, drama, sensual
// Expected 2026-05-23 weather: magnetic, edgy, eclectic → stretch
// Expected all 14 days in 2026-05-23..2026-06-05: relationship == stretch
```

#### Shared harness

```swift
static func generatePayload(profile: NarrativeFixtureProfile, date: Date) -> DailyFitPayload {
    // DailyEnergyEngine.generateSnapshot(...) + DailyFitPipeline.generate(..., stage1ExperimentalId)
}
```

**Until natal signs verified:** Mark Wren/Linden golden tests as `.disabled("Awaiting inspector-derived natal signs")` — Briar tests still gate CI.

---

### 15.2 Full 14-category role preference map

Each `StyleEssenceCategory` maps to accent-preferring and foundation-preferring `ColourRole` lists (for scoring bonus, not hard filter):

| Category | accentRolePreference (ordered) | foundationRolePreference (ordered) |
|----------|-------------------------------|-----------------------------------|
| edgy | .statement, .accent, .signature | .core, .neutral |
| romantic | .core, .accent, .support | .neutral, .anchor |
| classic | .core, .neutral, .anchor | .accent |
| utility | .neutral, .anchor, .core | .support |
| drama | .statement, .accent, .signature | .core, .neutral |
| playful | .accent, .support, .signature | .core, .neutral |
| polished | .core, .neutral, .anchor | .accent |
| effortless | .neutral, .core, .support | .anchor |
| sensual | .accent, .core, .support | .neutral |
| magnetic | .statement, .signature, .accent | .core, .neutral |
| grounded | .neutral, .anchor, .core | .support |
| eclectic | .accent, .statement, .support | .core |
| minimal | .neutral, .anchor, .core | .accent |
| maximalist | .statement, .signature, .accent | .core, .neutral |

**Intense cluster** (for soften/stretch gap detection): drama, edgy, maximalist, magnetic.  
**Restrained cluster:** polished, classic, minimal, romantic, grounded, effortless.

---

### 15.3 Palette algorithm (concrete)

#### Constants (move to `DailyFitCalibration.NarrativeSelectionTuning`)

```swift
rolePreferenceBonus: Double = 0.12        // per matching role tier (1st=full, 2nd=0.6, 3rd=0.3)
categoryEnergyWeight: Double = 0.18       // scales energy alignment term
narrativeJitter: Double = 0.06             // stage-1; lower than paletteJitter to reduce noise
```

#### Scoring formula

For each candidate colour `c` with role `r`:

```
energyTerm = Σ_e categoryEnergyBoost[e] * (1 if e in roleEnergyAlignment[r] else 0)
             / max(1, |roleEnergyAlignment[r]|)

roleTerm = rolePreferenceBonus * tierMultiplier(r, accentRolePreference)
         + rolePreferenceBonus * 0.5 * tierMultiplier(r, foundationRolePreference)

score = baseEnergyScore(vibeSource)      // existing scorePaletteCandidates term
      + categoryEnergyWeight * energyTerm
      + roleTerm
      + narrativeJitter * seededRandom
      + profileBias
```

`categoryEnergyBoost` = normalized blend of `essenceCategoryWeights[weatherTop1..3]` with weights `[0.55, 0.30, 0.15]`.

#### Slot allocator: `selectViaNarrativeSlots`

Called when `intent != nil` && stage-1.

```
Input: scored[(colour, score)], intent.palette.maxStatementSlots, role maps
statementPool = colours where role ∈ {.accent, .statement, .signature}
foundationPool = colours where role ∈ {.core, .neutral, .anchor, .support}

nStatement = min(intent.maxStatementSlots, statementPool.count)
Pick top nStatement from statementPool by score
Pick top (3 - nStatement) from foundationPool by score (exclude duplicates by hex)

If preferFoundationOverStatement (Briar gap flag): nStatement = min(nStatement, 1)
```

#### Worked example — Wren 2026-05-23 (contrast)

| Input | Value |
|-------|-------|
| Anchor top-3 | classic, polished, romantic |
| Weather top-3 | maximalist, edgy, eclectic |
| Relationship | contrast |
| maxStatementSlots | 1 |

**Expected output shape:** 1 colour with role ∈ {accent, statement, signature} scoring highest on edgy/maximalist energy; 2 colours with roles ∈ {core, neutral, anchor}. Trace: `statementSlotsUsed == 1`, `paletteAccentRoleMatch == true`.

#### Worked example — Linden 2026-05-23 (stretch)

| Input | Value |
|-------|-------|
| Anchor top-3 | romantic, drama, sensual |
| Weather top-3 | magnetic, edgy, eclectic |
| maxStatementSlots | 1 |

**Expected:** 1 statement/accent (magnetic/edgy aligned); 2 foundation/neutral/core.

#### Worked example — Briar 2026-05-26 (reinforce)

| Input | Value |
|-------|-------|
| Anchor top-3 | drama, maximalist, edgy |
| Weather top-3 | drama, sensual, eclectic |
| maxStatementSlots | 2 |

**Expected:** Up to 2 statement slots; tarot boost uses 50/50 anchor/weather blend.

---

### 15.4 Energy vector helpers

```swift
/// Blend essenceCategoryWeights rows for weather top-3 categories.
static func targetEnergyVector(
    weatherTop3: [StyleEssenceCategory],
    weights: [Double] = [0.55, 0.30, 0.15]
) -> [Energy: Double]

/// Convert tarot [String: Double] energyEmphasis keys to Energy enum (ignore unknown keys).
static func energyDictionary(from stringKeyed: [String: Double]) -> [Energy: Double]

/// Cosine similarity on union of keys; default 0 for missing.
static func cosineSimilarity(_ a: [Energy: Double], _ b: [Energy: Double]) -> Double
```

Place in `BlueprintLensEngine` or `NarrativeSelectionDirectives.swift`.

**Reinforce blend:**

```swift
let anchorVec = targetEnergyVector(anchorTop3, weights: [0.5, 0.35, 0.15])
let weatherVec = targetEnergyVector(weatherTop3, weights: [0.55, 0.30, 0.15])
let blended = zipEnergy(anchorVec, weatherVec, anchorWeight: 0.5)
```

---

### 15.5 Coherence heuristic (`overallPass`)

Per day, after payload built:

```swift
var pass = true

// Universal
pass &= palette.selectedRoles.contains { accentRoles.contains($0) }  // accentRoles = accent|statement|signature

// Relationship-specific
switch relationship {
case .contrast, .stretch:
    pass &= palette.statementSlotCount <= 1
case .soften:
    pass &= palette.statementSlotCount <= 1
    pass &= payload.vibrancy <= tuning.softenVibrancyCap + 0.02
case .reinforce:
    pass &= palette.statementSlotCount <= 2
}

pass &= tarotVariantWasScored  // not rotation fallback

coherenceTrace = NarrativeCoherenceTrace(..., overallPass: pass)
```

Inspector trace markdown: `- Coherence: pass` or `fail (palette statement slots: 2, expected ≤1)`.

---

### 15.6 Calibration tunables

Add to `DailyFitCalibration` (or nested `NarrativeSelectionTuning`):

| Key | Default | Used by |
|-----|---------|---------|
| `categoryBoostWeight` | 0.15 | Tarot card boost |
| `rolePreferenceBonus` | 0.12 | Palette scoring |
| `categoryEnergyWeight` | 0.18 | Palette scoring |
| `narrativePaletteJitter` | 0.06 | Palette scoring |
| `softenVibrancyCap` | 0.72 | Scales |
| `softenContrastCap` | 0.70 | Scales |
| `softenBaselineBlend` | 0.70 | Scales |
| `intenseAnchorRestrainedWeatherBlend` | 0.50 | Briar gap workaround scales |

Stage-1 preset in `DailyFitEngineRegistry` sets these; production preset omits struct (nil tuning → no narrative path).

---

### 15.7 Tarot variant scoring (full)

```swift
private static func selectVariant(
    for card: TarotCard,
    profileHash: String,
    dailyFitEngineId: String,
    intent: NarrativeIntent?,
    dailySeed: UInt64
) -> (variant: StyleEditVariant, trace: VariantSelectionTrace) {
    guard let intent, let edits = card.styleEdits, !edits.isEmpty else {
        // existing rotation path
    }
    let target = intent.tarot.targetEnergyVector
    var best = (index: 0, score: -1.0)
    for (i, edit) in edits.enumerated() {
        let vec = energyDictionary(from: edit.energyEmphasis)
        let score = cosineSimilarity(vec, target)
        if score > best.score { best = (i, score) }
    }
    let tieBreak = Int(dailySeed % UInt64(edits.count))
    // if top two within 0.01, use tieBreak — mirror card selection
    return (edits[selectedIndex], trace)
}
```

**Soften-specific:** Prefer variant with minimum `energyEmphasis["drama"] ?? 0.5` among top-3 variant scores.

---

## 16. Bottom line for implementer

1. **Phase A** stops the product mistake (generated copy in UI/exports). Ship first.  
2. **Phase B** makes existing widgets coherent via **selection bias** — implement §15.3–§15.7 literally; do not improvise palette scoring.  
3. **Verify production** with fingerprint guard before and after.  
4. **Briar** gates CI; **Linden/Wren** need §15.1 natal sign verification or manual trace sign-off.  
5. **Never** add user-facing strings.
