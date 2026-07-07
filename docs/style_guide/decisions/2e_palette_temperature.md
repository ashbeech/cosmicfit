# Decision 2e — Palette Temperature Reconciliation (SG-2, Phase 2e)

**Decision owner:** Ash (2026-07-06). **Status:** implemented (Layer A); Layer B ban recorded for SG-3.

## Decision

**Option A + Option B, both, in order.** Fix the temperature at the engine (A),
AND require palette prose to describe resolved colours by role with zero season
words (B). A makes the colours correct; B makes the prose structurally unable to
re-open a swatch-vs-text gap. The Phase 4a blocking check then holds all three
sides (prose == V4 == profile) permanently.

## The problem (and an important correction to the plan's premise)

The plan states Slate's Venus is in Taurus (earth = warm) but `ColourEngineV4`
produces a **cool** "Deep Winter", and the `palette_narrative` hardcodes season
words ("winter coats"). **Empirically, in the current engine the family side of
that flip is not occurring for Slate/Maria.** `MariaAshLocked_Tests`
(a pre-SG-2, pre-existing, passing anchor) already asserts and confirms Maria's
chart — the same Athens chart as Slate — resolves to **Deep Autumn, warm, deep**
via `ColourEngine.evaluateStrict`. Prior earth-depth work already keeps her in
the warm deep family. So for Slate the disagreement that remains is the **prose**
(hardcoded season words), which is Layer B (SG-3), not the family.

This does not make Layer A unnecessary — it makes it a **guaranteeing floor**
rather than a one-chart patch: nothing structurally prevents *a different*
warm-Venus chart, with stronger cooling signals, from reaching a cool deep
family. Layer A makes that impossible for every warm-Venus chart, and the
guarantee is proven directly by unit test. This correction is flagged for the
reviewer.

## Root cause (traced in code)

Production temperature is **not** read directly from `rawScores.warmth` — it is
the canonical temperature of the mapped `PaletteFamily`
(`FamilyProfiles.canonical`). The flip therefore happens in **family
classification**, not in a late `variables.temperature = …` assignment:

- `Overrides.evaluateEarthDepthOverride` (`ColourEngineV4/Overrides.swift`)
  forces depth to `.deep` for Slate (Pluto Scorpio, Saturn Capricorn, earth core
  count ≥ 2). **Depth is correct and is kept.**
- In the deep group of `FamilyMapping.classifyHighEarthWater`, a warm-earth chart
  whose cooling signals trip `s >= 80 || w <= -60` lands in `.deepWinter`
  (cool) instead of `.deepAutumn` (warm). This is the warm→cool flip.
- `Overrides.isCoolLeaningDeepAutumn` encodes the same cooling signal
  (`rawScores.warmth < warmthWarmMin` AND ≥ 2 of Asc/Venus/Sun/Moon/Saturn in
  `{virgo, capricorn}` — Slate: Moon Cap + Saturn Cap = 2).
- `Overrides.shouldApplyWinterCompression` is already guarded by
  `variables.temperature != .cool`, so it is downstream of the flip, not the
  cause.

## Layer A — Venus-element temperature floor (implemented)

**Principle:** the Venus-sign element sets a temperature *floor* that depth/muting
overrides may deepen or mute but must not **flip**. A warm Venus can become
deep-warm or muted-warm; it must not silently become cool.

Implementation (`Overrides.venusTemperatureFloor` + `applyVenusWarmFloor`,
called from `FamilyMapping.mapToFamily` immediately after `classify()`):

1. `venusTemperatureFloor(input:)` returns warm/cool/neutral from the Venus sign,
   mirroring `ChartAestheticProfile.temperature(forVenusSign:)` exactly
   (earth/fire warm; **Scorpio warm-deep despite water**; **Virgo neutral**;
   air/water cool). The two derivations are intentionally identical so the
   profile and the V4 engine agree.
2. When the Venus floor is warm and the classified family is a cool **deep**
   family (`deepWinter`, `trueWinter`, `brightWinter`), the family is remapped to
   `deepAutumn` — the warm equivalent at the **same depth** (deep, rich,
   structured). Depth and surface are preserved; only the temperature flip is
   undone. `flags.venusWarmFloorApplied` records the event.
3. The Earth-Depth Override and Surface Preservation are untouched — depth and
   surface were already correct; only the temperature flip was the bug.
4. **Scope of the fix is deliberately deep-only.** The traced flips all land in
   the deep group; non-deep cool families reached by a warm Venus are out of
   scope for this iteration and none of the golden set requires them (see the
   golden table below — every warm-Venus golden already resolves warm on the
   profile side, and Slate now resolves warm on the V4 side).

### Result for Slate

