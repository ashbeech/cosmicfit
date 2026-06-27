#!/usr/bin/env python3
"""
Cosmic Fit — Content Audit Engine (CLI)

Walks every user-visible Style Guide string, runs quality checks, and writes:
  - audit_report.json    (full machine-readable findings)
  - audit_progress.json  (live progress for the web UI)
  - audit_report.md      (human-readable report)
  - audit_handoff_pack.json  (grouped actions for another AI developer)

Usage:
    python3 tools/content_audit.py [--format all|json|markdown|handoff] [--sources cache,dataset,blueprints,runtime]
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

# Ensure tools/ is importable
sys.path.insert(0, str(Path(__file__).resolve().parent))

from content_audit_inventory import (
    AuditableItem,
    walk_narrative_cache,
    walk_dataset,
    walk_composed_blueprints,
    walk_extracted_strings,
    walk_rendered_templates,
    SECTION_KEYS,
)
from content_audit_checks import run_checks, ALL_CHECKS
from doc_banner import generated_report_banner


# ─── Paths ─────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data" / "style_guide"
CACHE_PATH = DATA_DIR / "blueprint_narrative_cache.json"
DATASET_PATH = DATA_DIR / "astrological_style_dataset.json"
BLUEPRINTS_DIR = REPO_ROOT / "docs" / "fixtures" / "production_audit" / "blueprints"
EXTRACTED_PATH = DATA_DIR / "extracted_runtime_strings.json"
PLACEHOLDER_FIXTURE_PATH = DATA_DIR / "audit_placeholder_fixture.json"

OUTPUT_DIR = DATA_DIR
REPORT_PATH = OUTPUT_DIR / "audit_report.json"
PROGRESS_PATH = OUTPUT_DIR / "audit_progress.json"
MARKDOWN_PATH = OUTPUT_DIR / "audit_report.md"
HANDOFF_PATH = OUTPUT_DIR / "audit_handoff_pack.json"
PAUSE_PATH = OUTPUT_DIR / "audit_pause_signal.json"


def is_paused() -> bool:
    if not PAUSE_PATH.exists():
        return False
    try:
        data = json.loads(PAUSE_PATH.read_text())
        return data.get("paused", False)
    except Exception:
        return False


# ─── Aggregate checks ─────────────────────────────────────────────────

def check_cross_cluster_duplicates(items_by_cluster: dict[str, dict[str, str]]) -> list[dict]:
    """Find near-identical paragraphs across different clusters."""
    from difflib import SequenceMatcher
    import uuid as _uuid

    issues = []
    section_texts: dict[str, list[tuple[str, str]]] = defaultdict(list)

    for cluster_key, sections in items_by_cluster.items():
        for section_key, text in sections.items():
            if text and len(text.split()) >= 20:
                section_texts[section_key].append((cluster_key, text))

    for section_key, entries in section_texts.items():
        seen_hashes: dict[str, str] = {}
        for cluster_key, text in entries:
            norm = " ".join(text.lower().split())
            if norm in seen_hashes:
                issues.append({
                    "id": str(_uuid.uuid4()),
                    "content_id": f"cache:{cluster_key}.{section_key}",
                    "check_id": "cross_cluster_duplicate",
                    "priority": "medium",
                    "why": f"Identical to {seen_hashes[norm]}.{section_key}.",
                    "flagged_fragment": text[:80],
                    "suggested_fix": "",
                    "rewrite_brief": f"This paragraph is identical to the one in cluster '{seen_hashes[norm]}'. Write unique content for this archetype.",
                    "action_type": "rewrite",
                    "json_edit_path": f"{cluster_key}.{section_key}",
                    "auto_fixable": False,
                    "span": None,
                })
            else:
                seen_hashes[norm] = cluster_key
    return issues


def check_intra_cluster_repetition(items_by_cluster: dict[str, dict[str, str]]) -> list[dict]:
    """Flag distinctive words used excessively across sections within one cluster."""
    import uuid as _uuid

    stop_words = {"the", "a", "an", "is", "are", "was", "were", "and", "or", "but",
                  "of", "in", "to", "for", "with", "on", "at", "by", "from", "that",
                  "this", "it", "you", "your", "not", "as", "be", "has", "have", "had",
                  "do", "does", "its", "when", "than", "no", "so", "if", "up", "out",
                  "just", "like", "what", "which", "who", "how", "all", "about", "into",
                  "over", "more", "very", "too", "also", "only", "own", "them", "their",
                  "there", "here", "will", "can", "would", "should", "could", "may",
                  "been", "being", "each", "every", "any", "some", "one", "two", "three"}
    issues = []

    for cluster_key, sections in items_by_cluster.items():
        all_words: Counter = Counter()
        section_count = 0
        for text in sections.values():
            if not text:
                continue
            section_count += 1
            words = set(w.lower().strip(".,;:!?\"'()") for w in text.split()
                        if len(w.strip(".,;:!?\"'()")) > 4)
            words -= stop_words
            all_words.update(words)

        if section_count < 4:
            continue

        for word, count in all_words.most_common(5):
            if count >= 8:
                issues.append({
                    "id": str(_uuid.uuid4()),
                    "content_id": f"cache:{cluster_key}",
                    "check_id": "intra_cluster_repetition",
                    "priority": "high",
                    "why": f"Word '{word}' appears in {count} sections within this cluster.",
                    "flagged_fragment": word,
                    "suggested_fix": "",
                    "rewrite_brief": f"The word '{word}' is overused across this cluster's sections. Vary vocabulary.",
                    "action_type": "rewrite",
                    "json_edit_path": cluster_key,
                    "auto_fixable": False,
                    "span": None,
                })
    return issues


def check_composed_code_lists(items: list[AuditableItem]) -> list[dict]:
    """Check for inconsistency within a single user's Code list."""
    import uuid as _uuid

    grouped: dict[str, list[AuditableItem]] = defaultdict(list)
    for item in items:
        if item.source_layer == "composed" and "code." in item.json_edit_path:
            key = f"{item.cluster_key}:{item.json_edit_path.split('[')[0]}"
            grouped[key].append(item)

    issues = []
    for key, bullets in grouped.items():
        if len(bullets) < 2:
            continue
        word_counts = [len(b.text.split()) for b in bullets]
        has_long = any(wc >= 12 for wc in word_counts)
        has_short = any(wc <= 5 for wc in word_counts)
        if has_long and has_short:
            short_bullets = [b for b in bullets if len(b.text.split()) <= 5]
            for b in short_bullets:
                issues.append({
                    "id": str(_uuid.uuid4()),
                    "content_id": b.content_id,
                    "check_id": "composed_code_inconsistency",
                    "priority": "high",
                    "why": "This short bullet sits alongside full sentences in the same Code list, creating an inconsistent user experience.",
                    "flagged_fragment": b.text.strip(),
                    "suggested_fix": "",
                    "rewrite_brief": "Expand to match the sentence length and style of the other bullets in this list.",
                    "action_type": "rewrite",
                    "json_edit_path": b.json_edit_path,
                    "auto_fixable": False,
                    "span": None,
                })
    return issues


