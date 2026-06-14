# Daily Fit Palette Selection — Handoff Document

**Status:** Analysis complete; **no code change shipped** for palette selection strategy. Direction agreed; implementation deferred to next developer.  
**Date:** 2026-05-20  
**Audience:** Engineers or AI agents continuing Daily Fit palette / Stage 2 work.  
**Origin:** Cursor conversation between Ash (product owner / primary tester) and an AI agent auditing how daily colours are selected, especially under the `stage1_experimental` engine preset.

---

## 1. Executive summary

Ash reported that Daily Fit palette colours feel **too static and too rules-driven**, with at least one swatch (often a bright signature or grounding colour) appearing day after day. The daily message feels like “wear this dramatic colour” even when that is not appropriate for everyday dressing.

Investigation confirmed:

1. **Palette selection is shared across all engine presets** — the inspector/app engine dropdown does **not** switch palette algorithms today.
2. **Drama-driven slot allocation** in `BlueprintLensEngine.selectDailyPalette` structurally locks palette composition (statement vs grounding quotas), which prevents all three colours from rotating freely.
3. **Signature colours are not hard-coded as mandatory**, but they are classified as “statement” roles and score highly on drama/edge days — so they appear often when drama is elevated.
4. **Drama values can be stuck high** for some profiles/dates (identical vibe profile across consecutive days), which keeps the palette in the “bold day” slot regime even when the user expects variation.
5. **Stage 1 experimental** changes vibe generation and calibration but **does not branch** on palette selection — so fixing palette stickiness is **not** automatically part of switching to `stage1_experimental`.

**Agreed direction:** Make daily palette selection **less restrictive and less rules-based**. Primary lever: **remove drama slot allocation** and replace with **pure top-3 scoring** from the full candidate pool, driven by role–energy alignment + jitter. Gate the new behaviour behind a **calibration flag or engine preset** so it can be A/B tested in the inspector dropdown before promotion to production.

**Not yet implemented.** This document is the handoff for that work.

---

## 2. Problem statement (user-visible)

### 2.1 Symptoms Ash reported

| Symptom | Detail |
|---------|--------|
| Not all 3 daily colours change | Often slots 1–2 rotate while slot 3 stays fixed (e.g. Champagne) |
| Signature colour feels always “on” | Bright chart-derived signature swatches recur on bold days; feels like a forced “wear this dramatic colour” message |
| Palette feels rules-based, not signal-based | Colours seem allocated by role quotas rather than responding freely to the day’s underlying energy mix |
| Unclear root cause | Could be drama stuck high, slot rules, or both |

### 2.2 Product intent (explicit)

Ash’s desired behaviour:

- **All three daily colours should be able to change** day to day.
- **No colour role should be forced** — including signature colours. Signatures should appear when appropriate for the day’s signal, not because a slot rule reserves space for statement/signature roles.
- **Selection should be free-flowing first**, then refined based on testing — not pre-constrained by drama thresholds.
- **Prefer input-driven selection** (vibe profile → score → pick) over structural quotas.

---

## 3. Architecture: where palette selection lives

### 3.1 Pipeline overview

```
Natal + progressed + transits + lunar + date
        ↓
DailyEnergyEngine              ← Stage 1 (sourceWeights, signEnergyMap, axisTuning)
                                 mode .stage1Experimental → amplified vibe delta
        ↓
DailyEnergySnapshot            (VibeBreakdown 21-pt, DerivedAxes, dailySeed, …)
        ↓
BlueprintLensEngine            ← Stage 2 (selectionWeights, stage2Sensitivity)
                                 selectDailyPalette() ← THIS DOCUMENT’S FOCUS
        ↓
DailyFitPayload.dailyPalette   (3 DailyColourPick + allPaletteHexes)
```

### 3.2 Key files

