#!/usr/bin/env python3
"""
Cosmic Fit — Blueprint Narrative Backfill Script (WP3)

Generates AI paragraphs for blueprint_narrative_cache.json via the Gemini API.
One API call per section per archetype cluster.

Usage:
    python3 backfill_narratives.py \
        --dataset astrological_style_dataset.json \
        --output blueprint_narrative_cache.json \
        [--clusters representative|full] \
        [--resume]

API key loading order:
    1. --api-key
    2. GEMINI_API_KEY from local .env
    3. GEMINI_API_KEY from shell environment

Integrates with:
    - review_notes.json (skip approved, re-prompt needs_revision, regenerate rejected)
    - pause_signal.json (halt if paused == true)
"""

import argparse
import json
import os
import sys
import time
import re
from datetime import datetime, timezone
from pathlib import Path

try:
    import google.generativeai as genai
except ImportError:
    print("ERROR: google-generativeai package not installed.")
    print("Install with: pip install google-generativeai")
    sys.exit(1)


def load_local_env_file() -> None:
    """Loads GEMINI_API_KEY from a local .env file if present."""
    candidate_paths = [
        Path.cwd() / ".env",
        Path(__file__).resolve().parent / ".env",
    ]

    seen: set[Path] = set()
    for env_path in candidate_paths:
        if env_path in seen or not env_path.exists():
            continue
        seen.add(env_path)

        for raw_line in env_path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue

            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip("'\"")

            if key and key not in os.environ:
                os.environ[key] = value


def resolve_api_key(cli_value: str | None) -> str:
    """Resolves the Gemini API key from CLI args or environment."""
    if cli_value:
        return cli_value

    env_value = os.environ.get("GEMINI_API_KEY", "").strip()
    if env_value:
        return env_value

    print("ERROR: Gemini API key not found.")
    print("Set GEMINI_API_KEY in a local .env file or pass --api-key.")
    sys.exit(1)


def resolve_model_name(cli_value: str | None) -> str:
    """Resolves the Gemini model name from CLI args or environment."""
    if cli_value:
        return cli_value

    env_value = os.environ.get("GEMINI_MODEL", "").strip()
    if env_value:
        return env_value

    return "gemini-2.0-flash"


load_local_env_file()


# ─── Constants ─────────────────────────────────────────────────────────

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
    "style_core": "Style Core",
    "textures_good": "Textures — Good",
    "textures_bad": "Textures — Bad",
    "textures_sweet_spot": "Textures — Sweet Spot",
    "palette_narrative": "Palette",
    "occasions_work": "Occasions — Work",
    "occasions_intimate": "Occasions — Intimate",
    "occasions_daily": "Occasions — Daily",
    "hardware_metals": "Hardware — Metals",
    "hardware_stones": "Hardware — Stones",
    "hardware_tip": "Hardware — Tip",
    "accessory_1": "Accessory — Paragraph 1",
    "accessory_2": "Accessory — Paragraph 2",
    "accessory_3": "Accessory — Paragraph 3",
    "pattern_narrative": "Pattern",
    "pattern_tip": "Pattern — Tip",
}

BANNED_WORDS = [
    "delve", "tapestry", "resonate", "elevate", "curate", "embark",
    "multifaceted", "realm", "robust", "leverage", "utilize", "harness",
    "holistic", "synergy", "paradigm", "nuanced", "myriad",
]

HEDGING_PHRASES = ["you might", "perhaps", "maybe", "possibly"]

ZODIAC_SIGNS = [
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
]

ELEMENTS = ["fire", "earth", "air", "water"]

SIGN_ELEMENTS = {
    "aries": "fire", "taurus": "earth", "gemini": "air", "cancer": "water",
    "leo": "fire", "virgo": "earth", "libra": "air", "scorpio": "water",
    "sagittarius": "fire", "capricorn": "earth", "aquarius": "air", "pisces": "water",
}


# ─── System Prompt ─────────────────────────────────────────────────────

