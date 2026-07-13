# SG-4 Gate: Swift Validation Layer, Composed-Output Contract, 576 Cutover Readiness

STATUS: APPROVED (2026-07-13, Ash) — cutover live as "V2"; v1 retained for rollback (see sign-off)

> Gate file per the master plan's "Human gate protocol". The shipped v1 cache
> (`data/style_guide/blueprint_narrative_cache.json`) must not be replaced
> until a human edits the sign-off block below to `APPROVED`.
> `CHANGES REQUESTED` reopens SG-4.
>
> Review pack: `docs/style_guide/sg4/review_pack/` (report + 11 renders).
> Prior gates: SG-3 APPROVED (`SG-3_GATE.md`).

---

## 1. Deliverables (handoff §2) — status

| # | Deliverable | Status |
|---|---|---|
| 1 | 576-cluster narrative cache via gated pipeline | **DONE** (SG-3 gate + handoff §3; post-run fixes §3 below) |
| 2 | Swift `StyleGuideCoherenceValidator` loading `style_guide_rules.json` + Python↔Swift parity test | **DONE** — `Cosmic Fit/InterpretationEngine/StyleGuideCoherenceValidator.swift`; 126-case parity corpus (`sg4_parity_fixture.json`) passes under xcodebuild (`SG4ValidatorParityTests`) |
| 3 | Phase 4a: prose == ColourEngineV4 == profile temperature | **DONE with pinned finding** — three-way check implemented (`SG4TemperatureCoherenceTests`); Slate agrees on all three sides; 8/15 synthetic goldens show a V4↔profile disagreement, pinned + gate item §4.2 |
| 4 | Phase 4b: element-contract checks on composed `CosmicBlueprint` after overlay + placeholder render | **DONE** — `SG4ComposedContractTests` (hygiene, formula fixed positions incl. Code first-Lean-Into, per-section floors, metal-strategy manifestation, omit categories, restraint principle) |
| 5 | Golden regression vs 16 ideals, Slate excluded from scoring | **DONE** — `SG4GoldenRegressionTests` (identity, lanes, formula-slot propagation) passes for the 15 non-reference charts; Slate hygiene-checked, not scored |
| 6 | Human gate → replace shipped v1 cache | **THIS DOCUMENT** — §4.1 regen done; cutover blocked on sign-off only |
| 7 | `codeAiFramingBackCompat` under xcodebuild | **DONE** — full `Cosmic FitTests` suite executed on iPhone 16 (iOS 18.4) simulator; see §5 |
| 8 | Follow-ups (fibre lexicon, trap-library expansion, blind-spot promotion) | Blind spots **promoted** (§2); `texture_bad` fibre lexicon + trap-library expansion remain follow-ups (§6) |

## 2. Gate/validator hardening shipped in this cycle

- **SG-3 blind spots promoted into `style_guide_rules.json` + both validators
  + audit** (handoff §5): extended American-spelling list (`rigor`,
  `artifact(s)`, `mold(s)`, `pants`, `curb(s)`, `-ize` verbs; allowed:
  `curb chain`, `track pants`), contraction-insensitive + pattern-based
  stamped-phrase check ("Weight and X do not" now blocks).
- **New write-gate error** `excluded_finish_unresolvable` (§4.1) and new
  audit categories `L_archetype_attribution`, `L_temp_contradiction`,
  `B_excluded_finish_unresolvable`, `E_accessory_principle_unmatched`,
  `G_stamped_phrase`.
- The Swift validator loads the identical rules file (Resources symlink);
  structural constants (placeholder vocabulary, section groups) are
  parity-asserted against the Python gate.

## 3. Content changes to the SG-4 artifact this cycle (no regeneration)

Every fix re-gated; full detail + counts in
`docs/style_guide/sg4/review_pack/sg4_report.md` §2:

1. 2 prose fixes (`finalising`; "one or two strong, functional items").
2. 1,728 archetype-codename attributions stripped from user-facing `tests`
   arrays (the "(Wren)" leak — found by the new composed-output checks;
   fixed in `test_trap_library.json` too).
3. 540 lane-contradicting trap fixes repaired (warm-metal directives on
   coolDominant charts; Slate's camel/wine/cognac fix stamped onto cool
   charts; rebuilt per chart from its own ranked colour table; library
   templates made colour-neutral).
