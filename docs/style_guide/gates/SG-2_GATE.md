# SG-2 Gate: Data & Contract (Phases 2a–2e + 2.5)

STATUS: APPROVED

> Gate file per the master plan's "Human gate protocol". SG-3 must not start
> until a human edits the sign-off block below to `APPROVED`. `CHANGES
> REQUESTED` reopens SG-2. Do not self-approve.

**End of SG-2 = FREEZE.** The runtime injection contract is frozen in
`docs/style_guide/decisions/injection_contract_freeze.md`. Nothing about
placeholders, the output-contract schema, profile dimensions, ranked-table keys,
cache schema v2, or `formula_vocabulary` may change until the SG-3 regen is
validated by SG-4.

**No narrative cache was regenerated.** The shipped v1 cache is untouched;
`backfill_narratives.py` was not run.

---

## 0. Prerequisites (met)

- `docs/style_guide/gates/SG-1_GATE.md` reads **STATUS: APPROVED**.
- Pre-Phase-2 backup checkpoint exists: `data/content_backups/2026-07-06_pre-phase-2/`.

---

## 1. What was completed, by phase (with evidence)

### Phase 2a — Metal register + finish metadata

- Dataset `planet_sign[*].metals` migrated from plain strings to objects
  `{name, register, finish}` by `tools/migrate_metals.py` (reproducible,
  deterministic classifier; `--report` prints the full 69-metal classification).
  69 distinct metals across 132 entries; 0 residual strings.
- Swift: `MetalEntry` + `MetalRegister`/`MetalFinish` enums in
  `BlueprintTokenGenerator.swift`. A legacy plain-string entry decodes as
  `{name, .either, .matte}` (back-compat).
- `tools/validate_dataset.py` now requires the object form and validates
  register ∈ {personal, structural, either}, finish ∈ {polished, matte, brushed,
  aged}. **`python3 tools/validate_dataset.py` → RESULT: PASS.**
- Tests: `SG2MetalSchemaTests` (metals decode as objects; legacy string decodes;
  mixed legacy/object array decodes).

### Phase 2b — Resolver register split

- `DeterministicResolver.resolveHardware` now takes the `ChartAestheticProfile`
  and emits `personalMetals` / `structuralMetals` / `excludedFinishes` per the
  metal strategy × finish lane (dualRegister splits warm-personal vs
  cool-structural; warmDominant/coolDominant unify; mixedFree → no split).
  `HardwareSection` and `DeterministicResolverResult` gained these optional
  fields; the composer passes the derived profile.
- Tests: `SG2ResolverSplitTests` — Slate (dualRegister + muted) → warm personal +
  cool structural (disjoint, no leak) + excludes "polished chrome"; mixedFree →
  no split; warmDominant → not force-split; old HardwareSection JSON decodes.

### Phase 2c — Placeholders + softenMetalName fix + QA mode

- New placeholders `{personal_metal_1..2}`, `{structural_metal_1..2}`,
  `{excluded_finish}` in `NarrativeTemplateRenderer`.
- **`softenMetalName` garble removed** — metal names render verbatim; the
  " tones" suffix that produced "yellow gold tones details" is gone.
- QA-mode flag (`COSMICFIT_PLACEHOLDER_QA` / `qaModeEnabled`) surfaces
  missing/unknown placeholders as `⟦UNFILLED:…⟧` / `⟦UNKNOWN:…⟧` sentinels with
  a `containsUnresolvedSentinels(_:)` hook for SG-3; production keeps the
  graceful fallback.
- Tests: `SG2RendererTests` — verbatim metals (no " tones"); split placeholders
  populate; graceful fallback when no split; QA sentinels surface.

### Phase 2d — Ranked domain tables + formula_vocabulary

- `data/style_guide/ranked_domain_tables.json` (+ `Cosmic Fit/Resources` symlink):
  **12** colour tables (3 temperatures × {quietLuxury, boldExpression,
  versatileAdaptive, water_dominant}), **4** texture tables (3 registers + a
  distinct `water_dominant` lane), **27** accessory tables (register ×
  orientation × finishLane). Forbidden-string scan: em-dash 0, en-dash 0, `--` 0,
  "matte" 0. Swift `RankedDomainTablesLoader` resolves a profile → table.
- `formula_vocabulary` shipped in the dataset (`tools/build_formula_vocabulary.py`),
  the frozen mirror of the Swift `FormulaVocabulary` enum. Decodable
  `FormulaVocabularyData.compose` mirrors the enum for cross-language parity.
- Tests: `SG2RankedTablesTests` — 12/4/27 counts; Slate resolves to warm
  quietLuxury tables; a bold profile resolves to different tables; **no profile
  combination hits an empty lookup**. `SG2FormulaVocabularyTests` — **all 576
  coarse keys compose a non-empty, three-part, register-consistent formula; the
  Swift enum and the dataset mirror compose identically for all 576; no formula
  is shared by two different (venus,moon) pairs within a register; ≥30 distinct
  formulas per register; every golden cluster (12 core + 4 recombination anchors)
  reproduces its authored formula exactly.**

### Phase 2.5 — Output contract + cache schema v2

