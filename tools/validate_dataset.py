#!/usr/bin/env python3
"""
WP4 — Dataset Validation Script

Validates astrological_style_dataset.json against the schema checklist
(docs/fixtures/dataset_schema_checklist.md) and the WP3 consumer
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
 10. fallback_palette_pool: ≥4 entries with name/hex/role; ≥1 core and ≥1 accent
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


def resolve_repo_path(path_str: str) -> Path:
    p = Path(path_str)
    return p if p.is_absolute() else (REPO_ROOT / p).resolve()

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


def load_dataset(path: Path | str) -> dict:
    with open(Path(path)) as f:
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

    # Metals: SG-2 Phase 2a object schema {name, register, finish}. Migration
    # is complete, so object form is required; a legacy string is an error.
    valid_registers = {"personal", "structural", "either"}
    valid_finishes = {"polished", "matte", "brushed", "aged"}
    for m in entry.get("metals", []):
        if isinstance(m, str):
            report.error(f"planet_sign[{key}].metals: legacy string '{m}' — migrate to object {{name, register, finish}}")
        elif isinstance(m, dict):
            if not isinstance(m.get("name"), str) or not m.get("name"):
                report.error(f"planet_sign[{key}].metals: entry missing 'name'")
            if m.get("register") not in valid_registers:
                report.error(f"planet_sign[{key}].metals['{m.get('name')}']: invalid register '{m.get('register')}'")
            if m.get("finish") not in valid_finishes:
                report.error(f"planet_sign[{key}].metals['{m.get('name')}']: invalid finish '{m.get('finish')}'")
        else:
            report.error(f"planet_sign[{key}].metals: entry must be an object")

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
    # Object-typed sections: required, must be JSON objects.
    for section in ["planet_sign", "aspects", "house_placements", "element_balance", "colour_library"]:
        if section not in dataset:
            report.error(f"Missing top-level section: {section}")
        elif not isinstance(dataset[section], dict):
            report.error(f"Top-level section '{section}' must be an object")

    # Array-typed sections: required, must be JSON arrays.
    # Added in Phase A spec v1.1 rev 3 §6.5 (Option A).
    for section in ["fallback_palette_pool"]:
        if section not in dataset:
            report.error(f"Missing top-level section: {section}")
        elif not isinstance(dataset[section], list):
            report.error(f"Top-level section '{section}' must be an array")

    if report.errors:
        return report.print_report()

    ps = dataset["planet_sign"]
    aspects = dataset["aspects"]
    hp = dataset["house_placements"]
    eb = dataset["element_balance"]
    cl = dataset["colour_library"]
    fpp = dataset["fallback_palette_pool"]

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

    # ─── fallback_palette_pool (Phase A spec §6.5, Option A) ───
    report.log(f"fallback_palette_pool: {len(fpp)} entries")
    if len(fpp) < 4:
        report.error(
            f"fallback_palette_pool: only {len(fpp)} entries "
            "(minimum 4 — at least 1 core and 1 accent, prefer ≥2 each)"
        )
    else:
        core_count = sum(1 for e in fpp if isinstance(e, dict) and e.get("role") == "core")
        accent_count = sum(1 for e in fpp if isinstance(e, dict) and e.get("role") == "accent")
        if core_count < 1 or accent_count < 1:
            report.error(
                f"fallback_palette_pool: needs ≥1 core and ≥1 accent "
                f"(got {core_count} core, {accent_count} accent)"
            )
        seen_names = set()
        for i, entry in enumerate(fpp):
            if not isinstance(entry, dict):
                report.error(f"fallback_palette_pool[{i}]: entry must be an object")
                continue
            missing_keys = [k for k in ("name", "hex", "role") if k not in entry]
            if missing_keys:
                report.error(
                    f"fallback_palette_pool[{i}]: missing required keys {missing_keys}"
                )
                continue
            name = entry.get("name", "")
            if name in seen_names:
                report.error(f"fallback_palette_pool[{i}]: duplicate name '{name}'")
            seen_names.add(name)
            if entry.get("role") not in ("core", "accent"):
                report.error(
                    f"fallback_palette_pool[{i}]: role must be 'core' or 'accent', "
                    f"got '{entry.get('role')}'"
                )
            hex_val = entry.get("hex", "")
            if not (isinstance(hex_val, str) and HEX_PATTERN.match(hex_val)):
                report.error(
                    f"fallback_palette_pool[{i}]: hex must be '#RRGGBB', got '{hex_val}'"
                )

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

    # ─── Part 6A: Astrological Axiom Checks ───
    validate_astrological_axioms(ps, report)

    # ─── SG-2 Phase 2d: formula_vocabulary (optional, but validated if present) ───
    validate_formula_vocabulary(dataset.get("formula_vocabulary"), report)

    return report.print_report()


SIGNS_LOWER = [
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
]
VALID_REGISTERS = {"quietLuxury", "boldExpression", "versatileAdaptive"}


def validate_formula_vocabulary(fv, report: "ValidationReport"):
    """SG-2 Phase 2d: 12 Venus rows (structure+accent, optional register/water
    variants) and 12 Moon rows (flow). Frozen mirror of the Swift enum."""
    if fv is None:
        report.warn("formula_vocabulary: absent (SG-2 ships it; freeze requires it)")
        return
    if not isinstance(fv, dict) or "venus_sign" not in fv or "moon_sign" not in fv:
        report.error("formula_vocabulary: must have 'venus_sign' and 'moon_sign'")
        return
    venus, moon = fv["venus_sign"], fv["moon_sign"]
    for sign in SIGNS_LOWER:
        if sign not in venus:
            report.error(f"formula_vocabulary.venus_sign: missing '{sign}'")
        else:
            row = venus[sign]
            if not isinstance(row.get("structure"), str) or not row.get("structure"):
                report.error(f"formula_vocabulary.venus_sign['{sign}']: missing 'structure'")
            if not isinstance(row.get("accent"), str) or not row.get("accent"):
                report.error(f"formula_vocabulary.venus_sign['{sign}']: missing 'accent'")
            sbr = row.get("structureByRegister")
            if sbr is not None:
                for reg in sbr:
                    if reg not in VALID_REGISTERS:
                        report.error(f"formula_vocabulary.venus_sign['{sign}']: invalid register '{reg}'")
        if sign not in moon:
            report.error(f"formula_vocabulary.moon_sign: missing '{sign}'")
        elif not isinstance(moon[sign].get("flow"), str) or not moon[sign].get("flow"):
            report.error(f"formula_vocabulary.moon_sign['{sign}']: missing 'flow'")
    report.log(f"formula_vocabulary: {len(venus)} Venus rows, {len(moon)} Moon rows")


# ─────────────────────────────────────────────────────────────────────────────
# Part 6A: Astrological Axiom Validation
# ─────────────────────────────────────────────────────────────────────────────

FIRE_SIGNS = ["aries", "leo", "sagittarius"]
EARTH_SIGNS = ["taurus", "virgo", "capricorn"]
AIR_SIGNS = ["gemini", "libra", "aquarius"]
WATER_SIGNS = ["cancer", "scorpio", "pisces"]

WARM_KEYWORDS = [
    "warm", "bold", "fiery", "red", "orange", "gold", "crimson", "coral",
    "amber", "saffron", "scarlet", "rust", "copper", "bronze", "sienna",
    "energetic", "dynamic", "dramatic", "statement", "vivid",
]
COOL_KEYWORDS = [
    "cool", "muted", "soft", "blue", "silver", "grey", "gray", "lavender",
    "mint", "teal", "aqua", "ice", "pearl", "pale", "dusty", "quiet",
    "subtle", "subdued", "understated",
]
SOFT_TEXTURE_KEYWORDS = [
    "soft", "flowing", "draped", "fluid", "silk", "chiffon", "jersey",
    "cashmere", "satin", "velvet", "gentle", "delicate",
]
STRUCTURE_KEYWORDS = [
    "structure", "structured", "tailored", "sharp", "angular", "architectural",
    "rigid", "crisp", "fitted", "restrained", "disciplined",
]


def _entry_has_keyword(entry: dict, paths: list[tuple[str, ...]], keywords: list[str]) -> bool:
    """Check if any of the given keywords appear in the entry at the given paths."""
    for field_path in paths:
        obj = entry
        for key in field_path:
            if isinstance(obj, dict):
                obj = obj.get(key, None)
            else:
                obj = None
                break
        if obj is None:
            continue
        items = obj if isinstance(obj, list) else [obj]
        for item in items:
            text = item.get("name", "").lower() if isinstance(item, dict) else str(item).lower()
            for kw in keywords:
                if kw in text:
                    return True
    return False


def _code_field_overlap(entry: dict) -> list[str]:
    """Return any keywords that appear in both code_leaninto and code_avoid."""
    lean = {k.lower().strip() for k in entry.get("code_leaninto", [])}
    avoid = {k.lower().strip() for k in entry.get("code_avoid", [])}
    return sorted(lean & avoid)


def validate_astrological_axioms(ps: dict, report: ValidationReport):
    """Part 6A: Cross-reference dataset entries against astrological axioms."""
    report.log("Part 6A: Running astrological axiom checks")

    colour_paths = [("colours", "primary"), ("colours", "accent")]
    silhouette_path = [("silhouette_keywords",)]
    texture_paths = [("textures", "good")]

    # Axiom 1: Venus in fire sign → warm/bold style keywords (not cool/muted)
    for sign in FIRE_SIGNS:
        key = f"venus_{sign}"
        if key not in ps:
            continue
        entry = ps[key]
        has_warm = _entry_has_keyword(entry, colour_paths + silhouette_path, WARM_KEYWORDS)
        has_cool_only = (
            not has_warm
            and _entry_has_keyword(entry, colour_paths + silhouette_path, COOL_KEYWORDS)
        )
        if has_warm:
            report.log(f"Axiom 1 PASS: {key} has warm/bold keywords")
        elif has_cool_only:
            report.warn(f"Axiom 1 WARN: {key} has only cool keywords — Venus in fire should trend warm")
        else:
            report.warn(f"Axiom 1 WARN: {key} — no clear warm or cool keywords found")

    # Axiom 2: Moon in water sign → soft textures and flowing silhouettes
    for sign in WATER_SIGNS:
        key = f"moon_{sign}"
        if key not in ps:
            continue
        entry = ps[key]
        has_soft = _entry_has_keyword(entry, texture_paths + silhouette_path, SOFT_TEXTURE_KEYWORDS)
        if has_soft:
            report.log(f"Axiom 2 PASS: {key} has soft/flowing texture keywords")
        else:
            report.warn(f"Axiom 2 WARN: {key} — Moon in water should emphasize soft textures")

    # Axiom 3: Saturn aspects should add structure/restraint, not drama/excess
    for sign in SIGNS:
        key = f"saturn_{sign}"
        if key not in ps:
            continue
        entry = ps[key]
        has_structure = _entry_has_keyword(entry, silhouette_path + texture_paths, STRUCTURE_KEYWORDS)
        if has_structure:
            report.log(f"Axiom 3 PASS: {key} has structure/restraint keywords")
        else:
            report.warn(f"Axiom 3 WARN: {key} — Saturn should emphasize structure/restraint")

    # Axiom 4: code_leaninto vs code_avoid — no keyword should appear in both
    overlap_count = 0
    for key, entry in ps.items():
        overlap = _code_field_overlap(entry)
        if overlap:
            overlap_count += 1
            report.error(
                f"Axiom 4 FAIL: {key} has keywords in both code_leaninto and code_avoid: {overlap}"
            )
    if overlap_count == 0:
        report.log("Axiom 4 PASS: no keywords appear in both code_leaninto and code_avoid")

    # Axiom 6: Code bullets must flow from section titles (Lean Into / Avoid / Consider)
    sys.path.insert(0, str(REPO_ROOT / "tools"))
    from code_header_flow_rules import header_flow_violation, section_kind_from_item

    header_flow_failures = 0
    for section_name, entries in (
        ("planet_sign", ps.items()),
        ("house_placements", dataset.get("house_placements", {}).items()),
    ):
        for key, entry in entries:
            if not isinstance(entry, dict):
                continue
            for field in ("code_leaninto", "code_avoid", "code_consider", "lean_into_bias", "code_consider_bias"):
                for i, text in enumerate(entry.get(field, []) or []):
                    kind = section_kind_from_item(field, "")
                    if kind and header_flow_violation(str(text), kind):
                        header_flow_failures += 1
                        report.error(
                            f"Axiom 6 FAIL: {section_name}.{key}.{field}[{i}]: "
                            f"{header_flow_violation(str(text), kind)} — \"{str(text)[:60]}…\""
                        )
            for i, text in enumerate(entry.get("opposites", {}).get("mood", []) or []):
                if header_flow_violation(str(text), "avoid"):
                    header_flow_failures += 1
                    report.error(
                        f"Axiom 6 FAIL: {section_name}.{key}.opposites.mood[{i}]: "
                        f"{header_flow_violation(str(text), 'avoid')} — \"{str(text)[:60]}…\""
                    )
    for key, entry in dataset.get("aspects", {}).items():
        if not isinstance(entry, dict):
            continue
        for field in ("code_addition_leaninto", "code_addition_avoid"):
            text = entry.get(field, "")
            if text:
                kind = section_kind_from_item(field, "")
                if kind and header_flow_violation(str(text), kind):
                    header_flow_failures += 1
                    report.error(
                        f"Axiom 6 FAIL: aspects.{key}.{field}: "
                        f"{header_flow_violation(str(text), kind)} — \"{str(text)[:60]}…\""
                    )
    if header_flow_failures == 0:
        report.log("Axiom 6 PASS: all Code bullets flow from section titles")

    # Axiom 5: Venus in earth sign → grounded/textured style (not airy/ethereal)
    grounded_keywords = [
        "grounded", "textured", "substantial", "structured", "earthy",
        "organic", "natural", "leather", "denim", "suede", "wool",
    ]
    for sign in EARTH_SIGNS:
        key = f"venus_{sign}"
        if key not in ps:
            continue
        entry = ps[key]
        has_grounded = _entry_has_keyword(entry, texture_paths + silhouette_path, grounded_keywords)
        if has_grounded:
            report.log(f"Axiom 5 PASS: {key} has grounded/textured keywords")
        else:
            report.warn(f"Axiom 5 WARN: {key} — Venus in earth should trend grounded/textured")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate astrological_style_dataset.json")
    parser.add_argument(
        "dataset_path",
        nargs="?",
        default=str(REPO_ROOT / "data" / "style_guide" / "astrological_style_dataset.json"),
        help="Path to dataset JSON file (relative paths resolve from repo root)",
    )
    parser.add_argument(
        "--strict-house-schema",
        action="store_true",
        help="Enforce expanded house placement fields as required",
    )
    args = parser.parse_args()

    dataset = load_dataset(resolve_repo_path(args.dataset_path))
    success = validate(dataset, strict_house_schema=args.strict_house_schema)
    sys.exit(0 if success else 1)
