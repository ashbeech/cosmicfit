# SG-3 Handoff & Defect Report (for external audit)

> **Purpose.** A complete picture of the SG-3 narrative-regeneration work: what was
> built, the first production run (149/192 clusters), every defect class the
> post-run audit found, the fixes applied to the prompt and write gate, and the
> open risks a second reviewer should scrutinise **before** the corrected re-run.
> **Status: NOT at gate.** No `SG-3_GATE.md` has been written. The first run was
> stopped deliberately after a systemic defect (palette literal-name leakage) was
> caught by manual review.
>
> Authored 2026-07-07. Repo root: `/Users/ash/dev/mobile_apps/cosmicfit`.

---

## 1. What SG-3 is

SG-3 regenerates the Style Guide narrative cache in the **instructional coach
genre** defined by the 16 hand-authored golden guides (`docs/style_guide/golden/`)
and the rubric (`docs/style_guide/style_standard.md`), replacing the shipped
"flattering description" prose. It fills the **frozen** SG-2 contracts (placeholder
vocabulary, output-contract schema, cache schema v2, ranked tables, formula
vocabulary — see `docs/style_guide/decisions/injection_contract_freeze.md`) and
adds a **blocking write gate** so bad paragraphs never land in the cache.

Scope is **192 representative clusters only** (a validation milestone, never a
shippable cache — the shipped app keeps its 576-cluster v1 cache). Scaling to 576
is SG-4.

---

## 2. Architecture / file map

**Python pipeline (all under `tools/`):**

| File | Role |
|---|---|
| `sg_profile.py` | Coarse `ChartAestheticProfile`, a faithful mirror of the Swift derivation; composes `coreFormula` from the frozen dataset table. `--parity` asserts against `profile_expectations.json`. |
| `sg_validation.py` | The **write gate** + all rule loading from the single source of truth. Dash / tic / formula / placeholder / season / **literal-leak** / **required-placeholder** checks; phrase-dedup helpers. |
| `sg_generate.py` | System prompt (coach voice), per-section task prompts, Style-DNA preamble, ranked-item grounding, test/trap selection, structured schema, and the **cluster orchestration** (sequential + dedup + gate retry/quarantine + holistic pass + cache-v2 assembly). |
| `sg_accessory_plan.py` | `accessoryCategoryPlan` from the ranked `accessory_specs` table (include/merge/omit → 3 slots). |
| `backfill_narratives.py` | CLI entrypoint: backup gate, key/model resolution, **cross-cluster parallel workers**, resume-from-partial, run log, quarantine + triage sidecars. |
| `build_representative_clusters.py` | Builds `tools/representative_clusters.json` (192, all golden force-included, coverage assertions). |
| `build_test_trap_library.py` | Builds `data/style_guide/test_trap_library.json` from the golden guides. |
| `render_cluster.py` | Review aid: renders a cache cluster to a readable composed guide (approximate placeholder fill — NOT the production renderer). |
| `sg3_report.py` | Validator report (quality re-scan, run-log stats, accessory comparison). |
| `sg3_diff_pack.py` | Slate current-v1 vs regen-v2 vs ideal diff pack. |
| `sg3_audit.py` | **Deep defect audit** (the tool that found the issues in §5). |

**Data artifacts (`data/style_guide/`):**
- `style_guide_rules.json` — **single source of truth** for gate rules (banned tics, dash regex, excluded keywords, season words, filler lexicon, repetition budgets, write-gate error/warning taxonomy). Intended to be loaded by BOTH this Python gate and the future SG-4 Swift `StyleGuideCoherenceValidator` (parity test is an SG-4 deliverable).
- `test_trap_library.json` — register-keyed named tests & traps.
- `section_examples.json` — verbatim golden excerpts (now used ONLY as the example-copy gate backstop; no longer injected into prompts — see §6.4).
- `blueprint_narrative_cache_sg3.json` — the regenerated cache (149 clusters from run 1).

**Swift:** `CodeSection.aiFraming: String?` added (`BlueprintModels.swift`) with a back-compat decode test (`SG2DataContractTests.swift::codeAiFramingBackCompat`). Not run under xcodebuild in this environment; needs CI.

---

## 3. Generation design (one cluster)

1. Derive the coarse profile from the cluster key (pure function; parity-tested).
2. For each of 16 section keys, **sequentially**:
   - build a prompt = Style-DNA preamble + formula binding + section task + placeholder/role grounding + selected test/trap + prior-decisions summary + phrase-dedup "do not reuse" hints;
   - call the model for structured `{text, sectionIntro}`;
   - run the **write gate**; on error, retry with a repair prompt (max 2), else **quarantine** (never written to cache);
   - deterministically attach `rankedItems` / `tests` / `traps` from the tables/library;
   - update the decisions accumulator and dedup set.
