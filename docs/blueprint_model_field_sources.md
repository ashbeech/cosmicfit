# Blueprint Model — Field Source Reference

> **Purpose:** Maps every field on `CosmicBlueprint` and its sub-structs to its
> data source category. Use this document to understand what populates each field
> without reading the Swift implementation.
>
> **Audience:** WP3 (engine), WP4 (dataset), WP5 (sync schema).

---

## Source Categories

| Code | Meaning | Populated By |
|------|---------|--------------|
| **D** | Deterministic | WP3 `DeterministicResolver` using WP4 dataset. No AI. |
| **AI** | AI-generated narrative | Cached in `blueprint_narrative_cache.json`, looked up by `BlueprintArchetypeKey`. |
| **U** | User-input passthrough | Copied directly from onboarding / `UserProfile`. |
| **M** | Runtime metadata | Set by the engine at generation time. |

---

## Field Mapping

### `CosmicBlueprint` (root)

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `userInfo` | `BlueprintUserInfo` | U | See below. |
| `styleCore` | `StyleCoreSection` | AI | |
| `textures` | `TexturesSection` | AI | |
| `palette` | `PaletteSection` | D + AI | Colours are deterministic; narrative is AI. |
| `occasions` | `OccasionsSection` | AI | |
| `hardware` | `HardwareSection` | D + AI | Lists are deterministic; text is AI. |
| `code` | `CodeSection` | D | Fully deterministic. |
| `accessory` | `AccessorySection` | AI | |
| `pattern` | `PatternSection` | D + AI | Lists are deterministic; narrative/tip are AI. |
| `generatedAt` | `Date` | M | ISO 8601 timestamp. |
| `engineVersion` | `String` | M | Semantic version, e.g. `"1.0.0"`. |

### `BlueprintUserInfo`

| Field | Type | Source |
|-------|------|--------|
| `birthDate` | `Date` | U |
| `birthLocation` | `String` | U |
| `generationDate` | `Date` | M |

### `StyleCoreSection`

| Field | Type | Source | Cache Key |
|-------|------|--------|-----------|
| `narrativeText` | `String` | AI | `style_core` |

### `TexturesSection`

| Field | Type | Source | Cache Key |
|-------|------|--------|-----------|
| `goodText` | `String` | AI | `textures_good` |
| `badText` | `String` | AI | `textures_bad` |
| `sweetSpotText` | `String` | AI | `textures_sweet_spot` |

### `PaletteSection`

| Field | Type | Source | Cache Key |
|-------|------|--------|-----------|
| `coreColours` | `[BlueprintColour]` | D | — |
| `accentColours` | `[BlueprintColour]` | D | — |
| `narrativeText` | `String` | AI | `palette_narrative` |

### `BlueprintColour`

| Field | Type | Source |
|-------|------|--------|
| `name` | `String` | D |
| `hexValue` | `String` | D |
| `role` | `ColourRole` | D |

### `OccasionsSection`

| Field | Type | Source | Cache Key |
|-------|------|--------|-----------|
| `workText` | `String` | AI | `occasions_work` |
| `intimateText` | `String` | AI | `occasions_intimate` |
| `dailyText` | `String` | AI | `occasions_daily` |

### `HardwareSection`

| Field | Type | Source | Cache Key |
|-------|------|--------|-----------|
| `metalsText` | `String` | AI | `hardware_metals` |
| `stonesText` | `String` | AI | `hardware_stones` |
| `tipText` | `String` | AI | `hardware_tip` |
| `recommendedMetals` | `[String]` | D | — |
| `recommendedStones` | `[String]` | D | — |

### `CodeSection`

| Field | Type | Source |
|-------|------|--------|
| `leanInto` | `[String]` | D |
| `avoid` | `[String]` | D |
| `consider` | `[String]` | D |

### `AccessorySection`

| Field | Type | Source | Cache Keys |
|-------|------|--------|------------|
| `paragraphs` | `[String]` | AI | `accessory_1`, `accessory_2`, `accessory_3` |

### `PatternSection`

| Field | Type | Source | Cache Key |
|-------|------|--------|-----------|
| `narrativeText` | `String` | AI | `pattern_narrative` |
| `tipText` | `String` | AI | `pattern_tip` |
| `recommendedPatterns` | `[String]` | D | — |
| `avoidPatterns` | `[String]` | D | — |

---

## Narrative Cache Key → Struct Field Mapping

This table shows exactly how each `BlueprintSection` raw value (used as the JSON
key in `blueprint_narrative_cache.json`) maps to a field on the corresponding
section struct.

| `BlueprintSection` Raw Value | Section Struct | Target Field |
|------------------------------|----------------|--------------|
| `style_core` | `StyleCoreSection` | `.narrativeText` |
| `textures_good` | `TexturesSection` | `.goodText` |
| `textures_bad` | `TexturesSection` | `.badText` |
| `textures_sweet_spot` | `TexturesSection` | `.sweetSpotText` |
| `palette_narrative` | `PaletteSection` | `.narrativeText` |
| `occasions_work` | `OccasionsSection` | `.workText` |
| `occasions_intimate` | `OccasionsSection` | `.intimateText` |
| `occasions_daily` | `OccasionsSection` | `.dailyText` |
| `hardware_metals` | `HardwareSection` | `.metalsText` |
| `hardware_stones` | `HardwareSection` | `.stonesText` |
| `hardware_tip` | `HardwareSection` | `.tipText` |
| `accessory_1` | `AccessorySection` | `.paragraphs[0]` |
| `accessory_2` | `AccessorySection` | `.paragraphs[1]` |
| `accessory_3` | `AccessorySection` | `.paragraphs[2]` |
| `pattern_narrative` | `PatternSection` | `.narrativeText` |
| `pattern_tip` | `PatternSection` | `.tipText` |

---

## `BlueprintToken.TokenCategory` → Section Mapping

| Token Category | Feeds Section(s) |
|----------------|-------------------|
| `texture` | `TexturesSection` |
| `colour` | `PaletteSection` |
| `silhouette` | `OccasionsSection`, `CodeSection` |
| `metal` | `HardwareSection` (metals) |
| `stone` | `HardwareSection` (stones) |
| `pattern` | `PatternSection` |
| `accessory` | `AccessorySection` |
| `mood` | `StyleCoreSection`, `OccasionsSection` |
| `structure` | `CodeSection`, `TexturesSection` |
| `expression` | `StyleCoreSection` |
