# Colour Engine V4.9 — MC Visibility Accent

**Status:** Ready for implementation
**Date:** 2026-06-10
**Audience:** AI developer with no prior knowledge of this codebase. Read top-to-bottom; every decision is justified.
**Prerequisite docs:**
- `docs/handoff/style_guide_midheaven_gap_handoff.md` (discovery + MC gap rationale)
- `docs/handoff/completions/colour_engine_v48_black_eligibility_completion.md` (V4.7/V4.8 completion state)

---

## 1. Executive Summary

### Problem

The colour engine has two MC-specific post-family overlays:
- **V4.7 DepthOverlayResolver** — adds dark/earthy depth when MC or Moon is in Scorpio, Taurus, Capricorn, Cancer, or Pisces. Targets support colours, deep anchor, and one contrast accent.
- **V4.8 BlackEligibilityResolver** — upgrades the deep anchor to black when Scorpio/Capricorn chart prominence is high enough.

Neither overlay handles the opposite case: a **fire or air MC** (Aries, Gemini, Leo, Libra, Sagittarius, Aquarius) whose public-facing colour direction is *brighter, more vivid, or more memorable* than the earthy/cool family template provides. Users with these MC signs can receive technically correct palettes that lack the single "visibility" accent that makes someone remembered after they leave the room.

### Goal

Add a **V4.9 MC Visibility Accent Resolver** that, when the MC is a fire or air sign, evaluates whether the existing accent band already covers the MC's colour direction. If it does not, the resolver appends one additional accent slot with role `.visibility` — a vivid, strategically chosen colour sourced from the MC ruler's sign expression table.

### What this plan does NOT do

| Out of scope | Reason |
|---|---|
| Modify DepthOverlayResolver | V4.7 depth is stable. Visibility is an additive feature, not a depth modification. |
| Modify BlackEligibilityResolver | V4.8 black is stable. |
| Change family classification | MC remains outside weighted family scoring — always a post-family overlay. |
| Change neutrals or core colours | Only the accent band is affected. |
| Change `ArchetypeKeyGenerator` or narrative keys | Colour-only change, no narrative impact. |
| Handle progressions or transits | Natal chart only. |
| Add MC as a `DriverKey` in `DriverWeights` | MC does not participate in family scoring. |

### Design principle

One colour, strategically chosen, is better than a trio. The resolver adds at most one accent. It is sourced from the MC *ruler's* sign (not the MC sign itself), because the ruler's sign determines how the MC actually expresses — the MC sign sets the "what", the ruler's sign sets the "how".

---

## 2. Current State (Baseline)

### Pipeline order (V4.8)

```
1.  Normalize weighted drivers
2.  Accumulate raw scores
3.  Apply deterministic modifiers
4.  Derive preliminary variables
5.  Classify family
6.  Output canonical variables
7.  Cool-leaning DA flag
8.  Map to cluster
9.  Look up palette template + support
10. Derive secondary pull
11. VariationSlots (bypassed)
11b. Winter-compression anchor override
11c. DepthOverlayResolver.resolve()
11d. BlackEligibilityResolver.resolve()
12. Assemble trace
13. ChartSignatureResolver (luminary + ruler signatures)
14. AccentResolver.resolve()
14b. DepthOverlayResolver.injectAccentDepth()
14c. Accent slot sync (for depth injection display)
15. Palette assembly + validator
16. Return ColourEngineResult
```

### Accent band shape

`AccentResolver` produces up to 2 slots:
- Slot 0: **Signature** accent (strongest underrepresented-element planet)
- Slot 1: **Contrast** accent (next-most-distant hue from Signature)

A collapse pass reduces to 1 slot when both occupy the same hue family (< 30°).

Depth injection (step 14b) can replace the last accent slot with a dark MC sign expression when MC is Scorpio/Capricorn/Taurus and all existing accents are light (L ≥ 40).

### Maria's current accent output (reference case)

