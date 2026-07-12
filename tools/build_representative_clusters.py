#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 representative-cluster selection (Phase 3f).

Rebuilds the 192-cluster representative selection as a REVIEWABLE ARTIFACT
(tools/representative_clusters.json), replacing the old
generate_representative_clusters() side-effect function.

The old grid used only 4 Moon representatives (12 Venus x 4 Moon x 4 element),
so golden clusters on the other 8 Moon signs (e.g. Cove's
venus_cancer__moon_scorpio__water_dominant) fell OUTSIDE the selection. This
rebuild force-includes every golden cluster and asserts coverage.

Guarantees (asserted before write):
  - exactly 192 unique cluster keys
  - 16 keys per Venus sign (even quota)
  - all 12 Venus signs present
  - all 12 Moon signs present
  - all 4 dominant elements present
  - all 16 golden cluster keys present
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GOLDEN_EXPECTATIONS = REPO_ROOT / "docs" / "style_guide" / "golden" / "profile_expectations.json"
OUTPUT = REPO_ROOT / "tools" / "representative_clusters.json"

ZODIAC = [
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
]
ELEMENTS = ["fire", "earth", "air", "water"]
PER_VENUS = 16  # 12 * 16 = 192


def key_of(venus: str, moon: str, element: str) -> str:
    return f"venus_{venus}__moon_{moon}__{element}_dominant"


def golden_keys() -> list[str]:
    with open(GOLDEN_EXPECTATIONS) as f:
        vectors = json.load(f)
    return [v["cluster_key"] for k, v in vectors.items() if k != "_meta"]


def parse(key: str) -> tuple[str, str, str]:
    parts = key.split("__")
    return (parts[0][len("venus_"):], parts[1][len("moon_"):],
            parts[2][: -len("_dominant")])


def build() -> list[str]:
    golden = golden_keys()
    golden_by_venus: dict[str, list[tuple[str, str]]] = {v: [] for v in ZODIAC}
    for gk in golden:
        gv, gm, ge = parse(gk)
        golden_by_venus[gv].append((gm, ge))

    selection: list[str] = []
    for vi, venus in enumerate(ZODIAC):
        combos: list[tuple[str, str]] = []
        # 12 combos: one per Moon sign, element rotated by (venus,moon) so all
        # four elements spread and warm-Venus/water "conflicting temperature"
        # cases occur naturally.
        for mi, moon in enumerate(ZODIAC):
            combos.append((moon, ELEMENTS[(vi + mi) % 4]))
        # 4 "variety" combos: first four Moon signs at a different element.
        for mi in range(4):
            combos.append((ZODIAC[mi], ELEMENTS[(vi + mi + 1) % 4]))

        # Force-include this Venus sign's golden combos. If a golden combo is
        # not already present, overwrite a variety slot (indices 12..15) so the
        # 12-Moon coverage block is preserved and the per-Venus count stays 16.
        variety_ptr = 12
        for gcombo in golden_by_venus[venus]:
            if gcombo in combos:
                continue
            if variety_ptr < len(combos):
                combos[variety_ptr] = gcombo
                variety_ptr += 1
            else:
                # More golden than variety slots for this Venus (never happens:
                # max 2 golden per Venus, 4 variety slots) — replace a duplicate.
                combos.append(gcombo)

        # De-duplicate within this Venus while preserving order, backfilling to
        # 16 from the unused (moon, element) space.
        seen: set[tuple[str, str]] = set()
        deduped: list[tuple[str, str]] = []
        for c in combos:
            if c not in seen:
                seen.add(c)
                deduped.append(c)
        mi = 0
        while len(deduped) < PER_VENUS:
            for moon in ZODIAC:
                for element in ELEMENTS:
                    cand = (moon, element)
                    if cand not in seen:
                        seen.add(cand)
                        deduped.append(cand)
                        break
                if len(deduped) >= PER_VENUS:
                    break
            mi += 1
            if mi > 4:
                break
        deduped = deduped[:PER_VENUS]
        for moon, element in deduped:
            selection.append(key_of(venus, moon, element))

    return sorted(set(selection))


def assert_coverage(keys: list[str]) -> None:
    assert len(keys) == 192, f"expected 192 keys, got {len(keys)}"
    assert len(set(keys)) == 192, "duplicate keys present"
    venus_seen, moon_seen, elem_seen = set(), set(), set()
    venus_counts: dict[str, int] = {}
    for k in keys:
        v, m, e = parse(k)
        venus_seen.add(v)
        moon_seen.add(m)
        elem_seen.add(e)
        venus_counts[v] = venus_counts.get(v, 0) + 1
    assert venus_seen == set(ZODIAC), f"missing Venus signs: {set(ZODIAC) - venus_seen}"
    assert moon_seen == set(ZODIAC), f"missing Moon signs: {set(ZODIAC) - moon_seen}"
    assert elem_seen == set(ELEMENTS), f"missing elements: {set(ELEMENTS) - elem_seen}"
    for v, c in venus_counts.items():
        assert c == PER_VENUS, f"Venus {v} has {c} keys, expected {PER_VENUS}"
    missing_golden = [g for g in golden_keys() if g not in set(keys)]
    assert not missing_golden, f"missing golden clusters: {missing_golden}"


def main() -> None:
    keys = build()
    assert_coverage(keys)
    payload = {
        "_meta": {
            "description": "SG-3 representative cluster selection (Phase 3f). 192 of "
                           "576 clusters. All 16 golden clusters force-included; even "
                           "16-per-Venus quota; all 12 Moon signs and 4 elements covered. "
                           "Generated by tools/build_representative_clusters.py.",
            "count": len(keys),
            "golden_included": golden_keys(),
        },
        "clusters": keys,
    }
    OUTPUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {OUTPUT} with {len(keys)} clusters.")
    print("Coverage assertions PASSED (192 unique, 16/Venus, 12 Moon, 4 element, 16 golden).")
    # Report Moon-sign distribution as evidence.
    moon_dist: dict[str, int] = {}
    for k in keys:
        _, m, _ = parse(k)
        moon_dist[m] = moon_dist.get(m, 0) + 1
    print("Moon distribution:", {m: moon_dist[m] for m in ZODIAC})


if __name__ == "__main__":
    try:
        main()
    except AssertionError as e:
        print(f"COVERAGE ASSERTION FAILED: {e}", file=sys.stderr)
        sys.exit(1)
