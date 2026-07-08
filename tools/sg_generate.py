#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 narrative generation core (Phases 3a-3e, 3g).

Builds the Style-DNA-conditioned prompts, drives sequential per-cluster
generation with decision propagation + phrase dedup, runs the blocking write
gate (retry -> repair -> quarantine), threads a holistic per-cluster edit pass,
and assembles cache schema v2 objects.

The CLI entrypoint (tools/backfill_narratives.py) owns argument parsing, the
backup gate, key/model resolution, resume, and file I/O; this module owns the
generation logic so it stays unit-testable without the network.
"""

from __future__ import annotations

import json
from pathlib import Path

import sg_validation as V
from sg_profile import CoarseProfile
from sg_accessory_plan import accessory_plan

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data" / "style_guide"
RANKED_TABLES_PATH = DATA_DIR / "ranked_domain_tables.json"
TEST_TRAP_LIBRARY_PATH = DATA_DIR / "test_trap_library.json"
SECTION_EXAMPLES_PATH = DATA_DIR / "section_examples.json"

SECTION_KEYS = [
    "style_core",
    "textures_good", "textures_bad", "textures_sweet_spot",
    "palette_narrative",
    "occasions_work", "occasions_intimate", "occasions_daily",
    "hardware_metals", "hardware_stones", "hardware_tip",
    "accessory_1", "accessory_2", "accessory_3",
    "pattern_narrative", "pattern_tip",
]

SECTION_DISPLAY = {
    "style_core": "Blueprint / Style Core",
    "textures_good": "Textures: The Good", "textures_bad": "Textures: The Bad",
    "textures_sweet_spot": "Textures: The Sweet Spot",
    "palette_narrative": "Palette",
    "occasions_work": "Occasions: At Work", "occasions_intimate": "Occasions: Intimate",
    "occasions_daily": "Occasions: Daily",
    "hardware_metals": "Hardware: The Metals", "hardware_stones": "Hardware: The Stones",
    "hardware_tip": "Hardware: Tip",
    "accessory_1": "Accessory: Opening", "accessory_2": "Accessory: Category",
    "accessory_3": "Accessory: Category / Exit test",
    "pattern_narrative": "Pattern", "pattern_tip": "Pattern: Tip",
}

CACHE_KEY_TO_SECTION = {
    "style_core": "blueprint", "palette_narrative": "palette",
    "textures_good": "textures", "textures_bad": "textures", "textures_sweet_spot": "textures",
    "occasions_work": "occasions", "occasions_intimate": "occasions", "occasions_daily": "occasions",
    "hardware_metals": "hardware", "hardware_stones": "hardware", "hardware_tip": "hardware",
    "accessory_1": "accessory", "accessory_2": "accessory", "accessory_3": "accessory",
    "pattern_narrative": "pattern", "pattern_tip": "pattern",
}

_JSON_CACHE: dict[str, dict] = {}


def _load(path: Path) -> dict:
    key = str(path)
    if key not in _JSON_CACHE:
        with open(path) as f:
            _JSON_CACHE[key] = json.load(f)
    return _JSON_CACHE[key]


# ─── System prompt (instructional coach voice) ────────────────────────

SYSTEM_PROMPT = """You are writing one section of a personal style guide for Cosmic Fit.

The guide is an INSTRUCTIONAL, SECOND-PERSON COACH'S MANUAL. You are teaching the
reader to dress and to trust their own physical instincts, as if handing them a
personal stylist's handbook they can use without you present.

VOICE:
- Instructional second-person coach. Give directives, tests, and traps:
  "Look for...", "Avoid...", "Pick it up and...", "Trust your hands...".
- Teach the reader to trust their own physical instincts by giving them a test
  they can apply with their own hands, eyes, or body. Invent that test in fresh
  words for THIS chart. Never reuse a stock sentence.
- Concrete over abstract. One strong image per paragraph. Named garments,
  fibres, colours, metals, and stones do the work, NOT evaluative adjectives.
- British English throughout (colour, jewellery, grey). The spelling is MATT,
  never matte.

NEVER write flattering description of the reader's taste. NEVER use observer
voice ("you walk into a room and..."). NEVER praise. The reader is not here to
be admired; they are here to learn how to dress. Banned phrases include:
"unbothered", "signs the cheques", "devastatingly chic", "command the room",
"quiet expensive authority", "effortlessly elegant", "walk into a room",
"an exercise in", "naturally gravitate", "your professional wardrobe",
"your daily rotation", "the energy of someone".

PUNCTUATION (hard rule): NEVER use em dashes, en dashes, or double hyphens used
as dashes. Use a COMMA when the dash would join a continuation in the same
sentence. Use a FULL STOP when the dash would start an independent clause. Do
not use semicolons as a dash substitute. (In the examples below, [DASH] marks
where a writer would wrongly place a dash; never emit that character.)
  WRONG: "expensive authority [DASH] the kind that speaks softly"
  RIGHT: "expensive authority, the kind that speaks softly"
  WRONG: "you know what works [DASH] trust it"
  RIGHT: "you know what works. Trust it."

