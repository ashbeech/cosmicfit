# Phase 2: DailyEnergyEngine — Axes, Transits & Snapshot Assembly

**Dependency:** Phase 0 (types) + Phase 1 (`DailyEnergyEngine.swift` exists with `generateVibeProfile`).
**Produces:** The complete `DailyEnergyEngine.generateSnapshot()` method that returns a fully populated `DailyEnergySnapshot`.
**Estimated scope:** ~200–250 lines added to the existing `DailyEnergyEngine.swift`.

---

## 1. Context

Phase 1 built the vibe profile generation core. This phase completes Stage 1 of the pipeline by adding:

1. **Derived axes evaluation** — 4 orthogonal style-manifestation axes (action, tempo, strategy, visibility), scored 1–10 with full range utilisation.
2. **Dominant transit extraction** — top 3–5 most influential transits summarised as `[DailyTransitSummary]`.
3. **Lunar context assembly** — phase name, waxing/waning, element.
4. **Daily seed generation** — deterministic seed for downstream selection.
5. **Full snapshot assembly** — the public `generateSnapshot()` entry point.

### Legacy problems this phase fixes

| Legacy Issue | How This Phase Fixes It |
|---|---|
| `DerivedAxesEvaluator` uses `5.0 + (rawScore * 0.5)` → axes cluster around 5–8 | New evaluation uses full 1–10 range with proper sigmoid scaling |
| `AxisVolatilityEngine` modulation is tiny (±12%) and moon logic is inverted | Modulation is integrated into the evaluator, moon logic is correct |
| `DailyVibeContent.derivedAxes` is never assigned (always 5,5,5,5) | Axes are embedded in `DailyEnergySnapshot` — no assignment gap possible |
| Transit data is passed as raw `TransitAspect` arrays through the pipeline | Top transits are pre-summarised as `DailyTransitSummary` |

---

## 2. File Location

You are **extending** the existing file from Phase 1:

```
Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift
```

Add to this file. Do not create a new file. The total file size after this phase should be under 500 lines.

---

## 3. What You Are Building

### 3.1 Public Entry Point

Add this as the **primary public method** (alongside the existing `generateVibeProfile`):

```swift
static func generateSnapshot(
    natalChart: NatalChartCalculator.NatalChart,
    progressedChart: NatalChartCalculator.NatalChart,
    transits: [NatalChartCalculator.TransitAspect],
    moonPhaseDegrees: Double,
    profileHash: String,
    date: Date = Date(),
    calibration: DailyFitCalibration = .default
) -> DailyEnergySnapshot
```

This method:
1. Calls `generateVibeProfile(...)` (from Phase 1) to get the `VibeBreakdown`.
2. Calls `evaluateAxes(...)` (new, built in this phase) to get `DerivedAxes`.
3. Calls `extractDominantTransits(...)` (new) to get `[DailyTransitSummary]`.
4. Calls `buildLunarContext(...)` (new) to get `LunarContext`.
5. Generates the daily seed via `DailySeedGenerator.generateDailySeed(profileHash:for:)`.
6. Sets `generatedAt` to the supplied `date` parameter (NOT `Date()`). This ensures deterministic output — the production caller passes `Date()`, but tests can pass a fixed date.
7. Stores `profileHash` directly on the snapshot (Stage 2 needs it for recency tracking).
8. Assembles and returns `DailyEnergySnapshot`.

### 3.2 Axes Evaluation

```swift
private static func evaluateAxes(
    natalChart: NatalChartCalculator.NatalChart,
    progressedChart: NatalChartCalculator.NatalChart,
    transits: [NatalChartCalculator.TransitAspect],
    moonPhaseDegrees: Double,
    dailySeed: Int,
    calibration: DailyFitCalibration
) -> DerivedAxes
```

The 4 axes describe *how* the day's style energy manifests:

| Axis | Low (1–3) | High (8–10) | Primary Drivers |
|---|---|---|---|
| **Action** | Contemplative, still, receptive | Dynamic, bold, assertive | Mars, Jupiter, Fire sign placements, hard transits |
| **Tempo** | Slow, measured, deliberate | Fast, spontaneous, reactive | Moon phase, Mercury, aspect density, transit count |
| **Strategy** | Intuitive, organic, freeform | Structured, planned, disciplined | Saturn, Virgo/Capricorn placements, earth element weight |
| **Visibility** | Inward, private, subtle | Outward, expressive, bold | Sun, Jupiter, Leo placements, MC planets |

#### Algorithm

For each axis:

1. **Compute raw score** by summing weighted contributions from relevant planets in the natal chart, progressed chart, and transits. Use `calibration.planetAxisMap.weight(forPlanet:axis:)` for the mapping.
2. **Apply moon phase modulation:**
   - Full moon boosts action and visibility.
   - New moon dampens action and visibility, boosts strategy.
   - Waxing phases gradually increase tempo.
   - Waning phases gradually decrease tempo.
   - Use `moonPhaseDegrees / 360.0` as the phase fraction (0.0 = new moon, 0.5 = full moon).
   - **Critical:** The legacy `AxisVolatilityEngine` had inverted moon logic where `fullMoonFactor = abs(phase - 0.5) * 2` was *largest* near new moon. Do NOT replicate this bug. Full moon = phase near 0.5 = max boost to action/visibility.
3. **Apply seed-based daily jitter** (±5–10% variation for flavour):
   - Use the `dailySeed` to create a `SeededRandomGenerator`.
   - Generate 4 jitter values in the range [-0.1, +0.1].
   - Apply as additive adjustments to the raw scores.
4. **Scale to 1–10 range** using a sigmoid-like mapping that utilises the full range:

```swift
private static func scaleToAxis(_ rawScore: Double) -> Double {
    // Sigmoid mapping: maps any raw score to 1–10 with good spread
    // tanh maps (-∞, +∞) → (-1, 1), then we scale to 1–10
    let normalised = tanh(rawScore * 0.5) // 0.5 controls spread
    return 1.0 + (normalised + 1.0) * 4.5  // maps (-1,1) → (1, 10)
}
```

Adjust the constants so that typical raw scores (from the sum of planet contributions) map to a 3–8 centre with 1–2 and 9–10 achievable by strong transits or concentrated placements. The key requirement is: **axes must actually use their full 1–10 range** across different users and days. The legacy system's base-5 floor that made everything cluster at 5–8 is the specific failure you are correcting.

### 3.3 Dominant Transit Extraction

```swift
private static func extractDominantTransits(
    from transits: [NatalChartCalculator.TransitAspect],
    limit: Int = 5
) -> [DailyTransitSummary]
```

1. For each transit, compute a strength score based on:
   - Orb tightness: `1.0 - (abs(orb) / maxOrb)` where maxOrb is the aspect's standard orb.
   - Planet weight: outer planets (Jupiter–Pluto) have more weight than inner (Moon, Mercury).
   - Aspect type: conjunctions strongest, then squares/oppositions, then trines/sextiles.
2. Sort by strength descending.
3. Take the top `limit` transits.
4. Map to `DailyTransitSummary` with normalised `strength` (0.0–1.0, where the strongest transit = 1.0).

Check the `NatalChartCalculator.TransitAspect` struct to understand available fields. Key fields you'll use: `transitPlanet` (or equivalent), `natalPlanet`, `aspectType`/`aspectName`, `orb`.

### 3.4 Lunar Context Assembly

```swift
private static func buildLunarContext(moonPhaseDegrees: Double) -> LunarContext
```

