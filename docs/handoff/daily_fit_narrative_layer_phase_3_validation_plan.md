# Daily Fit Narrative Layer — Plan 3: Unified Slider Normalization, Cohort Validation & Promotion Gate

**Status:** Audited implementation plan, split from `daily_fit_narrative_layer_handoff.md`.
**Scope:** Original Phase 3 and Phase 4.
**Prerequisite:** Plan 2 must be complete, reported, and approved by Ash.
**Must read first:** `daily_fit_narrative_layer_handoff.md`, `daily_fit_narrative_layer_phase_1_foundation_plan.md`, and `daily_fit_narrative_layer_phase_2_coherence_plan.md`.

---

## 1. Mission

This plan extends personal-scale display positions to all six Daily Fit sliders and proves, with cohort report data, that the full system produces improved, narratively coherent, user-specific results across hundreds of users and at least 60 days.

This is a validation and promotion-gate plan. It must not quietly change the narrative architecture from Plan 2.

---

## 2. Non-Negotiable Assumptions

1. All six slider markers must move on a user-relative scale.
2. No slider may remain stuck in one tertile across the full report window.
3. Coherence validation must include both intra-element and cross-element contradiction checks.
4. Production promotion is not automatic, even if metrics pass.
5. Ash reviews the final report before any production decision.

---

## 3. Phase 3: Unified Per-User Normalization

### 3.1 Extend Scale Types

Update `PersonalScaleKind` to include:

- `masculineFeminine`
- `angularRounded`
- `structuredDraped`

Update `PersonalScalePresentation` to include optional silhouette envelopes first if legacy decode requires it.

After compatibility is proven, stage1 payloads should always include all six envelopes.

### 3.2 Extend `PersonalScaleEnvelopeCalculator`

Add silhouette envelope construction for all three axes.

The strategy must be chosen from Plan 1 data:

- Use analytical envelopes only if baseline reports show they produce adequate observed travel.
- Use calibrated longitudinal envelopes if analytical envelopes are too narrow, too wide, or leave many users stuck.

Document the chosen strategy in the implementation notes.

### 3.3 Important Audit Note

The original handoff suggests computing longitudinal envelopes from a synthetic 60-day simulation. That is acceptable for validation, but it is risky as a production runtime dependency unless the app can reproduce it deterministically and cheaply.

If longitudinal envelopes are required, implement them as one of:

- committed calibration constants derived from the cohort,
- deterministic per-user forecast calculation with bounded runtime,
- or a clearly staged follow-up that remains behind `stage1_experimental`.

Do not introduce hidden network, date-range, or non-deterministic dependencies into payload generation.

### 3.4 Update UI Slider Positions

Update `DailyFitViewController.refreshDiamondScalePositions` so silhouette markers use `scalePresentation` display positions when available, falling back to raw `silhouetteProfile` values for legacy payloads.

The UI should not know the normalization formula. It should only consume display positions.

### 3.5 Required Tests

Add tests for:

- Silhouette envelope floor, ceiling, baseline, value, displayPosition, and baselinePosition.
- Floor maps to 0.0.
- Ceiling maps to 1.0.
- Degenerate ranges map to center.
- Stage1 payloads include six scale envelopes.
- Legacy payloads without silhouette envelopes decode safely.
- UI fallback uses raw silhouette only when displayPosition is absent.
- Production fingerprint unchanged.

---

## 4. Phase 4: Cohort Validation

### 4.1 Build Narrative Cohesion Harness

Create `tools/narrative_cohesion_harness.py`.

It must run:

- at least 200 users,
- at least 60 consecutive days,
- stage1 experimental mode,
- deterministic dates and seeds,
- final plan-driven payloads, not shadow-mode-only output.

### 4.2 Required Metrics

The final report must include:

- Essence top-1 flip rate.
- Distinct #1 essences per user.
- Essence top-3 category coverage.
- Slider range coverage for all six sliders.
- Slider tertile coverage for all six sliders.
- Palette diversity.
- Tarot variant plan match rate.
- Texture and pattern plan match rate.
- Essence opposition violation count.
- Cross-surface contradiction violation count.
- Coherence score.
- Sky accuracy score.
- User applicability score.
- Production fingerprint result.

### 4.3 Hard Pass/Fail Targets

Hard zero-tolerance targets:

- Visible essence opposition violations: 0.
- Cross-surface contradiction violations: 0.
- Salience drivers referenced by plans must correspond to real snapshot transits: 100%.
- Palette colours must come from the user's approved palette pool: 100%.
- Production fingerprint must be unchanged: 100%.

Quantitative improvement targets:

- Essence top-1 flip rate: at least 40%.
- Distinct #1 essences: at least 6 per user over 60 days, or documented pass criteria approved by Ash if cohort distribution makes this unrealistic for some edge users.
- Essence top-3 category coverage: at least 10 of 14.
- Slider range coverage: at least 0.5 for every slider per user unless a documented blueprint constraint makes that impossible.
- No slider stuck in one tertile for the full 60 days.
- Aggregate coherence score: at least 0.85.
- Accent essence matches top salience driver: at least 70%.
- Blueprint saturation and contrast baseline respected: at least 95%.

### 4.4 Report Review Process

Generate:

- `docs/fixtures/narrative_cohesion_report.json`
- a human-readable `.txt` or `.md` summary
- a final visual report if useful
- a promotion recommendation document only if all hard targets pass

AI must analyze the report and explicitly call out failures, weak passes, suspicious metrics, or signs of overfitting.

Ash must review and approve any promotion recommendation. Passing tests alone is not approval.

---

## 5. Cleanup Gate

After validation passes, perform a cleanup audit.

Classify old narrative code into:

- remove now,
- keep for production compatibility,
- keep for legacy decode,
- keep for diagnostics,
- follow-up removal.

Candidate cleanup list:

- `NarrativeIntentEngine`
- `NarrativeSelectionDirectives` functions no longer used by stage1
- `NarrativeTarotBridgeSelector`
- old narrative trace fields replaced by plan trace
- duplicated test fixtures superseded by final report fixtures

Do not remove compatibility code blindly. The cleanup criterion is not "new code exists"; it is "no supported path needs this code, and tests prove removal is safe."

---

## 6. Exit Gate For Plan 3

Plan 3 is complete only when:

- Stage1 payloads include display positions for all six sliders.
- UI uses display positions for all six sliders with legacy fallback.
- Slider range report passes the agreed targets.
- Narrative cohesion report passes every hard target.
- Aggregate quantitative targets pass or any exception is explicitly documented and accepted by Ash.
- No contradiction defects appear in the final cohort report.
- Production fingerprint is unchanged.
- Cleanup audit is complete.
- Ash has reviewed the final report and made a separate production promotion decision.

Do not promote to production automatically.
