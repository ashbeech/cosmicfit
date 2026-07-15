# Kickoff — Implement Sky Forward v1.0.2 (Daily Fit calibration refactor)

> **You are the implementing dev.** This prompt is self-contained. Read it fully, then read the plan it points to, before writing any code.
> **Your mandate:** take Sky Forward from **v1.0.1 → v1.0.2**, fixing the audited calibration defects, and land it **production-ready** — fully tested, every gate green — so it becomes the selected engine visible in the **Inspector** and the **next device build**, with a clean rollback to v1.0.1 preserved.

---

## 0. Read these first (in order)
1. **The plan (your spec, source of truth):** [`docs/handoff/sky_forward_v1_0_2_plan.md`](sky_forward_v1_0_2_plan.md) — 7 phases, fixed weights, gates, risks, verification. **Follow it exactly.** It has already survived one review round (rev 2); the blockers B1–B3 and decisions D1–D2 in its revision log are settled — do not re-open them without owner sign-off.
2. **The audit (the "why"):** [`docs/daily_fit_calibration_audit_2026-07-11.md`](../daily_fit_calibration_audit_2026-07-11.md) — findings F1–F7, experiments A1–A5, recommendations.
3. **Repo orientation:** the Daily Fit engine lives in `Cosmic Fit/InterpretationEngine/` (single source of truth; the `inspector/` SwiftPM package **symlinks** the same engine, so there is one engine, not a fork). Engine selection is in `Cosmic Fit/Core/Config/DailyFitEngineConfig.swift`.

If anything in the plan is ambiguous or reality has drifted from its reference map (line numbers, symbols), **stop and reconcile against the live code** — the plan's file:line anchors were accurate at 2026-07-13 but treat them as pointers, not gospel.

## 1. The outcome you are accountable for
A single reviewable **cutover commit** that:
- Flips production to **Sky Forward v1.0.2** (`stage2SkyFidelity` mode + `skyFidelityCalibration`), version stamp `"1.0.2"`.
- Retains **v1.0.1** fully runnable (in-code preset + git tag + file backup) — a true rollback, not just git history.
- Passes the **entire validation ladder and all fidelity gates** (below). Nothing merges until they are green.
- Is **actually visible** — the Inspector shows the new fingerprint/mode, and a device build shows the changed daily read (the cache-invalidation gate, B3, is what guarantees this).

