#!/usr/bin/env python3
"""
Cosmic Fit — Colour metal/fabric vocabulary audit.

Flags palette colour names that share vocabulary with metal/hardware
recommendations (the "Metal Tone" slider: Cool/Mixed/Warm for jewellery).
Names like `aged brass`, `Antique Brass`, `Burnt Copper` describe FABRIC
colours but can confuse users because they overlap with the hardware
recommendation vocabulary.

For each flagged name the tool builds a reachability map showing where the
name surfaces in the user-facing UI: family/band membership, sign accent
expressions, chart-signature nearest-match status, and Daily Fit eligibility.

Outputs:
  data/style_guide/colour_metal_fabric_audit.json
  data/style_guide/colour_metal_fabric_audit.md

Usage:
  python3 tools/colour_metal_fabric_audit.py
  python3 tools/colour_metal_fabric_audit.py --validate-proposals FILE
"""

from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO = Path(__file__).resolve().parents[1]
PALETTE_SWIFT = REPO / "Cosmic Fit/InterpretationEngine/ColourEngineV4/PaletteLibrary.swift"
SIGN_SWIFT = REPO / "Cosmic Fit/InterpretationEngine/ColourEngineV4/SignArchetypes.swift"
CHART_SWIFT = REPO / "Cosmic Fit/InterpretationEngine/ColourEngineV4/ChartSignatureResolver.swift"
OUT_JSON = REPO / "data/style_guide/colour_metal_fabric_audit.json"
OUT_MD = REPO / "data/style_guide/colour_metal_fabric_audit.md"

# ---------------------------------------------------------------------------
# Metal keyword heuristic
# ---------------------------------------------------------------------------

PRIMARY_METALS = frozenset({
    "brass", "bronze", "copper", "gold", "silver", "pewter",
    "gunmetal", "chrome", "platinum", "nickel", "steel",
})

COMPOUND_PREFIXES = frozenset({"burnished", "antique"})

EXCLUSIONS: set[str] = {"goldenrod", "marigold"}


def _metal_keywords_matched(name: str) -> list[str]:
    """Return metal keywords that triggered a flag for `name`, or empty list."""
    lower = name.lower()

    # Early-exit: exclusion list (full name match)
    if lower in EXCLUSIONS:
        return []

    tokens = re.findall(r"[a-z]+", lower)
    matched: list[str] = []

    for i, token in enumerate(tokens):
        # Skip tokens that are substrings of excluded compound words.
        if token == "gold" and any(
            exc_word in lower for exc_word in ("goldenrod", "marigold")
        ):
            continue

        if token in PRIMARY_METALS:
            # Check whether this is a compound pattern (burnished/antique + metal noun)
            if i > 0 and tokens[i - 1] in COMPOUND_PREFIXES:
                matched.append(f"{tokens[i - 1]} {token}")
            else:
                matched.append(token)
            continue

        # Compound prefix followed by a metal as next token
        if token in COMPOUND_PREFIXES and i + 1 < len(tokens) and tokens[i + 1] in PRIMARY_METALS:
            # Will be caught in the next iteration
            continue

    return matched


# ---------------------------------------------------------------------------
# Colour math (reused from colour_name_hex_audit.py)
# ---------------------------------------------------------------------------

def normalize_hex(hex_value: str) -> str:
    h = hex_value.strip().upper()
    if not h.startswith("#"):
        h = "#" + h
    return h


def hex_to_lab(hex_value: str) -> tuple[float, float, float]:
    hx = normalize_hex(hex_value)[1:]
    r, g, b = (int(hx[i : i + 2], 16) / 255.0 for i in (0, 2, 4))

    def inv_gamma(c: float) -> float:
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = inv_gamma(r), inv_gamma(g), inv_gamma(b)
    x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041
    x, y, z = x * 100, y * 100, z * 100

    def f(t: float) -> float:
        return t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116

    fx, fy, fz = f(x / 95.047), f(y / 100), f(z / 108.883)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


def delta_e(a: str, b: str) -> float:
    l1, aa, bb = hex_to_lab(a)
    l2, ac, bd = hex_to_lab(b)
    return math.sqrt((l1 - l2) ** 2 + (aa - ac) ** 2 + (bb - bd) ** 2)


def lch_to_hex(l: float, c: float, h: float) -> str:
    rad = math.radians(h)
    a = c * math.cos(rad)
    b = c * math.sin(rad)
    y_f = (l + 16) / 116
    x_f = y_f + a / 500
    z_f = y_f - b / 200

    def f_inv(t: float) -> float:
        return t**3 if t**3 > 0.008856 else (t - 16 / 116) / 7.787

    x = 95.047 * f_inv(x_f)
    y = 100.0 * f_inv(y_f)
    z = 108.883 * f_inv(z_f)
    r = x * 0.032406 + y * -0.015372 + z * -0.004986
    g = x * -0.009689 + y * 0.018758 + z * 0.000415
    bl = x * 0.000557 + y * -0.002040 + z * 0.010570

    def gamma(channel: float) -> float:
        if channel <= 0.0031308:
            return 12.92 * channel
        return 1.055 * (channel ** (1 / 2.4)) - 0.055

    r, g, bl = (max(0, min(1, gamma(v))) for v in (r, g, bl))
    return f"#{int(round(r * 255)):02X}{int(round(g * 255)):02X}{int(round(bl * 255)):02X}"


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

ZODIAC_SIGNS = frozenset({
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
})


@dataclass
class ColourEntry:
    name: str
    hex: str
    source: str
    context: str = ""
    line_number: int = 0


def parse_palette_library(path: Path) -> list[ColourEntry]:
    """Extract (name, hex) pairs from PaletteLibrary.swift with line numbers."""
    text = path.read_text()
    entries: list[ColourEntry] = []
    for i, line in enumerate(text.splitlines(), start=1):
        m = re.search(r'"([^"]+)":\s*"(#[0-9A-Fa-f]{6})"', line)
        if m:
            entries.append(ColourEntry(
                name=m.group(1),
                hex=normalize_hex(m.group(2)),
                source="palette_library",
                context="",
                line_number=i,
            ))
    return entries


def parse_sign_expressions(path: Path) -> list[ColourEntry]:
    """Extract SignExpression entries with sign/temperature context."""
    text = path.read_text()
    entries: list[ColourEntry] = []
    current_sign = ""
    current_temp = ""
    for i, line in enumerate(text.splitlines(), start=1):
        sign_match = re.match(r"\s+\.(\w+):\s*\[", line)
        if sign_match and sign_match.group(1) in ZODIAC_SIGNS:
            current_sign = sign_match.group(1)
        temp_match = re.match(r"\s+\.(warm|cool|neutral):\s*\[", line)
        if temp_match:
            current_temp = temp_match.group(1)
        expr_match = re.search(
            r'SignExpression\(L:\s*([\d.]+),\s*C:\s*([\d.]+),\s*h:\s*([\d.]+),\s*name:\s*"([^"]+)"\)',
            line,
        )
        if expr_match:
            l_val, c_val, h_val, name = expr_match.groups()
            hexv = lch_to_hex(float(l_val), float(c_val), float(h_val))
            entries.append(ColourEntry(
                name=name,
                hex=hexv,
                source="sign_accent_expression",
                context=f"{current_sign}/{current_temp}",
                line_number=i,
            ))
    return entries


# ---------------------------------------------------------------------------
# PaletteLibrary family/band membership
# ---------------------------------------------------------------------------

@dataclass
class FamilyBandMembership:
    family: str
    band: str


def parse_family_band_memberships(path: Path) -> dict[str, list[FamilyBandMembership]]:
    """Map each colour name to which family/band(s) it appears in."""
    text = path.read_text()
    memberships: dict[str, list[FamilyBandMembership]] = {}

    current_family = ""
    current_band = ""
    family_re = re.compile(r"\s*\.(\w+):\s*PaletteTriadV4\(")
    band_re = re.compile(r"\s*(neutrals|coreColours|accentColours|lightAnchor|deepAnchor):\s*")
    support_family_re = re.compile(r"\s*\.(\w+):\s*\[")

    in_support = False
    for line in text.splitlines():
        if "supportLibrary" in line:
            in_support = True
            continue
        if "colourNameToHex" in line:
            break

        if not in_support:
            fm = family_re.match(line)
            if fm:
                current_family = fm.group(1)
                continue
            bm = band_re.match(line)
            if bm:
                current_band = bm.group(1)

            # Find names in arrays
            for name in re.findall(r'"([^"]+)"', line):
                if name.startswith("#"):
                    continue
                if current_family and current_band:
                    memberships.setdefault(name.lower(), []).append(
                        FamilyBandMembership(family=current_family, band=current_band)
                    )
        else:
            fm = support_family_re.match(line)
            if fm and fm.group(1)[0].islower():
                current_family = fm.group(1)
            for name in re.findall(r'"([^"]+)"', line):
                if name.startswith("#"):
                    continue
                if current_family:
                    memberships.setdefault(name.lower(), []).append(
                        FamilyBandMembership(family=current_family, band="supportColours")
                    )

    return memberships


# ---------------------------------------------------------------------------
# Chart signature reachability
# ---------------------------------------------------------------------------

FAMILIES = [
    "lightSpring", "trueSpring", "brightSpring",
    "lightSummer", "trueSummer", "softSummer",
    "softAutumn", "trueAutumn", "deepAutumn",
    "deepWinter", "trueWinter", "brightWinter",
]

FAMILY_PROFILES: dict[str, tuple[str, str, str]] = {
    # family -> (depth, temperature, saturation)
    "lightSpring":  ("light",  "warm",    "rich"),
    "trueSpring":   ("medium", "warm",    "rich"),
    "brightSpring": ("medium", "neutral", "rich"),
    "lightSummer":  ("light",  "cool",    "soft"),
    "trueSummer":   ("medium", "cool",    "soft"),
    "softSummer":   ("medium", "cool",    "muted"),
    "softAutumn":   ("medium", "warm",    "muted"),
    "trueAutumn":   ("medium", "warm",    "rich"),
    "deepAutumn":   ("deep",   "warm",    "rich"),
    "deepWinter":   ("deep",   "cool",    "rich"),
    "trueWinter":   ("deep",   "cool",    "rich"),
    "brightWinter": ("deep",   "cool",    "rich"),
}

LIGHTNESS_RANGES: dict[str, tuple[float, float]] = {
    "light":  (70, 92),
    "medium": (40, 75),
    "deep":   (18, 48),
}

CHROMA_RANGES: dict[str, tuple[float, float]] = {
    "soft":  (6, 22),
    "muted": (14, 32),
    "rich":  (22, 60),
}

HUE_ARCS: dict[str, tuple[float, float]] = {
    "warm":    (10, 95),
    "neutral": (0, 360),
    "cool":    (170, 310),
}

SIGN_ARCHETYPES: dict[str, tuple[float, float, float]] = {
    "aries":       (48, 60,  28),
    "taurus":      (42, 32, 130),
    "gemini":      (72, 50,  85),
    "cancer":      (78, 12, 225),
    "leo":         (72, 55,  78),
    "virgo":       (52, 22, 105),
    "libra":       (75, 28,  10),
    "scorpio":     (26, 42,  15),
    "sagittarius": (35, 55, 310),
    "capricorn":   (22, 12, 260),
    "aquarius":    (55, 42, 215),
    "pisces":      (70, 25, 185),
}


def _clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))


def _hue_arc_contains(start: float, end: float, hue: float) -> bool:
    h = hue % 360
    if start == 0 and end == 360:
        return True
    if start <= end:
        return start <= h <= end
    return h >= start or h <= end


def _shortest_angular_dist(a: float, b: float) -> float:
    raw = abs(a - b) % 360
    return min(raw, 360 - raw)


def _clamp_hue(start: float, end: float, hue: float) -> float:
    h = hue % 360
    if _hue_arc_contains(start, end, h):
        return h
    d_start = _shortest_angular_dist(h, start)
    d_end = _shortest_angular_dist(h, end)
    return start if d_start <= d_end else end


def compute_signature_hex(sign: str, family: str) -> str:
    """Project a sign archetype into a family envelope, returning hex."""
    l_arch, c_arch, h_arch = SIGN_ARCHETYPES[sign]
    depth, temp, sat = FAMILY_PROFILES[family]

    l_lo, l_hi = LIGHTNESS_RANGES[depth]
    c_lo, c_hi = CHROMA_RANGES[sat]
    h_start, h_end = HUE_ARCS[temp]

    l = _clamp(l_arch, l_lo, l_hi)
    c = _clamp(c_arch, c_lo, c_hi)
    h = _clamp_hue(h_start, h_end, h_arch)

    return lch_to_hex(l, c, h)


def nearest_library_name(hex_value: str, library_map: dict[str, str]) -> str:
    """Find the nearest PaletteLibrary colour name for a given hex."""
    best_name = ""
    best_de = float("inf")
    for name, candidate_hex in library_map.items():
        de = delta_e(hex_value, candidate_hex)
        if de < best_de - 1e-9:
            best_de = de
            best_name = name
        elif abs(de - best_de) <= 1e-9 and (not best_name or name < best_name):
            best_name = name
    return best_name


def compute_signature_reachability(
    colour_name: str, library_map: dict[str, str]
) -> list[dict[str, str]]:
    """For each sign × family, check if this colour name is the nearest match."""
    hits: list[dict[str, str]] = []
    for sign in SIGN_ARCHETYPES:
        for family in FAMILIES:
            sig_hex = compute_signature_hex(sign, family)
            nearest = nearest_library_name(sig_hex, library_map)
            if nearest.lower() == colour_name.lower():
                hits.append({"sign": sign, "family": family, "signature_hex": sig_hex})
    return hits


# ---------------------------------------------------------------------------
# Nearest-5 computation
# ---------------------------------------------------------------------------

@dataclass
class NearestEntry:
    name: str
    hex: str
    delta_e: float


def nearest_n_library(
    hex_value: str, library_map: dict[str, str], exclude_name: str, n: int = 5
) -> list[NearestEntry]:
    """Find the N nearest palette library colours, excluding self."""
    exclude_lower = exclude_name.lower()
    distances: list[NearestEntry] = []
    for name, candidate_hex in library_map.items():
        if name.lower() == exclude_lower:
            continue
        de = delta_e(hex_value, candidate_hex)
        distances.append(NearestEntry(name=name, hex=candidate_hex, delta_e=round(de, 2)))
    distances.sort(key=lambda x: x.delta_e)
    return distances[:n]


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class Reachability:
    palette_family_bands: list[dict[str, str]] = field(default_factory=list)
    sign_accent_expressions: list[dict[str, str]] = field(default_factory=list)
    chart_signature_hits: list[dict[str, str]] = field(default_factory=list)
    daily_fit_eligible: bool = True


@dataclass
class FlaggedRow:
    name: str
    hex: str
    source: str
    context: str
    reachability: Reachability
    nearest_5: list[NearestEntry]
    metal_keywords_matched: list[str]
    source_locations: list[dict[str, Any]]


# ---------------------------------------------------------------------------
# Audit pipeline
# ---------------------------------------------------------------------------

def run_audit() -> dict[str, Any]:
    palette_entries = parse_palette_library(PALETTE_SWIFT)
    sign_entries = parse_sign_expressions(SIGN_SWIFT)
    all_entries = palette_entries + sign_entries

    # Library map for nearest-match lookups
    library_map: dict[str, str] = {}
    for e in palette_entries:
        if e.name.lower() not in {k.lower() for k in library_map}:
            library_map[e.name] = e.hex

    # Family/band memberships
    family_bands = parse_family_band_memberships(PALETTE_SWIFT)

    # Deduplicate entries by (source, name_lower, hex)
    seen: set[tuple[str, str, str]] = set()
    unique_entries: list[ColourEntry] = []
    for e in all_entries:
        key = (e.source, e.name.lower(), e.hex)
        if key not in seen:
            seen.add(key)
            unique_entries.append(e)

    # Flag entries with metal keywords
    flagged_rows: list[FlaggedRow] = []
    for entry in unique_entries:
        keywords = _metal_keywords_matched(entry.name)
        if not keywords:
            continue

        # Build reachability
        reachability = Reachability()

        # Palette family/band
        bands = family_bands.get(entry.name.lower(), [])
        reachability.palette_family_bands = [asdict(fb) for fb in bands]

        # Sign accent expression context
        if entry.source == "sign_accent_expression":
            parts = entry.context.split("/")
            reachability.sign_accent_expressions.append({
                "sign": parts[0] if len(parts) > 0 else "",
                "temperature": parts[1] if len(parts) > 1 else "",
            })

        # Also check if other sign entries share this name
        for other in unique_entries:
            if other is entry:
                continue
            if other.name.lower() == entry.name.lower() and other.source == "sign_accent_expression":
                parts = other.context.split("/")
                reachability.sign_accent_expressions.append({
                    "sign": parts[0] if len(parts) > 0 else "",
                    "temperature": parts[1] if len(parts) > 1 else "",
                })

        # Chart signature reachability (only for palette_library entries)
        if entry.source == "palette_library":
            reachability.chart_signature_hits = compute_signature_reachability(
                entry.name, library_map
            )

        reachability.daily_fit_eligible = True

        # Nearest 5
        nearest_5 = nearest_n_library(entry.hex, library_map, entry.name)

        # Source locations (relative to repo root)
        source_locations: list[dict[str, Any]] = []
        source_file = str(PALETTE_SWIFT.relative_to(REPO)) if entry.source == "palette_library" else str(SIGN_SWIFT.relative_to(REPO))
        source_locations.append({
            "file": source_file,
            "line": entry.line_number,
        })
        # Also find occurrences in the library section
        if entry.source == "sign_accent_expression":
            for pe in palette_entries:
                if pe.name.lower() == entry.name.lower():
                    source_locations.append({
                        "file": str(PALETTE_SWIFT.relative_to(REPO)),
                        "line": pe.line_number,
                    })

        flagged_rows.append(FlaggedRow(
            name=entry.name,
            hex=entry.hex,
            source=entry.source,
            context=entry.context,
            reachability=reachability,
            nearest_5=nearest_5,
            metal_keywords_matched=keywords,
            source_locations=source_locations,
        ))

    # Deduplicate flagged rows by (name_lower, source)
    deduped: list[FlaggedRow] = []
    deduped_keys: set[tuple[str, str]] = set()
    for row in flagged_rows:
        key = (row.name.lower(), row.source)
        if key not in deduped_keys:
            deduped_keys.add(key)
            deduped.append(row)

    report = _build_report(deduped, len(palette_entries), len(sign_entries))
    return report


def _build_report(
    flagged: list[FlaggedRow],
    palette_count: int,
    sign_count: int,
) -> dict[str, Any]:
    def row_dict(r: FlaggedRow) -> dict[str, Any]:
        return {
            "name": r.name,
            "hex": r.hex,
            "source": r.source,
            "context": r.context,
            "reachability": asdict(r.reachability),
            "nearest_5": [asdict(n) for n in r.nearest_5],
            "metal_keywords_matched": r.metal_keywords_matched,
            "source_locations": r.source_locations,
        }

    palette_flagged = [r for r in flagged if r.source == "palette_library"]
    sign_flagged = [r for r in flagged if r.source == "sign_accent_expression"]

    return {
        "summary": {
            "total_palette_library_tokens": palette_count,
            "total_sign_accent_expressions": sign_count,
            "flagged_total": len(flagged),
            "flagged_palette_library": len(palette_flagged),
            "flagged_sign_accent_expressions": len(sign_flagged),
            "unique_metal_keywords": sorted(
                set(k for r in flagged for k in r.metal_keywords_matched)
            ),
        },
        "flagged_rows": [row_dict(r) for r in sorted(flagged, key=lambda r: r.name.lower())],
    }


# ---------------------------------------------------------------------------
# Markdown rendering
# ---------------------------------------------------------------------------

