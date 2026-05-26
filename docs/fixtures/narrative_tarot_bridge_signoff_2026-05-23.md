# Narrative Tarot Bridge — Signoff 2026-05-23

**Status:** Phase 1 complete (trace only; bridgePass does not fail overallPass)  
**Profile:** Briar (`briar_sky_v2`)  
**Window:** 2026-05-23 → 2026-06-05 (14 days)  
**Engine:** `stage1_experimental`

## Calibration

| Tunable | Value | Notes |
|---------|-------|-------|
| `variantBridgeWeight` | **0.25** | Starting conservative per spec §5.4 |
| `bridgeCandidatePoolSize` | **15** | Full deck funnel headroom |
| `minVariantBridgeSimilarity` | **0.50** | Phase 1: trace-only threshold |
| `minBridgeMargin` | **0.01** | Phase 1: trace-only threshold |
| `pairScoreTieEpsilon` | **0.01** | Matches card tie-break |
| `categoryBoostWeight` | 0.15 | Unchanged from v1.1 |

## Test Results (automated)

| Test | Result |
|------|--------|
| `briar14DayAllBridged` | PASS — 14/14 days have non-nil bridge trace, pairsEvaluated > 0 |
| `jointSelectionCanBeatCardFirst` | PASS — variant scoring changed card winner within 14-day window |
| `bridgeTracePopulated` | PASS — all trace fields present and within valid ranges |
| `deterministicPair` | PASS — same inputs yield identical card+variant |
| `productionUnchanged` | PASS — nil bridgeTrace on production path |
| `ProductionFingerprintGuard` | PASS — production fingerprint unchanged |
| `NarrativeTarotUnification` | PASS — stage1VariantScored, categoryBoostApplied |
| `NarrativeCoherence_Briar` | PASS — all 4 existing coherence tests green |

## Bridge Stats Summary

- **Coverage:** 14/14 days have bridge trace (100%)
- **Joint selection impact:** Variant scoring demonstrably changes winning card on ≥1 day
- **Determinism:** Verified — same inputs produce identical (card, variant)
- **Production safety:** Production fingerprint unchanged; nil-intent path byte-identical

## Contrast Day Analysis

Briar's 14-day window is predominantly `reinforce` (shared drama top-1 anchor/weather). 
True contrast days with `overlapCount == 0` are rare for this profile in this window.
When contrast occurs, `contrastWeatherWins` is exported in trace; 1.2× variant multiplier
ensures weather-facing copy preference.

## Re-baselined Golden Tests

No golden tarot expectations needed re-baselining. The `DailyFitSkyForwardV2_Tests` remain
unchanged because:
1. Production path is untouched
2. Stage-1 tests use `DailyFitPipeline.generateWithTrace` which now uses the unified selector
3. The 14-day bridge test covers the stage-1 path

## Threshold Tuning Notes

Starting with `variantBridgeWeight = 0.25` (conservative). Observations:
- Joint selection demonstrably shifts cards when variant energy alignment is strong
- `bridgeCandidatePoolSize = 15` provides headroom beyond the existing top-10 trace
- No adjustment needed for Phase 1 (trace-only); revisit in Phase 2 enforcement

## Deferred Items

- **Wren variety:** Separate ticket — bridge may help but cannot solve template diversity
- **Phase 2 enforcement:** Blocked on Linden/Wren fixture natal signs (§15.1)
- **Threshold tuning from Linden/Wren:** Requires inspector-derived natal signs
- **`ground` relationship:** Deferred to v1.2 per parent spec

## Approval

Phase 1 (trace + joint selection) ready for merge.  
Phase 2 (bridgePass in overallPass) requires Ash review of contrast-day manual read.
