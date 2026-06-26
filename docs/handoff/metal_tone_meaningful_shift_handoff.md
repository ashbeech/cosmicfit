# Metal Tone Meaningful-Shift Gate — Full Handoff

**Date:** 2026-06-24  
**Audience:** AI developer or engineer scoping and implementing the metal tone G2 follow-up  
**Repo:** `/Users/ash/dev/mobile_apps/cosmicfit`  
**Engine:** `stage1_experimental` only (unless product explicitly promotes changes)  
**Status:** Phase 1 continuous UI **reversed by product decision (2026-06-26)** — metal marker restored to 3-point snap on personal-band `displayPosition` in `DailyFitViewController`. G2 engine/envelope work **superseded**. Post-snap cohort artifact: `docs/fixtures/slider_day_variation_report.metal_snap.json` (216×60, 2026-06-26). Metal audit gates: `METAL_GATES` in `tools/verify_slider_gates.py` (unchanged=80.0%, meaningful=20.0%, distinct=2.3).

**Prior status (2026-06-24):** Slider Variation Fix substantially complete — vibrancy + contrast PASS all cohort gates; metal failed G2 meaningful-shift under continuous UI.

**Parent workstream:** Slider Variation Fix (Phases 1–4, June 2026). This handoff covers **only the remaining metal gap**.

---

## 1. Executive summary

Users reported Daily Fit **Metal Tone** (and Contrast) sliders feeling **“stuck for days.”** A measured cohort audit (216 synthetic users × 60 days) confirmed the complaint: pre-fix, **86% of metal day-pairs showed zero UI movement** because the UI collapsed continuous engine values to three snap positions (Cool / Mixed / Warm).

**Phase 1 (metal UI snap removal) fixed the stuck-slider problem.** Post-fix, metal unchanged day-pairs dropped to **8.8%**, distinct UI positions rose from **2.2 → 54.1**, and max stuck streak fell from **26 → 3.7 days**.

**What remains:** Metal still fails the cohort **meaningful-shift gate (G2)**: only **25.9%** of consecutive day-pairs move ≥ 0.05 on the UI track, vs the required **> 45%**. The slider *moves* most days, but movement is usually **too small to feel meaningful** (72% of pairs move < 0.02).

**Your mission:** Design and implement changes so metal tone **PASSes all six binding cohort gates** (§4) without regressing vibrancy or contrast. Contrast tuning is **done — do not reopen** unless metal work accidentally breaks it.

---

## 2. Why this work is critical

### 2.1 User-facing impact

| Symptom | Pre-fix | Post-fix (Phase 1) | Still wrong |
|---------|---------|-------------------|-------------|
| “Slider frozen for weeks” | 100% of users mostly unchanged; p90 max streak **60 days** | 9.3% mostly unchanged; p90 streak **11 days** | **Resolved** |
| “Slider never feels like it shifts meaningfully” | 13.7% meaningful pairs | **25.9%** meaningful pairs | **Still fails** (need > 45%) |
| Partner sees only Cool / Mixed / Warm | 2.2 distinct positions (snap) | 54.1 distinct positions (continuous) | **Resolved** |

The partner brief was validated: contrast and metal **did** match “stuck for days.” Snap removal was necessary and sufficient for **visibility of movement**, but **not sufficient for perceptible daily cadence** matching vibrancy (~69% meaningful) or silhouette sliders (~52% meaningful).

### 2.2 Release gate

Product ship criteria for the Slider Variation Fix require **vibrancy, contrast, and metalTone each PASS all six binding gates** on a full cohort re-run. Currently:

- **Vibrancy:** PASS (no code changes in this workstream)
- **Contrast:** PASS (signal + envelope work complete)
- **Metal tone:** **FAIL G2 only** (5/6 gates pass)

Until metal G2 passes, the workstream is **not shippable** under the agreed plan.

### 2.3 Why G2 failed despite “successful” Phase 1

Two separate problems were conflated in the original audit:

```
┌─────────────────────────────────────────────────────────────────┐
│ Problem A — UI SNAP (Phase 1, FIXED)                            │
│   continuous displayPosition → snapMetalToThreePositions        │
│   → only {0, 0.5, 1} visible → 86% zero UI delta                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Problem B — IMPERCEPTIBLE DELTAS (THIS HANDOFF)                 │
│   Engine produces daily raw variation (meanRawRange ≈ 0.51)     │
│   Envelope maps small raw steps → tiny displayPosition steps      │
│   → 63% of pairs: |ΔUI| < 0.02; only 26%: |ΔUI| ≥ 0.05         │
└─────────────────────────────────────────────────────────────────┘
```

