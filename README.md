# Cosmic Fit — Codebase Reference & Handoff Document

> **Last audited:** May 2026
> **Bundle ID:** `com.thisisbullish.cosmicfit`
> **Platform:** iOS (UIKit, no SwiftUI, no storyboards except LaunchScreen)
> **Deployment target:** iOS 18.4
> **Language:** Swift 5
> **Dev Team:** `653BNKDSZS` (app target), `J5V4NZ3334` (project/test targets)

---

## 1. What Cosmic Fit Does

Cosmic Fit is an astrology-meets-fashion iOS app. It computes a natal birth chart from a user's birth date, time, and location, then translates astrological placements into personalised style guidance. The app has two primary outputs:

1. **Style Guide** — A permanent, per-user colour palette, texture recommendations, pattern guidance, accessory suggestions, hardware (metals/stones), and occasion-specific style advice. Generated once from the natal chart and cached. In code and on disk this data is the `CosmicBlueprint` model (`BlueprintStorage`, `BlueprintComposer`, etc.); older docs and filenames still say “blueprint” but the product name is **Style Guide**.

2. **Daily Fit** — A daily-changing style card powered by transiting planets, lunar phase, and the user's natal chart. Produces a tarot card selection, style-edit text, daily colour picks, vibrancy/contrast/metal-tone scales, a 14-category style-essence radar, silhouette profile, textures, and optional pattern. Deterministic per-user-per-day (seeded randomness).

---

## 2. Tech Stack & Dependencies

| Component | Detail |
|---|---|
| **UI Framework** | UIKit, 100% programmatic (no storyboards, no SwiftUI) |
| **Package Manager** | Swift Package Manager (via Xcode workspace) |
| **Ephemeris Library** | `SwissEphemeris` 0.0.99 (vsmithers1087) — planetary position calculations |
| **Backend** | Supabase Swift SDK 2.43.1 — auth (OTP), profile sync, cloud storage |
| **Crypto** | `swift-crypto` 4.3.1 (transitive via Supabase) |
| **HTTP** | `swift-http-types` 1.5.1 (transitive via Supabase) |
| **Concurrency** | `swift-concurrency-extras` 1.3.2, `swift-clocks` 1.0.6 (transitive) |
| **Planetary Data** | VSOP87D data files (bundled per-planet: `.ear`, `.jup`, `.mar`, etc.) |
| **Ephemeris Data** | `seas_18.se1` (Swiss Ephemeris asteroid/moon data) |
| **Fonts** | DM Sans (18 weights), DM Serif Text (2 weights), PT Serif (2 weights) |
| **Build Config** | `Dev.xcconfig` / `Prod.xcconfig` for Supabase URL and API key injection |
| **Backend Functions** | Supabase Edge Functions: `send-otp`, `verify-otp` (Deno/TypeScript) |
| **Database** | Supabase PostgreSQL — `001_initial_schema.sql` migration |
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

#### Swift test harness — blueprint fixture regeneration

| Location | Purpose |
|---|---|
| **`Cosmic FitTests/FixtureRegeneration.swift`** | Optional regeneration of **`docs/fixtures/blueprint_input_user_1.json`** and **`blueprint_input_user_2.json`** via the production **`BlueprintComposer`** pipeline. **Default:** validates fixture shape only (safe for CI). **To rewrite files on disk:** set environment variable **`REGENERATE_BLUEPRINT_FIXTURES=1`** when running that test. Output timestamps are pinned for byte-stable diffs. |

#### Cosmic Fit Inspector (local web UI)

A **macOS-only** sibling Swift package under **`inspector/`** that runs the **same** interpretation engine as the iOS app (via symlinks into `Cosmic Fit/`), served by a small **Hummingbird** HTTP server with a **vanilla HTML/CSS/JS** UI. Use it to inspect Style Guide (`CosmicBlueprint`) and Daily Fit (`DailyFitPayload` + `DailyFitDiagnosticReport`) for arbitrary birth inputs or preset charts, change the target calendar day, compare adjacent days, skim provenance/trace accordions, and run lightweight verdict checks — without building or deploying the iOS app.

**Start the server** (from repo root; first run may take a few minutes to resolve SPM deps):