| File | Role |
|------|------|
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | **`selectDailyPalette`** — current algorithm, role scoring, drama slot rules |
| `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` | `DailyPaletteSelection`, `DailyFitCalibration`, `Stage2Sensitivity` |
| `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift` | Engine presets (`production`, `legacy_baseline`, `stage1_experimental`) |
| `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` | Vibe generation; stage1 amplification (upstream of palette) |
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/ChartSignatureResolver.swift` | How luminary/ruler signature hexes are derived (Style Guide, not daily pick) |
| `Cosmic FitTests/BlueprintLensEngine_Payload_Tests.swift` | T4.4 palette tests encoding current slot rules |
| `inspector/Sources/CosmicFitInspectorServer/Web/app.js` | Palette selection trace UI |
| `docs/fixtures/ash_today_tomorrow_combined.txt` | Consecutive-day harness output for Ash |
| `docs/fixtures/daily_fit_calibration_report.txt` | Drama histogram + slot regime stats |

### 3.3 Style Guide vs Daily Fit palette

- **Style Guide (`CosmicBlueprint.palette`)** — permanent profile palette from `ColourEngineV4` / `BlueprintComposer`. Includes core, accent, neutrals, support, luminary signature, ruler signature, anchors.
- **Daily Fit palette (`DailyFitPayload.dailyPalette`)** — 3 colours **selected from** the Style Guide pool each day. Never invents colours outside the user’s palette.

Daily selection must only pick from the Style Guide candidate pool. The change under discussion is **how** those 3 are chosen, not **which pool** is used.

---

## 4. Engine selector: what the dropdown does and does not control

### 4.1 Registered presets (as of 2026-05-20)

| Preset id | Display name | Mode | Notes |
|-----------|--------------|------|-------|
| `production` | Production | `.standard` | Shipped calibration (`DailyFitCalibration.default`) |
| `legacy_baseline` | Legacy Baseline | `.standard` | Pre–Stage 2 weights for regression |
| `stage1_experimental` | Stage 1 Experimental (Sky Forward) | `.stage1Experimental` | Sky-heavy source weights + amplified vibe delta |

Registry: `DailyFitEngineRegistry.swift`.  
Dropdown wiring: `DailyFitEngineConfig.effectiveEngineId`, `ProfileViewController` (DEBUG), inspector.

### 4.2 What changes when you switch engines

| Lever | Affects palette? | How |
|-------|------------------|-----|
| `calibration.sourceWeights` | Indirectly | Changes `VibeBreakdown` → role scores |
| `calibration.stage2Sensitivity.paletteJitter` | Yes | Jitter range in scoring (production 0.08, stage1 0.15) |
| `mode: .stage1Experimental` | **No direct palette branch** | Branches vibe (`DailyEnergyEngine`), essence, silhouette in `BlueprintLensEngine` |
| `dailySeedPolicy` | Yes | Different `dailySeed` → different jitter tie-breaks |

### 4.3 Critical fact for implementers

**Removing drama slot allocation from `selectDailyPalette` without gating would change ALL presets simultaneously.**

The engine dropdown would **not** let you compare old slot rules vs new free-flowing selection unless you explicitly add:

- a **calibration flag** (recommended), or
- a **new engine preset**, or
- a **`DailyFitEngineMode` branch** at a central entry point.

Do **not** scatter `if engineId == "stage1_experimental"` in scoring loops. Per `docs/handoff/daily_fit_engine_selector_spec.md`, branch on `mode` or calibration at ≤2 central entry points.

---

## 5. Current algorithm (exact behaviour in code)

**Function:** `BlueprintLensEngine.selectDailyPalette(from:snapshot:calibration:)`  
**Location:** `BlueprintLensEngine.swift` (~lines 544–663)

### 5.1 Candidate pool

Collected in order, then deduped by hex (first occurrence wins):

1. `palette.coreColours`
2. `palette.accentColours`
3. `palette.neutrals` (if present)
4. `palette.supportColours` (if present)
5. `palette.lightAnchor` (if present)
6. `palette.deepAnchor` (if present)
7. `palette.luminarySignature` (if present)
8. `palette.rulerSignature` (if present)

All Style Guide bands are eligible. Anchors score via `.anchor → [.utility, .classic]` alignment and sit in the grounding pool, so they surface on classic / minimal / grounded days. Where an anchor duplicates a neutral hex, dedupe keeps the neutral (first occurrence wins).

**Deduping:** Luminary and ruler signatures often resolve to the **same hex** after LCH clamping into the family envelope. After dedupe, only one signature candidate remains.

### 5.2 Scoring

For each candidate:

```
baseScore = Σ (vibeProfile[energy] / 21.0)  for energy in roleEnergyAlignment[colour.role]
jitter    = random(0 .. paletteJitter)       using SeededRandomGenerator(seed: dailySeed)
profileBias = deterministicProfileColourBias(profileHash, hex)  // range ~0..0.012
totalScore = baseScore + jitter + profileBias
```

**Role–energy alignment table (current):**

| ColourRole | Aligned energies |
|------------|------------------|
| `.core` | classic, romantic |
| `.accent` | drama, playful |
| `.neutral` | utility, classic |
| `.support` | romantic, playful |
| `.signature` | drama, edge |
| `.statement` | drama, edge |
| `.anchor` | utility, classic |

Default fallback if role missing: `[.classic, .romantic]`.

**Calibration values:**

| Preset | `paletteJitter` |
|--------|-----------------|
| production (`Stage2Sensitivity.default`) | 0.08 |
| stage1_experimental | 0.15 |
| legacy_baseline | 0.001 |

### 5.3 Drama slot allocation (the restrictive rule)

After scoring and sorting descending, candidates split into two pools:

- **Statement pool:** roles in `{ .accent, .signature, .statement }`
- **Grounding pool:** all other roles (core, neutral, support, anchor)

**Slot quotas from drama vibe integer:**

| Drama value | maxStatementSlots | Composition |
|-------------|-------------------|-------------|
| 0–3 | 0 | 3 grounding only — **no accent/signature/statement possible** |
| 4 | 1 | 1 statement + 2 grounding |
| 5–10 | 2 | 2 statement + 1 grounding |

Selection:

```swift
selected = statementPool.prefix(actualStatement) + groundingPool.prefix(actualGrounding)
// if still < 3: fill from overall scored list, skipping used hexes
```

**Important:** Within each pool, picks are **`prefix(N)` after sort** — i.e. top N scorers, not random. Jitter only reorders when scores are close.

### 5.4 What is NOT forced

- There is **no rule** requiring luminary signature or ruler signature in the daily pick.
- There is **no rule** requiring a specific hex or name.
- Signatures are **candidates** like any other colour.

### 5.5 What IS forced (structural)

- **Number of statement vs grounding slots** is dictated by drama thresholds (above).
- On drama ≤ 3, signatures are **structurally excluded** regardless of score.
- On drama ≥ 5, **exactly 2 statement + 1 grounding** (when pools have enough candidates).
- The grounding slot is typically the **top grounding scorer**, which sticks when vibe profile is stable.

---

## 6. Diagnosis: two separate layers

### Layer A — Slot rules (palette selection bug)

Even when jitter and vibe vary, slot allocation prevents all 3 colours from changing:

- Statement slots (1–2 on bold days) rotate among top statement scorers.
- Grounding slot (3 on bold days) stays on the top grounding scorer — often unchanged for many consecutive days.

**Evidence — Ash harness (production calibration):**  
File: `docs/fixtures/ash_today_tomorrow_combined.txt`

```
Day 0: Coral, Saffron, Champagne     (drama=7, vibe identical)
Day 1: Burgundy, Tangerine, Champagne
       ↑ slots 1–2 changed          ↑ slot 3 fixed
