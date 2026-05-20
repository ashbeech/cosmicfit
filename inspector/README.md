# Cosmic Fit Inspector

A locally-hosted web tool for inspecting, debugging, and comparing Cosmic Fit's Style Guide and Daily Fit outputs for arbitrary or preset birth charts on any target day.

## Quick Start

```bash
cd inspector
swift run cosmicfit-inspector
```

Then open **http://127.0.0.1:7777** in your browser.

The header **Engine** dropdown selects the Daily Fit preset (`dailyFitEngineId`); override the server default with `DAILY_FIT_ENGINE_ID=legacy_baseline swift run cosmicfit-inspector` if needed. See the root **`README.md`** §4.1.1 for preset design and app usage.

The first build takes a few minutes (fetching SPM dependencies). Subsequent builds are incremental.

## Security

The server binds **only** to `127.0.0.1:7777` (loopback). It is not accessible from other machines on your network.

**Do not** expose this server via `ngrok`, tunnelling, or binding to `0.0.0.0`. It has no authentication and is designed strictly for local development.

No Supabase keys or production credentials are read or stored.

## Architecture

```
inspector/
  Package.swift               # SPM package definition
  Sources/
    CosmicFitInspectorLib/     # Engine (symlinks) + inspector glue
    CosmicFitInspectorServer/  # Hummingbird HTTP server + static web
      Web/                     # index.html, styles.css, app.js
  Resources/                   # Symlinks to shared data files
  Tests/
```

The inspector compiles the **same** Swift engine source files as the iOS app via symlinks — no copies, no drift. The engine types remain `internal`; the inspector glue lives in the same module for access.

### Key Dependencies

- [Hummingbird 2](https://github.com/hummingbird-project/hummingbird) — async Swift HTTP server
- [SwissEphemeris](https://github.com/vsmithers1087/SwissEphemeris) — planetary calculations
- Vanilla HTML/CSS/JS frontend (no npm, no build step)

## Presets

Four real-ephemeris presets are defined in `Resources/presets.json`:

| ID | Element | Profile |
|----|---------|---------|
| `fire` | Fire | Aries Sun — London dawn |
| `earth` | Earth | Taurus Sun — London morning |
| `air` | Air | Aquarius Sun — London early morning |
| `water` | Water | Scorpio Sun — London night |

### Adding a Preset

1. Pick a profile from `docs/fixtures/blueprint_birth_specs.json`
2. Add it to `Resources/presets.json` with a unique `id` and `elementDominance`
3. Restart the server

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/health` | Health check + engine version |
| `GET` | `/api/presets` | List preset profiles |
| `POST` | `/api/inspect` | Full pipeline (natal + blueprint + daily fit + verdicts) |
| `GET` | `/api/geocode?q=...` | Forward geocoding via CLGeocoder |
| `GET` | `/` | Web UI |

### POST /api/inspect

```json
{
  "birth": {
    "birthDate": "1984-12-11",
    "birthTime": "00:00",
    "unknownTime": false,
    "latitude": 51.5074,
    "longitude": -0.1278,
    "timeZoneId": "Europe/London",
    "locationLabel": "London, UK"
  },
  "targetDate": "2026-05-13",
  "options": { "composeBlueprint": true, "includeProgressed": true }
}
```

Set `composeBlueprint: false` for date-only changes (uses cached blueprint).

### Compare modes

| Mode | UI | Behaviour |
|------|-----|-----------|
| **Compare days** | “Compare days” + day count | Same `dailyFitEngineId` (header dropdown), multiple UTC dates in a horizontal carousel |
| **Compare engines** | “Compare engines” + A vs B selects | Same target UTC date, two registry engine ids side-by-side in Daily Fit, Trace, and Verdicts |

The two modes are mutually exclusive. Each `POST /api/inspect` still sends `options.dailyFitEngineId`; engine compare issues one request per column so tarot recency stays namespaced per engine (P3). Labels show **date (UTC) · engine id** on each pane.

## Verdicts

The inspector runs four automated checks on every response:

1. **source_contributions_normalised** — sum ≈ 1.0 (tolerance 0.005)
2. **vibrancy_contrast_metal_in_range** — all in [0, 1]
3. **palette_three_unique** — exactly 3 distinct daily colours
4. **tarot_recency** — uses the same `TarotRecencyTracker` as the app (isolated in `UserDefaults` suite `com.cosmicfit.inspector`). Recency and variant-rotation keys are namespaced by `dailyFitEngineId`, so switching the engine dropdown does not share tarot history between presets. Use `options.resetTarotHistory: true` to clear recency for the active engine only.

### Extending Verdicts

Add new checks to `Sources/CosmicFitInspectorLib/VerdictRunner.swift`. Each check returns a `VerdictRow` with `id`, `status` (pass/partial/fail), `expected`, `actual`, and optional `docRef`.

## Resource Symlinks

The `Resources/` directory contains symlinks to source-of-truth files:

- `astrological_style_dataset.json` → `data/style_guide/`
- `blueprint_narrative_cache.json` → `data/style_guide/`
- `VSOP87Data/` → `Cosmic Fit/Resources/VSOP87Data/`
- `seas_18.se1` → `Cosmic Fit/Resources/`
- `golden_cases.json` → `docs/fixtures/`

If a symlink breaks (e.g., after moving the repo), the server will report which resources are missing on startup.