```bash
cd inspector
swift run cosmicfit-inspector
```

Open **http://127.0.0.1:7777** in a browser on the same machine. The server binds **loopback only** (`127.0.0.1:7777`); it is not intended for LAN or public hosting and has no auth.

**Requirements:** macOS 14+, Xcode/Swift toolchain able to build the package. Resources under **`inspector/Resources/`** are symlinks to the shared style dataset, narrative cache, VSOP87 data, and Swiss Ephemeris files (see **`inspector/README.md`** for layout, API summary, presets, and security notes).

#### Supabase (backend authoring)

| Path | Purpose |
|---|---|
| **`supabase/functions/send-otp`**, **`verify-otp`** | Deno/TypeScript Edge Functions for phone OTP (sources for deploy; not executed by the iOS build). |
| **`supabase/migrations/`** | SQL migrations (e.g. **`001_initial_schema.sql`**) for the hosted database. |

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
├── Resources/                       # Symlinks to style_guide JSON, VSOP87, Swiss Ephemeris, presets
├── Sources/
│   ├── CosmicFitInspectorLib/       # Engine sources (symlinks) + request/response/engine glue
│   └── CosmicFitInspectorServer/    # `cosmicfit-inspector` executable + static Web/ UI
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
│   │   ├── NatalChartCalculator.swift # Heart of astrological computation (1388 lines): natal charts, progressed charts, transits, house systems, aspects
│   │   ├── AstronomicalCalculator.swift # Sun, Moon, planet positions from VSOP87/Swiss Ephemeris
│   │   ├── AstrologicalInterpreter.swift # Textual interpretations of chart placements
│   │   ├── AsteroidCalculator.swift   # Chiron, Lilith, North Node calculations
│   │   └── JulianDateCalculator.swift # Calendar ↔ Julian Day conversions
│   ├── Config/
│   │   ├── DebugConfiguration.swift   # Debug flag toggle and conditional logging
│   │   └── SupabaseConfig.swift       # Reads Supabase URL/key from Info.plist
│   ├── Services/
│   │   ├── CosmicFitAuthService.swift # Supabase OTP auth, session management, auth state notifications
│   │   ├── SupabaseSyncService.swift  # Profile + Style Guide (`CosmicBlueprint`) cloud sync (upload/download JSON)
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
│   ├── DailyEnergyEngine.swift        # Stage 1: natal+transits+lunar+progressed → VibeBreakdown (21-point budget) + DerivedAxes
│   ├── BlueprintLensEngine.swift      # Stage 2 Daily Fit: snapshot + CosmicBlueprint → DailyFitPayload (tarot, palette, textures, etc.)
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
│   │   ├── DailyFitViewController.swift # Daily Fit screen (2140 lines) — renders full DailyFitPayload
│   │   ├── NatalChartViewController.swift # Natal chart display with ChartWheelView
│   │   ├── StyleGuideViewController.swift # Style Guide hub (sections from `CosmicBlueprint`)
│   │   ├── StyleGuideDetailViewController.swift # Detail view for style guide sections
│   │   ├── ProfileViewController.swift # User profile display and edit
│   │   ├── InterpretationViewController.swift # Chart interpretation text display
│   │   ├── OnboardingFormViewController.swift # Birth data input form
│   │   ├── AnimatedLaunchScreenViewController.swift # Animated splash screen
│   │   ├── AnimatedWelcomeIntroViewController.swift # First-launch welcome flow
│   │   ├── AuthGateViewController.swift # Auth state gate (guest vs authenticated)
│   │   ├── OTPVerifyViewController.swift # OTP code entry for phone auth
│   │   ├── MenuViewController.swift   # Side/overlay menu
│   │   ├── FAQViewController.swift    # FAQ display
│   │   ├── GenericDetailViewController.swift # Reusable detail view
│   │   ├── PaymentPlaceholderViewController.swift # Placeholder for future payment flow
│   │   └── CardPresentationController.swift # Custom modal card presentation
│   └── Views/
│       ├── ChartWheelView.swift       # Natal chart wheel visualisation
│       ├── ColourPaletteView.swift     # Style Guide palette display (545 lines)
│       ├── DailyColourPaletteView.swift # Daily palette display (3 colours + context ring)
│       ├── EssenceTriangleView.swift   # 14-category essence radar chart (NEW)
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