def check_corpus_overuse(all_items: list[AuditableItem]) -> list[dict]:
    """Flag words used in >30% of narrative cache clusters."""
    import uuid as _uuid

    cluster_words: dict[str, set[str]] = defaultdict(set)
    stop_words = {"the", "a", "an", "is", "are", "was", "were", "and", "or", "but",
                  "of", "in", "to", "for", "with", "on", "at", "by", "from", "that",
                  "this", "it", "you", "your", "not", "as", "be", "has", "have", "had",
                  "do", "does", "its", "when", "than", "no", "so", "if", "up", "out",
                  "just", "like", "what", "which", "who", "how", "all", "about", "into",
                  "over", "more", "very", "too", "also", "only", "own", "them", "their"}

    for item in all_items:
        if item.source_layer == "narrative_cache" and item.cluster_key:
            words = set(w.lower().strip(".,;:!?\"'()") for w in item.text.split()
                        if len(w.strip(".,;:!?\"'()")) > 5)
            words -= stop_words
            cluster_words[item.cluster_key] |= words

    total_clusters = len(cluster_words)
    if total_clusters < 10:
        return []

    word_cluster_counts: Counter = Counter()
    for words in cluster_words.values():
        word_cluster_counts.update(words)

    issues = []
    threshold = total_clusters * 0.3
    for word, count in word_cluster_counts.most_common(20):
        if count >= threshold:
            issues.append({
                "id": str(_uuid.uuid4()),
                "content_id": "corpus",
                "check_id": "corpus_overuse",
                "priority": "low",
                "why": f"'{word}' appears in {count}/{total_clusters} clusters ({count/total_clusters:.0%}).",
                "flagged_fragment": word,
                "suggested_fix": "",
                "rewrite_brief": f"The word '{word}' is overused across the corpus. Consider varying it in future regeneration passes.",
                "action_type": "review",
                "json_edit_path": "",
                "auto_fixable": False,
                "span": None,
            })
    return issues


