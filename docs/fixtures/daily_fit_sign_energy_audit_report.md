# Daily Fit — SignEnergyMap Meaning Allocation Audit Report

**Status:** Complete, audit-only  
**Date:** 2026-05-22  
**Scope:** `DailyFitCalibration.default.signEnergyMap` only, with read-only downstream validation  
**Constraint:** No production, inspector, test, script, or calibration code changes were made  
**Implementation handoff:** [`docs/handoff/daily_fit_sign_energy_implementation_handoff.md`](../handoff/daily_fit_sign_energy_implementation_handoff.md)

This version supersedes the earlier report artifact. The previous artifact correctly identified that Sun-sign multipliers materially affect production output, but its neutral-Sun counterfactual over-corrected by dividing already pre-multiplier `rawEnergyScores` by the sign multipliers. Current inspector diagnostics show `postMultiplierScores = rawEnergyScores * signMultiplier`, so the read-only all-1.0 counterfactual is `normaliseToTwentyOne(rawEnergyScores)`.

---

## D2 — Executive Summary

### Bottom line

The 72-cell sign map is astrologically coherent in broad direction, but too confident in several numeric magnitudes for an app forecasting a user's daily **fashion weather**. The table works best when treated as a natal style-identity filter: it says how a Leo, Taurus, Scorpio, Aquarius, etc. tends to translate the sky into clothes. It is weaker as a daily weather layer, because production applies the natal Sun filter after all sky and chart inputs are mixed.

**Verdicts:** 59 Keep, 11 Adjust magnitude, 2 Adjust meaning, 0 Remove. No cell is nonsensical enough to delete outright. The main problems are saturation, element stacking, and a few inherited legacy meanings that read more like personality shorthand than fashion semantics.

### Corrected downstream impact

Read-only inspector refresh, 14 UTC days (`2026-05-09` through `2026-05-22`), using the four preset births in `inspector/Resources/presets.json`:

| Preset | Sun | Production dominant with multipliers | Neutral-Sun counterfactual dominant | Dominant flip vs neutral | Avg bar delta |
|--------|-----|--------------------------------------|-------------------------------------|--------------------------|---------------|
| fire | Aries | drama 11, playful 3 | edge 7, classic 5, playful 2 | 13/14 | 2.57 |
| earth | Taurus | classic 13, edge 1 | playful 5, edge 5, classic 3, drama 1 | 10/14 | 4.86 |
| air | Aquarius | edge 14 | drama 11, classic 2, playful 1 | 14/14 | 3.29 |
| water | Scorpio | drama 14 | classic 9, drama 3, playful 2 | 11/14 | 4.00 |

The corrected finding is still strong: sign multipliers materially set the production dominant energy on most days, especially Aquarius edge, Taurus classic, and Scorpio drama. The prior "100% for every preset" claim was too strong because it used the wrong neutral baseline.

**Scorpio note:** production picks **drama** as dominant on **14/14** days with multipliers on. The **11/14 flip** count means that on 3 days the neutral-Sun counterfactual also lands on drama (tied top scores), so the label does not change even though bar values differ. Dominant lock and flip rate measure different things.

### Readable product interpretation

Professionally, the sign layer is mostly good astrology translated into style language: Taurus as tactile polish, Leo as visibility, Virgo and Capricorn as disciplined utility/classic, Aquarius as future-facing edge, Pisces as softness and imagination. The problem is that a daily outfit forecast should feel like **today's sky through my wardrobe**, not always **my Sun sign wearing a costume**. The current `1.50` ceilings can make the Sun archetype louder than the actual weather.

### Recommendations snapshot

| Priority | Recommendation |
|----------|----------------|
| P0 | Decide whether production daily vibe should remain Sun-filtered, or whether sign multipliers should move to chart-anchor identity only, matching the `stage1_experimental` sky path. **Blocks all implementation until Ash signs off.** |
| P1 Phase 1 | Apply 13 mandatory cell changes in D5 (exact floats). |
| P1 Phase 2 | Optional 1.35 ceiling caps on flagship signs — product approval required. |
| P1 | Fix inherited weak meanings: Cancer utility and Scorpio utility should not be treated as primary boosts. |
| P1 | Document or dedupe stacking where sign map and `elementBoosts` push the same energy. |
| P2 | Add direct Leo preset coverage, replace anecdotal sign tests with rule-table coverage. |

