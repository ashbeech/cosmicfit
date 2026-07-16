#!/usr/bin/env python3
"""Analyze production audit harness output into a definitive readiness report.

Usage:
  python3 tools/production_audit_analyze.py [--in docs/fixtures/production_audit]

Output:
  <in>/summary.json   full machine-readable metrics (canvas/report source)
  <in>/summary.txt    human-readable digest
"""

from __future__ import annotations

import argparse
import json
import math
import re
import statistics as stats
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SLIDERS = ["vibrancy", "contrast", "metalTone",
           "masculineFeminine", "angularRounded", "structuredDraped"]
HARD_BLOCK_DAYS = 3
STUCK_RANGE = 0.08

ESSENCE_TO_ENERGY = {
    "drama": "drama", "classic": "classic", "romantic": "romantic",
    "utility": "utility", "playful": "playful", "edgy": "edge",
}

IMPERCEPTIBLE_DELTA = 0.02
MEANINGFUL_DELTA = 0.05

# --- Sky Forward v1.0.2 Phase 6c / plan G2 item 3: fail-closed cohort regression gate ---
# These are PINNED, pre-registered floors (governance G0): defensible absolute bars that any healthy
# engine clears, set well below the v1.0.1 committed baseline so they are floors, not tuned-to-pass
# bounds. The four gated metric families are exactly those named in the plan (mean coherence,
# narrative-cohesion pass rate, slider-variation coverage, tarot repeat-gap). Changing a constant
# here is an owner escalation, recorded in the plan revision log — never lower it just to pass.
GATE_MIN_COHERENCE_PASS_RATE = 0.85   # cohesion.avgOverallPassRate (v1.0.1 baseline: 1.0)
GATE_MIN_ENERGY_COSINE = 0.80         # cohesion.meanEnergyCosine — narrative↔vibe alignment (baseline ~0.91)
GATE_MIN_REPEAT_GAP = 3               # tarot.minRepeatGapObserved must exceed the HARD_BLOCK_DAYS window
GATE_MAX_STUCK_USER_FRACTION = 0.33   # per slider: fraction of users with range < STUCK_RANGE
# Relative regression tolerance vs the pinned baseline summary (when --baseline is supplied): a gated
# metric may not drop by more than this fraction of its baseline value.
GATE_REGRESSION_TOLERANCE = 0.15
# Wider tolerance for top-essence↔energy match only — owner-ratified (2026-07-16, plan rev 8) because
# this tag-overlap metric is confounded with (i.e. inversely tracks) essence variety, a release goal.
GATE_TOP_ESSENCE_REGRESSION_TOLERANCE = 0.25
DEFAULT_GATE_BASELINE = "docs/fixtures/production_audit_baseline_v1_0_1.json"


