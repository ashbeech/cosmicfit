# DailyFit Output Production Readiness — Handoff

**Date:** 2026-06-10  
**Status:** Strong beta candidate, **not broad-release ready yet**  
**Audience:** AI developer taking the current DailyFit work from "visibly improved" to production-ready  
**Primary report:** [DailyFit 14-Day Output Audit](/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/dailyfit-14d-output-audit.canvas.tsx)

---

## Executive Summary

The latest 14-day output audit shows the recent work is meaningfully visible in real generated outputs:

- Tarot recency prevention is behaving cleanly in the audited exports.
- Essence turnover is materially better; most users see many distinct top-3 essence combinations over 14 days.
- Palettes are changing from day to day and do not feel locked to one static triad.
- Narrative cohesion is generally credible: the card, essence set, and style-edit action usually belong together.
- Daily axes and presentation scales are moving, so the slider-responsiveness work is present in the payloads.

Shipping call: **not objectively ready for broad user release yet**. It is strong enough for a guarded beta / TestFlight cohort, especially if this replaces a weaker current experience, but several gaps should be closed before calling it production-ready.

---

## Evidence From The Audit

Source set:

- Wilder, Aurora, Lior, Pax, Briar, Cedar, Echo, Sable: `2026-05-27` to `2026-06-09`
- Wren: `2026-05-23` to `2026-06-05`
- Total: **9 users x 14 days = 126 DailyFit outputs**

Key metrics from the canvas:

| Area | Finding | Read |
|---|---:|---|
| Tarot recency | No adjacent repeats; shortest observed repeat gap was 10 days | Strong |
| Tarot variety | Average 12.1 unique cards per 14-day export | Strong |
| Essence turnover | Average 11.2 unique top-3 essence sets per 14-day export | Strong |
| Essence breadth | Average 8.1 distinct top-3 categories per user | Strong |
| Daily axes | Average 3.57 points of range on the 0-10 axis scale | Good |
| Palette variation | Average 12.1 distinct palette colour names per user | Good |
| Narrative | Average 7/14 conservative Tarot keyword/theme hits | Mixed but credible |

The report's qualitative examples also support the quantitative read: individual daily outputs generally show card-specific rituals, top essence alignment, and day-to-day shifts in visual language.

---

## Current Ship Readiness

### Recommended Release Posture

**Ship to guarded beta / TestFlight:** yes.

**Ship broadly to users:** not yet.

This is not because the system looks broken. It does not. The issue is confidence and polish: the work is clearly showing through, but the audit sample is too small and there are still visible repetition/perception gaps that could undermine trust over longer usage.

### Why It Is Not Broad-Release Ready Yet

1. **Narrative repetition is still visible after card eligibility resets.**  
   The hard block appears to prevent near-term repeats, but once a card becomes eligible again, repeated archetype titles or rituals can return. This is not incoherent, but it may feel templated to returning users.

2. **Slider perception is uneven.**  
   The underlying daily axes move substantially, and silhouette/metal movement is visible. Vibrancy and contrast still read narrower than the other scale families in the exported summaries. Before production, verify that users can feel those sliders moving in the UI, not just in JSON.

3. **The audit sample is persuasive but not exhaustive.**  
   9 users x 14 days is enough to confirm the work is showing through. It is not enough to prove broad readiness across edge profiles, unusual charts, low-transit periods, long-range usage, or different locations/timezones.

4. **Cohesion scoring was partly heuristic.**  
   The report includes qualitative spot checks and a conservative keyword/theme overlap measure. That is useful, but production readiness should include a more deliberate review of weak/mixed cases and repeated-card returns.

---

## Production-Readiness Work Plan

### P0 — Expand The Audit Cohort

Goal: prove the current behavior holds across a broader and more adversarial sample.

Recommended checks:

- Generate at least **50-100 users x 30-60 days** using the current stage1 path.
- Include diverse chart types: high-fire, high-water, high-earth, high-air, uniform-sign synthetic charts, strong outer-planet dominance, low visibility, high visibility, unknown birth time, and different device locations.
- Track:
  - shortest Tarot repeat gap
  - adjacent Tarot repeats
  - unique cards per 14/30/60 days
  - unique top-3 essence sets
  - distinct #1 essence categories
  - per-slider display-position range
  - palette retention and lead-colour repetition
  - repeated style-edit title/ritual rate

Acceptance:

- Zero adjacent Tarot repeats.
- No repeat inside the intended hard-block window.
- Repeated cards after cooldown should not usually repeat the exact same title + ritual pair.
- No user has obviously static top essences over a 14-day window unless there is a documented chart/transit reason.

