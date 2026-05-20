## Task: P8 — `.env` → xcconfig sync script (OPTIONAL)

**Prerequisites:** P1 merged (xcconfig key exists).

**Phase:** P8 only. Optional tooling — skip unless requested.

### Deliverables (spec §6.1)

- `tools/sync_env_to_xcconfig.sh` (or similar)
- Patches **only** `DAILY_FIT_ENGINE_ID` in Dev/Prod xcconfig
- Must not overwrite Supabase keys or other config
- Document in README / `.env.example`

### Do NOT

- Make script mandatory for local dev
- Auto-run in CI without explicit opt-in

### Acceptance

- [ ] Script idempotent; only touches `DAILY_FIT_ENGINE_ID`
- [ ] Documented usage in README