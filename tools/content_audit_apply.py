#!/usr/bin/env python3
"""
Cosmic Fit — Style Guide Audit Correction Pipeline

Applies mechanical fixes and batched Gemini rewrites using audit_handoff_final.json
as the action queue and audit_report.json for enrichment metadata.

Usage (from repo root):
    # Phase 1: deterministic fixes only
    python3 tools/content_audit_apply.py --phase mechanical --priority critical,high

    # Phase 2: AI rewrites (batched Gemini calls)
    python3 tools/content_audit_apply.py --phase rewrite --priority critical,high --resume

    # Both phases
    python3 tools/content_audit_apply.py --phase all --priority critical,high,medium,low

    # Dry run (no writes)
    python3 tools/content_audit_apply.py --phase all --dry-run --limit 50
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from backup_content_sources import require_backup_gate
from content_audit_json_path import get_at_path, set_at_path, path_exists, _MISSING
from gemini_client import (
    GeminiClient,
    QuotaExhaustedError,
    load_local_env_file,
    resolve_api_keys,
    resolve_model_name,
    REWRITE_JSON_SCHEMA,
)

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data" / "style_guide"

CANONICAL_JSON_FILES = {
    "astrological_style_dataset.json": DATA_DIR / "astrological_style_dataset.json",
    "blueprint_narrative_cache.json": DATA_DIR / "blueprint_narrative_cache.json",
}

LOG_PATH = DATA_DIR / "audit_apply_log.json"
PROGRESS_PATH = DATA_DIR / "audit_apply_progress.json"

MECHANICAL_CHECK_IDS = frozenset({
    "double_space", "em_dash", "american_spelling",
    "capitalisation", "missing_terminal_punctuation",
})

REWRITE_CHECK_IDS = frozenset({
    "nonsense_fragment", "pidgin_english", "not_a_sentence",
    "sparse_code_bullet", "wrong_format_for_field", "vague_direction",
    "ai_slop_words", "ai_slop_patterns", "intra_paragraph_repetition",
    "hedging_language", "missing_second_person", "excessive_length",
    "astrology_jargon_leak", "passive_voice_heavy",
    "sentence_start_repetition", "weak_opening", "keyword_stuffing",
    "intra_cluster_repetition", "cross_cluster_duplicate",
    "composed_code_inconsistency", "non_declarative_ending",
    "grammar_error",
})

AMERICAN_SPELLINGS = {
    "color": "colour", "center": "centre", "organize": "organise",
    "realize": "realise", "recognize": "recognise", "favor": "favour",
    "behavior": "behaviour", "honor": "honour", "labor": "labour",
    "catalog": "catalogue", "defense": "defence", "offense": "offence",
    "jewelry": "jewellery", "gray": "grey", "traveling": "travelling",
    "modeling": "modelling", "canceled": "cancelled",
}

_EM_DASH_RE = re.compile(r"[\u2014\u2013]|(?<!\-)--(?!\-)")
_DOUBLE_SPACE_RE = re.compile(r"  +")
_PLACEHOLDER_RE = re.compile(r"\{([a-z_0-9]+)\}")

SENTENCE_EXPECTED_FORMATS = frozenset({"paragraph", "template", "actionable_bullet"})

SWIFT_TEMPLATE_SKIP_PREFIXES = (
    "overlay:venus_house",
    "overlay:moon_house",
    "overlay:dominant_house",
    "overlay:midheaven_style_core.",
    "overlay:midheaven_work.",
    "overlay:domain_implication.",
)


# ─── Utilities ─────────────────────────────────────────────────────────

def resolve_source_path(source_file: str) -> Path | None:
    """Resolve a source_file value from the handoff to a real filesystem path."""
    if source_file in CANONICAL_JSON_FILES:
        return CANONICAL_JSON_FILES[source_file]
    if source_file.endswith(".swift"):
        candidate = REPO_ROOT / source_file
        if candidate.exists():
            return candidate
    return None


def is_canonical(source_file: str) -> bool:
    return source_file in CANONICAL_JSON_FILES or source_file.endswith(".swift")


# ─── Log / Progress ───────────────────────────────────────────────────

def load_log() -> dict[str, dict]:
    """Load existing apply log keyed by json_edit_path."""
    if LOG_PATH.exists():
        try:
            data = json.loads(LOG_PATH.read_text(encoding="utf-8"))
            return {entry["json_edit_path"]: entry for entry in data.get("entries", [])}
        except (json.JSONDecodeError, KeyError):
            pass
    return {}


def save_log(log_entries: dict[str, dict]):
    data = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_entries": len(log_entries),
        "entries": list(log_entries.values()),
    }
    LOG_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def save_progress(phase: str, completed: int, total: int, applied: int, skipped: int, failed: int):
    data = {
        "phase": phase,
        "completed": completed,
        "total": total,
        "applied": applied,
        "skipped": skipped,
        "failed": failed,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    PROGRESS_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


# ─── Data Loading ─────────────────────────────────────────────────────

def load_handoff(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get("actions", [])


def load_report(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def enrich_actions(actions: list[dict], report: dict) -> list[dict]:
    """Add ui_section, expected_format, suggested_fix from report if missing."""
    issue_lookup: dict[str, dict] = {}
    for issue in report.get("issues", []):
        issue_lookup[issue["id"]] = issue

    item_lookup: dict[str, dict] = {}
    for item in report.get("items", []):
        item_lookup[item["content_id"]] = item

    # Build path-based lookup for when UUID matching fails (cross-run handoffs)
    item_by_path: dict[str, dict] = {}
    for item in report.get("items", []):
        item_by_path[item.get("json_edit_path", "")] = item

    issues_by_path: dict[str, list[dict]] = {}
    for issue in report.get("issues", []):
        path = issue.get("json_edit_path", "")
        issues_by_path.setdefault(path, []).append(issue)

    for action in actions:
        if action.get("content_id") and action.get("expected_format"):
            continue

        # Strategy 1: join via related_issue_ids (same audit run)
        resolved = False
        for iid in action.get("related_issue_ids", []):
            issue = issue_lookup.get(iid)
            if issue:
                cid = issue.get("content_id", "")
                item = item_lookup.get(cid, {})
                if not action.get("content_id"):
                    action["content_id"] = cid
                if not action.get("ui_section"):
                    action["ui_section"] = item.get("ui_section", "")
                if not action.get("expected_format"):
                    action["expected_format"] = item.get("expected_format", "")
                if not action.get("suggested_fix"):
                    if issue.get("auto_fixable") and issue.get("suggested_fix"):
                        action["suggested_fix"] = issue["suggested_fix"]
                resolved = True
                break

        # Strategy 2: join via json_edit_path (cross-run handoffs)
        if not resolved:
            edit_path = action.get("json_edit_path", "")
            item = item_by_path.get(edit_path, {})
            if item:
                if not action.get("content_id"):
                    action["content_id"] = item.get("content_id", "")
                if not action.get("ui_section"):
                    action["ui_section"] = item.get("ui_section", "")
                if not action.get("expected_format"):
                    action["expected_format"] = item.get("expected_format", "")
                # Find best suggested_fix from path-based issues
                if not action.get("suggested_fix"):
                    for iss in issues_by_path.get(edit_path, []):
                        if iss.get("auto_fixable") and iss.get("suggested_fix"):
                            action["suggested_fix"] = iss["suggested_fix"]
                            break

    return actions


def filter_canonical(actions: list[dict]) -> list[dict]:
    return [a for a in actions if is_canonical(a.get("source_file", ""))]


def filter_priority(actions: list[dict], priorities: set[str]) -> list[dict]:
    return [a for a in actions if a.get("priority", "") in priorities]


# ─── File Manager ─────────────────────────────────────────────────────

class FileManager:
    """Loads JSON/text files on demand, tracks dirty state, writes at flush."""

    def __init__(self, dry_run: bool = False):
        self._json_cache: dict[Path, Any] = {}
        self._text_cache: dict[Path, str] = {}
        self._dirty: set[Path] = set()
        self._dry_run = dry_run

    def get_json(self, path: Path) -> Any:
        if path not in self._json_cache:
            self._json_cache[path] = json.loads(path.read_text(encoding="utf-8"))
        return self._json_cache[path]

    def mark_dirty(self, path: Path):
        self._dirty.add(path)

    def get_text(self, path: Path) -> str:
        if path not in self._text_cache:
            self._text_cache[path] = path.read_text(encoding="utf-8")
        return self._text_cache[path]

    def set_text(self, path: Path, content: str):
        self._text_cache[path] = content
        self._dirty.add(path)

    def flush(self) -> list[Path]:
        written: list[Path] = []
        if self._dry_run:
            return written
        for path in self._dirty:
            if path in self._json_cache:
                path.write_text(
                    json.dumps(self._json_cache[path], indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8",
                )
                written.append(path)
            elif path in self._text_cache:
                path.write_text(self._text_cache[path], encoding="utf-8")
                written.append(path)
        self._dirty.clear()
        return written


# ─── Phase 1: Mechanical Fixes ────────────────────────────────────────

def apply_em_dash_fix(text: str) -> str:
    """Replace em-dashes / en-dashes with commas (context-aware)."""
    def _replacer(m: re.Match) -> str:
        start = m.start()
        if start > 0 and text[start - 1] == " " and m.end() < len(text) and text[m.end()] == " ":
            return ","
        return ","
    return _EM_DASH_RE.sub(_replacer, text)


def apply_american_spelling_fix(text: str) -> str:
    result = text
    for us, uk in AMERICAN_SPELLINGS.items():
        result = re.sub(r"\b" + re.escape(us) + r"\b", uk, result, flags=re.IGNORECASE)
    return result


def apply_capitalisation_fix(text: str) -> str:
    stripped = text.lstrip()
    if stripped and stripped[0].isalpha() and not stripped[0].isupper():
        leading_ws = text[:len(text) - len(stripped)]
        return leading_ws + stripped[0].upper() + stripped[1:]
    return text


def apply_terminal_punctuation_fix(text: str, expected_format: str) -> str:
    if expected_format not in SENTENCE_EXPECTED_FORMATS:
        return text
    stripped = text.rstrip()
    if stripped and stripped[-1] not in ".!?":
        return stripped + "."
    return text


def apply_double_space_fix(text: str) -> str:
    return _DOUBLE_SPACE_RE.sub(" ", text)


def mechanical_fix(text: str, check_ids: list[str], expected_format: str) -> str:
    """Apply all applicable mechanical fixes in a stable order."""
    result = text
    checks = set(check_ids)

    if "double_space" in checks:
        result = apply_double_space_fix(result)
    if "em_dash" in checks:
        result = apply_em_dash_fix(result)
    if "american_spelling" in checks:
        result = apply_american_spelling_fix(result)
    if "capitalisation" in checks:
        result = apply_capitalisation_fix(result)
    if "missing_terminal_punctuation" in checks:
        result = apply_terminal_punctuation_fix(result, expected_format)

    return result


def needs_rewrite(check_ids: list[str]) -> bool:
    """Return True if any check_id requires AI rewrite after mechanical pass."""
    return bool(set(check_ids) & REWRITE_CHECK_IDS)


def run_mechanical_phase(
    actions: list[dict],
    fm: FileManager,
    log_entries: dict[str, dict],
    resume: bool = False,
    dry_run: bool = False,
) -> tuple[list[dict], int, int, int]:
    """Run mechanical fixes. Returns (rewrite_queue, applied, skipped, stale)."""
    rewrite_queue: list[dict] = []
    applied = 0
    skipped = 0
    stale = 0

    for action in actions:
        edit_path = action["json_edit_path"]

        if resume and edit_path in log_entries:
            entry = log_entries[edit_path]
            if entry.get("mechanical_status") == "applied":
                if needs_rewrite(action.get("check_ids", [])):
                    if entry.get("rewrite_status") != "applied":
                        rewrite_queue.append(action)
                skipped += 1
                continue

        source_file = action.get("source_file", "")
        file_path = resolve_source_path(source_file)
        if not file_path:
            log_entries[edit_path] = _log_entry(action, "mechanical", "skipped", reason="unresolved source file")
            skipped += 1
            continue

        if file_path.suffix == ".swift":
            current = _get_swift_string(fm, file_path, action["current_value"])
            if current is None:
                log_entries[edit_path] = _log_entry(action, "mechanical", "stale", reason="string not found in Swift")
                stale += 1
                continue
            new_text = mechanical_fix(current, action.get("check_ids", []), action.get("expected_format", ""))
            if new_text != current:
                if not dry_run:
                    _set_swift_string(fm, file_path, current, new_text)
                log_entries[edit_path] = _log_entry(action, "mechanical", "applied", old_value=current, new_value=new_text)
                applied += 1
            else:
                log_entries[edit_path] = _log_entry(action, "mechanical", "no_change")
        else:
            obj = fm.get_json(file_path)
            current = get_at_path(obj, edit_path)
            if current is _MISSING:
                log_entries[edit_path] = _log_entry(action, "mechanical", "stale", reason="path not found")
                stale += 1
                continue
            if str(current) != str(action.get("current_value", "")):
                log_entries[edit_path] = _log_entry(action, "mechanical", "stale",
                                                     reason="value mismatch", old_value=str(current))
                stale += 1
                continue
            new_text = mechanical_fix(str(current), action.get("check_ids", []), action.get("expected_format", ""))
            if new_text != str(current):
                if not dry_run:
                    set_at_path(obj, edit_path, new_text)
                    fm.mark_dirty(file_path)
                log_entries[edit_path] = _log_entry(action, "mechanical", "applied",
                                                     old_value=str(current), new_value=new_text)
                applied += 1
            else:
                log_entries[edit_path] = _log_entry(action, "mechanical", "no_change")

        if needs_rewrite(action.get("check_ids", [])):
            rewrite_queue.append(action)

    return rewrite_queue, applied, skipped, stale


# ─── Phase 2: Gemini Batched Rewrites ─────────────────────────────────

REWRITE_SYSTEM_PROMPT = """You are a fashion-insider style writer for Cosmic Fit, an astrological fashion guidance app.

