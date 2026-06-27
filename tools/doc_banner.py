#!/usr/bin/env python3
"""Shared Markdown banners for generated documentation artefacts."""

from __future__ import annotations

from datetime import datetime, timezone


def generated_report_banner(*, script: str, command: str, generated: str | None = None) -> list[str]:
    """Return a standard banner for generated Markdown reports."""
    timestamp = generated or datetime.now(timezone.utc).isoformat()
    return [
        "> **Status:** Generated",
        "> **Do not use as current architecture source.** See `README.md` and `docs/README.md`.",
        f"> **Generated:** {timestamp} by `{script}`",
        f"> **Re-run:** `{command}`",
        "",
    ]
