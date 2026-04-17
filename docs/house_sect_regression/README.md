# House/Sect Regression Harness

This directory stores golden regression artifacts for the house/sect integration rollout.

## Generate snapshot bundles

Place post-integration Blueprint JSON outputs under:

- `_reference/house_sect_regression/input_after/ash.json`
- `_reference/house_sect_regression/input_after/maria.json`
- `_reference/house_sect_regression/input_after/day_chart_venus_angular.json`
- `_reference/house_sect_regression/input_after/night_chart_venus_cadent.json`

Then generate bundles (before + after + diffs + invariants):

```bash
python3 generate_house_sect_regression.py \
  --fixture ash \
  --before _reference/fixtures/blueprint_input_user_1.json \
  --after _reference/house_sect_regression/input_after/ash.json
```

Repeat for each fixture.

### One-command fixture export

You can auto-generate all `input_after/*.json` files directly from the runtime engine:

```bash
python3 export_input_after_fixtures.py
```

Custom fixture subset:

```bash
python3 export_input_after_fixtures.py --fixtures ash maria
```

## Validate snapshot bundles in CI/local

Run bundle generation for each fixture and then scorecard generation:

```bash
python3 generate_house_sect_regression.py --fixture ash --before _reference/fixtures/blueprint_input_user_1.json --after _reference/house_sect_regression/input_after/ash.json
python3 review_house_sect_regression.py
```

## Generate manual review scorecard

```bash
python3 review_house_sect_regression.py
```

This produces `_reference/house_sect_regression/SCORECARD.md` with:

- Mechanical invariants table
- Specificity gain deltas
- Manual rubric checklist placeholders