Phase 1 correctly scoped **UI-only** changes. Problem B requires **engine and/or envelope** intervention — explicitly deferred in the parent plan.

---

## 3. Background — how we got here

### 3.1 Timeline

| Date | Milestone |
|------|-----------|
| 2026-06-22 | Baseline cohort audit → contrast + metal FAIL; vibrancy PASS (`docs/fixtures/slider_day_variation_report.json`) |
| 2026-06-22–24 | Slider Variation Fix Phases 1–4 implemented |
| Phase 1 | Removed `snapMetalToThreePositions` on presentation path in `DailyFitViewController` |
| Phase 2 | Added `computeStage1ContrastRaw` with sky-vibe + tempo inputs; wired `deriveContrast` + `buildPlan` |
| Phase 3 | Set `contrastPracticalHalfSpan = 0.22` from cohort P95 = 0.271 |
| Phase 4 | Added `SliderDayVariation_Tests.swift` CI gate; full 216×60 re-run |
| 2026-06-24 | Final tuned cohort audit → contrast PASS; metal G2 FAIL (`docs/fixtures/slider_day_variation_report.post_fix.json`) |

### 3.2 Baseline vs post-fix (216 users × 60 days)

| Metric | Baseline | Post-fix | Gate |
|--------|----------|----------|------|
| **Metal — unchanged day-pairs** | 86.3% | **8.8%** | < 20% ✓ |
| **Metal — meaningful day-pairs** | 13.7% | **25.9%** | **> 45% ✗** |
| **Metal — max stuck streak (mean)** | 26.0 d | **3.7 d** | < 8 d ✓ |
| **Metal — users mostly unchanged** | 100% | **9.3%** | < 15% ✓ |
| **Metal — distinct UI positions** | 2.2 | **54.1** | > 35 ✓ |
| **Metal — median day Δ (UI)** | 0.000 | **0.007** | Phase 1 wanted > 0.05 ✗ |
| **Contrast — unchanged day-pairs** | 49.6% | **14.4%** | < 20% ✓ |
| **Contrast — meaningful day-pairs** | 35.3% | **54.0%** | > 45% ✓ |

### 3.3 Post-fix delta histogram (metal UI day-pairs, n = 12,736)

| Bucket | % of pairs |
|--------|------------|
| 0 (unchanged) | 8.8% |
| < 0.02 (imperceptible) | **62.9%** |
| 0.02–0.05 | 2.4% |
| 0.05–0.10 (meaningful starts) | 3.9% |
| 0.10–0.20 | 13.0% |
| 0.20–0.50 | 8.8% |
| > 0.50 | 0.2% |

**Interpretation:** ~72% of day-pairs are unchanged or imperceptible. To pass G2 (> 45% meaningful), you need roughly **+19 percentage points** shifted from the < 0.02 bucket into ≥ 0.05 — without breaking G1/G3/G4/G5.

### 3.4 What was tried and rejected (do not repeat blindly)

| Experiment | Result | Why |
|------------|--------|-----|
| `metalPracticalHalfSpan = 0.20` in `PersonalScaleEnvelope` (narrow envelope like contrast) | **Regressed badly** on 50-user subset: unchanged 53.5%, meaningful 18.3%, max streak 20.7 d | Tighter envelope caused rail-pinning / zero median delta for many users |
| Increasing contrast vibe/tempo scales to plan defaults (0.25/0.15) | Ceiling-pinning for high-baseline contrast users | Led to tuned-down contrast constants (0.20/0.12) — **keep these** |

**Lesson:** Naïve envelope narrowing is not a copy-paste of the contrast playbook. Metal needs a dedicated calibration method (P95 deviation, subset sweeps, worst-user spot checks).

---

## 4. Binding PASS criteria (do not soften)

Source: Slider Variation Fix plan §3. Measured on **UI-visible** values from `tools/slider_day_variation_audit.py`. Vibrancy and contrast use continuous `displayPosition`. **Metal (post-2026-06-26 restore):** UI applies 3-position snap on personal-band `displayPosition`; metal uses relaxed **`METAL_GATES`** in `tools/verify_slider_gates.py` (not the continuous thresholds below).