Maria's chart: Taurus Sun, Taurus Venus, Taurus Mercury, Capricorn Moon, Capricorn Saturn, Pisces Ascendant, Gemini Mars, Gemini Jupiter, Scorpio Pluto, **Sagittarius MC**.

Current accents (from `docs/house_sect_regression/input_after/maria.json`):

| Slot | Name | Hex | Source Planet | Source Sign | Role |
|---|---|---|---|---|---|
| 0 | Iced Aqua | #00AFBF | Mars | Gemini | Signature |
| 1 | Aubergine | #562865 | Pluto | Scorpio | Contrast |

Maria already has a Gemini-sourced teal (Iced Aqua) from Mars, which happens to cover the same hue direction her Sagittarius MC ruler (Jupiter in Gemini) would request. Her palette is a borderline case — the visibility resolver must detect this existing coverage and skip.

### AccentRole enum (current)

```swift
enum AccentRole: String, Codable, CaseIterable {
    case signature = "Signature"
    case contrast = "Contrast"
    case depth = "Depth"
    case lift = "Lift"
}
```

`.depth` and `.lift` exist but are not currently assigned by any resolver.

### What the visibility accent is NOT

It is not the same as the depth overlay accent injection (step 14b). Depth injection replaces an existing accent with a *darker* variant when MC is Scorpio/Capricorn/Taurus. Visibility injection *appends* a new accent that is *vivid and strategically bright* when MC is a fire/air sign. They occupy different sides of the spectrum and target different MC sign groups with no overlap.

---

## 3. Astrological Design

### Which MC signs trigger visibility?

**Fire and air MC signs only.** These are the signs whose public-facing archetype demands luminosity, vibrancy, or memorability — qualities that earthy/watery family templates tend to underexpress.

```
Visibility MC signs: Aries, Gemini, Leo, Libra, Sagittarius, Aquarius
```

These six signs are exactly the complement of the existing DepthOverlayResolver's `depthSigns` set (Scorpio, Taurus, Capricorn, Cancer, Pisces). There is no overlap by design.

### MC ruler determines colour direction

The colour is sourced not from the MC sign's own expression table but from the **MC ruler's sign** in the user's chart.

Why: In traditional astrology, the MC sign describes the *theme* of public identity. The MC ruler's sign describes *how* that theme is expressed. For colour purposes, the "how" is the actionable signal.

Example — Maria:
- MC sign: Sagittarius → theme = expansive, philosophical, visible
- MC ruler: Jupiter (traditional ruler of Sagittarius)
- Jupiter's sign: Gemini → expression = intellectual, quick, mercurial, teal/aqua
- Visibility colour direction: Gemini → teal/aqua family

Example — hypothetical user:
- MC sign: Sagittarius → same theme
- MC ruler: Jupiter
- Jupiter's sign: Cancer → expression = nurturing, silver, soft blue
- Visibility colour direction: Cancer → completely different palette note

This is the same pattern used by `ChartSignatureResolver.rulerSignature()`, which derives the Ascendant ruler's colour from the ruler planet's sign.

### Domicile rulership table (Ptolemaic, already in `SignArchetypes`)

| MC Sign | Ruler Planet | DriverKey |
|---|---|---|
| Aries | Mars | `.mars` |
| Gemini | Mercury | `.mercury` |
| Leo | Sun | `.sun` |
| Libra | Venus | `.venus` |
| Sagittarius | Jupiter | `.jupiter` |
| Aquarius | Saturn | `.saturn` |

Use `SignArchetypes.domicileRuler(of:)` — this function already exists and returns the correct `DriverKey`.

---

## 4. Activation Rules

The resolver runs as **step 14d** in the pipeline (after accent depth injection, before final palette assembly).

### Gate 1: MC sign must be fire or air

```swift
private static let visibilitySigns: Set<V4ZodiacSign> = [
    .aries, .gemini, .leo, .libra, .sagittarius, .aquarius
]
```