Return ONLY the requested JSON object. The "text" field is plain prose (no
markdown, no headers, no bullet lists) unless the task explicitly asks for
placeholder tokens."""


SECTION_OUTPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "text": {"type": "string"},
        "sectionIntro": {"type": "string"},
    },
    "required": ["text", "sectionIntro"],
}

HOLISTIC_OUTPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "revisedSections": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "key": {"type": "string"},
                    "text": {"type": "string"},
                },
                "required": ["key", "text"],
            },
        },
        "closing": {"type": "string"},
    },
    "required": ["revisedSections", "closing"],
}


# ─── Style DNA preamble ───────────────────────────────────────────────

def build_style_dna_preamble(p: CoarseProfile) -> str:
    return (
        "STYLE DNA (binding decisions for this reader; every line of this "
        "section must be consistent with them):\n"
        f"- Aesthetic register: {p.aesthetic_register}\n"
        f"- Temperature: {p.temperature} (the temperature word in your prose MUST "
        f"be '{p.temperature}'; do not describe a {_opposite_temp(p.temperature)} palette)\n"
        f"- Metal strategy: {p.metal_strategy}\n"
        f"- Finish lane: {p.finish_lane}\n"
        f"- Orientation: {p.orientation}\n"
        f"- Core style formula: \"{p.core_formula}\"\n"
        f"- Formula keywords (the tokens the validator searches for): "
        f"{', '.join(p.core_keywords[:3])}\n"
        f"- Off-lane words you must NOT assert positively: "
        f"{', '.join(p.excluded_keywords)}\n"
    )


def _opposite_temp(t: str) -> str:
    return {"warm": "cool", "cool": "warm", "neutral": "strongly warm or cool"}[t]


# Sensory-compass MODALITY per dominant element (keywords, NOT example
# sentences). The Blueprint's ultimate-compass test MUST be built on this
# chart's modality and worded freshly; a weight compass on an air chart is a
# genre error. Described as guidance so we do not stamp a per-element sentence.
_COMPASS_MODALITY = {
    "earth": "WEIGHT and TOUCH in the hand: does it feel dense, substantial, and honest under the fingers",
    "fire": "SPEED and IMPACT: how fast can you move in it, does it go or does it hesitate and drag",
    "air": "CRISPNESS and SEPARATION: does it stay sharp, light, and cleanly cut, does it hold its line",
    "water": "BREATH and FLOW: how it moves and settles against the body, does it float or does it cling",
}


def compass_instruction(p: CoarseProfile) -> str:
    modality = _COMPASS_MODALITY.get(p.dominant_element, _COMPASS_MODALITY["earth"])
    return (
        "\nSENSORY COMPASS (critical): this chart's compass MUST be built on its "
        f"element's modality, which is {modality}. Name an ultimate-compass test the "
        "reader applies themselves, worded FRESHLY in your own language for this chart. "
        "Do NOT default to a weight/touch compass unless this chart is earth. NEVER use "
        "a stock sentence such as 'Looks lie. Weight doesn't.' or 'Trust this physical "
        "instinct as your ultimate compass.' Write a different sentence."
    )


def build_formula_binding(p: CoarseProfile, section_key: str) -> str:
    req = formula_requirement(section_key)
    base = (
        f"BINDING FORMULA: this reader's core style formula is "
        f"\"{p.core_formula}\". Thread it through your writing. "
    )
    if req == "verbatim":
        return base + (
            f"You MUST state the formula VERBATIM, exactly as "
            f"\"{p.core_formula}\", somewhere in the text."
        )
    if req == "final_term":
        return base + (
            f"Open by tying this section to the formula's final term "
            f"(\"{p.core_keywords[2]}\"), referencing the other two slots "
            f"(\"{p.core_keywords[0]}\", \"{p.core_keywords[1]}\")."
        )
    return base + "Reference at least one formula keyword explicitly."


def formula_requirement(section_key: str) -> str:
    """How strongly the formula must appear in this section's text."""
    if section_key in ("style_core", "occasions_daily"):
        return "verbatim"
    if section_key == "accessory_1":
        return "final_term"
    return "reference"


# ─── Ranked-item selection (deterministic, from Phase 2d tables) ──────

def _colour_lane(p: CoarseProfile) -> str:
    return "water_dominant" if p.dominant_element == "water" else p.aesthetic_register


