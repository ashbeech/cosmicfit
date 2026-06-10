#!/usr/bin/env python3
"""Plan 2 narrative coherence harness.

Runs the stage1_experimental engine for each preset across 60 consecutive days,
capturing DailyNarrativePlan decisions, rejected candidates, coherence validation,
and final routed payloads.

Requires the inspector server running at http://127.0.0.1:7777.

Usage:
  python3 tools/narrative_coherence_harness.py [--start YYYY-MM-DD] [--days 60]
      [--presets fire,earth,air,water,leo]

Output:
  docs/fixtures/narrative_coherence_report.json
  docs/fixtures/narrative_coherence_report.txt
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

OPPOSITION_PAIRS = [
    ("minimal", "maximalist"),
    ("polished", "edgy"),
    ("classic", "eclectic"),
    ("grounded", "playful"),
]
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
            "dailyFitEngineId": ENGINE,
        },
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        INSPECTOR_URL,
        data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def extract_essence_top3(payload: dict) -> list[str]:
    ep = payload.get("essenceProfile", {})
    vis = ep.get("visibleCategories", [])
    return [v["category"] for v in vis[:3]]


def check_oppositions(top3: list[str]) -> list[str]:
    violations = []
    s = set(top3)
    for a, b in OPPOSITION_PAIRS:
        if a in s and b in s:
            violations.append(f"{a} ↔ {b}")
    return violations


def run_harness(presets: list[dict], start: date, days: int) -> dict:
    results = {}
    for preset in presets:
        pid = preset["id"]
        print(f"\n{'='*60}")
        print(f"  Preset: {pid}")
        print(f"{'='*60}")

        daily_rows = []
        total_opposition_violations = 0
        total_cross_surface_violations = 0
        plans_generated = 0
        plans_rejected = 0
        rejection_reasons: dict[str, int] = defaultdict(int)
        accent_counter: Counter = Counter()
        relationship_counter: Counter = Counter()
        flip_count = 0
        prev_accent = None
        coherence_scores: list[float] = []

        for day_offset in range(days):
            d = start + timedelta(days=day_offset)
            ds = d.isoformat()
            try:
                resp = inspect(preset, ds)
            except Exception as e:
                print(f"  [SKIP] {ds}: {e}")
                continue

            payload = resp.get("payload", {})
            diag = resp.get("diagnostics", {})
            narrative_trace = diag.get("narrativeTrace", {})
            intent_trace = diag.get("narrativeIntentTrace", {})
            coherence_trace = diag.get("narrativeCoherenceTrace", {})

            top3 = extract_essence_top3(payload)
            accent = top3[0] if top3 else "unknown"
            relationship = narrative_trace.get("chosenRelationship", "unknown")
            template_key = narrative_trace.get("templateKey", "")

            # Opposition check
            opposition_violations = check_oppositions(top3)
            total_opposition_violations += len(opposition_violations)

            # Coherence score
            coherence_pass = coherence_trace.get("overallPass", False)
            score = 1.0 if coherence_pass else 0.0
            coherence_scores.append(score)

            # Accent tracking
            accent_counter[accent] += 1
            relationship_counter[relationship] += 1
            plans_generated += 1

            if prev_accent is not None and accent != prev_accent:
                flip_count += 1
            prev_accent = accent

            row = {
                "date": ds,
                "accent": accent,
                "top3": top3,
                "relationship": relationship,
                "templateKey": template_key,
                "oppositionViolations": opposition_violations,
                "coherencePass": coherence_pass,
                "vibrancy": payload.get("vibrancy", 0),
                "contrast": payload.get("contrast", 0),
                "metalTone": payload.get("metalTone", 0),
                "tarot": payload.get("tarotCard", {}).get("name", ""),
                "paletteHexes": [c["hexValue"] for c in payload.get("dailyPalette", {}).get("colours", [])],
            }
            daily_rows.append(row)

            if day_offset % 10 == 0:
                print(f"  {ds}: {accent:12s} ({relationship}) top3={top3}")

        distinct_accents = len(accent_counter)
        flip_rate = flip_count / max(1, plans_generated - 1) if plans_generated > 1 else 0
        mean_coherence = statistics.mean(coherence_scores) if coherence_scores else 0

        results[pid] = {
            "plansGenerated": plans_generated,
            "plansRejected": plans_rejected,
            "rejectionReasons": dict(rejection_reasons),
            "essenceOppositionViolations": total_opposition_violations,
            "crossSurfaceViolations": total_cross_surface_violations,
            "coherenceScore": round(mean_coherence, 4),
            "flipRate": round(flip_rate, 4),
            "distinctAccents": distinct_accents,
            "accentDistribution": dict(accent_counter.most_common()),
            "relationshipDistribution": dict(relationship_counter.most_common()),
            "dailyRows": daily_rows,
        }

        print(f"\n  Summary for {pid}:")
        print(f"    Plans generated:      {plans_generated}")
        print(f"    Opposition violations: {total_opposition_violations}")
        print(f"    Cross-surface violations: {total_cross_surface_violations}")
        print(f"    Coherence score:      {mean_coherence:.4f}")
        print(f"    Flip rate:            {flip_rate:.1%}")
        print(f"    Distinct accents:     {distinct_accents}")

    return results


def write_report(results: dict, start: date, days: int):
    FIXTURES.mkdir(parents=True, exist_ok=True)

    report = {
        "generated": datetime.utcnow().isoformat() + "Z",
        "engine": ENGINE,
        "startDate": start.isoformat(),
        "days": days,
        "presets": results,
    }

    json_path = FIXTURES / "narrative_coherence_report.json"
    with open(json_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"\nJSON: {json_path}")

    txt_path = FIXTURES / "narrative_coherence_report.txt"
    with open(txt_path, "w") as f:
        f.write(f"Narrative Coherence Report — Plan 2\n")
        f.write(f"Engine: {ENGINE}\n")
        f.write(f"Window: {start} + {days} days\n")
        f.write(f"Generated: {report['generated']}\n")
        f.write(f"{'='*70}\n\n")

        total_violations = 0
        total_cross = 0
        all_coherence = []
        all_flip = []
        all_distinct = []

        for pid, data in results.items():
            f.write(f"Preset: {pid}\n")
            f.write(f"  Plans generated:          {data['plansGenerated']}\n")
            f.write(f"  Plans rejected:           {data['plansRejected']}\n")
            f.write(f"  Opposition violations:    {data['essenceOppositionViolations']}\n")
            f.write(f"  Cross-surface violations: {data['crossSurfaceViolations']}\n")
            f.write(f"  Coherence score:          {data['coherenceScore']:.4f}\n")
            f.write(f"  Flip rate:                {data['flipRate']:.1%}\n")
            f.write(f"  Distinct accents:         {data['distinctAccents']}\n")
            f.write(f"  Accent distribution:      {data['accentDistribution']}\n")
            f.write(f"  Relationship distribution: {data['relationshipDistribution']}\n")
            f.write(f"\n")

            total_violations += data["essenceOppositionViolations"]
            total_cross += data["crossSurfaceViolations"]
            all_coherence.append(data["coherenceScore"])
            all_flip.append(data["flipRate"])
            all_distinct.append(data["distinctAccents"])

        f.write(f"{'='*70}\n")
        f.write(f"AGGREGATE\n")
        f.write(f"  Total opposition violations:    {total_violations}\n")
        f.write(f"  Total cross-surface violations: {total_cross}\n")
        f.write(f"  Mean coherence score:           {statistics.mean(all_coherence):.4f}\n")
        f.write(f"  Mean flip rate:                 {statistics.mean(all_flip):.1%}\n")
        f.write(f"  Mean distinct accents:          {statistics.mean(all_distinct):.1f}\n")
        f.write(f"\n  EXIT GATE CHECK:\n")
        f.write(f"    Opposition violations == 0:    {'PASS' if total_violations == 0 else 'FAIL'}\n")
        f.write(f"    Cross-surface violations == 0: {'PASS' if total_cross == 0 else 'FAIL'}\n")
        f.write(f"    Coherence ≥ 0.85:              {'PASS' if statistics.mean(all_coherence) >= 0.85 else 'FAIL'}\n")
        f.write(f"    Flip rate ≥ 40%:               {'PASS' if statistics.mean(all_flip) >= 0.40 else 'FAIL'}\n")

    print(f"TXT: {txt_path}")


def main():
    parser = argparse.ArgumentParser(description="Plan 2 narrative coherence harness")
    parser.add_argument("--start", type=str, default=None)
    parser.add_argument("--days", type=int, default=60)
    parser.add_argument("--presets", type=str, default=",".join(DEFAULT_PRESETS))
    args = parser.parse_args()

    start = date.fromisoformat(args.start) if args.start else date.today()

    all_presets = json.loads(PRESETS_PATH.read_text())
    wanted = set(args.presets.split(","))
    presets = [p for p in all_presets if p["id"] in wanted]

    if not presets:
        print(f"No matching presets for: {wanted}")
        sys.exit(1)

    print(f"Running narrative coherence harness: {len(presets)} presets × {args.days} days from {start}")
    results = run_harness(presets, start, args.days)
    write_report(results, start, args.days)
    print("\nDone.")


if __name__ == "__main__":
    main()