---

## D1 — Inventory & Provenance

Source verified in `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift`: `DailyFitCalibration.default.signEnergyMap`.

Production path verified in `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift`:

1. Accumulate raw scores from natal, progressed, transits, lunar phase, and current Sun.
2. Apply natal Sun-sign multipliers to every energy.
3. Normalise to the 21-point `VibeBreakdown`.

`stage1_experimental` differs: chart anchor applies sign multipliers, but sky vibe calls `generatePartialVibeProfileWithRaw(... shouldApplySignMultipliers: false)`. This means production daily bars and stage1 sky bars are not philosophically equivalent.

### Current matrix

| Sign | Classic | Playful | Romantic | Utility | Drama | Edge |
|------|---------|---------|----------|---------|-------|------|
| Aries | 0.90 | 1.30 | 1.00 | 1.00 | 1.40 | 1.20 |
| Taurus | 1.50 | 0.90 | 1.30 | 1.20 | 0.85 | 1.00 |
| Gemini | 0.85 | 1.50 | 1.00 | 1.00 | 1.00 | 1.20 |
| Cancer | 1.10 | 1.00 | 1.40 | 1.20 | 0.95 | 1.00 |
| Leo | 0.90 | 1.30 | 1.00 | 0.90 | 1.50 | 1.00 |
| Virgo | 1.50 | 0.95 | 0.90 | 1.40 | 0.85 | 1.00 |
| Libra | 1.30 | 1.20 | 1.40 | 1.00 | 0.95 | 0.90 |
| Scorpio | 1.00 | 0.85 | 0.90 | 1.10 | 1.50 | 1.30 |
| Sagittarius | 0.90 | 1.40 | 1.00 | 1.00 | 1.20 | 1.20 |
| Capricorn | 1.50 | 0.85 | 0.95 | 1.40 | 1.00 | 1.00 |
| Aquarius | 0.85 | 1.20 | 0.90 | 1.10 | 1.00 | 1.50 |
| Pisces | 0.90 | 1.10 | 1.50 | 1.00 | 1.00 | 1.20 |

### Provenance finding

The code comment ties these values to removed legacy `VibeBreakdownGenerator.getSunSignEnergyPreference()`. The direction appears migrated from legacy archetypes and compressed into the current 0.85-1.50 band. I found no written product rationale that explains why, for example, Scorpio drama remains 1.50 while Aries drama is 1.40, or why Cancer utility survives as 1.20.

---

## D1 — Full 72-Cell Meaning Audit

Working fashion-weather definitions:

| Energy | Fashion-weather meaning |
|--------|-------------------------|
| Classic | Timeless, polished, edited, tradition-aware |
| Playful | Novelty, wit, movement, light experimentation |
| Romantic | Softness, sensuality, intimacy, emotional texture |
| Utility | Practicality, function, ease, wardrobe-as-tool |
| Drama | Visibility, scale, statement, theatrical presence |
| Edge | Subversion, sharpness, futurism, unconventionality |

Element stack notes refer to `elementBoosts` on planets in signs of the same element: Fire adds drama/playful, Earth classic/utility, Air playful/edge, Water romantic/drama.

