#!/usr/bin/env python3
"""
Cosmic Fit — Unified content backup / restore for all user-facing copy sources.

Supersedes tools/backup_style_guide_sources.py for new work (that script and its
snapshots under data/style_guide/backups/ remain valid historical backups).

Covers BOTH copy domains (Style Guide Quality Overhaul, Phase -1):

  style_guide:
    - data/style_guide/astrological_style_dataset.json
    - data/style_guide/blueprint_narrative_cache.json
    - data/style_guide/blueprint_narrative_cache-2-clusters.json
    - data/style_guide/extracted_runtime_strings.json
    - Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift
    - Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift
    - tools/backfill_narratives.py

  daily_fit:
    - Cosmic Fit/Resources/TarotCards.json
    - Cosmic Fit/InterpretationEngine/TarotCard.swift

Backups live in repo-local dated directories:

  data/content_backups/{YYYY-MM-DD}_{label}/
    manifest.json          # created_at, domain, label, file list with bytes+sha256, restore command
    <repo-relative paths preserved>

  data/content_backups/LATEST.txt   # pointer to the most recent snapshot

Usage (from repo root):
    python3 tools/backup_content_sources.py backup --domain all --label style-guide-overhaul-initial
    python3 tools/backup_content_sources.py restore                      # from LATEST.txt
    python3 tools/backup_content_sources.py restore --backup-dir data/content_backups/2026-07-06_style-guide-overhaul-initial
    python3 tools/backup_content_sources.py restore --dry-run
    python3 tools/backup_content_sources.py list

Hard gate (non-interactive by construction): amend scripts (backfill_narratives.py,
content_audit_apply.py) import require_backup_gate() from this module and refuse to
run unless a backup for the current UTC date exists (or --backup-dir points at one),
unless --force-no-backup is passed. The gate NEVER prompts on stdin; it exits
non-zero with a clear message.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BACKUPS_ROOT = REPO_ROOT / "data" / "content_backups"
LATEST_POINTER = BACKUPS_ROOT / "LATEST.txt"

DOMAIN_SOURCES: dict[str, list[str]] = {
    "style_guide": [
        "data/style_guide/astrological_style_dataset.json",
        "data/style_guide/blueprint_narrative_cache.json",
        "data/style_guide/blueprint_narrative_cache-2-clusters.json",
        "data/style_guide/extracted_runtime_strings.json",
        "Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift",
        "Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift",
        "tools/backfill_narratives.py",
    ],
    "daily_fit": [
        "Cosmic Fit/Resources/TarotCards.json",
        "Cosmic Fit/InterpretationEngine/TarotCard.swift",
    ],
}

VALID_DOMAINS = ("style_guide", "daily_fit", "all")


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _utc_date_str() -> str:
    return _utc_now().strftime("%Y-%m-%d")


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _sources_for_domain(domain: str) -> list[str]:
    if domain == "all":
        return DOMAIN_SOURCES["style_guide"] + DOMAIN_SOURCES["daily_fit"]
    return DOMAIN_SOURCES[domain]


# ─── backup ────────────────────────────────────────────────────────────

def cmd_backup(domain: str, label: str | None) -> int:
    date_str = _utc_date_str()
    suffix = label if label else _utc_now().strftime("%H%M%SZ")
    backup_dir = BACKUPS_ROOT / f"{date_str}_{suffix}"

    if backup_dir.exists():
        print(f"ERROR: backup directory already exists: {backup_dir.relative_to(REPO_ROOT)}")
        print("Pass a different --label (or none, for a time-stamped name).")
        return 1

    rel_sources = _sources_for_domain(domain)
    missing = [rel for rel in rel_sources if not (REPO_ROOT / rel).exists()]
    if missing:
        print("ERROR: cannot back up, source file(s) missing:")
        for m in missing:
            print(f"  - {m}")
        return 1

    backup_dir.mkdir(parents=True)
    copied: list[dict] = []
    for rel in rel_sources:
        src = REPO_ROOT / rel
        dest = backup_dir / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        copied.append({
            "repo_path": rel,
            "bytes": src.stat().st_size,
            "sha256": _sha256(src),
        })
        print(f"  copied {rel}")

    manifest = {
        "created_at": _utc_now().isoformat(),
        "date": date_str,
        "domain": domain,
        "label": label or "",
        "purpose": "Dated content snapshot (Style Guide Quality Overhaul backup gate)",
        "files": copied,
        "restore_command": (
            f"python3 tools/backup_content_sources.py restore "
            f"--backup-dir {backup_dir.relative_to(REPO_ROOT)}"
        ),
    }
    (backup_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    LATEST_POINTER.write_text(str(backup_dir.relative_to(REPO_ROOT)) + "\n", encoding="utf-8")

    print(f"\nBackup complete: {backup_dir.relative_to(REPO_ROOT)}")
    print(f"  domain: {domain}, {len(copied)} file(s)")
    print(f"Latest pointer: {LATEST_POINTER.relative_to(REPO_ROOT)}")
    print(f"\nTo restore:\n  {manifest['restore_command']}")
    return 0


# ─── restore ───────────────────────────────────────────────────────────

def _resolve_backup_dir(arg: str | None) -> Path | None:
    if arg:
        p = Path(arg)
        if not p.is_absolute():
            p = REPO_ROOT / p
        return p
    if not LATEST_POINTER.exists():
        print("ERROR: no --backup-dir given and data/content_backups/LATEST.txt not found.")
        print("Run backup first, or pass --backup-dir explicitly.")
        return None
    return REPO_ROOT / LATEST_POINTER.read_text(encoding="utf-8").strip()


def cmd_restore(backup_dir: Path, dry_run: bool) -> int:
    manifest_path = backup_dir / "manifest.json"
    if not manifest_path.exists():
        print(f"ERROR: manifest not found: {manifest_path}")
        return 1

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    files = manifest.get("files", [])
    if not files:
        print("ERROR: manifest has no files.")
        return 1

    print(f"Restoring from: {backup_dir.relative_to(REPO_ROOT)}")
    print(f"Created: {manifest.get('created_at', 'unknown')} (domain: {manifest.get('domain', '?')})")

    errors = 0
    for entry in files:
        rel = entry["repo_path"]
        src = backup_dir / rel
        dest = REPO_ROOT / rel
        if not src.exists():
            print(f"  ERROR (missing in backup): {rel}")
            errors += 1
            continue
        expected = entry.get("sha256")
        if expected and _sha256(src) != expected:
            print(f"  ERROR (backup copy corrupted, sha256 mismatch): {rel}")
            errors += 1
            continue
        if dry_run:
            print(f"  would restore {rel}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        print(f"  restored {rel}")

    if dry_run:
        print("\n(DRY RUN — no files were modified)")
    elif errors == 0:
        print("\nRestore complete. If Swift copy sources were restored, re-run:")
        print("  python3 tools/extract_runtime_style_guide_strings.py")
    return 1 if errors else 0


# ─── list ──────────────────────────────────────────────────────────────

def cmd_list() -> int:
    if not BACKUPS_ROOT.exists():
        print("No content backups yet.")
        return 0
    dirs = sorted([d for d in BACKUPS_ROOT.iterdir() if d.is_dir()], key=lambda p: p.name)
    latest = LATEST_POINTER.read_text(encoding="utf-8").strip() if LATEST_POINTER.exists() else ""

    print("Content backups (data/content_backups/):\n")
    for d in dirs:
        marker = " (latest)" if str(d.relative_to(REPO_ROOT)) == latest else ""
        info = ""
        manifest = d / "manifest.json"
        if manifest.exists():
            try:
                m = json.loads(manifest.read_text(encoding="utf-8"))
                info = f"    {m.get('created_at', '')}  domain={m.get('domain', '?')}  files={len(m.get('files', []))}"
            except json.JSONDecodeError:
                info = "    (invalid manifest)"
        print(f"  {d.name}{marker}")
        if info:
            print(info)
    return 0


# ─── hard gate (imported by amend scripts) ─────────────────────────────

def find_backup_for_date(date_str: str | None = None, domains: tuple[str, ...] = ("style_guide", "all")) -> Path | None:
    """Return the newest backup dir for the given UTC date (default today)
    whose manifest domain is in `domains`, or None."""
    date_str = date_str or _utc_date_str()
    if not BACKUPS_ROOT.exists():
        return None
    candidates = sorted(
        [d for d in BACKUPS_ROOT.iterdir() if d.is_dir() and d.name.startswith(date_str)],
        key=lambda p: p.name,
        reverse=True,
    )
    for d in candidates:
        manifest = d / "manifest.json"
        if not manifest.exists():
            continue
        try:
            m = json.loads(manifest.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        if m.get("domain") in domains:
            return d
    return None


def require_backup_gate(
    script_name: str,
    backup_dir_arg: str | None = None,
    force_no_backup: bool = False,
    domains: tuple[str, ...] = ("style_guide", "all"),
) -> None:
    """Non-interactive content-backup hard gate for copy-amending scripts.

    Passes when one of:
      - force_no_backup is True (emergency override; prints a loud warning);
      - backup_dir_arg points at an existing backup with a manifest.json;
      - a backup for the current UTC date with a matching domain exists.

    Otherwise exits the process with code 2 and a clear message. NEVER prompts
    for keyboard input (master plan, blocking-flag rule).
    """
    if force_no_backup:
        print(f"WARNING [{script_name}]: --force-no-backup passed; content-backup gate BYPASSED.")
        print("         This is for emergencies only. Take a backup as soon as possible:")
        print("         python3 tools/backup_content_sources.py backup --domain all --label <purpose>")
        return

    if backup_dir_arg:
        p = Path(backup_dir_arg)
        if not p.is_absolute():
            p = REPO_ROOT / p
        if p.is_dir() and (p / "manifest.json").exists():
            print(f"[{script_name}] Backup gate satisfied by --backup-dir: {p}")
            return
        print(f"ERROR [{script_name}]: --backup-dir does not exist or has no manifest.json: {p}")
        sys.exit(2)

    found = find_backup_for_date(domains=domains)
    if found is not None:
        print(f"[{script_name}] Backup gate satisfied: {found.relative_to(REPO_ROOT)}")
        return

    print(f"ERROR [{script_name}]: no content backup found for today (UTC {_utc_date_str()}).")
    print("This script amends user-facing copy sources and refuses to run without a same-day backup.")
    print("Create one first:")
    print("  python3 tools/backup_content_sources.py backup --domain all --label <purpose>")
    print("Or point at an existing snapshot with --backup-dir, or (emergencies only) pass --force-no-backup.")
    sys.exit(2)


# ─── main ──────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Backup/restore Cosmic Fit content copy sources")
    sub = parser.add_subparsers(dest="command", required=True)

    p_backup = sub.add_parser("backup", help="Create a new dated snapshot")
    p_backup.add_argument("--domain", default="all", choices=VALID_DOMAINS,
                          help="Which copy domain to snapshot (default: all)")
    p_backup.add_argument("--label", default=None,
                          help="Purpose slug appended to the dated directory name")

    p_restore = sub.add_parser("restore", help="Restore from a backup")
    p_restore.add_argument("--backup-dir", default=None, help="Backup directory (default: LATEST.txt)")
    p_restore.add_argument("--dry-run", action="store_true", help="Show what would be restored")

    sub.add_parser("list", help="List available backups")

    args = parser.parse_args()

    if args.command == "backup":
        return cmd_backup(args.domain, args.label)
    if args.command == "restore":
        backup_dir = _resolve_backup_dir(args.backup_dir)
        if backup_dir is None:
            return 1
        if not backup_dir.is_dir():
            print(f"ERROR: backup directory not found: {backup_dir}")
            return 1
        return cmd_restore(backup_dir, args.dry_run)
    if args.command == "list":
        return cmd_list()
    return 1


if __name__ == "__main__":
    sys.exit(main())