def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# Colour metal/fabric vocabulary audit",
        "",
        "Generated by `tools/colour_metal_fabric_audit.py`.",
        "",
        "Re-run: `python3 tools/colour_metal_fabric_audit.py`",
        "",
        "## Purpose",
        "",
        'The app shows fabric-colour swatches beside a \u201cMetal Tone\u201d slider',
        "(Cool/Mixed/Warm for jewellery). Names that share metal/hardware",
        "vocabulary can confuse users. This audit flags those names for review.",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|------:|",
    ]
    s = report["summary"]
    lines.append(f"| Palette library tokens scanned | {s['total_palette_library_tokens']} |")
    lines.append(f"| Sign accent expressions scanned | {s['total_sign_accent_expressions']} |")
    lines.append(f"| **Flagged total** | **{s['flagged_total']}** |")
    lines.append(f"| Flagged (palette library) | {s['flagged_palette_library']} |")
    lines.append(f"| Flagged (sign accent expressions) | {s['flagged_sign_accent_expressions']} |")
    lines.append(f"| Unique metal keywords triggered | {len(s['unique_metal_keywords'])} |")
    lines.append("")
    lines.append(f"**Keywords triggered:** {', '.join(s['unique_metal_keywords'])}")
    lines.append("")

    lines.append("## Flagged entries")
    lines.append("")

    for row in report["flagged_rows"]:
        lines.append(f"### `{row['name']}` — `{row['hex']}`")
        lines.append("")
        lines.append(f"- **Source:** {row['source']}")
        lines.append(f"- **Context:** {row['context'] or '—'}")
        lines.append(f"- **Metal keywords:** {', '.join(row['metal_keywords_matched'])}")
        lines.append(f"- **Daily Fit eligible:** {'yes' if row['reachability']['daily_fit_eligible'] else 'no'}")
        lines.append("")

        # Reachability
        reach = row["reachability"]
        if reach["palette_family_bands"]:
            lines.append("**Palette family/band memberships:**")
            lines.append("")
            for fb in reach["palette_family_bands"]:
                lines.append(f"- {fb['family']} / {fb['band']}")
            lines.append("")

        if reach["sign_accent_expressions"]:
            lines.append("**Sign accent expression slots:**")
            lines.append("")
            for se in reach["sign_accent_expressions"]:
                lines.append(f"- {se['sign']} / {se['temperature']}")
            lines.append("")

        if reach["chart_signature_hits"]:
            lines.append("**Chart signature reachability** (this token is the nearest library match):")
            lines.append("")
            for hit in reach["chart_signature_hits"]:
                lines.append(f"- {hit['sign']} × {hit['family']} → `{hit['signature_hex']}`")
            lines.append("")

        # Nearest 5
        if row["nearest_5"]:
            lines.append("**Nearest 5 palette neighbours:**")
            lines.append("")
            lines.append("| Name | Hex | ΔE |")
            lines.append("|------|-----|----|")
            for n in row["nearest_5"]:
                lines.append(f"| {n['name']} | `{n['hex']}` | {n['delta_e']:.2f} |")
            lines.append("")

        # Source locations
        if row["source_locations"]:
            lines.append("**Source locations:**")
            lines.append("")
            for loc in row["source_locations"]:
                lines.append(f"- `{loc['file']}` line {loc['line']}")
            lines.append("")

        lines.append("---")
        lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Validation mode
# ---------------------------------------------------------------------------

@dataclass
class ValidationResult:
    status: str  # "BLOCK" | "WARN" | "OK"
    message: str
    row_index: int
    field: str = ""