```

Champagne is `[support]` — a grounding-pool colour. With drama=7, the engine always allocates 2 statement + 1 grounding; Champagne wins the grounding slot repeatedly.

Stage 2 calibration handoff (`daily_fit_stage2_calibration_handoff.md` §12 FAQ) explicitly notes: *“Slots 1–2 can remain fixed by drama/statement rules even when slot 3 moves.”*

### Layer B — Drama / vibe stuck high (upstream signal bug)

For synthetic Ash profile in the calibration harness, drama=7 and the **full vibe string are identical for 7+ consecutive days**:

```
Vibe: C=2 P=4 R=3 U=2 D=7 E3  (unchanged)
```

From `docs/fixtures/daily_fit_calibration_report.txt`:

- Ash profile: avg drama=7.0, min=7, max=7 over 30 days — always in **bold (2 statement / 1 grounding)** regime.
- Aggregate drama histogram (n=150): values cluster at 3, 4, 6, 7 — none at 0–2, 5, 8–10 due to 21-point quantization.
- Slot regime: 60% moderate (1 stmt), 40% bold (2 stmt), **0% quiet (0 stmt)** across 150 samples.

Stage 1 experimental **amplifies** daily delta from production anchor (`stage1VibeDeltaAmplification = 2.75` in `DailyEnergyEngine.swift`), which can push drama/edge higher — but the core palette stickiness from slot rules exists in **production too**.

**Conclusion:** Both layers contribute. **Fix slot rules first** (directly addresses “colours should be free-flowing”). Re-evaluate drama calibration separately after observing palette behaviour without slot quotas.

---

## 7. Signature colours — clarified

### 7.1 What signatures are

From `ChartSignatureResolver.swift`:

- **Luminary signature** — hex from Sun sign projected into palette family envelope.
- **Ruler signature** — hex from Ascendant domicile ruler’s sign projected into family envelope.

They live in the Style Guide as `BlueprintColour` with `role: .signature`. They are chart-personalised “hero” colours.

### 7.2 Why signatures feel “always on”

1. Classified as **statement roles** → compete for statement slots on drama ≥ 4 days.
2. Score highest when **drama + edge** vibes dominate (same alignment as accent/statement).
3. When drama is stuck at 6–7, user is always in 2-statement regime.
4. If luminary + ruler dedupe to one hex, that single signature competes with accents for 2 slots — high visibility.
5. Ash’s real Style Guide fixture (`docs/house_sect_regression/input_after/ash.json`) shows luminary and ruler both at `#724BA4` (different names: cobalt / midnight) — one deduped candidate.

