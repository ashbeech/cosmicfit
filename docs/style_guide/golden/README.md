# Golden Ideal Style Guides

This directory holds the hand-authored **ideal Style Guides** required by SG-0 (Phase 0c of the Style Guide Quality Overhaul). They define the target **genre**: an instructional, formula-driven stylist's manual written by a second-person coach, never flattering description. Everything downstream is anchored here:

- `docs/style_guide/style_standard.md` (Phase 0a rubric) must be **derived from these guides**, not from current engine output.
- `SECTION_EXAMPLES` in `tools/backfill_narratives.py` (Phase 3e) must be replaced with excerpts **from these guides**.
- `docs/style_guide/golden/profile_expectations.json` (SG-1) must assert the profile dimensions and `coreFormula` strings **recorded in each guide's metadata block**.
- SG-4 golden sign-off and regression acceptance score composed engine output **against these guides**.

## Non-circularity rule (binding)

**Slate is the reference chart** (Maria, birth 1989-04-28 04:30 Athens, cluster `venus_taurus__moon_capricorn__earth_dominant`; natal export in `cosmicfit_slate_natal_2026-06-29_to_2026-07-12_14d.md`). Slate's own cluster is **excluded from self-scoring** in all golden review and regression-diff acceptance. The standard is proven by the other 11 guides, never by grading Maria against Maria. This rule must also appear in the header of `style_standard.md`.

## The set (12 guides)

Every guide file begins with an HTML-comment metadata block (internal reference, invisible when rendered, **not** user-facing copy) recording its chart, profile dimensions, coreFormula, and accessory plan. The body below the comment is a 1:1 mock of the app's final composed user-facing output.

| Slot | Archetype | File | Venus | Moon | Element | Sect | Stellium | Register | Metals | Finish | Temp | coreFormula |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Slate (ref) | `slate_ideal.md` | Taurus | Capricorn | Earth | Night | Capricorn | quietLuxury | dualRegister | muted | warm | structure + softness + a touch of quiet depth |
| 2 | Ember | `ember_ideal.md` | Aries | Sagittarius | Fire | Day | none | boldExpression | warmDominant | polished | warm | clean impact + fast movement + one hot accent |
| 3 | Zephyr | `zephyr_ideal.md` | Gemini | Aquarius | Air | Day | none | versatileAdaptive | mixedFree | mixed | cool | crisp separation + mobile layers + one clever contrast |
| 4 | Cove | `cove_ideal.md` | Cancer | Scorpio | Water | Night | none | quietLuxury (protective) | coolDominant | muted | cool | soft shelter + quiet undercurrent + one sentimental keepsake |
| 5 | Blaze | `blaze_ideal.md` | Sagittarius | Leo | Fire | Day | fire (Sag) | boldExpression | mixedFree | polished | warm | expansive colour + athletic space + one theatrical finish |
| 6 | Flint | `flint_ideal.md` | Virgo | Virgo | Earth | Day | none | versatileAdaptive (precision) | coolDominant | muted | **neutral** | precise fit + honest fabric + one meticulous detail |
| 7 | Frost | `frost_ideal.md` | Aquarius | Libra | Air | Night | none | versatileAdaptive (sleek) | coolDominant | polished | cool | clean geometry + cool composure + one polished signal |
| 8 | Mist | `mist_ideal.md` | Pisces | Pisces | Water | Night | Pisces | quietLuxury (ethereal) | coolDominant | muted | cool | weightless layers + blurred edges + one pearl of light |
| 9 | Moss | `moss_ideal.md` | Capricorn | Taurus | Earth | Day | none | quietLuxury (heritage) | warmDominant | muted (aged) | warm | enduring structure + sensory comfort + one living texture |
| 10 | Cinder | `cinder_ideal.md` | Leo | Aries | Fire | Night | none | boldExpression (nocturnal) | dualRegister | polished | warm (dark) | dark drama + sharp edges + one molten flash |
| 11 | Breeze | `breeze_ideal.md` | Libra | Gemini | Air | Day | none | versatileAdaptive (balanced) | mixedFree (fine scale) | mixed | cool | balanced proportions + light movement + one refined touch |
| 12 | Tide | `tide_ideal.md` | Scorpio | Cancer | Water | Night | none | quietLuxury (deep) | warmDominant | muted (aged) | warm-deep | close drape + hidden depth + one warm point of light |
| 13 | Ripple | `ripple_ideal.md` | Taurus (reused) | Pisces (reused) | Water | Night | none | quietLuxury (melted) | warmDominant | muted | warm | soft structure + blurred edges + a touch of quiet depth |
| 14 | Hearth | `hearth_ideal.md` | Leo (reused) | Capricorn (reused) | Earth | Day | none | quietLuxury (warm regal) | warmDominant | mixed (muted + one polished flash) | warm | quiet grandeur + softness + one molten flash |
| 15 | Loom | `loom_ideal.md` | Pisces (reused) | Virgo (reused) | Air (slimmest margin) | Day | none | versatileAdaptive (TIE-BREAK, confidence=LOW) | mixedFree (fine) | mixed | cool | weightless layers + honest fabric + one pearl of light |
| 16 | Wren | `wren_ideal.md` | Cancer (reused) | Gemini (reused) | Fire | Day | Aries (fine-only) | versatileAdaptive (TIE-BREAK, confidence=LOW) | coolDominant (small) | muted | cool | soft shelter + light movement + one sentimental keepsake |