TASK: You will receive a batch of content items that need rewriting. Each has a current value, its UI location, the dataset key it belongs to (which tells you the astrological context), and specific issues to fix.

VOICE RULES:
- Sound like a stylish, culturally switched-on woman in her thirties who actually knows clothes
- Direct second-person address: "You", "Your"
- Fashion-literate and tactile: fabrics, construction, silhouette, movement, hardware, finish
- British English spelling (colour, centre, programme)
- No hedging: never use "you might", "perhaps", "maybe", "possibly"
- No astrology jargon in output — the user never sees planet names, house numbers, or aspect terms

ASTROLOGY-CONTEXT GROUNDING:
- Each item's json_edit_path contains the astrological source key (e.g. planet_sign.mars_aquarius, house_placements.venus_house_7, aspects.venus_conjunction_mars).
- Use this to understand the underlying astrological meaning and ensure your rewrite reflects the qualities, energies, and style tendencies of that placement.
- The rewrite must feel relevant and specific to the astrological archetype — not generic filler that could apply to any sign.

MOOD ANTI-TOKEN EXPANSION (for opposites.mood items):
- These are single words or short phrases representing style anti-qualities (e.g. "safe", "conventional", "chaotic").
- Expand each into a complete Avoid bullet (8-20 words, terminal full stop) grounded in the astrological context.
- The bullet completes the section title "Avoid ___" — open with a NOUN PHRASE or gerund, NEVER with Avoid/Resist/Skip/Stop/Reject/Refuse/Ditch.
- Example: "safe" for mars_aquarius → "Predictable, risk-free silhouettes that play it safe and drain your natural boldness."

