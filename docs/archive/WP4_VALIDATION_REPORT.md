# WP4 Validation Report

> **Date:** 2026-04-10
> **Artifact:** `astrological_style_dataset.json` (298 KB)
> **Validated against:** `docs/fixtures/dataset_schema_checklist.md`, WP3 consumer code

> **Related programme (2026):** the Palette Rework programme may require minor
> additive dataset changes (see [`palette_engine_rework_spec_v1.md`](palette_engine_rework_spec_v1.md)
> §6.5 and §8). Specifically, it may introduce an optional `fallback_palette_pool`
> key used only when chart-derived selection underflows. Existing validations in
> this report remain valid; new checks will be added if Phase A ships with the
> dataset change. See also [`repo_rename_spec_v1.md`](repo_rename_spec_v1.md)
> and [`palette_grid_spec_v1.md`](palette_grid_spec_v1.md).

---

## Validation Results

| Check | Result | Details |
|-------|--------|---------|
| Top-level sections (5) | PASS | `planet_sign`, `aspects`, `house_placements`, `element_balance`, `colour_library` |
| `planet_sign` cardinality | PASS | 132 entries (11 bodies × 12 signs) |
| `planet_sign` required fields | PASS | All 132 entries have all 12 required fields |
| `planet_sign` opposites | PASS | All 132 entries have `opposites.{textures, colours, silhouettes, mood}` |
| `aspects` count | PASS | 30 entries |
| `aspects` priority pairs | PASS | All 10 priority aspect pairs covered |
| `aspects` required fields | PASS | All entries have `effect`, `texture_modifier`, `colour_modifier`, `code_addition_leaninto`, `code_addition_avoid` |
| `house_placements` cardinality | PASS | 48 entries (4 planets × 12 houses) |
| `house_placements` required fields | PASS | All entries have `context` and `modifier` |
| `element_balance` count | PASS | 7 entries (4 element + 3 modality) |
| `element_balance` required fields | PASS | All entries have `overall_energy`, `palette_bias`, `texture_bias` |
| `colour_library` count | PASS | 162 entries (minimum 60) |
| `colour_library` hex format | PASS | All hex values match `#[0-9A-Fa-f]{6}` |
| `colour_library` associations | PASS | All entries have non-empty associations |
| Colour cross-reference | PASS | Every colour name in `planet_sign` primary/accent arrays has a matching `colour_library` entry |
| Key naming conventions | PASS | All `planet_sign` keys are `<body>_<sign>` lowercase |
| Aspect key format | PASS | All keys match `<planet1>_<aspect>_<planet2>` lowercase |
| House key format | PASS | All keys match `<planet>_house_<N>` |
| WP3 Codable compatibility | PASS | JSON structure matches `AstrologicalStyleDataset` struct in `BlueprintTokenGenerator.swift` |
| Backfill script integration | PASS | `describe_archetype()` in `backfill_narratives.py` correctly reads all dataset fields |

### Astrological Spot Checks

| Check | Result |
|-------|--------|
| Venus in Taurus → luxurious textures, earth tones, quality focus | PASS |
| Venus in Scorpio → dark palettes, power dressing, concealment | PASS |
| Moon in Cancer → comfort fabrics, nostalgic pieces, protective layering | PASS |
| Mars in Aries → athletic cuts, bold colours, decisive silhouettes | PASS |
| Saturn in Capricorn → structured tailoring, dark neutrals, investment pieces | PASS |

---

## Data Richness Tiers

Per spec requirements:

| Body | Entries | Detail Level | Notes |
|------|---------|-------------|-------|
| Venus | 12 | **Most detail** | 5-6 good textures, 2-3 primary colours, 2 accent colours, full philosophy |
| Moon | 12 | **High detail** | 4-5 good textures, 2 primary colours, full emotional philosophy |
| Sun | 12 | **Good detail** | 4-5 good textures, 2 primary colours, identity-focused philosophy |
| Mars | 12 | **Moderate detail** | 3 good textures, 2 primary colours, energy-focused |
| Ascendant | 12 | **Moderate detail** | 3 good textures, 1-2 primary colours, presentation-focused |
| Saturn | 12 | **Moderate detail** | 2-3 good textures, 1-2 primary colours, discipline-focused |
| Jupiter | 12 | **Light detail** | 2 good textures, 1 primary colour, expansion-focused |
| Mercury | 12 | **Light detail** | 2 good textures, 1 primary colour, communication-focused |
| Uranus | 12 | **Light detail** | 2 good textures, 1 primary colour, innovation-focused |
| Neptune | 12 | **Light detail** | 2-3 good textures, 1 primary colour, dream-focused |
| Pluto | 12 | **Light detail** | 2-3 good textures, 1 primary colour, transformation-focused |

---

## WP3 Consumer Contract Compatibility

### BlueprintTokenGenerator

