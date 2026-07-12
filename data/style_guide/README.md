# Style Guide source JSON (canonical copy)

> **Status:** Current
> **Last audited:** June 2026
> **Source of truth:** `../../README.md` for app architecture; this file documents canonical Style Guide data files.

These files are the **single source of truth** for:

| File | Role |
|------|------|
| **`astrological_style_dataset.json`** | Planet–sign → style mappings for `BlueprintTokenGenerator` / `DeterministicResolver`. Produced by **`tools/generate_dataset.py`**. |
| **`blueprint_narrative_cache.json`** | Pre-generated narrative paragraphs for `NarrativeCacheLoader`. Produced/edited via **`tools/backfill_narratives.py`** and **`tools/review_tool.py`**. |
| **`blueprint_narrative_cache-2-clusters.json`** | Smaller experimental narrative cache variant. |

## App bundle

**`Cosmic Fit/Resources/`** holds **symbolic links** to the files above so Xcode includes them in the app bundle without maintaining duplicate blobs. After editing data here, rebuild the app (or run from Xcode); no manual copy step.

If symlinks are problematic on your OS, replace them with copies and document the drift risk.

## Tests & Python tools

- XCTest resolves **`data/style_guide/…`** via `StyleGuideDataURL`.
- **`tools/validate_dataset.py`** defaults to **`data/style_guide/astrological_style_dataset.json`**.
- **`tools/review_tool.py`** defaults to **`data/style_guide/blueprint_narrative_cache.json`** (`review_notes.json` lives beside that file).

## Content backup rule (hard gate)

**No user-facing copy source may be amended until a dated backup exists and its manifest is verified.** This applies to the files above plus the Swift copy sources (`HouseSectOverlayGenerator.swift`, `StyleGuideViewController.swift`) and Daily Fit copy (`TarotCards.json`, `TarotCard.swift`).

```bash
python3 tools/backup_content_sources.py backup --domain all --label <purpose-slug>
python3 tools/backup_content_sources.py list
python3 tools/backup_content_sources.py restore   # from data/content_backups/LATEST.txt
```

Backups live under `data/content_backups/{YYYY-MM-DD}_{label}/` with a `manifest.json` (byte sizes + sha256) and a `LATEST.txt` pointer. The amend scripts (`backfill_narratives.py`, `content_audit_apply.py`) enforce this as a **non-interactive hard gate**: they exit with an error unless a same-day backup exists (or `--backup-dir` points at one); `--force-no-backup` bypasses for emergencies only. Historical snapshots under `data/style_guide/backups/` remain valid; new work uses `data/content_backups/`.

## Generated reports

Markdown files such as `audit_report.md`, `colour_name_hex_audit.md`, `colour_metal_fabric_audit.md`, `colour_metal_fabric_apply_report.md`, and `narrative_palette_literal_audit.md` are generated or run-specific reports. They are useful for content QA, but they are not source-of-truth architecture docs.
