#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 Slate diff pack (Phase 3f review deliverable).

Produces a side-by-side markdown pack for the human stop gate:
  current shipped v1 cache  vs  regenerated SG-3 v2 cache  vs  hand-authored ideal
for the reference chart Slate, cache-key by cache-key, with a per-section note on
which ideal elements are now present.

Slate is the reference chart and is EXCLUDED from standard scoring (non-circularity
rule); this pack is a genre/voice comparison for human eyes, not a pass/fail score.

Usage:
  python3 tools/sg3_diff_pack.py \
    --v1 data/content_backups/2026-07-07_pre-phase-3/data/style_guide/blueprint_narrative_cache.json \
    --v2 data/style_guide/blueprint_narrative_cache_sg3.json \
    --out docs/style_guide/sg3/slate_diff_pack.md
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sg_validation as V
from sg_profile import coarse_profile_from_key

REPO_ROOT = Path(__file__).resolve().parent.parent
SLATE = "venus_taurus__moon_capricorn__earth_dominant"

SECTION_ORDER = [
    "style_core", "palette_narrative",
    "textures_good", "textures_bad", "textures_sweet_spot",
    "occasions_work", "occasions_intimate", "occasions_daily",
    "hardware_metals", "hardware_stones", "hardware_tip",
    "accessory_1", "accessory_2", "accessory_3",
    "pattern_narrative", "pattern_tip",
]


def v1_text(cache: dict, key: str, section: str) -> str:
    obj = cache.get(key, {})
    val = obj.get(section) if isinstance(obj, dict) else None
    if isinstance(val, str):
        return val
    if isinstance(val, dict):
        return val.get("text", "")
    return ""


def v2_text(cache: dict, key: str, section: str) -> str:
    obj = cache.get(key, {})
    val = obj.get(section) if isinstance(obj, dict) else None
    if isinstance(val, dict):
        return val.get("text", "")
    return ""


def genre_notes(prof, v2_obj: dict) -> list[str]:
    notes = []
    sc = v2_obj.get("style_core", {}).get("text", "") if isinstance(v2_obj.get("style_core"), dict) else ""
    notes.append(("coreFormula stated verbatim in Blueprint",
                  prof.core_formula in sc))
    pal = v2_obj.get("palette_narrative", {})
    pal_t = pal.get("text", "") if isinstance(pal, dict) else ""
    notes.append(("palette free of season words", not V.find_season_words(pal_t)))
    notes.append(("palette rankedItems present (colours by role)",
                  bool(isinstance(pal, dict) and pal.get("rankedItems"))))
    allt = " ".join(s.get("text", "") for s in v2_obj.values() if isinstance(s, dict))
    notes.append(("zero em/en dashes across the guide", not V.find_dashes(allt)))
    notes.append(("zero banned tics across the guide", not V.find_banned_tics(allt)))
    closing = v2_obj.get("closing", "")
    notes.append(("closing ends with coreFormula",
                  bool(closing) and closing.rstrip(".").endswith(prof.core_formula)))
    acc1 = v2_obj.get("accessory_1", {})
    notes.append(("accessory opening ties to formula final term",
                  isinstance(acc1, dict) and prof.core_keywords[2] in acc1.get("text", "")))
    return notes


def build(v1: dict, v2: dict, ideal_path: Path) -> str:
    prof = coarse_profile_from_key(SLATE)
    v2_obj = v2.get(SLATE, {})
    out: list[str] = []
    out.append("# SG-3 Slate Diff Pack (current v1 vs regenerated v2 vs ideal)\n")
    out.append(f"Reference chart **Slate** (`{SLATE}`). Excluded from standard scoring "
               "per the non-circularity rule; this is a genre/voice comparison.\n")
    out.append(f"**coreFormula:** `{prof.core_formula}`  \n")
    out.append(f"**profile:** register={prof.aesthetic_register}, temperature={prof.temperature}, "
               f"metals={prof.metal_strategy}, finish={prof.finish_lane}\n")
    out.append(f"**Ideal reference:** `{ideal_path.relative_to(REPO_ROOT)}` "
               "(read alongside this pack; the full authored guide is the target).\n")

    out.append("\n## Genre checklist on the regenerated Slate\n")
    for label, ok in genre_notes(prof, v2_obj):
        out.append(f"- [{'x' if ok else ' '}] {label}")

    out.append("\n## Section-by-section: current v1 vs regenerated v2\n")
    for sk in SECTION_ORDER:
        out.append(f"\n### `{sk}`\n")
        cur = v1_text(v1, SLATE, sk).strip()
        new = v2_text(v2, SLATE, sk).strip()
        out.append("**Current (shipped v1):**\n")
        out.append(f"> {cur if cur else '_(absent in v1 cache)_'}\n")
        out.append("**Regenerated (SG-3 v2):**\n")
        out.append(f"> {new if new else '_(absent / quarantined)_'}\n")
    if v2_obj.get("closing"):
        out.append(f"\n### closing (new in v2)\n> _{v2_obj['closing']}_\n")
    return "\n".join(out)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--v1", required=True)
    ap.add_argument("--v2", required=True)
    ap.add_argument("--ideal", default=str(REPO_ROOT / "docs" / "style_guide" / "golden" / "slate_ideal.md"))
    ap.add_argument("--out", default=str(REPO_ROOT / "docs" / "style_guide" / "sg3" / "slate_diff_pack.md"))
    args = ap.parse_args()
    v1 = json.loads(Path(args.v1).read_text())
    v2 = json.loads(Path(args.v2).read_text())
    md = build(v1, v2, Path(args.ideal))
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(md)
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