def ranked_items_for_section(section_key: str, p: CoarseProfile) -> list[dict]:
    tables = _load(RANKED_TABLES_PATH)
    if section_key == "palette_narrative":
        key = f"{p.temperature}_{_colour_lane(p)}"
        tbl = tables["colours_by_role"].get(key, {})
        items: list[dict] = []
        for group in ("neutrals", "accents", "relief"):
            for c in tbl.get(group, []):
                items.append({"name": c["name"], "role": c["role"]})
        return items
    if section_key == "textures_good":
        tbl = tables["textures"].get(_colour_lane(p), [])
        ordered = sorted(tbl, key=lambda r: r.get("rank", 99))[:7]
        return [{"name": r["name"], "role": f"rank {r['rank']}", "useCase": r["useCase"]}
                for r in ordered]
    if section_key in ("accessory_1", "accessory_2", "accessory_3"):
        plan = accessory_plan(p.aesthetic_register, p.orientation, p.finish_lane)
        slot = int(section_key.split("_")[1])
        cats = []
        for s in plan["slots"]:
            if s["slot"] == slot:
                cats = s["categories"]
        return [{"name": c["category"], "role": "accessory category",
                 "useCase": f"{c['material']}, {c['finish']}"} for c in cats]
    return []


def pass_over_for_palette(p: CoarseProfile) -> list[str]:
    tables = _load(RANKED_TABLES_PATH)
    key = f"{p.temperature}_{_colour_lane(p)}"
    return tables["colours_by_role"].get(key, {}).get("passOver", [])


# ─── Test / trap selection (from the profile-gated library) ───────────

def select_tests_traps(section_key: str, p: CoarseProfile,
                       cluster_key: str = "") -> tuple[list[str], list[dict]]:
    """Pick from the register bucket, but ROTATE the choice by a deterministic
    hash of the cluster key so different charts in the same register do not all
    receive the identical canonical test/trap (which stamped verbatim across the
    first run, e.g. one pharmacy line on every bold chart)."""
    lib = _load(TEST_TRAP_LIBRARY_PATH)["sections"]
    section = CACHE_KEY_TO_SECTION.get(section_key)
    body = lib.get(section, {})
    reg = p.aesthetic_register
    seed = sum(ord(c) for c in cluster_key) if cluster_key else 0

    def pick(bucket: dict, n: int) -> list:
        pool = list(bucket.get(reg, []))
        pool += [x for x in bucket.get("any", []) if x not in pool]
        if not pool:
            return []
        start = seed % len(pool)
        rotated = pool[start:] + pool[:start]
        return rotated[:n]

    tests = pick(body.get("tests", {}), 1)
    traps = pick(body.get("traps", {}), 1)
    return tests, traps


def example_copy_error(text: str, examples: list[str], min_run: int = 10) -> str | None:
    """Blocks near-verbatim copying of a voice-reference example (a shared run of
    >= min_run words)."""
    text_grams = set(V.ngrams(text, min_run))
    for ex in examples:
        if text_grams & set(V.ngrams(ex, min_run)):
            return f"example_copy: reproduces a >= {min_run}-word run from a voice-reference example"
    return None


# ─── Per-section task instructions ────────────────────────────────────

_GROUP_B = V.GROUP_B_SECTIONS

