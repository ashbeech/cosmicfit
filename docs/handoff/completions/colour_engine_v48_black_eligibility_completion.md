# Colour Engine V4.7/V4.8 Completion — 2026-06-09

**Conversation scope:** Phase 1 verification, accent injection visibility fix, and black eligibility resolver.
**Audience:** Next AI developer implementing Phase 2 (narrative MC overlays) per `docs/handoff/style_guide_midheaven_phase2_implementation_plan.md`.

---

## 1. What was done in this conversation

Three pieces of work, in order:

### 1a. Phase 1 verification against Section 2b of the Phase 2 plan

Every claim in Section 2b was verified line-by-line against the actual code. Phase 1 is fully implemented and matches the plan.

| Section 2b Claim | Verified In |
|---|---|
| `BirthChartColourInput.midheaven: PlacementInput?` | `ColourEngineV4/Domain.swift` |
| MC adapted from natal chart | `ColourEngineV4/ChartInputAdapter.swift` |
| Support overlay (last slot substitution) | `ColourEngineV4/DepthOverlayResolver.swift` |
| Deep anchor overlay (shallow families only) | `ColourEngineV4/DepthOverlayResolver.swift` |
| Accent depth injection (after AccentResolver) | `ColourEngineV4/DepthOverlayResolver.swift` |
| MC ranked above Moon with 1.1x multiplier | `DepthOverlayResolver.rankedDepthSigns()` |
| Pipeline order: family → template → winter-compression → resolve() → AccentResolver → injectAccentDepth() | `ColourEngineV4/ColourEngine.swift` |
| Unit tests including accent injection | `DepthOverlayResolver_Tests.swift` (14 tests) |
| `BlueprintDiagnosticReport.depthOverlay` | `BlueprintDiagnostics.swift` |

### 1b. Step 0 fix: accent injection visibility (V4.7 bug)

**Problem:** `ColourEngine.evaluate()` ran `DepthOverlayResolver.injectAccentDepth()` which modified `accentHexes`, but the original `accentSlots` (from `AccentResolver`) were passed unchanged to `ColourEngineResult`. Downstream, `BlueprintComposer.buildV4PaletteSection()` reads `accentSlots[].hex` when slots exist — so the injected dark accent was **computed and traced but never displayed** in the Style Guide UI or Inspector.

**Fix:** Added step 14c in `ColourEngine.swift` — after accent injection, syncs the affected `AccentSlot` with the injected hex and name. Minimal change, no `BlueprintComposer` modification needed.