If `input.midheaven` is nil or its sign is not in `visibilitySigns`, skip.

### Gate 2: Family must not already be bright/high-contrast

Families whose templates already contain high-visibility, high-contrast colours do not need additional visibility injection.

```swift
private static let alreadyBrightFamilies: Set<PaletteFamily> = [
    .brightSpring, .brightWinter
]
```

If the family is in `alreadyBrightFamilies`, skip. These families have core colours like `poppy`, `vivid yellow`, `magenta red`, `icy teal` — inherently memorable.

### Gate 3: Existing accent band must lack coverage in the MC ruler's hue direction

This is the key deduplication check. The resolver computes the target hue direction from the MC ruler's sign expression table, then checks whether any existing accent hex is within 40° of that hue.

Algorithm:
1. Resolve MC ruler planet via `SignArchetypes.domicileRuler(of: mcSign)`.
2. Read the ruler planet's sign from `input.sign(for: rulerKey)`.
3. Get the family temperature from `FamilyProfiles.variables(for: family).temperature`.
4. Get the accent candidate list from `SignAccentExpressions.candidates(for: rulerSign, temperature: temperature)`.
5. Compute the target hue as the first candidate's hue angle (most-canonical-first ordering).
6. For each existing accent hex (from `accentHexes` after depth injection), compute Lab hue. If any accent's hue is within 40° angular distance of the target hue AND has chroma ≥ 15 (i.e., it's chromatic, not grey), the MC direction is already covered. Skip.
7. If no accent covers the MC direction, proceed to colour selection.

The 40° threshold matches the existing `AccentResolver.accentHueThresholdLadder` starting value and `collapseHueThreshold: 30°` — it's generous enough to catch "close enough" coverage.

### Gate 4: MC ruler sign must not duplicate an existing accent sign

If the accent band already contains a slot sourced from the exact same sign as the MC ruler sign, skip regardless of hue check. This prevents two slots from the same zodiacal source.

Check: `existingAccentSlots.contains(where: { $0.sourceSign == rulerSign })`.

---

## 5. Colour Selection

When all gates pass:

### Step 1: Get candidates

```swift
let candidates = SignAccentExpressions.candidates(
    for: rulerSign,
    temperature: temperature
)
```

### Step 2: Filter for vibrancy

The visibility accent must be *vivid*. Filter candidates by:
- Chroma (C) ≥ 30. This is higher than the existing `AccentResolver.hueSetChromaFloor` of 10, because the point is a "pop" colour, not a muted note.
- Lightness (L) ≥ 35 and L ≤ 70. Below 35 reads as depth (that's `DepthOverlayResolver`'s territory). Above 70 reads as pastel (not impactful enough for visibility).

```swift
let vivid = candidates.filter { $0.C >= 30 && $0.L >= 35 && $0.L <= 70 }
```

If `vivid` is empty, fall back to all candidates sorted by chroma descending.

### Step 3: Pick the most distinct candidate

From the vivid candidates, choose the one with the maximum minimum ΔE² distance from all existing palette hexes (neutrals + core + support + anchors + signatures + existing accents). This is the same "maximum separation" algorithm used by `DepthOverlayResolver.injectAccentDepth()`.

```swift
let avoidHexes = existingPaletteHexes + accentHexes
var best: (hex: String, name: String, dist: Double)?

for expr in vivid {
    let hex = ColourMath.lchToHex(L: expr.L, C: expr.C, h: expr.h)
    let minDist = avoidHexes.map { ColourMath.labDistanceSquared(hex, $0) }.min() ?? .infinity
    if best == nil || minDist > best!.dist {
        best = (hex, expr.name, minDist)
    }
}
```

### Step 4: Create the accent slot

```swift
AccentSlot(
    hex: chosenHex,
    displayName: chosenName,
    role: .visibility,
    sourcePlanet: rulerKey,   // e.g. .jupiter for Sagittarius MC
    sourceSign: rulerSign,     // e.g. .gemini for Jupiter in Gemini
    saturationOverrideApplied: false
)
```

