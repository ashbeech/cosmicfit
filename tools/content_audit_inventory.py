#!/usr/bin/env python3
"""
Cosmic Fit — Content Audit Inventory

Defines per-field quality rules for every user-visible Style Guide string,
and provides walker functions that yield (content_id, text, rule) tuples
for the audit engine to check.
"""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Generator

# ─── Reuse review_tool constants ───────────────────────────────────────

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

GROUP_A_SECTIONS = {"style_core", "occasions_work", "occasions_intimate",
                    "occasions_daily", "accessory_1", "accessory_2", "accessory_3"}
GROUP_B_SECTIONS = {"textures_good", "textures_bad", "textures_sweet_spot",
                    "palette_narrative", "hardware_metals", "hardware_stones",
                    "hardware_tip", "pattern_narrative", "pattern_tip"}


# ─── Content format expectations ───────────────────────────────────────

@dataclass(frozen=True)
class FieldRule:
    """Quality expectations for one auditable field type."""
    expected_format: str          # full_sentence | actionable_bullet | keyword | phrase | template | paragraph
    min_words: int = 1
    max_words: int = 999
    requires_second_person: bool = False
    requires_terminal_period: bool = False
    checks_enabled: tuple = ()    # empty = all checks enabled

    @property
    def is_sentence_expected(self) -> bool:
        return self.expected_format in ("full_sentence", "actionable_bullet", "paragraph")


# Narrative paragraphs (Group A and Group B raw templates)
NARRATIVE_PARAGRAPH = FieldRule(
    expected_format="paragraph",
    min_words=50, max_words=180,
    requires_second_person=True,
    requires_terminal_period=True,
)
NARRATIVE_TEMPLATE = FieldRule(
    expected_format="template",
    min_words=50, max_words=180,
    requires_second_person=True,
    requires_terminal_period=True,
)

# Code bullets (user-facing in The Code section)
CODE_BULLET = FieldRule(
    expected_format="actionable_bullet",
    min_words=8, max_words=40,
    requires_second_person=False,
    requires_terminal_period=True,
)
# Shorter aspect/house injections
CODE_INJECTION = FieldRule(
    expected_format="actionable_bullet",
    min_words=5, max_words=30,
    requires_second_person=False,
    requires_terminal_period=False,
)
# House lean_into_bias — currently fragments, flagged as HIGH
LEAN_INTO_BIAS = FieldRule(
    expected_format="actionable_bullet",
    min_words=5, max_words=30,
    requires_second_person=False,
    requires_terminal_period=False,
)
# House code_consider_bias
CODE_CONSIDER_BIAS = FieldRule(
    expected_format="actionable_bullet",
    min_words=5, max_words=30,
    requires_second_person=False,
    requires_terminal_period=False,
)
# Opposites mood tokens — injected into Code Avoid at runtime by DeterministicResolver
MOOD_AVOID_TOKEN = FieldRule(
    expected_format="actionable_bullet",
    min_words=8, max_words=40,
    requires_second_person=False,
    requires_terminal_period=True,
)
# House modifier — sentence clause used in overlay templates
HOUSE_MODIFIER = FieldRule(
    expected_format="phrase",
    min_words=3, max_words=30,
    requires_second_person=False,
    requires_terminal_period=False,
)
# Material/pattern keywords (substituted into templates)
KEYWORD = FieldRule(
    expected_format="keyword",
    min_words=1, max_words=5,
    checks_enabled=("empty_content", "garbled_text", "capitalisation", "double_space"),
)
# Short descriptive phrases (occasion_modifiers, style_philosophy, element_balance)
DESCRIPTOR_PHRASE = FieldRule(
    expected_format="phrase",
    min_words=2, max_words=20,
    checks_enabled=("empty_content", "garbled_text", "ai_slop_words", "american_spelling",
                     "double_space", "em_dash"),
)
# Composed blueprint paragraphs (rendered text users actually read)
COMPOSED_PARAGRAPH = FieldRule(
    expected_format="paragraph",
    min_words=40, max_words=200,
    requires_second_person=True,
    requires_terminal_period=True,
)
# Composed code bullets (after runtime merging)
COMPOSED_CODE_BULLET = FieldRule(
    expected_format="actionable_bullet",
    min_words=5, max_words=50,
    requires_second_person=False,
    requires_terminal_period=True,
)
# Runtime overlay strings (appended to narratives)
OVERLAY_STRING = FieldRule(
    expected_format="full_sentence",
    min_words=8, max_words=40,
    requires_second_person=True,
    requires_terminal_period=True,
)
# UI fallback strings
FALLBACK_PARAGRAPH = FieldRule(
    expected_format="paragraph",
    min_words=30, max_words=200,
    requires_second_person=True,
    requires_terminal_period=True,
)
FALLBACK_BULLET = FieldRule(
    expected_format="actionable_bullet",
    min_words=8, max_words=50,
    requires_second_person=False,
    requires_terminal_period=True,
)


# ─── Auditable item ───────────────────────────────────────────────────

# Rendered Group B output (placeholders substituted)
RENDERED_PARAGRAPH = FieldRule(
    expected_format="paragraph",
    min_words=50, max_words=180,
    requires_second_person=True,
    requires_terminal_period=True,
)

# Field kinds that feed user-facing Code bullets and must be full sentences
CODE_INJECTION_FIELD_KINDS = frozenset({
    "lean_into_bias",
    "code_addition_leaninto",
    "code_addition_avoid",
    "code_consider_bias",
    "opposites_mood",
})


@dataclass
class AuditableItem:
    content_id: str
    source_layer: str        # narrative_cache | dataset | composed | runtime | fallback | rendered
    source_file: str
    json_edit_path: str
    ui_section: str
    text: str
    rule: FieldRule
    cluster_key: str = ""
    section_key: str = ""
    field_kind: str = ""     # e.g. lean_into_bias, code_addition_leaninto


# ─── Known placeholders from NarrativeTemplateRenderer ────────────────

KNOWN_PLACEHOLDERS: set[str] = set()
for i in range(1, 5):
    KNOWN_PLACEHOLDERS.add(f"neutral_colour_{i}")
    KNOWN_PLACEHOLDERS.add(f"core_colour_{i}")
    KNOWN_PLACEHOLDERS.add(f"accent_colour_{i}")
    KNOWN_PLACEHOLDERS.add(f"texture_good_{i}")
    KNOWN_PLACEHOLDERS.add(f"recommended_pattern_{i}")
for i in range(1, 4):
    KNOWN_PLACEHOLDERS.add(f"metal_{i}")
    KNOWN_PLACEHOLDERS.add(f"stone_{i}")
    KNOWN_PLACEHOLDERS.add(f"texture_bad_{i}")
for i in range(1, 3):
    KNOWN_PLACEHOLDERS.add(f"sweet_spot_keyword_{i}")
    KNOWN_PLACEHOLDERS.add(f"avoid_pattern_{i}")
KNOWN_PLACEHOLDERS |= {"family", "cluster", "depth", "temperature", "saturation", "contrast", "surface"}


# ─── Walker: Layer 1 — Narrative Cache ─────────────────────────────────

def walk_narrative_cache(cache_path: str) -> Generator[AuditableItem, None, None]:
    if not os.path.exists(cache_path):
        return
    with open(cache_path) as f:
        cache = json.load(f)
    src = os.path.basename(cache_path)
    for cluster_key, sections in cache.items():
        if not isinstance(sections, dict):
            continue
        for section_key in SECTION_KEYS:
            text = sections.get(section_key, "")
            rule = NARRATIVE_TEMPLATE if section_key in GROUP_B_SECTIONS else NARRATIVE_PARAGRAPH
            yield AuditableItem(
                content_id=f"cache:{cluster_key}.{section_key}",
                source_layer="narrative_cache",
                source_file=src,
                json_edit_path=f"{cluster_key}.{section_key}",
                ui_section=SECTION_DISPLAY.get(section_key, section_key),
                text=text,
                rule=rule,
                cluster_key=cluster_key,
                section_key=section_key,
            )


