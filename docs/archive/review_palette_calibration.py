#!/usr/bin/env python3
"""
Palette Calibration Review Helper

Compares a generated Blueprint palette against a human-labeled benchmark and
writes a reviewer-friendly markdown report.

Usage:
  python3 review_palette_calibration.py \
    --benchmark docs/palette_calibration/benchmarks/maria_deep_autumn.json \
    --blueprint docs/fixtures/blueprint_input_user_2.json

  python3 review_palette_calibration.py \
    --benchmark docs/palette_calibration/benchmarks/maria_deep_autumn.json \
    --blueprint path/to/cosmic_fit_blueprint.json \
    --output docs/palette_calibration/reports/maria_deep_autumn.md
"""

from __future__ import annotations

import argparse
import colorsys
import json
from pathlib import Path


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def normalize_name(value: str) -> str:
    return " ".join(value.strip().lower().split())


def hex_to_hsl(hex_value: str) -> tuple[float, float, float] | None:
    value = hex_value.strip().lstrip("#")
    if len(value) != 6:
        return None

    try:
        red = int(value[0:2], 16) / 255.0
        green = int(value[2:4], 16) / 255.0
        blue = int(value[4:6], 16) / 255.0
    except ValueError:
        return None

    hue, lightness, saturation = colorsys.rgb_to_hls(red, green, blue)
    return hue * 360.0, saturation, lightness


# ---------------------------------------------------------------------------
# Colour family classification — mirrors DeterministicResolver.deriveProfileFromHex
# ---------------------------------------------------------------------------

TEMPERATURE_LABELS = {"warm", "neutral", "cool"}
DEPTH_LABELS = {"deep", "medium", "light"}
CHROMA_LABELS = {"muted", "moderate", "bright"}


def classify_colour(hex_value: str) -> dict[str, str]:
    """Classify a colour by temperature, depth, and chroma from hex.

    Boundaries intentionally match the Swift resolver so the review script
    and the engine agree on classifications.
    """
    hsl = hex_to_hsl(hex_value)
    if hsl is None:
        return {"temperature": "neutral", "depth": "medium", "chroma": "moderate"}

    hue, sat, light = hsl

    if sat < 0.10:
        temperature = "neutral"
    elif hue < 75 or hue >= 335:
        temperature = "warm"
    elif 170 <= hue < 275:
        temperature = "cool"
    else:
        temperature = "neutral"

    if light < 0.35:
        depth = "deep"
    elif light > 0.65:
        depth = "light"
    else:
        depth = "medium"

    if sat < 0.25:
        chroma = "muted"
    elif sat > 0.65:
        chroma = "bright"
    else:
        chroma = "moderate"

    return {"temperature": temperature, "depth": depth, "chroma": chroma}


def axis_distance(a: str, b: str, axis: list[str]) -> int:
    try:
        return abs(axis.index(a) - axis.index(b))
    except ValueError:
        return 0


def family_fit_score(classification: dict[str, str], target: dict[str, str]) -> float:
    score = 1.0
    score -= axis_distance(classification["temperature"], target["temperature"],
                           ["warm", "neutral", "cool"]) * 0.20
    score -= axis_distance(classification["depth"], target["depth"],
                           ["deep", "medium", "light"]) * 0.20
    score -= axis_distance(classification["chroma"], target["chroma"],
                           ["muted", "moderate", "bright"]) * 0.10
    return max(score, 0.0)


def coherence_summary(entries: list[dict], target: dict[str, str]) -> dict:
    """Compute family-coherence statistics for a set of palette entries."""
    if not entries:
        return {"mean_fit": 0.0, "min_fit": 0.0, "off_family_count": 0, "anchor_details": []}

    details: list[dict] = []
    fits: list[float] = []
    off_family = 0

    for entry in entries:
        hex_value = entry.get("hexValue")
        if not hex_value:
            continue
        cls = classify_colour(hex_value)
        fit = family_fit_score(cls, target)
        fits.append(fit)
        if fit < 0.5:
            off_family += 1
        details.append({
            "name": entry.get("name", "<unnamed>"),
            "hex": hex_value,
            "temperature": cls["temperature"],
            "depth": cls["depth"],
            "chroma": cls["chroma"],
            "fit": fit,
        })

    mean_fit = sum(fits) / len(fits) if fits else 0.0
    min_fit = min(fits) if fits else 0.0

    return {
        "mean_fit": mean_fit,
        "min_fit": min_fit,
        "off_family_count": off_family,
        "anchor_details": details,
    }


def extract_palette(blueprint: dict) -> tuple[list[dict], list[dict]]:
    palette = blueprint.get("palette", blueprint)
    return palette.get("coreColours", []), palette.get("accentColours", [])


def extract_names(entries: list[dict]) -> list[str]:
    return [entry.get("name", "").strip() for entry in entries if entry.get("name")]


