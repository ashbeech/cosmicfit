# WP2 Handoff Notes

> For the AI developers handling WP3, WP4, and WP5.
> Read this alongside `BLUEPRINT_REBUILD_SPEC_v2.3.md`.

---

## 1. What Is Now Frozen

`Cosmic Fit/InterpretationEngine/BlueprintModels.swift` is the **frozen WP2
contract**. It contains:

- `CosmicBlueprint` (root struct, 8 sections + metadata)
- `BlueprintUserInfo`, `StyleCoreSection`, `TexturesSection`, `PaletteSection`,
  `BlueprintColour`, `ColourRole`, `OccasionsSection`, `HardwareSection`,
  `CodeSection`, `AccessorySection`, `PatternSection`
- `BlueprintToken` with `TokenCategory` enum (10 cases)
- `BlueprintArchetypeKey` with `BlueprintSection` enum (16 cases)

**Do not add, remove, or rename fields** without filing a cross-WP blocking note.
All types conform to `Codable` and `Equatable`. The file compiles standalone with
Foundation only — no dependencies on any other codebase file.

---

## 1a. Active Programme — Palette Rework (2026)

The Palette Rework programme is an additive, explicitly scoped set of changes
to `BlueprintToken`, `BlueprintColour`, and `DeterministicResolver.resolvePalette`.
It preserves WP2 determinism and adds fields for astrological provenance.

Three companion hand-off specs define the work:

- **Phase 0** — [`repo_rename_spec_v1.md`](repo_rename_spec_v1.md) — rename this
  directory from `_reference/` to `docs/`. Mechanical sweep; no engine work.
- **Phase A** — [`palette_engine_rework_spec_v1.md`](palette_engine_rework_spec_v1.md)
  — token-layer + resolver rework for astrological fit. Adds `sourceColourRole`
  on `BlueprintToken` and `provenance` on `BlueprintColour`. Grows `accentColours`
  from 2 to 4. Full narrative cache regeneration.
- **Phase B** — [`palette_grid_spec_v1.md`](palette_grid_spec_v1.md) — 5×8
  Personal Palette Grid UI component in `Cosmic Fit/UI/Views/Palette/`. Consumes
  Phase A output; does not touch the engine.

Dependency chain: **0 → A → B**. Each spec declares its prerequisites explicitly
and must not be started early.

After Phase 0 merges, all three specs live at `docs/*.md`.

---

## 2. Keys That Must Not Change

### `BlueprintSection` raw values (16 canonical JSON keys)

These are the keys used in `blueprint_narrative_cache.json`:

```
style_core, textures_good, textures_bad, textures_sweet_spot,
palette_narrative, occasions_work, occasions_intimate, occasions_daily,
hardware_metals, hardware_stones, hardware_tip,
accessory_1, accessory_2, accessory_3,
pattern_narrative, pattern_tip
```

Access them via `section.rawValue` in Swift. No mapping table needed.

### `TokenCategory` raw values (10 canonical category identifiers)

```
texture, colour, silhouette, metal, stone,
pattern, accessory, mood, structure, expression
```

WP4 dataset entries should produce tokens whose categories map to these values.

### `ColourRole` raw values

```
core, accent, statement
```

---

## 3. Where Fixtures Live

| File | Purpose |
|------|---------|
| `_reference/fixtures/blueprint_input_user_1.json` | Ash example — shape-validation fixture |
| `_reference/fixtures/blueprint_input_user_2.json` | Maria example — shape-validation fixture |
| `_reference/fixtures/blueprint_expected_shape_checklist.md` | Every required field, type, and constraint |
| `_reference/fixtures/dataset_schema_checklist.md` | WP4 dataset structure requirements |
| `_reference/fixtures/CHANGELOG.md` | Fixture change log |

**Fixture rules (from spec §D):**
- All WPs must validate against the same fixture files.
- No WP may create a private fixture variant with divergent field names.
- Fixture updates require a CHANGELOG entry.