| Sign | Energy | Mult | Verdict | Proposed | Rationale |
|------|--------|------|---------|----------|-----------|
| Aries | classic | 0.90 | Adjust magnitude | 0.95 | Cardinal Mars fire is direct, athletic, and heat-seeking, so a classic dampen is right. At 0.90 it is a strong floor for a sign that can still wear clean tailoring as sharp actionwear. |
| Aries | playful | 1.30 | Keep | — | Fast, initiating fire maps well to playful fashion weather: sporty colour, movement, novelty, and quick-change styling. Stacks with Fire playful, but not at a ceiling. |
| Aries | romantic | 1.00 | Keep | — | Aries can be passionate, but its style expression is not primarily soft, sentimental, or yielding. Neutral is the correct read. |
| Aries | utility | 1.00 | Keep | — | Aries needs clothes that move, but that is active convenience rather than true utility archetype. Neutral is fair. |
| Aries | drama | 1.40 | Adjust magnitude | 1.35 | Direction is excellent: Aries is bold, competitive, hot, and visible. The issue is magnitude plus Fire drama stacking, which makes Mars weather too dominant in production. |
| Aries | edge | 1.20 | Keep | — | Mars gives sharpness, speed, and rule-breaking courage. A mild edge boost is appropriate without pretending Aries is the most avant-garde sign. |
| Taurus | classic | 1.50 | Keep | — | Fixed Venus earth is the clearest sign for tactile polish, quality, and enduring silhouettes. A ceiling boost is defensible if Taurus is meant to anchor luxury-classic weather. |
| Taurus | playful | 0.90 | Keep | — | Taurus is fixed and sensorially consistent; it resists gimmick and novelty. Strong dampen is acceptable because romantic/classic still carry beauty. |
| Taurus | romantic | 1.30 | Keep | — | Venus rulership supports sensual fabrics, skin-touch softness, and intimate pleasure. This is romantic in a grounded, material way. |
| Taurus | utility | 1.20 | Keep | — | Earth durability, comfort, and repeatable wardrobe staples justify a mild utility boost. It stacks with Earth utility but remains secondary to classic. |
| Taurus | drama | 0.85 | Keep | — | Taurus tends toward richness rather than spectacle. The floor is severe, but it cleanly differentiates Venus earth from Leo/Scorpio theatricality. |
| Taurus | edge | 1.00 | Keep | — | Taurus can be stubborn but not inherently subversive in fashion vocabulary. Neutral is correct. |
| Gemini | classic | 0.85 | Keep | — | Mutable Mercury air wants change, conversation, and clever styling over timeless restraint. The strong dampen is defensible because playful is the flagship. |
| Gemini | playful | 1.50 | Keep | — | This is the archetypal playful sign: wit, duality, styling games, prints, and mutable experimentation. Ceiling boost is coherent, though it should be monitored with Air playful stacking. |
| Gemini | romantic | 1.00 | Keep | — | Gemini is flirtatious and social, but not primarily soft, devotional, or sensual in this style system. Neutral is appropriate. |
| Gemini | utility | 1.00 | Keep | — | Mercury can be practical, but Gemini's product read is communication and variety rather than wardrobe function. Neutral is right. |
| Gemini | drama | 1.00 | Keep | — | Gemini can perform verbally, but fashion drama is not its natural lane. Neutral avoids turning every air sign into visibility. |
| Gemini | edge | 1.20 | Keep | — | Intellectual mischief, trend sampling, and androgynous or unexpected pairings justify a mild edge boost. It stacks with Air edge at a modest level. |
| Cancer | classic | 1.10 | Keep | — | Moon-ruled Cancer carries memory, heritage, and protective familiarity, which can express as vintage softness or traditional comfort. Mild classic boost fits. |
| Cancer | playful | 1.00 | Keep | — | Cancer's mood can be whimsical, but play is not stable enough to encode as a sign preference. Neutral is better. |
| Cancer | romantic | 1.40 | Keep | — | Cardinal water is emotionally expressive, intimate, and protective. Romantic fashion weather is a strong Cancer match and stacks naturally with Water romantic. |
| Cancer | utility | 1.20 | Adjust meaning | 1.05 | Protective does not equal utilitarian. Cancer wants comfort, safety, and softness, not tactical function. Keep only a tiny ease/comfort lift. |
| Cancer | drama | 0.95 | Keep | — | Cancer can be dramatic emotionally, but fashion expression is usually private and lunar rather than spectacle. Water drama stacking softens this dampen in charts. |
| Cancer | edge | 1.00 | Keep | — | Cancer is not primarily avant-garde or disruptive. Neutral is correct. |
| Leo | classic | 0.90 | Keep | — | Leo prefers radiance and self-display over restrained classicism. Strong dampen is acceptable because regal polish still appears through drama. |
| Leo | playful | 1.30 | Keep | — | Sun-ruled fixed fire is generous, warm, performative, and costume-friendly. Playful boost is a good fashion read and stacks with Fire playful. |
| Leo | romantic | 1.00 | Keep | — | Leo love is grand and expressive, but not necessarily soft or intimate in the Romantic energy sense. Neutral is sound. |
| Leo | utility | 0.90 | Adjust magnitude | 0.95 | Direction is right, but daily outfit forecasts still need wearability. A 0.90 floor makes Leo too allergic to function. |
| Leo | drama | 1.50 | Adjust magnitude | 1.35 | Meaning is correct: Leo is the solar performer. The ceiling plus Fire drama stacking risks locking fashion weather into statement mode even when the sky is subtler. |
| Leo | edge | 1.00 | Keep | — | Leo boldness is theatrical, royal, or glamorous rather than subversive. Neutral edge is appropriate. |
| Virgo | classic | 1.50 | Keep | — | Mutable Mercury earth is edited, precise, and materially discerning. Ceiling classic is defensible for crisp, clean, exacting style. |
| Virgo | playful | 0.95 | Keep | — | Virgo can be witty, but play is dry and controlled. A mild dampen is accurate. |
| Virgo | romantic | 0.90 | Keep | — | Virgo intimacy is understated and selective rather than openly soft. Strong dampen is acceptable, though not lower. |
| Virgo | utility | 1.40 | Adjust magnitude | 1.30 | Utility is central Virgo: fit, function, repair, usefulness. The value should remain high but not combine with classic to over-lock earth charts. |
| Virgo | drama | 0.85 | Keep | — | Virgo edits out excess. Strong drama dampen is one of the cleanest meanings in the table. |
| Virgo | edge | 1.00 | Keep | — | Virgo can be cerebral or exacting, but not inherently subversive. Neutral is correct. |
| Libra | classic | 1.30 | Keep | — | Venus cardinal air understands proportion, symmetry, and polish. Classic boost fits elegant social weather. |
| Libra | playful | 1.20 | Adjust magnitude | 1.30 | Libra is an air sign and social stylist. Playful should compete more strongly with romantic/classic so Libra does not become only prettiness and polish. |
| Libra | romantic | 1.40 | Keep | — | Partnership, beauty, grace, and Venusian charm make romantic a core Libra signal. Strong boost is sound. |
| Libra | utility | 1.00 | Keep | — | Libra optimizes balance and presentation, not practical gear. Neutral is correct. |
| Libra | drama | 0.95 | Keep | — | Libra avoids harsh confrontation and prefers harmony. Mild dampen is appropriate. |
| Libra | edge | 0.90 | Adjust magnitude | 0.95 | A strong edge dampen overcorrects. Cardinal air can be fashion-forward, art-scene, and taste-making even when not aggressively subversive. |
| Scorpio | classic | 1.00 | Keep | — | Scorpio can wear severe classics, but the archetype is intensity rather than timeless polish. Neutral is right. |
| Scorpio | playful | 0.85 | Keep | — | Fixed water is deep, private, and controlled. The floor is coherent because Scorpio rarely wants lightness as its primary weather. |
| Scorpio | romantic | 0.90 | Adjust magnitude | 0.95 | Scorpio is not "soft romantic," but it is magnetic, intimate, and erotic. A strong dampen underplays that water signature. |
| Scorpio | utility | 1.10 | Adjust meaning | 1.00 | Tactical/protective readings are not enough for a utility boost in fashion weather. Scorpio's wardrobe-as-armor belongs more to drama/edge than utility. |
| Scorpio | drama | 1.50 | Adjust magnitude | 1.35 | Direction is excellent: Scorpio carries intensity, contrast, and high-stakes presence. Production dominant = drama on 14/14 days with multipliers; neutral-Sun rarely picks drama (3/14). |
| Scorpio | edge | 1.30 | Keep | — | Pluto/Mars symbolism maps cleanly to dark glamour, subversion, leather/metal severity, and taboo-breaking style. Mild-strong edge boost is right. |
| Sagittarius | classic | 0.90 | Keep | — | Mutable Jupiter fire is expansive and restless, not restrained. Strong classic dampen is coherent. |
| Sagittarius | playful | 1.40 | Keep | — | Exploration, humour, colour, and appetite for novelty make playful a primary Sagittarius style weather. Fire playful stacks, but the sign needs a high value. |
| Sagittarius | romantic | 1.00 | Keep | — | Sagittarius warmth is generous but not usually soft, sentimental, or intimate. Neutral is correct. |
| Sagittarius | utility | 1.00 | Keep | — | Travel can imply practical clothing, but the archetype is freedom more than utility. Neutral avoids over-literalism. |
| Sagittarius | drama | 1.20 | Keep | — | Fire visibility and Jupiter scale justify a mild drama boost without making Sagittarius a Leo clone. |
| Sagittarius | edge | 1.20 | Keep | — | Philosophical rule-breaking and outsider freedom justify a mild edge boost. |
| Capricorn | classic | 1.50 | Keep | — | Saturn cardinal earth is authority, structure, tailoring, and status restraint. Ceiling classic is professionally sound. |
| Capricorn | playful | 0.85 | Keep | — | Capricorn tends serious, strategic, and controlled. Strong play dampen is coherent. |
| Capricorn | romantic | 0.95 | Keep | — | Warmth is reserved rather than absent. Mild dampen is better than pushing Capricorn into coldness. |
| Capricorn | utility | 1.40 | Keep | — | Wardrobe as armor, work, authority, and competence strongly support utility. The value is high but less problematic than Virgo because classic/utility are Capricorn's core. |
| Capricorn | drama | 1.00 | Keep | — | Capricorn can project power, but through structure rather than theatricality. Neutral is correct. |
| Capricorn | edge | 1.00 | Keep | — | Capricorn can be severe or minimalist, but not inherently avant-garde. Neutral is right. |
| Aquarius | classic | 0.85 | Keep | — | Fixed air with Saturn/Uranus symbolism resists convention and inherited taste. Strong classic dampen fits future-facing weather. |
| Aquarius | playful | 1.20 | Keep | — | Quirk, social experimentation, and unexpected styling support a mild playful boost. Air playful stacks. |
| Aquarius | romantic | 0.90 | Keep | — | Aquarius is often emotionally spacious, abstract, and detached. Strong romantic dampen is coherent. |
| Aquarius | utility | 1.10 | Adjust magnitude | 1.00 | Systems thinking does not automatically mean wardrobe utility. Leave function to earth signs unless a product ontology says techwear is utility. |
| Aquarius | drama | 1.00 | Keep | — | Aquarius stands apart but does not always seek theatrical visibility. Neutral keeps edge distinct from drama. |
| Aquarius | edge | 1.50 | Keep, monitor | 1.35 optional | Aquarius is the flagship edge sign: future, refusal, alien cool, unconventional silhouette. The meaning is correct, but refreshed downstream shows edge dominant 14/14 days, so cap if daily sky variety is the goal. |
| Pisces | classic | 0.90 | Keep | — | Mutable water blurs strict form and tradition. Strong classic dampen is acceptable. |
| Pisces | playful | 1.10 | Keep | — | Pisces has whimsy, fantasy, and costume imagination, but play is secondary to romantic softness. Mild boost fits. |
| Pisces | romantic | 1.50 | Keep, monitor | 1.35 optional | Neptune/Jupiter Pisces is the clearest romantic sign: softness, dream, longing, dissolving boundaries. Meaning is excellent; ceiling should be monitored for daily saturation. |
| Pisces | utility | 1.00 | Keep | — | Pisces is not a practical wardrobe archetype. Neutral is already generous. |
| Pisces | drama | 1.00 | Keep | — | Pisces can be cinematic, but its intensity is diffuse and atmospheric rather than dramatic in the Leo/Scorpio sense. Neutral is correct. |
| Pisces | edge | 1.20 | Adjust magnitude | 1.25 | Surrealism, mysticism, and boundary-dissolving style justify a little more edge than the current mild boost, without confusing Pisces with Aquarius/Scorpio. |

