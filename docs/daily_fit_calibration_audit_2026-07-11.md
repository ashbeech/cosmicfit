# Daily Fit Calibration Audit — natal / progressed / lunar / transit mix

> **Status:** Generated audit report (2026-07-11). Not an architecture handoff — engine truth remains `README.md` §4.1 + `DailyFitEngineRegistry.swift`.
> **Engine audited:** Sky Forward v1.0.1 (`production` → `.stage1Experimental`)
> **Method:** Code-path analysis of the shipped engine + five new real-ephemeris experiments (`inspector/Tests/InspectorEngineTests/CalibrationAudit_Tests.swift`), 12 real birth charts × 181 days (2026-01-01..2026-06-30). Raw experiment outputs: `docs/fixtures/calibration_audit_2026-07-11/`.
> **Question audited:** Is the proportional mix of natal / progressed / lunar / transits calibrated to communicate the actual astrological weather — and should the proportions themselves move (e.g. on full moons)?

---

## 1. Executive summary

The engine is **stable, deterministic, and fresh** — every existing gate passes, including with `CALIBRATION_CI_GATE=1`. But the calibration question has a clear answer: **the proportions that actually run are not the proportions anyone designed, and the moon is close to invisible in the vibe layer.**

| Source | Registry vector (docs/fingerprint) | Nominal runtime sky mix | **Measured effective share of the daily vibe** |
|---|---:|---:|---:|
| Transits | 0.44 | 0.25 | **0.94** (min 0.91, max 0.96) |
| Lunar phase | 0.30 | 0.60 | **0.046** (min 0.032, max 0.068) |
| Current sun | 0.03 | 0.15 | **0.013** |
| Natal | 0.16 | 0 (anchor-only) | 0 (anchor slice only) |
| Progressed | 0.07 | 0 (anchor-only) | 0 (anchor slice only) |

The suspicion that prompted this audit — *"the moon is quite a small proportion… are full moons taken into account as much as they should be?"* — is **confirmed and quantified**: the moon carries ~4.6% of the daily vibe energy, phase changes register as a step function that produced only **3 distinct vibe outputs across an entire lunar cycle** on a real sky, and **roughly half of all full moons are never labelled Full Moon at all** by the phase bucketing. Meanwhile ~25% of day-over-day axis motion is seeded random jitter, which is individually louder than the full-moon axis signal.

The good news: the *axes* path already treats the moon continuously and correctly (action/visibility climbs from 6.3 at new moon to 7.6 at full moon), the daily-variation requirement is genuinely met, and every fix below is a calibration change, not a rebuild.

---

## 2. How the mix actually works (what the docs don't say)

### 2.1 Two mixes, not one

`README.md` §4.1 presents one five-source weight table (0.16/0.44/0.30/0.07/0.03 from `DailyFitEngineRegistry.stage1ExperimentalCalibration`). At runtime the stage-1 path never blends those five. It computes two separate reads (`DailyEnergyEngine.swift:73–105`):

- **Chart anchor** (context only): natal 0.85 / progressed 0.15 (`stage1ChartSourceWeights`, `DailyEnergyEngine.swift:446–448`)
- **Daily sky** (this *is* the shown vibe): transits 0.25 / lunar 0.60 / currentSun 0.15 (`stage1SkySourceWeights`, `DailyEnergyEngine.swift:453–455`)

The registry vector is used for fingerprinting and diagnostics attribution. `AstrologicalSoundness_Tests` asserts properties of the five-source vector — i.e. the automated "soundness" checks validate a config that does not drive the daily output.

### 2.2 Why nominal ≠ effective: unnormalised transit accumulation

Each in-orb transit adds its own energy contribution (`accumulateTransitContribution`, `DailyEnergyEngine.swift:244–279`); the lunar phase adds a **fixed total of 1.0 × weight** (every per-phase bias vector sums to exactly 1.0, `DailyEnergyEngine.swift:178–187`). The transit detector (`NatalChartCalculator.calculateTransits`) checks ~13 transiting bodies × ~14 natal points × **11 aspect types including minors** (quintile, semi-sextile, sesquiquadrate…) at 2–3.5° orbs — which yields **41–83 in-orb transits every day (mean 59.7)** on real skies. Orb weighting is `1 − orb/10`, so at these orb caps every hit contributes 0.65–1.0 of full strength: a Pluto quintile natal Lilith at 2.4° counts almost the same as a Mars conjunction natal Sun at 0.1°. The vibe path applies **no planet-speed damping and no minor-aspect discount** (those exist only in the axis/salience paths; `TransitWeightCalculator.swift`, which has them, is dead code).

Net effect (experiment A1): transit share of the vibe tracks transit count almost perfectly (Pearson r = 0.94) and transits out-weigh lunar on **100% of 2,172 profile-days**.

**Two consequences:**
1. The nominal sky mix is fiction — lunar 0.60 becomes 0.046 in practice.
2. The effective proportions *already move daily* — but driven by combinatorial transit count (an artifact), not by astrological significance.

---

## 3. Findings

