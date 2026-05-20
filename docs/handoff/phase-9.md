## Task: P9 — Root README: Daily Fit engine versioning

**Prerequisites:** P0–P5 merged (selector MVP complete). If P6/P7/P8 land later, add short notes for those capabilities in the same README section.

**Phase:** P9 only. Documentation — no registry, inspector, or app code changes unless fixing factual errors in comments elsewhere.

### Goal

Make the repo **parent `README.md`** the onboarding entry point for Daily Fit engine versioning: why it exists, how it differs from Style Guide versioning, architecture, and how to use it in Inspector and Xcode.

**Authoritative detail:** `docs/handoff/daily_fit_engine_selector_spec.md` — README is a concise guide, not a duplicate spec.

### Deliverables (spec §16 P9, §17.1)

Amend **`README.md`** (repo root). Prefer additive subsections; match existing tone (handoff reference doc). Suggested placement:

1. **§2.1 — Cosmic Fit Inspector** (existing subsection ~line 88)
   - One paragraph: header **Engine** dropdown, `dailyFitEngineId` in session/API, link to full section below
   - Note: server default from `DAILY_FIT_ENGINE_ID` in environment when starting inspector (optional)

2. **New subsection under §4.1** — e.g. **`### 4.1.1 Daily Fit engine presets (version selector)`**
   - **Why:** Run multiple calibration presets (e.g. `production` vs `legacy_baseline`) for A/B tuning and regression without forking the repo or editing `DailyFitCalibration.default` until promotion
   - **What it is not:** Not Style Guide / `BlueprintComposer` `engineVersion`; not user-facing in Release (App Store always `production`)
   - **Design (short):**
     - Single `DailyFitEngineRegistry` — canonical preset list + fingerprints
     - Same chart/transit/lunar inputs; different `DailyFitCalibration` passed into `DailyEnergyEngine` / `BlueprintLensEngine`
     - Inspector: per-request `options.dailyFitEngineId`
     - App: build-time `DAILY_FIT_ENGINE_ID` via xcconfig → Info.plist → `DailyFitEngineConfig`; DEBUG Profile override (P5)
     - Frozen payloads and tarot state namespaced per engine (P2/P3)
   - **Presets:** List ids shipped in registry (`production`, `legacy_baseline`; mention `stage1_experimental` only if P7 merged)
   - **How to use — Inspector:** dropdown, compare labels, `resetTarotHistory` when switching presets (P3 policy), link `inspector/README.md`
   - **How to use — iOS DEBUG:** `.env` documents value → copy/sync to `Dev.xcconfig` → rebuild; or Profile engine picker without rebuild; Daily Fit tab debug banner
   - **How to use — iOS Release:** always `production`; plist non-production ignored
   - **CI / tests:** Do not set `DAILY_FIT_ENGINE_ID` in default CI; tests pass explicit `calibration:` unless testing config type
   - **Further reading:** `docs/handoff/daily_fit_engine_selector_spec.md`, `docs/handoff/daily_fit_stage2_calibration_handoff.md` (calibration tuning)

3. **§2.2 XCTest environment flags** (table)
   - Row for `DAILY_FIT_ENGINE_ID` (optional local / dedicated jobs only; not default CI)

4. **Quick start / config** (§5 or existing “copy Dev.xcconfig” block ~line 574)
   - Mention `DAILY_FIT_ENGINE_ID=production` in `.env` / `Dev.xcconfig.example` alongside Supabase keys
   - If P8 merged: one line on `tools/sync_env_to_xcconfig.sh`

5. **Repo tree comment** (optional one-line under `InterpretationEngine/` or `DailyFitEngineRegistry.swift` in §3 tree) if a file entry exists there

Do **not** rewrite unrelated README sections. Do **not** paste the full spec.

### Do NOT

- Change Swift, inspector UI, or xcconfig **values** (documentation only)
- Document unreleased presets as available before P7 registers them
- Replace `inspector/README.md` — cross-link only; update inspector README in P9 only if a single factual sentence is missing (§17.3)

### Acceptance

- [ ] New developer can answer: why versioning exists, inspector vs app paths, Release vs DEBUG behaviour
- [ ] README links to `docs/handoff/daily_fit_engine_selector_spec.md`
- [ ] Inspector §2.1 and Daily Fit §4.1.1 (or equivalent) are consistent with implemented P0–P5 behaviour
- [ ] §22 checklist complete (documentation boxes)
