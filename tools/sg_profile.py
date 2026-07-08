#!/usr/bin/env python3
"""
Cosmic Fit — Python coarse ChartAestheticProfile (SG-3, Phase 3a).

A faithful, language-neutral mirror of the Swift
`ChartAestheticProfile.coarseProfile(...)` (Cosmic
Fit/InterpretationEngine/ChartAestheticProfile.swift), implemented against the
spec in docs/style_guide/decisions/profile_derivation.md.

Everything that can appear inside cached narrative prose — register,
temperature, finish lane, metal strategy, coreFormula, core keywords, excluded
keywords — is a PURE function of the three coarse cache-key inputs
(venusSign, moonSign, dominantElement). This module derives exactly those.

`coreFormula` is composed from the FROZEN dataset table
`astrological_style_dataset.json -> formula_vocabulary` (the mirror of the
Swift `FormulaVocabulary` enum), so the Python computation cannot drift from
the shipped engine.

Fine-only signals (Moon house, element margins, stelliums, overlay policy) are
deliberately NOT implemented here: the coarse profile is written into 16
paragraphs shared by every user in a bucket, so nothing outside the key may
influence it (key-purity rule).

Parity: `python3 tools/sg_profile.py --parity` asserts the coarse output against
docs/style_guide/golden/profile_expectations.json for every golden chart.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DATASET = REPO_ROOT / "data" / "style_guide" / "astrological_style_dataset.json"
PROFILE_EXPECTATIONS = REPO_ROOT / "docs" / "style_guide" / "golden" / "profile_expectations.json"

ZODIAC_SIGNS = [
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
]
ELEMENTS = ["fire", "earth", "air", "water"]


# ─── Register (three-vote majority) ────────────────────────────────────

_QUIET_SIGNS = {"taurus", "cancer", "scorpio", "capricorn", "pisces"}
_BOLD_SIGNS = {"aries", "leo", "sagittarius"}
# else (gemini, virgo, libra, aquarius) -> versatileAdaptive


def register_character_of_sign(sign: str) -> str:
    s = sign.lower()
    if s in _QUIET_SIGNS:
        return "quietLuxury"
    if s in _BOLD_SIGNS:
        return "boldExpression"
    return "versatileAdaptive"


def register_character_of_element(element: str) -> str:
    e = element.lower()
    if e == "fire":
        return "boldExpression"
    if e in ("earth", "water"):
        return "quietLuxury"
    return "versatileAdaptive"  # air


def register_vote(venus: str, moon: str, element: str) -> tuple[str, bool]:
    """Returns (register, three_way_tie). Any character with >=2 votes wins;
    a three-way split resolves to versatileAdaptive and marks a tie-break."""
    votes = [
        register_character_of_element(element),
        register_character_of_sign(venus),
        register_character_of_sign(moon),
    ]
    counts: dict[str, int] = {}
    for v in votes:
        counts[v] = counts.get(v, 0) + 1
    for reg, count in counts.items():
        if count >= 2:
            return reg, False
    return "versatileAdaptive", True


def register_keyword(register: str) -> str:
    return {
        "quietLuxury": "quiet luxury",
        "boldExpression": "bold expression",
        "versatileAdaptive": "versatile",
    }[register]


# ─── Temperature (Venus element with sign nuance) ──────────────────────

def temperature_for_venus(venus: str) -> str:
    v = venus.lower()
    if v == "scorpio":
        return "warm"  # warm-deep despite water (Tide)
    if v == "virgo":
        return "neutral"  # the genuine neutral lane (Flint)
    if v in ("aries", "leo", "sagittarius", "taurus", "capricorn"):
        return "warm"
    return "cool"  # gemini, libra, aquarius, cancer, pisces


# ─── Finish lane (register base + Venus-sign lean, clamped) ────────────

def finish_lane(register: str, venus: str) -> str:
    base = {"quietLuxury": 0, "versatileAdaptive": 1, "boldExpression": 2}[register]
    v = venus.lower()
    if v in ("taurus", "cancer", "virgo", "scorpio", "capricorn"):
        lean = -1
    elif v in ("aries", "leo", "aquarius"):
        lean = +1
    else:  # gemini, libra, sagittarius, pisces
        lean = 0
    scaled = max(0, min(2, base + lean))
    return {0: "muted", 1: "mixed", 2: "polished"}[scaled]


# ─── Metal strategy (temperature lane + register + sign nuance) ────────

_COOL_STRUCTURAL_MOONS = {"capricorn", "aquarius", "aries", "virgo", "gemini", "libra"}


def metal_strategy(temperature: str, register: str, finish: str, venus: str, moon: str) -> str:
    # 1. versatile + mixed finish -> free (Zephyr, Breeze, Loom)
    if register == "versatileAdaptive" and finish == "mixed":
        return "mixedFree"
    # 2. cool / neutral lane -> cool metal (Cove, Mist, Frost, Flint, Wren)
    if temperature in ("cool", "neutral"):
        return "coolDominant"
    # 3. warm lane, Sagittarius Venus -> eclectic statement mixing (Blaze)
    if venus.lower() == "sagittarius":
        return "mixedFree"
    # 4. warm Venus + cool/structural Moon + single-minded finish (Slate, Cinder)
    if moon.lower() in _COOL_STRUCTURAL_MOONS and finish != "mixed":
        return "dualRegister"
    return "warmDominant"  # Ember, Moss, Tide, Ripple, Hearth


# ─── Orientation (additive score) ─────────────────────────────────────

def venus_orientation_lean(sign: str) -> int:
    s = sign.lower()
    if s in ("scorpio", "aries", "cancer"):
        return -2
    if s in ("taurus", "virgo", "pisces", "aquarius"):
        return -1
    if s == "capricorn":
        return 0
    if s == "sagittarius":
        return +2
    return +1  # gemini, leo, libra


def moon_orientation_lean(sign: str) -> int:
    s = sign.lower()
    if s in ("scorpio", "capricorn", "aries"):
        return -2
    if s in ("taurus", "cancer", "virgo", "pisces"):
        return -1
    return +1  # gemini, leo, libra, sagittarius, aquarius


def element_orientation_lean(element: str) -> int:
    e = element.lower()
    if e == "air":
        return +1
    if e in ("fire", "water"):
        return -1
    return 0  # earth


def orientation_lane(venus: str, moon: str, element: str) -> str:
    score = (
        venus_orientation_lean(venus)
        + moon_orientation_lean(moon)
        + element_orientation_lean(element)
    )
    if score >= 2:
        return "communityOriented"
    if score <= -2:
        return "selfContained"
    return "balanced"


# ─── Excluded aesthetic keywords ──────────────────────────────────────

def excluded_keywords(register: str, orientation: str) -> list[str]:
    if register == "quietLuxury":
        kw = ["bold", "global", "adventurous", "expansive", "loud"]
    elif register == "boldExpression":
        kw = ["muted", "understated"]
    else:  # versatileAdaptive
        kw = ["bold", "statement", "fierce", "never deviate"]
    if orientation == "selfContained":
        kw = kw + ["community", "belonging", "collective", "tribe"]
    return kw


# ─── Formula composition (from frozen dataset mirror) ─────────────────

_FORMULA_VOCAB_CACHE: dict | None = None


def _formula_vocab(dataset_path: Path = DEFAULT_DATASET) -> dict:
    global _FORMULA_VOCAB_CACHE
    if _FORMULA_VOCAB_CACHE is None:
        with open(dataset_path) as f:
            data = json.load(f)
        _FORMULA_VOCAB_CACHE = data["formula_vocabulary"]
    return _FORMULA_VOCAB_CACHE


def compose_formula(venus: str, moon: str, element: str, register: str,
                    dataset_path: Path = DEFAULT_DATASET) -> str:
    """Mirrors FormulaVocabularyData.compose (Swift). Sign keys lowercased."""
    fv = _formula_vocab(dataset_path)
    venus_row = fv["venus_sign"].get(venus.lower())
    moon_row = fv["moon_sign"].get(moon.lower())
    if venus_row is None or moon_row is None:
        # Cannot occur from the production key space.
        return "considered structure + ease of movement + one quiet signature"
    by_register = venus_row.get("structureByRegister") or {}
    if register in by_register:
        structure = by_register[register]
    elif element.lower() == "water" and venus_row.get("structureWaterVariant"):
        structure = venus_row["structureWaterVariant"]
    else:
        structure = venus_row["structure"]
    return f"{structure} + {moon_row['flow']} + {venus_row['accent']}"


# ─── Coarse profile assembly ──────────────────────────────────────────

class CoarseProfile:
    __slots__ = (
        "venus_sign", "moon_sign", "dominant_element",
        "orientation", "aesthetic_register", "metal_strategy", "finish_lane",
        "temperature", "core_formula", "core_keywords", "excluded_keywords",
        "confidence", "register_vote_three_way_tie",
    )

    def __init__(self, **kw):
        for k, v in kw.items():
            setattr(self, k, v)

    def as_dict(self) -> dict:
        return {k: getattr(self, k) for k in self.__slots__}


def coarse_profile(venus: str, moon: str, element: str,
                   dataset_path: Path = DEFAULT_DATASET) -> CoarseProfile:
    register, three_way_tie = register_vote(venus, moon, element)
    temperature = temperature_for_venus(venus)
    finish = finish_lane(register, venus)
    metals = metal_strategy(temperature, register, finish, venus, moon)
    orientation = orientation_lane(venus, moon, element)
    formula = compose_formula(venus, moon, element, register, dataset_path)
    keywords = formula.split(" + ") + [register_keyword(register)]
    # Coarse confidence knows nothing about element margins; only a three-way
    # register split marks it low.
    confidence = "low" if three_way_tie else "high"
    return CoarseProfile(
        venus_sign=venus.capitalize(),
        moon_sign=moon.capitalize(),
        dominant_element=element.lower(),
        orientation=orientation,
        aesthetic_register=register,
        metal_strategy=metals,
        finish_lane=finish,
        temperature=temperature,
        core_formula=formula,
        core_keywords=keywords,
        excluded_keywords=excluded_keywords(register, orientation),
        confidence=confidence,
        register_vote_three_way_tie=three_way_tie,
    )


def parse_cluster_key(key: str) -> tuple[str, str, str] | None:
    """venus_<sign>__moon_<sign>__<element>_dominant -> (venus, moon, element)."""
    parts = key.split("__")
    if len(parts) != 3:
        return None
    if not (parts[0].startswith("venus_") and parts[1].startswith("moon_")
            and parts[2].endswith("_dominant")):
        return None
    venus = parts[0][len("venus_"):]
    moon = parts[1][len("moon_"):]
    element = parts[2][: -len("_dominant")]
    return venus, moon, element


def coarse_profile_from_key(key: str,
                            dataset_path: Path = DEFAULT_DATASET) -> CoarseProfile | None:
    parsed = parse_cluster_key(key)
    if parsed is None:
        return None
    venus, moon, element = parsed
    return coarse_profile(venus, moon, element, dataset_path)


# ─── Parity test against the golden vectors ───────────────────────────

# Coarse-derivable, key-pure dimensions we assert. confidence and
# overlay_policy are FINE-profile expectations (element margins, stelliums)
# and are intentionally NOT asserted here (see profile_expectations.json
# _meta.notes). orientation IS asserted: the fine Moon-house adjustment can
# never flip a clear pole (|adj| = 1 < threshold 2) and does not flip any
# golden chart's recorded lane.
_PARITY_FIELDS = [
    ("orientation", "orientation"),
    ("aesthetic_register", "register"),
    ("metal_strategy", "metal_strategy"),
    ("finish_lane", "finish_lane"),
    ("temperature", "temperature"),
    ("core_formula", "core_formula"),
    ("excluded_keywords", "excluded_keywords"),
]


def run_parity() -> int:
    with open(PROFILE_EXPECTATIONS) as f:
        vectors = json.load(f)

    failures: list[str] = []
    checked = 0
    for archetype, expected in vectors.items():
        if archetype == "_meta":
            continue
        key = expected["cluster_key"]
        prof = coarse_profile_from_key(key)
        if prof is None:
            failures.append(f"{archetype}: could not parse cluster_key {key!r}")
            continue
        checked += 1
        got = prof.as_dict()
        for got_field, exp_field in _PARITY_FIELDS:
            exp_val = expected[exp_field]
            got_val = got[got_field]
            if isinstance(exp_val, list):
                if sorted(got_val) != sorted(exp_val):
                    failures.append(
                        f"{archetype}.{exp_field}: expected {exp_val}, got {got_val}"
                    )
            elif got_val != exp_val:
                failures.append(
                    f"{archetype}.{exp_field}: expected {exp_val!r}, got {got_val!r}"
                )
        # Tie-break confidence is the one coarse-detectable confidence signal.
        if expected.get("confidence") == "low" and expected.get("_tie_break_only"):
            if prof.confidence != "low":
                failures.append(f"{archetype}.confidence(tie): expected low")

    print(f"Parity: checked {checked} golden charts across {len(_PARITY_FIELDS)} coarse dimensions.")
    if failures:
        print(f"\nFAIL — {len(failures)} mismatch(es):")
        for line in failures:
            print(f"  ✗ {line}")
        return 1
    print("PASS — every golden chart's coarse profile matches profile_expectations.json.")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="SG-3 coarse ChartAestheticProfile")
    parser.add_argument("--parity", action="store_true",
                        help="Run the cross-language parity test vs profile_expectations.json")
    parser.add_argument("--key", help="Print the coarse profile for one cluster key")
    args = parser.parse_args()

    if args.key:
        prof = coarse_profile_from_key(args.key)
        if prof is None:
            print(f"Invalid cluster key: {args.key}")
            sys.exit(2)
        print(json.dumps(prof.as_dict(), indent=2, ensure_ascii=False))
        return

    if args.parity:
        sys.exit(run_parity())

    parser.print_help()


if __name__ == "__main__":
    main()