### F1 — The moon's vibe influence is a step function that barely steps *(HIGH)*
Lunar phase → one of 8 discrete buckets → fixed-magnitude bias vector (`MoonPhaseInterpreter.Phase.fromDegrees`, `lunarPhaseEnergies`). Experiment A2 swept the full 0–360° cycle at 0.25° resolution against a real 52-aspect sky: the vibe changed at only **3 boundary degrees**, by 2 points (of 42 max) each. Crossing into the Full Moon bucket at 177° produced **zero visible vibe change**. Between boundaries the moon cannot move the vibe at all — with lunar at 4.6% effective share, most of the 8 content shifts are erased by integer normalisation to the 21-point budget.

### F2 — About half of full moons are missed outright *(HIGH)*
The Full Moon bucket is 6° wide (177–183°); elongation advances ~12.2°/day, so the bucket covers ~0.5 day. New Moon is 4° wide (~0.33 day). Experiment A3 (calendar year 2026, sampled daily at 00/06/12/18 UTC): of **13 actual full-moon lunations, only 6–8 ever get a day labelled Full Moon; new moons: 3–4 of 13.** A missed full moon is labelled Waning Gibbous, whose energy vector leads with *classic* (0.35) instead of full moon's *drama+playful* (0.65) — the day's lunar message flips to roughly its opposite. There is no supermoon/eclipse/void-of-course/ingress modelling anywhere in the live path (already a README §5.2 caveat).

### F3 — Full-moon days are indistinguishable from ordinary churn in the vibe *(HIGH)*
Experiment A5 (6 profiles × 181 days): mean day-over-day vibe L1 delta is 1.17 within a lunar bucket, 1.50 on bucket-change days, and **1.25 on days entering the Full Moon bucket** — inside one standard deviation of baseline churn. A user cannot see a full moon in the vibe layer.

### F4 — Where the moon *does* work: the axes *(POSITIVE)*
`moonPhaseAxisModulations` (`DailyEnergyEngine.swift:1165–1176`) is continuous (`fullMoonProximity`), correctly signed, and measurable in output: mean (action+visibility)/2 = **6.30 near new moon → 7.05 near quarters → 7.64 near full moon**. This is the one live path where the astronomical moon is genuinely legible — and it feeds sliders/silhouette via Stage 2.

### F5 — Random jitter is louder than the moon *(MEDIUM-HIGH)*
Production `axisTuning.jitterRange = 0.40` exceeds the maximum full-moon axis nudge (±0.3). Experiment A4: **24.6% of all day-over-day axis motion is seeded noise**; jitter displaces axes by a mean 0.58 points (1–10 scale) within a single day — larger than the ~0.6-point full-vs-quarter lunar separation. Noise can fake "full moon energy" on a random Tuesday and mute a real full moon. (Legacy default jitter was 0.18; production raised it to 0.40 while also flattening the sigmoid.)

### F6 — Daily variation is real, but its provenance is mostly churn + noise *(MEDIUM)*
All variation gates pass (see §5). Zero-jitter runs still move 1.06 axis points/day on average, so the sky alone does vary — but at the vibe level the variation driver is turnover inside a ~60-transit soup where the population average moves slowly, plus jitter. The *narrative* the user reads day-to-day is therefore mostly "different subset of many small aspects" rather than "the moon waxed / a major transit perfected." Sky salience (top-transit extraction with speed factors and freshness bonuses) partially compensates at the tarot/accent layer.

### F7 — Natal/progressed are anchor-only by design; docs and tests describe a different engine *(MEDIUM, documentation)*
Natal 0.85/progressed 0.15 exist only in the anchor slice (context fields, narrative relationship classification); they contribute 0 to the daily vibe. That is a defensible weather-forecast design — but `README.md` §4.1's weight table, `docs/calibration_signoff.md`, and `AstrologicalSoundness_Tests` all describe/assert the five-source vector, so the documented mental model ("natal 16%, lunar 30% of the daily read") does not match the shipped behaviour. Also: `docs/fixtures/golden_cases.json` (required by the hard-failure `DailyFitGoldens_Tests`) is missing from disk, so the expert-golden suite is silently inert.

---

## 4. Direct answers to the audit questions

**Is the natal/progressed/lunar/transit mix proportionally right to communicate the day's energy?**
The weather-forecast intent (transits dominate, chart anchors) is delivered — but over-delivered by ~4× on transits (94% vs the intended 25–44%) and under-delivered by ~10× on the moon (4.6% vs 30–60%). The mix as *specified* is plausible; the mix as *executed* is not the specified one.

**Should the proportions move (e.g. lunar swelling on full moons)?**
They already move — by transit count, which is astrologically meaningless. There is no full/new-moon amplification anywhere in the live path (the only phase-amplified weighting in the codebase is dead code in `MoonPhaseInterpreter`). Making proportions move by *significance* (lunar-event proximity, transit exactness/rarity) instead of by *count* is the right direction and is a calibration-level change.

**If transits were reduced, would daily variation die?**
No. Variation survives transit normalisation because it comes from *which* aspects are tightest (turnover), lunar steps, and jitter — not from raw transit magnitude. Evidence: the axis path already uses only the top-5 tightest transits with speed damping and still moves 1.06 pts/day with jitter off; the 4C temporal-sensitivity and 4A drift gates pass under that regime.

