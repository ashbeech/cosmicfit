# Palette Calibration Programme Spec v1.1

## Primary Goal

Improve Blueprint palette calibration so generated palettes read as a coherent family across users, not merely as a collection of individually plausible chart colours.

This programme is specifically about closing the gap between:

- what the current engine selects
- what a human reviewer expects from the user's overall palette identity

## Problem Statement

The current resolver in `Cosmic Fit/InterpretationEngine/DeterministicResolver.swift` optimizes well for:

- chart grounding
- dataset primary/accent preservation
- hue diversity
- minimum anchor counts

It does **not** explicitly optimize for:

- warm vs cool coherence
- deep vs light coherence
- muted vs bright coherence
- staying within one recognisable seasonal family when the user clearly reads as one

Maria is the exemplar failure mode:

- several selected anchors are individually plausible
- the total palette drifts out of Deep Autumn coherence
- the later accents increase hue variety while weakening family resemblance

## Key Finding

The common failure mode is **family drift**, not total astrological failure.

In practice this means:

- core band may be broadly correct
- accent band introduces cool, airy, pastel, or metallic colours
- the final result loses temperature/depth integrity

This suggests calibration work should happen in the **dataset** and the **resolver**, not the UI.

## Non-Goals

- no UI redesign
- no `ColourPaletteView` changes
- no narrative cache regeneration as part of the first pass
- no per-user ad hoc overrides
- no hard-coding seasonal outputs directly from one benchmark user

## Deliverables

At the end of this programme:

1. the repo contains benchmark fixtures under `docs/palette_calibration/benchmarks/`
2. the repo contains a repeatable review script: `review_palette_calibration.py`
3. the dataset supports higher-level palette calibration metadata
4. the resolver prefers coherent family fit in addition to chart grounding
5. Maria and at least several contrast users improve without regressions

## Phase 1 - Benchmark Baseline

### Goal

Create a labeled benchmark set before changing engine logic.

### Required work

- keep `docs/palette_calibration/benchmarks/maria_deep_autumn.json`
- keep `docs/palette_calibration/benchmarks/ash_deep_autumn_winter_edge.json`
- add 12 to 20 benchmark users over time
- ensure the set spans:
  - warm / cool
  - deep / light
  - muted / bright
  - earthy / airy

### Success criteria

- benchmark files are human-readable
- each benchmark records:
  - birth data
  - expected family
  - preferred anchors
  - forbidden anchors
  - reviewer prompts

### Benchmark improvement rule

The benchmark harness itself should improve as the programme advances.

Do not treat the first benchmark files as final. They are the minimum viable
label set, not the full evaluation framework.

Each benchmark should become more useful over time by adding:

- a clearer target-family summary
- explicit drift patterns already observed in production
- tighter preferred / forbidden anchor lists
- looser or tighter thresholds where human review shows the current target is
  unrealistic or too forgiving

### Current benchmark-derived drift patterns

The first two labeled users already surface two reusable failure modes:

- **Maria**: warm/deep base with cool-airy accent leakage
- **Ash**: deep grounded target with cool/light core intrusion

These should be treated as named regression classes and referred to in future
PR notes when they recur.

### Benchmark scoring philosophy

The benchmark is intended to answer three different questions:

1. **Anchor fit** — did the engine choose enough on-family colours?
2. **Anchor exclusion** — did the engine avoid obviously off-family colours?
3. **Family coherence** — does the final set still read as one person?

The current script covers the first two mechanically and leaves the third to
human review. That is intentional for v1.1.

Future versions may add heuristic family-coherence scoring, but human review
remains the source of truth.

## Phase 2 - Dataset Enrichment

### Goal

Teach the engine what kind of colour family a chart contribution implies, not just which named colours it can emit.

### Recommended change

Extend dataset colour entries so each colour can optionally carry metadata like:

```json
{
  "name": "deep sage green",
  "hex": "#4A6741",
  "temperature": "warm",
  "depth": "deep",
  "chroma": "muted",
  "families": ["deep_autumn", "soft_autumn"]
}
```

### Notes