SECTION_TASK = {
    "style_core": (
        "Write the BLUEPRINT / Style Core. This must be at least TWO paragraphs "
        "separated by a blank line. Together they must contain: a chart-appropriate "
        "SENSORY or INSTINCT COMPASS (touch, weight, speed, breath, precision, "
        "whatever fits this register); the coreFormula stated VERBATIM in its "
        "'X + Y + Z' form with a concrete 'picture this' outfit that illustrates it; "
        "a BUILD-TEMPO statement (build slowly, deploy fast, drift by mood, per "
        "chart); and a named ULTIMATE-COMPASS test the reader can apply. Do NOT name "
        "specific colours, patterns, metals, stones or texture placeholders here; "
        "keep it directional."
    ),
    "textures_good": (
        "Write the TEXTURES 'The Good' framing paragraph. Teach the reader why these "
        "materials serve their style, and end pointing at the ranked list. Use the "
        "texture placeholders ({texture_good_1}..{texture_good_4}) in the prose in "
        "place of literal fibre names. Weave the named purchase/touch test."
    ),
    "textures_bad": (
        "Write the TEXTURES 'The Bad' paragraph: the materials to avoid, each with its "
        "PHYSICAL TELL (how it fails against the skin or in the hand). Use "
        "{texture_bad_1}..{texture_bad_3} in place of literal names. Use at least two."
    ),
    "textures_sweet_spot": (
        "Write the TEXTURES 'The Sweet Spot': the signature texture pairing for this "
        "reader. Use {sweet_spot_keyword_1}, {sweet_spot_keyword_2}, and you may "
        "reference {texture_good_1}. Keep it short and physical."
    ),
    "palette_narrative": (
        "Write the PALETTE narrative. Describe the reader's colours BY ROLE only, "
        "using the colour placeholders: {core_colour_1}..{core_colour_4} for the "
        "foundation/neutral base, {accent_colour_1}..{accent_colour_2} for the single "
        "deliberate accent, and name the RELIEF colour's when-to-use. State a one-line "
        "temperature statement that matches the Style DNA temperature. Give the "
        "pass-over list. Name the palette trap and its fix. NEVER name a season or a "
        "seasonal-analysis label (no winter/spring/summer/autumn, no 'Deep Autumn' "
        "etc.). Use placeholders, not literal colour names."
    ),
    "occasions_work": (
        "Write OCCASIONS 'At Work'. State which formula element LEADS at work for this "
        "reader, and how the other elements support. Keep it directional (no colour/"
        "metal/texture placeholders)."
    ),
    "occasions_intimate": (
        "Write OCCASIONS 'Intimate / Evening'. State which formula element leads in "
        "close, low-light settings. Directional prose, no placeholders."
    ),
    "occasions_daily": (
        "Write OCCASIONS 'Daily Movement'. Include a 'pharmacy line' equivalent (a "
        "named mundane errand that does NOT suspend the standard) and an explicit "
        "FORMULA-CONSTANCY line that restates the coreFormula VERBATIM. Directional "
        "prose, no placeholders."
    ),
    "hardware_metals": (
        "Write HARDWARE 'The Metals'. State this reader's metal STRATEGY in prose. For "
        "a dualRegister chart, split personal metal (worn against the skin, "
        "{personal_metal_1}/{personal_metal_2}) from structural metal (clasps, zips, "
        "buckles, {structural_metal_1}/{structural_metal_2}). For warm/coolDominant "
        "use single-register framing with {metal_1}..{metal_3}. For mixedFree, "
        "describe the freedom to mix, using {metal_1}..{metal_3}. Name the excluded "
        "finish with {excluded_finish} (or a named embraced finish if nothing is "
        "excluded). Use at least two metal placeholders."
    ),
    "hardware_stones": (
        "Write HARDWARE 'The Stones': a role-driven stone rule (density, clarity, "
        "light-holding, per chart). Use {stone_1}..{stone_3}; at least two."
    ),
    "hardware_tip": (
        "Write HARDWARE 'Tip': the pick-it-up WEIGHT TEST reworded in this reader's "
        "voice. You may reference {metal_1} or {stone_1}."
    ),
    "accessory_1": (
        "Write the ACCESSORY opening. Tie accessories to the formula's FINAL term, "
        "referencing the other two slots. Name the 'one or two strong pieces per look' "
        "principle explicitly. Then introduce the FIRST included category (see the "
        "accessory plan) with its material/finish/shape. Category-level nouns only "
        "(belts, bags, straps), no colour/metal placeholders."
    ),
    "accessory_2": (
        "Write the second ACCESSORY paragraph covering the SECOND included category "
        "with its material/finish/shape specs. Do NOT name any omitted category. "
        "Category-level nouns only."
    ),
    "accessory_3": (
        "Write the third ACCESSORY paragraph covering the remaining included "
        "category/categories with specs, and end with a named EXIT test (e.g. remove "
        "the one piece doing too much). Do NOT name any omitted category."
    ),
    "pattern_narrative": (
        "Write the PATTERN narrative. Give the TAILORED-vs-FLUID split (what tailored "
        "pieces take their pattern from vs what fluid pieces take). State a "
        "pattern-contrast rule that AGREES with the register (low-contrast tonal for "
        "quietLuxury; high-contrast graphic for boldExpression; adaptive for "
        "versatile). Use {recommended_pattern_1}..{recommended_pattern_4} and "
        "{avoid_pattern_1}..{avoid_pattern_2}. Give a pass-over list. Use at least two "
        "recommended and one avoid."
    ),
    "pattern_tip": (
        "Write the PATTERN 'Tip': a named distance/blur/legibility test tuned to this "
        "reader. You may reference {recommended_pattern_1}."
    ),
}


def build_section_prompt(
    section_key: str,
    p: CoarseProfile,
    ranked_items: list[dict],
    tests: list[str],
    traps: list[dict],
    prior_decisions: dict,
    dedup_hints: list[str],
    examples: list[str],
    repair_note: str | None = None,
) -> str:
    parts: list[str] = [build_style_dna_preamble(p)]
    parts.append("\n" + build_formula_binding(p, section_key))
    parts.append(f"\nSECTION: {SECTION_DISPLAY.get(section_key, section_key)}")
    parts.append(f"\nTASK: {SECTION_TASK.get(section_key, 'Write this section in the coach voice.')}")

    if section_key in _GROUP_B:
        parts.append(
            "\nPLACEHOLDERS: emit the exact placeholder tokens shown above (e.g. "
            "{core_colour_1}); do NOT invent literal colour/fibre/metal/stone/pattern "
            "names outside the placeholders. These are filled per-reader at render time."
        )
    else:
        parts.append(
            "\nPLAIN PROSE: this section must contain NO placeholder tokens at all."
        )

    if section_key == "style_core":
        parts.append(compass_instruction(p))

    if ranked_items:
        parts.append(_ranked_grounding_block(section_key, ranked_items))

    if section_key == "palette_narrative":
        po = pass_over_for_palette(p)
        if po:
            parts.append("\nPASS-OVER colours to name as off-limits: " + ", ".join(po))

    if section_key.startswith("accessory"):
        plan = accessory_plan(p.aesthetic_register, p.orientation, p.finish_lane)
        omit = [o["category"] for o in plan["omit"]]
        if omit:
            parts.append("\nNEVER name these OMITTED categories: " + ", ".join(omit))

    if tests:
        parts.append("\nApply this named test, but express it in THIS reader's OWN words "
                     "and imagery. Do NOT reproduce it as a stock sentence: " + " | ".join(tests))
    if traps:
        parts.append("\nName this failure mode and its fix in fresh words specific to this "
                     "reader (do not copy the wording): "
                     + " | ".join(f"{t['failure']} -> {t['fix']}" for t in traps))

    if prior_decisions:
        parts.append("\nPRIOR DECISIONS already made for this reader (stay consistent, "
                     "do not contradict):")
        for k, v in prior_decisions.items():
            parts.append(f"  - {k}: {v}")

    if dedup_hints:
        parts.append("\nDO NOT REUSE these words/phrases already used elsewhere in this "
                     "guide (find fresh language): " + ", ".join(dedup_hints[:20]))

    if examples:
        parts.append(
            "\nVOICE REFERENCE (ONE example, for TONE and CONCRETENESS only). Do NOT reuse "
            "any of its sentences, phrases, tests, images, colours, or structure. Write "
            "entirely fresh language specific to THIS reader:\n  " + examples[0])

    if repair_note:
        parts.append(f"\nREPAIR REQUIRED. Your previous attempt failed the write gate: "
                     f"{repair_note}. Fix exactly this and keep everything else.")

    parts.append(
        "\nLENGTH: keep it economical. A single-paragraph section should be about 60 to "
        "130 words. style_core uses two paragraphs of about 80 to 110 words each. Cut "
        "padding and do not restate a point you have already made."
    )
    parts.append(
        "\nReturn JSON: {\"text\": <the section prose>, \"sectionIntro\": <one opening "
        "line that frames what this section is for, in the coach voice>}."
    )
    return "\n".join(parts)


def _ranked_grounding_block(section_key: str, ranked_items: list[dict]) -> str:
    """Group A (accessory) sees literal category names (they ARE the content).
    Group B templated sections see a placeholder->role MAP only, never literal
    colour/fibre names (which must stay placeholders to be filled per-user)."""
    if section_key.startswith("accessory"):
        lines = ["\nCATEGORIES to cover in this paragraph (name them; they are the content):"]
        for it in ranked_items:
            uc = f": {it['useCase']}" if it.get("useCase") else ""
            lines.append(f"  - {it['name']}{uc}")
        return "\n".join(lines)

    if section_key == "palette_narrative":
        neutrals = [it for it in ranked_items if it["role"] not in ("accent", "relief")]
        accents = [it for it in ranked_items if it["role"] == "accent"]
        lines = ["\nPLACEHOLDER->ROLE MAP. Write with these tokens ONLY; never a literal "
                 "colour name (the reader's own colours are filled in at render time):"]
        for i, it in enumerate(neutrals[:4], 1):
            lines.append(f"  - {{core_colour_{i}}} = a {it['role'].replace('_', ' ')} neutral")
        for i, it in enumerate(accents[:2], 1):
            lines.append(f"  - {{accent_colour_{i}}} = your single deliberate accent")
        lines.append("  - the relief tone: describe its RELIEF role (when to reach for it) "
                     "in your own fresh words; do not name a literal colour and do not reuse a stock phrase")
        return "\n".join(lines)

    if section_key == "textures_good":
        lines = ["\nPLACEHOLDER->USE-CASE MAP. Write with these tokens ONLY; never a literal "
                 "fibre name (the reader's own fabrics are filled in at render time):"]
        for i, it in enumerate(ranked_items[:4], 1):
            uc = it.get("useCase", "")
            lines.append(f"  - {{texture_good_{i}}} = for {uc}")
        return "\n".join(lines)

    return ""


# ─── Extra formula checks beyond the shared gate ──────────────────────

def formula_gate_errors(text: str, section_key: str, p: CoarseProfile) -> list[str]:
    req = formula_requirement(section_key)
    lower = text.lower()
    errs: list[str] = []
    if req == "verbatim" and p.core_formula.lower() not in lower:
        errs.append(f"formula_verbatim_absent: must contain \"{p.core_formula}\" verbatim")
    if req == "final_term" and p.core_keywords[2].lower() not in lower:
        errs.append(f"formula_final_term_absent: must reference \"{p.core_keywords[2]}\"")
    if section_key == "style_core":
        paras = [x for x in text.split("\n\n") if x.strip()]
        if len(paras) < 2:
            errs.append("style_core_paragraph_floor: needs >= 2 paragraphs (blank-line separated)")
    return errs


_LENGTH_BLOCK = {"style_core": 280}  # per-section hard cap; default below
_LENGTH_BLOCK_DEFAULT = 200