**How do we test whether the Daily Fit communicates the actual sky?**
Invert the question: *can you recover the sky from the output?* The new harness does exactly this (full-moon distinguishability, effective-share measurement, jitter share). §6 proposes turning these into standing gates.

---

## 5. Test evidence

**New experiments** (all in `inspector/Tests/InspectorEngineTests/CalibrationAudit_Tests.swift`, run 2026-07-11, all passing; outputs in `docs/fixtures/calibration_audit_2026-07-11/`):

| Exp | Question | Headline result |
|---|---|---|
| A1 | Effective source shares, 12 profiles × 181 days | transits 94.1%, lunar 4.6%, sun 1.3%; r(count, share)=0.94 |
| A2 | Vibe granularity across a lunar cycle (fixed sky) | 3 distinct vibes; full-moon boundary invisible |
| A3 | Full/new-moon bucket hit rate (2026, daily sampling) | 6–8 of 13 full moons labelled; 3–4 of 13 new moons |
| A4 | Jitter share of axis motion (6 profiles × 91 days) | 24.6% of daily motion is noise; 0.58 pts within-day displacement |
| A5 | Full-moon salience in output | Vibe: indistinguishable (1.25 vs 1.17 baseline); Axes: legible (6.30→7.64) |

**Existing suites re-run 2026-07-11 — all green:** `DailyFitVariation_Tests`, `DailyFitCoherence_Tests`, `AstrologicalSoundness_Tests`, `DailyEnergyEngine_Snapshot_Tests` (default mode), plus `DailyFitVariation_Tests` + `DailyFitCoherence_Tests` under `CALIBRATION_CI_GATE=1` (7 tests, 2 suites, TEST SUCCEEDED). The committed 216×60 and 223×60 cohort evidence (slider day-variation, production audit v2, narrative cohesion) was reviewed and stands.

**Note on the "200+ users over 60 days" study:** it exists (`tools/synthetic_cohort.py` → 216 charts; `tools/slider_day_variation_audit.py` → 60 days) and it validated *freshness* (day-over-day deltas, streaks, distribution coverage). It never measured *fidelity* — no metric in that study asks whether the variation tracks the sky. Freshness and fidelity are different gates; only the first exists today.

---

## 6. Recommendations (priority order)

1. **Normalise transit accumulation in the vibe path** so nominal weights become real — either mirror the axis path (top-K tightest per planet, speed-damped) or divide the transit sum by effective count. This one change makes `lunar 0.60` mean something. Re-tune the sky mix afterwards (lunar will suddenly be audible; 0.60 may then be too loud — expect a re-calibration pass).
2. **Make the lunar vibe contribution continuous.** Interpolate between adjacent phase vectors by phase angle (cosine blend) instead of 8 hard buckets. This simultaneously kills the step function (F1) and the missed-full-moon problem (F2) — a full moon then peaks smoothly whether or not a sample lands in a 6° window.
3. **Add significance-driven weight modulation** — the "should proportions move?" answer: scale the lunar weight by `fullMoonProximity` (e.g. ×(1+k·proximity) around full/new), and surface named lunar events as first-class narrative events (already a §5.2 README caveat). Eclipses/supermoons can piggyback on the same hook later.
4. **Cut jitter below the signal floor** once (1) restores real variation: `jitterRange` from 0.40 → ≤0.18 (the legacy default), or scale it inversely with sky salience so quiet skies get texture and loud skies stay legible.
5. **Discount minor aspects and slow planets in the vibe path** (quintiles/semi-sextiles at 2° should not equal a Mars–Sun conjunction), consistent with what the axis path already does.
6. **Fix the evidence layer:** update README §4.1/`calibration_signoff.md` to document the two-mix runtime truth; point `AstrologicalSoundness_Tests` at the *effective* shares (A1-style) rather than the config vector; generate the missing `golden_cases.json` so `DailyFitGoldens_Tests` actually runs.
7. **Adopt fidelity gates** alongside the freshness gates: (a) effective lunar share within ±0.1 of nominal; (b) ≥90% of full moons produce a labelled event or a measurable output peak; (c) jitter share of axis motion < 15%; (d) full-moon vs baseline output delta statistically separable. The A1–A5 harness is the starting implementation.
8. **Re-run the validation ladder** (README §5.3: unit gates → 12×60 → 216×60 → 223×60 production audit) after any of the above; weights are fingerprinted, so a calibration change is a version bump (v1.1) with frozen-payload namespacing already handled by engine-id.

---

## 7. What was NOT changed

No engine code, weights, or behaviour were modified by this audit. Additions: the experiment suite (`CalibrationAudit_Tests.swift`), evidence fixtures (`docs/fixtures/calibration_audit_2026-07-11/`), this report, and a two-line compile fix to a stale inspector test (`DailyFitEngineRegistryInspectorTests.swift` was missing the new `resetEssenceRecencyHistory:` argument at 8 call sites — pre-existing breakage that blocked the inspector test target).