A slider **PASSes** when **all six** conditions are true on a full cohort run of `tools/slider_day_variation_audit.py`:

| Gate | Metric (`aggregate.{slider}`) | Threshold | Metal post-fix |
|------|--------------------------------|-----------|----------------|
| **G1** | `meanPctUnchangedDayPairsUI` | **< 20.0** | 8.8 ✓ |
| **G2** | `meanPctMeaningfulDayPairsUI` | **> 45.0** | **25.9 ✗** |
| **G3** | `meanMaxUnchangedStreakUI` | **< 8.0** | 3.7 ✓ |
| **G4** | `pctUsersMostlyUnchanged` | **< 15.0** | 9.3 ✓ |
| **G5** | `meanUiDistinct` | **> 35.0** | 54.1 ✓ |
| **G6** | Users with 60d UI `rawRange` < 0.33 | **< 10.0%** of cohort | Verify on re-run (likely PASS) |

**Definitions** (from audit tooling):

- **Unchanged:** `|ΔUI| < 1e-9`
- **Imperceptible:** `|ΔUI| < 0.02`
- **Meaningful:** `|ΔUI| ≥ 0.05`
- **Mostly unchanged user:** > 50% of that user’s day-pairs unchanged

**Release gate:** All three scale sliders (vibrancy, contrast, metalTone) PASS G1–G6. **Vibrancy must not regress.**

### 4.1 Phase 1 exit criterion (metal-specific, still open)

The parent plan also required:

- `medianDayDeltaUI` **> 0.0500** for metal after snap removal

Post-fix: **0.0072** (mean is 0.0545 — distribution is highly skewed). Treat median > 0.05 as a **strong secondary signal** that G2 work should improve.

---

## 5. Root cause analysis (Problem B)

### 5.1 Engine: `deriveMetalTone`

**File:** `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` (~line 1306)

```swift
baseline = tempVal * 0.6 + metalLean * 0.4   // palette-anchored, static per user
final = baseline + fireNudge - waterNudge + lunarNudge + lunarMetalMod
```

**Daily inputs:**

| Input | Stage 1 contribution | Typical daily swing |
|-------|---------------------|---------------------|
| Fire/water transit hits | `±min(hits * metalNudgePerHit, metalNudgeCap)` | Discrete steps per dominant transit set |
| Lunar named phase | ±0.03 on full/new moon | Occasional |
| Lunar degree | `(phaseDegrees/360 - 0.5) * 0.15` | Continuous but **small** (~±0.075 max) |

**Constants** (`Stage1ScaleSensitivity`):

- `metalNudgeCap = 0.30`
- `lunarNamedPhaseNudge = 0.03`
- `lunarDegreeScale = 0.15` → `lunarDegreeMaxAbs = 0.075`

Raw metal **does vary** (cohort mean 60d raw range ≈ 0.51). The issue is **magnitude per day-pair**, not total range over 60 days.

### 5.2 Envelope: wide display mapping

**File:** `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` — `metalToneEnvelope`

```swift
maxNudge = metalNudgeCap + lunarNamedPhaseNudge + lunarDegreeMaxAbs  // ≈ 0.405
floor = baseline - maxNudge
ceiling = baseline + maxNudge
displayPosition = (value - floor) / (ceiling - floor)
```

Envelope width ≈ **0.81** (for typical baseline). A raw daily change of **0.02** → display Δ ≈ **0.025** (imperceptible). Need **~0.04+ raw delta** for meaningful UI shift — but many days change less.

Contrast solved a similar problem with:

1. **Stronger sky-native signal** (`contrastVibeScale`, `contrastTempoScale`)
2. **Calibrated practical half-span** (`contrastPracticalHalfSpan = 0.22`)

Metal has **neither** a vibe/tempo-class daily signal nor a practical half-span. Parent plan deferred both.

### 5.3 UI path (2026-06-26 product restore)

**File:** `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` — `refreshDiamondScalePositions()`

```swift
if let sp = payload.scalePresentation {
    sliderTargetValues[2] = Self.snapMetalToThreePositions(sp.metalTone.displayPosition)
} else {
    sliderTargetValues[2] = Self.snapMetalToThreePositions(payload.metalTone)  // legacy only
}
```