---

## D3 — Cross-Sign Coherence Rules

| Rule | Result | Notes |
|------|--------|-------|
| R1: all signs define all six energies | Pass | 12 x 6 present in source. |
| R2: values in sanity band | Pass | All values are 0.85-1.50. |
| R3: Leo drama >= Aries drama | Pass | 1.50 >= 1.40, though both should be capped if sky variance matters. |
| R4: Taurus classic >= 1.3 | Pass | 1.50. |
| R5: Aquarius edge >= 1.3 | Pass | 1.50. |
| R6: Pisces romantic >= 1.3 | Pass | 1.50. |
| R7: each sign has no more than one strong dampen | Fail | Several signs have two or more values <= 0.95. This is not always wrong, but it should be intentional. |
| R8: no sign boosts more than two energies above 1.4 | Pass | The table avoids "everything sign" inflation. |
| R9: fire signs have drama or playful highest | Pass | Aries, Leo, Sagittarius all satisfy. |
| R10: earth signs have classic or utility top-2 | Pass | Taurus, Virgo, Capricorn all satisfy. |
| R11: water signs have romantic or drama top-2 | Pass | Cancer, Scorpio, Pisces satisfy. |
| R12: air signs have playful or edge top-2 | Partial fail | Gemini/Aquarius pass; Libra top-2 are romantic/classic, so Libra reads Venus-first more than air-first. |
| R13: opposite signs are not identical | Pass | All axis pairs differ meaningfully. |
| R14: max boost/min dampen asymmetry intentional | Partial | Boost ceiling 1.50 is much more forceful than 0.85 dampen in downstream normalisation. No product sign-off found. |

