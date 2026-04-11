#!/usr/bin/env python3
"""
One-command exporter for house/sect regression input_after fixtures.

This script runs a focused XCTest that generates post-integration Blueprint JSON files:
  _reference/house_sect_regression/input_after/{fixture}.json

Default fixtures:
  - ash
  - maria
  - day_chart_venus_angular
  - night_chart_venus_cadent
"""

from __future__ import annotations

import argparse
import os
import subprocess
from pathlib import Path


DEFAULT_FIXTURES = [
    "ash",
    "maria",
    "day_chart_venus_angular",
    "night_chart_venus_cadent",
]


def main() -> int:
    parser = argparse.ArgumentParser(description="Export input_after Blueprint fixtures")
    parser.add_argument(
        "--fixtures",
        nargs="+",
        default=DEFAULT_FIXTURES,
        help="Fixture IDs to keep after export (subset of defaults)",
    )
    parser.add_argument(
        "--output-dir",
        default="_reference/house_sect_regression/input_after",
        help="Output directory for exported JSON fixtures",
    )
    parser.add_argument(
        "--scheme",
        default="Cosmic Fit",
        help="Xcode scheme to test",
    )
    parser.add_argument(
        "--destination",
        default="platform=iOS Simulator,name=iPhone 16",
        help="xcodebuild test destination",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent
    selected = list(dict.fromkeys(args.fixtures))
    unknown = [name for name in selected if name not in DEFAULT_FIXTURES]
    if unknown:
        parser.error(f"Unknown fixture IDs: {', '.join(unknown)}")

    output_dir = (repo_root / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        "xcodebuild",
        "test",
        "-scheme",
        args.scheme,
        "-destination",
        args.destination,
        "-only-testing:Cosmic FitTests/HardeningEdgeCaseTests",
    ]

    print("Running:", " ".join(cmd))
    result = subprocess.run(cmd, cwd=repo_root)
    if result.returncode != 0:
        return result.returncode

    # Keep only requested fixtures so the review loop can focus on 2-4 charts.
    for fixture in DEFAULT_FIXTURES:
        path = output_dir / f"{fixture}.json"
        if fixture not in selected and path.exists():
            path.unlink()

    print("\nExport complete.")
    for fixture in selected:
        path = output_dir / f"{fixture}.json"
        status = "OK" if path.exists() else "MISSING"
        print(f" - {fixture}: {status} ({path})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
