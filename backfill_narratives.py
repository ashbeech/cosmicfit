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

# ─── Retry / Timeout ──────────────────────────────────────────────────

MAX_RETRIES = 3
REQUEST_TIMEOUT = 30
RETRY_BACKOFF = [2, 4, 8]
MAX_RATE_LIMIT_WAITS = 10
MAX_429_WAIT_SEC = 300
RATE_LIMIT_BUFFER_SEC = 5


class QuotaExhaustedError(Exception):
    """Raised when the Gemini API quota is exhausted and the run should stop."""


# ─── Placeholder Vocabulary ────────────────────────────────────────────

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

ALLOWED_PLACEHOLDERS = {
    *[f"core_colour_{i}" for i in range(1, 5)],
    *[f"accent_colour_{i}" for i in range(1, 3)],
    *[f"recommended_pattern_{i}" for i in range(1, 5)],
    *[f"avoid_pattern_{i}" for i in range(1, 3)],
    *[f"metal_{i}" for i in range(1, 4)],
    *[f"stone_{i}" for i in range(1, 4)],
    *[f"texture_good_{i}" for i in range(1, 5)],
    *[f"texture_bad_{i}" for i in range(1, 4)],
    *[f"sweet_spot_keyword_{i}" for i in range(1, 3)],
}

SECTION_ALLOWED_PLACEHOLDERS: dict[str, set[str]] = {
    "palette_narrative": {f"core_colour_{i}" for i in range(1, 5)} | {f"accent_colour_{i}" for i in range(1, 3)},
    "pattern_narrative": {f"recommended_pattern_{i}" for i in range(1, 5)} | {f"avoid_pattern_{i}" for i in range(1, 3)},
    "pattern_tip": {f"recommended_pattern_{i}" for i in range(1, 5)} | {f"avoid_pattern_{i}" for i in range(1, 3)},
    "hardware_metals": {f"metal_{i}" for i in range(1, 4)},
    "hardware_stones": {f"stone_{i}" for i in range(1, 4)},
    "hardware_tip": {f"metal_{i}" for i in range(1, 4)} | {f"stone_{i}" for i in range(1, 4)},
    "textures_good": {f"texture_good_{i}" for i in range(1, 5)},
    "textures_bad": {f"texture_bad_{i}" for i in range(1, 4)},
    "textures_sweet_spot": {f"sweet_spot_keyword_{i}" for i in range(1, 3)} | {f"texture_good_{i}" for i in range(1, 5)},
}

SECTION_PLACEHOLDER_REQUIREMENTS: dict[str, list[tuple[str, int]]] = {
    "palette_narrative": [("any", 3)],
    "textures_good": [("texture_good_", 2)],
    "textures_bad": [("texture_bad_", 2)],
    "textures_sweet_spot": [("sweet_spot_keyword_", 1)],
    "hardware_metals": [("metal_", 2)],
    "hardware_stones": [("stone_", 2)],
    "hardware_tip": [("any", 1)],
    "pattern_narrative": [("recommended_pattern_", 2), ("avoid_pattern_", 1)],
    "pattern_tip": [("any", 1)],
}

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
- Write like a stylish, culturally switched-on woman in her thirties who actually knows clothes
- Sound socially believable, observant, and human — not like ad copy, a trend report, or a sci-fi moodboard
- Direct second-person address: "You", "Your" — confident, but not barked orders in every sentence
- Fashion-literate and tactile: mention fabrics, construction, silhouette, movement, hardware, and finish when they genuinely fit
- Let the voice feel lived-in and knowing, like someone with taste talking to a friend, not a brand manifesto
- Short punchy sentences are welcome, but vary the rhythm; not every line should try to sound quotable
- Occasional humour and cultural texture are welcome when natural
- British English spelling (colour, centre, programme)
- No hedging: never use "you might", "perhaps", "maybe", "possibly"
- No astrology jargon in the output — the advice stands alone without explaining the chart

