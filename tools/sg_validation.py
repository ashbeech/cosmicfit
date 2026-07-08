#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 shared write-gate validation (Phase 3g + minimal 4a-4e).

The UPSTREAM paragraph filter for narrative regeneration. Loads every rule from
the single source of truth data/style_guide/style_guide_rules.json (the same
file the SG-4 Swift StyleGuideCoherenceValidator loads), so the two layers
cannot drift. Do NOT hand-duplicate the constant lists here.

Blocking (error) checks — a paragraph that trips one is NEVER written to the
production cache; it is retried with a repair prompt, then quarantined:
  - dash (em / en / double-hyphen)
  - banned tic
  - coreFormula keyword absent (Blueprint / Occasions-daily / Accessory-1)
  - unknown or Group-A-misplaced placeholder token
  - season word in palette_narrative

Warning checks — written but tagged in the triage sidecar:
  - cross-section phrase repetition
  - filler lexicon over cap
  - concrete-noun floor
"""

from __future__ import annotations

import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RULES_PATH = REPO_ROOT / "data" / "style_guide" / "style_guide_rules.json"

# ─── Frozen placeholder vocabulary (injection_contract_freeze.md section 1) ──

ALLOWED_PLACEHOLDERS: set[str] = set()
for _fam, _rng in [
    ("neutral_colour_", range(1, 5)),
    ("core_colour_", range(1, 5)),
    ("accent_colour_", range(1, 5)),
    ("recommended_pattern_", range(1, 5)),
    ("avoid_pattern_", range(1, 3)),
    ("metal_", range(1, 4)),
    ("stone_", range(1, 4)),
    ("personal_metal_", range(1, 3)),
    ("structural_metal_", range(1, 3)),
    ("texture_good_", range(1, 5)),
    ("texture_bad_", range(1, 4)),
    ("sweet_spot_keyword_", range(1, 3)),
]:
    for _i in _rng:
        ALLOWED_PLACEHOLDERS.add(f"{_fam}{_i}")
ALLOWED_PLACEHOLDERS |= {
    "family", "cluster", "depth", "temperature", "saturation", "contrast",
    "surface", "excluded_finish",
}

GROUP_A_SECTIONS = {
    "style_core",
    "occasions_work", "occasions_intimate", "occasions_daily",
    "accessory_1", "accessory_2", "accessory_3",
}
GROUP_B_SECTIONS = {
    "palette_narrative",
    "pattern_narrative", "pattern_tip",
    "hardware_metals", "hardware_stones", "hardware_tip",
    "textures_good", "textures_bad", "textures_sweet_spot",
}

_PLACEHOLDER_RE = re.compile(r"\{([a-z_0-9]+)\}")
_WORD_RE = re.compile(r"[a-z]+(?:['-][a-z]+)?")

_RULES_CACHE: dict | None = None
_RANKED_TABLES_PATH = REPO_ROOT / "data" / "style_guide" / "ranked_domain_tables.json"
_LEXICON_CACHE: dict | None = None


def _lexicons() -> dict:
    """Literal names that MUST be placeholders in the cache (filled per-user at
    render). Their appearance as literal words in Group B prose is leakage."""
    global _LEXICON_CACHE
    if _LEXICON_CACHE is None:
        rt = json.loads(_RANKED_TABLES_PATH.read_text())
        colours = set()
        for tbl in rt["colours_by_role"].values():
            for grp in ("neutrals", "accents", "relief"):
                for x in tbl.get(grp, []):
                    colours.add(x["name"].lower())
        fibres = {x["name"].lower() for tbl in rt["textures"].values() for x in tbl}
        _LEXICON_CACHE = {"colours": colours, "fibres": fibres}
    return _LEXICON_CACHE


# Which resolved-name lexicons must NOT appear literally in each Group B section.
# (Colours are always placeholder-substituted, so they may not appear literally
# in ANY templated section. Fibres may not appear in the texture sections.
# Pattern/metal/stone names are legitimately named in the golden guides, so they
# are not leak-gated here.)
_LEAK_LEXICONS_BY_SECTION = {
    "palette_narrative": ("colours",),
    "textures_good": ("colours", "fibres"),
    "textures_bad": ("colours", "fibres"),
    "textures_sweet_spot": ("colours", "fibres"),
    "hardware_metals": ("colours",),
    "hardware_stones": ("colours",),
    "hardware_tip": ("colours",),
    "pattern_narrative": ("colours",),
    "pattern_tip": ("colours",),
}

# Required placeholder families (family_prefixes, minimum) per Group B section.
# Tip sections are exempt (they may be abstract). A family list means ANY of the
# listed prefixes counts toward the minimum.
_REQUIRED_PLACEHOLDER_FAMILIES = {
    "palette_narrative": [(("core_colour_",), 2), (("accent_colour_",), 1)],
    "textures_good": [(("texture_good_",), 2)],
    "textures_bad": [(("texture_bad_",), 1)],
    "textures_sweet_spot": [(("sweet_spot_keyword_",), 1)],
    "hardware_metals": [(("metal_", "personal_metal_", "structural_metal_"), 2)],
    "hardware_stones": [(("stone_",), 1)],
    "pattern_narrative": [(("recommended_pattern_",), 1)],
}


def find_literal_leaks(text: str, section_key: str,
                       allowed_phrases: list[str] | None = None) -> list[str]:
    """Literal resolved-names (colours/fibres) appearing outside placeholders in
    a Group B templated section. These would ship verbatim to every user in the
    bucket and contradict their own resolved palette/textures.

    `allowed_phrases` are literal strings the chart is legitimately allowed to
    name (its own pass-over list, which the golden guides name verbatim). They
    are stripped from the text before lexicon matching, so "pass over warm olive
    green" does not trip on "olive" while a stray "olive" elsewhere still does."""
    lex_keys = _LEAK_LEXICONS_BY_SECTION.get(section_key)
    if not lex_keys:
        return []
    low = _PLACEHOLDER_RE.sub(" ", text.lower())
    for phrase in (allowed_phrases or []):
        low = low.replace(phrase.lower(), " ")
    lex = _lexicons()
    hits: list[str] = []
    for key in lex_keys:
        for name in lex[key]:
            if re.search(r"\b" + re.escape(name) + r"\b", low):
                hits.append(name)
    return sorted(set(hits))