def _allowed_leak_phrases(section_key: str, p: CoarseProfile) -> list[str]:
    """The literal strings a section may legitimately name (its pass-over list,
    which the golden guides name verbatim)."""
    if section_key == "palette_narrative":
        return pass_over_for_palette(p)
    return []


def gate_intro(intro: str, section_key: str, p: CoarseProfile) -> list[str]:
    """The sectionIntro is written to the cache and shown in the app, so it must
    pass the same hygiene checks as the body (dash / tic / leak / season /
    spelling). Formula/placeholder floors do not apply to a one-line intro."""
    if not intro:
        return []
    errors: list[str] = []
    if V.find_dashes(intro):
        errors.append("intro_dash")
    if V.find_banned_tics(intro):
        errors.append("intro_banned_tic: " + ", ".join(V.find_banned_tics(intro)))
    if V.find_american_spellings(intro):
        errors.append("intro_american_spelling: " + ", ".join(V.find_american_spellings(intro)))
    if V.find_stamped_phrases(intro):
        errors.append("intro_stamped_phrase: " + ", ".join(V.find_stamped_phrases(intro)))
    leaks = V.find_literal_leaks(intro, section_key, _allowed_leak_phrases(section_key, p))
    if leaks:
        errors.append("intro_literal_leak: " + ", ".join(leaks[:4]))
    if section_key == "palette_narrative" and V.find_season_words(intro):
        errors.append("intro_season_word: " + ", ".join(V.find_season_words(intro)))
    return errors


def gate_section(text: str, section_key: str, p: CoarseProfile,
                 existing_texts: list[str], examples: list[str] | None = None,
                 intro: str = "") -> dict:
    """Full write-gate verdict for one section: shared checks + pass-over-aware
    leak check + formula extras + example-copy guard + hard length block +
    intro hygiene."""
    result = V.validate_paragraph_gate(
        text, section_key, p.core_keywords, existing_texts,
        allowed_leak_phrases=_allowed_leak_phrases(section_key, p))
    extra = formula_gate_errors(text, section_key, p)
    if extra:
        result["errors"] = result["errors"] + extra
    copy_err = example_copy_error(text, examples or [])
    if copy_err:
        result["errors"] = result["errors"] + [copy_err]
    limit = _LENGTH_BLOCK.get(section_key, _LENGTH_BLOCK_DEFAULT)
    n = len(text.split())
    if n > limit:
        result["errors"] = result["errors"] + [f"too_long_block: {n} words > {limit}"]
    result["errors"] = result["errors"] + gate_intro(intro, section_key, p)
    result["passed"] = len(result["errors"]) == 0
    return result


def gate_closing(text: str, p: CoarseProfile) -> dict:
    errors: list[str] = []
    if V.find_dashes(text):
        errors.append("dash in closing")
    tics = V.find_banned_tics(text)
    if tics:
        errors.append("banned_tic in closing: " + ", ".join(tics))
    if V.find_american_spellings(text):
        errors.append("american_spelling in closing: " + ", ".join(V.find_american_spellings(text)))
    if V.find_stamped_phrases(text):
        errors.append("stamped_phrase in closing: " + ", ".join(V.find_stamped_phrases(text)))
    if V.find_season_words(text):
        errors.append("season_word in closing: " + ", ".join(V.find_season_words(text)))
    # Closing is prose (Group A voice); literal colour names should not appear.
    leaks = V.find_literal_leaks(text, "palette_narrative", pass_over_for_palette(p))
    if leaks:
        errors.append("literal_colour in closing: " + ", ".join(leaks[:4]))
    if not text.rstrip().rstrip(".").lower().endswith(p.core_formula.lower()):
        errors.append(f"closing must end with the coreFormula \"{p.core_formula}\"")
    return {"errors": errors, "warnings": [], "passed": len(errors) == 0}


# ─── Decisions accumulator update ─────────────────────────────────────

def update_decisions(acc: dict, section_key: str, p: CoarseProfile,
                     ranked_items: list[dict]) -> None:
    if section_key == "textures_good" and ranked_items:
        acc["top_textures"] = ", ".join(i["name"] for i in ranked_items[:4])
    if section_key == "palette_narrative":
        acc["palette_temperature"] = p.temperature
        if ranked_items:
            acc["core_colours"] = ", ".join(i["name"] for i in ranked_items[:4]
                                            if "base" in i["role"] or "neutral" in i["role"].lower())
    if section_key == "hardware_metals":
        acc["metal_strategy"] = p.metal_strategy
    acc.setdefault("formula", p.core_formula)


# ─── Holistic per-cluster edit pass (Phase 3d) ────────────────────────

def build_holistic_prompt(p: CoarseProfile, sections: dict[str, dict]) -> str:
    parts = [
        "You are doing a final HOLISTIC edit pass over one reader's complete style "
        "guide. Your job is to RECONCILE, not to invent. Do NOT add new claims, "
        "colours, or items that are not already present.",
        build_style_dna_preamble(p),
        f"\nThe binding thesis is the coreFormula: \"{p.core_formula}\". It must thread "
        "through the whole document as a single coherent spine.",
        "\nDo all of the following across the sections below:",
        "  1. Remove cross-section repetition (same phrasings, images, or sentence "
        "openings reused across sections). Reword the later occurrence.",
        "  2. Reconcile the voice so the whole guide reads as one instructional coach.",
        "  3. Strip and rewrite any em dash, en dash, or double-hyphen dash to a comma "
        "or full stop.",
        "  4. Ensure the coreFormula thesis is felt throughout (do not delete the "
        "verbatim statements in Blueprint or Occasions).",
        "  5. Preserve every placeholder token ({like_this}) exactly where it is.",
        "\nThen write the CLOSING line: one short italic-style map-of-instincts "
        f"sentence that ENDS with the coreFormula verbatim \"{p.core_formula}\".",
        "\nSECTIONS (key then text):",
    ]
    for sk in SECTION_KEYS:
        if sk in sections:
            parts.append(f"\n### {sk}\n{sections[sk]['text']}")
    parts.append(
        "\nReturn JSON: {\"revisedSections\": [{\"key\": <section_key>, \"text\": "
        "<revised text>}, ...], \"closing\": <the closing line>}. Include every "
        "section key you were given."
    )
    return "\n".join(parts)


# ─── Cluster orchestration ────────────────────────────────────────────

MAX_GATE_RETRIES = 2  # initial attempt + up to 2 repair attempts


def _approx_tokens(*strings: str) -> int:
    return sum(len(s) for s in strings) // 4


def generate_cluster(
    cluster_key: str,
    profile: CoarseProfile,
    generate_json,
    log_fn=lambda *_: None,
    existing_cluster: dict | None = None,
    section_keys: list[str] = SECTION_KEYS,
) -> dict:
    """Generate one cluster sequentially with dedup + write gate + holistic pass.

    `generate_json(prompt, system, schema) -> dict` performs the model call (or a
    stub in tests). Returns:
      {
        "cluster": { "coreFormula", "closing", "<section>": {v2 obj} },   # passing sections only
        "quarantine": { "<section>": {text, errors, attempts} },
        "run_log": [ {section, outcome, attempts, warnings, tokens} ],
      }
    """
    examples_all = _load(SECTION_EXAMPLES_PATH)["section_examples"]
    cluster: dict = {"coreFormula": profile.core_formula}
    quarantine: dict = {}
    run_log: list[dict] = []
    decisions: dict = {}
    passing_texts: list[str] = []

    # Seed decisions/dedup from any already-present passing sections (resume).
    if existing_cluster:
        for sk in section_keys:
            obj = existing_cluster.get(sk)
            if isinstance(obj, dict) and obj.get("text"):
                cluster[sk] = obj
                passing_texts.append(obj["text"])

    for sk in section_keys:
        if sk in cluster and cluster[sk].get("text"):
            run_log.append({"section": sk, "outcome": "skip_present", "attempts": 0,
                            "warnings": [], "tokens": 0})
            update_decisions(decisions, sk, profile, ranked_items_for_section(sk, profile))
            continue

        ranked = ranked_items_for_section(sk, profile)
        tests, traps = select_tests_traps(sk, profile, cluster_key)
        # Few-shot examples are NOT injected into the prompt (they drove verbatim
        # copying and re-introduced literal colour/fibre names). The full golden
        # set is retained only as the example-copy gate backstop below.
        gate_examples = examples_all.get(sk, [])
        dedup_hints = V.build_phrase_dedup_hints(
            {k: cluster[k]["text"] for k in cluster if isinstance(cluster.get(k), dict)}, limit=20)

        repair_note = None
        attempts = 0
        tokens = 0
        final_text = None
        final_intro = ""
        last_errors: list[str] = []
        last_warnings: list[str] = []

        while attempts <= MAX_GATE_RETRIES:
            attempts += 1
            prompt = build_section_prompt(sk, profile, ranked, tests, traps,
                                          decisions, dedup_hints, [], repair_note)
            try:
                out = generate_json(prompt, SYSTEM_PROMPT, SECTION_OUTPUT_SCHEMA)
            except Exception as e:  # network/quota errors bubble up to the CLI
                raise
            text = (out.get("text") or "").strip()
            intro = (out.get("sectionIntro") or "").strip()
            tokens += _approx_tokens(prompt, SYSTEM_PROMPT, text, intro)

            verdict = gate_section(text, sk, profile, passing_texts, gate_examples, intro=intro)
            last_errors = verdict["errors"]
            last_warnings = verdict["warnings"]
            if verdict["passed"]:
                final_text, final_intro = text, intro
                break
            repair_note = "; ".join(last_errors)
            log_fn(f"      {sk}: gate BLOCK (attempt {attempts}): {repair_note[:120]}")

        if final_text is None:
            quarantine[sk] = {"text": text, "errors": last_errors, "attempts": attempts}
            run_log.append({"section": sk, "outcome": "quarantined", "attempts": attempts,
                            "warnings": last_warnings, "tokens": tokens, "errors": last_errors})
            log_fn(f"    [Q] {sk} quarantined after {attempts} attempts")
            continue

        cluster[sk] = _assemble_section(final_text, final_intro, ranked, tests, traps)
        passing_texts.append(final_text)
        update_decisions(decisions, sk, profile, ranked)
        outcome = "pass" if attempts == 1 else "pass_after_retry"
        run_log.append({"section": sk, "outcome": outcome, "attempts": attempts,
                        "warnings": last_warnings, "tokens": tokens})
        log_fn(f"    [{'ok' if attempts==1 else 'ok*'}] {sk} ({len(final_text.split())}w)"
               + (f" warnings={len(last_warnings)}" if last_warnings else ""))

    # Holistic pass only if the full 16 sections all passed (no quarantine).
    if not quarantine and all(sk in cluster for sk in section_keys):
        try:
            hp = build_holistic_prompt(profile, cluster)
            hout = generate_json(hp, SYSTEM_PROMPT, HOLISTIC_OUTPUT_SCHEMA)
            _apply_holistic(cluster, profile, hout, run_log, log_fn)
        except Exception as e:
            log_fn(f"    holistic pass skipped (error): {e}")
            run_log.append({"section": "_holistic", "outcome": "error", "attempts": 1,
                            "warnings": [str(e)], "tokens": 0})
    else:
        run_log.append({"section": "_holistic", "outcome": "skipped_quarantine",
                        "attempts": 0, "warnings": [], "tokens": 0})

    return {"cluster": cluster, "quarantine": quarantine, "run_log": run_log}