**This is scoring + slot structure, not a “must include signature” rule.**

---

## 8. Spec drift: original Phase 4 vs current code

Original design (`docs/archive/daily_fit_rebuild/PHASE_4_PALETTE_TEXTURES_ASSEMBLY.md` §4.2):

1. Score all colours by role–energy alignment.
2. Pick top 3 with **soft diversity** (if top 3 same role, swap 3rd for next different role).
3. Deterministic tie-break via `dailySeed`.

**Current code replaced soft diversity with hard drama slot allocation.** The inspector’s `diversitySwapApplied` diagnostic flag does **not** implement the Phase 4 swap — it only compares final picks vs the first 3 raw candidates for trace purposes.

---

## 9. Agreed direction (not yet implemented)

### 9.1 Primary change: pure top-3 scoring

**Remove drama slot allocation.** Replace with:

1. Build candidate pool (unchanged).
2. Score all candidates (unchanged).
3. Sort by score descending.
4. Take top 3 **unique hexes**.

Drama still influences **which colours score highest** via role–energy alignment (accent/signature align with drama/edge; core/neutral align with classic/utility). No structural quotas.

### 9.2 Secondary (optional, after validation)

- **Soft role diversity nudge** (from original Phase 4): if top 3 share the same role family, swap only the 3rd pick — not a hard gate.
- **Signature scoring tweak**: only if signatures still dominate after removing slots — e.g. broaden signature alignment beyond drama+edge. **Do not implement preemptively.**

### 9.3 Explicit non-goals for this work

- Do **not** add “always include one grounding colour on bold days.”
- Do **not** add signature-specific mandatory rules.
- Do **not** increase jitter as the primary fix for stickiness.
- Do **not** change Style Guide / `ColourEngineV4` signature generation in this pass.
- Do **not** change drama/vibe calibration until palette selector change is validated.

---

## 10. Recommended implementation plan

### Step 1 — Add a calibration-controlled strategy flag

Extend `DailyFitCalibration.Stage2Sensitivity` (or adjacent struct) with something like:

```swift
enum PaletteSelectionStrategy: Equatable {
    case dramaSlots      // current behaviour — production default
    case pureScoring     // proposed free-flowing behaviour
}
```

Set on registry presets:

| Preset | Recommended initial value |
|--------|---------------------------|
| `production` | `.dramaSlots` (unchanged until promotion) |
| `legacy_baseline` | `.dramaSlots` |
| `stage1_experimental` | `.pureScoring` (for A/B in dropdown) |

