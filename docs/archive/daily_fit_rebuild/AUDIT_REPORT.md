# Phase Handoff Audit Report — 10 May 2026

**Purpose:** Cross-reference every phase document against the real codebase to identify mismatches, ambiguities, or gaps that would block an AI developer from producing production-ready code.

**Original verdict:** 3 critical blockers, 4 high-severity issues, several medium/low.

**Post-fix status:** All critical and high issues have been patched. See "Amendments Applied" at the end of this report.

---

## Phase 0: Foundation Types — PASS with 1 note

**Status:** Ready to hand off.

| # | Severity | Issue | Detail |
|---|---|---|---|
| 0.1 | Low | `DailyColourPick.role` is `String`, source is `ColourRole` enum | Intentional — serialise enum to string for the lighter struct. But the spec should add a one-line note: "Convert `BlueprintColour.role` to its `.rawValue` string when constructing `DailyColourPick`." |

No blockers. Types are clean, tests are comprehensive (18), fixtures use deterministic dates. The `EssenceTriangle` and `SilhouetteProfile` additions are well-specified.

---

## Phase 1: Vibe Profile Engine — PASS

**Status:** Ready to hand off. Not amended in this pass. No issues found in previous audit that weren't already resolved.

---

## Phase 2: Axes & Snapshot — PASS

**Status:** Ready to hand off. The `profileHash` and `generatedAt` fixes from the spec-fix pass are clean. Field-level test assertions are correctly specified.

---

## Phase 3: Tarot & StyleEdit — PASS with 2 notes

**Status:** Ready to hand off after minor clarification.

| # | Severity | Issue | Detail |
|---|---|---|---|
| 3.1 | Low | Variant rotation initial index is ambiguous | The spec offers two options (start at 0 vs -1) but doesn't decide. **Fix:** State explicitly: "Initialise at -1 so the first draw returns index 0 (variant I)." This is the intuitive behaviour. |
| 3.2 | Low | `TarotCards.json` content authoring not scoped | The spec correctly says `microRitual` and `wardrobeReflection` are optional for backward compat. But it should note that a **separate content task** is needed to populate the JSON with the authored ritual/question text for all 78 cards × 3 variants. Without this data, those UI sections will always be hidden. |

The variant rotation logic is clean. The `TarotRecencyTracker` API references now match the codebase exactly (`storeCardSelection(_:profileHash:date:)`, `getRecentSelections(profileHash:referenceDate:)`). The `styleEdits` property name is correct.

---

## Phase 4: Palette, Outfit Breakdown & Assembly — NEEDS FIXES (3 critical, 1 high)

**Status:** Blocked until fixes applied. Three issues will cause compile errors.

| # | Severity | Issue | Detail |
|---|---|---|---|
| **4.1** | **CRITICAL** | **`Saturation` enum has `.muted`, not `.medium`** | Phase 4 §4.5 maps `.soft` → 0.25, **`.medium`** → 0.50, `.rich` → 0.75. The actual enum in `Domain.swift` is `.soft`, **`.muted`**, `.rich`. Using `.medium` will cause a compile error. **Fix:** Change `.medium → 0.50` to `.muted → 0.50`. |
| **4.2** | **CRITICAL** | **`HardwareSection` field names wrong** | Phase 4 §3 says `hardware.metals` and `hardware.stones`. The actual struct has **`recommendedMetals: [String]`** and **`recommendedStones: [String]`**. Also has `metalsText`, `stonesText`, `tipText` (narrative strings). **Fix:** Replace `hardware.metals` with `hardware.recommendedMetals` and `hardware.stones` with `hardware.recommendedStones`. |
| **4.3** | **CRITICAL** | **`StyleCoreSection` has no structured data** | Phase 4 §4.9 says "Read `blueprint.styleCore` and `blueprint.code` to derive the user's permanent silhouette lean." But `StyleCoreSection` only has `narrativeText: String` — a free-text AI-generated paragraph. There's no structured data to programmatically extract masculine/feminine, angular/rounded, or structured/draped preferences. `CodeSection` has `leanInto: [String]`, `avoid: [String]`, `consider: [String]` — these are directive strings like "lean into structured shoulders" which _could_ be keyword-matched, but the spec doesn't acknowledge this limitation or provide a keyword mapping. **Fix:** Either (a) provide an explicit keyword-to-silhouette mapping for `CodeSection.leanInto`/`avoid`/`consider` strings, similar to the texture keyword mapping, or (b) state that silhouette baseline defaults to 0.5 on all three axes until structured silhouette data is added to the Blueprint, with axes modulation providing all variation. Option (b) is safer for V1. |
| 4.4 | High | Saturation table in §3 also says "Medium" | The Blueprint data table (§3) lists `Saturation` enum cases as "Soft, Medium, Rich". The actual cases are Soft, **Muted**, Rich. This table will mislead the developer even before they hit the algorithm. **Fix:** Correct the table to "Soft, Muted, Rich". |