def overlap(actual: list[str], preferred: list[str]) -> list[str]:
    actual_norm = {normalize_name(name): name for name in actual}
    hits: list[str] = []
    for candidate in preferred:
        key = normalize_name(candidate)
        if key in actual_norm:
            hits.append(actual_norm[key])
    return hits


def provenance_counts(entries: list[dict]) -> dict[str, int]:
    counts = {"chartDerived": 0, "crossPoolEscalation": 0, "libraryFallback": 0, "unknown": 0}
    for entry in entries:
        provenance = entry.get("provenance", {})
        kind = provenance.get("kind", "unknown")
        if kind not in counts:
            counts["unknown"] += 1
        else:
            counts[kind] += 1
    return counts


def average_hsl(entries: list[dict]) -> tuple[float, float, float] | None:
    triples = []
    for entry in entries:
        hex_value = entry.get("hexValue")
        if not hex_value:
            continue
        converted = hex_to_hsl(hex_value)
        if converted is not None:
            triples.append(converted)

    if not triples:
        return None

    hue = sum(item[0] for item in triples) / len(triples)
    saturation = sum(item[1] for item in triples) / len(triples)
    lightness = sum(item[2] for item in triples) / len(triples)
    return hue, saturation, lightness


def format_anchor_list(entries: list[dict]) -> list[str]:
    lines: list[str] = []
    for entry in entries:
        name = entry.get("name", "<unnamed>")
        hex_value = entry.get("hexValue", "<no-hex>")
        provenance = entry.get("provenance", {})
        kind = provenance.get("kind", "unknown")
        combo_key = provenance.get("comboKey", "-")
        lines.append(f"- `{name}` `{hex_value}` — `{kind}` ({combo_key})")
    return lines


def heuristic_status(
    core_hits: int,
    accent_hits: int,
    forbidden_hits: int,
    required_core_hits: int,
    required_accent_hits: int,
    max_forbidden_hits: int,
) -> str:
    if (
        core_hits >= required_core_hits
        and accent_hits >= required_accent_hits
        and forbidden_hits <= max_forbidden_hits
    ):
        return "PASS"
    return "REVIEW"


