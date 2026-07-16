#!/usr/bin/env python3
"""Production readiness audit harness.

Generates sequential multi-day DailyFit outputs + one Style Guide (Blueprint)
per user through the inspector server (http://127.0.0.1:7777), simulating the
real user experience: tarot/variant recency state persists across days
(history is reset only on each user's first day).

Usage:
  python3 tools/production_audit_harness.py [--days 45] [--start 2026-06-10]
      [--synthetic-stride 4] [--parallel 5] [--out docs/fixtures/production_audit]

Output:
  <out>/raw/<user_id>.jsonl        one trimmed record per user-day
  <out>/blueprints/<user_id>.json  full Style Guide blueprint (day 1)
  <out>/manifest.json              cohort + run metadata
"""

from __future__ import annotations

import argparse
import json
import sys
import threading
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSPECTOR_URL = "http://127.0.0.1:7777/api/inspect"
ENGINE = "production"

_print_lock = threading.Lock()


def load_cohort(synthetic_stride: int) -> list[dict]:
    presets = json.loads((ROOT / "inspector" / "Resources" / "presets.json").read_text())
    synth = json.loads((ROOT / "inspector" / "Resources" / "synthetic_cohort.json").read_text())
    cohort = list(presets) + synth[::synthetic_stride]
    return cohort


def inspect(user: dict, target_date: str, first_day: bool) -> dict:
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
            "composeBlueprint": first_day,
            "includeProgressed": True,
            "resetTarotHistory": first_day,
            "dailyFitEngineId": ENGINE,
        },
    }
    req = urllib.request.Request(
        INSPECTOR_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    last_err: Exception | None = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.loads(resp.read())
        except Exception as e:  # noqa: BLE001 - retry then surface
            last_err = e
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"inspect failed for {user['id']} {target_date}: {last_err}")


def trim_record(user_id: str, target_date: str, resp: dict) -> dict:
    df = resp.get("dailyFit") or {}
    p = df.get("payload") or {}
    g = df.get("diagnostics") or {}

    tarot = p.get("tarotCard") or {}
    sev = p.get("styleEditVariant") or {}
    ep = p.get("essenceProfile") or {}
    palette = (p.get("dailyPalette") or {}).get("colours") or []
    scales = p.get("scalePresentation") or {}
    sil = p.get("silhouetteProfile") or {}

    all_scores = sorted(
        (ep.get("allScores") or []), key=lambda x: -x.get("score", 0)
    )
    return {
        "user": user_id,
        "date": target_date,
        "tarot": {
            "name": tarot.get("name"),
            "arcana": tarot.get("arcana"),
            "suit": tarot.get("suit"),
            "keywords": tarot.get("keywords") or [],
            "themes": tarot.get("themes") or [],
        },
        "styleEdit": {
            "title": sev.get("title"),
            "variant": sev.get("variant"),
            "description": sev.get("description"),
            "dailyRitual": sev.get("dailyRitual"),
            "wardrobeReflection": sev.get("wardrobeReflection"),
            "energyEmphasis": sev.get("energyEmphasis") or {},
        },
        "essences": {
            "visible": [
                {"category": e.get("category"), "score": e.get("score")}
                for e in (ep.get("visibleCategories") or [])
            ],
            "rankedAll": [
                {"category": e.get("category"), "score": e.get("score")}
                for e in all_scores
            ],
        },
        "axes": p.get("axes") or {},
        "vibeBreakdown": p.get("vibeBreakdown") or {},
        "raw": {
            "vibrancy": p.get("vibrancy"),
            "contrast": p.get("contrast"),
            "metalTone": p.get("metalTone"),
            "silhouette": {
                "angularRounded": sil.get("angularRounded"),
                "masculineFeminine": sil.get("masculineFeminine"),
                "structuredDraped": sil.get("structuredDraped"),
            },
        },
        "displayPositions": {
            k: (v or {}).get("displayPosition") for k, v in scales.items()
        },
        "palette": [
            {"name": c.get("name"), "hex": c.get("hexValue"), "role": c.get("role")}
            for c in palette
        ],
        "pattern": p.get("dailyPattern"),
        "textures": p.get("dailyTextures") or [],
        "lunar": (p.get("lunarContext") or {}).get("phaseName"),
        "dominantTransits": [
            f"{t.get('transitPlanet')} {t.get('aspect')} {t.get('natalPlanet')}"
            for t in (p.get("dominantTransits") or [])[:3]
        ],
        "diag": {
            "coherence": g.get("narrativeCoherenceTrace") or {},
            "bridge": {
                k: (g.get("narrativeBridgeTrace") or {}).get(k)
                for k in (
                    "bridgePass",
                    "variantBridgeSimilarity",
                    "selectedVariantIndex",
                    "variantRecencySwapped",
                    "funnelCardCount",
                )
            },
            "intent": g.get("narrativeIntentTrace") or {},
            "variantRotationIndex": g.get("variantRotationIndex"),
        },
        "verdicts": {
            v.get("id"): v.get("status") for v in (resp.get("verdicts") or [])
        },
    }


def run_user(user: dict, days: list[str], out_raw: Path, out_bp: Path) -> str:
    uid = user["id"]
    existing = out_raw / f"{uid}.jsonl"
    if existing.exists() and len(existing.read_text().splitlines()) == len(days):
        return uid  # already complete (resume)
    records = []
    for i, d in enumerate(days):
        resp = inspect(user, d, first_day=(i == 0))
        if i == 0 and resp.get("blueprint"):
            (out_bp / f"{uid}.json").write_text(
                json.dumps(resp["blueprint"], indent=1, sort_keys=True)
            )
        records.append(trim_record(uid, d, resp))
    with (out_raw / f"{uid}.jsonl").open("w") as f:
        for r in records:
            f.write(json.dumps(r, sort_keys=True) + "\n")
    return uid


def main() -> None:
    global ENGINE
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=45)
    ap.add_argument("--start", type=str, default="2026-06-10")
    ap.add_argument("--synthetic-stride", type=int, default=4)
    ap.add_argument("--parallel", type=int, default=5)
    ap.add_argument("--out", type=str, default="docs/fixtures/production_audit")
    ap.add_argument("--engine", default=ENGINE,
                    help=f"Daily Fit engine id the inspector should run (default: {ENGINE}). "
                         f"Use sky_forward_v1_0_2 to audit v1.0.2 before the production cutover.")
    args = ap.parse_args()
    ENGINE = args.engine

    out = ROOT / args.out
    out_raw = out / "raw"
    out_bp = out / "blueprints"
    out_raw.mkdir(parents=True, exist_ok=True)
    out_bp.mkdir(parents=True, exist_ok=True)

    cohort = load_cohort(args.synthetic_stride)
    start = date.fromisoformat(args.start)
    days = [(start + timedelta(days=i)).isoformat() for i in range(args.days)]

    print(f"Audit harness: {len(cohort)} users x {args.days} days "
          f"({len(cohort) * args.days} calls), start {args.start}", flush=True)

    (out / "manifest.json").write_text(json.dumps({
        "engine": ENGINE,
        "start": args.start,
        "days": args.days,
        "users": [u["id"] for u in cohort],
        "generatedBy": "tools/production_audit_harness.py",
    }, indent=1))

    done = 0
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=args.parallel) as ex:
        futures = {ex.submit(run_user, u, days, out_raw, out_bp): u["id"] for u in cohort}
        for fut in as_completed(futures):
            uid = futures[fut]
            try:
                fut.result()
                done += 1
                with _print_lock:
                    print(f"  [{done}/{len(cohort)}] {uid} done "
                          f"({time.time() - t0:.0f}s elapsed)", flush=True)
            except Exception as e:  # noqa: BLE001
                with _print_lock:
                    print(f"  FAILED {uid}: {e}", file=sys.stderr, flush=True)

    print(f"Complete in {time.time() - t0:.0f}s -> {out}", flush=True)


if __name__ == "__main__":
    main()