The `.visibility` role is a new addition to `AccentRole`.

---

## 6. Pipeline Integration

### New step 14d in `ColourEngine.swift`

Insert after the current step 14c (accent slot sync for depth injection), before step 15 (palette assembly):

```swift
// 14d. V4.9 — MC visibility accent. When the MC is a fire/air sign
// and the existing accent band lacks coverage in the MC ruler's
// colour direction, appends one vivid accent for public-facing
// memorability. Complements DepthOverlayResolver (which handles
// depth-sign MCs) by covering brightness-sign MCs.
let visibilityResult = VisibilityAccentResolver.resolve(
    family: family,
    input: input,
    accentHexes: accentHexes,
    accentSlots: finalAccentSlots,
    existingPaletteHexes: personalPaletteHexes
)
if let visSlot = visibilityResult.slot {
    accentHexes.append(visSlot.hex)
    finalAccentSlots.append(visSlot)
}
let visibilityAccent = visibilityResult.trace
```

### Updated palette assembly

No structural change needed. `accentHexes` is already `[String]`, and `finalAccentSlots` is already `[AccentSlot]`. The palette's `accentColours` array grows from 2 to 3 hexes when visibility fires. `BlueprintComposer` already iterates `accentSlots` by index, so a third element will be picked up automatically.

### Updated `ColourEngineResult`

Add one field:

```swift
struct ColourEngineResult: Codable, Equatable {
    // ... existing fields ...
    let visibilityAccent: VisibilityAccentResolver.VisibilityResult
}
```

Default value: `.none` (same pattern as `depthOverlay` and `blackEligibility`).

---

## 7. New File: `VisibilityAccentResolver.swift`

Location: `Cosmic Fit/InterpretationEngine/ColourEngineV4/VisibilityAccentResolver.swift`

### Public types

```swift
enum VisibilityAccentResolver {

    struct VisibilityResult: Codable, Equatable {
        let slot: AccentSlot?
        let mcSign: V4ZodiacSign?
        let rulerPlanet: DriverKey?
        let rulerSign: V4ZodiacSign?
        let applied: Bool
        let skipReason: String?

        static let none = VisibilityResult(
            slot: nil, mcSign: nil, rulerPlanet: nil,
            rulerSign: nil, applied: false, skipReason: nil
        )
    }

    static func resolve(
        family: PaletteFamily,
        input: BirthChartColourInput,
        accentHexes: [String],
        accentSlots: [AccentSlot],
        existingPaletteHexes: [String]
    ) -> VisibilityResult { ... }
}
```

### Trace shape

The `VisibilityResult` traces:
- Which MC sign triggered evaluation
- Which ruler planet and ruler sign were resolved
- Whether it applied and what slot was produced
- A `skipReason` string for diagnostics ("no MC", "MC not a visibility sign", "family already bright", "hue already covered", "ruler sign already in accent band")

### AccentRole extension

Add `.visibility` to the existing enum:

```swift
enum AccentRole: String, Codable, CaseIterable {
    case signature = "Signature"
    case contrast = "Contrast"
    case depth = "Depth"
    case lift = "Lift"
    case visibility = "Visibility"
}
```

This is a one-line change in `Domain.swift`.

---

## 8. Changes to Existing Files

| File | Change | Risk |
|---|---|---|
| `ColourEngineV4/Domain.swift` | Add `.visibility` to `AccentRole`. Add `visibilityAccent: VisibilityAccentResolver.VisibilityResult` to `ColourEngineResult`. | Low — additive. Back-compat decoder already handles missing fields. |
| `ColourEngineV4/ColourEngine.swift` | Add step 14d call site. Pass `visibilityAccent` to result constructor. | Low — three lines of integration. |
| `BlueprintDiagnostics.swift` | Add `visibilityAccent` to `BlueprintDiagnosticReport`. | Low — same pattern as `depthOverlay` and `blackEligibility`. |
| `ColourEngineV4/VisibilityAccentResolver.swift` | **New file** — all resolver logic. | N/A |

