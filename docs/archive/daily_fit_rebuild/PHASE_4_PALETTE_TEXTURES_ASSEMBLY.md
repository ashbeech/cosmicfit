# Phase 4: BlueprintLensEngine — Outfit Breakdown, Essence, Silhouette & Full Payload Assembly

**Dependency:** Phase 0 (types) + Phase 2 (snapshot) + Phase 3 (`BlueprintLensEngine.swift` with tarot + style edit).
**Produces:** The complete `BlueprintLensEngine.generatePayload()` method that returns `DailyFitPayload`.
**Estimated scope:** ~350–450 lines added to existing `BlueprintLensEngine.swift`.

---

## 1. Context

Phase 3 built tarot card and style edit selection. This phase completes Stage 2 by adding:

1. **Daily palette selection** — 3 colours from the user's Blueprint palette, influenced by today's energy.
2. **Vibrancy, Contrast, Metal Tone** — 3 Blueprint-anchored scales modulated by daily energy/axes.
3. **Essence triangle** — collapsing 6 energies into 3 meta-dimensions for the triangle chart.
4. **Silhouette profile** — 3 bipolar scales with Blueprint baseline and axes modulation.
5. **Texture & pattern selection** — retained for diagnostics/future use (not displayed in current UI).
6. **Full `DailyFitPayload` assembly** — the complete output contract for the UI.

### The Blueprint-as-Lens Principle

> **The Blueprint defines the user's range. The daily energy moves a cursor within that range. Never outside it.**

This is the central design constraint of Stage 2. Every section must respect it differently:

| Section | Blueprint influence | Energy influence | Effect |
|---|---|---|---|
| **Palette** | 100% constraint — only Blueprint colours | Energy decides *which* colours surface today | Same user, different day = different 3 colours, always from their palette |
| **Vibrancy** | Sets centre point + ceiling/floor | Drama/Edge push up, Utility/Classic pull down | Deep Autumn stays vibrant; Soft Summer stays muted — but both vary daily |
| **Contrast** | Sets centre point + ceiling/floor | High Visibility → higher contrast | High-contrast user never goes flat; low-contrast user never goes jarring |
| **Metal Tone** | Sets baseline from temperature + metals | Fire transits → warmer, Water → cooler | Gold-leaning user stays warm but may shift slightly on watery days |
| **Essence triangle** | **Not constrained** — pure energy readout | 100% from vibe profile | Shows "what the sky is doing today", not a style prescription |
| **Silhouette** | ~75% baseline from style core/code | ~25% modulation from axes | Structured user stays structured; small daily nudges for freshness |
| **Textures** | 100% constraint — only Blueprint textures | Axes decide which surface today | (Computed, not displayed in current UI) |
| **Patterns** | 100% constraint — only Blueprint patterns | Visibility + energy gate | (Computed, not displayed in current UI) |

### Legacy system

The existing `DailyColourPaletteGenerator` has two paths:
- **Legacy path** (`selectDailyColours`): scores colours via string-matching vibe-to-colour alignment. Dead — tab bar never passes style guide colours.
- **V4 path** (`selectV4DailyColours`): simple deterministic rotation through the Blueprint palette based on day index. Works, but is pure rotation with no energy influence.

Your new palette selection combines the best of both: it selects from the Blueprint palette (like V4) but uses the energy snapshot to influence *which* colours are highlighted (adding the energy-awareness the V4 path lacks).

---

## 2. File Location

You are **extending** the existing file from Phase 3:

```
Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift
```

The total file size after this phase should be under 700 lines.

---

## 3. Blueprint Data You Will Consume

All data comes from `CosmicBlueprint` (defined in `BlueprintModels.swift`, 565 lines). The relevant sections:

### Palette (`blueprint.palette: PaletteSection`)

| Field | Type | Count | Notes |
|---|---|---|---|
| `neutrals` | `[BlueprintColour]?` | 4 | V4 neutral anchors. May be nil for legacy blueprints. |
| `coreColours` | `[BlueprintColour]` | 4 | Core palette anchors. Always present. |
| `accentColours` | `[BlueprintColour]` | 4 | Accent colours. Always present. |
| `supportColours` | `[BlueprintColour]?` | 4 | V4.2+ support colours. May be nil. |
| `lightAnchor` | `BlueprintColour?` | 1 | V4.3+ light edge anchor. |
| `deepAnchor` | `BlueprintColour?` | 1 | V4.3+ deep edge anchor. |
| `luminarySignature` | `BlueprintColour?` | 1 | V4.4+ Sun-derived hero colour. |
| `rulerSignature` | `BlueprintColour?` | 1 | V4.4+ ruler-derived signature. |

