# The Style Standard (machine-checkable element contract)

> **Status:** Current (SG-0 deliverable, authored 2026-07-06)
> **Derived from:** the 16 hand-authored golden ideal guides in `docs/style_guide/golden/` — NOT from current engine output. Where this standard and a golden guide disagree, **the golden guide wins** and this standard is amended.
> **Consumed by:** SG-1 (profile derivation), SG-2 (ranked tables), SG-3 (generation prompts, `SECTION_EXAMPLES`, write gate), SG-4 (`StyleGuideCoherenceValidator`, golden sign-off, regression acceptance).
> **Evidence tooling:** `tools/check_golden_guides.py` (rubric conformance over the golden set), `tools/harvest_narrative_tics.py` (tic evidence from the shipped cache, output in `tic_harvest.json` / `tic_harvest.md`).

## Non-circularity rule (binding, inherited by SG-4)

**Slate is the reference chart** (Maria, birth 1989-04-28 04:30 Athens, cluster `venus_taurus__moon_capricorn__earth_dominant`). Slate's own cluster is **excluded from self-scoring** in all golden review and regression-diff acceptance. The standard is proven by the non-reference guides, never by grading Maria against Maria. Mechanical hygiene checks still run on Slate's cluster like any other; its result simply does not count toward "the standard is met".

---

## 1. The genre

Every Style Guide is an **instructional, formula-driven stylist's manual** written by a second-person coach who teaches the user to dress and to trust their own instincts. It is never flattering description of the user's taste, never observer-voice social commentary ("you walk into a room..."), and never adjective soup.

The manual's spine is the chart's named **coreFormula** (`X + Y + Z` form, e.g. `structure + softness + a touch of quiet depth`), stated plainly and threaded through the whole document (fixed positions in §4).

## 2. Voice spec

- **Instructional second-person coach.** The guide gives directives, tests, and traps: "Look for...", "Avoid...", "Rely on the breath test...". It teaches the reader to trust their own physical instincts ("Trust this physical instinct as your ultimate compass. Looks lie. Weight doesn't.").
- **Concrete over abstract.** One strong image per paragraph; named garments, fibres, colours, metals, and stones do the work, not evaluative adjectives.
- **Chart-specific throughout.** A fire/bold chart's formula, palette, metals, accessories, patterns, and named tests must read completely different from an earth/quiet chart's while passing this same structural contract. Sensory compasses differ per chart (Slate: touch/weight; Ember: speed/hesitation; Mist: breath/float) — the *presence* of a compass is universal, its *modality* is not.
- **British English.** The spelling is **matt**, never matte. No American spellings (colour, jewellery, grey, ...).
- **No astrological jargon in user-facing prose.** No sign, planet, house, sect, or stellium names in the composed guide body.
- **No stock phrases** — see the banned-tic list (§7) and the repetition watch list (§8).

## 3. Punctuation (hard never)

No em dashes (`—`), en dashes (`–`), or double hyphens used as dashes (`--`) anywhere in user-facing copy. Replace with:

- a **comma** when the dash joins a continuation or appositive in the same sentence;
- a **full stop** when the dash would start an independent clause.

Semicolons are not the default dash substitute (comma or full stop only; a semicolon is acceptable only where two clauses are genuinely coordinated and it is not standing in for a dash). Markdown `---` horizontal-rule lines are document formatting, not prose, and are exempt. Detection: reuse `_EM_DASH_RE` from `tools/content_audit_checks.py`.

## 4. Every-section baseline (applies to all 8 sections)

