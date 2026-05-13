# Calibration Audit & Test Spec — Closure Summary

**Purpose:** In-repo record of work driven by the *Calibration Audit and Distribution Test Spec* (Cursor plan: `calibration_audit_and_test_spec_755e5694.plan.md`, typically under your local `.cursor/plans/`). This file is the **canonical handoff** for anyone who does not have access to that plan file.

**Closure date:** 2026-05-12  
**Status:** Plan items A–D (below) are closed with evidence in this repo.

---

## What Was Closed

### A) Phase 0C — Operational chain (reports → sign-off → thresholds → CI gating)

| Step | What was done |
|------|----------------|
| Report-only baselines | Suites write disambiguated reports via `CalibrationReportHelper.writeReport()` (engine version, UTC date, PID, UUID in filenames). Default directory: `docs/fixtures/`; override with `CALIBRATION_REPORT_DIR`. |
| Human review / sign-off | **`docs/calibration_signoff.md`** — reviewer, date, scope (thresholds, energy maps, calibration weights), decisions, optional follow-ups. |
| Locked thresholds | **Structural** guards are in XCTest (`#expect` on non-empty distributions, source weights sum, etc.). **Numeric** distribution gates (e.g. max family %) are intentionally deferred until more baseline history exists — documented in the sign-off artifact. |
| CI gating | **`CALIBRATION_CI_GATE=1`** turns on stricter paths in distribution/coherence/variation tests (see `CalibrationReportHelper.CalibrationTier`). There is **no** checked-in GitHub Actions workflow; gating is opt-in via environment when you run `xcodebuild`. |

Supporting strategy doc: **`docs/calibration_ephemeris_strategy.md`** (synthetic vs production ephemeris, Tier 2 policy).

### B) Part 3 — Chart population consistency (3A vs 3B–3E)

**Decision (documented in plan + strategy doc):** Parts **3B–3E** intentionally sweep **`ExtendedCalibrationProfiles.allCharts`** — **48 synthetic** sign-array charts — for CI speed and determinism. Part **3A** validates **real** charts from **`docs/fixtures/blueprint_birth_specs.json`** via `allChartsWithEphemeris` when VSOP87 + Swiss Ephemeris are available.

Fixtures for synthetic coverage: **`docs/fixtures/blueprint_calibration_profiles.json`**, **`docs/fixtures/blueprint_calibration_manifest.json`**.

### C) Part 6 — Astrological soundness (automated + sign-off)

| Layer | Location |
|-------|----------|
| **6A** Dataset axioms | **`tools/validate_dataset.py`** — schema + Part 6A axiom checks (Venus fire, Moon water, Saturn structure, `code_leaninto` / `code_avoid` overlap, etc.). |
| **6B–6C** Swift checks | **`Cosmic FitTests/AstrologicalSoundness_Tests.swift`** — energy profile behaviour vs planets/elements; `DailyFitCalibration` source weights and sign multipliers; optional report `astrological_soundness_*.txt`. |
| Human sign-off | **`docs/calibration_signoff.md`** §2–§4 — energy map and calibration weight review tables and approval. |

### D) Phase 0B.2 — VSOP87 safety wording vs implementation

**Implementation (authoritative):**

- **`VSOP87Parser`** loads VSOP87D files from **`Bundle.main`**. On load failure it uses a **Keplerian mean-longitude fallback** for all planets (reduced accuracy). There is **no** `fatalError` in `VSOP87Parser.swift` for missing VSOP data.
- **`Cosmic FitTests/VSOP87BundleIntegrity_Tests.swift`** — asserts all eight `VSOP87D.*` files exist in the **app** bundle and runs a J2000 Earth smoke test (longitude compared in **degrees** after conversion from radians).

**Not the same as VSOP87:** **`SwissEphemerisBootstrap.swift`** may still use `fatalError` if `seas_18.se1` is missing — that is Swiss Ephemeris bootstrap, not VSOP87 file loading.

**Spec alignment:** The calibration plan text was updated to describe **fallback + preflight** as the closed strategy; a full **`throws`** chain through `NatalChartCalculator` remains a possible future improvement, not a closure requirement.

---

## Code & Test Fixes Landed in Repo (high level)

| Area | Change |
|------|--------|
| Tarot path test | **`TarotScoringPathIntegrity_Tests.swift`** — use `BlueprintLensEngine.generatePayload(blueprint:snapshot:)` (production API name). |
| VSOP87 tests | **`VSOP87BundleIntegrity_Tests.swift`** — resolve VSOP files from `Bundle.main` (matches parser); J2000 assertion uses radians→degrees; optional flat resource path fallback. |