`BlueprintColour` has `name: String`, **`hexValue: String`** (NOT `hex`), and a **`role: ColourRole`** property where `ColourRole` is a typed enum (NOT a raw String). Check `BlueprintModels.swift` for the exact struct definition and all available fields. Use `hexValue` wherever you need the hex string, and the typed `ColourRole` enum for role comparison.

### Textures (`blueprint.textures: TexturesSection`)

| Field | Type | Notes |
|---|---|---|
| `recommendedTextures` | `[String]` | Top 4 textures. Always present. |
| `avoidTextures` | `[String]` | Top 3 to avoid. |
| `sweetSpotKeywords` | `[String]` | Top 2 sweet-spot keywords. |

### Palette Variables (`blueprint.palette.variables: DerivedVariables?`)

Available when the Blueprint was generated with V4+ engine. Check `ColourEngineV4/Domain.swift` for the full type:

| Field | Type | Notes |
|---|---|---|
| `depth` | `DepthLevel` enum | Light, Medium, Deep |
| `temperature` | `Temperature` enum | Cool, Neutral, Warm |
| `saturation` | `Saturation` enum | Soft, **Muted**, Rich |
| `contrast` | `ContrastLevel` enum | Low, Medium, High |
| `surface` | `SurfaceQuality` enum | Soft, Balanced, Structured |

These are the user's **permanent palette characteristics** — they anchor the vibrancy, contrast, and metal tone scales.

### Hardware (`blueprint.hardware: HardwareSection`)

| Field | Type | Notes |
|---|---|---|
| `recommendedMetals` | `[String]` | Recommended metals, e.g. ["gold", "brass", "copper"] or ["silver", "platinum", "white gold"]. |
| `recommendedStones` | `[String]` | Recommended stones. |
| `metalsText` | `String` | AI narrative about metals (not used in derivation). |
| `stonesText` | `String` | AI narrative about stones (not used in derivation). |
| `tipText` | `String` | AI hardware tip (not used in derivation). |

The metal preferences encode a temperature lean: gold/brass/copper = warm; silver/platinum/pewter = cool; rose gold/mixed = mixed.

### Style Core (`blueprint.styleCore: StyleCoreSection`)

Has a single field `narrativeText: String` — an AI-generated paragraph. **Not usable for programmatic derivation** (no structured properties). Do NOT attempt to parse it.

### Code (`blueprint.code: CodeSection`)

Contains deterministic directive arrays that feed silhouette baseline derivation:

| Field | Type | Notes |
|---|---|---|
| `leanInto` | `[String]` | Directives like "structured shoulders", "relaxed draping", "angular tailoring" |
| `avoid` | `[String]` | Directives like "overly stiff fabrics", "boxy silhouettes" |
| `consider` | `[String]` | Directives like "soft layering", "sharp lapels" |

These are the **only structured signals** available for silhouette baseline derivation. See §4.9 for the keyword mapping.

### Patterns (`blueprint.pattern: PatternSection`)

| Field | Type | Notes |
|---|---|---|
| `recommendedPatterns` | `[String]` | Recommended patterns. |
| `avoidPatterns` | `[String]` | Patterns to avoid. |

---

## 4. What You Are Building

### 4.1 Public Entry Point

Replace the Phase 3 partial API with the full payload generator:

```swift
static func generatePayload(
    blueprint: CosmicBlueprint,
    snapshot: DailyEnergySnapshot,
    calibration: DailyFitCalibration = .default
) -> DailyFitPayload
```

This method:
1. Calls `selectTarotAndStyleEdit(snapshot:calibration:)` (from Phase 3).
2. Calls `selectDailyPalette(...)` (new).
3. Calls `deriveVibrancy(...)` (new).
4. Calls `deriveContrast(...)` (new).
5. Calls `deriveMetalTone(...)` (new).
6. Calls `deriveEssenceTriangle(...)` (new).
7. Calls `deriveSilhouetteProfile(...)` (new).
8. Calls `selectDailyTextures(...)` (new — computed, not displayed in current UI).
9. Calls `selectDailyPattern(...)` (new — computed, not displayed in current UI).
10. Assembles `DailyFitPayload`.