1. A `sectionIntro` line (the section opens by framing what this section is for, in the guide's voice).
2. An explicit relationship to the named `coreFormula` (the formula, or the specific formula slot the section serves).
3. At least **1 named, actionable test or trap** (see per-section table for the canonical one).
4. Instructional second-person coach voice (§2).
5. Zero banned tics (§7), zero dash violations (§3).
6. Meets the concreteness floors and stays under the filler cap (§6).
7. The guide as a whole carries a top-level italic `closing` line (map-of-instincts frame) ending with the coreFormula.

## 5. Per-section element contract

The contract below is checked per **composed section** (the 8 the user sees) on the **combined rendered text** of the aggregated cache keys (§10). "Named" means the element is identifiable verbatim in the text, not implied.

| # | Section | Required elements (all checkable) | Canonical named test/trap |
|---|---------|-----------------------------------|---------------------------|
| 1 | **Blueprint** | intro; a chart-appropriate **sensory/instinct compass** (touch, speed, breath, precision... per chart); the **coreFormula stated verbatim** in `X + Y + Z` form; a concrete "picture this" outfit illustrating the formula; a **build-tempo statement** (slow curation, fast deployment, mood-led drift... per chart); a named ultimate-compass test | the chart's compass test ("trust your gut and walk away", "the hesitation test", "the breath test") |
| 2 | **Palette** | one-line **temperature statement** that must agree with the profile temperature (nuance mapping: `warm-deep` compares as `warm`; `neutral` is a valid lane, not an error); **>= 6 named foundation colours tagged by role** (base, bridge, white-replacement, structural dark... roles are chart-specific); a **singular, deliberate accent rule**; a named **relief colour** with its when-to-use; a **pass-over list**; a **named trap with its fix** | chart-specific palette trap (head-to-toe black -> break with camel/wine/cognac; the fade trap -> rescue with a saturated accent; dissolution -> restore one line) |
| 3 | **Textures** | "The Good": **exactly 7 bolded ranked fibres, each with a one-line use-case**; "The Bad": rejected materials each with its **physical tell**; "The Sweet Spot": the chart's signature texture pairing; a named **purchase test** | touch test / friction test / breath test ("if it feels squeaky or resists, leave it") |
| 4 | **Occasions** | work + intimate + daily **all present**; each states **which formula element leads** in that setting; an explicit **formula-constancy line** restating the coreFormula verbatim; a **"pharmacy line" equivalent** (a named mundane errand that does not suspend the standard, chart-specific: pharmacy, bakery, petrol station, dog walk, post office...) | the pharmacy line itself (dailiness does not suspend the standard) |
| 5 | **Hardware** | "The Metals": the chart's **metal strategy** stated in prose and consistent with its profile (`personal/structural` split **only** for dualRegister charts; single-register framing for warm/coolDominant; freedom for mixedFree); a **named excluded finish** (or a named embraced finish where the profile excludes nothing); **>= 2 named metals**; "The Stones": a role-driven stone rule (density, clarity, light-holding... per chart) with **>= 2 named stones** (an explicit restraint framing like Flint's is valid but still names its stones); "Tip": the **pick-it-up weight test**, reworded in the chart's voice | pick-it-up weight test ("Looks lie. Weight doesn't.") |
| 6 | **Code** | Lean Into / Avoid / Consider subsections with **>= 4 / >= 3 / >= 3 directives** respectively; the **first Lean Into states the coreFormula**; a **cost-per-wear** directive; the **five-to-ten-years longevity test**; >= 1 chart-specific physical evaluation (velocity test, movement check, weight check...) | cost-per-wear test AND "would I still wear this in five to ten years" |
| 7 | **Accessory** | opens by tying accessories to the **formula's final term** (the accent/depth slot) with the other slots referenced; the **"one or two strong pieces per look" principle named explicitly**; **>= 3 chart-conditional categories**, each with material/finish/shape specs, driven by the `accessoryCategoryPlan` (include/merge/omit only; omitted categories are never named); a named **exit test** | spotlight test / float test / "remove the earring doing too much" |
| 8 | **Pattern** | the **tailored-vs-fluid split** (what tailored pieces take pattern from vs what fluid pieces take); a **pattern-contrast rule that agrees with the profile register** (low-contrast tonal for quietLuxury; high-contrast graphic for boldExpression; the register decides, never a universal default); a **pass-over list**; a named **distance/blur/legibility test** tuned to the chart | step-back-and-soften-focus / ten-foot rule / underwater test |
| — | **Closing** | one italic map-of-instincts line, ending with the coreFormula verbatim | (not applicable) |

**Rule amendments made while validating against the golden set** (the guides won, per the derivation rule):

- The master plan's Blueprint element "tactile-compass framing (hands first, colour and silhouette follow)" is Slate-specific. Generalised to *chart-appropriate sensory/instinct compass* (Ember's is hesitation/speed, Mist's is breath). Same for Palette role names (the "warm / warm-cool bridge / cream-as-white / earthy-green" roles are Slate's; the checkable rule is *>= 6 named colours, each tagged with a role*).
- The master plan's Pattern element "low-contrast/tonal rule" is Slate-specific. The checkable rule is *contrast lane agrees with the register* (Ember/Blaze/Cinder legitimately demand high contrast).
- The master plan's Hardware "personal/structural metal split" is required **only** for `dualRegister` charts (Slate, Cinder). Imposing it on warmDominant/coolDominant/mixedFree charts would recreate the universal-hardcoding defect this overhaul exists to kill.
- The Accessory opening ties to the formula's **final term** (per the golden README structural contract); most guides restate all three slots and that remains the recommended form, but the checkable floor is final-term-plus-reference.

