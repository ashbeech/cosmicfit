# Daily Fit Narrative Layer — Plan 1: Measurement, Cohort & Adaptive Salience

**Status:** Audited implementation plan, split from `daily_fit_narrative_layer_handoff.md`.
**Scope:** Original Phase 0 and Phase 1 only.
**Audience:** AI developer implementing the first phase boundary.
**Must read first:** `daily_fit_narrative_layer_handoff.md`, especially the executive summary, root-cause analysis, and full testing strategy.

---

## 1. Mission

This plan establishes the proof system before changing user-facing behavior, then fixes the stale essence input by replacing slow-planet-dominated dominant-transit selection with a deterministic adaptive salience model.

The output of this plan is not "the new narrative layer." It is the measured, validated source signal that Plan 2 will consume.

Do not start Plan 2 until this plan has passed its exit gate and the report output has been reviewed by both AI and Ash.

---

## 2. Non-Negotiable Assumptions

1. Production behavior must remain unchanged.
2. Test data must represent hundreds of deterministic test users across at least 60 days.
3. The salience model must increase daily essence movement without creating incoherent essence top-3 combinations.
4. The implementation must not add user-facing copy.
5. Every output file and fixture must be reproducible from committed scripts.

---

## 3. Required Codebase Checks Before Editing

Before implementation, inspect the current code paths and confirm these are still true:

- `DailyFitPipeline.generate` is the single payload assembly path.
- `DailyEnergyEngine.extractDominantTransits` still uses fixed `transitPlanetWeights`.
- `BlueprintLensEngine.stage1TransitEssenceCategories` still maps multiple planets to the same essence category.
- `NarrativeSelectionDirectives.resolveEssenceConflicts` is still live in the stage1 path.
- `PersonalScalePresentation` still covers only vibrancy, contrast, and metal tone.

If any statement is no longer true, pause and update this plan before coding.

---

## 4. Phase 0: Measurement Baseline

### 4.1 Build Synthetic Cohort

Create `tools/synthetic_cohort.py`.

Requirements:

- Generate at least 200 deterministic synthetic users.
- Cover sun, moon, ascendant, palette saturation, contrast, and temperature diversity.
- Write `inspector/Resources/synthetic_cohort.json`.
- Use a fixed seed.
- Include a test or script assertion that rerunning the generator produces byte-identical output.

### 4.2 Build Slider Range Harness

Create `tools/slider_range_harness.py`.

Requirements:

- Run cohort users across at least 60 consecutive days.
- Capture raw values and display positions for all available sliders.
- For silhouette sliders, capture raw `payload.silhouetteProfile` values until Plan 3 adds display positions.
- Output `docs/fixtures/slider_range_report.json` and `.txt`.
- Include per-user min, max, range, histogram, tertile coverage, and stuck-axis flags.

### 4.3 Refresh Essence Diagnostics

Run the existing essence diagnostics harness against either the full cohort or a documented deterministic subset if runtime is too high.

Required output:

- Updated essence diagnostics fixture.
- Before-report covering top-1 flip rate, distinct #1 count, top-3 category coverage, and category stddev.

### 4.4 Baseline Report Review Gate

Before any salience code changes:

- AI must summarize the Phase 0 report and identify stuck sliders or stale categories.
- Ash must review the report and approve continuing.
- Store the approval note in the phase completion summary or PR description.

---

## 5. Phase 1: Adaptive Salience

### 5.1 Add `SkySalienceProfile`

Add the type in `DailyFitTypes.swift` or a dedicated file if that matches local style.

It must include:

- Sorted salience entries.
- Top salience drivers.
- Essence category per driver where mapped.
- Diagnostic fields for raw strength, speed factor, freshness bonus, and final normalized salience.

### 5.2 Replace Stage1 Essence Driver Source

Do not delete `extractDominantTransits`.

Instead:

- Keep existing dominant transits for production and compatibility.
- Add `computeSkySalience` for stage1.
- Store `skySalience` on `DailyEnergySnapshot` as optional stage1 diagnostics.
- Feed `skySalience.topDrivers` into stage1 essence scoring.

### 5.3 Rework Planet-to-Essence Mapping

Remove category collisions in the stage1 transit-to-essence mapping.

The exact mapping can be adjusted, but these rules are mandatory:

- No two planets may map to the same essence category.
- No mapping may create an obvious opposition pair as the default top-2 outcome.
- Add a unit test that fails if any planet mapping collision is reintroduced.

### 5.4 Keep Existing Essence Conflict Guardrails For Now

Do not remove `NarrativeSelectionDirectives.resolveEssenceConflicts` in Plan 1.

Reason: Plan 1 improves the input signal but does not yet provide a complete plan-owned coherence contract. Until Plan 2 routes visible essences through `DailyNarrativePlan`, the current opposition resolver remains the last live protection against combinations such as minimal plus maximalist appearing in the same diagram.

### 5.5 Required Tests

Add tests that prove:

- Same-orb Moon outranks same-orb Pluto.
- Applying or exact Venus outranks wide separating slow-planet signals.
- Per-day normalization makes top salience exactly 1.0 when transits exist.
- Duplicate category boosts are deduped.
- No planet-to-category collisions exist.
- No visible essence top-3 contains an opposition pair across the cohort run.
- Production fingerprint is unchanged.

### 5.6 Required Report Output

After implementation, rerun the reports and compare against Phase 0:

- Essence top-1 flip rate.
- Distinct #1 essences per user over 60 days.
- Categories appearing in visible top-3.
- Category stddev for formerly frozen categories.
- Production fingerprint result.

---

## 6. Exit Gate For Plan 1

Plan 1 is complete only when:

- Phase 0 baseline reports exist and are committed.
- Adaptive salience tests pass.
- Essence top-1 flip rate is at least 40% across the agreed cohort or subset.
- Distinct #1 essences are at least 6 per 60 days.
- Visible essence top-3 has zero opposition-pair violations in the report.
- Production fingerprint is unchanged.
- AI has summarized the report data.
- Ash has reviewed the report and explicitly approved moving to Plan 2.

Do not proceed to Plan 2 without this approval.
