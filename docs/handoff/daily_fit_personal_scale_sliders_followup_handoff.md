# Daily Fit — Personal Scale Sliders Follow-Up (Architecture & Cleanup)

**Status:** Follow-up handoff — post-implementation audit  
**Date:** 2026-05-23  
**Audience:** Engineer or AI agent doing thoughtful refactor / sign-off work  
**Scope:** Resolve five known gaps from the initial Personal Scale Sliders implementation. **Out of scope:** changing `deriveVibrancy` / `deriveContrast` / `deriveMetalTone` formulas, production calibration promotion, new user-facing copy.

**Primary spec (already implemented):**

| Doc | Role |
|-----|------|
| [`daily_fit_personal_scale_sliders_handoff.md`](./daily_fit_personal_scale_sliders_handoff.md) | Original feature spec — §6, §8, §10, §13 |

**Related docs:**

| Doc | Role |
|-----|------|
| [`daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](./daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md) | Soften caps (`softenVibrancyCap`, `softenContrastCap`) |
| [`daily_fit_narrative_tarot_bridge_handoff.md`](./daily_fit_narrative_tarot_bridge_handoff.md) | Interleaved tarot bridge work in same working tree |
| [`daily_fit_stage1_experimental_app_readiness_handoff.md`](./daily_fit_stage1_experimental_app_readiness_handoff.md) | Stage 1 app / inspector parity |

---

## 0. Context — what already landed

The Personal Scale Sliders feature is **functionally complete** and testable in Xcode + Inspector:

- **Engine:** `PersonalScaleEnvelope.swift` computes `floor`, `ceiling`, `baseline`, `displayPosition`, `baselinePosition` per scale.
- **Payload:** `DailyFitPayload.scalePresentation: PersonalScalePresentation?` (optional Codable).
- **UI:** `DailyFitViewController` uses `displayPosition` when presentation is present; legacy fallback preserved.
- **Inspector:** Personal envelope rows in Scale Derivation Traces + optional `display_position_in_range` verdict.
- **Tests:** P1–P10, I1–I5, U1–U2 implemented; full suite ~485 pass (4 pre-existing tarot recency failures unrelated).

**Engine safety confirmed:** No changes to production/legacy derivation formulas or calibration constants. Envelope math is display-only and mode-aware via read-only inputs.

**This handoff is not a re-implementation.** It is refactor, spec alignment, and PR hygiene for known audit findings.

---

## 1. Implementation handoff prompt (copy-paste)

```
Read docs/handoff/daily_fit_personal_scale_sliders_followup_handoff.md in full before coding.

Mission: Resolve the five follow-up items (§2–§6) from the post-implementation audit.
Do not re-implement Personal Scale Sliders from scratch.

Hard constraints (unchanged from original spec):
- DISPLAY ONLY — do not change deriveVibrancy, deriveContrast, or deriveMetalTone.
- Do not modify production calibration or engine fingerprints.
- Envelope math stays in PersonalScaleEnvelope.swift — not in DailyFitViewController.
- Legacy payloads without scalePresentation must still render (absolute fallback + metal 3-snap).

Deliver in order:
1. PR split / commit hygiene (§6) — if not already done
2. Shared vibrancy constants (§4) — low risk, do first
3. Baseline tick Auto Layout fix (§5) — UI-only
4. Soften cap architecture decision + implementation (§2) — requires product/spec choice
5. I4 threshold alignment (§3) — depends on §2 outcome

Stop and run after each item:
- PersonalScaleEnvelope_Tests
- PersonalScaleEnvelope_Integration_Tests (I4, I5)
- DailyFitUIIntegration_Tests (U1, U2)
- DailyFitSkyForwardV2_ProductionSafety_Tests (fingerprint guard)

Inspector: cd inspector && swift build (or ./run-inspector.sh)
```

---

## 2. Issue 1 — Soften cap deviation (spec §6.2, §15 Q1)

### Problem

The original spec recommends applying narrative soften caps to envelope ceilings when `narrativeSelection != nil`:

```swift
// Spec §6.2 / §6.3 (conservative v1 default per §15 Q1)
if narrativeSelection != nil {
    contrastCeiling = min(contrastCeiling, softenContrastCap)  // 0.70
    vibrancyCeiling = min(vibrancyCeiling, softenVibrancyCap)  // 0.72
}
```

**Current implementation:** Soften caps were **removed** from `PersonalScaleEnvelopeCalculator` because Briar (high contrast, baseline 0.75) produced a degenerate envelope:

| Scale | Analytical range | After soften cap |
|-------|------------------|------------------|
| Contrast (Briar, stage1) | floor ≈ 0.629, ceiling ≈ 0.871 | ceiling clamped to **0.70** → width ≈ 0.071 |
| Contrast display (14-day) | — | All days pegged at **displayPosition = 1.0** |

Removing the cap made I4/I5 pass but diverges from spec Q1 ("default for v1: **Yes**") and allows diamonds to sit at the far right on soften-heavy profiles — the scenario Q1 was meant to prevent.

### Why this is hard

There are **two different "soften" concepts**:

1. **Runtime narrative directive** — `ScaleDirective` from `NarrativeIntentEngine` caps the **absolute** engine output on soften days (`deriveContrast` / `deriveVibrancy` call sites).
2. **Envelope soften cap** — A **static** ceiling on the personal display band derived from calibration tunables, applied unconditionally when `narrativeSelection != nil`.

The envelope cap is not day-specific. A high-contrast user gets a permanently narrow ceiling even on non-soften days. That may be intentional (conservative band) or wrong (band should reflect full analytical range).

### Recommended architecture options

Evaluate these **before** coding. Pick one and document the decision in code comments + test names.

#### Option A — Restore spec default (unconditional soften cap)

Re-apply caps in `PersonalScaleEnvelope.swift` exactly as spec §6.2.

**Pros:** Spec-compliant; conservative ceiling prevents unreachable right-edge on soften profiles.  
**Cons:** Briar high-contrast envelope becomes very narrow; I5 may fail again unless contrast absolute values stay below cap.  
**Mitigation:** Accept narrow band as correct product behaviour (§8.2: high-contrast users shouldn't see far-left anyway). Update I5 to assert meaningful spread *within* the capped band, not ≥3 globally distinct positions at ceiling.

#### Option B — Conditional soften cap (relationship-aware envelope)

Pass narrative relationship (or resolved intent) into `makePresentation()` and apply cap **only when relationship == .soften**:

```swift
static func makePresentation(
    ...,
    narrativeRelationship: NarrativeRelationship? = nil
) -> PersonalScalePresentation
```

**Pros:** Aligns envelope with actual engine behaviour; full band on reinforce/stretch days.  
**Cons:** Envelope becomes **day-varying** (not stable per blueprint+engine as spec §6 intro states). UI baseline tick position could shift day-to-day. Requires pipeline wiring from `NarrativeIntentEngine` into envelope calculator.

#### Option C — Hybrid: analytical ceiling + soften cap only when it doesn't degenerate

```swift
let analyticalCeiling = clamp01(baseline + maxModulation)
if calibration.narrativeSelection != nil {
    let capped = min(analyticalCeiling, softenContrastCap)
    ceiling = (capped - floor >= epsilon) ? capped : analyticalCeiling
}
```

**Pros:** Honors Q1 when safe; avoids degenerate [floor, ceiling] collapse.  
**Cons:** Implicit heuristic; not in original spec; needs explicit test matrix.

#### Option D — Keep current (no soften cap in envelope) + update spec

Treat soften caps as **absolute-output-only** (runtime directive), not envelope bounds. Update spec §6.2, §15 Q1, P10, and handoff acceptance criteria to match.

**Pros:** Simplest; best display spread for high-contrast profiles; tests already green.  
**Cons:** Product sign-off required; contradicts written spec default.

### Files to touch

| File | Change |
|------|--------|
| `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` | Restore / conditional / hybrid cap logic |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | If Option B: pass intent relationship into `makePresentation` |
| `Cosmic FitTests/PersonalScaleEnvelope_Tests.swift` | P10 currently asserts cap **not** applied — rewrite per chosen option |
| `Cosmic FitTests/DailyFitSkyForwardV2_Tests.swift` | I4/I5 may need threshold or assertion updates |
| `docs/handoff/daily_fit_personal_scale_sliders_handoff.md` | If Option D: amend §6.2 / §15 Q1 (only with Ash sign-off) |

### Acceptance criteria (pick one path)

- [ ] Decision recorded in code comment at cap site (which option, why)
- [ ] P10 matches chosen behaviour
- [ ] I5: ≥3 distinct contrast display positions OR documented exception for high-contrast capped band
- [ ] Inspector trace shows ceiling consistent with implementation
- [ ] No change to absolute `payload.contrast` / `payload.vibrancy` values

---

## 3. Issue 2 — I4 threshold lowered (spec >0.05, test >0.02)

### Problem

Spec §10.2 / §13:

> metal `displayPosition` stddev **> 0.05** (proves snap removal would matter)

**Current test** (`DailyFitSkyForwardV2_Tests.swift`, `briar14DayMetalDisplayStddev`):

- Threshold: `stddev > 0.02`
- Observed: **stddev ≈ 0.0298** (would fail at 0.05)
- Also asserts: `distinctCount >= 3`

Metal envelope for Briar stage1: floor ≈ 0.275, ceiling ≈ 1.0 (wide). Absolute metal variation over 14 days is modest (~0.437–0.728 per spec §3.2), so display spread is diluted across a 0.725-wide band.

### Recommended approach

**Do not blindly restore 0.05** without fixing envelope semantics (Issue 1). Options:

1. **If Option A/C for soften cap:** Re-measure stddev; may still be <0.05 — consider asserting **distinct positions ≥ 3** as primary gate and stddev as secondary.
2. **If Option D (no cap):** Current 0.0298 may still be <0.05. Either:
   - Narrow metal envelope (e.g. use tighter nudge bounds for display only — **risky**, don't change deriveMetalTone), or
   - Revise spec threshold to **>0.02** with rationale: "proves snap removal matters" satisfied by ≥3 distinct positions + stddev >0.02.
3. **Split assertion:**
   ```swift
   #expect(distinctCount >= 3)           // primary: not stuck at snap centre
   #expect(stddev > 0.02)                // secondary: measurable spread
   // Optional aspirational: stddev > 0.05 when envelope width < 0.5
   ```

### Files to touch

| File | Change |
|------|--------|
| `Cosmic FitTests/DailyFitSkyForwardV2_Tests.swift` | Align I4 threshold + comments with Issue 1 decision |
| Spec (optional) | Update §10.2 I4 if product accepts 0.02 |

### Acceptance criteria

- [ ] I4 test name and assertion match documented product intent
- [ ] Test failure message prints stddev, distinct count, and envelope floor/ceiling for debugging
- [ ] §13 "no metal day stuck at centre by snap" verified by distinct positions, not stddev alone

---

## 4. Issue 3 — Hardcoded vibrancy modulation constants (DRY / maintenance)

### Problem

Stage 1 vibrancy envelope in `PersonalScaleEnvelope.swift` duplicates magic numbers from `BlueprintLensEngine.deriveVibrancy`:

| Constant | Envelope (`PersonalScaleEnvelope.swift`) | Engine (`BlueprintLensEngine.swift`) |
|----------|------------------------------------------|--------------------------------------|
| Vibe scale | `0.80` | `(push - pull) * 0.80` (line ~1086) |
| Tempo scale | `0.30` | `(tempo/10 - 0.5) * 0.30` (line ~1087) |
| Tempo min norm | `0.1` (in `(0.1 - 0.5) * 0.30`) | Implicit via sigmoid axis floor |

If engine coefficients change, envelope bounds drift silently → wrong display positions.

### Recommended refactor

Extract shared stage1 vibrancy sensitivity constants to a single location. Prefer **minimal scope**:

#### Option 1 — Private nested enum on `BlueprintLensEngine` (preferred)

```swift
// BlueprintLensEngine.swift
enum Stage1VibrancySensitivity {
    static let vibeScale: Double = 0.80
    static let tempoScale: Double = 0.30
    static let tempoNormMin: Double = 0.1  // sigmoid lower bound for envelope extrema
    static let tempoNormMax: Double = 1.0
}
```

Use in both `deriveVibrancy` and `PersonalScaleEnvelopeCalculator.vibrancyEnvelope`.

#### Option 2 — Add to `DailyFitCalibration.Stage2Sensitivity`

Only if these are intended to be tunable per engine preset. **Avoid** unless calibration team wants them in fingerprint.

#### Option 3 — Comment-only (minimum)

If extraction is deferred, add cross-reference comments at both sites:

```swift
// Must match BlueprintLensEngine.deriveVibrancy stage1: vibe * 0.80, tempo * 0.30
```

### Also consider

- **Contrast stage1:** Envelope uses `-0.22 * coeff` / `+0.22 * coeff`; engine uses `((visNorm-0.5)*0.6 + (strNorm-0.5)*0.4) * coeff`. Verify 0.22 remains correct if axis blend weights change.
- **Metal tone:** `nudgeCap` 0.30 / `lunarMetalMaxAbs` 0.075 duplicated between envelope and `deriveMetalTone` — same DRY treatment.

### Files to touch

| File | Change |
|------|--------|
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Extract constants; use in deriveVibrancy / deriveMetalTone |
| `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` | Import shared constants for envelope extrema |
| `Cosmic FitTests/PersonalScaleEnvelope_Tests.swift` | P2/P9 still pass; optional test that envelope max modulation matches engine formula |

### Acceptance criteria

- [ ] Single source of truth for stage1 vibrancy `0.80` / `0.30` (and ideally metal nudge caps)
- [ ] No change to computed absolute vibrancy values for fixed inputs (regression)
- [ ] P1, P2, P9 still green

---

## 5. Issue 4 — Baseline tick height in Auto Layout context

### Problem

`DailyFitViewController.makeBaselineTick(on:)` creates a tick with:

```swift
tick.frame = CGRect(x: 0, y: 0, width: 2, height: track.bounds.height > 0 ? track.bounds.height : 6)
tick.autoresizingMask = [.flexibleHeight]
```

Tracks use Auto Layout (`translatesAutoresizingMaskIntoConstraints = false`). `autoresizingMask` does not reliably resize subviews when the parent uses constraints. At setup time, `track.bounds.height` is often **0**, so tick height defaults to **6pt** and may never match track height after layout.

Horizontal positioning in `updateBaselineTick` uses `center.x` — correct for 2pt width.

### Recommended refactor

Replace frame + autoresizingMask with constraints:

```swift
private func makeBaselineTick(on track: UIView) -> UIView {
    let tick = UIView()
    tick.translatesAutoresizingMaskIntoConstraints = false
    tick.backgroundColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5)
    tick.isHidden = true
    track.addSubview(tick)
    NSLayoutConstraint.activate([
        tick.widthAnchor.constraint(equalToConstant: 2),
        tick.topAnchor.constraint(equalTo: track.topAnchor),
        tick.bottomAnchor.constraint(equalTo: track.bottomAnchor),
        // centerX set in updateBaselineTick via constraint stored on tick
    ])
    return tick
}
```

Store `centerXConstraint` per tick (or use `leadingAnchor` + constant updated in `updateBaselineTick`) instead of mutating `center.x`.

### Files to touch

| File | Change |
|------|--------|
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | Constraint-based tick; optional stored `NSLayoutConstraint?` for horizontal position |

### Acceptance criteria

- [ ] Baseline tick visually spans full track height after layout on device/simulator
- [ ] Tick position updates correctly in `viewDidLayoutSubviews` / `refreshDiamondScalePositions`
- [ ] Legacy path still hides ticks
- [ ] No new user-facing copy

### Manual QA

Build in Xcode → Daily Fit screen → verify tick height matches gradient track on vibrancy, contrast, and metal tone rows.

---

## 6. Issue 5 — Interleaved tarot bridge changes (PR / commit hygiene)

### Problem

The working tree mixes **two features**:

| Feature | Key files |
|---------|-----------|
| **Personal Scale Sliders** | `PersonalScaleEnvelope.swift`, `PersonalScaleEnvelope_Tests.swift`, UI baseline tick, `scalePresentation` on payload, inspector personal rows |
| **Narrative Tarot Bridge** | `NarrativeTarotBridgeSelector.swift`, `NarrativeTarotBridge_Tests.swift`, `TarotSelectionResult`, `NarrativeBridgeTrace`, `selectTarotAndStyleEditWithBridgeTrace`, bridge tunables on `NarrativeSelectionTuning` |

Both are **stage1-experimental-only** for engine changes; production tarot path is preserved. But merging as one PR obscures review and bisect.

### Recommended split

#### PR 1 — Personal Scale Sliders (merge first)

**Include:**

- `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` (new)
- `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` — **only** `scalePresentation` + related Codable/init/copy changes
- `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` — **only** `makePresentation` wiring + `scalePresentation` on payload (cherry-pick hunks)
- `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` — **only** `personalScalePresentation`
- `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` — display remap + baseline tick
- `Cosmic FitTests/PersonalScaleEnvelope_Tests.swift` (new)
- `Cosmic FitTests/DailyFitTypes_Tests.swift` — I2/I3
- `Cosmic FitTests/DailyFitSkyForwardV2_Tests.swift` — I1/I4/I5 integration block only
- `Cosmic FitTests/DailyFitUIIntegration_Tests.swift` — U1/U2
- `inspector/.../VerdictRunner.swift` — **only** `checkDisplayPositionRange`
- `inspector/.../Web/app.js` — **only** personal scale trace rows

**Exclude:** All tarot bridge files and bridge-related diffs in shared files.

#### PR 2 — Narrative Tarot Bridge

**Include:**

- `NarrativeTarotBridgeSelector.swift` (new)
- `NarrativeTarotBridge_Tests.swift` (new)
- `BlueprintLensEngine.swift` — tarot selection refactor
- `DailyFitTypes.swift` — `NarrativeBridgeTrace`, bridge tunables, coherence trace fields
- `DailyFitPipeline.swift`, `DailyFitDiagnostics.swift` — bridge trace wiring
- `NarrativeSelectionDirectives.swift`, `TarotCard.swift` (Equatable)
- `DailyFitEngineRegistry.swift` — fingerprint string extension
- Inspector bridge markdown rows (if not in PR 1)

### How to split

```bash
# Example: create scale-only branch from current work
git stash
git checkout -b feature/personal-scale-sliders
# Apply/cherry-pick only scale-related files
# Run tests (see §7)
git checkout -b feature/narrative-tarot-bridge
# Apply bridge files on top of main or after PR1 merges
```

If history is already one messy commit, use `git add -p` or manual file checkout from a patch.

### Acceptance criteria

- [ ] Two reviewable PRs with clear titles and test plans
- [ ] PR1 does not reference `NarrativeTarotBridgeSelector`
- [ ] PR2 does not change `PersonalScaleEnvelope` behaviour
- [ ] Production fingerprint tests still pass after each PR

---

## 7. Verification checklist (run before sign-off)

### Unit / integration

```bash
xcodebuild test -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
  -only-testing:"Cosmic FitTests/PersonalScaleEnvelopeTests" \
  -only-testing:"Cosmic FitTests/PersonalScaleEnvelope_Integration_Tests" \
  -only-testing:"Cosmic FitTests/DailyFitUIIntegrationTests" \
  -only-testing:"Cosmic FitTests/DailyFitSkyForwardV2_ProductionSafety_Tests" \
  -disable-concurrent-testing