### 4.2 Daily Palette Selection

```swift
private static func selectDailyPalette(
    from palette: PaletteSection,
    snapshot: DailyEnergySnapshot
) -> DailyPaletteSelection
```

**Algorithm:**

1. **Build the candidate pool** — gather all available `BlueprintColour` objects into a flat array. Each `BlueprintColour` already carries a `role: ColourRole` enum, so you don't need to assign roles manually. Pool sources:
   - `coreColours` (always present)
   - `accentColours` (always present)
   - `neutrals` (if present)
   - `supportColours` (if present)
   - `luminarySignature` (if present)
   - `rulerSignature` (if present)
   - Do NOT include `lightAnchor` or `deepAnchor` (these are edge anchors for UI framing, not daily recommendations).
   
   Use the colour's typed `ColourRole` enum for role-based scoring (not raw strings).

2. **Score each colour** for today's energy:
   - **Role-energy alignment:** different roles resonate with different energies:
     - Core → Classic, Romantic (these are the stable anchors)
     - Accent → Drama, Playful (these are the statement makers)
     - Neutral → Utility, Classic (foundational, practical)
     - Support → Romantic, Playful (versatile complements)
     - Signature → Drama, Edge (chart-derived hero colours, high impact)
   - Score = sum of (energy_alignment × normalised_vibe_value) for the dominant energies.
   - The energy with the highest vibe score should pull its aligned colour roles to the top.

3. **Ensure diversity:** the 3 selected colours must include at least 2 different roles. If the top 3 are all core colours, swap the third for the highest-scoring non-core colour.

4. **Deterministic tie-break:** use `snapshot.dailySeed` via `SeededRandomGenerator` to break ties.

5. **Build `allPaletteHexes`** — a flat array of all `hexValue` strings from the Blueprint palette (for the context ring in the UI). Include neutrals, core, accent, support, signatures — all available colours. Access each colour's `hexValue` property (not `hex`).

6. **Return** `DailyPaletteSelection` with 3 `DailyColourPick` items and the full hex array.

### 4.3 Daily Texture Selection

```swift
private static func selectDailyTextures(
    from textures: TexturesSection,
    snapshot: DailyEnergySnapshot
) -> [String]
```

**Algorithm:**

The Blueprint has 4 recommended textures. Select 2–3 based on axes:

| Axis State | Texture Preference |
|---|---|
| High action (≥ 7) | Prefer textures associated with movement: jersey, cotton, stretch fabrics |
| High strategy (≥ 7) | Prefer textures associated with structure: tweed, denim, leather |
| High tempo + high visibility | Prefer bold textures: velvet, silk, satin |
| Low tempo + low visibility | Prefer subtle textures: cashmere, linen, fine wool |

Since the Blueprint only provides 4 texture names (not structured data about texture properties), use a simple keyword-matching approach:

1. Define a static mapping of texture keywords to axis preferences:

```swift
private static let textureAxisAffinity: [String: [String: Double]] = [
    "silk":      ["visibility": 0.8, "tempo": 0.6],
    "velvet":    ["visibility": 0.9, "action": 0.3],
    "cashmere":  ["strategy": 0.4, "tempo": 0.3],
    "linen":     ["action": 0.5, "tempo": 0.4],
    "leather":   ["action": 0.8, "strategy": 0.7, "visibility": 0.6],
    "denim":     ["action": 0.7, "strategy": 0.6],
    "wool":      ["strategy": 0.5],
    "cotton":    ["action": 0.6, "tempo": 0.5],
    "suede":     ["visibility": 0.5, "strategy": 0.4],
    "tweed":     ["strategy": 0.8, "visibility": 0.4],
    "satin":     ["visibility": 0.7, "tempo": 0.6],
    "jersey":    ["action": 0.7, "tempo": 0.7],
    "chiffon":   ["visibility": 0.6, "tempo": 0.5],
    "corduroy":  ["strategy": 0.6, "action": 0.4]
]
```

2. For each recommended texture, compute a score by matching its name (case-insensitive substring match) against the mapping and multiplying by the snapshot's normalised axes values.
3. If no mapping match is found, score = 0.5 (neutral — still eligible).
4. Sort by score, take top 2–3 (take 3 if the third score is within 80% of the second).

### 4.4 Daily Pattern Selection

```swift
private static func selectDailyPattern(
    from patterns: PatternSection,
    snapshot: DailyEnergySnapshot
) -> String?
```

