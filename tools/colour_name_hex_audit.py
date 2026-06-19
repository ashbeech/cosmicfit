#!/usr/bin/env python3
"""
Cosmic Fit — Colour name ↔ hex systematic audit.

For every engine (name, hex) pair, finds the nearest CSS named colour,
nearest Pantone approximation, and nearest other PaletteLibrary token
(in CIE Lab ΔE76). Flags pairs where the label diverges from all
references beyond configurable thresholds.

Outputs:
  data/style_guide/colour_name_hex_audit.json
  data/style_guide/colour_name_hex_audit.md

Usage:
  python3 tools/colour_name_hex_audit.py
  python3 tools/colour_name_hex_audit.py --delta-e 8
"""

from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[1]
PALETTE_SWIFT = REPO / "Cosmic Fit/InterpretationEngine/ColourEngineV4/PaletteLibrary.swift"
SIGN_SWIFT = REPO / "Cosmic Fit/InterpretationEngine/ColourEngineV4/SignArchetypes.swift"
CHART_SWIFT = REPO / "Cosmic Fit/InterpretationEngine/ColourEngineV4/ChartSignatureResolver.swift"
OUT_JSON = REPO / "data/style_guide/colour_name_hex_audit.json"
OUT_MD = REPO / "data/style_guide/colour_name_hex_audit.md"

