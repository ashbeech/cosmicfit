# Profile conflict policy (SG-1, Phase 1e)

**Status:** Draft, part of SG-1 (awaiting SG-1 gate review)
**Swift implementation:** `ChartAestheticProfile` (`overlayPolicy`, `confidence`) + `HouseSectOverlayGenerator` (variant selection + excluded-keyword screen)
**Referenced by:** SG-4 handoff table (aesthetic-lane validator consumes `excludedAestheticKeywords`; this file defines the runtime half of the contract)

Governs what happens when **fine** chart signals (stelliums, houses, element margins) disagree with the **coarse** cache lane (Venus sign + Moon sign + dominant element) that the cached prose was written to.

---

## 1. Thresholds

| Signal                   | Threshold                                                                                          |
| ------------------------ | --------------------------------------------------------------------------------------------------- |
| Element dominance margin | top element count − runner-up (8-slot balance: 7 classical planets + Asc). `< 2` = slim margin      |
| Register vote            | 3 votes (element, Venus sign, Moon sign); winner needs ≥ 2                                          |
| Orientation pole         | additive score threshold ±2; the fine Moon-house adjustment has magnitude 1 and cannot flip a pole  |
| Stellium                 | 3+ of the ten planets in one sign                                                                   |

## 2. Tie-breaks (neutral lanes)

- Register three-way split → `versatileAdaptive` (never bold, never quiet by default).
- Orientation score in (−2, +2) → `balanced`.
- Finish arithmetic lands mid-scale → `mixed`.
- Every tie-break marks `confidence = low`.

Golden anchors: Loom (`balanced` / `mixedFree` / `mixed` / low) is the authored picture of "the engine hedges gracefully"; Wren is the authored picture of a genuine conflict.

## 3. Confidence

- `high`: register vote decisive AND (fine only) element margin ≥ 2.
- `low`: any tie-break fired, or (fine only) element margin < 2.

Low confidence never asserts a bold lane; see §4.

## 4. Fine-vs-coarse conflict resolution (priority order)

1. **Suppress** (mechanical enforcement: the excluded-keyword screen in `HouseSectOverlayGenerator.screened`). Any overlay sentence positively asserting one of the profile's `excludedAestheticKeywords` is dropped, never appended against the cache prose. Overlay strings are single positive-assertion sentences, so plain containment matching is sound at this call site.
2. **Neutral wording** (register/orientation variants). MC Sagittarius text, Moon-11th text, and `domainPairImplication` carry per-lane variants; off-lane charts get the moderate variant instead of the strong one.
3. **Documented cache variant** — only if a class of charts systematically needs it; must be proposed in a decision record, never silently introduced. No case identified in SG-1.

The coarse lane is **never flipped** by a fine signal, and `coreFormula` is never altered (key-purity rule).

## 5. overlayPolicy derivation (fine profile)

| Condition                                                                                                              | Policy                |
| ----------------------------------------------------------------------------------------------------------------------- | --------------------- |
| A stellium's register character conflicts with the coarse register **and** one side of the conflict is `boldExpression` | `suppressConflicting` |
| else `confidence == low`                                                                                                 | `neutralPreferred`    |
| otherwise                                                                                                                | `full`                |

- Only a bold-vs-non-bold mismatch is a genuine conflict; quiet vs versatile is a mild difference, not a contradiction.
- A **reinforcing** stellium changes nothing (Slate's Capricorn + Taurus stelliums, Mist's Pisces, Blaze's Sagittarius → `full`).
- Wren (Aries stellium + fire dominance vs coarse versatile lane) → `suppressConflicting`: prose stays true to the coarse lane (soft, quick, sheltering); the chart's heat may only surface through fabric function and pace, never as bold/statement/fierce vocabulary. Enforced mechanically because `bold`, `statement`, `fierce` sit in Wren's excluded keywords.
- Loom (slim margin, no stellium) → `neutralPreferred`.

## 6. Worked test cases (from the SG-1 plan)

1. *Fine says bold, coarse key maps to earth-dominant quietLuxury cluster:* impossible via the register vote (element is in the key), so the only route is a bold stellium — resolved as `suppressConflicting`; bold overlay text is dropped by the keyword screen. → **suppress, not override.**
2. *Chart with 2 fire / 2 earth / 2 air (+2 water) planets:* margin 0 → `confidence = low`, `neutralPreferred`; register resolved by whatever majority exists or the versatile tie-break.
3. *Strong fine signals, weak coarse key:* fine signals only modulate `orientation`/`confidence`/`overlayPolicy`; the coarse lanes and formula stand. → **suppress, not override.**