## 6. Numeric floors and caps

**Adopted verbatim from `docs/style_guide/golden/README.md`, not re-derived.** The numeric floors are the README's "Recommended numeric floors" (decision #2) and formula-placement rule (decision #3); the spelling row is a README **Hard rule**, not a numeric-floor decision:

| Rule | Floor | README source |
|------|-------|---------------|
| Palette named foundation/neutral colours | **>= 6** | decision #2 |
| Textures "The Good" ranked fibres, each bolded with a use-case | **exactly 7** | decision #2 |
| Accessory categories | **>= 3** | decision #2 |
| Named test or trap per section | **>= 1** | decision #2 |
| coreFormula fixed-position occurrences | **>= 5**: Blueprint (verbatim `X + Y + Z`), Occasions constancy line, Code's first Lean Into, the Accessory opening, and the closing line | decision #3 |
| Spelling | **matt**, never matte | Hard rules |

**Additional floors measured across all 16 golden guides during SG-0 rubric validation (provenance: `tools/check_golden_guides.py` + section measurements, 2026-07-06):**

| Rule | Floor / cap |
|------|-------------|
| Hardware named metals | >= 2 |
| Hardware named stones | >= 2 |
| Code directives | Lean Into >= 4, Avoid >= 3, Consider >= 3 |
| Adjective-filler cap (per section) | <= 3 occurrences from the filler lexicon |
| "rather than" (per guide) | <= 5 occurrences (golden max 5; cache mean 6.3, max 16) |

**Filler lexicon** (the "substantial/expensive/heavy-class" budget; counted as filler when used evaluatively): `substantial, expensive, luxurious, elevated, effortless, effortlessly, timeless, premium, sumptuous, exquisite`. Physical descriptors used physically (a *heavy* wool coat, a *substantial* buckle in a weight-test context) are the legitimate register of this genre and are not counted; SG-4's implementation must count lexicon words per section and flag, with the cap at 3 per section.

## 7. Banned tics (validator errors)

### 7a. Harvested list (evidence from the shipped 576-cluster cache)

Provenance: `tools/harvest_narrative_tics.py` over `data/style_guide/blueprint_narrative_cache.json` (576 clusters x 16 sections), ranked by distinct-cluster coverage; full tables in `docs/style_guide/tic_harvest.json`. Every phrase below appears in a large share of shipped clusters and in **zero** golden guides. These are the real tics the write gate (SG-3) and validator (SG-4) enforce.

| Banned phrase | Clusters (of 576) | Why banned |
|---|---|---|
| `unbothered` | 318 | flattering-observer voice (folklore tic confirmed real) |
| `walk into a room` / `walks into a room` / `when you walk into` | 290 | room-effect observer voice, wrong genre |
| `your daily rotation` | 270 | formulaic scaffolding |
| `your professional wardrobe` | 204 | formulaic section opener (occasions_work) |
| `is an exercise in` / `an exercise in` | 227 | abstract framing, anti-instructional |
| `an immediate sense of` | 165 | adjective-soup filler |
| `matters just as much` | 143 | stock comparison |
| `the rich scent of` | 139 | sensory cliché stamped across clusters |
| `there is a distinct` | 133 | formulaic opener (style_core) |
| `at the intersection of` | 132 | abstract positioning cliché |
| `dressing for you is` | 126 | formulaic opener |
| `satisfying snap` / `the satisfying snap of` | 121 | stamped sensory cliché (accessory_3) |
| `a substantial watch` | 117 | stamped item cliché |
| `naturally gravitate` | 104 | passive-taste description, wrong genre |
| `your off duty wardrobe` / `off duty dressing` (incl. hyphenated) | 122 | formulaic opener (occasions_daily). "Off-duty" as a plain adjective elsewhere is fine (Cinder uses "your off-duty edge") |
| `talk with your hands` | 90 | personality-reading, wrong genre |
| `the energy of someone` / `of someone who` (style_core) | 86 | observer voice describing the wearer |
| `command the room` | 74 | folklore tic confirmed real; room-effect voice |
| `at a moment's notice` | 78 | stock filler |

### 7b. Folklore floor (retained regardless of frequency)

`unbothered` (confirmed, 318 clusters), `signs the cheques` (confirmed, 3), `command the room` (confirmed, 74), `effortlessly elegant` (confirmed, 5), `devastatingly chic` (0 today, banned as floor), `quiet expensive authority` (0 today, banned as floor).