# W3C CSS Color Module Level 4 named colours (sRGB hex).
CSS_NAMED: dict[str, str] = {
    "aliceblue": "#F0F8FF",
    "antiquewhite": "#FAEBD7",
    "aqua": "#00FFFF",
    "aquamarine": "#7FFFD4",
    "azure": "#F0FFFF",
    "beige": "#F5F5DC",
    "bisque": "#FFE4C4",
    "black": "#000000",
    "blanchedalmond": "#FFEBCD",
    "blue": "#0000FF",
    "blueviolet": "#8A2BE2",
    "brown": "#A52A2A",
    "burlywood": "#DEB887",
    "cadetblue": "#5F9EA0",
    "chartreuse": "#7FFF00",
    "chocolate": "#D2691E",
    "coral": "#FF7F50",
    "cornflowerblue": "#6495ED",
    "cornsilk": "#FFF8DC",
    "crimson": "#DC143C",
    "cyan": "#00FFFF",
    "darkblue": "#00008B",
    "darkcyan": "#008B8B",
    "darkgoldenrod": "#B8860B",
    "darkgray": "#A9A9A9",
    "darkgreen": "#006400",
    "darkgrey": "#A9A9A9",
    "darkkhaki": "#BDB76B",
    "darkmagenta": "#8B008B",
    "darkolivegreen": "#556B2F",
    "darkorange": "#FF8C00",
    "darkorchid": "#9932CC",
    "darkred": "#8B0000",
    "darksalmon": "#E9967A",
    "darkseagreen": "#8FBC8F",
    "darkslateblue": "#483D8B",
    "darkslategray": "#2F4F4F",
    "darkslategrey": "#2F4F4F",
    "darkturquoise": "#00CED1",
    "darkviolet": "#9400D3",
    "deeppink": "#FF1493",
    "deepskyblue": "#00BFFF",
    "dimgray": "#696969",
    "dimgrey": "#696969",
    "dodgerblue": "#1E90FF",
    "firebrick": "#B22222",
    "floralwhite": "#FFFAF0",
    "forestgreen": "#228B22",
    "fuchsia": "#FF00FF",
    "gainsboro": "#DCDCDC",
    "ghostwhite": "#F8F8FF",
    "gold": "#FFD700",
    "goldenrod": "#DAA520",
    "gray": "#808080",
    "green": "#008000",
    "greenyellow": "#ADFF2F",
    "grey": "#808080",
    "honeydew": "#F0FFF0",
    "hotpink": "#FF69B4",
    "indianred": "#CD5C5C",
    "indigo": "#4B0082",
    "ivory": "#FFFFF0",
    "khaki": "#F0E68C",
    "lavender": "#E6E6FA",
    "lavenderblush": "#FFF0F5",
    "lawngreen": "#7CFC00",
    "lemonchiffon": "#FFFACD",
    "lightblue": "#ADD8E6",
    "lightcoral": "#F08080",
    "lightcyan": "#E0FFFF",
    "lightgoldenrodyellow": "#FAFAD2",
    "lightgray": "#D3D3D3",
    "lightgreen": "#90EE90",
    "lightgrey": "#D3D3D3",
    "lightpink": "#FFB6C1",
    "lightsalmon": "#FFA07A",
    "lightseagreen": "#20B2AA",
    "lightskyblue": "#87CEFA",
    "lightslategray": "#778899",
    "lightslategrey": "#778899",
    "lightsteelblue": "#B0C4DE",
    "lightyellow": "#FFFFE0",
    "lime": "#00FF00",
    "limegreen": "#32CD32",
    "linen": "#FAF0E6",
    "magenta": "#FF00FF",
    "maroon": "#800000",
    "mediumaquamarine": "#66CDAA",
    "mediumblue": "#0000CD",
    "mediumorchid": "#BA55D3",
    "mediumpurple": "#9370DB",
    "mediumseagreen": "#3CB371",
    "mediumslateblue": "#7B68EE",
    "mediumspringgreen": "#00FA9A",
    "mediumturquoise": "#48D1CC",
    "mediumvioletred": "#C71585",
    "midnightblue": "#191970",
    "mintcream": "#F5FFFA",
    "mistyrose": "#FFE4E1",
    "moccasin": "#FFE4B5",
    "navajowhite": "#FFDEAD",
    "navy": "#000080",
    "oldlace": "#FDF5E6",
    "olive": "#808000",
    "olivedrab": "#6B8E23",
    "orange": "#FFA500",
    "orangered": "#FF4500",
    "orchid": "#DA70D6",
    "palegoldenrod": "#EEE8AA",
    "palegreen": "#98FB98",
    "paleturquoise": "#AFEEEE",
    "palevioletred": "#DB7093",
    "papayawhip": "#FFEFD5",
    "peachpuff": "#FFDAB9",
    "peru": "#CD853F",
    "pink": "#FFC0CB",
    "plum": "#DDA0DD",
    "powderblue": "#B0E0E6",
    "purple": "#800080",
    "rebeccapurple": "#663399",
    "red": "#FF0000",
    "rosybrown": "#BC8F8F",
    "royalblue": "#4169E1",
    "saddlebrown": "#8B4513",
    "salmon": "#FA8072",
    "sandybrown": "#F4A460",
    "seagreen": "#2E8B57",
    "seashell": "#FFF5EE",
    "sienna": "#A0522D",
    "silver": "#C0C0C0",
    "skyblue": "#87CEEB",
    "slateblue": "#6A5ACD",
    "slategray": "#708090",
    "slategrey": "#708090",
    "snow": "#FFFAFA",
    "springgreen": "#00FF7F",
    "steelblue": "#4682B4",
    "tan": "#D2B48C",
    "teal": "#008080",
    "thistle": "#D8BFD8",
    "tomato": "#FF6347",
    "turquoise": "#40E0D0",
    "violet": "#EE82EE",
    "wheat": "#F5DEB3",
    "white": "#FFFFFF",
    "whitesmoke": "#F5F5F5",
    "yellow": "#FFFF00",
    "yellowgreen": "#9ACD32",
}

