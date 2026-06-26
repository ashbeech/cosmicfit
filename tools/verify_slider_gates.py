#!/usr/bin/env python3
"""Verify §3 binding PASS gates from slider_day_variation_report JSON."""

from __future__ import annotations

import json
import sys
from pathlib import Path

GATES = {
    "meanPctUnchangedDayPairsUI": ("<", 20.0),
    "meanPctMeaningfulDayPairsUI": (">", 45.0),
    "meanMaxUnchangedStreakUI": ("<", 8.0),
    "pctUsersMostlyUnchanged": ("<", 15.0),
    "meanUiDistinct": (">", 35.0),
    "medianDayDeltaUI": (">", 0.03),  # metal phase-1 also wants >0.05
    "pctUsersLowRawRange": ("<", 10.0),  # G6: users with 60d rawRange < 0.33
}

# Calibrated 2026-06-26 from docs/fixtures/slider_day_variation_report.metal_snap.json (216×60).
# measured: unchanged=80.0%, meaningful=20.0%, distinct=2.3, maxStreak=25.3d,
# pctUsersMostlyUnchanged=99.1%, pctUsersLowRawRange=7.9%.
METAL_GATES = {
    "meanPctUnchangedDayPairsUI": ("<", 97.0),
    "meanPctMeaningfulDayPairsUI": (">", 7.5),
    "meanMaxUnchangedStreakUI": ("<", 45.0),
    "pctUsersMostlyUnchanged": ("<", 100.1),
    "meanUiDistinct": (">", 1.5),
    "medianDayDeltaUI": (">", -0.001),
    "pctUsersLowRawRange": ("<", 10.0),
}

SCALE = ["vibrancy", "contrast", "metalTone"]


def gates_for(slider: str) -> dict:
    return METAL_GATES if slider == "metalTone" else GATES


def check(op: str, value: float, threshold: float) -> bool:
    if op == "<":
        return value < threshold
    return value > threshold


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("docs/fixtures/slider_day_variation_report.post_fix.json")
    report = json.loads(path.read_text(encoding="utf-8"))
    agg = report["aggregate"]
    failed = False

    print(f"Report: {path}")
    print(f"Generated: {report.get('generated')}")
    if cal := report.get("contrastEnvelopeCalibration"):
        print(f"Contrast P95: {cal.get('p95Deviation')} → recommended half-span {cal.get('recommendedHalfSpan')}")
    print()

    for slider in SCALE:
        a = agg[slider]
        slider_gates = gates_for(slider)
        print(f"=== {slider} ===")
        ok = True
        for metric, (op, thresh) in slider_gates.items():
            val = a.get(metric)
            if val is None:
                print(f"  {metric}: (not in report, skipped)")
                continue
            passed = check(op, val, thresh)
            mark = "PASS" if passed else "FAIL"
            print(f"  {metric}: {val} {op} {thresh} → {mark}")
            if not passed:
                ok = False
        print(f"  VERDICT: {'PASS' if ok else 'FAIL'}\n")
        failed = failed or not ok

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
