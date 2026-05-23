# Inspector Derivation Drill-Down — Handoff Document

**Status:** Phases 1, 2, and 3 **shipped**. Phases 4–7 are scoped but not started.  
**Date:** 2026-05-21  
**Audience:** Engineers or AI agents continuing inspector provenance / calibration work.  
**Origin:** Ash (product owner) needs to audit whether Cosmic Fit outputs — Style Guide (Blueprint) and multi-day Daily Fit readouts — are **meaningfully and accurately prescribed**, not just visually plausible. The local inspector (`inspector/`, port 7777) is the primary validation surface.

---

## 1. Executive summary

### 1.1 Why we started this work

Cosmic Fit produces rich outputs (palette swatches, vibe bars, essence rows, tarot, transits, scales, textures, etc.) driven by a multi-stage Swift pipeline. When something looks wrong — e.g. Drama stuck at 13/14 days, a signature colour appearing every day, or an essence category that never rotates — the team needs to answer:

> **“Which planetary input or engine step caused this output?”**

The iOS app does not expose this. The inspector was built to mirror production engine behaviour and surface structured diagnostics. Phase 1–2 focused on making **almost every output element clickable** and showing a **stepped derivation timeline** in a right-side drawer, backed by data that already existed in engine traces but was not wired to the API or UI.

**Success criterion:** Click any swatch, vibe bar, transit row, family tag, etc. → see a numbered pipeline from chart/sky inputs → intermediate scores → final selection. Compare mode (multi-day carousel, engine A vs B) must resolve the correct date + engine context.

**Out of scope for this initiative:** Changing production algorithms (e.g. sky-forward v2, palette selection rework). Those are separate specs. This work is **observability only** — though better traces often reveal algorithm bugs that motivate separate fixes.

### 1.2 What exists today (after Phase 2)

| Surface | Drill-down quality |
|---------|-------------------|
| **Style Guide swatches, family/cluster tags** | Full V4 colour-engine decision tree (chart input → drivers → raw scores → overrides → family/cluster → accent slots → output) |
| **Daily Fit swatches** | Stage 1 source mix + energy scores + Stage 2 candidate pool + top scored colours |
| **Vibe bars, scales (vibrancy/contrast/metal), essence, tarot, textures, pattern, lunar, style edit, silhouette** | Multi-step pipeline; scales show baseline → modulation → final |
| **Transit rows** | Aggregate transit share + selected transit metadata + all transit summaries — **no per-energy attribution yet** |
| **Trace & Provenance tab** | Daily Fit accordions + new Style Guide colour-engine accordion |

### 1.3 What Phase 3 delivers

**Per-planet / per-source energy attribution** for Daily Fit Stage 1: answer “Mars square Moon contributed +X to Edge” instead of only “transits = 32% of total.”

Phases 4–7 extend the same pattern to Stage 2 palette feature vectors, silhouette intermediate terms, Style Guide non-palette resolver traces, and a linked derivation graph.

---

## 2. Architecture context

### 2.1 Inspector stack

```
inspector/
  Sources/CosmicFitInspectorLib/
    InterpretationEngine/  → symlink to Cosmic Fit/InterpretationEngine/
    InspectorEngine.swift    → bootstrap, blueprint cache, resolve()
    InspectorResponse.swift  → API JSON shape
  Sources/CosmicFitInspectorServer/
    Web/app.js               → UI + derivation drawer
    Routes.swift             → POST /api/inspect
```

**Critical:** Engine Swift changes go in `Cosmic Fit/InterpretationEngine/` — the inspector compiles the same files via symlink. Only inspector glue (`InspectorResponse`, `InspectorEngine`, `app.js`) lives separately.

**Run correctly after engine changes:**

```bash
cd inspector
./run-inspector.sh   # NOT bare swift run — rebuilds symlinked sources
```

Open http://127.0.0.1:7777. Confirm **Built:** timestamp in header after edits.

### 2.2 API response shape (relevant fields)

