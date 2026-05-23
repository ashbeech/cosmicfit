# Daily Fit — Sun-Sign & Zodiac Meaning Allocation Audit — Handoff

**Status:** Not started — spec for executing developer / AI agent  
**Date:** 2026-05-22  
**Task type:** **Audit and report only — no code changes**  
**Audience:** Engineer or AI agent auditing whether zodiac-linked meaning weights are correct, justified, and produce sensible downstream Daily Fit output  
**Origin:** Product owner (Ash) needs confidence that allocations like “Leo → Drama ×1.5, Utility ×0.9” (and every similar boost/dampen across all signs) are intentional, defensible, and not distorting final UX — not just numerically present in code.

### Hard constraint — read first

| Allowed | Not allowed in this ticket |
|---------|---------------------------|
| Read Swift, run inspector, run existing tests, export/copy numbers into reports | Editing `Cosmic Fit/`, `inspector/`, tests, calibration tables, or scripts that change engine behaviour |
| Spreadsheet / MD / CSV analysis, screenshots, JSON exports from `/api/inspect` | Adding temporary test hooks, “all 1.0 multiplier” branches, new XCTest assertions, or “small fixes” while auditing |
| **Recommend** changes in the report (D5) with exact proposed values | **Implementing** those recommendations (separate follow-up ticket after Ash sign-off) |
| Optional: commit **report artifacts only** under `docs/fixtures/` | PRs that touch production logic “to help the audit” |

If a counterfactual (e.g. “what if all multipliers were 1.0?”) cannot be answered without code changes, **document it as a finding** and use **analytic estimates** (§6.4 pure-math sensitivity) or **engine-mode comparison** (standard vs `stage1_experimental` sky path) instead of modifying the repo.

**Related docs:**
- `docs/handoff/inspector_derivation_drilldown_handoff.md` — how to trace raw → post-multiplier → final in inspector
- `docs/calibration_signoff.md` — prior partial review (planet bases, element boosts); **does not** fully justify per-sign multipliers or numeric magnitudes
- `docs/handoff/daily_fit_stage2_calibration_handoff.md` — notes sign multipliers can dominate vibe quantization
- `docs/handoff/daily_fit_sky_forward_v2_refactor_handoff.md` — `stage1_experimental` sky path **skips** sign multipliers for daily vibe; chart anchor still uses chart mix + multipliers on chart vibe path

---

## 1. Executive summary

### 1.1 What Ash is asking

> “Who says Drama for Leo is 1.5 and Utility is 0.9? Same question for every sign and every energy — is the **meaning** right and is the **weight** right? Does that still produce the correct final output?”

This handoff directs a **full audit** of the **zodiac → style-energy meaning layer** in Stage 1: every boost and dampen, with written rationale, numeric review, and downstream verification. Outcome may be “keep as-is with documented rationale” or “change specific cells with evidence.”

### 1.2 What this layer is (one sentence)

After the engine sums weighted astrological inputs into six continuous **raw energy scores** (Classic, Playful, Romantic, Utility, Drama, Edge), it multiplies each score by a **natal Sun-sign preference** from `DailyFitCalibration.signEnergyMap`, producing **post-multiplier** scores, then normalises to the 21-point vibe budget (production / standard engine).

That Sun-sign pass is a **chart-identity filter**: “this user’s Leo Sun tends to express more Drama, less Utility,” applied uniformly to whatever the sky did that day.

### 1.3 What this handoff is NOT

- **Not** any implementation work — **no code changes** in this ticket (see hard constraint above)  
- **Not** a refactor of Stage 2 (palette, vibrancy, silhouette formulas) — only audit inputs that Stage 2 consumes  
- **Not** Style Guide / Blueprint colour family logic  
- **Not** tarot card text or narrative generation  
- **Not** writing new tests or calibration patches — only **list gaps** (D6); test/code updates are a **later** ticket if Ash approves D5  
- **Not** shipping multiplier fixes — recommendations go in the report; implementation is explicitly **out of scope** (§9)

---

## 2. Scope — tables to audit

Treat these as one **“meaning allocation family”** — all assign semantic lean from zodiac/planet/phase to the six energies. **Primary** focus is §2.1; **secondary** is §2.2–2.5 (stacking and confounding).

