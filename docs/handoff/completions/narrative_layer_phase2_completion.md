# Narrative Layer Phase 2 Completion — 2026-06-09

**Conversation scope:** Phase 2 — deterministic MC sign overlays to Style Guide narrative pipeline.
**Audience:** Next AI developer or human reviewer.
**Prerequisite:** Phase 1 (V4.7 MC/Moon depth overlay + V4.8 Black Eligibility) per `colour_engine_v48_black_eligibility_completion.md`.

---

## 1. What was done

All 7 steps from `docs/handoff/style_guide_midheaven_phase2_implementation_plan.md` are complete (Step 0 was already done by Dev 1):

### Step 1: `ChartAnalysis.midheavenSign`

- Added `midheavenSign: String` to the `ChartAnalysis` struct.
- Derived from `chart.midheaven` via existing `signName(for:)` in `ChartAnalyser.analyse()`.
- Updated all 5 `ChartAnalysis(` construction sites in `Cosmic_FitTests.swift`.

### Step 2: MC overlay in `HouseSectOverlayGenerator`

- Added 12-sign Style Core templates (public-image identity sentence).
- Added 12-sign Work occasion templates (professional styling sentence).
- Style Core MC overlay: **always appended** after Venus/sect text.
- Work MC overlay: **conditionally appended** — suppressed when house 10 is in `dominantHouses.prefix(2)` (dedup guard).
- All text is jargon-free: no zodiac sign names, no "Midheaven", no "MC", no house numbers.

### Step 3: BlueprintComposer debug diagnostics

- Added `Midheaven sign: {sign}` to the HOUSE/SECT OVERLAYS diagnostic section.

### Step 4: BlueprintDiagnosticReport MC fields

- Added `midheavenSign: String` and `midheavenOverlayApplied: Bool` to `BlueprintDiagnosticReport`.
- Custom `init(from decoder:)` provides backward-compatible defaults for cached JSON.
- `BlueprintDiagnostics.report(...)` accepts and passes the new fields.
- `BlueprintComposer.composeFull` passes `analysis.midheavenSign` and `midheavenOverlayApplied: true`.
- Inspector `app.js`: added "Midheaven Narrative Overlay" accordion with sign + applied status.

### Step 5: Unit tests

6 new tests added to `HouseSectIntegrationTests`:

| Test | Validates |
|---|---|
| `mcOverlayStyleCoreAlwaysPresent` | Scorpio MC → style core contains "magnetic" |
| `mcOverlayAllSigns` | All 12 signs produce style core text containing "public style" |
| `mcOverlayWorkPresentWhenH10NotDominant` | MC work text present when H10 not dominant |
| `mcOverlayWorkSuppressedWhenH10Dominant` | MC work text suppressed when H10 in top-2 |
| `mcOverlayDeterministic` | 20 runs produce identical output |
| `chartAnalyserMidheavenSign` | ChartAnalyser derives correct MC sign from natal chart longitude |

Updated existing tests:
- `overlayJargonCheck`: extended jargon list to include all 12 sign names + "Midheaven" + "MC"
- `overlayTemplateCoverageFloor`: updated to search both work and daily slots (MC overlay now occupies `occasionsWorkAppend`)

### Step 6: Fixtures regenerated

- `docs/house_sect_regression/input_after/{ash,maria,day_chart_venus_angular,night_chart_venus_cadent}.json` — all regenerated with MC overlay text visible.

### Step 7: Inspector rebuilt

- Inspector SPM package builds and all tests pass.
- Inspector `app.js` shows MC narrative overlay status in diagnostics accordion.
- Pre-existing `InspectOptions` test compilation issue fixed (added `deviceLatitude`/`deviceLongitude` nil params).

---

## 2. Files changed

| File | Change |
|---|---|
| `ChartAnalyser.swift` | Added `midheavenSign` to struct + `analyse()` derivation |
| `HouseSectOverlayGenerator.swift` | MC overlay templates (12+12 signs) + routing + dedup guard |
| `BlueprintComposer.swift` | MC sign in debug diagnostics; pass MC fields to `BlueprintDiagnostics.report()` |
| `BlueprintDiagnostics.swift` | `midheavenSign` + `midheavenOverlayApplied` fields + backward-compat decoder |
| `Cosmic_FitTests.swift` | 5 construction sites updated + 6 new MC tests + 2 existing tests updated |
| `inspector/.../Web/app.js` | MC narrative overlay accordion in diagnostics panel |
| `inspector/Tests/.../DailyFitEngineRegistryInspectorTests.swift` | Fixed pre-existing `InspectOptions` compilation (added location params) |
| `docs/house_sect_regression/input_after/*.json` | Regenerated with MC overlay text |

## 3. Files NOT changed (by design)

| File | Reason |
|---|---|
| `ColourEngineV4/*` | Phase 1 complete; Phase 2 is narrative-only |
| `ArchetypeKeyGenerator.swift` | Keyspace explosion; Venus/Moon/element only |
| `DepthOverlayResolver.swift` | Phase 1 activation rules stable |
| `SemanticTokenGenerator.swift` | Legacy path |
| `DeterministicResolver.swift` | Not palette or narrative |
| `NarrativeCacheLoader` / dataset JSON | Out of scope |

## 4. Test results (full suite, 2026-06-09)

| Suite | Tests | Result |
|---|---|---|
| Full `Cosmic FitTests` | 424 | **All pass** |
| `HouseSectIntegrationTests` | 19 | **All pass** (includes 6 new MC tests) |
| `HardeningEdgeCaseTests` | 5 | **All pass** |
| `ColourEngineV4_UnitTests` | (included) | **Pass** |
| `DepthOverlayResolver_Tests` | (included) | **Pass** |
| `BlackEligibilityResolver_Tests` | (included) | **Pass** |
| `PaletteReworkTests` | (included) | **Pass** |
| Inspector SPM tests | All | **Pass** |

## 5. Fixture validation

| Profile | MC Sign | Style Core overlay | Work overlay |
|---|---|---|---|
| ash | Gemini | "versatile and expressive" | "lean into adaptability" |
| maria | Scorpio | "magnetic and controlled" | "lean into powerful restraint" |
| day_chart_venus_angular | Cancer | "warm and approachable" | "lean into approachable authority" |
| night_chart_venus_cadent | Cancer | "warm and approachable" | "lean into approachable authority" |

## 6. Known issues / notes

1. **`midheavenOverlayApplied` is always `true`.** Since every valid sign resolves to text, this field will be true for all real charts. It's included for completeness and future-proofing (e.g. if a chart somehow produces an unknown sign string).

2. **MC overlay ordering:** Style Core text is appended AFTER Venus + sect overlay text. Work text is appended AFTER any dominant-house work text. This means MC is the last overlay signal in both sections.

3. **H10 dedup guard scope:** The guard suppresses MC work text when H10 is in the top-2 dominant houses. It does NOT suppress MC style core text — the style core MC sentence always fires because it's sign-quality language, not house-activity language.

4. **Palette unchanged by Phase 2.** No `ColourEngineV4/*` files were modified. Family, neutrals, core, support, deep-anchor, and accents remain exactly as Phase 1 (V4.7 + V4.8) left them.

5. **Inspector fixture regeneration not done.** The Stage 1 diagnostics harness (`tools/essence_stage1_diagnostics_harness.py`) and slider range harness were not re-run because they require the Inspector to be serving on port 7777 and are Daily Fit focused. The plan marks these as part of Step 7 validation but they test Daily Fit, not Style Guide MC directly.
