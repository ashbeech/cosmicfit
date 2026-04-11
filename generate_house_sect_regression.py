#!/usr/bin/env python3
"""
Build house/sect regression snapshot bundles from before/after Blueprint JSON files.

This tool is intentionally runtime-agnostic: it does not calculate charts itself.
It packages full before/after payloads, computes diffs, and enforces core invariants
for palette/pattern stability.

Usage:
  python3 generate_house_sect_regression.py \
    --fixture ash \
    --before _reference/fixtures/blueprint_input_user_1.json \
    --after _reference/house_sect_regression/input_after/ash.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def stable_list_diff(before: list[str], after: list[str]) -> tuple[list[str], list[str]]:
    before_set = set(before)
    after_set = set(after)
    added = sorted(after_set - before_set)
    removed = sorted(before_set - after_set)
    return added, removed


def build_diff(before: dict, after: dict) -> dict:
    before_code = before.get("code", {})
    after_code = after.get("code", {})

    lean_added, lean_removed = stable_list_diff(before_code.get("leanInto", []), after_code.get("leanInto", []))
    consider_added, consider_removed = stable_list_diff(before_code.get("consider", []), after_code.get("consider", []))

    narrative_keys = [
        ("style_core", ("styleCore", "narrativeText")),
        ("textures_good", ("textures", "goodText")),
        ("textures_bad", ("textures", "badText")),
        ("textures_sweet_spot", ("textures", "sweetSpotText")),
        ("palette_narrative", ("palette", "narrativeText")),
        ("occasions_work", ("occasions", "workText")),
        ("occasions_intimate", ("occasions", "intimateText")),
        ("occasions_daily", ("occasions", "dailyText")),
        ("hardware_metals", ("hardware", "metalsText")),
        ("hardware_stones", ("hardware", "stonesText")),
        ("hardware_tip", ("hardware", "tipText")),
        ("pattern_narrative", ("pattern", "narrativeText")),
        ("pattern_tip", ("pattern", "tipText")),
    ]
    changed_narratives: list[str] = []
    for key_name, path in narrative_keys:
        before_value = before[path[0]][path[1]]
        after_value = after[path[0]][path[1]]
        if before_value != after_value:
            changed_narratives.append(key_name)

    before_core_hex = [c["hexValue"] for c in before["palette"]["coreColours"]]
    after_core_hex = [c["hexValue"] for c in after["palette"]["coreColours"]]
    before_accent_hex = [c["hexValue"] for c in before["palette"]["accentColours"]]
    after_accent_hex = [c["hexValue"] for c in after["palette"]["accentColours"]]

    palette_unchanged = before_core_hex == after_core_hex and before_accent_hex == after_accent_hex
    pattern_unchanged = (
        before["pattern"]["recommendedPatterns"] == after["pattern"]["recommendedPatterns"]
        and before["pattern"]["avoidPatterns"] == after["pattern"]["avoidPatterns"]
    )

    return {
        "codeLeanIntoAdded": lean_added,
        "codeLeanIntoRemoved": lean_removed,
        "codeConsiderAdded": consider_added,
        "codeConsiderRemoved": consider_removed,
        "hardwareMetalsBefore": before["hardware"]["recommendedMetals"],
        "hardwareMetalsAfter": after["hardware"]["recommendedMetals"],
        "hardwareStonesBefore": before["hardware"]["recommendedStones"],
        "hardwareStonesAfter": after["hardware"]["recommendedStones"],
        "narrativesChanged": changed_narratives,
        "paletteUnchanged": palette_unchanged,
        "patternUnchanged": pattern_unchanged,
    }


def write_snapshot_bundle(fixture_id: str, before: dict, after: dict, output_path: Path) -> dict:
    bundle = {
        "fixtureID": fixture_id,
        "before": before,
        "after": after,
        "diff": build_diff(before, after),
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    return bundle


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate house/sect regression snapshot bundle")
    parser.add_argument("--fixture", required=True, help="Fixture ID, e.g. ash")
    parser.add_argument("--before", required=True, help="Path to baseline Blueprint JSON")
    parser.add_argument("--after", required=True, help="Path to post-integration Blueprint JSON")
    parser.add_argument(
        "--output-dir",
        default="_reference/house_sect_regression",
        help="Directory to write snapshot bundle JSON",
    )
    args = parser.parse_args()

    before = load_json(Path(args.before))
    after = load_json(Path(args.after))
    out_path = Path(args.output_dir) / f"{args.fixture}.json"
    bundle = write_snapshot_bundle(args.fixture, before, after, out_path)

    print(f"Wrote {out_path}")
    print(f"paletteUnchanged={bundle['diff']['paletteUnchanged']}")
    print(f"patternUnchanged={bundle['diff']['patternUnchanged']}")
    print(f"narrativesChanged={len(bundle['diff']['narrativesChanged'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
