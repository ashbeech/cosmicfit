# Sky Forward v1.0.2 — implementation status (2026-07-15)

> Branch `SFv102`. Engine work implemented + validated; **production not yet flipped** (the cutover is
> gated on the full cohort ladder, which is expensive to run — see "Remaining"). All changes are on the
> working tree, not committed. Triple rollback in place: git tag `sky-forward-v1.0.1` +
> `data/content_backups/2026-07-15_pre-sky-forward-v1.0.2/` + the in-code `sky_forward_v1_0_1` preset.

## Implemented + validated

| Phase | What | Evidence (all run + green) |
|---|---|---|
| 0 | Backup dir + `manifest.json` + `LATEST.txt`; annotated tag `sky-forward-v1.0.1`; B3 cache-key trace → **Remedy A** ([phase0 trace](sky_forward_v1_0_2_phase0_cache_trace.md)) | restore dry-run round-trips |
| 1 | `.stage2SkyFidelity` mode + `usesSkyForwardPipeline` helper; broadened ~25 structure gates; fixed 4 exhaustive switches; `sky_forward_v1_0_1` (rollback) + `sky_forward_v1_0_2` descriptors | `DailyFitEngineRegistry_Tests` 21/21 |
| 2 | `skyVibeWeights` + `lunarSignificanceCoeff` promoted into the fingerprinted calibration; canonical string serialises them **only when non-nil** | Pre-v1.0.2 fingerprints **byte-identical to the v1.0.1 tag** (proven by rebuild) |
| 3+4 | Continuous raised-cosine lunar blend (peaks at 180°), significance amplification `1+k·syzygyProx`, transit normalisation (shared `dominantTransits` top-5, speed-damp, minor discount), jitter 0.40→0.18. New accumulators; v1.0.1 path untouched | Effective lunar share **4.6% → 57.8%**; `r(transitCount, share)` **0.94 → −0.07**; transits out-weigh lunar **100% → 1.3%** of days |
| 5 | `LunarEventDetector` (eclipses via moon latitude + node proximity; supermoons via ≥5-term `AstronomicalCalculator.calculateMoonDistance`); D2 phase-label override | `LunarEventDetector_Tests` 5/5: **4/4 eclipses**, **13/13 full moons**, supermoons, ≥5-term depth |
| 6a | Fidelity gates (a)–(d) + A2 converted to **fail-closed** asserts behind `CALIBRATION_FIDELITY_GATE=1` | **All 5 gates GREEN** vs `sky_forward_v1_0_2` |
| 6b | `AstrologicalSoundness_Tests` 6C.2/6C.5 repointed to the lunar-led sky mix; README §4.1 two-mix truth; `calibration_signoff.md` supersession | `AstrologicalSoundness_Tests` + registry 33/33 |
| 7 (B3) | Remedy A: `calibrationFingerprint` stamped on `DailyFitPayload`; namespaced load/purge require fingerprint match (legacy un-namespaced files grandfathered) | B3 proof test green; **rollback drill byte-identical** (0 mismatches / 40 days) |

**Owner non-negotiable (24h variation): satisfied and improved.** Day-over-day vibe L1 delta **1.17 → 3.56**,
now moon-driven rather than transit/jitter noise. Full-moon axis legibility preserved (new 6.40 → full 7.69).

### Run the fidelity gates
```
cd inspector && CALIBRATION_ENGINE_ID=sky_forward_v1_0_2 CALIBRATION_FIDELITY_GATE=1 \
  swift test --filter CalibrationAudit_Tests
```
(a) off-syzygy lunar share ∈ [0.50,0.70] · (b) ≥12/13 full moons labelled · (c) jitter share < 0.15 ·
(d) syzygy mean ≥ off-syzygy +1σ · (A2) ≥20 distinct + no step-function + peak at 180°.