**Important:** The colour hex values in the fixtures are synthetic (derived from
the prose in `_reference/blueprint_examples.md`). They validate JSON shape, not
engine output correctness.

---

## 4. What the Narrative Cache Must Match

Each archetype cluster entry in `blueprint_narrative_cache.json` must contain all
16 `BlueprintSection` keys. The mapping from cache key to struct field:

| Cache Key | Target | Field |
|-----------|--------|-------|
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

Full detail: `_reference/blueprint_model_field_sources.md`.

---

## 5. NatalChart Shape Notes (from WP1)

These are critical for WP3's `ChartAnalyser`:

- **`NatalChart.planets`** is `[PlanetPosition]` (an array), NOT a keyed
  dictionary. Planet lookup is by iterating and checking `.name`.
- **`ascendant`** is a separate `Double` property on `NatalChart`. It is NOT
  included in the `planets` array.
- **`AstronomicalCalculator.calculateAspect(point1:point2:orb:)`** returns
  `(aspectType: String, exactness: Double)?`. This is the natal-aspect utility
  WP3 should adapt for natal-natal aspect detection.
- WP3 must compute **natal-natal aspects** (planets within the birth chart), NOT
  transit aspects. Do NOT call `NatalChartCalculator.calculateTransits()`.

---

## 6. What Remains Legacy — Do Not Reuse

| Type | Status |
|------|--------|
| `StyleToken` | Legacy. `BlueprintToken` is the new contract. |
| `InterpretationResult` | Legacy. `CosmicBlueprint` is the new output type. |
| `InterpretationTextLibraryShim.swift` | Temporary compile-only shim for Daily Fit. Delete once `SemanticTokenGenerator` / `DailyVibeGenerator` dependency is removed. |
| `_archive/extracted_planet_sign_token_tables.json` | WP4 starting point only. Not a runtime dependency. |
| All types in `_archive/` | Dead code kept for reference. |

---

## 7. What the Review Tool Spec Defines

`_reference/narrative_review_tool_spec.md` specifies:

- The exact JSON schema for `blueprint_narrative_cache.json`
- The exact JSON schema for `review_notes.json`
- Paragraph validation rules (word count, banned words, style markers)
- Tool UX requirements (dark theme, keyboard shortcuts, pipeline halt)
- Integration contract between the backfill script and the review tool

**WP3 owns building and running the tool.** WP2 owns only the interface spec.

---

## 8. Deterministic vs AI Fields — Quick Reference

| Source | Fields |
|--------|--------|
| **Deterministic** (WP3 resolver + WP4 dataset) | `PaletteSection.coreColours/accentColours`, `HardwareSection.recommendedMetals/recommendedStones`, `CodeSection.leanInto/avoid/consider`, `PatternSection.recommendedPatterns/avoidPatterns` |
| **AI-generated** (narrative cache lookup) | All `*Text`, `narrativeText`, and `paragraphs` fields |
| **User passthrough** | `BlueprintUserInfo.birthDate`, `.birthLocation` |
| **Runtime metadata** | `BlueprintUserInfo.generationDate`, `generatedAt`, `engineVersion` |

---

## 9. Round-Trip Tests

`Cosmic FitTests/Cosmic_FitTests.swift` contains fixture-driven validation tests:

- Decode/encode round-trip for both user fixtures
- Shape completeness (all required fields present and non-empty)
- No silent empty strings in list fields
- Hex value format validation
- `BlueprintSection` canonical key assertions (16 cases, all snake_case)
- `TokenCategory` assertions (10 cases, all lowercase single-word)
- `ColourRole` assertions (3 cases)
- `BlueprintToken` and `BlueprintArchetypeKey` encode/decode round-trips

**These tests must stay green through WP3/WP4 integration.** If a contract
change is required, update the fixtures and tests in the same commit.