```

### Inspector

```bash
cd inspector && swift build
# or ./run-inspector.sh — verify Scale Derivation Traces show personal floor/ceiling/display
```

### Manual app QA

- [ ] Diamonds move on personal track (not all metal at centre)
- [ ] Baseline ticks visible and full-height on all three scales
- [ ] Legacy payload path: absolute + metal 3-snap, ticks hidden

---

## 8. Suggested priority order

| Priority | Issue | Effort | Risk |
|----------|-------|--------|------|
| 1 | §6 PR split | Medium | Low — process only |
| 2 | §4 Shared constants | Low | Low |
| 3 | §5 Baseline tick AL | Low | Low — UI only |
| 4 | §2 Soften cap decision | High | Medium — product/spec |
| 5 | §3 I4 threshold | Low | Depends on §2 |

**Blocker for §2:** Ash / product must choose Option A, B, C, or D (§2). Do not guess.

---

## 9. File inventory (current working tree)

### Personal Scale Sliders (this feature)

| Path | Notes |
|------|-------|
| `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` | Envelope calculator |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | `scalePresentation` field |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Wired at end of generatePayload* |
| `Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift` | `personalScalePresentation` export |
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | Display remap + ticks |
| `Cosmic FitTests/PersonalScaleEnvelope_Tests.swift` | P1–P10 |
| `Cosmic FitTests/DailyFitSkyForwardV2_Tests.swift` | I1, I4, I5 block |
| `Cosmic FitTests/DailyFitTypes_Tests.swift` | I2, I3 |
| `Cosmic FitTests/DailyFitUIIntegration_Tests.swift` | U1, U2 |
| `inspector/Sources/CosmicFitInspectorLib/VerdictRunner.swift` | display_position_in_range |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Personal trace rows |

### Tarot Bridge (separate — do not conflate)

| Path | Notes |
|------|-------|
| `Cosmic Fit/InterpretationEngine/NarrativeTarotBridgeSelector.swift` | Joint card+variant selection |
| `Cosmic FitTests/NarrativeTarotBridge_Tests.swift` | Bridge tests |
| `docs/handoff/daily_fit_narrative_tarot_bridge_handoff.md` | Bridge spec |

---

## 10. Open question for product owner (Ash)

Before implementing §2, confirm:

> **Should personal scale envelope ceilings use narrative soften caps (spec Q1: Yes), or should soften caps apply only to absolute engine output on soften days?**

Until answered, keep current behaviour (no cap in envelope) or implement Option C as a safe middle ground.

---

## 11. Summary for implementer

1. **Split PRs** — Personal Scale Sliders vs Narrative Tarot Bridge.  
2. **DRY constants** — stage1 vibrancy (and ideally metal) shared between engine and envelope.  
3. **Fix baseline tick** — Auto Layout constraints, not autoresizingMask.  
4. **Resolve soften cap** — product decision required; tests and spec must align.  
5. **Align I4** — threshold follows §2 outcome; distinct positions ≥3 remains the primary snap-removal proof.

Do not change derivation formulas or production calibration. Display-only remapping stays in `PersonalScaleEnvelope.swift`.