- keep decode backwards-compatible where possible
- avoid duplicating this metadata in several places
- prefer attaching the metadata near colour definitions / colour library

### Reason

Without family metadata, the resolver can only reason over:

- source pool
- weight
- hue distance

That is not enough to preserve overall family identity.

## Phase 3 - Resolver Calibration

### Goal

Preserve chart fidelity while penalizing off-family drift.

### Required change

Update `resolvePalette` so candidate scoring considers:

- contributor relevance / combo rank
- dataset role fit (`primary` vs `accent`)
- hue diversity
- family coherence
- temperature fit
- depth fit
- chroma fit

### Suggested implementation shape

1. derive a target palette profile from the top chart contributors
2. score candidate colours against that profile
3. keep hue-gap rules, but make them subordinate to family fit
4. use cross-pool escalation only when the added colour still fits the family envelope

### Important rule

Do not let late accent slots "win" merely because they add a new hue. Variety is not the same thing as coherence.

## Phase 4 - Regression Gate

### Goal

Make palette quality review repeatable.

### Required work

- use `review_palette_calibration.py` to emit markdown reports
- compare before/after reports across benchmark users
- require both:
  - mechanical improvement
  - human sign-off

### Mechanical gates to add

- forbidden-anchor hits do not increase
- preferred core hit count does not decrease on labeled users
- preferred accent hit count does not decrease on labeled users
- provenance quality remains acceptable:
  - no new library fallback on benchmark users
- no benchmark user regresses from "family mostly coherent" to "visibly split"
  in human review notes

### Human-review gate

A calibration change is not considered successful unless a reviewer can say:

- the palette reads as one coherent family
- the top-ranked accents feel like believable headliners
- any "edge" influence remains an edge, not the dominant read
- the palette no longer drifts into obviously off-family material

## Maria-Specific Guidance

Maria should not be treated as "make her exact palette win."

She should be treated as evidence of a broader issue:

- warm/deep users can currently pick up cool, airy, or metallic accents
- the engine needs stronger family-lock behaviour

For Maria-like outputs, the resolver should tend to favor:

- olive / sage / hunter green
- camel / caramel / cognac / tawny / mocha
- rust / copper / saffron / mustard / honey
- deep teal / warm navy / plum / mulberry

And strongly penalize:

- lilac
- seafoam
- silver shimmer
- other icy or spring-fresh colours

## Ash-Specific Guidance

Ash should not be treated as evidence that the engine needs to become broadly
cooler or more high-contrast.

He should be treated as evidence of a different but related failure mode:

- deep/grounded users can still accumulate cool and light anchors early in
  the selection order
- the engine can mistake plausible chart colours for good palette anchors
  even when they break the overall family

For Ash-like outputs, the resolver should tend to favor:

- deep olive / forest green
- warm charcoal / espresso / oxblood
- terracotta / rust / burnt orange / warm ochre
- deep teal / dark navy / muted gold

And strongly penalize:

- pearl
- soft white
- pale blue
- cobalt blue when it brightens the palette rather than deepening it
- other icy or fresh high-lightness anchors

### Shared lesson from Maria + Ash

The common issue is not "the wrong astrology."

The common issue is:

- too much weight on local plausibility
- not enough weight on whole-palette coherence

Any resolver rewrite should therefore be evaluated against both users together.
A change that fixes Maria by warming everything up but makes Ash muddy, or a
change that fixes Ash by deepening everything but leaves Maria pastel-cool in
the accents, is not good enough.

## Testing Surfaces

### In app

Review in:

- `Style Guide`
- `The Palette`

### Off-device

Review in:

- `docs/palette_calibration/reports/*.md`
- exported or fixture blueprint JSON

The benchmark harness is not itself an in-app feature.

## Recommended Handoff

This spec can be handed to another AI dev with the instruction:

"Implement Phase 2 and Phase 3 from `docs/palette_calibration_programme_spec_v1.md`, using `docs/palette_calibration/benchmarks/` and `review_palette_calibration.py` as the evaluation harness. Treat Maria and Ash as the first two regression classes: warm/deep accent leakage and deep-grounded cool/light intrusion. Do not change UI code unless needed for debug visibility."