def build_report(benchmark: dict, blueprint: dict, benchmark_path: Path, blueprint_path: Path) -> str:
    core_entries, accent_entries = extract_palette(blueprint)
    core_names = extract_names(core_entries)
    accent_names = extract_names(accent_entries)
    all_names = core_names + accent_names

    expectations = benchmark["paletteExpectations"]
    preferred_core_hits = overlap(core_names, expectations["preferredCoreAnchors"])
    preferred_accent_hits = overlap(accent_names, expectations["preferredAccentAnchors"])
    forbidden_hits = overlap(all_names, expectations["forbiddenAnchors"])

    core_provenance = provenance_counts(core_entries)
    accent_provenance = provenance_counts(accent_entries)
    palette_hsl = average_hsl(core_entries + accent_entries)

    expected_family = benchmark["expectedFamily"]
    family_target = {
        "temperature": normalize_family_axis(expected_family.get("temperature", "neutral")),
        "depth": normalize_family_axis(expected_family.get("depth", "medium")),
        "chroma": normalize_family_axis(expected_family.get("chroma", "moderate")),
    }
    coherence = coherence_summary(core_entries + accent_entries, family_target)

    status = heuristic_status(
        core_hits=len(preferred_core_hits),
        accent_hits=len(preferred_accent_hits),
        forbidden_hits=len(forbidden_hits),
        required_core_hits=expectations["requiredCoreHits"],
        required_accent_hits=expectations["requiredAccentHits"],
        max_forbidden_hits=expectations["maxForbiddenHits"],
    )

    lines: list[str] = []
    lines.append(f"# Palette Calibration Review — {benchmark['label']}")
    lines.append("")
    lines.append(f"- Benchmark: `{benchmark_path}`")
    lines.append(f"- Blueprint: `{blueprint_path}`")
    lines.append(f"- Expected family: `{expected_family['season']}`")
    lines.append(f"- Mechanical status: **{status}**")
    lines.append("")
    lines.append("## Family Target")
    lines.append("")
    lines.append(f"- Temperature: `{expected_family['temperature']}`")
    lines.append(f"- Depth: `{expected_family['depth']}`")
    lines.append(f"- Chroma: `{expected_family['chroma']}`")
    lines.append(f"- Summary: {expected_family['summary']}")
    lines.append("")
    lines.append("## Actual Palette")
    lines.append("")
    lines.append("### Core Anchors")
    lines.append("")
    lines.extend(format_anchor_list(core_entries) or ["- (none)"])
    lines.append("")
    lines.append("### Accent Anchors")
    lines.append("")
    lines.extend(format_anchor_list(accent_entries) or ["- (none)"])
    lines.append("")
    lines.append("## Mechanical Review")
    lines.append("")
    lines.append(
        f"- Preferred core hits: **{len(preferred_core_hits)}** / target **{expectations['requiredCoreHits']}**"
    )
    lines.append(
        f"- Preferred accent hits: **{len(preferred_accent_hits)}** / target **{expectations['requiredAccentHits']}**"
    )
    lines.append(
        f"- Forbidden-anchor hits: **{len(forbidden_hits)}** / max **{expectations['maxForbiddenHits']}**"
    )
    lines.append("")
    lines.append(f"- Preferred core matches: {preferred_core_hits or ['(none)']}")
    lines.append(f"- Preferred accent matches: {preferred_accent_hits or ['(none)']}")
    lines.append(f"- Forbidden hits: {forbidden_hits or ['(none)']}")
    lines.append("")
    lines.append("## Family Coherence")
    lines.append("")
    lines.append(f"- Target profile: `{family_target['temperature']}/{family_target['depth']}/{family_target['chroma']}`")
    lines.append(f"- Mean family-fit score: **{coherence['mean_fit']:.2f}**")
    lines.append(f"- Minimum family-fit score: **{coherence['min_fit']:.2f}**")
    lines.append(f"- Off-family anchors (fit < 0.50): **{coherence['off_family_count']}**")
    lines.append("")
    lines.append("### Per-Anchor Classification")
    lines.append("")
    lines.append("| Anchor | Hex | Temp | Depth | Chroma | Fit |")
    lines.append("|--------|-----|------|-------|--------|-----|")
    for detail in coherence["anchor_details"]:
        fit_str = f"{detail['fit']:.2f}"
        flag = " ⚠" if detail["fit"] < 0.50 else ""
        lines.append(
            f"| {detail['name']} | `{detail['hex']}` | {detail['temperature']} "
            f"| {detail['depth']} | {detail['chroma']} | {fit_str}{flag} |"
        )
    lines.append("")
    lines.append("## Provenance")
    lines.append("")
    lines.append(f"- Core provenance: `{core_provenance}`")
    lines.append(f"- Accent provenance: `{accent_provenance}`")
    lines.append("")

    if palette_hsl is not None:
        hue, saturation, lightness = palette_hsl
        lines.append("## Aggregate HSL")
        lines.append("")
        lines.append(f"- Average hue: `{hue:.1f}`")
        lines.append(f"- Average saturation: `{saturation:.2f}`")
        lines.append(f"- Average lightness: `{lightness:.2f}`")
        lines.append("")

    lines.append("## Human Review Prompts")
    lines.append("")
    for prompt in benchmark.get("humanReviewPrompts", []):
        lines.append(f"- [ ] {prompt}")
    lines.append("")
    lines.append("## Notes")
    lines.append("")
    for note in benchmark.get("notes", []):
        lines.append(f"- {note}")
    lines.append("")
    lines.append("## Reviewer Summary")
    lines.append("")
    lines.append("- Final judgement:")
    lines.append("- Dataset changes needed:")
    lines.append("- Resolver changes needed:")
    lines.append("")
    return "\n".join(lines)


def normalize_family_axis(value: str) -> str:
    """Map benchmark family descriptors to the three-level axis values
    used by the classifier (e.g. 'muted_to_rich' → 'muted')."""
    value = value.lower().replace("-", "_")
    if value in TEMPERATURE_LABELS:
        return value
    if value in DEPTH_LABELS:
        return value
    if value in CHROMA_LABELS:
        return value
    if "warm" in value:
        return "warm"
    if "cool" in value:
        return "cool"
    if "deep" in value:
        return "deep"
    if "light" in value:
        return "light"
    if "muted" in value:
        return "muted"
    if "bright" in value:
        return "bright"
    return "moderate"


def main() -> int:
    parser = argparse.ArgumentParser(description="Review a generated palette against a benchmark")
    parser.add_argument(
        "--benchmark",
        required=True,
        help="Path to a palette calibration benchmark JSON file",
    )
    parser.add_argument(
        "--blueprint",
        required=True,
        help="Path to a generated CosmicBlueprint JSON file",
    )
    parser.add_argument(
        "--output",
        help="Optional markdown output path. Defaults to docs/palette_calibration/reports/<benchmark-id>.md",
    )
    args = parser.parse_args()

    benchmark_path = Path(args.benchmark)
    blueprint_path = Path(args.blueprint)
    benchmark = load_json(benchmark_path)
    blueprint = load_json(blueprint_path)

    output_path = Path(args.output) if args.output else Path(
        f"docs/palette_calibration/reports/{benchmark['id']}.md"
    )

    report = build_report(benchmark, blueprint, benchmark_path, blueprint_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(report + "\n", encoding="utf-8")

    print(f"Wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