### 4.1 Daily Fit Pipeline (the core of the app)

The Daily Fit is a **two-stage deterministic pipeline**:

#### Stage 1: Energy Snapshot (`DailyEnergyEngine`)

**Input:** natal chart, progressed chart, transit aspects, moon phase, date, calibration weights
**Output:** `DailyEnergySnapshot`

The engine blends five astrological sources with configurable weights (`DailyFitCalibration.SourceWeights`):

| Source | Weight | Purpose |
|---|---|---|
| Natal chart | 0.40 | Stable personality foundation |
| Transits | 0.25 | Daily variation driver |
| Lunar phase | 0.15 | Emotional/cyclical rhythm |
| Progressed chart | 0.15 | Slow personal evolution |
| Current sun sign | 0.05 | Seasonal background |

Each source contributes to six energy dimensions (`Energy` enum): **classic, playful, romantic, utility, drama, edge**. Raw scores are:
1. Accumulated from planet-energy base maps and element boosts
2. Multiplied by sun-sign-specific multipliers (`SignEnergyMap`)
3. Normalised to a **21-point integer budget** using largest-remainder allocation

The snapshot also includes:
- **DerivedAxes** (action, tempo, strategy, visibility) — 1–10 scale, sigmoid-mapped from planet-axis weights with element modifiers and moon-phase modulation
- **Dominant transits** — top 5 by orb tightness × planet weight × aspect weight
- **Lunar context** — phase name, waxing/waning, element, degrees
- **Daily seed** — deterministic `Int` from `profileHash + date` (ensures reproducibility)

#### Stage 2: Daily Fit lens (`BlueprintLensEngine`)

Applies the user’s **Style Guide** (`CosmicBlueprint`) to Stage 1 output. Type names retain the historical `Blueprint*` prefix.

**Input:** `DailyEnergySnapshot` + `CosmicBlueprint`
**Output:** `DailyFitPayload`

Selects and derives everything the UI renders:

| Field | Source |
|---|---|
| **Tarot card** | Cosine similarity (vibe + axes vectors vs card affinity), transit boost, recency penalty. Top-2 tiebreak by dailySeed. |
| **Style edit variant** | Rotation tracker (round-robin per card per profile) |
| **Daily palette** (3 colours) | Colours from the Style Guide palette scored by role-energy alignment, drama-driven slot allocation (statement vs grounding) |
| **Vibrancy** | Style Guide saturation baseline ± energy modulation (drama+edge vs utility+classic) |
| **Contrast** | Style Guide contrast baseline ± visibility axis modulation |
| **Metal tone** | Style Guide temperature + metal keywords ± transit fire/water nudge + lunar nudge |
| **Style essence** (14-category radar) | Weighted matrix: 14 categories × 6 energies + axis modifiers → top 3 displayed |
| **Silhouette profile** (3 bipolar scales) | Style Guide keyword scan baseline (~75%) + axes modulation (~25%) |
| **Textures** (2–3) | Style Guide textures scored by axis-keyword affinity |
| **Pattern** (optional) | Gated: visibility ≥ 6.0 AND dominant energy is drama/playful/edge |

### 4.2 Style Guide pipeline (`CosmicBlueprint`)

The **Style Guide** is the user's permanent style profile (persisted as `CosmicBlueprint`). It's generated once and cached locally.

**Flow:** `NatalChart` → `BlueprintTokenGenerator` (generates `BlueprintToken`s using `astrological_style_dataset.json`) → `DeterministicResolver` (resolves textures, patterns, metals, stones, code directives) + `NarrativeCacheLoader` (loads pre-written paragraphs from `blueprint_narrative_cache.json` via `BlueprintArchetypeKey`) → `BlueprintComposer` (assembles final `CosmicBlueprint`).

The `ColourEngineV4` subsystem separately resolves the palette:
`NatalChart` → `ChartInputAdapter` → `ChartSignatureResolver` (determines palette family + cluster) → template colours + chart-derived accents → LCH normalisation → `PaletteSection`.

