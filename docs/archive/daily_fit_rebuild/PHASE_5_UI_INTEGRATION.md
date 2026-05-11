# Phase 5: UI Integration & Pipeline Wiring

**Dependency:** Phase 0 (types) + Phase 2 (snapshot) + Phase 4 (complete `DailyFitPayload`).
**Produces:** The new 2-stage pipeline replaces the legacy `DailyVibeGenerator.generateDailyVibe()` call. The Daily Fit screen renders from `DailyFitPayload`.
**Estimated scope:** Modifications to 2 existing files, 1 new view, 1 optional adapter. ~400–500 lines changed/added.

---

## 1. Context

Phases 0–4 built the new pipeline in complete isolation. No existing file was touched. Now it's time to wire the new pipeline into the live app so the Daily Fit screen runs off `DailyEnergyEngine` → `BlueprintLensEngine` instead of `DailyVibeGenerator`.

### Current wiring

The call chain today is:

```
CosmicFitTabBarController.generateAndCacheDailyVibe(chartId:)
  → DailyVibeGenerator.generateDailyVibe(natalChart:progressedChart:transits:weather:moonPhase:profileHash:date:)
  → DailyVibeContent
  → stored in self.dailyVibeContent
  → passed to DailyFitViewController.configure(with:originalChartViewController:)
  → DailyFitViewController.updateContent() reads self.dailyVibeContent
```

Key files and lines:

| File | Line(s) | What Happens |
|---|---|---|
| `CosmicFitTabBarController.swift` | ~779–814 | `generateAndCacheDailyVibe(chartId:)` — calls `DailyVibeGenerator`, stores result, saves to `DailyVibeStorage` |
| `CosmicFitTabBarController.swift` | ~912–917 | Creates `DailyFitViewController`, calls `configure(with: dailyVibeContent, ...)` |
| `DailyFitViewController.swift` | ~86 | `private var dailyVibeContent: DailyVibeContent?` |
| `DailyFitViewController.swift` | ~195–204 | `func configure(with:originalChartViewController:)` |
| `DailyFitViewController.swift` | ~1480–1519 | `updateContent()` — reads from `dailyVibeContent` to populate all UI elements |

### What changes

1. **Tab bar controller** calls the new pipeline instead of `DailyVibeGenerator`.
2. **DailyFitViewController** gets a **major content overhaul** below the tarot card. The new layout replaces everything from "Style Edit" downward with the Figma-specified sections.
3. A new **`EssenceTriangleView`** is created to render the 3-vertex essence chart.
4. The legacy `DailyVibeContent` property and code paths remain in the file but become dead code (removed in Phase 7).

### New content layout (below tarot card, in scroll order)

| # | Section | Data source | UI approach |
|---|---|---|---|
| 1 | **Tarot paragraph** (Style Edit text) | `payload.styleEditVariant.description` | Existing `styleEditLabel` — just rename the header |
| 2 | **Daily Ritual** | `payload.styleEditVariant.microRitual` | New label + ornamental header. Hidden if `nil`. |
| 3 | **Outfit Breakdown** header | Static text | Existing `styleBreakdownDivider` — keep |
| 4 | **Style Palette** (3 colour swatches) | `payload.dailyPalette` | Existing `colourPaletteContainer` — rename header from "Colour" to "Style Palette" |
| 5 | **Vibrancy** scale | `payload.vibrancy` | Replace old pill sliders with single diamond-marker scale |
| 6 | **Contrast** scale | `payload.contrast` | New diamond-marker scale (same style as Vibrancy) |
| 7 | **Metal Tone** scale (Cool/Mixed/Warm) | `payload.metalTone` | Replace old tone slider with tri-label scale |
| 8 | **Essence** triangle chart | `payload.essenceTriangle` | **New `EssenceTriangleView`** — GROUNDED / EDGY / CLASSIC |
| 9 | **Silhouette** header | Static text | Existing `silhouetteHeaderDivider` — keep |
| 10 | **3 bipolar sliders** | `payload.silhouetteProfile` | Reuse existing `createBipolarSlider`, update labels and values |
| 11 | **Wardrobe Reflection** (question) | `payload.styleEditVariant.wardrobeReflection` | New italic label. Hidden if `nil`. |
| 12 | **Star divider** | Static | Existing `finalStarDivider` |
| 13 | **Tomorrow teaser** + CTA button | Static text + button | New section at bottom |