Audit default: `tools/slider_day_variation_audit.py` snaps metal UI on `displayPosition` (matches production). Use `--no-metal-snap` for continuous comparison only.

---

## 6. What the previous workstream completed (do not redo)

### 6.1 Code changes (landed)

| File | Change |
|------|--------|
| `DailyFitViewController.swift` | Presentation-path metal marker = continuous `displayPosition` |
| `BlueprintLensEngine.swift` | `computeStage1ContrastRaw`, contrast constants, `contrastPracticalHalfSpan = 0.22` |
| `DailyNarrativeSelector.swift` | `buildPlan` delegates contrast to shared helper |
| `PersonalScaleEnvelope.swift` | Contrast practical half-span (metal envelope **unchanged**) |
| `DailyFitSkyForwardV2_Tests.swift` | I4b/I4c/I5/I5b, integration tests |
| `SliderRangeAudit_Tests.swift` | Continuous metal `uiMarkerPosition` |
| `DailyFitUIIntegration_Tests.swift` | U3 continuous metal marker |
| `SliderDayVariation_Tests.swift` | 12 profiles × 30 days CI gate |
| `tools/slider_day_variation_audit.py` | Default continuous metal; `--output` flag; P95 tracking |
| `tools/slider_range_audit.py` | `CONTRAST_PRACTICAL_HALF_SPAN = 0.22` |
| `tools/verify_slider_gates.py` | Gate verification script |
| `canvases/slider-day-variation-audit.canvas.tsx` | Before/after audit canvas |

### 6.2 Final contrast constants (FROZEN unless regression)

```swift
// Stage1ScaleSensitivity
contrastVibeScale = 0.20
contrastTempoScale = 0.12
contrastPracticalHalfSpan = 0.22
```

### 6.3 Fixtures

| File | Purpose |
|------|---------|
| `docs/fixtures/slider_day_variation_report.json` | Pre-fix baseline (2026-06-22) |
| `docs/fixtures/slider_day_variation_report.post_fix.json` | Post-fix tuned run (2026-06-24) |
| `docs/fixtures/contrast_envelope_p95.json` | P95 = 0.2712 → half-span 0.22 |
| `docs/fixtures/slider_day_variation_report.tune_v1.json` | 50-user subset with contrast tuning (contrast PASS) |

---

## 7. Your mission — scope and constraints

### 7.1 In scope

- Increase **per-day UI meaningful shift rate** for metal tone on `stage1_experimental`
- Pass **G2** (and ideally median day Δ > 0.05) while keeping **G1, G3, G4, G5, G6** passing
- Add/adjust tests and audit tooling as needed
- Re-run full **216 × 60** cohort audit and update canvas/fixtures

### 7.2 Out of scope (unless product explicitly approves)

- Changing **vibrancy** or **contrast** constants (already PASS — regression = blocker)
- Re-introducing metal **3-snap** on the presentation path
- Production / legacy engine presets (`mode != .stage1Experimental`)
- New user-facing copy (metal names on slider, etc.)
- Lowering the **0.05 meaningful threshold** in audit tooling (gate is binding)

### 7.3 Parent plan deferral (now in scope for you)

The Slider Variation Fix plan marked these as **out of scope**:

> Changing `deriveMetalTone` formula or metal envelope

**This follow-up explicitly reopens both**, with product goal = pass G2. Document any formula or envelope change with cohort evidence.

### 7.4 Hard constraints (unchanged from Personal Scale Sliders spec)

- **Do not change** stored absolute `payload.metalTone` semantics for fingerprint/calibration tests without updating guards intentionally
- Envelope math stays in `PersonalScaleEnvelope.swift`
- Legacy payloads without `scalePresentation` must still render (absolute + 3-snap fallback)
- `DailyFitSkyForwardV2_Tests.absoluteValuesUnchanged` compares scale absolutes only (palette non-determinism excluded)

---

## 8. Recommended approach (starting points — not prescriptive)

### 8.1 Option A — Sky-native signal for metal (mirror contrast/vibrancy)

Add daily inputs to `deriveMetalTone` for `stage1Experimental` only:

- Sky vibe edge/drama vs classic/utility (same class as vibrancy/contrast)
- Tempo axis modulation
- Possibly visibility/strategy at smaller weight