### 2.1 Primary: `SignEnergyMap` (sun-sign post-multipliers)

| Property | Value |
|----------|--------|
| **Location** | `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` — `DailyFitCalibration.default.signEnergyMap` |
| **Applied in** | `DailyEnergyEngine.applySignMultipliers` — uses **natal Sun sign only** |
| **When it runs** | After raw accumulation, before `normaliseToTwentyOne` (standard / production vibe path) |
| **Inspector label** | “Sun-sign multipliers” / “Post-multiplier” in vibe drill-down |
| **Provenance** | Comment claims legacy `VibeBreakdownGenerator.getSunSignEnergyPreference()`; that generator **no longer exists** in repo — values were copied at Daily Fit rebuild and are only spot-checked by 4 tests |

**Audit every cell:** 12 signs × 6 energies = **72 multipliers**.

Expected range per code comment: ~**0.85–1.5** (neutral = **1.0**). Values outside that range are defects.

### 2.2 Secondary: `elementBoosts` (sign element on each planet)

| Property | Value |
|----------|--------|
| **Location** | `DailyEnergyEngine.swift` — private `elementBoosts` |
| **Applied in** | `accumulateChartContribution` — **every** natal/progressed planet gets element boost from **that planet’s sign element**, not Sun sign alone |
| **Effect** | Fire → +0.1 Drama, +0.05 Playful; Earth → +0.1 Classic, +0.05 Utility; Air → +0.1 Playful, +0.05 Edge; Water → +0.1 Romantic, +0.05 Drama |

**Risk:** Double-counting fire-sign “drama” — e.g. Leo Sun gets Drama boost via §2.1 **and** Leo planets get Fire element boost in §2.2. Audit must note **stacking**.

### 2.3 Secondary: `planetEnergyBase` (planet → energy affinity)

| Property | Value |
|----------|--------|
| **Location** | `DailyEnergyEngine.swift` — private `planetEnergyBase` |
| **Applied in** | Natal, progressed, transit accumulation |
| **Prior review** | `docs/calibration_signoff.md` §2.1 — planet-by-planet pass |

Re-audit only where sign-layer audit finds downstream surprises (e.g. Mars transits always swamp Leo drama bias).

### 2.4 Secondary: `lunarPhaseEnergies` (phase → energy bias)

| Property | Value |
|----------|--------|
| **Location** | `DailyEnergyEngine.swift` — `lunarPhaseEnergies` |
| **Applied in** | `accumulateLunarContribution` |

Not sign-based but affects same six energies; include if audit compares “chart identity vs sky” balance.

### 2.5 Secondary: `axisElementModifiers` (element → axis, not vibe energy)

| Property | Value |
|----------|--------|
| **Location** | `DailyEnergyEngine.swift` — `axisElementModifiers` |
| **Effect** | Fire signs on transits/planets push visibility/action; Earth pushes strategy; etc. |

Does not use `SignEnergyMap` but uses **same zodiac→meaning philosophy**. Optional Phase B if time: 4 axes × 4 elements = 16 modifiers.

---

## 3. Reference — current `SignEnergyMap` (full matrix)

Source of truth: `DailyFitTypes.swift` lines ~534–547. Re-verify against file at audit time.

| Sign | Classic | Playful | Romantic | Utility | Drama | Edge |
|------|---------|---------|----------|---------|-------|------|
| Aries | 0.90 | 1.30 | 1.00 | 1.00 | 1.40 | 1.20 |
| Taurus | 1.50 | 0.90 | 1.30 | 1.20 | 0.85 | 1.00 |
| Gemini | 0.85 | 1.50 | 1.00 | 1.00 | 1.00 | 1.20 |
| Cancer | 1.10 | 1.00 | 1.40 | 1.20 | 0.95 | 1.00 |
| Leo | 0.90 | 1.30 | 1.00 | 0.90 | **1.50** | 1.00 |
| Virgo | 1.50 | 0.95 | 0.90 | 1.40 | 0.85 | 1.00 |
| Libra | 1.30 | 1.20 | 1.40 | 1.00 | 0.95 | 0.90 |
| Scorpio | 1.00 | 0.85 | 0.90 | 1.10 | **1.50** | 1.30 |
| Sagittarius | 0.90 | 1.40 | 1.00 | 1.00 | 1.20 | 1.20 |
| Capricorn | 1.50 | 0.85 | 0.95 | 1.40 | 1.00 | 1.00 |
| Aquarius | 0.85 | 1.20 | 0.90 | 1.10 | 1.00 | **1.50** |
| Pisces | 0.90 | 1.10 | **1.50** | 1.00 | 1.00 | 1.20 |

