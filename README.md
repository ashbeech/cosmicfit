# Cosmic Fit — AI Developer Handoff

> **Last audited:** June 2026
> **Bundle ID:** `com.thisisbullish.cosmicfit`
> **Platform:** iOS (UIKit, no SwiftUI, no storyboards except LaunchScreen)
> **Deployment target:** iOS 18.4
> **Language:** Swift 5
> **Dev Team:** `653BNKDSZS` (app target), `J5V4NZ3334` (project/test targets)
> **Current Daily Fit engine:** Sky Forward v1.0.1 (`production`, `.stage1Experimental`)

---

## 1. What Cosmic Fit Does

Cosmic Fit is an astrology-meets-fashion iOS app. It computes a natal birth chart from a user's birth date, time, and location, then translates astrological placements into personalised style guidance. The app has two primary outputs:

1. **Style Guide** — A permanent, per-user colour palette, texture recommendations, pattern guidance, accessory suggestions, hardware (metals/stones), and occasion-specific style advice. Generated once from the natal chart and cached. In code and on disk this data is the `CosmicBlueprint` model (`BlueprintStorage`, `BlueprintComposer`, etc.); older docs and filenames still say “blueprint” but the product name is **Style Guide**.

2. **Daily Fit** — A daily-changing style card powered by the shipped **Sky Forward v1.0.1** engine. Sky Forward reads the user's chart as an anchor and today's sky as the weather: transits, lunar phase, and daily sky salience drive a tarot card, style edit, daily colours, vibrancy/contrast/metal-tone scales, 14-category essence radar, silhouette profile, textures, and optional pattern. It is deterministic for equal inputs, but reveal state, tarot recency, variant rotation, and frozen payloads are namespaced by engine id and can legitimately change the sequence a user sees over time.

The root README is intended to be the **go-to handoff for AI developers**. Deep specs and historical runbooks remain under `docs/handoff/`; use this file for the current state of the app, then follow links when you need implementation-level detail.

---

## 2. Tech Stack & Dependencies

| Component | Detail |
|---|---|
| **UI Framework** | UIKit, 100% programmatic (no storyboards, no SwiftUI) |
| **Package Manager** | Swift Package Manager (via Xcode workspace) |
| **Ephemeris Library** | `SwissEphemeris` 0.0.99 (vsmithers1087) — planetary position calculations |
| **Backend** | Supabase Swift SDK 2.46.0 — email OTP auth, profile sync, Style Guide sync, promo/comp access |
| **Crypto** | `swift-crypto` 4.5.0 (transitive via Supabase) |
| **HTTP** | `swift-http-types` 1.5.1 (transitive via Supabase) |
| **Concurrency** | `swift-concurrency-extras` 1.3.2, `swift-clocks` 1.0.6 (transitive) |
| **Planetary Data** | VSOP87D data files (bundled per-planet: `.ear`, `.jup`, `.mar`, etc.) |
| **Ephemeris Data** | `seas_18.se1` (Swiss Ephemeris asteroid/moon data) |
| **Fonts** | DM Sans (18 weights), DM Serif Text (2 weights), PT Serif (2 weights) |
| **Build Config** | `Dev.xcconfig` / `Prod.xcconfig` for Supabase URL and API key injection |
| **Backend Functions** | Supabase Edge Functions: `send-otp`, `verify-otp`, `signup-with-profile`, `delete-account`, `redeem-code`, `check-comp-access`, `revoke-comp-access`, `app-store-notifications` |
| **Database** | Supabase PostgreSQL — migrations `001`–`009` for profiles, blueprints, subscriptions, promo codes, comp access, subscription events, and account-deletion FK behaviour |
| **Python tooling** | Offline scripts for datasets, narratives, calibration/regression, and QA — **not** compiled into the app (see §2.1) |

### 2.1 Developer tooling (local only)

Everything below is for authoring, calibration, and tests. None of it ships in the iOS binary.

#### Python environment

All scripts live under **`tools/`**. Install dependencies from the repo root:

`pip install -r tools/requirements.txt`

That pulls in **Flask** (`tools/review_tool.py`) and **google-generativeai** (`tools/backfill_narratives.py`). Other scripts use the Python standard library only. See **`tools/README.md`** for a short quick-start.

#### Style Guide narrative QA (content creation)

| Script / artefact | Purpose |
|---|---|
| **`tools/review_tool.py`** | Local Flask web UI for reviewing AI-generated **Style Guide** paragraphs in `blueprint_narrative_cache.json`. Usage: `python3 tools/review_tool.py [--cache path/to/blueprint_narrative_cache.json] [--port 8420]`. Reviewer state: **`review_notes.json`** (approve / needs revision / reject). Spec: **`docs/narrative_review_tool_spec.md`**. |
| **`tools/backfill_narratives.py`** | Generates or refreshes narrative paragraphs (Gemini API), reads/writes the cache, and honours **`review_notes.json`** so approved copy is not blindly overwritten. Uses **`GEMINI_API_KEY`** (`.env` at repo root or env). |

**Canonical copy:** **`data/style_guide/blueprint_narrative_cache.json`**. **`Cosmic Fit/Resources/`** holds a **symlink** so the bundle resource name stays **`blueprint_narrative_cache.json`** (bundle key **`blueprint_narrative_cache`**). Renaming the bundle key requires `NarrativeCacheLoader` + Xcode.

**Legacy naming:** file basename unchanged for compatibility with existing tooling.

#### Style Guide dataset authoring (`astrological_style_dataset.json`)

| Script | Purpose |
|---|---|
| **`tools/generate_dataset.py`** | Authoring source for **`data/style_guide/astrological_style_dataset.json`** (planet–sign mappings, aspects, house placements, colour library, etc.) consumed by **`BlueprintTokenGenerator`**. The app bundle loads via **`Cosmic Fit/Resources/`** symlink → same file (see **`data/style_guide/README.md`**). |
| **`tools/validate_dataset.py`** | Validates that dataset JSON matches the schema checklist (**`docs/fixtures/dataset_schema_checklist.md`**) and the **`BlueprintTokenGenerator`** Codable contract. Also runs **Part 6A** astrological axiom checks (Venus fire, Moon water, Saturn structure, `code_leaninto` vs `code_avoid` overlap, etc.). Run after edits before committing. |

#### Palette calibration & house/sect regression (Python helpers)

| Script | Purpose |
|---|---|
| **`docs/archive/review_palette_calibration.py`** | **Archived** helper: compares a generated palette JSON to a human-labelled benchmark and writes a markdown report (still usable if paths are adjusted). Not on the default dev path; kept under **`docs/archive/`**. |
| **`tools/export_input_after_fixtures.py`** | Runs **`xcodebuild test`** for **`Cosmic FitTests/HardeningEdgeCaseTests`**, which writes **post-integration Style Guide JSON** into **`docs/house_sect_regression/input_after/{fixture}.json`**. Defaults: `ash`, `maria`, `day_chart_venus_angular`, `night_chart_venus_cadent`. Options: `--scheme`, `--destination`. Use this when refreshing regression inputs after engine changes. |
| **`tools/generate_house_sect_regression.py`** | Builds **before/after snapshot bundles** from Blueprint JSON paths (diffs code directives, narratives, palette stability). Writes artefacts under **`docs/house_sect_regression/`** for inspection. |
| **`tools/review_house_sect_regression.py`** | Reads snapshot JSONs and emits a reviewer **scorecard** (default / configurable **`SCORECARD.md`**). Usage: `python3 tools/review_house_sect_regression.py [--snapshots-dir …] [--output …]`. |

Calibration diagnostics and golden text used by XCTest often live under **`docs/fixtures/`** (e.g. `v4_*`, `*_calibration_*`, per-row classification JSON). Treat that tree as **test and tuning artefacts**, not app runtime.

#### SynthID removal (single image)

| Script | Purpose |
|---|---|
| **`tools/synthid_drop_tool.py`** | Local Flask UI to run **one** image through the same de-SynthID settings as **`scripts/run_full_synthid_removal.sh`** (`0.04` × 3 passes, 768px tiles, 128 overlap). Requires **`scripts/.venv`** plus **`pip install flask`** in that venv. Usage: `cd scripts && source .venv/bin/activate && python ../tools/synthid_drop_tool.py --port 8421`. All synthid tooling I/O lives under repo-root **`Resources/`** (not the Xcode bundle): `originals/`, `originals_desynthid/`, `.synthid_*` backups/candidates, and `synthid_drop_*` for the single-image UI. Batch card promotion still writes into **`Cosmic Fit/Resources/Assets.xcassets/Cards/`**. |

#### Swift test harness — blueprint fixture regeneration