1. Use `MoonPhaseInterpreter.Phase.fromDegrees(moonPhaseDegrees)` to get the phase enum.
2. Map to `phaseName` string (e.g. `.fullMoon` → `"Full Moon"`).
3. Determine `isWaxing`: phases 0–180° are waxing, 180–360° are waning.
4. Determine `element` from the Moon's approximate sign position. Use the phase degrees to estimate the Moon's zodiac sign (this is approximate — the moon phase angle is the Sun-Moon elongation, not the Moon's ecliptic longitude). For V1, derive element from the phase's traditional elemental association:
   - New Moon / Full Moon → Water (emotional peaks)
   - First Quarter / Last Quarter → Fire (action points)
   - Waxing Crescent / Waning Crescent → Air (transitional, mental)
   - Waxing Gibbous / Waning Gibbous → Earth (building, grounding)
5. Pass through `phaseDegrees` as-is.

---

## 4. Integration with Phase 1

Your `generateSnapshot` method calls `generateVibeProfile` from Phase 1. Do not modify `generateVibeProfile` — treat it as a stable internal API. If you find it needs adjustment, flag it in a code comment prefixed `// PHASE1-FEEDBACK:` but do not change it.

---

## 5. What You Must NOT Do

- **Do not modify any existing files** beyond `DailyEnergyEngine.swift`.
- **Do not touch the legacy axes system** (`DerivedAxesEvaluator.swift`, `AxisVolatilityEngine.swift`, `DerivedAxesConfiguration.swift`). Build fresh.
- **Do not replicate the base-5 floor.** Axes must use their full 1–10 range.
- **Do not replicate the inverted moon logic.** Full moon = max expression, not min.
- **Do not add `print()` statements.**

---

## 6. Acceptance Tests

Create a test file:

```
Cosmic FitTests/DailyEnergyEngine_Snapshot_Tests.swift
```

### Required Tests

| # | Test | What It Validates |
|---|---|---|
| T2.1 | `testSnapshotContainsValidVibeProfile` | `snapshot.vibeProfile.totalPoints == 21` and `snapshot.vibeProfile.isValid`. |
| T2.2 | `testSnapshotAxesInRange` | All 4 axes are between 1.0 and 10.0 inclusive. |
| T2.3 | `testSnapshotAxesUseFullRange` | Across 10 different test inputs (varying charts, transits, moon phases), the min axis value seen is ≤ 3.0 and the max is ≥ 8.0. This proves axes aren't clustering. |
| T2.4 | `testSnapshotDeterministic` | Same inputs (including a fixed `date`) produce identical snapshot. Run twice, assert field-level equality on all properties (vibeProfile, axes, dominantTransits, lunarContext, dailySeed, profileHash, generatedAt). `DailyEnergySnapshot` is not `Equatable`, so you must compare fields individually. |
| T2.5 | `testDominantTransitsLimitedTo5` | Even with 20 input transits, `snapshot.dominantTransits.count <= 5`. |
| T2.6 | `testDominantTransitsOrderedByStrength` | `snapshot.dominantTransits` is sorted descending by `strength`. |
| T2.7 | `testDominantTransitsStrengthNormalised` | The first transit has `strength == 1.0` (or close) and all are in 0.0–1.0. |
| T2.8 | `testLunarContextNewMoon` | With `moonPhaseDegrees = 0`, `lunarContext.phaseName == "New Moon"` and `isWaxing == true`. |
| T2.9 | `testLunarContextFullMoon` | With `moonPhaseDegrees = 180`, `phaseName == "Full Moon"` and `isWaxing == false`. |
| T2.10 | `testLunarContextWaxingWaning` | Degrees 0–179 → `isWaxing == true`, 180–359 → `isWaxing == false`. |
| T2.11 | `testFullMoonBoostsActionAndVisibility` | Same chart at full moon vs new moon: full moon has higher action and visibility axes. |
| T2.12 | `testDailySeedMatchesDailySeedGenerator` | `snapshot.dailySeed == DailySeedGenerator.generateDailySeed(profileHash:for:)` with same inputs. Also verify `snapshot.profileHash` matches the supplied profileHash. |
| T2.13 | `testEmptyTransitsProducesValidSnapshot` | Zero transits still produces a complete, valid snapshot with empty `dominantTransits`. |
| T2.14 | `testSnapshotCodableRoundTrip` | Encode snapshot to JSON, decode back, assert field-level equality on all properties (not `==`). Verify `profileHash` survives the round-trip. |

### Test Fixtures

Reuse the fixtures from Phase 1's test file. Extend them with:
- Transit fixtures: create 2–3 pre-built transit arrays (e.g. "heavy Mars transits", "soft Venus transits", "mixed transits").
- Moon phase fixtures: 0° (new), 90° (first quarter), 180° (full), 270° (last quarter).

---

## 7. Definition of Done

- [ ] `DailyEnergyEngine.generateSnapshot(...)` exists and returns a fully populated `DailyEnergySnapshot`.
- [ ] `DailyEnergyEngine.swift` is under 500 lines total (Phase 1 + Phase 2 combined).
- [ ] All 14 tests pass.
- [ ] Axes demonstrably use the full 1–10 range across test inputs (T2.3).
- [ ] Full moon correctly boosts action/visibility (T2.11) — no inverted logic.
- [ ] No modifications to any file other than `DailyEnergyEngine.swift` and the new test file.
- [ ] No `print()` statements.
- [ ] No `StyleToken` references.

---

## 8. What Comes Next

Phase 3 builds `BlueprintLensEngine` Stage 2, starting with tarot card and style edit selection. It consumes the `DailyEnergySnapshot` you produce here.

---

## 9. Standards

- **No print statements.**
- **No force-unwraps.**
- **Swift naming conventions.**
- **Indentation:** 4 spaces.
- **Line length:** prefer under 120 characters.
- **All new methods are `private static`** except `generateSnapshot` which is public.
- **`generateVibeProfile` remains public** for isolated testing.