Patterns are optional in the Daily Fit. Include a pattern only when the energy profile calls for it:

1. **Gate check:** only suggest a pattern if `snapshot.axes.visibility >= 6.0` AND the dominant energy is Drama, Playful, or Edge. If neither condition is met, return `nil`.
2. If gated in, select the pattern from `patterns.recommendedPatterns` that best matches the dominant energy:
   - Drama → bold patterns (stripes, animal print, large geometric)
   - Playful → fun patterns (polka dots, gingham, colourful prints)
   - Edge → unconventional patterns (abstract, asymmetric, mixed media)
3. Since patterns are just strings, use simple keyword affinity (similar to textures).
4. Deterministic selection via `snapshot.dailySeed` if multiple patterns score equally.

### 4.5 Vibrancy Derivation

```swift
private static func deriveVibrancy(
    from palette: PaletteSection,
    snapshot: DailyEnergySnapshot
) -> Double
```

**Algorithm:**

1. **Establish Blueprint baseline** from `palette.variables?.saturation`:
   - `.soft` → 0.25
   - `.muted` → 0.50
   - `.rich` → 0.75
   - `nil` (legacy blueprint) → 0.50

2. **Compute energy modulation** — Drama and Edge push vibrancy up; Utility and Classic pull it down:
   ```
   energyPush = (drama + edge) / 21.0        // 0.0–1.0 (how much of the day is bold)
   energyPull = (utility + classic) / 21.0    // 0.0–1.0 (how much of the day is grounded)
   modulation = (energyPush - energyPull) * 0.15   // ±0.15 max shift
   ```

3. **Clamp result** to `max(0.0, min(1.0, baseline + modulation))`.

The Blueprint ceiling/floor means a Soft Summer (baseline 0.25) with a Drama-heavy day might reach ~0.40 — noticeably lifted but never "rich". A Deep Autumn (baseline 0.75) on a quiet Utility day might dip to ~0.60 — softer but never muted.

### 4.6 Contrast Derivation

```swift
private static func deriveContrast(
    from palette: PaletteSection,
    snapshot: DailyEnergySnapshot
) -> Double
```

**Algorithm:**

1. **Establish Blueprint baseline** from `palette.variables?.contrast`:
   - `.low` → 0.25
   - `.medium` → 0.50
   - `.high` → 0.75
   - `nil` → 0.50

2. **Axes modulation** — Visibility axis is the primary driver:
   ```
   visibilityNorm = snapshot.axes.visibility / 10.0   // 0.1–1.0
   modulation = (visibilityNorm - 0.5) * 0.20         // ±0.10 max shift
   ```

3. **Clamp** to `[0.0, 1.0]`.

### 4.7 Metal Tone Derivation

```swift
private static func deriveMetalTone(
    from blueprint: CosmicBlueprint,
    snapshot: DailyEnergySnapshot
) -> Double
```

**Algorithm:**

1. **Establish Blueprint baseline** from two sources:
   - `palette.variables?.temperature`: `.cool` → 0.2, `.neutral` → 0.5, `.warm` → 0.8, `nil` → 0.5
   - `hardware.recommendedMetals`: scan for warm keywords ("gold", "brass", "copper", "bronze") vs cool ("silver", "platinum", "pewter", "white gold", "steel"). Compute a `metalLean` ratio.
   - `baseline = (temperatureValue * 0.6) + (metalLean * 0.4)` — temperature is the stronger signal.

2. **Energy/lunar modulation:**
   - Fire-dominant transits (Mars, Jupiter as transit planet + fire-energy alignment) → nudge warm (+0.05 per fire transit, capped at +0.10).
   - Water-dominant transits → nudge cool (-0.05 per water transit, capped at -0.10).
   - Full moon → slight cool nudge (-0.03). New moon → slight warm nudge (+0.03).

3. **Clamp** to `[0.0, 1.0]`. Output: 0.0 = cool, 0.5 = mixed, 1.0 = warm.

### 4.8 Essence Triangle Derivation

```swift
private static func deriveEssenceTriangle(
    from snapshot: DailyEnergySnapshot
) -> EssenceTriangle
```

**This is the one section NOT constrained by the Blueprint.** It's a pure energy readout showing "what the sky is doing today."

**Algorithm:**