SYSTEM_PROMPT = """You are a fashion-insider style writer for Cosmic Fit, an astrological fashion guidance app.

WRITING VOICE:
- Direct second-person address: "You", "Your" — not suggestions, declarations
- Confident, slightly irreverent tone — fashion-insider, not generic lifestyle
- Sensory and tactile language: how fabrics feel, how garments move, how hardware sounds
- Short punchy sentences mixed with longer flowing ones
- Occasional humour and cultural references
- British English spelling (colour, centre, programme)
- No hedging: never use "you might", "perhaps", "maybe", "possibly"
- No astrology jargon in the output — the advice stands alone without explaining the chart

PARAGRAPH STRUCTURE:
- 3-6 sentences per paragraph
- Open with a direct statement or imperative
- Middle sentences provide specific, concrete style directives (fabric names, silhouette shapes, colour families)
- Close with a punchy one-liner or a reframe connecting back to identity
- Never explain astrology — the advice IS the translation

VOCABULARY TO USE FREELY:
silhouette, drape, hemline, frame, layer, texture, tactile, crisp, dense, fluid, structured, architectural, streamlined, polish, editorial, grounded, anchor, shield, intentional, modular, elevated, matte, high-shine, heritage, deconstructed, raw hem, pin-tuck, pleat, poplin, heavy-gauge, knit, weighted, brushed, hammered, oxidised, mineral-toned, sun-drenched, buttery

BANNED WORDS (never use these):
delve, tapestry, resonate, elevate, curate, embark, multifaceted, realm, robust, leverage, utilize, harness, holistic, synergy, paradigm, landscape (metaphorical), nuanced, myriad

CONSTRAINTS:
- Each paragraph must be 50-150 words
- Plain text only — no markdown, no bullet points, no headers
- Output ONLY the paragraph text, nothing else"""


# ─── Section-Specific Prompts ──────────────────────────────────────────

SECTION_PROMPTS = {
    "style_core": "Write a Style Core paragraph that defines this person's overall style presence, identity, and the feeling they project when they walk into a room.",
    "textures_good": "Write a paragraph about the textures and fabrics that work well for this person — what they should reach for and why those materials suit their energy.",
    "textures_bad": "Write a paragraph about the textures and fabrics this person should avoid — what clashes with their energy and why.",
    "textures_sweet_spot": "Write a short paragraph about this person's ideal texture sweet spot — the specific quality that makes a garment perfect for them.",
    "palette_narrative": "Write a paragraph describing this person's ideal colour palette — their core colours, accent possibilities, and the overall mood of their palette.",
    "occasions_work": "Write a paragraph about how this person should dress for work/professional settings.",
    "occasions_intimate": "Write a paragraph about how this person should dress for intimate or evening settings.",
    "occasions_daily": "Write a paragraph about how this person should dress for daily, off-duty life.",
    "hardware_metals": "Write a paragraph about the metals and hardware finishes that suit this person.",
    "hardware_stones": "Write a paragraph about the stones and gems that suit this person.",
    "hardware_tip": "Write a short practical tip about how this person should approach accessories and hardware.",
    "accessory_1": "Write the first of three accessory paragraphs: the philosophy of one anchor piece vs many small ones.",
    "accessory_2": "Write the second accessory paragraph: how accessories provide structure or reinforce the style identity.",
    "accessory_3": "Write the third accessory paragraph: the sensory experience of accessories (sound, weight, texture, scent).",
    "pattern_narrative": "Write a paragraph about this person's relationship with patterns — what works, what does not, and why.",
    "pattern_tip": "Write a short practical tip about how this person should use patterns.",
}

