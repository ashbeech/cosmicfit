# Daily Fit: Inspector ↔ App Parity — Follow-up Handoff

**Status:** IN PROGRESS — multiple fixes applied; parity still NOT confirmed  
**Date:** 2026-05-26  
**Prior handoff:** [daily_fit_inspector_app_parity_handoff.md](./daily_fit_inspector_app_parity_handoff.md)  
**This chat:** Inspector parity investigation + hardcoded device location + asteroid/time fixes

---

## TL;DR for the next developer

Same user + same date still produces different Daily Fit in app vs Inspector. **This is not primarily a "Daily Fit cache" bug.** The app may serve a **frozen revealed payload** from disk, but Inspector recomputes every request.

The remaining divergence has been traced to **three input/runtime mismatches**:

1. **Device GPS** — app uses Yorkshire coords; Inspector originally sent none (now hardcoded default).
2. **Natal asteroids at 0°** — Swiss Ephemeris returns "success" with zero output; previous Moshier fallback never fired. Fixed with plausibility check (needs re-verify).
3. **Transit time anchor** — app uses `Date()` (wall clock); Inspector used local noon. Fixed for "today" only (needs re-verify).

**Tarot recency** and **app frozen payload** can still cause card-level differences even when sky math matches.

---

## Test fixture (Briar)

| Field                | Value                                                              |
| -------------------- | ------------------------------------------------------------------ |
| Birth date           | 12/11/1984 (1984-11-12)                                            |
| Birth time           | 12:00                                                              |
| Location             | London, England, United Kingdom                                    |
| Coordinates          | 51.5033768, -0.0795183                                             |
| Timezone             | Europe/London                                                      |
| Profile ID / hash    | `3533D487-C8B4-4A31-AE85-D11C01849B82`                             |
| Engine               | `stage1_experimental`                                              |
| Fingerprint          | `e4bd253ccae1444ad499c77ca6b7e2254941cbc3148efaa8156c07f48c1d694d` |
| Device GPS (app log) | 53.91278879084434, -0.1653861958493343                             |

Run Inspector:

```bash
cd inspector
DAILY_FIT_ENGINE_ID=stage1_experimental ./run-inspector.sh
```

Hard-refresh browser (Cmd+Shift+R) after rebuild.

---

## App ground truth (2026-05-26, from device log)

| Field                        | Value                                                                                                                                                            |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tarot                        | Knight of Wands (`Cards/Wands12`)                                                                                                                                |
| Dominant energy              | drama                                                                                                                                                            |
| Vibe budget                  | C=3 P=3 R=4 U=2 D=5 E=4                                                                                                                                          |
| Top 5 transits               | Neptune Square Moon (1.00), **Mars Conjunction Midheaven (0.95)**, Saturn Square Jupiter (0.89), **Jupiter Square Pholus (0.87)**, **Uranus Trine Vesta (0.81)** |
| Essence top 3                | SENSUAL=1.000, DRAMA=0.922, MAXIMALIST=0.534                                                                                                                     |
| Axes                         | Action=6.42, Tempo=5.40, Strategy=5.67, Visibility=9.08                                                                                                          |
| Colours                      | Deep Moonstone, Dark Sienna, dark terracotta                                                                                                                     |
| Total aspects detected (log) | 55 (note: handoff table said 57 — reconcile)                                                                                                                     |
| Device location in log       | `Using device location for Moon/Angle transits: 53.912789, -0.165386`                                                                                            |

---

## Timeline of user verification attempts

### Attempt 1 — before device-location fix

- Inspector export: `Device location (lat/lon) = (none)`
- Inspector log: `No device location available - using geocentric positions for all transits`
- Natal asteroids: all 0° Aries
- Result: Playful dominant, Ace of Cups / The Lovers tarot, wrong transit stack

### Attempt 2 — after device-location UI + hardcoded defaults (build 2026-05-26T10:59:33Z)

User exports:

- `cosmicfit_briar_natal_2026-05-26_vs_2026-05-27 (1).md`
- `cosmicfit_briar_dailyfit_2026-05-26_vs_2026-05-27.md`

**Progress:**

- Device location now present in export: `53.91278879084434 / -0.1653861958493343`
- Inspector log shows `[Device Location]` angle transits (e.g. Uranus Square Ascendant)
- Dominant shifted to **Edge** (closer to app drama axis, still wrong tarot)

**Still broken:**

- Natal export **still shows all asteroids at 0.0000°** (Chiron, Ceres, Pholus, Pallas, Vesta, Juno)
- Inspector log smoking gun — all six asteroids same bogus orb:
  ```
  Uranus Sextile Ceres (orb: 1.75°)
  Uranus Sextile Vesta (orb: 1.75°)
  Uranus Sextile Chiron (orb: 1.75°)
  ... (all identical orb = all at 0° natal)
  ```
- Missing app transits: Mars Conjunction Midheaven, Jupiter Square Pholus, Uranus Trine Vesta
- Inspector 26/05 tarot: **Ace of Swords** (app: Knight of Wands)
- Inspector dominant: **Edge** (app: **drama**)

---

## Root causes (confirmed)

### A. Device location missing → FIXED (needs re-verify)

App transit angles use GPS via `LocationManager.shared.deviceLocation` or `overrideDeviceLocation`.

**Fixes applied:**

- `InspectorRequest.InspectOptions`: `deviceLatitude`, `deviceLongitude`
- `InspectorEngine`: passes coords to `calculateTransits(overrideDeviceLocation:)`
- UI fields in `index.html` / `app.js`
- **Temporary parity default** in `InspectorDefaults.swift`:
  - `defaultDeviceLatitude = 53.91278879084434`
  - `defaultDeviceLongitude = -0.1653861958493343`
- `InspectorEngine` falls back to these when request omits coords
- `app.js` auto-fills empty device fields with same values

### B. Natal asteroids at 0° → PARTIALLY FIXED (needs re-verify)

**Original diagnosis:** Inspector only had `seas_18.se1`; asteroids need `sepl_18.se1` / `semo_18.se1`.

**Symlinks added** (exist on disk as of last check):

```
inspector/Resources/seas_18.se1 → Cosmic Fit/Resources/seas_18.se1
inspector/Resources/sepl_18.se1 → .build/checkouts/.../sepl_18.se1 (~484KB)
inspector/Resources/semo_18.se1 → .build/checkouts/.../semo_18.se1 (~1.3MB)
```

**Why symlinks alone didn't fix it:** `AsteroidCalculator` called `swe_calc_ut` with `SEFLG_SWIEPH`. When files are missing/wrong, Swiss Ephemeris often returns a **non-negative** return code but fills output with **zeros**. The first Moshier fallback only ran on `ret < 0`, so it never fired.

**Fix applied (this session) in `AsteroidCalculator.swift`:**

```swift
let needsFallback = ret < 0 || (xx[0] == 0 && xx[1] == 0 && xx[2] == 0)
if needsFallback {
    // retry with SEFLG_MOSEPH
}
```

Shared code — both app and Inspector pick this up via symlink.

**User has NOT re-exported since this fix.** Expect natal Chiron ~63° Gemini, not 0° Aries.

### C. Transit time anchor → FIXED for today (needs re-verify)

- **App:** `CosmicFitTabBarController.generateAndCacheDailyVibe` passes `Date()` to `calculateTransits(natalChart:date:)`
- **Inspector (before):** `DailyFitDateResolver.targetInstant` always used **local noon**
- Noon vs ~12:03 BST shifts local MC/ASC ~3°, enough to drop **Mars Conjunction Midheaven** from Inspector

**Fix applied in `AppProfileIdentity.swift` → `DailyFitDateResolver.targetInstant`:**

- If target date is **today** → return `Date()` (match app)
- Otherwise → local noon (stable for multi-day compare exports)

### D. Tarot recency → NOT FIXED (by design)