**Neutral baseline:** 1.00 on all energies (implicit default if sign missing).

**Extremes in table:** boosts at **1.50** (max in set); dampens at **0.85** (min in set). No value should be &lt; 0.85 or &gt; 1.50 without explicit product approval.

---

## 4. Product definitions — six energies (audit must use these)

Auditor must lock definitions with `Energy` enum and any in-app copy. Suggested working definitions (confirm against FAQ / UI):

| Energy | Style meaning (audit working definition) |
|--------|------------------------------------------|
| **Classic** | Timeless, polished, restrained, traditional elegance |
| **Playful** | Light, experimental, witty, novelty-friendly |
| **Romantic** | Soft, sensual, intimate, emotionally expressive |
| **Utility** | Practical, functional, understated, wardrobe-as-tool |
| **Drama** | Bold, statement, high visibility, theatrical presence |
| **Edge** | Avant-garde, subversive, unconventional, sharp |

Every sign×energy cell audit row must state: **boost / neutral / dampen** relative to 1.0, and whether that direction matches the sign’s usual astrological + brand vocabulary.

---

## 5. Engine behaviour (required reading)

### 5.1 Pipeline position

```
Sources (natal, transits, lunar, progressed, current Sun)
    → rawScores[6 energies]
    → × signEnergyMap[natal Sun][each energy]   ← THIS AUDIT (primary)
    → postMultiplierScores
    → normaliseToTwentyOne → VibeBreakdown (/21)
    → Stage 2 (palette, tarot scoring, essence, …)
```

Code references:
- `DailyEnergyEngine.applySignMultipliers`
- `DailyEnergyEngine.generateSnapshotWithTrace` (diagnostics: `signMultiplierApplied`, `postMultiplierScores`)

### 5.2 `stage1_experimental` caveat (critical for downstream audit)

| Path | Sign multipliers applied? |
|------|---------------------------|
| **Production / standard** daily vibe | **Yes** — post-multiplier feeds normalisation |
| **`stage1_experimental` sky vibe** (payload bars) | **No** — `generatePartialVibeProfileWithRaw(..., shouldApplySignMultipliers: false)` |
| **Chart anchor vibe** (inspector comparison) | **Yes** — chart mix uses `shouldApplySignMultipliers: true` |
| **Diagnostics `postMultiplierScores`** on stage1 | May still reflect a parallel full-mix + multiply trace — **do not** treat as sky payload truth |

When auditing downstream UX on **stage1_experimental**, weight sign-map findings toward **chart anchor vs today** and essence/tarot side paths; when auditing **production**, sign map directly moves vibe bars.

### 5.3 Quantization interaction

21-point integer budget + clamp 0–10 per energy means a **×1.5** on Drama often **does not change** the integer bar if raw ranking unchanged. Audit must include **counterfactual simulations** (§6.4), not only static table review.

### 5.4 Downstream consumers of vibe / sign bias

| Consumer | Sensitivity to sign multipliers |
|----------|--------------------------------|
| Vibe bars (6) | High (standard engine) |
| Dominant / secondary energy label | High |
| Tarot selection (`vibeWeight` cosine vs card `energyAffinity`) | Medium |
| Daily palette colour scoring (`roleEnergyAlignment`) | Medium — via dominant energy |
| Style essence top-3 (`resolveEssenceProfile`) | Medium — maps energies → 14 categories |
| Silhouette (stage1) | Low direct — driven by axes; indirect via overall calibration |
| Vibrancy / contrast | Low direct — palette + axes |

Deliverable must include **at least one end-to-end trace** per sign class (fire/earth/air/water) showing multiplier → post-multiplier → final vibe points → palette or essence change (or explicit “no change due to quantization”).

