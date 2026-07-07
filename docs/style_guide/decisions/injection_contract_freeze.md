# Injection Contract Freeze (end of SG-2)

**Frozen:** 2026-07-06, at the completion of SG-2 (Phases 2a–2e + 2.5).
**Rule:** no new placeholders, no output-contract schema changes, no profile
dimension additions, no ranked-table key changes, no cache-schema changes, and no
`formula_vocabulary` edits until the SG-3 regen is complete and validated by
SG-4. The narrative cache regen (~9,216 paragraphs) is expensive; if the
injection contract changes after regen starts, the cache goes stale.

This document is the authoritative snapshot of everything SG-3 fills.

---

## 1. Placeholder vocabulary

The complete set of `{placeholder_name}` tokens the renderer
(`NarrativeTemplateRenderer.allPlaceholders`) recognises. Any `{token}` not in
this set is unknown (graceful "" in production; `⟦UNKNOWN:token⟧` in QA mode).

**Palette / colour**
`neutral_colour_1..4`, `core_colour_1..4`, `accent_colour_1..4`,
`family`, `cluster`, `depth`, `temperature`, `saturation`, `contrast`, `surface`

**Patterns**
`recommended_pattern_1..4`, `avoid_pattern_1..2`

**Hardware — metals & stones**
`metal_1..3`, `stone_1..3`
**NEW (SG-2 Phase 2c):** `personal_metal_1..2`, `structural_metal_1..2`, `excluded_finish`

**Textures**
`texture_good_1..4`, `texture_bad_1..3`, `sweet_spot_keyword_1..2`

**Rendering rules (frozen):**
- Metal names substitute **verbatim** (no programmatic " tones" suffix — the old
  `softenMetalName` garble is removed). Softening for prose flow is the cache
  prose's job via placeholder position.
- Sentence-boundary capitalisation is applied when a placeholder follows
  `. ` / `? ` / `! `.
- Production: a recognised-but-unfilled placeholder → `"a complementary choice"`;
  an unknown placeholder → `""`.
- QA mode (`COSMICFIT_PLACEHOLDER_QA` env var or `qaModeEnabled`): unfilled →
  `⟦UNFILLED:token⟧`; unknown → `⟦UNKNOWN:token⟧`. `containsUnresolvedSentinels(_:)`
  is the SG-3 composed-output check hook. (Full strictness is SG-4.)

---

## 2. Output-contract schema (Phase 2.5)

Optional fields on `CosmicBlueprint` and its section structs
(`BlueprintModels.swift`). All optional; absent renders as pre-SG-2 layout.

**Cluster level (`CosmicBlueprint`):**
- `coreFormula: String?`
- `closing: String?`

**Per-section (`StyleCoreSection`, `TexturesSection`, `PaletteSection`,
`OccasionsSection`, `HardwareSection`, `CodeSection`, `AccessorySection`,
`PatternSection`):**
- `sectionIntro: String?`
- `rankedItems: [RankedItem]?`
- `tests: [String]?`
- `traps: [Trap]?`

**Hardware also carries (Phase 2b, deterministic):**
- `personalMetals: [String]?`, `structuralMetals: [String]?`, `excludedFinishes: [String]?`

**Types:**
- `RankedItem { name: String, role: String, useCase: String? }`
- `Trap { failure: String, fix: String }`

Back-compat: pre-SG-2 stored blueprints (missing all of the above) decode
unchanged — proven by `SG2OutputContractTests.legacyBlueprintDecodes` and
`legacyHardwareDecodes`.

---

## 3. Profile dimensions (`ChartAestheticProfile`)

Frozen enum cases and their string raw values (used verbatim as ranked-table key
components):

- `Orientation`: `selfContained` | `communityOriented` | `balanced`
- `AestheticRegister`: `quietLuxury` | `boldExpression` | `versatileAdaptive`
- `MetalStrategy`: `warmDominant` | `coolDominant` | `dualRegister` | `mixedFree`
- `FinishLane`: `muted` | `polished` | `mixed`
- `Temperature`: `warm` | `cool` | `neutral`
- `Confidence`: `high` | `low`
- `OverlayPolicy`: `full` | `neutralPreferred` | `suppressConflicting`

Derivation rules: `docs/style_guide/decisions/profile_derivation.md` (SG-1).
The Venus-element **temperature floor** (Phase 2e) mirrors
`temperature(forVenusSign:)` and is part of this freeze.

---

## 4. Ranked-table keys (`ranked_domain_tables.json`, Phase 2d)