# Pantone hex approximations (TCX / fashion references; not official sRGB specs).
# Sources: Pantone public press kits, widely cited design-system conversions.
PANTONE_NAMED: dict[str, str] = {
    "Pantone 18-1750 Viva Magenta": "#BE3455",
    "Pantone 19-4052 Classic Blue": "#0F4C81",
    "Pantone 17-5104 Ultimate Gray": "#939597",
    "Pantone 13-0647 Illuminating": "#F5DF4D",
    "Pantone 17-3938 Very Peri": "#6667AB",
    "Pantone 18-3838 Ultra Violet": "#5F4B8B",
    "Pantone 15-0343 Greenery": "#88B04B",
    "Pantone 18-1664 Marsala": "#955251",
    "Pantone 17-1463 Tangerine Tango": "#DD4124",
    "Pantone 18-2120 Honeysuckle": "#D94F70",
    "Pantone 14-0848 Mimosa": "#F0C05A",
    "Pantone 18-3943 Blue Iris": "#5A5B9F",
    "Pantone 17-2031 Rose Quartz": "#F7CAC9",
    "Pantone 15-3919 Serenity": "#92A8D1",
    "Pantone 18-1438 Marsala (2015)": "#955251",
    "Pantone 19-1664 Living Coral": "#FF6F61",
    "Pantone 19-4005 Blue Graphite": "#414449",
    "Pantone 11-0601 Bright White": "#F4F9FF",
    "Pantone 19-0303 Jet Black": "#2D2926",
    "Pantone 18-1663 Fiery Red": "#C8102E",
    "Pantone 17-1564 Coral Pink": "#E17B88",
    "Pantone 16-1546 Peach Echo": "#F7786B",
    "Pantone 15-1520 Peach": "#FFB59A",
    "Pantone 16-1364 Vibrant Orange": "#FF7420",
    "Pantone 17-1456 Tigerlily": "#E2583E",
    "Pantone 18-1441 Brick Red": "#C14A3D",
    "Pantone 19-1557 Chianti": "#8B2E3C",
    "Pantone 19-1655 Rhodamine Red": "#CE0058",
    "Pantone 19-1763 Rubine Red": "#CE0056",
    "Pantone 18-1750 Magenta": "#BE3455",
    "Pantone 266 C": "#582C83",
    "Pantone 286 C": "#003DA5",
    "Pantone 300 C": "#005EB8",
    "Pantone 347 C": "#009A44",
    "Pantone 485 C": "#DA291C",
    "Pantone 021 C": "#FE5000",
    "Pantone 109 C": "#FFD100",
    "Pantone 877 C Silver": "#A7A8AA",
    "Pantone 871 C Gold": "#84754E",
    "Pantone 448 C": "#4A412A",
    "Pantone 7527 C": "#D6C6B5",
    "Pantone 7501 C": "#DFC08A",
    "Pantone 4625 C": "#5C3317",
    "Pantone 7530 C": "#9D948E",
    "Pantone 7540 C": "#3F4444",
    "Pantone 7543 C": "#C8C9C7",
    "Pantone 7544 C": "#9EA2A2",
    "Pantone 7545 C": "#6D7275",
    "Pantone 7546 C": "#425563",
    "Pantone 7547 C": "#253746",
    "Pantone 7699 C": "#1B365D",
    "Pantone 7687 C": "#00558C",
    "Pantone 7686 C": "#0072CE",
    "Pantone 7684 C": "#00A3E0",
    "Pantone 7466 C": "#009CBD",
    "Pantone 7472 C": "#009CA6",
    "Pantone 7473 C": "#007681",
    "Pantone 7474 C": "#005F61",
    "Pantone 7475 C": "#004F59",
    "Pantone 7476 C": "#003E51",
    "Pantone 7477 C": "#002E3D",
    "Pantone 7478 C": "#7EDDD3",
    "Pantone 7479 C": "#5CB8B2",
    "Pantone 5483 C": "#4F868E",
    "Pantone 5493 C": "#89ABAC",
    "Pantone 5503 C": "#A4BCC2",
    "Pantone 5523 C": "#B7C9D1",
    "Pantone 7541 C": "#E5E1E6",
    "Pantone 663 C": "#E5E0DF",
    "Pantone 656 C": "#EAF2F5",
    "Pantone 657 C": "#D9E6EE",
    "Pantone 658 C": "#B9D3E9",
    "Pantone 659 C": "#89ABD3",
    "Pantone 660 C": "#5B87B7",
    "Pantone 661 C": "#3867A5",
    "Pantone 662 C": "#004B87",
    "Pantone 676 C": "#E5B3D6",
    "Pantone 675 C": "#E08CBE",
    "Pantone 674 C": "#D56AA3",
    "Pantone 673 C": "#C94C8A",
    "Pantone 672 C": "#B83A6B",
    "Pantone 671 C": "#A02C56",
    "Pantone 670 C": "#8B2346",
    "Pantone 7421 C": "#651D32",
    "Pantone 7420 C": "#8A1538",
    "Pantone 7422 C": "#C8102E",
    "Pantone 7423 C": "#E4002B",
    "Pantone 7424 C": "#FF3B30",
    "Pantone 7425 C": "#FF6A6A",
    "Pantone 7426 C": "#FF8C8C",
    "Pantone 7427 C": "#FFB3B3",
    "Pantone 7428 C": "#FFD6D6",
    "Pantone 7429 C": "#FFE5E5",
}