### Files NOT changed

| File | Reason |
|---|---|
| `AccentResolver.swift` | Signature + Contrast resolution is unchanged. Visibility is a separate pass. |
| `DepthOverlayResolver.swift` | Depth overlay is stable. No interaction. |
| `BlackEligibilityResolver.swift` | Black eligibility is stable. No interaction. |
| `ChartInputAdapter.swift` | Already populates `midheaven`. |
| `ChartSignatureResolver.swift` | Luminary/ruler signatures are unchanged. |
| `SignArchetypes.swift` / `SignAccentExpressions` | Existing tables are reused. No new expressions needed. |
| `PaletteLibrary.swift` | No new named colours needed. Visibility accent uses LCH→hex conversion. |
| `ArchetypeKeyGenerator.swift` | Narrative keys unchanged. |
| `BlueprintComposer.swift` | Already iterates `accentSlots` dynamically. |

---

## 9. Test Plan

### New test file: `VisibilityAccentResolver_Tests.swift`

| Test | Input | Expected |
|---|---|---|
| `testSkipsWhenNoMC` | Input with `midheaven: nil` | `.none`, skipReason = "no MC" |
| `testSkipsWhenMCIsDepthSign` | MC = Scorpio | `.none`, skipReason = "MC not a visibility sign" |
| `testSkipsForBrightSpring` | Family = Bright Spring, MC = Sagittarius | `.none`, skipReason = "family already bright" |
| `testSkipsForBrightWinter` | Family = Bright Winter, MC = Aries | `.none`, skipReason = "family already bright" |
| `testSkipsWhenHueAlreadyCovered` | MC = Sagittarius, Jupiter in Gemini, existing accent at h≈200 (teal zone) | `.none`, skipReason = "hue already covered" |
| `testSkipsWhenRulerSignAlreadyInAccentBand` | MC = Sagittarius, Jupiter in Gemini, existing accent with `sourceSign: .gemini` | `.none`, skipReason = "ruler sign already in accent band" |
| `testFiresMCRulerInNewDirection` | MC = Sagittarius, Jupiter in Leo, Deep Autumn family, accents in teal+wine zone | `.applied`, slot with Leo-sourced warm gold expression |
| `testFiresAriesMCMarsCool` | MC = Aries, Mars in Scorpio, Soft Summer family | `.applied`, slot with Scorpio cool expressions |
| `testFiresAquariusMCSaturnEarth` | MC = Aquarius, Saturn in Taurus, Soft Autumn family | `.applied`, slot with Taurus warm expressions |
| `testVisibilitySlotHasCorrectRole` | Any firing case | Slot `.role == .visibility` |
| `testVisibilitySlotSourcesFromRulerNotMC` | MC = Sagittarius, Jupiter in Cancer | Slot `.sourceSign == .cancer`, not `.sagittarius` |
| `testVibrancyFilterExcludesLowChroma` | Ruler sign with only low-C candidates below threshold | Falls back to highest-chroma candidate |
| `testDeterminism` | Same input evaluated twice | Identical result |
| `testMariaSagMCSkipsBecauseGeminiCovered` | Maria's actual chart (Sag MC, Jupiter in Gemini, existing Gemini accent) | `.none`, skipReason contains "covered" or "already in accent band" |

### Existing test suites that must still pass

| Suite | Tests | Notes |
|---|---|---|
| `MariaAshLocked_Tests` | All | Family, accents, signatures unchanged. |
| `ColourEngineV4_UnitTests` | 36 | Pipeline produces same results for non-visibility charts. |
| `DepthOverlayResolver_Tests` | 14 | Depth overlay untouched. |
| `BlackEligibilityResolver_Tests` | 10 | Black eligibility untouched. |
| `PaletteReworkTests` | 16 | Template palettes unchanged. |