---

## How to Run / Reproduce

### Dataset validation (Part 6A)

From repo root:

```bash
python3 tools/validate_dataset.py
```

Optional path: `python3 tools/validate_dataset.py path/to/astrological_style_dataset.json`

### Swift tests — calibration-relevant slices

Stable serial run (recommended locally):

```bash
cd /path/to/cosmicfit

xcodebuild test \
  -workspace "Cosmic Fit.xcworkspace" \
  -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"Cosmic FitTests/VSOP87BundleIntegrity_Tests" \
  -only-testing:"Cosmic FitTests/AstrologicalSoundness_Tests" \
  -only-testing:"Cosmic FitTests/SemanticTokenGenerator_ZodiacMath_Tests" \
  -only-testing:"Cosmic FitTests/TarotScoringPathIntegrity_Tests" \
  -parallel-testing-enabled NO
```

### Enable Tier 2 calibration gates

```bash
CALIBRATION_CI_GATE=1 xcodebuild test \
  -workspace "Cosmic Fit.xcworkspace" \
  -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"Cosmic FitTests" \
  -parallel-testing-enabled NO
```

### Write calibration reports outside `docs/fixtures/`

```bash
export CALIBRATION_REPORT_DIR="/tmp/cosmicfit-calibration-reports"
# then run xcodebuild test as usual
```

---

## Outstanding / Follow-Up (actionable)

These are **not** blockers for the plan closure above; they are the next sensible steps if you want a tighter ship.

| Item | Owner | Action |
|------|--------|--------|
| **`BlueprintDistribution_Tests` runtime crash** | Engineering | Some charts hit `SemanticTokenGenerator` / house-cusp code paths that crash with **index out of range** when running the full blueprint distribution suite. Reproduce: run `BlueprintDistribution_Tests` only. Fix generator bounds or synthetic chart cusps, then re-enable full suite in default CI. |
| **CI pipeline** | Engineering | Add `.github/workflows/` (or other CI) that sets `CALIBRATION_CI_GATE=1` and `CALIBRATION_REPORT_DIR` to a temp path and uploads artefacts. |
| **README vs `test_handoff` path** | Docs | README now points to **`docs/archive/test_handoff.md`** (canonical path). |
| **`calibration_ephemeris_strategy.md` vs 3A output name** | Docs | Strategy doc may mention a computed manifest JSON filename that does not match the **`blueprint_ephemeris_manifest_*.txt`** prefix written by tests — align wording when touching that doc. |
| **`ExtendedCalibrationProfiles` comments** | Engineering | File header says `allCharts` prefers ephemeris; code returns **synthetic only** — align comments with `allCharts` vs `allChartsWithEphemeris`. |
| **Part 6 owner sign-off** | Product / maintainer | **`docs/calibration_signoff.md`** notes optional final human seal; automated tests do not replace product review for copy/weights if you change engines. |
| **`validate_dataset.py` warning** | Dataset | One optional axiom warning (e.g. `saturn_taurus` structure keywords) — cosmetic; see sign-off doc. |

---

## Related Files (quick index)

| Path | Role |
|------|------|
| `Cosmic FitTests/CalibrationReportHelper.swift` | Tier env var, report dir, histogram helpers |
| `docs/calibration_signoff.md` | Human + policy sign-off for 0C and Part 6 |
| `docs/calibration_ephemeris_strategy.md` | Phase 0B hybrid ephemeris / Tier 2 policy |
| `docs/calibration_plan_closure_summary.md` | This summary |
| `tools/validate_dataset.py` | Dataset + 6A axioms |
| `Cosmic FitTests/AstrologicalSoundness_Tests.swift` | Part 6B / 6C automated |
| `Cosmic FitTests/VSOP87BundleIntegrity_Tests.swift` | VSOP87 bundle + smoke |
| `Cosmic Fit/Core/Utilities/VSOP87Parser.swift` | VSOP87 + fallback |

---

## Plan file location (Cursor)

If you use Cursor, the YAML-todo plan may live at:

`~/.cursor/plans/calibration_audit_and_test_spec_755e5694.plan.md`

This repository summary does **not** duplicate every section of that plan; it records **closure decisions and how to operate** the repo afterward.
