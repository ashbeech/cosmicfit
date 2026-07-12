# SG-4 Review Pack — Report (2026-07-09)

> Companion to `docs/style_guide/gates/SG-4_GATE.md`. Everything here is
> reproducible from the repo; commands are in the gate doc §Verification.

## 1. What this pack covers

SG-4 completed the two halves the handoff left open:

1. **Machine validation was extended from the cache to the composed app
   output.** A Swift `StyleGuideCoherenceValidator` now loads the same
   `style_guide_rules.json` as the Python write gate, with a 126-case parity
   corpus proving the two layers agree; composed `CosmicBlueprint` output
   (overlays applied, placeholders rendered) is contract-checked end-to-end
   for the 16 golden charts under xcodebuild.
2. **The composed-output checks found real defects the cache-level audits
   could not see** (they live in the deterministic arrays, the dataset, and
   the render seam, not the gated prose). Most were repaired in this cycle;
   two remain open for the gate reviewer (§4).

## 2. Content fixes applied to the SG-4 cache this cycle

All applied in-cache (no regeneration), each re-gated after edit:

| Fix | Scope |
|---|---|
| `finalizing` → `finalising` (missed Americanism) | 1 section |
| "a handful of strong, functional items" → "one or two strong, functional items" (restraint-principle conformance) | 1 section |
| Stripped `"(Wren)"`-style archetype-codename attributions from user-facing `tests` arrays (leaked provenance notes from `test_trap_library.json`) | 1,728 array entries + 13 library entries |
| Hardware trap fix "stay strictly in polished **warm** metal…" neutralised (was stamped on all 90 boldExpression clusters incl. 54 coolDominant) | 270 trap entries + 1 library entry |
| Palette trap fix "break it with a **warm point of light**, hammered gold cuff…" neutralised on cool charts | 7 trap entries + 1 library entry |
| Lane-contradicting palette trap fixes (e.g. "break it up with a camel layer, a deep wine scarf, or a rich cognac belt" on cool charts) rebuilt **per chart from its own ranked colour table**, role-matched (7 templates: 263 trap entries). Library templates rewritten colour-neutral so regeneration cannot recreate the class | 263 trap entries + 7 library entries |

Dataset (feeds the deterministic Code section and overlays; user-facing):

| Fix | Scope |
|---|---|
| Banned-tic rewrites (`of someone who`, `your daily rotation`, `command the room`, `naturally gravitate`, `walk into a room`, `unbothered`, `effortlessly elegant`, `your professional wardrobe`) — minimal rewording, meaning kept | 20 strings in `astrological_style_dataset.json` |

Gate/audit hardening in the same change (ground rule 2):

- `american_spellings` moved into `style_guide_rules.json` and extended with
  the SG-3 blind-spot list (`rigor`, `artifact(s)`, `mold(s)`, `pants`,
  `curb(s)`, `-ize` verbs); `allowed_phrases`: `curb chain` (jewellery),
  `track pants` (frost ideal uses it — the guides win).
- `stamped_phrases` is now contraction-insensitive (`doesn't` == `does not`)
  and pattern-based (`Weight and X do not` variants blocked).
- New audit categories: `L_archetype_attribution`, `L_temp_contradiction`,
  `B_excluded_finish_unresolvable`, `E_accessory_principle_unmatched`,
  `G_stamped_phrase`.
- New write-gate error `excluded_finish_unresolvable` (see §4.1).
- `concrete_lexicon` moved into the rules file (shared with Swift).

## 3. Engine/composer changes (Swift)

| Change | Why |
|---|---|
| `StyleGuideCoherenceValidator.swift` (new) | SG-4 deliverable 2: Swift half of the two-layer validator; loads `style_guide_rules.json` + `ranked_domain_tables.json` from the bundle (Resources symlinks added) |
| `sg4_parity_fixture.json` + `tools/sg4_parity_fixture.py` (new) | 126 gate cases (46 crafted + 80 sampled from the SG-4 cache) with Python verdicts baked in; `SG4ValidatorParityTests` replays them in Swift — all pass |
| `BlueprintComposer.composeCore(...)` seam + `ChartInputAdapter.adapt(analysis:)` | Lets tests compose the 15 synthetic golden charts (signs only, no birth time) through the production pipeline |
| `BlueprintComposer.padColourContext` | Render-completeness backstop: missing 3rd/4th colour placeholder slots fill from the user's own palette (support band, anchors) instead of fallback filler |
| `BlueprintComposer.completeCodeContract` | The deterministic dataset Code directives predate the standard: first Lean Into now states the coreFormula, and cost-per-wear + five-to-ten-years directives are supplied when absent. **Active only on v2 cache clusters** (coreFormula present) so shipped v1 behaviour is unchanged until cutover |
| `NarrativeTemplateRenderer.fallbackText(for:)` | Graceful fallback is token-family-aware ("a complementary metal/shade/finish…" instead of the generic "choice"). Fallback policy: profile-derivable slots (colours, finishes, patterns, weaves) must never fall back; per-user data-depth slots (a 2nd structural metal / stone the chart genuinely does not resolve) may use the designed family wording |
| `PaletteLibrary.deduplicatedAccentLabels` hex guard | Found live by the composed checks: a chart-derived accent slot carried a raw hex as its display name, rendering "apply deep mauve or **#8a4484**" into cinder's palette prose (and the same hex as a swatch label). Labels that start with "#" are now replaced with the nearest wardrobe colour token; a raw-hex hygiene check pins the class in `SG4ComposedContractTests` |

