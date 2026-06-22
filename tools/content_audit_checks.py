#!/usr/bin/env python3
"""
Cosmic Fit — Content Audit Checks

Every check function receives an AuditableItem and returns a list of Issue dicts.
The audit engine calls enabled checks per item based on its FieldRule.
"""

from __future__ import annotations

import re
import uuid
from collections import Counter
from typing import Optional

# Field kinds injected into user-facing Code bullets — must be full sentences
CODE_INJECTION_FIELD_KINDS = frozenset({
    "lean_into_bias",
    "code_addition_leaninto",
    "code_addition_avoid",
    "code_consider_bias",
    "opposites_mood",
})

FIELD_KIND_GUIDANCE = {
    "lean_into_bias": "lean_into_bias entries are injected into The Code Lean Into list at runtime.",
    "code_addition_leaninto": "code_addition_leaninto is injected into The Code Lean Into list from aspect data.",
    "code_addition_avoid": "code_addition_avoid is injected into The Code Avoid list from aspect data.",
    "code_consider_bias": "code_consider_bias is injected into The Code Consider list from house placement data.",
    "opposites_mood": "opposites.mood tokens are injected into The Code Avoid list as anti-tokens by DeterministicResolver at runtime.",
}

BANNED_WORDS = [
    "delve", "tapestry", "resonate", "elevate", "curate", "embark",
    "multifaceted", "realm", "robust", "leverage", "utilize", "harness",
    "holistic", "synergy", "paradigm", "nuanced", "myriad", "landscape",
    "journey", "foster", "unlock", "unleash", "seamless", "moreover",
    "furthermore",
]

AI_SLOP_PATTERNS = [
    (re.compile(r"\bit is important to note\b", re.I), "It is important to note"),
    (re.compile(r"\bin the realm of\b", re.I), "In the realm of"),
    (re.compile(r"\bthis allows you to\b", re.I), "This allows you to"),
    (re.compile(r"\bwhen it comes to your style journey\b", re.I), "When it comes to your style journey"),
    (re.compile(r"\bit'?s worth noting\b", re.I), "It's worth noting"),
    (re.compile(r"\bin today'?s world\b", re.I), "In today's world"),
    (re.compile(r"\bat the end of the day\b", re.I), "At the end of the day"),
    (re.compile(r"\bin conclusion\b", re.I), "In conclusion"),
    (re.compile(r"\blet'?s explore\b", re.I), "Let's explore"),
    (re.compile(r"\bdive into\b", re.I), "Dive into"),
]

HEDGING_PHRASES = ["you might", "perhaps", "maybe", "possibly", "could potentially"]

AMERICAN_SPELLINGS = {
    "color": "colour", "center": "centre", "organize": "organise",
    "realize": "realise", "recognize": "recognise", "favor": "favour",
    "behavior": "behaviour", "honor": "honour", "labor": "labour",
    "catalog": "catalogue", "defense": "defence", "offense": "offence",
    "jewelry": "jewellery", "gray": "grey", "traveling": "travelling",
    "modeling": "modelling", "canceled": "cancelled",
}

WEAK_OPENINGS = [
    "it is worth noting that",
    "when it comes to",
    "in terms of",
    "it goes without saying",
    "needless to say",
    "as we all know",
    "it should be noted that",
]

ASTROLOGY_JARGON = [
    re.compile(r"\bhouse\s+\d+\b", re.I),
    re.compile(r"\b(1st|2nd|3rd|4th|5th|6th|7th|8th|9th|10th|11th|12th)\s+house\b", re.I),
    re.compile(r"\b(venus|mars|jupiter|saturn|mercury|neptune|uranus|pluto)\b", re.I),
    re.compile(r"\b(conjunction|opposition|trine|sextile|square)\b", re.I),
    re.compile(r"\bnatal\s+chart\b", re.I),
    re.compile(r"\bascendant\b", re.I),
    re.compile(r"\bmidheaven\b", re.I),
]

# Passive voice heuristic: "is/was/were/been/be/being + past participle"
_PASSIVE_RE = re.compile(
    r"\b(?:is|was|were|been|be|being|are)\s+\w+(?:ed|en|t)\b", re.I
)

_EM_DASH_RE = re.compile(r"[\u2014\u2013]|(?<!\-)--(?!\-)")
_PLACEHOLDER_RE = re.compile(r"\{([a-z_0-9]+)\}")
_DOUBLE_SPACE_RE = re.compile(r"  +")
_SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])\s+")

_LANG_TOOL = None
_LANG_TOOL_FAILED = False


def _get_lang_tool():
    global _LANG_TOOL, _LANG_TOOL_FAILED
    if _LANG_TOOL_FAILED:
        return None
    if _LANG_TOOL is not None:
        return _LANG_TOOL
    try:
        import language_tool_python
        _LANG_TOOL = language_tool_python.LanguageTool("en-GB")
        return _LANG_TOOL
    except Exception as e:
        print(f"[content_audit] LanguageTool unavailable ({e}); grammar checks will be skipped.")
        _LANG_TOOL_FAILED = True
        return None


def _issue(item, check_id: str, priority: str, why: str,
           flagged_fragment: str = "", suggested_fix: str = "",
           rewrite_brief: str = "", action_type: str = "review",
           auto_fixable: bool = False, span: Optional[tuple] = None) -> dict:
    return {
        "id": str(uuid.uuid4()),
        "content_id": item.content_id,
        "check_id": check_id,
        "priority": priority,
        "why": why,
        "flagged_fragment": flagged_fragment,
        "suggested_fix": suggested_fix,
        "rewrite_brief": rewrite_brief,
        "action_type": action_type,
        "json_edit_path": item.json_edit_path,
        "auto_fixable": auto_fixable,
        "span": list(span) if span else None,
    }


# ─── CRITICAL checks ──────────────────────────────────────────────────

def check_empty_content(item) -> list[dict]:
    if not item.text or not item.text.strip():
        return [_issue(item, "empty_content", "critical",
                        "Content is empty or whitespace-only.",
                        rewrite_brief=f"Write new content for {item.ui_section}.",
                        action_type="rewrite")]
    return []


def check_broken_placeholder(item) -> list[dict]:
    if item.rule.expected_format == "template":
        return []
    issues = []
    for m in _PLACEHOLDER_RE.finditer(item.text):
        token = m.group(1)
        issues.append(_issue(
            item, "broken_placeholder", "critical",
            f"Literal placeholder {{{token}}} in user-visible text.",
            flagged_fragment=m.group(0),
            suggested_fix=f"Remove or replace {{{token}}} with actual content.",
            rewrite_brief=f"Replace {{{token}}} with a concrete value or rephrase the sentence.",
            action_type="rewrite",
            span=(m.start(), m.end()),
        ))
    return issues


def check_garbled_text(item) -> list[dict]:
    text = item.text
    garbled = re.findall(r"[\x00-\x08\x0b\x0c\x0e-\x1f\ufffd\ufffe\uffff]", text)
    if garbled:
        return [_issue(item, "garbled_text", "critical",
                        f"Found {len(garbled)} garbled/invalid character(s).",
                        flagged_fragment=repr(garbled[:5]),
                        rewrite_brief="Remove encoding artefacts and rewrite the affected text.",
                        action_type="rewrite")]
    return []


