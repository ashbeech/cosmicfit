# SG-0 Gate: Foundation (Phases -1, 0)

STATUS: APPROVED

> Gate file per the master plan's "Human gate protocol" (`style_guide_quality_overhaul_67e0c91f.plan.md`). SG-1 must not start until a human edits the sign-off block below to `APPROVED`. `CHANGES REQUESTED` reopens SG-0.

## Reviewer verdict (recorded 2026-07-06)

The human reviewer approved SG-0 with a short punch list. All requested corrections have been applied and verified (see §1a "Post-review corrections").

- **Q1 (golden guides are genuinely different genres): APPROVED.**
- **Q2 (rubric encodes the ideal without over-fitting to Slate): APPROVED WITH SMALL DOC FIXES** — applied: (a) `golden/README.md` guide counts corrected to 15 non-reference / 16 total; (b) `style_standard.md` §6 provenance corrected so the `matt` spelling row is attributed to the README **Hard rules** block, not numeric-floor decisions #2/#3 (a `README source` column was added).
- **Also review (tic harvest, baseline, Tarot test fix): APPROVED**, with one **required consistency fix** — applied: the stale `accentColours.count >= 2` fixture-shape assertions across the test suite were aligned to the chart-derived accent band (`>= 1`; Ash=1, Maria=2). Suite re-run green.

---

## 1. What was completed (with evidence)

### Phase -1: Content backup infrastructure

- **`tools/backup_content_sources.py`** (new): `backup` / `restore` / `list`, `--domain style_guide|daily_fit|all` (default `all`), `--label`, manifest with byte sizes + sha256 per file, `data/content_backups/LATEST.txt` pointer, and an importable `require_backup_gate()` used by the amend scripts.
- **Initial snapshot taken and verified**: `data/content_backups/2026-07-06_style-guide-overhaul-initial/` — 9 files, both copy domains (Style Guide: dataset, both narrative caches, extracted runtime strings, `HouseSectOverlayGenerator.swift`, `StyleGuideViewController.swift`, `backfill_narratives.py`; Daily Fit: `TarotCards.json`, `TarotCard.swift`). `manifest.json` lists all files with bytes + sha256. `LATEST.txt` points at it.
- **Restore round-trip verified**: `restore --dry-run` listed all 9; real `restore` ran; sha256 of `blueprint_narrative_cache.json` and `TarotCards.json` confirmed byte-identical after restore (shasum -c: OK).
- **Non-interactive hard gate wired into both amend scripts** (`tools/backfill_narratives.py`, `tools/content_audit_apply.py`): new `--backup-dir` and `--force-no-backup` flags; on a missing same-UTC-day backup the script exits **2** with instructions, never prompts on stdin. Verified before the snapshot existed: `backfill_narratives.py --dry-run` exited 2 with the refusal message; with `--force-no-backup` it proceeded (loud warning); after the snapshot, the gate reports "Backup gate satisfied". `content_audit_apply.py` gates real runs (dry runs write nothing) and smoke-tested clean.
- **Docs updated**: backup rule sections added to `data/style_guide/README.md` and `tools/README.md`.

### Phase 0c (pre-existing, validated here): golden guides + non-circularity

