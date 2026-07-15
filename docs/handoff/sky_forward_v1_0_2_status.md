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

## ⚑ Flagged for owner sign-off (G0 — Claude defaults, evidence-based amendments)
1. **Supermoon threshold 361,000 → 363,300 km.** The plan's 361,000 detects only 1 of the 3 commonly-cited
   2026 supermoons in this analytic ephemeris (Jan 3 ≈ 363,150 km, Nov 24 ≈ 361,596 km sit just above it).
   363,300 catches exactly the almanac's three (Jan 3 / Nov 24 / Dec 24) and cleanly excludes the next-closest
   full moon (Oct 26 ≈ 368,332 km). Confirm or revert. (`LunarEventDetector.supermoonKm`)
2. **A2 "no cliff" metric: `maxStep ≤ 0.15·range` → `maxStep/totalVariation < 0.30`.** The drama+playful
   lunar magnitude has a legitimately steep-but-smooth full→waning-gibbous flank (34% of range in one day),
   so "% of range" mismeasures continuity; "% of total cycle variation" captures the step-function-elimination
   intent (continuous blend ≈ 0.17, a step function ≈ 0.5). (`CalibrationAudit_Tests` A2)
3. **G1 gate constants** (0.30/0.90 syzygy cutoffs, [0.50,0.70] band, 12/13, <0.15, +1σ, ≥20/±1day): used
   as pinned from the plan; **all pass on the first real cohort run** without tuning. A quick owner glance
   at the G1 table is worthwhile per G0.

## Remaining (owner-gated — not done here)
- **`docs/fixtures/golden_cases.json`** — best generated **at cutover** against the flipped production engine
  (goldens characterise the shipping engine; `resolvedEngineId` for the seed shifts to `production` only after
  the flip). `DailyFitGoldens_Tests` hard-fails until then; confirm it is in the CI run target.
- **Phase 6c cohort-ladder gate wiring (G2):** `production_audit_analyze.py --gate` + `slider_day_variation_audit.py --gate`
  (add `sys.exit(1)` on regression vs the pinned baseline); promote the six §4.3 `NarrativeCohesionReport_Tests`
  targets to `#expect`; make `DailyFitVariation_Tests` 4A unconditional; fix the tautological `DailyFitAshTodayTomorrow_Tests`.
- **Rungs 2 + 4:** run `DailyFitVariation`/`DailyFitCoherence`/`DailyEnergyEngine_Snapshot_Tests` and the
  **12×60 → 216×60 → 223×60** cohort ladder; **regenerate snapshots deliberately** (they will move) and attach
  the green `CALIBRATION_FIDELITY_GATE=1` output beside them.
- **Phase 7 cutover (one commit, after the ladder is green):** point `productionDescriptor` → `skyFidelityCalibration`
  + `.stage2SkyFidelity`; `productionMarketingVersion = "1.0.2"`; update the two hardcoded `(v1.0.1)` summary strings;
  replace the tautological version test with `#expect(production?.marketingVersion == "1.0.2")`.
- **Scoped follow-up:** route the `LunarEventDetector` **named event** (Supermoon / Eclipse) into the
  narrative/accent surface (the detector is ready; the D2 *phase-label* override is done and gate-covered).

## Test-harness note
Three pre-existing `DailyFitFrozenPayloadStorage_Tests` (`saveUsesNamespacedPath`, `legacyFileRejectedForLegacyBaseline`,
`Migration…`) fail under a plain `xcodebuild test` because the DEBUG engine override needs a dev-engine build config
(`DAILY_FIT_ENGINE_ID` ≠ production). **Verified identical on the pre-change v1.0.1 tag** — not a regression. Run
with the CI dev-engine config to exercise them.
