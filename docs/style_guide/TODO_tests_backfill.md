# TODO: backfill bare `tests` labels in the narrative cache

> **Status:** OPEN — tracked follow-up to the SG-4 preview cutover (2026-07-13).
> **Owner:** Ash
> **Blocking submission?** No — a renderer stopgap ships clean without these.

## Problem

The SG-4 narrative cache (`data/style_guide/blueprint_narrative_cache.json`,
activated over v1 on 2026-07-13) populates the user-facing **Tests** subsection
for the first time (v1 shipped 0 test entries). The "Tests" section itself is
stipulated by `style_standard.md` — *named sensory self-checks that teach the
reader to trust physical instinct* ("the breath test", "the ten-foot rule").

But **~41% of test entries render as bare named labels with no explanation** —
e.g. a lone bullet reading `• the host test`. These are meaningless to the
user. The intended form pairs the name with its meaning, which the cache does
elsewhere, e.g.:

- `pick it up: looks lie, weight doesn't (the pick-it-up weight test)`
- `the reflection rule: hold the hardware under a direct light source; if it does not produce a sharp, blinding reflection, it is too dull`

### Measured incidence (2026-07-13, active cache)

- 8,640 `tests` entries total; **3,628 bare** (`the … test`, no `:`/`(`) across **41 distinct labels**.
- Each `tests` array holds exactly one entry, so a bare entry means the whole subsection disappears (no partial lists).
- Concentration by section: `style_core` 526/576 clusters (91%), `accessory_1/2/3` 526 each, `textures_good/bad/sweet_spot` 508 each. Hardware/occasions tests are mostly explained and unaffected.
- Some bare labels reuse internal archetype personas (`the ripple test`, `the one-ember test` — Ripple/Ember are golden codenames), i.e. a residual of the same `(Wren)`-leak class the SG-4 gate cleaned; the gate stripped parenthetical attributions but left persona-derived names.

### Why it passed the SG-4 gate

The concreteness floor counts "a named test is present" as satisfying the
requirement; it never checks that an explanatory clause is attached. Add that
check when backfilling.

## Current mitigation (shipped)

Renderer guard in
`Cosmic Fit/UI/ViewControllers/StyleGuideDetailViewController.swift`
(`isBareNamedTest`, applied in `outputContractTrailingSections()`): bare
`the … test` entries with no `:`/`(…)` are suppressed. The `!shown.isEmpty`
check drops the whole subsection when nothing survives, so no empty "Tests"
header renders. Net: the ~40% bare entries simply don't show a Tests subsection
(most visibly, the style-core one for ~91% of charts) until this backfill lands.

## Second issue: Title-Cased inline named tests (register defect, NOT hidden)

Separate from the bare bullets. In section body prose the cache uses the
golden's "Rely on the X test as your ultimate compass. [definition]"
construction — **6,735** lowercase, explained, and correct. But **75**
occurrences (58 distinct names — Patina, Anchor, Drop Weight, Exhalation,
Cheek Temperature, Subtraction Mirror, …) are **Title-Cased** — "Rely on the
Patina Test", "Apply the Anchor Test". The golden always writes these
lowercase ("the seam test", "the host test"), so the capitals misread as a
proper-noun / branded framework the user is expected to recognise, producing a
"what is this?!" jar even though the explanation follows in the next sentence.

- **Do NOT hide these** — the explanation is present and on-spec; suppressing would delete good content.
- **Fix = lowercase normalisation.** All 75 are mid-sentence (`the Xxx Test`, never sentence-initial), so lowercasing `the [Words] Test` → `the [words] test` is safe.
- Apply to the canonical `blueprint_narrative_cache_sg4.json`, then re-run the §7 cutover copy so the device (base) and Inspector (`_sg4.json`) stay aligned. Add a gate check forbidding Title-Cased `the … Test` in prose.

## Proper fix (this TODO)

1. Enumerate the 41 bare labels and author the paired `name: meaning` form for each (a small lexicon), OR regenerate the affected `tests` slots to always emit the explained form.
2. Rename/replace persona-derived test names (`the ripple test`, `the one-ember test`, `the host test`, …) — they should be sensory, not codename-derived.
3. Add a gate check: a `tests` entry must contain an explanatory clause (`:` or `(…)`), not just a named label. Wire into `sg_validation.py` / `StyleGuideCoherenceValidator`.
4. Regenerate the cache, re-run the SG suite, and **remove the `isBareNamedTest` renderer guard** (it's a stopgap, not the contract).