The Blueprint-as-Lens principle table is excellent. The essence triangle derivation is mathematically clean. The vibrancy/contrast formulas are reasonable once the enum name is fixed. The 26-test suite is comprehensive and the dual Blueprint fixture requirement ("warm user" + "cool user") is a strong testing pattern.

---

## Phase 5: UI Integration — NEEDS FIXES (2 high, 2 medium)

**Status:** Handoffable but will cause significant developer confusion without fixes.

| # | Severity | Issue | Detail |
|---|---|---|---|
| **5.1** | **High** | **Diamond scale views can't be updated dynamically** | The existing `createBipolarSlider(leftLabel:rightLabel:position:)` and `createToneSlider()` bake the diamond position into AutoLayout constraint multipliers at creation time. There is no stored constraint reference to modify later. The spec references `updateDiamondScale(vibrancyScale, value:)` and `updateSilhouetteSliders(with:)` — but these methods would need the developer to either: (a) store the `leftSpacer.widthAnchor` constraint and deactivate/recreate it on update, (b) destroy and recreate the views, or (c) refactor to use `layoutSubviews()` with a stored `position` property. **Fix:** Add a note in §3.2 under "Helper: Diamond Scale" explaining that the existing slider approach bakes position into constraints. The developer must either refactor the slider creation to support dynamic updates (preferred — store the multiplier constraint and replace it) or create the scales fresh in `updateContentFromPayload()` each time. Provide a concrete pattern. |
| **5.2** | **High** | **Tomorrow button: VC lacks access to pipeline inputs** | The `tomorrowButtonTapped()` handler needs natal chart, progressed chart, transits, moon phase, and Blueprint to run the pipeline. `DailyFitViewController` doesn't have these — they live in `CosmicFitTabBarController`. **Fix:** Specify the interaction pattern: either (a) a delegate/closure passed from the tab bar controller, (b) pass a lightweight "pipeline context" struct to the VC alongside the payload, or (c) the button simply navigates/signals the tab bar to regenerate with tomorrow's date. Option (c) is simplest. |
| 5.3 | Medium | Tone slider currently has no "Mixed" centre label | The Figma shows Cool / Mixed / Warm but the existing `createToneSlider()` only has "Cool" and "Warm". The spec should explicitly note that a third label needs to be added to the centre of the track. |
| 5.4 | Medium | Current silhouette labels documented for developer reference | The spec says to change labels but doesn't state what the _current_ labels are. Developer needs to know they're changing "Curvy" → "Rounded" and "Relaxed" → "Draped" specifically. **Fix:** Add a mapping table: current → new. |

The `EssenceTriangleView` spec is good — barycentric coordinates, styling details, 120-line limit. The content layout table is clear. The manual verification checklist (20 items) is thorough.

---

## Phase 6: Calibration & Diagnostics — PASS with 1 note

**Status:** Ready to hand off.

| # | Severity | Issue | Detail |
|---|---|---|---|
| 6.1 | Low | `VariantScoreEntry` removed but not all references may be cleaned | The variant rotation change means there are no variant "scores" to log. The struct now has `variantRotationIndex: Int` which is correct. Verify the calibration test descriptions in §3.2 don't still reference "variant scoring". |

The `ScaleDerivationTrace` and `SilhouetteDerivationTrace` additions are well-structured. The permission for targeted `internal` hooks (≤30 lines per engine file) is clearly stated and consistent with the "Do not modify" rules.

---

## Phase 7: Legacy Removal — PASS

**Status:** Ready to hand off. The `VibeBreakdownBarsView` audit note is correct — check if anything else uses it before deleting. The DailyFitViewController removal list correctly includes pill sliders, hardcoded silhouette, and takeaway. The tiered execution order is sound.

---

## Cross-cutting concerns

### 1. JSON content authoring is a dependency

Phases 3 and 5 assume that `TarotCards.json` will be populated with `microRitual` and `wardrobeReflection` text for all cards. This is a **content authoring task**, not a code task. Until done:
- The "Daily Ritual" section will be hidden (nil)
- The "Wardrobe Reflection" section will be hidden (nil)
- The variant rotation will cycle through identical-looking variants (same `description`, no ritual/question)

**Recommendation:** Create a separate workload for JSON content population. It can run in parallel with Phases 0–4 since it doesn't require code changes.

### 2. Silhouette baseline is the weakest derivation

The Blueprint has no structured silhouette data. `StyleCoreSection` is narrative text, `CodeSection` has directive strings. The spec's fallback to 0.5 baseline with axes-only modulation is the realistic V1 path, but it means the silhouette section will look the same for all users (only varying by daily axes), which undermines the Blueprint-as-Lens principle for that section.

**Recommendation:** Accept 0.5 baseline for V1. Add structured silhouette fields to `CosmicBlueprint` in a future Blueprint engine update.

