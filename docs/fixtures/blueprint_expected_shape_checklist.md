# Blueprint Expected Shape Checklist

> **Purpose:** Validates that any `CosmicBlueprint` JSON output contains every
> required field with the correct type. This is a shape-and-presence check, not a
> prose-content check.
>
> **Usage:** WP3 and WP4 must validate their engine output against this checklist.
> Round-trip tests in `Cosmic_FitTests.swift` assert these same constraints
> programmatically.

---

## Root: `CosmicBlueprint`

| Field | Swift Type | JSON Type | Required | Source |
|-------|-----------|-----------|----------|--------|
| `userInfo` | `BlueprintUserInfo` | object | Yes | U |
| `styleCore` | `StyleCoreSection` | object | Yes | AI |
| `textures` | `TexturesSection` | object | Yes | AI |
| `palette` | `PaletteSection` | object | Yes | D+AI |
| `occasions` | `OccasionsSection` | object | Yes | AI |
| `hardware` | `HardwareSection` | object | Yes | D+AI |
| `code` | `CodeSection` | object | Yes | D |
| `accessory` | `AccessorySection` | object | Yes | AI |
| `pattern` | `PatternSection` | object | Yes | D+AI |
| `generatedAt` | `Date` | string (ISO 8601) | Yes | M |
| `engineVersion` | `String` | string | Yes | M |

---

## `BlueprintUserInfo`

| Field | Swift Type | JSON Type | Required |
|-------|-----------|-----------|----------|
| `birthDate` | `Date` | string (ISO 8601) | Yes |
| `birthLocation` | `String` | string | Yes |
| `generationDate` | `Date` | string (ISO 8601) | Yes |

---

## `StyleCoreSection`

| Field | Swift Type | JSON Type | Required | Non-empty |
|-------|-----------|-----------|----------|-----------|
| `narrativeText` | `String` | string | Yes | Yes |

---

## `TexturesSection`

| Field | Swift Type | JSON Type | Required | Non-empty |
|-------|-----------|-----------|----------|-----------|
| `goodText` | `String` | string | Yes | Yes |
| `badText` | `String` | string | Yes | Yes |
| `sweetSpotText` | `String` | string | Yes | Yes |

---

## `PaletteSection`

| Field | Swift Type | JSON Type | Required | Constraints |
|-------|-----------|-----------|----------|-------------|
| `coreColours` | `[BlueprintColour]` | array of objects | Yes | 3 or 4 items, rank-sorted |
| `accentColours` | `[BlueprintColour]` | array of objects | Yes | **Exactly 4 items (Phase A, was ≥ 2)**, rank-sorted |
| `swatchFamilies` | `[SwatchFamily]` | array of objects | Yes | `coreColours.count + accentColours.count` entries |
| `narrativeText` | `String` | string | Yes | Non-empty; names exactly 2 accents (`.prefix(2)`) |

### `BlueprintColour`

| Field | Swift Type | JSON Type | Required | Constraints |
|-------|-----------|-----------|----------|-------------|
| `name` | `String` | string | Yes | Non-empty |
| `hexValue` | `String` | string | Yes | Matches `#[0-9A-Fa-f]{6}` |
| `role` | `ColourRole` | string | Yes | One of: `core`, `accent`, `statement` |
| `provenance` | `ColourProvenance` | object | Yes | See below; non-optional on new data (Phase A) |

### `ColourProvenance` (new in Phase A)

Tagged union. `kind` discriminates between three variants:

| `kind` | Extra fields |
|--------|--------------|
| `"chartDerived"` | `comboKey: String`, `contributorRank: Int`, `sourceRole: "primary" | "accent"`, `hueGapApplied: Double` |
| `"crossPoolEscalation"` | `comboKey: String`, `contributorRank: Int`, `originalRole: "primary" | "accent"`, `hueGapApplied: Double`, `reason: String` |
| `"libraryFallback"` | `reason: String` |