# ─── Walker: Layer 2 — Deterministic Dataset ──────────────────────────

_PLANET_SIGN_FIELDS: list[tuple[str, str, FieldRule]] = [
    ("code_leaninto", "The Code — Lean Into", CODE_BULLET),
    ("code_avoid", "The Code — Avoid", CODE_BULLET),
    ("code_consider", "The Code — Consider", CODE_BULLET),
]

_PLANET_SIGN_KEYWORD_FIELDS: list[tuple[str, str, FieldRule]] = [
    ("textures.good", "Texture keywords (good)", KEYWORD),
    ("textures.bad", "Texture keywords (bad)", KEYWORD),
    ("textures.sweet_spot_keywords", "Texture sweet-spot keywords", KEYWORD),
    ("patterns.recommended", "Pattern keywords (recommended)", KEYWORD),
    ("patterns.avoid", "Pattern keywords (avoid)", KEYWORD),
    ("metals", "Metal keywords", KEYWORD),
    ("stones", "Stone keywords", KEYWORD),
    ("silhouette_keywords", "Silhouette keywords", KEYWORD),
    ("colours.avoid", "Colour avoid keywords", KEYWORD),
]

_PLANET_SIGN_PHRASE_FIELDS: list[tuple[str, str, FieldRule]] = [
    ("style_philosophy", "Style philosophy", DESCRIPTOR_PHRASE),
    ("occasion_modifiers.work", "Occasion modifier — Work", DESCRIPTOR_PHRASE),
    ("occasion_modifiers.intimate", "Occasion modifier — Intimate", DESCRIPTOR_PHRASE),
    ("occasion_modifiers.daily", "Occasion modifier — Daily", DESCRIPTOR_PHRASE),
]


def _resolve_nested(obj: dict, dotpath: str):
    """Resolve a dotted path like 'textures.good' against a dict."""
    parts = dotpath.split(".")
    cur = obj
    for p in parts:
        if isinstance(cur, dict):
            cur = cur.get(p)
        else:
            return None
    return cur


