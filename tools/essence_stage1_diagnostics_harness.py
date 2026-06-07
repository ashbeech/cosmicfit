#!/usr/bin/env python3
"""Stage1-experimental essence rate-of-change diagnostics.

Focused on the `stage1_experimental` engine only. For each preset birth chart
across a window of days it captures, per day:
  - the visible top-3 essences
  - the full 14-category score vector
  - the chart-anchor top-3 (natal baseline, should be ~constant per user)
  - the dominant transit planets (the daily astrology driver)

It then quantifies WHY the daily rate of change is low by correlating the
(near-static) dominant outer-planet transits with the essence categories they
boost via `stage1TransitEssenceCategories`.

Two passes:
  daily   : N consecutive days  -> day-to-day rate of change
  monthly : 1st of each month    -> shows essences DO move on transit timescales

Usage:
  python3 tools/essence_stage1_diagnostics_harness.py [--start YYYY-MM-DD]
      [--days 60] [--months 12] [--presets fire,earth,air,water,leo]
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESETS_PATH = ROOT / "inspector" / "Resources" / "presets.json"
FIXTURES = ROOT / "docs" / "fixtures"
INSPECTOR_URL = "http://127.0.0.1:7777/api/inspect"
ENGINE = "stage1_experimental"

ALL_CATEGORIES = [
    "edgy", "romantic", "classic", "utility", "drama", "playful", "polished",
    "effortless", "sensual", "magnetic", "grounded", "eclectic", "minimal", "maximalist",
]

# From BlueprintLensEngine.stage1TransitEssenceCategories — which category each
# transiting planet boosts in stage1 essence scoring.
TRANSIT_TO_CATEGORY = {
    "Mars": "drama", "Venus": "romantic", "Sun": "magnetic", "Moon": "sensual",
    "Mercury": "playful", "Jupiter": "maximalist", "Saturn": "minimal",
    "Uranus": "edgy", "Neptune": "sensual", "Pluto": "edgy",
}
# Rough daily motion (deg/day) — illustrates which transits are "fast" vs "slow".
PLANET_SPEED = {
    "Moon": "fast", "Mercury": "fast", "Venus": "fast", "Sun": "fast",
    "Mars": "medium", "Jupiter": "slow", "Saturn": "slow",
    "Uranus": "slow", "Neptune": "slow", "Pluto": "slow",
}

DEFAULT_PRESETS = ["fire", "earth", "air", "water", "leo"]


def preset_birth(preset: dict) -> dict:
    return {
        "dateISO": preset["birthDateUTC"],
        "unknownTime": False,
        "latitude": preset["latitude"],
        "longitude": preset["longitude"],
        "timeZoneId": preset["timeZoneId"],
        "locationLabel": preset.get("label", preset["id"]),
    }


def inspect(preset: dict, target_date: str) -> dict:
    payload = {
        "birth": preset_birth(preset),
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


def extract_day(resp: dict) -> dict:
    payload = resp["dailyFit"]["payload"]
    diag = resp["dailyFit"]["diagnostics"]
    ep = payload["essenceProfile"]
    visible = [s["category"] for s in ep["visibleCategories"]]
    scores = {s["category"]: float(s["score"]) for s in ep["allScores"]}
    full = {c: scores.get(c, 0.0) for c in ALL_CATEGORIES}
    anchor = ep.get("chartAnchorScores") or []
    anchor_sorted = sorted(anchor, key=lambda s: -float(s["score"]))
    anchor_top3 = [s["category"] for s in anchor_sorted[:3]]
    transits = diag.get("transitSummaries", []) or []
    # de-dup planets preserving order, take top 3 by listed strength
    seen = []
    for t in transits:
        p = t.get("transitPlanet")
        if p and p not in seen:
            seen.append(p)
        if len(seen) >= 3:
            break
    return {
        "visible": visible,
        "scores": full,
        "anchorTop3": anchor_top3,
        "topTransits": seen,
    }


def normalize(vec: dict[str, float]) -> dict[str, float]:
    total = sum(vec.values())
    if total <= 0:
        return {c: 0.0 for c in ALL_CATEGORIES}
    return {c: vec[c] / total for c in ALL_CATEGORIES}


def l1(a: dict[str, float], b: dict[str, float]) -> float:
    return sum(abs(a[c] - b[c]) for c in ALL_CATEGORIES)


def jaccard(a: list[str], b: list[str]) -> float:
    sa, sb = set(a), set(b)
    u = sa | sb
    return len(sa & sb) / len(u) if u else 1.0


def analyze(days: list[dict]) -> dict:
    pairs = list(zip(days, days[1:]))
    n = len(pairs)
    top1 = [d["visible"][0] for d in days]

    top1_flips = sum(1 for a, b in pairs if a["visible"][0] != b["visible"][0])
    top3_changes = sum(1 for a, b in pairs if set(a["visible"]) != set(b["visible"]))
    l1s = [l1(normalize(a["scores"]), normalize(b["scores"])) for a, b in pairs]
    jac = [jaccard(a["visible"], b["visible"]) for a, b in pairs]

    # per-category volatility: stddev of normalised score across the window
    norm_days = [normalize(d["scores"]) for d in days]
    cat_std = {}
    cat_mean = {}
    cat_top3_freq = {}
    for c in ALL_CATEGORIES:
        vals = [nd[c] for nd in norm_days]
        cat_mean[c] = round(statistics.fmean(vals), 4)
        cat_std[c] = round(statistics.pstdev(vals), 4) if len(vals) > 1 else 0.0
        cat_top3_freq[c] = sum(1 for d in days if c in d["visible"])

    visible_categories = set()
    for d in days:
        visible_categories.update(d["visible"])

    # transit stability
    top1_transit = [d["topTransits"][0] if d["topTransits"] else "?" for d in days]
    transit_planets_seen = Counter()
    for d in days:
        for p in d["topTransits"]:
            transit_planets_seen[p] += 1

    return {
        "n_days": len(days),
        "top1_flip_rate": round(top1_flips / n, 3) if n else 0.0,
        "top3_change_rate": round(top3_changes / n, 3) if n else 0.0,
        "avg_l1": round(statistics.fmean(l1s), 4) if l1s else 0.0,
        "avg_jaccard": round(statistics.fmean(jac), 3) if jac else 1.0,
        "distinct_top1": len(set(top1)),
        "distinct_visible_categories": len(visible_categories),
        "visible_categories": sorted(visible_categories),
        "top1_distribution": dict(Counter(top1).most_common()),
        "cat_top3_freq": cat_top3_freq,
        "cat_mean": cat_mean,
        "cat_std": cat_std,
        "top1_transit_distribution": dict(Counter(top1_transit).most_common()),
        "transit_planets_seen": dict(transit_planets_seen.most_common()),
        "anchorTop3": days[0]["anchorTop3"],
    }


def fetch_series(preset: dict, dates: list[str]) -> list[dict]:
    out = []
    for d in dates:
        day = extract_day(inspect(preset, d))
        day["date"] = d
        out.append(day)
    return out


def run(start: date, n_days: int, n_months: int, preset_ids: list[str]) -> int:
    presets = json.loads(PRESETS_PATH.read_text())
    by_id = {p["id"]: p for p in presets}

    daily_dates = [(start + timedelta(days=i)).isoformat() for i in range(n_days)]
    monthly_dates = []
    y, m = start.year, start.month
    for _ in range(n_months):
        monthly_dates.append(date(y, m, 1).isoformat())
        m += 1
        if m > 12:
            m = 1
            y += 1

    daily_metrics: dict[str, dict] = {}
    monthly_metrics: dict[str, dict] = {}
    daily_series: dict[str, list] = {}
    monthly_series: dict[str, list] = {}

    for pid in preset_ids:
        preset = by_id[pid]
        ds = fetch_series(preset, daily_dates)
        ms = fetch_series(preset, monthly_dates)
        daily_series[pid] = ds
        monthly_series[pid] = ms
        daily_metrics[pid] = analyze(ds)
        monthly_metrics[pid] = analyze(ms)
        print(f"  {pid}: daily={n_days}d monthly={n_months}mo done", file=sys.stderr)

    FIXTURES.mkdir(parents=True, exist_ok=True)
    out_json = FIXTURES / "essence_stage1_diagnostics.json"
    out_json.write_text(
        json.dumps(
            {
                "generated": datetime.now().astimezone().isoformat(),
                "engine": ENGINE,
                "daily_window": {"start": daily_dates[0], "end": daily_dates[-1], "days": n_days},
                "monthly_window": {"start": monthly_dates[0], "end": monthly_dates[-1], "months": n_months},
                "transit_to_category": TRANSIT_TO_CATEGORY,
                "presets": preset_ids,
                "daily_metrics": daily_metrics,
                "monthly_metrics": monthly_metrics,
                "daily_series": daily_series,
                "monthly_series": monthly_series,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    # ---- text summary ----
    lines = [
        "Stage1 Experimental — Essence Rate-of-Change Diagnostics",
        f"Engine: {ENGINE}",
        f"Daily window:   {daily_dates[0]} .. {daily_dates[-1]} ({n_days} days)",
        f"Monthly window: {monthly_dates[0]} .. {monthly_dates[-1]} ({n_months} months)",
        f"Presets: {', '.join(preset_ids)}",
        "",
        "=== DAILY rate of change (consecutive days) ===",
        f"{'preset':<8}{'top1flip':>9}{'top3chg':>9}{'L1':>8}{'jacc':>7}{'#top1':>7}{'#cats_top3':>12}",
    ]
    for pid in preset_ids:
        m = daily_metrics[pid]
        lines.append(
            f"{pid:<8}{m['top1_flip_rate']:>9}{m['top3_change_rate']:>9}"
            f"{m['avg_l1']:>8}{m['avg_jaccard']:>7}{m['distinct_top1']:>7}{m['distinct_visible_categories']:>12}"
        )

    lines += [
        "",
        "=== MONTHLY rate of change (1st of each month) ===",
        f"{'preset':<8}{'top1flip':>9}{'top3chg':>9}{'L1':>8}{'#top1':>7}{'#cats_top3':>12}",
    ]
    for pid in preset_ids:
        m = monthly_metrics[pid]
        lines.append(
            f"{pid:<8}{m['top1_flip_rate']:>9}{m['top3_change_rate']:>9}"
            f"{m['avg_l1']:>8}{m['distinct_top1']:>7}{m['distinct_visible_categories']:>12}"
        )

    lines += ["", "=== ROOT CAUSE: dominant transit planets over the daily window ==="]
    for pid in preset_ids:
        m = daily_metrics[pid]
        tp = m["transit_planets_seen"]
        tp_str = ", ".join(
            f"{p}({c}d→{TRANSIT_TO_CATEGORY.get(p, '-')}/{PLANET_SPEED.get(p, '?')})"
            for p, c in tp.items()
        )
        lines.append(f"{pid}: {tp_str}")
        lines.append(f"   anchor top3 (natal): {', '.join(m['anchorTop3'])}")
        lines.append(f"   visible essences seen: {', '.join(m['visible_categories'])}")

    lines += ["", "=== Per-category daily volatility (stddev of normalised score, daily window) ==="]
    lines.append(f"{'preset':<8}" + "".join(f"{c[:5]:>7}" for c in ALL_CATEGORIES))
    for pid in preset_ids:
        cs = daily_metrics[pid]["cat_std"]
        lines.append(f"{pid:<8}" + "".join(f"{cs[c]:>7}" for c in ALL_CATEGORIES))

    out_txt = FIXTURES / "essence_stage1_diagnostics.txt"
    out_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print(f"\nWrote {out_json}")
    print(f"Wrote {out_txt}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--start", default=date.today().isoformat())
    ap.add_argument("--days", type=int, default=60)
    ap.add_argument("--months", type=int, default=12)
    ap.add_argument("--presets", default=",".join(DEFAULT_PRESETS))
    args = ap.parse_args()
    start = datetime.strptime(args.start, "%Y-%m-%d").date()
    preset_ids = [p.strip() for p in args.presets.split(",") if p.strip()]
    return run(start, args.days, args.months, preset_ids)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.URLError as exc:
        print(f"Inspector not reachable at {INSPECTOR_URL}: {exc}", file=sys.stderr)
        print("Start it with: cd inspector && ./run-inspector.sh", file=sys.stderr)
        raise SystemExit(1)