---

## 6. Audit methodology (executor must follow)

### 6.1 Phase A — Inventory & provenance

1. Export current tables to CSV/MD (72 + element + planet rows) by **copying from `DailyFitTypes.swift` / test output** — do not add new export scripts in this ticket.
   - Run existing `AstrologicalSoundness_Tests.testGenerateWeightAuditReport` and paste output into `docs/fixtures/` (read-only use of tests).
2. Search git history / `docs/archive/` for original `getSunSignEnergyPreference` rationale (file removed; may exist only in archive specs).
3. Document **who authored** each multiplier (legacy generator, rebuild migration, manual tweak) — “unknown” is a valid finding.

### 6.2 Phase B — Per-cell semantic review (72 rows)

For **each** sign × energy, complete a row in the audit spreadsheet:

| Column | Description |
|--------|-------------|
| Sign | Zodiac name |
| Energy | One of six |
| Multiplier | Current float |
| Direction | Boost (&gt;1) / Neutral (=1) / Dampen (&lt;1) |
| Magnitude band | Strong (≥1.4 or ≤0.9) / Mild / Neutral |
| Intended archetype | 1–2 sentence: why this sign should lean this energy |
| Astrological basis | Traditional rulerships, element, modality, or “brand archetype only” |
| Brand/product fit | Matches Cosmic Fit voice? |
| Conflicts with §2.2 elementBoosts? | e.g. double drama on fire signs |
| Verdict | **Keep** / **Adjust meaning** / **Adjust magnitude** / **Remove (→1.0)** |
| Proposed value (if change) | New multiplier + justification |
| Evidence | Link test, inspector screenshot, or literature note |

**Leo example (template):**

| Field | Example content |
|-------|-----------------|
| Multiplier | Drama 1.50, Utility 0.90 |
| Intended archetype | Leo as performative, visible, generous — drama high, utility low |
| Question to answer | Is 1.50 **too strong** vs 1.40 Aries drama? Is 0.90 utility **too harsh** for daily wearability? |
| Downstream | Run Leo natal preset 14 days — do drama bars stick at 10 while utility floor at 0? |

### 6.3 Phase C — Cross-sign coherence rules

Verify or challenge these **system-level** rules (existing tests only cover 4):

| Rule ID | Rule | Current test? |
|---------|------|----------------|
| R1 | All 12 signs define all 6 energies | `testAllSignsHaveMultipliers` |
| R2 | Multipliers ∈ (0, 3) sanity band | `testAllSignsHaveMultipliers` |
| R3 | Leo drama ≥ Aries drama | `testSignEnergyCoherence` |
| R4 | Taurus classic ≥ 1.3 | `testSignEnergyCoherence` |
| R5 | Aquarius edge ≥ 1.3 | `testSignEnergyCoherence` |
| R6 | Pisces romantic ≥ 1.3 | `testSignEnergyCoherence` |
| R7 | **Each sign has ≥1 boost (≥1.1) and ≤1 strong dampen (≤0.95)?** | Manual |
| R8 | **No sign boosts same energy &gt;1.4 on more than 2 energies** (avoid “everything sign”) | Manual |
| R9 | **Fire signs:** drama or playful highest; not utility-dominant | Manual |
| R10 | **Earth signs:** classic or utility among highest | Manual |
| R11 | **Water signs:** romantic or drama among highest | Manual |
| R12 | **Air signs:** playful or edge among highest | Manual |
| R13 | **Opposite signs** (axis pairs) are not identical maps | Manual |
| R14 | **Magnitude symmetry:** max boost 1.5 ↔ min dampen 0.85 — intentional asymmetry? | Manual |

Add failing rules as **action items**, not silent fixes.

### 6.4 Phase D — Numeric magnitude audit

For each non-1.0 cell, analyse **sensitivity**:

1. **Pure multiplier effect:** Given fixed raw vector `R = [1,1,1,1,1,1]`, compute post-mult and normalised /21 points.  
2. **Realistic raw vectors:** Use inspector `rawEnergyScores` from 3 presets × 14 days (Briar, Ash, + one earth-heavy profile).  
3. **Marginal flip test:** Increase multiplier from 1.4 → 1.5 — does integer vibe bar for that energy change on any day?  
4. **Sun-sign swap counterfactual:** Same chart, swap only Sun sign in test harness (if feasible) or compare presets differing only by Sun.