**Pros:** Same playbook that fixed contrast; daily signal independent of transit quantization.  
**Cons:** New constants need tuning loop; must not break baseline fingerprint tests.

### 8.2 Option B — Calibrated metal practical half-span

Measure cohort P95 of `|rawMetal - baseline|` post-signal, set:

```swift
metalPracticalHalfSpan = clamp(round(P95 + margin, 2), min, max)
```

Use in `metalToneEnvelope` for stage1 (replace wide `maxNudge` envelope).

**Pros:** Amplifies existing raw variation into UI deltas.  
**Cons:** **Failed naïvely at 0.20** — needs data-driven min/max and worst-user validation. Must not rail-pin.

### 8.3 Option C — Increase existing nudge sensitivities

Tune within current formula:

- `metalNudgeCap`, `lunarDegreeScale`, `calibration.stage2Sensitivity.metalNudgePerHit`
- Add finer-grained lunar or transit modulation

**Pros:** Smallest conceptual diff.  
**Cons:** May be insufficient alone; transit inputs are coarse (dominant transits only).

### 8.4 Suggested workflow

1. **Instrument** — extend audit or add script to report metal P95 raw deviation + per-user meaningful rate
2. **Subset sweep** — 50 users × 60 days (`--subset 50`) for fast iteration (~30 min/run)
3. **Worst users** — spot-check `synth_011_aries_sydney` (81% unchanged, 39d streak post-fix), `synth_012_aries_london` (36d streak)
4. **Full cohort** — 216 × 60 (~2 h) only when subset passes G2
5. **Verify gates** — `python3 tools/verify_slider_gates.py docs/fixtures/slider_day_variation_report.post_fix.json`

Compare against **vibrancy** (reference: 69% meaningful) and **structuredDraped** silhouette (~52% meaningful).

---

## 9. Testing PASS criteria

### 9.1 Cohort harness (release gate)

```bash
cd inspector && ./run-inspector.sh &
python3 tools/slider_day_variation_audit.py \
  --days 60 --parallel 8 --start 2026-04-23 \
  --output docs/fixtures/slider_day_variation_report.post_fix.json

python3 tools/verify_slider_gates.py docs/fixtures/slider_day_variation_report.post_fix.json
# Exit code 0 required
```

**Required:** vibrancy, contrast, metalTone all **VERDICT: PASS**.

### 9.2 Swift CI gate

```bash
# Use iOS 18.4 simulator — iOS 26.x simulators fail test host launch
xcodebuild test-without-building -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,id=80D13EB0-F96E-4A7B-93C3-9B2EC731C3A9" \
  -parallel-testing-enabled NO \
  -only-testing:"Cosmic FitTests/SliderDayVariation_Tests" \
  -only-testing:"Cosmic FitTests/PersonalScaleEnvelope_Integration_Tests" \
  -only-testing:"Cosmic FitTests/PersonalScaleEnvelopeTests" \
  -only-testing:"Cosmic FitTests/DailyFitUIIntegrationTests"
```

**`SliderDayVariation_Tests`** (12 named profiles × 30 days):

- Contrast + metal: ≥ 3 distinct `displayPosition` values
- Max consecutive unchanged UI days **< 10**

Note: CI gate does **not** assert meaningful-shift rate — cohort harness does.

### 9.3 Integration tests (must stay green)

| Test | Assertion |
|------|-----------|
| **I4c** | ≥ 2 distinct **snapped** metal UI positions over 14 Briar days |
| **I4b_legacySnap** | Snap function maps floor/ceiling/mid displayPosition to Cool/Mixed/Warm |
| **I5 / I5b** | Contrast distinct positions + plan/helper parity |
| **U3** | Metal marker snaps `displayPosition` to three positions on presentation path |
| **P3** | Metal baseline formula unchanged |
| **absoluteValuesUnchanged** | Same date → same vibrancy/contrast/metalTone absolutes |

### 9.4 Regression checks

After any metal change:

- [ ] Contrast still PASS all 6 gates on full cohort
- [ ] Vibrancy unchanged (G1–G6 match post-fix baseline ± noise)
- [ ] `BlueprintLensEngine_Payload_Tests` pass
- [ ] Inspector rebuild: `cd inspector && ./run-inspector.sh`