```json
{
  "blueprint": { "palette": { ... } },
  "blueprintDiagnostics": {
    "chartInput": { "sun": { "sign": "Scorpio", "degree": 12.3 }, ... },
    "boundaryFlags": [...],
    "familyDecisionTrace": {
      "rawScoresBeforeModifiers": { "depth": 3, "warmth": 5, ... },
      "normalizedDrivers": { "drivers": [{ "key": "Venus", "sign": "Libra", "weight": 4 }] },
      "variablesAfterOverrides": { "depth": "Deep", "temperature": "Warm", ... },
      "family": "Deep Autumn",
      "cluster": "Deep Warm Structured",
      ...
    },
    "accentSlots": [...]
  },
  "dailyFit": {
    "payload": { ... },
    "diagnostics": {
      "sourceContributions": { "natalShare": 0.45, "transitShare": 0.32, ... },
      "rawEnergyScores": { "drama": 2.1, "edge": 1.8, ... },
      "postMultiplierScores": { ... },
      "transitSummaries": [{ "transitPlanet": "Mars", "natalPlanet": "Moon", "aspect": "square", "strength": 0.72 }],
      "paletteSelectionTrace": { ... },
      ...
    }
  }
}
```

### 2.3 Pipeline overview

```
Natal + progressed + transits + lunar + current Sun
        ↓
DailyEnergyEngine.generateSnapshotWithTrace()     ← Phase 3 extends SnapshotTrace
        ↓
DailyEnergySnapshot + SnapshotTrace
        ↓
BlueprintLensEngine.generatePayloadWithTrace()    ← Phases 4–5 extend PayloadTrace
        ↓
DailyFitPayload + PayloadTrace
        ↓
DailyFitDiagnostics.generateReport()              ← maps traces → DailyFitDiagnosticReport
        ↓
InspectorResponse.dailyFit.diagnostics
```

Style Guide (profile-fixed, not date-varying):

```
NatalChart → ChartInputAdapter → ColourEngine.evaluateProduction()
        ↓
ColourEngineResult.trace (FamilyDecisionTrace)    ← Phase 2 now serialized
        ↓
BlueprintComposer.composeFull() → BlueprintDiagnosticReport
        ↓
InspectorResponse.blueprintDiagnostics
```

---

## 3. Phase 1 — Universal derivation drawer (shipped)

**Goal:** Click almost any output → numbered step timeline in right sidebar.

### 3.1 What was already in place

- Right-side drawer (`openDrill`) wired via `data-drill` attributes on DOM nodes
- Rich `DailyFitDiagnosticReport` on every `/api/inspect` response (Stage 1 energy + Stage 2 payload traces)
- `ColourProvenance` on every Style Guide swatch — but drawer wasn't using it
- Full **Trace & Provenance** card duplicating much of this as read-only accordions

### 3.2 Gaps Phase 1 closed

| Gap | Fix |
|-----|-----|
| Only handful of elements clickable | `data-drill` on swatches, vibe bars, essence rows, transits, scales, textures, pattern, lunar, style edit, silhouette, Style Guide tags |
| Style Guide swatches showed Daily Fit palette traces | Fixed: `blueprint-colour:` vs `colour:` drill keys |
| Compare-mode panes ignored context | `resolveDrillContext()` reads `.compare-pane` `data-date-iso` + `data-engine-id` |
| Flat tables in drawer | `renderDerivationTimeline()` — numbered stages with title, description, body |
| No active highlight | `.drill-active` on clicked node; Escape / click-outside / backdrop close |
| Silhouette field bug | Fixed `baselineMF` not `mfBaseline` |

### 3.3 Key UI files

| File | Role |
|------|------|
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | `openDrill`, `render*Drill` functions, `wireDrillHandlers()` |
| `inspector/Sources/CosmicFitInspectorServer/Web/index.html` | `#drill-drawer` aside |
| `inspector/Sources/CosmicFitInspectorServer/Web/styles.css` | `.derivation-step`, `.drill-active`, `.drawer-open` |

