## Task: P3 — Per-engine tarot recency + variant rotation keys

**Prerequisites:** P0 + P1 + P2 merged.

**Phase:** P3 only. Do not change tarot scoring formulas, recency penalty ladder, or diagnostics layout.

### Deliverables (spec §9.1, §17.1)

1. **`TarotRecencyTracker.swift`**
   - Include `dailyFitEngineId` in storage keys (card key + date list key)
   - Thread engine id through public API (parameter or context from caller — minimal surface change)

2. **`TarotVariantRotationTracker.swift`**
   - Include engine id in `variantRotation_*` keys

3. **Call sites** (§17.1 — wiring only, no formula changes): pass effective/request engine id from:
   - `BlueprintLensEngine.swift` — tracker calls in selection path
   - `InspectorEngine.swift` — request `dailyFitEngineId` into diagnostics / tracker paths
   - App tab bar path uses `DailyFitEngineConfig.effectiveEngineId` (no tab bar file edits required unless a call site lives only there)

4. **`inspector/.../VerdictRunner.swift`**
   - `checkTarotRecency` must query namespaced keys (pass engine id)

5. **Inspector policy (§18.2)**
   - On engine dropdown change: auto-set `resetTarotHistory: true` on first inspect **or** document manual reset in `inspector/README.md`

### Do NOT

- Change `recencyPenalty` math or `EngineConfig`
- Change tarot cosine scoring / tie-break logic
- Rewrite diagnostics (P4)

### Acceptance

- [ ] Switching engine in inspector does not bleed tarot history between presets
- [ ] VerdictRunner recency check uses correct engine namespace
- [ ] §22 checklist complete