| Location | Purpose |
|---|---|
| **`Cosmic FitTests/FixtureRegeneration.swift`** | Optional regeneration of **`docs/fixtures/blueprint_input_user_1.json`** and **`blueprint_input_user_2.json`** via the production **`BlueprintComposer`** pipeline. **Default:** validates fixture shape only (safe for CI). **To rewrite files on disk:** set environment variable **`REGENERATE_BLUEPRINT_FIXTURES=1`** when running that test. Output timestamps are pinned for byte-stable diffs. |

#### Cosmic Fit Inspector (local web UI)

A **macOS-only** sibling Swift package under **`inspector/`** that runs the **same** interpretation engine as the iOS app (via symlinks into `Cosmic Fit/`), served by a small **Hummingbird** HTTP server with a **vanilla HTML/CSS/JS** UI. Use it to inspect Style Guide (`CosmicBlueprint`) and Daily Fit (`DailyFitPayload` + `DailyFitDiagnosticReport`) for arbitrary birth inputs or preset charts, change the target calendar day, compare adjacent days, skim provenance/trace accordions, and run lightweight verdict checks — without building or deploying the iOS app.

The header **Engine** dropdown selects the active Daily Fit preset (`dailyFitEngineId`). The value is sent on every `POST /api/inspect` in `options.dailyFitEngineId` and persisted in browser session storage. Compare panes label each result with **date (UTC) · engine id**. See **§4.1.1** for why presets exist and how they differ from Style Guide versioning. When starting the server, you can optionally set **`DAILY_FIT_ENGINE_ID`** in the environment (e.g. `DAILY_FIT_ENGINE_ID=legacy_baseline ./run-inspector.sh`) as the default for requests that omit an explicit engine id.

**Start the server** (always use the run script after engine changes):

```bash
cd inspector
./run-inspector.sh
```

Open **http://127.0.0.1:7777** in a browser on the same machine. The server binds **loopback only** (`127.0.0.1:7777`); it is not intended for LAN or public hosting and has no auth.

**Why not `swift run cosmicfit-inspector` alone?** The inspector compiles engine code via **symlinks** into `Cosmic Fit/` (e.g. `InterpretationEngine/`, `Calculations/`). Swift Package Manager’s incremental build often **does not detect edits to symlink targets**, so `swift build` can skip recompiling changed engine files and serve a stale binary. The run script fixes this by:

1. Killing any existing process on port **7777** (avoids an old server still serving stale results)
2. Writing a fresh **`BuildStamp.swift`** (UTC timestamp baked into the binary)
3. Deleting **`.build/build.db`** so SPM re-scans source mtimes through symlinks (~10s rebuild, not a full clean)
4. Building and launching the inspector

**Verifying you have the latest code:**

| Where | What to check |
|---|---|
| **Terminal banner** on startup | `Built: <UTC timestamp>` plus short engine fingerprints |
| **Inspector UI** (header) | `Built: …` chip (from `GET /api/health`) |
| **Markdown export** metadata | `Inspector build: …` line |
| **`GET /api/health`** | `buildStamp` field |

If you edit engine code and the build stamp does not change after restarting with `./run-inspector.sh`, something is wrong — do not trust Daily Fit output until it does. A full nuclear reset is `cd inspector && rm -rf .build && ./run-inspector.sh` (~45s first rebuild).

**Requirements:** macOS 14+, Xcode/Swift toolchain able to build the package. Resources under **`inspector/Resources/`** are symlinks to the shared style dataset, narrative cache, VSOP87 data, and Swiss Ephemeris files (see **`inspector/README.md`** for layout, API summary, presets, and security notes).

#### Supabase (backend authoring)

| Path | Purpose |
|---|---|
| **`supabase/functions/send-otp`**, **`verify-otp`**, **`signup-with-profile`** | Deno/TypeScript Edge Functions for email OTP auth and onboarding signup/profile creation (sources for deploy; not executed by the iOS build). |
| **`supabase/functions/delete-account`**, **`redeem-code`**, **`check-comp-access`**, **`revoke-comp-access`**, **`app-store-notifications`** | Account deletion, promo/comp access, and App Store Server Notifications support. Deploy these before relying on the matching production app features. |
| **`supabase/migrations/`** | SQL migrations `001`–`009` for hosted tables, RLS, OTP/rate-limit helpers, subscription ledger/events, promo redemption position, and account-deletion FK behaviour. |

### 2.2 XCTest environment flags (calibration & golden regeneration)

These opt in to **writing** fixture files under **`docs/fixtures/`** or enabling verbose diagnostics. Omit them in CI unless you intend to refresh goldens.

| Variable | Test target / area | Purpose |
|---|---|---|
| **`REGENERATE_BLUEPRINT_FIXTURES=1`** | `FixtureRegeneration` | Rewrites **`blueprint_input_user_1.json`** / **`blueprint_input_user_2.json`**. |
| **`REGENERATE_V4_PALETTE_EXPECTATIONS=1`** | `V4CalibrationRegression_Tests` | Updates palette expectation rows in **`docs/fixtures/v4_dataset.json`** when colour logic changes. |
| **`REGENERATE_PALETTE_GRID_GOLDENS=1`** | `PaletteGridViewModel_Tests` | Regenerates **`palette_grid_golden_user_1.json`** / **`palette_grid_golden_user_2.json`**. |
| **`REGENERATE_V4_PLACEMENTS=1`** | `V4PlacementGenerator_Tests` | Runs placement-generation paths that skip by default; used for Maria/Ash-style fixture output. |
| **`PALETTE_CALIBRATION_DIAGNOSTIC=1`** | `Cosmic_FitTests` (`PaletteCalibrationDiagnostic`) | Enables an opt-in Ash palette / token diagnostic block (otherwise no-ops). |
| **`V4_REFERENCE_FIXTURE_PATH`** | `V4ReferenceAudit_Tests` | Overrides path to **`v4_markdown_reference.json`** when not beside **`docs/fixtures/`**. |
| **`CALIBRATION_CI_GATE=1`** | `Cosmic FitTests` (distribution, variation, coherence suites) | **Tier 2:** enables stricter calibration assertions (threshold-style gates). Default `xcodebuild test` runs Tier 1 (diagnostic / softer guards). See **`docs/calibration_plan_closure_summary.md`**. |
| **`CALIBRATION_REPORT_DIR`** | Any test using **`CalibrationReportHelper.writeReport`** | Absolute path, or path relative to repo root, for calibration **`*.txt`** outputs. If unset, reports go under **`docs/fixtures/`** with unique filenames (PID + UUID). Use in CI to avoid writers clobbering each other. |
| **`DAILY_FIT_ENGINE_ID`** | Optional local / dedicated jobs only | Selects the iOS app build default or inspector server default preset (`production`, `legacy_baseline`, etc.). **Do not set in default CI** — tests pass explicit `calibration:` unless testing `DailyFitEngineConfig`. See **§4.1.1**. |

For command-line examples and parallel-test caveats, see **`docs/archive/test_handoff.md`** (stabilizing **`xcodebuild test`**).

#### Calibration audit closure (distribution tests, VSOP87, astrological soundness)

| Doc | Purpose |
|---|---|
| **`docs/calibration_plan_closure_summary.md`** | What was closed against the calibration audit plan, what remains actionable, and copy-paste commands for validation. |
| **`docs/calibration_signoff.md`** | Sign-off artefact: baseline / threshold policy, Part 6 energy maps and calibration weights, dataset axiom outcomes. |
| **`docs/calibration_ephemeris_strategy.md`** | Hybrid ephemeris strategy (synthetic charts in default CI vs production ephemeris locally) and Tier 2 policy notes. |

---

## 3. Project Structure (Active Code Only)

