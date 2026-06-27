# Cosmic Fit Documentation Index

> **Status:** Current
> **Last audited:** June 2026
> **Source of truth:** `../README.md` for current app architecture; this file classifies supporting docs.

This directory contains test artefacts, generated reports, historical notes, and a few maintained operational docs. For AI-assisted development, read the root `README.md` first. It is the canonical handoff for how Cosmic Fit works today.

## Documentation Categories

| Category | Location | Rule for AI agents |
|---|---|---|
| **Canonical architecture** | `../README.md` | Read first for the current app state, shipped Daily Fit engine, data flow, and build/test notes. |
| **Maintained local guides** | `../inspector/README.md`, `../tools/README.md`, `../data/style_guide/README.md` | Local usage only. Defer architecture claims to the root README. |
| **Generated reports** | `../data/style_guide/*.md`, `../scripts/reports/`, `fixtures/*_audit.md` | Point-in-time tool output. Do not use as current architecture source. |
| **QA / tuning fixtures** | `fixtures/` | Test, calibration, and audit artefacts. These are not app runtime docs. |
| **Historical / pruned docs** | `archive/`, `handoff/`, `house_sect_regression/` | Historical context only. Do not infer current implementation behaviour from these paths. |
| **Calibration closure** | `calibration_*.md` | Closure and policy records. Production engine weights are superseded by Sky Forward v1.0.1 in the root README and `DailyFitEngineRegistry.swift`. |

## Current Architecture Entrypoints

- Current app handoff: `../README.md`
- Shipped Daily Fit preset truth: `../Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift`
- Local inspector usage: `../inspector/README.md`
- Python tooling usage: `../tools/README.md`
- Canonical Style Guide data: `../data/style_guide/README.md`

## Pruned Handoff Docs

The prior implementation handoff set under `docs/handoff/` was intentionally pruned. If a link points to a missing handoff or archive file, treat that link as stale and use the root README plus current source code instead.

Do not restore old handoff, archive, or fixture files just to satisfy a documentation link unless a current test or runtime path explicitly requires them.