4. 20 banned-tic strings reworded in `astrological_style_dataset.json`
   (deterministic Code/overlay text — user-facing, pre-SG legacy). NOTE: the
   dataset is bundled via the Resources symlink, so these rewrites ship with
   the next app build **independently of the cache cutover** (hygiene-only,
   meaning preserved; diff in git).

Composer/renderer (Swift, engine-side; details report §3): composed-output
colour-slot dedup + fill from the user's own palette; token-family-aware
graceful fallback (policy: profile-derivable slots never fall back; per-user
data-depth slots — e.g. a 2nd structural metal the chart genuinely does not
resolve — may use the designed "a complementary metal" wording); Code
contract completion (formula first-Lean-Into, cost-per-wear,
five-to-ten-years) **active only for v2 cache clusters** so shipped v1
behaviour is unchanged until cutover; `PaletteLibrary` accent-label hex guard
(a chart-derived accent slot carried a raw hex as its display name — visible
today as a swatch label like "#8a4484" — now labelled with the nearest
wardrobe colour token; raw-hex hygiene check added to the composed tests).

## 4. Open items the reviewer must rule on

### 4.1 RESOLVED (2026-07-09) — 169 `hardware_metals` sections regenerated

169 sections referenced `{excluded_finish}` on profiles that resolve no
excluded finish (mixedFree / non-muted dualRegister — ~29% of clusters), so
composed prose rendered "a complementary finish" filler mid-sentence. Never
live (the shipped v1 cache predates the placeholder).

**Repair (owner-approved spend, Ash, 2026-07-09):** the blocking write-gate
error `excluded_finish_unresolvable` plus a profile-aware prompt note were
added first; a resume-mode run then re-gated the full cache, dropped exactly
the 169 target sections (dry-run verified against
`docs/style_guide/sg4/excluded_finish_regen_list.json`), and regenerated
them: **169/169 applied, 166 first-pass + 3 pass-after-retry, 0 quarantined,
342 API calls, ~2.0h** (`gemini-3.1-pro-preview`, model id on every run-log
entry). Pre-regen cache preserved at
`data/content_backups/blueprint_narrative_cache_sg4_pre_excluded_finish_regen_2026-07-09.json`.