def check_narrative_too_short(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    wc = len(item.text.split())
    if wc < item.rule.min_words:
        return [_issue(item, "narrative_too_short", "critical",
                        f"Paragraph has {wc} words; minimum is {item.rule.min_words}.",
                        rewrite_brief=f"Expand to at least {item.rule.min_words} words while keeping it natural and specific.",
                        action_type="rewrite")]
    return []


def check_nonsense_fragment(item) -> list[dict]:
    if item.rule.expected_format in ("keyword", "phrase"):
        return []
    wc = len(item.text.split())
    if wc < 3 and item.text.strip():
        return [_issue(item, "nonsense_fragment", "critical",
                        f"Content is only {wc} word(s) — too short to convey meaning as a {item.rule.expected_format}.",
                        flagged_fragment=item.text.strip(),
                        rewrite_brief=f"Expand to a complete, actionable {item.rule.expected_format} of at least {item.rule.min_words} words.",
                        action_type="rewrite")]
    return []


# ─── HIGH checks ──────────────────────────────────────────────────────

def check_wrong_format_for_field(item) -> list[dict]:
    kind = getattr(item, "field_kind", "")
    if kind not in CODE_INJECTION_FIELD_KINDS:
        return []
    wc = len(item.text.split())
    text = item.text.strip()
    if wc >= 8 and text.endswith("."):
        return []
    guidance = FIELD_KIND_GUIDANCE.get(kind, "This field feeds user-facing Code bullets.")
    return [_issue(
        item, "wrong_format_for_field", "high",
        f"{guidance} Users see this as a standalone bullet, but it is a {wc}-word fragment not a full actionable sentence.",
        flagged_fragment=text[:80],
        rewrite_brief=(
            "Rewrite as one complete British-English actionable sentence (8–20 words), "
            "capitalised, ending with a full stop. Explain what the user should actually do."
        ),
        action_type="rewrite",
    )]


def check_sparse_code_bullet(item) -> list[dict]:
    if item.rule.expected_format not in ("actionable_bullet",):
        return []
    wc = len(item.text.split())
    if wc < item.rule.min_words:
        return [_issue(item, "sparse_code_bullet", "high",
                        f"Bullet has only {wc} word(s); users see this as a vague, unhelpful direction.",
                        flagged_fragment=item.text.strip(),
                        rewrite_brief=f"Expand to one complete British-English sentence ({item.rule.min_words}–{item.rule.max_words} words), actionable, explaining what the user should actually do.",
                        action_type="rewrite")]
    return []


def check_not_a_sentence(item) -> list[dict]:
    if not item.rule.is_sentence_expected:
        return []
    text = item.text.strip()
    if not text:
        return []
    words = text.split()
    if len(words) < 4:
        return []
    common_verbs = {"is", "are", "was", "were", "has", "have", "had", "do", "does",
                    "did", "will", "would", "could", "should", "can", "may", "might",
                    "shall", "must", "let", "make", "keep", "get", "go", "come",
                    "take", "give", "look", "find", "use", "feel", "dress", "wear",
                    "choose", "invest", "try", "avoid", "lean", "think", "treat",
                    "build", "add", "pull", "seek", "skip", "buy", "need", "want",
                    "trust", "stick", "ditch", "swap", "bring", "strip", "aim",
                    "focus", "commit", "consider", "prioritise", "embrace", "rely",
                    "project", "communicate", "signal", "read", "suit", "work",
                    "move", "walk", "run", "sit", "stand", "provides", "offers",
                    "delivers", "creates", "carries", "holds", "lets", "gives",
                    "means", "requires", "demands", "needs", "belongs", "feels",
                    "abandon", "adopt", "align", "anchor", "apply", "assert",
                    "assess", "balance", "ban", "banish", "base", "bin", "boycott",
                    "broadcast", "broaden", "bypass", "cease", "channel", "claim",
                    "clear", "combine", "command", "conceal", "construct", "defend",
                    "demand", "deploy", "discard", "disrupt", "dodge", "drop",
                    "edit", "eliminate", "enforce", "eradicate", "establish",
                    "execute", "expand", "exploit", "express", "flip", "ground",
                    "halt", "hide", "honour", "ignore", "include", "inject",
                    "integrate", "introduce", "investigate", "judge", "layer",
                    "leave", "maintain", "map", "master", "mirror", "mix", "never",
                    "overcome", "pay", "practise", "present", "prevent", "quit",
                    "refuse", "reject", "remove", "resist", "restrain", "root",
                    "schedule", "scrap", "scrutinise", "select", "sharpen", "shun",
                    "sidestep", "source", "steal", "steer", "step", "stop", "style",
                    "support", "swerve", "test", "throw", "tone", "wield", "wrap"}
    lower_words = {w.lower().rstrip(".,;:!?") for w in words}
    has_verb = bool(lower_words & common_verbs)
    if not has_verb:
        return [_issue(item, "not_a_sentence", "high",
                        "This reads as a label or fragment rather than a complete sentence with a verb.",
                        flagged_fragment=text[:80],
                        rewrite_brief="Rewrite as a complete sentence with a subject and verb.",
                        action_type="rewrite")]
    return []


def check_vague_direction(item) -> list[dict]:
    if item.rule.expected_format != "actionable_bullet":
        return []
    wc = len(item.text.split())
    if 3 <= wc <= 5:
        lower = item.text.lower().strip().rstrip(".")
        common_verbs = {"let", "use", "wear", "choose", "invest", "try", "avoid",
                        "lean", "think", "treat", "build", "dress", "keep", "seek",
                        "add", "skip", "buy", "ditch", "swap", "bring"}
        first_word = lower.split()[0] if lower else ""
        if first_word not in common_verbs:
            return [_issue(item, "vague_direction", "high",
                            f"This {wc}-word bullet is vague and unlikely to help a user.",
                            flagged_fragment=item.text.strip(),
                            rewrite_brief="Expand with a concrete action and object: what should the user do and why?",
                            action_type="rewrite")]
    return []


def check_grammar_error(item) -> list[dict]:
    if not item.rule.is_sentence_expected:
        return []
    text = item.text
    if item.rule.expected_format == "template":
        text = _PLACEHOLDER_RE.sub("something", text)
    lt = _get_lang_tool()
    if lt is None:
        return []
    issues = []
    try:
        matches = lt.check(text)
        for m in matches:
            if m.ruleId in ("WHITESPACE_RULE", "COMMA_PARENTHESIS_WHITESPACE",
                             "EN_QUOTES", "UPPERCASE_SENTENCE_START"):
                continue
            issues.append(_issue(
                item, "grammar_error", "high",
                f"Grammar: {m.message} (rule: {m.ruleId})",
                flagged_fragment=text[m.offset:m.offset + m.errorLength],
                suggested_fix=m.replacements[0] if m.replacements else "",
                rewrite_brief=f"Fix grammar issue: {m.message}",
                action_type="fix",
                span=(m.offset, m.offset + m.errorLength),
            ))
    except Exception:
        pass
    return issues


def check_pidgin_english(item) -> list[dict]:
    if not item.rule.is_sentence_expected:
        return []
    text = item.text.strip()
    if not text or len(text.split()) < 10:
        return []
    sentences = _SENTENCE_SPLIT_RE.split(text)
    issues = []
    for sent in sentences:
        sent = sent.strip()
        if not sent or len(sent.split()) < 8:
            continue
        words = sent.split()
        lower_words = [w.lower().rstrip(".,;:!?") for w in words]
        articles = {"a", "an", "the", "your", "their", "its", "this", "that", "these",
                    "those", "every", "each", "any", "some", "no", "my", "our", "his", "her"}
        has_article = bool(set(lower_words) & articles)
        if not has_article and len(words) > 8:
            issues.append(_issue(
                item, "pidgin_english", "high",
                "Sentence lacks articles/determiners, which may read as unnatural or broken English.",
                flagged_fragment=sent[:80],
                rewrite_brief="Add appropriate articles (a, the, your) to make this read as natural spoken English.",
                action_type="rewrite",
            ))
    return issues


def check_ai_slop_words(item) -> list[dict]:
    lower = item.text.lower()
    issues = []
    for word in BANNED_WORDS:
        if re.search(r"\b" + re.escape(word) + r"\b", lower):
            issues.append(_issue(
                item, "ai_slop_words", "high",
                f"AI-typical word '{word}' found.",
                flagged_fragment=word,
                suggested_fix=f"Replace '{word}' with a more natural alternative.",
                rewrite_brief=f"Remove or replace the AI-typical word '{word}' with plain, natural English.",
                action_type="fix",
                auto_fixable=False,
            ))
    return issues


def check_ai_slop_patterns(item) -> list[dict]:
    issues = []
    for pattern, label in AI_SLOP_PATTERNS:
        m = pattern.search(item.text)
        if m:
            issues.append(_issue(
                item, "ai_slop_patterns", "high",
                f"AI-typical phrase pattern: '{label}'.",
                flagged_fragment=m.group(0),
                rewrite_brief=f"Rephrase to avoid the cliched AI pattern '{label}'.",
                action_type="rewrite",
                span=(m.start(), m.end()),
            ))
    return issues


def check_intra_paragraph_repetition(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    words = item.text.lower().split()
    if len(words) < 20:
        return []
    issues = []
    # Check 4-gram repetition
    ngrams: Counter = Counter()
    for i in range(len(words) - 3):
        ng = " ".join(words[i:i+4])
        ngrams[ng] += 1
    for ng, count in ngrams.items():
        if count >= 2:
            issues.append(_issue(
                item, "intra_paragraph_repetition", "high",
                f"Phrase '{ng}' repeated {count} times within the same paragraph.",
                flagged_fragment=ng,
                rewrite_brief=f"Rephrase to avoid repeating '{ng}' multiple times.",
                action_type="rewrite",
            ))
            break  # one per paragraph is enough

    # Check stem-word overuse (same word 4+ times, excluding common words)
    stop_words = {"the", "a", "an", "is", "are", "was", "were", "and", "or", "but",
                  "of", "in", "to", "for", "with", "on", "at", "by", "from", "that",
                  "this", "it", "you", "your", "not", "as", "be", "has", "have", "had",
                  "do", "does", "its", "when", "than", "no", "so", "if", "up"}
    word_counts = Counter(w.strip(".,;:!?\"'()") for w in words if w.strip(".,;:!?\"'()") not in stop_words)
    for word, count in word_counts.most_common(3):
        if count >= 4 and len(word) > 3:
            issues.append(_issue(
                item, "intra_paragraph_repetition", "high",
                f"Word '{word}' used {count} times in one paragraph.",
                flagged_fragment=word,
                rewrite_brief=f"Vary vocabulary: '{word}' appears {count} times. Use synonyms or restructure sentences.",
                action_type="rewrite",
            ))
            break
    return issues


def check_missing_second_person(item) -> list[dict]:
    if not item.rule.requires_second_person:
        return []
    if not any(w in item.text for w in ("You", "Your", "you", "your")):
        return [_issue(item, "missing_second_person", "high",
                        "No second-person address (you/your). Narrative should speak directly to the user.",
                        rewrite_brief="Rewrite to address the user directly using 'you' and 'your'.",
                        action_type="rewrite")]
    return []


def check_composed_code_inconsistency(item) -> list[dict]:
    """Called externally with a list of bullets, not per-item."""
    return []


# ─── MEDIUM checks ────────────────────────────────────────────────────

def check_em_dash(item) -> list[dict]:
    issues = []
    for m in _EM_DASH_RE.finditer(item.text):
        char = m.group(0)
        before = item.text[max(0, m.start()-20):m.start()]
        after = item.text[m.end():m.end()+20]
        issues.append(_issue(
            item, "em_dash", "medium",
            f"Em-dash/en-dash found. Replace with comma or semicolon.",
            flagged_fragment=f"...{before}{char}{after}...",
            suggested_fix=f"...{before},{after}...",
            rewrite_brief="Replace em-dash or en-dash with a comma or semicolon.",
            action_type="fix",
            auto_fixable=True,
            span=(m.start(), m.end()),
        ))
    return issues


def check_capitalisation(item) -> list[dict]:
    if not item.rule.is_sentence_expected:
        return []
    text = item.text.strip()
    if not text:
        return []
    issues = []
    if text[0].isalpha() and not text[0].isupper():
        issues.append(_issue(
            item, "capitalisation", "medium",
            "Content does not start with a capital letter.",
            flagged_fragment=text[:20],
            suggested_fix=text[0].upper() + text[1:20],
            rewrite_brief="Capitalise the first letter.",
            action_type="fix",
            auto_fixable=True,
        ))
    return issues


def check_missing_terminal_punctuation(item) -> list[dict]:
    if not item.rule.requires_terminal_period:
        return []
    text = item.text.strip()
    if text and not text[-1] in ".!?":
        return [_issue(item, "missing_terminal_punctuation", "medium",
                        "Sentence-expected content does not end with terminal punctuation.",
                        flagged_fragment=text[-30:],
                        suggested_fix=text + ".",
                        rewrite_brief="Add a full stop at the end.",
                        action_type="fix",
                        auto_fixable=True)]
    return []


def check_hedging_language(item) -> list[dict]:
    lower = item.text.lower()
    issues = []
    for phrase in HEDGING_PHRASES:
        if re.search(r"\b" + re.escape(phrase) + r"\b", lower):
            issues.append(_issue(
                item, "hedging_language", "medium",
                f"Hedging phrase '{phrase}' weakens the writing.",
                flagged_fragment=phrase,
                rewrite_brief=f"Replace hedging phrase '{phrase}' with a confident, direct statement.",
                action_type="rewrite",
            ))
    return issues


def check_american_spelling(item) -> list[dict]:
    lower = item.text.lower()
    issues = []
    for us, uk in AMERICAN_SPELLINGS.items():
        if re.search(r"\b" + re.escape(us) + r"\b", lower):
            issues.append(_issue(
                item, "american_spelling", "medium",
                f"American spelling '{us}' — should be '{uk}'.",
                flagged_fragment=us,
                suggested_fix=uk,
                rewrite_brief=f"Change '{us}' to British English '{uk}'.",
                action_type="fix",
                auto_fixable=True,
            ))
    return issues


def check_excessive_length(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    wc = len(item.text.split())
    if wc > item.rule.max_words:
        return [_issue(item, "excessive_length", "medium",
                        f"Paragraph has {wc} words; maximum is {item.rule.max_words}.",
                        rewrite_brief=f"Tighten to under {item.rule.max_words} words without losing meaning.",
                        action_type="rewrite")]
    return []


def check_unknown_placeholder(item) -> list[dict]:
    if item.rule.expected_format != "template":
        return []
    from content_audit_inventory import KNOWN_PLACEHOLDERS
    issues = []
    for m in _PLACEHOLDER_RE.finditer(item.text):
        token = m.group(1)
        if token not in KNOWN_PLACEHOLDERS:
            issues.append(_issue(
                item, "unknown_placeholder", "medium",
                f"Placeholder {{{token}}} is not in the known list from NarrativeTemplateRenderer.",
                flagged_fragment=m.group(0),
                rewrite_brief=f"Verify {{{token}}} is valid or replace with a known placeholder.",
                action_type="review",
                span=(m.start(), m.end()),
            ))
    return issues


def check_astrology_jargon_leak(item) -> list[dict]:
    if item.source_layer in ("dataset",) and item.rule.expected_format in ("keyword", "phrase"):
        return []
    issues = []
    for pattern in ASTROLOGY_JARGON:
        m = pattern.search(item.text)
        if m:
            issues.append(_issue(
                item, "astrology_jargon_leak", "medium",
                f"Astrological jargon '{m.group(0)}' in user-facing text.",
                flagged_fragment=m.group(0),
                rewrite_brief=f"Replace '{m.group(0)}' with plain language — no chart terminology in user copy.",
                action_type="rewrite",
                span=(m.start(), m.end()),
            ))
    return issues


def check_double_space(item) -> list[dict]:
    m = _DOUBLE_SPACE_RE.search(item.text)
    if m:
        return [_issue(item, "double_space", "medium",
                        "Double space found.",
                        flagged_fragment=item.text[max(0, m.start()-10):m.end()+10],
                        suggested_fix=_DOUBLE_SPACE_RE.sub(" ", item.text[:50]),
                        rewrite_brief="Replace double spaces with single spaces.",
                        action_type="fix",
                        auto_fixable=True,
                        span=(m.start(), m.end()))]
    return []


def check_non_declarative_ending(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    if item.text.strip().endswith("?"):
        return [_issue(item, "non_declarative_ending", "medium",
                        "Narrative ends with a question mark — should be declarative.",
                        rewrite_brief="Rewrite the final sentence as a statement, not a question.",
                        action_type="rewrite")]
    return []


# ─── LOW checks ───────────────────────────────────────────────────────

def check_passive_voice_heavy(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    sentences = _SENTENCE_SPLIT_RE.split(item.text)
    if len(sentences) < 3:
        return []
    passive_count = sum(1 for s in sentences if _PASSIVE_RE.search(s))
    ratio = passive_count / len(sentences)
    if ratio > 0.4:
        return [_issue(item, "passive_voice_heavy", "low",
                        f"{passive_count}/{len(sentences)} sentences use passive voice ({ratio:.0%}).",
                        rewrite_brief="Rewrite passive sentences to active voice for more direct, engaging prose.",
                        action_type="rewrite")]
    return []


def check_sentence_start_repetition(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    sentences = _SENTENCE_SPLIT_RE.split(item.text)
    if len(sentences) < 3:
        return []
    starts = [s.strip().split()[0].lower() for s in sentences if s.strip()]
    counts = Counter(starts)
    for word, count in counts.most_common(1):
        if count >= 3:
            return [_issue(item, "sentence_start_repetition", "low",
                            f"{count} sentences start with '{word}'.",
                            flagged_fragment=word,
                            rewrite_brief=f"Vary sentence openings — {count} start with '{word}'.",
                            action_type="rewrite")]
    return []


def check_weak_opening(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    lower = item.text.lower().strip()
    for opener in WEAK_OPENINGS:
        if lower.startswith(opener):
            return [_issue(item, "weak_opening", "low",
                            f"Paragraph opens with filler phrase '{opener}'.",
                            flagged_fragment=opener,
                            rewrite_brief=f"Cut the filler opening '{opener}' and start with the actual point.",
                            action_type="rewrite")]
    return []


def check_list_style_inconsistency(item) -> list[dict]:
    # Handled at aggregate level by the engine, not per-item
    return []


def check_keyword_stuffing(item) -> list[dict]:
    if item.rule.expected_format not in ("paragraph", "template"):
        return []
    words = item.text.split()
    if len(words) < 30:
        return []
    ly_count = sum(1 for w in words if w.lower().endswith("ly") and len(w) > 4)
    ratio = ly_count / len(words)
    if ratio > 0.08:
        return [_issue(item, "keyword_stuffing", "low",
                        f"High density of -ly adverbs ({ly_count}/{len(words)} = {ratio:.0%}).",
                        rewrite_brief="Reduce adverb density; prefer stronger verbs and nouns.",
                        action_type="rewrite")]
    return []


_PALETTE_COLOUR_LITERALS = [
    "burnt siennas", "burnt sienna", "warm ochre", "cobalt blue", "deep cobalt",
    "electric blue", "fire red", "bright coral", "deep coral", "silver grey",
    "jet black", "ochres", "siennas", "ochre", "sienna", "cobalt", "coral",
]
_PALETTE_LITERAL_PATTERNS = [
    (re.compile(r"\b" + re.escape(lit) + r"\b", re.IGNORECASE), lit)
    for lit in sorted(_PALETTE_COLOUR_LITERALS, key=len, reverse=True)
]
_PALETTE_ALLOWLIST = [
    "matte silver", "cold steel", "brushed steel", "brushed silver",
    "industrial silver", "matte silver-grey", "silver-grey",
    "unpolished silver", "polished silver", "thick matte silver",
    "heavy steel", "cold silver",
]
_GROUP_B_PALETTE_SECTIONS = frozenset([
    "pattern_tip", "pattern_narrative",
    "hardware_metals", "hardware_stones", "hardware_tip",
])


def check_hardcoded_palette_colour_in_group_b(item) -> list[dict]:
    section = getattr(item, "section_key", "") or ""
    if section not in _GROUP_B_PALETTE_SECTIONS:
        return []
    text = _PLACEHOLDER_RE.sub(" ", item.text)
    issues = []
    for pat, literal in _PALETTE_LITERAL_PATTERNS:
        for m in pat.finditer(text):
            window_start = max(0, m.start() - 30)
            window_end = min(len(text), m.end() + 30)
            window = text[window_start:window_end].lower()
            if any(phrase in window for phrase in _PALETTE_ALLOWLIST):
                continue
            issues.append(_issue(
                item, "hardcoded_palette_colour_in_group_b", "high",
                f"Hardcoded palette colour \"{literal}\" in {section}; should use a {{core_colour_*}} or {{accent_colour_*}} placeholder.",
                flagged_fragment=text[max(0, m.start() - 20):m.end() + 20].strip(),
                suggested_fix=f"Replace \"{literal}\" with the appropriate {{core_colour_*}} or {{accent_colour_*}} placeholder.",
                rewrite_brief=f"Replace literal colour name with a palette placeholder.",
                action_type="rewrite",
                span=(m.start(), m.end()),
            ))
    return issues


# ─── Check registry ───────────────────────────────────────────────────

ALL_CHECKS = [
    # CRITICAL
    check_empty_content,
    check_broken_placeholder,
    check_garbled_text,
    check_narrative_too_short,
    check_nonsense_fragment,
    # HIGH
    check_sparse_code_bullet,
    check_wrong_format_for_field,
    check_not_a_sentence,
    check_vague_direction,
    check_grammar_error,
    check_pidgin_english,
    check_ai_slop_words,
    check_ai_slop_patterns,
    check_intra_paragraph_repetition,
    check_missing_second_person,
    check_hardcoded_palette_colour_in_group_b,
    # MEDIUM
    check_em_dash,
    check_capitalisation,
    check_missing_terminal_punctuation,
    check_hedging_language,
    check_american_spelling,
    check_excessive_length,
    check_unknown_placeholder,
    check_astrology_jargon_leak,
    check_double_space,
    check_non_declarative_ending,
    # LOW
    check_passive_voice_heavy,
    check_sentence_start_repetition,
    check_weak_opening,
    check_keyword_stuffing,
]


def run_checks(item) -> list[dict]:
    """Run all applicable checks against an AuditableItem."""
    enabled = item.rule.checks_enabled
    issues = []
    for check_fn in ALL_CHECKS:
        check_name = check_fn.__name__.replace("check_", "")
        if enabled and check_name not in enabled:
            continue
        issues.extend(check_fn(item))
    return issues