SECTION_EXAMPLES = {
    "style_core": [
        "Your presence is a study in precision and discipline. It is a look of sharp edges and clear boundaries. You lead with clean structure and a composed intensity. You do not just walk into a room; you occupy it with a focused authority that feels immediately powerful.",
        "Your presence works best when you treat your wardrobe as a public language. While you value the heavy and the settled, you use those qualities to set a standard for the people around you. You move through a room with the composure of someone who is teaching others how to appreciate quality. Your style works best when it feels like a long-term social legacy.",
    ],
    "textures_good": [
        "You need materials that feel like armour. If a fabric feels sharp and engineered, it is probably for you. Crisp poplin, raw denim, and structured wool hold their shape regardless of what you are doing. These textures reflect how disciplined you are. You require surfaces that are smooth, cold, and incredibly durable to match your internal focus.",
        "Go for fabrics with actual weight and integrity. Heavy gauge silks that feel cool and substantial provide the right anchor. Organic wools offer a proper architectural frame. Leather that is buttery and gains character with age belongs in your collection. They ground you, make you feel secure, and still look polished.",
    ],
    "textures_bad": [
        "Anything fluffy or overly romantic is a mismatch for your energy. Avoid flimsy jerseys or cheap lace that lacks structure. If a fabric feels like it is trying to be cute or soft, it will clash with how controlled you are. You are far too precise for a messy or wrinkled silhouette.",
    ],
    "textures_sweet_spot": [
        "The stiff and the sharp. You want clothes that feel like a uniform. If a piece does not encourage you to stand with more alignment the moment you put it on, it is not doing its job.",
    ],
    "palette_narrative": [
        "Your core colours are midnight, shadow, and ink. These deepest blacks and charcoal greys create a monochromatic shield. This allows your focus and sharp features to take centre stage. The drama comes from the cut of the garment rather than the pigment.",
    ],
    "occasions_work": [
        "Sharp tailoring and starched lines are your signature. You want to look like the most competent person in the building. A heavy overcoat or a structured layer is essential for your authority.",
    ],
    "occasions_intimate": [
        "When you relax, keep it sleek and streamlined. You look capable, not soft. A dark silk separate or a slim knit provides mystery without losing control. Aim for intense, focused attention.",
    ],
    "occasions_daily": [
        "Even off-duty, things need to feel deliberate and put together. High-quality dark denim and a structured jacket are essential tools. You move like someone with a clear destination. Everything has a purpose and nothing looks accidental.",
    ],
    "hardware_metals": [
        "You need cold power. Look for polished silver, surgical steel, or blackened titanium. Yellow gold often looks too warm for your icy mix. You want hardware that looks industrial or ancient. Sharp edges and high-shine surfaces that feel clinical are your best match.",
    ],
    "hardware_stones": [
        "Choose stones that look like they hold secrets. Black onyx and obsidian are perfect. You want stones that are dark at first glance but show their complexity when you look closer.",
    ],
    "hardware_tip": [
        "Precision is your law. One sharp piece: like a steel watch or a geometric signet ring: is all you need. Accessories work as hardware: functional, weighty, and intentional.",
    ],
    "accessory_1": [
        "One significant piece carries more weight than five minor ones. Whether it is a heavy steel watch or a structured leather case, let that item be the anchor. This creates a focal point that allows the rest of your look to stay quiet.",
    ],
    "accessory_2": [
        "Accessories are where you introduce your most rigid lines. While your clothes provide the shell, your accessories are the steel reinforcements. A belt with a heavy silver buckle acts as the final word on your discipline.",
    ],
    "accessory_3": [
        "Consider the click and the weight. The sound of a heavy watch being buckled is part of your daily ritual. You are not just decorating your body. You are setting the tone for the day ahead.",
    ],
    "pattern_narrative": [
        "Patterns are often a distraction. If you use them, they need to be as disciplined as you are. You do not do whimsical. You do structural.",
    ],
    "pattern_tip": [
        "Keep it monochromatic. If you are wearing a pattern, make sure the colours stay within the same dark family. A black-on-charcoal pinstripe is your peak. It provides detail while keeping your silhouette intact.",
    ],
}


# ─── Validation ────────────────────────────────────────────────────────

def validate_paragraph(text: str) -> dict:
    """Validates a paragraph against the quality rules from the spec."""
    words = text.split()
    word_count = len(words)
    lower = text.lower()

    found_banned = [w for w in BANNED_WORDS if w in lower]
    # Special case: "landscape" only banned in metaphorical use — flag all, reviewer decides
    if "landscape" in lower:
        found_banned.append("landscape (flagged — reviewer decides if metaphorical)")

    found_hedging = [p for p in HEDGING_PHRASES if p in lower]

    has_second_person = any(marker in text for marker in ["You", "Your", "you", "your"])
    has_declarative = not text.strip().endswith("?")

    return {
        "word_count": word_count,
        "length_ok": 50 <= word_count <= 150,
        "banned_words": found_banned,
        "hedging_phrases": found_hedging,
        "has_second_person": has_second_person,
        "has_declarative": has_declarative,
        "passed": (
            50 <= word_count <= 150
            and len(found_banned) == 0
            and len(found_hedging) == 0
            and has_second_person
            and has_declarative
        ),
    }


# ─── Cluster Key Generation ───────────────────────────────────────────

def generate_representative_clusters() -> list[str]:
    """Generates ~192 representative cluster keys."""
    moon_reps = {
        "aries": "aries", "leo": "aries", "sagittarius": "aries",
        "taurus": "taurus", "virgo": "taurus", "capricorn": "taurus",
        "gemini": "gemini", "libra": "gemini", "aquarius": "gemini",
        "cancer": "cancer", "scorpio": "cancer", "pisces": "cancer",
    }
    keys = set()
    for venus in ZODIAC_SIGNS:
        for moon in ZODIAC_SIGNS:
            moon_rep = moon_reps[moon]
            for element in ELEMENTS:
                keys.add(f"venus_{venus}__moon_{moon_rep}__{element}_dominant")
    return sorted(keys)


