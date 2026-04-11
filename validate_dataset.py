#!/usr/bin/env python3
"""
WP4 — Dataset Validation Script

Validates astrological_style_dataset.json against the schema checklist
(_reference/fixtures/dataset_schema_checklist.md) and the WP3 consumer
contract (BlueprintTokenGenerator.swift Codable types).

Checks:
  1. Top-level section presence and types
  2. planet_sign: 132 entries, all required fields, correct types
  3. aspects: ~30 entries, all required fields
  4. house_placements: 48 entries, all required fields
  5. element_balance: 7 entries, all required fields
  6. colour_library: ≥60 entries, hex format, associations
  7. Cross-reference: every colour name in planet_sign entries exists in colour_library
  8. Opposites field completeness
  9. Key naming conventions match WP3 expectations
"""

import argparse
import json
import re
import sys
from pathlib import Path

HEX_PATTERN = re.compile(r'^#[0-9A-Fa-f]{6}$')

SIGNS = [
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"
]

BODIES = [
    "sun", "moon", "mercury", "venus", "mars",
    "jupiter", "saturn", "uranus", "neptune", "pluto", "ascendant"
]

ELEMENT_BALANCE_KEYS = [
    "fire_dominant", "earth_dominant", "air_dominant", "water_dominant",
    "cardinal_dominant", "fixed_dominant", "mutable_dominant"
]

PRIORITY_ASPECT_PAIRS = [
    ("venus", "saturn"), ("venus", "jupiter"), ("venus", "mars"),
    ("venus", "uranus"), ("venus", "neptune"),
    ("moon", "saturn"), ("moon", "venus"),
    ("sun", "saturn"), ("mars", "saturn"),
    ("ascendant", "venus")
]

HOUSE_PLANETS = ["venus", "moon", "sun", "mars"]


def load_dataset(path: str) -> dict:
    with open(path) as f:
        return json.load(f)


class ValidationReport:
    def __init__(self):
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.info: list[str] = []

    def error(self, msg: str):
        self.errors.append(msg)

    def warn(self, msg: str):
        self.warnings.append(msg)

    def log(self, msg: str):
        self.info.append(msg)

    def print_report(self):
        print("=" * 70)
        print("WP4 DATASET VALIDATION REPORT")
        print("=" * 70)

        if self.info:
            print("\n--- INFO ---")
            for msg in self.info:
                print(f"  ✓ {msg}")

        if self.warnings:
            print(f"\n--- WARNINGS ({len(self.warnings)}) ---")
            for msg in self.warnings:
                print(f"  ⚠ {msg}")

        if self.errors:
            print(f"\n--- ERRORS ({len(self.errors)}) ---")
            for msg in self.errors:
                print(f"  ✗ {msg}")

        print(f"\n{'=' * 70}")
        if self.errors:
            print(f"RESULT: FAIL ({len(self.errors)} errors, {len(self.warnings)} warnings)")
        elif self.warnings:
            print(f"RESULT: PASS with {len(self.warnings)} warnings")
        else:
            print("RESULT: PASS")
        print("=" * 70)

        return len(self.errors) == 0


def validate_planet_sign_entry(key: str, entry: dict, report: ValidationReport):
    required_str_fields = ["style_philosophy"]
    required_obj_fields = ["textures", "colours", "patterns", "occasion_modifiers", "opposites"]
    required_arr_fields = ["metals", "stones", "silhouette_keywords", "code_leaninto", "code_avoid", "code_consider"]

    for field in required_str_fields:
        if field not in entry or not isinstance(entry[field], str) or not entry[field]:
            report.error(f"planet_sign[{key}]: missing or empty string field '{field}'")

    for field in required_arr_fields:
        if field not in entry:
            report.error(f"planet_sign[{key}]: missing array field '{field}'")
        elif not isinstance(entry[field], list) or len(entry[field]) == 0:
            report.error(f"planet_sign[{key}]: field '{field}' must be a non-empty array")

    for field in required_obj_fields:
        if field not in entry or not isinstance(entry[field], dict):
            report.error(f"planet_sign[{key}]: missing or non-object field '{field}'")

    # Textures sub-fields
    tex = entry.get("textures", {})
    for sub in ["good", "bad", "sweet_spot_keywords"]:
        if sub not in tex or not isinstance(tex.get(sub), list) or len(tex.get(sub, [])) == 0:
            report.error(f"planet_sign[{key}].textures.{sub}: missing or empty")

    # Colours sub-fields
    col = entry.get("colours", {})
    for sub in ["primary", "accent", "avoid"]:
        if sub not in col:
            report.error(f"planet_sign[{key}].colours.{sub}: missing")
    for c_entry in col.get("primary", []):
        if "name" not in c_entry or "hex" not in c_entry:
            report.error(f"planet_sign[{key}].colours.primary: entry missing 'name' or 'hex'")
        elif not HEX_PATTERN.match(c_entry["hex"]):
            report.error(f"planet_sign[{key}].colours.primary: invalid hex '{c_entry['hex']}'")
    for c_entry in col.get("accent", []):
        if isinstance(c_entry, dict):
            if "name" not in c_entry or "hex" not in c_entry:
                report.error(f"planet_sign[{key}].colours.accent: entry missing 'name' or 'hex'")
            elif not HEX_PATTERN.match(c_entry["hex"]):
                report.error(f"planet_sign[{key}].colours.accent: invalid hex '{c_entry['hex']}'")

    # Patterns sub-fields
    pat = entry.get("patterns", {})
    for sub in ["recommended", "avoid"]:
        if sub not in pat or not isinstance(pat.get(sub), list) or len(pat.get(sub, [])) == 0:
            report.error(f"planet_sign[{key}].patterns.{sub}: missing or empty")

    # Occasion modifiers
    occ = entry.get("occasion_modifiers", {})
    for sub in ["work", "intimate", "daily"]:
        if sub not in occ or not isinstance(occ.get(sub), str) or not occ.get(sub):
            report.error(f"planet_sign[{key}].occasion_modifiers.{sub}: missing or empty")

    # Opposites
    opp = entry.get("opposites", {})
    for sub in ["textures", "colours", "silhouettes", "mood"]:
        if sub not in opp or not isinstance(opp.get(sub), list) or len(opp.get(sub, [])) == 0:
            report.error(f"planet_sign[{key}].opposites.{sub}: missing or empty")