1. Collapse the 6-energy vibe profile into 3 meta-dimensions:
   ```
   classicRaw  = vibeProfile.classic + vibeProfile.romantic
   edgyRaw     = vibeProfile.edge + vibeProfile.drama
   groundedRaw = vibeProfile.utility + vibeProfile.playful
   ```

2. Normalise to sum to 1.0:
   ```
   total = classicRaw + edgyRaw + groundedRaw   // Always 21
   classic  = Double(classicRaw) / Double(total)
   edgy     = Double(edgyRaw) / Double(total)
   grounded = Double(groundedRaw) / Double(total)
   ```

3. Return `EssenceTriangle(classic: classic, edgy: edgy, grounded: grounded)`.

The triangle has high daily variance — this is where the user sees the cosmic volatility. Some days the point sits heavily in EDGY, other days it's balanced.

### 4.9 Silhouette Profile Derivation

```swift
private static func deriveSilhouetteProfile(
    from blueprint: CosmicBlueprint,
    snapshot: DailyEnergySnapshot
) -> SilhouetteProfile
```

**Algorithm:**

1. **Establish Blueprint baseline (~75% influence)** by keyword-scanning `blueprint.code`. The `CodeSection` has three `[String]` arrays — `leanInto`, `avoid`, `consider` — containing short directive strings like "structured shoulders", "relaxed draping", "angular tailoring". Scan these for silhouette signals using the keyword map below.

   **Keyword → axis mapping** (case-insensitive, substring match):

   | Axis | Push toward 0.0 (left label) | Push toward 1.0 (right label) |
   |---|---|---|
   | `masculineFeminine` | "masculine", "sharp", "tailored", "utilitarian", "rugged" | "feminine", "delicate", "graceful", "flowing", "soft" |
   | `angularRounded` | "angular", "geometric", "structured", "square", "pointed" | "rounded", "curved", "soft", "organic", "draped" |
   | `structuredDraped` | "structured", "tailored", "crisp", "stiff", "architectural" | "draped", "relaxed", "loose", "fluid", "unstructured" |

   **Scoring method** per axis:
   - Scan all strings in `leanInto` and `consider` for left-label keywords → count as leftHits.
   - Scan all strings in `leanInto` and `consider` for right-label keywords → count as rightHits.
   - Scan `avoid` for left-label keywords → count as rightHits (avoiding structured = lean draped).
   - Scan `avoid` for right-label keywords → count as leftHits.
   - `baseline = rightHits / max(1, leftHits + rightHits)` — gives 0.0–1.0.
   - **If no keywords match (leftHits + rightHits == 0), default to 0.5** (neutral).

   This is intentionally simple — the `CodeSection` data is the only structured signal available. `StyleCoreSection` has only `narrativeText` (a free-text paragraph) which cannot be reliably parsed. Document the keyword map in a code comment for future maintainability.

2. **Apply axes modulation (~25% influence):**
   ```
   actionNorm     = snapshot.axes.action / 10.0
   visibilityNorm = snapshot.axes.visibility / 10.0
   strategyNorm   = snapshot.axes.strategy / 10.0

   masculineFeminine = baseline.mf + (visibilityNorm - 0.5) * 0.25    // High visibility → feminine nudge
   angularRounded    = baseline.ar + (actionNorm - 0.5) * -0.20       // High action → angular nudge
   structuredDraped  = baseline.sd + (strategyNorm - 0.5) * -0.25     // High strategy → structured nudge
   ```

3. **Clamp** all three to `[0.0, 1.0]`.

The modulation is deliberately small — the user should recognise their baseline silhouette most days, with gentle shifts for energy.

### 4.10 Full Payload Assembly

Wire everything together:

```swift
static func generatePayload(
    blueprint: CosmicBlueprint,
    snapshot: DailyEnergySnapshot,
    calibration: DailyFitCalibration = .default
) -> DailyFitPayload {
    let (tarotCard, styleEditVariant) = selectTarotAndStyleEdit(
        snapshot: snapshot,
        calibration: calibration
    )
    let palette = selectDailyPalette(from: blueprint.palette, snapshot: snapshot)
    let vibrancy = deriveVibrancy(from: blueprint.palette, snapshot: snapshot)
    let contrast = deriveContrast(from: blueprint.palette, snapshot: snapshot)
    let metalTone = deriveMetalTone(from: blueprint, snapshot: snapshot)
    let essence = deriveEssenceTriangle(from: snapshot)
    let silhouette = deriveSilhouetteProfile(from: blueprint, snapshot: snapshot)
    let textures = selectDailyTextures(from: blueprint.textures, snapshot: snapshot)
    let pattern = selectDailyPattern(from: blueprint.pattern, snapshot: snapshot)

    return DailyFitPayload(
        tarotCard: tarotCard,
        styleEditVariant: styleEditVariant,
        dailyPalette: palette,
        vibrancy: vibrancy,
        contrast: contrast,
        metalTone: metalTone,
        essenceTriangle: essence,
        silhouetteProfile: silhouette,
        vibeBreakdown: snapshot.vibeProfile,
        axes: snapshot.axes,
        dominantTransits: snapshot.dominantTransits,
        lunarContext: snapshot.lunarContext,
        dailyTextures: textures,
        dailyPattern: pattern,
        generatedAt: snapshot.generatedAt
    )
}
```

---

## 5. What You Must NOT Do

- **Do not modify `BlueprintModels.swift`** or any Blueprint-layer file.
- **Do not modify `DailyColourPaletteGenerator.swift`.** Build fresh.
- **Do not generate colours outside the Blueprint palette.** Every colour in the output MUST come from the user's `PaletteSection`.
- **Do not generate textures outside the Blueprint's `recommendedTextures`.** Every texture MUST be one of the 4 recommended textures.
- **Do not add `print()` statements.**

---

## 6. Acceptance Tests

Create a test file:

```
Cosmic FitTests/BlueprintLensEngine_Payload_Tests.swift
```

### Required Tests

| # | Test | What It Validates |
|---|---|---|
| T4.1 | `testPayloadFullyPopulated` | `generatePayload` returns a `DailyFitPayload` with non-nil tarotCard, styleEditVariant, 3 palette colours, 2–3 textures. |
| T4.2 | `testPaletteColoursFromBlueprint` | Every colour `hexValue` in `dailyPalette.colours` exists in the Blueprint's palette sections (compare using `hexValue`, not `hex`). |
| T4.3 | `testPaletteHas3Colours` | `dailyPalette.colours.count == 3`. |
| T4.4 | `testPaletteDiversity` | At least 2 different roles represented in the 3 colours. |
| T4.5 | `testAllPaletteHexesComplete` | `dailyPalette.allPaletteHexes` contains every `hexValue` from the Blueprint's core + accent + neutral + support colours. |
| T4.6 | `testTexturesFromBlueprint` | Every texture in `dailyTextures` is present in `blueprint.textures.recommendedTextures`. |
| T4.7 | `testTextureCount` | `dailyTextures.count` is 2 or 3. |
| T4.8 | `testPatternNilWhenLowVisibility` | Snapshot with `visibility = 3.0` and dominant Classic → `dailyPattern == nil`. |
| T4.9 | `testPatternPresentWhenHighVisibility` | Snapshot with `visibility = 8.0` and dominant Drama → `dailyPattern != nil`. |
| T4.10 | `testPatternFromBlueprint` | If `dailyPattern` is non-nil, it exists in `blueprint.pattern.recommendedPatterns`. |
| T4.11 | `testPayloadDeterministic` | Same inputs produce identical payload (field-level assertions on all fields including new scales). |
| T4.12 | `testDifferentSnapshotsProduceDifferentPalettes` | A drama-heavy snapshot vs a classic-heavy snapshot against the same Blueprint produces at least 1 different colour in the palette. |
| T4.13 | `testPayloadCodableRoundTrip` | Encode `DailyFitPayload` to JSON, decode back. Assert field-level equality on all properties including vibrancy, contrast, metalTone, essenceTriangle, silhouetteProfile. |
| T4.14 | `testPayloadVibeBreakdownPassedThrough` | `payload.vibeBreakdown` values match `snapshot.vibeProfile` (field-level). |
| T4.15 | `testPayloadAxesPassedThrough` | `payload.axes` values match `snapshot.axes` (field-level). |
| T4.16 | `testVibrancyAnchorsToBlueprint` | A "soft saturation" Blueprint with a Drama-heavy snapshot still has `vibrancy < 0.50`. A "rich saturation" Blueprint with a Utility-heavy snapshot still has `vibrancy > 0.55`. Blueprint dominates. |
| T4.17 | `testVibrancyVariesWithEnergy` | Same Blueprint, two different snapshots (drama-heavy vs utility-heavy). Assert vibrancy values differ by at least 0.05. Energy creates real variation. |
| T4.18 | `testContrastAnchorsToBlueprint` | A "low contrast" Blueprint never produces `contrast > 0.50`. A "high contrast" Blueprint never produces `contrast < 0.50`. |
| T4.19 | `testMetalToneReflectsTemperature` | A warm-temperature Blueprint with gold metals → `metalTone > 0.6`. A cool-temperature Blueprint with silver metals → `metalTone < 0.4`. |
| T4.20 | `testEssenceTriangleSumsToOne` | `essenceTriangle.classic + essenceTriangle.edgy + essenceTriangle.grounded ≈ 1.0` (±0.001). |
| T4.21 | `testEssenceTriangleDramaHeavy` | Snapshot with drama=10, edge=7 → `essenceTriangle.edgy > 0.5`. |
| T4.22 | `testEssenceTriangleBalanced` | Balanced snapshot → all 3 vertices between 0.2 and 0.5. |
| T4.23 | `testSilhouetteBaselineDominates` | Same Blueprint, two snapshots with different axes. Assert all 3 silhouette values change by ≤ 0.25 (Blueprint baseline dominates, axes are a small modulation). |
| T4.24 | `testSilhouetteHighStrategyShiftsStructured` | Snapshot with `strategy = 9.0` → `silhouetteProfile.structuredDraped < 0.50` (shifted toward Structured side). |
| T4.25 | `testSilhouetteValuesInRange` | All 3 silhouette values between 0.0 and 1.0 inclusive. |
| T4.26 | `testVibrancyContrastMetalToneInRange` | `vibrancy`, `contrast`, `metalTone` all between 0.0 and 1.0 inclusive. |