**Alternative:** New preset id e.g. `palette_freeflow` with same calibration as production but `.pureScoring` — isolates palette change from stage1 vibe amplification.

Include the flag in fingerprint serialization (`DailyFitEngineRegistry.canonicalCalibrationString`) so preset identity is stable.

### Step 2 — Refactor `selectDailyPalette`

```swift
switch calibration.stage2Sensitivity.paletteSelectionStrategy {
case .dramaSlots:
    // existing statement/grounding pool logic
case .pureScoring:
    // sort scored, take top 3 unique hexes
}
```

Pass `mode` only if needed; prefer calibration flag for A/B isolation.

### Step 3 — Update tests

**Remove or rewrite** T4.4 tests in `BlueprintLensEngine_Payload_Tests.swift` that encode slot rules:

| Current test | Current assertion | Action |
|--------------|-------------------|--------|
| T4.4 low drama | 0 statement colours | Replace: pureScoring may pick statement if score wins; dramaSlots keeps old rule |
| T4.4 boundary drama=3 | 0 statement | Same |
| T4.4a moderate drama | exactly 1 statement | Remove for pureScoring path |
| T4.4b high drama | ≥1 grounding | Remove for pureScoring path |
| T4.4c no duplicate hex | 3 unique hexes | **Keep** for both strategies |

**Add new tests:**

- Pure scoring: top 3 match sorted scores (deterministic fixture + fixed seed).
- Pure scoring: all 3 slots can differ across consecutive-day snapshots (fixture-based).
- Strategy flag: production preset still uses dramaSlots until explicitly switched.
- No daily pick outside Style Guide pool (existing T4.2 — keep).

### Step 4 — Update diagnostics / inspector

- `BlueprintLensEngine` payload trace: log which strategy was used.
- Inspector palette trace (`app.js`): show strategy + selected picks with scores.
- Debug print block (~line 1317): replace drama slot label with strategy name when pureScoring.

### Step 5 — Validate before production promotion

1. **Ash consecutive days** — regenerate `docs/fixtures/ash_today_tomorrow_combined.txt` with pureScoring; confirm slot 3 rotates.
2. **Inspector** — compare `production` vs `stage1_experimental` (or dedicated preset) on real profile.
3. **98-day harness** — measure palette churn, signature appearance rate, role distribution.
4. **On-device** — bust frozen payload cache (`DailyFitFrozenPayloadStorage`) when comparing; revealed days persist old picks.

Promote `.pureScoring` to `production` only after Ash sign-off.

---

## 11. Expected behaviour after pureScoring

| Scenario | dramaSlots (current) | pureScoring (proposed) |
|----------|----------------------|------------------------|
| drama=7 | Always 2 stmt + 1 grounding | Top 3 by score — any role mix |
| Stable vibe, high drama | Grounding slot stuck (e.g. Champagne) | All 3 can still stick if scores dominate — but not structurally locked |
| Low drama day | 0 statement colours guaranteed | Signatures can appear if they score high (unlikely due to alignment) |
| Signature appearance | Often on bold days (statement pool) | Only when drama+edge scores beat all other candidates |
| User message | Implicit “bold accent + anchor” structure | “Today’s highest-alignment colours” |

---

## 12. Relationship to other in-flight work

| Related doc / work | Relationship |
|--------------------|--------------|
| `docs/handoff/daily_fit_stage2_calibration_handoff.md` | Stage 2 jitter shipped; did not remove slot rules. Palette churn metrics improved but slot 3 stickiness remains. |
| `docs/handoff/daily_fit_engine_selector_spec.md` | Engine registry conventions — use calibration/mode branching, not per-id string checks. |
| `docs/handoff/daily_fit_sky_forward_handoff.md` | Stage 1 sky-forward vibe work — orthogonal unless drama amplification is tuned later. |
| `docs/handoff/phase-7.md` | Stage 1 experimental mode — vibe/essence only; palette not in scope there. |

**Serialize work:** Palette strategy change can land independently of Stage 1 vibe tuning. If both change in one PR, A/B via dropdown becomes ambiguous.

---

## 13. Validation checklist for next developer