AMERICAN_SPELLINGS = ["matte", "color", "colored", "coloring", "center", "gray",
                      "jewelry", "organize", "realize", "recognize", "favorite",
                      "flavor", "behavior", "traveler", "fiber", "neighbor", "labor"]


def find_american_spellings(text: str) -> list[str]:
    low = text.lower()
    return [w for w in AMERICAN_SPELLINGS if re.search(r"\b" + w + r"\b", low)]


def missing_required_placeholders(text: str, section_key: str) -> list[str]:
    reqs = _REQUIRED_PLACEHOLDER_FAMILIES.get(section_key)
    if not reqs:
        return []
    tokens = _PLACEHOLDER_RE.findall(text)
    missing: list[str] = []
    for prefixes, minimum in reqs:
        count = len({t for t in tokens if any(t.startswith(p) for p in prefixes)})
        if count < minimum:
            missing.append(f"need >= {minimum} of {'/'.join(prefixes)} (found {count})")
    return missing


def load_rules(path: Path = RULES_PATH) -> dict:
    global _RULES_CACHE
    if _RULES_CACHE is None:
        with open(path) as f:
            _RULES_CACHE = json.load(f)
    return _RULES_CACHE


def _dash_re() -> re.Pattern:
    return re.compile(load_rules()["dash"]["regex"])


def all_banned_tics() -> list[str]:
    tics = load_rules()["banned_tics"]
    return tics["folklore_floor"] + tics["harvested"]


_STAMP_NORM_RE = re.compile(r"[^a-z0-9]+")


def _normalize_stamp(s: str) -> str:
    return _STAMP_NORM_RE.sub(" ", s.lower()).strip()