PLACEHOLDER PRESERVATION:
- If the source text contains {placeholder} tokens (e.g. {texture_good_1}, {core_colour_1}), preserve them EXACTLY in your rewrite. Do not remove, rename, or invent new placeholders.

BANNED WORDS (never use):
delve, tapestry, resonate, elevate, curate, embark, multifaceted, realm, robust, leverage, utilize, harness, holistic, synergy, paradigm, nuanced, myriad, landscape, journey, foster, unlock, unleash, seamless, moreover, furthermore

OUTPUT FORMAT:
Return valid JSON with exactly this schema:
{"rewrites": [{"json_edit_path": "...", "new_value": "..."}]}

One entry per input item. Preserve the json_edit_path exactly as given."""

FORMAT_RULES = {
    "actionable_bullet": (
        "Write a complete sentence of at least 8 words. Match the Code section title grammar: "
        "Lean Into → gerund opening (-ing); Avoid → noun phrase or gerund (never Avoid/Resist/Skip); "
        "Consider → gerund OR noun phrase (One/A/The/Whether), never imperatives like Wear/Build."
    ),
    "keyword": "Write a single descriptive keyword or short compound (2-3 words max). Lowercase, no punctuation.",
    "phrase": "Write a concise descriptive phrase (3-8 words). No terminal punctuation.",
    "paragraph": "Write 3-6 sentences, 50-150 words total. Open with an observation or judgement. Close memorably. Plain text only.",
    "template": "Write 3-6 sentences, 50-150 words. CRITICAL: preserve ALL {placeholder} tokens exactly as they appear in the original. Plain text only.",
    "full_sentence": "Write one complete sentence of at least 8 words. British English, second person where appropriate.",
}

SECTION_FORMAT_RULES = {
    "lean into": "Lean Into bullet: open with a gerund (-ing). Never repeat 'Lean into' or use imperatives (Build, Choose, Use).",
    "avoid": "Avoid bullet: open with a noun phrase or gerund completing 'Avoid ___'. Never use Avoid, Resist, Skip, Stop, Reject, Refuse, or Ditch.",
    "consider": "Consider bullet: open with a gerund OR noun phrase (One/A/The/Whether/How). Never use imperatives like Wear, Build, or Use.",
}


def _extract_astro_context(json_edit_path: str) -> str:
    """Extract human-readable astrological context from a json_edit_path."""
    parts = json_edit_path.split(".")
    if len(parts) >= 2 and parts[0] == "planet_sign":
        combo = parts[1].split("[")[0]
        planet, _, sign = combo.partition("_")
        return f"{planet.title()} in {sign.title()}"
    if len(parts) >= 2 and parts[0] == "house_placements":
        key = parts[1].split("[")[0]
        return key.replace("_", " ").title()
    if len(parts) >= 2 and parts[0] == "aspects":
        key = parts[1].split("[")[0]
        return key.replace("_", " ").title()
    return ""


def build_batch_prompt(batch: list[dict], expected_format: str) -> str:
    """Build the user prompt for a rewrite batch."""
    format_rule = FORMAT_RULES.get(expected_format, FORMAT_RULES["paragraph"])
    # Section-specific override for Code bullets
    ui_sections = {a.get("ui_section", "").lower() for a in batch}
    for key, rule in SECTION_FORMAT_RULES.items():
        if any(key in s for s in ui_sections):
            format_rule = rule
            break
    lines = [
        f"FORMAT REQUIREMENT: {format_rule}",
        "",
        f"Rewrite each item below. There are {len(batch)} items.",
        "",
    ]
    for i, action in enumerate(batch, 1):
        lines.append(f"--- Item {i} ---")
        lines.append(f"json_edit_path: {action['json_edit_path']}")
        astro = _extract_astro_context(action['json_edit_path'])
        if astro:
            lines.append(f"astrological_context: {astro}")
        lines.append(f"ui_section: {action.get('ui_section', 'Unknown')}")
        lines.append(f"current_value: {action.get('current_value', '')}")
        lines.append(f"issues: {', '.join(action.get('check_ids', []))}")
        lines.append(f"rewrite_brief: {action.get('rewrite_brief', '')}")
        lines.append("")

    lines.append("Return valid JSON: {\"rewrites\": [{\"json_edit_path\": \"...\", \"new_value\": \"...\"}]}")
    return "\n".join(lines)


def validate_rewrite(new_value: str, action: dict) -> str | None:
    """Validate a rewrite result. Returns error string or None if valid."""
    expected_format = action.get("expected_format", "")

    if not new_value.strip():
        return "empty rewrite"

    if expected_format == "actionable_bullet":
        if len(new_value.split()) < 5:
            return f"too short ({len(new_value.split())} words, need 5+)"

    if expected_format in ("paragraph", "template"):
        wc = len(new_value.split())
        if wc < 20:
            return f"paragraph too short ({wc} words)"
        if wc > 200:
            return f"paragraph too long ({wc} words)"

    original = action.get("current_value", "")
    original_tokens = set(_PLACEHOLDER_RE.findall(original))
    if original_tokens:
        new_tokens = set(_PLACEHOLDER_RE.findall(new_value))
        missing = original_tokens - new_tokens
        if missing:
            return f"missing placeholders: {missing}"
        invented = new_tokens - original_tokens
        if invented:
            return f"invented placeholders not in original: {invented}"

    for word in ["delve", "tapestry", "resonate", "elevate", "curate", "embark",
                 "multifaceted", "realm", "robust", "leverage", "utilize", "harness"]:
        if re.search(r"\b" + word + r"\b", new_value, re.I):
            return f"banned word: {word}"

    return None


def call_gemini_batch(client: GeminiClient, batch: list[dict], expected_format: str) -> dict[str, str]:
    """Call Gemini for a batch. Returns {json_edit_path: new_value}."""
    user_prompt = build_batch_prompt(batch, expected_format)
    parsed = client.generate_json(user_prompt, REWRITE_SYSTEM_PROMPT, REWRITE_JSON_SCHEMA)
    results: dict[str, str] = {}
    for entry in parsed.get("rewrites", []):
        path = entry.get("json_edit_path", "")
        value = entry.get("new_value", "")
        if path and value:
            results[path] = value
    return results


def _set_rewrite_log(
    log_entries: dict[str, dict],
    action: dict,
    status: str,
    *,
    reason: str = "",
    old_value: str = "",
    new_value: str = "",
) -> None:
    path = action["json_edit_path"]
    log_entries[path] = _log_entry(
        action, "rewrite", status,
        reason=reason, old_value=old_value, new_value=new_value,
        existing=log_entries.get(path),
    )


def _should_skip_swift_rewrite(
    action: dict,
    existing_entry: dict | None,
    resume: bool,
) -> str | None:
    source_file = action.get("source_file", "")
    edit_path = action.get("json_edit_path", "")
    if not source_file.endswith(".swift"):
        return None

    if any(edit_path.startswith(prefix) for prefix in SWIFT_TEMPLATE_SKIP_PREFIXES):
        return "allowlisted Swift runtime template"

    if not resume or not existing_entry:
        return None

    if existing_entry.get("rewrite_status") == "failed" and existing_entry.get("reason") == "Swift string not found":
        return "previous Swift string not found (resume skip)"

    return None


def run_rewrite_phase(
    actions: list[dict],
    fm: FileManager,
    log_entries: dict[str, dict],
    batch_size: int = 25,
    api_key: str | None = None,
    model_name: str | None = None,
    resume: bool = False,
    dry_run: bool = False,
) -> tuple[int, int, int]:
    """Run Gemini rewrite phase. Returns (applied, skipped, failed)."""
    try:
        from google import genai  # noqa: F401 — ensure google-genai is installed
    except ImportError:
        print("ERROR: google-genai not installed. Run: pip install google-genai")
        return 0, 0, len(actions)

    api_keys = resolve_api_keys(api_key)
    if not api_keys:
        print("ERROR: No Gemini API key found. Set GEMINI_API_KEY in .env")
        return 0, 0, len(actions)

    model_str = resolve_model_name(model_name)
    key_idx = 0
    client = GeminiClient(api_keys[key_idx], model_name=model_str)
    print(f"  Using model: {client.model}")

    # Filter to actions that still need rewrite
    queue = []
    resume_applied_skips = 0
    swift_skip_count = 0
    for action in actions:
        edit_path = action["json_edit_path"]
        existing = log_entries.get(edit_path)
        if resume and existing:
            if existing.get("rewrite_status") == "applied":
                resume_applied_skips += 1
                continue
        skip_reason = _should_skip_swift_rewrite(action, existing, resume)
        if skip_reason:
            _set_rewrite_log(log_entries, action, "skipped", reason=skip_reason)
            swift_skip_count += 1
            continue
        queue.append(action)

    if resume_applied_skips:
        print(f"  Resume: skipping {resume_applied_skips} already-applied items")
    if swift_skip_count:
        print(f"  Rewrite: skipping {swift_skip_count} Swift template/unmatched items")

    if not queue:
        print("  No actions need rewriting.")
        return 0, 0, 0

    # Group by expected_format for batching
    by_format: dict[str, list[dict]] = {}
    for action in queue:
        fmt = action.get("expected_format", "paragraph")
        by_format.setdefault(fmt, []).append(action)

    applied = 0
    skipped = 0
    failed = 0
    completed = 0
    total = len(queue)

    for fmt, fmt_actions in by_format.items():
        effective_batch_size = batch_size if fmt in ("actionable_bullet", "keyword", "phrase") else min(batch_size, 8)

        for batch_start in range(0, len(fmt_actions), effective_batch_size):
            batch = fmt_actions[batch_start:batch_start + effective_batch_size]
            print(f"  Batch: {fmt} [{batch_start+1}–{batch_start+len(batch)}/{len(fmt_actions)}]...", end="", flush=True)

            try:
                try:
                    results = call_gemini_batch(client, batch, fmt)
                except QuotaExhaustedError:
                    key_idx += 1
                    if key_idx < len(api_keys):
                        print(f" key exhausted, rotating to key {key_idx + 1}...")
                        client = GeminiClient(api_keys[key_idx], model_name=model_str)
                        print(f"  Using model: {client.model}")
                        try:
                            results = call_gemini_batch(client, batch, fmt)
                        except QuotaExhaustedError:
                            print(" all keys exhausted.")
                            failed += len(batch)
                            for action in batch:
                                _set_rewrite_log(log_entries, action, "failed", reason="quota exhausted")
                            continue
                    else:
                        print(" all keys exhausted.")
                        failed += len(batch)
                        for action in batch:
                            _set_rewrite_log(log_entries, action, "failed", reason="quota exhausted")
                        continue
                except Exception as e:
                    print(f" API error: {e}")
                    failed += len(batch)
                    for action in batch:
                        _set_rewrite_log(log_entries, action, "failed", reason=f"API error: {e}")
                    continue

                if not results:
                    print(" no results")
                    failed += len(batch)
                    for action in batch:
                        _set_rewrite_log(log_entries, action, "failed", reason="empty API response")
                    continue

                batch_applied = 0
                batch_failed = 0
                for action in batch:
                    edit_path = action["json_edit_path"]
                    new_value = results.get(edit_path)

                    if not new_value:
                        _set_rewrite_log(log_entries, action, "failed", reason="not in API response")
                        batch_failed += 1
                        failed += 1
                        continue

                    err = validate_rewrite(new_value, action)
                    if err:
                        _set_rewrite_log(log_entries, action, "failed",
                                         reason=f"validation: {err}", new_value=new_value)
                        batch_failed += 1
                        failed += 1
                        continue

                    source_file = action.get("source_file", "")
                    file_path = resolve_source_path(source_file)
                    if not file_path:
                        _set_rewrite_log(log_entries, action, "failed", reason="unresolved path")
                        batch_failed += 1
                        failed += 1
                        continue

                    if not dry_run:
                        if file_path.suffix == ".swift":
                            # Get the current value (post-mechanical)
                            mechanical_entry = log_entries.get(edit_path, {})
                            current = mechanical_entry.get("new_value") or action.get("current_value", "")
                            ok = _set_swift_string(fm, file_path, current, new_value)
                            if not ok:
                                _set_rewrite_log(log_entries, action, "failed", reason="Swift string not found")
                                batch_failed += 1
                                failed += 1
                                continue
                        else:
                            obj = fm.get_json(file_path)
                            set_at_path(obj, edit_path, new_value)
                            fm.mark_dirty(file_path)

                    _set_rewrite_log(log_entries, action, "applied",
                                     old_value=action.get("current_value", ""),
                                     new_value=new_value)
                    batch_applied += 1
                    applied += 1

                print(f" {batch_applied} applied, {batch_failed} failed")
            finally:
                completed += len(batch)
                if not dry_run:
                    save_log(log_entries)
                    fm.flush()
                    save_progress("rewrite", completed, total, applied, skipped, failed)
                time.sleep(0.5)

    return applied, skipped, failed


# ─── Swift Helpers ─────────────────────────────────────────────────────

def _get_swift_string(fm: FileManager, path: Path, target: str) -> str | None:
    """Check if target string exists in Swift file. Returns it if found once."""
    content = fm.get_text(path)
    escaped = target.replace("\\", "\\\\").replace('"', '\\"')
    count = content.count(f'"{escaped}"')
    if count == 1:
        return target
    # Try unescaped match
    count = content.count(f'"{target}"')
    if count == 1:
        return target
    return None


def _set_swift_string(fm: FileManager, path: Path, old: str, new: str) -> bool:
    """Replace a string literal in Swift. Returns False if ambiguous/not found."""
    content = fm.get_text(path)
    old_escaped = old.replace("\\", "\\\\").replace('"', '\\"')
    new_escaped = new.replace("\\", "\\\\").replace('"', '\\"')
    old_literal = f'"{old_escaped}"'
    new_literal = f'"{new_escaped}"'

    if content.count(old_literal) == 1:
        fm.set_text(path, content.replace(old_literal, new_literal, 1))
        return True

    # Try without escaping (already escaped in source)
    old_literal = f'"{old}"'
    new_literal = f'"{new}"'
    if content.count(old_literal) == 1:
        fm.set_text(path, content.replace(old_literal, new_literal, 1))
        return True

    return False


# ─── Log Entry Builder ─────────────────────────────────────────────────

def _log_entry(action: dict, phase: str, status: str, *,
               reason: str = "", old_value: str = "", new_value: str = "",
               existing: dict | None = None) -> dict:
    entry = dict(existing or {})
    entry.update({
        "json_edit_path": action["json_edit_path"],
        "source_file": action.get("source_file", ""),
        "priority": action.get("priority", ""),
        f"{phase}_status": status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })
    if reason:
        entry["reason"] = reason
    if old_value:
        entry["old_value"] = old_value
    if new_value:
        entry["new_value"] = new_value
    return entry


# ─── Verification ─────────────────────────────────────────────────────

def run_verification(touched_files: list[Path]):
    """Run dataset validation and content audit on affected sources."""
    dataset_path = CANONICAL_JSON_FILES["astrological_style_dataset.json"]
    if dataset_path in touched_files:
        print("\n  Running dataset validation...")
        result = subprocess.run(
            [sys.executable, str(REPO_ROOT / "tools" / "validate_dataset.py"),
             str(dataset_path)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"  WARNING: Dataset validation failed:\n{result.stderr[:500]}")
        else:
            print("  Dataset validation passed.")

    sources = []
    if dataset_path in touched_files:
        sources.append("dataset")
    if CANONICAL_JSON_FILES["blueprint_narrative_cache.json"] in touched_files:
        sources.append("cache")
    swift_touched = any(p.suffix == ".swift" for p in touched_files)
    if swift_touched:
        print("  Re-extracting runtime strings...")
        subprocess.run(
            [sys.executable, str(REPO_ROOT / "tools" / "extract_runtime_style_guide_strings.py")],
            capture_output=True, text=True,
        )
        sources.append("runtime")

    if sources:
        print(f"  Re-running audit on: {', '.join(sources)}...")
        result = subprocess.run(
            [sys.executable, str(REPO_ROOT / "tools" / "content_audit.py"),
             "--sources", ",".join(sources), "--format", "json"],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            print("  Audit complete — no critical/high issues remaining.")
        else:
            print(f"  Audit complete (exit 1 — issues remain). Check audit_report.json.")


# ─── Main ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Cosmic Fit — Audit Correction Pipeline")
    parser.add_argument("--handoff", default=str(DATA_DIR / "audit_handoff_final.json"),
                        help="Path to handoff actions JSON")
    parser.add_argument("--report", default=str(DATA_DIR / "audit_report.json"),
                        help="Path to audit report JSON")
    parser.add_argument("--phase", default="all", choices=["mechanical", "rewrite", "all"],
                        help="Which phase to run")
    parser.add_argument("--priority", default="critical,high,medium,low",
                        help="Comma-separated priority levels to process")
    parser.add_argument("--limit", type=int, default=0,
                        help="Max actions to process (0 = all)")
    parser.add_argument("--batch-size", type=int, default=25,
                        help="Items per Gemini API batch")
    parser.add_argument("--dry-run", action="store_true",
                        help="Run without writing any files")
    parser.add_argument("--resume", action="store_true",
                        help="Skip actions already marked applied in log")
    parser.add_argument("--verify", action="store_true",
                        help="Run validation and re-audit after fixes")
    parser.add_argument("--api-key", default=None, help="Gemini API key override")
    parser.add_argument("--model", default=None, help="Gemini model name override")
    parser.add_argument("--backup-dir", default=None,
                        help="Existing content backup directory satisfying the backup gate "
                             "(default: a data/content_backups/ snapshot for the current UTC date)")
    parser.add_argument("--force-no-backup", action="store_true",
                        help="EMERGENCY ONLY: bypass the content-backup hard gate")
    args = parser.parse_args()

    # Content-backup hard gate (Style Guide Quality Overhaul, Phase -1).
    # Non-interactive by construction: exits 2 with a message, never prompts.
    # Dry runs write nothing, so the gate only applies to real runs.
    if not args.dry_run:
        require_backup_gate(
            script_name="content_audit_apply.py",
            backup_dir_arg=args.backup_dir,
            force_no_backup=args.force_no_backup,
        )

    load_local_env_file()

    print(f"Loading handoff: {args.handoff}")
    actions = load_handoff(Path(args.handoff))

    print(f"Loading report: {args.report}")
    report = load_report(Path(args.report))

    print("Enriching actions with report metadata...")
    actions = enrich_actions(actions, report)

    print("Filtering to canonical sources...")
    actions = filter_canonical(actions)
    print(f"  {len(actions)} canonical actions")

    priorities = set(args.priority.split(","))
    actions = filter_priority(actions, priorities)
    print(f"  {len(actions)} after priority filter ({args.priority})")

    if args.limit > 0:
        actions = actions[:args.limit]
        print(f"  Limited to {len(actions)} actions")

    # Always load prior log so a rewrite-only run does not wipe mechanical entries.
    log_entries = load_log()
    fm = FileManager(dry_run=args.dry_run)

    total_applied = 0
    total_skipped = 0
    total_failed = 0
    rewrite_queue: list[dict] = []

    try:
        # Phase 1: Mechanical
        if args.phase in ("mechanical", "all"):
            print(f"\n{'='*60}")
            print("Phase 1: Mechanical fixes")
            print(f"{'='*60}")
            rewrite_queue, mech_applied, mech_skipped, mech_stale = run_mechanical_phase(
                actions, fm, log_entries, resume=args.resume, dry_run=args.dry_run,
            )
            total_applied += mech_applied
            total_skipped += mech_skipped
            total_failed += mech_stale
            print(f"\n  Mechanical: {mech_applied} applied, {mech_skipped} skipped, {mech_stale} stale")
            print(f"  Rewrite queue: {len(rewrite_queue)} actions")
            save_log(log_entries)
            save_progress("mechanical", len(actions), len(actions), mech_applied, mech_skipped, mech_stale)

        # Phase 2: Rewrite
        if args.phase in ("rewrite", "all"):
            print(f"\n{'='*60}")
            print("Phase 2: Gemini batched rewrites")
            print(f"{'='*60}")
            if args.phase == "rewrite":
                rewrite_queue = [a for a in actions if needs_rewrite(a.get("check_ids", []))]
            if rewrite_queue:
                rw_applied, rw_skipped, rw_failed = run_rewrite_phase(
                    rewrite_queue, fm, log_entries,
                    batch_size=args.batch_size,
                    api_key=args.api_key,
                    model_name=args.model,
                    resume=args.resume,
                    dry_run=args.dry_run,
                )
                total_applied += rw_applied
                total_skipped += rw_skipped
                total_failed += rw_failed
                print(f"\n  Rewrite: {rw_applied} applied, {rw_skipped} skipped, {rw_failed} failed")
            else:
                print("  No actions need AI rewrite.")
            save_log(log_entries)
            save_progress("rewrite", len(actions), len(actions), total_applied, total_skipped, total_failed)

        # Flush all dirty files
        written = fm.flush()
        if written:
            print(f"\n  Written {len(written)} file(s):")
            for p in written:
                print(f"    {p.relative_to(REPO_ROOT)}")

        # Verification
        if args.verify and written:
            print(f"\n{'='*60}")
            print("Phase 3: Verification")
            print(f"{'='*60}")
            run_verification(written)

    except KeyboardInterrupt:
        print("\n\nInterrupted — saving progress...")
        save_log(log_entries)
        written = fm.flush()
        if written:
            print(f"  Flushed {len(written)} file(s) to disk.")
        print("  Resume with the same command (--resume).")
        sys.exit(130)

    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    print(f"  Total applied: {total_applied}")
    print(f"  Total skipped: {total_skipped}")
    print(f"  Total failed/stale: {total_failed}")
    if args.dry_run:
        print("  (DRY RUN — no files were modified)")


if __name__ == "__main__":
    main()