## Mechanism anchors (guides 13-16 — added 2026-07-06)

The core 12 define the genre and anchor every sign's vocabulary once. Guides 13-16 are **mechanism anchors**: each exists to prove a specific piece of the machine, and each deliberately **reuses** already-anchored Venus/Moon signs — that reuse is the point, not a coverage error. The set is capped at 16; further guides add review cost without meaningful gain (few-shot prompts, the rubric, and scale quality are all carried by the contract and validator, not by example count).

- **Ripple + Hearth: recombination tests for the `formula_vocabulary` tables (SG-2).** The tables' promise is compositionality — 12x12 sign combinations reading naturally, of which the core 12 anchor only 12. Ripple recombines Slate's Venus-Taurus row with Mist's Moon-Pisces row; Hearth recombines Cinder's Venus-Leo row with Slate's Moon-Capricorn row. **Composition findings (binding on SG-2's table design):** Moon rows and Venus accent slots compose **verbatim** across registers; the Venus structure slot needs a small **per-register variant set** (Taurus "structure" -> water-register "soft structure"; Leo "dark drama" -> quietLuxury-register "quiet grandeur"). The vocabulary schema must therefore hold 2-3 register-inflected forms per Venus structure entry, not a single string.
- **Loom: the borderline/neutral anchor.** The only guide for a genuinely ambiguous chart (air dominant by the slimmest margin, dreamy Venus vs exacting Moon). It defines what "the engine hedges gracefully" reads like: both-and framing presented as a strength ("two hands sign a treaty"), all neutral lanes exercised (balanced orientation, versatileAdaptive tie-break, mixedFree fine-scale metals, mixed finish, confidence=LOW), and no strong lane assertion a conflicting fine signal could contradict. It is also a **pure-verbatim composition test**: all three formula slots reuse existing rows with zero inflection.
- **Wren: the overlay stress-case anchor.** Fine signals (Aries stellium, fire dominance) fight the coarse Venus/Moon lane. The guide demonstrates the conflict policy's required outcome: prose stays **true to the coarse lane** (soft, quick, sheltering); the chart's heat surfaces only through fabric **function** (breathability, stretch, one-motion layers) and pace framing — never through "bold/statement/fierce" vocabulary, so the excluded-keyword check passes. Overlays for such charts resolve to suppress/neutral. Also a second pure-verbatim composition test.

Validator note: Loom and Wren carry `confidence=LOW` profiles by design — they are the regression anchors for tie-break and suppress/neutral behaviour, and must be included in the SG-3 representative-cluster selection and SG-4 conflict-policy tests.

## Coverage properties (deliberate)

- **Within the core 12, all 12 Venus signs appear exactly once and all 12 Moon signs appear exactly once.** Any Venus-sign or Moon-sign lane in the dataset has one primary golden anchor; guides 13-16 add recombined second appearances by design (see Mechanism anchors above).
- **3 guides per dominant element** (earth: Slate, Flint, Moss; fire: Ember, Blaze, Cinder; air: Zephyr, Frost, Breeze; water: Cove, Mist, Tide). Same-element guides deliberately occupy **different registers**, proving element alone does not determine voice.
- **6 day / 6 night sect. 3 stellium cases** (Capricorn, fire, Pisces), 9 without.
- **All temperature lanes covered**, including the neutral lane (Flint), which SG-2's ranked tables must serve.
- **All four metal strategies covered, with contrasts that prove chart-conditionality:**
  - dualRegister appears twice with opposite finishes (Slate muted vs Cinder polished).
  - Polished chrome / high-shine silver is **excluded** for Slate but **embraced** for Frost. Exclusions are chart-conditional, never universal.
  - warmDominant appears polished (Ember) and aged/patinated (Tide, Moss).