### What is REMOVED from the current layout

- The **"Style Edit"** heading label (the paragraph stays, heading renamed)
- The **pill sliders** section (Brightness / Contrast / Vibrancy pills) → replaced by individual Vibrancy and Contrast scales
- The **`VibeBreakdownBarsView`** (6 energy bars) → replaced by Essence triangle
- The **`takeawayLabel`** → replaced by Wardrobe Reflection
- The **debug button** → removed (diagnostics are in Phase 6)

---

## 2. Files You Will Modify / Create

| File | What Changes |
|---|---|
| `Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift` | Replace `generateAndCacheDailyVibe` internals. Add new property for `DailyFitPayload`. |
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | Major overhaul of content sections below tarot card. New `updateContentFromPayload()`, new setup methods, removed/replaced sections. |
| **NEW:** `Cosmic Fit/UI/Views/EssenceTriangleView.swift` | Triangular radar chart with 3 labelled vertices (GROUNDED / EDGY / CLASSIC) and a plotted point. |
| **Optional:** `Cosmic Fit/InterpretationEngine/DailyFitPayloadStorage.swift` | For persisting `DailyFitPayload` via UserDefaults/file. |

---

## 3. What You Are Building

### 3.1 CosmicFitTabBarController Changes

#### New property

Add alongside the existing `dailyVibeContent` property (~line 28):

```swift
private var dailyFitPayload: DailyFitPayload?
```

#### Replace `generateAndCacheDailyVibe(chartId:)`

The existing method (lines ~779–814) calls `DailyVibeGenerator.generateDailyVibe(...)`. Replace its implementation with the new 2-stage pipeline. **Keep the method signature the same** so callers don't need to change.

New implementation:

```swift
private func generateAndCacheDailyVibe(chartId: String) {
    guard let natal = natalChart, let progressed = progressedChart else {
        // Fallback: still set legacy placeholder for safety
        dailyVibeContent = .placeholder
        return
    }

    let transits = NatalChartCalculator.calculateTransits(natalChart: natal)
    let julianDay = JulianDateCalculator.calculateJulianDate(from: Date())
    let moonPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)
    let profileHash = userProfile?.id ?? chartId

    // STAGE 1: Generate energy snapshot
    let snapshot = DailyEnergyEngine.generateSnapshot(
        natalChart: natal,
        progressedChart: progressed,
        transits: transits,
        moonPhaseDegrees: moonPhase,
        profileHash: profileHash,
        date: Date()
    )

    // STAGE 2: Apply Blueprint lens
    if let blueprint = BlueprintStorage.shared.load() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: blueprint,
            snapshot: snapshot
        )
        dailyFitPayload = payload

        // Persist for offline/reload
        // (optional — implement if DailyFitPayloadStorage exists)
    } else {
        // No Blueprint available — fall back to legacy generator so the UI still renders.
        // This shouldn't happen in normal flow but defend gracefully.
        let legacyContent = DailyVibeGenerator.generateDailyVibe(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhase: moonPhase,
            profileHash: profileHash,
            date: Date()
        )
        dailyVibeContent = legacyContent
        // NOTE: No print() — use structured diagnostics (Phase 6) if logging is needed.
    }
}
```