Deliverable table: **“% of days where multiplier change would flip dominant energy”** per sign class.

### 6.5 Phase E — Downstream output audit

Using inspector (`./run-inspector.sh`, port 7777):

1. **Presets:** At least 3 from `inspector` preset catalog covering:
   - Fire Sun (e.g. Leo)
   - Earth Sun (e.g. Capricorn/Taurus)
   - Water Sun (e.g. Pisces/Cancer)
2. **Engines:** `production` (or default) **and** `stage1_experimental` (document divergent behaviour).
3. **Horizon:** 14 consecutive UTC dates.
4. **Capture per day:** `rawEnergyScores`, `postMultiplierScores`, `signMultiplierApplied`, final vibe bars, dominant energy, top-3 essence, 3 palette names.
5. **Compare (no code changes):** Estimate sign-layer effect using one or more of:
   - **Analytic:** multiply recorded `rawEnergyScores` by `1 / signMultiplier` or by `1.0` in a spreadsheet to reconstruct “neutral Sun” post-mult, then note whether integer vibe bars would change (§6.4).
   - **Engine contrast:** same preset/date on **production** (multipliers on) vs **`stage1_experimental`** sky vibe (multipliers off daily path) — document what differs and attribute only where evidence supports it.
   - **Do not** add a repo branch with `SignEnergyMap` all-1.0; if that experiment is essential, list it as a **P0 follow-up implementation** item in D5, not work done in this audit.

**Acceptance:** Report must state whether Leo drama 1.5 **materially** changes palette/essence vs a neutral-multiplier baseline, or only shows in post-multiplier floats — using read-only methods above.

### 6.6 Phase F — Stacking review (elementBoosts × sign map)

Build matrix: for natal Sun sign S, list energies that get:

- Boost from `signEnergyMap[S]`
- Additional boost when Sun (or stellium) sits in same element via `elementBoosts`

Flag **over-bias** (e.g. Scorpio: Water + drama 1.5 + edge 1.3 + water drama +0.05 on every water planet).

Recommend: unify into one layer OR document intentional double weighting.

---

## 7. Deliverables

| # | Artifact | Format |
|---|----------|--------|
| D1 | **Audit spreadsheet** — 72 primary rows + verdict columns | CSV or MD table in `docs/fixtures/` |
| D2 | **Executive summary** (≤2 pages) — keep / change / defer | MD section at top of report file |
| D3 | **Cross-sign rule matrix** — pass/fail per R1–R14 | MD table |
| D4 | **Downstream impact report** — 3 presets × 14 days, with/without multipliers | MD + optional `docs/fixtures/sign_audit_downstream_*.txt` |
| D5 | **Recommended changes** — prioritized P0/P1/P2 | MD list with exact new floats |
| D6 | **Test gap list** — rules not covered by `AstrologicalSoundness_Tests` (describe only; do not add tests in this ticket) | MD |
| D7 | **Inspector evidence** — 3+ screenshots or exported JSON snippets showing post-multiplier step | PNG or JSON in `docs/fixtures/` |

**Primary output file (suggested):**  
`docs/fixtures/daily_fit_sign_energy_audit_report.md` (executor creates on completion)

---

## 8. Acceptance criteria

Audit is **complete** when:

1. All **72** `SignEnergyMap` cells have a verdict and written rationale (not “seems fine”).  
2. At least **4 spot-check tests** from `AstrologicalSoundness_Tests` are re-run and results cited; gaps expanded to cover all 12 signs if tests are weaker than manual review.  
3. **Downstream** section answers: “If we set all multipliers to 1.0, what changes for real presets over 14 days?” with quantitative diff (dominant energy changes, palette hash changes, essence top-3 changes).  
4. **stage1_experimental** behaviour is explicitly documented so product does not confuse sky vibe with post-multiplier trace.  
5. **Stacking** with `elementBoosts` is explicitly addressed.  
6. Ash can read D2 and approve, reject, or request implementation follow-up without reading Swift.