### Test status

Attempted:

```bash
xcodebuild test -project "Cosmic Fit.xcodeproj" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Cosmic_FitTests/AstrologicalSoundness_Tests
```

Result: tests did not run — `Cosmic_FitTests` is not a member of the specified test plan or scheme. A separate duplicate tarot PNG build failure has also been reported in the workspace; either blocker may affect CI.

---

## D4 — Downstream Impact, Read-Only

### Method

Inspector queried via `POST /api/inspect` on localhost using **`birth` from `inspector/Resources/presets.json`** (required — generic birth resolves all presets to Gemini Sun and invalidates sign attribution). No code or calibration values were changed.

Presets:

| Preset | Birth | Sun |
|--------|-------|-----|
| fire | 1990-04-05 05:30 London | Aries |
| earth | 1985-05-10 06:00 London | Taurus |
| air | 1985-02-10 04:00 London | Aquarius |
| water | 1990-11-10 02:00 London | Scorpio |

Counterfactual formula:

```text
neutral Sun = normaliseToTwentyOne(rawEnergyScores)
production    = normaliseToTwentyOne(rawEnergyScores * signEnergyMap[natal Sun])
```

Inspector diagnostics expose pre-multiplier `rawEnergyScores` and post-multiplier `postMultiplierScores` where `postMultiplierScores[energy] = rawEnergyScores[energy] * signMultiplier[energy]`.

