# Repo Rename Spec — `_reference/` → `docs/`

> **Version:** v1  
> **Phase:** 0 of the Palette Rework programme  
> **Dependency chain:** this spec is a hard prerequisite for `palette_engine_rework_spec_v1.md` (Phase A) and transitively for `palette_grid_spec_v1.md` (Phase B).  
> **Companion specs:** `docs/palette_engine_rework_spec_v1.md`, `docs/palette_grid_spec_v1.md` (these paths were moved from `_reference/...` as part of this sweep).

---

## 1. Summary

Rename the repo's reference-material directory from `_reference/` to `docs/`, and update every live reference to the old path across source, tests, scripts, and documentation. This is a **path-only** change — no file contents change except where they reference the path itself.

## 2. Goals

1. `git mv _reference docs` lands cleanly in a single commit.
2. After the sweep, `rg _reference` returns **zero** hits outside `.git/`.
3. All automated tests continue to pass (`swift test`).
4. All Python CLIs continue to work with their default arguments.
5. Every AI dev coming after Phase 0 can trust that `docs/...` paths are correct.

## 3. Non-Goals

- **No content reorganisation** inside the folder. `fixtures/`, `house_sect_regression/`, and all existing top-level documents move under `docs/` with their paths relative to the folder preserved. You are NOT restructuring — you are renaming.
- **No editing of fixture or dataset contents.** Only path references inside those files may be updated; data must not be touched.
- **No engine / UI changes.** The engine-side palette rework and the UI-side grid component are separate specs (Phase A and Phase B). Do not attempt either.
- **No Xcode project changes.** The project file (`Cosmic Fit.xcodeproj/project.pbxproj`) has been checked and contains **zero** `_reference` hits. Do not modify it.
- **No introduction of a new `_archive/` or similar folder.** None exists; scope is strictly `_reference/` → `docs/`.
- **No Cursor skills / canvases / plans changes.** Anything under `/Users/ash/.cursor/` is outside this repo and outside scope.

## 4. Touch Sites

These were discovered via `rg -n '_reference' --glob '!.git'` on the live repo at the time this spec was authored. If `rg` surfaces any additional live-file hit when you run the sweep, **treat it as in scope** and update it (it likely means a new file was added between spec-authoring and your start). Note it in your PR description.

### 4.1 Swift sources

- **`Cosmic FitTests/Cosmic_FitTests.swift`**
  - **Line 24** — `.appendingPathComponent("_reference")`
  - **Line 34** — hard-coded error message: `"Ensure the repo checkout contains _reference/fixtures/..."`
  - **Line 1087** — `.appendingPathComponent("_reference")`

- **`Cosmic Fit/InterpretationEngine/BlueprintModels.swift`**
  - **Line 17** — comment: `// See _reference/blueprint_model_field_sources.md for the full mapping.`

### 4.2 Python scripts

Each script has one or more hits on a pinned line. Update every hit to reference `docs/...`.

- **`validate_dataset.py`** — line 6 (docstring).
- **`review_tool.py`** — line 6 (docstring).
- **`review_house_sect_regression.py`** — lines 10, 59, 116, 121 (docstring, help text, default args).
- **`export_input_after_fixtures.py`** — lines 6, 41 (docstring, default arg).
- **`generate_house_sect_regression.py`** — lines 12–13, 110 (docstring, default arg).

Run the scripts with `--help` after editing to confirm the default arg strings print `docs/...`.

### 4.3 Top-level documentation

- **`README.md`** — lines 786, 872, 879–880, 895–896.
- **`BLUEPRINT_REBUILD_SPEC_v2.3.md`** — multiple. Run `rg -n '_reference' BLUEPRINT_REBUILD_SPEC_v2.3.md` and update every hit.

### 4.4 Cross-references inside the renamed folder itself

After `git mv`, these files live at `docs/...` but their **contents** still reference `_reference/...`. Update them:

- `docs/WP2_HANDOFF_NOTES.md`
- `docs/WP4_VALIDATION_REPORT.md`
- `docs/fixtures/CHANGELOG.md`
- `docs/house_sect_regression/REPORT.md`
- `docs/house_sect_regression/README.md`

### 4.5 Newly-authored specs inside the folder

Three spec files sit in `_reference/` at the time you start. They will move under `git mv` automatically:

- `_reference/repo_rename_spec_v1.md` (this file) → `docs/repo_rename_spec_v1.md`
- `_reference/palette_engine_rework_spec_v1.md` → `docs/palette_engine_rework_spec_v1.md`
- `_reference/palette_grid_spec_v1.md` → `docs/palette_grid_spec_v1.md`

**Check their contents** for any lingering `_reference/...` path strings and update those too. The specs were authored pre-rename, so they may reference their siblings by the old path.

## 5. Method

### 5.1 The rename itself

```bash
git mv _reference docs
```

Single commit, message: `chore(repo): rename _reference/ to docs/`.

### 5.2 The sweep

For each touch site in §4, open the file and update the path reference. Use exact-string replacement — no regex shortcuts that might match accidentally. Verify each change visually.

After editing all sites, run:

```bash
rg -n '_reference' --glob '!.git' --glob '!/Users/ash/.cursor/'
```

This must return **zero hits** in live files. If any hit remains, update it (it's likely a file that was added between spec-authoring and your start).

### 5.3 Commit structure

Preferred: two commits.

1. `chore(repo): rename _reference/ to docs/` — the `git mv` only.
2. `chore(repo): update _reference path references to docs` — all §4 sweep edits.

Alternative (also acceptable): single combined commit if the reviewer prefers atomic.

No `Co-authored-by` or other trailers are required unless your reviewer requests them.

## 6. Verification

Run all three before opening the PR. Capture output for the PR description.

### 6.1 Swift tests

```bash
xcodebuild test -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | tail -n 30
```

Or, if a simpler local test runner is in use, `swift test`. All fixture-loading tests must pass. If `Cosmic_FitTests.swift` fails to load a fixture, a path in §4.1 was missed.

### 6.2 Python CLIs

```bash
python3 validate_dataset.py --help
python3 review_tool.py --help
python3 review_house_sect_regression.py --help
python3 export_input_after_fixtures.py --help
python3 generate_house_sect_regression.py --help
```

Each help text must print `docs/...` in its default-arg strings. No `_reference/...` strings should appear.

### 6.3 Final grep

```bash
rg -n '_reference' --glob '!.git' --glob '!/Users/ash/.cursor/'
```

Must return zero hits.

## 7. PR Exhibits

Your PR description must include:

1. Output of `rg -n '_reference' --glob '!.git'` (expected: zero live-file hits).
2. Summary line of the Swift test run: either `xcodebuild test` tail or `swift test` output showing all suites passed.
3. Output of `python3 validate_dataset.py --help` (demonstrating updated default path).
4. Any touch sites you updated that were **not** pre-identified in §4 — list them and note how you discovered them.

## 8. Escalation

Stop and escalate in any of these cases:

- A Swift test fails to load a fixture after rename. Do **not** "fix" the test by editing fixture content; the issue is a missed path update.
- An additional live-file `_reference` hit appears that is not trivially an analogue of a pinned site (e.g. a new config file, an unexpected script). Confirm with the spec author before editing.
- `git mv` reports untracked files in `_reference/` (indicates local drift). Inspect and confirm whether those files should be kept.

## 9. Risks

- **External tooling with hardcoded paths.** Anything outside this repo (e.g. CI pipelines, user Cursor settings) referencing `_reference/` will break. This spec does not address external tooling; notify the programme owner in the PR if you know of any.
- **Documentation in review at the time of the rename.** PRs in flight that cite `_reference/` will need rebases. Not your problem, but flag it if you see draft PRs open.

## 10. Rollback

If the PR needs to be reverted post-merge:

```bash
git revert <commit1> <commit2>
```

(If you used the two-commit structure, revert both.)  
Or: `git mv docs _reference` and reverse the sweep.

The rename is a leaf change with no downstream consumers inside this repo except the two companion specs (which themselves haven't been consumed yet at your merge time). Rollback is low-risk.

## 11. Acceptance Criteria

- [ ] `git mv _reference docs` landed.
- [ ] All §4 touch sites updated.
- [ ] `rg -n '_reference' --glob '!.git'` returns zero hits.
- [ ] `swift test` green.
- [ ] All five Python CLIs print `docs/...` in `--help` default-arg strings.
- [ ] PR exhibits §7 captured in PR description.
- [ ] No engine code, UI code, fixture content, or dataset content modified.

---

*Authored as part of the Palette Rework programme. After Phase 0 merges, Phase A (`palette_engine_rework_spec_v1.md`) unblocks.*