- **Accessory category plans differ per chart** (see metadata blocks): hats only for Slate and Moss; scarves omitted for Ember, Frost, Cinder; watches only for Flint; sentimental jewellery only for Cove; statement jewellery for Cinder. A regen where all archetypes receive the same bags/scarves/belts/hats structure fails validation (SG-4 accessory-diversity assertion).
- **Traps are chart-specific**: head-to-toe-black (Slate), flat monochrome boredom (Zephyr), formless black (Tide), fade trap (Ember), dark monochrome (Blaze), swaddling (Cove), beige-out (Flint), total ice (Frost), dissolution (Mist), all-earth sink (Moss), costume drift (Cinder), prettiness-without-anchor (Breeze).

## Structural contract every guide satisfies

Each guide follows the same information architecture (this is what `style_standard.md` formalises):

1. **Blueprint**: sensory/instinct compass, the named coreFormula stated in plain `X + Y + Z` words with a concrete "picture this" outfit, a build-tempo statement, and a named ultimate-compass test.
2. **Palette**: one-line temperature statement; >=6 named foundation colours tagged by role; singular accent rule; a relief colour; a pass-over list; a named trap with its fix.
3. **Textures**: The Good (7 bolded ranked fibres, each with a use-case), The Bad (with physical tells), The Sweet Spot, plus a purchase test.
4. **Occasions**: work / intimate / daily, each shifting which formula element leads; an explicit formula-constancy line; a "pharmacy line" equivalent (dailiness does not suspend the standard).
5. **Hardware**: The Metals (strategy + a named excluded finish), The Stones (role-driven), Tip (the pick-it-up weight test, reworded per voice).
6. **Code**: Lean Into / Avoid / Consider, always including cost-per-wear and the 5-10-year longevity test plus one chart-specific physical evaluation.
7. **Accessory**: opens by tying accessories to the formula's final term; names the "one or two strong pieces per look" principle; 3 chart-conditional categories with material/finish/shape specs; a named exit test.
8. **Pattern**: tailored-vs-fluid split; pass-over list; a named distance/blur/legibility test tuned to the chart.
9. **Closing**: italic map-of-instincts line ending with the coreFormula.

**Hard rules**: no em dashes, en dashes, or `--` in prose (the `---` lines are markdown horizontal rules, document formatting only, and do not ship as user copy); no banned tics ("unbothered", "signs the cheques", "devastatingly chic", "command the room", "quiet expensive authority", "effortlessly elegant"); British English; the spelling is **matt** (not matte); concrete nouns over adjective filler throughout.

## Decisions made during authoring (feed into SG-0/SG-1)

1. **Tide is slot 12, not slot 4.** Tide's palette is explicitly warm-deep, which only reconciles with a water Venus through the Scorpio-Venus "warm-deep despite water" nuance in the SG-1 temperature table. Cove was authored as the slot-4 cool-water guide. Tide is therefore the canonical test vector for the sign-level temperature nuance.
2. **Recommended numeric floors for `style_standard.md`** (validated against all 12): >=6 named foundation/neutral colours in Palette; 7 ranked fibres in Textures Good; >=3 accessory categories; >=1 named test or trap per section (all guides exceed this).
3. **The formula must appear at minimum in**: Blueprint (verbatim `X + Y + Z`), Occasions (intro or constancy line), Code (first Lean Into), Accessory (opening), and the closing line. All 12 comply; the validator (`p4-formula`) can require exactly this.
4. **Metadata blocks are the seed of `profile_expectations.json`.** When SG-1 builds `ChartAestheticProfile`, its derivation must reproduce each guide's recorded dimensions from the chart facts on the same line. Where a derivation rule and a guide disagree, the guide wins and the rule is amended (the guides are the test vectors).
5. **Slate's guide title is the archetype name (Slate), not the user name (Maria)**, matching all other guides; the engine substitutes the real display name at composition time.
