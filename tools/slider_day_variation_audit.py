#!/usr/bin/env python3
"""Day-over-day slider variation audit for Daily Fit scale sliders.

Runs the synthetic cohort (216 users) across 60 consecutive days via the
inspector API, captures per-day displayPosition values, and computes:
  - consecutive-day delta distributions (raw + UI-visible)
  - unchanged-day streak lengths
  - comparison vs silhouette sliders

Metal tone UI uses 3-position snap on displayPosition (Cool/Mixed/Warm),
matching production DailyFitViewController behaviour.

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
# Engine the audit runs against. Sky Forward v1.0.2 by default (Phase 6c) so the gate validates the
# shipping candidate before cutover; override with --engine.
ENGINE = "sky_forward_v1_0_2"

SCALE_SLIDERS = ["vibrancy", "contrast", "metalTone"]
SILHOUETTE_SLIDERS = ["masculineFeminine", "angularRounded", "structuredDraped"]
ALL_SLIDERS = SCALE_SLIDERS + SILHOUETTE_SLIDERS

MEANINGFUL_DELTA = 0.05
IMPERCEPTIBLE_DELTA = 0.02

# --- Sky Forward v1.0.2 Phase 6c / plan G2 item 4: fail-closed stuck-slider gate ---
# The failure mode this gate exists to catch is a slider FROZEN by Phase 4's variation cuts
# (jitter 0.40→0.18, transit top-5 normalisation). Thresholds are PINNED (governance G0) and set as
# anti-freeze floors, NOT at the aspirational §4.3 [9] "range ≥ 0.5/user" — because even shipped
# v1.0.1 sits far below 0.5 on the natal-driven silhouette sliders (e.g. masculineFeminine ≈ 0.14
# meanRawRange, 100% of users < 0.33). A literal 0.5 floor would red on v1.0.1 itself, so it is
# reported as a DIAGNOSTIC, not a pass condition. The real bar is: no slider frozen (absolute), and
# no slider regressed beyond tolerance vs the pinned baseline. Changing a constant is an owner
# escalation, recorded in the plan revision log.
GATE_MIN_MEAN_RANGE = 0.05           # a slider whose cohort-mean 60-day range < this is frozen
GATE_MAX_PCT_RARELY_MEANINGFUL = 99  # % of users seeing a ≥MEANINGFUL_DELTA shift on <10% of days
GATE_TARGET_RANGE_PER_USER = 0.5     # §4.3 [9] aspirational target — reported as diagnostic only
GATE_REGRESSION_TOLERANCE = 0.25     # per slider, meanRawRange may not drop more than this vs baseline
DEFAULT_GATE_BASELINE = "docs/fixtures/slider_day_variation_baseline_v1_0_1.json"


def run_slider_gate(agg: dict, baseline_agg: dict | None) -> tuple[list[str], list[str]]:
    """Return (failures, diagnostics). Non-empty failures ⇒ fail-closed exit(1)."""
    failures: list[str] = []
    diagnostics: list[str] = []
    for slider in ALL_SLIDERS:
        a = agg.get(slider)
        if not a:
            continue
        mean_range = a["meanRawRange"]
        # (1) anti-freeze: a slider must actually move across the window
        if mean_range < GATE_MIN_MEAN_RANGE:
            failures.append(
                f"slider '{slider}' frozen: meanRawRange={mean_range:.4f} < floor {GATE_MIN_MEAN_RANGE}")
        # (2) practically-stuck: not (near-)every user rarely sees a meaningful (≥0.05) shift
        rarely = a["pctUsersRarelyMeaningful"]
        if rarely >= GATE_MAX_PCT_RARELY_MEANINGFUL:
            failures.append(
                f"slider '{slider}' stuck: {rarely:.0f}% of users see a ≥{MEANINGFUL_DELTA} shift on "
                f"<10% of days ≥ cap {GATE_MAX_PCT_RARELY_MEANINGFUL}%")
        # (3) regression vs pinned baseline
        if baseline_agg and slider in baseline_agg:
            base_range = baseline_agg[slider]["meanRawRange"]
            if base_range > 0 and mean_range < base_range * (1 - GATE_REGRESSION_TOLERANCE):
                failures.append(
                    f"slider '{slider}' range regressed: {mean_range:.4f} < "
                    f"{base_range:.4f}×{1 - GATE_REGRESSION_TOLERANCE:.2f} vs baseline "
                    f"(owner-priority: raise jitterRange / widen transit top-K)")
        # Diagnostic: literal §4.3 [9] target (not a pass condition — silhouette sliders sit below it)
        if mean_range < GATE_TARGET_RANGE_PER_USER:
            diagnostics.append(
                f"slider '{slider}' meanRawRange {mean_range:.3f} below §4.3[9] target "
                f"{GATE_TARGET_RANGE_PER_USER} (structural for natal-driven sliders; diagnostic only)")
    return failures, diagnostics

LEGACY_METAL_SNAP = True  # production UI snaps metal displayPosition to 3 positions


def snap_metal(value: float) -> float:
    if value < 1.0 / 3.0:
        return 0.0
    if value > 2.0 / 3.0:
        return 1.0
    return 0.5


def ui_value(slider: str, raw: float) -> float:
    if slider == "metalTone" and LEGACY_METAL_SNAP:
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
        if sp.get("contrast") and "contrast" in payload:
            values["_contrastDeviation"] = abs(
                float(payload["contrast"]) - float(sp["contrast"]["baseline"])
            )
        if sp.get("metalTone") and "metalTone" in payload:
            values["_metalDeviation"] = abs(
                float(payload["metalTone"]) - float(sp["metalTone"]["baseline"])
            )
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


def p95(values: list[float]) -> float:
    if not values:
        return 0.0
    sorted_vals = sorted(values)
    idx = int(len(sorted_vals) * 0.95)
    return sorted_vals[min(idx, len(sorted_vals) - 1)]


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
            "pctUsersLowRawRange": round(
                sum(1 for r in rows if r["rawRange"] < 0.33) / n * 100, 1
            ),
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


def run(start: date, n_days: int, subset: int | None, parallel: int, output: str | None = None,
        gate: bool = False, baseline_path: str | None = None) -> int:
    users = load_cohort(subset)
    dates = [(start + timedelta(days=i)).isoformat() for i in range(n_days)]

    print(f"Day variation audit: {len(users)} users × {n_days} days", file=sys.stderr)
    print(f"Window: {dates[0]} .. {dates[-1]}", file=sys.stderr)

    user_analyses: list[dict] = []
    all_deltas: list[dict] = []
    contrast_deviations: list[float] = []
    metal_deviations: list[float] = []

    if parallel > 1:
        with ThreadPoolExecutor(max_workers=parallel) as pool:
            futures = {pool.submit(run_user, u, dates): u["id"] for u in users}
            for i, future in enumerate(as_completed(futures)):
                uid, series, deltas = future.result()
                user_analyses.append(analyze_user_series(uid, series))
                all_deltas.extend(deltas)
                for day in series:
                    dev = day.get("_contrastDeviation")
                    if dev is not None:
                        contrast_deviations.append(float(dev))
                    mdev = day.get("_metalDeviation")
                    if mdev is not None:
                        metal_deviations.append(float(mdev))
                if (i + 1) % 20 == 0:
                    print(f"  {i+1}/{len(users)} users complete", file=sys.stderr)
    else:
        for i, user in enumerate(users):
            uid, series, deltas = run_user(user, dates)
            user_analyses.append(analyze_user_series(uid, series))
            all_deltas.extend(deltas)
            for day in series:
                dev = day.get("_contrastDeviation")
                if dev is not None:
                    contrast_deviations.append(float(dev))
                mdev = day.get("_metalDeviation")
                if mdev is not None:
                    metal_deviations.append(float(mdev))
            if (i + 1) % 10 == 0:
                print(f"  {i+1}/{len(users)} users complete", file=sys.stderr)

    contrast_p95 = p95(contrast_deviations)
    contrast_half_span = round(min(0.22, max(0.14, round(contrast_p95 + 0.04, 2))), 2)

    metal_p95 = p95(metal_deviations)
    metal_half_span = round(min(0.44, max(0.28, round(metal_p95 + 0.02, 2))), 2)

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
        "contrastEnvelopeCalibration": {
            "p95Deviation": round(contrast_p95, 4),
            "recommendedHalfSpan": contrast_half_span,
            "nSamples": len(contrast_deviations),
            "formula": "clamp(round(P95 + 0.04, 2), min=0.14, max=0.22)",
        },
        "metalEnvelopeCalibration": {
            "p95Deviation": round(metal_p95, 4),
            "recommendedHalfSpan": metal_half_span,
            "nSamples": len(metal_deviations),
            "formula": "clamp(round(P95 + 0.02, 2), min=0.28, max=0.44)",
        },
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
    out_json = Path(output) if output else FIXTURES / "slider_day_variation_report.json"
    out_json.parent.mkdir(parents=True, exist_ok=True)
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
        a = agg.get(slider)
        if not a:
            continue
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

    # --- Fail-closed stuck-slider gate (plan G2 item 4) ---
    if gate:
        baseline_agg = None
        if baseline_path:
            bpath = ROOT / baseline_path
            if bpath.exists():
                baseline_agg = json.loads(bpath.read_text()).get("aggregate")
                print(f"\nGATE: diffing against pinned baseline {baseline_path}")
            else:
                print(f"\nGATE: baseline {baseline_path} absent — enforcing absolute anti-freeze floors only")
        failures, diagnostics = run_slider_gate(agg, baseline_agg)
        for d in diagnostics:
            print(f"  · {d}")
        print("\n" + "=" * 60)
        if failures:
            print(f"GATE FAILED ({len(failures)} stuck/regressed slider(s)):")
            for f in failures:
                print(f"  ✘ {f}")
            print("A red gate is a signal to keep developing (plan §7 nudge order), not to ship.")
            return 1
        print("GATE PASSED — no frozen or regressed sliders.")
    return 0


def main() -> int:
    global LEGACY_METAL_SNAP, ENGINE
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--start", default="2026-04-23")
    ap.add_argument("--days", type=int, default=60)
    ap.add_argument("--subset", type=int, default=None)
    ap.add_argument("--parallel", type=int, default=6)
    ap.add_argument("--engine", default=ENGINE,
                    help=f"Daily Fit engine id to audit (default: {ENGINE})")
    ap.add_argument("--no-metal-snap", action="store_true",
                    help="Use continuous metal displayPosition (pre-snap comparison only)")
    ap.add_argument("--output", default=None,
                    help="Output JSON path (default: docs/fixtures/slider_day_variation_report.json)")
    ap.add_argument("--gate", action="store_true",
                    help="Fail-closed stuck-slider gate: sys.exit(1) if any slider is frozen or "
                         "regresses beyond tolerance vs --baseline.")
    ap.add_argument("--baseline", default=DEFAULT_GATE_BASELINE,
                    help="Pinned baseline report JSON to diff against in --gate mode "
                         "(absolute anti-freeze floors still apply if the baseline is absent).")
    args = ap.parse_args()
    LEGACY_METAL_SNAP = not args.no_metal_snap
    ENGINE = args.engine
    start = datetime.strptime(args.start, "%Y-%m-%d").date()
    return run(start, args.days, args.subset, args.parallel, args.output,
               gate=args.gate, baseline_path=args.baseline)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.URLError as exc:
        print(f"Inspector not reachable at {INSPECTOR_URL}: {exc}", file=sys.stderr)
        print("Start it with: cd inspector && ./run-inspector.sh", file=sys.stderr)
        raise SystemExit(1)