def run_gate(summary: dict, baseline: dict | None) -> list[str]:
    """Return a list of gate-failure messages (empty = PASS). Fail-closed: any entry ⇒ exit(1)."""
    failures: list[str] = []
    cohort = max(summary.get("cohortSize") or 0, 1)

    # (1) mean coherence
    coh = (summary.get("cohesion") or {}).get("avgOverallPassRate")
    if coh is None or coh < GATE_MIN_COHERENCE_PASS_RATE:
        failures.append(f"mean coherence avgOverallPassRate={coh} < floor {GATE_MIN_COHERENCE_PASS_RATE}")

    # (2) narrative-cohesion pass rate (narrative↔vibe energy alignment)
    cos = (summary.get("cohesion") or {}).get("meanEnergyCosine")
    if cos is None or cos < GATE_MIN_ENERGY_COSINE:
        failures.append(f"narrative-cohesion meanEnergyCosine={cos} < floor {GATE_MIN_ENERGY_COSINE}")

    # (3) tarot repeat-gap: no hard-block violations, and the closest repeat clears the block window
    tar = summary.get("tarot") or {}
    hbv = tar.get("totalHardBlockViolations")
    if hbv is None or hbv > 0:
        failures.append(f"tarot hard-block violations={hbv} (must be 0)")
    min_gap = tar.get("minRepeatGapObserved")
    if min_gap is not None and min_gap < GATE_MIN_REPEAT_GAP:
        failures.append(f"tarot minRepeatGapObserved={min_gap} < floor {GATE_MIN_REPEAT_GAP}")

    # (4) slider-variation coverage: no slider stuck for more than the allowed fraction of users
    stuck = (summary.get("sliders") or {}).get("stuckUserCounts") or {}
    for s in SLIDERS:
        frac = (stuck.get(s, 0) or 0) / cohort
        if frac > GATE_MAX_STUCK_USER_FRACTION:
            failures.append(
                f"slider '{s}' stuck for {frac:.0%} of users > {GATE_MAX_STUCK_USER_FRACTION:.0%} cap")

    # Optional: regression vs the pinned baseline (owner-priority: variation must not silently drop)
    if baseline:
        def rel_regress(label, path, tol=GATE_REGRESSION_TOLERANCE):
            cur = _dig(summary, path)
            base = _dig(baseline, path)
            if cur is None or base is None or base <= 0:
                return
            if cur < base * (1 - tol):
                failures.append(
                    f"{label} regressed vs baseline: {cur:.4f} < {base:.4f}×{1 - tol:.2f}")
        rel_regress("mean coherence", "cohesion.avgOverallPassRate")
        rel_regress("narrative-cohesion", "cohesion.meanEnergyCosine")
        # top-essence↔energy match uses a WIDER tolerance (owner-ratified 2026-07-16, plan rev 8):
        # this tag-overlap metric is confounded with essence variety — v1.0.2's +65% essence-variety
        # gain (avgUniqueTop1 5.7→9.4, a release goal + the 24h-variation non-negotiable) mechanically
        # lowers the odds the varied headline essence tag-matches any given tarot card. Manually reviewed
        # regression days read fine/better (v1.0.1's higher score came from a monotonous "romantic"
        # default). Gated only against a genuine collapse, not the variety tradeoff.
        rel_regress("top-essence match", "cohesion.avgTopEssenceEnergyMatchRate",
                    tol=GATE_TOP_ESSENCE_REGRESSION_TOLERANCE)
        # slider-variation coverage regression: mean display range across sliders
        cur_ranges = (summary.get("sliders") or {}).get("avgDisplayRange") or {}
        base_ranges = (baseline.get("sliders") or {}).get("avgDisplayRange") or {}
        if cur_ranges and base_ranges:
            cur_mean = sum(cur_ranges.get(s, 0) for s in SLIDERS) / len(SLIDERS)
            base_mean = sum(base_ranges.get(s, 0) for s in SLIDERS) / len(SLIDERS)
            if base_mean > 0 and cur_mean < base_mean * (1 - GATE_REGRESSION_TOLERANCE):
                failures.append(
                    f"slider-variation coverage regressed: mean range {cur_mean:.4f} < "
                    f"{base_mean:.4f}×{1 - GATE_REGRESSION_TOLERANCE:.2f} "
                    f"(owner-priority: raise jitterRange / widen transit top-K)")
    return failures


def _dig(d: dict, dotted: str):
    v = d
    for p in dotted.split("."):
        v = v.get(p) if isinstance(v, dict) else None
        if v is None:
            return None
    return v

STOPWORDS = set("the a an and or of to in on for with your you it is are be at as that this".split())


def tokens(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z]+", (text or "").lower())
            if len(w) > 3 and w not in STOPWORDS}


def cosine(a: dict, b: dict) -> float | None:
    keys = sorted(set(a) & set(b))
    if not keys:
        return None
    va = [float(a[k] or 0) for k in keys]
    vb = [float(b[k] or 0) for k in keys]
    na = math.sqrt(sum(x * x for x in va))
    nb = math.sqrt(sum(x * x for x in vb))
    if na == 0 or nb == 0:
        return None
    return sum(x * y for x, y in zip(va, vb)) / (na * nb)


def safe_mean(xs):
    xs = [x for x in xs if x is not None]
    return round(stats.mean(xs), 4) if xs else None


def windowed_unique(seq, window):
    if len(seq) < window:
        return None
    return stats.mean(len(set(seq[i:i + window])) for i in range(0, len(seq) - window + 1, window))


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