```
data/
└── style_guide/                       # Canonical Style Guide JSON — see data/style_guide/README.md
    ├── astrological_style_dataset.json
    ├── blueprint_narrative_cache.json
    └── blueprint_narrative_cache-2-clusters.json

inspector/                           # Local macOS web inspector — same Swift engine as the app (SPM + Hummingbird); see §2.1
├── Package.swift
├── README.md                        # Quick start, API, presets, resource symlinks, verdicts
├── run-inspector.sh                 # Preferred start script — kills stale server, invalidates SPM cache, rebuilds, runs
├── Resources/                       # Symlinks to style_guide JSON, VSOP87, Swiss Ephemeris, presets
├── Sources/
│   ├── CosmicFitInspectorLib/       # Engine sources (symlinks) + request/response/engine glue
│   └── CosmicFitInspectorServer/    # `cosmicfit-inspector` executable + static Web/ UI + BuildStamp.swift (generated)
└── Tests/

Cosmic Fit/
├── App/
│   └── AppDelegate.swift              # Entry point, auth bootstrap, launch flow, daily-fit refresh
├── Config/
│   ├── Dev.xcconfig                   # Supabase credentials (gitignored)
│   └── Prod.xcconfig                  # Supabase credentials (gitignored)
├── Core/
│   ├── NatalChartManager.swift        # Singleton facade for chart calculation, save/load, transits
│   ├── NatalChartManager+Interpretation.swift  # PLACEHOLDER — interpretation methods return static strings
│   ├── Calculations/
│   │   ├── NatalChartCalculator.swift # Heart of astrological computation: natal charts, progressed charts, transits, house systems, aspects
│   │   ├── AstronomicalCalculator.swift # Sun, Moon, planet positions from VSOP87/Swiss Ephemeris
│   │   ├── AstrologicalInterpreter.swift # Textual interpretations of chart placements
│   │   ├── AsteroidCalculator.swift   # Chiron, Lilith, North Node calculations
│   │   └── JulianDateCalculator.swift # Calendar ↔ Julian Day conversions
│   ├── Config/
│   │   ├── DebugConfiguration.swift   # Debug flag toggle and conditional logging
│   │   ├── DailyFitEngineConfig.swift # Resolves active Daily Fit preset from plist + DEBUG override (see §4.1.1)
│   │   └── SupabaseConfig.swift       # Reads Supabase URL/key from Info.plist
│   ├── Services/
│   │   ├── CosmicFitAuthService.swift # Supabase email OTP auth, signup-with-profile, session notifications
│   │   ├── SupabaseSyncService.swift  # Profile + Style Guide (`CosmicBlueprint`) cloud sync (upload/download JSON)
│   │   ├── StoreKitManager.swift      # Subscription products, purchases, restore flow
│   │   ├── EntitlementManager.swift   # Combines StoreKit + comp/promo entitlement state
│   │   ├── PromoCodeService.swift     # Promo/comp code redemption and status
│   │   └── AuthDeepLinkRouter.swift   # cosmicfit:// URL scheme handling for auth callbacks
│   └── Utilities/
│       ├── UserProfileStorage.swift   # Local profile persistence (Documents dir JSON)
│       ├── BlueprintStorage.swift     # Local Style Guide persistence — `CosmicBlueprint` JSON in Documents
│       ├── DailyFitFrozenPayloadStorage.swift # Daily Fit payload cache (one per day per profile)
│       ├── CoordinateTransformations.swift # Zodiac math, degree ↔ sign conversions
│       ├── VSOP87Parser.swift         # Parses bundled VSOP87D planetary theory files
│       ├── SwissEphemerisBootstrap.swift # Configures Swiss Ephemeris file paths at launch
│       ├── Ephemeris+Helpers.swift     # Convenience wrappers for SE library calls
│       ├── LocationManager.swift      # CLLocationManager wrapper for birth location
│       ├── WeatherService.swift       # Weather API (used by WeatherFabricFilter)
│       └── DebugLogger.swift          # Structured logging with subsystem tags
├── InterpretationEngine/
│   ├── DailyFitTypes.swift            # Foundation types: DailyEnergySnapshot, DailyFitPayload, StyleEssenceProfile, SilhouetteProfile, DailyFitCalibration, etc.
│   ├── DailyFitEngineRegistry.swift   # Canonical Daily Fit engine preset list + calibration fingerprints (see §4.1.1)
│   ├── DailyEnergyEngine.swift        # Sky Forward snapshot: chart anchor + today's sky → energies, axes, salience
│   ├── DailyFitPipeline.swift         # Sole Daily Fit assembly entry point for app, inspector, tests
│   ├── DailyNarrativeSelector.swift   # Plan-driven cohesion for Sky Forward payloads
│   ├── DailyNarrativeCoherence.swift  # Cross-surface contradiction gates and coherence scoring
│   ├── NarrativeTarotBridgeSelector.swift # Joint tarot/variant selection bridge
│   ├── BlueprintLensEngine.swift      # Snapshot + CosmicBlueprint + narrative plan → DailyFitPayload
│   ├── PersonalScaleEnvelope.swift    # User-relative display positions for personal style scales
│   ├── DailyFitDiagnostics.swift      # Diagnostic report generator (captures full pipeline trace)
│   ├── VibeBreakdown .swift           # Energy enum (6 types) and VibeBreakdown struct (⚠️ filename has trailing space)
│   ├── DerivedAxesEvaluator.swift     # DerivedAxes struct definition (action, tempo, strategy, visibility)
│   ├── DerivedAxesConfiguration.swift # Legacy axis config (may be superseded by DailyFitCalibration)
│   ├── CosmicFitInterpretationEngine.swift # Style Guide generator — currently outputs PLACEHOLDER text
│   ├── BlueprintModels.swift          # CosmicBlueprint, PaletteSection, BlueprintColour, ColourRole, ColourProvenance, etc.
│   ├── BlueprintComposer.swift        # Assembles CosmicBlueprint from tokens + narrative cache
│   ├── BlueprintTokenGenerator.swift  # Generates BlueprintTokens from natal chart + astrological dataset
│   ├── ArchetypeKeyGenerator.swift    # Generates BlueprintArchetypeKey for narrative cache lookup
│   ├── NarrativeCacheLoader.swift     # Loads blueprint_narrative_cache.json
│   ├── NarrativeTemplateRenderer.swift # Renders narrative templates with token substitution
│   ├── DeterministicResolver.swift    # Resolves deterministic Style Guide fields from tokens
│   ├── ChartAnalyser.swift            # Analyses natal chart for structural features
│   ├── PlanetPowerEvaluator.swift     # Scores planet strength (dignity, house, aspects)
│   ├── StructuralAxes.swift           # Chart structure analysis (element/modality balance)
│   ├── TarotCard.swift                # TarotCard model, StyleEditVariant, ArcanaType, SuitType
│   ├── TarotCardValidator.swift       # Validates TarotCards.json structure and completeness
│   ├── TarotRecencyTracker.swift      # Prevents repeating tarot cards within 3-7 days
│   ├── TarotVariantRotationTracker.swift # Rotates through style-edit variants per card
│   ├── TarotSelectionMonitor.swift    # Debug tool for monitoring card selection patterns
│   ├── SemanticTokenGenerator.swift   # Generates StyleTokens from natal chart (for Style Guide path)
│   ├── StyleToken.swift               # StyleToken struct (name, type, weight)
│   ├── InterpretationTextLibrary.swift # ⚠️ LEGACY — massive text library (1933 lines), marked "NOT CURRENTLY USED"
│   ├── InterpretationResult.swift     # InterpretationResult struct (used by Style Guide)
│   ├── ParagraphBlock.swift           # ParagraphBlock model for narrative assembly
│   ├── MoonPhaseInterpreter.swift     # Moon phase calculation and phase name mapping
│   ├── DailySeedGenerator.swift       # Deterministic daily seed from profileHash + date
│   ├── TransitWeightCalculator.swift  # Weights transit aspects by planet/type/orb
│   ├── WeatherFabricFilter.swift      # Filters fabric recommendations by current weather
│   ├── WeightingModel.swift           # Weighting configuration for token generation
│   ├── HouseSectOverlayGenerator.swift # House/sect dignity overlay calculations
│   ├── EngineConfig.swift             # Engine-level configuration constants
│   ├── ColourScoring.swift            # Colour scoring utilities
│   └── ColourEngineV4/               # V4 Colour Palette Engine (20 files, ~3200 lines total)
│       ├── ColourEngine.swift         # Main entry point: chart → PaletteSection
│       ├── Domain.swift               # PaletteFamily, PaletteCluster, DerivedVariables enums
│       ├── ChartInputAdapter.swift    # Converts NatalChart into colour engine input
│       ├── ChartSignatureResolver.swift # Resolves chart → palette family + cluster
│       ├── SignContributions.swift     # Per-sign colour contribution weights
│       ├── SignArchetypes.swift        # Sign-to-colour-archetype mappings
│       ├── ClusterMapping.swift        # Cluster → palette template mapping
│       ├── FamilyMapping.swift         # Family classification logic
│       ├── FamilyProfiles.swift        # Per-family colour profile definitions
│       ├── DriverWeights.swift         # Planet/sign weight drivers
│       ├── Scoring.swift               # Colour candidate scoring
│       ├── SecondaryPull.swift          # Adjacent family secondary pull detection
│       ├── Modifiers.swift             # Post-processing colour modifiers
│       ├── Normalize.swift             # LCH normalisation into family envelopes
│       ├── Overrides.swift             # Edge-case override rules
│       ├── AccentResolver.swift         # Chart-derived accent colour placement
│       ├── PaletteLibrary.swift         # Named colour library with hex values
│       ├── PaletteValidator.swift       # Validates palette completeness and sanity
│       ├── VariationSlots.swift         # Variation slot system for palette diversity
│       └── Thresholds.swift             # Scoring thresholds and gate constants
├── UI/
│   ├── CosmicFitTheme.swift           # Design system: colours, fonts, spacing, gradients
│   ├── SlideTabTransitionAnimator.swift # Custom horizontal tab transition
│   ├── VerticalSlideAnimator.swift    # Custom vertical slide transition
│   ├── ViewControllers/
│   │   ├── CosmicFitTabBarController.swift # Main tab bar: Daily Fit, Style Guide, Natal Chart, Profile
│   │   ├── DailyFitViewController.swift # Daily Fit screen — renders reveal state, entitlements, and full DailyFitPayload
│   │   ├── NatalChartViewController.swift # Natal chart display with ChartWheelView
│   │   ├── StyleGuideViewController.swift # Style Guide hub (sections from `CosmicBlueprint`)
│   │   ├── StyleGuideDetailViewController.swift # Detail view for style guide sections
│   │   ├── ProfileViewController.swift # User profile display and edit
│   │   ├── InterpretationViewController.swift # Chart interpretation text display
│   │   ├── OnboardingFormViewController.swift # Birth data input form
│   │   ├── AnimatedLaunchScreenViewController.swift # Animated splash screen
│   │   ├── AnimatedWelcomeIntroViewController.swift # First-launch welcome flow
│   │   ├── SignedOutLandingViewController.swift # Signed-out landing for complete-profile users
│   │   ├── AuthGateViewController.swift # Legacy/auth gate support; Daily Fit tab is not gated through this now
│   │   ├── OTPVerifyViewController.swift # OTP code entry for email auth
│   │   ├── MenuViewController.swift   # Side/overlay menu
│   │   ├── FAQViewController.swift    # FAQ display
│   │   ├── GenericDetailViewController.swift # Reusable detail view
│   │   ├── PurchaseViewController.swift # StoreKit purchase/restore flow
│   │   ├── StyleCalendarUnlockViewController.swift # Daily Fit entitlement unlock presentation
│   │   └── CardPresentationController.swift # Custom modal card presentation
│   └── Views/
│       ├── ChartWheelView.swift       # Natal chart wheel visualisation
│       ├── ColourPaletteView.swift     # Style Guide palette display (545 lines)
│       ├── DailyColourPaletteView.swift # Daily palette display (3 colours + context ring)
│       ├── EssenceTriangleView.swift   # 14-category essence radar chart
│       ├── DosAndDontsSectionView.swift # Style guide lean-into/avoid display
│       ├── LocationAutocompleteView.swift # Location search with autocomplete
│       ├── LocationResultTableViewCell.swift # Location search result cell
│       ├── AuthNudgeBannerView.swift   # Banner prompting guest users to sign up
│       ├── MenuBarView.swift           # Custom top menu bar
│       ├── MenuButton.swift            # Animated hamburger menu button
│       ├── ScrollingRunesBackgroundView.swift # Decorative background animation
│       ├── StarView.swift              # Star particle animation
│       └── Palette/
│           ├── PaletteGrid.swift       # Grid layout for colour swatches
│           ├── PaletteGridViewModel.swift # View model for palette grid (colour math, layout)
│           ├── ColourCell.swift         # Individual colour swatch cell
│           └── ColourMath.swift         # HSL/RGB/Hex conversion utilities
└── Resources/
    ├── TarotCards.json                # 78-card tarot deck with energyAffinity, axesAffinity, styleEdits (8306 lines)
    ├── astrological_style_dataset.json # → symlink to ../../data/style_guide/ (bundle resource name unchanged)
    ├── blueprint_narrative_cache.json  # → symlink to ../../data/style_guide/
    ├── blueprint_narrative_cache-2-clusters.json # → symlink to ../../data/style_guide/
    ├── Assets.xcassets                # App icons, card images, colour assets
    ├── Fonts/                         # DM Sans, DM Serif Text, PT Serif font files
    ├── VSOP87Data/                    # Planetary position data (8 planet files)
    └── seas_18.se1                    # Swiss Ephemeris asteroid data
```

