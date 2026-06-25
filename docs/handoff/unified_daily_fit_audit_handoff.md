# Unified Daily Fit Full Audit — Handoff

**Date:** 2026-06-25  
**Status:** Phase 0 complete, Phase 1 running, Phase 3 needs debugging  
**Plan file:** `.cursor/plans/unified_daily_fit_audit_ba334d41.plan.md`

---

## Goal

Run a comprehensive test of **all Daily Fit elements together** — 200+ users, 60+ days — on the current Sky Forward engine code (post June 22–24 slider fixes). Produce a single authoritative report that definitively answers whether results are accurate, varied daily, and complete for every user.

---

## What Was Done (Phase 0 — Fix Stale Infrastructure)

All five fixes are **complete and saved** (not yet committed):

### Fix 1: `tools/regenerate_cohesion_report.sh` line 21
- **Was:** `-only-testing:"Cosmic FitTests/NarrativeCohesionReportXCTests/testGenerateCohesionReportFixture"`
- **Now:** `-only-testing:"Cosmic FitTests/NarrativeCohesionReport_Tests/generateCohesionReport"`
- The old XCTest class name didn't exist; the test is a Swift Testing struct.

### Fix 2: `tools/narrative_coherence_harness.py` lines 120–121
- **Was:** `resp.get("payload", {})` and `resp.get("diagnostics", {})`
- **Now:** `(resp.get("dailyFit") or {}).get("payload", {})` and same for diagnostics
- Inspector nests under `resp["dailyFit"]`. Every other harness already uses the correct path.

### Fix 3: `tools/narrative_cohesion_harness.py`
- **Was:** Misleading stub with full docstring/CLI flags but `sys.exit(0)` in `main()`
- **Now:** Docstring says "DEPRECATED", prints redirect to Swift test, exits with code 2

### Fix 4: `tools/production_audit_harness.py` line 33
- **Was:** `ENGINE = "stage1_experimental"`
- **Now:** `ENGINE = "production"`
- Matches the shipped app engine ID. Same math, but tarot/variant recency keys are namespaced by engine ID, so "production" gives a true simulation of what users experience.

### Fix 5: `tools/production_audit_analyze.py` — slider day-variation metrics
- **Added:** `max_unchanged_streak()` helper function
- **Added:** `slider_variation_for_user()` function computing per-user, per-slider:
  - Day-over-day UI delta (mean, median)
  - % unchanged, % imperceptible (<0.02), % meaningful (>=0.05) day-pairs
  - Max unchanged streak, distinct positions count
- **Added:** In `main()`: collects raw day-pair deltas during file reading, computes aggregate slider variation stats and 7-bin delta histograms
- **Added:** `"sliderVariation"` key in `summary.json` and new `SLIDER VARIATION` section in `summary.txt`
- Constants: `IMPERCEPTIBLE_DELTA = 0.02`, `MEANINGFUL_DELTA = 0.05`

**Files modified (all in `tools/`):**
```
M tools/regenerate_cohesion_report.sh
M tools/narrative_coherence_harness.py
M tools/narrative_cohesion_harness.py
M tools/production_audit_harness.py
M tools/production_audit_analyze.py
```

---

## What Is Running Now

### Phase 1: Production Audit Harness (HTTP, 223 users × 60 days)

**Command:**
```bash
python3 tools/production_audit_harness.py \
  --days 60 --start 2026-04-26 --synthetic-stride 1 \
  --parallel 5 --out docs/fixtures/production_audit_v2
```

**Status as of 10:35 AM:** 30/223 users complete (~2,230s elapsed). Rate: ~5 users per 340s batch. Estimated completion: ~12:30–1:00 PM (roughly 2 more hours from 10:35 AM).

**Output directory:** `docs/fixtures/production_audit_v2/`
- `raw/<user_id>.jsonl` — one trimmed JSON record per user-day
- `blueprints/<user_id>.json` — full Style Guide blueprint (day 1)
- `manifest.json` — run metadata

**Inspector:** Running on port 7777, built today (2026-06-25T08:30:27Z). **Do not kill the inspector while this is running.**

**When complete:** The harness prints `Complete in <N>s -> docs/fixtures/production_audit_v2`.

### Phase 3: Swift Narrative Cohesion Test — NEEDS DEBUGGING

**Command (re-running with failure capture):**
```bash
xcodebuild test \
  -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,id=148BC509-DCD4-4EED-AFC7-00495D1E0B06' \
  -only-testing:"Cosmic FitTests/NarrativeCohesionReport_Tests" \
  -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 1800
```

**Problem:** The test runs for ~31 minutes (216 users × 60 days) then **fails**. The first attempt used `tail -40` which cut off the failure message. A second run is in progress capturing `grep -E "error:|fail|FAIL|expect|Expect|violation|assert|Assert"` to get the actual assertion.

**Simulator:** "Test iPhone" (id: `148BC509-DCD4-4EED-AFC7-00495D1E0B06`, iOS 26.5). Note: "iPhone 16 Pro" does **not** exist on iOS 26.5; only on 18.4.