### 3.4 Drill key convention

```
blueprint-colour:{name}   → Style Guide swatch (profile-fixed)
colour:{name}             → Daily Fit palette swatch (date-varying)
vibe:{energy}             → Vibe bar
essence:{category}        → Essence row
transit:{planet}          → Transit row
silhouette:{mf|ar|sd}     → Silhouette scale
blueprint-meta:{field}    → Family / cluster / secondaryPull tag
tarot, pattern, lunar, styleEdit, texture:{name}, vibrancy, contrast, metalTone
```

Dispatch in `openDrill(key, ctx)` — `[type, ...rest] = key.split(":")`.

---

## 4. Phase 2 — Style Guide decision tree (shipped)

**Goal:** Serialize `FamilyDecisionTrace` (already computed during `ColourEngine.evaluateProduction`) to the inspector API and render the full colour-engine decision tree in Style Guide drill-downs.

### 4.1 Backend changes

**New file:** `Cosmic Fit/InterpretationEngine/BlueprintDiagnostics.swift`

```swift
struct BlueprintDiagnosticReport: Codable, Equatable {
    let chartInput: BirthChartColourInput
    let boundaryFlags: [ChartInputAdapter.BoundaryFlag]
    let familyDecisionTrace: FamilyDecisionTrace
    let accentSlots: [AccentSlot]
}

struct BlueprintComposeResult: Equatable {
    let blueprint: CosmicBlueprint
    let diagnostics: BlueprintDiagnosticReport
}
```

**`BlueprintComposer`:**
- `compose(...)` → unchanged return type (`CosmicBlueprint`) for iOS app
- `composeFull(...)` → `BlueprintComposeResult` for inspector

**`InspectorEngine`:**
- Caches `blueprintDiagnostics` alongside blueprint per `profileHash`
- Uses `composeFull` on first compose; `invalidateBlueprint` clears both caches

**`InspectorResponse`:**
- Added `blueprintDiagnostics: BlueprintDiagnosticReport?`

### 4.2 UI changes

New helpers in `app.js`:
- `buildFamilyDecisionTraceSteps(ctx, options)` — 6–7 numbered steps
- `renderChartInputTable`, `renderNormalizedDriversTable`, `renderRawVariableScoresTable`, etc.
- Style Guide drill functions prepend decision tree steps before output/provenance steps
- Trace tab: `buildBlueprintDiagnosticsAccordion()` at top of `buildTraceHtml()`

### 4.3 Test

`inspector/Tests/InspectorEngineTests/DailyFitEngineRegistryInspectorTests.swift`:
- `testInspectResponseIncludesBlueprintDiagnostics()` — asserts `familyDecisionTrace` and non-empty normalized drivers

### 4.4 What Phase 2 deliberately did NOT include

- Per-texture / per-pattern scoring at Style Guide compose (still shows honest “not yet serialized” note on blueprint texture/pattern drill)
- Narrative selection decision tree (`ArchetypeKeyGenerator`, narrative cache fallback) — only colour engine
- Changes to production `CosmicBlueprint` model (diagnostics are inspector-only, not persisted in app blueprint)

---

## 5. Phase 3 — Per-planet energy attribution (shipped)

**Goal:** When clicking a **vibe bar**, **essence row**, or **transit row**, show which **specific inputs** (each transit aspect, each natal planet, lunar phase bucket, current Sun element) contributed how much to **each energy** — not just aggregate source shares.

### 5.1 Problem statement

Today `DailyFitDiagnosticReport` exposes:

| Field | What it tells you | What it doesn't tell you |
|-------|-------------------|--------------------------|
| `sourceContributions` | “Transits = 32% of total raw energy mass” | Which transit, which energy |
| `rawEnergyScores` / `postMultiplierScores` | Final per-energy totals | Decomposition by source |
| `transitSummaries` | Top transits by orb/strength | Per-energy contribution of each |

Example question Ash needs answered across a 14-day compare:

> “Day 3 Edge is 4.2 vs Day 4 Edge is 6.1 — which transits or lunar shift caused the delta?”

Phase 3 makes that answerable without reading Swift or running console logs.

### 5.2 Current Stage 1 accumulation (reference)

All logic in `DailyEnergyEngine.swift`:

| Source | Function | Weight key |
|--------|----------|------------|
| Natal chart planets | `accumulateChartContribution` | `calibration.sourceWeights.natal` |
| Progressed chart | same | `.progressed` |
| Transit aspects | `accumulateTransitContribution` | `.transits` |
| Lunar phase | `accumulateLunarContribution` | `.lunarPhase` |
| Current Sun element | `accumulateCurrentSunContribution` | `.currentSun` |

**Transit per-energy formula** (simplified):

```
contribution = planetEnergyBase[transitPlanet][energy]
             × orbStrength
             × (hard/soft aspect multiplier)
             × sourceWeights.transits
```

**Post-processing:** Sun-sign multipliers from `calibration.signEnergyMap` applied to all energies after accumulation (`applySignMultipliers`).

**Stage 1 experimental:** Separate sky-only vs chart-anchor vibe paths (`stage1SkySourceWeights`, `generatePartialVibeProfileWithRaw`). Phase 3 traces must respect the active engine mode — attribute the scores that actually feed the payload, not always the legacy full mix.

### 5.3 Proposed backend types

Add to `DailyFitDiagnostics.swift` (or new `DailyFitEnergyAttribution.swift`):

```swift
/// One line item: a specific input's contribution to one energy.
struct EnergyAttributionEntry: Codable, Equatable {
    let source: String           // "natal" | "progressed" | "transit" | "lunar" | "currentSun"
    let label: String            // "Mars square Moon", "Venus in Scorpio", "Waxing Gibbous", ...
    let energy: String           // Energy.rawValue
    let rawContribution: Double  // before sign multiplier
    let weightedContribution: Double // after source weight (+ aspect modifiers for transits)
}

/// Per-energy rollup with top contributors.
struct EnergyAttributionBreakdown: Codable, Equatable {
    let energy: String
    let totalRaw: Double
    let totalPostMultiplier: Double
    let entries: [EnergyAttributionEntry]  // sorted by abs(weightedContribution) desc
}

struct Stage1AttributionTrace: Codable, Equatable {
    let byEnergy: [EnergyAttributionBreakdown]   // 6 energies
    let signMultiplierApplied: [String: Double]  // energy → multiplier (from sun sign)
    let engineMode: String                       // "standard" | "stage1Experimental"
}
```

Extend `DailyFitDiagnosticReport`:

```swift
let stage1Attribution: Stage1AttributionTrace?  // optional for back-compat; populate always in generator
```

### 5.4 Implementation approach (recommended)

**Step 1 — Instrument accumulation without changing production scores**

Refactor `generateSnapshotWithTrace` to optionally collect attribution entries while looping. Pattern:

```swift
private static func accumulateTransitContribution(
    transits: [...],
    weight: Double,
    into scores: inout [Energy: Double],
    attribution: inout [EnergyAttributionEntry]? = nil  // nil in production path
)
```

When `attribution != nil`, for each `(transit, energy)` pair append an entry with:
- `source: "transit"`
- `label: "\(transit.transitPlanet) \(transit.aspectType) \(transit.natalPlanet)"`
- `rawContribution`, `weightedContribution`

Repeat for natal (label = `"Venus in Scorpio"`), progressed, lunar (label = phase name), current Sun (label = element).

**Step 2 — Capture sign multiplier as separate attribution step**

After accumulation, record multipliers per energy. Either:
- Add synthetic entries with `source: "signMultiplier"`, or
- Store in `signMultiplierApplied` and show as a dedicated drawer step (“Sun in Scorpio multipliers”).

**Step 3 — Wire through `DailyFitDiagnostics.generateReport`**

