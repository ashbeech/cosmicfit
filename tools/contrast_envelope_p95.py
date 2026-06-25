#!/usr/bin/env python3
"""Compute P95 contrast baseline deviation from inspector cohort sample."""

from __future__ import annotations

import json
import statistics
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSPECTOR_URL = "http://127.0.0.1:7777/api/inspect"
ENGINE = "stage1_experimental"


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


def main() -> int:
    cohort_path = ROOT / "inspector" / "Resources" / "synthetic_cohort.json"
    users = json.loads(cohort_path.read_text(encoding="utf-8"))
    start = datetime.strptime("2026-04-23", "%Y-%m-%d").date()
    days = 60
    dates = [(start + timedelta(days=i)).isoformat() for i in range(days)]

    deviations: list[float] = []

    def sample(user: dict, d: str) -> float | None:
        resp = inspect(user, d)
        payload = resp["dailyFit"]["payload"]
        sp = payload.get("scalePresentation")
        if not sp or "contrast" not in sp:
            return None
        raw = float(payload["contrast"])
        baseline = float(sp["contrast"]["baseline"])
        return abs(raw - baseline)

    tasks = [(u, d) for u in users for d in dates]
    with ThreadPoolExecutor(max_workers=8) as pool:
        futures = {pool.submit(sample, u, d): (u["id"], d) for u, d in tasks}
        done = 0
        for fut in as_completed(futures):
            done += 1
            if done % 2000 == 0:
                print(f"  {done}/{len(tasks)}", file=sys.stderr)
            try:
                val = fut.result()
                if val is not None:
                    deviations.append(val)
            except Exception as exc:
                uid, d = futures[fut]
                print(f"WARN {uid}@{d}: {exc}", file=sys.stderr)

    if not deviations:
        print("No deviations collected", file=sys.stderr)
        return 1

    deviations.sort()
    p95_idx = int(len(deviations) * 0.95)
    p95 = deviations[min(p95_idx, len(deviations) - 1)]
    half_span = round(min(0.22, max(0.14, round(p95 + 0.04, 2))), 2)

    out = {
        "nSamples": len(deviations),
        "p95Deviation": round(p95, 4),
        "recommendedHalfSpan": half_span,
        "formula": "clamp(round(P95 + 0.04, 2), min=0.14, max=0.22)",
    }
    out_path = ROOT / "docs" / "fixtures" / "contrast_envelope_p95.json"
    out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    print(f"Wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