## 4. Open findings for the gate reviewer

### 4.1 `{excluded_finish}` on profiles that resolve no excluded finish — RESOLVED

169 `hardware_metals` sections (mixedFree / non-muted dualRegister charts)
referenced a placeholder those profiles can never fill, rendering "a
complementary finish" filler into composed prose. Owner approved the spend on
2026-07-09; the targeted resume-mode regeneration completed the same day:
169/169 applied, 0 quarantined, 342 API calls. The write gate blocks the
class permanently (`excluded_finish_unresolvable` + profile-aware prompt
note), the test pin was removed, and the post-regen audit shows zero
findings in this class. Full detail: SG-4_GATE.md §4.1.

### 4.2 ColourEngineV4 vs profile temperature — 8 of 15 synthetic goldens disagree

On sign-only synthetic golden charts: ember/blaze/cinder (warm profile → V4
neutral), breeze/loom (cool → neutral), ripple (warm → cool), wren (cool →
warm), flint (neutral → warm). Slate (the one real chart) agrees on all three
sides. The 2e Layer A floor is deliberately deep-only ("non-deep cool
families reached by a warm Venus are out of scope"), and the V4 side of the
golden set had never been executed before this cycle. Consequence: for such
users the palette prose (cluster-keyed, asserts the profile temperature) sits
around swatches from a different-temperature V4 family — the swatch-vs-text
gap 2e 4a exists to close. Deviations are **pinned** in
`SG4TemperatureCoherenceTests.pinnedV4TemperatureDeviations` (drift fails the
suite). Engine-side reconciliation is an owner decision (extending the Venus
floor beyond deep families risks the V4 calibration anchors).

Caveat: the synthetic fixtures carry signs but no degrees; a real chart for
these archetypes could resolve differently. Slate is the only real-chart
evidence.

## 5. 6-gram stamping scan at 576 scale (style_standard §7c, 15% threshold)

20 six-grams sit above ~15% cluster coverage and appear in no golden guide.
Classification:

| Class | Examples | Judgment proposed |
|---|---|---|
| Restraint-principle scaffolding | "yourself to one or two strong" (316), "restrict yourself to one or two" (164) | Contract-mandated recurrence (SG-3 gate residual, unchanged) |
| Ranked-table use-case repeats | "dresses that trace the body with" (139), "unstructured protective coats that stay soft" (129), "trousers that drape cleanly and resist" (87) | Expected — deterministic rankedItems use-case strings (handoff §4 note) |
| Pass-over list phrasing (register-conditional) | "mustard rust and warm olive green" (103) | Same class as the accepted boldExpression pass-over residual |
| **Candidate tics (reviewer call)** | "between your thumb and index finger" (112), "leave it on the rail you" (103) | Natural instructional phrasing at high coverage; banning would force wide regeneration. Recommend: accept now, add to the §7c watch list for the next harvest |

## 6. Deep-audit residuals (post-fix, `tools/sg3_audit.py`)

| Finding | Count | Disposition |
|---|---|---|
| `B_excluded_finish_unresolvable` | 169 | §4.1 — regen queued |
| `B_groupB_no_placeholder` | 2 | Tips exempt (SG-3 accepted, informational) |
| `C_phrase_stamped` (restraint principle) | 4 n-grams | Contract-mandated (SG-3 accepted) |
| `C_phrase_stamped_by_register` (boldExpression pass-over) | 1 | SG-3 accepted |
| `E_accessory_principle_unmatched` | 1 | `venus_leo__moon_cancer__earth_dominant` carries the principle in words the pattern misses ("exactly one molten flash" + "a single polished hardware detail") — verified by eye |
| `H_too_long` | 25 | `style_core` 221–234w, under the 280 hard gate (SG-3 accepted class) |
| `G_american_spelling`, `G_stamped_phrase`, `L_archetype_attribution`, `L_temp_contradiction`, `A_*`, `D_*`, `E_*` (others), `I_*`, `J_*`, `K_*` | 0 | Clean after this cycle's fixes |

The frozen SG-3 gate artifact (`blueprint_narrative_cache_sg3.json`) still
carries the attribution/temperature-contradiction classes (576 / 2 findings)
— it is frozen as gate evidence and is not shipped; the classes are fixed at
the source (library + dataset) and in the SG-4 artifact.

## 7. Spot-reads (new-384 clusters)

11 renders in this directory (`render_*.md`), spread across registers,
temperatures and elements (8 from the new 384 + 3 warm-lane additions).
Read notes:

- Coach genre holds: imperative, chart-specific compasses (speed/momentum on
  fire, weight/drag on earth, separation on air), named tests and traps,
  role-tagged palettes with pass-over lists, formula threaded at the fixed
  positions. No dashes, no observer-voice tics, no season words observed.
- The composed-output defects that WERE visible in these renders (archetype
  attributions in test lines, warm-metal fix on cool charts, foreign-colour
  trap fixes) are the classes fixed in §2 — the renders were regenerated
  after the fixes.
- Residual roughness (reviewer judgment): occasional finish adjectives
  colliding with placeholder values ("high-shine matt silver" when prose
  wraps a matt-named metal in a gloss adjective) — low frequency, cosmetic;
  recommend watch-list, not regen.

## 8. Note on the review renderer

`render_cluster.py` fills placeholders with representative ranked-table
values, NOT the production V4 palette. The composed-output truth for per-user
fidelity is now the Swift `SG4ComposedContractTests` suite, which runs the
real `BlueprintComposer` + `NarrativeTemplateRenderer` path.
