# V4.6 Accent Refactor — Handoff & Next Steps

**Audience:** Next engineer or AI agent continuing palette/accent work.  
**Repo root:** `/Users/ash/dev/mobile_apps/cosmicfit`  
**Related plan (historical):** `~/.cursor/plans/accent_colour_refactor_8358cde3.plan.md` (todos marked completed for the implementation described below).

---

## 1. Why this refactor happened

**Problem the plan addressed:** The previous accent pipeline used **one LCH archetype per zodiac sign** and `SignArchetypes.projectSignIntoEnvelope(..., accentPop: true)`. That produced accents that could feel **disconnected** from the user’s seasonal family (e.g. a vivid violet for Sagittarius against a warm Deep Autumn core).

**Chosen direction (implemented):**

- **Family-conditioned candidates:** Each sign has **multiple** `SignExpression` rows keyed by canonical **`Temperature`** (`FamilyProfiles.variables(for: family).temperature` → warm / neutral / cool).
- **Spike scoring:** Pick the candidate that **maximises perceptual separation** from colours already in the “personal palette” set passed into the resolver (template neutrals/core/support/anchors resolved to **hex via `PaletteLibrary.hex(for:)`**, plus luminary and ruler signature hexes — see `ColourEngine` step 14).
- **Pairwise diversity:** Each new accent must be **ΔE ≥ 8** (squared Lab distance ≥ 64) from accents already chosen; scoring also folds in **already-chosen accent hexes** so later slots avoid doubling hues when alternatives exist.
- **Cleanup:** Removed patch-style helpers (`shiftToCreateDistance`, `findAlternative`, template fallbacks, old dual-threshold diversity guard) per plan.

**What was explicitly preserved:**

- **`ChartSignatureResolver`** and its **single-archetype table** for **luminary + ruler signatures** (envelope-projected, not accent-style).
- **Frozen V4 steps 1–12** in `ColourEngine` (classification, weights, etc.).
- **Slot *role* logic** in `AccentResolver`: which **planet + sign** feeds Signature / Contrast / Depth / Lift (same ordering and rules as before the refactor).

---

## 2. What was implemented (concrete)

### 2.1 Data: `SignAccentExpressions`

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/SignArchetypes.swift`

- New types: `SignExpression` (`L`, `C`, `h`, `name`), enum **`SignAccentExpressions`** with static `expressions: [V4ZodiacSign: [Temperature: [SignExpression]]]`.
- **12 signs × 3 temperatures × 3–4 candidates** (hand-tuned LCH + human-readable `name` for UI/copy).
- **`SignArchetypes.archetypes`** still aliases **`ChartSignatureResolver.archetypes`** for signatures and for **`ProgressedPaletteGenerator`** (`projectSignIntoEnvelope` + `accentPop` unchanged for progressed).

Renamed for clarity: `accentDisplayNames` → **`signDisplayNames`** (used by progressed display strings).

### 2.2 Resolver: `AccentResolver`

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/AccentResolver.swift`

- **`resolve(family:input:personalPaletteHexes:)`** looks up **`temperature`**, loads **`SignAccentExpressions.candidates(for:temperature:)`**, scores each candidate, picks best that satisfies pairwise distance to prior accents.
- **`spikeScore`:** `minDeltaE` to nearest colour in the avoidance set + small **hue-in-family-arc bonus** + **chroma floor penalty**.
- Avoidance set for scoring: **`personalPaletteHexes + chosenHexes`** so scoring prefers separation from **core + signatures + prior accents**.