### Production versus neutral Sun

| Preset | Prod dominant (14d) | Neutral CF dominant (14d) | Flip days | Avg L1 delta |
|--------|---------------------|---------------------------|-----------|--------------|
| Aries fire | drama 11, playful 3 | edge 7, classic 5, playful 2 | 13/14 | 2.57 |
| Taurus earth | classic 13, edge 1 | playful 5, edge 5, classic 3, drama 1 | 10/14 | 4.86 |
| Aquarius air | edge 14 | drama 11, classic 2, playful 1 | 14/14 | 3.29 |
| Scorpio water | drama 14 | classic 9, drama 3, playful 2 | 11/14 | 4.00 |

### Example traces

| Preset/date | Raw dominant | Production post-mult effect | Final with multipliers | Neutral-Sun CF |
|-------------|--------------|-----------------------------|------------------------|----------------|
| Aries 2026-05-09 | edge | drama 4.18 -> 5.85, edge 4.27 -> 5.12 | drama 5, edge 4 | drama 4, edge 4, romantic 4, playful 4 |
| Taurus 2026-05-09 | drama | classic 3.14 -> 4.71, drama 3.74 -> 3.18 | classic 5, romantic 5 | drama 4, edge 4, playful 4, romantic 4 |
| Aquarius 2026-05-09 | drama | edge 4.07 -> 6.11 | edge 6 | drama 5, edge 4 |
| Scorpio 2026-05-09 | drama | drama 4.24 -> 6.36, edge 3.98 -> 5.18 | drama 6 | classic 4, romantic 4, drama 4, edge 4 |