Map collected entries → `Stage1AttributionTrace` → `DailyFitDiagnosticReport.stage1Attribution`.

**Step 4 — Stage 1 experimental branch**

When `effectiveMode == .stage1Experimental`, attribute the **sky-only** mix that produces `skyVibe` / `vibeProfile`, not the legacy weighted sum. The trace should document which weight profile was used (`stage1SkySourceWeights` vs full weights).

**Step 5 — Do NOT change `generateSnapshot` production path**

Production app calls `generateSnapshot` without trace. Only `generateSnapshotWithTrace` (inspector / tests) pays the attribution cost.

### 5.5 UI changes (`app.js`)

**New helpers:**

```javascript
function renderEnergyAttributionTable(breakdown, highlightEnergy = null) { ... }
function renderEnergyAttributionForTransit(attribution, transitPlanet) { ... }
function buildStage1AttributionSteps(ctx, highlightEnergy = null) { ... }
```

**Update drill functions:**

| Drill | Add steps |
|-------|-----------|
| `renderVibeDrill(energy)` | Insert “Per-input attribution” step with `byEnergy` filtered/highlighted for clicked energy; show top 10 contributors |
| `renderEssenceDrill(category)` | Map essence category → underlying energies (document mapping or use postMultiplier as proxy); show attribution for dominant contributing energies |
| `renderTransitDrill(planet)` | New step: “Energy impact of this transit” — filter entries where `source === "transit"` and label contains planet; table of energy → contribution |

**Trace tab:**

Add accordion **“Stage 1 · Per-input energy attribution”** — matrix or six sub-accordions (one per energy).

### 5.6 Acceptance criteria

Use preset **Briar** (or Ash), **14-day compare**, engine **`stage1_experimental`**:

1. Click **Edge vibe bar** on two different days → drawer shows different top transit contributors (not identical tables).
2. Click **Mars transit row** → see non-zero Edge/Drama contributions when Mars is transiting.
3. `sourceContributions.transitShare` roughly matches sum of transit attribution entries / total (sanity check, tolerance ±5%).
4. Compare engines on same date → attribution differs when sky weights differ.
5. Inspector tests: decode `stage1Attribution.byEnergy` non-empty for a preset inspect response.
6. **No change** to production `DailyFitPayload` values for same inputs (attribution is read-only instrumentation).

### 5.7 Files to touch

| File | Change |
|------|--------|
| `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` | Instrument `accumulate*` functions; extend `SnapshotTrace` |
| `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` | New types; map trace → report |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Drill + trace UI |
| `inspector/Tests/InspectorEngineTests/` | New test for attribution presence |

### 5.8 Pitfalls

- **Sign multipliers:** Attribution “before multiplier” vs “after” must be labeled clearly or totals won't reconcile with `rawEnergyScores` / `postMultiplierScores`.
- **Double-counting:** Natal + progressed both iterate planets — labels must distinguish them.
- **Stage 1 experimental:** Sky-only path uses different weights; attributing the legacy mix while displaying sky vibe is misleading.
- **Performance:** Attribution only in diagnostic path; cap entries per energy (e.g. top 20) if needed.
- **Inspector symlink:** Edit `Cosmic Fit/InterpretationEngine/` — verify with `./run-inspector.sh`.

---

## 6. Future phases (4–7)

These are **not started**. Listed in priority order after Phase 3.

### Phase 4 — Per-colour feature vectors (Daily Fit Stage 2 palette)

**Problem:** `paletteSelectionTrace.topScoredColours` shows name / role / score — not which energies or axes drove each candidate.

**Work:**
- Extend `PayloadTrace.paletteTrace` in `BlueprintLensEngine.selectDailyPalette` to record per-candidate feature breakdown (energy alignment terms, role bonus, jitter draw).
- Add `PaletteCandidateTrace` to `DailyFitDiagnosticReport`.
- Update `renderDailyColourDrill` step “Scoring & selection” to show expandable feature rows.