- [ ] Confirm which preset(s) enable `.pureScoring` in registry
- [ ] Run `BlueprintLensEngine_Payload_Tests` — update T4.4 as specified
- [ ] Regenerate or run Ash today/tomorrow harness — document slot 3 behaviour
- [ ] Inspector: palette trace shows scores + strategy
- [ ] Compare signature appearance rate: dramaSlots vs pureScoring over 30 days for ashProfile
- [ ] Verify frozen payload invalidation when engine id / fingerprint changes
- [ ] Confirm Release build still hard-locks to production preset (`DailyFitEngineConfig`)
- [ ] Update `README.md` §Daily palette row if production promoted (currently says “drama-driven slot allocation”)

---

## 14. FAQ

**Q: Is signature colour always forced in the daily pick?**  
A: **No.** There is no mandatory signature rule. Signatures appear frequently because they are statement-role candidates that score well on drama/edge-heavy days and because slot rules reserve statement slots when drama ≥ 4.

**Q: If I switch to stage1_experimental in the dropdown, does palette selection change?**  
A: **Not algorithmically.** Only jitter (0.15 vs 0.08), vibe input (amplified delta), and seed policy change. Slot rules are identical.

**Q: Would removing slot rules fix everything Ash sees?**  
A: **It fixes structural stickiness** (forced grounding slot, statement quotas). If vibe profile is identical day-to-day, some stickiness may remain because scores do not change. That is Layer B — address after validating Layer A.

**Q: Should we fix drama being stuck at 7 first?**  
A: **No — fix palette selector first.** Then measure whether drama amplification or quantization still causes unwanted stickiness or over-bold messaging.

**Q: Should quiet days (drama ≤ 3) still exclude bright accents?**  
A: **Under pureScoring, not structurally.** Classic/utility-heavy days should naturally favour neutrals/cores via scoring. If testing shows inappropriate accents on quiet days, use soft scoring weights — not hard slot bans.

**Q: What about anchors?**  
A: Anchors remain excluded from the candidate pool (unchanged). They are not daily wear recommendations.

---

## 15. Code references (starting points)

```
BlueprintLensEngine.selectDailyPalette     — BlueprintLensEngine.swift ~569
roleEnergyAlignment / statementRoles       — BlueprintLensEngine.swift ~548–560
DailyFitEngineRegistry presets             — DailyFitEngineRegistry.swift
Stage2Sensitivity.default                  — DailyFitTypes.swift (~416)
generateVibeProfileStage1Amplified         — DailyEnergyEngine.swift ~357
T4.4 palette tests                         — BlueprintLensEngine_Payload_Tests.swift ~403
```

---

## 16. Related artifacts

| Artifact | Path |
|----------|------|
| Ash today vs tomorrow harness | `docs/fixtures/ash_today_tomorrow_combined.txt` |
| Drama histogram + slot regimes | `docs/fixtures/daily_fit_calibration_report.txt` |
| Real Ash Style Guide JSON | `docs/house_sect_regression/input_after/ash.json` |
| Stage 2 calibration handoff | `docs/handoff/daily_fit_stage2_calibration_handoff.md` |
| Engine selector spec | `docs/handoff/daily_fit_engine_selector_spec.md` |
| Original Phase 4 palette spec | `docs/archive/daily_fit_rebuild/PHASE_4_PALETTE_TEXTURES_ASSEMBLY.md` |
| Inspector web UI | `inspector/Sources/CosmicFitInspectorServer/Web/app.js` |

---

## 17. Conversation decisions log (for continuity)

| # | Question / topic | Conclusion |
|---|------------------|------------|
| 1 | Are signature colours always forced? | No — structural statement slots + scoring bias, not a dedicated signature rule |
| 2 | Why don’t all 3 colours change? | Drama slot rules + top-of-pool selection + stable vibe scores |
| 3 | Is this stage1_experimental only? | No — shared `selectDailyPalette` for all presets |
| 4 | Can dropdown toggle new palette behaviour? | Not without explicit calibration flag or new preset |
| 5 | Desired direction | Less restrictive, less rules-based, free-flowing top-3 scoring first |
| 6 | Implementation status | **Not started** — this document is the handoff |

---

*End of handoff.*
