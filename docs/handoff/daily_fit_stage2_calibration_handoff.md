# Daily Fit Stage 2 Calibration — Handoff Document

**Status:** Implemented in code (`DailyFitCalibration.default`), validated in automated exploration tests, **perceived as ineffective on device** by primary tester (Ash) for consecutive-day UX.  
**Date:** 2026-05-18  
**Audience:** Engineers or AI agents continuing Daily Fit sensitivity work.

---

## 1. Executive summary

Cosmic Fit’s **Daily Fit** card felt too static day-to-day: same palette accents, frozen vibrancy/contrast sliders, and unchanging style-essence labels, while tarot and style-edit copy rotated.

A multi-week **calibration exploration** (synthetic profiles × 98 days × many trial presets) identified a **hybrid production recipe**:

- **Stage 1 levers (A+ source weights + E axis unlock)** — increase how much transits/lunar phase move the underlying energy snapshot.
- **Stage 2 levers (H/J sensitivity)** — increase palette jitter and coefficients for vibrancy, contrast, silhouette, and metal nudge.

That recipe was shipped by updating **`DailyFitCalibration.default`** in `DailyFitTypes.swift`. Aggregate test metrics improved dramatically (palette churn ~0.11 → ~0.89 averaged across profiles).

**However:** the experience Ash reports on a **real build** (today vs tomorrow) still matches the *old* failure mode for several UI fields — especially **vibrancy**, **essence top-3**, and often **palette slots 1–2**. That does **not** mean the code change is a no-op; it means **aggregate 98-day harness metrics ≠ consecutive-day UX on a real profile**, and several operational gaps (frozen payloads, profile mismatch, Stage 1 limits) explain the disconnect.

**Stage 1 “dominant energy / essence flipping” was explicitly deferred** — it requires separate quantization / sign-multiplier work and was known to stay at **0 changes over 98 days** even after Stage 2 shipped.

---

## 2. Problem statement (why this work existed)

### 2.1 User-visible symptoms

Reports from testing (including Ash’s on-device checks):

| UI surface | Expected | Observed (pre-fix & often still on device) |
|------------|----------|---------------------------------------------|
| Daily palette (3 colours) | Meaningful day-to-day variation within Style Guide family | Slots 1–2 often identical; slot 3 sometimes swaps |
| Vibrancy / contrast sliders | Visible movement | Often identical to 3–4 decimal places |
| Style essence radar (top 3 labels) | Occasional label churn | Often fixed (e.g. MAXIMALIST, DRAMA, MAGNETIC) |
| Tarot card | Daily rotation | Generally works |
| Style-edit variant | Rotation per card | Generally works |
| Dominant energy label | Sometimes flips | Essentially never flips |

### 2.2 Technical root causes (confirmed in exploration)

1. **Heavy natal anchoring** — old source weights (`natal 0.40`) plus sun-sign multipliers (`SignEnergyMap`) dominate the 21-point vibe budget.
2. **Quantization** — six energies are normalized to **21 integer points**; small daily input shifts rarely change integers → vibe string identical many days in a row.
3. **Stage 2 damping** — `paletteJitter` was **0.001** (tie-break only); vibrancy/contrast coeffs were low; silhouette axis scale was **1.0**.
4. **Blueprint ceiling** — Daily Fit palette is scored from the user’s **Style Guide** (`CosmicBlueprint`) colour pool; drama-heavy profiles saturate on the same accent winners without jitter.
5. **Frozen payloads on device** — once the user reveals a day’s card, `DailyFitFrozenPayloadStorage` persists the exact `DailyFitPayload`; rebuilding the app does not clear it.
6. **Harness ≠ real user** — exploration “Ash” is a **synthetic Leo-fire chart** with a **calibration blueprint** (wide accent list), not Ash’s real natal chart + Deep Autumn Style Guide from production.

---

## 3. Architecture scope (what changed vs what did not)

### 3.1 Daily Fit pipeline (two stages)

```
Natal + progressed + transits + lunar + date
        ↓
DailyEnergyEngine          ← Stage 1 (DailyFitCalibration.sourceWeights, signEnergyMap, axisTuning)
        ↓
DailyEnergySnapshot        (VibeBreakdown 21-pt, DerivedAxes, transits, seed)
        ↓
BlueprintLensEngine        ← Stage 2 (selectionWeights, stage2Sensitivity)
        ↓
DailyFitPayload            (tarot, palette, scales, essence, silhouette, …)
```