### 7c. Change control

The banned list is append-mostly. Removing a phrase requires showing a golden guide that uses it (the guides win). SG-3 must re-run the harvest after regeneration; new phrases crossing ~15% cluster coverage that appear in no golden guide are candidate additions.

## 8. Repetition watch list (budgeted, not banned)

These phrases are legitimate instructional language (the golden guides use them) but become tics at cache scale. They carry **per-guide occurrence budgets** derived from golden maxima; SG-3's dedup and SG-4's phrase-repetition check enforce them across each cluster's 16 sections combined:

| Phrase | Golden max per guide | Budget |
|---|---|---|
| `rather than` | 5 | <= 5 |
| `look for` | 4 | <= 4 |
| `feel like` / `feels like` | 3 | <= 4 combined |
| `against the skin` | 2 | <= 2 |
| `relies on` | 2 | <= 2 |
| `heavy lifting` | 1 | <= 1 |
| `when you want` | 1 | <= 2 |
| `sense of` | 1 | <= 2 |
| `leave it on the` (hanger/rail/rack) | 1 | <= 2 |

## 9. Concreteness principle

Quality comes from **enumeration, not evaluation**: named colours (camel, toffee, oxblood), named fibres with use-cases (cashmere for knitwear, full-grain leather for bags), named metals and stones (brushed silver, grey spinel), named garments (bias-cut charmeuse slip, wool felt fedora), named tests (the breath test, the ten-foot rule). The floors in §6 are the checkable proxy; the SG-2 ranked domain tables are the supply of concrete nouns; SG-4's concreteness budget enforces floors + filler cap on every list section.

## 10. Cache-key seam: 16 cache keys -> 8 composed sections (binding for SG-3 and SG-4)

The element contract (§5) is written per **composed section**, but the narrative cache generates and stores **16 keys** (`SECTION_KEYS` in `tools/backfill_narratives.py`). Element-contract checks run on the **combined rendered text** of the aggregated keys, never on individual keys.

| Composed section (rubric) | Cache keys aggregated | Notes |
|---|---|---|
| 1. Blueprint | `style_core` (+ overlay appends) | `style_core` must hold >= 2 paragraphs (SG-3) to meet the contract |
| 2. Palette | `palette_narrative` | |
| 3. Textures | `textures_good`, `textures_bad`, `textures_sweet_spot` | contract checked on combined rendered text |
| 4. Occasions | `occasions_work`, `occasions_intimate`, `occasions_daily` | formula-constancy line typically lands in `occasions_daily` or a summary |
| 5. Hardware | `hardware_metals`, `hardware_stones`, `hardware_tip` | |
| 6. Code | deterministic `CodeSection` + optional `aiFraming` | not in the narrative cache (Swift-generated) |
| 7. Accessory | `accessory_1`, `accessory_2`, `accessory_3` | only 3 slots; `accessoryCategoryPlan` maps categories to slots (SG-3) |
| 8. Pattern | `pattern_narrative`, `pattern_tip` | |

The guide-level elements (coreFormula fixed positions, closing line) are checked on the fully composed `CosmicBlueprint` text after overlay append and placeholder render (SG-4 Phase 4b).

## 11. Rubric validation record (SG-0, 2026-07-06)

`tools/check_golden_guides.py` runs the mechanical subset of this contract (sections present, dashes, spelling, banned tics, formula propagation at the 5 fixed positions, 7 fibres, >= 6 palette colours, >= 2 metals, >= 2 stones, >= 3 accessory-plan includes, test/trap presence heuristic) over all 16 golden guides.

- **Result: 16/16 PASS** (15 non-reference guides prove the standard; Slate passes hygiene but is excluded from scoring per the non-circularity rule).
- Amendments made during validation (guide fixes were mechanical-hygiene or floor compliance; no voice or content re-authoring):
  - `zephyr_ideal.md`: "Matte silk" -> "Matt silk" (hard spelling rule from the golden README itself).
  - `ember_ideal.md`: added 2 ranked fibres (sharp wool twill, stretch cotton sateen) to meet the 7-fibre floor; Accessory opening now references all three formula slots.
  - `slate_ideal.md`: Code's first Lean Into now states the coreFormula (aligns the reference guide with golden README decision #3).
  - Rule narrowed instead of guide amended: the banned tic is the cache's formulaic `your off duty wardrobe` / `off duty dressing`, not the plain adjective "off-duty" (Cinder's "your off-duty edge" is legitimate).
