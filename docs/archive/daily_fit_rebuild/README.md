# Daily Fit Blueprint-First Rebuild — Phase Handoff Index

**Created:** 10 May 2026
**Source plan:** `.cursor/plans/daily_fit_audit_c4ef4ff1.plan.md`
**Source audit:** `docs/daily_fit_redesign_audit.md`

---

## Overview

This directory contains 8 handoff documents that together specify the complete rebuild of the Daily Fit pipeline from a legacy token-based system to a clean 2-stage architecture:

1. **Stage 1 — DailyEnergyEngine:** natal chart + transits + lunar phase + progressed chart → `DailyEnergySnapshot`
2. **Stage 2 — BlueprintLensEngine:** `CosmicBlueprint` + `DailyEnergySnapshot` → `DailyFitPayload`

Each phase is designed to be completed by a single AI developer without context overload. Phases are sequential — each depends on the prior phase's output.

---

## Phase Dependency Chain

```
Phase 0 ─── Foundation Types & Contracts
   │
   ├── Phase 1 ─── Vibe Profile Engine (Stage 1, part 1)
   │      │
   │      └── Phase 2 ─── Axes, Transits & Snapshot (Stage 1, part 2)
   │             │
   │             ├── Phase 3 ─── Tarot & StyleEdit Selection (Stage 2, part 1)
   │             │      │
   │             │      └── Phase 4 ─── Palette, Textures & Full Assembly (Stage 2, part 2)
   │             │             │
   │             │             └── Phase 5 ─── UI Integration & Pipeline Wiring
   │             │                    │
   │             │                    └── Phase 6 ─── Calibration & Diagnostics
   │             │                           │
   │             │                           └── Phase 7 ─── Legacy Code Removal
```

---

## Phase Summary

| Phase | Document | New Files | Modified Files | Lines (approx) | Test Count |
|---|---|---|---|---|---|
| **0** | [PHASE_0_FOUNDATION_TYPES.md](PHASE_0_FOUNDATION_TYPES.md) | `DailyFitTypes.swift`, `DailyFitTypes_Tests.swift` | None | ~250 | 18 |
| **1** | [PHASE_1_VIBE_PROFILE_ENGINE.md](PHASE_1_VIBE_PROFILE_ENGINE.md) | `DailyEnergyEngine.swift`, `DailyEnergyEngine_VibeProfile_Tests.swift` | None | ~280 | 12 |
| **2** | [PHASE_2_AXES_AND_SNAPSHOT.md](PHASE_2_AXES_AND_SNAPSHOT.md) | `DailyEnergyEngine_Snapshot_Tests.swift` | `DailyEnergyEngine.swift` (+200) | ~200 added | 14 |
| **3** | [PHASE_3_TAROT_AND_STYLEEDIT.md](PHASE_3_TAROT_AND_STYLEEDIT.md) | `BlueprintLensEngine.swift`, `TarotVariantRotationTracker.swift`, `BlueprintLensEngine_TarotStyleEdit_Tests.swift` | `TarotCard.swift` (+2 fields) | ~400 | 18 |
| **4** | [PHASE_4_PALETTE_TEXTURES_ASSEMBLY.md](PHASE_4_PALETTE_TEXTURES_ASSEMBLY.md) | `BlueprintLensEngine_Payload_Tests.swift` | `BlueprintLensEngine.swift` (+350) | ~350 added | 26 |
| **5** | [PHASE_5_UI_INTEGRATION.md](PHASE_5_UI_INTEGRATION.md) | `EssenceTriangleView.swift`, Optional: `DailyFitPayloadStorage.swift` | `CosmicFitTabBarController.swift`, `DailyFitViewController.swift` | ~500 changed | 11 + manual (20 items) |
| **6** | [PHASE_6_CALIBRATION_DIAGNOSTICS.md](PHASE_6_CALIBRATION_DIAGNOSTICS.md) | `DailyFitDiagnostics.swift`, `DailyFitCalibration_Tests.swift` | `DailyEnergyEngine.swift` (+≤30), `BlueprintLensEngine.swift` (+≤30) | ~350 | 12 |
| **7** | [PHASE_7_LEGACY_REMOVAL.md](PHASE_7_LEGACY_REMOVAL.md) | None | ~10 files edited, ~10 files deleted | -7,000 removed | 7 + manual |

**Total new code:** ~1,200 lines across 4 new engine files
**Total removed code:** ~7,000–8,000 lines of legacy code
**Net change:** roughly -6,000 lines

---

## Quality Standards (All Phases)

Every phase enforces these standards:

- **No `print()` statements** in production code.
- **No force-unwraps.** All code uses safe unwrapping.
- **No string-matching for data mapping.** Typed enums and dictionaries only.
- **All calibration weights are normalised** and live in `DailyFitCalibration`.
- **All methods are testable in isolation** with fixture data.
- **Swift naming conventions.** lowerCamelCase for properties, UpperCamelCase for types.
- **4-space indentation, no tabs.** Lines under 120 characters.
- **Doc comments on all public types and methods.**

---

## Open Questions (Resolved)

The audit identified 5 open questions. These are the decisions for this rebuild:

| # | Question | Decision |
|---|---|---|
| 1 | Tarot as headline anchor vs one-of-many | **Headline anchor.** Tarot card remains the emotional centrepiece of the Daily Fit. |
| 2 | V1 section scope | **Palette + textures + optional pattern + tarot/styleEdit + vibe bars + axes.** No prose sections for V1. |
| 3 | Progressed chart handling | **Stage 1 input.** Progressed chart feeds into the energy snapshot as a slow-evolution signal (~15% weight). |
| 4 | Energy names | **Keep "Utility" for now.** Can be renamed in a future UI-only change without engine impact. |
| 5 | Calibration format | **Swift constants** (compile-time, in `DailyFitCalibration.default`). Can migrate to JSON later if needed for remote config. |

---

## Spec-Fix Decisions (10 May 2026)

Post-audit corrections applied to all phase documents. These are binding for all phases:

| # | Issue | Resolution |
|---|---|---|
| 1 | `profileHash` threading | **`profileHash` is a stored property on `DailyEnergySnapshot`.** Stage 2 reads it from the snapshot — no separate argument needed. |
| 2 | `generatedAt` determinism | **Set from the supplied `date` parameter, NOT `Date()`.** Production callers pass `Date()`; tests pass a fixed date. Applies to both `DailyEnergySnapshot` and `DailyFitPayload`. |
| 3 | `Equatable` on top-level structs | **`DailyEnergySnapshot` and `DailyFitPayload` are `Codable` only** (not `Equatable`). Referenced external types (`TarotCard`, `StyleEditVariant`, `VibeBreakdown`, `DerivedAxes`) are not `Equatable` and Phase 0 must not modify them. Tests use **field-level assertions**. New nested types we own (`DailyTransitSummary`, `LunarContext`, `DailyColourPick`, `DailyPaletteSelection`) conform to both `Codable` and `Equatable`. |
| 4 | Phase 6 engine hooks | **Targeted `internal` hooks are permitted** (≤30 lines per engine file). No public API changes. No behaviour changes. |
| 5 | `BlueprintColour` field names | The property is **`hexValue: String`** (not `hex`). The role is a typed **`ColourRole` enum** (not a raw `String`). All specs updated. |
| 6 | `TarotCard` style edits property | The property is **`styleEdits: [StyleEditVariant]?`** (not `styleEditVariants`). |
| 7 | `TarotRecencyTracker` API | Correct methods: **`getRecentSelections(profileHash:referenceDate:)`** and **`storeCardSelection(_:profileHash:date:)`**. |
| 8 | Phase 6 non-Codable tuples | Replaced with concrete `Codable` structs: **`ScoredColourEntry`**, **`ScoredTextureEntry`**. |
| 9 | UI content redesign | **Figma-specified layout replaces everything below tarot card.** New sections: Daily Ritual, Vibrancy, Contrast, Metal Tone, Essence triangle, Wardrobe Reflection, Tomorrow teaser. Removed: Style Edit heading, pill sliders, vibe bars, takeaway. |
| 10 | Variant selection method | **Rotation-based cycling (I→II→III→I...)**, not energy scoring. Each variant is editorially authored and equally valid. |
| 11 | `StyleEditVariant` new fields | Added **`microRitual: String?`** and **`wardrobeReflection: String?`** (optional for backward compat with existing JSON). |
| 12 | New payload fields | Added **`essenceTriangle`**, **`silhouetteProfile`**, **`vibrancy`**, **`contrast`**, **`metalTone`** to `DailyFitPayload`. |
| 13 | New UI component | **`EssenceTriangleView`** — triangular radar chart with barycentric point plotting. |

---

## Daily Fit Content Redesign (Figma-specified)

The new pipeline produces a fundamentally different content layout below the tarot card. The tarot card reveal UX is unchanged.

**New layout (scroll order below tarot):**

| # | Section | Data Source | New/Existing |
|---|---|---|---|
| 1 | Tarot paragraph | `styleEditVariant.description` | Existing (renamed header) |
| 2 | Daily Ritual | `styleEditVariant.microRitual` | NEW (hidden if nil) |
| 3 | Outfit Breakdown header | Static | Existing |
| 4 | Style Palette (3 swatches) | `dailyPalette` | Existing (renamed header) |
| 5 | Vibrancy scale | `vibrancy` (0–1) | NEW (replaces pill sliders) |
| 6 | Contrast scale | `contrast` (0–1) | NEW (replaces pill sliders) |
| 7 | Metal Tone (Cool/Mixed/Warm) | `metalTone` (0–1) | Modified |
| 8 | Essence triangle | `essenceTriangle` (3 floats) | NEW (replaces vibe bars) |
| 9 | Silhouette (3 sliders) | `silhouetteProfile` (3 floats) | Modified (dynamic values, new labels) |
| 10 | Wardrobe Reflection | `styleEditVariant.wardrobeReflection` | NEW (hidden if nil) |
| 11 | Tomorrow teaser + CTA | Static + pipeline(date+1) | NEW |

**Key design principle: Blueprint-as-Lens.** All style-prescriptive outputs (palette, vibrancy, contrast, metal tone, silhouette) are constrained by the user's Blueprint. The Essence triangle is the sole unconstrained section — it shows raw cosmic energy.

**Variant rotation:** Each tarot card has 3 editorially authored variants (I, II, III) with paragraph, micro-ritual, and wardrobe reflection. Variants cycle sequentially per user per card to avoid repetition.

---

## Milestone: On-Device Testing

After **Phase 5 is complete**, the app runs on the new pipeline and can be tested on device. Phases 6 and 7 are refinement and cleanup — the core functionality is live at Phase 5.

After **Phase 7 is complete**, the codebase is clean, the legacy code is gone, and the Daily Fit is fully running on the new 2-stage architecture. This is the final deliverable.