# ─── Progress ──────────────────────────────────────────────────────────

def write_progress(total: int, completed: int, current_item: str, issues_found: int):
    data = {
        "total": total,
        "completed": completed,
        "current_item": current_item,
        "percent": round(completed / total * 100, 1) if total else 0,
        "issues_found": issues_found,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    PROGRESS_PATH.write_text(json.dumps(data, indent=2))


# ─── Report generation ─────────────────────────────────────────────────

def build_report(all_items: list[AuditableItem], all_issues: list[dict],
                 sources_audited: list[str], elapsed: float) -> dict:
    by_priority: Counter = Counter()
    by_check: Counter = Counter()
    for issue in all_issues:
        by_priority[issue["priority"]] += 1
        by_check[issue["check_id"]] += 1

    item_map: dict[str, dict] = {}
    for item in all_items:
        item_issues = [i for i in all_issues if i["content_id"] == item.content_id]
        highest = "none"
        priority_order = {"critical": 0, "high": 1, "medium": 2, "low": 3, "none": 4}
        for i in item_issues:
            if priority_order.get(i["priority"], 4) < priority_order.get(highest, 4):
                highest = i["priority"]
        item_map[item.content_id] = {
            "content_id": item.content_id,
            "source_layer": item.source_layer,
            "source_file": item.source_file,
            "json_edit_path": item.json_edit_path,
            "ui_section": item.ui_section,
            "expected_format": item.rule.expected_format,
            "original_content": item.text,
            "issue_count": len(item_issues),
            "highest_priority": highest,
        }

    flagged_count = sum(1 for v in item_map.values() if v["issue_count"] > 0)
    return {
        "meta": {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "engine_version": "1.0.0",
            "sources_audited": sources_audited,
            "total_items": len(all_items),
            "flagged_items": flagged_count,
            "clean_items": len(all_items) - flagged_count,
            "total_issues": len(all_issues),
            "by_priority": dict(by_priority),
            "by_check": dict(by_check.most_common()),
            "elapsed_seconds": round(elapsed, 1),
        },
        "items": list(item_map.values()),
        "issues": all_issues,
    }


def write_markdown(report: dict, path: Path):
    meta = report["meta"]
    lines = [
        "# Style Guide Content Audit Report",
        "",
        *generated_report_banner(
            script="tools/content_audit.py",
            command="python3 tools/content_audit.py --format all",
            generated=meta["timestamp"],
        ),
    ]
    lines.append(f"**Generated:** {meta['timestamp']}")
    lines.append(f"**Items audited:** {meta['total_items']}")
    lines.append(f"**Total issues:** {meta['total_issues']}")
    lines.append(f"**Elapsed:** {meta['elapsed_seconds']}s\n")

    for prio in ("critical", "high", "medium", "low"):
        count = meta["by_priority"].get(prio, 0)
        if count == 0:
            continue
        lines.append(f"\n## {prio.upper()} Issues ({count})\n")
        prio_issues = [i for i in report["issues"] if i["priority"] == prio]
        for idx, issue in enumerate(prio_issues, 1):
            lines.append(f"### {idx}. [{issue['check_id']}] `{issue['json_edit_path']}`\n")
            lines.append(f"**Content ID:** `{issue['content_id']}`")
            lines.append(f"**Why:** {issue['why']}")
            if issue.get("flagged_fragment"):
                lines.append(f"**Fragment:** \"{issue['flagged_fragment']}\"")
            if issue.get("suggested_fix"):
                lines.append(f"**Suggested fix:** {issue['suggested_fix']}")
            if issue.get("rewrite_brief"):
                lines.append(f"**Rewrite brief:** {issue['rewrite_brief']}")
            lines.append(f"**Auto-fixable:** {'Yes' if issue.get('auto_fixable') else 'No'}")
            lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")


def build_handoff_pack(report: dict, notes: dict | None = None, filtered: bool = False) -> dict:
    """Build handoff pack. If filtered=True, include only needs_fix or unreviewed items."""
    excluded_statuses = {"false_positive", "fixed", "acknowledged"}
    allowed_content_ids: set[str] | None = None
    if filtered and notes is not None:
        allowed_content_ids = set()
        for item in report.get("items", []):
            if item.get("issue_count", 0) == 0:
                continue
            cid = item["content_id"]
            status = notes.get(cid, {}).get("status", "")
            if status not in excluded_statuses:
                allowed_content_ids.add(cid)

    item_lookup = {it["content_id"]: it for it in report.get("items", [])}

    grouped: dict[str, list] = defaultdict(list)
    for issue in report.get("issues", []):
        cid = issue.get("content_id", "")
        if allowed_content_ids is not None and cid not in allowed_content_ids:
            continue
        key = f"{issue.get('json_edit_path', '')}||{cid}"
        grouped[key].append(issue)

    actions = []
    for _key, issues in grouped.items():
        top_issue = min(
            issues,
            key=lambda i: {"critical": 0, "high": 1, "medium": 2, "low": 3}.get(i["priority"], 4),
        )
        item_data = item_lookup.get(top_issue["content_id"], {})

        auto_fix_issue = next(
            (i for i in sorted(issues, key=lambda i: {"critical": 0, "high": 1, "medium": 2, "low": 3}.get(i["priority"], 4))
             if i.get("auto_fixable") and i.get("suggested_fix")),
            None,
        )

        actions.append({
            "priority": top_issue["priority"],
            "source_file": item_data.get("source_file", ""),
            "json_edit_path": top_issue["json_edit_path"],
            "current_value": item_data.get("original_content", ""),
            "action_type": top_issue.get("action_type", "review"),
            "rewrite_brief": top_issue.get("rewrite_brief", ""),
            "check_ids": list(set(i["check_id"] for i in issues)),
            "related_issue_ids": [i["id"] for i in issues],
            "content_id": top_issue.get("content_id", ""),
            "ui_section": item_data.get("ui_section", ""),
            "expected_format": item_data.get("expected_format", ""),
            "suggested_fix": auto_fix_issue["suggested_fix"] if auto_fix_issue else "",
        })

    priority_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    actions.sort(key=lambda a: priority_order.get(a["priority"], 4))

    instructions = (
        "Apply each action to the exact json_edit_path in the source file. "
        "Preserve JSON structure. Use British English throughout. "
        "Replace em-dashes with commas or semicolons. "
        "Ensure all Code bullets are complete actionable sentences of at least 8 words."
    )
    if filtered:
        instructions += (
            " This pack includes only items marked needs_fix or not yet triaged; "
            "false_positive, acknowledged, and fixed items are excluded."
        )

    return {
        "instructions": instructions,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "filtered": filtered,
        "total_actions": len(actions),
        "actions": actions,
    }


def write_handoff(report: dict, path: Path, notes: dict | None = None, filtered: bool = False):
    pack = build_handoff_pack(report, notes=notes, filtered=filtered)
    path.write_text(json.dumps(pack, indent=2, ensure_ascii=False), encoding="utf-8")


# ─── Main ──────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Cosmic Fit Content Audit Engine")
    parser.add_argument("--format", default="all", choices=["all", "json", "markdown", "handoff"],
                        help="Output format(s)")
    parser.add_argument("--sources", default="cache,dataset,blueprints,runtime,rendered",
                        help="Comma-separated source layers to audit")
    parser.add_argument("--output-dir", default=str(OUTPUT_DIR),
                        help="Directory for output files")
    args = parser.parse_args()

    sources = set(args.sources.split(","))
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Cosmic Fit — Content Audit Engine v1.0.0")
    print("=" * 60)

    # Collect all items
    all_items: list[AuditableItem] = []
    sources_audited: list[str] = []

    if "cache" in sources:
        print(f"\nLoading narrative cache: {CACHE_PATH}")
        cache_items = list(walk_narrative_cache(str(CACHE_PATH)))
        all_items.extend(cache_items)
        sources_audited.append("narrative_cache")
        print(f"  → {len(cache_items)} items")

    if "dataset" in sources:
        print(f"Loading dataset: {DATASET_PATH}")
        ds_items = list(walk_dataset(str(DATASET_PATH)))
        all_items.extend(ds_items)
        sources_audited.append("dataset")
        print(f"  → {len(ds_items)} items")

    if "blueprints" in sources:
        print(f"Loading composed blueprints: {BLUEPRINTS_DIR}")
        bp_items = list(walk_composed_blueprints(str(BLUEPRINTS_DIR)))
        all_items.extend(bp_items)
        sources_audited.append("composed_blueprints")
        print(f"  → {len(bp_items)} items")

    if "runtime" in sources:
        print(f"Loading extracted runtime strings: {EXTRACTED_PATH}")
        rt_items = list(walk_extracted_strings(str(EXTRACTED_PATH)))
        all_items.extend(rt_items)
        sources_audited.append("runtime_strings")
        print(f"  → {len(rt_items)} items")

    if "rendered" in sources:
        print(f"Loading rendered Group B templates: {CACHE_PATH}")
        rendered_items = list(walk_rendered_templates(
            str(CACHE_PATH), str(PLACEHOLDER_FIXTURE_PATH)
        ))
        all_items.extend(rendered_items)
        sources_audited.append("rendered_templates")
        print(f"  → {len(rendered_items)} items")

    total = len(all_items)
    print(f"\nTotal items to audit: {total}")
    print("Running checks...\n")

    # Per-item checks
    all_issues: list[dict] = []
    t0 = time.time()

    for idx, item in enumerate(all_items):
        while is_paused():
            time.sleep(1)

        issues = run_checks(item)
        all_issues.extend(issues)

        if idx % 200 == 0 or idx == total - 1:
            write_progress(total, idx + 1, item.content_id, len(all_issues))
            elapsed = time.time() - t0
            rate = (idx + 1) / elapsed if elapsed > 0 else 0
            pct = (idx + 1) / total * 100
            sys.stdout.write(f"\r  [{pct:5.1f}%] {idx+1}/{total} items | {len(all_issues)} issues | {rate:.0f} items/s")
            sys.stdout.flush()

    print()

    # Aggregate checks
    print("\nRunning aggregate checks...")

    # Build cluster map for narrative cache
    cache_cluster_map: dict[str, dict[str, str]] = defaultdict(dict)
    for item in all_items:
        if item.source_layer == "narrative_cache" and item.cluster_key:
            cache_cluster_map[item.cluster_key][item.section_key] = item.text

    dup_issues = check_cross_cluster_duplicates(cache_cluster_map)
    all_issues.extend(dup_issues)
    print(f"  Cross-cluster duplicates: {len(dup_issues)}")

    cluster_rep_issues = check_intra_cluster_repetition(cache_cluster_map)
    all_issues.extend(cluster_rep_issues)
    print(f"  Intra-cluster repetition: {len(cluster_rep_issues)}")

    code_issues = check_composed_code_lists(all_items)
    all_issues.extend(code_issues)
    print(f"  Composed code inconsistency: {len(code_issues)}")

    corpus_issues = check_corpus_overuse(all_items)
    all_issues.extend(corpus_issues)
    print(f"  Corpus overuse: {len(corpus_issues)}")

    elapsed = time.time() - t0
    write_progress(total, total, "complete", len(all_issues))

    # Build report
    report = build_report(all_items, all_issues, sources_audited, elapsed)

    # Write outputs
    fmt = args.format
    if fmt in ("all", "json"):
        rp = out_dir / "audit_report.json"
        rp.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"\nJSON report: {rp}")

    if fmt in ("all", "markdown"):
        mp = out_dir / "audit_report.md"
        write_markdown(report, mp)
        print(f"Markdown report: {mp}")

    if fmt in ("all", "handoff"):
        hp = out_dir / "audit_handoff_pack.json"
        write_handoff(report, hp)
        print(f"Handoff pack: {hp}")

    # Summary
    print(f"\n{'=' * 60}")
    print(f"Audit complete in {elapsed:.1f}s")
    print(f"Items audited: {report['meta']['total_items']}")
    print(f"Flagged items: {report['meta'].get('flagged_items', 0)}")
    print(f"Total issues:  {report['meta']['total_issues']}")
    for prio in ("critical", "high", "medium", "low"):
        count = report["meta"]["by_priority"].get(prio, 0)
        if count:
            print(f"  {prio.upper():>8}: {count}")
    print()
    if report["meta"]["by_check"]:
        print("Top checks:")
        by_check = report["meta"]["by_check"]
        if isinstance(by_check, dict):
            sorted_checks = sorted(by_check.items(), key=lambda x: x[1], reverse=True)
        else:
            sorted_checks = by_check
        for check_id, count in sorted_checks[:10]:
            print(f"  {check_id}: {count}")
    print(f"{'=' * 60}")

    has_critical_or_high = report["meta"]["by_priority"].get("critical", 0) + report["meta"]["by_priority"].get("high", 0)
    sys.exit(1 if has_critical_or_high else 0)


if __name__ == "__main__":
    main()