`schema_version: 1`. Resolver: `RankedDomainTablesLoader`.

**colours_by_role** — 12 keys = `<temperature>_<lane>` where lane ∈
{quietLuxury, boldExpression, versatileAdaptive, water_dominant}:
`warm_quietLuxury`, `cool_quietLuxury`, `neutral_quietLuxury`,
`warm_boldExpression`, `cool_boldExpression`, `neutral_boldExpression`,
`warm_versatileAdaptive`, `cool_versatileAdaptive`, `neutral_versatileAdaptive`,
`warm_water_dominant`, `cool_water_dominant`, `neutral_water_dominant`.
Value: `{ neutrals:[{name,role}], accents:[{name,role}], relief:[{name,role}], passOver:[String] }`.

**textures** — 4 keys: `quietLuxury`, `boldExpression`, `versatileAdaptive`,
`water_dominant` (distinct water lane, not folded into quietLuxury).
Value: `[{ name, useCase, rank }]` (≥7 rows each).

**accessory_specs** — 27 keys = `<register>_<orientation>_<finishLane>` (3×3×3).
Value: `{ categories: [{ category, decision, reason, material?, finish? }] }`,
`decision` ∈ {include, omit}.

**Coverage invariant (frozen):** every `(temperature × register)` colour key,
every register texture key, and every `(register × orientation × finishLane)`
accessory key resolves to a non-empty table — proven by
`SG2RankedTablesTests.noEmptyLookups`.

---

## 5. Cache file schema v2 (`blueprint_narrative_cache.json`, Phase 2.5)

**Shape:** top-level `schema_version` (Int) sibling to cluster keys. Each cluster
value is an object:
```json
{
  "coreFormula": "…",              // cluster-level, optional
  "closing": "…",                  // cluster-level, optional
  "<section_key>": {                // e.g. "style_core", "hardware_metals"
    "text": "…",
    "sectionIntro": "…",
    "rankedItems": [{ "name":"…", "role":"…", "useCase":"…" }],
    "tests": ["…"],
    "traps": [{ "failure":"…", "fix":"…" }]
  }
}
```

**v1 back-compat decode rule (frozen):** a section value that is a **plain
string** decodes as v1 `{ text: <string> }`. So the shipped v1 cache, the
2-cluster fixture, and the bundled copy all still load unchanged — proven by
`SG2CacheSchemaTests.v1StillLoads`; the v2 fixture round-trips loader → composer →
model fields (`v2FixtureLoads`, `composerWiring`).

Reserved cluster-level keys (never treated as sections): `coreFormula`,
`closing`, `schema_version`.

`backfill_narratives.py` (SG-3) writes v2 objects.

---

## 6. `formula_vocabulary` tables (Phase 2d)

Shipped in `astrological_style_dataset.json → formula_vocabulary`. Frozen mirror
of the Swift `FormulaVocabulary` enum so SG-3's Python parity computation cannot
drift.

- `venus_sign`: 12 rows `{ structure: String, structureByRegister?: {register:String},
  structureWaterVariant?: String, accent: String }`
- `moon_sign`: 12 rows `{ flow: String }`
- Composition (frozen): `structure + flow + accent`, where `structure` is the
  register-inflected variant if present, else the water variant when the chart is
  water-dominant, else the default. A pure function of the coarse key.
- Register-inflected variants that exist (golden-anchored): Taurus
  `structure → soft structure` (water); Leo `dark drama → quiet grandeur`
  (quietLuxury).

**Coverage invariant (frozen):** all 576 coarse keys compose a non-empty,
three-part, register-consistent formula; the Swift enum and the dataset mirror
compose identically for all 576; every golden cluster reproduces its authored
formula exactly — proven by `SG2FormulaVocabularyTests`.

---

## 7. Schema version

- Blueprint engine version (`BlueprintComposer.engineVersion`): **2.1.0** (this
  is the model/pipeline version; SG-2 adds only optional fields, so stored 2.1.0
  blueprints remain decodable; bump to 2.2.0 is deferred to the SG-3 regen so the
  regen and the version move together).
- Cache file: `schema_version` = **2** going forward; **1** = plain-string
  sections (still decodable).
- Ranked domain tables: `schema_version` = **1**.

---

## Handoff to SG-3

SG-3 fills the frozen slots (placeholders + output-contract + cache v2 objects)
and regenerates the cache. It must not add placeholders, change the output
schema, add profile dimensions, change ranked-table keys, or edit
`formula_vocabulary`. Any such need reopens SG-2 and this freeze.