### Production versus `stage1_experimental`

| Preset | Dominant differs production vs stage1 |
|--------|---------------------------------------|
| Aries | 14/14 |
| Taurus | 11/14 |
| Aquarius | 14/14 |
| Scorpio | 13/14 |

Inspector may still expose post-multiplier diagnostic numbers on stage1 runs, but the **stage1 sky vibe payload does not apply sign multipliers** to daily bars.

### Leo drama question

No Leo preset in the inspector catalog. Proxy: Scorpio drama 1.50 ceiling + `docs/fixtures/daily_fit_calibration_report.txt` `ashProfile` (Leo Sun, drama dominant 7/7, D=7 stable). **Add a Leo preset and rerun the 14-day harness** before merging Leo-specific caps (see implementation handoff P2).

---

## D5 — Recommended Fixes, Prose Only

### P0 — Product decision (blocks implementation)

| Option | Behaviour | When to choose |
|--------|-----------|----------------|
| **A** | Sign map on chart anchor only; remove from production daily full-mix (align with `stage1_experimental` sky path) | Daily Fit promise is **fashion weather** — sky should move the dominant read more often |
| **B** | Keep production Sun-filtered path; tune magnitudes only | Daily Fit promise is **natal signature through today** — Sun identity intentionally dominant |

**Do not change floats until Ash picks A or B.**

### P1 Phase 1 — Mandatory cell changes (13 cells)

Apply exactly these values in `DailyFitCalibration.default.signEnergyMap`:

| Sign | Energy | Current | Proposed |
|------|--------|---------|----------|
| Aries | classic | 0.90 | **0.95** |
| Aries | drama | 1.40 | **1.35** |
| Cancer | utility | 1.20 | **1.05** |
| Leo | utility | 0.90 | **0.95** |
| Leo | drama | 1.50 | **1.35** |
| Virgo | utility | 1.40 | **1.30** |
| Libra | playful | 1.20 | **1.30** |
| Libra | edge | 0.90 | **0.95** |
| Scorpio | romantic | 0.90 | **0.95** |
| Scorpio | utility | 1.10 | **1.00** |
| Scorpio | drama | 1.50 | **1.35** |
| Aquarius | utility | 1.10 | **1.00** |
| Pisces | edge | 1.20 | **1.25** |

### P1 Phase 2 — Optional ceiling caps (product approval required)

Only if Phase 1 still leaves unacceptable dominant lock after inspector rerun:

| Sign | Energy | Current | Optional cap | Notes |
|------|--------|---------|--------------|-------|
| Taurus | classic | 1.50 | 1.35 | Semantically correct flagship — do not cap without evidence |
| Gemini | playful | 1.50 | 1.35 | Same |
| Virgo | classic | 1.50 | 1.35 | Same |
| Capricorn | classic | 1.50 | 1.35 | Same |
| Aquarius | edge | 1.50 | 1.35 | Edge locked 14/14 in downstream |
| Pisces | romantic | 1.50 | 1.35 | Same |

### P1 — Stacking policy (Ash decision)

| Element | Stacked energies | Highest-risk signs |
|---------|------------------|--------------------|
| Fire | drama, playful | Aries and Leo drama; Sagittarius playful |
| Earth | classic, utility | Taurus/Virgo/Capricorn classic lock |
| Air | playful, edge | Aquarius edge; Gemini playful |
| Water | romantic, drama | Cancer/Pisces romantic; Scorpio drama |

If daily weather: dedupe or soften `elementBoosts` when Sun `signEnergyMap` already exceeds 1.30 for the same energy. If natal signature: keep stacking and document in `docs/calibration_signoff.md`.

### P2 — Evidence and test gaps

