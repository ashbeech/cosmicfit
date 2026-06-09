# Daily Fit Narrative Layer — Plan 2: Narrative Decision Layer & Coherence Contract

**Status:** Audited implementation plan, split from `daily_fit_narrative_layer_handoff.md`.
**Scope:** Original Phase 2 only.
**Audience:** **Plan 2 of 3** — the second AI developer in a sequential relay. You are not expected to implement Plan 3.
**Prerequisite:** Plan 1 complete, committed, and **Ash-approved**. Do not start if `docs/handoff/completions/narrative_layer_plan1_completion.md` is missing or shows exit gate failures.
**Must read first:** `daily_fit_narrative_layer_handoff.md` — Sequential AI developer workflow + §1–2. Then `daily_fit_narrative_layer_phase_1_foundation_plan.md` §7 (your inherited artifacts). Skim Plan 1 exit criteria (§6) to understand what you must preserve.

---

## 0. Your place in the relay

| | |
|---|---|
| **You are** | Developer 2 of 3 — `DailyNarrativePlan`, coherence contract, surface routing |
| **You inherit** | Plan 1 cohort, harnesses, `SkySalienceProfile`, baseline snapshots, Plan 1 completion doc |
| **You deliver to Developer 3** | Plan-driven stage1 path for all surfaces, coherence harness + report, shadow + exit canvases, completion doc |
| **You must not** | Rebuild the salience model, extend six-slider `displayPosition` normalization, run final promotion validation, or delete production-compatible types without documented reason |

**Your workflow (in order):**

1. §0.1 prerequisite verification — all Plan 1 artifacts present; stop if not.
2. §3 coherence contract — implement before routing.
3. §4 implementation — shadow mode first; Ash approves shadow canvas before §5 routing.
4. §5 surface routing — one group at a time with harness re-runs.
5. Tests (§7) + report (§8) + canvases (§4.6, §8.1).
6. §10 completion document.
7. **Stop.** Ash assigns Plan 3 to a new developer.

**Completion document (write last):** `docs/handoff/completions/narrative_layer_plan2_completion.md`

Same structure as Plan 1 completion doc (see Plan 1 §0), adapted for Plan 2 §9 exit criteria. Include shadow-mode approval date and per-surface routing status table.

### 0.1 Prerequisite verification (run before any edits)

Confirm every item exists and Plan 1 exit metrics still pass:

- [ ] `docs/handoff/completions/narrative_layer_plan1_completion.md` — all §6 gates passed, Ash approval recorded
- [ ] `inspector/Resources/synthetic_cohort.json` and `tools/synthetic_cohort.py`
- [ ] `tools/slider_range_harness.py` runs successfully
- [ ] `SkySalienceProfile` / `computeSkySalience` on stage1 path
- [ ] Phase 0 baseline snapshots committed
- [ ] Plan 1 exit canvases render real data
- [ ] `ProductionFingerprintGuard_Tests` green
- [ ] Essence flip rate ≥40%, distinct #1 ≥6, opposition violations = 0 (re-run harness if unsure)

If any check fails, **stop and report to Ash.** Do not re-implement Plan 1 scope unless Ash explicitly asks.

---

## 1. Mission

This plan inserts a single `DailyNarrativePlan` before any Daily Fit surface is selected. The plan must decide one coherent story for the day, then every visible surface must be allocated from that decision.

This is the phase that satisfies the core product assumption:

> A user must never see elements, or sub-parts within an element, narratively pulling in opposite directions.

That includes obvious intra-element contradictions such as minimal plus maximalist in the same essence diagram, and cross-element contradictions such as an expansive essence story paired with a silhouette, palette, texture, or pattern selection that communicates the opposite story without the plan explicitly resolving it.

---

## 2. Audit Finding: Original Plan Needs Tightening

The original handoff is directionally correct, but it is not strict enough on contradiction prevention.

The risky parts are:

- It retains a `contrast` relationship, which could be interpreted by an implementer as permission to show opposing user-facing signals.
- It says supporting essences may come from the anchor side on contrast days, but does not forbid visible opposition pairs strongly enough.
- It says old guardrails become dead code, but does not define the exact replacement tests that prove they can be removed safely.
- Its coherence score can pass at 0.85 while still allowing some contradiction defects.

This plan fixes those gaps by defining a hard coherence contract with zero-tolerance checks for visible contradictions.

---

## 3. Coherence Contract

Implement a formal coherence contract before routing surfaces through the new path.

### 3.1 Essence Opposition Contract

Visible essence top-3 must never contain these pairs:

- minimal and maximalist
- polished and edgy
- classic and eclectic
- grounded and playful

Keep `essenceOppositions` as the single source of truth unless the product owner approves changes.

### 3.2 Cross-Surface Compatibility Contract

Create a deterministic compatibility layer that classifies each visible surface into narrative polarities. The exact implementation can be a Swift enum or data table, but it must be code-owned and tested.

Required polarity dimensions:

- restraint vs expression
- softness vs sharpness
- classicism vs experimentation
- groundedness vs motion

Every plan allocation must either:

- align within the same polarity family, or
- use an approved bridge allocation that does not expose a direct contradiction in user-facing output.

Do not allow a surface to independently override this contract.

### 3.3 Relationship Semantics

`contrast` must not mean "show contradictory elements."

If the enum is kept for compatibility, document and test it as:

- `reinforce`: sky and chart point in the same direction.
- `stretch`: sky expands the user's anchor without contradicting it.
- `soften`: sky lowers intensity while preserving the same story.
- `contrast`: an internal selector state only; final visible output must still be bridged into a coherent story.

If keeping the word `contrast` causes implementer ambiguity, rename or wrap it in the new plan layer as `bridge`.

---

## 4. Implementation Shape

### 4.1 Add `DailyNarrativePlan`

Add a dedicated `DailyNarrativePlan.swift` unless local style strongly favors `DailyFitTypes.swift`.

The plan must include:

- `relationship`
- `accentEssence`
- exactly two `supportingEssences`
- `anchorEssences`
- `intensityLevel`
- `tempoEmphasis`
- target vibrancy, contrast, metal tone, and silhouette values
- palette and tarot directives
- texture and pattern directives or equivalent selection constraints
- salience driver trace
- coherence contract trace

Do not leave texture and pattern as vague "biases." They need explicit plan-owned constraints so they cannot contradict the rest of the day.

### 4.2 Add `DailyNarrativeSelector`

Create `DailyNarrativeSelector.select`.

Required behavior:

- Use Plan 1 `skySalience` as the primary sky input.
- Use precomputed raw essence and silhouette only as candidate inputs, not final authority.
- Pick an accent essence that is backed by sky salience and not forbidden by the coherence contract.
- Pick supporting essences that do not oppose the accent or each other.
- Allocate all slider and surface directives from the same plan.
- Use `snapshot.dailySeed` for tie-breaks.

### 4.3 Add Explicit Candidate Rejection

The selector must build candidate plans and reject any candidate that violates the coherence contract.

This should be testable as a pure function:

```swift
DailyNarrativeCoherence.validate(plan: DailyNarrativePlan) -> CoherenceValidationResult
```

The result should expose pass/fail and reasons, not just a score.

### 4.4 Shadow Mode First

Before using the plan output:

- Compute `DailyNarrativePlan` beside the existing pipeline.
- Store diagnostics for plan decisions, rejected candidates, and divergence from the old path.
- Do not route surfaces yet.
- Run the cohort harness for at least 60 days.

Ash must review shadow-mode report data and the shadow-mode canvas (§4.5) before routing begins.

### 4.5 Build Coherence Cohort Harness

Create `tools/narrative_coherence_harness.py` (or extend an existing harness if one already covers plan diagnostics).

Requirements:

- Run at least 200 cohort users across at least 60 consecutive days.
- Capture `DailyNarrativePlan`, rejected candidates, coherence validation results, and final routed payloads.
- Output `docs/fixtures/narrative_coherence_report.json` and `.txt`.
- Re-run after each surface routing step in §5; commit dated snapshots when metrics shift materially (e.g. `narrative_coherence_report.after_essence.json`).

### 4.6 Mandatory Shadow-Mode Canvas

After shadow-mode harness run, before any surface routing:

**File:** `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase2-shadow.canvas.tsx`

**Data source:** `docs/fixtures/narrative_coherence_report.json` (shadow-mode section)

**Required sections:**

| Section | Content |
|---------|---------|
| Plan generation summary | Plans generated, candidates rejected by reason (table + bar chart) |
| Hard gate badges | Essence opposition violations, cross-surface violations — must show 0 before routing |
| Coherence score | Mean score with note that score alone is insufficient |
| Variation retained | Essence flip rate and distinct #1 vs Plan 1 targets |
| Shadow vs legacy divergence | % of days plan would change essence, palette, or tarot vs old path |

Ash approves routing only after this canvas shows zero hard-gate violations in shadow mode.

---

## 5. Surface Routing Order

Route one surface group at a time. Do not batch all routing into one change.

1. Essence top-3.
2. Palette slot/directive allocation.
3. Tarot card and style-edit variant target vector.
4. Vibrancy and contrast targets.
5. Silhouette targets.
6. Metal tone target.
7. Textures.
8. Pattern.

After each routing step:

- Run unit tests.
- Run the relevant cohort harness.
- Inspect the report for contradiction violations.
- Keep the previous route as the rollback path until the full phase passes.

---

## 6. Existing Guardrails: Keep, Supersede, Then Clean

The current code has useful guardrails, but they should not remain as hidden duplicate behavior once the plan owns coherence.

### 6.1 Keep Initially

Keep these live until the corresponding plan replacement is implemented and tested:

- `NarrativeIntentEngine.resolve`
- `NarrativeSelectionDirectives.resolveEssenceConflicts`
- `NarrativeSelectionDirectives.applyNarrativePaletteScoring`
- `NarrativeSelectionDirectives.selectViaNarrativeSlots`
- `NarrativeTarotBridgeSelector.select`

### 6.2 Supersede During Routing

As each surface routes through `DailyNarrativePlan`, remove that surface's dependency on the old guardrail in the stage1 path.

Required stage1 cleanup by end of Plan 2:

- Essence conflict prevention is handled by `DailyNarrativeCoherence.validate`, not by post-hoc swapping.
- Palette allocation reads the plan's palette directive directly.
- Tarot selection reads the plan's tarot directive directly.
- Vibrancy, contrast, metal, silhouette, textures, and pattern no longer independently invent narrative direction.

### 6.3 Do Not Delete Production-Compatible Types Prematurely

Do not delete files needed by production, legacy decode, tests, or diagnostic comparison.

End state for Plan 2:

- Old narrative components may still compile.
- Stage1 plan-driven path must not call old post-hoc conflict correction.
- Any retained old code must have a named reason: production compatibility, diagnostic comparison, or planned removal after Plan 3 cleanup.

Add a test or static assertion that the stage1 plan-driven path does not call the old essence conflict resolver.

---

## 7. Required Tests

Add tests for:

- Plan determinism.
- Plan completeness.
- Accent essence backed by salience.
- Supporting essence count is exactly two.
- No visible essence opposition pairs, with 100% pass target.
- Candidate rejection explains every contradiction.
- Cross-surface compatibility contract rejects contradictory allocations.
- `contrast` or bridge days still produce coherent visible output.
- Every routed surface reads its narrative direction from `DailyNarrativePlan`.
- Production fingerprint unchanged.

The aggregate coherence score can remain, but it is not enough. Hard contradiction tests must be zero-tolerance.

---

## 8. Required Report Output

For the cohort across at least 60 days, report:

- Number of generated plans.
- Number of rejected candidate plans by reason.
- Essence opposition violations.
- Cross-surface contradiction violations.
- Coherence score.
- Essence variation retained from Plan 1.
- Tarot variant match rate.
- Palette directive match rate.
- Slider target match rate.
- Surfaces still using legacy guardrails.

The report must clearly identify any remaining old code dependency.

Commit final output as `docs/fixtures/narrative_coherence_report.json` and `.txt`.

### 8.1 Mandatory Plan 2 Exit Canvas

At Plan 2 completion, after all surfaces are routed:

**File:** `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase2-exit.canvas.tsx`

**Data sources (embed inline — no `fetch`):**

- Final `docs/fixtures/narrative_coherence_report.json`
- Plan 1 exit metrics (from `docs/fixtures/essence_stage1_diagnostics.json` or phase0/phase1 baseline copies) for variation comparison

**Required sections:**

| Section | Content |
|---------|---------|
| Executive pass/fail row | Badges for every Plan 2 exit criterion in §9 |
| Hard gate panel | Opposition violations (0), cross-surface violations (0) — prominent pass/fail |
| Surface routing checklist | Table: essence, palette, tarot, vibrancy/contrast, silhouette, metal, textures, pattern — each row shows plan-driven vs legacy guardrail |
| Rejected candidates | Breakdown by rejection reason |
| Match rates | Tarot variant, palette directive, slider target — table with targets |
| Coherence score | Mean with dimension breakdown if available |
| Variation retained | Side-by-side with Plan 1: flip rate, distinct #1, category coverage |
| Legacy dependency callout | Surfaces or code paths still calling old guardrails (must be none in stage1 plan path) |
| Narrative flow diagram | `skySalience` → `DailyNarrativePlan` → routed surfaces (labeled boxes) |

AI must link the canvas in the phase completion summary. Ash reviews this canvas before approving Plan 3.

---

## 9. Exit Gate For Plan 2

Plan 2 is complete only when:

- All surfaces in stage1 are routed through `DailyNarrativePlan`.
- Visible essence opposition violations are exactly zero.
- Cross-surface contradiction violations are exactly zero under the implemented compatibility contract.
- Coherence score is at least 0.85, but no hard contradiction test is allowed to fail.
- Essence variation targets from Plan 1 are maintained.
- Old stage1 post-hoc guardrails are no longer called in the plan-driven path.
- Retained old code is documented with a concrete reason.
- Production fingerprint is unchanged.
- `narrative_coherence_report` fixture committed.
- Shadow-mode canvas reviewed and zero hard-gate violations confirmed before routing.
- Plan 2 exit canvas exists with routing checklist, hard-gate panel, and pass/fail badges.
- AI has summarized the cohort report and linked both Plan 2 canvases.
- Ash has reviewed the fixtures and both canvases and explicitly approved moving to Plan 3.

Do not proceed to Plan 3 without this approval.

---

## 10. Handoff to Plan 3 developer

When §9 is satisfied, commit `docs/handoff/completions/narrative_layer_plan2_completion.md`. Developer 3 will verify these exist before coding:

| Artifact | Path |
|----------|------|
| Plan 1 completion doc | `docs/handoff/completions/narrative_layer_plan1_completion.md` |
| Plan 2 completion doc | `docs/handoff/completions/narrative_layer_plan2_completion.md` |
| Narrative plan types | `DailyNarrativePlan`, `DailyNarrativeSelector`, `DailyNarrativeCoherence` |
| Coherence harness | `tools/narrative_coherence_harness.py` |
| Coherence report | `docs/fixtures/narrative_coherence_report.json` |
| Shadow canvas | `canvases/narrative-layer-phase2-shadow.canvas.tsx` |
| Exit canvas | `canvases/narrative-layer-phase2-exit.canvas.tsx` |
| All surfaces routed | stage1 plan-driven path for essence → pattern (§5) |
| Variation preserved | essence metrics still meet Plan 1 targets |

Your session ends when the completion doc is committed and Ash has approved. A different AI developer receives `daily_fit_narrative_layer_phase_3_validation_plan.md`.
