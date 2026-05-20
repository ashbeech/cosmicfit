# Daily Fit Sky Forward — Handoff Document

**Status:** Partially implemented in **`stage1_experimental`** engine only. Production and Legacy Baseline unchanged.  
**Date:** 2026-05-20  
**Audience:** Dave (or any engineer/AI continuing sky-forward Daily Fit work)  
**Related docs:** [`daily_fit_engine_selector_spec.md`](daily_fit_engine_selector_spec.md), [`daily_fit_stage2_calibration_handoff.md`](daily_fit_stage2_calibration_handoff.md)

---

## 1. Executive summary

Daily Fit was reading like a **second Style Guide** — same essence labels, flat silhouette sliders, and stable vibe shape day after day — because **essence, silhouette, and vibe were all derived from a natal-heavy blended signal**. For profiles like Briar (12/11/1984 12:00 London), the top essence categories barely reordered across 14 consecutive days.

The product intent is the opposite:

> **Daily Fit = today's outside energy, anchored to who you are in your chart.**  
> Not “who you are again,” but “the sky is pushing here today — adapt like this.”

Example framing Ash wants in the product:

- **Chart anchor:** “You normally dress structured / masculine.”
- **Today's sky:** “Energy today is softer / more fluid.”
- **Daily Fit output:** “Lean feminine / draped **today** — relative to your baseline.”

**Sky Forward** is the name for this model. It is implemented only on the **`stage1_experimental`** engine preset (`DailyFitEngineMode.stage1Experimental`). Production (`production`) and Legacy Baseline (`legacy_baseline`) still use the standard blended pipeline.

This document explains **why the old approach felt pointless**, **what sky-forward means**, **what code exists today**, **what still doesn't work well enough**, and **what to do next**.

---

## 2. The user feedback that triggered this work

Ash's core complaint (paraphrased from inspection of Briar's 14-day export):

> *"This makes no sense in the context of a daily fit:*
>
> *Essence is derived from the vibe breakdown + axes. Briar's vibe shape is stable (always Drama-dominant, Edge secondary; drama only 5 vs 6). With the same natal/progressed anchor every day, the top categories don't reorder — sensual/minimal/maximalist stay on top, with only small percentage shifts below.*
>
> *He might as well be their star guide one-off communication because if it hardly moves and is always dominated then there's no point in having daily fluctuations because the signal is always gonna be very similar.*
>
> *What we want is outside forces more dominant, always anchored in the user's chart. Flip it so it's talking about the outside energy — not how you are normally according to your chart. It should be: this energy is going on now, and this is how you are, so you should adapt like this (e.g. dress structured/masculine normally, but today dress more feminine)."*

**Translation for engineering:** Daily Fit outputs must be **delta reads** (today vs chart), not **identity reads** (blended natal character re-stated daily).

---

## 3. Why the blended pipeline felt pointless

### 3.1 Single blended signal everywhere

Before sky-forward, the pipeline looked like this for **all engines including Stage 1's early calibration tweaks**:

```
Natal + progressed + transits + lunar + current sun
        ↓  (one weighted blend)
DailyEnergySnapshot.vibeProfile + axes
        ↓
Essence top-3  ← from blended vibe + blended axes
Silhouette     ← from Style Code keywords + blended axes
Palette/tarot  ← from blended vibe + axes + blueprint
```

Essence (`deriveStyleEssenceProfile`) scored 14 categories from **normalized blended vibe** plus **absolute axis values**. Silhouette nudged Style Code keyword baselines using **absolute daily axes**. Neither layer asked “what changed today relative to your chart?”

### 3.2 Natal anchoring + quantization

Even after Stage 2 calibration shipped higher transit/lunar weights in `DailyFitCalibration.default` (production: natal **28%**, transits **35%**), several forces keep daily output static:

| Force | Effect |
|---|---|
| **Natal + progressed + sun-sign multipliers** | Fixed per user; dominate vibe shape for drama-heavy charts |
| **21-point integer quantization** | Small daily raw shifts rarely flip integer counts → identical vibe strings many days |
| **Axis clustering (1–10)** | Many profiles sit near extremes; silhouette nudges clamp to ~1.0 |
| **Essence category thresholds** | Top-3 order stable when underlying vibe order stable |
| **Blueprint ceiling** | Palette drawn from Style Guide pool; signature colours (e.g. black cherry) win repeatedly |
| **Frozen payloads on device** | `DailyFitFrozenPayloadStorage` persists revealed-day payloads across rebuilds |

See [`daily_fit_stage2_calibration_handoff.md`](daily_fit_stage2_calibration_handoff.md) §2 for the full pre-fix symptom table.

### 3.3 Briar as the canonical test profile

| Field | Value |
|---|---|
| Birth | 12/11/1984 12:00, London UK (51.5074, -0.1278) |
| Profile hash | `469108800.0_51.5074_-0.1278` |
| Display name | Briar (deterministic from hash) |
| Sun | ~20° Scorpio |

**Pre sky-forward essence (14 days, Stage 1 calibration, standard mode logic):**

- Vibe: Drama-dominant, Edge secondary; drama integer often 5–6 only
- Essence top-3: sensual / minimal / maximalist — **stable order**, tiny % shifts
- Silhouette M/F often ~1.0 (saturated visibility axis + clamping)
- Palette: black cherry (#751A2F) in ~13/14 days — **not a legacy Style Guide bug**; it's the luminary/ruler **signature colour** in the current blueprint, heavily favoured by drama/statement scoring

**Important palette clarification:** Daily Fit **does** compose a fresh blueprint from the user's chart in inspector. Black cherry persists because it's in the **signature** band and scores well on drama-heavy days — not because an old cached Style Guide palette is leaking.

---

## 4. The sky-forward product model

### 4.1 Two-layer mental model

| Layer | Astrological sources | Product meaning | UI role |
|---|---|---|---|
| **Chart anchor** | Natal + progressed (+ Style Guide / Style Code) | “How you normally show up” | Reference baseline — **not** the daily headline |
| **Today's outside energy** | Transits + lunar phase + current sun | “What's active in the sky right now” | Primary daily signal |
| **Daily Fit output** | **Today relative to anchor** | “Adapt this way today” | Essence top-3, silhouette nudges, copy tone |

### 4.2 Desired user-facing read (not yet fully in app copy)

Production UI still renders essence/silhouette as absolute values. Inspector markdown export now annotates anchor vs today. Longer term, copy and labels should say things like:

- “Your chart baseline: **maximalist · drama · edgy**”
- “Today's adapt signal: **sensual · minimal · polished**”
- “Silhouette: usually structured — **today lean draped/feminine**”

### 4.3 What sky-forward is NOT

- **Not** “make every day dramatic” — amplify **delta from anchor**, not absolute sky intensity
- **Not** “ignore the chart” — chart is the reference frame
- **Not** production-shipped yet — sandbox on `stage1_experimental` only until validated
- **Not** a target of ~90% transits — see §7.3

---

## 5. Architecture: standard vs sky-forward

### 5.1 Pipeline overview

```
Natal + progressed + transits + lunar + date
        ↓
DailyEnergyEngine                    ← mode switch here
        ↓
DailyEnergySnapshot
  • vibeProfile      (blended — tarot/palette path)
  • axes             (daily axes)
  • chartVibeProfile (Stage 1 only — natal+progressed vibe)
  • skyVibeProfile   (Stage 1 only — transits+lunar+current sun vibe)
  • chartAxes        (Stage 1 only — natal+progressed axes, no transits/moon)
        ↓
BlueprintLensEngine                  ← mode switch here
        ↓
DailyFitPayload
  • essenceProfile (today scores + optional chartAnchorScores)
  • silhouetteProfile
  • palette, tarot, vibrancy, contrast, …
```

### 5.2 Engine registry

| Engine ID | Display name | Mode | Purpose |
|---|---|---|---|
| `production` | Production (Stage 2) | `.standard` | Shipped calibration (`.default`) |
| `legacy_baseline` | Legacy Baseline | `.standard` | Pre–Stage 2 regression weights |
| `stage1_experimental` | **Stage 1 Experimental (Sky Forward)** | `.stage1Experimental` | Sky-forward sandbox |

**Source of truth:** `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift`

Stage 1 uses `dailySeedPolicy: .includesEngineId` so RNG differs from production when comparing side-by-side in inspector.

### 5.3 Mode gating rule

All sky-forward behaviour is gated on `DailyFitEngineMode.stage1Experimental`. Production and Legacy never populate `chartVibeProfile`, `skyVibeProfile`, `chartAxes`, or `chartAnchorScores`.

Branch points (central switches — do not scatter preset-id string checks):

- `DailyEnergyEngine.generateVibeProfile` / `generateSnapshot` / `evaluateAxes`
- `BlueprintLensEngine.resolveEssenceProfile` / `deriveSilhouetteProfile`

---

## 6. Implementation detail (what exists today)

### 6.1 Partial source mixes (`DailyEnergyEngine.swift`)

Stage 1 computes **three parallel reads** from the same chart + date:

**Chart vibe** (`stage1ChartSourceWeights`):

| Source | Weight |
|---|---|
| Natal | 0.85 |
| Progressed | 0.15 |
| Transits | 0 |
| Lunar | 0 |
| Current sun | 0 |

Sign multipliers **applied** (natal sun sign).

**Sky vibe** (`stage1SkySourceWeights`):

| Source | Weight |
|---|---|
| Transits | 0.50 |
| Lunar | 0.35 |
| Current sun | 0.15 |
| Natal | 0 |
| Progressed | 0 |

Sign multipliers **not applied** (outside energy, not natal identity).

**Chart axes** (`evaluateChartAnchorAxes`):

- Natal + progressed only
- No transits, moon, or jitter
- Uses production spread (`DailyFitCalibration.default`)

Stored on `DailyEnergySnapshot` as optional fields (nil in standard mode).

### 6.2 Delta-amplified blended vibe (tarot / palette path)

For Stage 1, the main `vibeProfile` (used by palette/tarot selection) is **not** a plain weighted blend. It uses:

```
amplified[energy] = max(0, anchor[energy] + 2.75 × (daily[energy] − anchor[energy]))
```

Where:

- **anchor** = production default source weights (`stage1AnchorSourceWeights` = `DailyFitCalibration.default`)
- **daily** = Stage 1 calibration source weights (transit-heavy)

Constant: `stage1VibeDeltaAmplification = 2.75`

Then normalized to 21 integer points.

### 6.3 Delta-amplified axes

For Stage 1 daily axes:

```
axis = clamp(1..10, anchorAxis + 2.25 × (dailyAxis − anchorAxis))
```

- **anchorAxis** = natal+progressed only (production spread)
- **dailyAxis** = full mix including transits, moon, jitter

Constant: `stage1AxisDeltaAmplification = 2.25`

### 6.4 Essence — sky−chart delta scoring (`BlueprintLensEngine.swift`)

Standard mode: `deriveStyleEssenceProfile(from:)` — blended vibe + absolute axes.

Stage 1 mode: `deriveStyleEssenceProfileStage1Experimental(from:)`:

1. Normalize `chartVibeProfile` and `skyVibeProfile`
2. Compute per-energy delta: `4.0 × (sky − chart)`
3. Score 14 essence categories from **delta vibe** (not absolute sky or chart)
4. Add **axis delta** modifiers vs `chartAxes` (visibility/action/strategy), scaled `× 1.6`
5. Add **dominant transit** boost (`0.35` per matching planet→category map)
6. Top 3 from delta scores → `visibleCategories` (today's adapt signal)
7. Separately score chart vibe → `chartAnchorScores` (stable reference)

Constants:

| Constant | Value | Purpose |
|---|---|---|
| `stage1EssenceVibeDeltaAmplification` | 4.0 | Scale sky−chart vibe before category matrix |
| `stage1AxisEssenceMultiplier` | 1.6 | Axis delta influence on categories |
| `stage1TransitEssenceBoost` | 0.35 | Per dominant transit category nudge |

Dispatch: `resolveEssenceProfile(from:mode:)` switches on mode.

### 6.5 Silhouette — Style Code baseline + axis delta

Standard mode: Style Code keyword baseline ± absolute axis nudge.

Stage 1 mode (when `chartAxes` present):

- **Masculine/Feminine:** `mfBase + (visibility_delta × 0.45 × silhouetteAxisScale)`
- **Angular/Rounded:** `arBase + (action_delta × −0.36 × silhouetteAxisScale)`
- **Structured/Draped:** `sdBase + (strategy_delta × −0.45 × silhouetteAxisScale)`

Where `_delta = (daily_axis − chart_axis) / 9.0`.

Style Code keywords (`leanInto`, `consider`, `avoid`) still provide the **chart-identity baseline**; daily sky moves the sliders **relative to that baseline**.

### 6.6 Stage 1 full calibration (registry)

Used for blended daily path + Stage 2 sensitivity in inspector when `stage1_experimental` selected:

| Source | Weight |
|---|---|
| Transits | 0.44 |
| Lunar | 0.30 |
| Natal | 0.16 |
| Progressed | 0.07 |
| Current sun | 0.03 |

Stage 2 sensitivity (vs production): higher `paletteJitter` (0.15), vibrancy/contrast coeffs (0.45), `silhouetteAxisScale` (1.25).

### 6.7 Type changes (`DailyFitTypes.swift`)

`DailyEnergySnapshot` additions:

- `chartVibeProfile: VibeBreakdown?`
- `skyVibeProfile: VibeBreakdown?`
- `chartAxes: DerivedAxes?`

`StyleEssenceProfile` addition:

- `chartAnchorScores: [StyleEssenceScore]?` — chart baseline essence; nil in production

### 6.8 Inspector UI (`inspector/.../Web/app.js`)

Implemented in this conversation thread:

- **Multi-day compare export** — markdown export includes all days in compare range (not just target day)
- **Essence table** — when `chartAnchorScores` present: columns **Today | Chart anchor | markers**
  - ★ = top 3 today (adapt signal)
  - ◆ = top 3 on chart anchor
  - · adapt = category in today's top 3 but not chart top 3
- **Markdown export** includes anchor column and explanatory subtitle

**To validate:** restart inspector server, select `Stage 1 Experimental (Sky Forward)`, run Briar 14-day compare, re-export.

### 6.9 Tests updated

- `Cosmic FitTests/DailyFitEngineRegistry_Tests.swift` — sky-forward descriptor, mode, fingerprint
- `Cosmic FitTests/DailyFitEngineConfig_Tests.swift` — runtime engine override
- `inspector/Tests/.../DailyFitEngineRegistryInspectorTests.swift` — inspector registry parity

---

## 7. Diagnostics & common confusions

### 7.1 Source contributions ≠ configured weights

Inspector **Source contributions** shows **share of accumulated raw score mass**, not configured weights:

```swift
contributions["transits"] = transitTotal / totalRaw
```

Transits loop over **every active aspect** × **all 8 energies** × orb strength. Lunar is one phase vector. Natal is fixed. **~89% transit share on a busy day is emergent, not a design target.**

Configured sky slice transit weight is **50%**, full Stage 1 blend **44%**.

### 7.2 Do high transit shares help daily variation?

**Partially yes:**

- Transits are intentionally the highest-weight **moving** sky input
- They change day-to-day and drive sky vibe + deltas

**But:**

- Essence uses **sky − chart**, not raw transit share
- If transit pile dominates sky shape, you get variation in transit character but **limited reordering** after normalization + top-3 thresholds
- Briar post-fix: chart anchor stable (**drama · maximalist · edgy**); today varies more (**sensual · minimal · polished/eclectic**) but only ~**3 unique top-3 orderings across 14 days**

### 7.3 Black cherry persistence

Not a Style Guide version mismatch. Black cherry is Briar's **signature colour** in the current blueprint. Daily palette scoring favours signature/statement slots when drama/visibility run hot. Fixing “same accent every day” may require **palette selection policy** changes separate from sky-forward essence — e.g. stronger novelty/recency penalty, or decoupling signature from daily statement slot.

---

## 8. Validation snapshot (Briar, Stage 1 Sky Forward, 14 days)

After sky-forward essence + silhouette changes (inspector, engine `stage1_experimental`):

| Surface | Observation |
|---|---|
| **Chart anchor essence** | Stable: drama · maximalist · edgy |
| **Today essence** | Shifts: sensual · minimal · polished/eclectic variants |
| **Unique top-3 orderings** | ~3 / 14 days (better than zero, still subtle) |
| **Silhouette M/F** | Still fairly flat (~1.0) — axis clustering limits delta nudge |
| **Palette** | Black cherry still dominates most days (signature + drama scoring) |
| **Vibe integers** | Still often Drama-dominant; delta amplification helps downstream more than vibe string churn |

**Conclusion:** Sky-forward **direction is correct** and **essence anchor/today split works in inspector**, but **perceived daily variation is still insufficient** for Ash's bar on silhouette, palette, and essence reorder frequency.

---

## 9. Known gaps & recommended next work

### 9.1 P0 — Product framing in app UI (not just inspector)

The iOS Daily Fit card still presents essence/silhouette as absolute values. Dave should:

1. Show **chart anchor vs today** on essence (reuse `chartAnchorScores`)
2. Label top-3 as **“Adapt today”** not generic essence
3. Silhouette: show **baseline tick + today tick** on each bipolar slider
4. Optional narrative line: “Your chart leans X; today's sky suggests Y”

Files likely involved: `DailyFitViewController.swift`, `EssenceTriangleView.swift` (or successor radar), silhouette slider views.

### 9.2 P1 — Tune delta sensitivity

Current knobs (all in engine code, Stage 1 only):

| Knob | Current | Try if still flat |
|---|---|---|
| `stage1EssenceVibeDeltaAmplification` | 4.0 | 5–6 |
| `stage1VibeDeltaAmplification` | 2.75 | 3–3.5 |
| `stage1AxisDeltaAmplification` | 2.25 | 2.5–3 |
| Silhouette delta coeffs | 0.36–0.45 | increase if M/F still clamps |

Use Briar 14-day + Ash real profile exports as regression fixtures. Prefer **compare mode in inspector** (Production vs Stage 1 side-by-side).

### 9.3 P1 — Rebalance sky slice if transit-monoculture

If `skyVibeProfile` is effectively “all transits,” consider:

- Lower transit weight in `stage1SkySourceWeights` (e.g. 0.35 transits / 0.40 lunar / 0.25 sun)
- Cap transit aspects counted toward vibe (top N by orb strength)
- Weight lunar phase more on axis delta (moon moves faster than outer-planet transit pile)

### 9.4 P2 — Palette daily variation (orthogonal but user-visible)

Sky-forward doesn't fix signature colour winning daily. Options:

- Stronger `paletteJitter` / recency penalty for statement slot
- Separate “daily accent” pool from signature band
- Score palette against **sky vibe** or **vibe delta**, not blended drama-heavy vibe only

See `BlueprintLensEngine.selectDailyPalette` and Briar 14-day palette column in export.

### 9.5 P2 — Copy / tarot alignment

Tarot and style-edit copy should eventually reference **adaptation**, not restate identity. Likely needs template or token changes in tarot selection — out of scope for Stage 1 engine work but part of full product story.

### 9.6 P3 — Promote to production

Only after:

- [ ] Consecutive-day UX validated on real profiles (Ash + Briar + synthetic harness)
- [ ] Frozen payload migration strategy for `chartAnchorScores` field (backward compatible — already optional)
- [ ] README + `daily_fit_engine_selector_spec.md` §5.4 updated
- [ ] Explicit sign-off that Production should switch `mode` or merge Stage 1 algorithm into default

**Ash explicitly wanted Stage 1 only for now** — do not flip production without request.

### 9.7 P3 — Update spec doc

[`daily_fit_engine_selector_spec.md`](daily_fit_engine_selector_spec.md) §5.4 still describes Stage 1 as “future.” Update with sky-forward architecture, constants, and promotion checklist.

---

## 10. How to run & test

### Inspector

1. Build/run inspector server
2. Profile: Briar or custom birth data
3. Engine dropdown: **Stage 1 Experimental (Sky Forward)**
4. Enable **Compare** for date range (e.g. 14 days)
5. Export markdown — verify essence anchor column, summary table, multi-day sections

### Device / DEBUG

`DailyFitEngineConfig.runtimeOverrideEngineId = DailyFitEngineRegistry.stage1ExperimentalId` (see `DailyFitEngineConfig_Tests.swift`)

Clear frozen payloads when testing day-to-day churn: `DailyFitFrozenPayloadStorage` (revealed days persist exact payload).

### Unit tests

```bash
# App tests
xcodebuild test -scheme "Cosmic Fit" -only-testing:Cosmic\ FitTests/DailyFitEngineRegistry_Tests

# Inspector tests
cd inspector && swift test --filter DailyFitEngineRegistryInspectorTests
```

---

## 11. Key files (edit map for Dave)

| File | Responsibility |
|---|---|
| `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift` | Engine presets, Stage 1 calibration, display name |
| `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` | Partial profiles, delta vibe/axes, source weights |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Essence delta scoring, silhouette delta, palette |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | Snapshot + essence types |
| `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` | Source contribution breakdown for inspector |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Essence anchor UI, multi-day export |
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | On-device Daily Fit card (needs anchor UI) |
| `Cosmic FitTests/DailyFitEngineRegistry_Tests.swift` | Registry/mode regression |

---

## 12. Design principles (preserve these)

1. **Chart = anchor, sky = headline** — daily outputs describe adaptation, not identity restatement
2. **Delta over absolute** — score from `(today − chart)` wherever the product promise is “what's different today”
3. **Mode gating** — sky-forward stays in `.stage1Experimental` until promoted; production path must not regress
4. **Central switches** — branch on `DailyFitEngineMode`, never on raw engine id strings in engine math
5. **Style Guide stays permanent** — sky-forward changes Daily Fit interpretation, not blueprint composition (unless palette policy explicitly changes)
6. **Inspector first** — validate multi-day compare exports before shipping app UI

---

## 13. Open questions for Ash / product

1. Should **palette** also be sky-forward (score from sky vibe / delta), or stay blueprint-scored with more jitter?
2. Is **~3 essence reorderings / 14 days** enough, or is the bar **most days visibly different top-3**?
3. Should chart anchor appear on the **consumer app card**, or only in inspector/debug until copy is ready?
4. When promoting, merge into **`production`** preset or add a fourth **`sky_forward`** production preset?

---

## 14. Conversation context

This handoff consolidates work from the Cursor session on Daily Fit engine selector audit (P0–P9), Briar export validation, black cherry / palette investigation, and sky-forward Stage 1 implementation. Prior agent transcript: [Daily Fit sky-forward session](c83a5c0e-d60d-4021-92d1-70ea6d6ef40c).

**Uncommitted at handoff time** — changes exist in working tree across engine, inspector, tests, and fixtures; no commit was requested during that session.
