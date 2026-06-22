#!/usr/bin/env python3
"""Day-over-day slider variation audit for Daily Fit scale sliders.

Runs the synthetic cohort (216 users) across 60 consecutive days via the
inspector API, captures per-day displayPosition values, and computes:
  - consecutive-day delta distributions (raw + UI-visible)
  - unchanged-day streak lengths
  - comparison vs silhouette sliders

Outputs:
  docs/fixtures/slider_day_variation_report.json
  docs/fixtures/slider_day_variation_report.txt
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "docs" / "fixtures"
INSPECTOR_URL = "http://127.0.0.1:7777/api/inspect"
ENGINE = "stage1_experimental"

SCALE_SLIDERS = ["vibrancy", "contrast", "metalTone"]
SILHOUETTE_SLIDERS = ["masculineFeminine", "angularRounded", "structuredDraped"]
ALL_SLIDERS = SCALE_SLIDERS + SILHOUETTE_SLIDERS

MEANINGFUL_DELTA = 0.05
IMPERCEPTIBLE_DELTA = 0.02


def snap_metal(value: float) -> float:
    if value < 1.0 / 3.0:
        return 0.0
    if value > 2.0 / 3.0:
        return 1.0
    return 0.5


def ui_value(slider: str, raw: float) -> float:
    if slider == "metalTone":
        return snap_metal(raw)
    return raw


def load_cohort(subset: int | None) -> list[dict]:
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
        sil_env = payload.get("scalePresentation", {}).get(slider) if payload.get("scalePresentation") else None
        if sil_env and "displayPosition" in sil_env:
            values[slider] = float(sil_env["displayPosition"])
        else:
            val = sil.get(slider)
            values[slider] = float(val) if val is not None else None

    return values


def max_unchanged_streak(values: list[float], eps: float = 1e-9) -> int:
    if len(values) < 2:
        return len(values)
    best = cur = 1
    for i in range(1, len(values)):
        if abs(values[i] - values[i - 1]) <= eps:
            cur += 1
            best = max(best, cur)
        else:
            cur = 1
    return best


def analyze_user_series(user_id: str, series: list[dict[str, float | None]]) -> dict:
    out: dict = {"userId": user_id, "sliders": {}}
    for slider in ALL_SLIDERS:
        raw_vals = [d[slider] for d in series if d.get(slider) is not None]
        ui_vals = [ui_value(slider, v) for v in raw_vals]

        if len(raw_vals) < 2:
            out["sliders"][slider] = {"nDays": len(raw_vals), "skipped": True}
            continue

        raw_deltas = [abs(raw_vals[i] - raw_vals[i - 1]) for i in range(1, len(raw_vals))]
        ui_deltas = [abs(ui_vals[i] - ui_vals[i - 1]) for i in range(1, len(ui_vals))]

        unchanged_ui = sum(1 for d in ui_deltas if d < 1e-9)
        imperceptible_ui = sum(1 for d in ui_deltas if d < IMPERCEPTIBLE_DELTA)
        meaningful_ui = sum(1 for d in ui_deltas if d >= MEANINGFUL_DELTA)

        out["sliders"][slider] = {
            "nDays": len(raw_vals),
            "rawMin": round(min(raw_vals), 6),
            "rawMax": round(max(raw_vals), 6),
            "rawRange": round(max(raw_vals) - min(raw_vals), 6),
            "uiDistinct": len(set(round(v, 6) for v in ui_vals)),
            "meanDayDeltaRaw": round(statistics.fmean(raw_deltas), 6),
            "meanDayDeltaUI": round(statistics.fmean(ui_deltas), 6),
            "medianDayDeltaUI": round(statistics.median(ui_deltas), 6),
            "pctUnchangedDayPairsUI": round(unchanged_ui / len(ui_deltas) * 100, 1),
            "pctImperceptibleDayPairsUI": round(imperceptible_ui / len(ui_deltas) * 100, 1),
            "pctMeaningfulDayPairsUI": round(meaningful_ui / len(ui_deltas) * 100, 1),
            "maxUnchangedStreakUI": max_unchanged_streak(ui_vals),
            "maxUnchangedStreakRaw": max_unchanged_streak(raw_vals),
        }
    return out


def aggregate(users: list[dict]) -> dict:
    agg: dict[str, dict] = {}
    for slider in ALL_SLIDERS:
        rows = [u["sliders"][slider] for u in users if not u["sliders"].get(slider, {}).get("skipped")]
        if not rows:
            continue
        n = len(rows)
        agg[slider] = {
            "nUsers": n,
            "meanRawRange": round(statistics.fmean(r["rawRange"] for r in rows), 4),
            "medianRawRange": round(statistics.median(r["rawRange"] for r in rows), 4),
            "meanDayDeltaUI": round(statistics.fmean(r["meanDayDeltaUI"] for r in rows), 4),
            "medianDayDeltaUI": round(statistics.median(r["medianDayDeltaUI"] for r in rows), 4),
            "meanUiDistinct": round(statistics.fmean(r["uiDistinct"] for r in rows), 1),
            "pctUsersMostlyUnchanged": round(
                sum(1 for r in rows if r["pctUnchangedDayPairsUI"] >= 50) / n * 100, 1
            ),
            "pctUsersMostlyImperceptible": round(
                sum(1 for r in rows if r["pctImperceptibleDayPairsUI"] >= 80) / n * 100, 1
            ),
            "pctUsersRarelyMeaningful": round(
                sum(1 for r in rows if r["pctMeaningfulDayPairsUI"] < 10) / n * 100, 1
            ),
            "meanMaxUnchangedStreakUI": round(statistics.fmean(r["maxUnchangedStreakUI"] for r in rows), 1),
            "p90MaxUnchangedStreakUI": round(sorted(r["maxUnchangedStreakUI"] for r in rows)[int(n * 0.9)], 1),
            "meanPctUnchangedDayPairsUI": round(statistics.fmean(r["pctUnchangedDayPairsUI"] for r in rows), 1),
            "meanPctMeaningfulDayPairsUI": round(statistics.fmean(r["pctMeaningfulDayPairsUI"] for r in rows), 1),
        }
    return agg


def delta_histogram(users: list[dict], slider: str, bins: list[float]) -> list[int]:
    counts = [0] * (len(bins) - 1)
    for user in users:
        s = user["sliders"].get(slider, {})
        if s.get("skipped"):
            continue
        # Reconstruct approximate distribution from mean isn't ideal; store in run
        pass
    return counts


def run_user(user: dict, dates: list[str]) -> tuple[str, list[dict[str, float | None]], list[dict]]:
    series: list[dict[str, float | None]] = []
    delta_rows: list[dict] = []
    prev_ui: dict[str, float] | None = None

    for d in dates:
        try:
            resp = inspect(user, d)
            sliders = extract_sliders(resp)
            series.append(sliders)
            if prev_ui is not None:
                row = {"date": d}
                for slider in ALL_SLIDERS:
                    cur = sliders.get(slider)
                    if cur is None or slider not in prev_ui:
                        row[slider] = None
                    else:
                        row[slider] = abs(ui_value(slider, cur) - prev_ui[slider])
                delta_rows.append(row)
            prev_ui = {
                s: ui_value(s, sliders[s])
                for s in ALL_SLIDERS
                if sliders.get(s) is not None
            }
        except Exception as e:
            print(f"  WARN: {user['id']} @ {d}: {e}", file=sys.stderr)
            series.append({s: None for s in ALL_SLIDERS})

    return user["id"], series, delta_rows


def global_delta_histogram(all_deltas: list[dict], slider: str) -> dict:
    edges = [0, 0.001, 0.02, 0.05, 0.10, 0.20, 0.50, 1.01]
    labels = ["0 (unchanged)", "<0.02", "0.02–0.05", "0.05–0.10", "0.10–0.20", "0.20–0.50", ">0.50"]
    counts = [0] * len(labels)
    values = [d[slider] for d in all_deltas if d.get(slider) is not None]
    for v in values:
        for i in range(len(edges) - 1):
            if edges[i] <= v < edges[i + 1]:
                counts[i] += 1
                break
    total = len(values) or 1
    return {
        "labels": labels,
        "counts": counts,
        "pct": [round(c / total * 100, 1) for c in counts],
        "nPairs": len(values),
    }


def run(start: date, n_days: int, subset: int | None, parallel: int) -> int:
    users = load_cohort(subset)
    dates = [(start + timedelta(days=i)).isoformat() for i in range(n_days)]

    print(f"Day variation audit: {len(users)} users × {n_days} days", file=sys.stderr)
    print(f"Window: {dates[0]} .. {dates[-1]}", file=sys.stderr)

    user_analyses: list[dict] = []
    all_deltas: list[dict] = []

    if parallel > 1:
        with ThreadPoolExecutor(max_workers=parallel) as pool:
            futures = {pool.submit(run_user, u, dates): u["id"] for u in users}
            for i, future in enumerate(as_completed(futures)):
                uid, series, deltas = future.result()
                user_analyses.append(analyze_user_series(uid, series))
                all_deltas.extend(deltas)
                if (i + 1) % 20 == 0:
                    print(f"  {i+1}/{len(users)} users complete", file=sys.stderr)
    else:
        for i, user in enumerate(users):
            uid, series, deltas = run_user(user, dates)
            user_analyses.append(analyze_user_series(uid, series))
            all_deltas.extend(deltas)
            if (i + 1) % 10 == 0:
                print(f"  {i+1}/{len(users)} users complete", file=sys.stderr)

    agg = aggregate(user_analyses)
    histograms = {s: global_delta_histogram(all_deltas, s) for s in ALL_SLIDERS}

    report = {
        "generated": datetime.now().astimezone().isoformat(),
        "engine": ENGINE,
        "cohort": "synthetic_cohort",
        "nUsers": len(users),
        "window": {"start": dates[0], "end": dates[-1], "days": n_days},
        "thresholds": {
            "imperceptibleDelta": IMPERCEPTIBLE_DELTA,
            "meaningfulDelta": MEANINGFUL_DELTA,
        },
        "aggregate": agg,
        "deltaHistograms": histograms,
        "worstUsers": {
            slider: sorted(
                [
                    {
                        "userId": u["userId"],
                        "maxUnchangedStreakUI": u["sliders"][slider]["maxUnchangedStreakUI"],
                        "pctUnchangedDayPairsUI": u["sliders"][slider]["pctUnchangedDayPairsUI"],
                        "rawRange": u["sliders"][slider]["rawRange"],
                    }
                    for u in user_analyses
                    if not u["sliders"].get(slider, {}).get("skipped")
                ],
                key=lambda x: (-x["maxUnchangedStreakUI"], -x["pctUnchangedDayPairsUI"]),
            )[:10]
            for slider in SCALE_SLIDERS
        },
    }

    FIXTURES.mkdir(parents=True, exist_ok=True)
    out_json = FIXTURES / "slider_day_variation_report.json"
    out_json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "Slider Day-Variation Report",
        f"Engine: {ENGINE}",
        f"Cohort: synthetic_cohort ({len(users)} users)",
        f"Window: {dates[0]} .. {dates[-1]} ({n_days} days)",
        f"Generated: {report['generated']}",
        "",
        "=== AGGREGATE (UI-visible day-over-day) ===",
        f"{'slider':<20}{'medΔUI':>8}{'meanΔUI':>8}{'%unch':>8}{'%<0.02':>8}{'%≥0.05':>8}{'maxStrk':>8}{'distPos':>8}",
    ]
    for slider in ALL_SLIDERS:
        a = agg.get(slider)
        if not a:
            continue
        hist = histograms[slider]
        pct_unch = hist["pct"][0]
        pct_imp = hist["pct"][0] + hist["pct"][1]
        pct_mean = sum(hist["pct"][i] for i in range(3, len(hist["pct"])))
        lines.append(
            f"{slider:<20}{a['medianDayDeltaUI']:>8.4f}{a['meanDayDeltaUI']:>8.4f}"
            f"{a['meanPctUnchangedDayPairsUI']:>8.1f}{pct_imp:>8.1f}{pct_mean:>8.1f}"
            f"{a['meanMaxUnchangedStreakUI']:>8.1f}{a['meanUiDistinct']:>8.1f}"
        )

    lines += ["", "=== SCALE vs SILHOUETTE VERDICT ==="]
    for slider in SCALE_SLIDERS:
        a = agg[slider]
        sil = agg.get("structuredDraped", {})
        lines.append(
            f"  {slider}: {a['pctUsersRarelyMeaningful']:.0f}% users see meaningful shift <10% of days; "
            f"mean unchanged streak {a['meanMaxUnchangedStreakUI']:.1f} days"
        )

    out_txt = FIXTURES / "slider_day_variation_report.txt"
    out_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print(f"\nWrote {out_json}")
    print(f"Wrote {out_txt}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--start", default="2026-04-23")
    ap.add_argument("--days", type=int, default=60)
    ap.add_argument("--subset", type=int, default=None)
    ap.add_argument("--parallel", type=int, default=6)
    args = ap.parse_args()
    start = datetime.strptime(args.start, "%Y-%m-%d").date()
    return run(start, args.days, args.subset, args.parallel)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.URLError as exc:
        print(f"Inspector not reachable at {INSPECTOR_URL}: {exc}", file=sys.stderr)
        print("Start it with: cd inspector && ./run-inspector.sh", file=sys.stderr)
        raise SystemExit(1)