### 4.3 Natal Chart Calculation

`NatalChartCalculator` (1388 lines) handles:
- Planet positions via VSOP87D data files (Sun, Moon, Mercury–Pluto)
- Asteroid positions via Swiss Ephemeris (Chiron, Lilith, North Node)
- House cusps (Placidus and Whole Sign systems)
- Ascendant and Midheaven
- Progressed charts (secondary progressions with solar arc option)
- Transit calculations (current planet positions vs natal, with aspect detection)
- Aspect calculations (conjunction, opposition, trine, square, sextile + minor aspects)

### 4.4 Authentication & Data Sync

- **Auth flow:** Phone number → OTP via Supabase Edge Function (`send-otp` / `verify-otp`) → session token
- **Guest mode:** Full functionality without auth; `AuthNudgeBannerView` prompts signup
- **Sync:** Authenticated users can backup/restore profile + Style Guide (`CosmicBlueprint` JSON) via `SupabaseSyncService` (JSON blobs to Supabase storage)
- **Deep linking:** `cosmicfit://` URL scheme for auth callbacks via `AuthDeepLinkRouter`

### 4.5 Navigation & UI Architecture

- `AppDelegate` manages the full app lifecycle (no `SceneDelegate` — pre-iOS 13 style)
- Launch flow: `AnimatedLaunchScreenViewController` → (first launch) `AnimatedWelcomeIntroViewController` → `OnboardingFormViewController` → `CosmicFitTabBarController`; (returning user) → `CosmicFitTabBarController` directly
- Tab bar has 2 primary tabs: Daily Fit (or AuthGate when logged out), Style Guide. Natal Chart and Profile are presented as embedded detail views from the menu, not as tab items.
- All UI is programmatic UIKit with `NSLayoutConstraint`-based Auto Layout
- Theme system in `CosmicFitTheme.swift` defines app-wide colours, fonts, gradients
- Custom transitions: `SlideTabTransitionAnimator` (horizontal), `VerticalSlideAnimator` (vertical)
- Daily Fit refreshes on `applicationWillEnterForeground` if the date has changed

---

## 5. Test Suite

**30+ Swift sources** in `Cosmic FitTests/` (test suites plus shared helpers such as **`CalibrationReportHelper`**, **`CalibrationProfiles_Extended`**, **`StyleGuideDataURL`**). All XCTest / Swift Testing.

| Test File | What It Tests | Lines |
|---|---|---|
| `DailyEnergyEngine_VibeProfile_Tests` | Stage 1 vibe profile generation, 21-point budget invariant, energy distribution | 455 |
| `DailyEnergyEngine_Snapshot_Tests` | Full snapshot assembly, axes ranges, transit extraction, lunar context | 447 |
| `DailyFitTypes_Tests` | DailyFitPayload Codable roundtrip, EssenceTriangle→14-category migration, calibration validation | 433 |
| `DailyFitCalibration_Tests` | Source weight normalisation, sign energy map completeness, planet axis map coverage, pipeline integration | 778 |
| `DailyFitUIIntegration_Tests` | End-to-end: snapshot → payload → UI field population, frozen payload storage | 299 |
| `BlueprintLensEngine_Payload_Tests` | Full payload assembly, palette selection, vibrancy/contrast/metalTone derivation, essence/silhouette profiles | 858 |
| `BlueprintLensEngine_TarotStyleEdit_Tests` | Tarot card selection scoring, recency penalty, variant rotation, tiebreaking | 391 |
| `ColourEngineV4_UnitTests` | Colour engine family resolution, template palettes, normalisation, accent placement | 471 |
| `ChartSignatureResolver_Tests` | Chart → palette family/cluster resolution | 194 |
| `Cosmic_FitTests` | Original comprehensive test suite: chart calculation, interpretation, colour engine, Style Guide assembly | 1940 |
| `MariaAshLocked_Tests` | Locked reference outputs for two specific users (regression) | 390 |
| `PaletteGridViewModel_Tests` | Palette grid view model logic, colour conversion, layout | 600 |
| `PaletteRework_Tests` | Palette rework validation, anchor colours, swatch generation | 460 |
| `V4CalibrationDiagnostic_Tests` | Diagnostic report generation, trace completeness | 230 |
| `V4CalibrationOptimizer_Tests` | Calibration weight optimisation | 190 |
| `V4CalibrationRegression_Tests` | Regression tests for V4 calibration outputs | 271 |
| `V4PlacementGenerator_Tests` | Colour placement generation and validation | 180 |
| `V4ReferenceAudit_Tests` | Reference audit against known-good outputs | 569 |
| `VariationSlots_Tests` | Palette variation slot system | 320 |
| `FixtureRegeneration` | Utility to regenerate test fixtures (not a test suite per se) | 181 |
| `VSOP87BundleIntegrity_Tests` | VSOP87D files present in app bundle; J2000 Earth smoke test | — |
| `SemanticTokenGenerator_ZodiacMath_Tests` | 1-based zodiac → element/modality (Phase 0D contract) | — |
| `BlueprintDistribution_Tests` | Style Guide / blueprint distribution histograms (Parts 3B–3E); **may crash** on some paths until `SemanticTokenGenerator` house/token bounds are fixed — see **`docs/calibration_plan_closure_summary.md`** |
| `AstrologicalSoundness_Tests` | Part 6: energy-map behaviour + calibration weight invariants + optional soundness report | — |
| `TarotScoringPathIntegrity_Tests` | Phase 0F: legacy scoring audit + production `generatePayload` smoke | — |