### 2.3 Engine wiring

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/ColourEngine.swift`

- Step **14** still builds `personalPaletteHexes` with **`PaletteLibrary.hex(for:)`** for named template bands (critical fix from earlier work — **names are not hex**).
- Comment updated to describe V4.6 candidate selection (no `accentPop` for accent slots).

### 2.4 Progressed palette

**File:** `Cosmic Fit/InterpretationEngine/ColourEngineV4/ProgressedPaletteGenerator.swift`

- Only change: reference **`signDisplayNames`** instead of removed `accentDisplayNames`.

### 2.5 Tests & fixtures

- **`MariaAshLocked_Tests`:** Accent section updated for V4.6 — valid hex, pairwise ΔE, minimum distance from **neutrals+core** (threshold aligned with ΔE ≥ 8), names from expression table, determinism, qualitative warm-family check.
- **`V4CalibrationRegression_Tests`:** **Classification gate** unchanged (100-user classification still valid). **Palette gate** `accentColours` expectations in **`docs/fixtures/v4_dataset.json`** were regenerated to match new hex outputs.
- Full verification run (at time of implementation): Maria/Ash locked tests + classification + palette gate + `ColourEngineV4_UnitTests` green.

---

## 3. Product feedback — why results still feel wrong

**Summary from testing:** Accents can read as **re-stating the core band** (earthy olives, golds, ox-blood-adjacent reds) instead of **showcasing under-represented chart “colour”** (e.g. more **air/water / Gemini–Pisces** blues and cool notes) while still **harmonising** with the seasonal template.

**Example trace (realistic Deep Autumn user):**

From logs shared in review:

- Family: **Deep Autumn**, cluster **Deep Warm Structured**.
- Accents resolved roughly to **Golden Lichen**, **Olive Moss**, **Oxblood**, **Golden Amber** — alongside core rows like **oxblood**, **forest teal**, **forest green**, **dark terracotta**.

**Perceived issue:** The **scoring objective** (“spike” = **maximum distance** from the assembled personal palette) **does not equal** “surface **uncommon** chart emphasis.” Distance maximisation will happily pick **another warm yellow–olive** if it is far enough in Lab from existing swatches — it does **not** penalise **semantic doubling** of what the core already expresses (earth-rich, warm forest).

**Astrological intent gap:** The user described wanting accents drawn from **less common / limited / “crushed”** symbolic territory of the chart — e.g. **Gemini** placements and **Pisces rising** pushing **blues and cool air–water** accents — **re-tinted through** the Deep Autumn lens so they **harmonise**, not **repeat** what the core already showcases.

The **current slot assignment** still maps:

| Role       | Source logic (unchanged) |
|-----------|---------------------------|
| Signature | Venus; else Ascendant’s **domicile ruler’s** sign |
| Contrast  | Lowest **element** drivers, etc. |
| Depth     | Pluto → Mars → Saturn → … |
| Lift      | Jupiter → Sun → … |

That pipeline uses **`BirthChartColourInput`** (signs per driver only) — **no houses, no angularity, no aspect weights.** So **Pisces rising** only enters Signature if Venus is “claimed” and the ruler chain yields Pisces; **Gemini** appears only if those rules land on Mercury/Jupiter/Sun etc. **Contrast** is driven by **element distribution**, not “what’s astrologically rare in this chart.”

So the gap is **two-layered**:

1. **Objective mismatch:** “Max ΔE from palette” ≠ “highlight underrepresented chart motifs.”
2. **Coverage mismatch:** Fixed four-role planet rules may **never** privilege Ascendant, Moon, or “sparse” signs the product wants emphasised.

---

## 4. Suggested directions for the next iteration (not implemented)

These are **design forks** — pick one or combine after product sign-off.

### 4.1 Change the optimisation target (harmonious spike, not “far from core”)

Ideas:

- **Harmony-first:** Score candidates by **fit inside family envelope / hue arc** (or soft distance to envelope centre), then **secondary** separation from core — instead of **primary** `minDeltaE`.
- **“Don’t repeat core”:** Penalise candidates whose **hue family** or **Lab bucket** matches **dominant buckets** of neutrals+core (cluster in Lab space), even if ΔE is large.
- **Semantic zones:** Tag template/core colours with **role** (e.g. red-brown core vs green core) and **forbid** accent candidates that fall in the same **tagged zone** as any core swatch.

### 4.2 Drive slots from “underrepresented” chart geometry

Requires **clear rules** and possibly **more inputs** than `BirthChartColourInput`:

- **Element / modality counts:** Under-indexed element gets a slot (or gets priority in candidate hue families).
- **Ascendant / Moon as first-class** accent sources when they sit in **underrepresented** signs relative to weighted driver totals.
- **Optional:** House or angular data from Swiss Ephemeris pipeline if product wants **angular** placements to win — would require **threading new fields** from chart calculation into colour input (schema + tests).

### 4.3 Candidate table vs projection

- Keep **temperature-keyed** expressions but add **second axis**: e.g. **element family** or **hue bucket** per candidate so the resolver can **prefer air/water-blue families** when the chart says “surface Gemini/Pisces.”
- Or **reintroduce light envelope shaping** for accents only (different from signatures): map expression **direction** through **`ChartSignatureResolver`-style envelope** so blues read **Deep Autumn** but stay clearly **accent** (not signature crush).

### 4.4 Prevent duplicate “story” with luminary/ruler

Ensure accent roles **don’t** reuse the same **sign** already expressed in luminary/ruler rows when alternatives exist — optional **dedupe policy** in resolver.

---

## 5. Key files quick map

| Area | Path |
|------|------|
| Accent resolution | `Cosmic Fit/InterpretationEngine/ColourEngineV4/AccentResolver.swift` |
| Expression table | `Cosmic Fit/InterpretationEngine/ColourEngineV4/SignArchetypes.swift` (`SignAccentExpressions`) |
| Signatures (unchanged model) | `Cosmic Fit/InterpretationEngine/ColourEngineV4/ChartSignatureResolver.swift` |
| Personal palette hex assembly | `Cosmic Fit/InterpretationEngine/ColourEngineV4/ColourEngine.swift` (step 14) |
| Domain types | `Cosmic Fit/InterpretationEngine/ColourEngineV4/Domain.swift` (`AccentSlot`, `Temperature`, …) |
| Blueprint accent band | `Cosmic Fit/InterpretationEngine/BlueprintComposer.swift` |
| Regression dataset | `docs/fixtures/v4_dataset.json` |
| Locked users | `Cosmic FitTests/MariaAshLocked_Tests.swift` |

---

## 6. Regenerating palette expectations after future accent changes

Palette gate: **`V4CalibrationRegression_Tests.testPaletteGate`**.

- Environment variable intended for CI/local: **`REGENERATE_V4_PALETTE_EXPECTATIONS=1`** (see test file).  
- If simulator test runner does not inherit env, the test file historically supported a **temporary** `shouldRegenerate = true` for one-off regeneration (revert after writing `docs/fixtures/v4_dataset.json`).

Classification gate should stay **100/100** if steps 1–12 and family mapping are untouched.

---

## 7. Narrative / archetype fallback (orthogonal)

Logs showed **`ArchetypeKeyGenerator` fallback** and **`BlueprintComposer` narrative fallback** for a key mismatch — that is **separate** from accent hex logic but affects copy. Don’t confuse narrative key drift with colour engine behaviour.

---

## 8. One-line summary for the next owner

**Implemented:** Temperature-conditioned **multi-candidate** accents + **Lab-distance spike** scoring + pairwise diversity, with **fixed four-role planet rules** and **signatures still on the original archetype table**.  

**Still needed for the product vision:** Accents should **harmonise with** the core **without re-expressing** it — prioritising **chart-underrepresented** hue/story (e.g. air/water / rising / sparse placements) **through** the family lens, which requires **new objectives and/or new inputs**, not just larger ΔE from existing swatches.

---

*End of handoff.*
