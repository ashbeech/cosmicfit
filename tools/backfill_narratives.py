#!/usr/bin/env python3
"""
Cosmic Fit — Style Guide narrative backfill (SG-3 regeneration pipeline).

Regenerates the narrative cache in the instructional coach genre, writing cache
schema v2 objects gated by the blocking write gate. This is the CLI entrypoint;
the generation logic lives in tools/sg_generate.py (unit-testable without the
network), the write gate in tools/sg_validation.py, and the coarse profile in
tools/sg_profile.py.

Usage (from repo root):
    python3 tools/backfill_narratives.py \
        --clusters tools/representative_clusters.json \
        --backup-dir data/content_backups/{date}_pre-phase-3 \
        --output data/style_guide/blueprint_narrative_cache.json \
        [--resume-from-partial] [--rerun-quarantine] \
        [--model gemini-3.1-pro-preview] [--limit N] [--dry-run]

Resumability contract (Phase 3f): the cache is written after every cluster.
--resume-from-partial skips cluster/section pairs already present and passing
(v2 dicts with text); --rerun-quarantine re-attempts previously quarantined
sections. A crash mid-run never restarts from zero and never double-spends.

Budget: generation spend is pre-approved (Ash, 2026-07-06). The model id and a
cost/wall-clock estimate are pinned in the run log FOR THE RECORD, not as a
blocking approval step.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from backup_content_sources import require_backup_gate
import sg_generate as G
from sg_profile import coarse_profile_from_key
from gemini_client import (
    GeminiClient, QuotaExhaustedError,
    load_local_env_file, resolve_api_keys, resolve_model_name,
)

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE_SCHEMA_VERSION = 2
RESERVED_KEYS = {"schema_version", "coreFormula", "closing"}

load_local_env_file()


# ─── Multi-key generator (key rotation on quota exhaustion) ────────────

class MultiKeyGenerator:
    """Wraps N GeminiClients, rotating to the next key when one is quota-
    exhausted. Exposes generate_json(prompt, system, schema) -> dict."""

    def __init__(self, api_keys: list[str], model_name: str):
        self._keys = api_keys
        self._model = model_name
        self._idx = 0
        self._client = self._new_client(api_keys[0])
        self.calls = 0

    def _new_client(self, key: str):
        client = GeminiClient(key, self._model)
        # Pin the model: a model-not-found must NEVER silently downgrade to a
        # flash tier mid-run (the failure mode we stopped run 1 to avoid).
        # Disabling the fallback turns a retired preview model into a hard error
        # instead of an unlogged switch to gemini-2.5-flash.
        client._fallback_model = lambda: None
        if client.model != self._model:
            raise RuntimeError(f"client model {client.model} != requested {self._model}")
        return client

    @property
    def model(self) -> str:
        return self._client.model

    def _rotate(self) -> bool:
        if self._idx + 1 >= len(self._keys):
            return False
        self._idx += 1
        self._client = self._new_client(self._keys[self._idx])
        print(f"    Key quota exhausted; rotated to key {self._idx + 1}/{len(self._keys)}")
        return True

    def generate_json(self, prompt: str, system: str, schema: dict) -> dict:
        while True:
            try:
                self.calls += 1
                return self._client.generate_json(prompt, system, schema)
            except QuotaExhaustedError:
                if not self._rotate():
                    raise
            finally:
                time.sleep(0.2)  # gentle pacing


# ─── Cache / sidecar IO ───────────────────────────────────────────────

def load_cache(path: Path) -> dict:
    if path.exists():
        with open(path) as f:
            data = json.load(f)
        if isinstance(data, dict):
            data.setdefault("schema_version", CACHE_SCHEMA_VERSION)
            return data
    return {"schema_version": CACHE_SCHEMA_VERSION}


def save_json(path: Path, data) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    tmp.replace(path)


def existing_passing_sections(cache: dict, cluster_key: str, regate: bool = True) -> dict:
    """Sections already present for a cluster. With `regate` (default), each is
    re-checked against the CURRENT write gate and only kept if it still passes,
    so a resume never trusts stale content written by an older prompt/gate/model.
    Failing sections are treated as absent and regenerated."""
    obj = cache.get(cluster_key)
    if not isinstance(obj, dict):
        return {}
    candidates = {k: v for k, v in obj.items()
                  if k not in RESERVED_KEYS and isinstance(v, dict) and v.get("text")}
    if not regate:
        return candidates
    prof = coarse_profile_from_key(cluster_key)
    if prof is None:
        return candidates
    examples_all = G._load(G.SECTION_EXAMPLES_PATH)["section_examples"]
    kept: dict = {}
    passing_texts: list[str] = []
    for sk in G.SECTION_KEYS:
        v = candidates.get(sk)
        if not v:
            continue
        verdict = G.gate_section(v["text"], sk, prof, passing_texts,
                                 examples_all.get(sk, []), intro=v.get("sectionIntro", ""))
        if verdict["passed"]:
            kept[sk] = v
            passing_texts.append(v["text"])
    return kept


# ─── Volume / cost estimate (for the record) ──────────────────────────

def cost_estimate(n_clusters: int, model: str) -> dict:
    sections = len(G.SECTION_KEYS)
    base_calls = n_clusters * sections
    holistic_calls = n_clusters
    retry_factor = 1.3
    est_calls = int(base_calls * retry_factor) + holistic_calls
    # Rough token estimate: ~1.6k in + ~0.4k out per section call.
    est_tokens = est_calls * 2000
    return {
        "model": model,
        "clusters": n_clusters,
        "sections_per_cluster": sections,
        "base_section_calls": base_calls,
        "holistic_calls": holistic_calls,
        "estimated_calls_with_retries": est_calls,
        "estimated_tokens_order_of_magnitude": est_tokens,
        "note": "Estimate for the record only. Generation spend pre-approved "
                "(Ash, 2026-07-06); not a blocking approval step.",
    }


# ─── Main ─────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Cosmic Fit SG-3 narrative backfill")
    parser.add_argument("--clusters", default=str(REPO_ROOT / "tools" / "representative_clusters.json"),
                        help="Path to representative_clusters.json (default) or a JSON list of keys")
    parser.add_argument("--output", default=str(REPO_ROOT / "data" / "style_guide" / "blueprint_narrative_cache.json"))
    parser.add_argument("--backup-dir", default=None,
                        help="Existing content backup dir satisfying the backup gate")
    parser.add_argument("--force-no-backup", action="store_true",
                        help="EMERGENCY ONLY: bypass the content-backup hard gate")
    parser.add_argument("--model", help="Gemini model id (default: gemini_client.DEFAULT_MODEL / GEMINI_MODEL)")
    parser.add_argument("--api-key", help="Single Gemini API key override")
    parser.add_argument("--resume-from-partial", action="store_true",
                        help="Skip cluster/section pairs already present and passing")
    parser.add_argument("--rerun-quarantine", action="store_true",
                        help="Re-attempt sections in the quarantine file")
    parser.add_argument("--workers", type=int, default=0,
                        help="Parallel clusters (0 = one per API key; capped at min(keys,8))")
    parser.add_argument("--limit", type=int, default=0, help="Max clusters (0 = all)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print plan + one built prompt, make no API calls")
    args = parser.parse_args()

    # Content-backup hard gate (non-interactive: exits 2 with a message).
    require_backup_gate(
        script_name="backfill_narratives.py",
        backup_dir_arg=args.backup_dir,
        force_no_backup=args.force_no_backup,
    )

    output = Path(args.output)
    out_dir = output.parent
    quarantine_path = out_dir / "blueprint_narrative_cache_quarantine.json"
    triage_path = out_dir / "triage_status.json"
    runlog_path = out_dir / "sg3_run_log.jsonl"

    # Load cluster keys.
    clusters_doc = json.loads(Path(args.clusters).read_text())
    if isinstance(clusters_doc, dict):
        clusters = clusters_doc["clusters"]
        golden = clusters_doc.get("_meta", {}).get("golden_included", [])
    else:
        clusters = clusters_doc
        golden = []
    # Assert all golden clusters are in the selection before any spend.
    missing_golden = [g for g in golden if g not in set(clusters)]
    if missing_golden:
        print(f"ERROR: golden clusters missing from selection: {missing_golden}", file=sys.stderr)
        sys.exit(2)
    if args.limit > 0:
        clusters = clusters[:args.limit]

    model_name = resolve_model_name(args.model)
    print(f"SG-3 backfill — {len(clusters)} clusters, model={model_name}")
    print(f"Cost estimate (for the record): {json.dumps(cost_estimate(len(clusters), model_name))}")

    if args.dry_run:
        prof = coarse_profile_from_key(clusters[0])
        ex = G._load(G.SECTION_EXAMPLES_PATH)["section_examples"].get("palette_narrative", [])[:2]
        ri = G.ranked_items_for_section("palette_narrative", prof)
        tests, traps = G.select_tests_traps("palette_narrative", prof)
        prompt = G.build_section_prompt("palette_narrative", prof, ri, tests, traps,
                                        {"formula": prof.core_formula}, [], ex)
        print(f"\n[DRY RUN] {len(clusters)} clusters. Sample profile for {clusters[0]}:")
        print(json.dumps(prof.as_dict(), indent=2, ensure_ascii=False))
        print(f"\n[DRY RUN] Sample palette_narrative prompt:\n{prompt}")
        return

    api_keys = [args.api_key] if args.api_key else resolve_api_keys(None)
    workers = args.workers if args.workers > 0 else len(api_keys)
    workers = max(1, min(workers, len(api_keys), 8))
    # One generator per worker. Each gets the FULL key list, rotated so worker i
    # STARTS on key i (distribution) but can rotate through ALL keys when its
    # current one hits quota (failover). Each MultiKeyGenerator builds its own
    # GeminiClient instances, so nothing is shared across threads. This is the
    # fix for the run-1 stall: previously each worker held a single-key list, so
    # _rotate() had nothing to rotate to and quota exhaustion stalled the worker.
    def _rotated(seq, n):
        n %= len(seq)
        return seq[n:] + seq[:n]
    worker_gens = [MultiKeyGenerator(_rotated(api_keys, i), model_name)
                   for i in range(workers)]
    print(f"Loaded {len(api_keys)} API key(s); {workers} parallel worker(s). "
          f"Live model: {worker_gens[0].model}")

    cache = load_cache(output)
    cache["schema_version"] = CACHE_SCHEMA_VERSION
    quarantine = json.loads(quarantine_path.read_text()) if quarantine_path.exists() else {}
    triage = json.loads(triage_path.read_text()) if triage_path.exists() else {}

    # Pre-warm shared read-only JSON caches before spawning threads.
    G._load(G.SECTION_EXAMPLES_PATH); G._load(G.TEST_TRAP_LIBRARY_PATH); G._load(G.RANKED_TABLES_PATH)

    # Build the work list (apply resume skips up front).
    pending: list[str] = []
    skipped = 0
    for cluster_key in clusters:
        if coarse_profile_from_key(cluster_key) is None:
            print(f"  {cluster_key}: INVALID KEY, skipping")
            continue
        existing = existing_passing_sections(cache, cluster_key) if args.resume_from_partial else {}
        complete = (args.resume_from_partial and len(existing) == len(G.SECTION_KEYS)
                    and isinstance(cache.get(cluster_key), dict)
                    and cache[cluster_key].get("closing"))
        if complete and not (args.rerun_quarantine and quarantine.get(cluster_key)):
            skipped += 1
            continue
        pending.append(cluster_key)
    print(f"Pending clusters: {len(pending)} (skipped {skipped} already-complete)")

    started = datetime.now(timezone.utc).isoformat()
    totals = {"pass": 0, "pass_after_retry": 0, "quarantined": 0,
              "skip_present": skipped * len(G.SECTION_KEYS)}
    run_start = time.time()
    lock = threading.Lock()

    runlog = open(runlog_path, "a")
    runlog.write(json.dumps({"event": "run_start", "at": started, "model": worker_gens[0].model,
                             "clusters": len(pending), "workers": workers}) + "\n")
    runlog.flush()

    def worker(cluster_key: str, gen: MultiKeyGenerator):
        prof = coarse_profile_from_key(cluster_key)
        existing = existing_passing_sections(cache, cluster_key) if args.resume_from_partial else {}
        result = G.generate_cluster(cluster_key, prof, gen.generate_json,
                                    log_fn=lambda *_: None, existing_cluster=dict(existing))
        return cluster_key, prof, result, gen.model

    def persist(cluster_key, prof, result, model):
        cobj = cache.get(cluster_key)
        if not isinstance(cobj, dict) or any(k not in RESERVED_KEYS and not isinstance(v, dict)
                                             for k, v in cobj.items()):
            cobj = {}  # discard any legacy v1 plain-string cluster
        cobj["coreFormula"] = result["cluster"].get("coreFormula", prof.core_formula)
        if result["cluster"].get("closing"):
            cobj["closing"] = result["cluster"]["closing"]
        for sk in G.SECTION_KEYS:
            if sk in result["cluster"]:
                cobj[sk] = result["cluster"][sk]
        cache[cluster_key] = cobj
        if result["quarantine"]:
            quarantine.setdefault(cluster_key, {}).update(result["quarantine"])
        elif cluster_key in quarantine:
            del quarantine[cluster_key]
        for entry in result["run_log"]:
            totals[entry["outcome"]] = totals.get(entry["outcome"], 0) + 1
            if entry.get("warnings") and entry["section"] != "_holistic":
                triage.setdefault(cluster_key, {})[entry["section"]] = entry["warnings"]
            # Record the EXECUTING worker's model per entry (fallback disabled, so
            # it is verifiable) — a post-run audit can prove no flash downgrade.
            runlog.write(json.dumps({"cluster": cluster_key, "model": model, **entry}) + "\n")
        runlog.flush()
        save_json(output, cache)
        save_json(quarantine_path, quarantine)
        save_json(triage_path, triage)

    done = 0
    try:
        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = {pool.submit(worker, ck, worker_gens[i % workers]): ck
                       for i, ck in enumerate(pending)}
            for fut in as_completed(futures):
                ck = futures[fut]
                try:
                    cluster_key, prof, result, model = fut.result()
                except QuotaExhaustedError:
                    print(f"  {ck}: key quota exhausted; will resume later")
                    continue
                except Exception as e:  # keep the batch alive; cluster is resumable
                    print(f"  {ck}: ERROR {e}")
                    continue
                with lock:
                    persist(cluster_key, prof, result, model)
                    done += 1
                    q = "Q" if result["quarantine"] else "ok"
                    print(f"  [{done}/{len(pending)}] {cluster_key} "
                          f"({prof.aesthetic_register}/{prof.temperature}) {q}"
                          f"  elapsed={round(time.time()-run_start)}s", flush=True)
    finally:
        elapsed = round(time.time() - run_start, 1)
        api_calls = sum(g.calls for g in worker_gens)
        summary = {
            "event": "run_complete", "at": datetime.now(timezone.utc).isoformat(),
            "elapsed_sec": elapsed, "api_calls": api_calls, "totals": totals,
            "clusters_done": done,
            "clusters_with_quarantine": list(quarantine.keys()),
            "clusters_with_triage": list(triage.keys()),
        }
        runlog.write(json.dumps(summary) + "\n")
        runlog.close()

    print(f"\n{'='*64}")
    print("SG-3 BACKFILL COMPLETE")
    print(f"  Totals: {totals}")
    print(f"  API calls: {api_calls} | elapsed: {elapsed}s | clusters done: {done}")
    print(f"  Quarantined clusters: {len(quarantine)} -> {quarantine_path}")
    print(f"  Triage-tagged clusters: {len(triage)} -> {triage_path}")
    print(f"  Run log: {runlog_path}")
    print(f"  Output: {output}")
    print(f"{'='*64}")


if __name__ == "__main__":
    main()