### 3. `loadTarotCardImage(for:)` has print() statements

The existing method has multiple `print()` calls. Phase 5 adds a "no print() statements" standard. The developer will be confused about whether to clean up existing prints in methods they're calling but not modifying. **Recommendation:** Add a note: "Do not clean up print() statements in existing methods you're calling. Phase 7 handles legacy cleanup."

---

## Summary: What to fix before handoff

| Phase | Fix | Effort |
|---|---|---|
| **Phase 4** | Change `.medium` → `.muted` in Saturation mapping + table | 2 minutes |
| **Phase 4** | Change `hardware.metals` → `hardware.recommendedMetals`, `hardware.stones` → `hardware.recommendedStones` | 2 minutes |
| **Phase 4** | Resolve silhouette baseline — add keyword mapping for `CodeSection` or default to 0.5 | 10 minutes |
| **Phase 5** | Add dynamic slider update guidance (constraint replacement pattern or recreate-on-update) | 10 minutes |
| **Phase 5** | Specify tomorrow button interaction pattern (delegate/closure/signal) | 5 minutes |
| **Phase 5** | Add "Mixed" centre label note for tone slider | 1 minute |
| **Phase 5** | Add current → new silhouette label mapping table | 2 minutes |
| Phase 3 | Decide variant rotation initial index (-1) | 1 minute |
| Phase 3 | Note the JSON content authoring dependency | 2 minutes |

**Total estimated fix time: ~35 minutes**

After these fixes, all 8 phases are ready for delegation.

---

## Amendments Applied — 10 May 2026

All critical and high issues have been patched. The following changes were made:

| # | Phase | What Changed | Why |
|---|---|---|---|
| 1 | **Phase 4** §3 table + §4.5 | `Saturation` enum case `.medium` → `.muted` | The actual `Saturation` enum in `Domain.swift` has `.soft`, `.muted`, `.rich`. Using `.medium` would cause a compile error. |
| 2 | **Phase 4** §3 table + §4.7 + fixture | `hardware.metals` → `hardware.recommendedMetals`, `hardware.stones` → `hardware.recommendedStones` | The actual `HardwareSection` struct uses `recommendedMetals`/`recommendedStones`. Also added the narrative fields (`metalsText`, `stonesText`, `tipText`) to the table for completeness. |
| 3 | **Phase 4** §3 + §4.9 + fixture | Replaced vague "read `blueprint.styleCore`" with concrete `CodeSection` keyword-scan mapping | `StyleCoreSection` only has `narrativeText: String` — no structured data to extract. Provided an explicit keyword → axis mapping table, scoring method, and neutral-default fallback. Test fixture updated with concrete `leanInto` strings. |
| 4 | **Phase 5** §3.2 | Replaced placeholder `updateDiamondScale` with concrete constraint-replacement pattern | Existing `createBipolarSlider`/`createToneSlider` bake position into constraint multipliers at creation time — can't be updated. Added `createDiamondScale` pattern with stored constraint references and `viewDidLayoutSubviews` guidance. Also noted "Mixed" centre label for metal tone. |
| 5 | **Phase 5** §3.2 + §3.4 + tab bar wiring | Added `generateForDateHandler: ((Date) -> Void)?` closure and wiring | `DailyFitViewController` does not own pipeline inputs (natal chart, transits, Blueprint). The tab bar provides a closure at VC creation time. Also noted that `generateAndCacheDailyVibe` needs a `forDate:` parameter. |
| 6 | **Phase 3** §4.6 + T3.15 | Set rotation initial index to -1, updated cycle pattern | Removed "choose whichever" ambiguity. First draw now returns index 0 (variant I), which is the intuitive behaviour. Test T3.15 updated to match. |
| 7 | **Phase 0** §4.2 | Added `.rawValue` conversion note on `DailyColourPick.role` | Source `BlueprintColour.role` is a `ColourRole` enum, output `DailyColourPick.role` is `String`. One-line note prevents developer confusion. |

### What was NOT amended (and why)

| Audit finding | Why skipped |
|---|---|
| Phase 5 silhouette label mapping table | Already documented in the spec at §3.2 key mapping table: "Angular / Rounded (was 'Curvy')" and "Structured / Draped (was 'Relaxed')". |
| Phase 3 JSON content authoring dependency | Already documented in §5: "Do not modify `TarotCards.json`. The new fields will be added in a separate content task." |
| Phase 6 `VariantScoreEntry` cleanup | Already verified clean — `variantRotationIndex: Int` is present, no stale references remain. |
| Existing `print()` statements in `loadTarotCardImage` | Phase 5 spec says "No `print()` statements" for new code. Cleaning up existing methods is Phase 7's scope. No ambiguity for the developer. |
| `ContrastLevel.medium` in §4.6 | The `ContrastLevel` enum genuinely has `.medium` (unlike `Saturation`). This was correctly specified. |
