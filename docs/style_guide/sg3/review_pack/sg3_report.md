# SG-3 Validator Report

Cache: `data/style_guide/blueprint_narrative_cache_sg3.json`

## Quality re-scan (machine)

- Clusters scanned: **192**
- Sections scanned: **3072**
- Dash violations: **0**
- Banned-tic violations: **0**
- Season-word violations (palette): **0**
- style_core missing coreFormula verbatim: **0**
- Closing not ending with formula: **0**

## Run log
- Outcomes: {'pass': 3208, 'pass_after_retry': 150, 'applied': 372, 'skip_present': 2626, 'error': 2}
- Warning types: {'concrete_noun_floor': 280, 'phrase_repetition': 1018, 'revised 11 sections, reverted 1': 33, 'revised 15 sections, reverted 1': 92, 'revised 12 sections, reverted 1': 36, 'revised 14 sections, reverted 1': 61, 'revised 13 sections, reverted 3': 2, 'revised 13 sections, reverted 1': 63, 'revised 14 sections, reverted 2': 15, 'revised 10 sections, reverted 1': 17, 'revised 11 sections, reverted 0': 1, 'revised 9 sections, reverted 1': 14, 'revised 12 sections, reverted 2': 5, 'revised 13 sections, reverted 0': 3, 'revised 6 sections, reverted 1': 1, 'revised 13 sections, reverted 2': 4, 'revised 12 sections, reverted 0': 5, 'revised 7 sections, reverted 1': 4, 'revised 6 sections, reverted 2': 1, 'revised 8 sections, reverted 1': 6, 'revised 9 sections, reverted 0': 1, 'revised 10 sections, reverted 2': 3, 'Gemini API failed after 3 attempts (model=gemini-3.1-pro-preview)': 2, 'revised 9 sections, reverted 2': 2, 'revised 14 sections, reverted 0': 1, 'revised 15 sections, reverted 0': 1, 'revised 11 sections, reverted 2': 1}

## Quarantine / Triage
- Quarantined clusters: 0
- Triage-tagged clusters: 179

## accessoryCategoryPlan comparison

- **venus_taurus__moon_capricorn__earth_dominant** (quietLuxury, key `quietLuxury_selfContained_muted`, merged=True)
  - include: ['Handbags (slot 1, include)', 'Scarves (slot 2, include)', 'Belts (slot 3, merge)', 'Keepsake jewellery (slot 3, merge)']
  - omit: []
- **venus_leo__moon_aries__fire_dominant** (boldExpression, key `boldExpression_selfContained_polished`, merged=False)
  - include: ['Statement jewellery (slot 1, include)', 'Footwear (slot 2, include)', 'Structured bags (slot 3, include)']
  - omit: ['Scarves']
- **venus_gemini__moon_aquarius__air_dominant** (versatileAdaptive, key `versatileAdaptive_communityOriented_mixed`, merged=False)
  - include: ['Eyewear (slot 1, include)', 'Bags (slot 2, include)', 'Footwear (slot 3, include)']
  - omit: ['Belts']
- **venus_cancer__moon_scorpio__water_dominant** (quietLuxury, key `quietLuxury_selfContained_muted`, merged=True)
  - include: ['Handbags (slot 1, include)', 'Scarves (slot 2, include)', 'Belts (slot 3, merge)', 'Keepsake jewellery (slot 3, merge)']
  - omit: []