- All 16 golden guides exist in `docs/style_guide/golden/` (12 core + 4 mechanism anchors), authored before SG-0 execution. SG-0 did **not** re-author them; it validated them against the derived rubric (see below) and made 3 mechanical amendments (listed in §1 of `style_standard.md` §11 and golden README decision #6).
- **Non-circularity rule encoded in both required artifacts**: `docs/style_guide/golden/README.md` ("Non-circularity rule (binding)") and the header of `docs/style_guide/style_standard.md` ("Non-circularity rule (binding, inherited by SG-4)").

### Phase 0a: tic harvest + style standard rubric

- **`tools/harvest_narrative_tics.py`** (new): 2/3/4-gram frequency analysis over the shipped 576-cluster cache, within sentence bounds, placeholders excluded, ranked by distinct-cluster coverage, per-section tables, folklore-floor counting. Committed outputs: **`docs/style_guide/tic_harvest.json`** (full data) and **`docs/style_guide/tic_harvest.md`** (digest).
- **Key findings**: the folklore list was part-real: "unbothered" appears in **318/576 clusters** and "command the room" in 74; "devastatingly chic" and "quiet expensive authority" in 0. Real harvested tics include "walk into a room" (290 clusters), "your daily rotation" (270), "is an exercise in" (227), "your professional wardrobe" (204), "at the intersection of" (132), "the satisfying snap of" (121). Every banned phrase was cross-checked to appear in **zero** golden guides; high-frequency phrases the goldens legitimately use ("rather than", "pick it up", "cost-per-wear") went to a budgeted watch list instead of the ban list.
- **`docs/style_guide/style_standard.md`** (new): genre + voice spec; punctuation hard-never; every-section baseline; the full 8-section element contract table; numeric floors **adopted verbatim from the golden README** (>= 6 palette colours, exactly 7 fibres, >= 3 accessory categories, >= 1 test/trap per section, coreFormula at 5 fixed positions, matt spelling) plus SG-0-measured additions flagged with provenance (metals/stones >= 2, Code 4/3/3, filler cap <= 3/section, "rather than" <= 5/guide); harvested banned-tic list (§7a) + folklore floor (§7b) + change control (§7c); repetition watch list with budgets (§8); the **16 cache-key -> 8 composed-section mapping table** (§10); non-circularity header; rubric validation record (§11).
- **Rubric validated against all 16 guides**: `tools/check_golden_guides.py` (new) checks the mechanical subset (8 sections + closing, dashes, spelling, banned tics, formula at 5 positions, 7 fibres, >= 6 colours, metals/stones floors, accessory plan, test/trap heuristic). **Result: 16/16 PASS** (`python3 tools/check_golden_guides.py`, exit 0). Discrepancies found and resolved during validation:
  - `zephyr_ideal.md`: "Matte silk" -> "Matt silk" (guide violated its own README hard rule).
  - `ember_ideal.md`: had 5 ranked fibres vs the validated floor of 7 -> two fibres added in Ember's voice (sharp wool twill, stretch cotton sateen); Accessory opening now references all three formula slots.
  - `slate_ideal.md`: Code's first Lean Into did not state the coreFormula (golden README decision #3 claimed all 12 comply) -> formula line added.
  - Rule amended instead of guide (guides win): "off-duty" as plain adjective is allowed (Cinder); the banned tic is the cache's formulaic "your off duty wardrobe" / "off duty dressing". Slate-specific master-plan elements (tactile compass, low-contrast pattern rule, universal metal split) generalised to chart-conditional rules — documented in `style_standard.md` §5 "Rule amendments".

### Phase 0b: fixtures + baselines

- **`docs/fixtures/blueprint_input_user_1.json` and `_user_2.json` regenerated** (were missing on disk) via `TEST_RUNNER_REGENERATE_BLUEPRINT_FIXTURES=1 xcodebuild test ... -only-testing:"Cosmic FitTests/FixtureRegeneration"` — TEST SUCCEEDED, timestamps pinned to 2026-04-17 for byte-stable diffs.
- **Maria/Ash composed output exported** through the production `BlueprintComposer` pipeline (`HardeningEdgeCaseTests/exportInputAfterFixtures`, passed) and rendered to the pre-fix baselines: **`docs/style_guide/golden/baseline_maria_pre_overhaul.md`** and **`baseline_ash_pre_overhaul.md`** via the new `tools/render_blueprint_markdown.py` (golden-guide section order, app subheadings, palette/metal/pattern list data included). SG-4 must reuse the same renderer for "after" snapshots.
- The Maria baseline visibly exhibits the diagnosed defects (evidence the baseline is honest): "quiet, expensive authority" voice, "completely unbothered" (occasions_daily), Deep **Winter** / temperature=Cool palette against a warm-Venus chart, observer-voice Blueprint.

### Deviations / blockers encountered (documented, not silently deferred)

1. **Pre-existing test-target build breakage** (phase 0b; file `Cosmic FitTests/TarotCrossUserIsolation_Tests.swift`): the file referenced APIs that do not exist on the engine trackers (`storeSelection`, `getDailyColourHistory`, `StyleEssenceCategory.dramatic/.natural`), so the entire test target failed to compile and Phase 0b could not run. Fix: aligned the test to the real APIs (`storeCardSelection`, `daysSinceShown`, `.drama`/`.grounded`). No engine code touched.
2. **Stale fixture contract** (phase 0b; file `Cosmic FitTests/FixtureRegeneration.swift`): the old ">= 2 accents" assertion predates the palette-calibration lock under which Ash's chart yields exactly 1 chart-derived accent (asserted by `MariaAshLocked_Tests`). Regeneration wrote correct fixtures but failed the stale assertion. Fix: floor lowered to >= 1 with a comment citing the lock. No engine code touched.
3. **Environment-variable routing**: `REGENERATE_BLUEPRINT_FIXTURES=1` does not reach simulator test processes from the shell; the working invocation uses the `TEST_RUNNER_` prefix (recorded here for repeatability).

### Scope confirmation

`git status` shows **no changes** under `Cosmic Fit/` engine sources, no narrative-cache regeneration, no dataset schema changes, and no changes to `backfill_narratives.py` generation logic or prompts (only the backup gate + CLI flags were added). The only Swift changes are test files (deviations 1–2 and post-review consistency fix 4 below).

### §1a. Post-review corrections (applied 2026-07-06, after reviewer punch list)

1. **Doc — guide counts (`docs/style_guide/golden/README.md`)**: "the other 11 guides" -> "the other 15 non-reference guides"; heading "The set (12 guides)" -> "The set (16 guides)"; decisions #2/#3 "validated against all 12" / "All 12 comply" -> "all 16" / "All 16". (The intentional "core 12 / 12 Venus signs / guides 13-16" wording under coverage is unchanged — it refers to the zodiac, not the guide count.)
2. **Doc — floor provenance (`docs/style_guide/style_standard.md` §6)**: the first floors table now carries a `README source` column so each row is attributed correctly — numeric floors to README decision #2, the formula-placement floor to decision #3, and the **matt** spelling row to the README **Hard rules** block (not a numeric-floor decision).
3. **Test — accent-floor consistency (deviation 4)**: see below.

4. **Suite-wide accent-floor consistency** (phase 0b follow-up; reviewer-requested). The stale `accentColours.count >= 2` fixture-shape assertions in `Cosmic FitTests/Cosmic_FitTests.swift` (`shapeCompletenessUser1/2`), `PaletteGridViewModel_Tests.swift` (`fixturePaletteContract`), and `PaletteRework_Tests.swift` (`exactAccentCount`, `v4BandCounts`) were lowered to `>= 1` to match the regenerated fixtures (Ash=1, Maria=2) and the chart-derived 1...2 band. `PaletteRework_Tests.swift/v4TemplateProvenanceIntegrity` embedded the same stale "12 anchors, all `v4Template`" model and was rewritten to the real V4 provenance model (8 neutral+core anchors are `v4Template`; the 1...2 accents are `chartDerivedAccent`, never library fallback), confirmed against the fixtures' own `provenance.kind` values. **The engine-level per-chart contract in `MariaAshLocked_Tests` was left untouched** — `testAshAccentsAreChartDerived` asserts the *frozen placement* (`loadPlacement("ash")`) yields exactly 2 accent *slots* from `ColourEngine.evaluateStrict`, a different input than the *composed fixture* built from the recomputed 1984-12-11 chart (1 accent); both are correct, so there is no contradiction to resolve. No engine code touched. Verification: `xcodebuild test ... -only-testing:"Cosmic FitTests/BlueprintModelTests" -only-testing:"Cosmic FitTests/PaletteReworkTests" -only-testing:"Cosmic FitTests/PaletteLiveWiringTests" -only-testing:"Cosmic FitTests/MariaAshLocked_Tests"` -> **TEST SUCCEEDED** (all 4 classes green, including the rewritten `v4TemplateProvenanceIntegrity` and every `MariaAshLocked_Tests` case).

---

## 2. Reviewer instructions (step by step)

### Q1 — Are the golden guides genuinely different genres for different charts?

1. Open `docs/style_guide/golden/slate_ideal.md` (earth/quiet reference) and `docs/style_guide/golden/ember_ideal.md` (fire/bold) side by side.
2. Compare per section: formula (structure/softness/quiet depth vs clean impact/fast movement/one hot accent), palette (warm muted earth vs stark high-contrast + saturated brights), metals (muted dual-register, chrome excluded vs polished warm gold, antiqued excluded), pattern (blur-into-texture test vs ten-foot legibility test), compass (touch/weight vs hesitation/speed).
3. Spot-check a third contrast: `mist_ideal.md` (water/ethereal; breath test, pale translucency) against both.
4. Confirm the same 8-section + closing skeleton carries all three without the voices bleeding into each other.

### Q2 — Does the rubric encode the ideal without over-fitting to Slate?

1. Read `docs/style_guide/style_standard.md` §5, especially the "Rule amendments made while validating" list: the Slate-specific master-plan elements (tactile compass, palette role names, low-contrast pattern rule, universal personal/structural metal split) were deliberately generalised to chart-conditional rules. Verify you agree with each generalisation.
2. Check §6: the first floors table is adopted verbatim from `docs/style_guide/golden/README.md` and now carries a `README source` column — numeric floors to "Decisions" #2, the formula-placement floor to #3, and the `matt` spelling row to the README Hard rules block (no re-derivation). The second table is new but carries its own provenance.
3. Check §7: confirm the banned list contains only phrases absent from all goldens (spot-check by searching a couple, e.g. `rg -i "walk into a room" docs/style_guide/golden/*_ideal.md` returns nothing) and that legitimate coaching phrases sit in §8's budgeted watch list instead.
4. Run `python3 tools/check_golden_guides.py` — expect 16/16 PASS, exit 0, Slate marked as excluded from standard scoring.
5. Review the 3 golden-guide amendments (git diff on `zephyr_ideal.md`, `ember_ideal.md`, `slate_ideal.md`) and confirm they are mechanical/floor compliance, not re-authoring.

### Q3 — Is the backup infrastructure trustworthy?

1. Run `python3 tools/backup_content_sources.py list` — expect `2026-07-06_style-guide-overhaul-initial` marked `(latest)`, domain=all, files=9.
2. Open `data/content_backups/2026-07-06_style-guide-overhaul-initial/manifest.json` — confirm all 9 paths, byte sizes, sha256, and the restore command.
3. Run `python3 tools/backup_content_sources.py restore --dry-run` — expect all 9 listed, no writes.
4. Test the hard gate refusal path (no same-day backup): `.venv/bin/python tools/backfill_narratives.py --dataset data/style_guide/astrological_style_dataset.json --output /tmp/x.json --dry-run --backup-dir /nonexistent` — expect exit 2 with a clear message and **no interactive prompt**. (The plain command currently passes because today's snapshot exists; the refusal path was verified before the snapshot was taken.)
5. Confirm the rule is documented in `data/style_guide/README.md` and `tools/README.md`.

### Also review

- `docs/style_guide/tic_harvest.md` — sanity-check the top phrases read as genuine tics.
- `docs/style_guide/golden/baseline_maria_pre_overhaul.md` — confirm it reads as an honest "before" (wrong genre, cool Winter palette, folklore tics present).
- Deviations 1–2 above (the two test-file fixes) — confirm you accept them as in-scope unblocking fixes.

---

## 3. Exit-criteria checklist (pre-ticked by implementer, with evidence)

- [x] **Backup tooling works and initial snapshot is verified, covering BOTH domains** — `data/content_backups/2026-07-06_style-guide-overhaul-initial/manifest.json` (9 files, domain=all); restore round-trip sha256-verified; `LATEST.txt` set.
- [x] **`backfill_narratives.py --dry-run` refuses without backup and proceeds with `--force-no-backup`** — verified before the snapshot existed: exit 2 with message; `--force-no-backup` proceeded to the dry-run plan (192 clusters x 16 sections).
- [x] **At least 12 golden ideal guides spanning all 4 elements, day/night, stellium/no-stellium** — 16 guides in `docs/style_guide/golden/`; coverage matrix in that README (3 per element, 6/6 sect, 3 stelliums).
- [x] **Each golden guide follows the 8-section + closing structure** — `tools/check_golden_guides.py`: section/closing presence checked, 16/16 PASS.
- [x] **A fire/bold golden guide reads completely different from Slate** — Ember vs Slate (see reviewer Q1): different formula, palette, metals, patterns, compass.
- [x] **`style_standard.md` exists with complete element contract, numeric floors/caps, the 16-key -> 8-section mapping table, and a non-circularity header** — `docs/style_guide/style_standard.md` §5, §6, §10, header.
- [x] **Every golden guide (except Slate self) passes the rubric** — checker 16/16 PASS (15 non-reference guides prove the standard; Slate hygiene-checked but excluded from scoring).
- [x] **Harvested banned-tic list exists, committed alongside `style_standard.md`, folklore floor retained** — `docs/style_guide/tic_harvest.json` + `tic_harvest.md`; `style_standard.md` §7a/§7b.
- [x] **`style_standard.md` numeric floors match `golden/README.md` values (no re-derivation)** — §6 first table adopts them verbatim with a `README source` column (decisions #2/#3 for floors, Hard rules for the `matt` spelling row); the second table carries separate provenance.
- [x] **Blueprint fixtures regenerated and baseline snapshots captured** — `docs/fixtures/blueprint_input_user_{1,2}.json` (TEST SUCCEEDED); `docs/style_guide/golden/baseline_{maria,ash}_pre_overhaul.md`.
- [x] **No engine code, no schema changes, no cache changes** — git status: no `Cosmic Fit/` source changes; cache/dataset untouched; `backfill_narratives.py` gained only the backup gate. Two test-file fixes documented as deviations 1–2.

---

## 4. Sign-off

| Field | Value |
|---|---|
| Reviewer name | Human reviewer (recorded via agent) |
| Date | 2026-07-06 |
| Verdict (`APPROVED` / `CHANGES REQUESTED`) | **APPROVED** |
| Notes | Q1 approved; Q2 approved with small doc fixes; tic harvest / baseline / Tarot test fix approved with one accent-floor consistency fix. All three requested corrections applied and verified (see §1a): (1) golden/README.md guide counts 15/16; (2) style_standard.md §6 provenance column + `matt` attributed to Hard rules; (3) suite-wide `accentColours.count >= 1` alignment + `v4TemplateProvenanceIntegrity` rewritten, re-run TEST SUCCEEDED. `MariaAshLocked_Tests` engine contract left untouched. SG-1 may proceed. |