PARAGRAPH STRUCTURE:
- 3-6 sentences per paragraph
- Open with an observation, a judgement, or a clear point of view — not always an imperative
- Middle sentences should give specific, concrete style guidance (fabric names, silhouette shapes, colour families, styling logic)
- Close with a line that feels grounded and memorable, not like a slogan
- Never explain astrology — the advice IS the translation

STYLE RULES:
- Prefer concrete judgement over abstract fashion poetry
- Use elevated fashion language sparingly and only when it earns its place
- Vary sentence openings; do not keep starting with commands like "Demand", "Ditch", "Forget", "Treat", "Anchor"
- Avoid repeated crutch phrases such as "you require", "zero patience", "for the future", "editorial polish", "protective shield"
- Do not recycle the same colours, fabrics, or motifs in every paragraph unless they are truly essential to this archetype
- Keep the writing grounded in how a person would actually dress, shop, move, and be perceived
- One vivid image is enough; do not stack metaphors until the paragraph turns into campaign copy

DO NOT SOUND LIKE:
- a luxury brand campaign
- a futurist manifesto
- a generic AI stylist
- a list of aesthetic keywords stitched into sentences
- someone trying to sound fashionable rather than someone who actually is
- every paragraph at maximum intensity

BANNED WORDS (never use these):
delve, tapestry, resonate, elevate, curate, embark, multifaceted, realm, robust, leverage, utilize, harness, holistic, synergy, paradigm, landscape (metaphorical), nuanced, myriad