def walk_dataset(dataset_path: str) -> Generator[AuditableItem, None, None]:
    if not os.path.exists(dataset_path):
        return
    with open(dataset_path) as f:
        dataset = json.load(f)
    src = os.path.basename(dataset_path)

    # planet_sign entries
    planet_sign = dataset.get("planet_sign", {})
    for ps_key, entry in planet_sign.items():
        if not isinstance(entry, dict):
            continue

        # Code bullet arrays
        for field_name, ui_section, rule in _PLANET_SIGN_FIELDS:
            items = entry.get(field_name, [])
            if isinstance(items, list):
                for i, text in enumerate(items):
                    yield AuditableItem(
                        content_id=f"dataset:planet_sign.{ps_key}.{field_name}[{i}]",
                        source_layer="dataset",
                        source_file=src,
                        json_edit_path=f"planet_sign.{ps_key}.{field_name}[{i}]",
                        ui_section=ui_section,
                        text=str(text),
                        rule=rule,
                        field_kind=field_name,
                    )

        # Keyword arrays
        for dotpath, ui_section, rule in _PLANET_SIGN_KEYWORD_FIELDS:
            items = _resolve_nested(entry, dotpath)
            if isinstance(items, list):
                for i, text in enumerate(items):
                    val = text if isinstance(text, str) else (text.get("name", "") if isinstance(text, dict) else str(text))
                    yield AuditableItem(
                        content_id=f"dataset:planet_sign.{ps_key}.{dotpath}[{i}]",
                        source_layer="dataset",
                        source_file=src,
                        json_edit_path=f"planet_sign.{ps_key}.{dotpath}[{i}]",
                        ui_section=ui_section,
                        text=val,
                        rule=rule,
                    )

        # Phrase fields
        for dotpath, ui_section, rule in _PLANET_SIGN_PHRASE_FIELDS:
            val = _resolve_nested(entry, dotpath)
            if isinstance(val, str):
                yield AuditableItem(
                    content_id=f"dataset:planet_sign.{ps_key}.{dotpath}",
                    source_layer="dataset",
                    source_file=src,
                    json_edit_path=f"planet_sign.{ps_key}.{dotpath}",
                    ui_section=ui_section,
                    text=val,
                    rule=rule,
                )

        # Opposites mood (anti-tokens fed into Code Avoid at runtime)
        moods = _resolve_nested(entry, "opposites.mood")
        if isinstance(moods, list):
            for i, m in enumerate(moods):
                yield AuditableItem(
                    content_id=f"dataset:planet_sign.{ps_key}.opposites.mood[{i}]",
                    source_layer="dataset",
                    source_file=src,
                    json_edit_path=f"planet_sign.{ps_key}.opposites.mood[{i}]",
                    ui_section="The Code — Avoid (anti-token)",
                    text=str(m),
                    rule=MOOD_AVOID_TOKEN,
                    field_kind="opposites_mood",
                )

    # aspects
    aspects = dataset.get("aspects", {})
    for asp_key, entry in aspects.items():
        if not isinstance(entry, dict):
            continue
        for field_name, ui_section in [
            ("code_addition_leaninto", "The Code — Lean Into (aspect)"),
            ("code_addition_avoid", "The Code — Avoid (aspect)"),
        ]:
            val = entry.get(field_name, "")
            if val:
                yield AuditableItem(
                    content_id=f"dataset:aspects.{asp_key}.{field_name}",
                    source_layer="dataset",
                    source_file=src,
                    json_edit_path=f"aspects.{asp_key}.{field_name}",
                    ui_section=ui_section,
                    text=str(val),
                    rule=CODE_INJECTION,
                    field_kind=field_name,
                )
        for field_name in ("effect", "texture_modifier", "colour_modifier"):
            val = entry.get(field_name, "")
            if val:
                yield AuditableItem(
                    content_id=f"dataset:aspects.{asp_key}.{field_name}",
                    source_layer="dataset",
                    source_file=src,
                    json_edit_path=f"aspects.{asp_key}.{field_name}",
                    ui_section=f"Aspect — {field_name}",
                    text=str(val),
                    rule=DESCRIPTOR_PHRASE,
                )

    # house_placements
    houses = dataset.get("house_placements", {})
    for hp_key, entry in houses.items():
        if not isinstance(entry, dict):
            continue
        mod = entry.get("modifier", "")
        if mod:
            yield AuditableItem(
                content_id=f"dataset:house_placements.{hp_key}.modifier",
                source_layer="dataset",
                source_file=src,
                json_edit_path=f"house_placements.{hp_key}.modifier",
                ui_section="House overlay modifier",
                text=str(mod),
                rule=HOUSE_MODIFIER,
            )
        for field_name, ui_section, rule in [
            ("lean_into_bias", "The Code — Lean Into (house bias)", LEAN_INTO_BIAS),
            ("code_consider_bias", "The Code — Consider (house bias)", CODE_CONSIDER_BIAS),
        ]:
            items = entry.get(field_name, [])
            if isinstance(items, list):
                for i, text in enumerate(items):
                    yield AuditableItem(
                        content_id=f"dataset:house_placements.{hp_key}.{field_name}[{i}]",
                        source_layer="dataset",
                        source_file=src,
                        json_edit_path=f"house_placements.{hp_key}.{field_name}[{i}]",
                        ui_section=ui_section,
                        text=str(text),
                        rule=rule,
                        field_kind=field_name,
                    )

    # element_balance
    elements = dataset.get("element_balance", {})
    for el_key, entry in elements.items():
        if not isinstance(entry, dict):
            continue
        for field_name in ("overall_energy", "palette_bias", "texture_bias"):
            val = entry.get(field_name, "")
            if val:
                yield AuditableItem(
                    content_id=f"dataset:element_balance.{el_key}.{field_name}",
                    source_layer="dataset",
                    source_file=src,
                    json_edit_path=f"element_balance.{el_key}.{field_name}",
                    ui_section=f"Element balance — {field_name}",
                    text=str(val),
                    rule=DESCRIPTOR_PHRASE,
                )


