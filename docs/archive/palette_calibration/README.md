# Palette Calibration Benchmark

This directory holds human-labeled palette benchmarks used to calibrate the Blueprint palette engine against real user expectations.

## What this is for

The current resolver is strong at:

- preserving dataset primary vs accent pools
- maintaining hue diversity
- avoiding library fallback

It is weaker at:

- maintaining a coherent temperature/depth/chroma family
- preferring palette cohesion over "more different colours"
- expressing a recognisable seasonal family when a user clearly reads as one

This benchmark harness exists so palette tuning can happen with repeatable review artifacts instead of one-off screenshots and chat context.

## Where to see results

The benchmark harness itself is **not surfaced in the app UI**.

On device, you still review the result in the normal product surface:

1. open `Style Guide`
2. tap `The Palette`
3. inspect the generated anchors and tonal rows

The benchmark workflow lives **off-device** in repo tooling:

- benchmark fixtures in `docs/palette_calibration/benchmarks/`
- generated markdown reports in `docs/palette_calibration/reports/`
- comparison script at `review_palette_calibration.py`

## Benchmark file shape

Each benchmark JSON should contain:

- `id`
- `label`
- `source`
- `birth`
- `expectedFamily`
- `paletteExpectations`
- `humanReviewPrompts`
- `notes`

Keep benchmark expectations human-readable and product-facing. This is not a resolver-internals format.

## Suggested workflow

1. Generate or pull a real `CosmicBlueprint` JSON for the user under review.
2. Create or update a benchmark JSON in `benchmarks/`.
3. Run:

```bash
python3 review_palette_calibration.py \
  --benchmark docs/palette_calibration/benchmarks/maria_deep_autumn.json \
  --blueprint path/to/cosmic_fit_blueprint.json \
  --output docs/palette_calibration/reports/maria_deep_autumn.md
```

4. Read the markdown report.
5. Review the palette in-app on device or simulator.
6. Adjust the dataset and/or resolver.
7. Re-run until the mechanical score improves and human review passes.

## Calibration philosophy

Use this harness to tune for:

- coherent palette family
- fewer obviously off-family anchors
- stronger top-two narrative-exposed accents
- stable improvements across multiple labeled users

Do **not** use it to overfit one chart at the expense of everyone else.
