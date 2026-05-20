## Context

Implement **one phase only** of the Daily Fit Engine Version Selector.

**Spec (authoritative):** `docs/handoff/daily_fit_engine_selector_spec.md`

**Read before coding:** §1.1 (guardrails), §3.2 (versioning boundary), §16 (phase scope table), §17.1/§17.3 (file allowlist), §22 (PR checklist).

**Golden rule:** If a file is not in §17.1 or §17.3 for this phase, do not edit it. Use §16 for what the phase delivers; §17 for which files may change.

**This work is selector infrastructure only.** Do not add `variation_v1`, tune weights, change `DailyFitCalibration.default` values, or refactor engine algorithms unless this phase explicitly says so.

**Phase order:** P0 → P1 → … → P9. Do not skip ahead. **P9** (root README) runs after P0–P5; optional P6/P7/P8 may merge before or after P9. Assume prior phases are merged and working.

**Phase handoff files:** `docs/handoff/phase-0.md` … `phase-9.md` (+ this file).

**Verify after every phase:**
- `Cosmic FitTests` pass with no `DAILY_FIT_ENGINE_ID` in the environment
- `production` preset output unchanged vs pre-implementation baseline (bit-identical for same profile/date/blueprint/tarot state)
- Complete §22 checklist for this phase in the PR description