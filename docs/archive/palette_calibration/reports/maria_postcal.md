# Palette Calibration Review — Maria - Deep Autumn benchmark

- Benchmark: `docs/palette_calibration/benchmarks/maria_deep_autumn.json`
- Blueprint: `docs/fixtures/blueprint_input_user_2.json`
- Expected family: `deep_autumn`
- Mechanical status: **REVIEW**

## Family Target

- Temperature: `warm`
- Depth: `deep`
- Chroma: `muted_to_rich`
- Summary: Grounded, earthy, warm, dark, mineral, and softly saturated rather than icy, pastel, or metallic-cool.

## Actual Palette

### Core Anchors

- `jet black` `#0A0A0A` — `chartDerived` (saturn_capricorn)
- `deep sage green` `#4A6741` — `chartDerived` (venus_taurus)
- `sophisticated caramel` `#A0722D` — `chartDerived` (venus_taurus)
- `deep charcoal` `#333333` — `chartDerived` (moon_capricorn)

### Accent Anchors

- `cool navy` `#003153` — `chartDerived` (saturn_capricorn)
- `deep burnt saffron` `#CC7722` — `chartDerived` (venus_taurus)
- `dusty rose` `#DCAE96` — `chartDerived` (venus_taurus)
- `oxidised gold` `#B08D57` — `chartDerived` (venus_taurus)

## Mechanical Review

- Preferred core hits: **2** / target **3**
- Preferred accent hits: **3** / target **2**
- Forbidden-anchor hits: **0** / max **0**

- Preferred core matches: ['deep sage green', 'sophisticated caramel']
- Preferred accent matches: ['oxidised gold', 'deep burnt saffron', 'dusty rose']
- Forbidden hits: ['(none)']

## Family Coherence

- Target profile: `warm/deep/muted`
- Mean family-fit score: **0.60**
- Minimum family-fit score: **0.30**
- Off-family anchors (fit < 0.50): **3**

### Per-Anchor Classification

| Anchor | Hex | Temp | Depth | Chroma | Fit |
|--------|-----|------|-------|--------|-----|
| jet black | `#0A0A0A` | neutral | deep | muted | 0.80 |
| deep sage green | `#4A6741` | neutral | deep | muted | 0.80 |
| sophisticated caramel | `#A0722D` | warm | medium | moderate | 0.60 |
| deep charcoal | `#333333` | neutral | deep | muted | 0.80 |
| cool navy | `#003153` | cool | deep | bright | 0.40 ⚠ |
| deep burnt saffron | `#CC7722` | warm | medium | bright | 0.50 ⚠ |
| dusty rose | `#DCAE96` | warm | light | moderate | 0.30 ⚠ |
| oxidised gold | `#B08D57` | warm | medium | moderate | 0.60 |

## Provenance

- Core provenance: `{'chartDerived': 4, 'crossPoolEscalation': 0, 'libraryFallback': 0, 'unknown': 0}`
- Accent provenance: `{'chartDerived': 4, 'crossPoolEscalation': 0, 'libraryFallback': 0, 'unknown': 0}`

## Aggregate HSL

- Average hue: `54.2`
- Average saturation: `0.42`
- Average lightness: `0.36`

## Human Review Prompts

- [ ] Does the palette read as one coherent family rather than a bag of individually plausible chart colours?
- [ ] Do the top two accents feel like the strongest chart-characteristic flashes for this user?
- [ ] Does the palette stay warm/deep overall, or drift into cool, airy, pastel territory?
- [ ] Do later accent slots strengthen the family, or merely increase hue diversity?
- [ ] Would a stylist looking only at these anchors recognise the target family as Deep Autumn-adjacent?

## Notes

- This benchmark is intentionally opinionated: it represents a target family the user expected and manually validated.
- It should be used as a calibration exemplar, not as ground truth for every Taurus-heavy chart.

## Reviewer Summary

- Final judgement:
- Dataset changes needed:
- Resolver changes needed:

