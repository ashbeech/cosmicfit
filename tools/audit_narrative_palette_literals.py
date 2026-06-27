#!/usr/bin/env python3
"""
Cosmic Fit — Audit narrative cache for hardcoded palette colour literals.

Scans Group B narrative sections (pattern_tip, pattern_narrative,
hardware_metals, hardware_stones, hardware_tip) for literal colour names
that should be replaced with {core_colour_*} / {accent_colour_*} placeholders
so rendered text matches the V4 palette shown on the Style Guide Palette screen.

Outputs:
  data/style_guide/narrative_palette_literal_audit.json
  data/style_guide/narrative_palette_literal_audit.md

Usage:
  python3 tools/audit_narrative_palette_literals.py
  python3 tools/audit_narrative_palette_literals.py --suggest
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

from doc_banner import generated_report_banner

REPO = Path(__file__).resolve().parents[1]
CACHE_PATH = REPO / "data/style_guide/blueprint_narrative_cache.json"
DATASET_PATH = REPO / "data/style_guide/astrological_style_dataset.json"
OUT_JSON = REPO / "data/style_guide/narrative_palette_literal_audit.json"
OUT_MD = REPO / "data/style_guide/narrative_palette_literal_audit.md"

SCAN_SECTIONS = frozenset([
    "pattern_tip", "pattern_narrative",
    "hardware_metals", "hardware_stones", "hardware_tip",
])

PALETTE_COLOUR_LITERALS: list[str] = [
    # Multi-word and plural forms first (longest match wins)
    "burnt siennas",
    "burnt sienna",
    "warm ochre",
    "cobalt blue",
    "deep cobalt",
    "electric blue",
    "fire red",
    "silver grey",
    "bright coral",
    "deep coral",
    "jet black",
    "ochres",
    "siennas",
    # Single-word palette terms
    "ochre",
    "sienna",
    "cobalt",
    "coral",
]

# Phrases that contain a colour word but describe metal/gem finishes, not
# garment palette colours — safe to leave as editorial prose.
ALLOWLIST_PHRASES: list[str] = [
    "matte silver",
    "cold steel",
    "brushed steel",
    "brushed silver",
    "industrial silver",
    "matte silver-grey",
    "silver-grey",
    "unpolished silver",
    "polished silver",
    "thick matte silver",
    "heavy steel",
    "cold silver",
]

_PLACEHOLDER_RE = re.compile(r"\{[a-z_0-9]+\}")


def _build_patterns() -> list[tuple[re.Pattern, str]]:
    """Build regex patterns for each literal, sorted longest-first to avoid
    partial matches (e.g. 'burnt siennas' before 'burnt sienna')."""
    sorted_literals = sorted(PALETTE_COLOUR_LITERALS, key=len, reverse=True)
    patterns = []
    for lit in sorted_literals:
        pat = re.compile(r"\b" + re.escape(lit) + r"\b", re.IGNORECASE)
        patterns.append((pat, lit))
    return patterns


def _strip_placeholders(text: str) -> str:
    """Replace {placeholder} tokens with whitespace so they don't interfere
    with colour detection."""
    return _PLACEHOLDER_RE.sub(" ", text)


def _is_allowlisted(text: str, match_start: int, match_end: int) -> bool:
    """Check if the match is part of an allowlisted phrase."""
    window_start = max(0, match_start - 30)
    window_end = min(len(text), match_end + 30)
    window = text[window_start:window_end].lower()
    for phrase in ALLOWLIST_PHRASES:
        if phrase in window:
            return True
    return False


def _suggest_replacement(literal: str, section: str) -> str:
    """Suggest a placeholder replacement based on the literal and section."""
    lit = literal.lower()
    if lit in ("burnt sienna", "burnt siennas", "warm ochre", "ochres", "ochre", "sienna", "siennas"):
        return "{core_colour_1}"
    if lit in ("cobalt blue", "deep cobalt", "cobalt", "fire red", "electric blue", "bright coral", "deep coral", "coral"):
        return "{accent_colour_1}"
    if lit == "silver grey":
        return "{core_colour_2}"
    if lit == "jet black":
        return "{core_colour_1}"
    return "{core_colour_1}"


def audit(cache: dict, suggest: bool = False) -> list[dict]:
    patterns = _build_patterns()
    violations = []

    for cluster_key in sorted(cache.keys()):
        sections = cache[cluster_key]
        for section_key in sorted(SCAN_SECTIONS):
            text = sections.get(section_key, "")
            if not text:
                continue
            searchable = _strip_placeholders(text)
            for pat, literal in patterns:
                for m in pat.finditer(searchable):
                    if _is_allowlisted(text, m.start(), m.end()):
                        continue
                    entry = {
                        "cluster": cluster_key,
                        "section": section_key,
                        "literal": literal,
                        "position": m.start(),
                        "context": searchable[max(0, m.start() - 40):m.end() + 40].strip(),
                    }
                    if suggest:
                        entry["suggested_placeholder"] = _suggest_replacement(literal, section_key)
                    violations.append(entry)

    return violations


def write_json(violations: list[dict], path: Path) -> None:
    report = {
        "total_violations": len(violations),
        "by_section": {},
        "by_literal": {},
        "violations": violations,
    }
    section_counts: Counter = Counter()
    literal_counts: Counter = Counter()
    for v in violations:
        section_counts[v["section"]] += 1
        literal_counts[v["literal"]] += 1
    report["by_section"] = dict(section_counts.most_common())
    report["by_literal"] = dict(literal_counts.most_common())

    with open(path, "w") as f:
        json.dump(report, f, indent=2)


def write_md(violations: list[dict], path: Path) -> None:
    section_counts: Counter = Counter()
    literal_counts: Counter = Counter()
    for v in violations:
        section_counts[v["section"]] += 1
        literal_counts[v["literal"]] += 1

    lines = [
        "# Narrative palette literal audit",
        "",
        *generated_report_banner(
            script="tools/audit_narrative_palette_literals.py",
            command="python3 tools/audit_narrative_palette_literals.py",
        ),
        f"**Total violations: {len(violations)}**",
        "",
        "## By section",
        "",
        "| Section | Count |",
        "|---------|-------|",
    ]
    for s, c in section_counts.most_common():
        lines.append(f"| `{s}` | {c} |")

    lines += [
        "",
        "## By literal",
        "",
        "| Literal | Count |",
        "|---------|-------|",
    ]
    for l, c in literal_counts.most_common():
        lines.append(f"| {l} | {c} |")

    lines += ["", f"See `{OUT_JSON.name}` for full violation details.", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit narrative cache for hardcoded palette colour literals")
    parser.add_argument("--suggest", action="store_true", help="Include placeholder replacement suggestions")
    args = parser.parse_args()

    with open(CACHE_PATH) as f:
        cache = json.load(f)

    violations = audit(cache, suggest=args.suggest)

    write_json(violations, OUT_JSON)
    write_md(violations, OUT_MD)

    print(f"Audit complete: {len(violations)} violations found")
    print(f"  JSON: {OUT_JSON}")
    print(f"  MD:   {OUT_MD}")

    if violations:
        sys.exit(1)
    else:
        print("All clean — no hardcoded palette colour literals in target sections.")


if __name__ == "__main__":
    main()