def _assemble_section(text: str, intro: str, ranked: list[dict],
                      tests: list[str], traps: list[dict]) -> dict:
    obj: dict = {"text": text}
    if intro:
        obj["sectionIntro"] = intro
    if ranked:
        obj["rankedItems"] = [
            {k: v for k, v in {"name": r["name"], "role": r["role"],
                               "useCase": r.get("useCase")}.items() if v is not None}
            for r in ranked
        ]
    if tests:
        obj["tests"] = list(tests)
    if traps:
        obj["traps"] = [{"failure": t["failure"], "fix": t["fix"]} for t in traps]
    return obj


def _apply_holistic(cluster: dict, profile: CoarseProfile, hout: dict,
                    run_log: list[dict], log_fn) -> None:
    revised = {r["key"]: (r.get("text") or "").strip()
               for r in hout.get("revisedSections", []) if r.get("key")}
    examples_all = _load(SECTION_EXAMPLES_PATH)["section_examples"]
    changed = 0
    reverted = 0
    for sk in SECTION_KEYS:
        if sk not in cluster or sk not in revised:
            continue
        new_text = revised[sk]
        if not new_text or new_text == cluster[sk]["text"]:
            continue
        # Re-gate the revised text against the rest WITH the example-copy guard
        # and the section's own intro, so holistic cannot smuggle in a defect.
        others = [cluster[o]["text"] for o in SECTION_KEYS if o in cluster and o != sk]
        verdict = gate_section(new_text, sk, profile, others,
                               examples_all.get(sk, []), intro=cluster[sk].get("sectionIntro", ""))
        if verdict["passed"]:
            cluster[sk]["text"] = new_text
            changed += 1
        else:
            reverted += 1
    # Closing line, gated.
    closing = (hout.get("closing") or "").strip()
    cverdict = gate_closing(closing, profile)
    if cverdict["passed"]:
        cluster["closing"] = closing
    else:
        # Deterministic fallback closing that satisfies the gate.
        cluster["closing"] = (
            f"Your style guide is a map of your own instincts, built on {profile.core_formula}."
        )
        log_fn(f"    holistic closing failed gate ({cverdict['errors']}); used fallback")
    run_log.append({"section": "_holistic", "outcome": "applied", "attempts": 1,
                    "warnings": [f"revised {changed} sections, reverted {reverted}"],
                    "tokens": 0})
    log_fn(f"    holistic: revised {changed}, reverted {reverted}, closing set")


if __name__ == "__main__":
    # Dry build of one Slate section prompt (no network) for inspection.
    import sys
    from sg_profile import coarse_profile_from_key
    key = sys.argv[1] if len(sys.argv) > 1 else "venus_taurus__moon_capricorn__earth_dominant"
    section = sys.argv[2] if len(sys.argv) > 2 else "palette_narrative"
    prof = coarse_profile_from_key(key)
    ex = _load(SECTION_EXAMPLES_PATH)["section_examples"].get(section, [])
    ri = ranked_items_for_section(section, prof)
    tests, traps = select_tests_traps(section, prof)
    prompt = build_section_prompt(section, prof, ri, tests, traps,
                                  {"formula": prof.core_formula}, [], ex[:2])
    print(prompt)