### Blueprint Test Fixture

Create a minimal `CosmicBlueprint` fixture with:
- 4 neutrals, 4 core colours, 4 accent colours, 4 support colours
- `palette.variables` populated: use `.rich` saturation, `.high` contrast, `.warm` temperature for the "warm user" fixture and `.soft` / `.low` / `.cool` for the "cool user" fixture.
- `hardware.recommendedMetals`: `["gold", "brass", "copper"]` for warm fixture, `["silver", "platinum", "white gold"]` for cool fixture.
- 4 recommended textures: "cashmere", "denim", "silk", "leather"
- 3 recommended patterns: "stripes", "herringbone", "abstract geometric"
- `styleCore`: any `narrativeText` string (not used in derivation — just needs to compile).
- `code`: warm fixture uses `leanInto: ["structured shoulders", "sharp tailoring", "angular lines"]`; cool fixture uses `leanInto: ["soft draping", "relaxed fits", "fluid layering"]`. This tests that keyword scanning produces different silhouette baselines.
- Populate other required sections with minimal stub data.

**Create TWO Blueprint fixtures** ("warm user" and "cool user") to test that Blueprint anchoring actually constrains output differently.

Check `BlueprintModels.swift` for all required fields in `CosmicBlueprint` — every section must be provided (even if stubbed) for the fixture to compile.

---

## 7. Definition of Done

- [ ] `BlueprintLensEngine.generatePayload(...)` returns a fully populated `DailyFitPayload` with all new fields.
- [ ] All 26 tests pass.
- [ ] Every colour, texture, and pattern in the output comes from the Blueprint — no generated/invented values.
- [ ] Vibrancy, contrast, and metal tone are Blueprint-anchored — different Blueprints produce meaningfully different baselines.
- [ ] Essence triangle sums to 1.0 and reflects the vibe profile accurately.
- [ ] Silhouette profile is Blueprint-dominated with small axes modulation.
- [ ] `BlueprintLensEngine.swift` is under 700 lines total (Phase 3 + Phase 4).
- [ ] No modifications to any existing file (Phase 3 already modified `TarotCard.swift`).
- [ ] No `print()` statements.

---

## 8. What Comes Next

Phase 5 wires the new 2-stage pipeline into the existing UI, replacing the legacy `DailyVibeGenerator.generateDailyVibe()` call.

---

## 9. Standards

- **No print statements.**
- **No force-unwraps.**
- **Swift naming conventions.**
- **Indentation:** 4 spaces.
- **Line length:** prefer under 120 characters.
- **All new internal methods are `private static`.**
- **`generatePayload` is the sole public API after this phase** (alongside `selectTarotAndStyleEdit` from Phase 3 which remains public for testing).
