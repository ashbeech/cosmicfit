#!/usr/bin/env python3
"""
Cosmic Fit — Banned-tic harvest (Style Guide Quality Overhaul, SG-0 Phase 0a).

Runs n-gram frequency analysis over the shipped 576-cluster narrative cache
(data/style_guide/blueprint_narrative_cache.json) to find the REAL recurring
verbal tics the current engine produces. The folklore list ("unbothered",
"signs the cheques", etc.) is retained as a floor; per the fifth-pass audit,
those phrases are not in the current prompts, so the enforced list must come
from evidence in the shipped cache.

Method:
  - For every cluster x section, lowercase the text and strip {placeholders}
    (each placeholder becomes a boundary; n-grams never span it, so resolved
    values cannot fabricate phantom phrases).
  - Count 2-, 3-, and 4-word n-grams. The headline metric is CLUSTER COVERAGE:
    the number of distinct clusters (of 576) whose guide contains the phrase
    at least once. A phrase in 200+ clusters is a tic by construction; total
    occurrence count is reported alongside.
  - N-grams composed entirely of function words ("of the", "as much as") are
    excluded from the report; content-bearing grams that merely contain
    function words are kept.
  - Per-section-type tables are also emitted (top phrases per section key),
    since some tics live in only one section type.
  - The folklore floor list is explicitly counted, whether or not it charts.

Output (committed alongside style_standard.md):
  docs/style_guide/tic_harvest.json  — full machine-readable report
  docs/style_guide/tic_harvest.md    — human-readable digest

Usage (from repo root):
  python3 tools/harvest_narrative_tics.py
  python3 tools/harvest_narrative_tics.py --cache data/style_guide/blueprint_narrative_cache.json --top 80
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CACHE = REPO_ROOT / "data" / "style_guide" / "blueprint_narrative_cache.json"
OUT_JSON = REPO_ROOT / "docs" / "style_guide" / "tic_harvest.json"
OUT_MD = REPO_ROOT / "docs" / "style_guide" / "tic_harvest.md"

# Folklore floor (master plan Phase 0a): counted regardless of frequency.
FOLKLORE_FLOOR = [
    "unbothered",
    "signs the cheques",
    "devastatingly chic",
    "command the room",
    "quiet expensive authority",
    "effortlessly elegant",
]

_PLACEHOLDER_RE = re.compile(r"\{[a-z_0-9]+\}")
_WORD_RE = re.compile(r"[a-z]+(?:'[a-z]+)?")

# Function words: n-grams made ONLY of these are structural, not tics.
FUNCTION_WORDS = frozenset("""
a an and are as at be but by for from has have if in into is it its not of on
or so than that the their them then there these they this to was were when
which will with you your yours yourself
""".split())


def extract_segments(text: str) -> list[list[str]]:
    """Split text at placeholders and sentence boundaries; return word lists.

    N-grams never span a placeholder or a sentence boundary, so we only count
    phrases the cache actually says in one breath.
    """
    segments: list[list[str]] = []
    for chunk in _PLACEHOLDER_RE.split(text.lower()):
        for sentence in re.split(r"[.!?;:]", chunk):
            words = _WORD_RE.findall(sentence)
            if len(words) >= 2:
                segments.append(words)
    return segments


def ngrams_of(words: list[str], n: int):
    for i in range(len(words) - n + 1):
        yield " ".join(words[i:i + n])


def is_reportable(gram: str) -> bool:
    tokens = gram.split()
    return any(t not in FUNCTION_WORDS for t in tokens)


def main() -> int:
    parser = argparse.ArgumentParser(description="Harvest recurring n-gram tics from the narrative cache")
    parser.add_argument("--cache", default=str(DEFAULT_CACHE), help="Path to blueprint_narrative_cache.json")
    parser.add_argument("--top", type=int, default=60, help="Top-N phrases per n-gram size in the report")
    parser.add_argument("--top-per-section", type=int, default=15, help="Top-N phrases per section type")
    parser.add_argument("--min-clusters", type=int, default=30,
                        help="Minimum cluster coverage for a phrase to appear in the global tables")
    args = parser.parse_args()

    cache: dict[str, dict[str, str]] = json.loads(Path(args.cache).read_text(encoding="utf-8"))
    n_clusters = len(cache)

    # gram -> set of clusters containing it (per n); gram -> total occurrences
    sizes = (2, 3, 4)
    cluster_cov: dict[int, dict[str, set]] = {n: defaultdict(set) for n in sizes}
    occurrences: dict[int, Counter] = {n: Counter() for n in sizes}
    # section_key -> n -> gram -> cluster set
    section_cov: dict[str, dict[int, dict[str, set]]] = defaultdict(
        lambda: {n: defaultdict(set) for n in sizes}
    )

    folklore_hits: dict[str, dict] = {
        phrase: {"total_occurrences": 0, "clusters": set()} for phrase in FOLKLORE_FLOOR
    }

    for cluster_key, sections in cache.items():
        for section_key, text in sections.items():
            if not isinstance(text, str):
                continue
            lower = text.lower()
            for phrase in FOLKLORE_FLOOR:
                cnt = lower.count(phrase)
                if cnt:
                    folklore_hits[phrase]["total_occurrences"] += cnt
                    folklore_hits[phrase]["clusters"].add(cluster_key)
            for words in extract_segments(text):
                for n in sizes:
                    for gram in ngrams_of(words, n):
                        cluster_cov[n][gram].add(cluster_key)
                        occurrences[n][gram] += 1
                        section_cov[section_key][n][gram].add(cluster_key)

    def table_for(cov: dict[str, set], occ: Counter | None, min_clusters: int, top: int) -> list[dict]:
        rows = [
            {
                "phrase": gram,
                "clusters": len(cl),
                "cluster_pct": round(100.0 * len(cl) / n_clusters, 1),
                "occurrences": occ[gram] if occ is not None else None,
            }
            for gram, cl in cov.items()
            if len(cl) >= min_clusters and is_reportable(gram)
        ]
        rows.sort(key=lambda r: (-r["clusters"], -(r["occurrences"] or 0), r["phrase"]))
        return rows[:top]

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "cache_file": str(Path(args.cache)),
        "clusters_analysed": n_clusters,
        "method": "2/3/4-word n-grams within sentence bounds, placeholders excluded; "
                  "ranked by distinct-cluster coverage; all-function-word grams excluded",
        "folklore_floor": {
            phrase: {
                "total_occurrences": data["total_occurrences"],
                "clusters": len(data["clusters"]),
            }
            for phrase, data in folklore_hits.items()
        },
        "global_top": {
            str(n): table_for(cluster_cov[n], occurrences[n], args.min_clusters, args.top)
            for n in sizes
        },
        "per_section_top": {
            section_key: {
                str(n): table_for(section_cov[section_key][n], None, max(10, args.min_clusters // 3),
                                  args.top_per_section)
                for n in sizes
            }
            for section_key in sorted(section_cov)
        },
    }

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Markdown digest
    lines = [
        "# Narrative cache tic harvest",
        "",
        f"> Generated {report['generated_at']} by `tools/harvest_narrative_tics.py` over "
        f"`{Path(args.cache).name}` ({n_clusters} clusters x 16 sections).",
        "> Ranking metric: **cluster coverage** (distinct clusters containing the phrase).",
        "> Full data: `tic_harvest.json`.",
        "",
        "## Folklore floor check",
        "",
        "| Phrase | Occurrences | Clusters |",
        "|---|---|---|",
    ]
    for phrase, data in report["folklore_floor"].items():
        lines.append(f"| {phrase} | {data['total_occurrences']} | {data['clusters']} |")

    for n in sizes:
        lines += ["", f"## Top {n}-word phrases (>= {args.min_clusters} clusters)", "",
                  "| Phrase | Clusters | % of 576 | Occurrences |", "|---|---|---|---|"]
        for row in report["global_top"][str(n)]:
            lines.append(f"| {row['phrase']} | {row['clusters']} | {row['cluster_pct']} | {row['occurrences']} |")

    lines += ["", "## Per-section leaders (3-grams)", ""]
    for section_key in sorted(section_cov):
        rows = report["per_section_top"][section_key]["3"][:5]
        if not rows:
            continue
        lines.append(f"**{section_key}**: " + "; ".join(
            f"\"{r['phrase']}\" ({r['clusters']})" for r in rows))
        lines.append("")

    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Analysed {n_clusters} clusters.")
    print(f"Wrote {OUT_JSON.relative_to(REPO_ROOT)}")
    print(f"Wrote {OUT_MD.relative_to(REPO_ROOT)}")
    print("\nFolklore floor hits:")
    for phrase, data in report["folklore_floor"].items():
        print(f"  {phrase!r}: {data['total_occurrences']} occurrences in {data['clusters']} clusters")
    print("\nTop 12 3-gram tics by cluster coverage:")
    for row in report["global_top"]["3"][:12]:
        print(f"  {row['clusters']:>4} clusters ({row['cluster_pct']:>5}%)  {row['phrase']!r}  x{row['occurrences']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
