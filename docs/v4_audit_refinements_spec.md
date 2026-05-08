# V4 Audit Refinements — Implementation Spec

**Date**: 2026-04-20
**Depends on**: V4 100-User Audit (complete, `docs/v4_100_user_audit_handoff.md`)
**Scope**: Two product refinements surfaced by the double audit. No classification, scoring, or variation logic changes.

---

## 1. Background

The 100-user audit and its independent review confirmed the V4 colour palette engine is production-ready:

- Family classification: 100/100.
- All regression gates: passing.
- Off-white coverage: 100/100.
- Per-user variation: active and working as specified.

Two product refinements were surfaced:

| # | Refinement | Decision |
|---|-----------|----------|
| R1 | Add literal "black" swatch for winter-compressed Deep Autumn users | **Yes — implement** |
| R2 | Shift Soft Autumn's light anchor from "oatmeal" to a lighter colour | **Yes — implement** |

---

## 2. R1 — Literal Black for Winter-Compressed Deep Autumn

### 2.1 Problem

Deep Autumn's deepest swatches are "ink brown" (`#2B1E15`, L\* ~14) and "espresso" (`#3C2415`, L\* ~16). The ink brown hex was corrected from `#0A0603` (L\* ~3, indistinguishable from black) to a visible warm off-black. For users with `winterCompressionApplied = true` — whose charts push toward Deep Winter's cold, inky edge — a literal black swatch is warranted. The three Winter families already carry "black" (`#0A0A0A`) in their templates; DA with winter compression sits on the boundary.

### 2.2 Which users are affected

Only Deep Autumn users where `overrideFlags.winterCompressionApplied == true`. From the audit dataset, this is a subset of the 20 DA rows. Other families are unaffected:

- Deep/True/Bright Winter already have literal "black" (18/100 in the audit).
- Bright Spring has "clear black" (`#0D1014`) — functionally black, different name by design (warm-neutral tone).
- True Autumn's deepest is "espresso" — literal black doesn't belong in a warm earthy family without winter compression.
- Light, Soft, True Spring/Summer families are too light/muted for any black swatch — by design.

### 2.3 Approach: conditional deep-anchor override

Override the `deepAnchor` from "ink brown" to "black" when `winterCompressionApplied == true` for Deep Autumn users. This is the cleanest mechanism because:

1. The deep anchor is the swatch that represents the user's darkest foundation. For winter-compressed DA, "black" is a better foundation name than "ink brown."
2. The anchor lives outside the variation slot system (it's not in neutrals/core/accent/support), so this doesn't interfere with `VariationSlots.apply`.
3. Anchors are currently family-determined and pull-invariant. This refinement adds a single flag-gated exception for DA only — a targeted, traceable change.
4. "Ink brown" (`#2B1E15`) is now a visible warm off-black (L\* ~14), clearly distinct from "black" (`#0A0A0A`, L\* ~4). The override gives winter-compressed DA users true black while non-compressed DA keeps the warm deep brown.

Non-winter-compressed DA users (like Maria) keep "ink brown" as their deep anchor — their palette stays purely warm with no winter edge.

### 2.4 Code changes

#### `ColourEngine.swift` — new step between current steps 11 and 12

After variation is applied (step 11) and before the trace is assembled (step 12), add a conditional anchor override:

```swift
// 11b. Deep Autumn winter-compression anchor override
var finalPalette = palette
if family == .deepAutumn && flags.winterCompressionApplied {
    finalPalette = PaletteTriadV4(
        neutrals: palette.neutrals,
        coreColours: palette.coreColours,
        accentColours: palette.accentColours,
        supportColours: palette.supportColours,
        lightAnchor: palette.lightAnchor,
        deepAnchor: "black"
    )
}
```

Then use `finalPalette` (instead of `palette`) in the `ColourEngineResult` constructor.

#### `PaletteLibrary.swift` — no change to the base template

Deep Autumn's base template keeps `deepAnchor: "ink brown"`. The override is applied conditionally in the engine pipeline, not in the library. This preserves the library as a pure family-level lookup.

"Black" (`#0A0A0A`) is already in `colourNameToHex` (from the Deep Winter template), so no new colour entry is needed.

### 2.5 Trace impact

Add a new field to `OverrideFlags` or annotate the trace so the anchor override is visible in diagnostics:

```swift
struct OverrideFlags: Codable, Equatable {
    // ... existing flags ...
    var deepAnchorOverriddenToBlack: Bool = false
}
```

Set this flag to `true` when the override fires. The audit harness can then report which users got the override.

### 2.6 Alternatively: keep `OverrideFlags` unchanged

If adding a new flag feels heavy for a single-line override, the trace already carries `winterCompressionApplied` + `family == .deepAutumn`, from which the override can be inferred. The new flag is optional — include it if the implementer judges it aids debuggability, omit if not.

---

## 3. R2 — Lighter Anchor for Soft Autumn

### 3.1 Problem

Soft Autumn's light anchor is "oatmeal" (`#D2C6B2`, L\* ~83). In the audit, all 9 Soft Autumn rows missed the very-light threshold (L\* >= 88). While the threshold is arbitrary, "oatmeal" reads as a mid-light neutral, not an off-white. A lighter anchor gives SA users a visible light-to-dark range that parallels what other families get from their light anchors.

### 3.2 Approach: change SA light anchor to "bone"

Replace `lightAnchor: "oatmeal"` with `lightAnchor: "bone"` in the Soft Autumn template.

"Bone" (`#EFE6D3`, L\* ~92) is already in `colourNameToHex` (defined in the V4.3 universal anchors section). It's warm-toned, which matches SA's temperature profile. It's lighter than "warm cream" (`#F2E8D4`, L\* ~93) but both work — "bone" is slightly more muted, which suits Soft Autumn's low-saturation character.

### 3.3 Code change

#### `PaletteLibrary.swift` — single-line edit

```swift
// Before:
.softAutumn: PaletteTriadV4(
    neutrals: ["camel", "warm taupe", "oatmeal", "olive beige"],
    coreColours: ["terracotta", "olive sage", "muted teal", "soft rust"],
    accentColours: ["antique gold", "soft copper", "moss green", "muted amber"],
    lightAnchor: "oatmeal",
    deepAnchor: "bitter chocolate"
),

// After:
.softAutumn: PaletteTriadV4(
    neutrals: ["camel", "warm taupe", "oatmeal", "olive beige"],
    coreColours: ["terracotta", "olive sage", "muted teal", "soft rust"],
    accentColours: ["antique gold", "soft copper", "moss green", "muted amber"],
    lightAnchor: "bone",
    deepAnchor: "bitter chocolate"
),
```

"Oatmeal" stays in `neutrals[2]` — it's still an important SA colour. Only the light anchor slot changes.

### 3.4 No other files changed

The light anchor flows through the existing pipeline without any conditional logic. `ColourEngine.evaluate()` already reads `lightAnchor` from the `PaletteTriadV4` returned by `PaletteLibrary.palette(for:)`. No engine, variation, or domain changes are needed.

---

## 4. Test Updates

### 4.1 `MariaAshLocked_Tests.swift`

#### Ash anchor test — update expected deep anchor

Ash is Deep Autumn with `winterCompressionApplied = true`, so after R1 his deep anchor changes.

```swift
// Before:
func testAshHasDeepAutumnAnchors() throws {
    let result = ColourEngine.evaluateStrict(input: try ashInput)
    XCTAssertEqual(result.palette.lightAnchor, "warm cream", ...)
    XCTAssertEqual(result.palette.deepAnchor, "ink brown", ...)
}

// After:
func testAshHasDeepAutumnAnchors() throws {
    let result = ColourEngine.evaluateStrict(input: try ashInput)
    XCTAssertEqual(result.palette.lightAnchor, "warm cream",
        "Ash lightAnchor should be 'warm cream' for Deep Autumn")
    XCTAssertEqual(result.palette.deepAnchor, "black",
        "Ash deepAnchor should be 'black' — winter-compressed DA override")
}
```

#### Maria anchor test — unchanged

Maria is Deep Autumn without winter compression, so her deep anchor stays "ink brown." The existing test needs no changes.

#### Shared anchor test — update

`testAshAndMariaShareAnchors` currently asserts both users share both anchors. After R1, they share `lightAnchor` but differ on `deepAnchor`:

```swift
// Before:
func testAshAndMariaShareAnchors() throws {
    // ... asserts both lightAnchor and deepAnchor are equal
}

// After:
func testAshAndMariaShareAnchors() throws {
    let ashResult = ColourEngine.evaluateStrict(input: try ashInput)
    let mariaResult = ColourEngine.evaluateStrict(input: try mariaInput)
    XCTAssertEqual(ashResult.palette.lightAnchor, mariaResult.palette.lightAnchor,
        "Same-family users must share the lightAnchor (foundation invariance)")
    XCTAssertNotEqual(ashResult.palette.deepAnchor, mariaResult.palette.deepAnchor,
        "Winter-compressed DA (Ash) gets 'black'; non-compressed DA (Maria) keeps 'ink brown'")
}
```

#### New test — winter-compression anchor override

```swift
func testWinterCompressedDAGetsBlackDeepAnchor() throws {
    let result = ColourEngine.evaluateStrict(input: try ashInput)
    XCTAssertTrue(result.trace.overrideFlags.winterCompressionApplied)
    XCTAssertEqual(result.palette.deepAnchor, "black",
        "Deep Autumn + winterCompressionApplied → deepAnchor must be 'black'")
}

func testNonCompressedDAKeepsInkBrownDeepAnchor() throws {
    let result = ColourEngine.evaluateStrict(input: try mariaInput)
    XCTAssertFalse(result.trace.overrideFlags.winterCompressionApplied)
    XCTAssertEqual(result.palette.deepAnchor, "ink brown",
        "Deep Autumn without winter compression keeps 'ink brown'")
}
```

### 4.2 `V4CalibrationRegression_Tests.swift`

The palette gate expectations for DA rows with winter compression will change (deepAnchor "ink brown" → "black"). All SA rows' light anchors will change ("oatmeal" → "bone").

Regenerate with `REGENERATE_V4_PALETTE_EXPECTATIONS=1`.

The **classification gate** (family, variables, cluster) is completely unaffected — neither change touches scoring or classification.

### 4.3 `V4ReferenceAudit_Tests.swift`

No code changes needed in the audit harness — it reads the engine output as-is. After R1+R2 the audit report numbers will improve:

| Metric | Before | After (expected) |
|--------|--------|-------------------|
| Literal black swatch | 18/100 | 18 + (DA rows with winterCompression) |
| Near-black swatch | 53/100 | No change (already counted) |
| Very-light swatch | 91/100 | 100/100 (all 9 SA rows gain "bone" at L\* ~92) |
| Named off-white | 100/100 | 100/100 (unchanged) |

### 4.4 `PaletteGridViewModel_Tests.swift`

Golden snapshots for user 1 and user 2 will need regeneration if either user is DA-with-compression or SA. Regenerate with `REGENERATE_PALETTE_GRID_GOLDENS=1`.

### 4.5 `VariationSlots_Tests.swift`

No changes. Variation logic is unaffected — both refinements operate outside the substitution map.

### 4.6 `ChartSignatureResolver_Tests.swift`

No changes. Chart signatures are independent of anchors and light/dark template changes.

---

## 5. Fixture Regeneration Checklist

After both code changes are in place:

| Step | Command / action | Fixture updated |
|------|-----------------|-----------------|
| 1 | `REGENERATE_V4_PALETTE_EXPECTATIONS=1` → run `V4CalibrationRegression_Tests` | `docs/fixtures/v4_dataset.json` (palette expectations for affected rows) |
| 2 | `REGENERATE_PALETTE_GRID_GOLDENS=1` → run `PaletteGridViewModel_Tests` | `docs/fixtures/palette_grid_golden_user_1.json`, `palette_grid_golden_user_2.json` |
| 3 | Run `V4ReferenceAudit_Tests` (no env var needed) | `docs/fixtures/v4_markdown_reference_audit.json`, `v4_markdown_reference_audit.md` |
| 4 | Unset env vars, run full test suite | All green |

---

## 6. Files Changed (complete list)

| File | Change | Refinement |
|------|--------|-----------|
| `ColourEngineV4/ColourEngine.swift` | Add conditional deepAnchor override for winter-compressed DA | R1 |
| `ColourEngineV4/PaletteLibrary.swift` | Change SA `lightAnchor` from "oatmeal" to "bone" | R2 |
| `ColourEngineV4/Domain.swift` | *(Optional)* Add `deepAnchorOverriddenToBlack` to `OverrideFlags` | R1 |
| `Cosmic FitTests/MariaAshLocked_Tests.swift` | Update Ash anchor assertions, update shared-anchor test, add compression-gated tests | R1 |
| `Cosmic FitTests/V4CalibrationRegression_Tests.swift` | Regenerate palette expectations | R1 + R2 |
| `Cosmic FitTests/PaletteGridViewModel_Tests.swift` | Regenerate golden snapshots | R1 + R2 |

---

## 7. Files NOT Changed

Explicit non-goals — do not touch:

| Area | Files |
|------|-------|
| Classification / scoring | `FamilyMapping.swift`, `Scoring.swift`, `Modifiers.swift`, `Thresholds.swift`, `Overrides.swift` |
| Variation logic | `VariationSlots.swift` |
| Chart signatures | `ChartSignatureResolver.swift` |
| Secondary pull derivation | `SecondaryPull.swift` |
| Support palette templates | `PaletteLibrary.supportLibrary` |
| Base palette colours (except SA lightAnchor) | `PaletteLibrary.library` neutrals/core/accent bands |
| UI layer | `PaletteGrid.swift`, `PaletteGridViewModel.swift`, `ColourPaletteView.swift`, `StyleGuideViewController.swift` |
| Blueprint models | `BlueprintModels.swift`, `BlueprintComposer.swift` |
| Narrative / daily palette | `DailyColourPaletteGenerator.swift`, `blueprint_narrative_cache.json` |
| Colour name-to-hex map | No new entries needed — both "black" and "bone" are already defined |

---

## 8. Acceptance Criteria

1. **Ash gets literal "black"**: `ColourEngine.evaluateStrict(input: ashInput).palette.deepAnchor == "black"`.
2. **Maria keeps "ink brown"**: `ColourEngine.evaluateStrict(input: mariaInput).palette.deepAnchor == "ink brown"`.
3. **Soft Autumn gets "bone"**: `PaletteLibrary.palette(for: .softAutumn).lightAnchor == "bone"`.
4. **Classification untouched**: V4 regression classification gate remains 100/100.
5. **All existing tests pass** after fixture regeneration.
6. **Audit report improves**: very-light swatch count moves from 91/100 to 100/100; literal-black count increases.
7. **No new colours added to `colourNameToHex`** — both "black" and "bone" are already present.

---

## 9. Implementation Order

1. Apply R2 first (single-line change in `PaletteLibrary.swift`) — it has zero downstream code dependencies.
2. Apply R1 (conditional override in `ColourEngine.swift`, optional flag in `Domain.swift`).
3. Update `MariaAshLocked_Tests.swift` assertions.
4. Regenerate `v4_dataset.json` expectations.
5. Regenerate palette grid goldens.
6. Rerun the audit to confirm improved numbers.
7. Run full test suite — all green before handing back.
