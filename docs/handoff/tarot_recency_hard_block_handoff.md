# Tarot Recency Hard-Block — Handoff

**Date**: 2026-06-10  
**Status**: Implementation complete, **not committed**  
**Triggered by**: Wren 14-day audit — `Six of Wands` repeating despite existing recency machinery  
**Scope**: Daily Fit tarot selection (production + stage-1 bridge paths)

---

## Problem Statement

During a manual audit of 8 users' 14-day Daily Fit exports, **Wren** showed heavy Tarot repetition (`Six of Wands` on many consecutive days). The team expected `TarotRecencyTracker` to prevent this.

**Root cause (confirmed):**

1. `TarotRecencyTracker.getCooldownCards()` existed and was designed for a **3-day hard block**, but was **never called** in the selection path.
2. Recency was only applied as a **soft subtractive penalty** in `TarotCardScoring.recencyPenalty()` (max 0.7).
3. For profiles with strong astro alignment to one card (Wren → high visibility / drama / classic / action), that card's base score could **overcome** the penalty every day.
4. The narrative layer (`DailyNarrativeSelector`, `DailyNarrativeCoherence`) does **not** enforce card recency — it only scores energy-vector alignment between the plan's `tarotDirective` and the selected card after selection.

**Not a bug:** Inspector multi-day compare correctly accumulates recency history (`resetTarotHistory` is not sent during range loads). Storage and retrieval were working; enforcement was not.

---

## Solution Delivered

**Two-tier recency model** (now actually wired):

| Tier | Window | Mechanism | Where |
|------|--------|-----------|-------|
| **Hard block** | Last 3 days (`daysAgo` 1–3) | Card removed from candidate pool entirely | `BlueprintLensEngine.selectTarotAndStyleEditWithBridgeTrace` |
| **Soft penalty** | Days 4–10 | Score subtraction (0.12–0.25) + frequency escalation | `TarotCardScoring.recencyPenalty` (unchanged) |

Single enforcement point: `selectTarotAndStyleEditWithBridgeTrace` is the unified entry for:
- Production / nil-intent path
- Stage-1 narrative bridge path (`NarrativeTarotBridgeSelector`)
- `generatePayloadWithTrace` (delegates to the same method for actual selection)

---

## Code Changes

### 1. `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift`

In `selectTarotAndStyleEditWithBridgeTrace`:

```swift
let cooldownCards = TarotRecencyTracker.shared.getCooldownCards(...)
let eligibleCards = cooldownCards.isEmpty
    ? allCards
    : allCards.filter { !cooldownCards.contains($0.card.name) }
```

- **Bridge path**: passes `eligibleCards` to `NarrativeTarotBridgeSelector.select(allCards: eligibleCards, ...)`
- **Production path**: scores only `eligibleCards`
- **Diagnostics** (`printDiagnostics`): logs hard-blocked card names when non-empty

**Intentionally unchanged:** `generatePayloadWithTrace` still scores **all** cards for inspector trace display (top-10 table). Blocked cards may still appear as high scorers in the trace even though they cannot be selected. This is diagnostic-only.

### 2. `Cosmic Fit/InterpretationEngine/TarotRecencyTracker.swift`

- Exposed `static let cooldownDayCount = 3` (public) for diagnostics/UI references
- `getCooldownCards()` unchanged — now actively used

### 3. `Cosmic FitTests/NarrativeTarotBridge_Tests.swift`

Added `cooldownHardBlock()`:
- Runs 7-day Briar stage-1 sweep with isolated trackers
- Asserts no card repeats on consecutive days
- Asserts no card repeats within any 3-day sliding window

---

## Tests Run (passing)

```bash
xcodebuild test -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:"Cosmic FitTests/NarrativeTarotBridge_Tests"

xcodebuild test -scheme "Cosmic Fit" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:"Cosmic FitTests/TarotScoringPathIntegrity_Tests"

xcodebuild test -scheme "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:"Cosmic FitTests/DailyFitSkyForwardV2_Tests" \
  -only-testing:"Cosmic FitTests/DailyNarrativePlan_Tests" \
  -only-testing:"Cosmic FitTests/NarrativeCoherence_Tests"
```

Build also verified: `xcodebuild build -scheme "Cosmic Fit" -destination "platform=iOS Simulator,name=iPhone 16"`

---

## Git State

**This fix is uncommitted.** Only these 3 files belong to this work item:

```
M Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift
M Cosmic Fit/InterpretationEngine/TarotRecencyTracker.swift
M Cosmic FitTests/NarrativeTarotBridge_Tests.swift
```

The working tree has many other unrelated narrative-layer / colour-engine changes. **Do not bundle this fix into a mega-commit** unless Ash explicitly wants that.

Suggested commit message:

```
Enforce 3-day tarot cooldown as hard block in selection path.

getCooldownCards() existed but was never wired into card selection;
recency was only a soft penalty strong astro matches could override.
```

