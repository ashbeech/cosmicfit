#!/usr/bin/env python3
"""Slider Range Audit — Full Diagnostic.

Computes raw value range, baseline-relative delta range, envelope span,
display-position range, clamp rate, and actual UI marker range for all 6 sliders.

Uses known Stage1ScaleSensitivity constants + slider_range_report.json per-user data.
Outputs docs/fixtures/slider_range_audit.json + .txt.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "docs" / "fixtures"

# --- Stage1ScaleSensitivity constants ---
VIBRANCY_PRACTICAL_HALF_SPAN = 0.22
CONTRAST_MAX_BLEND_NORM = 0.50
CONTRAST_COEFF = 0.55  # from stage1ExperimentalCalibration
CONTRAST_PRACTICAL_HALF_SPAN = 0.22  # Phase 3: P95 deviation 0.269 + 0.04 margin (cap 0.22)
METAL_NUDGE_CAP = 0.30
METAL_PRACTICAL_HALF_SPAN = 0.36  # Tuned for G2: balances display travel vs rail-pin
LUNAR_NAMED_PHASE_NUDGE = 0.03
LUNAR_DEGREE_SCALE = 0.15
LUNAR_DEGREE_MAX_ABS = LUNAR_DEGREE_SCALE * 0.5
SILHOUETTE_FLOOR = 0.12
SILHOUETTE_CEILING = 0.88
SILHOUETTE_SD_PRACTICAL_HALF_SPAN = 0.34  # Plan 4: per-user envelope for SD (widened C2)
SILHOUETTE_MFAR_PRACTICAL_HALF_SPAN = 0.34  # Plan 4: per-user envelope for MF/AR (widened C3)

# Blueprint variant cycle (idx % 6)
VARIANTS = [
    {"saturation": "soft", "contrast": "low", "temperature": "cool", "metals": ["silver", "platinum"]},
    {"saturation": "muted", "contrast": "medium", "temperature": "neutral", "metals": ["gold", "silver"]},
    {"saturation": "rich", "contrast": "high", "temperature": "warm", "metals": ["gold", "brass"]},
    {"saturation": "soft", "contrast": "medium", "temperature": "warm", "metals": ["silver", "steel"]},
    {"saturation": "muted", "contrast": "high", "temperature": "cool", "metals": ["gold", "copper"]},
    {"saturation": "rich", "contrast": "low", "temperature": "neutral", "metals": ["platinum", "silver"]},
]

WARM_METALS = {"gold", "brass", "copper", "bronze"}
COOL_METALS = {"silver", "platinum", "pewter", "white gold", "steel"}


def vibrancy_baseline(sat: str) -> float:
    return {"soft": 0.25, "muted": 0.50, "rich": 0.75}[sat]


def contrast_baseline(con: str) -> float:
    return {"low": 0.25, "medium": 0.50, "high": 0.75}[con]


def metal_baseline(temp: str, metals: list[str]) -> float:
    temp_val = {"cool": 0.2, "neutral": 0.5, "warm": 0.8}[temp]
    warm_count = sum(1 for m in metals if m in WARM_METALS)
    cool_count = sum(1 for m in metals if m in COOL_METALS)
    metal_lean = warm_count / max(1, warm_count + cool_count)
    return temp_val * 0.6 + metal_lean * 0.4


def vibrancy_envelope(baseline: float) -> tuple[float, float]:
    floor = max(0.0, min(1.0, baseline - VIBRANCY_PRACTICAL_HALF_SPAN))
    ceiling = max(0.0, min(1.0, baseline + VIBRANCY_PRACTICAL_HALF_SPAN))
    return floor, ceiling


def contrast_envelope(baseline: float) -> tuple[float, float]:
    floor = max(0.0, min(1.0, baseline - CONTRAST_PRACTICAL_HALF_SPAN))
    ceiling = max(0.0, min(1.0, baseline + CONTRAST_PRACTICAL_HALF_SPAN))
    return floor, ceiling


def metal_envelope(baseline: float) -> tuple[float, float]:
    half_span = METAL_PRACTICAL_HALF_SPAN
    floor = max(0.0, min(1.0, baseline - half_span))
    ceiling = max(0.0, min(1.0, baseline + half_span))
    return floor, ceiling


def silhouette_envelope(kind: str, baseline: float) -> tuple[float, float]:
    half_span = SILHOUETTE_SD_PRACTICAL_HALF_SPAN if kind == "structuredDraped" else SILHOUETTE_MFAR_PRACTICAL_HALF_SPAN
    floor = max(0.0, min(1.0, baseline - half_span))
    ceiling = max(0.0, min(1.0, baseline + half_span))
    return floor, ceiling


def display_position(value: float, floor: float, ceiling: float) -> float:
    span = ceiling - floor
    if span < 0.001:
        return 0.5
    return max(0.0, min(1.0, (value - floor) / span))


def snap_metal(dp: float) -> float:
    if dp < 1.0 / 3.0:
        return 0.0
    if dp > 2.0 / 3.0:
        return 1.0
    return 0.5


def main():
    report_path = FIXTURES / "slider_range_report.json"
    report = json.loads(report_path.read_text())
    users_data = report["users"]

    slider_names = ["vibrancy", "contrast", "metalTone",
                    "masculineFeminine", "angularRounded", "structuredDraped"]

    # Compute per-variant envelope parameters
    variant_envelopes: list[dict] = []
    for v in VARIANTS:
        vib_base = vibrancy_baseline(v["saturation"])
        con_base = contrast_baseline(v["contrast"])
        met_base = metal_baseline(v["temperature"], v["metals"])
        vib_env = vibrancy_envelope(vib_base)
        con_env = contrast_envelope(con_base)
        met_env = metal_envelope(met_base)
        sil_sd_env = silhouette_envelope("structuredDraped", 0.5)
        sil_mf_env = silhouette_envelope("masculineFeminine", 0.5)
        variant_envelopes.append({
            "vibrancy": {"baseline": vib_base, "floor": vib_env[0], "ceiling": vib_env[1], "span": vib_env[1] - vib_env[0]},
            "contrast": {"baseline": con_base, "floor": con_env[0], "ceiling": con_env[1], "span": con_env[1] - con_env[0]},
            "metalTone": {"baseline": met_base, "floor": met_env[0], "ceiling": met_env[1], "span": met_env[1] - met_env[0]},
            "masculineFeminine": {"baseline": 0.5, "floor": sil_mf_env[0], "ceiling": sil_mf_env[1], "span": sil_mf_env[1] - sil_mf_env[0]},
            "angularRounded": {"baseline": 0.5, "floor": sil_mf_env[0], "ceiling": sil_mf_env[1], "span": sil_mf_env[1] - sil_mf_env[0]},
            "structuredDraped": {"baseline": 0.5, "floor": sil_sd_env[0], "ceiling": sil_sd_env[1], "span": sil_sd_env[1] - sil_sd_env[0]},
        })

    # Aggregate per slider
    aggregate: dict[str, dict] = {}
    for slider in slider_names:
        dp_ranges = []
        raw_ranges_approx = []
        baseline_delta_ranges = []
        envelope_spans = []
        clamp_rates = []
        ui_marker_ranges = []
        ui_distinct_counts = []

        for user_idx, user in enumerate(users_data):
            variant_idx = user_idx % 6
            env_info = variant_envelopes[variant_idx][slider]
            user_sliders = user.get("sliders", {})
            if slider not in user_sliders:
                continue
            s = user_sliders[slider]
            dp_min = s["min"]
            dp_max = s["max"]
            dp_range = s["range"]
            dp_mean = s["mean"]

            # Reverse-engineer raw values from display positions
            floor = env_info["floor"]
            ceiling = env_info["ceiling"]
            span = env_info["span"]
            baseline = env_info["baseline"]

            raw_min = floor + dp_min * span
            raw_max = floor + dp_max * span
            raw_range = raw_max - raw_min

            delta_min = raw_min - baseline
            delta_max = raw_max - baseline
            delta_range = delta_max - delta_min

            # Clamp rate: dp at 0.0 or 1.0 means value at floor or ceiling
            # Approximate: if dp_min < 0.01 → clamping at floor; dp_max > 0.99 → clamping at ceiling
            clamp_floor = 1 if dp_min < 0.005 else 0
            clamp_ceiling = 1 if dp_max > 0.995 else 0
            clamp_rate = (clamp_floor + clamp_ceiling) / 2.0

            # UI marker range
            if slider == "metalTone":
                snapped_min = snap_metal(dp_min)
                snapped_max = snap_metal(dp_max)
                ui_range = snapped_max - snapped_min
                # Estimate distinct positions from dp range
                distinct = 1
                if dp_range > 0.33:
                    distinct = 2
                if dp_min < 0.33 and dp_max > 0.67:
                    distinct = 3
            else:
                ui_range = dp_range
                distinct = max(1, int(dp_range * 30))  # approximate distinct positions

            dp_ranges.append(dp_range)
            raw_ranges_approx.append(raw_range)
            baseline_delta_ranges.append(delta_range)
            envelope_spans.append(span)
            clamp_rates.append(clamp_rate)
            ui_marker_ranges.append(ui_range)
            ui_distinct_counts.append(distinct)

        n = len(dp_ranges)
        if n == 0:
            continue

        sorted_dp = sorted(dp_ranges)
        sorted_raw = sorted(raw_ranges_approx)

        # Envelope utilization: how much of the envelope is actually used
        mean_raw = sum(raw_ranges_approx) / n
        mean_span = sum(envelope_spans) / n
        utilization = mean_raw / mean_span if mean_span > 0 else 0

        aggregate[slider] = {
            "nUsers": n,
            "meanRawRange": round(sum(raw_ranges_approx) / n, 4),
            "p50RawRange": round(sorted_raw[n // 2], 4),
            "meanBaselineDeltaRange": round(sum(baseline_delta_ranges) / n, 4),
            "meanEnvelopeSpan": round(mean_span, 4),
            "envelopeUtilization": round(utilization, 4),
            "meanDisplayPositionRange": round(sum(dp_ranges) / n, 4),
            "p10DpRange": round(sorted_dp[int(n * 0.1)], 4),
            "p50DpRange": round(sorted_dp[n // 2], 4),
            "p90DpRange": round(sorted_dp[int(n * 0.9)], 4),
            "meanClampRate": round(sum(clamp_rates) / n, 4),
            "pctUsersClampAny": round(sum(1 for c in clamp_rates if c > 0) / n * 100, 1),
            "pctUsersClampHigh": round(sum(1 for c in clamp_rates if c > 0.1) / n * 100, 1),
            "meanUiMarkerRange": round(sum(ui_marker_ranges) / n, 4),
            "meanUiDistinctPositions": round(sum(ui_distinct_counts) / n, 1),
            "pctStuckOneTertile_dp": round(sum(1 for r in dp_ranges if r < 0.33) / n * 100, 1),
            "pctStuckOneTertile_ui": round(sum(1 for r in ui_marker_ranges if r < 0.33) / n * 100, 1),
        }

    # Variant envelope summary
    variant_summary = []
    for i, ve in enumerate(variant_envelopes):
        v = VARIANTS[i]
        summary = {"variant": i, "config": f"{v['saturation']}/{v['contrast']}/{v['temperature']}"}
        for slider in slider_names:
            summary[slider] = {
                "baseline": round(ve[slider]["baseline"], 4),
                "floor": round(ve[slider]["floor"], 4),
                "ceiling": round(ve[slider]["ceiling"], 4),
                "span": round(ve[slider]["span"], 4),
            }
        variant_summary.append(summary)

    output = {
        "generated": "2026-06-10",
        "engine": "stage1_experimental",
        "cohort": "synthetic_cohort",
        "nUsers": len(users_data),
        "window": {"start": "2026-05-01", "days": 60},
        "aggregate": aggregate,
        "variantEnvelopes": variant_summary,
    }

    out_json = FIXTURES / "slider_range_audit.json"
    out_json.write_text(json.dumps(output, indent=2, sort_keys=True))

    # Write TXT
    txt = "Slider Range Audit — Full Diagnostic\n"
    txt += "Engine: stage1_experimental | 216 users × 60 days | 2026-05-01\n"
    txt += "═" * 90 + "\n\n"

    for name in slider_names:
        agg = aggregate.get(name, {})
        if not agg:
            continue
        txt += f"┌─ {name.upper()} {'─' * max(0, 70 - len(name))}\n"
        txt += f"│ Raw value range (mean):          {agg['meanRawRange']:.4f}\n"
        txt += f"│ Raw value range (p50):           {agg['p50RawRange']:.4f}\n"
        txt += f"│ Baseline-relative delta (mean):  {agg['meanBaselineDeltaRange']:.4f}\n"
        txt += f"│ Envelope span (mean):            {agg['meanEnvelopeSpan']:.4f}\n"
        txt += f"│ Envelope utilization:            {agg['envelopeUtilization']:.4f}\n"
        txt += f"│ Display position range (mean):   {agg['meanDisplayPositionRange']:.4f}\n"
        txt += f"│ Display position range (p10/p50/p90): {agg['p10DpRange']:.3f}/{agg['p50DpRange']:.3f}/{agg['p90DpRange']:.3f}\n"
        txt += f"│ Clamp rate (mean):               {agg['meanClampRate']:.4f}\n"
        txt += f"│ Users with any clamping:         {agg['pctUsersClampAny']:.0f}%\n"
        txt += f"│ Users with >10% clamping:        {agg['pctUsersClampHigh']:.0f}%\n"
        txt += f"│ UI marker range (mean):          {agg['meanUiMarkerRange']:.4f}\n"
        txt += f"│ UI distinct positions (mean):    {agg['meanUiDistinctPositions']:.1f}\n"
        txt += f"│ Stuck one tertile (dp):          {agg['pctStuckOneTertile_dp']:.0f}%\n"
        txt += f"│ Stuck one tertile (UI):          {agg['pctStuckOneTertile_ui']:.0f}%\n"
        txt += f"└{'─' * 88}\n\n"

    txt += "═" * 90 + "\n"
    txt += "DIAGNOSIS SUMMARY\n\n"
    txt += "Bottleneck key: [E]=Envelope [S]=Signal [U]=UI [C]=Coherence cap\n\n"

    for name in slider_names:
        agg = aggregate.get(name, {})
        if not agg:
            continue
        dp_range = agg["meanDisplayPositionRange"]
        ui_range = agg["meanUiMarkerRange"]
        util = agg["envelopeUtilization"]
        clamp = agg["meanClampRate"]

        bottlenecks = []
        if util < 0.5:
            bottlenecks.append("[E] envelope too wide for actual signal")
        if dp_range < 0.4:
            bottlenecks.append("[S] weak daily signal variation")
        if ui_range < dp_range * 0.8:
            bottlenecks.append("[U] UI snap compresses range")
        if clamp > 0.05:
            bottlenecks.append("[E] envelope too narrow (clamping)")

        status = "OK" if dp_range >= 0.5 else ("WEAK" if dp_range >= 0.35 else "POOR")
        txt += f"  {name:<20} [{status}] "
        txt += " + ".join(bottlenecks) if bottlenecks else "— no major bottleneck"
        txt += "\n"

    txt += "\n" + "═" * 90 + "\n"
    txt += "VARIANT ENVELOPE REFERENCE\n\n"
    for vs in variant_summary:
        txt += f"  Variant {vs['variant']}: {vs['config']}\n"
        for slider in slider_names:
            s = vs[slider]
            txt += f"    {slider:<20} baseline={s['baseline']:.3f}  floor={s['floor']:.3f}  ceiling={s['ceiling']:.3f}  span={s['span']:.3f}\n"
        txt += "\n"

    out_txt = FIXTURES / "slider_range_audit.txt"
    out_txt.write_text(txt)

    print(txt)
    print(f"\nWrote: {out_json}")
    print(f"Wrote: {out_txt}")


if __name__ == "__main__":
    main()