def find_stamped_phrases(text: str) -> list[str]:
    """Verbatim stock sentences (normalised, punctuation-insensitive) that must
    never be reproduced in the cache. Loaded from style_guide_rules.json."""
    phrases = load_rules().get("stamped_phrases", {}).get("phrases", [])
    norm_text = _normalize_stamp(text)
    return [p for p in phrases if _normalize_stamp(p) in norm_text]


# ─── Individual checks ────────────────────────────────────────────────

def find_dashes(text: str) -> list[str]:
    return [m.group(0) for m in _dash_re().finditer(text)]


def find_banned_tics(text: str) -> list[str]:
    lower = text.lower()
    return [tic for tic in all_banned_tics() if tic in lower]


def find_season_words(text: str) -> list[str]:
    """Season / seasonal-analysis labels banned in palette_narrative prose."""
    sw = load_rules()["season_words"]
    lower = text.lower()
    hits: list[str] = []
    for phrase in sw["analysis_labels"]:
        if phrase in lower:
            hits.append(phrase)
    for word in sw["bare"]:
        if re.search(rf"\b{re.escape(word)}\b", lower):
            # do not double-report if already covered by a compound label
            if not any(word in h for h in hits):
                hits.append(word)
    return hits


def formula_keywords_present(text: str, core_keywords: list[str]) -> bool:
    """The coreFormula's three components are the tokens the validator searches
    for. Present iff at least one of the three formula slot phrases (the first
    three core_keywords, i.e. everything except the register keyword) appears
    verbatim (case-insensitive) OR the whole formula string appears."""
    lower = text.lower()
    slot_phrases = [kw.lower() for kw in core_keywords[:3]]  # structure/flow/accent
    return any(p in lower for p in slot_phrases)


def find_placeholder_errors(text: str, section_key: str) -> list[str]:
    """Returns blocking placeholder errors: unknown tokens, or any placeholder
    in a Group-A (plain-prose) section."""
    tokens = _PLACEHOLDER_RE.findall(text)
    errors: list[str] = []
    if section_key in GROUP_A_SECTIONS and tokens:
        errors.append(
            "Group A section must be plain prose but contains placeholders: "
            + ", ".join(f"{{{t}}}" for t in tokens[:5])
        )
    unknown = [t for t in tokens if t not in ALLOWED_PLACEHOLDERS]
    if unknown:
        errors.append("Unknown placeholder token(s): " + ", ".join(f"{{{t}}}" for t in unknown[:5]))
    return errors


def filler_count(text: str) -> tuple[int, list[str]]:
    """Count filler-lexicon words (evaluative-use heuristic: plain occurrence)."""
    fl = load_rules()["filler_lexicon"]
    lower = text.lower()
    hits = [w for w in fl["words"] if re.search(rf"\b{re.escape(w)}\b", lower)]
    return len(hits), hits


def concrete_noun_floor(text: str, minimum: int = 2) -> bool:
    """Heuristic concreteness floor: at least `minimum` named concrete nouns
    (colours / fibres / metals / stones / garments) present. Uses the colour +
    metal + stone lexicons plus a small garment list. Warning-level only."""
    lower = text.lower()
    concrete = _CONCRETE_LEXICON
    found = sum(1 for w in concrete if re.search(rf"\b{re.escape(w)}\b", lower))
    # Placeholders count as concrete (they resolve to named nouns at render).
    found += len(_PLACEHOLDER_RE.findall(text))
    return found >= minimum


_CONCRETE_LEXICON = set("""
cashmere wool merino tweed silk leather suede linen cotton velvet corduroy
denim mohair alpaca camelhair gabardine twill flannel jersey satin charmeuse
crepe chiffon organza taffeta canvas nylon neoprene viscose polyester acrylic
gold silver brass copper platinum pewter gunmetal bronze chrome steel titanium
rhodium garnet onyx quartz pearl moonstone opal aquamarine ruby citrine emerald
diamond sapphire amber jade turquoise lapis agate tourmaline topaz obsidian
malachite carnelian amethyst hematite labradorite peridot coral spinel
coat blazer trousers jacket blouse shirt dress skirt knit knitwear scarf belt
bag handbag boots loafers trainers shoes buckle clasp zip ring pendant cuff
necklace earring watch fedora camel toffee taupe cream olive moss oxblood
burgundy plum cognac charcoal oatmeal ecru khaki sage teal petrol navy stone
""".split())