**Important:** The existing `DailyVibeStorage.shared.saveDailyVibeForUser(...)` / `saveDailyVibe(...)` calls are for the legacy content. You may either:
- Remove them (if you're confident nothing else reads from `DailyVibeStorage`), OR
- Leave them in alongside the new pipeline (belt and braces).

The safer choice is to leave them for now. Phase 7 will clean them up.

#### Update DailyFitViewController creation

At line ~912–917, the tab bar creates and configures the Daily Fit VC:

```swift
let dailyFitVC = DailyFitViewController()
if let dailyVibeContent = dailyVibeContent {
    dailyFitVC.configure(
        with: dailyVibeContent,
        originalChartViewController: createDebugChartViewController()
    )
}
```

Add the new payload path:

```swift
let dailyFitVC = DailyFitViewController()
if let payload = dailyFitPayload {
    dailyFitVC.configure(
        with: payload,
        originalChartViewController: createDebugChartViewController()
    )
} else if let dailyVibeContent = dailyVibeContent {
    // Legacy fallback
    dailyFitVC.configure(
        with: dailyVibeContent,
        originalChartViewController: createDebugChartViewController()
    )
}

// Wire tomorrow button — the VC can't run the pipeline itself, so provide a closure.
dailyFitVC.generateForDateHandler = { [weak self] date in
    guard let self = self else { return }
    self.generateAndCacheDailyVibe(chartId: self.currentChartId ?? "", forDate: date)
    if let payload = self.dailyFitPayload {
        dailyFitVC.configure(with: payload, originalChartViewController: nil)
    }
}
```

> **Note:** This requires `generateAndCacheDailyVibe(chartId:)` to accept an optional `forDate:` parameter (defaulting to `Date()`). Add that parameter to the method signature — a 1-line change.

### 3.2 DailyFitViewController Changes

This is a significant restructure. The tarot card reveal and header stay untouched. Everything from the paragraph downward gets rebuilt.

#### New property

Add alongside the existing `dailyVibeContent` property:

```swift
private var dailyFitPayload: DailyFitPayload?
```

#### New stored view references

Add these properties for the new UI sections:

```swift
// New pipeline views
private let microRitualHeaderDivider: UIView?    // Ornamental "Daily Ritual" header
private let microRitualLabel = UILabel()
private var essenceTriangleView: EssenceTriangleView?
private let wardrobeReflectionLabel = UILabel()
private let tomorrowTeaseLabel = UILabel()
private let tomorrowButton = UIButton(type: .system)
private let vibrancyScale: UIView    // Diamond-marker scale
private let contrastScale: UIView    // Diamond-marker scale

/// Closure provided by the tab bar controller to regenerate the pipeline for a given date.
/// The VC does NOT own pipeline inputs (natal chart, transits, Blueprint) — the tab bar does.
var generateForDateHandler: ((Date) -> Void)?
```

#### New `configure` overload

```swift
func configure(with payload: DailyFitPayload,
               originalChartViewController: NatalChartViewController?) {
    self.dailyFitPayload = payload
    self.originalChartViewController = originalChartViewController

    if isViewLoaded {
        updateContentFromPayload()
    }
}
```

#### Restructured `setupContentViewComponents()`

When the new pipeline is active, the content sections below the tarot card are set up in this order:

```swift
private func setupNewPipelineContentSections() {
    // 1. Tarot paragraph (reuse existing styleEditLabel, rename header)
    setupStyleParagraphSection()       // Was "Style Edit", now just the paragraph with no heading or a renamed heading

    // 2. Daily Ritual (micro-ritual from variant)
    setupMicroRitualSection()          // NEW — ornamental "Daily Ritual" header + ritual text

    // 3. Outfit Breakdown header
    setupStyleBreakdownSection()       // EXISTING — keep the "Outfit Breakdown" header

    // 4. Style Palette (colour swatches)
    setupColourPaletteSection()        // EXISTING — rename header from "Colour" to "Style Palette"

    // 5–6. Vibrancy + Contrast scales
    setupVibrancyContrastSection()     // NEW — replaces old pill sliders

    // 7. Metal Tone scale
    setupMetalToneSection()            // MODIFIED — add "Mixed" centre label

    // 8. Essence triangle
    setupEssenceSection()              // NEW — replaces VibeBreakdownBarsView

    // 9–10. Silhouette sliders
    setupSilhouetteSection()           // MODIFIED — new labels, dynamic values

    // 11. Wardrobe Reflection
    setupWardrobeReflectionSection()   // NEW — italic question

    // 12. Star divider
    setupFinalDivider()                // EXISTING

    // 13. Tomorrow teaser + CTA
    setupTomorrowSection()             // NEW
}
```

#### New `updateContentFromPayload()` method

This is the new rendering path. It maps `DailyFitPayload` fields to the new and existing UI components:

```swift
private func updateContentFromPayload() {
    guard let payload = dailyFitPayload else { return }

    // Tarot card (unchanged)
    loadTarotCardImage(for: payload.tarotCard)
    tarotTitleLabel.text = payload.tarotCard.displayName.uppercased()

    // Date (unchanged)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, d MMMM yyyy"
    dateFormatter.locale = Locale(identifier: "en_GB")
    dateLabel.text = dateFormatter.string(from: Date())

    // Tarot paragraph (Style Edit text)
    styleEditLabel.text = payload.styleEditVariant.description

    // Daily Ritual (micro-ritual)
    if let ritual = payload.styleEditVariant.microRitual {
        microRitualLabel.text = ritual
        microRitualHeaderDivider?.isHidden = false
        microRitualLabel.isHidden = false
    } else {
        microRitualHeaderDivider?.isHidden = true
        microRitualLabel.isHidden = true
    }

    // Style Palette (3 colour swatches)
    let dailyHexes = payload.dailyPalette.colours.map { $0.hexValue }
    let allHexes = payload.dailyPalette.allPaletteHexes
    colourPaletteContainer.configure(dailyHexes: dailyHexes, allPaletteHexes: allHexes)

    // Vibrancy scale — update diamond marker position
    updateDiamondScale(vibrancyScale, value: payload.vibrancy)

    // Contrast scale — update diamond marker position
    updateDiamondScale(contrastScale, value: payload.contrast)

    // Metal Tone scale — update diamond marker position
    updateDiamondScale(toneSliderContainer, value: payload.metalTone)

    // Essence triangle
    essenceTriangleView?.configure(with: payload.essenceTriangle)

    // Silhouette sliders — update positions from payload
    updateSilhouetteSliders(with: payload.silhouetteProfile)

    // Wardrobe Reflection
    if let reflection = payload.styleEditVariant.wardrobeReflection {
        wardrobeReflectionLabel.text = reflection
        wardrobeReflectionLabel.isHidden = false
    } else {
        wardrobeReflectionLabel.isHidden = true
    }
}
```

**Key mapping details:**

| Payload Field | UI Component | Approach |
|---|---|---|
| `styleEditVariant.description` | `styleEditLabel` | Direct text (existing label, header renamed) |
| `styleEditVariant.microRitual` | `microRitualLabel` | NEW label, hidden if nil |
| `dailyPalette.colours[].hexValue` | `colourPaletteContainer` | Existing `configure(dailyHexes:allPaletteHexes:)` |
| `vibrancy` | `vibrancyScale` | Diamond marker at position (0–1) on horizontal track |
| `contrast` | `contrastScale` | Diamond marker at position (0–1) on horizontal track |
| `metalTone` | `toneSliderContainer` | Diamond marker at position (0–1), tri-label: Cool / Mixed / Warm |
| `essenceTriangle` | `essenceTriangleView` | NEW view — plots point in triangle (see §3.3) |
| `silhouetteProfile.masculineFeminine` | bipolar slider 1 | Reuse `createBipolarSlider("Masculine", "Feminine", value)` |
| `silhouetteProfile.angularRounded` | bipolar slider 2 | Labels: "Angular" / "Rounded" (was "Curvy") |
| `silhouetteProfile.structuredDraped` | bipolar slider 3 | Labels: "Structured" / "Draped" (was "Relaxed") |
| `styleEditVariant.wardrobeReflection` | `wardrobeReflectionLabel` | NEW italic label, hidden if nil |
| — | `tomorrowButton` | Tapping runs pipeline with `date + 1 day` |

#### Helper: Diamond Scale — Creating and Updating

The vibrancy, contrast, and metal tone scales all use the same visual pattern — a horizontal track with a diamond ♦ marker.

**Important implementation detail:** The existing `createToneSlider()` and `createBipolarSlider(leftLabel:rightLabel:position:)` bake the diamond position into AutoLayout constraint multipliers at creation time. Constraint multipliers **cannot be changed after activation** — you'd have to deactivate the old constraint and activate a new one. For dynamically updated scales, use this pattern instead:

```swift
private func createDiamondScale(leftLabel: String, rightLabel: String, centreLabel: String? = nil) -> (container: UIView, indicator: UILabel, track: UIView) {
    // Build the track + labels + diamond exactly like createBipolarSlider but:
    // 1. Do NOT set any width-multiplier constraint on the spacers.
    // 2. Instead, store a single centerX constraint on the indicator, anchored to track.leadingAnchor with a constant.
    // 3. Return the indicator and track references so the constant can be updated later.
}

private var vibrancyIndicatorConstraint: NSLayoutConstraint?
private var contrastIndicatorConstraint: NSLayoutConstraint?
private var metalToneIndicatorConstraint: NSLayoutConstraint?

private func updateDiamondScale(constraint: inout NSLayoutConstraint?, indicator: UILabel, track: UIView, value: Double) {
    constraint?.isActive = false
    let offset = value * track.bounds.width
    let newConstraint = indicator.centerXAnchor.constraint(equalTo: track.leadingAnchor, constant: offset)
    newConstraint.isActive = true
    constraint = newConstraint
}
```

Call `updateDiamondScale(...)` inside `updateContentFromPayload()` and also in `viewDidLayoutSubviews()` (since `track.bounds.width` is zero until layout). This is the same visual style as the existing sliders — match the track colour (`.lightGray`), diamond ("♦"), and `CosmicFitTheme.Colours.cosmicBlue` tint exactly.

**For the silhouette sliders:** The same pattern applies. The existing `createBipolarSlider` must be adapted or a new `createUpdatableBipolarSlider` created that returns stored constraint references. The silhouette section currently uses hardcoded positions — the new version must accept dynamic values from the payload.

**For the metal tone scale:** Add a third "Mixed" label centred on the track (the existing `createToneSlider` only has "Cool" and "Warm"). Study the existing layout and insert a centred label between the two endpoints.

#### Update `viewDidLoad` path

```swift
if dailyFitPayload != nil {
    updateContentFromPayload()
} else {
    updateContent()  // legacy path
}
```

Find all call sites where `updateContent()` is invoked and add this branching.

### 3.3 New View: `EssenceTriangleView`

Create a new file:

```
Cosmic Fit/UI/Views/EssenceTriangleView.swift
```

A custom `UIView` that renders a triangular radar chart with 3 labelled vertices and a plotted point.

**Visual spec (from Figma):**
- An equilateral triangle drawn with thin dotted lines.
- Vertex labels positioned outside each corner: **GROUNDED** (top), **EDGY** (bottom-left), **CLASSIC** (bottom-right). Use `CosmicFitTheme.Typography` for the label font.
- A single plotted point (small diamond or dot) inside the triangle showing today's position.
- The point position is computed from the 3 normalised values: each value (0–1) determines how far the point is pulled toward that vertex.

**Barycentric coordinates:**
```
point.x = classic * classicVertex.x + edgy * edgyVertex.x + grounded * groundedVertex.x
point.y = classic * classicVertex.y + edgy * edgyVertex.y + grounded * groundedVertex.y
```

Where `classicVertex`, `edgyVertex`, `groundedVertex` are the 3 corner positions of the triangle in the view's coordinate space.

**API:**

```swift
final class EssenceTriangleView: UIView {
    func configure(with essence: EssenceTriangle)
}
```

**Styling:**
- Match the existing `DailyFitViewController` aesthetic (dark lines on light background, `CosmicFitTheme.Colours.cosmicBlue`).
- The triangle should be ~200pt wide, centred.
- Lines between vertices: thin (0.5pt), with short dashes connecting them to the plotted point.
- The plotted point: a small filled diamond (like the existing scale markers), 8×8pt.
- Labels: `CosmicFitTheme.Typography.FontSizes.caption`, uppercase, letter-spaced.

Keep the view under **120 lines**. It's a pure display component — no interactivity.

### 3.4 Tomorrow Section

At the bottom of the scroll view, below the star divider:

```swift
private func setupTomorrowSection() {
    // Italic teaser: "Tomorrow's energy is already shifting..."
    tomorrowTeaseLabel.text = "Tomorrow's energy is already shifting..."
    CosmicFitTheme.styleBodyLabel(tomorrowTeaseLabel, fontSize: ..., weight: .regular)
    tomorrowTeaseLabel.font = tomorrowTeaseLabel.font.withTraits(.traitItalic)

    // CTA button: "SEE TOMORROW'S FIT >"
    tomorrowButton.setTitle("SEE TOMORROW'S FIT  ›", for: .normal)
    // Style: bordered, uppercase, matching existing button aesthetics
    tomorrowButton.addTarget(self, action: #selector(tomorrowButtonTapped), for: .touchUpInside)
}

@objc private func tomorrowButtonTapped() {
    guard let generateForDate = generateForDateHandler else { return }
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    generateForDate(tomorrow)
}
```

The "tomorrow" generation reuses the exact same pipeline with `Calendar.current.date(byAdding: .day, value: 1, to: Date())` as the `date` parameter. The result replaces the current payload and triggers `updateContentFromPayload()`.

---

## 4. What You Must NOT Do

- **Do not delete the legacy `DailyVibeContent` property or `updateContent()` method.** Those are cleaned up in Phase 7. They serve as the fallback path until the new pipeline is confirmed working.
- **Do not modify `DailyColourPaletteView.swift`.** It already accepts the data formats we need for palette rendering.
- **Do not modify `DailyVibeGenerator.swift`.** It continues to exist for the legacy fallback.
- **Do not modify any Phase 0–4 files.** The engine and types are frozen.
- **Do not remove `DailyVibeStorage` calls yet.** Phase 7 handles cleanup.
- **Do not change the tarot card reveal UX.** The unrevealed card → tap → reveal → scroll behaviour is working and must stay exactly as-is.
- **Do not invent new styling.** All new UI elements must use existing `CosmicFitTheme` colours, fonts, and spacing patterns. Match the established aesthetic.

---

## 5. Edge Cases to Handle

1. **No Blueprint available:** If `BlueprintStorage.shared.load()` returns nil, the new pipeline can't run. The code above already falls back to the legacy `DailyVibeGenerator` and sets `dailyVibeContent`. The VC creation code then picks up the legacy path. This should be rare but must be handled without crashing or showing an empty screen.

2. **Blueprint exists but incomplete:** If the Blueprint has empty palette sections or missing textures, `BlueprintLensEngine.generatePayload` should still return a valid payload (Phase 4 tests cover this). But verify the UI doesn't crash on edge values.

3. **View not yet loaded:** Both `configure` methods already check `isViewLoaded` before calling update. Ensure the new path also defers correctly.

4. **Calendar/date-picker feature:** `DailyFitViewController` has a `calendarButton` and `calendarButtonTapped` method. If this allows viewing past dates, ensure the new pipeline is called with the selected date, not just `Date()`. Check the existing implementation and mirror any date-override logic.

---

## 6. Acceptance Tests

Create a test file:

```
Cosmic FitTests/DailyFitUIIntegration_Tests.swift
```

These are integration-level tests. Some may need to instantiate view controllers, which requires `@testable import Cosmic_Fit` and `import XCTest`.

### Required Tests

| # | Test | What It Validates |
|---|---|---|
| T5.1 | `testNewPipelineProducesPayload` | Call `DailyEnergyEngine.generateSnapshot(...)` then `BlueprintLensEngine.generatePayload(...)` with fixture data. Assert the payload is fully populated including all new fields. |
| T5.2 | `testPayloadPaletteHexesAreValidHex` | Every `hexValue` in `payload.dailyPalette.colours[].hexValue` matches the pattern `#[0-9A-Fa-f]{6}`. |
| T5.3 | `testPayloadVibeBreakdownValid` | `payload.vibeBreakdown.totalPoints == 21`. |
| T5.4 | `testPayloadTarotCardHasImage` | `payload.tarotCard.imagePath` is non-empty. |
| T5.5 | `testPayloadStyleEditHasDescription` | `payload.styleEditVariant.description` is non-empty. |
| T5.6 | `testDailyColourPaletteViewAcceptsPayloadData` | Instantiate `DailyColourPaletteView()`, call `configure(dailyHexes:allPaletteHexes:)` with payload data. Assert no crash. |
| T5.7 | `testEssenceTriangleViewAcceptsPayloadData` | Instantiate `EssenceTriangleView()`, call `configure(with: payload.essenceTriangle)`. Assert no crash and view has non-zero intrinsic size. |
| T5.8 | `testFullPipelineEndToEnd` | Given a fixture natal chart, progressed chart, transits, moon phase, and a persisted Blueprint fixture, run the full Stage 1 → Stage 2 pipeline and assert the output is a valid `DailyFitPayload` with all fields populated. |
| T5.9 | `testLegacyFallbackWhenNoBlueprintPresent` | If no Blueprint is stored, the tab bar controller should still produce a non-nil daily content (via legacy fallback). This test may be a manual verification note if the tab bar controller is hard to instantiate in tests. |
| T5.10 | `testEssenceTrianglePointInBounds` | Given any `EssenceTriangle`, the plotted point (computed via barycentric coords) falls inside the triangle bounds. |
| T5.11 | `testPayloadNewScalesInRange` | `payload.vibrancy`, `payload.contrast`, `payload.metalTone` are all in [0.0, 1.0]. `payload.silhouetteProfile` values are all in [0.0, 1.0]. |

### Manual Verification Checklist

These cannot be fully automated but must be verified on device before Phase 5 is considered done:

- [ ] App launches without crash.
- [ ] Daily Fit tab shows a tarot card image. Tap-to-reveal animation works.
- [ ] Tarot card title and date display correctly.
- [ ] Tarot paragraph (style edit description) text appears below card.
- [ ] Daily Ritual section appears with micro-ritual text (or is hidden if nil).
- [ ] "Outfit Breakdown" header displays.
- [ ] "Style Palette" shows 3 colour swatches from the Blueprint palette.
- [ ] Vibrancy scale renders with diamond marker at correct position.
- [ ] Contrast scale renders with diamond marker at correct position.
- [ ] Metal Tone scale renders with Cool / Mixed / Warm labels and diamond marker.
- [ ] Essence triangle renders with GROUNDED / EDGY / CLASSIC labels and plotted point.
- [ ] Silhouette section shows 3 sliders: Masculine/Feminine, Angular/Rounded, Structured/Draped.
- [ ] Silhouette slider positions reflect the payload values (not hardcoded).
- [ ] Wardrobe Reflection question appears in italics (or is hidden if nil).
- [ ] Star divider displays.
- [ ] "Tomorrow's energy is already shifting..." teaser and "SEE TOMORROW'S FIT" button appear.
- [ ] Tapping "SEE TOMORROW'S FIT" triggers pipeline with tomorrow's date and updates content.
- [ ] Scrolling works smoothly through all sections.
- [ ] Card reveal → scroll → all new content visible UX flow is seamless.
- [ ] Switching tabs and returning to Daily Fit doesn't crash or reset content.

---

## 7. Definition of Done

- [ ] The Daily Fit screen renders from `DailyFitPayload` with the new Figma layout when a Blueprint is available.
- [ ] `EssenceTriangleView.swift` exists and renders correctly.
- [ ] All new content sections display: paragraph, ritual, palette, vibrancy, contrast, metal tone, essence, silhouette, reflection, tomorrow teaser.
- [ ] Legacy `DailyVibeContent` path still works as a fallback (no regression).
- [ ] All 11 automated tests pass.
- [ ] Manual verification checklist (20 items) passes on a real device or simulator.
- [ ] No crashes on launch, tab switching, or background/foreground transitions.
- [ ] Only `CosmicFitTabBarController.swift` and `DailyFitViewController.swift` are modified among existing files (plus new `EssenceTriangleView.swift` and optional `DailyFitPayloadStorage.swift`).
- [ ] Phase 0–4 files are untouched.
- [ ] Tarot card reveal UX is unchanged.

---

## 8. What Comes Next

Phase 6 adds calibration tooling and diagnostic logging. Phase 7 strips the dead legacy code. After Phase 5, you have a **working Daily Fit on-device** running the new pipeline — the first point where real user testing can begin.

---

## 9. Standards

- **Preserve existing code style.** The tab bar controller and daily fit VC use specific patterns (property naming, method organisation, comment style). Match them.
- **No force-unwraps.**
- **Indentation:** 4 spaces.
- **Keep both code paths (new + legacy) clearly separated** with MARK comments:
  ```swift
  // MARK: - New Pipeline (DailyFitPayload)
  // MARK: - Legacy Pipeline (DailyVibeContent)
  ```
- **Tarot card reveal and header are untouched.** The layout above the paragraph stays exactly as-is.
- **All new UI elements use existing `CosmicFitTheme`** — colours, fonts, spacing. No new design tokens.
- **No `print()` statements.** Use structured diagnostics (Phase 6) for any logging needs.
