# TASK — Surface named lunar events (Supermoon / Eclipse) into the narrative + accent

> **Status: ✅ COMPLETE (2026-07-16).** Implemented on `SFv102` per the approach below. Kept as the
> completion record; the original kickoff follows unchanged.
>
> **What was built:**
> - `NamedLunarEventSummary` (`label` + 0–1 `strength`) and `LunarContext.namedEvent`
>   (`DailyFitTypes.swift`) — attached only for `isSpecialEvent` days on the `usesSkyFidelityVibe`
>   path, flows snapshot → payload for the UI; nil is omitted from JSON, so v1.0.1 output and
>   legacy frozen payloads are byte-identical (covered by a decode/encode test).
> - `DailyEnergyEngine`: the event is detected once per snapshot (both build sites), drives the
>   D2 phase-label override as before, and on special-event days
>   `injectNamedEventDriver(into:event:)` prepends a Moon-led salience driver (aspect = event
>   label, salience 1.0, essence `.playful`) — so the accent ranking (cooldown-exempt sky-top
>   category), the essence transit boost, intensity/tempo, and the plan's
>   `salienceDrivers`/`skyJustification` all reference the event with zero per-consumer wiring.
> - **No lunar-significance boost** was applied: changing the vibe accumulation would alter
>   fingerprinted-calibration output on non-event surfaces (version bump + cohort re-run). The
>   surfacing is fingerprint-neutral, exactly as scoped below.
> - Test: `Cosmic FitTests/DailyFitNamedLunarEvent_Tests.swift` — all 7 almanac special-event
>   days assert snapshot/payload label, event-led salience, plan justification + high/peak
>   intensity; ordinary day + plain-full-moon negatives; v1.0.1 rollback preset untouched;
>   determinism; legacy-JSON compatibility.
> - **Fixture-drift note:** the committed Rung 4 cohort fixtures predate this feature; the
>   2026-05-31 micromoon falls inside the slider window (Apr 23 + 60d), so regenerated fixtures
>   will differ on that day by design. Gates use pinned floors, not byte-compares.

---

> **Original kickoff (self-contained, for reference):**
> **Scope:** one focused feature + its test. Not a refactor.

## What this is

Sky Forward v1.0.2 added a **`LunarEventDetector`** ([`Cosmic Fit/InterpretationEngine/LunarEventDetector.swift`](../../Cosmic%20Fit/InterpretationEngine/LunarEventDetector.swift))
that identifies first-class named lunar events for a date — **`.solarEclipse` / `.lunarEclipse` /
`.supermoon` / `.micromoon` / `.fullMoon` / `.newMoon`**, each with a 0–1 `strength`. It exposes the hooks
you need: `eventLabel` ("Supermoon", "Lunar Eclipse", …), `isSpecialEvent` (true for eclipse/super/micro),
and `strength`.

**What already ships (do not redo):** the **D2 phase-label override** — near a syzygy the detector's result
overrides the 6°-bucket phase name so a true full moon always reads "Full Moon". This is done and gate-covered.

**What this task adds:** route the **named event** (the *rarer* Supermoon / Solar Eclipse / Lunar Eclipse days,
i.e. `isSpecialEvent`) into the **narrative + accent surface**, so the device build actually *tells the user*
"today is a supermoon / an eclipse" — richer than just the corrected phase label. Optionally apply a small
lunar-weight significance boost while a special event is active.

## The exact wiring (already traced for you)

1. **The event is already detected but discarded** — [`DailyEnergyEngine.swift:1572–1573`](../../Cosmic%20Fit/InterpretationEngine/DailyEnergyEngine.swift#L1572),
   inside `buildLunarContext(...)`, guarded by `applyEventLabelOverride` (true only for `usesSkyFidelityVibe`,
   i.e. the v1.0.2 path). Today only `event.phaseLabel` is used; `event.eventLabel` / `isSpecialEvent` /
   `strength` are dropped on the floor. **This is where you capture it.**
2. **The snapshot's salience path** (what drives the accent) is `SkySalienceProfile` — built at
   [`DailyEnergyEngine.swift:~1472–1532`](../../Cosmic%20Fit/InterpretationEngine/DailyEnergyEngine.swift#L1472)
   (`topDrivers`, each with an `essenceCategory`), attached to the snapshot (`skySalience:` at lines 149 / 1026).
3. **The accent consumer** reads `snapshot.skySalience?.topDrivers` at
   [`BlueprintLensEngine.swift:1898`](../../Cosmic%20Fit/InterpretationEngine/BlueprintLensEngine.swift#L1898);
   narrative selection is `DailyNarrativeSelector.select(...)`.

## Suggested approach (implementer's discretion)

- Add an optional `lunarEvent: LunarEvent?` (or just `namedEventLabel: String?` + `isSpecialEvent: Bool`) to the
  **snapshot** (or `DailyFitPayload`), populated from the detector in `buildLunarContext` — **only on the
  `usesSkyFidelityVibe` path** (keep v1.0.1 untouched).
- On `isSpecialEvent` days, surface `eventLabel` in the narrative/accent (e.g. inject a named-event salience
  driver so the accent essence / narrative can reference "Supermoon"/"Eclipse"), and — optionally — apply a
  modest lunar-significance boost scaled by `strength` while active.
- Keep the phase-label override exactly as-is.

## Acceptance criteria

- A new test (Swift Testing, app target) that feeds a **known 2026 special-event date** from the pinned almanac
  [`docs/fixtures/lunar_events_2026.json`](../fixtures/lunar_events_2026.json) — e.g. supermoon **2026-01-03 /
  2026-11-24 / 2026-12-24**, lunar eclipse **2026-03-03 / 2026-08-28**, solar eclipse **2026-02-17 / 2026-08-12** —
  through the v1.0.2 engine and asserts the named event reaches the narrative/accent surface (label present /
  accent influenced), and that an **ordinary day does not** get a named-event surfacing.
- Determinism preserved (pure function of chart + date; no wall-clock / RNG outside the seeded jitter).

## Constraints (non-negotiable — same as the v1.0.2 release)

- **Never mutate the v1.0.1 path.** Gate all new behaviour on `effectiveMode.usesSkyFidelityVibe`
  (the v1.0.2 vibe). `stage1ExperimentalCalibration` / the `.stage1Experimental` branch stay byte-identical.
- **New engine output changes the fingerprint** → if you alter the *calibration*, it's a version bump and a
  cohort-ladder re-run; prefer surfacing the already-detected event **without** changing the fingerprinted
  calibration (a snapshot/payload field + narrative wiring is fingerprint-neutral).
- Determinism is sacred; the detector is already a pure function of the date.

## Reference

- Detector + hooks: `LunarEventDetector.swift` (`eventLabel`, `isSpecialEvent`, `strength`, `isFullMoonFamily`).
- Almanac fixture (test dates): `docs/fixtures/lunar_events_2026.json`.
- Detector cross-check test (pattern to mirror): `inspector/Tests/InspectorEngineTests/LunarEventDetector_Tests.swift`.
- The v1.0.2 release context (background only): `docs/handoff/sky_forward_v1_0_2_status.md`, plan `sky_forward_v1_0_2_plan.md` §Phase 5.
