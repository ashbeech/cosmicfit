#!/usr/bin/env python3
"""Slider range measurement harness for the Daily Fit narrative layer.

Runs cohort users across 60 consecutive days via the inspector API and captures:
  - scalePresentation.{vibrancy,contrast,metalTone}.displayPosition
  - silhouetteProfile.{masculineFeminine,angularRounded,structuredDraped}

Produces per-user and aggregate statistics for slider range coverage.

Usage:
    python3 tools/slider_range_harness.py [--start YYYY-MM-DD] [--days 60]
        [--cohort synthetic_cohort|presets] [--subset 50]
        [--parallel 4]

Output:
    docs/fixtures/slider_range_report.json
    docs/fixtures/slider_range_report.txt
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
import urllib.error
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "docs" / "fixtures"
INSPECTOR_URL = "http://127.0.0.1:7777/api/inspect"
ENGINE = "stage1_experimental"

SLIDERS = [
    "vibrancy", "contrast", "metalTone",
    "masculineFeminine", "angularRounded", "structuredDraped",
]

SCALE_SLIDERS = {"vibrancy", "contrast", "metalTone"}
SILHOUETTE_SLIDERS = {"masculineFeminine", "angularRounded", "structuredDraped"}


def load_cohort(cohort_name: str, subset: int | None) -> list[dict]:
    if cohort_name == "presets":
        path = ROOT / "inspector" / "Resources" / "presets.json"
    else:
        path = ROOT / "inspector" / "Resources" / "synthetic_cohort.json"
    users = json.loads(path.read_text(encoding="utf-8"))
    if subset and subset < len(users):
        users = users[:subset]
    return users


def inspect(user: dict, target_date: str) -> dict:
    payload = {
        "birth": {
            "dateISO": user["birthDateUTC"],
            "unknownTime": False,
            "latitude": user["latitude"],
            "longitude": user["longitude"],
            "timeZoneId": user["timeZoneId"],
            "locationLabel": user.get("label", user["id"]),
        },
        "targetDate": target_date,
        "options": {
            "composeBlueprint": True,
            "includeProgressed": True,
            "resetTarotHistory": True,
            "dailyFitEngineId": ENGINE,
        },
    }
    req = urllib.request.Request(
        INSPECTOR_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        return json.load(resp)


def extract_sliders(resp: dict) -> dict[str, float | None]:
    payload = resp["dailyFit"]["payload"]
    values: dict[str, float | None] = {}

    sp = payload.get("scalePresentation")
    if sp:
        for slider in SCALE_SLIDERS:
            env = sp.get(slider)
            values[slider] = float(env["displayPosition"]) if env else None
    else:
        for slider in SCALE_SLIDERS:
            values[slider] = None

    sil = payload.get("silhouetteProfile", {})
    for slider in SILHOUETTE_SLIDERS:
        val = sil.get(slider)
        values[slider] = float(val) if val is not None else None

    return values


def histogram(values: list[float], bins: int = 10) -> list[int]:
    counts = [0] * bins
    for v in values:
        idx = min(int(v * bins), bins - 1)
        counts[idx] += 1
    return counts


def tertile(v: float) -> int:
    if v < 1 / 3:
        return 0
    elif v < 2 / 3:
        return 1
    else:
        return 2


def analyze_user(user_id: str, days_data: list[dict[str, float | None]]) -> dict:
    result: dict = {"userId": user_id, "sliders": {}}
    for slider in SLIDERS:
        values = [d[slider] for d in days_data if d[slider] is not None]
        if not values:
            result["sliders"][slider] = {
                "min": None, "max": None, "range": 0.0,
                "mean": None, "stddev": 0.0,
                "histogram": [0] * 10,
                "tertileCoverage": 0,
                "stuckInOneTertile": True,
                "rangeLt03": True,
                "rangeGt08": False,
                "nDays": 0,
            }
            continue

        mn, mx = min(values), max(values)
        rng = mx - mn
        tertiles_seen = set(tertile(v) for v in values)

        result["sliders"][slider] = {
            "min": round(mn, 6),
            "max": round(mx, 6),
            "range": round(rng, 6),
            "mean": round(statistics.fmean(values), 6),
            "stddev": round(statistics.pstdev(values), 6) if len(values) > 1 else 0.0,
            "histogram": histogram(values),
            "tertileCoverage": len(tertiles_seen),
            "stuckInOneTertile": len(tertiles_seen) == 1,
            "rangeLt03": rng < 0.3,
            "rangeGt08": rng > 0.8,
            "nDays": len(values),
        }
    return result


def run_user(user: dict, dates: list[str]) -> tuple[str, list[dict[str, float | None]]]:
    days_data = []
    for d in dates:
        try:
            resp = inspect(user, d)
            sliders = extract_sliders(resp)
            days_data.append(sliders)
        except Exception as e:
            print(f"  WARN: {user['id']} @ {d}: {e}", file=sys.stderr)
            days_data.append({s: None for s in SLIDERS})
    return user["id"], days_data


def run(start: date, n_days: int, cohort_name: str, subset: int | None, parallel: int) -> int:
    users = load_cohort(cohort_name, subset)
    dates = [(start + timedelta(days=i)).isoformat() for i in range(n_days)]

    print(f"Slider range harness: {len(users)} users × {n_days} days", file=sys.stderr)
    print(f"Cohort: {cohort_name}, start: {dates[0]}, end: {dates[-1]}", file=sys.stderr)

    user_analyses: list[dict] = []

    if parallel > 1:
        with ThreadPoolExecutor(max_workers=parallel) as pool:
            futures = {pool.submit(run_user, u, dates): u["id"] for u in users}
            for i, future in enumerate(as_completed(futures)):
                uid, days_data = future.result()
                user_analyses.append(analyze_user(uid, days_data))
                if (i + 1) % 10 == 0:
                    print(f"  {i+1}/{len(users)} users complete", file=sys.stderr)
    else:
        for i, user in enumerate(users):
            uid, days_data = run_user(user, dates)
            user_analyses.append(analyze_user(uid, days_data))
            if (i + 1) % 10 == 0:
                print(f"  {i+1}/{len(users)} users complete", file=sys.stderr)

    # Aggregate stats
    aggregate: dict = {}
    for slider in SLIDERS:
        ranges = [u["sliders"][slider]["range"] for u in user_analyses
                  if u["sliders"][slider]["range"] is not None and u["sliders"][slider]["nDays"] > 0]
        stuck = sum(1 for u in user_analyses if u["sliders"][slider]["stuckInOneTertile"])
        lt03 = sum(1 for u in user_analyses if u["sliders"][slider]["rangeLt03"])
        gt08 = sum(1 for u in user_analyses if u["sliders"][slider]["rangeGt08"])
        n = len(ranges)

        aggregate[slider] = {
            "meanRange": round(statistics.fmean(ranges), 4) if ranges else 0.0,
            "medianRange": round(statistics.median(ranges), 4) if ranges else 0.0,
            "pctStuckOneTertile": round(stuck / len(user_analyses) * 100, 1) if user_analyses else 0.0,
            "pctRangeLt03": round(lt03 / len(user_analyses) * 100, 1) if user_analyses else 0.0,
            "pctRangeGt08": round(gt08 / len(user_analyses) * 100, 1) if user_analyses else 0.0,
            "nUsers": n,
        }

    report = {
        "generated": datetime.now().astimezone().isoformat(),
        "engine": ENGINE,
        "cohort": cohort_name,
        "nUsers": len(users),
        "window": {"start": dates[0], "end": dates[-1], "days": n_days},
        "aggregate": aggregate,
        "users": user_analyses,
    }

    FIXTURES.mkdir(parents=True, exist_ok=True)
    out_json = FIXTURES / "slider_range_report.json"
    out_json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    # Text summary
    lines = [
        "Slider Range Report",
        f"Engine: {ENGINE}",
        f"Cohort: {cohort_name} ({len(users)} users)",
        f"Window: {dates[0]} .. {dates[-1]} ({n_days} days)",
        f"Generated: {report['generated']}",
        "",
        "=== AGGREGATE ===",
        f"{'slider':<20}{'meanRange':>10}{'medRange':>10}{'%stuck':>8}{'%<0.3':>8}{'%>0.8':>8}",
    ]
    for slider in SLIDERS:
        a = aggregate[slider]
        lines.append(
            f"{slider:<20}{a['meanRange']:>10.4f}{a['medianRange']:>10.4f}"
            f"{a['pctStuckOneTertile']:>8.1f}{a['pctRangeLt03']:>8.1f}{a['pctRangeGt08']:>8.1f}"
        )

    lines += ["", "=== PER-USER STUCK FLAGS (first 20) ==="]
    for u in user_analyses[:20]:
        stuck_sliders = [s for s in SLIDERS if u["sliders"][s]["stuckInOneTertile"]]
        if stuck_sliders:
            lines.append(f"  {u['userId']}: stuck on {', '.join(stuck_sliders)}")

    out_txt = FIXTURES / "slider_range_report.txt"
    out_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print(f"\nWrote {out_json}")
    print(f"Wrote {out_txt}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--start", default=date.today().isoformat())
    ap.add_argument("--days", type=int, default=60)
    ap.add_argument("--cohort", default="synthetic_cohort", choices=["synthetic_cohort", "presets"])
    ap.add_argument("--subset", type=int, default=None,
                    help="Use only first N users from cohort (for faster iteration)")
    ap.add_argument("--parallel", type=int, default=4,
                    help="Number of parallel requests to inspector")
    args = ap.parse_args()
    start = datetime.strptime(args.start, "%Y-%m-%d").date()
    return run(start, args.days, args.cohort, args.subset, args.parallel)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.URLError as exc:
        print(f"Inspector not reachable at {INSPECTOR_URL}: {exc}", file=sys.stderr)
        print("Start it with: cd inspector && ./run-inspector.sh", file=sys.stderr)
        raise SystemExit(1)