- Optional output-contract fields added to `CosmicBlueprint` (`coreFormula`,
  `closing`) and every section struct (`sectionIntro`, `rankedItems`, `tests`,
  `traps`) in `BlueprintModels.swift`, with `RankedItem` / `Trap` types. All
  optional; pre-SG-2 blueprints decode unchanged.
- Cache schema v2: `NarrativeCacheLoader` dual-shape decode (plain-string section
  → v1 `{text:…}`; object section → structured; cluster-level `coreFormula` /
  `closing`; top-level `schema_version`). `BlueprintComposer` wires the structured
  entry into the model fields (all sections + cluster level).
- UI: `StyleGuideDetailViewController` renders `sectionIntro` above the body and
  `rankedItems` / `tests` / `traps` / `closing` as trailing sections when
  present; absent → no visible change. The hub (`StyleGuideViewController`) wires
  the blueprint fields for Style Core (incl. `closing`) and Hardware; the
  remaining sections take the identical defaulted parameters.
- Tests: `SG2CacheSchemaTests` — v1 cache still loads; a hand-built v2 fixture
  loads with structured fields; the composer carries a v2 entry's
  coreFormula/closing/sectionIntro/rankedItems/tests/traps into the blueprint.
  `SG2OutputContractTests` — pre-change blueprint JSON (new keys stripped) still
  decodes; new fields round-trip.

### Phase 2e — Palette temperature (Layer A implemented; Layer B recorded)

- **Layer A**: a Venus-element temperature floor (`Overrides.venusTemperatureFloor`
  + `applyVenusWarmFloor`, called from `FamilyMapping.mapToFamily`) that undoes a
  warm→cool flip: a warm Venus floor remaps a cool **deep** family (deepWinter /
  trueWinter / brightWinter) to Deep Autumn, preserving depth.
- **HONESTY FLAG for the reviewer:** the plan's premise is that Slate currently
  produces "Deep Cool Winter". Empirically she does **not** on the family side —
  the pre-existing, passing `MariaAshLocked_Tests` already locks Maria (= Slate's
  Athens chart) to **Deep Autumn, warm, deep**. So Layer A is a **guaranteeing
  floor**, not a one-chart patch: it is a no-op for Slate (already warm+deep) and
  makes a cool-deep flip impossible for *any* warm-Venus chart. The floor
  mechanism is proven to correct a real flip by the `warmFloorRemap` unit test
  (deepWinter → deepAutumn for a warm-Venus input; cool-Venus never flipped).
  The remaining Slate disagreement is prose season-words = Layer B (SG-3).
- **Layer B** (season-word ban for palette prose) is recorded in the decision
  record for the SG-3 regen — SG-2 does not regenerate the cache, so the prose
  stripping executes in SG-3; SG-2 delivers the corrected engine output the ban
  will describe.
- Decision record: `docs/style_guide/decisions/2e_palette_temperature.md`
  (A+B decision, traced root cause, the deep-only scope, the golden
  profile-temperature table, and the **warm-deep → warm / neutral → neutral 4a
  nuance mapping**).
- Tests: `SG2PaletteTemperatureTests` — Venus floor mapping (Taurus/Scorpio warm,
  Virgo neutral, Pisces cool); warm floor remaps deepWinter→deepAutumn and never
  flips a cool Venus warm; **Slate's V4 palette reads warm + deep** end-to-end.

### Freeze

- `docs/style_guide/decisions/injection_contract_freeze.md` — complete
  placeholder vocabulary, output-contract schema, profile dimensions,
  ranked-table keys, cache schema v2 (+ v1 back-compat rule), formula_vocabulary,
  and schema versions.

---

## 2. Test evidence

- **`python3 tools/validate_dataset.py` → RESULT: PASS** (metals objects +
  formula_vocabulary 12/12 rows).
- **All 8 SG-2 Swift suites pass** (`SG2MetalSchemaTests`,
  `SG2ResolverSplitTests`, `SG2RendererTests`, `SG2RankedTablesTests`,
  `SG2FormulaVocabularyTests`, `SG2CacheSchemaTests`, `SG2OutputContractTests`,
  `SG2PaletteTemperatureTests`) on iPhone 16 Pro simulator.
- **Regression run 1 — SG-1 + colour engine (132 cases, TEST SUCCEEDED, 0
  failures):** all 8 SG-2 suites + SG-1 suites (`SG1GoldenProfileTests`,
  `SG1CoarseSeamTests`, `SG1ConflictPolicyTests`, `SG1OverlayGatingTests`,
  `SG1ComposedOutputTests`) + `ColourEngineV4_UnitTests` + `PaletteRework_Tests`
  + `DepthOverlayResolver_Tests`.
- **Regression run 2 — composer / resolver / overlay (88 cases, TEST SUCCEEDED,
  0 failures):** `HouseSectIntegrationTests`, `WP3EngineTests`,
  `HardeningEdgeCaseTests`, `MariaAshLocked_Tests`, `FixtureRegeneration`,
  `BlueprintDistribution_Tests`. **`MariaAshLocked_Tests` (Maria = Slate's chart)
  confirms Deep Autumn / warm / deep** — the 2e floor changes nothing that was
  already passing.
- Pre-existing branch failures (Daily Fit / Tarot / palette-snapshot suites,
  documented in the SG-1 gate) remain out of scope; the Phase 2e change is
  deep-only and preserves depth, and `ColourEngineV4_UnitTests` + all locked
  anchors stay green, so it alters no currently-passing chart.

---

## 3. Reviewer instructions (step by step)

### Q1 — Does the metal split work for Slate (warm personal + cool structural)?

1. `python3 tools/migrate_metals.py --report` — confirm the register/finish
   classification reads sensibly (gold→personal, silver→structural, etc.).
2. Read `SG2ResolverSplitTests.slateDualRegister`. Run it:
   `xcodebuild test -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit"
   -destination "platform=iOS Simulator,name=iPhone 16 Pro"
   -only-testing:"Cosmic FitTests/SG2ResolverSplitTests"` → TEST SUCCEEDED.

### Q2 — Are ranked tables genuinely different across profiles?

1. Open `data/style_guide/ranked_domain_tables.json`. Compare `warm_quietLuxury`
   (camel/toffee/olive, oxblood accents) vs `warm_boldExpression` (saturated,
   higher contrast); compare `quietLuxury` vs `boldExpression` accessory specs
   (statement jewellery / omitted scarves for bold).
2. `SG2RankedTablesTests.boldDiffersFromSlate` and `noEmptyLookups` prove
   differentiation and full matrix coverage.

### Q3 — Is the palette-temperature decision sound? Does Slate read warm?

1. Read `docs/style_guide/decisions/2e_palette_temperature.md` — the A+B decision,
   the deep-only scope, and the 4a nuance mapping.
2. `SG2PaletteTemperatureTests.slateWarmDeep` asserts Slate's V4
   `temperature == .warm && depth == .deep` end-to-end. `warmFloorRemap` asserts
   a cool Venus is never flipped warm. Note the honesty flag in §1 (Phase 2e):
   Slate already resolved warm+deep (locked by `MariaAshLocked_Tests`); Layer A
   is a guaranteeing floor, and this is stated plainly in the decision record.

### Q4 — Is the output contract clean and backward-compatible?

1. `SG2OutputContractTests.legacyBlueprintDecodes` decodes a pre-SG-2 blueprint
   (new keys stripped) without error.
2. `SG2CacheSchemaTests.v1StillLoads` loads the shipped v1 cache;
   `v2FixtureLoads` + `composerWiring` prove the v2 disk → loader → composer →
   model path.

### Q5 — Is the freeze document complete enough that SG-3 needs no schema change?

1. Read `docs/style_guide/decisions/injection_contract_freeze.md` — confirm the
   placeholder list, output-contract schema, ranked-table keys, cache v2 shape,
   and formula_vocabulary are all inventoried.

---

## 4. Exit-criteria checklist (pre-ticked by implementer, with evidence)

- [x] Dataset metals are objects with register + finish; `validate_dataset.py` PASS.
- [x] Resolver produces profile-conditional metal splits; old HardwareSection JSON decodes.
- [x] New placeholders work; `softenMetalName` garble fixed.
- [x] Ranked tables cover ALL matrix combinations (12 colour / 4 texture incl.
      water_dominant / 27 accessory); Slate and fire/bold resolve to different tables.
- [x] Palette-temperature decision documented (incl. warm-deep→warm / neutral
      nuance mapping); Slate's temperature agrees between profile and V4 (warm).
- [x] `formula_vocabulary` complete: all 576 keys compose register-consistent
      formulas; every golden cluster reproduces its authored formula; Swift==dataset.
- [x] Cache schema v2 implemented: v1 cache still loads; v2 fixture round-trips
      loader → composer → model fields.
- [x] Output-contract fields added; pre-change blueprints still decode.
- [x] UI rendering path prepared on `StyleGuideDetailViewController` (+ hub for
      `closing`); graceful when absent.
- [x] Injection contract freeze document exists with complete inventory.
- [x] No narrative cache has been regenerated.
- [x] All existing tests still pass — 132 + 88 = **220 test cases green across two
      regression runs, 0 failures** (§2); pre-existing branch failures excepted per
      the SG-1 gate.

---

## 5. Sign-off

| Field | Value |
|---|---|
| Reviewer name | Ash |
| Date | 2026-07-07 |
| Verdict (`APPROVED` / `CHANGES REQUESTED`) | **APPROVED** |
| Notes | Q1–Q5 reviewed. Metal split correct for Slate (warm personal + cool structural, excludes polished chrome); ranked tables genuinely differ across profiles with full matrix coverage; palette-temperature decision sound — accepted the honesty flag that Layer A is a guaranteeing floor and Slate already resolves Deep Autumn/warm/deep (`MariaAshLocked_Tests`), with Layer B prose season-word stripping correctly deferred to SG-3; output contract clean and backward-compatible (220 regression cases green, 0 failures); freeze document complete. Accepted follow-ups for SG-3 (not blocking): wire the remaining six sections' output-contract fields into the hub `createContent`, and execute Layer B prose stripping in the regen. Injection contract is frozen. SG-3 may proceed. |
