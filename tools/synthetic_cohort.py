#!/usr/bin/env python3
"""Generate a deterministic synthetic cohort for Daily Fit narrative layer testing.

Produces 216 synthetic birth charts spanning diverse astrological configurations:
  12 sun signs × 3 birth times (ascendant diversity) × 3 locations × 2 year offsets

Each chart is deterministically generated from a fixed seed. Rerunning this script
produces byte-identical output.

Usage:
    python3 tools/synthetic_cohort.py [--verify]

Flags:
    --verify   Assert output matches existing file (CI determinism check)

Output:
    inspector/Resources/synthetic_cohort.json
"""

from __future__ import annotations

import hashlib
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = ROOT / "inspector" / "Resources" / "synthetic_cohort.json"

SEED = 42

# Sun sign date ranges (approximate ingress dates for non-leap years).
# Each entry: (sign_name, month, day) — the sun enters that sign around this date.
SUN_SIGN_INGRESSES = [
    ("aries", 3, 21),
    ("taurus", 4, 20),
    ("gemini", 5, 21),
    ("cancer", 6, 21),
    ("leo", 7, 23),
    ("virgo", 8, 23),
    ("libra", 9, 23),
    ("scorpio", 10, 23),
    ("sagittarius", 11, 22),
    ("capricorn", 12, 22),
    ("aquarius", 1, 20),
    ("pisces", 2, 19),
]

# Birth times chosen to produce different ascendant signs (rising changes ~every 2h).
BIRTH_TIMES_UTC = [
    (4, 0),   # pre-dawn — typically places asc ~2 signs before sun
    (12, 0),  # midday — asc roughly opposite sun
    (20, 0),  # evening — asc ~4 signs after sun
]

# Geographic locations for timezone / chart variation.
LOCATIONS = [
    {"latitude": 51.5074, "longitude": -0.1278, "timeZoneId": "Europe/London", "city": "London"},
    {"latitude": 40.7128, "longitude": -74.0060, "timeZoneId": "America/New_York", "city": "New York"},
    {"latitude": -33.8688, "longitude": 151.2093, "timeZoneId": "Australia/Sydney", "city": "Sydney"},
]

# Birth years — two offsets for generational planet variation.
BIRTH_YEARS = [1985, 1992]


def generate_cohort() -> list[dict]:
    """Generate 216 deterministic synthetic users."""
    cohort: list[dict] = []
    idx = 0

    for sign_name, month, day in SUN_SIGN_INGRESSES:
        # Place birth date 5 days after ingress to ensure sun is solidly in sign.
        base_day = day + 5

        for year in BIRTH_YEARS:
            for hour, minute in BIRTH_TIMES_UTC:
                for loc in LOCATIONS:
                    try:
                        birth_dt = datetime(year, month, base_day, hour, minute, 0, tzinfo=timezone.utc)
                    except ValueError:
                        # Handle month overflow (e.g. day 37 in a short month).
                        # Roll into next month.
                        overflow_date = datetime(year, month, 1, hour, minute, 0, tzinfo=timezone.utc)
                        birth_dt = overflow_date + timedelta(days=base_day - 1)

                    user_id = f"synth_{idx:03d}_{sign_name}_{loc['city'].lower().replace(' ', '')}"
                    label = (
                        f"Synth {idx:03d} — {sign_name.title()} Sun, "
                        f"{birth_dt.strftime('%H:%M')} UTC, {loc['city']} ({year})"
                    )

                    cohort.append({
                        "id": user_id,
                        "label": label,
                        "birthDateUTC": birth_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
                        "latitude": loc["latitude"],
                        "longitude": loc["longitude"],
                        "timeZoneId": loc["timeZoneId"],
                        "generatorSeed": SEED,
                        "sunSign": sign_name,
                        "birthYear": year,
                    })
                    idx += 1

    return cohort


def main() -> int:
    verify_mode = "--verify" in sys.argv

    cohort = generate_cohort()
    content = json.dumps(cohort, indent=2, ensure_ascii=False) + "\n"

    if verify_mode:
        if not OUTPUT_PATH.exists():
            print(f"FAIL: {OUTPUT_PATH} does not exist", file=sys.stderr)
            return 1
        existing = OUTPUT_PATH.read_text(encoding="utf-8")
        if existing != content:
            expected_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
            actual_hash = hashlib.sha256(existing.encode()).hexdigest()[:16]
            print(
                f"FAIL: Output is not byte-identical.\n"
                f"  Expected SHA256 prefix: {expected_hash}\n"
                f"  Actual SHA256 prefix:   {actual_hash}",
                file=sys.stderr,
            )
            return 1
        print(f"PASS: {OUTPUT_PATH} is byte-identical ({len(cohort)} users)")
        return 0

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(content, encoding="utf-8")
    file_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
    print(f"Generated {len(cohort)} synthetic users → {OUTPUT_PATH}")
    print(f"SHA256 prefix: {file_hash}")
    print(f"Determinism: rerun with --verify to confirm byte-identical output")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