Post-regen verification: `B_excluded_finish_unresolvable` **0**, 576/576
complete, no `{excluded_finish}` left in any regenerated section; the
composed-hygiene test pin was removed and the strict SG-4 suite re-run.
Residual shifts from the resume's holistic pass (it may revise sibling
sections of a regenerated cluster, each revision re-gated):
`B_groupB_no_placeholder` 2→3 (tip sections, exempt),
`E_accessory_principle_unmatched` 1→3 (all three verified by eye — the
principle is present in fresh words the audit pattern misses, e.g. "Limit
yourself to one or two extras per look"), and the boldExpression pass-over
register stamp dropped below the reporting threshold (an improvement).

### 4.2 ColourEngineV4 vs profile temperature — 8/15 synthetic goldens disagree

ember/blaze/cinder (profile warm → V4 neutral), breeze/loom (cool → neutral),
ripple (warm → cool), wren (cool → warm), flint (neutral → warm). Slate (the
only real chart) agrees on all three sides. The 2e Layer A floor is
deliberately deep-only; this is the first time the V4 side of the golden set
has been executed. Deviations are pinned
(`SG4TemperatureCoherenceTests.pinnedV4TemperatureDeviations`) so drift fails
CI. **Decision needed:** accept as known engine scope (prose describes the
resolved swatches via placeholders, so per-user text/swatch colour names stay
consistent; only the temperature *word* in cluster prose can disagree), or
schedule engine work to extend the Venus floor beyond deep families
(calibration-anchor risk; out of SG-4 scope to decide unilaterally).

### 4.3 Residuals to re-confirm (SG-3-accepted classes + new informational)

Report §5–§6: restraint-principle scaffolding stamps (contract-mandated),
ranked-table use-case repeats, boldExpression pass-over phrasing, 25
`H_too_long` style_core (under hard cap), 1 principle-pattern miss (verified
by eye), 2 tip sections without placeholders (exempt), 2 candidate tics for
the §7c watch list ("between your thumb and index finger" ×112, "leave it on
the rail you" ×103).

## 5. Verification (all pass as of 2026-07-09, this machine)

```bash
# SG-0 golden rubric (16/16), SG-1 parity (16/16), SG-3 gate self-test
.venv/bin/python tools/check_golden_guides.py
.venv/bin/python tools/sg_profile.py --parity
.venv/bin/python tools/sg_validation.py

# SG-4 deep audit — expect exactly the §4.3 residuals + 169 × §4.1
.venv/bin/python tools/sg3_audit.py --cache data/style_guide/blueprint_narrative_cache_sg4.json

# completeness 576/576 + model proof (handoff §6 commands unchanged)

# parity fixture freshness (regenerate + expect no diff)
.venv/bin/python tools/sg4_parity_fixture.py

# Swift: full suite (includes SG4* suites and SG2DataContractTests/codeAiFramingBackCompat)
xcodebuild test -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4,arch=arm64'
```

Swift suite results (final, 2026-07-09 post-regen, strict — the only pin left
is the §4.2 temperature set): SG4ValidatorParityTests 3/3,
SG4TemperatureCoherenceTests 1/1, SG4ComposedContractTests 3/3,
SG4GoldenRegressionTests 1/1, SG1GoldenProfileTests 4/4, SG2 suites all green
in the full run (incl. `codeAiFramingBackCompat`). Exit 0.

**Pre-existing failure attribution.** This machine had never run the Swift
suite (SG-3 gate §6 caveat). A clean-HEAD baseline run (worktree, no SG-4
changes) reproduces every non-SG-4 failure seen in the full run —
`DailyFitEngineConfig` (4), `DailyFitFrozenPayloadStorage` (3),
`DailyFitGoldens` (4), `NarrativeCoherence_Briar` (2),
`NarrativePaletteUnification` (3), `NarrativeTarotUnification` (1),
`PaletteGridGoldenSnapshotTests` (2), `TarotStyleEdit
testSelectionDeterministic` (1), plus two flaky-at-baseline tests
(`PersonalScaleEnvelope buildPlanContrast…`, `PromoUserIsolation
compAccessStorageRoundTrip`) — i.e. none are SG-4 regressions; they predate
this work and are out of SG scope. Two stale test expectations were updated
to current contract behaviour (`buildContextMapping` expected the pre-SG-2
"silver tones" garble; two fallback-wording asserts follow the SG-4
token-family fallback). `V4CalibrationOptimizer_Tests` was excluded from the
verification run after running >45 min without completing (pre-existing,
unrelated to SG); run it separately if wanted.

## 6. Outstanding after sign-off (non-blocking)

- `texture_bad` fibre lexicon (SG-3 §9a carry-over).
- Test/trap library expansion for single-entry hardware pools.
- §7c watch list: re-harvest after any regeneration; the two candidate tics
  in §4.3.
- Commit everything on `refactor/style-guide` (owner's call on multi-MB
  logs/caches, per SG-3 gate §6 precedent).

## 7. Cutover procedure (only after APPROVED + §4.1 regen)

```bash
cp data/style_guide/blueprint_narrative_cache.json \
   data/content_backups/blueprint_narrative_cache_v1_pre_sg4.json
cp data/style_guide/blueprint_narrative_cache_sg4.json \
   data/style_guide/blueprint_narrative_cache.json
# Resources symlink follows automatically; then re-run the full Swift suite.
```

---

## 8. Sign-off

| Field | Value |
|---|---|
| Reviewer name | Ash |
| Date | 2026-07-13 |
| Verdict (`APPROVED` / `CHANGES REQUESTED`) | **APPROVED** |
| Notes | Approved after on-device (own account) + Inspector testing. Cutover executed; SG-4 is now the live content, referred to henceforth as **"V2"**. **Stipulation: v1 must NOT be destroyed** — retained at `data/content_backups/blueprint_narrative_cache_v1_pre_sg4.json` as a permanent last-resort rollback (revert = copy it over `data/style_guide/blueprint_narrative_cache.json`). Two post-cutover content/render fixes applied this session and covered by this approval: (1) renderer guard hides bare `the … test` bullet entries (`StyleGuideDetailViewController.isBareNamedTest`, see `TODO_tests_backfill.md`); (2) 94 Title-Cased inline `the … Test/Check` names lowercased in the canonical cache to match golden register. Forward workflow: paragraph amendments handled retroactively via the partner's live paragraph-editor tool (download updated JSON per build) — release is not gated on per-paragraph review. §4.2 pinned temperature deviation remains an accepted non-blocker. |