- App: `UserDefaults.standard` via `TarotRecencyTracker`
- Inspector: `UserDefaults(suiteName: "com.cosmicfit.inspector")` — separate store
- Inspector log shows `tarot.recency.stage1_experimental.{profileHash}.{date}` keys accumulating across multi-day runs
- Use **Reset tarot history** checkbox before submit for clean tarot parity
- Even with reset, tarot can differ if vibe/axes/transits still differ upstream

### E. App frozen Daily Fit payload → NOT AN INSPECTOR ISSUE

`DailyFitFrozenPayloadStorage` + `DailyFitRevealPersistence` freeze the exact payload once user reveals the card. On relaunch, app loads frozen JSON instead of regenerating.

**Implication:** App "ground truth" may be a snapshot from an earlier generation moment, not live recompute. For parity testing:

- Compare against a **fresh app run** after clearing reveal flags / frozen files, OR
- Treat frozen app output as canonical UX truth but accept Inspector won't match unless inputs + instant + recency all align

---

## Fixes applied (cumulative across sessions)

| Fix                                      | Files                                                        | Status                                |
| ---------------------------------------- | ------------------------------------------------------------ | ------------------------------------- |
| `overrideDeviceLocation` on transit calc | `NatalChartCalculator.swift`                                 | Applied                               |
| Inspector request device lat/lon         | `InspectorRequest.swift`, `InspectorEngine.swift`            | Applied                               |
| Device location UI                       | `index.html`, `app.js`, `styles.css`                         | Applied                               |
| Hardcoded test device GPS default        | `InspectorDefaults.swift`, `InspectorEngine.swift`, `app.js` | Applied                               |
| Ephemeris symlinks sepl/semo             | `inspector/Resources/`                                       | Applied                               |
| Moshier fallback on `ret < 0`            | `AsteroidCalculator.swift`                                   | Applied (insufficient alone)          |
| **Moshier fallback on zero output**      | `AsteroidCalculator.swift`                                   | Applied **this session — UNVERIFIED** |
| **Today uses Date() not noon**           | `AppProfileIdentity.swift`                                   | Applied **this session — UNVERIFIED** |
| Resource validation for 3 .se1 files     | `ResourcePaths.swift`                                        | Applied                               |

---

## Parity verification checklist

After `./run-inspector.sh`, single-day test first (26/05/2026), then 2-day compare.

### Natal chart export

- [ ] Chiron ≠ 0° (expect ~63° Gemini)
- [ ] Pallas, Ceres, Vesta, Juno, Pholus all non-zero
- [ ] Device location row populated

### Transit log (Inspector stdout)

- [ ] `Using device location for Moon/Angle transits: 53.912789, -0.165386` (NOT "No device location")
- [ ] No clusters of identical asteroid orbs (e.g. six aspects all at 1.75°)
- [ ] `Mars Conjunction Midheaven` present (~0.95 strength) when run at similar wall-clock time as app
- [ ] `Jupiter Square Pholus` present
- [ ] `Uranus Trine Vesta` present

### Daily Fit payload (26/05/2026)

- [ ] Dominant = **drama** (not Edge / Playful)
- [ ] Vibe budget = C=3 P=3 R=4 U=2 D=5 E=4
- [ ] Tarot = **Knight of Wands** (may still differ if recency/frozen app — investigate separately)
- [ ] Essence top 3 includes DRAMA high (app: SENSUAL, DRAMA, MAXIMALIST)
- [ ] Axes roughly match app (~6.4 action, ~5.4 tempo, ~5.7 strategy, ~9.1 visibility)

### Tarot isolation

- [ ] Check "Reset tarot history" before submit
- [ ] Compare tarot only after transit + vibe budget match

---

## If parity still fails after re-export

### Asteroids still 0°

1. Confirm symlinks resolve:
   ```bash
   ls -la inspector/Resources/*.se1
   wc -c inspector/Resources/sepl_18.se1  # ~484055
   ```
2. Add temporary logging in `AsteroidCalculator.position(of:at:)`:
   - log `ret`, `xx[0]`, whether Moshier path taken, asteroid name