ZODIAC_SIGNS = frozenset({
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
})

# High-risk labels: users are likely to Google these against CSS / paint chips.
STRICT_LABEL_TO_CSS: dict[str, str] = {
    "steel blue": "steelblue",
    "royal blue": "royalblue",
    "midnight blue": "midnightblue",
    "magenta red": "magenta",
    "tomato red": "tomato",
    "fuchsia red": "fuchsia",
    "true red": "red",
    "blue red": "blueviolet",
    "electric fuchsia": "fuchsia",
    "electric blue": "dodgerblue",
    "clear cyan": "cyan",
    "clear turquoise": "turquoise",
    "cerulean": "steelblue",
    "regal blue": "royalblue",
    "arctic blue": "deepskyblue",
    "goldenrod": "goldenrod",
    "crimson": "crimson",
    "coral": "coral",
    "maroon": "maroon",
    "indigo": "indigo",
    "violet": "violet",
    "purple": "purple",
    "turquoise": "turquoise",
    "teal": "teal",
    "lime": "lime",
    "gold": "gold",
    "silver": "silver",
    "black": "black",
    "white": "white",
    "navy": "navy",
    "peach": "peachpuff",
    "plum": "plum",
    "lavender": "lavender",
    "magenta": "magenta",
    "fuchsia": "fuchsia",
    "cyan": "cyan",
    "aqua": "aqua",
    "ivory": "ivory",
    "khaki": "khaki",
    "tan": "tan",
    "beige": "beige",
    "chocolate": "chocolate",
    "sienna": "sienna",
    "peru": "peru",
    "salmon": "salmon",
    "tomato": "tomato",
    "orchid": "orchid",
    "wheat": "wheat",
    "linen": "linen",
    "snow": "snow",
    "azure": "azure",
    "bisque": "bisque",
    "chartreuse": "chartreuse",
}


@dataclass
class ColourEntry:
    name: str
    hex: str
    source: str
    context: str = ""


@dataclass
class NearestMatch:
    name: str
    hex: str
    delta_e: float


@dataclass
class AuditRow:
    name: str
    hex: str
    source: str
    context: str
    nearest_css: NearestMatch | None
    nearest_pantone: NearestMatch | None
    nearest_library: NearestMatch | None
    implied_css: NearestMatch | None
    css_label_match: bool
    flags: list[str]
    actionable_flags: list[str]


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
    y = (l + 16) / 116
    x = y + a / 500
    z = y - b / 200

    def f_inv(t: float) -> float:
        return t**3 if t**3 > 0.008856 else (t - 16 / 116) / 7.787

    x = 95.047 * f_inv(x)
    y = 100.0 * f_inv(y)
    z = 108.883 * f_inv(z)
    r = x * 0.032406 + y * -0.015372 + z * -0.004986
    g = x * -0.009689 + y * 0.018758 + z * 0.000415
    bl = x * 0.000557 + y * -0.002040 + z * 0.010570

    def gamma(channel: float) -> float:
        if channel <= 0.0031308:
            return 12.92 * channel
        return 1.055 * (channel ** (1 / 2.4)) - 0.055

    r, g, bl = (max(0, min(1, gamma(v))) for v in (r, g, bl))
    return f"#{int(round(r * 255)):02X}{int(round(g * 255)):02X}{int(round(bl * 255)):02X}"