**File changed:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/ColourEngine.swift` (step 14c, ~lines 183-198)

### 1c. V4.8 — Black Eligibility Resolver (new feature)

**Motivation:** Many users instinctively reach for black regardless of seasonal family. The colour engine should validate and guide that instinct when the chart supports it. Deep/Winter/Bright families already have black in their templates, but Soft/True Summer, Soft/True Autumn, and Spring families did not — even when chart placements strongly justify black.

**Implementation:** New file `ColourEngineV4/BlackEligibilityResolver.swift`. Runs after `DepthOverlayResolver` in the pipeline. Evaluates cumulative chart signals and upgrades the deep anchor to a family-appropriate shade of black when the score meets threshold.

---

## 2. Files changed

| File | Change |
|---|---|
| `ColourEngineV4/ColourEngine.swift` | Step 14c (accent slot sync), step 11d (black eligibility), `blackEligibility` in result |
| `ColourEngineV4/Domain.swift` | Added `blackEligibility: BlackEligibilityResolver.BlackResult` to `ColourEngineResult` |
| `ColourEngineV4/PaletteLibrary.swift` | Added `soft black` (#1A1A1E) and `black brown` (#1C1210) hex entries |
| `ColourEngineV4/BlackEligibilityResolver.swift` | **New file** — black eligibility scoring + mode selection |
| `BlueprintDiagnostics.swift` | Added `blackEligibility` to `BlueprintDiagnosticReport`, custom decoder for back-compat |

## 3. Files NOT changed (and should not be in Phase 2)

| File | Reason |
|---|---|
| `ArchetypeKeyGenerator.swift` | Keyspace explosion; Venus/Moon/element only |
| `DepthOverlayResolver.swift` | Phase 1 complete; activation rules stable |
| `BlueprintComposer.swift` | No structural changes needed; accent slot sync fixed upstream |
| `NarrativeCacheLoader` / dataset JSON | Out of scope |
| `SemanticTokenGenerator.swift` | Legacy path |

## 4. New test file

| File | Tests | Status |
|---|---|---|
| `Cosmic FitTests/BlackEligibilityResolver_Tests.swift` | 10 tests | All pass |

Tests cover: Zendaya-like (Soft Summer + Scorpio MC), Deep Winter skip, True Winter skip, winter-compression skip, fire/air no-black, Capricorn-heavy eligibility, warm family mode selection, full engine integration, determinism, signal tracing.

## 5. Test results (full relevant suite, 2026-06-09)

| Suite | Tests | Result |
|---|---|---|
| `BlackEligibilityResolver_Tests` | 10 | **PASS** |
| `ColourEngineV4_UnitTests` | 36 | **PASS** |
| `DepthOverlayResolver_Tests` | 14 | **PASS** |
| `PaletteReworkTests` | 16 | **PASS** |
| `HouseSectIntegrationTests` | 13 | **PASS** |
| `HardeningEdgeCaseTests` | 5 | **PASS** |
| **Total** | **94** | **All pass** |

Pre-existing failures in `NarrativeTarotBridge_Tests` (10 issues, floating-point drift) and `NarrativeCoherence_Briar_Tests` (2 issues, golden expectation mismatch) remain unchanged from before this conversation.

## 6. V4.8 Black Eligibility — Design Reference

### Pipeline position

```
family → template → winter-compression → DepthOverlayResolver → BlackEligibilityResolver → AccentResolver → accent injection → final palette
```

### Scoring model

Cumulative score from chart signals. Threshold: **>= 2.0** required for eligibility. A single signal is never enough alone.

| Signal | Weight | Rationale |
|---|---|---|
| Scorpio MC | 1.5 | Public image = magnetic depth |
| Scorpio Asc | 1.3 | Presentation reads dark/intense |
| Capricorn MC | 1.2 | Authority/structure = black as power |
| Scorpio Venus | 1.0 | Style instinct toward black |
| Capricorn Asc | 1.0 | Authority presentation |
| Pluto in Scorpio | 0.8 | Generational depth amplifier |
| Scorpio Moon | 0.8 | Emotional pull toward dark |
| Aquarius Asc | 0.7 | Black as modern uniform |
| Scorpio Sun | 0.7 | Identity in depth |
| Capricorn Venus | 0.7 | Quality over flash |
| Scorpio Mars | 0.6 | Drive/action in darkness |
| Aquarius MC | 0.6 | Edge/independence |
| Capricorn Saturn | 0.6 | Saturn in domicile = severity |
| Capricorn Moon/Sun | 0.5 | Earth authority |
| Aquarius Venus | 0.5 | Modern edge in style |
| Pluto in Capricorn | 0.5 | Generational structure |
| Saturn in Scorpio/Capricorn/Aquarius | 0.4 | Saturn dignity = restriction/black |

### Mode selection by family temperature

| Temperature | Score 2.0–3.5 | Score 3.5+ |
|---|---|---|
| Warm | black brown (#1C1210) | true black (#0A0A0A) |
| Cool | ink navy (#1B2A4A) or soft black (#1A1A1E) | true black (#0A0A0A) |
| Neutral | soft black (#1A1A1E) | true black (#0A0A0A) |

### Skip conditions

- Family already has black in template (Deep Winter, True Winter, Bright Winter, Bright Spring)
- Winter-compression already applied (Deep Autumn with black anchor)
- Deep anchor is already a black-named swatch (black, clear black, soft black, black brown, ink brown, blue-black)

### Inspector validation results (all 7 presets + Zendaya)

| Profile | Family | Deep Anchor | Eligible | Mode | Score | Signals |
|---|---|---|---|---|---|---|
| Aries Sun (Fire) | Bright Winter | black | skip | - | 0 | family has black |
| Taurus Sun (Earth) | Bright Spring | clear black | skip | - | 0 | family has black |
| Aquarius Sun (Air) | Bright Winter | black | skip | - | 0 | family has black |
| Scorpio Sun (Water) | Deep Winter | black | skip | - | 0 | family has black |
| Leo Sun (Fire) | True Spring | ink navy | No | - | 0.8 | Pluto in Scorpio (alone, below threshold) |
| Maria (Taurus/Pisces) | Deep Winter | black | skip | - | 0 | family has black |
| Ash (Sag/Pisces) | Bright Spring | clear black | skip | - | 0 | family has black |
| **Zendaya** | **Soft Summer** | **ink navy** | **Yes** | **ink navy** | **2.0** | Capricorn MC, Pluto in Scorpio |

### Diagnostic trace shape

`ColourEngineResult.blackEligibility` and `BlueprintDiagnosticReport.blackEligibility` carry:

```swift
BlackResult {
    mode: BlackMode?          // trueBlack | softBlack | blackBrown | blackCherry | inkNavy
    colourName: String?       // palette name for the chosen swatch
    hex: String?              // hex value
    originalDeepAnchor: String? // what the anchor was before
    eligible: Bool
    score: Double             // cumulative chart signal score
    signals: [String]         // human-readable list of contributing signals
}
```

Inspector JSON response now includes `blueprintDiagnostics.blackEligibility`.

---

## 7. What Phase 2 should do next

Phase 2 is fully scoped in `docs/handoff/style_guide_midheaven_phase2_implementation_plan.md`. The colour engine work from this conversation (Steps 0 and 1b/1c) is **not Phase 2** — it is pre-Phase-2 colour stabilization.

Phase 2 narrative work is:

1. **Step 1:** Add `midheavenSign` to `ChartAnalysis` (struct + `analyse()`)
2. **Step 2:** Add MC overlay to `HouseSectOverlayGenerator` (12-sign Style Core + Work templates, H10 dedup guard)
3. **Step 3:** Update `BlueprintComposer` debug diagnostics (MC sign log line)
4. **Step 4:** Extend `BlueprintDiagnosticReport` with `midheavenSign` + `midheavenOverlayApplied`
5. **Step 5:** New unit tests for MC overlay routing, jargon freedom, deduplication
6. **Step 6:** Regenerate regression fixtures
7. **Step 7:** Rebuild Inspector and validate presets

**Critical constraint:** Phase 2 should **not** modify any `ColourEngineV4/*` files. The colour engine (V4.7 depth overlay + V4.8 black eligibility) is now stable. Phase 2 is narrative-only.

---

## 8. Known issues / notes for next developer

1. **Zendaya's MC sign depends on birth time.** The discovery doc says Scorpio MC, but with 09:02 birth at Oakland the ephemeris gives Capricorn MC + Aries Asc. The unit tests use a synthetic "Zendaya-like" chart with hard-coded Scorpio MC for the canonical test case. Real Zendaya birth time may differ from what was used in the original Inspector PDF.

2. **Accent injection visibility was silently broken before this conversation.** The fix (step 14c accent slot sync) is minimal and correct. If any test expects pre-injection accent hex values in `accentSlots`, it will now see the injected values instead — this is the intended behavior.

3. **Black eligibility does not use house data.** The plan discussed 8th/10th house emphasis as potential signals, but `BirthChartColourInput` does not carry house information — only sign placements. Adding house-based scoring would require expanding the colour input struct, which was out of scope for this conversation. The current sign-based scoring is sufficient for the described use cases.

4. **Pre-existing test failures (12 issues) are unchanged.** `NarrativeTarotBridge_Tests.deterministicPair` (10 floating-point issues) and `NarrativeCoherence_Briar_Tests` / `NarrativePaletteUnification_Tests` (2 golden expectation mismatches) predate this conversation. They are documented in the Plan 1 completion.

5. **Inspector `app.js` does not render `blackEligibility`.** The JSON response carries the full `BlackResult` trace, but the web UI accordion doesn't display it yet. Adding a row is a small JS change, deferred unless needed for Phase 2 validation.

6. **`v4_dataset.json` fixture may need regeneration.** If accent hex arrays in the dataset fixture were recorded before the accent slot sync fix, they will now differ for profiles where accent injection fires. Regenerate with `REGENERATE_BLUEPRINT_FIXTURES=1` if tests flag a mismatch.
