# Daily Fit Narrative Layer — Plan 1: Measurement, Cohort & Adaptive Salience

**Status:** Audited implementation plan, split from `daily_fit_narrative_layer_handoff.md`.
**Scope:** Original Phase 0 and Phase 1 only.
**Audience:** **Plan 1 of 3** — the first AI developer in a sequential relay. You are not expected to implement Plan 2 or Plan 3.
**Must read first:** `daily_fit_narrative_layer_handoff.md` — §1 executive summary, §2 root-cause analysis, and the **Sequential AI developer workflow** section only. Skim §11 testing strategy. Do not implement content from Plan 2 or Plan 3 sections of the parent handoff.

---

## 0. Your place in the relay

| | |
|---|---|
| **You are** | Developer 1 of 3 — measurement baseline + adaptive salience |
| **You inherit** | Nothing from a prior narrative-layer phase. Parent handoff context only. |
| **You deliver to Developer 2** | Cohort + harnesses, `SkySalienceProfile`, improved essence signal, baseline snapshots, canvases, completion doc |
| **You must not** | Add `DailyNarrativePlan`, route surfaces through a plan layer, extend silhouette `displayPosition`, remove `resolveEssenceConflicts`, or touch production paths |

**Your workflow (in order):**

1. §3 codebase checks — confirm assumptions still hold.
2. §4 Phase 0 — baseline measurement **before** any engine changes.
3. §4.5 — Ash approves baseline; store approval in completion doc.
4. §5 Phase 1 — adaptive salience implementation.
5. Tests (§5.5) + reports (§5.6) + canvases (§4.4, §5.7).
6. §7 completion document — mandatory handoff artifact for Developer 2.
7. **Stop.** Ash assigns Plan 2 to a new developer after reviewing your completion doc and canvases.

**Completion document (write last):** `docs/handoff/completions/narrative_layer_plan1_completion.md`

Use this structure:

```markdown
# Plan 1 completion — [date]
## Exit gate checklist
- [ ] each §6 criterion with pass/fail and evidence path
## Artifacts committed
- list every fixture, canvas, script, and test file
## Metrics summary
- essence flip rate, distinct #1, opposition violations, fingerprint
## Ash approval
- date and note (or "pending")
## Known issues / notes for Plan 2
- anything the next developer must know
```

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
6. Each phase boundary must ship a mandatory Cursor canvas report (tables, pass/fail badges, diagrams) fed from committed JSON fixtures — not chat-only summaries.

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

### 4.4 Mandatory Phase 0 Canvas (Baseline Snapshot)

Before any salience code changes, create a Cursor canvas that Ash can open beside the chat for at-a-glance verification.

**File:** `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase1-baseline.canvas.tsx`

**Data sources (embed inline — no `fetch`):**

- `docs/fixtures/slider_range_report.json`
- `docs/fixtures/essence_stage1_diagnostics.json` (or the documented cohort subset fixture path)

**Required sections:**

| Section | Content |
|---------|---------|
| Cohort summary | User count, day window, deterministic seed, harness run timestamp |
| Slider range table | Per-slider mean range, % users stuck in one tertile, % users with range &lt; 0.3 |
| Slider histograms | One labeled chart per slider (axis labels + units) |
| Essence staleness table | Top-1 flip rate, distinct #1 / 60d, categories in top-3 / 14, frozen-category stddev |
| Transit dominance | % of users dominated by slow outer planets (if present in fixture) |
| Pass/fail badges | Phase 1 quantitative targets from §6 shown as pending (baseline only) |

Follow the Cursor canvas skill (`~/.cursor/skills-cursor/canvas/SKILL.md`): single `.canvas.tsx`, import only from `cursor/canvas`, no empty placeholder sections.

### 4.5 Baseline Report Review Gate

Before any salience code changes:

- AI must summarize the Phase 0 report and identify stuck sliders or stale categories.
- Ash must review the JSON fixtures **and** the Phase 0 canvas and approve continuing.
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
- Updated `docs/fixtures/slider_range_report.json` and essence diagnostics fixture.

### 5.7 Mandatory Plan 1 Exit Canvas (Before / After)

At Plan 1 completion, create or update the exit canvas showing baseline vs post-salience results.

**File:** `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase1-exit.canvas.tsx`

**Data sources (embed inline — no `fetch`):**

- Phase 0 baseline copies committed as `docs/fixtures/slider_range_report.phase0_baseline.json` and `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json` (snapshot before salience changes)
- Post-Plan-1 `docs/fixtures/slider_range_report.json` and essence diagnostics fixture

**Required sections:**

| Section | Content |
|---------|---------|
| Executive pass/fail row | Badges for each Plan 1 exit criterion in §6 |
| Essence before/after table | Flip rate, distinct #1, category coverage, frozen-category stddev — side by side |
| Essence delta chart | Bar or line chart comparing Phase 0 vs Phase 1 aggregate metrics |
| Slider range before/after | Mean range per slider; stuck-user counts |
| Opposition violations | Count across cohort (must be 0) with pass badge |
| Production fingerprint | Unchanged / changed badge |
| Salience proof diagram | Simple flow: snapshot transits → `SkySalienceProfile` → essence drivers (labels from trace fields) |

AI must link the canvas in the phase completion summary. Ash reviews this canvas — not just the JSON — before approving Plan 2.

---

## 6. Exit Gate For Plan 1

Plan 1 is complete only when:

- Phase 0 baseline reports exist and are committed.
- Phase 0 baseline canvas exists and renders real cohort data.
- Phase 0 baseline fixtures are snapshotted for later before/after comparison.
- Adaptive salience tests pass.
- Essence top-1 flip rate is at least 40% across the agreed cohort or subset.
- Distinct #1 essences are at least 6 per 60 days.
- Visible essence top-3 has zero opposition-pair violations in the report.
- Production fingerprint is unchanged.
- Plan 1 exit canvas exists with before/after tables, charts, and pass/fail badges.
- AI has summarized the report data and linked both canvases.
- Ash has reviewed the fixtures and both canvases and explicitly approved moving to Plan 2.

Do not proceed to Plan 2 without this approval.

---

## 7. Handoff to Plan 2 developer

When §6 is satisfied, commit `docs/handoff/completions/narrative_layer_plan1_completion.md`. Developer 2 will verify these exist before coding:

| Artifact | Path |
|----------|------|
| Synthetic cohort | `inspector/Resources/synthetic_cohort.json` |
| Cohort generator | `tools/synthetic_cohort.py` |
| Slider harness | `tools/slider_range_harness.py` |
| Phase 0 baseline snapshots | `docs/fixtures/slider_range_report.phase0_baseline.json`, `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json` |
| Current reports | `docs/fixtures/slider_range_report.json`, essence diagnostics fixture |
| Baseline canvas | `canvases/narrative-layer-phase1-baseline.canvas.tsx` |
| Exit canvas | `canvases/narrative-layer-phase1-exit.canvas.tsx` |
| Salience implementation | `SkySalienceProfile`, `computeSkySalience` on stage1 path |
| Completion doc | `docs/handoff/completions/narrative_layer_plan1_completion.md` |

Your session ends when the completion doc is committed and Ash has approved. A different AI developer receives `daily_fit_narrative_layer_phase_2_coherence_plan.md`.