# ─── Walker: Layer 3 — Composed Blueprint Outputs ─────────────────────

_COMPOSED_TEXT_FIELDS = [
    ("styleCore.narrativeText", "The Blueprint", COMPOSED_PARAGRAPH),
    ("textures.goodText", "The Textures — Good", COMPOSED_PARAGRAPH),
    ("textures.badText", "The Textures — Bad", COMPOSED_PARAGRAPH),
    ("textures.sweetSpotText", "The Textures — Sweet Spot", COMPOSED_PARAGRAPH),
    ("palette.narrativeText", "The Palette", COMPOSED_PARAGRAPH),
    ("occasions.workText", "The Occasions — Work", COMPOSED_PARAGRAPH),
    ("occasions.intimateText", "The Occasions — Intimate", COMPOSED_PARAGRAPH),
    ("occasions.dailyText", "The Occasions — Daily", COMPOSED_PARAGRAPH),
    ("hardware.metalsText", "The Hardware — Metals", COMPOSED_PARAGRAPH),
    ("hardware.stonesText", "The Hardware — Stones", COMPOSED_PARAGRAPH),
    ("hardware.tipText", "The Hardware — Tip", COMPOSED_PARAGRAPH),
    ("pattern.narrativeText", "The Pattern", COMPOSED_PARAGRAPH),
    ("pattern.tipText", "The Pattern — Tip", COMPOSED_PARAGRAPH),
]

_COMPOSED_CODE_FIELDS = [
    ("code.leanInto", "The Code — Lean Into", COMPOSED_CODE_BULLET),
    ("code.avoid", "The Code — Avoid", COMPOSED_CODE_BULLET),
    ("code.consider", "The Code — Consider", COMPOSED_CODE_BULLET),
]


def walk_composed_blueprints(blueprints_dir: str) -> Generator[AuditableItem, None, None]:
    if not os.path.isdir(blueprints_dir):
        return
    for fname in sorted(os.listdir(blueprints_dir)):
        if not fname.endswith(".json"):
            continue
        fpath = os.path.join(blueprints_dir, fname)
        try:
            with open(fpath) as f:
                bp = json.load(f)
        except (json.JSONDecodeError, IOError):
            continue
        user_id = fname.replace(".json", "")

        for dotpath, ui_section, rule in _COMPOSED_TEXT_FIELDS:
            val = _resolve_nested(bp, dotpath)
            if isinstance(val, str) and val.strip():
                yield AuditableItem(
                    content_id=f"composed:{user_id}.{dotpath}",
                    source_layer="composed",
                    source_file=f"blueprints/{fname}",
                    json_edit_path=dotpath,
                    ui_section=ui_section,
                    text=val,
                    rule=rule,
                    cluster_key=user_id,
                )

        for dotpath, ui_section, rule in _COMPOSED_CODE_FIELDS:
            items = _resolve_nested(bp, dotpath)
            if isinstance(items, list):
                for i, text in enumerate(items):
                    yield AuditableItem(
                        content_id=f"composed:{user_id}.{dotpath}[{i}]",
                        source_layer="composed",
                        source_file=f"blueprints/{fname}",
                        json_edit_path=f"{dotpath}[{i}]",
                        ui_section=ui_section,
                        text=str(text),
                        rule=rule,
                        cluster_key=user_id,
                    )

        # Accessory paragraphs
        acc_paras = _resolve_nested(bp, "accessory.paragraphs")
        if isinstance(acc_paras, list):
            for i, text in enumerate(acc_paras):
                yield AuditableItem(
                    content_id=f"composed:{user_id}.accessory.paragraphs[{i}]",
                    source_layer="composed",
                    source_file=f"blueprints/{fname}",
                    json_edit_path=f"accessory.paragraphs[{i}]",
                    ui_section=f"The Accessory — Paragraph {i+1}",
                    text=str(text),
                    rule=COMPOSED_PARAGRAPH,
                    cluster_key=user_id,
                )