### Maria's locked fixture

`docs/fixtures/v4_locked_placements_maria.json` does not currently include a `midheaven` field. Since `midheaven` is `PlacementInput?`, the fixture will decode as `nil` and the resolver will skip with "no MC". This is safe for regression.

If you want to validate the Maria-specific skip behavior against a real MC, add `"midheaven": { "sign": "Sagittarius", "degree": ... }` to the fixture and write a dedicated test. Maria's MC is Sagittarius based on her birth data (1989-04-28, 04:30, Athens → Pisces Asc → Sagittarius MC). The expected outcome is: resolver evaluates, finds Gemini-sourced Iced Aqua already in accent band, and skips.

---

## 10. Worked Examples

### Example A: Maria (Sagittarius MC, Deep Winter)

```
MC sign:        Sagittarius → visibility sign ✓
Family:         Deep Winter → not bright ✓
MC ruler:       Jupiter (domicile lord of Sagittarius)
Jupiter sign:   Gemini
Temperature:    Cool
Gemini/cool candidates: Mercurial Teal (h≈200), Cool Citrine (h≈190), Iced Aqua (h≈210)
Target hue:     ~200° (teal zone)

Existing accents:
  Slot 0: Iced Aqua #00AFBF (Mars/Gemini) — hue ≈ 195°
  Slot 1: Aubergine #562865 (Pluto/Scorpio) — hue ≈ 310°

Hue check: Iced Aqua at ~195° is within 40° of target ~200° AND chroma is high
→ SKIP. Hue already covered.

Additionally: existing accent sourceSign == .gemini == rulerSign
→ SKIP. Ruler sign already in accent band.

Result: no visibility accent appended. Palette unchanged.
```

### Example B: Hypothetical user (Sagittarius MC, Jupiter in Leo, Deep Autumn)

```
MC sign:        Sagittarius → visibility sign ✓
Family:         Deep Autumn (warm, deep, rich) → not bright ✓
MC ruler:       Jupiter
Jupiter sign:   Leo
Temperature:    Warm
Leo/warm candidates: Solar Gold (L:72, C:55, h:78), Antique Brass (L:58, C:50, h:62),
                     Amber Flame (L:55, C:58, h:52)

Vibrancy filter (C ≥ 30, 35 ≤ L ≤ 70):
  Solar Gold: L=72 → excluded (too light)
  Antique Brass: L=58, C=50 → ✓
  Amber Flame: L=55, C=58 → ✓

Existing accents: both in teal/wine hue zones (h≈195, h≈15)
Hue check: target hue ~62°. No existing accent within 40°.
Sign check: no accent sourced from Leo.

→ FIRES. Select Amber Flame (L:55, C:58, h:52) or Antique Brass (L:58, C:50, h:62)
  based on maximum ΔE² separation from existing palette.

Result: third accent slot appended with role .visibility, source planet .jupiter,
  source sign .leo. Palette gains a warm gold/amber visibility note.
```

### Example C: Hypothetical user (Aquarius MC, Saturn in Capricorn, Soft Summer)

```
MC sign:        Aquarius → visibility sign ✓
Family:         Soft Summer (cool, medium, muted) → not bright ✓
MC ruler:       Saturn
Saturn sign:    Capricorn
Temperature:    Cool
Capricorn/cool candidates: Saturn Slate (L:25, C:15, h:260),
                           Cool Graphite (L:28, C:18, h:245),
                           Steel Blue (L:32, C:22, h:235)

Vibrancy filter (C ≥ 30): ALL excluded. Capricorn expressions are low-chroma.

Fallback: sort by C descending → Steel Blue (C:22) is highest.
  Still below threshold. Use it anyway as best available.

Hue check: target ~235°. If existing accents are at h≈350 and h≈90,
  no coverage within 40°.

→ FIRES with Steel Blue. A subtle, muted "authority" note rather than a vivid pop.
  This is correct for Capricorn — Saturn doesn't ask for brightness, it asks for weight.
```