---

## 10. Key files reference

| File | Role |
|------|------|
| `BlueprintLensEngine.swift` | `deriveMetalTone`, `Stage1ScaleSensitivity` constants |
| `PersonalScaleEnvelope.swift` | `metalToneEnvelope` — floor/ceiling/displayPosition |
| `DailyFitViewController.swift` | Slider marker (continuous vs snap) |
| `tools/slider_day_variation_audit.py` | Cohort harness + aggregate metrics |
| `tools/verify_slider_gates.py` | PASS/FAIL gate checker |
| `Cosmic FitTests/SliderDayVariation_Tests.swift` | In-process CI gate |
| `Cosmic FitTests/DailyFitSkyForwardV2_Tests.swift` | I4c, I5, integration |
| `inspector/Resources/synthetic_cohort.json` | 216-user synthetic cohort |
| `canvases/slider-day-variation-audit.canvas.tsx` | Visual before/after (update on ship) |

**Related handoffs:**

| Doc | Role |
|-----|------|
| [`daily_fit_personal_scale_sliders_handoff.md`](./daily_fit_personal_scale_sliders_handoff.md) | Original personal scale spec (snap removal §16) |
| [`daily_fit_personal_scale_sliders_followup_handoff.md`](./daily_fit_personal_scale_sliders_followup_handoff.md) | Envelope architecture context |

---

## 11. Implementation handoff prompt (copy-paste)

```
Read docs/handoff/metal_tone_meaningful_shift_handoff.md in full before coding.

Mission: Pass metal tone cohort gate G2 (meanPctMeaningfulDayPairsUI > 45%) on
stage1_experimental while keeping G1/G3/G4/G5/G6 passing and NOT regressing
vibrancy or contrast (both currently PASS all six gates).

Context: UI snap removal is DONE. Metal moves continuously (54 distinct positions)
but 63% of day-pairs move < 0.02 on the track. Engine raw range is fine (~0.51);
daily delta magnitude and envelope mapping are the bottleneck.

Do NOT:
- Reintroduce metal 3-snap on presentation path
- Change contrastVibeScale (0.20), contrastTempoScale (0.12), or contrastPracticalHalfSpan (0.22)
- Lower the 0.05 meaningful threshold in audit tooling
- Ship partial fix (contrast-only)

Do:
1. Propose metal signal and/or envelope calibration with P95-style evidence
2. Iterate on 50-user subset (--subset 50) before full 216×60 run
3. Verify: python3 tools/verify_slider_gates.py docs/fixtures/slider_day_variation_report.post_fix.json
4. Run Swift CI gate tests on iOS 18.4 simulator
5. Update canvas + post_fix fixture on success

Start by reading deriveMetalTone and metalToneEnvelope, then post_fix deltaHistogram
for metalTone in docs/fixtures/slider_day_variation_report.post_fix.json.
```

---

## 12. Success checklist

- [ ] Metal **G2** > 45% meaningful day-pairs on full 216×60 cohort
- [ ] Metal **G1, G3, G4, G5, G6** still PASS
- [ ] Vibrancy + contrast **all six gates** still PASS (no regression)
- [ ] `medianDayDeltaUI` for metal **> 0.05** (strongly desired)
- [ ] `SliderDayVariation_Tests` + integration tests pass
- [ ] `docs/fixtures/slider_day_variation_report.post_fix.json` updated
- [ ] `canvases/slider-day-variation-audit.canvas.tsx` updated with final metal metrics
- [ ] Changes documented in commit message / PR with before/after table

---

## 13. Escalation trigger

If after tuning `metalNudgeCap`, lunar scales, vibe-class signal, and envelope calibration (with P95 method), **G2 remains < 40%** on full cohort:

- Stop and escalate to product/engineering with harness JSON attached
- Consider whether **0.05 meaningful threshold** is appropriate for metal’s Cool/Mixed/Warm semantics (product decision — do not change unilaterally)
- Parent plan deferred: “Soften envelope caps” — only if > 10% of users pegged at display 1.0 (not current primary issue)

---

*End of handoff. Questions about contrast/vibrancy work → see post-fix fixtures and `canvases/slider-day-variation-audit.canvas.tsx`. Questions about personal scale envelope architecture → see `daily_fit_personal_scale_sliders_handoff.md`.*
