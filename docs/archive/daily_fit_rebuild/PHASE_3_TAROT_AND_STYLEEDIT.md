# Phase 3: BlueprintLensEngine — Tarot & StyleEdit Selection

**Dependency:** Phase 0 (types) + Phase 2 (complete `DailyEnergySnapshot`).
**Produces:** `BlueprintLensEngine` with tarot card selection and variant rotation. Also modifies `StyleEditVariant` to carry richer content fields.
**Estimated scope:** ~300–400 lines. One new file, two modified files, one new small tracker.

---

## 1. Context

This is the start of **Stage 2** of the pipeline. Stage 1 (Phases 1–2) produced a `DailyEnergySnapshot` — a pure astrological distillation of the day. Stage 2 takes that snapshot and the user's `CosmicBlueprint` and selects *what the user sees*.

In this phase, you build the tarot card and style edit selection. These are the "headline" of the Daily Fit — the emotional/narrative centrepiece that anchors the entire daily recommendation.

### Legacy system

The existing `TarotCardSelector` (1,059 lines) uses a multi-stage approach:
1. Axis filter → candidate pool
2. Multi-factor score (50% vibe, 35% axes, 15% transit boost)
3. Recency penalty via `TarotRecencyTracker`
4. Tie-break via daily seed

The approach is sound but overcomplicated. The main issues:
- Card axis data is on a 0–100 scale while day axes are 1–10 — normalisation happens mid-scoring (`card.axes.action / 10.0`) instead of at load time.
- `StyleEditSelector` in `TarotCard.swift` normalises vibe energies by `/100` instead of `/21` — compressing all vibe influence to ~21% of intended range. This is a confirmed bug (audit item #1).
- Fallback chains mean calibration issues cascade unpredictably.

### What you build differently

- **Normalise card data at load time**, not during scoring.
- **Fix the vibe normalisation bug** — divide by 21, not 100.
- **Simpler scoring** — same concept (vibe + axes + transit boost), cleaner implementation.
- **Same recency tracking** — reuse `TarotRecencyTracker` directly, it works correctly.
- **Use `DailyFitCalibration.SelectionWeights`** for the vibe/axis/transit weight split.

---

## 2. File Location

Create one new file:

```
Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift
```

This file imports `Foundation` only.

---

## 3. Existing Components You Will Use (Do NOT Redefine)

| Component | Location | How You Use It |
|---|---|---|
| `TarotCard` | `TarotCard.swift` (499 lines) | The card model. Has `energyAffinity: [String: Double]`, `axesAffinity: [String: Double]?`, `keywords`, `themes`, **`styleEdits: [StyleEditVariant]?`** (note: the property is `styleEdits`, NOT `styleEditVariants`). Each card has exactly 3 variants. |
| `StyleEditVariant` | `TarotCard.swift` | **You will modify this struct** (see §3.5). Currently has `variant`, `title`, `description`, `energyEmphasis`, `axesEmphasis`. You add `microRitual` and `wardrobeReflection`. |
| `TarotRecencyTracker` | `TarotRecencyTracker.swift` (326 lines) | Singleton. Call **`TarotRecencyTracker.shared.getRecentSelections(profileHash:referenceDate:)`** to get recently shown cards. Call **`.storeCardSelection(_:profileHash:date:)`** after choosing. The tracker requires a `profileHash` and `date` — both are available from `snapshot.profileHash` and `snapshot.generatedAt`. |
| `TarotCards.json` | `Cosmic Fit/Resources/` (or wherever the bundle loads from) | Loaded by `TarotCardSelector.loadAllCards()` or equivalent. Check the existing loader. |
| `DailyEnergySnapshot` | `DailyFitTypes.swift` (Phase 0) | Your input from Stage 1. |
| `DailyFitCalibration` | `DailyFitTypes.swift` (Phase 0) | Provides `SelectionWeights`. |
| `VibeBreakdown` | `VibeBreakdown .swift` | Part of the snapshot. |
| `DerivedAxes` | `DerivedAxesEvaluator.swift` | Part of the snapshot. |
| `Energy` | `VibeBreakdown .swift` | Enum for energy names. |

### Loading Tarot Cards

Before building your scoring, study how the existing `TarotCardSelector` loads cards. Look for a method like `loadAllCards()` or check if cards are loaded from `TarotCards.json` via `Bundle.main`. You must use the same loading mechanism — do NOT create a new JSON file or modify the existing one. The card data is correct; the scoring was the problem.

Read `TarotCard.swift` fully. The `TarotCard` struct has:
- `energyAffinity: [String: Double]` — maps energy names (e.g. "classic", "drama") to affinity scores (0–1 range).
- `axesAffinity: [String: Double]?` — maps axis names (e.g. "action", "tempo") to affinity scores. **Note:** These are on a **0–100 scale** in the JSON, not 0–1. The legacy system normalises mid-scoring by dividing by 10. You must normalise at load time.
- `styleEdits: [StyleEditVariant]?` — array of exactly 3 variants per card (I, II, III).

---

## 4. What You Are Building

### 4.1 Public Method (Partial — tarot + styleEdit only)

```swift
enum BlueprintLensEngine {

    static func selectTarotAndStyleEdit(
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default
    ) -> (tarotCard: TarotCard, styleEditVariant: StyleEditVariant)
}
```

Phase 4 will add the full `generatePayload(...)` method. For now, build and test the tarot + style edit selection in isolation.

> **`profileHash` note:** `DailyEnergySnapshot` carries `profileHash` and `generatedAt` (set in Phase 2). The `TarotRecencyTracker` API requires both, so this method extracts them from the snapshot — no additional arguments needed.

### 4.2 Tarot Card Selection Algorithm

1. **Load all cards** from the JSON bundle.
2. **Normalise card data** — for each card, if `axesAffinity` values are on the 0–100 scale, divide by 100 to get 0–1. Do this once at load, cache the result.
3. **Get recent cards** from `TarotRecencyTracker.shared.getRecentSelections(profileHash: snapshot.profileHash, referenceDate: snapshot.generatedAt)`. This returns recent selections scoped to the user's profile.
4. **Score each card** against the snapshot:

```
cardScore = (vibeScore × selectionWeights.vibeWeight)
          + (axisScore × selectionWeights.axisWeight)
          + (transitBoost × selectionWeights.transitBoost)
          - recencyPenalty
```

**Vibe score** (0–1):
- Compute cosine similarity between the card's `energyAffinity` vector and the snapshot's vibe profile (normalised to fractions of 21).
- The vibe profile must be normalised to sum to 1.0 before comparison: `profile[energy] = vibeBreakdown.value(for: energy) / 21.0`.
- **This fixes the legacy bug where vibe was divided by 100 instead of 21.**

**Axis score** (0–1):
- Compute cosine similarity between the card's normalised `axesAffinity` and the snapshot's axes (normalised to 0–1 by dividing by 10).
- If card has no `axesAffinity`, axis score = 0.5 (neutral).

**Transit boost** (0–1):
- For each dominant transit in the snapshot, check if the transiting planet's energy affinities align with the card's energy affinities. Sum alignment, cap at 1.0.
- This gives a bonus to cards that resonate with the day's active transits.

**Recency penalty** (0–0.3):
- If the card was shown in the last 3 days: penalty = 0.3.
- If shown in the last 7 days: penalty = 0.15.
- Otherwise: penalty = 0.

5. **Select the highest-scoring card.**
6. **Record selection** via `TarotRecencyTracker.shared.storeCardSelection(selectedCard, profileHash: snapshot.profileHash, date: snapshot.generatedAt)`.
7. **Deterministic tie-break:** If two cards have scores within 0.01 of each other, use `snapshot.dailySeed` to pick between them deterministically.

### 4.3 Style Edit Variant Selection — Rotation-Based

Variant selection does **NOT** use energy scoring. Each card has exactly 3 variants (I, II, III). Variants are **cycled sequentially** per user per card — guaranteeing no meaningful repetition:

1. Query `TarotVariantRotationTracker` (see §3.6) for the last variant index used for this card + profileHash.
2. Next variant index = `(lastIndex + 1) % 3`.
3. Select `tarotCard.styleEdits[nextIndex]`.
4. Record the new index via the tracker.
5. If `tarotCard.styleEdits` is `nil` or empty (defend), construct a minimal fallback `StyleEditVariant` with the card's name, empty emphasis maps, and placeholder strings for `microRitual` / `wardrobeReflection`.

**Why rotation, not scoring?** The 3 variants are editorially authored — each is equally valid for the card. The goal is freshness across repeated draws of the same card over the year. Scoring would repeatedly pick the "best match" and the user would never see the other two.

### 4.4 Cosine Similarity Helper

Build a private helper:

```swift
private static func cosineSimilarity(_ a: [String: Double], _ b: [String: Double]) -> Double
```

Standard cosine similarity formula. Handle the zero-vector case (return 0.0 if either vector is all zeros).

### 4.5 Modify `StyleEditVariant` (in `TarotCard.swift`)

**This is the one existing file you modify in this phase.** Add two new fields to the struct:

```swift
struct StyleEditVariant: Codable {
    let variant: String
    let title: String
    let description: String          // The "Style Edit" paragraph
    let energyEmphasis: [String: Double]
    let axesEmphasis: [String: Int]
    let microRitual: String?         // NEW — "The Micro-Ritual" text
    let wardrobeReflection: String?  // NEW — "The Wardrobe Reflection" question
}
```

Both new fields are **optional** (`String?`) for backward compatibility — existing JSON entries that lack them will decode to `nil`. When a variant is displayed, the UI treats `nil` as "not available" and hides that section gracefully.

**Codable handling:** Because `StyleEditVariant` already uses synthesised `Codable` conformance and the fields have default-nil behaviour via optionality, no custom `init(from:)` is needed.

### 4.6 `TarotVariantRotationTracker`

Create a new small file:

```
Cosmic Fit/InterpretationEngine/TarotVariantRotationTracker.swift
```

This tracks which variant index was last shown for each card, per user. Lightweight `UserDefaults`-backed storage:

```swift
final class TarotVariantRotationTracker {
    static let shared = TarotVariantRotationTracker()

    /// Returns the next variant index (0, 1, or 2) for the given card and user.
    /// Automatically advances the rotation.
    func nextVariantIndex(forCard cardName: String, profileHash: String) -> Int

    /// Peek at the next index without advancing. Useful for tests.
    func peekNextVariantIndex(forCard cardName: String, profileHash: String) -> Int

    /// Reset all rotation state. Test-only.
    func resetAll()
}
```

**Storage key format:** `"variantRotation_\(profileHash)_\(cardName)"` → stores an `Int` (0, 1, or 2).

**Logic:**
1. Read current index from UserDefaults (default **-1** if key absent).
2. `nextIndex = (currentIndex + 1) % 3`
3. Store `nextIndex`.
4. Return `nextIndex`.

The first draw of any card returns variant index **0** (variant I), since `(-1 + 1) % 3 == 0`. Subsequent draws cycle 1 → 2 → 0 → 1 → 2 → ...

---

## 5. What You Must NOT Do

- **Do not modify `TarotCardSelector.swift`.**
- **Do not modify `TarotCards.json`.** The new `microRitual` / `wardrobeReflection` fields will be added to the JSON in a separate content task. Your code must handle them being absent (hence the optionality).
- **Do not modify `TarotRecencyTracker.swift`.** Use its public API as-is.
- **You WILL modify `TarotCard.swift`** — only to add the two new optional fields to `StyleEditVariant` (see §4.5). No other changes to that file.
- **Do not build palette, texture, or pattern selection.** That's Phase 4.
- **Do not add `print()` statements.**
- **Do not replicate the `/100` normalisation bug.** Vibe energies sum to 21, so normalise by 21.

---

## 6. Acceptance Tests

Create a test file:

```
Cosmic FitTests/BlueprintLensEngine_TarotStyleEdit_Tests.swift
```

### Required Tests

| # | Test | What It Validates |
|---|---|---|
| T3.1 | `testTarotCardSelected` | Given any valid snapshot, a tarot card is always returned (never crashes). |
| T3.2 | `testStyleEditVariantSelected` | Given any valid snapshot, a style edit variant is always returned. |
| T3.3 | `testSelectionDeterministic` | Same snapshot produces the same card and variant on repeated calls (assuming recency state is the same). |
| T3.4 | `testHighDramaSnapshotSelectsDramaticCard` | A snapshot with drama=10, others=2-3 selects a card with high drama affinity (verify `card.energyAffinity["drama"]! >= 0.5`). |
| T3.5 | `testHighRomanticSnapshotSelectsRomanticCard` | A snapshot with romantic=10 selects a card with high romantic affinity. |
| T3.6 | `testRecencyPreventsRepetition` | Select a card, record it, then select again — the second selection is different (unless there's only one candidate, which won't happen with 78 tarot cards). |
| T3.7 | `testVibeNormalisedBy21Not100` | Create a snapshot with `classic=21, others=0`. Compute the internal vibe vector. Assert `classic` component is `1.0` (= 21/21), NOT `0.21` (= 21/100). This is a regression test for the legacy bug. |
| T3.8 | `testAxesNormalisedAtLoad` | Load a card. If its raw `axesAffinity["action"]` is, say, 80, the normalised version used in scoring should be 0.8. Verify this is done at load, not during scoring. |
| T3.9 | `testTransitBoostInfluencesSelection` | A snapshot with a dominant Mars transit should score Mars-aligned cards higher than a snapshot with the same vibe but no transits. |
| T3.10 | `testVariantRotationCyclesThrough3` | Draw the same card 3 times for the same profileHash. Assert the 3 returned variants have 3 different `.variant` values (I, II, III in some order). |
| T3.11 | `testFallbackWhenNoAxesAffinity` | A card with nil `axesAffinity` still gets scored (axis score defaults to 0.5). |
| T3.12 | `testCosineSimilarityIdenticalVectors` | `cosineSimilarity(a, a) ≈ 1.0`. |
| T3.13 | `testCosineSimilarityOrthogonalVectors` | Two vectors with no overlap produce similarity ≈ 0.0. |
| T3.14 | `testAllCardsLoadSuccessfully` | Load cards from JSON, assert count >= 22 (Major Arcana at minimum). |
| T3.15 | `testVariantRotationWrapsAround` | Draw the same card 6 times. Assert the variant pattern repeats (indexes cycle 0,1,2,0,1,2). |
| T3.16 | `testVariantRotationIsolatedPerProfile` | Draw a card once for profileHash "A", then once for profileHash "B". They should both get the same variant index (rotation is per-user-per-card). |
| T3.17 | `testStyleEditVariantNewFieldsDecodeGracefully` | Create a `StyleEditVariant` without `microRitual`/`wardrobeReflection` in JSON. Assert they decode as `nil` without crashing. |
| T3.18 | `testStyleEditVariantNewFieldsRoundTrip` | Create a variant with both new fields populated, encode/decode, assert the values survive. |

### Test Fixtures

Create snapshot fixtures that emphasise specific energies:
- Drama-heavy: `VibeBreakdown(classic: 1, playful: 1, romantic: 1, utility: 1, drama: 10, edge: 7)`
- Romantic-heavy: `VibeBreakdown(classic: 2, playful: 1, romantic: 10, utility: 2, drama: 3, edge: 3)`
- Balanced: `VibeBreakdown(classic: 4, playful: 3, romantic: 4, utility: 3, drama: 4, edge: 3)`

---

## 7. Definition of Done

- [ ] `BlueprintLensEngine.swift` exists and compiles.
- [ ] `TarotVariantRotationTracker.swift` exists and compiles.
- [ ] `StyleEditVariant` in `TarotCard.swift` has `microRitual: String?` and `wardrobeReflection: String?`.
- [ ] `selectTarotAndStyleEdit(snapshot:calibration:)` works correctly.
- [ ] Variant selection uses rotation (cycling I→II→III), not energy scoring.
- [ ] All 18 tests pass.
- [ ] Vibe energies are normalised by `/21.0` — the `/100` bug is NOT present.
- [ ] Card axes data is normalised at load time, not mid-scoring.
- [ ] `TarotRecencyTracker` is used for card recency — no custom card recency logic.
- [ ] Only `TarotCard.swift` is modified among existing files (2 optional fields added to `StyleEditVariant`).
- [ ] No `print()` statements.
- [ ] `BlueprintLensEngine.swift` is under 350 lines. `TarotVariantRotationTracker.swift` is under 60 lines.

---

## 8. What Comes Next

Phase 4 adds palette, texture, and pattern selection to `BlueprintLensEngine`, then assembles the complete `DailyFitPayload`.

---

## 9. Standards

- **No print statements.**
- **No force-unwraps.** Use safe unwrapping everywhere.
- **Swift naming conventions.**
- **Indentation:** 4 spaces.
- **Line length:** prefer under 120 characters.
- **Stateless engine.** `BlueprintLensEngine` is an enum (no instances), all methods are static.
- **All internal methods are `private static`.**