def parse_palette_library(path: Path) -> list[ColourEntry]:
    text = path.read_text()
    pairs = re.findall(r'"([^"]+)": "(#[0-9A-Fa-f]{6})"', text)
    return [
        ColourEntry(name=name, hex=normalize_hex(hexv), source="palette_library", context="template token")
        for name, hexv in pairs
    ]


def parse_sign_expressions(path: Path) -> list[ColourEntry]:
    text = path.read_text()
    entries: list[ColourEntry] = []
    current_sign = ""
    current_temp = ""
    for line in text.splitlines():
        sign_match = re.match(r"\s+\.(\w+): \[", line)
        if sign_match and sign_match.group(1) in ZODIAC_SIGNS:
            current_sign = sign_match.group(1)
        temp_match = re.match(r"\s+\.(warm|cool|neutral): \[", line)
        if temp_match:
            current_temp = temp_match.group(1)
        expr_match = re.search(
            r'SignExpression\(L: ([\d.]+), C: ([\d.]+), h:\s*([\d.]+), name: "([^"]+)"\)',
            line,
        )
        if expr_match:
            l_val, c_val, h_val, name = expr_match.groups()
            hexv = lch_to_hex(float(l_val), float(c_val), float(h_val))
            entries.append(
                ColourEntry(
                    name=name,
                    hex=hexv,
                    source="sign_accent_expression",
                    context=f"{current_sign}/{current_temp}",
                )
            )
    return entries


def parse_chart_archetypes(path: Path) -> list[ColourEntry]:
    text = path.read_text()
    entries: list[ColourEntry] = []
    for sign, l_val, c_val, h_val in re.findall(
        r"\.(\w+):\s+Archetype\(L: ([\d.]+), C: ([\d.]+), h:\s*([\d.]+)\)",
        text,
    ):
        hexv = lch_to_hex(float(l_val), float(c_val), float(h_val))
        entries.append(
            ColourEntry(
                name=f"{sign} signature archetype",
                hex=hexv,
                source="chart_signature_archetype",
                context=sign,
            )
        )
    return entries


def implied_css_reference(name: str, hex_value: str) -> NearestMatch | None:
    """If the label explicitly references a CSS colour name, return that pairing."""
    lowered = name.lower().strip()
    css_key: str | None = None

    if lowered in STRICT_LABEL_TO_CSS:
        css_key = STRICT_LABEL_TO_CSS[lowered]
    else:
        joined = re.sub(r"[^a-z0-9]+", "", lowered)
        if joined in CSS_NAMED:
            css_key = joined

    if css_key is None or css_key not in CSS_NAMED:
        return None

    css_hex = normalize_hex(CSS_NAMED[css_key])
    return NearestMatch(name=css_key, hex=css_hex, delta_e=round(delta_e(hex_value, css_hex), 2))


def tokenize_label(name: str) -> set[str]:
    return {t for t in re.split(r"[^a-z0-9]+", name.lower()) if t}


def css_tokens() -> dict[str, set[str]]:
    return {name: tokenize_label(name) for name in CSS_NAMED}


def nearest_in_catalog(hex_value: str, catalog: dict[str, str]) -> NearestMatch:
    best_name = ""
    best_hex = ""
    best_de = float("inf")
    for name, candidate in catalog.items():
        de = delta_e(hex_value, candidate)
        if de < best_de:
            best_de = de
            best_name = name
            best_hex = normalize_hex(candidate)
    return NearestMatch(name=best_name, hex=best_hex, delta_e=round(best_de, 2))


def nearest_library_token(
    hex_value: str, library: dict[str, str], exclude_name: str | None
) -> NearestMatch | None:
    exclude = (exclude_name or "").lower()
    best: NearestMatch | None = None
    for name, candidate in library.items():
        if name.lower() == exclude:
            continue
        de = delta_e(hex_value, candidate)
        if best is None or de < best.delta_e:
            best = NearestMatch(name=name, hex=normalize_hex(candidate), delta_e=round(de, 2))
    return best


