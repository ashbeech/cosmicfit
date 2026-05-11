# Style Guide source JSON (canonical copy)

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