CONSTRAINTS:
- Each paragraph must be 50-150 words
- Plain text only — no markdown, no bullet points, no headers
- Output ONLY the paragraph text, nothing else"""


# ─── Section-Specific Prompts ──────────────────────────────────────────

SECTION_PROMPTS = {
    # ── Group A: general prose, no placeholders ──
    "style_core": (
        "Write a Style Core paragraph that defines this person's overall style presence, identity, and the feeling they project when they walk into a room. "
        "Do NOT mention specific colour names, pattern names, metal names, stone names, or texture names. Keep advice general and directional."
    ),
    "occasions_work": (
        "Write a paragraph about how this person should dress for work/professional settings. "
        "Do NOT mention specific colour names, pattern names, metal names, stone names, or texture names. Keep advice general and directional."
    ),
    "occasions_intimate": (
        "Write a paragraph about how this person should dress for intimate or evening settings. "
        "Do NOT mention specific colour names, pattern names, metal names, stone names, or texture names. Keep advice general and directional."
    ),
    "occasions_daily": (
        "Write a paragraph about how this person should dress for daily, off-duty life. "
        "Do NOT mention specific colour names, pattern names, metal names, stone names, or texture names. Keep advice general and directional."
    ),
    "accessory_1": (
        "Write the first of three accessory paragraphs: the philosophy of one anchor piece vs many small ones. "
        "Keep the prose general and sensory. You may use category-level examples such as belts, bags, straps, watches, rings, clasps, and leather, "
        "but do not use placeholders and do not reference specific metals, stones, or colours by name."
    ),
    "accessory_2": (
        "Write the second accessory paragraph: how accessories provide structure or reinforce the style identity. "
        "Keep the prose general and sensory. You may use category-level examples such as belts, bags, straps, watches, rings, clasps, and leather, "
        "but do not use placeholders and do not reference specific metals, stones, or colours by name."
    ),
    "accessory_3": (
        "Write the third accessory paragraph: the sensory experience of accessories (sound, weight, texture, scent). "
        "Keep the prose general and sensory. You may use category-level examples such as belts, bags, straps, watches, rings, clasps, and leather, "
        "but do not use placeholders and do not reference specific metals, stones, or colours by name."
    ),
    # ── Group B: templated with placeholders ──
    "palette_narrative": (
        "Write a paragraph describing this person's ideal colour palette — their core colours, accent possibilities, and the overall mood of their palette. "
        "Use these placeholders for colours: {core_colour_1}, {core_colour_2}, {core_colour_3}, {core_colour_4}, {accent_colour_1}, {accent_colour_2}. "
        "Do NOT invent colour names outside these placeholders. You do not need to use every placeholder, but use at least three."
    ),
    "textures_good": (
        "Write a paragraph about the textures and fabrics that work well for this person — what they should reach for and why those materials suit their energy. "
        "Use these placeholders for textures: {texture_good_1}, {texture_good_2}, {texture_good_3}, {texture_good_4}. "
        "Do NOT invent specific fabric or texture names outside these placeholders. Use at least two."
    ),
    "textures_bad": (
        "Write a paragraph about the textures and fabrics this person should avoid — what clashes with their energy and why. "
        "Use these placeholders for textures to avoid: {texture_bad_1}, {texture_bad_2}, {texture_bad_3}. "
        "Do NOT invent specific fabric or texture names outside these placeholders. Use at least two."
    ),
    "textures_sweet_spot": (
        "Write a short paragraph about this person's ideal texture sweet spot — the specific quality that makes a garment perfect for them. "
        "Use these placeholders for sweet-spot keywords: {sweet_spot_keyword_1}, {sweet_spot_keyword_2}. "
        "You may also reference {texture_good_1} or {texture_good_2} if relevant. Do NOT invent specific texture names outside these placeholders."
    ),
    "hardware_metals": (
        "Write a paragraph about the metals and hardware finishes that suit this person. "
        "Use these placeholders for metals: {metal_1}, {metal_2}, {metal_3}. "
        "Do NOT invent specific metal names outside these placeholders. Use at least two."
    ),
    "hardware_stones": (
        "Write a paragraph about the stones and gems that suit this person. "
        "Use these placeholders for stones: {stone_1}, {stone_2}, {stone_3}. "
        "Do NOT invent specific stone or gem names outside these placeholders. Use at least two."
    ),
    "hardware_tip": (
        "Write a short practical tip about how this person should approach accessories and hardware. "
        "You may reference {metal_1} or {stone_1} if it strengthens the tip. Do NOT invent specific metal or stone names outside placeholders."
    ),
    "pattern_narrative": (
        "Write a paragraph about this person's relationship with patterns — what works, what does not, and why. "
        "Use these placeholders for patterns: {recommended_pattern_1}, {recommended_pattern_2}, {recommended_pattern_3}, {recommended_pattern_4}, "
        "{avoid_pattern_1}, {avoid_pattern_2}. "
        "Do NOT invent specific pattern names outside these placeholders. Use at least two recommended and one avoid."
    ),
    "pattern_tip": (
        "Write a short practical tip about how this person should use patterns. "
        "You may reference {recommended_pattern_1} or {recommended_pattern_2} if it strengthens the tip. "
        "Do NOT invent specific pattern names outside placeholders."
    ),
}

SECTION_EXAMPLES = {
    "style_core": [
        "Your presence is a study in precision and discipline. It is a look of sharp edges and clear boundaries. You lead with clean structure and a composed intensity. You do not just walk into a room; you occupy it with a focused authority that feels immediately powerful.",
        "Your presence works best when you treat your wardrobe as a public language. While you value the heavy and the settled, you use those qualities to set a standard for the people around you. You move through a room with the composure of someone who is teaching others how to appreciate quality. Your style works best when it feels like a long-term social legacy.",
        "Your presence works best when it looks bright, centred, and completely polished. It is an aesthetic of radiant precision. While you have a natural ability to take up space, you do it through the quality of your craft rather than shouting for attention. Your style works best when it is clean, high-end, and perfectly maintained.",
    ],
    "textures_good": [
        "You need materials that feel like armour. If a fabric feels sharp and engineered, it is probably for you. {texture_good_1} and {texture_good_2} hold their shape regardless of what you are doing. These textures reflect how disciplined you are. Reach for {texture_good_3} when you need surfaces that are smooth, cold, and incredibly durable.",
        "Go for fabrics with actual weight and integrity. {texture_good_1} provides the right anchor, while {texture_good_2} offers a proper architectural frame. {texture_good_3} that gains character with age belongs in your collection. They ground you, make you feel secure, and still look polished.",
        "You need a mix of the intellectual and the indestructible. Go for {texture_good_1} that does not wrinkle, {texture_good_2} with a dry feel, and {texture_good_3}. Because you are constantly moving, you need fabrics that snap back into shape.",
    ],
    "textures_bad": [
        "Anything fluffy or overly romantic is a mismatch for your energy. Avoid {texture_bad_1} or {texture_bad_2} that lacks structure. If a fabric feels like it is trying to be cute or soft, it will clash with how controlled you are. You are far too precise for a messy or wrinkled silhouette.",
        "Flimsy or disposable fabrics just do not suit you. If a material is scratchy or overly synthetic, it is a hard pass. {texture_bad_1} and {texture_bad_2} fight your natural movement and are a distraction. If you have to spend your whole day messing with a garment to make it sit right, it is draining your energy.",
        "Anything that looks tired or worn out is a hard pass. {texture_bad_1} that pills or loses its shape will make you feel off-beat. Avoid {texture_bad_2} that swamps your frame. If you have to spend your whole day messing with a garment because it sags or bags, it is draining your energy.",
    ],
    "textures_sweet_spot": [
        "The {sweet_spot_keyword_1} and the {sweet_spot_keyword_2}. You want clothes that feel like a uniform. If a piece does not encourage you to stand with more alignment the moment you put it on, it is not doing its job.",
        "Your absolute peak is a blend of {sweet_spot_keyword_1} and {sweet_spot_keyword_2}. Choose items that look high quality at a glance but feel like a secret luxury when touched. If it does not feel like a treat for your skin, it does not belong in your wardrobe.",
        "The {sweet_spot_keyword_1} combined with {sweet_spot_keyword_2}. You want a jacket with a sharp, disciplined shoulder but a fabric that moves as fast as you do. If a piece does not deliver both qualities, it does not belong in your wardrobe.",
    ],
    "palette_narrative": [
        "Your core colours are {core_colour_1}, {core_colour_2}, and {core_colour_3}. These create a monochromatic shield that allows your focus and sharp features to take centre stage. Introduce {accent_colour_1} in small doses when you want a controlled flash of difference. The drama comes from the cut of the garment rather than the pigment.",
        "Your palette is rooted in {core_colour_1} and {core_colour_2}, with {core_colour_3} anchoring the base. These tones provide a stable foundation for your personality to shine through. {accent_colour_1} and {accent_colour_2} add seasonal flexibility without breaking the story.",
        "Your palette is built on agile neutrals punctuated by strategic high-contrast. Your base is {core_colour_1}, {core_colour_2}, and {core_colour_3}. These provide the solid structure you need. Use {accent_colour_1} in small, intentional places to keep the look moving.",
    ],
    "occasions_work": [
        "Sharp tailoring and clean lines are your signature. You want to look like the most competent person in the building. Authority comes from discipline, proportion, and a silhouette that never looks accidental.",
        "Lean into your architectural side. Use structure, restraint, and deliberate shape to settle into the room. You look best when you appear as the person who is definitely in charge without needing to overstate it.",
        "Go for polish with enough flexibility to move through the day. Your work look should feel authoritative but adaptable, like the person who already understands the brief and can still think on their feet.",
    ],
    "occasions_intimate": [
        "When you relax, keep it sleek and streamlined. You look capable, not vague. Aim for a mood that feels close-range, intentional, and quietly magnetic rather than overly softened.",
        "Soften the edges when the sun goes down. Keep the base composed, but let the overall impression feel more fluid, mysterious, and easy to read at close distance.",
        "This is where you introduce details that reward a second glance. You want a look that invites conversation without trying too hard, with enough intrigue to feel memorable and enough control to stay elegant.",
    ],
    "occasions_daily": [
        "Even off-duty, things need to feel deliberate and put together. You move like someone with a clear destination, so the overall impression should stay clean, purposeful, and free of clutter.",
        "Even casual looks need to look intentional. You can do relaxed, but it should never read as sloppy or half-finished. Aim for ease with a backbone.",
        "Lean into a daily look that feels prepared, mobile, and considered. You need to look like you are going somewhere important, even if you are only stepping out briefly. Every element should serve a purpose and hold the line.",
    ],
    "hardware_metals": [
        "You need cold power. {metal_1} is your foundation — it reads as sharp and intentional. Layer in {metal_2} for variety, and consider {metal_3} when you want something with a bit more weight. You want hardware that looks industrial or ancient.",
        "Your energy requires hardware with actual presence. {metal_1} provides the right anchor, while {metal_2} gives you warmth when you need it. Choose pieces in {metal_3} that feel like they have some history.",
        "Your hardware should be clinical and modern. {metal_1} is your default. {metal_2} works for evening and special occasions. You want details that look like they belong on a high-end instrument.",
    ],
    "hardware_stones": [
        "Choose stones that look like they hold secrets. {stone_1} is perfect for you. {stone_2} adds depth without being flashy. You want stones that are dark at first glance but show their complexity when you look closer.",
        "Skip the perfectly clear gems. You suit stones that look like they were pulled directly from the earth. {stone_1} and {stone_2} work best. {stone_3} adds a natural richness. These inclusions make the pieces feel alive and connected to you.",
        "Choose stones that suggest mental focus and clarity. {stone_1} and {stone_2} work best. You suit gems that have flashes of light or hidden depth, echoing your ability to see multiple sides of a situation at once.",
    ],
    "hardware_tip": [
        "Precision is your law. One sharp piece in {metal_1} — like a watch or a geometric signet ring — is all you need. Accessories work as hardware: functional, weighty, and intentional.",
        "One substantial anchor piece is always more powerful than a bunch of delicate items. Pick a signature in {metal_1} and let it be the focal point.",
        "The hardware should feel like a tool for a sharp mind. A watch in {metal_1} with a complex dial or a ring set with {stone_1} suits your energy. Precision over ornament always wins.",
    ],
    "accessory_1": [
        "One significant piece carries more weight than five minor ones. Whether it is a heavy watch or a structured leather case, let that item be the anchor. This creates a focal point that allows the rest of your look to stay quiet.",
        "One significant piece carries more weight than five minor ones. Whether it is a heavy watch or a perfectly made bag, let that item be the anchor. This creates a focal point that allows the rest of your look to stay quiet.",
        "One high-status accessory acts as your anchor. Because your clothes are often versatile and modular, you need one serious piece to signal your authority. This one piece finishes the look and gives you the confidence to move through any door.",
    ],
    "accessory_2": [
        "Accessories are where you introduce your most rigid lines. While your clothes provide the shell, your accessories are the reinforcements. A belt with a heavy buckle acts as the final word on your discipline.",
        "While your clothes might flow, your accessories should provide the structure. A stiff bag or a firm leather strap acts as the frame for your more fluid choices.",
        "Accessories are where you show off your attention to detail. While your clothes might be simple, your accessories should be flawless. A well-kept leather bag or a pair of polished shoes acts as the final proof of your high standards.",
    ],
    "accessory_3": [
        "Consider the click and the weight. The sound of a heavy watch being buckled is part of your daily ritual. You are not just decorating your body. You are setting the tone for the day ahead.",
        "Think about the sound and scent of your accessories. The weight of a heavy buckle or the specific smell of high-quality leather adds to the vibe. Style is a total sensory environment.",
        "Think about the light and the finish. The way a buckle catches the sun or the specific shine on a pair of leather loafers adds to the vibe. Style is about the total polished package.",
    ],
    "pattern_narrative": [
        "Patterns are often a distraction. If you use them, they need to be as disciplined as you are. {recommended_pattern_1} and {recommended_pattern_2} work because they mirror your precision. Avoid {avoid_pattern_1} — it fights your energy.",
        "You do not really do busy prints. Anything too frantic fights your energy and looks forced. Stick to {recommended_pattern_1} and {recommended_pattern_2}. Stay well away from {avoid_pattern_1} and {avoid_pattern_2}.",
        "You do not really do loud prints. Anything too chaotic fights your need for order and looks messy. Your patterns need to be small-scale, like {recommended_pattern_1} or {recommended_pattern_2}. Avoid {avoid_pattern_1} at all costs.",
    ],
    "pattern_tip": [
        "Keep it monochromatic. If you are wearing a {recommended_pattern_1}, make sure the colours stay within the same dark family. It provides detail while keeping your silhouette intact.",
        "Use {recommended_pattern_1} as a texture. A tonal version adds depth without screaming for attention. It is your secret weapon for looking interesting without trying too hard.",
        "Use {recommended_pattern_1} as a way to add a bit of texture to a monochrome look. Keeping the pattern limited to one area of your outfit helps you maintain focus and clarity.",
    ],
}


# ─── Validation ────────────────────────────────────────────────────────

STYLE_WARNING_PATTERNS = {
    "stock_opener": re.compile(r"^(Demand|Ditch|Forget|Treat|Anchor|Reach|Swap|Build|Keep|Wear)\b", re.IGNORECASE),
    "stock_phrase": re.compile(
        r"\b(you require|zero patience|for the future|editorial polish|protective shield|high-voltage|move as fast as|"
        r"architectural edge|demand materials|ditch the|treat your)\b",
        re.IGNORECASE,
    ),
}

TRACKED_MOTIF_WORDS = {
    "architectural", "editorial", "future", "futuristic", "technical", "neoprene",
    "heavy-gauge", "electric", "silver", "grey", "modular", "shield", "armour",
    "high-shine", "progressive"
}

VOICE_STOPWORDS = {
    "your", "you", "with", "that", "this", "they", "them", "from", "into", "because",
    "while", "where", "when", "have", "need", "look", "like", "their", "there", "these",
    "those", "will", "just", "than", "then", "what", "which", "about", "over", "under",
    "after", "before", "make", "more", "most", "less", "only", "really", "very",
}


def build_cluster_repetition_hints(existing_sections: dict[str, str]) -> list[str]:
    counts: dict[str, int] = {}
    for text in existing_sections.values():
        for token in re.findall(r"[a-z]+(?:-[a-z]+)?", text.lower()):
            if len(token) < 5 or token in VOICE_STOPWORDS:
                continue
            counts[token] = counts.get(token, 0) + 1
    repeated = [token for token, count in counts.items() if count >= 2]
    tracked_first = [token for token in repeated if token in TRACKED_MOTIF_WORDS]
    remainder = sorted(token for token in repeated if token not in TRACKED_MOTIF_WORDS)
    return (tracked_first + remainder)[:8]


def style_warnings(text: str, existing_cluster_texts: list[str] | None = None) -> list[str]:
    warnings: list[str] = []
    lower = text.lower()

    if STYLE_WARNING_PATTERNS["stock_opener"].search(text.strip()):
        warnings.append("Opens with an imperative command; voice may feel too barked.")

    stock_hits = STYLE_WARNING_PATTERNS["stock_phrase"].findall(text)
    if len(stock_hits) >= 2:
        warnings.append("Contains multiple stock prompt phrases; may sound templated.")

    motif_hits = {word for word in TRACKED_MOTIF_WORDS if word in lower}
    if len(motif_hits) >= 5:
        warnings.append("High motif density; may read like keyword-stacked fashion copy.")

    if existing_cluster_texts:
        existing_lower = " ".join(existing_cluster_texts).lower()
        repeated_cluster_words = sorted(
            word for word in TRACKED_MOTIF_WORDS
            if existing_lower.count(word) >= 2 and word in lower
        )
        if len(repeated_cluster_words) >= 3:
            warnings.append(
                "Repeats motifs already used heavily in this cluster: "
                + ", ".join(repeated_cluster_words[:5])
            )

    return warnings

def validate_template_placeholders(text: str, section_key: str) -> list[str]:
    """Validates placeholder usage for Group A / Group B section rules."""
    warnings: list[str] = []
    found_tokens = re.findall(r"\{([a-z_0-9]+)\}", text)

    if section_key in GROUP_A_SECTIONS:
        if found_tokens:
            warnings.append(
                f"Group A section contains placeholders (should have none): "
                + ", ".join(f"{{{t}}}" for t in found_tokens[:5])
            )
    elif section_key in GROUP_B_SECTIONS:
        if not found_tokens:
            warnings.append("Group B section contains zero placeholders (should have at least one).")
        allowed = SECTION_ALLOWED_PLACEHOLDERS.get(section_key, ALLOWED_PLACEHOLDERS)
        invalid = [t for t in found_tokens if t not in allowed]
        if invalid:
            warnings.append(
                f"Invalid placeholders for {section_key}: "
                + ", ".join(f"{{{t}}}" for t in invalid[:5])
            )
        unique_valid = {t for t in found_tokens if t in allowed}
        for family, minimum in SECTION_PLACEHOLDER_REQUIREMENTS.get(section_key, []):
            if family == "any":
                count = len(unique_valid)
                label = "allowed placeholders"
            else:
                count = len([t for t in unique_valid if t.startswith(family)])
                label = f"`{family}*` placeholders"
            if count < minimum:
                warnings.append(
                    f"{section_key} requires at least {minimum} distinct {label}; found {count}."
                )

    return warnings


def validate_paragraph(text: str, existing_cluster_texts: list[str] | None = None, section_key: str | None = None) -> dict:
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
    style_flags = style_warnings(text, existing_cluster_texts)

    placeholder_warnings: list[str] = []
    if section_key:
        placeholder_warnings = validate_template_placeholders(text, section_key)

    return {
        "word_count": word_count,
        "length_ok": 50 <= word_count <= 150,
        "banned_words": found_banned,
        "hedging_phrases": found_hedging,
        "has_second_person": has_second_person,
        "has_declarative": has_declarative,
        "style_warnings": style_flags,
        "placeholder_warnings": placeholder_warnings,
        "passed": (
            50 <= word_count <= 150
            and len(found_banned) == 0
            and len(found_hedging) == 0
            and has_second_person
            and has_declarative
            and len(placeholder_warnings) == 0
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


def _is_rate_limited(err: Exception) -> bool:
    """Check if the error is a 429 / RESOURCE_EXHAUSTED rate limit."""
    msg = str(err)
    return "429" in msg or "RESOURCE_EXHAUSTED" in msg


def _parse_retry_delay(err: Exception) -> int:
    """Extract server-suggested retry delay from error message, or 0."""
    match = re.search(r"retryDelay.*?(\d+)s", str(err))
    return int(match.group(1)) if match else 0


# ─── Gemini API Call ───────────────────────────────────────────────────

def generate_paragraph(
    model,
    section_key: str,
    cluster_key: str,
    archetype_desc: str,
    existing_sections: dict[str, str],
    revision_note: str | None = None,
) -> str:
    """Makes a single Gemini API call for one section of one cluster."""
    section_prompt = SECTION_PROMPTS.get(section_key, f"Write a paragraph for the {section_key} section.")
    examples = SECTION_EXAMPLES.get(section_key, [])
    repetition_hints = build_cluster_repetition_hints(existing_sections)

    user_prompt_parts = [
        f"Archetype configuration:\n{archetype_desc}",
        f"\nSection: {SECTION_DISPLAY.get(section_key, section_key)}",
        f"\nTask: {section_prompt}",
        "\nVoice target: stylish, natural, specific, and socially believable. "
        "This should feel like a very switched-on fashion astrologer talking like a real person, "
        "not a luxury campaign or a futurist monologue.",
        "\nImportant voice guardrails:",
        "- Do not overuse commands or slogan-y openings.",
        "- Do not stack the same fashion buzzwords over and over.",
        "- Keep the paragraph grounded in real clothing judgement and human behaviour.",
        "- If using vivid imagery, use one strong image and move on.",
    ]

    if repetition_hints:
        user_prompt_parts.append(
            "\nWords and motifs already used elsewhere in this cluster. Avoid leaning on them again unless truly necessary: "
            + ", ".join(repetition_hints)
        )

    if examples:
        user_prompt_parts.append("\nExample paragraphs in the target voice:")
        for i, ex in enumerate(examples, 1):
            user_prompt_parts.append(f"\nExample {i}: {ex}")

    if revision_note:
        user_prompt_parts.append(f"\nRevision guidance from reviewer: {revision_note}")

    user_prompt = "\n".join(user_prompt_parts)

    rate_limit_waits = 0
    attempt = 0

    while attempt < MAX_RETRIES:
        attempt += 1
        try:
            print(f"      {section_key} (attempt {attempt}/{MAX_RETRIES})...", end="", flush=True)
            response = model.generate_content(
                [{"role": "user", "parts": [user_prompt]}],
                request_options={"timeout": REQUEST_TIMEOUT, "retry": None},
            )
            print(" ok")
            return response.text.strip()

        except Exception as e:
            msg = str(e)
            print(f" error: {msg}")

            if _is_rate_limited(e):
                if "limit: 0" in msg:
                    print(f"    Model unavailable on current API tier (limit: 0)")
                    raise QuotaExhaustedError(msg)

                retry_sec = _parse_retry_delay(e)
                if (
                    retry_sec > 0
                    and retry_sec <= MAX_429_WAIT_SEC
                    and rate_limit_waits < MAX_RATE_LIMIT_WAITS
                ):
                    wait_sec = retry_sec + RATE_LIMIT_BUFFER_SEC
                    rate_limit_waits += 1
                    attempt -= 1
                    print(f"      Rate limited — waiting {wait_sec}s "
                          f"(wait {rate_limit_waits}/{MAX_RATE_LIMIT_WAITS})...")
                    time.sleep(wait_sec)
                    continue

                print(f"    Quota exhausted — no parseable retry delay or max waits reached")
                raise QuotaExhaustedError(msg)

            if attempt < MAX_RETRIES:
                backoff = RETRY_BACKOFF[attempt - 1]
                print(f"      retrying in {backoff}s...")
                time.sleep(backoff)

    print(f"    FAILED after {MAX_RETRIES} attempts: {section_key}")
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
            if status in ("needs_revision", "rejected"):
                revision_note = section_review.get("note", "") or None

            # Generate
            existing_sections = {
                key: value
                for key, value in cache[cluster_key].items()
                if key != section_key and value
            }
            try:
                text = generate_paragraph(
                    model, section_key, cluster_key, archetype_desc, existing_sections, revision_note
                )
            except QuotaExhaustedError as e:
                print(f"\n{'='*60}")
                print(f"QUOTA EXHAUSTED — saving progress and stopping.")
                print(f"  {e}")
                print(f"  Re-run with --resume to continue later.")
                print(f"{'='*60}")
                with open(args.output, "w") as f:
                    json.dump(cache, f, indent=2, ensure_ascii=False)
                sys.exit(1)

            if not text:
                total_failed += 1
                print(f"    FAILED: {section_key}")
                continue

            # Validate
            vr = validate_paragraph(text, list(existing_sections.values()), section_key=section_key)
            status_icon = "✓" if vr["passed"] else "⚠"
            print(f"    {status_icon} {section_key} ({vr['word_count']}w)")

            if not vr["passed"] or vr["style_warnings"] or vr["placeholder_warnings"]:
                validation_failures += 1
                if vr["banned_words"]:
                    print(f"      Banned: {', '.join(vr['banned_words'])}")
                if vr["hedging_phrases"]:
                    print(f"      Hedging: {', '.join(vr['hedging_phrases'])}")
                if not vr["length_ok"]:
                    print(f"      Length: {vr['word_count']} words (need 50-150)")
                for warning in vr["style_warnings"]:
                    print(f"      Voice: {warning}")
                for warning in vr["placeholder_warnings"]:
                    print(f"      Placeholder: {warning}")

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