---

## 4. Architecture Deep Dive

### 4.1 Daily Fit Pipeline (Sky Forward)

The shipped Daily Fit engine is **Sky Forward v1.0.1**. In Release builds, `DailyFitEngineConfig.effectiveEngineId` resolves to `production`, and the registry maps `production` to `DailyFitEngineMode.stage1Experimental`. Do not treat `production` as legacy Stage 2 or `.default` calibration.

The active pipeline is:

```text
NatalChart + progressed chart + transits + moon phase
  -> DailyEnergyEngine.generateSnapshot
  -> DailyFitPipeline.generate
  -> DailyNarrativeSelector -> DailyNarrativePlan
  -> BlueprintLensEngine.generatePayloadFromPlan
  -> PersonalScaleEnvelope display positions
  -> DailyFitViewController
```

#### Stage 1: Energy Snapshot (`DailyEnergyEngine`)

**Input:** natal chart, progressed chart, transit aspects, moon phase, date, calibration weights, `dailyFitEngineId`  
**Output:** `DailyEnergySnapshot`

Sky Forward uses the stage-1 source weights from `DailyFitEngineRegistry.stage1ExperimentalCalibration`:

| Source | Weight | Purpose |
|---|---:|---|
| Natal chart | 0.16 | Chart anchor; stable personal baseline |
| Transits | 0.44 | Primary daily weather driver |
| Lunar phase | 0.30 | Daily cycle and visibility/action modulation |
| Progressed chart | 0.07 | Slow personal evolution |
| Current sun sign | 0.03 | Seasonal background |

The stage-1 path separates **chart anchor** and **today's sky**. Daily vibe and axes are sky-forward, while anchor fields remain available on payloads for context. `SignMultiplierPolicy.stage1OptionA` applies sign multipliers to the chart anchor but not to the daily sky read.

The snapshot includes the six-energy vibe profile (`classic`, `playful`, `romantic`, `utility`, `drama`, `edge`), derived axes (`action`, `tempo`, `strategy`, `visibility`), dominant transits, lunar context, sky salience, and deterministic daily seed.

#### Stage 2: Narrative Plan + Daily Fit Lens

`DailyFitPipeline` is the sole app/inspector/test entry point. For `.stage1Experimental`, it builds one `DailyNarrativePlan` before payload assembly. The plan coordinates tarot, palette, essence, scales, and silhouette so the UI surfaces tell one story without adding generated "Daily Brief" prose.

`BlueprintLensEngine.generatePayloadFromPlan` applies the user's Style Guide (`CosmicBlueprint`) to the sky-forward snapshot and returns the `DailyFitPayload` rendered by the app:

| Field | Source |
|---|---|
| **Tarot card + style edit variant** | Narrative bridge selection, card affinity, recency hard blocks, variant rotation |
| **Daily palette** | Style Guide colours scored by narrative/sky fit with `pureSkyScoring` in Sky Forward |
| **Vibrancy / contrast / metal tone** | Raw scale derivation plus `PersonalScaleEnvelope` display positions |
| **Style essence** | 14-category profile with visible top categories and chart-anchor support data |
| **Silhouette profile** | Masculine/feminine, angular/rounded, structured/draped, including chart-anchor fields |
| **Textures / pattern** | Style Guide candidates filtered by daily axes and narrative relationship |
| **Engine metadata** | `dailyFitEngineId`, fingerprint-sensitive output, recency/frozen namespaces |

#### 4.1.1 Daily Fit engine presets

`DailyFitEngineRegistry.swift` is the single source of truth for presets, calibration, mode, marketing version, and fingerprints.

| `dailyFitEngineId` | Mode | Purpose |
|---|---|---|
| `production` | `.stage1Experimental` | Shipped Sky Forward v1.0.1; App Store / Release path |
| `stage1_experimental` | `.stage1Experimental` | DEBUG alias with the same calibration/fingerprint as production; different UserDefaults namespaces |
| `legacy_baseline` | `.standard` | Pre–Stage 2 source/selection weights for regression comparison |
| `stage2_legacy` | `.standard` | Pre-Sky Forward Stage 2/default-calibration regression preset |

There is one math pipeline for shipped users: Release app -> `production` -> `.stage1Experimental` -> narrative-plan payload path. The two Sky Forward IDs differ only in state namespace and DEBUG presentation. Do **not** gate logic on `engineId == stage1_experimental`; gate on `DailyFitEngineMode`.

The `.standard` branches are intentional legacy paths. They support regression tests, fingerprint guards, and DEBUG engine comparisons; do not delete or "consolidate" them unless a future migration explicitly removes those presets.

**Inspector:** Start with `cd inspector && ./run-inspector.sh` (see §2.1). The inspector compiles the same symlinked engine sources as the app. Equal profile/date/blueprint/tarot-history inputs should produce equal payloads. Differences are usually stale inspector binary, different location/date inputs, tarot/variant recency, visible-essence recency, or a frozen revealed app payload.

**iOS DEBUG:** `DAILY_FIT_ENGINE_ID` can set the build default, and the Profile engine picker appears only when dev engine tools are allowed. Force refresh when comparing engines so stale frozen payloads are removed.