**Test fixtures** live in `docs/fixtures/` — JSON and text files with known-good reference outputs.

**Parallel test runs / flaky clones:** See [`docs/archive/test_handoff.md`](docs/archive/test_handoff.md) for diagnosis, fixes applied, and remaining `UserDefaults`/clone isolation work.

**Calibration / distribution testing:** See **`docs/calibration_plan_closure_summary.md`** for env vars, commands, and known gaps (`CALIBRATION_CI_GATE`, `CALIBRATION_REPORT_DIR`).

**UI Tests:** `Cosmic FitUITests/` contains two boilerplate files from Xcode project template — **not meaningfully implemented**.

---

## 6. Legacy Code, Dead Ends & Cleanup Targets

### 6.1 Confirmed Dead / Legacy Code (safe to remove)

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

### 6.2 Files with Naming Issues

| Issue | File |
|---|---|
| Trailing space in filename | `VibeBreakdown .swift` — should be `VibeBreakdown.swift` |
| `.DS_Store` files checked in | Root, `Cosmic Fit/`, `Cosmic Fit/Resources/` |

### 6.3 Bugs & Risks

| Risk | Details |
|---|---|
| **VSOP87 load failures** | **`VSOP87Parser`** uses a **Keplerian fallback** if VSOP87D files cannot be loaded (no `fatalError` in the VSOP87 parser for missing theory files). **`VSOP87BundleIntegrity_Tests`** preflights bundle resources from **`Bundle.main`**. Separately, **`SwissEphemerisBootstrap`** may still `fatalError` if **`seas_18.se1`** is missing — that is Swiss Ephemeris bootstrap, not VSOP87. |
| ~~**`SemanticTokenGenerator` sign math bug**~~ | **Resolved** for the Style Guide token path: 1-based zodiac element/modality is covered by **`SemanticTokenGenerator_ZodiacMath_Tests`**. If you change zodiac math, run that suite and re-check Part 3 distribution tests. |
| **Duplicate `Package.resolved`** | Two copies exist: one under `.xcodeproj` (swift-crypto 4.4.0) and one under `.xcworkspace` (swift-crypto 4.3.1). Different revisions — Xcode may fight over resolution. |
| **Secrets possibly committed** | `Dev.xcconfig` and `Prod.xcconfig` are gitignored by `.gitignore`, but the checked-in files may contain real Supabase credentials. Verify and rotate if exposed. |
| **"Daily Vibe" naming drift** | `AppDelegate`, `UserProfileStorage`, and several notifications still reference "Daily Vibe" (the old feature name) while the product is "Daily Fit". Confusing for new developers. |

### 6.4 Structural Concerns

