# Palette Grid 4x4 Refactor — Developer Handoff

**Date**: 2026-04-20
**Owner**: Ash
**Plan**: `.cursor/plans/palette_grid_4x4_refactor_147998dc.plan.md`
**Related**: [`docs/archive/palette_grid_spec_v1.md`](archive/palette_grid_spec_v1.md) (previous 5x16 spec — now superseded for the UI layer)

---

## 1. Goal

Replace the current **5-column × 16-row tonal-expansion palette grid** with a clean **4×4 grid of single-colour swatches**. Each of the 16 anchor colours the engine selects is displayed exactly once (no tonal expansion). Swatches are arranged in reading order, **sorted by hue proximity**, so visually similar colours sit next to each other (e.g. petrol → teal → forest green, or red → orange → yellow).

This is a **UI-layer refactor only**. The ColourEngineV4 selection logic, `VariationSlots` substitutions, `PaletteLibrary`, `PaletteSection`, and every file under `ColourEngineV4/` stay exactly as they are.

---

## 2. Current state (what exists today)

### 2.1 Data flow

```
PaletteSection (up to 4 neutral + 4 core + 4 accent + 4 support BlueprintColours)
        │
        ▼
PaletteGridViewModel.build(from:)
        │  (expands each anchor to 5 tonal variants via ColourMath.tonalOffsets)
        ▼
PaletteGrid                   ← 5 columns × 16 rows, banded by role
        │
        ▼
ColourPaletteView             ← UICollectionView, 16 sections × 5 items
                                 + section headers ("Neutral Colours", etc.)
```

### 2.2 Tonal expansion (the bit to rip out)

