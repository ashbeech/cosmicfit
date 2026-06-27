#!/usr/bin/env python3
"""Audit maintained Markdown docs for broken links and stale guidance."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote


REPO = Path(__file__).resolve().parents[1]

STRICT_DOCS = [
    REPO / "README.md",
    REPO / "AGENTS.md",
    REPO / "docs/README.md",
    REPO / "inspector/README.md",
    REPO / "tools/README.md",
    REPO / "data/style_guide/README.md",
    REPO / "docs/calibration_ephemeris_strategy.md",
    REPO / "docs/calibration_plan_closure_summary.md",
]

STATUS_RE = re.compile(r"^\s*> \*\*Status:\*\*", re.MULTILINE)
MD_LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")

PRUNED_PATHS = [
    "docs/archive/test_handoff.md",
    "docs/fixtures/blueprint_birth_specs.json",
    "docs/fixtures/golden_cases.json",
    "docs/fixtures/blueprint_input_user_",
]

STALE_PATTERNS = [
    (re.compile(r"\bDaily Vibe\b", re.IGNORECASE), "Daily Vibe naming appears in a current doc"),
    (re.compile(r"production unchanged", re.IGNORECASE), "production unchanged wording appears"),
    (re.compile(r"stage1_experimental.{0,80}(shipped|release|app store)", re.IGNORECASE), "stage1_experimental may be described as shipped"),
    (re.compile(r"0\.40.{0,80}0\.25.{0,80}0\.15.{0,80}0\.15.{0,80}0\.05", re.DOTALL), "old source-weight table appears"),
]


@dataclass
class Finding:
    severity: str
    path: Path
    message: str

    def format(self) -> str:
        rel = self.path.relative_to(REPO)
        return f"[{self.severity}] {rel}: {self.message}"


def status(text: str) -> str:
    for line in text.splitlines()[:12]:
        if line.startswith("> **Status:**"):
            return line.split(":", 1)[1].strip().lower()
    return ""


def is_generated_or_historical(text: str) -> bool:
    value = status(text)
    return "generated" in value or "historical" in value or "superseded" in value


def target_for_link(path: Path, raw_target: str) -> Path | None:
    target = raw_target.strip()
    if not target or target.startswith("#"):
        return None
    if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.IGNORECASE):
        return None
    target = target.split("#", 1)[0].strip()
    if not target:
        return None
    target = unquote(target)
    if target.startswith("/"):
        return Path(target)
    return (path.parent / target).resolve()


def audit_links(path: Path, text: str, findings: list[Finding]) -> None:
    for match in MD_LINK_RE.finditer(text):
        target = target_for_link(path, match.group(1))
        if target is None:
            continue
        if not target.exists():
            findings.append(Finding("ERROR", path, f"broken link: {match.group(1)}"))


def audit_status(path: Path, text: str, findings: list[Finding]) -> None:
    if path.name == "README.md" and path == REPO / "README.md":
        return
    if path == REPO / "AGENTS.md":
        return
    if not STATUS_RE.search(text):
        findings.append(Finding("WARN", path, "missing status metadata block"))


def audit_pruned_paths(path: Path, text: str, findings: list[Finding]) -> None:
    rel = path.relative_to(REPO).as_posix()
    allowed = rel in {
        "docs/README.md",
        "docs/handoff/README.md",
        "docs/archive/README.md",
    }
    for token in PRUNED_PATHS:
        if token in text and not allowed:
            findings.append(Finding("WARN", path, f"references pruned path token: {token}"))


def audit_stale_terms(path: Path, text: str, findings: list[Finding]) -> None:
    if is_generated_or_historical(text):
        return
    for pattern, message in STALE_PATTERNS:
        if pattern.search(text):
            findings.append(Finding("WARN", path, message))


def main() -> int:
    findings: list[Finding] = []
    docs = [p for p in STRICT_DOCS if p.exists()]

    for path in docs:
        text = path.read_text(encoding="utf-8")
        audit_status(path, text, findings)
        audit_links(path, text, findings)
        audit_pruned_paths(path, text, findings)
        audit_stale_terms(path, text, findings)

    errors = [f for f in findings if f.severity == "ERROR"]
    warnings = [f for f in findings if f.severity == "WARN"]

    if findings:
        for finding in findings:
            print(finding.format())
    else:
        print("Docs audit passed with no findings.")

    print(f"\nSummary: {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