def slider_variation_for_user(records: list[dict]) -> dict[str, dict]:
    """Compute day-over-day slider variation metrics per slider."""
    out: dict[str, dict] = {}
    for s in SLIDERS:
        vals = [r["displayPositions"].get(s) for r in records]
        vals = [float(v) for v in vals if v is not None]
        if len(vals) < 2:
            out[s] = {"skipped": True, "nDays": len(vals)}
            continue
        deltas = [abs(vals[i] - vals[i - 1]) for i in range(1, len(vals))]
        unchanged = sum(1 for d in deltas if d < 1e-9)
        imperceptible = sum(1 for d in deltas if d < IMPERCEPTIBLE_DELTA)
        meaningful = sum(1 for d in deltas if d >= MEANINGFUL_DELTA)
        n_pairs = len(deltas)
        out[s] = {
            "nDays": len(vals),
            "meanDayDelta": round(stats.fmean(deltas), 6),
            "medianDayDelta": round(stats.median(deltas), 6),
            "pctUnchangedDayPairs": round(unchanged / n_pairs * 100, 1),
            "pctImperceptibleDayPairs": round(imperceptible / n_pairs * 100, 1),
            "pctMeaningfulDayPairs": round(meaningful / n_pairs * 100, 1),
            "maxUnchangedStreak": max_unchanged_streak(vals),
            "distinctPositions": len(set(round(v, 6) for v in vals)),
        }
    return out


def analyze_user(records: list[dict]) -> dict:
    records = sorted(records, key=lambda r: r["date"])
    n = len(records)

    # --- Tarot rotation ---
    cards = [r["tarot"]["name"] for r in records]
    adjacent_repeats = sum(1 for i in range(1, n) if cards[i] == cards[i - 1])
    last_seen: dict[str, int] = {}
    gaps = []
    hard_block_violations = 0
    for i, c in enumerate(cards):
        if c in last_seen:
            gap = i - last_seen[c]
            gaps.append(gap)
            if gap <= HARD_BLOCK_DAYS:
                hard_block_violations += 1
        last_seen[c] = i

    # --- Repeated card narrative templates ---
    by_card: dict[str, list[dict]] = defaultdict(list)
    for r in records:
        by_card[r["tarot"]["name"]].append(r["styleEdit"])
    repeated_card_occurrences = 0
    exact_title_ritual_repeats = 0
    title_repeat_only = 0
    for c, edits in by_card.items():
        if len(edits) < 2:
            continue
        for i in range(1, len(edits)):
            repeated_card_occurrences += 1
            prev = edits[i - 1]
            cur = edits[i]
            if cur["title"] == prev["title"] and cur["dailyRitual"] == prev["dailyRitual"]:
                exact_title_ritual_repeats += 1
            elif cur["title"] == prev["title"]:
                title_repeat_only += 1

    # --- Essences ---
    top3_sets = [frozenset(e["category"] for e in r["essences"]["visible"]) for r in records]
    top1 = [r["essences"]["rankedAll"][0]["category"] if r["essences"]["rankedAll"] else None
            for r in records]
    longest_top3_streak = 1
    cur_streak = 1
    for i in range(1, n):
        if top3_sets[i] == top3_sets[i - 1]:
            cur_streak += 1
            longest_top3_streak = max(longest_top3_streak, cur_streak)
        else:
            cur_streak = 1

    # --- Sliders ---
    slider_ranges = {}
    stuck = []
    for s in SLIDERS:
        vals = [r["displayPositions"].get(s) for r in records]
        vals = [v for v in vals if v is not None]
        rng = (max(vals) - min(vals)) if vals else 0.0
        slider_ranges[s] = round(rng, 4)
        if rng < STUCK_RANGE:
            stuck.append(s)
    axis_ranges = {}
    for a in ("action", "strategy", "tempo", "visibility"):
        vals = [r["axes"].get(a) for r in records if r["axes"].get(a) is not None]
        axis_ranges[a] = round(max(vals) - min(vals), 3) if vals else 0.0

    # --- Palette ---
    day_palettes = [[c["name"] for c in r["palette"]] for r in records]
    unique_colours = len({c for p in day_palettes for c in p})
    retention = [len(set(day_palettes[i]) & set(day_palettes[i - 1])) for i in range(1, n)]
    lead = [p[0] if p else None for p in day_palettes]
    lead_adjacent_repeat = sum(1 for i in range(1, n) if lead[i] and lead[i] == lead[i - 1])
    patterns = [r["pattern"] for r in records]
    textures = [t for r in records for t in r["textures"]]

    # --- Cohesion ---
    overall_pass = [bool((r["diag"]["coherence"] or {}).get("overallPass")) for r in records]
    bridge_pass = [bool((r["diag"]["coherence"] or {}).get("bridgePass")) for r in records]
    sims = [(r["diag"]["bridge"] or {}).get("variantBridgeSimilarity") for r in records]
    relationships = Counter((r["diag"]["intent"] or {}).get("relationship") for r in records)
    variant_swaps = sum(1 for r in records if (r["diag"]["bridge"] or {}).get("variantRecencySwapped"))

    keyword_hits = 0
    energy_cosines = []
    top_essence_match = 0
    top_essence_eligible = 0
    for r in records:
        card_tokens = set()
        for k in r["tarot"]["keywords"] + r["tarot"]["themes"]:
            card_tokens |= tokens(k)
        edit_text = " ".join(filter(None, [
            r["styleEdit"]["title"], r["styleEdit"]["description"],
            r["styleEdit"]["dailyRitual"], r["styleEdit"]["wardrobeReflection"],
        ]))
        if card_tokens & tokens(edit_text):
            keyword_hits += 1
        c = cosine(r["vibeBreakdown"], r["styleEdit"]["energyEmphasis"])
        if c is not None:
            energy_cosines.append(c)
        t1 = r["essences"]["rankedAll"][0]["category"] if r["essences"]["rankedAll"] else None
        mapped = ESSENCE_TO_ENERGY.get(t1)
        if mapped:
            top_essence_eligible += 1
            ee = r["styleEdit"]["energyEmphasis"] or {}
            top2 = sorted(ee, key=lambda k: -ee[k])[:2]
            if mapped in top2:
                top_essence_match += 1

    # --- Completeness / gaps ---
    gap_days = 0
    gap_fields = Counter()
    for r in records:
        missing = []
        if not r["tarot"]["name"]:
            missing.append("tarotCard")
        for f in ("title", "description", "dailyRitual", "wardrobeReflection"):
            if not (r["styleEdit"].get(f) or "").strip():
                missing.append(f"styleEdit.{f}")
        if len(r["palette"]) != 3 or len({c["name"] for c in r["palette"]}) != 3:
            missing.append("palette3unique")
        # NOTE: dailyPattern is optional by design (visibility/energy gate); tracked
        # separately as patternPresenceRate, not as a gap.
        if not r["textures"]:
            missing.append("textures")
        if len(r["essences"]["visible"]) < 3:
            missing.append("essencesTop3")
        if any(r["displayPositions"].get(s) is None for s in SLIDERS):
            missing.append("sliderPositions")
        if missing:
            gap_days += 1
            gap_fields.update(missing)

    # --- Verdicts ---
    verdict_fails = Counter()
    verdict_total = Counter()
    for r in records:
        for vid, status in (r["verdicts"] or {}).items():
            verdict_total[vid] += 1
            if status != "pass":
                verdict_fails[vid] += 1

    return {
        "days": n,
        "tarot": {
            "uniqueCards": len(set(cards)),
            "uniquePer14d": round(windowed_unique(cards, 14) or 0, 2),
            "adjacentRepeats": adjacent_repeats,
            "hardBlockViolations": hard_block_violations,
            "minRepeatGap": min(gaps) if gaps else None,
            "repeatGaps": gaps,
            "cardCounts": dict(Counter(cards)),
        },
        "repeatNarrative": {
            "repeatedCardOccurrences": repeated_card_occurrences,
            "exactTitleRitualRepeats": exact_title_ritual_repeats,
            "titleRepeatOnly": title_repeat_only,
            "uniqueTitles": len({r["styleEdit"]["title"] for r in records}),
            "uniqueRituals": len({r["styleEdit"]["dailyRitual"] for r in records}),
        },
        "essences": {
            "uniqueTop3Sets": len(set(top3_sets)),
            "uniqueTop3Per14d": round(windowed_unique(top3_sets, 14) or 0, 2),
            "uniqueTop1": len(set(t for t in top1 if t)),
            "longestTop3Streak": longest_top3_streak,
            "top1Counts": dict(Counter(t for t in top1 if t)),
        },
        "sliders": {"ranges": slider_ranges, "stuck": stuck, "axisRanges": axis_ranges},
        "sliderVariation": slider_variation_for_user(records),
        "palette": {
            "uniqueColours": unique_colours,
            "meanNextDayRetention": safe_mean(retention),
            "leadAdjacentRepeats": lead_adjacent_repeat,
            "uniquePatterns": len(set(patterns)),
            "uniqueTextures": len(set(textures)),
        },
        "cohesion": {
            "overallPassRate": round(sum(overall_pass) / n, 4),
            "bridgePassRate": round(sum(bridge_pass) / n, 4),
            "meanBridgeSimilarity": safe_mean(sims),
            "minBridgeSimilarity": round(min([s for s in sims if s is not None]), 4) if any(s is not None for s in sims) else None,
            "relationships": dict(relationships),
            "variantRecencySwaps": variant_swaps,
            "keywordHitRate": round(keyword_hits / n, 4),
            "meanEnergyCosine": safe_mean(energy_cosines),
            "topEssenceEnergyMatchRate": round(top_essence_match / top_essence_eligible, 4) if top_essence_eligible else None,
        },
        "gaps": {"daysWithGaps": gap_days, "fields": dict(gap_fields)},
        "patternPresenceRate": round(sum(1 for p in patterns if p) / n, 4),
        "verdicts": {
            "fails": dict(verdict_fails),
            "totalChecks": sum(verdict_total.values()),
        },
    }