**Changed:** `DailyFitCalibration.default` — consumed by both engines when callers pass `.default` (production path).

**Not changed:**

- **Style Guide** generation (`BlueprintComposer`, `ColourEngineV4`, narrative cache) — permanent profile, separate pipeline.
- **Tarot text / style-edit copy** content libraries.
- **`SignEnergyMap` / `PlanetAxisMap`** standard tables (no “compressed signs” trial shipped).
- **Dominant-energy selection logic** beyond what Stage 1 weight shifts indirectly provide.

### 3.2 README drift

`README.md` §4.1 still documents **old** source weights (0.40 / 0.25 / …). Trust **`DailyFitTypes.swift`** as source of truth until README is updated.

---

## 4. Exploration history (trials → decision)

Exploration lived in `Cosmic FitTests/DailyFitCalibrationExploration_Tests.swift` with reports under `docs/fixtures/calibration_exploration_98day_*.txt`.

### 4.1 Trial families (abbreviated)

| Trial | Intent | Outcome |
|-------|--------|---------|
| **BASELINE** (legacy `.default`) | Control | Low palette churn; vibe ~14% day-to-day integer changes |
| **A+** | Rebalance sources toward transits + lunar | Vibe change ~31%; modest palette/contrast lift |
| **B** | Tarot selection tweaks | More tarot diversity; little palette impact |
| **C / D** | Transit boost in selection weights | **No effect** on vibe/palette vs baseline (selection weights already dominated by vibe) |
| **E** | A+ + axis desaturation (`sigmoidSpread` 2.0→1.4, `jitterRange` 0.1→0.18) | Slightly more contrast σ; same vibe rate as A+ |
| **F / G** | A+ + **compressed** `SignEnergyMap` multipliers | **Rejected** — vibe change rate collapsed (~31% → ~6%) |
| **H** | G + high `paletteJitter` + boosted vibrancy/contrast coeffs | Palette churn → ~1.0 for stuck profiles |
| **I** | Silhouette scale + metal nudge | Silhouette σ up; metal still ~0 in synthetic transit harness |
| **J** | H + I full bundle | Best palette motion but carries F/G’s vibe regression |

### 4.2 Shipped recipe (“PRODUCTION”)

**Do:** A+ source weights + E axis tuning + H/J Stage 2 sensitivity.  
**Do not:** Compressed sign multipliers (F/G/J bundle).

Final preset is aliased as `CalibrationPresets.production` = `DailyFitCalibration.default`.

---

## 5. Implementation record (what was actually merged)

### 5.1 `DailyFitTypes.swift` — `DailyFitCalibration.default`

| Parameter | Legacy | Production (current) |
|-----------|--------|----------------------|
| `sourceWeights.natal` | 0.40 | **0.28** |
| `sourceWeights.transits` | 0.25 | **0.35** |
| `sourceWeights.lunarPhase` | 0.15 | **0.22** |
| `sourceWeights.progressed` | 0.15 | **0.10** |
| `sourceWeights.currentSun` | 0.05 | 0.05 |
| `selectionWeights` | vibe 0.50, axis 0.35, transitBoost 0.15 | **unchanged** |
| `axisTuning.sigmoidSpread` | 2.0 | **1.4** |
| `axisTuning.jitterRange` | 0.1 | **0.18** |
| `stage2Sensitivity.paletteJitter` | 0.001 | **0.08** |
| `stage2Sensitivity.vibrancyCoeff` | 0.15 | **0.35** |
| `stage2Sensitivity.contrastCoeff` | 0.20 | **0.40** |
| `stage2Sensitivity.silhouetteAxisScale` | 1.0 | **2.0** |
| `stage2Sensitivity.metalNudgePerHit` | 0.05 | **0.10** |
| `signEnergyMap` / `planetAxisMap` | standard | **unchanged** |

### 5.2 Test suite adjustments

Files touched to match new intentional behaviour (not an exhaustive git list):

