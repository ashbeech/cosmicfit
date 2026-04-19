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
- `slate` `#708090` — `chartDerived` (saturn_capricorn)
- `buttery cream` `#FFFDD0` — `chartDerived` (venus_taurus)
- `deep sage green` `#4A6741` — `chartDerived` (venus_taurus)

### Accent Anchors

- `dusty rose` `#DCAE96` — `chartDerived` (venus_taurus)
- `oxidised gold` `#B08D57` — `chartDerived` (venus_taurus)
- `teal` `#008080` — `crossPoolEscalation` (mars_gemini)
- `midnight blue` `#191970` — `crossPoolEscalation` (neptune_capricorn)

## Mechanical Review

- Preferred core hits: **2** / target **3**
- Preferred accent hits: **2** / target **2**
- Forbidden-anchor hits: **0** / max **0**

- Preferred core matches: ['buttery cream', 'deep sage green']
- Preferred accent matches: ['oxidised gold', 'dusty rose']
- Forbidden hits: ['(none)']

## Family Coherence

- Target profile: `warm/deep/muted`
- Mean family-fit score: **0.56**
- Minimum family-fit score: **0.40**
- Off-family anchors (fit < 0.50): **3**

### Per-Anchor Classification

| Anchor | Hex | Temp | Depth | Chroma | Fit |
|--------|-----|------|-------|--------|-----|
| jet black | `#0A0A0A` | neutral | deep | muted | 0.80 |
| slate | `#708090` | cool | medium | muted | 0.40 ⚠ |
| buttery cream | `#FFFDD0` | warm | light | bright | 0.40 ⚠ |
| deep sage green | `#4A6741` | neutral | deep | muted | 0.80 |
| dusty rose | `#DCAE96` | warm | light | moderate | 0.50 |
| oxidised gold | `#B08D57` | warm | medium | moderate | 0.70 |
| teal | `#008080` | cool | deep | bright | 0.40 ⚠ |
| midnight blue | `#191970` | cool | deep | moderate | 0.50 |

## Provenance

- Core provenance: `{'chartDerived': 4, 'crossPoolEscalation': 0, 'libraryFallback': 0, 'unknown': 0}`
- Accent provenance: `{'chartDerived': 2, 'crossPoolEscalation': 2, 'libraryFallback': 0, 'unknown': 0}`

## Aggregate HSL

- Average hue: `106.3`
- Average saturation: `0.48`
- Average lightness: `0.44`

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