**iOS Release:** Always `production`; non-production plist values are ignored.

**CI / tests:** Do not set `DAILY_FIT_ENGINE_ID` in default CI. Unit tests pass explicit calibration/engine ids unless testing `DailyFitEngineConfig`.

**Further reading:** [`docs/handoff/sky_forward_final_consolidation_handoff.md`](docs/handoff/sky_forward_final_consolidation_handoff.md), [`docs/handoff/daily_fit_engine_selector_spec.md`](docs/handoff/daily_fit_engine_selector_spec.md), [`docs/handoff/daily_fit_personal_scale_sliders_handoff.md`](docs/handoff/daily_fit_personal_scale_sliders_handoff.md).

### 4.2 Style Guide pipeline (`CosmicBlueprint`)

The **Style Guide** is the user's permanent style profile (persisted as `CosmicBlueprint`). It's generated once and cached locally.

**Flow:** `NatalChart` → `BlueprintTokenGenerator` (generates `BlueprintToken`s using `astrological_style_dataset.json`) → `DeterministicResolver` (resolves textures, patterns, metals, stones, code directives) + `NarrativeCacheLoader` (loads pre-written paragraphs from `blueprint_narrative_cache.json` via `BlueprintArchetypeKey`) → `BlueprintComposer` (assembles final `CosmicBlueprint`).

The `ColourEngineV4` subsystem separately resolves the palette:
`NatalChart` → `ChartInputAdapter` → `ChartSignatureResolver` (determines palette family + cluster) → template colours + chart-derived accents → LCH normalisation → `PaletteSection`.

### 4.3 Natal Chart Calculation

`NatalChartCalculator` handles:
- Planet positions via VSOP87D data files (Sun, Moon, Mercury–Pluto)
- Asteroid positions via Swiss Ephemeris (Chiron, Lilith, North Node)
- House cusps (Placidus and Whole Sign systems)
- Ascendant and Midheaven
- Progressed charts (secondary progressions with solar arc option)
- Transit calculations (current planet positions vs natal, with aspect detection)
- Aspect calculations (conjunction, opposition, trine, square, sextile + minor aspects)

### 4.4 Authentication, Entitlements & Data Sync

- **Auth flow:** Email → OTP via Supabase Edge Functions (`send-otp` / `verify-otp`) → session token. Onboarding can call `signup-with-profile` to create auth + profile together.
- **Launch state:** Users can be complete-profile/authenticated, complete-profile/signed-out, onboarding-pending-auth, or first-run. `AppDelegate.performLaunchRouting()` chooses the correct shell.
- **Guest / signed-out mode:** Daily Fit and Style Guide can be browsed with local profile data, but reveal/section access is entitlement-aware. `SignedOutLandingViewController` and auth nudges guide signup.
- **Entitlements:** `EntitlementManager` combines StoreKit subscription status with promo/comp access (`StoreKitManager`, `PromoCodeService`, `CompAccessStorage`).
- **Sync:** Authenticated users can backup/restore profile + Style Guide (`CosmicBlueprint` JSON) via `SupabaseSyncService`. Daily Fit frozen payloads are local-only.
- **Account deletion:** `ProfileViewController` calls the `delete-account` edge function; deploy that function before claiming production deletion is live.
- **Deep linking:** `cosmicfit://` URL scheme for auth callbacks via `AuthDeepLinkRouter`.

### 4.5 Navigation & UI Architecture

- `AppDelegate` manages the full app lifecycle (no `SceneDelegate` — pre-iOS 13 style), auth listener, StoreKit/entitlement bootstrap, launch routing, and date-change refresh.
- Launch flow: `AnimatedLaunchScreenViewController` → welcome/onboarding when no complete profile; onboarding page 4 when auth is pending; `CosmicFitTabBarController` when authenticated; `SignedOutLandingViewController` when profile is complete but signed out.
- Tab bar has 2 primary tabs: Daily Fit and Style Guide. Natal Chart, Profile, purchases, FAQ, and legal/account actions are reached from the menu/profile flows rather than as primary tabs.
- All UI is programmatic UIKit with `NSLayoutConstraint`-based Auto Layout
- Theme system in `CosmicFitTheme.swift` defines app-wide colours, fonts, gradients
- Custom transitions: `SlideTabTransitionAnimator` (horizontal), `VerticalSlideAnimator` (vertical)
- Daily Fit refreshes on app active/day-change/significant-time-change notifications when the calendar day changes.

---

## 5. Tests, Audits & Current Findings

`Cosmic FitTests/` contains 60+ Swift test/support files across XCTest and Swift Testing. Prefer categories over exact line counts; the suite changes frequently.

| Area | Representative files | Purpose |
|---|---|---|
| **Sky Forward / engine registry** | `DailyFitSkyForwardV2_Tests`, `DailyFitEngineRegistry_Tests`, `DailyFitEngineConfig_Tests`, `ProductionFingerprintGuard_Tests` | Lock shipped engine mode, calibration/fingerprint, production output, and DEBUG override rules |
| **Daily energy / salience** | `DailyEnergyEngine_*`, `SkySalience_Tests`, `DailyFitCalibration_Tests`, `AstrologicalSoundness_Tests` | Vibe budgets, axes, lunar context, sky salience, sign/planet energy plausibility |
| **Narrative cohesion** | `DailyNarrativePlan_Tests`, `NarrativeIntentEngine_Tests`, `NarrativeTarotBridge_Tests`, `NarrativeCoherence_Tests`, `NarrativeCohesionReport_Tests` | Plan-driven cross-surface alignment; no generated Daily Brief copy in app |
| **Payload / sliders / recency** | `BlueprintLensEngine_Payload_Tests`, `PersonalScaleEnvelope_Tests`, `SliderSignalValidation_Tests`, `SliderRangeAudit_Tests`, `SliderDayVariation_Tests`, `DailyFitFrozenPayloadStorage_Tests` | Daily Fit assembly, display envelopes, reveal/frozen behaviour, day-to-day slider motion |
| **Style Guide / colour** | `ColourEngineV4_UnitTests`, `ColourReachability_Tests`, `MariaAshLocked_Tests`, `V4ReferenceAudit_Tests`, `PaletteGridViewModel_Tests` | Colour engine, locked Ash/Maria outputs, palette UI logic |
| **Distribution / goldens** | `DailyFitGoldens_Tests`, `DailyFitDistribution_Tests`, `DailyFitVariation_Tests`, `DailyFitCoherence_Tests`, `FixtureRegeneration` | Golden fixtures, cohort metrics, optional fixture regeneration |

### 5.1 Latest Sky Forward Audit Findings

The latest committed large-audit fixtures reflect wave-2 Sky Forward and the v1.0.1 production bump:

| Artifact | Scope | Current summary |
|---|---|---|
| `docs/fixtures/production_audit_v2/summary.txt` | 223 users x 60 days (`production`) | 66,900 / 66,900 verdict checks pass; 0 gap days; 0 tarot adjacent repeats; 0 hard-block violations; cohesion 1.0; M/F stuck users down to 4; structured/draped stuck users down to 0 |
| `docs/fixtures/narrative_cohesion_report.txt` | 216 users x 60 days (`stage1_experimental`, same math as production) | Opposition violations 0; mean coherence 0.9999; accent-salience match 88.7%; cross-surface violations 10 / 12,960 user-days (~0.08%), below the rate gate but not literally zero |
| `docs/fixtures/slider_range_report.json` | 216-user slider coverage | Wave-2 slider coverage is materially improved; contrast still has narrower range than other sliders and should be watched after future tuning |

### 5.2 Interpretation Caveats To Preserve

These are current product/QA truths, not failures:

- **Professional astrological accuracy is partially machine-checked, not professionally signed off.** Tests assert directional plausibility for elements, planets, signs, source weights, and lunar-axis behaviour, but there is no astrologer-authored per-user/per-day golden set.
- **Daily Fit internal contradictions are gated; Daily Fit vs Style Guide contradictions are not fully automated.** `DailyNarrativeCoherence` checks daily cross-surface conflicts, but there is no full blueprint/style-guide narrative comparison harness yet.
- **Full moons are mathematically influential but not explicitly named in the app UI.** Lunar phases affect energies and axes, yet key events are currently implicit. Eclipses, retrogrades, ingresses, void-of-course Moon, and returns are not first-class narrative events.
- **Cross-surface rate gate passes, zero-tolerance wording can mislead.** The report labels nonzero cross-surface count as FAIL, while the hard assertion is rate-based (`< 0.001`).

### 5.3 Validation Order For Future Engine Changes

Use the ordered runbook in [`docs/handoff/sky_forward_final_consolidation_handoff.md`](docs/handoff/sky_forward_final_consolidation_handoff.md). In short:

1. Unit/regression suites for registry, fingerprint, payload, envelope, narrative, and recency.
2. `SliderSignalValidation_Tests` for fast 12x60 signal checks.
3. `NarrativeCohesionReport_Tests` for 216x60 plan-level cohesion.
4. `tools/production_audit_harness.py` + `tools/production_audit_analyze.py` for 223x60 inspector-backed production audit.

**Test fixtures** live in `docs/fixtures/` — JSON and text files with known-good reference outputs. `docs/fixtures/` is QA/tuning artefact storage, not app runtime.

**Parallel test runs / flaky clones:** See [`docs/archive/test_handoff.md`](docs/archive/test_handoff.md) and newer green-path docs if present. Set `CALIBRATION_REPORT_DIR` when a test job writes reports.

**UI Tests:** `Cosmic FitUITests/` contains boilerplate Xcode template files only; there is no meaningful automated E2E coverage yet.

---

## 6. Deep Handoffs & Runbooks

This README is the current front door. Use these docs for implementation-level detail, but check the stale notes before copying claims forward.

| Doc | Use when |
|---|---|
| [`docs/handoff/sky_forward_final_consolidation_handoff.md`](docs/handoff/sky_forward_final_consolidation_handoff.md) | Sky Forward promotion model, code map, validation order, and what not to overwrite |
| [`docs/handoff/unified_daily_fit_audit_handoff.md`](docs/handoff/unified_daily_fit_audit_handoff.md) | Production audit harness history and 223x60 analysis workflow |
| [`docs/handoff/daily_fit_engine_selector_spec.md`](docs/handoff/daily_fit_engine_selector_spec.md) | Engine selector wiring, frozen payload namespacing, Release/DEBUG guardrails |
| [`docs/handoff/daily_fit_inspector_app_parity_followup_handoff.md`](docs/handoff/daily_fit_inspector_app_parity_followup_handoff.md) | App vs inspector mismatch debugging and parity checklist |
| [`docs/handoff/daily_fit_stage1_experimental_app_readiness_handoff.md`](docs/handoff/daily_fit_stage1_experimental_app_readiness_handoff.md) | App payload parity, ghost triangle, DEBUG enablement; promotion-state sections are historical |
| [`docs/handoff/daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](docs/handoff/daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md) | Narrative cohesion rules, no generated daily prose, plan-driven selection |
| [`docs/handoff/daily_fit_personal_scale_sliders_handoff.md`](docs/handoff/daily_fit_personal_scale_sliders_handoff.md) | Personal scale envelope design intent and slider semantics |
| [`docs/handoff/legal_production_audit_handoff.md`](docs/handoff/legal_production_audit_handoff.md) | Privacy/Terms sync, UK entity, account deletion, and legal deployment checks |

**Known stale handoff caveat:** older Sky Forward docs that describe `stage1_experimental` as the real engine and production as unchanged are superseded for promotion state. Current code has `production` shipping Sky Forward v1.0.1.

---

## 7. Legacy Code, Dead Ends & Cleanup Targets

### 7.1 Confirmed Dead / Legacy Code (safe to remove)

**Files that are entirely dead (no call sites in active codebase):**

| File | Why It's Dead | Action |
|---|---|---|
| `_archive/` directory | 8 files (308 KB): `CompositeTheme.swift`, old `InterpretationTextLibrary.swift`, `ParagraphAssembler.swift` (72 KB!), `ThemeSelector.swift`, `Tier2TokenLibrary.swift` (97 KB), `TokenEnergyOverrides.swift`, `TokenPrefixMatrix.swift`, `extracted_planet_sign_token_tables.json`. All explicitly archived, not compiled. | **Delete entire directory** |
| `Cosmic FitUITests/` | Boilerplate Xcode template — `testExample` has no assertions, `testLaunch` only screenshots. | **Delete** |
| `ParagraphBlock.swift` | No references in active Swift code. Leftover from removed ParagraphAssembler. | **Delete** |
| `StructuralAxes.swift` | No references in active Swift code. | **Delete** |
| `ColourScoring.swift` | No references in active Swift code. Legacy "Daily System" scoring. | **Delete** |
| `TransitWeightCalculator.swift` | No call sites. `DailyEnergyEngine` uses its own simpler transit scoring. | **Delete** |
| `TarotSelectionMonitor.swift` | No references. Superseded by `BlueprintLensEngine` scoring. | **Delete** |
| `WeatherFabricFilter.swift` | Only referenced from archived `ParagraphAssembler.swift`. | **Delete** |
| `Ephemeris+Helpers.swift` | `bigFour`, `BodyPosition`, `Date.julianDayUT` — none are called anywhere. Duplicates `AsteroidCalculator` functionality. | **Delete** |
| `AstrologicalInterpreter.swift` | `interpretNatalChart` is only reachable via `NatalChartManager.interpretNatalChart` which itself is never called. `generateGuidance` has no call sites. 665 lines of static text tables with no consumers. | **Delete** |
| `CardPresentationController.swift` | Custom presentation controller with zero references anywhere in the project. | **Delete** |
| `LocationResultTableViewCell.swift` | No references. Superseded by `LocationSuggestionCell` inside `LocationAutocompleteView`. | **Delete** |
| `StarView.swift` | No references in any other file. | **Delete** |
| `Palette/ColourCell.swift` | `UICollectionViewCell` subclass — no references. The palette grid uses plain `UIView` cells instead. | **Delete** |

**Files that are mostly or partially dead:**

| File | Dead Portions | Action |
|---|---|---|
| `InterpretationTextLibrary.swift` | 1933 lines. Header says "⚠️ LEGACY SYSTEM - NOT CURRENTLY USED". The `TokenGeneration` substructs ARE still read by `SemanticTokenGenerator`, but the large `DailyVibe`, `StyleGuide`, `MoonPhase`, `Weather` prose tables and `getText()` method have no consumers. | **Delete** (verify `SemanticTokenGenerator` refs first) |
| `NatalChartManager+Interpretation.swift` | Returns hardcoded placeholder strings. No call sites. | **Delete** |
| `NatalChartManager.swift` | `saveNatalChart`, `loadNatalChart`, `getSavedChartNames`, `deleteNatalChart`, `interpretNatalChart`, `calculateTypedTransits` — all orphaned. Commented-out method block (lines 172–222). | **Remove dead methods and comment block** |
| `CosmicFitInterpretationEngine.swift` | Outputs placeholder text. `calculateCurrentMoonPhase()` and `getCurrentJulianDay()` are never called. `generateCustomStyleGuidance()` is hardcoded if/else. | **Rewrite or delete** |
| `AppDelegate.swift` | `configureAppearance()` is never called (duplicate of `setupGlobalAppearance()`). `handleDailyVibeUpdate()` is `@objc` but never registered with NotificationCenter. | **Remove dead methods** |
| `CoordinateTransformations.swift` | `eclipticToEquatorial`, `equatorialToHorizon`, `equatorialToEcliptic`, `geocentricToTopocentric`, `formatDegrees`, `parseFormattedDegrees`, `zodiacToDecimalDegrees`, `normalizeRadians` — none called outside this file. | **Remove unused methods** |
| `SupabaseSyncService.swift` | `syncPreferencesToSupabase()` has no callers. | **Remove** |
| `MoonPhaseInterpreter.swift` | `tokensForStyleGuideRelevance` and `tokensForDailyVibe` have no references outside this file. Phase classification IS used by `DailyEnergyEngine`. | **Remove dead token methods** |
| `TarotCard.swift` | `StyleEditSelector` class is defined but `BlueprintLensEngine` uses rotation instead. `calculateMatchScore` pipeline is legacy (superseded by cosine scoring). `extractEnergyFromVibe` normalises by 100 instead of 21 — mismatched semantics. | **Remove legacy scoring code** |
| `DailyFitViewController.swift` | `originalChartViewController` stored never read. `cardTitleLabel` unused. `setupScrollIndicator()` never called. `createThemedStyledText()` and `createThemedVibeBreakdownText()` never called. | **Remove dead properties/methods** |
| `StyleGuideDetailViewController.swift` | `birthDate`, `birthCity`, `birthCountry`, `originalChartViewController`, `tabBarHeight`, `interactiveDismissalInProgress`, `initialTouchPoint` — all declared, never used. | **Remove dead properties** |
| `StyleGuideViewController.swift` | `configure(with content:)` parameter `content` is unused. `originalChartViewController` held but never used. Navigation delegate + `VerticalSlideAnimator` effectively unused in current flow. | **Clean up** |
| `NatalChartViewController.swift` | `DebugInitializer.setupDebugEnhancements()` never called. `showStyleGuideInterpretation()` / `showStyleGuideInterpretationWithDebug()` duplicated, both show placeholder. `handleDateChange()` only prints. | **Remove dead code** |
| `VerticalSlideAnimator.swift` | Only referenced from `StyleGuideViewController`'s navigation delegate, but Style Guide never pushes. Effectively unused. | **Delete or defer** |
| `EngineConfig.swift` | Partially superseded by `DailyFitCalibration`. `TarotRecencyTracker` still reads some values. | **Reconcile with DailyFitCalibration** |
| `DerivedAxesConfiguration.swift` | Thresholds for legacy copy-selection. `DailyFitCalibration.PlanetAxisMap` may supersede. | **Verify references, potentially delete** |

**Non-code files to remove or relocate:**

| File/Directory | Action |
|---|---|
| `BLUEPRINT_REBUILD_SPEC_v2.3.md` | **Delete** (82 KB historical spec at repo root) |
| `INLINE_LOCATION_AUTOCOMPLETE.md` | **Delete** (feature spec at repo root) |
| `__pycache__/` | **Delete, add to .gitignore** |
| `.venv/` | **Add to .gitignore** |
| Root-level Python scripts | **Resolved** — live under **`tools/`** |
| ~~Root-level JSON duplicates~~ | **Resolved** — canonical files under **`data/style_guide/`**; **`Resources/`** uses symlinks. |
| Duplicate **`requirements.txt`** at repo root | **Resolved** — dependencies live in **`tools/requirements.txt`**. |
| `docs/` directory | Review and prune planning artefacts. Keep `docs/fixtures/` (test fixtures). |

### 7.2 Files with Naming Issues

| Issue | File |
|---|---|
| Trailing space in filename | `VibeBreakdown .swift` — should be `VibeBreakdown.swift` |
| `.DS_Store` files checked in | Root, `Cosmic Fit/`, `Cosmic Fit/Resources/` |

### 7.3 Bugs & Risks

| Risk | Details |
|---|---|
| **VSOP87 load failures** | **`VSOP87Parser`** uses a **Keplerian fallback** if VSOP87D files cannot be loaded (no `fatalError` in the VSOP87 parser for missing theory files). **`VSOP87BundleIntegrity_Tests`** preflights bundle resources from **`Bundle.main`**. Separately, **`SwissEphemerisBootstrap`** may still `fatalError` if **`seas_18.se1`** is missing — that is Swiss Ephemeris bootstrap, not VSOP87. |
| ~~**`SemanticTokenGenerator` sign math bug**~~ | **Resolved** for the Style Guide token path: 1-based zodiac element/modality is covered by **`SemanticTokenGenerator_ZodiacMath_Tests`**. If you change zodiac math, run that suite and re-check Part 3 distribution tests. |
| **Multiple `Package.resolved` contexts** | The app workspace and the inspector package resolve dependencies separately. Keep both in sync intentionally when bumping shared packages; do not assume inspector dependency changes affect the Xcode workspace. |
| **Secrets possibly committed** | `Dev.xcconfig` and `Prod.xcconfig` are gitignored by `.gitignore`, but the checked-in files may contain real Supabase credentials. Verify and rotate if exposed. |
| **"Daily Vibe" naming drift** | `AppDelegate`, `UserProfileStorage`, and several notifications still reference "Daily Vibe" (the old feature name) while the product is "Daily Fit". Confusing for new developers. |

### 7.4 Structural Concerns

| Concern | Details |
|---|---|
| **Placeholder interpretation path** | `CosmicFitInterpretationEngine.generateStyleGuideInterpretation()` returns placeholder text. The Style Guide tab works for real sections (palette, textures, etc.) via `BlueprintStorage` + `CosmicBlueprint`, but the old sentence-assembly interpretation is disconnected. |
| ~~**Duplicate data files**~~ | **Resolved** — single canonical **`data/style_guide/`** tree; tests use `StyleGuideDataURL`; bundle entries are symlinks. |
| **DailyFitViewController is very large** | God-controller handling layout, reveal state, entitlement presentation, payload rendering, tarot card display, colour palette, essence radar, silhouette bars, vibe breakdown, transit list, lunar phase, texture/pattern display, animations, and scroll management. Should be decomposed. |
| **CosmicFitTabBarController is very large** | Handles tab setup, Style Guide generation, Daily Fit orchestration, caching, notification handling, debug logging, refresh flows, and menu presentation. Too many responsibilities. |
| **Singleton overuse** | `NatalChartManager.shared`, `SavedChartStorage.shared`, `TarotRecencyTracker.shared`, `TarotVariantRotationTracker.shared`, `UserProfileStorage.shared`, `BlueprintStorage.shared`, `CosmicFitAuthService.shared`, `LocationManager` — makes testing and dependency injection difficult. |
| **Mixed data flow patterns** | Some paths use `[String: Any]` dictionaries (legacy `calculateNatalChart` return type) while the modern pipeline uses typed structs. The dictionary-based API should be phased out. |
| **No dependency injection** | `TarotRecencyTracker.shared` / `TarotVariantRotationTracker.shared` are called inside `BlueprintLensEngine` static methods, making those methods harder to test in isolation. |
| **SemanticTokenGenerator serves two masters** | Generates tokens for both the placeholder interpretation path and the `CosmicBlueprint` composition path. `generateStyleGuideTokens` is only consumed by the placeholder `CosmicFitInterpretationEngine`. |
| **Tests write to `docs/`** | Several test suites write fixture files and reports to `docs/fixtures/`. Set **`CALIBRATION_REPORT_DIR`** in CI to a temp directory to avoid parallel job collisions; report filenames include a run disambiguator (see **`CalibrationReportHelper`**). |
| **No UI/E2E test coverage** | UITests are boilerplate. No automated user journey tests (onboarding, Daily Fit, Style Guide, auth flow). |

---

## 8. Strengths

| Strength | Details |
|---|---|
| **Deterministic, testable pipeline** | The Daily Fit pipeline is deterministic for equal profile/date/blueprint/engine/recency inputs, making it highly testable. Calibration, fingerprint, and recency namespaces make engine changes auditable. |
| **Comprehensive test suite** | Broad XCTest coverage from unit tests through snapshot tests to integration tests, plus calibration / distribution harnesses under **`Cosmic FitTests/`**. Locked reference tests (`MariaAshLocked_Tests`) prevent regressions. |
| **Clean type contracts** | `DailyFitTypes.swift` defines well-documented Codable types with backward-compatible decoding (e.g., `EssenceTriangle` → `StyleEssenceProfile` migration). |
| **Sophisticated colour engine** | ColourEngineV4 is a well-structured subsystem with clear separation of concerns (family resolution, template mapping, normalisation, accent placement, validation). |
| **Diagnostic infrastructure** | `DailyFitDiagnostics` generates complete pipeline traces. `BlueprintLensEngine.logDailyFitDiagnostics()` provides rich console output. `generateSnapshotWithTrace()` and `generatePayloadWithTrace()` expose intermediate values. |
| **Style Guide data model is production-ready** | `BlueprintModels.swift` defines `CosmicBlueprint` with versioned fields (V4, V4.2, V4.3, V4.4), optional backward-compatible decoding, and clear field-source documentation (D/AI/U/M). |
| **Calibration and tuning surfaces** | `DailyFitCalibration` centralises preset weights and selection policy; Sky Forward slider/display tuning lives in `BlueprintLensEngine`, `DailyEnergyEngine`, and `PersonalScaleEnvelope`. |

---

## 9. Key Data Contracts

### VibeBreakdown (21-point budget)
Six integer values (0–10 each) summing to exactly 21:
`classic + playful + romantic + utility + drama + edge = 21`

### DerivedAxes (1–10 scale)
Four continuous values: `action`, `tempo`, `strategy`, `visibility`

### DailyEnergySnapshot (Stage 1 output)
Contains: `vibeProfile`, `axes`, `dominantTransits`, `lunarContext`, `dailySeed`, `profileHash`, `generatedAt`, and Sky Forward-only support such as `chartVibeProfile`, `skyVibeProfile`, and `skySalience`.

### DailyFitPayload (pipeline output / what the UI renders)
Contains: `tarotCard`, `styleEditVariant`, `dailyPalette`, `vibrancy`, `contrast`, `metalTone`, `scalePresentation`, `essenceProfile`, `silhouetteProfile`, `vibeBreakdown`, `axes`, `dominantTransits`, `lunarContext`, `dailyTextures`, `dailyPattern`, `dailyFitEngineId`, and `generatedAt`.

### `CosmicBlueprint` — persisted Style Guide (permanent per-user)
Contains: `userInfo`, `styleCore`, `textures`, `palette`, `occasions`, `hardware`, `code`, `accessory`, `pattern`, `generatedAt`, `engineVersion`

---

## 10. Configuration & Secrets

| File | Purpose | Gitignored? |
|---|---|---|
| `Cosmic Fit/Config/Dev.xcconfig` | Supabase URL + API key (dev) | Yes |
| `Cosmic Fit/Config/Prod.xcconfig` | Supabase URL + API key (prod) | Yes |
| `.env` | Python tooling env vars (includes `DAILY_FIT_ENGINE_ID` for documentation) | Yes |
| `Dev.xcconfig.example` | Template for dev config (Supabase + `DAILY_FIT_ENGINE_ID`) | No (committed) |
| `.env.example` | Template for Python env + Daily Fit engine preset | No (committed) |

**Optional — Daily Fit engine id sync:** iOS reads `DAILY_FIT_ENGINE_ID` from xcconfig → Info.plist at build time (not from `.env` at runtime). After editing `DAILY_FIT_ENGINE_ID` in `.env`, run `./tools/sync_env_to_xcconfig.sh` to patch **only** that key in `Dev.xcconfig` / `Prod.xcconfig` (Supabase keys are untouched). Rebuild the app to apply. Not required for local dev — you can set the xcconfig line manually.

---

## 11. Build & Run

1. Open `Cosmic Fit.xcworkspace` (not the `.xcodeproj`)
2. Copy `Dev.xcconfig.example` → `Dev.xcconfig` and fill in Supabase credentials. Keep `DAILY_FIT_ENGINE_ID = production` unless you are deliberately testing another preset (see **§4.1.1**). The same key is documented in `.env.example`.
3. SPM dependencies resolve automatically on first open
4. Build target: `Cosmic Fit` (iOS Simulator or device)
5. Tests: `Cosmic FitTests` target — run via `Cmd+U`

**Optional — Cosmic Fit Inspector (macOS):** `cd inspector && ./run-inspector.sh`, then open **http://127.0.0.1:7777** (see §2.1 and **`inspector/README.md`**). After changing engine code under `Cosmic Fit/InterpretationEngine/`, always restart via the script so symlinked sources are recompiled.

**Optional — dataset QA (Python):** `python3 tools/validate_dataset.py` (see §2.1).

**Optional — calibration gates from Terminal:** pass **`CALIBRATION_CI_GATE=1`** and optionally **`CALIBRATION_REPORT_DIR`** when running `xcodebuild test` (see §2.2 and **`docs/calibration_plan_closure_summary.md`**).

---

## 12. Cleanup Checklist for New Developer

### Phase 1: Safe deletions (zero functional impact)

- [ ] Delete `_archive/` directory entirely
- [ ] Delete `Cosmic FitUITests/` (boilerplate only)
- [ ] Delete `BLUEPRINT_REBUILD_SPEC_v2.3.md` and `INLINE_LOCATION_AUTOCOMPLETE.md` from repo root
- [ ] Delete `__pycache__/`, add to `.gitignore`
- [ ] Ensure `.venv/` is in `.gitignore`
- [ ] Remove `.DS_Store` files and add `**/.DS_Store` to `.gitignore`
- [ ] Delete entirely orphaned files: `ParagraphBlock.swift`, `StructuralAxes.swift`, `ColourScoring.swift`, `TransitWeightCalculator.swift`, `TarotSelectionMonitor.swift`, `WeatherFabricFilter.swift`, `Ephemeris+Helpers.swift`, `AstrologicalInterpreter.swift`
- [ ] Delete orphaned UI files: `CardPresentationController.swift`, `LocationResultTableViewCell.swift`, `StarView.swift`, `Palette/ColourCell.swift`
- [ ] Rename `VibeBreakdown .swift` → `VibeBreakdown.swift` (fix trailing space)

### Phase 2: Dead method / property removal (verify build succeeds)

- [ ] Delete `NatalChartManager+Interpretation.swift` (all-placeholder, no call sites)
- [ ] Delete dead methods in `NatalChartManager.swift`: `saveNatalChart`, `loadNatalChart`, `getSavedChartNames`, `deleteNatalChart`, `interpretNatalChart`, `calculateTypedTransits`, commented-out `calculateTransitChart` block
- [ ] Delete `AppDelegate.configureAppearance()` (never called), `handleDailyVibeUpdate()` (never registered)
- [ ] Remove unused properties in `DailyFitViewController`: `originalChartViewController`, `cardTitleLabel`, `setupScrollIndicator()`, `createThemedStyledText()`, `createThemedVibeBreakdownText()`
- [ ] Remove unused properties in `StyleGuideDetailViewController`: `birthDate`, `birthCity`, `birthCountry`, `originalChartViewController`, `tabBarHeight`, `interactiveDismissalInProgress`, `initialTouchPoint`
- [ ] Remove `DebugInitializer` class and swizzle in `NatalChartViewController.swift`
- [ ] Remove `StyleEditSelector` class from `TarotCard.swift`
- [ ] Remove unused helpers in `CoordinateTransformations.swift`
- [ ] Remove `SupabaseSyncService.syncPreferencesToSupabase()` (no callers)
- [ ] Remove dead token methods from `MoonPhaseInterpreter.swift`
- [ ] Delete `VerticalSlideAnimator.swift` (effectively unused in current flow)

### Phase 3: Legacy evaluation (requires design decision)

- [ ] Delete or rewrite `InterpretationTextLibrary.swift` — confirm `SemanticTokenGenerator` can be refactored to not depend on `TokenGeneration` substructs
- [ ] Decide fate of `CosmicFitInterpretationEngine.swift` — the Style Guide needs either a real implementation or removal
- [ ] Reconcile `EngineConfig.swift` and `DerivedAxesConfiguration.swift` with `DailyFitCalibration`
- [x] Fix `SemanticTokenGenerator.getSignElement/getSignModality` for 1-based zodiac indices — covered by **`SemanticTokenGenerator_ZodiacMath_Tests`** (see **`docs/calibration_plan_closure_summary.md`**)
- [x] VSOP87 missing-file safety — **`VSOP87Parser`** uses Keplerian fallback (no `fatalError` for missing VSOP files); optional future improvement: thread **`throws`** through **`NatalChartCalculator`** for explicit errors instead of silent fallback

### Phase 4: Repo hygiene

- [x] Move Python scripts + `requirements.txt` into **`tools/`** (see **`tools/README.md`**)
- [x] Canonical Style Guide JSON under **`data/style_guide/`**; **`Resources/`** symlinks (see **`data/style_guide/README.md`**)
- [ ] Keep app workspace and inspector package dependency resolution in sync intentionally when bumping shared packages
- [ ] Review `docs/` — keep `docs/fixtures/` (test data), prune planning artefacts
- [ ] Rename "Daily Vibe" → "Daily Fit" in `AppDelegate`, `UserProfileStorage`, notification names
- [ ] Verify `Dev.xcconfig` / `Prod.xcconfig` aren't committed with real secrets; rotate if so

### Phase 5: Architectural improvements (larger effort)

- [ ] Decompose the very large `DailyFitViewController` into child views/controllers or a coordinator
- [ ] Decompose the very large `CosmicFitTabBarController` — extract Style Guide / Daily Fit orchestration
- [ ] Introduce dependency injection to replace singleton calls inside engine methods
- [ ] Phase out `[String: Any]` dictionary API from `NatalChartCalculator` in favour of typed `NatalChart` returns

---

## 13. File Inventory Summary

Exact counts churn quickly; use this as an orientation map rather than a line-count contract.

| Layer | What to expect |
|---|---|
| App / lifecycle | `AppDelegate` plus launch/auth/date-change orchestration |
| Core | Chart calculation, config, services, storage, location/weather, ephemeris bootstrap |
| InterpretationEngine | Style Guide composer, ColourEngineV4, Sky Forward Daily Fit pipeline, narrative plan/coherence, tarot/recency, diagnostics |
| UI | Programmatic UIKit screens, custom views, purchase/legal/profile flows, Daily Fit and Style Guide rendering |
| Tests | 60+ Swift files across engine, Style Guide, Daily Fit, narrative, fixture, and regression coverage |
| Inspector | Separate Swift package with symlinked app engine sources and local web UI |
| Supabase | Migrations plus Deno edge functions for auth, profile/signup, deletion, subscriptions, promo/comp access |

| Resource | Role |
|---|---|
| `Cosmic Fit/Resources/TarotCards.json` | 78-card tarot deck with energy/axis affinity and style edits |
| `data/style_guide/astrological_style_dataset.json` | Canonical Style Guide astrological dataset |
| `data/style_guide/blueprint_narrative_cache.json` | Canonical reviewed Style Guide narrative cache |
| `Cosmic Fit/Resources/VSOP87Data/` | Bundled planetary theory files |
| `Cosmic Fit/Resources/seas_18.se1` | Swiss Ephemeris asteroid/moon data |
| `Cosmic Fit/Resources/Assets.xcassets/Cards/` | Tarot/card image assets |
| `Cosmic Fit/Resources/Fonts/` | Bundled DM Sans, DM Serif Text, PT Serif fonts |
