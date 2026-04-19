# Palette Calibration Review — Ash - Deep Autumn with Winter edge benchmark

- Benchmark: `docs/palette_calibration/benchmarks/ash_deep_autumn_winter_edge.json`
- Blueprint: `docs/fixtures/blueprint_input_user_1.json`
- Expected family: `deep_autumn_with_winter_edge`
- Mechanical status: **REVIEW**

## Family Target

- Temperature: `slightly_warm_to_neutral`
- Depth: `deep`
- Chroma: `muted_to_rich`
- Summary: Darker, grounded, slightly warm colours that feel expensive and controlled, with room for black, oxblood, and dark navy as a winter edge.

## Actual Palette

### Core Anchors

- `pearl` `#F0EAD6` — `chartDerived` (moon_cancer)
- `soft white` `#FAFAFA` — `chartDerived` (moon_cancer)
- `cobalt blue` `#0047AB` — `chartDerived` (sun_sagittarius)
- `warm taupe` `#8B8589` — `chartDerived` (ascendant_virgo)

### Accent Anchors

- `pale blue` `#AEC6CF` — `chartDerived` (moon_cancer)
- `seashell pink` `#FFF5EE` — `chartDerived` (moon_cancer)
- `neon lime` `#CCFF00` — `chartDerived` (venus_aquarius)
- `ultraviolet` `#6B0099` — `chartDerived` (venus_aquarius)

## Mechanical Review

- Preferred core hits: **0** / target **2**
- Preferred accent hits: **0** / target **2**
- Forbidden-anchor hits: **4** / max **1**

- Preferred core matches: ['(none)']
- Preferred accent matches: ['(none)']
- Forbidden hits: ['pearl', 'soft white', 'pale blue', 'cobalt blue']

## Family Coherence

- Target profile: `warm/deep/muted`
- Mean family-fit score: **0.45**
- Minimum family-fit score: **0.10**
- Off-family anchors (fit < 0.50): **4**

### Per-Anchor Classification

| Anchor | Hex | Temp | Depth | Chroma | Fit |
|--------|-----|------|-------|--------|-----|
| pearl | `#F0EAD6` | warm | light | moderate | 0.50 |
| soft white | `#FAFAFA` | neutral | light | muted | 0.40 ⚠ |
| cobalt blue | `#0047AB` | cool | deep | bright | 0.40 ⚠ |
| warm taupe | `#8B8589` | neutral | medium | muted | 0.60 |
| pale blue | `#AEC6CF` | cool | light | moderate | 0.10 ⚠ |
| seashell pink | `#FFF5EE` | warm | light | bright | 0.40 ⚠ |
| neon lime | `#CCFF00` | warm | medium | bright | 0.60 |
| ultraviolet | `#6B0099` | neutral | deep | bright | 0.60 |

## Provenance

- Core provenance: `{'chartDerived': 4, 'crossPoolEscalation': 0, 'libraryFallback': 0, 'unknown': 0}`
- Accent provenance: `{'chartDerived': 4, 'crossPoolEscalation': 0, 'libraryFallback': 0, 'unknown': 0}`

## Aggregate HSL

- Average hue: `144.5`
- Average saturation: `0.59`
- Average lightness: `0.66`

## Human Review Prompts

- [ ] Does the palette read as grounded, dark, and controlled rather than bright, playful, or airy?
- [ ] Do the anchors feel like one coherent family, or does the palette split between autumnal depth and cool bright contrast?
- [ ] Is the winter edge limited to black, dark navy, burgundy, or oxblood rather than turning the whole palette icy?
- [ ] Would a stylist looking only at these anchors recognise a Deep Autumn base before a Winter reading?
- [ ] Do light or cool anchors weaken the structure of the palette?

## Notes

- This benchmark is based on the live user and should not be conflated with the older repo fixture currently named Ash.
- The known current drift pattern for this user is cool/light intrusion: pearl, soft white, pale blue, and cobalt blue.

## Reviewer Summary

- Final judgement:
- Dataset changes needed:
- Resolver changes needed:

