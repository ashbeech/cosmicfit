#!/usr/bin/env python3
"""
Shared rules for Code bullet section header flow (Lean Into / Avoid / Consider).

Bullets are read as continuations of their section title:
  Lean Into → gerund opening
  Avoid     → noun phrase or gerund (no redundant Avoid/Resist/Skip…)
  Consider  → gerund OR noun/article phrase (One/A/The/Whether…)
"""

from __future__ import annotations

import re
from typing import Literal

SectionKind = Literal["lean_into", "avoid", "consider"]

GERUND_RE = re.compile(r"^[A-Z][a-z]+ing\b")

CONSIDER_NOUN_OK = re.compile(
    r"^(One |A |An |The |Whether |How |Anything|Any |Your |Colour |Color |Versatile |Soft |"
    r"Accessories |Reversible |Head-to-toe |Cold, |Ugly-on-purpose|Conventional |"
    r"Nostalgia-driven|Apologetic |Visible |Overly |Complicated |Cheap |Harsh |"
    r"Aggressively |Ill-fitting |Rigid |Strictly |Basic |Predictable |Monotonous |"
    r"Clinical |Stark |Severe |Sloppy |Disordered |Overtly |Deliberately |Trendy |"
    r"Self-effacing |Historically |Totally |Intensely |Disposable |Impulsive |Trend-led |"
    r"Fast |Fragile |Fussy |Fiddly |Muted |Bold |Flat |Under |Non-|Nothing |Nobody |Not )",
    re.I,
)

# Leading directive verbs that duplicate the Avoid section title when read aloud.
AVOID_REDUNDANT_SINGLE = re.compile(
    r"^(Avoid|Resist|Skip|Stop|Reject|Refuse|Ditch|Shun|Banish|Quit|Cease|Eliminate|"
    r"Discard|Drop|Bin|Boycott|Halt|Defend|Prevent|Restrain|Eliminate|Walk)\b",
    re.I,
)

AVOID_REDUNDANT_PHRASES = [
    (re.compile(r"^Refuse to \w+ into ", re.I), ""),
    (re.compile(r"^Refuse to ", re.I), ""),
    (re.compile(r"^Never wear ", re.I), ""),
    (re.compile(r"^Never buy ", re.I), ""),
    (re.compile(r"^Never ", re.I), ""),
    (re.compile(r"^Walk away from ", re.I), ""),
    (re.compile(r"^Do not ", re.I), ""),
    (re.compile(r"^Don't ", re.I), ""),
]

LEAN_INTO_FIELD_KINDS = frozenset({
    "code_leaninto", "lean_into_bias", "code_addition_leaninto",
})
AVOID_FIELD_KINDS = frozenset({
    "code_avoid", "opposites_mood", "code_addition_avoid",
})
CONSIDER_FIELD_KINDS = frozenset({
    "code_consider", "code_consider_bias",
})

IMPERATIVE_FIRST = re.compile(
    r"^(Wear|Keep|Invest|Plan|Dress|Anchor|Introduce|Make|Use|Choose|Build|Add|Try|"
    r"Pair|Layer|Match|Edit|Curate|Seek|Commit|Focus|Start|Embrace|Favour|Favor|Opt|"
    r"Pick|Grab|Hold|Take|Give|Show|Set|Create|Balance|Swap|Switch|Shift|Move|Step|"
    r"Run|Walk|Work|Play|Look|Feel|Think|Remember|Notice|Watch|Check|Test|Ask|Tell|"
    r"Speak|Write|Read|Learn|Study|Practice|Experiment|Explore|Discover|Find|Get|Go|"
    r"Come|Stay|Leave|Return|Bring|Carry|Put|Place|Turn|Open|Close|Save|Spend|Pay|"
    r"Buy|Sell|Order|Send|Receive|Accept|Decline|Deny|Allow|Permit|Block|Remove|Clear|"
    r"Clean|Wash|Dry|Iron|Fold|Hang|Store|Organise|Organize|Sort|Filter|Search|Scan|"
    r"Review|Rate|Rank|Score|Mark|Tag|Label|Name|Call|Define|Describe|Explain|Justify|"
    r"Defend|Support|Help|Assist|Aid|Serve|Provide|Offer|Supply|Deliver|Track|Monitor|"
    r"Measure|Count|Calculate|Estimate|Predict|Forecast|Project|Schedule|Book|Reserve|"
    r"Register|Sign|Join|Exit|Enter|Begin|End|Finish|Complete|Continue|Pause|Wait|"
    r"Delay|Hurry|Rush|Slow|Speed|Increase|Decrease|Raise|Lower|Boost|Reduce|Minimize|"
    r"Maximize|Optimise|Optimize|Improve|Enhance|Upgrade|Downgrade|Fix|Repair|Restore|"
    r"Replace|Renew|Refresh|Update|Change|Modify|Adjust|Adapt|Customise|Customize|"
    r"Personalise|Personalize|Tailor|Fit|Size|Scale|Grow|Shrink|Stretch|Expand|Contract|"
    r"Extend|Shorten|Lengthen|Widen|Narrow|Soften|Harden|Strengthen|Weaken|Tighten|"
    r"Loosen|Fasten|Button|Zip|Snap|Hook|Clip|Tie|Knot|Buckle|Lace|Thread|Weave|Knit|"
    r"Crochet|Sew|Stitch|Hem|Dart|Pleat|Gather|Ruffle|Fringe|Tassel|Bead|Sequin|"
    r"Embroider|Applique|Print|Dye|Bleach|Stain|Fade|Patina|Age|Break|Install|Treat|"
    r"Select|Prioritise|Prioritize|Honour|Honor|Trust|Stick|Touch|Touch|Designate|Collect|"
    r"Combine|Include|Control|Let|Exploit|Integrate|Channel|Express|Find|Adopt|Conceal|"
    r"Play|Schedule|Prioritising|Walk|Halt|Defend|Prevent|Quit|Restrain|Drop|Eliminate|"
    r"Stop|Avoid|Resist|Reject|Refuse|Skip|Banish|Ditch|Shun|Never|Source|Steer|Wield|"
    r"Throw|Tone|Wrap|Ground|Assert|Deploy|Execute|Flip|Hide|Ignore|Inject|Layer|Map|"
    r"Master|Mirror|Mix|Pay|Practise|Practice|Present|Scrutinise|Scrutinize|Sharpen|"
    r"Sidestep|Steal|Style|Swerve|Broadcast|Broaden|Bypass|Claim|Clear|Command|Construct|"
    r"Demand|Disrupt|Dodge|Edit|Enforce|Eradicate|Establish|Expand|Express|Honour|Honour|"
    r"Incorporate|Lead|Apply|Maintain|Judge|Hunt|Indulge|Achieve|Root|Rely|Aim|Align|"
    r"Overcome|Concentrate|Lean|Assess|Audit)\b",
    re.I,
)

# Edge cases where mechanical transform is unreliable — queue for manual/AI rewrite.
AVOID_EDGE_CASE = re.compile(
    r"^(Refuse to|Stop \w+-chasing|Walk away|Never wear|Never buy|Halt the|Defend your|"
    r"Prevent your|Quit hiding|Restrain your|Eliminate any|Drop those|Banish every)\b",
    re.I,
)

IRREGULAR_GERUNDS = {
    "be": "being",
    "let": "letting",
    "run": "running",
    "sit": "sitting",
    "get": "getting",
    "dig": "digging",
    "stop": "stopping",
    "plan": "planning",
    "tie": "tying",
    "die": "dying",
    "lie": "lying",
}


def section_kind_from_item(field_kind: str = "", ui_section: str = "") -> SectionKind | None:
    fk = field_kind or ""
    if fk in LEAN_INTO_FIELD_KINDS:
        return "lean_into"
    if fk in AVOID_FIELD_KINDS:
        return "avoid"
    if fk in CONSIDER_FIELD_KINDS:
        return "consider"
    ui = ui_section.lower()
    if "lean into" in ui:
        return "lean_into"
    if "avoid" in ui:
        return "avoid"
    if "consider" in ui:
        return "consider"
    return None


def _capitalize_first(text: str) -> str:
    if not text:
        return text
    return text[0].upper() + text[1:]


def imperative_to_gerund(word: str) -> str:
    """Convert first word imperative to gerund form."""
    lower = word.lower().rstrip(".,;:!?")
    if lower in IRREGULAR_GERUNDS:
        base = IRREGULAR_GERUNDS[lower]
    elif lower.endswith("ie"):
        base = lower[:-2] + "ying"
    elif lower.endswith("e") and not lower.endswith("ee"):
        base = lower[:-1] + "ing"
    elif len(lower) >= 3 and lower[-1] not in "aeiou" and lower[-2] in "aeiou" and lower[-3] not in "aeiou":
        base = lower + lower[-1] + "ing"
    else:
        base = lower + "ing"
    # British -ise verbs
    if lower.endswith("ise"):
        base = lower[:-1] + "ing"  # prioritise -> prioritising
    if word[0].isupper():
        return _capitalize_first(base)
    return base


def strip_avoid_redundant(text: str) -> tuple[str, bool]:
    """Strip leading Avoid-section redundant verbs. Returns (new_text, was_edge_case)."""
    t = text.strip()
    edge = bool(AVOID_EDGE_CASE.match(t))

    for pat, repl in AVOID_REDUNDANT_PHRASES:
        if pat.match(t):
            t = pat.sub(repl, t, count=1)
            break
    else:
        m = AVOID_REDUNDANT_SINGLE.match(t)
        if m:
            verb = m.group(1).lower()
            t = t[m.end():].lstrip()
            if verb == "skip" and t.lower().startswith("the "):
                t = t[4:]

    t = _capitalize_first(t.lstrip())
    return t, edge


