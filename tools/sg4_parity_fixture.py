#!/usr/bin/env python3
"""
Cosmic Fit — SG-4 Python↔Swift validator parity fixture generator.

Writes data/style_guide/sg4_parity_fixture.json: a corpus of gate cases with
the Python write gate's verdicts baked in, plus golden-cluster expectations
(omit categories, pass-over lists) the Swift composed-contract tests consume.

The Swift StyleGuideCoherenceValidator runs every case and must reproduce the
error/warning code sets exactly (SG4ValidatorParityTests). Regenerate this
fixture whenever style_guide_rules.json or sg_validation.py changes:

    .venv/bin/python tools/sg4_parity_fixture.py

The generator is deterministic (no timestamps, sorted keys, fixed sampling),
so a regenerated fixture diffs cleanly.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sg_validation as V
import sg_generate as G
from sg_profile import coarse_profile_from_key
from sg_accessory_plan import accessory_plan

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_PATH = REPO_ROOT / "data" / "style_guide" / "sg4_parity_fixture.json"
CACHE_PATH = REPO_ROOT / "data" / "style_guide" / "blueprint_narrative_cache_sg4.json"
EXPECT_PATH = REPO_ROOT / "docs" / "style_guide" / "golden" / "profile_expectations.json"

# Every 29th cluster of the 576 → ~20 real clusters sampled into the corpus.
REAL_SAMPLE_STRIDE = 29
REAL_SAMPLE_SECTIONS = ["style_core", "palette_narrative", "hardware_metals", "accessory_1"]

SLATE_KEYWORDS = ["structure", "softness", "a touch of quiet depth", "quiet luxury"]


def error_code(msg: str) -> str:
    """Maps a gate error string to its taxonomy code (write_gate.errors)."""
    if msg.startswith("Group A section"):
        return "group_a_placeholder"
    if msg.startswith("Unknown placeholder"):
        return "unknown_placeholder"
    if msg.startswith("literal_name_leak"):
        return "literal_name_leak"
    return msg.split(":", 1)[0]


def warning_code(msg: str) -> str:
    return msg.split(":", 1)[0]


def length_blocked(text: str, section_key: str) -> bool:
    lb = V.load_rules()["write_gate"]["length_block"]
    limit = lb.get(section_key, lb["default"])
    return len(text.split()) > limit


def build_case(case_id: str, text: str, section_key: str,
               core_keywords: list[str] | None = None,
               existing_cluster_texts: list[str] | None = None,
               allowed_leak_phrases: list[str] | None = None) -> dict:
    kw = core_keywords if core_keywords is not None else SLATE_KEYWORDS
    result = V.validate_paragraph_gate(
        text, section_key, kw,
        existing_cluster_texts=existing_cluster_texts,
        allowed_leak_phrases=allowed_leak_phrases)
    return {
        "id": case_id,
        "section_key": section_key,
        "core_keywords": kw,
        "existing_cluster_texts": existing_cluster_texts or [],
        "allowed_leak_phrases": allowed_leak_phrases or [],
        "text": text,
        "expected": {
            "passed": result["passed"],
            "error_codes": sorted(error_code(e) for e in result["errors"]),
            "warning_codes": sorted(warning_code(w) for w in result["warnings"]),
            "too_long_block": length_blocked(text, section_key),
        },
    }


def crafted_cases() -> list[dict]:
    KW = SLATE_KEYWORDS
    clean_a = ("Build your wardrobe on structure and softness. Pick up a wool "
               "coat and feel its weight before you buy. A camel coat and a "
               "cream knit carry the look.")
    cases = [
        # ── hygiene: dashes ──────────────────────────────────────────
        build_case("clean_group_a", clean_a, "style_core"),
        build_case("dash_em", "Structure leads here — trust the cut of a wool coat.", "style_core"),
        build_case("dash_en", "Structure leads – a wool coat over a cream knit.", "style_core"),
        build_case("dash_double_hyphen", "Structure leads -- a wool coat over a cream knit.", "style_core"),
        build_case("dash_markdown_rule_exempt", "Structure and softness anchor the look.\n---\nA wool coat carries the depth.", "style_core"),
        # ── banned tics ──────────────────────────────────────────────
        build_case("tic_walk_into", "You walk into a room and your structure and softness in a wool coat register at once.", "style_core"),
        build_case("tic_folklore", "Your look stays unbothered; structure and softness in a wool coat hold it steady.", "style_core"),
        # ── american spellings (incl. SG-4 extensions) ───────────────
        build_case("us_matte", "A matte buckle secures the structure and softness of a leather belt.", "style_core"),
        build_case("us_finalizing_extended", "Before finalizing the look, weigh the structure and softness of the wool coat.", "style_core"),
        build_case("us_rigor_extended", "Apply rigor to the structure and softness of every wool seam.", "style_core"),
        build_case("us_rigorous_allowed", "Apply a rigorous check to the structure and softness of every wool seam.", "style_core"),
        build_case("us_curb_chain_allowed", "A heavy curb chain adds structure and softness against a wool collar.", "style_core"),
        build_case("us_high_curb_blocked", "Step off the high curb; the structure and softness of the wool coat still hold.", "style_core"),
        build_case("us_track_pants_allowed", "Crisp nylon track pants keep the structure and softness in motion.", "style_core"),
        build_case("us_mold_extended", "Never let mold near the structure and softness of stored wool.", "style_core"),
        # ── stamped phrases (incl. SG-4 contraction/pattern closure) ─
        build_case("stamp_literal", "Trust this physical instinct as your ultimate compass. Structure and softness in a wool coat decide the rest.", "style_core"),
        build_case("stamp_contraction_expanded", "Looks lie. Weight does not. Structure and softness in a wool coat decide.", "style_core"),
        build_case("stamp_pattern_and_form", "Looks lie. Weight and glitter do not. Structure and softness in a wool coat decide.", "style_core"),
        build_case("stamp_near_miss_passes", "Showroom lighting flatters a wool coat. The drag of structure and softness in your palm does not.", "style_core"),
        # ── core formula ─────────────────────────────────────────────
        build_case("formula_absent_daily", "For errands, wear leather trainers and a fine merino knit that moves with you.", "occasions_daily"),
        build_case("formula_present_daily", "Errands keep the softness; leather trainers and a merino knit carry it.", "occasions_daily"),
        build_case("formula_not_required_intimate", "For dinner, a velvet blazer over a silk blouse works without effort.", "occasions_intimate"),
        # ── placeholders ─────────────────────────────────────────────
        build_case("group_a_placeholder", "Your palette leans on {core_colour_1} with structure and softness throughout, in wool and leather.", "style_core"),
        build_case("unknown_placeholder", "Anchor on {mystery_token} with {core_colour_1}, {core_colour_2} and {accent_colour_1} in wool.", "palette_narrative"),
        build_case("palette_missing_required", "Your {core_colour_1} base sets the tone; keep leather and wool close.", "palette_narrative"),
        build_case("palette_required_met", "Anchor on {core_colour_1} and {core_colour_2}; let {accent_colour_1} cut through wool and leather.", "palette_narrative"),
        build_case("hardware_stones_missing_required", "Choose stones with density and weight; wool and leather nearby stay matt.", "hardware_stones"),
        build_case("hardware_stones_required_met", "Choose {stone_1} for density; wool and leather nearby stay matt.", "hardware_stones"),
        build_case("textures_good_missing_required", "Rely on {texture_good_1} for knitwear; leather handles the rest.", "textures_good"),
        build_case("textures_good_required_met", "Rely on {texture_good_1} for knitwear and {texture_good_2} for coats; leather handles the rest.", "textures_good"),
        build_case("hardware_metals_split_met", "Wear {personal_metal_1} at the collar and {structural_metal_1} at the buckle; both stay matt.", "hardware_metals"),
        build_case("pattern_required_met", "Let {recommended_pattern_1} live on tailored wool; keep fluid silk plain.", "pattern_narrative"),
        build_case("tip_exempt_from_required", "Pick it up first. If the clasp feels hollow, leave it on the shelf.", "hardware_tip"),
        # ── season words ─────────────────────────────────────────────
        build_case("season_bare", "Your winter coats want {core_colour_1}, {core_colour_2} and {accent_colour_1} for depth in wool.", "palette_narrative"),
        build_case("season_analysis_label", "This is a deep autumn story: {core_colour_1}, {core_colour_2} and {accent_colour_1} in wool.", "palette_narrative"),
        build_case("season_ok_outside_palette", "A winter coat in heavy wool holds structure and softness close.", "style_core"),
        # ── literal leaks ────────────────────────────────────────────
        build_case("leak_colour_in_palette", "Camel anchors everything; add {core_colour_1}, {core_colour_2} and {accent_colour_1} in wool.", "palette_narrative"),
        build_case("leak_allowed_passover", "Pass over icy grey. Anchor on {core_colour_1} and {core_colour_2}; {accent_colour_1} cuts through wool.", "palette_narrative", allowed_leak_phrases=["icy grey"]),
        build_case("leak_fibre_in_textures", "Cashmere is the point: rely on {texture_good_1} and {texture_good_2} for coats.", "textures_good"),
        build_case("leak_not_gated_group_a", "A camel coat and toffee scarf carry structure and softness all day.", "style_core"),
        # ── warnings ─────────────────────────────────────────────────
        build_case("warn_filler_over_cap", "An effortless, timeless, luxurious, premium wool coat carries structure and softness.", "style_core"),
        build_case("warn_concrete_floor", "Structure and softness matter more than anything else you value.", "style_core"),
        build_case("warn_phrase_repetition",
                   "Look for structure and softness. Look for weight in wool. Look for a clean hem. Look for depth in leather. Look for balance.",
                   "style_core",
                   existing_cluster_texts=["Look for a spine of wool. Look for a soft collar."]),
        # ── length block ─────────────────────────────────────────────
        build_case("too_long_default", " ".join(["Structure and softness hold the wool coat close."] * 26), "occasions_work"),
        build_case("too_long_style_core_under", " ".join(["Structure and softness hold the wool coat close."] * 30), "style_core"),
        build_case("too_long_style_core_over", " ".join(["Structure and softness hold the wool coat close."] * 36), "style_core"),
    ]
    return cases


def real_cases() -> list[dict]:
    cache = json.loads(CACHE_PATH.read_text())
    keys = sorted(k for k in cache if k != "schema_version" and isinstance(cache[k], dict))
    sampled = keys[::REAL_SAMPLE_STRIDE]
    cases = []
    for k in sampled:
        prof = coarse_profile_from_key(k)
        for sk in REAL_SAMPLE_SECTIONS:
            sec = cache[k].get(sk)
            if not isinstance(sec, dict) or not sec.get("text"):
                continue
            allowed = G.pass_over_for_palette(prof) if sk == "palette_narrative" else []
            cases.append(build_case(
                f"cache::{k}::{sk}", sec["text"], sk,
                core_keywords=prof.core_keywords,
                allowed_leak_phrases=allowed))
    return cases


def golden_expectations() -> dict:
    exp = json.loads(EXPECT_PATH.read_text())
    out = {}
    for archetype, e in sorted(exp.items()):
        if archetype == "_meta":
            continue
        prof = coarse_profile_from_key(e["cluster_key"])
        plan = accessory_plan(prof.aesthetic_register, prof.orientation, prof.finish_lane)
        out[archetype] = {
            "cluster_key": e["cluster_key"],
            "core_formula": e["core_formula"],
            "temperature": e["temperature"],
            "register": e["register"],
            "metal_strategy": e["metal_strategy"],
            "finish_lane": e["finish_lane"],
            "orientation": e["orientation"],
            "core_keywords": prof.core_keywords,
            "omit_categories": sorted(o["category"] for o in plan["omit"]),
            "pass_over_phrases": G.pass_over_for_palette(prof),
        }
    return out


def main() -> None:
    fixture = {
        "_meta": {
            "description": ("SG-4 Python<->Swift validator parity fixture. Generated by "
                            "tools/sg4_parity_fixture.py from sg_validation.py verdicts; "
                            "consumed by SG4ValidatorParityTests.swift + SG4ComposedContractTests.swift. "
                            "Regenerate after any change to style_guide_rules.json or sg_validation.py."),
            "schema_version": 1,
        },
        "allowed_placeholders": sorted(V.ALLOWED_PLACEHOLDERS),
        "group_a_sections": sorted(V.GROUP_A_SECTIONS),
        "group_b_sections": sorted(V.GROUP_B_SECTIONS),
        "gate_cases": crafted_cases() + real_cases(),
        "golden": golden_expectations(),
    }
    n_block = sum(1 for c in fixture["gate_cases"] if not c["expected"]["passed"])
    OUT_PATH.write_text(json.dumps(fixture, indent=2, ensure_ascii=False, sort_keys=False) + "\n")
    print(f"Wrote {OUT_PATH.relative_to(REPO_ROOT)}: "
          f"{len(fixture['gate_cases'])} gate cases ({n_block} blocking), "
          f"{len(fixture['golden'])} golden expectations.")


if __name__ == "__main__":
    main()