---

## Follow-Up Work (for next dev)

### P0 — Validate the original bug is fixed

1. **Re-export Wren 14-day** from Inspector (2026-05-23 → 2026-06-05 window used in audit).
2. Count unique tarot cards and check `Six of Wands` frequency.
3. **Expected**: no card appears twice within any 3-day window; overall variety should improve vs pre-fix export.

Wren fixture stub exists but tests are disabled pending natal sign verification:

- `Cosmic FitTests/NarrativeFixtures.swift` — `wrenHash`, `wrenNatalSigns`
- `@Test("Wren contrast window", .disabled("Awaiting inspector-derived natal signs"))`

Consider adding a `wren14DayNoTarotRepeat()` test once natal signs are verified (mirror `cooldownHardBlock` but on Wren profile).

### P1 — Inspector UX clarity

Inspector tarot score table (`inspector/.../Web/app.js`) still shows all cards ranked by score with recency penalty. It does **not** indicate which cards were hard-blocked.

**Suggestion:** Surface `cooldownCards` in the diagnostic payload and mark blocked rows in the UI (e.g. strikethrough or "BLOCKED" badge). Otherwise reviewers may think the engine "picked the wrong card" when the top scorer was excluded.

`VerdictRunner.checkTarotRecency` already checks post-hoc (fail if selected card was in last 3 days). With the hard block, this should now consistently **pass** for multi-day sweeps. Re-run verdicts on a Wren compare range to confirm.

### P2 — Edge cases to be aware of

| Edge case | Behaviour today | Action if problematic |
|-----------|-----------------|----------------------|
| **Same-day re-run** | If today's card is already stored, `daysAgo == 0` → card is in cooldown set → selection may differ on second run | Exclude `daysAgo == 0` from `getCooldownCards` if idempotent same-day re-runs are required |
| **Empty eligible pool** | Falls back to `The Fool` | Extremely unlikely (78 cards, 3-day window). No change needed unless seen in prod |
| **Narrative plan coherence** | `DailyNarrativeCoherence` scores `tarotMatch` on energy vector only, not card identity | By design — recency is a selection concern, not a plan concern |
| **Direct `NarrativeTarotBridgeSelector.select` calls in tests** | Tests that pass raw `allCards` bypass the hard block unless they go through `BlueprintLensEngine` | Keep test calls routed through pipeline or pass pre-filtered cards intentionally |

### P3 — Optional tuning (only if Ash wants more variety)

- Increase `cooldownDayCount` from 3 → 4 or 5
- Strengthen soft penalty tiers in `TarotCardScoring.recencyPenalty` for days 4–10
- Add per-preset recency tuning via `DailyFitCalibration` (currently hardcoded — see `docs/handoff/daily_fit_engine_selector_spec.md`)

**Do not tune until Wren re-export confirms 3-day hard block is sufficient.**

---

## Architecture Reference

```
DailyFitPipeline.generateWithTrace
  └─ BlueprintLensEngine.selectTarotAndStyleEditWithBridgeTrace   ← HARD BLOCK HERE
       ├─ TarotRecencyTracker.getCooldownCards() → eligibleCards
       ├─ [stage-1] NarrativeTarotBridgeSelector.select(allCards: eligibleCards)
       │    └─ TarotCardScoring.scoreCard(..., recentSelections)  ← SOFT PENALTY
       └─ [production] score eligibleCards directly
            └─ TarotRecencyTracker.storeCardSelection()
```

**Narrative layer (no recency enforcement):**

```
DailyNarrativeSelector.select → DailyNarrativePlan.tarotDirective (energy vector)
DailyNarrativeCoherence.validate → tarotMatch (vector cosine similarity only)
```

Recency is intentionally **not** in the plan/coherence contract. The fix keeps it at the Blueprint lens selection layer where cards are actually chosen.

---

## Prior Conversation Context

Full audit and investigation transcript: agent session `554fd8c2-cd9d-4371-8557-f593409c9399`

Key findings from that session:
- 8-user 14-day audit quantified slider range, essence turnover, narrative cohesion
- Wren's astro profile strongly aligns with `Six of Wands` (drama, classic, playful, visibility axes)
- Soft penalty simulation showed Six of Wands still winning after penalty subtraction
- Inspector `loadCompareRange` confirmed recency history accumulates correctly across days

---

## Exit Checklist for Next Dev

- [ ] Wren 14-day re-export shows improved tarot variety (no 3-day repeats)
- [ ] Optional: Wren-specific unit test once natal signs verified
- [ ] Optional: Inspector UI marks hard-blocked cards in score table
- [ ] Commit the 3-file fix (isolated from other WIP)
- [ ] Confirm `VerdictRunner` tarot_recency passes on multi-day Wren compare

---

**STOP after validation + commit unless Ash requests tuning or inspector UI work.**