def fix_lean_into(text: str) -> tuple[str, bool]:
    """Return (fixed_text, needs_manual). needs_manual if cannot auto-fix."""
    t = text.strip()
    if GERUND_RE.match(t):
        return t, False
    # "Lean heavily into…" / "Lean into your…" — strip duplicate section verb
    if re.match(r"^Lean\s+(heavily\s+)?into\s+", t, re.I):
        t = re.sub(r"^Lean\s+(heavily\s+)?into\s+", "", t, count=1, flags=re.I)
        t = _capitalize_first(t)
    m = IMPERATIVE_FIRST.match(t)
    if m:
        if m.group(1).lower() == "lean":
            # "Lead with…" handled; "Lean heavily" already stripped
            rest = t[m.end():].lstrip()
            return _capitalize_first(rest), False
        gerund = imperative_to_gerund(m.group(1))
        rest = t[m.end():]
        return gerund + rest, False
    # Noun/adjective phrase → prefix with Prioritising for natural "Lean into prioritising…"
    if re.match(r"^[A-Z]", t):
        return f"Prioritising {t[0].lower()}{t[1:]}", False
    return t, True


def fix_consider(text: str) -> tuple[str, bool]:
    t = text.strip()
    if GERUND_RE.match(t) or CONSIDER_NOUN_OK.match(t):
        return t, False
    m = IMPERATIVE_FIRST.match(t)
    if not m:
        return t, True
    gerund = imperative_to_gerund(m.group(1))
    rest = t[m.end():]
    return gerund + rest, False


def fix_avoid(text: str) -> tuple[str, bool]:
    t = text.strip()
    if not AVOID_REDUNDANT_SINGLE.match(t) and not any(p.match(t) for p, _ in AVOID_REDUNDANT_PHRASES):
        return t, False
    new, edge = strip_avoid_redundant(t)
    return new, edge


def header_flow_violation(text: str, section: SectionKind) -> str | None:
    """Return violation reason or None if OK."""
    t = text.strip()
    if not t:
        return None
    if section == "lean_into":
        if GERUND_RE.match(t):
            return None
        if IMPERATIVE_FIRST.match(t):
            return "lean_into_imperative"
        return "lean_into_not_gerund"
    if section == "avoid":
        if AVOID_REDUNDANT_SINGLE.match(t):
            return "avoid_redundant_verb"
        if any(p.match(t) for p, _ in AVOID_REDUNDANT_PHRASES):
            return "avoid_redundant_phrase"
        return None
    if section == "consider":
        if GERUND_RE.match(t):
            return None
        if CONSIDER_NOUN_OK.match(t):
            return None
        if t.lower().startswith("how "):
            return None
        if IMPERATIVE_FIRST.match(t):
            return "consider_imperative"
        # Other capitalized noun/adjective phrases ("Colour harmony…") are valid.
        if re.match(r"^[A-Z]", t):
            return None
        return "consider_imperative"
    return None


def auto_fix(text: str, section: SectionKind) -> tuple[str, bool, str]:
    """
    Attempt mechanical fix. Returns (new_text, changed, status).
    status: ok | fixed | manual_needed
    """
    if header_flow_violation(text, section) is None:
        return text, False, "ok"
    if section == "lean_into":
        new, manual = fix_lean_into(text)
        if manual:
            return text, False, "manual_needed"
        return new, new != text, "fixed"
    if section == "avoid":
        new, edge = fix_avoid(text)
        if new == text:
            return text, False, "manual_needed"
        if edge and header_flow_violation(new, section):
            return text, False, "manual_needed"
        return new, new != text, "fixed"
    if section == "consider":
        new, manual = fix_consider(text)
        if manual:
            return text, False, "manual_needed"
        return new, new != text, "fixed"
    return text, False, "manual_needed"


REWRITE_BRIEFS = {
    "lean_into": (
        "Rewrite so the bullet completes 'Lean into ___' with a gerund opening (-ing). "
        "Never repeat 'Lean into' or use imperatives (Build, Choose, Use). "
        "Example: 'Building your wardrobe foundation on warm neutrals…'"
    ),
    "avoid": (
        "Rewrite so the bullet completes 'Avoid ___' with a noun phrase or gerund. "
        "Never use Avoid, Resist, Skip, Stop, Reject, Refuse, Ditch, Banish, or Never. "
        "Example: 'Harsh synthetic fabrics that trap heat and static…'"
    ),
    "consider": (
        "Rewrite so the bullet completes 'Consider ___' with a gerund OR noun phrase "
        "(One/A/The/Whether). Never use imperatives like Wear, Build, Use. "
        "Example: 'Wearing intriguing tactile textures…' or 'One statement piece rather than…'"
    ),
}