**Reference:** `docs/handoff/daily_fit_palette_selection_handoff.md` (palette algorithm direction — separate from this observability work, but traces help validate palette changes).

### Phase 5 — Silhouette intermediate terms

**Problem:** `silhouetteTrace` has baseline + final only (`baselineMF`, `finalMF`, …). No per-energy or per-axis nudges.

**Work:**
- In `deriveSilhouetteProfile`, capture intermediate modulation terms (which vibe energies nudged M/F, A/R, S/D).
- Extend `SilhouetteDerivationTrace` with e.g. `modulationTerms: [SilhouetteModulationEntry]`.
- Update `renderSilhouetteDrill` with a “Modulation breakdown” step.

### Phase 6 — Style Guide non-palette traces

**Problem:** Blueprint texture/pattern/hardware tags still show “traces not yet serialized.”

**Work:**
- At `BlueprintComposer.composeFull`, capture `DeterministicResolver` ranking/scoring for textures, patterns, metals, stones.
- Extend `BlueprintDiagnosticReport` with resolver traces (similar to `FamilyDecisionTrace` pattern).
- Update `renderBlueprintTagDrill` for texture/pattern.

**Reference:** `#if DEBUG logBlueprintDiagnostics` in `BlueprintComposer.swift` — console decision tree for narrative, hardware, textures; promote relevant sections to structured Codable.

### Phase 7 — Linked derivation graph

**Problem:** Flat report — can't click “Deep Autumn selected” → “warmth +2 from Venus in Taurus.”

**Work:**
- Optional `DerivationNode` graph: `{ id, title, detail, parentIds, childIds }`.
- Drawer steps link to child nodes (in-drawer navigation or expand-in-place).
- Higher effort; defer until Phases 3–6 stable.

---

## 7. Related documents

| Document | Relevance |
|----------|-----------|
| `docs/local_cosmicfit_inspector_web_spec.md` | Original inspector product spec — “explain why” |
| `docs/handoff/daily_fit_sky_forward_v2_implementation_spec.md` | Stage 1 experimental engine — Phase 3 must attribute sky-only path correctly |
| `docs/handoff/daily_fit_palette_selection_handoff.md` | Palette selection direction — Phase 4 traces support validation |
| `inspector/README.md` | Run instructions, compare modes, verdicts |
| `README.md` § Inspector | High-level overview |

---

## 8. Verification checklist (any phase)

- [ ] `./run-inspector.sh` — server starts, **Built:** timestamp updates
- [ ] Load preset, click drill targets, drawer opens with numbered steps
- [ ] Compare days carousel — drill resolves correct date from pane
- [ ] Compare engines — drill resolves correct `dailyFitEngineId`
- [ ] Trace & Provenance tab shows new accordions
- [ ] `swift test` in `inspector/` compiles (XCTest discovery may report 0 tests in some environments; ensure build succeeds)
- [ ] Production app blueprint compose unchanged (`BlueprintComposer.compose` signature stable)

---

## 9. Quick reference — key symbols

| Symbol | Location |
|--------|----------|
| `FamilyDecisionTrace` | `ColourEngineV4/Domain.swift` |
| `BlueprintDiagnosticReport` | `BlueprintDiagnostics.swift` |
| `DailyFitDiagnosticReport` | `DailyFitDiagnostics.swift` |
| `SnapshotTrace` | `DailyEnergyEngine.swift` (~line 462) |
| `PayloadTrace` | `BlueprintLensEngine.swift` (~line 333) |
| `openDrill` / `buildFamilyDecisionTraceSteps` | `inspector/.../Web/app.js` |
| `InspectorEngine.resolve` | `InspectorEngine.swift` |

---

**Handoff complete.** Phase 3 executor should start with §5.4 Step 1 (instrument `accumulateTransitContribution`), add tests, then UI. Ask Ash if essence→energy mapping for Phase 3 essence drill is ambiguous — may need a small lookup table in `BlueprintLensEngine` or `DailyFitTypes`.
