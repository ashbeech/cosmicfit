# Daily Fit — Stage 1 Experimental: Inspector → App Readiness Handoff

**Status:** Active checklist (use at go-time for on-device Stage 1 testing)  
**Date:** 2026-05-23  
**Audience:** Engineer or AI agent validating Stage 1 before Ash tests `stage1_experimental` on device  
**Scope:** Enable and verify **`stage1_experimental`** in the iOS app. **Out of scope:** merging Stage 1 into `production` or shipping Release with a non-production preset.

**Related docs:**

| Doc | Role |
|-----|------|
| [`daily_fit_sky_forward_handoff.md`](./daily_fit_sky_forward_handoff.md) | Sky-forward product intent + engine design |
| [`daily_fit_sky_forward_v2_implementation_spec.md`](./daily_fit_sky_forward_v2_implementation_spec.md) | Stage 1 v2 algorithm spec + Briar 14-day targets |
| [`daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](./daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md) | Stage-1 selection cohesion (no new user copy) |
| [`daily_fit_engine_selector_spec.md`](./daily_fit_engine_selector_spec.md) | Engine registry, frozen payloads, Release lock |
| [`inspector_derivation_drilldown_handoff.md`](./inspector_derivation_drilldown_handoff.md) | Inspector drill-down / attribution (QA-only) |
| [`daily_fit_personal_scale_sliders_handoff.md`](./daily_fit_personal_scale_sliders_handoff.md) | User-relative Vibrancy / Contrast / Metal Tone slider spec |
| [`docs/fixtures/narrative_unification_signoff_2026-05-23.md`](../fixtures/narrative_unification_signoff_2026-05-23.md) | Latest Briar narrative closure record |

---

## 1. Executive summary

Stage 1 Experimental (`dailyFitEngineId: stage1_experimental`, `DailyFitEngineMode.stage1Experimental`) is the **sky-forward daily read**: chart anchor vs today's outside energy. The inspector is the primary validation surface; the app must show the **same payload** when the same engine id, profile, date, blueprint, and tarot history state are used.

### 1.1 Three-layer model (read this first)

| Layer | Shared? | What it is |
|-------|---------|------------|
| **Engine math** | Yes — symlinked | `Cosmic Fit/InterpretationEngine/` compiled by both app and inspector |
| **Payload assembly** | Yes | `DailyFitPipeline.generate` / `generateWithTrace` — **sole** entry point for app, inspector diagnostics, and tests |
| **Observability UI** | Inspector-only | Drill-down drawer, compare carousel, verdicts, trace markdown — **not required in app** |
| **Product UI** | App-only gap | How existing widgets **present** anchor vs weather (essence ghost triangle, future silhouette ticks) |

**Golden rule:** If inspector and app disagree on palette / tarot / essence / scales for the same inputs, fix **engine or pipeline wiring** — do not “fix” the inspector renderer alone.

### 1.2 What “App has everything Inspector has” means

| Must match (payload) | Inspector-only (OK to skip in app) |
|----------------------|-------------------------------------|
| Palette, tarot, essence scores, scales, textures, pattern | Stage 1 attribution accordions (`stage1Attribution`, `stage1AxisAttribution`) |
| `chartAnchorScores`, `chartAnchorMF/AR/SD` on payload | Derivation drill-down steps per swatch/bar |
| Narrative **selection bias** (relationship-driven tarot/palette/scales) | `NarrativeCoherenceTrace` / verdict rows |
| `dailyFitEngineId` + fingerprint on payload | Multi-day compare, engine A vs B, markdown export |
| Essence ghost triangle when stage-1 | Trace tab markdown export |

**Forbidden in app (per narrative unification):** generated “Daily Brief” paragraphs, theme headings, or new instruction copy. Cohesion comes from **existing UI selections**, not new strings.

---

## 2. Architecture reference

```
Cosmic Fit/InterpretationEngine/     ← symlinked into inspector
  DailyEnergyEngine.swift            Stage 1 sky/chart split, sky-only axes
  BlueprintLensEngine.swift          Stage 1 essence, silhouette, palette, scales
  DailyFitPipeline.swift             Sole payload assembly (app + inspector + tests)
  NarrativeIntentEngine.swift        Stage-1 selection bias only
  DailyFitEngineRegistry.swift       stage1_experimental preset + calibration
  DailyFitDiagnostics.swift          Full trace for inspector API

inspector/
  InspectorEngine.swift              resolve() → DailyFitDiagnostics.generateReport
  Web/app.js                         Compare, drill-down, trace export

Cosmic Fit/UI/
  CosmicFitTabBarController.swift    DailyFitPipeline.generate + engine id
  DailyFitViewController.swift       Renders payload (essence ghost when stage-1)
  EssenceTriangleView.swift          Weather triangle + optional anchor ghost
```

**Run inspector after engine edits:**

```bash
cd inspector && ./run-inspector.sh
```

Confirm header **Built:** timestamp updates. Do **not** use bare `swift run` after symlinked source changes.

---

## 3. Phase 1 — Inspector completeness checklist

Complete **before** claiming app readiness. All boxes should be checked (or explicitly deferred with Ash sign-off).

### 3.1 Engine registry & preset

- [ ] `DailyFitEngineRegistry.stage1ExperimentalId` == `"stage1_experimental"`
- [ ] Descriptor has `mode: .stage1Experimental`, distinct fingerprint from `production`
- [ ] Calibration includes sky-forward weights, `.pureSkyScoring`, `SignMultiplierPolicy.stage1OptionA` (daily sky OFF sign mult; chart anchor ON)
- [ ] `DailyFitEngineRegistryInspectorTests` pass (`cd inspector && swift test --filter DailyFitEngineRegistryInspectorTests`)

### 3.2 Stage 1 sky-forward engine (shared Swift)

Verify mode gates in **`DailyEnergyEngine.swift`**:

- [ ] `chartVibeProfile` + `skyVibeProfile` computed separately
- [ ] Stage 1 `vibeProfile` = sky vibe (not delta-amplified blend)
- [ ] Stage 1 axes from sky-only sources (`stage1SkySourceWeights`)
- [ ] `generateSnapshotWithTrace` attributes sky path when `stage1Experimental`

Verify mode gates in **`BlueprintLensEngine.swift`**:

- [ ] Essence uses sky−chart delta path; populates `chartAnchorScores`
- [ ] Silhouette sky-centred for stage-1; stores `chartAnchorMF/AR/SD` on payload
- [ ] Palette uses `.pureSkyScoring` (no core-anchor guarantee)
- [ ] Vibrancy / contrast / metal read sky vibe where spec requires
- [ ] Pattern near-top seed rotation gated on stage-1 only

App regression gates (must stay green):

- [ ] `ProductionFingerprintGuard_Tests` — production fingerprint unchanged
- [ ] `BlueprintLensEngine_Payload_Tests` production / legacy paths unchanged
- [ ] `DailyFitSkyForwardV2_Tests` + Briar golden tests pass

### 3.3 Narrative unification (Stage-1 selection cohesion)

Per [`daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md`](./daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md):

- [ ] `DailyFitPipeline.generateWithTrace` resolves `NarrativeIntentEngine` **before** tarot/palette/scales
- [ ] No user-facing generated copy in payload (`narrativeBrief` not shown anywhere)
- [ ] `NarrativePaletteUnification_Tests`, `NarrativeCoherence_Briar_Tests`, `NarrativeIntentEngine_Tests` pass
- [ ] Briar 2026-05-23: relationship **reinforce**, `overallPass` — see [`narrative_unification_signoff_2026-05-23.md`](../fixtures/narrative_unification_signoff_2026-05-23.md)

### 3.4 Inspector diagnostics API

- [ ] `POST /api/inspect` returns `dailyFit.payload` + `dailyFit.diagnostics`
- [ ] Diagnostics include `stage1Attribution`, `stage1AxisAttribution` for stage-1 runs
- [ ] Diagnostics include `narrativeTrace`, `narrativeIntentTrace`, `narrativeCoherenceTrace` (trace QA)
- [ ] Response meta includes `dailyFitEngineId` + fingerprint
- [ ] Engine change sends `resetTarotHistory: true` (inspector Web UI)

### 3.5 Inspector Web UI (QA surfaces — not app ports)

- [ ] Header engine dropdown lists `Stage 1 Experimental (Sky Forward)`
- [ ] Daily Fit pane: essence **Today | Chart anchor** columns when `chartAnchorScores` present
- [ ] Trace tab / trace markdown export: narrative relationship + coherence (no Daily Brief in dailyfit export)
- [ ] Stage 1 attribution accordions populated for stage-1 engine
- [ ] Compare days + compare engines work; cache keyed by `dailyFitEngineId:dateISO`
- [ ] Drill-down drawer resolves correct date + engine context in compare mode

### 3.6 Manual inspector sign-off (Ash)

Run Briar (or target profile) **14-day compare** with `stage1_experimental`. Targets from [`daily_fit_sky_forward_v2_implementation_spec.md`](./daily_fit_sky_forward_v2_implementation_spec.md) §13.4:

| Surface | Target (smoke) |
|---------|----------------|
| Axes | Vary; not all 10 |
| Silhouette | All three sliders move across window |
| Contrast / vibrancy / metal | Not identical every day |
| Essence top-3 | ≥5 unique orderings / 14 days |
| Palette | ≥6 distinct 3-colour combos; no colour >7/14 |
| Textures / pattern | Some variation |

- [ ] Ash signed off 14-day inspector compare (date + initials below)

**Ash inspector sign-off:** _________________ Date: _______

Optional pending (do not block app Stage-1 test unless Ash says otherwise):

- [ ] Wren contrast window manual trace sign-off (§7.4 narrative handoff)
- [ ] Linden stretch window manual trace sign-off

---

## 4. Phase 2 — App parity with Inspector

Goal: **same `DailyFitPayload`** and **equivalent product presentation** for stage-1, using existing UI — no new prose blocks.

### 4.1 Pipeline wiring (payload parity — critical)

- [ ] `CosmicFitTabBarController.generateAndCacheDailyVibe` calls **`DailyFitPipeline.generate`** (not raw `BlueprintLensEngine.generatePayload`)
- [ ] Passes `DailyFitEngineConfig.effectiveCalibration` and `DailyFitEngineConfig.effectiveEngineId`
- [ ] `DailyEnergyEngine.generateSnapshot` receives same `calibration` + `dailyFitEngineId`
- [ ] Frozen payload save/load preserves `dailyFitEngineId`; stale engine artifacts purged on load (`DailyFitFrozenPayloadStorage`)
- [ ] Reveal flag keys namespaced by engine id (`DailyFitRevealPersistence`)

**Parity spot-check (mandatory):**

1. Pick preset profile + UTC date (e.g. Briar 2026-05-23).
2. Inspector: `stage1_experimental`, `resetTarotHistory: true`, export payload JSON or compare pane values.
3. App DEBUG: Profile engine picker → Stage 1 Experimental; clear today's freeze (DEV force refresh or delete reveal + frozen file).
4. Compare: `dailyFitEngineId`, palette hexes, tarot card, essence top-3, vibrancy/contrast/metal, silhouette MF/AR/SD.

- [ ] Payload fields match inspector for spot-check date(s)

### 4.2 Tarot recency parity

Inspector resets tarot history on engine switch; **app does not automatically**.

When switching engine in Profile picker or after build-time engine change:

- [ ] Document/test whether tarot matches inspector after manual clear:
  ```swift
  TarotRecencyTracker.shared.clearProfile(
      profileHash: profileHash,
      dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
  )
  ```
- [ ] **Recommended app fix (if parity fails):** call `clearProfile` for old + new engine ids in `handleDailyFitEngineOverrideChanged` (DEBUG only)

### 4.3 App UI — what must reflect Inspector semantics

| Surface | Inspector shows | App status | Required for Stage-1 app test |
|---------|-----------------|------------|-------------------------------|
| Essence | Today + anchor columns | Ghost anchor triangle via `EssencePresentationDirective` | [ ] Verify on device — solid weather triangle + dashed ghost |
| Silhouette | Chart anchor reference in drill-down | Today slider only; `chartAnchorMF/AR/SD` on payload unused | [ ] **Optional v1** — dual tick on sliders (see §4.4). Not blocking payload test |
| Palette / tarot / scales | Full values in pane | Same payload drives existing widgets | [ ] Visual sanity on 2+ consecutive days |
| Sky vibe bars | Six-energy section in inspector | Not a separate app widget (vibe shapes essence/scales) | [ ] N/A — no app port required |
| Generated narrative | Trace export only | Must remain absent | [ ] Confirm no Daily Brief labels in app |

**Essence triangle acceptance (Option A — implemented):**

- [ ] `DailyFitViewController` passes `EssencePresentationDirective(showAnchorGhost: true)` when `dailyFitEngineId == stage1_experimental` and `chartAnchorScores != nil`
- [ ] `EssenceTriangleView`: weather = solid triangle + stars; anchor = dashed ghost + muted labels
- [ ] Production engine: single-triangle behaviour unchanged (screenshot or UI test)

### 4.4 Known app UI gaps (document, do not confuse with engine bugs)

These are **presentation** gaps only — payload already contains anchor fields:

| Gap | Payload field | Follow-up doc |
|-----|---------------|---------------|
| Silhouette baseline tick | `silhouetteProfile.chartAnchorMF/AR/SD` | [`daily_fit_sky_forward_handoff.md`](./daily_fit_sky_forward_handoff.md) §9.1 |
| Explicit “adapt today” copy | — | **Do not add** generated copy; use selection cohesion only |
| Separate sky vibe widget | `snapshot.skyVibeProfile` (internal to pipeline) | Inspector-only display |

Defer silhouette dual-tick UI unless Ash requests before device test.

### 4.5 DEBUG engine infrastructure

- [ ] Profile → **Daily Fit engine (debug)** picker lists all registry descriptors including Stage 1
- [ ] Changing picker posts `.dailyFitEngineOverrideChanged`; tab bar regenerates today
- [ ] Non-production engine shows debug subtitle on Daily Fit tab
- [ ] `DailyFitEngineConfig_Tests` pass (override + validation)

### 4.6 Tests (app-side gates)

- [ ] `DailyFitEngineRegistry_Tests` — stage-1 descriptor, diff vs production, sign multiplier policy
- [ ] `DailyFitEngineConfig_Tests` — runtime override to `stage1_experimental`
- [ ] `DailyFitUIIntegration_Tests` — payload → UI field population
- [ ] `NarrativeCoherence_Briar_Tests` + palette/tarot unification suites green
- [ ] Full `Cosmic FitTests` green locally (note documented exceptions in narrative signoff)

---

## 5. Phase 3 — Enable Stage 1 Experimental in the app (test build only)

**Goal:** Ash runs **`stage1_experimental` on device/simulator** while **Release stays on `production`**.

### 5.1 Release safety (non-negotiable)

- [ ] `DailyFitEngineConfig.effectiveEngineId` in **Release** always returns `DailyFitEngineRegistry.productionId` ( `#else` branch )
- [ ] Do **not** set `DAILY_FIT_ENGINE_ID=stage1_experimental` in **Prod.xcconfig** for App Store builds
- [ ] Confirm App Store / TestFlight archive uses Release configuration

### 5.2 Option A — DEBUG Profile picker (fastest, no rebuild)

1. Build **Debug** to device/simulator.
2. Profile → Daily Fit engine (debug) → **Stage 1 Experimental (Sky Forward)**.
3. Trigger regeneration (picker auto-regenerates today via notification).

- [ ] Verified on Debug build

**After switching to stage-1:**

- [ ] Run DEV **Force refresh** once if palette/tarot looks stale vs inspector
- [ ] Clear tarot recency for stage-1 engine id if tarot differs from inspector (§4.2)

### 5.3 Option B — Build-time preset (Debug xcconfig)

For a Debug build that defaults to stage-1 without picker:

1. Set in `.env`: `DAILY_FIT_ENGINE_ID=stage1_experimental`
2. Sync to xcconfig: `./tools/sync_env_to_xcconfig.sh` (or manually set in `Dev.xcconfig`)
3. Rebuild Debug — `Info.plist` key `DAILY_FIT_ENGINE_ID` injected at build time

- [ ] `DailyFitEngineConfig.buildTimeEngineId` resolves to `stage1_experimental` in Debug
- [ ] Profile picker “reset to build default” clears override correctly

### 5.4 Frozen payload migration (one-time on upgrade)

When stage-1 fingerprint or narrative selection tunables change, old freezes may show stale output.

- [ ] On first launch after engine bump, purge stage-1 freezes if needed:
  ```swift
  DailyFitFrozenPayloadStorage.shared.purgeEngineId(
      DailyFitEngineRegistry.stage1ExperimentalId
  )
  ```
  (Or use Profile DEV force refresh — wipes all freezes.)

- [ ] Document in PR if fingerprint bumped again

### 5.5 On-device validation script (Ash)

Minimum manual test before promoting later to production:

1. [ ] **Today card** loads under stage-1 without crash
2. [ ] Essence shows weather + ghost anchor (not production single-triangle)
3. [ ] Compare **today vs tomorrow** — at least one of: palette, tarot, essence order, or scales differs
4. [ ] Compare **same date** inspector vs app — payload parity (§4.1)
5. [ ] Reveal + kill app + relaunch — frozen payload stable and still stage-1
6. [ ] Switch back to **production** in picker — card matches pre-stage-1 production behaviour

**Ash device sign-off:** _________________ Date: _______

---

## 6. Phase 4 — Explicitly out of scope (production promotion)

Do **not** perform these steps as part of “test stage-1 in app first”:

- [ ] ~~Merge Stage 1 algorithm into `DailyFitCalibration.default`~~
- [ ] ~~Set `production` registry row to `mode: .stage1Experimental`~~
- [ ] ~~Ship Release with non-production `DAILY_FIT_ENGINE_ID`~~
- [ ] ~~Remove DEBUG engine picker without replacement product decision~~

When ready later, use promotion checklist in [`daily_fit_sky_forward_handoff.md`](./daily_fit_sky_forward_handoff.md) §9.6 and update [`daily_fit_engine_selector_spec.md`](./daily_fit_engine_selector_spec.md) §5.4.

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| App matches production while picker says stage-1 | Stale frozen payload or reveal flag | Force refresh; purge engine freezes |
| App differs from inspector on tarot only | Tarot recency not reset on engine switch | `clearProfile` for both engine ids |
| Inspector updated, app numbers old | Inspector not rebuilt | `./run-inspector.sh`; check Built stamp |
| Essence looks like Style Guide repeat | Viewing production engine or old freeze | Confirm `payload.dailyFitEngineId` |
| Ghost triangle missing | `chartAnchorScores` nil or production mode | Inspect payload; confirm stage-1 pipeline |
| “Daily Brief” text in app | Narrative v1 regression | Remove — see narrative unification Phase A |

---

## 8. Commands quick reference

```bash
# Inspector unit tests
cd inspector && swift test --filter DailyFitEngineRegistryInspectorTests

# App Stage-1 / narrative gates
xcodebuild test -scheme "Cosmic Fit" \
  -only-testing:"Cosmic FitTests/DailyFitEngineRegistry_Tests" \
  -only-testing:"Cosmic FitTests/DailyFitSkyForwardV2_Tests" \
  -only-testing:"Cosmic FitTests/NarrativeCoherence_Briar_Tests" \
  -only-testing:"Cosmic FitTests/NarrativePaletteUnification_Tests"

# Sign-energy harness (inspector must be running)
python3 tools/sign_energy_inspector_harness.py
```

---

## 9. File map (edit only when checklist item fails)

| Concern | Primary files |
|---------|---------------|
| Stage-1 engine math | `DailyEnergyEngine.swift`, `BlueprintLensEngine.swift`, `DailyFitEngineRegistry.swift` |
| Payload assembly | `DailyFitPipeline.swift` |
| Narrative selection bias | `NarrativeIntentEngine.swift`, `DailyFitTypes.swift` (calibration tunables) |
| App generation | `CosmicFitTabBarController.swift` |
| App presentation | `DailyFitViewController.swift`, `EssenceTriangleView.swift` |
| Engine config | `DailyFitEngineConfig.swift`, `Dev.xcconfig`, `.env.example` |
| Frozen storage | `DailyFitFrozenPayloadStorage.swift`, `DailyFitRevealPersistence.swift` |
| Inspector glue | `InspectorEngine.swift`, `inspector/.../Web/app.js` |
| Diagnostics / trace | `DailyFitDiagnostics.swift` |

---

## 10. PR / AI agent sign-off template

Copy into PR description when closing this checklist:

```markdown
## Stage 1 Experimental — App readiness

### Phase 1 Inspector
- [ ] Registry + engine tests green
- [ ] Narrative Briar gate green
- [ ] Inspector manual sign-off (or deferred: ___)

### Phase 2 App parity
- [ ] DailyFitPipeline wired in tab bar
- [ ] Payload spot-check matches inspector (profile/date: ___)
- [ ] Essence ghost triangle verified
- [ ] Tarot recency parity addressed (clear on switch / manual doc)

### Phase 3 Device test enablement
- [ ] Debug stage-1 via picker and/or Dev.xcconfig
- [ ] Release still locked to production
- [ ] Frozen payload purge documented if fingerprint bumped
- [ ] Ash device sign-off (or pending)

### Out of scope
- [ ] Production promotion NOT included in this PR
```

---

*End of handoff.*