def analyze_blueprints(bp_dir: Path) -> dict:
    sections = {}
    families = Counter()
    sentence_owners: dict[str, set[str]] = defaultdict(set)
    per_user = {}
    users = 0
    for f in sorted(bp_dir.glob("*.json")):
        bp = json.loads(f.read_text())
        users += 1
        texts = {
            "styleCore": (bp.get("styleCore") or {}).get("narrativeText"),
            "palette": (bp.get("palette") or {}).get("narrativeText"),
            "pattern": (bp.get("pattern") or {}).get("narrativeText"),
            "texturesGood": (bp.get("textures") or {}).get("goodText"),
            "texturesBad": (bp.get("textures") or {}).get("badText"),
            "texturesSweetSpot": (bp.get("textures") or {}).get("sweetSpotText"),
            "hardwareMetals": (bp.get("hardware") or {}).get("metalsText"),
            "hardwareStones": (bp.get("hardware") or {}).get("stonesText"),
            "occasionsDaily": (bp.get("occasions") or {}).get("dailyText"),
            "occasionsWork": (bp.get("occasions") or {}).get("workText"),
            "occasionsIntimate": (bp.get("occasions") or {}).get("intimateText"),
            "accessory": " ".join((bp.get("accessory") or {}).get("paragraphs") or []),
        }
        missing = [k for k, v in texts.items() if not (v or "").strip()]
        code = bp.get("code") or {}
        if not code.get("leanInto") or not code.get("avoid"):
            missing.append("code")
        wc = {k: len((v or "").split()) for k, v in texts.items()}
        per_user[f.stem] = {"missingSections": missing, "wordCounts": wc}
        for k, v in texts.items():
            sections.setdefault(k, []).append(len((v or "").split()))
        fam = (bp.get("palette") or {}).get("family")
        if fam:
            families[fam] += 1
        for v in texts.values():
            for s in re.split(r"(?<=[.!?])\s+", v or ""):
                s = s.strip()
                if len(s) > 40:
                    sentence_owners[s].add(f.stem)

    shared = [s for s, owners in sentence_owners.items() if len(owners) > max(2, users * 0.2)]
    total_sentences = len(sentence_owners)
    return {
        "users": users,
        "sectionWordCounts": {k: {"mean": safe_mean(v), "min": min(v), "max": max(v)}
                              for k, v in sections.items()},
        "usersWithMissingSections": {u: d["missingSections"] for u, d in per_user.items()
                                     if d["missingSections"]},
        "paletteFamilies": dict(families),
        "uniqueSentences": total_sentences,
        "sentencesSharedBy20pct": len(shared),
        "sharedSentenceExamples": shared[:8],
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="indir", type=str, default="docs/fixtures/production_audit")
    ap.add_argument("--gate", action="store_true",
                    help="Fail-closed regression gate: sys.exit(1) if any pinned cohort metric "
                         "(mean coherence, narrative-cohesion, slider coverage, tarot repeat-gap) "
                         "falls below its floor or regresses beyond tolerance vs --baseline.")
    ap.add_argument("--baseline", type=str, default=DEFAULT_GATE_BASELINE,
                    help="Pinned baseline summary.json to diff against in --gate mode "
                         "(absolute floors still apply if the baseline is absent).")
    args = ap.parse_args()
    base = ROOT / args.indir

    per_user = {}
    all_slider_deltas: dict[str, list[float]] = {s: [] for s in SLIDERS}
    for f in sorted((base / "raw").glob("*.jsonl")):
        records = [json.loads(line) for line in f.read_text().splitlines() if line.strip()]
        if not records:
            continue
        per_user[f.stem] = analyze_user(records)
        sorted_recs = sorted(records, key=lambda r: r["date"])
        for s in SLIDERS:
            vals = [float(r["displayPositions"][s]) for r in sorted_recs
                    if r["displayPositions"].get(s) is not None]
            for i in range(1, len(vals)):
                all_slider_deltas[s].append(abs(vals[i] - vals[i - 1]))

    users = list(per_user.values())
    n_users = len(users)

    def agg(path, fn=safe_mean):
        vals = []
        for u in users:
            v = u
            for p in path.split("."):
                v = v.get(p) if isinstance(v, dict) else None
                if v is None:
                    break
            vals.append(v)
        return fn([v for v in vals if v is not None])

    all_gaps = [g for u in users for g in u["tarot"]["repeatGaps"]]
    gap_hist = Counter(all_gaps)
    relationship_totals = Counter()
    for u in users:
        relationship_totals.update(u["cohesion"]["relationships"])
    verdict_fail_totals = Counter()
    for u in users:
        verdict_fail_totals.update(u["verdicts"]["fails"])
    slider_avg = {s: safe_mean([u["sliders"]["ranges"][s] for u in users]) for s in SLIDERS}
    stuck_users = {s: sum(1 for u in users if s in u["sliders"]["stuck"]) for s in SLIDERS}
    card_totals = Counter()
    for u in users:
        card_totals.update(u["tarot"]["cardCounts"])

    # --- Slider day-variation aggregate ---
    sv_agg: dict[str, dict] = {}
    sv_histograms: dict[str, dict] = {}
    hist_edges = [0, 0.001, 0.02, 0.05, 0.10, 0.20, 0.50, 1.01]
    hist_labels = ["0 (unchanged)", "<0.02", "0.02-0.05", "0.05-0.10",
                   "0.10-0.20", "0.20-0.50", ">0.50"]
    for s in SLIDERS:
        rows = [u["sliderVariation"][s] for u in users
                if not u["sliderVariation"].get(s, {}).get("skipped")]
        if not rows:
            continue
        n_sv = len(rows)
        sv_agg[s] = {
            "nUsers": n_sv,
            "meanDayDelta": round(stats.fmean(r["meanDayDelta"] for r in rows), 4),
            "medianDayDelta": round(stats.median(r["medianDayDelta"] for r in rows), 4),
            "meanDistinctPositions": round(stats.fmean(r["distinctPositions"] for r in rows), 1),
            "meanMaxUnchangedStreak": round(stats.fmean(r["maxUnchangedStreak"] for r in rows), 1),
            "meanPctUnchangedDayPairs": round(stats.fmean(r["pctUnchangedDayPairs"] for r in rows), 1),
            "meanPctMeaningfulDayPairs": round(stats.fmean(r["pctMeaningfulDayPairs"] for r in rows), 1),
            "pctUsersMostlyUnchanged": round(
                sum(1 for r in rows if r["pctUnchangedDayPairs"] >= 50) / n_sv * 100, 1),
            "pctUsersRarelyMeaningful": round(
                sum(1 for r in rows if r["pctMeaningfulDayPairs"] < 10) / n_sv * 100, 1),
            "pctUsersLowRange": round(
                sum(1 for u in users if u["sliders"]["ranges"].get(s, 0) < 0.33) / n_sv * 100, 1),
        }
        deltas = all_slider_deltas[s]
        counts = [0] * len(hist_labels)
        for d in deltas:
            for i in range(len(hist_edges) - 1):
                if hist_edges[i] <= d < hist_edges[i + 1]:
                    counts[i] += 1
                    break
        n_deltas = len(deltas) or 1
        sv_histograms[s] = {
            "labels": hist_labels,
            "counts": counts,
            "pct": [round(c / n_deltas * 100, 1) for c in counts],
            "nDayPairs": len(deltas),
        }

    summary = {
        "cohortSize": n_users,
        "daysPerUser": users[0]["days"] if users else 0,
        "totalUserDays": sum(u["days"] for u in users),
        "tarot": {
            "totalAdjacentRepeats": sum(u["tarot"]["adjacentRepeats"] for u in users),
            "totalHardBlockViolations": sum(u["tarot"]["hardBlockViolations"] for u in users),
            "minRepeatGapObserved": min((u["tarot"]["minRepeatGap"] for u in users
                                         if u["tarot"]["minRepeatGap"] is not None), default=None),
            "avgUniqueCards45d": agg("tarot.uniqueCards"),
            "avgUniqueCardsPer14d": agg("tarot.uniquePer14d"),
            "repeatGapHistogram": {str(k): v for k, v in sorted(gap_hist.items())},
            "cardFrequencyTop10": card_totals.most_common(10),
            "distinctCardsUsedCohort": len(card_totals),
        },
        "repeatNarrative": {
            "totalRepeatedCardOccurrences": sum(u["repeatNarrative"]["repeatedCardOccurrences"] for u in users),
            "totalExactTitleRitualRepeats": sum(u["repeatNarrative"]["exactTitleRitualRepeats"] for u in users),
            "totalTitleRepeatOnly": sum(u["repeatNarrative"]["titleRepeatOnly"] for u in users),
            "avgUniqueTitles": agg("repeatNarrative.uniqueTitles"),
            "avgUniqueRituals": agg("repeatNarrative.uniqueRituals"),
        },
        "essences": {
            "avgUniqueTop3Sets45d": agg("essences.uniqueTop3Sets"),
            "avgUniqueTop3SetsPer14d": agg("essences.uniqueTop3Per14d"),
            "avgUniqueTop1": agg("essences.uniqueTop1"),
            "maxTop3Streak": max(u["essences"]["longestTop3Streak"] for u in users),
            "usersWithStreakOver7": sum(1 for u in users if u["essences"]["longestTop3Streak"] > 7),
        },
        "sliders": {
            "avgDisplayRange": slider_avg,
            "stuckUserCounts": stuck_users,
            "avgAxisRanges": {a: safe_mean([u["sliders"]["axisRanges"][a] for u in users])
                              for a in ("action", "strategy", "tempo", "visibility")},
        },
        "palette": {
            "avgUniqueColours45d": agg("palette.uniqueColours"),
            "avgNextDayRetention": agg("palette.meanNextDayRetention"),
            "totalLeadAdjacentRepeats": sum(u["palette"]["leadAdjacentRepeats"] for u in users),
            "avgUniquePatterns": agg("palette.uniquePatterns"),
            "avgUniqueTextures": agg("palette.uniqueTextures"),
        },
        "cohesion": {
            "avgOverallPassRate": agg("cohesion.overallPassRate"),
            "avgBridgePassRate": agg("cohesion.bridgePassRate"),
            "meanBridgeSimilarity": agg("cohesion.meanBridgeSimilarity"),
            "worstBridgeSimilarity": min((u["cohesion"]["minBridgeSimilarity"] for u in users
                                          if u["cohesion"]["minBridgeSimilarity"] is not None), default=None),
            "relationshipDistribution": dict(relationship_totals),
            "totalVariantRecencySwaps": sum(u["cohesion"]["variantRecencySwaps"] for u in users),
            "avgKeywordHitRate": agg("cohesion.keywordHitRate"),
            "meanEnergyCosine": agg("cohesion.meanEnergyCosine"),
            "avgTopEssenceEnergyMatchRate": agg("cohesion.topEssenceEnergyMatchRate"),
        },
        "gaps": {
            "totalDaysWithGaps": sum(u["gaps"]["daysWithGaps"] for u in users),
            "fieldTotals": dict(sum((Counter(u["gaps"]["fields"]) for u in users), Counter())),
        },
        "patternPresenceRate": agg("patternPresenceRate"),
        "verdicts": {
            "totalChecks": sum(u["verdicts"]["totalChecks"] for u in users),
            "failTotals": dict(verdict_fail_totals),
        },
        "sliderVariation": {
            "aggregate": sv_agg,
            "deltaHistograms": sv_histograms,
        },
        "perUser": per_user,
    }

    bp_dir = base / "blueprints"
    if bp_dir.exists():
        summary["blueprints"] = analyze_blueprints(bp_dir)

    (base / "summary.json").write_text(json.dumps(summary, indent=1, sort_keys=True))

    # Human digest
    lines = [
        f"Production audit: {n_users} users x {summary['daysPerUser']} days "
        f"({summary['totalUserDays']} user-days)",
        "",
        f"TAROT  adjacent repeats: {summary['tarot']['totalAdjacentRepeats']} | "
        f"hard-block violations: {summary['tarot']['totalHardBlockViolations']} | "
        f"min gap: {summary['tarot']['minRepeatGapObserved']} | "
        f"avg unique/14d: {summary['tarot']['avgUniqueCardsPer14d']}",
        f"REPEAT NARRATIVE  exact title+ritual repeats: "
        f"{summary['repeatNarrative']['totalExactTitleRitualRepeats']} / "
        f"{summary['repeatNarrative']['totalRepeatedCardOccurrences']} repeated-card occurrences",
        f"ESSENCES  avg unique top-3/14d: {summary['essences']['avgUniqueTop3SetsPer14d']} | "
        f"max streak: {summary['essences']['maxTop3Streak']}",
        f"SLIDERS  avg display range: " + " ".join(
            f"{s}={summary['sliders']['avgDisplayRange'][s]}" for s in SLIDERS),
        f"SLIDERS  stuck user counts: {summary['sliders']['stuckUserCounts']}",
        f"PALETTE  avg unique colours: {summary['palette']['avgUniqueColours45d']} | "
        f"next-day retention: {summary['palette']['avgNextDayRetention']}",
        f"COHESION  overall pass: {summary['cohesion']['avgOverallPassRate']} | "
        f"keyword hit: {summary['cohesion']['avgKeywordHitRate']} | "
        f"energy cosine: {summary['cohesion']['meanEnergyCosine']}",
        f"GAPS  days with missing fields: {summary['gaps']['totalDaysWithGaps']}",
        f"VERDICTS  fails: {summary['verdicts']['failTotals'] or 'none'} "
        f"of {summary['verdicts']['totalChecks']} checks",
    ]
    if sv_agg:
        lines += [
            "",
            "SLIDER VARIATION (day-over-day)",
            f"  {'slider':<20}{'meanΔ':>8}{'medΔ':>8}{'%unch':>8}{'%≥0.05':>8}"
            f"{'maxStrk':>8}{'distPos':>8}{'%stuck':>8}",
        ]
        for s in SLIDERS:
            a = sv_agg.get(s)
            if not a:
                continue
            lines.append(
                f"  {s:<20}{a['meanDayDelta']:>8.4f}{a['medianDayDelta']:>8.4f}"
                f"{a['meanPctUnchangedDayPairs']:>8.1f}{a['meanPctMeaningfulDayPairs']:>8.1f}"
                f"{a['meanMaxUnchangedStreak']:>8.1f}{a['meanDistinctPositions']:>8.1f}"
                f"{a['pctUsersLowRange']:>8.1f}"
            )
    if "blueprints" in summary:
        b = summary["blueprints"]
        lines += [
            f"BLUEPRINTS  {b['users']} users | missing sections: "
            f"{len(b['usersWithMissingSections'])} users | "
            f"sentences shared by >20% of users: {b['sentencesSharedBy20pct']} "
            f"of {b['uniqueSentences']}",
        ]
    (base / "summary.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))

    # --- Fail-closed regression gate (plan G2 item 3) ---
    if args.gate:
        baseline = None
        baseline_path = ROOT / args.baseline
        if baseline_path.exists():
            baseline = json.loads(baseline_path.read_text())
            print(f"\nGATE: diffing against pinned baseline {args.baseline}")
        else:
            print(f"\nGATE: baseline {args.baseline} absent — enforcing absolute floors only")
        failures = run_gate(summary, baseline)
        print("\n" + "=" * 60)
        if failures:
            print(f"GATE FAILED ({len(failures)} regression(s)):")
            for f in failures:
                print(f"  ✘ {f}")
            print("A red gate is a signal to keep developing (plan §7 nudge order), not to ship.")
            raise SystemExit(1)
        print("GATE PASSED — all pinned cohort metrics within floors/tolerance.")


if __name__ == "__main__":
    main()