3. Consider **copying** sepl/semo into `inspector/Resources/` instead of symlinks to `.build/checkouts/` (symlinks break after clean builds)
4. Verify `SwissEphemerisBootstrap.initialise(ephemerisDirectoryPath: ResourcePaths.swissEphemerisDirectory.path)` runs before first natal calc (it does in `InspectorEngine.bootstrap()`)

### Transits close but not exact

- Compare `generatedAt` / target instant in JSON payload (Inspector used to stamp noon: `2026-05-26T11:00:00Z`)
- App uses live `Date()` — re-run Inspector within minutes of app refresh for today
- Multi-day exports for **future dates** still use noon — expected minor drift vs app if app ever shows those days at wall clock

### Tarot matches vibe but not app

- App may be serving **frozen payload** from reveal — check `Documents/DailyFitFrozen/`
- App recency in standard UserDefaults vs Inspector suite — separate histories
- Seed / deterministic selection: confirm same profile hash, engine id, date, and recency state

---

## Key files

| File                                                               | Role                                               |
| ------------------------------------------------------------------ | -------------------------------------------------- |
| `Cosmic Fit/Core/Calculations/AsteroidCalculator.swift`            | Asteroid positions; zero-output → Moshier fallback |
| `Cosmic Fit/Core/Calculations/NatalChartCalculator.swift`          | Transit detection; `overrideDeviceLocation`        |
| `Cosmic Fit/Core/Utilities/SwissEphemerisBootstrap.swift`          | Ephemeris path init (Bundle vs explicit path)      |
| `Cosmic Fit/Core/Utilities/DailyFitFrozenPayloadStorage.swift`     | App frozen payload after card reveal               |
| `Cosmic Fit/InterpretationEngine/TarotRecencyTracker.swift`        | Tarot recency (UserDefaults)                       |
| `Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift`    | App Daily Fit gen; uses `Date()` + device GPS      |
| `inspector/Sources/CosmicFitInspectorLib/InspectorEngine.swift`    | Inspector pipeline; device fallback + bootstrap    |
| `inspector/Sources/CosmicFitInspectorLib/InspectorDefaults.swift`  | Hardcoded test device GPS                          |
| `inspector/Sources/CosmicFitInspectorLib/AppProfileIdentity.swift` | `DailyFitDateResolver` — today → `Date()`          |
| `inspector/Sources/CosmicFitInspectorLib/ResourcePaths.swift`      | Ephemeris dir + validation                         |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js`            | Request build, device default fill, export         |
| `inspector/Resources/*.se1`                                        | Swiss Ephemeris data files                         |
| `inspector/run-inspector.sh`                                       | Build + run on port 7777                           |

---

## Suggested next steps (priority order)

1. **Restart Inspector** from latest code (`swift build` already passed after session fixes).
2. **Single-day export** for 26/05/2026 with Reset tarot history checked.
3. **Confirm natal asteroids non-zero** in export — if still 0°, debug `AsteroidCalculator` logging before anything else.
4. **Diff top 5 transits** against app log; Mars MC is the canary.
5. Only then diff tarot / palette / copy — upstream math must match first.
6. Optional cleanup after parity confirmed:
   - Remove hardcoded device location default (keep UI fields)
   - Copy ephemeris files into Resources permanently
   - Document app frozen-payload behavior in parity test protocol

---

## User artifacts from this session

Downloads folder (for diffing):

- `Inspector log.txt` — latest run with device location + zeroed asteroids
- `App log.txt` — app with GPS + correct asteroid transits in aspect list
- `cosmicfit_briar_natal_2026-05-26_vs_2026-05-27 (1).md` — asteroids still 0°
- `cosmicfit_briar_dailyfit_2026-05-26_vs_2026-05-27.md` — Edge dominant, Ace of Swords / Judgement

**Important:** User has not yet exported after the **zero-output Moshier fix** and **today=Date() fix**. Next export is the critical verification gate.
