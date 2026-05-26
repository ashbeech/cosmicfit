# Daily Fit: Inspector ↔ App Parity — Handoff

**Status:** PARTIALLY FIXED — code changes applied but parity NOT yet verified  
**Date:** 2026-05-26  
**Prior chat:** [Inspector app parity investigation](2b1de7a7-0e56-4e94-8c4b-6d3ded42867d)  
**This chat:** [Parity fix implementation](910abd8e-6192-4e1f-b3c4-fc089a116fa0)

---

## Problem Statement

The Daily Fit output for the same user and same date differs between:
- **iOS app** running on device (debug build, `stage1_experimental`)
- **Inspector** at `localhost:7777` (started with `DAILY_FIT_ENGINE_ID=stage1_experimental ./run-inspector.sh`)

The expectation is identical output for identical inputs, since both run the same engine code.

---

## Test User

| Field | Value |
|---|---|
| Birth date | 12/11/1984 (1984-11-12) |
| Birth time | 12:00 |
| Location | London, England, United Kingdom |
| Coordinates | 51.5033768, -0.0795183 |
| Timezone | Europe/London |
| App User ID (profile hash) | `3533D487-C8B4-4A31-AE85-D11C01849B82` |
| Engine | `stage1_experimental` |
| Fingerprint | `e4bd253ccae1…` |
| Target date | 2026-05-26 |
| Device location (app GPS) | 53.912722, -0.165519 (Yorkshire) |

---

## App Output (ground truth from device log, 2026-05-26)

