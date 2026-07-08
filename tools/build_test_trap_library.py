#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 test/trap library builder (Phase 3e deliverable).

Transforms the verbatim golden-guide extraction (golden_extract.json) into
data/style_guide/test_trap_library.json: the canonical, profile/register-keyed
supply of named tests and traps that the generation prompts draw from and that
SG-4's test/trap-presence check validates against.

Structure:
  sections[<composed_section>] = {
    tests:  { <register|"any">: [ "<verbatim test phrase>", ... ] },
    traps:  { <register|"any">: [ { failure, fix }, ... ] }
  }
Register-neutral entries (e.g. "cost-per-wear") land under "any". Entries carry
their originating register from the golden set; a chart selects its own register
bucket first, then falls back to "any".
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
EXTRACT = Path("/private/tmp/claude-501/-Users-ash-dev-mobile-apps-cosmicfit/"
               "ba00ec8e-4964-489f-b2e8-71f46dddf43f/scratchpad/golden_extract.json")
OUTPUT = REPO_ROOT / "data" / "style_guide" / "test_trap_library.json"

CACHE_KEY_TO_SECTION = {
    "style_core": "blueprint",
    "palette_narrative": "palette",
    "textures_good": "textures", "textures_bad": "textures", "textures_sweet_spot": "textures",
    "occasions_work": "occasions", "occasions_intimate": "occasions", "occasions_daily": "occasions",
    "hardware_metals": "hardware", "hardware_stones": "hardware", "hardware_tip": "hardware",
    "accessory_1": "accessory", "accessory_2": "accessory", "accessory_3": "accessory",
    "pattern_narrative": "pattern", "pattern_tip": "pattern",
    # code is Swift-deterministic; kept for SG-4 completeness
}

VALID_REGISTERS = {"quietLuxury", "boldExpression", "versatileAdaptive"}


def _register_of(entry: dict | str) -> str:
    if isinstance(entry, dict):
        r = entry.get("register", "any")
        return r if r in VALID_REGISTERS else "any"
    return "any"


def _test_text(entry: dict | str) -> str:
    if isinstance(entry, str):
        return entry
    return entry.get("test") or entry.get("failure") or ""


def build() -> dict:
    extract = json.loads(EXTRACT.read_text())
    tt = extract["tests_and_traps"]

    sections: dict[str, dict] = {}
    for section, body in tt.items():
        tests_by_reg: dict[str, list[str]] = {}
        traps_by_reg: dict[str, list[dict]] = {}

        for entry in body.get("tests", []):
            text = _test_text(entry)
            if not text:
                continue
            reg = _register_of(entry)
            tests_by_reg.setdefault(reg, [])
            if text not in tests_by_reg[reg]:
                tests_by_reg[reg].append(text)

        for entry in body.get("traps", []):
            if not isinstance(entry, dict):
                continue
            if "failure" not in entry or "fix" not in entry:
                # register-note or annotation rows are kept as metadata
                continue
            reg = _register_of(entry)
            traps_by_reg.setdefault(reg, [])
            trap = {"failure": entry["failure"], "fix": entry["fix"]}
            if trap not in traps_by_reg[reg]:
                traps_by_reg[reg].append(trap)

        # Preserve any annotation notes (e.g. pattern register-inversion note).
        notes = [e["note"] for e in body.get("traps", [])
                 if isinstance(e, dict) and "note" in e]

        sections[section] = {"tests": tests_by_reg, "traps": traps_by_reg}
        if notes:
            sections[section]["notes"] = notes

    return {
        "_meta": {
            "description": "SG-3 profile/register-keyed test & trap library (Phase 3e). "
                           "Verbatim named tests and traps harvested from the 16 golden "
                           "guides. Generation selects the chart's register bucket first, "
                           "then falls back to 'any'. Consumed by tools/backfill_narratives.py "
                           "and validated by SG-4's test/trap-presence check. Built by "
                           "tools/build_test_trap_library.py from the golden guides.",
            "schema_version": 1,
            "cache_key_to_section": CACHE_KEY_TO_SECTION,
        },
        "sections": sections,
    }


def main() -> None:
    lib = build()
    OUTPUT.write_text(json.dumps(lib, indent=2, ensure_ascii=False) + "\n")
    # Coverage summary
    print(f"Wrote {OUTPUT}")
    for section, body in lib["sections"].items():
        n_tests = sum(len(v) for v in body["tests"].values())
        n_traps = sum(len(v) for v in body["traps"].values())
        regs = sorted(set(body["tests"]) | set(body["traps"]))
        print(f"  {section:10s}: {n_tests} tests, {n_traps} traps, registers={regs}")


if __name__ == "__main__":
    main()