def validate_aspect_entry(key: str, entry: dict, report: ValidationReport):
    required = ["effect", "texture_modifier", "colour_modifier", "code_addition_leaninto", "code_addition_avoid"]
    for field in required:
        if field not in entry or not isinstance(entry[field], str) or not entry[field]:
            report.error(f"aspects[{key}]: missing or empty field '{field}'")


def validate_house_entry(key: str, entry: dict, report: ValidationReport, strict_house_schema: bool):
    for field in ["context", "modifier"]:
        if field not in entry or not isinstance(entry[field], str) or not entry[field]:
            report.error(f"house_placements[{key}]: missing or empty field '{field}'")

    expanded_required = ["keywords", "code_consider_bias", "occasion_bias", "lean_into_bias"]
    for field in expanded_required:
        if field not in entry:
            if strict_house_schema:
                report.error(f"house_placements[{key}]: missing required expanded field '{field}'")
            else:
                report.warn(f"house_placements[{key}]: missing migration-state field '{field}'")
            continue

        value = entry[field]
        if not isinstance(value, list) or len(value) == 0:
            if strict_house_schema:
                report.error(f"house_placements[{key}]: field '{field}' must be a non-empty array")
            else:
                report.warn(f"house_placements[{key}]: field '{field}' should be a non-empty array")

    if "hardware_bias" in entry:
        hw = entry["hardware_bias"]
        if not isinstance(hw, dict):
            report.error(f"house_placements[{key}]: hardware_bias must be an object")
        else:
            for sub in ["metals", "stones"]:
                if sub not in hw:
                    report.error(f"house_placements[{key}].hardware_bias: missing '{sub}'")
                elif not isinstance(hw[sub], list):
                    report.error(f"house_placements[{key}].hardware_bias.{sub}: must be an array")


def validate_element_entry(key: str, entry: dict, report: ValidationReport):
    for field in ["overall_energy", "palette_bias", "texture_bias"]:
        if field not in entry or not isinstance(entry[field], str) or not entry[field]:
            report.error(f"element_balance[{key}]: missing or empty field '{field}'")


def validate_colour_entry(key: str, entry: dict, report: ValidationReport):
    if "hex" not in entry or not HEX_PATTERN.match(entry.get("hex", "")):
        report.error(f"colour_library[{key}]: missing or invalid hex value")
    if "associations" not in entry or not isinstance(entry.get("associations"), list) or len(entry.get("associations", [])) == 0:
        report.error(f"colour_library[{key}]: missing or empty associations")


