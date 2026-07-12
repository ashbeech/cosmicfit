#!/usr/bin/env python3
"""SG-2 Phase 2d: emit the `formula_vocabulary` block into the dataset.

The canonical source is the Swift `FormulaVocabulary` enum
(`ChartAestheticProfile.swift`); this script mirrors those 12 Venus rows and
12 Moon rows into `astrological_style_dataset.json` so SG-3's Python parity
computation reads the SAME frozen tables (no Swift/Python drift). A Swift
parity test (`SG2FormulaVocabularyTests`) asserts the JSON composes
identically to the Swift enum for all 576 coarse keys.

Venus row shape mirrors `FormulaVocabulary.VenusEntry`:
  { "structure": <default>, "structureByRegister"?: {register: str},
    "structureWaterVariant"?: str, "accent": <default> }
Moon row shape: { "flow": <default> }

Run: python3 tools/build_formula_vocabulary.py
"""
import json
from pathlib import Path

DATASET = Path(__file__).resolve().parent.parent / "data/style_guide/astrological_style_dataset.json"

# Golden-anchored vocabulary (lowercased sign keys). Anchors noted per row.
VENUS = {
    "aries":       {"structure": "clean impact",        "accent": "one hot accent"},                 # Ember
    "taurus":      {"structure": "structure",           "structureWaterVariant": "soft structure",
                    "accent": "a touch of quiet depth"},                                              # Slate, Ripple
    "gemini":      {"structure": "crisp separation",    "accent": "one clever contrast"},            # Zephyr
    "cancer":      {"structure": "soft shelter",        "accent": "one sentimental keepsake"},       # Cove, Wren
    "leo":         {"structure": "dark drama",
                    "structureByRegister": {"quietLuxury": "quiet grandeur"},
                    "accent": "one molten flash"},                                                    # Cinder, Hearth
    "virgo":       {"structure": "precise fit",         "accent": "one meticulous detail"},          # Flint
    "libra":       {"structure": "balanced proportions","accent": "one refined touch"},              # Breeze
    "scorpio":     {"structure": "close drape",         "accent": "one warm point of light"},        # Tide
    "sagittarius": {"structure": "expansive colour",    "accent": "one theatrical finish"},          # Blaze
    "capricorn":   {"structure": "enduring structure",  "accent": "one living texture"},             # Moss
    "aquarius":    {"structure": "clean geometry",      "accent": "one polished signal"},            # Frost
    "pisces":      {"structure": "weightless layers",   "accent": "one pearl of light"},             # Mist, Loom
}

MOON = {
    "aries":       {"flow": "sharp edges"},       # Cinder
    "taurus":      {"flow": "sensory comfort"},   # Moss
    "gemini":      {"flow": "light movement"},    # Breeze, Wren
    "cancer":      {"flow": "hidden depth"},      # Tide
    "leo":         {"flow": "athletic space"},    # Blaze
    "virgo":       {"flow": "honest fabric"},     # Flint, Loom
    "libra":       {"flow": "cool composure"},    # Frost
    "scorpio":     {"flow": "quiet undercurrent"},# Cove
    "sagittarius": {"flow": "fast movement"},     # Ember
    "capricorn":   {"flow": "softness"},          # Slate, Hearth
    "aquarius":    {"flow": "mobile layers"},     # Zephyr
    "pisces":      {"flow": "blurred edges"},     # Mist, Ripple
}


def main():
    data = json.loads(DATASET.read_text())
    data["formula_vocabulary"] = {"venus_sign": VENUS, "moon_sign": MOON}
    DATASET.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    assert len(VENUS) == 12 and len(MOON) == 12
    print(f"Wrote formula_vocabulary: {len(VENUS)} Venus rows, {len(MOON)} Moon rows -> {DATASET}")


if __name__ == "__main__":
    main()