## 2. Non-negotiable ground rules
- **Phase 0 first, always.** Before editing a single engine file: create the git tag `sky-forward-v1.0.1`, and snapshot every file you will touch into `data/content_backups/2026-07-1X_pre-sky-forward-v1.0.2/` with a `manifest.json` (bytes + sha256 + one-line restore command), per the repo's `tools/backup_content_sources.py` convention. Update `LATEST.txt`. **No backup, no edits.**
- **Never mutate the v1.0.1 path.** `stage1ExperimentalCalibration` and the `.stage1Experimental` code branch stay byte-for-byte identical. All new behaviour goes behind the **new** `.stage2SkyFidelity` mode. Add a regression test proving every pre-existing fingerprint is unchanged (Phase 2).
- **Determinism is sacred.** The engine is seeded and reproducible. The new mode, the lunar significance function, and the eclipse/supermoon detector must all be pure functions of (chart, date) — no wall-clock, no RNG outside the existing seeded jitter. Same input → same output, forever.
- **The gates are the acceptance bar, not the seed numbers.** The plan's weights (lunar 0.60 / transits 0.25 / sun 0.15, `k=0.8`, jitter 0.18) are a **ratified starting point**. If a gate fails, follow the plan's **nudge order** (each knob maps to one gate — they don't fight). The *ratio intent* (lunar-led) is owner-fixed; do not re-invert to transit-dominant.
- **Build both targets clean:** the app (`xcodebuild`) and the inspector package (`swift build` / `swift test`). A change that breaks the inspector target is not done.

## 3. Build order (phases — detail is in the plan)
Implement in this sequence; each phase should compile and keep existing tests green (except where the plan says a test is intentionally repointed/updated):

1. **Phase 0** — backups + git tag + the B3 cache-key trace (record which cutover remedy applies).
2. **Phase 1** — add `stage2SkyFidelity` mode + `sky_forward_v1_0_1` rollback descriptor + a new experimental `sky_forward_v1_0_2` descriptor. **Do not flip production yet.**
3. **Phase 2** — promote the vibe sky-mix into the fingerprinted calibration (`skyVibeWeights` + `lunarSignificanceCoeff`), nil-fallback for legacy. **Add the byte-identical-fingerprint regression test.**
4. **Phase 3** — continuous cosine-blended lunar vibe + significance amplification (`1 + k·syzygyProximity`). Handle the 315°↔0° wrap. New mode only.
5. **Phase 4** — transit normalisation (shared `dominantTransits` helper: tightest-per-planet → top-5 → speed-damp), minor-aspect discount, jitter 0.40→0.18. **Validate Phases 3+4 together** — Phase 3 has no visible effect until 4 lands; do not chase a "no effect" ghost.
6. **Phase 5** — `LunarEventDetector` (eclipses via moon latitude + node proximity; supermoons via the **required ≥5-term** `calculateMoonDistance` — a *separate* function, not a signature change to `calculateMoonPosition`). **The detector overrides the user-facing phase label near syzygy.** Add the almanac cross-check test (known 2026 eclipse + supermoon dates).
7. **Phase 6** — evidence layer: README §4.1, `calibration_signoff.md`, repoint `AstrologicalSoundness_Tests` to measured effective shares, **generate `docs/fixtures/golden_cases.json`** and **harden `DailyFitGoldens_Tests` to hard-fail on a missing fixture**. Convert A1–A5 into the four fidelity gates behind `CALIBRATION_FIDELITY_GATE=1`.
8. **Phase 7** — cutover (see §5).

> Note: the repo already contains a private leading-term-only `calculateMoonDistance` in `NatalChartCalculator` (mean 384,400 ± 21,000 km, floor ~363,400 km) — this is exactly the model the plan's **B2** flags as unable to detect supermoons (never < 361,000 km). Do **not** reuse it as-is for events; implement the ≥5-term series the plan specifies.

## 4. Test & acceptance ladder — nothing ships until ALL green
Run bottom-up; a red rung blocks the next.

**Rung 1 — Unit / regression (app target):**
```
xcodebuild test -scheme "Cosmic Fit" \
  -only-testing:"Cosmic FitTests/DailyFitEngineRegistry_Tests" \
  -only-testing:"Cosmic FitTests/DailyFitGoldens_Tests" \
  -only-testing:"Cosmic FitTests/AstrologicalSoundness_Tests" \
  CALIBRATION_CI_GATE=1 -parallel-testing-enabled NO
```
- Version = `1.0.2`; `sky_forward_v1_0_1` retains `"1.0.1"` + a **distinct fingerprint**; legacy fingerprints byte-identical (Phase 2 test); goldens now **run** (not silently inert) and pass; soundness tests assert **effective** shares.

**Rung 2 — Variation/coherence + snapshots (app target):**
```
xcodebuild test -scheme "Cosmic Fit" \
  -only-testing:"Cosmic FitTests/DailyFitVariation_Tests" \
  -only-testing:"Cosmic FitTests/DailyFitCoherence_Tests" \
  -only-testing:"Cosmic FitTests/DailyEnergyEngine_Snapshot_Tests" \
  CALIBRATION_CI_GATE=1 -parallel-testing-enabled NO
```
- Freshness gates stay green. **Snapshots will move — regenerate deliberately with diff review, never blindly.**

**Rung 3 — Fidelity gates (inspector target) — the heart of this release:**
```
cd inspector && CALIBRATION_FIDELITY_GATE=1 \
  CALIBRATION_AUDIT_DIR=../docs/fixtures/calibration_audit_2026-07-11 \
  swift test --filter CalibrationAudit_Tests
```
- **(a)** off-syzygy lunar share within ±0.1 of ~0.60 · **(b)** ≥90% of 2026 full moons **labelled** (detector override) · **(c)** jitter share < 15% · **(d)** on-syzygy full/new delta statistically separable · A2 smooth + peaked at 180°.
- Plus the `LunarEventDetector` almanac test (2026 eclipse/supermoon dates within tolerance).

**Rung 4 — Cohort ladder (full, before cutover):**
- **12×60:** `SliderSignalValidation_Tests` + the A1–A5 harness above.
- **216×60:** `python3 tools/synthetic_cohort.py --verify` → `python3 tools/slider_day_variation_audit.py --start 2026-04-23 --days 60 --subset --parallel 6` → `NarrativeCohesionReport_Tests`.
- **223×60:** `python3 tools/production_audit_harness.py --out docs/fixtures/production_audit_v2` → `python3 tools/production_audit_analyze.py --in docs/fixtures/production_audit_v2`. Review the summary — no regressions in slider variation, narrative cohesion, or coverage.

**Rung 5 — Cache-invalidation proof (B3, blocking):** a test that seeds a v1.0.1-cached daily payload for a profile+date, cuts over, and asserts the served output is the **v1.0.2** result, not the stale cache.

**Rung 6 — Rollback drill:** set `DAILY_FIT_ENGINE_ID=sky_forward_v1_0_1` (DEBUG override) and confirm **byte-identical v1.0.1 output**; run the manifest's restore command and confirm it round-trips.

## 5. Cutover — making it live in Inspector + device build
Do this **only after Rungs 1–6 are green.** It is one commit:
1. Point `productionDescriptor` → `skyFidelityCalibration` + `.stage2SkyFidelity`; set `productionMarketingVersion = "1.0.2"`; update the hardcoded `"(v1.0.2)"` in the production `summary` (two spots in `DailyFitEngineRegistry.swift`).
2. Apply the **B3 cache remedy** you identified in Phase 0 (fingerprint-in-key preferred; id-bump fallback) so post-cutover output actually changes.
3. Update `DailyFitEngineRegistry_Tests` expected version + retained-preset assertions.

**How you (and the owner) then see it:**
- **Inspector:** the daily-fit fingerprint and engine display line change to Sky Forward v1.0.2; the new `.stage2SkyFidelity` mode is reported. In DEBUG you can flip between `production` (v1.0.2), `sky_forward_v1_0_1`, and the legacy presets via the runtime override to compare side by side.
- **Device build:** Release pins `productionId`, so the **next build automatically runs v1.0.2** — the Profile screen version stamp reads **"Sky Forward v1.0.2"** (derived from `productionVersionDisplayText`, no UI change needed), and the daily read shows audible moon movement, correctly-labelled full moons, and named eclipse/supermoon days.

## 6. Definition of Done (check every box)
- [ ] Phase 0 backup dir + `manifest.json` + `sky-forward-v1.0.1` git tag exist.
- [ ] v1.0.1 runnable via `sky_forward_v1_0_1` preset; rollback drill passes byte-identical.
- [ ] All 6 test rungs green; snapshots regenerated with reviewed diffs.
- [ ] `golden_cases.json` generated; `DailyFitGoldens_Tests` hard-fails if it's missing.
- [ ] `AstrologicalSoundness_Tests` assert effective shares, not the `.default` vector.
- [ ] Fidelity gates (a)–(d) green on their correct (off/on-syzygy) bases.
- [ ] Eclipse/supermoon detector matches the 2026 almanac; label override works.
- [ ] B3 cache-invalidation proof test green; cutover output verifiably changes.
- [ ] Version bumped to 1.0.2; Inspector fingerprint + Profile stamp reflect it.
- [ ] README §4.1 + `calibration_signoff.md` updated to the two-mix / v1.0.2 truth.
- [ ] Cutover is one clean, reviewable commit; the plan's revision log decisions are all honoured.

## 7. What is explicitly out of scope
- The axis path (F4) — preserved as the reference model, unchanged.
- Void-of-course modelling — deferred.
- `MoonPhaseInterpreter.tokensForDailyVibe` dead code — leave as-is (note for future cleanup).
- Re-inverting the mix to transit-dominant — owner-ratified as lunar-led; do not change without sign-off.

**When in doubt, the plan doc wins; when the plan is silent, preserve v1.0.1 behaviour and ask.**
