#!/usr/bin/env python3
"""
Cosmic Fit — SG-0 Phase 0a evidence helper: check golden ideal guides against
the machine-checkable parts of docs/style_guide/style_standard.md.

This is NOT the SG-4 production validator (out of SG-0 scope). It is a
documentation QA aid that proves the rubric is achievable: every golden guide
must pass, or either the guide or the rubric is amended (golden guide wins on
matters of voice/content; the rubric wins on mechanical hygiene).

Checks per guide:
  1. All 8 numbered sections + closing italic line present.
  2. No em dashes, en dashes, or ' -- ' in prose (markdown '---' hr lines and
     the metadata HTML comment are exempt).
  3. Spelling 'matt' not 'matte'; no American spellings from the audit list.
  4. Banned tics absent (folklore floor + harvested list).
  5. coreFormula propagation: all three formula slots (leading articles
     stripped) appear in Blueprint, Occasions, Code, Accessory, and the
     closing line.
  6. Textures Good: exactly 7 bolded ranked fibres with use-case lines.
  7. Palette: >= 6 named foundation/colour terms (lexicon-based; approximate,
     verify failures by eye).
  8. >= 2 named metals in Hardware; >= 2 named stones (or explicit restraint
     framing).
  9. Accessory metadata plan lists >= 3 include categories.
 10. Word 'test' or 'trap' evidence in each section (heuristic for the
     >=1 named test/trap floor; manual reading confirms).

Non-circularity: Slate is still checked mechanically (hygiene applies to all
files), but its result is excluded from the pass/fail scoring of the standard
itself, per the non-circularity rule.

Usage: python3 tools/check_golden_guides.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GOLDEN_DIR = REPO_ROOT / "docs" / "style_guide" / "golden"

EM_DASH_RE = re.compile(r"[\u2014\u2013]")
DOUBLE_HYPHEN_RE = re.compile(r"(?<!-)--(?!-)")

BANNED_TICS = [
    # Folklore floor (master plan)
    "unbothered", "signs the cheques", "devastatingly chic", "command the room",
    "quiet expensive authority", "effortlessly elegant",
    # Harvested from the shipped 576-cluster cache (tools/harvest_narrative_tics.py)
    "walk into a room", "walks into a room", "when you walk into",
    "is an exercise in", "an exercise in",
    "at the intersection of", "there is a distinct",
    "satisfying snap", "the rich scent of", "talk with your hands",
    "a substantial watch", "your professional wardrobe",
    "your off duty wardrobe", "off duty dressing", "your off-duty wardrobe",
    "off-duty dressing", "your daily rotation",
    "an immediate sense of", "matters just as much",
    "naturally gravitate", "at a moment's notice", "dressing for you is",
    "the energy of someone",
]

AMERICAN = ["color", "center", "organize", "realize", "recognize", "favorite",
            "jewelry", "gray ", "flavor", "behavior"]

COLOUR_LEXICON = set("""
camel toffee taupe stone cream olive moss oxblood burgundy plum cognac charcoal
black white navy indigo bone ivory oyster pearl aqua lavender grey silver blue
green red orange tangerine magenta marigold cobalt scarlet wine caramel rust
terracotta ochre bronze chocolate espresso mahogany brick sand oatmeal ecru
khaki sage teal petrol ink midnight slate graphite pewter smoke fog mist
blush rose pink lilac violet aubergine damson merlot bordeaux cherry crimson
mustard honey amber gold copper brass butter lemon citrine peach apricot coral
salmon mint pistachio emerald forest pine juniper eucalyptus seafoam turquoise
cerulean sky powder denim chambray heather mauve orchid fuchsia raspberry
berry mulberry currant fig walnut chestnut hazel tan fawn biscuit almond
vanilla chalk snow porcelain platinum gunmetal steel iron flint bark loam
umber sienna clay brandy sherry port claret garnet ruby jade lapis onyx
tobacco whisky caramelised nutmeg cinnamon paprika saffron tomato vermilion
poppy flame ember carbon soot ash obsidian jet raven storm thunder ocean
marine ultramarine sapphire azure glacier arctic ice frost pearl-grey
bottle hunter lichen fern reed willow celadon vetiver artichoke
""".split())

METAL_WORDS = ["gold", "silver", "brass", "copper", "platinum", "pewter",
               "gunmetal", "bronze", "chrome", "steel", "titanium", "rhodium"]
STONE_WORDS = ["garnet", "onyx", "quartz", "pearl", "moonstone", "opal",
               "aquamarine", "ruby", "rubies", "citrine", "emerald", "diamond",
               "sapphire", "amber", "jade", "turquoise", "lapis", "agate",
               "tourmaline", "topaz", "obsidian", "malachite", "carnelian",
               "amethyst", "hematite", "labradorite", "peridot", "coral",
               "spinel", "tiger's eye", "tiger eye"]

SECTION_HEADS = [
    "## 1. The Blueprint", "## 2. The Palette", "## 3. The Textures",
    "## 4. The Occasions", "## 5. The Hardware", "## 6. The Code",
    "## 7. The Accessory", "## 8. The Pattern",
]


def strip_metadata(text: str) -> str:
    return re.sub(r"<!--.*?-->", "", text, flags=re.S)


def split_sections(body: str) -> dict[str, str]:
    """Return {section_head: text} for the 8 numbered sections + '_closing'."""
    sections: dict[str, str] = {}
    positions = []
    for head in SECTION_HEADS:
        idx = body.find(head)
        positions.append((head, idx))
    for i, (head, idx) in enumerate(positions):
        if idx < 0:
            sections[head] = ""
            continue
        end = len(body)
        for _, later_idx in positions[i + 1:]:
            if later_idx > idx:
                end = later_idx
                break
        sections[head] = body[idx:end]
    closing = ""
    for line in reversed(body.strip().splitlines()):
        line = line.strip()
        if line.startswith("_") and line.endswith("_"):
            closing = line
            break
    sections["_closing"] = closing
    return sections


def formula_slots(meta: str) -> list[str]:
    m = re.search(r"coreFormula:\s*(.+)", meta)
    if not m:
        return []
    slots = [s.strip().lower() for s in m.group(1).split("+")]
    cleaned = []
    for s in slots:
        tokens = s.split()
        while tokens and tokens[0] in ("a", "an", "the", "one"):
            tokens = tokens[1:]
        cleaned.append(" ".join(tokens))
    return cleaned


def check_guide(path: Path) -> tuple[list[str], list[str]]:
    """Return (errors, notes)."""
    raw = path.read_text(encoding="utf-8")
    meta_match = re.search(r"<!--(.*?)-->", raw, flags=re.S)
    meta = meta_match.group(1) if meta_match else ""
    body = strip_metadata(raw)
    prose = "\n".join(l for l in body.splitlines() if l.strip() != "---")
    lower = prose.lower()
    errors: list[str] = []
    notes: list[str] = []

    # 1. sections
    sections = split_sections(body)
    for head in SECTION_HEADS:
        if not sections[head]:
            errors.append(f"missing section: {head}")
    if not sections["_closing"]:
        errors.append("missing closing italic line")

    # 2. dashes
    if EM_DASH_RE.search(prose):
        errors.append("contains em/en dash in prose")
    if DOUBLE_HYPHEN_RE.search(prose):
        errors.append("contains double-hyphen dash in prose")

    # 3. spelling
    if re.search(r"\bmatte\b", lower):
        errors.append("uses 'matte' (must be 'matt')")
    for w in AMERICAN:
        if re.search(rf"\b{w.strip()}\b", lower):
            errors.append(f"American spelling: {w.strip()}")

    # 4. banned tics
    for tic in BANNED_TICS:
        if tic in lower:
            errors.append(f"banned tic present: {tic!r}")

    # 5. formula propagation
    slots = formula_slots(meta)
    if len(slots) != 3:
        errors.append(f"metadata coreFormula does not have 3 slots: {slots}")
    else:
        positions = {
            "Blueprint": sections["## 1. The Blueprint"],
            "Occasions": sections["## 4. The Occasions"],
            "Code": sections["## 6. The Code"],
            "Accessory": sections["## 7. The Accessory"],
            "closing": sections["_closing"],
        }
        for pos_name, text in positions.items():
            tl = text.lower()
            missing = [s for s in slots if s not in tl]
            if missing:
                errors.append(f"formula slots missing in {pos_name}: {missing}")

    # 6. textures good: 7 bolded fibres
    tex = sections["## 3. The Textures"]
    good_part = tex.split("### The Bad")[0]
    fibres = re.findall(r"^\*\*([^*]+)\*\*:", good_part, flags=re.M)
    if len(fibres) != 7:
        errors.append(f"Textures Good has {len(fibres)} bolded ranked fibres (need 7)")

    # 7. palette colours
    pal = sections["## 2. The Palette"].lower()
    pal_words = set(re.findall(r"[a-z][a-z'-]+", pal))
    named = sorted(pal_words & COLOUR_LEXICON)
    if len(named) < 6:
        errors.append(f"Palette names only {len(named)} lexicon colours: {named}")
    else:
        notes.append(f"palette colours ({len(named)}): {', '.join(named[:12])}")

    # 8. metals + stones
    hw = sections["## 5. The Hardware"].lower()
    metals = sorted({w for w in METAL_WORDS if re.search(rf"\b{w}\b", hw)})
    stones = sorted({w for w in STONE_WORDS if w in hw})
    if len(metals) < 2:
        errors.append(f"Hardware names {len(metals)} metals (need >=2): {metals}")
    if len(stones) < 2:
        errors.append(f"Hardware names {len(stones)} stones (need >=2): {stones}")

    # 9. accessory plan
    plan_match = re.search(r"accessory_?[Pp]lan:\s*(.+)", meta)
    if plan_match:
        includes = plan_match.group(1).lower().count("=include")
        # plans may list categories jointly, e.g. "sheer scarves/stoles=include"
        if includes < 3:
            errors.append(f"accessory plan has {includes} include categories (need >=3)")
    else:
        errors.append("metadata missing accessory plan")

    # 10. test/trap heuristic (named tests, traps, rules, pharmacy-line
    # equivalents, cost-per-wear and longevity directives all count)
    TEST_TRAP_RE = re.compile(
        r"\btest\b|\btrap\b|\brule\b|\bprinciple\b"
        r"|cost.per.wear|five to ten years?"
        r"|does not require|watch out for|ask yourself|ask whether|ask if"
        r"|if .{3,90}(leave|take it off|put it down|swap|walk away|let it go|disqualified|belongs to someone else)"
    )
    for head in SECTION_HEADS:
        if not TEST_TRAP_RE.search(sections[head].lower()):
            notes.append(f"no literal test/trap keyword in {head} (verify by eye)")

    return errors, notes


def main() -> int:
    guides = sorted(GOLDEN_DIR.glob("*_ideal.md"))
    if not guides:
        print("No golden guides found.")
        return 1
    any_fail = False
    for g in guides:
        errors, notes = check_guide(g)
        status = "PASS" if not errors else "FAIL"
        is_ref = g.stem == "slate_ideal"
        suffix = "  [reference chart: excluded from standard scoring]" if is_ref else ""
        print(f"{status}  {g.name}{suffix}")
        for e in errors:
            print(f"      ERROR: {e}")
        for n in notes:
            print(f"      note:  {n}")
        if errors and not is_ref:
            any_fail = True
    print()
    print("Non-circularity: slate_ideal.md hygiene is checked, but the standard's")
    print("pass/fail is decided by the non-reference guides only.")
    return 1 if any_fail else 0


if __name__ == "__main__":
    sys.exit(main())
