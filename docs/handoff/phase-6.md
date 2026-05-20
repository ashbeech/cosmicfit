## Task: P6 — Inspector side-by-side engine compare (OPTIONAL)

**Prerequisites:** P0–P5 merged. **This phase is optional** — not required for selector MVP.

**Phase:** P6 only.

### Deliverables (spec §7.5 v2)

- Same birth profile + same UTC date, **two engine columns** (e.g. `production` vs `legacy_baseline`)
- Separate tarot state per column (relies on P3 namespacing + explicit engine id per request)
- Labels: date + engine id per pane
- Does not replace existing “compare days” mode — additive UI

### Do NOT

- Block or refactor P0–P5 behaviour
- Add new presets or tune calibrations

### Acceptance

- [ ] Side-by-side engine compare works for two registry ids on one date
- [ ] §22 checklist complete