6. **No files under `Cosmic Fit/` or `inspector/` were modified** as part of completing this audit (report-only deliverables under `docs/fixtures/` are allowed).

**This ticket is complete when the report exists — not when calibration is fixed.** If D5 recommends changes, Ash opens a **separate implementation ticket**; do not fold implementation into the audit PR.

---

## 9. Implementation follow-up (explicitly out of scope — separate ticket only)

If audit recommends changes:

| Area | File | Notes |
|------|------|-------|
| Sign multipliers | `DailyFitTypes.swift` | `DailyFitCalibration.default.signEnergyMap` |
| Engine registry clones | `DailyFitEngineRegistry.swift` | stage1 copies `default.signEnergyMap` today |
| Tests | `Cosmic FitTests/AstrologicalSoundness_Tests.swift` | Replace 4 anecdotes with rule table |
| Docs | `docs/calibration_signoff.md`, `README.md` §4.1 | Source weights drift noted elsewhere |
| Inspector | No change required unless new diagnostics wanted |

Consider product options Ash should decide:

- **A.** Keep sign multipliers on chart anchor only; sky daily vibe never uses them (align prod with stage1).  
- **B.** Reduce magnitudes (e.g. cap boosts at 1.25, dampens at 0.95).  
- **C.** Replace Sun-only with ascendant or stellium-weighted map.  
- **D.** Remove layer entirely (all 1.0) and rely on planets/transits.

---

## 10. Tools & commands

```bash
# Inspector (trace raw → post-multiplier → vibe)
cd inspector && ./run-inspector.sh
# http://127.0.0.1:7777 — click vibe bar → "Sun-sign multipliers" step

# Run existing soundness tests
cd "Cosmic FitTests"  # or xcode test target
# AstrologicalSoundness_Tests: 6C.3, 6C.4, 6C.5

# Optional: generate weight report (extend 6C.5)
```

**Inspector drill keys:** `vibe:{energy}` — shows raw, post-multiplier, per-input attribution.

---

## 11. Existing automated coverage (baseline)

| Test | What it proves | Gap |
|------|----------------|-----|
| `testAllSignsHaveMultipliers` | 12×6 present, 0&lt;m&lt;3 | No semantic correctness |
| `testSignEnergyCoherence` | Leo≥Aries drama; Taurus classic; Aquarius edge; Pisces romantic | 4 assertions only |
| `testGenerateWeightAuditReport` | Prints matrix to test output | Not committed as fixture; no verdict |

Executor should run `testGenerateWeightAuditReport` and commit output under `docs/fixtures/` as audit baseline snapshot.

---

## 12. Open questions for Ash (executor to surface in D2)

1. Should **Sun sign alone** define chart identity, or also **Rising** / **Moon** (both in chart)?  
2. Is **1.50 / 0.85** the approved global max/min, or should spreads be tighter (e.g. 1.2 / 0.95)?  
3. For Daily Fit product intent: should consecutive days reflect **sky** more than **natal sign** (favours stage1 direction)?  
4. Are six energies equally fundamental, or should some signs boost **two** “primary” energies only and leave others strictly at 1.0?  
5. Should audit cite **astrological tradition** only, **fashion semantics** only, or a written **Cosmic Fit style ontology** (if none exists, flag as product debt)?

---

## 13. Quick reference — code symbols

| Symbol | Location |
|--------|----------|
| `SignEnergyMap` | `DailyFitTypes.swift` |
| `DailyFitCalibration.default` | `DailyFitTypes.swift` |
| `applySignMultipliers` | `DailyEnergyEngine.swift` |
| `elementBoosts` | `DailyEnergyEngine.swift` |
| `planetEnergyBase` | `DailyEnergyEngine.swift` |
| `AstrologicalSoundness_Tests` | `Cosmic FitTests/AstrologicalSoundness_Tests.swift` |
| `stage1SkySourceWeights` | `DailyEnergyEngine.swift` (sky path, no sign mult) |

---

**Handoff complete.** Executor starts with §6.1 inventory, fills §6.2 spreadsheet for all 72 cells, then §6.5 downstream before recommending changes in §9.