- `DailyFitCalibration_Tests.swift` — thresholds, default snapshot
- `DailyFitCalibrationExploration_Tests.swift` — presets reduced to `LEGACY_BASELINE` + `PRODUCTION`; added `ashTodayVsTomorrowStableReport()`
- `DailyFitVariation_Tests.swift` — inter-user / palette thresholds relaxed
- `DailyEnergyEngine_VibeProfile_Tests.swift` — verified explicit overrides still valid
- `BlueprintLensEngine_Payload_Tests.swift` — vibrancy assertions use relative ordering
- `AstrologicalSoundness_Tests.swift` — transit weight now largest source by design
- `DailyFitAshTodayTomorrow_Tests.swift` — **added** for harness + real Ash scenarios; **unreliable in CI/simulator** (often 0.000s / no file written)

### 5.3 Exploration harness assumptions

`DailyFitCalibrationExploration_Tests` uses:

- **5 synthetic profiles** (ash Leo-fire, water, earth, air, fire)
- **98 days** from fixed base date `2026-05-10`
- **Synthetic transit list** per day (not full ephemeris for most profiles)
- **Calibration blueprint** per profile (rich accent/support pools — not user Style Guides)

Metrics are valid for **relative preset comparison**, not for predicting a specific user’s Deep Autumn palette on their phone.

---

## 6. Why Stage 1 amends were not shipped (separate workstream)

“Stage 1” in product language maps to **energy snapshot** changes that would flip:

- `VibeBreakdown` integer allocation more often
- **Dominant energy** label (`drama`, `playful`, …)
- **Style essence** top-3 categories (14-way radar)

### 6.1 Known limitation: dominant energy never moves

Across **all exploration presets**, **all profiles**, **98 days**:

```
Dominant energy changes: 0 / 97 day-pairs
```

This is structural:

- 21-point budget + largest-remainder rounding
- Sun-sign `SignEnergyMap` multipliers (e.g. Leo drama 1.5×)
- Saturated profiles (high drama natal) absorb transit noise without changing dominant bucket

**Compressed sign multipliers (Trial F/G)** were tried to fix this and **were rejected** because they slashed vibe integer change rate (~31% → ~6%) — worse overall motion.

### 6.2 What Stage 2 was meant to fix vs Stage 1

| Layer | Stage 2 shipped fix | Still needs Stage 1-style work |
|-------|---------------------|------------------------------|
| Palette slot names | Jitter breaks ties | Statement slot logic still drama-biased |
| Vibrancy / contrast | Higher coeffs | Still flat if vibe integers + axes unchanged day-to-day |
| Silhouette sliders | Higher axis scale | Angular/rounded often pinned at 0 in harness |
| Essence top-3 | Indirect via energies/axes | No dedicated essence quantization redesign |
| Dominant energy label | — | Requires new Stage 1 design |

**Decision:** Ship Stage 2 sensitivity **now** for palette/scales motion; schedule Stage 1 redesign for essence/dominant-energy flipping.

---

## 7. Validation results (automated)

### 7.1 Primary report artifact

**File:** `docs/fixtures/calibration_exploration_98day_v4.7_2026-05-18_pid71624_b1d4f4b3.txt`  
(~242 KB, 5 profiles × 98 days × 2 presets)

Regenerate:

```bash
cd /path/to/cosmicfit
xcodebuild build-for-testing -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4"
xcodebuild test-without-building -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4" \
  -only-testing:"Cosmic FitTests/DailyFitCalibrationExploration_Tests/runFullExploration()"
```

Reports write to `docs/fixtures/` with unique suffixes via `CalibrationReportHelper` (see `CALIBRATION_REPORT_DIR` env override).

### 7.2 Comparison summary (from report § COMPARISON SUMMARY)

**Averages per preset (5 profiles, 98 days each):**

| Preset | Tarot (uniq) | Dom. energy Δ | Vibe int. change % | Palette churn | Vibrancy σ | Contrast σ |
|--------|--------------|-----------------|--------------------|---------------|------------|------------|
| **LEGACY_BASELINE** | 13.6 | **0.0** | 14.4% | 0.111 | 0.00339 | 0.00795 |
| **PRODUCTION** | 17.4 | **0.0** | **31.1%** | **0.892** | **0.00798** | **0.02837** |

**Per-profile PRODUCTION highlights:**

