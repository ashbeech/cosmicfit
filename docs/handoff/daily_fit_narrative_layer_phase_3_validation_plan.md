# Daily Fit Narrative Layer — Plan 3: Unified Slider Normalization, Cohort Validation & Promotion Gate

**Status:** Audited implementation plan, split from `daily_fit_narrative_layer_handoff.md`.
**Scope:** Original Phase 3 and Phase 4 only.
**Audience:** **Plan 3 of 3** — the final AI developer in the relay. This is the last implementation phase before Ash's promotion decision.
**Prerequisite:** Plans 1 and 2 complete, committed, and **Ash-approved**. Do not start if either completion doc is missing or shows exit gate failures.
**Must read first:** `daily_fit_narrative_layer_handoff.md` — Sequential AI developer workflow + §11 testing strategy. Then Plan 1 §7 and Plan 2 §10 (inherited artifacts). You do not need to re-read full Plan 1/2 implementation sections unless verifying a specific dependency.

---

## 0. Your place in the relay

| | |
|---|---|
| **You are** | Developer 3 of 3 — six-slider normalization, final cohort validation, cleanup audit |
| **You inherit** | Full plan-driven stage1 path from Plan 2, cohort + harnesses from Plan 1, all prior fixtures and canvases |
| **You deliver to Ash** | Six-slider display positions, cohesion harness report, exit canvas, promotion recommendation (if hard gates pass), cleanup audit, completion doc |
| **You must not** | Redesign `DailyNarrativePlan` or the coherence contract, rebuild salience, promote to production without Ash's separate decision, or delete compatibility code without cleanup audit justification |

**Your workflow (in order):**

1. §0.1 prerequisite verification.
2. §3 slider normalization implementation.
3. §4 cohesion harness + validation metrics.
4. §4.4 exit canvas + §4.5 report review.
5. §5 cleanup audit (classify only — removal only where tests prove safe).
6. §7 completion document.
7. **Stop.** Production promotion is Ash's decision, not yours.

**Completion document (write last):** `docs/handoff/completions/narrative_layer_plan3_completion.md`

Include every §6 exit criterion, four-dimension metric table, promotion recommendation status, and cleanup audit summary.

### 0.1 Prerequisite verification (run before any edits)

- [ ] `docs/handoff/completions/narrative_layer_plan1_completion.md` — passed, Ash-approved
- [ ] `docs/handoff/completions/narrative_layer_plan2_completion.md` — passed, Ash-approved
- [ ] `DailyNarrativePlan` routes all stage1 surfaces (Plan 2 §5)
- [ ] `docs/fixtures/narrative_coherence_report.json` — hard gates at 0 violations
- [ ] Plan 2 exit canvas exists and matches fixture data
- [ ] Phase 0 baseline snapshots still committed (needed for before/after)
- [ ] `ProductionFingerprintGuard_Tests` green
- [ ] Essence variation targets from Plan 1 still met

If any check fails, **stop and report to Ash.** Do not re-implement Plan 1 or Plan 2 scope unless Ash explicitly asks.

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
5. Ash reviews the final report and exit canvas before any production decision.
6. Each phase boundary must ship a mandatory Cursor canvas report (tables, pass/fail badges, diagrams) fed from committed JSON fixtures — not chat-only summaries.

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

### 4.4 Mandatory Plan 3 Exit Canvas (Full Validation)

After the cohesion harness run, create the final validation canvas. This is the primary deliverable Ash uses to decide promotion.

**File:** `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase3-exit.canvas.tsx`

**Data sources (embed inline — no `fetch`):**

- `docs/fixtures/narrative_cohesion_report.json`
- `docs/fixtures/slider_range_report.json` (post–Plan 3, all six sliders)
- Phase 0 baseline copies: `docs/fixtures/slider_range_report.phase0_baseline.json`, `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json`
- Plan 2 final `docs/fixtures/narrative_coherence_report.json` (coherence mid-point reference)

**Required sections — four validation dimensions:**

| Dimension | Canvas content |
|-----------|----------------|
| **Variation** | Before/after table: essence flip rate, distinct #1, category coverage, palette diversity; slider range coverage for all 6 sliders; stuck-slider count |
| **Coherence** | Hard gates (0 opposition, 0 cross-surface); mean coherence score; texture/pattern/tarot match rates |
| **Sky accuracy** | Accent–salience match %, salience-driver validity %, determinism badge |
| **User applicability** | Palette-from-blueprint %, metal/saturation/contrast baseline respect % |

**Also required:**

- Executive pass/fail row for every hard target in §4.3 and every quantitative target (weak passes flagged separately).
- Before/after charts spanning Phase 0 baseline → Plan 3 final for essence staleness and slider travel.
- System architecture diagram: `SkySalienceProfile` → `DailyNarrativePlan` → six sliders + surfaces.
- Promotion recommendation panel: promote / do not promote / promote with documented exceptions — only if hard targets pass.

Follow the Cursor canvas skill. Omit sections with no data; do not render placeholders.

### 4.5 Report Review Process

Generate:

- `docs/fixtures/narrative_cohesion_report.json`
- `docs/fixtures/narrative_cohesion_report.txt` (or `.md` summary)
- `docs/fixtures/narrative_layer_promotion_recommendation.md` only if all hard targets pass
- Plan 3 exit canvas (mandatory — not optional)

AI must analyze the report and canvas data and explicitly call out failures, weak passes, suspicious metrics, or signs of overfitting.

Ash must review the cohesion fixtures, the exit canvas, and any promotion recommendation. Passing tests alone is not approval.

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
- Plan 3 exit canvas exists with four-dimension tables, before/after charts, hard-gate badges, and promotion panel.
- AI has linked the exit canvas and summarized pass/fail against every §4.3 target.
- Ash has reviewed the final fixtures, exit canvas, and made a separate production promotion decision.

Do not promote to production automatically.

---

## 7. Final handoff to Ash (end of relay)

When §6 is satisfied, commit `docs/handoff/completions/narrative_layer_plan3_completion.md`. This closes the three-developer relay. There is no Plan 4 implementation handoff.

| Artifact | Path |
|----------|------|
| Plan 1 + Plan 2 completion docs | `docs/handoff/completions/narrative_layer_plan1_completion.md`, `narrative_layer_plan2_completion.md` |
| Plan 3 completion doc | `docs/handoff/completions/narrative_layer_plan3_completion.md` |
| Cohesion harness | `tools/narrative_cohesion_harness.py` |
| Final cohesion report | `docs/fixtures/narrative_cohesion_report.json` |
| Updated slider report | `docs/fixtures/slider_range_report.json` (all six sliders with displayPosition) |
| Exit canvas | `canvases/narrative-layer-phase3-exit.canvas.tsx` |
| Promotion recommendation | `docs/fixtures/narrative_layer_promotion_recommendation.md` (if hard gates pass) |
| Cleanup audit | recorded in Plan 3 completion doc |

Ash uses the exit canvas and promotion recommendation to decide production promotion. Your session ends when the completion doc is committed — not when production is promoted.