# ─── Walker: Layer 4+5 — Runtime extracted strings ────────────────────

def walk_extracted_strings(extracted_path: str) -> Generator[AuditableItem, None, None]:
    if not os.path.exists(extracted_path):
        return
    with open(extracted_path) as f:
        data = json.load(f)
    src = os.path.basename(extracted_path)

    for entry in data.get("overlays", []):
        yield AuditableItem(
            content_id=f"runtime:{entry['id']}",
            source_layer="runtime",
            source_file=entry.get("swift_file", src),
            json_edit_path=entry["id"],
            ui_section=entry.get("ui_section", "Overlay"),
            text=entry["text"],
            rule=OVERLAY_STRING,
        )

    for entry in data.get("fallbacks", []):
        rule = FALLBACK_BULLET if entry.get("format") == "bullet" else FALLBACK_PARAGRAPH
        yield AuditableItem(
            content_id=f"fallback:{entry['id']}",
            source_layer="fallback",
            source_file=entry.get("swift_file", src),
            json_edit_path=entry["id"],
            ui_section=entry.get("ui_section", "Fallback"),
            text=entry["text"],
            rule=rule,
        )


# ─── Walker: Layer 6 — Rendered Group B templates ─────────────────────

_PLACEHOLDER_RE = re.compile(r"\{([a-z_0-9]+)\}")


def _load_placeholder_fixture(fixture_path: str) -> dict[str, str]:
    if not os.path.exists(fixture_path):
        return {}
    with open(fixture_path) as f:
        return json.load(f)


def _render_template(template: str, placeholders: dict[str, str]) -> str:
    def repl(match: re.Match) -> str:
        key = match.group(1)
        return placeholders.get(key, "a complementary choice")
    return _PLACEHOLDER_RE.sub(repl, template)


def walk_rendered_templates(
    cache_path: str,
    fixture_path: str,
) -> Generator[AuditableItem, None, None]:
    """Audit Group B narratives with placeholder tokens substituted."""
    if not os.path.exists(cache_path):
        return
    placeholders = _load_placeholder_fixture(fixture_path)
    if not placeholders:
        return

    with open(cache_path) as f:
        cache = json.load(f)
    src = os.path.basename(cache_path)
    fixture_name = os.path.basename(fixture_path)

    for cluster_key, sections in cache.items():
        if not isinstance(sections, dict):
            continue
        for section_key in SECTION_KEYS:
            if section_key not in GROUP_B_SECTIONS:
                continue
            raw = sections.get(section_key, "")
            if not raw or "{" not in raw:
                continue
            rendered = _render_template(raw, placeholders)
            yield AuditableItem(
                content_id=f"rendered:{cluster_key}.{section_key}",
                source_layer="rendered",
                source_file=f"{src} (rendered via {fixture_name})",
                json_edit_path=f"{cluster_key}.{section_key}",
                ui_section=f"{SECTION_DISPLAY.get(section_key, section_key)} (rendered)",
                text=rendered,
                rule=RENDERED_PARAGRAPH,
                cluster_key=cluster_key,
                section_key=section_key,
                field_kind="rendered_template",
            )