## ✅ Owner sign-off obtained (G0 — 2026-07-15, plan rev 5)
1. **Supermoon threshold 361,000 → 363,300 km — RATIFIED.** Live scan re-derived the evidence: Jan 3 ≈ 363,150 km,
   Nov 24 ≈ 361,596 km, Dec 24 ≈ 357,100 km (almanac's three); next-closest full moon Oct 26 ≈ 368,332 km. At
   361,000 only Dec 24 fires; 363,300 catches all three and excludes Oct 26 by ~5,000 km. (`LunarEventDetector.supermoonKm`)
2. **A2 "no cliff" metric: `maxStep ≤ 0.15·range` → `maxStep/totalVariation < 0.30` — RATIFIED.** Live A2 gate:
   `distinct=40 maxStep=0.185 totalVar=1.089 stepShare=0.170 peakDeg=182.9`. The drama+playful lunar magnitude
   has a legitimately steep-but-smooth full→waning-gibbous flank (34% of range in one day), so "% of range"
   mismeasures continuity; "% of total cycle variation" captures the step-elimination intent (continuous ≈ 0.17,
   step function ≈ 0.5). (`CalibrationAudit_Tests` A2)
3. **G1 gate constants** (0.30/0.90 syzygy cutoffs, [0.50,0.70] band, 12/13, <0.15, +1σ, ≥20/±1day): **ACCEPTED
   as pinned** — all pass on the first real cohort run without tuning (live off-syzygy lunar share 0.578; gate-d
   syzygy mean 0.622 ≥ threshold 0.553). No amendment.

## Phase 6c — DONE this session (2026-07-15, validated)
- **Gate wiring complete + validated:** `production_audit_analyze.py --gate` + `slider_day_variation_audit.py --gate`
  (pinned floors + baseline-regression `sys.exit(1)`; baselines committed at `docs/fixtures/*_baseline_v1_0_1.json`;
  fail-closed logic unit-verified). Six §4.3 `NarrativeCohesionReport_Tests` targets promoted to `#expect` (via new
  `SkyForwardV2Support.gateEngineId` hook → runs against v1.0.2). `DailyFitVariation_Tests` 4A made unconditional +
  repointed to v1.0.2 (**GREEN**). `DailyFitAshTodayTomorrow_Tests` tautology fixed (**GREEN**). `DailyFitCoherence_Tests` **GREEN**.
- **Three owner-ratified §4.3 target corrections (plan rev 6/7), measured against real v1.0.2:**
  - **[7] distinct-#1 ≥ 6 → ≥ 4.5.** ≥6 is the metric's theoretical max (6 accent essences; needs all-6-per-user). v1.0.2 = 4.82, v1.0.1 = 4.6.
  - **[9] slider range ≥ 0.5/user → mean ≥ 0.50 AND weakest ≥ 0.35.** Literal ≥0.5 unreachable via v1.0.2-only calibration
    (displayPosition halfSpans are hardcoded `Stage1ScaleSensitivity` constants, shared w/ v1.0.1; `silhouetteAxisScale`/
    `contrastCoeff` proven inert; jitter recovers it but fails gate (c) at 19%). v1.0.2: mean 0.61 / weakest 0.40.
  - **[6]/[8]/[11]/[12] pass at plan thresholds** (flip 0.54, coverage 13.9, coherence 1.0, salience 0.87).

## Remaining before cutover
- **Rung 2:** `DailyEnergyEngine_Snapshot_Tests` are **property-based** (not golden fixtures) → cutover-invariant, no regen
  needed (verify with a run). `DailyFitCoherence` **GREEN**.
- **Rung 4 cohort ladder (EXPENSIVE — needs the inspector HTTP server on :7777; ~overnight):**
  - 216×60: `cd inspector && ./run-inspector.sh &` then `python3 tools/slider_day_variation_audit.py --start 2026-04-23 --days 60 --subset 216 --parallel 6 --gate` (engine defaults to `sky_forward_v1_0_2`).
  - 223×60: `python3 tools/production_audit_harness.py --engine sky_forward_v1_0_2 --out docs/fixtures/production_audit_v2` → `python3 tools/production_audit_analyze.py --in docs/fixtures/production_audit_v2 --gate`.
  - A red `--gate` → keep developing per plan §7 nudge order (each knob → one gate), not stop.
- **`docs/fixtures/golden_cases.json`** — generate **at cutover** against the flipped production engine (`resolvedEngineId`
  shifts to `production` only after the flip). `DailyFitGoldens_Tests` hard-fails until then; confirm it's in the CI run target.
- **Phase 7 cutover (ONE commit, ONLY after Rungs 1–6 all green — NOT done this session, Rung 4 pending):**
  `DailyFitEngineRegistry.swift` — line ~68 `productionMarketingVersion = "1.0.1"` → `"1.0.2"`; `productionDescriptor`
  (lines ~176–182) `calibration: stage1ExperimentalCalibration` → `skyFidelityCalibration`, `fingerprint(for: skyFidelityCalibration)`,
  `mode: .stage1Experimental` → `.stage2SkyFidelity`, summary "(v1.0.1)" → "(v1.0.2)". `DailyFitEngineRegistry_Tests.swift:36`
  tautology → `#expect(production?.marketingVersion == "1.0.2")` + production mode/fingerprint asserts. (Repo policy: NO AI Co-Authored-By in the commit.)
- **Scoped follow-up — ✅ DONE (2026-07-16):** the `LunarEventDetector` **named event** (Supermoon / Eclipse)
  now routes into the narrative/accent surface: `LunarContext.namedEvent` (snapshot → payload, v1.0.2 path
  only, nil omitted from JSON) + `injectNamedEventDriver` prepends a Moon-led salience driver on special-event
  days (accent/intensity/justification all read it). Fingerprint-neutral. Covered by
  `DailyFitNamedLunarEvent_Tests` (all 7 pinned-almanac 2026 event days + ordinary-day/rollback negatives).
  See DEV_HANDOFF §6h for the fixture-drift note (2026-05-31 micromoon sits in the Rung 4 slider window).

## Test-harness note
Three pre-existing `DailyFitFrozenPayloadStorage_Tests` (`saveUsesNamespacedPath`, `legacyFileRejectedForLegacyBaseline`,
`Migration…`) fail under a plain `xcodebuild test` because the DEBUG engine override needs a dev-engine build config
(`DAILY_FIT_ENGINE_ID` ≠ production). **Verified identical on the pre-change v1.0.1 tag** — not a regression. Run
with the CI dev-engine config to exercise them.