def generate_full_clusters() -> list[str]:
    """Generates all 576 cluster keys."""
    keys = []
    for venus in ZODIAC_SIGNS:
        for moon in ZODIAC_SIGNS:
            for element in ELEMENTS:
                keys.append(f"venus_{venus}__moon_{moon}__{element}_dominant")
    return keys


# ─── Archetype Description ─────────────────────────────────────────────

def describe_archetype(cluster_key: str, dataset: dict) -> str:
    """Builds a style-focused description of the archetype for the prompt.

    Includes a note about house/sect overlay integration so AI-generated
    base narratives remain general enough for deterministic overlays to
    blend naturally at runtime.
    """
    parts = cluster_key.split("__")
    if len(parts) != 3:
        return f"Archetype: {cluster_key}"

    venus_key = parts[0]  # e.g. "venus_scorpio"
    moon_key = parts[1]   # e.g. "moon_capricorn"
    element_part = parts[2]  # e.g. "fire_dominant"

    venus_sign = venus_key.replace("venus_", "").title()
    moon_sign = moon_key.replace("moon_", "").title()
    element = element_part.replace("_dominant", "").title()

    lines = [
        "Archetype configuration:",
        f"  Venus: {venus_sign} (aesthetic taste)",
        f"  Moon: {moon_sign} (comfort style)",
        f"  Dominant element: {element} (energetic tone)",
        "",
        "  Note: This archetype's narratives will be combined at runtime with house-specific",
        "  and sect-specific overlays. Write for the general archetype without assuming",
        "  specific house placements or day/night chart.",
    ]

    ps = dataset.get("planet_sign", {})
    if venus_key in ps:
        entry = ps[venus_key]
        lines.append(f"Style philosophy: {entry.get('style_philosophy', 'N/A')}")
        textures = entry.get("textures", {})
        if textures.get("good"):
            lines.append(f"Good textures: {', '.join(textures['good'][:4])}")
        colours = entry.get("colours", {})
        primary = colours.get("primary", [])
        if primary:
            names = [c["name"] for c in primary[:3]]
            lines.append(f"Core colours: {', '.join(names)}")

    if moon_key in ps:
        entry = ps[moon_key]
        lines.append(f"Moon style feel: {entry.get('style_philosophy', 'N/A')}")

    eb = dataset.get("element_balance", {})
    elem_key = element_part
    if elem_key in eb:
        lines.append(f"Element energy: {eb[elem_key].get('overall_energy', 'N/A')}")

    return "\n".join(lines)


# ─── Gemini API Call ───────────────────────────────────────────────────

def generate_paragraph(
    model,
    section_key: str,
    cluster_key: str,
    archetype_desc: str,
    revision_note: str | None = None,
) -> str:
    """Makes a single Gemini API call for one section of one cluster."""
    section_prompt = SECTION_PROMPTS.get(section_key, f"Write a paragraph for the {section_key} section.")
    examples = SECTION_EXAMPLES.get(section_key, [])

    user_prompt_parts = [
        f"Archetype configuration:\n{archetype_desc}",
        f"\nSection: {SECTION_DISPLAY.get(section_key, section_key)}",
        f"\nTask: {section_prompt}",
    ]

    if examples:
        user_prompt_parts.append("\nExample paragraphs in the target voice:")
        for i, ex in enumerate(examples, 1):
            user_prompt_parts.append(f"\nExample {i}: {ex}")

    if revision_note:
        user_prompt_parts.append(f"\nRevision guidance from reviewer: {revision_note}")

    user_prompt = "\n".join(user_prompt_parts)

    try:
        response = model.generate_content(
            [
                {"role": "user", "parts": [user_prompt]},
            ]
        )
        return response.text.strip()
    except Exception as e:
        print(f"    ERROR generating {section_key}: {e}")
        return ""


# ─── Pause Signal ──────────────────────────────────────────────────────

def check_pause(output_dir: str) -> bool:
    """Returns True if pause_signal.json exists and paused == true."""
    path = os.path.join(output_dir, "pause_signal.json")
    if not os.path.exists(path):
        return False
    try:
        with open(path) as f:
            data = json.load(f)
        if data.get("paused"):
            reason = data.get("reason", "unknown")
            print(f"\n⏸  Pipeline paused: {reason}")
            return True
    except (json.JSONDecodeError, IOError):
        pass
    return False


