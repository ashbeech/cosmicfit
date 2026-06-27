# Cosmic Fit — developer tools

> **Status:** Current
> **Last audited:** June 2026
> **Source of truth:** `../README.md` for app architecture; this file documents local tool usage only.

Python utilities for datasets, Style Guide narrative QA, content auditing, and regression helpers. **Not** used by the iOS app build.

## Setup

Create a virtual environment and install dependencies (from the **repository root**):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r tools/requirements.txt
```

**Grammar checks** (`grammar_error` in the content audit) use LanguageTool via `language-tool-python`, which requires **Java 8+**:

```bash
java -version   # must succeed; install OpenJDK if missing
```

Run scripts from the **repository root**. Canonical Style Guide JSON lives under **`data/style_guide/`** (see **`data/style_guide/README.md`**).

```bash
python3 tools/validate_dataset.py
python3 tools/review_tool.py --port 8420
```

## Style Guide content audit

Audits every user-visible Style Guide string (narrative cache, dataset, composed blueprints, runtime overlays/fallbacks, rendered Group B templates) and produces actionable reports.

```bash
# One-time: extract Swift runtime strings for audit
python3 tools/extract_runtime_style_guide_strings.py

# Full audit (writes audit_report.json, audit_report.md, audit_handoff_pack.json)
python3 tools/content_audit.py --format all

# Audit specific layers only
python3 tools/content_audit.py --sources dataset,blueprints

# Web UI — browse all items, triage issues, export handoff packs
python3 tools/content_audit_tool.py --port 8422
```

Open http://localhost:8422. Use **Run Audit** to start a fresh scan, **Pause Audit** to halt mid-run, and **Export Final Handoff** for a triage-filtered pack (excludes `false_positive`, `acknowledged`, and `fixed` items).

The UI also loads `audit_apply_log.json` and shows **before/after correction diffs**, handoff priority at correction time, and amendment status (applied / failed / skipped). Filter sidebar by **amended** to review only corrected items. If the audit report is older than the apply log, a banner prompts you to re-run the audit.

Output files are written to `data/style_guide/`:

| File | Purpose |
|------|---------|
| `audit_report.json` | Full report — all items plus issues |
| `audit_report.md` | Human-readable issue digest |
| `audit_handoff_pack.json` | Complete developer handoff pack |
| `audit_handoff_final.json` | Triage-filtered handoff (from UI export) |
| `audit_review_notes.json` | Manual triage state from the web UI |
| `audit_progress.json` | Live audit progress for the UI |

Markdown audit outputs are generated reports, not architecture handoffs. Use the root `README.md` for current app behaviour and `docs/README.md` for documentation status labels.

## Audit correction (apply fixes)

Applies deterministic mechanical fixes and AI-generated rewrites using the handoff pack as a queue.

**Before the first apply run**, snapshot canonical sources:

```bash
python3 tools/backup_style_guide_sources.py backup --label 2026-06-16
python3 tools/backup_style_guide_sources.py list
# Restore if needed:
python3 tools/backup_style_guide_sources.py restore
```

Backups live under `data/style_guide/backups/`; the latest path is in `LATEST_PRE_CORRECTION.txt`.

```bash
# 1. Mechanical fixes only (fast, no API key needed)
python3 tools/content_audit_apply.py --phase mechanical --priority critical,high

# 2. AI rewrites via Gemini (batched; needs GEMINI_API_KEY in .env)
# Uses google.genai SDK. Set GEMINI_MODEL=gemini-3.1-pro-preview (default if unset).
python3 tools/content_audit_apply.py --phase rewrite --priority critical,high --resume

# 3. Both phases in one run
python3 tools/content_audit_apply.py --phase all --priority critical,high,medium,low

# 4. Pilot run (dry-run, limited)
python3 tools/content_audit_apply.py --phase all --dry-run --limit 50

# 5. Verify after corrections
python3 tools/content_audit_apply.py --phase mechanical --verify
```

Progress is tracked in `data/style_guide/audit_apply_log.json` and `audit_apply_progress.json`. Use `--resume` to skip already-applied actions.

**SynthID single-image drop** (needs `scripts/.venv` for torch/diffusers):

```bash
cd scripts && source .venv/bin/activate
pip install flask   # once, if not already installed in this venv
python ../tools/synthid_drop_tool.py --port 8421
```

Opens http://localhost:8421 — drag an image, submit. Uses the same settings as `run_full_synthid_removal.sh` (0.04 × 3 passes, 768px tiles, 128 overlap). All synthid I/O is under repo-root `Resources/` (outside the Xcode bundle): drop tool → `synthid_drop_inbox/`, `synthid_drop_desynthid/`, `synthid_drop_state/`; batch originals → `originals/` / `originals_desynthid/`; backups & candidates → `.synthid_backups/`, `.synthid_baseline/`, `.synthid_candidates/`, `.synthid_originals_backup/`, `.synthid_originals_candidates/`.

Full catalogue and behaviour are documented in the root **`README.md`** (§2.1–2.2).

**Daily Fit sign-energy validation** (requires local inspector on `127.0.0.1:7777`):

```bash
cd inspector && ./run-inspector.sh   # separate terminal
python3 tools/sign_energy_inspector_harness.py
```

Writes sign-energy validation artefacts under `docs/fixtures/` when the harness runs. Treat those outputs as generated QA reports, not current architecture docs.

## Documentation audit

Checks maintained Markdown docs for broken links, stale architecture terms, and missing status metadata:

```bash
python3 tools/audit_docs.py
```