def validate(dataset: dict, strict_house_schema: bool) -> bool:
    report = ValidationReport()

    # ─── Top-level sections ───
    for section in ["planet_sign", "aspects", "house_placements", "element_balance", "colour_library"]:
        if section not in dataset:
            report.error(f"Missing top-level section: {section}")
        elif not isinstance(dataset[section], dict):
            report.error(f"Top-level section '{section}' must be an object")

    if report.errors:
        return report.print_report()

    ps = dataset["planet_sign"]
    aspects = dataset["aspects"]
    hp = dataset["house_placements"]
    eb = dataset["element_balance"]
    cl = dataset["colour_library"]

    # ─── planet_sign: cardinality ───
    expected_ps_keys = set()
    for body in BODIES:
        for sign in SIGNS:
            expected_ps_keys.add(f"{body}_{sign}")

    actual_ps_keys = set(ps.keys())
    missing_ps = expected_ps_keys - actual_ps_keys
    extra_ps = actual_ps_keys - expected_ps_keys

    report.log(f"planet_sign: {len(ps)} entries (expected 132)")
    if missing_ps:
        for k in sorted(missing_ps):
            report.error(f"planet_sign: missing entry '{k}'")
    if extra_ps:
        for k in sorted(extra_ps):
            report.warn(f"planet_sign: unexpected entry '{k}'")

    for key, entry in ps.items():
        validate_planet_sign_entry(key, entry, report)

    # ─── aspects ───
    report.log(f"aspects: {len(aspects)} entries")
    for key, entry in aspects.items():
        validate_aspect_entry(key, entry, report)

    # Check priority aspects are covered
    aspect_types = ["conjunction", "square", "trine", "opposition", "sextile"]
    for p1, p2 in PRIORITY_ASPECT_PAIRS:
        found = False
        for atype in aspect_types:
            if f"{p1}_{atype}_{p2}" in aspects or f"{p2}_{atype}_{p1}" in aspects:
                found = True
                break
        if not found:
            report.warn(f"aspects: no entry for priority pair {p1}-{p2}")

    # ─── house_placements: cardinality ───
    expected_hp_keys = set()
    for planet in HOUSE_PLANETS:
        for house in range(1, 13):
            expected_hp_keys.add(f"{planet}_house_{house}")

    actual_hp_keys = set(hp.keys())
    missing_hp = expected_hp_keys - actual_hp_keys

    report.log(f"house_placements: {len(hp)} entries (expected 48)")
    for k in sorted(missing_hp):
        report.error(f"house_placements: missing entry '{k}'")

    for key, entry in hp.items():
        validate_house_entry(key, entry, report, strict_house_schema=strict_house_schema)

    # ─── element_balance ───
    report.log(f"element_balance: {len(eb)} entries (expected 7)")
    for key in ELEMENT_BALANCE_KEYS:
        if key not in eb:
            report.error(f"element_balance: missing entry '{key}'")

    for key, entry in eb.items():
        validate_element_entry(key, entry, report)

    # ─── colour_library ───
    report.log(f"colour_library: {len(cl)} entries (minimum 60)")
    if len(cl) < 60:
        report.error(f"colour_library: only {len(cl)} entries (minimum 60)")

    for key, entry in cl.items():
        validate_colour_entry(key, entry, report)

    # ─── Cross-reference: colours in planet_sign → colour_library ───
    cl_lower = {k.lower(): k for k in cl.keys()}
    missing_colours = set()
    for ps_key, ps_entry in ps.items():
        colours = ps_entry.get("colours", {})
        for c in colours.get("primary", []):
            name = c.get("name", "").lower()
            if name and name not in cl_lower:
                missing_colours.add(c.get("name", ""))
        for c in colours.get("accent", []):
            if isinstance(c, dict):
                name = c.get("name", "").lower()
                if name and name not in cl_lower:
                    missing_colours.add(c.get("name", ""))

    if missing_colours:
        for name in sorted(missing_colours):
            report.warn(f"colour cross-ref: '{name}' used in planet_sign but not in colour_library")
    else:
        report.log("colour cross-ref: all planet_sign colour names found in colour_library")

    # ─── Astrological spot checks ───
    spot_checks = [
        ("venus_taurus", "textures", "good", "cashmere", "Venus in Taurus should include cashmere"),
        ("venus_scorpio", "colours", "primary", "midnight", "Venus in Scorpio should include dark colour"),
        ("moon_cancer", "textures", "good", "soft", "Moon in Cancer should include soft textures"),
    ]
    for key, field, sub, keyword, desc in spot_checks:
        if key in ps:
            data = ps[key].get(field, {})
            if isinstance(data, dict):
                items = data.get(sub, [])
                found = False
                for item in items:
                    if isinstance(item, dict):
                        if keyword.lower() in item.get("name", "").lower():
                            found = True
                            break
                    elif isinstance(item, str):
                        if keyword.lower() in item.lower():
                            found = True
                            break
                if found:
                    report.log(f"Spot check PASS: {desc}")
                else:
                    report.warn(f"Spot check WARN: {desc}")

    return report.print_report()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate astrological_style_dataset.json")
    parser.add_argument(
        "dataset_path",
        nargs="?",
        default="astrological_style_dataset.json",
        help="Path to dataset JSON file",
    )
    parser.add_argument(
        "--strict-house-schema",
        action="store_true",
        help="Enforce expanded house placement fields as required",
    )
    args = parser.parse_args()

    dataset = load_dataset(args.dataset_path)
    success = validate(dataset, strict_house_schema=args.strict_house_schema)
    sys.exit(0 if success else 1)