# ─── Cross-section phrase repetition + dedup hints (Phase 3c) ──────────

_STOPWORDS = {
    "your", "you", "with", "that", "this", "they", "them", "from", "into",
    "because", "while", "where", "when", "have", "need", "look", "like",
    "their", "there", "these", "those", "will", "just", "than", "then",
    "what", "which", "about", "over", "under", "after", "before", "make",
    "more", "most", "less", "only", "very", "the", "and", "for", "are",
    "but", "not", "its", "one", "out", "off", "own", "way", "how", "why",
}


def _words(text: str) -> list[str]:
    return _WORD_RE.findall(text.lower())


def ngrams(text: str, n: int) -> list[str]:
    ws = _words(text)
    return [" ".join(ws[i:i + n]) for i in range(len(ws) - n + 1)]


def _is_content_phrase(phrase: str) -> bool:
    toks = phrase.split()
    non_stop = [t for t in toks if t not in _STOPWORDS and len(t) >= 4]
    return len(non_stop) >= 2


def cross_section_phrase_repeats(sections: dict[str, str], min_words: int = 4,
                                 min_count: int = 2) -> list[tuple[str, int]]:
    """Phrases of >= min_words repeated across a cluster's sections."""
    counts: dict[str, int] = {}
    for text in sections.values():
        for phrase in set(ngrams(text, min_words)):  # count once per section
            if _is_content_phrase(phrase):
                counts[phrase] = counts.get(phrase, 0) + 1
    repeats = [(p, c) for p, c in counts.items() if c >= min_count]
    repeats.sort(key=lambda pc: (-pc[1], pc[0]))
    return repeats


def repetition_budget_violations(combined_text: str) -> list[str]:
    """Phrases exceeding their per-cluster budget from style_guide_rules.json."""
    budgets = load_rules()["repetition_budgets"]["phrases"]
    lower = combined_text.lower()
    violations: list[str] = []
    for phrase, budget in budgets.items():
        count = lower.count(phrase)
        if count > budget:
            violations.append(f"{phrase!r} x{count} (budget {budget})")
    return violations


def extract_key_phrases(text: str, sizes=(3, 4, 5)) -> list[str]:
    """Notable multi-word content phrases from a section, for the do_not_reuse
    list fed to subsequent sections (Phase 3c)."""
    out: list[str] = []
    seen: set[str] = set()
    for n in sizes:
        for phrase in ngrams(text, n):
            if _is_content_phrase(phrase) and phrase not in seen:
                seen.add(phrase)
                out.append(phrase)
    return out


def build_phrase_dedup_hints(existing_sections: dict[str, str], limit: int = 20) -> list[str]:
    """Up to `limit` do-not-reuse hints: cross-section repeated phrases first,
    then distinctive single content words. Replaces the single-word-only
    baseline (build_cluster_repetition_hints)."""
    hints: list[str] = []
    for phrase, _c in cross_section_phrase_repeats(existing_sections, min_words=3, min_count=2):
        hints.append(phrase)
        if len(hints) >= limit:
            return hints
    # Fill remaining budget with repeated distinctive single words.
    word_counts: dict[str, int] = {}
    for text in existing_sections.values():
        for w in set(_words(text)):
            if len(w) >= 6 and w not in _STOPWORDS:
                word_counts[w] = word_counts.get(w, 0) + 1
    for w, c in sorted(word_counts.items(), key=lambda kv: (-kv[1], kv[0])):
        if c >= 2 and w not in hints:
            hints.append(w)
        if len(hints) >= limit:
            break
    return hints[:limit]


# ─── Full paragraph gate ──────────────────────────────────────────────