def css_label_match(name: str, nearest_css_name: str) -> bool:
    label_tokens = tokenize_label(name)
    css_token_set = css_tokens()
    css_label_tokens = css_token_set.get(nearest_css_name, set())
    if not label_tokens or not css_label_tokens:
        return False
    overlap = label_tokens & css_label_tokens
    if overlap:
        return True
    # Multi-word CSS names split without spaces in catalog keys.
    for css_name, tokens in css_token_set.items():
        if tokens & label_tokens and css_name == nearest_css_name:
            return True
    # Label contains a CSS key as substring token e.g. "steel blue" -> steelblue
    joined = re.sub(r"[^a-z0-9]+", "", name.lower())
    if joined == nearest_css_name or nearest_css_name in joined or joined in nearest_css_name:
        return True
    return False


def audit_entry(
    entry: ColourEntry,
    library_map: dict[str, str],
    delta_e_threshold: float,
    warn_delta_e: float,
) -> AuditRow:
    nearest_css = nearest_in_catalog(entry.hex, CSS_NAMED)
    nearest_pantone = nearest_in_catalog(entry.hex, PANTONE_NAMED)
    nearest_lib = nearest_library_token(entry.hex, library_map, exclude_name=entry.name if entry.source == "palette_library" else None)
    implied_css = implied_css_reference(entry.name, entry.hex)

    label_match = css_label_match(entry.name, nearest_css.name)
    flags: list[str] = []
    actionable: list[str] = []

    if implied_css and implied_css.delta_e > warn_delta_e:
        flags.append(f"label_implied_css_mismatch:{implied_css.name} ΔE={implied_css.delta_e:.1f}")
        actionable.append(flags[-1])

    if label_match and nearest_css.delta_e > warn_delta_e:
        flags.append(f"css_semantic_mismatch:ΔE={nearest_css.delta_e:.1f}")
        if not any("label_implied_css_mismatch" in f for f in actionable):
            actionable.append(flags[-1])

    if nearest_css.delta_e > delta_e_threshold:
        flags.append(f"css_nearest_far:ΔE={nearest_css.delta_e:.1f}")

    if nearest_pantone.delta_e > delta_e_threshold:
        flags.append(f"pantone_nearest_far:ΔE={nearest_pantone.delta_e:.1f}")

    if nearest_lib and nearest_lib.delta_e <= 3 and entry.source != "palette_library":
        flags.append(f"library_duplicate:{nearest_lib.name} ΔE={nearest_lib.delta_e:.1f}")
        actionable.append(flags[-1])
    elif nearest_lib and nearest_lib.delta_e <= 5 and entry.source == "sign_accent_expression":
        flags.append(f"library_near_match:{nearest_lib.name} ΔE={nearest_lib.delta_e:.1f}")
        actionable.append(flags[-1])
    elif nearest_lib and nearest_lib.delta_e > delta_e_threshold and entry.source != "palette_library":
        flags.append(f"library_nearest_far:{nearest_lib.name} ΔE={nearest_lib.delta_e:.1f}")

    if entry.source == "palette_library":
        canonical = None
        for k, v in library_map.items():
            if k.lower() == entry.name.lower():
                canonical = v
                break
        if canonical and normalize_hex(canonical) != entry.hex:
            flags.append("library_internal_hex_mismatch")
            actionable.append(flags[-1])

    return AuditRow(
        name=entry.name,
        hex=entry.hex,
        source=entry.source,
        context=entry.context,
        nearest_css=nearest_css,
        nearest_pantone=nearest_pantone,
        nearest_library=nearest_lib,
        implied_css=implied_css,
        css_label_match=label_match,
        flags=flags,
        actionable_flags=actionable,
    )


def dedupe_entries(entries: Iterable[ColourEntry]) -> list[ColourEntry]:
    seen: set[tuple[str, str, str]] = set()
    out: list[ColourEntry] = []
    for e in entries:
        key = (e.source, e.name.lower(), e.hex)
        if key in seen:
            continue
        seen.add(key)
        out.append(e)
    return out


def build_library_map(entries: list[ColourEntry]) -> dict[str, str]:
    return {e.name: e.hex for e in entries if e.source == "palette_library"}


def render_markdown(report: dict) -> str:
    lines = [
        "# Colour name ↔ hex audit",
        "",
        "Generated by `tools/colour_name_hex_audit.py`.",
        "",
        "Re-run: `python3 tools/colour_name_hex_audit.py`",
        "",
        "## Thresholds",
        "",
        f"- **Actionable warn ΔE**: {report['thresholds']['css_semantic_warn_delta_e']} — label implies a standard CSS/Pantone reference but hex diverges",
        f"- **Informational ΔE**: {report['thresholds']['flag_delta_e']} — nearest global CSS/Pantone reference (most wardrobe tokens fail this by design)",
        "",
        "## Summary",
        "",
        "| Metric | Count |",
        "|--------|------:|",
    ]
    s = report["summary"]
    for key, val in s.items():
        lines.append(f"| {key.replace('_', ' ')} | {val} |")

    lines.extend([
        "",
        "## Tier 1 — Label implies a standard colour (fix list)",
        "",
        "These names explicitly reference CSS vocabulary. If the hex does not match, users will search and find the wrong swatch.",
        "",
    ])
    implied = report["priority_fixes"]["label_implied_css_mismatch"]
    if not implied:
        lines.append("_None above threshold._")
    else:
        lines.append("| Name | Hex | Source | Implied CSS | CSS hex | ΔE | Nearest library |")
        lines.append("|------|-----|--------|-------------|---------|----:|-----------------|")
        for row in implied:
            lib = row.get("nearest_library")
            lib_s = f"{lib['name']} `{lib['hex']}` ({lib['delta_e']:.1f})" if lib else "—"
            imp = row["implied_css"]
            lines.append(
                f"| {row['name']} | `{row['hex']}` | {row['source']} | {imp['name']} | `{imp['hex']}` | {imp['delta_e']:.1f} | {lib_s} |"
            )

    lines.extend([
        "",
        "## Tier 2 — Near-duplicate of an existing library token",
        "",
        "Chart-derived accents that are perceptually identical to a template token but use a different label.",
        "",
    ])
    dupes = report["priority_fixes"]["library_near_duplicates"]
    if not dupes:
        lines.append("_None._")
    else:
        lines.append("| Name | Hex | Source | Library token | Library hex | ΔE |")
        lines.append("|------|-----|--------|---------------|-------------|----:|")
        for row in dupes:
            lib = row["nearest_library"]
            lines.append(
                f"| {row['name']} | `{row['hex']}` | {row['source']} | {lib['name']} | `{lib['hex']}` | {lib['delta_e']:.1f} |"
            )

    lines.extend([
        "",
        "## Tier 3 — CSS token overlap (weaker signal)",
        "",
        "Label shares tokens with the globally nearest CSS name, but no explicit phrase mapping.",
        "",
    ])
    semantic = report["priority_fixes"]["css_semantic_mismatch"]
    if not semantic:
        lines.append("_None._")
    else:
        lines.append("| Name | Hex | Source | Nearest CSS | CSS hex | ΔE |")
        lines.append("|------|-----|--------|-------------|---------|----:|")
        for row in semantic:
            css = row["nearest_css"]
            lines.append(
                f"| {row['name']} | `{row['hex']}` | {row['source']} | {css['name']} | `{css['hex']}` | {css['delta_e']:.1f} |"
            )

    lines.extend(["", "## Full inventory", ""])
    lines.append("| Name | Hex | Source | Context | Implied CSS ΔE | Nearest CSS ΔE | Nearest Pantone ΔE | Actionable |")
    lines.append("|------|-----|--------|---------|---------------:|---------------:|-------------------:|------------|")
    for row in report["all_rows"]:
        imp = row.get("implied_css")
        imp_de = f"{imp['delta_e']:.1f}" if imp else "—"
        act = ", ".join(row.get("actionable_flags", [])) or "—"
        lines.append(
            f"| {row['name']} | `{row['hex']}` | {row['source']} | {row['context']} | {imp_de} | {row['nearest_css']['delta_e']:.1f} | {row['nearest_pantone']['delta_e']:.1f} | {act} |"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit colour name/hex pairs")
    parser.add_argument("--delta-e", type=float, default=10.0, help="Flag when nearest reference ΔE exceeds this")
    parser.add_argument("--css-warn-delta-e", type=float, default=5.0, help="Warn on CSS semantic overlap above this ΔE")
    args = parser.parse_args()

    palette_entries = parse_palette_library(PALETTE_SWIFT)
    sign_entries = parse_sign_expressions(SIGN_SWIFT)
    chart_entries = parse_chart_archetypes(CHART_SWIFT)
    all_entries = dedupe_entries(palette_entries + sign_entries + chart_entries)
    library_map = build_library_map(palette_entries)

    rows = [
        audit_entry(e, library_map, args.delta_e, args.css_warn_delta_e)
        for e in all_entries
    ]

    flagged = [r for r in rows if r.flags]
    actionable = [r for r in rows if r.actionable_flags]
    implied_fixes = [
        r for r in rows
        if r.implied_css and r.implied_css.delta_e > args.css_warn_delta_e
    ]
    implied_fixes.sort(key=lambda r: r.implied_css.delta_e if r.implied_css else 0, reverse=True)

    semantic = [
        r for r in rows
        if r.css_label_match
        and r.nearest_css
        and r.nearest_css.delta_e > args.css_warn_delta_e
        and not (r.implied_css and r.implied_css.delta_e > args.css_warn_delta_e)
    ]
    semantic.sort(key=lambda r: r.nearest_css.delta_e if r.nearest_css else 0, reverse=True)

    dupes = [
        r for r in rows
        if r.nearest_library
        and r.nearest_library.delta_e <= 5
        and r.source != "palette_library"
        and any("library_duplicate" in f or "library_near_match" in f for f in r.actionable_flags)
    ]
    dupes.sort(key=lambda r: r.nearest_library.delta_e if r.nearest_library else 0)

    def row_dict(r: AuditRow) -> dict:
        return {
            "name": r.name,
            "hex": r.hex,
            "source": r.source,
            "context": r.context,
            "css_label_match": r.css_label_match,
            "flags": r.flags,
            "actionable_flags": r.actionable_flags,
            "nearest_css": asdict(r.nearest_css) if r.nearest_css else None,
            "nearest_pantone": asdict(r.nearest_pantone) if r.nearest_pantone else None,
            "nearest_library": asdict(r.nearest_library) if r.nearest_library else None,
            "implied_css": asdict(r.implied_css) if r.implied_css else None,
        }

    report = {
        "thresholds": {
            "flag_delta_e": args.delta_e,
            "css_semantic_warn_delta_e": args.css_warn_delta_e,
        },
        "summary": {
            "total_pairs": len(rows),
            "palette_library_tokens": len(palette_entries),
            "sign_accent_expressions": len(sign_entries),
            "chart_signature_archetypes": len(chart_entries),
            "informational_flags": len(flagged),
            "actionable_rows": len(actionable),
            "label_implied_css_mismatches": len(implied_fixes),
            "css_semantic_mismatches": len(semantic),
            "library_near_duplicates": len(dupes),
        },
        "priority_fixes": {
            "label_implied_css_mismatch": [row_dict(r) for r in implied_fixes],
            "library_near_duplicates": [row_dict(r) for r in dupes],
            "css_semantic_mismatch": [row_dict(r) for r in semantic],
        },
        "actionable_rows": [row_dict(r) for r in sorted(actionable, key=lambda r: r.name.lower())],
        "all_rows": [row_dict(r) for r in sorted(rows, key=lambda r: (r.source, r.name.lower()))],
    }

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(report, indent=2) + "\n")
    OUT_MD.write_text(render_markdown(report))
    print(f"Wrote {OUT_JSON}")
    print(f"Wrote {OUT_MD}")
    print(
        f"Audited {len(rows)} pairs — "
        f"{len(actionable)} actionable, "
        f"{len(implied_fixes)} label-implied CSS mismatches (ΔE>{args.css_warn_delta_e}), "
        f"{len(dupes)} library near-duplicates"
    )


if __name__ == "__main__":
    main()