# ─── Main ──────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Cosmic Fit Blueprint Narrative Backfill")
    parser.add_argument("--api-key", help="Gemini API key (overrides .env / environment)")
    parser.add_argument("--dataset", required=True, help="Path to astrological_style_dataset.json")
    parser.add_argument("--output", required=True, help="Path to blueprint_narrative_cache.json")
    parser.add_argument("--clusters", choices=["representative", "full"], default="representative",
                        help="Cluster set to generate (default: representative)")
    parser.add_argument("--resume", action="store_true",
                        help="Resume from existing output file (skip already-generated)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print plan without making API calls")
    parser.add_argument("--limit", type=int, default=0,
                        help="Max clusters to generate (0 = all). Use with a small number to test quality.")
    parser.add_argument("--model",
                        help="Gemini model name (overrides .env / environment; default: gemini-2.0-flash)")
    args = parser.parse_args()
    api_key = resolve_api_key(args.api_key)
    model_name = resolve_model_name(args.model)

    # Load dataset
    with open(args.dataset) as f:
        dataset = json.load(f)
    print(f"Loaded dataset with {len(dataset.get('planet_sign', {}))} planet-sign entries")

    # Load or initialise cache
    cache: dict[str, dict[str, str]] = {}
    if args.resume and os.path.exists(args.output):
        with open(args.output) as f:
            cache = json.load(f)
        print(f"Resuming with {len(cache)} existing clusters")

    # Load review notes if present
    output_dir = os.path.dirname(os.path.abspath(args.output))
    review_path = os.path.join(output_dir, "review_notes.json")
    review_notes: dict = {}
    if os.path.exists(review_path):
        with open(review_path) as f:
            review_notes = json.load(f)
        print(f"Loaded review notes for {len(review_notes)} clusters")

    # Generate cluster keys
    if args.clusters == "full":
        clusters = generate_full_clusters()
    else:
        clusters = generate_representative_clusters()
    if args.limit > 0:
        clusters = clusters[:args.limit]

    print(f"Target clusters: {len(clusters)}")
    print(f"Sections per cluster: {len(SECTION_KEYS)}")
    print(f"Total paragraphs: {len(clusters) * len(SECTION_KEYS)}")

    if args.dry_run:
        print("\n[DRY RUN] Would generate paragraphs for:")
        for key in clusters:
            print(f"  {key}")
        return

    # Configure Gemini
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(
        model_name=model_name,
        system_instruction=SYSTEM_PROMPT,
    )

    # Backfill loop
    total_generated = 0
    total_skipped = 0
    total_failed = 0
    validation_failures = 0

    for ci, cluster_key in enumerate(clusters):
        if check_pause(output_dir):
            print("Saving progress and exiting...")
            break

        if cluster_key not in cache:
            cache[cluster_key] = {}

        archetype_desc = describe_archetype(cluster_key, dataset)
        cluster_review = review_notes.get(cluster_key, {})

        print(f"\n[{ci+1}/{len(clusters)}] {cluster_key}")

        for section_key in SECTION_KEYS:
            # Check review status
            section_review = cluster_review.get(section_key, {})
            status = section_review.get("status", "")

            if status == "approved":
                total_skipped += 1
                continue

            # If content exists and no review entry, preserve (unreviewed)
            if section_key in cache[cluster_key] and cache[cluster_key][section_key] and not status:
                total_skipped += 1
                continue

            revision_note = None
            if status == "needs_revision":
                revision_note = section_review.get("note", "")

            # Generate
            text = generate_paragraph(
                model, section_key, cluster_key, archetype_desc, revision_note
            )

            if not text:
                total_failed += 1
                print(f"    FAILED: {section_key}")
                continue

            # Validate
            vr = validate_paragraph(text)
            status_icon = "✓" if vr["passed"] else "⚠"
            print(f"    {status_icon} {section_key} ({vr['word_count']}w)")

            if not vr["passed"]:
                validation_failures += 1
                if vr["banned_words"]:
                    print(f"      Banned: {', '.join(vr['banned_words'])}")
                if vr["hedging_phrases"]:
                    print(f"      Hedging: {', '.join(vr['hedging_phrases'])}")
                if not vr["length_ok"]:
                    print(f"      Length: {vr['word_count']} words (need 50-150)")

            cache[cluster_key][section_key] = text
            total_generated += 1

            # Save after every paragraph so the review tool can pick it up live
            with open(args.output, "w") as f:
                json.dump(cache, f, indent=2, ensure_ascii=False)

            # Rate limiting
            time.sleep(0.5)

    # Final save
    with open(args.output, "w") as f:
        json.dump(cache, f, indent=2, ensure_ascii=False)

    print(f"\n{'='*60}")
    print(f"COMPLETE")
    print(f"  Generated:  {total_generated}")
    print(f"  Skipped:    {total_skipped}")
    print(f"  Failed:     {total_failed}")
    print(f"  Validation warnings: {validation_failures}")
    print(f"  Output: {args.output}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