3. A **holistic pass** revises all 16 for cross-section repetition + voice + threads the closing line (each revision re-gated; reverts if it fails).
4. Assemble a cache-v2 cluster object `{coreFormula, closing, <section>:{text,sectionIntro,rankedItems,tests,traps}}`.

Cache is written after **every cluster** (resumable; `--resume-from-partial`).

---

## 4. Run 1 (the run we stopped)

- Model **`gemini-2.5-pro`**, 3 parallel workers, ~2.5 min/cluster wall-clock.
- **149/192 clusters completed and saved** before we stopped it deliberately.
- Write-gate result: **0 quarantined**, 0 dashes, 0 banned tics, 0 season words, formula threaded, closings correct — i.e. it passed everything the gate *checked*. The defects in §5 are things the gate **did not** check (that is the core lesson).

---

## 5. Defects found by the post-run audit (`sg3_audit.py` over 149 clusters)

| # | Class | Count | Severity | Root cause |
|---|---|---|---|---|
| 1 | **Palette literal-colour leakage** | **149/149** | Critical | Prompt injected the ranked colour *names* as grounding AND asked for placeholders; model did both. Literal names would ship verbatim to every user in the bucket, contradicting their resolved swatches (the exact swatch-vs-text gap SG-2 2e Layer B exists to close). |
| 2 | Over-length sections | 135 | Medium | No length discipline in the new prompt/gate (the old 50–150-word cap was dropped). Palette/occasions ran 220–240 words; drives redundancy. |
| 3 | Few-shot example copying | 41 | Medium | Golden excerpts were injected as few-shot examples; the model reproduced ≥12-word runs (esp. `occasions_daily`, `accessory_1`). |
| 4 | Cross-cluster phrase stamping | 23 phrases | Medium | (a) Injected test/trap strings reproduced near-verbatim across a register (one pharmacy line on ~100 bold charts); (b) the compass line copied from an example (~100); (c) rubric-required "one or two strong pieces per look" (~126, partly by design). Cache-scale tics in the making. |
| 5 | Group-B sections missing placeholders | 20 | Medium | `hardware_stones` / `hardware_tip` / `pattern_tip` sometimes emitted zero placeholders (fully abstract), so no per-user substitution happens. |
| 6 | Textures fibre-name leakage | 9 | Low–Med | Same class as #1 for `texture_good_*`. |
| 7 | `occasions_daily` formula "missing" | 7 | Low | Almost certainly case-sensitivity false positives (gate matched case-insensitively, audit exact-case). Worth normalising. |

**Confirmed CLEAN (0 findings):** American spelling, palette temperature-word disagreement, omitted-accessory-category leakage, duplicate identical sections across clusters, unknown placeholder tokens, blueprint formula-verbatim, closing-ends-with-formula, accessory final-term reference, dashes, banned tics, season words.

The single most important meta-finding: **the write gate only catches what it is told to check.** #1, #3, #5 all sailed through the gate. The fixes below add the missing checks so the gate — not manual review — is the backstop.

---

## 6. Fixes applied (ready for the re-run)

1. **Group-B grounding is now roles-only** (`sg_generate._ranked_grounding_block`). Palette/textures prompts receive a `{placeholder} = role/use-case` map and **never a literal colour/fibre name**. (Fixes #1, #6 at source.)
2. **New blocking gate check — `literal_name_leak`** (`sg_validation.find_literal_leaks`). Any ranked colour name in a Group-B section, or fibre name in a texture section, outside placeholders → error → repair/quarantine. Verified it now blocks the run-1 leaky paragraphs. Colour names are gated in **all** Group-B sections (they leaked into hardware too). Pattern/metal/stone *names* are deliberately NOT leak-gated (the golden guides name them literally).
3. **New blocking gate check — `missing_required_placeholder`** (`sg_validation.missing_required_placeholders`). Each non-tip Group-B section must contain its required placeholder families (e.g. `hardware_stones` needs `{stone_*}`, palette needs `≥2 core_colour_* + ≥1 accent_colour_*`). (Fixes #5.)
4. **Few-shot examples removed from prompts**; retained only as the **`example_copy` gate backstop** (≥10-word shared run with any golden excerpt → error). The example text also re-introduced literal colours, so removing it helps #1 too. (Fixes #3.)
5. **Length discipline**: prompt now targets 60–130 words (style_core 2×~80–110); gate emits a `too_long` warning >180 words. (Mitigates #2; note: warning, not block — see risks.)
6. **Test/trap de-stamping**: prompt instructs the model to express the test/trap in the reader's **own words** (not the stock sentence), and `select_tests_traps` now **rotates** the library choice by a hash of the cluster key so one canonical line is not stamped across a whole register. (Mitigates #4.)
7. **Re-run model** set to **`gemini-3.1-pro-preview`** (via `GEMINI_MODEL`), per the owner's directive.

All fixes are code-level in `sg_generate.py` / `sg_validation.py` / `style_guide_rules.json`; the gate self-test and profile parity still pass.

---

## 7. Open risks / what a second auditor should scrutinise

1. **Residual required-phrase recurrence.** Some cross-cluster recurrence is *mandated* by the rubric: `coreFormula` verbatim (Blueprint, Occasions, closing), the "one or two strong pieces per look" principle (Accessory), a sensory compass (Blueprint). De-stamping cannot remove these; it can only vary the surrounding phrasing. **Question for the auditor:** is the *contract-required* recurrence acceptable, and is the *non-required* phrasing now varied enough? Re-run the audit's `C_phrase_stamped` after the corrected run and judge the residual.
2. **Length is a warning, not a block.** If 3.1-pro still runs long, verbosity persists. Consider promoting to a hard block, or a max-word cap, if the re-run audit still shows many `too_long`.
3. **`render_cluster.py` is an approximation.** It fills placeholders with representative bucket values, not the real `NarrativeTemplateRenderer`. Final human sign-off ideally views **real composed output from the app** (SG-4 inspector territory). Do not treat the rendered pack as ground truth for per-user colour fidelity.
4. **Hardware metal/stone leakage is NOT gated.** Metals/stones are placeholder-substituted in the cache but the golden guides also name them literally, so we did not leak-gate them. Run 1 used `{metal_*}` correctly, but a literal metal name could slip through unblocked. Decide whether to leak-gate these too (risk: false positives on common words like "gold"/"steel").
5. **Pattern names allowed literally by design.** The tailored-vs-fluid split names weave patterns (herringbone, houndstooth) verbatim in the golden guides, so `pattern_narrative` is not leak-gated for pattern names — but it *is* gated for colour names and must still use `{recommended_pattern_*}`. Confirm this is the intended contract.
6. **Temperature check is a coarse heuristic** (presence of the opposite temperature word). It could miss subtle disagreement. SG-4's three-way check (prose == V4 == profile) is the real gate.
7. **Coarse-profile parity covers the 16 golden charts only.** The other 560 combinations are correct *by construction* (pure function of the key). Spot-checking a handful against the Swift engine would harden confidence.
8. **`example_copy` gate uses 10-word shared runs** — could false-positive on genuinely common instructional phrasing and cause avoidable quarantine/retry. Monitor the re-run's retry/quarantine rate.
9. **Operational**: 3.1-pro is ~13 min/cluster single-stream; full 192 with 3 workers ≈ 14h. Resumable, pre-approved spend, but long.
10. **Swift `aiFraming` test not executed here** (no xcodebuild). Needs a CI/test run to confirm compile + decode.
11. **Two-layer validator parity is not yet built.** `style_guide_rules.json` is the shared source, but the SG-4 Swift validator that must load it — and the parity test proving Python and Swift agree — is an SG-4 deliverable. Until then, only the Python side enforces these rules.
12. **Decisions accumulator + dedup are heuristic.** They reduce but do not guarantee elimination of cross-section repetition; the holistic pass is the safety net. Judge coherence on real composed guides.

---

## 8. How to reproduce / re-run / re-audit

```bash
# profile parity (must PASS 16/16)
.venv/bin/python tools/sg_profile.py --parity

# write-gate self-test
.venv/bin/python tools/sg_validation.py

# deep audit of an existing cache
.venv/bin/python tools/sg3_audit.py --cache data/style_guide/blueprint_narrative_cache_sg3.json

# corrected full re-run (192, 3.1-pro, resumable)  [pre-approved spend]
# Blocker-1 fix: start on a FRESH file so no run-1 (old-prompt/old-model) cluster
# is inherited. Keep run 1 aside for diffing. --resume-from-partial is then only
# for crash recovery within this run (and it re-gates existing sections).
mv data/style_guide/blueprint_narrative_cache_sg3.json \
   data/style_guide/blueprint_narrative_cache_sg3_run1.json
nohup .venv/bin/python -u tools/backfill_narratives.py \
  --clusters tools/representative_clusters.json \
  --backup-dir data/content_backups/2026-07-07_pre-phase-3 \
  --workers 3 --resume-from-partial \
  --output data/style_guide/blueprint_narrative_cache_sg3.json \
  > data/style_guide/sg3_console.log 2>&1 &   # model auto-resolves to gemini-3.1-pro-preview
```

---

## 9. Exit criteria still outstanding for the SG-3 gate

- Corrected re-run of all 192 with the fixes above.
- `sg3_audit.py` shows **0** for classes #1, #3, #5, #6 and an acceptable residual for #2, #4 (reviewer's call).
- Zero quarantine remaining (or all quarantined items resolved).
- Slate diff pack + validator report + ≥3 non-Slate golden samples + accessory-plan comparison produced.
- Human sign-off, then `docs/style_guide/gates/SG-3_GATE.md` = `AWAITING REVIEW` → `APPROVED`.

---

## 9a. Second-review round (external audit response, 2026-07-07)

An external audit of this handoff found three **blockers** and several cheaper
issues on top of §5. All are now fixed in code and verified; the audit itself
confirmed profile parity (16/16), the gate self-test, and that the new gate
blocks 456/2384 run-1 sections. Resolution:

**Blocker 1 — resume would keep the 149 defective clusters.** `--resume-from-partial`
skipped any cluster with 16 sections + a closing, and `existing_passing_sections`
never re-gated. **Fixed:** (a) `existing_passing_sections` now RE-GATES every
existing section against the current gate and drops failures (verified: the
run-1 leaky Blaze cluster now reports 13/16 → regenerates); (b) the corrected run
starts on a **fresh output file** (run-1 output moved aside for diffing), so
`--resume-from-partial` is purely crash recovery. See the §8 command.

**Blocker 2 — pass-over list vs leak gate contradiction (88/192 clusters).** Four
colour lanes' `passOver` strings contain lexicon names (e.g. "icy grey"), so the
model was told to write words the new leak gate then rejected. **Fixed:**
`find_literal_leaks` takes `allowed_phrases` (the chart's own pass-over list) and
strips them before matching. Verified: naming the pass-over colours passes, a
stray "camel/oxblood" still blocks.

**Blocker 3 — silent mid-run downgrade to flash.** `GeminiClient` could switch a
worker to `gemini-2.5-flash` on a 404, unlogged. **Fixed:** `MultiKeyGenerator`
disables the fallback (`_fallback_model → None`), so a retired model is a hard
error, not a downgrade; and the model id is now recorded on **every run-log
entry**, so a post-run audit can prove the model per cluster.

**Cheaper items (all done):**
- `sectionIntro` and `closing` are now gated (dash / tic / leak / season /
  spelling); intro checks fold into `gate_section` via `gate_intro`.
- Length is now a **hard block**, section-specific: 200 words default, 280 for
  `style_core` (was a 180 warning that fired on 95/149 style_core sections).
- `sg3_audit.py` raised to gate coverage: literal-leak over **all** Group B
  sections (was palette+textures_good only — now catches 397 vs 158), formula
  checks made case-insensitive (kills the §5 #7 false positive), and
  **per-register stamping** added (found 62 register-conditional stamps the
  global 40% threshold missed, e.g. the touch test in 55/74 quietLuxury clusters).
- Holistic revisions now re-gate **with** the example-copy guard and intro.

**Accepted / documented (not changed), per the auditor's own recommendation:**
- **Metal/stone leak-gating left OFF** (§7.4): false-positive risk is real
  ("steel blue" is a colour, "gold" is common); run 1 used `{metal_*}` correctly.
- **Required-phrase recurrence** (§7.1) is contract-mandated; judged after the run.
- **Test/trap rotation is a no-op for single-entry pools** (hardware has 1
  test/1 trap per register). Accepted consciously: the "express in your own
  words" instruction is the mitigation; expand the library later if hardware
  stamping shows up in the re-run audit.
- **`texture_bad` fibre lexicon gap:** the leak lexicon is built from the ranked
  *good*-textures table, so literal *bad*-fibre names ("polyester") in
  `textures_bad` are under-gated (they should still be `{texture_bad_*}`
  placeholders, which the required-placeholder check enforces). Flagged for a
  follow-up lexicon if the re-run audit shows leakage there.

## 10. TL;DR for the auditor

The engine, profile parity, gate framework, orchestration, resumability, and accessory logic are solid and the coach genre reads well across registers. The first run exposed that **the write gate under-checked** — it missed literal-name leakage, few-shot copying, and missing placeholders. Those checks are now added and the leaky class is verified blocked. Please pressure-test §7, especially (1) required-phrase recurrence, (2) whether length should hard-block, and (4) hardware metal/stone leakage — and tell us what else we have not thought to check before we spend ~14h on the corrected 192-cluster run.