def validate_proposals(proposals_path: Path, report: dict[str, Any]) -> list[ValidationResult]:
    """Validate a proposals JSON file against the current palette inventory."""
    proposals_text = proposals_path.read_text()
    proposals = json.loads(proposals_text)

    if not isinstance(proposals, list):
        return [ValidationResult(
            status="BLOCK",
            message="Proposals file must be a JSON array of objects.",
            row_index=-1,
        )]

    # Build reserved inventory from current palette
    palette_entries = parse_palette_library(PALETTE_SWIFT)
    reserved_names: set[str] = {e.name.lower() for e in palette_entries}

    sign_entries = parse_sign_expressions(SIGN_SWIFT)
    reserved_names.update(e.name.lower() for e in sign_entries)

    # Normalisation for collision detection
    def _normalise(name: str) -> str:
        return re.sub(r"[\s\-_]+", " ", name.strip().lower())

    reserved_normalised: set[str] = {_normalise(n) for n in reserved_names}

    results: list[ValidationResult] = []
    proposed_names_seen: set[str] = set()

    for i, proposal in enumerate(proposals):
        if not isinstance(proposal, dict):
            results.append(ValidationResult(
                status="BLOCK", message="Proposal entry is not a dict.", row_index=i,
            ))
            continue

        proposed_name = proposal.get("proposed_name", "")

        # Missing rationale
        if not proposal.get("rationale"):
            results.append(ValidationResult(
                status="BLOCK",
                message="Missing `rationale` field.",
                row_index=i,
                field="rationale",
            ))

        # Missing source/reachability
        if not proposal.get("source") and not proposal.get("reachability"):
            results.append(ValidationResult(
                status="BLOCK",
                message="Missing `source` or `reachability` field.",
                row_index=i,
                field="source",
            ))

        # Hex changed
        original_hex = proposal.get("hex", "")
        proposed_hex = proposal.get("proposed_hex", "")
        if proposed_hex and original_hex:
            if normalize_hex(proposed_hex) != normalize_hex(original_hex):
                results.append(ValidationResult(
                    status="BLOCK",
                    message=f"Hex changed from {original_hex} to {proposed_hex}. Renames must preserve hex.",
                    row_index=i,
                    field="hex",
                ))

        if not proposed_name:
            continue

        # Already in reserved inventory
        if proposed_name.lower() in reserved_names:
            # Only block if it's a different entry being renamed to an existing name
            original_name = proposal.get("name", "")
            if original_name.lower() != proposed_name.lower():
                results.append(ValidationResult(
                    status="BLOCK",
                    message=f"`proposed_name` '{proposed_name}' already exists in reserved inventory.",
                    row_index=i,
                    field="proposed_name",
                ))

        # Normalised collision
        norm_proposed = _normalise(proposed_name)
        original_name = proposal.get("name", "")
        if norm_proposed in reserved_normalised and original_name.lower() != proposed_name.lower():
            if not any(r.row_index == i and "reserved inventory" in r.message for r in results):
                results.append(ValidationResult(
                    status="BLOCK",
                    message=f"Normalised name collision: '{proposed_name}' collides with existing entry.",
                    row_index=i,
                    field="proposed_name",
                ))

        # Duplicate within batch
        if proposed_name.lower() in proposed_names_seen:
            results.append(ValidationResult(
                status="BLOCK",
                message=f"Duplicate `proposed_name` '{proposed_name}' within proposal batch.",
                row_index=i,
                field="proposed_name",
            ))
        proposed_names_seen.add(proposed_name.lower())

        # Proposed name still contains metal keyword with rename verdict
        verdict = proposal.get("verdict", "")
        if verdict == "rename":
            keywords = _metal_keywords_matched(proposed_name)
            if keywords:
                results.append(ValidationResult(
                    status="WARN",
                    message=f"Proposed name '{proposed_name}' still contains metal keyword(s): {keywords}.",
                    row_index=i,
                    field="proposed_name",
                ))

        # Case convention checks
        source = proposal.get("source", "")
        if source == "palette_library" and proposed_name != proposed_name.lower():
            results.append(ValidationResult(
                status="WARN",
                message=f"PaletteLibrary proposals should be lowercase: '{proposed_name}'.",
                row_index=i,
                field="proposed_name",
            ))
        if source == "sign_accent_expression" and proposed_name != proposed_name.title():
            results.append(ValidationResult(
                status="WARN",
                message=f"Sign accent proposals should be Title Case: '{proposed_name}'.",
                row_index=i,
                field="proposed_name",
            ))

    return results


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Audit colour names for metal/hardware vocabulary overlap"
    )
    parser.add_argument(
        "--validate-proposals",
        type=Path,
        metavar="FILE",
        help="Validate a proposals JSON file against the current inventory",
    )
    args = parser.parse_args()

    report = run_audit()

    if args.validate_proposals:
        results = validate_proposals(args.validate_proposals, report)
        blocks = [r for r in results if r.status == "BLOCK"]
        warns = [r for r in results if r.status == "WARN"]

        print(f"Validation: {len(results)} issues ({len(blocks)} BLOCK, {len(warns)} WARN)")
        print()
        for r in results:
            prefix = "❌ BLOCK" if r.status == "BLOCK" else "⚠️  WARN"
            idx = f"[row {r.row_index}]" if r.row_index >= 0 else "[global]"
            print(f"  {prefix} {idx} {r.message}")

        if blocks:
            print(f"\n{len(blocks)} blocking issue(s) — proposals cannot proceed.")
            raise SystemExit(1)
        elif warns:
            print(f"\n{len(warns)} warning(s) — review recommended but not blocking.")
        else:
            print("\nAll proposals valid.")
        return

    # Write outputs
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(report, indent=2) + "\n")
    OUT_MD.write_text(render_markdown(report))

    s = report["summary"]
    print(f"Wrote {OUT_JSON}")
    print(f"Wrote {OUT_MD}")
    print(
        f"Scanned {s['total_palette_library_tokens']} palette tokens + "
        f"{s['total_sign_accent_expressions']} sign expressions — "
        f"{s['flagged_total']} flagged "
        f"({s['flagged_palette_library']} palette, "
        f"{s['flagged_sign_accent_expressions']} sign accents)"
    )
    print(f"Metal keywords triggered: {', '.join(s['unique_metal_keywords'])}")


if __name__ == "__main__":
    main()