| Concern | Details |
|---|---|
| **Placeholder interpretation path** | `CosmicFitInterpretationEngine.generateStyleGuideInterpretation()` returns placeholder text. The Style Guide tab works for real sections (palette, textures, etc.) via `BlueprintStorage` + `CosmicBlueprint`, but the old sentence-assembly interpretation is disconnected. |
| ~~**Duplicate data files**~~ | **Resolved** — single canonical **`data/style_guide/`** tree; tests use `StyleGuideDataURL`; bundle entries are symlinks. |
| **DailyFitViewController is 2140 lines** | God-controller handling layout, data loading, payload rendering, tarot card display, colour palette, essence radar, silhouette bars, vibe breakdown, transit list, lunar phase, texture/pattern display, animations, and scroll management. Should be decomposed. |
| **CosmicFitTabBarController is 1080 lines** | Handles tab setup, Style Guide generation, Daily Fit orchestration, caching, notification handling, debug logging. Too many responsibilities. |
| **Singleton overuse** | `NatalChartManager.shared`, `SavedChartStorage.shared`, `TarotRecencyTracker.shared`, `TarotVariantRotationTracker.shared`, `UserProfileStorage.shared`, `BlueprintStorage.shared`, `CosmicFitAuthService.shared`, `LocationManager` — makes testing and dependency injection difficult. |
| **Mixed data flow patterns** | Some paths use `[String: Any]` dictionaries (legacy `calculateNatalChart` return type) while the modern pipeline uses typed structs. The dictionary-based API should be phased out. |
| **No dependency injection** | `TarotRecencyTracker.shared` / `TarotVariantRotationTracker.shared` are called inside `BlueprintLensEngine` static methods, making those methods harder to test in isolation. |
| **SemanticTokenGenerator serves two masters** | Generates tokens for both the placeholder interpretation path and the `CosmicBlueprint` composition path. `generateStyleGuideTokens` is only consumed by the placeholder `CosmicFitInterpretationEngine`. |
| **Tests write to `docs/`** | Several test suites write fixture files and reports to `docs/fixtures/`. Set **`CALIBRATION_REPORT_DIR`** in CI to a temp directory to avoid parallel job collisions; report filenames include a run disambiguator (see **`CalibrationReportHelper`**). |
| **No UI/E2E test coverage** | UITests are boilerplate. No automated user journey tests (onboarding, Daily Fit, Style Guide, auth flow). |

---

## 7. Strengths

| Strength | Details |
|---|---|
| **Deterministic, testable pipeline** | The Daily Fit pipeline is fully deterministic given a seed, making it highly testable. The `DailyFitCalibration` surface centralises all tunable weights. |
| **Comprehensive test suite** | Broad XCTest coverage from unit tests through snapshot tests to integration tests, plus calibration / distribution harnesses under **`Cosmic FitTests/`**. Locked reference tests (`MariaAshLocked_Tests`) prevent regressions. |
| **Clean type contracts** | `DailyFitTypes.swift` defines well-documented Codable types with backward-compatible decoding (e.g., `EssenceTriangle` → `StyleEssenceProfile` migration). |
| **Sophisticated colour engine** | ColourEngineV4 is a well-structured 20-file subsystem with clear separation of concerns (family resolution, template mapping, normalisation, accent placement, validation). |
| **Diagnostic infrastructure** | `DailyFitDiagnostics` generates complete pipeline traces. `BlueprintLensEngine.logDailyFitDiagnostics()` provides rich console output. `generateSnapshotWithTrace()` and `generatePayloadWithTrace()` expose intermediate values. |
| **Style Guide data model is production-ready** | `BlueprintModels.swift` defines `CosmicBlueprint` with versioned fields (V4, V4.2, V4.3, V4.4), optional backward-compatible decoding, and clear field-source documentation (D/AI/U/M). |
| **Calibration surface** | `DailyFitCalibration` provides a single config surface for all weights, enabling systematic tuning without code changes. |

---

## 8. Key Data Contracts

### VibeBreakdown (21-point budget)
Six integer values (0–10 each) summing to exactly 21:
`classic + playful + romantic + utility + drama + edge = 21`

### DerivedAxes (1–10 scale)
Four continuous values: `action`, `tempo`, `strategy`, `visibility`