This example shows that the resolver naturally adapts: fire MC rulers produce vivid accents, earth MC rulers produce structural ones. The vibrancy filter creates a preference, not a hard gate.

---

## 11. Palette Structure Impact

### Before V4.9

```
Accent band: 1–2 chart-derived slots (Signature + Contrast, collapse to 1 if similar)
```

### After V4.9

```
Accent band: 1–3 chart-derived slots (Signature + Contrast + optional Visibility)
```

The third accent slot is additive. `PaletteTriadV4.accentColours` is `[String]` — no structural schema change. `BlueprintComposer` iterates `accentSlots` dynamically and assigns provenance, so a third slot will appear in the Style Guide output automatically.

### Palette band display order (for Blueprint/Inspector)

When the visibility accent is present, the accent band should display:

```
[ Signature accent ] [ Contrast accent ] [ Visibility accent ]
```

The visibility accent is always last. This matches the existing convention where the most "supplementary" accent occupies the final position.

---

## 12. Diagnostic Trace

### `ColourEngineResult.visibilityAccent`

Carries the full `VisibilityResult` for Inspector drill-down:

```swift
VisibilityResult {
    slot: AccentSlot?          // the appended visibility accent (nil if skipped)
    mcSign: V4ZodiacSign?      // the MC sign that was evaluated
    rulerPlanet: DriverKey?    // the MC sign's domicile ruler
    rulerSign: V4ZodiacSign?   // the ruler planet's sign in the chart
    applied: Bool              // whether a visibility accent was appended
    skipReason: String?        // human-readable reason for skipping
}
```

### `BlueprintDiagnosticReport.visibilityAccent`

Same structure. Carried in the Inspector JSON response alongside `depthOverlay` and `blackEligibility`.

---

## 13. Implementation Order

Execute these steps in order. Each step should compile and pass tests before proceeding.

### Step 1: Add `.visibility` to `AccentRole`

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/Domain.swift`

Add `case visibility = "Visibility"` to the `AccentRole` enum. One line. Existing tests pass — no code currently generates this role.

### Step 2: Create `VisibilityAccentResolver.swift`

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/VisibilityAccentResolver.swift` (new file)

Implement the full resolver as described in sections 4–5. The resolver is self-contained and depends only on:
- `BirthChartColourInput` (Domain.swift)
- `SignArchetypes.domicileRuler(of:)` (SignArchetypes.swift)
- `SignAccentExpressions.candidates(for:temperature:)` (SignArchetypes.swift)
- `FamilyProfiles.variables(for:)` (FamilyProfiles.swift)
- `ColourMath.lchToHex(L:C:h:)` and `ColourMath.hexToLab(_:)` and `ColourMath.labDistanceSquared(_:_:)` (ColourMath.swift)

No new dependencies. No imports beyond Foundation.

### Step 3: Add `visibilityAccent` to `ColourEngineResult`

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/Domain.swift`

Add `let visibilityAccent: VisibilityAccentResolver.VisibilityResult` to `ColourEngineResult`. Default value `.none` in the `init`. Back-compat decoder: `try c.decodeIfPresent(...) ?? .none`.

### Step 4: Wire into `ColourEngine.swift`

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/ColourEngine.swift`

Add step 14d after the existing step 14c accent slot sync:

```swift
let visibilityResult = VisibilityAccentResolver.resolve(
    family: family,
    input: input,
    accentHexes: accentHexes,
    accentSlots: finalAccentSlots,
    existingPaletteHexes: personalPaletteHexes
)
if let visSlot = visibilityResult.slot {
    accentHexes.append(visSlot.hex)
    finalAccentSlots.append(visSlot)
}
```

Pass `visibilityAccent: visibilityResult` to the `ColourEngineResult` constructor.

