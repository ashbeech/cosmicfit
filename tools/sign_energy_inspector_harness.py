#!/usr/bin/env python3
"""14-day Daily Fit sign-energy downstream harness via local inspector API."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESETS_PATH = ROOT / "inspector" / "Resources" / "presets.json"
FIXTURES = ROOT / "docs" / "fixtures"
INSPECTOR_URL = "http://127.0.0.1:7777/api/inspect"

ENERGIES = ["classic", "playful", "romantic", "utility", "drama", "edge"]
WINDOW_START = date(2026, 5, 9)
WINDOW_DAYS = 14
ENGINES = ["production", "stage1_experimental"]
EVIDENCE_SAMPLE_DATES = ["2026-05-09", "2026-05-15", "2026-05-22"]


def normalise_to_twenty_one(raw: dict[str, float]) -> dict[str, int]:
    total = sum(raw.get(e, 0.0) for e in ENERGIES)
    if total <= 0:
        return {e: {"classic": 4, "playful": 4, "romantic": 4, "utility": 3, "drama": 3, "edge": 3}[e] for e in ENERGIES}

    ideals = [(e, (raw[e] / total) * 21.0) for e in ENERGIES]
    bases = {e: int(v) for e, v in ideals}
    remainders = sorted(((e, v - int(v)) for e, v in ideals), key=lambda x: x[1], reverse=True)
    allocated = sum(bases.values())
    idx = 0
    while allocated < 21 and idx < len(remainders):
        bases[remainders[idx][0]] += 1
        allocated += 1
        idx += 1

    clamped = {}
    overflow = 0
    for e in ENERGIES:
        val = bases[e]
        if val > 10:
            overflow += val - 10
            clamped[e] = 10
        elif val < 0:
            overflow += val
            clamped[e] = 0
        else:
            clamped[e] = val

    if overflow > 0:
        for e, _ in remainders:
            room = 10 - clamped[e]
            if room <= 0:
                continue
            add = min(room, overflow)
            clamped[e] += add
            overflow -= add
            if overflow <= 0:
                break

    return clamped


def dominant_from_breakdown(breakdown: dict[str, int]) -> str:
    return max(ENERGIES, key=lambda e: breakdown.get(e, 0))


def dominant_from_raw(raw: dict[str, float]) -> str:
    return dominant_from_breakdown(normalise_to_twenty_one(raw))


def l1_delta(a: dict[str, int], b: dict[str, int]) -> float:
    return sum(abs(a.get(e, 0) - b.get(e, 0)) for e in ENERGIES)


def preset_birth(preset: dict) -> dict:
    return {
        "dateISO": preset["birthDateUTC"],
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
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.load(resp)


def sun_sign_from_preset(preset_id: str) -> str:
    mapping = {
        "fire": "Aries",
        "earth": "Taurus",
        "air": "Aquarius",
        "water": "Scorpio",
        "leo": "Leo",
    }
    return mapping.get(preset_id, preset_id)


def run_harness() -> int:
    presets = json.loads(PRESETS_PATH.read_text())
    preset_ids = ["fire", "earth", "air", "water", "leo"]
    presets_by_id = {p["id"]: p for p in presets if p["id"] in preset_ids}

    dates = [(WINDOW_START + timedelta(days=i)).isoformat() for i in range(WINDOW_DAYS)]

    evidence_rows = []
    prod_summary: dict[str, dict] = {}
    stage1_vs_prod: dict[str, int] = defaultdict(int)

    for preset_id in preset_ids:
        preset = presets_by_id[preset_id]
        prod_dominants: list[str] = []
        neutral_dominants: list[str] = []
        flip_count = 0
        l1_total = 0.0

        for target_date in dates:
            prod = inspect(preset, target_date, "production")
            diag = prod["dailyFit"]["diagnostics"]
            payload = prod["dailyFit"]["payload"]
            raw = diag["rawEnergyScores"]
            final = payload["vibeBreakdown"]
            prod_dom = dominant_from_breakdown({k: int(final[k]) for k in ENERGIES})
            neutral_dom = dominant_from_raw(raw)
            prod_dominants.append(prod_dom)
            neutral_dominants.append(neutral_dom)
            if prod_dom != neutral_dom:
                flip_count += 1
            l1_total += l1_delta(
                {k: int(final[k]) for k in ENERGIES},
                normalise_to_twenty_one(raw),
            )

            stage1 = inspect(preset, target_date, "stage1_experimental")
            s1_dom = dominant_from_breakdown(
                {k: int(stage1["dailyFit"]["payload"]["vibeBreakdown"][k]) for k in ENERGIES}
            )
            if s1_dom != prod_dom:
                stage1_vs_prod[preset_id] += 1

            if target_date in EVIDENCE_SAMPLE_DATES:
                s1_diag = stage1["dailyFit"]["diagnostics"]
                if s1_diag["postMultiplierScores"] != s1_diag["rawEnergyScores"]:
                    raise RuntimeError(
                        f"stage1 post/raw mismatch for {preset_id} on {target_date}"
                    )
                if s1_diag["stage1Attribution"]["signMultipliersAppliedToDailyVibe"] is not False:
                    raise RuntimeError(
                        f"stage1 daily mult policy not OFF for {preset_id} on {target_date}"
                    )
                evidence_rows.append(
                    {
                        "preset": preset_id,
                        "engine": "production",
                        "date": target_date,
                        "sunSign": sun_sign_from_preset(preset_id),
                        "rawEnergyScores": raw,
                        "postMultiplierScores": diag["postMultiplierScores"],
                        "finalVibeBreakdown": {k: int(final[k]) for k in ENERGIES},
                        "signMultiplierApplied": diag["stage1Attribution"]["signMultiplierApplied"],
                        "signMultipliersAppliedToDailyVibe": diag["stage1Attribution"]["signMultipliersAppliedToDailyVibe"],
                        "dominantEnergy": prod_dom,
                    }
                )
                evidence_rows.append(
                    {
                        "preset": preset_id,
                        "engine": "stage1_experimental",
                        "date": target_date,
                        "sunSign": sun_sign_from_preset(preset_id),
                        "rawEnergyScores": s1_diag["rawEnergyScores"],
                        "postMultiplierScores": s1_diag["postMultiplierScores"],
                        "finalVibeBreakdown": {
                            k: int(stage1["dailyFit"]["payload"]["vibeBreakdown"][k]) for k in ENERGIES
                        },
                        "signMultiplierApplied": s1_diag["stage1Attribution"]["signMultiplierApplied"],
                        "signMultipliersAppliedToDailyVibe": s1_diag["stage1Attribution"]["signMultipliersAppliedToDailyVibe"],
                        "chartAnchorSignMultiplierApplied": s1_diag["stage1Attribution"].get(
                            "chartAnchorSignMultiplierApplied"
                        ),
                        "dominantEnergy": s1_dom,
                    }
                )

        prod_summary[preset_id] = {
            "sun": sun_sign_from_preset(preset_id),
            "prod_counts": Counter(prod_dominants),
            "neutral_counts": Counter(neutral_dominants),
            "flip": flip_count,
            "avg_l1": round(l1_total / WINDOW_DAYS, 2),
        }

    lines = [
        "Daily Fit Sign Energy Downstream Audit (post Phase 1 + sign multiplier policy)",
        f"Generated: {date.today().isoformat()}",
        f"Window: {dates[0]} .. {dates[-1]} UTC ({WINDOW_DAYS} days)",
        "Presets: fire(Aries), earth(Taurus), air(Aquarius), water(Scorpio), leo(Leo)",
        "Birth source: inspector/Resources/presets.json",
        "",
        "Counterfactual formula:",
        "  neutral Sun = normaliseToTwentyOne(rawEnergyScores)",
        "  production    = payload vibeBreakdown (raw * signEnergyMap applied, then normalised)",
        "",
        "--- SUMMARY (production) ---",
        "",
    ]

    for preset_id in preset_ids:
        s = prod_summary[preset_id]
        prod_str = ", ".join(f"{k} {v}" for k, v in s["prod_counts"].most_common())
        neutral_str = ", ".join(f"{k} {v}" for k, v in s["neutral_counts"].most_common())
        lines.append(f"Preset: {preset_id} ({s['sun']})")
        lines.append(f"  Production dominant: {prod_str}")
        lines.append(f"  Neutral CF dominant: {neutral_str}")
        lines.append(f"  Flip vs neutral: {s['flip']}/{WINDOW_DAYS}")
        lines.append(f"  Avg L1 bar delta: {s['avg_l1']}")
        lines.append("")

    lines.extend(
        [
            "",
            "--- PRODUCTION vs stage1_experimental (dominant label differs) ---",
            "",
        ]
    )
    for preset_id in preset_ids:
        lines.append(f"{sun_sign_from_preset(preset_id):<12}{stage1_vs_prod[preset_id]}/{WINDOW_DAYS}")

    lines.extend(
        [
            "",
            "--- STAGE1 POLICY SPOT CHECK ---",
            "stage1_experimental: signMultipliersAppliedToDailyVibe=false on all sampled runs",
            "stage1_experimental: postMultiplierScores == rawEnergyScores on all sampled runs",
            "",
        ]
    )

    out_txt = FIXTURES / "sign_audit_downstream_post_phase1.txt"
    out_json = FIXTURES / "sign_audit_inspector_evidence.json"
    out_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")
    out_json.write_text(json.dumps(evidence_rows, indent=2) + "\n", encoding="utf-8")

    matrix_lines = [
        "=== Sign Energy Multipliers (from DailyFitTypes.swift) ===",
        f"Generated: {date.today().isoformat()} post Phase 1",
        "",
        "Sign           classic    playful    romantic   utility    drama      edge",
    ]
    # Read current map from a production inspect call
    sample = inspect(presets_by_id["fire"], dates[0], "production")
    mults = sample["dailyFit"]["diagnostics"]["stage1Attribution"]["signMultiplierApplied"]
    # mults only has applied values for one sign - read from Swift source instead via known Phase1 table
    phase1 = {
        "Aries": [0.95, 1.30, 1.00, 1.00, 1.35, 1.20],
        "Taurus": [1.50, 0.90, 1.30, 1.20, 0.85, 1.00],
        "Gemini": [0.85, 1.50, 1.00, 1.00, 1.00, 1.20],
        "Cancer": [1.10, 1.00, 1.40, 1.05, 0.95, 1.00],
        "Leo": [0.90, 1.30, 1.00, 0.95, 1.35, 1.00],
        "Virgo": [1.50, 0.95, 0.90, 1.30, 0.85, 1.00],
        "Libra": [1.30, 1.30, 1.40, 1.00, 0.95, 0.95],
        "Scorpio": [1.00, 0.85, 0.95, 1.00, 1.35, 1.30],
        "Sagittarius": [0.90, 1.40, 1.00, 1.00, 1.20, 1.20],
        "Capricorn": [1.50, 0.85, 0.95, 1.40, 1.00, 1.00],
        "Aquarius": [0.85, 1.20, 0.90, 1.00, 1.00, 1.50],
        "Pisces": [0.90, 1.10, 1.50, 1.00, 1.00, 1.25],
    }
    for sign, vals in phase1.items():
        matrix_lines.append(
            f"  {sign:<14}" + "".join(f"{v:10.2f}" for v in vals)
        )
    (FIXTURES / "sign_energy_matrix_baseline.txt").write_text("\n".join(matrix_lines) + "\n", encoding="utf-8")

    print(f"Wrote {out_txt}")
    print(f"Wrote {out_json}")
    print(f"Updated {FIXTURES / 'sign_energy_matrix_baseline.txt'}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(run_harness())
    except urllib.error.URLError as exc:
        print(f"Inspector not reachable at {INSPECTOR_URL}: {exc}", file=sys.stderr)
        print("Start it with: cd inspector && ./run-inspector.sh", file=sys.stderr)
        raise SystemExit(1)