### DailyEnergySnapshot (Stage 1 output)
Contains: `vibeProfile`, `axes`, `dominantTransits`, `lunarContext`, `dailySeed`, `profileHash`, `generatedAt`

### DailyFitPayload (Stage 2 output / what the UI renders)
Contains: `tarotCard`, `styleEditVariant`, `dailyPalette`, `vibrancy`, `contrast`, `metalTone`, `essenceProfile`, `silhouetteProfile`, `vibeBreakdown`, `axes`, `dominantTransits`, `lunarContext`, `dailyTextures`, `dailyPattern`, `generatedAt`

### `CosmicBlueprint` — persisted Style Guide (permanent per-user)
Contains: `userInfo`, `styleCore`, `textures`, `palette`, `occasions`, `hardware`, `code`, `accessory`, `pattern`, `generatedAt`, `engineVersion`

---

## 9. Configuration & Secrets

| File | Purpose | Gitignored? |
|---|---|---|
| `Cosmic Fit/Config/Dev.xcconfig` | Supabase URL + API key (dev) | Yes |
| `Cosmic Fit/Config/Prod.xcconfig` | Supabase URL + API key (prod) | Yes |
| `.env` | Python tooling env vars | Yes |
| `Dev.xcconfig.example` | Template for dev config | No (committed) |
| `.env.example` | Template for Python env | No (committed) |

---

## 10. Build & Run

1. Open `Cosmic Fit.xcworkspace` (not the `.xcodeproj`)
2. Copy `Dev.xcconfig.example` → `Dev.xcconfig` and fill in Supabase credentials
3. SPM dependencies resolve automatically on first open
4. Build target: `Cosmic Fit` (iOS Simulator or device)
5. Tests: `Cosmic FitTests` target — run via `Cmd+U`

**Optional — Cosmic Fit Inspector (macOS):** `cd inspector && swift run cosmicfit-inspector`, then open **http://127.0.0.1:7777** (see §2.1 and **`inspector/README.md`**).

**Optional — dataset QA (Python):** `python3 tools/validate_dataset.py` (see §2.1).

**Optional — calibration gates from Terminal:** pass **`CALIBRATION_CI_GATE=1`** and optionally **`CALIBRATION_REPORT_DIR`** when running `xcodebuild test` (see §2.2 and **`docs/calibration_plan_closure_summary.md`**).

---

## 11. Cleanup Checklist for New Developer

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
- [ ] Consolidate two `Package.resolved` files — prefer workspace copy
- [ ] Review `docs/` — keep `docs/fixtures/` (test data), prune planning artefacts
- [ ] Rename "Daily Vibe" → "Daily Fit" in `AppDelegate`, `UserProfileStorage`, notification names
- [ ] Verify `Dev.xcconfig` / `Prod.xcconfig` aren't committed with real secrets; rotate if so

### Phase 5: Architectural improvements (larger effort)

- [ ] Decompose `DailyFitViewController` (2140 lines) into child VCs or coordinator
- [ ] Decompose `CosmicFitTabBarController` (1080 lines) — extract Style Guide / Daily Fit orchestration
- [ ] Introduce dependency injection to replace singleton calls inside engine methods
- [ ] Phase out `[String: Any]` dictionary API from `NatalChartCalculator` in favour of typed `NatalChart` returns

---

## 12. File Inventory Summary

| Layer | Files | Lines |
|---|---|---|
| App | 1 | 269 |
| Core | 16 | 5,609 |
| InterpretationEngine (top-level) | 30 | ~13,600 |
| ColourEngineV4 | 20 | ~3,200 |
| UI | 35 | 13,050 |
| Tests | 33+ Swift files in Cosmic FitTests | (varies) |
| **Total active Swift** | **122** | **~45,385** |

| Resource | Size |
|---|---|
| TarotCards.json | 306 KB (8,306 lines, 78 cards) |
| data/style_guide/astrological_style_dataset.json | ~478 KB |
| data/style_guide/blueprint_narrative_cache.json | ~5.6 MB |
| VSOP87 data files | 4.2 MB total |
| Font files | 1.6 MB total |