**Test file:** `Cosmic FitTests/NarrativeCohesionReport_Tests.swift`  
**Test struct:** `NarrativeCohesionReport_Tests` (Swift Testing, not XCTest)  
**Method:** `generateCohesionReport()`

**Hard gate assertions (lines 483–488):**
```swift
#expect(aggOppositions == 0, "Opposition violations must be zero")
#expect(crossSurfaceRate < 0.001, "Cross-surface violation rate must be < 0.1%")
#expect(meanCoherence >= 0.85, "Coherence score must be ≥ 0.85")
```

**Previous passing run:** 2026-06-14 (predates June 22–24 slider fixes). Failure could be caused by engine changes since then affecting one of these gates.

**Failure details (2026-06-25):** The test runs for ~31 minutes then fails (exit code 65). Fixture files are NOT updated (still June 14), which means the test is throwing/crashing BEFORE reaching the file-write code at line 397, not just failing an assertion at line 483. This suggests a runtime error during the 216×60 computation loop (lines 197–299), possibly a force unwrap, array bounds, or API change since June 14.

**Debugging approach:** Run the test without output filtering to capture the actual error:
```bash
xcodebuild test \
  -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,id=148BC509-DCD4-4EED-AFC7-00495D1E0B06' \
  -only-testing:"Cosmic FitTests/NarrativeCohesionReport_Tests" \
  -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 1800 \
  2>&1 | tee /tmp/cohesion_test_full.log | tail -100
```
Then search `/tmp/cohesion_test_full.log` for the actual Swift error. Alternatively, check `#filePath` resolution — when running via xcodebuild, `#filePath` should point to the original source, but verify that `fixturesDir` at line 398 resolves correctly.

**Note on `-only-testing` and Swift Testing:** The filter `-only-testing:"Cosmic FitTests/NarrativeCohesionReport_Tests"` does work (confirmed: the test ran for 31 minutes doing real work). An earlier attempt with `/generateCohesionReport` appended ran 0 tests — use suite-level filtering only.

---

## What Remains

### When Production Audit Completes

1. **Run the analyzer:**
   ```bash
   python3 tools/production_audit_analyze.py --in docs/fixtures/production_audit_v2
   ```
   This produces `summary.json` and `summary.txt` with all metrics including the new slider variation section.

2. **Review `summary.txt`** — single authoritative digest of all Daily Fit elements.

### When Swift Test Completes (or Fails)

1. **Read the failure output** to determine which gate failed.
2. **Check `docs/fixtures/narrative_cohesion_report.txt`** — it's written before assertions, so the data is there.
3. If the failure is a real regression (e.g., opposition violations > 0), that's a genuine finding from the audit.
4. If the failure is a threshold marginal miss (e.g., coherence 0.849 vs 0.85), note it in the results.

### Phase 4: Verification

1. **Slider gates:** The production audit summary now includes slider variation metrics directly. Run `python3 tools/verify_slider_gates.py` on the slider variation data if a compatible format is needed.
2. **Cross-reference:** Compare the narrative_cohesion_report (Swift, plan-level) with production_audit_v2 summary (HTTP, payload-level) — coherence and essence metrics should broadly agree.

---

## Key Architecture Notes

- **Three test harnesses** exist, each measuring different aspects:
  - `tools/production_audit_harness.py` + `production_audit_analyze.py` — HTTP via inspector, broadest coverage (tarot, essences, sliders, palette, narrative, cohesion diagnostics, verdicts, blueprints)
  - `tools/slider_day_variation_audit.py` — HTTP, slider-only day-over-day deltas (now incorporated into the production audit analyzer)
  - `Cosmic FitTests/NarrativeCohesionReport_Tests.swift` — direct Swift engine, plan-level coherence gates (opposition violations, cross-surface, accent-salience match)

- **Inspector** (`inspector/run-inspector.sh`) compiles the same engine sources as the iOS app via symlinks. Must be built on current `main` before running HTTP harnesses.

- **Engine IDs:** `"production"` and `"stage1_experimental"` are functionally identical (same calibration, same math). Production audit now uses `"production"` to match the shipped app.

- **Synthetic cohort:** 216 users (12 signs × 3 times × 3 cities × 2 birth years) in `inspector/Resources/synthetic_cohort.json`. With 7 presets = 223 total users.

---

## File Paths Quick Reference

| What | Path |
|------|------|
| Plan file | `.cursor/plans/unified_daily_fit_audit_ba334d41.plan.md` |
| Production audit output | `docs/fixtures/production_audit_v2/` |
| Production audit harness | `tools/production_audit_harness.py` |
| Production audit analyzer | `tools/production_audit_analyze.py` |
| Swift cohesion test | `Cosmic FitTests/NarrativeCohesionReport_Tests.swift` |
| Cohesion report output | `docs/fixtures/narrative_cohesion_report.json` + `.txt` |
| Slider variation audit | `tools/slider_day_variation_audit.py` |
| Slider gates checker | `tools/verify_slider_gates.py` |
| Inspector start script | `inspector/run-inspector.sh` |
| Synthetic cohort | `inspector/Resources/synthetic_cohort.json` |
| This handoff | `docs/handoff/unified_daily_fit_audit_handoff.md` |
