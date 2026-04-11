#!/usr/bin/env python3
"""
House/Sect Regression Review Helper

Reads snapshot artifacts from `_reference/house_sect_regression/*.json` and
generates a reviewer-friendly scorecard markdown report.

Usage:
  python3 review_house_sect_regression.py
  python3 review_house_sect_regression.py --snapshots-dir _reference/house_sect_regression --output _reference/house_sect_regression/SCORECARD.md
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_snapshots(directory: Path) -> list[dict]:
    snapshots: list[dict] = []
    for path in sorted(directory.glob("*.json")):
        with path.open("r", encoding="utf-8") as f:
            snapshots.append(json.load(f))
    return snapshots


def specificity_gain(snapshot: dict) -> int:
    before = snapshot["before"]["code"]
    after = snapshot["after"]["code"]
    before_count = len(before.get("leanInto", [])) + len(before.get("consider", []))
    after_count = len(after.get("leanInto", [])) + len(after.get("consider", []))
    return after_count - before_count


def rough_actionability_rate(snapshot: dict) -> float:
    directives = snapshot["after"]["code"].get("leanInto", []) + snapshot["after"]["code"].get("consider", [])
    if not directives:
        return 0.0
    actionable_verbs = (
        "choose", "prioritize", "build", "wear", "use", "invest", "keep", "let", "treat",
        "stick", "trust", "focus", "balance", "avoid", "dress", "seek", "draw"
    )
    actionable = 0
    for directive in directives:
        text = directive.strip().lower()
        if any(text.startswith(v + " ") for v in actionable_verbs):
            actionable += 1
    return actionable / len(directives)


def build_report(snapshots: list[dict]) -> str:
    if not snapshots:
        return "# House/Sect Regression Scorecard\n\nNo snapshots found.\n"

    lines: list[str] = []
    lines.append("# House/Sect Regression Scorecard")
    lines.append("")
    lines.append("Auto-generated from `_reference/house_sect_regression/*.json`.")
    lines.append("Manual reviewer sign-off is required for contradiction and identity-retention gates.")
    lines.append("")
    lines.append("## Mechanical Gates")
    lines.append("")
    lines.append("| Fixture | Palette unchanged | Pattern unchanged | Specificity gain | Rough actionability |")
    lines.append("|---|---:|---:|---:|---:|")

    specificity_pass_count = 0
    for snapshot in snapshots:
        fixture_id = snapshot.get("fixtureID", "<unknown>")
        diff = snapshot["diff"]
        gain = specificity_gain(snapshot)
        if gain >= 1:
            specificity_pass_count += 1
        actionability = rough_actionability_rate(snapshot)
        lines.append(
            f"| `{fixture_id}` | {'yes' if diff['paletteUnchanged'] else 'no'} | "
            f"{'yes' if diff['patternUnchanged'] else 'no'} | {gain:+d} | {actionability:.0%} |"
        )

    lines.append("")
    lines.append("## Manual Review Checklist")
    lines.append("")
    lines.append("- [ ] **Directive actionability ≥ 80%** (human rubric)")
    lines.append("- [ ] **Contradiction rate = 0** between base narratives and overlays")
    lines.append("- [ ] **Specificity gain**: at least +1 directive in 3/4 fixtures")
    lines.append("- [ ] **Identity retention**: Ash + Maria still read as same core identity")
    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append(f"- Specificity gain pass count (auto): **{specificity_pass_count}/{len(snapshots)}**")
    lines.append("- Actionability metric above is heuristic-only; human rubric is the source of truth.")
    lines.append("")

    for snapshot in snapshots:
        fixture_id = snapshot.get("fixtureID", "<unknown>")
        diff = snapshot["diff"]
        lines.append(f"### {fixture_id}")
        lines.append("")
        lines.append(f"- Code lean-into added: {len(diff.get('codeLeanIntoAdded', []))}")
        lines.append(f"- Code consider added: {len(diff.get('codeConsiderAdded', []))}")
        lines.append(f"- Narrative sections changed: {', '.join(diff.get('narrativesChanged', [])) or '(none)'}")
        lines.append(f"- Metals before/after: {diff.get('hardwareMetalsBefore', [])} -> {diff.get('hardwareMetalsAfter', [])}")
        lines.append(f"- Stones before/after: {diff.get('hardwareStonesBefore', [])} -> {diff.get('hardwareStonesAfter', [])}")
        lines.append("")
        lines.append("- Reviewer notes:")
        lines.append("  - ")
        lines.append("")

    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate house/sect regression scorecard")
    parser.add_argument(
        "--snapshots-dir",
        default="_reference/house_sect_regression",
        help="Directory containing fixture snapshot JSON files",
    )
    parser.add_argument(
        "--output",
        default="_reference/house_sect_regression/SCORECARD.md",
        help="Markdown output path",
    )
    args = parser.parse_args()

    snapshots_dir = Path(args.snapshots_dir)
    output_path = Path(args.output)

    snapshots = load_snapshots(snapshots_dir)
    report = build_report(snapshots)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(report, encoding="utf-8")
    print(f"Wrote {output_path}")
    print(f"Snapshots processed: {len(snapshots)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