def validate_paragraph_gate(
    text: str,
    section_key: str,
    core_keywords: list[str],
    existing_cluster_texts: list[str] | None = None,
    allowed_leak_phrases: list[str] | None = None,
) -> dict:
    """Returns {errors, warnings, passed}. `passed` is True iff zero errors."""
    errors: list[str] = []
    warnings: list[str] = []
    rules = load_rules()
    formula_sections = set(rules["write_gate"]["core_formula_required_sections"])

    dashes = find_dashes(text)
    if dashes:
        errors.append(f"dash: found {len(dashes)} dash character(s) ({dashes[0]!r})")

    tics = find_banned_tics(text)
    if tics:
        errors.append("banned_tic: " + ", ".join(repr(t) for t in tics))

    american = find_american_spellings(text)
    if american:
        errors.append("american_spelling: " + ", ".join(american))

    stamps = find_stamped_phrases(text)
    if stamps:
        errors.append("stamped_phrase: " + ", ".join(repr(s) for s in stamps))

    if section_key in formula_sections and not formula_keywords_present(text, core_keywords):
        errors.append(
            "core_formula_absent: none of the formula slot phrases "
            + str([kw for kw in core_keywords[:3]]) + " appear"
        )

    errors.extend(find_placeholder_errors(text, section_key))

    leaks = find_literal_leaks(text, section_key, allowed_leak_phrases)
    if leaks:
        errors.append("literal_name_leak (must be placeholders): " + ", ".join(leaks[:6]))

    missing_ph = missing_required_placeholders(text, section_key)
    if missing_ph:
        errors.append("missing_required_placeholder: " + "; ".join(missing_ph))

    if section_key == "palette_narrative":
        seasons = find_season_words(text)
        if seasons:
            errors.append("season_word_in_palette: " + ", ".join(seasons))

    # Warnings
    n_filler, filler_hits = filler_count(text)
    cap = rules["filler_lexicon"]["cap_per_section"]
    if n_filler > cap:
        warnings.append(f"filler_over_cap: {n_filler} filler words {filler_hits} (cap {cap})")

    if not concrete_noun_floor(text):
        warnings.append("concrete_noun_floor: fewer than 2 named concrete nouns")

    if existing_cluster_texts:
        combined = " ".join(existing_cluster_texts + [text])
        for v in repetition_budget_violations(combined):
            warnings.append(f"phrase_repetition: {v}")

    return {"errors": errors, "warnings": warnings, "passed": len(errors) == 0}


if __name__ == "__main__":
    # Smoke test: load rules and run the gate on a few crafted paragraphs.
    import sys
    rules = load_rules()
    print(f"Loaded rules v{rules['_meta']['schema_version']}: "
          f"{len(all_banned_tics())} banned tics, "
          f"{len(ALLOWED_PLACEHOLDERS)} placeholders.")
    cases = [
        ("clean prose", "style_core",
         "Build your wardrobe on structure and softness. Pick up a wool coat and feel its weight before you buy.",
         ["structure", "softness", "a touch of quiet depth", "quiet luxury"]),
        ("has dash", "style_core",
         "You know what works — trust it. Structure leads here.",
         ["structure", "softness", "a touch of quiet depth", "quiet luxury"]),
        ("banned tic", "style_core",
         "You walk into a room and everyone notices your structure and softness.",
         ["structure", "softness", "a touch of quiet depth", "quiet luxury"]),
        ("formula absent", "occasions_daily",
         "For errands, wear leather trainers and a fine merino knit that moves with you.",
         ["structure", "softness", "a touch of quiet depth", "quiet luxury"]),
        ("season word", "palette_narrative",
         "Your winter coats want {core_colour_1} and {accent_colour_1} for depth.",
         ["structure", "softness", "a touch of quiet depth", "quiet luxury"]),
        ("group A placeholder", "style_core",
         "Your palette leans on {core_colour_1} with structure and softness throughout.",
         ["structure", "softness", "a touch of quiet depth", "quiet luxury"]),
    ]
    fails = 0
    for label, sk, txt, kw in cases:
        r = validate_paragraph_gate(txt, sk, kw)
        verdict = "PASS" if r["passed"] else "BLOCK"
        expect_block = label != "clean prose"
        ok = (not r["passed"]) == expect_block
        if not ok:
            fails += 1
        print(f"  [{'ok' if ok else 'XX'}] {label}: {verdict} errors={r['errors']}")
    sys.exit(1 if fails else 0)