- `AstrologicalStyleDataset` Codable struct: all CodingKeys match JSON snake_case keys exactly
- `PlanetSignEntry` struct: all fields populated for all 132 entries
- `AspectEntry` struct: all fields populated for all 30 entries
- `HousePlacementEntry` struct: all fields populated for all 48 entries
- `ElementBalanceEntry` struct: all fields populated for all 7 entries
- `ColourLibraryEntry` struct: all fields populated for all 162 entries
- Dataset loads via `loadDataset(from:)` by filename `astrological_style_dataset`

### DeterministicResolver

- **Palette**: colour names in dataset entries have matching `colour_library` entries with hex values for `resolvePalette()` to look up
- **Hardware**: all `metals` and `stones` arrays are non-empty for all 132 entries
- **Code**: all `code_leaninto`, `code_avoid`, `code_consider` arrays are non-empty for all 132 entries
- **Patterns**: all `patterns.recommended` and `patterns.avoid` arrays are non-empty for all 132 entries
- **Anti-tokens**: all `opposites.mood` arrays are non-empty for all 132 entries (used by `resolveCode()` for avoid generation)

### ArchetypeKeyGenerator / backfill_narratives.py

- All Venus sign entries (`venus_<sign>`) exist: 12/12
- All Moon sign entries (`moon_<sign>`) exist: 12/12
- All element balance entries (`<element>_dominant`) exist: 4/4
- `describe_archetype()` resolves all three key components correctly from the dataset

---

## Frozen Contract Compliance

| Constraint | Status |
|-----------|--------|
| No WP2 field additions/removals/renames | COMPLIANT — no changes to `BlueprintModels.swift` |
| No WP3 consumer code changes | COMPLIANT — no changes to any WP3 engine files |
| 16 `BlueprintSection.rawValue` strings respected | COMPLIANT — not touched |
| `NatalChart.planets` is array, not dictionary | N/A — WP4 does not touch NatalChart |
| No legacy type reuse (`StyleToken`, `InterpretationResult`) | COMPLIANT |

---

## Assumptions and Design Decisions

1. **Outer planet entries use an abbreviated constructor.** Jupiter, Mercury, Uranus, Neptune, and Pluto entries have lighter detail with a single `bad` texture placeholder ("overworked or gimmicky fabrics") and empty accent colour arrays. This is intentional per the spec's data richness tiering. WP3's fallback logic handles sparse entries gracefully.

2. **Colour library exceeds 80 entries (162 vs 60-80 target).** This ensures full coverage for all colour names referenced across 132 planet-sign entries. The extra entries add no cost at runtime since `DeterministicResolver` only looks up colours it encounters in tokens.

3. **Aspect entries cover all 5 major aspect types for the Venus-Saturn pair** (conjunction, square, trine, opposition, sextile) and at least one aspect type for all other priority pairs. Total of 30 entries. WP3's `resolveCode()` constructs keys as `<planet1>_<aspectType>_<planet2>` all lowercased from `ChartAspect`, so our keys match this format exactly.

4. **House placement modifier strings are deliberately concise.** They serve as contextual annotations for WP3's house-context logic, not as full prose. The current WP3 code does not actively consume house placements in the deterministic resolver, but the data is available for future integration per the spec.

5. **Opposites fields are populated for all 132 entries.** Currently WP3's `resolveCode()` only reads `opposites.mood` for anti-token generation. The `opposites.textures`, `.colours`, and `.silhouettes` fields are populated as required by the schema checklist for future deterministic resolver expansion.

6. **Array ordering is intentional.** In Venus, Moon, Sun, Mars, and Ascendant entries, `textures.good`, `colours.primary`, `metals`, `stones`, `patterns.recommended`, `code_leaninto`, etc. are ordered by relevance/prominence. WP3 uses stable ordering for tie-breaking, so the first items in each array carry implicit priority.

7. **No DeterministicResolver fallback changes needed.** The current fallback fill behaviour (placeholder strings like "(see Blueprint for details)") is acceptable. The dataset provides sufficient coverage (non-empty arrays for all required fields on all entries) that fallbacks should rarely trigger in practice.

---

## Files Delivered

| File | Purpose |
|------|---------|
| `astrological_style_dataset.json` | Complete WP4 dataset (production artifact) |
| `generate_dataset.py` | Dataset generation script (developer tool, not a runtime dependency) |
| `validate_dataset.py` | Dataset validation script (developer tool) |
| `docs/WP4_VALIDATION_REPORT.md` | This report |

---

## No Fixture Changes Required

The WP4 dataset introduces no changes to:
- `docs/fixtures/blueprint_input_user_1.json`
- `docs/fixtures/blueprint_input_user_2.json`
- `docs/fixtures/blueprint_expected_shape_checklist.md`
- `docs/fixtures/dataset_schema_checklist.md`
