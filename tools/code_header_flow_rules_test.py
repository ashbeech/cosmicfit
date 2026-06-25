#!/usr/bin/env python3
"""Unit tests for Code bullet section header flow rules."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from code_header_flow_rules import (  # noqa: E402
    auto_fix,
    header_flow_violation,
)


class HeaderFlowRulesTests(unittest.TestCase):
    def test_avoid_strips_redundant_verb(self):
        text = "Avoid harsh synthetic fabrics that trap heat and static."
        self.assertEqual(header_flow_violation(text, "avoid"), "avoid_redundant_verb")
        new, changed, status = auto_fix(text, "avoid")
        self.assertEqual(status, "fixed")
        self.assertTrue(changed)
        self.assertIsNone(header_flow_violation(new, "avoid"))
        self.assertTrue(new.startswith("Harsh synthetic"))

    def test_avoid_resist_to_noun_phrase(self):
        text = "Resist impulsive fast-fashion buys that lack tactile quality."
        new, changed, status = auto_fix(text, "avoid")
        self.assertEqual(status, "fixed")
        self.assertTrue(new.startswith("Impulsive fast-fashion"))

    def test_lean_into_imperative_to_gerund(self):
        text = "Build your wardrobe foundation on warm neutrals."
        self.assertIsNotNone(header_flow_violation(text, "lean_into"))
        new, changed, status = auto_fix(text, "lean_into")
        self.assertEqual(status, "fixed")
        self.assertTrue(new.startswith("Building your wardrobe"))

    def test_lean_into_already_gerund_ok(self):
        text = "Investing in fewer, better pieces that you will reach for every week."
        self.assertIsNone(header_flow_violation(text, "lean_into"))

    def test_consider_imperative_to_gerund(self):
        text = "Wear intriguing tactile textures and unexpected asymmetric shapes."
        new, changed, status = auto_fix(text, "consider")
        self.assertEqual(status, "fixed")
        self.assertTrue(new.startswith("Wearing intriguing"))

    def test_consider_noun_phrase_unchanged(self):
        text = "One statement piece rather than layered complexity."
        self.assertIsNone(header_flow_violation(text, "consider"))
        new, changed, status = auto_fix(text, "consider")
        self.assertEqual(status, "ok")
        self.assertFalse(changed)
        self.assertEqual(new, text)

    def test_consider_the_phrase_unchanged(self):
        text = "The three-year test before every purchase."
        self.assertIsNone(header_flow_violation(text, "consider"))


if __name__ == "__main__":
    unittest.main()