| Profile | Palette churn | Vibe change % | Notes |
|---------|---------------|---------------|-------|
| ash (Leo fire) | **1.003** | 26.8% | Was **0.000** churn under legacy — completely stuck 98/98 days |
| water | 1.313 | 30.9% | Strongest churn |
| earth | 0.577 | 23.7% | Moderate |
| air | 0.564 | 41.2% | Highest vibe % |
| fire | 1.003 | 33.0% | Same churn as ash |

**Legacy ash (Leo fire):** `Coral, Tangerine, Champagne` for **all 98 days** (vibrancy 0.793 constant).  
**Production ash:** palette rotates across accent names; vibrancy spans ~0.817–0.850 over 98 days; contrast σ ~0.013.

### 7.3 Consecutive-day harness (today vs tomorrow)

**File:** `docs/fixtures/ash_today_tomorrow_combined.txt`

Regenerate:

```bash
xcodebuild test-without-building -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4" \
  -only-testing:"Cosmic FitTests/DailyFitCalibrationExploration_Tests/ashTodayVsTomorrowStableReport()"
```

**Day 0 vs day 1 (harness Ash, production `.default`, base 2026-05-10):**

| Field | Result |
|-------|--------|
| Palette 1 | Coral → Burgundy (**differs**) |
| Palette 2 | Saffron → Tangerine (**differs**) |
| Palette 3 | Champagne → Champagne (same) |
| Vibrancy | 0.8333 → 0.8333 (**same**) |
| Contrast | 0.912 → 0.916 (tiny Δ) |
| Essence top-3 | MAXIMALIST / DRAMA / MAGNETIC (**same**) |
| Tarot | Six of Wands → Six of Wands (**same**) |
| Dominant energy | drama → drama |

**Interpretation:** Stage 2 **did** change palette on adjacent days in harness conditions, but **did not** change vibrancy or essence on that pair — matching what Ash sees for sliders/essence even when palette slot 3 moves on device.

### 7.4 Full test suite

At implementation time, serial **`Cosmic FitTests`** passed after threshold updates. Re-verify before release:

```bash
xcodebuild test -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4"
```

---

## 8. User testing vs automated metrics (the gap)

### 8.1 Ash on-device report (post-implementation)

Ash compared **today vs tomorrow** on a DEBUG build and still saw:

- Same **first two** palette colours
- Same **vibrancy** and **contrast** (to displayed precision)
- Same **essence** triple (Maximalist, Magnetic, Drama)
- Tarot may or may not match depending on reveal/freeze state

### 8.2 Why exploration “success” can coexist with device “failure”

| Factor | Effect |
|--------|--------|
| **Frozen payload cache** | After card reveal, `DailyFitFrozenPayloadStorage` returns old payload. Fix: Profile → **“⟳ Force refresh all data”** (DEBUG), or delete app, or clear `DailyFitFrozen/` + `CardRevealed_*` UserDefaults keys. |
| **Real chart + real blueprint** | Production Ash ≠ harness Ash. Real Style Guide may have narrower winning accents; statement-colour logic locks slots 1–2. |
| **Consecutive days are hardest** | 98-day σ aggregates tiny daily deltas; **day 0 vs 1** often shares vibe integers, moon phase family, tarot pool. |
| **Stage 2 ≠ essence** | Essence top-3 unchanged is **expected** until Stage 1 work; not a sign Stage 2 code path is dead. |
| **Vibrancy tied to quantized vibe** | If `VibeBreakdown` integers identical, vibrancy modulation may land on the same 4-decimal value. |
| **Build not refreshed** | Old binary without new `.default` still runs; frozen cache preserves old outputs even after upgrade. |

### 8.3 Real Ash fixture test (incomplete)

`DailyFitAshTodayTomorrow_Tests.swift` includes a **real birth** path:

- Birth: `1984-12-11`, London (`AshTodayTomorrowSupport`)
- Blueprint: `docs/house_sect_regression/input_after/ash.json`
- Ephemeris transits via `NatalChartCalculator.calculateTransits`

This test was intended to write an extended combined report and flag when real Ash reproduces the stuck UI pattern. It **often failed to run to completion** in Xcode simulator sessions. **Do not treat it as validated** until it passes reliably.

---

## 9. How to inspect and debug (tooling)

