# Fixtures Changelog

All changes to shared test fixtures under `docs/fixtures/`.

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