Likely relevant files:

- `Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift`
- `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift`
- `Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift`
- `Cosmic Fit/InterpretationEngine/TarotRecencyTracker.swift`
- `tools/narrative_cohesion_harness.py`
- `tools/slider_range_audit.py`

### P0 — Fix Repeated Card Narrative Templates

Goal: if a card returns after the cooldown window, it should not feel like the same day repeating.

Observed issue:

- The report shows no near-term Tarot repeat problem.
- However, repeated cards can carry recognizable title/ritual patterns when they return after 10-11 days.

Recommended implementation direction:

- Add recency-aware variant selection for `styleEditVariant`, not just card selection.
- Track recently used card-title/ritual variants separately from card identity.
- When a card repeats after cooldown, prefer a different variant if available.
- If no alternate exists, vary the ritual/reflection copy using the day's essence/axis emphasis.

Acceptance:

- For any repeated card within a 30-day export, exact title + ritual duplication should be rare or zero.
- Repeated cards should visibly adapt to that day's top essence set and axes.

Likely relevant files:

- `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift`
- `Cosmic Fit/InterpretationEngine/NarrativeTarotBridgeSelector.swift`
- `Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift`
- `Cosmic Fit/InterpretationEngine/TarotRecencyTracker.swift`

### P1 — Verify Slider Perception In The UI

Goal: confirm the slider work is user-visible, not only payload-visible.

Observed issue:

- Daily axes are moving well.
- UI-facing scale movement is present but uneven; vibrancy/contrast are still narrower than silhouette/metal in the audited outputs.

Recommended checks:

- Inspect `scalePresentation` / display positions for all six sliders across a larger cohort.
- Compare raw axis movement against actual UI marker movement.
- Specifically validate vibrancy and contrast in low-variation windows.
- Confirm the app UI uses display positions consistently and does not fall back to raw values unexpectedly.

Acceptance:

- No slider appears stuck across a normal 14-day user journey.
- Vibrancy and contrast should show perceptible travel in real UI screenshots/exports.
- Any intentionally low-motion slider should have a product rationale.

Likely relevant files:

- `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift`
- `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift`
- `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift`
- UI code that renders DailyFit slider positions, especially `refreshDiamondScalePositions` if present in the current branch.

### P1 — Strengthen Narrative Cohesion Review

Goal: move from "credible" to "production-confidence" cohesion.

Recommended checks:

- Sample weak/mixed days from the larger audit and manually classify:
  - card/title alignment
  - card/ritual alignment
  - essence/title alignment
  - palette/essence alignment
  - daily reflection specificity
- Add a report field for repeated title/ritual pairs.
- Add a report field for "same card, different day, same narrative" cases.

Acceptance:

- Weak cases should be explainable and not contradictory.
- Same-card returns should read as a new interpretation, not a duplicate.
- No visible contradiction between top essences and narrative instruction.

Likely relevant files:

- `Cosmic Fit/InterpretationEngine/DailyNarrativeCoherence.swift`
- `Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift`
- `Cosmic Fit/InterpretationEngine/NarrativeSelectionDirectives.swift`
- `Cosmic FitTests/NarrativeCohesionReport_Tests.swift`

---

## Suggested Test / Report Targets

Before broad release, aim for:

| Gate | Target |
|---|---|
| Tarot hard-block violations | 0 |
| Adjacent Tarot repeats | 0 |
| Avg unique cards per 14 days | >= 11 |
| Avg unique top-3 essence sets per 14 days | >= 10 |
| Repeated exact title + ritual for same card | 0 or explicitly justified |
| Users with visually stuck sliders over 14 days | 0 for real profiles |
| Palette next-day retention | not always 0, not always high; target depends on user anchor |
| Manual cohesion review | no contradiction-class failures |

---

## Important Context For The Next Dev

- The current working tree is already dirty and contains broad narrative, colour, slider, and fixture work. Do **not** revert unrelated changes.
- This handoff is a readiness/polish pass, not a request to rewrite the narrative system.
- The canvas report is the starting point for the evidence, not the final gate.
- Preserve the good parts: Tarot hard-block behavior, essence turnover, and current cohesion should not regress while addressing repetition and UI-perception gaps.

---

## Suggested Completion Criteria

The next dev can call this production-ready when:

1. A larger cohort report confirms the 14-day audit findings hold across broader profiles.
2. Repeated cards after cooldown no longer feel like repeated days.
3. UI-facing sliders show perceptible movement for real users, especially vibrancy and contrast.
4. Narrative cohesion weak cases have been reviewed and either fixed or documented.
5. Focused tests/reports are updated and passing.

