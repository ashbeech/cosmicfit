# House/Sect Regression Harness

> **Status:** Historical
> **Last audited:** June 2026
> **Source of truth:** `../../README.md` for current Style Guide architecture.

This directory stores historical regression artifacts from the house/sect integration rollout. The workflow below references fixture inputs that are no longer present in the current tree, so do not use it as an active runbook without first verifying it against the current engine and root README.

## Generate snapshot bundles

Place post-integration Blueprint JSON outputs under:

- `docs/house_sect_regression/input_after/ash.json`
- `docs/house_sect_regression/input_after/maria.json`
- `docs/house_sect_regression/input_after/day_chart_venus_angular.json`
- `docs/house_sect_regression/input_after/night_chart_venus_cadent.json`

Then generate bundles (before + after + diffs + invariants) using a verified current before-fixture path and the matching `input_after/{fixture}.json`.

Repeat for each fixture.

### One-command fixture export

You can auto-generate all `input_after/*.json` files directly from the runtime engine:

```bash
python3 tools/export_input_after_fixtures.py
```

Custom fixture subset:

```bash
python3 tools/export_input_after_fixtures.py --fixtures ash maria
```

## Validate snapshot bundles in CI/local

Run bundle generation for each fixture and then scorecard generation:

```bash
python3 tools/review_house_sect_regression.py
```

## Generate manual review scorecard

```bash
python3 tools/review_house_sect_regression.py
```

This produces `docs/house_sect_regression/SCORECARD.md` with:

- Mechanical invariants table
- Specificity gain deltas
- Manual rubric checklist placeholders
