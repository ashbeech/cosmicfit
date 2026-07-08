#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 deliverables / validator report (Phase 3f review pack).

Scans the regenerated cache + quarantine + triage + run log and emits:
  - a validator report (paragraphs generated / passed / retried / quarantined,
    warning distribution, remaining triage),
  - a machine quality re-scan (dashes / banned tics / season words / formula
    propagation across every regenerated cluster),
  - an accessoryCategoryPlan comparison across registers.

Usage:
  python3 tools/sg3_report.py --cache data/style_guide/blueprint_narrative_cache.json
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sg_validation as V
from sg_profile import coarse_profile_from_key
from sg_accessory_plan import accessory_plan

REPO_ROOT = Path(__file__).resolve().parent.parent


def scan_quality(cache: dict) -> dict:
    issues = {"dash": [], "tic": [], "season": [], "formula_missing": [], "closing_bad": []}
    clusters = 0
    sections = 0
    for key, obj in cache.items():
        if key == "schema_version" or not isinstance(obj, dict):
            continue
        prof = coarse_profile_from_key(key)
        if prof is None:
            continue
        clusters += 1
        for sk, sec in obj.items():
            if sk in ("coreFormula", "closing") or not isinstance(sec, dict):
                continue
            sections += 1
            t = sec.get("text", "")
            if V.find_dashes(t):
                issues["dash"].append(f"{key}:{sk}")
            if V.find_banned_tics(t):
                issues["tic"].append(f"{key}:{sk} {V.find_banned_tics(t)}")
            if sk == "palette_narrative" and V.find_season_words(t):
                issues["season"].append(f"{key} {V.find_season_words(t)}")
        # formula propagation
        sc = obj.get("style_core", {})
        if isinstance(sc, dict) and prof.core_formula not in sc.get("text", ""):
            issues["formula_missing"].append(f"{key}:style_core")
        closing = obj.get("closing", "")
        if closing and not closing.rstrip(".").endswith(prof.core_formula):
            issues["closing_bad"].append(key)
    return {"clusters": clusters, "sections": sections, "issues": issues}


def run_log_stats(runlog_path: Path) -> dict:
    if not runlog_path.exists():
        return {}
    outcomes = Counter()
    warn_types = Counter()
    for line in runlog_path.read_text().splitlines():
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        if "outcome" in e and "section" in e:
            outcomes[e["outcome"]] += 1
            for w in e.get("warnings", []):
                warn_types[w.split(":")[0]] += 1
    return {"outcomes": dict(outcomes), "warning_types": dict(warn_types)}


def accessory_comparison(keys: list[str]) -> list[dict]:
    out = []
    for key in keys:
        prof = coarse_profile_from_key(key)
        if prof is None:
            continue
        plan = accessory_plan(prof.aesthetic_register, prof.orientation, prof.finish_lane)
        out.append({
            "cluster": key,
            "register": prof.aesthetic_register,
            "table_key": plan["table_key"],
            "include": [f"{i['category']} (slot {i['slot']}, {i['decision']})" for i in plan["include"]],
            "omit": [o["category"] for o in plan["omit"]],
            "merged": plan["overflow_merged"],
        })
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=str(REPO_ROOT / "data" / "style_guide" / "blueprint_narrative_cache.json"))
    ap.add_argument("--runlog", default=str(REPO_ROOT / "data" / "style_guide" / "sg3_run_log.jsonl"))
    ap.add_argument("--quarantine", default=str(REPO_ROOT / "data" / "style_guide" / "blueprint_narrative_cache_quarantine.json"))
    ap.add_argument("--triage", default=str(REPO_ROOT / "data" / "style_guide" / "triage_status.json"))
    ap.add_argument("--json", action="store_true", help="Emit JSON instead of markdown")
    args = ap.parse_args()

    cache = json.loads(Path(args.cache).read_text())
    quality = scan_quality(cache)
    logs = run_log_stats(Path(args.runlog))
    quarantine = json.loads(Path(args.quarantine).read_text()) if Path(args.quarantine).exists() else {}
    triage = json.loads(Path(args.triage).read_text()) if Path(args.triage).exists() else {}

    golden_sample = [
        "venus_taurus__moon_capricorn__earth_dominant",   # Slate quietLuxury earth
        "venus_leo__moon_aries__fire_dominant",           # Cinder boldExpression fire
        "venus_gemini__moon_aquarius__air_dominant",      # Zephyr versatileAdaptive air
        "venus_cancer__moon_scorpio__water_dominant",     # Cove quietLuxury water
    ]
    acc = accessory_comparison(golden_sample)

    report = {
        "cache": args.cache,
        "quality_scan": {
            "clusters_scanned": quality["clusters"],
            "sections_scanned": quality["sections"],
            "dash_violations": len(quality["issues"]["dash"]),
            "banned_tic_violations": len(quality["issues"]["tic"]),
            "season_word_violations": len(quality["issues"]["season"]),
            "formula_missing_style_core": len(quality["issues"]["formula_missing"]),
            "closing_not_ending_with_formula": len(quality["issues"]["closing_bad"]),
            "examples": {k: v[:5] for k, v in quality["issues"].items() if v},
        },
        "run_log": logs,
        "quarantine": {"clusters": len(quarantine), "keys": list(quarantine.keys())},
        "triage": {"clusters": len(triage), "keys": list(triage.keys())},
        "accessory_comparison": acc,
    }

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return

    q = report["quality_scan"]
    print(f"# SG-3 Validator Report\n")
    print(f"Cache: `{args.cache}`\n")
    print(f"## Quality re-scan (machine)\n")
    print(f"- Clusters scanned: **{q['clusters_scanned']}**")
    print(f"- Sections scanned: **{q['sections_scanned']}**")
    print(f"- Dash violations: **{q['dash_violations']}**")
    print(f"- Banned-tic violations: **{q['banned_tic_violations']}**")
    print(f"- Season-word violations (palette): **{q['season_word_violations']}**")
    print(f"- style_core missing coreFormula verbatim: **{q['formula_missing_style_core']}**")
    print(f"- Closing not ending with formula: **{q['closing_not_ending_with_formula']}**")
    if q["examples"]:
        print(f"- Examples: {json.dumps(q['examples'])}")
    print(f"\n## Run log\n- Outcomes: {logs.get('outcomes', {})}")
    print(f"- Warning types: {logs.get('warning_types', {})}")
    print(f"\n## Quarantine / Triage\n- Quarantined clusters: {report['quarantine']['clusters']}")
    print(f"- Triage-tagged clusters: {report['triage']['clusters']}")
    print(f"\n## accessoryCategoryPlan comparison\n")
    for a in acc:
        print(f"- **{a['cluster']}** ({a['register']}, key `{a['table_key']}`, merged={a['merged']})")
        print(f"  - include: {a['include']}")
        print(f"  - omit: {a['omit']}")


if __name__ == "__main__":
    main()