`ColourEngineV4` for Slate reads `temperature = warm`, `depth = deep`,
`family = Deep Autumn` — confirmed end-to-end by
`SG2PaletteTemperatureTests.slateWarmDeep` and independently by the pre-existing
`MariaAshLocked_Tests` (`testMariaFamilyIsDeepAutumn`, `testMariaTemperatureIsWarm`,
`testMariaDepthIsDeep`), all passing. For Slate the floor is a **no-op** (she is
already in a warm family, not a cool deep family). The floor *mechanism* is
proven to correct a genuine flip by the direct `applyVenusWarmFloor` unit test
(`warmFloorRemap`: a Slate-like warm-Venus input classified to `deepWinter` is
remapped to `deepAutumn`; a cool-Venus input is never flipped warm).

## Layer B — palette prose from resolved colours, no season words (SG-3)

- `palette_narrative` (regenerated in SG-3) must describe the **actual resolved
  colours** with role annotation (neutral / accent / relief / trap), never
  hardcoded season labels ("winter coats", "Deep Cool Winter", etc.).
- The SG-3 generation prompt gains a season-word ban in its VOICE/no-dash rule
  block; existing hardcoded season words are stripped during the SG-3 regen.
- After Layer A the resolved colours for Slate are warm/muted/deep, so B now
  describes the correct thing — A and B reinforce rather than mask.
- **SG-2 does not regenerate the cache** (out of scope), so Layer B's prose
  stripping executes in SG-3. What SG-2 delivers for Layer B is this recorded
  ban and the corrected engine output that the ban will describe.

## Impact on the 576 clusters

The Venus floor is a pure function of the Venus sign; the *flip* it corrects is
chart-specific (it fires only when a warm Venus chart's cooling signals were
strong enough to reach a cool deep family). We cannot enumerate a real chart for
all 576 cache clusters (a cluster key is coarse: Venus × Moon × element; V4
temperature needs a full chart), so the honest, verifiable evidence is:

- **Profile side (all 16 golden charts):** unchanged by Phase 2e — the coarse
  profile temperature was already Venus-based (SG-1). Recorded below.
- **V4 side (Slate, the one real chart in the test suite):** already `deepAutumn`
  / warm / deep before and after Phase 2e (the floor is a no-op for her). The
  remaining Slate work is Layer B prose (SG-3).

Any warm-Venus chart that *would otherwise* resolve to a cool deep family now
shifts warm instead. Because the remap is deep-only and preserves depth, no chart
loses depth and no cool-Venus chart is ever pushed warm (`warmFloorRemap`).
`ColourEngineV4_UnitTests` (calibration fixtures) and `MariaAshLocked_Tests` both
remain green, so the floor changes **no currently-passing** chart.

## Temperature nuance mapping (required by the Phase 4a three-way check)

The engine enum `Temperature` is warm / cool / neutral. The golden set uses
nuance labels the 4a check must normalise before comparing:

| Golden nuance label | Maps to (4a) |
|---|---|
| `warm-deep` (Tide, Scorpio-Venus warm-despite-water) | `warm` |
| `neutral` (Flint, a real lane) | `neutral` |
| `warm` / `cool` | themselves |

The 4a three-way check (`prose temperature == V4 temperature == profile
temperature`) applies this mapping on all three sides. Without it the check
false-fails the exact golden guides authored to test the nuances.

### Golden profile temperatures (profile side; feeds the 4a check)

| Archetype | Venus | Profile temp | 4a-mapped |
|---|---|---|---|
| Slate | Taurus | warm | warm |
| Ember | Aries | warm | warm |
| Zephyr | Gemini | cool | cool |
| Cove | Cancer | cool | cool |
| Blaze | Sagittarius | warm | warm |
| Flint | Virgo | neutral | neutral |
| Frost | Aquarius | cool | cool |
| Mist | Pisces | cool | cool |
| Moss | Capricorn | warm | warm |
| Cinder | Leo | warm | warm |
| Breeze | Libra | cool | cool |
| Tide | Scorpio | warm (warm-deep) | warm |
| Ripple | Taurus | warm | warm |
| Hearth | Leo | warm | warm |
| Loom | Pisces | cool | cool |
| Wren | Cancer | cool | cool |

8 warm, 7 cool, 1 neutral. No warm-Venus golden resolves cool on the profile
side; Slate now agrees on the V4 side.

## How this feeds the Phase 4a blocking check

Phase 4a asserts `prose temperature == V4 temperature == profile temperature`
after the nuance mapping above. This phase ensures the check *can* agree on all
three sides: Layer A aligns V4 with the profile; Layer B (SG-3) aligns the prose
with the resolved colours; the nuance mapping makes warm-deep and neutral compare
correctly.
