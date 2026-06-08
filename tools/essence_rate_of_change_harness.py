#!/usr/bin/env python3
"""Daily Fit essence rate-of-change audit across users and days.

Calls the local inspector API (http://127.0.0.1:7777/api/inspect) for each
preset birth chart across a window of consecutive calendar days and measures
how much the 14-category style-essence profile changes day-over-day.

Metrics per (preset, engine):
  - top1_flip_rate   : fraction of consecutive day-pairs where the #1 essence changes
  - top3_change_rate : fraction of consecutive day-pairs where the visible top-3 SET changes
  - avg_top3_jaccard : mean Jaccard overlap of consecutive top-3 sets (1.0 = identical)
  - avg_l1_delta     : mean L1 distance between consecutive 14-dim score vectors
  - avg_top1_dwell   : mean run length (in days) the #1 essence stays put
  - distinct_top1    : count of distinct #1 essences seen over the window

Usage:
  python3 tools/essence_rate_of_change_harness.py [--start YYYY-MM-DD] [--days N]
      [--engines production,stage1_experimental] [--presets fire,earth,...]
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from collections import Counter
from datetime import date, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESETS_PATH = ROOT / "inspector" / "Resources" / "presets.json"
FIXTURES = ROOT / "docs" / "fixtures"
INSPECTOR_URL = "http://127.0.0.1:7777/api/inspect"

ALL_CATEGORIES = [
    "edgy", "romantic", "classic", "utility", "drama", "playful", "polished",
    "effortless", "sensual", "magnetic", "grounded", "eclectic", "minimal", "maximalist",
]

DEFAULT_PRESETS = ["fire", "earth", "air", "water", "leo"]
DEFAULT_ENGINES = ["production", "stage1_experimental"]


def preset_birth(preset: dict) -> dict:
    instant = preset["birthDateUTC"]  # e.g. 1990-04-05T05:30:00Z
    return {
        "dateISO": instant,
        "unknownTime": False,
        "latitude": preset["latitude"],
        "longitude": preset["longitude"],
        "timeZoneId": preset["timeZoneId"],
        "locationLabel": preset.get("label", preset["id"]),
    }


def inspect(preset: dict, target_date: str, engine_id: str) -> dict:
    payload = {
        "birth": preset_birth(preset),
        "targetDate": target_date,
        "options": {
            "composeBlueprint": True,
            "includeProgressed": True,
            "resetTarotHistory": True,
            "dailyFitEngineId": engine_id,
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


def essence_from_response(resp: dict) -> tuple[list[str], dict[str, float]]:
    ep = resp["dailyFit"]["payload"]["essenceProfile"]
    visible = [s["category"] for s in ep["visibleCategories"]]
    scores = {s["category"]: float(s["score"]) for s in ep["allScores"]}
    # Ensure all 14 present (0.0 default)
    full = {c: scores.get(c, 0.0) for c in ALL_CATEGORIES}
    return visible, full


def normalize(vec: dict[str, float]) -> dict[str, float]:
    total = sum(vec.values())
    if total <= 0:
        return {c: 0.0 for c in ALL_CATEGORIES}
    return {c: vec[c] / total for c in ALL_CATEGORIES}


def l1(a: dict[str, float], b: dict[str, float]) -> float:
    return sum(abs(a[c] - b[c]) for c in ALL_CATEGORIES)


def jaccard(a: list[str], b: list[str]) -> float:
    sa, sb = set(a), set(b)
    union = sa | sb
    return len(sa & sb) / len(union) if union else 1.0


def dwell_runs(seq: list[str]) -> list[int]:
    runs: list[int] = []
    if not seq:
        return runs
    cur = seq[0]
    length = 1
    for x in seq[1:]:
        if x == cur:
            length += 1
        else:
            runs.append(length)
            cur = x
            length = 1
    runs.append(length)
    return runs


def analyze(days: list[dict]) -> dict:
    """days: list of {date, visible:[..3], scores:{14}} sorted by date."""
    top1 = [d["visible"][0] for d in days]
    pairs = list(zip(days, days[1:]))
    n_pairs = len(pairs)

    top1_flips = sum(1 for a, b in pairs if a["visible"][0] != b["visible"][0])
    top3_changes = sum(1 for a, b in pairs if set(a["visible"]) != set(b["visible"]))
    jacc = [jaccard(a["visible"], b["visible"]) for a, b in pairs]
    l1s = [l1(normalize(a["scores"]), normalize(b["scores"])) for a, b in pairs]
    runs = dwell_runs(top1)

    return {
        "n_days": len(days),
        "n_pairs": n_pairs,
        "top1_flip_rate": round(top1_flips / n_pairs, 3) if n_pairs else 0.0,
        "top3_change_rate": round(top3_changes / n_pairs, 3) if n_pairs else 0.0,
        "avg_top3_jaccard": round(sum(jacc) / len(jacc), 3) if jacc else 1.0,
        "avg_l1_delta": round(sum(l1s) / len(l1s), 4) if l1s else 0.0,
        "max_l1_delta": round(max(l1s), 4) if l1s else 0.0,
        "avg_top1_dwell": round(sum(runs) / len(runs), 2) if runs else 0.0,
        "max_top1_dwell": max(runs) if runs else 0,
        "distinct_top1": len(set(top1)),
        "top1_distribution": dict(Counter(top1).most_common()),
    }


def run(start: date, n_days: int, engines: list[str], preset_ids: list[str]) -> int:
    presets = json.loads(PRESETS_PATH.read_text())
    by_id = {p["id"]: p for p in presets}
    missing = [p for p in preset_ids if p not in by_id]
    if missing:
        print(f"Unknown preset(s): {missing}. Available: {list(by_id)}", file=sys.stderr)
        return 2

    dates = [(start + timedelta(days=i)).isoformat() for i in range(n_days)]
    results: dict[str, dict] = {}
    raw_series: dict[str, dict] = {}

    for engine in engines:
        results[engine] = {}
        raw_series[engine] = {}
        for pid in preset_ids:
            preset = by_id[pid]
            days = []
            for d in dates:
                resp = inspect(preset, d, engine)
                visible, scores = essence_from_response(resp)
                days.append({"date": d, "visible": visible, "scores": scores})
            results[engine][pid] = analyze(days)
            raw_series[engine][pid] = [
                {"date": x["date"], "visible": x["visible"]} for x in days
            ]
            print(f"  [{engine}] {pid}: done ({n_days} days)", file=sys.stderr)

    FIXTURES.mkdir(parents=True, exist_ok=True)
    out_json = FIXTURES / "essence_rate_of_change.json"
    out_json.write_text(
        json.dumps(
            {
                "generated": datetime.now().astimezone().isoformat(),
                "window": {"start": dates[0], "end": dates[-1], "days": n_days},
                "engines": engines,
                "presets": preset_ids,
                "metrics": results,
                "series": raw_series,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    # Human-readable summary
    lines = [
        "Daily Fit — Essence Rate-of-Change Audit",
        f"Window: {dates[0]} .. {dates[-1]} ({n_days} days, {n_days - 1} day-pairs)",
        f"Presets: {', '.join(preset_ids)}",
        "",
        "Metric guide:",
        "  top1_flip   = % of consecutive days where the #1 essence changes",
        "  top3_change = % of consecutive days where the visible top-3 SET changes",
        "  jaccard     = mean overlap of consecutive top-3 sets (1.0 = unchanged)",
        "  L1          = mean L1 distance between consecutive normalised 14-dim vectors",
        "  dwell       = mean consecutive days the #1 essence stays put",
        "  distinct    = number of distinct #1 essences across the window",
        "",
    ]
    header = f"{'engine':<22}{'preset':<8}{'top1_flip':>10}{'top3_chg':>10}{'jaccard':>9}{'L1':>9}{'dwell':>7}{'distinct':>10}"
    for engine in engines:
        lines.append(f"--- {engine} ---")
        lines.append(header)
        for pid in preset_ids:
            m = results[engine][pid]
            lines.append(
                f"{engine:<22}{pid:<8}"
                f"{m['top1_flip_rate']:>10}{m['top3_change_rate']:>10}"
                f"{m['avg_top3_jaccard']:>9}{m['avg_l1_delta']:>9}"
                f"{m['avg_top1_dwell']:>7}{m['distinct_top1']:>10}"
            )
        # engine aggregate
        agg_keys = ["top1_flip_rate", "top3_change_rate", "avg_top3_jaccard", "avg_l1_delta", "avg_top1_dwell"]
        agg = {k: sum(results[engine][p][k] for p in preset_ids) / len(preset_ids) for k in agg_keys}
        lines.append(
            f"{engine:<22}{'MEAN':<8}"
            f"{round(agg['top1_flip_rate'], 3):>10}{round(agg['top3_change_rate'], 3):>10}"
            f"{round(agg['avg_top3_jaccard'], 3):>9}{round(agg['avg_l1_delta'], 4):>9}"
            f"{round(agg['avg_top1_dwell'], 2):>7}{'':>10}"
        )
        lines.append("")

    out_txt = FIXTURES / "essence_rate_of_change.txt"
    out_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("\n".join(lines))
    print(f"\nWrote {out_json}")
    print(f"Wrote {out_txt}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--start", default=date.today().isoformat(), help="YYYY-MM-DD window start")
    ap.add_argument("--days", type=int, default=30, help="number of consecutive days")
    ap.add_argument("--engines", default=",".join(DEFAULT_ENGINES))
    ap.add_argument("--presets", default=",".join(DEFAULT_PRESETS))
    args = ap.parse_args()

    start = datetime.strptime(args.start, "%Y-%m-%d").date()
    engines = [e.strip() for e in args.engines.split(",") if e.strip()]
    preset_ids = [p.strip() for p in args.presets.split(",") if p.strip()]
    return run(start, args.days, engines, preset_ids)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.URLError as exc:
        print(f"Inspector not reachable at {INSPECTOR_URL}: {exc}", file=sys.stderr)
        print("Start it with: cd inspector && ./run-inspector.sh", file=sys.stderr)
        raise SystemExit(1)
