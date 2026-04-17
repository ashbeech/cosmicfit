# Fixtures Changelog

All changes to shared test fixtures under `docs/fixtures/`.

---

## 2026-04-17 — Palette engine rework (Phase A)

- Regenerated `blueprint_input_user_1.json` and `blueprint_input_user_2.json`
  end-to-end against the new resolver (`docs/palette_engine_rework_spec_v1.md`
  v1.1 §11). `userInfo.birthDate` and `userInfo.birthLocation` preserved
  exactly; every other section re-derived from the production pipeline
  (`BlueprintComposer.compose`).
- `palette.accentColours.length` is now **exactly 4** (was 2 / 3). The
  shape checklist has been updated accordingly.
- Every `BlueprintColour` now carries a `provenance` object (see
  `BlueprintModels.ColourProvenance`). For both fixtures, provenance is
  `.chartDerived` on all 8 anchors — zero cross-pool escalation, zero
  library fallback. This is the §8.3 pass target.
- `palette.coreColours` and `palette.accentColours` are rank-sorted
  ascending by `provenance.contributorRank`; the narrative-exposed
  top-2 accents are therefore the highest-signal accents for each user.
- `palette.narrativeText` uses the same cached templates as before — no
  cache regeneration in Phase A per v1.1 §10. Rendered prose may cite
  different accent names because the rank-sorted top-2 pair now differs
  from the old resolver's weight-ordered first two.
- New `token_supply_diagnostic.txt` appendix captures the §8 pre-req
  gate output (fixtures + 11 synthetic charts).
- Pinned `generationDate` and `generatedAt` to `2026-04-17T00:00:00Z`
  in both fixtures so subsequent `FixtureRegeneration` re-runs produce
  byte-identical output.
- Shape checklist bumped: `accentColours.count == 4` (was `>= 2`);
  `BlueprintColour.provenance` present.

---

## 2026-04-10 — WP2 Initial Creation

- Created `blueprint_input_user_1.json` (Ash example — shape-validation fixture)
- Created `blueprint_input_user_2.json` (Maria example — shape-validation fixture)
- Created `blueprint_expected_shape_checklist.md`
- Created `dataset_schema_checklist.md`
- Created this `CHANGELOG.md`

**Notes on synthetic/placeholder values:**
- Colour hex values in the fixture JSONs are synthetic (derived from prose
  descriptions in `docs/blueprint_examples.md`). They exist to validate
  the `BlueprintColour` JSON shape, not to assert engine output correctness.
- `blueprint_input_user_2.json` sets `birthLocation` to `"Unknown"` because the
  Maria example in `blueprint_examples.md` provides no location. This is a
  fixture-only placeholder to satisfy the non-optional `String` field; the engine
  will always have a real location from onboarding.
- Recommended metals, stones, patterns, and code directives are transcribed
  directly from the example text.
- Narrative text fields are verbatim from the canonical examples.