### Step 5: Update `BlueprintDiagnostics.swift`

**File:** `Cosmic Fit/InterpretationEngine/BlueprintDiagnostics.swift`

Add `visibilityAccent: VisibilityAccentResolver.VisibilityResult` to `BlueprintDiagnosticReport`. Same pattern as `depthOverlay` and `blackEligibility`: add to struct, add to CodingKeys, add back-compat decode with `?? .none`.

### Step 6: Write unit tests

**File:** `Cosmic FitTests/VisibilityAccentResolver_Tests.swift` (new file)

Implement the test plan from section 9.

### Step 7: Run full regression suite

Run all existing test suites listed in section 9. Verify zero regressions. If `MariaAshLocked_Tests` or `ColourEngineV4_UnitTests` fail, investigate — the visibility resolver should be invisible to charts that don't trigger it.

### Step 8: Rebuild Inspector and validate presets

Rebuild the Inspector server (`inspector/` directory). Run all preset profiles. Verify:
- Maria and Ash: no visibility accent (Maria's MC fixture is nil; Ash has a Sagittarius MC but is Bright Spring which skips).
- Any preset with a fire/air MC on a non-bright family: visibility accent appears in the JSON response.

---

## 14. Constants Summary

| Constant | Value | Rationale |
|---|---|---|
| `visibilitySigns` | `{Aries, Gemini, Leo, Libra, Sagittarius, Aquarius}` | Fire + air MC signs — complement of depth signs |
| `alreadyBrightFamilies` | `{Bright Spring, Bright Winter}` | Templates already contain vivid, memorable colours |
| `hueCoverageThreshold` | 40° | Matches AccentResolver starting hue ladder value |
| `chromaticFloor` | 15 | Existing accent must be truly chromatic (not near-grey) to count as coverage |
| `vibrancyChromaMin` | 30 | Visibility accent should be vivid, not muted |
| `vibrancyLightnessMin` | 35 | Below 35 = depth territory (DepthOverlayResolver) |
| `vibrancyLightnessMax` | 70 | Above 70 = pastel (not impactful enough for "memorable") |

---

## 15. Risk Assessment

| Risk | Likelihood | Mitigation |
|---|---|---|
| Third accent slot breaks BlueprintComposer layout | Low | `accentColours` is `[String]` — dynamic. BlueprintComposer iterates `accentSlots` by index. Verify in Inspector. |
| Visibility accent clashes with existing accents | Low | Maximum ΔE² separation algorithm ensures distance. Same algorithm as depth injection. |
| Maria fixture regression | None | `midheaven` is nil in locked fixture → resolver returns `.none`. |
| Ash fixture regression | None | Ash is Bright Spring → bright family skip gate. |
| Too many charts trigger visibility | Medium | Fire/air MC = ~50% of charts. But most will be covered by existing accent band or be in bright families. Monitor via Inspector. |
| Visibility accent looks wrong in warm families with cool MC ruler | Low | Temperature conditioning in `SignAccentExpressions` already adapts candidates to family temperature. A cool ruler sign in a warm family gets the warm candidates for that sign. |

---

## 16. Future Extensions (Out of Scope for V4.9)

1. **Upgrade existing accent vibrancy.** When the accent band covers the MC direction but at low chroma, upgrade the existing accent to a more vivid variant. Deferred because it modifies rather than appends.

2. **MC ruler house weighting.** If the MC ruler is angular (houses 1/4/7/10), give the visibility accent higher chroma. If cadent (3/6/9/12), reduce. Deferred because `BirthChartColourInput` does not carry house data.

3. **Inspector web UI rendering.** Add a `visibilityAccent` row to the Inspector `app.js` accordion. Small JS change, deferred unless needed for validation.

4. **Progressed chart visibility.** The user's partner mentioned that Maria's current progressions are "substantially more Gemini." Progressed chart data is out of scope for the natal colour engine.
