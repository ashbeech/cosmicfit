# Phase 0 — B3 cache-key trace & remedy decision (Sky Forward v1.0.2)

> Recorded before any engine edit, per plan Phase 0. Determines the Phase-7 blocking cache-invalidation remedy.

## Finding

The **only** persistent cache of a computed daily result is
`Cosmic Fit/Core/Utilities/DailyFitFrozenPayloadStorage.swift`, which writes one JSON
file per `(profileKey, engineId, calendar-day)` to `Documents/DailyFitFrozen/`.

The cache key is the **filename**, built by `namespacedFileURL(date:profileKey:engineId:)`
(`DailyFitFrozenPayloadStorage.swift:196-201`):

```
"\(sanitizedProfileKey(profileKey))_\(engineId)_\(day).json"
```

`engineId` comes from `DailyFitEngineConfig.effectiveEngineId`, which is **`"production"`**
in Release (`DailyFitEngineConfig.swift:71-81`). Load-time validation (`:230-244`) and
`purgeStaleArtifacts` (`:277-331`) both compare **only** `resolvedDailyFitEngineId == effectiveId`.
The persisted `DailyFitPayload` has **no fingerprint field** (`DailyFitTypes.swift:294-300`).

There is **no remote/Supabase cache** of daily payloads (`SupabaseSyncService` syncs only
profile + Blueprint/Style Guide). On-disk frozen storage is the whole story.

`fingerprint` and `marketingVersion` are computed and shown in diagnostics/Inspector/Profile
only — never written into any cache key.

## Consequence

At cutover, `productionId` stays `"production"` and only the fingerprint moves
(1.0.1 → 1.0.2 calibration). **The frozen cache will NOT bust** — any day already frozen
under v1.0.1 keeps serving the stale payload. The release ships invisibly for those days.
This is the single most likely way to ship an invisible release (plan B3).

## Remedy decision → **Remedy A (fingerprint-in-key)**

Plan guidance: "fingerprint-in-key preferred; id-bump fallback." Constraint: `productionId`
must stay `"production"` (it anchors display/version, reveal flags, recency namespaces).
Remedy B (bump the id string) would ripple through reveal flags + recency namespaces and
reset unrelated history. **Remedy A is chosen** and is contained to the storage layer.

### Phase-7 edit sites (all in `DailyFitFrozenPayloadStorage.swift` unless noted)
1. `namespacedFileURL` (`:196-201`) — add current-calibration fingerprint (short prefix) as a
   filename segment: `..._\(engineId)_\(fpShort)_\(day).json`. The fingerprint is
   `DailyFitEngineRegistry.fingerprint(for: DailyFitEngineConfig.effectiveCalibration)`
   (or the descriptor's `.fingerprint`).
2. `load` engine-match (`:230-244`) + `hasValidFrozenPayload` (`:333-349`) — compare the new
   fingerprint segment, not just the engine id.
3. `purgeStaleArtifacts` (`:277-331`) + `engineIdFromNamespacedFilename` (`:351-367`) — teach the
   filename parser about the new `_<fp>_` segment; purge files whose fingerprint segment != current.
4. (If a persisted equality check is preferred over filename-only) stamp `calibrationFingerprint`
   onto `DailyFitPayload` (`DailyFitTypes.swift:284-300` + `CodingKeys` + `withDailyFitEngineId`) via
   `decodeIfPresent` (backward compatible).
5. Reveal-flag keys (`DailyFitRevealPersistence.revealedFlagKey` / `sliderEntranceAnimationFlagKey`,
   `:29-49`) are un-namespaced for the production id → a fresh fingerprint means the recomputed day
   is served, but the reveal flag would still read "revealed". Confirm at Phase 7 whether reveal
   flags must also carry the fingerprint so a cutover day re-reveals (likely yes for the B3 proof).

### Phase-7 proof test (Rung 5, blocking)
Seed a v1.0.1-cached daily payload for `(profile, date)`, cut over to v1.0.2, assert the served
output is the **v1.0.2** result, not the stale cache.

## Reference: fingerprint source
`DailyFitEngineRegistry.fingerprint(for:)` (`DailyFitEngineRegistry.swift:111-115`) = SHA-256 over
`canonicalCalibrationString(for:)` (`:224-302`). Distinct per calibration → distinct once
`skyVibeWeights`/`lunarSignificanceCoeff` land in the canonical string (Phase 2).
