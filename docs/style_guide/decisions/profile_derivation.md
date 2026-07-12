# ChartAestheticProfile derivation spec (SG-1)

**Status:** Draft, part of SG-1 (awaiting SG-1 gate review)
**Swift implementation:** `Cosmic Fit/InterpretationEngine/ChartAestheticProfile.swift`
**Test vectors:** `docs/style_guide/golden/profile_expectations.json` (inputs: `docs/style_guide/golden/fixtures/*_chart.json` + Slate's real natal export)
**Python parity consumer:** SG-3's coarse profile in `tools/backfill_narratives.py` must implement exactly the rules below and assert against the same vectors.

This document is language-neutral: every rule is expressed as data + arithmetic so the Swift and Python implementations cannot drift. The 16 golden guides are the fitted anchors; where a draft rule and a guide disagreed, the guide won and the rule below is the amended one.

---

## 1. Inputs

### Coarse profile (cache-key level)

Exactly three inputs, parsed from the narrative cluster key `venus_<sign>__moon_<sign>__<element>_dominant`:

- `venusSign`
- `moonSign`
- `dominantElement` (fire / earth / air / water)

Everything that can appear inside cached narrative prose — **register, temperature, finish lane, metal strategy, coreFormula, core keywords** — is a pure function of these three. This is the **key-purity rule**: 16 cached paragraphs are shared by every user in the bucket, so nothing outside the key may influence them.

### Fine profile (full chart)

Adds, on top of the same coarse core (never replacing it):

- `planetHouses["Moon"]` → orientation adjustment
- full `elementBalance` (fire/earth/air/water counts, 7 classical planets + Ascendant) → confidence margin
- `planetSigns` over all ten bodies → stellium detection → overlay conflict policy

Fine signals refine `orientation`, `confidence`, and `overlayPolicy` **only**. They never alter `coreFormula`, `aestheticRegister`, `temperature`, `finishLane`, or `metalStrategy`.

## 2. Sign character tables

### 2.1 Register character (per sign)

| Character           | Signs                                       |
| ------------------- | ------------------------------------------- |
| `quietLuxury`       | Taurus, Cancer, Scorpio, Capricorn, Pisces  |
| `boldExpression`    | Aries, Leo, Sagittarius                     |
| `versatileAdaptive` | Gemini, Virgo, Libra, Aquarius              |

### 2.2 Register character (per element)

fire → `boldExpression`; earth, water → `quietLuxury`; air → `versatileAdaptive`.

## 3. aestheticRegister — three-vote majority

Votes: `character(dominantElement)`, `character(venusSign)`, `character(moonSign)`. Any character with ≥ 2 votes wins. A three-way split resolves to **`versatileAdaptive`** and marks the vote as a **tie-break** (feeds confidence). Golden anchor for the tie-break: Wren (fire element = bold, Cancer Venus = quiet, Gemini Moon = versatile → versatileAdaptive, confidence low).

## 4. temperature — Venus element with sign nuance

Warm: Aries, Leo, Sagittarius, Taurus, Capricorn, **Scorpio** (warm-deep nuance maps onto `warm` — golden anchor: Tide).
Neutral: **Virgo** (the genuine neutral lane — golden anchor: Flint).
Cool: Gemini, Libra, Aquarius, Cancer, Pisces.

Nuance labels in guide metadata (warm-deep, dark-warm) map onto the enum **before** any comparison.

## 5. finishLane — register base + Venus-sign lean, clamped

Scale: `0 = muted`, `1 = mixed`, `2 = polished`.

- Base: quietLuxury = 0, versatileAdaptive = 1, boldExpression = 2.
- Venus-sign lean: −1 for Taurus, Cancer, Virgo, Scorpio, Capricorn; +1 for Aries, Leo, Aquarius; 0 for Gemini, Libra, Sagittarius, Pisces.
- `finish = clamp(base + lean, 0, 2)`.

Golden anchors: Flint (1−1=0 muted), Frost (1+1=2 polished), Hearth (0+1=1 mixed), Wren (1−1=0 muted), Loom (1+0=1 mixed), Cinder (2+1→2 polished).

## 6. metalStrategy — temperature lane + register + sign nuance (NOT raw element)

Evaluated in order; first match wins:

1. `register == versatileAdaptive && finish == mixed` → **mixedFree** (Zephyr, Breeze, Loom).
2. `temperature ∈ {cool, neutral}` → **coolDominant** (Cove, Mist, Frost, Flint, Wren).
3. `venusSign == Sagittarius` → **mixedFree** (statement-scale eclectic mixing — Blaze).
4. `moonSign ∈ COOL_STRUCTURAL_MOONS && finish != mixed` → **dualRegister**, where `COOL_STRUCTURAL_MOONS = {Capricorn, Aquarius, Aries, Virgo, Gemini, Libra}` (warm personal register + cool structural register — Slate muted, Cinder polished; Hearth escapes via its mixed finish, whose single gold flash absorbs the contrast).
5. otherwise → **warmDominant** (Ember, Moss, Tide, Ripple, Hearth).

## 7. orientation — additive score

`score = venusLean(venusSign) + moonLean(moonSign) + elementLean(dominantElement) [+ moonHouseAdjustment (fine only)]`

| Table        | −2                        | −1                              | 0         | +1                                        | +2          |
| ------------ | ------------------------- | ------------------------------- | --------- | ----------------------------------------- | ----------- |
| `venusLean`  | Scorpio, Aries, Cancer    | Taurus, Virgo, Pisces, Aquarius | Capricorn | Gemini, Leo, Libra                        | Sagittarius |
| `moonLean`   | Scorpio, Capricorn, Aries | Taurus, Cancer, Virgo, Pisces   | —         | Gemini, Leo, Libra, Sagittarius, Aquarius | —           |
| `elementLean`| —                         | fire, water                     | earth     | air                                       | —           |

Fine-only `moonHouseAdjustment`: houses 3, 7, 11 → +1; houses 1, 4, 8, 12 → −1; else 0. One house step (magnitude 1) can never flip a clear pole (threshold 2) on its own — this is how Slate's Moon-in-11th (score −3 + 1 = −2) is absorbed without flipping her `selfContained` lane.

Lanes: `score ≥ +2` → `communityOriented`; `score ≤ −2` → `selfContained`; else `balanced`.

## 8. coreFormula — register skeleton + per-sign vocabulary (key-pure)

Shape (register skeleton): `<structure pole> + <softness/flow pole> + <accent/depth signature>`.
Slot 1 and slot 3 come from the **Venus-sign row**; slot 2 from the **Moon-sign row**. Moon rows and Venus accent slots compose **verbatim across registers**; Venus structure entries carry a small register/element-inflected variant set (golden findings: Hearth, Ripple).

Selection order for slot 1: register-specific variant if present → water-dominant variant if `dominantElement == water` and present → default.

### Venus vocabulary (SG-1 golden entries; SG-2 ships full dataset tables)

| Venus sign  | Structure (slot 1)                                                     | Accent (slot 3)          | Anchor        |
| ----------- | ---------------------------------------------------------------------- | ------------------------ | ------------- |
| Aries       | clean impact                                                           | one hot accent           | Ember         |
| Taurus      | structure *(water-dominant variant: soft structure)*                   | a touch of quiet depth   | Slate, Ripple |
| Gemini      | crisp separation                                                       | one clever contrast      | Zephyr        |
| Cancer      | soft shelter                                                           | one sentimental keepsake | Cove, Wren    |
| Leo         | dark drama *(quietLuxury variant: quiet grandeur)*                     | one molten flash         | Cinder, Hearth|
| Virgo       | precise fit                                                            | one meticulous detail    | Flint         |
| Libra       | balanced proportions                                                   | one refined touch        | Breeze        |
| Scorpio     | close drape                                                            | one warm point of light  | Tide          |
| Sagittarius | expansive colour                                                       | one theatrical finish    | Blaze         |
| Capricorn   | enduring structure                                                     | one living texture       | Moss          |
| Aquarius    | clean geometry                                                         | one polished signal      | Frost         |
| Pisces      | weightless layers                                                      | one pearl of light       | Mist, Loom    |

### Moon vocabulary (slot 2, verbatim across registers)

| Moon sign   | Flow (slot 2)      | Anchor        |
| ----------- | ------------------ | ------------- |
| Aries       | sharp edges        | Cinder        |
| Taurus      | sensory comfort    | Moss          |
| Gemini      | light movement     | Breeze, Wren  |
| Cancer      | hidden depth       | Tide          |
| Leo         | athletic space     | Blaze         |
| Virgo       | honest fabric      | Flint, Loom   |
| Libra       | cool composure     | Frost         |
| Scorpio     | quiet undercurrent | Cove          |
| Sagittarius | fast movement      | Ember         |
| Capricorn   | softness           | Slate, Hearth |
| Aquarius    | mobile layers      | Zephyr        |
| Pisces      | blurred edges      | Mist, Ripple  |

`coreKeywords` = the three formula components + the register keyword (`quiet luxury` / `bold expression` / `versatile`).

**Key-purity test (hard requirement):** `coarseProfile(key).coreFormula == fineProfile(chart).coreFormula` for every golden chart. Both the register (vote over key inputs) and the water-dominant inflection (element is in the key) are key-pure by construction.

## 9. excludedAestheticKeywords

Positive-assertion exclusions, by register plus an orientation extension:

| Condition                     | Keywords                                                                                     |
| ----------------------------- | -------------------------------------------------------------------------------------------- |
| `quietLuxury`                 | bold, global, adventurous, expansive, loud                                                   |
| `boldExpression`              | muted, understated                                                                           |
| `versatileAdaptive`           | bold, statement, fierce, never deviate                                                       |
| `orientation == selfContained`| + community, belonging, collective, tribe                                                    |

"statement" is **not** excluded for quietLuxury: Slate's own golden ideal uses "a statement belt" positively; guides win over rules.

**Assertion-aware semantics (binding for SG-4):** these keywords flag **positive assertions only**. Avoid/pass-over content may name what it rejects ("pass over loud brights" is compliant; "a loud statement necklace completes the look" is a violation). The SG-4 validator must be section-aware or negation-aware. Validation against all 16 golden guides (2026-07-06): zero positive assertions of any profile's excluded keywords in its own guide; all matches occur in Avoid/pass-over/metadata contexts.

Runtime overlay strings (`HouseSectOverlayGenerator`) are single positive-assertion sentences by construction, so the overlay screen may use plain containment matching.

## 10. Stelliums (fine only)

A stellium = 3+ of the ten planets (Sun..Pluto) sharing a sign. Computed explicitly (not a `ChartAnalysis` field). Stelliums never alter coarse lanes (key purity); they feed the overlay conflict policy (see `profile_conflict_policy.md`). Slate's chart carries both the guide-named Capricorn stellium (Moon, Saturn, Uranus, Neptune) and a Taurus stellium (Sun, Mercury, Venus) — both reinforce her quiet lane.

## 11. Confidence

- **Fine:** `low` iff element dominance margin `< 2` (top element count minus runner-up, over the 8-slot balance) **or** the register vote was a three-way tie. Otherwise `high`. Anchors: Loom (margin 1 → low), Wren (tie → low).
- **Coarse:** the key carries no margins; `low` iff the register vote was a three-way tie.

## 12. Golden coverage

The 16 vectors in `profile_expectations.json` cover: all 12 Venus signs, all 12 Moon signs, all 4 elements, all 3 registers, all 4 metal strategies, all 3 finish lanes, all 3 temperatures, all 3 orientations, both confidence levels, and all 3 overlay policies. Every rule above reproduces every golden guide's metadata block exactly.
