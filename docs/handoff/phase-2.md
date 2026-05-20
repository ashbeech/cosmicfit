## Task: P2 — Frozen payload namespacing + DEBUG invalidation

**Prerequisites:** P0 + P1 merged.

**Phase:** P2 only. Do not implement P3+ (tarot key namespacing, diagnostics fixes, Profile UI).

### Deliverables (spec §8, §17.1)

1. **`DailyFitFrozenPayloadStorage.swift`**
   - Filename: `{profileKey}_{dailyFitEngineId}_{yyyy-MM-dd}.json`
   - **Legacy load:** still read old `{profileKey}_{yyyy-MM-dd}.json` (implicit `production`); do not break existing reveals under `production`
   - **Engine mismatch (storage layer):** on `load`, if stored `dailyFitEngineId` (or implicit `production` on legacy file) ≠ `DailyFitEngineConfig.effectiveEngineId`, return `nil` (treat as stale → tab bar regenerates). Do **not** add mismatch checks in `CosmicFitTabBarController` — keep tab bar diff minimal
   - **Save path:** read `DailyFitEngineConfig.effectiveEngineId` inside storage when freezing — no `DailyFitViewController` changes required for engine id metadata

2. **`DailyFitTypes.swift`** — `DailyFitPayload`
   - Optional `dailyFitEngineId: String?` on encode/decode (custom Codable — update keys, init, encode, decode)
   - Missing on decode → `"production"`

3. **Invalidation triggers**
   - **Every launch (DEBUG and Release):** if today’s frozen/reveal state exists for the active profile but engine id ≠ `DailyFitEngineConfig.effectiveEngineId`, invalidate today (clear reveal flag and/or delete today’s namespaced file) so the next Daily Fit load regenerates
   - **P5 adds** immediate invalidation on Profile picker change — P2 only implements the mechanism + launch-time check; testing runtime switch before P5: change `Dev.xcconfig` / rebuild, or defer switch test to P5

4. **Reveal flag (§8.2):** namespace `CardRevealed_*` key with engine id **or** rely on stale-flag recovery via storage `load` returning `nil` — pick one, document in PR

Storage reads `DailyFitEngineConfig.effectiveEngineId` at save/load. No `DailyFitViewController` changes in this phase.

### Do NOT

- Namespace tarot keys (P3)
- Fix `logDailyFitDiagnostics` (P4)
- Break legacy frozen file loading for matching `production` engine
- Modify `DailyFitViewController` (§17.2)

### Acceptance

- [ ] Reveal/freeze under `production`, switch effective id to `legacy_baseline` (xcconfig rebuild **or** defer to P5 picker) → today regenerates, not stale production freeze
- [ ] Legacy `{profile}_{date}.json` loads for `production` only; returns `nil` (regenerate) when effective id is `legacy_baseline`
- [ ] Launch-time mismatch invalidates today without Profile picker (P5)
- [ ] §22 checklist complete