### 9.1 macOS Inspector (recommended for real charts)

```bash
cd inspector
swift run cosmicfit-inspector
# Open http://127.0.0.1:7777
```

Same engine as iOS (symlinked sources). Compare **adjacent days** with real ephemeris without frozen cache. See `inspector/README.md`.

### 9.2 On-device / DEBUG

- `ProfileViewController` → **Force refresh all data** — clears frozen payloads and regenerates (also triggered on profile/chart changes in `CosmicFitTabBarController`).
- `DailyFitDiagnostics.generateReport` — diagnostic trace for Stage 1 + Stage 2 (used in tests/inspector).

### 9.3 Key source files

| File | Role |
|------|------|
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | `DailyFitCalibration.default` |
| `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` | Stage 1 |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Stage 2 payload |
| `Cosmic Fit/Core/Utilities/DailyFitFrozenPayloadStorage.swift` | Post-reveal freeze |
| `Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift` | Load/save frozen payloads |
| `Cosmic FitTests/DailyFitCalibrationExploration_Tests.swift` | 98-day + ash today/tomorrow |
| `Cosmic FitTests/CalibrationReportHelper.swift` | Report output paths |

---

## 10. Risks called out in the plan (still valid)

| Risk | Status |
|------|--------|
| Palette too chaotic | Not observed; jitter 0.08 still ranks by vibe affinity |
| Vibrancy/contrast overshoot | Clamped 0–1; consecutive days can still look identical |
| Silhouette instability | σ increased but bounded; some axes still pin at 0 |
| Tests break on exact values | Addressed in test pass |
| Dominant energy never flips | **Still true** — needs Stage 1 |
| Metal tone flat in tests | Synthetic transits don’t fire metal nudges meaningfully |

---

## 11. Recommended next steps (priority order)

1. **Unblock real-Ash validation** — fix `DailyFitAshTodayTomorrow_Tests` / merge real-birth block into stable `ashTodayVsTomorrowStableReport()` using `ash.json` + ephemeris.
2. **DEBUG “dump today vs tomorrow”** — bypass frozen cache, print payload JSON to console or share sheet for field-by-field diff on device.
3. **Stage 1 design spike** — essence / dominant-energy flipping without compressed signs (e.g. transit-triggered nudges, separate essence quantization, or reduced sign multiplier range selectively).
4. **Update README** §4.1 weights table to match production defaults.
5. **Optional:** Stable symlink/copy for latest `calibration_exploration_98day_combined.txt` (today only timestamped files exist).
6. **Product copy** — set expectations: palette may move before essence labels do.

---

## 12. Quick FAQ for the next developer

**Q: Did Stage 2 ship?**  
A: Yes — `DailyFitCalibration.default` in `DailyFitTypes.swift` reflects the PRODUCTION preset.

**Q: Then why does Ash still see the same colours?**  
A: Check frozen cache, confirm DEBUG build date, compare harness report vs real chart in inspector. Slots 1–2 can remain fixed by drama/statement rules even when slot 3 moves.

**Q: Are the 98-day metrics fake?**  
A: No — they’re real for the **synthetic harness**. They don’t guarantee **your** consecutive-day phone UX.

**Q: Was Stage 2 a waste?**  
A: No for palette rotation in harness (ash churn 0 → 1.0). Incomplete for essence/dominant energy and marginal for vibrancy on adjacent days.

**Q: What should we ship to users next?**  
A: Stage 1 essence/dominant-energy work + real-profile validation + cache-bust UX, not more Stage 2 jitter alone.

---

## 13. Related artifacts index

| Artifact | Path |
|----------|------|
| 98-day exploration (PRODUCTION vs LEGACY) | `docs/fixtures/calibration_exploration_98day_v4.7_2026-05-18_pid71624_b1d4f4b3.txt` |
| Ash today vs tomorrow (harness only) | `docs/fixtures/ash_today_tomorrow_combined.txt` |
| Real Ash Style Guide fixture | `docs/house_sect_regression/input_after/ash.json` |
| Earlier 7-day calibration note | `docs/fixtures/daily_fit_calibration_report.txt` |
| Inspector | `inspector/README.md` |
| Prior exploration transcript | Cursor chat — Stage 2 implementation thread |

---

*End of handoff.*