[`PaletteGridViewModel.swift`](../Cosmic Fit/UI/Views/Palette/PaletteGridViewModel.swift#L96-L111) expands each anchor hex to 5 tones via `ColourMath.tonalOffsets = [+0.30, +0.15, 0.0, −0.15, −0.30]` applied to L in HSL space. The **centre column (toneIndex 2, offset 0.0)** is effectively the anchor hex round-tripped through HSL (within 1 channel unit). This is the "true" tone and is the colour we want to keep.

### 2.3 Current model types

From [`PaletteGrid.swift`](../Cosmic Fit/UI/Views/Palette/PaletteGrid.swift):

```swift
struct PaletteGrid: Equatable {
    let rows: [PaletteRow]
    var hidesEmptyRows: Bool
    static let columnCount = 5
    static let rowCount = 16
    // + neutralRowCount / coreRowCount / accentRowCount / supportRowCount (= 4 each)
}

struct PaletteRow: Equatable {
    let role: ColourRole
    let anchorName: String?
    let anchorHex: String?
    let cells: [PaletteCell]           // exactly 5
}

struct PaletteCell: Equatable {
    enum Kind: Equatable {
        case filled(hex: String)
        case empty
    }
    let kind: Kind
    let toneIndex: Int                 // 0 = lightest, 4 = darkest
}
```

### 2.4 View

[`ColourPaletteView.swift`](../Cosmic Fit/UI/Views/ColourPaletteView.swift) is a `UICollectionView` with:

- 16 sections (one per grid row), each with 5 items
- Per-band section headers (`"Neutral Colours"`, `"Core Colours"`, `"Accent Colours"`, `"Supporting Colours"`)
- Optional dev-only `showsDevelopmentAnchorNames` flag
- Public API: `configure(with grid: PaletteGrid)` and `static func placeholder() -> PaletteGrid`
- Call site: [`StyleGuideViewController.swift:510`](../Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift#L510)

---

## 3. Target state (what to build)

### 3.1 Data flow (new)

```
PaletteSection (same as before: up to 16 BlueprintColours across 4 bands)
        │
        ▼
PaletteGridViewModel.build(from:)
        │  (flattens all bands into one list; no tonal expansion;
        │   sorts by hue proximity; lays into 4×4)
        ▼
PaletteGrid                   ← 4 columns × 4 rows, single-swatch cells
        │
        ▼
ColourPaletteView             ← UICollectionView, 1 section × 16 items
                                 NO band headers
```

### 3.2 Visual spec

| Property | Value |
|---|---|
| Columns | **4** |
| Rows | **4** |
| Total cells | **16** (one swatch per engine-selected anchor colour) |
| Cell shape | Square |
| Cell size | `(availableWidth − 3 × cellSpacing) / 4` |
| Inter-cell spacing | `2 pt` (unchanged) |
| Corner radius | `4 pt` (unchanged, from `ColourCell`) |
| Band headers | **Removed** — no "Neutral Colours"/"Core Colours"/etc. labels |
| Labels on swatches | **None** (production) |
| Dev anchor-name toggle | **Removed** (we no longer have a per-row concept) |
| Scroll | Disabled (parent scroll view owns scrolling, unchanged) |
| Cell tap | None (decorative only, unchanged) |

The grid renders as a perfect square: `4 × cellSize + 3 × cellSpacing` tall and wide. Because the current grid occupies a very tall area (16 rows), the new grid will be dramatically shorter; any surrounding stack/scroll layout will simply reflow around the new intrinsic content size. No changes needed in the parent view controllers.

### 3.3 Colour ordering: hue-proximity sort

All 16 colours (from every band, flattened) are sorted into a single list by hue proximity, then filled into the 4×4 grid in reading order (left-to-right, top-to-bottom). The role/band of each colour no longer affects its position.

**Algorithm** (deterministic, pure function):

```
for each BlueprintColour c in the union of
    section.neutrals ?? [] + section.coreColours + section.accentColours + section.supportColours ?? []:

    parse c.hexValue → (h, s, l)
    if parse fails → bucket = "malformed" (stable terminal bucket)
    else if s < 0.10 → bucket = "achromatic" (near-grey / off-white / black)
    else              → bucket = "chromatic"

sort keys:

    chromatic:   primary = hue (0.0…1.0 starting at red, ascending → orange → yellow → green → cyan → blue → purple → magenta → back to red)
                 secondary = lightness ascending (darker first within same hue)
                 tertiary = original insertion index (stability)

    achromatic:  primary = lightness ascending (darkest grey first)
                 secondary = original insertion index

    malformed:   sort by original insertion index

combined order: [chromatics (sorted)] + [achromatics (sorted)] + [malformed (sorted)]
```

**Why chromatic → achromatic (not the other way round)?** The user asked for "blues to greens, reds to oranges to yellows" — i.e. a flowing hue sequence as the visual headline. Greys and off-whites grouped together at the end form a natural "grounding" terminus without interrupting the chromatic flow.

**Why `s < 0.10` as the achromatic threshold?** Empirically, a HSL saturation under ~0.10 reads as grey/off-white regardless of hue — any `hue` value is noise at that saturation. `0.10` is the round-trip-stable cutoff used elsewhere in this codebase (see `ColourMath.hexToHSL` + `hslToHex` tolerance).

**Why not 2D proximity (nearest-neighbour layout)?** Explicitly rejected by the user in the scoping call — reading-order sort is sufficient and keeps the algorithm trivially deterministic and testable.

**Determinism**: same `PaletteSection` in → byte-identical `PaletteGrid` out. No randomness, no dictionary iteration order dependence. This property must be preserved for the golden snapshot tests to stay meaningful.

### 3.4 Input with fewer than 16 anchors

Per the scoping call, legacy V4.1 data (no support band) is **no longer a concern** — every blueprint going through the app is V4.2 with exactly 16 anchors. However, be defensively robust:

- If the flattened anchor list has **fewer than 16 colours**, fill the remaining trailing cells with `PaletteCell.Kind.empty`.
- If it has **more than 16** (should never happen, but guard against future PaletteSection growth), truncate to the first 16 after sorting.

The `ColourCell.configureEmpty()` path (UIColor.label at 8% alpha) already exists and is reused for empty cells.

---

## 4. File-by-file changes

### 4.1 `Cosmic Fit/UI/Views/Palette/PaletteGrid.swift` — model

Rewrite. Drop the `PaletteRow` type; the grid becomes a flat `[PaletteCell]` of length 16 (or `[[PaletteCell]]` of 4 arrays of 4 — whichever the developer finds cleaner; either works). My recommendation: keep it flat for simplicity and index `i / 4` → row, `i % 4` → column in the view.

```swift
struct PaletteGrid: Equatable {
    let cells: [PaletteCell]           // exactly 16 in order (reading order)

    static let columnCount = 4
    static let rowCount = 4
    static let cellCount = 16          // columnCount * rowCount
}

struct PaletteCell: Equatable {
    enum Kind: Equatable {
        case filled(hex: String, anchorName: String)   // name kept for accessibility only
        case empty
    }
    let kind: Kind
}
```

**Remove**:
- `PaletteRow` struct entirely
- `hidesEmptyRows` flag
- `toneIndex` on `PaletteCell` (no tonal expansion means no tone index)
- All the `neutralRowCount / coreRowCount / accentRowCount / supportRowCount` constants
- `nonEmptyRowCount` helper (can be replaced with `cells.filter { if case .filled = $0.kind { true } else { false } }.count` if any caller needs it — probably none do now)

**Keep**: `Equatable` conformance, Foundation-only, no UIKit.

### 4.2 `Cosmic Fit/UI/Views/Palette/PaletteGridViewModel.swift` — transform

Rewrite `build(from:)`. New responsibilities:

1. Flatten `section.neutrals ?? []`, `section.coreColours`, `section.accentColours`, `section.supportColours ?? []` into one `[BlueprintColour]` list, preserving the above concatenation order (provides a stable tie-breaker when hues are equal).
2. Run the hue-proximity sort from §3.3.
3. Map each sorted `BlueprintColour` to a `PaletteCell.Kind.filled(hex: …, anchorName: …)`.
4. Pad the trailing cells with `.empty` until the list is exactly 16 long; truncate if longer.
5. Return `PaletteGrid(cells: …)`.

**Remove** entirely:
- `expandToFiveTones(anchorHex:)`
- `lightnessClamp`, `saturationDelta`
- `buildFilledRow`, `buildEmptyRow`

**Keep**:
- `malformedHexFallback: String = "#808080"` — still used if `ColourMath.hexToHSL` returns nil for a cell's hex. In the new design, a malformed hex still produces a filled cell (backed by the fallback grey) rather than an empty one, matching existing behaviour from the old `expandToFiveTones` malformed path.

**Key helpers** to add (pseudo-Swift):

```swift
private enum HueBucket: Int {
    case chromatic = 0
    case achromatic = 1
    case malformed = 2
}

private struct SortKey {
    let bucket: HueBucket
    let hue: Double            // 0…1 for chromatic; 0 for others
    let lightness: Double      // 0…1
    let originalIndex: Int     // tie-break
}

private static let achromaticSaturationThreshold: Double = 0.10

private static func sortKey(for hex: String, index: Int) -> SortKey {
    guard let (h, s, l) = ColourMath.hexToHSL(hex) else {
        return SortKey(bucket: .malformed, hue: 0, lightness: 0, originalIndex: index)
    }
    if s < achromaticSaturationThreshold {
        return SortKey(bucket: .achromatic, hue: 0, lightness: l, originalIndex: index)
    }
    return SortKey(bucket: .chromatic, hue: h, lightness: l, originalIndex: index)
}
```

Then sort the `(BlueprintColour, SortKey)` pairs lexicographically on
`(bucket.rawValue, hue, lightness, originalIndex)` — which gives:
chromatic-ascending-hue → achromatic-ascending-lightness → malformed-by-index.

### 4.3 `Cosmic Fit/UI/Views/ColourPaletteView.swift` — view

Simplify aggressively. The current file is ~500 lines; the new one should be roughly half that.

**Remove**:
- All the band-header machinery: `PaletteSectionHeaderView` class, `bandTitle(for:)`, `isBandLeader(_:)`, `firstVisibleRow(inRange:)`, `bandTitleHeight`, `coreBandStartRow` / `accentBandStartRow` / `supportBandStartRow` constants, `headerHeight(for:)`, `referenceSizeForHeaderInSection`, and the `viewForSupplementaryElementOfKind` handler.
- `showsDevelopmentAnchorNames` flag and `devAnchorLabelHeight` (no longer meaningful; there's no per-row anchor name).
- `hidesEmptyRows` checks (`isRowVisible`, the insetForSectionAt logic).
- `toneRoleName(for:)` helper.

**Simplify**:
- `numberOfSections` → `1` (or keep as `grid == nil ? 0 : 1`).
- `numberOfItemsInSection` → `PaletteGrid.cellCount` (i.e. 16), or the count of cells in the grid.
- `cellForItemAt` → look up `grid.cells[indexPath.item]`, switch on `.filled / .empty`, call `configure(withHex:)` or `configureEmpty()`. Set accessibilityLabel to the `anchorName` from the filled cell's associated value.
- `sizeForItemAt` → `let size = (width − 3 × cellSpacing) / 4; return CGSize(width: size, height: size)`.
- `intrinsicContentSize` → `width` wide × `(4 × cellSize + 3 × cellSpacing)` tall.

**Keep unchanged**:
- `init()`, `setupUI()`, the basic constraint setup that pins the collection view to the view bounds.
- The `isScrollEnabled = false`, `allowsSelection = false` configuration.
- The `ColourCell` registration (the cell class itself does not need to change).
- The public API `configure(with grid: PaletteGrid)` — signature and name preserved so `StyleGuideViewController` compiles with no change.
- `static func placeholder() -> PaletteGrid` — keep, but update its implementation to build a `PaletteGrid` with 16 `.filled` cells using the sorted output of `PaletteGridViewModel.build(from:)` on the same fixture `PaletteSection` it already constructs. The placeholder input palette (warm ivory, sage, saffron, etc.) does not need to change; it just flows through the new build function.

### 4.4 `Cosmic Fit/UI/Views/Palette/ColourCell.swift`

**No changes needed.** `configure(withHex:)` and `configureEmpty()` are already exactly what the new design wants.

### 4.5 `Cosmic Fit/UI/Views/Palette/ColourMath.swift`

**Keep** `hexToHSL`, `hslToHex` — the hue sort reuses `hexToHSL`.

**Remove** `tonalOffsets` — no longer referenced after this refactor. Grep for any remaining references and delete; the test in `ColourMathTests.tonalOffsetsClampToValidRange` (in `PaletteGridViewModel_Tests.swift`) must also be deleted.

### 4.6 Call sites — `StyleGuideViewController.swift`

Check [line 510 onwards](../Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift#L510). If the current code references `showsDevelopmentAnchorNames` (behind a `#if DEBUG`), remove that reference — the flag no longer exists. Otherwise no changes.

---

## 5. Tests

### 5.1 Delete

From [`Cosmic FitTests/PaletteGridViewModel_Tests.swift`](../Cosmic FitTests/PaletteGridViewModel_Tests.swift):

- `ColourMathTests.tonalOffsetsClampToValidRange` — `tonalOffsets` is gone.
- `PaletteGridViewModelTests.happyPathAllFilled` — assumes 16 rows × 5 cells × role bands, all wrong now.
- `PaletteGridViewModelTests.shortCorePadsWithEmptyRow` — row-padding concept is gone.
- `PaletteGridViewModelTests.filledRowProducesFiveValidHexTones` — rows don't exist.
- `PaletteGridViewModelTests.nonEmptyRowCountMatchesFilledRows` — helper is gone.

### 5.2 Keep (with mechanical updates)

- `ColourMathTests.hexToHSLRejectsBadHex` — unchanged.
- `ColourMathTests.hexRoundTripStable` — unchanged.
- `PaletteGridViewModelTests.malformedHexFallsBackToSentinel` — update to assert that a malformed hex still produces a filled cell (or the correctly bucketed `.malformed` position) with the `#808080` fallback hex. The surrounding cells should still be present and valid.
- `PaletteGridViewModelTests.determinismAcrossRebuilds` — unchanged in intent; update the assertion target to the new `PaletteGrid` shape.
- `PaletteGridGoldenSnapshotTests.goldenSnapshotUser1` / `goldenSnapshotUser2` — **keep**, they are the primary regression for this change. Update the `PaletteGridSnapshot` / `PaletteCellSnapshot` Codable mirrors in `GoldenSnapshotSupport` to match the new `PaletteGrid` shape:

```swift
fileprivate struct PaletteGridSnapshot: Codable, Equatable {
    let cells: [PaletteCellSnapshot]
    init(from grid: PaletteGrid) {
        self.cells = grid.cells.map(PaletteCellSnapshot.init(from:))
    }
}

fileprivate struct PaletteCellSnapshot: Codable, Equatable {
    let hex: String?
    let anchorName: String?
    init(from cell: PaletteCell) {
        switch cell.kind {
        case .filled(let hex, let name):
            self.hex = hex
            self.anchorName = name
        case .empty:
            self.hex = nil
            self.anchorName = nil
        }
    }
}
```

- `PaletteLiveWiringTests` — all four sub-tests must compile after the shape change. Update assertions from `PaletteGrid.rowCount`/`nonEmptyRowCount` to `PaletteGrid.cellCount` and `grid.cells.filter(isFilled).count`.

### 5.3 Add (new tests)

```swift
@Test("Output has exactly 16 cells in reading order")
func producesExactly16Cells() {
    let grid = PaletteGridViewModel.build(from: Self.v4Section())
    #expect(grid.cells.count == 16)
}

@Test("Hue-proximity sort: red < yellow < green < blue in output order")
func hueSortOrdersByHue() {
    // Build a fake PaletteSection whose 16 anchors span deliberate hues:
    // 4 reds, 4 yellows, 4 greens, 4 blues — shuffled on input.
    // Assert the output cells come out in hue-ascending order.
}

@Test("Achromatics come after chromatics, sorted by lightness")
func achromaticsPlacedAfterChromatics() {
    // 8 chromatic + 8 achromatic (low-saturation greys/off-whites).
    // Assert cells 0…7 are all chromatic; cells 8…15 all achromatic;
    // and that the achromatics appear darkest → lightest.
}

@Test("Determinism: repeated builds yield identical grids")
func deterministicBuild() {
    // 10 rebuilds, all ==.
}

@Test("Fewer than 16 inputs pads trailing cells with .empty")
func padsShortInputs() {
    // Build a section missing the entire support band (12 anchors total).
    // Assert cells.count == 16, the last 4 are .empty.
}

@Test("Similar hues land adjacent: petrol / teal / forest-green together")
func similarHuesAdjacent() {
    // Seed a section with #1B3A4B (petrol), #3C7A85 (teal), #254D32 (forest),
    // plus 13 other clearly distant colours.
    // Find the indices of petrol/teal/forest in the output; assert they are
    // within a contiguous range of length 3 (allowing any permutation among them).
}
```

### 5.4 Tests in other files

- [`MariaAshLocked_Tests.swift`](../Cosmic FitTests/MariaAshLocked_Tests.swift) — grep for any assertion on `PaletteGrid.rowCount`, `PaletteRow`, `toneIndex`, `hidesEmptyRows`. Update accordingly. These tests are about engine output (`PaletteTriadV4`), not grid shape, so most likely nothing here changes.
- [`VariationSlots_Tests.swift`](../Cosmic FitTests/VariationSlots_Tests.swift) — should be untouched (engine-layer tests).
- [`Cosmic_FitTests.swift`](../Cosmic FitTests/Cosmic_FitTests.swift) — grep just in case.

### 5.5 Golden regeneration

After the new `PaletteGridViewModel.build` is in place and the `GoldenSnapshotSupport` structs have been updated:

```bash
# From Xcode:
#   1. Edit scheme → Test action → Arguments tab → Environment Variables
#      Add:   REGENERATE_PALETTE_GRID_GOLDENS = 1
#   2. Run the test class `PaletteGridGoldenSnapshotTests` once
#   3. Unset the env var
#   4. Commit the updated docs/fixtures/palette_grid_golden_user_1.json
#      and docs/fixtures/palette_grid_golden_user_2.json
```

The `v4_regression.actual.json` files that appear during failing runs are debugging artefacts, not part of the golden — do not commit them.

---

## 6. Acceptance criteria

1. App builds cleanly, no warnings introduced.
2. Style Guide → palette section shows a single square 4×4 colour grid, no band labels, no tonal variations per colour.
3. Each of the 16 swatches is a flat single colour = the engine-selected anchor hex (round-tripped through HSL, within 1 channel unit — same as the "centre column" colour in the old grid).
4. Two users with different palettes (e.g. Ash vs Maria) produce visibly different grids (already true from the engine; this refactor does not regress it).
5. Within a single user's grid, visually similar colours sit next to each other in reading order (e.g. blues-to-greens or reds-to-oranges chain without jumps).
6. All non-deleted tests in `Cosmic FitTests/PaletteGridViewModel_Tests.swift` pass; new tests from §5.3 pass.
7. `goldenSnapshotUser1` and `goldenSnapshotUser2` pass against the regenerated goldens.
8. `PaletteLiveWiringTests` all pass (the storage round-trip path still works).

---

## 7. What NOT to touch

Explicit non-goals. Changing any of these is out of scope and will be rejected in review:

| Area | File(s) |
|---|---|
| Colour selection engine | everything under `Cosmic Fit/InterpretationEngine/ColourEngineV4/` |
| Per-user variation | `VariationSlots.swift`, `VariationSlots_Tests.swift` |
| Blueprint models | `BlueprintModels.swift` (`PaletteSection`, `BlueprintColour`, `ColourRole`) |
| Blueprint composer | `BlueprintComposer.swift` |
| Daily palette generator | `DailyColourPaletteGenerator.swift`, `DailyColourPaletteView.swift` |
| Narrative text | `blueprint_narrative_cache.json` |
| Calibration fixtures & harness | everything in `docs/fixtures/` **except** the two `palette_grid_golden_user_*.json` files |
| Supabase sync | untouched |

The engine still produces exactly 16 anchor `BlueprintColour`s per user, split across 4 bands by role; this refactor only changes how those 16 are *displayed*, not which 16 are selected.

---

## 8. Suggested implementation order

1. Update the model (`PaletteGrid.swift`) — gives you compiler errors everywhere downstream as a checklist.
2. Rewrite `PaletteGridViewModel.build` with the new sort + flatten logic. Write the new unit tests (§5.3) *before* the view layer.
3. Simplify `ColourPaletteView.swift` — delete first, then trim `cellForItemAt` and `sizeForItemAt` to the 4×4 shape.
4. Update the `GoldenSnapshotSupport` Codable mirrors in the test file.
5. Delete the obsolete tests from §5.1.
6. Regenerate goldens (§5.5). Eyeball-diff the new golden JSONs before committing — they should be ~⅓ the size of the current ones (16 cells × name+hex vs 16 rows × 5 cells × hex).
7. Delete `ColourMath.tonalOffsets` and any dead references.
8. Run the full test suite. All green before handing back.

---

## 9. Open items (flag if uncertain)

- **Hue sort rotation anchor**: the spec says "start at red" (hue = 0.0). If during implementation the sort visually clumps awkwardly — e.g. the split between magenta (hue ~0.95) and red (hue ~0.02) lands mid-row and breaks the "similar colours adjacent" feel — discuss with Ash before tweaking. The rotation anchor and the `achromaticSaturationThreshold` (0.10) are the two tuning knobs. Any change must be deterministic and reflected in the goldens.
- **Placeholder palette**: the current `ColourPaletteView.placeholder()` embeds a hardcoded fixture palette (Deep Autumn). After the refactor, its output will render as a sorted 4×4 of those 16 colours. Quickly eyeball this in a debug build — if it looks ugly (unlikely with a coherent DA palette), consider picking 16 more hue-spread colours for the placeholder. Cosmetic, not blocking.