Add Leo inspector preset. Add parameterized R1–R14 tests. Add test-only all-1.0 / capped-map harness for future audits.

---

## D6 — Test Gap List

| Gap | Current state | Follow-up |
|-----|---------------|-----------|
| Scheme cannot run target from CLI | Test plan membership error | Fix scheme/test plan membership |
| Duplicate tarot PNG targets | May block full build | Resolve copy-target conflict |
| Semantic coverage | Four sign assertions only | Parameterized R1–R14 tests |
| Product min/max | Tests check (0, 3) only | Assert approved band explicitly |
| Downstream dominance | No 14-day harness | Snapshot flip rates production vs stage1 |
| Leo evidence | No Leo preset | Add preset; rerun harness |
| Counterfactuals | No all-1.0 runtime switch | Test-only harness |
| Stacking | No sign × element test | Synthetic Leo + fire planets chart |

---

## D7 — Evidence Artifacts

| Artifact | Status | Use |
|----------|--------|-----|
| `docs/fixtures/sign_energy_matrix_baseline.txt` | Current | Source matrix snapshot |
| `docs/fixtures/sign_energy_audit_matrix.csv` | Aligned with this report | 72-row spreadsheet export |
| `docs/fixtures/sign_audit_downstream_corrected.txt` | Pre-Phase-1 baseline | 14-day summary using corrected neutral formula |
| `docs/fixtures/sign_audit_downstream_post_phase1.txt` | **Current** | Post Phase 1 + sign multiplier policy (includes Leo preset) |
| `docs/fixtures/sign_audit_inspector_evidence.json` | **Current** | Sample traces; policy fields + chart-anchor mults |
| `docs/fixtures/sign_audit_downstream_production.txt` | **Stale — do not use** | Used wrong neutral counterfactual (`raw / multiplier`) |
| `docs/fixtures/daily_fit_calibration_report.txt` | Reference | Leo `ashProfile` drama 7/7 days |

---

## Acceptance Checklist

| Criterion | Status |
|-----------|--------|
| All 72 cells have rationale and verdict | Met |
| Downstream impact proven read-only (corrected formula) | Met |
| `stage1_experimental` documented | Met |
| Stacking addressed | Met |
| Fixes recommended in prose only | Met |
| Implementation handoff written | Met — see linked doc |
| No production code changes | Met |

Implementation of recommended values requires Ash sign-off on **P0** first. See [`daily_fit_sign_energy_implementation_handoff.md`](../handoff/daily_fit_sign_energy_implementation_handoff.md).

---

## Implementation Addendum (2026-05-22)

**P0 Option A** is implemented for `stage1_experimental` via `DailyFitCalibration.signMultiplierPolicy`:

| Path | Policy |
|------|--------|
| Daily sky vibe (`vibeProfile` / `skyVibeProfile`) | OFF (`applyToDailyVibe: false`) |
| Chart anchor (`chartVibeProfile`) | ON (`applyToChartAnchor: true`) |
| Production / `legacy_baseline` daily full-mix | ON (unchanged) |

**Phase 1** applied the 13 mandatory D5 cell updates in `DailyFitCalibration.default.signEnergyMap`. Stage1 sky bars are structurally unchanged (policy OFF); chart anchor and production daily vibe reflect the tuned map.

Inspector diagnostics now label post-multiplier trace as equal to raw when daily policy is OFF. Leo preset added to `inspector/Resources/presets.json`.

**Validation harness:** `python3 tools/sign_energy_inspector_harness.py` (inspector running on `:7777`) writes `docs/fixtures/sign_audit_downstream_post_phase1.txt` and refreshes `sign_audit_inspector_evidence.json`.

**Post-Phase 1 production highlights (14-day window, see fixture):**
- Scorpio drama dominant: 14/14 (unchanged label lock; bar magnitudes reduced vs pre-Phase-1)
- Aquarius edge dominant: 14/14
- Leo drama dominant: 13/14 (new preset evidence)
- Aries production drama: 8/14 (was 11/14 pre-Phase-1)
- stage1 vs production dominant differs: Aries 9/14, Leo 12/14, Aquarius 14/14
