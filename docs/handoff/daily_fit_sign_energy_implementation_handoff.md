# Daily Fit — SignEnergyMap Implementation Handoff

**Status:** Ready for implementation after P0 sign-off — **P0 Option A shipped for stage1 (2026-05-22)**  
**Date:** 2026-05-22  
**Audit source:** [`docs/fixtures/daily_fit_sign_energy_audit_report.md`](../fixtures/daily_fit_sign_energy_audit_report.md)  
**Prior audit spec:** [`daily_fit_sign_energy_meaning_audit_handoff.md`](daily_fit_sign_energy_meaning_audit_handoff.md)

---

## 1. Hard gate — P0 product decision

**Do not write code until Ash chooses one option.**

| Option | What changes | Files likely touched |
|--------|--------------|----------------------|
| **A — Fashion weather** | Remove sign multipliers from production daily full-mix; apply only on chart-anchor path (align with `stage1_experimental` sky slice) | `DailyEnergyEngine.swift`, possibly `DailyFitEngineRegistry.swift`, product copy |
| **B — Natal signature** | Keep production architecture; apply Phase 1 cell tuning only | `DailyFitTypes.swift` (+ tests/docs below) |

If **A**: Phase 1 float table may be unnecessary or reduced — confirm with Ash before editing `signEnergyMap`.

If **B**: implement Phase 1 exactly as specified below.

**Update (2026-05-22):** P0 Option A implemented for `stage1_experimental` via `SignMultiplierPolicy`. Phase 1 map tuning applied to `DailyFitCalibration.default.signEnergyMap`. Validation harness: `python3 tools/sign_energy_inspector_harness.py` → `docs/fixtures/sign_audit_downstream_post_phase1.txt`.

---

## 2. Phase 1 — Mandatory sign map changes (Option B)

**File:** `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift`  
**Target:** `DailyFitCalibration.default.signEnergyMap` (lines ~534–547)

Apply these 13 cell updates only:

```swift
// Phase 1 — from audit D5
"Aries":       [..., .classic: 0.95, ..., .drama: 1.35, ...]
"Cancer":      [..., .utility: 1.05, ...]
"Leo":         [..., .utility: 0.95, .drama: 1.35, ...]
"Virgo":       [..., .utility: 1.30, ...]
"Libra":       [..., .playful: 1.30, .edge: 0.95, ...]
"Scorpio":     [..., .romantic: 0.95, .utility: 1.00, .drama: 1.35, ...]
"Aquarius":    [..., .utility: 1.00, ...]
"Pisces":      [..., .edge: 1.25, ...]
```

All other cells remain at current values.

### Registry sync

`DailyFitEngineRegistry.swift` clones `DailyFitCalibration.default.signEnergyMap` for `production` and `stage1_experimental` presets. After editing `DailyFitTypes.swift`, verify fingerprints update as expected — no separate map copy unless a preset intentionally diverges.

---

## 3. Phase 2 — Optional ceiling caps (Option B, Ash approval only)

**Do not implement in the same PR as Phase 1 unless Ash explicitly approves Phase 2.**

| Sign | Energy | Current | Optional |
|------|--------|---------|----------|
| Taurus | classic | 1.50 | 1.35 |
| Gemini | playful | 1.50 | 1.35 |
| Virgo | classic | 1.50 | 1.35 |
| Capricorn | classic | 1.50 | 1.35 |
| Aquarius | edge | 1.50 | 1.35 |
| Pisces | romantic | 1.50 | 1.35 |

Run inspector 14-day harness after Phase 1; only apply Phase 2 if dominant lock remains unacceptable.

---

## 4. Stacking policy (Ash decision — same or follow-up PR)

Audit flagged double weighting: `signEnergyMap` + `elementBoosts` in `DailyEnergyEngine.swift` both push drama/playful/classic/utility on the Sun element.

| If intent is… | Action |
|---------------|--------|
| Daily weather | Soften or skip `elementBoosts` when Sun `signEnergyMap` for that energy already > 1.30 |
| Natal signature | No code change; document stacking in `docs/calibration_signoff.md` |

---

## 5. Tests and docs

| Item | File | Action |
|------|------|--------|
| Coherence assertions | `Cosmic FitTests/AstrologicalSoundness_Tests.swift` | Update expected values for changed cells; expand beyond 4 anecdotes when feasible |
| R3–R6 | same | Leo drama 1.35 still >= Aries 1.35 — passes |
| Calibration sign-off | `docs/calibration_signoff.md` | Record approved band, P0 choice, Phase 1 deltas |
| README §4.1 | `README.md` | Note sign map revision if product-facing |

**Known CI blocker:** `Cosmic_FitTests` may not be in scheme test plan; duplicate tarot PNG copy targets may also block build. Fix scheme membership or run tests manually in Xcode before merge.

---

## 6. Inspector validation (acceptance)

After implementation, rerun read-only harness:

```bash
cd inspector && ./run-inspector.sh
# POST /api/inspect — use birth from inspector/Resources/presets.json
```

**Window:** 14 UTC days, e.g. `2026-05-09` … `2026-05-22`  
**Presets:** fire (Aries), earth (Taurus), air (Aquarius), water (Scorpio)  
**Engines:** `production`, `stage1_experimental`

**Counterfactual (read-only):**

```text
neutral Sun = normaliseToTwentyOne(rawEnergyScores)
production    = normaliseToTwentyOne(rawEnergyScores * signEnergyMap[Sun])
```

### Success criteria (Phase 1, Option B)

| Check | Baseline (pre-change) | Expect after Phase 1 |
|-------|----------------------|----------------------|
| Scorpio prod dominant drama | 14/14 days | Lower lock or lower avg drama bar — not necessarily zero |
| Aquarius prod dominant edge | 14/14 days | Some sky-driven variation if edge cap not applied |
| Leo drama | Not in inspector presets | Add Leo preset (P2) and confirm D bar / dominant stable but less saturated |
| `testSignEnergyCoherence` | Passes | Still passes after Leo/Aries drama both 1.35 |
| No regression | stage1 sky path unchanged | Sky bars still skip sign mult on daily path |

Document before/after flip rates in PR description or `docs/fixtures/`.

---

## 7. P2 follow-ups (separate tickets OK)

1. **Leo inspector preset** — e.g. from `docs/fixtures/blueprint_birth_specs.json` `real_leo_01`
2. **Parameterized R1–R14 tests** — replace anecdotal coherence checks
3. **Test-only all-1.0 / capped-map harness** — for future calibration A/B
4. **Cosmic Fit six-energy ontology** — fashion-first definitions for product copy

---

## 8. Out of scope for this ticket

- Stage 2 formulas (palette, vibrancy, silhouette)
- Blueprint / Style Guide colour families
- Tarot narrative generation
- Changing `planetEnergyBase` or `lunarPhaseEnergies` unless downstream audit surprises appear

---

## 9. Quick reference

| Symbol | Location |
|--------|----------|
| `SignEnergyMap` | `DailyFitTypes.swift` |
| `applySignMultipliers` | `DailyEnergyEngine.swift` |
| `elementBoosts` | `DailyEnergyEngine.swift` |
| Engine presets | `DailyFitEngineRegistry.swift` |
| Inspector presets | `inspector/Resources/presets.json` |