| Field | Value |
|---|---|
| Seed | 3816705321 |
| Tarot | Knight of Wands ("The Blaze") |
| Dominant energy | drama |
| Vibe budget | C=3 P=3 R=4 U=2 D=5 E=4 |
| Top 5 transits | Neptune Square Moon (1.00), Mars Conjunction Midheaven (0.95), Saturn Square Jupiter (0.89), Jupiter Square Pholus (0.87), Uranus Trine Vesta (0.81) |
| Essence top 3 | SENSUAL=1.000, DRAMA=0.922, MAXIMALIST=0.534 |
| Axes | Action=6.42, Tempo=5.40, Strategy=5.67, Visibility=9.08 |
| Colours | Deep Moonstone (#366064), Dark Sienna (#82312E), dark terracotta (#9E4E3A) |
| Vibrancy / Contrast / Metal | 0.76 / 0.65 / 0.69 |
| Silhouette (M/F, A/R, S/D) | 0.80, 0.59, 0.52 |
| Textures | vintage silk, soft flannel, washed cotton |
| Pattern | nautical stripes |
| Total transits detected | 57 |

---

## Inspector Output BEFORE fixes (Briar export, correct profile hash)

| Field | Value |
|---|---|
| Tarot | Ace of Cups ("The Intuition") |
| Dominant energy | Playful |
| Vibe budget | C=3 P=4 R=4 U=2 D=4 E=4 |
| Top 5 transits | Neptune Square Moon (1.00), Saturn Square Jupiter (0.89), Saturn Trine Uranus (0.76), Mars Opposition Pluto (0.71), Jupiter Trine Midheaven (0.67) |
| Essence top 3 | SENSUAL=1.000, MINIMAL=0.595, EFFORTLESS=0.291 |
| Axes | Action=5.49, Tempo=8.61, Strategy=7.06, Visibility=6.30 |
| Colours | Deep Moonstone (#366064), dark terracotta (#9E4E3A), slate (#5B6770) |
| Vibrancy / Contrast / Metal | 0.82 / 0.59 / 0.69 |
| Silhouette (M/F, A/R, S/D) | 0.58, 0.50, 0.65 |
| Textures | washed cotton, heritage knits, vintage silk |
| Pattern | soft gingham |
| Natal asteroids | ALL at 0.0000° (Chiron, Vesta, Pholus, Juno, Pallas, Ceres) |

---

## Root Cause Analysis

Two issues explain all divergence:

### Root Cause A: Device location missing from Inspector

`NatalChartCalculator.calculateTransitAspectToAngle()` (line 922) computes the **transit-time local MC/ASC at GPS coordinates** when device location is available. Without it, falls back to the natal birth-chart angles.

- App at Yorkshire (53.9°N): Mars is exactly conjunct the current local MC (orb 0.17°) → strength 0.95
- Inspector with no device location: uses natal MC (234° Scorpio) → Mars doesn't aspect it at all

This removes the app's #2 transit, shifting Drama 5→4 and Playful 3→4, flipping dominant energy from drama→playful and cascading through axes, essences, tarot, palette, everything.

### Root Cause B: Swiss Ephemeris files incomplete for asteroids

`AsteroidCalculator.position(of:at:)` calls `swe_calc_ut()` for named minor bodies (SE_CHIRON=15 through SE_VESTA=20). These bodies' data lives in `sepl_18.se1` (the main planetary file). The Inspector only had `seas_18.se1` in its Resources dir. Result: all asteroid natal positions returned 0°.

This removes app transits #4 (`Jupiter Square Pholus`) and #5 (`Uranus Trine Vesta`) — further diverging the vibe budget.

---

## Fixes Applied (this session)

### Fix 1: Device location parameter — APPLIED, NOT YET VERIFIED

**Changes made:**
- `Cosmic Fit/Core/Calculations/NatalChartCalculator.swift` — added `overrideDeviceLocation: CLLocationCoordinate2D? = nil` parameter to `calculateTransits()`. When provided, uses that instead of `LocationManager.shared.deviceLocation`. Backward-compatible (all existing callers use default `nil`).
- `inspector/Sources/CosmicFitInspectorLib/InspectorRequest.swift` — added `deviceLatitude: Double?` and `deviceLongitude: Double?` to `InspectOptions`
- `inspector/Sources/CosmicFitInspectorLib/InspectorEngine.swift` — added `import CoreLocation`, reads lat/lon from request options, constructs `CLLocationCoordinate2D`, passes to `calculateTransits(overrideDeviceLocation:)`
- `inspector/Sources/CosmicFitInspectorServer/Web/index.html` — added Device Location lat/lon input fields after Profile ID field
- `inspector/Sources/CosmicFitInspectorServer/Web/styles.css` — added `.device-location-row` (flex row with gap) and `.device-location-input` styles
- `inspector/Sources/CosmicFitInspectorServer/Web/app.js` — wired into `buildRequest()` (sends `deviceLatitude`/`deviceLongitude` in options), `readFormInputs()`, `applyFormInputs()` (session persistence), and markdown export table

### Fix 2: Missing ephemeris files + Moshier fallback — APPLIED, NOT YET VERIFIED

**Changes made:**
- `inspector/Resources/sepl_18.se1` — new symlink → `../../inspector/.build/checkouts/SwissEphemeris/Sources/SwissEphemeris/JPL/sepl_18.se1`
- `inspector/Resources/semo_18.se1` — new symlink → `../../inspector/.build/checkouts/SwissEphemeris/Sources/SwissEphemeris/JPL/semo_18.se1`
- `Cosmic Fit/Core/Calculations/AsteroidCalculator.swift` — `position(of:at:)` now checks `swe_calc_ut` return value; if negative (error), retries with `SEFLG_MOSEPH` (Moshier analytical ephemeris, no files needed). This is shared code (symlinked into Inspector) so both targets get the fix.
- `inspector/Sources/CosmicFitInspectorLib/ResourcePaths.swift` — `validateResources()` now checks for `sepl_18.se1` and `semo_18.se1` in addition to `seas_18.se1`

---

## Current State

- Inspector builds successfully (`swift build` — clean, 11s)
- Code changes compile and are wired end-to-end
- **NOT YET TESTED** — the user has not yet rebuilt the Inspector and re-exported to confirm parity

---

## What the Next Developer Needs to Do

### 1. Rebuild and verify parity

```bash
cd inspector
DAILY_FIT_ENGINE_ID=stage1_experimental ./run-inspector.sh
```

In Inspector UI, set:
- Birth date: `12/11/1984`, time `12:00`, location "London"
- Profile ID: `3533D487-C8B4-4A31-AE85-D11C01849B82`
- Device Location: `53.912722` / `-0.165519`
- Engine: stage1_experimental
- Target date: `26/05/2026`

Compare output against the app ground truth table above. Key checks:
- [ ] Natal asteroids no longer 0° (check natal chart export — Chiron should be ~63° Gemini, not 0° Aries)
- [ ] Transit count = 57 (matching app)
- [ ] Top transit #2 = Mars Conjunction Midheaven (strength ~0.95)
- [ ] Top transit #4 = Jupiter Square Pholus (strength ~0.87)
- [ ] Vibe budget = C=3 P=3 R=4 U=2 D=5 E=4
- [ ] Dominant = drama
- [ ] Tarot = Knight of Wands

### 2. If asteroids still 0°

The symlinks point into `.build/checkouts/` which is created by `swift build`. If a clean build wiped checkouts, the symlinks would break. Check:
```bash
ls -la inspector/Resources/*.se1
wc -c < inspector/Resources/sepl_18.se1   # should be ~484055 bytes
```

If broken, re-resolve:
```bash
cd inspector && swift package resolve
ls .build/checkouts/SwissEphemeris/Sources/SwissEphemeris/JPL/
```
Then re-create symlinks or copy the files directly.

Alternative: the Moshier fallback in `AsteroidCalculator` should catch this — if `sepl_18.se1` is missing, `swe_calc_ut` returns negative and the code retries with `SEFLG_MOSEPH`. If asteroids are STILL 0°, the fallback path may also be failing. Add debug logging:
```swift
// In AsteroidCalculator.position(of:at:)
if ret < 0 {
    let errMsg = String(cString: serr)
    print("[AsteroidCalc] SEFLG_SWIEPH failed for \(asteroid): \(errMsg)")
    // ... existing Moshier fallback ...
}
```

### 3. If transit count or dominant energy still differs

Remaining minor source of variance: **date instant**. The app uses `Date()` (wall clock at ~10:58 AM BST), the Inspector uses `DailyFitDateResolver.targetInstant` (local noon in birth timezone). This causes ~1 hour difference in Moon position and minor angle differences. If the transit list matches on 56/57 but one borderline aspect crosses in/out of orb, this is the cause.

Also check **tarot recency** — the app stores recency in `UserDefaults.standard`. If the Inspector has different recency history, the tarot card may differ even with identical vibe/axes. To eliminate: check "Reset tarot history" in Inspector before submitting.

### 4. If device location fields don't appear in UI

The Inspector serves static files from `Sources/CosmicFitInspectorServer/Web/`. After code changes, you must rebuild (`swift build`) for the resource bundle to update. If the old UI is cached in browser, hard-refresh (Cmd+Shift+R).

---

## Previously Fixed Issues (prior session)

1. **Engine preset mismatch** — User starts with `DAILY_FIT_ENGINE_ID=stage1_experimental`
2. **Profile hash mismatch** — Profile ID field added to Inspector UI
3. **Geocoding coordinate mismatch** — Inspector geocoder replaced with MapKit (`MKLocalSearch`)

---

## Key Files

| File | Role |
|---|---|
| `Cosmic Fit/Core/Calculations/NatalChartCalculator.swift` | Transit detection; `calculateTransits(overrideDeviceLocation:)` at line 482 |
| `Cosmic Fit/Core/Calculations/AsteroidCalculator.swift` | Asteroid positions with Moshier fallback |
| `inspector/Sources/CosmicFitInspectorLib/InspectorEngine.swift` | Inspector engine; builds device coord + passes to transit calc (line ~125-132) |
| `inspector/Sources/CosmicFitInspectorLib/InspectorRequest.swift` | Request structure (`deviceLatitude`, `deviceLongitude` in `InspectOptions`) |
| `inspector/Sources/CosmicFitInspectorLib/ResourcePaths.swift` | Resource path resolution + validation (all 3 .se1 files) |
| `inspector/Sources/CosmicFitInspectorServer/Web/index.html` | Inspector HTML (Device Location inputs) |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Inspector JS (`buildRequest`, `readFormInputs`, `applyFormInputs`, export) |
| `inspector/Sources/CosmicFitInspectorServer/Web/styles.css` | Device location input styles |
| `inspector/Resources/` | Ephemeris symlinks: `seas_18.se1`, `sepl_18.se1`, `semo_18.se1` |
| `Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift` | App's daily fit generation (line 775+) |
| `Cosmic Fit/Config/Dev.xcconfig` | App engine ID config |
| `inspector/run-inspector.sh` | Build + run script for Inspector |
