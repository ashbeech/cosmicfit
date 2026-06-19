#!/usr/bin/env python3
"""
Cosmic Fit — Backup / restore canonical Style Guide sources before audit correction.

Files covered (same set as content_audit_apply.py):
  - data/style_guide/astrological_style_dataset.json
  - data/style_guide/blueprint_narrative_cache.json
  - data/style_guide/extracted_runtime_strings.json
  - Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift
  - Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift

Usage (from repo root):
    python3 tools/backup_style_guide_sources.py backup
    python3 tools/backup_style_guide_sources.py restore
    python3 tools/backup_style_guide_sources.py restore --backup-dir data/style_guide/backups/pre_correction_2026-06-16
    python3 tools/backup_style_guide_sources.py list
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BACKUPS_ROOT = REPO_ROOT / "data" / "style_guide" / "backups"
LATEST_POINTER = BACKUPS_ROOT / "LATEST_PRE_CORRECTION.txt"

# Repo-relative paths to snapshot
SOURCE_PATHS: list[str] = [
    "data/style_guide/astrological_style_dataset.json",
    "data/style_guide/blueprint_narrative_cache.json",
    "data/style_guide/extracted_runtime_strings.json",
    "Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift",
    "Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift",
]


def _utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%SZ")


def _resolve_sources() -> list[Path]:
    paths: list[Path] = []
    missing: list[str] = []
    for rel in SOURCE_PATHS:
        p = REPO_ROOT / rel
        if p.exists():
            paths.append(p)
        else:
            missing.append(rel)
    if missing:
        print("WARNING: missing files (skipped):")
        for m in missing:
            print(f"  - {m}")
    return paths


def cmd_backup(label: str | None) -> int:
    stamp = _utc_stamp()
    name = f"pre_correction_{stamp}"
    if label:
        name = f"pre_correction_{label}"

    backup_dir = BACKUPS_ROOT / name
    backup_dir.mkdir(parents=True, exist_ok=False)

    copied: list[dict] = []
    for src in _resolve_sources():
        rel = src.relative_to(REPO_ROOT)
        dest = backup_dir / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        copied.append({
            "repo_path": str(rel),
            "backup_path": str(dest.relative_to(REPO_ROOT)),
            "bytes": src.stat().st_size,
        })
        print(f"  copied {rel}")

    manifest = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "purpose": "Pre-audit-correction snapshot (content_audit_apply.py)",
        "repo_root": str(REPO_ROOT),
        "files": copied,
        "restore_command": (
            f"python3 tools/backup_style_guide_sources.py restore "
            f"--backup-dir {backup_dir.relative_to(REPO_ROOT)}"
        ),
    }
    manifest_path = backup_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    BACKUPS_ROOT.mkdir(parents=True, exist_ok=True)
    LATEST_POINTER.write_text(str(backup_dir.relative_to(REPO_ROOT)) + "\n", encoding="utf-8")

    print(f"\nBackup complete: {backup_dir.relative_to(REPO_ROOT)}")
    print(f"  {len(copied)} file(s)")
    print(f"Latest pointer: {LATEST_POINTER.relative_to(REPO_ROOT)}")
    print(f"\nTo restore:\n  {manifest['restore_command']}")
    return 0


def _resolve_backup_dir(arg: str | None) -> Path | None:
    if arg:
        p = Path(arg)
        if not p.is_absolute():
            p = REPO_ROOT / p
        return p

    if not LATEST_POINTER.exists():
        print("ERROR: No --backup-dir given and LATEST_PRE_CORRECTION.txt not found.")
        print("Run backup first, or pass --backup-dir explicitly.")
        return None

    rel = LATEST_POINTER.read_text(encoding="utf-8").strip()
    return REPO_ROOT / rel


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
    print(f"Created: {manifest.get('created_at', 'unknown')}")

    for entry in files:
        rel = entry["repo_path"]
        src = backup_dir / rel
        dest = REPO_ROOT / rel
        if not src.exists():
            print(f"  SKIP (missing in backup): {rel}")
            continue
        if dry_run:
            print(f"  would restore {rel}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        print(f"  restored {rel}")

    if dry_run:
        print("\n(DRY RUN — no files were modified)")
    else:
        print(f"\nRestore complete. Re-run extract if Swift was restored:")
        print("  python3 tools/extract_runtime_style_guide_strings.py")
    return 0


def cmd_list() -> int:
    if not BACKUPS_ROOT.exists():
        print("No backups yet.")
        return 0

    dirs = sorted(
        [d for d in BACKUPS_ROOT.iterdir() if d.is_dir()],
        key=lambda p: p.name,
    )
    latest = LATEST_POINTER.read_text(encoding="utf-8").strip() if LATEST_POINTER.exists() else ""

    print("Style Guide pre-correction backups:\n")
    for d in dirs:
        marker = " (latest)" if str(d.relative_to(REPO_ROOT)) == latest else ""
        manifest = d / "manifest.json"
        when = ""
        if manifest.exists():
            try:
                when = json.loads(manifest.read_text(encoding="utf-8")).get("created_at", "")
            except json.JSONDecodeError:
                when = "invalid manifest"
        print(f"  {d.name}{marker}")
        if when:
            print(f"    {when}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Backup/restore Style Guide canonical sources")
    sub = parser.add_subparsers(dest="command", required=True)

    p_backup = sub.add_parser("backup", help="Create a new pre-correction snapshot")
    p_backup.add_argument("--label", default=None, help="Optional suffix (e.g. 2026-06-16)")

    p_restore = sub.add_parser("restore", help="Restore from a backup")
    p_restore.add_argument("--backup-dir", default=None, help="Backup directory (default: latest)")
    p_restore.add_argument("--dry-run", action="store_true", help="Show what would be restored")

    sub.add_parser("list", help="List available backups")

    args = parser.parse_args()

    if args.command == "backup":
        return cmd_backup(args.label)
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
