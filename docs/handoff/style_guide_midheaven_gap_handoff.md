# Style Guide Midheaven Gap Handoff

**Status:** Discovery handoff only. No implementation in this document.
**Date:** 2026-06-09
**Audience:** Future AI developer implementing broader Style Guide Midheaven support.
**Current priority:** Keep the active implementation plan focused on the colour palette. Use this handoff later to flesh out a full implementation plan for MC influence across the rest of the Style Guide.

## 1. Executive Summary

We reviewed a Cosmic Fit Inspector PDF for Zendaya and noticed the Style Guide colour palette was broadly plausible but lacked the deeper brown, oxblood, garnet, bark, bitter chocolate, or dark-plum depth that her Scorpio Midheaven and Taurus Moon would be expected to introduce.

The investigation found two separate issues:

- **Colour palette issue:** The V4 colour engine includes the Moon, but the Moon's influence is diluted by family classification and does not reliably surface in visible support/accent/deep-anchor slots. The Midheaven is completely absent from the colour engine input.
- **Broader Style Guide issue:** The Midheaven sign is absent across the Style Guide generation pipeline. The system uses planetary signs, houses, sect, Venus/Moon narrative keys, and dominant house emphasis, but it does not expose or consume a `midheavenSign` as a first-class Style Guide input.

Practical impact varies by section. Colour palette has the clearest and highest-impact gap. Style Core and Occasions may also benefit from MC sign influence. Textures, hardware, and patterns are lower-priority because Venus, Moon, house placement, sect, and deterministic resolver data already provide stronger signals there.

## 2. Scope Boundary

The active implementation plan should remain focused on:

- Adding MC/Moon depth influence to the **Style Guide colour palette only**.
- Preserving the existing palette family classification.
- Allowing MC/Moon to affect support, accent, and deep-anchor positions after the family is chosen.

This handoff is for a later, separate body of work:

- Add MC sign as a broader Style Guide signal.
- Decide which Style Guide sections should consume it.
- Avoid over-expanding the current colour palette change into a narrative architecture change.

## 3. Key Product Finding

For Zendaya's PDF:

- Sun: Virgo
- Moon: Taurus
- Ascendant: Aquarius
- Midheaven: Scorpio
- V4 palette family shown: `Soft Summer`
- Secondary pull shown: `True Summer`

The current palette is coherent for a Soft Summer output: dusty sage, muted rose, mushroom, smoked navy, muted charcoal, warm taupe, camel, and similar colours.

But Scorpio MC plus Taurus Moon should plausibly introduce a deeper public/grounding note. The expected direction is not to reclassify the entire palette as Deep Autumn. The better target is:

```text
Soft Summer base
+ Scorpio MC / Taurus Moon depth overlay
= Soft Summer with richer earth-wine grounding
```

Examples of desired additional notes:

- oxblood
- garnet
- bark brown
- bitter chocolate
- dark plum
- espresso / ink brown where appropriate

## 4. What The Current Code Does

### 4.1 Chart Analysis

File:

- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ChartAnalyser.swift`

`ChartAnalysis` currently exposes:

- `sunSign`
- `moonSign`
- `ascendantSign`
- `venusSign`
- `marsSign`
- `planetSigns`
- `planetHouses`
- `significantAspects`
- `dominantPlanets`
- `chartSect`
- `planetSectStatus`
- `houseEmphasis`

It does **not** expose:

- `midheavenSign`
- `midheavenDegree`
- any MC-specific domain object

The underlying natal chart already has MC data:

- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/Core/Calculations/NatalChartCalculator.swift`
- `NatalChartCalculator.NatalChart` includes `midheaven: Double`

So this is not an astrology calculation gap. It is a downstream analysis/input modeling gap.

### 4.2 Colour Engine V4

**Superseded by V4.7 work completed on 2026-06-09.** This section records the original discovery state. The current implementation is documented in `docs/handoff/style_guide_midheaven_phase2_implementation_plan.md`, especially `## 2b. Phase 1 Actual State (post-iteration, 2026-06-09)`.

Files:

- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/Domain.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/ChartInputAdapter.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/ColourEngine.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/DriverWeights.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/SignContributions.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/FamilyMapping.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/AccentResolver.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ColourEngineV4/PaletteLibrary.swift`

`BirthChartColourInput` includes:

- Ascendant
- Venus
- Sun
- Moon
- Mercury
- Mars
- Saturn
- Jupiter
- optional Pluto
- optional Midheaven (`midheaven: PlacementInput?`) in the current V4.7 implementation

Original discovery note: it did **not** include Midheaven. Current state: Midheaven is present in `BirthChartColourInput`, populated by `ChartInputAdapter`, and consumed by `DepthOverlayResolver`.

Moon is present with weight `14` in `DriverWeights`. Taurus Moon contributes depth and warmth through `SignContributions`, but the final family classification can still land in Soft Summer due to the full chart mix. Once the family is selected, the fixed Soft Summer template dominates the visible palette.

Original V4 flow at discovery time:

1. Normalize weighted drivers.
2. Accumulate raw scores.
3. Apply modifiers.
4. Classify family.
5. Use family canonical variables.
6. Load fixed family palette template and support colours.
7. Optionally apply Deep Autumn winter-compression deep-anchor override.
8. Generate Sun-derived luminary signature.
9. Generate Ascendant-ruler-derived ruler signature.
10. Resolve chart-derived accent slots.
11. Return `ColourEngineResult`.

Current V4.7 colour flow:

```text
family
→ template
→ winter-compression
→ DepthOverlayResolver.resolve()
→ AccentResolver
→ DepthOverlayResolver.injectAccentDepth()
→ final palette
```

Current V4.7 MC/Moon depth behavior:

- Support overlay can replace the last support slot, e.g. `camel` → `oxblood`.
- Deep-anchor overlay can replace shallow-family anchors, e.g. `muted charcoal` → `bitter chocolate`.
- Accent depth injection can replace one light accent with a darker MC expression when MC is Scorpio, Capricorn, or Taurus and the accent band lacks a dark note.
- MC remains outside weighted family scoring; family classification is preserved.

Recommended colour-only insertion point:

- After family/template lookup and winter-compression.
- Before accent resolution.

Reason:

- Family stays stable.
- Neutrals and core colours can remain family-pure.
- Support/deep-anchor can gain MC/Moon depth.
- Accent resolver will then score against the updated support/anchor palette.

### 4.3 Archetype/Narrative Key Generation

File:

- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/ArchetypeKeyGenerator.swift`

Narrative cluster keys are built as:

```text
venus_<sign>__moon_<sign>__<element>_dominant
```

The key generation explicitly prioritizes:

- Venus mismatch distance: 3
- Moon mismatch distance: 2
- Element mismatch distance: 1

There is no MC component in the narrative key.

This means Style Guide narrative selection is strongly Venus/Moon/element driven, with no direct public-image or vocation-signature component from the MC.

### 4.4 House/Sect Overlays

File:

- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift`

This generator appends deterministic overlay text to sections:

- Venus house overlay -> Style Core
- Moon house overlay -> Textures or Daily occasions
- Sect overlay -> Style Core
- Dominant house overlay -> Work or Daily occasions

It knows house 10 as the `"public"` domain through `ChartAnalyser.houseDomainLabel(for:)`, but this is house emphasis, not MC sign.

Important distinction:

- Planets in or emphasis around the 10th house can affect text.
- The zodiac sign on the Midheaven itself does not affect text.

So a user can have Scorpio MC and receive no Scorpio-public-image signal unless other chart factors happen to route similar language.

### 4.5 Semantic Token Generator

File:

- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/InterpretationEngine/SemanticTokenGenerator.swift`

This older/general token generator contains 10th-house logic:

- Angular houses get extra weight.
- House 10 is annotated as Midheaven/public image.
- House 10 can produce professional/public expression tokens.

But this is based on planets being in the 10th house or house context. It does not create tokens from the MC sign itself.

This is not sufficient to solve the gap.

## 5. Section-by-Section Impact Assessment

### 5.1 Colour Palette

Impact: **High**

Reason:

- Colour is where MC sign archetype maps most directly to visible output.
- Scorpio MC should be able to add wine, oxblood, dark plum, bark, or other deep notes.
- Taurus Moon should be able to add grounded earth/brown/olive depth.
- Current palette can be family-coherent but insufficiently personalized.

Recommended action:

- Implement MC/Moon post-family depth overlay in ColourEngineV4.
- Preserve family, core, and neutrals.
- Allow changes to support, accent, and deep-anchor positions.

### 5.2 Style Core

Impact: **Moderate**

Reason:

- Style Core expresses presence, public read, and overall wardrobe identity.
- MC sign is naturally relevant to public image and how a person's style lands in the world.
- Current Style Core gets Venus, sect, and sometimes dominant-house overlays, but not MC sign.

Potential future action:

- Add a lightweight MC-sign overlay to Style Core, separate from archetype key selection.
- Prefer deterministic append text over changing the main narrative cluster key at first.
- Keep language jargon-free, as with the existing house/sect overlays.

Example target behavior:

- Scorpio MC: public style reads more magnetic, controlled, private, intense, polished through depth.
- Taurus MC: public style reads more tactile, stable, expensive, grounded.
- Leo MC: public style reads more radiant, performative, generous, confident.

### 5.3 Occasions

Impact: **Moderate**

Reason:

- Work/professional styling is the clearest narrative area for MC.
- Current dominant-house overlay can route to Work if top houses include `"public"`, but that is not the same as MC sign.

Potential future action:

- Add optional MC overlay specifically to `occasionsWorkAppend`.
- Keep it short and deterministic.
- Avoid duplicating existing house 10 dominant-house text.

### 5.4 Textures

Impact: **Low to Moderate**

Reason:

- Textures are already strongly informed by Moon house and Venus/Moon style logic.
- MC could refine professional texture choices, but it should not dominate sensory/comfort signals.

Potential future action:

- Consider MC only as a secondary modifier for work-facing texture language.
- Do not re-key texture narrative around MC.

### 5.5 Hardware

Impact: **Low**

Reason:

- Hardware is currently driven by deterministic resolver outputs, sect, metals/stones, and chart token sources.
- MC could influence finish or public-facing statement level, but this is likely less urgent than colour and Style Core.

Potential future action:

- Defer unless user-facing audits show hardware repeatedly missing public-image tone.

### 5.6 Patterns

Impact: **Low**

Reason:

- Pattern recommendations are more naturally driven by Venus, Moon, element, house context, and existing pattern token logic.
- MC sign may be relevant for professional pattern restraint or drama, but this is likely a refinement layer.

Potential future action:

- Defer until colour and narrative MC overlays are validated.

## 6. Recommended Future Architecture

### 6.1 Add MC To ChartAnalysis

Add fields such as:

```swift
let midheavenSign: String
let midheavenDegree: Double
```

Source:

```swift
let mcSign = signName(for: chart.midheaven)
```

This makes MC available to all downstream Style Guide modules without each module re-reading raw natal chart geometry.

### 6.2 Keep Colour Engine Input Separate But Consistent

For ColourEngineV4, add optional MC placement directly to `BirthChartColourInput`:

```swift
let midheaven: PlacementInput?
```

This keeps the colour engine deterministic and testable, and avoids relying on `ChartAnalysis` for a field that can be derived from the natal chart.

### 6.3 Use Overlays Before Re-Keying Narrative Clusters

Do **not** start by changing `ArchetypeKeyGenerator` to include MC. That would expand the keyspace massively:

```text
12 Venus x 12 Moon x 12 MC x 4 elements = 6,912 keys
```

The existing representative/fallback key strategy is already designed around Venus, Moon, and element. Adding MC there would create a large narrative-cache and fallback problem.

Safer first step:

- Add `midheavenSign` to `ChartAnalysis`.
- Add deterministic MC append text in `HouseSectOverlayGenerator`.
- Route it to Style Core and/or Work occasions.
- Keep the main narrative key unchanged.

## 7. Relationship To Active Colour Palette Plan

The active colour-palette plan should be treated as Phase 1 of MC work:

1. Add optional MC to colour input.
2. Implement MC/Moon depth overlay after family selection.
3. Preserve family classification and core palette.
4. Add trace metadata.
5. Validate fixture churn.

Future broader Style Guide work should be treated as Phase 2+:

1. Add MC sign to `ChartAnalysis`.
2. Add Inspector diagnostics for MC sign availability.
3. Add Style Core/Work occasion MC overlays.
4. Evaluate user-facing output across known profiles.
5. Only consider narrative-key expansion if overlays prove insufficient.

## 8. Tests And Validation For Future Work

When implementing broader MC Style Guide support, add tests for:

- `ChartAnalyser` exposes correct `midheavenSign` from `NatalChart.midheaven`.
- Existing Style Guide outputs decode and remain backward compatible.
- `HouseSectOverlayGenerator` produces MC overlay text only when appropriate.
- MC overlay routes to the intended section, likely Style Core and/or Work.
- No duplicate or contradictory public-image language when house 10 is already dominant.
- Known profile snapshots show expected changes without broad narrative churn.

Useful existing areas to inspect:

- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic FitTests/Cosmic_FitTests.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic FitTests/PaletteRework_Tests.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/Cosmic FitTests/FixtureRegeneration.swift`
- `/Users/ash/dev/mobile_apps/cosmicfit/docs/house_sect_regression/input_after/`
- `/Users/ash/dev/mobile_apps/cosmicfit/docs/archive/fixtures/blueprint_input_user_*.json`

## 9. Risks

### Risk: MC becomes too dominant

MC should shape public-image polish, not override Venus/Moon/body comfort. In most Style Guide sections it should be a secondary overlay, not a classifier.

### Risk: Narrative key explosion

Adding MC to `ArchetypeKeyGenerator` would greatly expand possible keys and cached narrative requirements. Avoid this unless there is a deliberate narrative-cache redesign.

### Risk: Duplicate language

House 10 dominant-house text and MC sign text could both speak about public identity. Future implementation should dedupe or route MC text only when it adds a distinct sign-based quality.

### Risk: Colour and narrative drift apart

If the colour palette gains MC depth but Style Core remains entirely softness/comfort-oriented, the experience may still feel slightly under-personalized. This is why broader MC narrative support is worth future planning, but not part of the first colour implementation.

## 10. Recommended Next Step

Do not expand the current implementation plan yet. First ship and validate the colour-palette MC/Moon overlay.

After colour validation, create a separate implementation plan for:

- `ChartAnalysis.midheavenSign`
- Style Core MC overlay
- Work occasions MC overlay
- Inspector diagnostics for MC usage
- regression fixtures for broader Style Guide text changes

