# Cosmic Fit — Test crashes / failures hand-off

Hand-off for another developer (or AI) with a fresh context window: stabilize `xcodebuild test`, especially under **parallel simulator clones**, and fix real assertion failures.

## Goal

Make **`xcodebuild test`** reliable so parallel clones don’t intermittently crash or fail unrelated tests, and fix any **real** assertion failures.

## Current status (baseline)

After the fixes described below:

- **`xcodebuild test … -only-testing:"Cosmic FitTests" -parallel-testing-enabled NO`** → **218 tests passed** (full `Cosmic FitTests` target).
- **Parallel runs** may still show **a small number of flaky failures** on one clone (see [Remaining issue](#remaining-issue-parallel-only)).

## What was wrong (diagnosis)

### 1. Parallel clone “everything fails at 0s”

Often **not** assertion failures — one **host process / clone crashes at launch** or mid-run; tests assigned to that clone show as failed.

### 2. `VSOP87Parser` race + fatal fallback

**File:** `Cosmic Fit/Core/Utilities/VSOP87Parser.swift`

Mutable static `planetData` / `useFallback` were loaded from multiple threads during parallel tests → dictionary corruption / races → path hit **`fatalError` in stub fallback** (`calculateFallbackHeliocentricCoordinates` / geocentric).

**Fix:** Thread-safe one-shot load via `static let` initialization, plus **real Keplerian fallback** instead of `fatalError`.

### 3. `AppDelegate` heavy launch in test host

**File:** `Cosmic Fit/App/AppDelegate.swift`

**Fix:** Early exit when running under tests (environment / XCTest class probe) — minimal window + empty root view controller.

### 4. Real test bugs (not infra)

- **Palette grid counts:** Fixture had “warm ivory” vs “cream” at very low ΔE → hit **dedup threshold** (~ΔE 4) → one fewer filled cell. **Fix:** fourth core swatch changed to a clearly distinct hex in `Cosmic FitTests/PaletteGridViewModel_Tests.swift`.
- **T4.4 palette roles:** Tests compared roles to `"Accent"` etc.; **`ColourRole.rawValue` is lowercase** → counts wrong. **Fix:** use `"accent"`, `"signature"`, `"statement"` in `Cosmic FitTests/BlueprintLensEngine_Payload_Tests.swift`.
- **Golden JSON:** Regenerated `docs/fixtures/palette_grid_golden_user_1.json` and `palette_grid_golden_user_2.json` after grid output changed.

## Remaining issue (parallel-only)

**Symptoms:** For example `testVariantRotationWrapsAround`, `testRecencyPreventsRepetition` failing **only** when Xcode uses **multiple simulator clones**.

**Likely cause:** **`TarotVariantRotationTracker` / recency state backed by `UserDefaults`** — simulator clones may share or contend on the **same app container**, so rotation/recency isn’t isolated per logical test process.

**Suggested fixes (pick one):**

- Mark the affected suite **`@Suite(.serialized)`** (Swift Testing) so those tests don’t run concurrently with others that touch the same storage.
- **Isolate persistence in tests:** inject a **suite-specific `UserDefaults` suite name** or **in-memory store** when the test environment is detected.
- **CI workaround:** run with **`-parallel-testing-enabled NO`** until isolation is implemented.

## How to reproduce

```bash
cd /path/to/cosmicfit

# Stable baseline (should be green after fixes)
xcodebuild test -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"Cosmic FitTests" \
  -parallel-testing-enabled NO

# Parallel path (may surface clone / UserDefaults flakiness)
xcodebuild test -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"Cosmic FitTests"
```

## If debugging crashes again

- Inspect **`~/Library/Logs/DiagnosticReports/Cosmic Fit-*.ips`** for `_assertionFailure`, `VSOP87Parser`, or main-thread XCTest waiter stacks.
- Distinguish **clone crash** (many unrelated tests fail on the same clone PID) vs **single assertion** (one test, clear message).

## Files worth knowing

| Area | Path |
|------|------|
| VSOP87 / race | `Cosmic Fit/Core/Utilities/VSOP87Parser.swift` |
| Test launch guard | `Cosmic Fit/App/AppDelegate.swift` |
| Palette fixtures / goldens | `Cosmic FitTests/PaletteGridViewModel_Tests.swift`, `docs/fixtures/palette_grid_golden_user_*.json` |
| Role strings fix | `Cosmic FitTests/BlueprintLensEngine_Payload_Tests.swift` |
| Rotation / recency | Search codebase for `TarotVariantRotationTracker`, `TarotRecencyTracker` |