Fixture expectation: zero `"libraryFallback"` entries for `blueprint_input_user_1` and `_user_2`.

---

## `OccasionsSection`

| Field | Swift Type | JSON Type | Required | Non-empty |
|-------|-----------|-----------|----------|-----------|
| `workText` | `String` | string | Yes | Yes |
| `intimateText` | `String` | string | Yes | Yes |
| `dailyText` | `String` | string | Yes | Yes |

---

## `HardwareSection`

| Field | Swift Type | JSON Type | Required | Constraints |
|-------|-----------|-----------|----------|-------------|
| `metalsText` | `String` | string | Yes | Non-empty |
| `stonesText` | `String` | string | Yes | Non-empty |
| `tipText` | `String` | string | Yes | Non-empty |
| `recommendedMetals` | `[String]` | array of strings | Yes | ≥ 2 items, each non-empty |
| `recommendedStones` | `[String]` | array of strings | Yes | ≥ 2 items, each non-empty |

---

## `CodeSection`

| Field | Swift Type | JSON Type | Required | Constraints |
|-------|-----------|-----------|----------|-------------|
| `leanInto` | `[String]` | array of strings | Yes | ≥ 3 items, each non-empty |
| `avoid` | `[String]` | array of strings | Yes | ≥ 3 items, each non-empty |
| `consider` | `[String]` | array of strings | Yes | ≥ 3 items, each non-empty |

---

## `AccessorySection`

| Field | Swift Type | JSON Type | Required | Constraints |
|-------|-----------|-----------|----------|-------------|
| `paragraphs` | `[String]` | array of strings | Yes | Exactly 3 items, each non-empty |

---

## `PatternSection`

| Field | Swift Type | JSON Type | Required | Constraints |
|-------|-----------|-----------|----------|-------------|
| `narrativeText` | `String` | string | Yes | Non-empty |
| `tipText` | `String` | string | Yes | Non-empty |
| `recommendedPatterns` | `[String]` | array of strings | Yes | ≥ 2 items, each non-empty |
| `avoidPatterns` | `[String]` | array of strings | Yes | ≥ 2 items, each non-empty |

---

## Enum Values (canonical, must not change)

### `ColourRole`

| Case | Raw Value |
|------|-----------|
| `core` | `"core"` |
| `accent` | `"accent"` |
| `statement` | `"statement"` |

### `BlueprintToken.TokenCategory` (10 cases)

| Case | Raw Value |
|------|-----------|
| `texture` | `"texture"` |
| `colour` | `"colour"` |
| `silhouette` | `"silhouette"` |
| `metal` | `"metal"` |
| `stone` | `"stone"` |
| `pattern` | `"pattern"` |
| `accessory` | `"accessory"` |
| `mood` | `"mood"` |
| `structure` | `"structure"` |
| `expression` | `"expression"` |

### `BlueprintArchetypeKey.BlueprintSection` (16 cases)

| Case | Raw Value |
|------|-----------|
| `styleCore` | `"style_core"` |
| `texturesGood` | `"textures_good"` |
| `texturesBad` | `"textures_bad"` |
| `texturesSweetSpot` | `"textures_sweet_spot"` |
| `paletteNarrative` | `"palette_narrative"` |
| `occasionsWork` | `"occasions_work"` |
| `occasionsIntimate` | `"occasions_intimate"` |
| `occasionsDaily` | `"occasions_daily"` |
| `hardwareMetals` | `"hardware_metals"` |
| `hardwareStones` | `"hardware_stones"` |
| `hardwareTip` | `"hardware_tip"` |
| `accessoryParagraph1` | `"accessory_1"` |
| `accessoryParagraph2` | `"accessory_2"` |
| `accessoryParagraph3` | `"accessory_3"` |
| `patternNarrative` | `"pattern_narrative"` |
| `patternTip` | `"pattern_tip"` |
